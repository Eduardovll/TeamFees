unit SuperAdminGuard;

interface

uses
  Horse, Enums,
  JOSE.Core.JWT,
  JOSE.Core.JWK,
  JOSE.Core.Builder,
  Horse.Exception;

type
  TSuperAdminGuard = class
  public
    class function Require(const Secret: string): THorseCallback;
  end;

implementation

uses
  System.SysUtils, System.JSON, System.DateUtils;

class function TSuperAdminGuard.Require(const Secret: string): THorseCallback;
begin
  Result :=
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Token: string;
      Key: TJWK;
      JWT: TJWT;
      UserRole: string;
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

        UserRole := JWT.Claims.JSON.GetValue<string>('role');

        if UserRole <> 'SUPER_ADMIN' then
        begin
          Res.Status(403).Send(TJSONObject.Create
            .AddPair('error', 'Forbidden')
            .AddPair('message', 'Acesso exclusivo para Super Admin'));
          raise EHorseCallbackInterrupted.Create;
        end;

        Next;
      finally
        Key.Free;
      end;
    end;
end;

end.
