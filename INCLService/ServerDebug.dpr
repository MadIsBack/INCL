program ServerDebug;

{%ToDo 'ServerDebug.todo'}
{%File 'version.txt'}


uses
  Forms,
  Service_Debug in 'Service_Debug.pas' {Form1},
  Arbeit in 'arbeit.pas',
  DBMain in 'DBMain.pas',
  Main in 'Main.pas' {INCLServ: TService},
  DatenM in 'DatenM.pas',
  U_Metall in 'U_Metall.pas',
  U_SPC in 'U_SPC.pas',
  Th_Schicht in 'Th_Schicht.pas',
  SQL_fuc in 'SQL_fuc.pas',
  Th_Zusatz in 'Th_Zusatz.pas',
  Th_SignalLog in 'Th_SignalLog.pas',
  Th_DBBackup in 'Th_DBBackup.pas',
  SPCUtility in 'SPCUtility.pas',
  utils in 'utils.pas';

{$R *.res}

begin
  Application.Initialize;
//  FUllDebugModeScanMemoryPoolBeforeEveryOperation:= true;
//  FullDebugModeRegisterAllAllocsAsExpectedMemoryLeak:= true;


  Application.Title := 'Server Debug';
  Application.CreateForm(TForm1, Form1);
  Form1.Left := 50;
  Form1.Top := 50;
  Application.CreateForm(TDaten, Daten);
  Application.CreateForm(TINCLServ, INCLServ);
  Application.Run;
end.

