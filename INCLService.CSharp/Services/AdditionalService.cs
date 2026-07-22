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
        private readonly CommonDB _database;
        
        private int _priority = 4; // Default: tpNormal
        private int _timerInterval = 600; // Sekunden (10 Minuten)
        private DateTime _lastExecution = DateTime.MinValue;
        
        public AdditionalService(
            ILogger<AdditionalService> logger,
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

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("AdditionalService started with priority {Priority}", _priority);
            
            try
            {
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
                
                // Beispiel: Datenbereinigung, Statistikberechnungen, etc.
                // using (var reader = _database.ExecuteReader("SELECT * FROM Aufgaben WHERE Erledigt = 0"))
                // {
                //     while (await reader.ReadAsync(stoppingToken))
                //     {
                //         // Aufgabe verarbeiten
                //     }
                // }
                
                _logger.LogDebug("Additional tasks executed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error executing additional tasks");
            }
        }

        public override async Task StopAsync(CancellationToken cancellationToken)
        {
            _logger.LogInformation("AdditionalService stopping...");
            await base.StopAsync(cancellationToken);
        }
    }
}
