unit Payment;

interface

type
  TPayment = class
  private
    FId: Integer;
    FMemberFeeId: Integer;
    FAmountCents: Integer;
    FMethod: string; // 'PIX' | 'CASH' | 'TRANSFER'
    FTransactionId: string;
    FPaidAt: TDateTime;
    FCreatedAt: TDateTime;
  public
    property Id: Integer read FId write FId;
    property MemberFeeId: Integer read FMemberFeeId write FMemberFeeId;
    property AmountCents: Integer read FAmountCents write FAmountCents;
    property Method: string read FMethod write FMethod;
    property TransactionId: string read FTransactionId write FTransactionId;
    property PaidAt: TDateTime read FPaidAt write FPaidAt;
    property CreatedAt: TDateTime read FCreatedAt write FCreatedAt;
  end;

implementation

end.
