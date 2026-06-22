// <summary>
// Arbeit.cs - Translation of arbeit.pas
// Main work/order processing module
// </summary>

using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Common;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Threading;

namespace INCLService_CSharp
{
    // ========================================================================
    // Record Types from arbeit.pas
    // ========================================================================

    /// <summary>
    /// Cavity change record
    /// </summary>
    public class TCavChange
    {
        public string BetriebsauftragNr { get; set; } = string.Empty;
        public DateTime Datum { get; set; } = DateTime.MinValue;
        public int Alt { get; set; } = 0;
        public int Neu { get; set; } = 0;
        public int Produziert { get; set; } = 0;
        public int Schusszaehler { get; set; } = 0;
    }

    /// <summary>
    /// Order record
    /// </summary>
    public class TAuftrag
    {
        public string BetriebsauftragNr { get; set; } = string.Empty;
        public string BetriebsauftragNr_Alt { get; set; } = string.Empty;
        public string AuftragNr { get; set; } = string.Empty;
        public string Bezeichnung { get; set; } = string.Empty;
        public string Zustaendig { get; set; } = string.Empty;
        public string Signal { get; set; } = string.Empty;
        public int Sollwert { get; set; } = 0;
        public int SollwertOffset { get; set; } = 0;
        public int Istwert { get; set; } = 0;
        public int Ist_PRZ { get; set; } = 0;
        public int Ausschuss { get; set; } = 0;
        public int Verpackt { get; set; } = 0;
        public int Anfahrausschuss { get; set; } = 0;
        public int Vorwarnung { get; set; } = 0;
        public bool Erzeugt { get; set; } = false;
        public bool VorwarnungErzeugt { get; set; } = false;
        public short Stat { get; set; } = 0;
        public int Solltakt { get; set; } = 0;
        public DateTime StartDatum { get; set; } = DateTime.MinValue;
        public DateTime EndeDatum { get; set; } = DateTime.MinValue;
        public string EndeDatumSTR { get; set; } = string.Empty;
        public double LTSOLL { get; set; } = 0;
        public double LTIST { get; set; } = 0;
        public double LT1 { get; set; } = 0;
        public double LT2 { get; set; } = 0;
        public int Werkzeug { get; set; } = 0;
        public string WerkzeugNr { get; set; } = string.Empty;
        public int WerkzeugMerker { get; set; } = 0;
        public int IstStandzeit { get; set; } = 0;
        public int Einsatzdauer { get; set; } = 0;
        public bool HalbAuto { get; set; } = false;
        public int Kopfgroesse { get; set; } = 0;
        public int KAVITAET_SOLL { get; set; } = 0;
        public int InPause { get; set; } = 0;
        public int Var_Kavitaet { get; set; } = 0;
        public int StueckSchicht { get; set; } = 0;
        public string Schwesterauftrag { get; set; } = string.Empty;
        public string Kunde { get; set; } = string.Empty;
        public string Form { get; set; } = string.Empty;
        public int Programm_Nr { get; set; } = 0;
        public bool MasterAuftrag { get; set; } = false;
        public double PersonalZeit { get; set; } = 0;
        public int Optimiert { get; set; } = 0;
        public int OptimiertAktuell { get; set; } = 0;
        public int ImStatusOptimieren { get; set; } = 0;
        public int Packgroesse { get; set; } = 0;
        public int PALETTENGROESSE { get; set; } = 0;
        public int SchichtLaufzeit { get; set; } = 0;
        public int planzykluszeit { get; set; } = 0;
        public int ausschussquote { get; set; } = 0;
        public int SollSpannzeitStk { get; set; } = 0;
        public int SollSpannzeitGes { get; set; } = 0;
        public string InterBezeichnung { get; set; } = string.Empty;
        public TCavChange LetzerKavWechsel { get; set; } = new TCavChange();
        public bool WasReset { get; set; } = false;
        public int SchichtAuftragsLaufzeit { get; set; } = 0;
        public int GesamtLaufzeit { get; set; } = 0;
        public string BaNrLaufzeit { get; set; } = string.Empty;
        public bool Mustern { get; set; } = false;
    }

