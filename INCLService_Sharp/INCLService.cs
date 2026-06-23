using System;
using System.IO;
using System.ServiceProcess;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using INCLUDIS.Utils.CommonDB;

namespace INCLService_Sharp
{
    /// <summary>
    /// INCLServer Windows Service
    /// Mandantenfähigkeit: Durch Angabe des Datenbankbenutzers (DBUSER)
    /// wird der Dienst nach Kompilierung für den jeweiligen Mandanten erstellt:
    /// SERVICE_DISPLAY_NAME + DBUSER ist der Dienstname im MS Dienst-Manager.
    /// </summary>
    public partial class INCLService : ServiceBase
    {
        private const string SERVICE_DISPLAY_NAME = "INCLServer";
        private const int MAX_FILE_SIZE_MB = 4;
        private const string TRACE_DIR = "LOG";

        private static string INCLUDIS_HOME = string.Empty;
        private static readonly object CSLog = new object();
        
        public static string DBUser = "includis";
        public static string DBServer = "db";
        public static string DBPass = "comtas";
        public static string DBInitialCatalog = "includis";
        public static string DBProvider = string.Empty;

        private bool lastDBConnectStatus = true;
        private bool S7MainOK = true;
        private S7Main s7Main;
        private bool terminated = false;
        private readonly ILogger<INCLService> logger;

        public INCLService()
        {
            this.ServiceName = SERVICE_DISPLAY_NAME + DBUser.ToUpper();
            this.DisplayName = SERVICE_DISPLAY_NAME + DBUser.ToUpper();
            this.CanPauseAndContinue = true;
            this.AutoLog = true;
            
            // Initialize logger
            var loggerFactory = LoggerFactory.Create(builder =>
            {
                builder.AddConsole();
            });
            logger = loggerFactory.CreateLogger<INCLService>();
        }

        protected override void OnStart(string[] args)
        {
            WriteMessage("Service starting...", 0);
            SetDBUser(args);
            
            // Initialize and start the service
            Task.Run(() => ServiceExecute());
        }

        protected override void OnStop()
        {
            terminated = true;
            WriteMessage("Service Stop...", 0);
            
            // Clean up
            s7Main?.Dispose();
            base.OnStop();
        }

        protected override void OnPause()
        {
            WriteMessage("Service Pause...", 0);
            base.OnPause();
        }

        protected override void OnContinue()
        {
            WriteMessage("Service Continued...", 0);
            base.OnContinue();
        }

        protected override void OnShutdown()
        {
            WriteMessage("Service Shutdown...", 0);
            base.OnShutdown();
        }

