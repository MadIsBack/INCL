using System;
using System.ServiceProcess;
using System.Threading;
using Microsoft.Win32;

namespace INCLService_CSharp
{
    public class CriticalSection : IDisposable
    {
        private object lockObj = new object();
        
        public void Enter()
        {
            Monitor.Enter(lockObj);
        }
        
        public void Leave()
        {
            Monitor.Exit(lockObj);
        }
        
        public void Dispose()
        {
            // Nothing to dispose for this simple implementation
        }
    }

    public partial class INCLServ : ServiceBase
    {
        public const int MAX_FILE_SIZE_MB = 4;
        public const string TRACE_DIR = "LOG";
        public const string SERVICE_DISPLAY_NAME = "INCLServer";

        private bool lastDBConnectStatus = false;
        private Thread serviceThread;
        private bool running = false;

        public static string DBUser { get; set; } = "includis";
        public static string INCLUDIS_HOME { get; set; } = "";
        public static CriticalSection CSLog { get; set; } = new CriticalSection();

        public INCLServ()
        {
            this.ServiceName = SERVICE_DISPLAY_NAME;
            this.EventLog.Log = "Application";
            
            // Set up service properties
            this.CanStop = true;
            this.CanPauseAndContinue = true;
            this.AutoLog = true;
        }

        protected override void OnStart(string[] args)
        {
            // Service start
            SetDBUser();
            
            // Start service thread
            running = true;
            serviceThread = new Thread(ServiceExecute);
            serviceThread.IsBackground = true;
            serviceThread.Start();
            
            EventLog.WriteEntry("INCLServer service started", EventLogEntryType.Information);
        }

        protected override void OnStop()
        {
            // Service stop
            running = false;
            if (serviceThread != null && serviceThread.IsAlive)
            {
                serviceThread.Join(5000); // Wait up to 5 seconds
            }
            
            EventLog.WriteEntry("INCLServer service stopped", EventLogEntryType.Information);
        }

        protected override void OnPause()
        {
            // Service pause
            EventLog.WriteEntry("INCLServer service paused", EventLogEntryType.Information);
            base.OnPause();
        }

        protected override void OnContinue()
        {
            // Service continue
            EventLog.WriteEntry("INCLServer service continued", EventLogEntryType.Information);
            base.OnContinue();
        }

        protected override void OnShutdown()
        {
            // Service shutdown
            OnStop();
            EventLog.WriteEntry("INCLServer service shutdown", EventLogEntryType.Information);
            base.OnShutdown();
        }

        private void ServiceExecute()
        {
            while (running)
            {
                try
                {
                    // Main service loop
                    // Check database connection
                    CheckDBConnection();
                    
                    // Perform service tasks
                    PerformServiceTasks();
                    
                    // Sleep for a while
                    Thread.Sleep(1000);
                }
                catch (Exception ex)
                {
                    EventLog.WriteEntry("Service error: " + ex.Message, EventLogEntryType.Error);
                }
            }
        }

        private void CheckDBConnection()
        {
            // Check database connection status
            bool currentStatus = DatenM.Instance != null && DatenM.Instance.Database != null && DatenM.Instance.Database.Connected;
            
            if (currentStatus != lastDBConnectStatus)
            {
                lastDBConnectStatus = currentStatus;
                if (currentStatus)
                {
                    EventLog.WriteEntry("Database connected", EventLogEntryType.Information);
                }
                else
                {
                    EventLog.WriteEntry("Database disconnected", EventLogEntryType.Warning);
                }
            }
        }

        private void PerformServiceTasks()
        {
            // Perform regular service tasks
            // This would include various database operations, monitoring, etc.
        }

        public void SetDBUser()
        {
            // Set database user from registry or configuration
            try
            {
                // Try to read from registry
                string subKey = "SOFTWARE\INCL\INCLServer";
                using (RegistryKey key = Registry.LocalMachine.OpenSubKey(subKey))
                {
                    if (key != null)
                    {
                        string dbUser = key.GetValue("DBUSER") as string;
                        if (!string.IsNullOrEmpty(dbUser))
                        {
                            DBUser = dbUser;
                        }
                    }
                }
            }
            catch
            {
                // Use default if registry read fails
                DBUser = "includis";
            }
        }
    }

    public static class MainGlobals
    {
        public static INCLServ INCLServ { get; set; }
    }
}
