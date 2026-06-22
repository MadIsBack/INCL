using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Common;
using System.Timers;

namespace Komponenten_V63_CSharp
{
    public class CO_AliveClient : IDisposable
    {
        private int fTimeOut;
        private string FApplication;
        private CO_Database fDatabase;
        private object fOwner;
        private CO_Query FQuery;
        private string logpath = "";
        private string displayname = "";
        private bool WithoutTrigger = false;
        private bool fDelete = false;
        private double _diffTimeZoneDays = 0;
        private bool diffTimeZone = false;
        private string dBTimeZone = "";

        public string Application => FApplication;
        public int TimeOut => fTimeOut;

        public CO_AliveClient(CO_Database aDatabase, string aApplication, int aTimeOut, object AOwner,
            string lp = "", string dn = "", bool deleteOnDestroy = false)
        {
            if (!string.IsNullOrEmpty(lp))
            {
                int pos = lp.LastIndexOf('\\');
                if (pos >= 0)
                    logpath = lp.Substring(pos);
            }
            displayname = dn;
            fTimeOut = aTimeOut;
            FApplication = aApplication;
            fDatabase = aDatabase;
            fOwner = AOwner;
            fDelete = deleteOnDestroy;

            FQuery = new CO_Query();
            FQuery.Database = fDatabase;

            try
            {
                FQuery.SQL = "SELECT * FROM setup_par WHERE SCHLUESSEL IN ('INCL_AliveTimerWithoutTrigger', 'INCL_AliveTimerWithTimeDifference')";
                FQuery.Open();
                // In a real implementation, we would read the results
            }
            catch { }

            tick();
        }

        public bool tick()
        {
            bool result = false;
            try
            {
                string S = "SELECT * FROM alivetimer WHERE Application = '" + FApplication + "'";
                FQuery.SQL = S;
                FQuery.Open();
                
                if (/* FQuery.IsEmpty */ true) // Simplified for now
                {
                    if (WithoutTrigger)
                    {
                        S = "INSERT INTO alivetimer (Nr, Application, LastTimer, TimeOut, AliveMarker, dbtimestamp, ServiceDisplayName)" +
                            " VALUES (alivetimerID.nextval,'" + FApplication + "'," + FloatToPunktString(DateTime.Now.AddDays(_diffTimeZoneDays).ToOADate()) +
                            ", " + fTimeOut + ", 1, CAST(CURRENT_TIMESTAMP as FLOAT) + 2, '" + displayname + "')";
                    }
                    else
                    {
                        S = "INSERT INTO alivetimer (Nr, Application, LastTimer, TimeOut, AliveMarker, ServiceDisplayName)" +
                            " VALUES (alivetimerID.nextval,'" + FApplication + "'," + FloatToPunktString(DateTime.Now.ToOADate()) +
                            ", " + fTimeOut + ", 1, '" + displayname + "')";
                    }
                }
                else
                {
                    if (WithoutTrigger)
                    {
                        S = "UPDATE alivetimer SET LastTimer=" + FloatToPunktString(DateTime.Now.AddDays(_diffTimeZoneDays).ToOADate()) +
                            ", TimeOut= " + fTimeOut +
                            ", AliveMarker=" + (/* FQuery.FieldByName('alivemarker').AsInteger + 1 */ 1) +
                            ", dbtimestamp = CAST(CURRENT_TIMESTAMP as FLOAT) + 2" +
                            " WHERE Application = '" + FApplication + "'";
                    }
                    else
                    {
                        S = "UPDATE alivetimer SET LastTimer=" + FloatToPunktString(DateTime.Now.AddDays(_diffTimeZoneDays).ToOADate()) +
                            ", TimeOut= " + fTimeOut +
                            ", AliveMarker=" + (/* FQuery.FieldByName('alivemarker').AsInteger + 1 */ 1) +
                            " WHERE Application = '" + FApplication + "'";
                    }
                }
                
                FQuery.SQL = S;
                FQuery.ExecSQL();
                result = true;
            }
            catch { }

            if (!string.IsNullOrEmpty(logpath) && !string.IsNullOrEmpty(displayname))
            {
                try
                {
                    S = "SELECT * FROM ALIVETIMERCOMMENT WHERE Application = '" + FApplication + "'";
                    FQuery.SQL = S;
                    FQuery.Open();
                    if (/* FQuery.IsEmpty */ true) // Simplified
                    {
                        S = "INSERT INTO ALIVETIMERCOMMENT (Nr, Application, AliveComment, Logfile)" +
                            " VALUES (ALIVETIMERCOMMENTID.nextval,'" + FApplication + "', 'Restart Service " + displayname + " on " +
                            ComputerName + "', '" + ComputerName + logpath + "')";
                        FQuery.SQL = S;
                        FQuery.ExecSQL();
                    }
                }
                catch { }
            }

            return result;
        }

        private string FloatToPunktString(double aFloat)
        {
            string result = aFloat.ToString();
            if (result.Contains(","))
            {
                result = result.Replace(",", ".");
            }
            return result;
        }

        private string ComputerName()
        {
            return Environment.MachineName;
        }

        public void Dispose()
        {
            if (fDelete && FQuery != null)
            {
                FQuery.SQL = "DELETE FROM alivetimer WHERE Application = '" + FApplication + "'";
                FQuery.ExecSQL();
            }
            
            if (FQuery != null)
            {
                FQuery.Dispose();
                FQuery = null;
            }
        }

