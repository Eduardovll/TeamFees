unit MemberInvitationRepositoryFD;

interface

uses
  FireDAC.Comp.Client,
  MemberInvitationRepositoryIntf;

type
  TMemberInvitationRepositoryFD = class(TInterfacedObject, IMemberInvitationRepository)
  private
    FConn: TFDConnection;
  public
    constructor Create(const AConn: TFDConnection);
    procedure Add(const Invitation: TMemberInvitation);
    function GetByToken(const Token: string): TMemberInvitation;
    procedure MarkAsActivated(const Token: string);
  end;

implementation

uses
  System.SysUtils;

constructor TMemberInvitationRepositoryFD.Create(const AConn: TFDConnection);
begin
  inherited Create;
  FConn := AConn;
end;

procedure TMemberInvitationRepositoryFD.Add(const Invitation: TMemberInvitation);
var
  Q: TFDQuery;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'INSERT INTO member_invitation (member_id, token, expires_at, created_at) ' +
      'VALUES (:member_id, :token, :expires_at, CURRENT_TIMESTAMP)';
    
    Q.ParamByName('member_id').AsInteger := Invitation.MemberId;
    Q.ParamByName('token').AsString := Invitation.Token;
    Q.ParamByName('expires_at').AsDateTime := Invitation.ExpiresAt;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

function TMemberInvitationRepositoryFD.GetByToken(const Token: string): TMemberInvitation;
var
  Q: TFDQuery;
begin
  Result := nil;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'SELECT id, member_id, token, expires_at, activated_at, created_at ' +
      'FROM member_invitation WHERE token = :token LIMIT 1';
    
    Q.ParamByName('token').AsString := Token;
    Q.Open;
    
    if not Q.IsEmpty then
    begin
      Result := TMemberInvitation.Create;
      Result.Id := Q.FieldByName('id').AsInteger;
      Result.MemberId := Q.FieldByName('member_id').AsInteger;
      Result.Token := Q.FieldByName('token').AsString;
      Result.ExpiresAt := Q.FieldByName('expires_at').AsDateTime;
      if not Q.FieldByName('activated_at').IsNull then
        Result.ActivatedAt := Q.FieldByName('activated_at').AsDateTime;
      Result.CreatedAt := Q.FieldByName('created_at').AsDateTime;
    end;
  finally
    Q.Free;
  end;
end;

procedure TMemberInvitationRepositoryFD.MarkAsActivated(const Token: string);
var
  Q: TFDQuery;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConn;
    Q.SQL.Text :=
      'UPDATE member_invitation SET activated_at = CURRENT_TIMESTAMP ' +
      'WHERE token = :token';
    
    Q.ParamByName('token').AsString := Token;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

end.
