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
    /// Maschinen-Daten
    /// Äquivalent zu den Includis-Arrays in DBMain.pas / arbeit.pas.
    /// Wird von CCC_Init aus der Tabelle 'Maschine' gefüllt.
    /// </summary>
    public class MaschinenDaten
    {
        public int Nr { get; set; } = 0;
        public string Lizenz { get; set; } = string.Empty;
        public bool IstArchiviert { get; set; } = false;
        public int StueckGesamt { get; set; } = 0;
        public int StueckAuftragGesamt { get; set; } = 0;
        public int StueckAuftragAlt { get; set; } = 0;
        public int DiffStueck { get; set; } = 0;
        public int StueckAuftragSchicht { get; set; } = 0;
        public int StueckSchicht { get; set; } = 0;
        public int Betriebsstunden { get; set; } = 0;
        public int Taktzeit { get; set; } = 0;
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
        public int Kopfgroesse { get; set; } = 1;

        // --- Von CCC_Init aus Tabelle 'Maschine' gefüllt (vgl. arbeit.pas CCC_Init) ---
        /// <summary>Kennung der Maschine (Maschine.Kennung)</summary>
        public string Maschine { get; set; } = string.Empty;
        /// <summary>Kurzbezeichnung der Maschine (Maschine.KURZKENNUNG)</summary>
        public string KURZKENNUNG { get; set; } = string.Empty;
        /// <summary>Maschinennummer als String (= Datenblock, Maschine.Datenblock)</summary>
        public string MaschNr { get; set; } = string.Empty;
        /// <summary>Echte Maschinennummer als String (Maschine.Maschnr)</summary>
        public string MaschNrEcht { get; set; } = string.Empty;
        /// <summary>Sortierung im Maschinenpanel (Maschine.SORT_MASCHPANEL)</summary>
        public int SORT_MASCHPANEL { get; set; } = 0;
        /// <summary>Automatisches Rüsten aktiv (Maschine.Autoruesten = 1)</summary>
        public bool AutoRuesten { get; set; } = false;
        /// <summary>Maschine aktiv (Maschine.MaschAktiv &lt;&gt; 0)</summary>
        public bool MaschAktiv { get; set; } = false;
        /// <summary>Datenblock der Maschine (Maschine.Datenblock)</summary>
        public int Datenblock { get; set; } = 0;
        /// <summary>Packgröße (Maschine.Packgroesse)</summary>
        public int Packgroesse { get; set; } = 1;
        /// <summary>Warmtrennen aktiv (Maschine.Warmtrennen &lt;&gt; 0)</summary>
        public bool Masch_Warmtrennen { get; set; } = false;
        /// <summary>Produktion gleich Pack (Maschine.Prod_Gleich_Pack &lt;&gt; 0)</summary>
        public bool Prod_Gleich_Pack { get; set; } = false;
        /// <summary>Zyklenzähler letzter Stand (Maschine.zyklenlast)</summary>
        public int ZyklusLast { get; set; } = 0;
        /// <summary>Zeitpunkt des letzten Zyklus (Maschine.zyklastdatumzeit, TDateTime als Float)</summary>
        public double ZyklusLastZeitpunkt { get; set; } = 0;
        /// <summary>Gesamte Zyklen (Maschine.zyklenall)</summary>
        public int ZyklenAll { get; set; } = 0;
        /// <summary>Maschinentyp / manuelle Buchung (Maschine.manuelle_buchung)</summary>
        public int MaschinenTyp { get; set; } = 0;
        /// <summary>Inventarnummer (Maschine.InventarNr bei Barcode-Auftragsstart, sonst Index)</summary>
        public int InventarNr { get; set; } = 0;
        /// <summary>Gut vom Bus (Maschine.gut_von_bus = 1)</summary>
        public bool GutVonBus { get; set; } = false;
        /// <summary>Kombination separat buchen (Maschine.kombi_separat = 1)</summary>
        public bool KombiSeparat { get; set; } = false;
        /// <summary>Spannzeit-Toleranz (Maschine.spannzeittol)</summary>
        public int SpannzeitToleranz { get; set; } = 0;
        /// <summary>Prüfstation (abgeleitet aus Maschine.Station: einfach/zweifach/dreifach)</summary>
        public int Pruefstation { get; set; } = 1;
        /// <summary>Maschine ist blockiert (TPM-Blockstillstand oder Bypass)</summary>
        public bool Maschine_geblockt { get; set; } = false;
        /// <summary>Direkte Stückzahlbuchung (Maschine.stueckzahldirekt = 1)</summary>
        public bool StueckzahlDirekt { get; set; } = false;
        /// <summary>Mustern aktiv (PDE.Mustern = 1)</summary>
        public bool MusternAktiv { get; set; } = false;
        /// <summary>Artikelzyklus für Taktberechnung (Taktoption.Artikelzyklus)</summary>
        public int ArtikelZyklus { get; set; } = 100;
        /// <summary>Soll-Takt (PDE.Taktzeit)</summary>
        public int Solltakt { get; set; } = 0;
        /// <summary>Ist-Takt</summary>
        public int IstTakt { get; set; } = 0;
        /// <summary>Nutzungsgrad in Prozent</summary>
        public int Nutzung { get; set; } = 0;
        /// <summary>Leistungsgrad in Prozent</summary>
        public int Leistung { get; set; } = 0;
        /// <summary>Qualitätsgrad in Prozent</summary>
        public int Qualitaet { get; set; } = 0;
        /// <summary>Effektivität in Prozent</summary>
        public int Effektivitaet { get; set; } = 0;
        /// <summary>Prüf-Packgröße (PDE.Grundeinstellung)</summary>
        public int PruefPack { get; set; } = 0;

        // --- Verknüpfte Datenstrukturen ---
        /// <summary>Aktueller Auftrag der Maschine (vgl. TAuftrag in Arbeit.pas)</summary>
        public Auftrag Auftrag { get; set; } = new Auftrag();
        /// <summary>BDE-Daten der Maschine (vgl. TBDE in Arbeit.pas)</summary>
        public BDE BDE { get; set; } = new BDE();
    }

    /// <summary>
    /// Stillstand-Definition (TPM_Stillstaende)
    /// Äquivalent zu TStillstand in arbeit.pas
    /// </summary>
    public class StillstandDefinition
    {
        public int Stillstandnr { get; set; } = 0;
        public string Bezeichnung { get; set; } = string.Empty;
        public int Aktion { get; set; } = 0;
        public int Gruppe { get; set; } = 0;
        public bool Geplant { get; set; } = false;
    }

    /// <summary>
    /// Maschinen-Zustand je Datenblock
    /// Äquivalent zu MaschZustand-Array in arbeit.pas
    /// </summary>
    public class MaschZustandItem
    {
        public string MaschNr { get; set; } = string.Empty;
        public int Zustand { get; set; } = -1;
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

        // Stillstand-Definitionen (TPM_Stillstaende) - Äquivalent zu Stillstand-Array in arbeit.pas
        public List<StillstandDefinition> Stillstaende { get; set; } = new List<StillstandDefinition>();
        // Maschinen-Zustände je Datenblock - Äquivalent zu MaschZustand-Array in arbeit.pas
        public List<MaschZustandItem> MaschZustand { get; set; } = new List<MaschZustandItem>();

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
    }
}
