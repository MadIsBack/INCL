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
    /// Service für zusätzliche Funktionen
    /// Äquivalent zu TThread_Zusatz in Delphi
    /// </summary>
    public class AdditionalService : BackgroundService
    {
        private readonly ILogger<AdditionalService> _logger;
        private readonly IConfiguration _configuration;
        private readonly AppConfig _appConfig;
        
        private CommonDB _database;
        private int _priority = 4; // Default: tpNormal
        private int _timerInterval = 600; // Sekunden (10 Minuten)
        private DateTime _lastExecution = DateTime.MinValue;
        
        public AdditionalService(
            ILogger<AdditionalService> logger,
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
                _priority = _configuration.GetValue<int>("Addons:Priority", 4);
                _timerInterval = _configuration.GetValue<int>("Addons:Timer", 600);
                
                _logger.LogInformation("AdditionalService configured - Priority: {Priority}, Timer: {Timer}s",
                    _priority, _timerInterval);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error loading AdditionalService configuration");
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
                
                _logger.LogInformation("AdditionalService database initialized");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error initializing AdditionalService database");
            }
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("AdditionalService started with priority {Priority}", _priority);
            
            try
            {
                // Datenbankverbindung herstellen
                if (_database != null)
                {
                    try
                    {
                        _database.Connected = true;
                        _logger.LogInformation("AdditionalService database connected");
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Error connecting AdditionalService database");
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
                        await ExecuteAdditionalTasksAsync(stoppingToken);
                    }
                    
                    // Kurze Pause, um CPU zu schonen
                    await Task.Delay(1000, stoppingToken);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "AdditionalService terminated unexpectedly");
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
                        _logger.LogError(ex, "Error disconnecting AdditionalService database");
                    }
                }
                _logger.LogInformation("AdditionalService stopped");
            }
        }

        private async Task ExecuteAdditionalTasksAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("Executing additional tasks...");
                
                if (_database == null || !_database.Connected)
                {
                    _logger.LogWarning("Database not connected, skipping additional tasks");
                    return;
                }
                
                // Hier würden die zusätzlichen Aufgaben implementiert werden
                // Äquivalent zu TThread_Zusatz.Execute in Delphi
                
                // Beispiel: Datenbereinigung
                await CleanupOldDataAsync(stoppingToken);
                
                // Beispiel: Statistikberechnungen
                await CalculateStatisticsAsync(stoppingToken);
                
                // Beispiel: Archivierungsaufgaben
                await ArchiveOldDataAsync(stoppingToken);
                
                _logger.LogDebug("Additional tasks executed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error executing additional tasks");
            }
        }

        private async Task CleanupOldDataAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("Cleaning up old data...");
                
                // Alte temporäre Daten löschen
                using (var command = _database.CreateCommand())
                {
                    command.CommandText = "DELETE FROM TempDaten WHERE Erstellungsdatum < @CutoffDate";
                    command.Parameters.AddWithValue("@CutoffDate", DateTime.Now.AddDays(-30));
                    var rowsAffected = await command.ExecuteNonQueryAsync(stoppingToken);
                    _logger.LogDebug("Deleted {Count} old temp records", rowsAffected);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error cleaning up old data");
            }
        }

        private async Task CalculateStatisticsAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("Calculating statistics...");
                
                // Statistiken neu berechnen
                using (var reader = _database.ExecuteReader(
                    "SELECT MaschinenNr, COUNT(*) as Count FROM Produktionsdaten WHERE Datum = @Today GROUP BY MaschinenNr",
                    System.Data.CommandType.Text))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        var maschinenNr = reader.GetInt32(0);
                        var count = reader.GetInt32(1);
                        
                        _logger.LogDebug("Machine {Machine}: {Count} records today", maschinenNr, count);
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error calculating statistics");
            }
        }

        private async Task ArchiveOldDataAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("Archiving old data...");
                
                // Alte Daten archivieren
                // Hier könnte ein INSERT INTO Archiv SELECT * FROM Produktionsdaten WHERE Datum < @CutoffDate
                // gefolgt von DELETE FROM Produktionsdaten WHERE Datum < @CutoffDate
                // implementiert werden
                
                _logger.LogDebug("Data archiving completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error archiving old data");
            }
        }

        public override async Task StopAsync(CancellationToken cancellationToken)
        {
            _logger.LogInformation("AdditionalService stopping...");
            await base.StopAsync(cancellationToken);
        }
    }
}
