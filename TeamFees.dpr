program TeamFees;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  AppComposition,
  ServerHorse;

begin
  try
    ReportMemoryLeaksOnShutdown := True;

    TAppComposition.Configure;
    TServerHorse.Start;

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.

