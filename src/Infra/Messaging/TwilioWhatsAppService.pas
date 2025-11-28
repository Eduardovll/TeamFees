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
    function SendNewTenantNotification(const PhoneNumber, BusinessName, BusinessType, Plan, AdminName, AdminEmail, AdminPhone: string): Boolean;
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
  Url, CleanPhone, EncodedMessage: string;
  MessageBytes: TBytes;
begin
  Result := False;
  
  CleanPhone := PhoneNumber.Replace('(', '').Replace(')', '').Replace('-', '').Replace(' ', '').Trim;
  if not CleanPhone.StartsWith('55') then
    CleanPhone := '55' + CleanPhone;
  
  // Codificar mensagem preservando UTF-8
  MessageBytes := TEncoding.UTF8.GetBytes(Message);
  EncodedMessage := TNetEncoding.URL.EncodeBytesToString(MessageBytes);
  
  HttpClient := THTTPClient.Create;
  try
    HttpClient.ContentType := 'application/x-www-form-urlencoded; charset=utf-8';
    
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
      '&Body=' + EncodedMessage,
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

function TTwilioWhatsAppService.SendNewTenantNotification(const PhoneNumber, BusinessName, BusinessType, Plan, AdminName, AdminEmail, AdminPhone: string): Boolean;
var
  Message: string;
begin
  Message :=
    '🎉 *NOVO CLIENTE CADASTRADO!*' + #13#10#13#10 +
    '🏢 *EMPRESA*' + #13#10 +
    'Nome: ' + BusinessName + #13#10 +
    'Tipo: ' + BusinessType + #13#10 +
    'Plano: ' + Plan + #13#10 +
    'Data: ' + FormatDateTime('dd/mm/yyyy hh:nn', Now) + #13#10#13#10 +
    '👤 *RESPONSÁVEL*' + #13#10 +
    'Nome: ' + AdminName + #13#10 +
    'Email: ' + AdminEmail + #13#10 +
    'Telefone: ' + AdminPhone + #13#10#13#10 +
    '✅ Conta criada com sucesso!' + #13#10 +
    '_TeamFees SaaS - Notificação Automática_';
  
  Result := SendMessage(PhoneNumber, Message);
end;

end.
