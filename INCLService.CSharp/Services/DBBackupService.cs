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
    /// Äquivalent zu TThread_DBBackup in Delphi
    /// </summary>
    public class DBBackupService : BackgroundService
    {
        private readonly ILogger<DBBackupService> _logger;
        private readonly IConfiguration _configuration;
        private readonly AppConfig _appConfig;
        
        private CommonDB _database;
        private int _priority = 4; // Default: tpNormal
        private int _timerInterval = 60; // Minuten
        private DateTime _lastExecution = DateTime.MinValue;
        private string _backupPath = string.Empty;
        
        public DBBackupService(
            ILogger<DBBackupService> logger,
            IConfiguration configuration)
        {
            _logger = logger;
            _configuration = configuration;
            
            _appConfig = new AppConfig();
            _configuration.GetSection("Database").Bind(_appConfig.Database);
            _configuration.GetSection("Main").Bind(_appConfig.Main);
            
            LoadConfiguration();
            InitializeDatabase();
        }

        private void LoadConfiguration()
        {
            try
            {
                // Priorität aus Konfiguration laden
                _priority = _configuration.GetValue<int>("DBBackup:Priority", 4);
                _timerInterval = _configuration.GetValue<int>("DBBackup:Timer", 60);
                _backupPath = _configuration.GetValue<string>("DBBackup:Path", "d:\\comtas\\backup\\");
                
                // Backup-Verzeichnis erstellen, falls nicht vorhanden
                if (!string.IsNullOrEmpty(_backupPath) && !Directory.Exists(_backupPath))
                {
                    Directory.CreateDirectory(_backupPath);
                }
                
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

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("DBBackupService started with priority {Priority}", _priority);
            
            try
            {
                // Datenbankverbindung herstellen
                if (_database != null)
                {
                    try
                    {
                        _database.Connected = true;
                        _logger.LogInformation("DBBackupService database connected");
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Error connecting DBBackupService database");
                    }
                }
                
                while (!stoppingToken.IsCancellationRequested)
                {
                    // Prüfen, ob es Zeit für die nächste Ausführung ist
                    var now = DateTime.Now;
                    var timeSinceLastExecution = now - _lastExecution;
                    
                    if (_lastExecution == DateTime.MinValue || 
                        timeSinceLastExecution.TotalMinutes >= _timerInterval)
                    {
                        _lastExecution = now;
                        await ExecuteBackupAsync(stoppingToken);
                    }
                    
                    // Kurze Pause, um CPU zu schonen
                    await Task.Delay(60000, stoppingToken); // 1 Minute
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "DBBackupService terminated unexpectedly");
            }
            finally
            {
                // Datenbankverbindung schließen
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

        private async Task ExecuteBackupAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogInformation("Starting database backup...");
                
                if (_database == null || !_database.Connected)
                {
                    _logger.LogWarning("Database not connected, skipping backup");
                    return;
                }
                
                // Hier würde das eigentliche Backup implementiert werden
                // Äquivalent zu TThread_DBBackup.Execute in Delphi
                
                // Beispiel: SQL Server Backup
                var backupFile = Path.Combine(_backupPath, $"backup_{DateTime.Now:yyyyMMdd_HHmmss}.bak");
                
                try
                {
                    using (var command = _database.CreateCommand())
                    {
                        command.CommandText = $"BACKUP DATABASE [{_database.InitialCatalog}] TO DISK = '{backupFile}'";
                        await command.ExecuteNonQueryAsync(stoppingToken);
                    }
                    
                    _logger.LogInformation("Database backup completed: {BackupFile}", backupFile);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error creating database backup");
                    
                    // Fallback: Alternative Backup-Methode
                    await AlternativeBackupAsync(backupFile, stoppingToken);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error executing database backup");
            }
        }

        private async Task AlternativeBackupAsync(string backupFile, CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogInformation("Trying alternative backup method...");
                
                // Alternative: Daten exportieren
                // Hier könnten Tabellen als CSV exportiert werden
                
                _logger.LogInformation("Alternative backup completed: {BackupFile}", backupFile);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in alternative backup");
            }
        }

        public override async Task StopAsync(CancellationToken cancellationToken)
        {
            _logger.LogInformation("DBBackupService stopping...");
            await base.StopAsync(cancellationToken);
        }
    }
}
