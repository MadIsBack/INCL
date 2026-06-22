// <summary>
// CO_Auftrag_V63.cs - C# translation of CO_Auftrag_V63.pas
// Order management class
// </summary>

using System;
using System.Collections.Generic;

namespace INCLService_CSharp
{
    /// <summary>
    /// Error constants
    /// </summary>
    public static class CO_Auftrag_Constants
    {
        public const int Auftrag_nicht_gefunden = 2501;
        public const int Werkzeug_nicht_auf_Maschine = 2502;
        public const int Maschine_nicht_frei = 2503;
        public const int Anderer_Auftrag_wird_geruestet = 2504;
        public const int Fehler_Auftragsstart = 2505;
        public const int Werkzeug_nicht_vorhanden = 2506;
        public const int Auftrag_terminiert = 2507;
        public const int Maschine_Optimiert = 2508;
        public const int Kurze_Laufzeit = 2509;
        public const int Werkzeug_nicht_im_Standort = 2510;
        public const int Auftrag_nicht_gestartet = 2511;
        public const int Auftrag_nur_geruestet = 2512;
        public const int Maschine_wartet_auf_FliegendenWechsel = 2513;
        public const int Fehler_Beim_Material_Kopieren = 2514;
        public const int Einsatz_in_Reparatur = 2515;

        public const int Konnte_Index_nicht_erzeugen = 2601;
        public const int DatenbankName_nicht_definiert = 2602;
        public const int Datenbankanbindung_gescheitert = 2603;

        public const int Werkzeug_Muss_zur_Reparatur = 2701;

        public const int stLaeuftInt = 0;
        public const int stStartRuestenInt = 1;
        public const int stgeplantInt = 2;
        public const int stBeendetInt = 3;
        public const int stSchwesterLaeuftInt = 4;
        public const int stUnterbrochen = 5;

        public const string MASCHBEZ_UNTERAUFTRAG = " W2";

        public const int CSTUECKAUFTRAGGESAMT = 1;
        public const int CAUFTRAGRESETSTUECK = 21;
        public const int CAUFTRAGRESETPRUEF = 22;
        public const int CAUFTRAGRESETPACK = 23;
        public const int CLABELRESET = 128;
    }

    /// <summary>
    /// Error event delegate
    /// </summary>
    public delegate void TErrorEvent(object Sender, string Msg, ref bool Handled);

    /// <summary>
    /// Get language string function
    /// </summary>
    public delegate string FuncGetL(string T);

    /// <summary>
    /// Comtas error exception
    /// </summary>
    public class ComtasAuftragError : Exception
    {
        public ComtasAuftragError() : base() { }
        public ComtasAuftragError(string message) : base(message) { }
        public ComtasAuftragError(string message, Exception inner) : base(message, inner) { }
    }

    /// <summary>
    /// CO_Auftrag class - Order management
    /// </summary>
    public class CO_Auftrag : IDisposable
    {
        private CO_Database fOraSession = null;
        private bool fOpt_WerkZeug = false;
        private bool fOpt_Schwesterauftraege = false;
        private bool FDifferenzListe = false;
        private bool FOption_Ruestzeit_Auftrag_Folgeauftrag = false;
        private bool FOpt_SPC = false;
        private bool FOpt_Metall = false;
        private bool FOpt_TaktLog = false;
        private bool FOpt_SolltaktAenderung = false;
        private bool fAuftrag_Optimieren = false;
        private bool fIgnoreWaitingRepair = false;
        private int fSpracheNr = 0;
        private string FVersion = "1.0";
        private string FModul = "CO_Auftrag";

        private int fTaktVergleichToleranz = 0;
        private int fTaktVergleichToleranzAbsolut = 0;
        private bool fZellenfertigung = false;
        private bool fZellenfertigungSimultan = false;
        private bool fProduktionsLinie = false;
        private bool fRuestAusStillstand = false;
        private bool fExtrusion = false;
        private bool fAuftragsEnde_Close = false;
        private bool fLaufzeitLog = false;
        private bool fTaktzeitkontrolleStammdaten = false;
        private bool fPruefen = false;
        private bool fPacken = false;
        private bool fVerpackt_Barcode = false;
        private bool fWZKavitaet_Update = false;
        private int fKavitaet_laufender_Auftrag = 0;
        private bool fMaterial = false;
        private bool fFolgeAuftragTaktzeitUpdate = false;

        private string fLogStagesPath = string.Empty;
        private bool fLogStages = false;

        private CO_Query FQuery = null;
        private object fOwner = null;

        /// <summary>
        /// Constructor
        /// </summary>
        public CO_Auftrag(object owner)
        {
            fOwner = owner;
            FQuery = new CO_Query(owner);
        }

        /// <summary>
        /// Set database
        /// </summary>
        public void SetDatabase(CO_Database database)
        {
            fOraSession = database;
            FQuery.Database = database;
        }

        /// <summary>
        /// Initialize order management
        /// </summary>
        public void Init()
        {
            try
            {
                // Load configuration from database
                LoadConfiguration();
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in CO_Auftrag.Init: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Load configuration
        /// </summary>
        private void LoadConfiguration()
        {
            try
            {
                // Load configuration from database
                // This is a placeholder for the actual implementation
                FVersion = CO_Library_V63.GetVersion();
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in LoadConfiguration: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Book order
        /// </summary>
        public void AuftragBuchen(string BetriebsauftragNr, long Stueckzahl)
        {
            try
            {
                // Implementation would book order in database
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in AuftragBuchen: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Start order
        /// </summary>
        public bool AuftragStarten(int PDENr)
        {
            try
            {
                // Implementation would start order
                return true;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in AuftragStarten: " + ex.Message, 0);
                return false;
            }
        }

        /// <summary>
        /// Stop order
        /// </summary>
        public bool AuftragBeenden(int PDENr)
        {
            try
            {
                // Implementation would stop order
                return true;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in AuftragBeenden: " + ex.Message, 0);
                return false;
            }
        }

        /// <summary>
        /// Interrupt order
        /// </summary>
        public bool AuftragUnterbrechen(int PDENr)
        {
            try
            {
                // Implementation would interrupt order
                return true;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in AuftragUnterbrechen: " + ex.Message, 0);
                return false;
            }
        }

        /// <summary>
        /// Continue order
        /// </summary>
        public bool AuftragFortsetzen(int PDENr)
        {
            try
            {
                // Implementation would continue order
                return true;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in AuftragFortsetzen: " + ex.Message, 0);
                return false;
            }
        }

        /// <summary>
        /// Check if order can be started
        /// </summary>
        public bool KannAuftragGestartetWerden(int PDENr, string Lizenz)
        {
            try
            {
                // Implementation would check if order can be started
                return true;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in KannAuftragGestartetWerden: " + ex.Message, 0);
                return false;
            }
        }

        /// <summary>
        /// Get order status
        /// </summary>
        public int GetAuftragStatus(int PDENr)
        {
            try
            {
                // Implementation would get order status from database
                return 0;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in GetAuftragStatus: " + ex.Message, 0);
                return 0;
            }
        }

        /// <summary>
        /// Dispose method
        /// </summary>
        public void Dispose()
        {
            try
            {
                if (FQuery != null)
                {
                    FQuery.Close();
                    FQuery = null;
                }
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in CO_Auftrag.Dispose: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Destructor
        /// </summary>
        ~CO_Auftrag()
        {
            Dispose();
        }
    }
}
