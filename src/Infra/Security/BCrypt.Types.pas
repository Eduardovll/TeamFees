unit BCrypt.Types;

interface

type
  TBCryptHash = class
  public
    class function CreateHash(const Password: string; Cost: Integer = 12): string;
    class function VerifyHash(const Password, Hash: string): Boolean;
  end;

implementation

uses
  BCrypt.Provider;

class function TBCryptHash.CreateHash(const Password: string; Cost: Integer): string;
begin
  Result := TBCryptProvider.Generate(Password, Cost);
end;

class function TBCryptHash.VerifyHash(const Password, Hash: string): Boolean;
begin
  Result := TBCryptProvider.Verify(Password, Hash);
end;

end.

