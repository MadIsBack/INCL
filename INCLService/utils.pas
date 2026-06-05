unit utils;

interface

uses
    {$IFNDEF AZURE}
  Main,
  {$ELSE}
  MainAzure,
  {$ENDIF}

  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
   StdCtrls, TlHelp32, psAPI,
   CO_DataBase;

procedure EnumProcesses;
function EnumProcess(ProcessName : string) : string;
function ProcessMemory_KB(id : Cardinal): string;
function GetComputerNetName: string;

procedure LogUsrEvent(Query: TCO_Query; eventId: Integer; EventToken: string; BAnr, Artikel, Lizenz, Werkzeug, Neu: string; prod: integer;
                      Alt: string = ''; Notice : string = ''; RefNo : string = ''); overload;
procedure LogUsrEvent(searchQuery, updateQuery: TCO_Query; eventId: Integer; EventToken: string; BAnr, Neu: string; Alt: string = ''; Notice : string = ''; RefNo : string = ''); overload;
function FloatToPunktString(aFloat: Extended): string;
procedure ChangeDtCode(updateQuery: TCO_Query; stillstandnr, stillogNr: Integer; usrEventLog: Boolean; comment : string = ''); overload;
procedure ChangeDtCode(query: TCO_Query; stillstandnr, stillogNr: Integer; usrEventlog, autoBuchung, reaktionszeit: Boolean; comment : string = ''); overload;
procedure ChangeDtCode(updateQuery: TCO_Query; stillstandnr, stillogNr: Integer; stillogQuery: TCO_Query; comment : string = ''); overload;
procedure LogAndChangeDtCode(updateQuery: TCO_Query; stillstandnr, stillogNr: Integer; stillogQuery: TCO_Query; autoBuchung, Reaktionszeit: Boolean; comment : string = ''); overload;
procedure LogDtChangeEvent(stillogQuery, updateQuery: TCO_Query; stillogNr: Integer; comment : string = '');
implementation

uses
  SQL_fuc, Sprache_V63, Dialogs, DatenM, Maindll, Th_Schicht, DateUtils,
  SyncObjs, Th_Zusatz, Th_DBBackup, CO_Setup2, IniFiles, DbMain;


function ProcessMemory_KB(id : Cardinal): string;
var
  MemCounters: TProcessMemoryCounters;
  S: string;
begin
  MemCounters.cb := SizeOf(MemCounters);

  if GetProcessMemoryInfo(id, @MemCounters, SizeOf(MemCounters)) then
  begin
    S := IntToStr(MemCounters.WorkingSetSize div 1024);
    while Length(S) < 7 do
      S := ' ' + S;

    Result := S + ' [';

    S := IntToStr(MemCounters.PagefileUsage div 1024);
    while Length(S) < 7 do
      S := ' ' + S;

    Result := Result + S + ']';
  end                       ;
end;

procedure EnumProcesses;
var
  ContinueLoop: BOOL;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
  s : string;
  i : string;
  c : Cardinal;
begin
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := SizeOf(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);
  while Integer(ContinueLoop) <> 0 do
  begin
    s := FProcessEntry32.szExeFile;
    c := OpenProcess(PROCESS_ALL_ACCESS, False, FProcessEntry32.th32ProcessID);
    if c >0 then
      i :=  ProcessMemory_KB(c)
    else
      i := '';
    SchreibeMeldung(s + ' ' + i,5);
    ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
end;

function EnumProcess(ProcessName : string) : string;
var
  ContinueLoop: BOOL;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
  s : string;
  i : string;
  c : Cardinal;
begin
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := SizeOf(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);
  while Integer(ContinueLoop) <> 0 do
  begin
    s := FProcessEntry32.szExeFile;
    if Pos(ProcessName,s) >0 then
    begin
      c := OpenProcess(PROCESS_ALL_ACCESS, False, FProcessEntry32.th32ProcessID);
      if c >0 then
        i :=  ProcessMemory_KB(c)
      else
        i := '';
      SchreibeMeldung(s + ' ' + i,5);
      result := i;
    end;
    ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
