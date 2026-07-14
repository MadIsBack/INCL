using System;

namespace INCLUDIS.INCLServer.Cs.Models
{
    /// <summary>
    /// Portierung von TMaschine und TIncludis aus Arbeit.pas.
    /// Enthält Maschinen- und Includis-Daten.
    /// </summary>
    public class Maschine
    {
        public int MaschNr { get; set; }
        public string Lizenz { get; set; } = string.Empty;
    }

    /// <summary>
    /// Portierung von TMaschZustand aus Arbeit.pas.
    /// </summary>
    public class MaschZustand
    {
        public string MaschNr { get; set; } = string.Empty;
        public int Zustand { get; set; }
    }

    /// <summary>
    /// Portierung von TStillstand aus Arbeit.pas.
    /// </summary>
    public class Stillstand
    {
        public int Stillstandnr { get; set; }
        public string Bezeichnung { get; set; } = string.Empty;
        public int Aktion { get; set; }
        public int Gruppe { get; set; }
        public bool Geplant { get; set; }
    }

    /// <summary>
    /// Portierung von TSignal aus Arbeit.pas.
    /// </summary>
    public class Signal
    {
        public int SignalNr { get; set; }
        public int SignalArt { get; set; }
    }

    /// <summary>
    /// Portierung von TMSignal aus Arbeit.pas.
    /// </summary>
    public class MSignal
    {
        public int Nr { get; set; }
        public int MaschNr { get; set; }
        public int SignalNr { get; set; }
    }

    /// <summary>
    /// Portierung von TBDE aus Arbeit.pas.
    /// Enthält Betriebsdatenerfassungs-Daten.
    /// </summary>
    public class BDE
    {
        public string Bezeichnung { get; set; } = string.Empty;
        public string Zustaendig { get; set; } = string.Empty;
        public string Signal { get; set; } = string.Empty;
        public int Sollwert { get; set; }
        public int Istwert { get; set; }
        public int IstPRZ { get; set; }
        public int Vorwarnung { get; set; }
        public bool Erzeugt { get; set; }
        public bool VorwarnungErzeugt { get; set; }
    }

    /// <summary>
    /// Portierung von TTPM aus Arbeit.pas.
    /// </summary>
    public class TPMData
    {
        public bool Stillstand { get; set; }
        public string Fehlercode { get; set; } = string.Empty;
        public int Gebucht { get; set; }
    }

    /// <summary>
    /// Portierung von TShiftTypeRec aus Arbeit.pas.
    /// </summary>
    public class ShiftTypeRec
    {
        public string ShiftType { get; set; } = string.Empty;
        public int LastTruncDate { get; set; }
        public int LastShift { get; set; }
        public DateTime LastCall { get; set; }
    }

