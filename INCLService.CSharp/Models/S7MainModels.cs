using System;
using System.Collections.Generic;

namespace INCLService.CSharp.Models
{
    /// <summary>
    /// Signal-Maschine-Eintrag
    /// Äquivalent zu TSignalMaschineItem in Sprache_V63.pas
    /// </summary>
    public class SignalMaschineItem
    {
        public int Nr { get; set; } = 0;
        public int Istwert { get; set; } = 0;
        public string IstwertString { get; set; } = string.Empty;
        public int Maschnr { get; set; } = 0;
        public int Signalart { get; set; } = 0;
    }

    /// <summary>
    /// Liste von Signal-Maschine-Einträgen
    /// Äquivalent zu TSignalMaschineList in Sprache_V63.pas
    /// </summary>
    public class SignalMaschineList : List<SignalMaschineItem>
    {
        /// <summary>
        /// Gibt den Istwert für eine bestimmte Nr zurück
        /// </summary>
        public int GetIstwertByNr(int nr)
        {
            foreach (var item in this)
            {
                if (item.Nr == nr)
                {
                    return item.Istwert;
                }
            }
            return 0;
        }

        /// <summary>
        /// Gibt den Boolean-Wert für eine bestimmte Nr zurück
        /// </summary>
        public bool GetBoolByNr(int nr)
        {
            int wert = GetIstwertByNr(nr);
            return wert != 0;
        }

        /// <summary>
        /// Gibt das SignalMaschineItem für eine bestimmte Nr zurück
        /// </summary>
        public SignalMaschineItem GetNr(int nr)
        {
            foreach (var item in this)
            {
                if (item.Nr == nr)
                {
                    return item;
                }
            }
            return null;
        }
    }

    /// <summary>
    /// Letzter Kavitätswechsel - Äquivalent zu TCavChange in arbeit.pas
    /// </summary>
    public class CavChange
    {
        public double Datum { get; set; } = -1;
        public string BetriebsauftragNr { get; set; } = string.Empty;
        public int Alt { get; set; } = 0;
        public int Neu { get; set; } = 1;
        public int Produziert { get; set; } = 0;
        public int Schusszaehler { get; set; } = 0;
    }

