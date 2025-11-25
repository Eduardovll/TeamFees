unit BCrypt.Utils;

interface

uses
  System.SysUtils, System.Classes;

function BCryptBase64Encode(const Input: TBytes): string;
function BCryptBase64Decode(const S: string): TBytes;

implementation

const
  BCRYPT_BASE64_CODE: PAnsiChar =
    './ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

function BCryptBase64Encode(const Input: TBytes): string;
var
  I: Integer;
  C1, C2, C3: Byte;
  O1, O2, O3, O4: Byte;
begin
  Result := '';
  I := 0;

  while I < Length(Input) do
  begin
    C1 := Input[I];
    Inc(I);

    if I < Length(Input) then
    begin
      C2 := Input[I];
      Inc(I);
    end
    else
      C2 := 0;

    if I < Length(Input) then
    begin
      C3 := Input[I];
      Inc(I);
    end
    else
      C3 := 0;

    O1 := C1 shr 2;
    O2 := ((C1 and $03) shl 4) or (C2 shr 4);
    O3 := ((C2 and $0F) shl 2) or (C3 shr 6);
    O4 := C3 and $3F;

    Result := Result +
      Char(BCRYPT_BASE64_CODE[O1]) +
      Char(BCRYPT_BASE64_CODE[O2]) +
      Char(BCRYPT_BASE64_CODE[O3]) +
      Char(BCRYPT_BASE64_CODE[O4]);
  end;
end;

function BCryptBase64Decode(const S: string): TBytes;
var
  I, Len: Integer;
  C1, C2, C3, C4: Integer;
  O1, O2, O3: Byte;
  function Pos64(C: Char): Integer;
  var
    P: PAnsiChar;
  begin
    P := AnsiStrScan(BCRYPT_BASE64_CODE, AnsiChar(C));
    if P = nil then
      raise Exception.CreateFmt('Invalid BCrypt Base64 character: %s', [C]);
    Result := P - BCRYPT_BASE64_CODE;
  end;
begin
  Len := Length(S);
  if Len mod 4 <> 0 then
    raise Exception.Create('Invalid BCrypt Base64 length.');

  SetLength(Result, (Len div 4) * 3);
  I := 1;
  var RPos := 0;

  while I <= Len do
  begin
    C1 := Pos64(S[I]); Inc(I);
    C2 := Pos64(S[I]); Inc(I);
    C3 := Pos64(S[I]); Inc(I);
    C4 := Pos64(S[I]); Inc(I);

    O1 := (C1 shl 2) or (C2 shr 4);
    O2 := ((C2 and $0F) shl 4) or (C3 shr 2);
    O3 := ((C3 and $03) shl 6) or C4;

    Result[RPos] := O1; Inc(RPos);
    Result[RPos] := O2; Inc(RPos);
    Result[RPos] := O3; Inc(RPos);
  end;

  // BCrypt usa comprimento exato do salt/hash
  SetLength(Result, RPos);
end;

end.
