unit Th_DBBackup;

interface

uses
  Classes, Windows, IniFiles, Registry, SysUtils, DB, CO_DataBase;

type
  TThread_DBBackup = class(TThread)
  private
    { Private declarations }
    CDatabase: TCO_Database;
    qSuch: TCO_Query;
    qUpdate : TCO_Query;
    function proceedBackup: Boolean;
    function getBackupAppl: string;
    function getCronNextRun(aMinute, aStunde, aMonatstag, aMonat, aWochentag: string): TDateTime;
  protected
    procedure Execute; override;
  public
    constructor Create(aSuspended: Boolean);
    destructor Destroy; override;
  end;

var
  Thread_DBBackup: TThread_DBBackup;
  Event_DBBackup: THandle;

implementation

uses
    {$IFNDEF AZURE}
  Main,
  {$ELSE}
  MainAzure,
  {$ENDIF}

  CO_Setup2, Arbeit;

{ Important: Methods and properties of objects in VCL or CLX can only be used
  in a method called using Synchronize, for example,

      Synchronize(UpdateCaption);

  and UpdateCaption could look like,

    procedure Th_DBBackup.UpdateCaption;
    begin
      Form1.Caption := 'Updated in a thread';
    end; }

{ Th_DBBackup }

constructor TThread_DBBackup.Create(aSuspended: Boolean);
begin
  inherited Create(Suspended);
  FreeOnTerminate := False;
  Priority := tpNormal;
  CDatabase := TCO_Database.Create(nil);
  CDatabase.UserName := DBUser;
  CDatabase.Password := DBPass;
  CDatabase.Server := DBServer;
    {$IF INCLUDISDatabaseTyp = 1}
      CDatabase.InitialCatalog := DBInitialCatalog;
  {$IFEND}	


  qSuch := TCO_Query.Create(nil);
  qSuch.Database := CDatabase;
  qUpdate := TCO_Query.Create(nil);
  qUpdate.Database := CDatabase;
end;

destructor TThread_DBBackup.Destroy;
begin
  qSuch.Free;
  CDatabase.Free;
  inherited;
end;

procedure TThread_DBBackup.Execute;
begin
  while not Terminated do
  begin
    WaitForSingleObject(Event_DBBackup, INFINITE);
    try
      // Nachsehen ob Backup ausgeführt werden muss
      if proceedBackup then
        SchreibeMeldung('Backup created', 0);
    except on E: Exception do
        SchreibeMeldung('Backup failed ' + E.message, 0);
    end;
  end;
end;

function TThread_DBBackup.getBackupAppl: string;
var
  reg: TRegistry;
  I: Integer;
  Sections: TStringList;
begin
  Result := 'none';
  Sections := TStringList.Create;
  reg := TRegistry.Create;
  reg.RootKey := HKEY_LOCAL_MACHINE;
  reg.OpenKey('\SOFTWARE\ORACLE', True);
  reg.GetKeyNames(Sections);

  for I := 0 to Sections.Count - 1 do
    if Copy(Sections[I], 1, 4) = 'KEY_' then
    begin
      reg.OpenKey(Sections[I], False);
      Result := reg.ReadString('ORACLE_HOME');
    end;

  if (Result <> 'none') and (Result <> '') then
  begin
    Result := Result + '\bin\exp.exe';
    if not FileExists(Result) then
      Result := 'none';
  end;

  reg.Free;
  Sections.Free;
end;

function TThread_DBBackup.getCronNextRun(aMinute, aStunde, aMonatstag,
  aMonat, aWochentag: string): TDateTime;
