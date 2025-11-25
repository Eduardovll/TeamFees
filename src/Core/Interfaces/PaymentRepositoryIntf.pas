unit PaymentRepositoryIntf;

interface

uses
  System.Generics.Collections,
  Payment;

type
  IPaymentRepository = interface
    ['{0E3A20E6-EB0F-4D04-9E3B-97A6D7462C1B}']
    procedure Add(const P: TPayment);
    function FindById(const Id: Integer): TPayment;
    function ListAll: TObjectList<TPayment>;
  end;

implementation

end.
