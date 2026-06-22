// <summary>
// DBMain.cs - C# translation of DBMain.pas
// Contains constants, type definitions, and global variables for database operations
// </summary>

using System;
using System.Collections.Generic;

namespace INCLService_CSharp
{
    public static class DBMain
    {
        // ========================================================================
        // Constants from the Delphi file
        // ========================================================================
        
        public const string Module = "INCLServer";
        public const string VerDatum = "31.10.2005";

        public const int TAGMINUTEN = 1440;
        public const double Stunde = 1.0 / 24.0;

        public const double MINUTEN5 = 5.0 / TAGMINUTEN;
        public const double MINUTEN10 = 10.0 / TAGMINUTEN;
        public const double MINUTEN60 = Stunde;
        public const int INC_Application = 50;

        public const int Max_ANZAHL = 600;
        public const int MAX_S7_LESEVERSUCHE = 100;
        public const int Max_Nutzung = 100;
        public const int Max_Leistung = 200;
        public const int MAX_BARCODE = 13;

        public const int VToleranz = 5;
        public const int VHandToleranz = 5;

        public const int SchichtZeitHandbetrieb = 60;

        // Time constants
        public const double Zeit_zum_MDEAuftrag = 0.003472; // 5 minutes
        public const double Zeit_zum_AutoStart = 0.006944; // 10 minutes
        public const double Zeit_zur_Meldung = 0.041664; // 60 minutes

        public const int StatusPlanDiff = 1440;

        // Simulation flags
        public const bool SIMULATION = false;
        public const bool TEMPSIMULATION = false;
        public const bool BCDSIMULATION = false;

        // Variable type constants
        public const int BYTEVAR = 0;
        public const int WORDVAR = 1;
        public const int DWORDVAR = 2;
        public const int BOOLVAR = 3;

        // SPS Data address constants
        public const int CSTUECKGESAMT = 0;
        public const int CSTUECKAUFTRAGGESAMT = 1;
        public const int CSTUECKAUFTRAGSCHICHT = 2;
        public const int CSTUECKSCHICHT = 3;

        public const int CBETRIEBSSTUNDEN = 4;
        public const int CTAKTZEIT = 5;
        public const int CLAUFZEITGESAMT = 6;
        public const int CLAUFZEITSCHICHT = 7;

        public const int CSTUECKPREUFGESAMT = 8;
        public const int CSTUECKPRUEFAUFTRAGGESAMT = 9;
        public const int CSTUECKPRUEFAUFTRAGSCHICHT = 10;
        public const int CSTUECKPRUEFSCHICHT = 11;

        public const int CSTUECKPACKGESAMT = 12;
        public const int CSTUECKPACKAUFTRAGGESAMT = 13;
        public const int CSTUECKPACKAUFTRAGSCHICHT = 14;
        public const int CSTUECKPACKSCHICHT = 15;

        // Byte variables
        public const int CBCD = 16;

        // Bool variables
        public const int CBCD_READ = 17;
        public const int CHANDAUTO = 18;
        public const int CDRUCKART = 19;
        public const int CMASCHPROGRAMMBETRIEB = 20;

        // Bool Rückmeldungen
        public const int CAUFTRAGRESETSTUECK = 21;
        public const int CAUFTRAGRESETPRUEF = 22;
        public const int CAUFTRAGRESETPACK = 23;

        // Bool Rückmeldungen global
        public const int CSCHICHTWECHSEL = 24;
        public const int CROTELAMPE_AUS = 25;

        // Individuelle Stillstandsmeldungen
        public const int CINDIVSTILLSTAND = 26;

        // Barcode
        public const int CBARCODE_GELESEN = 27;
        public const int CBARCODE = 28;

        public const int CAUFTRAG_FREIGABE = 29;
        public const int CMASCHINEN_STATUS = 30;

        public const int CTERMINAL_MASCHINE = 31;
        public const int CREPARATUR_START_ENDE = 32;
        public const int CTERMINAL_EINHEIT = 33;
        public const int CTerminal_Menge_Gebucht = 34;

