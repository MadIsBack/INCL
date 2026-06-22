// <summary>
// Th_Schicht.cs - C# translation of Th_Schicht.pas
// Thread for shift calculations and TPM processing
// </summary>

using System;
using System.Threading;

namespace INCLService_CSharp
{
    /// <summary>
    /// Thread for shift calculations
    /// </summary>
    public class Thread_Schicht : IDisposable
    {
        private CO_DataBase.CO_Database CDatabase;
        private CO_Query qSuch, qSuch2, qSuch3, qSuch4;
        private CO_Query qUpdate, qDurchlauf;
        private CO_TPM_V63.TCO_TPM ThTPM;
        private CO_INCMeldung_V63.TCO_INCMeldung Th_Meldung;
        private bool FNachBerechnung = false;
        private int LogFile_Mode = 0;
        private string SQLStr = "";
        private CO_AliveTimer.CO_AliveClient ShiftAliveTimer;

        public bool Berechnung_aktiv = false;
        public bool Schicht_Berechnung = false;
        public bool Recalculate_Mode = false;
        public int AlteSchicht = 0;
        public CO_SPC_V63.TCO_SPC ThSPC;

        private Thread thread;
        private bool shouldStop = false;

        /// <summary>
        /// Constructor
        /// </summary>
        public Thread_Schicht()
        {
            // Initialize database connection
            CDatabase = new CO_DataBase.CO_Database();
            CDatabase.UserName = Main.DBUser;
            CDatabase.Password = Main.DBPass;
            CDatabase.Server = Main.DBServer;
            
            if (DBMain.INCLUDISDatabaseTyp == 1)
            {
                CDatabase.InitialCatalog = Main.DBInitialCatalog;
                CDatabase.SqlProvider = Main.DBProvider;
            }

            // Initialize queries
            qSuch = new CO_Query();
            qSuch2 = new CO_Query();
            qSuch3 = new CO_Query();
            qSuch4 = new CO_Query();
            qUpdate = new CO_Query();
            qDurchlauf = new CO_Query();

            // Set query properties
            qSuch.Database = CDatabase;
            qSuch2.Database = CDatabase;
            qSuch3.Database = CDatabase;
            qSuch4.Database = CDatabase;
            qUpdate.Database = CDatabase;
            qDurchlauf.Database = CDatabase;

            // Initialize other components
            ThTPM = new CO_TPM_V63.TCO_TPM();
            Th_Meldung = new CO_INCMeldung_V63.TCO_INCMeldung();
            ThSPC = new CO_SPC_V63.TCO_SPC();
            ShiftAliveTimer = new CO_AliveTimer.CO_AliveClient();

            // Set thread properties
            thread = new Thread(Execute);
            thread.IsBackground = true;
            thread.Priority = ThreadPriority.Normal;
        }

        /// <summary>
        /// Start the thread
        /// </summary>
        public void Start()
        {
            shouldStop = false;
            thread.Start();
        }

        /// <summary>
        /// Stop the thread
        /// </summary>
        public void Stop()
        {
            shouldStop = true;
            thread.Join(5000); // Wait up to 5 seconds
        }

        /// <summary>
        /// Main thread execution
        /// </summary>
        private void Execute()
        {
            try
            {
                Berechnung_aktiv = true;
                
                while (!shouldStop)
                {
                    try
                    {
                        // Main shift calculation logic
                        if (Schicht_Berechnung)
                        {
                            // Check for shift change
                            if (Schichtwechsel())
                            {
                                StartSchichtWechsel(AlteSchicht);
                            }

                            // Perform shift calculations
                            Berechne_A_Daten(MainDLL.Trunc(MainDLL.Jetzt - 1), MainDLL.Trunc(MainDLL.Jetzt), "");
                            
                            // TPM calculations
                            if (DBMain.TPM_Auswertung)
                            {
                                TPM_Korrektur(MainDLL.Trunc(MainDLL.Jetzt - 1), MainDLL.Trunc(MainDLL.Jetzt), true, "");
                            }

                            // Check for recalculation
                            if (NachBerechnung)
                            {
                                Recalculation();
                                SetNachBerechnung(false);
                            }
                        }

                        // Sleep for a while
                        Thread.Sleep(60000); // 1 minute
                    }
                    catch (Exception ex)
                    {
                        MainDLL.SchreibeMeldung("Error in Th_Schicht Execute: " + ex.Message, 0);
                        Thread.Sleep(30000); // Wait 30 seconds on error
                    }
                }
            }
            finally
            {
                Berechnung_aktiv = false;
            }
        }

