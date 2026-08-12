using INCLService.CSharp.Utilities;
using INCLService.CSharp.Models;
using INCLUDIS.Utils.CommonDB;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Threading;
using System.Threading.Tasks;

namespace INCLService.CSharp.Services
{
    /// <summary>
    /// Signal-Log-Eintragsklasse
    /// Äquivalent zu TSignalClass in Th_SignalLog.pas
    /// </summary>
    public class SignalClass
    {
        public int SignalNr { get; set; } = 0;
        public int Nr { get; set; } = 0;
        public int MaschNr { get; set; } = 0;
        public string Istwert { get; set; } = string.Empty;
        public string Oldwert { get; set; } = "0";
        public int Oldlognr { get; set; } = -1;
        
        /// <summary>
        /// Erstellt eine Kopie dieses Objekts
        /// </summary>
        public SignalClass CopyMe()
        {
            return new SignalClass
            {
                SignalNr = this.SignalNr,
                Nr = this.Nr,
                MaschNr = this.MaschNr,
                Istwert = this.Istwert,
                Oldwert = this.Oldwert,
                Oldlognr = this.Oldlognr
            };
        }
    }

    /// <summary>
    /// Service für Signal-Logging
    /// Äquivalent zu TThread_Signallog in Th_SignalLog.pas
    /// Schritt 24: Vervollständigung mit Signal-Überwachungslogik
    /// </summary>
    public class SignalLogService : BackgroundService
    {
        private readonly ILogger<SignalLogService> _logger;
        private readonly IConfiguration _configuration;
        private readonly AppConfig _appConfig;
        private readonly ServiceEventSystem _serviceEvents;
        
        private CommonDB _database;
        private int _priority = 3; // Default: tpLower
        private int _timerInterval = 30; // Sekunden
        private DateTime _lastExecution = DateTime.MinValue;
        
        // Signal-Liste
        private List<SignalClass> _entryList = new List<SignalClass>();
        
        // Signal-Log-Liste für offene Einträge
        private SignalLogEintragListe _openSignalLogEntries = new SignalLogEintragListe();
        
        // Letzte Signalwerte für Vergleich
        private Dictionary<int, string> _lastSignalValues = new Dictionary<int, string>();
        
        public SignalLogService(
            ILogger<SignalLogService> logger,
            IConfiguration configuration,
            ServiceEventSystem serviceEvents = null)
        {
            _logger = logger;
            _configuration = configuration;
            _appConfig = new AppConfig();
            _configuration.GetSection("Database").Bind(_appConfig.Database);
            _configuration.GetSection("Main").Bind(_appConfig.Main);
            _serviceEvents = serviceEvents ?? ServiceEvents.Instance;
            
            LoadConfiguration();
            InitializeDatabase();
        }

        /// <summary>
        /// Setzt das Event für SignalLogService
        /// </summary>
        public void SetEvent()
        {
            _serviceEvents.SetEvent(ServiceEventSystem.EVENT_SIGNALLLOG);
        }
        
        /// <summary>
        /// Pulses das Event für SignalLogService
        /// </summary>
        public void PulseEvent()
        {
            _serviceEvents.PulseEvent(ServiceEventSystem.EVENT_SIGNALLLOG);
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

        /// <summary>
        /// Initialisiert die Signal-Liste
        /// Äquivalent zu InitializeSignalList in Th_SignalLog.pas
        /// </summary>
        private async Task InitializeSignalListAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("InitializeSignalList: Signal-Liste wird initialisiert");
                
                _entryList.Clear();
                _lastSignalValues.Clear();
                
                // Alle aktiven Signale aus der Datenbank laden
                string sql = @"SELECT signal_maschine.Nr, signal_maschine.Istwert, signal_maschine.MaschNr, 
                    signal_maschine.SignalNr
                    FROM signal_maschine 
                    JOIN signale ON signale.SignalNr = signal_maschine.SignalNr
                    WHERE signale.Aktiv = 1";
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        var entry = new SignalClass
                        {
                            Nr = reader.GetInt32(0),
                            Istwert = reader.GetString(1),
                            MaschNr = reader.GetInt32(2),
                            SignalNr = reader.GetInt32(3)
                        };
                        
                        _entryList.Add(entry);
                        _lastSignalValues[entry.Nr] = entry.Istwert;
                    }
                }
                