        public const int CTERMINAL_EINGABE = 35;
        public const int CTERMINAL_STILLSTAND_GEBUCHT = 36;
        public const int CTERMINAL_STOER_KOMMT_GEHT = 37;
        public const int CTERMINAL_STOER_NR = 38;
        public const int CTERMINAL_STILL_STOER = 39;

        // Barcode arrays
        public const int CBARCODE1 = 40;
        public const int CBARCODE2 = 41;
        public const int CBARCODE3 = 42;
        public const int CBARCODE4 = 43;
        public const int CBARCODE5 = 44;
        public const int CBARCODE6 = 45;
        public const int CBARCODE7 = 46;
        public const int CBARCODE8 = 47;
        public const int CBARCODE9 = 48;
        public const int CBARCODE10 = 49;
        public const int CBARCODE11 = 50;
        public const int CBARCODE12 = 51;
        public const int CBARCODE13 = 52;

        // SPC signals
        public const int CSPC_SIGNAL = 53;

        // Barcode 2
        public const int CBARCODE_GELESEN_2 = 58;
        public const int CBARCODE_2_1 = 59;
        public const int CBARCODE_2_2 = 60;
        public const int CBARCODE_2_3 = 61;
        public const int CBARCODE_2_4 = 62;
        public const int CBARCODE_2_5 = 63;
        public const int CBARCODE_2_6 = 64;
        public const int CBARCODE_2_7 = 65;
        public const int CBARCODE_2_8 = 66;
        public const int CBARCODE_2_9 = 67;
        public const int CBARCODE_2_10 = 68;
        public const int CBARCODE_2_11 = 69;
        public const int CBARCODE_2_12 = 70;
        public const int CBARCODE_2_13 = 71;

        // Barcode 3
        public const int CBARCODE_GELESEN_3 = 72;
        public const int CBARCODE_3_1 = 73;
        public const int CBARCODE_3_2 = 74;
        public const int CBARCODE_3_3 = 75;
        public const int CBARCODE_3_4 = 76;
        public const int CBARCODE_3_5 = 77;
        public const int CBARCODE_3_6 = 78;
        public const int CBARCODE_3_7 = 79;
        public const int CBARCODE_3_8 = 80;
        public const int CBARCODE_3_9 = 81;
        public const int CBARCODE_3_10 = 82;
        public const int CBARCODE_3_11 = 83;
        public const int CBARCODE_3_12 = 84;
        public const int CBARCODE_3_13 = 85;

        public const int CAUFTRAG_START_MASCHINE1 = 86;
        public const int CAUFTRAG_START_MASCHINE2 = 87;
        public const int CAUFTRAG_START_MASCHINE3 = 88;

        public const int CTERMINAL_AUFTRAG_BEENDEN = 89;
        public const int CTERMINAL_AUFTRAG_UNTERBRECHEN = 90;
        public const int CTERMINAL_ETIKETT = 91;

        public const int CWARMTRENNEN = 92;
        public const int CPROGRAMM_NR = 93;
        public const int CPROGRAMM_START = 94;
        public const int CPROGRAMM_ENDE = 95;

        public const int CTERMINAL_AUFTRAGNR = 96;
        public const int CTERMINAL_AUFTRAGNR_ASCII = 97;

        public const int CFEHLERNR = 98;
        public const int CVORRICHTUNG = 99;
        public const int CSTILLSTANDNR = 100;
        public const int CJOB_STUCKZAHL = 101;

        public const int CAUTOAUSSCHUSS_AUFTRAG = 102;
        public const int CAUTOAUSSCHUSS_SCHICHT = 103;
        public const int CAUTOAUSSCHUSS_AUFTRAGSCHICHT = 104;

        public const int CRUESTEN2 = 105;
        public const int CWARTENAUFFREIGABE = 106;

        public const int CAUSSCHUSS = 107;
        public const int CPERSONALNR = 108;
        public const int CPERSONALNR_RESET = 109;
        public const int CHEIZUNGSDAUER = 110;

