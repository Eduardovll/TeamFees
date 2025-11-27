unit Tenant;

interface

uses
  System.SysUtils;

type
  TTenantPlan = (tpTrial, tpBasic, tpPro, tpPremium);
  TTenantStatus = (tsActive, tsSuspended, tsCancelled);
  TBusinessType = (btAcademia, btTime, btEscola, btEstudio, btCorrida, btOutro);

  TTenant = class
  private
    FId: string;
    FBusinessName: string;
    FBusinessType: TBusinessType;
    FCNPJ: string;
    FSubdomain: string;
    FPlan: TTenantPlan;
    FStatus: TTenantStatus;
    FTrialEndsAt: TDateTime;
    FMaxMembers: Integer;
    FCreatedAt: TDateTime;
    FUpdatedAt: TDateTime;
  public
    property Id: string read FId write FId;
    property BusinessName: string read FBusinessName write FBusinessName;
    property BusinessType: TBusinessType read FBusinessType write FBusinessType;
    property CNPJ: string read FCNPJ write FCNPJ;
    property Subdomain: string read FSubdomain write FSubdomain;
    property Plan: TTenantPlan read FPlan write FPlan;
    property Status: TTenantStatus read FStatus write FStatus;
    property TrialEndsAt: TDateTime read FTrialEndsAt write FTrialEndsAt;
    property MaxMembers: Integer read FMaxMembers write FMaxMembers;
    property CreatedAt: TDateTime read FCreatedAt write FCreatedAt;
    property UpdatedAt: TDateTime read FUpdatedAt write FUpdatedAt;
  end;

function BusinessTypeToStr(AType: TBusinessType): string;
function StrToBusinessType(const AStr: string): TBusinessType;
function PlanToStr(APlan: TTenantPlan): string;
function StrToPlan(const AStr: string): TTenantPlan;
function StatusToStr(AStatus: TTenantStatus): string;

implementation

function BusinessTypeToStr(AType: TBusinessType): string;
begin
  case AType of
    btAcademia: Result := 'academia';
    btTime: Result := 'time';
    btEscola: Result := 'escola';
    btEstudio: Result := 'estudio';
    btCorrida: Result := 'corrida';
    btOutro: Result := 'outro';
  end;
end;

function StrToBusinessType(const AStr: string): TBusinessType;
begin
  if AStr = 'academia' then Result := btAcademia
  else if AStr = 'time' then Result := btTime
  else if AStr = 'escola' then Result := btEscola
  else if AStr = 'estudio' then Result := btEstudio
  else if AStr = 'corrida' then Result := btCorrida
  else Result := btOutro;
end;

function PlanToStr(APlan: TTenantPlan): string;
begin
  case APlan of
    tpTrial: Result := 'trial';
    tpBasic: Result := 'basic';
    tpPro: Result := 'pro';
    tpPremium: Result := 'premium';
  end;
end;

function StrToPlan(const AStr: string): TTenantPlan;
begin
  if AStr = 'trial' then Result := tpTrial
  else if AStr = 'basic' then Result := tpBasic
  else if AStr = 'pro' then Result := tpPro
  else if AStr = 'premium' then Result := tpPremium
  else Result := tpTrial;
end;

function StatusToStr(AStatus: TTenantStatus): string;
begin
  case AStatus of
    tsActive: Result := 'active';
    tsSuspended: Result := 'suspended';
    tsCancelled: Result := 'cancelled';
  end;
end;

end.