        /// <summary>
        /// Main service execution loop
        /// </summary>
        private async Task ServiceExecute()
        {
            try
            {
                lastDBConnectStatus = true;
                
                WriteMessage("Compiled with switches: ", 0);
                
                // Wait for database connection
                while (!CheckDBVerbindung() && !terminated)
                {
                    if (!lastDBConnectStatus)
                    {
                        lastDBConnectStatus = false;
                        WriteMessage("Database not available.", 0);
                    }
                    
                    WriteMessage("Wait 30 sec.", 0);
                    await Task.Delay(30000);
                }

                if (terminated)
                    return;

                S7MainOK = true;
                WriteMessage("Database connection successfully... Start programm...", 0);
                
                try
                {
                    s7Main = new S7Main(this);
                }
                catch (Exception ex)
                {
                    WriteMessage("Error Service.Create: " + ex.Message, 0);
                }

                while (!terminated)
                {
                    // Process requests
                    await Task.Delay(1000);
                    
                    if (!S7MainOK)
                    {
                        // An error occurred during execution, restart
                        try
                        {
                            s7Main?.Dispose();
                        }
                        catch { }

                        WriteMessage("New start program...", 0);
                        try
                        {
                            s7Main = new S7Main(this);
                        }
                        catch (Exception ex)
                        {
                            WriteMessage("Error Service.Create: " + ex.Message, 0);
                        }
                        S7MainOK = true;
                    }
                }
            }
            catch (Exception ex)
            {
                WriteMessage("Error in ServiceExecute: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Check database connection
        /// </summary>
        private bool CheckDBVerbindung()
        {
            WriteMessage("Check connect.", 0);
            
            try
            {
                using (var cdb = new CommonDB())
                {
                    cdb.UserName = DBUser;
                    cdb.Password = DBPass;
                    cdb.Server = DBServer;
                    cdb.InitialCatalog = DBInitialCatalog;
                    cdb.SqlProvider = DBProvider;
                    
                    WriteMessage("Using " + DBUser + "@" + DBServer + " (" + DBInitialCatalog + ")" + " - Provider:" + DBProvider, 0);
                    
                    cdb.Connected = true;
                    
                    if (cdb.Connected)
                    {
                        WriteMessage("Connect Ok.", 0);
                        return true;
                    }
                    else
                    {
                        WriteMessage("Connect failed.", 0);
                        return false;
                    }
                }
            }
            catch (Exception ex)
            {
                WriteMessage("Connect failed: " + ex.Message, 0);
                return false;
            }
        }

        /// <summary>
        /// Set database user from command line parameters
        /// </summary>
        private void SetDBUser(string[] args)
        {
            const string kDBUser = "DBUSER=";
            const string kDBPass = "DBPASS=";
            const string kDBServer = "DBSERVER=";

            DBUser = string.Empty;
            DBPass = string.Empty;
            DBServer = string.Empty;

            if (args != null && args.Length > 0)
            {
                foreach (var arg in args)
                {
                    var upperArg = arg.ToUpper();
                    if (upperArg.Contains(kDBUser.ToUpper()))
                    {
                        DBUser = arg.Substring(upperArg.IndexOf(kDBUser.ToUpper()) + kDBUser.Length);
                    }
                    if (upperArg.Contains(kDBPass.ToUpper()))
                    {
                        DBPass = arg.Substring(upperArg.IndexOf(kDBPass.ToUpper()) + kDBPass.Length);
                    }
                    if (upperArg.Contains(kDBServer.ToUpper()))
                    {
                        DBServer = arg.Substring(upperArg.IndexOf(kDBServer.ToUpper()) + kDBServer.Length);
                    }
                }
            }

            if (string.IsNullOrEmpty(DBUser))
                DBUser = "INCLUDIS";

            if (string.IsNullOrEmpty(DBPass))
                DBPass = "comtas";

            if (string.IsNullOrEmpty(DBServer))
                DBServer = "includis.world";

            if (string.IsNullOrEmpty(DBInitialCatalog))
                DBInitialCatalog = DBUser;

            DBUser = DBUser.ToUpper();

            // Load from INI file
            var inifn = Path.Combine(Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location), 
                "INCL_" + DBUser + ".ini");
            
            if (File.Exists(inifn))
            {
                // TODO: Implement INI file reading
                // For now, use default values
            }
        }

        /// <summary>
        /// Write message to log file
        /// </summary>
        public static void WriteMessage(string message, int mode)
        {
            try
            {
                if (string.IsNullOrEmpty(INCLUDIS_HOME))
                    return;

                INCLUDIS_HOME = ForceBackSlash(INCLUDIS_HOME);
                var meldeDir = ForceBackSlash(INCLUDIS_HOME + TRACE_DIR);

                if (!Directory.Exists(meldeDir))
                {
                    Directory.CreateDirectory(meldeDir);
                }

                string meldeFile = mode switch
                {
                    0 => Path.Combine(meldeDir, "svc_" + DBUser.ToLower() + "_trace.log"),
                    1 => Path.Combine(meldeDir, "svc_" + DBUser.ToLower() + "_timer.log"),
                    2 => Path.Combine(meldeDir, "svc_" + DBUser.ToLower() + "_shift.log"),
                    3 => Path.Combine(meldeDir, "svc_" + DBUser.ToLower() + "_addons.log"),
                    4 => Path.Combine(meldeDir, "svc_" + DBUser.ToLower() + "_recalc.log"),
                    5 => Path.Combine(meldeDir, "svc_" + DBUser.ToLower() + "_memory.log"),
                    6 => Path.Combine(meldeDir, "svc_" + DBUser.ToLower() + "_down.log"),
                    7 => Path.Combine(meldeDir, "svc_" + DBUser.ToLower() + "_memdbg.log"),
                    _ => Path.Combine(meldeDir, "svc_" + DBUser.ToLower() + "_trace.log")
                };

                var s = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + " : " + message;

                // Check file size
                if (File.Exists(meldeFile))
                {
                    var fileInfo = new FileInfo(meldeFile);
                    if (fileInfo.Length > (MAX_FILE_SIZE_MB * 1024 * 1024))
                    {
                        File.WriteAllText(meldeFile, s + Environment.NewLine);
                    }
                    else
                    {
                        File.AppendAllText(meldeFile, s + Environment.NewLine);
                    }
                }
                else
                {
                    File.WriteAllText(meldeFile, s + Environment.NewLine);
                }

                // Check for specific error patterns
                if (message.Contains("Gleitkommawert") || message.Contains("invalid month") || message.Contains("invalid number"))
                {
                    File.AppendAllText(meldeFile, "  DecimalSeparator: " + System.Globalization.CultureInfo.CurrentCulture.NumberFormat.NumberDecimalSeparator + Environment.NewLine);
                    File.AppendAllText(meldeFile, "  ThousandSeparator: " + System.Globalization.CultureInfo.CurrentCulture.NumberFormat.NumberGroupSeparator + Environment.NewLine);
                    File.AppendAllText(meldeFile, "  ShortDateFormat: " + System.Globalization.CultureInfo.CurrentCulture.DateTimeFormat.ShortDatePattern + Environment.NewLine);
                    File.AppendAllText(meldeFile, "  ShortTimeFormat: " + System.Globalization.CultureInfo.CurrentCulture.DateTimeFormat.ShortTimePattern + Environment.NewLine);
                }
            }
            catch { }
        }

        /// <summary>
        /// Ensure path ends with backslash
        /// </summary>
        private static string ForceBackSlash(string s)
        {
            if (string.IsNullOrEmpty(s))
                return s;
            
            if (s.EndsWith("\\", StringComparison.Ordinal))
                return s;
            
            return s + "\\";
        }

        /// <summary>
        /// Run service as console application for debugging
        /// </summary>
        public void RunAsConsole()
        {
            Console.WriteLine("Running INCLService as console application...");
            Console.WriteLine("Press Ctrl+C to stop.");
            
            OnStart(Environment.GetCommandLineArgs());
            
            // Keep running until Ctrl+C
            var cts = new CancellationTokenSource();
            Console.CancelKeyPress += (sender, e) =>
            {
                e.Cancel = true;
                cts.Cancel();
                OnStop();
            };
            
            try
            {
                Task.Delay(-1, cts.Token).Wait();
            }
            catch (TaskCanceledException) { }
        }
    }
}