        public const int Maschinenstatus = 123;
        public const int CSPANNZEITSUMME = 124;
        public const int CSPANNZEITAKTUELL = 125;
        public const int CSPSKAVITAET = 139;

        // ========================================================================
        // Database type constants
        // ========================================================================
        
        public static int INCLUDISDatabaseTyp = 1; // 1 = SQL Server, other values for different DB types

        // ========================================================================
        // Global Variables
        // ========================================================================
        
        // Machine count
        public static int Anzahl_Masch = 0;

        // Feature flags
        public static bool Pruefen = false; // Prüf-Lichtschranken vorhanden
        public static bool Packen = false; // Die Gepackten Stückzahlen werden zurückgemeldet
        public static bool Verpackt_Barcode = false; // Die Verpackten-Artikel werden über Barcode zurückgemeldet
        public static bool Verpackt_aus_Ausschuss = false;
        public static bool Ende_Aus_Verpackt = false;
        public static bool BCD_Schalter = false; // Störmeldungen, Auftragstart, -ende über BCD-Schalter
        public static bool SPC = false; // Modul SPC vorhanden
        public static bool SPC_Stich = false; // Nur SPC-Stichproben speichern
        public static bool halbautomatik = false; // Änderung der zugrundegelegten Toleranzen bei Halbautomaten
        public static bool pruef_gleich_pack = false; // Die Anzahl der Gepackten Artikel wird den Geprüften gleichgesetzt
        public static bool werkzeugverwaltung = false; // Modul Werkzeugverwaltung vorhanden
        public static bool maschinenreinigung = false; // Setzt x Minuten vor Schichtwechsel alle Maschinen auf Grün
        public static bool Werkstatt_Ausschuss = false; // Ausschuss wird über Werkstattversion zurückgemeldet
        public static bool Differenzliste = false;
        public static bool Runtime_Log = false;
        public static bool Ruestzeit_Auftrag_FolgeAuftrag = false;
        public static bool Warmtrennen = false;
        public static DateTime Recalculation_Time = DateTime.MinValue;
        public static bool Kavitaet_laufender_Auftrag = false;
        public static bool Kavitaet_laufender_Auftrag2 = false;
        public static bool Kavitaet_laufender_Auftrag3 = false;
        public static bool Palette_Rest = false;
        public static bool Metall = false;
        public static bool Stoer_Gleich_Ruest = false;
        public static bool Stillstand_Werksplanung = false;
        public static bool FehlerNr_Dyn = false;
        public static bool KombiWerkzeuge = false;
        public static bool Ende_Aus_Isttakt = false;
        public static bool Ende_Aus_Isttakt_IstKav = false;
        public static bool WZ_Warnung_Sperren = false;
        public static bool Variable_Kavitaet = false;
        public static bool DoppelWerkzeuge = false;
        public static bool Auftragstart_Barcode = false;
        public static bool Personal_Anmeldung = false;
        public static bool Reparatur_Anmeldung = false;
        public static bool Maschinen_Status_Schreiben = false;
        public static bool Auftrag_Automatik_Start = false;
        public static bool LogSignals = false;
        public static bool Extrusion = false;
        public static bool TPM_Auswertung = false;
        public static bool Taktzeit_aus_Stamm = false;
        public static bool Ruesten_Autobuchen = false;
        public static bool barcodepzewerkstatt = false;
        public static bool Still_Ueberwachungszeit = false;
        public static bool JOBPRODUKTION = false;
        public static bool QS = false;
        public static bool METALL_BEARBEITUNG = false;
        public static bool Maschinenwartung = false;
        public static int Stillstand_Minute_Loeschen = 0;
        public static bool AutoRuesten = false;
        public static int Shift_Model = 0;
        public static int MaxSchichtTime = 0;
        public static int SchichtDauer = 0;
        public static int Stillstaende_Schicht = 0;
        public static bool Active_Alarming = false;
        public static bool Menge_Schicht_Berechnen = false;
        public static bool Menge_Schicht_Minus = false;
        public static bool MachineCycleCount = false;
        public static bool RUESTPROT_AUS_STILLSTAND = false;
        public static bool RUESTGRUND = false;
        public static bool FolgeAuftrag_Autostart = false;
        public static bool TACKTLOG_CHECK = false;
        public static int TACKTLOG_CHECK_TOLERANZ = 0;
        public static bool SHORT_DELAY_AUTO_BOOK = false;
        public static int SHORT_DELAY_AUTO_BOOK_VALUE = 0;
        public static bool BLOCKSTILLSTAND = false;
        public static bool AUFTRAG_BLOCK = false;
        public static bool BCDAutoStartNachRuesten = false;
        public static bool PersonalNr_Signal = false;
        public static bool Ausschuss_Signal = false;
        public static bool PackedLogFromShiftLog = false;
        public static bool Heizungskontrolle = false;
        public static bool PauseBuchen = false;
        public static bool buchen_arbeitsfrei_bis = false;
        public static bool BypassMode = false;
        public static bool SpannzeitUeberwachen = false;
        public static bool OptionPlanung = false;
        public static int SPC_Check_Toleranz = 0;
        public static int SPC_Ausreisser_Loeschen = 0;
        public static int SPC_NichtAufzeichnenVorSchicht = 0;
        public static int RuestStillstandNrUngeplant = 0;
        public static bool RuestenIstGeplant = false;
        public static bool KavitaetFromSPS = false;
        public static bool AuftragKette = false;
        public static string ServerNameDesDienstes = "";
        public static string IgnorePendingStatement = "";
        public static int CalcCycleCounter = 0;
        public static int MaxCycles = 10;
        public static string MerkerSchichtwechsel = "";
        public static string MerkerRoteLampe = "";

