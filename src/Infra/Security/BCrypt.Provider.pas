unit BCrypt.Provider;

interface

uses
  System.SysUtils, BCrypt.Crypto, BCrypt.Base64;

function BCryptHash(const Password: string; Cost: Integer = 12): string;
function BCryptVerify(const Password, Hash: string): Boolean;

implementation

function RandomSalt: TBytes;
var
  I: Integer;
begin
  SetLength(Result, 16);
  for I := 0 to 15 do
    Result[I] := Random(256);
end;

function BCryptHashInternal(const Password: string; const Salt: TBytes; Cost: Integer): TBytes;
const
  Magic: RawByteString = 'OrpheanBeholderScryDoubt';
var
  BF: TBlowfish;
  KeyBytes: TBytes;
  Block: TBytes;
  I: Integer;
  L, R: Cardinal;
begin
  KeyBytes := TEncoding.UTF8.GetBytes(Password + #0);
  BF := TBlowfish.Create(KeyBytes, Salt, Cost);
  SetLength(Result, 24);

  for I := 0 to 2 do
  begin
    Block := Copy(BytesOf(Magic), I*8, 8);

    L := (Block[0] shl 24) or (Block[1] shl 16) or (Block[2] shl 8) or Block[3];
    R := (Block[4] shl 24) or (Block[5] shl 16) or (Block[6] shl 8) or Block[7];

    BF.EncryptBlock(L, R);

    Result[I*8+0] := (L shr 24) and $FF;
    Result[I*8+1] := (L shr 16) and $FF;
    Result[I*8+2] := (L shr 8) and $FF;
    Result[I*8+3] :=  L        and $FF;

    Result[I*8+4] := (R shr 24) and $FF;
    Result[I*8+5] := (R shr 16) and $FF;
    Result[I*8+6] := (R shr 8)  and $FF;
    Result[I*8+7] :=  R         and $FF;
  end;

  BF.Free;
end;

function BCryptHash(const Password: string; Cost: Integer): string;
var
  Salt, Hash: TBytes;
begin
  Salt := RandomSalt;
  Hash := BCryptHashInternal(Password, Salt, Cost);

  Result :=
    Format('$2a$%.2d$%s%s',
      [ Cost,
        BCryptEncode(Salt),
        BCryptEncode(Hash)
      ]);
end;

function BCryptVerify(const Password, Hash: string): Boolean;
var
  Cost: Integer;
  SaltStr, HashStr: string;
  Salt, HashBytes, CompareBytes: TBytes;
begin
  Result := False;

  if not Hash.StartsWith('$2a$') then Exit;

  Cost := StrToIntDef(Hash.Substring(4, 2), -1);
  if Cost < 4 then Exit;

  SaltStr := Hash.Substring(7, 22);
  HashStr := Hash.Substring(29);

  Salt := BCryptDecode(SaltStr);
  HashBytes := BCryptDecode(HashStr);

  CompareBytes := BCryptHashInternal(Password, Salt, Cost);

  Result := CompareMem(@HashBytes[0], @CompareBytes[0], Length(HashBytes));
end;

end.

