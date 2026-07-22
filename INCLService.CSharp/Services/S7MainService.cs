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
    /// Haupt-Service, der alle anderen Services koordiniert
    /// Äquivalent zu TS7Main in Delphi
    /// </summary>
    public class S7MainService : BackgroundService
    {
        private readonly ILogger<S7MainService> _logger;
        private readonly IConfiguration _configuration;
        private readonly AppConfig _appConfig;
        
        private CommonDB _database;
        private bool _hochlauf = true;
        private bool _firstLauf = true;
        private bool _datenEnabled = true;
        private int _errorCount = 0;
        
        // Timer-Intervalle aus Konfiguration
        private int _mainTimerInterval = 15; // Sekunden
        private int _aliveTimerInterval = 15; // Sekunden
        
        // Konfigurationseinstellungen
        public bool Pruefen { get; set; } = false;
        public bool Packen { get; set; } = false;
        public bool VerpacktBarcode { get; set; } = false;
        public bool VerpacktAusAusschuss { get; set; } = false;
        public bool EndeAusVerpackt { get; set; } = false;
        public bool BCDSchalter { get; set; } = false;
        public bool SPC { get; set; } = false;
        public bool SPCStich { get; set; } = false;
        public bool Halbautomatik { get; set; } = false;
        public bool PruefGleichPack { get; set; } = false;
        public bool Werkzeugverwaltung { get; set; } = false;
        public bool Maschinenreinigung { get; set; } = false;
        public bool WerkstattAusschuss { get; set; } = false;
        public bool Differenzliste { get; set; } = false;
        public bool RuntimeLog { get; set; } = false;
        public bool RuestzeitAuftragFolgeAuftrag { get; set; } = false;
        
        public string ServerNameDesDienstes { get; private set; } = "LOCALHOST";
        public string IgnorePendingStatement { get; private set; } = " AND pending = 0";

        public S7MainService(
            ILogger<S7MainService> logger,
            IConfiguration configuration)
        {
            _logger = logger;
            _configuration = configuration;
            
            _appConfig = new AppConfig();
            _configuration.GetSection("Database").Bind(_appConfig.Database);
            _configuration.GetSection("Main").Bind(_appConfig.Main);
            
            // Servername setzen
            ServerNameDesDienstes = Environment.MachineName.ToUpper();
            
            // Eigene Datenbankverbindung initialisieren
            InitializeDatabase();
            
            // Konfiguration aus appsettings.json laden
            LoadConfiguration();
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
                
                _logger.LogInformation("S7MainService database initialized");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error initializing S7MainService database");
            }
        }

        private void LoadConfiguration()
        {
            try
            {
                // Timer-Intervalle
                _mainTimerInterval = _configuration.GetValue<int>("Main:Timer", 15);
                _aliveTimerInterval = _configuration.GetValue<int>("Main:AliveTimerInterval", 15);
                
                // IgnorePending-Einstellung
                var ignorePending = _configuration.GetValue<bool>("Main:IgnorePending", true);
                IgnorePendingStatement = ignorePending ? " AND pending = 0" : string.Empty;
                
                // Feature-Flags
                Pruefen = _configuration.GetValue<bool>("Features:Pruefen", false);
                Packen = _configuration.GetValue<bool>("Features:Packen", false);
                VerpacktBarcode = _configuration.GetValue<bool>("Features:VerpacktBarcode", false);
                VerpacktAusAusschuss = _configuration.GetValue<bool>("Features:VerpacktAusAusschuss", false);
                EndeAusVerpackt = _configuration.GetValue<bool>("Features:EndeAusVerpackt", false);
                BCDSchalter = _configuration.GetValue<bool>("Features:BCDSchalter", false);
                SPC = _configuration.GetValue<bool>("Features:SPC", false);
                SPCStich = _configuration.GetValue<bool>("Features:SPCStich", false);
                Halbautomatik = _configuration.GetValue<bool>("Features:Halbautomatik", false);
                PruefGleichPack = _configuration.GetValue<bool>("Features:PruefGleichPack", false);
                Werkzeugverwaltung = _configuration.GetValue<bool>("Features:Werkzeugverwaltung", false);
                Maschinenreinigung = _configuration.GetValue<bool>("Features:Maschinenreinigung", false);
                WerkstattAusschuss = _configuration.GetValue<bool>("Features:WerkstattAusschuss", false);
                Differenzliste = _configuration.GetValue<bool>("Features:Differenzliste", false);
                RuntimeLog = _configuration.GetValue<bool>("Features:RuntimeLog", false);
                RuestzeitAuftragFolgeAuftrag = _configuration.GetValue<bool>("Features:RuestzeitAuftragFolgeAuftrag", false);
                
                _logger.LogInformation("S7MainService configuration loaded. MainTimer: {Timer}s, AliveTimer: {AliveTimer}s",
                    _mainTimerInterval, _aliveTimerInterval);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error loading S7MainService configuration");
            }
        }

        private async Task Timer1TimerAsync(CancellationToken stoppingToken)
        {
            try
            {
                // Hier würde die Haupt-Logik ausführen
                // Daten lesen, verarbeiten, etc.
                
                if (_hochlauf)
                {
                    _hochlauf = false;
                    _logger.LogInformation("Hochlaufphase abgeschlossen");
                }
                
                if (_firstLauf)
                {
                    _firstLauf = false;
                    _logger.LogInformation("Erster Lauf abgeschlossen");
                }
                
                // Datenbank-Operationen
                if (_datenEnabled && _database != null && _database.Connected)
                {
                    // Daten lesen und verarbeiten
                    await ReadDataAsync(stoppingToken);
                }
                else if (_database != null && !_database.Connected)
                {
                    // Versuchen, die Verbindung wiederherzustellen
                    await ReconnectDatabaseAsync(stoppingToken);
                }
            }
            catch (Exception ex)
            {
                _errorCount++;
                _logger.LogError(ex, "Error in Timer1Timer (Count: {Count})", _errorCount);
            }
        }

        private async Task ReconnectDatabaseAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogWarning("Attempting to reconnect database...");
                _database.Connected = false;
                await Task.Delay(5000, stoppingToken); // 5 Sekunden warten
                _database.Connected = true;
                _logger.LogInformation("Database reconnected successfully");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error reconnecting database");
            }
        }

        private async Task ReadDataAsync(CancellationToken stoppingToken)
        {
            // Hier würden die Daten aus der Datenbank gelesen werden
            // Äquivalent zu DatenLesen, DatenLesen2, DatenLesen_Metall in Delphi
            
            try
            {
                // Beispiel: Setup-Daten laden
                using (var reader = _database.ExecuteReader("SELECT * FROM SETUP WHERE Nr = 1"))
                {
                    if (await reader.ReadAsync(stoppingToken))
                    {
                        // Daten verarbeiten
                        _logger.LogDebug("Setup data loaded");
                    }
                }
                
                // Beispiel: Maschinenstatus lesen
                using (var reader = _database.ExecuteReader(
                    "SELECT MaschinenNr, Status, LetzteAenderung FROM Maschinenstatus WHERE Aktiv = 1"))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        var maschinenNr = reader.GetInt32(0);
                        var status = reader.GetString(1);
                        var letzteAenderung = reader.GetDateTime(2);
                        
                        _logger.LogDebug("Maschine {Nr}: Status={Status}, Letzte Änderung={Zeit}",
                            maschinenNr, status, letzteAenderung);
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error reading data from database");
            }
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("S7MainService started");
            
            try
            {
                // Datenbankverbindung herstellen
                if (_database != null)
                {
                    try
                    {
                        _database.Connected = true;
                        _logger.LogInformation("S7MainService database connected");
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Error connecting S7MainService database");
                    }
                }
                
                // Initialisierung
                await InitializeAsync(stoppingToken);
                
                // Hauptschleife
                while (!stoppingToken.IsCancellationRequested)
                {
                    await Timer1TimerAsync(stoppingToken);
                    
                    // Warten bis zum nächsten Zyklus
                    await Task.Delay(_mainTimerInterval * 1000, stoppingToken);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "S7MainService terminated unexpectedly");
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
                        _logger.LogError(ex, "Error disconnecting S7MainService database");
                    }
                }
                _logger.LogInformation("S7MainService stopped");
            }
        }

        private async Task InitializeAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogInformation("S7MainService initializing...");
                
                // Datenbankverbindung prüfen
                if (_database == null || !_database.Connected)
                {
                    _logger.LogWarning("Database not connected");
                    return;
                }
                
                // Setup-Daten laden
                await LoadSetupDataAsync(stoppingToken);
                
                _logger.LogInformation("S7MainService initialized successfully");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error initializing S7MainService");
            }
        }

        private async Task LoadSetupDataAsync(CancellationToken stoppingToken)
        {
            try
            {
                using (var reader = _database.ExecuteReader(
                    "SELECT * FROM SETUP WHERE Nr = 1"))
                {
                    if (await reader.ReadAsync(stoppingToken))
                    {
                        // Sprache und andere Einstellungen laden
                        // Äquivalent zu den Delphi-Code in TS7Main.Create
                        _logger.LogInformation("Setup data loaded from database");
                    }
                    else
                    {
                        _logger.LogError("Error: Setup data not found");
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error loading setup data");
            }
        }

        public override async Task StopAsync(CancellationToken cancellationToken)
        {
            _logger.LogInformation("S7MainService stopping...");
            await base.StopAsync(cancellationToken);
        }
    }
}
