unit TwilioWhatsAppService;

interface

uses
  WhatsAppServiceIntf,
  System.SysUtils,
  System.Classes,
  System.Net.HttpClient,
  System.Net.URLClient,
  System.NetEncoding;

type
  TTwilioWhatsAppService = class(TInterfacedObject, IWhatsAppService)
  private
    FAccountSID: string;
    FAuthToken: string;
    FFromNumber: string;
    // FGroupId: string; // Para uso futuro com conta paga (grupos)
  public
    constructor Create(const AccountSID, AuthToken, FromNumber: string);
    function SendPaymentReceipt(const PhoneNumber, MemberName: string; FeeId, AmountCents: Integer; const PaidAt: TDateTime): Boolean;
    function SendMessage(const PhoneNumber, Message: string): Boolean;
    function SendNewTenantNotification(const PhoneNumber, BusinessName, BusinessType, Plan, Subdomain, AdminName, AdminEmail, AdminPhone: string): Boolean;
  end;

implementation

constructor TTwilioWhatsAppService.Create(const AccountSID, AuthToken, FromNumber: string);
begin
  FAccountSID := AccountSID;
  FAuthToken := AuthToken;
  FFromNumber := FromNumber;
  // FGroupId := GroupId; // Para uso futuro com conta paga (grupos)
end;

function TTwilioWhatsAppService.SendPaymentReceipt(const PhoneNumber, MemberName: string; FeeId, AmountCents: Integer; const PaidAt: TDateTime): Boolean;
var
  HttpClient: THTTPClient;
  Response: IHTTPResponse;
  RequestBody: TStringStream;
  Url, CleanPhone, Message, Amount, Auth: string;
begin
  Result := False;
  
  CleanPhone := PhoneNumber.Replace('(', '').Replace(')', '').Replace('-', '').Replace(' ', '').Trim;
  if not CleanPhone.StartsWith('55') then
    CleanPhone := '55' + CleanPhone;
  
  Amount := FormatFloat('#,##0.00', AmountCents / 100);
  
  Message := Format(
    '💰 *PAGAMENTO CONFIRMADO*' + #10#10 +
    '👤 *Jogador:* %s' + #10 +
    '💵 *Valor:* R$ %s' + #10 +
    '📅 *Data:* %s' + #10 +
    '🔢 *Mensalidade:* #%d' + #10#10 +
    '✅ Pagamento via PIX confirmado!' + #10 +
    '_TeamFees - Gestao de Mensalidades_',
    [MemberName, Amount, FormatDateTime('dd/mm/yyyy hh:nn', PaidAt), FeeId]
  );
  
  HttpClient := THTTPClient.Create;
  try
    HttpClient.ContentType := 'application/x-www-form-urlencoded';
    
    Url := Format('https://api.twilio.com/2010-04-01/Accounts/%s/Messages.json', [FAccountSID]);
    
    HttpClient.CredentialsStorage.AddCredential(
      TCredentialsStorage.TCredential.Create(
        TAuthTargetType.Server,
        '',
        Url,
        FAccountSID,
        FAuthToken
      )
    );
    
    RequestBody := TStringStream.Create(
      'From=' + TNetEncoding.URL.Encode('whatsapp:' + FFromNumber) +
      '&To=' + TNetEncoding.URL.Encode('whatsapp:+' + CleanPhone) +
      // Para grupos (conta paga): '&To=' + TNetEncoding.URL.Encode('whatsapp:' + FGroupId) +
      '&Body=' + TNetEncoding.URL.Encode(Message),
      TEncoding.UTF8
    );
    try
      Response := HttpClient.Post(Url, RequestBody);
      Result := (Response.StatusCode = 200) or (Response.StatusCode = 201);
      
      if not Result then
        Writeln('>>> Erro Twilio: ', Response.StatusCode, ' - ', Response.ContentAsString);
    finally
      RequestBody.Free;
    end;
  finally
    HttpClient.Free;
  end;
end;

function TTwilioWhatsAppService.SendMessage(const PhoneNumber, Message: string): Boolean;
var
  HttpClient: THTTPClient;
  Response: IHTTPResponse;
  RequestBody: TStringStream;
  Url, CleanPhone: string;
begin
  Result := False;
  
  CleanPhone := PhoneNumber.Replace('(', '').Replace(')', '').Replace('-', '').Replace(' ', '').Trim;
  if not CleanPhone.StartsWith('55') then
    CleanPhone := '55' + CleanPhone;
  
  HttpClient := THTTPClient.Create;
  try
    HttpClient.ContentType := 'application/x-www-form-urlencoded';
    
    Url := Format('https://api.twilio.com/2010-04-01/Accounts/%s/Messages.json', [FAccountSID]);
    
    HttpClient.CredentialsStorage.AddCredential(
      TCredentialsStorage.TCredential.Create(
        TAuthTargetType.Server,
        '',
        Url,
        FAccountSID,
        FAuthToken
      )
    );
    
    RequestBody := TStringStream.Create(
      'From=' + TNetEncoding.URL.Encode('whatsapp:' + FFromNumber) +
      '&To=' + TNetEncoding.URL.Encode('whatsapp:+' + CleanPhone) +
      '&Body=' + TNetEncoding.URL.Encode(Message),
      TEncoding.UTF8
    );
    try
      Response := HttpClient.Post(Url, RequestBody);
      Result := (Response.StatusCode = 200) or (Response.StatusCode = 201);
      
      if Result then
        Writeln('>>> WhatsApp enviado para: +', CleanPhone)
      else
        Writeln('>>> Erro Twilio: ', Response.StatusCode, ' - ', Response.ContentAsString);
    finally
      RequestBody.Free;
    end;
  finally
    HttpClient.Free;
  end;
end;

function TTwilioWhatsAppService.SendNewTenantNotification(const PhoneNumber, BusinessName, BusinessType, Plan, Subdomain, AdminName, AdminEmail, AdminPhone: string): Boolean;
var
  Message: string;
begin
  Message := Format(
    '🎉 *NOVO TENANT CADASTRADO!*' + #10#10 +
    '🏢 *Empresa:* %s' + #10 +
    '📋 *Tipo:* %s' + #10 +
    '💎 *Plano:* %s' + #10 +
    '🌐 *Subdomínio:* %s' + #10 +
    '📅 *Data:* %s' + #10#10 +
    '👤 *DADOS DO RESPONSÁVEL*' + #10 +
    '📛 *Nome:* %s' + #10 +
    '📧 *Email:* %s' + #10 +
    '📱 *Telefone:* %s' + #10#10 +
    '✅ Conta criada com sucesso!' + #10 +
    '_TeamFees SaaS - Notificação Automática_',
    [BusinessName, BusinessType, Plan, Subdomain, FormatDateTime('dd/mm/yyyy hh:nn', Now), AdminName, AdminEmail, AdminPhone]
  );
  
  Result := SendMessage(PhoneNumber, Message);
end;

end.
