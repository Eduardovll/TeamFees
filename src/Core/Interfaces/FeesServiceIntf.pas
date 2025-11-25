unit FeesServiceIntf;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  System.JSON,
  MemberFee, Enums;

type
  TGenerateCycleInput = record
    Year: Word;
    Month: Word;
    DueDay: Word;
    AmountCents: Integer;
  end;

  IFeesService = interface
    ['{B8B6F4F0-7F48-4E64-8C24-1ED12B8EE8F9}']
    function GenerateCycle(const Input: TGenerateCycleInput): Integer; // retorna CycleId
    function RegeneratePix(const MemberFeeId: Integer): TMemberFee;
    procedure ManualSetPaid(const MemberFeeId: Integer; const AmountCents: Integer);
    procedure ConfirmPixWebhook(const TxId: string; const AmountCents: Integer; const Payload: string);
    function GetSummary: TJSONObject;
    function ListPagedFees(Page, Limit: Integer; const Order, Status: string): TJSONObject;
    function ListMyFees(MemberId, Page, Limit: Integer; const Order, Status: string): TJSONObject;
  end;

implementation

end.
