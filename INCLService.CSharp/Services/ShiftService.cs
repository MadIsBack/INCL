using INCLService.CSharp.Models;
using INCLUDIS.Utils.CommonDB;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using System;
using System.Threading;
using System.Threading.Tasks;

namespace INCLService.CSharp.Services
{
    /// <summary>
    /// Service für Schichtwechsel-Logik
    /// Äquivalent zu TThread_Schicht in Delphi
    /// </summary>
    public class ShiftService : BackgroundService
    {
        private readonly ILogger<ShiftService> _logger;
        private readonly IConfiguration _configuration;
        private readonly AppConfig _appConfig;
        
        private CommonDB _database;
        private int _priority = 3; // Default: tpLower
        private int _timerInterval = 60; // Sekunden
        private DateTime _lastExecution = DateTime.MinValue;
        
        // Schicht-spezifische Variablen
        public int AlteSchicht { get; set; } = 0;
        public bool SchichtBerechnung { get; set; } = false;
        public bool BerechnungAktiv { get; set; } = false;
        public bool RecalculateMode { get; set; } = false;
        
        public ShiftService(
            ILogger<ShiftService> logger,
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
                _priority = _configuration.GetValue<int>("Shift:Priority", 3);
                _timerInterval = _configuration.GetValue<int>("Shift:Timer", 60);
                
                _logger.LogInformation("ShiftService configured - Priority: {Priority}, Timer: {Timer}s",
                    _priority, _timerInterval);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error loading ShiftService configuration");
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
                
                _logger.LogInformation("ShiftService database initialized");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error initializing ShiftService database");
            }
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("ShiftService started with priority {Priority}", _priority);
            
            try
            {
                // Datenbankverbindung herstellen
                if (_database != null)
                {
                    try
                    {
                        _database.Connected = true;
                        _logger.LogInformation("ShiftService database connected");
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Error connecting ShiftService database");
                    }
                }
                
                while (!stoppingToken.IsCancellationRequested)
                {
                    // Prüfen, ob es Zeit für die nächste Ausführung ist
                    var now = DateTime.Now;
                    var timeSinceLastExecution = now - _lastExecution;
                    
                    if (_lastExecution == DateTime.MinValue || 
                        timeSinceLastExecution.TotalSeconds >= _timerInterval)
                    {
                        _lastExecution = now;
                        await ExecuteShiftLogicAsync(stoppingToken);
                    }
                    
                    // Kurze Pause, um CPU zu schonen
                    await Task.Delay(1000, stoppingToken);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "ShiftService terminated unexpectedly");
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
                        _logger.LogError(ex, "Error disconnecting ShiftService database");
                    }
                }
                _logger.LogInformation("ShiftService stopped");
            }
        }

        private async Task ExecuteShiftLogicAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("Executing shift logic...");
                
                if (_database == null || !_database.Connected)
                {
                    _logger.LogWarning("Database not connected, skipping shift logic");
                    return;
                }
                
                // Hier würde die Schichtwechsel-Logik implementiert werden
                // Äquivalent zu TThread_Schicht.Execute in Delphi
                
                // Beispiel: Prüfen, ob Schichtwechsel nötig ist
                if (await CheckSchichtwechselAsync(stoppingToken))
                {
                    _logger.LogInformation("Schichtwechsel erkannt, starte Berechnungen...");
                    await StartSchichtWechselAsync(AlteSchicht, stoppingToken);
                }
                
                // Weitere Schicht-Berechnungen
                if (SchichtBerechnung)
                {
                    await BerechneSchichtDatenAsync(stoppingToken);
                }
                
                _logger.LogDebug("Shift logic executed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error executing shift logic");
            }
        }

        private async Task<bool> CheckSchichtwechselAsync(CancellationToken stoppingToken)
        {
            // Hier würde geprüft werden, ob ein Schichtwechsel nötig ist
            // Äquivalent zu Schichtwechsel-Funktion in Delphi
            try
            {
                using (var reader = _database.ExecuteReader(
                    "SELECT TOP 1 * FROM Schichtwechsel WHERE Berechnet = 0 ORDER BY Datum"))
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
                _logger.LogError(ex, "Error checking Schichtwechsel");
                return false;
            }
        }

        private async Task StartSchichtWechselAsync(int alteSchicht, CancellationToken stoppingToken)
        {
            // Hier würde der Schichtwechsel gestartet werden
            // Äquivalent zu StartSchichtWechsel in Delphi
            try
            {
                BerechnungAktiv = true;
                AlteSchicht = alteSchicht;
                
                // Schichtwechsel-Logik implementieren
                _logger.LogInformation("Schichtwechsel von Schicht {AlteSchicht} gestartet", alteSchicht);
                
                // Beispiel: TPM-Daten für neue Schicht berechnen
                await BerechneTPMSchichtAsync(stoppingToken);
                
                BerechnungAktiv = false;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in StartSchichtWechsel");
                BerechnungAktiv = false;
            }
        }

        private async Task BerechneTPMSchichtAsync(CancellationToken stoppingToken)
        {
            // Hier würden die TPM-Daten für die Schicht berechnet werden
            // Äquivalent zu TPM_Schicht_Pruefen, Berechne_Stillstaende_Schicht, etc.
            try
            {
                _logger.LogDebug("Berechne TPM Schicht Daten...");
                
                // Beispiel: Stillstandszeiten berechnen
                using (var reader = _database.ExecuteReader(
                    "SELECT MaschinenNr, StillstandNr, StartZeit, EndeZeit FROM Stillstandslog WHERE Schicht = 1"))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        // Stillstandszeiten verarbeiten
                        var maschinenNr = reader.GetInt32(0);
                        var stillstandNr = reader.GetInt32(1);
                        var startZeit = reader.GetDateTime(2);
                        var endeZeit = reader.GetDateTime(3);
                        
                        _logger.LogDebug("Stillstand Maschine {Maschine}, Nr {Nr}: {Start} - {Ende}",
                            maschinenNr, stillstandNr, startZeit, endeZeit);
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error berechnend TPM Schicht");
            }
        }

        private async Task BerechneSchichtDatenAsync(CancellationToken stoppingToken)
        {
            // Hier würden die Schichtdaten berechnet werden
            // Äquivalent zu Berechne_A_Daten, TPM_Korrektur, etc.
            try
            {
                _logger.LogDebug("Berechne Schicht Daten...");
                
                // Beispiel: Produktionsdaten der Schicht berechnen
                // using (var reader = _database.ExecuteReader("SELECT ... FROM Produktionsdaten"))
                // {
                //     ...
                // }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error berechnend Schicht Daten");
            }
        }

        public override async Task StopAsync(CancellationToken cancellationToken)
        {
            _logger.LogInformation("ShiftService stopping...");
            await base.StopAsync(cancellationToken);
        }
    }
}
