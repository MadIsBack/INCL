using System;

namespace INCLService.CSharp.Models
{
    /// <summary>
    /// Kavitätsänderung
    /// Äquivalent zu TCavChange in Arbeit.pas
    /// </summary>
    public class CavChange
    {
        public string BetriebsauftragNr { get; set; } = string.Empty;
        public DateTime Datum { get; set; } = DateTime.MinValue;
        public int Alt { get; set; } = 0;
        public int Neu { get; set; } = 0;
        public int Produziert { get; set; } = 0;
        public int Schusszaehler { get; set; } = 0;
    }

    /// <summary>
    /// Auftrag
    /// Äquivalent zu TAuftrag in Arbeit.pas
    /// </summary>
    public class Auftrag
    {
        public string BetriebsauftragNr { get; set; } = string.Empty;
        public string BetriebsauftragNrAlt { get; set; } = string.Empty;
        public string AuftragNr { get; set; } = string.Empty;
        public string Bezeichnung { get; set; } = string.Empty;
        public string Zustaendig { get; set; } = string.Empty;
        public string Signal { get; set; } = string.Empty;
        public int Sollwert { get; set; } = 0;
        public int SollwertOffset { get; set; } = 0;
        public int Istwert { get; set; } = 0;
        public int IstPRZ { get; set; } = 0;
        public int Ausschuss { get; set; } = 0;
        public int Verpackt { get; set; } = 0;
        public int Anfahrausschuss { get; set; } = 0;
        public int Vorwarnung { get; set; } = 0;
        public bool Erzeugt { get; set; } = false;
        public bool VorwarnungErzeugt { get; set; } = false;
        public short Stat { get; set; } = 0;
        public int Solltakt { get; set; } = 0;
        public DateTime StartDatum { get; set; } = DateTime.MinValue;
        public DateTime EndeDatum { get; set; } = DateTime.MaxValue;
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
        public int VarKavitaet { get; set; } = 0;
        public int StueckSchicht { get; set; } = 0;
        public string Schwesterauftrag { get; set; } = string.Empty;
        public string Kunde { get; set; } = string.Empty;
        public string Form { get; set; } = string.Empty;
        public int ProgrammNr { get; set; } = 0;
        public bool MasterAuftrag { get; set; } = false;
        public double PersonalZeit { get; set; } = 0;
        public int Optimiert { get; set; } = 0;
        public int OptimiertAktuell { get; set; } = 0;
        public int ImStatusOptimieren { get; set; } = 0;
        public int Packgroesse { get; set; } = 0;
        public int PALETTENGROESSE { get; set; } = 0;
        public int SchichtLaufzeit { get; set; } = 0;
        public int Planzykluszeit { get; set; } = 0;
        public int Ausschussquote { get; set; } = 0;
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
    /// BDE (Betriebsdatenerfassung)
    /// Äquivalent zu TBDE in Arbeit.pas
    /// </summary>
    public class BDE
    {
        public string Bezeichnung { get; set; } = string.Empty;
        public string Zustaendig { get; set; } = string.Empty;
        public string Signal { get; set; } = string.Empty;
        public int Sollwert { get; set; } = 0;
        public int Istwert { get; set; } = 0;
        public int IstPRZ { get; set; } = 0;
        public int Vorwarnung { get; set; } = 0;
        public bool Erzeugt { get; set; } = false;
        public bool VorwarnungErzeugt { get; set; } = false;
    }

    /// <summary>
    /// TPM-Daten
    /// Äquivalent zu TTPM in Arbeit.pas
    /// </summary>
    public class TPMData
    {
        public int MaschinenNr { get; set; } = 0;
        public int Schicht { get; set; } = 0;
        public DateTime Datum { get; set; } = DateTime.MinValue;
        public int StillstandNr { get; set; } = 0;
        public string Stillstand { get; set; } = string.Empty;
        public int Dauer { get; set; } = 0;
        public int Anzahl { get; set; } = 0;
        public bool Geplant { get; set; } = false;
    }
}
