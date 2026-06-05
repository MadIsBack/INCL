unit FlexKalender;

interface

uses Classes, StdCtrls, ASGSQLite3, CO_Database, Windows, Forms, Dialogs,SysUtils;

type
  TFlexKalender = class
  private
    schicht1 : integer;
    schicht2 : integer;
    schicht3 : integer;

    fDatabase : TCO_Database;
    fQuery1 : TCO_Query;
    fQuery2 : TCO_Query;

    fSQLiteDB : TASQLite3DB;
    fSQLiteQuery : TASQLite3Query;
    fSQLiteQuery2 : TASQLite3Query;
    fSQLiteUpdate : TASQLite3Query;

    fOwner : TComponent;

    procedure CreateTable;
    procedure CreateEntry(aStart, aEnde : extended; aGruppe : Integer);
    procedure SplittAllEntries(aStart, aEnde : Real; aGruppe : Integer);

    function incDatum(aDatetime : extended; aMinuten : integer):extended;
    function FloatToStrPunkt(aFloat:Extended):String;
  public
    function getArbeitsszeit(aStart, aEnde : extended; aGruppe : Integer):Integer;
    procedure Init;
    procedure Refresh;

    constructor Create(aOwner :TComponent; aQuery: TCO_Query);
end;

implementation

{ TFlexKalender }

constructor TFlexKalender.Create(aOwner :TComponent; aQuery: TCO_Query);
begin
  inherited create;
  fOwner := aOwner;
  fDatabase := aQuery.Database;

  fQuery1 := TCO_Query.Create(fOwner);
  fQuery1.Database := fDatabase;
  fQuery2 := TCO_Query.Create(fOwner);
  fQuery2.Database := fDatabase;

  fSQLiteDB := TASQLite3DB.Create(fOwner);
  fSQLiteDB.DefaultExt := '';
  fSQLiteDB.Database := ':memory:';
  fSQLiteQuery := TASQLite3Query.Create(fOwner);
  fSQLiteQuery.Connection := fSQLiteDB;
  fSQLiteQuery2 := TASQLite3Query.Create(fOwner);
  fSQLiteQuery2.Connection := fSQLiteDB;
  fSQLiteUpdate := TASQLite3Query.Create(fOwner);
  fSQLiteUpdate.Connection := fSQLiteDB;

  Init;
end;

procedure TFlexKalender.CreateEntry(aStart, aEnde: extended;
  aGruppe: Integer);
