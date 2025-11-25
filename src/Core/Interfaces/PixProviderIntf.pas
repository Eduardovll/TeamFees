unit PixProviderIntf;

interface

type
  TPixCharge = record
    TxId: string;
    ProviderId: string;
    QrCode: string;
  end;

  IPixProvider = interface
    ['{4A7C1AA1-5A0B-4D5B-9A76-8B56D62B4C42}']
    function CreateCharge(const UniqueKey: string; const AmountCents: Integer; const Description: string): TPixCharge;
  end;

implementation

end.