var
  minutearray: array[0..59] of Boolean;
  stundearray: array[0..23] of Boolean;
  monattagarray: array[1..31] of Boolean; // Achutung Schaltjahre !!!
  monatarray: array[1..12] of Boolean;
  wochentagarray: array[0..7] of Boolean; // 0 = Sonntag
  templist: TStringList;
  I, Start, Ende: Integer;
  Y, M, D, H, N, S, dow, ms: Word;

  function convertcron(aList: string): TStringList;
  var
    srclist: TStringList;
    I, STEP, posi: Integer;
    S: string;
  begin
    srcList := TStringList.Create;
    srcList.Delimiter := ',';
    srcList.DelimitedText := aList;
    Result := TStringList.Create;
    // Gucken nach '-'
    for I := 0 to srclist.Count - 1 do
    begin
      S := srclist[I];
      if Pos('-', S) > 0 then
      begin
        if Pos('/', S) > 0 then
        begin
          STEP := StrToInt(Copy(S, Pos('/', S) + 1, 2));
          Delete(S, Pos('/', S), 3);
        end
        else
          STEP := 1;
        Start := StrToInt(Copy(S, 1, Pos('-', S) - 1));
        Ende := StrToInt(Copy(S, Pos('-', S) + 1, 2));

        posi := Start;
        while posi < Ende + 1 do
        begin
          Result.Add(IntToStr(posi));
          Inc(posi, STEP);
        end;
      end
      else
        Result.Add(S);
    end;
    srcList.Free;
  end;

begin
  // Intervals sind möglich wie 4-6 -> 4,5,6
  // Auch Reihen 3,4,5
  // Auch */2 bedeutet 0,2,4,6,8,...
  // Auch Kombination 2-4,6-7
  if Pos('*', aMinute) > 0 then
  begin
    Delete(aMinute, 1, 1);
    aMinute := '0-59' + aMinute;
  end;
  if Pos('*', aStunde) > 0 then
  begin
    Delete(aStunde, 1, 1);
    aStunde := '0-23' + aStunde;
  end;
  if Pos('*', aMonatstag) > 0 then
  begin
    Delete(aMonatstag, 1, 1);
    aMonatstag := '1-31' + aMonatstag;
  end;
  if Pos('*', aMonat) > 0 then
  begin
    Delete(aMonat, 1, 1);
    aMonat := '1-12' + aMonat;
  end;
  if Pos('*', aWochentag) > 0 then
  begin
    Delete(aWochentag, 1, 1);
    aWochentag := '0-7';
  end;

  templist := convertcron(aMinute);
  for I := 0 to 59 do
    minutearray[I] := False;
  for I := 0 to templist.Count - 1 do
    minutearray[StrToInt(templist.Strings[I])] := True;
  templist.Free;

  templist := convertcron(aStunde);
  for I := 0 to 23 do
    stundearray[I] := False;
  for I := 0 to templist.Count - 1 do
    stundearray[StrToInt(templist.Strings[I])] := True;
  templist.Free;

  templist := convertcron(aMonatstag);
  for I := 1 to 31 do
    monattagarray[I] := False;
  for I := 0 to templist.Count - 1 do
    monattagarray[StrToInt(templist.Strings[I])] := True;
  templist.Free;

  templist := convertcron(aMonat);
  for I := 1 to 12 do
    monatarray[I] := False;
  for I := 0 to templist.Count - 1 do
    monatarray[StrToInt(templist.Strings[I])] := True;
  templist.Free;

  templist := convertcron(aWochentag);
  for I := 0 to 7 do
    wochentagarray[I] := False;
  for I := 0 to templist.Count - 1 do
    wochentagarray[StrToInt(templist.Strings[I])] := True;
  if wochentagarray[0] or wochentagarray[7] then
  begin
    wochentagarray[0] := True;
    wochentagarray[7] := True;
  end;
  templist.Free;

  // Welche Stunde, Minute, Monat, Mo haben wir
  Result := N_o_w;
  repeat
    // Sekunden auf 00 setzen. Sieht besser aus
    Result := Round(Result * 1440) / 1440;
    Result := Result + 1 / 1440; // Um eine mMinute nach vorne schieben
    DecodeDateFully(Result, Y, M, D, dow);
    DecodeTime(Result, H, N, S, ms);
    // Nächsten Termin suchen wo alles true ist
  until (wochentagarray[dow - 1] and minutearray[N] and stundearray[H] and monattagarray[D] and monatarray[M]);
