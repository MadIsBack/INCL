using System;

namespace INCLUDIS.INCLServer.Cs.Models
{
    /// <summary>
    /// Portierung von TAuftrag aus Arbeit.pas.
    /// Enthält alle Auftragsdaten.
    /// </summary>
    public class Auftrag
    {
        public string BetriebsauftragNr { get; set; } = string.Empty;
        public string BetriebsauftragNrAlt { get; set; } = string.Empty;
        public string AuftragNr { get; set; } = string.Empty;
        public string Bezeichnung { get; set; } = string.Empty;
        public string Zustaendig { get; set; } = string.Empty;
        public string Signal { get; set; } = string.Empty;
        public int Sollwert { get; set; }
        public int SollwertOffset { get; set; }
        public int Istwert { get; set; }
        public int IstPRZ { get; set; }
        public int Ausschuss { get; set; }
        public int Verpackt { get; set; }
        public int Anfahrausschuss { get; set; }
        public int Vorwarnung { get; set; }
        public bool Erzeugt { get; set; }
        public bool VorwarnungErzeugt { get; set; }
        public short Stat { get; set; } // Smallint
        public int Solltakt { get; set; }
        public DateTime StartDatum { get; set; }
        public DateTime EndeDatum { get; set; }
        public string EndeDatumSTR { get; set; } = string.Empty;
        public double LTSOLL { get; set; }
        public double LTIST { get; set; }
        public double LT1 { get; set; }
        public double LT2 { get; set; }
        public int Werkzeug { get; set; }
        public string WerkzeugNr { get; set; } = string.Empty;
        public int WerkzeugMerker { get; set; } // Anzahl Schuss des letzten Zyklus
        public int IstStandzeit { get; set; }
        public int Einsatzdauer { get; set; }
        public bool HalbAuto { get; set; }
        public int Kopfgroesse { get; set; }
        public int KAVITAET_SOLL { get; set; }
        public int InPause { get; set; }
        public int VarKavitaet { get; set; }
        public int StueckSchicht { get; set; }
        public string Schwesterauftrag { get; set; } = string.Empty;
        public string Kunde { get; set; } = string.Empty;
        public string Form { get; set; } = string.Empty;
        public int ProgrammNr { get; set; }
        public bool MasterAuftrag { get; set; }
        public double PersonalZeit { get; set; }
        public int Optimiert { get; set; }
        public int OptimiertAktuell { get; set; }
        public int ImStatusOptimieren { get; set; }
        public int Packgroesse { get; set; }
        public int PALETTENGROESSE { get; set; }
        public int SchichtLaufzeit { get; set; }
        public int Planzykluszeit { get; set; }
        public int Ausschussquote { get; set; }
        public int SollSpannzeitStk { get; set; }
        public int SollSpannzeitGes { get; set; }
        public string InterBezeichnung { get; set; } = string.Empty;
        public CavChange LetzerKavWechsel { get; set; } = new();
        public bool WasReset { get; set; }
        public int SchichtAuftragsLaufzeit { get; set; }
        public int GesamtLaufzeit { get; set; }
        public string BaNrLaufzeit { get; set; } = string.Empty;
        public bool Mustern { get; set; }
    }

    /// <summary>
    /// Portierung von TCavChange aus Arbeit.pas.
    /// Enthält Daten für Kavitätswechsel.
    /// </summary>
    public class CavChange
    {
        public string BetriebsauftragNr { get; set; } = string.Empty;
        public DateTime Datum { get; set; }
        public int Alt { get; set; }
        public int Neu { get; set; }
        public int Produziert { get; set; }
        public int Schusszaehler { get; set; }
    }
}
