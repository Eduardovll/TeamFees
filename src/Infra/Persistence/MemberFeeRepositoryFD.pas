unit MemberFeeRepositoryFD;

interface

uses
  System.Generics.Collections,
  System.JSON,
  Data.DB,
  FireDAC.Comp.Client,
  JsonHelper,
  MemberFeeRepositoryIntf, MemberFee, Enums;

type
  TMemberFeeRepositoryFD = class(TInterfacedObject, IMemberFeeRepository)
  private
    FConn: TFDConnection;
    function MapFee(Q: TFDQuery): TMemberFee;
  public
    constructor Create(const AConn: TFDConnection);
    function GetByMemberAndCycle(const MemberId, CycleId: Integer): TMemberFee;
    procedure Add(const Fee: TMemberFee);
    procedure Update(const Fee: TMemberFee);
    function GetByCycle(const CycleId: Integer; const Status: TFeeStatus): TObjectList<TMemberFee>;
    function GetByPixTxId(const TxId: string): TMemberFee;
    function FindById(const Id: Integer): TMemberFee;
    function GetSummary: TJSONObject;
    function GetDebtors: TJSONArray;
    function ListPaged(Page, Limit: Integer; Order: string; const Status: string; const MemberId: Integer = 0): TJSONObject;
    function ListPagedByMember(MemberId, Page, Limit: Integer; Order: string; const Status: string): TJSONObject;
    procedure SetExempt(const FeeId: Integer; const Reason: string);
    procedure Delete(const FeeId: Integer);
  end;

implementation

uses Money, System.SysUtils, System.DateUtils, System.Math;

constructor TMemberFeeRepositoryFD.Create(const AConn: TFDConnection);
begin
  inherited Create;
  FConn := AConn;
end;

function TMemberFeeRepositoryFD.MapFee(Q: TFDQuery): TMemberFee;
var F: TMemberFee;
begin
  F := TMemberFee.Create;
  F.Id := Q.FieldByName('id').AsInteger;
  F.MemberId := Q.FieldByName('member_id').AsInteger;
  F.CycleId := Q.FieldByName('cycle_id').AsInteger;
  F.Amount := TMoney.FromCents(Q.FieldByName('amount_cents').AsInteger);
  F.Status := StrToFeeStatus(Q.FieldByName('status').AsString);
  F.PixTxId := Q.FieldByName('pix_txid').AsString;
  F.PixProviderId := Q.FieldByName('pix_provider_id').AsString;
  F.PixQrCode := Q.FieldByName('pix_qr_code').AsString;
  F.DueDate := Q.FieldByName('due_date').AsDateTime;
  F.PaidAt := Q.FieldByName('paid_at').AsDateTime;
  if not Q.FieldByName('exempt_reason').IsNull then
    F.ExemptReason := Q.FieldByName('exempt_reason').AsString;
  Result := F;
end;

function TMemberFeeRepositoryFD.GetByMemberAndCycle(const MemberId, CycleId: Integer): TMemberFee;
var Q: TFDQuery;
begin
  Result := nil;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text := 'select * from member_fee where member_id=:m and cycle_id=:c';
    Q.ParamByName('m').AsInteger := MemberId;
    Q.ParamByName('c').AsInteger := CycleId;
    Q.Open;
    if not Q.IsEmpty then
      Result := MapFee(Q);
  finally
    Q.Free;
  end;
end;

procedure TMemberFeeRepositoryFD.Add(const Fee: TMemberFee);
var Q: TFDQuery;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text := 'insert into member_fee(member_id,cycle_id,amount_cents,status,due_date) ' +
                  'values(:m,:c,:a,:s,:d) returning id';
    Q.ParamByName('m').AsInteger := Fee.MemberId;
    Q.ParamByName('c').AsInteger := Fee.CycleId;
    Q.ParamByName('a').AsInteger := Fee.Amount.Cents;
    Q.ParamByName('s').AsString := FeeStatusToStr(Fee.Status);
    Q.ParamByName('d').AsDate := Fee.DueDate;
    Q.Open;
    Fee.Id := Q.FieldByName('id').AsInteger;
  finally
    Q.Free;
  end;
end;

procedure TMemberFeeRepositoryFD.Update(const Fee: TMemberFee);
var
  Q: TFDQuery;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'update member_fee set ' +
      'amount_cents = :a, ' +
      'status = :s, ' +
      'pix_txid = :tx, ' +
      'pix_qr_code = :qr, ' +
      'pix_provider_id = :pid, ' +
      'due_date = :d, ' +
      'paid_at = :p ' +
      'where id = :id';

    Q.ParamByName('a').AsInteger := Fee.Amount.Cents;
    Q.ParamByName('s').AsString := FeeStatusToStr(Fee.Status);
    Q.ParamByName('tx').AsString := Fee.PixTxId;
    Q.ParamByName('qr').AsString := Fee.PixQrCode;
    Q.ParamByName('pid').AsString := Fee.PixProviderId;
    Q.ParamByName('d').AsDate := Fee.DueDate;

    Q.ParamByName('p').DataType := ftDateTime;
    if Fee.PaidAt > 0 then
      Q.ParamByName('p').AsDateTime := Fee.PaidAt
    else
      Q.ParamByName('p').Clear;

    Q.ParamByName('id').AsInteger := Fee.Id;

    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

