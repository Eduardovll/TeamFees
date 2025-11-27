unit FeesService;

interface

uses
  System.SysUtils,
  System.DateUtils,
  System.Math,
  System.Generics.Collections,
  System.JSON,
  BillingCycle,
  Enums,
  Member,
  UnitOfWorkIntf,
  FeesServiceIntf,
  MemberRepositoryIntf,
  MemberFeeRepositoryIntf,
  PaymentRepositoryIntf,
  PixProviderIntf,
  MemberFee;

type
  TFeesService = class(TInterfacedObject, IFeesService)
  private
    FMembers: IMemberRepository;
    FFees: IMemberFeeRepository;
    FPayments: IPaymentRepository;
    FUoW: IUnitOfWork;
    FPix: IPixProvider;
  public
    constructor Create(const AMembers: IMemberRepository; const AFees: IMemberFeeRepository;
                       const APayments: IPaymentRepository; const AUoW: IUnitOfWork; const APix: IPixProvider);
    function GenerateCycle(const Input: TGenerateCycleInput): Integer;
    function GenerateCustomFees(const Input: TGenerateCustomFeesInput): TGenerateCustomFeesResult;
    function RegeneratePix(const MemberFeeId: Integer): TMemberFee;
    procedure ManualSetPaid(const MemberFeeId: Integer; const AmountCents: Integer);
    procedure ConfirmPixWebhook(const TxId: string; const AmountCents: Integer; const Payload: string);
    function GetSummary: TJSONObject;
    function ListPagedFees(Page, Limit: Integer; const Order, Status: string): TJSONObject;
    function ListMyFees(MemberId, Page, Limit: Integer; const Order, Status: string): TJSONObject;
  end;

implementation

uses Money, Payment;

constructor TFeesService.Create(const AMembers: IMemberRepository; const AFees: IMemberFeeRepository;
  const APayments: IPaymentRepository; const AUoW: IUnitOfWork; const APix: IPixProvider);
begin
  inherited Create;
  FMembers := AMembers;
  FFees := AFees;
  FPayments := APayments;
  FUoW := AUoW;
  FPix := APix;
end;

function TFeesService.GenerateCycle(const Input: TGenerateCycleInput): Integer;
var
  Actives: TObjectList<TMember>;
  CycleId: Integer;
  M: TMember;
  Fee: TMemberFee;
  Due: TDateTime;
begin
  // Define o ciclo AAAAMM (ex: 202511)
  CycleId := (Input.Year * 100) + Input.Month;

  // Garante que o dia de vencimento � v�lido no m�s
  Due := EncodeDate(Input.Year, Input.Month,
           EnsureRange(Input.DueDay, 1, DaysInAMonth(Input.Year, Input.Month)));

  // Busca membros ativos
  Actives := FMembers.GetActive;
  try
    FUoW.BeginTran;

    for M in Actives do
    begin
      // Evita duplicar mensalidades j� existentes
      Fee := FFees.GetByMemberAndCycle(M.Id, CycleId);
      if Fee = nil then
      begin
        Fee := TMemberFee.Create;
        Fee.MemberId := M.Id;
        Fee.CycleId := CycleId;
        Fee.Amount := TMoney.FromCents(Input.AmountCents);
        Fee.Status := fsOpen;
        Fee.DueDate := Due;
        Fee.PaidAt := 0;
        Fee.PixTxId := '';
        Fee.PixProviderId := '';
        Fee.PixQrCode := '';

        FFees.Add(Fee);
      end;
    end;

    FUoW.Commit;
  except
    FUoW.Rollback;
    raise;
  end;

  Result := CycleId;
end;

function TFeesService.GenerateCustomFees(const Input: TGenerateCustomFeesInput): TGenerateCustomFeesResult;
var
  Members: TObjectList<TMember>;
  M: TMember;
  Fee, ExistingFee: TMemberFee;
  CurrentDueDate: TDateTime;
  CurrentYear, CurrentMonth, DayDummy: Word;
  CycleId: Integer;
  MonthIndex, I: Integer;
  SkippedList: TList<string>;
