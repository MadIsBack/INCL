// <summary>
// CO_Alivetimer.cs - C# translation of CO_Alivetimer.pas
// Alive timer for monitoring database heartbeat
// </summary>

using System;
using System.Collections.Generic;
using System.Timers;

namespace INCLService_CSharp
{
    /// <summary>
    /// Alive client class - monitors a specific application's heartbeat
    /// </summary>
    public class TCO_AliveClient : IDisposable
    {
        private int fTimeOut = 60; // Timeout in seconds
        private string FApplication = string.Empty;
        private CO_Database fDatabase = null;
        private object fOwner = null;
        private CO_Query FQuery = null;
        private string logpath = string.Empty;
        private string displayname = string.Empty;
        private bool WithoutTrigger = false;
        private bool fDelete = false;
        private double _diffTimeZoneDays = 0;
        private bool diffTimeZone = false;
        private string dBTimeZone = string.Empty;

        private Timer timer = null;
        private DateTime lastTick = DateTime.MinValue;
        private bool isAlive = true;

        /// <summary>
        /// Application name
        /// </summary>
        public string Application { get { return FApplication; } }

        /// <summary>
        /// Timeout in seconds
        /// </summary>
        public int TimeOut { get { return fTimeOut; } }

        /// <summary>
        /// Computer name
        /// </summary>
        public string ComputerName()
        {
            return Environment.MachineName;
        }

        /// <summary>
        /// Constructor
        /// </summary>
        public TCO_AliveClient(CO_Database aDatabase, string aApplication, int aTimeOut, 
            object AOwner, string lp = "", string dn = "", bool deleteOnDestroy = false)
        {
            fDatabase = aDatabase;
            FApplication = aApplication;
            fTimeOut = aTimeOut;
            fOwner = AOwner;
            logpath = lp;
            displayname = dn;
            fDelete = deleteOnDestroy;

            FQuery = new CO_Query(AOwner);
            FQuery.Database = fDatabase;

            // Start timer
            timer = new Timer(fTimeOut * 1000);
            timer.Elapsed += OnTimerElapsed;
            timer.AutoReset = true;
            timer.Enabled = true;
            timer.Start();

            lastTick = DateTime.Now;
            isAlive = true;
        }

        /// <summary>
        /// Timer tick - check if client is alive
        /// </summary>
        public bool tick()
        {
            try
            {
                lastTick = DateTime.Now;
                isAlive = true;
                return true;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in TCO_AliveClient.tick: " + ex.Message, 0);
                return false;
            }
        }

