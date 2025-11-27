unit FeesController;

interface

uses
  Horse,
  Horse.JWT,
  System.SysUtils,
  System.DateUtils,
  System.JSON,
  FeesServiceIntf,
  FeesService,
  Enums,
  MemberFee,
  Member,
  MemberRepositoryIntf,
  MemberFeeRepositoryIntf,
  PaymentRepositoryIntf,
  UnitOfWorkIntf,
  PixProviderIntf,
  RoleGuard,
  JOSE.Core.JWT,
  JOSE.Core.JWK,
  JOSE.Core.Builder,
  AppConfig,
  WhatsAppServiceIntf;

var
  FeesSvc: IFeesService;
  WhatsAppSvc: IWhatsAppService;
  FeesRepo: IMemberFeeRepository;
  MembersRepo: IMemberRepository;

procedure GetMyFees(Req: THorseRequest; Res: THorseResponse; Next: TProc);
procedure RegisterFeesRoutes(const Secret: string; Config: IHorseJWTConfig);

implementation

function ParseISO8601Date(const DateStr: string): TDateTime;
var
  Year, Month, Day: Word;
begin
  Year := StrToInt(Copy(DateStr, 1, 4));
  Month := StrToInt(Copy(DateStr, 6, 2));
  Day := StrToInt(Copy(DateStr, 9, 2));
  Result := EncodeDate(Year, Month, Day);
end;