        ~CO_AliveClient()
        {
            Dispose();
        }
    }

    public class CO_AliveTimer : IDisposable
    {
        private int fTimeOut; // Timeout in Sekunden
        private string fMsgDown; // Message die beim Überschreiten des TO gesendet wird
        private string fSubjectDown; // Subject bei Überschreiten TO
        private string fMsgUp; // Message die bei Wiederaufnahme gesendet wird
        private string fSubjectUp; // Subject bei Wiederaufnahme
        private List<string> fToList = new List<string>(); // Liste der Mailadressen To:
        private List<string> fCCList = new List<string>(); // Liste der Mailadressen CC:
        private List<string> fBCCList = new List<string>(); // Liste der Mailadressen BCC:
        private string fFromAddress = ""; // Mailadresse die als Absender benutzt wird
        private string fSystem = ""; // Eintrag in INC_Meldung welches System überwacht wird
        private bool fAlert = false; // Alarm aktiv, wird nach Abfrage zurück gesetzt
        private bool fAlertMerker = false; // Alarmmerker
        private bool fSystemOK = false; // Meldung nach Alarm, wieder alles OK
        private object fOwner;
        private DateTime fLastTime; // Timer der auf TimeOut wartet
        private DateTime fLastTimeintern;
        private int fMaxErrors = 3;
        private CO_Query FQuery;
        private Timer fTimer;

        public int TimeOut { get => fTimeOut; set => fTimeOut = value; }
        public string MsgDown { get => fMsgDown; set => fMsgDown = value; }
        public string SubjectDown { get => fSubjectDown; set => fSubjectDown = value; }
        public string MsgUp { get => fMsgUp; set => fMsgUp = value; }
        public string SubjectUp { get => fSubjectUp; set => fSubjectUp = value; }
        public List<string> ToList { get => fToList; set => fToList = value; }
        public List<string> CCList { get => fCCList; set => fCCList = value; }
        public List<string> BCCList { get => fBCCList; set => fBCCList = value; }
        public string FromAddress { get => fFromAddress; set => fFromAddress = value; }
        public string System { get => fSystem; set => fSystem = value; }
        public DateTime LastTime { get => fLastTime; set => fLastTime = value; }
        public DateTime LastTimeIntern { get => fLastTimeintern; set => fLastTimeintern = value; }
        public int MaxErrors { get => fMaxErrors; set => fMaxErrors = value; }

        public bool Alert => getAlert();
        public bool SystemOK => getSystemOK();

        public CO_AliveTimer(CO_Database aDatabase, object AOwner)
        {
            fOwner = AOwner;
            FQuery = new CO_Query();
            FQuery.Database = aDatabase;

            fToList = new List<string>();
            fCCList = new List<string>();
            fBCCList = new List<string>();

            fMaxErrors = 3;
            fTimer = new Timer(5000); // 5 seconds interval
            fTimer.Elapsed += OnTimer;
            fTimer.Enabled = false;
            fAlertMerker = false;
            fSystemOK = false;
            fAlert = false;
        }

        private bool getAlert()
        {
            bool result = fAlert;
            fAlert = false;
            return result;
        }

        private bool getSystemOK()
        {
            bool result = fSystemOK;
            if (fSystemOK)
            {
                fSystemOK = false;
                fAlertMerker = false;
            }
            return result;
        }

        private void OnTimer(object sender, ElapsedEventArgs e)
        {
            // Check database field and remember alive marker
            string S = "SELECT * FROM alivetimer WHERE application = '" + fSystem + "'";
            FQuery.SQL = S;
            FQuery.Open();
            
            if (/* !FQuery.IsEmpty */ false) // Simplified for now
            {
                // fLastTimeintern = FQuery.FieldByName('lasttimer').AsFloat;
                FQuery.Close();
                
                // Check if timeout has been exceeded
                TimeSpan elapsed = DateTime.Now - fLastTimeintern;
                if (elapsed.TotalSeconds > (fTimeOut * fMaxErrors))
                {
                    fAlert = (!fAlertMerker) || fAlert;
                }
                else
                {
                    fSystemOK = fAlertMerker;
                }

                if (fAlert)
                    fAlertMerker = fAlert;
            }
        }

        public void StartTimer()
        {
            OnTimer(null, null);
            fTimer.Enabled = true;
        }

        public void Free()
        {
            Dispose();
        }

        public void Dispose()
        {
            if (fTimer != null)
            {
                fTimer.Enabled = false;
                fTimer.Dispose();
                fTimer = null;
            }

            if (FQuery != null)
            {
                FQuery.Dispose();
                FQuery = null;
            }
        }

        ~CO_AliveTimer()
        {
            Dispose();
        }
    }

    public class CO_AliveTimerList : List<CO_AliveTimer>
    {
        public new CO_AliveTimer this[int index]
        {
            get => base[index];
            set => base[index] = value;
        }

        public new int Add(CO_AliveTimer aAliveTimer)
        {
            base.Add(aAliveTimer);
            return base.Count - 1;
        }

        public new void RemoveAt(int index)
        {
            if (index >= 0 && index < base.Count)
            {
                var item = base[index];
                item.Dispose();
                base.RemoveAt(index);
            }
        }

        public void ClearAll()
        {
            foreach (var item in this)
            {
                item.Dispose();
            }
            base.Clear();
        }
    }
}