    /// <summary>
    /// Hauptklasse für Includis-Daten (portiert von TIncludis aus Arbeit.pas).
    /// Enthält alle relevanten Daten für eine Maschine.
    /// </summary>
    public class Includis
    {
        public string Lizenz { get; set; } = string.Empty;
        public string Maschine { get; set; } = string.Empty;
        public string KURZKENNUNG { get; set; } = string.Empty;
        public string MaschNr { get; set; } = string.Empty;
        public string MaschNrEcht { get; set; } = string.Empty;
        public int SORT_MASCHPANEL { get; set; }
        public bool MaschAktiv { get; set; }
        public short Datenblock { get; set; }
        public int InventarNr { get; set; }
        public bool IstArchiviert { get; set; }
        public bool MaschWarmtrennen { get; set; }
        public bool ProdGleichPack { get; set; }
        public int Kopfgroesse { get; set; } = 1;
        public int Packgroesse { get; set; } = 1;
        public int PruefPack { get; set; } // 1 = Prüfen und Packen; 4 = kein Prüfen, kein Packen
        public int Pruefstation { get; set; }
        public int Betriebsstunden { get; set; }
        public int IstTakt { get; set; }
        public int Solltakt { get; set; }
        public int LaufzeitGes { get; set; }
        public int LaufzeitSchicht { get; set; }
        public int Zustand { get; set; }
        public int ZustandAlt { get; set; }
        public int Schicht { get; set; }
        public int AusschussSchicht { get; set; }
        public int AusschussAuftragSchicht { get; set; }
        public int StueckAuftragGesamt { get; set; }
        public int StueckPruefAuftragGesamt { get; set; }
        public int StueckPackAuftragGesamt { get; set; }
        public int StueckAuftragAlt { get; set; }
        public int StueckSchicht { get; set; }
        public int StueckPruefSchicht { get; set; }
        public int StueckPackSchicht { get; set; }
        public int StueckAuftragSchicht { get; set; }
        public int StueckPruefAuftragSchicht { get; set; }
        public int StueckPackAuftragSchicht { get; set; }
        public int StueckAuftragSchichtAlt { get; set; }
        public int StueckAuftragSchichtSPS { get; set; }
        public int KARTONS { get; set; }
        public int PALETTEN { get; set; }
        public double Nutzung { get; set; }
        public double Qualitaet { get; set; }
        public double Leistung { get; set; }
        public double Effektivitaet { get; set; }
        public bool StueckGeaendert { get; set; }
        public bool HandAuto { get; set; } // True bei Halbautomatik
        public bool BCDRead { get; set; }
        public short BCDCode { get; set; }
        public bool RuestzeitVorbei { get; set; }
        public int RuestzeitIST { get; set; }
        public DateTime MaschLaeuftZeit { get; set; } // ZeitMerker für Zeit_zum_AutoStart
        public short MaschZustandBeiRuesten { get; set; }
        public int TaktLogMerker { get; set; }
        public int ArtikelZyklus { get; set; }
        public int MaschinenZaehler { get; set; }
        public int Stops { get; set; }
        public int Analagenausfall { get; set; }
        public int Ruesten { get; set; }
        public int Logistik { get; set; }
        public int NichtGebucht { get; set; }
        public int Geplant { get; set; }
        public int Ungeplant { get; set; }
        public int Sollaufzeit { get; set; }
        public int IstLaufZeit { get; set; }
        public string Einheit { get; set; } = string.Empty;
        public bool AutoRuesten { get; set; }
        public double AutoRuestZeit { get; set; }
        public double AutoRuestStart { get; set; }
        public int MaschinenTyp { get; set; }
        public bool IsArbeitsfrei { get; set; }
        public bool MaschineGeblockt { get; set; } // RP BLOCKSTILL
        public int Heizungsdauer { get; set; }
        public bool SPC_Aktiv { get; set; }
        public int IstSpannzeitStk { get; set; }
        public int IstSpannzeitGes { get; set; }
        public int SpannzeitToleranz { get; set; }
        public DateTime LetzterMaschinenStart { get; set; }
        public DateTime LetzterMaschinenStop { get; set; }
        public double LaufzeitInZustand { get; set; }
        public double StillstandInZustand { get; set; }
        public DateTime LetzterAuftragsZustandWechsel { get; set; }
        public bool MaschineLaeuft { get; set; } // Maschinenzustand unabhängig Rüsten
        public int RuestZustand { get; set; } // 0->kein Auftrag, 1->Rüsten 1, 2->Rüsten 2, 3->Auftrag läuft
        public int Ruestgrund { get; set; }
        public double TmpLaufzeitInZustand { get; set; }
        public double TmpStillstandInZustand { get; set; }
        public double TmpLaufzeitInZustandSchicht { get; set; }
        public double TmpStillstandInZustandSchicht { get; set; }
        public DateTime TmpLastZustandCheck { get; set; }
        public bool UnterauftragVorhanden { get; set; }
        public int LetzterZyklusZaehler { get; set; }
        public int AktuellerZyklusZaehler { get; set; }
        public int ZyklenAuftragGesamt { get; set; }
        public int ZyklenAuftragSchicht { get; set; }
        public double TaktToleranzPlus { get; set; }
        public double TaktToleranzMinus { get; set; }
        public int SpindelOvr { get; set; }
        public int VorschubOvr { get; set; }
        public bool StueckzahlDirekt { get; set; }
        public int CurrentStillNr { get; set; }
        public bool GutVonBus { get; set; }
        public bool KombiSeparat { get; set; }
        public int ZyklenNeu { get; set; }
        public int ZyklusLast { get; set; }
        public int ZyklenDiff { get; set; }
        public int ZyklenAll { get; set; }
        public DateTime ZyklusLastZeitpunkt { get; set; }
        public bool MusternAktiv { get; set; }

        // Referenzen auf andere Objekte
        public Auftrag Auftrag { get; set; } = new();
        public BDE BDE { get; set; } = new();
    }
}
