unit MemberController;

interface

uses
  System.SysUtils,
  System.JSON,
  System.Generics.Collections,
  FireDAC.Comp.Client,
  Horse,
  Member,
  MemberRepositoryFD,
  MemberRepositoryIntf;

var
  Repo: IMemberRepository;

procedure RegisterMemberRoutes;

implementation

uses
  RoleGuard, Enums, AppConfig, BCrypt.Provider, JOSE.Core.JWT, JOSE.Core.JWK, JOSE.Core.Builder,
  MemberInvitationRepositoryIntf, MemberInvitationRepositoryFD, EmailService, FDConnectionFactory,
  System.DateUtils, WhatsAppServiceIntf, TwilioWhatsAppService;

procedure GetAllMembers(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Members: TObjectList<TMember>;
  Arr: TJSONArray;
  M: TMember;
  Obj: TJSONObject;
begin
  Members := Repo.GetActive;
  Arr := TJSONArray.Create;
  try
    for M in Members do
    begin
      Obj := TJSONObject.Create;
      Obj.AddPair('id', TJSONNumber.Create(M.Id));
      Obj.AddPair('full_name', M.FullName);
      Obj.AddPair('email', M.Email);
      Obj.AddPair('phone', M.PhoneWhatsApp);
      Obj.AddPair('cpf', M.CPF);
      Obj.AddPair('is_active', TJSONBool.Create(M.IsActive));
      Arr.AddElement(Obj);
    end;
    Res.Send<TJSONArray>(Arr);
  finally
    Members.Free;
  end;
end;

procedure GetMemberById(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  M: TMember;
  Id: Integer;
  Obj: TJSONObject;
begin
  Id := StrToIntDef(Req.Params['id'], 0);
  M := Repo.GetById(Id);
  if not Assigned(M) then
  begin
    Res.Status(404).Send('Member not found');
    Exit;
  end;

  Obj := TJSONObject.Create;
  Obj.AddPair('id', TJSONNumber.Create(M.Id));
  Obj.AddPair('full_name', M.FullName);
  Obj.AddPair('email', M.Email);
  Obj.AddPair('cpf', M.CPF);
  Obj.AddPair('is_active', TJSONBool.Create(M.IsActive));

  Res.Send(Obj);
end;

procedure PutUpdateProfile(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Token: string;
  JWT: TJWT;
  Key: TJWK;
  MemberId: Integer;
  Body: TJSONObject;
  M: TMember;
  FullName, Email, Phone, NewPassword, CurrentPassword: string;
  Cfg: TAppConfig;
begin
  Token := Req.Headers['authorization'].Replace('Bearer ', '').Trim;
  
  if Token = '' then
  begin
    Res.Status(401).Send(TJSONObject.Create.AddPair('error', 'Token inválido'));
    Exit;
  end;

  Cfg := TAppConfig.LoadFromEnv;
  Key := TJWK.Create(Cfg.JwtSecret);
  try
    JWT := TJOSE.Verify(Key, Token);
    if not Assigned(JWT) then
    begin
      Res.Status(401).Send(TJSONObject.Create.AddPair('error', 'Token inválido'));
      Exit;
    end;
    
    MemberId := StrToInt(JWT.Claims.Subject);
  finally
    Key.Free;
  end;
  
  M := Repo.GetById(MemberId);
  if not Assigned(M) then
  begin
    Res.Status(404).Send(TJSONObject.Create.AddPair('error', 'Usuário não encontrado'));
    Exit;
  end;
  
  Body := Req.Body<TJSONObject>;
  FullName := Body.GetValue<string>('full_name', '');
  Email := Body.GetValue<string>('email', '');
  Phone := Body.GetValue<string>('phone', '');
  NewPassword := Body.GetValue<string>('new_password', '');
  CurrentPassword := Body.GetValue<string>('current_password', '');
  
  // Validações
  if FullName = '' then
  begin
    Res.Status(400).Send(TJSONObject.Create.AddPair('error', 'Nome completo é obrigatório'));
    Exit;
  end;
  
  if Email = '' then
  begin
    Res.Status(400).Send(TJSONObject.Create.AddPair('error', 'Email é obrigatório'));
    Exit;
  end;
  
  // Verifica se email já existe (se mudou)
  if Email <> M.Email then
  begin
    var ExistingMember := Repo.FindByEmail(Email);
    if Assigned(ExistingMember) and (ExistingMember.Id <> MemberId) then
    begin
      Res.Status(400).Send(TJSONObject.Create.AddPair('error', 'Email já está em uso'));
      Exit;
    end;
  end;
  
  // Verifica se telefone já existe (se mudou)
  if (Phone <> '') and (Phone <> M.PhoneWhatsApp) then
  begin
    var ExistingMember := Repo.FindByPhone(Phone);
    if Assigned(ExistingMember) and (ExistingMember.Id <> MemberId) then
    begin
      Res.Status(400).Send(TJSONObject.Create.AddPair('error', 'Telefone já está em uso'));
      Exit;
    end;
  end;
  
  // Se quer trocar senha, valida senha atual
  if NewPassword <> '' then
  begin
    if CurrentPassword = '' then
    begin
      Res.Status(400).Send(TJSONObject.Create.AddPair('error', 'Senha atual é obrigatória para trocar a senha'));
      Exit;
    end;
    
    if not BCryptVerify(CurrentPassword, M.PasswordHash) then
    begin
      Res.Status(400).Send(TJSONObject.Create.AddPair('error', 'Senha atual incorreta'));
      Exit;
    end;
    
    if Length(NewPassword) < 6 then
    begin
      Res.Status(400).Send(TJSONObject.Create.AddPair('error', 'Nova senha deve ter no mínimo 6 caracteres'));
      Exit;
    end;
    
    M.PasswordHash := BCryptHash(NewPassword, 12);
  end;
  
  // Atualiza dados
  M.FullName := FullName;
  M.Email := Email;
  M.PhoneWhatsApp := Phone;
  
  Repo.Update(M);
  
  Res.Send(TJSONObject.Create
    .AddPair('message', 'Perfil atualizado com sucesso')
    .AddPair('full_name', M.FullName)
    .AddPair('email', M.Email)
    .AddPair('phone', M.PhoneWhatsApp));
end;

procedure PostCreateMember(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Body: TJSONObject;
  M: TMember;
  FullName, Email, Phone, CPF, RoleStr: string;
  Role: TUserRole;
  Cfg: TAppConfig;
  Conn: TFDConnection;
  InvitationRepo: IMemberInvitationRepository;
  EmailSvc: IEmailService;
  Invitation: TMemberInvitation;
  Token: string;
  DefaultPassword: string;
begin
  Body := Req.Body<TJSONObject>;
  FullName := Body.GetValue<string>('full_name', '');
  Email := Body.GetValue<string>('email', '');
  Phone := Body.GetValue<string>('phone', '');
  CPF := Body.GetValue<string>('cpf', '');
  RoleStr := Body.GetValue<string>('role', 'PLAYER');
  
  // Validações
  if FullName = '' then
  begin
    Res.Status(400).Send(TJSONObject.Create.AddPair('error', 'Nome completo é obrigatório'));
    Exit;
  end;
  
  if CPF = '' then
  begin
    Res.Status(400).Send(TJSONObject.Create.AddPair('error', 'CPF é obrigatório'));
    Exit;
  end;
  
  if (Email = '') and (Phone = '') then
  begin
    Res.Status(400).Send(TJSONObject.Create.AddPair('error', 'Email ou telefone é obrigatório'));
    Exit;
  end;
  
  // Verifica duplicação
  if Assigned(Repo.FindByCPF(CPF)) then
  begin
    Res.Status(400).Send(TJSONObject.Create.AddPair('error', 'CPF já está cadastrado'));
    Exit;
  end;
  
  if (Email <> '') and Assigned(Repo.FindByEmail(Email)) then
  begin
    Res.Status(400).Send(TJSONObject.Create.AddPair('error', 'Email já está em uso'));
    Exit;
  end;
  
  if (Phone <> '') and Assigned(Repo.FindByPhone(Phone)) then
  begin
    Res.Status(400).Send(TJSONObject.Create.AddPair('error', 'Telefone já está em uso'));
    Exit;
  end;
  
  // Converte role
  Role := StrToRole(RoleStr);
  
  Cfg := TAppConfig.LoadFromEnv;
  Conn := TFDConnectionFactory.CreatePostgres(Cfg);
  
  // Cria membro
  M := TMember.Create;
  M.FullName := FullName;
  M.Email := Email;
  M.PhoneWhatsApp := Phone;
  M.CPF := CPF;
  M.Role := Role;
  M.IsActive := True;
  
  // Define senha = últimos 6 dígitos do CPF
  DefaultPassword := Copy(CPF.Replace('.', '').Replace('-', ''), Length(CPF.Replace('.', '').Replace('-', '')) - 5, 6);
  M.PasswordHash := BCryptHash(DefaultPassword, 12);
  
  // Salva membro
  Repo.Add(M);
  
  // Envia credenciais via WhatsApp se tiver telefone
  if Phone <> '' then
  begin
    var WhatsAppSvc: IWhatsAppService := TTwilioWhatsAppService.Create(
      Cfg.TwilioAccountSID,
      Cfg.TwilioAuthToken,
      Cfg.TwilioFromNumber
    );
    
    // Define senha padrão
    DefaultPassword := Copy(Phone, Length(Phone) - 5, 6);
    
    var Message := Format(
      '🎉 *BEM-VINDO AO TEAMFEES!*' + #10#10 +
      '👤 *Nome:* %s' + #10 +
      '📄 *CPF:* %s' + #10 +
      '🔑 *Senha inicial:* %s' + #10 +
      '_(Últimos 6 dígitos do CPF)_' + #10#10 +
      '🌐 *Acesse:* %s' + #10#10 +
      '⚠️ _Altere sua senha no primeiro acesso!_' + #10 +
      '_TeamFees - Gestão de Mensalidades_',
      [FullName, CPF, DefaultPassword, Cfg.FrontendUrl]
    );
    
    // Envia via WhatsApp
    var WppSent := WhatsAppSvc.SendMessage(Phone, Message);
    
    if WppSent then
      Res.Send(TJSONObject.Create
        .AddPair('message', 'Membro criado! Credenciais enviadas via WhatsApp.')
        .AddPair('id', TJSONNumber.Create(M.Id)))
    else
      Res.Send(TJSONObject.Create
        .AddPair('message', Format('Membro criado! Senha: %s (WhatsApp indisponível)', [DefaultPassword]))
        .AddPair('id', TJSONNumber.Create(M.Id)));
  end
  else
  begin
    // Sem telefone - retorna senha na resposta
    Res.Send(TJSONObject.Create
      .AddPair('message', Format('Membro criado! Senha inicial: %s (últimos 6 dígitos do CPF)', [DefaultPassword]))
      .AddPair('id', TJSONNumber.Create(M.Id))
      .AddPair('default_password', DefaultPassword));
  end;
  
  {$REGION 'Email - Desabilitado temporariamente'}
  // TODO: Implementar envio de email quando houver domínio próprio
  // Código pronto para qualquer provedor SMTP (Gmail, Outlook, SendGrid, etc)
  // Configurar no .env: SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASSWORD
  (*
  if Email <> '' then
  begin
    Token := FormatDateTime('yyyymmddhhnnss', Now) + '_' + IntToStr(Random(999999));
    
    Invitation := TMemberInvitation.Create;
    Invitation.MemberId := M.Id;
    Invitation.Token := Token;
    Invitation.ExpiresAt := IncHour(Now, 48);
    
    InvitationRepo := TMemberInvitationRepositoryFD.Create(Conn);
    InvitationRepo.Add(Invitation);
    
    EmailSvc := TEmailService.Create(Cfg);
    EmailSvc.SendActivationEmail(Email, FullName, Token);
  end;
  *)
  {$ENDREGION}
end;

procedure RegisterMemberRoutes;
var
  Cfg: TAppConfig;
begin
  Cfg := TAppConfig.LoadFromEnv;
  
  // Rota para o próprio usuário atualizar seu perfil
  THorse.Put('/profile', PutUpdateProfile);
  
  // Rotas para ADMIN apenas
  THorse.Group
    .Prefix('/members')
    .Use(TRoleGuard.Require(urAdmin, Cfg.JwtSecret))
    .Get('', GetAllMembers)
    .Get('/:id', GetMemberById)
    .Post('', PostCreateMember);
end;

end.
