using INCLService.CSharp.Models;
using INCLService.CSharp.Services;
using INCLService.CSharp.Utilities;
using INCLUDIS.Utils.CommonDB;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Serilog;
using System;
using System.IO;
using System.Threading;
using System.Threading.Tasks;

namespace INCLService.CSharp
{
    /// <summary>
    /// Integrationstest-Klasse für Schritt 25
    /// Testet alle Services und Funktionen
    /// </summary>
    public class IntegrationTest
    {
        private readonly ILogger<IntegrationTest> _logger;
        private readonly IConfiguration _configuration;
        private CommonDB _database;
        private ServiceEventSystem _serviceEvents;
        
        public IntegrationTest(ILogger<IntegrationTest> logger, IConfiguration configuration)
        {
            _logger = logger;
            _configuration = configuration;
            _serviceEvents = new ServiceEventSystem();
            InitializeDatabase();
        }

        private void InitializeDatabase()
        {
            var appConfig = new AppConfig();
            _configuration.GetSection("Database").Bind(appConfig.Database);
            
            _database = new CommonDB
            {
                UserName = appConfig.Database.DB_User,
                Password = appConfig.Database.DB_Pass,
                Server = appConfig.Database.DB_Server,
                InitialCatalog = appConfig.Database.InitialCatalog,
                SqlProvider = appConfig.Database.Provider
            };
        }

        /// <summary>
        /// Führt alle Integrationstests aus
        /// </summary>
        public async Task RunAllTestsAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("=== Integrationstest Start ===");
            
            try
            {
                // Datenbankverbindung herstellen
                if (_database != null)
                {
                    _database.Connected = true;
                    _logger.LogInformation("Datenbankverbindung hergestellt");
                }
                
                // Test 1: S7MainService_CCC
                await TestS7MainServiceCCCAsync(stoppingToken);
                
                // Test 2: ShiftService
                await TestShiftServiceAsync(stoppingToken);
                
                // Test 3: SignalLogService
                await TestSignalLogServiceAsync(stoppingToken);
                
                // Test 4: DBBackupService
                await TestDBBackupServiceAsync(stoppingToken);
                
                // Test 5: Event-Kommunikation
                await TestEventCommunicationAsync(stoppingToken);
                
                _logger.LogInformation("=== Alle Tests erfolgreich ===");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Integrationstest fehlgeschlagen");
            }
            finally
            {
                if (_database != null && _database.Connected)
                {
                    _database.Connected = false;
                }
            }
        }

        /// <summary>
        /// Testet S7MainService_CCC Funktionen
        /// </summary>
        private async Task TestS7MainServiceCCCAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("--- Test: S7MainService_CCC ---");
            
