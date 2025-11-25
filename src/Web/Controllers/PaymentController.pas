unit PaymentController;

interface

uses
  Horse, PaymentRepositoryIntf, MemberFeeRepositoryIntf, MemberRepositoryIntf;

var
  PayRepo: IPaymentRepository;
  FeeRepo: IMemberFeeRepository;
  MemRepo: IMemberRepository;

procedure RegisterPaymentRoutes;

implementation

uses
  System.SysUtils, System.JSON, System.Generics.Collections,
  Payment, MemberFee, Member, RoleGuard, Enums, AppConfig;

function DateISO(const D: TDateTime): string;
begin
  if D > 0 then
    Result := FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss', D)
  else
    Result := '';
end;

procedure GetPayments(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  L: TObjectList<TPayment>;
  P: TPayment;
  Arr: TJSONArray;
  Obj: TJSONObject;
  Fee: TMemberFee;
  Mem: TMember;
begin
  L := PayRepo.ListAll;
  try
    Arr := TJSONArray.Create;
    for P in L do
    begin

      Fee := FeeRepo.FindById(P.MemberFeeId);
      Mem := nil;
      if Assigned(Fee) then
        Mem := MemRepo.GetById(Fee.MemberId);

      Obj := TJSONObject.Create
        .AddPair('id', TJSONNumber.Create(P.Id))
        .AddPair('member_fee_id', TJSONNumber.Create(P.MemberFeeId))
        .AddPair('amount_cents', TJSONNumber.Create(P.AmountCents))
        .AddPair('method', P.Method)
        .AddPair('transaction_id', P.TransactionId)
        .AddPair('paid_at', DateISO(P.PaidAt))
        .AddPair('created_at', DateISO(P.CreatedAt));

      if Assigned(Fee) then
        Obj.AddPair('cycle_id', TJSONNumber.Create(Fee.CycleId));
      if Assigned(Mem) then
        Obj.AddPair('member_name', Mem.FullName);

      Arr.AddElement(Obj);
    end;
    Res.Send(Arr);
  finally
    L.Free;
  end;
end;

procedure GetPaymentById(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Id: Integer;
  P: TPayment;
  Obj: TJSONObject;
begin
  Id := StrToIntDef(Req.Params['id'], 0);
  if Id = 0 then
    raise Exception.Create('Par�metro inv�lido: id');

  P := PayRepo.FindById(Id);
  if P = nil then
    raise Exception.Create('Pagamento n�o encontrado');

  Obj := TJSONObject.Create
    .AddPair('id', TJSONNumber.Create(P.Id))
    .AddPair('member_fee_id', TJSONNumber.Create(P.MemberFeeId))
    .AddPair('amount_cents', TJSONNumber.Create(P.AmountCents))
    .AddPair('method', P.Method)
    .AddPair('transaction_id', P.TransactionId)
    .AddPair('paid_at', DateISO(P.PaidAt))
    .AddPair('created_at', DateISO(P.CreatedAt));

  Res.Send(Obj);
end;

procedure RegisterPaymentRoutes;
var
  Cfg: TAppConfig;
begin
  Cfg := TAppConfig.LoadFromEnv;
  
  // Rotas para TREASURER e ADMIN
  THorse.Group
    .Prefix('/payments')
    .Use(TRoleGuard.Require(urTreasurer, Cfg.JwtSecret))
    .Get('', GetPayments)
    .Get('/:id', GetPaymentById);
end;

end.