procedure PostGenerateCycle(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Body: TJSONObject;
  Inp: TGenerateCycleInput;
  CycleId: Integer;
begin
  Body := Req.Body<TJSONObject>;
  Inp.Year := Body.GetValue<Integer>('year');
  Inp.Month := Body.GetValue<Integer>('month');
  Inp.DueDay := Body.GetValue<Integer>('due_day');
  Inp.AmountCents := Body.GetValue<Integer>('amount_cents');

  CycleId := FeesSvc.GenerateCycle(Inp);

  Res.Send(
    TJSONObject.Create
      .AddPair('cycle_id', TJSONNumber.Create(CycleId))
      .AddPair('message', 'Ciclo gerado com sucesso!')
  );
end;

procedure PostGenerateCustomFees(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Body: TJSONObject;
  Inp: TGenerateCustomFeesInput;
  Result: TGenerateCustomFeesResult;
  MemberIdsArray: TJSONArray;
  I: Integer;
  SkippedArray: TJSONArray;
  Response: TJSONObject;
begin
  Body := Req.Body<TJSONObject>;
  
  // Parsear member_ids (pode ser vazio para "todos")
  MemberIdsArray := Body.GetValue<TJSONArray>('member_ids');
  if MemberIdsArray <> nil then
  begin
    SetLength(Inp.MemberIds, MemberIdsArray.Count);
    for I := 0 to MemberIdsArray.Count - 1 do
      Inp.MemberIds[I] := MemberIdsArray.Items[I].GetValue<Integer>();
  end
  else
    SetLength(Inp.MemberIds, 0);
  
  Inp.AmountCents := Body.GetValue<Integer>('amount_cents');
  Inp.DueDate := ParseISO8601Date(Body.GetValue<string>('due_date'));
  Inp.Reference := Body.GetValue<string>('reference', '');
  Inp.MonthsCount := Body.GetValue<Integer>('months_count', 1);
  
  Result := FeesSvc.GenerateCustomFees(Inp);
  
  // Montar resposta
  Response := TJSONObject.Create;
  Response.AddPair('total_created', TJSONNumber.Create(Result.TotalCreated));
  Response.AddPair('total_skipped', TJSONNumber.Create(Result.TotalSkipped));
  
  // Array de membros que foram pulados
  SkippedArray := TJSONArray.Create;
  for I := 0 to High(Result.SkippedMembers) do
    SkippedArray.Add(Result.SkippedMembers[I]);
  Response.AddPair('skipped_members', SkippedArray);
  
  Response.AddPair('message', Format('%d mensalidades criadas com sucesso!', [Result.TotalCreated]));
  
  Res.Status(201).Send(Response);
end;

procedure PostManualSetPaid(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Body: TJSONObject;
  FeeId, Amount: Integer;
begin
  Body := Req.Body<TJSONObject>;
  FeeId := Body.GetValue<Integer>('member_fee_id');
  Amount := Body.GetValue<Integer>('amount_cents');

  FeesSvc.ManualSetPaid(FeeId, Amount);

  Res.Status(200)
     .Send(TJSONObject.Create.AddPair('message', 'Pagamento registrado com sucesso.'));
end;


procedure PostRegeneratePix(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Body: TJSONObject;
  FeeId: Integer;
  F: MemberFee.TMemberFee;
  J: TJSONObject;
begin
  Body := Req.Body<TJSONObject>;
  FeeId := Body.GetValue<Integer>('member_fee_id');
  F := FeesSvc.RegeneratePix(FeeId);

  J := TJSONObject.Create
    .AddPair('pix_txid', F.PixTxId)
    .AddPair('pix_provider_id', F.PixProviderId)
    .AddPair('pix_qr_code', F.PixQrCode);

  Res.Send(J);
end;

procedure GetFeesSummary(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  Res.Send(FeesSvc.GetSummary);
end;

procedure GetFees(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Page, Limit: Integer;
  Order, Status: string;
  Data: TJSONObject;
begin
  Writeln('>>> Executou GetFees!');
  Page := StrToIntDef(Req.Query['page'], 1);
  Limit := StrToIntDef(Req.Query['limit'], 20);
  Order := Req.Query['order'];
  Status := Trim(Req.Query['status']).ToUpper; // "open", "paid" ou vazio

  if (Status <> '') and (not Status.Equals('OPEN')) and (not Status.Equals('PAID')) then
    raise Exception.CreateFmt('Par�metro "status" inv�lido: "%s". Valores aceitos: OPEN ou PAID.', [Status]);

  Data := FeesSvc.ListPagedFees(Page, Limit, Order, Status);
  Res.Send<TJSONObject>(Data);
end;

procedure GetMyFees(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Token: string;
  JWT: TJWT;
  Key: TJWK;
  Page, Limit, MemberIdInt: Integer;
  MemberId, Order, Status: string;
  Data: TJSONObject;
  Cfg: TAppConfig;
begin
  Token := Req.Headers['authorization'].Replace('Bearer ', '').Trim;
  
  if Token = '' then
  begin
    Res.Status(401).Send(TJSONObject.Create.AddPair('error', 'Token inválido ou ausente'));
    Exit;
  end;

  Cfg := TAppConfig.LoadFromEnv;
  Key := TJWK.Create(Cfg.JwtSecret);
  try
    JWT := TJOSE.Verify(Key, Token);
    if not Assigned(JWT) then
    begin
      Res.Status(401).Send(TJSONObject.Create.AddPair('error', 'Token inválido'));
      Exit;
    end;
    
    MemberId := JWT.Claims.Subject;
    MemberIdInt := StrToInt(MemberId);
    Writeln('>>> GetMyFees: MemberId = ', MemberIdInt);
  finally
    Key.Free;
  end;
  
  Page := StrToIntDef(Req.Query['page'], 1);
  Limit := StrToIntDef(Req.Query['limit'], 20);
  Order := Req.Query['order'];
  Status := Trim(Req.Query['status']).ToUpper;

  if (Status <> '') and (not Status.Equals('OPEN')) and (not Status.Equals('PAID')) then
    raise Exception.CreateFmt('Parâmetro "status" inválido: "%s". Valores aceitos: OPEN ou PAID.', [Status]);

  Data := FeesSvc.ListMyFees(MemberIdInt, Page, Limit, Order, Status);
  Res.Send<TJSONObject>(Data);
end;

procedure PostGenerateMyPix(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  FeeId: Integer;
  F: MemberFee.TMemberFee;
  J: TJSONObject;
begin
  FeeId := StrToIntDef(Req.Params['id'], 0);
  if FeeId = 0 then
    raise Exception.Create('ID inválido');
  
  F := FeesSvc.RegeneratePix(FeeId);
  
  J := TJSONObject.Create
    .AddPair('pix_txid', F.PixTxId)
    .AddPair('pix_provider_id', F.PixProviderId)
    .AddPair('pix_qr_code', F.PixQrCode);
  
  Res.Send(J);
end;

procedure PostSendReceipt(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Token: string;
  JWT: TJWT;
  Key: TJWK;
  FeeId, MemberIdInt: Integer;
  MemberId: string;
  Fee: TMemberFee;
  Member: TMember;
  Phone, FullName: string;
  Cfg: TAppConfig;
begin
  Token := Req.Headers['authorization'].Replace('Bearer ', '').Trim;
  
  if Token = '' then
  begin
    Res.Status(401).Send(TJSONObject.Create.AddPair('error', 'Token inválido'));
    Exit;
  end;

  Cfg := TAppConfig.LoadFromEnv;
  Key := TJWK.Create(Cfg.JwtSecret);
  try
    JWT := TJOSE.Verify(Key, Token);
    if not Assigned(JWT) then
    begin
      Res.Status(401).Send(TJSONObject.Create.AddPair('error', 'Token inválido'));
      Exit;
    end;
    
    MemberId := JWT.Claims.Subject;
    MemberIdInt := StrToInt(MemberId);
  finally
    Key.Free;
  end;
  
  FeeId := StrToIntDef(Req.Params['id'], 0);
  if FeeId = 0 then
    raise Exception.Create('ID inválido');
  
  if not Assigned(FeesRepo) then
    raise Exception.Create('Sistema não inicializado');
  
  Fee := FeesRepo.FindById(FeeId);
  try
    if not Assigned(Fee) then
      raise Exception.Create('Mensalidade não encontrada');
    
    if Fee.MemberId <> MemberIdInt then
      raise Exception.Create('Você não tem permissão para acessar esta mensalidade');
    
    if Fee.Status <> fsPaid then
      raise Exception.Create('Apenas mensalidades pagas podem gerar comprovante');
    
    Member := MembersRepo.GetById(MemberIdInt);
    try
      if not Assigned(Member) then
        raise Exception.Create('Membro não encontrado');
      
      Phone := Member.PhoneWhatsApp;
      FullName := Member.FullName;
      
      if Phone = '' then
        raise Exception.Create('Telefone WhatsApp não cadastrado');
      
      if WhatsAppSvc.SendPaymentReceipt(Phone, FullName, FeeId, Fee.Amount.Cents, Fee.PaidAt) then
        Res.Send(TJSONObject.Create.AddPair('message', 'Comprovante enviado com sucesso!'))
      else
        raise Exception.Create('Erro ao enviar comprovante via WhatsApp');
    finally
      Member.Free;
    end;
  finally
    Fee.Free;
  end;
end;

procedure RegisterFeesRoutes(const Secret: string; Config: IHorseJWTConfig);
begin

  // ==== ROTAS PROTEGIDAS ====
  // Rotas para PLAYER ver suas mensalidades e gerar PIX
  THorse.Get('/my-fees', GetMyFees);
  THorse.Post('/my-fees/:id/generate-pix', PostGenerateMyPix);
  THorse.Post('/my-fees/:id/send-receipt', PostSendReceipt);
  // Rotas para TREASURER e ADMIN
  THorse.Group
    .Prefix('/fees')
    .Use(TRoleGuard.Require(urTreasurer, Secret))
    .Get('', GetFees)
    .Get('/summary', GetFeesSummary)
    .Post('/generate', PostGenerateCustomFees)
    .Post('/manual-set-paid', PostManualSetPaid)
    .Post('/regenerate-pix', PostRegeneratePix);

  // Rota exclusiva para ADMIN
  THorse.Group
    .Prefix('/cycles')
    .Use(TRoleGuard.Require(urAdmin, Secret))
    .Post('/generate', PostGenerateCycle);
end;

end.

