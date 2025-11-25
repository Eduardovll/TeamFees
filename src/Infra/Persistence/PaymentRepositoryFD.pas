unit PaymentRepositoryFD;

interface

uses
  System.Generics.Collections,
  System.SysUtils,
  FireDAC.Comp.Client,
  Payment,
  PaymentRepositoryIntf;

type
  TPaymentRepositoryFD = class(TInterfacedObject, IPaymentRepository)
  private
    FConn: TFDConnection;
    function Map(Q: TFDQuery): TPayment;
  public
    constructor Create(const AConn: TFDConnection);
    procedure Add(const P: TPayment);
    function FindById(const Id: Integer): TPayment;
    function ListAll: TObjectList<TPayment>;
  end;

implementation

constructor TPaymentRepositoryFD.Create(const AConn: TFDConnection);
begin
  inherited Create;
  FConn := AConn;
end;

function TPaymentRepositoryFD.FindById(const Id: Integer): TPayment;
var Q: TFDQuery;
begin
  Result := nil;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'select id, member_fee_id, amount_cents, method, transaction_id, paid_at, created_at '+
      'from payment where id = :id';
    Q.ParamByName('id').AsInteger := Id;
    Q.Open;
    if not Q.IsEmpty then
      Result := Map(Q);
  finally
    Q.Free;
  end;
end;

function TPaymentRepositoryFD.ListAll: TObjectList<TPayment>;
var Q: TFDQuery;
begin
  Result := TObjectList<TPayment>.Create(True);
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'select id, member_fee_id, amount_cents, method, transaction_id, paid_at, created_at '+
      'from payment order by id';
    Q.Open;
    while not Q.Eof do
    begin
      Result.Add(Map(Q));
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

function TPaymentRepositoryFD.Map(Q: TFDQuery): TPayment;
begin
  Result := TPayment.Create;
  Result.Id            := Q.FieldByName('id').AsInteger;
  Result.MemberFeeId   := Q.FieldByName('member_fee_id').AsInteger;
  Result.AmountCents   := Q.FieldByName('amount_cents').AsInteger;
  Result.Method        := Q.FieldByName('method').AsString;
  Result.TransactionId := Q.FieldByName('transaction_id').AsString;
  Result.PaidAt        := Q.FieldByName('paid_at').AsDateTime;
  Result.CreatedAt     := Q.FieldByName('created_at').AsDateTime;
end;

procedure TPaymentRepositoryFD.Add(const P: TPayment);
var
  Q: TFDQuery;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'insert into payment(member_fee_id, amount_cents, method, transaction_id, paid_at, created_at) ' +
      'values(:f, :a, :m, :t, :p, :c)';
    Q.ParamByName('f').AsInteger := P.MemberFeeId;
    Q.ParamByName('a').AsInteger := P.AmountCents;
    Q.ParamByName('m').AsString := P.Method;
    Q.ParamByName('t').AsString := P.TransactionId;
    Q.ParamByName('c').AsDateTime := P.CreatedAt;

    if P.PaidAt > 0 then
      Q.ParamByName('p').AsDateTime := P.PaidAt
    else
      Q.ParamByName('p').Clear;

    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

end.
