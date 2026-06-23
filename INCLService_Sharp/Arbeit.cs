using System;
using System.Collections.Generic;
using System.Data;
using INCLUDIS.Utils.CommonDB;

namespace INCLService_Sharp
{
    /// <summary>
    /// Work data structures and functions - 1:1 translation from Arbeit.pas
    /// </summary>
    
    /// <summary>
    /// Cavity change record - 1:1 translation from Delphi TCavChange
    /// </summary>
    public class TCavChange
    {
        public string BetriebsauftragNr { get; set; } = string.Empty;
        public DateTime Datum { get; set; } = DateTime.MinValue;
        public int Alt { get; set; } = 0;
        public int Neu { get; set; } = 0;
        public int Produziert { get; set; } = 0;
        public int Schusszaehler { get; set; } = 0;
    }

    /// <summary>
    /// Order record - 1:1 translation from Delphi TAuftrag
    /// </summary>
    public class TAuftrag
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
        public short Stat { get; set; } = 0;
        public int Solltakt { get; set; } = 0;
        public DateTime StartDatum { get; set; } = DateTime.MinValue;
        public DateTime EndeDatum { get; set; } = DateTime.MinValue;
        public string EndeDatumSTR { get; set; } = string.Empty;
        public double LTSOLL { get; set; } = 0.0;
        public double LTIST { get; set; } = 0.0;
        public double LT1 { get; set; } = 0.0;
        public double LT2 { get; set; } = 0.0;
        public int Werkzeug { get; set; } = 0;
        public string WerkzeugNr { get; set; } = string.Empty;
        public int WerkzeugMerker { get; set; } = 0;
        public int IstStandzeit { get; set; } = 0;
        public int Einsatzdauer { get; set; } = 0;
        public bool HalbAuto { get; set; } = false;
        public int Kopfgroesse { get; set; } = 0;
        public int KAVITAET_SOLL { get; set; } = 0;
        public int InPause { get; set; } = 0;
        public int Var_Kavitaet { get; set; } = 0;
        public int StueckSchicht { get; set; } = 0;
        public string Schwesterauftrag { get; set; } = string.Empty;
        public string Kunde { get; set; } = string.Empty;
        public string Form { get; set; } = string.Empty;
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
        public string InterBezeichnung { get; set; } = string.Empty;
        public TCavChange LetzerKavWechsel { get; set; } = new TCavChange();
        public bool WasReset { get; set; } = false;
        public int SchichtAuftragsLaufzeit { get; set; } = 0;
        public int GesamtLaufzeit { get; set; } = 0;
        public string BaNrLaufzeit { get; set; } = string.Empty;
        public bool Mustern { get; set; } = false;
    }

    /// <summary>
    /// BDE record - 1:1 translation from Delphi TBDE
    /// </summary>
    public class TBDE
    {
        public string Bezeichnung { get; set; } = string.Empty;
        public string Zustaendig { get; set; } = string.Empty;
        public string Signal { get; set; } = string.Empty;
        public int Sollwert { get; set; } = 0;
        public int Istwert { get; set; } = 0;
        public int Ist_PRZ { get; set; } = 0;
        public int Vorwarnung { get; set; } = 0;
        public bool Erzeugt { get; set; } = false;
        public bool VorwarnungErzeugt { get; set; } = false;
    }

    /// <summary>
    /// TPM record - 1:1 translation from Delphi TTPM
    /// </summary>
    public class TTPM
    {
        public bool Stillstand { get; set; } = false;
        public string Fehlercode { get; set; } = string.Empty;
        public int Gebucht { get; set; } = 0;
    }

    /// <summary>
    /// Includis machine record - 1:1 translation from Delphi TIncludis
    /// </summary>
    public class TIncludis
    {
        public string Lizenz { get; set; } = string.Empty;
        public string Maschine { get; set; } = string.Empty;
        public string KURZKENNUNG { get; set; } = string.Empty;
        public string MaschNr { get; set; } = string.Empty;
        public string MaschNrEcht { get; set; } = string.Empty;
        public int SORT_MASCHPANEL { get; set; } = 0;
        public bool MaschAktiv { get; set; } = false;
        public short Datenblock { get; set; } = 0;
        public TAuftrag Auftrag { get; set; } = new TAuftrag();
        public int InventarNr { get; set; } = 0;
        public bool IstArchiviert { get; set; } = false;
        public bool Masch_Warmtrennen { get; set; } = false;
        public bool Prod_Gleich_Pack { get; set; } = false;
        public TBDE BDE { get; set; } = new TBDE();
        public int Kopfgroesse { get; set; } = 0;
        public int Packgroesse { get; set; } = 0;
        public int PruefPack { get; set; } = 0;
        public int Pruefstation { get; set; } = 0;
        public int Betriebsstunden { get; set; } = 0;
        public int IstTakt { get; set; } = 0;
        public int Solltakt { get; set; } = 0;
        public int LaufzeitGes { get; set; } = 0;
        public int LaufzeitSchicht { get; set; } = 0;
        public int Zustand { get; set; } = 0;
        public int ZustandAlt { get; set; } = 0;
        public int Schicht { get; set; } = 0;
        public int AusschussSchicht { get; set; } = 0;
        public int AusschussAuftragSchicht { get; set; } = 0;
        public int StueckAuftragGesamt { get; set; } = 0;
        public int StueckPruefAuftragGesamt { get; set; } = 0;
        public int StueckPackAuftragGesamt { get; set; } = 0;
        public int StueckAuftragAlt { get; set; } = 0;
        public int StueckSchicht { get; set; } = 0;
        public int StueckPruefSchicht { get; set; } = 0;
        public int StueckPackSchicht { get; set; } = 0;
        public int StueckAuftragSchicht { get; set; } = 0;
        public int StueckPruefAuftragSchicht { get; set; } = 0;
        public int StueckPackAuftragSchicht { get; set; } = 0;
        public int StueckAuftragSchichtAlt { get; set; } = 0;
        public int StueckAuftragSchicht_SPS { get; set; } = 0;
        public int KARTONS { get; set; } = 0;
        public int PALETTEN { get; set; } = 0;
        public double Nutzung { get; set; } = 0.0;
        public double Qualitaet { get; set; } = 0.0;
        public double Leistung { get; set; } = 0.0;
        public double Effektivitaet { get; set; } = 0.0;
        public bool StueckGeaendert { get; set; } = false;
        public bool HandAuto { get; set; } = false;
        public bool BCD_Read { get; set; } = false;
        public short BCDCode { get; set; } = 0;
        public bool RuestzeitVorbei { get; set; } = false;
        public int RuestzeitIST { get; set; } = 0;
        public DateTime MaschLaeuftZeit { get; set; } = DateTime.MinValue;
        public short MaschZustandBeiRuesten { get; set; } = 0;
        public int TaktLogMerker { get; set; } = 0;
        public int ArtikelZyklus { get; set; } = 0;
        public int MaschinenZaehler { get; set; } = 0;
        public int Stops { get; set; } = 0;
        public int Analagenausfall { get; set; } = 0;
        public int Ruesten { get; set; } = 0;
        public int Logistik { get; set; } = 0;
        public int NichtGebucht { get; set; } = 0;
        public int Geplant { get; set; } = 0;
        public int Ungeplant { get; set; } = 0;
        public int Sollaufzeit { get; set; } = 0;
        public int IstLaufZeit { get; set; } = 0;
        public string Einheit { get; set; } = string.Empty;
        public bool AutoRuesten { get; set; } = false;
        public double AutoRuestZeit { get; set; } = 0.0;
        public double AutoRuestStart { get; set; } = 0.0;
        public int MaschinenTyp { get; set; } = 0;
        public bool isArbeitefrei { get; set; } = false;
        public bool Maschine_geblockt { get; set; } = false;
        public int Heizungsdauer { get; set; } = 0;
        public bool SPC_Aktiv { get; set; } = false;
    }

    /// <summary>
    /// Global arrays and variables - 1:1 translation from Delphi
    /// </summary>
    public static class ArbeitGlobals
    {
        // Global arrays (size would be determined at runtime)
        public static List<TIncludis> Includis { get; set; } = new List<TIncludis>();
        public static List<int> StueckGesamt { get; set; } = new List<int>();
        public static List<int> StueckAuftragGesamt { get; set; } = new List<int>();
        public static List<int> StueckAuftragSchicht { get; set; } = new List<int>();
        public static List<int> StueckSchicht { get; set; } = new List<int>();
        public static List<int> Betriebsstunden { get; set; } = new List<int>();
        public static List<int> Taktzeit { get; set; } = new List<int>();
        public static List<int> LaufzeitGes { get; set; } = new List<int>();
        public static List<int> LaufzeitSchicht { get; set; } = new List<int>();
        public static List<int> StueckPruefGesamt { get; set; } = new List<int>();
        public static List<int> StueckPruefAuftragGesamt { get; set; } = new List<int>();
        public static List<int> StueckPruefAuftragSchicht { get; set; } = new List<int>();
        public static List<int> StueckPruefSchicht { get; set; } = new List<int>();
        public static List<int> StueckPackGesamt { get; set; } = new List<int>();
        public static List<int> StueckPackAuftragGesamt { get; set; } = new List<int>();
        public static List<int> StueckPackAuftragSchicht { get; set; } = new List<int>();
        public static List<int> StueckPackSchicht { get; set; } = new List<int>();
        
        // Machine state arrays
        public static List<bool> MaschLaeuft { get; set; } = new List<bool>();
        public static List<bool> Maschinenstatus { get; set; } = new List<bool>();
        public static List<bool> MaschProgrammbetrieb { get; set; } = new List<bool>();
        
        // Other global variables
        public static int Anzahl_Masch { get; set; } = 0;
        public static DateTime Last_Time_Meldung { get; set; } = DateTime.MinValue;
        public static string IgnorePendingStatement { get; set; } = " AND pending = 0";
    }

    /// <summary>
    /// Work utility functions - 1:1 translation from Delphi
    /// </summary>
    public static class ArbeitUtils
    {
        private static CommonDB _database;
        
        public static CommonDB Database
        {
            get
            {
                if (_database == null)
                {
                    _database = new CommonDB
                    {
                        UserName = INCLService.DBUser,
                        Password = INCLService.DBPass,
                        Server = INCLService.DBServer,
                        InitialCatalog = INCLService.DBInitialCatalog,
                        SqlProvider = INCLService.DBProvider
                    };
                }
                return _database;
            }
            set
            {
                _database = value;
            }
        }

        /// <summary>
        /// Initialize work data - 1:1 translation from Delphi
        /// </summary>
        public static void Initialize()
        {
            try
            {
                INCLService.WriteMessage("Arbeit: Initializing work data", 0);
                
                // Load machine count from setup
                string sql = "SELECT Anzahl_Masch FROM SETUP WHERE Nr = '1' ";
                var result = Database.ExecuteScalar(sql);
                
                if (result != null && result != DBNull.Value)
                {
                    ArbeitGlobals.Anzahl_Masch = Convert.ToInt32(result);
                }
                
                // Initialize arrays
                InitializeArrays();
                
                // Load machine data
                LoadMachineData();
                
                INCLService.WriteMessage("Arbeit: Work data initialized", 0);
            }
            catch (Exception ex)
            {
                INCLService.WriteMessage("Error in Arbeit.Initialize: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Initialize arrays - 1:1 translation from Delphi
        /// </summary>
        private static void InitializeArrays()
        {
            try
            {
                // Clear existing data
                ArbeitGlobals.Includis.Clear();
                ArbeitGlobals.StueckGesamt.Clear();
                ArbeitGlobals.StueckAuftragGesamt.Clear();
                ArbeitGlobals.StueckAuftragSchicht.Clear();
                ArbeitGlobals.StueckSchicht.Clear();
                ArbeitGlobals.Betriebsstunden.Clear();
                ArbeitGlobals.Taktzeit.Clear();
                ArbeitGlobals.LaufzeitGes.Clear();
                ArbeitGlobals.LaufzeitSchicht.Clear();
                ArbeitGlobals.StueckPruefGesamt.Clear();
                ArbeitGlobals.StueckPruefAuftragGesamt.Clear();
                ArbeitGlobals.StueckPruefAuftragSchicht.Clear();
                ArbeitGlobals.StueckPruefSchicht.Clear();
                ArbeitGlobals.StueckPackGesamt.Clear();
                ArbeitGlobals.StueckPackAuftragGesamt.Clear();
                ArbeitGlobals.StueckPackAuftragSchicht.Clear();
                ArbeitGlobals.StueckPackSchicht.Clear();
                ArbeitGlobals.MaschLaeuft.Clear();
                ArbeitGlobals.Maschinenstatus.Clear();
                ArbeitGlobals.MaschProgrammbetrieb.Clear();
                
                // Resize arrays to Anzahl_Masch + 1 (1-based indexing)
                for (int i = 0; i <= ArbeitGlobals.Anzahl_Masch; i++)
                {
                    ArbeitGlobals.Includis.Add(new TIncludis());
                    ArbeitGlobals.StueckGesamt.Add(0);
                    ArbeitGlobals.StueckAuftragGesamt.Add(0);
                    ArbeitGlobals.StueckAuftragSchicht.Add(0);
                    ArbeitGlobals.StueckSchicht.Add(0);
                    ArbeitGlobals.Betriebsstunden.Add(0);
                    ArbeitGlobals.Taktzeit.Add(0);
                    ArbeitGlobals.LaufzeitGes.Add(0);
                    ArbeitGlobals.LaufzeitSchicht.Add(0);
                    ArbeitGlobals.StueckPruefGesamt.Add(0);
                    ArbeitGlobals.StueckPruefAuftragGesamt.Add(0);
                    ArbeitGlobals.StueckPruefAuftragSchicht.Add(0);
                    ArbeitGlobals.StueckPruefSchicht.Add(0);
                    ArbeitGlobals.StueckPackGesamt.Add(0);
                    ArbeitGlobals.StueckPackAuftragGesamt.Add(0);
                    ArbeitGlobals.StueckPackAuftragSchicht.Add(0);
                    ArbeitGlobals.StueckPackSchicht.Add(0);
                    ArbeitGlobals.MaschLaeuft.Add(false);
                    ArbeitGlobals.Maschinenstatus.Add(false);
                    ArbeitGlobals.MaschProgrammbetrieb.Add(false);
                }
            }
            catch (Exception ex)
            {
                INCLService.WriteMessage("Error in InitializeArrays: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Load machine data - 1:1 translation from Delphi
        /// </summary>
        private static void LoadMachineData()
        {
            try
            {
                INCLService.WriteMessage("Arbeit: Loading machine data", 0);
                
                string sql = "SELECT * FROM MASCHINE WHERE Aktiv = 1 ORDER BY Nr";
                using (var reader = Database.GetReader(sql))
                {
                    int index = 1; // 1-based indexing
                    while (reader.Read() && index <= ArbeitGlobals.Anzahl_Masch)
                    {
                        var maschine = ArbeitGlobals.Includis[index];
                        
                        if (!reader.IsDBNull("Lizenz"))
                            maschine.Lizenz = reader.GetString("Lizenz");
                        if (!reader.IsDBNull("Maschine"))
                            maschine.Maschine = reader.GetString("Maschine");
                        if (!reader.IsDBNull("KURZKENNUNG"))
                            maschine.KURZKENNUNG = reader.GetString("KURZKENNUNG");
                        if (!reader.IsDBNull("MaschNr"))
                            maschine.MaschNr = reader.GetString("MaschNr");
                        if (!reader.IsDBNull("MaschNrEcht"))
                            maschine.MaschNrEcht = reader.GetString("MaschNrEcht");
                        if (!reader.IsDBNull("SORT_MASCHPANEL"))
                            maschine.SORT_MASCHPANEL = reader.GetInt32("SORT_MASCHPANEL");
                        if (!reader.IsDBNull("MaschAktiv"))
                            maschine.MaschAktiv = reader.GetInt32("MaschAktiv") == 1;
                        if (!reader.IsDBNull("Datenblock"))
                            maschine.Datenblock = reader.GetInt16("Datenblock");
                        if (!reader.IsDBNull("InventarNr"))
                            maschine.InventarNr = reader.GetInt32("InventarNr");
                        if (!reader.IsDBNull("IstArchiviert"))
                            maschine.IstArchiviert = reader.GetInt32("IstArchiviert") == 1;
                        
                        index++;
                    }
                }
                
                INCLService.WriteMessage("Arbeit: Machine data loaded", 0);
            }
            catch (Exception ex)
            {
                INCLService.WriteMessage("Error in LoadMachineData: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Get machine by number - 1:1 translation from Delphi
        /// </summary>
        public static TIncludis GetMaschine(int maschNr)
        {
            try
            {
                if (maschNr >= 1 && maschNr <= ArbeitGlobals.Anzahl_Masch)
                {
                    return ArbeitGlobals.Includis[maschNr];
                }
                return null;
            }
            catch (Exception ex)
            {
                INCLService.WriteMessage("Error in GetMaschine: " + ex.Message, 0);
                return null;
            }
        }

        /// <summary>
        /// Get SPS value for machine - 1:1 translation from Delphi
        /// </summary>
        public static int GetSPSWert(int maschNr, int signalNr)
        {
            try
            {
                // This would read from SPS/PLC
                // For now, return 0
                return 0;
            }
            catch (Exception ex)
            {
                INCLService.WriteMessage("Error in GetSPSWert: " + ex.Message, 0);
                return 0;
            }
        }

        /// <summary>
        /// Set SPS value for machine - 1:1 translation from Delphi
        /// </summary>
        public static void SetSPSWert(int maschNr, int signalNr, int wert)
        {
            try
            {
                // This would write to SPS/PLC
                // For now, just log it
                INCLService.WriteMessage("SetSPSWert: Machine=" + maschNr + ", Signal=" + signalNr + ", Value=" + wert, 1);
            }
            catch (Exception ex)
            {
                INCLService.WriteMessage("Error in SetSPSWert: " + ex.Message, 0);
            }
        }
    }
}
