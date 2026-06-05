unit Arbeit;

interface

uses
  {$IFNDEF AZURE}
  Main,
  {$ELSE}
  MainAzure,
  {$ENDIF}
  CO_DataBase, Windows, DBMain, Math, DatenM, Variants, SysUtils, Controls,
  SvcMgr, CO_INCMeldung_V63, SQL_fuc, Classes, CO_Auftrag_V63, SchichtUtilLib, ActiveX;

type
  TCavChange = record
    BetriebsauftragNr: string;
    Datum: TDateTime;
    Alt: Integer;
    Neu: Integer;
    Produziert: Integer;
    Schusszaehler: Integer;
  end;  

type
  TAuftrag = record
    BetriebsauftragNr: string;
    BetriebsauftragNr_Alt: string;
    AuftragNr: string;
    Bezeichnung: string;
    Zustaendig: string;
    Signal: string;
    Sollwert: Integer;
    SollwertOffset: Integer;
    Istwert: Integer;
    Ist_PRZ: Integer;
    Ausschuss: Integer;
    Verpackt: Integer;
    Anfahrausschuss: Integer;
    Vorwarnung: Integer;
    Erzeugt: Boolean;
    VorwarnungErzeugt: Boolean;
    Stat: Smallint;
    Solltakt: Integer;
    StartDatum: TDateTime;
    EndeDatum: TDateTime;
    EndeDatumSTR: string;
    LTSOLL: Real;
    LTIST: Real;
    LT1, LT2: Real;
    Werkzeug: Integer;
    WerkzeugNr: string;
    WerkzeugMerker: Integer; //Anzahl Schuss des letzten Zyklus
    IstStandzeit: Integer;
    Einsatzdauer: Integer;
    HalbAuto: Boolean;
    Kopfgroesse: Integer;
    KAVITAET_SOLL: Integer;
    InPause: Integer;
    Var_Kavitaet: Integer;
    StueckSchicht: Integer;
    Schwesterauftrag: string;
    Kunde: string;
    Form: string;
    Programm_Nr: Integer;
    MasterAuftrag: Boolean;
    PersonalZeit: Real;
    Optimiert: Integer;
    OptimiertAktuell: Integer;
    ImStatusOptimieren: Integer;
    Packgroesse: Integer;
    PALETTENGROESSE: Integer;
    SchichtLaufzeit: Integer;
    planzykluszeit: Integer;
    ausschussquote: Integer;
    SollSpannzeitStk: Integer;
    SollSpannzeitGes: Integer;
    InterBezeichnung: string;
    LetzerKavWechsel: TCavChange;
    WasReset: BOOL;
    SchichtAuftragsLaufzeit: Integer;
    GesamtLaufzeit : Integer;
    BaNrLaufzeit : string;
    Mustern : Boolean;
  end;

type
  TBDE = record
    Bezeichnung: string;
    Zustaendig: string;
    Signal: string;
    Sollwert: Integer;
    Istwert: Integer;
    Ist_PRZ: Integer;
    Vorwarnung: Integer;
    Erzeugt: Boolean;
    VorwarnungErzeugt: Boolean;
  end;

type
  TTPM = record
    Stillstand: Boolean;
    Fehlercode: string;
    Gebucht: Integer;
  end;

type
  TIncludis = record
    Lizenz: string;
    Maschine: string;
    KURZKENNUNG: string;
    MaschNr: string;
    MaschNrEcht: string;
    SORT_MASCHPANEL: Integer;
    MaschAktiv: Boolean;
    Datenblock: Smallint;
    Auftrag: TAuftrag;
    InventarNr: Integer;

    IstArchiviert: Boolean;

    Masch_Warmtrennen: Boolean;
    Prod_Gleich_Pack: Boolean;

    BDE: TBDE;

    Kopfgroesse: Integer;
    Packgroesse: Integer;
    PruefPack: Integer; // 1 = Prüfen und Packen; 4 = kein Prüfen, kein Packen
    Pruefstation: Integer;

    Betriebsstunden: Integer;
    IstTakt: Integer;
    Solltakt: Integer;
    LaufzeitGes: Integer;
    LaufzeitSchicht: Integer;
    Zustand: Integer;
    ZustandAlt: Integer;
    Schicht: Integer;

    AusschussSchicht: Integer;
    AusschussAuftragSchicht: Integer;

    StueckAuftragGesamt: Integer;
    StueckPruefAuftragGesamt: Integer;
    StueckPackAuftragGesamt: Integer;
    StueckAuftragAlt: Integer;

    StueckSchicht: Integer;
    StueckPruefSchicht: Integer;
    StueckPackSchicht: Integer;

    StueckAuftragSchicht: Integer;
    StueckPruefAuftragSchicht: Integer;
    StueckPackAuftragSchicht: Integer;
    StueckAuftragSchichtAlt: Integer;

    StueckAuftragSchicht_SPS: Integer;

    KARTONS: Integer;
    PALETTEN: Integer;
    Nutzung: Real;
    Qualitaet: Real;
    Leistung: Real;
    Effektivitaet: Real;

    StueckGeaendert: Boolean;

    HandAuto: Boolean; //True bei Halbautomatik

    BCD_Read: Boolean;
    BCDCode: Smallint;

    RuestzeitVorbei: Boolean;
    RuestzeitIST: Integer;
    MaschLaeuftZeit: TDateTime; //ZeitMerker für Zeit_zum_AutoStart
    MaschZustandBeiRuesten: Smallint;
    TaktLogMerker: Integer;
    ArtikelZyklus: Integer;
    MaschinenZaehler: Integer;

    Stops: Integer;
    Analagenausfall: Integer;
    Ruesten: Integer;
    Logistik: Integer;
    NichtGebucht: Integer;
    Geplant: Integer;
    Ungeplant: Integer;
    Sollaufzeit: Integer;
    IstLaufZeit: Integer;

    Einheit: string;

    AutoRuesten: Boolean;
    AutoRuestZeit: Real;
    AutoRuestStart: Real;
    MaschinenTyp: integer;
    isArbeitefrei: Boolean;
    Maschine_geblockt: Boolean; //RP BLOCKSTILL
    Heizungsdauer: Integer;
    SPC_Aktiv: Boolean;
    IstSpannzeitStk: Integer;
    IstSpannzeitGes: Integer;
    SpannzeitToleranz: Integer;
    LetzterMaschinenStart : TDateTime;
    LetzterMaschinenStop : TDateTime;
    LaufzeitInZustand : Real;
    StillstandInZustand : Real;
    LetzterAuftragsZustandWechsel : TDateTime;
    MaschineLaeuft : Boolean; // Maschinenzustand unabhängig Rüsten
    RuestZustand : Integer; // 0->kein Auftrag, 1->Rüsten 1, 2->Rüsten 2, 3->Auftrag läuft
    Ruestgrund : Integer;
    TmpLaufzeitInZustand : Real;
    TmpStillstandInZustand : Real;
    TmpLaufzeitInZustandSchicht : Real;
    TmpStillstandInZustandSchicht : Real;
    TmpLastZustandCheck : TDateTime;
    UnterauftragVorhanden : Boolean;
    LetzterZyklusZaehler : Integer;
    AktuellerZyklusZaehler : Integer;
    ZyklenAuftragGesamt : Integer;
    ZyklenAuftragSchicht : Integer;
    TaktToleranzPlus : Real;
    TaktToleranzMinus : Real;
    SpindelOvr : Integer;
    VorschubOvr : Integer;
    StueckzahlDirekt : Boolean;
    CurrentStillNr : Integer;
    GutVonBus : Boolean;
    KombiSeparat : Boolean;
//    AusschussQuote : Real;

    ZyklenNeu : Integer;
    ZyklusLast : Integer;
    ZyklenDiff : Integer;
    ZyklenAll : Integer;
    ZyklusLastZeitpunkt : TDateTime;
    MusternAktiv : Boolean;
  end;

type
  TMaschZustand = record
    MaschNr: string;
    Zustand: Integer;
  end;

type
  TStillstand = record
    Stillstandnr: Integer;
    Bezeichnung: string;
    Aktion: Integer;
    Gruppe: Integer;
    Geplant: Boolean;
  end;

  TSignal = record
    SignalNr: Integer;
    SignalArt: Integer;
  end;

  TMSignal = record
    Nr: Integer;
    MaschNr: Integer;
    SignalNr: Integer;
  end;

  TMaschine = record
    MaschNr: Integer;
    Lizenz: string;
  end;

  TShiftTypeRec = record
    ShiftType : string;
    LastTruncDate : Integer;
    LastShift : Integer;
    LastCall : TDateTime;
  end;

var
  Includis: array of TIncludis;
  SQLStr: string;
  SQLCountSTR: string;

  Vor_Schichtwechsel: Boolean;
  Nach_Schichtwechsel: Boolean;
  Vor_Werksplanung: Boolean;

  MaschZustand: array of TMaschZustand;
  Stillstand: array of TStillstand;

  First: Boolean;


  vorSchicht1, vorSchicht2, vorSchicht3, vorSchicht0: Real;
  Schicht1, Schicht2, Schicht3, Schicht0: Real;
  DSchicht1, DSchicht2, DSchicht3: Integer;
  TimeZone: Integer;

  SchichtSpeicher: Integer;
  VerpacktAusAusschussAktiv : Boolean;

  Signal: array of TSignal;
  MSignal: array of TMSignal;
  Maschine: array of TMaschine;

  SchichtTypArray : array[0..Max_ANZAHL] of TShiftTypeRec;
  DebugStage : Integer;

procedure CCC_Init;
procedure CCC_Daten_Aktualisieren;
procedure CCC_Job_Auftrag;
procedure CCC_BDE_Auftrag;
procedure CCC_Daten_Schreiben;
procedure CCC_Zeiten_Aufrunden;
procedure CCC_TPM_BCD_Meldung;
procedure CCC_Auftrag_Starten_BCDCode(Lizenz: string; Ruesten: Boolean);
procedure CCC_TPM_Stillstand_Check;
procedure CCC_CheckRuestprot_Arbeitsfrei;
procedure CCC_CheckPause;

procedure CCC_RoteLampeCheckAus(Lizenz: string);
procedure CCC_CheckStatusTPM_Stillog;
procedure CCC_TPM_Zustandswechsel(MaschNr: string; Datenblock, ZustandAlt, ZustandNeu: Integer; Schicht: string; Schuss, Prod: Integer; AfGesperrt : boolean);
procedure CCC_MDEWerte_fuellen;
procedure CCC_MDE_Soll_Ist_Vergleich;
procedure CCC_Erzeuge_Arbeitsplan(Lizenz: string; MaschNr: string; Signal: string;
  Sollwert: string; Bezeichnung: string; Zustaendig: string; Vorwarnung: Boolean; VorwarnungSTR: string; BDE_Ver:
  Boolean; RoteLampeAn: Boolean);
function CCC_GetKennung(MaschNr: string): string;
function CCC_GetMaschIndex(Lizenz: string): Integer;
function CCC_GetMaschZustand(Lizenz: string): Integer;
function CCC_GetMaschNrLizenz(Lizenz: string): string;
procedure CCC_AuftragAutomatikStart;
procedure CCC_AuftragAutomatikStartVariabel;
procedure CCC_Telegramm_Auswerten;
procedure CCC_Barcode_auswerten(BC1, BC2, BC3: string);
procedure CCC_Check_TerminOrder;
function CCC_GetWerkzeugNr(Schluessel: Integer): string;
procedure CCC_Material_ausbuchen(MaterialEAN: string; Menge: Integer; Bedienernr: string);

procedure CCC_Job_erzeugen(Q: TCO_Query; Lizenz, Bezeichnung, Quelle, Signal, Zustaendig,
  Status: string; Rote_lampe: Boolean; Zyklus: Integer);

procedure CCC_FehlerNr_auswertung;
procedure CCC_FehlerNr_Check;
procedure CCC_TPM_Signalauswertung;
procedure CCC_Schreibe_Signallog(Kommt: Boolean; First: Boolean; FehlerNr: Integer; Schicht: string; Status: string;
  Ursache: string; Wirkung: string; MaschNr: string);
procedure CCC_Auftrag_Start_Barcode(BarCodeNr: Byte);
procedure CCC_Check_Auftrag_Freigabe;
procedure CCC_Schreibe_Maschinen_Status;
procedure CCC_Check_Menge_Gebucht;
procedure CCC_Check_Terminal_Auftrag_Ende;
procedure CCC_Check_Terminal_Auftrag_Unterbrochen;
procedure CCC_Check_Terminal_Stillstand;
procedure CCC_Check_Warmtrennen;
procedure CCC_Check_Job_Stueckzahl;
procedure CCC_Check_StillstandNr_SPS;
procedure CCC_UeberwachungszeitBerechnen(MaschNr: Integer);
procedure CCC_QS_Jobs;
procedure CCC_A_Felder_Schicht_Berechnen2(aQ1, aQ2, aU: TCO_Query;  aSchichtstart: Extended; aSchicht: Integer);
procedure CCC_A_Felder_Schicht_Berechnen(aQ1, aQ2, aU: TCO_Query; aSchichtstart: Extended; aSchicht: Integer);
procedure CCC_TaktzeitIstSchreiben;

procedure CheckJobPrestart;

procedure CCC_Auto_Ruesten2;
procedure CCC_InsertStillGehtEvent(KeyNr: string);
procedure CCC_SchreibeSystemID;
function CCC_CheckLicenses: Boolean;

procedure CCC_FolgeAuftrag_Starten;
procedure CCC_SetSchichtKonstante;
procedure CCC_Verpackt_aus_Ausschuss_Berechnen;
procedure CCC_Maschinen_Wartung;

procedure CCC_CheckBlock;
procedure CCC_CheckBypass;

procedure CCC_CheckUnterbrocheneAuftraege;
function CCC_GetTPMSchichtAnfang(Schicht: Integer; DatumZeit: Real): Real;
procedure CCC_Taktzeit_Aus_Stamm_Update;

procedure CCC_JobSetupAndRestart(aCOAuftrag : TCO_Auftrag);
procedure CCC_Calc_R2_Times;
procedure CCC_AutoSetup2;



function TTT_GetMaschNr(Lizenz: string): Integer;

function TTT_GetTPMSchichtZeit(Schicht: Integer; DatumZeit: Real): Real;
function TTT_GetTPMSchichtDatum(Schicht: Integer; DatumZeit: Real): Real;
function TTT_GetArbeitszeit_Schicht(qSuch4: TCO_Query; MaschNr: Integer; Datum: Real; Schicht: Integer): Integer;
function TTT_GetSchichtTyp(qSuch4: TCO_Query; MaschNr: Integer; Datum: Real; Schicht: Integer): string;
procedure TTT_InsertStillstandEvent(qUpdate: TCO_Query; aMaschNr: string);
function TTT_GetMaschine(MaschNr: Integer): string;
function TTT_GetSignalNr(SignalArt: Integer): Integer;
function TTT_GetMonatStr(Datum: TDateTime): string;
procedure TTT_ErstelldatumEinfuegen(qUpdate, qSuch3: TCO_Query; Aufruf: Integer);
function TTT_GetRuestStillstandUeberschreitung(aqUpdate, aqSuch: TCO_Query; aMaschNr: Integer; aLizenz: string):
  Integer;
procedure VerpacktProtAusAusschussRechnen(aQSuch, aQSuch2, aQUpdate : TCO_Query; aDBUser : string); overload;
procedure VerpacktProtAusAusschussRechnen(aQSuch, aQSuch2, aQUpdate : TCO_Query; aDBUser : string; fromDate : TDateTime);overload;

function GFloat(H: string): Real;


function GetDBNr(SignalNr: Integer; MaschNr: Integer): Integer;
procedure LoadSignals(Q: TCO_Query);

function GetMonat(Datum: TDateTime): string;
function GetQuartal(Datum: TDateTime): string;
function GetJahr(Datum: TDateTime): string;
function GetAktion(Stillstandnr: Integer): Integer;
function GetSignalStillstand(Datenblock: Integer): Integer;
function GetKWStr(Datum: TDateTime): string;
function GetKW(Datum: TDateTime): string;
function Format_String(Wert: string): Integer;
procedure Pause(Sek: Integer);
function GetSelectedMaschinen(Q: TCO_Query; AndStr, Feld, Liste: string; Style: Integer): string;
procedure Statistik_Berechnen;
procedure CCC_Proc_Ruesten_AutoBuchen;
procedure GetPersonalNr_Signal;
procedure GetAusschuss_Signal;



function CheckCO_DatabaseConnect(C: TCO_Database; Q: TCO_Query; LogId: Integer; thread:string): Boolean;

function N_o_w: TDateTime;

implementation

uses
  comtas_h, U_Metall, Sprache_V63, DB, Dialogs, CO_Setup2, utils,
  Maindll, IniFiles, Th_Schicht, DateUtils;

procedure CCC_Init;
var
  Wert, SQLStr, s: string;
  machNo, I, J: Integer;
  Kav: Integer;
  ArchiveActive, ForceShotsOnCavityChange, everycycle: Boolean;
begin
//  ArchiveActive := TCO_Setup.GetParamBool(Daten.qUpdate,'SVC_OmitArchivedMachines');
  I := 1;
  SQLStr := 'select * from Maschine Order by Datenblock';
  SQL_Get(Daten.qSuch, SQLStr);
  Daten.qSuch.First;
  while not Daten.qSuch.EOF do
  begin
    if I > Anzahl_Masch then
      break;
    Includis[I].IstArchiviert := ( Daten.qSuch.FieldByName('oeerelevant').AsString <> '1')
      or  ( Daten.qSuch.FieldByName('archiviert').AsString = '1');
    Includis[I].Lizenz := Daten.qSuch.FieldByName('Lizenz').AsString;
    Includis[I].Maschine := Daten.qSuch.FieldByName('Kennung').AsString;
    Includis[I].KURZKENNUNG := Daten.qSuch.FieldByName('KURZKENNUNG').AsString;
    Includis[I].MaschNr := IntToStr(Daten.qSuch.FieldByName('Datenblock').AsInteger);
    Includis[I].MaschNrEcht := IntToStr(Daten.qSuch.FieldByName('Maschnr').AsInteger);
    Includis[I].SORT_MASCHPANEL := Daten.qSuch.FieldByName('SORT_MASCHPANEL').AsInteger;
    Includis[I].AutoRuesten := Daten.qSuch.FieldByName('Autoruesten').AsInteger = 1;

    Includis[I].MaschAktiv := Daten.qSuch.FieldByName('MaschAktiv').AsInteger <> 0;

    Includis[I].Datenblock := Daten.qSuch.FieldByName('Datenblock').AsInteger;
    Includis[I].Packgroesse := Format_String(Daten.qSuch.FieldByName('Packgroesse').AsString);

    Includis[I].Masch_Warmtrennen := Daten.qSuch.FieldByName('Warmtrennen').AsInteger <> 0;
    Includis[I].Prod_Gleich_Pack := Daten.qSuch.FieldByName('Prod_Gleich_Pack').AsInteger <> 0;

    Includis[I].ZyklusLast := Daten.qSuch.FieldByName('zyklenlast').AsInteger;
    Includis[I].ZyklusLastZeitpunkt := Daten.qSuch.FieldByName('zyklastdatumzeit').AsFloat;
    Includis[i].ZyklenAll := Daten.qSuch.FieldByName('zyklenall').AsInteger;

    Includis[I].MaschinenTyp := Daten.qSuch.FieldByName('manuelle_buchung').AsInteger;
    if Auftragstart_Barcode then
      Includis[I].InventarNr := Format_String(Daten.qSuch.FieldByName('InventarNr').AsString)
    else
      Includis[I].InventarNr := I;
    try
      Includis[I].GutVonBus := Daten.qSuch.FieldByName('gut_von_bus').AsInteger = 1;
      Includis[I].KombiSeparat := Daten.qSuch.FieldByName('kombi_separat').AsInteger = 1;
    except
    end;


    if Verpackt_Barcode then
      Includis[I].Packgroesse := 1;
    Includis[I].SpannzeitToleranz := Daten.qSuch.FieldByName('spannzeittol').AsInteger;
    Includis[I].Auftrag.Stat := -1;
    Includis[I].Auftrag.Schwesterauftrag := '';
    Includis[I].Auftrag.Form := '';

    Includis[I].Kopfgroesse := Format_String(Daten.qSuch.FieldByName('Kopfgroesse').AsString);

    if Includis[I].Kopfgroesse < 1 then
      Includis[I].Kopfgroesse := 1;
    if Includis[I].Packgroesse < 1 then
      Includis[I].Packgroesse := 1;

    Wert := Daten.qSuch.FieldByName('Station').AsString;
    Includis[I].Pruefstation := 1;
    if Wert = '' then
      Includis[I].Pruefstation := 1;
    if Wert = GetL('einfach') then
      Includis[I].Pruefstation := 1;
    if Wert = GetL('zweifach') then
      Includis[I].Pruefstation := 2;
    if Wert = GetL('dreifach') then
      Includis[I].Pruefstation := 3;
    //RP BLOCKSTILL
    try
      Includis[I].Maschine_geblockt := False;
      //RS 14.06.2016 man muss doch nicht die Query feuern, wenn keiner der Schalter sitzt
      if (BLOCKSTILLSTAND or AUFTRAG_BLOCK) then
      begin
        SQLStr := 'select tpm_stillstaende.stillstand, tpm_stillstaende.StillstandNr,'
          + ' tpm_stillstaende.geplant, tpm_stillstaende.Gruppe, tpm_stillstaende.BLOCKSTILLSTAND'
          + ' from tpm_stillstaende,'
          //+ 'tpm_stillog where tpm_stillog.maschnr = ''' + Includis[I].MaschNr
          + 'tpm_stillog where tpm_stillstaende.StillstandNr = tpm_stillog.StillstandNr AND geht=0 '
          + ' and tpm_stillog.Nr = (select max(nr) from tpm_stillog where maschnr = ''' + Includis[I].MaschNr + ''')';
        SQL_Get(Daten.qCount, SQLStr);

        Includis[I].Maschine_geblockt := (Daten.qCount.FieldByName('BLOCKSTILLSTAND').AsInteger = 1);
      end;
    except
      Includis[I].Maschine_geblockt := False;
    end;
    //********************

    Includis[I].StueckzahlDirekt := Daten.qSuch.FieldByName('stueckzahldirekt').AsInteger = 1;

    if BypassMode then
      Includis[I].Maschine_geblockt := Daten.qSuch.FieldByName('bypass').AsInteger = 1;
    Inc(I);
    Daten.qSuch.Next;
  end;

  for I := 1 to Anzahl_Masch do
  begin
    Includis[I].Auftrag.AuftragNr := '';
    Includis[I].Auftrag.Schwesterauftrag := '';
    Includis[I].Auftrag.Form := '';
    //RS 20.04.2016 - Kienle: Werkzeug, Werkzeugnr und Endedatum werden auch sicherheitshalber "abgenullt"
    Includis[I].Auftrag.Werkzeug := 0;
    Includis[I].Auftrag.WerkzeugNr := '';
    Includis[I].Auftrag.EndeDatum := 0;
  end;

  Daten.qSuch.Close;

  SQLStr := 'SELECT SUM(a_istlaufzeit) laufzeit, maschnr, BETRIEBSAUFTRAGNR '
    + ' FROM tpm_schicht WHERE betriebsauftragnr IN '
    + ' (SELECT betriebsauftragnr FROM pde WHERE stat = 0) '
    + ' GROUP BY maschnr, BETRIEBSAUFTRAGNR ';

  SQL_Get(Daten.qSuch4, SQLStr);
  while not Daten.qSuch4.Eof do
  begin
    i := Daten.qSuch4.FieldByName('maschnr').AsInteger;
    if (i > 0) and (i < Anzahl_Masch) then
    begin
      Includis[i].Auftrag.GesamtLaufzeit := Daten.qSuch4.FieldByName('laufzeit').AsInteger;
      Includis[i].Auftrag.BaNrLaufzeit := Daten.qSuch4.FieldByName('betriebsauftragnr').AsString;
    end;
    Daten.qSuch4.Next;
  end;

  SQL_Insert(Daten.qUpdate, 'UPDATE pde SET kopfgroesse=1 WHERE kopfgroesse=0');
  SQL_Insert(Daten.qUpdate, 'UPDATE maschinf SET kavitaet=1 WHERE kavitaet=0');

  //RS 15.06.2016 Hiermit können wir eventuell das Einlesen etwas beschleunigen.
  SQLStr := 'select CASE WHEN m.maschnr IS NULL THEN mo.maschnr ELSE m.maschnr END maschnr , p.* from PDE p '
  + ' LEFT JOIN maschoffline mo ON mo.lizenz = p.lizenz '
  + ' LEFT JOIN maschine m ON m.lizenz = p.lizenz '
  + ' where p.stat in (0, 1)';
  SQL_Get(Daten.qSuch, SQLStr);
  Daten.qSuch.First;


  while not Daten.qSuch.EOF do
  begin
    Wert := Daten.qSuch.FieldByName('Lizenz').AsString;
    machNo := Daten.qSuch.FieldByName('maschnr').AsInteger;
    I := Anzahl_Masch + 1;
    if (machNo < I) then
      if (UpperCase(Includis[machNo].Lizenz) = UpperCase(Wert)) then
        I := machNo;

    if I > Anzahl_Masch then
    begin
      for J := 1 to Anzahl_Masch do
        if UpperCase(Includis[J].Lizenz) = UpperCase(Wert) then
          I := J;
    end;

    if I <= Anzahl_Masch then
    begin
      Includis[I].MusternAktiv := Daten.qSuch.FieldByName('Mustern').AsInteger = 1;
      Includis[I].Auftrag.Mustern := Daten.qSuch.FieldByName('Mustern').AsInteger = 1;
      Includis[I].Auftrag.WasReset := false;
      Includis[I].Auftrag.BetriebsauftragNr := Daten.qSuch.FieldByName('BetriebsAuftragNr').AsString;
      Includis[I].Auftrag.AuftragNr := Daten.qSuch.FieldByName('AuftragNr').AsString;
      Includis[I].Auftrag.Bezeichnung := Daten.qSuch.FieldByName('Bezeichnung').AsString;
      Includis[I].Auftrag.Zustaendig := Daten.qSuch.FieldByName('Zustaendig').AsString;
      Includis[I].Auftrag.Signal := Daten.qSuch.FieldByName('Signal').AsString;
      try
 //       Includis[I].Auftrag.Sollwert := Format_String(IntToStr(
   //       StrToInt(Daten.qSuch.FieldByName('Sollwert').AsString) + AUTOAUSSCHUSS_AUFTRAG[I].Istwert));
        Includis[I].Auftrag.Sollwert := Format_String(IntToStr(StrToInt(Daten.qSuch.FieldByName('Sollwert').AsString)));
      except
        Includis[I].Auftrag.Sollwert := Format_String(Daten.qSuch.FieldByName('Sollwert').AsString);
      end;
      try
        Includis[I].Auftrag.SollwertOffset := Format_String(IntToStr(StrToInt(Daten.qSuch.FieldByName('SollwertOffset').AsString)));
      except
        Includis[I].Auftrag.SollwertOffset := Format_String(Daten.qSuch.FieldByName('SollwertOffset').AsString);
      end;

      Includis[I].Auftrag.planzykluszeit := Daten.qSuch.FieldByName('planzykluszeit').AsInteger;
      Includis[I].Auftrag.ausschussquote := Daten.qSuch.FieldByName('ausschussquote').AsInteger;

      Includis[I].Auftrag.SollSpannzeitStk := Daten.qSuch.FieldByName('SOLLSPANNZEITSTK').AsInteger;
      Includis[I].Auftrag.SollSpannzeitGes := Daten.qSuch.FieldByName('SOLLSPANNZEITGES').AsInteger;

      try
        Includis[I].Solltakt := Daten.qSuch.FieldByName('Taktzeit').AsInteger;
      except
      end;

      Includis[I].Auftrag.StueckSchicht := Daten.qSuch.FieldByName('StueckSchicht').AsInteger;
      Includis[I].Auftrag.PersonalZeit := GFloat(Daten.qSuch.FieldByName('Personalzeit').AsString);
      Includis[I].Auftrag.Optimiert := Daten.qSuch.FieldByName('optimiert').AsInteger;
      Includis[I].Auftrag.OptimiertAktuell := Daten.qSuch.FieldByName('tmpschuss').AsInteger;
      Includis[I].Auftrag.ImStatusOptimieren := Daten.qSuch.FieldByName('InPause').AsInteger;

      if S7Main.HochlaufTPM then
        Includis[I].StueckAuftragGesamt := Format_String(Daten.qSuch.FieldByName('Istwert').AsString);

      Includis[I].Auftrag.Schwesterauftrag := Daten.qSuch.FieldByName('Schwesterauftrag').AsString;
      Includis[I].Auftrag.Form := Daten.qSuch.FieldByName('Form').AsString;

      Includis[I].Auftrag.Ausschuss := Daten.qSuch.FieldByName('Ausschuss').AsInteger;
      Includis[I].Auftrag.Verpackt := Format_String(Daten.qSuch.FieldByName('Pack').AsString);

      Includis[I].Auftrag.Vorwarnung := Format_String(Daten.qSuch.FieldByName('Vorwarnung').AsString);
      if (Daten.qSuch.FieldByName('Betriebsart').AsString = GetL('Halbautomatik')) and halbautomatik then
        Includis[I].Auftrag.HalbAuto := True
      else
        Includis[I].Auftrag.HalbAuto := False;
      if Daten.qSuch.FieldByName('Erzeugt').AsString = '1' then
      begin
        Includis[I].Auftrag.Erzeugt := True;
        Includis[I].Auftrag.VorwarnungErzeugt := True;
      end
      else
      begin
        Includis[I].Auftrag.Erzeugt := False;
        Includis[I].Auftrag.VorwarnungErzeugt := False;
      end;
      Includis[I].Auftrag.Solltakt := Daten.qSuch.FieldByName('Taktzeit').AsInteger;
      Includis[I].Auftrag.Stat := Daten.qSuch.FieldByName('stat').AsInteger;
      Includis[I].Auftrag.Programm_Nr := Daten.qSuch.FieldByName('Programm_Nr').AsInteger;
      Includis[I].Auftrag.StartDatum := GFloat(Daten.qSuch.FieldByName('StartdatumZeit').AsString);
      Includis[I].Auftrag.EndeDatum := GFloat(Daten.qSuch.FieldByName('EnddatumZeit').AsString);
      Includis[I].Auftrag.EndeDatumSTR := Daten.qSuch.FieldByName('EndDatumSTR').AsString;
      Includis[I].Auftrag.LTSOLL := GFloat(Daten.qSuch.FieldByName('LTDatumZeit').AsString);
      Includis[I].Auftrag.LTIST := GFloat(Daten.qSuch.FieldByName('EnddatumZeit').AsString);
      Includis[I].Auftrag.LT1 := GFloat(Daten.qSuch.FieldByName('Termin1').AsString);
      Includis[I].Auftrag.LT2 := GFloat(Daten.qSuch.FieldByName('Termin2').AsString);

      Includis[I].Auftrag.Kunde := Daten.qSuch.FieldByName('Kunde').AsString;

      Includis[I].Auftrag.Werkzeug := Daten.qSuch.FieldByName('Werkzeug').AsInteger;

      try
        Includis[I].Auftrag.Packgroesse := Format_String(Daten.qSuch.FieldByName('PACKGROESSE').AsString);
        Includis[I].Auftrag.PALETTENGROESSE := Format_String(Daten.qSuch.FieldByName('EndDatumSTR').AsString);
      except
        Includis[I].Auftrag.Packgroesse := 0;
        Includis[I].Auftrag.PALETTENGROESSE := 0;
      end;

      if Daten.qSuch.FieldByName('Masterauftrag').AsInteger = 1 then
        Includis[I].Auftrag.MasterAuftrag := True
      else
        Includis[I].Auftrag.MasterAuftrag := False;

      if werkzeugverwaltung then
        Includis[I].Auftrag.WerkzeugNr := CCC_GetWerkzeugNr(Includis[I].Auftrag.Werkzeug);

      if Includis[I].Auftrag.Form = '' then
        Includis[I].Auftrag.Form := IntToStr(Includis[I].Auftrag.Werkzeug);

      try
        if Daten.qSuch.FieldByName('Grundeinstellung').IsNull or ( Daten.qSuch.FieldByName('Grundeinstellung').AsString = '' ) then
          Includis[I].PruefPack := 0
        else
          Includis[I].PruefPack := Daten.qSuch.FieldByName('Grundeinstellung').AsInteger;
      except
        Includis[I].PruefPack := 0;
      end;

      try
        if KavitaetFromSPS then
        begin
          Kav := SPSKavitaet[i].Istwert;
          //14.04.2015 RS: Auch aus der SPS wird nur eine Kavitaet > 0 übernommen;
          if Kav < 1 then
            Kav := 1;
          if Kav <> Daten.qSuch.FieldByName('Kopfgroesse').AsInteger then
            SQL_Insert(Daten.qUpdate, 'UPDATE pde SET kopfgroesse = ' + IntToStr(Kav) + ' WHERE nr = ' +
              Daten.qSuch.FieldByName('nr').AsString);
        end
        else
        begin
          //RS 16.06.2015: Neue Logik für setup.kavitaet_laufender_Auftrag = 3;
          S := 'SELECT * FROM kavprot WHERE betriebsauftragnr = ''' + Includis[I].Auftrag.BetriebsauftragNr + ''' ORDER BY datum DESC';
          SQL_Get(Daten.qSuch2, S);
          if Daten.qSuch2.IsEmpty OR not Kavitaet_laufender_Auftrag3 then
          begin
            Kav := Daten.qSuch.FieldByName('Kopfgroesse').AsInteger;
            Includis[I].Auftrag.LetzerKavWechsel.Datum := -1;
          end
          else
          begin
            Includis[I].Auftrag.LetzerKavWechsel.Datum := Daten.qSuch2.FieldByName('datum').AsFloat;
            Includis[I].Auftrag.LetzerKavWechsel.BetriebsauftragNr := Includis[I].Auftrag.BetriebsauftragNr;
            Includis[I].Auftrag.LetzerKavWechsel.Alt := Daten.qSuch2.FieldByName('Wert1').AsInteger;
            Includis[I].Auftrag.LetzerKavWechsel.Neu := Daten.qSuch2.FieldByName('Wert2').AsInteger;
            Includis[I].Auftrag.LetzerKavWechsel.Produziert := Daten.qSuch2.FieldByName('Produziert').AsInteger;
            Includis[I].Auftrag.LetzerKavWechsel.Schusszaehler := Daten.qSuch2.FieldByName('Schusszaehler').AsInteger;
            //Sicherheitshalber prüfen wir auf Plausibilität. Wennn Schusszaehler 0 ist aber Produziert nicht, dann liegt ein alter Eintrag vor!
            if ( Includis[I].Auftrag.LetzerKavWechsel.Produziert > 0 ) AND (Includis[I].Auftrag.LetzerKavWechsel.Schusszaehler < 1) then
              Includis[I].Auftrag.LetzerKavWechsel.Datum := -1;
            Kav := Includis[I].Auftrag.LetzerKavWechsel.Neu;
          end;
        end;

      except
        try
          Includis[I].Auftrag.LetzerKavWechsel.Datum := -1;
          Kav := Daten.qSuch.FieldByName('Kavitaet_Soll').AsInteger;
          SQL_Insert(Daten.qUpdate, 'UPDATE pde SET kopfgroesse = kavitaet_soll WHERE nr = ' +
            Daten.qSuch.FieldByName('nr').AsString);
        except
          Kav := 1;
          SQL_Insert(Daten.qUpdate, 'UPDATE pde SET kopfgroesse = 1, kavitaet_soll = 1 WHERE nr = ' +
            Daten.qSuch.FieldByName('nr').AsString);
        end;
      end;

      //RS 16.06.2015: OptimitierAktuell wird nicht bei Kavitäts-Wechsel detailliert berechnet
      Includis[I].Auftrag.OptimiertAktuell := Includis[I].Auftrag.OptimiertAktuell * Kav;

      if Kavitaet_laufender_Auftrag2 and (Kav > 0) and (Includis[I].Auftrag.Kopfgroesse > 0)
        and (Includis[I].Auftrag.Kopfgroesse <> Kav)
        and (Includis[I].Auftrag.BetriebsauftragNr = Includis[I].Auftrag.BetriebsauftragNr_Alt) then
      begin
        (*RS 07.02.2014 - Petainer - Hier gab es mit dem Running Change Probleme, weil die Kavität zu schnell geändert wird.
          Dementsprechend wird in den ersten x Minuten keine Stückzahl durch den Dienst in den Koppler geschrieben!*)
        ForceShotsOnCavityChange := True;
        if TCO_Setup.GetParamBool(Daten.qUpdate,'INCL_RunningChangeOnPrintRequest') then
        begin

          SQL_Get(Daten.qCount, 'SELECT max(started) started FROM runningchangeevents rc WHERE BANEW = '''
            + Includis[I].Auftrag.BetriebsauftragNr + '''');
          if not Daten.qCount.IsEmpty then
          begin
            if ((Daten.qCount.FieldByName('started').AsFloat
                + (TCO_Setup.GetParamInt(Daten.qUpdate, 'INCL_SVCDontWriteCavityForXminutes') / 1440))
                > Now ) then
             ForceShotsOnCavityChange := False;
          end;

        end;
        if ForceShotsOnCavityChange and TCO_Setup.GetParamBool(Daten.qUpdate, 'SVC_BuchungBeiKavWechsel') then
          S7Main.S7_Auftrag.AuftragBuchen(Includis[I].Auftrag.BetriebsauftragNr, Includis[I].StueckAuftragGesamt);

        SQLStr := 'Update Maschine Set Kopfgroesse = ' + IntToStr(Kav) + ' where MaschNr = ' + Includis[I].MaschNr;
        SQL_Insert(Daten.qUpdate, SQLStr);
      end;

      Includis[I].Auftrag.BetriebsauftragNr_Alt := Includis[I].Auftrag.BetriebsauftragNr;
      Includis[I].Auftrag.Kopfgroesse := Kav;
      Includis[I].Auftrag.KAVITAET_SOLL := Daten.qSuch.FieldByName('KAVITAET_SOLL').AsInteger;
      Includis[I].Auftrag.InPause := Daten.qSuch.FieldByName('InPause').AsInteger;

      Includis[I].Auftrag.Var_Kavitaet := Daten.qSuch.FieldByName('Var_Kavitaet').AsInteger;
      if Includis[I].Auftrag.Var_Kavitaet < 1 then
        Includis[I].Auftrag.Var_Kavitaet := 1;
      if Includis[I].Auftrag.Var_Kavitaet > 999 then
        Includis[I].Auftrag.Var_Kavitaet := 1;
    end;
    Daten.qSuch.Next;
  end;

  for I := 1 to Anzahl_Masch do
  begin
    if ( Includis[I].Auftrag.AuftragNr = '' ) and not ( Includis[I].Auftrag.WasReset) then
    begin
      Includis[I].MusternAktiv := false;
      Includis[I].Auftrag.Mustern := false;
      Includis[I].Auftrag.Bezeichnung := GetL('kein aktueller Auftrag');
      Includis[I].Auftrag.BetriebsauftragNr := '';
      Includis[I].Auftrag.Zustaendig := '';
      Includis[I].Auftrag.Signal := '';
      Includis[I].Auftrag.Sollwert := 0;
      Includis[I].Auftrag.SollwertOffset := 0;
      Includis[I].Auftrag.Vorwarnung := 0;
      Includis[I].Auftrag.Erzeugt := False;
      Includis[I].Auftrag.Solltakt := 0;
      Includis[I].Auftrag.Stat := stgeplantInt;
      Includis[I].Auftrag.Werkzeug := 0;
      Includis[I].PruefPack := 1;
      if KavitaetFromSPS then
        Includis[I].Auftrag.Kopfgroesse := SPSKavitaet[i].Istwert
      else
        Includis[I].Auftrag.Kopfgroesse := Includis[I].Kopfgroesse;
      if Includis[I].Auftrag.Kopfgroesse = 0 then
        Includis[I].Auftrag.Kopfgroesse := 1;
      Includis[I].Auftrag.KAVITAET_SOLL := 1;

      Includis[I].Auftrag.InPause := 0;

      Includis[I].Auftrag.Var_Kavitaet := 1;
      Includis[I].IstTakt := 0;
      Includis[I].Solltakt := 0;

      Includis[I].StueckSchicht := 0;
      Includis[I].StueckPackSchicht := 0;
      Includis[I].StueckPruefSchicht := 0;
      Includis[I].Nutzung := 0;
      Includis[I].Leistung := 0;
      Includis[I].Qualitaet := 0;
      Includis[I].Effektivitaet := 0;
      Includis[I].Auftrag.Ist_PRZ := 0;
      Includis[I].Auftrag.Programm_Nr := 0;
      Includis[I].Auftrag.Istwert := 0;
      Includis[I].Auftrag.Ausschuss := 0;
      Includis[I].Auftrag.Verpackt := 0;
      Includis[I].StueckPruefAuftragGesamt := 0;
      Includis[I].StueckPackAuftragGesamt := 0;
      Includis[I].Auftrag.Schwesterauftrag := '';
      Includis[I].Auftrag.Form := '';
      Includis[I].Auftrag.PersonalZeit := 0;
      Includis[I].Auftrag.Anfahrausschuss := 0;
      Includis[I].Auftrag.Kunde := '';
      AUTOAUSSCHUSS_AUFTRAGSchicht[I].Istwert := 0;
      AUTOAUSSCHUSS_AUFTRAG[I].Istwert := 0;
      Includis[I].Auftrag.WasReset := True;
    end
  end;

  if TCO_Setup.GetParamBool(Daten.qSuch, 'INCL_MJAInterruptedDescr') then
  begin
    SQLStr := 'SELECT m.maschid, case WHEN p.c IS NULL THEN 0 ELSE 1 END interrupted'
            + ' FROM'
            + ' maschine m'
            + ' LEFT JOIN'
            + ' ('
            + '   SELECT lizenz, COUNT(nr) c'
            + '   FROM pde'
            + '   WHERE stat = 5'
            + '   GROUP BY lizenz'
            + ' )p ON p.lizenz = m.lizenz'
            + ' ORDER BY maschid';
    Daten.qSuch.Close;
    SQL_Get(Daten.qSuch, SQLStr);
    Daten.qSuch.First;
    while not Daten.qSuch.Eof do
    begin
      I := Daten.qSuch.FieldByName('maschid').AsInteger;
      if (Daten.qSuch.FieldByName('interrupted').AsInteger > 0) and (Includis[I].Auftrag.AuftragNr = '') then
        Includis[I].Auftrag.InterBezeichnung := Getl('Auftrag unterbrochen')
      else
        Includis[I].Auftrag.InterBezeichnung := Includis[I].Auftrag.Bezeichnung;
      Daten.qSuch.Next;
    end;


  end
  else
  begin
    FOR I := 1 to Anzahl_Masch do
      if not Includis[I].IstArchiviert then
        Includis[I].Auftrag.InterBezeichnung := Includis[I].Auftrag.Bezeichnung;
  end;
  //***********************************************************************
  //    BDE-DATEN EINSTELLEN
  //***********************************************************************
  Daten.qSuch.Close;
  SQLGet(Daten.qSuch, 'MDE', 'Erzeugt', '0', False);
  Daten.qSuch.First;

  while not Daten.qSuch.EOF do
  begin
    Wert := Daten.qSuch.FieldByName('Lizenz').AsString;
    //Eintrag der Lizenz in Includis-Daten suchen
    //RS 14.06.2016: Ist das hier nicht buggy? wenn für zwei Maschinen ein Eintrag in MDE existiert, dann bekommt unter Umständen nur eine die Daten. denn wenn die "erste" in MDE im Includis[]-Array VOR der "zweiten" steht, dann wird BDE.Bezeichnung der ersten doch zu ''
    for I := 1 to Anzahl_Masch do
    begin
      Includis[I].BDE.Bezeichnung := '';
      if Includis[I].Lizenz = Wert then
        break;
    end;

    if I <= Anzahl_Masch then
    begin
      Includis[I].BDE.Bezeichnung := Daten.qSuch.FieldByName('JobBezeichnung').AsString;
      Includis[I].BDE.Zustaendig := Daten.qSuch.FieldByName('Zustaendig').AsString;
      Includis[I].BDE.Signal := Daten.qSuch.FieldByName('Signal').AsString;
      Includis[I].BDE.Sollwert := Daten.qSuch.FieldByName('Sollwert_ABS').AsInteger;
      Includis[I].BDE.Vorwarnung := Daten.qSuch.FieldByName('Vorwarnung_ABS').AsInteger;
      if Daten.qSuch.FieldByName('Erzeugt').AsString = '1' then
        Includis[I].BDE.Erzeugt := True
      else
        Includis[I].BDE.Erzeugt := False;

      Includis[I].BDE.VorwarnungErzeugt := False;
    end;
    Daten.qSuch.Next;
  end;

  for I := 1 to Anzahl_Masch do
  begin
    if Includis[I].BDE.Bezeichnung = '' then
    begin
      Includis[I].BDE.Bezeichnung := '';
      Includis[I].BDE.Zustaendig := '';
      Includis[I].BDE.Signal := '';
      Includis[I].BDE.Sollwert := 0;
      Includis[I].BDE.Vorwarnung := 0;
      Includis[I].BDE.Erzeugt := False;
    end;
  end;

  everycycle := False;
  SQLStr := 'SELECT saveeverycycle FROM setup WHERE nr = 1';
  try
    SQL_Get(Daten.qSuch, SQLStr);
    if not Daten.qSuch.IsEmpty then
      everycycle := Daten.qSuch.FieldByName('saveeverycycle').AsInteger = 1;
  except
  end;

  (* RS 14.06.2016: das kommt doch noch einmal in Zeile 904ff
  for I := 1 to Anzahl_Masch do
  begin
    if everycycle then
      Includis[I].ArtikelZyklus := 1
    else
      Includis[I].ArtikelZyklus := 100;
  end;
  *)

  Daten.qSuch4.SQL.Text := 'SELECT * FROM Taktoption';
  Daten.qSuch4.Open;
  while not Daten.qSuch4.Eof do
  begin
    try
      i := StrToInt(CCC_GetMaschNrLizenz(Daten.qSuch4.FieldByName('lizenz').AsString));
    except
      i := 0;
    end;
    if i > 0 then
      Includis[I].ArtikelZyklus := Daten.qSuch4.FieldByName('Artikelzyklus').AsInteger;
    Daten.qSuch4.Next;
  end;


  for I := 1 to Anzahl_Masch do
  begin
    if Includis[I].IstArchiviert then
      Continue;
    if everycycle then
      Includis[I].ArtikelZyklus := 1
    else
    begin
      if SQLGetBool(Daten.qSuch4, 'TAKTOPTION', 'Lizenz', Includis[I].Lizenz) then
        Includis[I].ArtikelZyklus := Daten.qSuch4.FieldByName('Artikelzyklus').AsInteger
      else
        Includis[I].ArtikelZyklus := 100;
    end;
  end;

  // end;

  // *********************************
  // *     Stillstände einstellen    *
  // *********************************

  SQLStr := 'Select Count(*) CNT from TPM_Stillstaende';
  SQL_Get(Daten.qSuch, SQLStr);
  SetLength(Stillstand, Daten.qSuch.FieldByName('CNT').AsInteger + 1);

  SQLStr := 'Select * from TPM_Stillstaende';
  SQL_Get(Daten.qSuch, SQLStr);
  I := 1;
  while not Daten.qSuch.EOF do
  begin
    Stillstand[I].Stillstandnr := Daten.qSuch.FieldByName('Stillstandnr').AsInteger;
    Stillstand[I].Bezeichnung := Daten.qSuch.FieldByName('Stillstand').AsString;
    Stillstand[I].Aktion := Daten.qSuch.FieldByName('Aktion').AsInteger;
    Stillstand[I].Gruppe := Daten.qSuch.FieldByName('Gruppe').AsInteger;
    if Daten.qSuch.FieldByName('Geplant').AsInteger = 1 then
      Stillstand[I].Geplant := True
    else
      Stillstand[I].Geplant := False;
    Inc(I);
    Daten.qSuch.Next;
  end;

  if S7Main.HochlaufTPM then
    for I := 1 to Anzahl_Masch do
    begin
      MaschZustand[I].MaschNr := Includis[I].MaschNr;
      MaschZustand[I].Zustand := -1;
      S7Main.HochlaufTPM := False;
    end;

  First := False;
end;

function GFloat(H: string): Real;
var
  S: string;
begin
  S := Trim(H);
  if S = '' then
    Result := 0
  else
  begin
    try
      if Pos(',', S) > 0 then
      begin
        if DecimalSeparator = ',' then
        begin
          Result := StrToFloat(S);
          exit;
        end
        else
        begin
          while Pos(',', S) > 0 do
            S[Pos(',', S)] := '.';
          Result := StrToFloat(S);
          exit;
        end;
      end;
      if DecimalSeparator = '.' then
        Result := StrToFloat(S)
      else
      begin
        while Pos('.', S) > 0 do
          S[Pos('.', S)] := DecimalSeparator;
        Result := StrToFloat(S);
      end;
    except
      try
        if DecimalSeparator = ',' then
          Result := StrToFloat(S)
        else
        begin
          while Pos(',', S) > 0 do
            S[Pos(',', S)] := DecimalSeparator;
          Result := StrToFloat(S);
        end;
      except
        Result := 0;
        SchreibeMeldung('Error GFloat (StrToFloat) : ' + S, 0);
      end;
    end;
  end;
end;

procedure CCC_Daten_Aktualisieren;
var
  IMaschProgramm: Integer;
  SProd, SAutoAusschuss, SAnfahr, AProd, AAnfahr, SZyk, AZyk, SPruef, APruef: Integer;
  Zustand_Wert, Schichtwert, SchichtSpeicherIni: Integer;
  Zeitreal, LastChange: Real;
  isfeiertag : boolean;

  Meldung: string;
  Ausschuss, tmptakt: Integer;
  Schichtanfang: TDateTime;
  tbMinuten, NA: Integer;
  Divisor: Integer;
  Tagwechsel: Boolean;
  Tag: Integer;

  MinutenAnfang, MinutenJetzt: Real;

  diff, I: Integer;

  SQLStr, s: string;
  Minuten: Integer;
  TmpDate, Werksplanungszeit: TDateTime;
  Ini: TIniFile;

  keinProduziertBeiRuesten : Boolean;
  Anfahr_Ausschuss2: Boolean;


begin
  Vor_Schichtwechsel := False;
  Vor_Werksplanung := False;
  Zustand_Wert := 0;
  Schichtwert := 1;
  keinProduziertBeiRuesten := TCO_Setup.GetParamBool(Daten.qSuch,'INCL_ProducedInShiftWithoutSetup');

  SQLGet(Daten.qSuch4, 'Setup', 'Nr', '1', False);
  Anfahr_Ausschuss2 := Daten.qSuch4.FieldByName('Anfahr_Ausschuss2').AsInteger = 1;

  if Shift_Model <> 2 then
  begin

    //Kurz vor Schichtwechsel alle Maschinen auf grün
    Zeitreal := Frac(Jetzt);
    if ((Zeitreal >= vorSchicht1) and (Zeitreal < Schicht1)) then
      Vor_Schichtwechsel := True;
    if ((Zeitreal >= vorSchicht2) and (Zeitreal < Schicht2)) then
      Vor_Schichtwechsel := True;
    if ((Zeitreal >= vorSchicht3) and (Zeitreal < Schicht3)) then
      Vor_Schichtwechsel := True;

    TmpDate := Trunc(Jetzt);
    //Schicht einstellen
    if ((Zeitreal >= Schicht1) and (Zeitreal < Schicht2)) then
      Schichtwert := 1;
    if ((Zeitreal >= Schicht2) and (Zeitreal < Schicht3)) then
      Schichtwert := 2;
    if ((Zeitreal >= Schicht3) and (Zeitreal <= 1)) then
      Schichtwert := 3;
    if ((Zeitreal >= 0.0) and (Zeitreal < Schicht1)) then
    begin
      Schichtwert := 3;
      TmpDate := TmpDate - 1;
    end;
    if Schichtwert = 0 then
      Schichtwert := 3;

  end
  else
  begin
    //Kurz vor Schichtwechsel alle Maschinen auf grün
    Zeitreal := Frac(Jetzt);
    if (Zeitreal >= vorSchicht1) and (Zeitreal < Schicht1) then
      Vor_Schichtwechsel := True;
    if (Zeitreal >= vorSchicht2) and (Zeitreal < Schicht2) then
      Vor_Schichtwechsel := True;

    TmpDate := Trunc(Jetzt);
    //Schicht einstellen
    if (Zeitreal >= Schicht1) and (Zeitreal < Schicht2) then
      Schichtwert := 1;
    if (Zeitreal >= Schicht2) and (Zeitreal < 1) then
      Schichtwert := 2;
    if (Zeitreal >= 0.0) and (Zeitreal < Schicht1) then
    begin
      Schichtwert := 2;
      TmpDate := TmpDate - 1;
    end;
    if Schichtwert = 0 then
      Schichtwert := 2;
  end;

  
  SQLStr := 'SELECT * FROM kalenderfeiertage WHERE trunc(startdate) <= ' + IntToStr(Trunc(TmpDate)) + ' AND trunc(enddate+1) >= ' + IntToStr(Trunc(TmpDate)) + ' AND active=1';
  SQL_Get(Daten.qSuch, SQLStr);
  
  isfeiertag := (Daten.qSuch.FieldByName('startdateshift').AsInteger <= Schichtwert) and (Schichtwert <= Daten.qSuch.FieldByName('enddateshift').AsInteger);
  
  SQLStr := 'Select * from KALENDER where DatumINT = ''' + IntToStr(Trunc(TmpDate)) + '''';
  SQL_Get(Daten.qSuch, SQLStr);
  Minuten := Daten.qSuch.FieldByName('Schicht' + IntToStr(Schichtwert)).AsInteger;
  SchichtDauer := GetSchichtDauer(Schichtwert);
  Werksplanungszeit := 0;
  if (Minuten < SchichtDauer) and (Minuten > 0) then
  begin
    if Schichtwert = 1 then
      Werksplanungszeit := Schicht2 - (Minuten / 1440);
    if Schichtwert = 2 then
      Werksplanungszeit := Schicht3 - (Minuten / 1440);
    if Schichtwert = 3 then
      if Minuten < 360 then
        Werksplanungszeit := Schicht1 - (Minuten / 1440)
      else
        Werksplanungszeit := 1 - ((Minuten - 360) / 1440);
    if (Frac(Jetzt) > Werksplanungszeit - Trunc(Werksplanungszeit))
      and (Frac(Jetzt) < (Werksplanungszeit - Trunc(Werksplanungszeit) + (1 / 2880))) then
      Vor_Werksplanung := True;
  end;

  if isfeiertag then
    Werksplanungszeit :=0;
  

  SchichtSpeicherIni := SchichtSpeicher;

  try
    if not Thread_Schicht.Berechnung_aktiv then
    begin
      Ini := TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'incl_' + DBUser + '.ini');
      LastChange := Ini.ReadFloat('System', 'last_shift_change', -1);
      if LastChange > -1 then
      begin
        SchichtSpeicherIni := GetSchichtNr(LastChange);
        if N_o_w - LastChange > 1 then
        begin
          if SchichtSpeicherIni = 1 then
          begin
            if Shift_Model = 2 then
              SchichtSpeicherIni := 2
            else
              SchichtSpeicherIni := 3;
          end
          else
            SchichtSpeicherIni := SchichtSpeicherIni - 1;
        end;
        SchichtSpeicher := SchichtSpeicherIni;
      end;
      Ini.Free;
    end;
  except
  end;

  if not (SchichtSpeicher = -1) and (SchichtSpeicher <> Schichtwert) then
  begin
    //Schichtwechsel auslösen
    Daten.qUpdate.Close;
    Daten.qUpdate.SQL.Clear;
    SQLStr := 'INSERT INTO SIWECHSEL (Nr,Schichtwechsel,alteSchicht,neueSchicht)'
      + 'VALUES(SIWECHSELID.NextVal'
      + ',''1'
      + ''',''' + IntToStr(SchichtSpeicher)
      + ''',''' + IntToStr(Schichtwert)
      + ''')';
    SQL_Insert(Daten.qUpdate, SQLStr);
  end;

  SchichtSpeicher := Schichtwert;

  SQLStr := 'SELECT * FROM maschine';
  Daten.qSuch.SQL.Text := SQLStr;
  Daten.qSuch.Open;
  while not Daten.qSuch.EOF do
  begin
   I := Daten.qSuch.FieldByName('maschid').AsInteger;
    Heizungsoll[I] := Daten.qSuch.FieldByName('heatingstd').AsInteger;
    try
      Includis[I].SPC_Aktiv := Daten.qSuch.FieldByName('spcaktiv').AsInteger = 1;
    except
      Includis[I].SPC_Aktiv := SPC;
    end;

    Daten.qSuch.Next;
  end;
  Daten.qSuch.Close;


  SQLStr := 'SELECT mde_ver.nr vernr, maschnr, toleranzint FROM mde_ver '
    + ' LEFT JOIN maschine ON mde_ver.lizenz = maschine.lizenz';
  SQL_Get(Daten.qSuch, SQLStr);
  while not Daten.qSuch.EOF do
  begin
    s := Daten.qSuch.FieldByName('maschnr').AsString;
//    i := Daten.qSuch.FieldByName('maschnr').AsInteger;
    if s = '' then
    begin
      SQL_Insert(Daten.qupdate, 'DELETE FROM mde_ver WHERE nr = ' + Daten.qSuch.FieldByName('vernr').AsString);
    end
    else
    begin
      i := StrToInt(s);
      if (i <= Anzahl_Masch) then
      begin
        Includis[i].TaktToleranzPlus := Daten.qSuch.FieldByName('ToleranzINT').AsInteger;
        Includis[i].TaktToleranzMinus := Daten.qSuch.FieldByName('ToleranzINT').AsInteger;
      end;
    end;
    Daten.qSuch.Next;
  end;

  for I := 1 to Anzahl_Masch do
  begin
    If (Includis[I].IstArchiviert) and (i > 1) then
      Continue;


    Includis[i].ZyklenNeu := StueckAuftragGesamt[I].Istwert;

    if Taktzeit[I].Istwert > 0 then  // Wenn Taktzeit 0 ist steht oder stand Maschine !
    begin
      // Initial
      if (Includis[i].ZyklenAll > 0) or (Includis[i].ZyklusLast > 0) then
      begin
        if (Includis[i].ZyklenNeu > Includis[i].ZyklusLast) then
        begin
        // Prüfen ob Zeit hinkommt. Keine negativen. Keine großen Sprünge erlauben.
          tmptakt := Taktzeit[I].Istwert;
          if tmptakt =0 then
            tmptakt := 1000; // Eine Sekunde mindesttakt
          if (((Includis[i].ZyklenNeu - Includis[i].ZyklusLast) * tmptakt) / 1000) <  ((Now - Includis[i].ZyklusLastZeitpunkt) * 1440 * 60) then
            Includis[i].ZyklenDiff := Includis[i].ZyklenNeu - Includis[i].ZyklusLast;
        end
        else
        begin
          Includis[i].ZyklenDiff := 0;
        end;
        Includis[i].ZyklusLast := INCLUDIS[i].ZyklenNeu;
      end
      else
      begin
        Includis[i].ZyklenDiff := 0;
      end;
    end;


    if Includis[I].Auftrag.Var_Kavitaet < 1 then
      Includis[I].Auftrag.Var_Kavitaet := 1;

    Includis[I].Betriebsstunden := Betriebsstunden[I].Istwert;
    if Includis[I].Betriebsstunden < 0 then
    begin
      SchreibeMeldung('Error: Operating hours / machine < 0: '
        + Includis[I].Maschine + ' at ' + DateTimeToStr(Jetzt), 0);
    end;

    Includis[I].LaufzeitGes := LaufzeitGes[I].Istwert;
    if Includis[I].LaufzeitGes < 0 then
    begin
      SchreibeMeldung('Error: Runtime Total / machine < 0: '
        + Includis[I].Maschine + ' at ' + DateTimeToStr(Jetzt), 0);
    end;

    Includis[I].LaufzeitSchicht := LaufzeitSchicht[I].Istwert;
    if Includis[I].LaufzeitSchicht < 0 then
    begin
      SchreibeMeldung('Error: Runtime shift / machine < 0: '
        + Includis[I].Maschine + ' at ' + DateTimeToStr(Jetzt), 0);
    end;

    if Includis[I].Maschine_geblockt then //RP BLOCKSTILL
      Includis[I].IstTakt := 0
    else
      Includis[I].IstTakt := Taktzeit[I].Istwert; //RP BLOCKSTILL

    Includis[I].ZustandAlt := Includis[I].Zustand;

    // Reale Laufzeit ermitteln
    if MaschProgrammbetrieb[I].Istwert then // Maschine läuft lt. Bus
    begin
      Includis[i].TmpLaufzeitInZustand := Includis[i].TmpLaufzeitInZustand
        + ((Jetzt - Includis[i].TmpLastZustandCheck) * 1440);
      Includis[i].TmpLaufzeitInZustandSchicht := Includis[i].TmpLaufzeitInZustandSchicht
        + ((Jetzt - Includis[i].TmpLastZustandCheck) * 1440);
      if not Includis[i].MaschineLaeuft then  // Maschine stand vorher
      begin
        Includis[i].StillstandInZustand := (Jetzt - Includis[i].LetzterMaschinenStop) * 1440;
        Includis[i].LetzterMaschinenStart := Jetzt;
        Includis[i].MaschineLaeuft := true;
      end
      else
      begin
        Includis[i].LaufzeitInZustand := (Jetzt - Includis[i].LetzterMaschinenStart) * 1440;
      end;
    end
    else  // Maschine steht lt. Bus.
    begin
      Includis[i].TmpStillstandInZustand := Includis[i].TmpStillstandInZustand
        + ((Jetzt - Includis[i].TmpLastZustandCheck) * 1440);
      Includis[i].TmpStillstandInZustandSchicht :=Includis[i].TmpStillstandInZustandSchicht
        + ((Jetzt - Includis[i].TmpLastZustandCheck) * 1440);
      if Includis[i].MaschineLaeuft then  // Maschine lief vorher
      begin
        Includis[i].LaufzeitInZustand := (Jetzt - Includis[i].LetzterMaschinenStart) * 1440;
        Includis[i].LetzterMaschinenStop := Jetzt;
        Includis[i].MaschineLaeuft := false;
      end
      else
      begin
        Includis[i].StillstandInZustand := (Jetzt - Includis[i].LetzterMaschinenStop) * 1440;
      end;
    end;
    Includis[i].TmpLastZustandCheck := Jetzt;

    if not Includis[I].Maschine_geblockt then
    begin //RP BLOCKSTILL
      if MaschProgrammbetrieb[I].Istwert and (GetSignalStillstand(I) = -1) then
        IMaschProgramm := 1
      else
        IMaschProgramm := 0;

      if IMaschProgramm = 0 then
        Zustand_Wert := 2;
      if IMaschProgramm = 1 then
        Zustand_Wert := 0;

      if Includis[I].Auftrag.Stat = stStartRuestenInt then
      begin
        Includis[I].MaschZustandBeiRuesten := Zustand_Wert;
        Zustand_Wert := MaschRuesten;
      end;

      Includis[I].Zustand := Zustand_Wert;
    end; //RP BLOCKSTILL

    if Includis[I].Maschine_geblockt then
    begin
      MaschProgrammbetrieb[I].Istwert := False;
      IMaschProgramm := 0;
      Includis[I].Zustand := 2;
      Zustand_Wert := 2;
    end;

    if Ruestzeit_Auftrag_FolgeAuftrag then
    begin
      if (Includis[I].Auftrag.Stat <> stLaeuftInt) then //kein Auftrag angemeldet, also Status = Rüsten
        Includis[I].Zustand := MaschRuesten;
    end;

    Includis[I].Schicht := Schichtwert;

    if not Includis[I].Maschine_geblockt then
    begin //RP BLOCKSTILL

      if Includis[I].Auftrag.InPause = 0 then
      begin
        if KavitaetFromSPS then
          Includis[I].StueckAuftragGesamt := (StueckAuftragGesamt[I].Istwert)
            div Includis[I].Auftrag.Var_Kavitaet
        else
        begin
          //RS 16.06.2015: Neue Logik für setup.kavitaet_laufender_Auftrag = 3;
          if not Kavitaet_laufender_Auftrag3 OR (Includis[I].Auftrag.LetzerKavWechsel.Datum < 0) then
             Includis[I].StueckAuftragGesamt := (StueckAuftragGesamt[I].Istwert * Includis[I].Auftrag.Kopfgroesse)
            div Includis[I].Auftrag.Var_Kavitaet
          else
          begin
            diff := StueckAuftragGesamt[I].Istwert - Includis[I].Auftrag.LetzerKavWechsel.Schusszaehler;
            Includis[I].StueckAuftragGesamt := (diff * Includis[I].Auftrag.Kopfgroesse) div Includis[I].Auftrag.Var_Kavitaet
                                            + Includis[I].Auftrag.LetzerKavWechsel.Produziert;
            			
          end;
        end;
      end;

      if Includis[I].Auftrag.InPause = 1 then
        Includis[I].Auftrag.Anfahrausschuss := Includis[I].Auftrag.Anfahrausschuss + Diff_Stueck[I];

      //Includis[I].Auftrag.Istwert := Includis[I].StueckAuftragGesamt;
      // Darf nicht pauschal gemacht werden. Beim Rüsten gibts sonst Probleme !!! Len 07.02.12

      Includis[I].StueckPruefAuftragGesamt := StueckPruefAuftragGesamt[I].Istwert * Includis[I].Pruefstation;

      if not Verpackt_Barcode then
        Includis[I].StueckPackAuftragGesamt := StueckPackAuftragGesamt[I].Istwert * Includis[I].Packgroesse;

      if Includis[I].Prod_Gleich_Pack then
      begin
        Includis[I].StueckAuftragGesamt := Includis[I].StueckPackAuftragGesamt;
        Includis[I].Auftrag.Istwert := Includis[I].StueckAuftragGesamt;
      end;

      if Includis[I].Auftrag.Sollwert = 0 then
        Includis[I].Auftrag.Sollwert := 1;

      if (Includis[I].Auftrag.Stat = stLaeuftInt) or (Includis[I].Auftrag.Stat = stStartRuestenInt) then
      begin
        Includis[I].Auftrag.Istwert := Includis[I].StueckAuftragGesamt;
      end;
      if (keinProduziertBeiRuesten and (Includis[I].Auftrag.Stat = stStartRuestenInt)) then
        Includis[I].Auftrag.Istwert := 0;


      if Extrusion then
      begin
        SQLStr := 'select Count(*) CNT from BuchungsProt'
          + ' where BetriebsAuftragNr = ''' + Includis[I].Auftrag.BetriebsauftragNr + '''';
        SQL_Get(Daten.qSuch, SQLStr);
        if Daten.qSuch.FieldByName('CNT').AsInteger > 0 then
        begin
          SQLStr := 'select Sum(Menge) CNT from BuchungsProt'
            + ' where BetriebsAuftragNr = ''' + Includis[I].Auftrag.BetriebsauftragNr + '''';
          SQL_Get(Daten.qSuch, SQLStr);
          Includis[I].Auftrag.Istwert := Format_String(Daten.qSuch.FieldByName('CNT').AsString);
        end
        else
        begin
          Includis[I].Auftrag.Istwert := 0;
        end;
      end;

      Includis[I].Auftrag.Ist_PRZ := Round((Includis[I].Auftrag.Istwert  /
      ( Includis[I].Auftrag.Sollwert + Includis[I].Auftrag.SollwertOffset))* 100);

      (* RS 07.03.2016 - KIENLE - Damit im Nachrüsten nicht die Auftrags-Menge von Detail-Aufträgen verloren geht *)
      if KombiWerkzeuge and ( ( Includis[I].Auftrag.Stat <> stStartRuestenInt) OR not Anfahr_Ausschuss2 ) then
      begin
        if Includis[I].Auftrag.MasterAuftrag then
        begin
          try
            // RS: 16.06.2015: Für Detail-Aufträge kann auch Kavität verändert werden.
            if Kavitaet_laufender_Auftrag3 then
            begin
              S := 'SELECT * FROM PDEKOMBI where MASTERBETRIEBSAUFTRAGNR = '
                 + '''' + Includis[I].Auftrag.BetriebsauftragNr + '''';
              SQL_Get(Daten.qSuch2, S);
              while not Daten.qSuch2.Eof do
              begin
                S := 'SELECT * FROM kavprot WHERE betriebsauftragnr = '
                   + '''' + daten.qSuch2.FieldByName('Betriebsauftragnr').AsString  + ''''
                   + ' ORDER BY datum DESC';
                SQL_Get(Daten.qSuch3, S);
                if Daten.qSuch3.IsEmpty then
                begin
                  diff := Daten.qSuch2.FieldByName('Kavitaet').AsInteger * StueckAuftragGesamt[I].Istwert;
                end
                else
                begin
                  diff := StueckAuftragGesamt[I].Istwert - Daten.qSuch3.FieldByName('Schusszaehler').AsInteger;
                  diff := diff * Daten.qSuch3.FieldByName('Wert2').AsInteger;
                  diff := diff + Daten.qSuch3.FieldByName('Produziert').AsInteger;
                end;
                S := 'UPDATE PDEKOMBI SET istwert = ' + IntToStr(diff)
                   + ' WHERE betriebsauftragnr = '
                   + '''' + daten.qSuch2.FieldByName('Betriebsauftragnr').AsString  + ''''
                   + IgnorePendingStatement;
                SQL_Insert(Daten.qUpdate, S);
                Daten.qSuch2.Next;
              end;
            end
            else


            (*
                                     Die mit einbauen !!!
            ProduziertDetailAuftrag = 190,
        /// <summary> Gut auf Detailauftrag. Derzeit nur einer möglich !! </summary>
        GutDetailAuftrag = 191,
        /// <summary> Ausschuss auf Detailauftrag. Derzeit nur einer möglich !! </summary>
        AusschussDetailAuftrag = 192,
        /// <summary> Ausschuss auf Masterauftrag, aber kein Autoausschuss. Derzeit nur einer möglich !! </summary>
        AusschussMasterAuftrag = 193,


            *)
            if not Includis[i].KombiSeparat then
            begin
              SQL_Insert(Daten.qUpdate, 'update PDEKOMBI set istwert = ('
                + IntToStr(Includis[I].Auftrag.Istwert div Includis[I].Auftrag.Kopfgroesse)
                + ' * Kavitaet) '
                + ' where MASTERBETRIEBSAUFTRAGNR = ''' + Includis[I].Auftrag.BetriebsauftragNr + ''''
                + IgnorePendingStatement);
            end;
          except on e: Exception do
            SchreibeMeldung(e.Message + ' - ' + Includis[I].Auftrag.BetriebsauftragNr,0);
          end;
          // Korrekturen in maschinf für Detailaufträge vornehmen
          try
            SQLStr := 'SELECT p.*, '
              + '(SELECT sum(ausschuss+autoausschuss) FROM tpm_schichtkombi WHERE '
              + ' tpm_schichtkombi.betriebsauftragnr = p.betriebsauftragnr'
            {$IFDEF INCL_MSADO}
              + ' COLLATE database_default'
            {$ENDIF}
              + ') '
              + ' ausschuss, a.gesamtausschuss FROM pdekombi p, aarchiv a '
              + 'WHERE p.betriebsauftragnr=a.betriebsauftragnr and p.masterbetriebsauftragnr ='''
              + Includis[I].Auftrag.BetriebsauftragNr + '''';
            SQL_Get(Daten.qSuch, SQLStr);
            while not Daten.qSuch.EOF do
            begin
              SQL_Get(Daten.qSuch2, 'SELECT * FROM pdekombi WHERE betriebsauftragnr = '''
                + Daten.qSuch.FieldByName('betriebsauftragnr').AsString + '''');

              SQLStr := 'UPDATE maschinf SET endedatum = null';
                //  + DateTimeToStr(GetEndeDatumLizenz(Includis[I].Lizenz, Includis[I].Auftrag.BetriebsauftragNr,
//  Jetzt, Trunc((Daten.qSuch2.FieldByName('sollwert').AsInteger - Daten.qSuch2.FieldByName('istwert').AsInteger)
//  * Includis[I].Auftrag.Solltakt / (6000 * Daten.qSuch2.FieldByName('kavitaet').AsInteger))))
              if not Includis[i].KombiSeparat then
              begin
                if Includis[i].MusternAktiv then
                begin
                  SQLStr := SQLStr + ', stueck=0, MusternStueck = ' + Daten.qSuch.FieldByName('istwert').AsString
                  + ', istwert_prz = ''0 %'' ';
                end
                else
                begin
                  SQLStr := SQLStr + ', stueck = ' + Daten.qSuch.FieldByName('istwert').AsString
                  + ', istwert_prz = ''' + IntToStr(Trunc(Daten.qSuch.FieldByName('istwert').AsInteger * 100 /
                  Daten.qSuch.FieldByName('sollwert').AsInteger)) + ' %'' ';
                end;
              end;
              SQLStr := SQLStr + ', kavitaet = ''' + Daten.qSuch.FieldByName('kavitaet').AsString
                + ''', ausschuss = ''' + Daten.qSuch.FieldByName('ausschuss').AsString
                + ''', Sollwert = ''' + Daten.qSuch.FieldByName('Sollwert').AsString
                + ''', gesamtausschuss = ''' + Daten.qSuch.FieldByName('gesamtausschuss').AsString
                + ''', kavitaet_soll = ''' + Daten.qSuch.FieldByName('kavitaet').AsString
                + ''' WHERE betriebsauftragnr = ''' + Daten.qSuch.FieldByName('betriebsauftragnr').AsString + '''';

              SQL_Insert(Daten.qUpdate, SQLStr);


              Daten.qSuch.Next;
            end;
          except
          end;
        end;
      end;

      //RS 16.06.2015: hier wird die Kavitäts-Wechsel-Funktion nicht berücksichtigt.
      if not Metall then
      begin
        if Variable_Kavitaet then
          Includis[I].StueckSchicht := (StueckSchicht[I].Istwert * Includis[I].Auftrag.Kopfgroesse) div
            Includis[I].Auftrag.Var_Kavitaet
        else
        begin
          if KavitaetFromSPS then
            Includis[I].StueckSchicht := StueckSchicht[I].Istwert
          else
            Includis[I].StueckSchicht := StueckSchicht[I].Istwert * Includis[I].Auftrag.Kopfgroesse;
        end;
      end;

      try
        if Includis[I].Auftrag.Packgroesse > 0 then
          Includis[I].KARTONS := Includis[I].StueckAuftragGesamt div Includis[I].Auftrag.Packgroesse
        else
          Includis[I].KARTONS := 0;
        if Includis[I].KARTONS > 0 then
          Includis[I].PALETTEN := Includis[I].StueckAuftragGesamt div Includis[I].KARTONS
        else
          Includis[I].PALETTEN := 0;
      except
        Includis[I].KARTONS := 0;
        Includis[I].PALETTEN := 0;
      end;
      Includis[I].StueckPruefSchicht := StueckPruefSchicht[I].Istwert * Includis[I].Pruefstation;
      if not Verpackt_Barcode then
        Includis[I].StueckPackSchicht := StueckPackSchicht[I].Istwert * Includis[I].Packgroesse;

      Includis[I].AusschussSchicht := Includis[I].StueckSchicht - Includis[I].StueckPackSchicht;

      Includis[I].AusschussAuftragSchicht := Includis[I].StueckAuftragSchicht - Includis[I].StueckPackAuftragSchicht;

      //RS 16.06.2015: hier wird die Kavitäts-Wechsel-Funktion nicht berücksichtigt.
      if not Metall then
      begin
        if Variable_Kavitaet then
          Includis[I].StueckAuftragSchicht := (StueckAuftragSchicht[I].Istwert * Includis[I].Auftrag.Kopfgroesse)
            div Includis[I].Auftrag.Var_Kavitaet
        else
        begin
          if KavitaetFromSPS then
            Includis[I].StueckAuftragSchicht := StueckAuftragSchicht[I].Istwert
          else
             Includis[I].StueckAuftragSchicht := StueckAuftragSchicht[I].Istwert * Includis[I].Auftrag.Kopfgroesse;
        end;
       end;

      Includis[I].StueckAuftragSchicht_SPS := Includis[I].StueckAuftragSchicht;

      if Menge_Schicht_Berechnen and (Includis[I].Auftrag.BetriebsauftragNr <> '')  then
      begin
        SQLStr := 'select Sum(Produziert) PP, Sum(Anfahrausschuss) AA, SUM(zyklen)zz, SUM(geprueft) prf,'
          + ' Sum(Autoausschuss / CASE WHEN kavitaet = 0 THEN 1 ELSE kavitaet END) AUS from TPM_Schicht where BetriebsAuftragNr = '''
          + Includis[I].Auftrag.BetriebsauftragNr + ''''
          + ' and DatumZeit < ' + FloatToPunktString(TTT_GetTPMSchichtZeit(Includis[I].Schicht, Jetzt) - 1 / 1440);
        {$IFDEF INCL_MSADO}
//           SQLStr := SQLSTR + ' COLLATE database_default';
        {$ENDIF}
        SQL_Get(Daten.qSuch, SQLStr);
        if not Daten.qSuch.IsEmpty then
        begin
          SProd := Daten.qSuch.FieldByName('PP').AsInteger;
          SAnfahr := Daten.qSuch.FieldByName('AA').AsInteger;
          SAutoAusschuss := Daten.qSuch.FieldByName('AUS').AsInteger;
          SZyk := Daten.qSuch.FieldByName('zz').AsInteger;
          SPruef := Daten.qSuch.FieldByName('prf').AsInteger;
        end
        else
        begin
          SProd := 0;
          SAnfahr := 0;
          SAutoAusschuss := 0;
          SZyk := 0;
          SPruef :=0;
        end;

        if SQLGetBool(Daten.qSuch, 'PDE', 'BetriebsAuftragNr', Includis[I].Auftrag.BetriebsauftragNr) then
        begin
          if ( ( Daten.qSuch.FieldByName('Pending').AsInteger = 0 ) AND ( Daten.qSuch.FieldByName('stat').AsInteger = 0 ) ) then
          begin
            AProd := Includis[I].Auftrag.Istwert;
            APruef := Includis[I].StueckPruefAuftragGesamt;
          end
          else
          begin
            AProd := Daten.qSuch.FieldByName('Istwert').AsInteger;
            if Daten.qSuch.FieldByName('Pruef').AsString = '' then
              APruef := 0
            else
              APruef := Daten.qSuch.FieldByName('Pruef').AsInteger;
          end;
          AAnfahr := Daten.qSuch.FieldByName('Anfahr_Ausschuss').AsInteger;
          Includis[I].StueckAuftragSchicht := AProd - SProd;
          Includis[I].Auftrag.Anfahrausschuss := AAnfahr - SAnfahr;
          Includis[i].StueckPruefSchicht := APruef - SPruef;
          StueckPruefAuftragSchicht[I].Istwert := Includis[i].StueckPruefSchicht;
          AZyk := StueckAuftragGesamt[i].Istwert;
          if AZyk =0 then
          begin
            SQLStr := 'select SUM(zyklen)zz FROM TPM_Schicht WHERE BetriebsAuftragNr = '''
              + Includis[I].Auftrag.BetriebsauftragNr + '''';
            SQL_Get(Daten.qSuch, SQLStr);
            AZyk := Daten.qSuch.FieldByName('zz').AsInteger;
          end;
          Includis[i].ZyklenAuftragGesamt := AZyk;
          Includis[i].ZyklenAuftragSchicht := AZyk - SZyk;
          if Includis[i].ZyklenAuftragSchicht < 0 then
            Includis[i].ZyklenAuftragSchicht :=0;
          // Minus im Schichtprotokoll zulassen?  Sascha. 04.09.2008

          if not Menge_Schicht_Minus then
          begin
            if Includis[I].StueckAuftragSchicht < 0 then
              Includis[I].StueckAuftragSchicht := 0;
            if Includis[I].Auftrag.Anfahrausschuss < 0 then
              Includis[I].Auftrag.Anfahrausschuss := 0;
          end;
        end
        else
        begin
          if Includis[I].Auftrag.Stat <> stStartRuestenInt then
            Includis[I].StueckAuftragSchicht := Includis[I].Auftrag.Istwert - SProd
          else
            Includis[I].StueckAuftragSchicht := Includis[I].Auftrag.Istwert - SAnfahr;

          if Includis[I].StueckAuftragSchicht < 0 then
            Includis[I].StueckAuftragSchicht := 0;
        end;
        if Includis[I].Auftrag.Stat = stStartRuestenInt then
          AUTOAUSSCHUSS_AUFTRAGSchicht[I].Istwert := 0
        else
          AUTOAUSSCHUSS_AUFTRAGSchicht[I].Istwert := AUTOAUSSCHUSS_AUFTRAG[I].Istwert - SAutoAusschuss;
      end
      else
      begin
        SProd := 0;
        SAnfahr := 0;
        SAutoAusschuss := 0;
        SZyk := 0;
        SPruef :=0;
        AUTOAUSSCHUSS_AUFTRAGSchicht[I].Istwert :=0;
        Includis[I].Auftrag.Anfahrausschuss := 0;
        AUTOAUSSCHUSS_AUFTRAGSchicht[I].Istwert := 0;
        if Includis[I].Auftrag.Stat = stStartRuestenInt then
        begin
          Includis[I].Auftrag.Anfahrausschuss := Includis[I].StueckAuftragSchicht;
          Includis[I].StueckAuftragSchicht := 0;
        end;
      end;

      Includis[I].StueckPruefAuftragSchicht := StueckPruefAuftragSchicht[I].Istwert * Includis[I].Pruefstation;
      if not Verpackt_Barcode then
        Includis[I].StueckPackAuftragSchicht := StueckPackAuftragSchicht[I].Istwert * Includis[I].Packgroesse;
    end;

    //RP BLOCKSTILL
    if Includis[I].PruefPack = 4 then
    begin
      // kein Prüfen, kein Packen
      Includis[I].StueckPruefAuftragGesamt := Includis[I].StueckAuftragGesamt;
      if not Verpackt_Barcode then
        Includis[I].StueckPackAuftragGesamt := Includis[I].StueckAuftragGesamt;

      Includis[I].StueckPruefSchicht := Includis[I].StueckSchicht;
      if not Verpackt_Barcode then
        Includis[I].StueckPackSchicht := Includis[I].StueckSchicht;
      Includis[I].AusschussSchicht := Includis[I].StueckSchicht - Includis[I].StueckPackSchicht;

      Includis[I].StueckPruefAuftragSchicht := Includis[I].StueckAuftragSchicht;
      if not Verpackt_Barcode then
        Includis[I].StueckPackAuftragSchicht := Includis[I].StueckAuftragSchicht;
    end;

    if Verpackt_aus_Ausschuss then
    begin
      Includis[I].StueckPackAuftragGesamt := Includis[I].Auftrag.Istwert
        - Includis[I].Auftrag.Ausschuss;
      Includis[I].StueckPackAuftragSchicht := Includis[I].StueckAuftragSchicht
        - Includis[I].AusschussAuftragSchicht;
      Includis[I].StueckPackSchicht := Includis[I].StueckSchicht - Includis[I].AusschussSchicht;
    end;

    if halbautomatik then
      Includis[I].HandAuto := HandAuto[I].Istwert
    else
      Includis[I].HandAuto := False;

    Includis[I].BCD_Read := BCD_Read[I].Istwert;
    Includis[I].BCDCode := BCD[I].Istwert;

    //**************************************************************************************************
    //   BERECHNUNGEN: NUTZUNG, LEISTUNG, QUALIITÄT, EFFEKTIVITÄT
    //**************************************************************************************************
    if not Includis[I].Maschine_geblockt then
    begin //RP BLOCKSTILL
      Ausschuss := Includis[I].StueckAuftragSchicht - Includis[I].StueckPackAuftragSchicht;

      //Nutzung berechnen
      Tagwechsel := False;
      Schichtanfang := Schicht1;
      if Includis[I].Schicht = 1 then
        Schichtanfang := Schicht1;
      if Includis[I].Schicht = 2 then
        Schichtanfang := Schicht2;
      if Includis[I].Schicht = 3 then
        Schichtanfang := Schicht3;

      Tag := Trunc(Schichtanfang);
      MinutenAnfang := Schichtanfang - Tag;
      //Tagwechsel
      if MinutenAnfang > 0.8 then
      begin
        Tagwechsel := True;
        MinutenAnfang := 0.0;
      end;

      Tag := Trunc(Jetzt);
      MinutenJetzt := Jetzt - Tag;

      tbMinuten := Trunc((MinutenJetzt - MinutenAnfang) * 24 * 60);
      if Tagwechsel then
        tbMinuten := tbMinuten + 120; // von 22:00 bis 0:00 Uhr

      //wenn handbetrieb, dann "SchichtZeitHandbetrieb" abziehen
      if ((tbMinuten > SchichtZeitHandbetrieb) and (Includis[I].HandAuto)) then
        tbMinuten := tbMinuten - SchichtZeitHandbetrieb;

      if (tbMinuten < 0) and (Shift_Model <> 2) then
      begin
        Meldung := 'Error: calculation minutes start of shift to ' + DateToStr(Trunc(Jetzt))
          + ' at: ' + TimeToStr(Frac(Jetzt)) + ' < 0 !! Minutes: ' + IntToStr(tbMinuten);
        SchreibeMeldung(Meldung, 0);
      end;

      //Qualität berechnen
      NA := 0; //nur bei Metall einzusetzen
      Divisor := Includis[I].StueckAuftragSchicht;
      if Divisor = 0 then
        Divisor := 1;
      Includis[I].Qualitaet := ((Includis[I].StueckAuftragSchicht - Ausschuss - NA - Includis[I].AusschussAuftragSchicht) / Divisor) * 100;
    end; //if NOT Includis[I].Maschine_geblockt then begin  //RP BLOCKSTILL
  end;

  for I := 1 to Anzahl_Masch do
  begin
    if ( Includis[I].Auftrag.AuftragNr = '' ) and not Includis[I].IstArchiviert then
    begin
      Includis[I].IstTakt := 0;
      Includis[I].StueckSchicht := 0;
      Includis[I].StueckPackSchicht := 0;
      Includis[I].StueckPruefSchicht := 0;
      Includis[I].Nutzung := 0;
      Includis[I].Leistung := 0;
      Includis[I].Qualitaet := 0;
      Includis[I].Effektivitaet := 0;
      Includis[I].Auftrag.Ist_PRZ := 0;
      Includis[I].Auftrag.Programm_Nr := 0;
      Includis[I].Auftrag.Istwert := 0;
      Includis[I].Auftrag.Ausschuss := 0;
      Includis[I].Auftrag.Verpackt := 0;
      Includis[I].StueckPruefAuftragGesamt := 0;
      Includis[I].StueckPackAuftragGesamt := 0;
      Includis[I].Auftrag.Schwesterauftrag := '';
      Includis[I].Auftrag.Form := '';
      Includis[I].Auftrag.Optimiert := 0;
      Includis[I].Auftrag.OptimiertAktuell := 0;
      Includis[I].Auftrag.Anfahrausschuss := 0;
      Includis[I].StueckPackAuftragSchicht := 0;

      Includis[I].StueckAuftragSchicht := 0;
      Includis[I].AusschussAuftragSchicht := 0;
      Includis[i].ZyklenAuftragGesamt := 0;
      Includis[i].ZyklenAuftragSchicht := 0;
    end;
  end;
end;

procedure CCC_Job_Auftrag;
var
  Nummer: Integer;
  Meldung: string;
  I: Integer;
  automatikstr: string;
begin
  for I := 1 to Anzahl_Masch do
  begin
    if (Includis[I].Auftrag.Stat = stLaeuftInt) and not Includis[I].IstArchiviert then
    begin
      //Menge erfüllt ??
      if ((Includis[I].Auftrag.Istwert >= ( Includis[I].Auftrag.SollwertOffset + Includis[I].Auftrag.Sollwert)) and not Includis[I].Auftrag.Erzeugt) then
      begin
        //****************************************************
        //      A r b e i t s p l a n   e r s t e l l e n
        //****************************************************
        //prüfen, ob Arbeitsplan schon erzeugt ist
        Daten.qSuch.Close;
        if (SQL2GetBool(Daten.qSuch, 'BDA', 'Lizenz', Includis[I].Lizenz, 'Bezeichnung',
          Includis[I].Auftrag.Bezeichnung)) then
        begin
          if Daten.qSuch.FieldByName('Zustand').AsString = GetL('Vorwarnung') then
          begin //Zustand ändern
            Nummer := Daten.qSuch.FieldByName('Nr').AsInteger;
            Meldung := GetL('Menge erfüllt');
            UpdateSQL(Daten.qUpdate, 'BDA', 'Zustand', Meldung, 'Nr', IntToStr(Nummer));
            if Daten.qSuch.FieldByName('Erledigt').AsString = GetL('Vorwarnung') then
            begin //Zustand in Stammliste ändern
              UpdateSQL(Daten.qUpdate, 'BDA', 'Erledigt', Meldung, 'Nr', IntToStr(Nummer));
            end;
          end;
        end
        else
        begin
          CCC_Erzeuge_Arbeitsplan(Includis[I].Lizenz, Includis[I].MaschNr,
            Includis[I].Auftrag.Signal,
            IntToStr(Includis[I].Auftrag.Sollwert + Includis[I].Auftrag.SollwertOffset),
            Includis[I].Auftrag.Bezeichnung,
            Includis[I].Auftrag.Zustaendig,
            False, IntToStr(Includis[I].Auftrag.Vorwarnung), False, False);
        end;
        //Auftrag als "Erzeugt" deklarieren
        Daten.qSuch.Close;
        if (SQL2GetBool(Daten.qSuch, 'PDE', 'Lizenz', Includis[I].Lizenz, 'Bezeichnung',
          Includis[I].Auftrag.Bezeichnung)) then
          Update2SQL(Daten.qUpdate, 'PDE', 'Erzeugt', '1', 'Lizenz', Includis[I].Lizenz, 'Bezeichnung',
            Includis[I].Auftrag.Bezeichnung);

        //Daten Aktualisieren
        CCC_Init;
        Exit;
      end;

      // Vorwarnung ??
      if ((Includis[I].Auftrag.Ist_PRZ >= Includis[I].Auftrag.Vorwarnung) and not Includis[I].Auftrag.VorwarnungErzeugt) then
      begin
        //****************************************************
        //    VORWARNUNG  A r b e i t s p l a n   e r s t e l l e n
        //****************************************************
        //prüfen, ob Arbeitsplan schon erzeugt ist
        Daten.qSuch.Close;
        if (SQL2GetBool(Daten.qSuch, 'BDA', 'Lizenz', Includis[I].Lizenz, 'Bezeichnung',
          Includis[I].Auftrag.Bezeichnung)) then
        begin
        end
        else
        begin
          CCC_Erzeuge_Arbeitsplan(Includis[I].Lizenz, Includis[I].MaschNr,
            Includis[I].Auftrag.Signal,
            IntToStr(Includis[I].Auftrag.Sollwert + Includis[I].Auftrag.SollwertOffset),
            Includis[I].Auftrag.Bezeichnung,
            Includis[I].Auftrag.Zustaendig,
            True, IntToStr(Includis[I].Auftrag.Vorwarnung), False, False);
        end;
        Includis[I].Auftrag.VorwarnungErzeugt := True;
      end;
      // Halbautomatik Schlüsselschalter ??
      if (((Includis[I].Auftrag.HalbAuto <> Includis[I].HandAuto)
        and not Includis[I].Auftrag.VorwarnungErzeugt)
        and (Includis[I].Auftrag.Stat <> 2) and halbautomatik)
        and TCO_Setup.GetParamBool(Daten.qUpdate, 'INCL_HalbautomatSchluesselschalter') then
      begin
        //****************************************************
        //    VORWARNUNG  A r b e i t s p l a n   e r s t e l l e n
        //****************************************************
        //prüfen, ob Arbeitsplan schon erzeugt ist
        if Includis[I].Auftrag.HalbAuto then
          automatikstr := GetL('Halbautomatik')
        else
          automatikstr := GetL('Automatik');
        Daten.qSuch.Close;
        if (SQL2GetBool(Daten.qSuch, 'BDA', 'Lizenz', Includis[I].Lizenz,
          'Bezeichnung', GetL('Fehler Auftrag: Schlüsselschalter prüfen'))) then
        begin
        end
        else
        begin
          CCC_Erzeuge_Arbeitsplan(Includis[I].Lizenz, Includis[I].MaschNr,
            Includis[I].Auftrag.Signal,
            automatikstr,
            GetL('Fehler Auftrag: Schlüsselschalter prüfen'),
            Includis[I].Auftrag.Zustaendig,
            False, IntToStr(Includis[I].Auftrag.Vorwarnung), False, True);
        end;
        Includis[I].Auftrag.VorwarnungErzeugt := True;
      end;
    end;
  end;
end;

procedure CCC_BDE_Auftrag;
var
  Nummer: Integer;
  Meldung: string;
  I: Integer;
begin
  for I := 1 to Anzahl_Masch do
  begin
    if (Includis[I].BDE.Bezeichnung <> '') and not Includis[I].IstArchiviert then
    begin
      //Menge erfüllt ??
      if ((Includis[I].Betriebsstunden >= Includis[I].BDE.Sollwert) and not Includis[I].BDE.Erzeugt) then
      begin
        //****************************************************
        //      A r b e i t s p l a n   e r s t e l l e n
        //****************************************************
        //prüfen, ob Arbeitsplan schon erzeugt ist
        Daten.qSuch.Close;
        if (SQL2GetBool(Daten.qSuch, 'BDA', 'Lizenz', Includis[I].Lizenz, 'Bezeichnung', Includis[I].BDE.Bezeichnung)) then
        begin
          if (Daten.qSuch.FieldByName('Zustand').AsString = 'Vorwarnung') then
          begin //Zustand ändern
            Nummer := Daten.qSuch.FieldByName('Nr').AsInteger;
            Meldung := GetL('sofort erledigen');
            UpdateSQL(Daten.qUpdate, 'BDA', 'Zustand', Meldung, 'Nr', IntToStr(Nummer));
            if Daten.qSuch.FieldByName('Erledigt').AsString = GetL('Vorwarnung') then
            begin //Zustand in Stammliste ändern
              UpdateSQL(Daten.qUpdate, 'BDA', 'Erledigt', Meldung, 'Nr', IntToStr(Nummer));
            end;
          end;
        end
        else
        begin
          CCC_Erzeuge_Arbeitsplan(Includis[I].Lizenz, Includis[I].MaschNr,
            Includis[I].BDE.Signal,
            IntToStr(Includis[I].BDE.Sollwert),
            Includis[I].BDE.Bezeichnung,
            Includis[I].BDE.Zustaendig,
            False, IntToStr(Includis[I].BDE.Vorwarnung), False, False);
        end;
        //Auftrag als "Erzeugt" deklarieren
        Daten.qSuch.Close;
        if (SQL2GetBool(Daten.qSuch, 'MDE', 'Lizenz', Includis[I].Lizenz, 'JobBezeichnung',
          Includis[I].BDE.Bezeichnung)) then
        begin
          Nummer := Daten.qSuch.FieldByName('Nr').AsInteger;
          DeleteSQL(Daten.qUpdate, 'MDE', 'Nr', IntToStr(Nummer));
        end;
        //Daten Aktualisieren
        CCC_Init;
        Exit;
      end;

      // Vorwarnung ??
      if ((Includis[I].Betriebsstunden >= Includis[I].BDE.Vorwarnung) and not Includis[I].BDE.VorwarnungErzeugt) then
      begin
        //****************************************************
        //    VORWARNUNG  A r b e i t s p l a n   e r s t e l l e n
        //****************************************************
        //prüfen, ob Arbeitsplan schon erzeugt ist
        Daten.qSuch.Close;
        if (SQL2GetBool(Daten.qSuch, 'BDA', 'Lizenz', Includis[I].Lizenz, 'Bezeichnung', Includis[I].BDE.Bezeichnung)) then
        begin
        end
        else
        begin
          CCC_Erzeuge_Arbeitsplan(Includis[I].Lizenz, Includis[I].MaschNr,
            Includis[I].BDE.Signal,
            IntToStr(Includis[I].BDE.Sollwert),
            Includis[I].BDE.Bezeichnung,
            Includis[I].BDE.Zustaendig,
            True, IntToStr(Includis[I].BDE.Vorwarnung), False, False);
        end;
        Includis[I].BDE.VorwarnungErzeugt := True;
      end;
    end;
  end;
end;

procedure CCC_Daten_Schreiben;
var
  ZustandStr: string;
  T, real_t: TDateTime;
  AnzJob: string;
  cavFactor, diffMenge, RemainTime, ZeitSchicht, DT: Real;
  Nummer: Integer;
  Dauer: Integer;
  SollwertABS: Integer;
  Istwert: Integer;
  Sollwert: Integer;
  Lizenz, Kurzkennung: string;
  StartDatumStr: string;
  EndeDatum: string;
  EndeZeitpunkt: TDateTime;
  StatStr: string;
  AusTemp1, AusTemp2, AusSpritz, AusNach, AusSpeed: Smallint;
  Erzeugen: Boolean;
  AnzSchuss: Integer;
  IstStandzeit, Einsatzdauer, Sollstandzeit: Integer;
  IstStandzeit_2, Sollstandzeit_2: Integer;
  tmpLiz, Istwert_PRZ, Stueck: string;
  Anzahl, Nr: Integer;
  SPC_Value: Real;
  Termin_Rechnerisch: TDateTime;
  Erstellungsdatum: TDateTime;
  OEE_Stops, OEE_Anlagenausfall, OEE_Ruesten: Integer;
  OEE_Logistik, OEE_Nichtgebucht, OEE_Geplant: Integer;
  OEE_Ungeplant, OEE_Sollaufzeit, OEE_Istlaufzeit: Integer;
  OEE_Nutzung, OEE_Leistung, OEE_Qualitaet, OEE_Effektivitaet: Real;
  Ausschuss, tmp_Stueck, tmp_prz, tmp_musternstueck: Integer;
  Reststandzeit: Integer;
  CO_Meldung: Integer;
  tmp_Produziert: Integer;
  StillAktual: string;
  StillNr: Integer;
  WaitCnt, ZustandInt, I, J, EndeTakt, Prod: Integer;
  DoppelWZ, MaschNr: string;
  TaktMittelSchicht, TaktMittelAuftrag: Real;
  SHIFT_TYP: string;
  Anfahr_Ausschuss2: Boolean;
  SollKartons: Integer;
  VerpacktKartons: Integer;
  Personal: string;
  SchichtMengenAuchOhneLaufzeit, AuftragsEndeberechnen: Boolean;
  rt_laufzeit, rt_einlegezeit, rt_stillzeit: Integer;
  heizungmeldungan, takt_aus_plan: Boolean;
  EndeDT: Real;
  Schichtstart: Extended;
  optimiert_schicht: Integer;
  ueberprod : bool;
  stage : integer;
  COTPM_Stillstaende : TStillstandEintragsListe;
//  COTPM_StillstaendeAll : TStillstandEintragsListe;
  StillListObject : TStillstandEintrag;
 // tempstilllist : TStillstandEintragsListe;
  tmp_starttime : TDateTime;
  isunicode : boolean;
  LizenzList : TStringList;
  tmpFloat : Extended;
  VerpacktProtAusAarchivUndAusschussProt : boolean;
  VerpacktProtAusSchichtausschuss,wartunginende : boolean;
  FpAusschussQuote : Boolean;
  taktzeitSchichtTmp, taktzeitAuftragTmp : real;
  taktzeitUpperTmp, taktzeitLowerTmp : real;
  VerpacktInSchichtProt:bool;

  function GetAusschussSPSKavitaet(Wert, Kopfgroesse : Integer) : Integer;
  begin
    if KavitaetFromSPS then
      result := Wert
    else
      result := Wert * Kopfgroesse;
  end;

begin
stage :=0;
  real_t := Jetzt;
  ZeitSchicht := Frac(Jetzt);
{$ifdef TIMEMEAS}
  SchreibeMeldung('Start', 1);
{$endif}
  EndeDatum := '';
  VerpacktInSchichtProt:=TCO_Setup.GetParamBool(Daten.qSuch, 'INCL_VerpacktInSchichtProt');

  SQLGet(Daten.qSuch4, 'Setup', 'Nr', '1', False);
  Anfahr_Ausschuss2 := Daten.qSuch4.FieldByName('Anfahr_Ausschuss2').AsInteger = 1;
  VerpacktProtAusSchichtausschuss := TCO_Setup.GetParamBool(Daten.qSuch3, 'INCL_VerpacktProt_aus_Schichtausschuss');

  wartunginende := TCO_Setup.GetParamBool(Daten.qSuch4,  'Wartung_Verlaengert_Auftrag', False);
  AuftragsEndeberechnen := TCO_Setup.GetParamBool(Daten.qSuch4, 'INCL_Auftragsende_immer_berechnen');
  SchichtMengenAuchOhneLaufzeit := TCO_Setup.GetParamBool(Daten.qSuch4, 'INCL_ShiftProducedWithoutRuntime');
  FpAusschussQuote := TCO_Setup.GetParamBool(Daten.qSuch4, 'FP_Ausschussquote');
  takt_aus_plan := TCO_Setup.GetParamInt(Daten.qUpdate, 'FP_Plantakt') > 0;

  if Vor_Schichtwechsel then
  begin
    if Includis[1].Schicht = 1 then
      ZeitSchicht := Schicht2;
    if Includis[1].Schicht = 2 then
      ZeitSchicht := Schicht3;
    if Includis[1].Schicht = 3 then
      ZeitSchicht := Schicht1;
  end;

  case Includis[1].Schicht of
    1: Schichtstart := Trunc(Jetzt) + Schicht1;
    2: Schichtstart := Trunc(Jetzt) + Schicht2;
    3: Schichtstart := Trunc(Jetzt) + Schicht3;
  end;
  if Frac(Jetzt) < Schicht1 then
    SchichtStart := Schichtstart - 1;

  if ZeitSchicht > 1 then
    ZeitSchicht := ZeitSchicht - Trunc(ZeitSchicht);

  T := Trunc(Jetzt) + ZeitSchicht; //Zeit runden

{$ifdef TIMEMEAS}
  SchreibeMeldung('Start MaschCyc', 1);
{$endif}

  isunicode := SQLGet(Daten.qSuch, 'PDESTAMM_UNICODE', 'Auftragnr', Includis[I].Auftrag.AuftragNr, true) > 0;

  VerpacktProtAusAarchivUndAusschussProt := TCO_Setup.GetParamBool(Daten.qSuch4, 'INCL_VerpacktProt_aus_Aarchiv_und_AusschussProt', false);
  // caching der Stillstände im Bereich für CO_TPM.Calc

  COTPM_Stillstaende := TStillstandEintragsListe.Create;

//  COTPM_StillstaendeAll := TStillstandEintragsListe.Create;
  SQLStr := 'select tl.nr, tl.kommt, tl.geht, tl.maschnr, ts.gruppe, ts.geplant, tl.stillstandnr, ts.stillstand from TPM_STILLOG tl '
      + ' LEFT JOIN tpm_stillstaende ts ON ts.stillstandnr=tl.stillstandnr '
      + ' where Kommt <= ' + FloatToPunktString(Jetzt)
      + ' and  case when geht = 0 then ' +FloatToPunktString(Jetzt)+ ' else geht end >= '
      + FloatToPunktString(CCC_GetTPMSchichtAnfang(Includis[1].Schicht, Jetzt));
  SQL_Get(Daten.qSuch, SQLStr);
  while not Daten.qSuch.Eof do
  begin
    StillListObject := TStillstandEintrag.Create;
    StillListObject.Nr :=  Daten.qSuch.FieldByName('nr').AsInteger;
    StillListObject.Kommt := Daten.qSuch.FieldByName('kommt').AsFloat;
    StillListObject.Geht := Daten.qSuch.FieldByName('geht').AsFloat;
    StillListObject.Maschnr := Daten.qSuch.FieldByName('maschnr').AsInteger;
    StillListObject.Geplant := Daten.qSuch.FieldByName('geplant').AsInteger=1;
    StillListObject.GrundNr := Daten.qSuch.FieldByName('stillstandnr').AsInteger;
    StillListObject.Gruppe := Daten.qSuch.FieldByName('gruppe').AsInteger;
    StillListObject.Stillstand := Daten.qSuch.FieldByName('stillstand').AsString;
    COTPM_Stillstaende.AddRaw(StillListObject);
//    COTPM_StillstaendeAll.AddRaw(StillListObject.CopyMe);
    Daten.qSuch.Next;
  end;

  stage := 1;

  LizenzList := TStringList.Create;
  SQLStr := 'SELECT lizenz FROM maschinf';
  SQL_Get(Daten.qSuch, SQLStr);
  while not Daten.qSuch.Eof do
  begin
    Lizenz := Daten.qSuch.FieldByName('lizenz').AsString;
	  if (LizenzList.IndexOf(Lizenz) > -1) then // Wenn schon drin, nicht noch einmal hinzufügen
	  begin
		  if (LizenzList.IndexOf('W2') < 0)  then // Kein KombiWerkzeug, also beide Einträge löschen
		  begin
			  SQL_Insert(Daten.qUpdate, 'DELETE FROM maschinf WHERE lizenz=''' + Lizenz + '''');
        i := LizenzList.IndexOf(Lizenz);
			  LizenzList.Delete(i);
  		end;
	  end
	  else
		  LizenzList.Add(Daten.qSuch.FieldByName('lizenz').AsString);
    Daten.qSuch.Next;
  end;
  // Dann löschen wir hier gleich mal auch doppelte PDE Einträge  , Max Nr ist meist zuviel.
  SQL_Insert(Daten.qUpdate, 'DELETE FROM pde WHERE nr =(SELECT MAX(nr) FROM pde GROUP BY betriebsauftragnr HAVING COUNT(*) > 1)');

 try
  tmp_starttime := Now;
  for I := 1 to Anzahl_Masch do
  begin
    //SchreibeMeldung('Last Cylce MNr:' + IntTostr(i) + ' - ' + FloatToStr(trunc((Now-tmp_starttime) * 24*60*60*1000)) + 'ms', 1);
    tmp_starttime := now;
    if (Includis[I].Lizenz = '' ) or Includis[I].IstArchiviert then
      Continue;

    //**************************************************************************
    //  MASCH_ZUSTAND schreiben
    //**************************************************************************
    if (Includis[I].Zustand = 0) then
      ZustandStr := GetL('Programmbetrieb');
    if (Includis[I].Zustand = 1) then
      ZustandStr := GetL('Rüsten');
    if (Includis[I].Zustand = 2) then
      ZustandStr := GetL('Störung');
    if (Includis[I].Zustand = 4) then
      ZustandStr := GetL('undefiniert');

    if Includis[I].MaschinenTyp > 0 then
      if SQL2GetBool(Daten.qSuch, 'PDE', 'Lizenz', Includis[I].Lizenz, 'stat', '0') then
      begin
        Includis[I].Auftrag.Istwert := Daten.qSuch.FieldByName('istwert').AsInteger;
      end;
    try  // Standard ist True, Promens Neumünster deaktiviert (false), muss aber wieder rein !!!!
      if true then // Zustandsabfrage rausgeschmissen. Ende kann immer berechnet werden.  ML 18.09.2008
        (*
        if Includis[I].Zustand = 0 then
        begin
          if (Includis[I].Auftrag.Stat = stLaeuftInt) then
            EndeDatum := DateTimeToStr(Includis[I].Auftrag.EndeDatum)
          else
            EndeDatum := ' ';
        end;

        if (Includis[I].Zustand <> 0) or AuftragsEndeberechnen then
        *)
      begin
        //RS 20.04.2016 - Kienle: wenn kein Auftrag läuft, wird die Restlaufzeit immer auf 0 und die Ist-Kavität immer auf 1 gesetzt
        if Includis[I].Auftrag.BetriebsauftragNr = '' then
        begin
          RemainTime := 0;
          Includis[I].Auftrag.Kopfgroesse := 1
        end;
          
        EndeDatum := Includis[I].Auftrag.EndeDatumSTR;
        if not Arbeitsfrei(Includis[I].Lizenz, Jetzt) then
          if (Includis[I].Auftrag.Stat = stLaeuftInt) then
          begin
            if Ende_Aus_Isttakt or Ende_Aus_Isttakt_IstKav then
              EndeTakt := S7Main.S7_Auftrag.GetIstTakt(Includis[I].Lizenz)
            else
              EndeTakt := Includis[I].Auftrag.Solltakt;
            if EndeTakt < 10 then
              EndeTakt := Includis[I].Auftrag.Solltakt;

            if takt_aus_plan then
              if Includis[I].Auftrag.planzykluszeit > 0 then
                EndeTakt := Includis[I].Auftrag.planzykluszeit;
            if FpAusschussQuote then
              EndeTakt := Round(EndeTakt * (1 + (Includis[I].Auftrag.ausschussquote / 10000)));

            if SpannzeitUeberwachen then
              EndeTakt := EndeTakt + Round(Includis[I].Auftrag.SollSpannzeitStk * (1 + (Includis[I].SpannzeitToleranz /
                100)));
stage := 2;
            if Includis[I].Kopfgroesse <= 0 then
              Includis[I].Kopfgroesse := 1;
            if Includis[I].Auftrag.Var_Kavitaet < 1 then
              Includis[I].Auftrag.Var_Kavitaet := 1;
            ueberprod := ( Includis[I].Auftrag.Sollwert  + Includis[I].Auftrag.SollwertOffset ) > Includis[I].Auftrag.Istwert;
            if Ende_Aus_Verpackt then
              ueberprod := ( Includis[I].Auftrag.Sollwert  + Includis[I].Auftrag.SollwertOffset ) > Includis[I].Auftrag.Verpackt;
            if ueberprod then
            begin
              if Variable_Kavitaet and not SpannzeitUeberwachen then
                cavFactor := Includis[I].Auftrag.Var_Kavitaet
              else
                cavFactor := 1;
              if not SpannzeitUeberwachen then
              begin
                if Ende_Aus_Isttakt_IstKav then
                begin
                  cavFactor := cavFactor / Includis[I].Kopfgroesse;
                end
                else
                begin
                  if TCO_Setup.GetParamBool(Daten.qSuch, 'INCL_Restlaufzeit_Aus_AuftragsKav') then
                    cavFactor := cavFactor / Includis[I].Auftrag.Kopfgroesse
                  else
                    cavFactor := cavFactor / Includis[I].Kopfgroesse;
                end;
              end;

//              diffMenge := ( Includis[I].Auftrag.Sollwert + Includis[I].Auftrag.SollwertOffset );
              diffMenge :=  Includis[I].Auftrag.Sollwert;
              if Ende_Aus_Verpackt then
                diffMenge := diffMenge - Includis[I].Auftrag.Verpackt
              else
                diffMenge := diffMenge - Includis[I].Auftrag.Istwert;

              RemainTime := diffMenge * EndeTakt / 6000 * cavFactor;
            end
            else
              RemainTime := 0;
            EndeZeitpunkt := GetEndeDatumLizenz(Includis[I].Lizenz, Includis[I].Auftrag.BetriebsauftragNr, Jetzt, Trunc(RemainTime));

            if wartunginende then // Check ob Wartung um Zeitraum. Dann Endezeitpunkt ggf. mehrfach verlängern
            begin
              repeat
                SQLStr := 'SELECT * FROM wartung WHERE startdatumzeit < '+ FloatToStr(EndeZeitpunkt)
                  +  ' AND enddatumzeit > '+FloatToPunktString(EndeZeitpunkt) + ' AND stat = 0 AND lizenz = ''' + Lizenz + '''';
                SQL_Get(Daten.qSuch3, SQLStr);
                if not Daten.qSuch3.IsEmpty then
                begin
                  RemainTime := RemainTime + trunc((Daten.qSuch3.FieldByName('enddatumzeit').AsFloat - Daten.qSuch3.FieldByName('startdatumzeit').AsFloat)*1440);
                  EndeZeitpunkt := GetEndeDatumLizenz(Includis[I].Lizenz, Includis[I].Auftrag.BetriebsauftragNr, Now, Trunc(RemainTime));
                end;
              until (Daten.qSuch3.IsEmpty)
            end;
stage := 3;
            Includis[I].Auftrag.LTIST := EndeZeitpunkt;
            EndeDatum := DateTimeToStr(EndeZeitpunkt);

            Dauer := Trunc((EndeZeitpunkt - Includis[I].Auftrag.LTSOLL) * 60 * 24);
            if Dauer > StatusPlanDiff then
              StatStr := GetL('verspätet')
            else
              StatStr := GetL('OK');

            SQLStr := 'update PDE set '
              + ' EndDatumSTR =     ''' + EndeDatum
              + ''',EndDatumZeit =  ' + FloatToPunktString(EndeZeitpunkt)
              + ',Diff =          ''' + IntToStr(Dauer) + ' min';
            if not Includis[i].StueckzahlDirekt then
              SQLStr :=SQLStr  + ''',Istwert =       ''' + IntToStr(Includis[I].Auftrag.Istwert);
            SQLStr :=SQLStr  + ''',StatusDiff =    ''' + StatStr
              + ''' where (Lizenz = ''' + Includis[I].Lizenz + ''' AND stat = ''0'')'
              + IgnorePendingStatement;
            SQL_Insert(Daten.qUpdate, SQLStr);
          end
          else
            EndeDatum := ' ';
      end;
stage := 4;
      if Nach_Schichtwechsel then
      begin
        try
          //Set the database in order for the TPM-class to be properly re-initialized
//{$IF NOT INCLUDISDatabaseTyp = 1}
          S7Main.TPM.ReInit;
//{$IFEND}
        except on ex: Exception do
          SchreibeMeldung(ex.Message + ' on reinit of S7TPM', 0);
        end;
        if Ende_Aus_Isttakt or Ende_Aus_Isttakt_IstKav then
          EndeTakt := S7Main.S7_Auftrag.GetIstTakt(Includis[I].Lizenz)
        else
          EndeTakt := Includis[I].Auftrag.Solltakt;
        if EndeTakt < 10 then
          EndeTakt := Includis[I].Auftrag.Solltakt;

        if takt_aus_plan then
          if Includis[I].Auftrag.planzykluszeit > 0 then
            EndeTakt := Includis[I].Auftrag.planzykluszeit;
        EndeTakt := Round(EndeTakt * (1 + (Includis[I].Auftrag.ausschussquote / 10000)));

stage := 5;
        if SpannzeitUeberwachen then
          EndeTakt := EndeTakt + Round(Includis[I].Auftrag.SollSpannzeitStk * (1 + (Includis[I].SpannzeitToleranz /
            100)));

        if (Includis[I].Kopfgroesse <= 0) then
          Includis[I].Kopfgroesse := 1;
        if (Includis[I].Auftrag.Kopfgroesse <= 0) then
          Includis[I].Auftrag.Kopfgroesse := 1;
        if ( ( Includis[I].Auftrag.Sollwert + Includis[I].Auftrag.SollwertOffset ) > Includis[I].Auftrag.Istwert) then
        begin
          if Variable_Kavitaet and not SpannzeitUeberwachen then
            cavFactor := Includis[I].Auftrag.Var_Kavitaet
          else
            cavFactor := 1;
          if not SpannzeitUeberwachen then
          begin
            if Ende_Aus_Isttakt_IstKav then
            begin
              cavFactor := cavFactor / Includis[I].Kopfgroesse;
            end
            else
            begin
              if TCO_Setup.GetParamBool(Daten.qSuch, 'INCL_Restlaufzeit_Aus_AuftragsKav') then
                cavFactor := cavFactor / Includis[I].Auftrag.Kopfgroesse
              else
                cavFactor := cavFactor / Includis[I].Kopfgroesse;
            end;
          end;
stage := 6;

//          diffMenge := ( Includis[I].Auftrag.Sollwert + Includis[I].Auftrag.SollwertOffset );
          diffMenge := Includis[I].Auftrag.Sollwert;
          if Ende_Aus_Verpackt then
            diffMenge := diffMenge - Includis[I].Auftrag.Verpackt
          else
            diffMenge := diffMenge - Includis[I].Auftrag.Istwert;

          RemainTime := diffMenge * EndeTakt / 6000 * cavFactor;
        end
        else
          RemainTime := 0;

        EndeZeitpunkt := GetEndeDatumLizenz(Includis[I].Lizenz, Includis[I].Auftrag.BetriebsauftragNr, Jetzt, Trunc(RemainTime));
        
          if wartunginende then // Check ob Wartung um Zeitraum. Dann Endezeitpunkt ggf. mehrfach verlängern
            begin
              repeat
                SQLStr := 'SELECT * FROM wartung WHERE startdatumzeit < '+ FloatToStr(EndeZeitpunkt)
                  +  ' AND enddatumzeit > '+FloatToPunktString(EndeZeitpunkt) + ' AND stat = 0 AND lizenz = ''' + Lizenz + '''';
                SQL_Get(Daten.qSuch3, SQLStr);
                if not Daten.qSuch3.IsEmpty then
                begin
                  RemainTime := RemainTime + trunc((Daten.qSuch3.FieldByName('enddatumzeit').AsFloat - Daten.qSuch3.FieldByName('startdatumzeit').AsFloat)*1440);
                  EndeZeitpunkt := GetEndeDatumLizenz(Includis[I].Lizenz, Includis[I].Auftrag.BetriebsauftragNr, Now, Trunc(RemainTime));
                end;
              until (Daten.qSuch3.IsEmpty)
            end;

        Includis[I].Auftrag.LTIST := EndeZeitpunkt;
        EndeDatum := DateTimeToStr(EndeZeitpunkt);
stage := 7;

        Dauer := Trunc((EndeZeitpunkt - Includis[I].Auftrag.LTSOLL) * 60 * 24);
        if Dauer > StatusPlanDiff then
          StatStr := GetL('verspätet')
        else
          StatStr := GetL('OK');

        if Includis[I].MusternAktiv then
        begin
         SQLStr := 'update PDE set'
            + ' EndDatumSTR =         ''' + EndeDatum
            + ''', EndDatumZeit =     ' + FloatToPunktString(EndeZeitpunkt)
            + ', Diff =             ''' + IntToStr(Dauer) + GetL(' min')
            + ''', Istwert = 0 '
            + ', MusternStueck =          ''' + IntToStr(Includis[I].Auftrag.Istwert)
            + ''', StatusDiff =       ''' + StatStr
            + ''' where (Lizenz = ''' + Includis[I].Lizenz + ''' AND stat = ''0'')'
            + IgnorePendingStatement;
          SQL_Insert(Daten.qUpdate, SQLStr);
        end
        else
        begin
          SQLStr := 'update PDE set'
            + ' EndDatumSTR =         ''' + EndeDatum
            + ''', EndDatumZeit =     ' + FloatToPunktString(EndeZeitpunkt)
            + ', Diff =             ''' + IntToStr(Dauer) + GetL(' min')
            + ''', Istwert =          ''' + IntToStr(Includis[I].Auftrag.Istwert)
            + ''', StatusDiff =       ''' + StatStr
            + ''' where (Lizenz = ''' + Includis[I].Lizenz + ''' AND stat = ''0'')'
            + IgnorePendingStatement;
          SQL_Insert(Daten.qUpdate, SQLStr);
        end;
      end;

    except
      SchreibeMeldung('Reason: Write data -> calculation of end date', 0);
    end;
stage := 8;

    AnzJob := '0';
    //AnzJob:= InttoStr(SQLGet(Daten.qSuch,BDA_Tabelle,'Lizenz',Includis[i].Lizenz,True));

    if Includis[I].Maschine = '' then
      AnzJob := '0';

    if (Includis[I].Zustand = MaschRuesten) then
    begin
      Stueck := GetL('Rüsten');
      Istwert_PRZ := ' ';
    end
    else
    begin
      Stueck := IntToStr(Includis[I].Auftrag.Istwert);
      Istwert_PRZ := IntToStr(Includis[I].Auftrag.Ist_PRZ) + ' %';
    end;

    Daten.qUpdate.Close;
    Daten.qUpdate.SQL.Clear;

    if EndeDatum = '' then
      EndeDatum := ' ';
    if Length(EndeDatum) > 24 then
      EndeDatum := ' ';
stage := 9;

    if EndeDatum = ' ' then
      EndeDatum := DateTimeToStr(N_o_w);
    try
      EndeDT := StrToDateTime(EndeDatum);
    except
      EndeDT := N_o_w;
    end;
    if Includis[I].Auftrag.StartDatum > 10000 then
      StartDatumStr := DateTimeToStr(Includis[I].Auftrag.StartDatum)
    else
      StartDatumStr := '';

    Reststandzeit := 0;
    if werkzeugverwaltung then
    begin
      //Reststandzeit ermitteln
      if SQLGetBool(Daten.qSuch, 'Werkzeug', 'WerkzeugNr', Includis[I].Auftrag.WerkzeugNr) then
        Reststandzeit := Daten.qSuch.FieldByName('ISTSTANDZEITINT').AsInteger
      else
        Reststandzeit := 0;
    end;

    if Reststandzeit < 0 then
      Reststandzeit := 0;

    CO_Meldung := 0;
stage := 10;

    ZustandInt := Includis[I].Zustand;
    StillAktual := '';
    if Includis[I].Zustand = 2 then
    begin
      StillListObject := COTPM_Stillstaende.GetOpenByMaschNr(I);
      if (StillListObject <> nil) then
      begin
        StillAktual := StillListObject.Stillstand;
        StillNr := StillListObject.GrundNr;
        if StillListObject.Geplant then
          ZustandInt := 5;
        if StillNr = 3 then
          ZustandInt := 6;
        if StillListObject.Gruppe = 1 then
          ZustandInt := 1;
      end;
      {
    // Hole den der geht = 0 and
      SQLStr := 'select tpm_stillstaende.stillstand, tpm_stillstaende.StillstandNr,'
        + ' tpm_stillstaende.geplant, tpm_stillstaende.Gruppe'
        + ' from tpm_stillstaende,'
        + 'tpm_stillog where tpm_stillog.maschnr = ''' + Includis[I].MaschNr
        + '''  and geht = 0 and tpm_stillstaende.StillstandNr = tpm_stillog.StillstandNr';
      SQL_Get(Daten.qSuch, SQLStr);
      StillAktual := Daten.qSuch.FieldByName('Stillstand').AsString;
      StillNr := Daten.qSuch.FieldByName('StillstandNr').AsInteger;
      if Daten.qSuch.FieldByName('geplant').AsInteger = 1 then
        ZustandInt := 5;
      if Daten.qSuch.FieldByName('StillstandNr').AsInteger = 3 then
        ZustandInt := 6;
      if Daten.qSuch.FieldByName('Gruppe').AsInteger = 1 then
        ZustandInt := 1;
        }
    end;
stage := 11;

    if Includis[I].Maschine_geblockt then
    begin //RP BLOCKSTILL
      ZustandInt := 7;
      ZustandStr := GetL('geblockt');
    end;

    Daten.qSuch.Close;
    if Includis[I].Auftrag.Packgroesse > 0 then
      SollKartons := Round( ( Includis[I].Auftrag.Sollwert + Includis[I].Auftrag.SollwertOffset ) / Includis[I].Auftrag.Packgroesse)
    else
      SollKartons := 0;

    if Includis[I].Auftrag.BetriebsauftragNr = '' then
    begin
      AUTOAUSSCHUSS_AUFTRAG[I].Istwert := 0;
      AUTOAUSSCHUSS_AUFTRAGSchicht[I].Istwert := 0;
    end;

    if Includis[I].Auftrag.Packgroesse > 0 then
      VerpacktKartons := Round(Includis[I].StueckPackAuftragGesamt / Includis[I].Auftrag.Packgroesse)
    else
      VerpacktKartons := 0;

    // wenn Tabelle Maschinf über anderen SQL Befehl festgehalten wird, kann hier gewartet werden
    Waitcnt := 0;
    tmp_Stueck := Includis[I].Auftrag.Istwert;
    tmp_prz :=  Includis[I].Auftrag.Ist_PRZ;
    if (Includis[I].Zustand = 1) and TCO_Setup.GetParamBool(Daten.qsuch, 'INCL_ZeroProducedMaschinfDuringSetup') then
    begin
      tmp_Stueck := 0;
      tmp_prz := 0;
    end;
	
    repeat
//      if not SQLGetBool(Daten.qSuch, 'Maschinf', 'Maschine', Includis[I].Maschine) then
      if not LizenzList.IndexOf(Includis[i].Maschine) > -1 then
      begin
        Sleep(500);
        inc(waitcnt);
      end
      else
      begin
        waitcnt := 10;
      end;
    until waitcnt > 3;

    if TCO_Setup.GetParamBool(Daten.qSuch, 'INCL_RemainTime_Gross') then
      RemainTime :=  (EndeDT - N_o_w) * 1440;
stage := 12;

    // Schleife wurde beenden. wenn Eintrag gefunden dann waitcnt = 10, sonst kleiner.
    if waitcnt = 10 then // SQLGet(Daten.qSuch, 'Maschinf', 'Maschine', Includis[I].Maschine, True) > 0 then
    begin
      SQLStr := 'update Maschinf set '
        + 'DatumZeit =            ' + FloatToPunktString(real_t)
        + ',KURZKENNUNG =       ''' + Includis[I].KURZKENNUNG
        + ''',Betriebsstunden =   ''' + IntToStr(Includis[I].Betriebsstunden)
        + ''',Taktzeit =          ''' + IntToStr(Includis[I].IstTakt)
        + ''',Taktzeit_Str =      ''' + FloatToStrF2(Includis[I].IstTakt / 1000, ffFixed, 10, 2)
        + ''',Solltakt =          ''' + IntToStr(Includis[I].Solltakt)
        + ''',Solltakt_Str =      ''' + FloatToStrF2(Includis[I].Solltakt / 100, ffFixed, 10, 2)
        + ''',StueckSchicht =     ''' + IntToStr(Includis[I].StueckSchicht)
        + ''',PackSchicht =       ''' + IntToStr(Includis[I].StueckPackSchicht)
        + ''',Pruefschicht =      ''' + IntToStr(Includis[I].StueckPruefSchicht)
        + ''',Verfuegbarkeit =    ''' + FloatToStrF2(Includis[I].Nutzung, ffFixed, 10, 2)
        + ''',Leistung =          ''' + FloatToStrF2(Includis[I].Leistung, ffFixed, 10, 2)
        + ''',Qualitaet =         ''' + FloatToStrF2(Includis[I].Qualitaet, ffFixed, 10, 2)
        + ''',Effektivitaet =     ''' + FloatToStrF2(Includis[I].Effektivitaet, ffFixed, 10, 2)
        + ''',Bezeichnung =       ''' + Includis[I].Auftrag.Bezeichnung
        + ''',InterBezeichnung =  ''' + Includis[I].Auftrag.InterBezeichnung
        + ''',ArtikelNr =         ''' + Includis[I].Auftrag.AuftragNr
        + ''',BetriebsAuftragNr = ''' + Includis[I].Auftrag.BetriebsauftragNr
        + ''',Sollwert =          ''' + IntToStr(Includis[I].Auftrag.Sollwert)
        + ''',SollwertOffset =          ''' + IntToStr(Includis[I].Auftrag.SollwertOffset);
      if Includis[i].MusternAktiv then
      begin
        SQLStr := SQLStr + ''',Stueck = ''0'', Mustern=1, '
          + ' MusternStueck =            ''' + IntToStr(tmp_stueck)
          + ''',Istwert_PRZ =       ''0 %';
          if ZustandInt = 1 then
            SQLStr := SQLStr + ''',ZustandInt =        ''' + IntToStr(1)
              + ''',Zustand =           ''' + GetL('Mustern/Rüsten')
          else
            SQLStr := SQLStr + ''',ZustandInt =        ''' + IntToStr(12)
              + ''',Zustand =           ''' + GetL('Mustern') ;
      end
      else
      begin
        SQLStr := SQLStr + ''', Mustern=0, Stueck =            ''' + IntToStr(tmp_stueck)
          + ''',Istwert_PRZ =       ''' + IntToStr(tmp_prz) + ' %'
          + ''',Zustand =           ''' + ZustandStr
          + ''',ZustandInt =        ''' + IntToStr(ZustandInt)
      end;

      SQLStr := SQLStr + ''',stat =              ''' + IntToStr(Includis[I].Auftrag.Stat)
        + ''',Programm_Nr =       ''' + IntToStr(Includis[I].Auftrag.Programm_Nr)
        + ''',InPause =           ''' + IntToStr(Includis[I].Auftrag.InPause)
        + ''',Var_Kavitaet =      ''' + IntToStr(Includis[I].Auftrag.Var_Kavitaet)
        + ''',Kavitaet =          ''' + IntToStr(Includis[I].Auftrag.Kopfgroesse)
        + ''',KAVITAET_SOLL =     ''' + IntToStr(Includis[I].Auftrag.KAVITAET_SOLL)
        + ''',Einheit =           ''' + Includis[I].Einheit
        + ''',Ausschuss =         ''' + IntToStr(Includis[I].Auftrag.Ausschuss
        + (GetAusschussSPSKavitaet(AUTOAUSSCHUSS_AUFTRAG[I].Istwert, Includis[I].Auftrag.Kopfgroesse)))
        + ''',Pruef =             ''' + IntToStr(Includis[I].StueckPruefAuftragGesamt);
      if Verpackt_aus_Ausschuss then
      begin
      if not VerpacktProtAusSchichtausschuss then
//      if not TCO_Setup.GetParamBool(Daten.qSuch3, 'INCL_VerpacktProt_aus_Schichtausschuss') then
//        SQLStr :=SQLStr + ''', Pack = ''' + Daten.qSuch.FieldByName('Pack').AsString ;
        SQLStr :=SQLStr + ''', Pack = ''' + IntToStr(Includis[I].StueckPackAuftragGesamt);
      end;
      SQLStr :=SQLStr + ''',Schwesterauftrag =  ''' + Includis[I].Auftrag.Schwesterauftrag
        + ''',Form =              ''' + Includis[I].Auftrag.Form
        + ''',EndeDatum =         ''' + EndeDatum
        + ''',StartDatum =        ''' + StartDatumStr

        + ''',EndDatumZeit =      ' + FloatToPunktString(INCLUDIS[i].Auftrag.EndeDatum)
        + ',StartDatumZeit =    ' + FloatToPunktString(INCLUDIS[i].Auftrag.StartDatum)

        + ',SAUftrag =          ''0'
        + ''',MaschNrInt =        ''' + Includis[I].MaschNrEcht
        + ''',Stillstand_Grund =  ''' + StillAktual
        + ''',StillstandNr =      ''' + IntToStr(StillNr)
        + ''',Werkzeug =          ''' + Includis[I].Auftrag.WerkzeugNr
        + ''',RestStandZeit =     ''' + IntToStr(Reststandzeit)
        + ''',LTSOLL =            ' + FloatToPunktString(Includis[I].Auftrag.LTSOLL)
        + ',LTIST =             ' + FloatToPunktString(Includis[I].Auftrag.LTIST)
        + ',LT1 =               ' + FloatToPunktString(Includis[I].Auftrag.LT1)
        + ',LT2 =               ' + FloatToPunktString(Includis[I].Auftrag.LT2)
        + ',KARTONS =           ''' + IntToStr(Includis[I].KARTONS)
        + ''',PALETTEN =          ''' + IntToStr(Includis[I].PALETTEN)
        + ''',PACKGROESSE =       ''' + IntToStr(Includis[I].Auftrag.Packgroesse)
        + ''',PALETTENGROESSE =   ''' + IntToStr(Includis[I].Auftrag.PALETTENGROESSE)
        + ''',SOLLKARTONS =       ''' + IntToStr(SollKartons)
        + ''',VERPACKTKARTONS =   ''' + IntToStr(VerpacktKartons)
        + ''',Optimiert =         ''' + IntToStr(Includis[I].Auftrag.Optimiert)
        + ''',Extruder =         ''' + IntToStr(Extruderan[I])
        + ''',Kunde =            ''' + Includis[I].Auftrag.Kunde
        + ''',RemainTime =        ''' + IntToStr(Trunc(RemainTime))
        + ''' where (Maschine = ''' + Includis[I].Maschine + ''')'
        + IgnorePendingStatement;
      SQL_Insert(Daten.qUpdate, SQLStr);
    end
    else
    begin
      SQLStr := 'INSERT INTO Maschinf (Nr, Lizenz, MaschNr,'
        + ' MaschNrInt, KURZKENNUNG, SORT_MASCHPANEL, Maschine, DatumZeit, Zustand, ZustandInt, Betriebsstunden,'
        + ' Taktzeit, StueckSchicht, PackSchicht, Pruefschicht, AnzJob, Verfuegbarkeit,'
        + ' Leistung, Qualitaet, Effektivitaet, Bezeichnung, InterBezeichnung, ArtikelNr,'
        + ' BetriebsauftragNr, SAuftrag, Schwesterauftrag, Form, Sollwert, SollwertOffset, Istwert_PRZ,'
        + ' stat, Programm_Nr, Stueck, Einheit, Ausschuss, Pruef, Pack, Kavitaet,KAVITAET_SOLL,'
        + ' InPause, StartDatum, EndeDatum, Optimiert, LTSOLL, LTIST, LT1, LT2, SollKartons, VErpacktKartons)'
        + ' VALUES(MASCHINFID.NextVal'
        + ',''' + Includis[I].Lizenz
        + ''',''' + Includis[I].MaschNr
        + ''',''' + Includis[I].MaschNrEcht
        + ''',''' + Includis[I].KURZKENNUNG
        + ''',''' + IntToStr(Includis[I].SORT_MASCHPANEL)
        + ''',''' + Includis[I].Maschine
        + ''',' + FloatToPunktString(Jetzt)
        + ',''' + ZustandStr
        + ''',''' + IntToStr(ZustandInt)
        + ''',''' + IntToStr(Includis[I].Betriebsstunden)
        + ''',''' + IntToStr(Includis[I].IstTakt)
        + ''',''' + IntToStr(Includis[I].StueckSchicht)
        + ''',''' + IntToStr(Includis[I].StueckPackSchicht)
        + ''',''' + IntToStr(Includis[I].StueckPruefSchicht)
        + ''',''' + AnzJob
        + ''',''' + FloatToStrF2(Includis[I].Nutzung, ffFixed, 10, 2)
        + ''',''' + FloatToStrF2(Includis[I].Leistung, ffFixed, 10, 2)
        + ''',''' + FloatToStrF2(Includis[I].Qualitaet, ffFixed, 10, 2)
        + ''',''' + FloatToStrF2(Includis[I].Effektivitaet, ffFixed, 10, 2)
        + ''',''' + Includis[I].Auftrag.Bezeichnung
        + ''',''' + Includis[I].Auftrag.InterBezeichnung
        + ''',''' + Includis[I].Auftrag.AuftragNr
        + ''',''' + Includis[I].Auftrag.BetriebsauftragNr
        + ''',''0'
        + ''',''' + Includis[I].Auftrag.Schwesterauftrag
        + ''',''' + Includis[I].Auftrag.Form
        + ''',''' + IntToStr(Includis[I].Auftrag.Sollwert)
        + ''',''' + IntToStr(Includis[I].Auftrag.SollwertOffset)
        + ''',''' + IntToStr(tmp_prz) + ' %'
        + ''',''' + IntToStr(Includis[I].Auftrag.Stat)
        + ''',''' + IntToStr(Includis[I].Auftrag.Programm_Nr);
      if Includis[i].MusternAktiv then
      begin
        SQLStr := SQLStr + ''', ''0';
      end
      else
      begin
        SQLStr := SQLStr + ''',''' + IntToStr(tmp_stueck);
      end;
        SQLStr := SQLStr + ''',''' + Includis[I].Einheit
        + ''',''' + IntToStr(Includis[I].Auftrag.Ausschuss
        + (GetAusschussSPSKavitaet(AUTOAUSSCHUSS_AUFTRAG[I].Istwert, Includis[I].Auftrag.Kopfgroesse)))
        + ''',''' + IntToStr(Includis[I].StueckPruefAuftragGesamt)
        + ''',''' + IntToStr(Includis[I].StueckPackAuftragGesamt)
        + ''',''' + IntToStr(Includis[I].Auftrag.Kopfgroesse)
        + ''',''' + IntToStr(Includis[I].Auftrag.KAVITAET_SOLL)
        + ''',''' + IntToStr(Includis[I].Auftrag.InPause)
        + ''',''' + StartDatumStr
        + ''',''' + EndeDatum
        + ''',''' + IntToStr(Includis[I].Auftrag.Optimiert)
        + ''',' + FloatToPunktString(Includis[I].Auftrag.LTSOLL)
        + ',' + FloatToPunktString(Includis[I].Auftrag.LTIST)
        + ',' + FloatToPunktString(Includis[I].Auftrag.LT1)
        + ',' + FloatToPunktString(Includis[I].Auftrag.LT2)
        + ',''' + IntToStr(SollKartons)
        + ''',''' + IntToStr(VerpacktKartons)
        + ''')';
        SQL_Insert(Daten.qUpdate, SQLStr);
      end;
stage := 13;

    // Für Unterauftrag mit aktualisieren
          SQLStr := 'update Maschinf set '
        + 'DatumZeit =            ''' + FloatToStr2(real_t)
        + ''',Zustand =           ''' + ZustandStr
        + ''',ZustandInt =        ''' + IntToStr(ZustandInt)
        + ''',KURZKENNUNG =       ''' + Includis[I].KURZKENNUNG
        + ''',Betriebsstunden =   ''' + IntToStr(Includis[I].Betriebsstunden)
        + ''',Taktzeit =          ''' + IntToStr(Includis[I].IstTakt)
        + ''',Taktzeit_Str =      ''' + FloatToStrF2(Includis[I].IstTakt / 1000, ffFixed, 10, 2)
        + ''',Solltakt =          ''' + IntToStr(Includis[I].Solltakt)
        + ''',Solltakt_Str =      ''' + FloatToStrF2(Includis[I].Solltakt / 100, ffFixed, 10, 2)
        + ''',Verfuegbarkeit =    ''' + FloatToStrF2(Includis[I].Nutzung, ffFixed, 10, 2)
        + ''',Leistung =          ''' + FloatToStrF2(Includis[I].Leistung, ffFixed, 10, 2)
        + ''',Qualitaet =         ''' + FloatToStrF2(Includis[I].Qualitaet, ffFixed, 10, 2)
        + ''',Effektivitaet =     ''' + FloatToStrF2(Includis[I].Effektivitaet, ffFixed, 10, 2)
        + ''',stat =              ''' + IntToStr(Includis[I].Auftrag.Stat)
        + ''',Programm_Nr =       ''' + IntToStr(Includis[I].Auftrag.Programm_Nr)
        + ''',InPause =           ''' + IntToStr(Includis[I].Auftrag.InPause)
        + ''',Var_Kavitaet =      ''' + IntToStr(Includis[I].Auftrag.Var_Kavitaet)
//        + ''',Kavitaet =          ''' + IntToStr(Includis[I].Auftrag.Kopfgroesse)
//        + ''',KAVITAET_SOLL =     ''' + IntToStr(Includis[I].Auftrag.KAVITAET_SOLL)
        + ''',Einheit =           ''' + Includis[I].Einheit
        + ''',Schwesterauftrag =  ''' + Includis[I].Auftrag.Schwesterauftrag
        + ''',Form =              ''' + Includis[I].Auftrag.Form
        + ''',EndeDatum =         ''' + EndeDatum
        + ''',StartDatum =        ''' + StartDatumStr
        + ''',EndDatumZeit =      ' + FloatToPunktString(INCLUDIS[i].Auftrag.EndeDatum)
        + ',StartDatumZeit =      ' + FloatToPunktString(INCLUDIS[i].Auftrag.StartDatum)
        + ',SAUftrag =            ''0'
        + ''',MaschNrInt =        ''' + Includis[I].MaschNrEcht
        + ''',Stillstand_Grund =  ''' + StillAktual
        + ''',StillstandNr =      ''' + IntToStr(StillNr)
        + ''',Werkzeug =          ''' + Includis[I].Auftrag.WerkzeugNr
        + ''',RestStandZeit =     ''' + IntToStr(Reststandzeit)
        + ''',LTSOLL =            ' + FloatToPunktString(Includis[I].Auftrag.LTSOLL)
        + ',LTIST =             ' + FloatToPunktString(Includis[I].Auftrag.LTIST)
        + ',LT1 =               ' + FloatToPunktString(Includis[I].Auftrag.LT1)
        + ',LT2 =               ' + FloatToPunktString(Includis[I].Auftrag.LT2)
        + ',KARTONS =           ''' + IntToStr(Includis[I].KARTONS)
        + ''',PALETTEN =          ''' + IntToStr(Includis[I].PALETTEN)
        + ''',PACKGROESSE =       ''' + IntToStr(Includis[I].Auftrag.Packgroesse)
        + ''',PALETTENGROESSE =   ''' + IntToStr(Includis[I].Auftrag.PALETTENGROESSE)
        + ''',SOLLKARTONS =       ''' + IntToStr(SollKartons)
        + ''',VERPACKTKARTONS =   ''' + IntToStr(VerpacktKartons)
        + ''',Optimiert =         ''' + IntToStr(Includis[I].Auftrag.Optimiert)
        + ''',Extruder =         ''' + IntToStr(Extruderan[I])
        + ''',Kunde =            ''' + Includis[I].Auftrag.Kunde
        + ''',RemainTime =        ''' + IntToStr(Trunc(RemainTime))
        + ''' where (Maschine = ''' + Includis[I].Maschine + ' W2'')'
        + IgnorePendingStatement;
    SQL_Insert(Daten.qUpdate, SQLStr);

stage := 14;
 // Gleich noch in Musterprot eintragen.
    if Includis[i].MusternAktiv then
    begin
      if ZustandInt <> 1 then
      begin
        tmp_musternstueck := tmp_stueck;
        SQLStr := 'UPDATE musternprot SET produziert = ' + IntToStr(tmp_stueck)
          + ' - (SELECT CASE WHEN SUM(produziert) IS NULL THEN 0 ELSE SUM(produziert) END FROM musternprot '
          + ' WHERE betriebsauftragnr = ''' + Includis[I].Auftrag.BetriebsauftragNr + ''' AND enddatumzeit > 1)'
          + ' WHERE betriebsauftragnr = ''' + Includis[I].Auftrag.BetriebsauftragNr + ''' AND enddatumzeit < 1';
        SQL_Insert(Daten.qUpdate, SQLStr);
        SQLStr := 'UPDATE musternprot SET produziert_gesamt_auftrag = '
          + '(SELECT SUM(produziert) FROM musternprot '
          + ' WHERE betriebsauftragnr = ''' + Includis[I].Auftrag.BetriebsauftragNr + ''')'
          + ' WHERE betriebsauftragnr = ''' + Includis[I].Auftrag.BetriebsauftragNr + '''';
        SQL_Insert(Daten.qUpdate, SQLStr);
      end;
    end;

    if TCO_Setup.GetParamBool(Daten.qUpdate, 'INCL_Verpackt_manuell_autom') then
    begin
      SQLStr := 'UPDATE maschinf SET MaBuStueck = (SELECT sum(zugang - abgang) '
        + '+ (maschinf.stueck - MAX(maschinenzaehler)) FROM verpacktprot WHERE betriebsauftragnr = '''
        + Includis[I].Auftrag.BetriebsauftragNr + ''') , MaBuKartons = ROUND((SELECT sum(zugang - abgang) '
        + '+ (maschinf.stueck - MAX(maschinenzaehler)) FROM verpacktprot WHERE betriebsauftragnr = '''
        + Includis[I].Auftrag.BetriebsauftragNr + ''') / maschinf.packgroesse) WHERE betriebsauftragnr = '''
        + Includis[I].Auftrag.BetriebsauftragNr + '''';
      SQL_Insert(Daten.qUpdate, SQLStr);
    end;

    if isunicode then
    begin
      if SQLGet(Daten.qSuch, 'PDESTAMM_UNICODE', 'Auftragnr', Includis[I].Auftrag.AuftragNr, true) > 0 then
      begin
        SQLStr := 'UPDATE maschinf SET Bezeichnung = '
              + ' (     SELECT bezeichnung '
              + '       FROM PDESTAMM_UNICODE'
              + '       WHERE PDESTAMM_UNICODE.auftragnr = maschinf.Artikelnr)'
                + ' WHERE maschinf.Artikelnr = ''' + Includis[I].Auftrag.AuftragNr + '''';
        SQL_Insert(Daten.qUpdate, SQLStr )
      end;
    end;

    if KavitaetFromSPS then
    begin

    end;
stage := 15;

    if SpannzeitUeberwachen then
    begin // Aktualisieren von PDE, Maschinf, AARCHIV
      Includis[I].IstSpannzeitStk := SpannzeitAktuell[I].Istwert;
      Includis[I].IstSpannzeitGes := SpannzeitSumme[I].Istwert;

      SQL_Insert(Daten.qUpdate, 'UPDATE maschinf SET '
        + ' SOLLSPANNZEITSTK = ' + IntToStr(Includis[I].Auftrag.SollSpannzeitStk) + ', '
        + ' ISTSPANNZEITSTK = ' + IntToStr(Includis[I].IstSpannzeitStk)
        + ' WHERE Maschine = ''' + Includis[I].Maschine + '''');
      SQL_Insert(Daten.qUpdate, 'UPDATE PDE SET '
        + ' SOLLSPANNZEITSTK = ' + IntToStr(Includis[I].Auftrag.SollSpannzeitStk) + ', '
        + ' ISTSPANNZEITSTK = ' + IntToStr(Includis[I].IstSpannzeitStk) + ', '
        + ' SOLLSPANNZEITGES = ' + IntToStr(Includis[I].Auftrag.SollSpannzeitGes) + ', '
        + ' ISTSPANNZEITGES = ' + IntToStr(Includis[I].IstSpannzeitGes)
        + ' WHERE BetriebsauftragNr = ''' + Includis[I].Auftrag.BetriebsauftragNr + '''');
      SQL_Insert(Daten.qUpdate, 'UPDATE AARCHIV SET '
        + ' SOLLSPANNZEITSTK = ' + IntToStr(Includis[I].Auftrag.SollSpannzeitStk) + ', '
        + ' ISTSPANNZEITSTK = ' + IntToStr(Includis[I].IstSpannzeitStk) + ', '
        + ' SOLLSPANNZEITGES = ' + IntToStr(Includis[I].Auftrag.SollSpannzeitGes) + ', '
        + ' ISTSPANNZEITGES = ' + IntToStr(Includis[I].IstSpannzeitGes)
        + ' WHERE BetriebsauftragNr = ''' + Includis[I].Auftrag.BetriebsauftragNr + '''');
    end;

    if Heizungskontrolle then
    begin
      SQLGet(Daten.qSuch, 'Maschinf', 'Maschine', Includis[I].Maschine, False);
      heizungmeldungan := Daten.qSuch.FieldByName('heating').AsInteger = 1;

      if Heizungsdauer[I].Istwert = 0 then
        SQL_Insert(Daten.qUpdate, 'UPDATE maschinf SET heatingstart = 0, heating = 0 '
          + ' WHERE Maschine = ''' + Includis[I].Maschine + ''' AND heating = 0');
stage := 16;

      SQL_Insert(Daten.qUpdate, 'UPDATE maschinf SET heatingstd = ' + IntToStr(Heizungsoll[I])
        + ' WHERE Maschine = ''' + Includis[I].Maschine + '''');

      if (Heizungsdauer[I].Istwert > 0) then
        SQL_Insert(Daten.qUpdate, 'UPDATE maschinf SET heatingstart = ''' + FloatToStr2(N_o_w - (Heizungsdauer[I].Istwert
          / 1440)) + ''' '
          + ' WHERE Maschine = ''' + Includis[I].Maschine + '''');

      if (Heizungsoll[I] < Heizungsdauer[I].Istwert) and (not heizungmeldungan) then
      begin
        CCC_Erzeuge_Arbeitsplan(Includis[I].Lizenz, Includis[I].MaschNr, GetL('HEIZUNG'),
          IntToStr(Heizungsoll[I]) + GetL(' Min.'), GetL('Heizung ist noch angeschaltet'), ' ', False, ' ', True,
          True);
        SQL_Insert(Daten.qUpdate, 'UPDATE maschinf SET heating =1 '
          + ' WHERE Maschine = ''' + Includis[I].Maschine + '''');
        // Protokoll Eintrag erzeugen
        SQL_Insert(Daten.qUpdate, 'INSERT INTO heatinglog (nr, maschnr, startdatumzeit, enddatumzeit) '
         + ' VALUES (heatinglogid.nextval, ''' + Includis[I].MaschNr + ''', ' + FloatToPunktString(Now) + ', 0)');
      end;

      if (Heizungsoll[I] >= Heizungsdauer[I].Istwert) and (heizungmeldungan) then
      begin
        SQL_Insert(Daten.qUpdate, 'UPDATE maschinf SET heating=0, heatingstart =0 '
          + ' WHERE Maschine = ''' + Includis[I].Maschine + '''');
          SQL_Insert(Daten.qUpdate, 'UPDATE heatinglog SET enddatumzeit= ' + FloatToPunktString(Now) + ' WHERE '
            + ' maschnr = ''' + Includis[I].MaschNr + ''' AND enddatumzeit=0');
        // Protokoll schließen wenn offen
      end;
    end;

    SQL_Get(Daten.qUpdate, 'select Sum(Zugang-Abgang) CNT from VerpacktProt where BetriebsAuftragNr = '''
      + Includis[I].Auftrag.BetriebsauftragNr + '''');
    try
      Prod := Daten.qUpdate.FieldByName('CNT').AsInteger;
    except
      Prod := 0;
    end;
stage := 17;

    SQL_Insert(Daten.qUpdate, 'update maschinf set pack= ' + IntToStr(Prod) + ' where betriebsauftragnr='''
      + Includis[I].Auftrag.BetriebsauftragNr + '''');

    try
      if barcodepzewerkstatt then
      begin
        // Holen der Leute, die Im Bereich von Schichtanfang bis jetzt angemeldet waren.
(*
        SQLStr := 'SELECT b.name name, b.personalnr '
          + ' FROM pze_werkstatt pw, bediener b WHERE (geht >= '''
          + FloatToStr2(TTT_GetTPMSchichtZeit(Includis[I].Schicht, Jetzt))
          + ''' OR geht = 0 ) AND maschnr=' + Includis[I].MaschNr
          + ' AND b.personalnr=pw.personalnr ORDER BY kommt';
          *)
          // Nur aktuell angemeldetes Personal anzeigen
        SQLStr := 'SELECT b.name name, b.personalnr '
          + ' FROM pze_werkstatt pw, bediener b WHERE geht = 0  AND maschnr='
          + Includis[I].MaschNr
          + ' AND b.personalnr=pw.personalnr ORDER BY kommt';

stage := 18;
        SQL_Get(Daten.qUpdate, SQLStr);
        if not Daten.qUpdate.IsEmpty then
        begin
          Personal := Daten.qUpdate.FieldByName('name').AsString;

          SQLStr := 'UPDATE maschinf SET personalnr = '''
            + Daten.qUpdate.FieldByName('personalnr').AsString + ''', personal = '''
            + Personal + ' ';

          SQL_Get(Daten.qUpdate, 'SELECT count(distinct(b.personalnr)) cnt'
            + ' FROM pze_werkstatt pw, bediener b WHERE (geht >= '''
            + FloatToStr2(TTT_GetTPMSchichtZeit(Includis[I].Schicht, Jetzt))
            + ''' OR geht = 0 ) AND maschnr=' + Includis[I].MaschNr
            + ' AND b.personalnr=pw.personalnr');

          if Daten.qUpdate.FieldByName('cnt').AsInteger > 1 then
            SQLStr := SQLStr + '(' + Daten.qUpdate.FieldByName('cnt').AsString + ')';
          SQLStr := SQLStr + ''' WHERE (Maschine = ''' + Includis[I].Maschine + ''')';
          SQL_Insert(Daten.qUpdate, SQLStr);
        end
        else
        begin // wenn niemand angeldet ist, dann auch keinen anzeigen
          SQLStr := 'UPDATE maschinf SET personalnr = '''' , personal = '''' '
            + ' WHERE (Maschine = ''' + Includis[I].Maschine + ''')';
          SQL_Insert(Daten.qUpdate, SQLStr);
        end;
      end;
    except
    end;
stage := 19;

    // *****************************************************************
    //  AuftragArchiv aktualisieren:
    //******************************************************************

    if (Includis[I].Zustand = 1) and Anfahr_Ausschuss2 then
      begin
        SQLStr := 'update AArchiv set'
          + ' Anfahr_Ausschuss = ''' + IntToStr(Includis[I].Auftrag.Istwert)
          + ''' where Betriebsauftragnr = ''' + Includis[I].Auftrag.BetriebsauftragNr + '''';
        SQL_Insert(Daten.qUpdate, SQLStr);

        SQLStr := 'update PDE set'
          + ' Anfahr_Ausschuss = ''' + IntToStr(Includis[I].Auftrag.Istwert)
          + ''' where Betriebsauftragnr = ''' + Includis[I].Auftrag.BetriebsauftragNr + '''';
        SQL_Insert(Daten.qUpdate, SQLStr);


      end;
    if Includis[I].Auftrag.Istwert > 0 then
    begin
      (*if (Includis[I].Zustand = 1) and Anfahr_Ausschuss2 then
      begin
        SQLStr := 'update AArchiv set'
          + ' Anfahr_Ausschuss = ''' + IntToStr(Includis[I].Auftrag.Istwert)
          + ''' where Betriebsauftragnr = ''' + Includis[I].Auftrag.BetriebsauftragNr + '''';
        SQL_Insert(Daten.qUpdate, SQLStr);

        SQLStr := 'update PDE set'
          + ' Anfahr_Ausschuss = ''' + IntToStr(Includis[I].Auftrag.Istwert)
          + ''' where Betriebsauftragnr = ''' + Includis[I].Auftrag.BetriebsauftragNr + '''';
        SQL_Insert(Daten.qUpdate, SQLStr);


      end
      else  *)
stage := 20;
      if not((Includis[I].Zustand = 1) and Anfahr_Ausschuss2) then
      begin
        SQLStr := 'update AArchiv set '
          + ' Geprueft = ' + IntToStr(Includis[I].StueckPruefAuftragGesamt) + ' ' ;
        if Includis[i].MusternAktiv then
        begin
          if not Includis[i].StueckzahlDirekt then
            SQLStr :=  SQLStr +   ', ProduziertINT = 0,  MusternStueck=' + IntToStr(Includis[I].Auftrag.Istwert);
          SQLStr :=  SQLStr  + ', Zyklen = ' + IntToStr(Includis[i].ZyklenAuftragGesamt)
            + ', ProduziertSTR = 0 '
            + ',AusschussPRZ = 0';
        end
        else
        begin
          if not Includis[i].StueckzahlDirekt then
            SQLStr :=  SQLStr +   ', ProduziertINT = ' + IntToStr(Includis[I].Auftrag.Istwert);
          SQLStr :=  SQLStr  + ', Zyklen = ' + IntToStr(Includis[i].ZyklenAuftragGesamt)
            + ', ProduziertSTR = ''' + IntToStr(Includis[I].Auftrag.Istwert)
            + ''',AusschussPRZ = ''' + IntToStr(Round(100 / Includis[I].Auftrag.Istwert
            * (Includis[I].Auftrag.Istwert - Includis[I].StueckPackAuftragGesamt))) + '''';
        end;

        SQLStr := SQLStr + ' where Betriebsauftragnr = ''' + Includis[I].Auftrag.BetriebsauftragNr + ''''
                  + IgnorePendingStatement;
        SQL_Insert(Daten.qUpdate, SQLStr);

        SQLStr := 'update PDE set'
          + ' Pruef = ' + IntToStr(Includis[I].StueckPruefAuftragGesamt) + ' ';

        if not Includis[i].MusternAktiv then
        begin
          if not Includis[i].StueckzahlDirekt then
            SQLStr :=  SQLStr + ', istwert = ''' + IntToStr(Includis[I].Auftrag.Istwert) + '''';
        end
        else
        begin
            SQLStr :=  SQLStr + ', istwert = 0, MusternStueck=''' + IntToStr(Includis[I].Auftrag.Istwert) + '''';
        end;


        SQLStr :=  SQLStr + ',StueckSchicht = ''' + IntToStr(Includis[I].Auftrag.StueckSchicht)
          + ''' where Betriebsauftragnr = ''' + Includis[I].Auftrag.BetriebsauftragNr + ''' AND stat IN (0,1)'
          + IgnorePendingStatement;
        SQL_Insert(Daten.qUpdate, SQLStr);

        if Includis[I].Auftrag.MasterAuftrag then
        begin
          SQLStr := 'select pk.*, a.startdatumzeit'
                   + ' FROM PDEKombi pk'
                   + ' LEFT JOIN aarchiv a ON a.betriebsauftragnr = pk.betriebsauftragnr'
                   + ' WHERE pk.MasterBetriebsAuftragNr = ''' + Includis[I].Auftrag.BetriebsauftragNr
            + '''';
          SQL_Get(Daten.qSuch, SQLStr);
          while not Daten.qSuch.EOF do
          begin
            if not(Includis[i].KombiSeparat and Includis[i].GutVonBus) then
            begin
              if Includis[i].MusternAktiv then
              begin
                SQLStr := 'update AArchiv set '
                  + 'ProduziertINT = 0, ProduziertSTR = 0, MusternStueck = ''' + Daten.qSuch.FieldByName('Istwert').AsString
                  + ''' where Betriebsauftragnr = ''' + Daten.qSuch.FieldByName('BetriebsAuftragNr').AsString + ''''
                  + IgnorePendingStatement;
              end
              else
              begin
                SQLStr := 'update AArchiv set '
                  + 'ProduziertINT = ''' + Daten.qSuch.FieldByName('Istwert').AsString
                  + ''',ProduziertSTR = ''' + Daten.qSuch.FieldByName('Istwert').AsString
                  + ''' where Betriebsauftragnr = ''' + Daten.qSuch.FieldByName('BetriebsAuftragNr').AsString + ''''
                  + IgnorePendingStatement;
              end;
                SQL_Insert(Daten.qUpdate, SQLStr);
            end;

            try
              if SQLGet(Daten.qSuch2, 'maschinf', 'BetriebsAuftragNr', Daten.qSuch.FieldByName('BetriebsAuftragNr').AsString, true) < 1 then
              begin
                SQLStr := 'insert Into MaschInf ('
                        + 'Nr, Lizenz, DatumZeit, Maschine,MaschNr,MaschNrInt, ZUSTAND, ZUSTANDINT, Taktzeit,'
                        + ' Sollwert, ISTWERT_PRZ, STUECK,PACK,STUECKSCHICHT,PACKSCHICHT,PRUEFSCHICHT,PRUEF,'
                        + ' LTSOLL, LTIST, Stat, ArtikelNr,'
                        + ' BetriebsAuftragNr, Bezeichnung, AUSSCHUSS,'
                        + ' Werkzeug, WERKZEUG_NR,'
                        + ' TAKTZEIT_STR) values (MaschinfId.NextVal,'
                        + ' ''' + Includis[I].Maschine + MASCHBEZ_UNTERAUFTRAG + ''','
                        + FloatToPunktString(Daten.qSuch.FieldByName('startDatumzeit').AsFloat) + ',' //FloatToPunktString(StartDatumZeit) + ','
                        + ' ''' + Includis[I].Maschine + MASCHBEZ_UNTERAUFTRAG + ''','
                        + ' ''' + Includis[I].MaschNr + ''','
                        + ' ''' + Includis[I].MaschNr + ''','
                        + ' ''' + GetL('offline') + ''','
                        + ' ''3'','
                        + ' ''' + IntToStr(0) + ''','
                        + ' ''' + Daten.qSuch.FieldByName('Sollwert').AsString + ''','
                        + ' ''' + IntToStr(0) + ' %'','
                        + ' ''' + IntToStr(0) + ''',' //STUECK
                      + ' ''' + IntToStr(0) + ''',' //PACK
                      + ' ''' + IntToStr(0) + ''','
                        + ' ''' + IntToStr(0) + ''','
                        + ' ''' + IntToStr(0) + ''','
                        + ' ''' + IntToStr(0) + ''','
                        + ' ''' + IntToStr(0) + ''','
                        + ' ''' + IntToStr(0) + ''','
                        + ' ''' + IntToStr(0) + ''','
                        + ' ''' + Daten.qSuch.FieldByName('AuftragNr').AsString + ''','
                        + ' ''' + Daten.qSuch.FieldByName('BetriebsAuftragNr').AsString + ''','
                        + ' ''' + Daten.qSuch.FieldByName('Bezeichnung').AsString + ''','
                        + ' ''0'','
                        + ' ''0'','
                        + ' ''0'','
                        + ' ''0'')';
                      try
                        SQL_Insert(Daten.qUpdate, SQLStr);
                      except on e: Exception do
                        SchreibeMeldung(e.Message + ' on inserting missing detail job in maschinf with ''' + SQLStr + '''', 0);
                      end;

              end;
            except  on e: Exception do
              SchreibeMeldung(e.MEssage + ' on checking missing detail jobs in maschinf', 0);
            end;
            Daten.qSuch.Next;
          end;
        end;
      end;
    end;
stage := 21;

    (*
    //**************************************************************************
    //  PDEStatistik schreiben
    //**************************************************************************
    //wenn Datensatz vorhanden, dann löschen...
    //if Not(Includis[i].HandAuto AND (Includis[i].Schicht = 3) and Halbautomatik) then begin
    if False then
    begin
      //
      //    if  (Includis[i].Auftrag.Stat = stLaeuftInt) then begin
      //         SQLSTR:= 'Select * from '+ PDE_Statistik_Tabelle +' where (Lizenz ='''+ Includis[i].Lizenz +''') AND(Schicht ='''+ InttoStr(Includis[i].Schicht) +''')AND(Datum ='''+ DatetoStr(Datum) +''')';
      //         SQLCountSTR:= 'Select COUNT(* ) CNT from '+ PDE_Statistik_Tabelle +' where (Lizenz ='''+ Includis[i].Lizenz +''') AND(Schicht ='''+ InttoStr(Includis[i].Schicht) +''')AND(Datum ='''+ DatetoStr(Datum) +''')';
      //      end
      // else  begin
      if Includis[I].Auftrag.BetriebsauftragNr <> '' then
      begin
        SQLCountSTR := 'Select COUNT(* ) CNT from PDESTAT where (Lizenz =''' + Includis[I].Lizenz
          + ''') AND(Schicht =''' + IntToStr(Includis[I].Schicht) + ''')AND(Datum ='''
          + DateToStrSQL(Jetzt) + ''') AND (Betriebsauftragnr ='''
          + Includis[I].Auftrag.BetriebsauftragNr + ''')';
        SQLStr := 'Select * from PDESTAT where (Lizenz =''' + Includis[I].Lizenz
          + ''') AND(Schicht =''' + IntToStr(Includis[I].Schicht) + ''') AND (Datum ='''
          + DateToStrSQL(Jetzt) + ''')AND(Betriebsauftragnr ='''
          + Includis[I].Auftrag.BetriebsauftragNr + ''')';
      end
      else
      begin
        SQLCountSTR := 'Select COUNT(* ) CNT from PDESTAT where (Lizenz ='''
          + Includis[I].Lizenz + ''') AND(Schicht =''' + IntToStr(Includis[I].Schicht)
          + ''') AND (Datum =''' + DateToStrSQL(Jetzt) + ''')AND(Bezeichnung ='''
          + Includis[I].Auftrag.Bezeichnung + ''')';
        SQLStr := 'Select * from PDESTAT where (Lizenz =''' + Includis[I].Lizenz
          + ''') AND (Schicht =''' + IntToStr(Includis[I].Schicht) + ''')AND(Datum ='''
          + DateToStrSQL(Trunc(Jetzt)) + ''')AND(Bezeichnung ='''
          + Includis[I].Auftrag.Bezeichnung + ''')';
      end;
      Daten.qSuch.Close;
      Daten.qCount.Close;
      SQL_Get(Daten.qSuch, SQLStr);
//      SQL_Get(Daten.qCount, SQLCountSTR);
      if not Daten.qSuch.IsEmpty then // (Daten.qCount.FieldByName('CNT').AsInteger > 0) then
      begin
        Daten.qSuch.Last;
        Nummer := Daten.qSuch.FieldByName('Nr').AsInteger;
        Daten.qUpdate.Close;
        DeleteSQL(Daten.qUpdate, 'PDESTAT', 'Nr', IntToStr(Nummer));
      end;

      SQLStr := 'INSERT INTO PDESTAT (Nr,Lizenz,Datum,Zeit,DatumSTR,DatumZeit,Schicht,AuftragNr,BetriebsAuftragNr,'
        + 'Bezeichnung,Produziert,geprueft,verpackt,ausschuss,ProduziertInt,geprueftInt,verpacktInt,ausschussInt)'
        + 'VALUES(PDESTATID.NextVal'
        + ',''' + Includis[I].Lizenz
        + ''',''' + DateToStr(Trunc(Jetzt))
        + ''',''' + TimeToStr(ZeitSchicht)
        + ''',''' + DateToStr(Jetzt)
        + ''',''' + FloatToStr2(Jetzt)
        + ''',''' + IntToStr(Includis[I].Schicht)
        + ''',''' + Includis[I].Auftrag.AuftragNr
        + ''',''' + Includis[I].Auftrag.BetriebsauftragNr
        + ''',''' + Includis[I].Auftrag.Bezeichnung
        + ''',''' + IntToStr(Includis[I].StueckAuftragSchicht)
        + ''',''' + IntToStr(Includis[I].StueckPruefAuftragSchicht)
        + ''',''' + IntToStr(Includis[I].StueckPackAuftragSchicht)
        + ''',''' + IntToStr(Includis[I].AusschussAuftragSchicht)
        + ''',''' + IntToStr(Includis[I].StueckAuftragSchicht)
        + ''',''' + IntToStr(Includis[I].StueckPruefAuftragSchicht)
        + ''',''' + IntToStr(Includis[I].StueckPackAuftragSchicht)
        + ''',''' + IntToStr(Includis[I].AusschussSchicht)
        + ''')';
      SQL_Insert(Daten.qUpdate, SQLStr);
    end;
    *)
    //**************************************************************************
    //  Verpackte pro Schicht berechnen
    //**************************************************************************
    if VerpacktInSchichtProt then
    begin
      SQLStr := 'select Sum(Zugang-Abgang) as CNT from VerpacktProt'
        + ' where datum >= ' + FloatToPunktString(S7Main.TPM.VonDatum)
        + ' and datum < ' + FloatToPunktString(S7Main.TPM.BisDatum)
        + ' and Maschine = ''' + Includis[I].Lizenz + ''''
        + ' and betriebsauftragnr = ''' + Includis[I].Auftrag.BetriebsauftragNr + '''';
      SQL_Get(Daten.qSuch, SQLStr);
      Includis[I].StueckPackAuftragSchicht := Daten.qSuch.FieldByName('CNT').AsInteger;
    end;

    //**************************************************************************
    //  TPMStatistik schreiben
    //**************************************************************************
    //wenn Datensatz vorhanden, dann löschen...
    if not (Includis[I].HandAuto and (Includis[I].Schicht = 3) and halbautomatik) then
    begin
      if not Metall then
      begin
        Erstellungsdatum := TTT_GetTPMSchichtZeit(Includis[I].Schicht, Jetzt);

        SQLCountSTR := 'Select COUNT(* ) CNT from tpm_schicht where (maschnr ='
          + Includis[I].MaschNr + ') AND (Schicht =' + IntToStr(Includis[I].Schicht)
          + ') AND (Datum =''' + DateToStrSQL(TTT_GetTPMSchichtDatum(Includis[I].Schicht, Jetzt)) + ''')';
        SQLStr := 'Select * from tpm_schicht where (maschnr ='
          + Includis[I].MaschNr + ') AND (Schicht =' + IntToStr(Includis[I].Schicht)
          + ') AND (Datum =''' + DateToStrSQL(TTT_GetTPMSchichtDatum(Includis[I].Schicht, Jetzt))
          + ''') order by nr DESC';

stage := 22;
        SQL_Get(Daten.qSuch, SQLStr);
       // SQL_Get(Daten.qCount, SQLCountSTR);
        Nummer := 0;
        Ausschuss := 0;
        tmp_Produziert := -1;
        if not Daten.qSuch.IsEmpty then // .qCount.FieldByName('CNT').AsInteger > 0 then
        begin
          while not Daten.qSuch.Eof do
          begin
            Erstellungsdatum := Jetzt;
            if Daten.qSuch.FieldByName('Betriebsauftragnr').AsString = Includis[I].Auftrag.BetriebsauftragNr then
            begin
              Nummer := Daten.qSuch.FieldByName('Nr').AsInteger;
              Erstellungsdatum := GFloat(Daten.qSuch.FieldByName('Erstellungsdatum').AsString);
              tmp_Produziert := Daten.qSuch.FieldByName('Produziert').AsInteger;

              if SQL_Get(Daten.qCount, 'select * from tpm_stillog where (stillstandnr = 2) and (geht = 0) AND (MaschNr = '''
                + Includis[I].MaschNr + ''')') then
                Erstellungsdatum := Daten.qCount.FieldByName('Kommt').AsFloat - 0.00001;
              if Erstellungsdatum < 36000 then
                Erstellungsdatum := Daten.qSuch.FieldByName('datumZeit').AsFloat;
              if Erstellungsdatum < 36000 then
                Erstellungsdatum := Jetzt;
              Ausschuss := Daten.qSuch.FieldByName('Ausschuss').AsInteger;

              //            if (Includis[I].Auftrag.Stat <> stStartRuestenInt) then
              //              Includis[I].Auftrag.Anfahrausschuss := Daten.qSuch.FieldByName('Anfahrausschuss').AsInteger;
              Daten.qUpdate.Close;
              break;
            end
            else
              Daten.qSuch.Next
          end;
        end;
      end
      else
      begin //if NOT Metall then begin
        //Metall
        Erstellungsdatum := Jetzt;
        tmp_Produziert := -1;
        if Includis[I].Auftrag.BetriebsauftragNr <> '' then
        begin
          SQLCountSTR := 'Select COUNT(* ) CNT from tpm_schicht where Betriebsauftragnr = '''
            + Includis[I].Auftrag.BetriebsauftragNr + ''' AND (maschnr ='''
            + Includis[I].MaschNr + ''') AND(Schicht =''' + IntToStr(Includis[I].Schicht)
            + ''')AND(Datum =''' + DateToStrSQL(TTT_GetTPMSchichtDatum(Includis[I].Schicht, Jetzt)) + ''')';
          SQLStr := 'Select * from tpm_schicht where Betriebsauftragnr = '''
            + Includis[I].Auftrag.BetriebsauftragNr + ''' AND (maschnr ='''
            + Includis[I].MaschNr + ''') AND(Schicht =''' + IntToStr(Includis[I].Schicht)
            + ''')AND(Datum =''' + DateToStrSQL(TTT_GetTPMSchichtDatum(Includis[I].Schicht, Jetzt))
            + ''') order by nr';
        end
        else
        begin
          SQLCountSTR := 'Select COUNT(* ) CNT from tpm_schicht where Betriebsauftragnr is NULL AND (maschnr ='''
            + Includis[I].MaschNr + ''') AND(Schicht =''' + IntToStr(Includis[I].Schicht)
            + ''')AND(Datum =''' + DateToStrSQL(TTT_GetTPMSchichtDatum(Includis[I].Schicht, Jetzt))
            + ''')';
          SQLStr := 'Select * from tpm_schicht where Betriebsauftragnr is NULL AND (maschnr ='''
            + Includis[I].MaschNr + ''') AND(Schicht =''' + IntToStr(Includis[I].Schicht)
            + ''')AND(Datum =''' + DateToStrSQL(TTT_GetTPMSchichtDatum(Includis[I].Schicht, Jetzt))
            + ''') order by nr';
        end;
        SQL_Get(Daten.qSuch, SQLStr);
     //   SQL_Get(Daten.qCount, SQLCountSTR);
        Nummer := 0;
        Ausschuss := 0;
        if not Daten.qSuch.IsEmpty then // Daten Daten.qCount.FieldByName('CNT').AsInteger > 0 then
        begin
          Nummer := Daten.qSuch.FieldByName('Nr').AsInteger;
          Erstellungsdatum := Daten.qSuch.FieldByName('Erstellungsdatum').AsFloat;
          if SQL_Get(Daten.qCount, 'select * from tpm_stillog where (stillstandnr = 2) and (geht = 0)'
              + ' AND (MaschNr =''' + Includis[I].MaschNr + ''')') then
            Erstellungsdatum := GFloat(Daten.qCount.FieldByName('Kommt').AsString) - 0.00001;
          if Erstellungsdatum < 36000 then
            Erstellungsdatum := Daten.qSuch.FieldByName('datumZeit').AsFloat;
          if Erstellungsdatum < 36000 then
            Erstellungsdatum := Jetzt;
          Ausschuss := Daten.qSuch.FieldByName('Ausschuss').AsInteger;
          Daten.qUpdate.Close;
        end;
      end;
stage := 23;
      optimiert_schicht := 0;
      if Includis[I].Auftrag.BetriebsauftragNr <> '' then
      begin
        DT := TTT_GetTPMSchichtDatum(Includis[I].Schicht, Jetzt);
//        SchichtDauer
        SQLStr := 'Select Sum(Menge) as CNT from Ausschuss_Prot where BetriebsAuftragNr = '''
          + Includis[I].Auftrag.BetriebsauftragNr + ''''
          + ' and DatumZeit between (' + FloatToPunktString(DT) + ') and (' + FloatToPunktString(DT + SchichtDauer / 1440) + ')';//1 / 3) + ')';
        SQL_Get(Daten.qSuch, SQLStr);
        try
          Ausschuss := Daten.qSuch.FieldByName('CNT').AsInteger;
        except
          Ausschuss := 0;
        end;

        if Includis[I].Auftrag.ImStatusOptimieren = 1 then
        begin
          SQLStr := ' SELECT sum(optimiertstk) sumopt FROM tpm_schicht WHERE nr <> '
            + ' (SELECT MAX(nr) FROM tpm_schicht WHERE betriebsauftragnr = ''' + Includis[I].Auftrag.BetriebsauftragNr +
            ''' )'
            + ' AND betriebsauftragnr = ''' + Includis[I].Auftrag.BetriebsauftragNr + '''';
          SQL_Get(Daten.qSuch, SQLStr);
          try
            optimiert_schicht := Daten.qSuch.FieldByName('sumopt').AsInteger;
          except
          end;

          Includis[I].Auftrag.Optimiert := optimiert_schicht;

          SQLStr := 'SELECT SUM(istwert) sumist FROM optimierungsprot WHERE betriebsauftragnr = '''
            + Includis[I].Auftrag.BetriebsauftragNr + '''';
          SQL_Get(Daten.qSuch, SQLStr);
          try
            optimiert_schicht := Daten.qSuch.FieldByName('sumist').AsInteger - optimiert_schicht;
          except
            optimiert_schicht := 0;
          end;
          optimiert_schicht := optimiert_schicht +
            ((StueckAuftragGesamt[I].Istwert * Includis[I].Auftrag.Kopfgroesse)
            - Includis[I].Auftrag.OptimiertAktuell) + 1;
          // Wenn Optimierung anliegt, dann ist Stückzahl in Opt Prot -1, daher +1
          Includis[I].Auftrag.Optimiert := Includis[I].Auftrag.Optimiert + optimiert_schicht;
        end
        else
        begin
          SQLStr := 'SELECT SUM(CAST(istwert AS integer)) sumist FROM optimierungsprot WHERE betriebsauftragnr = '''
            + Includis[I].Auftrag.BetriebsauftragNr + '''';
          SQL_Get(Daten.qSuch, SQLStr);
          try
            optimiert_schicht := Daten.qSuch.FieldByName('sumist').AsInteger;
          except
            optimiert_schicht := 0;
          end;

          Includis[I].Auftrag.Optimiert := optimiert_schicht;

          SQLStr := ' SELECT sum(optimiertstk) sumopt FROM tpm_schicht WHERE nr <> '
            + ' (SELECT MAX(nr) FROM tpm_schicht WHERE betriebsauftragnr = ''' + Includis[I].Auftrag.BetriebsauftragNr +
            ''' )'
            + ' AND betriebsauftragnr = ''' + Includis[I].Auftrag.BetriebsauftragNr + '''';
          SQL_Get(Daten.qSuch, SQLStr);
          try
            optimiert_schicht := optimiert_schicht - Daten.qSuch.FieldByName('sumopt').AsInteger;
          except
          end;
        end;

        SQLStr := 'UPDATE maschinf SET optimiert = ' + IntToStr(Includis[I].Auftrag.Optimiert)
          + ' WHERE lizenz in (''' + Includis[I].Lizenz + ''', ''' + Includis[I].Lizenz + ' W2'')';
        SQL_Insert(Daten.qUpdate, SQLStr);

      end;
stage := 24;
      S7Main.TPM.VonDatum := CCC_GetTPMSchichtAnfang(Includis[I].Schicht, Jetzt);

      S7Main.TPM.BisDatum := Jetzt;
      S7Main.TPM.Zeitraum := 0;
      S7Main.TPM.Schicht := Includis[I].Schicht;
      S7Main.TPM.MaschNr := StrToInt(Includis[I].MaschNr);
      S7Main.TPM.AlleMaschinen := False;
      SchichtDauer := GetSchichtDauer(Includis[I].Schicht);

      if S7Main.TPM.CalculateCached(COTPM_Stillstaende) = 1 then
    //  if S7Main.TPM.Calculate(false) = 1 then

      begin
        OEE_Stops := S7Main.TPM.Stops;
        OEE_Anlagenausfall := S7Main.TPM.Anlagenausfall;
        OEE_Ruesten := S7Main.TPM.Ruesten;
        OEE_Logistik := S7Main.TPM.Logistik;
        OEE_Nichtgebucht := S7Main.TPM.NichtGebucht;

        if OEE_Anlagenausfall > SchichtDauer then
          OEE_Anlagenausfall := SchichtDauer;
        if OEE_Ruesten > SchichtDauer then
          OEE_Ruesten := SchichtDauer;
        if OEE_Logistik > SchichtDauer then
          OEE_Logistik := SchichtDauer;
        if OEE_Nichtgebucht > SchichtDauer then
          OEE_Nichtgebucht := SchichtDauer;

        OEE_Sollaufzeit := S7Main.TPM.Solllaufzeit;
        OEE_Istlaufzeit := S7Main.TPM.IstLaufZeit;

        OEE_Geplant := S7Main.TPM.Geplant;
        OEE_Ungeplant := S7Main.TPM.Ungeplant;

        if OEE_Geplant > SchichtDauer then
          OEE_Geplant := SchichtDauer;
        if OEE_Ungeplant > SchichtDauer then
          OEE_Ungeplant := SchichtDauer;

        if OEE_Sollaufzeit < 0 then
          OEE_Sollaufzeit := 0;
        if OEE_Sollaufzeit > SchichtDauer then
          OEE_Sollaufzeit := SchichtDauer;

        if OEE_Istlaufzeit < 0 then
          OEE_Istlaufzeit := 0;
        if OEE_Istlaufzeit > OEE_Sollaufzeit then
          OEE_Istlaufzeit := OEE_Sollaufzeit;

        if OEE_Sollaufzeit <> 0 then
        begin
          OEE_Nutzung := (OEE_Istlaufzeit / OEE_Sollaufzeit) * 100;
        end
        else
        begin
          OEE_Nutzung := (OEE_Istlaufzeit / 1) * 100;
        end;

stage := 25;
        //RS 16.06.2015: Kavitätswechsel werden bei der Leistung sauber berücksichtigt, indem tpm_schicht.zyklen herangezogen wird. Dann muss auch Var_Kavitaet nicht mehr berücksichtigt werden
        if Kavitaet_laufender_Auftrag3 then
        begin
          if OEE_Istlaufzeit <> 0 then
            OEE_Leistung := ((Includis[I].Auftrag.Solltakt * 0.01)
              * Includis[I].ZyklenAuftragSchicht / (OEE_Istlaufzeit * 60)) * 100
          else
            OEE_Leistung := ((Includis[I].Auftrag.Solltakt * 0.01)
              * Includis[I].ZyklenAuftragSchicht / (1 * 60 )) * 100;
        end
        else
        begin
          if OEE_Istlaufzeit <> 0 then
          begin
            if Variable_Kavitaet then
              OEE_Leistung := ((Includis[I].Auftrag.Solltakt * 0.01)
                * Includis[I].StueckAuftragSchicht / (OEE_Istlaufzeit * 60
                * Includis[I].Auftrag.Kopfgroesse / Includis[I].Auftrag.Var_Kavitaet)) * 100
            else
              OEE_Leistung := ((Includis[I].Auftrag.Solltakt * 0.01)
                * Includis[I].StueckAuftragSchicht / (OEE_Istlaufzeit * 60
                * Includis[I].Auftrag.Kopfgroesse)) * 100;
          end
          else
            OEE_Leistung := ((Includis[I].Auftrag.Solltakt * 0.01)
              * Includis[I].StueckAuftragSchicht / (1 * 60 * Includis[I].Auftrag.Kopfgroesse)) * 100;
        end;

        tmp_Stueck := Includis[I].StueckAuftragSchicht;
        
        // Wenn kein Auftrag, dann keine Stückzahlen ML 18.10.17
        if Includis[I].Auftrag.BetriebsauftragNr = '' then
          tmp_stueck := 0;
stage := 25;

        if Nummer <> 0 then
        begin
          // Wenn manuelle Maschine, Produziert lesen und benutzen
          try
            if ( Includis[I].MaschinenTyp > 0 ) and ( Includis[I].Auftrag.BetriebsauftragNr <> '' ) then
            begin
              //SQLStr := 'SELECT produziert FROM tpm_schicht WHERE nr = ' + IntToStr(Nummer);
              SQLStr := 'SELECT SUM(menge)  produziert'
                      + ' FROM BUCHUNGSPROT'
                      + ' WHERE BETRIEBSAUFTRAGNR = ''' + Includis[I].Auftrag.BetriebsauftragNr + ''''
                      + ' AND datum > ' + FloatToPunktString(TTT_GetTPMSchichtZeit(Includis[I].Schicht, Jetzt));
              SQL_Get(Daten.qUpdate, SQLStr);
              tmp_Stueck := Daten.qUpdate.FieldByName('produziert').AsInteger;
              Includis[I].StueckAuftragSchicht := tmp_Stueck;
              Includis[I].Auftrag.StueckSchicht := tmp_Stueck;
              Includis[I].StueckPackAuftragSchicht := tmp_Stueck;
              Daten.qUpdate.Close;
            end;
          except
          end;
          //    DeleteSQL(Daten.qUpdate, 'TPM_Schicht', 'Nr', IntToStr(Nummer));
        end;

        // Schichtlaufzeit vom Auftrag berechnen
        SQLStr := 'SELECT MAX(auftragstart) startdt FROM laufzeitlog WHERE betriebsauftragnr = '''
          + Includis[I].Auftrag.BetriebsauftragNr + '''';
        SQL_Get(Daten.qUpdate, SQLStr);
        if not Daten.qUpdate.IsEmpty then
          Includis[I].Auftrag.StartDatum := Daten.qUpdate.FieldByName('startdt').AsFloat
        else
          Includis[I].Auftrag.StartDatum := 0;

stage := 26;
          (*   Ersetzt durch cached Liste ML 29.02.2016
        SQLStr := 'SELECT ROUND(SUM('
          + ' CASE WHEN geht = 0  THEN ' + FloatToPunktString(Jetzt) + ' ELSE geht END - '
          + 'CASE WHEN kommt < '
          + FloatToPunktString(MAX(Includis[I].Auftrag.StartDatum, Schichtstart))
          + ' THEN ' + FloatToPunktString(MAX(Includis[I].Auftrag.StartDatum, Schichtstart))
          + ' ELSE kommt END) * 1440) summe '
          + ' FROM tpm_stillog WHERE maschnr = ' + IntToStr(Includis[I].Datenblock)
          + ' AND (geht > ' + FloatToPunktString(MAX(Includis[I].Auftrag.StartDatum, Schichtstart))
          + ' OR geht = 0)';
        SQL_Get(Daten.qUpdate, SQLStr);

        Includis[I].Auftrag.SchichtLaufzeit := Round((Jetzt - MAX(Includis[I].Auftrag.StartDatum, Schichtstart)) * 1440)
          -
          Daten.qUpdate.FieldByName('summe').AsInteger;
*)
        Includis[I].Auftrag.SchichtLaufzeit := Round((Jetzt - MAX(Includis[I].Auftrag.StartDatum, Schichtstart)) * 1440)
        -
        COTPM_Stillstaende.GetDauerByMaschNrFromDate(MAX(Includis[I].Auftrag.StartDatum, Schichtstart), Includis[i].Datenblock);

stage := 27;
        if Includis[I].Auftrag.StartDatum = 0 then
          Includis[I].Auftrag.SchichtLaufzeit := 0;

        if Includis[I].Auftrag.Schwesterauftrag <> '' then
          tmp_Stueck := tmp_Stueck * 2;

        if tmp_Stueck > 0 then
          OEE_Qualitaet := (tmp_Stueck - Ausschuss) / tmp_Stueck * 100
        else
          OEE_Qualitaet := Includis[I].Qualitaet;

        if Metall then
          tmp_Stueck := Includis[I].Auftrag.StueckSchicht;

        if Includis[I].Auftrag.Solltakt = 0 then
          OEE_Leistung := 100;

        if OEE_Nutzung > Max_Nutzung then
          OEE_Nutzung := Max_Nutzung;
        if OEE_Leistung > Max_Leistung then
          OEE_Leistung := Max_Leistung;

        if OEE_Nutzung < 0 then
          OEE_Nutzung := 0;
        if OEE_Leistung < 0 then
          OEE_Leistung := 0;
        if OEE_Qualitaet < 0 then
          OEE_Qualitaet := 0;

        if OEE_Nutzung < 1 then
        begin
          OEE_Leistung := 0;
          OEE_Qualitaet := 0;
        end;

        OEE_Effektivitaet := OEE_Nutzung * OEE_Leistung * OEE_Qualitaet / 10000;

stage := 28;
        Includis[I].Nutzung := OEE_Nutzung;
        Includis[I].Leistung := OEE_Leistung;
        Includis[I].Qualitaet := OEE_Qualitaet;
        Includis[I].Effektivitaet := OEE_Effektivitaet;

        if (not Includis[I].MaschAktiv) or ((OEE_Istlaufzeit = 0) and (tmp_Stueck > 0)) then
        begin
          if Includis[I].MaschinenTyp <> 1 then
          begin
            OEE_Stops := 0;
            OEE_Anlagenausfall := 0;
            OEE_Ruesten := 0;
            OEE_Logistik := 0;
            OEE_Nichtgebucht := 0;
            OEE_Sollaufzeit := 0;
            OEE_Istlaufzeit := 0;
            OEE_Geplant := 0;
            OEE_Ungeplant := 0;
            OEE_Nutzung := 0;
            OEE_Leistung := 0;
            OEE_Qualitaet := 0;
            OEE_Effektivitaet := 0;

            Includis[I].Nutzung := OEE_Nutzung;
            Includis[I].Leistung := OEE_Leistung;
            Includis[I].Qualitaet := OEE_Qualitaet;
            Includis[I].Effektivitaet := OEE_Effektivitaet;
          end;

          if ( ( Includis[I].MaschinenTyp = 0 ) and (not SchichtMengenAuchOhneLaufzeit) ) then
            tmp_Stueck := 0;

        end;

        if Verpackt_aus_Ausschuss then
          Includis[I].StueckPackAuftragSchicht := Includis[I].StueckAuftragSchicht
            - Ausschuss;

        // Nachgucken ob Isttakt pro Schicht ermittelt werden soll
        // Sascha. 16.12.2008.
        // Frage: Warum Isttaktzeit pro Auftrag = Isttaktzeit für die letzte Schicht?

        SQLStr := 'SELECT AVG(TAKTZEIT) AS TAKT from Taktzeiten where Lizenz = '''
          + Includis[I].Lizenz + ''' AND datumzeit > '
          + FloatToPunktString(S7Main.TPM.VonDatum) + ' AND datumzeit < '
          + FloatToPunktString(S7Main.TPM.BisDatum);
        SQL_Get(Daten.qUpdate, SQLStr);
        TaktMittelSchicht := Daten.qUpdate.FieldByName('TAKT').AsFloat;

        if (TaktMittelSchicht = 0) and (Nummer > 0) then
        begin
          if SQLGetBool(Daten.qUpdate, 'TPM_Schicht', 'Nr', IntToStr(Nummer)) then
            TaktMittelSchicht := Daten.qUpdate.FieldByName('Isttakt').AsFloat;
          if Includis[I].Auftrag.BetriebsauftragNr <> '' then
          begin
            if (TaktMittelSchicht = 0) and (SQLGetBool(Daten.qUpdate, 'AArchiv', 'Betriebsauftragnr',
              Includis[I].Auftrag.BetriebsauftragNr)) then
              TaktMittelSchicht := Daten.qUpdate.FieldByName('taktzeitist').AsFloat / 100;
            if TaktMittelSchicht = 0 then
              TaktMittelSchicht := Includis[I].Auftrag.Solltakt / 100;
          end;
        end;

        TaktMittelAuftrag := TaktMittelSchicht;
        // Und nu mal richtig. TaktMittelSchicht ist die berechnete Taktzeit in der Schicht.
        if (Includis[I].Auftrag.SchichtLaufzeit > 0) and (Includis[I].Auftrag.BetriebsauftragNr <> '' )
          and (Includis[I].Zustand = 0) and (Includis[I].ZyklenAuftragSchicht > 0) then // Nur mit Auftrag und Laufzeit und laufend und produziert > 0
        begin
          taktzeitSchichtTmp := (Includis[I].Auftrag.SchichtLaufzeit * 60) / Includis[i].ZyklenAuftragSchicht;
          // Plausi ! Jetzt !
          // Abweichung Max 1/3 Solltakt bis 3 * Solltakt. Ansonsten alte Berechnung behalten
          taktzeitUpperTmp := (Includis[I].Auftrag.Solltakt / 100) * 3;
          taktzeitLowerTmp := (Includis[I].Auftrag.Solltakt / 100) / 3;
          if (taktzeitSchichtTmp > taktzeitLowerTmp) and (taktzeitSchichtTmp < taktzeitUpperTmp) then
          begin
            TaktMittelSchicht := taktzeitSchichtTmp;
          end;


          TaktMittelAuftrag := TaktMittelSchicht;
          if (Includis[i].Auftrag.GesamtLaufzeit > 0) and (Includis[i].Auftrag.BetriebsauftragNr = Includis[i].Auftrag.BaNrLaufzeit) then // Nur wenn der Aufrag läuft der auch eingelesen wurde
          begin
            taktzeitAuftragTmp := (Includis[i].Auftrag.GesamtLaufzeit * 60) / Includis[i].ZyklenAuftragGesamt;
            if (taktzeitAuftragTmp > taktzeitLowerTmp) and (taktzeitAuftragTmp < taktzeitUpperTmp) then
            begin
              TaktMittelAuftrag := taktzeitAuftragTmp;
            end;
          end;
        end;

stage := 28;
        SQLStr := 'UPDATE aarchiv SET '
          + ' taktzeitist = ''' + IntToStr(Trunc(TaktMittelAuftrag * 100)) + ''''
          + ' WHERE betriebsauftragnr= ''' + Includis[I].Auftrag.BetriebsauftragNr + '''';
        SQL_Insert(Daten.qUpdate, SQLStr);

        try
          SHIFT_TYP := TTT_GetSchichtTyp(Daten.qSuch4, StrToInt(Includis[I].MaschNr), Jetzt, 0); //Includis[I].Schicht);
        except
          SHIFT_TYP := '';
        end;

        if TCO_Setup.GetParamBool(Daten.qSuch4, 'INCL_Verpackt_nicht_Schicht_bezogen') then
        begin
          OEE_Qualitaet := 100;
          Includis[I].StueckPackAuftragSchicht := 0;
        end;

        if Includis[i].MusternAktiv then
        begin
          if ZustandInt <> 1 then
          begin
           // Differenz der Schichten ausrechnen
            SQLStr := 'SELECT SUM(musternstueck) musstk FROM tpm_schicht '
              + ' WHERE betriebsauftragnr = ''' + Includis[I].Auftrag.BetriebsauftragNr + ''' '
              + ' AND datumzeit < ' + FloatToPunktString(TTT_GetTPMSchichtZeit(Includis[I].Schicht, Jetzt) - 5/1440); // 5 Min vor akt Schicht
            SQL_Get(Daten.qSuch5, SQLStr);
            if not Daten.qSuch5.IsEmpty then
            begin
              tmp_musternstueck := tmp_musternstueck - daten.qSuch5.FieldByName('musstk').AsInteger;
            end;
          end
          else
          begin
            tmp_musternstueck := 0;
          end;
        end
        else
        begin
          tmp_musternstueck := 0;
        end;


        if Nummer = 0 then  // Kurz vor Schichtwechsel, muss einmalig ausgeführt werden
          if i = 1 then // Nur in erstem Durchgang testen
          begin
            if TCO_Setup.GetParamBool(Daten.qSuch4, 'INCL_VerpacktProt_aus_Schichtausschuss')  and
               not TCO_Setup.GetParamBool(Daten.qSuch4, 'INCL_VerpacktProt_aus_Aarchiv_und_AusschussProt', false) then
              VerpacktProtAusAusschussRechnen(Daten.qSuch, Daten.qSuch2, Daten.qUpdate, DBUser);
          end;

stage := 29;
        if Nummer = 0 then
        begin
          SQLStr := 'Insert into tpm_schicht (nr, maschnr, Datum, schicht, SHIFT_TYP, datumzeit,'
            + ' KW, Monat, nutzung, leistung, qualitaet, effektivitaet, BetriebsAuftragNr, AuftragNr,'
            + ' Bezeichnung,Personalzeit, produziert, produziert_org, geprueft, verpackt, verpackt_org, stops,'
            + ' anlagenausfall, ruesten, logistik,'
            + ' nichtgebucht, geplant, ungeplant, solLlaufzeit, istlaufzeit, solltakt, isttakt,'
            + ' Erstellungsdatum, Ausschuss, Kavitaet, kav_soll, Var_Kavitaet, Anfahrausschuss, Werkzeug,'
            + ' FORM, SPS_Stueck_Schicht, SPS_Schuss_Schicht, SPS_Stueck_Gesamt, '
            + ' SPS_Schuss_Gesamt, optimiertstk, AUTOAUSSCHUSS) values '
            + '(tpm_schichtID.Nextval'
            + ',''' + Includis[I].MaschNr
            + ''',''' + DateToStrSQL(TTT_GetTPMSchichtDatum(Includis[I].Schicht, Jetzt))
            + ''',''' + IntToStr(Includis[I].Schicht)
            + ''',''' + SHIFT_TYP
            + ''',' + FloatToPunktString(TTT_GetTPMSchichtZeit(Includis[I].Schicht, Jetzt))
            + ',''' + GetKWStr(Jetzt)
            + ''',''' + TTT_GetMonatStr(Jetzt)
            + ''',''' + FloatToStrF2(OEE_Nutzung, ffFixed, 10, 2)
            + ''',''' + FloatToStrF2(OEE_Leistung, ffFixed, 10, 2)
            + ''',''' + FloatToStrF2(OEE_Qualitaet, ffFixed, 10, 2)
            + ''',''' + FloatToStrF2(OEE_Effektivitaet, ffFixed, 10, 2)
            + ''',''' + Includis[I].Auftrag.BetriebsauftragNr
            + ''',''' + Includis[I].Auftrag.AuftragNr
            + ''',''' + Includis[I].Auftrag.Bezeichnung
            + ''',''' + FloatToStrF2(Includis[I].Auftrag.PersonalZeit, ffFixed, 10, 2);
           if Includis[i].MusternAktiv then
            SQLStr := SQLStr + ''',0,0'
           else
             SQLStr := SQLStr + ''',' + IntToStr(tmp_Stueck) //Feld PRODUZIERT
                + ',' + IntToStr(tmp_Stueck); //Feld PRODUZIERT

          SQLStr := SQLStr + ',''' + IntToStr(Includis[I].StueckPruefAuftragSchicht)
            + ''',''' + IntToStr(Includis[I].StueckPackAuftragSchicht)
            + ''',''' + IntToStr(Includis[I].StueckPackAuftragSchicht)
            + ''',''' + IntToStr(OEE_Stops) // Stops
          + ''',''' + IntToStr(OEE_Anlagenausfall) //Anlagenausfall
          + ''',''' + IntToStr(OEE_Ruesten) //Rüsten
          + ''',''' + IntToStr(OEE_Logistik) // Logistik
          + ''',''' + IntToStr(OEE_Nichtgebucht) //Nicht gebucht
          + ''',''' + IntToStr(OEE_Geplant) //Geplant
          + ''',''' + IntToStr(OEE_Ungeplant) //Ungeplant
          + ''',''' + IntToStr(OEE_Sollaufzeit) //Sollaufzeit
          + ''',''' + IntToStr(OEE_Istlaufzeit) //Istlaufzeit
          + ''',''' + FloatToStrF2(Includis[I].Auftrag.Solltakt / 100, ffFixed, 10, 2) // Solltakt
          + ''',''' + FloatToStrF2(TaktMittelSchicht, ffFixed, 10, 2) // Isttakt
          + ''',''' + FloatToStr2(Erstellungsdatum)
            + ''',''' + IntToStr(Ausschuss)
            + ''',''' + IntToStr(Includis[I].Auftrag.Kopfgroesse) // Kavität
            + ''',''' + IntToStr(Includis[I].Auftrag.Kopfgroesse) // Kavität
          + ''',''' + IntToStr(Includis[I].Auftrag.Var_Kavitaet) // Var_Kavität
          + ''',''' + IntToStr(Includis[I].Auftrag.Anfahrausschuss) // Anfahrausschuss
          + ''',''' + Includis[I].Auftrag.WerkzeugNr // Werkzeug
          + ''',''' + Includis[I].Auftrag.Form // FORM

          + ''',''' + IntToStr(Includis[I].StueckAuftragSchicht_SPS)
            + ''',''' + IntToStr(StueckAuftragSchicht[I].Istwert)
            + ''',''' + IntToStr(Includis[I].StueckAuftragGesamt)
            + ''',''' + IntToStr(StueckAuftragGesamt[I].Istwert)
            + ''',''' + IntToStr(optimiert_schicht)

          + ''',''' + IntToStr(GetAusschussSPSKavitaet(AUTOAUSSCHUSS_AUFTRAGSchicht[I].Istwert, Includis[I].Auftrag.Kopfgroesse))
            // AUTOAUSCHUSS
          + ''')';
          SQL_Insert(Daten.qUpdate, SQLStr);
        end
        else
        begin

            SQLStr := 'update tpm_schicht set'
//            + ' maschnr = ' + Includis[I].MaschNr + ','
//            + ' Datum = ''' + DateToStrSQL(TTT_GetTPMSchichtDatum(Includis[I].Schicht, Jetzt)) + ''','
//            + ' Schicht = ' + IntToStr(Includis[I].Schicht) + ','
//            + ' SHIFT_TYP = ''' + SHIFT_TYP + ''','
//            + ' DatumZeit = ' + FloatToPunktString(TTT_GetTPMSchichtZeit(Includis[I].Schicht, Jetzt)) + ','
//            + ' KW = ''' + GetKWStr(Jetzt) + ''','
//            + ' Monat = ''' + TTT_GetMonatStr(Jetzt) + ''','
            + ' Nutzung = ' + FloatToPunktStringF2(OEE_Nutzung, ffFixed, 10, 2) + ','
            + ' Leistung = ' + FloatToPunktStringF2(OEE_Leistung, ffFixed, 10, 2) + ','
            + ' Qualitaet = ' + FloatToPunktStringF2(OEE_Qualitaet, ffFixed, 10, 2) + ','
            + ' Effektivitaet = ' + FloatToPunktStringF2(OEE_Effektivitaet, ffFixed, 10, 2) + ','
//            + ' BetriebsauftragNr = ''' + Includis[I].Auftrag.BetriebsauftragNr + ''','
//            + ' AuftragNr = ''' + Includis[I].Auftrag.AuftragNr + ''','
//            + ' Bezeichnung = ''' + Includis[I].Auftrag.Bezeichnung + ''','
            + ' PersonalZeit = ''' + FloatToStrF2(Includis[I].Auftrag.PersonalZeit, ffFixed, 10, 2) + ''',';
          if Includis[i].MusternAktiv then
          begin
            SQLStr := SQLStr + ' Produziert=0, Produziert_org=0, Mustern=1, MusternStueck=' + IntToStr(tmp_musternstueck)+ ','  ;
          end
          else
          begin
           if not Includis[i].StueckzahlDirekt then
             SQLStr :=  SQLStr+ ' Produziert = ''' + IntToStr(tmp_Stueck) + ''',';

           SQLStr := SQLStr + ' Produziert_org = ''' + IntToStr(tmp_Stueck) + ''','
            + ' geprueft = ''' + IntToStr(Includis[I].StueckPruefAuftragSchicht) + ''',';
           end;
          if Verpackt_aus_Ausschuss or VerpacktInSchichtProt then
          if not VerpacktProtAusAarchivUndAusschussProt then
        //  if not TCO_Setup.GetParamBool(Daten.qSuch4, 'INCL_VerpacktProt_aus_Aarchiv_und_AusschussProt', false) then
            SQLStr := SQLStr + ' verpackt = ' + IntToStr(Includis[I].StueckPackAuftragSchicht) + ','
              + ' verpackt_org = ' + IntToStr(Includis[I].StueckPackAuftragSchicht) + ',';
            SQLStr := SQLStr + ' Stops = ' + IntToStr(OEE_Stops) + ','
            + ' Anlagenausfall = ' + IntToStr(OEE_Anlagenausfall) + ','
            + ' Ruesten = ' + IntToStr(OEE_Ruesten) + ','
            + ' Logistik = ' + IntToStr(OEE_Logistik) + ','
            + ' NichtGebucht = ' + IntToStr(OEE_Nichtgebucht) + ','
            + ' Geplant = ' + IntToStr(OEE_Geplant) + ','
            + ' Ungeplant = ' + IntToStr(OEE_Ungeplant) + ','
            + ' Solllaufzeit = ' + IntToStr(OEE_Sollaufzeit) + ','
            + ' IstLaufZeit = ' + IntToStr(OEE_Istlaufzeit) + ','
            + ' Solltakt = ' + FloatToPunktStringF2(Includis[I].Auftrag.Solltakt / 100, ffFixed, 10, 2) + ','
            + ' IstTakt = ' + FloatToPunktStringF2(TaktMittelSchicht, ffFixed, 10, 2) + ','
//            + ' Erstellungsdatum = ' + FloatToPunktString(Erstellungsdatum) + ','
            + ' Ausschuss = ' + IntToStr(Ausschuss) + ','
            + ' Kavitaet = ' + IntToStr(Includis[I].Auftrag.Kopfgroesse) + ','
            + ' Kav_soll = ' + IntToStr(Includis[I].Auftrag.KAVITAET_SOLL) + ','
            + ' Var_Kavitaet = ' + IntToStr(Includis[I].Auftrag.Var_Kavitaet) + ','
            + ' Anfahrausschuss = ' + IntToStr(Includis[I].Auftrag.Anfahrausschuss) + ','
            + ' Werkzeug = ''' + Includis[I].Auftrag.WerkzeugNr + ''','
            + ' Form = ''' + Includis[I].Auftrag.Form + ''','
            + ' SPS_Stueck_Schicht = ' + IntToStr(Includis[I].StueckAuftragSchicht_SPS) + ','
            + ' SPS_Schuss_Schicht = ' + IntToStr(StueckAuftragSchicht[I].Istwert) + ','
            + ' SPS_Stueck_Gesamt = ' + IntToStr(Includis[I].StueckAuftragGesamt) + ','
            + ' SPS_Schuss_Gesamt = ' + IntToStr(StueckAuftragGesamt[I].Istwert) + ','
            + ' Zyklen = ' + IntToStr(Includis[i].ZyklenAuftragSchicht) + ','
            + ' A_Istlaufzeit = ' + IntToStr(Includis[I].Auftrag.SchichtLaufzeit) + ','
            + ' optimiertstk = ' + IntToStr(optimiert_schicht) + ','
            + ' AUTOAUSSCHUSS = ' + IntToStr(GetAusschussSPSKavitaet(AUTOAUSSCHUSS_AUFTRAGSchicht[I].Istwert,
            Includis[I].Auftrag.Kopfgroesse))
            + ' where Nr = ' + IntToStr(Nummer)
            + IgnorePendingStatement;

          SQL_Insert(Daten.qUpdate, SQLStr);
        end;

stage := 30;
        if Runtime_Log then
        begin
          if Nummer <> 0 then // Theortische und kalkulierte Schichtleistung eintragen
          begin
            if Includis[I].Auftrag.Solltakt > 0 then
            begin
              try
                SQL_Get(Daten.qUpdate, 'SELECT sum(Dauer_still) sumez FROM runtime_log WHERE '
                  + ' maschnr = ' + Includis[I].MaschNr + ' AND startdatumzeit>= '''
                  + FloatToStr2((TTT_GetTPMSchichtDatum(Includis[I].Schicht, Jetzt))) + ''''
                  + ' AND status_nr=2');
                rt_einlegezeit := Daten.qUpdate.FieldByName('sumez').AsInteger div 60;

                SQL_Get(Daten.qUpdate, 'SELECT sum(Dauer_prog) sumlz FROM runtime_log WHERE '
                  + ' maschnr = ' + Includis[I].MaschNr + ' AND startdatumzeit>= '''
                  + FloatToStr2((TTT_GetTPMSchichtDatum(Includis[I].Schicht, Jetzt))) + ''''
                  + ' AND status_nr=1');
                rt_laufzeit := Daten.qUpdate.FieldByName('sumlz').AsInteger div 60;

                SQL_Get(Daten.qUpdate, 'SELECT sum(Dauer_still) sumsz FROM runtime_log WHERE '
                  + ' maschnr = ' + Includis[I].MaschNr + ' AND startdatumzeit>= '''
                  + FloatToStr2((TTT_GetTPMSchichtDatum(Includis[I].Schicht, Jetzt))) + ''''
                  + ' AND status_nr > 2');
                rt_stillzeit := Daten.qUpdate.FieldByName('sumsz').AsInteger div 60;
                // Hole Laufzeiten aus runtimelog

                SQLStr := 'UPDATE tpm_schicht SET menge_kalk_schicht = ''' +
                  IntToStr(Round(((OEE_Sollaufzeit - rt_einlegezeit) * Includis[I].Auftrag.Kopfgroesse)
                  / (Includis[I].Auftrag.Solltakt / 100))) + ''' WHERE Nr = ' + IntToStr(Nummer);
                SQL_Insert(Daten.qUpdate, SQLStr);

                SQLStr := 'UPDATE tpm_schicht SET menge_th_schicht = ''' +
                  IntToStr(Round(((rt_laufzeit - rt_einlegezeit) * Includis[I].Auftrag.Kopfgroesse)
                  / (Includis[I].Auftrag.Solltakt / 100))) + ''' WHERE Nr = ' + IntToStr(Nummer);
                SQL_Insert(Daten.qUpdate, SQLStr);

                //RS 16.06.2015: Kavitätswechsel werden auch weiterhin nicht sauber berücksichtigt
                SQLStr := 'UPDATE tpm_schicht SET menge_kalk_schicht = ''' +
                  IntToStr(Round(((OEE_Sollaufzeit - rt_einlegezeit) * Includis[I].Auftrag.Kopfgroesse)
                  / (Includis[I].Auftrag.Solltakt / 100))) + ''', menge_th_schicht = ''' +
                  IntToStr(Round(((rt_laufzeit - rt_einlegezeit) * Includis[I].Auftrag.Kopfgroesse)
                  / (Includis[I].Auftrag.Solltakt / 100))) + ''''
                  + ' WHERE Nr = ' + IntToStr(Nummer);
                SQL_Insert(Daten.qUpdate, SQLStr);
                (* Was ist denn das ??? ML 26.02.2014
                SQLStr := 'UPDATE tpm_schicht SET  WHERE Nr = ' + IntToStr(Nummer);
                SQL_Insert(Daten.qUpdate, SQLStr);
                *)
              except on E: Exception do
                  SchreibeMeldung(E.message + ' in runtimecalc', 1);
              end;
            end;
          end;
        end;

        // PErsonalnummer bei personalschalter eintragen
        if Nummer <> 0 then
        begin
          try
            if barcodepzewerkstatt then
            begin
              // Holen der Leute, die Im Bereich von Schichtanfang bis jetzt angemeldet waren.
              SQL_Get(Daten.qUpdate, 'SELECT b.name name, b.personalnr '
                + ' FROM pze_werkstatt pw, bediener b WHERE (geht >= '''
                + FloatToStr2(TTT_GetTPMSchichtZeit(Includis[I].Schicht, Jetzt))
                + ''' OR geht = 0 ) AND maschnr=' + Includis[I].MaschNr
                + ' AND b.personalnr=pw.personalnr ORDER BY kommt DESC');
              if not Daten.qUpdate.IsEmpty then
              begin
                Personal := Daten.qUpdate.FieldByName('name').AsString;

                SQLStr := 'UPDATE tpm_schicht SET personalnr = '''
                  + Daten.qUpdate.FieldByName('personalnr').AsString + ''', personal = '''
                  + Personal + ' ';

                SQL_Get(Daten.qUpdate, 'SELECT count(*) cnt'
                  + ' FROM pze_werkstatt pw, bediener b WHERE (geht >= '''
                  + FloatToStr2(TTT_GetTPMSchichtZeit(Includis[I].Schicht, Jetzt))
                  + ''' OR geht = 0 ) AND maschnr=' + Includis[I].MaschNr
                  + ' AND b.personalnr=pw.personalnr');

                if Daten.qUpdate.FieldByName('cnt').AsInteger > 1 then
                  SQLStr := SQLStr + '(' + Daten.qUpdate.FieldByName('cnt').AsString + ')';
                SQLStr := SQLStr + ''' WHERE Nr = ' + IntToStr(Nummer);
                SQL_Insert(Daten.qUpdate, SQLStr);
              end;
            end;
          except
          end;
        end;
      end;
    end;

stage := 31;
    //RP BLOCKSTILL
    //if taktlog and (Includis[I].Auftrag.BetriebsauftragNr <> '') and (Includis[I].Zustand = stLaeuftInt) then
    if (not Includis[I].Maschine_geblockt) and (Includis[I].Auftrag.BetriebsauftragNr <> '') then
      if (Includis[I].Zustand = stLaeuftInt) or ((Includis[I].Zustand = stStartRuestenInt)
          and (TCO_Setup.GetParamBool(Daten.qUpdate, 'INCL_TaktlogWaehrendRuesten'))) then
    begin
      if not TCO_Setup.GetParamBool(Daten.qSuch, 'INCL_TaktzeitProtokollVonComm') then
      begin
        if StueckAuftragGesamt[I].Istwert < Includis[I].TaktLogMerker then
          Includis[I].TaktLogMerker := 0; // Neuer Auftrag ??
        if StueckAuftragGesamt[I].Istwert >= (Includis[I].TaktLogMerker + Includis[I].ArtikelZyklus) then
        begin
          if Includis[I].IstTakt > 0 then // Wenn Taktzeit = 0 dann nicht schreiben
          begin

            SQLStr := 'Insert into TAKTZEITEN (Nr, Lizenz, AUFTRAGNR, Schuss, DatumZeit, DatumStr,'
              + ' TaktZeit, TaktzeitStr, Solltakt, tolplus, tolminus, Schicht, MittelWertMerker) VALUES (TAKTZEITENID.NextVal'
              + ',''' + Includis[I].Lizenz
              + ''',''' + Includis[I].Auftrag.BetriebsauftragNr
              + ''',''' + IntToStr(StueckAuftragGesamt[I].Istwert)
              + ''',' + FloatToPunktString(Jetzt)
              + ',''' + DateTimeToStr(Jetzt)
              + ''',' + FloatToPunktString(Includis[I].IstTakt / 1000)
              + ',''' + FloatToStrF2(Includis[I].IstTakt / 1000, ffFixed, 8, 2) + GetL(' s')
              + ''',' + FloatToPunktString(Includis[I].SollTakt / 100)
              + ',' + FloatToPunktString(Includis[I].TaktToleranzPlus)
              + ',' + FloatToPunktString(Includis[I].TaktToleranzMinus)
              + ',''' + IntToStr(Includis[I].Schicht)
              + ''',''0'
              + ''')';
            SQL_Insert(Daten.qUpdate, SQLStr);
            Includis[I].TaktLogMerker := StueckAuftragGesamt[I].Istwert;

            SQLStr := 'delete from TAKTZEITEN where AUFTRAGNR <> ''' + Includis[I].Auftrag.BetriebsauftragNr
              + ''' AND LIZENZ = ''' + Includis[I].Lizenz + '''';
            SQL_Insert(Daten.qUpdate, SQLStr);
          end;
        end;
      end;
    end;

    //*******************************************************************
    //     Werkzeug-Standzeiten schreiben
    //*******************************************************************
   if (Includis[I].Auftrag.Stat = 0) and werkzeugverwaltung then
    begin
      if S7Main.MaschAuftragStart > -1 then
        if (SQLGetBool(Daten.qSuch, 'MASCHINE', 'Datenblock', IntToStr(S7Main.MaschAuftragStart))) then
        begin
          tmpLiz := Daten.qSuch.FieldByName('Lizenz').AsString;
          if tmpLiz = Includis[I].Lizenz then
          begin
            Includis[I].Auftrag.WerkzeugMerker := 0;
            Includis[I].Auftrag.Istwert := 0;
          end;
        end;
stage := 32;

      //Standzeiten Aktualisieren
             //RS 16.06.2015: Imho müssen wir nichts bezüglich Kavitätswechsel unternehmen, da das Restrisiko verschwindend gering bleibt, dass ein Schuss mit alter Kavität erst dann hier berücksichtigt wird, wenn schon eine neue Kavität gilt
     if (Includis[I].Auftrag.WerkzeugMerker > 0) and (Includis[I].Auftrag.WerkzeugMerker < Includis[I].Auftrag.Istwert) then
      begin
        if Variable_Kavitaet then
          AnzSchuss := (Includis[I].Auftrag.Istwert - Includis[I].Auftrag.WerkzeugMerker)
            div Includis[I].Auftrag.Kopfgroesse * Includis[I].Auftrag.Var_Kavitaet
//            div Includis[I].Kopfgroesse * Includis[I].Auftrag.Var_Kavitaet // Alt und falsch Len 6.2.14?!?!
        else
          AnzSchuss := (Includis[I].Auftrag.Istwert - Includis[I].Auftrag.WerkzeugMerker) div Includis[I].Auftrag.Kopfgroesse;
//          AnzSchuss := (Includis[I].Auftrag.Istwert - Includis[I].Auftrag.WerkzeugMerker) div Includis[I].Kopfgroesse; // Alt und falsch Len 6.2.14?!?!

// Hier mal eine Plausi einbauen. Wenn Aufträge unterbrochen werden oder Stückzahlen einfach so geändert werden, stimmt die Zykluszählung nicht mehr.
// Das Ganze abgesichert, dass, wenn der letzte Durchlauf < 10 Minuten her ist, dann max 100 Zyklen Unterschied.
        if (Now - Last_Time_Meldung) < 10/1440 then
        begin
          if AnzSchuss > 100 then
            AnzSchuss:=0;
        end;

        if AnzSchuss > 0 then
          if SQLGetBool(Daten.qSuch, 'WERKZEUG', 'Werkzeug', IntToStr(Includis[I].Auftrag.Werkzeug)) then
          begin
            Nummer := Daten.qSuch.FieldByName('Nr').AsInteger;
            IstStandzeit := Daten.qSuch.FieldByName('IstStandzeitInt').AsInteger;
            Sollstandzeit := Daten.qSuch.FieldByName('SollstandzeitInt').AsInteger;

            IstStandzeit_2 := Daten.qSuch.FieldByName('IstStandzeit_2').AsInteger;
            Sollstandzeit_2 := Daten.qSuch.FieldByName('Sollstandzeit_2').AsInteger;

            Einsatzdauer := Daten.qSuch.FieldByName('EinsatzdauerInt').AsInteger;
            DoppelWZ := Daten.qSuch.FieldByName('DOPPELWERKZEUG').AsString;

            if (AnzSchuss <= IstStandzeit) or (Sollstandzeit = 0) then
            begin
              IstStandzeit := IstStandzeit - AnzSchuss;
              if not TCO_setup.GetParamBool(Daten.qSuch3, 'INCL_MoldPrewarningsFromBdaSvc') then
              begin
                if SQLGetBool(Daten.qSuch3, 'BDA', 'Bezeichnung', Daten.qSuch.FieldByName('WerkzeugNr').AsString
                  + GetL(': WKZ-Standzeit abgelaufen')) then
                  DeleteSQL(Daten.qUpdate, 'BDA', 'Nr', IntToStr(Daten.qSuch3.FieldByName('Nr').AsInteger));
              end;
            end
            else
            begin
              if TCO_setup.GetParamBool(Daten.qSuch3, 'INCL_Negative_Mold_Lifetime') then
                IstStandzeit := IstStandzeit - AnzSchuss
              else
                IstStandzeit := 0;
              if not TCO_setup.GetParamBool(Daten.qSuch3, 'INCL_MoldPrewarningsFromBdaSvc') then
              begin
                if (not SQLGetBool(Daten.qSuch3, 'BDA', 'Bezeichnung', Daten.qSuch.FieldByName('WerkzeugNr').AsString
                  + GetL(': WKZ-Standzeit abgelaufen'))) and ((Daten.qSuch.FieldByName('Status').AsString = GetL('Maschine'))
                  OR
                      (TCO_Setup.GetParamBool(Daten.qSuch5, 'INCL_MoldStateFromStateInt') AND (Daten.qSuch.FieldByName('Statusint').AsInteger=1))) then
                  CCC_Job_erzeugen(Daten.qUpdate, Daten.qSuch.FieldByName('Statusexakt').AsString,
                    Daten.qSuch.FieldByName('WerkzeugNr').AsString
                    + GetL(': WKZ-Standzeit abgelaufen'), 'WKZ', IntToStr(Daten.qSuch.FieldByName('Werkzeug').AsInteger),
                    Daten.qSuch.FieldByName('Zustaendig').AsString, GetL('WKZ pruefen'), False, 0);
              end;
            end;

            if (not TCO_Setup.GetParamBool(Daten.qSuch5, 'INCL_MoldCycleFromCoreSvc')) and (Sollstandzeit_2 > 0) then
            begin
              if TCO_setup.GetParamBool(Daten.qSuch3, 'INCL_Increment_Mold_Lifetime2') then
              begin
                if IstStandzeit_2 >= Sollstandzeit_2 then
                begin
                  IstStandzeit_2 := 0;
                  if not TCO_setup.GetParamBool(Daten.qSuch3, 'INCL_MoldPrewarningsFromBdaSvc') then
                  begin
                    if (not SQLGetBool(Daten.qSuch3, 'BDA', 'Bezeichnung', Daten.qSuch.FieldByName('WerkzeugNr').AsString
                      + GetL(': WKZ-Standzeit_2 abgelaufen'))) and ((Daten.qSuch.FieldByName('Status').AsString = GetL('Maschine')) OR
                      (TCO_Setup.GetParamBool(Daten.qSuch5, 'INCL_MoldStateFromStateInt') AND (Daten.qSuch.FieldByName('Statusint').AsInteger=1))) then
                      CCC_Job_erzeugen(Daten.qUpdate, Daten.qSuch.FieldByName('Statusexakt').AsString,
                        Daten.qSuch.FieldByName('WerkzeugNr').AsString + GetL(': WKZ-Standzeit_2 abgelaufen'), 'WKZ',
                        IntToStr(Daten.qSuch.FieldByName('Werkzeug').AsInteger),
                        Daten.qSuch.FieldByName('Zustaendig').AsString, GetL('WKZ pruefen'), False, 0);
                  end;
                end;

                IstStandzeit_2 := IstStandzeit_2 + AnzSchuss;
              end
              else
                IstStandzeit_2 := IstStandzeit_2 - AnzSchuss;

              SQLStr := 'update WERKZEUG set'
                + ' IstStandzeit_2 = ''' + IntToStr(IstStandzeit_2) + ''' where Nr = ' + IntToStr(Nummer);
              SQL_Insert(Daten.qUpdate, SQLStr);
            end;

            Einsatzdauer := Einsatzdauer + AnzSchuss;
            if not TCO_Setup.GetParamBool(Daten.qSuch5, 'INCL_MoldCycleFromCoreSvc') then
            begin
              if (Daten.qSuch.FieldByName('Status').AsString = GetL('Maschine'))OR
                    (TCO_Setup.GetParamBool(Daten.qSuch5, 'INCL_MoldStateFromStateInt') AND (Daten.qSuch.FieldByName('Statusint').AsInteger=1))
                     then
              begin
                SQLStr := 'update WERKZEUG set '
                  + 'EinsatzdauerInt =   ''' + IntToStr(Einsatzdauer)
                  + ''',Einsatzdauer =      ''' + IntToStr(Einsatzdauer)
                  + ''' where Nr = ' + IntToStr(Nummer);
                SQL_Insert(Daten.qUpdate, SQLStr);

                if (IstStandzeit >= 0 ) or TCO_setup.GetParamBool(Daten.qSuch3, 'INCL_Negative_Mold_Lifetime') then
                begin
                  SQLStr := 'update WERKZEUG set '
                    + 'IstStandzeitInt =  ''' + IntToStr(IstStandzeit)
                    + ''',IstStandzeit =  ''' + IntToStr(IstStandzeit)
                    + ''' where Nr = ' + IntToStr(Nummer);
                  SQL_Insert(Daten.qUpdate, SQLStr);
                end;
              end;
            end;
stage := 33;

            //*******************************************************************
            //     DoppelWerkzeuge
            //*******************************************************************
            if DoppelWerkzeuge and (DoppelWZ <> '') then
            begin
              if (SQLGetBool(Daten.qSuch, 'WERKZEUG', 'WerkzeugNr', DoppelWZ)) then
              begin
                Nummer := Daten.qSuch.FieldByName('Nr').AsInteger;
                IstStandzeit := Daten.qSuch.FieldByName('IstStandzeitInt').AsInteger;
                Einsatzdauer := Daten.qSuch.FieldByName('EinsatzdauerInt').AsInteger;

                if AnzSchuss <= IstStandzeit then
                begin
                  IstStandzeit := IstStandzeit - AnzSchuss;
                  if not TCO_setup.GetParamBool(Daten.qSuch3, 'INCL_MoldPrewarningsFromBdaSvc') then
                  begin
                    if SQLGetBool(Daten.qSuch3, 'BDA', 'Bezeichnung', Daten.qSuch.FieldByName('WerkzeugNr').AsString
                      + GetL(': WKZ-Standzeit abgelaufen')) then
                      DeleteSQL(Daten.qUpdate, 'BDA', 'Nr', IntToStr(Daten.qSuch3.FieldByName('Nr').AsInteger));
                  end;
                end
                else
                begin
                  if TCO_setup.GetParamBool(Daten.qSuch3, 'INCL_Negative_Mold_Lifetime') then
                    IstStandzeit := IstStandzeit - AnzSchuss
                  else
                    IstStandzeit := 0;
                  if not TCO_setup.GetParamBool(Daten.qSuch3, 'INCL_MoldPrewarningsFromBdaSvc') then
                  begin
                    if (not SQLGetBool(Daten.qSuch3, 'BDA', 'Bezeichnung', Daten.qSuch.FieldByName('WerkzeugNr').AsString
                      + GetL(': WKZ-Standzeit abgelaufen')))
                      and ((Daten.qSuch.FieldByName('Status').AsString = GetL('Maschine')) OR
                      (TCO_Setup.GetParamBool(Daten.qSuch5, 'INCL_MoldStateFromStateInt') AND (Daten.qSuch.FieldByName('Statusint').AsInteger=1)))
                      then
                      CCC_Job_erzeugen(Daten.qUpdate, Daten.qSuch.FieldByName('Statusexakt').AsString,
                        Daten.qSuch.FieldByName('WerkzeugNr').AsString + GetL(': WKZ-Standzeit abgelaufen'), 'WKZ',
                        IntToStr(Daten.qSuch.FieldByName('Werkzeug').AsInteger),
                        Daten.qSuch.FieldByName('Zustaendig').AsString, 'WKZ pruefen', False, 0);
                  end;
                end;

                Einsatzdauer := Einsatzdauer + AnzSchuss;

                SQLStr := 'update WERKZEUG set '
                  + 'EinsatzdauerInt =   ''' + IntToStr(Einsatzdauer)
                  + ''',Einsatzdauer =      ''' + IntToStr(Einsatzdauer)
                  + ''' where Nr = ' + IntToStr(Nummer);
                SQL_Insert(Daten.qUpdate, SQLStr);

                if (IstStandzeit >= 0 ) or TCO_setup.GetParamBool(Daten.qSuch3, 'INCL_Negative_Mold_Lifetime') then
                begin
                  SQLStr := 'update WERKZEUG set '
                    + 'IstStandzeitInt =      ''' + IntToStr(IstStandzeit)
                    + ''',IstStandzeit =      ''' + IntToStr(IstStandzeit)
                    + ''' where Nr = ' + IntToStr(Nummer);
                  SQL_Insert(Daten.qUpdate, SQLStr);
                end;
              end;
            end;
          end;
      end;
      Includis[I].Auftrag.WerkzeugMerker := Includis[I].Auftrag.Istwert;

      if MachineCycleCount then
      begin
        SQLStr := 'UPDATE maschine SET '
          + ' ZYKLENALL = ZYKLENALL + ' + IntToStr(Includis[i].ZyklenDiff) + ', '
          + ' ZYKLASTDATUMZEIT = ' + FloatToPunktString(now) + ', '
          + ' ZYKLENLAST = ' + IntToStr(Includis[i].ZyklenNeu)
          + ' WHERE maschnr = ' + IntToStr(Includis[i].Datenblock);
        SQL_Insert(Daten.qUpdate, SQLStr);
      end;

    end;
  end;
  except on e : exception do
    SchreibeMeldung('Exception ('+IntToStr(stage)+') during main write cycle ' + e.Message, 0);
  end;
stage := 34;
  LizenzList.Destroy;
  COTPM_Stillstaende.Destroy;
//  COTPM_StillstaendeAll.Destroy;
stage := 35;

{$ifdef TIMEMEAS}
  SchreibeMeldung('Calc A_Fields', 1);
{$endif}


  // A_Felder Schicht berechnen
  try
    CCC_A_Felder_Schicht_Berechnen(Daten.qSuch, Daten.qSuch2, Daten.qUpdate, SchichtStart, GetSchichtNr(SchichtStart));
  except
  end;
stage := 36;
{$ifdef TIMEMEAS}
  SchreibeMeldung('Taktzeiten', 1);
{$endif}
  try
    CCC_TaktzeitIstSchreiben;

  except
  end;

  (*
  SQLSTR := 'UPDATE maschinf SET '
      + ' RemainParts = CASE WHEN (sollwert - stueck) < 0 THEN 0 ELSE sollwert - stueck END ';
    SQL_Insert(Daten.qUpdate, SQLStr);
    *)
    //*******************************************************************
    //     MDE-Istwerte schreiben
    //*******************************************************************
    (*
  Daten.qSuch.Close;
  SQLStr := 'select * from MDE';
  SQL_Get(Daten.qSuch, SQLStr);
  Daten.qSuch.First;
  while not Daten.qSuch.EOF do
  begin
    Lizenz := Daten.qSuch.FieldByName('Lizenz').AsString;
    J := 0;
    for I := 1 to Anzahl_Masch do
      if (Lizenz = Includis[I].Lizenz) then
      begin
        J := I;
        break;
      end;

    if J > 0 then
    begin
      Nummer := Daten.qSuch.FieldByName('Nr').AsInteger;
      SollwertABS := Daten.qSuch.FieldByName('Sollwert_ABS').AsInteger;
      Sollwert := Format_String(Daten.qSuch.FieldByName('Sollwert_Diff').AsString);
      Istwert := Sollwert - (SollwertABS - Includis[I].Betriebsstunden);
      Termin_Rechnerisch := GetEndeDatumLizenz(Includis[I].Lizenz, Includis[I].Auftrag.BetriebsauftragNr,
        Jetzt, Istwert * 60);
      Daten.qUpdate.Close;
      SQLStr := 'UPDATE mde set Istwert_Diff = ''' + IntToStr(Istwert) + ' h'', '
        + ' Termin_Rechnerisch = ''' + FloatToStrF2(Termin_Rechnerisch, ffFixed, 15, 10) + ''''
        + ' WHERE nr = ' + IntToStr(Nummer);
      SQL_Insert(Daten.qUpdate, SQLStr);
//      UpdateSQL(Daten.qUpdate, 'MDE', 'Istwert_Diff', IntToStr(Istwert) + ' h', 'Nr', IntToStr(Nummer));
  //    UpdateSQL(Daten.qUpdate, 'MDE', 'Termin_Rechnerisch', FloatToStrF2(Termin_Rechnerisch, ffFixed, 15, 10),
    //    'Nr',
      //  IntToStr(Nummer));
    end;
    Daten.qSuch.Next;
  end;
  *)
{$ifdef TIMEMEAS}
  SchreibeMeldung('Offline', 1);
{$endif}

  //*******************************************************************
  //     OfflineMaschinen in Maschinf
  //*******************************************************************
  Daten.qSuch.Close;
  SQLStr := 'select * from MASCHOFFLINE';
  SQL_Get(Daten.qSuch, SQLStr);
  Daten.qSuch.First;
  while not Daten.qSuch.EOF do
  begin
    Lizenz := Daten.qSuch.FieldByName('Lizenz').AsString;
    MaschNr := Daten.qSuch.FieldByName('MaschNr').AsString;
    Kurzkennung := Daten.qSuch.FieldByName('Kurzkennung').AsString;
    Waitcnt := 0;
    repeat
      if not SQLGetBool(Daten.qSuch2, 'Maschinf', 'Maschine', Lizenz) then
      begin
        Sleep(500);
        inc(waitcnt);
      end
      else
      begin
        waitcnt := 10;
      end;
    until waitcnt > 3;
    // Schleife wurde beenden. wenn Eintrag gefunden dann waitcnt = 10, sonst kleiner.
stage := 37;


    if waitcnt < 10 then // SQLGet(Daten.qSuch2, 'MASCHINF', 'LIZENZ', Lizenz, True) = 0 then
    begin
      SQLStr := 'insert Into MaschInf ('
        + 'Nr, Lizenz,Bezeichnung,Pack, DatumZeit, Maschine,MaschNr,MaschNrInt, ZUSTAND, ZUSTANDINT, Taktzeit,'
        + ' Sollwert, ISTWERT_PRZ, STUECK, Stat, AUSSCHUSS, TAKTZEIT_STR, KURZKENNUNG) values (MaschinfId.NextVal,'
        + ' ''' + Lizenz + ''','
        + ' ''' + GetL('kein aktueller Auftrag') + ''','
        + ' ''0'','
        + ' ''' + FloatToStr2(N_o_w) + ''','
        + ' ''' + Lizenz + ''','
        + ' ''' + MaschNr + ''','
        + ' ''' + MaschNr + ''','
        + ' ''' + GetL('offline') + ''','
        + ' ''3'','
        + ' ''0'','
        + ' ''0'','
        + ' ''0 %'','
        + ' ''0'','
        + ' ''0'','
        + ' ''0'','
        + ' ''0'','
        + ' ''' + Kurzkennung + ''')';
      try
        SQL_Insert(Daten.qUpdate, SQLStr);
      except
      end;
    end;
    Daten.qSuch.Next;
  end;

stage := 38;
  SQLStr := 'select * from PDE where PDE.Lizenz in (select Lizenz from Maschoffline) and PDE.Stat < 2';
  SQL_Get(Daten.qSuch, SQLStr);
  Daten.qSuch.First;
  while not Daten.qSuch.EOF do
  begin
    SQLStr := 'Update Maschinf set'
      + ' Sollwert = ''' + Daten.qSuch.FieldByName('Sollwert').AsString + ''','
      + ' Istwert_Prz = ''' + Daten.qSuch.FieldByName('Ist_Prz').AsString + ' %'','
      + ' Taktzeit = ''' + IntToStr(Daten.qSuch.FieldByName('taktzeit').AsInteger * 10) + ''','
      + ' Stueck = ''' + Daten.qSuch.FieldByName('Istwert').AsString + ''',';
    if not TCO_Setup.GetParamBool(Daten.qSuch3, 'INCL_VerpacktProt_aus_Schichtausschuss') then
      SQLStr :=SQLStr + ' Pack = ''' + Daten.qSuch.FieldByName('Pack').AsString + ''',';
    SQLStr :=SQLStr + ' StartDatum = ''' + DateTimeToStr(Daten.qSuch.FieldByName('StartDatumZeit').AsFloat) + ''','
      + ' EndeDatum = ''' + DateTimeToStr(Daten.qSuch.FieldByName('EndDatumZeit').AsFloat) + ''','
      + ' LTSoll = ''' + Daten.qSuch.FieldByName('Termin1').AsString + ''','
      + ' LTIst = ''' + Daten.qSuch.FieldByName('EndDatumZeit').AsString + ''','
      + ' ArtikelNr = ''' + Daten.qSuch.FieldByName('AuftragNr').AsString + ''','
      + ' BetriebsAuftragNr = ''' + Daten.qSuch.FieldByName('BetriebsAuftragNr').AsString + ''','
      + ' Bezeichnung = ''' + Daten.qSuch.FieldByName('Bezeichnung').AsString + ''','
      + ' Ausschuss = ''' + Daten.qSuch.FieldByName('Ausschuss').AsString + ''','
      + ' Kavitaet = ''' + Daten.qSuch.FieldByName('Kopfgroesse').AsString + ''','
      + ' Kavitaet_Soll = ''' + Daten.qSuch.FieldByName('Kavitaet_Soll').AsString + ''''
      + ' where Lizenz = ''' + Daten.qSuch.FieldByName('Lizenz').AsString + ''''
      + IgnorePendingStatement;
    SQL_Insert(Daten.qUpdate, SQLStr);

    Daten.qSuch.Next;
  end;

stage := 39;
  if IgnorePendingStatement <> '' then
  begin
    // Maschinf Pending Status zurück setzen
    SQL_Insert(Daten.qUpdate, 'UPDATE maschinf SET pending=0 WHERE pending > 0');
    // Tpm_schicht Pending Status zurück setzen
    SQL_Insert(Daten.qUpdate, 'UPDATE tpm_schicht SET pending=0 WHERE pending > 0');
    // pde Pending Status zurück setzen
    SQL_Insert(Daten.qUpdate, 'UPDATE pde SET pending=0 WHERE pending > 0');
    // pdekombi Pending Status zurück setzen
    SQL_Insert(Daten.qUpdate, 'UPDATE pdekombi SET pending=0 WHERE pending > 0');
    // aarchiv Pending Status zurück setzen
    SQL_Insert(Daten.qUpdate, 'UPDATE aarchiv SET pending=0 WHERE pending > 0');
  end;
{$ifdef TIMEMEAS}
  SchreibeMeldung('DelDTLog', 1);
{$endif}

  if Stillstand_Minute_Loeschen > 0 then
  begin
    SQLStr := 'delete from TPM_Stillog where (Geht > 0) and (Geht - Kommt < '
      + IntToStr(Stillstand_Minute_Loeschen) + ' / 1440)';
    SQL_Insert(Daten.qUpdate, SQLStr);
  end;

  //09.07.2013 RS: Notnagel SUH: Maschinen wurden doppelt in maschinf eingetragen. Hierüber bereinigen wir
  {$ifdef INCL_ORA}
    try
      SQLStr := 'DELETE FROM maschinf'
              + ' WHERE rowid NOT IN ( '
              + '         SELECT MAX(rowid)'
              + '         FROM maschinf'
              + '         GROUP BY lizenz, betriebsauftragnr)';
      SQL_Insert(Daten.qUpdate, SQLStr);
    except on e: Exception do
      SchreibeMeldung(e.Message + ' on purging maschinf', 0);
    end;
  {$endif}
  //18.09.2013 CEFEG
  try
    SQLStr := 'DELETE FROM maschinf'
            + ' WHERE maschine LIKE ''% W2'''
            + ' AND betriebsauftragnr NOT IN '
            + ' (SELECT betriebsauftragnr'
            + '  FROM pdekombi'
            + '  WHERE masterbetriebsauftragnr IN '
            + '   (SELECT betriebsauftragnr'
            + '    FROM maschinf'
            + '   )'
            + ' )';
    SQL_Insert(Daten.qUpdate, SQLStr);
  except on e: Exception do
    SchreibeMeldung(e.Message + ' on inserting missing detail job in maschinf with ''' + SQLStr + '''', 0);
  end;
end;

procedure CCC_Zeiten_Aufrunden;
var
  Zeit, Datum: TDateTime;
  Nummer: Integer;
  AlteSchicht: Integer;
  I: Integer;
begin
  Datum := Trunc(Jetzt);
  Zeit := Frac(Jetzt);
  if Zeit <= Schicht1 then
    Datum := Datum - 1;

  for I := 1 to Anzahl_Masch do
  begin
    if Includis[I].IstArchiviert then
 	  Continue;
    if (Includis[I].Schicht = 1) then
    begin
      Zeit := Schicht1;
      AlteSchicht := 3;
    end
    else
      if (Includis[I].Schicht = 2) then
      begin
        Zeit := Schicht2;
        AlteSchicht := 1;
      end
      else
      begin
        Zeit := Schicht3;
        AlteSchicht := 2;
      end;

    if SQL3GetBool(Daten.qSuch, 'SPC', 'Maschine', Includis[I].Maschine,
      'Schicht', IntToStr(AlteSchicht), 'Datum', DateToStr(Datum)) then
    begin
      Nummer := Daten.qSuch.FieldByName('Nr').AsInteger;
      UpdateSQL(Daten.qUpdate, 'SPC', 'Zeit', TimeToStr(Zeit), 'Nr', IntToStr(Nummer));
    end;
  end;
end;

procedure CCC_TPM_BCD_Meldung;
var
  I, Nr: Integer;
  SQLStr: string;
  Meldung: string;
  Still: Integer;
begin
  for I := 1 to Anzahl_Masch do
    if Includis[I].BCD_Read AND not Includis[I].IstArchiviert then
    begin

      S7Main.Schreibe_SPS_Wert(StrToInt(Includis[I].MaschNr), TTT_GetSignalNr(CBCD_READ), 0);
      UpdateSQL(Daten.qSuch, 'Signal_Maschine', 'Istwert', '0', 'nr', IntToStr(BCD_Read[I].DBNr));
      UpdateSQL(Daten.qSuch, 'Signal_Maschine', 'Istwert', '0', 'nr', IntToStr(BCD[I].DBNr));

      //BCD-Code erhalten
      if Includis[I].BCDCode = 99 then
      begin
        //Auftrag beenden
        SQLStr := ' SELECT betriebsauftragnr FROM maschinf WHERE lizenz = ''' + Includis[I].Lizenz + '''';
        SQL_Get(Daten.qSuch, SQLStr);
        if not Daten.qSuch.IsEmpty then
          LogUsrEvent(Daten.qSuch2,Daten.qUpdate,129, 'WFA', Daten.qSuch.FieldByName('betriebsauftragnr').AsString, '');
        S7Main.S7_Auftrag.Beenden(Includis[I].Lizenz);
        Exit;
      end;

      if Includis[I].BCDCode = 88 then
      begin
        //Auftrag starten
        if BCDAutoStartNachRuesten then // Bei Schalter nur Starten, wenn Auftrag rüstet
        begin
          SQL_Get(Daten.qSuch, 'SELECT * from PDE where Lizenz = ''' + Includis[I].Lizenz + ''' AND (stat = 1)');
          if not Daten.qSuch.IsEmpty then
            CCC_Auftrag_Starten_BCDCode(Includis[I].Lizenz, False);
        end
        else
          CCC_Auftrag_Starten_BCDCode(Includis[I].Lizenz, False);
        Exit;
      end;

      if Includis[I].BCDCode = 77 then
      begin
        //Auftrag Ruesten
        CCC_Auftrag_Starten_BCDCode(Includis[I].Lizenz, True);
        Exit;
      end;

      if Includis[I].BCDCode = 50 then
      begin
        //Auftrag beenden
        CCC_RoteLampeCheckAus(Includis[I].Lizenz);
        Exit;
      end;

      if (SQLGetBool(Daten.qSuch, 'BCD', 'Bcdcode', IntToStr(Includis[I].BCDCode))) then
        Meldung := Daten.qSuch.FieldByName('Stillstand').AsString
      else
        Meldung := 'nicht definiert';

      SQLStr := 'select * from TPM_STILLOG where (MaschNr = ''' + Includis[I].MaschNr + ''' AND Geht = 0)';
      SQL_Get(Daten.qSuch, SQLStr);
      Daten.qSuch.First;
      while not Daten.qSuch.EOF do
      begin
        Nr := Daten.qSuch.FieldByName('Nr').AsInteger;

        Still := Includis[I].BCDCode + 10;
        if SQLGetBool(Daten.qUpdate, 'TPM_STILLSTAENDE', 'STILLSTANDNR', IntToStr(Still)) then
        begin
          if Includis[I].Zustand <> stStartRuestenInt then
            UpdateSQL(Daten.qUpdate, 'tpm_Stillog', 'Stillstandnr', IntToStr(Still), 'Nr', IntToStr(Nr));
        end;
        Daten.qSuch.Next;
      end;
      Daten.qSuch.Close;
    end;
end;

procedure CCC_Auftrag_Starten_BCDCode(Lizenz: string; Ruesten: Boolean);
var
  EventId, I, Ret: Integer;
  EventToken, BetriebsauftragNr: string;
begin
  I := CCC_GetMaschIndex(Lizenz);
  if (I = - 1) then
    Exit;

  SQLCountSTR := 'select Count(*) CNT from PDE where Lizenz = ''' + Lizenz +
    ''' AND (stat = 0) '; // Achtung Änderung !! Aufträge, die gerüstet werden, könne auch über BCD gestartet werden
  Daten.qSuch2.Close;
  SQL_Get(Daten.qSuch2, SQLCountSTR);
  if Daten.qSuch2.FieldByName('CNT').AsInteger > 0 then
  begin

    CCC_Erzeuge_Arbeitsplan(Includis[I].Lizenz, Includis[I].MaschNr,
      GetL('Auftrag Fehler'),
      ' 1',
      GetL('Fehler Auftrag starten: laufenden Auftrag beenden!'), // Änderung Mentor 30.06 1800
      GetL('Bediener'),
      False, '1', False, True);

    S7Main.Schreibe_SPS_Wert(0, TTT_GetSignalNr(CROTELAMPE_AUS), 1);
    Exit;
  end;

  SQLCountSTR := 'select Count(*) CNT from PDE where Lizenz = ''' + Lizenz + ''' AND (stat in (1,2))';
  Daten.qSuch2.Close;
  SQL_Get(Daten.qSuch2, SQLCountSTR);
  if Daten.qSuch2.FieldByName('CNT').AsInteger <= 0 then
  begin

    CCC_Erzeuge_Arbeitsplan(Includis[I].Lizenz, Includis[I].MaschNr,
      GetL('Auftrag Fehler'),
      ' 1',
      GetL('Fehler Auftrag-Start: kein Auftrag angelegt'),
      GetL('Bediener'),
      False, '1', False, True);

    S7Main.Schreibe_SPS_Wert(0, TTT_GetSignalNr(CROTELAMPE_AUS), 1);
    Exit;
  end;

  SQLStr := 'select * from PDE where Lizenz = ''' + Lizenz +
    ''' AND (stat = 2 or stat = 1) Order by Stat, StartDatumZeit';
  // Achtung Änderung !! Aufträge, die gerüstet werden, könne auch über BCD gestartet werden

  SQL_Get(Daten.qSuch2, SQLStr);
  Daten.qSuch2.First;

  BetriebsauftragNr := Daten.qSuch2.FieldByName('BetriebsauftragNr').AsString;

  Ret := S7Main.S7_Auftrag.Starten(Includis[I].Lizenz, BetriebsauftragNr, Ruesten);
  if Ruesten then
  begin
    EventId := 127;
    EventToken := 'WUA';
  end
  else
  begin
    EventId := 126;
    EventToken := 'WSA';
  end;
  LogUsrEvent(Daten.qSuch3,Daten.qUpdate, EventId, EventToken, Betriebsauftragnr, '');

  if Ret <> 0 then
  begin
    CCC_Erzeuge_Arbeitsplan(Includis[I].Lizenz, Includis[I].MaschNr,
      GetL('Auftrag Fehler'),
      ' 1',
      GetL('Fehler Auftrag-Start... FehlerNr: ') + IntToStr(Ret),
      GetL('Bediener'),
      False, '1', False, True);

    S7Main.Schreibe_SPS_Wert(0, TTT_GetSignalNr(CROTELAMPE_AUS), 1);
    Exit;
  end;
end;

procedure CCC_MDEWerte_fuellen;
var
  I, J: Integer;
  Nummer, St_Schicht, SignalKod: Integer;
  S, Signal1, Signal2, Istwert, IstWertStr: string;
  SQLStr, Lizenz: string;
  AbweichnungSTR: string;
  Abweichung, AbweichungPRZ, Taktzeit, ToleranzInt: Integer;
  AbwREL, AbwRELPRZ: Real;
  Solltakt, Sollwert_mal_zehn: Integer;
begin
  // Sollwertint ist Solltakt in Sec / 100
  // Istwertint ist Isttakt in Sec / 1000

  //****** MDE-Vergleich-Tabelle aktualisieren
  Daten.qSuch.Close;

  S := 'delete from MDE_Ver where MDE_Ver.Lizenz not in (select Lizenz from Maschine) or MDE_Ver.Lizenz is null';
  SQL_Insert(Daten.qUpdate, S);

  SQLStr := 'select * from MDE_VER order by Lizenz';
  SQL_Get(Daten.qSuch, SQLStr);
  Daten.qSuch.First;
  while not Daten.qSuch.EOF do
  begin
    Lizenz := Daten.qSuch.FieldByName('Lizenz').AsString;
    J := CCC_GetMaschIndex(Lizenz);
    if J = -1 then
      Exit;

    if (Lizenz <> Includis[J].Lizenz) then
      Exit;

    Nummer := Daten.qSuch.FieldByName('Nr').AsInteger;
    Signal1 := Daten.qSuch.FieldByName('Signal1').AsString;
    SignalKod := Daten.qSuch.FieldByName('SignalKod').AsInteger;
    Signal2 := Daten.qSuch.FieldByName('Signal2').AsString;
    ToleranzInt := Daten.qSuch.FieldByName('ToleranzINT').AsInteger;

    Includis[i].TaktToleranzPlus := ToleranzInt;
    Includis[i].TaktToleranzMinus := ToleranzInt;

    if SignalKod = 0 then
    begin
      if Includis[J].IstTakt = 0 then
        Includis[J].IstTakt := 1;
      Taktzeit := Includis[J].IstTakt;
      IstWertStr := FloatToStrF2(Taktzeit * 0.001, ffFixed, 5, 2);

//      if  SQLGet(Daten.qSuch2, 'Maschinf', 'Lizenz', Lizenz, True) > 0 then
      if  SQLGetBool(Daten.qSuch2, 'Maschinf', 'Lizenz', Lizenz) then
      begin
        Solltakt := Daten.qSuch2.FieldByName('Solltakt').AsInteger;
        if Solltakt > 0 then
        begin
          Daten.qUpdate.SQL.Text := 'UPDATE mde_ver SET sollwertint = ' + IntToStr(Solltakt)
            + ', sollwert = ''' + FloatToStrF2(Solltakt / 100, ffFixed, 10, 1)
            + ''' WHERE nr = ' + IntToStr(Nummer);
          Daten.qUpdate.ExecSQL;
        end;
      end;

      Sollwert_mal_zehn := Daten.qSuch.FieldByName('SollwertInt').AsInteger;
      try
        AbwREL := Round(100 * ((Sollwert_mal_zehn / 100) - (Taktzeit / 1000))) / 100;
      except
        AbwREL := 0;
      end;
      try
        if Sollwert_mal_zehn = 0 then
          AbwRELPRZ := 0
        else
          AbwRELPRZ := Round(100 * ((AbwREL / (Sollwert_mal_zehn / 100)) * 100)) / 100;
      except
      AbwRELPRZ := 0;
      end;

      Abweichung := Sollwert_mal_zehn - Round(Includis[J].IstTakt * 0.1);

      if (Sollwert_mal_zehn = 0) then
        Sollwert_mal_zehn := 1;

      if Abweichung < 0 then
        Abweichung := Abweichung * -1;
      AbweichungPRZ := Trunc(Abweichung  / (Sollwert_mal_zehn/100));
      if AbweichungPRZ < 0 then
        AbweichungPRZ := AbweichungPRZ * -1;

      AbweichnungSTR := FloatToStrF2((Abweichung / 100), ffFixed, 5, 2);

      Daten.qUpdate.SQL.Text := 'UPDATE mde_ver SET istwertint = ' + IntToStr(Taktzeit)
        + ', istwert = ''' + IstWertStr + ''''
        + ', abwrel = ' + FloatToPunktString(AbwREL)
        + ', abwrelprz = ' + FloatToPunktString(AbwRELPRZ)
        + ', abweichung = ''' +AbweichnungSTR + ''''
        +  ', AbweichungPRZ = ''' +IntToStr(AbweichungPRZ) + ''''
        + ' WHERE nr = ' + IntToStr(Nummer);
      Daten.qUpdate.ExecSQL;


//      SQL_Insert(Daten.qUpdate, SQLStr);
//      UpdateSQL(Daten.qUpdate, 'MDE_VER', 'Abweichung', AbweichnungSTR, 'Nr', IntToStr(Nummer));
//      UpdateSQL(Daten.qUpdate, 'MDE_VER', 'AbweichungPRZ', IntToStr(AbweichungPRZ), 'Nr', IntToStr(Nummer));

      if AbweichungPRZ > ToleranzInt then
        UpdateSQL(Daten.qUpdate, 'Maschinf', 'CO_Meldung', '1', 'Lizenz', Lizenz)
      else
        UpdateSQL(Daten.qUpdate, 'Maschinf', 'CO_Meldung', '0', 'Lizenz', Lizenz);
    end;

    if SignalKod = 2 then
    begin
      Abweichung := Includis[J].StueckSchicht - (StrToInt(Istwert));
      if Abweichung < 0 then
        Abweichung := Abweichung * -1;

      St_Schicht := Includis[J].StueckSchicht;
      if (St_Schicht = 0) then
        St_Schicht := 1;
      AbweichungPRZ := Trunc(Abweichung * 100 / St_Schicht);
      if AbweichungPRZ < 0 then
        AbweichungPRZ := AbweichungPRZ * -1;

      SQLStr := 'UPDATE mde_ver SET Sollwert = ''' +IntToStr(Includis[J].StueckSchicht)
        + ''', SollwertInt = ''' +IntToStr(Includis[J].StueckSchicht) + ''''
        + ', abweichung = ''' +AbweichnungSTR
        +  ''', AbweichungPRZ = ''' +IntToStr(AbweichungPRZ) + ''''
        + ' WHERE nr = ' + IntToStr(Nummer);
      SQL_Insert(Daten.qUpdate, SQLStr);

//      UpdateSQL(Daten.qUpdate, 'MDE_VER', 'Sollwert', IntToStr(Includis[J].StueckSchicht), 'Nr',
  //      IntToStr(Nummer));
//      UpdateSQL(Daten.qUpdate, 'MDE_VER', 'SollwertInt', IntToStr(Includis[J].StueckSchicht), 'Nr',
  //      IntToStr(Nummer));

//      UpdateSQL(Daten.qUpdate, 'MDE_VER', 'Abweichung', IntToStr(Abweichung), 'Nr', IntToStr(Nummer));
  //    UpdateSQL(Daten.qUpdate, 'MDE_VER', 'AbweichungPRZ', IntToStr(AbweichungPRZ), 'Nr',
//        IntToStr(Nummer));
    end;

    Daten.qSuch.Next;
  end;
end;

procedure CCC_Erzeuge_Arbeitsplan(Lizenz: string; MaschNr: string; Signal: string;
  Sollwert: string; Bezeichnung: string; Zustaendig: string; Vorwarnung: Boolean; VorwarnungSTR: string; BDE_Ver:
  Boolean; RoteLampeAn: Boolean);
var
  Nummer: Integer;
  WertZustand, SQLStr, Maschine: string;
  Quelle: string;
  Soll: string;
  SollP: array[0..40] of Char;
  T: TDateTime;
  IntRoteLampe: Smallint;
  NeuerJob: Smallint;
begin
  T := Jetzt;

  Quelle := '';
  Quelle := GetL('BDE');

  if RoteLampeAn then
    IntRoteLampe := 1
  else
    IntRoteLampe := 0;

  if (Signal = GetL('HEIZUNG')) then
    Quelle := GetL('System');
  if (Signal = GetL('Stückzahl Maschine')) and not BDE_Ver then
    Quelle := GetL('Produktion');
  if (Signal = GetL('Stückzahl prüfen')) and not BDE_Ver then
    Quelle := GetL('Produktion');
  if (Signal = GetL('Stückzahl gepackt')) and not BDE_Ver then
    Quelle := GetL('Produktion');
  if (Signal = GetL('VS-Poti')) and not BDE_Ver then
    Quelle := GetL('Produktion');

  if ((Signal = GetL('Stückzahl Maschine')) and not BDE_Ver) then
    if not JOBPRODUKTION then
      Exit;

  if Signal = GetL('Soll-Heizzone 1') then
    Quelle := GetL('SPC');
  if Signal = GetL('Soll-Heizzone 2') then
    Quelle := GetL('SPC');
  if Signal = GetL('Soll-Spritzdruck') then
    Quelle := GetL('SPC');
  if Signal = GetL('Soll-Nachdruck') then
    Quelle := GetL('SPC');
  if Signal = GetL('Soll-Speed') then
    Quelle := GetL('SPC');

  if Quelle = GetL('Auftragstart') then
    WertZustand := GetL('sofort erledigen');
  if Quelle = GetL('BDE') then
  begin
    if Vorwarnung then
      WertZustand := GetL('Vorwarnung')
    else
      WertZustand := GetL('sofort erledigen');
  end
  else
  begin
    if Vorwarnung then
      WertZustand := GetL('Vorwarnung')
    else
      WertZustand := GetL('Menge erfüllt');
  end;
  if (Signal = GetL('HEIZUNG')) and (Quelle = GetL('System')) then
    WertZustand := GetL('sofort erledigen');

  if Quelle = GetL('SPC') then
    WertZustand := GetL('sofort erledigen');

  NeuerJob := 1;
  //wenn vorhanden, dann löschen
  Daten.qCreateDB.Close;

  // Wenn schon vorhanden, dann nicht wieder einfügen
  if (Signal = GetL('HEIZUNG')) and (Quelle = GetL('System')) then
  begin
    SQL_Get(Daten.qUpdate, 'SELECT count(*) cnt FROM bda WHERE lizenz = ''' + Lizenz
      + ''' AND signal = ''' + Signal + '''');
    if Daten.qUpdate.FieldByName('cnt').AsInteger > 0 then
      Exit;
  end;

  if Pos(GetL('Taktzeit'), Bezeichnung) > 0 then
    if TCO_Setup.GetParamBool(Daten.qSuch3, 'INCL_TaktmeldungNichtWiederholen') then
    begin
      SQL_Get(Daten.qUpdate, 'SELECT count(*) cnt FROM bda WHERE lizenz = ''' + Lizenz
        + ''' AND signal = ''' + Signal + '''');
      if Daten.qUpdate.FieldByName('cnt').AsInteger > 0 then
        Exit;
    end;

  if (SQL2GetBool(Daten.qCreateDB, 'BDA', 'Lizenz', Lizenz, 'Bezeichnung', Bezeichnung)) then
  begin
    Nummer := Daten.qCreateDB.FieldByName('Nr').AsInteger;
    DeleteSQL(Daten.qUpdate, 'BDA', 'Nr', IntToStr(Nummer));
    NeuerJob := 0;
  end;
  Daten.qCreateDB.Close;

  Soll := Sollwert;
  StrPCopy(SollP, Soll);
  if Quelle = GetL('BDE') then
    if (StrPos(SollP, 'h') = nil) then
      Soll := Soll + ' h';

 if Signal = GetL('Soll-Takt') then
    Soll := Sollwert + ' s';

  if Length(Bezeichnung) > 198 then
    SetLength(Bezeichnung, 199);

  Maschine := CCC_GetKennung(MaschNr);

  SQLStr := 'INSERT INTO BDA (Nr,Lizenz,DatumZeit,Bezeichnung,'
    + 'Quelle,Zustaendig,Zustand,Masch_bez,Signal,Sollwert,Vorwarnung,Erledigt,RoteLampeAn,NeuerJob)'
    + 'VALUES(BDAID.NextVal'
    + ',''' + Lizenz
    + ''',' + FloatToPunktString(T)
    + ',''' + Bezeichnung
    + ''',''' + Quelle
    + ''',''' + Zustaendig
    + ''',''' + WertZustand
    + ''',''' + Maschine
    + ''',''' + Signal
    + ''',''' + Soll
    + ''',''' + VorwarnungSTR
    + ''',''' + WertZustand
    + ''',''' + IntToStr(IntRoteLampe)
    + ''',''' + IntToStr(NeuerJob)
    + ''')';
  SQL_Insert(Daten.qUpdate, SQLStr);

  if Active_Alarming then
  begin // Aktive Alarmierung bei Eintrag über PopUp
    try

      SQLStr := 'INSERT INTO alertnotification (Nr, Alertstamp, Message, Typ, Confirmation) VALUES ('
        + 'AlertNotificationId.NextVal, '
        + '''' + FloatToStr2(N_o_w) + ''', '
        + '''' + Maschine + ' : ' + Signal + '-' + WertZustand + ''',';

      if IntRoteLampe = 1 then
        SQLStr := SQLStr + IntToStr(ord(mtWarning)) + ', '
      else
        SQLStr := SQLStr + IntToStr(ord(mtInformation)) + ', ';

      SQLStr := SQLStr + '0)';
      SQL_Insert(Daten.qUpdate, SQLStr);
    except
    end;
  end;

  Daten.qCreateDB.Close;
  if (SQL2GetBool(Daten.qCreateDB, 'BDA', 'Lizenz', Lizenz, 'Bezeichnung', Bezeichnung)) then
  begin
    Nummer := Daten.qCreateDB.FieldByName('Nr').AsInteger;
    UpdateSQL(Daten.qUpdate, 'BDA', 'JobNummer', MaschNr + ' / ' + IntToStr(Nummer), 'Nr', IntToStr(Nummer));
  end;
  Daten.qCreateDB.Close;
end;

procedure CCC_MDE_Soll_Ist_Vergleich;

  function TimeOver(Zeit: TDateTime): Boolean;
  var
    Jetzt1: TDateTime;
    Wert: Real;
  begin
    Result := False;
    Jetzt1 := Frac(N_o_w);
    Wert := Jetzt1 - Zeit;
    if (Wert < 0) then
      Wert := Wert * -1;
    if (Wert) > Zeit_zum_MDEAuftrag then
      Result := True;
  end;

var
  SQLStr, Liz, Meldung: string;
  Nummer: Integer;
  ErsterFehler: TDateTime;
  Bez: string;
  pBez, pMeldung: array[0..50] of Char;
  RoteLampe: Boolean;
  FatalerFehler: Boolean;
  Soll: string;
begin
  FatalerFehler := False;
  SQLStr := 'Select * from MDE_VER where (Erzeugt = 0) AND (SPC = 0)';

  Daten.qSuch.Close;
  SQL_Get(Daten.qSuch, SQLStr);
  Daten.qSuch.First;
  while not Daten.qSuch.EOF do
  begin
    if ((ABS(Daten.qSuch.FieldByName('ToleranzINT').AsInteger) <=
      ABS(Format_String(Daten.qSuch.FieldByName('AbweichungPRZ').AsString))) or
      ( (Daten.qSuch.FieldByName('TOLERANZABSOLUTINT').AsInteger > 0) AND (Daten.qSuch.FieldByName('TOLERANZABSOLUTINT').AsInteger <
      Trunc(Daten.qSuch.FieldByName('Abweichung').AsFloat * 100))) ) then
    begin
      Bez := Daten.qSuch.FieldByName('JobBezeichnung').AsString;
      if Pos(GetL('Taktzeit'), Bez) > 0 then
        if TCO_Setup.GetParamBool(Daten.qSuch3, 'INCL_TaktmeldungNurBeiUeberschreiten') then
          if Daten.qSuch.FieldByName('sollwertint').AsInteger >
            (Daten.qSuch.FieldByName('istwertint').AsInteger / 10) then
          begin
            Daten.qSuch.Next;
            Continue;
          end;

      Nummer := Daten.qSuch.FieldByName('Nr').AsInteger;
      if (Daten.qSuch.FieldByName('ErsterFehler').AsInteger = 1) then
      begin
        ErsterFehler := Daten.qSuch.FieldByName('ErsterFehlerTime').AsDateTime;
        if TimeOver(ErsterFehler) then
        begin
          //************* Auftrag erzeugen *******************************
          Liz := Daten.qSuch.FieldByName('Lizenz').AsString;

          //Prüfen, ob Maschine läuft
          if not (CCC_GetMaschZustand(Liz) = 0) then
          begin
            SQLStr := 'UPDATE mde_ver SET Erzeugt = 0, ErsterFehler = 0 WHERE nr = ' + IntToStr(Nummer);
            SQL_Insert(Daten.qUpdate, SQLStr);

      //      UpdateSQL(Daten.qUpdate, 'MDE_VER', 'Erzeugt', '0', 'Nr', IntToStr(Nummer));
//            UpdateSQL(Daten.qUpdate, 'MDE_VER', 'ErsterFehler', '0', 'Nr', IntToStr(Nummer));
            //Exit;
          end
          else
          begin
            RoteLampe := False;
            Soll := Daten.qSuch.FieldByName('Sollwert').AsString;
            Bez := Daten.qSuch.FieldByName('JobBezeichnung').AsString;
            //Bei spezifischen Fehlern Rote Lampe anzeigen
            StrPCopy(pBez, Bez);

            Meldung := GetL('Taktzeit');
            StrPCopy(pMeldung, Meldung);
            if StrPos(pBez, pMeldung) <> nil then
              RoteLampe := True;

            Meldung := GetL('Temperatur Heizzone 1');
            StrPCopy(pMeldung, Meldung);
            if StrPos(pBez, pMeldung) <> nil then
              RoteLampe := True;

            Meldung := GetL('Temperatur Heizzone 2');
            StrPCopy(pMeldung, Meldung);
            if StrPos(pBez, pMeldung) <> nil then
              RoteLampe := True;

            Meldung := GetL('Spritzdruck');
            StrPCopy(pMeldung, Meldung);
            if StrPos(pBez, pMeldung) <> nil then
              RoteLampe := True;

            Meldung := GetL('Nachdruck');
            StrPCopy(pMeldung, Meldung);
            if StrPos(pBez, pMeldung) <> nil then
              RoteLampe := True;

            Daten.qCreateDB.Close;
            if (not SQLGetBool(Daten.qCreateDB, 'BDA', 'Bezeichnung', Bez)) then
            begin
              if RoteLampe then
                S7Main.Schreibe_SPS_Wert(0, TTT_GetSignalNr(CROTELAMPE_AUS), 1);
            end;

            try
              CCC_Erzeuge_Arbeitsplan(Liz, CCC_GetMaschNrLizenz(Liz), Daten.qSuch.FieldByName('Signal1').AsString,
                Soll, Daten.qSuch.FieldByName('JobBezeichnung').AsString,
                Daten.qSuch.FieldByName('Zustaendig').AsString, False, '', True,
                RoteLampe);
            except
            end;
            //Eintrag zurücksetzen
            SQLStr := 'UPDATE mde_ver SET Erzeugt = 0, ErsterFehler = 0 WHERE nr = ' + IntToStr(Nummer);
            SQL_Insert(Daten.qUpdate, SQLStr);
//            UpdateSQL(Daten.qUpdate, 'MDE_VER', 'Erzeugt', '0', 'Nr', IntToStr(Nummer));
  //          UpdateSQL(Daten.qUpdate, 'MDE_VER', 'ErsterFehler', '0', 'Nr', IntToStr(Nummer));
          end;
        end;
      end
      else //ErsterFehler = 1 (Toleranz das erste mal überschritten)
      begin
        SQLStr := 'UPDATE mde_ver SET ErsterFehler = 1, ErsterFehlerTime = '''
          + TimeToStr(Frac(Jetzt)) + ''' WHERE nr = ' + IntToStr(Nummer);
        SQL_Insert(Daten.qUpdate, SQLStr);
//        UpdateSQL(Daten.qUpdate, 'MDE_VER', 'ErsterFehler', '1', 'Nr', IntToStr(Nummer));
  //      UpdateSQL(Daten.qUpdate, 'MDE_VER', 'ErsterFehlerTime', TimeToStr(Frac(Jetzt)), 'Nr',
//          IntToStr(Nummer));
      end;
    end
    else
      SQL_Insert(Daten.qUpdate, 'DELETE FROM bda WHERE lizenz = '''
        + Daten.qSuch.FieldByName('Lizenz').AsString
        + ''' AND signal = ''' + Daten.qSuch.FieldByName('Signal1').AsString + '''');

    //Job innerhalb von Zeit_zum_MDEAuftrag (10 Min) wieder innerhalb Toleranz, also ErsterFehler zurücksetzten
    if ((Daten.qSuch.FieldByName('ToleranzINT').AsInteger >=
      Format_String(Daten.qSuch.FieldByName('AbweichungPRZ').AsString)) and
      (Daten.qSuch.FieldByName('ErsterFehler').AsInteger = 1)) then
    begin
      Nummer := Daten.qSuch.FieldByName('Nr').AsInteger;
      UpdateSQL(Daten.qUpdate, 'MDE_VER', 'ErsterFehler', '0', 'Nr', IntToStr(Nummer));
    end;

    Daten.qSuch.Next;
  end;
  if FatalerFehler then
    S7MainOK := False;
end;

function CCC_GetKennung(MaschNr: string): string;
var
  I: Integer;
begin
  try
    //RS 15.06.2016: Wir können doch erst einmal prüfen, ob wir nicht direkt das Element nehmen können
    try
      I := StrToInt(MaschNr);
    except
      I := 1;
    end;
    if (I <= Anzahl_Masch ) AND (Includis[I].MaschNr = MaschNr) then
    begin
      Result := Includis[I].Maschine;
      Exit;
    end;

    for I := 1 to Anzahl_Masch do
      if (Includis[I].MaschNr = MaschNr) then
        break;

    if I <= Anzahl_Masch then
      Result := Includis[I].Maschine
    else
      Result := 'error';
  except
    Result := 'error';
  end;
end;

function CCC_GetMaschIndex(Lizenz: string): Integer;
var
  I, J: Integer;
begin
  J := -1;
  for I := 1 to Anzahl_Masch do
    if (Includis[I].Lizenz = Lizenz) then
    begin
      J := I;
      break;
    end;
  Result := J;
end;

function CCC_GetMaschZustand(Lizenz: string): Integer;
var
  I: Integer;
begin
  I := CCC_GetMaschIndex(Lizenz);
  if (I = -1) then
    I := Anzahl_Masch;
  Result := Includis[I].Zustand;
end;

function CCC_GetMaschNrLizenz(Lizenz: string): string;
var
  I: Integer;
begin
  if Lizenz = '' then
  begin
    Result := '0';
    Exit;
  end;

  I := CCC_GetMaschIndex(Lizenz);
  If I < 0 then
    Result := '0'
  else
    Result := Includis[I].MaschNr;
end;

procedure CCC_AuftragAutomatikStartVariabel;
var
  I, J, RuestZeit: Integer;
  Startzeit, RuestZeitReal: Real;
  Lizenz: string;
  BetriebsauftragNr: string;
  AutostartZeit : Integer;
begin
  // Sitzt der Schalter ?
  AutostartZeit := TCO_Setup.GetParamInt(Daten.qSuch, 'INCL_AutostartZeitNachRuesten') ;
  if AutostartZeit > 0 then
  begin
    Daten.qSuch.SQL.Text := 'SELECT * FROM pde WHERE stat = '+IntToStr(stStartRuestenInt);
    Daten.qSuch.Open;
    while not Daten.qSuch.Eof do
    begin
      Lizenz := Daten.qSuch.FieldByName('Lizenz').AsString;
      BetriebsauftragNr := Daten.qSuch.FieldByName('Betriebsauftragnr').AsString;
      RuestZeit := Format_String(Daten.qSuch.FieldByName('Ruestzeit').AsString);
      Startzeit := StrToFloat(Daten.qSuch.FieldByName('StartDatumZeit').AsString);
      RuestZeitReal := RuestZeit / 1440;
      if (Jetzt > (Startzeit + RuestZeitReal)) then // Ruestzeit ist vorbei
      begin
        I := CCC_GetMaschIndex(Lizenz);
        if I <> -1 then
        begin
         if ((not Includis[I].RuestzeitVorbei) and (Includis[I].MaschZustandBeiRuesten = stLaeuftInt)) then
          begin
            Includis[I].MaschLaeuftZeit := Jetzt;
            Includis[I].RuestzeitVorbei := True;
          end;
          // Neuer Block für Autostart
          if Includis[I].RuestzeitVorbei then // Rüstzeit ist vorbei bei Laufen starten
          begin
            if (Includis[I].MaschZustandBeiRuesten = stLaeuftInt) then
            begin
              if (Jetzt > (Includis[I].MaschLaeuftZeit + AutostartZeit)) then
              begin
                //Maschine lief  Zeit_zum_AutoStart konstant, also Auftrag starten
                S7Main.S7_Auftrag.Starten(Lizenz, BetriebsauftragNr, False);
                LogUsrEvent(Daten.qSuch2,Daten.qUpdate,126, 'WSA', Betriebsauftragnr, '');
              end;
            end
            else
             // Maschine laeuft nicht, also Zeit neu einstellen
              Includis[I].MaschLaeuftZeit := Jetzt;
          end;
        end;
      end;
      Daten.qSuch.Next;
    end;
  end;
end;


procedure CCC_AuftragAutomatikStart;
var
  I, J, RuestZeit: Integer;
  Startzeit, RuestZeitReal: Real;
  Lizenz: string;
  BetriebsauftragNr: string;
begin
  if (SQLGetBool(Daten.qSuch, 'PDE', 'stat', IntToStr(stStartRuestenInt))) then
  begin
    Daten.qSuch.First;
    while not Daten.qSuch.EOF do
    begin
      Lizenz := Daten.qSuch.FieldByName('Lizenz').AsString;
      BetriebsauftragNr := Daten.qSuch.FieldByName('Betriebsauftragnr').AsString;
      RuestZeit := Format_String(Daten.qSuch.FieldByName('Ruestzeit').AsString);
      Startzeit := StrToFloat(Daten.qSuch.FieldByName('StartDatumZeit').AsString);
      RuestZeitReal := RuestZeit / 1440;
      if (Jetzt > (Startzeit + RuestZeitReal)) then
      begin
        //Ruestzeit abgelaufen -> Maschine Zeit_zum_AutoStart konstant?
        I := CCC_GetMaschIndex(Lizenz);
        if I <> -1 then
        begin

          if ((not Includis[I].RuestzeitVorbei) and (Includis[I].MaschZustandBeiRuesten = stLaeuftInt)) then
          begin
            Includis[I].MaschLaeuftZeit := Jetzt;
            Includis[I].RuestzeitVorbei := True;
          end;
          // Neuer Block für Autostart
          if Includis[I].RuestzeitVorbei then // Rüstzeit ist vorbei bei Laufen starten
          begin
            if Includis[I].MaschZustandBeiRuesten = stLaeuftInt then // Wenn Maschine läuft, starten
            begin
              S7Main.S7_Auftrag.Starten(Lizenz, BetriebsauftragNr, False);
              LogUsrEvent(Daten.qSuch2,Daten.qUpdate,126, 'WSA', Betriebsauftragnr, '');
            end
            else
              {// Maximal 10 Minuten warten und starten} if Startzeit + RuestZeitReal + Zeit_zum_AutoStart < Jetzt then
              begin
                S7Main.S7_Auftrag.Starten(Lizenz, BetriebsauftragNr, False);
                LogUsrEvent(Daten.qSuch2,Daten.qUpdate,126, 'WSA', Betriebsauftragnr, '');
              end;
          end;
          // Alter Block
                    (* Auf Wunsch von Jochen für PEPI am 15.2.2007 rausgeflogen

                    if Includis[I].RuestzeitVorbei then
                    begin
                      if (Includis[I].MaschZustandBeiRuesten = stLaeuftInt) then
                      begin
                        if (Jetzt > (Includis[I].MaschLaeuftZeit + Zeit_zum_AutoStart)) then
                        begin
                        //Maschine lief  Zeit_zum_AutoStart konstant, also Auftrag starten
                          Ret := S7Main.S7_Auftrag.Starten(Lizenz, BetriebsauftragNr, False);
                          if Ret <> 0 then
                          begin
                            CCC_Erzeuge_Arbeitsplan(Includis[I].Lizenz, Includis[I].MaschNr,
                              GetL('Auftrag Fehler'),
                              ' 1',
                              GetL('Fehler Auftrag-Start... FehlerNr: ') + IntToStr(Ret),
                              GetL('Bediener'),
                              False, '1', False, True);
                          end;
                        end;
                      end
                      else
                      // Maschine laeuft nicht, also Zeit neu einstellen
                        Includis[I].MaschLaeuftZeit := Jetzt;
                    end;
                         *)
        end;
      end;
      Daten.qSuch.Next;
    end;
  end;
end;

function CCC_GetWerkzeugNr(Schluessel: Integer): string;
begin
  Daten.qSuch4.Close;
  if SQLGetBool(Daten.qSuch4, 'WERKZEUG', 'werkzeug', IntToStr(Schluessel)) then
    Result := Daten.qSuch4.FieldByName('WerkzeugNr').AsString
  else
    Result := 'error';
end;

procedure CCC_RoteLampeCheckAus(Lizenz: string);
var
  SQLStr: string;
  Nr: Integer;
begin
  if (SQL2GetBool(Daten.qSuch, 'BDA', 'Lizenz', Lizenz, 'RoteLampeAn', '1')) then
  begin
    Daten.qSuch.First;
    while not Daten.qSuch.EOF do
    begin
      Nr := Daten.qSuch.FieldByName('Nr').AsInteger;

      //Job Archivieren
      SQLStr := 'INSERT INTO ARCHIV (Nr,Hersteller,Typ,Jobnummer,Bezeichnung,'
        + 'Masch_bez,Lizenz,Quelle,Zustaendig,Erledigt,Datum,Zeit,DatumZeit,ErledigtAm,Erledigtvon)'
        + 'VALUES(ARCHIVID.NextVal'
        + ',''' + Daten.qSuch.FieldByName('Hersteller').AsString
        + ''',''' + Daten.qSuch.FieldByName('Typ').AsString
        + ''',''' + Daten.qSuch.FieldByName('Jobnummer').AsString
        + ''',''' + Daten.qSuch.FieldByName('Bezeichnung').AsString
        + ''',''' + Daten.qSuch.FieldByName('Masch_bez').AsString
        + ''',''' + Daten.qSuch.FieldByName('Lizenz').AsString
        + ''',''' + Daten.qSuch.FieldByName('Quelle').AsString
        + ''',''' + Daten.qSuch.FieldByName('Zustaendig').AsString
        + ''',''' + Daten.qSuch.FieldByName('Erledigt').AsString
        + ''',''' + DateToStr(Daten.qSuch.FieldByName('Datum').AsDateTime)
        + ''',''' + Daten.qSuch.FieldByName('Zeit').AsString
        + ''','' '
        + ''',''' + DateToStr(Trunc(Jetzt))
        + ''',''' + GetL('Bediener Maschine')
        + ''')';

      SQL_Insert(Daten.qUpdate, SQLStr);

      DeleteSQL(Daten.qUpdate, 'BDA', 'Nr', IntToStr(Nr));
      S7Main.Schreibe_SPS_Wert(0, TTT_GetSignalNr(CROTELAMPE_AUS), 0);
      Daten.qSuch.Next;
    end;
  end;
  if SQLGetBool(Daten.qSuch, 'BDA', 'RoteLampeAn', '1') then
    S7Main.Schreibe_SPS_Wert(0, TTT_GetSignalNr(CROTELAMPE_AUS), 1);
end;

procedure CCC_Telegramm_Auswerten;
var
  Nr: Integer;
  Bar1, Bar2, Bar3: string;
begin
  try
    if SQLGetBool(Daten.qSuch4, 'TELEGRAMM', 'Neuer_Barcode', '1') then
    begin
      //Neuer Barcode eingetroffen!!
      Daten.qSuch4.First;
      while not Daten.qSuch4.EOF do
      begin
        Nr := Daten.qSuch4.FieldByName('Nr').AsInteger;

        Bar1 := Daten.qSuch4.FieldByName('Barcode1').AsString;
        Bar2 := Daten.qSuch4.FieldByName('Barcode2').AsString;
        Bar3 := Daten.qSuch4.FieldByName('Barcode3').AsString;

        if (Bar1 <> '') and (Bar2 <> '') and (Bar3 <> '') then
          CCC_Barcode_auswerten(Bar1, Bar2, Bar3);

        //Barcode quitieren...
        UpdateSQL(Daten.qUpdate, 'TELEGRAMM', 'Neuer_Barcode', '0', 'Nr', IntToStr(Nr));

        Daten.qSuch4.Next;
      end;
    end;
  except
    SQL_Insert(Daten.qUpdate, 'update TELEGRAMM set Neuer_Barcode = 0');
  end;
end;

procedure CCC_Barcode_auswerten(BC1, BC2, BC3: string);

  function CheckBarcode(bar: string): string;
  var
    I: Integer;
  begin
    for I := 0 to Length(bar) do
      if not (bar[I] in [#0, #48..#57]) then
        bar[I] := '0';
    Result := bar;
  end;

var
  Barcode: array[1..3] of string;
  MaterialB, MengeB, BedienerB: Boolean;
  I: Integer;
  Material, Bediener: string;
  Menge: Integer;
begin
  try
    Barcode[1] := CheckBarcode(BC1);
    Barcode[2] := CheckBarcode(BC2);
    Barcode[3] := CheckBarcode(BC3);
    MaterialB := False;
    Menge := 0;
    MengeB := False;
    BedienerB := False;
    for I := 1 to 3 do
    begin
      if Length(Barcode[I]) = 12 then
        Barcode[I] := '0' + Barcode[I];
      if Length(Barcode[I]) = 13 then
      begin
        MaterialB := True;
        Material := Barcode[I];
      end
      else
      begin
        if (StrToInt64(Barcode[I]) div 1000000 = 90) then
        begin //Bediener
          BedienerB := True;
          Bediener := Barcode[I];
        end;
        if StrToInt64(Barcode[I]) div 1000000 = 77 then
        begin //Menge
          MengeB := True;
          Menge := (StrToInt64(Barcode[I]) div 10000) mod 100;
        end;
      end;
    end;
    if MaterialB and MengeB and BedienerB then
    begin // Alle Barcode eingelesen ??
      CCC_Material_ausbuchen(Material, Menge, Bediener);
    end;

  except
    Exit;
  end;
end;

procedure CCC_Material_ausbuchen(MaterialEAN: string; Menge: Integer; Bedienernr: string);
var
  SQLStr: string;
  Gesamtmenge: Integer;
  Nummer: Integer;
  MaterialID: Integer;
  Materialnummer: string;
  Einheitsgewicht: Integer;
  Neue_Menge: Integer;
  Restmenge: Integer;
  Bediener: string;
  vorbuchen: Integer;
  materialstueckliste : Boolean;
begin
  try
    SQLGet(Daten.qSuch, 'BEDIENER', 'Bedienernr', Bedienernr, False);
    Bediener := Daten.qSuch.FieldByName('Name').AsString;
    SQLGet(Daten.qSuch, 'MATERIALCHARGEN', 'EANCode', MaterialEAN, False);
    Nummer := Daten.qSuch.FieldByName('Nr').AsInteger;
    MaterialID := Daten.qSuch.FieldByName('MaterialID').AsInteger;

    SQLGet(Daten.qSuch2, 'MATERIALNUMMERN', 'MaterialID', IntToStr(MaterialID), False);
    Materialnummer := Daten.qSuch2.FieldByName('Materialnummer').AsString;

    if Bedienernr = '90050008' then
      Menge := -Menge;

    SQLStr := 'Select * from MATERIALCHARGEN where MaterialID = ''' + IntToStr(MaterialID) +
      ''' AND Restmenge > 0 Order By Lieferdatum';
    SQL_Get(Daten.qSuch2, SQLStr);
    Daten.qSuch2.First;
    if Daten.qSuch2.FieldByName('EANCode').AsString = MaterialEAN then
    begin
      Einheitsgewicht := Daten.qSuch.FieldByName('Einheitsgewicht').AsInteger;
      Restmenge := Daten.qSuch.FieldByName('Restmenge').AsInteger;
      Gesamtmenge := Menge * Einheitsgewicht;
      if Gesamtmenge <= Restmenge then
      begin
        UpdateSQL(Daten.qUpdate, 'MATERIALCHARGEN', 'Restmenge', IntToStr(Restmenge - Gesamtmenge), 'Nr',
          IntToStr(Nummer));
        SQLGet(Daten.qSuch, 'MATERIALNUMMERN', 'MaterialID', IntToStr(MaterialID), False);
        Neue_Menge := Daten.qSuch.FieldByName('Bestand').AsInteger - Gesamtmenge;
        UpdateSQL(Daten.qUpdate, 'MATERIALNUMMERN', 'Bestand', IntToStr(Neue_Menge), 'MaterialID',
          IntToStr(MaterialID));
        SQLStr := 'Insert into MATERIALBUCHUNGEN' +
          ' (Nr,EANCode,Bediener,Menge,EntnahmedatumSTR,Entnahmedatum) '
          + 'VALUES (MATERIALBUCHUNGENID.nextval'
          + ',''' + MaterialEAN
          + ''',''' + Bedienernr
          + ''',''' + IntToStr(Gesamtmenge)
          + ''',''' + DateToStr(Jetzt)
          + ''',''' + FloatToStrF2(Jetzt, ffFixed, 5, 10) + ''')';
        SQL_Insert(Daten.qUpdate, SQLStr);

        vorbuchen := 0;
        SQLStr := 'SELECT materialvorbuchen, materialstueckliste FROM setup WHERE nr = 1';
        try
          SQL_Get(Daten.qSuch, SQLStr);
          if not Daten.qSuch.IsEmpty then
          begin
            vorbuchen := Daten.qSuch.FieldByName('materialvorbuchen').AsInteger;
            materialstueckliste := Daten.qSuch.FieldByName('materialstueckliste').AsInteger > 0;
          end;
        except
        end;

        if MaterialStueckliste then
        begin
          if vorbuchen > 0 then
            SQLStr := 'Select pde.Betriebsauftragnr from PDE '
              + ' left join materialstueckliste on materialstueckliste.auftragnr = pde.auftragnr'
              + ' where materialstueckliste.materialid = ''' + IntToStr(MaterialID)
              + ''' AND ((pde.STATUS <> ''' + GetL('geplant') + ''') OR (pde.STATUS = ''' + GetL('geplant')
              + ''' AND pde.startdatumzeit < ' + FloatToPunktString(Now + vorbuchen) + '))'
          else
            SQLStr := 'Select pde.Betriebsauftragnr from PDE '
              + ' left join materialstueckliste on materialstueckliste.auftragnr = pde.auftragnr'
              + ' where materialstueckliste.materialid = '''
              + IntToStr(MaterialID) + ''' AND pde.STATUS <> ''' + GetL('geplant') + '''';
        end
        else
        begin
          if vorbuchen > 0 then
            SQLStr := 'Select Betriebsauftragnr from PDE where Material = ''' + IntToStr(MaterialID)
              + ''' AND ((STATUS <> ''' + GetL('geplant') + ''') OR (STATUS = ''' + GetL('geplant')
              + ''' AND startdatumzeit < ' + FloatToPunktString(Now + vorbuchen) + '))'
          else
            SQLStr := 'Select Betriebsauftragnr from PDE where Material = '''
              + IntToStr(MaterialID) + ''' AND STATUS <> ''' + GetL('geplant') + '''';
        end;
        SQL_Get(Daten.qSuch, SQLStr);
        Daten.qSuch.First;
        while not Daten.qSuch.EOF do
        begin
          SQLStr := 'Insert into MATERIALZUOR (Nr,Betriebsauftragnr, EANCode, ts_assigned) '
            + ' VALUES (MATERIALID.nextval'
            + ',''' + Daten.qSuch.FieldByName('Betriebsauftragnr').AsString
            + ''',''' + MaterialEAN + ''',' + FloatToPunktString(Now) + ')';
          SQL_Insert(Daten.qUpdate, SQLStr);
          Daten.qSuch.Next;
        end;

(*
        if vorbuchen = 0 then
        begin
          SQLStr := 'Select Betriebsauftragnr from PDE where Material = ''' + IntToStr(MaterialID)
            + ''' AND STATUS <> ''' + GetL('geplant') + '''';
          SQL_Get(Daten.qSuch, SQLStr);
          Daten.qSuch.First;
          while not Daten.qSuch.EOF do
          begin
            SQLStr := 'Insert into MATERIALZUOR (Nr,Betriebsauftragnr, EANCode) '
              + ' VALUES (MATERIALID.nextval'
              + ',''' + Daten.qSuch.FieldByName('Betriebsauftragnr').AsString
              + ''',''' + MaterialEAN + ''')';
            SQL_Insert(Daten.qUpdate, SQLStr);
            Daten.qSuch.Next;
          end;
        end
        else
        begin
          SQLStr := 'Select Betriebsauftragnr from PDE where Material = ''' + IntToStr(MaterialID)
            + ''' AND ((STATUS <> ''' + GetL('geplant') + ''') OR (STATUS = ''' + GetL('geplant')
            + ''' AND startdatumzeit < ''' + FloatToStr2(N_o_w + vorbuchen) + '''))';
          SQL_Get(Daten.qSuch, SQLStr);
          Daten.qSuch.First;
          while not Daten.qSuch.EOF do
          begin
            SQLStr := 'Insert into MATERIALZUOR (Nr,Betriebsauftragnr, EANCode) '
              + ' VALUES (MATERIALID.nextval'
              + ',''' + Daten.qSuch.FieldByName('Betriebsauftragnr').AsString
              + ''',''' + MaterialEAN + ''')';
            SQL_Insert(Daten.qUpdate, SQLStr);
            Daten.qSuch.Next;
          end;

        end;
*)
      end
      else
        CCC_Job_erzeugen(Daten.qUpdate, Includis[1].Lizenz, GetL('Zuviel Material gebucht: ') + Materialnummer,
          'Materialverwaltung',
          'Materialbuchung', Bediener, 'Warnung', True, 0);
    end
    else
      CCC_Job_erzeugen(Daten.qUpdate, Includis[1].Lizenz, GetL('Falsche Charge gebucht: ') + Materialnummer,
        'Materialverwaltung', 'Materialbuchung', Bediener, 'Warnung', True, 0);
  except
  end;
end;

procedure CCC_Job_erzeugen(Q: TCO_Query; Lizenz, Bezeichnung, Quelle, Signal, Zustaendig,
  Status: string; Rote_lampe: Boolean; Zyklus: Integer);
var
  SQLStr: string;
  LampeZahl, Nr: Integer;
begin
  if SQL2GetBool(Q, 'BDA', 'Lizenz', Lizenz, 'Bezeichnung', Bezeichnung) then
  begin
    Nr := Q.FieldByName('Nr').AsInteger;
    UpdateSQL(Q, 'BDA', 'Datumzeit', FloatToStr2(N_o_w), 'Nr', IntToStr(Nr));
    try
{$IFNDEF INCL_MSADO}
      UpdateSQL(Q, 'BDA', 'Termin', DateToStr(Trunc(N_o_w)), 'Nr', IntToStr(Nr));
{$ENDIF}
    except
      SchreibeMeldung('DE1C93DB-1D54-44CC-A7FC-3AF9687E1D32', 0);
    end;
    Exit;
  end;

  if Length(Bezeichnung) > 198 then
    SetLength(Bezeichnung, 199);

  if Rote_lampe then
    LampeZahl := 1
  else
    LampeZahl := 0;
  SQLStr := 'INSERT INTO BDA (Nr, Lizenz, Jobnummer, Bezeichnung,'
    + ' Datumzeit, Quelle, Zustaendig, Zustand, Masch_Bez, status,'
    + ' signal, rotelampean, neuerjob) VALUES (BDAId.Nextval'
    + ',''' + Lizenz
    + ''','''
    + ''',''' + Bezeichnung
    + ''',' + FloatToPunktString(N_o_w)
    + ',''' + Quelle
    + ''',''' + Zustaendig
    + ''',''' + Status
    + ''',''' + Lizenz
    + ''',''' + Status
    + ''',''' + Signal
    + ''',''' + IntToStr(LampeZahl)
    + ''',''1'')';
  SQL_Insert(Q, SQLStr);

  if Active_Alarming then
  begin // Aktive Alarmierung bei Eintrag über PopUp
    try
      SQLStr := 'INSERT INTO alertnotification (Nr, Alertstamp, Message, Typ, Confirmation) VALUES ('
        + 'AlertNotificationId.NextVal, '
        + '''' + FloatToStr2(N_o_w) + ''', '
        + '''' + Lizenz + ' : ' + Signal + '-' + Status + ''',';

      if LampeZahl = 1 then
        SQLStr := SQLStr + IntToStr(ord(mtWarning)) + ', '
      else
        SQLStr := SQLStr + IntToStr(ord(mtInformation)) + ', ';

      SQLStr := SQLStr + '0)';
      SQL_Insert(Q, SQLStr);
    except
    end;
  end;
end;

procedure CCC_Check_TerminOrder;
var
  SQLStr: string;
  NaechsterTermin, NaechsteVorwarnung: TDateTime;
  Nr: Integer;
begin
  // Alle Vorwarnungen checken
  NaechsterTermin := 0;
  NaechsteVorwarnung := 0;
  SQLStr := 'Select * from TERMINORDER where (VWDAtumzeit <= ' + FloatToPunktString(Jetzt) +
    ') and (Erzeugt < ''1'')';
  SQL_Get(Daten.qSuch, SQLStr);
  while not Daten.qSuch.EOF do
  begin
    if not SQL3GetBool(Daten.qSuch2, 'BDA', 'Lizenz', Daten.qSuch.FieldByName('Lizenz').AsString,
      'Bezeichnung', Daten.qSuch.FieldByName('Bezeichnung').AsString, 'Status', 'Vorwarnung') then
      CCC_Job_erzeugen(Daten.qUpdate, Daten.qSuch.FieldByName('Lizenz').AsString,
        Daten.qSuch.FieldByName('Bezeichnung').AsString,
        GetL('Termin'),
        GetL('Termin'),
        Daten.qSuch.FieldByName('Zustaendig').AsString,
        'Vorwarnung',
        False, 0);
    UpdateSQL(Daten.qUpdate, 'TERMINORDER', 'Erzeugt', '1', 'Nr', Daten.qSuch.FieldByName('Nr').AsString);
    Daten.qSuch.Next;
  end;
  // Alle fälligen Termin erfassen
  SQLStr := 'Select * from TERMINORDER where (Datumzeit <= ' + FloatToPunktString(Jetzt) +
    ') and (Erzeugt < ''2'')';
  SQL_Get(Daten.qSuch, SQLStr);
  while not Daten.qSuch.EOF do
  begin
    if SQL3GetBool(Daten.qSuch2, 'BDA', 'Lizenz', Daten.qSuch.FieldByName('Lizenz').AsString, 'Bezeichnung',
      Daten.qSuch.FieldByName('Bezeichnung').AsString, 'Status', 'Vorwarnung') then
      DeleteSQL(Daten.qUpdate, 'BDA', 'Nr', Daten.qSuch2.FieldByName('Nr').AsString);

    if not SQL2GetBool(Daten.qSuch2, 'BDA', 'Lizenz', Daten.qSuch.FieldByName('Lizenz').AsString, 'Bezeichnung',
      Daten.qSuch.FieldByName('Bezeichnung').AsString) then
      CCC_Job_erzeugen(Daten.qUpdate, Daten.qSuch.FieldByName('Lizenz').AsString,
        Daten.qSuch.FieldByName('Bezeichnung').AsString,
        GetL('Termin'), GetL('Termin'), Daten.qSuch.FieldByName('Zustaendig').AsString, GetL('Termin'), False, 0)
    else
    begin
      Nr := Daten.qSuch2.FieldByName('Nr').AsInteger;
      SQLStr := 'UPDATE bda SET Datum = ''' + DateToStr(Trunc(Jetzt))
        + ''', Zeit = ''' +TimeToStr(Frac(Jetzt))
        + ''', Datumzeit = ' +FloatToPunktString(Jetzt);
{$IFNDEF INCL_MSADO}
      SQLStr := SQLStr    + ', Termin = ''' +DateToStr(Trunc(Jetzt)) + '''';
{$ENDIF}
      SQLStr := SQLStr  + ' WHERE nr = ' + IntToStr(Nr);
      SQL_Insert(Daten.qUpdate, SQLStr);

//      UpdateSQL(Daten.qUpdate, 'BDA', 'Datum', DateToStr(Trunc(Jetzt)), 'Nr', IntToStr(Nr));
  //    UpdateSQL(Daten.qUpdate, 'BDA', 'Zeit', TimeToStr(Frac(Jetzt)), 'Nr', IntToStr(Nr));
    //  UpdateSQL(Daten.qUpdate, 'BDA', 'Datumzeit', FloatToStrF2(Jetzt, ffFixed, 6, 5), 'Nr', IntToStr(Nr));
      //UpdateSQL(Daten.qUpdate, 'BDA', 'Termin', DateToStr(Trunc(Jetzt)), 'Nr', IntToStr(Nr));
      Exit;
    end;

    UpdateSQL(Daten.qUpdate, 'TERMINORDER', 'Erzeugt', '2', 'Nr', Daten.qSuch.FieldByName('Nr').AsString);

    if Daten.qSuch.FieldByName('Wiederholung').AsInteger = 1 then
    begin
      // Wiederkehrender Termin
      if Daten.qSuch.FieldByName('WiederholungsEinheit').AsString = 'Minuten' then
        NaechsterTermin := Daten.qSuch.FieldByName('Datumzeit').AsFloat +
          (Daten.qSuch.FieldByName('Wiederholungsintervall').AsInteger / 1440);
      if Daten.qSuch.FieldByName('WiederholungsEinheit').AsString = 'Stunden' then
        NaechsterTermin := Daten.qSuch.FieldByName('Datumzeit').AsFloat +
          (Daten.qSuch.FieldByName('Wiederholungsintervall').AsInteger / 24);
      if Daten.qSuch.FieldByName('WiederholungsEinheit').AsString = 'Tage' then
        NaechsterTermin := Daten.qSuch.FieldByName('Datumzeit').AsFloat +
          (Daten.qSuch.FieldByName('Wiederholungsintervall').AsInteger);
      if Daten.qSuch.FieldByName('WiederholungsEinheit').AsString = 'Wochen' then
        NaechsterTermin := Daten.qSuch.FieldByName('Datumzeit').AsFloat +
          (Daten.qSuch.FieldByName('Wiederholungsintervall').AsInteger * 7);
      if Daten.qSuch.FieldByName('WiederholungsEinheit').AsString = 'Monate' then
      begin
        NaechsterTermin := IncMonth(Daten.qSuch.FieldByName('Datumzeit').AsFloat,
          Daten.qSuch.FieldByName('Wiederholungsintervall').AsInteger);
        NaechsteVorwarnung := NaechsterTermin - (Daten.qSuch.FieldByName('Datumzeit').AsFloat -
          Daten.qSuch.FieldByName('VWDatumZeit').AsFloat);
      end;
      SQLStr := 'INSERT INTO TERMINORDER' +
        ' (Nr, Lizenz, Bezeichnung, Datum, Uhrzeit, DatumZeit, VWDatumZeit, VWZeit,'
        + ' VWEinheit, Wiederholung, Wiederholungsintervall, Wiederholungseinheit, Erzeugt, Zustaendig) '
        + 'VALUES(TERMINORDERID.NextVal'
        + ',''' + Daten.qSuch.FieldByName('Lizenz').AsString
        + ''',''' + Daten.qSuch.FieldByName('Bezeichnung').AsString
        + ''',''' + DateToStr(NaechsterTermin)
        + ''',''' + TimeToStr(NaechsterTermin)
        + ''',' + FloatToPunktString(NaechsterTermin)
        + ',' + FloatToPunktString(NaechsteVorwarnung)
        + ',''' + Daten.qSuch.FieldByName('VWZeit').AsString
        + ''',''' + Daten.qSuch.FieldByName('VWEinheit').AsString
        + ''',''1'
        + ''',''' + Daten.qSuch.FieldByName('Wiederholungsintervall').AsString
        + ''',''' + Daten.qSuch.FieldByName('Wiederholungseinheit').AsString
        + ''',''1'
        + ''',''' + Daten.qSuch.FieldByName('Zustaendig').AsString
        + ''')';
      SQL_Insert(Daten.qUpdate, SQLStr);
    end;
    DeleteSQL(Daten.qUpdate, 'TERMINORDER', 'Nr', Daten.qSuch.FieldByName('Nr').AsString);
    Daten.qSuch.Next;
  end;
end;

procedure CCC_TPM_Stillstand_Check;
var
  I, mnr: Integer;
  Lizenz, SQLStr: string;
  AFGesperrtArray : array[1..Max_ANZAHL] of Extended;

begin
DebugStage := 0;

  SQL_Get(Daten.qSuch5, 'SELECT maschid, afgesperrtbis FROM maschine');
  while not Daten.qSuch5.eof do
  begin
    mnr := Daten.qSuch5.FieldByName('maschid').AsInteger;
    if mnr < Max_Anzahl then
      AFGesperrtArray[mnr] := Daten.qSuch5.FieldByName('afgesperrtbis').AsFloat;
    Daten.qSuch5.Next;
  end;

  for I := 1 to Anzahl_Masch do
    Includis[i].CurrentStillNr := -1;

  SQLStr := 'SELECT nr, maschnr from tpm_Stillog where maschnr <=' + IntTostr(Anzahl_Masch)+ ' AND Geht = 0';
  SQL_Get(Daten.qSuch, SQLStr);
  while not Daten.qSuch.Eof do
  begin
    Includis[Daten.qSuch.FieldByName('maschnr').AsInteger].CurrentStillNr := Daten.qSuch.FieldByName('nr').AsInteger;
    Daten.qSuch.Next;
  end;

  for I := 1 to Anzahl_Masch do
  begin
DebugStage := 100 + i;

    if (Includis[I].MaschinenTyp <> 1) And not Includis[I].IstArchiviert then
    begin
      if MaschZustand[I].Zustand = Null then
        MaschZustand[I].Zustand := 0;
      if MaschZustand[I].Zustand <> -1 then
      begin
        if (not (Includis[I].Zustand = MaschZustand[I].Zustand)) and (Includis[I].Zustand <> stStartRuestenInt) then
        begin
          if not (Ruestzeit_Auftrag_FolgeAuftrag and (Includis[I].Auftrag.Stat <> stLaeuftInt)) then
          begin //Änderung des Zustandes einer Maschine
            if not Includis[i].MusternAktiv then
            begin
              Lizenz := Includis[I].Lizenz;
              if not (Lizenz = '') then
              begin
                CCC_TPM_Zustandswechsel(Includis[I].MaschNr, I, MaschZustand[I].Zustand, Includis[I].Zustand,
                  IntToStr(Includis[I].Schicht), StueckAuftragGesamt[I].Istwert, Includis[I].StueckAuftragGesamt,
                  AFGesperrtArray[i]>Jetzt);
  DebugStage := 200 + i;
              end;
            end;
          end;
         end
            // Wenn durch parallele Bedienung während Stillstand gerüste wird kann es zu Überschneidungen kommen und der Zustand nciht mehr stimmen
            // Maschine rüstet, aber keine Stillstand vorhanden. Dann doof.
         else if (Includis[i].Auftrag.Stat = stStartRuestenInt) and (Includis[i].CurrentStillNr = -1) then  // Hier muss definitiv ein offener Stillstand vorhanden sein.
         begin
            // Wenn kein Stillstand tun wir mal so als wäre der alte Zustand Maschine läuft..;-)
           CCC_TPM_Zustandswechsel(Includis[I].MaschNr, I, stLaeuftInt, Includis[I].Zustand,
               IntToStr(Includis[I].Schicht), StueckAuftragGesamt[I].Istwert, Includis[I].StueckAuftragGesamt,
               AFGesperrtArray[i]>Jetzt);
         end;
      end;
    end;
  end;



  for I := 1 to Anzahl_Masch do
  begin
DebugStage := 100 + i;

    if (Includis[I].MaschinenTyp <> 1) And not Includis[I].IstArchiviert then
    begin
      if MaschZustand[I].Zustand > 0 then
      begin
//          SQLStr := 'select Count(*) CNT from tpm_Stillog where Geht = 0 AND maschnr = ' + Includis[I].MaschNr;
//          SQL_Get(Daten.qSuch, SQLStr);
//          if Daten.qSuch.FieldByName('CNT').AsInteger = 0 then
        if Includis[i].CurrentStillNr < 0 then
          CCC_TPM_Zustandswechsel(Includis[I].MaschNr, I, -1, 0, IntToStr(Includis[I].Schicht), StueckAuftragGesamt[I].Istwert,
            Includis[I].StueckAuftragGesamt,AFGesperrtArray[i]>Jetzt);
  DebugStage := 300 + i;
      end;
    end;
  end;

  //neue Werte speichern
  for I := 1 to Anzahl_Masch do
  begin
    if Includis[I].IstArchiviert then
      Continue;
    if Includis[I].Zustand = Null then
      Includis[I].Zustand := -1;
    MaschZustand[I].Zustand := Includis[I].Zustand;
  DebugStage := 400 + i;

  end;

  //Bestimmte Stillstände buchen??
  for I := 1 to Anzahl_Masch do
  begin
    if (Includis[I].Zustand = 2) and Vorrichtung[I].Istwert And not Includis[I].IstArchiviert then //Maschine steht
    begin
      SQLStr := 'select Nr from TPM_STILLOG where MaschNr = ''' + Includis[I].MaschNr +
        ''' AND GEHT=0 AND STILLSTANDNR=1';
      SQL_Get(Daten.qSuch, SQLStr);
      Daten.qSuch.First;
  DebugStage := 500 + i;

      while not Daten.qSuch.EOF do
      begin
        //Die Fehler Nr 4 wird gebucht; Aus "TPM_STILLSTAENDE"
        UpdateSQL(Daten.qUpdate, 'TPM_STILLOG', 'STILLSTANDNR', '4', 'Nr', Daten.qSuch.FieldByName('Nr').AsString);
        Daten.qSuch.Next;
      end;
    end;
  end;

  // Autobuchung mit der Überwachungszeit
  if Still_Ueberwachungszeit then
    for I := 1 to Anzahl_Masch do
    try
      if not Includis[I].IstArchiviert then
        CCC_UeberwachungszeitBerechnen(Includis[I].Datenblock);
    except
      SchreibeMeldung('Error: calc monitoring time(' + IntToStr(Includis[I].Datenblock) + ')', 0);
    end;
end;

// Alle Rüsteinträge der letzten 10 Minuten ansehen und Arbeitsfrei korrigieren
// Pausen mit berücksichtigen

procedure CCC_CheckRuestprot_Arbeitsfrei;
var
  S: string;
  bdt, edt: Real;
  I, Zeitraum, stepper, freiraum, Pause: Integer;
  Lizenz: string;
  mgruppe: Integer;
begin
  S := 'SELECT lizenz, rueststart, CASE WHEN ruestende < 1 THEN ' + FloatToPunktString(N_o_w)
    + ' ELSE ruestende END ruestende, nr FROM ruestprot WHERE arbeitsfrei IS NULL OR ruestende < 1 OR ruestende > '
    + FloatToPunktString(N_o_w - 10 / 1440);
  SQL_Get(Daten.qSuch, S);
  while not Daten.qSuch.EOF do
  begin
    bdt := Daten.qSuch.FieldByName('rueststart').AsFloat;
    edt := Daten.qSuch.FieldByName('ruestende').AsFloat;
    if edt = 0 then
      edt := N_o_w;
    Lizenz := Daten.qSuch.FieldByName('lizenz').AsString;
    mgruppe := GetGruppe(Lizenz);
    S := 'SELECT SUM(( '
      + ' CASE WHEN'
      + ' CASE WHEN geht=0 THEN ' + FloatToPunktString(N_o_w) + ' ELSE geht END '
      + ' > ' + FloatToPunktString(edt) + ' THEN ' + FloatToPunktString(edt) + ' ELSE geht END '
      + ' - '
      + ' CASE WHEN kommt < ' + FloatToPunktString(bdt) + ' THEN ' + FloatToPunktString(bdt) + ' ELSE kommt END)*1440) '
      + ' pause FROM tpm_stillog '
      + ' WHERE maschnr = (SELECT maschid FROM maschine WHERE lizenz = ''' + Lizenz + ''') AND '
      + ' kommt < ' + FloatToPunktString(edt) + ' AND (geht > ' + FloatToPunktString(bdt) + ' OR geht = 0)'
      + ' AND stillstandnr = 7';
    SQL_Get(Daten.qSuch2, S);
    Pause := Daten.qSuch2.FieldByName('pause').AsInteger;
    // Pausenzeit in der Zeit abgrenzen und mit abziehen
    Zeitraum := Trunc((edt - bdt) * 1440);
    I := 0;
    stepper := 5;
    freiraum := 0;
    while I < Zeitraum do
    begin
      if isMomentArbeitsFrei(mgruppe, bdt + I / 1440) then
        Inc(freiraum, stepper);
      Inc(I, stepper);
    end;
    SQL_Insert(Daten.qUpdate, 'UPDATE ruestprot SET arbeitsfrei = ' + IntToStr(freiraum + Pause)
      + ' WHERE nr = ' + IntToStr(Daten.qSuch.FieldByName('nr').AsInteger));
    Daten.qSuch.Next;
  end;
end;

procedure CCC_CheckPause;
// Nachsehen ob derzeit Pause ist
// Wenn Pause ist, nachsehen ob es Stillstände gitb, die nicht gebucht sind
// Wenn Stillstände nicht gebucht wurden, dann pause (7) buchen
// Nachgucken ob Pauseeintrag in DB nicht negativ ist !!!!
var
  S: string;
  nid, stillgrund, Day: Integer;
  nur_ungebucht : Boolean;
begin
  nur_ungebucht := TCO_Setup.GetParamBool(Daten.qSuch5, 'INCL_AutoPauseNurBeiUngebuchtemStillstand');
  S := 'SELECT * FROM pause WHERE startzeit < ' + FloatToPunktString(Frac(Jetzt))
    + ' AND endzeit > ' + FloatToPunktString(Frac(Jetzt));
  SQL_Get(Daten.qSuch, S);
  while not Daten.qSuch.EOF do
  begin
    // Gucken ob heute auch als Pause aktiviert ist
    Day := DayOfTheWeek(N_o_w) - 1;
    if (Trunc(Power(2, Day)) and Daten.qSuch.FieldByName('tagesmaske').AsInteger) > 0 then
    begin
      // Welche Maschinen sind davon betroffen ?
      S := 'SELECT ts.schusszaehler, ts.prodzaehler, ts.nr nr, ts.stillstandnr stillnr FROM tpm_stillog ts LEFT JOIN maschine m ON m.maschnr=ts.maschnr '
        + ' WHERE ts.geht = 0 ';
      if nur_ungebucht then
        S := S + ' AND ts.stillstandnr in (1,2) ';
      S := S + ' AND ts.stillstandnr <> 7 AND m.werkskalendergruppe = '
        + IntToStr(Daten.qSuch.FieldByName('kalendergruppenr').AsInteger);
      // Arbeitsfrei darf nicht beachtet werden
      S := S + ' AND ts.stillstandnr <> 3';
      SQL_Get(Daten.qSuch2, S);
      while not Daten.qSuch2.EOF do
      begin
        if (not buchen_arbeitsfrei_bis) or (Daten.qSuch2.FieldByName('stillnr').AsInteger = 2) then
        begin
          // Splitten
          S := 'SELECT tpm_stillogid.nextval nid FROM dual';
          SQL_Get(Daten.qSuch3, S);
          nid := Daten.qSuch3.FieldByName('nid').AsInteger;
          S := 'UPDATE tpm_stillog SET geht = ' + FloatToPunktString(Jetzt) + ' WHERE nr = '
            + IntToStr(Daten.qSuch2.FieldByName('nr').AsInteger);
          SQL_Insert(Daten.qUpdate, S);

          S := 'UPDATE tpm_stillog SET dauer = ROUND((geht - kommt)*1440) WHERE nr = '
            + IntToStr(Daten.qSuch2.FieldByName('nr').AsInteger);
          SQL_Insert(Daten.qUpdate, S);

          S := 'SELECT * FROM tpm_stillog WHERE nr = ' + IntToStr(Daten.qSuch2.FieldByName('nr').AsInteger);
          SQL_Get(Daten.qSuch3, S);

          S := 'INSERT INTO tpm_stillog (Nr,Maschnr, Kommt, Geht, Schicht, '
            + 'StillstandNr, Reaktionszeit, Erstellungsdatum, STOERUNG, '
            + 'AutoBuchung, RUESTPROT, BetriebsAuftragNr, '
            + 'AuftragNr, Bezeichnung, Shift_Typ, KommtStr, werkzeugnr, SCHUSSZAEHLER, prodzaehler) VALUES ('
            + IntToStr(nid) + ', '''
            + Daten.qSuch3.FieldByName('Maschnr').AsString + ''', '
            + FloatToPunktString(Jetzt) + ', 0, '''
            + IntToStr(Daten.qSuch3.FieldByName('schicht').AsInteger) + ''', 7, '''
            + Daten.qSuch3.FieldByName('Reaktionszeit').AsString + ''', '
            + FloatToPunktString(Daten.qSuch3.FieldByName('Erstellungsdatum').AsFloat) + ', '''
            + Daten.qSuch3.FieldByName('STOERUNG').AsString + ''', '''
            + Daten.qSuch3.FieldByName('AutoBuchung').AsString + ''', '''
            + Daten.qSuch3.FieldByName('RUESTPROT').AsString + ''', '''
            + Daten.qSuch3.FieldByName('BetriebsAuftragNr').AsString + ''', '''
            + Daten.qSuch3.FieldByName('AuftragNr').AsString + ''', '''
            + Daten.qSuch3.FieldByName('Bezeichnung').AsString + ''', '''
            + '-'', '''
            + DateTimeToStr(Jetzt) + ''', '''
            + Daten.qSuch3.FieldByName('werkzeugnr').AsString + ''','
            + IntToStr(Daten.qSuch3.FieldByName('SCHUSSZAEHLER').AsInteger)
            + ',' + IntToStr(Daten.qSuch3.FieldByName('prodzaehler').AsInteger) + ')';
          SQL_Insert(Daten.qUpdate, S);
        end
        else
          ChangeDtCode(Daten.qUpdate,7, Daten.qSuch2.FieldByName('nr').AsInteger,  True, 'CheckPause5390');
        Daten.qSuch2.Next;
      end;
    end;
    Daten.qSuch.Next;
  end;

  // Alle Pause gebuchten Stillstände ansehen
  S := 'SELECT werkskalendergruppe,  tpm_stillog.maschnr, tpm_stillog.nr, kommt, geht FROM tpm_stillog '
    + ' LEFT JOIN maschine ON maschine.maschnr = tpm_stillog.maschnr '
    + ' WHERE stillstandnr=7 AND geht=0';
  SQL_Get(Daten.qSuch, S);
  while not Daten.qSuch.EOF do
  begin
    // Wenn denn welche gefunden sind, nachsehe, ob jetzt noch pause ist
    S := 'SELECT COUNT(*) cnt FROM pause WHERE startzeit < ' + FloatToPunktString(Frac(Jetzt))
      + ' AND endzeit > ' + FloatToPunktString(Frac(Jetzt)) + ' AND kalendergruppenr = '
      + IntToStr(Daten.qSuch.FieldByName('werkskalendergruppe').AsInteger);
    SQL_Get(Daten.qSuch2, S);
    if Daten.qSuch2.FieldByName('cnt').AsInteger = 0 then // es ist keine Pause mehr
    begin
      // Nachgucken welcher Stillstand gebucht war. Rüsten wird zurück gesetzt
      // kommt vom Stillstand darf höchstens eine minute nach dem vorherigen stillstand sein, dann alten grund buchen
      // sonst 0 buchen
      stillgrund := 1;
      S := 'SELECT * FROM tpm_stillog WHERE geht > ' + FloatToPunktString(Daten.qSuch.FieldByName('kommt').AsFloat - 1
        / 1440)
        + ' AND maschnr = ' + IntToStr(Daten.qSuch.FieldByName('maschnr').AsInteger) + ' AND stillstandnr <> 7 ';
      SQL_Get(Daten.qSuch2, S);
      if not Daten.qSuch2.IsEmpty then
        stillgrund := Daten.qSuch2.FieldByName('stillstandnr').AsInteger;

      if (stillgrund = 2) or (not buchen_arbeitsfrei_bis) then // Splitten
      begin
        S := 'UPDATE tpm_stillog SET geht = ' + FloatToPunktString(N_o_w) + ' WHERE nr = '
          + IntToStr(Daten.qSuch.FieldByName('nr').AsInteger);
        SQL_Insert(Daten.qUpdate, S);
        S := 'UPDATE tpm_stillog SET dauer = ROUND((geht - kommt)*1440) WHERE nr = '
          + IntToStr(Daten.qSuch.FieldByName('nr').AsInteger);
        SQL_Insert(Daten.qUpdate, S);
        if stillgrund=5 then
          stillgrund := 1;
        S := 'SELECT * FROM tpm_stillog WHERE nr = ' + IntToStr(Daten.qSuch.FieldByName('nr').AsInteger);
        SQL_Get(Daten.qSuch3, S);
        S := 'INSERT INTO tpm_stillog (Nr,Maschnr, Kommt, Geht, Schicht, '
          + 'StillstandNr, Reaktionszeit, Erstellungsdatum, STOERUNG, '
          + 'AutoBuchung, RUESTPROT, BetriebsAuftragNr, '
          + 'AuftragNr, Bezeichnung, Shift_Typ, KommtStr, werkzeugnr, SCHUSSZAEHLER, prodzaehler) VALUES ('
          + 'tpm_stillogid.nextval, '''
          + Daten.qSuch.FieldByName('Maschnr').AsString + ''', '
          + FloatToPunktString(Jetzt) + ', 0, '''
          + IntToStr(Daten.qSuch3.FieldByName('schicht').AsInteger) + ''', '
          + IntToStr(stillgrund) + ', '''
          + Daten.qSuch3.FieldByName('Reaktionszeit').AsString + ''', '
          + FloatToPunktString(Daten.qSuch3.FieldByName('Erstellungsdatum').AsFloat) + ', '''
          + Daten.qSuch3.FieldByName('STOERUNG').AsString + ''', '''
          + Daten.qSuch3.FieldByName('AutoBuchung').AsString + ''', '''
          + Daten.qSuch3.FieldByName('RUESTPROT').AsString + ''', '''
          + Daten.qSuch3.FieldByName('BetriebsAuftragNr').AsString + ''', '''
          + Daten.qSuch3.FieldByName('AuftragNr').AsString + ''', '''
          + Daten.qSuch3.FieldByName('Bezeichnung').AsString + ''', '''
          + '-'', '''
          + DateTimeToStr(Jetzt) + ''', '''
          + Daten.qSuch3.FieldByName('werkzeugnr').AsString + ''','
            + IntToStr(Daten.qSuch2.FieldByName('SCHUSSZAEHLER').AsInteger)
            + ',' + IntToStr(Daten.qSuch2.FieldByName('prodzaehler').AsInteger) + ')';
        SQL_Insert(Daten.qUpdate, S);
      end;
    end;
    Daten.qSuch.Next;
  end;
end;

function TTT_GetArbeitszeit_Schicht(qSuch4: TCO_Query; MaschNr: Integer; Datum: Real; Schicht: Integer): Integer;
var
  Gruppe: Integer;
  SQLStr : string;
  isfeiertag : boolean;
  
begin
  Result := GetSchichtDauer(Schicht);

  SQLStr := 'SELECT * FROM kalenderfeiertage WHERE trunc(startdate) <= ' + IntToStr(Trunc(Datum)) + ' AND trunc(enddate+1) >= ' + IntToStr(Trunc(Datum)) + ' AND active=1';
  SQL_Get(Daten.qSuch, SQLStr);
  isfeiertag := (Daten.qSuch.FieldByName('startdateshift').AsInteger <= Schicht) and (Schicht <= Daten.qSuch.FieldByName('enddateshift').AsInteger);

  if SQLGetBool(qSuch4, 'Maschine', 'Maschnr', IntToStr(MaschNr)) then
  begin
    Gruppe := qSuch4.FieldByName('WERKSKALENDERGRUPPE').AsInteger;

    if SQLGetBool(qSuch4, 'Kalender', 'DatumInt', IntToStr(Trunc(Datum))) then
    begin
      if Gruppe = 0 then
        case Schicht of
          1: Result := qSuch4.FieldByName('Schicht1').AsInteger;
          2: Result := qSuch4.FieldByName('Schicht2').AsInteger;
          3: Result := qSuch4.FieldByName('Schicht3').AsInteger;
        end;

      if Gruppe > 0 then
      try
        case Schicht of
          1: Result := qSuch4.FieldByName('GRUPPE' + IntToStr(Gruppe) + '_S1').AsInteger;
          2: Result := qSuch4.FieldByName('GRUPPE' + IntToStr(Gruppe) + '_S2').AsInteger;
          3: Result := qSuch4.FieldByName('GRUPPE' + IntToStr(Gruppe) + '_S3').AsInteger;
        end;
      except
        Result := GetSchichtDauer(Schicht);
      end;
    end;
  end;
  if isfeiertag then
    result :=0;
end;

function TTT_GetTPMSchichtZeit(Schicht: Integer; DatumZeit: Real): Real;
begin
  Result := DatumZeit;
  case Schicht of
    1: Result := Trunc(DatumZeit) + Frac(Schicht1);
    2:
      begin
        if Shift_Model <> 2 then
          Result := Trunc(DatumZeit) + Frac(Schicht2)
        else
        begin
          if (Frac(DatumZeit) < Frac(Schicht1)) and (Frac(DatumZeit) > 0) then
            Result := Trunc(DatumZeit) - 1 + Frac(Schicht2)
          else
            Result := Trunc(DatumZeit) + Frac(Schicht2);
        end;
      end;
    3:
      begin
        if (Frac(DatumZeit) < Frac(Schicht1)) and (Frac(DatumZeit) > 0) then
          Result := Trunc(DatumZeit) - 1 + Frac(Schicht3)
        else
          Result := Trunc(DatumZeit) + Frac(Schicht3)
      end;
  end;
end;

function CCC_GetTPMSchichtAnfang(Schicht: Integer; DatumZeit: Real): Real;
begin
  Result := DatumZeit;
  case Schicht of
    1: Result := Trunc(DatumZeit) + Frac(Schicht1);
    2:
      begin
        if Shift_Model <> 2 then
          Result := Trunc(DatumZeit) + Frac(Schicht2)
        else
        begin
          if Frac(DatumZeit) < Frac(Schicht1) then
            Result := Trunc(DatumZeit) - 1 + Frac(Schicht2)
          else
            Result := Trunc(DatumZeit) + Frac(Schicht2);
        end;
      end;
    3:
      begin
        if Frac(DatumZeit) < Frac(Schicht1) then
          Result := Trunc(DatumZeit) - 1 + Frac(Schicht3)
        else
          Result := Trunc(DatumZeit) + Frac(Schicht3);
      end;
  end;
end;

function TTT_GetTPMSchichtDatum(Schicht: Integer; DatumZeit: Real): Real;
begin
  Result := DatumZeit;
  case Schicht of
    1: Result := Trunc(DatumZeit) + Frac(Schicht1);
    2:
      begin
        if Shift_Model <> 2 then
          Result := Trunc(DatumZeit) + Frac(Schicht2)
        else
        begin
          if Frac(DatumZeit) < Frac(Schicht1) then
            Result := Trunc(DatumZeit) - 1 + Frac(Schicht2)
          else
            Result := Trunc(DatumZeit) + Frac(Schicht2);
        end;
      end;
    3:
      begin
        if Frac(DatumZeit) < Frac(Schicht1) then
          Result := Trunc(DatumZeit) - 1 + Frac(Schicht3)
        else
          Result := Trunc(DatumZeit) + Frac(Schicht3);
      end;
  end;
end;

procedure CCC_CheckStatusTPM_Stillog;
var
  Prod, mno, Schuss, laeuft, mustergrund: Integer;
  S, StillNr, nrstring: string;
  Bez, BANr, ANr, MNr, maxNr: string;
  dtsql : string;
  musternoption, mustert : boolean;
begin
  DebugStage := 0;

  musternoption := TCO_Setup.GetParamBool(Daten.qSuch, 'MJA_Activate_Mustern');
  if musternoption then
  begin
    SQL_Get(Daten.qsuch, 'SELECT * FROM tpm_stillstaende WHERE system_id = 6');
    if not Daten.qSuch.IsEmpty then
      mustergrund := Daten.qSuch.FieldByName('stillstandnr').AsInteger;
  end;
  S := 'select maschine.manuelle_buchung, maschinf.zustandint, maschinf.MaschNr, signal_maschine.istwert, maschinf.mustern, '
    + ' maschinf.betriebsauftragnr, maschinf.artikelnr, maschinf.mustern, maschinf.bezeichnung '
    + ' from tpm_stillog, maschinf, maschine, signal_maschine where'
    + ' tpm_stillog.maschnr = maschinf.maschnr and maschinf.maschnr = maschine.maschnr'
    + ' and ((maschinf.zustandint in (1, 2)) or (maschinf.mustern=1)) and tpm_stillog.geht <> 0 and tpm_stillog.kommt ='
    + ' (select max(tpm_stillog.kommt) from tpm_stillog where tpm_stillog.maschnr = maschinf.maschnr)'
    + ' and maschinf.maschnr = maschine.maschnr  AND maschine.oeerelevant=1 AND maschinf.pending =0'
    + ' and signal_maschine.MASCHNR=maschinf.maschnr AND signalnr = (SELECT signalnr FROM signale where signalart =20) ';

  // Das geht so nicht. Beim Splitten bekommt der neue Stillstand die höhere Nummer !!!
  // Als Referenz des letzten offenen Stillstandes muss die Kommt Zeit genommen werden
  // Martin 2.12.2004

  // Änderung in "maschinf.zustandint in (1,2)". Wenn die Maschine in Rüsten ist, erzeugen wir immer den neuen
  // nicht abgeschlosenen Stillstand (wenn der nicht vorhanden).
  // Sascha. 11.02.2005

  // 1 - rüsten, 2 - steht

  SQL_Get(Daten.qSuch, S);
  Daten.qSuch.First;
  DebugStage := 1;
  while not Daten.qSuch.EOF do
  begin
     if Daten.qSuch.FieldByName('manuelle_buchung').AsInteger <> 1 then
    begin
      // Hier kommt einen Fehler, wenn ein Auftrag zwischen "Write" und "StillstandCheck" gestartet wurde.
      //  if Daten.qSuch.FieldByName('zustandint').AsInteger = 1 then
      //    StillNr := '2'
      //  else
      //    StillNr := '1';
      mustert := Daten.qSuch.FieldByName('Mustern').AsInteger =1;
      mno := Daten.qSuch.FieldByName('MaschNr').AsInteger;
      laeuft := Daten.qSuch.FieldByName('istwert').AsInteger;

      if mustert then
      begin
        if musternoption then // Dürfte nicht passieren. Wenn doch, trotzdem nicht hier rein springen,... aus Gründen...
        begin
          // Check Stillstandsprot
          if Daten.qSuch.FieldByName('mustern').AsInteger = 1 then // Sollte der Eintrag in der Maschinf noch nicht korrekt sein, dann auf nächsten Zyklus warten
          begin
            s := 'SELECT * FROM tpm_stillog WHERE maschnr = ' + Daten.qSuch.FieldByName('MaschNr').AsString + ' AND geht < 1 AND stillstandnr =' + IntTostr(mustergrund);
            // Gibt es einen ist alles gut, sonst -> anlegen
            SQL_Get(Daten.qSuch2, S);
            if Daten.qSuch2.IsEmpty then
            begin
              // Stillstand anlegen beendet wird er von selbst.

              S := 'INSERT INTO TPM_Stillog (Nr,MaschNr,Schicht,Kommt,Stillstandnr,KommtStr,'
                + ' betriebsauftragnr, auftragnr, bezeichnung, SCHUSSZAEHLER, prodzaehler) VALUES(TPM_StillogID.Nextval'
                + ',''' + IntToStr(mno)
                + ''',''' + IntToStr(Includis[1].Schicht)
                + ''',' + FloatToPunktString(Jetzt)
                + ',''' + IntTostr(mustergrund)
                + ''',''' + DateTimeToStr(Jetzt)
                + ''',''' + Daten.qSuch.FieldByName('Betriebsauftragnr').AsString
                + ''',''' + Daten.qSuch.FieldByName('artikelnr').AsString
                + ''',''' + Daten.qSuch.FieldByName('Bezeichnung').AsString
                + ''', 0,0)';

              SQL_Insert(Daten.qUpdate, S);

              TTT_ErstelldatumEinfuegen(Daten.qUpdate, Daten.qSuch3, 10);

              TTT_InsertStillstandEvent(Daten.qUpdate, IntToStr(mno));
            end;
          end;
        end;
      end
      else
      begin
        if (laeuft = 0) or (Daten.qSuch.FieldByName('zustandint').AsInteger = 1) then
        begin
          S := 'SELECT betriebsauftragnr, auftragnr, bezeichnung, DefStillstand, Stat FROM pde WHERE lizenz = '''
            + TTT_GetMaschine(Daten.qSuch.FieldByName('MaschNr').AsInteger) + ''' AND stat in (0, 1)';
          SQL_Get(Daten.qSuch2, S);
  DebugStage := 200 + Daten.qSuch.FieldByName('MaschNr').AsInteger;

          if (not Daten.qSuch2.IsEmpty) then
          begin
            Bez := Daten.qSuch2.FieldByName('Bezeichnung').AsString;
            ANr := Daten.qSuch2.FieldByName('auftragnr').AsString;
            BANr := Daten.qSuch2.FieldByName('Betriebsauftragnr').AsString;

            if (Daten.qSuch2.FieldByName('Stat').AsInteger = 1) then
            begin
              StillNr := '2';
              if (NOT RUESTPROT_AUS_STILLSTAND ) AND RUESTGRUND then
              begin
                SQLStr := 'select rp.GRUND FROm ruestprot rp INNER JOIN TPM_STILLSTAENDE ts ON ts.stillstandnr = rp.grund WHERE (Ruestende is null OR RUESTENDE = 0) AND LIZENZ = '''
                        + TTT_GetMaschine(Daten.qSuch.FieldByName('MaschNr').AsInteger) + '''';
                SQL_Get(Daten.qSuch3, SQLStr);
                if not Daten.qSuch3.IsEmpty then
                  StillNr := Daten.qSuch3.FieldByName('grund').AsString;
              end;
            end
            else
              StillNr := '1';

            // if (Daten.qSuch.FieldByName('zustandint').AsInteger = 1)
            if (Daten.qSuch2.FieldByName('Stat').AsInteger = 1)
              and (Daten.qSuch2.FieldByName('DefStillstand').AsInteger > 2) then
              StillNr := Daten.qSuch2.FieldByName('DefStillstand').AsString;
          end
          else
          begin
            Bez := '-';
            ANr := '-';
            BANr := '-';
            StillNr := '1';
          end;
          DebugStage := 300 + Daten.qSuch.FieldByName('MaschNr').AsInteger;

          SQLStr := 'select Count(*) CNT from tpm_Stillog where maschnr = ''' + Daten.qSuch.FieldByName('MaschNr').AsString+ ''' AND Geht = 0';
          SQL_Get(Daten.qSuch2, SQLStr);
          if Daten.qSuch2.FieldByName('CNT').AsInteger = 0 then
          begin
            mno := Daten.qSuch.FieldByName('Maschnr').AsInteger;
            if ( ( mno > 0 ) and ( mno <= Anzahl_Masch ) ) then
            begin
              Schuss := StueckAuftragGesamt[mno].Istwert;
              Prod := Includis[mno].StueckAuftragGesamt;
            end
            else
            begin
              Schuss := 0;
              Prod := 0;
            end;
            S := 'INSERT INTO TPM_Stillog (Nr,MaschNr,Schicht,Kommt,Stillstandnr,KommtStr,'
              + ' betriebsauftragnr, auftragnr, bezeichnung, SCHUSSZAEHLER, prodzaehler) VALUES(TPM_StillogID.Nextval'
              + ',''' + IntToStr(mno)
              + ''',''' + IntToStr(Includis[1].Schicht)
              + ''',' + FloatToPunktString(Jetzt)
              + ',''' + StillNr
              + ''',''' + DateTimeToStr(Jetzt)
              + ''',''' + BANr
              + ''',''' + ANr
              + ''',''' + Bez
              + ''', ' + IntToStr(Schuss)
              + ',' + IntToStr(Prod) + ')';

            SQL_Insert(Daten.qUpdate, S);
            DebugStage := 400 + Daten.qSuch.FieldByName('MaschNr').AsInteger;


            TTT_ErstelldatumEinfuegen(Daten.qUpdate, Daten.qSuch3, 1);
            DebugStage := 500 + Daten.qSuch.FieldByName('MaschNr').AsInteger;

            TTT_InsertStillstandEvent(Daten.qUpdate, Daten.qSuch.FieldByName('Maschnr').AsString);
            DebugStage := 600 + Daten.qSuch.FieldByName('MaschNr').AsInteger;
          end;
        end;
      end;
    end;
    Daten.qSuch.Next;
  end;

  //****************************** Stillstandsgründe gerade ziehen **************
  if (NOT RUESTPROT_AUS_STILLSTAND ) AND RUESTGRUND then
  begin
    s := 'SELECT maschnr, grund,rueststart, betriebsauftragnr FROM ruestprot '
      + ' LEFT JOIN maschine ON maschine.lizenz=ruestprot.lizenz '
      + ' WHERE ruestende=0 AND grund > 2';
    SQL_Get(Daten.qSuch, S);
    while not Daten.qSuch.Eof do
    begin
    // Stillstand fängt +/- 2 Minuten im Abstand an wenn er anliegt
      s := 'SELECT stillstandnr, nr, betriebsauftragnr FROM tpm_stillog '
       + ' WHERE maschnr = ' + Daten.qSuch.FieldByName('maschnr').AsString
       + ' AND geht < 1 AND kommt > '
       + FloatToPunktString(Daten.qSuch.FieldbyName('rueststart').AsFloat-2/1440) + ' AND '
       + FloatToPunktString(Daten.qSuch.FieldbyName('rueststart').AsFloat+2/1440) + ' > kommt';
      SQL_Get(Daten.qSuch2, S);
      if (not Daten.qSuch2.IsEmpty) then
      begin
        if Daten.qSuch.FieldByName('grund').AsInteger <> Daten.qSuch2.FieldByName('stillstandnr').AsInteger then
        begin
          s := 'UPDATE tpm_stillog SET stillstandnr = ' + Daten.qSuch.FieldByName('grund').AsString
            + ' WHERE nr = ' + Daten.qSuch2.FieldByName('nr').AsString;
          SQL_Insert(Daten.qUpdate, S);
        end;

        if ((Daten.qSuch2.FieldByName('betriebsauftragnr').AsString = '') or (Daten.qSuch2.FieldByName('betriebsauftragnr').AsString = '-')) then
        begin
          s := 'UPDATE ts SET ts.auftragnr=pde.auftragnr, ts.betriebsauftragnr=pde.betriebsauftragnr, ts.bezeichnung=pde.bezeichnung '
           + ' FROM tpm_stillog AS ts '
           + ' INNER JOIN pde ON pde.BETRIEBSAUFTRAGNR =''' + Daten.qSuch.FieldByName('betriebsauftragnr').AsString +''' '
           + ' WHERE ts.nr=' + Daten.qSuch2.FieldByName('nr').AsString;
          SQL_Insert(Daten.qUpdate, S);

        end;
      end;


      Daten.qSuch.Next;
    end;

//    s := 'SELECT maschnr, grund,rueststart FROM ruestprot '
//      + ' LEFT JOIN maschine ON maschine.lizenz=ruestprot.lizenz '
//      + ' WHERE ruestende=0 AND grund > 2';
//    SQL_Get(Daten.qSuch, S);
  end;

  //*******************************************************************
  if TCO_Setup.GetParamBool(Daten.qSuch5, 'INCL_AfterCheckDowntime') then
  begin
    S := 'select tpm_stillog.nr nummer from tpm_stillog, maschinf where tpm_stillog.maschnr = maschinf.maschnr '
      + ' and maschinf.zustandint = 0 and (tpm_stillog.geht = 0 or tpm_stillog.geht is null) and tpm_stillog.nr = '
      + ' (select max(nr) from tpm_stillog where tpm_stillog.maschnr = maschinf.maschnr)';
    SQL_Get(Daten.qSuch, S);
    Daten.qSuch.First;
    while not Daten.qSuch.EOF do
    begin
      S := 'UPDATE tpm_stillog SET '
        + ' geht = ''' + FloatToStr2(Jetzt) + ''''
        + ', betriebsauftragnr = ''-'''
        + ', auftragnr = ''-'''
        + ', bezeichnung = ''-'''
        + ' WHERE Nr = ' + Daten.qSuch.FieldByName('Nummer').AsString;

      SQL_Insert(Daten.qUpdate, S);

      Daten.qSuch.Next;
    end;
  end;
 DebugStage := 7;

  // Beim Rüsten "Stillstand nicht gebucht" wird als "Rüsten" gebucht

  //  S := 'select tpm_stillog.Nr, maschinf.zustandint, maschinf.MaschNr from tpm_stillog, maschinf'
  //    + ' where tpm_stillog.maschnr = maschinf.maschnr and maschinf.zustandint = 1 and tpm_stillog.geht = 0'
  //    + ' and tpm_stillog.StillstandNr = 1';

  // Es gibt eine Zeitverzögerung zwischen Auftra in "Rüsten" und Maschine in "Rüsten"

  S := 'select tpm_stillog.Nr, PDE.Stat, Maschine.Lizenz'
    + ' from tpm_stillog, PDE, Maschine'
    + ' where tpm_stillog.maschnr = maschine.maschnr and Maschine.Lizenz = PDE.Lizenz'
    + ' and PDE.Stat = 1 and tpm_stillog.geht = 0 and tpm_stillog.StillstandNr = 1';
  SQL_Get(Daten.qSuch, S);
  Daten.qSuch.First;
DebugStage := 8;

  while not Daten.qSuch.EOF do
  begin
    ChangeDtCode(Daten.qUpdate, 2, Daten.qSuch.FieldByName('Nr').AsInteger, True, 'CSTS5733');
    Daten.qSuch.Next;
  end;
DebugStage := 9;



  S := 'SELECT stillstandnr, maschnr FROM tpm_stillog WHERE nr IN(SELECT max(nr) mnr FROM tpm_stillog GROUP BY maschnr)';
  Daten.qUpdate.SQL.Text := 'UPDATE maschinf SET stillstandnr = :still  WHERE maschnrint = :mnr';
  SQL_Get(Daten.qSuch2, S);
  while not Daten.qSuch2.Eof do
  begin
    //   S := 'UPDATE maschinf SET stillstandnr = ' + Daten.qSuch2.FieldByName('stillstandnr').AsString
    //    + ' WHERE maschnrint = ' + Daten.qSuch2.FieldByName('maschnr').AsString;
    Daten.qUpdate.ParamByNameAsInteger('still', Daten.qSuch2.FieldByName('stillstandnr').AsInteger);
    Daten.qUpdate.ParamByNameAsInteger('mnr', Daten.qSuch2.FieldByName('maschnr').AsInteger);
//    SQL_Insert(Daten.qUpdate, S);
  Daten.qUpdate.ExecSQL;

    Daten.qSuch2.Next;
  end;

  (*
  S := 'SELECT max(tpm_stillog.nr) mnr, maschinf.maschnr maschnr FROM maschinf '
    + ' JOIN tpm_stillog ON tpm_stillog.maschnr = maschinf.maschnr '
    + ' GROUP BY maschinf.maschnr';
  SQL_Get(Daten.qSuch, S);
  while not Daten.qSuch.EOF do
  begin
    MNr := Daten.qSuch.FieldByName('maschnr').AsString;
    maxNr := Daten.qSuch.FieldByName('mnr').AsString;

    S := 'SELECT stillstandnr FROM tpm_stillog WHERE nr = ' + maxNr;
    SQL_Get(Daten.qSuch2, S);

    S := 'UPDATE maschinf SET stillstandnr = ' + Daten.qSuch2.FieldByName('stillstandnr').AsString
      + ' WHERE maschnr = ' + MNr;
    SQL_Insert(Daten.qUpdate, S);
    Daten.qSuch.Next;
  end;
  *)

DebugStage := 10;

(*
  S := 'update maschinf set stillstandnr = '
    + ' (select stillstandnr from tpm_stillog where Nr ='
    + ' (select max(NR) from tpm_stillog where tpm_stillog.Maschnr = maschinf.maschnr))';

  SQL_Insert(Daten.qUpdate, S);
  *)
end;

procedure CCC_TPM_Zustandswechsel(MaschNr: string; Datenblock, ZustandAlt, ZustandNeu: Integer; Schicht: string; Schuss, Prod: Integer; AfGesperrt : boolean);
var
  BANr, ANr, Bez, SQLStr, Liz: string;
  StillstandsNr: Integer;
  I, Nummer, Dauer: Integer;
  DatProd: Real;
  stat : integer;
  kommt :Extended;
  ruestengefunden : boolean;
begin
  DatProd := Jetzt;
  if Frac(Jetzt) < Frac(Schicht1) then
    DatProd := DatProd - 1;
  //*********************************************


  (* RS 15.06.2016: Wir übergeben doch schon den Index "I" für das Array Includis. Da müssen wir hier doch nicht noch zwei Mal durch das Array iterieren
  Liz := TTT_GetMaschine(StrToInt(MaschNr));
  for I := 1 to Anzahl_Masch do
    if Includis[I].Lizenz = Liz then
      break;
  *)
  try
    I := Datenblock;
    Liz := Includis[I].Lizenz;
  except
    I := 1;
  end;

  // *******************************
  // * Initialisierung (Systemstart)
  // *******************************

  StillstandsNr := 1;
  if (ZustandAlt = -1) and (ZustandNeu = MaschStillStoer) then
  begin
    if (TTT_GetArbeitszeit_Schicht(Daten.qSuch4, Includis[I].Datenblock, DatProd, StrToInt(Schicht)) = 0) and (not afgesperrt) then
    begin
      StillstandsNr := 3; // Arbeitsfrei Werkspl.
    end
    else
    begin
      StillstandsNr := GetSignalStillstand(Datenblock); // Störung
      if StillstandsNr = -1 then
        StillstandsNr := 1;
      if Stoer_Gleich_Ruest then
        StillstandsNr := 2;
    end;

    SQLStr := 'UPDATE pde SET change_art=''U'' WHERE lizenz = ''' + TTT_GetMaschine(StrToInt(MaschNr)) + ''' AND stat in (0,4)';
    SQL_Insert(Daten.qUpdate, SQLStr);
    {
    Update2SQL(Daten.qUpdate, 'PDE', 'Change_Art', 'U', 'Lizenz', TTT_GetMaschine(StrToInt(MaschNr)), 'stat', '0');
    Update2SQL(Daten.qUpdate, 'PDE', 'Change_Art', 'U', 'Lizenz', TTT_GetMaschine(StrToInt(MaschNr)), 'stat', '4');
     }
    Daten.qSuch.Close;
    // Auktuelle AuftragsNr suchen
    SQLStr := 'SELECT betriebsauftragnr banr, auftragnr anr, bezeichnung bez FROM pde WHERE lizenz = ''' + Liz +
      ''' AND (stat =0 or stat =1)';
    SQL_Get(Daten.qSuch, SQLStr);
    if Daten.qSuch.IsEmpty then
    begin
      BANr := '-';
      ANr := '-';
      Bez := '-';
    end
    else
    begin
      BANr := Daten.qSuch.FieldByName('banr').AsString;
      ANr := Daten.qSuch.FieldByName('anr').AsString;
      Bez := Daten.qSuch.FieldByName('bez').AsString;
    end;
    SQLStr := 'select Count(*) CNT from tpm_Stillog where maschnr = ' + MaschNr + ' AND Geht = 0';
    SQL_Get(Daten.qSuch, SQLStr);
    if Daten.qSuch.FieldByName('CNT').AsInteger = 0 then
    begin
      if StillstandsNr <> 1 then
        SQLStr := 'INSERT INTO TPM_Stillog (Nr,MaschNr,Schicht,Kommt,Stillstandnr,KommtStr,'
          + 'Reaktionszeit, betriebsauftragnr, auftragnr, bezeichnung, SCHUSSZAEHLER, prodzaehler)'
          + ' VALUES(TPM_StillogID.Nextval'
          + ',''' + MaschNr
          + ''',''' + Schicht
          + ''',' + FloatToPunktString(Jetzt)
          + ',''' + IntToStr(StillstandsNr)
          + ''',''' + DateTimeToStr(Jetzt)
          + ''',''0'
          + ''',''' + BANr
          + ''',''' + ANr
          + ''',''' + Bez
          + ''', ' + IntToStr(Schuss)
          + ',' + IntToStr(Prod) + ')'
      else
        SQLStr := 'INSERT INTO TPM_Stillog (Nr,MaschNr,Schicht,Kommt,Stillstandnr,KommtStr,'
          + 'betriebsauftragnr, auftragnr, bezeichnung, SCHUSSZAEHLER, prodzaehler)'
          + ' VALUES(TPM_StillogID.Nextval'
          + ',''' + MaschNr
          + ''',''' + Schicht
          + ''',' + FloatToPunktString(Jetzt)
          + ',''' + IntToStr(StillstandsNr)
          + ''',''' + DateTimeToStr(Jetzt)
          + ''',''' + BANr
          + ''',''' + ANr
          + ''',''' + Bez
          + ''', ' + IntToStr(Schuss)
          + ',' + IntToStr(Prod) + ')';

      SQL_Insert(Daten.qUpdate, SQLStr);
      TTT_ErstelldatumEinfuegen(Daten.qUpdate, Daten.qSuch3, 2);
      TTT_InsertStillstandEvent(Daten.qUpdate, MaschNr);
    end;
  end;

  if (ZustandAlt = -1) and (ZustandNeu = MaschLaeuft) then
  begin
    //Maschine von Störung auf Normalbetrieb
{
    Update2SQL(Daten.qUpdate, 'PDE', 'Change_Art', 'B', 'Lizenz', MaschNr, 'stat', '0');
    Update2SQL(Daten.qUpdate, 'PDE', 'Change_Art', 'B', 'Lizenz', MaschNr, 'stat', '4');
    }
    SQLStr := 'UPDATE pde SET change_art=''B'' WHERE lizenz = ''' + TTT_GetMaschine(StrToInt(MaschNr)) + ''' AND stat in (0,4)';
    SQL_Insert(Daten.qUpdate, SQLStr);
    Daten.qSuch.Close;
    SQLStr := 'select * from tpm_Stillog where Geht = 0 AND maschnr = ' + MaschNr;
    SQL_Get(Daten.qSuch, SQLStr);
    Daten.qSuch.First;
    while not Daten.qSuch.EOF do
    begin
      Nummer := Daten.qSuch.FieldByName('Nr').AsInteger;
      Dauer := Trunc((N_o_w - Daten.qSuch.FieldByName('Kommt').AsFloat) * 1440);
      if Dauer = 0 then
        Dauer := 1;

      SQLStr := 'UPDATE tpm_Stillog SET Geht = ' +FloatToPunktString(N_o_w)
        +  ', GehtStr = ''' +DateTimeToStr(N_o_w) + ''', dauer ='+IntToStr(Dauer)+' WHERE nr = ' + IntToStr(Nummer);
      SQL_Insert(Daten.qUpdate, SQLStr);

//      UpdateSQL(Daten.qUpdate, 'tpm_Stillog', 'Geht', FloatToStr2(N_o_w), 'Nr', IntToStr(Nummer));
//      UpdateSQL(Daten.qUpdate, 'tpm_Stillog', 'GehtStr', DateTimeToStr(N_o_w), 'Nr', IntToStr(Nummer));
//      UpdateSQL(Daten.qUpdate, 'tpm_Stillog', 'dauer', IntToStr(Dauer), 'Nr', IntToStr(Nummer));
      CCC_InsertStillGehtEvent(IntToStr(Nummer));
      Daten.qSuch.Next;
    end;
    Daten.qSuch.Close;
  end;

  // ********************
  // * Störung kommt    *
  // ********************
  if (ZustandAlt = MaschLaeuft) and (ZustandNeu = MaschStillStoer) then
  begin
    if (TTT_GetArbeitszeit_Schicht(Daten.qSuch4, Includis[I].Datenblock, DatProd, StrToInt(Schicht)) = 0) and (not AfGesperrt) then
    begin
      StillstandsNr := 3; // Arbeitsfrei Werkspl.
    end
    else
    begin
      StillstandsNr := GetSignalStillstand(Datenblock); // Störung
      if StillstandsNr = -1 then
        StillstandsNr := 1;
      if Stoer_Gleich_Ruest then
        StillstandsNr := 2;
    end;
                                            {
    Update2SQL(Daten.qUpdate, 'PDE', 'Change_Art', 'U', 'Lizenz', TTT_GetMaschine(StrToInt(MaschNr)), 'stat', '0');
    Update2SQL(Daten.qUpdate, 'PDE', 'Change_Art', 'U', 'Lizenz', TTT_GetMaschine(StrToInt(MaschNr)), 'stat', '4');
       }
    SQLStr := 'UPDATE pde SET change_art=''U'' WHERE lizenz = ''' + TTT_GetMaschine(StrToInt(MaschNr)) + ''' AND stat in (0,4)';
    SQL_Insert(Daten.qUpdate, SQLStr);
    Daten.qSuch.Close;

    SQLStr := 'SELECT betriebsauftragnr banr, auftragnr anr, bezeichnung bez FROM pde WHERE lizenz = '''
      + Liz + ''' AND (stat =0 or stat =1)';
    SQL_Get(Daten.qSuch, SQLStr);
    if Daten.qSuch.IsEmpty then
    begin
      BANr := '-';
      ANr := '-';
      Bez := '-';
    end
    else
    begin
      BANr := Daten.qSuch.FieldByName('banr').AsString;
      ANr := Daten.qSuch.FieldByName('anr').AsString;
      Bez := Daten.qSuch.FieldByName('bez').AsString;
    end;

    SQLStr := 'select Count(*) CNT from tpm_Stillog where maschnr = ''' + MaschNr + ''' AND Geht = 0';
    SQL_Get(Daten.qSuch, SQLStr);
    if Daten.qSuch.FieldByName('CNT').AsInteger = 0 then
    begin
      if StillstandsNr <> 1 then
        SQLStr := 'INSERT INTO TPM_Stillog (Nr,MaschNr,Schicht,Kommt,Stillstandnr,KommtStr,'
          + 'Reaktionszeit, betriebsauftragnr, auftragnr, bezeichnung, SCHUSSZAEHLER, prodzaehler)'
          + ' VALUES(TPM_StillogID.Nextval'
          + ',''' + MaschNr
          + ''',''' + Schicht
          + ''',' + FloatToPunktString(Jetzt)
          + ',''' + IntToStr(StillstandsNr)
          + ''',''' + DateTimeToStr(Jetzt)
          + ''',''0'
          + ''',''' + BANr
          + ''',''' + ANr
          + ''',''' + Bez
          + ''', ' + IntToStr(Schuss)
          + ',' + IntToStr(Prod) + ')'

      else
        SQLStr := 'INSERT INTO TPM_Stillog (Nr,MaschNr,Schicht,Kommt,Stillstandnr,KommtStr,'
          + 'betriebsauftragnr, auftragnr, bezeichnung, SCHUSSZAEHLER, prodzaehler)'
          + ' VALUES(TPM_StillogID.Nextval'
          + ',''' + MaschNr
          + ''',''' + Schicht
          + ''',' +      FloatToPunktString(Jetzt)
          + ',''' + IntToStr(StillstandsNr)
          + ''',''' + DateTimeToStr(Jetzt)
          + ''',''' + BANr
          + ''',''' + ANr
          + ''',''' + Bez
          + ''', ' + IntToStr(Schuss)
          + ',' + IntToStr(Prod) + ')';
          

      SQL_Insert(Daten.qUpdate, SQLStr);
      TTT_ErstelldatumEinfuegen(Daten.qUpdate, Daten.qSuch3, 3);
      TTT_InsertStillstandEvent(Daten.qUpdate, MaschNr);
    end;
  end;

  // ********************
  // * Rüsten  kommt    *
  // ********************
  if (ZustandAlt = MaschLaeuft) and (ZustandNeu = MaschRuesten) then
  begin
    StillstandsNr := -1; // Rüsten
    ruestengefunden := false;
    if (not RUESTPROT_AUS_STILLSTAND) AND RUESTGRUND then
    begin
      SQLStr := 'SELECT GRUND FROm ruestprot rp INNER JOIN TPM_STILLSTAENDE ts ON ts.stillstandnr = rp.grund '
        + ' WHERE (rp.Ruestende is null OR rp.RUESTENDE = 0) AND rp.LIZENZ = ''' + Liz + '''';
      SQL_Get(Daten.qSuch, SQLStr);
      if not Daten.qSuch.IsEmpty then
      begin
        StillstandsNr := Daten.qSuch.FieldByName('grund').AsInteger;
        ruestengefunden := true;
      end;
    end;
                             {
    Update2SQL(Daten.qUpdate, 'PDE', 'Change_Art', 'U', 'Lizenz', MaschNr, 'stat', '0');
    Update2SQL(Daten.qUpdate, 'PDE', 'Change_Art', 'U', 'Lizenz', MaschNr, 'stat', '4');
  }
    SQLStr := 'UPDATE pde SET change_art=''U'' WHERE lizenz = ''' + TTT_GetMaschine(StrToInt(MaschNr)) + ''' AND stat in (0,4)';
    SQL_Insert(Daten.qUpdate, SQLStr);
    Daten.qSuch.Close;

    SQLStr := 'SELECT betriebsauftragnr banr, auftragnr anr, bezeichnung bez, stat FROM pde WHERE lizenz = ''' + Liz +
      ''' AND (stat =0 or stat =1)';
    SQL_Get(Daten.qSuch, SQLStr);
    if Daten.qSuch.IsEmpty then
    begin
      BANr := '-';
      ANr := '-';
      Bez := '-';
      stat := -1;
    end
    else
    begin
      BANr := Daten.qSuch.FieldByName('banr').AsString;
      ANr := Daten.qSuch.FieldByName('anr').AsString;
      Bez := Daten.qSuch.FieldByName('bez').AsString;
      stat := Daten.qSuch.FieldByName('stat').AsInteger;
    end;

    SQLStr := 'select Count(*) CNT from tpm_Stillog where maschnr = ''' + MaschNr + ''' AND Geht = 0';
    SQL_Get(Daten.qSuch, SQLStr);
    if Daten.qSuch.FieldByName('CNT').AsInteger = 0 then
    begin
      // Änderung 10.2.22 ML, wenn kein offener Eintrag Rüsten im Rüstprot vorhanden ist und Maschine in Zustand rüsten,
      // stimmt dies nicht und führt zu falschen Einträgen im SchichtProt
      if ((stat = 1)and (ruestengefunden)) or ((StillstandsNr <> 2) AND (Stillstandsnr >-1)) then // Wenn Stillstandnr = -1 ist Status unklar und wird beim nächsten Durchlauf noch mal analysiert.
      begin
        SQLStr := 'INSERT INTO TPM_Stillog (Nr,MaschNr,Schicht,Kommt,Stillstandnr,KommtStr,'
          + 'Reaktionszeit, betriebsauftragnr, auftragnr, bezeichnung, SCHUSSZAEHLER, prodzaehler)'
          + ' VALUES(TPM_StillogID.Nextval'
          + ',''' + MaschNr
          + ''',''' + Schicht
          + ''',' + FloatToPunktString(Jetzt)
          + ',''' + IntToStr(StillstandsNr)
          + ''',''' + DateTimeToStr(Jetzt)
          + ''',''0'
          + ''',''' + BANr
          + ''',''' + ANr
          + ''',''' + Bez
          + ''', ' + IntToStr(Schuss)
          + ',' + IntToStr(Prod) + ')';


        SQL_Insert(Daten.qUpdate, SQLStr);
        TTT_ErstelldatumEinfuegen(Daten.qUpdate, Daten.qSuch3, 4);
        TTT_InsertStillstandEvent(Daten.qUpdate, MaschNr);
      end;
    end;
  end;

  // **********************
  // * Störung/Rüsten geht*
  // **********************
  if (ZustandAlt = MaschStillStoer) and (ZustandNeu = MaschLaeuft)
    or (ZustandAlt = MaschRuesten) and (ZustandNeu = MaschLaeuft) then
  begin

    //Maschine von Störung auf Normalbetrieb
    {
    Update2SQL(Daten.qUpdate, 'PDE', 'Change_Art', 'B', 'Lizenz', MaschNr, 'stat', '0');
    Update2SQL(Daten.qUpdate, 'PDE', 'Change_Art', 'B', 'Lizenz', MaschNr, 'stat', '4');
  }
    SQLStr := 'UPDATE pde SET change_art=''B'' WHERE lizenz = ''' + TTT_GetMaschine(StrToInt(MaschNr)) + ''' AND stat in (0,4)';
    SQL_Insert(Daten.qUpdate, SQLStr);
    Daten.qSuch.Close;
    SQLStr := 'select * from tpm_Stillog where Geht = 0 AND maschnr = ' + MaschNr;
    SQL_Get(Daten.qSuch, SQLStr);
    Daten.qSuch.First;
    while not Daten.qSuch.EOF do
    begin
      Nummer := Daten.qSuch.FieldByName('Nr').AsInteger;
      kommt := Daten.qSuch.FieldByName('Kommt').AsFloat;
      Dauer := Trunc((N_o_w - kommt) * 1440);

      if Dauer = 0 then
        Dauer := 1;

      SQLStr := 'UPDATE tpm_Stillog SET Geht = ' +FloatToPunktString(N_o_w)
        +  ', GehtStr = ''' +DateTimeToStr(N_o_w) + ''', dauer ='+IntToStr(Dauer)+' WHERE nr = ' + IntToStr(Nummer);
      SQL_Insert(Daten.qUpdate, SQLStr);
      CCC_InsertStillGehtEvent(IntToStr(Nummer));

      Daten.qSuch.Next;
    end;
    Daten.qSuch.Close;
  end;

  // **********************
  // * Störung wird Rüsten*
  // **********************
  if (ZustandAlt = MaschStillStoer) and (ZustandNeu = MaschRuesten) then
  begin
    Daten.qSuch.Close;
    SQLStr := 'select * from tpm_stillog where (Geht = 0)AND(maschnr = ''' + MaschNr + ''')';
    SQL_Get(Daten.qSuch, SQLStr);
    Daten.qSuch.First;
    while not Daten.qSuch.EOF do
    begin
      Nummer := Daten.qSuch.FieldByName('Nr').AsInteger;
      StillstandsNr := 2; // Rüsten

      UpdateSQL(Daten.qUpdate, 'tpm_Stillog', 'Stillstandnr', IntToStr(StillstandsNr), 'Nr', IntToStr(Nummer));

      Daten.qSuch.Next;
    end;

    //Rüsten erzeugen
    Daten.qSuch.Close;
    SQLStr := 'select Count(*) CNT from tpm_Stillog where maschnr = ''' + MaschNr + ''' AND Geht = 0';
    SQL_Get(Daten.qSuch, SQLStr);
    if Daten.qSuch.FieldByName('CNT').AsInteger = 0 then
    begin

      SQLStr := 'INSERT INTO TPM_Stillog (Nr,MaschNr,Schicht,Kommt,Stillstandnr,KommtStr, SCHUSSZAEHLER, prodzaehler)'
        + ' VALUES(TPM_StillogID.Nextval'
        + ',''' + MaschNr
        + ''',''' + Schicht
        + ''',' + FloatToPunktString(Jetzt)
        + ',''' + IntToStr(StillstandsNr)
        + ''',''' + DateTimeToStr(Jetzt)
        + ''', ' + IntToStr(Schuss)
          + ',' + IntToStr(Prod) + ')';
        
      SQL_Insert(Daten.qUpdate, SQLStr);
      TTT_ErstelldatumEinfuegen(Daten.qUpdate, Daten.qSuch3, 5);
      TTT_InsertStillstandEvent(Daten.qUpdate, MaschNr);
    end;
  end;

  if Stoer_Gleich_Ruest then
  begin
     Daten.qSuch2.SQL.Text := 'SELECT ts.NR, mi.BETRIEBSAUFTRAGNR, mi.LIZENZ, mi.WERKZEUG, mi.ARTIKELNR, s.stillstand, mi.stueck, s2.stillstand alterstillstand'
      + ' FROM TPM_STILLOG  ts'
      + ' LEFT JOIN MASCHINE m ON m.maschnr = ts.maschnr'
      + ' LEFT JOIN MASCHINF mi ON m.lizenz = mi.lizenz'
      + ' LEFT JOIN TPM_STILLSTAENDE s ON s.STILLSTANDNR = 2'
      + ' LEFT JOIN TPM_STILLSTAENDE s2 ON s2.stillstandnr = ts.stillstandnr'
      + ' WHERE ts.StillstandNr = 1 ';
    Daten.qSuch2.Open;
    while not Daten.qSuch2.EOF do
    begin
      Nummer := Daten.qSuch2.FieldByName('nr').AsInteger;
      ChangeDtCode(Daten.qUpdate, 2, Nummer, Daten.qSuch2, 'TZ6130');
      Daten.qSuch2.Next;
    end;
  end;
end;

procedure CCC_TPM_Signalauswertung;
var
  I, J: Integer;
begin
  for I := 1 to Anzahl_Masch do
  begin
    if Includis[I].IstArchiviert then
      Continue;  
    for J := 0 to Length(IndivStillstand[I].Istwert) - 1 do
    begin
      if IndivStillstand[I].Istwert[J] <> IndivStillstand[I].Istwert_alt[J] then
      begin
        case GetAktion(IndivStillstand[I].Stillstand[J]) of
          saStoerung:
            begin
            end;
          saJob:
            begin
            end;
          saHinweis:
            begin
            end;
        end;
      end;
    end;
  end;
end;

procedure CCC_FehlerNr_auswertung;
var
  I, J: Integer;
  Status, Ursache, Wirkung: string;
  First: Boolean;
begin
  for I := 1 to Anzahl_Masch do
  begin
    for J := 0 to Length(FehlerNr[I].Istwert) - 1 do
    begin
      if Includis[I].IstArchiviert then
        Continue; 

      //Prüfen, ob Fehler ansteht...
      if (FehlerNr[I].Istwert[J] > 0) and (FehlerNr[I].Istwert[J] <> FehlerNr[I].Istwert_alt[J]) then
      begin
        //Fehler gekommen

        if J = 0 then //Erster Fehler!!
        begin
          Status := GetL('Ersterfehler');
          Ursache := GetL('Fehler: ');
          Wirkung := GetL('Anlagenausfall');
          First := True;
        end
        else
        begin
          Status := GetL('Folgefehler');
          Ursache := GetL('Fehler: ');
          Wirkung := GetL('Anlagenausfall');
          First := False;
        end;

        if FehlerNr[I].Istwert[J] <> 9999 then
          CCC_Schreibe_Signallog(True, First, FehlerNr[I].Istwert[J], IntToStr(Includis[I].Schicht), Status, Ursache,
            Wirkung, Includis[I].MaschNr)
      end;

      if (FehlerNr[I].Istwert[J] = 0) and (FehlerNr[I].Istwert[J] <> FehlerNr[I].Istwert_alt[J]) then
      begin
        //Fehler gegangen

        if J = 0 then //Erster Fehler!!
        begin
          Status := GetL('Ersterfehler');
          Ursache := GetL('Fehler: ');
          Wirkung := GetL('Anlagenausfall');
          First := True;
        end
        else
        begin
          Status := GetL('Folgefehler');
          Ursache := GetL('Fehler: ');
          Wirkung := GetL('Anlagenausfall');
          First := False;
        end;

        CCC_Schreibe_Signallog(False, First, FehlerNr[I].Istwert_alt[J], IntToStr(Includis[I].Schicht), Status,
          Ursache,
          Wirkung, Includis[I].MaschNr)
      end;
      FehlerNr[I].Istwert_alt[J] := FehlerNr[I].Istwert[J];
    end;
  end;
end;

procedure CCC_FehlerNr_Check;
var
  I, J, FNr: Integer;
  Status, Ursache, Wirkung: string;
  Gefunden, First: Boolean;
begin
  SQLStr := 'select * from tpm_Signallog where Geht = 0';
  SQL_Get(Daten.qSuch2, SQLStr);
  Daten.qSuch2.First;
  while not Daten.qSuch2.EOF do
  begin
    I := Daten.qSuch2.FieldByName('MaschNr').AsInteger;
    FNr := Daten.qSuch2.FieldByName('FehlerNr').AsInteger;
    Gefunden := False;
    First := False;
    for J := 0 to Length(FehlerNr[I].Istwert) - 1 do
    begin
      if FehlerNr[I].Istwert[J] = FNr then
        Gefunden := True;
    end;
    if not Gefunden then
      CCC_Schreibe_Signallog(False, First, FNr, IntToStr(Includis[I].Schicht), Status, Ursache, Wirkung, IntToStr(I));
    Daten.qSuch2.Next;
  end;
end;

procedure CCC_Schreibe_Signallog(Kommt: Boolean; First: Boolean; FehlerNr: Integer; Schicht: string; Status: string;
  Ursache: string; Wirkung: string; MaschNr: string);
var
  Nummer: Integer;
  Dauer: Integer;
  FirstStr: string;
begin
  if Kommt then
  begin

    if First then
      FirstStr := '1'
    else
      FirstStr := '0';
    // Signalflanke gekommen
    SQLStr := 'select Count(*) CNT from tpm_Signallog where FehlerNr = ''' + IntToStr(FehlerNr) + ''' AND Geht = 0';
    SQL_Get(Daten.qSuch, SQLStr);
    if Daten.qSuch.FieldByName('CNT').AsInteger = 0 then
    begin
      SQLStr := 'INSERT INTO TPM_Signallog (Nr,kommt,Geht,Schicht,StillstandNr,FEHLERNR , Status,Ursache, Wirkung, Dauer,ERSTERFEHLER, MASCHNR )'
        + ' VALUES(TPM_SignallogID.Nextval'
        + ',''' + FloatToStr2(Jetzt)
        + ''',''0'
        + ''',''' + Schicht
        + ''',''' + IntToStr(0)
        + ''',''' + IntToStr(FehlerNr)
        + ''',''' + Status
        + ''',''' + Ursache
        + ''',''' + Wirkung
        + ''',''0'
        + ''',''' + FirstStr
        + ''',''' + MaschNr
        + ''')';
      SQL_Insert(Daten.qUpdate, SQLStr);
    end;
  end
  else
  begin
    // Signalflanke abgefallen
    SQLStr := 'select * from tpm_Signallog where FehlerNr = ''' + IntToStr(FehlerNr) + ''' AND Geht = 0';
    SQL_Get(Daten.qSuch, SQLStr);
    Daten.qSuch.First;
    while not Daten.qSuch.EOF do
    begin
      Nummer := Daten.qSuch.FieldByName('Nr').AsInteger;
      Dauer := Trunc((Jetzt - Daten.qSuch.FieldByName('Kommt').AsFloat) * 1440);
      if Dauer = 0 then
        Dauer := 1;

      SQLStr := 'UPDATE tpm_Signallog SET Geht = ' +FloatToPunktString(Jetzt)
        +  ', GehtStr = ''' +DateTimeToStr(Jetzt) + ''', dauer ='+IntToStr(Dauer)+' WHERE nr = ' + IntToStr(Nummer);
      SQL_Insert(Daten.qUpdate, SQLStr);
//      UpdateSQL(Daten.qUpdate, 'tpm_Signallog', 'Geht', FloatToStr2(Jetzt), 'Nr', IntToStr(Nummer));
//      UpdateSQL(Daten.qUpdate, 'tpm_Signallog', 'dauer', IntToStr(Dauer), 'Nr', IntToStr(Nummer));
      Daten.qSuch.Next;
    end;
  end;
end;

procedure CCC_Auftrag_Start_Barcode(BarCodeNr: Byte); //BarcodeNr = 1, 2 oder 3
var
  Maschine: string;
  I, ret_Ende: Integer;
  ret_start: Integer;

  Eigenschaft, Name: string;
  Status: string;
  Masch: string;
  MaschNr: Integer;
  Gefunden: Boolean;
  Nummer, Dauer: Integer;
  EAN: string;
  Tmp: string;
  PersNr: Integer;
  SQLStr: string;
  Auft, Job_Meldung: string;
  PDENr: Integer;
begin
  Job_Meldung := GetL('Fehler bei Auftragstart über Barcode... Auftrag:');

  case BarCodeNr of
    1:
      if not Barcode_Gelesen.Istwert then
        Exit;
    2:
      if not Barcode_Gelesen_2.Istwert then
        Exit;
    3:
      if not Barcode_Gelesen_3.Istwert then
        Exit;
  end;

  //Diese Funktion wurde für das Project Gehr entwickelt:
  //Die Funktion wird aufgerufen, wenn das Modul "Auftragstart_Barcode" aktiv ist.
  //Es wird zunächst der Barcode analysiert: es kann entweder eine
  //Auftragnr eines zu startenden Auftrages sein (a), oder eine Personalnr
  //eines Mittabeiters (b), oder eine Personalnr eines Mitarbeiters für eine Raparatur (c).

  //Im Fall (a) wird der Auftrag gestartet (geg. ein laufender Auftrag zunächst beendet)
  //Im Fall (b) wird ein Protokolleintrag in der Tabelle "Personalanmeldung erzeugt
  //Im Fall (c) wird ein Protokolleintrag in der tabelle "Reparaturanmeldung" erzeugt

  //Es werden insgesamt 3 Barcodes gelesen

  EAN := '';
  for I := 1 to MAX_BARCODE do
  begin
    case BarCodeNr of
      1: EAN := EAN + IntToStr(Barcode[I].Istwert);
      2: EAN := EAN + IntToStr(Barcode_2[I].Istwert);
      3: EAN := EAN + IntToStr(Barcode_3[I].Istwert);
    end;
  end;

  //PersonalNr filtern
  MaschNr := 0;
  Tmp := '';
  Auft := '';
  case BarCodeNr of
    1:
      begin
        Tmp := Tmp + IntToStr(Barcode[8].Istwert);
        Tmp := Tmp + IntToStr(Barcode[9].Istwert);
        Tmp := Tmp + IntToStr(Barcode[10].Istwert);
        Tmp := Tmp + IntToStr(Barcode[11].Istwert);
        Tmp := Tmp + IntToStr(Barcode[12].Istwert);

        Auft := Auft + IntToStr(Barcode[5].Istwert);
        Auft := Auft + IntToStr(Barcode[6].Istwert);
        Auft := Auft + IntToStr(Barcode[7].Istwert);
        Auft := Auft + IntToStr(Barcode[8].Istwert);
        Auft := Auft + IntToStr(Barcode[9].Istwert);
        Auft := Auft + IntToStr(Barcode[10].Istwert);

        if Barcode[11].Istwert = 0 then
          Auft := Auft + 'L'
        else
          Auft := Auft + 'K';

        MaschNr := AuftragStart1.Istwert;
      end;
    2:
      begin
        Tmp := Tmp + IntToStr(Barcode_2[8].Istwert);
        Tmp := Tmp + IntToStr(Barcode_2[9].Istwert);
        Tmp := Tmp + IntToStr(Barcode_2[10].Istwert);
        Tmp := Tmp + IntToStr(Barcode_2[11].Istwert);
        Tmp := Tmp + IntToStr(Barcode_2[12].Istwert);

        Auft := Auft + IntToStr(Barcode_2[5].Istwert);
        Auft := Auft + IntToStr(Barcode_2[6].Istwert);
        Auft := Auft + IntToStr(Barcode_2[7].Istwert);
        Auft := Auft + IntToStr(Barcode_2[8].Istwert);
        Auft := Auft + IntToStr(Barcode_2[9].Istwert);
        Auft := Auft + IntToStr(Barcode_2[10].Istwert);

        if Barcode_2[11].Istwert = 0 then
          Auft := Auft + 'L'
        else
          Auft := Auft + 'K';

        MaschNr := AuftragStart2.Istwert;
      end;
    3:
      begin
        Tmp := Tmp + IntToStr(Barcode_3[8].Istwert);
        Tmp := Tmp + IntToStr(Barcode_3[9].Istwert);
        Tmp := Tmp + IntToStr(Barcode_3[10].Istwert);
        Tmp := Tmp + IntToStr(Barcode_3[11].Istwert);
        Tmp := Tmp + IntToStr(Barcode_3[12].Istwert);

        Auft := Auft + IntToStr(Barcode_3[5].Istwert);
        Auft := Auft + IntToStr(Barcode_3[6].Istwert);
        Auft := Auft + IntToStr(Barcode_3[7].Istwert);
        Auft := Auft + IntToStr(Barcode_3[8].Istwert);
        Auft := Auft + IntToStr(Barcode_3[9].Istwert);
        Auft := Auft + IntToStr(Barcode_3[10].Istwert);

        if Barcode_3[11].Istwert = 0 then
          Auft := Auft + 'L'
        else
          Auft := Auft + 'K';

        MaschNr := AuftragStart3.Istwert;
      end;
  end;
  PersNr := StrToInt(Tmp);

  //******************

  Eigenschaft := 'unbekannter Barcode...';
  Status := '';

  if SQLGetBool(Daten.qSuch, 'PDE', 'BETRIEBSAUFTRAGNR', Auft) then
  begin
    //********************************************
    // Barcode beinhaltet Fall (a)
    //********************************************
    PDENr := Daten.qSuch.FieldByName('Nr').AsInteger;

    ret_Ende := 0;

    //Prüfen, ob ein anderer Auftrag auf der gewählten Maschine läuft
    Maschine := Daten.qSuch.FieldByName('Lizenz').AsString;

    //Prüfen, ob Auftrag auf der geplanten Maschine laufen soll
    Gefunden := False;
    if MaschNr > 0 then
    begin
      for I := 1 to Anzahl_Masch do
        if Includis[I].InventarNr = MaschNr then
        begin
          Gefunden := True;
          break;
        end;

      if Gefunden then
      begin
        //es wurde eine Maschnr am Terminal eingegeben...
        if Includis[I].Lizenz <> Maschine then
        begin
          //Der Auftrag soll auf einer anderen Maschine als geplant laufen..., also umbuchen
          UpdateSQL(Daten.qUpdate, 'PDE', 'LIZENZ', Includis[I].Lizenz, 'Nr', IntToStr(PDENr));
          UpdateSQL(Daten.qUpdate, 'PDE', 'CHANGE_ART', 'P', 'Nr', IntToStr(PDENr));
          Maschine := Includis[I].Lizenz;
        end;
      end;

    end;

    if SQL2GetBool(Daten.qSuch, 'PDE', 'LIZENZ', Maschine, 'stat', IntToStr(stLaeuftInt)) then
    begin
      //ein anderer Auftrag läuft auf der Maschine, also laufenden Auftrag beenden
      if Daten.qSuch.FieldByName('BETRIEBSAUFTRAGNR').AsString = Auft then
      begin
        case BarCodeNr of
          1:
            begin
              S7Main.Schreibe_SPS_Wert(0, TTT_GetSignalNr(CBARCODE_GELESEN), 0);
              UpdateSQL(Daten.qSuch, 'Signal_Maschine', 'Istwert', '0', 'nr', IntToStr(Barcode_Gelesen.DBNr));
            end;
          2:
            begin
              S7Main.Schreibe_SPS_Wert(0, TTT_GetSignalNr(CBARCODE_GELESEN_2), 0);
              UpdateSQL(Daten.qSuch, 'Signal_Maschine', 'Istwert', '0', 'nr', IntToStr(Barcode_Gelesen_2.DBNr));
            end;
          3:
            begin
              S7Main.Schreibe_SPS_Wert(0, TTT_GetSignalNr(CBARCODE_GELESEN_3), 0);
              UpdateSQL(Daten.qSuch, 'Signal_Maschine', 'Istwert', '0', 'nr', IntToStr(Barcode_Gelesen_3.DBNr));
            end;
        end;
        Exit;
      end;

      SQLStr := ' SELECT betriebsauftragnr FROM maschinf WHERE lizenz = ''' + Includis[I].Lizenz + '''';
      SQL_Get(Daten.qSuch, SQLStr);
      if not Daten.qSuch.IsEmpty then
        LogUsrEvent(Daten.qSuch2, Daten.qUpdate, 129, 'WFA', Daten.qSuch.FieldByName('betriebsauftragnr').AsString, '');

      ret_Ende := S7Main.S7_Auftrag.Beenden(Maschine);
    end
    else
      if SQL2GetBool(Daten.qSuch, 'PDE', 'LIZENZ', Maschine, 'stat', IntToStr(stStartRuestenInt)) then
      begin
        //ein anderer Auftrag läuft auf der Maschine (Rüsten), also Auftrag beenden
        if Daten.qSuch.FieldByName('BETRIEBSAUFTRAGNR').AsString = Auft then
        begin
          case BarCodeNr of
            1:
              begin
                S7Main.Schreibe_SPS_Wert(0, TTT_GetSignalNr(CBARCODE_GELESEN), 0);
                UpdateSQL(Daten.qSuch, 'Signal_Maschine', 'Istwert', '0', 'nr', IntToStr(Barcode_Gelesen.DBNr));
              end;
            2:
              begin
                S7Main.Schreibe_SPS_Wert(0, TTT_GetSignalNr(CBARCODE_GELESEN_2), 0);
                UpdateSQL(Daten.qSuch, 'Signal_Maschine', 'Istwert', '0', 'nr', IntToStr(Barcode_Gelesen_2.DBNr));
              end;
            3:
              begin
                S7Main.Schreibe_SPS_Wert(0, TTT_GetSignalNr(CBARCODE_GELESEN_3), 0);
                UpdateSQL(Daten.qSuch, 'Signal_Maschine', 'Istwert', '0', 'nr', IntToStr(Barcode_Gelesen_3.DBNr));
              end;
          end;
          Exit;
        end;
        SQLStr := ' SELECT betriebsauftragnr FROM maschinf WHERE lizenz = ''' + Includis[I].Lizenz + '''';
        SQL_Get(Daten.qSuch, SQLStr);
        if not Daten.qSuch.IsEmpty then
          LogUsrEvent(Daten.qSuch2, Daten.qUpdate, 129, 'WFA', Daten.qSuch.FieldByName('betriebsauftragnr').AsString, '');

        ret_Ende := S7Main.S7_Auftrag.Beenden(Maschine);
      end;

    ret_start := S7Main.S7_Auftrag.Starten(Maschine, Auft, True);
    LogUsrEvent(Daten.qSuch2, Daten.qUpdate, 127, 'WUA', Auft, '');

    Eigenschaft := GetL('Auftragstart über Barcode...');
    if ((ret_start = 0) and (ret_Ende = 0)) then
      Status := GetL('Auftrag erfolgreich gestartet...');
    if ((ret_start <> 0) or (ret_Ende <> 0)) then
      Status := GetL('Fehler: Auftragstart. Nr: ')
        + IntToStr(ret_start) + '/' + IntToStr(ret_Ende);
    if Gefunden then
      Status := Status + GetL(' Masch: ') + IntToStr(MaschNr);
    if Length(Status) > 49 then
      Status[49] := #0;

  end;

  if SQLGetBool(Daten.qSuch, 'ZUSTAENDIG', 'PersonalNr', IntToStr(PersNr)) then
  begin
    //********************************************
    // Barcode beinhaltet Fall (b) oder (c)
    //********************************************
    Name := Daten.qSuch.FieldByName('Bezeichnung').AsString;

    case Daten.qSuch.FieldByName('PersonalArt').AsInteger of

      0:
        begin //Fall (a)
          SQLStr := 'INSERT INTO PersonalAnmeldung (Nr,Barcode,DatumZeitStr,DatumZeit,'
            + ' Name,Status)'
            + 'VALUES(BarcodeProtID.NextVal'
            + ',''' + EAN
            + ''',''' + DateTimeToStr(N_o_w)
            + ''',''' + FloatToStr2(N_o_w)
            + ''',''' + Name
            + ''',''' + Status

          + ''')';
          SQL_Insert(Daten.qSuch, SQLStr);
          Eigenschaft := GetL('Personalanmeldung');
        end;

      1:
        begin //Fall (b)
          //Maschine auslesen
          if SQLGetBool(Daten.qSuch, 'Maschine', 'Datenblock', IntToStr(Terminal_Maschine.Istwert)) then
            Masch := Daten.qSuch.FieldByName('Lizenz').AsString
          else
            Masch := '';
          //*****************

          Eigenschaft := GetL('Reparaturanmeldung... Start / Ende nicht def.');

          if Reparatur_Start_Ende.Istwert = 1 then
          begin
            Status := GetL('Anmeldung');
            SQLStr := 'INSERT INTO ReparaturAnmeldung (Nr,Barcode,DatumZeitStr,DatumZeit,'
              + ' KommtStr,Kommt,Maschine,Name,Status)'
              + 'VALUES(BarcodeProtID.NextVal'
              + ',''' + EAN
              + ''',''' + DateTimeToStr(Jetzt)
              + ''',''' + FloatToStr2(Jetzt)
              + ''',''' + DateTimeToStr(Jetzt)
              + ''',''' + FloatToStr2(Jetzt)
              + ''',''' + Masch
              + ''',''' + Name
              + ''',''' + Status

            + ''')';
            SQL_Insert(Daten.qSuch, SQLStr);
            Eigenschaft := GetL('Reparaturanmeldung');
          end;

          if Reparatur_Start_Ende.Istwert = 2 then
          begin
            Status := GetL('Abmeldung');

            Daten.qSuch.Close;
            SQLStr := 'select COUNT(*) CNT from ReparaturAnmeldung where ((Geht is NULL) or (Geht = 0))AND(Barcode = '''
              + EAN + ''')';
            SQL_Get(Daten.qSuch, SQLStr);

            if Daten.qSuch.FieldByName('CNT').AsInteger > 0 then
            begin
              SQLStr := 'select * from ReparaturAnmeldung where ((Geht is NULL) or (Geht = 0))AND(Barcode = '''
                + EAN + ''')';
              SQL_Get(Daten.qSuch, SQLStr);
              Daten.qSuch.First;

              while not Daten.qSuch.EOF do
              begin
                Nummer := Daten.qSuch.FieldByName('Nr').AsInteger;
                Dauer := Trunc((Jetzt - Daten.qSuch.FieldByName('Kommt').AsFloat) * 1440);
                if Dauer = 0 then
                  Dauer := 1;

                UpdateSQL(Daten.qUpdate, 'ReparaturAnmeldung', 'Geht', FloatToStr2(Jetzt), 'Nr', IntToStr(Nummer));
                UpdateSQL(Daten.qUpdate, 'ReparaturAnmeldung', 'GehtStr', DateTimeToStr(Jetzt), 'Nr',
                  IntToStr(Nummer));
                UpdateSQL(Daten.qUpdate, 'ReparaturAnmeldung', 'dauer', IntToStr(Dauer), 'Nr', IntToStr(Nummer));
                Daten.qSuch.Next;
                Status := GetL('Reparatur erfolgreich abgemeldet...');
              end;
            end
            else
              Status := GetL('Fehler Rep.Abmeldung: Reparatur nicht bekannt.');
          end;
        end;
    end;
  end;

  //*****************************************************************
  //  PROTOKOLL Schreiben
  //*****************************************************************

  SQLStr := 'INSERT INTO BarcodeProt (Nr,Barcode,DatumZeitStr,DatumZeit,'
    + ' Eigenschaft,Status)'
    + 'VALUES(BarcodeProtID.NextVal'
    + ',''' + EAN
    + ''',''' + DateTimeToStr(N_o_w)
    + ''',''' + FloatToStr2(N_o_w)
    + ''',''' + Eigenschaft
    + ''',''' + Status

  + ''')';
  SQL_Insert(Daten.qSuch, SQLStr);

  //*****************************************************************
  //Signal in SPS zurücksetzten
  case BarCodeNr of
    1:
      begin
        S7Main.Schreibe_SPS_Wert(0, TTT_GetSignalNr(CBARCODE_GELESEN), 0);
        UpdateSQL(Daten.qSuch, 'Signal_Maschine', 'Istwert', '0', 'nr', IntToStr(Barcode_Gelesen.DBNr));
      end;
    2:
      begin
        S7Main.Schreibe_SPS_Wert(0, TTT_GetSignalNr(CBARCODE_GELESEN_2), 0);
        UpdateSQL(Daten.qSuch, 'Signal_Maschine', 'Istwert', '0', 'nr', IntToStr(Barcode_Gelesen_2.DBNr));
      end;
    3:
      begin
        S7Main.Schreibe_SPS_Wert(0, TTT_GetSignalNr(CBARCODE_GELESEN_3), 0);
        UpdateSQL(Daten.qSuch, 'Signal_Maschine', 'Istwert', '0', 'nr', IntToStr(Barcode_Gelesen_3.DBNr));
      end;
  end;
  //S7Main.Schreibe_SPS_Wert(0,GetSignalNr(CTERMINAL_EINGABE),0);
  //UpdateSQL(Daten.qSuch,'Signal_Maschine','Istwert','0','nr',InttoStr(Terminal_Eingabe.DBNr));

end;

procedure CCC_Check_Auftrag_Freigabe;
var
  I, Ret: Integer;
  Stat: string;
begin
  for I := 1 to Anzahl_Masch do
    if Includis[I].MaschAktiv and not Includis[I].IstArchiviert then
      if Auftrag_Freigabe[I].Istwert then
      begin
        Stat := GetL('Freigabetaster: '); //16 Stellen
        //Freigabe eines Auftrages erteilt...
        if SQL2GetBool(Daten.qSuch, 'PDE', 'LIZENZ', Includis[I].Lizenz, 'stat', IntToStr(stStartRuestenInt)) then
        begin
          //Auftrag wird gerüstet, also starten
          Ret := S7Main.S7_Auftrag.Starten(Includis[I].Lizenz, Includis[I].Auftrag.BetriebsauftragNr, False);
          LogUsrEvent(Daten.qSuch2, Daten.qUpdate, 126, 'WSA', Includis[I].Auftrag.BetriebsauftragNr, '');

          if Ret <> 0 then
          begin
            //Fehler bei Auftragstart
            CCC_Job_erzeugen(Daten.qUpdate, Includis[I].Lizenz, GetL('Fehler bei Auftragstart: ') + IntToStr(Ret),
              GetL('BDE'), '',
              GetL('Bediener'), GetL('Fehler'), False, 0);
            //*****************************************************************
            //  PROTOKOLL Schreiben
            //*****************************************************************

            SQLStr := 'INSERT INTO AuftragstartProt (Nr,Maschine,BetriebsauftragNr,AuftragNr,'
              + ' Bezeichnung,DatumZeitStr,DatumZeit,Modul,Status)'
              + 'VALUES(AuftragstartProtID.NextVal'
              + ',''' + Includis[I].Lizenz
              + ''',''' + Includis[I].Auftrag.BetriebsauftragNr
              + ''',''' + Includis[I].Auftrag.AuftragNr
              + ''',''' + Includis[I].Auftrag.Bezeichnung
              + ''',''' + DateTimeToStr(N_o_w)
              + ''',''' + FloatToStr2(N_o_w)
              + ''',''' + GetL('Auftragsfreigabe')
              + ''',''' + GetL('Fehler: ') + IntToStr(Ret)

            + ''')';
            SQL_Insert(Daten.qSuch, SQLStr);

            Stat := Stat + GetL('Auftragfreigabe Fehler: ') + IntToStr(Ret); //Stat = 44 Stellen
          end
          else
            Stat := Stat + GetL('Auftrag freigegeben...'); //Stat = 39 Stellen
        end
        else
        begin
          if SQL2GetBool(Daten.qSuch, 'PDE', 'LIZENZ', Includis[I].Lizenz, 'stat', IntToStr(stLaeuftInt)) then
            Stat := Stat + GetL('Auftrag war bereits gestartet...')
          else
            if not SQLGetBool(Daten.qSuch, 'PDE', 'LIZENZ', Includis[I].Lizenz) then
              Stat := Stat + GetL('Kein Auftrag angelegt...');

        end;

        S7Main.Schreibe_SPS_Wert(StrToInt(Includis[I].MaschNr), SigNoAuftrag_Freigabe, 0);
        UpdateSQL(Daten.qSuch, 'Signal_Maschine', 'Istwert', '0', 'nr', IntToStr(Auftrag_Freigabe[I].DBNr));

        //*****************************************************************
        //  PROTOKOLL für Freigabe Taster Schreiben
        //*****************************************************************
        SQLStr := 'INSERT INTO FREIGABE_TASTER_PROT (Nr,Maschine,'
          + ' DatumZeitStr,DatumZeit,Status)'
          + 'VALUES(FREIGABE_TASTER_PROTID.NextVal'
          + ',''' + Includis[I].Lizenz
          + ''',''' + DateTimeToStr(N_o_w)
          + ''',''' + FloatToStr2(N_o_w)
          + ''',''' + Stat
          + ''')';
        SQL_Insert(Daten.qSuch, SQLStr);
      end;
end;

procedure CCC_Schreibe_Maschinen_Status;
const
  laRot = 0;
  laGruen = 1;
  laGelb = 2;
  laRotBlink = 3;
var
  I: Integer;
  Stat: Integer;

  betr: string;
  ANr: Integer;
  ANr_ASCII: Integer;
begin
  for I := 1 to Anzahl_Masch do
    if Includis[I].MaschAktiv and not Includis[I].IstArchiviert then
    begin
      Stat := laRot;

      case Includis[I].Zustand of
        stLaeuftInt:
          if SQL2GetBool(Daten.qSuch, 'PDE', 'LIZENZ', Includis[I].Lizenz, 'stat', IntToStr(stLaeuftInt)) then
            Stat := laGruen;
        stStartRuestenInt:
          Stat := laGelb;
      end;

      //************************************************************
      // RP Änderung 05.07.05
      // Wenn kein Auftrag angemeldet ist, soll rote Lampe blinken
      if (Includis[I].Auftrag.Bezeichnung = GetL('kein aktueller Auftrag')) then
        Stat := laRotBlink;
      //************************************************************

      if (Stat <> Maschinen_Zustand[I].Istwert) and (Includis[I].MaschNr <> '') then
        S7Main.Schreibe_SPS_Wert(StrToInt(Includis[I].MaschNr), TTT_GetSignalNr(CMASCHINEN_STATUS), Stat);

      //************************************************************
      //  AUFTRAGNR schreiben
      //************************************************************
      if Includis[I].Auftrag.BetriebsauftragNr <> '' then
      begin

        betr := Includis[I].Auftrag.BetriebsauftragNr;
        ANr_ASCII := 0;
        if betr[Length(betr)] = 'K' then
          ANr_ASCII := 75;
        if betr[Length(betr)] = 'L' then
          ANr_ASCII := 76;

        try
          ANr := Format_String(betr);
        except
          ANr := 0;
        end;
      end
      else
      begin
        ANr := 0;
        ANr_ASCII := 0;
      end;

      if (((ANr <> Terminal_AuftragNr[I].Istwert) or (ANr = 0)) and (Includis[I].MaschNr <> '')) then
      begin

        S7Main.Schreibe_SPS_Wert(StrToInt(Includis[I].MaschNr), TTT_GetSignalNr(CTERMINAL_AUFTRAGNR), ANr);
        S7Main.Schreibe_SPS_Wert(StrToInt(Includis[I].MaschNr), TTT_GetSignalNr(CTERMINAL_AUFTRAGNR_ASCII), ANr_ASCII);

        UpdateSQL(Daten.qSuch, 'Signal_Maschine', 'Istwert', IntToStr(ANr), 'nr',
          IntToStr(Terminal_AuftragNr[I].DBNr));
        UpdateSQL(Daten.qSuch, 'Signal_Maschine', 'Istwert', IntToStr(ANr_ASCII), 'nr',
          IntToStr(Terminal_AuftragNr_ASCII[I].DBNr));
      end;
    end;
end;

procedure CCC_Check_Menge_Gebucht;
var
  I, Ret: Integer;
  Name: string;
begin
  for I := 1 to Anzahl_Masch do
  begin
    if Includis[I].IstArchiviert then
      continue;

    if Terminal_Menge_Gebucht[I].Istwert then
    begin
      //Maschine auslesen

      case Terminal_Einheit[I].Istwert of
        1: Includis[I].Einheit := GetL('Meter');
        2: Includis[I].Einheit := GetL('Stück');
        3: Includis[I].Einheit := GetL('KG');
      else
        Includis[I].Einheit := '';
      end;

      //*****************************************************************
      //   PROTOKOLL schreiben
      //*****************************************************************
      Daten.qSuch.Close;
      SQLStr := 'select Name from Personalanmeldung where nr = (select max(nr) from Personalanmeldung)';
      SQL_Get(Daten.qSuch, SQLStr);
      try
        Name := Daten.qSuch.FieldByName('Name').AsString;
      except
        Name := '';
      end;

      //Plausibilität
      if Includis[I].Auftrag.Istwert = 0 then
      begin
        SQLStr := 'select MAX(Mengeges) as menge from MENGE_BUCH_PROT where BETRIEBSAUFTRAGNR = ''' +
          Includis[I].Auftrag.BetriebsauftragNr + '''';
        SQL_Get(Daten.qSuch, SQLStr);
        try
          Includis[I].Auftrag.Istwert := Daten.qSuch.FieldByName('menge').AsInteger;
        except
          Includis[I].Auftrag.Istwert := 0;
        end;
      end;

      //Plausibilität doppelte Einträge

      SQLStr := 'INSERT INTO MENGE_BUCH_PROT (Nr,Maschine,BETRIEBSAUFTRAGNR,Mengeges,menge,Einheit,'
        + ' DatumZeitStr,DatumZeit,Etikett,Name,Schicht,Status)'
        + 'VALUES(MENGE_BUCH_PROTID.NextVal'
        + ',''' + Includis[I].Lizenz
        + ''',''' + Includis[I].Auftrag.BetriebsauftragNr
        + ''',''' + IntToStr(Includis[I].Auftrag.Istwert)
        + ''',''' + IntToStr(Includis[I].StueckAuftragSchicht)
        + ''',''' + Includis[I].Einheit
        + ''',''' + DateTimeToStr(N_o_w)
        + ''',''' + FloatToStr2(N_o_w)
        + ''',''' + IntToStr(Terminal_Etikett[I].Istwert)
        + ''',''' + Name
        + ''',''' + IntToStr(Includis[I].Schicht)
        + ''','''
        + ''')';
      SQL_Insert(Daten.qSuch, SQLStr);

      //*****************************************************************

      //Menge wurde gebucht, also prüfen ob Auftrag läuft, sonst starten
      if SQL2GetBool(Daten.qSuch, 'PDE', 'LIZENZ', Includis[I].Lizenz, 'stat', IntToStr(stStartRuestenInt)) then
      begin
        //Auftrag wird gerüstet, also starten
        Ret := S7Main.S7_Auftrag.Starten(Includis[I].Lizenz, Includis[I].Auftrag.BetriebsauftragNr, False);
        LogUsrEvent(Daten.qSuch2, Daten.qUpdate, 126, 'WSA', Includis[I].Auftrag.BetriebsauftragNr, '');

        if Ret <> 0 then
        begin
          //Fehler bei Auftragstart
          CCC_Job_erzeugen(Daten.qUpdate, Includis[I].Lizenz, GetL('Fehler bei Auftragstart: ') + IntToStr(Ret),
            GetL('BDE'), '',
            GetL('Bediener'), GetL('Fehler'), False, 0);
          //*****************************************************************
          //  PROTOKOLL Schreiben
          //*****************************************************************

          SQLStr := 'INSERT INTO AuftragstartProt (Nr,Maschine,BetriebsauftragNr,AuftragNr,'
            + ' Bezeichnung,DatumZeitStr,DatumZeit,Modul,Status)'
            + 'VALUES(AuftragstartProtID.NextVal'
            + ',''' + Includis[I].Lizenz
            + ''',''' + Includis[I].Auftrag.BetriebsauftragNr
            + ''',''' + Includis[I].Auftrag.AuftragNr
            + ''',''' + Includis[I].Auftrag.Bezeichnung
            + ''',''' + DateTimeToStr(N_o_w)
            + ''',''' + FloatToStr2(N_o_w)
            + ''',''' + GetL('Terminal')
            + ''',''' + GetL('Fehler: ') + IntToStr(Ret)

          + ''')';
          SQL_Insert(Daten.qSuch, SQLStr);
        end;
      end;

      //Signal in SPS zurücksetzten
      S7Main.Schreibe_SPS_Wert(StrToInt(Includis[I].MaschNr), SigNoMenge_Gebucht, 0);
      UpdateSQL(Daten.qSuch, 'Signal_Maschine', 'Istwert', '0', 'nr', IntToStr(Terminal_Menge_Gebucht[I].DBNr));

    end;
  end;

end;

procedure CCC_Check_Terminal_Auftrag_Ende;
var
  I: Integer;
  SQLStr: string;
begin
  for I := 1 to Anzahl_Masch do
  begin
    if Includis[I].IstArchiviert then
      continue;

    if Terminal_Auftrag_Beendet[I].Istwert then
    begin
      //prüfen, ob ein Auftrag läuft
      if SQL2GetBool(Daten.qSuch, 'PDE', 'LIZENZ', Includis[I].Lizenz, 'stat', IntToStr(stLaeuftInt)) then
      begin
        //ein Auftrag läuft auf der Maschine, also laufenden Auftrag beenden
        SQLStr := ' SELECT betriebsauftragnr FROM maschinf WHERE lizenz = ''' + Includis[I].Lizenz + '''';
        SQL_Get(Daten.qSuch, SQLStr);
        if not Daten.qSuch.IsEmpty then
          LogUsrEvent(Daten.qSuch2, Daten.qUpdate, 129, 'WFA', Daten.qSuch.FieldByName('betriebsauftragnr').AsString, '');
        S7Main.S7_Auftrag.Beenden(Includis[I].Lizenz);
      end
      else
        if SQL2GetBool(Daten.qSuch, 'PDE', 'LIZENZ', Includis[I].Lizenz, 'stat', IntToStr(stStartRuestenInt)) then
        begin
          //ein anderer Auftrag läuft auf der Maschine (Rüsten), also Auftrag beenden
          SQLStr := ' SELECT betriebsauftragnr FROM maschinf WHERE lizenz = ''' + Includis[I].Lizenz + '''';
          SQL_Get(Daten.qSuch, SQLStr);
          if not Daten.qSuch.IsEmpty then
            LogUsrEvent(Daten.qSuch2, Daten.qUpdate, 129, 'WFA', Daten.qSuch.FieldByName('betriebsauftragnr').AsString, '');
          S7Main.S7_Auftrag.Beenden(Includis[I].Lizenz);
        end;
      //Signal in SPS zurücksetzten
      S7Main.Schreibe_SPS_Wert(StrToInt(Includis[I].MaschNr), SigNoTerminal_Auftrag_Unterbrochen, 0);
      UpdateSQL(Daten.qSuch, 'Signal_Maschine', 'Istwert', '0', 'nr', IntToStr(Terminal_Auftrag_Beendet[I].DBNr));

    end;
  end;

end;

procedure CCC_Check_Terminal_Auftrag_Unterbrochen;
var
  I: Integer;
begin
  for I := 1 to Anzahl_Masch do
  begin
    if Includis[I].IstArchiviert then
      continue;

    if Terminal_Auftrag_Unterbrochen[I].Istwert then
    begin

      //prüfen, ob ein Auftrag läuft
      if SQL2GetBool(Daten.qSuch, 'PDE', 'LIZENZ', Includis[I].Lizenz, 'stat', IntToStr(stLaeuftInt)) then
      begin
        //ein Auftrag läuft auf der Maschine, also laufenden Auftrag beenden
        S7Main.S7_Auftrag.Unterbrechen(Includis[I].Lizenz);
        LogUsrEvent(Daten.qSuch2, Daten.qUpdate, 128, 'WIA', Daten.qSuch.FieldByName('Betriebsauftragnr').AsString, '');
      end
      else
        if SQL2GetBool(Daten.qSuch, 'PDE', 'LIZENZ', Includis[I].Lizenz, 'stat', IntToStr(stStartRuestenInt)) then
        begin
          //ein anderer Auftrag läuft auf der Maschine (Rüsten), also Auftrag beenden
          S7Main.S7_Auftrag.Unterbrechen(Includis[I].Lizenz);
          LogUsrEvent(Daten.qSuch2, Daten.qUpdate, 128, 'WIA', Daten.qSuch.FieldByName('Betriebsauftragnr').AsString, '');
        end;
      //Signal in SPS zurücksetzten
      S7Main.Schreibe_SPS_Wert(StrToInt(Includis[I].MaschNr), SigNoTerminal_Auftrag_Unterbrochen, 0);
      UpdateSQL(Daten.qSuch, 'Signal_Maschine', 'Istwert', '0', 'nr', IntToStr(Terminal_Auftrag_Unterbrochen[I].DBNr));
    end;
  end;
end;

procedure CCC_Check_Terminal_Stillstand;
var
  I, Nummer, Dauer: Integer;
begin
  for I := 1 to Anzahl_Masch do
    if Includis[I].IstArchiviert then
      continue;

    if Terminal_Stillstand_Gebucht[I].Istwert then
    begin
      if Terminal_StoerKommtGeht[I].Istwert = 1 then
      begin

        //Stillstand Kommt
        SQLStr := 'INSERT INTO TPM_Stillog (Nr,MaschNr,Schicht,Kommt,Stillstandnr,KommtStr,STOERUNG)'
          + ' VALUES(TPM_StillogID.Nextval'
          + ',''' + Includis[I].MaschNr
          + ''',''' + IntToStr(Includis[1].Schicht)
          + ''',' + FloatToPunktString(Jetzt)
          + ',''' + IntToStr(Terminal_Stoer_Nr[I].Istwert)
          + ''',''' + DateTimeToStr(Jetzt)
          + ''',''' + IntToStr(Terminal_Still_Stoer[I].Istwert)
          + ''')';
        SQL_Insert(Daten.qUpdate, SQLStr);
        TTT_ErstelldatumEinfuegen(Daten.qUpdate, Daten.qSuch3, 6);
        TTT_InsertStillstandEvent(Daten.qUpdate, Includis[I].MaschNr);

      end;

      if Terminal_StoerKommtGeht[I].Istwert = 2 then
      begin
        //Stillstand geht
        Daten.qSuch.Close;
        SQLStr := 'select * from tpm_Stillog where (STILLSTANDNR <> 2) AND(Geht = 0)AND(maschnr = ''' +
          Includis[I].MaschNr + ''')';
        SQL_Get(Daten.qSuch, SQLStr);
        Daten.qSuch.First;
        while not Daten.qSuch.EOF do
        begin
          Nummer := Daten.qSuch.FieldByName('Nr').AsInteger;
          Dauer := Trunc((Jetzt - Daten.qSuch.FieldByName('Kommt').AsFloat) * 1440);
          if Dauer = 0 then
            Dauer := 1;

      SQLStr := 'UPDATE tpm_Stillog SET Geht = ' +FloatToPunktString(Jetzt)
        +  ', GehtStr = ''' +DateTimeToStr(Jetzt) + ''', dauer ='+IntToStr(Dauer)+' WHERE nr = ' + IntToStr(Nummer);
      SQL_Insert(Daten.qUpdate, SQLStr);
//          UpdateSQL(Daten.qUpdate, 'tpm_Stillog', 'Geht', FloatToStr2(Jetzt), 'Nr', IntToStr(Nummer));
  //        UpdateSQL(Daten.qUpdate, 'tpm_Stillog', 'GehtStr', DateTimeToStr(Jetzt), 'Nr', IntToStr(Nummer));
    //      UpdateSQL(Daten.qUpdate, 'tpm_Stillog', 'dauer', IntToStr(Dauer), 'Nr', IntToStr(Nummer));
          Daten.qSuch.Next;
        end;
        Daten.qSuch.Close;
      end;

      //Signal in SPS zurücksetzten
      S7Main.Schreibe_SPS_Wert(StrToInt(Includis[I].MaschNr), SigNoTerminal_StillstandGebucht, 0);
      UpdateSQL(Daten.qSuch, 'Signal_Maschine', 'Istwert', '0', 'nr', IntToStr(Terminal_Stillstand_Gebucht[I].DBNr));
    end;
end;

//************************************************************************
//************************************************************************
//************************************************************************

procedure CCC_Check_Warmtrennen;
var
  I, Tmp: Integer;
begin
  for I := 1 to Anzahl_Masch do
  begin
    if Includis[I].IstArchiviert then
      continue;

    if MaschWarmtrennen[I].Istwert <> Includis[I].Masch_Warmtrennen then
    begin
      if Includis[I].Masch_Warmtrennen then
        Tmp := 1
      else
        Tmp := 0;
      S7Main.Schreibe_SPS_Wert(StrToInt(Includis[I].MaschNr), TTT_GetSignalNr(CWARMTRENNEN), Tmp);
    end;
  end;
end;

procedure CCC_Check_Job_Stueckzahl;
var
  I: Integer;
begin
  for I := 1 to Anzahl_Masch do
  begin
    if Includis[I].IstArchiviert then
      continue;

    if (Job_Stueckzahl[I].Istwert > 0) then
    begin
      CCC_Erzeuge_Arbeitsplan(Includis[I].Lizenz, Includis[I].MaschNr, GetL('VS-Poti'), '0',
        GetL('VS-Poti'), GetL('Bediener'), False, GetL('sofort erledigen'), False, False);
    end
    else
    begin
      SQL_Insert(Daten.qUpdate, 'delete from bda where Signal = ''' + GetL('VS-Poti') + ''' AND Lizenz = ''' +
        Includis[I].Lizenz + '''');
    end;
  end;
end;

procedure CCC_Check_StillstandNr_SPS;
var
  I: Integer;
  SQLStr: string;
  Stillstand: string;
begin
  for I := 1 to Anzahl_Masch do
  begin
    if Includis[I].IstArchiviert then
      continue;

    if METALL_BEARBEITUNG then
    begin
      if StillstandNr_SPS[I].Istwert > 0 then
      begin
        StillstandNr_SPS[I].Istwert := StillstandNr_SPS[I].Istwert + 9; //Stillstandsnummer in INCLUDIS erst ab 10!
        Stillstand := S7Main.TPM.GetStillstand(StillstandNr_SPS[I].Istwert);

        SQLStr := 'select * from TPM_STILLOG where  Nr = (Select Max(Nr) from TPM_STILLOG where Maschnr = '''
          + Includis[I].MaschNr + ''')';
        SQL_Get(Daten.qSuch, SQLStr);

        if Daten.qSuch.FieldByName('StillstandNr').AsInteger <> StillstandNr_SPS[I].Istwert then
          S7Main.TPM.StillstandErzeugen(Daten.qSuch.FieldByName('Nr').AsInteger, Stillstand);
      end;
    end
    else
    begin
      if StillstandNr_SPS[I].Istwert > 0 then
      begin

        if StillstandNr_SPS[I].Istwert = 2 then
          StillstandNr_SPS[I].Istwert := TTT_GetRuestStillstandUeberschreitung(Daten.qUpdate, Daten.qSuch,
            Includis[I].Datenblock, Includis[I].Lizenz);

        Stillstand := S7Main.TPM.GetStillstand(StillstandNr_SPS[I].Istwert);

        SQLStr := 'select * from TPM_STILLOG where Maschnr = ' + Includis[I].MaschNr + ' order by Kommt desc';
        SQL_Get(Daten.qSuch, SQLStr);

        if Daten.qSuch.FieldByName('StillstandNr').AsInteger = 1 then
          S7Main.TPM.StillstandBuchen(Daten.qSuch.FieldByName('Nr').AsInteger, Stillstand, '')
        else
          if Daten.qSuch.FieldByName('StillstandNr').AsInteger <> StillstandNr_SPS[I].Istwert then
            S7Main.TPM.StillstandErzeugen(Daten.qSuch.FieldByName('Nr').AsInteger, Stillstand);
      end;

      if StillstandNr_SPS[I].Istwert < 0 then
      begin
        Stillstand := S7Main.TPM.GetStillstand((maxint + StillstandNr_SPS[I].Istwert) + 1);

        SQLStr := 'select * from TPM_STILLOG where  Nr = (Select Max(Nr) from TPM_STILLOG where Maschnr = '''
          + Includis[I].MaschNr + ''')';
        SQL_Get(Daten.qSuch, SQLStr);
        ChangeDtCode(Daten.qUpdate, 0, StrToInt(Includis[I].Maschnr), True, 'CSNS7174'); //RS 06.01.2016 ist das wirklich richtig? und nicht ChangeDtCode(0, Daten.qSuch.FieldByName('Nr').AsInteger, True, 'CSNS7174')
        S7Main.TPM.StillstandBuchen(Daten.qSuch.FieldByName('Nr').AsInteger, Stillstand, '');
      end;
    end;
  end;
end;

procedure CCC_UeberwachungszeitBerechnen(MaschNr: Integer);

  function GetUWZeit(SNR: Integer): Integer;
  begin
    if SQLGetBool(Daten.qSuch2, 'TPM_Stillstaende', 'StillstandNr', IntToStr(SNR)) then
      Result := Daten.qSuch2.FieldByName('UEBERWACHUNGSZEIT').AsInteger
    else
      Result := 0;
  end;

var
  S: string;
  Uz, SNR: Integer;
  GZeit: Real;
begin
  SchreibeMeldung(' U0 - ' +  IntToStr(MaschNr),7);
  S := 'SELECT UEBERWACHUNGSZEIT'
     + ' FROM TPM_STILLSTAENDE'
     + ' WHERE STILLSTANDNR = ('
     + '        SELECT stillstandnr'
     + '        FROM TPM_Stillog'
     + '        WHERE nr = ('
     + '                SELECT max(nr)'
     + '                FROM tpm_stillog'
     + '                WHERE MaschNr = ' + IntToStr(MaschNr)
     + '                AND stillstandnr <> 1'
     + '        )'
     + ' )';
  SQL_Get(Daten.qSuch, S);
  SchreibeMeldung(' U1 - ' + IntToStr(MaschNr),7);
  Uz := Daten.qSuch.FieldByName('UEBERWACHUNGSZEIT').AsInteger;
  if Uz > 0 then
  begin
    S := 'select * from TPM_Stillog where MaschNr = ' + IntToStr(MaschNr) + ' order by Kommt desc';
    SQL_Get(Daten.qSuch, S);
    Daten.qSuch.First;
    SchreibeMeldung(' UI - ',7);
    while (Daten.qSuch.FieldByName('StillStandNr').AsInteger = 1) and not Daten.qSuch.EOF do
      Daten.qSuch.Next;

    SchreibeMeldung(' US - ',7);
    SNR := Daten.qSuch.FieldByName('StillStandNr').AsInteger;
    if SNR > 1 then
    begin
      Uz := GetUWZeit(SNR);
    SchreibeMeldung(' UZ - ' + IntToStr(Uz),7);
      if Uz > 0 then
      begin
        while (Daten.qSuch.FieldByName('StillStandNr').AsInteger = SNR)  and not Daten.qSuch.EOF  do
          Daten.qSuch.Next;
        if  not Daten.qSuch.EOF  then
        begin
          SchreibeMeldung(' US2 - ',7);
          Daten.qSuch.Prior;
          GZeit := Daten.qSuch.FieldByName('Geht').AsFloat;
          Daten.qSuch.First;
          while (Daten.qSuch.FieldByName('StillStandNr').AsInteger = 1) and not Daten.qSuch.EOF do
          begin
            if Daten.qSuch.FieldByName('Kommt').AsFloat - GZeit < Uz / 1440 then
            begin
              ChangeDtCode(Daten.qUpdate, SNR, Daten.qSuch.FieldByName('Nr').AsInteger, true, true, false, 'UZB7241');
            end;
            Daten.qSuch.Next;
          end;
        end;
      end;
    end;
  end;
end;

procedure CCC_QS_Jobs;
var
  S, PPNr, Bez, Liz, JobNum, Nr: string;
  Interval: Integer;
  D: Real;
begin
  SQLGet(Daten.qSuch, 'PDE', 'Stat', '0', False);
  while not Daten.qSuch.EOF do
  begin
    PPNr := Daten.qSuch.FieldByName('Pruefplan').AsString;
    if PPNr <> '' then
      if SQLGetBool(Daten.qSuch2, 'Pruefplan', 'PPNr', PPNr) then
      begin
        if Daten.qSuch2.FieldByName('Job_Wert1').AsInteger = 1 then
        begin
          Interval := Daten.qSuch2.FieldByName('Intervall_Wert1').AsInteger;
          Bez := GetL('Prüfplan: Auftrag-Nr. = ') + Daten.qSuch.FieldByName('BetriebsAuftragNr').AsString
            + ', '
            + Daten.qSuch2.FieldByName('Pruefteile1').AsString + GetL(' Teile / ')
            + IntToStr(Interval) + GetL(' min.');
          Liz := Daten.qSuch.FieldByName('Lizenz').AsString;

          if not SQLGetBool(Daten.qSuch3, 'BDA', 'Bezeichnung', Bez) then
          begin
            if SQLGetBool(Daten.qSuch3, 'BDATime', 'Bezeichnung', Bez) then
              D := Daten.qSuch3.FieldByName('Datum').AsFloat
            else
              D := 0;
            D := MAX(D, Daten.qSuch.FieldByName('StartDatumZeit').AsFloat);

            if N_o_w - D > Interval / 1440 then
            begin
              if SQLGetBool(Daten.qSuch3, 'Maschine', 'Lizenz', Liz) then
                JobNum := Daten.qSuch3.FieldByName('MaschNr').AsString
              else
                JobNum := '0';

              S := 'select BDAId.Nextval as CNT from Setup';
              SQL_Get(Daten.qSuch3, S);
              Nr := Daten.qSuch3.FieldByName('CNT').AsString;
              JobNum := JobNum + ' / ' + Nr;

              S := 'INSERT INTO BDA (Nr, Lizenz, Jobnummer, Bezeichnung,'
                + ' Datumzeit, Masch_Bez, Signal, neuerjob) VALUES ('
                + Nr
                + ',''' + Liz
                + ''',''' + JobNum
                + ''',''' + Bez
                + ''',' + FloatToPunktString(N_o_w)
                + ',''' + Liz
                + ''',''' + GetL('Prüfplan')
                + ''',''1'')';
              SQL_Insert(Daten.qUpdate, S);
              if Active_Alarming then
              begin // Aktive Alarmierung bei Eintrag über PopUp
                try
                  SQLStr := 'INSERT INTO alertnotification (Nr, Alertstamp, Message, Typ, Confirmation) VALUES ('
                    + 'AlertNotificationId.NextVal, '
                    + '''' + FloatToStr2(N_o_w) + ''', '
                    + '''' + Liz + ' : ' + GetL('Prüfplan') + '-' + JobNum + ''','
                    + IntToStr(ord(mtWarning)) + ', '
                    + '0)';
                  SQL_Insert(Daten.qUpdate, SQLStr);
                except
                end;
              end;

              S := 'delete from BDATime where Bezeichnung = ''' + Bez + '''';
              SQL_Insert(Daten.qUpdate, S);

              S := 'Insert into BDATime (Nr, Bezeichnung, DatumZeit) values (BDATimeId.NextVal,'
                + ' ''' + Bez + ''','
                + ' ' + FloatToPunktString(N_o_w) + ')';
              SQL_Insert(Daten.qUpdate, S);
            end;
          end;
        end;
      end;
    Daten.qSuch.Next;
  end;
end;

function DateOverlap(aZRStart, aZREnd, aItemStart, aItemEnd: TDateTime): Extended;
begin
  if (aZRStart <= aItemEnd) and (aZREnd >= aItemStart) then // Item befindet sich in ZR
  begin
    if aItemStart < aZRStart then
      aItemStart := aZRStart;
    if aItemEnd > aZREnd then
      aItemEnd := aZREnd;
    Result := (aItemEnd - aItemStart) * 1440;
  end
  else
    Result := 0;
end;

procedure CCC_A_Felder_Schicht_Berechnen2(aQ1, aQ2, aU: TCO_Query;  aSchichtstart: Extended; aSchicht: Integer);
var
  banrbefore, S, BANr: string;
  DT: Real;
  Stueck, Schicht, Nr, MaschNr, I, J: Integer;
  sarr: array[1..3] of Real;
  bdt, edt: Extended;
  stillist: TStillstandEintragsListe;
  stillisteTotal: TStillstandEintragsListe;

  laufzeitlist: TStartStopEintragsListe;
  laufzeitlistetotal : TStartStopEintragsListe;

  Stillstand: TStillstandEintrag;
  Laufzeit : TStartStopEintrag;

  Ruest, Logistik, ausfall, ungebucht,
    Geplant, Ungeplant, Lauf, stillgesamt,
    zrges, zrstill, soll: Extended;

begin

  try
    stillist := nil;// TStillstandEintragsListe.Create;
    laufzeitlist := nil;//TStartStopEintragsListe.Create;

    sarr[1] := Schicht1;
    sarr[2] := Schicht2;
    sarr[3] := Schicht3;

    if Shift_Model = 1 then
    begin
      if aSchicht = 1 then
        zrges := Round((sarr[2] - sarr[1]) * 1440)
      else
        if aSchicht = 2 then
          zrges := Round((sarr[3] - sarr[2]) * 1440)
        else
          zrges := Round(((1 + sarr[1]) - sarr[3]) * 1440);
    end
    else
    begin
      if aSchicht = 1 then
        zrges := Round((sarr[2] - sarr[1]) * 1440)
      else
        if aSchicht = 2 then
          zrges := Round((1+sarr[1] - sarr[2]) * 1440)
    end;

    bdt := Trunc(aSchichtstart) + sarr[aSchicht];
    edt := bdt + zrges / 1440;

    if edt > N_o_w then
      edt := N_o_w;

    stillisteTotal := TStillstandEintragsListe.Create;
    S := 'SELECT tpm_stillog.nr, tpm_stillog.kommt, tpm_stillog.geht, tpm_stillstaende.gruppe, tpm_stillstaende.geplant, '
      + ' tpm_stillog.stillstandnr grundnr, tpm_stillog.maschnr FROM tpm_stillog '
      + ' LEFT JOIN tpm_stillstaende ON tpm_stillog.stillstandnr = tpm_stillstaende.stillstandnr '
      + ' WHERE kommt <= ' + FloatToPunktString(edt)
      + ' AND (geht >= ' + FloatToPunktString(bdt) + ' OR geht = 0)';
    SQL_Get(aQ2, S);
    while not aQ2.EOF do
    begin
      Stillstand := TStillstandEintrag.Create;
      Stillstand.Kommt := aQ2.FieldByName('kommt').AsFloat;
      if Stillstand.Kommt < bdt then
        Stillstand.Kommt := bdt;
      Stillstand.Geht := aQ2.FieldByName('geht').AsFloat;
      if Stillstand.Geht = 0 then
        Stillstand.Geht := edt;
      if Stillstand.Geht > edt then
        Stillstand.Geht := edt;
      Stillstand.GrundNr := aQ2.FieldByName('grundnr').AsInteger;
      Stillstand.Maschnr := aQ2.FieldByName('maschnr').AsInteger;
      Stillstand.Geplant := aQ2.FieldByName('geplant').AsInteger = 1;
      Stillstand.Gruppe := aQ2.FieldByName('gruppe').AsInteger;
      Stillstand.Nr := aQ2.FieldByName('nr').AsInteger;
      stillisteTotal.Add(Stillstand);
      aQ2.Next;
    end;

    laufzeitlistetotal := TStartStopEintragsListe.Create;

    S := 'SELECT rueststart, auftragstart, auftragende, betriebsauftragnr FROM laufzeitlog WHERE rueststart <= ' + FloatToPunktString(edt)
      + ' AND (auftragende >= ' + FloatToPunktString(bdt) + ' OR auftragende = 0)';
    SQL_Get(aQ2, S);
    while not aQ2.EOF do
    begin
      Laufzeit := TStartStopEintrag.Create;
      Laufzeit.AuftragNr := aQ2.FieldByName('betriebsauftragnr').AsString;
      Laufzeit.Start := aQ2.FieldByName('auftragstart').AsFloat;
      if Laufzeit.Start < bdt then
        Laufzeit.Start := bdt;
      Laufzeit.RuestStart := aQ2.FieldByName('rueststart').AsFloat;
      if Laufzeit.RuestStart < bdt then
        Laufzeit.RuestStart := bdt;
      Laufzeit.Stop := aQ2.FieldByName('auftragende').AsFloat;
      if Laufzeit.Stop = 0 then
        Laufzeit.Stop := edt;
      if Laufzeit.Stop > edt then
        Laufzeit.Stop := edt;
      laufzeitlistetotal.Add(Laufzeit);
      aQ2.Next;
    end;

    S := 'SELECT nr, betriebsauftragnr, maschnr FROM tpm_schicht '
      + ' WHERE datumzeit > ' + FloatToPunktString(bdt - 5 / 1440)
      + ' AND datumzeit < ' + FloatToPunktString(bdt + 5 / 1440)
      // + ' AND betriebsauftragnr IS NOT NULL '
    + ' ORDER BY betriebsauftragnr, nr';
    SQL_Get(aQ1, S);

    while not aQ1.EOF do
    begin
      BANr := aQ1.FieldByName('betriebsauftragnr').AsString;
      if banrbefore <> BANr then
      begin
        banrbefore := BANr;
     //   laufzeitlist.Clear;
      end;

      Nr := aQ1.FieldByName('nr').AsInteger;
      MaschNr := aQ1.FieldByName('maschnr').AsInteger;

      if (laufzeitlist <> nil)  then
//        laufzeitlist.Destroy;
        laufzeitlist.Free;
      laufzeitlist := laufzeitlistetotal.GetByBetriebsauftragNr(BANr);

      if (stillist <> nil) then
//        stillist.Destroy;
        stillist.Free;
      stillist := stillisteTotal.GetByMaschNr(MaschNr);

      Geplant := 0;
      Ungeplant := 0;
      ausfall := 0;
      Ruest := 0;
      Logistik := 0;
      ungebucht := 0;
      zrges := 0;
      for J := 0 to laufzeitlist.Count - 1 do
      begin
        Laufzeit := laufzeitlist.Items[J];
        zrges := zrges + (Laufzeit.Stop - Laufzeit.RuestStart) * 1440;
        for I := 0 to stillist.Count - 1 do
        begin
          Stillstand := stillist.Items[I];
          zrstill := DateOverlap(Laufzeit.RuestStart, Laufzeit.Stop, Stillstand.Kommt, Stillstand.Geht);
          if Stillstand.Geplant then
            Geplant := Geplant + zrstill
          else
            Ungeplant := Ungeplant + zrstill;

          if Stillstand.Gruppe = 0 then
            ausfall := ausfall + zrstill;
          if Stillstand.Gruppe = 1 then
            Ruest := Ruest + zrstill;
          if Stillstand.Gruppe = 2 then
            Logistik := Logistik + zrstill;
          if Stillstand.Gruppe = 3 then
             ungebucht := ungebucht + zrstill;
        end;
      end;
      stillgesamt := Ungeplant + Geplant;
      Lauf := zrges - stillgesamt;
      if lauf < 0 then
        lauf :=0;
      soll := zrges - geplant;
      if soll< 0 then
        soll := 0;
      S := 'UPDATE tpm_schicht SET '
        + ' A_SOLLLAUFZEIT = ' + IntToStr(round(soll)) + ','
        + ' A_ISTLAUFZEIT = ' + IntToStr(round(Lauf)) + ','
        + ' A_GEPLANT = ' + IntToStr(round(Geplant)) + ','
        + ' A_UNGEPLANT = ' + IntToStr(round(Ungeplant)) + ','
        + ' A_ANLAGENAUSFALL = ' + IntToStr(round(ausfall)) + ','
        + ' A_RUESTEN = ' + IntToStr(round(Ruest)) + ','
        + ' A_LOGISTIK = ' + IntToStr(round(Logistik)) + ','
        + ' A_NICHTGEBUCHT = ' + IntToStr(round(ungebucht))
        + ' WHERE nr = ' + IntToStr(Nr);
      SQL_Insert(aU, S);
      aQ1.Next;
    end;
  finally
    stillist.Free;
    stillisteTotal.Destroy;
    laufzeitlist.Free;
    laufzeitlistetotal.Destroy;
  end;
end;


procedure CCC_A_Felder_Schicht_Berechnen(aQ1, aQ2, aU: TCO_Query; aSchichtstart: Extended; aSchicht: Integer);
var
  S, BANr, banrbefore: string;
  DT: Real;
  Stueck, Schicht, Nr, MaschNr, I, J: Integer;
  sarr: array[1..3] of Real;
  bdt, edt: Extended;
  stillist: TStillstandEintragsListe;
  laufzeitlist: TStartStopEintragsListe;

  Stillstand: TStillstandEintrag;
  Laufzeit: TStartStopEintrag;

  Ruest, Logistik, ausfall, ungebucht,
    Geplant, Ungeplant, Lauf, stillgesamt,
    zrges, zrstill, soll: Extended;

begin
CCC_A_Felder_Schicht_Berechnen2(aQ1, aQ2, aU,aSchichtstart,aSchicht);
exit;
  try
    stillist := TStillstandEintragsListe.Create;
    laufzeitlist := TStartStopEintragsListe.Create;

    sarr[1] := Schicht1;
    sarr[2] := Schicht2;
    sarr[3] := Schicht3;

    if Shift_Model = 1 then
    begin
      if aSchicht = 1 then
        zrges := Round((sarr[2] - sarr[1]) * 1440)
      else
        if aSchicht = 2 then
          zrges := Round((sarr[3] - sarr[2]) * 1440)
        else
          zrges := Round(((1 + sarr[1]) - sarr[3]) * 1440);
    end
    else
    begin
      if aSchicht = 1 then
        zrges := Round((sarr[2] - sarr[1]) * 1440)
      else
        if aSchicht = 2 then
          zrges := Round((1+sarr[1] - sarr[2]) * 1440)
    end;

    bdt := Trunc(aSchichtstart) + sarr[aSchicht];
    edt := bdt + zrges / 1440;

    if edt > N_o_w then
      edt := N_o_w;

    S := 'SELECT nr, betriebsauftragnr, maschnr FROM tpm_schicht '
      + ' WHERE datumzeit > ' + FloatToPunktString(bdt - 5 / 1440)
      + ' AND datumzeit < ' + FloatToPunktString(bdt + 5 / 1440)
      // + ' AND betriebsauftragnr IS NOT NULL '
    + ' ORDER BY betriebsauftragnr, nr';
    SQL_Get(aQ1, S);
    banrbefore := '';

    while not aQ1.EOF do
    begin
      BANr := aQ1.FieldByName('betriebsauftragnr').AsString;
      if banrbefore <> BANr then
      begin
        banrbefore := BANr;
        laufzeitlist.Clear;
      end;

      Nr := aQ1.FieldByName('nr').AsInteger;
      MaschNr := aQ1.FieldByName('maschnr').AsInteger;
      S := 'SELECT rueststart, auftragstart, auftragende FROM laufzeitlog WHERE betriebsauftragnr = '''
        + BANr + ''' AND rueststart <= ' + FloatToPunktString(edt)
        + ' AND (auftragende >= ' + FloatToPunktString(bdt) + ' OR auftragende = 0)';
      SQL_Get(aQ2, S);
      while not aQ2.EOF do
      begin
        Laufzeit := TStartStopEintrag.Create;
        Laufzeit.Start := aQ2.FieldByName('auftragstart').AsFloat;
        if Laufzeit.Start < bdt then
          Laufzeit.Start := bdt;
        Laufzeit.RuestStart := aQ2.FieldByName('rueststart').AsFloat;
        if Laufzeit.RuestStart < bdt then
          Laufzeit.RuestStart := bdt;
        Laufzeit.Stop := aQ2.FieldByName('auftragende').AsFloat;
        if Laufzeit.Stop = 0 then
          Laufzeit.Stop := edt;
        if Laufzeit.Stop > edt then
          Laufzeit.Stop := edt;
        laufzeitlist.Add(Laufzeit);
        aQ2.Next;
      end;

      stillist.Clear;
      S := 'SELECT tpm_stillog.kommt, tpm_stillog.geht, tpm_stillstaende.gruppe, tpm_stillstaende.geplant, '
        + ' tpm_stillog.stillstandnr grundnr FROM tpm_stillog '
        + ' LEFT JOIN tpm_stillstaende ON tpm_stillog.stillstandnr = tpm_stillstaende.stillstandnr '
        + ' WHERE maschnr = ' + IntToStr(MaschNr) + ' AND kommt <= ' + FloatToPunktString(edt)
        + ' AND (geht >= ' + FloatToPunktString(bdt) + ' OR geht = 0)';
      SQL_Get(aQ2, S);
      while not aQ2.EOF do
      begin
        Stillstand := TStillstandEintrag.Create;
        Stillstand.Kommt := aQ2.FieldByName('kommt').AsFloat;
        if Stillstand.Kommt < bdt then
          Stillstand.Kommt := bdt;
        Stillstand.Geht := aQ2.FieldByName('geht').AsFloat;
        if Stillstand.Geht = 0 then
          Stillstand.Geht := edt;
        if Stillstand.Geht > edt then
          Stillstand.Geht := edt;
        Stillstand.GrundNr := aQ2.FieldByName('grundnr').AsInteger;
        Stillstand.Geplant := aQ2.FieldByName('geplant').AsInteger = 1;
        Stillstand.Gruppe := aQ2.FieldByName('gruppe').AsInteger;
        stillist.Add(Stillstand);
        aQ2.Next;
      end;

      Geplant := 0;
      Ungeplant := 0;
      ausfall := 0;
      Ruest := 0;
      Logistik := 0;
      ungebucht := 0;
      zrges := 0;
      for J := 0 to laufzeitlist.Count - 1 do
      begin
        Laufzeit := laufzeitlist.Items[J];
        zrges := zrges + (Laufzeit.Stop - Laufzeit.RuestStart) * 1440;
        for I := 0 to stillist.Count - 1 do
        begin
          Stillstand := stillist.Items[I];
          zrstill := DateOverlap(Laufzeit.RuestStart, Laufzeit.Stop, Stillstand.Kommt, Stillstand.Geht);
          if Stillstand.Geplant then
            Geplant := Geplant + zrstill
          else
            Ungeplant := Ungeplant + zrstill;

          if Stillstand.Gruppe = 0 then
            ausfall := ausfall + zrstill;
          if Stillstand.Gruppe = 1 then
            Ruest := Ruest + zrstill;
          if Stillstand.Gruppe = 2 then
            Logistik := Logistik + zrstill;
          if Stillstand.Gruppe = 3 then
            ungebucht := ungebucht + zrstill;
        end;
      end;
      stillgesamt := Ungeplant + Geplant;
      Lauf := zrges - stillgesamt;
      soll := zrges - geplant;
      if soll< 0 then
        soll := 0;
      S := 'UPDATE tpm_schicht SET '
        + ' A_SOLLLAUFZEIT = ' + IntToStr(round(soll)) + ','
        + ' A_ISTLAUFZEIT = ' + IntToStr(round(Lauf)) + ','
        + ' A_GEPLANT = ' + IntToStr(round(Geplant)) + ','
        + ' A_UNGEPLANT = ' + IntToStr(round(Ungeplant)) + ','
        + ' A_ANLAGENAUSFALL = ' + IntToStr(round(ausfall)) + ','
        + ' A_RUESTEN = ' + IntToStr(round(Ruest)) + ','
        + ' A_LOGISTIK = ' + IntToStr(round(Logistik)) + ','
        + ' A_NICHTGEBUCHT = ' + IntToStr(round(ungebucht))
        + ' WHERE nr = ' + IntToStr(Nr);
      SQL_Insert(aU, S);
      aQ1.Next;
    end;
  finally
    stillist.Destroy;
    laufzeitlist.Destroy;
  end;
end;

procedure CCC_TaktzeitIstSchreiben;
var s, s2 : string;
    sl : TStringList;
    i : Integer;

begin
  // IstTaktzeiten für aktuelle Schichteinträge schreiben
  // Großes SQL Statement. Läuft schneller durch als Schleife für jede Maschine ML 26.09.2017
  // SQL Server :
{$IFDEF INCL_MSADO}
// TPM_SCHICHT aktualisieren
  s := 'SELECT MAX(nr) mnr FROM tpm_schicht '
    + ' WHERE maschnr IN (select maschid FROM maschine WHERE oeerelevant=1) '
    + ' GROUP BY maschnr';
  SQL_Get(Daten.qSuch4, s);
  sl := TStringList.Create;
  while not Daten.qSuch4.Eof do
  begin
    sl.Add(Daten.qSuch4.FieldByName('mnr').AsString);
    Daten.qSuch4.Next;
  end;
  for i := 0 to sl.Count-1 do
  begin
      s := 'UPDATE TPM_SCHICHT SET ISTTAKT = sub.isttaktreal FROM '
    + ' (SELECT  ROUND(((CAST(a_istlaufzeit AS FLOAT) * 60.0) / ((CAST(produziert AS FLOAT)/CAST(kavitaet AS FLOAT))*CAST(var_kavitaet AS FLOAT))),2) isttaktreal, '
    + ' isttakt, produziert, var_kavitaet, kavitaet, a_istlaufzeit, nr '
    + ' FROM tpm_schicht WHERE nr = ' +sl[i] + ' AND betriebsauftragnr '
    + ' IS NOT NULL '
    + ' AND (produziert*kavitaet)>0 AND A_ISTLAUFZEIT>0 '
    + ' AND datumzeit > ' + FloatToPunktString(Now-1)
    + ' ) AS sub '
    + ' WHERE tpm_schicht.nr=sub.nr '; //  Noch mal eine bessere Filterung

    SQL_Insert(Daten.qUpdate,s);
  end;

  sl.Free;
 (* s := 'UPDATE TPM_SCHICHT SET ISTTAKT = sub.isttaktreal FROM '
    + ' (SELECT  ROUND(((CAST(a_istlaufzeit AS FLOAT) * 60.0) / ((CAST(produziert AS FLOAT)/CAST(kavitaet AS FLOAT))*CAST(var_kavitaet AS FLOAT))),2) isttaktreal, '
    + ' isttakt, produziert, var_kavitaet, kavitaet, a_istlaufzeit, nr '
    + ' FROM tpm_schicht WHERE nr IN ( '
    + ' SELECT MAX(nr) FROM tpm_schicht '
    + ' WHERE maschnr IN (select maschid FROM maschine WHERE oeerelevant=1) '
    + ' GROUP BY maschnr) AND betriebsauftragnr '
    + ' IS NOT NULL '
    + ' AND (produziert*kavitaet)>0 AND A_ISTLAUFZEIT>0 '
    + ' AND datumzeit > ' + FloatToPunktString(Now-1)
    + ' ) AS sub '
    + ' WHERE tpm_schicht.nr=sub.nr '; //  Noch mal eine bessere Filterung
  SQL_Insert(Daten.qUpdate, s);
  *)
  s := ' UPDATE aarchiv SET taktzeitist =sub.isttaktreal FROM '
    + ' (SELECT  ROUND(((CAST(SUM(a_istlaufzeit) AS FLOAT) * 60.0) / ((CAST(SUM(produziert) AS FLOAT)/CAST(MAX(kavitaet) AS FLOAT))*CAST(MAX(var_kavitaet) AS FLOAT)))*100,0) isttaktreal, '
    + ' betriebsauftragnr '
    + ' FROM tpm_schicht WHERE betriebsauftragnr IN '
    + ' (SELECT betriebsauftragnr FROM PDE WHERE stat=0) AND (produziert*kavitaet)>0 AND A_ISTLAUFZEIT>0 GROUP BY betriebsauftragnr) '
    + ' AS sub '
    + ' WHERE aarchiv.betriebsauftragnr = sub.betriebsauftragnr ';
  SQL_Insert(Daten.qUpdate, s);


{$ELSE}
  // Geht nicht anders. Verschachteltes SQL Statement braucht ewig ! ML 27.09.2017
  sl := TStringList.Create;
  try
    s := '  SELECT nr,  ROUND(((CAST(a_istlaufzeit AS FLOAT) * 60.0) / ((CAST(produziert AS FLOAT)/CAST(kavitaet AS FLOAT))*CAST(var_kavitaet AS FLOAT))),2) isttaktreal '
       + ' FROM tpm_schicht WHERE nr IN ( '
       + ' SELECT MAX(nr) FROM tpm_schicht '
       + ' WHERE maschnr IN (select maschid FROM maschine WHERE oeerelevant=1) '
       + ' GROUP BY maschnr) '
       + ' AND betriebsauftragnr IS NOT NULL AND (produziert*kavitaet)>0 AND A_ISTLAUFZEIT>0 ';
    Daten.qSuch4.SQL.Text := s;
    Daten.qSuch4.Open;
    while not Daten.qSuch4.Eof do
    begin
      sl.Add('UPDATE tpm_schicht SET isttakt=' +FloatToPunktString(Daten.qSuch4.FieldByName('isttaktreal').AsFloat)
        + ' WHERE nr=' + IntToStr(Daten.qSuch4.FieldByName('nr').AsInteger));
        Daten.qSuch4.Next;
    end;
(*   Archiv Update ist zu langsam.
    s := 'SELECT  ROUND(((CAST(SUM(a_istlaufzeit) AS FLOAT) * 60.0) / ((CAST(SUM(produziert) AS FLOAT)/CAST(MAX(kavitaet) AS FLOAT))*CAST(MAX(var_kavitaet) AS FLOAT)))*100,0) isttaktreal, '
      + ' betriebsauftragnr '
      + ' FROM tpm_schicht WHERE betriebsauftragnr IN (SELECT betriebsauftragnr FROM PDE WHERE stat=0) AND (produziert*kavitaet)>0 AND A_ISTLAUFZEIT>0 GROUP BY betriebsauftragnr ';
    Daten.qSuch4.SQL.Text := s;
    Daten.qSuch4.Open;
    while not Daten.qSuch4.Eof do
    begin
      sl.Add('UPDATE aarchiv SET taktzeitist=' + FloatToPunktString(Daten.qSuch4.FieldByName('isttaktreal').AsFloat)
        + ' WHERE betriebsauftragnr=''' + Daten.qSuch4.FieldByName('betriebsauftragnr').AsString + '''');
        Daten.qSuch4.Next;
    end;
  *)
    Daten.qUpdate.Database.StartTransaction;
    for i := 0 to sl.Count-1 do
    begin
      s2 := sl[i];
      SQL_Insert(Daten.qUpdate,s2);
    end;
    Daten.qUpdate.Database.Commit;
  except on ex:Exception do
    SchreibeMeldung('Exception on writing current Cycletime in tpm_schicht: ' + ex.Message,0);
  end;
  sl.Free;

{$ENDIF}
end;

procedure CheckJobPrestart;
var s, lizenz, banr, nr, artnr, bez : string;
    res : integer;
    _jetzt : real;
begin
  _jetzt := now;
  s := 'SELECT * FROM pde WHERE startdatumzeit < ' + FloatToPunktString(_jetzt) + ' AND prestart = 1';
  SQL_Get(Daten.qSuch, S);
  while not Daten.qSuch.EOF do
  begin
    Lizenz := Daten.qSuch.FieldByName('Lizenz').AsString;
    BANr := Daten.qSuch.FieldByName('BetriebsAuftragNr').AsString;
    artnr := Daten.qSuch.FieldByName('AuftragNr').AsString;
    bez := Daten.qSuch.FieldByName('bezeichnung').AsString;
    Nr := Daten.qSuch.FieldByName('Nr').AsString;
    s := 'SELECT * FROM pde WHERE lizenz = ''' + lizenz + ''' AND stat < 2';
    SQL_Get(Daten.qSuch2, s);
    if not daten.qSuch2.IsEmpty then
    begin
      // Beende/ Unterbreche laufenden Auftrag
      LogUsrEvent(Daten.qSuch3, Daten.qUpdate, 129, 'WFA', Daten.qSuch2.FieldByName('Betriebsauftragnr').AsString, '');
      res := S7Main.S7_Auftrag.Beenden(Lizenz);
      if res <> 0 then  //Fehler bei Auftragende
          CCC_Job_erzeugen(Daten.qUpdate, Lizenz, GetL('Fehler bei Auftragende: ') + IntToStr(res),
            GetL('BDE'), '', GetL('Bediener'), GetL('Fehler'), False, 0);
    end;
    // Starte Prestart Job
    LogUsrEvent(Daten.qSuch3, Daten.qUpdate, 126, 'WSA', banr, '');
    res := S7Main.S7_Auftrag.Starten(Lizenz, banr, false);

    if res <> 0 then
    begin
      //Fehler bei Auftragstart
      CCC_Job_erzeugen(Daten.qUpdate, Lizenz, GetL('Fehler bei Auftragstart: ') + IntToStr(res),
        GetL('BDE'), '', GetL('Bediener'), GetL('Fehler'), False, 0);
      //*****************************************************************
      //  PROTOKOLL Schreiben
      //*****************************************************************
      SQLStr := 'INSERT INTO AuftragstartProt (Nr,Maschine,BetriebsauftragNr,AuftragNr,'
        + ' Bezeichnung,DatumZeitStr,DatumZeit,Modul,Status)'
        + 'VALUES(AuftragstartProtID.NextVal'
        + ',''' + lizenz
        + ''',''' + banr
        + ''',''' + artnr
        + ''',''' + bez
        + ''',''' + DateTimeToStr(_jetzt)
        + ''',''' + FloatToStr2(_jetzt)
        + ''',''' + GetL('Service')
        + ''',''' + GetL('Fehler: ') + IntToStr(res)
        + ''')';
      SQL_Insert(Daten.qUpdate, SQLStr);
    end;

    // Setze Prestart auf 0
    S := 'UPDATE pde SET prestart = 0 WHERE nr = ' + nr;
    SQL_Insert(Daten.qUpdate, s);
    Daten.qSuch.Next;
  end;
end;

procedure CCC_Auto_Ruesten2;
var
  S, Lizenz, BANr, Nr: string;
  MaschNr, WSig, RSig: Integer;
  RZeit, RStart, FStart, FZeit: Real;
begin
  RSig := 0;

  S := 'select * from Ruest_Auto';
  SQL_Get(Daten.qSuch, S);
  while not Daten.qSuch.EOF do
  begin
    Nr := Daten.qSuch.FieldByName('Nr').AsString;
    MaschNr := Daten.qSuch.FieldByName('MaschNr').AsInteger;
    Lizenz := Daten.qSuch.FieldByName('Lizenz').AsString;
    RStart := Daten.qSuch.FieldByName('RuestStart').AsFloat;
    RZeit := Daten.qSuch.FieldByName('Ruestzeit').AsFloat;
    WSig := Daten.qSuch.FieldByName('Ruest_SignalNr').AsInteger;
    FStart := Daten.qSuch.FieldByName('FreigabeStart').AsFloat;
    FZeit := Daten.qSuch.FieldByName('FreigabeZeit').AsFloat;

    if not SQL2GetBool(Daten.qSuch, 'PDE', 'Lizenz', Lizenz, 'Stat', '1') then
      Exit;
    BANr := Daten.qSuch.FieldByName('BetriebsAuftragNr').AsString;

    if SQL2GetBool(Daten.qSuch, 'Signal_Maschine', 'MaschNr', IntToStr(MaschNr), 'SignalNr',
      IntToStr(TTT_GetSignalNr(CRUESTEN2))) then
      RSig := Daten.qSuch.FieldByName('Istwert').AsInteger
    else
      Exit;

    if WSig = 1 then
    begin
      S7Main.Schreibe_SPS_Wert(MaschNr, TTT_GetSignalNr(CWARTENAUFFREIGABE), 1);
      S := 'update Ruest_Auto set'
        + ' RuestZeit = ''' + FloatToStr2(RZeit + (N_o_w - RStart)) + ''','
        + ' RuestStart = ''' + FloatToStr2(N_o_w) + ''','
        + ' FreigabeStart = ''' + FloatToStr2(N_o_w) + ''''
        + ' where Nr = ' + Nr;
      SQL_Insert(Daten.qUpdate, S);

      if RSig = 2 then
      begin
        S7Main.Schreibe_SPS_Wert(MaschNr, TTT_GetSignalNr(CWARTENAUFFREIGABE), 2);
        S := 'update Ruest_Auto set Ruest_SignalNr = 0 where Nr = ' + Nr;
        SQL_Insert(Daten.qUpdate, S);
      end;
    end;

    if WSig = 0 then
    begin
      if RSig = 0 then
      begin
        S7Main.Schreibe_SPS_Wert(MaschNr, TTT_GetSignalNr(CWARTENAUFFREIGABE), 0);
        S7Main.S7_Auftrag.Starten(Lizenz, BANr, True);
        LogUsrEvent(Daten.qSuch2, Daten.qUpdate, 126, 'WUA', BANr, '');
        S := 'update AArchiv set'
          + ' RuestZeitIst = ''' + IntToStr(Trunc(RZeit * 1440)) + ''','
          + ' RuestFreigabe =  ''' + IntToStr(Trunc(FZeit * 1440)) + ''''
          + ' where Maschine = ''' + Lizenz + ''' and BetriebsAuftragNr = ''' + BANr + '''';
        SQL_Insert(Daten.qUpdate, S);
        S := 'delete from Ruest_Auto where Lizenz = ''' + Lizenz + '''';
        SQL_Insert(Daten.qUpdate, S);
        S7Main.Schreibe_SPS_Wert(MaschNr, TTT_GetSignalNr(CWARTENAUFFREIGABE), 0);
      end;
      if RSig = 1 then
      begin
        S7Main.Schreibe_SPS_Wert(MaschNr, TTT_GetSignalNr(CWARTENAUFFREIGABE), 1);
        S := 'update Ruest_Auto set Ruest_SignalNr = 1 where Nr = ' + Nr;
        SQL_Insert(Daten.qUpdate, S);
      end;
      S := 'update Ruest_Auto set'
        + ' FreigabeZeit = ''' + FloatToStr2(FZeit + (N_o_w - FStart)) + ''','
        + ' FreigabeStart = ''' + FloatToStr2(N_o_w) + ''''
        + ' where Nr = ' + Nr;
      SQL_Insert(Daten.qUpdate, S);
    end;
    Daten.qSuch.Next;
  end;
end;

procedure TTT_InsertStillstandEvent(qUpdate: TCO_Query; aMaschNr: string);
var
  KEY, S: string;
begin
  S := 'select Max(Nr) as CNT from TPM_Stillog where MaschNr = ' + aMaschNr;
  SQL_Get(qUpdate, S);
  KEY := qUpdate.FieldByName('CNT').AsString;
  try
    S := 'insert into ERPEvents (Nr, BetriebsAuftragNr, Event, Datumzeit)'
      + ' values (ERPEventsId.NextVal,'
      + '''' + KEY + ''','
      + '''H'','
      +  FloatToPunktString(N_o_w) + ')';
    SQL_Insert(qUpdate, S);
  except
  end;
end;

procedure CCC_InsertStillGehtEvent(KeyNr: string);
var
  S: string;
begin
  try
    S := 'insert into ERPEvents (Nr, BetriebsAuftragNr, Event, Datumzeit)'
      + ' values (ERPEventsId.NextVal,'
      + '''' + KeyNr + ''','
      + '''G'','
      + FloatToPunktString(N_o_w) + ')';
    SQL_Insert(Daten.qUpdate, S);
  except
  end;
end;

procedure CCC_SchreibeSystemID;
var
  S, sysid, Kunde: string;
  SerialNum: Longword;
  A, B: Longword;
  Buffer: array[0..255] of Char;
  I: Cardinal;
  stage : Integer;
begin
  stage := 0;
  try
    S := 'SELECT firma FROM setup WHERE nr = 1';
    SQL_Get(Daten.qSuch, S);
    Kunde := '';
  stage := 100;
    if not Daten.qSuch.IsEmpty then
      Kunde := Daten.qSuch.FieldByName('firma').AsString;
    A := 1;
  stage := 200;
    for I := 1 to Length(Kunde) do
    begin
      stage := 200 + i;
      A := A * ord(Kunde[I]);
      A := A mod (maxint div 128);
    end;
  stage := 300;
    I := A;
//    if GetVolumeInformation('c:\', Buffer, SizeOf(Buffer), @SerialNum, A, B, nil, 0) then
//    begin
//  stage := 400;
//      sysid := IntToStr(ABS((I * SerialNum) mod Longword(MaxInt)));
//      S := 'UPDATE setup SET SystemID = ''' + sysid + ''' WHERE nr=1';
//      SQL_Insert(Daten.qUpdate, S);
  stage := 500;
//    end;
  except on ex : exception do
    SchreibeMeldung('No SystemID in Table Setup ('+IntToStr(stage)+'): ' + ex.Message, 0);
  end;
end;

function CCC_CheckLicenses: Boolean;
var
  SQLStr: string;
  Cnt: Integer;
  sysid: Cardinal;
  lizid: string;
  cc: TCryptClass;
begin
  Result := True;
  try
    try
      SQLStr := 'SELECT COUNT(*) cnt FROM MASCHINE WHERE maschaktiv = 1 AND INKAPAZITAET = 1';
      SQL_Get(Daten.qSuch, SQLStr);
      Cnt := Daten.qSuch.FieldByName('cnt').AsInteger;
      cc := TCryptClass.Create(True);
      SQLStr := 'SELECT SystemID, licensekey FROM setup WHERE nr = 1';
      SQL_Get(Daten.qSuch, SQLStr);
      sysid := Daten.qSuch.FieldByName('systemid').AsInteger;
      lizid := Daten.qSuch.FieldByName('licensekey').AsString;
      if lizid <> '' then
      begin
        cc.SystemID := sysid;
        cc.CryptKeyString := lizid;
        if not cc.isValid then
        begin
          SchreibeMeldung('No valid licensekey', 0);
          Result := False;
        end;
        if cc.Day30Over then
        begin
          SchreibeMeldung('Test period over', 0);
          Result := False;
        end;
        if ((not cc.Unlimited) and (cc.MashineAmount < Cnt)) then
        begin
          SchreibeMeldung('To few machine licenses', 0);
          Result := False;
        end;
      end
      else
      begin
        SchreibeMeldung('No valid licensekey', 0);
        Result := False;
      end;
    finally
      FreeAndNil(cc);
    end;
  except
    SchreibeMeldung('Problem checking Licenses', 0);
  end;
end;

//******************************************************************************
//******************************************************************************
//******************************************************************************

function TTT_GetSchichtTyp(qSuch4: TCO_Query; MaschNr: Integer; Datum: Real; Schicht: Integer): string;
var
  Gruppe: Integer;
  D: Real;
begin
  Result := '';
  if Shift_Model = 1 then
    exit;
  D := RoundTo(Datum, -5);

  if Schicht = 0 then
  begin
    if Frac(D) < RoundTo(Schicht1, -5) then
      Schicht := 3
    else
      if Frac(D) >= RoundTo(Schicht3, -5) then
        Schicht := 3
      else
        if Frac(D) >= RoundTo(Schicht2, -5) then
          Schicht := 2
        else
          if Frac(D) >= RoundTo(Schicht1, -5) then
            Schicht := 1;
    if (Shift_Model = 2) and (Schicht = 3) then
      Schicht := 2;
  end;

  if Frac(D) < RoundTo(Schicht1, -5) then
    D := Trunc(D - 1)
  else
    D := Trunc(D);

  

  if (SchichtTypArray[MaschNr].LastTruncDate <> D)
    or (SchichtTypArray[MaschNr].LastShift <> Schicht)
    or (SchichtTypArray[MaschNr].ShiftType = '')
    or (SchichtTypArray[MaschNr].LastCall < now - 10/1440)
  then
  begin
    SchichtTypArray[MaschNr].LastTruncDate := Trunc(D);
    SchichtTypArray[MaschNr].LastShift := Schicht;
    SchichtTypArray[MaschNr].LastCall := now;

    if SQLGetBool(qSuch4, 'Maschine', 'Maschnr', IntToStr(MaschNr)) then
    begin
      Gruppe := qSuch4.FieldByName('WERKSKALENDERGRUPPE').AsInteger;

      if SQLGetBool(qSuch4, 'Kalender', 'DatumInt', IntToStr(Trunc(D))) then
      begin
        if Gruppe = 0 then
          case Schicht of
            1: Result := qSuch4.FieldByName('SHIFT_TYP_S1').AsString;
            2: Result := qSuch4.FieldByName('SHIFT_TYP_S2').AsString;
            3: Result := qSuch4.FieldByName('SHIFT_TYP_S3').AsString;
          end;

        if Gruppe > 0 then
        try
          case Schicht of
            1: Result := qSuch4.FieldByName('SHIFT_TYP_' + IntToStr(Gruppe) + '_S1').AsString;
            2: Result := qSuch4.FieldByName('SHIFT_TYP_' + IntToStr(Gruppe) + '_S2').AsString;
            3: Result := qSuch4.FieldByName('SHIFT_TYP_' + IntToStr(Gruppe) + '_S3').AsString;
          end;
        except
          Result := '';
        end;
      end;
    end;
    SchichtTypArray[MaschNr].ShiftType := Result;
  end
  else
    Result := SchichtTypArray[MaschNr].ShiftType;

end;

procedure CCC_FolgeAuftrag_STarten;
var
  S: string;
  BANr, ArtNr: string;
  Soll, Ist: Integer;
  Alwaysautostartbei, autostartbei: Integer;
  Startzeit: Real;
  aLizenz: string;
begin
  // Ist Autostart für Maschine aktiv?
  Alwaysautostartbei := TCO_Setup.GetParamInt(Daten.qSuch, 'SVC_ForceAutoStartAtPCNT');
  if Alwaysautostartbei > 0 then
  begin
    S := ' UPDATE maschine SET autostartbei = ' + IntToSTr(Alwaysautostartbei);
    SQL_Insert(Daten.qUpdate, S);
  end;
  S := 'SELECT autostartbei, Lizenz FROM Maschine where autostartbei > 0';
  SQL_Get(Daten.qSuch, S);
  while not Daten.qSuch.EOF do
  begin
    aLizenz := Daten.qSuch.FieldByName('Lizenz').AsString;
    autostartbei := Daten.qSuch.FieldByName('autostartbei').AsInteger;
    // Soll- und Iststückzahl holen
    S := 'SELECT startdatumzeit, sollwert, istwert, auftragnr, case when pack IS null OR pack = '''''
       + ' then ''0'' else pack end pack, betriebsauftragnr, startdatumzeit '
       + ' FROM pde'
       + ' WHERE lizenz = ''' + aLizenz + ''' AND stat < 2';
    SQL_Get(Daten.qSuch2, S);
    if not Daten.qSuch2.IsEmpty then
    begin
      Soll := Daten.qSuch2.FieldByName('sollwert').AsInteger;
      if Ende_Aus_Verpackt then
        Ist := Daten.qSuch2.FieldByName('pack').AsInteger
      else
        Ist := Daten.qSuch2.FieldByName('istwert').AsInteger;
      BANr := Daten.qSuch2.FieldByName('betriebsauftragnr').AsString;
      ArtNr := Daten.qSuch2.FieldByName('auftragnr').AsString;
      Startzeit := Daten.qSuch2.FieldByName('startdatumzeit').AsFloat;
      // Ist Stückzahl erreicht?
      if Ist > (Soll * autostartbei div 100) then
      begin
        // Ja
        // Aktuellen Auftrag beenden
        S := 'SELECT betriebsauftragnr, auftragnr FROM pde WHERE stat > 1 AND lizenz =''' + aLizenz
          + ''' ORDER BY startdatumzeit';
        // Wenn artikelnr identisch, dann auftrag starten
        SQL_Get(Daten.qSuch2, S);
        Daten.qSuch2.First;
        if not Daten.qSuch2.EOF then
        begin
          if Daten.qSuch2.FieldByName('auftragnr').AsString = ArtNr then
          begin
            // Auftrag muss mindestens 10 Minuten gelaufen sein bevor der nächste automtisch gestartet werden kann.
            if Startzeit < (N_o_w - Zeit_zum_AutoStart) then
            begin
              LogUsrEvent(Daten.qSuch3, Daten.qUpdate, 129, 'WFA', BANr, '');
              if S7Main.S7_Auftrag.Beenden(aLizenz) = 0 then
              begin
                S7Main.S7_Auftrag.Starten(aLizenz, Daten.qSuch2.FieldByName('betriebsauftragnr').AsString, False);
                LogUsrEvent(Daten.qSuch3, Daten.qUpdate, 126, 'WSA', Daten.qSuch2.FieldByName('betriebsauftragnr').AsString, '');
                Daten.qSuch2.Last;
              end
              else
              begin
                // Zurücksetzen des Autostart
                S := 'UPDATE maschine SET autostartbei = ' + IntToStr(-autostartbei)
                  + ' WHERE lizenz = ''' + aLizenz + '''';
                SQL_Insert(Daten.qUpdate, S);

              end;
            end;
          end
          else
          begin
            // Zurücksetzen des Autostart
            S := 'UPDATE maschine SET autostartbei = ' + IntToStr(-autostartbei)
              + ' WHERE lizenz = ''' + aLizenz + '''';
            SQL_Insert(Daten.qUpdate, S);

          end;
        end;
      end;
    end
    else
    begin
      // Zurücksetzen des Autostart
      S := 'UPDATE maschine SET autostartbei = ' + IntToStr(-autostartbei)
        + ' WHERE lizenz = ''' + aLizenz + '''';
      SQL_Insert(Daten.qUpdate, S);
    end;

    Daten.qSuch.Next;
  end;
end;

procedure CCC_SetSchichtKonstante;
begin
  if Shift_Model <> 2 then
  begin
    DSchicht1 := GetSchichtDauer(1);
    DSchicht2 := GetSchichtDauer(2);
    DSchicht3 := GetSchichtDauer(3);

    MaxSchichtTime := MAX(DSchicht1, MAX(DSchicht2, DSchicht3));
  end
  else
  begin
    //    Schicht1 := 5 / 24;
    //    Schicht2 := 17 / 24;
    //    Schicht3 := 17 / 24;

    DSchicht1 := Trunc((Schicht2 - Schicht1) * 1440);
    DSchicht2 := 1440 - DSchicht1;
    DSchicht3 := 0;

    MaxSchichtTime := 720;
  end;

  vorSchicht1 := Schicht1 - 1 / 1440;
  vorSchicht2 := Schicht2 - 1 / 1440;
  vorSchicht3 := Schicht2 - 1 / 1440;
end;

procedure CCC_Verpackt_aus_Ausschuss_Berechnen;
var
  S: string;
begin
  S := 'Update PDE set Pack = Decode(Istwert, Null, 0, Istwert) - Decode(Ausschuss, Null, 0, Ausschuss)';
  SQL_Insert(Daten.qUpdate, S);
  S := 'Update PDE set Pack = 0 where Pack < 0';
  SQL_Insert(Daten.qUpdate, S);

  S := 'Update AArchiv set VerpacktInt = ProduziertInt - Ausschuss where VerpacktInt <> ProduziertInt - Ausschuss';
  SQL_Insert(Daten.qUpdate, S);
  S := 'Update AArchiv set VerpacktInt = 0 where VerpacktInt < 0';
  SQL_Insert(Daten.qUpdate, S);

  S := 'Update MaschInf set Pack = Stueck - Ausschuss';
  SQL_Insert(Daten.qUpdate, S);
  S := 'Update MaschInf set Pack = 0 where Pack < 0';
  SQL_Insert(Daten.qUpdate, S);

  // Änderung
  // TPM_Schicht für einen Tag zurück berechnen

  S := 'Update TPM_Schicht set Verpackt = Produziert - (Ausschuss +autoausschuss) where DatumZeit > ''' +
    IntToStr(Trunc(N_o_w) - 1) + '''';
  SQL_Insert(Daten.qUpdate, S);
  S := 'Update TPM_Schicht set Verpackt_org = verpackt where DatumZeit > ''' +
    IntToStr(Trunc(N_o_w) - 1) + '''';
  SQL_Insert(Daten.qUpdate, S);
  S := 'Update TPM_Schicht set Verpackt = 0 where Verpackt < 0 and DatumZeit > ''' + IntToStr(Trunc(N_o_w) - 1) + '''';
  SQL_Insert(Daten.qUpdate, S);
  S := 'Update TPM_Schicht set Verpackt_org = 0 where Verpackt_org < 0 and DatumZeit > ''' + IntToStr(Trunc(N_o_w) - 1) + '''';
  SQL_Insert(Daten.qUpdate, S);
end;

procedure CCC_Maschinen_Wartung;
var
  I, Schuss: Integer;
  S: string;
begin
  for I := 1 to Anzahl_Masch do
  begin
    if Includis[I].IstArchiviert then
      continue;
    if (StueckSchicht[I].Altwert > 0) and (StueckSchicht[I].Istwert > StueckSchicht[I].Altwert) then
    begin
      Schuss := StueckSchicht[I].Istwert - StueckSchicht[I].Altwert;
      S := 'update Maschinenwartung set AktuellZyklus = AktuellZyklus + ' + IntToStr(Schuss)
        + ' where Lizenz = ''' + StueckSchicht[I].Maschine + '''';
      SQL_Insert(Daten.qUpdate, S);
    end;
    StueckSchicht[I].Altwert := StueckSchicht[I].Istwert;
  end;

  S := 'select * from MaschinenWartung where AktuellZyklus >= AktionZyklus';
  SQL_Get(Daten.qSuch, S);
  while not Daten.qSuch.EOF do
  begin
    S := 'INSERT INTO BDA (Nr, Lizenz, DatumZeit, Bezeichnung,'
      + ' Quelle, Signal, Sollwert) VALUES (BDAId.NextVal'
      + ',''' + Daten.qSuch.FieldByName('Lizenz').AsString
      + ''',' + FloatToPunktString(N_o_w)
      + ',''' + GetL('Wartungsüberprüfung Maschine "') + Daten.qSuch.FieldByName('Lizenz').AsString +
      GetL('" einleiten')
      + ''',''' + GetL('Maschinenwartung')
      + ''',''' + GetL('Stückzahl Maschine')
      + ''',''' + Daten.qSuch.FieldByName('AktuellZyklus').AsString
      + ''')';
    SQL_Insert(Daten.qUpdate, S);

    if Active_Alarming then
    begin // Aktive Alarmierung bei Eintrag über PopUp
      try
        SQLStr := 'INSERT INTO alertnotification (Nr, Alertstamp, Message, Typ, Confirmation) VALUES ('
          + 'AlertNotificationId.NextVal, '
          + '''' + FloatToStr2(N_o_w) + ''', '
          + '''' + Daten.qSuch.FieldByName('Lizenz').AsString + ' : ' + GetL('Maschinenwartung') + '-'
          + GetL('Stückzahl Maschine') + ''',' + IntToStr(ord(mtInformation)) + ', 0)';
        SQL_Insert(Daten.qUpdate, SQLStr);
      except
      end;
    end;

    S := 'INSERT INTO MaschinenwartungProt (Nr, Lizenz, Wartung, ZaehlerStand)'
      + ' VALUES (MaschinenwartungProtId.NextVal'
      + ',''' + Daten.qSuch.FieldByName('Lizenz').AsString
      + ''',''' + FloatToStr2(N_o_w)
      + ''',''' + Daten.qSuch.FieldByName('AktuellZyklus').AsString
      + ''')';
    SQL_Insert(Daten.qUpdate, S);

    S := 'update Maschinenwartung set AktuellZyklus = 0'
      + ' where Lizenz = ''' + Daten.qSuch.FieldByName('Lizenz').AsString + '''';
    SQL_Insert(Daten.qUpdate, S);

    Daten.qSuch.Next;
  end;
end;

procedure CCC_CheckBypass;
var
  S: string;
begin
  // Nachsehen ob Maschine in Block und kein Stillstand 6 gebucht ist
  S := 'SELECT maschine.maschnr, maschine.bypass, maschinf.zustandint FROM maschine '
    + ' JOIN maschinf ON maschine.maschnr=maschinf.maschnr ';
  SQL_Get(Daten.qSuch, S);
  while not Daten.qSuch.EOF do
  begin
    if Daten.qSuch.FieldByName('bypass').AsInteger = 1 then // Nachsehen ob Stillstand 6 aktiv ist
    begin
      S := 'SELECT * FROM tpm_stillog WHERE maschnr = ' + Daten.qSuch.FieldByName('maschnr').AsString
        + ' AND geht = 0 ';
      SQL_Get(Daten.qSuch2, S);
      if not Daten.qSuch2.IsEmpty then
      begin
        if Daten.qSuch2.FieldByName('stillstandnr').AsInteger <> 6 then
          // Stillstand beenden und neuen mit 6 erzeugen
        begin
          S := 'UPDATE tpm_stillog SET geht = ' + FloatToPunktString(Jetzt) + ' WHERE nr = '
            + IntToStr(Daten.qSuch2.FieldByName('nr').AsInteger);
          SQL_Insert(Daten.qUpdate, S);

          S := 'INSERT INTO TPM_Stillog (Nr,MaschNr,Schicht,Kommt,Stillstandnr,KommtStr,'
            + ' betriebsauftragnr, auftragnr, bezeichnung) VALUES(TPM_StillogID.Nextval'
            + ',''' + Daten.qSuch.FieldByName('Maschnr').AsString
            + ''',''' + IntToStr(Includis[1].Schicht)
            + ''',' + FloatToPunktString(Jetzt)
            + ',6,''' + DateTimeToStr(Jetzt)
            + ''',''-'',''-'',''-'')';
          SQL_Insert(Daten.qUpdate, S);
        end;
      end
      else
      begin
        // Stillstand mit 6 erzeugen
        S := 'INSERT INTO TPM_Stillog (Nr,MaschNr,Schicht,Kommt,Stillstandnr,KommtStr,'
          + ' betriebsauftragnr, auftragnr, bezeichnung) VALUES(TPM_StillogID.Nextval'
          + ',''' + Daten.qSuch.FieldByName('Maschnr').AsString
          + ''',''' + IntToStr(Includis[1].Schicht)
          + ''',' + FloatToPunktString(Jetzt)
          + ',6,''' + DateTimeToStr(Jetzt)
          + ''',''-'',''-'',''-'')';
        SQL_Insert(Daten.qUpdate, S);
      end;

    end
    else
    begin
      S := 'SELECT * FROM tpm_stillog WHERE maschnr = ' + Daten.qSuch.FieldByName('maschnr').AsString
        + ' AND geht = 0 AND stillstandnr = 6';
      SQL_Get(Daten.qSuch2, S);
      if not Daten.qSuch2.IsEmpty then
      begin
        S := 'UPDATE tpm_stillog SET geht = ' + FloatToPunktString(Jetzt) + ' WHERE nr = '
          + IntToStr(Daten.qSuch2.FieldByName('nr').AsInteger);
        SQL_Insert(Daten.qUpdate, S);
      end;
    end;
    Daten.qSuch.Next;
  end;
end;

procedure CCC_CheckBlock;
var
  S: string;
begin
  // Nachsehen, ob auf einer Maschine ein Stillstand gebucht ist,
  // auf der ein Auftrag mit auftrag_block aktiv läuft

  S := ' SELECT t.nr tnr FROM tpm_stillog t, pde p, maschine m'
    + ' WHERE m.lizenz = p.lizenz AND m.maschnr=t.maschnr AND p.auftrag_block = 1'
    + ' AND t.stillstandnr = 1 AND t.geht = 0 AND p.stat IN (0,1)';
  SQL_Get(Daten.qSuch, S);
  while not Daten.qSuch.EOF do
  begin
    ChangeDtCode(Daten.qUpdate, 6, Daten.qSuch.FieldByName('tnr').AsInteger, true, false, true, 'CB8158');
    Daten.qSuch.Next;
  end;
  // Wenn kein Auftrag auf Maschine, dann nicht blocken.
  // Nachsehen, ob Blockstillstand noch aktiv, wenn nicht Blockauftrag nicht mehr läuft
  S := 'SELECT maschnr FROM maschinf WHERE zustandint = 7 ';
  SQL_Get(Daten.qSuch, S);
  while not Daten.qSuch.EOF do
  begin
    // zustand und zustandint in maschinf anpassen
    S := 'UPDATE maschinf SET zustandint=stat WHERE maschnr = '
      + Daten.qSuch.FieldByName('maschnr').AsString + ' AND maschnr NOT IN '
      + '(SELECT maschnr FROM tpm_stillog WHERE geht = 0 AND stillstandnr=6)';
    SQL_Insert(Daten.qUpdate, S);
    Daten.qSuch.Next;
  end;
end;

procedure CCC_Taktzeit_Aus_Stamm_Update;
var
  S, Nr: string;
  A, B: Integer;
begin
  S := 'select PDE.Nr, PDE.Taktzeit, PDEStamm.Solltaktzeit, Maschine.Station, PDE.Zweifach'
    + ' from PDE, PDEStamm, Maschine'
    + ' where PDE.AuftragNr = PDEStamm.AuftragNr and PDE.Lizenz = Maschine.Lizenz'
    + ' and PDEStamm.Solltaktzeit <> PDE.Taktzeit and PDEStamm.Solltaktzeit > 0'
    + ' AND pde.stat = 2';
  SQL_Get(Daten.qDurchlauf, S);
  while not Daten.qDurchlauf.EOF do
  begin
    Nr := Daten.qDurchlauf.FieldByName('Nr').AsString;
    A := Daten.qDurchlauf.FieldByName('Solltaktzeit').AsInteger;
    B := Daten.qDurchlauf.FieldByName('Taktzeit').AsInteger;
    if (Daten.qDurchlauf.FieldByName('Station').AsString = '2')
      and (Daten.qDurchlauf.FieldByName('Zweifach').AsInteger = 1) then
      A := A div 2;

    if A <> B then
    begin
      S := 'update PDE set'
        + ' Taktzeit = ' + IntToStr(A) + ','
        + ' TaktzeitStr = ''' + FloatToStr2(A / 100) + ''''
        + ' where Nr = ' + Nr;
      SQL_Insert(Daten.qUpdate, S);
    end;
    Daten.qDurchlauf.Next;
  end;
end;

procedure CCC_JobSetupAndRestart(aCOAuftrag : TCO_Auftrag);
var s : String;
    mnr, liz, banr : string;
    stat, nr, prod, ist : integer;
    _now_ : TDateTime;
begin
  s := 'SELECT lizenz, maschnr FROM maschine';
  SQL_Get(Daten.qDurchlauf,s);
  while not Daten.qDurchlauf.Eof do
  begin
    mnr := Daten.qDurchlauf.FieldByName('maschnr').AsString;
    liz := Daten.qDurchlauf.FieldByName('lizenz').AsString;
    s := 'SELECT betriebsauftragnr, stat, STUECKGEZAEHLT, istwert FROM pde WHERE stat IN (0,1) AND lizenz = ''' + liz + '''';
    SQL_Get(Daten.qSuch,s);
    if not Daten.qSuch.IsEmpty then
    begin
      stat := Daten.qSuch.FieldByName('stat').AsInteger;
      banr := Daten.qSuch.FieldByName('betriebsauftragnr').AsString;
      prod := Daten.qSuch.FieldByName('STUECKGEZAEHLT').AsInteger;
      ist := Daten.qSuch.FieldByName('istwert').AsInteger;
      if stat = 0 then // Auftrag Rüstet. Ggf. Starten
      begin
        if ist > 0 then
          if prod = 0 then
          begin
            s := 'UPDATE pde SET stueckgezaehlt = 0 WHERE betriebsauftragnr = ''' + banr + '''';
            SQL_Insert(Daten.qUpdate, s);
          end;
        if prod > 0 then // Bereits Stueck gezählt
        begin
        // Testen ob Stückzahl = 0
          s := 'SELECT signal_maschine.istwert prod FROM signal_maschine '
            + ' LEFT JOIN signale ON signale.signalnr = signal_maschine.signalnr '
            + ' WHERE signale.signalart = 1 AND signal_maschine.maschnr = ' + mnr;
          SQL_Get(Daten.qSuch, s);
          if not Daten.qSuch.IsEmpty then
          begin
            if Daten.qSuch.FieldByName('prod').AsInteger = 0 then
            begin
              _now_ := Now;
              // Stillprot ändern
              s := 'SELECT MAX(nr) mnr FROM tpm_stillog WHERE maschnr = ' + mnr;
              SQL_Get(Daten.qSuch, s);
              if not Daten.qSuch.IsEmpty then
              begin
                nr := Daten.qSuch.FieldByName('mnr').AsInteger;
                s := 'UPDATE tpm_stillog SET geht = ' + FloatToPunktString(_now_) + ', gehtstr = '''
                  + DateTimeToStr(_now_) + ''' WHERE geht > 0 AND nr = ' + IntToStr(nr);
                SQL_Insert(Daten.qUpdate, s);

                s := 'UPDATE tpm_stillog SET dauer = ROUND((geht - kommt) * 1440) WHERE geht > 0 AND nr = ' + IntToStr(nr);
                SQL_Insert(Daten.qUpdate, s);
              end;
              Daten.qSuch.Close;
            // Laufzeitlog ändern
              s := 'SELECT MAX(nr) mnr FROM LaufzeitLog WHERE Betriebsauftragnr = ''' + banr + '''';
              SQL_Get(Daten.qSuch, s);
              if not Daten.qSuch.IsEmpty then
              begin
                nr := Daten.qSuch.FieldByName('mnr').AsInteger;
                s := 'UPDATE laufzeitlog SET AuftragStart = ' + FloatToPunktString(_now_) + ' WHERE nr = ' + IntToStr(nr);
                SQL_Insert(Daten.qUpdate, s);

                s := 'UPDATE LaufzeitLog SET RuestZeit = ROUND((AuftragStart - RuestStart) * 1440) '
                  + ' WHERE Nr = ' + IntToStr(nr);
                SQL_Insert(daten.qUpdate, SQLStr);
              end;
              Daten.qSuch.close;

              // Rüstprot ändern
              s := 'SELECT MAX(nr) mnr FROM ruestprot WHERE betriebsauftragnr = ''' + banr + ''' AND lizenz = ''' + liz + '''';
              SQL_Get(Daten.qSuch, s);
              if not Daten.qSuch.IsEmpty then
              begin
                nr := Daten.qSuch.FieldByName('mnr').AsInteger;
                s := 'UPDATE ruestprot SET ruestende = ' + FloatToPunktString(_now_) + ' WHERE nr = ' + IntToStr(nr);
                SQL_Insert(Daten.qUpdate, s);
                S := 'UPDATE RuestProt SET'
                  + ' RuestIst = ROUND((ruestende-rueststart)*1440)'
                  + ' WHERE nr = ' + IntToStr(nr);
                SQL_Insert(Daten.qUpdate, s);
              end;
              Daten.qSuch.Close;

              s := 'UPDATE pde SET bemerkung1 = '' '' WHERE betriebsauftragnr = ''' + banr + ''''; // Merker für C Event setzen
              SQL_Insert(Daten.qUpdate, s);
            end
            else
            begin  // Ggf. Event 'C' für Auftrag Start senden
              s := 'SELECT bemerkung1 FROM pde WHERE betriebsauftragnr = ''' + banr + '''';
              SQL_Get(Daten.qSuch, s);
              if not Daten.qSuch.IsEmpty then
              begin
                if Daten.qSuch.FieldByName('bemerkung1').AsString <> 'csend' then
                begin
                  s := 'UPDATE pde SET bemerkung1 = ''csend'' WHERE betriebsauftragnr = ''' + banr + '''';
                  SQL_Insert(Daten.qUpdate, s);

                  SQLStr := 'insert into ERPEvents (Nr, BetriebsAuftragNr, Event, Datumzeit)'
                    + ' values (ERPEventsId.NextVal,'
                    + '''' + banr + ''','
                    + '''C'','
                    + FloatToPunktString(now) + ')';
                    SQL_Insert(Daten.qUpdate, SQLStr);
                  end;
              end;
              Daten.qSuch.Close;
            end;
          end;
        end;
      end;
    end;
    Daten.qDurchlauf.Next;
  end;
  Daten.qDurchlauf.Close;
end;

procedure CCC_Calc_R2_Times;
var
  slEintrag : TSignalLogEintrag;
  slEintragList, slMList : TSignalLogEintragListe;
  stillEintrag : TStillstandEintrag;
  stillListe, stillMList : TStillstandEintragsListe;
  s, mnrs : string;
  schichtstart, schichtende : extended;
  m1, m2,i : integer;
   lauf, down, ges : Extended;
begin

  case Includis[1].Schicht of
    1: Schichtstart := Trunc(Jetzt) + Schicht1;
    2: Schichtstart := Trunc(Jetzt) + Schicht2;
    3: begin
        if frac(Jetzt) < Schicht1 then
          Schichtstart := Trunc(Jetzt) + Schicht3 -1
        else
          Schichtstart := Trunc(Jetzt) + Schicht3;
      end;
  end;

  schichtende := jetzt;
  if schichtende > jetzt then
    schichtende := jetzt;
  // Alle Einträge zwischen jetzt und Schichtanfang berechnen
  s := 'SELECT rueststart, ruestende, grund, maschine.maschid FROM ruestprot '
    + ' LEFT JOIN maschine ON maschine.lizenz = ruestprot.lizenz '
    + ' WHERE '
    + ' rueststart <= ' + FloatToPunktString(schichtende)
    + ' AND ( ruestende >= ' + FloatToPunktString(Schichtstart)
    + ' OR ruestende = 0 )';
  Daten.qSuch.SQL.Text := s;
  Daten.qSuch.Open;
  stillListe := TStillstandEintragsListe.create;
  while not Daten.qSuch.Eof do
  begin
    if Daten.qSuch.FieldByName('maschid').AsInteger <> 0 then
    begin
      stillEintrag := TStillstandEintrag.Create;
      stillEintrag.Kommt := Daten.qSuch.FieldByName('rueststart').AsFloat;
      if stillEintrag.Kommt < schichtstart then
        stillEintrag.Kommt := schichtstart;
      stillEintrag.Geht := Daten.qSuch.FieldByName('ruestende').AsFloat;
      if stillEintrag.Geht > schichtende then
        stillEintrag.Geht := schichtende;
      if stillEintrag.Geht < 1 then
        stillEintrag.Geht := schichtende;
      stillEintrag.GrundNr := Daten.qSuch.FieldByName('grund').AsInteger;
      stillEintrag.Maschnr := Daten.qSuch.FieldByName('maschid').AsInteger;
      stillListe.Add(stillEintrag);
    end;
    Daten.qSuch.Next;
  end;
  mnrs := stillListe.getMaschNrsString;
  if mnrs <> '' then
  begin
    s := 'SELECT * FROM signallog WHERE signalnr = '
      + ' (SELECT signalnr FROM signale WHERE signalart = '
      + IntToStr(MaschProgrammbetrieb[1].SignalNr) + ') AND '
      + ' startdatumzeit <= ' + FloatToPunktString(schichtende)
      + ' AND ( enddatumzeit >= ' + FloatToPunktString(Schichtstart)
      + ' OR enddatumzeit = 0 or enddatumzeit IS NULL ) '
      + ' AND maschnr IN ('+mnrs+') AND wert=1';
    Daten.qSuch.SQL.Text := s;
    Daten.qSuch.Open;
    slEintragList := TSignalLogEintragListe.Create;

    while not Daten.qSuch.Eof do
    begin
      slEintrag := TSignalLogEintrag.Create;
      slEintrag.Start := Daten.qSuch.FieldByName('startdatumzeit').AsFloat;
      if slEintrag.Start < schichtstart then
        slEintrag.Start := schichtstart;
      slEintrag.Stop := Daten.qSuch.FieldByName('enddatumzeit').AsFloat;
      if slEintrag.Stop < 1 then
        slEintrag.Stop := schichtende;
      if slEintrag.Stop > schichtende then
        slEintrag.Stop := schichtende;
      slEintrag.wert := Daten.qSuch.FieldByName('wert').AsInteger;
      slEintrag.maschnr := Daten.qSuch.FieldByName('maschnr').AsInteger;
      slEintragList.Add(slEintrag);
      Daten.qSuch.Next;
    end;

    for i:= 1 to Anzahl_Masch do
    begin
      if Includis[I].IstArchiviert then
        Continue;
      slMList := slEintragList.GetByMaschNr(i);
      stillMList := stillListe.GetByMaschNr(i);
      if (slMList <> nil) and (stillMList <> nil) then
      begin
        ges := 0;
        lauf := 0;
        for m2 := 0 to stillMList.Count-1 do
        begin
          ges := DateOverlap(schichtstart, schichtende, stillMList.Items[m2].Kommt, stillMList.Items[m2].geht );
          for m1 := 0 to slMList.Count-1 do
            lauf := lauf + DateOverlap(slMList.Items[m1].Start, slMList.Items[m1].Stop, stillMList.Items[m2].Kommt, stillMList.Items[m2].geht );
        end;

        down := ges -lauf;

        s := ' UPDATE tpm_schicht SET r2_plcruntime = ' + IntToStr(round(lauf))+ ', r2_plcdown = '
          + IntToStr(round(down)) + ', r2_plcparts = ' + IntToStr(Includis[I].Auftrag.Anfahrausschuss)
          + ' WHERE nr = (SELECT max(nr) FROM tpm_schicht WHERE maschnr = '
          + IntToStr(i) + ')';
        SQL_Insert(Daten.qUpdate,s);
      end;
      try
        if slMList <> nil then
          slMList.Free;
      except
      end;
      try
        if stillMList <> nil then
          stillMList.Free;
      except
      end;
    end;
    slEintragList.Destroy;
  end;
  stillListe.Destroy;
end;

procedure CCC_AutoSetup2;
var interval, mnri, grundnr, nr, i, aktstat : Integer;
  mnr : string;
  s : string;

begin
  // Automatisch nach n Minuten von Rüsten 1 in Rüsten 2 umschalten
  interval := TCO_Setup.GetParamInt(Daten.qSuch, 'INCL_AutoSetup2Time');

  // Nachsehen welche Aufträge / Maschine in Rüsten 1 stehen (Rüstgrund Nr 8)
  s := 'SELECT nr, rueststart, lizenz, arbeitsfrei, grund FROM ruestprot WHERE ruestende = 0';
  Daten.qSuch.SQL.Text := s;
  Daten.qSuch.Open;
  while not Daten.qSuch.Eof do
  begin
    mnr := CCC_GetMaschNrLizenz(Daten.qSuch.FieldByName('lizenz').AsString);
    try
      mnri := StrToInt(mnr);
    except
    end;
    if mnri > 0 then
    begin
      grundnr := Daten.qSuch.FieldByName('grund').AsInteger;
      // Prüfen ob Maschine läuft und länger mit Rüstgrund
      Includis[mnri].Ruestgrund := grundnr;
      if (Includis[mnri].MaschineLaeuft) and (grundnr = 8)  then
      begin
        if ((Jetzt - Includis[mnri].LetzterMaschinenStart) * 1440) > interval then
        begin
//        Rüstgrund ändern
          s := 'UPDATE RuestProt SET RuestEnde = ' + FloatToPunktString(Jetzt)
            + ' WHERE nr = ' + Daten.qSuch.FieldByName('nr').AsString;
          SQL_Insert(Daten.qUpdate, s);

          s := 'Insert into RuestProt'
            + ' (Nr, grund, BetriebsAuftragNr, Name , PersonalNr, RuestStart, RuestSoll, Lizenz, Werkzeug) '
            + ' (SELECT RuestProtId.NextVal, 9, Betriebsauftragnr, name, personalnr, ' + FloatToPunktString(Jetzt)
            + ', RuestSoll, Lizenz, Werkzeug FROM ruestprot WHERE nr = ' + daten.qSuch.FieldByName('nr').AsString
            + ')';
          SQL_Insert(Daten.qUpdate, s);

          s := 'SELECT max(nr) mnr  FROM tpm_stillog WHERE maschnr=' + mnr + ' AND geht = 0';
          SQL_Get(Daten.qSuch2, s);

          if not Daten.qSuch2.IsEmpty then
          begin
            if Daten.qSuch2.FieldByName('mnr').AsString <> '' then
            begin
              s := 'UPDATE tpm_stillog SET geht = ' + FloatToPunktString(Jetzt)
                + ' WHERE nr = ' + Daten.qSuch2.FieldByName('mnr').AsString;
              SQL_Insert(Daten.qUpdate, s);

              s := 'Insert into tpm_stillog'
                + ' (Nr, stillstandnr, maschnr, kommt, geht, erstellungsdatum) '
                + ' (SELECT tpm_stillogId.NextVal, 9, maschnr, ' + FloatToPunktString(Jetzt)
                + ', 0, '+FloatToPunktString(Jetzt) +' FROM tpm_stillog WHERE nr = '
                + daten.qSuch2.FieldByName('mnr').AsString + ')';
              SQL_Insert(Daten.qUpdate, s);
            end;
          end;
        end;
      end;
    end;
    Daten.qSuch.Next;
  end;

  (*
  // Nachsehen ob sich Zustände außerhalb des Dienstes verändert haben
  // Ruestzustand vorher und aktuell vergleichen
  // Es muss ein Auftrag auf der Maschine sein, also alle Aufträge mit Status 0 und 1
  s := 'SELECT betriebsauftragnr, maschine.lizenz, maschid, stat FROM maschine '
    + ' LEFT OUTER JOIN pde ON maschine.lizenz = pde.lizenz '
    + ' WHERE pde.stat IN (0,1) OR pde.stat IS NULL '
    + ' ORDER BY maschid';
  Daten.qSuch.SQL.Text := s;
  Daten.qSuch.Open;
  while not Daten.qSuch.Eof do
  begin
    mnri := Daten.qSuch.FieldByName('maschid').AsInteger;
    // Nachsehen in Rüstprotokoll nach offenem Eintrag (Rüsten 1 oder 2)
    if Daten.qSuch.FieldByName('stat').IsNull then
      aktstat := 0 // Kein Auftrag auf Maschine
    else
      if Daten.qSuch.FieldByName('stat').AsInteger = 0 then
       aktstat := 3 // Auftrag läuft auf Maschine
      else
      begin
        if Includis[mnri].Ruestgrund = 8 then
          aktstat := 1;
        if Includis[mnri].Ruestgrund = 9 then
          aktstat := 2;
      end;
    if aktstat <> Includis[mnri].RuestZustand then
    begin
      Includis[mnri].TmpLaufzeitInZustand := 0;
      Includis[mnri].TmpStillstandInZustand := 0;
      Includis[mnri].TmpLaufzeitInZustandSchicht := 0;
      Includis[mnri].TmpStillstandInZustandSchicht := 0;
    end;

    if (aktstat = 1) or (aktstat = 2) then
    begin
      s := 'UPDATE ruestprot SET runtime = ' + IntToStr(round(Includis[mnri].TmpLaufzeitInZustand))
        + ', downtime =' + IntToStr(round(Includis[mnri].TmpStillstandInZustand))
        + ' WHERE maschnr = ' + IntToStr(mnri) + ' AND geht = 0';
      SQL_Insert(Daten.qUpdate,s);
    end;

    if aktstat = 2 then
    begin
      s := ' UPDATE tpm_schicht set r2_plcruntime = '
        + IntToStr(round(Includis[mnri].TmpLaufzeitInZustandSchicht))+ ', r2_plcdowntime = ' +
        IntToStr(round(Includis[mnri].TmpStillstandInZustandSchicht))
        + ' WHERE nr = (SELECT max(nr) FROM tpm_schicht WHERE maschnr = '
        + IntToStr(mnri) + ')';
      SQL_Insert(Daten.qUpdate,s);
    end;


    Daten.qSuch.Next;
  end;
    *)
    CCC_Calc_R2_Times;
end;

procedure CCC_CheckUnterbrocheneAuftraege;
var
  S: string;
  I, Nr, Nr2: Integer;
begin
  if TCO_Setup.GetParamInt(Daten.qUpdate, 'INCL_CheckUnterbrocheneAuftraege') = 1 then
  begin
    S := 'select Max(Nr) CNT from Log_Signal_Schreiben';
    SQL_Get(Daten.qSuch, S);
    S := 'update Setup_Par set Wert = ' + Daten.qSuch.FieldByName('CNT').AsString
      + ' where Schluessel = ''INCL_CheckUnterbrocheneAuftraege''';
    SQL_Insert(Daten.qUpdate, S);
  end;

  Nr := TCO_Setup.GetParamInt(Daten.qUpdate, 'INCL_CheckUnterbrocheneAuftraege');
  Nr2 := 0;

  S := 'select Log_Signal_Schreiben.Nr, Log_Signal_Schreiben.MaschNr, Log_Signal_Schreiben.SignalNr,'
    + ' Log_Signal_Schreiben.Wert'
    + ' from Log_Signal_Schreiben, Signale'
    + ' where Log_Signal_Schreiben.Nr > ' + IntToStr(Nr)
    + ' and Log_Signal_Schreiben.SignalNr = Signale.SignalNr'
    + ' and Signale.SignalArt in (1, 21)'
    + ' order by Log_Signal_Schreiben.Nr';
  SQL_Get(Daten.qDurchlauf, S);
  while not Daten.qDurchlauf.EOF do
  begin
    Nr2 := Daten.qDurchlauf.FieldByName('Nr').AsInteger;
    for I := 1 to 3 do
    begin
      S := 'INSERT INTO SIGNAL_SCHREIBEN (Nr, MaschNr, SignalNr, Wert)'
        + ' VALUES (SIGNAL_SCHREIBENID.NextVal,'
        + ' ' + Daten.qDurchlauf.FieldByName('MaschNr').AsString + ','
        + ' ' + Daten.qDurchlauf.FieldByName('SignalNr').AsString + ','
        + ' ' + Daten.qDurchlauf.FieldByName('Wert').AsString + ')';
      SQL_Insert(Daten.qUpdate, S);
    end;
    Daten.qDurchlauf.Next;
  end;

  if Nr2 > 0 then
  begin
    S := 'update Setup_Par set Wert = ' + IntToStr(Nr2)
      + ' where Schluessel = ''INCL_CheckUnterbrocheneAuftraege''';
    SQL_Insert(Daten.qUpdate, S);
  end;
end;

function TTT_GetMaschine(MaschNr: Integer): string;
var
  I: Integer;
  R: string;
begin
  //RS 15.06.2016: Wir können doch erst einmal prüfen, ob wir nicht direkt das Element nehmen können
  try
    I := MaschNr;
  except
    I := 0;
  end;
  if (I < Length(Maschine) ) AND (Maschine[I].MaschNr  = MaschNr) then
  begin
    Result := Maschine[I].Lizenz;
    Exit;
  end;

  I := 0;
  R := 'error';
  while (I < Length(Maschine)) and (R = 'error') do
  begin
    if Maschine[I].MaschNr = MaschNr then
      R := Maschine[I].Lizenz;
    Inc(I);
  end;
  Result := R;
end;

function TTT_GetMaschNr(Lizenz: string): Integer;
var
  R, I: Integer;
begin
  I := 0;
  R := 0;
  while (I < Length(Maschine)) and (R = 0) do
  begin
    if Maschine[I].Lizenz = Lizenz then
      R := Maschine[I].MaschNr;
    Inc(I);
  end;
  Result := R;
end;

function GetDBNr(SignalNr: Integer; MaschNr: Integer): Integer;
var
  R, I: Integer;
begin
  I := 0;
  R := -1;
  if SignalNr = -1 then
  begin
	Result := -1;
	exit;
  end;
  while (I < Length(MSignal)) and (R = -1) do
  begin
    if (MSignal[I].SignalNr = SignalNr) and (MSignal[I].MaschNr = MaschNr) then
      R := MSignal[I].Nr;
    Inc(I);
  end;
  Result := R;
end;

function TTT_GetSignalNr(SignalArt: Integer): Integer;
var
  R, I: Integer;
begin
  I := 0;
  R := -1;
  while (I < Length(Signal)) and (R = -1) do
  begin
    if Signal[I].SignalArt = SignalArt then
      R := Signal[I].SignalNr;
    Inc(I);
  end;
  Result := R;
end;

procedure LoadSignals(Q: TCO_Query);
var
  S, S1: string;
  I, Anz: Integer;
begin
  // Maschine laden.
  S := 'select Count(*) CNT from Maschine';
  SQL_Get(Q, S);
  Anz := Q.FieldByName('CNT').AsInteger;
  SetLength(Maschine, Anz);

  S := 'select * from Maschine';
  SQL_Get(Q, S);
  for I := 0 to Anz - 1 do
  begin
    Maschine[I].MaschNr := Q.FieldByName('MaschNr').AsInteger;
    Maschine[I].Lizenz := Q.FieldByName('Lizenz').AsString;
    Q.Next;
  end;

  // Signale laden
  S := 'select Count(*) CNT from Signale';
  SQL_Get(Q, S);
  Anz := Q.FieldByName('CNT').AsInteger;
  SetLength(Signal, Anz);

  S := 'select * from Signale';
  SQL_Get(Q, S);
  for I := 0 to Anz - 1 do
  begin
    Signal[I].SignalNr := Q.FieldByName('SignalNr').AsInteger;
    Signal[I].SignalArt := Q.FieldByName('SignalArt').AsInteger;
    Q.Next;
  end;

  // Signal_Maschine laden
  S1 := ' from Signal_Maschine, Maschine where Signal_Maschine.MaschNr = Maschine.MaschNr and Maschine.manuelle_buchung <> 1';
  S := 'select Count(*) CNT' + S1;
  SQL_Get(Q, S);
  Anz := Q.FieldByName('CNT').AsInteger;
  SetLength(MSignal, Anz);

  S := 'select Signal_Maschine.*' + S1;
  SQL_Get(Q, S);
  for I := 0 to Anz - 1 do
  begin
    MSignal[I].Nr := Q.FieldByName('Nr').AsInteger;
    MSignal[I].MaschNr := Q.FieldByName('MaschNr').AsInteger;
    MSignal[I].SignalNr := Q.FieldByName('SignalNr').AsInteger;
    Q.Next;
  end;
end;

function GetAktion(Stillstandnr: Integer): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to Length(Stillstand) do
    if Stillstand[I].Stillstandnr = Stillstandnr then
      Result := Stillstand[I].Aktion
end;

function GetSignalStillstand(Datenblock: Integer): Integer;
var
  I: Integer;
begin
  Result := -1;
  if IndivStillstand[Datenblock].Istwert = nil then
    Exit;
  for I := 0 to Length(IndivStillstand[Datenblock].Istwert) - 1 do
    if (GetAktion(IndivStillstand[Datenblock].Stillstand[I]) = saStoerung) and IndivStillstand[Datenblock].Istwert[I] then
      Result := IndivStillstand[Datenblock].Stillstand[I];
end;

function GetKWStr(Datum: TDateTime): string;
var
  KW, KWJahr: Word;
begin
  DateToKw(Datum, KW, KWJahr);
  Result := IntToStr(KW) + ' / ' + IntToStr(KWJahr);
end;

function GetKW(Datum: TDateTime): string;
var
  KW, KWJahr: Word;
begin
  DateToKw(Datum, KW, KWJahr);
  Result := IntToStr(KW);
end;

function TTT_GetMonatStr(Datum: TDateTime): string;
var
  Tag, Monat, Jahr: Word;
begin
  DecodeDate(Datum, Jahr, Monat, Tag);
  Result := LongMonthNames[Monat] + ' ' + IntToStr(Jahr);
end;

function GetMonat(Datum: TDateTime): string;
var
  Tag, Monat, Jahr: Word;
begin
  DecodeDate(Datum, Jahr, Monat, Tag);
  Result := IntToStr(Monat);
end;

function GetJahr(Datum: TDateTime): string;
var
  Tag, Monat, Jahr: Word;
begin
  DecodeDate(Datum, Jahr, Monat, Tag);
  Result := IntToStr(Jahr);
end;

function GetQuartal(Datum: TDateTime): string;
var
  Tag, Monat, Jahr: Word;
  Quartal: Word;
begin
  DecodeDate(Datum, Jahr, Monat, Tag);
  case Monat of
    1: Quartal := 1;
    2: Quartal := 1;
    3: Quartal := 1;
    4: Quartal := 2;
    5: Quartal := 2;
    6: Quartal := 2;
    7: Quartal := 3;
    8: Quartal := 3;
    9: Quartal := 3;
    10: Quartal := 4;
    11: Quartal := 4;
    12: Quartal := 4;
  else
    Quartal := 0;
  end;
  Result := IntToStr(Quartal);
end;

procedure TTT_ErstelldatumEinfuegen(qUpdate, qSuch3: TCO_Query; Aufruf: Integer);
var
  zustand_maschinf, zustand_sigmasch, MNr, dtnr, emsg: string;
begin
  try
    SQL_Get(qUpdate, 'SELECT maschnr, nr FROM tpm_stillog WHERE nr = (SELECT MAX(nr) FROM TPM_STILLOG)');
    MNr := qUpdate.FieldByName('maschnr').AsString;
    dtnr := qUpdate.FieldByName('nr').AsString;

    SQL_Insert(qUpdate, 'UPDATE TPM_Stillog SET Erstellungsdatum = ' + FloatToPunktString(N_o_w)
      + ' WHERE Nr = ' + dtnr);


    SQL_Get(qUpdate, 'SELECT zustandint FROM maschinf WHERE maschnr = ' + MNr);
    zustand_maschinf := qUpdate.FieldByName('zustandint').AsString;

    SQL_Get(qUpdate, 'SELECT istwert FROM signal_maschine WHERE signalnr = '
      + IntToStr(TTT_GetSignalNr(CMASCHPROGRAMMBETRIEB)) + ' AND maschnr = ' + MNr);
    zustand_sigmasch := qUpdate.FieldByName('istwert').AsString;

    emsg := '';
    if (zustand_maschinf = '0') then
      emsg := '*';
    if (zustand_sigmasch = '1') then
      emsg := '#';

    SchreibeMeldung(emsg + IntToStr(Aufruf) + ': MNo:' + MNr + ' DTNo:' + dtnr
      + ' Sig:' + zustand_sigmasch + ' Maschinf:' + zustand_maschinf + emsg, 6);

  except
  end;
end;

function TTT_GetRuestStillstandUeberschreitung(aqUpdate, aqSuch: TCO_Query; aMaschNr: Integer; aLizenz: string):
  Integer;
var
  S, BANr: string;
  RuestSoll: Integer;
begin
  Result := 2;

  // Wenn Rüsten ungeplant, dann Funktion nicht durchlaufen
  if not RuestenIstGeplant then
    Exit;

  // Nachsehen welcher Auftrag aktuell auf der Maschine gerüstet wird
  S := 'SELECT betriebsauftragnr, ruestzeit FROM pde WHERE lizenz = '''
    + aLizenz + ''' AND stat in (0,1)';
  aqSuch.SQL.Text := S;
  aqSuch.Open;
  if aqSuch.IsEmpty then
    Exit;
  RuestSoll := aqSuch.FieldByName('ruestzeit').AsInteger;
  BANr := aqSuch.FieldByName('betriebsauftragnr').AsString;
  aqSuch.Close;
  // Nachsehen welcher Status Rüsten derzeit anliegt
  S := 'SELECT stillstandnr FROM tpm_stillog WHERE maschnr = ' + IntToStr(aMaschNr)
    + ' AND geht = 0 ORDER BY kommt DESC';
  aqSuch.SQL.Text := S;
  aqSuch.Open;
  if aqSuch.IsEmpty then
    Exit;

  // wenn aktuell Rüsten ungeplant anliegt exit
  if aqSuch.FieldByName('stillstandnr').AsInteger = RuestStillstandNrUngeplant then
  begin
    Result := RuestStillstandNrUngeplant;
    Exit;
  end;

  aqSuch.Close;
  // wenn Rüsten geplant anliegt, dann auf Rüstzeitüberschreitung testen
  S := 'SELECT SUM((CASE WHEN geht = 0 THEN ' + FloatToPunktString(N_o_w)
    + ' ELSE geht END - kommt) * 1440) ist FROM tpm_stillog WHERE '
    + ' stillstandnr = 2 AND betriebsauftragnr = ''' + BANr + '''';
  aqSuch.SQL.Text := S;
  aqSuch.Open;
  if RuestSoll <= aqSuch.FieldByName('ist').AsInteger then
    Result := RuestStillstandNrUngeplant;
  aqSuch.Close;

end;

/// Funktion zur Berechnung des Verpackt Protokolls auf ThZusatz und bei, bzw. kurz vor Schictwechsel
procedure VerpacktProtAusAusschussRechnen(aQSuch, aQSuch2, aQUpdate : TCO_Query; aDBUser : string);overload;
var
  Ini: TIniFile;
  lastrun: TDateTime;

begin
  Ini := TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'incl_' + aDBUser + '.ini');
  lastrun := Ini.ReadDateTime('Addons', 'LastRun', 0);
  Ini.WriteDateTime('Addons', 'LastRun', N_o_w);
  Ini.Free;

  lastrun := lastrun - GetSchichtDauerDatum(lastrun) / 1440;
  VerpacktProtAusAusschussRechnen(aQSuch, aQSuch2, aQUpdate, aDBUser, lastrun);
end;

procedure VerpacktProtAusAusschussRechnen(aQSuch, aQSuch2, aQUpdate : TCO_Query; aDBUser : string; fromDate : TDateTime);overload;
var
  S, banr: string;
  Ini: TIniFile;
  lastrun, dat: TDateTime;
  gutschicht, verpackt, buchmenge, gutall: Integer;
  buchen : Boolean;

begin
  if VerpacktAusAusschussAktiv  then
    exit;

  VerpacktAusAusschussAktiv := true;
  try
   (* Ini := TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'incl_' + aDBUser + '.ini');
    lastrun := Ini.ReadDateTime('Addons', 'LastRun', 0);
    Ini.WriteDateTime('Addons', 'LastRun', N_o_w);
    Ini.Free;

    lastrun := lastrun - GetSchichtDauerDatum(lastrun) / 1440;
    *)
    lastrun:=fromDate;

    s:='(SELECT betriebsauftragnr, max(auftragnr) auftragnr,'
      + ' max(bezeichnung) bezeichnung, max(lizenz) lizenz, datumzeit dat FROM tpm_schicht'
      + ' INNER JOIN maschine ON tpm_schicht.maschnr = maschine.maschnr'
      + ' WHERE datumzeit > ' + FloatToPunktString(lastrun)
      + ' AND betriebsauftragnr IS NOT NULL'
      + ' GROUP BY betriebsauftragnr, datumzeit )'
      + ' UNION '
      + '(SELECT pdekombi.betriebsauftragnr, max(pdekombi.auftragnr) auftragnr,'
      + ' max(pdekombi.bezeichnung) bezeichnung, max(lizenz) lizenz, datumzeit dat FROM tpm_schicht'
      + ' INNER JOIN maschine ON tpm_schicht.maschnr = maschine.maschnr'
      + ' INNER JOIN pdekombi ON tpm_schicht.betriebsauftragnr = pdekombi.masterbetriebsauftragnr '
      + ' WHERE datumzeit > ' + FloatToPunktString(lastrun)
      + ' AND pdekombi.betriebsauftragnr IS NOT NULL'
      + ' GROUP BY pdekombi.betriebsauftragnr, datumzeit )'
      + ' ORDER BY dat';
    aqSuch.SQL.Text := s;

    aqSuch.Open;

    while not aqSuch.EOF do
    begin
      banr :=  aqSuch.FieldByName('betriebsauftragnr').AsString;
        s := 'SELECT sum(produziert)-sum(autoausschuss)-sum(ausschuss) gutschicht,'
          + ' (SELECT sum(zugang-abgang) FROM verpacktprot WHERE betriebsauftragnr = ''' + banr + ''' ) verpackt,'
          + ' (SELECT sum(produziert)-sum(autoausschuss)-sum(ausschuss) FROM tpm_schicht'
          + ' WHERE betriebsauftragnr = ''' + banr + ''') gutall,'
          + ' max(datumzeit) dat FROM tpm_schicht'
          + ' WHERE tpm_schicht.betriebsauftragnr = ''' + aqSuch.FieldByName('betriebsauftragnr').AsString + ''''
          + ' AND datumzeit < ' + FloatToPunktString(aqSuch.FieldByName('dat').AsFloat + (4 / 1440))
          + ' AND datumzeit > ' + FloatToPunktString(aqSuch.FieldByName('dat').AsFloat - (3 / 1440))
          + ' GROUP BY tpm_schicht.betriebsauftragnr';
        aqSuch2.SQL.Text := s;
        aqSuch2.Open;
        buchen := False;
        if not aqSuch2.IsEmpty then
        begin
          gutschicht := aqSuch2.FieldByName('gutschicht').AsInteger;
          gutall := aqSuch2.FieldByName('gutall').AsInteger;
          verpackt := aqSuch2.FieldByName('verpackt').AsInteger;
          dat :=  aqSuch2.FieldByName('dat').AsFloat;
          buchmenge := 0;
          buchen := True;
        end
        else
        begin   // Wenn nicht gefunden, dann in TPM_SCHICHTKOMBI suchen. Tabelle wird von INCLCoreSVC gefüllt
          s := 'SELECT sum(produziert)-sum(autoausschuss)-sum(ausschuss) gutschicht,'
            + ' (SELECT sum(zugang-abgang) FROM verpacktprot WHERE betriebsauftragnr = ''' + banr + ''' ) verpackt,'
            + ' (SELECT sum(produziert)-sum(autoausschuss)-sum(ausschuss) FROM tpm_schichtkombi'
            + ' WHERE betriebsauftragnr = ''' + banr + ''') gutall,'
            + ' max(datumzeit) dat FROM tpm_schichtkombi'
            + ' WHERE tpm_schichtkombi.betriebsauftragnr = ''' + banr + ''''
            + ' AND datumzeit < ' + FloatToPunktString(aqSuch.FieldByName('dat').AsFloat + (4 / 1440))
            + ' AND datumzeit > ' + FloatToPunktString(aqSuch.FieldByName('dat').AsFloat - (3 / 1440))
            + ' GROUP BY tpm_schichtkombi.betriebsauftragnr';
          aqSuch2.SQL.Text := s;
          try
            aqSuch2.Open;
            if not aqSuch2.IsEmpty then
            begin
              gutschicht := aqSuch2.FieldByName('gutschicht').AsInteger;
              gutall := aqSuch2.FieldByName('gutall').AsInteger;
              verpackt := aqSuch2.FieldByName('verpackt').AsInteger;
              dat :=  aqSuch2.FieldByName('dat').AsFloat;
              buchmenge := 0;
              buchen := True;
            end
            else
              buchen := False;
          except
            buchen := False;
          end;
        end;

        if buchen then
        begin
          if gutall <> verpackt then
          begin
            buchmenge := gutall - verpackt;

            //if buchmenge > gutschicht then
            //  buchmenge := gutschicht;

            aQSuch2.SQL.Text := 'SELECT SUM(zugang-abgang) sumpack FROM verpacktprot WHERE datum > '
              + FloatToPunktString(aqSuch.FieldByName('dat').AsFloat) +' AND betriebsauftragnr = '''
              + banr + '''';
            aQSuch2.Open;

            buchmenge := buchmenge + aQSuch2.FieldByName('sumpack').AsInteger;

            if buchmenge > gutschicht then
              buchmenge := gutschicht;

          end;

          if buchmenge <> 0 then
          begin

            aQUpdate.SQL.Text := 'DELETE FROM verpacktprot WHERE datum > '
              + FloatToPunktString(aqSuch.FieldByName('dat').AsFloat) +' AND betriebsauftragnr = '''
              + banr + '''';
            aQUpdate.ExecSQL;

            S := 'INSERT INTO verpacktprot (nr, betriebsauftragnr, auftragnr, bezeichnung, barcode,'
              + ' zugang, abgang, bclesernr, datum, eintragsdatum, lastchange, hostname, userid,'
              + ' maschine) VALUES  (verpacktprotid.nextval, '''
              + banr + ''', '''
              + aqSuch.FieldByName('auftragnr').AsString + ''', '''
              + aqSuch.FieldByName('bezeichnung').AsString + ''', '''
              + 'service'', '
              + IntToStr(MAX(buchmenge, 0)) + ', '
              + IntToStr(ABS(Min(buchmenge, 0))) + ', 0, '
              + FloatToPunktString(dat + 1 / 1440) + ', '
              + FloatToPunktString(dat + 1 / 1440) + ', '
              + FloatToPunktString(Now)  + ','
              + '''' + ServerNameDesDienstes + ''','
              + '''-2'','
              + '''' + aqSuch.FieldByName('lizenz').AsString + ''')';
            aqUpdate.SQL.Text := S;
           aqUpdate.ExecSQL;

           S := 'update TPM_Schicht set Verpackt = CASE WHEN (Produziert - Ausschuss - AutoAusschuss) < 0 '
              + ' THEN 0 ELSE Produziert - Ausschuss - AutoAusschuss END '
              + ' where BetriebsAuftragNr = ''' + banr + '''';
            aqUpdate.SQL.Text := S;
            aqUpdate.ExecSQL;
            S := 'update TPM_Schicht set Verpackt_ORG = verpackt'
              + ' where BetriebsAuftragNr = ''' + banr + '''';
            aqUpdate.SQL.Text := S;
            aqUpdate.ExecSQL;
            S := 'update TPM_Schichtkombi set Verpackt = CASE WHEN (Produziert - Ausschuss - AutoAusschuss) < 0 '
              + ' THEN 0 ELSE Produziert - Ausschuss - AutoAusschuss END '
              + ' where BetriebsAuftragNr = ''' + banr + '''';
            aqUpdate.SQL.Text := S;
            aqUpdate.ExecSQL;
            S := 'update TPM_Schichtkombi set Verpackt_ORG = verpackt'
              + ' where BetriebsAuftragNr = ''' + banr + '''';
            aqUpdate.SQL.Text := S;
            aqUpdate.ExecSQL;
          end;
        end;

      aqSuch2.SQL.Text := 'SELECT sum(zugang-abgang) pack FROM verpacktprot WHERE betriebsauftragnr = '''
        + aqSuch.FieldByName('betriebsauftragnr').AsString + '''';
      aqSuch2.Open;
      if aQSuch2.FieldByName('pack').AsInteger > 0 then
      begin
        SQL_Insert(aQUpdate, 'UPDATE aarchiv SET Verpacktint = ' + aQSuch2.FieldByName('pack').AsString
        + ' WHERE betriebsauftragnr = ''' + aqSuch.FieldByName('betriebsauftragnr').AsString +'''');
        SQL_Insert(aQUpdate, 'UPDATE pde SET pack = ' + aQSuch2.FieldByName('pack').AsString
        + ' WHERE betriebsauftragnr = ''' + aqSuch.FieldByName('betriebsauftragnr').AsString +'''');
        SQL_Insert(aQUpdate, 'UPDATE maschinf SET pack = ' + aQSuch2.FieldByName('pack').AsString
        + ' WHERE betriebsauftragnr = ''' + aqSuch.FieldByName('betriebsauftragnr').AsString +'''');
      end;
      aqSuch2.Close;

      aqSuch.Next;
    end;
    aqSuch.Close;

    S := 'UPDATE TPM_Schichtkombi SET verpackt = 0 WHERE verpackt < 0';
    aqUpdate.SQL.Text := S;
    aqUpdate.ExecSQL;

    S := 'UPDATE TPM_Schichtkombi SET verpackt_org = 0 WHERE verpackt_org < 0';
    aqUpdate.SQL.Text := S;
    aqUpdate.ExecSQL;

    S := 'UPDATE TPM_Schicht SET verpackt = 0 WHERE verpackt < 0';
    aqUpdate.SQL.Text := S;
    aqUpdate.ExecSQL;

    S := 'UPDATE TPM_Schicht SET verpackt_org = 0 WHERE verpackt_org < 0';
    aqUpdate.SQL.Text := S;
    aqUpdate.ExecSQL;
  except on ex:Exception do
    SchreibeMeldung(ex.Message, 1);
  end;
  VerpacktAusAusschussAktiv := false;
end;

function Format_String(Wert: string): Integer;
var
  X, Y: array[0..100] of Char;
  I: Integer;
  Nummer: string;
  neg: Boolean;
begin
  Result := 0;
  neg := False;
  if (Wert = '') then
  begin
    Result := 0;
    Exit;
  end;

  I := 0;
  StrPCopy(X, Wert);
  while I < 99 do
  begin
    if (X[I] = #45) then
    begin
      neg := True;
      X[I] := '0';
    end;
    if not (X[I] in [#48..#57]) then
      break;
    Y[I] := X[I];
    Inc(I);
  end;
  Y[I] := #0;
  Nummer := StrPas(Y);
  if not (Nummer = '') then
  begin
    Result := StrToInt(Nummer);
    if neg then
      Result := Result * (-1);
  end;
end;

procedure Pause(Sek: Integer);
begin
  Sleep(Sek * 1000);
end;

function GetSelectedMaschinen(Q: TCO_Query; AndStr, Feld, Liste: string; Style: Integer): string;
var
  S, S1, T: string;
  I, A, B: Integer;
begin
  while (length(Liste)>0) and (Liste[1] = ' ') do
    Delete(Liste,1,1);

  if (Liste = '') then
  begin
    Result := '';
    Exit;
  end;

  T := ' ' + Liste + ' ';
  while Pos('  ', T) > 0 do
    System.Delete(T, Pos('  ', T), 1);

  S := ' ';
  S1 := '';
  for I := 1 to 1000 do
  begin
    A := Pos(' ' + IntToStr(I) + ' ', T);
    B := Pos(' ' + IntToStr(I) + ' ', S);
    if (A > 0) and (B = 0) then
    begin
      S := S + IntToStr(I) + ' ';
      if Style = 0 then
        S1 := S1 + IntToStr(I) + ','
      else
        if SQLGetBool(Q, 'Maschine', 'MaschNr', IntToStr(I)) then
          S1 := S1 + '''' + Q.FieldByName('Lizenz').AsString + ''',';
    end;
  end;

  if Length(S1) > 0 then
    System.Delete(S1, Length(S1), 1);

  Result := ' ' + AndStr + ' ' + Feld + ' in (' + S1 + ') ';
end;

procedure Statistik_Berechnen;
begin
  if not Thread_Schicht.Berechnung_aktiv then
  begin
    Thread_Schicht.Recalculate_Mode := True;
    PulseEvent(Event_Schicht);
  end;
end;

procedure CCC_Proc_Ruesten_AutoBuchen;
var
  SQLStr: string;
begin
  SQLStr := 'select * from TPM_Stillog, Maschinf where TPM_Stillog.MaschNr = Maschinf.MaschNr'
    + ' and Geht = 0 and TPM_Stillog.StillstandNr = 1 and Maschinf.BetriebsAuftragNr is null';
  SQL_Get(Daten.qSuch, SQLStr);
  while not Daten.qSuch.EOF do
  begin
    SQLStr := 'select * from TPM_Stillog where MaschNr = ' + Daten.qSuch.FieldByName('MaschNr').AsString
      + ' order by Kommt Desc';
    SQL_Get(Daten.qSuch2, SQLStr);
    Daten.qSuch2.Next;
    if Daten.qSuch2.FieldByName('StillstandNr').AsInteger = 2 then
      ChangeDtCode(Daten.qUpdate, 2,Daten.qSuch.FieldByName('Nr').AsInteger, true, 'PRAB9237' ); // ??? Das habe ich nicht verstanden. Sascha. 05.11.2007
    Daten.qSuch.Next;
  end;
end;

function CheckCO_DatabaseConnect(C: TCO_Database; Q: TCO_Query; LogId: Integer; thread:string): Boolean;
begin
  Result := True;
  try
    C.Connected := True;
    Q.SQL.Text := 'select Nr from Setup';
    Q.Open;
    Q.Close;
  except
    try
      SchreibeMeldung('['+thread+']:Connection failed. Reconnecting...', LogId);
      C.Connected := False;
      C.Connected := True;
      SchreibeMeldung('['+thread+']:Reconnected.', LogId);
    except on e: Exception do
      begin
        Result := False;
        if Pos(UpperCase('CoInitialize'), UpperCase(e.Message))>0 then
        begin
          CoInitialize(nil);
          SchreibeMeldung('CoInitialize called', LogId);
        end
        else
          SchreibeMeldung('No connect (Ex:'+e.Message+')', LogId);
        Exit;
      end;
    end;
    SchreibeMeldung('Connect ok', LogId);
  end;
end;

procedure GetPersonalNr_Signal;
var
  PName, Nr, Liz, S: string;
  MaschNr, Wert, Wert2: Integer;
  Closed: Boolean;
begin
  S := 'select * from Signal_Maschine where SignalNr = ' + IntToStr(TTT_GetSignalNr(CPERSONALNR))
    + ' order by MaschNr';
  SQL_Get(Daten.qSuch, S);
  while not Daten.qSuch.EOF do
  begin
    Wert := Daten.qSuch.FieldByName('Istwert').AsInteger;
    MaschNr := Daten.qSuch.FieldByName('MaschNr').AsInteger;
    if (Wert = 0) or (SQLGetBool(Daten.qSuch2, 'ZUSTAENDIG', 'PersonalNr', IntToStr(Wert))) then
    begin
      if Wert > 0 then
        PName := Daten.qSuch2.FieldByName('Bezeichnung').AsString;

      Liz := TTT_GetMaschine(MaschNr);
      S := 'select * from PersonalMaschine where Maschine = ''' + Liz + ''' order by Kommt desc';
      SQL_Get(Daten.qSuch2, S);
      if not Daten.qSuch2.IsEmpty then
        Wert2 := Daten.qSuch2.FieldByName('PersonalNr').AsInteger
      else
        Wert2 := 0;

      Closed := Daten.qSuch2.IsEmpty or (Daten.qSuch2.FieldByName('Geht').AsFloat > 0);
      if not Closed then
      begin
        Nr := Daten.qSuch2.FieldByName('Nr').AsString;
        if (Wert = 0) or (Wert > 0) and (Wert2 > 0) and (Wert <> Wert2) then
        begin
          S := 'update PersonalMaschine set Geht = ''' + FloatToStr2(N_o_w) + ''' where Nr = ' + Nr;
          SQL_Insert(Daten.qUpdate, S);
          S := 'update PersonalMaschine set Dauer = Round((Geht-Kommt)*1440) where Nr = ' + Nr;
          SQL_Insert(Daten.qUpdate, S);
          S := 'update PZE_Werkstatt set Geht = ''' + FloatToStr2(N_o_w) + ''' where Geht = 0 and MaschNr = ' +
            IntToStr(MaschNr);
          SQL_Insert(Daten.qUpdate, S);
          Closed := True;
        end;
      end;

      if Closed and (Wert > 0) then
      begin
        S := 'insert into PersonalMaschine (Nr, PersonalNr, PersonalName, Maschine, Kommt, Geht, Dauer)'
          + ' values (PersonalMaschineId.NextVal,'
          + ' ''' + IntToStr(Wert) + ''','
          + ' ''' + PName + ''','
          + ' ''' + Liz + ''','
          + ' ''' + FloatToStr2(N_o_w) + ''','
          + ' 0, 0)';
        SQL_Insert(Daten.qUpdate, S);

        S := 'insert into PZE_Werkstatt (Nr, MaschNr, Kommt, Geht, PersonalNr)'
          + ' values (PZE_WerkstattId.NextVal,'
          + ' ''' + IntToStr(MaschNr) + ''','
          + ' ''' + FloatToStr2(N_o_w) + ''','
          + ' ''0'','
          + ' ''' + IntToStr(Wert) + ''')';
        SQL_Insert(Daten.qUpdate, S);

        S := 'insert into PERSONALANMELDUNG (Nr, PersonalNr, Name, DatumZeit, Status)'
          + ' values (PERSONALANMELDUNGId.NextVal,'
          + ' ''' + IntToStr(Wert) + ''','
          + ' ''' + PName + ''','
          + ' ''' + FloatToStr2(N_o_w) + ''','
          + ' ''' + GetL('angemeldet') + ''')';
        SQL_Insert(Daten.qUpdate, S);
      end;
    end
    else
    begin
      S7Main.Schreibe_SPS_Wert(MaschNr, TTT_GetSignalNr(CPERSONALNR_RESET), 1);
    end;
    Daten.qSuch.Next;
  end;
end;

procedure GetAusschuss_Signal;
var
  Liz, S, BANr: string;
  PRZ, MaschNr, Wert, Ausschuss, Ausschuss_act: Integer;
  DT: Real;
begin
  S := 'select * from Signal_Maschine where SignalNr = ' + IntToStr(TTT_GetSignalNr(CAUSSCHUSS))
    + ' order by MaschNr';
  SQL_Get(Daten.qSuch, S);
  while not Daten.qSuch.EOF do
  begin
    Wert := Daten.qSuch.FieldByName('Istwert').AsInteger;
    MaschNr := Daten.qSuch.FieldByName('MaschNr').AsInteger;
    Liz := TTT_GetMaschine(MaschNr);

    S := 'select * from PDE where Lizenz = ''' + Liz + ''' and Stat < 2';
    SQL_Get(Daten.qSuch2, S);
    if not Daten.qSuch2.EOF then
      BANr := Daten.qSuch2.FieldByName('BetriebsAuftragNr').AsString
    else
      BANr := '';

    if BANr <> '' then
    begin
      UpdateSQL(Daten.qUpdate, 'AArchiv', 'AUSSCHUSS', IntToStr(Wert), 'BetriebsAuftragNr', BANr);
      UpdateSQL(Daten.qUpdate, 'Maschinf', 'AUSSCHUSS', IntToStr(Wert), 'BetriebsAuftragNr', BANr);
      UpdateSQL(Daten.qUpdate, 'PDE', 'AUSSCHUSS', IntToStr(Wert), 'BetriebsAuftragNr', BANr);

      if SQLGetBool(Daten.qSuch2, 'AARchiv', 'BetriebsAuftragNr', BANr) then
      begin
        try
          PRZ := Daten.qSuch2.FieldByName('Ausschuss').AsInteger * 100 div
            Daten.qSuch2.FieldByName('ProduziertInt').AsInteger;
        except
          PRZ := 0;
        end;
        UpdateSQL(Daten.qUpdate, 'AArchiv', 'AUSSCHUSSPRZ', IntToStr(PRZ), 'BetriebsAuftragNr', BANr);
      end;

      DT := TTT_GetTPMSchichtDatum(Includis[MaschNr].Schicht, Jetzt);
      DT := DT + 1 / 24;

      S := 'Select Count(*) CNT from Ausschuss_Prot where BetriebsAuftragNr = ''' + BANr + ''''
        + ' and DatumZeit between (''' + FloatToStr2(DT - 1 / 2 / 1440) + ''') and (''' + FloatToStr2(DT + 1 / 2 / 1440)
        + ''')';
      SQL_Get(Daten.qSuch2, S);
      if Daten.qSuch2.FieldByName('CNT').AsInteger = 0 then
      begin
        S := 'insert into Ausschuss_Prot (Nr, BETRIEBSAUFTRAGNR, DATUMZEIT, Schicht, Module, Menge) values ('
          + 'Ausschuss_ProtId.NextVal,'
          + ' ''' + BANr + ''','
          + ' ''' + FloatToStr2(DT) + ''','
          + ' ''' + IntToStr(Includis[MaschNr].Schicht) + ''','
          + ' ''Bus'','
          + ' ''0'')';
        SQL_Insert(Daten.qUpdate, S);
      end;

      S := 'Select Sum(Menge) CNT from Ausschuss_Prot where BetriebsAuftragNr = ''' + BANr + '''';
      SQL_Get(Daten.qSuch2, S);
      try
        Ausschuss := Daten.qSuch2.FieldByName('CNT').AsInteger;
      except
        Ausschuss := 0;
      end;

      S := 'Select Menge from Ausschuss_Prot where BetriebsAuftragNr = ''' + BANr + ''''
        + ' and DatumZeit between (''' + FloatToStr2(DT - 1 / 2 / 1440) + ''') and (''' + FloatToStr2(DT + 1 / 2 / 1440)
        + ''')';
      SQL_Get(Daten.qSuch2, S);
      try
        Ausschuss_act := Daten.qSuch2.FieldByName('Menge').AsInteger;
      except
        Ausschuss_act := 0;
      end;

      Ausschuss := Wert - (Ausschuss - Ausschuss_act);

      if Ausschuss > 0 then
      begin
        S := 'update Ausschuss_Prot set Menge = ' + IntToStr(Ausschuss) + ' where BetriebsAuftragNr = ''' + BANr + ''''
          + ' and DatumZeit between (''' + FloatToStr2(DT - 1 / 2 / 1440) + ''') and (''' + FloatToStr2(DT + 1 / 2 /
          1440) + ''')';
        SQL_Insert(Daten.qUpdate, S);
      end;
    end;
    Daten.qSuch.Next;
  end;
end;

function N_o_w: TDateTime;
var
  SystemTime: TSystemTime;
begin
  if TimeZone = 0 then
    Result := Now
  else
  begin
    GetSystemTime(SystemTime);
    Result := SystemTimeToDateTime(SystemTime) + TimeZone / 24;
  end;
end;

end.


initialization

VerpacktAusAusschussAktiv := false;

finalization
