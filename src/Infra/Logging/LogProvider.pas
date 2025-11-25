unit LogProvider;

interface

type
  ILog = interface
    ['{E9E8A9C7-70E2-41B0-9266-1C8F9A3F8235}']
    procedure Info(const Msg: string);
    procedure Error(const Msg: string);
  end;

  TConsoleLog = class(TInterfacedObject, ILog)
  public
    procedure Info(const Msg: string);
    procedure Error(const Msg: string);
  end;

implementation

uses System.SysUtils;

procedure TConsoleLog.Info(const Msg: string);
begin
  Writeln('[INFO] ' + Msg);
end;

procedure TConsoleLog.Error(const Msg: string);
begin
  Writeln('[ERROR] ' + Msg);
end;

end.