        /// <summary>
        /// Timer elapsed event
        /// </summary>
        private void OnTimerElapsed(object sender, ElapsedEventArgs e)
        {
            try
            {
                if ((DateTime.Now - lastTick).TotalSeconds > fTimeOut)
                {
                    if (isAlive)
                    {
                        isAlive = false;
                        // Trigger down event
                        MainDLL.SchreibeMeldung("AliveTimer: " + FApplication + " is DOWN", 0);
                    }
                }
                else
                {
                    if (!isAlive)
                    {
                        isAlive = true;
                        // Trigger up event
                        MainDLL.SchreibeMeldung("AliveTimer: " + FApplication + " is UP", 0);
                    }
                }
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in OnTimerElapsed: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Dispose method
        /// </summary>
        public void Dispose()
        {
            try
            {
                if (timer != null)
                {
                    timer.Stop();
                    timer.Dispose();
                    timer = null;
                }
                if (FQuery != null)
                {
                    FQuery.Close();
                    FQuery = null;
                }
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in TCO_AliveClient.Dispose: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Destructor
        /// </summary>
        ~TCO_AliveClient()
        {
            Dispose();
        }
    }

    /// <summary>
    /// Alive timer class - monitors multiple applications
    /// </summary>
    public class TCO_AliveTimer : IDisposable
    {
        private int fTimeOut = 60; // Timeout in seconds
        private string fMsgDown = "System is DOWN";
        private string fSubjectDown = "ALERT: System Down";
        private string fMsgUp = "System is UP";
        private string fSubjectUp = "INFO: System Up";
        private List<string> fToList = new List<string>();
        private List<string> fCCList = new List<string>();
        private List<string> fBCCList = new List<string>();
        private string fFromAddress = "includis@comtas.com";
        private string fSystem = "INCLService";
        private bool fAlert = false;
        private bool fAlertMerker = false;
        private bool fSystemOK = true;
        private object fOwner = null;
        private CO_Query FQuery = null;
        private Timer fTimer = null;
        private DateTime fLastTime = DateTime.MinValue;
        private DateTime fLastTimeintern = DateTime.MinValue;
        private int fMaxErrors = 3;

        private List<TCO_AliveClient> clients = new List<TCO_AliveClient>();

        /// <summary>
        /// Timeout in seconds
        /// </summary>
        public int TimeOut
        {
            get { return fTimeOut; }
            set { fTimeOut = value; }
        }

        /// <summary>
        /// Down message
        /// </summary>
        public string MsgDown
        {
            get { return fMsgDown; }
            set { fMsgDown = value; }
        }

        /// <summary>
        /// Down subject
        /// </summary>
        public string SubjectDown
        {
            get { return fSubjectDown; }
            set { fSubjectDown = value; }
        }

        /// <summary>
        /// Up message
        /// </summary>
        public string MsgUp
        {
            get { return fMsgUp; }
            set { fMsgUp = value; }
        }

        /// <summary>
        /// Up subject
        /// </summary>
        public string SubjectUp
        {
            get { return fSubjectUp; }
            set { fSubjectUp = value; }
        }

        /// <summary>
        /// To list
        /// </summary>
        public List<string> ToList
        {
            get { return fToList; }
            set { fToList = value; }
        }

        /// <summary>
        /// CC list
        /// </summary>
        public List<string> CCList
        {
            get { return fCCList; }
            set { fCCList = value; }
        }

        /// <summary>
        /// BCC list
        /// </summary>
        public List<string> BCCList
        {
            get { return fBCCList; }
            set { fBCCList = value; }
        }

        /// <summary>
        /// From address
        /// </summary>
        public string FromAddress
        {
            get { return fFromAddress; }
            set { fFromAddress = value; }
        }

        /// <summary>
        /// System name
        /// </summary>
        public string System
        {
            get { return fSystem; }
            set { fSystem = value; }
        }

        /// <summary>
        /// Last time
        /// </summary>
        public DateTime LastTime
        {
            get { return fLastTime; }
            set { fLastTime = value; }
        }

        /// <summary>
        /// Last time internal
        /// </summary>
        public DateTime LastTimeIntern
        {
            get { return fLastTimeintern; }
            set { fLastTimeintern = value; }
        }

        /// <summary>
        /// Max errors
        /// </summary>
        public int MaxErrors
        {
            get { return fMaxErrors; }
            set { fMaxErrors = value; }
        }

        /// <summary>
        /// Alert status
        /// </summary>
        public bool Alert
        {
            get { return fAlert; }
        }

        /// <summary>
        /// System OK status
        /// </summary>
        public bool SystemOK
        {
            get { return fSystemOK; }
        }

        /// <summary>
        /// Constructor
        /// </summary>
        public TCO_AliveTimer(CO_Database database, object owner)
        {
            fOwner = owner;
            FQuery = new CO_Query(owner);
            FQuery.Database = database;

            // Initialize timer
            fTimer = new Timer(fTimeOut * 1000);
            fTimer.Elapsed += OnTimer;
            fTimer.AutoReset = true;
            fTimer.Enabled = true;
            fTimer.Start();
        }

        /// <summary>
        /// Add client
        /// </summary>
        public void AddClient(string application, int timeout)
        {
            try
            {
                TCO_AliveClient client = new TCO_AliveClient(FQuery.Database, application, timeout, fOwner);
                clients.Add(client);
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in AddClient: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Remove client
        /// </summary>
        public void RemoveClient(string application)
        {
            try
            {
                for (int i = clients.Count - 1; i >= 0; i--)
                {
                    if (clients[i].Application == application)
                    {
                        clients[i].Dispose();
                        clients.RemoveAt(i);
                    }
                }
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in RemoveClient: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Timer event
        /// </summary>
        private void OnTimer(object sender, ElapsedEventArgs e)
        {
            try
            {
                // Check all clients
                foreach (TCO_AliveClient client in clients)
                {
                    if (!client.tick())
                    {
                        // Client is not responding
                        MainDLL.SchreibeMeldung("AliveTimer: Client " + client.Application + " not responding", 0);
                    }
                }
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in OnTimer: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Dispose method
        /// </summary>
        public void Dispose()
        {
            try
            {
                if (fTimer != null)
                {
                    fTimer.Stop();
                    fTimer.Dispose();
                    fTimer = null;
                }
                
                foreach (TCO_AliveClient client in clients)
                {
                    client.Dispose();
                }
                clients.Clear();
                
                if (FQuery != null)
                {
                    FQuery.Close();
                    FQuery = null;
                }
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in TCO_AliveTimer.Dispose: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Destructor
        /// </summary>
        ~TCO_AliveTimer()
        {
            Dispose();
        }
    }
}