    /// <summary>
    /// BDE (Betriebsdatenerfassung) record
    /// </summary>
    public class TBDE
    {
        public string Bezeichnung { get; set; } = string.Empty;
        public string Zustaendig { get; set; } = string.Empty;
        public string Signal { get; set; } = string.Empty;
        public int Sollwert { get; set; } = 0;
        public int Istwert { get; set; } = 0;
        public int Ist_PRZ { get; set; } = 0;
        public int Vorwarnung { get; set; } = 0;
        public bool Erzeugt { get; set; } = false;
        public bool VorwarnungErzeugt { get; set; } = false;
    }

    /// <summary>
    /// TPM (Total Productive Maintenance) record
    /// </summary>
    public class TTPM
    {
        public bool Stillstand { get; set; } = false;
        public string Fehlercode { get; set; } = string.Empty;
        public int Gebucht { get; set; } = 0;
    }

    /// <summary>
    /// Main Includis record - represents machine state and data
    /// </summary>
    public class TIncludis
    {
        public string Lizenz { get; set; } = string.Empty;
        public string Maschine { get; set; } = string.Empty;
        public string KURZKENNUNG { get; set; } = string.Empty;
        public string MaschNr { get; set; } = string.Empty;
        public string MaschNrEcht { get; set; } = string.Empty;
        public int SORT_MASCHPANEL { get; set; } = 0;
        public bool MaschAktiv { get; set; } = false;
        public short Datenblock { get; set; } = 0;
        public TAuftrag Auftrag { get; set; } = new TAuftrag();
        public int InventarNr { get; set; } = 0;
        public bool IstArchiviert { get; set; } = false;
        public bool Masch_Warmtrennen { get; set; } = false;
        public bool Prod_Gleich_Pack { get; set; } = false;
        public TBDE BDE { get; set; } = new TBDE();
        public int Kopfgroesse { get; set; } = 0;
        public int Packgroesse { get; set; } = 0;
        public int PruefPack { get; set; } = 0;
        public int Pruefstation { get; set; } = 0;
        public int Betriebsstunden { get; set; } = 0;
        public int IstTakt { get; set; } = 0;
        public int Solltakt { get; set; } = 0;
        public int LaufzeitGes { get; set; } = 0;
        public int LaufzeitSchicht { get; set; } = 0;
        public int Zustand { get; set; } = 0;
        public int ZustandAlt { get; set; } = 0;
        public int Schicht { get; set; } = 0;
        public int AusschussSchicht { get; set; } = 0;
        public int AusschussAuftragSchicht { get; set; } = 0;
        public int StueckAuftragGesamt { get; set; } = 0;
        public int StueckPruefAuftragGesamt { get; set; } = 0;
        public int StueckPackAuftragGesamt { get; set; } = 0;
        public int StueckAuftragAlt { get; set; } = 0;
        public int StueckSchicht { get; set; } = 0;
        public int StueckPruefSchicht { get; set; } = 0;
        public int StueckPackSchicht { get; set; } = 0;
        public int StueckAuftragSchicht { get; set; } = 0;
        public int StueckPruefAuftragSchicht { get; set; } = 0;
        public int StueckPackAuftragSchicht { get; set; } = 0;
        public int StueckAuftragSchichtAlt { get; set; } = 0;
        public int StueckAuftragSchicht_SPS { get; set; } = 0;
        public int KARTONS { get; set; } = 0;
        public int PALETTEN { get; set; } = 0;
        public double Nutzung { get; set; } = 0;
        public double Qualitaet { get; set; } = 0;
        public double Leistung { get; set; } = 0;
        public double Effektivitaet { get; set; } = 0;
        public bool StueckGeaendert { get; set; } = false;
        public bool HandAuto { get; set; } = false;
        public bool BCD_Read { get; set; } = false;
        public short BCDCode { get; set; } = 0;
        public bool RuestzeitVorbei { get; set; } = false;
        public int RuestzeitIST { get; set; } = 0;
        public DateTime MaschLaeuftZeit { get; set; } = DateTime.MinValue;
        public short MaschZustandBeiRuesten { get; set; } = 0;
        public int TaktLogMerker { get; set; } = 0;
        public int ArtikelZyklus { get; set; } = 0;
        public int MaschinenZaehler { get; set; } = 0;
        public int Stops { get; set; } = 0;
        public int Analagenausfall { get; set; } = 0;
        public int Ruesten { get; set; } = 0;
        public int Logistik { get; set; } = 0;
        public int NichtGebucht { get; set; } = 0;
        public int Geplant { get; set; } = 0;
        public int Ungeplant { get; set; } = 0;
        public int Sollaufzeit { get; set; } = 0;
        public int IstLaufZeit { get; set; } = 0;
        public string Einheit { get; set; } = string.Empty;
        public bool AutoRuesten { get; set; } = false;
        public double AutoRuestZeit { get; set; } = 0;
        public double AutoRuestStart { get; set; } = 0;
        public int MaschinenTyp { get; set; } = 0;
        public bool isArbeitefrei { get; set; } = false;
        public bool Maschine_geblockt { get; set; } = false;
        public int Heizungsdauer { get; set; } = 0;
        public bool SPC_Aktiv { get; set; } = false;
        public int IstSpannzeitStk { get; set; } = 0;
        public int IstSpannzeitGes { get; set; } = 0;
        public int SpannzeitToleranz { get; set; } = 0;
        public DateTime LetzterMaschinenStart { get; set; } = DateTime.MinValue;
        public DateTime LetzterMaschinenStop { get; set; } = DateTime.MinValue;
        public double LaufzeitInZustand { get; set; } = 0;
        public double StillstandInZustand { get; set; } = 0;
        public DateTime LetzterAuftragsZustandWechsel { get; set; } = DateTime.MinValue;
        public bool MaschineLaeuft { get; set; } = false;
        public int RuestZustand { get; set; } = 0;
        public int Ruestgrund { get; set; } = 0;
        public double TmpLaufzeitInZustand { get; set; } = 0;
        public double TmpStillstandInZustand { get; set; } = 0;
        public double TmpLaufzeitInZustandSchicht { get; set; } = 0;
        public double TmpStillstandInZustandSchicht { get; set; } = 0;
        public DateTime TmpLastZustandCheck { get; set; } = DateTime.MinValue;
        public bool UnterauftragVorhanden { get; set; } = false;
        public int LetzterZyklusZaehler { get; set; } = 0;
        public int AktuellerZyklusZaehler { get; set; } = 0;
        public int ZyklenAuftragGesamt { get; set; } = 0;
        public int ZyklenAuftragSchicht { get; set; } = 0;
        public double TaktToleranzPlus { get; set; } = 0;
        public double TaktToleranzMinus { get; set; } = 0;
        public int SpindelOvr { get; set; } = 0;
        public int VorschubOvr { get; set; } = 0;
        public bool StueckzahlDirekt { get; set; } = false;
        public int CurrentStillNr { get; set; } = 0;
        public bool RoteLampe { get; set; } = false;
        public bool GutVonBus { get; set; } = false;
        public bool KombiSeparat { get; set; } = false;
        public int ZyklenNeu { get; set; } = 0;
        public int ZyklusLast { get; set; } = 0;
        public int ZyklenDiff { get; set; } = 0;
        public int ZyklenAll { get; set; } = 0;
        public DateTime ZyklusLastZeitpunkt { get; set; } = DateTime.MinValue;
        public bool MusternAktiv { get; set; } = false;
    }