end;

function GetComputerNetName: string;
var
  buffer: array[0..255] of char;
  size: dword;
begin
  size := 256;
  if GetComputerName(buffer, size) then
    Result := buffer
  else
    Result := ''
end;


procedure LogUsrEvent(query: TCO_Query; eventId: Integer; EventToken: string; BAnr, Artikel, Lizenz, Werkzeug, Neu: string; prod: integer;
                      Alt: string = ''; Notice : string = ''; RefNo : string = '');
var
  S: string;
begin
  S := 'INSERT INTO USR_EVENTLOG(NR, EVENTDATETIME, USERID, SOURCE, EVENTID, NOTICE, WORKORDERNO,'
     + ' LICENSE, TOOLNO, PARTNO, NEWVALUE, REFERENCENO, HOSTNAME, EVENTTOKEN, JOBPRODUCED, oldvalue)'
     + ' VALUES (USR_EVENTLOGID.Nextval,' + FloatToPunktString(Now) + ', ''-2'', ''INCLService'', ''' + IntToStr(eventId) + ''', '''
     +  Notice + ''', ''' +  BAnr + ''', '''
     +  Lizenz + ''', ''' +  Werkzeug + ''', '''
     +  Artikel + ''', ''' +  Neu + ''', '''
     +  RefNo + ''', ''' + ServerNameDesDienstes + ''', ''' + EventToken + ''',''' +  IntToStr(prod) + ''','
     + '''' + alt + ''')';
  SQL_Insert(query, S);
end;

procedure LogUsrEvent(searchQuery, updateQuery: TCO_Query; eventId: Integer; EventToken: string; BAnr, Neu: string; Alt: string = ''; Notice : string = ''; RefNo : string = '');
var
 Artikel, Lizenz, Werkzeug, S: string;
 prod: integer;