        // Machine state constants
        public static int MaschRuesten = 1;
        public static int MaschinenStatusLaufend = 0;
        public static int MaschinenStatusRuesten = 1;
        public static int MaschinenStatusStillstand = 2;

        // Time constants for monitoring
        public static int Uberwachungszeit_Minuten = 30;
        public static int Warmtrennen_Minuten = 15;
        public static int Ruestzeit_Minuten = 10;
        public static int Wartung_Stunden = 168; // 7 Tage * 24 Stunden
        public static int QS_MinQualitaet = 95;

        // ========================================================================
        // SPS Data Arrays - These would be populated from S7Main
        // ========================================================================
        
        // Arrays for SPS data
        public static TSPS_Daten_DWord[] StueckGesamt = new TSPS_Daten_DWord[Max_ANZAHL + 1];
        public static TSPS_Daten_DWord[] StueckAuftragGesamt = new TSPS_Daten_DWord[Max_ANZAHL + 1];
        public static int[] StueckAuftragAlt = new int[Max_ANZAHL + 1];
        public static int[] Diff_Stueck = new int[Max_ANZAHL + 1];
        public static TSPS_Daten_DWord[] StueckAuftragSchicht = new TSPS_Daten_DWord[Max_ANZAHL + 1];
        public static TSPS_Daten_DWord[] StueckSchicht = new TSPS_Daten_DWord[Max_ANZAHL + 1];

        public static TSPS_Daten_DWord[] Betriebsstunden = new TSPS_Daten_DWord[Max_ANZAHL + 1];
        public static TSPS_Daten_DWord[] Taktzeit = new TSPS_Daten_DWord[Max_ANZAHL + 1];
        public static TSPS_Daten_DWord[] LaufzeitGes = new TSPS_Daten_DWord[Max_ANZAHL + 1];
        public static TSPS_Daten_DWord[] LaufzeitSchicht = new TSPS_Daten_DWord[Max_ANZAHL + 1];

        public static TSPS_Daten_DWord[] StueckPruefGesamt = new TSPS_Daten_DWord[Max_ANZAHL + 1];
        public static TSPS_Daten_DWord[] StueckPruefAuftragGesamt = new TSPS_Daten_DWord[Max_ANZAHL + 1];
        public static TSPS_Daten_DWord[] StueckPruefAuftragSchicht = new TSPS_Daten_DWord[Max_ANZAHL + 1];
        public static TSPS_Daten_DWord[] StueckPruefSchicht = new TSPS_Daten_DWord[Max_ANZAHL + 1];

