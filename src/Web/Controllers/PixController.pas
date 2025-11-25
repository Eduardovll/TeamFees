unit PixController;

interface

uses Horse, System.SysUtils, System.JSON, FeesServiceIntf, MercadoPagoPixProvider, AppConfig,
  WhatsAppServiceIntf, MemberFeeRepositoryIntf, MemberRepositoryIntf, Enums;

var 
  FeesSvc: IFeesService;
  PixProvider: TMercadoPagoPixProvider;
  WhatsAppSvc: IWhatsAppService;
  FeesRepo: IMemberFeeRepository;
  MembersRepo: IMemberRepository;

procedure RegisterPixRoutes;

implementation

procedure PostWebhook(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  B, Data: TJSONObject;
  PaymentId, TxId, Action, PaymentStatus, ExternalReference: string;
  ValorCents: Integer;
begin
  Writeln('>>> Webhook Mercado Pago recebido');
  B := Req.Body<TJSONObject>;
  Writeln('>>> Payload: ', B.ToJSON);
  
  // Mercado Pago envia: {"action": "payment.updated", "data": {"id": "123456"}}
  Action := B.GetValue<string>('action', '');
  
  if (Action <> 'payment.updated') and (Action <> 'payment.created') then
  begin
    Writeln('>>> Action ignorada: ', Action);
    Res.Status(200).Send('OK');
    Exit;
  end;
  
  // Extrai o ID do pagamento
  Data := B.GetValue<TJSONObject>('data');
  if not Assigned(Data) then
  begin
    Writeln('>>> Data não encontrado');
    Res.Status(400).Send('Data inválido');
    Exit;
  end;
  
  PaymentId := Data.GetValue<string>('id', '');
  
  if PaymentId = '' then
  begin
    Writeln('>>> PaymentId vazio');
    Res.Status(400).Send('PaymentId inválido');
    Exit;
  end;
  
  // Busca detalhes do pagamento na API do Mercado Pago
  Writeln('>>> Buscando detalhes do pagamento: ', PaymentId);
  if not PixProvider.GetPaymentDetails(PaymentId, ExternalReference, ValorCents, PaymentStatus) then
  begin
    Writeln('>>> Erro ao buscar detalhes do pagamento');
    Res.Status(500).Send('Erro ao buscar detalhes');
    Exit;
  end;
  
  Writeln('>>> ExternalReference: ', ExternalReference);
  Writeln('>>> ValorCents: ', ValorCents);
  Writeln('>>> Status: ', PaymentStatus);
  
  // Só processa se o pagamento foi aprovado
  if PaymentStatus <> 'approved' then
  begin
    Writeln('>>> Pagamento não aprovado, ignorando');
    Res.Status(200).Send('OK');
    Exit;
  end;
  
  TxId := ExternalReference;
  
  Writeln('>>> Processando pagamento TxId: ', TxId);
  FeesSvc.ConfirmPixWebhook(TxId, ValorCents, B.ToJSON);
  
  // Envia notificação WhatsApp para todos os ADMINs
  try
    var Fee := FeesRepo.GetByPixTxId(TxId);
    if Assigned(Fee) then
    begin
      var PayerMember := MembersRepo.GetById(Fee.MemberId);
      if Assigned(PayerMember) and Assigned(WhatsAppSvc) then
      begin
        // Busca todos os membros ADMIN e envia notificação
        var AllMembers := MembersRepo.GetActive;
        try
          for var Admin in AllMembers do
          begin
            if (Admin.Role = urAdmin) and (Admin.PhoneWhatsApp <> '') then
            begin
              WhatsAppSvc.SendPaymentReceipt(Admin.PhoneWhatsApp, PayerMember.FullName, Fee.Id, Fee.Amount.Cents, Fee.PaidAt);
              Writeln('>>> Notificação WhatsApp enviada para admin: ', Admin.FullName);
            end;
          end;
        finally
          AllMembers.Free;
        end;
        PayerMember.Free;
      end;
      Fee.Free;
    end;
  except
    on E: Exception do
      Writeln('>>> Erro ao enviar WhatsApp: ', E.Message);
  end;
  
  Res.Status(200).Send('OK');
end;

procedure RegisterPixRoutes;
begin
  THorse.Post('/pix/webhook', PostWebhook); // p�blico; valide assinatura do PSP depois
end;

end.
