unit CO_Library2_V63;

interface

uses
  CO_DataBase, SysUtils, Windows, Forms, DBTables, StdCtrls, ComCtrls;

procedure SQL_Get(Query: TCO_Query; SQLStr: string);
function SQLGet(Query: TCO_Query; Tabelle: string; Feld: string; Wert: string; Ergebnis: Boolean): Integer;
procedure SQL_Insert(Query: TCO_Query; SQLStr: string);

function GetMaschNr(qTmp: TCO_Query; Maschine: string): Integer;
function isMaschOnline(qTmp: TCO_Query; Maschine: string): Boolean;
function FloatToPunktString(aFloat: Extended): string;

function GetAuftragLaufZeit(q1, q2: TCO_Query; BANr: string): Integer;
procedure HandleSystemError(Sender: TObject; E: Exception; aCustomString: string);

procedure WriteLog(aString: string);

implementation

//==============================================================================

procedure SQL_Get(Query: TCO_Query; SQLStr: string);
begin
  Query.Close;
  Query.SQL.Clear;
  Query.SQL.Add(SQLStr);
  Query.Open;
  Query.First;
end;
//==============================================================================

function SQLGet(Query: TCO_Query; Tabelle: string; Feld: string; Wert: string; Ergebnis: Boolean): Integer;
var
  SQLStr: string;
