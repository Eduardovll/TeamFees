unit JwtAuth;

interface

uses
  Horse,
  AppConfig,
  JOSE.Core.JWT,
  JOSE.Core.JWK,
  JOSE.Core.JWS,
  JOSE.Core.JWA,
  System.SysUtils;

type
  TJwtAuth = class
  public
    class function Build(const Cfg: TAppConfig): THorseCallback;
  end;

implementation

class function TJwtAuth.Build(const Cfg: TAppConfig): THorseCallback;
begin
  Result :=
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Token: string;
      JWT: TJWT;
      Key: TJWK;
      JWS: TJWS;
    begin
      // Rotas públicas
      if Req.PathInfo.StartsWith('/auth/')
         or (Req.PathInfo = '/pix/webhook') then
      begin
        Next;
        Exit;
      end;

      // Pega o Bearer
      Token := Req.Headers['Authorization'];
      Token := Token.Replace('Bearer ', '', [rfIgnoreCase]).Trim;

      if Token = '' then
      begin
        Res.Status(401).Send('Token ausente.');
        Exit;
      end;

      JWT := TJWT.Create;
      Key := TJWK.Create(Cfg.JwtSecret);
      JWS := TJWS.Create(JWT);

      try
        try
          JWS.SetKey(Key);
          JWS.CompactToken := Token;

          if JWT.Claims.Expiration < Now then
          begin
            Res.Status(401).Send('Token expirado.');
            Exit;
          end;

          // SALVA AQUI — versão antiga do Horse usa Session
          Req.Session(JWT);

          Next;

        except
          Res.Status(401).Send('Token inválido.');
        end;

      finally
        Key.Free;
        JWS.Free;
        // JWT não libera — está na session
      end;

    end;
end;

end.

