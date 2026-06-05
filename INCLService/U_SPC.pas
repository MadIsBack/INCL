unit U_SPC;

interface

uses
  {$IFNDEF AZURE}
  Main,
  {$ELSE}
  MainAzure,
  {$ENDIF}
  DBMain, DatenM, SQL_fuc, SysUtils, Controls, CO_SPC_V63;

procedure SPC_Init;
procedure SPC_Aktuelle_Werte_Schreiben;
procedure SPC_Stichproben_Schreiben;
procedure SPC_SchichtProtokoll_Schreiben;
procedure SPC_Schichtberechnung(SI: Integer; aSPC :TCO_SPC);
function GetLastStichprobe(index: Integer): Integer;
function CheckSPCDaten(index: Integer): Boolean;
function CheckAusreisser(index: Integer): Boolean;
function CheckSPC_Stich_Daten(index: Integer): Boolean;
function CheckVorSchicht: Boolean;
procedure DeleteAusreisserSchicht;
procedure DeleteAusreisserStich;
procedure SPC_SollIstVergleich;

procedure SPC_Stich_Schreiben;

implementation

uses
  Sprache_V63, Arbeit, comtas_h, CO_Setup2, Classes, SPCUtility;

procedure SPC_Init;
var
  I, J: Integer;
  SQLStr: string;
begin

  SQLStr := 'select * from QSPCSETUP';
  SQL_Get(Daten.qSuch3, SQLStr);

  for I := 1 to Anzahl_Masch do
  begin
    if Includis[I].IstArchiviert then
      Continue;

    if Daten.qSuch3.Locate('MASCHINE', Includis[I].Lizenz, []) then
    begin

      for J := 0 to Length(SPC_Signal[I].Signal) - 1 do
      begin
        SPC_Signal[I].Sollwert[J] := Daten.qSuch3.FieldByName('Sollwert_' + SPC_Signal[I].Signal[J]).AsFloat;
        SPC_Signal[I].TOL1P[J] := Daten.qSuch3.FieldByName('TOL1P_' + SPC_Signal[I].Signal[J]).AsInteger;
        SPC_Signal[I].TOL1N[J] := Daten.qSuch3.FieldByName('TOL1N_' + SPC_Signal[I].Signal[J]).AsInteger;
        SPC_Signal[I].TOL2P[J] := Daten.qSuch3.FieldByName('TOL2P_' + SPC_Signal[I].Signal[J]).AsInteger;
        SPC_Signal[I].TOL2N[J] := Daten.qSuch3.FieldByName('TOL2N_' + SPC_Signal[I].Signal[J]).AsInteger;
        SPC_Signal[I].Stichproben[J] := Daten.qSuch3.FieldByName('STICH_' + SPC_Signal[I].Signal[J]).AsInteger;
        if Daten.qSuch3.FieldByName('SPCAKT_' + SPC_Signal[I].Signal[J]).AsInteger = 1 then
          SPC_Signal[I].Aktiv[J] := True
        else
          SPC_Signal[I].Aktiv[J] := False;
        SPC_Save[I].X_Schuss := SPC_Signal[I].Stichproben[J];
      end;

    end
    else
    begin

      for J := 0 to Length(SPC_Signal[I].Signal) - 1 do
      begin
        SPC_Signal[I].Sollwert[J] := 0;
        SPC_Signal[I].TOL1P[J] := 0;
        SPC_Signal[I].TOL1N[J] := 0;
        SPC_Signal[I].TOL2P[J] := 0;
        SPC_Signal[I].TOL2N[J] := 0;
        SPC_Signal[I].Stichproben[J] := 0;
        SPC_Signal[I].Aktiv[J] := False;
        SPC_Save[I].AuftragNr := '';
      end;
    end;
  end;
end;

procedure SPC_Aktuelle_Werte_Schreiben;
var
  I, J: Integer;
  StatStr: string;
  Nr: Integer;
  Abw: Integer;
