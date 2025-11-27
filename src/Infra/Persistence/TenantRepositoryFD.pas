unit TenantRepositoryFD;

interface

uses
  TenantRepositoryIntf, Tenant, FireDAC.Comp.Client, System.SysUtils;

type
  TTenantRepositoryFD = class(TInterfacedObject, ITenantRepository)
  private
    FConnection: TFDConnection;
  public
    constructor Create(AConnection: TFDConnection);
    function CreateTenant(ATenant: TTenant): string;
    function FindById(const AId: string): TTenant;
    function FindBySubdomain(const ASubdomain: string): TTenant;
    function SubdomainExists(const ASubdomain: string): Boolean;
    function GetMemberCount(const ATenantId: string): Integer;
    function CanAddMember(const ATenantId: string): Boolean;
  end;

function StrToTenantStatus(const AStr: string): TTenantStatus;

implementation

uses
  System.DateUtils;

constructor TTenantRepositoryFD.Create(AConnection: TFDConnection);
begin
  FConnection := AConnection;
end;

function TTenantRepositoryFD.CreateTenant(ATenant: TTenant): string;
var
  Query: TFDQuery;
begin
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FConnection;
    Query.SQL.Text :=
      'INSERT INTO tenants (business_name, business_type, cnpj, subdomain, plan, status, trial_ends_at, settings) ' +
      'VALUES (:business_name, :business_type, :cnpj, :subdomain, :plan, :status, :trial_ends_at, ' +
      'jsonb_build_object(''max_members'', :max_members, ''features'', ARRAY[''basic_billing'', ''pix'', ''whatsapp''])) ' +
      'RETURNING id::text';

    Query.ParamByName('business_name').AsString := ATenant.BusinessName;
    Query.ParamByName('business_type').AsString := BusinessTypeToStr(ATenant.BusinessType);
    Query.ParamByName('cnpj').AsString := ATenant.CNPJ;
    Query.ParamByName('subdomain').AsString := ATenant.Subdomain;
    Query.ParamByName('plan').AsString := PlanToStr(ATenant.Plan);
    Query.ParamByName('status').AsString := StatusToStr(ATenant.Status);
    Query.ParamByName('trial_ends_at').AsDateTime := ATenant.TrialEndsAt;
    Query.ParamByName('max_members').AsInteger := ATenant.MaxMembers;

    Query.Open;
    Result := Query.FieldByName('id').AsString;
  finally
    Query.Free;
  end;
end;

function TTenantRepositoryFD.FindById(const AId: string): TTenant;
var
  Query: TFDQuery;
begin
  Result := nil;
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FConnection;
    Query.SQL.Text := 'SELECT id::text as id, business_name, business_type, cnpj, subdomain, plan, status, trial_ends_at, created_at, updated_at FROM tenants WHERE id = :id::uuid';
    Query.ParamByName('id').AsString := AId;
    Query.Open;

    if not Query.IsEmpty then
    begin
      Result := TTenant.Create;
      Result.Id := Query.FieldByName('id').AsString;
      Result.BusinessName := Query.FieldByName('business_name').AsString;
      Result.BusinessType := StrToBusinessType(Query.FieldByName('business_type').AsString);
      Result.CNPJ := Query.FieldByName('cnpj').AsString;
      Result.Subdomain := Query.FieldByName('subdomain').AsString;
      Result.Plan := StrToPlan(Query.FieldByName('plan').AsString);
      Result.Status := StrToTenantStatus(Query.FieldByName('status').AsString);
      Result.TrialEndsAt := Query.FieldByName('trial_ends_at').AsDateTime;
      Result.CreatedAt := Query.FieldByName('created_at').AsDateTime;
    end;
  finally
    Query.Free;
  end;
end;

function TTenantRepositoryFD.FindBySubdomain(const ASubdomain: string): TTenant;
var
  Query: TFDQuery;
begin
  Result := nil;
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FConnection;
    Query.SQL.Text := 'SELECT id::text as id, business_name, business_type, cnpj, subdomain, plan, status, trial_ends_at, created_at, updated_at FROM tenants WHERE subdomain = :subdomain';
    Query.ParamByName('subdomain').AsString := ASubdomain;
    Query.Open;

    if not Query.IsEmpty then
    begin
      Result := TTenant.Create;
      Result.Id := Query.FieldByName('id').AsString;
      Result.BusinessName := Query.FieldByName('business_name').AsString;
      Result.BusinessType := StrToBusinessType(Query.FieldByName('business_type').AsString);
      Result.CNPJ := Query.FieldByName('cnpj').AsString;
      Result.Subdomain := Query.FieldByName('subdomain').AsString;
      Result.Plan := StrToPlan(Query.FieldByName('plan').AsString);
      Result.Status := StrToTenantStatus(Query.FieldByName('status').AsString);
      Result.TrialEndsAt := Query.FieldByName('trial_ends_at').AsDateTime;
      Result.CreatedAt := Query.FieldByName('created_at').AsDateTime;
    end;
  finally
    Query.Free;
  end;
end;

function TTenantRepositoryFD.SubdomainExists(const ASubdomain: string): Boolean;
var
  Query: TFDQuery;
begin
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FConnection;
    Query.SQL.Text := 'SELECT COUNT(*) as total FROM tenants WHERE subdomain = :subdomain';
    Query.ParamByName('subdomain').AsString := ASubdomain;
    Query.Open;
    Result := Query.FieldByName('total').AsInteger > 0;
  finally
    Query.Free;
  end;
end;

function TTenantRepositoryFD.GetMemberCount(const ATenantId: string): Integer;
var
  Query: TFDQuery;
begin
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FConnection;
    Query.SQL.Text := 'SELECT COUNT(*) as total FROM member WHERE tenant_id = :tenant_id::uuid AND is_active = true';
    Query.ParamByName('tenant_id').AsString := ATenantId;
    Query.Open;
    Result := Query.FieldByName('total').AsInteger;
  finally
    Query.Free;
  end;
end;

function TTenantRepositoryFD.CanAddMember(const ATenantId: string): Boolean;
var
  Query: TFDQuery;
  CurrentCount, MaxMembers: Integer;
begin
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FConnection;
    Query.SQL.Text := 'SELECT (settings->>''max_members'')::int as max_members FROM tenants WHERE id = :id::uuid';
    Query.ParamByName('id').AsString := ATenantId;
    Query.Open;
    
    MaxMembers := Query.FieldByName('max_members').AsInteger;
    CurrentCount := GetMemberCount(ATenantId);
    
    Result := CurrentCount < MaxMembers;
  finally
    Query.Free;
  end;
end;

function StrToTenantStatus(const AStr: string): TTenantStatus;
begin
  if AStr = 'active' then Result := tsActive
  else if AStr = 'suspended' then Result := tsSuspended
  else if AStr = 'cancelled' then Result := tsCancelled
  else Result := tsActive;
end;

end.
