unit TenantController;

interface

uses
  Horse, System.JSON, TenantRepositoryIntf, MemberRepositoryIntf, Tenant, Member, Enums, WhatsAppServiceIntf;

type
  TTenantController = class
  private
    FTenantRepo: ITenantRepository;
    FMemberRepo: IMemberRepository;
    FWhatsAppSvc: IWhatsAppService;
  public
    constructor Create(ATenantRepo: ITenantRepository; AMemberRepo: IMemberRepository; AWhatsAppSvc: IWhatsAppService);
    procedure Signup(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    procedure CheckSubdomain(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    procedure GetCurrent(Req: THorseRequest; Res: THorseResponse; Next: TProc);
  end;

procedure RegisterTenantRoutes(ATenantRepo: ITenantRepository; AMemberRepo: IMemberRepository; AWhatsAppSvc: IWhatsAppService);

implementation

uses
  System.SysUtils, System.DateUtils, BCrypt.Provider, System.StrUtils, JOSE.Core.JWT;

constructor TTenantController.Create(ATenantRepo: ITenantRepository; AMemberRepo: IMemberRepository; AWhatsAppSvc: IWhatsAppService);
begin
  FTenantRepo := ATenantRepo;
  FMemberRepo := AMemberRepo;
  FWhatsAppSvc := AWhatsAppSvc;
end;

function GenerateSubdomain(const ABusinessName: string): string;
var
  Clean: string;
  I: Integer;
begin
  Clean := LowerCase(ABusinessName);
  Clean := StringReplace(Clean, ' ', '-', [rfReplaceAll]);
  
  Result := '';
  for I := 1 to Length(Clean) do
  begin
    if CharInSet(Clean[I], ['a'..'z', '0'..'9', '-']) then
      Result := Result + Clean[I];
  end;
  
  if Length(Result) > 30 then
    Result := Copy(Result, 1, 30);
    
  Result := Result + '-' + FormatDateTime('yyyymmddhhnnss', Now);
end;

function OnlyNumbers(const AStr: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(AStr) do
  begin
    if CharInSet(AStr[I], ['0'..'9']) then
      Result := Result + AStr[I];
  end;
end;

procedure TTenantController.Signup(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Body: TJSONObject;
  Tenant: TTenant;
  Member: TMember;
  TenantId, Subdomain: string;
  TrialEndsAt: TDateTime;
  Response: TJSONObject;
  InitialPassword: string;
begin
  try
    Body := Req.Body<TJSONObject>;
    
    Tenant := TTenant.Create;
    try
      Tenant.BusinessName := Body.GetValue<string>('business_name');
      Tenant.BusinessType := StrToBusinessType(Body.GetValue<string>('business_type'));
      Tenant.CNPJ := Body.GetValue<string>('cnpj', '');
      Tenant.Subdomain := GenerateSubdomain(Tenant.BusinessName);
      Tenant.Plan := tpTrial;
      Tenant.Status := tsActive;
      Tenant.TrialEndsAt := IncDay(Now, 14);
      Tenant.MaxMembers := 30;
      
      TenantId := FTenantRepo.CreateTenant(Tenant);
      TrialEndsAt := Tenant.TrialEndsAt;
      Subdomain := Tenant.Subdomain;
    finally
      Tenant.Free;
    end;
    
    Member := TMember.Create;
    try
      Member.TenantId := TenantId;
      Member.FullName := Body.GetValue<string>('admin_name');
      Member.Email := Body.GetValue<string>('admin_email');
      Member.PhoneWhatsApp := Body.GetValue<string>('admin_phone');
      Member.CPF := Body.GetValue<string>('admin_cpf');
      Member.Role := urAdmin;
      Member.IsActive := True;
      
      InitialPassword := Copy(OnlyNumbers(Member.CPF), Length(OnlyNumbers(Member.CPF)) - 5, 6);
      Member.PasswordHash := BCryptHash(InitialPassword, 12);
      
      FMemberRepo.Add(Member);
    finally
      Member.Free;
    end;
    
    Response := TJSONObject.Create;
    Response.AddPair('tenant_id', TenantId);
    Response.AddPair('trial_ends_at', DateToISO8601(TrialEndsAt));
    Response.AddPair('message', 'Conta criada com sucesso! Verifique seu email.');
    
    // Notificar admin via WhatsApp
    try
      FWhatsAppSvc.SendNewTenantNotification(
        '18991159828',
        Body.GetValue<string>('business_name'),
        Body.GetValue<string>('business_type'),
        'Trial',
        Subdomain,
        Body.GetValue<string>('admin_name'),
        Body.GetValue<string>('admin_email'),
        Body.GetValue<string>('admin_phone', 'Não informado')
      );
    except
      on E: Exception do
        Writeln('>>> Erro ao enviar notificação WhatsApp: ', E.Message);
    end;
    
    Res.Status(201).Send<TJSONObject>(Response);
  except
    on E: Exception do
    begin
      Res.Send<TJSONObject>(
        TJSONObject.Create.AddPair('error', E.Message)
      ).Status(400);
    end;
  end;
end;

procedure TTenantController.CheckSubdomain(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Subdomain: string;
  Exists: Boolean;
  Response: TJSONObject;
begin
  try
    Subdomain := Req.Params['subdomain'];
    Exists := FTenantRepo.SubdomainExists(Subdomain);
    
    Response := TJSONObject.Create;
    Response.AddPair('available', TJSONBool.Create(not Exists));
    
    Res.Send<TJSONObject>(Response);
  except
    on E: Exception do
    begin
      Res.Send<TJSONObject>(
        TJSONObject.Create.AddPair('error', E.Message)
      ).Status(400);
    end;
  end;
end;

procedure TTenantController.GetCurrent(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  TenantId: string;
  Tenant: TTenant;
  Response: TJSONObject;
  JWT: TJWT;
begin
  try
    JWT := Req.Session<TJWT>;
    if JWT = nil then
      raise Exception.Create('Token não encontrado');
    
    TenantId := JWT.Claims.JSON.GetValue<string>('tenant_id', '');
    
    if TenantId.IsEmpty then
      raise Exception.Create('Tenant ID não encontrado');
    
    Tenant := FTenantRepo.FindById(TenantId);
    try
      if Tenant = nil then
        raise Exception.Create('Tenant não encontrado');
      
      Response := TJSONObject.Create;
      Response.AddPair('id', Tenant.Id);
      Response.AddPair('business_name', Tenant.BusinessName);
      Response.AddPair('business_type', BusinessTypeToStr(Tenant.BusinessType));
      Response.AddPair('subdomain', Tenant.Subdomain);
      Response.AddPair('plan', PlanToStr(Tenant.Plan));
      Response.AddPair('status', StatusToStr(Tenant.Status));
      Response.AddPair('trial_ends_at', DateToISO8601(Tenant.TrialEndsAt));
      
      Res.Send<TJSONObject>(Response);
    finally
      Tenant.Free;
    end;
  except
    on E: Exception do
    begin
      Res.Send<TJSONObject>(
        TJSONObject.Create.AddPair('error', E.Message)
      ).Status(400);
    end;
  end;
end;

procedure RegisterTenantRoutes(ATenantRepo: ITenantRepository; AMemberRepo: IMemberRepository; AWhatsAppSvc: IWhatsAppService);
var
  Controller: TTenantController;
begin
  Controller := TTenantController.Create(ATenantRepo, AMemberRepo, AWhatsAppSvc);
  
  THorse.Post('/tenants/signup', Controller.Signup);
  THorse.Get('/tenants/check-subdomain/:subdomain', Controller.CheckSubdomain);
  THorse.Get('/tenants/current', Controller.GetCurrent);
end;

end.