begin
  for I := 1 to Anzahl_Masch do
  begin

    if Includis[I].Lizenz = '' then
      Continue;

    if not Includis[I].SPC_Aktiv or Includis[I].IstArchiviert then
      Continue;

    StatStr := GetL('kein Auftrag');
    if Includis[I].Auftrag.Stat = stLaeuftInt then
      StatStr := GetL('läuft');
    if Includis[I].Auftrag.Stat = stStartRuestenInt then
      StatStr := GetL('Rüsten');

    if SQLGet(Daten.qSuch, 'QSPCAKTUELL', 'MASCHINE', Includis[I].Lizenz, True) = 0 then
    begin

      SQLStr := 'INSERT INTO QSPCAKTUELL  (Nr,MASCHINE,AUFTRAGNR ,DATUMZEIT ,STATUS  ';
      for J := 0 to Length(SPC_Signal[I].Signal) - 1 do
        SQLStr := SQLStr + ',IST_' + SPC_Signal[I].Signal[J]
          + ',SOLLWERT_' + SPC_Signal[I].Signal[J]
          + ',TOL1P_' + SPC_Signal[I].Signal[J]
          + ',TOL1N_' + SPC_Signal[I].Signal[J]
          + ',TOL2P_' + SPC_Signal[I].Signal[J]
          + ',TOL2N_' + SPC_Signal[I].Signal[J]
          + ',ABW_' + SPC_Signal[I].Signal[J];

      SQLStr := SQLStr + ')';

      SQLStr := SQLStr + 'VALUES(QSPCAKTUELLID.NextVal'
        + ',''' + Includis[I].Lizenz
        + ''',''' + Includis[I].Auftrag.BetriebsauftragNr
        + ''',''' + FloatToStr2(Jetzt)
        + ''',''' + StatStr;

      for J := 0 to Length(SPC_Signal[I].Signal) - 1 do
      begin
        if SPC_Signal[I].Sollwert[J] > 0 then
          Abw := Round((SPC_Signal[I].Istwert[J] - SPC_Signal[I].Sollwert[J]) * 100 / SPC_Signal[I].Sollwert[J])
        else
          Abw := 0;
        SQLStr := SQLStr + ''',''' + FloatToStrF2(SPC_Signal[I].Istwert[J], ffFixed, 10, 2)
          + ''',''' + FloatToStrF2(SPC_Signal[I].Sollwert[J], ffFixed, 10, 2)
          + ''',''' + IntToStr(SPC_Signal[I].TOL1P[J])
          + ''',''' + IntToStr(SPC_Signal[I].TOL1N[J])
          + ''',''' + IntToStr(SPC_Signal[I].TOL2P[J])
          + ''',''' + IntToStr(SPC_Signal[I].TOL2N[J])
          + ''',''' + IntToStr(Abw);
      end;

      SQLStr := SQLStr + ''')';

      SQL_Insert(Daten.qUpdate, SQLStr);
    end
    else
    begin
      //Datensatz vorhanden, also nur Update
      Nr := Daten.qSuch.FieldByName('Nr').AsInteger;

      SQLStr := 'update QSPCAKTUELL set '
        + 'AUFTRAGNR =               ''' + Includis[I].Auftrag.BetriebsauftragNr
        + ''',DATUMZEIT =          ''' + FloatToStr2(Jetzt)
        + ''',STATUS =             ''' + StatStr;

      for J := 0 to Length(SPC_Signal[I].Signal) - 1 do
      begin
        if SPC_Signal[I].Sollwert[J] > 0 then
          Abw := Round((SPC_Signal[I].Istwert[J] - SPC_Signal[I].Sollwert[J]) * 100 / SPC_Signal[I].Sollwert[J])
        else
          Abw := 0;
        SQLStr := SQLStr + ''',IST_' + SPC_Signal[I].Signal[J] + ' = ''' + FloatToStrF2(SPC_Signal[I].Istwert[J], ffFixed, 10, 2)
          + ''',SOLLWERT_' + SPC_Signal[I].Signal[J] + ' = ''' + FloatToStrF2(SPC_Signal[I].Sollwert[J], ffFixed, 10, 2)
          + ''',TOL1P_' + SPC_Signal[I].Signal[J] + ' = ''' + IntToStr(SPC_Signal[I].TOL1P[J])
          + ''',TOL1N_' + SPC_Signal[I].Signal[J] + ' = ''' + IntToStr(SPC_Signal[I].TOL1N[J])
          + ''',TOL2P_' + SPC_Signal[I].Signal[J] + ' = ''' + IntToStr(SPC_Signal[I].TOL2P[J])
          + ''',TOL2N_' + SPC_Signal[I].Signal[J] + ' = ''' + IntToStr(SPC_Signal[I].TOL2N[J])
          + ''',ABW_' + SPC_Signal[I].Signal[J] + ' = ''' + IntToStr(Abw);
      end;
      SQLStr := SQLStr + ''' where Nr = ' + IntToStr(Nr);

      SQL_Insert(Daten.qUpdate, SQLStr);
    end;
  end;
end;

procedure SPC_Stichproben_Schreiben;
var
  I, J: Integer;
  Schuss: Integer;
begin

  if not CheckVorSchicht then
    Exit;
  for I := 1 to Anzahl_Masch do
  begin

    if not Includis[I].SPC_Aktiv or Includis[I].IstArchiviert then
      Continue;

    if not (Includis[I].Auftrag.Stat = 0) then
      Continue; //Auftrag läuft
    if not (Includis[I].Zustand = 0) then
      Continue; // Maschine Programmbetrieb (grün)

    //Stückzahl erhöt, also SPC schreiben
    Schuss := StueckAuftragGesamt[I].Istwert;

    //Neuer Auftrag gestartet??
    if SPC_Save[I].AuftragNr <> Includis[I].Auftrag.BetriebsauftragNr then
    begin
      SPC_Save[I].Last_SchichtProtokoll_Schuss := 0;
      SPC_Save[I].Last_Stichprobe_Schuss := 0;
      SPC_Save[I].AuftragNr := Includis[I].Auftrag.BetriebsauftragNr;
      Stich_Zaehler[I] := 0;
    end;

    if ((SPC_Save[I].Last_Stichprobe_Schuss + SPC_Save[I].X_Schuss) <= Schuss)
      or (Stich_Zaehler[I] > 0) then
    begin

      if Stich_Zaehler[I] >= 10 + 1 then
      begin
        Stich_Zaehler[I] := 0;
        Continue;
      end;

      Stich_Zaehler[I] := Stich_Zaehler[I] + 1;

      if not CheckSPCDaten(I) then
        Continue; //Jeder SPC Wert größer 0 ??
      if not CheckAusreisser(I) then
        Continue; // Jeder Wert innerhalb der gültigen Grenzen, kein techischer Ausreisser?

      SQLStr := 'SELECT * FROM QSPCSTICH WHERE nr = (SELECT MAX(nr) FROM qspcstich '
        + ' WHERE maschine = ''' + Includis[I].Lizenz
        + ''' AND auftragnr = ''' + Includis[I].Auftrag.BetriebsauftragNr
        + ''') AND schuss = ''' + IntToStr(Schuss) + '''';
      //          + ' AND datumzeit > ''' + FloatToStr2(N_o_w - 1 / 24) + '''';

      (*
            SQLStr := 'SELECT * FROM QSPCSTICH WHERE maschine = ''' + Includis[I].Lizenz
              + ''' AND datumzeit > ''' + FloatToStr2(N_o_w - 1 / 24)
              + ''' AND auftragnr = ''' + Includis[I].Auftrag.BetriebsauftragNr
              + ''' AND schuss = ''' + IntToStr(Schuss) + '''';
      *)
      SQL_Get(Daten.qSuch3, SQLStr);

      if not Daten.qSuch3.IsEmpty then
      begin
        // Wenn der letzte aufgezeichnete Schuss der gleiche war, dann nicht noch einmal aufzeichnen
(*
        SQL_Get(Daten.qSuch3, SQLStr);
        if not Daten.qSuch3.IsEmpty then
        *)
        Continue;
      end;

      SPC_Save[I].Last_Stichprobe_Schuss := Schuss;
      SPC_Save[I].AuftragNr := Includis[I].Auftrag.BetriebsauftragNr;

      SQLStr := 'INSERT INTO QSPCSTICH  (Nr,MASCHINE,AUFTRAGNR ,DATUMZEIT , DATUMZEITSTR,SCHICHT , SCHUSS ';
      for J := 0 to Length(SPC_Signal[I].Signal) - 1 do
        SQLStr := SQLStr + ',IST_' + SPC_Signal[I].Signal[J] + ',SOLLWERT_' + SPC_Signal[I].Signal[J];

      SQLStr := SQLStr + ')';

      SQLStr := SQLStr + 'VALUES(QSPCSTICHID.NextVal'
        + ',''' + Includis[I].Lizenz
        + ''',''' + Includis[I].Auftrag.BetriebsauftragNr
        + ''',''' + FloatToStr2(Jetzt)
        + ''',''' + DateTimeToStr(Jetzt)
        + ''',''' + IntToStr(Includis[I].Schicht)
        + ''',''' + IntToStr(Schuss);

      for J := 0 to Length(SPC_Signal[I].Signal) - 1 do
        SQLStr := SQLStr + ''',''' + FloatToStrF2(SPC_Signal[I].Istwert[J], ffFixed, 10, 2) + ''',''' + FloatToStrF2(SPC_Signal[I].Sollwert[J], ffFixed, 10,
          2);

      SQLStr := SQLStr + ''')';
      SQL_Insert(Daten.qUpdate, SQLStr);
    end;
  end;
end;

procedure SPC_SchichtProtokoll_Schreiben;
var
  I, J: Integer;
  Schuss: Integer;
begin

  for I := 1 to Anzahl_Masch do
  begin

    if not Includis[I].SPC_Aktiv or Includis[I].IstArchiviert then
      Continue;
    //if NOT SPC_Save[i].SPC then Continue;
    if not (Includis[I].Auftrag.Stat = 0) then
      Continue; //Auftrag läuft
    if not (Includis[I].Zustand = 0) then
      Continue; // Maschine Programmbetrieb (grün)

    //if NOT CheckSPCDaten(i) then Continue;        //Jeder SPC Wert größer 0 ??
    if not CheckAusreisser(I) then
      Continue; // Jeder Wert innerhalb der gültigen Grenzen, kein techischer Ausreisser?

    //Neuer Auftrag gestartet??
    if SPC_Save[I].AuftragNr <> Includis[I].Auftrag.BetriebsauftragNr then
    begin
      SPC_Save[I].Last_SchichtProtokoll_Schuss := 0;
      SPC_Save[I].Last_Stichprobe_Schuss := 0;
      SPC_Save[I].AuftragNr := Includis[I].Auftrag.BetriebsauftragNr;
    end;

    Schuss := StueckAuftragGesamt[I].Istwert;

    SPC_Save[I].Last_SchichtProtokoll_Schuss := Schuss;
    SPC_Save[I].AuftragNr := Includis[I].Auftrag.BetriebsauftragNr;

    if SQL2Get(Daten.qUpdateS, 'QSPCSCHICHT', 'AUFTRAGNR', Includis[I].Auftrag.BetriebsauftragNr,
      'SCHUSS', IntToStr(Schuss), True) = 0 then
    begin

      SQLStr := 'INSERT INTO QSPCSCHICHT (Nr,MASCHINE,AUFTRAGNR ,DATUMZEIT ,SCHICHT,  SCHUSS ';
      for J := 0 to Length(SPC_Signal[I].Signal) - 1 do
        SQLStr := SQLStr + ',IST_' + SPC_Signal[I].Signal[J] + ',SOLLWERT_' + SPC_Signal[I].Signal[J];

      SQLStr := SQLStr + ')';

      SQLStr := SQLStr + 'VALUES(QSPCSCHICHTID.NextVal'
        + ',''' + Includis[I].Lizenz
        + ''',''' + Includis[I].Auftrag.BetriebsauftragNr
        + ''',''' + FloatToStr2(Jetzt)
        + ''',''' + IntToStr(Includis[I].Schicht)
        + ''',''' + IntToStr(Schuss);

      for J := 0 to Length(SPC_Signal[I].Signal) - 1 do
        SQLStr := SQLStr + ''',''' + FloatToStrF2(SPC_Signal[I].Istwert[J], ffFixed, 10, 2) + ''','''
          + FloatToStrF2(SPC_Signal[I].Sollwert[J], ffFixed, 10, 2);

      SQLStr := SQLStr + ''')';

      SQL_Insert(Daten.qUpdateS, SQLStr);
    end;

    SQLStr := 'delete from qspcschicht where (auftragNr <> ''' + Includis[I].Auftrag.BetriebsauftragNr
      + ''') AND (MASCHINE = ''' + Includis[I].Lizenz + ''')';
    SQL_Insert(Daten.qUpdateS, SQLStr);

  end;

  //  DeleteAusreisserStich;
  //  DeleteAusreisserSchicht;

end;

procedure SPC_Schichtberechnung(SI: Integer; aSPC :TCO_SPC);
var
  I: Integer;
begin
  for I := 1 to Anzahl_Masch do
  begin
    if not Includis[I].SPC_Aktiv OR Includis[I].IstArchiviert then
      Continue;
    if Includis[I].Auftrag.BetriebsauftragNr <> '' then
    begin
//      S7Main.cSPC.MaschNr := StrToInt(Includis[I].MaschNr);
//      S7Main.cSPC.AuftragNr := Includis[I].Auftrag.BetriebsauftragNr;
//      S7Main.cSPC.Schicht := SI;
//      S7Main.cSPC.SPC_Berechnung_Schicht;
      aSPC.MaschNr := StrToInt(Includis[I].MaschNr);
      aSPC.AuftragNr := Includis[I].Auftrag.BetriebsauftragNr;
      aSPC.Schicht := SI;
      aSPC.SPC_Berechnung_Schicht;
    end;
  end;
end;

function GetLastStichprobe(index: Integer): Integer;
var
  SQLStr: string;
begin
  SQLStr := 'select MAX(Schuss) CNT from QSPCSTICH where Maschine = ''' + Includis[index].Lizenz + '''';
  SQL_Get(Daten.qSuch, SQLStr);
  Result := Daten.qSuch.FieldByName('CNT').AsInteger;
end;

function CheckSPCDaten(index: Integer): Boolean;
var
  J: Integer;
begin
  Result := True;
  for J := 0 to Length(SPC_Signal[index].Istwert) - 1 do
    if (SPC_Signal[index].Istwert[J] < 0.01) and (SPC_Signal[index].Aktiv[J]) then
    begin
      Result := False;
      Exit;
    end;
end;

function CheckAusreisser(index: Integer): Boolean;
var
  J: Integer;
begin
  Result := True;
  if SPC_Check_Toleranz = 0 then
    Exit;

  for J := 0 to Length(SPC_Signal[index].Istwert) - 1 do
    if (SPC_Signal[index].Istwert[J] > (SPC_Signal[index].Sollwert[J] * (1 + (SPC_Check_Toleranz / 100))))
      or (SPC_Signal[index].Istwert[J] < (SPC_Signal[index].Sollwert[J] * (1 - (SPC_Check_Toleranz / 100)))) then
    begin
      Result := False;
      Exit;
    end;
end;

function CheckVorSchicht: Boolean;
var fracnow : extended;
begin
  Result := True;
  if SPC_NichtAufzeichnenVorSchicht > 0 then
  begin
    fracnow := Frac(N_o_w + SPC_NichtAufzeichnenVorSchicht / 1440);
    case Includis[1].Schicht of
      1:
        if fracnow > Schicht2 then
          Result := False;
      2:
        if fracnow > Schicht3 then
          Result := False;
      3:
        if fracnow > Schicht1 then
          Result := False;
    end;
  end;

end;

procedure DeleteAusreisserSchicht;
var
  signame, SQLStr: string;
  I, J, mxcnt: Integer;
  SL: TStringList;
  sm: TSPCMaschine;
  ss: TSPCSchuss;
  sv: TSPCValue;
begin
  try
    if SPC_Ausreisser_Loeschen > 0 then // Letzte n+1 Schüsse nach Ausreißern suchen und ggf. löschen
    begin
      for I := 1 to Anzahl_Masch do
      begin
        sm := TSPCMaschine.Create;
        sm.Lizenz := Includis[I].Lizenz;
        sm.MaschNr := Includis[I].Datenblock;

        // letzten n +2 Schüsse von allen Maschinen holen
        mxcnt := SPC_Ausreisser_Loeschen + 2;
        SQLStr := 'SELECT * FROM qspcschicht WHERE maschine = ''' + Includis[I].Lizenz
          + ''' AND auftragnr = ''' + Includis[I].Auftrag.BetriebsauftragNr + ''' ORDER BY nr DESC';
        // Aktueller Schuss muss OK sein
        // Letzter abgerufender Schuss muss auch OK sein.
        Daten.qSuch.SQL.Text := SQLStr;
        Daten.qSuch.Open;
        while (not Daten.qSuch.EOF) and (mxcnt > 0) do
        begin
          Dec(mxcnt);
          ss := TSPCSchuss.Create;
          ss.Nr := Daten.qSuch.FieldByName('nr').AsInteger;
          ss.Schuss := Daten.qSuch.FieldByName('schuss').AsInteger;
          for J := 0 to Length(SPC_Signal[I].Istwert) - 1 do
          begin
            if SPC_Signal[I].Aktiv[J] then
            begin
              signame := 'IST_' + SPC_Signal[I].Signal[J];
              sv := TSPCValue.Create;
              sv.Nr := SPC_Signal[I].SignalNr[J];
              sv.Name := SPC_Signal[I].Signal[J];
              sv.Ist := Daten.qSuch.FieldByName(signame).AsFloat;
              sv.MaxValue := SPC_Signal[I].Sollwert[J] * (1 + SPC_Signal[I].TOL2P[J] / 100);
              sv.MinValue := SPC_Signal[I].Sollwert[J] * (1 - SPC_Signal[I].TOL2N[J] / 100);
              ss.ValueList.Add(sv);
            end;
          end;
          sm.SchussList.Add(ss);
          Daten.qSuch.Next;
        end;

        // Resultat ansehen
        if sm.SchussList.Count > 0 then
          if sm.IsOKFirst and sm.IsOKLast then
          begin
            // erster und letzter Schuss dürfen maximal 20 Schuss auseinander sein.
            if ABS(sm.SchussList.Items[sm.SchussList.Count - 1].Schuss - sm.SchussList.Items[0].Schuss) < sm.SchussList.Count + 5 then
            begin
              SL := sm.getErrorList;
              if SL <> nil then
              begin
                for J := 0 to SL.Count - 1 do
                begin
                  Daten.qUpdate.SQL.Text := 'DELETE FROM qspcschicht WHERE nr = ' + SL.Strings[J];
                  Daten.qUpdate.ExecSQL;
                end;
                SL.Free;
              end;
            end;
          end;
        sm.Destroy;
      end;
    end;
  except
  end;

end;

procedure DeleteAusreisserStich;
var
  signame, SQLStr: string;
  I, J, mxcnt: Integer;
  SL: TStringList;
  sm: TSPCMaschine;
  ss: TSPCSchuss;
  sv: TSPCValue;
begin
  try
    if SPC_Ausreisser_Loeschen > 0 then // Letzte n+1 Schüsse nach Ausreißern suchen und ggf. löschen
    begin
      for I := 1 to Anzahl_Masch do
      begin
        sm := TSPCMaschine.Create;
        sm.Lizenz := Includis[I].Lizenz;
        sm.MaschNr := Includis[I].Datenblock;

        // letzten n +2 Schüsse von allen Maschinen holen
        mxcnt := SPC_Ausreisser_Loeschen + 2;
        SQLStr := 'SELECT * FROM qspcstich WHERE maschine = ''' + Includis[I].Lizenz
          + ''' AND auftragnr = ''' + Includis[I].Auftrag.BetriebsauftragNr + ''' ORDER BY nr DESC';
        // Aktueller Schuss muss OK sein
        // Letzter abgerufender Schuss muss auch OK sein.
        Daten.qSuch.SQL.Text := SQLStr;
        Daten.qSuch.Open;
        while (not Daten.qSuch.EOF) and (mxcnt > 0) do
        begin
          Dec(mxcnt);
          ss := TSPCSchuss.Create;
          ss.Nr := Daten.qSuch.FieldByName('nr').AsInteger;
          ss.Schuss := Daten.qSuch.FieldByName('schuss').AsInteger;
          for J := 0 to Length(SPC_Signal[I].Istwert) - 1 do
          begin
            if SPC_Signal[I].Aktiv[J] then
            begin
              signame := 'IST_' + SPC_Signal[I].Signal[J];
              sv := TSPCValue.Create;
              sv.Nr := SPC_Signal[I].SignalNr[J];
              sv.Name := SPC_Signal[I].Signal[J];
              sv.Ist := Daten.qSuch.FieldByName(signame).AsFloat;
              sv.MaxValue := SPC_Signal[I].Sollwert[J] * (1 + SPC_Signal[I].TOL2P[J] / 100);
              sv.MinValue := SPC_Signal[I].Sollwert[J] * (1 - SPC_Signal[I].TOL2N[J] / 100);
              ss.ValueList.Add(sv);
            end;
          end;
          sm.SchussList.Add(ss);
          Daten.qSuch.Next;
        end;

        // Resultat ansehen
        if sm.SchussList.Count > 0 then
          if sm.IsOKFirst and sm.IsOKLast then
          begin
            // erster und letzter Schuss dürfen maximal 20 Schuss auseinander sein.
            if ABS(sm.SchussList.Items[sm.SchussList.Count - 1].Schuss - sm.SchussList.Items[0].Schuss) < sm.SchussList.Count + 5 then
            begin
              SL := sm.getErrorList;
              if SL <> nil then
              begin
                for J := 0 to SL.Count - 1 do
                begin
                  Daten.qUpdate.SQL.Text := 'DELETE FROM qspcstich WHERE nr = ' + SL.Strings[J];
                  Daten.qUpdate.ExecSQL;
                end;
                SL.Free;
              end;
            end;
          end;
        sm.Destroy;
      end;
    end;
  except
  end;

end;

function CheckSPC_Stich_Daten(index: Integer): Boolean;
var
  J: Integer;
begin
  Result := False;
  if Length(SPC_Signal[index].Istwert) < 1 then
    Exit;
  for J := 0 to Length(SPC_Signal[index].Istwert) - 1 do
    if SPC_Signal[index].Istwert[J] = 0 then
    begin
      Result := False;
      Exit;
    end;
  Result := True;
end;

procedure SPC_SollIstVergleich;
var
  I, J: Integer;
  Soll_P, Soll_N: Real; //Absolutwert positiv und negative Toleranz
  zyk: Integer;
  _delCyk: Integer;
  _dtMinuten: Integer;
  _neuerAuftrag: Boolean;
  Zeit_zum_SPCAuftrag: Extended;
  S: string;
begin
  Zeit_zum_SPCAuftrag := TCO_Setup.GetParamInt(Daten.qSuch5, 'SPC_Zeit_zum_Auftrag');
  _delCyk := TCO_Setup.GetParamInt(Daten.qSuch5, 'SPC_AutoConfirmMessageAfterNGoodCycles');
  _dtMinuten := TCO_Setup.GetParamInt(Daten.qSuch5, 'SPC_DeleteMessageAfterNMinutesDowntime');
  for I := 1 to Anzahl_Masch do
  begin
    If Includis[I].IstArchiviert then
      Continue;

    if (Includis[I].Zustand <> stLaeuftInt) and (_dtMinuten > 0) then
    begin
      for J := 0 to Length(SPC_Signal[I].Signal) - 1 do
        if SPC_Signal[I].MeldungAktiv[J] then
        begin
          // ggf. Job löschen
          S := 'SELECT kommt FROM tpm_stillog WHERE maschnr = ' + Includis[I].MaschNr + ' and geht = 0';
          SQL_Get(Daten.qUpdate, S);
          if not Daten.qUpdate.IsEmpty then
            if Daten.qUpdate.FieldByName('kommt').AsFloat < N_o_w + _dtMinuten / 1440 then
            begin
              Daten.qUpdate.SQL.Text := 'DELETE FROM BDA WHERE bezeichnung = '''
                + GetL('SPC: Abweichung ') + SPC_Signal[I].Signal[J]
                + ''' AND lizenz = ''' + Includis[I].Lizenz + '''';
              Daten.qUpdate.ExecSQL;
              SPC_Signal[I].MeldungAktiv[J] := False;
            end;
        end;
    end
    else
      if (Includis[I].Auftrag.BetriebsauftragNr <> '') and (Includis[I].Zustand = stLaeuftInt) then
      begin
        if not Includis[I].SPC_Aktiv then
          Continue;
        _neuerAuftrag := False;

        if Includis[I].Auftrag.BetriebsauftragNr <> SPC_Signal[I].Auftrag then
        begin
          _neuerAuftrag := True;
          SPC_Signal[I].Auftrag := Includis[I].Auftrag.BetriebsauftragNr;
        end;

        try
          zyk := Trunc(Includis[I].StueckAuftragGesamt / Includis[I].Kopfgroesse);
        except
          zyk := 0;
        end;

        for J := 0 to Length(SPC_Signal[I].Signal) - 1 do
        begin
          if _neuerAuftrag then
            SPC_Signal[I].LetzteAbweichung[J] := 0;

          Soll_P := SPC_Signal[I].Sollwert[J] + ((SPC_Signal[I].Sollwert[J] * SPC_Signal[I].TOL2P[J]) / 100);
          Soll_N := SPC_Signal[I].Sollwert[J] - ((SPC_Signal[I].Sollwert[J] * SPC_Signal[I].TOL2N[J]) / 100);
          if SPC_Signal[I].Aktiv[J] and ((SPC_Signal[I].Istwert[J] > Soll_P) or (SPC_Signal[I].Istwert[J] < Soll_N)) then
          begin
            //Signal hat Abweichung!!!
            if SPC_Signal[I].LetzteAbweichung[J] = 0 then
            begin
              //Init
              SPC_Signal[I].LetzteAbweichung[J] := N_o_w;
              SPC_Signal[I].LetzterGuterSchuss[J] := zyk - 1;
              SPC_Signal[I].ErsterSchlechterSchuss[J] := zyk;

              Continue;
            end;

            if (SPC_Signal[I].LetzteAbweichung[J] + (Zeit_zum_SPCAuftrag / 1440)) < N_o_w then
            begin
              // JOB ERZEUGEN!!!
              SPC_Signal[I].LetzteAbweichung[J] := 0;
              SPC_Signal[I].MeldungAktiv[J] := True;
              SPC_Signal[I].ErsterGuterSchuss[J] := 0;
              CCC_Job_erzeugen(Daten.qUpdate, Includis[I].Lizenz, GetL('SPC: Abweichung ') + SPC_Signal[I].Signal[J],
                GetL('SPC'), GetL('SPC-Vergleich'), '', '', True, zyk);
            end;
          end
          else
          begin
            if SPC_Signal[I].LetzteAbweichung[J] > 0 then
            begin
              //Signal hat keine Abweichung, also TimeMerker zurückstellen
              SPC_Signal[I].LetzteAbweichung[J] := 0;
            end;
            if SPC_Signal[I].ErsterGuterSchuss[J] = 0 then
            begin
              SPC_Signal[I].LetzterSchlechterSchuss[J] := zyk - 1;
              SPC_Signal[I].ErsterGuterSchuss[J] := zyk;
            end;
          end;

          if SPC_Signal[I].MeldungAktiv[J] then
          begin
            // ggf. Job löschen
            if (_delCyk > 0) and (SPC_Signal[I].ErsterGuterSchuss[J] > 0) then
              if (zyk - SPC_Signal[I].ErsterGuterSchuss[J]) > _delCyk then
              begin
                Daten.qUpdate.SQL.Text := 'DELETE FROM BDA WHERE bezeichnung = '''
                  + GetL('SPC: Abweichung ') + SPC_Signal[I].Signal[J]
                  + ''' AND lizenz = ''' + Includis[I].Lizenz + '''';
                Daten.qUpdate.ExecSQL;
                SPC_Signal[I].MeldungAktiv[J] := False;
              end;
          end;
        end;
      end;
  end;
end;

procedure SPC_Stich_Schreiben;
var
  I, J: Integer;
  Schuss: Integer;
  Tmp: Boolean;
begin
  Tmp := False;

  for I := 1 to Anzahl_Masch do
  begin
    If Includis[I].IstArchiviert then
      Continue;

    //Stückzahl erhöt, also SPC schreiben
    Schuss := StueckAuftragGesamt[I].Istwert;
    if Schuss = GetLastStichprobe(I) then
      Continue;

    if not Includis[I].SPC_Aktiv then
      Continue;
    if not CheckSPC_Stich_Daten(I) then
      Continue; //Jeder SPC Wert größer 0 ??

    SQLStr := 'SELECT * FROM QSPCSTICH WHERE maschine = ''' + Includis[I].Lizenz
      + ''' AND auftragnr = ''' + Includis[I].Auftrag.BetriebsauftragNr
      + ''' AND schuss = ''' + IntToStr(Schuss) + '''';

    SQL_Get(Daten.qSuch3, SQLStr);

    if not Daten.qSuch3.IsEmpty then
      Continue;

    SQLStr := 'INSERT INTO QSPCSTICH  (Nr,MASCHINE,AUFTRAGNR ,DATUMZEIT , DATUMZEITSTR,SCHICHT , SCHUSS ';
    for J := 0 to Length(SPC_Signal[I].Signal) - 1 do
      SQLStr := SQLStr + ',IST_' + SPC_Signal[I].Signal[J] + ',SOLLWERT_' + SPC_Signal[I].Signal[J];

    SQLStr := SQLStr + ')';

    SQLStr := SQLStr + 'VALUES(QSPCSTICHID.NextVal'
      + ',''' + Includis[I].Lizenz
      + ''',''' + Includis[I].Auftrag.BetriebsauftragNr
      + ''',''' + FloatToStr2(Jetzt)
      + ''',''' + DateTimeToStr(Jetzt)
      + ''',''' + IntToStr(Includis[I].Schicht)
      + ''',''' + IntToStr(Schuss);

    for J := 0 to Length(SPC_Signal[I].Signal) - 1 do
      SQLStr := SQLStr + ''',''' + FloatToStrF2(SPC_Signal[I].Istwert[J], ffFixed, 10, 2) + ''',''' + FloatToStrF2(SPC_Signal[I].Sollwert[J], ffFixed, 10, 2);

    SQLStr := SQLStr + ''')';

    Daten.qUpdate.Close;
    Daten.qUpdate.SQL.Clear;
    Daten.qUpdate.SQL.Add(SQLStr);
    Daten.qUpdate.ExecSQL;

    //Quittung schreiben
    if not Tmp then
    begin

      SQLStr := 'update signal_maschine set istwert = 0 where Nr = ' + IntToStr(SPC_Signal[I].DBNr[0]);
      SQL_Insert(Daten.qUpdate, SQLStr);

      SQLStr := 'INSERT INTO SIGNAL_SCHREIBEN (Nr,MaschNr,SignalNr,Wert)'
        + 'VALUES(SIGNAL_SCHREIBENId.NextVal'
        + ',''' + Includis[I].MaschNr
        + ''',''' + IntToStr(SPC_Signal[I].SignalNr[0])
        + ''',''0'
        + ''')';
      // SQL_INSERT(Daten.qUpdate, SQLSTR);

      //tmp:= True;
    end;

  end;

end;

end.

