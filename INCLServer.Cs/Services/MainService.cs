using INCLUDIS.Utils.CommonDB;
using INCLUDIS.INCLServer.Cs.Database;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using System;
using System.Threading;
using System.Threading.Tasks;

namespace INCLUDIS.INCLServer.Cs.Services
{
    /// <summary>
    /// Hauptservice, der die anderen Services koordiniert.
    /// Ersatz für TS7Main aus Delphi.
    /// </summary>
    public class MainService : BackgroundService
    {
        private readonly ILogger<MainService> _logger;
        private readonly TPM _tpm;
        private readonly Func<CommonDB> _dbFactory;
        private readonly INCLServerConfig _config;
        
        // Events für die Kommunikation mit anderen Services
        public event EventHandler<SchichtEventArgs> OnSchichtwechsel;
        public event EventHandler<BackupEventArgs> OnBackupRequired;
        
        // Status-Flags
        private bool _datenLesenAktiv = false;
        private bool _s7MainOK = true;
        private int _errorCount = 0;

        public MainService(
            ILogger<MainService> logger,
            TPM tpm,
            Func<CommonDB> dbFactory,
            INCLServerConfig config)
        {
            _logger = logger;
            _tpm = tpm;
            _dbFactory = dbFactory;
            _config = config;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("MainService gestartet. Initialisiere Datenbankverbindung...");

            // Warten, bis die Datenbankverbindung steht
            while (!await CheckDBVerbindung(stoppingToken) && !stoppingToken.IsCancellationRequested)
            {
                _logger.LogWarning("Datenbank nicht verfügbar. Warte 30 Sekunden...");
                await Task.Delay(30000, stoppingToken);
            }

            if (stoppingToken.IsCancellationRequested)
            {
                _logger.LogInformation("MainService wurde vor dem Start der Hauptschleife abgebrochen.");
                return;
            }

            _logger.LogInformation("Datenbankverbindung erfolgreich. Starte Hauptprogramm...");
            _s7MainOK = true;

            // Hauptschleife
            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    // Daten lesen (analog zu DatenLesen in Delphi)
                    await DatenLesen(stoppingToken);
                    
                    // Prüfen, ob ein Fehler aufgetreten ist
                    if (!_s7MainOK)
                    {
                        _logger.LogError("Fehler während der Ausführung. Neustart...");
                        await Neustart(stoppingToken);
                    }

                    // Kurze Pause, um CPU-Last zu reduzieren
                    await Task.Delay(1000, stoppingToken);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Fehler in der Hauptschleife des MainService");
                    _errorCount++;
                    
                    if (_errorCount > 10)
                    {
                        _logger.LogError("Zu viele Fehler. Beende Service...");
                        break;
                    }
                    
                    await Task.Delay(5000, stoppingToken);
                }
            }