begin
  fSQLiteQuery.SQL.Text := 'INSERT INTO kalender_flex(kalgruppe, startdatumzeit, enddatumzeit, zeitraum) VALUES ('
    + IntToStr(aGruppe) + ','
    + FloatToStrPunkt(aStart) + ','+FloatToStrPunkt(aEnde) + ','''
    + IntToStr(round((aEnde-aStart)*1440)) + ''')';
  fSQLiteQuery.ExecSQL;

end;

procedure TFlexKalender.SplittAllEntries(aStart, aEnde : Real; aGruppe : Integer);
var maxtag, mintag, tag, kgruppe, knr : integer;
    kstart, kende : real;
begin
  // Alle Einträge suchen, in denen der Bereich liegt
  // So lange wiederholen bis der Bereich nirgends mehr drin liegt
  mintag := trunc(now);
  maxtag := trunc(now);
  fSQLiteQuery2.SQL.Text := 'SELECT max(enddatumzeit) maxende FROM kalender_flex WHERE kalgruppe = '+ IntToStr(aGruppe);
  fSQLiteQuery2.Open;
  if not fSQLiteQuery2.IsEmpty then
    maxtag := trunc(fSQLiteQuery2.FieldByName('maxende').AsFloat);

  fSQLiteQuery2.SQL.Text := 'SELECT min(startdatumzeit) minstart FROM kalender_flex WHERE kalgruppe = '+ IntToStr(aGruppe);
  fSQLiteQuery2.Open;
  if not fSQLiteQuery2.IsEmpty then
    mintag := trunc(fSQLiteQuery2.FieldByName('minstart').AsFloat);

  for tag := mintag to maxtag do
  begin
    fSQLiteQuery2.SQL.Text := 'SELECT * FROM '
      + ' kalender_flex WHERE kalgruppe = ' + IntToStr(aGruppe)
      + ' AND startdatumzeit < ' + FloatToStrPunkt(tag + aEnde) + ' AND enddatumzeit > '
      + FloatToStrPunkt(tag + aStart);
    fSQLiteQuery2.Open;
    if not fSQLiteQuery2.IsEmpty then
    begin
      kstart := fSQLiteQuery2.FieldByName('startdatumzeit').AsFloat;
      kende := fSQLiteQuery2.FieldByName('enddatumzeit').AsFloat;
      knr := fSQLiteQuery2.FieldByName('nr').AsInteger;
      if (tag + aStart <= kstart) and ( tag + aEnde >= kende) then // Pausenzeit ist größer als Eintrag -> löschen
      begin
        fSQLiteUpdate.SQL.Text := 'DELETE FROM kalender_flex WHERE nr = ' + IntToStr(knr);
        fSQLiteUpdate.ExecSQL;
      end
      else
      if tag + aEnde > kende then  // Pause fängt früher an, Eintragsende verschieben
      begin
        fSQLiteUpdate.SQL.Text := 'UPDATE kalender_flex SET enddatumzeit = ' + FloatToStrPunkt(tag + aStart) + ' WHERE nr = ' + IntToStr(knr);
        fSQLiteUpdate.ExecSQL;
      end
      else
      if tag + aStart < kstart then  // Pause hört später auf, Eintragsstart verschieben
      begin
        fSQLiteUpdate.SQL.Text := 'UPDATE kalender_flex SET startdatumzeit = ' + FloatToStrPunkt(tag + aEnde) + ' WHERE nr = ' + IntToStr(knr);
        fSQLiteUpdate.ExecSQL;
      end
      else // Eintrag splitten
      begin
        fSQLiteUpdate.SQL.Text := 'UPDATE kalender_flex SET enddatumzeit = ' + FloatToStrPunkt(tag + aStart) + ' WHERE nr = ' + IntToStr(knr);
        fSQLiteUpdate.ExecSQL;
        CreateEntry(tag + aEnde, kEnde, aGruppe);
      end;
    end;
  end;
end;


procedure TFlexKalender.CreateTable;
begin
  fSQLiteQuery.SQL.Text := 'CREATE TABLE kalender_flex('
          + ' NR Integer Primary Key, '
          + ' kalgruppe INTEGER,'
          + ' startdatumzeit FLOAT,'
          + ' enddatumzeit FLOAT,'
          + ' zeitraum INTEGER'
         + ')'; // neue Kalender TAbelle erzeugen
  try
    fSQLiteQuery.ExecSQL;
  except
  end;

  fSQLiteQuery.SQL.Text :='create Index kalender_flex_start on kalender_flex(startdatumzeit)';
  try
    fSQLiteQuery.ExecSQL;
  except
  end;

  fSQLiteQuery.SQL.Text :='create Index kalender_flex_ende on kalender_flex(enddatumzeit)';
  try
    fSQLiteQuery.ExecSQL;
  except
  end;

  fSQLiteQuery.SQL.Text :='create Index kalender_flex_gruppe on kalender_flex(kalgruppe)';
  try
    fSQLiteQuery.ExecSQL;
  except
  end;
end;

function TFlexKalender.FloatToStrPunkt(aFloat: Extended): String;
var sepchar : char;
begin
  sepchar := DecimalSeparator;
  DecimalSeparator := '.';
  result := FloatToStr(aFloat);
  DecimalSeparator := sepchar;
end;

function TFlexKalender.getArbeitsszeit(aStart, aEnde: extended;
  aGruppe: Integer): Integer;
var s : String;
begin
  fSQLiteQuery.SQL.Text := 'SELECT ROUND(SUM( (CASE WHEN enddatumzeit > ' + FloatToStrPunkt(aEnde)
    + ' THEN ' + FloatToStrPunkt(aEnde) + ' ELSE enddatumzeit END - '
    + 'CASE WHEN startdatumzeit < ' + FloatToStrPunkt(aStart)
    + ' THEN ' + FloatToStrPunkt(aStart) + ' ELSE startdatumzeit END ) * 1440)) sumsum '
    + 'FROM kalender_flex WHERE '
    + 'kalgruppe = ' + IntToStr(aGruppe) + ' AND startdatumzeit < '
    + FloatToStrPunkt(aEnde) + ' AND enddatumzeit > ' + FloatToStrPunkt(aStart);
  fSQLiteQuery.Open;
  if not fSQLiteQuery.IsEmpty then
    s := fSQLiteQuery.FieldByName('sumsum').AsString
  else
    s := '0';
  if s='' then s := '0';
  if (pos('.',s))>0 then
  begin
    Insert(DecimalSeparator,s,pos('.',s));
    delete(s,pos('.',s),1);
  end;

  result := round(StrToFloat(s));
end;

function TFlexKalender.incDatum(aDatetime: extended;
  aMinuten: integer): extended;
begin

end;

procedure TFlexKalender.Init;
begin
  CreateTable;
  fSQLiteQuery.sql.Text := 'delete from kalender_flex';
  try
    fSQLiteQuery.ExecSQL;
  except
  end;

  fQuery1.sql.Text := 'select * from setup';
  fQuery1.open;
  if not (fQuery1.IsEmpty) then
  begin
    schicht1 := fQuery1.FieldByName('schicht1').AsInteger;
    schicht2 := fQuery1.FieldByName('schicht2').AsInteger;
    schicht3 := fQuery1.FieldByName('schicht3').AsInteger;
  end
  else
  begin
    schicht1 := 360;
    schicht2 := 840;
    schicht3 := 1320;
  end;
  Refresh;
end;

procedure TFlexKalender.Refresh;
var zeitarray : array[0..16]of integer;
    zustandakt : array[0..16] of boolean; // true = aktiv, false = nicht aktiv
    zustandlast : array[0..16] of boolean; // true = aktiv, false = nicht aktiv
    start : array[0..16] of extended;
    ende : array[0..16] of extended;
    zeit12, zeit23, zeit31, bitfilter,  pgruppe : Integer;
    pstart, pende : Extended;
    i,schichtzeit, schicht, sollschichtzeit, schichtstart : Integer;
begin
    fSQLiteQuery.SQL.Text := 'DELETE FROM kalender_flex';
    fSQLiteQuery.ExecSQL;

    zeit12 := schicht2 - schicht1;
    zeit23 := schicht3 - schicht2;
    zeit31 := 1440-schicht3 + schicht1;

    for i := 0 to 16 do
    begin
      zeitarray[i] :=0;
      zustandakt[i] := false;
      zustandlast[i] := false;
    end;
    // Konvertieren von alten auf neuen Kalender
    fQuery1.SQL.Text := 'SELECT * FROM kalender ORDER BY datumint';
    fQuery1.Open;
    while not (fQuery1.Eof) do
    begin
      i := 0;
// *******************************  Berechung Start Gruppe 0 *****************************
      for schicht := 1 to 3 do
      begin
        schichtzeit := fQuery1.FieldByName('schicht'+IntToStr(schicht)).AsInteger;

        case schicht of
          1 : sollschichtzeit := zeit12;
          2 : sollschichtzeit := zeit23;
          3 : sollschichtzeit := zeit31;
        end;

        case schicht of
          1 : schichtstart := schicht1;
          2 : schichtstart := schicht2;
          3 : schichtstart := schicht3;
        end;


        case schicht of
          1 : bitfilter := 1;
          2 : bitfilter := 2;
          3 : bitfilter := 4;
        end;

        if schichtzeit = sollschichtzeit then
        begin
          zustandakt[i] := true;
          zeitarray[i] := zeitarray[i] + sollschichtzeit;
          if not zustandlast[i] then
            start[i] := fQuery1.FieldByName('datumint').AsFloat + (schichtstart)/1440;
          zustandlast[i] := true;
        end;

        if schichtzeit = 0 then
        begin
          zustandakt[i] := false;
          if zustandlast[i] then
          begin
            ende[i] := fQuery1.FieldByName('datumint').AsFloat + schichtstart/1440;
            CreateEntry(start[i], ende[i],i);
          end;
          zustandlast[i] := false;
        end;



        if (schichtzeit > 0) and (schichtzeit < sollschichtzeit) then
        begin
          if (fQuery1.FieldByName('schichtende_g'+IntToStr(i)).AsInteger AND bitfilter)>0 then
          begin
            zustandakt[i] := true;
            if zustandlast[i] then
            begin
              ende[i] := fQuery1.FieldByName('datumint').AsFloat + schichtstart/1440;
              CreateEntry(start[i], ende[i],i);
            end;
            start[i] := fQuery1.FieldByName('datumint').AsFloat + (schichtzeit + schichtstart)/1440;
            zustandlast[i] := true;
          end
          else
          begin
            zustandakt[i] := false;
            if not zustandlast[i] then
            begin
              start[i] := fQuery1.FieldByName('datumint').AsFloat + (schichtstart)/1440;
              zustandlast[i] := true;
            end;

            if zustandlast[i] then
            begin
              ende[i] := fQuery1.FieldByName('datumint').AsFloat + (schichtzeit +schichtstart)/1440;
              CreateEntry(start[i], ende[i],i);
            end;
            zustandlast[i] := false;
          end;
        end;
      end;

// Ende Spezialbehandlung Gruppe 0


      for i := 1 to 16 do
      begin
        for schicht := 1 to 3 do
        begin
          schichtzeit := fQuery1.FieldByName('gruppe'+IntToStr(i)+'_S'+IntToStr(schicht)).AsInteger;

          case schicht of
            1 : sollschichtzeit := zeit12;
            2 : sollschichtzeit := zeit23;
            3 : sollschichtzeit := zeit31;
          end;

          case schicht of
            1 : schichtstart := schicht1;
            2 : schichtstart := schicht2;
            3 : schichtstart := schicht3;
          end;

        case schicht of
          1 : bitfilter := 1;
          2 : bitfilter := 2;
          3 : bitfilter := 4;
        end;

          if schichtzeit = sollschichtzeit then
          begin
            zustandakt[i] := true;
            zeitarray[i] := zeitarray[i] + sollschichtzeit;
            if not zustandlast[i] then
              start[i] := fQuery1.FieldByName('datumint').AsFloat + (schichtstart)/1440;
            zustandlast[i] := true;
          end;

          if schichtzeit = 0 then
          begin
            zustandakt[i] := false;
            if zustandlast[i] then
            begin
              ende[i] := fQuery1.FieldByName('datumint').AsFloat + schichtstart/1440;
              CreateEntry(start[i], ende[i],i);
            end;
            zustandlast[i] := false;
          end;

          if (schichtzeit > 0) and (schichtzeit < sollschichtzeit) then
          begin
            if (fQuery1.FieldByName('schichtende_g'+IntToStr(i)).AsInteger AND bitfilter) > 0 then
            begin
              zustandakt[i] := true;
              if zustandlast[i] then
              begin
                ende[i] := fQuery1.FieldByName('datumint').AsFloat + schichtstart/1440;
                CreateEntry(start[i], ende[i],i);
              end;
              start[i] := fQuery1.FieldByName('datumint').AsFloat + (schichtzeit + schichtstart)/1440;
              zustandlast[i] := true;
            end
            else
            begin
              zustandakt[i] := false;

              if not zustandlast[i] then
              begin
                start[i] := fQuery1.FieldByName('datumint').AsFloat + (schichtstart)/1440;
                zustandlast[i] := true;
              end;

              if zustandlast[i] then
              begin
                ende[i] := fQuery1.FieldByName('datumint').AsFloat + (schichtzeit +schichtstart)/1440;
                CreateEntry(start[i], ende[i],i);
              end;
              zustandlast[i] := false;
            end;
          end;
        end;
      end;
      fQuery1.Next;
    end;
    // Jetzt Pausenzeiten holen und Einträge entsprechend splitten
    fQuery1.SQL.Text := 'SELECT * FROM pause ORDER BY kalendergruppe, startzeit';
    fQuery1.Open;
    while not (fQuery1.Eof) do
    begin
      // Wer weiß wie lange das dauern wird
      pstart := fQuery1.FieldByName('startzeit').AsFloat;
      pende := fQuery1.FieldByName('endzeit').AsFloat;
      pgruppe := fQuery1.FieldByName('kalendergruppenr').AsInteger;

      SplittAllEntries(pstart, pende, pgruppe);

      fQuery1.Next;
    end;
end;


end.
