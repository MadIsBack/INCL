// <summary>
// Th_SignalLog.cs - C# translation of Th_SignalLog.pas
// Thread for signal logging
// </summary>

using System;
using System.Collections.Generic;
using System.Threading;

namespace INCLService_CSharp
{
    /// <summary>
    /// Signal class for signal logging
    /// </summary>
    public class TSignalClass
    {
        public int SignalNr { get; set; } = 0;
        public int Nr { get; set; } = 0;
        public int MaschNr { get; set; } = 0;
        public string Istwert { get; set; } = string.Empty;
        public string oldwert { get; set; } = string.Empty;
        public int oldlognr { get; set; } = -1;
    }

    /// <summary>
    /// Signal logging thread class
    /// </summary>
    public class TThread_SignalLog : IDisposable
    {
        private CO_Database CDatabase;
        private CO_Query qSuch = new CO_Query();
        private CO_Query qSuch2 = new CO_Query();
        private CO_Query qUpdate = new CO_Query();
        private List<TSignalClass> entryList = new List<TSignalClass>();
        
        private Thread thread;
        private bool running = false;
        private bool suspended = false;

        /// <summary>
        /// Constructor
        /// </summary>
        public TThread_SignalLog(bool suspended)
        {
            try
            {
                this.suspended = suspended;
                
                // Initialize database connection
                CDatabase = new CO_Database();
                CDatabase.UserName = MainAzure.DBUser;
                CDatabase.Password = MainAzure.DBPass;
                CDatabase.Server = MainAzure.DBServer;
                CDatabase.InitialCatalog = MainAzure.DBInitialCatalog;

                qSuch.Database = CDatabase;
                qSuch2.Database = CDatabase;
                qUpdate.Database = CDatabase;

                // Read signal list and current values
                ReadSignalList();
                ReadOldValues();
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in TThread_SignalLog constructor: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Read signal list from database
        /// </summary>
        private void ReadSignalList()
        {
            try
            {
                entryList.Clear();
                
                string sql = string.Empty;
                if (CO_Setup2.TCO_Setup.GetParamInt(qSuch, "INCL_AutoSetup2Time") > 0)
                {
                    sql = "SELECT sm.nr nr, sm.maschnr maschnr, s.signalnr signalnr, sm.istwert istwert" +
                        " FROM signale s " +
                        " LEFT JOIN signal_maschine sm ON sm.signalnr = s.signalnr " +
                        " WHERE s.logit=1 OR s.signalart = 24";
                }
                else
                {
                    sql = "SELECT sm.nr nr, sm.maschnr maschnr, s.signalnr signalnr, sm.istwert istwert" +
                        " FROM signale s " +
                        " LEFT JOIN signal_maschine sm ON sm.signalnr = s.signalnr " +
                        " WHERE s.logit=1";
                }
                
                qSuch.SQL.Text = sql;
                qSuch.Open();
                
                while (!qSuch.EOF)
                {
                    TSignalClass sc = new TSignalClass();
                    sc.SignalNr = qSuch.FieldByName("signalnr").AsInteger;
                    sc.Nr = qSuch.FieldByName("nr").AsInteger;
                    sc.MaschNr = qSuch.FieldByName("maschnr").AsInteger;
                    sc.Istwert = qSuch.FieldByName("istwert").AsString;
                    sc.oldwert = "0";
                    entryList.Add(sc);
                    qSuch.Next();
                }
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in ReadSignalList: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Read old values from signal log
        /// </summary>
        private void ReadOldValues()
        {
            try
            {
                string sql = "SELECT * FROM signallog WHERE enddatumzeit IS null";
                qSuch.SQL.Text = sql;
                qSuch.Open();
                
                while (!qSuch.EOF)
                {
                    int nr = qSuch.FieldByName("nr").AsInteger;
                    int maschnr = qSuch.FieldByName("maschnr").AsInteger;
                    int signalnr = qSuch.FieldByName("signalnr").AsInteger;
                    string wert = qSuch.FieldByName("wert").AsString;
                    int lognr = qSuch.FieldByName("nr").AsInteger;
                    
                    TSignalClass sc = getSignalByNumbers(maschnr, signalnr);
                    if (sc != null)
                    {
                        sc.oldwert = wert;
                        sc.oldlognr = lognr;
                    }
                    qSuch.Next();
                }
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in ReadOldValues: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Convert float to string with point as decimal separator
        /// </summary>
        private string FloatToPunktStr(double aFloat)
        {
            string result = SQL_fuc.FloatToStr2(aFloat);
            if (result.Contains(","))
            {
                result = result.Replace(",", ".");
            }
            return result;
        }

        /// <summary>
        /// Get signal by machine number and signal number
        /// </summary>
        private TSignalClass getSignalByNumbers(int aMaschnr, int aSignalNr)
        {
            foreach (var sc in entryList)
            {
                if (sc.MaschNr == aMaschnr && sc.SignalNr == aSignalNr)
                {
                    return sc;
                }
            }
            return null;
        }

        /// <summary>
        /// Get signal by sequence number
        /// </summary>
        private TSignalClass getSignalBySeqNumber(int ANr)
        {
            foreach (var sc in entryList)
            {
                if (sc.Nr == ANr)
                {
                    return sc;
                }
            }
            return null;
        }

        /// <summary>
        /// Thread execution method
        /// </summary>
        protected void Execute()
        {
            running = true;
            
            try
            {
                while (running)
                {
                    // Wait for signal event or timeout
                    // In a real implementation, this would use WaitForSingleObject
                    // For now, we'll use a sleep
                    Thread.Sleep(1000);
                    
                    if (suspended)
                        continue;
                    
                    try
                    {
                        // Read current values and compare
                        ReadCurrentValuesAndCompare();
                    }
                    catch (Exception ex)
                    {
                        MainDLL.SchreibeMeldung("Error in SignalLog Execute: " + ex.Message, 0);
                    }
                }
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in SignalLog thread: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Read current values and compare with old values
        /// </summary>
        private void ReadCurrentValuesAndCompare()
        {
            try
            {
                string sql = "SELECT sm.nr nr, sm.maschnr maschnr, s.signalnr signalnr, sm.istwert istwert" +
                    " FROM signale s " +
                    " LEFT JOIN signal_maschine sm ON sm.signalnr = s.signalnr " +
                    " WHERE s.logit=1";
                qSuch.SQL.Text = sql;
                qSuch.Open();
                
                while (!qSuch.EOF)
                {
                    int nr = qSuch.FieldByName("nr").AsInteger;
                    int maschnr = qSuch.FieldByName("maschnr").AsInteger;
                    int signalnr = qSuch.FieldByName("signalnr").AsInteger;
                    string istwert = qSuch.FieldByName("istwert").AsString;
                    
                    TSignalClass sc = getSignalBySeqNumber(nr);
                    if (sc != null)
                    {
                        sc.Istwert = istwert;
                        if (sc.Istwert != sc.oldwert)
                        {
                            // Value changed, create new entry and end old one
                            if (sc.oldlognr > -1)
                            {
                                // End old entry
                                string updateSql = "UPDATE signallog SET enddatumzeit = " + 
                                    FloatToPunktStr(MainDLL.DateTimeToFloat(DateTime.Now)) + 
                                    " WHERE nr = " + sc.oldlognr;
                                qUpdate.SQL.Text = updateSql;
                                qUpdate.ExecSQL();
                            }
                            
                            sc.oldwert = sc.Istwert;
                            
                            // Get next log number
                            string nextValSql = "SELECT signallogid.nextval nv FROM dual";
                            qSuch2.SQL.Text = nextValSql;
                            qSuch2.Open();
                            if (!qSuch2.EOF)
                            {
                                sc.oldlognr = qSuch2.FieldByName("nv").AsInteger;
                            }
                            else
                            {
                                // For SQL Server
                                nextValSql = "SELECT ISNULL(MAX(nr), 0) + 1 FROM signallog";
                                qSuch2.SQL.Text = nextValSql;
                                qSuch2.Open();
                                if (!qSuch2.EOF)
                                {
                                    sc.oldlognr = qSuch2.FieldByName("nv").AsInteger;
                                }
                            }
                            
                            // Insert new entry
                            string insertSql = "INSERT INTO signallog (nr, startdatumzeit, wert, maschnr, signalnr) VALUES (" +
                                sc.oldlognr + ", " + FloatToPunktStr(MainDLL.DateTimeToFloat(DateTime.Now)) + 
                                ", '" + sc.Istwert.Replace("'", "''") + ", " + sc.MaschNr + ", " + sc.SignalNr + ")";
                            qUpdate.SQL.Text = insertSql;
                            qUpdate.ExecSQL();
                        }
                    }
                    qSuch.Next();
                }
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in ReadCurrentValuesAndCompare: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Start the thread
        /// </summary>
        public void Start()
        {
            try
            {
                if (thread == null || !thread.IsAlive)
                {
                    running = true;
                    suspended = false;
                    thread = new Thread(Execute);
                    thread.IsBackground = true;
                    thread.Start();
                }
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in SignalLog Start: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Stop the thread
        /// </summary>
        public void Stop()
        {
            try
            {
                running = false;
                if (thread != null && thread.IsAlive)
                {
                    thread.Join(1000); // Wait up to 1 second
                }
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in SignalLog Stop: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Suspend the thread
        /// </summary>
        public void Suspend()
        {
            suspended = true;
        }

        /// <summary>
        /// Resume the thread
        /// </summary>
        public void Resume()
        {
            suspended = false;
        }

        /// <summary>
        /// Dispose method
        /// </summary>
        public void Dispose()
        {
            try
            {
                Stop();
                
                if (qSuch != null)
                {
                    qSuch.Close();
                    qSuch.Dispose();
                    qSuch = null;
                }
                
                if (qSuch2 != null)
                {
                    qSuch2.Close();
                    qSuch2.Dispose();
                    qSuch2 = null;
                }
                
                if (qUpdate != null)
                {
                    qUpdate.Close();
                    qUpdate.Dispose();
                    qUpdate = null;
                }
                
                if (CDatabase != null)
                {
                    CDatabase.Connected = false;
                    CDatabase = null;
                }
                
                entryList.Clear();
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in SignalLog Dispose: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Destructor
        /// </summary>
        ~TThread_SignalLog()
        {
            Dispose();
        }
    }

    /// <summary>
    /// Signal logging globals
    /// </summary>
    public static class SignalLogGlobals
    {
        public static TThread_SignalLog Thread_Signallog { get; set; } = null;
        public static IntPtr Event_SignalLog { get; set; } = IntPtr.Zero;
    }
}