            _logger.LogInformation("MainService wird beendet.");
        }

        /// <summary>
        /// Prüft die Datenbankverbindung.
        /// </summary>
        private async Task<bool> CheckDBVerbindung(CancellationToken stoppingToken)
        {
            try
            {
                using var db = _dbFactory();
                _logger.LogInformation("Prüfe Datenbankverbindung...");
                
                // Einfache Abfrage, um die Verbindung zu testen
                using var reader = db.GetReader("SELECT 1");
                return reader.Read();
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Datenbankverbindung fehlgeschlagen.");
                return false;
            }
        }

        /// <summary>
        /// Liest Daten aus der Datenbank (analog zu DatenLesen in Delphi).
        /// </summary>
        private async Task DatenLesen(CancellationToken stoppingToken)
        {
            if (_datenLesenAktiv)
                return;

            _datenLesenAktiv = true;
            
            try
            {
                using var db = _dbFactory();
                _logger.LogInformation("Lese Daten aus der Datenbank...");
                
                // Beispiel: Maschinenleistung abrufen
                using var reader = db.GetReader("SELECT MaschNr, Stueck FROM Maschinenleistung WHERE Berechnet = 0");
                
                while (reader.Read())
                {
                    var maschNr = reader.GetInt32("MaschNr");
                    var stueck = reader.GetInt32("Stueck");
                    
                    _logger.LogDebug("Maschine {MaschNr}: {Stueck} Stück", maschNr, stueck);
                }
                
                // Schichtwechsel prüfen
                await PruefeSchichtwechsel(db, stoppingToken);
                
                // Backup prüfen
                await PruefeBackup(db, stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Fehler beim Lesen der Daten.");
                _s7MainOK = false;
            }
            finally
            {
                _datenLesenAktiv = false;
            }
        }

        /// <summary>
        /// Prüft, ob ein Schichtwechsel stattgefunden hat.
        /// </summary>
        private async Task PruefeSchichtwechsel(CommonDB db, CancellationToken stoppingToken)
        {
            try
            {
                // Beispiel: Aktuelle Schicht abrufen
                using var reader = db.GetReader("SELECT TOP 1 SchichtId, SchichtNummer FROM Schichtwechsel WHERE Berechnet = 0 ORDER BY SchichtId DESC");
                
                if (reader.Read())
                {
                    var schichtId = reader.GetInt32("SchichtId");
                    var schichtNummer = reader.GetInt32("SchichtNummer");
                    
                    _logger.LogInformation("Schichtwechsel erkannt: Schicht {SchichtNummer} (ID: {SchichtId})", schichtNummer, schichtId);
                    
                    // Event auslösen
                    OnSchichtwechsel?.Invoke(this, new SchichtEventArgs(schichtId, schichtNummer));
                    
                    // Schicht berechnen
                    _tpm.BerechneSchicht(schichtId);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Fehler beim Prüfen des Schichtwechsels.");
            }
        }

        /// <summary>
        /// Prüft, ob ein Backup erforderlich ist.
        /// </summary>
        private async Task PruefeBackup(CommonDB db, CancellationToken stoppingToken)
        {
            try
            {
                // Beispiel: Prüfen, ob ein Backup in den letzten 24 Stunden durchgeführt wurde
                using var reader = db.GetReader("SELECT TOP 1 BackupZeitpunkt FROM BackupProtokoll ORDER BY BackupZeitpunkt DESC");
                
                if (reader.Read())
                {
                    var letztesBackup = reader.GetDateTime("BackupZeitpunkt");
                    var zeitSeitBackup = DateTime.Now - letztesBackup;
                    
                    // Backup alle 24 Stunden durchführen
                    if (zeitSeitBackup.TotalHours >= 24)
                    {
                        _logger.LogInformation("Backup erforderlich (letztes Backup: {LetztesBackup})", letztesBackup);
                        OnBackupRequired?.Invoke(this, new BackupEventArgs(DateTime.Now));
                    }
                }
                else
                {
                    // Kein Backup-Eintrag gefunden → Backup erforderlich
                    _logger.LogInformation("Kein Backup-Eintrag gefunden. Backup erforderlich.");
                    OnBackupRequired?.Invoke(this, new BackupEventArgs(DateTime.Now));
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Fehler beim Prüfen des Backups.");
            }
        }

        /// <summary>
        /// Führt einen Neustart der Hauptlogik durch (analog zu S7Main.Free und Neuaufbau in Delphi).
        /// </summary>
        private async Task Neustart(CancellationToken stoppingToken)
        {
            _logger.LogInformation("Neustart der Hauptlogik...");
            
            // Kurze Wartezeit
            await Task.Delay(5000, stoppingToken);
            
            _s7MainOK = true;
            _errorCount = 0;
        }

        /// <summary>
        /// Wird aufgerufen, wenn der Service pausiert wird.
        /// </summary>
        public override async Task StopAsync(CancellationToken cancellationToken)
        {
            _logger.LogInformation("MainService wird pausiert...");
            await base.StopAsync(cancellationToken);
        }
    }

    /// <summary>
    /// EventArgs für Schichtwechsel-Events.
    /// </summary>
    public class SchichtEventArgs : EventArgs
    {
        public int SchichtId { get; }
        public int SchichtNummer { get; }

        public SchichtEventArgs(int schichtId, int schichtNummer)
        {
            SchichtId = schichtId;
            SchichtNummer = schichtNummer;
        }
    }

    /// <summary>
    /// EventArgs für Backup-Events.
    /// </summary>
    public class BackupEventArgs : EventArgs
    {
        public DateTime BackupZeitpunkt { get; }

        public BackupEventArgs(DateTime backupZeitpunkt)
        {
            BackupZeitpunkt = backupZeitpunkt;
        }
    }
}