    /// <summary>
    /// Machine state record
    /// </summary>
    public class TMaschZustand
    {
        public string MaschNr { get; set; } = string.Empty;
        public int Zustand { get; set; } = 0;
    }

    /// <summary>
    /// Downtime record
    /// </summary>
    public class TStillstand
    {
        public int Stillstandnr { get; set; } = 0;
        public string Bezeichnung { get; set; } = string.Empty;
        public int Aktion { get; set; } = 0;
        public int Gruppe { get; set; } = 0;
        public bool Geplant { get; set; } = false;
    }

    /// <summary>
    /// Signal record
    /// </summary>
    public class TSignal
    {
        public int SignalNr { get; set; } = 0;
        public int SignalArt { get; set; } = 0;
    }

    /// <summary>
    /// Machine signal record
    /// </summary>
    public class TMSignal
    {
        public int Nr { get; set; } = 0;
        public int MaschNr { get; set; } = 0;
        public int SignalNr { get; set; } = 0;
    }

    /// <summary>
    /// Machine record
    /// </summary>
    public class TMaschine
    {
        public int MaschNr { get; set; } = 0;
        public string Lizenz { get; set; } = string.Empty;
    }

    /// <summary>
    /// Shift type record
    /// </summary>
    public class TShiftTypeRec
    {
        public string ShiftType { get; set; } = string.Empty;
        public int LastTruncDate { get; set; } = 0;
        public int LastShift { get; set; } = 0;
        public DateTime LastCall { get; set; } = DateTime.MinValue;
    }

