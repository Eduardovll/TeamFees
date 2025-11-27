unit TenantMiddleware;

interface

uses
  Horse;

procedure UseTenantMiddleware(Req: THorseRequest; Res: THorseResponse; Next: TProc);

implementation

uses
  System.SysUtils, System.JSON, System.DateUtils, JOSE.Core.JWT, JOSE.Core.JWK, JOSE.Core.Builder,
  TenantRepositoryIntf, TenantRepositoryFD, FDConnectionFactory, AppConfig, FireDAC.Comp.Client, Tenant, Horse.Exception;

procedure UseTenantMiddleware(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Token: string;
  JWT: TJWT;
  Key: TJWK;
  TenantId: string;
  Cfg: TAppConfig;
  Conn: TFDConnection;
  TenantRepo: ITenantRepository;
  TenantObj: Tenant.TTenant;
  Path: string;
begin
  Path := Req.RawWebRequest.PathInfo;
  
  // Pular rotas públicas (sem JWT)
  if Path.StartsWith('/auth/') or 
     Path.StartsWith('/tenants/signup') or 
     Path.StartsWith('/tenants/check-subdomain') or
     Path.StartsWith('/activate/') or
     Path.StartsWith('/pix/webhook') then
  begin
    Next;
    Exit;
  end;
  
  try
    // Pegar token do header
    Token := Req.Headers['Authorization'];
    if Token.StartsWith('Bearer ') then
      Token := Token.Substring(7).Trim;
    
    // Decodificar JWT manualmente
    Cfg := TAppConfig.LoadFromEnv;
    Key := TJWK.Create(Cfg.JwtSecret);
    try
      JWT := TJOSE.Verify(Key, Token);
      if JWT = nil then
        raise Exception.Create('Token inválido');
      
      TenantId := JWT.Claims.JSON.GetValue<string>('tenant_id', '');
    finally
      Key.Free;
    end;
    
    if TenantId.IsEmpty then
      raise Exception.Create('Tenant ID não encontrado no token');
    
    // Verificar status e trial do tenant
    Cfg := TAppConfig.LoadFromEnv;
    Conn := TFDConnectionFactory.CreatePostgres(Cfg);
    TenantRepo := TTenantRepositoryFD.Create(Conn);
    TenantObj := TenantRepo.FindById(TenantId);
    
    if TenantObj = nil then
      raise Exception.Create('Tenant não encontrado');
    
    try
      // Verificar se tenant está ativo
      if TenantObj.Status <> tsActive then
        raise Exception.Create('Conta suspensa ou cancelada. Entre em contato com o suporte.');
      
      // Verificar se trial expirou
      if (TenantObj.Plan = tpTrial) and (Now > TenantObj.TrialEndsAt) then
        raise Exception.Create('Período de teste expirado. Faça upgrade do seu plano.');
      
      // Tenant válido - continua
      Next;
    finally
      TenantObj.Free;
    end;
  except
    on E: Exception do
    begin
      Res.Send<TJSONObject>(
        TJSONObject.Create.AddPair('error', E.Message)
      ).Status(403);
      raise EHorseCallbackInterrupted.Create;
    end;
  end;
end;

end.