function TMemberFeeRepositoryFD.GetByCycle(const CycleId: Integer; const Status: TFeeStatus): TObjectList<TMemberFee>;
var Q: TFDQuery;
begin
  Result := TObjectList<TMemberFee>.Create(True);
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConn;
    if Status = fsOpen then
      Q.SQL.Text := 'select * from member_fee where cycle_id=:c and status=''OPEN''' else
      Q.SQL.Text := 'select * from member_fee where cycle_id=:c';
    Q.ParamByName('c').AsInteger := CycleId;
    Q.Open;
    while not Q.Eof do
    begin
      Result.Add(MapFee(Q));
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

function TMemberFeeRepositoryFD.FindById(const Id: Integer): TMemberFee;
var
  Q: TFDQuery;
begin
  Result := nil;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text := 'SELECT * FROM member_fee WHERE id = :id';
    Q.ParamByName('id').AsInteger := Id;
    Q.Open;

    if not Q.IsEmpty then
      Result := MapFee(Q);
  finally
    Q.Free;
  end;
end;


function TMemberFeeRepositoryFD.GetByPixTxId(const TxId: string): TMemberFee;
var Q: TFDQuery;
begin
  Result := nil;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text := 'select * from member_fee where pix_txid = :txid';
    Q.ParamByName('txid').AsString := TxId;
    Q.Open;

    if not Q.Eof then
    begin
      Result := TMemberFee.Create;
      Result.Id := Q.FieldByName('id').AsInteger;
      Result.MemberId := Q.FieldByName('member_id').AsInteger;
      Result.CycleId := Q.FieldByName('cycle_id').AsInteger;
      Result.Amount := TMoney.FromCents(Q.FieldByName('amount_cents').AsInteger);
      Result.Status := StrToFeeStatus(Q.FieldByName('status').AsString);
      Result.DueDate := Q.FieldByName('due_date').AsDateTime;
      Result.PaidAt := Q.FieldByName('paid_at').AsDateTime;
      Result.PixTxId := Q.FieldByName('pix_txid').AsString;
      Result.PixProviderId := Q.FieldByName('pix_provider_id').AsString;
      Result.PixQrCode := Q.FieldByName('pix_qr_code').AsString;
    end;
  finally
    Q.Free;
  end;
end;

function TMemberFeeRepositoryFD.GetDebtors: TJSONArray;
var
  Q: TFDQuery;
  Arr: TJSONArray;
  Obj: TJSONObject;
begin
  Q := TFDQuery.Create(nil);
  Arr := TJSONArray.Create;
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'select m.id AS member_id, m.full_name, f.amount_cents, f.due_date ' +
      'FROM member_fee f JOIN member m ON m.id = f.member_id ' +
      'WHERE f.status = ''OPEN'' ' +
      'ORDER BY f.due_date;';
    Q.Open;

    while not Q.Eof do
    begin
      Obj := TJSONObject.Create;
      Obj.AddPair('id',TJsonHelper.SafeNumber(Q.FieldByName('member_id')));
      Obj.AddPair('nome', TJsonHelper.SafeString(Q.FieldByName('full_name')));
      Obj.AddPair('valor', TJsonHelper.SafeNumber(Q.FieldByName('amount_cents')));
      Obj.AddPair('vencimento', TJsonHelper.SafeDate(Q.FieldByName('due_date')));

      Arr.AddElement(Obj);
      Q.Next;
    end;

    Result := Arr;
  finally
    Q.Free;
  end;
end;

