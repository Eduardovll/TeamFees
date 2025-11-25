unit MemberRepositoryFD;

interface

uses
  System.Generics.Collections,
  FireDAC.Comp.Client,
  Enums,
  Member,
  MemberRepositoryIntf;


type
  TMemberRepositoryFD = class(TInterfacedObject, IMemberRepository)
  private
    FConn: TFDConnection;
    function MapRow(Q: TFDQuery): TMember;
  public
    constructor Create(const AConn: TFDConnection);
    function GetActive: TObjectList<TMember>;
    function GetById(const Id: Integer): TMember;
    function FindByEmail(const Email: string): TMember;
    function FindByPhone(const Phone: string): TMember;
    function FindByCPF(const CPF: string): TMember;
    procedure Add(const M: TMember);
    procedure Update(const M: TMember);
  end;

implementation

uses
  System.SysUtils;

constructor TMemberRepositoryFD.Create(const AConn: TFDConnection);
begin
  inherited
  Create;
  FConn := AConn;
end;

{Método central para mapear um registro do banco em TMember}
function TMemberRepositoryFD.MapRow(Q: TFDQuery): TMember;
begin
  Result := TMember.Create;

  Result.Id            := Q.FieldByName('id').AsInteger;
  Result.FullName      := Q.FieldByName('full_name').AsString;
  Result.PhoneWhatsApp := Q.FieldByName('phone_whatsapp').AsString;
  Result.Email         := Q.FieldByName('email').AsString;
  Result.CPF           := Q.FieldByName('cpf').AsString;
  Result.IsActive      := Q.FieldByName('is_active').AsBoolean;
  Result.Role          := StrToRole(Q.FieldByName('role').AsString);
  Result.PasswordHash  := Q.FieldByName('password_hash').AsString;
end;


{FindByEmail}
function TMemberRepositoryFD.FindByEmail(const Email: string): TMember;
var
  Q: TFDQuery;
begin
  Result := nil;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'select id, full_name, phone_whatsapp, email, cpf, is_active, role, password_hash '+
      'from member where email = :email limit 1';

    Q.ParamByName('email').AsString := Email;
    Q.Open;

    if not Q.IsEmpty then
      Result := MapRow(Q);

  finally
    Q.Free;
  end;
end;

function TMemberRepositoryFD.FindByPhone(const Phone: string): TMember;
var
  Q: TFDQuery;
begin
  Result := nil;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'select ' +
      'id, full_name, phone_whatsapp, email, cpf, is_active, role, password_hash '+
      'from member ' +
      'where phone_whatsapp = :phone limit 1';

    Q.ParamByName('phone').AsString := Phone;
    Q.Open;

    if not Q.IsEmpty then
      Result := MapRow(Q);
  finally
     Q.Free;
  end;
end;

function TMemberRepositoryFD.FindByCPF(const CPF: string): TMember;
var
  Q: TFDQuery;
begin
  Result := nil;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'select id, full_name, phone_whatsapp, email, cpf, is_active, role, password_hash '+
      'from member where cpf = :cpf limit 1';

    Q.ParamByName('cpf').AsString := CPF;
    Q.Open;

    if not Q.IsEmpty then
      Result := MapRow(Q);
  finally
    Q.Free;
  end;
end;

{GetActive}
function TMemberRepositoryFD.GetActive: TObjectList<TMember>;
var
  Q: TFDQuery;
begin
  Result := TObjectList<TMember>.Create(True);

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'select id, full_name, phone_whatsapp, email, cpf, is_active, role, password_hash '+
      'from member where is_active = true';

    Q.Open;

    while not Q.Eof do
    begin
      Result.Add(MapRow(Q));
      Q.Next;
    end;

  finally
    Q.Free;
  end;
end;


{GetById}
function TMemberRepositoryFD.GetById(const Id: Integer): TMember;
var
  Q: TFDQuery;
begin
  Result := nil;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'select id, full_name, phone_whatsapp, email, cpf, is_active, role, password_hash '+
      'from member where id = :id limit 1';

    Q.ParamByName('id').AsInteger := Id;
    Q.Open;

    if not Q.IsEmpty then
      Result := MapRow(Q);

  finally
    Q.Free;
  end;
end;

procedure TMemberRepositoryFD.Add(const M: TMember);
var
  Q: TFDQuery;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'INSERT INTO member (full_name, email, phone_whatsapp, cpf, role, is_active, password_hash, created_at) ' +
      'VALUES (:full_name, :email, :phone, :cpf, :role, :is_active, :password_hash, CURRENT_TIMESTAMP) ' +
      'RETURNING id';

    Q.ParamByName('full_name').AsString := M.FullName;
    Q.ParamByName('email').AsString := M.Email;
    Q.ParamByName('phone').AsString := M.PhoneWhatsApp;
    Q.ParamByName('cpf').AsString := M.CPF;
    Q.ParamByName('role').AsString := RoleToStr(M.Role);
    Q.ParamByName('is_active').AsBoolean := M.IsActive;
    Q.ParamByName('password_hash').AsString := M.PasswordHash;
    Q.Open;
    
    if not Q.IsEmpty then
      M.Id := Q.FieldByName('id').AsInteger;
  finally
    Q.Free;
  end;
end;

procedure TMemberRepositoryFD.Update(const M: TMember);
var
  Q: TFDQuery;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'update member set ' +
      'full_name = :full_name, ' +
      'email = :email, ' +
      'phone_whatsapp = :phone, ' +
      'password_hash = :password_hash ' +
      'where id = :id';

    Q.ParamByName('id').AsInteger := M.Id;
    Q.ParamByName('full_name').AsString := M.FullName;
    Q.ParamByName('email').AsString := M.Email;
    Q.ParamByName('phone').AsString := M.PhoneWhatsApp;
    Q.ParamByName('password_hash').AsString := M.PasswordHash;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

end.