    // ========================================================================
    // Global Variables
    // ========================================================================

    public static class ArbeitGlobals
    {
        // Arrays
        public static List<TIncludis> Includis { get; set; } = new List<TIncludis>();
        public static string SQLStr { get; set; } = string.Empty;
        public static string SQLCountSTR { get; set; } = string.Empty;

        public static bool Vor_Schichtwechsel { get; set; } = false;
        public static bool Nach_Schichtwechsel { get; set; } = false;
        public static bool Vor_Werksplanung { get; set; } = false;

        public static List<TMaschZustand> MaschZustand { get; set; } = new List<TMaschZustand>();
        public static List<TStillstand> Stillstand { get; set; } = new List<TStillstand>();

        public static bool First { get; set; } = false;

        public static double vorSchicht1 { get; set; } = 0;
        public static double vorSchicht2 { get; set; } = 0;
        public static double vorSchicht3 { get; set; } = 0;
        public static double vorSchicht0 { get; set; } = 0;
        public static double Schicht1 { get; set; } = 0;
        public static double Schicht2 { get; set; } = 0;
        public static double Schicht3 { get; set; } = 0;
        public static double Schicht0 { get; set; } = 0;
        public static int DSchicht1 { get; set; } = 0;
        public static int DSchicht2 { get; set; } = 0;
        public static int DSchicht3 { get; set; } = 0;
        public static int TimeZone { get; set; } = 0;

        public static int SchichtSpeicher { get; set; } = 0;
        public static bool VerpacktAusAusschussAktiv { get; set; } = false;

        public static List<TSignal> Signal { get; set; } = new List<TSignal>();
        public static List<TMSignal> MSignal { get; set; } = new List<TMSignal>();
        public static List<TMaschine> Maschine { get; set; } = new List<TMaschine>();

        public static TShiftTypeRec[] SchichtTypArray { get; set; } = new TShiftTypeRec[DBMain.Max_ANZAHL + 1];
        public static int DebugStage { get; set; } = 0;
    }

    // ========================================================================
    // Function Declarations
    // ========================================================================

    public static class ArbeitFunctions
    {
        // Main procedures
        public static void CCC_Init()
        {
            ArbeitImplementation.CCC_Init_Implementation();
        }

        public static void CCC_Daten_Aktualisieren()
        {
            ArbeitImplementation.CCC_Daten_Aktualisieren_Implementation();
        }

        public static void CCC_Job_Auftrag()
        {
            ArbeitImplementation.CCC_Job_Auftrag_Implementation();
        }

        public static void CCC_BDE_Auftrag()
        {
            ArbeitImplementation.CCC_BDE_Auftrag_Implementation();
        }

        public static void CCC_Daten_Schreiben()
        {
            ArbeitImplementation.CCC_Daten_Schreiben_Implementation();
        }

