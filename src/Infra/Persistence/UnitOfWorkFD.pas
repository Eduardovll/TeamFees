unit UnitOfWorkFD;

interface

uses UnitOfWorkIntf, FireDAC.Comp.Client;

type
  TUnitOfWorkFD = class(TInterfacedObject, IUnitOfWork)
  private
    FConn: TFDConnection;
  public
    constructor Create(const AConn: TFDConnection);
    procedure BeginTran;
    procedure Commit;
    procedure Rollback;
  end;

implementation

constructor TUnitOfWorkFD.Create(const AConn: TFDConnection);
begin
  inherited Create;
  FConn := AConn;
end;

procedure TUnitOfWorkFD.BeginTran;
begin
  if not FConn.InTransaction then FConn.StartTransaction;
end;

procedure TUnitOfWorkFD.Commit;
begin
  if FConn.InTransaction then FConn.Commit;
end;

procedure TUnitOfWorkFD.Rollback;
begin
  if FConn.InTransaction then FConn.Rollback;
end;

end.
