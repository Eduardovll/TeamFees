unit FDConnectionFactory;

interface

uses FireDAC.Stan.Async, FireDAC.DApt, FireDAC.Comp.Client, AppConfig;

type
  TFDConnectionFactory = class
  public
    class function CreatePostgres(const Cfg: TAppConfig): TFDConnection; static;
  end;

implementation

uses FireDAC.Phys.PG, FireDAC.Stan.Def, System.SysUtils;

class function TFDConnectionFactory.CreatePostgres(const Cfg: TAppConfig): TFDConnection;
var
  Conn: TFDConnection;
begin
  Conn := TFDConnection.Create(nil);
  Conn.Params.DriverID := 'PG';
  Conn.Params.Values['Server'] := Cfg.DBHost;
  Conn.Params.Values['Port'] := Cfg.DBPort;
  Conn.Params.Database := Cfg.DBName;
  Conn.Params.UserName := Cfg.DBUser;
  Conn.Params.Password := Cfg.DBPass;
  Conn.LoginPrompt := False;
  Conn.Connected := True;
  Result := Conn;
end;

end.