        public static TSPS_Daten_DWord[] StueckPackGesamt = new TSPS_Daten_DWord[Max_ANZAHL + 1];
        public static TSPS_Daten_DWord[] StueckPackAuftragGesamt = new TSPS_Daten_DWord[Max_ANZAHL + 1];
        public static TSPS_Daten_DWord[] StueckPackAuftragSchicht = new TSPS_Daten_DWord[Max_ANZAHL + 1];
        public static TSPS_Daten_DWord[] StueckPackSchicht = new TSPS_Daten_DWord[Max_ANZAHL + 1];

        public static TSPS_Daten_Word[] Terminal_AuftragNr = new TSPS_Daten_Word[Max_ANZAHL + 1];

        // SPC data
        public static TSPS_Daten_DWord_Dyn[] SPC_Signal = new TSPS_Daten_DWord_Dyn[Max_ANZAHL + 1];
        public static int[] Stich_Zaehler = new int[Max_ANZAHL + 1];

        // Machine state data
        public static TSPS_Daten_Word[] Maschinen_Zustand = new TSPS_Daten_Word[Max_ANZAHL + 1];
        public static TSPS_Daten_Word[] Terminal_Einheit = new TSPS_Daten_Word[Max_ANZAHL + 1];
        public static TSPS_Daten_Word[] Terminal_StoerKommtGeht = new TSPS_Daten_Word[Max_ANZAHL + 1];
        public static TSPS_Daten_Word[] Terminal_Stoer_Nr = new TSPS_Daten_Word[Max_ANZAHL + 1];
        public static TSPS_Daten_Word[] Terminal_Still_Stoer = new TSPS_Daten_Word[Max_ANZAHL + 1];
        public static TSPS_Daten_Word[] Terminal_Etikett = new TSPS_Daten_Word[Max_ANZAHL + 1];
        public static TSPS_Daten_Word[] Programm_Nr = new TSPS_Daten_Word[Max_ANZAHL + 1];
        public static TSPS_Daten_Word[] Terminal_AuftragNr_ASCII = new TSPS_Daten_Word[Max_ANZAHL + 1];

        // BCD data
        public static TSPS_Daten_Byte[] BCD = new TSPS_Daten_Byte[Max_ANZAHL + 1];
        public static TSPS_Daten_DWord[] StillstandNr_SPS = new TSPS_Daten_DWord[Max_ANZAHL + 1];
        public static TSPS_Daten_DWord[] StillstandNr_SPS_Save = new TSPS_Daten_DWord[Max_ANZAHL + 1];
        public static TSPS_Daten_Byte[] Job_Stueckzahl = new TSPS_Daten_Byte[Max_ANZAHL + 1];

        // Bool arrays
        public static TSPS_Daten_Bool[] BCD_Read = new TSPS_Daten_Bool[Max_ANZAHL + 1];
        public static TSPS_Daten_Bool[] HandAuto = new TSPS_Daten_Bool[Max_ANZAHL + 1];
        public static TSPS_Daten_Bool[] MaschProgrammbetrieb = new TSPS_Daten_Bool[Max_ANZAHL + 1];
        public static TSPS_Daten_Bool[] Auftrag_Freigabe = new TSPS_Daten_Bool[Max_ANZAHL + 1];
        public static TSPS_Daten_Bool[] Programm_Start = new TSPS_Daten_Bool[Max_ANZAHL + 1];
        public static TSPS_Daten_Bool[] Programm_Ende = new TSPS_Daten_Bool[Max_ANZAHL + 1];
        public static TSPS_Daten_Bool[] Terminal_Menge_Gebucht = new TSPS_Daten_Bool[Max_ANZAHL + 1];
        public static TSPS_Daten_Bool[] Terminal_Stillstand_Gebucht = new TSPS_Daten_Bool[Max_ANZAHL + 1];

