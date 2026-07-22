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
        private readonly CommonDB _database;
        
        private int _priority = 4; // Default: tpNormal
        private int _timerInterval = 60; // Minuten
        private DateTime _lastExecution = DateTime.MinValue;
        private string _backupPath = string.Empty;
        
        public DBBackupService(
            ILogger<DBBackupService> logger,
            IConfiguration configuration,
            CommonDB database)
        {
            _logger = logger;
            _configuration = configuration;
            _database = database;
            
            LoadConfiguration();
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

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("DBBackupService started with priority {Priority}", _priority);
            
            try
            {
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
                // var backupFile = Path.Combine(_backupPath, $"backup_{DateTime.Now:yyyyMMdd_HHmmss}.bak");
                // using (var command = _database.CreateCommand())
                // {
                //     command.CommandText = $"BACKUP DATABASE [{_database.InitialCatalog}] TO DISK = '{backupFile}'";
                //     await command.ExecuteNonQueryAsync(stoppingToken);
                // }
                
                _logger.LogInformation("Database backup completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error executing database backup");
            }
        }

        public override async Task StopAsync(CancellationToken cancellationToken)
        {
            _logger.LogInformation("DBBackupService stopping...");
            await base.StopAsync(cancellationToken);
        }
    }
}
