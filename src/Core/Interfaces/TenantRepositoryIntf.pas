unit TenantRepositoryIntf;

interface

uses
  Tenant;

type
  ITenantRepository = interface
    ['{8F3A2B1C-4D5E-6F7A-8B9C-0D1E2F3A4B5C}']
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

implementation

end.
