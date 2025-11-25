unit AuthController;

interface

procedure RegisterAuthRoutes;

implementation

uses
  Horse,
  System.JSON,
  System.SysUtils,
  AuthService,
  MemberRepositoryFD,
  AppConfig,
  BCrypt.Provider,        // <-- BCrypt REAL
  FireDAC.Comp.Client,
  FDConnectionFactory,
  JOSE.Core.JWT;

//
//  POST /auth/login
//
procedure PostLogin(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Body: TJSONObject;
  Email, Password: string;
  Cfg: TAppConfig;
  Service: TAuthService;
  Repo: TMemberRepositoryFD;
  ResultAuth: TAuthResult;
  Conn: TFDConnection;
begin
  Body := Req.Body<TJSONObject>;
  Email := Body.GetValue<string>('identifier'); // Pode ser email ou telefone
  Password := Body.GetValue<string>('password');

  Cfg := TAppConfig.LoadFromEnv;

  Conn := TFDConnectionFactory.CreatePostgres(Cfg);
  Repo := TMemberRepositoryFD.Create(Conn);
  Service := TAuthService.Create(Cfg, Repo);

  ResultAuth := Service.Login(Email, Password);

  if not ResultAuth.Success then
  begin
    Res.Status(401)
       .Send(TJSONObject.Create
         .AddPair('error', ResultAuth.ErrorMessage));
    Exit;
  end;

  Res.Send(
    TJSONObject.Create
      .AddPair('access_token', ResultAuth.Token)
      .AddPair('token_type', 'Bearer')
      .AddPair('role', ResultAuth.Role)
      .AddPair('member_id', IntToStr(ResultAuth.MemberId))
      .AddPair('full_name', ResultAuth.FullName)
      .AddPair('email', ResultAuth.Email)
      .AddPair('phone', ResultAuth.Phone)
      .AddPair('expires_in', TJSONNumber.Create(3600))
  );
end;

//
//  GET /auth/me
//
procedure GetMe(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  JWT: TJWT;
  Role, MemberId, FullName, Email: string;
begin
  JWT := Req.Session<TJWT>;
  Writeln('validei GetMe');
  if JWT = nil then
  begin
    Res.Status(401)
       .Send(TJSONObject.Create.AddPair('error', 'Token inválido ou ausente.'));
    Exit;
  end;

  MemberId := JWT.Claims.Subject;
  Role     := JWT.Claims.JSON.GetValue<string>('role');
  FullName := JWT.Claims.JSON.GetValue<string>('full_name');
  Email    := JWT.Claims.JSON.GetValue<string>('email');

  Res.Send(
    TJSONObject.Create
      .AddPair('id', MemberId)
      .AddPair('full_name', FullName)
      .AddPair('email', Email)
      .AddPair('role', Role)
  );
end;

//
//  GET /auth/test-hash
//
procedure TestHash(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Hash: string;
begin
  Hash := BCryptHash('363839', 12);

  Res.Send(
    TJSONObject.Create
      .AddPair('hash', Hash)
  );
end;


procedure TestCheck(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Ok: Boolean;
  Hash: string;
begin
  Hash := '$2a$12$4u2p/fz6UsebAuTWPg0msu938vlGTO9JKsxMsaFrNksuA2z2yxXg3l'; // copie exatamente o do banco

  Ok := BCryptVerify('363839', Hash);

  if Ok then
    Res.Send('OK � senha correta')
  else
    Res.Send('ERR � senha incorreta');
end;

//
//  Registro de rotas
//
procedure RegisterAuthRoutes;
begin
  THorse.Post('/auth/login', PostLogin);
  THorse.Get('/auth/me', GetMe);
  // Rotas de teste - comentadas
  // THorse.Get('/auth/test-hash', TestHash);
  // THorse.Get('/auth/test-check', TestCheck);
end;

end.