function TMemberFeeRepositoryFD.GetSummary: TJSONObject;
var
  Q: TFDQuery;
  OpenCount, PaidCount, TotalCount: Integer;
  OpenAmount, PaidAmount, TotalAmount: Double;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'select status, count(*) qtd, sum(amount_cents) total_cents ' +
      'from member_fee group by status';
    Q.Open;

    OpenCount := 0; PaidCount := 0; TotalCount := 0;
    OpenAmount := 0; PaidAmount := 0; TotalAmount := 0;

    while not Q.Eof do
    begin
      if Q.FieldByName('status').AsString = 'OPEN' then
      begin
        OpenCount := Q.FieldByName('qtd').AsInteger;
        OpenAmount := Q.FieldByName('total_cents').AsFloat / 100;
      end
      else if Q.FieldByName('status').AsString = 'PAID' then
      begin
        PaidCount := Q.FieldByName('qtd').AsInteger;
        PaidAmount := Q.FieldByName('total_cents').AsFloat / 100;
      end;

      TotalCount := TotalCount + Q.FieldByName('qtd').AsInteger;
      TotalAmount := TotalAmount + Q.FieldByName('total_cents').AsFloat / 100;
      Q.Next;
    end;

    Result := TJSONObject.Create
      .AddPair('qtd_abertos', TJSONNumber.Create(OpenCount))
      .AddPair('qtd_pagos', TJSONNumber.Create(PaidCount))
      .AddPair('qtd_total', TJSONNumber.Create(TotalCount))
      .AddPair('valor_abertos', TJSONNumber.Create(OpenAmount))
      .AddPair('valor_pagos', TJSONNumber.Create(PaidAmount))
      .AddPair('valor_total', TJSONNumber.Create(TotalAmount));

  finally
    Q.Free;
  end;
end;

function TMemberFeeRepositoryFD.ListPaged(Page, Limit: Integer; Order: string; const Status: string; const MemberId: Integer = 0): TJSONObject;
var
  Q: TFDQuery;
  TotalQ: TFDQuery;
  Arr: TJSONArray;
  Obj: TJSONObject;
  Offset, TotalCount, TotalPages: Integer;
begin
  Result := nil;
  Q := TFDQuery.Create(nil);
  TotalQ := TFDQuery.Create(nil);
  try
    Q.Connection := FConn;
    TotalQ.Connection := FConn;

    if Order.Trim = '' then Order := 'vencimento_desc';
    if Page < 1 then Page := 1;
    if Limit <= 0 then Limit := 20;
    Offset := (Page - 1) * Limit;

    Q.SQL.Text := 'select f.id, f.member_id, m.full_name, f.amount_cents, f.status, f.due_date, f.paid_at, f.exempt_reason ' +
                  'from member_fee f ' +
                  'join member m on m.id = f.member_id ' +
                  'where 1=1 ';
    if Status <> '' then
      Q.SQL.Add('and f.status = :status');
    if MemberId > 0 then
      Q.SQL.Add('and f.member_id = :member_id');

    if SameText(Order, 'nome_desc') then
      Q.SQL.Add('order by m.full_name desc')
    else if SameText(Order, 'valor_desc') then
      Q.SQL.Add('order by f.amount_cents desc')
    else if SameText(Order, 'vencimento_desc') then
      Q.SQL.Add('order by f.due_date desc')
    else if SameText(Order, 'nome') then
      Q.SQL.Add('order by m.full_name')
    else if SameText(Order, 'valor') then
      Q.SQL.Add('order by f.amount_cents')
    else if SameText(Order, 'vencimento') then
      Q.SQL.Add('order by f.due_date')
    else
      Q.SQL.Add('order by f.id');


    Q.SQL.Add('limit :limit offset :offset');

    if Status <> '' then
      Q.ParamByName('status').AsString := Status;
    if MemberId > 0 then
      Q.ParamByName('member_id').AsInteger := MemberId;

    Q.ParamByName('limit').AsInteger := Limit;
    Q.ParamByName('offset').AsInteger := Offset;


    TotalQ.SQL.Text := 'select count(*) as total from member_fee f join member m on m.id = f.member_id where 1=1';
    if Status <> '' then
      TotalQ.SQL.Add('and f.status = :status');
    if MemberId > 0 then
      TotalQ.SQL.Add('and f.member_id = :member_id');

    if Status <> '' then
      TotalQ.ParamByName('status').AsString := Status;
    if MemberId > 0 then
      TotalQ.ParamByName('member_id').AsInteger := MemberId;

    TotalQ.Open;
    TotalCount := TotalQ.FieldByName('total').AsInteger;
    TotalPages := Ceil(TotalCount / Limit);

    Q.Open;
    Arr := TJSONArray.Create;

    while not Q.Eof do
    begin
      Obj := TJSONObject.Create;
      Obj.AddPair('id', TJSONNumber.Create(Q.FieldByName('id').AsInteger));
      Obj.AddPair('nome', Q.FieldByName('full_name').AsString);
      Obj.AddPair('valor', TJSONNumber.Create(Q.FieldByName('amount_cents').AsInteger));
      Obj.AddPair('status', Q.FieldByName('status').AsString);
      Obj.AddPair('vencimento', TJSONString.Create(DateToISO8601(Q.FieldByName('due_date').AsDateTime)));
      if not Q.FieldByName('paid_at').IsNull then
        Obj.AddPair('pago_em', TJSONString.Create(DateToISO8601(Q.FieldByName('paid_at').AsDateTime)));
      if not Q.FieldByName('exempt_reason').IsNull then
        Obj.AddPair('exempt_reason', Q.FieldByName('exempt_reason').AsString);
      Arr.AddElement(Obj);
      Q.Next;
    end;

    Result := TJSONObject.Create
      .AddPair('page', TJSONNumber.Create(Page))
      .AddPair('limit', TJSONNumber.Create(Limit))
      .AddPair('total_count', TJSONNumber.Create(TotalCount))
      .AddPair('total_pages', TJSONNumber.Create(TotalPages))
      .AddPair('has_prev', TJSONBool.Create(Page > 1))
      .AddPair('has_next', TJSONBool.Create(Page < TotalPages))
      .AddPair('data', Arr);

  finally
    TotalQ.Free;
    Q.Free;
  end;
