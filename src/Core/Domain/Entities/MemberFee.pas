unit MemberFee;

interface

uses Money, Enums, System.SysUtils;

type
  TMemberFee = class
  private
    FId: Integer;
    FMemberId: Integer;
    FCycleId: Integer;
    FAmount: TMoney;
    FStatus: TFeeStatus;
    FPixTxId: string;
    FPixQrCode: string;
    FPixProviderId: string;
    FDueDate: TDateTime;
    FPaidAt: TDateTime;
    FExemptReason: string;
  public
    property Id: Integer read FId write FId;
    property MemberId: Integer read FMemberId write FMemberId;
    property CycleId: Integer read FCycleId write FCycleId;
    property Amount: TMoney read FAmount write FAmount;
    property Status: TFeeStatus read FStatus write FStatus;
    property PixTxId: string read FPixTxId write FPixTxId;
    property PixQrCode: string read FPixQrCode write FPixQrCode;
    property PixProviderId: string read FPixProviderId write FPixProviderId;
    property DueDate: TDateTime read FDueDate write FDueDate;
    property PaidAt: TDateTime read FPaidAt write FPaidAt;
    property ExemptReason: string read FExemptReason write FExemptReason;
  end;

implementation

end.
