unit BCrypt;

interface

function BCryptHashPassword(const Password: string; Cost: Integer = 12): string;
function BCryptCheckPassword(const Password, Hash: string): Boolean;

implementation

uses
  BCrypt.Types;

function BCryptHashPassword(const Password: string; Cost: Integer): string;
begin
  Result := TBCryptHash.CreateHash(Password, Cost);
end;

function BCryptCheckPassword(const Password, Hash: string): Boolean;
begin
  Result := TBCryptHash.VerifyHash(Password, Hash);
end;

end.
