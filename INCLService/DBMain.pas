unit DBMain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, SvcMgr, IniFiles,
  Grids, DBGrids, StdCtrls, ImgList, ComCtrls, ExtCtrls, Menus, ToolWin, CO_Setup2,
  CO_TPM_V63, CO_Auftrag_V63, CO_SPC_V63, CO_INCMeldung_V63, Th_Schicht, Th_Zusatz,

  CO_library_V63, Th_DBBackup, CO_DataBase, CO_AliveTimer;

const
  Module = 'INCLServer';
  VerDatum = '31.10.2005';

  TAGMINUTEN = 1440;
  Stunde = 1 / 24;

  MINUTEN5 = 5 / TAGMINUTEN;
  MINUTEN10 = 10 / TAGMINUTEN;
  MINUTEN60 = Stunde;
  INC_Application = 50;

  Max_ANZAHL = 600;
  MAX_S7_LESEVERSUCHE = 100;
  Max_Nutzung = 100;
  Max_Leistung = 200;
  MAX_BARCODE = 13;

  VToleranz = 5;
  VHandToleranz = 5;

  SchichtZeitHandbetrieb = 60;

  //VIelleicht in Zukunft besser z.B. 5 Minuten = MINUTEN5 (siehe oben)

  Zeit_zum_MDEAuftrag = 0.003472; //entspricht 5 Minuten
  Zeit_zum_AutoStart = 0.006944; //entspricht 10 Minuten
  //Zeit_zum_SPCAuftrag = 0.006944; // Jetzt über Setup_par //entspricht 10 Minuten
  Zeit_zur_Meldung = 0.041664; //entspricht 60 Minuten

  StatusPlanDiff = 1440;

  SIMULATION = False; //Simulation gesamt
  TEMPSIMULATION = False; //Zur Simulation der Temperatur
  BCDSIMULATION = False;

  BYTEVAR = 0;
  WORDVAR = 1;
  DWORDVAR = 2;
  BOOLVAR = 3;

  // DWORD Variablen
  CSTUECKGESAMT = 0;
  CSTUECKAUFTRAGGESAMT = 1;
  CSTUECKAUFTRAGSCHICHT = 2;
  CSTUECKSCHICHT = 3;

  CBETRIEBSSTUNDEN = 4;
  CTAKTZEIT = 5;
  CLAUFZEITGESAMT = 6;
  CLAUFZEITSCHICHT = 7;

  CSTUECKPREUFGESAMT = 8;
  CSTUECKPRUEFAUFTRAGGESAMT = 9;
  CSTUECKPRUEFAUFTRAGSCHICHT = 10;
  CSTUECKPRUEFSCHICHT = 11;

  CSTUECKPACKGESAMT = 12;
  CSTUECKPACKAUFTRAGGESAMT = 13;
  CSTUECKPACKAUFTRAGSCHICHT = 14;
  CSTUECKPACKSCHICHT = 15;

  //Byte Variablen
  CBCD = 16;

  //Bool Variablen
  CBCD_READ = 17;
  CHANDAUTO = 18;
  CDRUCKART = 19;

  CMASCHPROGRAMMBETRIEB = 20;

  //Bool Rückmeldungen
  CAUFTRAGRESETSTUECK = 21;
  CAUFTRAGRESETPRUEF = 22;
  CAUFTRAGRESETPACK = 23;

  //Bool Rückmeldungen global
  CSCHICHTWECHSEL = 24;
  CROTELAMPE_AUS = 25;

  // Individuelle Stillstandsmeldungen
  CINDIVSTILLSTAND = 26;

  //Barcode
  CBARCODE_GELESEN = 27; //Boolean -> Barcode wurde gelesen
  CBARCODE = 28; //DWORD -> Barcode

  CAUFTRAG_FREIGABE = 29;
  CMASCHINEN_STATUS = 30;

  CTERMINAL_MASCHINE = 31;
  CREPARATUR_START_ENDE = 32;
  CTERMINAL_EINHEIT = 33;
  CTerminal_Menge_Gebucht = 34;

  CTERMINAL_EINGABE = 35;

  CTERMINAL_STILLSTAND_GEBUCHT = 36;
  CTERMINAL_STOER_KOMMT_GEHT = 37;
  CTERMINAL_STOER_NR = 38;
  CTERMINAL_STILL_STOER = 39;

  CBARCODE1 = 40;
  CBARCODE2 = 41;
  CBARCODE3 = 42;
  CBARCODE4 = 43;
  CBARCODE5 = 44;
  CBARCODE6 = 45;
  CBARCODE7 = 46;
  CBARCODE8 = 47;
  CBARCODE9 = 48;
  CBARCODE10 = 49;
  CBARCODE11 = 50;
  CBARCODE12 = 51;
  CBARCODE13 = 52;

  //SPC-Signale
  CSPC_SIGNAL = 53;

  CBARCODE_GELESEN_2 = 58;
  CBARCODE_2_1 = 59;
  CBARCODE_2_2 = 60;
  CBARCODE_2_3 = 61;
  CBARCODE_2_4 = 62;
  CBARCODE_2_5 = 63;
  CBARCODE_2_6 = 64;
  CBARCODE_2_7 = 65;
  CBARCODE_2_8 = 66;
  CBARCODE_2_9 = 67;
  CBARCODE_2_10 = 68;
  CBARCODE_2_11 = 69;
  CBARCODE_2_12 = 70;
  CBARCODE_2_13 = 71;

  CBARCODE_GELESEN_3 = 72;
  CBARCODE_3_1 = 73;
  CBARCODE_3_2 = 74;
  CBARCODE_3_3 = 75;
  CBARCODE_3_4 = 76;
  CBARCODE_3_5 = 77;
  CBARCODE_3_6 = 78;
  CBARCODE_3_7 = 79;
  CBARCODE_3_8 = 80;
  CBARCODE_3_9 = 81;
  CBARCODE_3_10 = 82;
  CBARCODE_3_11 = 83;
  CBARCODE_3_12 = 84;
  CBARCODE_3_13 = 85;

  CAUFTRAG_START_MASCHINE1 = 86;
  CAUFTRAG_START_MASCHINE2 = 87;
  CAUFTRAG_START_MASCHINE3 = 88;

  CTERMINAL_AUFTRAG_BEENDEN = 89;
  CTERMINAL_AUFTRAG_UNTERBRECHEN = 90;

  CTERMINAL_ETIKETT = 91;

  CWARMTRENNEN = 92;

  CPROGRAMM_NR = 93;
  CPROGRAMM_START = 94;
  CPROGRAMM_ENDE = 95;

  CTERMINAL_AUFTRAGNR = 96;
  CTERMINAL_AUFTRAGNR_ASCII = 97; //Buschstabe L oder K für Gehr

  CFEHLERNR = 98;
  CVORRICHTUNG = 99;
  CSTILLSTANDNR = 100;
  CJOB_STUCKZAHL = 101;

  CAUTOAUSSCHUSS_AUFTRAG = 102;
  CAUTOAUSSCHUSS_SCHICHT = 103;
  CAUTOAUSSCHUSS_AUFTRAGSCHICHT = 104;

  CRUESTEN2 = 105;
  CWARTENAUFFREIGABE = 106;

  CAUSSCHUSS = 107;
  CPERSONALNR = 108;
  CPERSONALNR_RESET = 109;
  CHEIZUNGSDAUER = 110;

  Maschinenstatus = 123;
  CSPANNZEITSUMME = 124;
  CSPANNZEITAKTUELL = 125;
  CSPSKAVITAET = 139;

  //TPM-Störgruppen
  TPMAnlage = 0;
  TPMRuesten = 1;
  TPMLogistik = 2;

  //*****************************************************************

  MaschLaeuft = 0;
  MaschRuesten = 1;
  MaschStillStoer = 2;
  MaschStillundefeniert = 4;
  MaschStillOrg = 5;

  saStoerung = 0;
  saJob = 1;
  saHinweis = 2;

type
  TSPS_Daten_DWord = record
    Maschine: ShortString;
    Signal: ShortString;
    LizenzInt: Integer;
    Adresse: string;
    Format: Integer;
    Istwert: Integer;
    Altwert: Integer;

    DBNr: Integer;
    SignalNr: Integer;
  end;

type
  TSPS_Daten_Word = record
    Maschine: ShortString;
    Signal: ShortString;
    LizenzInt: Integer;
    Adresse: string;
    Format: Integer;
    Istwert: Integer;

    DBNr: Integer;
    SignalNr: Integer;
  end;

type
  TSPS_Daten_Byte = record
    Maschine: ShortString;
    Signal: ShortString;
    LizenzInt: Integer;
    Adresse: string;
    Format: Integer;
    Istwert: Byte;

    DBNr: Integer;
    SignalNr: Integer;
  end;

type
  TSPS_Daten_Bool = record
    Maschine: ShortString;
    Signal: ShortString;
    LizenzInt: Integer;
    Adresse: string;
    Format: Integer;
    Istwert: Boolean;

    DBNr: Integer;
    SignalNr: Integer;
  end;

type
  TSPS_Daten_DWORD_Dyn = record
    Maschine: ShortString;
    Auftrag: string;
    Signal: array of ShortString;
    LizenzInt: Integer;
    Adresse: string;
    Format: Integer;
    Istwert: array of Real;

    Sollwert: array of Real;
    Tol1P: array of Integer;
    Tol1N: array of Integer;
    Tol2P: array of Integer;
    Tol2N: array of Integer;

    DBNr: array of Integer;
    SignalArt: Integer;
    SignalNr: array of Integer;

    Stichproben: array of Integer;

    Aktiv: array of Boolean;
    LetzteAbweichung: array of Real; //Soll-Ist Vergleich
    LetzterGuterSchuss: array of Integer;
    LetzterSchlechterSchuss: array of Integer;
    ErsterSchlechterSchuss: array of Integer;
    ErsterGuterSchuss: array of Integer;
    MeldungAktiv: array of Boolean;
  end;

type
  TSPS_Daten_Bool_Dyn = record
    Maschine: ShortString;
    Signal: ShortString;
    LizenzInt: Integer;
    Adresse: string;
    Format: Integer;
    Istwert: array of Boolean;

    DBNr: array of Integer;
    SignalArt: Integer;
    SignalNr: array of Integer;
    Stillstand: array of Integer;
    Istwert_alt: array of Boolean;
  end;

type
  TSPS_Daten_DWORD_Dyn_Fehler = record
    Maschine: ShortString;
    Signal: ShortString;
    LizenzInt: Integer;
    Adresse: string;
    Format: Integer;
    Istwert: array of Integer;

    DBNr: array of Integer;
    SignalArt: Integer;
    SignalNr: array of Integer;
    Istwert_alt: array of Integer;
  end;

type
  TTelegramm = record
    Adresse: string;
    Istwert: Byte;
  end;

type
  TSPC_Save = record
    Stueckzahl: Integer; //Zählerstand ALT -> SPC Werte nur schreiben, wenn sich
    //die Stückzahl erhöt hat
    SPC: Boolean; //Bei True werden SPC Werte geschrieben

    Last_Stichprobe_Schuss: Integer; //Letzte Stichprobe
    Last_SchichtProtokoll_Schuss: Integer; //Letzter Protokolleintrag

    X_Schuss: Integer; //Jeden X_Schuss Stichproben schreiben
    AuftragNr: string;
  end;

type
  TAuftragReset = record
    Produziert: string;
    Geprueft: string;
    Verpackt: string;
  end;

type
  TWerkskalender = record
    Tag: Integer;
    Schicht: array[1..3] of Smallint;
  end;

type
  TSignalMaschineItem = class
  public
    IstwertString : string;
    Istwert : Integer;
    MaschNr : Integer;
    SignalNr : Integer;
    Nr : Integer;
    Signalart : Integer;
    function CopyMe : TSignalMaschineItem;
  end;

type
  TSignalMaschineList = class(TList)
  private
    function getItem(index: Integer): TSignalMaschineItem;
    procedure setItem(index: Integer; const Value: TSignalMaschineItem);
  public
    property Items[index: Integer]: TSignalMaschineItem read getItem write setItem;
    function Add(aSignalEintrag: TSignalMaschineItem): Integer;
    function GetByMaschNr(aMaschNr : Integer) : TSignalMaschineList;
    function GetByMaschNrSignalart(aMaschNr : Integer; aSignalart : Integer) : TSignalMaschineItem;
    function GetNr(aNr : Integer) : TSignalMaschineItem;
    function GetIstwertByNr(aNr : Integer) : Integer;
    function GetBoolByNr(aNr : Integer) : Boolean;
    procedure Clear;
    destructor Destroy;
  end;


type
{$IFDEF  AZURE}
  TS7Main = class//(TComponent)
{$ELSE}
  TS7Main = class(TComponent)
{$ENDIF}
  private
    { Private-Deklarationen}
    Daten_Enabled: Boolean;
    First_Lauf: Boolean;

    Recalculation_Next: TDateTime;
    ErrorCount : Integer;
    MainServiceAliveTimer : TCO_AliveClient;
    function NeueSchicht(var AlteSchicht: Integer): Boolean;
    function CheckRoteLampeAus: Boolean;
    procedure Hole_Daten_Tabelle(Datentyp: Integer);
    procedure HandleSystemError(Sender: TObject; E: Exception; aCustomString: string);
  public
    HochlaufTPM: Boolean;
    MaschAuftragStart: Smallint; //wenn auftrag gestartet, dann MaschAusftragStart = Datenblock
    TPM: TCO_TPM;
    cSPC: TCO_SPC;
    S7_Auftrag: TCO_Auftrag;
    INC_Meldung: TCO_INCMeldung;
    Metall_Freigabe_Auftrag_Gestartet: Boolean;
//    Last_Time_Meldung: Real;

    ThreadZusatzTimer: Integer;
    ThreadZusatzLast: TDateTime;

    ThreadSignallogTimer: Integer;
    ThreadSignallogLast: TDateTime;

    ThreadBackupTimer: Integer;
    ThreadBackupLast: TDateTime;

    Timer1: TTimer;

    procedure Timer1Timer(Sender: TObject);
{$IFDEF  AZURE}
    constructor Create;
{$ELSE}
    constructor Create(AOwner: TComponent); override;
{$ENDIF}
    destructor Destroy; override;

    procedure Create_Threads;

    procedure In_SPSWerteDB;
    procedure Schreibe_SPS_Wert(MaschNr: Integer; SignalNr: Integer; Wert: Integer);
    procedure DatenLesen;
    procedure DatenLesen2;
    procedure DatenLesen_Metall;
    function GetStueckAuftragAlt(index: Integer): Longint;
    function CheckManuelleStueckBuchung(index: Integer): Boolean;
  end;

var
  Anzahl_Masch: Integer;

  Pruefen: Boolean; // Prüf-Lichschranken vorhanden
  Packen: Boolean; // Die Gepackten Stückzahlen werden zurückgemeldet
  Verpackt_Barcode: Boolean; // Die Verpackten-Artikel werden über Barcode zurückgemeldet
  Verpackt_aus_Ausschuss: Boolean;
  Ende_Aus_Verpackt: Boolean;
  BCD_Schalter: Boolean; // Störmeldungen, Auftragstart, -ende über BCD-Schalter
  SPC: Boolean; // Modul SPC vorhanden
  SPC_Stich: Boolean; // Nur SPC-Stichproben speichern
  halbautomatik: Boolean; // Änderung der zugrundegelegten Toleranzen bei Halbautomaten (Mentor)
  pruef_gleich_pack: Boolean; //False   // Die Anzahl der Gepackten Artikel wird den Geprüften gleichgesetzt
  werkzeugverwaltung: Boolean; //False   // Modul Werkzeugverwaltung vorhanden (Auftrag Start & Ende)
  maschinenreinigung: Boolean; // Setzt x Minuten vor Schichtwechsel alle Maschinen auf Grün, um
  // Arbeitsfrei Werkspl. in des TPM-Protokoll einzutragen. (Mentor)
  Werkstatt_Ausschuss: Boolean; // Ausschuss wird über Werkstattversion zurückgemeldet
  Differenzliste: Boolean;
  Runtime_Log: Boolean;
  Ruestzeit_Auftrag_FolgeAuftrag: Boolean;

  Warmtrennen: Boolean;

  Recalculation_Time: TDateTime;

  Kavitaet_laufender_Auftrag: Boolean;
  Kavitaet_laufender_Auftrag2: Boolean;
  Kavitaet_laufender_Auftrag3: Boolean;

  Palette_Rest: Boolean;

  Metall: Boolean;

  Stoer_Gleich_Ruest: Boolean;

  Stillstand_Werksplanung: Boolean;

  FehlerNr_Dyn: Boolean;

  KombiWerkzeuge: Boolean;

  Ende_Aus_Isttakt: Boolean;
  Ende_Aus_Isttakt_IstKav: Boolean;
  WZ_Warnung_Sperren : Boolean;
  Variable_Kavitaet: Boolean;

  DoppelWerkzeuge: Boolean;

  Auftragstart_Barcode: Boolean;
  Personal_Anmeldung: Boolean;
  Reparatur_Anmeldung: Boolean;
  Maschinen_Status_Schreiben: Boolean;
  Auftrag_Automatik_Start: Boolean;
  LogSignals: Boolean;

  Extrusion: Boolean;
  TPM_Auswertung: Boolean;
  Taktzeit_aus_Stamm: Boolean;
  Ruesten_Autobuchen: Boolean;
  barcodepzewerkstatt: Boolean;

  Still_Ueberwachungszeit: Boolean;

  JOBPRODUKTION: Boolean;

  QS: Boolean;
  METALL_BEARBEITUNG: Boolean;

  Maschinenwartung: Boolean;

  Stillstand_Minute_Loeschen: Integer;
  AutoRuesten: Boolean;

  Shift_Model: Integer;
  MaxSchichtTime: Integer;
  SchichtDauer: Integer;

  Stillstaende_Schicht: Integer;
  Active_Alarming: Boolean;
  Menge_Schicht_Berechnen: Boolean;
  Menge_Schicht_Minus: Boolean;
  MachineCycleCount : Boolean;
  
  RUESTPROT_AUS_STILLSTAND: Boolean;
  RUESTGRUND: Boolean;
  FolgeAuftrag_Autostart: Boolean;

  //RP TAKTLOG_CHECK
  TACKTLOG_CHECK: Boolean;
  TACKTLOG_CHECK_TOLERANZ: Integer;
  //RP SHORT_DELAY_AUTO_BOOK
  SHORT_DELAY_AUTO_BOOK: Boolean;
  SHORT_DELAY_AUTO_BOOK_VALUE: Integer;
  BLOCKSTILLSTAND: Boolean;
  AUFTRAG_BLOCK: Boolean;
  BCDAutoStartNachRuesten: Boolean;
  PersonalNr_Signal: Boolean;
  Ausschuss_Signal: Boolean;
  PackedLogFromShiftLog: Boolean;
  Heizungskontrolle: Boolean;
  PauseBuchen: Boolean;
  buchen_arbeitsfrei_bis: Boolean;
  BypassMode: Boolean;
  SpannzeitUeberwachen: Boolean;
  OptionPlanung: Boolean;
  SPC_Check_Toleranz : Integer;
  SPC_Ausreisser_Loeschen : Integer;
  SPC_NichtAufzeichnenVorSchicht : Integer;
  RuestStillstandNrUngeplant : Integer;
  RuestenIstGeplant : Boolean;
  KavitaetFromSPS : Boolean;
  AuftragKette : Boolean;
  ServerNameDesDienstes: String;
  //Suffix zum Statement, über das ggf. datensätze mit Pending <> 0 beim Update ignoriert werden
  IgnorePendingStatement: string;

  // Für Debug Durchlauf
  CalcCycleCounter : Integer;
  MaxCycles : Integer = 10;


  //Adressen
  MerkerSchichtwechsel: ShortString;
  MerkerRoteLampe: ShortString;

  Barcode_Gelesen: TSPS_Daten_Bool;
  Barcode_Gelesen_2: TSPS_Daten_Bool;
  Barcode_Gelesen_3: TSPS_Daten_Bool;
  Barcode: array[1..MAX_BARCODE] of TSPS_Daten_Word;
  Barcode_2: array[1..MAX_BARCODE] of TSPS_Daten_Word;
  Barcode_3: array[1..MAX_BARCODE] of TSPS_Daten_Word;
  Terminal_Maschine: TSPS_Daten_Word;
  Reparatur_Start_Ende: TSPS_Daten_Word;

  AuftragStart1: TSPS_Daten_Byte;
  AuftragStart2: TSPS_Daten_Byte;
  AuftragStart3: TSPS_Daten_Byte;

  Terminal_Eingabe: TSPS_Daten_Bool;

  //Arrays der Adressen
  //Format                      : DWORD (SPS)
  //****************************************************************
  StueckGesamt: array[1..Max_ANZAHL] of TSPS_Daten_DWord;
  StueckAuftragGesamt: array[1..Max_ANZAHL] of TSPS_Daten_DWord;
  StueckAuftragAlt: array[1..Max_ANZAHL] of Integer;
  Diff_Stueck: array[1..Max_ANZAHL] of Integer;
  StueckAuftragSchicht: array[1..Max_ANZAHL] of TSPS_Daten_DWord;
  StueckSchicht: array[1..Max_ANZAHL] of TSPS_Daten_DWord;

  Betriebsstunden: array[1..Max_ANZAHL] of TSPS_Daten_DWord;
  Taktzeit: array[1..Max_ANZAHL] of TSPS_Daten_DWord;
  LaufzeitGes: array[1..Max_ANZAHL] of TSPS_Daten_DWord;
  LaufzeitSchicht: array[1..Max_ANZAHL] of TSPS_Daten_DWord;

  StueckPruefGesamt: array[1..Max_ANZAHL] of TSPS_Daten_DWord;
  StueckPruefAuftragGesamt: array[1..Max_ANZAHL] of TSPS_Daten_DWord;
  StueckPruefAuftragSchicht: array[1..Max_ANZAHL] of TSPS_Daten_DWord;
  StueckPruefSchicht: array[1..Max_ANZAHL] of TSPS_Daten_DWord;

  StueckPackGesamt: array[1..Max_ANZAHL] of TSPS_Daten_DWord;
  StueckPackAuftragGesamt: array[1..Max_ANZAHL] of TSPS_Daten_DWord;
  StueckPackAuftragSchicht: array[1..Max_ANZAHL] of TSPS_Daten_DWord;
  StueckPackSchicht: array[1..Max_ANZAHL] of TSPS_Daten_DWord;

  Terminal_AuftragNr: array[1..Max_ANZAHL] of TSPS_Daten_Word;

  //****************************************************************

  //*************   SPC   ***********************************************
  SPC_Signal: array[1..Max_ANZAHL] of TSPS_Daten_DWORD_Dyn;
  Stich_Zaehler: array[1..Max_ANZAHL] of Integer;

  //****************************************************************
  Maschinen_Zustand: array[1..Max_ANZAHL] of TSPS_Daten_Word;
  Terminal_Einheit: array[1..Max_ANZAHL] of TSPS_Daten_Word;
  Terminal_StoerKommtGeht: array[1..Max_ANZAHL] of TSPS_Daten_Word;
  Terminal_Stoer_Nr: array[1..Max_ANZAHL] of TSPS_Daten_Word;
  Terminal_Still_Stoer: array[1..Max_ANZAHL] of TSPS_Daten_Word;
  Terminal_Etikett: array[1..Max_ANZAHL] of TSPS_Daten_Word;
  Programm_Nr: array[1..Max_ANZAHL] of TSPS_Daten_Word;
  Terminal_AuftragNr_ASCII: array[1..Max_ANZAHL] of TSPS_Daten_Word;

  //****************************************************************
  BCD: array[1..Max_ANZAHL] of TSPS_Daten_Byte;
  StillstandNr_SPS: array[1..Max_ANZAHL] of TSPS_Daten_DWord;
  StillstandNr_SPS_Save: array[1..Max_ANZAHL] of TSPS_Daten_DWord;
  Job_Stueckzahl: array[1..Max_ANZAHL] of TSPS_Daten_Byte;
  //****************************************************************
  BCD_Read: array[1..Max_ANZAHL] of TSPS_Daten_Bool;
  HandAuto: array[1..Max_ANZAHL] of TSPS_Daten_Bool;

  MaschProgrammbetrieb: array[1..Max_ANZAHL] of TSPS_Daten_Bool;
  Auftrag_Freigabe: array[1..Max_ANZAHL] of TSPS_Daten_Bool;

  Programm_Start: array[1..Max_ANZAHL] of TSPS_Daten_Bool;
  Programm_Ende: array[1..Max_ANZAHL] of TSPS_Daten_Bool;

  Terminal_Menge_Gebucht: array[1..Max_ANZAHL] of TSPS_Daten_Bool;
  Terminal_Stillstand_Gebucht: array[1..Max_ANZAHL] of TSPS_Daten_Bool;

  Terminal_Auftrag_Beendet: array[1..Max_ANZAHL] of TSPS_Daten_Bool;
  Terminal_Auftrag_Unterbrochen: array[1..Max_ANZAHL] of TSPS_Daten_Bool;

  MaschWarmtrennen: array[1..Max_ANZAHL] of TSPS_Daten_Bool;

  IndivStillstand: array[1..Max_ANZAHL] of TSPS_Daten_Bool_Dyn;
  FehlerNr: array[1..Max_ANZAHL] of TSPS_Daten_DWORD_Dyn_Fehler;

  Vorrichtung: array[1..Max_ANZAHL] of TSPS_Daten_Bool;

  AUTOAUSSCHUSS_AUFTRAG: array[1..Max_ANZAHL] of TSPS_Daten_DWord;
  AUTOAUSSCHUSS_SCHICHT: array[1..Max_ANZAHL] of TSPS_Daten_DWord;
  AUTOAUSSCHUSS_AUFTRAGSchicht: array[1..Max_ANZAHL] of TSPS_Daten_DWord;
  Heizungsdauer: array[1..Max_ANZAHL] of TSPS_Daten_DWord;
  Heizungsoll: array[1..Max_ANZAHL] of Integer;
  Extruderan: array[1..Max_ANZAHL] of Integer;
  JetztArbeitsfrei: array[1..Max_ANZAHL] of Integer;

  SpannzeitSumme: array[1..Max_ANZAHL] of TSPS_Daten_DWord;
  SpannzeitAktuell: array[1..Max_ANZAHL] of TSPS_Daten_DWord;
  SPSKavitaet: array[1..Max_ANZAHL] of TSPS_Daten_DWord;

  //****************************************************************
  //*********  Barcode-Telegramme **********************************
  Telegramm_Merker: string;

  L_Tele1: string;
  L_Tele2: string;
  L_Tele3: string;

  Tele1: array[1..254] of TTelegramm;
  Tele2: array[1..254] of TTelegramm;
  Tele3: array[1..254] of TTelegramm;

  Barcode1: string;
  Barcode2: string;
  Barcode3: string;

  SPC_Save: array[1..Max_ANZAHL] of TSPC_Save;

  Erg_ByteVar: Byte;
  Erg_BoolVar: Boolean;
  //****************************************************************

  AuftragReset: array[1..Max_ANZAHL] of TAuftragReset;

  S7Daten: Integer;
  S7Typ: Integer;

  ZweiteHaelfte, DritteHaelfte: Boolean;

  Ende: Boolean;
  Hochlauf: Boolean;
  Anzeige: string;
  Lese_Daten: Boolean;
  Last_Time_Meldung : Real;
  Jetzt: TDateTime;
  TimerBegin, TimerEnd: TDateTime;

  Event_Schicht: THandle;
  Event_Zusatz: THandle;

  //*********************************//
  //Signal-"Schalter"
  SigNoStillstandNr_SPS, SigNoTerminal_StillstandGebucht,SigNoTerminal_StillstandKommtGeht,
  SigNoTerminal_Auftrag_Unterbrochen, SigNoTerminal_Auftrag_Ende,  SigNoMenge_Gebucht,
  SigNoAuftrag_Freigabe, SigNoSignalauswertung, SigNoStillstand_Check, SigNoAuftrag_Starten_BCDCode,
  SigNoAuftrag_Ende, SigNoAuftrag_Start : Integer;

  //*********************************//

