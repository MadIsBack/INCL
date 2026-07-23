using INCLService.CSharp.Utilities;
using INCLService.CSharp.Models;
using INCLUDIS.Utils.CommonDB;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using System;
using System.IO;
using System.Threading;
using System.Threading.Tasks;

namespace INCLService.CSharp.Services
{
    /// <summary>
    /// Service für Datenbank-Backups
    /// Äquivalent zu TThread_DBBackup in Delphi
    /// Schritt 18: ServiceEventSystem Integration
    /// </summary>
    public class DBBackupService : BackgroundService
    {
        private readonly ILogger<DBBackupService> _logger;
        private readonly IConfiguration _configuration;
        private readonly AppConfig _appConfig;
        private readonly ServiceEventSystem _serviceEvents;
        
        private CommonDB _database;
        private int _priority = 4; // Default: tpNormal
        private int _timerInterval = 60; // Minuten
        private DateTime _lastExecution = DateTime.MinValue;
        private string _backupPath = string.Empty;
        
        public DBBackupService(
            ILogger<DBBackupService> logger,
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
        /// Setzt das Event für DBBackupService
        /// </summary>
        public void SetEvent()
        {
            _serviceEvents.SetEvent(ServiceEventSystem.EVENT_DBBACKUP);
        }
        
        /// <summary>
        /// Pulses das Event für DBBackupService
        /// </summary>
        public void PulseEvent()
        {
            _serviceEvents.PulseEvent(ServiceEventSystem.EVENT_DBBACKUP);
        }

        private void LoadConfiguration()
        {
            try
            {
                // Priorität aus Konfiguration laden
                _priority = _configuration.GetValue<int>("DBBackup:Priority", 4);
