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
        
        // Signal-Liste
        private List<SignalClass> _entryList = new List<SignalClass>();
        
        // Signal-Log-Liste für offene Einträge
        private SignalLogEintragListe _openSignalLogEntries = new SignalLogEintragListe();
        
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
                
                // Signalliste initialisieren
                await InitializeSignalListAsync(stoppingToken);
                
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

        private async Task InitializeSignalListAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogInformation("Initializing signal list...");
                
                if (_database == null || !_database.Connected)
                {
                    _logger.LogWarning("Database not connected, skipping signal list initialization");
                    return;
                }
                
                // Signalliste anlegen und aktuelle Werte lesen
                string sql = @"SELECT sm.nr nr, sm.maschnr maschnr, s.signalnr signalnr, sm.istwert istwert
                    FROM signale s 
                    LEFT JOIN signal_maschine sm ON sm.signalnr = s.signalnr 
                    WHERE s.logit=1";
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        var signalClass = new SignalClass
                        {
                            SignalNr = reader.GetInt32(reader.GetOrdinal("signalnr")),
                            Nr = reader.GetInt32(reader.GetOrdinal("nr")),
                            MaschNr = reader.GetInt32(reader.GetOrdinal("maschnr")),
                            Istwert = reader.GetString(reader.GetOrdinal("istwert")),
                            Oldwert = "0"
                        };
                        
                        _entryList.Add(signalClass);
                    }
                }
                
                // Alte Werte in Signalliste eintragen (offene Einträge aus Signallog)
                sql = "SELECT * FROM signallog WHERE enddatumzeit IS null";
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        var maschNr = reader.GetInt32(reader.GetOrdinal("maschnr"));
                        var signalNr = reader.GetInt32(reader.GetOrdinal("signalnr"));
                        var wert = reader.GetString(reader.GetOrdinal("wert"));
                        var nr = reader.GetInt32(reader.GetOrdinal("nr"));
                        
                        var signalClass = GetSignalByNumbers(maschNr, signalNr);
                        if (signalClass != null)
                        {
                            signalClass.Oldwert = wert;
                            signalClass.Oldlognr = nr;
                        }
                    }
                }
                
                _logger.LogInformation("Signal list initialized with {Count} signals", _entryList.Count);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error initializing signal list");
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
                
                // Lesen von aktuellen Werten und Vergleichen
                string sql = @"SELECT sm.nr nr, sm.maschnr maschnr, s.signalnr signalnr, sm.istwert istwert
                    FROM signale s 
                    LEFT JOIN signal_maschine sm ON sm.signalnr = s.signalnr 
                    WHERE s.logit=1";
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        var nr = reader.GetInt32(reader.GetOrdinal("nr"));
                        var signalClass = GetSignalBySeqNumber(nr);
                        
                        if (signalClass != null)
                        {
                            signalClass.Istwert = reader.GetString(reader.GetOrdinal("istwert"));
                            
                            // Wenn sich der Wert geändert hat
                            if (signalClass.Istwert != signalClass.Oldwert)
                            {
                                await HandleSignalChangeAsync(signalClass, stoppingToken);
                            }
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

        private async Task HandleSignalChangeAsync(SignalClass signalClass, CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogInformation("Signal change detected - Maschine: {MaschNr}, Signal: {SignalNr}, Old: {Old}, New: {New}",
                    signalClass.MaschNr, signalClass.SignalNr, signalClass.Oldwert, signalClass.Istwert);
                
                // Alten Eintrag beenden
                if (signalClass.Oldlognr > -1)
                {
                    string sql = $"UPDATE signallog SET enddatumzeit = '{FloatToPunktStr(DateTime.Now)}' WHERE nr = {signalClass.Oldlognr}";
                    using (var command = _database.CreateCommand(sql))
                    {
                        await command.ExecuteNonQueryAsync(stoppingToken);
                    }
                }
                
                // Neuer Wert speichern
                signalClass.Oldwert = signalClass.Istwert;
                
                // Neue Log-Nummer generieren (in Oracle: signallogid.nextval)
                // In SQL Server: IDENTITY oder SEQUENCE
                int newLogNr = await GetNextLogNrAsync(stoppingToken);
                signalClass.Oldlognr = newLogNr;
                
                // Neuen Eintrag in Signallog schreiben
                sql = $"INSERT INTO signallog (nr, startdatumzeit, wert, maschnr, signalnr) 
                    VALUES ({newLogNr}, '{FloatToPunktStr(DateTime.Now)}', '{signalClass.Istwert}', {signalClass.MaschNr}, {signalClass.SignalNr})";
                
                using (var command = _database.CreateCommand(sql))
                {
                    await command.ExecuteNonQueryAsync(stoppingToken);
                }
                
                _logger.LogDebug("Signal change logged - LogNr: {LogNr}", newLogNr);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error handling signal change");
            }
        }

        private async Task<int> GetNextLogNrAsync(CancellationToken stoppingToken)
        {
            try
            {
                // Versuchen, die nächste Log-Nummer zu generieren
                // Abhängig vom Datenbanksystem
                
                // Für SQL Server mit IDENTITY
                string sql = "SELECT ISNULL(MAX(nr), 0) + 1 FROM signallog";
                using (var reader = _database.ExecuteReader(sql))
                {
                    if (await reader.ReadAsync(stoppingToken))
                    {
                        return reader.GetInt32(0);
                    }
                }
                
                return 1;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting next log number");
                return 1;
            }
        }

        /// <summary>
        /// Sucht ein Signal nach Maschinen-Nummer und Signal-Nummer
        /// Äquivalent zu getSignalByNumbers in Delphi
        /// </summary>
        private SignalClass GetSignalByNumbers(int maschNr, int signalNr)
        {
            foreach (var signal in _entryList)
            {
                if (signal.MaschNr == maschNr && signal.SignalNr == signalNr)
                {
                    return signal;
                }
            }
            return null;
        }

        /// <summary>
        /// Sucht ein Signal nach Sequenz-Nummer
        /// Äquivalent zu getSignalBySeqNumber in Delphi
        /// </summary>
        private SignalClass GetSignalBySeqNumber(int nr)
        {
            foreach (var signal in _entryList)
            {
                if (signal.Nr == nr)
                {
                    return signal;
                }
            }
            return null;
        }

        /// <summary>
        /// Konvertiert einen DateTime-Wert in einen String mit Punkt als Dezimaltrennzeichen
        /// Äquivalent zu FloatToPunktStr in Delphi
        /// </summary>
        private string FloatToPunktStr(DateTime dateTime)
        {
            // In Delphi wird N_o_w (Now) als Float gespeichert
            // In C# konvertieren wir das Datum in einen Oracle/SQL Server kompatiblen String
            return dateTime.ToString("yyyy-MM-dd HH:mm:ss", CultureInfo.InvariantCulture);
        }

        public override async Task StopAsync(CancellationToken cancellationToken)
        {
            _logger.LogInformation("SignalLogService stopping...");
            await base.StopAsync(cancellationToken);
        }
    }
}