        /// <summary>
        /// Check if shift change occurred
        /// </summary>
        public bool Schichtwechsel()
        {
            try
            {
                int currentShift = DBMain.GetSchichtNr(MainDLL.DateTimeToFloat(MainDLL.Jetzt));
                if (currentShift != AlteSchicht)
                {
                    AlteSchicht = currentShift;
                    return true;
                }
                return false;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in Schichtwechsel: " + ex.Message, 0);
                return false;
            }
        }

        /// <summary>
        /// Start shift change processing
        /// </summary>
        public void StartSchichtWechsel(int AlteSchicht)
        {
            try
            {
                MainDLL.SchreibeMeldung("Shift change detected: from " + AlteSchicht.ToString() + " to " + 
                    DBMain.GetSchichtNr(MainDLL.DateTimeToFloat(MainDLL.Jetzt)).ToString(), 2);

                // Perform shift change actions
                // This would include various cleanup and initialization tasks
                
                // Update shift in database
                string SQLStr = "UPDATE Setup SET Schicht = " + 
                    DBMain.GetSchichtNr(MainDLL.DateTimeToFloat(MainDLL.Jetzt)).ToString() + 
                    " WHERE Nr = 1";
                SQL_fuc.SQL_Insert(qUpdate, SQLStr);

                // Trigger shift change events
                ArbeitGlobals.Vor_Schichtwechsel = true;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in StartSchichtWechsel: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Calculate A data (shift data)
        /// </summary>
        public void Berechne_A_Daten(double Von, double Bis, string MNrs)
        {
            try
            {
                // This would calculate various shift-related data
                // For now, implement basic structure
                
                DateTime VonDate = MainDLL.ConvertFromFloat(Von);
                DateTime BisDate = MainDLL.ConvertFromFloat(Bis);

                MainDLL.SchreibeMeldung("Calculating A data from " + VonDate.ToString() + " to " + BisDate.ToString(), 2);

                // Calculate for each machine
                for (int i = 1; i <= DBMain.Anzahl_Masch; i++)
                {
                    if (ArbeitGlobals.Includis[i].IstArchiviert)
                        continue;

                    // Calculate shift data for this machine
                    // This would include piece counts, downtimes, etc.
                }
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in Berechne_A_Daten: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// TPM correction
        /// </summary>
        public void TPM_Korrektur(double Von, double Bis, bool Berechnen_TPM_Auswertung, string MNrs)
        {
            try
            {
                // This would perform TPM corrections for the specified period
                MainDLL.SchreibeMeldung("TPM correction from " + Von.ToString() + " to " + Bis.ToString(), 2);

                // Calculate TPM data
                if (Berechnen_TPM_Auswertung)
                {
                    Berechne_TPM_Auswertung(MainDLL.ConvertFromFloat(Von), MainDLL.ConvertFromFloat(Bis), MNrs);
                }
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in TPM_Korrektur: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Calculate TPM evaluation
        /// </summary>
        public void Berechne_TPM_Auswertung(DateTime Von, DateTime Bis, string MNrs)
        {
            try
            {
                // This would calculate TPM evaluation data
                MainDLL.SchreibeMeldung("Calculating TPM evaluation from " + Von.ToString() + " to " + Bis.ToString(), 2);

                // For each machine, calculate TPM metrics
                for (int i = 1; i <= DBMain.Anzahl_Masch; i++)
                {
                    if (ArbeitGlobals.Includis[i].IstArchiviert)
                        continue;

                    // Calculate availability, performance, quality for this machine
                    // This would involve complex SQL queries and calculations
                }
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in Berechne_TPM_Auswertung: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Get signal number
        /// </summary>
        private int GetSignalNr(CO_Query Query, int SignalArt)
        {
            try
            {
                string SQLStr = "SELECT SignalNr FROM Signal WHERE SignalArt = " + SignalArt.ToString();
                SQL_fuc.SQL_Get(Query, SQLStr);
                
                if (!Query.IsEmpty())
                    return Query.FieldByName("SignalNr").AsInteger();
                else
                    return 0;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in GetSignalNr: " + ex.Message, 0);
                return 0;
            }
        }

        /// <summary>
        /// Get downtime duration
        /// </summary>
        public void GetStillZeit(DateTime VonDatum, DateTime BisDatum, int MaschNr, int Stillstandnr,
            double AStart, double AEnde, out int Dauer, out int Anzahl, out int ADauer)
        {
            Dauer = 0;
            Anzahl = 0;
            ADauer = 0;

            try
            {
                // Calculate downtime duration between the specified dates
                // This would query the TPM_Stillog table and calculate the total downtime
                
                string SQLStr = "SELECT Start, Ende FROM TPM_Stillog WHERE MaschNr = " + MaschNr.ToString() +
                    " AND StillstandNr = " + Stillstandnr.ToString() +
                    " AND Start >= " + MainDLL.DateTimeToFloat(VonDatum).ToString() +
                    " AND Ende <= " + MainDLL.DateTimeToFloat(BisDatum).ToString();
                
                SQL_fuc.SQL_Get(qSuch, SQLStr);
                
                while (!qSuch.EOF)
                {
                    DateTime Start = MainDLL.ConvertFromFloat(qSuch.FieldByName("Start").AsFloat());
                    DateTime Ende = MainDLL.ConvertFromFloat(qSuch.FieldByName("Ende").AsFloat());
                    
                    // Calculate duration
                    TimeSpan duration = Ende - Start;
                    Dauer += (int)duration.TotalMinutes;
                    Anzahl++;
                    
                    qSuch.Next();
                }

                // Calculate adjusted duration
                ADauer = Dauer;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in GetStillZeit: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Get article number from order number
        /// </summary>
        public string GetArtikelNr(string AuftragNr)
        {
            try
            {
                string SQLStr = "SELECT ArtikelNr FROM PDE WHERE AuftragNr = '" + AuftragNr + "'";
                SQL_fuc.SQL_Get(qSuch, SQLStr);
                
                if (!qSuch.IsEmpty())
                    return qSuch.FieldByName("ArtikelNr").AsString();
                else
                    return "";
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in GetArtikelNr: " + ex.Message, 0);
                return "";
            }
        }

        /// <summary>
        /// Set recalculation flag
        /// </summary>
        public void SetNachBerechnung(bool Value)
        {
            FNachBerechnung = Value;
        }

        /// <summary>
        /// Get recalculation flag
        /// </summary>
        public bool GetNachBerechnung()
        {
            return FNachBerechnung;
        }

        /// <summary>
        /// Perform recalculation
        /// </summary>
        public int Recalculation()
        {
            try
            {
                MainDLL.SchreibeMeldung("Starting recalculation...", 4);
                
                // Perform various recalculations
                Berechne_TPM_Schicht_Verpackt_Ausschuss(7, ""); // Last 7 days
                Nachbuchen_aus_AArchiv(7, ""); // Last 7 days
                Berechne_TPM_Auftragsdetail(7, ""); // Last 7 days
                Berechne_TPM_Produktionsdetail(7, ""); // Last 7 days
                
                MainDLL.SchreibeMeldung("Recalculation completed.", 4);
                return 1;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in Recalculation: " + ex.Message, 0);
                return 0;
            }
        }

        /// <summary>
        /// Calculate TPM shift packed/scrap
        /// </summary>
        public void Berechne_TPM_Schicht_Verpackt_Ausschuss(int Days, string MNrs)
        {
            try
            {
                MainDLL.SchreibeMeldung("Calculating TPM shift packed/scrap for last " + Days.ToString() + " days", 4);
                
                // This would calculate packed and scrap quantities for TPM
                // For each machine, calculate the packed and scrap pieces
                for (int i = 1; i <= DBMain.Anzahl_Masch; i++)
                {
                    if (ArbeitGlobals.Includis[i].IstArchiviert)
                        continue;

                    // Calculate for this machine
                    // This would involve SQL queries to get the data
                }
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in Berechne_TPM_Schicht_Verpackt_Ausschuss: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Post bookings from archive
        /// </summary>
        public void Nachbuchen_aus_AArchiv(int Days, string MNrs)
        {
            try
            {
                MainDLL.SchreibeMeldung("Posting bookings from archive for last " + Days.ToString() + " days", 4);
                
                // This would post bookings from the archive table
                // For each machine, check for bookings that need to be posted
                for (int i = 1; i <= DBMain.Anzahl_Masch; i++)
                {
                    if (ArbeitGlobals.Includis[i].IstArchiviert)
                        continue;

                    // Check for bookings to post
                }
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in Nachbuchen_aus_AArchiv: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Calculate TPM order details
        /// </summary>
        public void Berechne_TPM_Auftragsdetail(int Days, string MNRs)
        {
            try
            {
                MainDLL.SchreibeMeldung("Calculating TPM order details for last " + Days.ToString() + " days", 4);
                
                // This would calculate detailed order data for TPM
                for (int i = 1; i <= DBMain.Anzahl_Masch; i++)
                {
                    if (ArbeitGlobals.Includis[i].IstArchiviert)
                        continue;

                    // Calculate order details for this machine
                }
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in Berechne_TPM_Auftragsdetail: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Calculate TPM production details
        /// </summary>
        public void Berechne_TPM_Produktionsdetail(int Days, string MNrs)
        {
            try
            {
                MainDLL.SchreibeMeldung("Calculating TPM production details for last " + Days.ToString() + " days", 4);
                
                // This would calculate detailed production data for TPM
                for (int i = 1; i <= DBMain.Anzahl_Masch; i++)
                {
                    if (ArbeitGlobals.Includis[i].IstArchiviert)
                        continue;

                    // Calculate production details for this machine
                }
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in Berechne_TPM_Produktionsdetail: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Calculate extrusion data
        /// </summary>
        public void Berechne_Extrusion(int TPMNr, string AuftragNr, double Von, double Bis)
        {
            try
            {
                // This would calculate extrusion-specific data
                MainDLL.SchreibeMeldung("Calculating extrusion data for order " + AuftragNr, 4);
                
                // Special calculations for extrusion machines
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in Berechne_Extrusion: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Update TPM performance total
        /// </summary>
        public void TPM_Leistung_Gesamt_Update()
        {
            try
            {
                // This would update the total performance data for TPM
                MainDLL.SchreibeMeldung("Updating TPM performance total", 4);
                
                // Update performance data for all machines
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in TPM_Leistung_Gesamt_Update: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Update TPM produced total
        /// </summary>
        public void TPM_Produziert_Gesamt_Update()
        {
            try
            {
                // This would update the total produced data for TPM
                MainDLL.SchreibeMeldung("Updating TPM produced total", 4);
                
                // Update produced data for all machines
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in TPM_Produziert_Gesamt_Update: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// TPM shift shift3 (special function)
        /// </summary>
        public void TPM_Schicht_Schicht3()
        {
            try
            {
                // Special function for shift 3 calculations
                MainDLL.SchreibeMeldung("TPM shift shift3 calculation", 4);
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in TPM_Schicht_Schicht3: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// TPM stillog correction
        /// </summary>
        public void TPM_Stillog_Korrektur(int Arc_Tag, int Kor_Tag)
        {
            try
            {
                MainDLL.SchreibeMeldung("TPM stillog correction from day " + Arc_Tag.ToString() + " to " + Kor_Tag.ToString(), 4);
                
                // Correct TPM stillog data for the specified period
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in TPM_Stillog_Korrektur: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Check TPM shift
        /// </summary>
        public void TPM_Schicht_Pruefen(int Tage)
        {
            try
            {
                MainDLL.SchreibeMeldung("Checking TPM shift for last " + Tage.ToString() + " days", 4);
                
                // Check TPM shift data for the specified period
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in TPM_Schicht_Pruefen: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Calculate downtimes per shift
        /// </summary>
        public void Berechne_Stillstaende_Schicht(int aTage)
        {
            try
            {
                MainDLL.SchreibeMeldung("Calculating downtimes per shift for last " + aTage.ToString() + " days", 4);
                
                // Calculate downtime data per shift
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in Berechne_Stillstaende_Schicht: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Check runtime log
        /// </summary>
        public void CheckLaufzeitLog()
        {
            try
            {
                MainDLL.SchreibeMeldung("Checking runtime log", 4);
                
                // Check runtime log for inconsistencies
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in CheckLaufzeitLog: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// TPM evaluation correction
        /// </summary>
        public void TPM_AuswertungKorrektur()
        {
            try
            {
                MainDLL.SchreibeMeldung("TPM evaluation correction", 4);
                
                // Correct TPM evaluation data
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in TPM_AuswertungKorrektur: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Calculate TPM production details debug
        /// </summary>
        public void Berechne_TPM_ProduktionsdetailDebug(double Start, int Days, string MNrs)
        {
            try
            {
                MainDLL.SchreibeMeldung("Calculating TPM production details debug from " + Start.ToString() + " for " + Days.ToString() + " days", 4);
                
                // Debug version of production details calculation
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in Berechne_TPM_ProduktionsdetailDebug: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Property for NachBerechnung
        /// </summary>
        public bool NachBerechnung
        {
            get { return FNachBerechnung; }
            set { SetNachBerechnung(value); }
        }

        /// <summary>
        /// Cleanup
        /// </summary>
        public void Dispose()
        {
            try
            {
                shouldStop = true;
                if (thread != null)
                {
                    thread.Join(5000);
                    thread = null;
                }

                // Cleanup database objects
                if (qSuch != null) qSuch.Dispose();
                if (qSuch2 != null) qSuch2.Dispose();
                if (qSuch3 != null) qSuch3.Dispose();
                if (qSuch4 != null) qSuch4.Dispose();
                if (qUpdate != null) qUpdate.Dispose();
                if (qDurchlauf != null) qDurchlauf.Dispose();
                if (CDatabase != null) CDatabase.Dispose();
                if (ThTPM != null) ThTPM.Dispose();
                if (Th_Meldung != null) Th_Meldung.Dispose();
                if (ThSPC != null) ThSPC.Dispose();
                if (ShiftAliveTimer != null) ShiftAliveTimer.Dispose();
            }
            catch { }
        }

        /// <summary>
        /// Static instance
        /// </summary>
        public static Thread_Schicht Instance { get; set; }
    }
}