unit JwtProvider;

interface

uses
  JOSE.Core.JWT,
  JOSE.Core.JWK,
  JOSE.Core.JWS,
  JOSE.Core.JWA,
  System.SysUtils,
  System.DateUtils;

type
  TJwtProvider = class
  public
    class function GenerateToken(
      const MemberId: Integer;
      const FullName: string;
      const Role: string;
      const Email: string;
      const TenantId: string;
      const Secret: string
    ): string;
  end;

implementation

class function TJwtProvider.GenerateToken(
  const MemberId: Integer;
  const FullName: string;
  const Role: string;
  const Email: string;
  const TenantId: string;
  const Secret: string
): string;
var
  JWT: TJWT;
  Key: TJWK;
  JWS: TJWS;
begin
  JWT := TJWT.Create;
  try
    // Identifica��o principal
    JWT.Claims.Subject := IntToStr(MemberId);

    // Expira��o (1 hora)
    JWT.Claims.Expiration := Now + (1 / 24);

    // ===== CUSTOM CLAIMS CORRETOS =====
    JWT.Claims.JSON.AddPair('role', Role);
    JWT.Claims.JSON.AddPair('full_name', FullName);
    JWT.Claims.JSON.AddPair('email', Email);
    JWT.Claims.JSON.AddPair('member_id', IntToStr(MemberId));
    JWT.Claims.JSON.AddPair('tenant_id', LowerCase(TenantId));

    // Cria��o do token
    Key := TJWK.Create(Secret);
    JWS := TJWS.Create(JWT);
    try
      JWS.Sign(Key, TJOSEAlgorithmId.HS256);
      Result := JWS.CompactToken;
    finally
      JWS.Free;
      Key.Free;
    end;

  finally
    JWT.Free;
  end;
end;


end.
