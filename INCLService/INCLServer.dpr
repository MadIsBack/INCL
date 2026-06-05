program INCLServer;

{%ToDo 'INCLServer.todo'}
{%File 'version.txt'}

uses
//  FastMM4,
  SvcMgr,                                               
  Main in 'Main.pas' {INCLServ: TService},
  DatenM in 'DatenM.pas' {Daten: TDataModule},
  DBMain in 'DBMain.pas',
  Th_Zusatz in 'Th_Zusatz.pas',
  Th_Schicht in 'Th_Schicht.pas',
  VarConst in 'VarConst.pas',
  Arbeit in 'arbeit.pas',
  Th_SignalLog in 'Th_SignalLog.pas',
  Th_DBBackup in 'Th_DBBackup.pas',
  U_SPC in 'U_SPC.pas',
  utils in 'utils.pas';

{$R *.RES}

begin
  Application.Initialize;
//  FUllDebugModeScanMemoryPoolBeforeEveryOperation:= true;
//  FullDebugModeRegisterAllAllocsAsExpectedMemoryLeak:= true;

  Application.CreateForm(TINCLServ, INCLServ);
  Application.CreateForm(TDaten, Daten);
  Application.Run;
end.
