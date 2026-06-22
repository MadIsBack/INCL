using System;

namespace INCLService_CSharp
{
    public static class DBMain
    {
        // Constants from the Delphi file
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

        // Maybe in the future better e.g. 5 minutes = MINUTEN5 (see above)
        public const double Zeit_zum_MDEAuftrag = 0.003472; // corresponds to 5 minutes
        public const double Zeit_zum_AutoStart = 0.006944; // corresponds to 10 minutes
        // Zeit_zum_SPCAuftrag = 0.006944; // Now via Setup_par // corresponds to 10 minutes
        public const double Zeit_zur_Meldung = 0.041664; // corresponds to 60 minutes

        public const int StatusPlanDiff = 1440;

        public const bool SIMULATION = false; // Simulation total
        public const bool TEMPSIMULATION = false; // For temperature simulation
        public const bool BCDSIMULATION = false;

        public const int BYTEVAR = 0;
        public const int WORDVAR = 1;
        public const int DWORDVAR = 2;

        // Additional constants that would be in the Delphi file
        public const int MAX_MASCHINEN = 100;
        public const int MAX_AUFTRAG = 1000;
        public const int MAX_STILLSTAND = 500;
        public const int MAX_SIGNAL = 200;
        public const int MAX_PERSONAL = 200;

        // Status constants
        public const int STATUS_FREI = 0;
        public const int STATUS_LAEUFT = 1;
        public const int STATUS_RUESTEN = 2;
        public const int STATUS_STILLSTAND = 3;
        public const int STATUS_WARTUNG = 4;

        // Type definitions would be converted to C# classes
        public class TMaschinenStatus
        {
            public int MaschinenNr { get; set; } = 0;
            public int Status { get; set; } = 0;
            public DateTime LetzteAenderung { get; set; } = DateTime.MinValue;
            public string AktuellerAuftrag { get; set; } = "";
        }

        public class TAuftragsDaten
        {
            public string AuftragsNr { get; set; } = "";
            public string BetriebsAuftragsNr { get; set; } = "";
            public int MaschinenNr { get; set; } = 0;
            public DateTime StartDatum { get; set; } = DateTime.MinValue;
            public DateTime EndeDatum { get; set; } = DateTime.MinValue;
            public int SollMenge { get; set; } = 0;
            public int IstMenge { get; set; } = 0;
            public int Ausschuss { get; set; } = 0;
        }

        // Global variables would be converted to static properties
        public static bool DatabaseConnected { get; set; } = false;
        public static int AktuelleSchicht { get; set; } = 0;
        public static DateTime LetzterSchichtwechsel { get; set; } = DateTime.MinValue;

        // Function declarations
        public static void InitializeDatabase()
        {
            // Initialize database connections
        }

        public static void ShutdownDatabase()
        {
            // Close database connections
        }

        public static bool CheckDatabaseConnection()
        {
            return DatabaseConnected;
        }

        public static void UpdateMaschinenStatus()
        {
            // Update machine status
        }

        public static void UpdateAuftragsDaten()
        {
            // Update order data
        }

        // More functions would be implemented here
        // This is a simplified version of the large DBMain.pas file
    }
}
