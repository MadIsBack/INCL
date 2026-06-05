unit SQL_fuc;

interface

uses
  psAPI, CO_DataBase, Windows, DatenM, DB, Controls, SysUtils;

function Handle_DB_Error(E: string): Boolean;
function RestartDatabase: Boolean;

function SQL_Get(Query: TCO_Query; SQLStr: string) : Boolean;
function SQL_Insert(Query: TCO_Query; SQLStr: string) : integer;

function SQLGetBool(Query: TCO_Query; Tabelle: string; Feld: string; Wert: string): Boolean;
function SQL2GetBool(Query: TCO_Query; Tabelle: string; Feld: string; Wert: string; Feld2: string; Wert2: string ): Boolean;
function SQL3GetBool(Query: TCO_Query; Tabelle: string; Feld: string; Wert: string; Feld2: string; Wert2: string; Feld3: string; Wert3: string): Boolean;

function SQLGet(Query: TCO_Query; Tabelle: string; Feld: string; Wert: string; Ergebnis: Boolean): Integer;
function SQL2Get(Query: TCO_Query; Tabelle: string; Feld: string; Wert: string; Feld2: string; Wert2: string; Ergebnis: Boolean): Integer;
function SQL3Get(Query: TCO_Query; Tabelle: string; Feld: string; Wert: string; Feld2: string; Wert2: string; Feld3: string; Wert3: string;
  Ergebnis: Boolean): Integer;

procedure UpdateSQL(Query: TCO_Query; Tabelle: string; UpdateFeld: string; UpdateWert: string;
  WhereFeld: string; WhereWert: string);

procedure Update2SQL(Query: TCO_Query; Tabelle: string; UpdateFeld: string; UpdateWert: string;
  WhereFeld: string; WhereWert: string; WhereFeld2: string; WhereWert2: string);

procedure DeleteSQL(Query: TCO_Query; Tabelle: string; Feld: string; Wert: string);

function GetGlobalMemory_MB: string;
function CurrentProcessMemory_KBInt: Integer;
function CurrentProcessMemory_KB: string;

function FloatToStr2(Value: Extended): string;
function FloatToStrF2(Value: Extended; Format: TFloatFormat; Precision, Digits: Integer): string;
function FloatToPunktStringF2(Value: Extended; Format: TFloatFormat; Precision, Digits: Integer): string;



implementation

uses
    {$IFNDEF AZURE}
  Main,
  {$ELSE}
  MainAzure,
  {$ENDIF}
  Sprache_V63, DBMain, Arbeit, comtas_h;

function Handle_DB_Error(E: string): Boolean;
begin
  Result := False;
  //*** ORA-01000 Max Oper Cursors überschritten ****
  if Pos('ORA-01000', UpperCase(E)) > 0 then
  begin
    //Daten.Database.Connected := False;
    Result := RestartDatabase;
  end;
end;

function RestartDatabase: Boolean;
begin
  Result := False;
  Daten.Database.Connected := False;
  try
    Daten.Database.Connected := True;
    Result := Daten.Database.Connected;
  except
  end;
end;

function SQL_Get(Query: TCO_Query; SQLStr: string):Boolean;
var
  S: string;
begin
  Result := False;
  Query.Close;
  Query.SQL.Clear;
  Query.SQL.Text := SQLStr;
  try
    Query.Open;
    Result := not Query.IsEmpty;
    Query.First;
  except
    on E: Exception do
    begin
      Daten.Conn := False;
      S := '';
      case Query.Tag of
        0: S := '(MAIN)';
        1: S := '(ADDON)';
        2: S := '(SHIFT)';
      end;
      SchreibeMeldung(S + ' ' + GetL('Exception. SQL: ') + Query.Name + ': ' + SQLStr, 0);
      SchreibeMeldung('Message: ' + E.message, 0);

      if Handle_DB_Error(E.message) then
      try
        Query.Open;
        Result := not Query.IsEmpty;
      except
      end;
    end;
  end;
end;

function SQL_Insert(Query: TCO_Query; SQLStr: string) : integer;
var
  S: string;