end;

function TMemberFeeRepositoryFD.ListPagedByMember(MemberId, Page, Limit: Integer; Order: string; const Status: string): TJSONObject;
var
  Q: TFDQuery;
  TotalQ: TFDQuery;
  Arr: TJSONArray;
  Obj: TJSONObject;
  Offset, TotalCount, TotalPages: Integer;
begin
  Q := TFDQuery.Create(nil);
  TotalQ := TFDQuery.Create(nil);
  try
    Q.Connection := FConn;
    TotalQ.Connection := FConn;

    if Order.Trim = '' then Order := 'vencimento_desc';
    if Page < 1 then Page := 1;
    if Limit <= 0 then Limit := 20;
    Offset := (Page - 1) * Limit;

    Q.SQL.Text := 'select f.id, f.amount_cents, f.status, f.due_date, f.paid_at ' +
                  'from member_fee f ' +
                  'where f.member_id = :member_id ';
    if Status <> '' then
      Q.SQL.Add('and f.status = :status');

    if SameText(Order, 'vencimento_desc') then
      Q.SQL.Add('order by f.due_date desc')
    else if SameText(Order, 'vencimento') then
      Q.SQL.Add('order by f.due_date')
    else
      Q.SQL.Add('order by f.due_date desc');

    Q.SQL.Add('limit :limit offset :offset');

    Q.ParamByName('member_id').AsInteger := MemberId;
    if Status <> '' then
      Q.ParamByName('status').AsString := Status;
    Q.ParamByName('limit').AsInteger := Limit;
    Q.ParamByName('offset').AsInteger := Offset;

    TotalQ.SQL.Text := 'select count(*) as total from member_fee f where f.member_id = :member_id';
    if Status <> '' then
      TotalQ.SQL.Add('and f.status = :status');

    TotalQ.ParamByName('member_id').AsInteger := MemberId;
    if Status <> '' then
      TotalQ.ParamByName('status').AsString := Status;

    TotalQ.Open;
    TotalCount := TotalQ.FieldByName('total').AsInteger;
    TotalPages := Ceil(TotalCount / Limit);

    Q.Open;
    Arr := TJSONArray.Create;

    while not Q.Eof do
    begin
      Obj := TJSONObject.Create;
      Obj.AddPair('id', TJSONNumber.Create(Q.FieldByName('id').AsInteger));
      Obj.AddPair('valor', TJSONNumber.Create(Q.FieldByName('amount_cents').AsInteger));
      Obj.AddPair('status', Q.FieldByName('status').AsString);
      Obj.AddPair('vencimento', TJSONString.Create(DateToISO8601(Q.FieldByName('due_date').AsDateTime)));
      if not Q.FieldByName('paid_at').IsNull then
        Obj.AddPair('pago_em', TJSONString.Create(DateToISO8601(Q.FieldByName('paid_at').AsDateTime)));
      Arr.AddElement(Obj);
      Q.Next;
    end;

    Result := TJSONObject.Create
      .AddPair('page', TJSONNumber.Create(Page))
      .AddPair('limit', TJSONNumber.Create(Limit))
      .AddPair('total_count', TJSONNumber.Create(TotalCount))
      .AddPair('total_pages', TJSONNumber.Create(TotalPages))
      .AddPair('has_prev', TJSONBool.Create(Page > 1))
      .AddPair('has_next', TJSONBool.Create(Page < TotalPages))
      .AddPair('data', Arr);

  finally
    TotalQ.Free;
    Q.Free;
  end;
end;

procedure TMemberFeeRepositoryFD.SetExempt(const FeeId: Integer; const Reason: string);
var Q: TFDQuery;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text := 'update member_fee set status = ''EXEMPT'', exempt_reason = :reason where id = :id';
    Q.ParamByName('reason').AsString := Reason;
    Q.ParamByName('id').AsInteger := FeeId;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

procedure TMemberFeeRepositoryFD.Delete(const FeeId: Integer);
var Q: TFDQuery;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text := 'delete from member_fee where id = :id';
    Q.ParamByName('id').AsInteger := FeeId;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

end.



