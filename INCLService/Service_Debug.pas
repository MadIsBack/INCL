unit Service_Debug;

interface

uses
  SysUtils, Arbeit, DBMain, Main, Forms, Classes, Buttons, ComCtrls, StdCtrls,
  Controls, DB, Grids, DBGrids, ExtCtrls, CO_SpinEdit_V63, Spin, CO_DataBase,
  ValEdit, Windows;

type
  TForm1 = class(TForm)
    CheckBox1: TCheckBox;
    Timer1: TTimer;
    Button4: TButton;
    Button3: TButton;
    Button1: TButton;
    Button2: TButton;
    Button5: TButton;
    Backup: TButton;
    StartDT: TDateTimePicker;
    Label1: TLabel;
    ListBox1: TListBox;
    btn1: TButton;
    lblInfo: TLabel;
    Button6: TButton;
    Button7: TButton;
    MemTimer: TTimer;
    Button8: TButton;
    CO_SpinEdit1: TCO_SpinEdit;
    Button9: TButton;
    procedure Button1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure BackupClick(Sender: TObject);
    procedure btn1Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure MemTimerTimer(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure Button9Click(Sender: TObject);

  private
    procedure SetDBUser;
  public
  end;

var
  Form1: TForm1;
  S7Main: TS7Main = nil;

implementation

uses
  SQL_fuc, Sprache_V63, Dialogs, DatenM, Maindll, Th_Schicht, DateUtils,
  SyncObjs, Th_Zusatz, Th_DBBackup, CO_Setup2, IniFiles, Utils, U_SPC;

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
  ListBox1.Items.Insert(0, DateTimeTostr(Now) + ':' +CurrentProcessMemory_KB);
  Application.ProcessMessages;
  Daten.Database.Connected := False;
  Daten.Database.UserName := DBUser;
  Daten.Database.Password := DBPass;
  Daten.Database.Server := DBServer;
  Daten.Database.InitialCatalog := DBInitialCatalog;

  Left := 100;
  Top := 0;
  CheckBox1.Checked := False;
  Button1.ENABLED := False;

  try
    S7Main := TS7Main.Create(Self);
  except
  end;

  Main.S7Main := S7Main;
  CheckBox1.Checked := True;
  CheckBox1.Caption := 'Service running';
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if S7Main <> nil then
    S7Main.Destroy;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin

  SetDBUser;
  CSLog := TCriticalSection.Create;
  Caption := 'Service [' + DBUser + ']';
  CheckBox1.Caption := DBUser;

  StartDT.DateTime := N_o_w - 1;
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  Tim: TDateTime;
begin
  Button2.ENABLED := False;
  INCLUDIS_HOME := 'c:\comtas\1\';
  Daten.Database.UserName := DBUser;
  Daten.Database.Password := DBPass;
  Daten.Database.Server := DBServer;

  Thread_Schicht := TThread_Schicht.Create(True);

  SQLGet(Daten.qSuch, 'SETUP', 'Nr', '1', True);
  SpracheNr := Daten.qSuch.FieldByName('Sprache').AsInteger;
  Sprache2 := Daten.qSuch.FieldByName('Sprache2').AsInteger;
  Sprache_Format := Daten.qSuch.FieldByName('Sprache_Format').AsInteger;
  Verpackt_Aus_Ausschuss := Daten.qSuch.FieldByName('Verpackt_Aus_Ausschuss').AsInteger = 1;
  Anzahl_Masch := Daten.qSuch.FieldByName('anzahl_masch').AsInteger;
  Packen := Daten.qSuch.FieldByName('Packen').AsInteger = 1;
  Stillstaende_Schicht := Daten.qSuch.FieldByName('SchichtStillstaende_berechnen').AsInteger;
  Shift_Model := Daten.qSuch.FieldByName('Shift_Model').AsInteger;
  Schicht1 := Daten.qSuch.FieldByName('Schicht1').AsInteger / 1440;
  Schicht2 := Daten.qSuch.FieldByName('Schicht2').AsInteger / 1440;
  Schicht3 := Daten.qSuch.FieldByName('Schicht3').AsInteger / 1440;
  Heizungskontrolle := Daten.qSuch.FieldByName('heating_control').AsInteger = 1;
  SpannzeitUeberwachen := Daten.qSuch.FieldByName('Spannzeit').AsInteger = 1;

  try
    TimeZone := Daten.qSuch.FieldByName('TimeZone').AsInteger;
  except
    TimeZone := 0;
  end;

  MakeEnviroment(Daten.qUpdate);

  K_Init(Daten.qUpdate);

  CCC_SetSchichtKonstante;

  LoadSignals(Daten.qUpdate);

  Tim := N_o_w;

  // Thread_Schicht.TPM_Stillog_Korrektur(100, 100);
  try
    S7Main := TS7Main.Create(Self);
  except
  end;
  Thread_Schicht.Recalculate_Mode := True;
  Thread_Schicht.Recalculation;
 // Main.S7Main := S7Main;
  //Thread_Schicht.TPM_Schicht_Schicht3;
  //lblInfo.Caption := 'SPC schichtberechung';
  //Application.ProcessMessages;
//  SPC_Schichtberechnung( 3, Thread_Schicht.ThSPC);
 // Thread_Schicht.Free;
  MessageDlg(TimeToStr(N_o_w - Tim), mtInformation, [mbOK], 0);
//   lblInfo.Caption := 'Ende';
  Application.ProcessMessages;
//  Exit;

  lblInfo.Caption := 'Korrektur';
  Application.ProcessMessages;
  Thread_Schicht.TPM_Korrektur(N_o_w - 5, N_o_w, False, '');
  lblInfo.Caption := 'Ende';
  Application.ProcessMessages;
  Exit;


  lblInfo.Caption := 'Verpackt';
  Application.ProcessMessages;
  Thread_Schicht.Berechne_TPM_Schicht_Verpackt_Ausschuss(5, '');

  lblInfo.Caption := 'Auswertung';
  Application.ProcessMessages;
  Thread_Schicht.Berechne_TPM_Auswertung(N_o_w - 5, N_o_w, '');

  lblInfo.Caption := 'Proddetail';
  Application.ProcessMessages;
  Thread_Schicht.Berechne_TPM_Produktionsdetail(5, '');

  lblInfo.Caption := 'Auftragsdetail';
  Application.ProcessMessages;
  Thread_Schicht.Berechne_TPM_Auftragsdetail(5, '');

  lblInfo.Caption := 'Done';
  Application.ProcessMessages;

  Thread_Schicht.Free;
  MessageDlg(TimeToStr(N_o_w - Tim), mtInformation, [mbOK], 0);

  Close;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FreeAndNil(CSLog);
end;

procedure TForm1.Button3Click(Sender: TObject);
var i : integer;
    start : TDateTime;
begin
  Daten.Database.UserName := DBUser;
  Daten.Database.Password := DBPass;
  Daten.Database.Server := DBServer;
  start := Now;
  SQLGet(Daten.qSuch, 'SETUP', 'Nr', '1', True);
  SpracheNr := Daten.qSuch.FieldByName('Sprache').AsInteger;
  Sprache2 := Daten.qSuch.FieldByName('Sprache2').AsInteger;
  Sprache_Format := Daten.qSuch.FieldByName('Sprache_Format').AsInteger;
  Verpackt_Aus_Ausschuss := Daten.qSuch.FieldByName('Verpackt_Aus_Ausschuss').AsInteger = 1;
  Anzahl_Masch := Daten.qSuch.FieldByName('anzahl_masch').AsInteger;
  barcodepzewerkstatt := Daten.qSuch.FieldByName('barcodepzewerkstatt').AsInteger = 1;

  Shift_Model := Daten.qSuch.FieldByName('Shift_Model').AsInteger;
  Schicht1 := Daten.qSuch.FieldByName('Schicht1').AsInteger / 1440;
  Schicht2 := Daten.qSuch.FieldByName('Schicht2').AsInteger / 1440;
  Schicht3 := Daten.qSuch.FieldByName('Schicht3').AsInteger / 1440;
  Heizungskontrolle := Daten.qSuch.FieldByName('heating_control').AsInteger = 1;
  SpannzeitUeberwachen := Daten.qSuch.FieldByName('Spannzeit').AsInteger = 1;
  try
    TimeZone := Daten.qSuch.FieldByName('TimeZone').AsInteger;
  except
    TimeZone := 0;
  end;

  SHORT_DELAY_AUTO_BOOK := Daten.qSuch.FieldByName('SHORT_DELAY_AUTO_BOOK').AsInteger = 1;
  SHORT_DELAY_AUTO_BOOK_VALUE := Daten.qSuch.FieldByName('SHORT_DELAY_AUTO_BOOK_VALUE').AsInteger;
  buchen_arbeitsfrei_bis := Daten.qSuch.FieldByName('buchen_arbeitsfrei_bis').AsInteger = 1;
  OptionPlanung := Daten.qSuch.FieldByName('Planung').AsInteger = 1;

  MakeEnviroment(Daten.qUpdate);

  K_Init(Daten.qUpdate);

  CCC_SetSchichtKonstante;

  Thread_Zusatz := TThread_Zusatz.Create(True);
  sleep(2000);
  LoadSignals(daten.qSuch);

  
//  Thread_Zusatz.TaktMitteln(true);
  // Thread_Zusatz.Autoterminierung;
   // Thread_Zusatz.StartProgramme;
  //  CCC_MDEWerte_fuellen;
  //  PulseEvent(Event_Zusatz);
  //  Thread_Zusatz.Laufzeit_Berechnen;
  //  Thread_Zusatz.CheckVerpacktProt;
//    Thread_Zusatz.ArbeitsFrei_Buchen;
//  Thread_Zusatz.Book_Short_Delay;
  //  Thread_Zusatz.Taktzeit_Personal;
//  Thread_Zusatz.CheckPackSchicht(30);
 // i := Thread_Zusatz.CheckPackSchicht(10);
  //ShowMessage(IntToStr(i));
//  Thread_Zusatz.CalcPackedlogFromShiftlog(42480);
//  Thread_Zusatz.CalcPackedlogFromShiftlog;
//  Thread_Zusatz.StartProgramme;
 Thread_Zusatz.Reschedule;

 // Thread_Zusatz.Job_No_to_Downtime_Log;
  //Thread_Zusatz.CheckSollstueck;
  // Thread_Zusatz.CalcPackedlogFromShiftlog;
  // Thread_Zusatz.CheckPackSchicht(TCO_Setup.GetParamInt(Daten.qSuch, 'INCL_Verpackt_Schicht_Nachberechnen'));

 // RuestStillstandNrUngeplant := 141;
//  RuestenIstGeplant := True;
 // Thread_Zusatz.UnscheduledSetup;

  //Thread_Zusatz.CheckPackSchicht(3);
  ShowMessage('Ende : ' + IntToStr(Round((now-start)*1440*60)) + ' secs');
  Application.Terminate;
end;

procedure TForm1.Button4Click(Sender: TObject);
var
  F: TextFile;
  startdate, enddate: TDateTime;
  days: Integer;
begin
  Button4.ENABLED := False;


  Daten.Database.UserName := DBUser;
  Daten.Database.Password := DBPass;
  Daten.Database.Server := DBServer;

  Thread_Schicht := TThread_Schicht.Create(True);

  SQLGet(Daten.qSuch, 'SETUP', 'Nr', '1', True);
  SpracheNr := Daten.qSuch.FieldByName('Sprache').AsInteger;
  Sprache2 := Daten.qSuch.FieldByName('Sprache2').AsInteger;
  Sprache_Format := Daten.qSuch.FieldByName('Sprache_Format').AsInteger;
  Verpackt_Aus_Ausschuss := Daten.qSuch.FieldByName('Verpackt_Aus_Ausschuss').AsInteger = 1;
  Anzahl_Masch := Daten.qSuch.FieldByName('anzahl_masch').AsInteger;
  Packen := Daten.qSuch.FieldByName('Packen').AsInteger = 1;

  Shift_Model := Daten.qSuch.FieldByName('Shift_Model').AsInteger;
  Schicht1 := Daten.qSuch.FieldByName('Schicht1').AsInteger / 1440;
  Schicht2 := Daten.qSuch.FieldByName('Schicht2').AsInteger / 1440;
  Schicht3 := Daten.qSuch.FieldByName('Schicht3').AsInteger / 1440;

  startdate := StartDT.Date + Schicht1 / 60;
  enddate := Trunc(N_o_w)  + 1;
  days := round(enddate - startdate);

  try
    TimeZone := Daten.qSuch.FieldByName('TimeZone').AsInteger;
  except
    TimeZone := 0;
  end;
  INCLUDIS_HOME := ExtractFilePath(Application.ExeName);
  MakeEnviroment(Daten.qUpdate);
  ListBox1.Items.Clear;
  ListBox1.Items.Add(DateTimeToStr(N_o_w) + ' : Start Init');
  Application.ProcessMessages;
  K_Init(Daten.qUpdate);
  ListBox1.Items.Add(DateTimeToStr(N_o_w) + ' : Start Schichtkonstante');
  Application.ProcessMessages;
  CCC_SetSchichtKonstante;

  ListBox1.Items.Add(DateTimeToStr(N_o_w) + ' : Load Signals');
  SchreibeMeldung(DateTimeToStr(N_o_w) + ' : Load Signals', 2);
  Application.ProcessMessages;
  LoadSignals(Daten.qSuch);

  ListBox1.Items.Add(DateTimeToStr(N_o_w) + ' : Start Stillkorrektur');
  SchreibeMeldung(DateTimeToStr(N_o_w) + ' : Start Stillkorrektur', 2);
  Application.ProcessMessages;
  Thread_Schicht.TPM_Stillog_Korrektur(180, days);

  ListBox1.Items.Add(DateTimeToStr(N_o_w) + ' : Start Schichtkorrektur');
  SchreibeMeldung(DateTimeToStr(N_o_w) + ' : Start Schichtkorrektur', 2);
  Application.ProcessMessages;
  Thread_Schicht.TPM_Schicht_Pruefen(days);

  ListBox1.Items.Add(DateTimeToStr(N_o_w) + ' : Start TPM Korrektur');
  SchreibeMeldung(DateTimeToStr(N_o_w) + ' : Start TPM Korrektur', 2);
  Application.ProcessMessages;
  Thread_Schicht.TPM_Korrektur(trunc(startdate),trunc(enddate), false, '');

  ListBox1.Items.Add(DateTimeToStr(N_o_w) + ' : Check Laufzeit');
  SchreibeMeldung(DateTimeToStr(N_o_w) + ' : Check Laufzeit', 2);
  Application.ProcessMessages;
  Thread_Schicht.CheckLaufzeitLog;

  ListBox1.Items.Add(DateTimeToStr(N_o_w) + ' : Skip TPM Auswertung');
  SchreibeMeldung(DateTimeToStr(N_o_w) + ' : Skip TPM Auswertung', 2);
  Application.ProcessMessages;
    Thread_Schicht.Berechne_TPM_Auswertung(trunc(startdate),trunc(enddate), '');

  ListBox1.Items.Add(DateTimeToStr(N_o_w) + ' : Start Produktionsdetail');
  SchreibeMeldung(DateTimeToStr(N_o_w) + ' : Start Produktionsdetail', 2);
  Application.ProcessMessages;
  Thread_Schicht.Berechne_TPM_Produktionsdetail(days, '');

  ListBox1.Items.Add(DateTimeToStr(N_o_w) + ' : Start Auftragsdetail');
  SchreibeMeldung(DateTimeToStr(N_o_w) + ' : Start Auftragsdetail', 2);
  Application.ProcessMessages;
  Thread_Schicht.Berechne_TPM_Auftragsdetail(days, '');

  ListBox1.Items.Add(DateTimeToStr(N_o_w) + ' : Berechnung fertig');
  SchreibeMeldung(DateTimeToStr(N_o_w) + ' : Berechnung fertig', 2);
  Application.ProcessMessages;
  Thread_Schicht.Free;

  //  Application.Terminate;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  Button4Click(nil);
end;

procedure TForm1.SetDBUser;
const
  kDBUSer = 'DBUSER=';
  kDBPass = 'DBPASS=';
  kDBServer = 'DBSERVER=';
var
  I: Integer;
begin
  DBUser := '';
  DBPass := '';
  DBServer := '';
  if System.ParamCount > 0 then
  begin
    for I := 0 to System.ParamCount do
    begin
      if Pos(kDBUSer, UpperCase(ParamStr(I))) > 0 then
        DBUser := Copy(ParamStr(I), Pos(kDBUSer, (ParamStr(I))) + Length(kDBUSer), 100);

      if Pos(kDBPass, UpperCase(ParamStr(I))) > 0 then
        DBPass := Copy(ParamStr(I), Pos(kDBPass, UpperCase(ParamStr(I))) + Length(kDBPass), 100);

      if Pos(kDBServer, UpperCase(ParamStr(I))) > 0 then
        DBServer := Copy(ParamStr(I), Pos(kDBServer, UpperCase(ParamStr(I))) + Length(kDBServer), 100);
    end;
  end;

  if DBUser = '' then
    DBUser := 'INCLUDIS';

  if DBPass = '' then
    DBPass := 'comtas';

  if DBServer = '' then
    DBServer := 'includis.world';

  //DBUser := UpperCase(DBUser);
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
  Daten.Database.UserName := DBUser;
  Daten.Database.Password := DBPass;
  Daten.Database.Server := DBServer;

  Daten.qSuch.SQL.Text := 'insert into SIWECHSEL (Nr, SCHICHTWECHSEL, AlteSchicht, NEUESCHICHT)'
    + ' values (1,1,3,1)';
  Daten.qSuch.ExecSQL;
end;

procedure TForm1.BackupClick(Sender: TObject);
begin
  if Thread_DBBackup = nil then
  begin
    Event_DBBackup := CreateEvent(nil, True, False, nil);
    Thread_DBBackup := TThread_DBBackup.Create(True);
    Thread_DBBackup.Priority := tpNormal;
    Thread_DBBackup.Resume;
  end;
  PulseEvent(Event_DBBackup);
end;

procedure TForm1.btn1Click(Sender: TObject);
var ini : TInifile;
begin

  Daten.Database.UserName := DBUser;
  Daten.Database.Password := DBPass;
  Daten.Database.Server := DBServer;

  MakeEnviroment(Daten.qUpdate);


  K_Init(Daten.qUpdate);


  //VerpacktProtAusAusschussRechnen(Daten.qSuch, Daten.qSuch2, Daten.qUpdate, DBUser, 41820);

  CCC_SetSchichtKonstante;
SQLGet(Daten.qSuch, 'SETUP', 'Nr', '1', True);
  SpracheNr := Daten.qSuch.FieldByName('Sprache').AsInteger;
  Sprache2 := Daten.qSuch.FieldByName('Sprache2').AsInteger;
  Sprache_Format := Daten.qSuch.FieldByName('Sprache_Format').AsInteger;
  Verpackt_Aus_Ausschuss := Daten.qSuch.FieldByName('Verpackt_Aus_Ausschuss').AsInteger = 1;
  Anzahl_Masch := Daten.qSuch.FieldByName('anzahl_masch').AsInteger;
  Packen := Daten.qSuch.FieldByName('Packen').AsInteger = 1;

  Shift_Model := Daten.qSuch.FieldByName('Shift_Model').AsInteger;
  Schicht1 := Daten.qSuch.FieldByName('Schicht1').AsInteger / 1440;
  Schicht2 := Daten.qSuch.FieldByName('Schicht2').AsInteger / 1440;
  Schicht3 := Daten.qSuch.FieldByName('Schicht3').AsInteger / 1440;
  Thread_Zusatz := TThread_Zusatz.Create(True);
  sleep(2000);
//  Thread_schicht.TPM_Korrektur(42240.25, 42241.25, true, '3');
  //Thread_Schicht.Recalculate_Mode := true;
  //Thread_Schicht.Recalculation;

  // Thread_Zusatz.CheckAuftragKette;
  //  CCC_MDEWerte_fuellen;
  //  PulseEvent(Event_Zusatz);
  //  Thread_Zusatz.Laufzeit_Berechnen;
  //  Thread_Zusatz.CheckVerpacktProt;
//    Thread_Zusatz.ArbeitsFrei_Buchen;
Thread_Zusatz.CheckAuftragKette;
  //  Thread_Zusatz.Book_Short_Delay;
  //  Thread_Zusatz.Taktzeit_Personal;
  //  Thread_Zusatz.CalcPackedlogFromShiftlog;
 // Thread_Zusatz.Laufzeit_Berechnen  ;
//   Thread_Zusatz.Job_No_to_Downtime_Log;
  // RuestStillstandNrUngeplant := 141;
 // RuestenIstGeplant := True;

 // Thread_Zusatz.ArbeitsFrei_Buchen;

//  Ini := TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'incl_' + DBUser + '.ini');
//  Ini.WriteDateTime('Addons', 'LastRun', now);
//  Ini.Free;


  Application.Terminate;
end;


procedure TForm1.Button6Click(Sender: TObject);
var ini : TInifile;
begin

  Daten.Database.UserName := DBUser;
  Daten.Database.Password := DBPass;
  Daten.Database.Server := DBServer;

  MakeEnviroment(Daten.qUpdate);


  K_Init(Daten.qUpdate);


  //VerpacktProtAusAusschussRechnen(Daten.qSuch, Daten.qSuch2, Daten.qUpdate, DBUser, 41820);

  CCC_SetSchichtKonstante;
SQLGet(Daten.qSuch, 'SETUP', 'Nr', '1', True);
  SpracheNr := Daten.qSuch.FieldByName('Sprache').AsInteger;
  Sprache2 := Daten.qSuch.FieldByName('Sprache2').AsInteger;
  Sprache_Format := Daten.qSuch.FieldByName('Sprache_Format').AsInteger;
  Verpackt_Aus_Ausschuss := Daten.qSuch.FieldByName('Verpackt_Aus_Ausschuss').AsInteger = 1;
  Anzahl_Masch := Daten.qSuch.FieldByName('anzahl_masch').AsInteger;
  Packen := Daten.qSuch.FieldByName('Packen').AsInteger = 1;

  Shift_Model := Daten.qSuch.FieldByName('Shift_Model').AsInteger;
  Schicht1 := Daten.qSuch.FieldByName('Schicht1').AsInteger / 1440;
  Schicht2 := Daten.qSuch.FieldByName('Schicht2').AsInteger / 1440;
  Schicht3 := Daten.qSuch.FieldByName('Schicht3').AsInteger / 1440;
  Thread_Schicht := TThread_Schicht.Create(True);
  sleep(2000);
//  Thread_schicht.
//  Thread_schicht.TPM_Korrektur(42815.25, 42821.25, true, '');
CCC_A_Felder_Schicht_Berechnen2(Daten.qSuch, Daten.qSuch2, Daten.qUpdate, 43221.25, 1);
  //Thread_Schicht.Recalculate_Mode := true;
  //Thread_Schicht.Recalculation;
  //Thread_Schicht.Berechne_TPM_Auftragsdetail(10,'');

//  Ini := TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'incl_' + DBUser + '.ini');
//  Ini.WriteDateTime('Addons', 'LastRun', now);
//  Ini.Free;


  Application.Terminate;
end;

procedure TForm1.Button7Click(Sender: TObject);
begin
 Daten.Database.Connected := False;
  Daten.Database.UserName := DBUser;
  Daten.Database.Password := DBPass;
  Daten.Database.Server := DBServer;

  Left := 100;
  Top := 0;
  CheckBox1.Checked := False;
  Button1.ENABLED := False;
  ListBox1.Items.Insert(0, DateTimeToStr(Now) + ': Start up');
  Application.ProcessMessages;
  try
    if S7Main= nil then
    begin
      S7Main := TS7Main.Create(Self);
      S7Main.Timer1.Enabled := false;
      Main.S7Main := S7Main;
      ListBox1.Items.Insert(0, DateTimeToStr(Now) + ': Service created');
      Application.ProcessMessages;
    end;
  except
  end;
  ListBox1.Items.Insert(0, DateTimeToStr(Now) + ': Service running');
  Application.ProcessMessages;

  

  Button7.Enabled := false;
  S7Main.Timer1Timer(nil);
      S7Main.Timer1.Enabled := false;
  ListBox1.Items.Insert(0, DateTimeToStr(Now) + ': Service waiting');
  Application.ProcessMessages;
  Button7.Enabled := true;
end;

procedure TForm1.MemTimerTimer(Sender: TObject);
begin
  ListBox1.Items.Insert(0, DateTimeTostr(Now) + ':' +CurrentProcessMemory_KB);
  Application.ProcessMessages;
end;

procedure TForm1.Button8Click(Sender: TObject);

var ini : TInifile;
  Tim: TDateTime;
begin
  ListBox1.Items.Add(DateTimeToStr(N_o_w) + ' : Init');

  Daten.Database.UserName := DBUser;
  Daten.Database.Password := DBPass;
  Daten.Database.Server := DBServer;

  MakeEnviroment(Daten.qUpdate);


  K_Init(Daten.qUpdate);


  Thread_Schicht := TThread_Schicht.Create(True);

  CCC_SetSchichtKonstante;
  SQLGet(Daten.qSuch, 'SETUP', 'Nr', '1', True);
  SpracheNr := Daten.qSuch.FieldByName('Sprache').AsInteger;
  Sprache2 := Daten.qSuch.FieldByName('Sprache2').AsInteger;
  Sprache_Format := Daten.qSuch.FieldByName('Sprache_Format').AsInteger;
  Verpackt_Aus_Ausschuss := Daten.qSuch.FieldByName('Verpackt_Aus_Ausschuss').AsInteger = 1;
  Anzahl_Masch := Daten.qSuch.FieldByName('anzahl_masch').AsInteger;
  Packen := Daten.qSuch.FieldByName('Packen').AsInteger = 1;

  Shift_Model := Daten.qSuch.FieldByName('Shift_Model').AsInteger;
  Schicht1 := Daten.qSuch.FieldByName('Schicht1').AsInteger / 1440;
  Schicht2 := Daten.qSuch.FieldByName('Schicht2').AsInteger / 1440;
  Schicht3 := Daten.qSuch.FieldByName('Schicht3').AsInteger / 1440;
  sleep(2000);
  Tim := N_o_w;
  ListBox1.Items.Add(DateTimeToStr(N_o_w) + ' : Start adjustment');

  lblInfo.Caption := 'Korrektur';
  Application.ProcessMessages;
  Thread_Schicht.Berechne_A_Daten(N_o_w - CO_SpinEdit1.Value, N_o_w, '');
  lblInfo.Caption := 'Ende';

  ListBox1.Items.Add(DateTimeToStr(N_o_w) + ' : Done');
  MessageDlg(TimeToStr(N_o_w - Tim), mtInformation, [mbOK], 0);
  Application.ProcessMessages;
  Exit;
end;

procedure TForm1.Button9Click(Sender: TObject);
var
  startdate, enddate: TDateTime;
  days: Integer;
begin
  Button9.ENABLED := False;


  Daten.Database.UserName := DBUser;
  Daten.Database.Password := DBPass;
  Daten.Database.Server := DBServer;

  Thread_Schicht := TThread_Schicht.Create(True);

  SQLGet(Daten.qSuch, 'SETUP', 'Nr', '1', True);
  SpracheNr := Daten.qSuch.FieldByName('Sprache').AsInteger;
  Sprache2 := Daten.qSuch.FieldByName('Sprache2').AsInteger;
  Sprache_Format := Daten.qSuch.FieldByName('Sprache_Format').AsInteger;
  Verpackt_Aus_Ausschuss := Daten.qSuch.FieldByName('Verpackt_Aus_Ausschuss').AsInteger = 1;
  Anzahl_Masch := Daten.qSuch.FieldByName('anzahl_masch').AsInteger;
  Packen := Daten.qSuch.FieldByName('Packen').AsInteger = 1;

  Shift_Model := Daten.qSuch.FieldByName('Shift_Model').AsInteger;
  Schicht1 := Daten.qSuch.FieldByName('Schicht1').AsInteger / 1440;
  Schicht2 := Daten.qSuch.FieldByName('Schicht2').AsInteger / 1440;
  Schicht3 := Daten.qSuch.FieldByName('Schicht3').AsInteger / 1440;

  startdate := StartDT.Date + Schicht1 / 60;
  days := CO_SpinEdit1.Value;
  enddate := startdate + days;

  try
    TimeZone := Daten.qSuch.FieldByName('TimeZone').AsInteger;
  except
    TimeZone := 0;
  end;
  INCLUDIS_HOME := ExtractFilePath(Application.ExeName);
  MakeEnviroment(Daten.qUpdate);
  ListBox1.Items.Clear;
  ListBox1.Items.Add(DateTimeToStr(N_o_w) + ' : Start Init');
  Application.ProcessMessages;
  K_Init(Daten.qUpdate);
  ListBox1.Items.Add(DateTimeToStr(N_o_w) + ' : Start Schichtkonstante');
  Application.ProcessMessages;
  CCC_SetSchichtKonstante;

  ListBox1.Items.Add(DateTimeToStr(N_o_w) + ' : Load Signals');
  SchreibeMeldung(DateTimeToStr(N_o_w) + ' : Load Signals', 2);
  Application.ProcessMessages;
  LoadSignals(Daten.qSuch);

// ListBox1.Items.Add(DateTimeToStr(N_o_w) + ' : Start Stillkorrektur');
//   SchreibeMeldung(DateTimeToStr(N_o_w) + ' : Start Stillkorrektur', 2);
//   Application.ProcessMessages;
//   Thread_Schicht.TPM_Stillog_Korrektur(180, days);

//   ListBox1.Items.Add(DateTimeToStr(N_o_w) + ' : Start Schichtkorrektur');
//   SchreibeMeldung(DateTimeToStr(N_o_w) + ' : Start Schichtkorrektur', 2);
//   Application.ProcessMessages;
//   Thread_Schicht.TPM_Schicht_Pruefen(days);

//   ListBox1.Items.Add(DateTimeToStr(N_o_w) + ' : Check Laufzeit');
//   SchreibeMeldung(DateTimeToStr(N_o_w) + ' : Check Laufzeit', 2);
//   Application.ProcessMessages;
//   Thread_Schicht.CheckLaufzeitLog;

   ListBox1.Items.Add(DateTimeToStr(N_o_w) + ' : Skip TPM Auswertung');
   SchreibeMeldung(DateTimeToStr(N_o_w) + ' : Skip TPM Auswertung', 2);
   Application.ProcessMessages;
     Thread_Schicht.Berechne_TPM_Auswertung(trunc(startdate),trunc(enddate), '');

  ListBox1.Items.Add(DateTimeToStr(N_o_w) + ' : Start Produktionsdetail');
  SchreibeMeldung(DateTimeToStr(N_o_w) + ' : Start Produktionsdetail', 2);
  Application.ProcessMessages;
  Thread_Schicht.Berechne_TPM_ProduktionsdetailDebug(startdate, days , '');

//  ListBox1.Items.Add(DateTimeToStr(N_o_w) + ' : Start Auftragsdetail');
//  SchreibeMeldung(DateTimeToStr(N_o_w) + ' : Start Auftragsdetail', 2);
//  Application.ProcessMessages;
//  Thread_Schicht.Berechne_TPM_Auftragsdetail(days, '');

  ListBox1.Items.Add(DateTimeToStr(N_o_w) + ' : Berechnung fertig');
  SchreibeMeldung(DateTimeToStr(N_o_w) + ' : Berechnung fertig', 2);
  Application.ProcessMessages;
  Thread_Schicht.Free;

  Button9.Enabled := true;
end;

end.

