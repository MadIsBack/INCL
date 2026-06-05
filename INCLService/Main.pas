unit Main;

interface

//Mandantenfähigkeit: Durch Angabe des Datenbankbenutzers (DBUSER)
//wird der Dienst nach Kompilierung für den jeweiligen
//Mandanten erstellt: SERVICE_DISPLAY_NAME + DBUSER ist der Dienstname
//im MS Diente-Manager.

// Die Installation des Dienstes erfolgt mit Parameter /DBUSER=
// Dieser wird in die Registry geschrieben. Der Service holt sich den DBUSER
// über diesen Parameter.

// Die Installation des Dienstes erfolgt somit für jeden Mandanten wie folgt :
// INCLMsgService /DBUSER=XXXXX /install

uses
  CO_DataBase, Windows, Messages, SysUtils, Classes, Graphics, Controls, SvcMgr,
  DBMain, SyncObjs, ActiveX, Registry, IniFiles;

const
  MAX_FILE_SIZE_MB = 4;
  TRACE_DIR = 'LOG';

  SERVICE_DISPLAY_NAME = 'INCLServer';

type
  TINCLServ = class(TService)
    procedure ServiceExecute(Sender: TService);
    procedure ServiceBeforeInstall(Sender: TService);
    procedure ServiceCreate(Sender: TObject);
    procedure ServiceDestroy(Sender: TObject);
    procedure ServicePause(Sender: TService; var Paused: Boolean);
    procedure ServiceContinue(Sender: TService; var Continued: Boolean);
    procedure ServiceAfterInstall(Sender: TService);
    procedure ServiceShutdown(Sender: TService);
  private
    lastDBConnectStatus: Boolean;
  public
    procedure SetDBUser;
    function GetServiceController: TServiceController; override;
  end;

var
  INCLServ: TINCLServ;
  S7Main: TS7Main;
  S7MainOK: Boolean;
  INCLUDIS_HOME: string;
  CSLog: TCriticalSection;
  DBUser: string = 'includis';
  DBServer: string = 'db';
  DBPass: string = 'comtas';
  DBInitialCatalog : string = 'includis';
  DBProvider : string = '';

function ForceBackSlash(S: string): string;
procedure SchreibeMeldung(Meldung: string; Modus: Integer);
function CheckDBVerbindung: Boolean;

implementation

uses
  DatenM, Dialogs, Arbeit, SQL_fuc;

{$R *.DFM}

procedure ServiceController(CtrlCode: DWORD); stdcall;
begin
  INCLServ.Controller(CtrlCode);
end;

function TINCLServ.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

function CheckDBVerbindung: Boolean;
var
  iData: TCO_Database;
begin
  Randomize;
  SchreibeMeldung('Check connect.', 0);
  iData := TCO_Database.Create(nil);
  try
    iData.Connected := False;
    iData.UserName := DBUser;
    iData.Password := DBPass;
    iData.Server := DBServer;
    {$IF INCLUDISDatabaseTyp = 1}
      iData.InitialCatalog := DBInitialCatalog;
	    iData.SqlProvider := DBProvider;
      SchreibeMeldung('Using ' + DBUSer + '@' + DBServer + ' (' + DBInitialCatalog + ')' + ' - Provider:' + iData.SqlProvider, 0);
	  
	{$ELSE}	
      SchreibeMeldung('Using ' + DBUSer + '@' + DBServer, 0);
    {$IFEND}
    iData.Connected := True;
  except
  end;

  Result := iData.Connected;
  try
    iData.Connected := False;
  except
  end;
  try
    FreeAndNil(iData);
  except
  end;

  if Result then
    SchreibeMeldung('Connect Ok.', 0)
  else
    SchreibeMeldung('Connect failed.', 0);
end;

function ForceBackSlash(S: string): string;
begin
  if S[Length(S)] <> '\' then
    Result := S + '\'
  else
    Result := S;
end;

procedure SchreibeMeldung(Meldung: string; Modus: Integer);
var
  F: TextFile;
  S: string;
  TMPFILE: file of Byte;
  L: Integer;
  MeldeDir: string;
  MeldeFile: string;