implementation

uses
    {$IFNDEF AZURE}
  Main,
  {$ELSE}
  MainAzure,
  {$ENDIF}

  CreateAddress, DatenM, U_SPC, U_Metall, Maindll, Arbeit, SQL_fuc, Sprache_V63,
  {$ifdef FullDebugMode}
    Service_Debug,
  {$endif}

  Dialogs, Th_SignalLog, Utils;

function TSignalMaschineItem.CopyMe;
begin
  Result := TSignalMaschineItem.Create;
  Result.maschnr := self.maschnr;
  Result.nr := self.nr;
  Result.SignalNr := self.SignalNr;
  Result.Signalart := self.Signalart;
  Result.IstwertString := self.IstwertString;
  Result.Istwert := self.Istwert;

end;

function TSignalMaschineList.getItem(index: Integer): TSignalMaschineItem;
begin
  Result := TSignalMaschineItem(TList(Self).Items[index]);
end;

procedure TSignalMaschineList.setItem(index: Integer; const Value: TSignalMaschineItem);
begin
   Self[index] := Value;
end;

function TSignalMaschineList.Add(aSignalEintrag: TSignalMaschineItem): Integer;
begin
 Result := TList(Self).Add(aSignalEintrag);
end;

function TSignalMaschineList.GetByMaschNrSignalart(aMaschNr : Integer; aSignalart : Integer) : TSignalMaschineItem;
var i : Integer;
begin
  result := nil;
  for i := 0 to self.Count-1 do
  begin
    if (self.Items[i].maschnr = aMaschnr) and (self.Items[i].signalart = aSignalart) then
    begin
      result :=self.Items[i];
      exit;
    end;
  end;
end;

function TSignalMaschineList.GetByMaschNr(aMaschNr : Integer) : TSignalMaschineList;
var i : Integer;
begin
  result := TSignalMaschineList.Create;
  for i := 0 to self.Count-1 do
  begin
    if self.Items[i].maschnr = aMaschnr then
      result.Add(self.Items[i]);
//      result.Add(self.Items[i].CopyMe);
  end;
end;

function TSignalMaschineList.GetNr(aNr : Integer) : TSignalMaschineItem;
var i : Integer;
begin
  result := nil;
  for i := 0 to self.Count-1 do
  begin
    if self.Items[i].nr = aNr then
    begin
      result := self.Items[i];
      exit;
    end;
  end;
end;

function TSignalMaschineList.GetIstwertByNr(aNr : Integer) : Integer;
var i : Integer;
begin
  result := 0;
  for i := 0 to self.Count-1 do
  begin
    if self.Items[i].nr = aNr then
    begin
      result := self.Items[i].Istwert;
      exit;
    end;
  end;
end;

function TSignalMaschineList.GetBoolByNr(aNr : Integer) : Boolean;
var i : Integer;
begin
  result := false;
  for i := 0 to self.Count-1 do
  begin
    if self.Items[i].nr = aNr then
    begin
      result := self.Items[i].Istwert=1;
      exit;
    end;
  end;
end;

procedure TSignalMaschineList.Clear;
begin
  while Self.Count > 0 do
  begin
    Self.Items[0].Destroy;
    Self.Delete(0);
  end;
  inherited;
end;

destructor TSignalMaschineList.Destroy;
begin
  while Self.Count > 0 do
  begin
    Self.Items[0].Destroy;
    Self.Delete(0);
  end;
  inherited;
end;


{$IFDEF  AZURE}
    constructor TS7Main.Create;
{$ELSE}
    constructor TS7Main.Create(AOwner: TComponent);
{$ENDIF}

var
  A, I: Integer;
  S, SQLStr, Masch: string;
  Hoch: Integer;
  SPC_Stichproben: Integer;
  Ini: TIniFile;
  timediff : Extended;
  timediffstring : string;

begin
{$IFNDEF  AZURE}
  inherited Create(AOwner);
  ServerNameDesDienstes := GetComputerNetName;
{$ELSE}
  ServerNameDesDienstes := 'AZURE';
{$ENDIF}

  ErrorCount := 0;
  s := ExtractFilePath(ParamStr(0)) + 'incl_' + DBUser + '.ini';
  Ini := TIniFile.Create(s);