begin
  if Ergebnis then
  begin
    SQLStr := 'Select COUNT(*) as CNT from ' + Tabelle + ' where ' + Feld + '=''' + Wert + '''';
    Query.Close;
    SQL_Get(Query, SQLStr);
    Result := Query.FieldByName('CNT').AsInteger;
  end
  else
    Result := -1;

  SQLStr := 'Select * from ' + Tabelle + ' where ' + Feld + '=''' + Wert + '''';
  SQL_Get(Query, SQLStr);
end;
//==============================================================================

procedure SQL_Insert(Query: TCO_Query; SQLStr: string);
begin
  Query.Active := False;
  Query.SQL.Clear;
  Query.SQL.Add(SQLStr);
  Query.ExecSQL;
  Query.Active := False;
end;
//==============================================================================

function GetMaschNr(qTmp: TCO_Query; Maschine: string): Integer;
var
  Tmp: Integer;
begin
  Result := -1;
  Tmp := SQLGet(qTmp, 'MASCHINE', 'Lizenz', Maschine, True);
  if Tmp > 0 then
    Result := qTmp.FieldByName('MaschNr').AsInteger
  else
  begin
    Tmp := SQLGet(qTmp, 'MaschOffline', 'Lizenz', Maschine, True);
    if Tmp > 0 then
      Result := qTmp.FieldByName('MaschNr').AsInteger
  end;
end;
//==============================================================================

function isMaschOnline(qTmp: TCO_Query; Maschine: string): Boolean;
begin
  Result := SQLGet(qTmp, 'MASCHINE', 'Lizenz', Maschine, True) > 0;
end;
//==============================================================================

function GetAuftragLaufZeit(q1, q2: TCO_Query; BANr: string): Integer;
var
  S, Liz: string;
  MaschNr: Integer;
  Start, Ende, lZeit, SZeit: Real;
begin
  Result := 0;
  if SQLGet(q1, 'AARchiv', 'BetriebsAuftragNr', BANr, True) > 0 then
  begin
    Liz := q1.FieldByName('Maschine').AsString;
    MaschNr := GetMaschNr(q1, Liz);
    if isMaschOnline(q1, Liz) then
    begin
      lZeit := 0;
      SQLGet(q1, 'LaufzeitLog', 'BetriebsAuftragNr', BANr, False);
      while not q1.EOF do
      begin
        Start := q1.FieldByName('AuftragStart').AsFloat;
        Ende := q1.FieldByName('AuftragEnde').AsFloat;
        if Ende = 0 then
          Ende := Now;
        if Start = 0 then
          Start := Ende;

        S := 'select Sum(Least(Decode(Geht, 0,99999, Geht), '''
          + FloatToStr(Ende) + ''') - Greatest(Kommt, ''' + FloatToStr(Start) + ''')) as CNT'
          + ' from TPM_Stillog, TPM_Stillstaende where MaschNr = ' + IntToStr(MaschNr)
          + ' and TPM_Stillog.StillstandNr = TPM_Stillstaende.StillstandNr and TPM_Stillstaende.StillstandNr = 3'
          + ' and Least(Decode(Geht, 0, 99999, Geht), '''
          + FloatToStr(Ende) + ''') - Greatest(Kommt, ''' + FloatToStr(Start) + ''') > 0';
        SQL_Get(q2, S);
        try
          SZeit := q2.FieldByName('CNT').AsFloat;
        except
          SZeit := 0;
        end;
        lZeit := lZeit + Ende - Start - SZeit;
        q1.Next;
      end;
      Result := Round(lZeit * 1440);
    end
    else // für Offline Maschinen  //Sascha 24.02.2005
    begin
      S := 'select Sum(Duration) as CNT from Rework where JobNo = ''' + BANr + '''';
      SQL_Get(q1, S);
      try
        Result := q1.FieldByName('CNT').AsInteger;
      except
        Result := 0;
      end;
    end;
  end;
end;
//==============================================================================
function FloatToPunktString(aFloat: Extended): string;
begin
  Result := FloatToStr(aFloat);
  if Pos(',', Result) > 0 then
  begin
    Insert('.', Result, Pos(',', Result));
    Delete(Result, Pos(',', Result), 1);
  end;
end;


//==============================================================================

procedure HandleSystemError(Sender: TObject; E: Exception; aCustomString: string);
var
  S: string;
  ClassRef: TClass;
  ClassThree: string;
begin

  try
    ClassThree := E.ClassName;
    ClassRef := E.ClassType;
    while ClassRef.ClassParent <> nil do
    begin
      ClassRef := ClassRef.ClassParent;
      ClassThree := ClassRef.ClassName + ' => ' + ClassThree;
    end;
  except
  end;

  S := '--- This report is created by automated reporting system.' + #13#10
    + 'Form            : [' + SCREEN.ActiveForm.Name + ']' + #13#10
    + 'EXE-File        : [' + Application.ExeName + ']' + #13#10
    + 'DateTime        : [' + DateTimeToStr(Now) + ']' + #13#10
    + 'ClassThree      : [' + ClassThree + ']' + #13#10
    + 'Message         : [' + E.message + ']' + #13#10
    + 'Comment         : [' + aCustomString + ']' + #13#10
    + '--- End of report ---------------------------------------' + #13#10;

  WriteLog(S);
end;

procedure WriteLog(aString: string);
var
  F: TextFile;
  S: string;
  tmpFile: file of Byte;
  I, L: Integer;
  TRACEFILE: string;
begin
  S := Application.ExeName;
  I := Length(S);
  while S[Length(S)] <> '.' do
    Delete(S, Length(S), 1);
  TRACEFILE := S + 'log';
  if not FileExists(TRACEFILE) then
  begin
    AssignFile(F, TRACEFILE);
{$I-}
    Rewrite(F);
{$I+}
  end
  else
  begin

    //Größe der Datei prüfen
    AssignFile(tmpFile, TRACEFILE);
    Reset(tmpFile);
    L := FileSize(tmpFile);
    CloseFile(tmpFile);

    AssignFile(F, TRACEFILE);
{$I-}
    if L > (1024 * 1024) then
      Rewrite(F) //Datei löschen, weil zu groß
    else
      Append(F); //an Datei anhängen
{$I+}

  end;

  if ioResult <> 0 then
    Application.ProcessMessages;

  S := DateTimeToStr(Now) + ':   ' + aString;
  WriteLn(F, aString);

  CloseFile(F);
end;

end.

