unit WhatsAppService;

interface

uses
  WhatsAppServiceIntf,
  System.SysUtils,
  WhatsAppModule;

type
  TWhatsAppService = class(TInterfacedObject, IWhatsAppService)
  public
    function SendPaymentReceipt(const PhoneNumber, MemberName: string; FeeId, AmountCents: Integer; const PaidAt: TDateTime): Boolean;
  end;

implementation

function TWhatsAppService.SendPaymentReceipt(const PhoneNumber, MemberName: string; FeeId, AmountCents: Integer; const PaidAt: TDateTime): Boolean;
var
  Message: string;
  Amount: string;
begin
  Result := False;
  
  if not Assigned(WhatsAppDM) then
  begin
    Writeln('>>> WhatsAppDM não inicializado');
    Exit;
  end;
  
  if not WhatsAppDM.IsAuthenticated then
  begin
    Writeln('>>> WhatsApp não autenticado. Escaneie o QR Code.');
    Exit;
  end;
  
  Amount := FormatFloat('#,##0.00', AmountCents / 100);
  
  Message := Format(
    '✅ *COMPROVANTE DE PAGAMENTO*' + sLineBreak + sLineBreak +
    '👤 *Nome:* %s' + sLineBreak +
    '💰 *Valor:* R$ %s' + sLineBreak +
    '📅 *Data do Pagamento:* %s' + sLineBreak +
    '🔢 *ID da Mensalidade:* #%d' + sLineBreak + sLineBreak +
    '✔️ Pagamento confirmado com sucesso!' + sLineBreak +
    '_TeamFees - Gestão de Mensalidades_',
    [MemberName, Amount, FormatDateTime('dd/mm/yyyy hh:nn', PaidAt), FeeId]
  );
  
  Result := WhatsAppDM.SendMessage(PhoneNumber, Message);
end;

end.
