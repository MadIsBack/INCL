unit MainAzure;

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
  TINCLServAzure = class
    procedure ServiceExecute;
    procedure ServiceDestroy;
    procedure ServiceShutdown;
  private
    lastDBConnectStatus: Boolean;
    terminated : Boolean;
    isinstop : Boolean;
    name : string;
    shutdownfile : string;
    notfirststart : Boolean;
    function  CheckShutdownFile : Boolean;
  public
    procedure SetDBUser;
    procedure Run;
//    function GetServiceController: TServiceController; override;
  end;

var
  INCLServAzure: TINCLServAzure;
  S7Main: TS7Main;
  S7MainOK: Boolean;
  INCLUDIS_HOME: string;
  CSLog: TCriticalSection;
  DBUser: string = 'includis';
  DBServer: string = 'db';
  DBPass: string = 'comtas';
  DBInitialCatalog : string = 'includis';

function ForceBackSlash(S: string): string;
procedure SchreibeMeldung(Meldung: string; Modus: Integer);
function CheckDBVerbindung: Boolean;

implementation

uses
  DatenM, Dialogs, Arbeit, SQL_fuc;



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

procedure TINCLServAzure.ServiceExecute;
var s : string;
    i : Integer;
    Unicode: Boolean;
    Msg: TMsg;
begin
{$IF INCLUDISDatabaseTyp = 1}
  SetDBUser;
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

  {$IFDEF AZURE}
    s := s + 'AZURE;';
  {$ENDIF}

    SchreibeMeldung('Compiled with switches : ' + S, 0);

    while not (Daten.Database.Connected) and not Terminated do
    begin

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
      S7Main := TS7Main.Create;
    except on E: Exception do
        SchreibeMeldung('Error Service.Create : ' + E.message, 0)
    end;

    while not Terminated do
    begin
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
          S7Main := TS7Main.Create;
        except on E: Exception do
            SchreibeMeldung('Error Service.Create : ' + E.message, 0)
        end;
        S7MainOK := True;

      end
      else
      begin
        if CheckShutdownFile then
        begin
          terminated := True;
        end
        else
        begin
          for i := 0 to 20 do
          begin
            if GetMessage(Msg, 0, 0, 0) then
            begin
              Unicode := (Msg.hwnd = 0) or IsWindowUnicode(Msg.hwnd);
              TranslateMessage(Msg);
              if Unicode then
                DispatchMessageW(Msg)
              else
                DispatchMessageA(Msg);
            end;
            Sleep(50);
          end;
//          Sleep(1000);
        end;
      end;
    end;
  finally
    CSLog.Free;
  end;

{$IF INCLUDISDatabaseTyp = 1}
  CoUninitialize;
{$IFEND}
end;



procedure TINCLServAzure.Run;
begin
  if not notfirststart then
  begin
    notfirststart  := True;
    SetDBUser;
  end;
  while True do
  begin
    if not CheckShutdownFile then
    begin
      isinstop := False;
      SchreibeMeldung('Shutdownfile ''' + shutdownfile + ''' does not exists. Starting service...', 0);
      terminated := False;
      ServiceExecute;
    end
    else
    begin
      if not isinstop then
      begin
        SchreibeMeldung('Shutdownfile ''' + shutdownfile + ''' exists. Stopping service...', 0);
        isinstop := True;
      end;
      Sleep(1000);
    end;
  end;
end;

function TINCLServAzure.CheckShutdownFile : Boolean;
var
  nSize: DWORD;
  sdfile : string;
begin
  if shutdownfile = '' then
  begin
    shutdownfile := GetEnvironmentVariable('WEBJOBS_SHUTDOWN_FILE');
//    shutdownfile := GetEnvironmentVariable('TWINCATSDK') + 'SHUTDOWN'; War zum testen
    SchreibeMeldung('Read shutdown file : ' + shutdownfile, 0);
  end;
  if shutdownfile = '' then
    Result := False
  else
    Result := FileExists(shutdownfile);
end;

function GetEnvVar(const varName: string): string;
begin
end;


procedure TINCLServAzure.ServiceDestroy;
begin
  SchreibeMeldung('Service Stop...', 0);
end;

procedure TINCLServAzure.SetDBUser;
const
  kDBUSer = 'DBUSER=';
  kDBPass = 'DBPASS=';
  kDBServer = 'DBSERVER=';
var
  I: Integer;
  Ini: TIniFile;
  inifn: string;
begin
  DBUser := 'INCLUDIS';
  DBPass := 'comtas';
  DBServer := 'includis.world';
  DBInitialCatalog := DBUser;

  inifn := ExtractFilePath(ParamStr(0)) + 'INCL_' + DBUser + '.ini';

  Ini := TIniFile.Create(inifn);
  DBServer := Ini.ReadString('Database', 'DB_Server', 'includis.world');
  DBUser := Ini.ReadString('Database', 'DB_User', DBUser);
  DBPass := Ini.ReadString('Database', 'DB_Password', DBPass);
  DBInitialCatalog := Ini.ReadString('Database', 'InitialCatalog', DBUser);
  Ini.WriteString('Database', 'DB_Server', DBServer);
  Ini.WriteString('Database', 'DB_User', DBUser);
  Ini.WriteString('Database', 'DB_Password', DBPass);

  {$IF INCLUDISDatabaseTyp = 1}
  Ini.WriteString('Database', 'InitialCatalog', DBInitialCatalog);
  {$IFEND}
  INCLUDIS_HOME := Ini.ReadString('Main', 'Home', 'd:\comtas\');

  Ini.Free;
end;

procedure TINCLServAzure.ServiceShutdown;
begin
  SchreibeMeldung('Service Shutdown...', 0);
end;

end.


