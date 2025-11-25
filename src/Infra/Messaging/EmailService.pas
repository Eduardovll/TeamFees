unit EmailService;

{$REGION 'Documentação'}
(*
  EmailService - Serviço de envio de emails via SMTP
  
  PRONTO PARA USO COM QUALQUER PROVEDOR SMTP:
  - Gmail (com senha de app)
  - Outlook/Hotmail
  - SendGrid
  - Mailgun
  - Amazon SES
  - Brevo (Sendinblue)
  - Qualquer servidor SMTP customizado
  
  CONFIGURAÇÃO NO .ENV:
  SMTP_HOST=smtp.provedor.com
  SMTP_PORT=587 (ou 465 para SSL implícito)
  SMTP_USER=seu_usuario
  SMTP_PASSWORD=sua_senha_ou_api_key
  SMTP_FROM_EMAIL=remetente@dominio.com
  SMTP_FROM_NAME=Nome do Remetente
  
  SUPORTE:
  - TLS 1.0, 1.1, 1.2
  - TLS Explícito (porta 587) e Implícito (porta 465)
  - Autenticação SMTP
  - HTML emails
*)
{$ENDREGION}

interface

uses
  System.SysUtils, AppConfig;

type
  IEmailService = interface
    ['{A5B3C7D9-1E2F-4A5B-8C9D-0E1F2A3B4C5D}']
    function SendActivationEmail(const ToEmail, ToName, Token: string): Boolean;
  end;

  TEmailService = class(TInterfacedObject, IEmailService)
  private
    FConfig: TAppConfig;
  public
    constructor Create(const AConfig: TAppConfig);
    function SendActivationEmail(const ToEmail, ToName, Token: string): Boolean;
  end;

implementation

uses
  IdSMTP, IdMessage, IdSSLOpenSSL, IdText, IdExplicitTLSClientServerBase, IdSSLOpenSSLHeaders;

constructor TEmailService.Create(const AConfig: TAppConfig);
begin
  inherited Create;
  FConfig := AConfig;
end;

function TEmailService.SendActivationEmail(const ToEmail, ToName, Token: string): Boolean;
var
  SMTP: TIdSMTP;
  Msg: TIdMessage;
  SSL: TIdSSLIOHandlerSocketOpenSSL;
  ActivationUrl: string;
  HtmlBody: string;
begin
  Result := False;
  
  if (ToEmail = '') or (FConfig.SmtpHost = '') then
    Exit;

  ActivationUrl := Format('%s/activate/%s', [FConfig.FrontendUrl, Token]);
  
  HtmlBody := Format(
    '<html><body style="font-family: Arial, sans-serif;">' +
    '<div style="max-width: 600px; margin: 0 auto; padding: 20px;">' +
    '<h2 style="color: #2563eb;">Bem-vindo ao TeamFees!</h2>' +
    '<p>Olá <strong>%s</strong>,</p>' +
    '<p>Você foi convidado para fazer parte do TeamFees. Para ativar sua conta e criar sua senha, clique no botão abaixo:</p>' +
    '<div style="text-align: center; margin: 30px 0;">' +
    '<a href="%s" style="background-color: #2563eb; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">Ativar Conta</a>' +
    '</div>' +
    '<p>Ou copie e cole este link no seu navegador:</p>' +
    '<p style="background-color: #f3f4f6; padding: 10px; border-radius: 5px; word-break: break-all;">%s</p>' +
    '<p style="color: #6b7280; font-size: 12px; margin-top: 30px;">Este link expira em 48 horas.</p>' +
    '<p style="color: #6b7280; font-size: 12px;">Se você não solicitou este convite, ignore este email.</p>' +
    '</div></body></html>',
    [ToName, ActivationUrl, ActivationUrl]
  );

  SMTP := TIdSMTP.Create(nil);
  Msg := TIdMessage.Create(nil);
  SSL := nil;
  
  try
    try
      // Configuração SMTP básica
      SMTP.Host := FConfig.SmtpHost;
      SMTP.Port := FConfig.SmtpPort;
      SMTP.Username := FConfig.SmtpUser;
      SMTP.Password := FConfig.SmtpPassword;
      
      // Tenta configurar SSL apenas se porta for 587 ou 465
      if (FConfig.SmtpPort = 587) or (FConfig.SmtpPort = 465) then
      begin
        SSL := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
        SSL.SSLOptions.SSLVersions := [sslvTLSv1, sslvTLSv1_1, sslvTLSv1_2];
        SSL.SSLOptions.Mode := sslmClient;
        SSL.SSLOptions.VerifyMode := [];
        SSL.SSLOptions.VerifyDepth := 0;
        
        SMTP.IOHandler := SSL;
        
        if FConfig.SmtpPort = 465 then
          SMTP.UseTLS := utUseImplicitTLS
        else
          SMTP.UseTLS := utUseExplicitTLS;
      end
      else
        SMTP.UseTLS := utNoTLSSupport;
      
      // Configuração da mensagem
      Msg.From.Address := FConfig.SmtpFromEmail;
      Msg.From.Name := FConfig.SmtpFromName;
      Msg.Recipients.EMailAddresses := ToEmail;
      Msg.Subject := 'Ative sua conta no TeamFees';
      Msg.ContentType := 'text/html';
      Msg.CharSet := 'UTF-8';
      
      with TIdText.Create(Msg.MessageParts, nil) do
      begin
        Body.Text := HtmlBody;
        ContentType := 'text/html';
        CharSet := 'UTF-8';
      end;
      
      // Envia email
      SMTP.Connect;
      try
        SMTP.Send(Msg);
        Result := True;
        Writeln('>>> Email de ativação enviado para: ', ToEmail);
      finally
        SMTP.Disconnect;
      end;
      
    except
      on E: Exception do
      begin
        Writeln('>>> AVISO: Falha ao enviar email: ', E.Message);
        Writeln('>>> Configure um provedor SMTP válido (SendGrid, Mailgun, etc) ou use Gmail com Senha de App');
        Result := False;
      end;
    end;
  finally
    if Assigned(SSL) then
      SSL.Free;
    Msg.Free;
    SMTP.Free;
  end;
end;

end.
