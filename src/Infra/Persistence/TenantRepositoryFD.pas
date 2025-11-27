unit TenantRepositoryFD;

interface

uses
  TenantRepositoryIntf, Tenant, FireDAC.Comp.Client, System.SysUtils, System.JSON;

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
    function GetAllTenants: string;
    function UpdateTenantStatus(const ATenantId, AStatus: string): Boolean;
    function RenewTenant(const ATenantId: string; AMonths: Integer): string;
    function UpdateTenant(const ATenantId, ABusinessName, ABusinessType, APlan: string): Boolean;
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

function TTenantRepositoryFD.GetAllTenants: string;
var
  Query: TFDQuery;
  Tenants, Tenant: TJSONObject;
  TenantsArray: TJSONArray;
begin
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FConnection;
    Query.SQL.Text := 'SELECT id::text, subdomain, business_name, business_type, plan, status, trial_ends_at, created_at FROM tenants ORDER BY created_at DESC';
    Query.Open;

    TenantsArray := TJSONArray.Create;
    while not Query.Eof do
    begin
      Tenant := TJSONObject.Create;
      Tenant.AddPair('id', Query.FieldByName('id').AsString);
      Tenant.AddPair('subdomain', Query.FieldByName('subdomain').AsString);
      Tenant.AddPair('business_name', Query.FieldByName('business_name').AsString);
      Tenant.AddPair('business_type', Query.FieldByName('business_type').AsString);
      Tenant.AddPair('plan', Query.FieldByName('plan').AsString);
      Tenant.AddPair('status', Query.FieldByName('status').AsString);
      if not Query.FieldByName('trial_ends_at').IsNull then
        Tenant.AddPair('trial_ends_at', Query.FieldByName('trial_ends_at').AsString)
      else
        Tenant.AddPair('trial_ends_at', TJSONNull.Create);
      Tenant.AddPair('created_at', Query.FieldByName('created_at').AsString);
      TenantsArray.AddElement(Tenant);
      Query.Next;
    end;

    Result := TenantsArray.ToJSON;
    TenantsArray.Free;
  finally
    Query.Free;
  end;
end;

function TTenantRepositoryFD.UpdateTenantStatus(const ATenantId, AStatus: string): Boolean;
var
  Query: TFDQuery;
begin
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FConnection;
    FConnection.StartTransaction;
    try
      Query.SQL.Text := 'UPDATE tenants SET status = :status WHERE id = :id::uuid';
      Query.ParamByName('status').AsString := AStatus;
      Query.ParamByName('id').AsString := ATenantId;
      Query.ExecSQL;
      FConnection.Commit;
      Result := True;
    except
      FConnection.Rollback;
      Result := False;
      raise;
    end;
  finally
    Query.Free;
  end;
end;

function TTenantRepositoryFD.RenewTenant(const ATenantId: string; AMonths: Integer): string;
var
  Query: TFDQuery;
  CurrentExpires, NewExpires: TDateTime;
begin
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FConnection;
    FConnection.StartTransaction;
    try
      Query.SQL.Text := 'SELECT trial_ends_at FROM tenants WHERE id = :id::uuid';
      Query.ParamByName('id').AsString := ATenantId;
      Query.Open;

      if Query.FieldByName('trial_ends_at').IsNull then
        CurrentExpires := Now
      else
        CurrentExpires := Query.FieldByName('trial_ends_at').AsDateTime;

      if CurrentExpires < Now then
        CurrentExpires := Now;

      NewExpires := IncMonth(CurrentExpires, AMonths);

      Query.Close;
      Query.SQL.Text := 'UPDATE tenants SET trial_ends_at = :expires WHERE id = :id::uuid';
      Query.ParamByName('expires').AsDateTime := NewExpires;
      Query.ParamByName('id').AsString := ATenantId;
      Query.ExecSQL;

      FConnection.Commit;
      Result := DateToISO8601(NewExpires);
    except
      FConnection.Rollback;
      raise;
    end;
  finally
    Query.Free;
  end;
end;

function TTenantRepositoryFD.UpdateTenant(const ATenantId, ABusinessName, ABusinessType, APlan: string): Boolean;
var
  Query: TFDQuery;
  SQL: string;
begin
  Query := TFDQuery.Create(nil);
  try
    Query.Connection := FConnection;
    FConnection.StartTransaction;
    try
      SQL := 'UPDATE tenants SET ';
      if ABusinessName <> '' then SQL := SQL + 'business_name = :business_name, ';
      if ABusinessType <> '' then SQL := SQL + 'business_type = :business_type, ';
      if APlan <> '' then SQL := SQL + 'plan = :plan, ';
      SQL := SQL.TrimRight([',', ' ']) + ' WHERE id = :id::uuid';

      Query.SQL.Text := SQL;
      if ABusinessName <> '' then Query.ParamByName('business_name').AsString := ABusinessName;
      if ABusinessType <> '' then Query.ParamByName('business_type').AsString := ABusinessType;
      if APlan <> '' then Query.ParamByName('plan').AsString := APlan;
      Query.ParamByName('id').AsString := ATenantId;
      Query.ExecSQL;

      FConnection.Commit;
      Result := True;
    except
      FConnection.Rollback;
      Result := False;
      raise;
    end;
  finally
    Query.Free;
  end;
end;

end.
