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
    /// Service für Signal-Logging
    /// Äquivalent zu TThread_Signallog in Delphi
    /// </summary>
    public class SignalLogService : BackgroundService
    {
        private readonly ILogger<SignalLogService> _logger;
        private readonly IConfiguration _configuration;
        private readonly CommonDB _database;
        
        private int _priority = 3; // Default: tpLower
        private int _timerInterval = 30; // Sekunden
        private DateTime _lastExecution = DateTime.MinValue;
        
        public SignalLogService(
            ILogger<SignalLogService> logger,
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
                _priority = _configuration.GetValue<int>("Signallog:Priority", 3);
                _timerInterval = _configuration.GetValue<int>("Signallog:Timer", 30);
                
                _logger.LogInformation("SignalLogService configured - Priority: {Priority}, Timer: {Timer}s",
                    _priority, _timerInterval);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error loading SignalLogService configuration");
            }
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("SignalLogService started with priority {Priority}", _priority);
            
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
                        await ExecuteSignalLoggingAsync(stoppingToken);
                    }
                    
                    // Kurze Pause, um CPU zu schonen
                    await Task.Delay(1000, stoppingToken);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "SignalLogService terminated unexpectedly");
            }
            finally
            {
                _logger.LogInformation("SignalLogService stopped");
            }
        }

        private async Task ExecuteSignalLoggingAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("Executing signal logging...");
                
                if (_database == null || !_database.Connected)
                {
                    _logger.LogWarning("Database not connected, skipping signal logging");
                    return;
                }
                
                // Hier würde die Signal-Logging-Logik implementiert werden
                // Äquivalent zu TThread_Signallog.Execute in Delphi
                
                // Beispiel: Signale aus der Datenbank lesen und loggen
                // using (var reader = _database.ExecuteReader("SELECT * FROM Signale WHERE Logged = 0"))
                // {
                //     while (await reader.ReadAsync(stoppingToken))
                //     {
                //         // Signal verarbeiten und loggen
                //     }
                // }
                
                _logger.LogDebug("Signal logging executed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error executing signal logging");
            }
        }

        public override async Task StopAsync(CancellationToken cancellationToken)
        {
            _logger.LogInformation("SignalLogService stopping...");
            await base.StopAsync(cancellationToken);
        }
    }
}
