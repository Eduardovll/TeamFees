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
  
  TGenerateCustomFeesInput = record
    MemberIds: TArray<Integer>;  // Array de IDs dos membros (vazio = todos)
    AmountCents: Integer;
    DueDate: TDateTime;
    Reference: string;  // Ex: "Mensalidade Dez/2024"
    MonthsCount: Integer;  // Quantos meses gerar (1 = apenas 1 mês)
  end;
  
  TGenerateCustomFeesResult = record
    TotalCreated: Integer;
    TotalSkipped: Integer;
    SkippedMembers: TArray<string>;  // Nomes dos membros que já tinham mensalidade
  end;

  IFeesService = interface
    ['{B8B6F4F0-7F48-4E64-8C24-1ED12B8EE8F9}']
    function GenerateCycle(const Input: TGenerateCycleInput): Integer; // retorna CycleId
    function GenerateCustomFees(const Input: TGenerateCustomFeesInput): TGenerateCustomFeesResult;
    function RegeneratePix(const MemberFeeId: Integer): TMemberFee;
    procedure ManualSetPaid(const MemberFeeId: Integer; const AmountCents: Integer);
    procedure ConfirmPixWebhook(const TxId: string; const AmountCents: Integer; const Payload: string);
    function GetSummary: TJSONObject;
    function ListPagedFees(Page, Limit: Integer; const Order, Status: string; const MemberId: Integer = 0): TJSONObject;
    function ListMyFees(MemberId, Page, Limit: Integer; const Order, Status: string): TJSONObject;
    procedure SetFeeExempt(const FeeId: Integer; const Reason: string);
  end;

implementation

end.