{$IFNDEF  AZURE}
  if not Ini.ValueExists('Main', 'Home') then
    Ini.WriteString('Main', 'Home', 'd:\comtas\');
  INCLUDIS_HOME := Ini.ReadString('Main', 'Home', 'd:\comtas\');
  SchreibeMeldung(Module + '.Create... Version: ' + GetVersion(4) + ' (' + DBUser + ')', 0);
{$ELSE}
  SchreibeMeldung(Module + '.Create... Version: AZURE (' + DBUser + ')', 0);
{$ENDIF}
  SchreibeMeldung('... Please edit configuration file incl_' + DBUser + '.ini ....', 0);

  Hochlauf := True;
  First_Lauf := True;
  Daten_Enabled := True;

  Last_Time_Meldung := 0;

  if not Ini.ValueExists('Main', 'Timer') then
    Ini.WriteInteger('Main', 'Timer', 15);
  A := Ini.ReadInteger('Main', 'Timer', 15);

  Timer1 := TTimer.Create(nil);
  try
    Timer1.Interval := A * 1000;
  except
    Timer1.Interval := 10000;
  end;

  //INI-Schalter für ESW, so dass auch Datensätze mit pending <> 0 aktualisiert werden. Default: True, d.h. wenn pending <> 0, wird erst beim nächsten Zyklus aktualisiert (Etimex)
  if not Ini.ValueExists('Main', 'IgnorePending') then
    Ini.WriteBool('Main', 'IgnorePending', true);
  if Ini.ReadBool('Main', 'IgnorePending', true) then
    IgnorePendingStatement := ' AND pending = 0'
  else
    IgnorePendingStatement := '';
  if not Ini.ValueExists('Main', 'AliveTimerInterval') then
	Ini.WriteInteger('Main', 'AliveTimerInterval', Timer1.Interval div 100);
  A := Ini.ReadInteger('Main', 'AliveTimerInterval', Timer1.Interval div 100);
{$IFNDEF AZURE}
  MainServiceAliveTimer := TCO_AliveClient.Create(Daten.Database,'MainService', A, AOwner,
  ForceBackSlash(INCLUDIS_HOME + TRACE_DIR) + 'svc_' + LowerCase(DBUser) + '_timer.log', SERVICE_DISPLAY_NAME + UpperCase(DBUser));
{$ELSE}
  MainServiceAliveTimer := TCO_AliveClient.Create(Daten.Database,'MainService', A, nil,
  ForceBackSlash(INCLUDIS_HOME + TRACE_DIR) + 'svc_' + LowerCase(DBUser) + '_timer.log', SERVICE_DISPLAY_NAME + UpperCase(DBUser));
{$ENDIF}


  Timer1.OnTimer := Timer1Timer;

  CO_TPMGetL := @GetL;
  TPM := TCO_TPM.Create(nil);
  TPM.Database := Daten.Database;

  CO_SPCGetL := @GetL;
  cSPC := TCO_SPC.Create(nil);
  cSPC.OraSession := Daten.Database;

  if SQLGet(Daten.qSuch, 'SETUP', 'Nr', '1', True) < 1 then
  begin
    SchreibeMeldung('Error: Setup', 0);
  end;

  SpracheNr := Daten.qSuch.FieldByName('Sprache').AsInteger;
  Sprache2 := Daten.qSuch.FieldByName('Sprache2').AsInteger;

  MakeEnviroment(Daten.qUpdate);

  Pruefen := Daten.qSuch.FieldByName('Pruefen').AsInteger = 1;
  Packen := Daten.qSuch.FieldByName('Packen').AsInteger = 1;
  Verpackt_Barcode := Daten.qSuch.FieldByName('Verpackt_Barcode').AsInteger = 1;
  Verpackt_Aus_Ausschuss := Daten.qSuch.FieldByName('Verpackt_Aus_Ausschuss').AsInteger = 1;
  Ende_Aus_Verpackt := Daten.qSuch.FieldByName('Ende_Aus_Verpackt').AsInteger = 1;
  BCD_Schalter := Daten.qSuch.FieldByName('BCD_Schalter').AsInteger = 1;
  SPC := Daten.qSuch.FieldByName('SPC').AsInteger = 1;
  SPC_Stich := Daten.qSuch.FieldByName('SPC_Stich').AsInteger = 1;
  SPC_Check_Toleranz := Daten.qSuch.FieldByName('SPC_Check_Toleranz').AsInteger;
  SPC_Ausreisser_Loeschen := Daten.qSuch.FieldByName('SPC_Ausreisser_Loeschen').AsInteger;
  SPC_NichtAufzeichnenVorSchicht := Daten.qSuch.FieldByName('SPC_NichtAufzeichnenVorSchicht').AsInteger;

  halbautomatik := Daten.qSuch.FieldByName('Halbautomatik').AsInteger = 1;
  werkzeugverwaltung := Daten.qSuch.FieldByName('Werkzeug').AsInteger = 1;
  maschinenreinigung := Daten.qSuch.FieldByName('maschinenreinigung').AsInteger = 1;
  Werkstatt_Ausschuss := Daten.qSuch.FieldByName('Werkstatt_Ausschuss').AsInteger = 1;
  Differenzliste := Daten.qSuch.FieldByName('Differenzliste').AsInteger = 1;
  Ruestzeit_Auftrag_FolgeAuftrag := Daten.qSuch.FieldByName('Ruestzeit_Auftrag_Folgeauftrag').AsInteger = 1;
  Auftragstart_Barcode := Daten.qSuch.FieldByName('AuftragStart_Barcode').AsInteger = 1;
  Personal_Anmeldung := Daten.qSuch.FieldByName('Personal_Anmeldung').AsInteger = 1;
  Reparatur_Anmeldung := Daten.qSuch.FieldByName('Reparatur_Anmeldung').AsInteger = 1;
  Auftrag_Automatik_Start := Daten.qSuch.FieldByName('Auftrag_Automatik_Start').AsInteger = 1;
  Warmtrennen := Daten.qSuch.FieldByName('WARMTRENNEN').AsInteger = 1;
  FolgeAuftrag_Autostart := Daten.qSuch.FieldByName('folgeauftrag_autostart').AsInteger = 1;
  Kavitaet_laufender_Auftrag := Daten.qSuch.FieldByName('Kavitaet_laufender_Auftrag').AsInteger = 1;
  Kavitaet_laufender_Auftrag2 := Daten.qSuch.FieldByName('Kavitaet_laufender_Auftrag').AsInteger = 2;
  Kavitaet_laufender_Auftrag3 := Daten.qSuch.FieldByName('Kavitaet_laufender_Auftrag').AsInteger = 3;
  Palette_Rest := Daten.qSuch.FieldByName('Paletten_Rest').AsInteger = 1;
  Metall := Daten.qSuch.FieldByName('METALL').AsInteger = 1;
  Stoer_Gleich_Ruest := Daten.qSuch.FieldByName('Stoer_Gleich_Ruest').AsInteger = 1;
  Stillstand_Werksplanung := Daten.qSuch.FieldByName('Stillstand_Werksplanung').AsInteger = 1;
  FehlerNr_Dyn := Daten.qSuch.FieldByName('FehlerNr_Dyn').AsInteger = 1;
  KombiWerkzeuge := Daten.qSuch.FieldByName('Kombiwerkzeuge').AsInteger = 1;
  Ende_Aus_Isttakt := Daten.qSuch.FieldByName('Ende_Aus_Isttakt').AsInteger = 1;
  Ende_Aus_Isttakt_IstKav := Daten.qSuch.FieldByName('Ende_Aus_Isttakt_IstKav').AsInteger = 1;
  WZ_Warnung_Sperren := Daten.qSuch.FieldByName('WZ_Warnung_Sperren').AsInteger = 1;
  Variable_Kavitaet := Daten.qSuch.FieldByName('Variable_Kavitaet').AsInteger = 1;
  DoppelWerkzeuge := Daten.qSuch.FieldByName('DOPPELWERKZEUGE').AsInteger = 1;
  Extrusion := Daten.qSuch.FieldByName('Extrusion').AsInteger = 1;
  TPM_Auswertung := Daten.qSuch.FieldByName('TPM_AUSWERTUNG').AsInteger = 1;
  METALL_BEARBEITUNG := Daten.qSuch.FieldByName('METALL_BEARBEITUNG').AsInteger = 1;
  Maschinenwartung := Daten.qSuch.FieldByName('Maschinenwartung').AsInteger = 1;
  Stillstand_Minute_Loeschen := Daten.qSuch.FieldByName('Stillstand_Minute_Loeschen').AsInteger;
  AutoRuesten := Daten.qSuch.FieldByName('AutoRuesten').AsInteger = 1;
  RUESTPROT_AUS_STILLSTAND := Daten.qSuch.FieldByName('RUESTPROT_AUS_STILLSTAND').AsInteger = 1;
  RUESTGRUND := Daten.qSuch.FieldByName('RUESTGRUND').AsInteger = 1;
  Shift_Model := Daten.qSuch.FieldByName('SHIFT_MODEL').AsInteger;
  Heizungskontrolle := Daten.qSuch.FieldByName('heating_control').AsInteger = 1;
  Schicht1 := Daten.qSuch.FieldByName('Schicht1').AsInteger / 1440;
  Schicht2 := Daten.qSuch.FieldByName('Schicht2').AsInteger / 1440;
  Schicht3 := Daten.qSuch.FieldByName('Schicht3').AsInteger / 1440;
  TimeZone := Daten.qSuch.FieldByName('TimeZone').AsInteger;
  SpannzeitUeberwachen := Daten.qSuch.FieldByName('Spannzeit').AsInteger = 1;
  OptionPlanung := Daten.qSuch.FieldByName('Planung').AsInteger = 1;
   KavitaetFromSPS  := Daten.qSuch.FieldByName('SPSKavitaet').AsInteger = 1;
   AuftragKette := Daten.qSuch.FieldByName('AuftragKette').AsInteger = 1;
  Still_Ueberwachungszeit := Daten.qSuch.FieldByName('STILL_UEBERWACHUNGSZEIT').AsInteger = 1;
  JOBPRODUKTION := Daten.qSuch.FieldByName('JOBPRODUKTION').AsInteger = 1;
  QS := Daten.qSuch.FieldByName('QS').AsInteger = 1;
  SPC_Stichproben := Daten.qSuch.FieldByName('SPC_STICHPROBEN').AsInteger;
  Runtime_Log := Daten.qSuch.FieldByName('Runtime_Log').AsInteger = 1;

  TACKTLOG_CHECK := Daten.qSuch.FieldByName('TACKTLOG_CHECK').AsInteger = 1;
  TACKTLOG_CHECK_TOLERANZ := Daten.qSuch.FieldByName('TACKTLOG_CHECK_TOLERANZ').AsInteger;
  SHORT_DELAY_AUTO_BOOK := Daten.qSuch.FieldByName('SHORT_DELAY_AUTO_BOOK').AsInteger = 1;
  SHORT_DELAY_AUTO_BOOK_VALUE := Daten.qSuch.FieldByName('SHORT_DELAY_AUTO_BOOK_VALUE').AsInteger;

  buchen_arbeitsfrei_bis := Daten.qSuch.FieldByName('buchen_arbeitsfrei_bis').AsInteger = 1;
  PersonalNr_Signal := Daten.qSuch.FieldByName('PersonalNr_Signal').AsInteger = 1;
  Ausschuss_Signal := Daten.qSuch.FieldByName('Ausschuss_Signal').AsInteger = 1;
  BypassMode := Daten.qSuch.FieldByName('Bypassmode').AsInteger = 1;

  Stillstaende_Schicht := Daten.qSuch.FieldByName('SchichtStillstaende_berechnen').AsInteger;
  Active_Alarming := Daten.qSuch.FieldByName('Active_Alarming').AsInteger = 1;
  cSPC.Active_Alarming := Active_Alarming;

  BLOCKSTILLSTAND := Daten.qSuch.FieldByName('BLOCKSTILLSTAND').AsInteger = 1;
  AUFTRAG_BLOCK := Daten.qSuch.FieldByName('AUFTRAG_BLOCK').AsInteger = 1;
  Menge_Schicht_Berechnen := Daten.qSuch.FieldByName('Menge_Schicht_Berechnen').AsInteger = 1;
  Menge_Schicht_Minus := Daten.qSuch.FieldByName('Menge_Schicht_Minus').AsInteger = 1;

  BCDAutoStartNachRuesten := Daten.qSuch.FieldByName('AutoStartAfterSetup').AsInteger = 1;
  Taktzeit_aus_Stamm := Daten.qSuch.FieldByName('Taktzeit_aus_Stamm').AsInteger = 1;
  Ruesten_Autobuchen := Daten.qSuch.FieldByName('Ruesten_Autobuchen').AsInteger = 1;
  barcodepzewerkstatt := Daten.qSuch.FieldByName('barcodepzewerkstatt').AsInteger = 1;
  MachineCycleCount :=Daten.qSuch.FieldByName('MachineCycleCount').AsInteger = 1;

  Maschinen_Status_Schreiben := Auftragstart_Barcode;
  Daten.qSuch.close;

  SQLStr := 'SELECT COUNT(*) cnt FROM signale WHERE logit = 1';
  try
    SQL_Get(Daten.qSuch, SQLStr);
    LogSignals := Daten.qSuch.FieldByName('CNT').AsInteger > 0;
  except
    LogSignals := False;
  end;
  Daten.qSuch.close;

  SQLStr := 'select count(*) as CNT from maschine';
  SQL_Get(Daten.qSuch, SQLStr);
  Anzahl_Masch := Daten.qSuch.FieldByName('CNT').AsInteger;
  Daten.qSuch.close;

  SQLStr := 'select MAX(maschid) as MID from maschine';
  SQL_Get(Daten.qSuch, SQLStr);
  if Daten.qSuch.FieldByName('MID').AsInteger > Anzahl_Masch then
    Anzahl_Masch := Daten.qSuch.FieldByName('MID').AsInteger;
  Daten.qSuch.close;

  if Anzahl_Masch = 0 then
    SchreibeMeldung('Error: amount of machines = 0', 0);

  CO_AuftragGetL := @GetL;
  S7_Auftrag := TCO_Auftrag.Create(nil);
  S7_Auftrag.Database := Daten.Database;
  S7_Auftrag.Option_Werkzeug := werkzeugverwaltung;
  S7_Auftrag.Option_DifferenzListe := Differenzliste;
  S7_Auftrag.Option_Ruestzeit_Auftrag_Folgeauftrag := Ruestzeit_Auftrag_FolgeAuftrag;
  S7_Auftrag.Option_SPC := SPC;
  S7_Auftrag.Option_Metall := Metall;
  S7_Auftrag.Option_TaktLog := True;
  S7_Auftrag.CO_Modul := 'SVC';
  S7_Auftrag.LogStages := False;
  S7_Auftrag.SupressEvents := TCO_Setup.GetParamBool(Daten.qSuch5, 'INCL_SupressJobEvents');
{$IFNDEF  AZURE}
  S7_Auftrag.CO_Version := GetVersion(4);
{$ELSE}
  S7_Auftrag.CO_Version := 'AZURE';
{$ENDIF}

  INC_Meldung := TCO_INCMeldung.Create(nil);
  INC_Meldung.Database := Daten.Database;
  INC_Meldung.ApplicationID := INC_Application;
  INC_Meldung.RechnerNr := 0;
  INC_Meldung.Anmelden;

  SetLength(Includis, Anzahl_Masch + 1);
  SetLength(MaschZustand, Anzahl_Masch + 1);

  InitAddr;
  Ende := False;

  HochlaufTPM := True;
  First := True;
  SchichtSpeicher := -1;

  K_Init(Daten.qSuch);

  CCC_SetSchichtKonstante;

  LoadSignals(Daten.qSuch5);

  //***************************************************************
  //       GLOBALE DATEN
  //***************************************************************
  for I := 1 to MAX_BARCODE do
  begin
    Barcode[I].Maschine := '';
    Barcode[I].Signal := GetL('Barcode') + IntToStr(I);
    Barcode[I].LizenzInt := 0;
    Barcode[I].Format := WORDVAR;
    Barcode[I].Istwert := 0;
    Barcode[I].SignalNr := CBARCODE1 + I - 1;
    Barcode[I].DBNr := GetDBNr(TTT_GetSignalNr(CBARCODE1 + I - 1), 0);
  end;

  for I := 1 to MAX_BARCODE do
  begin
    Barcode_2[I].Maschine := '';
    Barcode_2[I].Signal := GetL('Barcode2') + IntToStr(I);
    Barcode_2[I].LizenzInt := 0;
    Barcode_2[I].Format := WORDVAR;
    Barcode_2[I].Istwert := 0;
    Barcode_2[I].SignalNr := CBARCODE_2_1 + I - 1;
    Barcode_2[I].DBNr := GetDBNr(TTT_GetSignalNr(CBARCODE_2_1 + I - 1), 0);
  end;

  for I := 1 to MAX_BARCODE do
  begin
    Barcode_3[I].Maschine := '';
    Barcode_3[I].Signal := GetL('Barcode') + IntToStr(I);
    Barcode_3[I].LizenzInt := 0;
    Barcode_3[I].Format := WORDVAR;
    Barcode_3[I].Istwert := 0;
    Barcode_3[I].SignalNr := CBARCODE_3_1 + I - 1;
    Barcode_3[I].DBNr := GetDBNr(TTT_GetSignalNr(CBARCODE_3_1 + I - 1), 0);
  end;

  Barcode_Gelesen.Maschine := '';
  Barcode_Gelesen.Signal := GetL('Barcode gelesen');
  Barcode_Gelesen.LizenzInt := 0;
  Barcode_Gelesen.Format := BOOLVAR;
  Barcode_Gelesen.Istwert := False;
  Barcode_Gelesen.SignalNr := CBARCODE_GELESEN;
  Barcode_Gelesen.DBNr := GetDBNr(TTT_GetSignalNr(CBARCODE_GELESEN), 0);

  Barcode_Gelesen_2.Maschine := '';
  Barcode_Gelesen_2.Signal := GetL('Barcode gelesen');
  Barcode_Gelesen_2.LizenzInt := 0;
  Barcode_Gelesen_2.Format := BOOLVAR;
  Barcode_Gelesen_2.Istwert := False;
  Barcode_Gelesen_2.SignalNr := CBARCODE_GELESEN_2;
  Barcode_Gelesen_2.DBNr := GetDBNr(TTT_GetSignalNr(CBARCODE_GELESEN_2), 0);

  Barcode_Gelesen_3.Maschine := '';
  Barcode_Gelesen_3.Signal := GetL('Barcode gelesen');
  Barcode_Gelesen_3.LizenzInt := 0;
  Barcode_Gelesen_3.Format := BOOLVAR;
  Barcode_Gelesen_3.Istwert := False;
  Barcode_Gelesen_3.SignalNr := CBARCODE_GELESEN_3;
  Barcode_Gelesen_3.DBNr := GetDBNr(TTT_GetSignalNr(CBARCODE_GELESEN_3), 0);

  Terminal_Maschine.Maschine := '';
  Terminal_Maschine.Signal := GetL('Terminal Maschine');
  Terminal_Maschine.LizenzInt := 0;
  Terminal_Maschine.Format := WORDVAR;
  Terminal_Maschine.SignalNr := CTERMINAL_MASCHINE;
  Terminal_Maschine.DBNr := GetDBNr(TTT_GetSignalNr(CTERMINAL_MASCHINE), 0);

  Reparatur_Start_Ende.Maschine := '';
  Reparatur_Start_Ende.Signal := GetL('Reparatur_Start_Ende');
  Reparatur_Start_Ende.LizenzInt := 0;
  Reparatur_Start_Ende.Format := WORDVAR;
  Reparatur_Start_Ende.SignalNr := CREPARATUR_START_ENDE;
  Reparatur_Start_Ende.DBNr := GetDBNr(TTT_GetSignalNr(CREPARATUR_START_ENDE), 0);

  Terminal_Eingabe.Maschine := '';
  Terminal_Eingabe.Signal := GetL('Terminal_Eingabe');
  Terminal_Eingabe.LizenzInt := 0;
  Terminal_Eingabe.Format := BOOLVAR;
  Terminal_Eingabe.Istwert := False;
  Terminal_Eingabe.SignalNr := CTERMINAL_EINGABE;
  Terminal_Eingabe.DBNr := GetDBNr(TTT_GetSignalNr(CTERMINAL_EINGABE), 0);

  AuftragStart1.Maschine := '';
  AuftragStart1.Signal := GetL('Auftrag Start Maschine');
  AuftragStart1.LizenzInt := 0;
  AuftragStart1.Format := BYTEVAR;
  AuftragStart1.Istwert := 0;
  AuftragStart1.SignalNr := CAUFTRAG_START_MASCHINE1;
  AuftragStart1.DBNr := GetDBNr(TTT_GetSignalNr(CAUFTRAG_START_MASCHINE1), 0);

  AuftragStart2.Maschine := '';
  AuftragStart2.Signal := GetL('Auftrag Start Maschine');
  AuftragStart2.LizenzInt := 0;
  AuftragStart2.Format := BYTEVAR;
  AuftragStart2.Istwert := 0;
  AuftragStart2.SignalNr := CAUFTRAG_START_MASCHINE2;
  AuftragStart2.DBNr := GetDBNr(TTT_GetSignalNr(CAUFTRAG_START_MASCHINE2), 0);

  AuftragStart3.Maschine := '';
  AuftragStart3.Signal := GetL('Auftrag Start Maschine');
  AuftragStart3.LizenzInt := 0;
  AuftragStart3.Format := BYTEVAR;
  AuftragStart3.Istwert := 0;
  AuftragStart3.SignalNr := CAUFTRAG_START_MASCHINE3;
  AuftragStart3.DBNr := GetDBNr(TTT_GetSignalNr(CAUFTRAG_START_MASCHINE3), 0);

  //***************************************************************
  SigNoStillstandNr_SPS := TTT_GetSignalNr(CSTILLSTANDNR);
  SigNoTerminal_StillstandGebucht := TTT_GetSignalNr(CTERMINAL_STILLSTAND_GEBUCHT);
  SigNoTerminal_StillstandKommtGeht := TTT_GetSignalNr(CTERMINAL_STOER_KOMMT_GEHT);
  SigNoTerminal_Auftrag_Unterbrochen := TTT_GetSignalNr(CTERMINAL_AUFTRAG_UNTERBRECHEN);
  SigNoTerminal_Auftrag_Ende := TTT_GetSignalNr(CTERMINAL_AUFTRAG_BEENDEN);
  SigNoMenge_Gebucht := TTT_GetSignalNr(CTerminal_Menge_Gebucht);
  SigNoAuftrag_Freigabe := TTT_GetSignalNr(CAUFTRAG_FREIGABE);
  SigNoSignalauswertung := TTT_GetSignalNr(CINDIVSTILLSTAND);
  SigNoAuftrag_Starten_BCDCode := TTT_GetSignalNr(CBCD);
  SigNoAuftrag_Ende := TTT_GetSignalNr(CPROGRAMM_ENDE);
  SigNoAuftrag_Start := TTT_GetSignalNr(CPROGRAMM_START);

  //***************************************************************

  for I := 1 to Anzahl_Masch do
  begin
    if Includis[I].IstArchiviert then
      Continue;

    Masch := TTT_GetMaschine(I);

    StueckGesamt[I].Maschine := Masch;
    StueckGesamt[I].Signal := GetL('Artikel gesamt');
    StueckGesamt[I].LizenzInt := I;
    StueckGesamt[I].Format := DWORDVAR;
    StueckGesamt[I].Istwert := 0;
    StueckGesamt[I].SignalNr := CSTUECKGESAMT;
    StueckGesamt[I].DBNr := GetDBNr(TTT_GetSignalNr(CSTUECKGESAMT), I);

    StueckAuftragAlt[I] := 0;
    Diff_Stueck[I] := 0;

    StueckAuftragGesamt[I].Maschine := Masch;
    StueckAuftragGesamt[I].Signal := GetL('Artikel Auftrag');
    StueckAuftragGesamt[I].LizenzInt := I;
    StueckAuftragGesamt[I].Format := DWORDVAR;
    StueckAuftragGesamt[I].Istwert := 0;
    StueckAuftragGesamt[I].SignalNr := CSTUECKAUFTRAGGESAMT;
    StueckAuftragGesamt[I].DBNr := GetDBNr(TTT_GetSignalNr(CSTUECKAUFTRAGGESAMT), I);

    StueckAuftragSchicht[I].Maschine := Masch;
    StueckAuftragSchicht[I].Signal := GetL('Artikel Auftrag/Schicht');
    StueckAuftragSchicht[I].LizenzInt := I;
    StueckAuftragSchicht[I].Format := DWORDVAR;
    StueckAuftragSchicht[I].Istwert := 0;
    StueckAuftragSchicht[I].SignalNr := CSTUECKAUFTRAGSCHICHT;
    StueckAuftragSchicht[I].DBNr := GetDBNr(TTT_GetSignalNr(CSTUECKAUFTRAGSCHICHT), I);

    StueckSchicht[I].Maschine := Masch;
    StueckSchicht[I].Signal := GetL('Artikel Schicht');
    StueckSchicht[I].LizenzInt := I;
    StueckSchicht[I].Format := DWORDVAR;
    StueckSchicht[I].Istwert := 0;
    StueckSchicht[I].Altwert := 0;
    StueckSchicht[I].SignalNr := CSTUECKSCHICHT;
    StueckSchicht[I].DBNr := GetDBNr(TTT_GetSignalNr(CSTUECKSCHICHT), I);

    Betriebsstunden[I].Maschine := Masch;
    Betriebsstunden[I].Signal := GetL('Betriebsstunden');
    Betriebsstunden[I].LizenzInt := I;
    Betriebsstunden[I].Format := DWORDVAR;
    Betriebsstunden[I].Istwert := 0;
    Betriebsstunden[I].SignalNr := CBETRIEBSSTUNDEN;
    Betriebsstunden[I].DBNr := GetDBNr(TTT_GetSignalNr(CBETRIEBSSTUNDEN), I);

    Taktzeit[I].Maschine := Masch;
    Taktzeit[I].Signal := GetL('Taktzeit');
    Taktzeit[I].LizenzInt := I;
    Taktzeit[I].Format := DWORDVAR;
    Taktzeit[I].Istwert := 0;
    Taktzeit[I].SignalNr := CTAKTZEIT;
    Taktzeit[I].DBNr := GetDBNr(TTT_GetSignalNr(CTAKTZEIT), I);

    LaufzeitGes[I].Maschine := Masch;
    LaufzeitGes[I].Signal := GetL('Maschinenlaufzeit gesamt');
    LaufzeitGes[I].LizenzInt := I;
    LaufzeitGes[I].Format := DWORDVAR;
    LaufzeitGes[I].Istwert := 0;
    LaufzeitGes[I].SignalNr := CLAUFZEITGESAMT;
    LaufzeitGes[I].DBNr := GetDBNr(TTT_GetSignalNr(CLAUFZEITGESAMT), I);

    LaufzeitSchicht[I].Maschine := Masch;
    LaufzeitSchicht[I].Signal := GetL('Maschinenlaufzeit Schicht');
    LaufzeitSchicht[I].LizenzInt := I;
    LaufzeitSchicht[I].Format := DWORDVAR;
    LaufzeitSchicht[I].Istwert := 0;
    LaufzeitSchicht[I].SignalNr := CLAUFZEITSCHICHT;
    LaufzeitSchicht[I].DBNr := GetDBNr(TTT_GetSignalNr(CLAUFZEITSCHICHT), I);

    StueckPruefGesamt[I].Maschine := Masch;
    StueckPruefGesamt[I].Signal := GetL('Geprüfte Artikel gesamt');
    StueckPruefGesamt[I].LizenzInt := I;
    StueckPruefGesamt[I].Format := DWORDVAR;
    StueckPruefGesamt[I].SignalNr := CSTUECKPREUFGESAMT;
    StueckPruefGesamt[I].DBNr := GetDBNr(TTT_GetSignalNr(CSTUECKPREUFGESAMT), I);

    StueckPruefAuftragGesamt[I].Maschine := Masch;
    StueckPruefAuftragGesamt[I].Signal := GetL('Geprüfte Artikel Auftrag');
    StueckPruefAuftragGesamt[I].LizenzInt := I;
    StueckPruefAuftragGesamt[I].Format := DWORDVAR;
    StueckPruefAuftragGesamt[I].SignalNr := CSTUECKPRUEFAUFTRAGGESAMT;
    StueckPruefAuftragGesamt[I].DBNr := GetDBNr(TTT_GetSignalNr(CSTUECKPRUEFAUFTRAGGESAMT), I);

    StueckPruefAuftragSchicht[I].Maschine := Masch;
    StueckPruefAuftragSchicht[I].Signal := GetL('Geprüfte Artikel Auftrag/Schicht');
    StueckPruefAuftragSchicht[I].LizenzInt := I;
    StueckPruefAuftragSchicht[I].Format := DWORDVAR;
    StueckPruefAuftragSchicht[I].SignalNr := CSTUECKPRUEFAUFTRAGSCHICHT;
    StueckPruefAuftragSchicht[I].DBNr := GetDBNr(TTT_GetSignalNr(CSTUECKPRUEFAUFTRAGSCHICHT), I);

    StueckPruefSchicht[I].Maschine := Masch;
    StueckPruefSchicht[I].Signal := GetL('Geprüfte Artikel Schicht');
    StueckPruefSchicht[I].LizenzInt := I;
    StueckPruefSchicht[I].Format := DWORDVAR;
    StueckPruefSchicht[I].SignalNr := CSTUECKPRUEFSCHICHT;
    StueckPruefSchicht[I].DBNr := GetDBNr(TTT_GetSignalNr(CSTUECKPRUEFSCHICHT), I);

    StueckPackGesamt[I].Maschine := Masch;
    StueckPackGesamt[I].Signal := GetL('Gepackte Artikel gesamt');
    StueckPackGesamt[I].LizenzInt := I;
    StueckPackGesamt[I].Format := DWORDVAR;
    StueckPackGesamt[I].SignalNr := CSTUECKPACKGESAMT;
    StueckPackGesamt[I].DBNr := GetDBNr(TTT_GetSignalNr(CSTUECKPACKGESAMT), I);

    StueckPackAuftragGesamt[I].Maschine := Masch;
    StueckPackAuftragGesamt[I].Signal := GetL('Gepackte Artikel Auftrag');
    StueckPackAuftragGesamt[I].LizenzInt := I;
    StueckPackAuftragGesamt[I].Format := DWORDVAR;
    StueckPackAuftragGesamt[I].SignalNr := CSTUECKPACKAUFTRAGGESAMT;
    StueckPackAuftragGesamt[I].DBNr := GetDBNr(TTT_GetSignalNr(CSTUECKPACKAUFTRAGGESAMT), I);

    StueckPackAuftragSchicht[I].Maschine := Masch;
    StueckPackAuftragSchicht[I].Signal := GetL('Gepackte Artikel Auftrag/Schicht');
    StueckPackAuftragSchicht[I].LizenzInt := I;
    StueckPackAuftragSchicht[I].Format := DWORDVAR;
    StueckPackAuftragSchicht[I].SignalNr := CSTUECKPACKAUFTRAGSCHICHT;
    StueckPackAuftragSchicht[I].DBNr := GetDBNr(TTT_GetSignalNr(CSTUECKPACKAUFTRAGSCHICHT), I);

    StueckPackSchicht[I].Maschine := Masch;
    StueckPackSchicht[I].Signal := GetL('Gepackte Artikel Schicht');
    StueckPackSchicht[I].LizenzInt := I;
    StueckPackSchicht[I].Format := DWORDVAR;
    StueckPackSchicht[I].SignalNr := CSTUECKPACKSCHICHT;
    StueckPackSchicht[I].DBNr := GetDBNr(TTT_GetSignalNr(CSTUECKPACKSCHICHT), I);

    Terminal_AuftragNr[I].Maschine := Masch;
    Terminal_AuftragNr[I].Signal := GetL('CTERMINAL_AUFTRAGNR');
    Terminal_AuftragNr[I].LizenzInt := I;
    Terminal_AuftragNr[I].Format := DWORDVAR;
    Terminal_AuftragNr[I].SignalNr := CTERMINAL_AUFTRAGNR;
    Terminal_AuftragNr[I].DBNr := GetDBNr(TTT_GetSignalNr(CTERMINAL_AUFTRAGNR), I);

    Maschinen_Zustand[I].Maschine := Masch;
    Maschinen_Zustand[I].Signal := GetL('Maschinen Zustand');
    Maschinen_Zustand[I].LizenzInt := I;
    Maschinen_Zustand[I].Format := WORDVAR;
    Maschinen_Zustand[I].SignalNr := CMASCHINEN_STATUS;
    Maschinen_Zustand[I].DBNr := GetDBNr(TTT_GetSignalNr(CMASCHINEN_STATUS), I);

    Terminal_Menge_Gebucht[I].Maschine := Masch;
    Terminal_Menge_Gebucht[I].Signal := GetL('Terminal Menge gebucht');
    Terminal_Menge_Gebucht[I].LizenzInt := I;
    Terminal_Menge_Gebucht[I].Format := BOOLVAR;
    Terminal_Menge_Gebucht[I].Istwert := False;
    Terminal_Menge_Gebucht[I].SignalNr := CTerminal_Menge_Gebucht;
    Terminal_Menge_Gebucht[I].DBNr := GetDBNr(SigNoMenge_Gebucht, I);

    Terminal_Einheit[I].Maschine := Masch;
    Terminal_Einheit[I].Signal := GetL('Terminal_Einheit');
    Terminal_Einheit[I].LizenzInt := I;
    Terminal_Einheit[I].Format := WORDVAR;
    Terminal_Einheit[I].SignalNr := CTERMINAL_EINHEIT;
    Terminal_Einheit[I].DBNr := GetDBNr(TTT_GetSignalNr(CTERMINAL_EINHEIT), I);

    Terminal_Etikett[I].Maschine := Masch;
    Terminal_Etikett[I].Signal := GetL('Terminal_Etikett');
    Terminal_Etikett[I].LizenzInt := I;
    Terminal_Etikett[I].Format := WORDVAR;
    Terminal_Etikett[I].SignalNr := CTERMINAL_ETIKETT;
    Terminal_Etikett[I].DBNr := GetDBNr(TTT_GetSignalNr(CTERMINAL_ETIKETT), I);

    Programm_Nr[I].Maschine := Masch;
    Programm_Nr[I].Signal := GetL('Programm_Nr');
    Programm_Nr[I].LizenzInt := I;
    Programm_Nr[I].Format := WORDVAR;
    Programm_Nr[I].SignalNr := CPROGRAMM_NR;
    Programm_Nr[I].DBNr := GetDBNr(TTT_GetSignalNr(CPROGRAMM_NR), I);

    Terminal_Stillstand_Gebucht[I].Maschine := Masch;
    Terminal_Stillstand_Gebucht[I].Signal := GetL('Terminal Menge gebucht');
    Terminal_Stillstand_Gebucht[I].LizenzInt := I;
    Terminal_Stillstand_Gebucht[I].Format := BOOLVAR;
    Terminal_Stillstand_Gebucht[I].Istwert := False;
    Terminal_Stillstand_Gebucht[I].SignalNr := CTERMINAL_STILLSTAND_GEBUCHT;
    Terminal_Stillstand_Gebucht[I].DBNr := GetDBNr(SigNoTerminal_StillstandGebucht, I);

    Terminal_StoerKommtGeht[I].Maschine := Masch;
    Terminal_StoerKommtGeht[I].Signal := GetL('Terminal_StoerKommtGeht');
    Terminal_StoerKommtGeht[I].LizenzInt := I;
    Terminal_StoerKommtGeht[I].Format := WORDVAR;
    Terminal_StoerKommtGeht[I].SignalNr := CTERMINAL_STOER_KOMMT_GEHT;
    Terminal_StoerKommtGeht[I].DBNr := GetDBNr(SigNoTerminal_StillstandKommtGeht, I);

    Terminal_Stoer_Nr[I].Maschine := Masch;
    Terminal_Stoer_Nr[I].Signal := GetL('Terminal_Stoer_Nr');
    Terminal_Stoer_Nr[I].LizenzInt := I;
    Terminal_Stoer_Nr[I].Format := WORDVAR;
    Terminal_Stoer_Nr[I].SignalNr := CTERMINAL_STOER_NR;
    Terminal_Stoer_Nr[I].DBNr := GetDBNr(TTT_GetSignalNr(CTERMINAL_STOER_NR), I);

    Terminal_Still_Stoer[I].Maschine := Masch;
    Terminal_Still_Stoer[I].Signal := GetL('Terminal_Still_Stoer');
    Terminal_Still_Stoer[I].LizenzInt := I;
    Terminal_Still_Stoer[I].Format := WORDVAR;
    Terminal_Still_Stoer[I].SignalNr := CTERMINAL_STILL_STOER;
    Terminal_Still_Stoer[I].DBNr := GetDBNr(TTT_GetSignalNr(CTERMINAL_STILL_STOER), I);

    BCD[I].Maschine := Masch;
    BCD[I].Signal := GetL('BCD-Codierschalter');
    BCD[I].LizenzInt := I;
    BCD[I].Format := BYTEVAR;
    BCD[I].Istwert := 0;
    BCD[I].SignalNr := CBCD;
    BCD[I].DBNr := GetDBNr(SigNoAuftrag_Starten_BCDCode, I);

    StillstandNr_SPS[I].Maschine := Masch;
    StillstandNr_SPS[I].Signal := GetL('StillstandNr_SPS');
    StillstandNr_SPS[I].LizenzInt := I;
    StillstandNr_SPS[I].Format := DWORDVAR;
    StillstandNr_SPS[I].Istwert := 0;
    StillstandNr_SPS[I].SignalNr := CSTILLSTANDNR;
    StillstandNr_SPS[I].DBNr := GetDBNr(SigNoStillstandNr_SPS, I);

    // StillstandNr_SPS_Save[I] := 0;

    Job_Stueckzahl[I].Maschine := Masch;
    Job_Stueckzahl[I].Signal := GetL('Job_Stueckzahl');
    Job_Stueckzahl[I].LizenzInt := I;
    Job_Stueckzahl[I].Format := BYTEVAR;
    Job_Stueckzahl[I].Istwert := 0;
    Job_Stueckzahl[I].SignalNr := CJOB_STUCKZAHL;
    Job_Stueckzahl[I].DBNr := GetDBNr(TTT_GetSignalNr(CJOB_STUCKZAHL), I);

    Terminal_AuftragNr_ASCII[I].Maschine := Masch;
    Terminal_AuftragNr_ASCII[I].Signal := GetL('CTERMINAL_AUFTRAGNR_ASCII');
    Terminal_AuftragNr_ASCII[I].LizenzInt := I;
    Terminal_AuftragNr_ASCII[I].Format := BYTEVAR;
    Terminal_AuftragNr_ASCII[I].Istwert := 0;
    Terminal_AuftragNr_ASCII[I].SignalNr := CTERMINAL_AUFTRAGNR_ASCII;
    Terminal_AuftragNr_ASCII[I].DBNr := GetDBNr(TTT_GetSignalNr(CTERMINAL_AUFTRAGNR_ASCII), I);

    BCD_Read[I].Maschine := Masch;
    BCD_Read[I].Signal := GetL('BCD_Code_Lesen');
    BCD_Read[I].LizenzInt := I;
    BCD_Read[I].Format := BOOLVAR;
    BCD_Read[I].Istwert := False;
    BCD_Read[I].SignalNr := CBCD_READ;
    BCD_Read[I].DBNr := GetDBNr(TTT_GetSignalNr(CBCD_READ), I);

    HandAuto[I].Maschine := Masch;
    HandAuto[I].Signal := GetL('Hand / Automatik');
    HandAuto[I].LizenzInt := I;
    HandAuto[I].Format := BOOLVAR;
    HandAuto[I].Istwert := False;
    HandAuto[I].SignalNr := CHANDAUTO;
    HandAuto[I].DBNr := GetDBNr(TTT_GetSignalNr(CHANDAUTO), I);

    MaschProgrammbetrieb[I].Maschine := Masch;
    MaschProgrammbetrieb[I].Signal := GetL('Maschine Programmbetrieb');
    MaschProgrammbetrieb[I].LizenzInt := I;
    MaschProgrammbetrieb[I].Format := BOOLVAR;
    MaschProgrammbetrieb[I].Istwert := False;
    MaschProgrammbetrieb[I].SignalNr := CMASCHPROGRAMMBETRIEB;
    MaschProgrammbetrieb[I].DBNr := GetDBNr(TTT_GetSignalNr(CMASCHPROGRAMMBETRIEB), I);

    Terminal_Auftrag_Beendet[I].Maschine := Masch;
    Terminal_Auftrag_Beendet[I].Signal := GetL('Terminal_Auftrag_Beendet');
    Terminal_Auftrag_Beendet[I].LizenzInt := I;
    Terminal_Auftrag_Beendet[I].Format := BOOLVAR;
    Terminal_Auftrag_Beendet[I].Istwert := False;
    Terminal_Auftrag_Beendet[I].SignalNr := CTERMINAL_AUFTRAG_BEENDEN;
    Terminal_Auftrag_Beendet[I].DBNr := GetDBNr(SigNoTerminal_Auftrag_Ende, I);

    Terminal_Auftrag_Unterbrochen[I].Maschine := Masch;
    Terminal_Auftrag_Unterbrochen[I].Signal := GetL('Terminal_Auftrag_Unterbrochen');
    Terminal_Auftrag_Unterbrochen[I].LizenzInt := I;
    Terminal_Auftrag_Unterbrochen[I].Format := BOOLVAR;
    Terminal_Auftrag_Unterbrochen[I].Istwert := False;
    Terminal_Auftrag_Unterbrochen[I].SignalNr := CTERMINAL_AUFTRAG_UNTERBRECHEN;
    Terminal_Auftrag_Unterbrochen[I].DBNr := GetDBNr(SigNoTerminal_Auftrag_Unterbrochen, I);

    MaschWarmtrennen[I].Maschine := Masch;
    MaschWarmtrennen[I].Signal := GetL('MaschWarmtrennen');
    MaschWarmtrennen[I].LizenzInt := I;
    MaschWarmtrennen[I].Format := BOOLVAR;
    MaschWarmtrennen[I].Istwert := False;
    MaschWarmtrennen[I].SignalNr := CWARMTRENNEN;
    MaschWarmtrennen[I].DBNr := GetDBNr(TTT_GetSignalNr(CWARMTRENNEN), I);

    Auftrag_Freigabe[I].Maschine := Masch;
    Auftrag_Freigabe[I].Signal := GetL('Auftragsfreigabe');
    Auftrag_Freigabe[I].LizenzInt := I;
    Auftrag_Freigabe[I].Format := BOOLVAR;
    Auftrag_Freigabe[I].Istwert := False;
    Auftrag_Freigabe[I].SignalNr := CAUFTRAG_FREIGABE;
    Auftrag_Freigabe[I].DBNr := GetDBNr(SigNoAuftrag_Freigabe, I);

    Programm_Start[I].Maschine := Masch;
    Programm_Start[I].Signal := GetL('Programm_Start');
    Programm_Start[I].LizenzInt := I;
    Programm_Start[I].Format := BOOLVAR;
    Programm_Start[I].Istwert := False;
    Programm_Start[I].SignalNr := CPROGRAMM_START;
    Programm_Start[I].DBNr := GetDBNr(SigNoAuftrag_Start, I);

    Programm_Ende[I].Maschine := Masch;
    Programm_Ende[I].Signal := GetL('Programm_Ende');
    Programm_Ende[I].LizenzInt := I;
    Programm_Ende[I].Format := BOOLVAR;
    Programm_Ende[I].Istwert := False;
    Programm_Ende[I].SignalNr := CPROGRAMM_ENDE;
    Programm_Ende[I].DBNr := GetDBNr(SigNoAuftrag_Ende, I);

    IndivStillstand[I].Maschine := Masch;
    IndivStillstand[I].Signal := GetL('Individueller Stillstand');
    IndivStillstand[I].LizenzInt := I;
    IndivStillstand[I].Format := BOOLVAR;
    IndivStillstand[I].SignalArt := CINDIVSTILLSTAND;

    SPC_Signal[I].Maschine := Masch;
    SPC_Signal[I].LizenzInt := I;
    SPC_Signal[I].Format := DWORDVAR;
    SPC_Signal[I].SignalArt := CSPC_SIGNAL;

    SPC_Save[I].Stueckzahl := -1;
    SPC_Save[I].X_Schuss := SPC_Stichproben;
    SPC_Save[I].AuftragNr := '';
    SPC_Save[I].Last_Stichprobe_Schuss := -1;
    SPC_Save[I].Last_SchichtProtokoll_Schuss := -1;
    SPC_Save[I].SPC := False;

    Stich_Zaehler[I] := 0;

    Vorrichtung[I].Maschine := Masch;
    Vorrichtung[I].Signal := GetL('Vorrichtung');
    Vorrichtung[I].LizenzInt := I;
    Vorrichtung[I].Format := BOOLVAR;
    Vorrichtung[I].Istwert := False;
    Vorrichtung[I].SignalNr := CVORRICHTUNG;
    Vorrichtung[I].DBNr := GetDBNr(TTT_GetSignalNr(CVORRICHTUNG), I);

    AUTOAUSSCHUSS_AUFTRAG[I].Maschine := Masch;
    AUTOAUSSCHUSS_AUFTRAG[I].Signal := 'AUTOAUSSCHUSS_AUFTRAG';
    AUTOAUSSCHUSS_AUFTRAG[I].LizenzInt := I;
    AUTOAUSSCHUSS_AUFTRAG[I].Format := DWORDVAR;
    AUTOAUSSCHUSS_AUFTRAG[I].Istwert := 0;
    AUTOAUSSCHUSS_AUFTRAG[I].SignalNr := CAUTOAUSSCHUSS_AUFTRAG;
    AUTOAUSSCHUSS_AUFTRAG[I].DBNr := GetDBNr(TTT_GetSignalNr(CAUTOAUSSCHUSS_AUFTRAG), I);

    AUTOAUSSCHUSS_SCHICHT[I].Maschine := Masch;
    AUTOAUSSCHUSS_SCHICHT[I].Signal := 'AUTOAUSSCHUSS_SCHICHT';
    AUTOAUSSCHUSS_SCHICHT[I].LizenzInt := I;
    AUTOAUSSCHUSS_SCHICHT[I].Format := DWORDVAR;
    AUTOAUSSCHUSS_SCHICHT[I].Istwert := 0;
    AUTOAUSSCHUSS_SCHICHT[I].SignalNr := CAUTOAUSSCHUSS_SCHICHT;
    AUTOAUSSCHUSS_SCHICHT[I].DBNr := GetDBNr(TTT_GetSignalNr(CAUTOAUSSCHUSS_SCHICHT), I);

    AUTOAUSSCHUSS_AUFTRAGSchicht[I].Maschine := Masch;
    AUTOAUSSCHUSS_AUFTRAGSchicht[I].Signal := 'AUTOAUSSCHUSS_AUFTRAGSCHICHT';
    AUTOAUSSCHUSS_AUFTRAGSchicht[I].LizenzInt := I;
    AUTOAUSSCHUSS_AUFTRAGSchicht[I].Format := DWORDVAR;
    AUTOAUSSCHUSS_AUFTRAGSchicht[I].Istwert := 0;
    AUTOAUSSCHUSS_AUFTRAGSchicht[I].SignalNr := CAUTOAUSSCHUSS_AUFTRAGSCHICHT;
    AUTOAUSSCHUSS_AUFTRAGSchicht[I].DBNr := GetDBNr(TTT_GetSignalNr(CAUTOAUSSCHUSS_AUFTRAGSCHICHT), I);

    Heizungsdauer[I].Maschine := Masch;
    Heizungsdauer[I].Signal := GetL('Heizungsdauer');
    Heizungsdauer[I].LizenzInt := I;
    Heizungsdauer[I].Format := WORDVAR;
    Heizungsdauer[I].SignalNr := CHEIZUNGSDAUER;
    Heizungsdauer[I].DBNr := GetDBNr(TTT_GetSignalNr(CHEIZUNGSDAUER), I);

    SpannzeitSumme[I].Maschine := Masch;
    SpannzeitSumme[I].Signal := GetL('SpannzeitSumme');
    SpannzeitSumme[I].LizenzInt := I;
    SpannzeitSumme[I].Format := WORDVAR;
    SpannzeitSumme[I].SignalNr := CSPANNZEITSUMME;
    SpannzeitSumme[I].DBNr := GetDBNr(TTT_GetSignalNr(CSPANNZEITSUMME), I);

    SpannzeitAktuell[I].Maschine := Masch;
    SpannzeitAktuell[I].Signal := GetL('SpannzeitAktuell');
    SpannzeitAktuell[I].LizenzInt := I;
    SpannzeitAktuell[I].Format := WORDVAR;
    SpannzeitAktuell[I].SignalNr := CSPANNZEITAKTUELL;
    SpannzeitAktuell[I].DBNr := GetDBNr(TTT_GetSignalNr(CSPANNZEITAKTUELL), I);


    SPSKavitaet[i].Maschine := Masch;
    SPSKavitaet[I].Signal := GetL('Kavitaet');
    SPSKavitaet[I].LizenzInt := I;
    SPSKavitaet[I].Format := WORDVAR;
    SPSKavitaet[I].SignalNr := CSPSKAVITAET;
    SPSKavitaet[I].DBNr := GetDBNr(TTT_GetSignalNr(CSPSKAVITAET), I);
    JetztArbeitsfrei[I] := -1;
  end;

  SQLStr := 'Select Signal_Maschine.*, maschine.datenblock from signal_maschine, signale, maschine where (signal_maschine.signalnr = signale.signalnr) and (signale.SignalArt = '''
    + IntToStr(CINDIVSTILLSTAND) + ''') and (signal_maschine.maschnr = maschine.Maschnr)';
  SQL_Get(Daten.qSuch, SQLStr);
  while not Daten.qSuch.EOF do
  begin
    if IndivStillstand[Daten.qSuch.FieldByName('Datenblock').AsInteger].Istwert = nil then
    begin
      SetLength(IndivStillstand[Daten.qSuch.FieldByName('Datenblock').AsInteger].Istwert, 1);
      SetLength(IndivStillstand[Daten.qSuch.FieldByName('Datenblock').AsInteger].DBNr, 1);
      SetLength(IndivStillstand[Daten.qSuch.FieldByName('Datenblock').AsInteger].SignalNr, 1);
      SetLength(IndivStillstand[Daten.qSuch.FieldByName('Datenblock').AsInteger].Stillstand, 1);
      SetLength(IndivStillstand[Daten.qSuch.FieldByName('Datenblock').AsInteger].Istwert_alt, 1);
    end
    else
    begin
      SetLength(IndivStillstand[Daten.qSuch.FieldByName('Datenblock').AsInteger].Istwert,
        Length(IndivStillstand[Daten.qSuch.FieldByName('Datenblock').AsInteger].Istwert) + 1);
      SetLength(IndivStillstand[Daten.qSuch.FieldByName('Datenblock').AsInteger].DBNr,
        Length(IndivStillstand[Daten.qSuch.FieldByName('Datenblock').AsInteger].DBNr) + 1);
      SetLength(IndivStillstand[Daten.qSuch.FieldByName('Datenblock').AsInteger].SignalNr,
        Length(IndivStillstand[Daten.qSuch.FieldByName('Datenblock').AsInteger].SignalNr) + 1);
      SetLength(IndivStillstand[Daten.qSuch.FieldByName('Datenblock').AsInteger].Stillstand,
        Length(IndivStillstand[Daten.qSuch.FieldByName('Datenblock').AsInteger].Stillstand) + 1);
      SetLength(IndivStillstand[Daten.qSuch.FieldByName('Datenblock').AsInteger].Istwert_alt,
        Length(IndivStillstand[Daten.qSuch.FieldByName('Datenblock').AsInteger].Istwert_alt) + 1);
    end;
    IndivStillstand[Daten.qSuch.FieldByName('Datenblock').AsInteger].SignalNr[Length(IndivStillstand[Daten.qSuch.FieldByName('Datenblock').AsInteger].SignalNr)
    - 1] := Daten.qSuch.FieldByName('Signalnr').AsInteger;
    IndivStillstand[Daten.qSuch.FieldByName('Datenblock').AsInteger].DBNr[Length(IndivStillstand[Daten.qSuch.FieldByName('Datenblock').AsInteger].DBNr) - 1] :=
    Daten.qSuch.FieldByName('nr').AsInteger;
    IndivStillstand[Daten.qSuch.FieldByName('Datenblock').AsInteger].Istwert_alt[Length(IndivStillstand[Daten.qSuch.FieldByName('Datenblock').AsInteger].Istwert_alt) - 1] := False;

    SQLStr := 'Select TPM_Maschzuordnung.* from TPM_Maschzuordnung,Maschine where (SignalNr = ''' +
      Daten.qSuch.FieldByName('SignalNr').AsString + ''')'
      + ' and (Maschine.Datenblock = ''' + Daten.qSuch.FieldByName('Datenblock').AsString +
      ''') and (Maschine.Maschnr = TPM_Maschzuordnung.MaschNr)';
    SQL_Get(Daten.qSuch2, SQLStr);
    IndivStillstand[Daten.qSuch.FieldByName('Datenblock').AsInteger].Stillstand[Length(IndivStillstand[Daten.qSuch.FieldByName('Datenblock').AsInteger].Stillstand) - 1] := Daten.qSuch2.FieldByName('Stillstandnr').AsInteger;
    Daten.qSuch.Next;
  end;

  SQLStr := 'Select Signal_Maschine.*, maschine.datenblock from signal_maschine, signale, maschine  where (signal_maschine.signalnr = signale.signalnr) and (signale.SignalArt = '''
    + IntToStr(CFEHLERNR) + ''') and (signal_maschine.maschnr = maschine.Maschnr)';
  SQL_Get(Daten.qSuch, SQLStr);
  while not Daten.qSuch.EOF do
  begin
    if FehlerNr[Daten.qSuch.FieldByName('Datenblock').AsInteger].Istwert = nil then
    begin
      SetLength(FehlerNr[Daten.qSuch.FieldByName('Datenblock').AsInteger].Istwert, 1);
      SetLength(FehlerNr[Daten.qSuch.FieldByName('Datenblock').AsInteger].DBNr, 1);
      SetLength(FehlerNr[Daten.qSuch.FieldByName('Datenblock').AsInteger].SignalNr, 1);
      SetLength(FehlerNr[Daten.qSuch.FieldByName('Datenblock').AsInteger].Istwert_alt, 1);
    end
    else
    begin
      SetLength(FehlerNr[Daten.qSuch.FieldByName('Datenblock').AsInteger].Istwert,
        Length(FehlerNr[Daten.qSuch.FieldByName('Datenblock').AsInteger].Istwert) + 1);
      SetLength(FehlerNr[Daten.qSuch.FieldByName('Datenblock').AsInteger].DBNr,
        Length(FehlerNr[Daten.qSuch.FieldByName('Datenblock').AsInteger].DBNr) + 1);
      SetLength(FehlerNr[Daten.qSuch.FieldByName('Datenblock').AsInteger].SignalNr,
        Length(FehlerNr[Daten.qSuch.FieldByName('Datenblock').AsInteger].SignalNr) + 1);
      SetLength(FehlerNr[Daten.qSuch.FieldByName('Datenblock').AsInteger].Istwert_alt,
        Length(FehlerNr[Daten.qSuch.FieldByName('Datenblock').AsInteger].Istwert_alt) + 1);
    end;
    FehlerNr[Daten.qSuch.FieldByName('Datenblock').AsInteger].SignalNr[Length(FehlerNr[Daten.qSuch.FieldByName('Datenblock').AsInteger].SignalNr) - 1] :=
    Daten.qSuch.FieldByName('Signalnr').AsInteger;
    FehlerNr[Daten.qSuch.FieldByName('Datenblock').AsInteger].DBNr[Length(FehlerNr[Daten.qSuch.FieldByName('Datenblock').AsInteger].DBNr) -
    1] := Daten.qSuch.FieldByName('nr').AsInteger;
    FehlerNr[Daten.qSuch.FieldByName('Datenblock').AsInteger].Istwert_alt[Length(FehlerNr[Daten.qSuch.FieldByName('Datenblock').AsInteger].Istwert_alt) - 1] :=
    9999;

    Daten.qSuch.Next;
  end;

  //**************************************************************************
  //*********************** SPC **********************************************
  //**************************************************************************
  SQLStr := 'Select Signal_Maschine.*, maschine.datenblock, signale.signal from signal_maschine, signale, maschine  where (signal_maschine.signalnr = signale.signalnr) and (signale.SignalArt = '''
    + IntToStr(CSPC_SIGNAL) + ''') and (signal_maschine.maschnr = maschine.Maschnr)';
  SQL_Get(Daten.qSuch, SQLStr);
  while not Daten.qSuch.EOF do
  begin
    if SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Istwert = nil then
    begin
      SetLength(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Istwert, 1);
      SetLength(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].DBNr, 1);
      SetLength(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].SignalNr, 1);
      SetLength(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Signal, 1);
      SetLength(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Sollwert, 1);
      SetLength(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Tol1P, 1);
      SetLength(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Tol1N, 1);
      SetLength(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Tol2P, 1);
      SetLength(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Tol2N, 1);
      SetLength(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Stichproben, 1);
      SetLength(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Aktiv, 1);
      SetLength(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].LetzteAbweichung, 1);

      SetLength(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].LetzterGuterSchuss, 1);
      SetLength(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].LetzterSchlechterSchuss, 1);
      SetLength(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].ErsterSchlechterSchuss, 1);
      SetLength(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].ErsterGuterSchuss, 1);
      SetLength(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].MeldungAktiv, 1);
    end
    else
    begin
      SetLength(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Istwert,
        Length(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Istwert) + 1);
      SetLength(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].DBNr,
        Length(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].DBNr) + 1);
      SetLength(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].SignalNr,
        Length(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].SignalNr) + 1);
      SetLength(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Signal,
        Length(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Signal) + 1);
      SetLength(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Sollwert,
        Length(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Sollwert) + 1);
      SetLength(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Tol1P,
        Length(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Tol1P) + 1);
      SetLength(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Tol1N,
        Length(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Tol1N) + 1);
      SetLength(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Tol2P,
        Length(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Tol2P) + 1);
      SetLength(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Tol2N,
        Length(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Tol2N) + 1);
      SetLength(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Stichproben,
        Length(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Stichproben) + 1);
      SetLength(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Aktiv,
        Length(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Aktiv) + 1);
      SetLength(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].LetzteAbweichung,
        Length(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].LetzteAbweichung) + 1);

      SetLength(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].LetzterGuterSchuss,
        Length(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].LetzterGuterSchuss) + 1);

      SetLength(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].LetzterSchlechterSchuss,
        Length(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].LetzterSchlechterSchuss) + 1);

      SetLength(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].ErsterSchlechterSchuss,
        Length(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].ErsterSchlechterSchuss) + 1);

      SetLength(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].ErsterGuterSchuss,
        Length(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].ErsterGuterSchuss) + 1);

      SetLength(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].MeldungAktiv,
        Length(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].MeldungAktiv) + 1);

    end;
    SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].SignalNr[Length(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].SignalNr) - 1] :=
    Daten.qSuch.FieldByName('Signalnr').AsInteger;
    SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Signal[Length(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Signal) - 1] :=
    Daten.qSuch.FieldByName('Signal').AsString;
    SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].DBNr[Length(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].DBNr) - 1] :=
    Daten.qSuch.FieldByName('nr').AsInteger;
    SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Istwert[Length(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Istwert) - 1] := 0;
    SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Istwert[Length(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Sollwert) - 1] := 0;
    SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Istwert[Length(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Tol1P) - 1] := 0;
    SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Istwert[Length(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Tol1N) - 1] := 0;
    SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Istwert[Length(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Tol2P) - 1] := 0;
    SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Istwert[Length(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Tol2N) - 1] := 0;
    SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Istwert[Length(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Stichproben) - 1] :=
    0;
    SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Istwert[Length(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Aktiv) - 1] := 0;
    SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Istwert[Length(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].LetzteAbweichung) -
    1] := 0;

    SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Istwert[Length(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].LetzterGuterSchuss)
    -
      1] := 0;
    SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Istwert[Length(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].LetzterSchlechterSchuss) -
    1] := 0;
    SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Istwert[Length(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].ErsterSchlechterSchuss) -
    1] := 0;
    SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Istwert[Length(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].ErsterGuterSchuss) -
    1] := 0;
    SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].Istwert[Length(SPC_Signal[Daten.qSuch.FieldByName('Datenblock').AsInteger].MeldungAktiv) -
    1] := 0;
    Daten.qSuch.Next;
  end;
  //**************************************************************************
  // Stillstand für Auftragsblock erzeugen
  if AUFTRAG_BLOCK then
  begin
    SQL_Get(Daten.qSuch, 'SELECT COUNT(*) cnt FROM tpm_stillstaende WHERE stillstandnr = 6');
    if Daten.qSuch.FieldByName('cnt').AsInteger = 0 then
    begin
      SQLStr := 'INSERT INTO TPM_Stillstaende (StillstandNr, Stillstand, Gruppe,'
        + ' Geplant, Aktion, UEBERWACHUNGSZEIT, WS_Anzeige,USER_COLOR, blockstillstand)'
        + ' VALUES (' + IntToStr(6) + ''
        + ',''' + GetL('nicht überwacht')
        + ''',''' + IntToStr(2)
        + ''',''' + IntToStr(1)
        + ''',''' + IntToStr(0)
        + ''',''' + IntToStr(0)
        + ''',''' + IntToStr(0)
        + ''',''' + IntToStr(0)
        + ''',''' + IntToStr(1)
        + ''')';
      try
        SQL_Insert(Daten.qUpdate, SQLStr);
      except
      end;

      SQLStr := 'alter table TPM_Auswertung add Still_6 integer default 0';
      try
        SQL_Insert(Daten.qUpdate, SQLStr);
      except
      end;
      // SQLStr := 'alter table TPM_Auswertung add Count_6 integer default 0';
      // try
      //   SQL_Insert(Daten.qUpdate, SQLStr);
      // except
      // end;

      SQLStr := 'update TPM_AUSWERTUNG set Still_6 = 0';
      try
        SQL_Insert(Daten.qUpdate, SQLStr);
      except
      end;

      // SQLStr := 'update TPM_AUSWERTUNG set Count_6 = 0';
      // try
      //   SQL_Insert(Daten.qUpdate, SQLStr);
      // except
      // end;
    end;
  end;
  //********************* Ungeplanten Stillstandsgrund anlegen ***************

  SQLStr := 'SELECT stillstandnr FROM tpm_stillstaende WHERE system_id = ' + IntToStr(CSTILLNRRUESTENUNGEPLANT);
  Daten.qSuch.SQL.Text := SQLStr;
  Daten.qSuch.Open;
  if Daten.qSuch.IsEmpty then // Keiner gefunden, eintragen !!!
  begin
    Daten.qUpdate.SQL.Text := 'INSERT INTO tpm_stillstaende '
      + '(Stillstandnr, Stillstand, gruppe, geplant, aktion, system_id ) values '
      + '(tpm_stillstaendeid.nextval,''' + GetL('Rüsten ungepl.') + ''' , 1, 0, 0, '
      + IntToStr(CSTILLNRRUESTENUNGEPLANT) + ')';
    Daten.qUpdate.ExecSQL;

    Daten.qSuch.Close;
    Daten.qSuch.Open;

   {$IFDEF INCL_MSADO}
    Daten.qUpdate.SQL.Text := 'ALTER TABLE tpm_auswertung ADD STILL_'
      + IntToStr(Daten.qSuch.FieldByName('stillstandnr').AsInteger) + ' Integer, COUNT_'
      + IntToStr(Daten.qSuch.FieldByName('stillstandnr').AsInteger) + ' Integer';
   {$ELSE}
    Daten.qUpdate.SQL.Text := 'ALTER TABLE tpm_auswertung ADD (STILL_'
      + IntToStr(Daten.qSuch.FieldByName('stillstandnr').AsInteger) + ' Integer, COUNT_'
      + IntToStr(Daten.qSuch.FieldByName('stillstandnr').AsInteger) + ' Integer)';
   {$ENDIF}
    Daten.qUpdate.ExecSQL;
  end;
  RuestStillstandNrUngeplant := Daten.qSuch.FieldByName('stillstandnr').AsInteger;
  Daten.qSuch.Close;
  SQLStr := 'SELECT geplant FROM tpm_stillstaende WHERE system_id = ' + IntToStr(CSTILLNRRUESTENGEPLANT);
  Daten.qSuch.SQL.Text := SQLStr;
  Daten.qSuch.Open;
  if not Daten.qSuch.EOF then // Keiner gefunden, eintragen !!!
    RuestenIstGeplant := Daten.qSuch.FieldByName('geplant').AsInteger = 1;
  Daten.qSuch.Close;

  //**************************************************************************
  try
    Recalculation_Time := StrToTime(TCO_Setup.GetParamStr(Daten.qSuch, 'INCL_Recalculation_am'));
  except
    SchreibeMeldung('Error in INCL_Recalculation_am', 0);
    Recalculation_Time := 0;
  end;
  Recalculation_Next := Trunc(N_o_w) + Recalculation_Time;
  if Recalculation_Time < Frac(N_o_w) then
    Recalculation_Next := Recalculation_Next + 1;

  if Recalculation_Time > 0 then
    SchreibeMeldung('Next recalculation: ' + DateTimeToStr(Recalculation_Next), 0);

  Event_Schicht := CreateEvent(nil, True, False, nil);
  Event_Zusatz := CreateEvent(nil, True, False, nil);
  Event_SignalLog := CreateEvent(nil, True, False, nil);
  Event_DBBackup := CreateEvent(nil, True, False, nil);

  Thread_Schicht := nil;
  Thread_Zusatz := nil;
  Thread_Signallog := nil;
  Thread_DBBackup := nil;

  Create_Threads;

  Ini.Free;

  Daten.Conn := True;

  //**************************************************************************

//  S := 'delete from Stat_Recalc where Gestartet = 1 and Frei = 1';
//  SQL_Insert(Daten.qUpdate, S);

{$IFNDEF  AZURE}

{$ENDIF}

  Timer1.ENABLED := True;
  SchreibeMeldung(Module + '.Create finish... Version: ' + GetVersion(4), 0);
  Hochlauf := False;
  TimerBegin := N_o_w;
  TimerEnd := N_o_w;

end;


procedure TS7Main.Create_Threads;
var
  Ini: TIniFile;
  A: Integer;
begin
  Ini := TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'incl_' + DBUser + '.ini');

  if not Ini.ValueExists('Shift', 'Priority') then
    Ini.WriteInteger('Shift', 'Priority', 3);
  A := Ini.ReadInteger('Shift', 'Priority', 3);
  if Thread_Schicht = nil then
  begin
    Thread_Schicht := TThread_Schicht.Create(True);
    Thread_Schicht.Priority := tpNormal;
    case A of
      1: Thread_Schicht.Priority := tpIdle;
      2: Thread_Schicht.Priority := tpLowest;
      3: Thread_Schicht.Priority := tpLower;
      4: Thread_Schicht.Priority := tpNormal;
      5: Thread_Schicht.Priority := tpHigher;
      6: Thread_Schicht.Priority := tpHighest;
      7: Thread_Schicht.Priority := tpTimeCritical;
    end;

    Thread_Schicht.Resume;
  end;

  if Thread_DBBackup = nil then
  begin
    Thread_DBBackup := TThread_DBBackup.Create(True);
    Thread_DBBackup.Priority := tpNormal;
    Thread_DBBackup.Resume;
  end;

  ThreadBackupLast := N_o_w;
  ThreadBackupTimer := 60;

  if not Ini.ValueExists('Signallog', 'Priority') then
    Ini.WriteInteger('Signallog', 'Priority', 3);
  A := Ini.ReadInteger('Signallog', 'Priority', 3);

  if Thread_Signallog = nil then
  begin
    Thread_Signallog := TThread_Signallog.Create(True);
    Thread_Signallog.Priority := tpNormal;
    case A of
      1: Thread_Signallog.Priority := tpIdle;
      2: Thread_Signallog.Priority := tpLowest;
      3: Thread_Signallog.Priority := tpLower;
      4: Thread_Signallog.Priority := tpNormal;
      5: Thread_Signallog.Priority := tpHigher;
      6: Thread_Signallog.Priority := tpHighest;
      7: Thread_Signallog.Priority := tpTimeCritical;
    end;
    Thread_Signallog.Resume;

    if not Ini.ValueExists('Signallog', 'Timer') then
      Ini.WriteInteger('Signallog', 'Timer', 30);
    ThreadSignallogTimer := Ini.ReadInteger('Signallog', 'Timer', 30);
    ThreadSignallogLast := N_o_w;
  end;

  if Thread_Zusatz = nil then
  begin
    Thread_Zusatz := TThread_Zusatz.Create(True);
    Thread_Zusatz.Priority := tpNormal;
    case A of
      1: Thread_Zusatz.Priority := tpIdle;
      2: Thread_Zusatz.Priority := tpLowest;
      3: Thread_Zusatz.Priority := tpLower;
      4: Thread_Zusatz.Priority := tpNormal;
      5: Thread_Zusatz.Priority := tpHigher;
      6: Thread_Zusatz.Priority := tpHighest;
      7: Thread_Zusatz.Priority := tpTimeCritical;
    end;
    Thread_Zusatz.Resume;

    if not Ini.ValueExists('Addons', 'Timer') then
      Ini.WriteInteger('Addons', 'Timer', 600);
    ThreadZusatzTimer := Ini.ReadInteger('Addons', 'Timer', 600);
    ThreadZusatzLast := N_o_w;

    Ini.WriteString('Help', 'Prority_1', 'Idle');
    Ini.WriteString('Help', 'Prority_2', 'Lowest');
    Ini.WriteString('Help', 'Prority_3', 'Lower');
    Ini.WriteString('Help', 'Prority_4', 'Normal');
    Ini.WriteString('Help', 'Prority_5', 'Higher');
    Ini.WriteString('Help', 'Prority_6', 'Highest');
    Ini.WriteString('Help', 'Prority_7', 'TimeCritical');
  end;
end;

//***********************************************************

procedure TS7Main.In_SPSWerteDB;
var
  SQLStr: string;
  I: Integer;
  IMaschProgramm, IMaschStoerung: Smallint;
begin
  IMaschStoerung := 0;
  //Alle aktuellen SPS-Werte in Datenbank schreiben...
  //Jede Maschine in DB
  for I := 1 to Anzahl_Masch do
  begin
    if Includis[I].IstArchiviert then
      Continue;
      
    if MaschProgrammbetrieb[I].Istwert then
      IMaschProgramm := 1
    else
      IMaschProgramm := 0;

    if not SQLGetBool(Daten.qSuch, 'SPSWERTE', 'LizenzInt', IntToStr(I)) then
      SQLStr := 'INSERT INTO SPSWERTE (Nr,LizenzInt,MaschProgramm,MaschOrg,'
        + ' MaschStoerung, StueckGesamt, StueckAuftragGesamt, StueckAuftragSchicht, '
        + ' StueckSchicht, Betriebsstunden, Taktzeit, LaufzeitGes, LaufzeitSchicht, '
        + ' StueckPruefGesamt, StueckPruefAuftragGesamt, StueckPruefAuftragSchicht, '
        + ' StueckPruefSchicht,StueckPackGesamt,StueckPackAuftragGesamt,'
        + ' StueckPackAuftragSchicht, StueckPackSchicht)'
        + ' VALUES (SPSWERTEID.NextVal'
        + ',''' + IntToStr(I)
        + ''',''' + IntToStr(IMaschProgramm)
        + ''',''' + IntToStr(0)
        + ''',''' + IntToStr(IMaschStoerung)
        + ''',''' + IntToStr(StueckGesamt[I].Istwert)
        + ''',''' + IntToStr(StueckAuftragGesamt[I].Istwert)
        + ''',''' + IntToStr(StueckAuftragSchicht[I].Istwert)
        + ''',''' + IntToStr(StueckSchicht[I].Istwert)
        + ''',''' + IntToStr(Betriebsstunden[I].Istwert)
        + ''',''' + IntToStr(Taktzeit[I].Istwert)
        + ''',''' + IntToStr(LaufzeitGes[I].Istwert)
        + ''',''' + IntToStr(LaufzeitSchicht[I].Istwert)
        + ''',''' + IntToStr(StueckPruefGesamt[I].Istwert)
        + ''',''' + IntToStr(StueckPruefAuftragGesamt[I].Istwert)
        + ''',''' + IntToStr(StueckPruefAuftragSchicht[I].Istwert)
        + ''',''' + IntToStr(StueckPruefSchicht[I].Istwert)
        + ''',''' + IntToStr(StueckPackGesamt[I].Istwert)
        + ''',''' + IntToStr(StueckPackAuftragGesamt[I].Istwert)
        + ''',''' + IntToStr(StueckPackAuftragSchicht[I].Istwert)
        + ''',''' + IntToStr(StueckPackSchicht[I].Istwert)
        + ''')'
    else
      SQLStr := 'update SPSWERTE set '
        + 'MaschProgramm =   ''' + IntToStr(IMaschProgramm)
        //  + ''',MaschOrg =      ''' + IntToStr(0)
      + ''',MaschStoerung =      ''' + IntToStr(IMaschStoerung)
        + ''',StueckGesamt =      ''' + IntToStr(StueckGesamt[I].Istwert)
        + ''',StueckAuftragGesamt =      ''' + IntToStr(StueckAuftragGesamt[I].Istwert)
        + ''',StueckAuftragSchicht =      ''' + IntToStr(StueckAuftragSchicht[I].Istwert)
        + ''',StueckSchicht =      ''' + IntToStr(StueckSchicht[I].Istwert)
        + ''',Betriebsstunden =      ''' + IntToStr(Betriebsstunden[I].Istwert)
        + ''',Taktzeit =      ''' + IntToStr(Taktzeit[I].Istwert)
        + ''',LaufzeitGes =      ''' + IntToStr(LaufzeitGes[I].Istwert)
        + ''',LaufzeitSchicht =      ''' + IntToStr(LaufzeitSchicht[I].Istwert)
        + ''',StueckPruefGesamt =      ''' + IntToStr(StueckPruefGesamt[I].Istwert)
        + ''',StueckPruefAuftragGesamt =      ''' + IntToStr(StueckPruefAuftragGesamt[I].Istwert)
        + ''',StueckPruefAuftragSchicht =      ''' + IntToStr(StueckPruefAuftragSchicht[I].Istwert)
        + ''',StueckPruefSchicht =      ''' + IntToStr(StueckPruefSchicht[I].Istwert)
        + ''',StueckPackGesamt =      ''' + IntToStr(StueckPackGesamt[I].Istwert)
        + ''',StueckPackAuftragGesamt =      ''' + IntToStr(StueckPackAuftragGesamt[I].Istwert)
        + ''',StueckPackAuftragSchicht =      ''' + IntToStr(StueckPackAuftragSchicht[I].Istwert)
        + ''',StueckPackSchicht =      ''' + IntToStr(StueckPackSchicht[I].Istwert)
        + ''' where LizenzInt = ' + IntToStr(I);

    SQL_Insert(Daten.qUpdate, SQLStr);
  end;
end;
//*********************************************************

destructor TS7Main.Destroy;
var
  I: Integer;
begin

  INC_Meldung.Abmelden;
  INC_Meldung.Destroy;

  Ende := True;
  TPM.Destroy;
  S7_Auftrag.Destroy;
  cSPC.Destroy;

  Includis := nil;
  MaschZustand := nil;

  for I := 1 to Anzahl_Masch do
  begin
    IndivStillstand[I].Istwert := nil;
    IndivStillstand[I].SignalNr := nil;
    IndivStillstand[I].DBNr := nil;
    IndivStillstand[I].Stillstand := nil;
    IndivStillstand[I].Istwert_alt := nil;

    FehlerNr[I].Istwert := nil;
    FehlerNr[I].SignalNr := nil;
    FehlerNr[I].DBNr := nil;
    FehlerNr[I].Istwert_alt := nil;

    SPC_Signal[I].Istwert := nil;
    SPC_Signal[I].SignalNr := nil;
    SPC_Signal[I].Signal := nil;
    SPC_Signal[I].DBNr := nil;

    SPC_Signal[I].Sollwert := nil;
    SPC_Signal[I].Tol1P := nil;
    SPC_Signal[I].Tol1N := nil;
    SPC_Signal[I].Tol2P := nil;
    SPC_Signal[I].Tol2N := nil;
    SPC_Signal[I].Stichproben := nil;
    SPC_Signal[I].Aktiv := nil;
    SPC_Signal[I].LetzteAbweichung := nil;

    SPC_Signal[I].LetzterGuterSchuss := nil;
    SPC_Signal[I].LetzterSchlechterSchuss := nil;
    SPC_Signal[I].ErsterSchlechterSchuss := nil;
    SPC_Signal[I].ErsterGuterSchuss := nil;
    SPC_Signal[I].MeldungAktiv := nil;

  end;

  Stillstand := nil;
  if Thread_Schicht <> nil then
  begin
    Thread_Schicht.Terminate;
    PulseEvent(Event_Schicht);
    Thread_Schicht.WaitFor;
    FreeAndNil(Thread_Schicht);
  end;

  if Thread_Zusatz <> nil then
  begin
    Thread_Zusatz.Terminate;
    PulseEvent(Event_Zusatz);
    Thread_Zusatz.WaitFor;
    FreeAndNil(Thread_Zusatz);
  end;

  if Thread_Signallog <> nil then
  begin
    Thread_Signallog.Terminate;
    PulseEvent(Event_SignalLog);
    Thread_Signallog.WaitFor;
    FreeAndNil(Thread_Signallog);
  end;

  if Thread_DBBackup <> nil then
  begin
    Thread_DBBackup.Terminate;
    PulseEvent(Event_DBBackup);
    Thread_DBBackup.WaitFor;
    FreeAndNil(Thread_DBBackup);
  end;

  MainServiceAliveTimer.Free;
end;

procedure TS7Main.DatenLesen2;
var
  istwert : Integer;
  istwertstr : string;
  maschnr : integer;
  nr : integer;
  signalart : integer;
  i, j, k, l : Integer;
  siglist : TSignalMaschineList;
  sigitem : TSignalMaschineItem;
  s, s2 : string;
begin


// Init der Werte die evtl. nicht gelesen werden weil Signal nicht vorhanden
  Barcode_Gelesen.Istwert := false;
  Barcode_Gelesen_2.Istwert := false;
  Barcode_Gelesen_3.Istwert := false;

  siglist := TSignalMaschineList.Create;
  try
    SQLStr := 'SELECT signal_maschine.nr, signal_maschine.istwert istwert, signal_maschine.maschnr maschnr, signale.signalart'
      + ' FROM signal_maschine '
      + ' LEFT JOIN signale ON signale.signalnr=signal_maschine.signalnr ';
    SQL_Get(Daten.qIstwert, SQLStr);

    while not Daten.qIstwert.Eof do
    begin
      sigitem := TSignalMaschineItem.Create;
      try
        sigitem.Istwert :=  Daten.qIstwert.FieldByName('Istwert').AsInteger;
      except
        sigitem.Istwert := 0;
      end;
      sigitem.IstwertString := Daten.qIstwert.FieldByName('Istwert').AsString;
      sigitem.maschnr := Daten.qIstwert.FieldByName('Maschnr').AsInteger;
      sigitem.nr := Daten.qIstwert.FieldByName('nr').AsInteger;
      sigitem.signalart := Daten.qIstwert.FieldByName('signalart').AsInteger;

      siglist.Add(sigitem);
      Daten.qIstwert.Next;
    end;

  except
  end;

  if Auftragstart_Barcode then
  begin
    Barcode_Gelesen.Istwert := siglist.GetBoolByNr(Barcode_Gelesen.DBNr);
    Barcode_Gelesen_2.Istwert := siglist.GetBoolByNr(Barcode_Gelesen_2.DBNr);
    Barcode_Gelesen_3.Istwert := siglist.GetBoolByNr(Barcode_Gelesen_3.DBNr);

    if Barcode_Gelesen.Istwert then
    begin
      for I := 1 to MAX_BARCODE do
      begin
        sigitem := siglist.getNr(Barcode[I].DBNr);
        if (sigitem <> nil) then
          Barcode[I].Istwert := sigitem.Istwert;
      end;
    end;

    if Barcode_Gelesen_2.Istwert then
    begin
      for I := 1 to MAX_BARCODE do
      begin
        sigitem := siglist.getNr(Barcode_2[I].DBNr);
        if (sigitem <> nil) then
          Barcode_2[I].Istwert := sigitem.Istwert;
      end;
    end;

    if Barcode_Gelesen_3.Istwert then
    begin
      for I := 1 to MAX_BARCODE do
      begin
        sigitem := siglist.getNr(Barcode_3[I].DBNr);
        if (sigitem <> nil) then
          Barcode_3[I].Istwert := sigitem.Istwert;
      end;
    end;

    AuftragStart1.Istwert := siglist.GetIstwertByNr(AuftragStart1.DBNr);
    AuftragStart2.Istwert := siglist.GetIstwertByNr(AuftragStart2.DBNr);
    AuftragStart3.Istwert := siglist.GetIstwertByNr(AuftragStart3.DBNr);

    Terminal_Maschine.Istwert := siglist.GetIstwertByNr(Terminal_Maschine.DBNr);
    Reparatur_Start_Ende.Istwert := siglist.GetIstwertByNr(Reparatur_Start_Ende.DBNr);
    Terminal_Eingabe.Istwert := siglist.GetBoolByNr(Terminal_Eingabe.DBNr);
  end;

  for I := 1 to Anzahl_Masch do
  begin
    if Includis[I].IstArchiviert then
      Continue;
      
    StueckAuftragGesamt[I].Istwert := siglist.GetIstwertByNr(StueckAuftragGesamt[I].DBNr);

    sigitem := siglist.GetNr(StueckGesamt[I].DBNr);
    if sigitem <> nil then
      StueckGesamt[I].Istwert := sigitem.Istwert
    else
      StueckGesamt[I].Istwert := StueckAuftragGesamt[I].Istwert;

(*    Fällt erstmal raus. Alte extrem inperformante Funktionen ML 29.02.2016
   Includis[I].StueckGeaendert := CheckManuelleStueckBuchung(I);

    if StueckAuftragAlt[I] = 0 then
      StueckAuftragAlt[I] := GetStueckAuftragAlt(I);

    if (StueckAuftragGesamt[I].Istwert < StueckAuftragAlt[I]) and not Includis[I].StueckGeaendert then
      StueckAuftragAlt[I] := 0
    else
      StueckAuftragAlt[I] := StueckAuftragGesamt[I].Istwert;

    Diff_Stueck[I] := StueckAuftragGesamt[I].Istwert - StueckAuftragAlt[I];
    if Diff_Stueck[I] < 0 then
      Diff_Stueck[I] := 0;
*)

    StueckAuftragSchicht[I].Istwert := siglist.GetIstwertByNr(StueckAuftragSchicht[I].DBNr);
    StueckSchicht[I].Istwert := siglist.GetIstwertByNr(StueckSchicht[I].DBNr);
    Betriebsstunden[I].Istwert := siglist.GetIstwertByNr(Betriebsstunden[I].DBNr);
    Taktzeit[I].Istwert := siglist.GetIstwertByNr(Taktzeit[I].DBNr);
    LaufzeitGes[I].Istwert := siglist.GetIstwertByNr(LaufzeitGes[I].DBNr);
    LaufzeitSchicht[I].Istwert := siglist.GetIstwertByNr(LaufzeitSchicht[I].DBNr);
    StueckPruefGesamt[I].Istwert := siglist.GetIstwertByNr(StueckPruefGesamt[I].DBNr);
    StueckPruefAuftragGesamt[I].Istwert := siglist.GetIstwertByNr(StueckPruefAuftragGesamt[I].DBNr);
    StueckPruefAuftragSchicht[I].Istwert := siglist.GetIstwertByNr(StueckPruefAuftragSchicht[I].DBNr);
    StueckPruefSchicht[I].Istwert := siglist.GetIstwertByNr(StueckPruefSchicht[I].DBNr);
    StueckPackGesamt[I].Istwert := siglist.GetIstwertByNr(StueckPackGesamt[I].DBNr);
    StueckPackAuftragGesamt[I].Istwert := siglist.GetIstwertByNr(StueckPackAuftragGesamt[I].DBNr);
    StueckPackAuftragSchicht[I].Istwert := siglist.GetIstwertByNr(StueckPackAuftragSchicht[I].DBNr);
    StueckPackSchicht[I].Istwert := siglist.GetIstwertByNr(StueckPackSchicht[I].DBNr);
    AUTOAUSSCHUSS_AUFTRAG[I].Istwert := siglist.GetIstwertByNr(AUTOAUSSCHUSS_AUFTRAG[I].DBNr);
    AUTOAUSSCHUSS_SCHICHT[I].Istwert := siglist.GetIstwertByNr(AUTOAUSSCHUSS_SCHICHT[I].DBNr);
    AUTOAUSSCHUSS_AUFTRAGSchicht[I].Istwert := siglist.GetIstwertByNr(AUTOAUSSCHUSS_AUFTRAGSchicht[I].DBNr);
    Maschinen_Zustand[I].Istwert := siglist.GetIstwertByNr(Maschinen_Zustand[I].DBNr);
    Terminal_AuftragNr[I].Istwert :=  siglist.GetIstwertByNr(Terminal_AuftragNr[I].DBNr);
    Terminal_AuftragNr_ASCII[I].Istwert := siglist.GetIstwertByNr(Terminal_AuftragNr_ASCII[I].DBNr);
    BCD[I].Istwert := siglist.GetIstwertByNr(BCD[I].DBNr);
    StillstandNr_SPS[I].Istwert := siglist.GetIstwertByNr(StillstandNr_SPS[I].DBNr);

    Job_Stueckzahl[I].Istwert := siglist.GetIstwertByNr(Job_Stueckzahl[I].DBNr);

    BCD_Read[I].Istwert := siglist.GetBoolByNr(BCD_Read[I].DBNr);
    HandAuto[I].Istwert := siglist.GetBoolByNr(HandAuto[I].DBNr);
    MaschProgrammbetrieb[I].Istwert := siglist.GetBoolByNr(MaschProgrammbetrieb[I].DBNr);

(* Entfernt. Kunde existiert so nicht mehr und hat sich wenn an die neuen Geplogenheiten zu halten ML 29.02.2016
    if not Metall then
    begin //CWK Grasso
      if Daten.qIstwert.Locate('Nr', MaschProgrammbetrieb[I].DBNr, []) then
        if Daten.qIstwert.FieldByName('Istwert').AsInteger = 1 then
          MaschProgrammbetrieb[I].Istwert := True
        else
          MaschProgrammbetrieb[I].Istwert := False;
    end;

    if Metall then
    begin //CWK Grasso
      if (I <> 1) and (I <> 2) and (I <> 3) and (I <> 8) then
      begin
        if Daten.qIstwert.Locate('Nr', MaschProgrammbetrieb[I].DBNr, []) then
          if Daten.qIstwert.FieldByName('Istwert').AsInteger = 1 then
            MaschProgrammbetrieb[I].Istwert := True
          else
            MaschProgrammbetrieb[I].Istwert := False;
      end;
    end;
*)
    Auftrag_Freigabe[I].Istwert := siglist.GetBoolByNr(Auftrag_Freigabe[I].DBNr);
    Terminal_Menge_Gebucht[I].Istwert := siglist.GetBoolByNr(Terminal_Menge_Gebucht[I].DBNr);
    Terminal_Einheit[I].Istwert := siglist.GetIstwertByNr(Terminal_Einheit[I].DBNr);
    Terminal_Stillstand_Gebucht[I].Istwert := siglist.GetBoolByNr(Terminal_Stillstand_Gebucht[I].DBNr);
    Terminal_Auftrag_Beendet[I].Istwert := siglist.GetBoolByNr(Terminal_Auftrag_Beendet[I].DBNr);
    Terminal_Auftrag_Unterbrochen[I].Istwert := siglist.GetBoolByNr(Terminal_Auftrag_Unterbrochen[I].DBNr);
    MaschWarmtrennen[I].Istwert := siglist.GetBoolByNr(MaschWarmtrennen[I].DBNr);
    Vorrichtung[I].Istwert := siglist.GetBoolByNr(Vorrichtung[I].DBNr);

    SpannzeitSumme[I].Istwert := siglist.GetIstwertByNr(SpannzeitSumme[I].DBNr);
    SpannzeitAktuell[I].Istwert := trunc(siglist.GetIstwertByNr(SpannzeitAktuell[I].DBNr) / 10);;
    SPSKavitaet[I].Istwert := siglist.GetIstwertByNr(SPSKavitaet[I].DBNr);
    if SPSKavitaet[I].Istwert < 0 then
      SPSKavitaet[I].Istwert := 0;

    Heizungsdauer[I].Istwert := siglist.GetIstwertByNr(Heizungsdauer[I].DBNr);
    Terminal_StoerKommtGeht[I].Istwert := siglist.GetIstwertByNr(Terminal_StoerKommtGeht[I].DBNr);
    Terminal_Stoer_Nr[I].Istwert := siglist.GetIstwertByNr(Terminal_Stoer_Nr[I].DBNr);
    Terminal_Still_Stoer[I].Istwert := siglist.GetIstwertByNr(Terminal_Still_Stoer[I].DBNr);
    Terminal_Etikett[I].Istwert := siglist.GetIstwertByNr(Terminal_Etikett[I].DBNr);

    sigitem := siglist.GetByMaschNrSignalart(i, 121);
    Extruderan[I] := 0;
    if sigitem <> nil then
      Extruderan[i] := sigitem.Istwert;

    //************************************************************
    //********************* METALL **********************************
    //************************************************************

    if Metall then
    begin
      sigitem := siglist.GetNr(Programm_Nr[I].DBNr);
      if sigitem <> nil then
      begin
        s := sigitem.IstwertString;
        s2 := '';
        for k := 1 to length(s) do
        begin
          try
            s2 := s2 + IntToStr(StrToInt(s[k]));
            l := StrToInt(s2);
          except
          end;

        end;
        Programm_Nr[I].Istwert := l;//Daten.qIstwert.FieldByName('Istwert').AsInteger;
      end;

     Programm_Start[I].Istwert := siglist.GetBoolByNr(Programm_Start[I].DBNr);
     Programm_Ende[I].Istwert := siglist.GetBoolByNr(Programm_Ende[I].DBNr);
    end;

    //********************* SPC **********************************

    if SPC then
    begin
      if StueckAuftragGesamt[I].Istwert <> SPC_Save[I].Stueckzahl then
      begin
        SPC_Save[I].SPC := True;
        SPC_Save[I].Stueckzahl := StueckAuftragGesamt[I].Istwert;

        if SPC_Signal[I].Istwert <> nil then
          for J := 0 to Length(SPC_Signal[I].Istwert) - 1 do
              SPC_Signal[I].Istwert[J] := siglist.GetIstwertByNr(SPC_Signal[I].DBNr[J])/100;
      end
      else
        SPC_Save[I].SPC := False;
    end;

    if SPC_Stich then
    begin
      if SPC_Signal[I].Istwert <> nil then
        for J := 0 to Length(SPC_Signal[I].Istwert) - 1 do
          SPC_Signal[I].Istwert[J] := siglist.GetIstwertByNr(SPC_Signal[I].DBNr[J])/100;;
    end;
  end;

  if Metall then
    DatenLesen_Metall;

  siglist.Destroy;
end;

procedure TS7Main.DatenLesen;
var
  SQLStr, s, s2: string;
  I, J, k, l: Integer;
begin
  DatenLesen2; // Sprung auf die neue Funktion
  exit;

  SQLStr := 'select nr, istwert from signal_Maschine';
  SQL_Get(Daten.qIstwert, SQLStr);

  if Auftragstart_Barcode then
  begin
    if Daten.qIstwert.Locate('Nr', Barcode_Gelesen.DBNr, []) then
    begin
      if Daten.qIstwert.FieldByName('Istwert').AsInteger = 0 then
        Barcode_Gelesen.Istwert := False
      else
        Barcode_Gelesen.Istwert := True;
    end
    else
      Barcode_Gelesen.Istwert := False;

    if Daten.qIstwert.Locate('Nr', Barcode_Gelesen_2.DBNr, []) then
    begin
      if Daten.qIstwert.FieldByName('Istwert').AsInteger = 0 then
        Barcode_Gelesen_2.Istwert := False
      else
        Barcode_Gelesen_2.Istwert := True;
    end
    else
      Barcode_Gelesen_2.Istwert := False;

    if Daten.qIstwert.Locate('Nr', Barcode_Gelesen_3.DBNr, []) then
    begin
      if Daten.qIstwert.FieldByName('Istwert').AsInteger = 0 then
        Barcode_Gelesen_3.Istwert := False
      else
        Barcode_Gelesen_3.Istwert := True;
    end
    else
      Barcode_Gelesen_3.Istwert := False;

    if Barcode_Gelesen.Istwert then
    begin
      for I := 1 to MAX_BARCODE do
      begin
        if Daten.qIstwert.Locate('Nr', Barcode[I].DBNr, []) then
          Barcode[I].Istwert := Daten.qIstwert.FieldByName('Istwert').AsInteger;
      end;
    end;

    if Barcode_Gelesen_2.Istwert then
    begin
      for I := 1 to MAX_BARCODE do
      begin
        if Daten.qIstwert.Locate('Nr', Barcode_2[I].DBNr, []) then
          Barcode_2[I].Istwert := Daten.qIstwert.FieldByName('Istwert').AsInteger;
      end;
    end;

    if Barcode_Gelesen_3.Istwert then
    begin
      for I := 1 to MAX_BARCODE do
      begin
        if Daten.qIstwert.Locate('Nr', Barcode_3[I].DBNr, []) then
          Barcode_3[I].Istwert := Daten.qIstwert.FieldByName('Istwert').AsInteger;
      end;
    end;

    if Daten.qIstwert.Locate('Nr', AuftragStart1.DBNr, []) then
      AuftragStart1.Istwert := Daten.qIstwert.FieldByName('Istwert').AsInteger;

    if Daten.qIstwert.Locate('Nr', AuftragStart2.DBNr, []) then
      AuftragStart2.Istwert := Daten.qIstwert.FieldByName('Istwert').AsInteger;

    if Daten.qIstwert.Locate('Nr', AuftragStart3.DBNr, []) then
      AuftragStart3.Istwert := Daten.qIstwert.FieldByName('Istwert').AsInteger;

    if Daten.qIstwert.Locate('Nr', Terminal_Maschine.DBNr, []) then
      Terminal_Maschine.Istwert := Daten.qIstwert.FieldByName('Istwert').AsInteger;

    if Daten.qIstwert.Locate('Nr', Reparatur_Start_Ende.DBNr, []) then
      Reparatur_Start_Ende.Istwert := Daten.qIstwert.FieldByName('Istwert').AsInteger;

    if Daten.qIstwert.Locate('Nr', Terminal_Eingabe.DBNr, []) then
    begin
      if Daten.qIstwert.FieldByName('Istwert').AsInteger = 0 then
        Terminal_Eingabe.Istwert := False
      else
        Terminal_Eingabe.Istwert := True;
    end
    else
      Terminal_Eingabe.Istwert := False;
  end;

  for I := 1 to Anzahl_Masch do
  begin
    if Includis[I].IstArchiviert then
      Continue;
    if Daten.qIstwert.Locate('Nr', StueckGesamt[I].DBNr, []) then
      StueckGesamt[I].Istwert := Daten.qIstwert.FieldByName('Istwert').AsInteger
    else // Wenn kein Signal, dann Stueckzahl aus PDE div Kopfgroesse
    begin
      if SQL2GetBool(Daten.qSuch4, 'PDE', 'lizenz', StueckGesamt[I].Maschine, 'stat', '0') then
      begin
        try
          StueckGesamt[I].Istwert := StrToInt(Daten.qSuch4.FieldByName('istwert').AsString) div
            StrToInt(Daten.qSuch4.FieldByName('kopfgroesse').AsString);
        except
          StueckGesamt[I].Istwert := 0;
        end;
      end;
    end;

    Includis[I].StueckGeaendert := CheckManuelleStueckBuchung(I);

    if StueckAuftragAlt[I] = 0 then
      StueckAuftragAlt[I] := GetStueckAuftragAlt(I);

    if (StueckAuftragGesamt[I].Istwert < StueckAuftragAlt[I]) and not Includis[I].StueckGeaendert then
      StueckAuftragAlt[I] := 0
    else
      StueckAuftragAlt[I] := StueckAuftragGesamt[I].Istwert;

    if Daten.qIstwert.Locate('Nr', StueckAuftragGesamt[I].DBNr, []) then
      StueckAuftragGesamt[I].Istwert := Daten.qIstwert.FieldByName('Istwert').AsInteger
    else // Wenn kein Signal, dann Stueckzahl aus PDE div Kopfgroesse
      StueckAuftragGesamt[I].Istwert := StueckGesamt[I].Istwert;

    Diff_Stueck[I] := StueckAuftragGesamt[I].Istwert - StueckAuftragAlt[I];
    if Diff_Stueck[I] < 0 then
      Diff_Stueck[I] := 0;

    if Daten.qIstwert.Locate('Nr', StueckAuftragSchicht[I].DBNr, []) then
      StueckAuftragSchicht[I].Istwert := Daten.qIstwert.FieldByName('Istwert').AsInteger;

    if Daten.qIstwert.Locate('Nr', StueckSchicht[I].DBNr, []) then
      StueckSchicht[I].Istwert := Daten.qIstwert.FieldByName('Istwert').AsInteger;

    if Daten.qIstwert.Locate('Nr', Betriebsstunden[I].DBNr, []) then
      Betriebsstunden[I].Istwert := Daten.qIstwert.FieldByName('Istwert').AsInteger;

    if Daten.qIstwert.Locate('Nr', Taktzeit[I].DBNr, []) then
      Taktzeit[I].Istwert := Daten.qIstwert.FieldByName('Istwert').AsInteger;

    if Daten.qIstwert.Locate('Nr', LaufzeitGes[I].DBNr, []) then
      LaufzeitGes[I].Istwert := Daten.qIstwert.FieldByName('Istwert').AsInteger;

    if Daten.qIstwert.Locate('Nr', LaufzeitSchicht[I].DBNr, []) then
      LaufzeitSchicht[I].Istwert := Daten.qIstwert.FieldByName('Istwert').AsInteger;

    if Daten.qIstwert.Locate('Nr', StueckPruefGesamt[I].DBNr, []) then
      StueckPruefGesamt[I].Istwert := Daten.qIstwert.FieldByName('Istwert').AsInteger;

    if Daten.qIstwert.Locate('Nr', StueckPruefAuftragGesamt[I].DBNr, []) then
      StueckPruefAuftragGesamt[I].Istwert := Daten.qIstwert.FieldByName('Istwert').AsInteger;

    if Daten.qIstwert.Locate('Nr', StueckPruefAuftragSchicht[I].DBNr, []) then
      StueckPruefAuftragSchicht[I].Istwert := Daten.qIstwert.FieldByName('Istwert').AsInteger;

    if Daten.qIstwert.Locate('Nr', StueckPruefSchicht[I].DBNr, []) then
      StueckPruefSchicht[I].Istwert := Daten.qIstwert.FieldByName('Istwert').AsInteger;

    if Daten.qIstwert.Locate('Nr', StueckPackGesamt[I].DBNr, []) then
      StueckPackGesamt[I].Istwert := Daten.qIstwert.FieldByName('Istwert').AsInteger;

    if Daten.qIstwert.Locate('Nr', StueckPackAuftragGesamt[I].DBNr, []) then
      StueckPackAuftragGesamt[I].Istwert := Daten.qIstwert.FieldByName('Istwert').AsInteger;

    if Daten.qIstwert.Locate('Nr', StueckPackAuftragSchicht[I].DBNr, []) then
      StueckPackAuftragSchicht[I].Istwert := Daten.qIstwert.FieldByName('Istwert').AsInteger;

    if Daten.qIstwert.Locate('Nr', StueckPackSchicht[I].DBNr, []) then
      StueckPackSchicht[I].Istwert := Daten.qIstwert.FieldByName('Istwert').AsInteger;

    if Daten.qIstwert.Locate('Nr', AUTOAUSSCHUSS_AUFTRAG[I].DBNr, []) then
      AUTOAUSSCHUSS_AUFTRAG[I].Istwert := Daten.qIstwert.FieldByName('Istwert').AsInteger;

    if Daten.qIstwert.Locate('Nr', AUTOAUSSCHUSS_SCHICHT[I].DBNr, []) then
      AUTOAUSSCHUSS_SCHICHT[I].Istwert := Daten.qIstwert.FieldByName('Istwert').AsInteger;

    if Daten.qIstwert.Locate('Nr', AUTOAUSSCHUSS_AUFTRAGSchicht[I].DBNr, []) then
      AUTOAUSSCHUSS_AUFTRAGSchicht[I].Istwert := Daten.qIstwert.FieldByName('Istwert').AsInteger;

    if Daten.qIstwert.Locate('Nr', Maschinen_Zustand[I].DBNr, []) then
      Maschinen_Zustand[I].Istwert := Daten.qIstwert.FieldByName('Istwert').AsInteger;

    if Daten.qIstwert.Locate('Nr', Terminal_AuftragNr[I].DBNr, []) then
      Terminal_AuftragNr[I].Istwert := Daten.qIstwert.FieldByName('Istwert').AsInteger;

    if Daten.qIstwert.Locate('Nr', Terminal_AuftragNr_ASCII[I].DBNr, []) then
      Terminal_AuftragNr_ASCII[I].Istwert := Daten.qIstwert.FieldByName('Istwert').AsInteger;

    if Daten.qIstwert.Locate('Nr', BCD[I].DBNr, []) then
      BCD[I].Istwert := Daten.qIstwert.FieldByName('Istwert').AsInteger;

    if Daten.qIstwert.Locate('Nr', StillstandNr_SPS[I].DBNr, []) then
      StillstandNr_SPS[I].Istwert := Daten.qIstwert.FieldByName('Istwert').AsInteger
    else
      StillstandNr_SPS[I].Istwert := 0;

    if Daten.qIstwert.Locate('Nr', Job_Stueckzahl[I].DBNr, []) then
      Job_Stueckzahl[I].Istwert := Daten.qIstwert.FieldByName('Istwert').AsInteger
    else
      Job_Stueckzahl[I].Istwert := 0;

    if Daten.qIstwert.Locate('Nr', BCD_Read[I].DBNr, []) then
      if Daten.qIstwert.FieldByName('Istwert').AsInteger = 1 then
        BCD_Read[I].Istwert := True
      else
        BCD_Read[I].Istwert := False;

    if Daten.qIstwert.Locate('Nr', HandAuto[I].DBNr, []) then
      if Daten.qIstwert.FieldByName('Istwert').AsInteger = 1 then
        HandAuto[I].Istwert := True
      else
        HandAuto[I].Istwert := False;

    if not Metall then
    begin //CWK Grasso
      if Daten.qIstwert.Locate('Nr', MaschProgrammbetrieb[I].DBNr, []) then
        if Daten.qIstwert.FieldByName('Istwert').AsInteger = 1 then
          MaschProgrammbetrieb[I].Istwert := True
        else
          MaschProgrammbetrieb[I].Istwert := False;
    end;

    if Metall then
    begin //CWK Grasso
      if (I <> 1) and (I <> 2) and (I <> 3) and (I <> 8) then
      begin
        if Daten.qIstwert.Locate('Nr', MaschProgrammbetrieb[I].DBNr, []) then
          if Daten.qIstwert.FieldByName('Istwert').AsInteger = 1 then
            MaschProgrammbetrieb[I].Istwert := True
          else
            MaschProgrammbetrieb[I].Istwert := False;
      end;
    end;

    if Daten.qIstwert.Locate('Nr', Auftrag_Freigabe[I].DBNr, []) then
      if Daten.qIstwert.FieldByName('Istwert').AsInteger = 1 then
        Auftrag_Freigabe[I].Istwert := True
      else
        Auftrag_Freigabe[I].Istwert := False;

    if Daten.qIstwert.Locate('Nr', Terminal_Menge_Gebucht[I].DBNr, []) then
    begin
      if Daten.qIstwert.FieldByName('Istwert').AsInteger = 0 then
        Terminal_Menge_Gebucht[I].Istwert := False
      else
        Terminal_Menge_Gebucht[I].Istwert := True;
    end
    else
      Terminal_Menge_Gebucht[I].Istwert := False;

    if Daten.qIstwert.Locate('Nr', Terminal_Einheit[I].DBNr, []) then
      Terminal_Einheit[I].Istwert := Daten.qIstwert.FieldByName('Istwert').AsInteger;

    if Daten.qIstwert.Locate('Nr', Terminal_Stillstand_Gebucht[I].DBNr, []) then
    begin
      if Daten.qIstwert.FieldByName('Istwert').AsInteger = 0 then
        Terminal_Stillstand_Gebucht[I].Istwert := False
      else
        Terminal_Stillstand_Gebucht[I].Istwert := True;
    end
    else
      Terminal_Stillstand_Gebucht[I].Istwert := False;

    if Daten.qIstwert.Locate('Nr', Terminal_Auftrag_Beendet[I].DBNr, []) then
    begin
      if Daten.qIstwert.FieldByName('Istwert').AsInteger = 0 then
        Terminal_Auftrag_Beendet[I].Istwert := False
      else
        Terminal_Auftrag_Beendet[I].Istwert := True;
    end
    else
      Terminal_Auftrag_Beendet[I].Istwert := False;

    if Daten.qIstwert.Locate('Nr', Terminal_Auftrag_Unterbrochen[I].DBNr, []) then
    begin
      if Daten.qIstwert.FieldByName('Istwert').AsInteger = 0 then
        Terminal_Auftrag_Unterbrochen[I].Istwert := False
      else
        Terminal_Auftrag_Unterbrochen[I].Istwert := True;
    end
    else
      Terminal_Auftrag_Unterbrochen[I].Istwert := False;

    if Daten.qIstwert.Locate('Nr', MaschWarmtrennen[I].DBNr, []) then
    begin
      if Daten.qIstwert.FieldByName('Istwert').AsInteger = 0 then
        MaschWarmtrennen[I].Istwert := False
      else
        MaschWarmtrennen[I].Istwert := True;
    end
    else
      MaschWarmtrennen[I].Istwert := False;

    if Daten.qIstwert.Locate('Nr', Vorrichtung[I].DBNr, []) then
    begin
      if Daten.qIstwert.FieldByName('Istwert').AsInteger = 0 then
        Vorrichtung[I].Istwert := False
      else
        Vorrichtung[I].Istwert := True;
    end
    else
      Vorrichtung[I].Istwert := False;

    if Daten.qIstwert.Locate('Nr', SpannzeitSumme[I].DBNr, []) then
      SpannzeitSumme[I].Istwert := Daten.qIstwert.FieldByName('Istwert').AsInteger;

    if Daten.qIstwert.Locate('Nr', SpannzeitAktuell[I].DBNr, []) then
    begin
      SpannzeitAktuell[I].Istwert := Trunc(Daten.qIstwert.FieldByName('Istwert').AsInteger / 10);
      if SpannzeitAktuell[I].Istwert < 100 then
        SpannzeitAktuell[I].Istwert := 0;
    end;

    if Daten.qIstwert.Locate('Nr', SPSKavitaet[I].DBNr, []) then
    begin
      SPSKavitaet[I].Istwert := Daten.qIstwert.FieldByName('Istwert').AsInteger;
      if SPSKavitaet[I].Istwert < 0 then
        SPSKavitaet[I].Istwert := 0;
    end;


    if Daten.qIstwert.Locate('Nr', Heizungsdauer[I].DBNr, []) then
      Heizungsdauer[I].Istwert := Daten.qIstwert.FieldByName('Istwert').AsInteger;

    if Daten.qIstwert.Locate('Nr', Terminal_StoerKommtGeht[I].DBNr, []) then
      Terminal_StoerKommtGeht[I].Istwert := Daten.qIstwert.FieldByName('Istwert').AsInteger;

    if Daten.qIstwert.Locate('Nr', Terminal_Stoer_Nr[I].DBNr, []) then
      Terminal_Stoer_Nr[I].Istwert := Daten.qIstwert.FieldByName('Istwert').AsInteger;

    if Daten.qIstwert.Locate('Nr', Terminal_Still_Stoer[I].DBNr, []) then
      Terminal_Still_Stoer[I].Istwert := Daten.qIstwert.FieldByName('Istwert').AsInteger;

    if Daten.qIstwert.Locate('Nr', Terminal_Etikett[I].DBNr, []) then
      Terminal_Etikett[I].Istwert := Daten.qIstwert.FieldByName('Istwert').AsInteger;

    //************************************************************
    //********************* METALL **********************************
    //************************************************************

    if Metall then
    begin
      if Daten.qIstwert.Locate('Nr', Programm_Nr[I].DBNr, []) then
      begin
        s := Daten.qIstwert.FieldByName('Istwert').AsString;
        s2 := '';
        for k := 1 to length(s) do
        begin
          try
            s2 := s2 + IntToStr(StrToInt(s[k]));
            l := StrToInt(s2);
          except
          end;

        end;
        Programm_Nr[I].Istwert := l;//Daten.qIstwert.FieldByName('Istwert').AsInteger;
      end;

      if Daten.qIstwert.Locate('Nr', Programm_Start[I].DBNr, []) then
      begin
        if Daten.qIstwert.FieldByName('Istwert').AsInteger = 0 then
          Programm_Start[I].Istwert := False
        else
          Programm_Start[I].Istwert := True;
      end
      else
        Programm_Start[I].Istwert := False;

      if Daten.qIstwert.Locate('Nr', Programm_Ende[I].DBNr, []) then
      begin
        if Daten.qIstwert.FieldByName('Istwert').AsInteger = 0 then
          Programm_Ende[I].Istwert := False
        else
          Programm_Ende[I].Istwert := True;
      end
      else
        Programm_Ende[I].Istwert := False;

    end;

    //********************* SPC **********************************

    if SPC then
    begin
      if StueckAuftragGesamt[I].Istwert <> SPC_Save[I].Stueckzahl then
      begin
        SPC_Save[I].SPC := True;
        SPC_Save[I].Stueckzahl := StueckAuftragGesamt[I].Istwert;

        if SPC_Signal[I].Istwert <> nil then
          for J := 0 to Length(SPC_Signal[I].Istwert) - 1 do
          begin
            if Daten.qIstwert.Locate('Nr', SPC_Signal[I].DBNr[J], []) then
              SPC_Signal[I].Istwert[J] := Daten.qIstwert.FieldByName('Istwert').AsInteger / 100;
          end;

      end
      else
        SPC_Save[I].SPC := False;
    end;

    if SPC_Stich then
    begin
      if SPC_Signal[I].Istwert <> nil then
        for J := 0 to Length(SPC_Signal[I].Istwert) - 1 do
        begin
          if Daten.qIstwert.Locate('Nr', SPC_Signal[I].DBNr[J], []) then
            SPC_Signal[I].Istwert[J] := Daten.qIstwert.FieldByName('Istwert').AsInteger / 100;
        end;
    end;
    Extruderan[I] := 0;
  end;

  // Daten für Extruder holen
  Daten.qIstwert.SQL.Text := 'SELECT signal_maschine.istwert istwert, signal_maschine.maschnr maschnr'
    + ' FROM signal_maschine '
    + ' LEFT JOIN signale ON signale.signalnr=signal_maschine.signalnr '
    + ' WHERE signalart=121';
  Daten.qIstwert.Open;
  while not Daten.qIstwert.EOF do
  begin
    Extruderan[Daten.qIstwert.FieldByName('maschnr').AsInteger] := Daten.qIstwert.FieldByName('istwert').AsInteger;
    Daten.qIstwert.Next;
  end;
  Daten.qIstwert.Close;

  if Metall then
    DatenLesen_Metall;
end;

procedure TS7Main.DatenLesen_Metall;
var
  SQLStr: string;
  I: Integer;
begin
  if Metall then
  begin
    //Stückzahlen gesondert lesen...
    for I := 1 to Anzahl_Masch do
    begin
      StueckAuftragGesamt[I].Istwert := 0;
    end;

    SQLStr := 'select maschine.datenblock,pde.Istwert from maschine,pde '
      + ' where (maschine.lizenz = pde.lizenz) AND (PDE.stat = 0 or pde.stat = 1)';
    if TCO_Setup.GetParamBool(Daten.qUpdate,'SVC_OmitArchivedMachines') then
      SQLStr := SQLStr  + ' AND maschine.archiviert <> 1 ';
    SQL_Get(Daten.qSuch, SQLStr);
    Daten.qSuch.First;
    while not Daten.qSuch.EOF do
    begin
      try
        StueckAuftragGesamt[Daten.qSuch.FieldByName('Datenblock').AsInteger].Istwert :=
          Format_String(Daten.qSuch.FieldByName('Istwert').AsString);
      except
      end;
      Daten.qSuch.Next;
    end;
  end;
end;

procedure TS7Main.Timer1Timer(Sender: TObject);
var
  EText, Meldung: string;
  SchichtChange: Boolean;
  AlteSchicht: Integer;
  logstr : string;
  mem, mem2 : integer;
  label labende;
begin
  SchreibeMeldung('Curr Process Memory [KB]: ' + CurrentProcessMemory_KB, 5);

{$ifdef FullDebugMode}
  CalcCycleCounter := CalcCycleCounter +1;
  SchreibeMeldung('Curr Cycle: ' + IntToStr(CalcCycleCounter), 1);
{$endif}
  if Hochlauf then
    Exit;
  if not Daten_Enabled then
    Exit;

  try
    Daten.Database.Connected := True;
    Daten.qSuch.SQL.Text := 'select Nr from Setup';
    Daten.qSuch.Open;
    Daten.qSuch.Close;

  except
    try
      SchreibeMeldung('Connection failed. Reconnecting...', 0);
      Daten.Database.Connected := False;
      Daten.Database.Connected := True;
      SchreibeMeldung('Reconnected.', 0);
    except
      Exit;
    end;
  end;

  if INCLUDISDatabaseTyp = dbTypMSSQL then
  begin
    DecimalSeparator := '.';
    ThousandSeparator := ',';
  end;

  TimerBegin := N_o_w;
  SchreibeMeldung('--- begin', 1);
  Timer1.ENABLED := False;
  SchichtChange := False;
  Jetzt := N_o_w;



  try
    MakeEnviroment(Daten.qUpdate);
    CCC_SchreibeSystemID;
    if not CCC_CheckLicenses then
    begin
      Timer1.ENABLED := False;
      SchreibeMeldung('System stopped', 0);
      Exit;
    end;

    RefreshKGruppe(Daten.qSuch);

    if INC_Meldung <> nil then
      case INC_Meldung.Meldung_Auswerten of
        MSG_KALENDER_CHANGE: K_Init(Daten.qSuch);
      end;

    if ThreadZusatzLast + ThreadZusatzTimer / 60 / 1440 < Jetzt then
    begin
      ThreadZusatzLast := Jetzt;
      PulseEvent(Event_Zusatz);
    end;

    if ThreadSignallogLast + ThreadSignallogTimer / 60 / 1440 < Jetzt then
    begin
      ThreadSignallogLast := Jetzt;
      PulseEvent(Event_SignalLog);
    end;

    if ThreadBackupLast + ThreadBackupTimer / 60 / 1440 < Jetzt then
    begin
      ThreadBackupLast := Jetzt;
      PulseEvent(Event_DBBackup);
    end;

    if Recalculation_Time > 0 then
      if Recalculation_Next < N_o_w then
      begin
        Recalculation_Next := Trunc(N_o_w) + 1 + Recalculation_Time;
        Thread_Schicht.AlteSchicht := GetSchichtNr(N_o_w);
        Thread_Schicht.Schicht_Berechnung := False;
        PulseEvent(Event_Schicht);
      end;

    Nach_Schichtwechsel := False;
    if NeueSchicht(AlteSchicht) then
    begin
      SchichtChange := True;
      Thread_Schicht.Schicht_Berechnung := True;
      Thread_Schicht.AlteSchicht := AlteSchicht;
      PulseEvent(Event_Schicht);

      // Auch Thread Zusatz starten
      ThreadZusatzLast := Jetzt;
      PulseEvent(Event_Zusatz);
    end;

    SQL_Get(Daten.qSuch, 'select Count(*) CNT from Stat_Recalc2 where Frei = 1');
    if Daten.qSuch.FieldByName('CNT').AsInteger > 0 then
      Statistik_Berechnen;

    if CheckRoteLampeAus and BCD_Schalter then
      S7Main.Schreibe_SPS_Wert(0, TTT_GetSignalNr(CROTELAMPE_AUS), 0)
    else
      S7Main.Schreibe_SPS_Wert(0, TTT_GetSignalNr(CROTELAMPE_AUS), 1);

    MaschAuftragStart := -1;

    logstr := 'Read';
    {$IFDEF INCL_MSADO}
//    logstr := logstr + ' - SQLServer-Process-Memory : ' + EnumProcess('sqlservr.exe');
    {$ENDIF}

    SchreibeMeldung(logstr, 1);
    try
//      mem := CurrentProcessMemory_KBInt;
      DatenLesen;
//      mem2 :=CurrentProcessMemory_KBInt;
//      SchreibeMeldung(logstr + ': ' + IntToStr(mem) + ' -> ' + IntToStr(mem2) + ' = ' +IntToStr(mem2-mem), 7);
    except
      SchreibeMeldung('Error: Read data', 0);
      raise;
    end;

    if Kavitaet_laufender_Auftrag then
    begin
      try
        In_SPSWerteDB;
      except
        SchreibeMeldung('Error: In_SPSWerteDB', 0);
      end;
    end;

    INC_Meldung.ServerStatusOK;

    logstr := 'Init';
    {$IFDEF INCL_MSADO}
//    logstr := logstr +' - SQLServer-Process-Memory : ' +  EnumProcess('sqlservr.exe');
    {$ENDIF}
    SchreibeMeldung(logstr, 1);
    try
//      mem := CurrentProcessMemory_KBInt;
      CCC_Init;
//      mem2 :=CurrentProcessMemory_KBInt;
//      SchreibeMeldung(logstr + ': ' + IntToStr(mem) + ' -> ' + IntToStr(mem2) + ' = ' +IntToStr(mem2-mem), 7);
    except on ex:exception do
      begin
        
        SchreibeMeldung('Error: Init data', 0);
        raise;
      end;
    end;

    if Packen and Verpackt_Barcode then

    begin
      Hole_Daten_Tabelle(CSTUECKPACKAUFTRAGGESAMT);
      Hole_Daten_Tabelle(CSTUECKPACKAUFTRAGSCHICHT);
      Hole_Daten_Tabelle(CSTUECKPACKSCHICHT);
    end;

    if TCO_Setup.GetParamBool(Daten.qSuch, 'INCL_PrescheduledJobStart') then
    begin
      try
        CheckJobPrestart;
      except
        SchreibeMeldung(GetL('Reason: CheckJobPrestart'), 0);
        raise;
      end;
    end;
    
//goto labende;

    if Metall then
    begin

      Metall_Freigabe_Auftrag_Gestartet := False;

      try
        if SigNoAuftrag_Start > -1 then
          Check_Auftrag_Start;
      except
        SchreibeMeldung(GetL('Reason: Check_Auftrag_Start'), 0);
        raise;
      end;

      try
        if SigNoAuftrag_Ende > -1 then
          Check_Auftrag_Ende;
      except
        SchreibeMeldung(GetL('Reason: Check_Auftrag_Ende'), 0);
        raise;
      end;

      if Metall_Freigabe_Auftrag_Gestartet then
      begin
        Timer1.ENABLED := True;
        Exit;
      end;
    end;

    if Auftragstart_Barcode then
    begin
      try
        CCC_Auftrag_Start_Barcode(1);
        CCC_Auftrag_Start_Barcode(2);
        CCC_Auftrag_Start_Barcode(3);
      except
        SchreibeMeldung(GetL('Reason: AuftragStart_Barcode'), 0);
      end;
    end;

    try
      if SigNoAuftrag_Freigabe > -1 then
        CCC_Check_Auftrag_Freigabe;
    except
      SchreibeMeldung(GetL('Reason: Auftrag_Freigabe'), 0);
      raise;
    end;

    logstr := 'Update';
    {$IFDEF INCL_MSADO}
//    logstr := logstr +' - SQLServer-Process-Memory : ' +  EnumProcess('sqlservr.exe');
    {$ENDIF}
    SchreibeMeldung(logstr, 1);
    try
      CCC_Daten_Aktualisieren;
    except
      SchreibeMeldung('Error: Update', 0);
      raise;
    end;

    if TCO_Setup.GetParamInt(Daten.qUpdate, 'INCL_CheckUnterbrocheneAuftraege') > 0 then
    try
      CCC_CheckUnterbrocheneAuftraege;
    except
      SchreibeMeldung(GetL('Reason: CheckUnterbrocheneAuftraege'), 0);
      raise;
    end;

    if TCO_Setup.GetParamInt(Daten.qUpdate, 'INCL_AutoSetup2Time') > 0 then
    try
      CCC_AutoSetup2;
    except
      SchreibeMeldung(GetL('Reason: AutoSetup2'), 0);
      raise;
    end;


    try
      if ( SigNoTerminal_StillstandGebucht > -1 ) and ( SigNoTerminal_StillstandKommtGeht > - 1 ) then
        CCC_Check_Terminal_Stillstand;
    except
      SchreibeMeldung(GetL('Reason: Check_Terminal_Stillstand'), 0);
      raise;
    end;

    if SchichtChange then
      CCC_Zeiten_Aufrunden;

    try
      CCC_Job_Auftrag;
    except
      SchreibeMeldung(GetL('Reason: Job_Auftrag'), 0);
    end;

    if Auftrag_Automatik_Start then
    begin
      try
        CCC_AuftragAutomatikStart;
      except
        SchreibeMeldung(GetL('Reason: AuftragAutomatikStart'), 0);
      end;
    end;

    try
      CCC_AuftragAutomatikStartVariabel;
    except
        SchreibeMeldung(GetL('Reason: AuftragAutomatikStart')+ ' vari', 0);
    end;


    try
      CCC_BDE_Auftrag;
    except
      SchreibeMeldung(GetL('Reason: BDE_Auftrag'), 0);
    end;

    try
      if SigNoMenge_Gebucht > -1 then
        CCC_Check_Menge_Gebucht;
    except
      SchreibeMeldung('Error: Check booked amount', 0);
    end;

    try
      if SigNoTerminal_Auftrag_Ende > -1 then
        CCC_Check_Terminal_Auftrag_Ende;
    except
      SchreibeMeldung(GetL('Reason: Check_Terminal_Auftrag_Ende'), 0);
    end;

    try
      if SigNoTerminal_Auftrag_Unterbrochen > -1 then
        CCC_Check_Terminal_Auftrag_Unterbrochen;
    except
      SchreibeMeldung(GetL('Reason: Check_Terminal_Auftrag_Unterbrochen'), 0);
    end;

    logstr := 'Write';
    {$IFDEF INCL_MSADO}
//    logstr := logstr + ' - SQLServer-Process-Memory : ' + EnumProcess('sqlservr.exe');
    {$ENDIF}


    SchreibeMeldung(logstr, 1);
    try
      CCC_Daten_Schreiben;
    except
      SchreibeMeldung(GetL('Reason: Daten_Schreiben'), 0);
      raise;
    end;

    logstr := 'Check downtimes';
    {$IFDEF INCL_MSADO}
//    logstr := logstr + ' - SQLServer-Process-Memory : ' + EnumProcess('sqlservr.exe');
    {$ENDIF}
    SchreibeMeldung(logstr, 1);
    try
      CCC_TPM_Stillstand_Check;
      if Ruesten_AutoBuchen then
        CCC_Proc_Ruesten_AutoBuchen;
    except on ex : Exception do
      SchreibeMeldung(GetL('Reason: TPM_Stillstand_Check') + ' ' + IntToStr(DebugStage)+ ' ' + ex.Message, 0);
    end;

    if TCO_Setup.GetParamBool(Daten.qSuch, 'INCL_Pausen') then
    begin
      logstr := 'Check Pause';
      {$IFDEF INCL_MSADO}
//      logstr := logstr + ' - SQLServer-Process-Memory : ' + EnumProcess('sqlservr.exe');
      {$ENDIF}
      SchreibeMeldung(logstr, 1);
      try
        CCC_CheckPause;
      except
        SchreibeMeldung('Reason: Pause', 0);
      end;
    end;

    logstr := 'Check Setup';
    {$IFDEF INCL_MSADO}
//    logstr := logstr + ' - SQLServer-Process-Memory : ' + EnumProcess('sqlservr.exe');
    {$ENDIF}
    SchreibeMeldung(logstr, 1);
    try
      CCC_CheckRuestprot_Arbeitsfrei;
    except
      SchreibeMeldung('Reason: Setup Log', 0);
    end;

    logstr := 'Check downtime log';
    {$IFDEF INCL_MSADO}
//    logstr := logstr + ' - SQLServer-Process-Memory : ' + EnumProcess('sqlservr.exe');
    {$ENDIF}
    SchreibeMeldung(logstr, 1);
    try
      CCC_CheckStatusTPM_Stillog;
    except on ex : Exception do
      SchreibeMeldung(GetL('Reason: CheckStatusTPM_Stillog') + ' ' + IntToStr(DebugStage)+ ' ' + ex.Message, 0);
    end;

    if Taktzeit_aus_Stamm then
    begin
      logstr := 'Cycletime from master data';
      {$IFDEF INCL_MSADO}
//      logstr := logstr + ' - SQLServer-Process-Memory : ' + EnumProcess('sqlservr.exe');
      {$ENDIF}
      SchreibeMeldung(logstr, 1);
      try
        CCC_Taktzeit_Aus_Stamm_Update;
      except
        SchreibeMeldung(GetL('Reason: Taktzeit_Aus_Stamm_Update'), 0);
      end;
    end;

    try
      if SigNoSignalauswertung > - 1 then
        CCC_TPM_Signalauswertung;
    except
      SchreibeMeldung(GetL('Reason: TPM_Signalauswertung'), 0);
    end;

    if FehlerNr_Dyn then
    begin
      try
        CCC_FehlerNr_auswertung;
        CCC_FehlerNr_Check;
      except
        SchreibeMeldung(GetL('Reason: FehlerNr_auswertung'), 0);
      end;
    end;

    if BCD_Schalter then
    begin
      try
        if SigNoAuftrag_Starten_BCDCode > -1 then
          CCC_TPM_BCD_Meldung;
      except
        SchreibeMeldung(GetL('Reason: TPM_BCD_Meldung'), 0);
        raise;
      end;

      try
        CCC_Telegramm_Auswerten;
      except
        SchreibeMeldung(GetL('Reason: Telegramm_Auswerten'), 0);
      end;
    end;

    try
      CCC_MDEWerte_fuellen;
    except
      SchreibeMeldung(GetL('Reason: MDEWerte_fuellen'), 0);
    end;

    try
      CCC_MDE_Soll_Ist_Vergleich;
    except
      SchreibeMeldung(GetL('Reason: MDE_Soll_Ist_Vergleich'), 0);
    end;

    if Warmtrennen then
    try
      CCC_Check_Warmtrennen;
    except
      SchreibeMeldung(GetL('Reason: Check_Warmtrennen'), 0);
      raise;
    end;

    if Maschinen_Status_Schreiben then
    begin
      try
        CCC_Schreibe_Maschinen_Status;
      except
        SchreibeMeldung(GetL('Reason: Schreibe_Maschinen_Status'), 0);
        raise;
      end;
    end;

    try
      CCC_Check_TerminOrder;
    except
      SchreibeMeldung(GetL('Reason: Check_Terminorder'), 0);
      raise;
    end;

    try
      if SigNoStillstandNr_SPS > - 1 then
        CCC_Check_StillstandNr_SPS;
    except
      SchreibeMeldung(GetL('Reason: Check_StillstandNr_SPS'), 0);
    end;

//Goto  labende;

    if METALL_BEARBEITUNG then
    begin
      try
        CCC_Check_Job_Stueckzahl;
      except
        SchreibeMeldung(GetL('Reason: Check_Job_Stueckzahl'), 0);
      end;
    end;

    //***********************************************
    //*********** SPC *******************************
    //***********************************************
    if SPC_Stich then
    begin
      SchreibeMeldung('Write SPC', 1);
      try
        SPC_Stich_Schreiben;
      except
        SchreibeMeldung(GetL('Reason: SPC_Stichproben_Schreiben'), 0);
      end;
    end;

    if SPC then
    begin
      SchreibeMeldung('Init SPC', 1);
      try
        SPC_Init;
      except
        SchreibeMeldung(GetL('Reason: SPC_Init'), 0);
      end;

      SchreibeMeldung('Write SPC', 1);
      try
        SPC_Aktuelle_Werte_Schreiben;
      except
        SchreibeMeldung(GetL('Reason: SPC_Aktuelle_Werte_Schreiben'), 0);
      end;

      SchreibeMeldung('Write SPC Spotcheck', 1);
      try
        SPC_Stichproben_Schreiben;
      except
        SchreibeMeldung(GetL('Reason: SPC_Stichproben_Schreiben'), 0);
      end;

      SchreibeMeldung('SPC Shift log', 1);
      try
        SPC_SchichtProtokoll_Schreiben;
      except
        SchreibeMeldung(GetL('Reason: SPC_SchichtProtokoll_Schreiben'), 0);
      end;

      SchreibeMeldung('SPC Set / Curr compare', 1);
      try
        SPC_SollIstVergleich;
      except
        SchreibeMeldung(GetL('Reason: SPC_Soll_Ist_Vergleich'), 0);
      end;

    end;

    if QS then
        if not TCO_Setup.GetParamBool(Daten.qUpdate, 'INCL_BdaList_Testplan_BdaService') then
          try
            CCC_QS_Jobs;
          except
            SchreibeMeldung(GetL('Reason: QS_Jobs'), 0);
        end;

    if AutoRuesten then
    try
      CCC_Auto_Ruesten2;
    except
      SchreibeMeldung(GetL('Reason: Auto_Ruesten2'), 0);
    end;

    if Verpackt_aus_Ausschuss then
    try
      CCC_Verpackt_aus_Ausschuss_Berechnen;
    except
      SchreibeMeldung(GetL('Reason: Verpackt_aus_Ausschuss'), 0);
    end;

    if FolgeAuftrag_Autostart then
    try
      CCC_FolgeAuftrag_Starten;
    except on ex: Exception do
        SchreibeMeldung(GetL('Reason: FolgeAuftrag_Starten') + ' ' + ex.message, 0);
    end;

    if Maschinenwartung then
    try
      CCC_Maschinen_Wartung;
    except
      SchreibeMeldung(GetL('Reason: Maschinen_Wartung'), 0);
    end;

    if AUFTRAG_BLOCK then
    try
      CCC_CheckBlock;
    except
      SchreibeMeldung(GetL('Reason: CheckBlock'), 0);
    end;

    if TCO_Setup.GetParamBool(Daten.qSuch, 'JobSetupAndRestart') then
    try
      CCC_JobSetupAndRestart(S7_Auftrag);
    except
      SchreibeMeldung(GetL('Reason: JobSetupAndRestart'), 0);
    end;

    if BypassMode then
    try
      CCC_CheckBypass;
    except
      SchreibeMeldung(GetL('Reason: CheckBypass'), 0);
    end;

    if PersonalNr_Signal then
    try
      GetPersonalNr_Signal;
    except
      SchreibeMeldung('Error: 31A365A1-2289-4A5F-9036-82C07C591367', 0);
    end;

    if Ausschuss_Signal then
    try
      GetAusschuss_Signal;
    except
      SchreibeMeldung('Error: E6892507-8265-4897-BEA3-F752DE0EE6AE', 0);
    end;

    if not Daten.Conn then
    begin
      SchreibeMeldung('Connecting has been restored', 0);
      Daten.Conn := True;
    end;

labende:

    if Last_Time_Meldung < (N_o_w - Zeit_zur_Meldung) then
    begin
      SchreibeMeldung('Data update successful...', 0);
      Last_Time_Meldung := N_o_w;
    end;

    (* Alivetimer auf Ende gezogen, damit nur bei erfolgreichem Durchlauf Ali getriggert wird *)
    MainServiceAliveTimer.tick;

    except  on E: Exception do
    begin
      inc(ErrorCount);
      HandleSystemError(Self,E,'');
      EText := E.message;
      Meldung := GetL('Error (' + IntToStr(ErrorCount) + ') : ') + DateTimeToStr(Trunc(Jetzt)) + ' : ' + EText;
      SchreibeMeldung(Meldung, 0);
      if ErrorCount > 4 then
      begin
        S7MainOK := False;
        SchreibeMeldung('S7MainOK false !', 0);
      end;
    end;
  end;


  SchreibeMeldung('--- end', 1);
  SchreibeMeldung('time from begin = ' + TimeToStr(N_o_w - TimerBegin), 1);
  SchreibeMeldung('time from   end = ' + TimeToStr(N_o_w - TimerEnd), 1);
  SchreibeMeldung('Current Process Memory [KB]: ' + CurrentProcessMemory_KB, 1);

  Meldung := 'Runtime: ' + TimeToStr(N_o_w - TimerBegin) + ' Memory: ' + CurrentProcessMemory_KB;
  SchreibeMeldung(Meldung, 5);

  TimerEnd := N_o_w;
  Timer1.ENABLED := True;
{$ifdef FullDebugMode}
  if CalcCycleCounter >= MaxCycles then
  begin
    SchreibeMeldung('Debug Cycles reached', 1);
//    Form1.Close;
  end;
{$endif}

end;

procedure TS7Main.HandleSystemError(Sender: TObject; E: Exception; aCustomString: string);
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
    //    + 'Form            : [' + SCREEN.ActiveForm.Name + ']' + #13#10
    // + 'EXE-File        : [' + Application.ExeName + ']' + #13#10
    + 'DateTime        : [' + DateTimeToStr(Now) + ']' + #13#10
    + 'ClassThree      : [' + ClassThree + ']' + #13#10
    + 'Message         : [' + E.message + ']' + #13#10
    + 'Comment         : [' + aCustomString + ']' + #13#10
    + '--- End of report ---------------------------------------' + #13#10;

  SchreibeMeldung(s,0);
end;


procedure TS7Main.Schreibe_SPS_Wert(MaschNr: Integer; SignalNr: Integer; Wert: Integer);
var
  SQLStr: string;
  Nr: Integer;
begin
  if not SQLGetBool(Daten.qUpdate, 'SIGNALE', 'SIGNALNR', IntToStr(SignalNr)) then
    Exit;

  SQLStr := 'select COUNT(*) CNT from SIGNAL_SCHREIBEN where Maschnr = ' + IntToStr(MaschNr) + ' AND SignalNr = ' +
    IntToStr(SignalNr);
  SQL_Get(Daten.qUpdate, SQLStr);
  if Daten.qUpdate.FieldByName('CNT').AsInteger > 0 then
  begin
    SQLStr := 'select * from SIGNAL_SCHREIBEN where Maschnr = ' + IntToStr(MaschNr) + ' AND SignalNr = ' +
      IntToStr(SignalNr);
    SQL_Get(Daten.qUpdate, SQLStr);
    Nr := Daten.qUpdate.FieldByName('Nr').AsInteger;
    if Daten.qUpdate.FieldByName('Wert').AsInteger <> Wert then
      UpdateSQL(Daten.qUpdate, 'SIGNAL_SCHREIBEN', 'Wert', IntToStr(Wert), 'Nr', IntToStr(Nr));
    Exit;
  end;

  if SignalNr = -1 then
    Exit;

  SQLStr := 'INSERT INTO SIGNAL_SCHREIBEN (Nr,MaschNr,SignalNr,Wert)'
    + 'VALUES(SIGNAL_SCHREIBENID.NextVal'
    + ',''' + IntToStr(MaschNr)
    + ''',''' + IntToStr(SignalNr)
    + ''',''' + IntToStr(Wert)
    + ''')';
  SQL_Insert(Daten.qUpdate, SQLStr);

  SQLStr := 'INSERT INTO LOG_SIGNAL_SCHREIBEN (Nr, DatumZeit, Datumexakt, MaschNr, SignalNr, Wert)'
    + ' VALUES (Log_SIGNAL_SCHREIBENID.NextVal,'
    + ' ''' + DateTimeToStr(N_o_w) + ''','
    + FloatToPunktString(N_o_w) + ','
    + ' ''' + IntToStr(MaschNr) + ''','
    + ' ''' + IntToStr(SignalNr) + ''','
    + ' ''' + IntToStr(Wert) + ''')';
  SQL_Insert(Daten.qUpdate, SQLStr);
end;

function TS7Main.NeueSchicht(var AlteSchicht: Integer): Boolean;
var
  SQLStr: string;
  Nr: Integer;
begin
  Result := False;
  AlteSchicht := -1;
  SQLStr := 'Select * from SIWECHSEL';
  SQL_Get(Daten.qSuch, SQLStr);
  if Daten.qSuch.FieldByName('Schichtwechsel').AsInteger = 1 then
  begin
    Result := True;
    Nr := Daten.qSuch.FieldByName('Nr').AsInteger;
    AlteSchicht := Daten.qSuch.FieldByName('AlteSchicht').AsInteger;
    SQLStr := 'delete from SIWECHSEL where Nr = ''' + IntToStr(Nr) + '''';
    SQL_Insert(Daten.qUpdate, SQLStr);
  end;
end;

function TS7Main.CheckRoteLampeAus: Boolean;
var
  SQLStr: string;
  Nr: Integer;
begin
  SQLStr := 'Select Count(*) CNT from ROTELAMPE';
  SQL_Get(Daten.qSuch, SQLStr);
  if (Daten.qSuch.FieldByName('CNT').AsInteger > 0) then
  begin
    SQLStr := 'Select * from ROTELAMPE';
    SQL_Get(Daten.qSuch, SQLStr);
    Daten.qSuch.First;
    while not Daten.qSuch.EOF do
    begin
      Nr := Daten.qSuch.FieldByName('Nr').AsInteger;
      DeleteSQL(Daten.qUpdate, 'ROTELAMPE', 'Nr', IntToStr(Nr));
      Daten.qSuch.Next;
    end;
  end;

  SQLStr := 'select COUNT(*) CNT from BDA where RoteLampeAn = 1';
  SQL_Get(Daten.qSuch, SQLStr);
  Result := Daten.qSuch.FieldByName('CNT').AsInteger = 0;
end;

procedure TS7Main.Hole_Daten_Tabelle(Datentyp: Integer);
var
  I: Integer;
  SQLStr: string;
begin
  case Datentyp of
    CSTUECKPACKSCHICHT:
      begin
        for I := 1 to Anzahl_Masch do
        begin
          if Includis[i].IstArchiviert then
            Continue;
          if SQLGetBool(Daten.qSuch, 'PACKMASCH', 'Lizenz', Includis[I].Lizenz) then
          begin
            Includis[I].StueckPackSchicht := Daten.qSuch.FieldByName('StueckPackSchicht').AsInteger;
          end
          else
            Includis[I].StueckPackSchicht := 0;
        end;
      end;
    CSTUECKPACKAUFTRAGSCHICHT:
      begin
        for I := 1 to Anzahl_Masch do
        begin
          if Includis[i].IstArchiviert then
            Continue;
          if SQLGetBool(Daten.qSuch, 'PACKAUFTRAG', 'Betriebsauftragnr', Includis[I].Auftrag.BetriebsauftragNr) then
          begin
            Includis[I].StueckPackAuftragSchicht := Daten.qSuch.FieldByName('StueckPackAuftragSchicht').AsInteger;
          end
          else
            Includis[I].StueckPackAuftragSchicht := 0;
        end;
      end;
    CSTUECKPACKAUFTRAGGESAMT:
      begin
        for I := 1 to Anzahl_Masch do
        begin
          if Includis[i].IstArchiviert then
            Continue;
          SQLStr := 'select Sum(Zugang-Abgang) as CNT from VerpacktProt where BetriebsAuftragNr=''' +
            Includis[I].Auftrag.BetriebsauftragNr + '''';
          SQL_Get(Daten.qSuch, SQLStr);
          Includis[I].StueckPackAuftragGesamt := Daten.qSuch.FieldByName('CNT').AsInteger;
        end;
      end;
  end;
end;

function TS7Main.GetStueckAuftragAlt(index: Integer): Longint;
begin
  if SQLGetBool(Daten.qSuch, 'SPSWERTE', 'LIZENZINT', IntToStr(index)) then
    Result := Daten.qSuch.FieldByName('STUECKAUFTRAGGESAMT').AsInteger
  else
    Result := 0;
end;

function TS7Main.CheckManuelleStueckBuchung(index: Integer): Boolean;
begin
  if SQLGetBool(Daten.qSuch3, 'SPSWERTE', 'LIZENZINT', IntToStr(index)) then
    Result := Daten.qSuch3.FieldByName('MASCHORG').AsInteger = 1
  else
    Result := False;

  if Result then
  begin
    SQLStr := 'update SPSWERTE set MaschOrg = 0 where LizenzInt = ' + IntToStr(index);
    SQL_Insert(Daten.qUpdate, SQLStr);

    StueckAuftragAlt[index] := 0;
    Diff_Stueck[index] := 0;
  end;
end;

end.