        // Additional SPS data
        public static TSPS_Daten_Bool[] Vorrichtung = new TSPS_Daten_Bool[Max_ANZAHL + 1];
        public static TSPS_Daten_DWord[] AUTOAUSSCHUSS_AUFTRAG = new TSPS_Daten_DWord[Max_ANZAHL + 1];
        public static TSPS_Daten_DWord[] AUTOAUSSCHUSS_SCHICHT = new TSPS_Daten_DWord[Max_ANZAHL + 1];
        public static TSPS_Daten_DWord[] AUTOAUSSCHUSS_AUFTRAGSCHICHT = new TSPS_Daten_DWord[Max_ANZAHL + 1];

        // Barcode data
        public static TSPS_Daten_Bool Barcode_Gelesen = new TSPS_Daten_Bool();
        public static TSPS_Daten_Bool Barcode_Gelesen_2 = new TSPS_Daten_Bool();
        public static TSPS_Daten_Bool Barcode_Gelesen_3 = new TSPS_Daten_Bool();
        public static TSPS_Daten_Word[] Barcode = new TSPS_Daten_Word[MAX_BARCODE + 1];
        public static TSPS_Daten_Word[] Barcode_2 = new TSPS_Daten_Word[MAX_BARCODE + 1];
        public static TSPS_Daten_Word[] Barcode_3 = new TSPS_Daten_Word[MAX_BARCODE + 1];
        public static TSPS_Daten_Word Terminal_Maschine = new TSPS_Daten_Word();
        public static TSPS_Daten_Word Reparatur_Start_Ende = new TSPS_Daten_Word();

        // Order start data
        public static TSPS_Daten_Byte AuftragStart1 = new TSPS_Daten_Byte();
        public static TSPS_Daten_Byte AuftragStart2 = new TSPS_Daten_Byte();
        public static TSPS_Daten_Byte AuftragStart3 = new TSPS_Daten_Byte();
        public static TSPS_Daten_Bool Terminal_Eingabe = new TSPS_Daten_Bool();

        // ========================================================================
        // Type Definitions
        // ========================================================================
        
        /// <summary>
        /// SPS Data DWord record
        /// </summary>
        public class TSPS_Daten_DWord
        {
            public string Maschine { get; set; } = "";
            public string Signal { get; set; } = "";
            public int LizenzInt { get; set; } = 0;
            public string Adresse { get; set; } = "";
            public int Format { get; set; } = 0;
            public int Istwert { get; set; } = 0;
            public int Altwert { get; set; } = 0;
            public int DBNr { get; set; } = 0;
            public int SignalNr { get; set; } = 0;
        }

        /// <summary>
        /// SPS Data Word record
        /// </summary>
        public class TSPS_Daten_Word
        {
            public string Maschine { get; set; } = "";
            public string Signal { get; set; } = "";
            public int LizenzInt { get; set; } = 0;
            public string Adresse { get; set; } = "";
            public int Format { get; set; } = 0;
            public int Istwert { get; set; } = 0;
            public int DBNr { get; set; } = 0;
            public int SignalNr { get; set; } = 0;
        }

        /// <summary>
        /// SPS Data Byte record
        /// </summary>
        public class TSPS_Daten_Byte
        {
            public string Maschine { get; set; } = "";
            public string Signal { get; set; } = "";
            public int LizenzInt { get; set; } = 0;
            public string Adresse { get; set; } = "";
            public int Format { get; set; } = 0;
            public byte Istwert { get; set; } = 0;
            public int DBNr { get; set; } = 0;
            public int SignalNr { get; set; } = 0;
        }

        /// <summary>
        /// SPS Data Bool record
        /// </summary>
        public class TSPS_Daten_Bool
        {
            public string Maschine { get; set; } = "";
            public string Signal { get; set; } = "";
            public int LizenzInt { get; set; } = 0;
            public string Adresse { get; set; } = "";
            public int Format { get; set; } = 0;
            public bool Istwert { get; set; } = false;
            public int DBNr { get; set; } = 0;
            public int SignalNr { get; set; } = 0;
        }

