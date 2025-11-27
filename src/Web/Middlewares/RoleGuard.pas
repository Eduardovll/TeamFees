unit RoleGuard;

interface

uses
  Horse, Enums,
  JOSE.Core.JWT,
  JOSE.Core.JWK,
  JOSE.Core.JWA,
  JOSE.Core.JWS,
  JOSE.Core.Builder,
  Horse.Exception;

type
  TRoleGuard = class
  public
    class function Require(const Role: TUserRole; const Secret: string): THorseCallback;
  end;

implementation

uses
  System.SysUtils,
  System.JSON,
  System.DateUtils,
  System.Rtti;

function IsJWTExpired(const JWT: TJWT): Boolean;
var
  Exp: TDateTime;
begin
  Result := False;

  if (JWT = nil) or (JWT.Claims = nil) then
    Exit(True);

  if JWT.Claims.HasExpiration then
  begin
    Exp := JWT.Claims.Expiration;
    Result := Now >= Exp;
  end;
end;

class function TRoleGuard.Require(const Role: TUserRole; const Secret: string): THorseCallback;
begin
  Result :=
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Token: string;
      Key: TJWK;
      JWT: TJWT;
      UserRole: string;
      Ctx: TRttiContext;
          RttiType: TRttiType;
          Field: TRttiField;
    begin
      Token := Req.Headers['authorization'].Replace('Bearer ', '').Trim;

      if Token = '' then
      begin
        Res.Status(401).Send(TJSONObject.Create
          .AddPair('error', 'Unauthorized')
          .AddPair('message', 'Token não fornecido'));
        raise EHorseCallbackInterrupted.Create;
      end;

      Key := TJWK.Create(Secret);
      JWT := nil;

      try
        try
          JWT := TJOSE.Verify(Key, Token);
        except
          on E: Exception do
          begin
            Res.Status(401).Send(TJSONObject.Create
              .AddPair('error', 'Unauthorized')
              .AddPair('message', 'Token inválido'));
            raise EHorseCallbackInterrupted.Create;
          end;
        end;

        if not Assigned(JWT) then
        begin
          Res.Status(401).Send(TJSONObject.Create
            .AddPair('error', 'Unauthorized')
            .AddPair('message', 'Token inválido'));
          raise EHorseCallbackInterrupted.Create;
        end;

        if IsJWTExpired(JWT) then
        begin
          Res.Status(401).Send(TJSONObject.Create
            .AddPair('error', 'Unauthorized')
            .AddPair('message', 'Token expirado'));
          raise EHorseCallbackInterrupted.Create;
        end;

        try
          UserRole := JWT.Claims.JSON.GetValue<string>('role');
        except
          on E: Exception do
          begin
            Res.Status(403).Send(TJSONObject.Create
              .AddPair('error', 'Forbidden')
              .AddPair('message', 'Erro ao ler role do token'));
            raise EHorseCallbackInterrupted.Create;
          end;
        end;

        if UserRole = '' then
        begin
          Res.Status(403).Send(TJSONObject.Create
            .AddPair('error', 'Forbidden')
            .AddPair('message', 'Role não encontrada no token'));
          raise EHorseCallbackInterrupted.Create;
        end;

        if (UserRole <> RoleToStr(Role)) and (UserRole <> 'ADMIN') and (UserRole <> 'SUPER_ADMIN') then
        begin
          Res.Status(403).Send(TJSONObject.Create
            .AddPair('error', 'Forbidden')
            .AddPair('message', 'Permissão insuficiente'));
          raise EHorseCallbackInterrupted.Create;
        end;

        // Guarda o JWT na sessão para uso posterior
        begin
          Ctx := TRttiContext.Create;
          try
            RttiType := Ctx.GetType(Req.ClassType);
            Field := RttiType.GetField('FSession');
            if Assigned(Field) then
              Field.SetValue(TObject(Req), JWT);
          finally
            Ctx.Free;
          end;
        end;
        Next;
      finally
        Key.Free;
      end;
    end;
end;

end.
