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
        private readonly CommonDB _database;
        
        private int _priority = 3; // Default: tpLower
        private int _timerInterval = 60; // Sekunden
        private DateTime _lastExecution = DateTime.MinValue;
        
        public ShiftService(
            ILogger<ShiftService> logger,
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

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("ShiftService started with priority {Priority}", _priority);
            
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
                _logger.LogInformation("ShiftService stopped");
            }
        }

        private async Task ExecuteShiftLogicAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("Executing shift logic...");
                
                // Hier würde die Schichtwechsel-Logik implementiert werden
                // Äquivalent zu TThread_Schicht.Execute in Delphi
                
                if (_database == null || !_database.Connected)
                {
                    _logger.LogWarning("Database not connected, skipping shift logic");
                    return;
                }
                
                // Beispiel: Prüfen, ob Schichtwechsel nötig ist
                // using (var reader = _database.ExecuteReader("SELECT ... FROM Schichtwechsel"))
                // {
                //     while (await reader.ReadAsync(stoppingToken))
                //     {
                //         // Schichtwechsel-Logik
                //     }
                // }
                
                _logger.LogDebug("Shift logic executed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error executing shift logic");
            }
        }

        public override async Task StopAsync(CancellationToken cancellationToken)
        {
            _logger.LogInformation("ShiftService stopping...");
            await base.StopAsync(cancellationToken);
        }
    }
}
