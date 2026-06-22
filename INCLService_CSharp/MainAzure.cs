// <summary>
// MainAzure.cs - C# translation of MainAzure.pas
// Azure service implementation for INCL service
// </summary>

using System;
using System.IO;
using System.Threading;
using System.Runtime.InteropServices;

namespace INCLService_CSharp
{
    /// <summary>
    /// INCL Azure Service class
    /// </summary>
    public class TINCLServAzure
    {
        private const int MAX_FILE_SIZE_MB = 4;
        private const string TRACE_DIR = "LOG";
        private const string SERVICE_DISPLAY_NAME = "INCLServer";

        private bool lastDBConnectStatus = true;
        private bool terminated = false;
        private bool isinstop = false;
        private string name = string.Empty;
        private string shutdownfile = string.Empty;
        private bool notfirststart = false;

        public static string INCLUDIS_HOME = string.Empty;
        public static string DBUser = "includis";
        public static string DBServer = "db";
        public static string DBPass = "comtas";
        public static string DBInitialCatalog = "includis";
        
        private static readonly object CSLog = new object();
        public static bool S7MainOK = true;
        public static object S7Main = null; // Would be TS7Main in Delphi

        /// <summary>
        /// Service execute method
        /// </summary>
        public void ServiceExecute()
        {
            try
            {
                // Initialize
                lastDBConnectStatus = true;
                string compileSwitches = GetCompileSwitches();
                SchreibeMeldung("Compiled with switches : " + compileSwitches, 0);

                // Wait for database connection
                while (!DatenM.Instance.Database.Connected && !terminated)
                {
                    if (CheckDBVerbindung())
                    {
                        try
                        {
                            SchreibeMeldung("Connected.", 0);
                            DatenM.Instance.Database.Connected = false;
                            DatenM.Instance.Database.UserName = DBUser;
                            DatenM.Instance.Database.Password = DBPass;
                            DatenM.Instance.Database.Server = DBServer;
                            DatenM.Instance.Database.InitialCatalog = DBInitialCatalog;
                            DatenM.Instance.Database.Connected = true;
                        }
                        catch (Exception ex)
                        {
                            SchreibeMeldung("Error connecting: " + ex.Message, 0);
                        }
                    }

                    if (!DatenM.Instance.Database.Connected)
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
                            lastDBConnectStatus = true;
                    }

                    if (!DatenM.Instance.Database.Connected && !terminated)
                    {
                        SchreibeMeldung("Wait 30 sec.", 0);
                        Thread.Sleep(30000);
                    }
                }

                if (terminated)
                    return;

                S7MainOK = true;
                SchreibeMeldung("Database connection successfully... Start programm...", 0);
                
                try
                {
                    // S7Main would be created here
                    // S7Main = new TS7Main();
                }
                catch (Exception ex)
                {
                    SchreibeMeldung("Error Service.Create : " + ex.Message, 0);
                }

                // Main service loop
                while (!terminated)
                {
                    if (!S7MainOK)
                    {
                        // Error occurred, restart
                        try
                        {
                            // S7Main.Free();
                        }
                        catch (Exception) { }

                        SchreibeMeldung("New start program...", 0);
                        try
                        {
                            // S7Main = new TS7Main();
                        }
                        catch (Exception ex)
                        {
                            SchreibeMeldung("Error Service.Create : " + ex.Message, 0);
                        }
                        S7MainOK = true;
                    }
                    else
                    {
                        if (CheckShutdownFile())
                        {
                            terminated = true;
                        }
                        else
                        {
                            // Process messages
                            for (int i = 0; i <= 20; i++)
                            {
                                // Process Windows messages
                                // This would be handled by Windows message loop in Windows Service
                                Thread.Sleep(50);
                            }
                        }
                    }
                }
            }
            finally
            {
                // Cleanup
            }
        }

        /// <summary>
        /// Service destroy method
        /// </summary>
        public void ServiceDestroy()
        {
            SchreibeMeldung("Service Stop...", 0);
        }

        /// <summary>
        /// Service shutdown method
        /// </summary>
        public void ServiceShutdown()
        {
            SchreibeMeldung("Service Shutdown...", 0);
        }

        /// <summary>
        /// Run method
        /// </summary>
        public void Run()
        {
            if (!notfirststart)
            {
                notfirststart = true;
                SetDBUser();
            }

            while (true)
            {
                if (!CheckShutdownFile())
                {
                    isinstop = false;
                    SchreibeMeldung("Shutdownfile '" + shutdownfile + "' does not exists. Starting service...", 0);
                    terminated = false;
                    ServiceExecute();
                }
                else
                {
                    if (!isinstop)
                    {
                        SchreibeMeldung("Shutdownfile '" + shutdownfile + "' exists. Stopping service...", 0);
                        isinstop = true;
                    }
                    Thread.Sleep(1000);
                }
            }
        }

        /// <summary>
        /// Check shutdown file
        /// </summary>
        private bool CheckShutdownFile()
        {
            if (string.IsNullOrEmpty(shutdownfile))
            {
                shutdownfile = Environment.GetEnvironmentVariable("WEBJOBS_SHUTDOWN_FILE");
                SchreibeMeldung("Read shutdown file : " + shutdownfile, 0);
            }

            if (string.IsNullOrEmpty(shutdownfile))
                return false;
            
            return File.Exists(shutdownfile);
        }

