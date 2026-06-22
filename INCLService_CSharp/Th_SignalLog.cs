using System;
using System.Collections.Generic;
using System.Threading;

namespace INCLService_CSharp
{
    public class TSignalClass
    {
        public int SignalNr { get; set; } = 0;
        public int Nr { get; set; } = 0;
        public int MaschNr { get; set; } = 0;
        public string Istwert { get; set; } = "";
        public string oldwert { get; set; } = "";
        public int oldlognr { get; set; } = -1;
    }

    public class TThread_SignalLog : IDisposable
    {
        private CO_Database CDatabase;
        private CO_Query qSuch, qSuch2, qUpdate;
        private List<TSignalClass> entryList = new List<TSignalClass>();
        
        private Thread thread;
        private bool running = false;

        public TThread_SignalLog(bool suspended)
        {
            // Constructor
            CDatabase = new CO_Database();
            // In real implementation: CDatabase.UserName = DBUser; CDatabase.Password = DBPass; etc.

            qSuch = new CO_Query();
            qSuch.Database = CDatabase;

            qSuch2 = new CO_Query();
            qSuch2.Database = CDatabase;

            qUpdate = new CO_Query();
            qUpdate.Database = CDatabase;

            // Read signal list and current values
            if (CO_Setup2.GetParamInt(qSuch, "INCL_AutoSetup2Time") > 0)
            {
                qSuch.SQL = "SELECT sm.nr nr, sm.maschnr maschnr, s.signalnr signalnr, sm.istwert istwert" +
                    " FROM signale s " +
                    " LEFT JOIN signal_maschine sm ON sm.signalnr = s.signalnr " +
                    " WHERE s.logit=1 OR s.signalart = 24";
            }
            else
            {
                qSuch.SQL = "SELECT sm.nr nr, sm.maschnr maschnr, s.signalnr signalnr, sm.istwert istwert" +
                    " FROM signale s " +
                    " LEFT JOIN signal_maschine sm ON sm.signalnr = s.signalnr " +
                    " WHERE s.logit=1";
            }
            qSuch.Open();
            
            // In real implementation, we would read the results
            // while not qSuch.EOF do
            // {
            //   TSignalClass sc = new TSignalClass();
            //   sc.SignalNr = qSuch.FieldByName("signalnr").AsInteger;
            //   sc.Nr = qSuch.FieldByName("nr").AsInteger;
            //   sc.MaschNr = qSuch.FieldByName("maschnr").AsInteger;
            //   sc.Istwert = qSuch.FieldByName("istwert").AsString;
            //   sc.oldwert = "0";
            //   entryList.Add(sc);
            //   qSuch.Next;
            // }

            // Read old values in signal list
            qSuch.SQL = "SELECT * FROM signallog WHERE enddatumzeit IS null";
            qSuch.Open();
            // In real implementation, we would process the results
        }

        private string FloatToPunktStr(double aFloat)
        {
            string result = SQL_fuc.FloatToStr2(aFloat);
            if (result.Contains(","))
            {
                result = result.Replace(",", ".");
            }
            return result;
        }

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

        protected void Execute()
        {
            running = true;
            
            try
            {
                while (running)
                {
                    // Wait for signal event
                    // In real implementation: WaitForSingleObject(Event_SignalLog, INFINITE);
                    Thread.Sleep(1000);
                    
                    try
                    {
                        // Read current values and compare
                        // If changes, then create new entry
                        qSuch.SQL = "SELECT sm.nr nr, sm.maschnr maschnr, s.signalnr signalnr, sm.istwert istwert" +
                            " FROM signale s " +
                            " LEFT JOIN signal_maschine sm ON sm.signalnr = s.signalnr " +
                            " WHERE s.logit=1";
                        qSuch.Open();
                        
                        // In real implementation, we would process the results
                        // while not qSuch.EOF do
                        // {
                        //   TSignalClass sc = getSignalBySeqNumber(qSuch.FieldByName("nr").AsInteger);
                        //   if (sc != null)
                        //   {
                        //     sc.Istwert = qSuch.FieldByName("istwert").AsString;
                        //     if (sc.Istwert != sc.oldwert)
                        //     {
                        //       // Create new entry and end old one
                        //       if (sc.oldlognr > -1)
                        //       {
                        //         qUpdate.SQL = "UPDATE signallog SET enddatumzeit = " + FloatToPunktStr(DateTime.Now.ToOADate()) + " WHERE nr = " + sc.oldlognr;
                        //         qUpdate.ExecSQL();
                        //       }
                        //       sc.oldwert = sc.Istwert;
                        //       // Get next log number
                        //       qSuch2.SQL = "SELECT signallogid.nextval nv FROM dual";
                        //       qSuch2.Open();
                        //       sc.oldlognr = qSuch2.FieldByName("nv").AsInteger;
                        //       // Insert new entry
                        //       qUpdate.SQL = "INSERT INTO signallog (nr, startdatumzeit, wert, maschnr, signalnr) VALUES (" + sc.oldlognr + ", " + FloatToPunktStr(DateTime.Now.ToOADate()) + ", '" + sc.Istwert + "', " + sc.MaschNr + ", " + sc.SignalNr + ")";
                        //       qUpdate.ExecSQL();
                        //     }
                        //   }
                        //   qSuch.Next;
                        // }
                    }
                    catch { }
                }
            }
            catch { }
        }

        public void Start()
        {
            if (thread == null || !thread.IsAlive)
            {
                running = true;
                thread = new Thread(Execute);
                thread.IsBackground = true;
                thread.Start();
            }
        }

        public void Stop()
        {
            running = false;
            if (thread != null && thread.IsAlive)
            {
                thread.Join(1000); // Wait up to 1 second
            }
        }

        public void Dispose()
        {
            Stop();
            
            if (qSuch != null)
            {
                qSuch.Dispose();
                qSuch = null;
            }
            
            if (qSuch2 != null)
            {
                qSuch2.Dispose();
                qSuch2 = null;
            }
            
            if (qUpdate != null)
            {
                qUpdate.Dispose();
                qUpdate = null;
            }
            
            if (CDatabase != null)
            {
                CDatabase.Dispose();
                CDatabase = null;
            }
            
            entryList.Clear();
        }

        ~TThread_SignalLog()
        {
            Dispose();
        }
    }

    public static class SignalLogGlobals
    {
        public static TThread_SignalLog Thread_Signallog { get; set; }
        public static IntPtr Event_SignalLog { get; set; } = IntPtr.Zero;
    }
}
