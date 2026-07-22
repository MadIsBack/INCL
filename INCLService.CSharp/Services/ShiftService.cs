using INCLService.CSharp.Models;
using INCLService.CSharp.Utilities;
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
        private int _priority = 3;
        private DateTime _lastExecution = DateTime.MinValue;
        
        public int AlteSchicht { get; set; } = 0;
        public bool SchichtBerechnung { get; set; } = true;
        public bool BerechnungAktiv { get; set; } = false;
        public bool RecalculateMode { get; set; } = false;
        public int LogFileMode { get; set; } = 2;
        
        public int ShiftModel { get; set; } = 1;
        public int Schicht1 { get; set; } = 6;
        public int Schicht2 { get; set; } = 14;
        public int Schicht3 { get; set; } = 22;
        
        private TPM _thTPM;
        private StillstandEintragsListe _stillstandListe = new StillstandEintragsListe();
        
        public ShiftService(ILogger<ShiftService> logger, IConfiguration configuration)
        {
            _logger = logger;
            _configuration = configuration;
            _appConfig = new AppConfig();
            _configuration.GetSection("Database").Bind(_appConfig.Database);
            _configuration.GetSection("Main").Bind(_appConfig.Main);
            LoadConfiguration();
            InitializeDatabase();
            InitializeTPM();
        }

        private void LoadConfiguration()
        {
            _priority = _configuration.GetValue<int>("Shift:Priority", 3);
            ShiftModel = _configuration.GetValue<int>("Shift:ShiftModel", 1);
            Schicht1 = _configuration.GetValue<int>("Shift:Schicht1", 6);
            Schicht2 = _configuration.GetValue<int>("Shift:Schicht2", 14);
            Schicht3 = _configuration.GetValue<int>("Shift:Schicht3", 22);
        }

        private void InitializeDatabase()
        {
            _database = new CommonDB
            {
                UserName = _appConfig.Database.DB_User,
                Password = _appConfig.Database.DB_Pass,
                Server = _appConfig.Database.DB_Server,
                InitialCatalog = _appConfig.Database.InitialCatalog,
                SqlProvider = _appConfig.Database.Provider
            };
        }

        private void InitializeTPM()
        {
            _thTPM = new TPM(_database)
            {
                ShiftModel = ShiftModel,
                Schicht1 = Schicht1,
                Schicht2 = Schicht2,
                Schicht3 = Schicht3
            };
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("ShiftService started with priority {Priority}", _priority);
            
            try
            {
                if (_database != null)
                {
                    _database.Connected = true;
                    _logger.LogInformation("ShiftService database connected");
                }
                
                while (!stoppingToken.IsCancellationRequested)
                {
                    // Auf Event warten (wie WaitForSingleObject in Delphi)
                    await ServiceEvents.WaitForEventAsync(ServiceEventSystem.EVENT_SCHICHT, stoppingToken);
                    
                    if (stoppingToken.IsCancellationRequested)
                        break;
                    
                    _logger.LogInformation("[{LogFileMode}] Single Object triggered", LogFileMode);
                    
                    if (_database == null || !_database.Connected)
                    {
                        _logger.LogWarning("Database not connected, skipping shift logic");
                        continue;
                    }
                    
                    if (!await CheckDatabaseConnectionAsync(stoppingToken))
                    {
                        continue;
                    }
                    
                    _logger.LogInformation("[{LogFileMode}] Database seems active", LogFileMode);
                    
                    BerechnungAktiv = true;
                    
                    try
                    {
                        if (RecalculateMode)
                        {
                            LogFileMode = 4;
                            _logger.LogInformation("[{LogFileMode}] Start Recalc", LogFileMode);
                            await RecalculationAsync(stoppingToken);
                            _logger.LogInformation("[{LogFileMode}] End Recalc", LogFileMode);
                        }
                        else
                        {
                            LogFileMode = 2;
                            _logger.LogInformation("[{LogFileMode}] Start Shift Change", LogFileMode);
                            await StartSchichtWechselAsync(AlteSchicht, stoppingToken);
                            _logger.LogInformation("[{LogFileMode}] End Shift Change", LogFileMode);
                        }
                    }
                    finally
                    {
                        BerechnungAktiv = false;
                    }
                    
                    _logger.LogInformation("[{LogFileMode}] End of Block", LogFileMode);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "ShiftService terminated unexpectedly");
            }
            finally
            {
                if (_database != null && _database.Connected)
                    _database.Connected = false;
                _logger.LogInformation("ShiftService stopped");
            }
        }

        private async Task<bool> CheckDatabaseConnectionAsync(CancellationToken stoppingToken)
        {
            try
            {
                if (_database == null || !_database.Connected)
                {
                    _logger.LogWarning("Database not connected, retrying...");
                    for (int i = 0; i < 10; i++)
                    {
                        if (stoppingToken.IsCancellationRequested) return false;
                        await Task.Delay(1000, stoppingToken);
                        try
                        {
                            if (_database != null)
                            {
                                _database.Connected = false;
                                _database.Connected = true;
                            }
                        }
                        catch (Exception ex)
                        {
                            _logger.LogError(ex, "Error reconnecting database");
                        }
                    }
                    return _database != null && _database.Connected;
                }
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error checking database connection");
                return false;
            }
        }

        private async Task RecalculationAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogInformation("Recalculation started");
                if (_thTPM != null) _thTPM.Calculate(true);
                await BerechneStillstaendeAsync(stoppingToken);
                _logger.LogInformation("Recalculation completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in Recalculation");
            }
        }

        private async Task StartSchichtWechselAsync(int alteSchicht, CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogInformation("Schichtwechsel von Schicht {AlteSchicht} gestartet", alteSchicht);
                if (_thTPM != null)
                {
                    _thTPM.Schicht = alteSchicht;
                    _thTPM.Calculate(false);
                }
                await BerechneStillstaendeAsync(stoppingToken);
                await SaveSchichtwechselAsync(alteSchicht, stoppingToken);
                _logger.LogInformation("Schichtwechsel abgeschlossen");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in StartSchichtWechsel");
            }
        }

        private async Task BerechneStillstaendeAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("Berechne Stillstände...");
                using (var reader = _database.ExecuteReader(
                    "SELECT Nr, Kommt, Geht, GrundNr, Geplant, Maschnr, Gruppe, Stillstand FROM Stillstandslog WHERE Berechnet = 0"))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        var eintrag = new StillstandEintrag
                        {
                            Nr = reader.GetInt32(0),
                            Kommt = reader.GetDateTime(1),
                            Geht = reader.GetDateTime(2),
                            GrundNr = reader.GetInt32(3),
                            Geplant = reader.GetBoolean(4),
                            Maschnr = reader.GetInt32(5),
                            Gruppe = reader.GetInt32(6),
                            Stillstand = reader.GetString(7)
                        };
                        _stillstandListe.Add(eintrag);
                    }
                }
                foreach (var maschNr in GetUniqueMaschinenNummern())
                {
                    var dauer = _stillstandListe.GetDauerByMaschNr(maschNr);
                    _logger.LogDebug("Maschine {MaschNr}: Stillstandsdauer = {Dauer} Minuten", maschNr, dauer);
                }
                _logger.LogDebug("Stillstände berechnet");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error berechnend Stillstände");
            }
        }

        private List<int> GetUniqueMaschinenNummern()
        {
            var maschinenNummern = new List<int>();
            foreach (var eintrag in _stillstandListe)
            {
                if (!maschinenNummern.Contains(eintrag.Maschnr))
                    maschinenNummern.Add(eintrag.Maschnr);
            }
            return maschinenNummern;
        }

        private async Task SaveSchichtwechselAsync(int alteSchicht, CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("Speichere Schichtwechsel...");
                using (var command = _database.CreateCommand())
                {
                    command.CommandText = "UPDATE Schichtwechsel SET Berechnet = 1 WHERE Schicht = @Schicht";
                    command.Parameters.AddWithValue("@Schicht", alteSchicht);
                    await command.ExecuteNonQueryAsync(stoppingToken);
                }
                _logger.LogDebug("Schichtwechsel gespeichert");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error speichernd Schichtwechsel");
            }
        }

        public bool CheckSchichtwechsel()
        {
            try
            {
                int signalNr = GetSignalNr(TPM.CSTILLNRARBEITSFREI);
                if (signalNr == -1) return false;
                
                bool manuell = false;
                using (var reader = _database.ExecuteReader("SELECT manuelle_Buchung FROM setup WHERE nr = 1"))
                {
                    if (reader.Read()) manuell = reader.GetInt32(0) == 1;
                }
                
                if (!manuell)
                {
                    using (var reader = _database.ExecuteReader(
                        "SELECT COUNT(*) FROM SIGNAL_SCHREIBEN WHERE SignalNr = @SignalNr"))
                    {
                        reader.Parameters.AddWithValue("@SignalNr", signalNr);
                        if (reader.Read() && reader.GetInt32(0) > 0) return false;
                    }
                }
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error checking Schichtwechsel");
                return false;
            }
        }

        private int GetSignalNr(int signalArt)
        {
            try
            {
                using (var reader = _database.ExecuteReader(
                    "SELECT SignalNr FROM SIGNALE WHERE SignalArt = @SignalArt"))
                {
                    reader.Parameters.AddWithValue("@SignalArt", signalArt);
                    if (reader.Read()) return reader.GetInt32(0);
                }
                return -1;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in GetSignalNr");
                return -1;
            }
        }

        public override async Task StopAsync(CancellationToken cancellationToken)
        {
            _logger.LogInformation("ShiftService stopping...");
            await base.StopAsync(cancellationToken);
        }
    }
}