        /// <summary>
        /// SPS Data DWord Dynamic record
        /// </summary>
        public class TSPS_Daten_DWord_Dyn
        {
            public string Maschine { get; set; } = "";
            public string Signal { get; set; } = "";
            public int LizenzInt { get; set; } = 0;
            public string Adresse { get; set; } = "";
            public int Format { get; set; } = 0;
            public int Istwert { get; set; } = 0;
            public int Altwert { get; set; } = 0;
            public int DBNr { get; set; } = 0;
            public int SignalNr { get; set; } = 0;
            public bool Dynamic { get; set; } = false;
        }

        // ========================================================================
        // Initialization
        // ========================================================================
        
        /// <summary>
        /// Initialize DBMain with default values
        /// </summary>
        public static void Initialize()
        {
            // Initialize arrays
            for (int i = 0; i <= Max_ANZAHL; i++)
            {
                StueckGesamt[i] = new TSPS_Daten_DWord();
                StueckAuftragGesamt[i] = new TSPS_Daten_DWord();
                StueckAuftragSchicht[i] = new TSPS_Daten_DWord();
                StueckSchicht[i] = new TSPS_Daten_DWord();
                Betriebsstunden[i] = new TSPS_Daten_DWord();
                Taktzeit[i] = new TSPS_Daten_DWord();
                LaufzeitGes[i] = new TSPS_Daten_DWord();
                LaufzeitSchicht[i] = new TSPS_Daten_DWord();
                StueckPruefGesamt[i] = new TSPS_Daten_DWord();
                StueckPruefAuftragGesamt[i] = new TSPS_Daten_DWord();
                StueckPruefAuftragSchicht[i] = new TSPS_Daten_DWord();
                StueckPruefSchicht[i] = new TSPS_Daten_DWord();
                StueckPackGesamt[i] = new TSPS_Daten_DWord();
                StueckPackAuftragGesamt[i] = new TSPS_Daten_DWord();
                StueckPackAuftragSchicht[i] = new TSPS_Daten_DWord();
                StueckPackSchicht[i] = new TSPS_Daten_DWord();
                Terminal_AuftragNr[i] = new TSPS_Daten_Word();
                SPC_Signal[i] = new TSPS_Daten_DWord_Dyn();
                Maschinen_Zustand[i] = new TSPS_Daten_Word();
                Terminal_Einheit[i] = new TSPS_Daten_Word();
                Terminal_StoerKommtGeht[i] = new TSPS_Daten_Word();
                Terminal_Stoer_Nr[i] = new TSPS_Daten_Word();
                Terminal_Still_Stoer[i] = new TSPS_Daten_Word();
                Terminal_Etikett[i] = new TSPS_Daten_Word();
                Programm_Nr[i] = new TSPS_Daten_Word();
                Terminal_AuftragNr_ASCII[i] = new TSPS_Daten_Word();
                BCD[i] = new TSPS_Daten_Byte();
                StillstandNr_SPS[i] = new TSPS_Daten_DWord();
                StillstandNr_SPS_Save[i] = new TSPS_Daten_DWord();
                Job_Stueckzahl[i] = new TSPS_Daten_Byte();
                BCD_Read[i] = new TSPS_Daten_Bool();
                HandAuto[i] = new TSPS_Daten_Bool();
                MaschProgrammbetrieb[i] = new TSPS_Daten_Bool();
                Auftrag_Freigabe[i] = new TSPS_Daten_Bool();
                Programm_Start[i] = new TSPS_Daten_Bool();
                Programm_Ende[i] = new TSPS_Daten_Bool();
                Terminal_Menge_Gebucht[i] = new TSPS_Daten_Bool();
                Terminal_Stillstand_Gebucht[i] = new TSPS_Daten_Bool();
                Vorrichtung[i] = new TSPS_Daten_Bool();
                AUTOAUSSCHUSS_AUFTRAG[i] = new TSPS_Daten_DWord();
                AUTOAUSSCHUSS_SCHICHT[i] = new TSPS_Daten_DWord();
                AUTOAUSSCHUSS_AUFTRAGSCHICHT[i] = new TSPS_Daten_DWord();
            }

            // Initialize barcode arrays
            for (int i = 0; i <= MAX_BARCODE; i++)
            {
                Barcode[i] = new TSPS_Daten_Word();
                Barcode_2[i] = new TSPS_Daten_Word();
                Barcode_3[i] = new TSPS_Daten_Word();
            }

            // Load configuration from CO_Setup2
            LoadConfiguration();
        }

