// <summary>
// Main.cs - C# translation of Main.pas
// Main service class for INCLService
// </summary>

using System;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.ServiceProcess;
using System.Threading;
using Microsoft.Win32;

namespace INCLService_CSharp
{
    /// <summary>
    /// INCL Service - Windows Service for INCLUDIS calculation
    /// </summary>
    public partial class INCLService : ServiceBase
    {
        private const int MAX_FILE_SIZE_MB = 4;
        private const string TRACE_DIR = "LOG";
        private const string SERVICE_DISPLAY_NAME = "INCLServer";

        private bool lastDBConnectStatus = true;
        private CriticalSection CSLog = new CriticalSection();
        
        public static string DBUser = "includis";
        public static string DBServer = "db";
        public static string DBPass = "comtas";
        public static string DBInitialCatalog = "includis";
        public static string DBProvider = "";
        public static string INCLUDIS_HOME = "";

        public INCLService()
        {
            this.ServiceName = SERVICE_DISPLAY_NAME + DBUser.ToUpper();
            this.DisplayName = SERVICE_DISPLAY_NAME + DBUser.ToUpper();
            this.EventLog.Log = "Application";
            
            // Set up service description
            this.CanPauseAndContinue = true;
            this.CanShutdown = true;
            this.CanStop = true;
        }

        /// <summary>
        /// Main service execution
        /// </summary>
        protected override void OnStart(string[] args)
        {
            try
            {
                // Initialize COM for database connections
                if (DBMain.INCLUDISDatabaseTyp == 1)
                {
                    // For SQL Server connections
                }

                // Create critical section for logging
                CSLog = new CriticalSection();
                lastDBConnectStatus = true;

                // Log compilation switches
                string switches = GetCompilationSwitches();
                SchreibeMeldung("Compiled with switches: " + switches, 0);

                // Set database user from parameters
                SetDBUser();

                // Wait for database connection
                while (!DatenM.Database.Connected && !this.IsStopping)
                {
                    // Process service requests
                    Thread.Sleep(100);

                    if (CheckDBVerbindung())
                    {
                        try
                        {
                            SchreibeMeldung("Connected.", 0);
                            DatenM.Database.Connected = false;
                            DatenM.Database.UserName = DBUser;
                            DatenM.Database.Password = DBPass;
                            DatenM.Database.Server = DBServer;
                            
                            if (DBMain.INCLUDISDatabaseTyp == 1)
                            {
                                DatenM.Database.InitialCatalog = DBInitialCatalog;
                                DatenM.Database.SqlProvider = DBProvider;
                            }
                            
                            DatenM.Database.Connected = true;
                        }
                        catch (Exception ex)
                        {
                            SchreibeMeldung("Error connecting: " + ex.Message, 0);
                        }
                    }

                    if (!DatenM.Database.Connected)
                    {
                        if (lastDBConnectStatus)
                        {
                            lastDBConnectStatus = false;
                            SchreibeMeldung("Database not available.", 0);
                        }
                    }
                    else
                    {
                        if (!lastDBConnectStatus)
                        {
                            lastDBConnectStatus = true;
                        }
                    }

                    if (!DatenM.Database.Connected && !this.IsStopping)
                    {
                        SchreibeMeldung("Wait 30 sec.", 0);
                        Thread.Sleep(30000);
                    }
                }

                if (this.IsStopping)
                    return;

                // Initialize S7Main
                bool S7MainOK = true;
                SchreibeMeldung("Database connection successfully... Start program...", 0);
                
                try
                {
                    // S7Main would be initialized here
                    // For now, we'll use a placeholder
                    S7Main.Initialize();
                }
                catch (Exception ex)
                {
                    SchreibeMeldung("Error Service.Create: " + ex.Message, 0);
                    S7MainOK = false;
                }

                // Main service loop
                while (!this.IsStopping)
                {
                    // Process service requests
                    Thread.Sleep(100);
                    
                    if (!S7MainOK)
                    {
                        // Error occurred during execution, restart
                        try
                        {
                            S7Main.Cleanup();
                        }
                        catch { }

                        SchreibeMeldung("New start program...", 0);
                        try
                        {
                            S7Main.Initialize();
                        }
                        catch (Exception ex)
                        {
                            SchreibeMeldung("Error Service.Create: " + ex.Message, 0);
                        }
                        S7MainOK = true;
                    }
                }
            }
            finally
            {
                CSLog?.Dispose();
                
                if (DBMain.INCLUDISDatabaseTyp == 1)
                {
                    // CoUninitialize for COM
                }
            }
        }

