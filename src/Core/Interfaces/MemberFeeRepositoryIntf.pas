unit MemberFeeRepositoryIntf;

interface

uses
  System.JSON,
  System.Generics.Collections,
  Enums,
  MemberFee;

type
  IMemberFeeRepository = interface
    ['{6E0D1D8F-2D4B-4A0F-8A30-37B2B4C9B2B9}']
    function GetByMemberAndCycle(const MemberId, CycleId: Integer): TMemberFee;
    procedure Add(const Fee: TMemberFee);
    procedure Update(const Fee: TMemberFee);
    function GetByCycle(const CycleId: Integer; const Status: TFeeStatus): TObjectList<TMemberFee>;
    function GetByPixTxId(const ATxId: string): TMemberFee;
    function FindById(const Id: Integer): TMemberFee;
    function GetSummary: TJSONObject;
    function GetDebtors: TJSONArray;
    function ListPaged(Page, Limit: Integer; Order: string; const Status: string; const MemberId: Integer = 0): TJSONObject;
    function ListPagedByMember(MemberId, Page, Limit: Integer; Order: string; const Status: string): TJSONObject;
    procedure SetExempt(const FeeId: Integer; const Reason: string);
    procedure Delete(const FeeId: Integer);
  end;

implementation

end.