                _logger.LogInformation("InitializeSignalList: {Count} Signale geladen", _entryList.Count);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in InitializeSignalList");
            }
        }

        /// <summary>
        /// Führt Signal-Logging aus
        /// Äquivalent zu ExecuteSignalLogging in Th_SignalLog.pas
        /// </summary>
        private async Task ExecuteSignalLoggingAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("ExecuteSignalLogging: Signal-Logging wird ausgeführt");
                
                // Signal-Liste initialisieren (falls noch nicht geschehen)
                if (_entryList.Count == 0)
                {
                    await InitializeSignalListAsync(stoppingToken);
                }
                
                // Für jedes Signal prüfen, ob sich der Wert geändert hat
                foreach (var entry in _entryList)
                {
                    await HandleSignalChangeAsync(entry, stoppingToken);
                }
                
                _logger.LogDebug("ExecuteSignalLogging: Signal-Logging abgeschlossen");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in ExecuteSignalLogging");
            }
        }

        /// <summary>
        /// Behandelt Signaländerungen
        /// Äquivalent zu HandleSignalChange in Th_SignalLog.pas
        /// </summary>
        private async Task HandleSignalChangeAsync(SignalClass entry, CancellationToken stoppingToken)
        {
            try
            {
                // Aktuellen Wert aus der Datenbank lesen
                string sql = $"SELECT Istwert FROM signal_maschine WHERE Nr = {entry.Nr}";
                string currentValue = string.Empty;
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    if (await reader.ReadAsync(stoppingToken))
                    {
                        currentValue = reader.GetString(0);
                    }
                }
                
                // Prüfen, ob sich der Wert geändert hat
                if (_lastSignalValues.TryGetValue(entry.Nr, out string lastValue))
                {
                    if (currentValue != lastValue)
                    {
                        _logger.LogDebug("HandleSignalChange: Signal {SignalNr} hat sich geändert: {OldValue} -> {NewValue}",
                            entry.SignalNr, lastValue, currentValue);
                        
                        // Signaländerung in Datenbank loggen
                        await LogSignalChangeAsync(entry, lastValue, currentValue, stoppingToken);
                        
                        // Letzten Wert aktualisieren
                        _lastSignalValues[entry.Nr] = currentValue;
                        entry.Oldwert = lastValue;
                        entry.Istwert = currentValue;
                    }
                }
                else
                {
                    // Erster Lauf: Wert speichern
                    _lastSignalValues[entry.Nr] = currentValue;
                    entry.Oldwert = currentValue;
                    entry.Istwert = currentValue;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in HandleSignalChange for Signal {SignalNr}", entry.SignalNr);
            }
        }

        /// <summary>
        /// Loggt Signaländerungen in die Datenbank
        /// Äquivalent zu LogSignalChange in Th_SignalLog.pas
        /// </summary>
        private async Task LogSignalChangeAsync(SignalClass entry, string oldValue, string newValue, CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("LogSignalChange: Signaländerung wird geloggt (SignalNr: {SignalNr}, MaschNr: {MaschNr})",
                    entry.SignalNr, entry.MaschNr);
                
                // Prüfen, ob ein offener Eintrag existiert
                int logNr = await GetOpenSignalLogNrAsync(entry.Nr, stoppingToken);
                
                if (logNr > 0)
                {
                    // Offenen Eintrag aktualisieren
                    string sql = $"UPDATE SIGNALLOG SET Ende = GETDATE(), Dauer = DATEDIFF(SECOND, Start, GETDATE()), 
                        Wert = '{newValue}' WHERE Nr = {logNr}";
                    await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                    
                    _logger.LogDebug("LogSignalChange: Offener Eintrag {LogNr} aktualisiert", logNr);
                }
                else
                {
                    // Neuen Eintrag erstellen
                    string sql = $"INSERT INTO SIGNALLOG (Nr, SignalNr, MaschNr, Start, Ende, Wert, Dauer) 
                        VALUES (SIGNALLOGID.NextVal, {entry.SignalNr}, {entry.MaschNr}, GETDATE(), GETDATE(), 
                        '{newValue}', 0)";
                    await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                    
                    _logger.LogDebug("LogSignalChange: Neuer Eintrag erstellt");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in LogSignalChange");
            }
        }

        /// <summary>
        /// Gibt die Nr eines offenen Signal-Log-Eintrags zurück
        /// </summary>
        private async Task<int> GetOpenSignalLogNrAsync(int signalMaschineNr, CancellationToken stoppingToken)
        {
            try
            {
                string sql = $"SELECT Nr FROM SIGNALLOG WHERE SignalMaschineNr = {signalMaschineNr} AND Ende IS NULL ORDER BY Nr DESC";
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    if (await reader.ReadAsync(stoppingToken))
                    {
                        return reader.GetInt32(0);
                    }
                }
                
                return -1;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in GetOpenSignalLogNr");
                return -1;
            }
        }

        /// <summary>
        /// Prüft Datenbankverbindung
        /// </summary>
        private async Task<bool> CheckDatabaseConnectionAsync(CancellationToken stoppingToken)
        {
            try
            {
                if (_database == null || !_database.Connected)
                {
                    _logger.LogWarning("CheckDatabaseConnection: Datenbank nicht verbunden");
                    return false;
                }
                
                // Test-Abfrage
                string sql = "SELECT 1";
                using (var reader = _database.ExecuteReader(sql))
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
                _logger.LogError(ex, "Error in CheckDatabaseConnection");
                return false;
            }
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("SignalLogService started with priority {Priority}", _priority);
            
            try
            {
                if (_database != null)
                {
                    _database.Connected = true;
                    _logger.LogInformation("SignalLogService database connected");
                }
                
                // Signal-Liste initialisieren
                await InitializeSignalListAsync(stoppingToken);
                
                while (!stoppingToken.IsCancellationRequested)
                {
                    // Auf Event warten (wie WaitForSingleObject in Delphi)
                    await _serviceEvents.WaitForEventAsync(ServiceEventSystem.EVENT_SIGNALLLOG, stoppingToken);
                    
                    if (stoppingToken.IsCancellationRequested)
                        break;
                    
                    if (_database == null || !_database.Connected)
                    {
                        _logger.LogWarning("Database not connected, skipping signal logging");
                        continue;
                    }
                    
                    if (!await CheckDatabaseConnectionAsync(stoppingToken))
                    {
                        continue;
                    }
                    
                    // Signal-Logging ausführen
                    await ExecuteSignalLoggingAsync(stoppingToken);
                    
                    _lastExecution = DateTime.Now;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "SignalLogService terminated unexpectedly");
            }
            finally
            {
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

        public override async Task StopAsync(CancellationToken cancellationToken)
        {
            _logger.LogInformation("SignalLogService stopping...");
            await base.StopAsync(cancellationToken);
        }
    }
}
