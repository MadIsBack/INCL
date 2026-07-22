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
    /// Äquivalent zu den Includis-Arrays in DBMain.pas
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
