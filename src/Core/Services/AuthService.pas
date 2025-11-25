unit AuthService;

interface

uses
  MemberRepositoryIntf,
  AppConfig,
  Member,
  Enums,
  System.SysUtils;

type
  TAuthResult = record
    Success: Boolean;
    Token: string;
    Role: string;
    MemberId: Integer;
    FullName: string;
    Email: string;
    Phone: string;
    ErrorMessage: string;
  end;

  TAuthService = class
  private
    FRepo: IMemberRepository;
    FCfg: TAppConfig;
  public
    constructor Create(const Cfg: TAppConfig; const Repo: IMemberRepository);
    function Login(const Identifier, Password: string): TAuthResult;
  end;

implementation

uses
  BCrypt.Provider,
  JwtProvider;

constructor TAuthService.Create(const Cfg: TAppConfig; const Repo: IMemberRepository);
begin
  FCfg := Cfg;
  FRepo := Repo;
end;

function TAuthService.Login(const Identifier, Password: string): TAuthResult;
var
  M: TMember;
begin
  Result.Success := False;

  // Tenta buscar por email primeiro
  M := FRepo.FindByEmail(Identifier);

  // Se não encontrou, tenta buscar por telefone
  if not Assigned(M) then
    M := FRepo.FindByPhone(Identifier);

  if not Assigned(M) then
  begin
    Result.ErrorMessage := 'Usuário ou senha incorretos.';
    Exit;
  end;

  if not M.IsActive then
  begin
    Result.ErrorMessage := 'Usuário inativo. Entre em contato com o administrador.';
    Exit;
  end;

  if not BCryptVerify(Password, M.PasswordHash) then
  begin
    Result.ErrorMessage := 'Usuário ou senha incorretos.';
    Exit;
  end;

  Result.Token := TJwtProvider.GenerateToken(
    M.Id,
    M.FullName,
    RoleToStr(M.Role),
    M.Email,
    FCfg.JwtSecret
  );

  Result.Success := True;
  Result.Role := RoleToStr(M.Role);
  Result.MemberId := M.Id;
  Result.FullName := M.FullName;
  Result.Email := M.Email;
  Result.Phone := M.PhoneWhatsApp;
end;

end.

