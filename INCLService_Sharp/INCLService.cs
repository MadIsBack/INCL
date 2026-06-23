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

        public static string INCLUDIS_HOME = string.Empty;
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
            this.ServiceName = SERVICE_DISPLAY_NAME + (DBUser != null ? DBUser.ToUpper() : "");
            this.DisplayName = SERVICE_DISPLAY_NAME + (DBUser != null ? DBUser.ToUpper() : "");
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
        /// Main service execution loop - 1:1 translation from Delphi
        /// </summary>
        private async Task ServiceExecute()
        {
            string s = string.Empty;
            
            try
            {
                // CSLog := TCriticalSection.Create;
                lastDBConnectStatus = true;
                s = string.Empty;

                // Check compile switches - in C# we use conditional compilation symbols
                #if INCL_ORA
                    s += "INCL_ORA;";
                #endif
                #if ODAC
                    s += "ODAC;";
                #endif
                #if INCL_MSADO
                    s += "INCL_MSADO;";
                #endif
                #if TIMEMEAS
                    s += "TIMEMEAS;";
                #endif

                WriteMessage("Compiled with switches: " + s, 0);

                // Wait for database connection
                while (!Daten.Instance.Database.Connected && !terminated)
                {
                    // ServiceThread.ProcessRequests(False); - Not directly translatable in .NET
                    
                    if (CheckDBVerbindung())
                    {
                        try
                        {
                            WriteMessage("Connected.", 0);
                            Daten.Instance.Database.Connected = false;
                            Daten.Instance.Database.UserName = DBUser;
                            Daten.Instance.Database.Password = DBPass;
                            Daten.Instance.Database.Server = DBServer;
                            #if INCLUDISDatabaseTyp == 1
                                Daten.Instance.Database.InitialCatalog = DBInitialCatalog;
                                Daten.Instance.Database.SqlProvider = DBProvider;
                            #endif
                            Daten.Instance.Database.Connected = true;
                        }
                        catch { }
                    }

                    if (!Daten.Instance.Database.Connected)
                    {
                        if (lastDBConnectStatus)
                        {
                            lastDBConnectStatus = false;
                            WriteMessage("Database not available.", 0);
                        }
                    }
                    else
                    {
                        if (!lastDBConnectStatus)
                            lastDBConnectStatus = true;
                    }
                    
                    if (!Daten.Instance.Database.Connected && !terminated)
                    {
                        WriteMessage("Wait 30 sec.", 0);
                        await Task.Delay(30000);
                    }
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
                    // ServiceThread.ProcessRequests(True); - Not directly translatable
                    
                    // Check if S7MainOK and test every second if there was an error
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
                    
                    await Task.Delay(1000);
                }
            }
            catch (Exception ex)
            {
                WriteMessage("Error in ServiceExecute: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Check database connection - 1:1 translation from Delphi
        /// </summary>
        private bool CheckDBVerbindung()
        {
            WriteMessage("Check connect.", 0);
            
            CommonDB iData = null;
            bool result = false;
            
            try
            {
                iData = new CommonDB();
                iData.Connected = false;
                iData.UserName = DBUser;
                iData.Password = DBPass;
                iData.Server = DBServer;
                
                #if INCLUDISDatabaseTyp == 1
                    iData.InitialCatalog = DBInitialCatalog;
                    iData.SqlProvider = DBProvider;
                    WriteMessage("Using " + DBUser + "@" + DBServer + " (" + DBInitialCatalog + ")" + " - Provider:" + iData.SqlProvider, 0);
                #else
                    WriteMessage("Using " + DBUser + "@" + DBServer, 0);
                #endif
                
                iData.Connected = true;
                result = iData.Connected;
                
                try
                {
                    iData.Connected = false;
                }
                catch { }
                
                if (result)
                    WriteMessage("Connect Ok.", 0);
                else
                    WriteMessage("Connect failed.", 0);
            }
            catch (Exception ex)
            {
                WriteMessage("Connect failed: " + ex.Message, 0);
                result = false;
            }
            finally
            {
                try
                {
                    iData?.Dispose();
                }
                catch { }
            }
            
            return result;
        }

        /// <summary>
        /// Set database user from command line parameters - 1:1 translation from Delphi
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
                for (int i = 0; i < args.Length; i++)
                {
                    string upperArg = args[i].ToUpper();
                    int pos;
                    
                    pos = upperArg.IndexOf(kDBUser.ToUpper());
                    if (pos > 0)
                        DBUser = args[i].Substring(pos + kDBUser.Length, Math.Min(100, args[i].Length - pos - kDBUser.Length));

                    pos = upperArg.IndexOf(kDBPass.ToUpper());
                    if (pos > 0)
                        DBPass = args[i].Substring(pos + kDBPass.Length, Math.Min(100, args[i].Length - pos - kDBPass.Length));

                    pos = upperArg.IndexOf(kDBServer.ToUpper());
                    if (pos > 0)
                        DBServer = args[i].Substring(pos + kDBServer.Length, Math.Min(100, args[i].Length - pos - kDBServer.Length));
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
            string inifn = Path.Combine(Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location), 
                "INCL_" + DBUser + ".ini");
            
            if (File.Exists(inifn))
            {
                // Read INI file - simplified version
                var iniLines = File.ReadAllLines(inifn);
                foreach (var line in iniLines)
                {
                    if (line.StartsWith("[Database]", StringComparison.OrdinalIgnoreCase))
                        continue;
                    
                    var parts = line.Split('=');
                    if (parts.Length == 2)
                    {
                        string key = parts[0].Trim();
                        string value = parts[1].Trim();
                        
                        if (key.Equals("DB_Server", StringComparison.OrdinalIgnoreCase))
                            DBServer = value;
                        else if (key.Equals("InitialCatalog", StringComparison.OrdinalIgnoreCase))
                            DBInitialCatalog = value;
                        else if (key.Equals("Provider", StringComparison.OrdinalIgnoreCase))
                            DBProvider = value;
                        else if (key.Equals("Home", StringComparison.OrdinalIgnoreCase))
                            INCLUDIS_HOME = value;
                    }
                }
                
                // Write back to INI file
                try
                {
                    File.WriteAllText(inifn, string.Join(Environment.NewLine, iniLines));
                }
                catch { }
            }
        }

        /// <summary>
        /// Write message to log file - 1:1 translation from Delphi
        /// </summary>
        public static void WriteMessage(string message, int mode)
        {
            try
            {
                if (string.IsNullOrEmpty(INCLUDIS_HOME))
                    return;

                INCLUDIS_HOME = ForceBackSlash(INCLUDIS_HOME);
                string meldeDir = ForceBackSlash(INCLUDIS_HOME + TRACE_DIR);

                if (!Directory.Exists(meldeDir))
                {
                    try
                    {
                        Directory.CreateDirectory(meldeDir);
                    }
                    catch
                    {
                        return;
                    }
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

                string s = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + " : " + message;

                // Check file size and write
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
                if (s.Contains("Gleitkommawert") || s.Contains("invalid month") || s.Contains("invalid number"))
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
        /// Ensure path ends with backslash - 1:1 translation from Delphi
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
