unit AdminTenantsController;

interface

uses
  Horse, System.JSON, System.SysUtils,
  TenantRepositoryIntf;

type
  TAdminTenantsController = class
  private
    FTenantRepo: ITenantRepository;
  public
    constructor Create(ATenantRepo: ITenantRepository);
    procedure GetAllTenants(Req: THorseRequest; Res: THorseResponse);
    procedure UpdateTenantStatus(Req: THorseRequest; Res: THorseResponse);
    procedure RenewTenant(Req: THorseRequest; Res: THorseResponse);
    procedure UpdateTenant(Req: THorseRequest; Res: THorseResponse);
  end;

implementation

constructor TAdminTenantsController.Create(ATenantRepo: ITenantRepository);
begin
  FTenantRepo := ATenantRepo;
end;

procedure TAdminTenantsController.GetAllTenants(Req: THorseRequest; Res: THorseResponse);
begin
  Res.Send(FTenantRepo.GetAllTenants);
end;

procedure TAdminTenantsController.UpdateTenantStatus(Req: THorseRequest; Res: THorseResponse);
var
  TenantId, NewStatus: string;
  Body: TJSONObject;
begin
  TenantId := Req.Params['id'];
  Body := Req.Body<TJSONObject>;
  
  if not Body.TryGetValue<string>('status', NewStatus) then
  begin
    Res.Status(400).Send(TJSONObject.Create.AddPair('error', 'Status é obrigatório'));
    Exit;
  end;

  if not (NewStatus.ToUpper.Equals('ACTIVE') or NewStatus.ToUpper.Equals('SUSPENDED')) then
  begin
    Res.Status(400).Send(TJSONObject.Create.AddPair('error', 'Status inválido'));
    Exit;
  end;

  if FTenantRepo.UpdateTenantStatus(TenantId, NewStatus.ToLower) then
    Res.Send(TJSONObject.Create.AddPair('message', 'Status atualizado com sucesso'))
  else
    Res.Status(500).Send(TJSONObject.Create.AddPair('error', 'Erro ao atualizar status'));
end;

procedure TAdminTenantsController.RenewTenant(Req: THorseRequest; Res: THorseResponse);
var
  TenantId, NewExpiresAt: string;
  Body: TJSONObject;
  Months: Integer;
begin
  TenantId := Req.Params['id'];
  Body := Req.Body<TJSONObject>;
  
  if not Body.TryGetValue<Integer>('months', Months) then
    Months := 1;

  NewExpiresAt := FTenantRepo.RenewTenant(TenantId, Months);
  Res.Send(TJSONObject.Create
    .AddPair('message', 'Plano renovado com sucesso')
    .AddPair('new_expires_at', NewExpiresAt));
end;

procedure TAdminTenantsController.UpdateTenant(Req: THorseRequest; Res: THorseResponse);
var
  TenantId, BusinessName, BusinessType, Plan: string;
  Body: TJSONObject;
begin
  TenantId := Req.Params['id'];
  Body := Req.Body<TJSONObject>;

  BusinessName := '';
  BusinessType := '';
  Plan := '';
  
  Body.TryGetValue<string>('business_name', BusinessName);
  Body.TryGetValue<string>('business_type', BusinessType);
  Body.TryGetValue<string>('plan', Plan);

  if FTenantRepo.UpdateTenant(TenantId, BusinessName, BusinessType, Plan) then
    Res.Send(TJSONObject.Create.AddPair('message', 'Tenant atualizado com sucesso'))
  else
    Res.Status(500).Send(TJSONObject.Create.AddPair('error', 'Erro ao atualizar tenant'));
end;

end.