end;

function TThread_DBBackup.proceedBackup: Boolean;
var
  Datei, DateiArc, DateiLog: string;
  CommandLine: string;
  StartUpInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
  S: string;
  SR: TSearchRec;
  I: Integer;

  Ini: TIniFile;
  BackupAppl: string;
  backups: TStringList;
  nextruns: TStringList;
  sections: TStringList;
  nextrun: TDateTime;

  oldestfile: string;
  oldestfiledate: Integer;

  newestfile: string;
  newestfiledate: Integer;

  LogFileName, LogFileNameArc: string;
  backupcnt: Integer;
  currentfileamount: Integer;

  cronline: TStringList;

  directory: string;
  backupfilename: string;
  backupextension: string;
  ENABLED: Boolean;

  lastnumber: Integer;
  execres: Cardinal;

  zAppName: array[0..512] of Char;

  function leadingZero(aVal: Integer; aDigits: Integer): string;
  begin
    Result := IntToStr(aVal);
    while Length(Result) < aDigits do
      Result := '0' + Result;
  end;

begin
  Result := False;
  // Variablen sind :
  //  Pfad für Backupfile (UNC oder mit Laufwerk)
  //  Pfad für Export Anwendung (probieren aus Registry zu holen und einzutragen)
  //  Anzahl der Backupfiles
  //  Zeit der Backups