    /// <summary>
    /// Auftragsdaten - Äquivalent zu TAuftrag in arbeit.pas
    /// Wird von CCC_Init aus der PDE-Tabelle gefüllt
    /// </summary>
    public class AuftragDaten
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
        public int Stat { get; set; } = -1;
        public int Solltakt { get; set; } = 0;
        public double StartDatum { get; set; } = 0;
        public double EndeDatum { get; set; } = 0;
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
        public int Kopfgroesse { get; set; } = 1;
        public int KAVITAET_SOLL { get; set; } = 1;
        public int InPause { get; set; } = 0;
        public int Var_Kavitaet { get; set; } = 1;
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
        public CavChange LetzerKavWechsel { get; set; } = new CavChange();
        public bool WasReset { get; set; } = false;
        public int SchichtAuftragsLaufzeit { get; set; } = 0;
        public int GesamtLaufzeit { get; set; } = 0;
        public string BaNrLaufzeit { get; set; } = string.Empty;
        public bool Mustern { get; set; } = false;
    }

    /// <summary>
    /// BDE-Daten - Äquivalent zu TBDE in arbeit.pas
    /// Wird von CCC_Init aus der MDE-Tabelle gefüllt
    /// </summary>
    public class BdeDaten
    {
        public string Bezeichnung { get; set; } = string.Empty;
        public string Zustaendig { get; set; } = string.Empty;
        public string Signal { get; set; } = string.Empty;
        public int Sollwert { get; set; } = 0;
        public int Vorwarnung { get; set; } = 0;
        public bool Erzeugt { get; set; } = false;
        public bool VorwarnungErzeugt { get; set; } = false;
    }

    /// <summary>
    /// Stillstandsdefinition - Äquivalent zu TStillstand in arbeit.pas
    /// Wird von CCC_Init aus der TPM_Stillstaende-Tabelle geladen
    /// </summary>
    public class StillstandDaten
    {
        public int Stillstandnr { get; set; } = 0;
        public string Bezeichnung { get; set; } = string.Empty;
        public int Aktion { get; set; } = 0;
        public int Gruppe { get; set; } = 0;
        public bool Geplant { get; set; } = false;
    }

    /// <summary>
    /// Maschinen-Daten
    /// Äquivalent zu TIncludis (Includis-Array) in arbeit.pas
    /// Wird von CCC_Init aus der Maschine-Tabelle initialisiert
    /// </summary>
    public class MaschinenDaten
    {
        public int Nr { get; set; } = 0;
        public string Lizenz { get; set; } = string.Empty;
        public string Maschine { get; set; } = string.Empty;
        public string KURZKENNUNG { get; set; } = string.Empty;
        public string MaschNr { get; set; } = string.Empty;
        public string MaschNrEcht { get; set; } = string.Empty;
        public int SORT_MASCHPANEL { get; set; } = 0;
        public bool MaschAktiv { get; set; } = false;
        public int Datenblock { get; set; } = 0;
        public AuftragDaten Auftrag { get; set; } = new AuftragDaten();
        public int InventarNr { get; set; } = 0;
        public bool IstArchiviert { get; set; } = false;
        public bool Masch_Warmtrennen { get; set; } = false;
        public bool Prod_Gleich_Pack { get; set; } = false;
        public BdeDaten BDE { get; set; } = new BdeDaten();
        public int Kopfgroesse { get; set; } = 1;
        public int Packgroesse { get; set; } = 1;
        public int PruefPack { get; set; } = 1;
        public int Pruefstation { get; set; } = 1;
        public int StueckGesamt { get; set; } = 0;
        public int StueckAuftragGesamt { get; set; } = 0;
        public int StueckAuftragAlt { get; set; } = 0;
        public int DiffStueck { get; set; } = 0;
        public int StueckAuftragSchicht { get; set; } = 0;
        public int StueckSchicht { get; set; } = 0;
        public int Betriebsstunden { get; set; } = 0;
        public int Taktzeit { get; set; } = 0;
        public int IstTakt { get; set; } = 0;
        public int Solltakt { get; set; } = 0;
        public int LaufzeitGes { get; set; } = 0;
        public int LaufzeitSchicht { get; set; } = 0;
        public int StueckPruefGesamt { get; set; } = 0;
        public int StueckPruefAuftragGesamt { get; set; } = 0;
        public int StueckPruefAuftragSchicht { get; set; } = 0;
        public int StueckPruefSchicht { get; set; } = 0;
        public int StueckPackGesamt { get; set; } = 0;
        public int StueckPackAuftragGesamt { get; set; } = 0;
        public int StueckPackAuftragSchicht { get; set; } = 0;
        public int StueckPackSchicht { get; set; } = 0;
        public int MaschinenZustand { get; set; } = 0;
        public int TerminalAuftragNr { get; set; } = 0;
        public int TerminalAuftragNrASCII { get; set; } = 0;
        public int BCD { get; set; } = 0;
        public int StillstandNrSPS { get; set; } = 0;
        public bool StueckGeaendert { get; set; } = false;
        public double Nutzung { get; set; } = 0;
        public double Qualitaet { get; set; } = 0;
        public double Leistung { get; set; } = 0;
        public double Effektivitaet { get; set; } = 0;
        public bool AutoRuesten { get; set; } = false;
        public int MaschinenTyp { get; set; } = 0;
        public bool Maschine_geblockt { get; set; } = false;
        public bool StueckzahlDirekt { get; set; } = false;
        public bool GutVonBus { get; set; } = false;
        public bool KombiSeparat { get; set; } = false;
        public bool MusternAktiv { get; set; } = false;
        public int ArtikelZyklus { get; set; } = 100;
        public int ZyklusLast { get; set; } = 0;
        public double ZyklusLastZeitpunkt { get; set; } = 0;
        public int ZyklenAll { get; set; } = 0;
        public int SpannzeitToleranz { get; set; } = 0;
    }

    /// <summary>
    /// Barcode-Daten
    /// </summary>
    public class BarcodeDaten
    {
        public int DBNr { get; set; } = 0;
        public bool Istwert { get; set; } = false;
        public int Wert { get; set; } = 0;
    }

    /// <summary>
    /// S7Main-Datenmodell
    /// Enthält alle Daten, die in TS7Main verwaltet werden
    /// </summary>
    public class S7MainData
    {
        // Maschinen-Daten
        public List<MaschinenDaten> Includis { get; set; } = new List<MaschinenDaten>();
        public int AnzahlMasch { get; set; } = 0;
        // Stillstandsdefinitionen (aus TPM_Stillstaende)
        public List<StillstandDaten> Stillstaende { get; set; } = new List<StillstandDaten>();
        
        // Barcode-Daten
        public BarcodeDaten BarcodeGelesen { get; set; } = new BarcodeDaten();
        public BarcodeDaten BarcodeGelesen2 { get; set; } = new BarcodeDaten();
        public BarcodeDaten BarcodeGelesen3 { get; set; } = new BarcodeDaten();
        public List<BarcodeDaten> Barcode { get; set; } = new List<BarcodeDaten>();
        public List<BarcodeDaten> Barcode2 { get; set; } = new List<BarcodeDaten>();
        public List<BarcodeDaten> Barcode3 { get; set; } = new List<BarcodeDaten>();
        
        // Auftragsstart-Signale
        public BarcodeDaten AuftragStart1 { get; set; } = new BarcodeDaten();
        public BarcodeDaten AuftragStart2 { get; set; } = new BarcodeDaten();
        public BarcodeDaten AuftragStart3 { get; set; } = new BarcodeDaten();
        
        // Weitere Signale
        public BarcodeDaten TerminalMaschine { get; set; } = new BarcodeDaten();
        public BarcodeDaten ReparaturStartEnde { get; set; } = new BarcodeDaten();
        public BarcodeDaten TerminalEingabe { get; set; } = new BarcodeDaten();
        
        // Signal-Liste
        public SignalMaschineList SignalList { get; set; } = new SignalMaschineList();
        
        // Letzte Ausführungszeit
        public DateTime LastDate { get; set; } = DateTime.MinValue;
        // Erstlauf-Kennzeichen (First aus arbeit.pas)
        public bool First { get; set; } = true;
    }
}
