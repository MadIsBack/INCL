using INCLService.CSharp.Utilities;
using INCLService.CSharp.Models;
using INCLUDIS.Utils.CommonDB;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using System;
using System.IO;
using System.Threading;
using System.Threading.Tasks;

namespace INCLService.CSharp.Services
{
    /// <summary>
    /// Service für Datenbank-Backups
    /// Äquivalent zu TThread_DBBackup in Th_DBBackup.pas
    /// Schritt 24: Vervollständigung mit Backup-Logik
    /// </summary>
    public class DBBackupService : BackgroundService
    {
        private readonly ILogger<DBBackupService> _logger;
        private readonly IConfiguration _configuration;
        private readonly AppConfig _appConfig;
        private readonly ServiceEventSystem _serviceEvents;
        
        private CommonDB _database;
        private int _priority = 4; // Default: tpNormal
        private int _timerInterval = 60; // Minuten
        private DateTime _lastExecution = DateTime.MinValue;
        private string _backupPath = string.Empty;
        
        // Backup-Einstellungen
        public int BackupRetentionDays { get; set; } = 30; // 30 Tage behalten
        public bool BackupEnabled { get; set; } = true;
        public string BackupFilePrefix { get; set; } = "INCL_Backup_";
        public string BackupFileExtension { get; set; } = ".bak";
        
        public DBBackupService(
            ILogger<DBBackupService> logger,
            IConfiguration configuration,
            ServiceEventSystem serviceEvents = null)
        {
            _logger = logger;
            _configuration = configuration;
            _appConfig = new AppConfig();
            _configuration.GetSection("Database").Bind(_appConfig.Database);
            _configuration.GetSection("Main").Bind(_appConfig.Main);
            _serviceEvents = serviceEvents ?? ServiceEvents.Instance;
            
            LoadConfiguration();
            InitializeDatabase();
        }

        /// <summary>
        /// Setzt das Event für DBBackupService
        /// </summary>
        public void SetEvent()
        {
            _serviceEvents.SetEvent(ServiceEventSystem.EVENT_DBBACKUP);
        }
        
        /// <summary>
        /// Pulses das Event für DBBackupService
        /// </summary>
        public void PulseEvent()
        {
            _serviceEvents.PulseEvent(ServiceEventSystem.EVENT_DBBACKUP);
        }

        private void LoadConfiguration()
        {
            try
            {
                // Priorität aus Konfiguration laden
                _priority = _configuration.GetValue<int>("DBBackup:Priority", 4);
                _timerInterval = _configuration.GetValue<int>("DBBackup:Timer", 60);
                _backupPath = _configuration.GetValue<string>("DBBackup:Path", "d:\\comtas\\backup\\");
                
                BackupRetentionDays = _configuration.GetValue<int>("DBBackup:RetentionDays", 30);
                BackupEnabled = _configuration.GetValue<bool>("DBBackup:Enabled", true);
                BackupFilePrefix = _configuration.GetValue<string>("DBBackup:FilePrefix", "INCL_Backup_");
                BackupFileExtension = _configuration.GetValue<string>("DBBackup:FileExtension", ".bak");
                
                _logger.LogInformation("DBBackupService configured - Priority: {Priority}, Timer: {Timer}min, Path: {Path}",
                    _priority, _timerInterval, _backupPath);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error loading DBBackupService configuration");
            }
        }

        private void InitializeDatabase()
        {
            try
            {
                _database = new CommonDB
                {
                    UserName = _appConfig.Database.DB_User,
                    Password = _appConfig.Database.DB_Pass,
                    Server = _appConfig.Database.DB_Server,
                    InitialCatalog = _appConfig.Database.InitialCatalog,
                    SqlProvider = _appConfig.Database.Provider
                };
                
                _logger.LogInformation("DBBackupService database initialized");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error initializing DBBackupService database");
            }
        }

        /// <summary>
        /// Erstellt ein Datenbank-Backup
        /// Äquivalent zu CreateBackup in Th_DBBackup.pas
        /// </summary>
        private async Task<bool> CreateBackupAsync(CancellationToken stoppingToken)
        {
            try
            {
                if (!BackupEnabled)
                {
                    _logger.LogDebug("CreateBackup: Backup ist deaktiviert");
                    return false;
                }
                
                _logger.LogInformation("CreateBackup: Backup wird erstellt");
                
                // Backup-Verzeichnis erstellen, falls nicht vorhanden
                if (!Directory.Exists(_backupPath))
                {
                    Directory.CreateDirectory(_backupPath);
                    _logger.LogDebug("CreateBackup: Backup-Verzeichnis erstellt: {Path}", _backupPath);
                }
                
                // Backup-Dateiname generieren
                string backupFileName = $"{BackupFilePrefix}{DateTime.Now:yyyyMMdd_HHmmss}{BackupFileExtension}";
                string backupFilePath = Path.Combine(_backupPath, backupFileName);
                
                // Hier würde das eigentliche Backup durchgeführt werden
                // Da wir keine direkte Datenbankverbindung für Backups haben,
                // würde hier die Logik aus Delphi portiert werden
                
                // Für SQL Server: BACKUP DATABASE
                if (_appConfig.Database.Provider.Contains("SqlClient") || 
                    _appConfig.Database.Provider.Contains("SQL") ||
                    string.IsNullOrEmpty(_appConfig.Database.Provider))
                {
                    string sql = $@"BACKUP DATABASE [{_appConfig.Database.InitialCatalog}] 
                        TO DISK = '{backupFilePath}' 
                        WITH COMPRESSION, STATS = 10";
                    
                    await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                    _logger.LogInformation("CreateBackup: SQL Server Backup erstellt: {FilePath}", backupFilePath);
                }
                else
                {
                    // Für andere Datenbanken: Datei kopieren
                    _logger.LogWarning("CreateBackup: Backup für Provider {Provider} nicht implementiert", 
                        _appConfig.Database.Provider);
                    return false;
                }
                
                // Alte Backups bereinigen
                await CleanupOldBackupsAsync(stoppingToken);
                
                _logger.LogInformation("CreateBackup: Backup erfolgreich erstellt");
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in CreateBackup");
                return false;
            }
        }

