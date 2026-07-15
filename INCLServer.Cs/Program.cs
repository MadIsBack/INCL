using INCLUDIS.Utils.CommonDB;
using INCLUDIS.INCLServer.Cs.Services;
using INCLUDIS.INCLServer.Cs.Database;
using INCLUDIS.INCLServer.Cs.Config;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Serilog;
using System.IO;

namespace INCLUDIS.INCLServer.Cs
{
    public class Program
    {
        public static async Task Main(string[] args)
        {
            // HostBuilder erstellen
            var host = Host.CreateDefaultBuilder(args)
                .ConfigureAppConfiguration((hostingContext, config) =>
                {
                    // Basisverzeichnis setzen
                    config.SetBasePath(Directory.GetCurrentDirectory());
                    
                    // appsettings.json laden
                    config.AddJsonFile("appsettings.json", optional: false, reloadOnChange: true);
                    
                    // Kommandozeilenargumente (für DBUser, DBServer, etc.)
                    config.AddCommandLine(args);
                })
                .ConfigureServices((hostContext, services) =>
                {
                    // Konfiguration auslesen
                    var configuration = hostContext.Configuration;
                    var inclServerConfig = configuration.GetSection("INCLServer").Get<INCLServerConfig>();
                    
                    // CommonDB Factory für die Erstellung von Instanzen pro Service
                    services.AddSingleton<INCLServerConfig>(inclServerConfig);
                    
                    // CommonDB Factory: Jeder Service erhält seine eigene Instanz
                    services.AddSingleton<Func<CommonDB>>(provider => () =>
                    {
                        var config = provider.GetRequiredService<INCLServerConfig>();
                        
                        // Datenbanktyp bestimmen (Standard: MSSQL)
                        var dbType = CommonDB.DatabaseType.dtMSSQL;
                        
                        // Connection String aufbauen
                        var connectionString = $
                            "Server={config.DBServer};
                             Database={config.DBInitialCatalog};
                             User Id={config.DBUser};
                             Password={config.DBPass};";
                        
                        if (!string.IsNullOrEmpty(config.DBProvider))
                        {
                            connectionString += $"Provider={config.DBProvider};";
                        }
                        
                        return new CommonDB(dbType, connectionString);
                    });
                    
                    // TPM (Statistikfunktionen) als Singleton registrieren
                    services.AddSingleton<TPM>(provider =>
                    {
                        var dbFactory = provider.GetRequiredService<Func<CommonDB>>();
                        return new TPM(dbFactory);
                    });
                    
                    // MainService als Singleton registrieren, damit andere Services darauf zugreifen können
                    services.AddSingleton<MainService>();
                    
                    // Services registrieren
                    services.AddHostedService<MainService>(provider =>
                    {
                        var logger = provider.GetService<ILogger<MainService>>();
                        var tpm = provider.GetRequiredService<TPM>();
                        var dbFactory = provider.GetRequiredService<Func<CommonDB>>();
                        var config = provider.GetRequiredService<INCLServerConfig>();
                        return new MainService(logger, tpm, dbFactory, config);
                    });
                    services.AddHostedService<SchichtService>();
                    services.AddHostedService<ZusatzService>();
                    services.AddHostedService<SignalLogService>();
                    services.AddHostedService<DBBackupService>();
                })
                .UseSerilog((hostingContext, services, configuration) =>
                {
                    var inclServerConfig = hostingContext.Configuration.GetSection("INCLServer").Get<INCLServerConfig>();
                    var dbUser = inclServerConfig?.DBUser ?? "includis";
                    var logDir = Path.Combine(inclServerConfig?.INCLUDIS_HOME ?? "D:\\comtas\\", inclServerConfig?.LogSettings?.LogDirectory ?? "LOG");
                    
                    // Verzeichnis erstellen, falls nicht vorhanden
                    Directory.CreateDirectory(logDir);
                    
                    // Serilog Konfiguration für mandantenspezifische Logs
                    configuration
                        .MinimumLevel.Information()
                        .Enrich.FromLogContext()
                        .WriteTo.Console()
                        .WriteTo.File(
                            path: Path.Combine(logDir, $"svc_{dbUser.ToLower()}_trace.log"),
                            rollingInterval: Serilog.RollingInterval.Day,
                            fileSizeLimitBytes: (inclServerConfig?.LogSettings?.MaxFileSizeMB ?? 4) * 1024 * 1024,
                            retainedFileCountLimit: inclServerConfig?.LogSettings?.RetainedFileCount ?? 7,
                            outputTemplate: "{Timestamp:yyyy-MM-dd HH:mm:ss} - {Message:lj}{NewLine}{Exception}");
                })
                .Build();

            // Host starten
            await host.RunAsync();
        }
    }
}
