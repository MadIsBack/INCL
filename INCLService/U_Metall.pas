unit U_Metall;

interface

uses
  CO_DataBase,
  {$IFNDEF AZURE}
  Main,
  {$ELSE}
  MainAzure,
  {$ENDIF}
  DBMain, DatenM, SQL_fuc, SysUtils, Controls, Arbeit;

procedure Check_Auftrag_Start;
procedure Check_Auftrag_Ende;
procedure Schreibe_Protokoll(StartEnde: Boolean; PDENr: Integer; index: Integer; Programm_Nr: Integer);
procedure Schreibe_Protokoll_Warmlaufprogramm(Maschine: string; Programm_Nr: Integer; index: Integer);
procedure Schreibe_Protokoll_StartEnde(Maschine: string; StartEnde: Boolean;
  Programm_Nr: Integer; Eigenschaft: string; Meldung: string);
procedure AAA_Freigabe_Auftrag_Starten(qSuch2: TCO_Query; PDENr: Integer);
function AAA_CheckWarmlaufProgramm(qUpdate: TCO_Query; Programm_Nr: Integer): Boolean;

implementation

uses
  comtas_h, Sprache_V63, utils;

procedure Check_Auftrag_Start;
var
  I: Integer;
  SQLStr, Meldung: string;
begin
  for I := 1 to Anzahl_Masch do
  begin
    if Includis[I].IstArchiviert then
      Continue;
    if Programm_Start[I].Istwert and (Programm_Nr[I].Istwert > 0) then
    begin

      SQLStr := 'SELECT COUNT(*) CNT from PDE where Programm_Nr = ' + IntToStr(Programm_Nr[I].Istwert)
        + ' AND (stat = 0 or stat = 1 or stat = 5 or stat = 6) AND Lizenz = ''' + Includis[I].Lizenz + '''';
      SQL_Get(Daten.qSuch, SQLStr);
      if Daten.qSuch.FieldByName('CNT').AsInteger > 0 then
      begin

        SQLStr := 'SELECT * from PDE where Programm_Nr = ' + IntToStr(Programm_Nr[I].Istwert)
          + ' AND (stat = 0 or stat = 1 or stat = 5 or stat = 6) AND Lizenz = ''' + Includis[I].Lizenz + '''';
        SQL_Get(Daten.qSuch, SQLStr);

        case Daten.qSuch.FieldByName('stat').AsInteger of

          stLaeuftInt:
            begin
              Schreibe_Protokoll(True, Daten.qSuch.FieldByName('Nr').AsInteger, I, Programm_Nr[I].Istwert);
              Meldung := 'Start OK.';
            end;

          stStartRuestenInt:
            begin
              Schreibe_Protokoll(True, Daten.qSuch.FieldByName('Nr').AsInteger, I, Programm_Nr[I].Istwert);
              Meldung := 'Start OK.';
            end;

          stFreigabeInt:
            begin
              Schreibe_Protokoll(True, Daten.qSuch.FieldByName('Nr').AsInteger, I, Programm_Nr[I].Istwert);
              AAA_Freigabe_Auftrag_Starten(Daten.qSuch2, Daten.qSuch.FieldByName('Nr').AsInteger);
              Meldung := GetL('Start OK. Auftrag gestartet...');
            end;

          stUnterbrochenInt:
            begin
              Schreibe_Protokoll(True, Daten.qSuch.FieldByName('Nr').AsInteger, I, Programm_Nr[I].Istwert);
              AAA_Freigabe_Auftrag_Starten(Daten.qSuch2, Daten.qSuch.FieldByName('Nr').AsInteger);
              Meldung := GetL('Start OK. Auftrag gestartet...');
            end;
        end;

        Schreibe_Protokoll_StartEnde(Includis[I].Lizenz, True, Programm_Nr[I].Istwert, Meldung, GetL('bekannt'));

      end
      else
      begin //if Daten.qSuch.FieldbyName('CNT').AsInteger > 0 then begin
        //Programm_Nr nicht gefunden !!!
        if AAA_CheckWarmlaufProgramm(Daten.qUpdate, Programm_Nr[I].Istwert) then
        begin
          Schreibe_Protokoll_Warmlaufprogramm(Includis[I].Lizenz, Programm_Nr[I].Istwert, I);
          Schreibe_Protokoll_StartEnde(Includis[I].Lizenz, True, Programm_Nr[I].Istwert,
            GetL('Warmlaufprogramm gestartet...'), GetL('bekannt'));
        end
        else
          //Laufende Programme beenden
          Schreibe_Protokoll(True, -1, I, Programm_Nr[I].Istwert);
        //Schreibe_Protokoll_Warmlaufprogramm(Includis[i].Lizenz,Programm_Nr[i].Istwert,i);
        SQLStr := ' SELECT betriebsauftragnr FROM maschinf WHERE lizenz = ''' + Includis[I].Lizenz + '''';
        SQL_Get(Daten.qSuch, SQLStr);
        if not Daten.qSuch.IsEmpty then
          LogUsrEvent(Daten.qSuch2, Daten.qUpdate, 128, 'WIA', Daten.qSuch.FieldByName('Betriebsauftragnr').AsString, '');

        S7Main.S7_Auftrag.Unterbrechen(Includis[I].Lizenz);
        Schreibe_Protokoll_StartEnde(Includis[I].Lizenz, True, Programm_Nr[I].Istwert,
          GetL('Programm-Nr. nicht freigegeben...'), GetL('unbekannt'));
      end;

      //Signal in SPS zurücksetzten
      S7Main.Schreibe_SPS_Wert(StrToInt(Includis[I].MaschNr), TTT_GetSignalNr(CPROGRAMM_NR), 0);
      UpdateSQL(Daten.qSuch, 'Signal_Maschine', 'Istwert', '0', 'nr', IntToStr(Programm_Nr[I].DBNr));
      S7Main.Schreibe_SPS_Wert(StrToInt(Includis[I].MaschNr), SigNoAuftrag_Start, 0);
      UpdateSQL(Daten.qSuch, 'Signal_Maschine', 'Istwert', '0', 'nr', IntToStr(Programm_Start[I].DBNr));

      S7Main.DatenLesen_Metall;
    end;
  end;

  for I := 1 to Anzahl_Masch do
  begin
    if Includis[I].IstArchiviert then
      Continue;
    if Programm_Start[I].Istwert then
      S7Main.Schreibe_SPS_Wert(StrToInt(Includis[I].MaschNr), SigNoAuftrag_Start, 0);
    UpdateSQL(Daten.qSuch, 'Signal_Maschine', 'Istwert', '0', 'nr', IntToStr(Programm_Start[I].DBNr));
  end;
end;

procedure Check_Auftrag_Ende;
var
  I: Integer;
begin
  for I := 1 to Anzahl_Masch do
  begin
    if Includis[I].IstArchiviert then
      Continue;

    if Programm_Ende[I].Istwert then
    begin

      SQLStr := 'SELECT COUNT(*) CNT from PDE where Programm_Nr = ' + IntToStr(Programm_Nr[I].Istwert)
        + ' AND (stat = 0 or stat = 1) AND Lizenz = ''' + Includis[I].Lizenz + '''';
      SQL_Get(Daten.qSuch, SQLStr);
      if Daten.qSuch.FieldByName('CNT').AsInteger > 0 then
      begin

        SQLStr := 'SELECT * from PDE where Programm_Nr = ' + IntToStr(Programm_Nr[I].Istwert)
          + ' AND (stat = 0 or stat = 1) AND Lizenz = ''' + Includis[I].Lizenz + '''';
        SQL_Get(Daten.qSuch, SQLStr);

        Schreibe_Protokoll(False, Daten.qSuch.FieldByName('Nr').AsInteger, I, Programm_Nr[I].Istwert);

        Schreibe_Protokoll_StartEnde(Includis[I].Lizenz, False, Programm_Nr[I].Istwert,
          'Ende OK.', 'bekannt');

      end
      else
      begin
        Schreibe_Protokoll(False, -1, I, Programm_Nr[I].Istwert);
        Schreibe_Protokoll_StartEnde(Includis[I].Lizenz, False, Programm_Nr[I].Istwert,
          GetL('Programm war nicht gestartet...'), GetL('unbekannt'));
      end;

      //Signal in SPS zurücksetzten
      S7Main.Schreibe_SPS_Wert(StrToInt(Includis[I].MaschNr), TTT_GetSignalNr(CPROGRAMM_NR), 0);
      UpdateSQL(Daten.qSuch, 'Signal_Maschine', 'Istwert', '0', 'nr', IntToStr(Programm_Nr[I].DBNr));
      S7Main.Schreibe_SPS_Wert(StrToInt(Includis[I].MaschNr), SigNoAuftrag_Ende, 0);
      UpdateSQL(Daten.qSuch, 'Signal_Maschine', 'Istwert', '0', 'nr', IntToStr(Programm_Ende[I].DBNr));

      S7Main.DatenLesen_Metall;
    end;
  end;
end;

procedure Schreibe_Protokoll(StartEnde: Boolean; PDENr: Integer; index: Integer; Programm_Nr: Integer);
var
  Palettenwechsel, RuestZeit, Laufzeit, Istwert: Integer;
  SQLStr, Liz, BetriebsauftragNr: string;
  Taktzeit, laufzeitdiff: Integer;
  TPM_Start: Real;
  TPM_Stat_Nr: Integer;
begin

  if StartEnde then
  begin
    //Programm wurde gestartet...
    if SQLGet(Daten.qSuch2, 'PDE', 'Nr', IntToStr(PDENr), True) > 0 then
    begin
      Liz := Daten.qSuch2.FieldByName('Lizenz').AsString;
      BetriebsauftragNr := Daten.qSuch2.FieldByName('Betriebsauftragnr').AsString;
      Taktzeit := Round(Daten.qSuch2.FieldByName('Taktzeit').AsInteger / 60 / 100);
    end
    else
    begin
      Liz := Includis[index].Maschine;
      BetriebsauftragNr := 'unbekannt';
      Taktzeit := 0;
    end;

    //Prüfen, ob noch andere Programme auf dieser Maschine laufen...
    //wenn ja, dann beenden
    if SQL2Get(Daten.qSuch3, 'PDEPROT', 'Maschine', Liz, 'EndeDatumZeit', '0', True) > 0 then
    begin
      Daten.qSuch3.First;
      while not Daten.qSuch3.EOF do
      begin
        //Programme beenden...

        if Daten.qSuch3.FieldByName('Programm_Nr').AsInteger = Programm_Nr then
          Exit;

        Schreibe_Protokoll(False, Daten.qSuch3.FieldByName('PDE_Nr').AsInteger, index, Programm_Nr);
        Daten.qSuch3.Next;
      end;
    end;

    //***************************************************************
    // Palettenwechsel berechnen
    //***************************************************************
    SQLStr := 'select * from PDEPROT where Maschine = '''
      + Liz + ''' order by StartDatumZeit';
    SQL_Get(Daten.qUpdate, SQLStr);
    Daten.qUpdate.Last;
    Palettenwechsel := Round((N_o_w - Daten.qUpdate.FieldByName('EndeDatumZeit').AsFloat) * 1440);
    TPM_Start := Daten.qUpdate.FieldByName('EndeDatumZeit').AsFloat;

    //Letzte Störung buchen
    if Palettenwechsel > 3 then
    begin

      SQLStr := 'delete from TPM_Stillog where MaschNr = ' + Includis[index].MaschNr
        + ' AND Stillstandnr = 2 AND Geht = 0';

      // SQL_Insert(Daten.qUpdate, SQLStr);

      SQLStr := 'delete from TPM_Stillog where MaschNr = ' + Includis[index].MaschNr
        + ' AND Stillstandnr = 2 '
        + ' AND KOMMT > ''' + FloatToStr2(TPM_Start) + ''' AND GEHT < ''' + FloatToStr2(N_o_w) + '''';

      // SQL_Insert(Daten.qUpdate, SQLStr);

      SQLStr := 'INSERT INTO TPM_Stillog (Nr,MaschNr,Schicht,Kommt,Stillstandnr,KommtStr, '
        + ' Reaktionszeit,Geht,GehtStr,Dauer)'
        + ' VALUES(TPM_StillogID.Nextval'
        + ',''' + Includis[index].MaschNr
        + ''',''' + IntToStr(Includis[index].Schicht)
        + ''',''' + FloatToStr2(TPM_Start)
        + ''',''' + IntToStr(10)
        + ''',''' + DateToStr(TPM_Start) + ' ' + TimeToStr(Frac(TPM_Start))
        + ''',''0'
        + ''',''' + FloatToStr2(N_o_w)
        + ''',''' + DateToStr(N_o_w) + ' ' + TimeToStr(Frac(N_o_w))
        + ''',''' + IntToStr(Palettenwechsel)
        + ''')';

      SQL_Insert(Daten.qUpdate, SQLStr);
    end;
    //***************************************************************

    if SQLGet(Daten.qUpdate, 'PDE', 'Nr', IntToStr(PDENr), True) > 0 then
      Istwert := Daten.qUpdate.FieldByName('Istwert').AsInteger
    else
      Istwert := -1;
    Inc(Istwert);

    if Palettenwechsel < 0 then
      Palettenwechsel := 0;

    RuestZeit := 0;
    Laufzeit := 0;

    SQLStr := 'INSERT INTO PDEPROT (Nr,PDE_Nr,Maschine,Programm_Nr,BetriebsauftragNr,StartDatumZeit,EndeDatumZeit,'
      + 'Laufzeit,Sollaufzeit,Palettenwechsel,Ruestzeit, Menge)'
      + 'VALUES(PDEPROTID.NextVal'
      + ',''' + IntToStr(PDENr)
      + ''',''' + Liz
      + ''',''' + IntToStr(Programm_Nr)
      + ''',''' + BetriebsauftragNr
      + ''',''' + FloatToStr2(N_o_w)
      + ''',''0'
      + ''',''' + IntToStr(Laufzeit)
      + ''',''' + IntToStr(Taktzeit)
      + ''',''' + IntToStr(Palettenwechsel)
      + ''',''' + IntToStr(RuestZeit)
      + ''',''' + IntToStr(Istwert)
      + ''')';

    SQL_Insert(Daten.qUpdate, SQLStr);

    UpdateSQL(Daten.qUpdate, 'MASCHINF', 'Programm_Start', FloatToStr2(N_o_w), 'Maschine', Liz);

  end
  else
  begin
    //Programm wurde beendet
    if PDENr = -1 then
    begin
      //unbekanntes Programm
      SQLStr := 'select COUNT(*) CNT from PDEPROT where (PDE_NR = -1) AND MAschine = ''' + Includis[index].Maschine + ''' AND EndeDatumZeit = 0';
      SQL_Get(Daten.qSuch4, SQLStr);
      if Daten.qSuch4.FieldByName('CNT').AsInteger > 0 then
      begin
        SQLStr := 'select * from  PDEPROT where (PDE_NR = -1) AND MAschine = ''' + Includis[index].Maschine + ''' AND EndeDatumZeit = 0';
        SQL_Get(Daten.qSuch4, SQLStr);
        Daten.qSuch4.First;
        while not Daten.qSuch4.EOF do
        begin
          //Programme beenden...
          Laufzeit := Round((N_o_w - Daten.qSuch4.FieldByName('StartDatumZeit').AsFloat) * 1440);
          if Laufzeit < 0 then
            Laufzeit := 0;
          Istwert := 0;
          laufzeitdiff := Daten.qSuch4.FieldByName('Sollaufzeit').AsInteger - Laufzeit;

          SQLStr := 'update PDEPROT set '
            + 'EndeDatumZeit =         ' + FloatToPunktString(N_o_w)
            + ',Laufzeit =           ''' + IntToStr(Laufzeit)
            + ''',laufzeitdiff =       ''' + IntToStr(laufzeitdiff)
            + ''',Menge =              ''' + IntToStr(Istwert)
            + ''' where (Nr = ' + IntToStr(Daten.qSuch4.FieldByName('Nr').AsInteger) + ')';

          SQL_Insert(Daten.qUpdate, SQLStr);

          Daten.qSuch4.Next;
        end;
      end;
      Exit;
    end;

    if SQL2Get(Daten.qSuch4, 'PDEPROT', 'PDE_NR', IntToStr(PDENr), 'EndeDatumZeit', '0', True) > 0 then
    begin
      Daten.qSuch4.First;
      while not Daten.qSuch4.EOF do
      begin
        //Programme beenden...
        Laufzeit := Round((N_o_w - Daten.qSuch4.FieldByName('StartDatumZeit').AsFloat) * 1440);
        if Laufzeit < 0 then
          Laufzeit := 0;

        if SQLGet(Daten.qUpdate, 'PDE', 'Nr', IntToStr(PDENr), True) > 0 then
          Istwert := Daten.qUpdate.FieldByName('Istwert').AsInteger
        else
          Istwert := -1;
        Inc(Istwert);
        Inc(Includis[index].StueckAuftragSchicht);
        Inc(StueckSchicht[index].Istwert);
        Inc(Includis[index].Auftrag.StueckSchicht);

        laufzeitdiff := Daten.qSuch4.FieldByName('Sollaufzeit').AsInteger - Laufzeit;

        SQLStr := 'update PDEPROT set '
          + 'EndeDatumZeit =         ' + FloatToPunktString(N_o_w)
          + ',Laufzeit =           ''' + IntToStr(Laufzeit)
          + ''',laufzeitdiff =       ''' + IntToStr(laufzeitdiff)
          + ''',Menge =              ''' + IntToStr(Istwert)
          + ''' where (Nr = ' + IntToStr(Daten.qSuch4.FieldByName('Nr').AsInteger) + ')';

        SQL_Insert(Daten.qUpdate, SQLStr);

        UpdateSQL(Daten.qUpdate, 'PDE', 'Istwert', IntToStr(Istwert), 'Nr', IntToStr(PDENr));
        UpdateSQL(Daten.qUpdate, 'PDE', 'StueckSchicht', IntToStr(Includis[index].Auftrag.StueckSchicht), 'Nr', IntToStr(PDENr));

        SQLStr := 'Select Nr from tpm_schicht where Betriebsauftragnr = ''' + Includis[index].Auftrag.BetriebsauftragNr
          + ''' AND (maschnr =''' + Includis[index].MaschNr + ''') AND(Schicht ='''
          + IntToStr(Includis[index].Schicht) + ''')AND(Datum ='''
          + DateToStrSQL(Trunc(Jetzt)) + ''') order by nr';
        SQL_Get(Daten.qUpdate, SQLStr);
        TPM_Stat_Nr := Daten.qUpdate.FieldByName('Nr').AsInteger;
        UpdateSQL(Daten.qUpdate, 'tpm_schicht', 'produziert', IntToStr(Includis[index].Auftrag.StueckSchicht), 'Nr', IntToStr(TPM_Stat_Nr));

        Daten.qSuch4.Next;
      end;
    end;
  end;
end;

procedure Schreibe_Protokoll_Warmlaufprogramm(Maschine: string; Programm_Nr: Integer; index: Integer);
var
  Laufzeit, Istwert: Integer;
  SQLStr: string;
  laufzeitdiff, PDENr: Integer;
begin
  if SQL2Get(Daten.qSuch4, 'PDEPROT', 'Maschine', Maschine, 'EndeDatumZeit', '0', True) > 0 then
  begin
    Daten.qSuch4.First;
    while not Daten.qSuch4.EOF do
    begin
      //Programme beenden...
      Laufzeit := Round((N_o_w - Daten.qSuch4.FieldByName('StartDatumZeit').AsFloat) * 1440);
      if Laufzeit < 0 then
        Laufzeit := 0;

      if SQL2Get(Daten.qUpdate, 'PDE', 'Lizenz', Maschine, 'stat', '0', True) > 0 then
      begin
        Istwert := Daten.qUpdate.FieldByName('Istwert').AsInteger;
        PDENr := Daten.qUpdate.FieldByName('Nr').AsInteger;
      end
      else
      begin
        Istwert := -1;
        PDENr := -1;
      end;
      Inc(Istwert);

      Inc(Includis[index].StueckAuftragSchicht);
      Inc(StueckSchicht[index].Istwert);

      laufzeitdiff := Daten.qSuch4.FieldByName('Sollaufzeit').AsInteger - Laufzeit;

      SQLStr := 'update PDEPROT set '
        + 'EndeDatumZeit =         ' + FloatToPunktString(N_o_w)
        + ',Laufzeit =           ''' + IntToStr(Laufzeit)
        + ''',laufzeitdiff =       ''' + IntToStr(laufzeitdiff)
        + ''',Menge =              ''' + IntToStr(Istwert)
        + ''' where (Nr = ' + IntToStr(Daten.qSuch4.FieldByName('Nr').AsInteger) + ')';

      SQL_Insert(Daten.qUpdate, SQLStr);

      UpdateSQL(Daten.qUpdate, 'PDE', 'Istwert', IntToStr(Istwert), 'Nr', IntToStr(PDENr));

      Daten.qSuch4.Next;
    end;
  end;
end;

procedure Schreibe_Protokoll_StartEnde(Maschine: string; StartEnde: Boolean;
  Programm_Nr: Integer; Eigenschaft: string; Meldung: string);
const
  CSTART = 'Start';
  CEnde = 'Ende';
var
  SQLStr: string;
begin
  if StartEnde then
    SQLStr := 'INSERT INTO Programm_Prot (Nr,Maschine,Programm_Nr,DatumZeit,StartDatumZeit,EndeDatumZeit,Status,Eigenschaft,Meldung)'
      + 'VALUES(Programm_ProtID.NextVal'
      + ',''' + Maschine
      + ''',''' + IntToStr(Programm_Nr)
      + ''',''' + FloatToStr2(N_o_w)
      + ''',''' + FloatToStr2(N_o_w)
      + ''',''0'
      + ''',''' + CSTART
      + ''',''' + Eigenschaft
      + ''',''' + Meldung
      + ''')'
  else
    SQLStr := 'INSERT INTO Programm_Prot (Nr,Maschine,Programm_Nr,DatumZeit,StartDatumZeit,EndeDatumZeit,Status,Eigenschaft,Meldung)'
      + 'VALUES(Programm_ProtID.NextVal'
      + ',''' + Maschine
      + ''',''' + IntToStr(Programm_Nr)
      + ''',''' + FloatToStr2(N_o_w)
      + ''',''0'
      + ''',''' + FloatToStr2(N_o_w)
      + ''',''' + CEnde
      + ''',''' + Eigenschaft
      + ''',''' + Meldung
      + ''')';

  SQL_Insert(Daten.qUpdate, SQLStr);