        public static void CCC_Zeiten_Aufrunden()
        {
            ArbeitImplementation.CCC_Zeiten_Aufrunden_Implementation();
        }

        // Additional CCC functions
        public static void CCC_TPM_BCD_Meldung()
        {
            ArbeitImplementation.CCC_TPM_BCD_Meldung_Implementation();
        }

        public static void CCC_Auftrag_Starten_BCDCode(string Lizenz, bool Ruesten)
        {
            ArbeitImplementation.CCC_Auftrag_Starten_BCDCode_Implementation(Lizenz, Ruesten);
        }

        public static void CCC_TPM_Stillstand_Check()
        {
            ArbeitImplementation.CCC_TPM_Stillstand_Check_Implementation();
        }

        public static void CCC_CheckRuestprot_Arbeitsfrei()
        {
            ArbeitImplementation.CCC_CheckRuestprot_Arbeitsfrei_Implementation();
        }

        public static void CCC_CheckPause()
        {
            ArbeitImplementation.CCC_CheckPause_Implementation();
        }

        public static void CCC_RoteLampeCheckAus(string Lizenz)
        {
            ArbeitImplementation.CCC_RoteLampeCheckAus_Implementation(Lizenz);
        }

        public static void CCC_CheckStatusTPM_Stillog()
        {
            ArbeitImplementation.CCC_CheckStatusTPM_Stillog_Implementation();
        }

        public static void CCC_TPM_Zustandswechsel(string MaschNr, int Datenblock, int ZustandAlt, int ZustandNeu, 
            string Schicht, int Schuss, int Prod, bool AfGesperrt)
        {
            ArbeitImplementation.CCC_TPM_Zustandswechsel_Implementation(MaschNr, Datenblock, ZustandAlt, ZustandNeu, 
                Schicht, Schuss, Prod, AfGesperrt);
        }

        public static void CCC_MDEWerte_fuellen()
        {
            ArbeitImplementation.CCC_MDEWerte_fuellen_Implementation();
        }

        public static void CCC_MDE_Soll_Ist_Vergleich()
        {
            ArbeitImplementation.CCC_MDE_Soll_Ist_Vergleich_Implementation();
        }

        public static void CCC_Telegramm_Auswerten()
        {
            ArbeitImplementation.CCC_Telegramm_Auswerten_Implementation();
        }

        public static void CCC_Barcode_auswerten(string BC1, string BC2, string BC3)
        {
            ArbeitImplementation.CCC_Barcode_auswerten_Implementation(BC1, BC2, BC3);
        }

        public static void CCC_Material_ausbuchen(string MaterialEAN, int Menge, string Bedienernr)
        {
            ArbeitImplementation.CCC_Material_ausbuchen_Implementation(MaterialEAN, Menge, Bedienernr);
        }

        public static void CCC_Check_TerminOrder()
        {
            ArbeitImplementation.CCC_Check_TerminOrder_Implementation();
        }

        public static void CCC_AuftragAutomatikStart()
        {
            ArbeitImplementation.CCC_AuftragAutomatikStart_Implementation();
        }

        public static void CCC_AuftragAutomatikStartVariabel()
        {
            ArbeitImplementation.CCC_AuftragAutomatikStartVariabel_Implementation();
        }

        public static void CCC_UeberwachungszeitBerechnen(int MaschNr)
        {
            ArbeitImplementation.CCC_UeberwachungszeitBerechnen_Implementation(MaschNr);
        }

        public static string CCC_GetWerkzeugNr(int Schluessel)
        {
            return ArbeitImplementation.CCC_GetWerkzeugNr_Implementation(Schluessel);
        }

        public static void CCC_Job_erzeugen(CO_Query Q, string Lizenz, string Bezeichnung, string Quelle, 
            string Signal, string Zustaendig, string Sollwert, string Vorwarnung, 
            bool VorwarnungBool, bool RoteLampeAn)
        {
            ArbeitImplementation.CCC_Job_erzeugen_Implementation(Q, Lizenz, Bezeichnung, Quelle, 
                Signal, Zustaendig, Sollwert, Vorwarnung, VorwarnungBool, RoteLampeAn);
        }

