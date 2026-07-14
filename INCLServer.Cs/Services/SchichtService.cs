using INCLUDIS.Utils.CommonDB;
using INCLUDIS.INCLServer.Cs.Database;
using INCLUDIS.INCLServer.Cs.Utilities;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using System;
using System.Threading;
using System.Threading.Tasks;

namespace INCLUDIS.INCLServer.Cs.Services
{
    /// <summary>
    /// Service für Schichtberechnungen.
    /// Ersatz für TThread_Schicht aus Delphi.
    /// </summary>
    public class SchichtService : BackgroundService
    {
        private readonly ILogger<SchichtService> _logger;
        private readonly TPM _tpm;
        private readonly Func<CommonDB> _dbFactory;
        private readonly INCLServerConfig _config;
        private readonly MainService _mainService;
        
        // Status-Flags
        private bool _berechnungAktiv = false;
        private bool _nachBerechnung = false;
        private int _alteSchicht = 0;
        private int _errorCount = 0;

        public SchichtService(
            ILogger<SchichtService> logger,
            TPM tpm,
            Func<CommonDB> dbFactory,
            INCLServerConfig config,
            MainService mainService)
        {
            _logger = logger;
            _tpm = tpm;
            _dbFactory = dbFactory;
            _config = config;
            _mainService = mainService;
            
            // Event-Handler für Schichtwechsel registrieren
            _mainService.OnSchichtwechsel += MainService_OnSchichtwechsel;
        }

        private void MainService_OnSchichtwechsel(object sender, MainService.SchichtEventArgs e)
        {
            _logger.LogInformation("Schichtwechsel-Event empfangen: Schicht {SchichtNummer} (ID: {SchichtId})", e.SchichtNummer, e.SchichtId);
            _alteSchicht = e.SchichtNummer;
            _nachBerechnung = true;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("SchichtService gestartet.");

            // Initialisierung
            await InitialisiereSchichtDaten(stoppingToken);

            // Hauptschleife
            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    if (_nachBerechnung)
                    {
                        await BerechneSchichtDaten(stoppingToken);
                        _nachBerechnung = false;
                    }
                    else
                    {
                        // Regelmäßige Überprüfung
                        await PruefeSchichtwechsel(stoppingToken);
                        
                        // TPM-Daten aktualisieren
                        await AktualisiereTPMDaten(stoppingToken);
                    }

                    // Wartezeit aus der Konfiguration
                    var interval = _config.ThreadSettings.SchichtService.IntervalSeconds;
                    await Task.Delay(interval * 1000, stoppingToken);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Fehler im SchichtService");
                    _errorCount++;
                    
                    if (_errorCount > 5)
                    {
                        _logger.LogError("Zu viele Fehler im SchichtService. Warte 60 Sekunden...");
                        await Task.Delay(60000, stoppingToken);
                        _errorCount = 0;
                    }
                    else
                    {
                        await Task.Delay(10000, stoppingToken);
                    }
                }
            }

