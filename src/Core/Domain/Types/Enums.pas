unit Enums;

interface

type
  TUserRole = (urPlayer, urTreasurer, urAdmin, urSuperAdmin);

  TFeeStatus = (fsOpen, fsPaid, fsLate, fsCanceled, fsExempt);

function RoleToStr(const A: TUserRole): string;
function StrToRole(const S: string): TUserRole;
function FeeStatusToStr(const S: TFeeStatus): string;
function StrToFeeStatus(const S: string): TFeeStatus;

implementation

uses System.SysUtils;

function RoleToStr(const A: TUserRole): string;
begin
  case A of
    urPlayer:     Result := 'PLAYER';
    urTreasurer:  Result := 'TREASURER';
    urAdmin:      Result := 'ADMIN';
    urSuperAdmin: Result := 'SUPER_ADMIN';
  end;
end;

function StrToRole(const S: string): TUserRole;
var U: string;
begin
  U := UpperCase(S);
  if U = 'SUPER_ADMIN' then Exit(urSuperAdmin);
  if U = 'ADMIN' then Exit(urAdmin);
  if U = 'TREASURER' then Exit(urTreasurer);
  Result := urPlayer;
end;

function FeeStatusToStr(const S: TFeeStatus): string;
begin
  case S of
    fsOpen:     Result := 'OPEN';
    fsPaid:     Result := 'PAID';
    fsLate:     Result := 'LATE';
    fsCanceled: Result := 'CANCELED';
    fsExempt:   Result := 'EXEMPT';
  end;
end;

function StrToFeeStatus(const S: string): TFeeStatus;
var U: string;
begin
  U := UpperCase(S);
  if U = 'PAID' then Exit(fsPaid);
  if U = 'LATE' then Exit(fsLate);
  if U = 'CANCELED' then Exit(fsCanceled);
  if U = 'EXEMPT' then Exit(fsExempt);
  Result := fsOpen;
end;

end.