        // Additional CCC functions from arbeit.pas
        public static void CCC_FehlerNr_auswertung()
        {
            ArbeitImplementation.CCC_FehlerNr_auswertung_Implementation();
        }

        public static void CCC_FehlerNr_Check()
        {
            ArbeitImplementation.CCC_FehlerNr_Check_Implementation();
        }

        public static void CCC_TPM_Signalauswertung()
        {
            ArbeitImplementation.CCC_TPM_Signalauswertung_Implementation();
        }

        public static void CCC_Schreibe_Signallog(bool Kommt, bool First, int FehlerNr, string Schicht, string Status)
        {
            ArbeitImplementation.CCC_Schreibe_Signallog_Implementation(Kommt, First, FehlerNr, Schicht, Status);
        }

        public static void CCC_Auftrag_Start_Barcode(byte BarCodeNr)
        {
            ArbeitImplementation.CCC_Auftrag_Start_Barcode_Implementation(BarCodeNr);
        }

        public static void CCC_Check_Auftrag_Freigabe()
        {
            ArbeitImplementation.CCC_Check_Auftrag_Freigabe_Implementation();
        }

        public static void CCC_Schreibe_Maschinen_Status()
        {
            ArbeitImplementation.CCC_Schreibe_Maschinen_Status_Implementation();
        }

        public static void CCC_Check_Menge_Gebucht()
        {
            ArbeitImplementation.CCC_Check_Menge_Gebucht_Implementation();
        }

        public static void CCC_Check_Terminal_Auftrag_Ende()
        {
            ArbeitImplementation.CCC_Check_Terminal_Auftrag_Ende_Implementation();
        }

        public static void CCC_Check_Terminal_Auftrag_Unterbrochen()
        {
            ArbeitImplementation.CCC_Check_Terminal_Auftrag_Unterbrochen_Implementation();
        }

        public static void CCC_Check_Terminal_Stillstand()
        {
            ArbeitImplementation.CCC_Check_Terminal_Stillstand_Implementation();
        }

        public static void CCC_Check_Warmtrennen()
        {
            ArbeitImplementation.CCC_Check_Warmtrennen_Implementation();
        }

        public static void CCC_Check_Job_Stueckzahl()
        {
            ArbeitImplementation.CCC_Check_Job_Stueckzahl_Implementation();
        }

        public static void CCC_Check_StillstandNr_SPS()
        {
            ArbeitImplementation.CCC_Check_StillstandNr_SPS_Implementation();
        }

        public static void CCC_QS_Jobs()
        {
            ArbeitImplementation.CCC_QS_Jobs_Implementation();
        }

        public static void CCC_A_Felder_Schicht_Berechnen2(CO_Query aQ1, CO_Query aQ2, CO_Query aU, double aSchichtstart, int aSchicht)
        {
            ArbeitImplementation.CCC_A_Felder_Schicht_Berechnen2_Implementation(aQ1, aQ2, aU, aSchichtstart, aSchicht);
        }

        public static void CCC_A_Felder_Schicht_Berechnen(CO_Query aQ1, CO_Query aQ2, CO_Query aU, double aSchichtstart, int aSchicht)
        {
            ArbeitImplementation.CCC_A_Felder_Schicht_Berechnen_Implementation(aQ1, aQ2, aU, aSchichtstart, aSchicht);
        }

        public static void CCC_TaktzeitIstSchreiben()
        {
            ArbeitImplementation.CCC_TaktzeitIstSchreiben_Implementation();
        }

        public static void CCC_Auto_Ruesten2()
        {
            ArbeitImplementation.CCC_Auto_Ruesten2_Implementation();
        }

        public static void CCC_InsertStillGehtEvent(string KeyNr)
        {
            ArbeitImplementation.CCC_InsertStillGehtEvent_Implementation(KeyNr);
        }

