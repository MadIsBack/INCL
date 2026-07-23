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
    /// Schritt 18: ServiceEventSystem Integration
    /// </summary>
    public class ShiftService : BackgroundService
    {
        private readonly ILogger<ShiftService> _logger;
        private readonly IConfiguration _configuration;
        private readonly AppConfig _appConfig;
        private readonly ServiceEventSystem _serviceEvents;
        
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
        
        public ShiftService(ILogger<ShiftService> logger, IConfiguration configuration, ServiceEventSystem serviceEvents = null)
        {
            _logger = logger;
            _configuration = configuration;
            _appConfig = new AppConfig();
            _configuration.GetSection("Database").Bind(_appConfig.Database);
            _configuration.GetSection("Main").Bind(_appConfig.Main);
            _serviceEvents = serviceEvents ?? ServiceEvents.Instance;
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

        /// <summary>
        /// Setzt das Event für ShiftService
        /// </summary>
        public void SetEvent()
        {
            _serviceEvents.SetEvent(ServiceEventSystem.EVENT_SCHICHT);
        }
        
        /// <summary>
        /// Pulses das Event für ShiftService
        /// </summary>
        public void PulseEvent()
        {
            _serviceEvents.PulseEvent(ServiceEventSystem.EVENT_SCHICHT);
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
                    await _serviceEvents.WaitForEventAsync(ServiceEventSystem.EVENT_SCHICHT, stoppingToken);
                    
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