begin
  Result.TotalCreated := 0;
  Result.TotalSkipped := 0;
  SetLength(Result.SkippedMembers, 0);
  
  SkippedList := TList<string>.Create;
  try
    // Buscar membros
    if Length(Input.MemberIds) = 0 then
      Members := FMembers.GetActive  // Todos os membros ativos
    else
    begin
      // Membros específicos
      Members := TObjectList<TMember>.Create(True);
      for I := 0 to High(Input.MemberIds) do
      begin
        M := FMembers.GetById(Input.MemberIds[I]);
        if M <> nil then
          Members.Add(M);
      end;
    end;
    
    try
      FUoW.BeginTran;
      
      // Gerar para cada mês
      for MonthIndex := 0 to Input.MonthsCount - 1 do
      begin
        // Calcular data de vencimento do mês atual
        CurrentDueDate := IncMonth(Input.DueDate, MonthIndex);
        DecodeDate(CurrentDueDate, CurrentYear, CurrentMonth, DayDummy);
        CycleId := (CurrentYear * 100) + CurrentMonth;
        
        // Gerar para cada membro
        for M in Members do
        begin
          // Verificar se já existe mensalidade para este membro neste ciclo
          ExistingFee := FFees.GetByMemberAndCycle(M.Id, CycleId);
          
          if ExistingFee = nil then
          begin
            // Criar nova mensalidade
            Fee := TMemberFee.Create;
            Fee.MemberId := M.Id;
            Fee.CycleId := CycleId;
            Fee.Amount := TMoney.FromCents(Input.AmountCents);
            Fee.Status := fsOpen;
            Fee.DueDate := CurrentDueDate;
            Fee.PaidAt := 0;
            Fee.PixTxId := '';
            Fee.PixProviderId := '';
            Fee.PixQrCode := '';
            
            FFees.Add(Fee);
            Inc(Result.TotalCreated);
          end
          else
          begin
            // Já existe - adicionar ao log
            if SkippedList.IndexOf(M.FullName) = -1 then
              SkippedList.Add(M.FullName);
            Inc(Result.TotalSkipped);
          end;
        end;
      end;
      
      FUoW.Commit;
      
      // Converter lista de skipped para array
      SetLength(Result.SkippedMembers, SkippedList.Count);
      for I := 0 to SkippedList.Count - 1 do
        Result.SkippedMembers[I] := SkippedList[I];
        
    except
      FUoW.Rollback;
      raise;
    end;
  finally
    SkippedList.Free;
    Members.Free;
  end;
end;

function TFeesService.GetSummary: TJSONObject;
begin
  Result := FFees.GetSummary;
end;

function TFeesService.ListPagedFees(Page, Limit: Integer; const Order, Status: string): TJSONObject;
begin
  Result := FFees.ListPaged(Page, Limit, Order, Status);
end;

function TFeesService.ListMyFees(MemberId, Page, Limit: Integer; const Order, Status: string): TJSONObject;
begin
  Result := FFees.ListPagedByMember(MemberId, Page, Limit, Order, Status);
end;

function TFeesService.RegeneratePix(const MemberFeeId: Integer): TMemberFee;
var
  Fee: TMemberFee;
  Charge: TPixCharge;
begin
  // Busca o registro por ID
  Fee := FFees.FindById(MemberFeeId);
  if Fee = nil then
    raise Exception.Create('Mensalidade n�o encontrada.');

  // Impede regenerar PIX de mensalidades j� quitadas
  if Fee.Status = fsPaid then
    raise Exception.Create('Mensalidade j� quitada, n�o � poss�vel gerar novo PIX.');

  // Gera nova cobran�a via provedor PIX
  Charge := FPix.CreateCharge(
    Format('FEE-%d', [Fee.Id]),
    Fee.Amount.Cents,
    Format('Mensalidade ciclo %d', [Fee.CycleId])
  );

  // Atualiza os dados do PIX
  Fee.PixTxId := Charge.TxId;
  Fee.PixProviderId := Charge.ProviderId;
  Fee.PixQrCode := Charge.QrCode;
  Fee.Status := fsOpen;

  // Persiste com transa��o
  FUoW.BeginTran;
  try
    FFees.Update(Fee);
    FUoW.Commit;
  except
    FUoW.Rollback;
    raise;
  end;

  Result := Fee;
end;


procedure TFeesService.ManualSetPaid(const MemberFeeId: Integer; const AmountCents: Integer);
var
  Fee: TMemberFee;
  P: TPayment;
begin
  Fee := FFees.FindById(MemberFeeId);
  if Fee = nil then
    raise Exception.CreateFmt('Mensalidade ID %d n�o encontrada', [MemberFeeId]);

  if Fee.Status = fsPaid then
    raise Exception.Create('Essa mensalidade j� foi paga.');

  FUoW.BeginTran;
  try
    // Atualiza o status
    Fee.Status := fsPaid;
    Fee.PaidAt := Now;
    FFees.Update(Fee);

    // Cria o registro de pagamento
    P := TPayment.Create;
    P.MemberFeeId := Fee.Id;
    P.AmountCents := AmountCents;
    P.Method := 'CASH';
    P.TransactionId := Format('TX-%d-%s', [Fee.Id, FormatDateTime('yyyymmddhhnnss', Now)]);
    P.PaidAt := Now;
    P.CreatedAt := Now;
    FPayments.Add(P);

    FUoW.Commit;
  except
    FUoW.Rollback;
    raise;
  end;
end;


procedure TFeesService.ConfirmPixWebhook(const TxId: string; const AmountCents: Integer; const Payload: string);
var
  Fee: TMemberFee;
  P: TPayment;
begin
  Fee := FFees.GetByPixTxId(TxId);
  if Fee = nil then
    raise Exception.Create('Mensalidade n�o encontrada para TxId informado.');

  // Evita marcar 2 vezes
  if Fee.Status = fsPaid then
    raise Exception.Create('Mensalidade j� est� quitada.');

  FUoW.BeginTran;
  try
    Fee.Status := fsPaid;
    Fee.PaidAt := Now;
    FFees.Update(Fee);

    // Cria registro de pagamento
    P := TPayment.Create;
    P.MemberFeeId := Fee.Id;
    P.AmountCents := AmountCents;
    P.Method := 'PIX';
    P.TransactionId := TxId;
    P.PaidAt := now;
    FPayments.Add(P);

    FUoW.Commit;
  except
    FUoW.Rollback;
    raise;
  end;
end;


end.