        public static void CCC_SchreibeSystemID()
        {
            ArbeitImplementation.CCC_SchreibeSystemID_Implementation();
        }

        public static bool CCC_CheckLicenses()
        {
            return ArbeitImplementation.CCC_CheckLicenses_Implementation();
        }

        public static void CCC_FolgeAuftrag_Starten()
        {
            ArbeitImplementation.CCC_FolgeAuftrag_Starten_Implementation();
        }

        public static void CCC_SetSchichtKonstante()
        {
            ArbeitImplementation.CCC_SetSchichtKonstante_Implementation();
        }

        public static void CCC_Verpackt_aus_Ausschuss_Berechnen()
        {
            ArbeitImplementation.CCC_Verpackt_aus_Ausschuss_Berechnen_Implementation();
        }

        public static void CCC_Maschinen_Wartung()
        {
            ArbeitImplementation.CCC_Maschinen_Wartung_Implementation();
        }

        public static void CCC_CheckBlock()
        {
            ArbeitImplementation.CCC_CheckBlock_Implementation();
        }

        public static void CCC_CheckBypass()
        {
            ArbeitImplementation.CCC_CheckBypass_Implementation();
        }

        public static void CCC_CheckUnterbrocheneAuftraege()
        {
            ArbeitImplementation.CCC_CheckUnterbrocheneAuftraege_Implementation();
        }

        public static double CCC_GetTPMSchichtAnfang(int Schicht, double DatumZeit)
        {
            return ArbeitImplementation.CCC_GetTPMSchichtAnfang_Implementation(Schicht, DatumZeit);
        }

        public static void CCC_Taktzeit_Aus_Stamm_Update()
        {
            ArbeitImplementation.CCC_Taktzeit_Aus_Stamm_Update_Implementation();
        }

        public static void CCC_JobSetupAndRestart(CO_Auftrag aCOAuftrag)
        {
            ArbeitImplementation.CCC_JobSetupAndRestart_Implementation(aCOAuftrag);
        }

        public static void CCC_Calc_R2_Times()
        {
            ArbeitImplementation.CCC_Calc_R2_Times_Implementation();
        }

        public static void CCC_AutoSetup2()
        {
            ArbeitImplementation.CCC_AutoSetup2_Implementation();
        }

        public static void CCC_Auto_Ruesten()
        {
            ArbeitImplementation.CCC_Auto_Ruesten_Implementation();
        }

        // Utility functions
        public static double GFloat(string H)
        {
            if (string.IsNullOrWhiteSpace(H))
                return 0;

            string S = H.Trim();

            try
            {
                // Handle comma as decimal separator
                if (S.Contains(','))
                {
                    if (CultureInfo.CurrentCulture.NumberFormat.NumberDecimalSeparator == ",")
                    {
                        return double.Parse(S, CultureInfo.CurrentCulture);
                    }
                    else
                    {
                        S = S.Replace(",", ".");
                        return double.Parse(S, CultureInfo.InvariantCulture);
                    }
                }
                
                // Handle dot as decimal separator
                if (S.Contains('.'))
                {
                    if (CultureInfo.CurrentCulture.NumberFormat.NumberDecimalSeparator == ".")
                    {
                        return double.Parse(S, CultureInfo.CurrentCulture);
                    }
                    else
                    {
                        S = S.Replace(".", CultureInfo.CurrentCulture.NumberFormat.NumberDecimalSeparator);
                        return double.Parse(S, CultureInfo.CurrentCulture);
                    }
                }
                
                return double.Parse(S, CultureInfo.InvariantCulture);
            }
            catch
            {
                try
                {
                    if (CultureInfo.CurrentCulture.NumberFormat.NumberDecimalSeparator == ",")
                    {
                        return double.Parse(S, CultureInfo.CurrentCulture);
                    }
                    else
                    {
                        S = S.Replace(",", CultureInfo.CurrentCulture.NumberFormat.NumberDecimalSeparator);
                        return double.Parse(S, CultureInfo.CurrentCulture);
                    }
                }
                catch
                {
                    MainDLL.SchreibeMeldung("Error GFloat (double.Parse) : " + S, 0);
                    return 0;
                }
            }
        }

