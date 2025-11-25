unit AppComposition;

interface

uses
  System.Classes,
  System.SysUtils,
  System.IOUtils,
  FireDAC.Comp.Client,

  EnvLoader,
  UnitOfWorkFD,
  AppConfig,
  FDConnectionFactory,

  MemberRepositoryFD,
  MemberFeeRepositoryFD,
  PaymentRepositoryFD,

  MemberRepositoryIntf,
  MemberFeeRepositoryIntf,
  PaymentRepositoryIntf,
  UnitOfWorkIntf,
  PixProviderIntf,
  WhatsAppServiceIntf,

  FeesService,
  FeesController,
  MemberController,
  PixController,
  PaymentController,
  MercadoPagoPixProvider,
  TwilioWhatsAppService;

type
  TAppComposition = class
  private
    class var FUnitOfWork: IUnitOfWork;
  public
    class procedure Configure;
    class function GetUnitOfWork: IUnitOfWork;
  end;

implementation

type

  TPixProviderStub = class(TInterfacedObject, IPixProvider)
    function CreateCharge(const UniqueKey: string; const AmountCents: Integer; const Description: string): TPixCharge;
  end;

function TPixProviderStub.CreateCharge(const UniqueKey: string; const AmountCents: Integer; const Description: string): TPixCharge;
begin
  Result.TxId := UniqueKey + '-' + AmountCents.ToString;
  Result.ProviderId := 'stub-' + UniqueKey;
  Result.QrCode := 'QR:DUMMY:' + UniqueKey;
end;

{ TAppComposition }

class procedure TAppComposition.Configure;
var
  Cfg: TAppConfig;
  Conn: TFDConnection;
  UoW: IUnitOfWork;
  Members: IMemberRepository;
  Fees: IMemberFeeRepository;
  Payments: IPaymentRepository;
  Pix: TMercadoPagoPixProvider;
  EnvPath: string;
begin
  // Carrega arquivo .env
  EnvPath := TPath.Combine(ExtractFilePath(ParamStr(0)), '..\..\.env');
  if not TFile.Exists(EnvPath) then
    EnvPath := TPath.Combine(GetCurrentDir, '.env');
  
  LoadEnvFile(EnvPath);
  
  Cfg := TAppConfig.LoadFromEnv;
  Conn := TFDConnectionFactory.CreatePostgres(Cfg);

  FUnitOfWork := TUnitOfWorkFD.Create(Conn);
  UoW := FUnitOfWork;
  Members := TMemberRepositoryFD.Create(Conn);
  Fees := TMemberFeeRepositoryFD.Create(Conn);
  Payments := TPaymentRepositoryFD.Create(Conn);
  Pix := TMercadoPagoPixProvider.Create(Cfg.MercadoPagoToken);

  // Inje��o manual simples
  Writeln('>>> Twilio AccountSID: ', Cfg.TwilioAccountSID);
  Writeln('>>> Twilio AuthToken: ', Copy(Cfg.TwilioAuthToken, 1, 8), '...');
  Writeln('>>> Twilio FromNumber: ', Cfg.TwilioFromNumber);
  
  MemberController.Repo := Members;
  FeesController.FeesSvc := TFeesService.Create(Members, Fees, Payments, UoW, Pix);
  FeesController.WhatsAppSvc := TTwilioWhatsAppService.Create(
    Cfg.TwilioAccountSID,
    Cfg.TwilioAuthToken,
    Cfg.TwilioFromNumber
    // Cfg.TwilioGroupId // Para uso futuro com conta paga (grupos)
  );
  FeesController.FeesRepo := Fees;
  FeesController.MembersRepo := Members;
  PixController.FeesSvc := FeesController.FeesSvc;
  PixController.PixProvider := Pix as TMercadoPagoPixProvider;
  PixController.WhatsAppSvc := FeesController.WhatsAppSvc;
  PixController.FeesRepo := Fees;
  PixController.MembersRepo := Members;

  PaymentController.PayRepo := Payments;
  PaymentController.FeeRepo := Fees;
  PaymentController.MemRepo := Members;
end;

class function TAppComposition.GetUnitOfWork: IUnitOfWork;
begin
  Result := FUnitOfWork;
end;

end.
