unit ActivationController;

interface

uses Horse;

procedure RegisterActivationRoutes;

implementation

uses
  System.SysUtils, System.JSON, System.DateUtils,
  AppConfig, FDConnectionFactory, FireDAC.Comp.Client,
  MemberRepositoryIntf, MemberRepositoryFD,
  MemberInvitationRepositoryIntf, MemberInvitationRepositoryFD,
  BCrypt.Provider, Member;

procedure PostActivate(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Token, Password: string;
  Body: TJSONObject;
  Cfg: TAppConfig;
  Conn: TFDConnection;
  InvitationRepo: IMemberInvitationRepository;
  MemberRepo: IMemberRepository;
  Invitation: TMemberInvitation;
  M: TMember;
begin
  Token := Req.Params['token'];
  Body := Req.Body<TJSONObject>;
  Password := Body.GetValue<string>('password', '');
  
  if Password = '' then
  begin
    Res.Status(400).Send(TJSONObject.Create.AddPair('error', 'Senha é obrigatória'));
    Exit;
  end;
  
  if Length(Password) < 6 then
  begin
    Res.Status(400).Send(TJSONObject.Create.AddPair('error', 'Senha deve ter no mínimo 6 caracteres'));
    Exit;
  end;
  
  Cfg := TAppConfig.LoadFromEnv;
  Conn := TFDConnectionFactory.CreatePostgres(Cfg);
  
  InvitationRepo := TMemberInvitationRepositoryFD.Create(Conn);
  Invitation := InvitationRepo.GetByToken(Token);
  
  if not Assigned(Invitation) then
  begin
    Res.Status(404).Send(TJSONObject.Create.AddPair('error', 'Convite não encontrado'));
    Exit;
  end;
  
  if Invitation.ActivatedAt > 0 then
  begin
    Res.Status(400).Send(TJSONObject.Create.AddPair('error', 'Este convite já foi utilizado'));
    Exit;
  end;
  
  if Now > Invitation.ExpiresAt then
  begin
    Res.Status(400).Send(TJSONObject.Create.AddPair('error', 'Este convite expirou'));
    Exit;
  end;
  
  // Atualiza senha do membro
  MemberRepo := TMemberRepositoryFD.Create(Conn);
  M := MemberRepo.GetById(Invitation.MemberId);
  
  if not Assigned(M) then
  begin
    Res.Status(404).Send(TJSONObject.Create.AddPair('error', 'Membro não encontrado'));
    Exit;
  end;
  
  M.PasswordHash := BCryptHash(Password, 12);
  MemberRepo.Update(M);
  
  // Marca convite como ativado
  InvitationRepo.MarkAsActivated(Token);
  
  Res.Send(TJSONObject.Create
    .AddPair('message', 'Conta ativada com sucesso! Você já pode fazer login.')
    .AddPair('email', M.Email));
end;

procedure RegisterActivationRoutes;
begin
  THorse.Post('/activate/:token', PostActivate);
end;

end.
