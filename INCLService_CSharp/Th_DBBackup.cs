// <summary>
// Th_DBBackup.cs - C# translation of Th_DBBackup.pas
// Database backup thread
// </summary>

using System;
using System.Diagnostics;
using System.IO;
using System.Threading;

namespace INCLService_CSharp
{
    /// <summary>
    /// Database backup thread class
    /// </summary>
    public class TThread_DBBackup : IDisposable
    {
        private CO_Database CDatabase;
        private CO_Query qSuch = new CO_Query();
        private CO_Query qUpdate = new CO_Query();
        
        private Thread thread;
        private bool running = false;
        private bool suspended = false;
        
        private string backupPath = string.Empty;
        private string backupApp = string.Empty;
        private int backupIntervalHours = 24;
        private DateTime lastBackup = DateTime.MinValue;

        /// <summary>
        /// Constructor
        /// </summary>
        public TThread_DBBackup(bool aSuspended)
        {
            try
            {
                suspended = aSuspended;
                
                // Initialize database connection
                CDatabase = new CO_Database();
                CDatabase.UserName = MainAzure.DBUser;
                CDatabase.Password = MainAzure.DBPass;
                CDatabase.Server = MainAzure.DBServer;
                CDatabase.InitialCatalog = MainAzure.DBInitialCatalog;

                qSuch.Database = CDatabase;
                qUpdate.Database = CDatabase;
                
                // Load configuration
                LoadConfiguration();
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in TThread_DBBackup constructor: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Load configuration from database
        /// </summary>
        private void LoadConfiguration()
        {
            try
            {
                // Get backup path from configuration
                backupPath = CO_Setup2.TCO_Setup.GetParamStr(qSuch, "BackupPath", false);
                if (string.IsNullOrEmpty(backupPath))
                {
                    backupPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Backup");
                }
                
                // Ensure backup directory exists
                if (!Directory.Exists(backupPath))
                {
                    Directory.CreateDirectory(backupPath);
                }
                
                // Get backup application
                backupApp = CO_Setup2.TCO_Setup.GetParamStr(qSuch, "BackupApplication", false);
                if (string.IsNullOrEmpty(backupApp))
                {
                    // Default to SQL Server backup utility
                    backupApp = "sqlcmd.exe";
                }
                
                // Get backup interval
                backupIntervalHours = CO_Setup2.TCO_Setup.GetParamInt(qSuch, "BackupIntervalHours", false);
                if (backupIntervalHours <= 0)
                {
                    backupIntervalHours = 24; // Default to 24 hours
                }
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in LoadConfiguration: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Check if backup should proceed
        /// </summary>
        private bool proceedBackup()
        {
            try
            {
                // Check if it's time for backup
                if ((DateTime.Now - lastBackup).TotalHours >= backupIntervalHours)
                {
                    return true;
                }
                return false;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in proceedBackup: " + ex.Message, 0);
                return false;
            }
        }

        /// <summary>
        /// Get backup application path
        /// </summary>
        private string getBackupAppl()
        {
            try
            {
                if (!string.IsNullOrEmpty(backupApp))
                {
                    // Check if it's a full path
                    if (Path.IsPathRooted(backupApp))
                    {
                        if (File.Exists(backupApp))
                            return backupApp;
                    }
                    else
                    {
                        // Try to find in system path
                        string[] paths = Environment.GetEnvironmentVariable("PATH").Split(';');
                        foreach (string path in paths)
                        {
                            string fullPath = Path.Combine(path, backupApp);
                            if (File.Exists(fullPath))
                                return fullPath;
                        }
                    }
                }
                return string.Empty;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in getBackupAppl: " + ex.Message, 0);
                return string.Empty;
            }
        }

        /// <summary>
        /// Get next run time based on cron-like schedule
        /// </summary>
        private DateTime getCronNextRun(string aMinute, string aStunde, string aMonatstag, string aMonat, string aWochentag)
        {
            try
            {
                // Simplified implementation - just return next hour
                return DateTime.Now.AddHours(1);
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in getCronNextRun: " + ex.Message, 0);
                return DateTime.Now.AddHours(1);
            }
        }

        /// <summary>
        /// Perform database backup
        /// </summary>
        private void PerformBackup()
        {
            try
            {
                string backupFile = Path.Combine(backupPath, "INCL_Backup_" + DateTime.Now.ToString("yyyyMMdd_HHmmss") + ".bak");
                
                if (CDatabase.DatabaseType == DatabaseType.dbTypMSSQL)
                {
                    // SQL Server backup
                    string connectionString = CDatabase.ConnectionString;
                    string databaseName = CDatabase.InitialCatalog;
                    
                    // Use sqlcmd to backup database
                    string arguments = "-S " + CDatabase.Server + " -U " + CDatabase.UserName + 
                        " -P " + CDatabase.Password + " -Q \"BACKUP DATABASE [" + databaseName + 
                        "] TO DISK = '" + backupFile + "'\"";
                    
                    ProcessStartInfo psi = new ProcessStartInfo("sqlcmd.exe", arguments);
                    psi.CreateNoWindow = true;
                    psi.UseShellExecute = false;
                    psi.RedirectStandardOutput = true;
                    psi.RedirectStandardError = true;
                    
                    using (Process process = Process.Start(psi))
                    {
                        process.WaitForExit();
                        string output = process.StandardOutput.ReadToEnd();
                        string error = process.StandardError.ReadToEnd();
                        
                        if (process.ExitCode == 0)
                        {
                            MainDLL.SchreibeMeldung("Database backup successful: " + backupFile, 2);
                            lastBackup = DateTime.Now;
                        }
                        else
                        {
                            MainDLL.SchreibeMeldung("Database backup failed: " + error, 0);
                        }
                    }
                }
                else // Oracle
                {
                    // Oracle backup would use expdp or similar
                    MainDLL.SchreibeMeldung("Oracle backup not implemented yet", 2);
                }
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in PerformBackup: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Clean up old backups
        /// </summary>
        private void CleanupOldBackups()
        {
            try
            {
                // Keep only the last 7 backups
                DirectoryInfo dirInfo = new DirectoryInfo(backupPath);
                FileInfo[] files = dirInfo.GetFiles("INCL_Backup_*.bak");
                
                if (files.Length > 7)
                {
                    // Sort by creation time
                    Array.Sort(files, (x, y) => x.CreationTime.CompareTo(y.CreationTime));
                    
                    // Delete oldest files
                    for (int i = 0; i < files.Length - 7; i++)
                    {
                        try
                        {
                            files[i].Delete();
                        }
                        catch (Exception ex)
                        {
                            MainDLL.SchreibeMeldung("Error deleting old backup: " + ex.Message, 0);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in CleanupOldBackups: " + ex.Message, 0);
            }
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
                    if (!suspended && proceedBackup())
                    {
                        string backupApp = getBackupAppl();
                        if (!string.IsNullOrEmpty(backupApp))
                        {
                            PerformBackup();
                            CleanupOldBackups();
                        }
                    }
                    
                    // Sleep until next scheduled run
                    Thread.Sleep(3600000); // Sleep for 1 hour
                }
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in Th_DBBackup Execute: " + ex.Message, 0);
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
                MainDLL.SchreibeMeldung("Error in Th_DBBackup Start: " + ex.Message, 0);
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
                    thread.Join(5000); // Wait up to 5 seconds
                }
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in Th_DBBackup Stop: " + ex.Message, 0);
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
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in Th_DBBackup Dispose: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Destructor
        /// </summary>
        ~TThread_DBBackup()
        {
            Dispose();
        }
    }

    /// <summary>
    /// Database backup globals
    /// </summary>
    public static class DBBackupGlobals
    {
        public static TThread_DBBackup Thread_DBBackup { get; set; } = null;
        public static IntPtr Event_DBBackup { get; set; } = IntPtr.Zero;
    }
}