        /// <summary>
        /// Set database user from configuration
        /// </summary>
        public void SetDBUser()
        {
            const string kDBUser = "DBUSER=";
            const string kDBPass = "DBPASS=";
            const string kDBServer = "DBSERVER=";

            try
            {
                DBUser = "INCLUDIS";
                DBPass = "comtas";
                DBServer = "includis.world";
                DBInitialCatalog = DBUser;

                string iniPath = Path.Combine(Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location), 
                    "INCL_" + DBUser + ".ini");

                // Read INI file (simplified - would use proper INI file reading)
                if (File.Exists(iniPath))
                {
                    // In a real implementation, we would read the INI file properly
                    // For now, we'll use environment variables or defaults
                }

                // Try to read from environment variables
                string envDBUser = Environment.GetEnvironmentVariable("DBUSER");
                string envDBPass = Environment.GetEnvironmentVariable("DBPASS");
                string envDBServer = Environment.GetEnvironmentVariable("DBSERVER");
                string envInitialCatalog = Environment.GetEnvironmentVariable("INITIALCATALOG");

                if (!string.IsNullOrEmpty(envDBUser))
                    DBUser = envDBUser;
                if (!string.IsNullOrEmpty(envDBPass))
                    DBPass = envDBPass;
                if (!string.IsNullOrEmpty(envDBServer))
                    DBServer = envDBServer;
                if (!string.IsNullOrEmpty(envInitialCatalog))
                    DBInitialCatalog = envInitialCatalog;

                INCLUDIS_HOME = Environment.GetEnvironmentVariable("INCLUDIS_HOME");
                if (string.IsNullOrEmpty(INCLUDIS_HOME))
                    INCLUDIS_HOME = "d:\\comtas\\";
            }
            catch (Exception ex)
            {
                SchreibeMeldung("Error in SetDBUser: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Get compile switches
        /// </summary>
        private string GetCompileSwitches()
        {
            // In C#, we can't easily detect compile-time switches like in Delphi
            // So we'll return a default string
            return "INCL_MSADO;";
        }

        /// <summary>
        /// Check database connection
        /// </summary>
        public static bool CheckDBVerbindung()
        {
            try
            {
                MainDLL.SchreibeMeldung("Check connect.", 0);
                
                CO_Database iData = new CO_Database();
                try
                {
                    iData.Connected = false;
                    iData.UserName = DBUser;
                    iData.Password = DBPass;
                    iData.Server = DBServer;
                    iData.InitialCatalog = DBInitialCatalog;
                    iData.Connected = true;
                }
                catch (Exception ex)
                {
                    MainDLL.SchreibeMeldung("Error in CheckDBVerbindung: " + ex.Message, 0);
                    return false;
                }

                bool result = iData.Connected;
                try
                {
                    iData.Connected = false;
                }
                catch (Exception) { }

                if (result)
                    MainDLL.SchreibeMeldung("Connect Ok.", 0);
                else
                    MainDLL.SchreibeMeldung("Connect failed.", 0);

                return result;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in CheckDBVerbindung: " + ex.Message, 0);
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
            if (S.EndsWith("\\"))
                return S;
            return S + "\\";
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

                if (!Directory.Exists(MeldeDir))
                {
                    try
                    {
                        Directory.CreateDirectory(MeldeDir);
                    }
                    catch (Exception)
                    {
                        return;
                    }
                }

                string MeldeFile = string.Empty;
                switch (Modus)
                {
                    case 0: MeldeFile = MeldeDir + "svc_" + DBUser.ToLower() + "_trace.log"; break;
                    case 1: MeldeFile = MeldeDir + "svc_" + DBUser.ToLower() + "_timer.log"; break;
                    case 2: MeldeFile = MeldeDir + "svc_" + DBUser.ToLower() + "_shift.log"; break;
                    case 3: MeldeFile = MeldeDir + "svc_" + DBUser.ToLower() + "_addons.log"; break;
                    case 4: MeldeFile = MeldeDir + "svc_" + DBUser.ToLower() + "_recalc.log"; break;
                    case 5: MeldeFile = MeldeDir + "svc_" + DBUser.ToLower() + "_memory.log"; break;
                    case 6: MeldeFile = MeldeDir + "svc_" + DBUser.ToLower() + "_down.log"; break;
                    case 7: MeldeFile = MeldeDir + "svc_" + DBUser.ToLower() + "_memdbg.log"; break;
                    default: MeldeFile = MeldeDir + "svc_" + DBUser.ToLower() + "_trace.log"; break;
                }

                lock (CSLog)
                {
                    string S = MainDLL.DateTimeToStr(MainDLL.N_o_w) + " : " + Meldung;

                    // Check if we need to add debug info for specific errors
                    if (Meldung.Contains("Gleitkommawert") || Meldung.Contains("invalid month") || 
                        Meldung.Contains("invalid number"))
                    {
                        S += Environment.NewLine + "  DecimalSeparator: " + CultureInfo.CurrentCulture.NumberFormat.NumberDecimalSeparator;
                        S += Environment.NewLine + "  ThousandSeparator: " + CultureInfo.CurrentCulture.NumberFormat.NumberGroupSeparator;
                        S += Environment.NewLine + "  ShortDateFormat: " + CultureInfo.CurrentCulture.DateTimeFormat.ShortDatePattern;
                        S += Environment.NewLine + "  ShortTimeFormat: " + CultureInfo.CurrentCulture.DateTimeFormat.ShortTimePattern;
                    }

                    // Write to file
                    File.AppendAllText(MeldeFile, S + Environment.NewLine);

                    // Check file size and truncate if needed
                    FileInfo fileInfo = new FileInfo(MeldeFile);
                    if (fileInfo.Exists && fileInfo.Length > (MAX_FILE_SIZE_MB * 1024 * 1024))
                    {
                        // Truncate file
                        File.WriteAllText(MeldeFile, string.Empty);
                    }
                }
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine("Error in SchreibeMeldung: " + ex.Message);
            }
        }
    }
}
