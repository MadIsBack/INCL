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
    /// Critical Control Center Service - Führt alle CCC-Funktionen aus DBMain.pas aus
    /// Schritt 23: Implementierung der kritischen CCC-Funktionen als eigenständiger Service
    /// </summary>
    public class CCCService : BackgroundService
    {
        private readonly ILogger<CCCService> _logger;
        private readonly IConfiguration _configuration;
        private readonly AppConfig _appConfig;
        private readonly ServiceEventSystem _serviceEvents;
        private CommonDB _database;
        private S7MainData _s7Data;
        private S7MainServiceCCC _ccc;
        
        // Timer-Intervall
        private int _timerInterval = 15; // Sekunden
        
        // Feature-Flags
        public bool AuftragAutomatikStart { get; set; } = false;
        public bool METALL_BEARBEITUNG { get; set; } = false;
        
        public CCCService(
            ILogger<CCCService> logger,
            IConfiguration configuration,
            ServiceEventSystem serviceEvents = null)
        {
            _logger = logger;
            _configuration = configuration;
            _appConfig = new AppConfig();
            _configuration.GetSection("Database").Bind(_appConfig.Database);
            _configuration.GetSection("Main").Bind(_appConfig.Main);
            _serviceEvents = serviceEvents ?? ServiceEvents.Instance;
            
            // Feature-Flags laden
            LoadConfiguration();
            
            // Datenbank initialisieren
            InitializeDatabase();
            
            // S7MainData initialisieren
            _s7Data = new S7MainData();
        }

        private void LoadConfiguration()
        {
            try
            {
                _timerInterval = _configuration.GetValue<int>("Main:Timer", 15);
                AuftragAutomatikStart = _configuration.GetValue<bool>("Features:AuftragAutomatikStart", false);
                METALL_BEARBEITUNG = _configuration.GetValue<bool>("Features:METALL_BEARBEITUNG", false);
                
                _logger.LogInformation("CCCService configuration loaded. Timer: {Timer}s, AuftragAutomatikStart: {AuftragAutomatikStart}",
                    _timerInterval, AuftragAutomatikStart);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error loading CCCService configuration");
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
                
                _logger.LogInformation("CCCService database initialized");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error initializing CCCService database");
            }
        }

        /// <summary>
        /// Setzt die S7MainData-Instanz
        /// </summary>
        public void SetS7Data(S7MainData data)
        {
            _s7Data = data;
            if (_ccc != null)
            {
                _ccc = new S7MainServiceCCC(_logger, _database, null);
            }
        }

        /// <summary>
        /// Setzt das Event für CCCService
        /// </summary>
        public void SetEvent(string eventName)
        {
            _serviceEvents.SetEvent(eventName);
        }
        
        /// <summary>
        /// Pulses das Event für CCCService
        /// </summary>
        public void PulseEvent(string eventName)
        {
            _serviceEvents.PulseEvent(eventName);
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("CCCService started");
            
            try
            {
                // Datenbankverbindung herstellen
                if (_database != null)
                {
                    try
                    {
                        _database.Connected = true;
                        _logger.LogInformation("CCCService database connected");
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Error connecting CCCService database");
                    }
                }
                
                // CCC-Funktionen initialisieren
                _ccc = new S7MainServiceCCC(_logger, _database, null);
                await _ccc.CCC_InitAsync(stoppingToken);

                // Barcode-Scanner initialisieren
                for (int scannerNr = 1; scannerNr <= 3; scannerNr++)
                {
                    await _ccc.CCC_Auftrag_Start_BarcodeAsync(scannerNr, stoppingToken);
                }

                // Hauptschleife
                while (!stoppingToken.IsCancellationRequested)
                {
                    await ExecuteCCCFunktionenAsync(stoppingToken);
                    
                    // Warten bis zum nächsten Zyklus
                    await Task.Delay(_timerInterval * 1000, stoppingToken);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "CCCService terminated unexpectedly");
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
                        _logger.LogError(ex, "Error disconnecting CCCService database");
                    }
                }
                _logger.LogInformation("CCCService stopped");
            }
        }

        private async Task ExecuteCCCFunktionenAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("CCCService: Führe CCC-Funktionen aus");
                
                // CCC-Funktionen aufrufen
                if (AuftragAutomatikStart)
                {
                    await _ccc.CCC_AuftragAutomatikStartAsync(stoppingToken);
                }
                await _ccc.CCC_AuftragAutomatikStartVariabelAsync(stoppingToken);
                await _ccc.CCC_Check_Auftrag_FreigabeAsync(stoppingToken);
                await _ccc.CCC_Daten_AktualisierenAsync(stoppingToken);
                await _ccc.CCC_CheckUnterbrocheneAuftraegeAsync(stoppingToken);
                await _ccc.CCC_Daten_SchreibenAsync(stoppingToken);
                await _ccc.In_SPSWerteDBAsync(stoppingToken);
                
                // Schichtwechsel prüfen
                int alteSchicht;
                if (await _ccc.NeueSchichtAsync(out alteSchicht, stoppingToken))
                {
                    _logger.LogInformation("CCCService: Schichtwechsel erkannt (Alte Schicht: {AlteSchicht})", alteSchicht);
                }
                
                // Rote Lampe prüfen
                await _ccc.CheckRoteLampeAusAsync(stoppingToken);
                
                _logger.LogDebug("CCCService: CCC-Funktionen abgeschlossen");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "CCCService: Fehler bei der Ausführung der CCC-Funktionen");
            }
        }

        public override async Task StopAsync(CancellationToken cancellationToken)
        {
            _logger.LogInformation("CCCService stopping...");
            await base.StopAsync(cancellationToken);
        }
    }
}
