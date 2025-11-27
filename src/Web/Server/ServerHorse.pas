unit ServerHorse;

interface

uses
  System.SysUtils,
  System.IOUtils,
  System.JSON,
  Horse,
  Horse.CORS,
  Horse.Jhonson,
  Horse.JWT,
  HorseSwaggerStatic,
  ErrorMiddleware,
  TenantMiddleware,
  TenantController,
  TenantRepositoryFD,
  TenantRepositoryIntf,
  MemberRepositoryFD,
  MemberRepositoryIntf,
  FDConnectionFactory,
  FireDAC.Comp.Client,
  FeesController,
  MemberController,
  PixController,
  PaymentController,
  AuthController,
  ActivationController,
  AppConfig;

type
  TServerHorse = class
  public
    class procedure Start;
  end;

implementation

class procedure TServerHorse.Start;
const
  SWAGGER_ROOT = 'C:\TeamFees\src\Web\Docs';
var
  Cfg: TAppConfig;
  JwtCfg: IHorseJWTConfig;
begin
  Cfg := TAppConfig.LoadFromEnv;

  // ==== MIDDLEWARES BASE ====
  THorse.Use(CORS);
  THorse.Use(Jhonson);
  UseErrorMiddleware;

  // ==== ROTAS PÚBLICAS (SEM JWT E SEM TENANT) ====
  RegisterAuthRoutes;   // /auth/login e /auth/me não exigem token
  RegisterActivationRoutes;  // /activate/:token não exige token
  
  // Registrar rotas de tenant (signup é pública, current é protegida)
  var Cfg2 := TAppConfig.LoadFromEnv;
  var Conn2 := TFDConnectionFactory.CreatePostgres(Cfg2);
  var TenantRepo := TTenantRepositoryFD.Create(Conn2);
  var MemberRepo := TMemberRepositoryFD.Create(Conn2);
  RegisterTenantRoutes(TenantRepo, MemberRepo);

  // Rota de teste - comentada
  {THorse.Get('/checkhorse',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Res.Send<TJSONObject>(
        TJSONObject.Create
          .AddPair('status', 'OK')
          .AddPair('message', 'Servidor Horse rodando com sucesso!')
      );
    end
  );}

  // ==== JWT PROTEGE APENAS O QUE VEM DEPOIS ====
  JwtCfg := THorseJWTConfig.New;
  JwtCfg.SkipRoutes(['/auth/login', '/auth/me', '/pix/webhook', '/activate/*', '/tenants/signup', '/tenants/check-subdomain/*']);
  THorse.Use(
    HorseJWT(Cfg.JwtSecret, JwtCfg)
  );
  
  // ==== TENANT MIDDLEWARE (Isolamento de dados - APENAS ROTAS PROTEGIDAS) ====
  THorse.Use(UseTenantMiddleware);
  
  RegisterMemberRoutes;     // /members (JWT + Tenant obrigatório)
  RegisterFeesRoutes(Cfg.JwtSecret, JwtCfg);       // /fees (JWT + Tenant obrigatório + RoleGuard)
  RegisterPixRoutes;        // /pix (JWT + Tenant obrigatório)
  RegisterPaymentRoutes;    // /payments (JWT + Tenant obrigatório)

  // ==== SWAGGER ====
  UseSwaggerDocs('/swagger', SWAGGER_ROOT);

  // ==== START SERVER ====
  // Deploy automático via GitHub Actions - Teste
  THorse.Listen(9000,
    procedure
    begin
      Writeln('=== TeamFees API Server ===');
      Writeln('Porta: 9000');
      Writeln('Deploy automatico v2.0 funcionando!!');
    end
  );
end;

end.