begin
  S := 'SELECT mi.BETRIEBSAUFTRAGNR, mi.LIZENZ, mi.WERKZEUG, mi.ARTIKELNR, mi.stueck'
     + ' FROM maschinf mi '
     + ' WHERE mi.betriebsauftragnr = ''' + BAnr + '''';
  SQL_Get(searchQuery, S);
  if searchQuery.IsEmpty then
  begin
    S := ' SELECT p.Betriebsauftragnr, p.lizenz, w.werkzeugnr werkzeug, p.auftragnr artikelnr, p.istwert stueck'
       + ' FROM PDE p LEFT JOIN WERKZEUG w ON p.WERKZEUG = w.WERKZEUG '
       + ' WHERE p.betriebsauftragnr = ''' + BAnr + '''';
    SQL_Get(searchQuery, S);
    if searchQuery.IsEmpty then
    begin
      S := 'SELECT a.Betriebsauftragnr, a.maschine lizenz, a.werkzeugnr werkzeug, a.auftragnr artikelnr, a.produziertint stueck'
         + ' FROM aarchiv a '
         + ' WHERE a.betriebsauftragnr = ''' + BAnr + '''';
      SQL_Get(searchQuery, S);
    end;
  end;
  if not searchQuery.IsEmpty then
  begin
    LogUsrEvent(updateQuery, eventId,EventToken, Banr, searchQuery.FieldByName('Artikelnr').AsString, searchQuery.FieldByName('Lizenz').AsString,
                searchQuery.FieldByName('Werkzeug').AsString, Neu, searchQuery.FieldByName('stueck').AsInteger, Alt, Notice, RefNo);
  end;

end;

function FloatToPunktString(aFloat: Extended): string;
begin
  Result := FloatToStr2(aFloat);
  if Pos(',', Result) > 0 then
  begin
    Insert('.', Result, Pos(',', Result));
    Delete(Result, Pos(',', Result), 1);
  end;
end;

procedure ChangeDtCode(updateQuery: TCO_Query; stillstandnr, stillogNr: Integer; usrEventLog: Boolean; comment : string = ''); overload;
begin
  ChangeDtCode(updateQuery, stillstandnr, stillogNr, usrEventlog, false, false, comment);
end;
procedure ChangeDtCode(query: TCO_Query; stillstandnr, stillogNr: Integer; usrEventlog, autoBuchung, reaktionszeit: Boolean; comment : string = ''); overload;
var
  S: string;
begin
  if (usrEventlog) then
  begin
    S := 'SELECT mi.BETRIEBSAUFTRAGNR, mi.LIZENZ, mi.WERKZEUG, mi.ARTIKELNR, s.stillstand, mi.stueck, s2.stillstand alterstillstand'
      + ' FROM TPM_STILLOG  ts'
      + ' LEFT JOIN MASCHINE m ON m.maschnr = ts.maschnr'
      + ' LEFT JOIN MASCHINF mi ON m.lizenz = mi.lizenz'
      + ' LEFT JOIN TPM_STILLSTAENDE s ON s.STILLSTANDNR = ' + IntToStr(stillstandnr)
      + ' LEFT JOIN TPM_STILLSTAENDE s2 ON s2.stillstandnr = ts.stillstandnr'
      + ' WHERE ts.nr = ' + IntToStr(stillogNr);
    SQL_Get(query, S);
    LogDtChangeEvent(query, query, stillogNr, comment);
  end;

  S := 'update tpm_stillog set StillstandNr = ' + IntToStr(Stillstandnr)
     + ', lastchange = ' + FloatToPunktString(Now)
     + ', userid = ''-2'', hostname = ''' + ServerNameDesDienstes + '''';
  if AutoBuchung then
    S := S + ', AutoBuchung = ' + FloatToPunktString(Now);
  if Reaktionszeit then
    S := S + ', reaktionszeit = trunc((' + FloatToPunktString(Now) + ' - kommt)*1440)';
  S := S  + ' WHERE nr = ' + IntToStr(StillogNr);
  SQL_Insert(query, S);
end;

procedure ChangeDtCode(updateQuery: TCO_Query; stillstandnr, stillogNr: Integer; stillogQuery: TCO_Query; comment : string = ''); overload;
begin
  LogAndChangeDtCode(updateQuery, stillstandnr, stillogNr, stillogQuery, false, false, comment);
end;

procedure LogAndChangeDtCode(updateQuery: TCO_Query; stillstandnr, stillogNr: Integer; stillogQuery: TCO_Query; autoBuchung, Reaktionszeit: Boolean; comment : string = ''); overload;
begin
  ChangeDtCode(updateQuery, stillstandnr, stillogNr, false, false, false);
  LogDtChangeEvent(stillogQuery, updateQuery, stillogNr, comment);
end;

procedure LogDtChangeEvent(stillogQuery, updateQuery: TCO_Query; stillogNr: Integer; comment : string = '');
var
  BaNr, ArtikelNr, Lizenz, Werkzeug, AlterStillstand, NeuerStillstand: string;
  Stueck: Integer;
begin
  try
    BaNr := stillogQuery.FieldByName('Betriebsauftragnr').AsString;
  except
  end;
  try
    ArtikelNr := stillogQuery.FieldByName('ARTIKELNR').AsString
  except
  end;
  try
    Lizenz := stillogQuery.FieldByName('Lizenz').AsString
  except
  end;
  try
    Werkzeug := stillogQuery.FieldByName('Werkzeug').AsString
  except
  end;
  try
    AlterStillstand := stillogQuery.FieldByName('alterstillstand').AsString
  except
  end;
  try
    NeuerStillstand := stillogQuery.FieldByName('Stillstand').AsString
  except
  end;
  try
    Stueck := stillogQuery.FieldByName('stueck').AsInteger
  except
  end;
  if (comment = '') then
    comment := IntToStr(stillogNr);
    
  LogUsrEvent(updateQuery, 201, 'DBK', BaNr, ArtikelNr, Lizenz, Werkzeug, NeuerStillstand, Stueck, AlterStillstand, comment, IntToStr(stillogNr));
end;

end.