begin
  try
{$I-}
    if INCLUDIS_HOME = '' then
      Exit;
    INCLUDIS_HOME := ForceBackSlash(INCLUDIS_HOME);
    MeldeDir := ForceBackSlash(INCLUDIS_HOME + TRACE_DIR);

    if not DirectoryExists(MeldeDir) then
    begin
      if not CreateDir(MeldeDir) then
        Exit;
    end;

    case Modus of
      0: MeldeFile := MeldeDir + 'svc_' + LowerCase(DBUser) + '_trace.log';
      1: MeldeFile := MeldeDir + 'svc_' + LowerCase(DBUser) + '_timer.log';
      2: MeldeFile := MeldeDir + 'svc_' + LowerCase(DBUser) + '_shift.log';
      3: MeldeFile := MeldeDir + 'svc_' + LowerCase(DBUser) + '_addons.log';
      4: MeldeFile := MeldeDir + 'svc_' + LowerCase(DBUser) + '_recalc.log';
      5: MeldeFile := MeldeDir + 'svc_' + LowerCase(DBUser) + '_memory.log';
      6: MeldeFile := MeldeDir + 'svc_' + LowerCase(DBUser) + '_down.log';
      7: MeldeFile := MeldeDir + 'svc_' + LowerCase(DBUser) + '_memdbg.log';
    end;

    if not FileExists(MeldeFile) then
    begin
      AssignFile(F, MeldeFile);
      Rewrite(F);
    end
    else
    begin
      AssignFile(TMPFILE, MeldeFile);
      Reset(TMPFILE);
      L := FileSize(TMPFILE);
      CloseFile(TMPFILE);

      AssignFile(F, MeldeFile);

      if L > (MAX_FILE_SIZE_MB * 1024 * 1024) then
        Rewrite(F)
      else
        Append(F);
    end;

//    S := DateTimeToStr(N_o_w) + ' - ' +CurrentProcessMemory_KB + 'kB : ' + Meldung;
    S := DateTimeToStr(N_o_w) + ' : ' + Meldung;
    WriteLn(F, S);

    if (Pos('Gleitkommawert', S) > 0) or (Pos('invalid month', S) > 0) or (Pos('invalid number', S) > 0) then
    begin
      WriteLn(F, '  DecimalSeparator: ' + DecimalSeparator);
      WriteLn(F, '  ThousandSeparator: ' + ThousandSeparator);
      WriteLn(F, '  ShortDateFormat: ' + ShortDateFormat);
      WriteLn(F, '  ShortTimeFormat: ' + ShortTimeFormat);
    end;

    CloseFile(F);
{$I+}
  except
  end;

  end;

procedure TINCLServ.ServiceExecute(Sender: TService);
var s : string;
begin
{$IF INCLUDISDatabaseTyp = 1}
  CoInitialize(nil);
{$IFEND}
  try
    CSLog := TCriticalSection.Create;
    lastDBConnectStatus := True;
 s := '';

  {$IFDEF INCL_ORA}
    s := s + 'INCL_ORA;';
  {$ENDIF}
  {$IFDEF ODAC}
    s := s + 'ODAC;';
  {$ENDIF}
  {$IFDEF INCL_MSADO}
    s := s + 'INCL_MSADO;';
  {$ENDIF}
  {$IFDEF TIMEMEAS}
    s := s + 'TIMEMEAS;';
  {$ENDIF}

  SchreibeMeldung('Compiled with switches : ' + S, 0);
    // SetDBUser;

    while not (Daten.Database.Connected) and not Terminated do
    begin
      ServiceThread.ProcessRequests(False);

      if CheckDBVerbindung then
      begin
        try
          SchreibeMeldung('Connected.', 0);
          Daten.Database.Connected := False;
          Daten.Database.UserName := DBUser;
          Daten.Database.Password := DBPass;
          Daten.Database.Server := DBServer;
          {$IF INCLUDISDatabaseTyp = 1}
          Daten.Database.InitialCatalog := DBInitialCatalog;
		      Daten.Database.SqlProvider := DBProvider;
          {$IFEND}
          Daten.Database.Connected := True;
        except
        end;
      end;

      if not (Daten.Database.Connected) then
      begin
        if lastDBConnectStatus then
        begin
          lastDBConnectStatus := False;
          SchreibeMeldung('Database not available.', 0);
        end;
      end
      else
      begin
        if not lastDBConnectStatus then
          lastDBConnectStatus := True;
      end;
      if not (Daten.Database.Connected) and not Terminated then
      begin
        SchreibeMeldung('Wait 30 sec.', 0);
        Sleep(30000);
      end;
    end;

    if Terminated then
      Exit;

    S7MainOK := True;
    SchreibeMeldung('Database connection successfully... Start programm...', 0);
    try
      S7Main := TS7Main.Create(Self);
    except on E: Exception do
        SchreibeMeldung('Error Service.Create : ' + E.message, 0)
    end;

    while not Terminated do
    begin
      ServiceThread.ProcessRequests(True);
      // Möglicherweise ProcessRequests(false), anschließend
      // Test ob S7MainOK und am Ende sleep(1000)
      // Testet dann alle Sekunde ob es einen Fehler bei S7Main gab.
      if not S7MainOK then
      begin

        //Ein Fehler ist während der Ausführung aufgetreten,
        //also Neuanlauf
        try
          S7Main.Free;
        except
        end;

        SchreibeMeldung('New start program...', 0);
        try
          S7Main := TS7Main.Create(Self);
        except on E: Exception do
            SchreibeMeldung('Error Service.Create : ' + E.message, 0)
        end;
        S7MainOK := True;

      end;
    end;
  finally
    CSLog.Free;
  end;

{$IF INCLUDISDatabaseTyp = 1}
  CoUninitialize;
{$IFEND}
end;