        /// <summary>
        /// Load configuration from CO_Setup2
        /// </summary>
        private static void LoadConfiguration()
        {
            try
            {
                // These would be loaded from the database or configuration files
                // For now, set some reasonable defaults
                Anzahl_Masch = CO_Setup2.TCO_Setup.GetParamInt(null, "Anzahl_Maschinen", 50);
                Shift_Model = CO_Setup2.TCO_Setup.GetParamInt(null, "Shift_Model", 3);
                SchichtDauer = CO_Setup2.TCO_Setup.GetParamInt(null, "SchichtDauer", 480); // 8 hours in minutes
                
                // Load boolean flags
                Pruefen = CO_Setup2.TCO_Setup.GetParamBool(null, "Pruefen");
                Packen = CO_Setup2.TCO_Setup.GetParamBool(null, "Packen");
                Verpackt_Barcode = CO_Setup2.TCO_Setup.GetParamBool(null, "Verpackt_Barcode");
                Verpackt_aus_Ausschuss = CO_Setup2.TCO_Setup.GetParamBool(null, "Verpackt_aus_Ausschuss");
                SPC = CO_Setup2.TCO_Setup.GetParamBool(null, "SPC");
                halbautomatik = CO_Setup2.TCO_Setup.GetParamBool(null, "halbautomatik");
                werkzeugverwaltung = CO_Setup2.TCO_Setup.GetParamBool(null, "werkzeugverwaltung");
                KavitaetFromSPS = CO_Setup2.TCO_Setup.GetParamBool(null, "KavitaetFromSPS");
                Active_Alarming = CO_Setup2.TCO_Setup.GetParamBool(null, "Active_Alarming");
                
                // Load time constants
                Uberwachungszeit_Minuten = CO_Setup2.TCO_Setup.GetParamInt(null, "Ueberwachungszeit_Minuten", 30);
                Warmtrennen_Minuten = CO_Setup2.TCO_Setup.GetParamInt(null, "Warmtrennen_Minuten", 15);
                Ruestzeit_Minuten = CO_Setup2.TCO_Setup.GetParamInt(null, "Ruestzeit_Minuten", 10);
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error loading DBMain configuration: " + ex.Message, 0);
            }
        }

        // ========================================================================
        // Utility Functions
        // ========================================================================
        
        /// <summary>
        /// Get shift duration in minutes
        /// </summary>
        public static int GetSchichtDauer(int Schicht)
        {
            // This would return the duration of the specified shift
            // For now, return the configured shift duration
            return SchichtDauer;
        }

        /// <summary>
        /// Get shift number for a given time
        /// </summary>
        public static int GetSchichtNr(double Zeit)
        {
            double frac = MainDLL.Frac(Zeit);
            
            if (Shift_Model == 2) // 2-shift model
            {
                if (frac >= ArbeitGlobals.Schicht1 && frac < ArbeitGlobals.Schicht2)
                    return 1;
                else if (frac >= ArbeitGlobals.Schicht2 || frac < ArbeitGlobals.Schicht1)
                    return 2;
                else
                    return 1;
            }
            else // 3-shift model
            {
                if (frac >= ArbeitGlobals.Schicht1 && frac < ArbeitGlobals.Schicht2)
                    return 1;
                else if (frac >= ArbeitGlobals.Schicht2 && frac < ArbeitGlobals.Schicht3)
                    return 2;
                else
                    return 3;
            }
        }
    }
}