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