        /// <summary>
        /// Bereinigt alte Backups
        /// </summary>
        private async Task CleanupOldBackupsAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("CleanupOldBackups: Alte Backups werden bereinigt");
                
                if (!Directory.Exists(_backupPath))
                {
                    _logger.LogDebug("CleanupOldBackups: Backup-Verzeichnis existiert nicht");
                    return;
                }
                
                DateTime cutoffDate = DateTime.Now.AddDays(-BackupRetentionDays);
                
                foreach (string filePath in Directory.GetFiles(_backupPath, $"{BackupFilePrefix}*{BackupFileExtension}"))
                {
                    try
                    {
                        FileInfo fileInfo = new FileInfo(filePath);
                        if (fileInfo.CreationTime < cutoffDate)
                        {
                            fileInfo.Delete();
                            _logger.LogDebug("CleanupOldBackups: Altes Backup gelöscht: {FilePath}", filePath);
                        }
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Error deleting old backup: {FilePath}", filePath);
                    }
                }
                
                _logger.LogDebug("CleanupOldBackups: Bereinigung abgeschlossen");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in CleanupOldBackups");
            }
        }

        /// <summary>
        /// Prüft, ob ein Backup benötigt wird
        /// </summary>
        private bool IsBackupNeeded()
        {
            try
            {
                // Backup alle _timerInterval Minuten
                if ((DateTime.Now - _lastExecution).TotalMinutes >= _timerInterval)
                {
                    return true;
                }
                
                return false;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in IsBackupNeeded");
                return false;
            }
        }

        /// <summary>
        /// Prüft Datenbankverbindung
        /// </summary>
        private async Task<bool> CheckDatabaseConnectionAsync(CancellationToken stoppingToken)
        {
            try
            {
                if (_database == null || !_database.Connected)
                {
                    _logger.LogWarning("CheckDatabaseConnection: Datenbank nicht verbunden");
                    return false;
                }
                
                // Test-Abfrage
                string sql = "SELECT 1";
                using (var reader = _database.ExecuteReader(sql))
                {
                    if (await reader.ReadAsync(stoppingToken))
                    {
                        return true;
                    }
                }
                
                return false;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in CheckDatabaseConnection");
                return false;
            }
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("DBBackupService started with priority {Priority}", _priority);
            
            try
            {
                if (_database != null)
                {
                    _database.Connected = true;
                    _logger.LogInformation("DBBackupService database connected");
                }
                
                while (!stoppingToken.IsCancellationRequested)
                {
                    // Auf Event warten (wie WaitForSingleObject in Delphi)
                    await _serviceEvents.WaitForEventAsync(ServiceEventSystem.EVENT_DBBACKUP, stoppingToken);
                    
                    if (stoppingToken.IsCancellationRequested)
                        break;
                    
                    if (_database == null || !_database.Connected)
                    {
                        _logger.LogWarning("Database not connected, skipping backup");
                        continue;
                    }
                    
                    if (!await CheckDatabaseConnectionAsync(stoppingToken))
                    {
                        continue;
                    }
                    
                    // Backup ausführen
                    if (IsBackupNeeded())
                    {
                        bool success = await CreateBackupAsync(stoppingToken);
                        if (success)
                        {
                            _lastExecution = DateTime.Now;
                        }
                    }
                    else
                    {
                        _logger.LogDebug("DBBackupService: Backup nicht benötigt (letzte Ausführung: {LastExecution})", _lastExecution);
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "DBBackupService terminated unexpectedly");
            }
            finally
            {
                if (_database != null && _database.Connected)
                {
                    try
                    {
                        _database.Connected = false;
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Error disconnecting DBBackupService database");
                    }
                }
                _logger.LogInformation("DBBackupService stopped");
            }
        }

        public override async Task StopAsync(CancellationToken cancellationToken)
        {
            _logger.LogInformation("DBBackupService stopping...");
            await base.StopAsync(cancellationToken);
        }
    }
}
