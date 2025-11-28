unit WhatsAppServiceIntf;

interface

type
  IWhatsAppService = interface
    ['{8F3A5B2C-9D4E-4F1A-B8C6-7E2D3A1F5C8B}']
    function SendPaymentReceipt(const PhoneNumber, MemberName: string; FeeId, AmountCents: Integer; const PaidAt: TDateTime): Boolean;
    function SendMessage(const PhoneNumber, Message: string): Boolean;
    function SendNewTenantNotification(const PhoneNumber, BusinessName, BusinessType, Plan, AdminName, AdminEmail, AdminPhone: string): Boolean;
  end;

implementation

end.
