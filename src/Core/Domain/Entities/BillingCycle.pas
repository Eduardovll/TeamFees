unit BillingCycle;

interface

type
  TBillingCycle = class
  private
    FId: Integer;
    FYear: Word;
    FMonth: Word;
  public
    property Id: Integer read FId write FId;
    property Year: Word read FYear write FYear;
    property Month: Word read FMonth write FMonth;
  end;

implementation

end.