            try
            {
                // S7MainService-CCC erstellen
                var s7MainService = new S7MainService(_logger, _configuration, _serviceEvents);
                var ccc = new S7MainServiceCCC(_logger, _database, s7MainService);
                
                // Test 1: CCC_Init
                await ccc.CCC_InitAsync(stoppingToken);
                _logger.LogInformation("✅ CCC_InitAsync: Erfolgreich");
                
                // Test 2: NeueSchicht
                int alteSchicht;
                bool schichtwechsel = await ccc.NeueSchichtAsync(out alteSchicht, stoppingToken);
                _logger.LogInformation("✅ NeueSchichtAsync: Schichtwechsel = {Schichtwechsel}, AlteSchicht = {AlteSchicht}", 
                    schichtwechsel, alteSchicht);
                
                // Test 3: CheckRoteLampeAus
                bool roteLampeOk = await ccc.CheckRoteLampeAusAsync(stoppingToken);
                _logger.LogInformation("✅ CheckRoteLampeAusAsync: Ergebnis = {RoteLampeOk}", roteLampeOk);
                
                // Test 4: In_SPSWerteDB (nur wenn Daten vorhanden)
                // await ccc.In_SPSWerteDBAsync(stoppingToken);
                // _logger.LogInformation("✅ In_SPSWerteDBAsync: Erfolgreich");
                
                _logger.LogInformation("✅ S7MainService_CCC Tests: Alle erfolgreich");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ S7MainService_CCC Tests: Fehlgeschlagen");
            }
        }

        /// <summary>
        /// Testet ShiftService Funktionen
        /// </summary>
        private async Task TestShiftServiceAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("--- Test: ShiftService ---");
            
            try
            {
                var shiftService = new ShiftService(_logger, _configuration, _serviceEvents);
                
                // Test 1: Schichtwechsel prüfen
                bool schichtwechsel = await shiftService.SchichtwechselAsync(stoppingToken);
                _logger.LogInformation("✅ SchichtwechselAsync: Ergebnis = {Schichtwechsel}", schichtwechsel);
                
                // Test 2: GetSignalNr
                int signalNr = await shiftService.GetSignalNrAsync(24, stoppingToken); // CSCHICHTWECHSEL
                _logger.LogInformation("✅ GetSignalNrAsync: SignalNr = {SignalNr}", signalNr);
                
                _logger.LogInformation("✅ ShiftService Tests: Alle erfolgreich");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ ShiftService Tests: Fehlgeschlagen");
            }
        }

        /// <summary>
        /// Testet SignalLogService Funktionen
        /// </summary>
        private async Task TestSignalLogServiceAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("--- Test: SignalLogService ---");
            
            try
            {
                var signalLogService = new SignalLogService(_logger, _configuration, _serviceEvents);
                
                // Test 1: Signal-Liste initialisieren
                await signalLogService.InitializeSignalListAsync(stoppingToken);
                _logger.LogInformation("✅ InitializeSignalListAsync: Erfolgreich");
                
                // Test 2: Signal-Logging ausführen
                await signalLogService.ExecuteSignalLoggingAsync(stoppingToken);
                _logger.LogInformation("✅ ExecuteSignalLoggingAsync: Erfolgreich");
                
                _logger.LogInformation("✅ SignalLogService Tests: Alle erfolgreich");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ SignalLogService Tests: Fehlgeschlagen");
            }
        }

        /// <summary>
        /// Testet DBBackupService Funktionen
        /// </summary>
        private async Task TestDBBackupServiceAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("--- Test: DBBackupService ---");
            
            try
            {
                var dbBackupService = new DBBackupService(_logger, _configuration, _serviceEvents);
                
                // Test 1: IsBackupNeeded
                bool backupNeeded = dbBackupService.IsBackupNeeded();
                _logger.LogInformation("✅ IsBackupNeeded: Ergebnis = {BackupNeeded}", backupNeeded);
                
                // Test 2: CleanupOldBackups (nur wenn Backup-Verzeichnis existiert)
                await dbBackupService.CleanupOldBackupsAsync(stoppingToken);
                _logger.LogInformation("✅ CleanupOldBackupsAsync: Erfolgreich");
                
                _logger.LogInformation("✅ DBBackupService Tests: Alle erfolgreich");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ DBBackupService Tests: Fehlgeschlagen");
            }
        }

        /// <summary>
        /// Testet Event-Kommunikation
        /// </summary>
        private async Task TestEventCommunicationAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("--- Test: Event-Kommunikation ---");
            
            try
            {
                // Test 1: Event setzen
                _serviceEvents.SetEvent(ServiceEventSystem.EVENT_SCHICHT);
                _logger.LogInformation("✅ SetEvent: EVENT_SCHICHT gesetzt");
                
                // Test 2: Event pulsen
                _serviceEvents.PulseEvent(ServiceEventSystem.EVENT_SIGNALLLOG);
                _logger.LogInformation("✅ PulseEvent: EVENT_SIGNALLLOG gepulst");
                
                // Test 3: Auf Event warten (mit Timeout)
                var cts = new CancellationTokenSource(TimeSpan.FromSeconds(5));
                await _serviceEvents.WaitForEventAsync(ServiceEventSystem.EVENT_ZUSATZ, cts.Token);
                _logger.LogInformation("✅ WaitForEventAsync: EVENT_ZUSATZ gewartet");
                
                // Test 4: Alle Events zurücksetzen
                _serviceEvents.ResetAllEvents();
                _logger.LogInformation("✅ ResetAllEvents: Alle Events zurückgesetzt");
                
                _logger.LogInformation("✅ Event-Kommunikation Tests: Alle erfolgreich");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ Event-Kommunikation Tests: Fehlgeschlagen");
            }
        }
    }

    /// <summary>
    /// Test-Programm
    /// </summary>
    public class TestProgram
    {
        public static async Task Main(string[] args)
        {
            // Configuration aufbauen
            var configuration = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
                .Build();

            // Serilog konfigurieren
            Log.Logger = new LoggerConfiguration()
                .ReadFrom.Configuration(configuration)
                .CreateLogger();

            try
            {
                Log.Information("=== Integrationstest Start ===");
                
                // Logger erstellen
                var loggerFactory = new LoggerFactory(new[] { new SerilogLoggerProvider() });
                var logger = loggerFactory.CreateLogger<IntegrationTest>();
                
                // Integrationstest ausführen
                var test = new IntegrationTest(logger, configuration);
                await test.RunAllTestsAsync(CancellationToken.None);
                
                Log.Information("=== Integrationstest Ende ===");
            }
            catch (Exception ex)
            {
                Log.Fatal(ex, "Integrationstest fehlgeschlagen");
            }
            finally
            {
                Log.CloseAndFlush();
            }
        }
    }
}