        /// <summary>
        /// Stop the service
        /// </summary>
        protected override void OnStop()
        {
            SchreibeMeldung("Service Stop...", 0);
            S7Main.Cleanup();
        }

        /// <summary>
        /// Pause the service
        /// </summary>
        protected override void OnPause()
        {
            SchreibeMeldung("Service Pause...", 0);
            base.OnPause();
        }

        /// <summary>
        /// Continue the service
        /// </summary>
        protected override void OnContinue()
        {
            SchreibeMeldung("Service Continued...", 0);
            base.OnContinue();
        }

        /// <summary>
        /// Service shutdown
        /// </summary>
        protected override void OnShutdown()
        {
            SchreibeMeldung("Service Shutdown...", 0);
            base.OnShutdown();
        }

        /// <summary>
        /// Before install
        /// </summary>
        protected override void OnInstall(System.Collections.Specialized.NameValueCollection parameters)
        {
            SetDBUser();
            this.DisplayName = SERVICE_DISPLAY_NAME + DBUser.ToUpper();
            this.ServiceName = this.DisplayName;
            CSLog = new CriticalSection();
            
            base.OnInstall(parameters);
        }

        /// <summary>
        /// After install
        /// </summary>
        protected override void OnAfterInstall()
        {
            SetDBUser();
            
            try
            {
                using (RegistryKey reg = Registry.LocalMachine.OpenSubKey(
                    @"System\CurrentControlSet\Services\" + this.ServiceName, true))
                {
                    if (reg != null)
                    {
                        reg.SetValue("Description", "INCLUDIS Service for Calculation for User " + DBUser);
                        reg.SetValue("ImagePath", System.Reflection.Assembly.GetExecutingAssembly().Location + 
                            " /DBUSER=" + DBUser + " /DBSERVER=" + DBServer);
                    }
                }
            }
            catch (Exception ex)
            {
                SchreibeMeldung("Error in OnAfterInstall: " + ex.Message, 0);
            }
            
            base.OnAfterInstall();
        }

        /// <summary>
        /// Set database user from parameters
        /// </summary>
        private void SetDBUser()
        {
            const string kDBUser = "DBUSER=";
            const string kDBPass = "DBPASS=";
            const string kDBServer = "DBSERVER=";

            DBUser = "";
            DBPass = "";
            DBServer = "";

            // Check command line parameters
            string[] args = Environment.GetCommandLineArgs();
            for (int i = 0; i < args.Length; i++)
            {
                string arg = args[i].ToUpper();
                
                if (arg.Contains(kDBUser))
                {
                    DBUser = args[i].Substring(arg.IndexOf(kDBUser) + kDBUser.Length);
                    if (DBUser.Length > 100)
                        DBUser = DBUser.Substring(0, 100);
                }
                
                if (arg.Contains(kDBPass))
                {
                    DBPass = args[i].Substring(arg.IndexOf(kDBPass) + kDBPass.Length);
                    if (DBPass.Length > 100)
                        DBPass = DBPass.Substring(0, 100);
                }
                
                if (arg.Contains(kDBServer))
                {
                    DBServer = args[i].Substring(arg.IndexOf(kDBServer) + kDBServer.Length);
                    if (DBServer.Length > 100)
                        DBServer = DBServer.Substring(0, 100);
                }
            }

            // Set defaults if not provided
            if (string.IsNullOrEmpty(DBUser))
                DBUser = "INCLUDIS";

            if (string.IsNullOrEmpty(DBPass))
                DBPass = "comtas";

            if (string.IsNullOrEmpty(DBServer))
                DBServer = "includis.world";

            if (string.IsNullOrEmpty(DBInitialCatalog))
                DBInitialCatalog = DBUser;

            DBUser = DBUser.ToUpper();

            // Read from INI file
            string iniPath = Path.Combine(Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location), 
                "INCL_" + DBUser + ".ini");

            try
            {
                var ini = new IniFiles.TIniFile(iniPath);
                DBServer = ini.ReadString("Database", "DB_Server", "includis.world");
                DBInitialCatalog = ini.ReadString("Database", "InitialCatalog", DBUser);
                DBProvider = ini.ReadString("Database", "Provider", DBProvider);
                
                ini.WriteString("Database", "DB_Server", DBServer);
                ini.WriteString("Database", "Provider", DBProvider);
                
                if (DBMain.INCLUDISDatabaseTyp == 1)
                {
                    ini.WriteString("Database", "InitialCatalog", DBInitialCatalog);
                }
                
                INCLUDIS_HOME = ini.ReadString("Main", "Home", "d:\\comtas\\");
                ini.Free();
            }
            catch (Exception ex)
            {
                SchreibeMeldung("Error reading INI file: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Get compilation switches
        /// </summary>
        private string GetCompilationSwitches()
        {
            System.Collections.Generic.List<string> switches = new System.Collections.Generic.List<string>();
            
            // These would be set based on compilation defines
            // For now, return a placeholder
            switches.Add("INCL_MSADO");
            
            return string.Join(";", switches);
        }

        /// <summary>
        /// Check database connection
        /// </summary>
        public static bool CheckDBVerbindung()
        {
            try
            {
                SchreibeMeldung("Check connect.", 0);
                
                // Create a temporary database connection
                var iData = new CO_DataBase.CO_Database();
                
                try
                {
                    iData.Connected = false;
                    iData.UserName = DBUser;
                    iData.Password = DBPass;
                    iData.Server = DBServer;
                    
                    if (DBMain.INCLUDISDatabaseTyp == 1)
                    {
                        iData.InitialCatalog = DBInitialCatalog;
                        iData.SqlProvider = DBProvider;
                        SchreibeMeldung("Using " + DBUser + "@" + DBServer + " (" + DBInitialCatalog + ") - Provider:" + iData.SqlProvider, 0);
                    }
                    else
                    {
                        SchreibeMeldung("Using " + DBUser + "@" + DBServer, 0);
                    }
                    
                    iData.Connected = true;
                    
                    if (iData.Connected)
                    {
                        SchreibeMeldung("Connect Ok.", 0);
                        return true;
                    }
                    else
                    {
                        SchreibeMeldung("Connect failed.", 0);
                        return false;
                    }
                }
                finally
                {
                    try
                    {
                        iData.Connected = false;
                    }
                    catch { }
                    
                    try
                    {
                        iData.Dispose();
                    }
                    catch { }
                }
            }
            catch (Exception ex)
            {
                SchreibeMeldung("Error in CheckDBVerbindung: " + ex.Message, 0);
                return false;
            }
        }

        /// <summary>
        /// Force backslash at end of string
        /// </summary>
        public static string ForceBackSlash(string S)
        {
            if (string.IsNullOrEmpty(S))
                return S;
            
            if (S[S.Length - 1] != '\\')
                return S + '\\';
            else
                return S;
        }

        /// <summary>
        /// Write message to log file
        /// </summary>
        public static void SchreibeMeldung(string Meldung, int Modus)
        {
            try
            {
                if (string.IsNullOrEmpty(INCLUDIS_HOME))
                    return;

                INCLUDIS_HOME = ForceBackSlash(INCLUDIS_HOME);
                string MeldeDir = ForceBackSlash(INCLUDIS_HOME + TRACE_DIR);

                // Create directory if it doesn't exist
                if (!Directory.Exists(MeldeDir))
                {
                    try
                    {
                        Directory.CreateDirectory(MeldeDir);
                    }
                    catch
                    {
                        return;
                    }
                }

                // Determine log file based on mode
                string MeldeFile = "";
                switch (Modus)
                {
                    case 0: MeldeFile = Path.Combine(MeldeDir, "svc_" + DBUser.ToLower() + "_trace.log"); break;
                    case 1: MeldeFile = Path.Combine(MeldeDir, "svc_" + DBUser.ToLower() + "_timer.log"); break;
                    case 2: MeldeFile = Path.Combine(MeldeDir, "svc_" + DBUser.ToLower() + "_shift.log"); break;
                    case 3: MeldeFile = Path.Combine(MeldeDir, "svc_" + DBUser.ToLower() + "_addons.log"); break;
                    case 4: MeldeFile = Path.Combine(MeldeDir, "svc_" + DBUser.ToLower() + "_recalc.log"); break;
                    case 5: MeldeFile = Path.Combine(MeldeDir, "svc_" + DBUser.ToLower() + "_memory.log"); break;
                    case 6: MeldeFile = Path.Combine(MeldeDir, "svc_" + DBUser.ToLower() + "_down.log"); break;
                    case 7: MeldeFile = Path.Combine(MeldeDir, "svc_" + DBUser.ToLower() + "_memdbg.log"); break;
                    default: MeldeFile = Path.Combine(MeldeDir, "svc_" + DBUser.ToLower() + "_trace.log"); break;
                }

                // Check file size and rotate if needed
                if (File.Exists(MeldeFile))
                {
                    FileInfo fi = new FileInfo(MeldeFile);
                    if (fi.Length > MAX_FILE_SIZE_MB * 1024 * 1024)
                    {
                        // Rotate log file
                        try
                        {
                            string backupFile = MeldeFile + ".old";
                            if (File.Exists(backupFile))
                                File.Delete(backupFile);
                            File.Move(MeldeFile, backupFile);
                        }
                        catch { }
                    }
                }

                // Write message to log file
                string S = MainDLL.DateTimeToStr(MainDLL.N_o_w) + " : " + Meldung;
                
                // Check for specific error patterns
                if (S.Contains("Gleitkommawert") || S.Contains("invalid month") || S.Contains("invalid number"))
                {
                    S += "\n  DecimalSeparator: " + System.Globalization.CultureInfo.CurrentCulture.NumberFormat.NumberDecimalSeparator;
                    S += "\n  ThousandSeparator: " + System.Globalization.CultureInfo.CurrentCulture.NumberFormat.NumberGroupSeparator;
                    S += "\n  ShortDateFormat: " + System.Globalization.CultureInfo.CurrentCulture.DateTimeFormat.ShortDatePattern;
                    S += "\n  ShortTimeFormat: " + System.Globalization.CultureInfo.CurrentCulture.DateTimeFormat.ShortTimePattern;
                }

                File.AppendAllText(MeldeFile, S + Environment.NewLine);
            }
            catch (Exception ex)
            {
                // Fallback to event log if file logging fails
                EventLog.WriteEntry("Application", "Error writing log: " + ex.Message, EventLogEntryType.Error);
            }
        }

        /// <summary>
        /// Critical section for thread-safe logging
        /// </summary>
        public class CriticalSection : IDisposable
        {
            private readonly object _lock = new object();

            public void Enter()
            {
                Monitor.Enter(_lock);
            }

            public void Leave()
            {
                Monitor.Exit(_lock);
            }

            public void Dispose()
            {
                // Nothing to dispose, but implement IDisposable for compatibility
            }
        }
    }

    /// <summary>
    /// Service entry point
    /// </summary>
    public static class Program
    {
        static void Main(string[] args)
        {
            // Check if we're running as a service or console
            if (Environment.UserInteractive)
            {
                // Running as console application (for debugging)
                INCLService service = new INCLService();
                
                // Set up console control handler
                Console.CancelKeyPress += (sender, e) => {
                    service.Stop();
                    e.Cancel = true;
                };
                
                Console.WriteLine("INCL Service - Console Mode");
                Console.WriteLine("Press Ctrl+C to stop...");
                
                service.OnDebug();
                service.Start(args);
                
                // Wait for service to stop
                while (service.IsRunning)
                {
                    Thread.Sleep(1000);
                }
            }
            else
            {
                // Running as Windows Service
                ServiceBase[] ServicesToRun;
                ServicesToRun = new ServiceBase[] { new INCLService() };
                ServiceBase.Run(ServicesToRun);
            }
        }
    }
}