// SQLScript nach BAckup einbauen 'execute DBMS_STATS.GATHER_SCHEMA_STATS(ownname=>'INCLUDIS', cascade=> TRUE)'


  Ini := TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'incl_' + DBUser + '.ini');
  ENABLED := Ini.ReadBool('BackupSystem', 'Enabled', False);
  Ini.WriteBool('BackupSystem', 'Enabled', ENABLED);
  if not ENABLED then
  begin
    Ini.Free;
    Exit;
  end;

  sections := TStringList.Create;
  backups := TStringList.Create;
  nextruns := TStringList.Create;

  BackupAppl := Ini.ReadString('BackupSystem', 'ExportAppl', 'none');
  if BackupAppl = 'none' then
    BackupAppl := getBackupAppl;

  Ini.WriteString('BackupSystem', 'ExportAppl', BackupAppl);
  Ini.WriteString('BackupSystem', 'Comment', '!!! Only use local Path otherwise check permissions !!!');
  Ini.ReadSections(sections);

  for I := 0 to sections.Count - 1 do
  begin
    if Pos('Backup_', sections.Strings[I]) > 0 then
    begin
      nextruns.Add(Ini.ReadString(sections.Strings[I], 'NextRun', 'none'));
      // Neuen NextRun schreiben
      cronline := TStringList.Create;
      cronline.Delimiter := ' ';
      cronline.DelimitedText := Ini.ReadString(sections.Strings[I], 'Interval', 'none');
      backups.Add(cronline.DelimitedText);
      Ini.WriteString(sections.Strings[I], 'NextRun', DateTimeToStr(getCronNextRun(
        cronline.Strings[0], cronline.Strings[1], cronline.Strings[2],
        cronline.Strings[3], cronline.Strings[4])));
      cronline.Free;
    end;
  end;

  if nextruns.Count = 0 then
  begin
    Ini.WriteString('Backup_1', 'Comment', 'Syntax like crontab. See documentation');
    Ini.WriteString('Backup_1', 'Comment2', 'min hour day month weekday backupfile backupfileamount_min');
    Ini.WriteString('Backup_1', 'Interval', '0 3 * * * D:\comtas\sicherung\includis.dmp 7');
    Ini.WriteString('Backup_1', 'NextRun', DateTimeToStr(getCronNextRun('0', '3', '*', '*', '*')));
  end;

  Ini.Free;

  // Herausfiltern ob Backup laufen soll oder nicht
  for I := 0 to nextruns.Count - 1 do
  begin
    try
      nextrun := StrToDateTime(nextruns[I]);
    except
      // Wenn es kein Nextrun gibt, dann muss ausgeführt werden
      nextrun := N_o_w - 1;
    end;

    if nextrun < N_o_w then
    begin
      // Nachgucken ob BackupApp vorhanden
{$IFDEF INCL_ORA}
      if not FileExists(BackupAppl) then
        raise Exception.Create('No backup Application found : ' + BackupAppl);
{$ENDIF}
      // Ausführen von Backup
      cronline := TStringList.Create;
      cronline.Delimiter := ' ';
      cronline.DelimitedText := backups[I];
      lastnumber := 1;
      Datei := LowerCase(cronline.Strings[5]);
      try
        backupcnt := StrToInt(cronline.Strings[6]);
      except
        backupcnt := 1;
      end;
      cronline.Free;

      if backupcnt > 0 then
      begin
        directory := ExtractFilePath(Datei);
        backupfilename := ExtractFileName(Datei);
        backupextension := ExtractFileExt(Datei);
        System.Delete(backupfilename, Pos(backupextension, backupfilename), Length(backupfilename));
        S := directory + backupfilename + '????' + backupextension;
        // Laufende Nummer finden
        currentfileamount := 0;
        if not DirectoryExists(directory) then
          CreateDir(directory);
        if FindFirst(S, faAnyFile, SR) = 0 then
        begin
          oldestfile := sr.Name;
          oldestfiledate := sr.Time;
          newestfile := sr.Name;
          newestfiledate := sr.Time;
          Inc(currentfileamount);
          while FindNext(SR) = 0 do
          begin
            Inc(currentfileamount);
            if sr.Time < oldestfiledate then
            begin
              oldestfile := sr.Name;
              oldestfiledate := sr.Time;
            end;
            if sr.Time > newestfiledate then
            begin
              newestfile := sr.Name;
              newestfiledate := sr.Time;
            end;
          end;
          FindClose(SR);

          // holen der Zahl für letzte Nummer

          S := newestfile;
          Delete(S, 1, Length(backupfilename));
          Delete(S, Pos(backupextension, S), Length(backupextension));

          try
            lastnumber := StrToInt(S);
          except
            lastnumber := 1;
          end;
        end;
      end;

      Datei := directory + backupfilename + leadingZero(lastnumber + 1, 4) + backupextension;
      DateiLog := directory + backupfilename + '.log';
      // Backup schreiben

      LogFileName := 'DB_EXPORT_' + DBUser + '.LOG';
      LogFileNameArc := 'DB_EXPORT_' + DBUser + '_ARC.LOG';

      fillchar(StartUpInfo, SizeOf(TStartupInfo), 0);
      CommandLine := DBUser + '/' + DBPass
        + '@includis.world consistent=Y File=''' + Datei
        + ''' Owner=' + DBUser + ' LOG=''' + directory + LogFileName + '''';
      StartUpInfo.cb := SizeOf(TStartupInfo);
      StartUpInfo.lpTitle := PChar('INCLUDIS Backup [' + DBUser + ']');
      StartUpInfo.dwFlags := STARTF_USESHOWWINDOW;
      StartUpInfo.wShowWindow := SW_SHOW;

      //Result :=
{$IFDEF INCL_MSADO}
      S := 'BACKUP DATABASE includis TO DISK = ''' + Datei + ''' WITH INIT, SKIP, STATS = 10, FORMAT';
      qUpdate.SQL.Text := s;
      qUpdate.ExecSQL;
      S := 'backup log includis TO DISK = ''' + DateiLog + '''';
      qUpdate.SQL.Text := s;
      qUpdate.ExecSQL;
      S := 'DBCC SHRINKFILE ("includis_Log", 1)';
      qUpdate.SQL.Text := s;
      qUpdate.ExecSQL;
      S := 'DBCC SHRINKFILE ("includis_Data")';
      qUpdate.SQL.Text := s;
      qUpdate.ExecSQL;
{$ELSE}

      StrPCopy(zAppName, BackupAppl + ' ' + CommandLine);

      if not CreateProcess(nil, //PChar(BackupAppl),
        zAppName, //PChar(CommandLine),
        nil,
        nil,
        False,
        NORMAL_PRIORITY_CLASS or CREATE_NEW_CONSOLE,
        nil,
        nil, //PChar(directory + '\'),
        StartUpInfo,
        ProcessInfo) then
      begin
        SchreibeMeldung('CreateProcess Backup failed : ' + IntToStr(GetLastError), 0);
        raise Exception.Create(zAppName);
      end
      else
      begin
        WaitforSingleObject(ProcessInfo.hProcess, infinite);
        GetExitCodeProcess(ProcessInfo.hProcess, execres);
        if execres > 0 then
          SchreibeMeldung('Backup result : ' + IntToStr(execres), 0);
      end;

      if TCO_Setup.GetParamBool(qSuch, 'Minibase_Archive_Backup') then
      begin
        DateiArc := directory + backupfilename + '_arc' + leadingZero(lastnumber + 1, 4) + backupextension;
        CommandLine := DBUSER + '_arc/' + DBPASS
          + '@includis.world consistent=Y File=''' + DateiArc
          + ''' Owner=' + DBUser + '_Arc LOG=''' + directory + LogFileNameArc + '''';
        //Result :=
        StartUpInfo.lpTitle := PChar('INCLUDIS Backup [' + DBUser + '_ARC]');

        StrPCopy(zAppName, BackupAppl + ' ' + CommandLine);
        if not CreateProcess(nil, //PChar(BackupAppl),
          zAppName, //PChar(CommandLine),
          nil,
          nil,
          False,
          NORMAL_PRIORITY_CLASS or CREATE_NEW_CONSOLE,
          nil,
          nil, //PChar(directory + '\'),
          StartUpInfo,
          ProcessInfo) then
        begin
          SchreibeMeldung('CreateProcess Backup_Arc failed : ' + IntToStr(GetLastError), 0);
          raise Exception.Create(zAppName);
        end
        else
        begin
          WaitforSingleObject(ProcessInfo.hProcess, infinite);
          GetExitCodeProcess(ProcessInfo.hProcess, execres);
          if execres > 0 then
            SchreibeMeldung('Backup arc result : ' + IntToStr(execres), 0);
        end;
      end;
{$ENDIF}

      // Überflüssige Dateiene löschen
      while currentfileamount > backupcnt do
      begin
        DeleteFile(directory + oldestfile);
        S := directory + backupfilename + '_arc' + '????' + backupextension;
        // Laufende Nummer finden
        currentfileamount := 0;
        if FindFirst(S, faAnyFile, SR) = 0 then
        begin
          oldestfile := sr.Name;
          oldestfiledate := sr.Time;
          Inc(currentfileamount);
          while FindNext(SR) = 0 do
          begin
            Inc(currentfileamount);
            if sr.Time < oldestfiledate then
            begin
              oldestfile := sr.Name;
              oldestfiledate := sr.Time;
            end;
          end;
        end;
        FindClose(SR);
      end;
      // UNd weils so schön war für _Arc das selbe nochmal
      if TCO_Setup.GetParamBool(qSuch, 'Minibase_Archive_Backup') then
      begin
        while currentfileamount > backupcnt do
        begin
          DeleteFile(directory + oldestfile);
          S := directory + backupfilename + '_arc????' + backupextension;
          // Laufende Nummer finden
          currentfileamount := 0;
          if FindFirst(S, faAnyFile, SR) = 0 then
          begin
            oldestfile := sr.Name;
            oldestfiledate := sr.Time;
            Inc(currentfileamount);
            while FindNext(SR) = 0 do
            begin
              Inc(currentfileamount);
              if sr.Time < oldestfiledate then
              begin
                oldestfile := sr.Name;
                oldestfiledate := sr.Time;
              end;
            end;
          end;
          FindClose(SR);
        end;
      end;
      Result := True;
    end;
  end;

  backups.Free;
  nextruns.Free;
  sections.Free;

end;

end.

