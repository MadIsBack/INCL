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
        public bool SchichtBerechnung { get; set; } = true;
        public bool BerechnungAktiv { get; set; } = false;
        public bool RecalculateMode { get; set; } = false;
        public int LogFileMode { get; set; } = 2; // 2 = Shift
        
        // Shift-Modell (1 = 2-Schicht, 2 = 3-Schicht)
        public int ShiftModel { get; set; } = 1;
        public int Schicht1 { get; set; } = 6; // 6:00 Uhr
        public int Schicht2 { get; set; } = 14; // 14:00 Uhr
        public int Schicht3 { get; set; } = 22; // 22:00 Uhr
        
        // TPM-Instanz
        private TPM _thTPM;
        
        // Stillstandsliste
        private StillstandEintragsListe _stillstandListe = new StillstandEintragsListe();
        
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
            InitializeTPM();
        }

        private void LoadConfiguration()
        {
            try
            {
                // Priorität aus Konfiguration laden
                _priority = _configuration.GetValue<int>("Shift:Priority", 3);
                _timerInterval = _configuration.GetValue<int>("Shift:Timer", 60);
                
                // Shift-Modell und Schichtzeiten
                ShiftModel = _configuration.GetValue<int>("Shift:ShiftModel", 1);
                Schicht1 = _configuration.GetValue<int>("Shift:Schicht1", 6);
                Schicht2 = _configuration.GetValue<int>("Shift:Schicht2", 14);
                Schicht3 = _configuration.GetValue<int>("Shift:Schicht3", 22);
                
                _logger.LogInformation("ShiftService configured - Priority: {Priority}, Timer: {Timer}s, ShiftModel: {Model}",
                    _priority, _timerInterval, ShiftModel);
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

        private void InitializeTPM()
        {
            try
            {
                _thTPM = new TPM(_database);
                _thTPM.ShiftModel = ShiftModel;
                _thTPM.Schicht1 = Schicht1;
                _thTPM.Schicht2 = Schicht2;
                _thTPM.Schicht3 = Schicht3;
                
                _logger.LogInformation("ShiftService TPM initialized");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error initializing ShiftService TPM");
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
                _logger.LogInformation("[{LogFileMode}] Wait for Single Object...", LogFileMode);
                
                // Hier würde auf ein Event gewartet werden (in Delphi: WaitForSingleObject)
                // In C# verwenden wir eine Verzögerung als Platzhalter
                await Task.Delay(1000, stoppingToken);
                
                _logger.LogInformation("[{LogFileMode}] Single Object triggered", LogFileMode);
                
                if (_database == null || !_database.Connected)
                {
                    _logger.LogWarning("Database not connected, skipping shift logic");
                    return;
                }
                
                // Datenbankverbindung prüfen
                if (!await CheckDatabaseConnectionAsync(stoppingToken))
                {
                    return;
                }
                
                _logger.LogInformation("[{LogFileMode}] Database seems active", LogFileMode);
                
                BerechnungAktiv = true;
                
                try
                {
                    if (stoppingToken.IsCancellationRequested)
                    {
                        _logger.LogInformation("[{LogFileMode}] Shift Calc Terminated - 1", LogFileMode);
                        return;
                    }
                    
                    if (RecalculateMode)
                    {
                        LogFileMode = 4; // Recalc
                        _logger.LogInformation("[{LogFileMode}] Start Recalc", LogFileMode);
                        await RecalculationAsync(stoppingToken);
                        _logger.LogInformation("[{LogFileMode}] End Recalc", LogFileMode);
                    }
                    else
                    {
                        LogFileMode = 2; // Shift
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
                _logger.LogInformation("[{LogFileMode}] ----------------------------------------------------", LogFileMode);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "[{LogFileMode}] Exception in Shift.Execute", LogFileMode);
            }
        }

        private async Task<bool> CheckDatabaseConnectionAsync(CancellationToken stoppingToken)
        {
            try
            {
                // Datenbankverbindung prüfen
                if (_database == null || !_database.Connected)
                {
                    _logger.LogWarning("[{LogFileMode}] Database not connected, retrying...", LogFileMode);
                    
                    // 30 Sekunden warten und mehrmals versuchen
                    for (int i = 0; i < 10; i++)
                    {
                        if (stoppingToken.IsCancellationRequested)
                        {
                            _logger.LogInformation("[{LogFileMode}] Shift Calc Terminated - 2", LogFileMode);
                            return false;
                        }
                        
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
                            _logger.LogError(ex, "[{LogFileMode}] Error reconnecting database", LogFileMode);
                        }
                    }
                    
                    return _database != null && _database.Connected;
                }
                
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "[{LogFileMode}] Error checking database connection", LogFileMode);
                return false;
            }
        }

        private async Task RecalculationAsync(CancellationToken stoppingToken)
        {
            // Hier würde die Neuberechnung durchgeführt werden
            // Äquivalent zu Recalculation in Delphi
            try
            {
                _logger.LogInformation("Recalculation started");
                
                // TPM-Daten neu berechnen
                if (_thTPM != null)
                {
                    _thTPM.Calculate(true); // Mit Korrektur
                }
                
                // Stillstandsberechnungen
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
            // Hier würde der Schichtwechsel gestartet werden
            // Äquivalent zu StartSchichtWechsel in Delphi
            try
            {
                _logger.LogInformation("Schichtwechsel von Schicht {AlteSchicht} gestartet", alteSchicht);
                
                // TPM-Daten für neue Schicht berechnen
                if (_thTPM != null)
                {
                    _thTPM.Schicht = alteSchicht;
                    _thTPM.Calculate(false); // Ohne Korrektur
                }
                
                // Stillstandsberechnungen für die neue Schicht
                await BerechneStillstaendeAsync(stoppingToken);
                
                // Schichtwechsel in der Datenbank speichern
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
            // Hier würden die Stillstände berechnet werden
            try
            {
                _logger.LogDebug("Berechne Stillstände...");
                
                // Stillstandsdaten aus der Datenbank laden
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
                
                // Stillstandszeiten berechnen
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
                {
                    maschinenNummern.Add(eintrag.Maschnr);
                }
            }
            return maschinenNummern;
        }

        private async Task SaveSchichtwechselAsync(int alteSchicht, CancellationToken stoppingToken)
        {
            // Hier würde der Schichtwechsel in der Datenbank gespeichert werden
            try
            {
                _logger.LogDebug("Speichere Schichtwechsel...");
                
                // Beispiel: Schichtwechsel in der Datenbank markieren
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

        /// <summary>
        /// Prüft, ob ein Schichtwechsel nötig ist
        /// Äquivalent zu Schichtwechsel in Delphi
        /// </summary>
        public bool CheckSchichtwechsel()
        {
            try
            {
                // Prüfen, ob ein Schichtwechsel-Signal vorliegt
                int signalNr = GetSignalNr(TPM.CSTILLNRARBEITSFREI); // Beispiel-Signal
                
                if (signalNr == -1)
                {
                    return false;
                }
                
                // Prüfen, ob manuelle Buchung aktiviert ist
                bool manuell = false;
                using (var reader = _database.ExecuteReader("SELECT manuelle_Buchung FROM setup WHERE nr = 1"))
                {
                    if (reader.Read())
                    {
                        manuell = reader.GetInt32(0) == 1;
                    }
                }
                
                // Prüfen, ob Datensatz schon erzeugt wurde
                if (!manuell)
                {
                    using (var reader = _database.ExecuteReader(
                        "SELECT COUNT(*) FROM SIGNAL_SCHREIBEN WHERE SignalNr = @SignalNr",
                        System.Data.CommandType.Text))
                    {
                        if (reader.Read() && reader.GetInt32(0) > 0)
                        {
                            return false; // Schon erzeugt
                        }
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

        /// <summary>
        /// Gibt die Signal-Nummer für eine bestimmte Signal-Art zurück
        /// Äquivalent zu GetSignalNr in Delphi
        /// </summary>
        private int GetSignalNr(int signalArt)
        {
            try
            {
                using (var reader = _database.ExecuteReader(
                    "SELECT SignalNr FROM SIGNALE WHERE SignalArt = @SignalArt",
                    System.Data.CommandType.Text))
                {
                    if (reader.Read())
                    {
                        return reader.GetInt32(0);
                    }
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
