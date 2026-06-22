using System;
using System.Collections.Generic;

namespace INCLService_CSharp
{
    // Record types from the Delphi file
    
    public class TCavChange
    {
        public string BetriebsauftragNr { get; set; } = "";
        public DateTime Datum { get; set; } = DateTime.MinValue;
        public int Alt { get; set; } = 0;
        public int Neu { get; set; } = 0;
        public int Produziert { get; set; } = 0;
        public int Schusszaehler { get; set; } = 0;
    }

    public class TAuftrag
    {
        public string BetriebsauftragNr { get; set; } = "";
        public string BetriebsauftragNr_Alt { get; set; } = "";
        public string AuftragNr { get; set; } = "";
        public string Bezeichnung { get; set; } = "";
        public string Zustaendig { get; set; } = "";
        public string Signal { get; set; } = "";
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
        public string EndeDatumSTR { get; set; } = "";
        public double LTSOLL { get; set; } = 0.0;
        public double LTIST { get; set; } = 0.0;
        public double LT1 { get; set; } = 0.0;
        public double LT2 { get; set; } = 0.0;
        public int Werkzeug { get; set; } = 0;
        public string WerkzeugNr { get; set; } = "";
        public int WerkzeugMerker { get; set; } = 0; // Anzahl Schuss des letzten Zyklus
        public int IstStandzeit { get; set; } = 0;
        public int Einsatzdauer { get; set; } = 0;
        public bool HalbAuto { get; set; } = false;
        public int Kopfgroesse { get; set; } = 0;
        public int KAVITAET_SOLL { get; set; } = 0;
        public int InPause { get; set; } = 0;
        public int Var_Kavitaet { get; set; } = 0;
        public int StueckSchicht { get; set; } = 0;
        public string Schwesterauftrag { get; set; } = "";
        public string Kunde { get; set; } = "";
        public string Form { get; set; } = "";
        public int Programm_Nr { get; set; } = 0;
        public bool MasterAuftrag { get; set; } = false;
        public double PersonalZeit { get; set; } = 0.0;
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
        public string InterBezeichnung { get; set; } = "";
        public TCavChange LetzerKavWechsel { get; set; } = new TCavChange();
        public bool WasReset { get; set; } = false;
        public int SchichtAuftragsLaufzeit { get; set; } = 0;
        public int GesamtLaufzeit { get; set; } = 0;
        public string BaNrLaufzeit { get; set; } = "";
        public bool Mustern { get; set; } = false;
    }

    public class TBDE
    {
        public string Bezeichnung { get; set; } = "";
        public string Zustaendig { get; set; } = "";
        public string Signal { get; set; } = "";
        public int Sollwert { get; set; } = 0;
        public int Istwert { get; set; } = 0;
        public int Ist_PRZ { get; set; } = 0;
        public int Vorwarnung { get; set; } = 0;
        public bool Erzeugt { get; set; } = false;
        public bool VorwarnungErzeugt { get; set; } = false;
    }

    public class TTPM
    {
        public int Nr { get; set; } = 0;
        public int MaschinenNr { get; set; } = 0;
        public int StillstandNr { get; set; } = 0;
        public DateTime Kommt { get; set; } = DateTime.MinValue;
        public DateTime Geht { get; set; } = DateTime.MinValue;
        public int Dauer { get; set; } = 0;
        public int Gruppe { get; set; } = 0;
        public bool Geplant { get; set; } = false;
        public string Grund { get; set; } = "";
        public string BANr { get; set; } = "";
        public string Werkzeug { get; set; } = "";
        public string Lizenz { get; set; } = "";
        public string Artikel { get; set; } = "";
        public string ChargenNr { get; set; } = "";
        public string Personal { get; set; } = "";
        public string Notice { get; set; } = "";
        public string RefNo { get; set; } = "";
        public int EventId { get; set; } = 0;
        public string EventToken { get; set; } = "";
    }

    public static class Arbeit
    {
        // Global variables and functions would be implemented here
        public static List<TAuftrag> AuftragList { get; set; } = new List<TAuftrag>();
        public static List<TBDE> BDEList { get; set; } = new List<TBDE>();
        public static List<TTPM> TPMList { get; set; } = new List<TTPM>();

        // Function declarations
        public static void Initialize()
        {
            // Initialize work data
        }

        public static void LoadAuftragData()
        {
            // Load order data
        }

        public static void ProcessAuftrag(TAuftrag auftrag)
        {
            // Process order
        }

        public static void UpdateTPMData()
        {
            // Update TPM data
        }

        public static void CalculateStatistics()
        {
            // Calculate statistics
        }

        // More functions would be implemented here
        // This is a simplified version of the large arbeit.pas file
    }
}