end;

procedure AAA_Freigabe_Auftrag_Starten(qSuch2: TCO_Query; PDENr: Integer);
var
  SQLStr: string;
  Liz, Auftrag: string;
begin
  if SQLGet(qSuch2, 'PDE', 'Nr', IntToStr(PDENr), True) > 0 then
  begin
    Liz := qSuch2.FieldByName('Lizenz').AsString;
    Auftrag := qSuch2.FieldByName('Betriebsauftragnr').AsString;

    //Prüfen, ob ein anderer Auftrag auf der Maschine läuft...
    SQLStr := 'SELECT COUNT(*) CNT from PDE where Lizenz = ''' + Liz + ''''
      + ' AND (stat = 0 or stat = 1)';
    SQL_Get(qSuch2, SQLStr);
    if qSuch2.FieldByName('CNT').AsInteger > 0 then
    begin
        SQLStr := ' SELECT betriebsauftragnr FROM maschinf WHERE lizenz = ''' + Liz + '''';
        SQL_Get(qSuch2, SQLStr);
        if not qSuch2.IsEmpty then
          LogUsrEvent(Daten.qSuch3,Daten.qUpdate, 128, 'WIA', qSuch2.FieldByName('Betriebsauftragnr').AsString, '');
      S7Main.S7_Auftrag.Unterbrechen(Liz);
    end;

    S7Main.S7_Auftrag.Starten(Liz, Auftrag, False);
    LogUsrEvent(Daten.qSuch3,Daten.qUpdate,126, 'WSA', Auftrag, '');

    S7Main.S7_Auftrag.Laufende_Auftraege_Terminieren;
    S7Main.S7_Auftrag.Autoterminierung;

    S7Main.Metall_Freigabe_Auftrag_Gestartet := True;
  end;
end;

function AAA_CheckWarmlaufProgramm(qUpdate: TCO_Query; Programm_Nr: Integer): Boolean;
begin
  Result := False;
  if SQLGet(qUpdate, 'WARMPROGRAMM', 'Programm_Nr', IntToStr(Programm_Nr), True) > 0 then
    Result := True;
end;

end.

