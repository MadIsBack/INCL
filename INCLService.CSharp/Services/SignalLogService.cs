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
    /// Äquivalent zu TThread_Signallog in Delphi
    /// Schritt 18: ServiceEventSystem Integration
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

