unit EnvLoader;

interface

procedure LoadEnvFile(const FileName: string);

implementation

uses
  System.SysUtils, System.Classes, System.IOUtils
  {$IFDEF MSWINDOWS}
  , Winapi.Windows
  {$ENDIF}
  {$IFDEF POSIX}
  , Posix.Stdlib
  {$ENDIF}
  ;

procedure LoadEnvFile(const FileName: string);
var
  Lines: TStringList;
  CurrentLine, Key, Value: string;
  EqualPos, I: Integer;
begin
  if not TFile.Exists(FileName) then
  begin
    Writeln('>>> Arquivo .env nao encontrado: ', FileName);
    Exit;
  end;

  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(FileName);
    
    for I := 0 to Lines.Count - 1 do
    begin
      CurrentLine := Trim(Lines[I]);
      
      if (CurrentLine = '') or CurrentLine.StartsWith('#') then
        Continue;
      
      EqualPos := Pos('=', CurrentLine);
      if EqualPos > 0 then
      begin
        Key := Trim(Copy(CurrentLine, 1, EqualPos - 1));
        Value := Trim(Copy(CurrentLine, EqualPos + 1, Length(CurrentLine)));
        
        {$IFDEF MSWINDOWS}
        Winapi.Windows.SetEnvironmentVariable(PChar(Key), PChar(Value));
        {$ENDIF}
        {$IFDEF POSIX}
        Posix.Stdlib.setenv(MarshaledAString(UTF8String(Key)), MarshaledAString(UTF8String(Value)), 1);
        {$ENDIF}
      end;
    end;
    
    Writeln('>>> Arquivo .env carregado com sucesso!');
  finally
    Lines.Free;
  end;
end;

end.
