unit Money;

interface

type
  TMoney = record
  private
    FCents: Int64;
  public
    class function FromDecimal(const AValue: Double): TMoney; static;
    class function FromCents(const ACents: Int64): TMoney; static;
    function ToDecimal: Double;
    function Cents: Int64;
  end;

implementation

class function TMoney.FromDecimal(const AValue: Double): TMoney;
begin
  Result.FCents := Round(AValue * 100);
end;

class function TMoney.FromCents(const ACents: Int64): TMoney;
begin
  Result.FCents := ACents;
end;

function TMoney.ToDecimal: Double;
begin
  Result := FCents / 100.0;
end;

function TMoney.Cents: Int64;
begin
  Result := FCents;
end;

end.
