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
    public class MainService : BackgroundService
    {
        private readonly ILogger<MainService> _logger;
        private readonly IConfiguration _configuration;
        private readonly AppConfig _appConfig;
        private CommonDB _database;
        private bool _lastDBConnectStatus = true;
        private bool _s7MainOK = true;
        private string _dbUser = "includis";
        private string _dbServer = "db";
        private string _dbPass = "comtas";
        private string _dbInitialCatalog = "includis";
        private string _dbProvider = string.Empty;
        private string _includisHome = string.Empty;
        private readonly object _logLock = new object();

        public MainService(ILogger<MainService> logger, IConfiguration configuration)
        {
            _logger = logger;
            _configuration = configuration;
            
            // Konfiguration laden
            _appConfig = new AppConfig();
            _configuration.GetSection("Database").Bind(_appConfig.Database);
            _configuration.GetSection("Main").Bind(_appConfig.Main);
            
            SetDBUser();
            _includisHome = _appConfig.Main.Home;
        }

        private void SetDBUser()
        {
            // DB-Parameter aus Konfiguration oder Command-Line-Argumenten
            // Command-Line-Argumente haben Vorrang
            var args = Environment.GetCommandLineArgs();
            
            for (int i = 0; i < args.Length; i++)
            {
                var arg = args[i].ToUpper();
                if (arg.StartsWith("DBUSER="))
                    _dbUser = arg.Substring("DBUSER=".Length).Trim();
                else if (arg.StartsWith("DBPASS="))
                    _dbPass = arg.Substring("DBPASS=".Length).Trim();
                else if (arg.StartsWith("DBSERVER="))
                    _dbServer = arg.Substring("DBSERVER=".Length).Trim();
            }

            // Falls nicht gesetzt, Default-Werte verwenden
            if (string.IsNullOrEmpty(_dbUser))
                _dbUser = _appConfig.Database.DB_User;
            
            if (string.IsNullOrEmpty(_dbPass))
                _dbPass = _appConfig.Database.DB_Pass;
                
            if (string.IsNullOrEmpty(_dbServer))
                _dbServer = _appConfig.Database.DB_Server;
            
            if (string.IsNullOrEmpty(_dbInitialCatalog))
                _dbInitialCatalog = _appConfig.Database.InitialCatalog;
            
            if (string.IsNullOrEmpty(_dbProvider))
                _dbProvider = _appConfig.Database.Provider;

            _dbUser = _dbUser.ToUpper();
            
            // INCLUDIS_HOME aus Konfiguration
            if (string.IsNullOrEmpty(_includisHome))
                _includisHome = _appConfig.Main.Home;
        }

        private bool CheckDBConnection()
        {
            _logger.LogInformation("Check connect.");
            
            try
            {
                _database = new CommonDB
                {
                    UserName = _dbUser,
                    Password = _dbPass,
                    Server = _dbServer,
                    InitialCatalog = _dbInitialCatalog,
                    SqlProvider = _dbProvider
                };
                
                _logger.LogInformation("Using {User}@{Server} ({Catalog}) - Provider:{Provider}",
                    _dbUser, _dbServer, _dbInitialCatalog, _dbProvider);
                
                _database.Connected = true;
                
                if (_database.Connected)
                {
                    _logger.LogInformation("Connect Ok.");
                    return true;
                }
                else
                {
                    _logger.LogInformation("Connect failed.");
                    return false;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Database connection check failed");
                return false;
            }
        }

        private void WriteMessage(string message, int mode = 0)
        {
            // Log-Modus:
            // 0 = trace, 1 = timer, 2 = shift, 3 = addons, 4 = recalc, 5 = memory, 6 = down, 7 = memdbg
            string logFile = mode switch
            {
                0 => "svc_" + _dbUser.ToLower() + "_trace.log",
                1 => "svc_" + _dbUser.ToLower() + "_timer.log",
                2 => "svc_" + _dbUser.ToLower() + "_shift.log",
                3 => "svc_" + _dbUser.ToLower() + "_addons.log",
                4 => "svc_" + _dbUser.ToLower() + "_recalc.log",
                5 => "svc_" + _dbUser.ToLower() + "_memory.log",
                6 => "svc_" + _dbUser.ToLower() + "_down.log",
                7 => "svc_" + _dbUser.ToLower() + "_memdbg.log",
                _ => "svc_" + _dbUser.ToLower() + "_trace.log"
            };

            var logDir = Path.Combine(_includisHome, "LOG");
            if (!Directory.Exists(logDir))
                Directory.CreateDirectory(logDir);

            var logPath = Path.Combine(logDir, logFile);
            const long maxFileSize = 4 * 1024 * 1024;

            lock (_logLock)
            {
                if (File.Exists(logPath))
                {
                    var fileInfo = new FileInfo(logPath);
                    if (fileInfo.Length > maxFileSize)
                        File.Delete(logPath);
                }
                File.AppendAllText(logPath, $"{DateTime.Now:yyyy-MM-dd HH:mm:ss} : {message}{Environment.NewLine}");
            }

            switch (mode)
            {
                case 0: _logger.LogInformation(message); break;
                case 1: _logger.LogDebug(message); break;
                case 2: _logger.LogInformation(message); break;
                case 3: _logger.LogInformation(message); break;
                case 4: _logger.LogInformation(message); break;
                case 5: _logger.LogWarning(message); break;
                case 6: _logger.LogError(message); break;
                case 7: _logger.LogTrace(message); break;
            }
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            WriteMessage("Service started", 0);

            try
            {
                // Datenbankverbindung prüfen und herstellen
                while ((_database == null || !_database.Connected) && !stoppingToken.IsCancellationRequested)
                {
                    if (CheckDBConnection())
                    {
                        try
                        {
                            WriteMessage("Connected.", 0);
                            if (_database != null)
                                _database.Connected = false;
                            
                            _database = new CommonDB
                            {
                                UserName = _dbUser,
                                Password = _dbPass,
                                Server = _dbServer,
                                InitialCatalog = _dbInitialCatalog,
                                SqlProvider = _dbProvider
                            };
                            _database.Connected = true;
                        }
                        catch (Exception ex)
                        {
                            WriteMessage("Error connecting: " + ex.Message, 0);
                        }
                    }

                    if (_database == null || !_database.Connected)
                    {
                        if (_lastDBConnectStatus)
                        {
                            _lastDBConnectStatus = false;
                            WriteMessage("Database not available.", 0);
                        }
                    }
                    else
                    {
                        if (!_lastDBConnectStatus)
                            _lastDBConnectStatus = true;
                    }

                    if ((_database == null || !_database.Connected) && !stoppingToken.IsCancellationRequested)
                    {
                        WriteMessage("Wait 30 sec.", 0);
                        await Task.Delay(30000, stoppingToken);
                    }
                }

                if (stoppingToken.IsCancellationRequested)
                    return;

                WriteMessage("Database connection successfully... Start program...", 0);

                // Hier würden die anderen Services gestartet werden
                // In .NET Core werden die Services automatisch vom Host gestartet
                // Wir müssen nur warten, bis der Host alle Services gestartet hat
                while (!stoppingToken.IsCancellationRequested)
                {
                    // Hauptschleife - einfach warten
                    await Task.Delay(1000, stoppingToken);
                }
            }
            catch (Exception ex)
            {
                WriteMessage("Error in ServiceExecute: " + ex.Message, 0);
            }
        }

        public override async Task StopAsync(CancellationToken cancellationToken)
        {
            WriteMessage("Service Stop...", 0);
            try
            {
                if (_database != null && _database.Connected)
                    _database.Connected = false;
            }
            catch (Exception ex)
            {
                WriteMessage("Error stopping database: " + ex.Message, 0);
            }
            await base.StopAsync(cancellationToken);
        }
    }
}
