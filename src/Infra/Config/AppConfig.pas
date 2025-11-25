unit AppConfig;

interface

type
  TAppConfig = class
  public
    DBHost, DBPort, DBName, DBUser, DBPass: string;
    JwtSecret: string;
    HttpPort: Integer;
    PixWebhookSecret: string;
    MercadoPagoToken: string;
    TwilioAccountSID: string;
    TwilioAuthToken: string;
    TwilioFromNumber: string;
    TwilioGroupId: string;
    SmtpHost: string;
    SmtpPort: Integer;
    SmtpUser: string;
    SmtpPassword: string;
    SmtpFromName: string;
    SmtpFromEmail: string;
    FrontendUrl: string;
    class function LoadFromEnv: TAppConfig; static;
  end;

implementation

uses System.SysUtils;

class function TAppConfig.LoadFromEnv: TAppConfig;
begin
  Result := TAppConfig.Create;
  Result.DBHost := GetEnvironmentVariable('DB_HOST');
  Result.DBPort := GetEnvironmentVariable('DB_PORT');
  Result.DBName := GetEnvironmentVariable('DB_NAME');
  Result.DBUser := GetEnvironmentVariable('DB_USER');
  Result.DBPass := GetEnvironmentVariable('DB_PASS');
  Result.JwtSecret := GetEnvironmentVariable('JWT_SECRET');
  Result.HttpPort := StrToIntDef(GetEnvironmentVariable('HTTP_PORT'), 9000);
  Result.PixWebhookSecret := GetEnvironmentVariable('PIX_WEBHOOK_SECRET');
  Result.MercadoPagoToken := GetEnvironmentVariable('MERCADOPAGO_ACCESS_TOKEN');
  Result.TwilioAccountSID := GetEnvironmentVariable('TWILIO_ACCOUNT_SID');
  Result.TwilioAuthToken := GetEnvironmentVariable('TWILIO_AUTH_TOKEN');
  Result.TwilioFromNumber := GetEnvironmentVariable('TWILIO_FROM_NUMBER');
  Result.TwilioGroupId := GetEnvironmentVariable('TWILIO_GROUP_ID');
  Result.SmtpHost := GetEnvironmentVariable('SMTP_HOST');
  Result.SmtpPort := StrToIntDef(GetEnvironmentVariable('SMTP_PORT'), 587);
  Result.SmtpUser := GetEnvironmentVariable('SMTP_USER');
  Result.SmtpPassword := GetEnvironmentVariable('SMTP_PASSWORD');
  Result.SmtpFromName := GetEnvironmentVariable('SMTP_FROM_NAME');
  Result.SmtpFromEmail := GetEnvironmentVariable('SMTP_FROM_EMAIL');
  Result.FrontendUrl := GetEnvironmentVariable('FRONTEND_URL');
end;

end.