begin
  Query.Close;
  Query.SQL.Clear;
  Query.SQL.Add(SQLStr);
  try
    result := Query.ExecSQL;
  except
    on E: Exception do
    begin
      Daten.Conn := False;
      S := '';
      case Query.Tag of
        0: S := '(MAIN)';
        1: S := '(ADDON)';
        2: S := '(SHIFT)';
      end;
      SchreibeMeldung(S + ' ' + GetL('Exception. SQL: ') + Query.Name + ': ' + SQLStr, 0);
      SchreibeMeldung('Message: ' + E.message, 0);

      if Handle_DB_Error(E.message) then
      try
        Query.ExecSQL;
      except
      end;
    end;
  end;
  Query.Close;
end;


function SQLGetBool(Query: TCO_Query; Tabelle: string; Feld: string; Wert: string): Boolean;
var
  SQLStr: string;
begin
  SQLStr := 'Select * from ' + Tabelle + ' where ' + Feld + '=''' + Wert + '''';
  SQL_Get(Query, SQLStr);
  Result := not Query.IsEmpty;
end;

function SQL2GetBool(Query: TCO_Query; Tabelle: string; Feld: string; Wert: string; Feld2: string; Wert2: string ): Boolean;
var
  SQLStr: string;
begin
  SQLStr := 'Select * from ' + Tabelle + ' where (' + Feld + '=''' + Wert + ''') AND (' + Feld2 + '=''' + Wert2 + ''')';

  if (Wert = '') and (Wert2 = '') then
    SQLStr := 'Select * from ' + Tabelle;

  if (not (Wert = '')) and (Wert2 = '') then
    SQLStr := 'Select * from ' + Tabelle + ' where ' + Feld + '=''' + Wert + '''';

  if (Wert = '') and (not (Wert2 = '')) then
    SQLStr := 'Select * from ' + Tabelle + ' where ' + Feld2 + '=''' + Wert2 + '''';
  SQL_Get(Query, SQLStr);
  result := not Query.IsEmpty
end;

function SQL3GetBool(Query: TCO_Query; Tabelle: string; Feld: string; Wert: string; Feld2: string; Wert2: string; Feld3: string; Wert3: string): Boolean;
var
  SQLStr: string;
begin
  SQLStr := 'Select * from ' + Tabelle + ' where (' + Feld + '=''' + Wert + ''') AND(' + Feld2 + '=''' + Wert2 + ''')AND(' + Feld3 + '='''
    + Wert3 + ''')';

  if (Wert = '') and (Wert2 = '') then
    SQLStr := 'Select * from ' + Tabelle;

  if (not (Wert = '')) and (Wert2 = '') then
    SQLStr := 'Select * from ' + Tabelle + ' where ' + Feld + '=''' + Wert + '''';

  if (Wert = '') and (not (Wert2 = '')) then
    SQLStr := 'Select * from ' + Tabelle + ' where ' + Feld2 + '=''' + Wert2 + '''';

  SQL_Get(Query, SQLStr);
  result := not Query.IsEmpty;
end;

function SQLGet(Query: TCO_Query; Tabelle: string; Feld: string; Wert: string; Ergebnis: Boolean): Integer;
var
  SQLStr: string;
begin
  if Ergebnis then
  begin
    SQLStr := 'Select COUNT(*) CNT from ' + Tabelle + ' where ' + Feld + '=''' + Wert + '''';
    Query.Close;
    SQL_Get(Query, SQLStr);
    Result := Query.FieldByName('CNT').AsInteger;
  end
  else
    Result := -1;

  SQLStr := 'Select * from ' + Tabelle + ' where ' + Feld + '=''' + Wert + '''';
  SQL_Get(Query, SQLStr);
end;


function SQL2Get(Query: TCO_Query; Tabelle: string; Feld: string; Wert: string; Feld2: string; Wert2: string; Ergebnis: Boolean): Integer;
var
  SQLStr: string;
begin
  if Ergebnis then
  begin
    SQLStr := 'Select COUNT(*) CNT from ' + Tabelle + ' where (' + Feld + '=''' + Wert + ''') AND (' + Feld2 + '=''' + Wert2 + ''')';

    if (Wert = '') and (Wert2 = '') then
      SQLStr := 'Select COUNT(*) CNT from ' + Tabelle;

    if (not (Wert = '')) and (Wert2 = '') then
      SQLStr := 'Select COUNT(*) CNT from ' + Tabelle + ' where ' + Feld + '=''' + Wert + '''';

    if (Wert = '') and (not (Wert2 = '')) then
      SQLStr := 'Select COUNT(*) CNT from ' + Tabelle + ' where ' + Feld2 + '=''' + Wert2 + '''';

    Query.Close;
    SQL_Get(Query, SQLStr);
    Result := Query.FieldByName('CNT').AsInteger;
  end
  else
    Result := -1;

  SQLStr := 'Select * from ' + Tabelle + ' where (' + Feld + '=''' + Wert + ''') AND (' + Feld2 + '=''' + Wert2 + ''')';

  if (Wert = '') and (Wert2 = '') then
    SQLStr := 'Select * from ' + Tabelle;

  if (not (Wert = '')) and (Wert2 = '') then
    SQLStr := 'Select * from ' + Tabelle + ' where ' + Feld + '=''' + Wert + '''';

  if (Wert = '') and (not (Wert2 = '')) then
    SQLStr := 'Select * from ' + Tabelle + ' where ' + Feld2 + '=''' + Wert2 + '''';

  SQL_Get(Query, SQLStr);
end;

function SQL3Get(Query: TCO_Query; Tabelle: string; Feld: string; Wert: string; Feld2: string; Wert2: string;
  Feld3: string; Wert3: string; Ergebnis: Boolean): Integer;
var
  SQLStr: string;
begin
  if Ergebnis then
  begin
    SQLStr := 'Select COUNT(*) CNT from ' + Tabelle + ' where (' + Feld + '=''' + Wert + ''') AND(' + Feld2 + '=''' + Wert2 + ''')AND(' + Feld3
      + '=''' + Wert3 + ''')';

    if (Wert = '') and (Wert2 = '') then
      SQLStr := 'Select COUNT(*) CNT from ' + Tabelle;

    if (not (Wert = '')) and (Wert2 = '') then
      SQLStr := 'Select COUNT(*) CNT from ' + Tabelle + ' where ' + Feld + '=''' + Wert + '''';

    if (Wert = '') and (not (Wert2 = '')) then
      SQLStr := 'Select COUNT(*) CNT from ' + Tabelle + ' where ' + Feld2 + '=''' + Wert2 + '''';

    Query.Close;
    SQL_Get(Query, SQLStr);
    Result := Query.FieldByName('CNT').AsInteger;
  end
  else
    Result := -1;

  SQLStr := 'Select * from ' + Tabelle + ' where (' + Feld + '=''' + Wert + ''') AND(' + Feld2 + '=''' + Wert2 + ''')AND(' + Feld3 + '='''
    + Wert3 + ''')';

  if (Wert = '') and (Wert2 = '') then
    SQLStr := 'Select * from ' + Tabelle;

  if (not (Wert = '')) and (Wert2 = '') then
    SQLStr := 'Select * from ' + Tabelle + ' where ' + Feld + '=''' + Wert + '''';

  if (Wert = '') and (not (Wert2 = '')) then
    SQLStr := 'Select * from ' + Tabelle + ' where ' + Feld2 + '=''' + Wert2 + '''';

  SQL_Get(Query, SQLStr);
end;

procedure UpdateSQL(Query: TCO_Query; Tabelle: string; UpdateFeld: string; UpdateWert: string;
  WhereFeld: string; WhereWert: string);
var
  SQLStr: string;
begin
  SQLStr := 'UPDATE ' + Tabelle + ' SET ' + UpdateFeld + '=''' + UpdateWert + ''' where ' + WhereFeld + '=''' + WhereWert + '''';
  SQL_Insert(Query, SQLStr);
end;

procedure Update2SQL(Query: TCO_Query; Tabelle: string; UpdateFeld: string; UpdateWert: string;
  WhereFeld: string; WhereWert: string; WhereFeld2: string; WhereWert2: string);
var
  SQLStr: string;
begin
  SQLStr := 'UPDATE ' + Tabelle + ' SET ' + UpdateFeld + '=''' + UpdateWert + ''' where (' + WhereFeld + '=''' + WhereWert + ''') AND (' +
    WhereFeld2 + '=''' + WhereWert2 + ''')';
  SQL_Insert(Query, SQLStr);
end;

procedure DeleteSQL(Query: TCO_Query; Tabelle: string; Feld: string; Wert: string);
var
  SQLStr: string;
begin
  SQLStr := 'DELETE FROM ' + Tabelle + ' where ' + Feld + '=''' + Wert + '''';
  SQL_Insert(Query, SQLStr);
end;

function GetGlobalMemory_MB: string;
var
  memory: TMemoryStatus;
  S: string;
begin
  memory.dwLength := SizeOf(memory);
  GlobalMemoryStatus(memory);
  S := '[MB] MemTot:' + IntToStr(memory.dwTotalPhys div 1048576)
    + '-Free:' + IntToStr(memory.dwAvailPhys div 1048576)
    + '-PageTot:' + IntToStr(memory.dwTotalPageFile div 1048576)
    + '-PageFree:' + IntToStr(memory.dwAvailPageFile div 1048576)
    + '-VirtTot:' + IntToStr(memory.dwTotalVirtual div 1048576)
    + '-VirtFree:' + IntToStr(memory.dwAvailVirtual div 1048576)
    + '-Granted:' + IntToStr((memory.dwTotalPageFile - memory.dwAvailPageFile) div 1048576);

  Result := S;
end;

function ProcessMemory_KB(ProcessName : string): string;
var
  MemCounters: TProcessMemoryCounters;
  S: string;
begin
  MemCounters.cb := SizeOf(MemCounters);

  if GetProcessMemoryInfo(GetCurrentProcess, @MemCounters, SizeOf(MemCounters)) then
  begin
    S := IntToStr(MemCounters.WorkingSetSize div 1024);
    while Length(S) < 7 do
      S := ' ' + S;

    Result := S + ' [';

    S := IntToStr(MemCounters.PagefileUsage div 1024);
    while Length(S) < 7 do
      S := ' ' + S;

    Result := Result + S + ']';
  end
  else
    RaiseLastOSError;
end;

function CurrentProcessMemory_KBInt: Integer;
var
  MemCounters: TProcessMemoryCounters;
  S: string;
begin
  MemCounters.cb := SizeOf(MemCounters);
  if GetProcessMemoryInfo(GetCurrentProcess, @MemCounters, SizeOf(MemCounters)) then
  begin
    result := (MemCounters.WorkingSetSize div 1024);
  end
  else
    RaiseLastOSError;
end;


function CurrentProcessMemory_KB: string;
var
  MemCounters: TProcessMemoryCounters;
  S: string;
begin
  MemCounters.cb := SizeOf(MemCounters);
  if GetProcessMemoryInfo(GetCurrentProcess, @MemCounters, SizeOf(MemCounters)) then
  begin
    S := IntToStr(MemCounters.WorkingSetSize div 1024);
    while Length(S) < 7 do
      S := ' ' + S;

    Result := S + ' [';

    S := IntToStr(MemCounters.PagefileUsage div 1024);
    while Length(S) < 7 do
      S := ' ' + S;

    Result := Result + S + ']';
  end
  else
    RaiseLastOSError;
end;

function FloatToStr2(Value: Extended): string;
begin
  if INCLUDISDatabaseTyp = dbTypMSSQL then
  begin
    DecimalSeparator := '.';
    // ThousandSeparator := ',';
  end;

  Result := FloatToStr(Value);
end;

function FloatToStrF2(Value: Extended; Format: TFloatFormat; Precision, Digits: Integer): string;
begin
  if INCLUDISDatabaseTyp = dbTypMSSQL then
  begin
    DecimalSeparator := '.';
    // ThousandSeparator := ',';
  end;

  Result := FloatToStrF(Value, Format, Precision, Digits);
end;

function FloatToPunktStringF2(Value: Extended; Format: TFloatFormat; Precision, Digits: Integer): string;
begin
  Result := FloatToStrF(Value, Format, Precision, Digits);
//  if INCLUDISDatabaseTyp = dbTypMSSQL then
  begin
    if Pos(',', Result) > 0 then
    begin
      Insert('.', Result, Pos(',', Result));
      Delete(Result, Pos(',', Result), 1);
    end;
  end;
end;

end.