        public static int Format_String(string Wert)
        {
            if (string.IsNullOrWhiteSpace(Wert))
                return 0;
            
            try
            {
                return int.Parse(Wert, CultureInfo.InvariantCulture);
            }
            catch
            {
                try
                {
                    return int.Parse(Wert, CultureInfo.CurrentCulture);
                }
                catch
                {
                    return 0;
                }
            }
        }

        public static void Pause(int Sek)
        {
            Thread.Sleep(Sek * 1000);
        }

        public static string GetMonat(DateTime Datum)
        {
            return Datum.ToString("MM");
        }

        public static string GetQuartal(DateTime Datum)
        {
            int month = Datum.Month;
            if (month <= 3) return "Q1";
            if (month <= 6) return "Q2";
            if (month <= 9) return "Q3";
            return "Q4";
        }

        public static string GetJahr(DateTime Datum)
        {
            return Datum.ToString("yyyy");
        }

        public static string GetKWStr(DateTime Datum)
        {
            CultureInfo ci = CultureInfo.CurrentCulture;
            int week = ci.Calendar.GetWeekOfYear(Datum, CalendarWeekRule.FirstDay, DayOfWeek.Monday);
            return week.ToString("D2");
        }

        public static string GetKW(DateTime Datum)
        {
            CultureInfo ci = CultureInfo.CurrentCulture;
            int week = ci.Calendar.GetWeekOfYear(Datum, CalendarWeekRule.FirstDay, DayOfWeek.Monday);
            return week.ToString();
        }

        public static DateTime N_o_w
        {
            get { return DateTime.Now; }
        }

        // Additional functions will be implemented in subsequent steps
        public static int CCC_GetMaschIndex(string Lizenz)
        {
            return ArbeitImplementation.CCC_GetMaschIndex(Lizenz);
        }

        public static int CCC_GetMaschZustand(string Lizenz)
        {
            return ArbeitImplementation.CCC_GetMaschZustand(Lizenz);
        }

        public static string CCC_GetMaschNrLizenz(string Lizenz)
        {
            return ArbeitImplementation.CCC_GetMaschNrLizenz(Lizenz);
        }

        public static string CCC_GetKennung(string MaschNr)
        {
            return ArbeitImplementation.CCC_GetKennung(MaschNr);
        }

        public static int GetSignalStillstand(int Datenblock)
        {
            throw new NotImplementedException("GetSignalStillstand not yet implemented");
        }

        public static int GetAktion(int Stillstandnr)
        {
            throw new NotImplementedException("GetAktion not yet implemented");
        }

        public static int GetDBNr(int SignalNr, int MaschNr)
        {
            throw new NotImplementedException("GetDBNr not yet implemented");
        }

        public static void LoadSignals(CO_Query Q)
        {
            throw new NotImplementedException("LoadSignals not yet implemented");
        }

        public static string GetSelectedMaschinen(CO_Query Q, string AndStr, string Feld, string Liste, int Style)
        {
            throw new NotImplementedException("GetSelectedMaschinen not yet implemented");
        }

        public static void Statistik_Berechnen()
        {
            throw new NotImplementedException("Statistik_Berechnen not yet implemented");
        }

        public static void GetPersonalNr_Signal()
        {
            throw new NotImplementedException("GetPersonalNr_Signal not yet implemented");
        }

        public static void GetAusschuss_Signal()
        {
            throw new NotImplementedException("GetAusschuss_Signal not yet implemented");
        }

        public static bool CheckCO_DatabaseConnect(CO_Database C, CO_Query Q, int LogId, string thread)
        {
            throw new NotImplementedException("CheckCO_DatabaseConnect not yet implemented");
        }

        public static void CCC_Proc_Ruesten_AutoBuchen()
        {
            throw new NotImplementedException("CCC_Proc_Ruesten_AutoBuchen not yet implemented");
        }
    }
}
