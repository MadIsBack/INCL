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
    /// Service für Signal-Logging
    /// Äquivalent zu TThread_Signallog in Delphi
    /// </summary>
    public class SignalLogService : BackgroundService
    {
        private readonly ILogger<SignalLogService> _logger;
        private readonly IConfiguration _configuration;
        private readonly AppConfig _appConfig;
        
        private CommonDB _database;
        private int _priority = 3; // Default: tpLower
        private int _timerInterval = 30; // Sekunden
        private DateTime _lastExecution = DateTime.MinValue;
        
        public SignalLogService(
            ILogger<SignalLogService> logger,
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
                
                _logger.LogInformation("SignalLogService database initialized");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error initializing SignalLogService database");
            }
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("SignalLogService started with priority {Priority}", _priority);
            
            try
            {
                // Datenbankverbindung herstellen
                if (_database != null)
                {
                    try
                    {
                        _database.Connected = true;
                        _logger.LogInformation("SignalLogService database connected");
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Error connecting SignalLogService database");
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
                // Datenbankverbindung schließen
                if (_database != null && _database.Connected)
                {
                    try
                    {
                        _database.Connected = false;
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Error disconnecting SignalLogService database");
                    }
                }
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
                
                // Signale aus der Datenbank lesen und loggen
                using (var reader = _database.ExecuteReader(
                    "SELECT SignalId, SignalName, Wert, Zeitstempel FROM Signale WHERE Gelesen = 0 ORDER BY Zeitstempel"))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        var signalId = reader.GetInt32(0);
                        var signalName = reader.GetString(1);
                        var wert = reader.GetInt32(2);
                        var zeitstempel = reader.GetDateTime(3);
                        
                        _logger.LogInformation("Signal {Id} ({Name}): Wert={Wert} at {Zeitstempel}",
                            signalId, signalName, wert, zeitstempel);
                        
                        // Signal als gelesen markieren
                        using (var updateCmd = _database.CreateCommand())
                        {
                            updateCmd.CommandText = "UPDATE Signale SET Gelesen = 1 WHERE SignalId = @SignalId";
                            updateCmd.Parameters.AddWithValue("@SignalId", signalId);
                            await updateCmd.ExecuteNonQueryAsync(stoppingToken);
                        }
                    }
                }
                
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
