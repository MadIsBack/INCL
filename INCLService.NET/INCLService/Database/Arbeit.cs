namespace INCLService.Database;

public class TCavChange
{
    public string BetriebsauftragNr { get; set; } = string.Empty;
    public double Datum { get; set; }
    public int Alt { get; set; }
    public int Neu { get; set; }
    public int Produziert { get; set; }
    public int Schusszaehler { get; set; }
}

public class TBDE
{
    public string Bezeichnung { get; set; } = string.Empty;
    public string Zustaendig { get; set; } = string.Empty;
    public string Signal { get; set; } = string.Empty;
    public int Sollwert { get; set; }
    public int Istwert { get; set; }
    public int Ist_PRZ { get; set; }
    public int Vorwarnung { get; set; }
    public bool Erzeugt { get; set; }
    public bool VorwarnungErzeugt { get; set; }
}

public class TTPM
{
    public bool Stillstand { get; set; }
    public string Fehlercode { get; set; } = string.Empty;
    public int Gebucht { get; set; }
}

public class TAuftrag
{
    public string BetriebsauftragNr { get; set; } = string.Empty;
    public string BetriebsauftragNr_Alt { get; set; } = string.Empty;
    public string AuftragNr { get; set; } = string.Empty;
    public string Bezeichnung { get; set; } = string.Empty;
    public string Zustaendig { get; set; } = string.Empty;
    public string Signal { get; set; } = string.Empty;
    public int Sollwert { get; set; }
    public int SollwertOffset { get; set; }
    public int Istwert { get; set; }
    public int Ist_PRZ { get; set; }
    public int Ausschuss { get; set; }
    public int Verpackt { get; set; }
    public int Anfahrausschuss { get; set; }
    public int Vorwarnung { get; set; }
    public bool Erzeugt { get; set; }
    public bool VorwarnungErzeugt { get; set; }
    public short Stat { get; set; }
    public int Solltakt { get; set; }
    public double StartDatum { get; set; }
    public double EndeDatum { get; set; }
    public string EndeDatumSTR { get; set; } = string.Empty;
    public double LTSOLL { get; set; }
    public double LTIST { get; set; }
    public double LT1 { get; set; }
    public double LT2 { get; set; }
    public int Werkzeug { get; set; }
    public string WerkzeugNr { get; set; } = string.Empty;
    public int WerkzeugMerker { get; set; }
    public int IstStandzeit { get; set; }
    public int Einsatzdauer { get; set; }
    public bool HalbAuto { get; set; }
    public int Kopfgroesse { get; set; }
    public int KAVITAET_SOLL { get; set; }
    public int InPause { get; set; }
    public int Var_Kavitaet { get; set; }
    public int StueckSchicht { get; set; }
    public string Schwesterauftrag { get; set; } = string.Empty;
    public string Kunde { get; set; } = string.Empty;
    public string Form { get; set; } = string.Empty;
    public int Programm_Nr { get; set; }
    public bool MasterAuftrag { get; set; }
    public double PersonalZeit { get; set; }
    public int Optimiert { get; set; }
    public int OptimiertAktuell { get; set; }
    public int ImStatusOptimieren { get; set; }
    public int Packgroesse { get; set; }
    public int PALETTENGROESSE { get; set; }
    public int SchichtLaufzeit { get; set; }
    public int planzykluszeit { get; set; }
    public int ausschussquote { get; set; }
    public int SollSpannzeitStk { get; set; }
    public int SollSpannzeitGes { get; set; }
    public string InterBezeichnung { get; set; } = string.Empty;
    public TCavChange LetzerKavWechsel { get; set; } = new TCavChange();
    public bool WasReset { get; set; }
    public int SchichtAuftragsLaufzeit { get; set; }
    public int GesamtLaufzeit { get; set; }
    public string BaNrLaufzeit { get; set; } = string.Empty;
    public bool Mustern { get; set; }
}

public class TIncludis
{
    public string Lizenz { get; set; } = string.Empty;
    public string Maschine { get; set; } = string.Empty;
    public string KURZKENNUNG { get; set; } = string.Empty;
    public string MaschNr { get; set; } = string.Empty;
    public string MaschNrEcht { get; set; } = string.Empty;
    public int SORT_MASCHPANEL { get; set; }
    public bool MaschAktiv { get; set; }
    public short Datenblock { get; set; }
    public TAuftrag Auftrag { get; set; } = new TAuftrag();
    public int InventarNr { get; set; }
    public bool IstArchiviert { get; set; }
    public bool Masch_Warmtrennen { get; set; }
    public bool Prod_Gleich_Pack { get; set; }
    public TBDE BDE { get; set; } = new TBDE();
    public int Kopfgroesse { get; set; }
    public int Packgroesse { get; set; }
    public int PruefPack { get; set; }
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
    public int StueckAuftragSchicht_SPS { get; set; }
    public int KARTONS { get; set; }
    public int PALETTEN { get; set; }
    public double Nutzung { get; set; }
    public double Qualitaet { get; set; }
    public double Leistung { get; set; }
    public double Effektivitaet { get; set; }
    public bool StueckGeaendert { get; set; }
    public bool HandAuto { get; set; }
    public bool BCD_Read { get; set; }
    public short BCDCode { get; set; }
    public bool RuestzeitVorbei { get; set; }
    public int RuestzeitIST { get; set; }
    public double MaschLaeuftZeit { get; set; }
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
    public bool isArbeitefrei { get; set; }
    public bool Maschine_geblockt { get; set; }
    public int Heizungsdauer { get; set; }
    public bool SPC_Aktiv { get; set; }
}

public class Arbeit
{
    public static int Anzahl_Masch { get; set; } = 0;
    public static TIncludis[] Includis { get; set; } = Array.Empty<TIncludis>();

    public void Initialize()
    {
        // Initialisierung der Maschinen und Aufträge
    }
}