procedure TINCLServ.ServiceBeforeInstall(Sender: TService);
begin
  SetDBUser;
  DisplayName := SERVICE_DISPLAY_NAME + UpperCase(DBUser);
  Name := DisplayName;
  CSLog := TCriticalSection.Create;
end;

procedure TINCLServ.ServiceCreate(Sender: TObject);
begin
  SetDBUser;
  DisplayName := SERVICE_DISPLAY_NAME + UpperCase(DBUser);
  Name := DisplayName;
end;

procedure TINCLServ.ServiceDestroy(Sender: TObject);
begin
  SchreibeMeldung('Service Stop...', 0);
end;

procedure TINCLServ.ServicePause(Sender: TService; var Paused: Boolean);
begin
  SchreibeMeldung('Service Pause...', 0);
end;

procedure TINCLServ.ServiceContinue(Sender: TService; var Continued: Boolean);
begin
  SchreibeMeldung('Service Continued...', 0);
  Continued := True;
end;

procedure TINCLServ.ServiceAfterInstall(Sender: TService);
var
  Reg: TRegistry;
begin
  SetDBUser;
  Reg := TRegistry.Create(KEY_READ or KEY_WRITE);
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    if Reg.OpenKey('\System\CurrentControlSet\Services\' + Name, True) then
    begin
      Reg.WriteString('Description', 'INCLUDIS Service for Calculation for User ' + DBUser);
      Reg.WriteString('ImagePath', System.ParamStr(0) + ' /DBUSER=' + DBUser + ' /DBSERVER=' + DBServer);
    end
  finally
    Reg.Free;
  end;
end;

procedure TINCLServ.SetDBUser;
const
  kDBUSer = 'DBUSER=';
  kDBPass = 'DBPASS=';
  kDBServer = 'DBSERVER=';
var
  I: Integer;
  Ini: TIniFile;
  inifn: string;
begin
  DBUser := '';
  DBPass := '';
  DBServer := '';

  if System.ParamCount > 0 then
  begin
    for I := 0 to System.ParamCount do
    begin
      if Pos(kDBUSer, UpperCase(ParamStr(I))) > 0 then
        DBUser := Copy(ParamStr(I), Pos(kDBUSer, UpperCase(ParamStr(I))) + Length(kDBUSer), 100);

      if Pos(kDBPass, UpperCase(ParamStr(I))) > 0 then
        DBPass := Copy(ParamStr(I), Pos(kDBPass, UpperCase(ParamStr(I))) + Length(kDBPass), 100);

      if Pos(kDBServer, UpperCase(ParamStr(I))) > 0 then
        DBServer := Copy(ParamStr(I), Pos(kDBServer, UpperCase(ParamStr(I))) + Length(kDBServer), 100);
    end;
  end
  else
    if Self.ParamCount > 0 then
    begin
      for I := 0 to Self.ParamCount do
      begin
        if Pos(kDBUSer, UpperCase(Self.Param[I])) > 0 then
          DBUser := Copy(Self.Param[I], Pos(kDBUSer, UpperCase(Self.Param[I])) + Length(kDBUSer), 100);

        if Pos(kDBPass, UpperCase(Self.Param[I])) > 0 then
          DBPass := Copy(Self.Param[I], Pos(kDBPass, UpperCase(Self.Param[I])) + Length(kDBPass), 100);

        if Pos(kDBServer, UpperCase(Self.Param[I])) > 0 then
          DBServer := Copy(Self.Param[I], Pos(kDBServer, UpperCase(Self.Param[I])) + Length(kDBServer), 100);
      end;
    end;

  if DBUser = '' then
    DBUser := 'INCLUDIS';

  if DBPass = '' then
    DBPass := 'comtas';

  if DBServer = '' then
    DBServer := 'includis.world';

  if DBInitialCatalog = '' then
    DBInitialCatalog := DBUser;

  DBUser := UpperCase(DBUser);

  inifn := ExtractFilePath(ParamStr(0)) + 'INCL_' + DBUser + '.ini';

  Ini := TIniFile.Create(inifn);
  DBServer := Ini.ReadString('Database', 'DB_Server', 'includis.world');
  DBInitialCatalog := Ini.ReadString('Database', 'InitialCatalog', DBUser);
  DBProvider := Ini.ReadString('Database', 'Provider', DBProvider);
  Ini.WriteString('Database', 'DB_Server', DBServer);
  Ini.WriteString('Database', 'Provider', DBProvider);
  {$IF INCLUDISDatabaseTyp = 1}
  Ini.WriteString('Database', 'InitialCatalog', DBInitialCatalog);
  {$IFEND}
  INCLUDIS_HOME := Ini.ReadString('Main', 'Home', 'd:\comtas\');

  Ini.Free;
end;

procedure TINCLServ.ServiceShutdown(Sender: TService);
begin
  SchreibeMeldung('Service Shutdown...', 0);
end;

end.

