unit RepositoryIntf;

interface

type
  IRepository<T: class> = interface
    ['{8912A8C3-6504-4B47-9B26-0A3F5965D7C1}']
    function GetById(const Id: Integer): T;
    procedure Add(const AEntity: T);
    procedure Update(const AEntity: T);
  end;

implementation

end.
