unit UnitOfWorkIntf;

interface

type
  IUnitOfWork = interface
    ['{A36B48A8-3C0E-4B8A-9A4A-1C7B6E239C10}']
    procedure BeginTran;
    procedure Commit;
    procedure Rollback;
  end;

implementation

end.
