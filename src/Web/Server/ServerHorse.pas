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

  // ==== ROTAS PÚBLICAS ====
  RegisterAuthRoutes;   // /auth/login e /auth/me não exigem token
  RegisterActivationRoutes;  // /activate/:token não exige token

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
  JwtCfg.SkipRoutes(['/auth/login', '/auth/me', '/pix/webhook', '/activate/*']);
  THorse.Use(
    HorseJWT(Cfg.JwtSecret, JwtCfg)
  );
  
  RegisterMemberRoutes;     // /members (JWT obrigatório)
  RegisterFeesRoutes(Cfg.JwtSecret, JwtCfg);       // /fees (JWT obrigatório + RoleGuard)
  RegisterPixRoutes;        // /pix (JWT obrigatório)
  RegisterPaymentRoutes;    // /payments (JWT obrigatório)

  // ==== SWAGGER ====
  UseSwaggerDocs('/swagger', SWAGGER_ROOT);

  // ==== START SERVER ====
  THorse.Listen(9000,
    procedure
    begin
      Writeln('Servidor Horse iniciado na porta 9000');
      Writeln('http://localhost:9000/checkhorse');
    end
  );
end;

end.

