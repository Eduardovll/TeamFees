unit WhatsAppModule;

interface

uses
  System.SysUtils, System.Classes, uTWPPConnect;

type
  TWhatsAppDM = class(TDataModule)
    WPPConnect: TWPPConnect;
    procedure WPPConnectGetQrCode(Sender: TObject; const QrCode: TResultQRCodeClass);
    procedure WPPConnectConnected(Sender: TObject);
    procedure WPPConnectDisconnected(Sender: TObject);
  private
    FAuthenticated: Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    function IsAuthenticated: Boolean;
    function SendMessage(const PhoneNumber, Message: string): Boolean;
  end;

var
  WhatsAppDM: TWhatsAppDM;

implementation

{%CLASSGROUP 'System.Classes.TPersistent'}

{$R *.dfm}

constructor TWhatsAppDM.Create(AOwner: TComponent);
begin
  inherited;
  FAuthenticated := False;
  
  WPPConnect.Config.AutoStart := True;
  WPPConnect.Config.AutoClose := False;
  WPPConnect.Config.Headless := False;
  
  WPPConnect.Connect;
end;

procedure TWhatsAppDM.WPPConnectGetQrCode(Sender: TObject; const QrCode: TResultQRCodeClass);
begin
  Writeln('>>> QR Code gerado. Escaneie com WhatsApp:');
  Writeln(QrCode.Base64);
end;

procedure TWhatsAppDM.WPPConnectConnected(Sender: TObject);
begin
  FAuthenticated := True;
  Writeln('>>> WhatsApp conectado com sucesso!');
end;

procedure TWhatsAppDM.WPPConnectDisconnected(Sender: TObject);
begin
  FAuthenticated := False;
  Writeln('>>> WhatsApp desconectado');
end;

function TWhatsAppDM.IsAuthenticated: Boolean;
begin
  Result := FAuthenticated and WPPConnect.Auth;
end;

function TWhatsAppDM.SendMessage(const PhoneNumber, Message: string): Boolean;
var
  CleanPhone: string;
begin
  Result := False;
  
  if not IsAuthenticated then
  begin
    Writeln('>>> WhatsApp não autenticado');
    Exit;
  end;
  
  CleanPhone := PhoneNumber.Replace('(', '').Replace(')', '').Replace('-', '').Replace(' ', '').Trim;
  if not CleanPhone.StartsWith('55') then
    CleanPhone := '55' + CleanPhone;
  
  CleanPhone := CleanPhone + '@c.us';
  
  try
    WPPConnect.SendTextMessage(CleanPhone, Message);
    Result := True;
  except
    on E: Exception do
      Writeln('>>> Erro ao enviar mensagem: ', E.Message);
  end;
end;

end.
