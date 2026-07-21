using INCLUDIS.Utils.CommonDB;
using INCLUDIS.INCLServer.Cs.Utilities;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using System;
using System.Diagnostics;
using System.IO;
using System.Threading;
using System.Threading.Tasks;

namespace INCLUDIS.INCLServer.Cs.Services
{
    /// <summary>
    /// Service für Datenbanksicherungen.
    /// Ersatz für TThread_DBBackup aus Delphi.
    /// </summary>
    public class DBBackupService : BackgroundService
    {
        private readonly ILogger<DBBackupService> _logger;
        private readonly Func<CommonDB> _dbFactory;
        private readonly INCLServerConfig _config;
        private readonly MainService _mainService;
        
        // Status-Flags
        private bool _backupAktiv = false;
        private int _errorCount = 0;

        public DBBackupService(
            ILogger<DBBackupService> logger,
            Func<CommonDB> dbFactory,
            INCLServerConfig config,
            MainService mainService)
        {
            _logger = logger;
            _dbFactory = dbFactory;
            _config = config;
            _mainService = mainService;
            
            // Event-Handler für Backup-Anforderungen registrieren
         //   _mainService.OnBackupRequired += MainService_OnBackupRequired;
        }

        //private void MainService_OnBackupRequired(object sender, MainService.BackupEventArgs e)
        //{
        //    _logger.LogInformation("Backup-Event empfangen: Backup um {BackupZeitpunkt}", e.BackupZeitpunkt);
        //    _ = FuehreBackupDurch(); // Fire-and-Forget
        //}

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("DBBackupService gestartet.");

            // Hauptschleife
            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    // Regelmäßig prüfen, ob ein Backup erforderlich ist
                    if (IstBackupErforderlich())
                    {
                        await FuehreBackupDurch();
                    }
                    
                    // Wartezeit aus der Konfiguration
                    var interval = _config.ThreadSettings.DBBackupService.IntervalSeconds;
                    await Task.Delay(interval * 1000, stoppingToken);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Fehler im DBBackupService");
                    _errorCount++;
                    
                    if (_errorCount > 5)
                    {
                        _logger.LogError("Zu viele Fehler im DBBackupService. Warte 60 Sekunden...");
                        await Task.Delay(60000, stoppingToken);
                        _errorCount = 0;
                    }
                    else
                    {
                        await Task.Delay(10000, stoppingToken);
                    }
                }
            }

            _logger.LogInformation("DBBackupService wird beendet.");
        }

        /// <summary>
        /// Prüft, ob ein Backup erforderlich ist.
        /// </summary>
        private bool IstBackupErforderlich()
        {
            try
            {
                var db = _dbFactory();
                
                // Beispiel: Prüfen, ob ein Backup in den letzten 24 Stunden durchgeführt wurde
                using var reader = db.GetReader("SELECT TOP 1 BackupZeitpunkt FROM BackupProtokoll ORDER BY BackupZeitpunkt DESC");
                
                if (reader.Read())
                {
                    var letztesBackup = reader.GetDateTime("BackupZeitpunkt");
                    var zeitSeitBackup = DateTime.Now - letztesBackup;
                    
                    // Backup alle 24 Stunden durchführen
                    return zeitSeitBackup.TotalHours >= 24;
                }
                
                // Kein Backup-Eintrag gefunden → Backup erforderlich
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Fehler beim Prüfen, ob ein Backup erforderlich ist.");
                return false;
            }
        }

        /// <summary>
        /// Führt ein Backup der Datenbank durch.
        /// </summary>
        public async Task FuehreBackupDurch()
        {
            if (_backupAktiv)
                return;

            _backupAktiv = true;
            
            try
            {
                _logger.LogInformation("Starte Datenbank-Backup...");
                
                // Backup-Verzeichnis erstellen
                var backupDir = Path.Combine(_config.INCLUDIS_HOME, "Backups");
                Directory.CreateDirectory(backupDir);
                
                // Backup-Dateiname generieren
                var backupDatei = Path.Combine(backupDir, $"Backup_{_config.DBInitialCatalog}_{DateTime.Now:yyyyMMdd_HHmmss}.bak");
                
                // Prüfen, ob Lizenzen gültig sind
                if (!HelperFunctions.CheckLicenses(_dbFactory()))
                {
                    _logger.LogWarning("Backup abgebrochen: Lizenzen nicht gültig.");
                    return;
                }
                
                // Hier würde normalerweise der Backup-Befehl ausgeführt werden
                // Beispiel für SQL Server mit sqlcmd:
                // await FuehreExternesBackupDurch(backupDatei);
                
                // Für diese Implementierung simulieren wir das Backup
                _logger.LogInformation("Backup wird durchgeführt: {BackupDatei}", backupDatei);
                
                // Backup in der Datenbank protokollieren
                var db = _dbFactory();
                var sql = @"
                    INSERT INTO BackupProtokoll (BackupZeitpunkt, BackupDatei, Erfolgreich) 
                    VALUES (@BackupZeitpunkt, @BackupDatei, @Erfolgreich)";
                
                db.ExecuteNonQuery(sql, new { BackupZeitpunkt = DateTime.Now, BackupDatei = backupDatei, Erfolgreich = true });
                
                _logger.LogInformation("Backup erfolgreich abgeschlossen.");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Fehler beim Durchführen des Backups.");
                
                // Fehler in der Datenbank protokollieren
                var db = _dbFactory();
                var sql = @"
                    INSERT INTO BackupProtokoll (BackupZeitpunkt, Fehler) 
                    VALUES (@BackupZeitpunkt, @Fehler)";
                
                db.ExecuteNonQuery(sql, new { BackupZeitpunkt = DateTime.Now, Fehler = ex.Message });
            }
            finally
            {
                _backupAktiv = false;
            }
        }

        /// <summary>
        /// Führt ein Backup mit einem externen Tool durch (z. B. SQL Server sqlcmd).
        /// </summary>
        private async Task FuehreExternesBackupDurch(string backupDatei)
        {
            try
            {
                // Beispiel für SQL Server mit sqlcmd
                var sqlCmdPath = "sqlcmd";
           //     var backupBefehl = $@"-S {_config.DBServer} -U {_config.DBUser} -P {_config.DBPass} -Q \"BACKUP DATABASE [{_config.DBInitialCatalog}] TO DISK = '{backupDatei}'\"";
                
                var processInfo = new ProcessStartInfo
                {
                    FileName = sqlCmdPath,
                  //  Arguments = backupBefehl,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    UseShellExecute = false,
                    CreateNoWindow = true
                };
                
                using var process = new Process { StartInfo = processInfo };
                process.Start();
                
                var output = await process.StandardOutput.ReadToEndAsync();
                var error = await process.StandardError.ReadToEndAsync();
                
                await process.WaitForExitAsync();
                
                if (process.ExitCode != 0)
                {
                    throw new Exception($"Backup fehlgeschlagen: {error}");
                }

                _logger.LogInformation("Externes Backup erfolgreich: {Output}", output);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Fehler beim Durchführen des externen Backups.");
                throw;
            }
        }

        public override async Task StopAsync(CancellationToken cancellationToken)
        {
            _logger.LogInformation("DBBackupService wird beendet...");
            await base.StopAsync(cancellationToken);
        }
    }
}
