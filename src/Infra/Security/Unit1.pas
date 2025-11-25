unit Unit1;

interface

uses
  System.SysUtils, System.Classes;

function BCryptEncode(const Input: TBytes): string;
function BCryptDecode(const Input: string): TBytes;

implementation

const
  BCRYPT_ALPHABET = './ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

function BCryptEncode(const Input: TBytes): string;
var
  I: Integer;
  C1, C2, C3: Integer;
  OutStr: string;
begin
  OutStr := '';
  I := 0;

  while I < Length(Input) do
  begin
    C1 := Input[I];
    Inc(I);

    OutStr := OutStr + BCRYPT_ALPHABET[(C1 shr 2) + 1];

    C1 := (C1 and $03) shl 4;

    if I >= Length(Input) then
    begin
      OutStr := OutStr + BCRYPT_ALPHABET[(C1 and $3F) + 1];
      Break;
    end;

    C2 := Input[I];
    Inc(I);
    C1 := C1 or ((C2 shr 4) and $0F);
    OutStr := OutStr + BCRYPT_ALPHABET[(C1 and $3F) + 1];

    C1 := (C2 and $0F) shl 2;

    if I >= Length(Input) then
    begin
      OutStr := OutStr + BCRYPT_ALPHABET[(C1 and $3F) + 1];
      Break;
    end;

    C3 := Input[I];
    Inc(I);

    C1 := C1 or ((C3 shr 6) and $03);
    OutStr := OutStr + BCRYPT_ALPHABET[(C1 and $3F) + 1];
    OutStr := OutStr + BCRYPT_ALPHABET[(C3 and $3F) + 1];
  end;

  Result := OutStr;
end;

function IndexOfChar(const C: Char): Integer;
begin
  Result := Pos(C, BCRYPT_ALPHABET) - 1;
  if Result < 0 then
    raise Exception.CreateFmt('Invalid BCrypt character: %s', [C]);
end;

function BCryptDecode(const Input: string): TBytes;
var
  I: Integer;
  OutList: TBytes;
  O: Integer;
  C1, C2, C3, C4: Integer;
begin
  SetLength(OutList, 0);
  I := 1;

  while I <= Length(Input) do
  begin
    C1 := IndexOfChar(Input[I]);     Inc(I);
    C2 := IndexOfChar(Input[I]);     Inc(I);

    O := Length(OutList);
    SetLength(OutList, O + 1);
    OutList[O] := (C1 shl 2) or ((C2 shr 4) and $03);

    if I > Length(Input) then Break;

    C3 := IndexOfChar(Input[I]);     Inc(I);
    OutList := OutList + [( (C2 and $0F) shl 4) or ((C3 shr 2) and $0F)];

    if I > Length(Input) then Break;

    C4 := IndexOfChar(Input[I]);     Inc(I);
    OutList := OutList + [ ((C3 and $03) shl 6) or (C4 and $3F) ];
  end;

  Result := OutList;
end;

end.