            _logger.LogInformation("SchichtService wird beendet.");
        }

        /// <summary>
        /// Initialisiert die Schichtdaten.
        /// </summary>
        private async Task InitialisiereSchichtDaten(CancellationToken stoppingToken)
        {
            try
            {
                using var db = _dbFactory();
                _logger.LogInformation("Initialisiere Schichtdaten...");
                
                // Aktuelle Schicht abrufen
                using var reader = db.GetReader("SELECT TOP 1 SchichtNummer FROM Schichtwechsel ORDER BY SchichtId DESC");
                if (reader.Read())
                {
                    _alteSchicht = reader.GetInt32("SchichtNummer");
                    _logger.LogInformation("Aktuelle Schicht: {AlteSchicht}", _alteSchicht);
                }
                
                // Schichtkonstante setzen
                TPMHelper.SetSchichtKonstante(db, _alteSchicht);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Fehler bei der Initialisierung der Schichtdaten.");
            }
        }

        /// <summary>
        /// Berechnet die Schichtdaten.
        /// </summary>
        private async Task BerechneSchichtDaten(CancellationToken stoppingToken)
        {
            if (_berechnungAktiv)
                return;

            _berechnungAktiv = true;
            
            try
            {
                using var db = _dbFactory();
                _logger.LogInformation("Berechne Schichtdaten für Schicht {AlteSchicht}...", _alteSchicht);
                
                // Maschinenleistung für die Schicht berechnen
                await BerechneMaschinenleistung(db, stoppingToken);
                
                // Schichtwechsel berechnen
                await BerechneSchichtwechsel(db, stoppingToken);
                
                // Stillstände berechnen
                await BerechneStillstaende(db, stoppingToken);
                
                // A-Felder für die Schicht berechnen
                TPMHelper.CalculateAFelderSchicht(db, _alteSchicht, DateTime.Today.AddDays(-1));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Fehler bei der Berechnung der Schichtdaten.");
            }
            finally
            {
                _berechnungAktiv = false;
            }
        }

        /// <summary>
        /// Berechnet die Maschinenleistung für die Schicht.
        /// </summary>
        private async Task BerechneMaschinenleistung(CommonDB db, CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogInformation("Berechne Maschinenleistung für Schicht {AlteSchicht}...", _alteSchicht);
                
                // Beispiel: Maschinenleistung für die Schicht berechnen
                using var reader = db.GetReader(@"
                    SELECT MaschNr, Stueck, Laufzeit 
                    FROM Maschinenleistung 
                    WHERE SchichtId = (
                        SELECT TOP 1 SchichtId 
                        FROM Schichtwechsel 
                        WHERE SchichtNummer = @SchichtNummer 
                        ORDER BY SchichtId DESC
                    )
                ", new { SchichtNummer = _alteSchicht });
                
                while (reader.Read())
                {
                    var maschNr = reader.GetInt32("MaschNr");
                    var stueck = reader.GetInt32("Stueck");
                    var laufzeit = reader.GetInt32("Laufzeit");
                    
                    _logger.LogDebug("Maschine {MaschNr}: {Stueck} Stück, {Laufzeit} Minuten", maschNr, stueck, laufzeit);
                    
                    // TPM-Statistikfunktionen aufrufen
                    _tpm.BerechneSchicht(_alteSchicht);
                    
                    // TPMHelper für detaillierte Berechnungen
                    TPMHelper.CalculateTPM(db, maschNr, DateTime.Today);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Fehler beim Berechnen der Maschinenleistung.");
            }
        }

        /// <summary>
        /// Berechnet den Schichtwechsel.
        /// </summary>
        private async Task BerechneSchichtwechsel(CommonDB db, CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogInformation("Berechne Schichtwechsel...");
                
                // Beispiel: Schichtwechsel in der Datenbank markieren
                var sql = @"
                    UPDATE Schichtwechsel 
                    SET Berechnet = 1 
                    WHERE SchichtNummer = @SchichtNummer";
                
                db.ExecuteNonQuery(sql, new { SchichtNummer = _alteSchicht });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Fehler beim Berechnen des Schichtwechsels.");
            }
        }

        /// <summary>
        /// Berechnet die Stillstände für die Schicht.
        /// </summary>
        private async Task BerechneStillstaende(CommonDB db, CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogInformation("Berechne Stillstände für Schicht {AlteSchicht}...", _alteSchicht);
                
                // Beispiel: Stillstände abrufen und berechnen
                using var reader = db.GetReader(@"
                    SELECT StillstandNr, MaschNr, StartZeit, EndeZeit 
                    FROM Stillstandsprotokoll 
                    WHERE SchichtNummer = @SchichtNummer 
                    AND Berechnet = 0
                ", new { SchichtNummer = _alteSchicht });
                
                while (reader.Read())
                {
                    var stillstandNr = reader.GetInt32("StillstandNr");
                    var maschNr = reader.GetInt32("MaschNr");
                    var startZeit = reader.GetDateTime("StartZeit");
                    var endeZeit = reader.GetDateTime("EndeZeit");
                    
                    // Dauer berechnen
                    var dauer = (int)(endeZeit - startZeit).TotalMinutes;
                    
                    _logger.LogDebug("Stillstand {StillstandNr} auf Maschine {MaschNr}: {Dauer} Minuten", stillstandNr, maschNr, dauer);
                    
                    // TPM-Statistikfunktionen aufrufen
                    _tpm.BerechneStillstandszeiten(maschNr, startZeit, endeZeit);
                    
                    // TPMHelper für Stillstandsprüfung
                    TPMHelper.CheckTPMStillstand(db, maschNr);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Fehler beim Berechnen der Stillstände.");
            }
        }

        /// <summary>
        /// Aktualisiert die TPM-Daten für alle Maschinen.
        /// </summary>
        private async Task AktualisiereTPMDaten(CancellationToken stoppingToken)
        {
            try
            {
                using var db = _dbFactory();
                _logger.LogInformation("Aktualisiere TPM-Daten...");
                
                // Für jede Maschine die TPM-Werte aktualisieren
                foreach (var maschine in ArbeitHelper.MaschineList)
                {
                    if (stoppingToken.IsCancellationRequested)
                        break;
                    
                    TPMHelper.CalculateTPM(db, maschine.MaschNr, DateTime.Today);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Fehler beim Aktualisieren der TPM-Daten.");
            }
        }

        /// <summary>
        /// Prüft, ob ein Schichtwechsel stattgefunden hat.
        /// </summary>
        private async Task PruefeSchichtwechsel(CancellationToken stoppingToken)
        {
            try
            {
                using var db = _dbFactory();
                
                // Beispiel: Prüfen, ob ein neuer Schichtwechsel vorliegt
                using var reader = db.GetReader(@"
                    SELECT TOP 1 SchichtNummer 
                    FROM Schichtwechsel 
                    WHERE Berechnet = 0 
                    ORDER BY SchichtId DESC
                ");
                
                if (reader.Read())
                {
                    var neueSchicht = reader.GetInt32("SchichtNummer");
                    
                    if (neueSchicht != _alteSchicht)
                    {
                        _logger.LogInformation("Neuer Schichtwechsel erkannt: {NeueSchicht} (vorher: {AlteSchicht})", neueSchicht, _alteSchicht);
                        _alteSchicht = neueSchicht;
                        _nachBerechnung = true;
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Fehler beim Prüfen des Schichtwechsels.");
            }
        }

        public override async Task StopAsync(CancellationToken cancellationToken)
        {
            _logger.LogInformation("SchichtService wird beendet...");
            await base.StopAsync(cancellationToken);
        }
    }
}
