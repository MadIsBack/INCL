using INCLService.CSharp.Models;
using INCLService.CSharp.Services;
using INCLUDIS.Utils.CommonDB;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Serilog;
using System;
using System.IO;
using System.Threading.Tasks;

namespace INCLService.CSharp
{
    public class Program
    {
        public static async Task Main(string[] args)
        {
            // Configuration aufbauen
            var configuration = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
                .AddCommandLine(args)
                .Build();

            // Serilog konfigurieren
            Log.Logger = new LoggerConfiguration()
                .ReadFrom.Configuration(configuration)
                .CreateLogger();

            try
            {
                Log.Information("Starting INCL Service...");

                var host = Host.CreateDefaultBuilder(args)
                    .ConfigureAppConfiguration((hostingContext, config) =>
                    {
                        config.AddConfiguration(configuration);
                    })
                    .ConfigureServices((hostContext, services) =>
                    {
                        // Configuration registrieren
                        services.AddSingleton<IConfiguration>(hostContext.Configuration);

                        // Logging konfigurieren
                        services.AddLogging(loggingBuilder =>
                        {
                            loggingBuilder.ClearProviders();
                            loggingBuilder.AddSerilog();
                        });

                        // CommonDB Instanz erstellen und registrieren
                        var appConfig = new AppConfig();
                        hostContext.Configuration.GetSection("Database").Bind(appConfig.Database);
                        hostContext.Configuration.GetSection("Main").Bind(appConfig.Main);
                        
                        var commonDb = new CommonDB
                        {
                            UserName = appConfig.Database.DB_User,
                            Password = appConfig.Database.DB_Pass,
                            Server = appConfig.Database.DB_Server,
                            InitialCatalog = appConfig.Database.InitialCatalog,
                            SqlProvider = appConfig.Database.Provider
                        };
                        
                        services.AddSingleton<CommonDB>(commonDb);

                        // Services registrieren
                        services.AddHostedService<MainService>();
                        services.AddHostedService<S7MainService>();
                        services.AddHostedService<ShiftService>();
                        services.AddHostedService<DBBackupService>();
                        services.AddHostedService<SignalLogService>();
                        services.AddHostedService<AdditionalService>();
                    })
                    .UseSerilog()
                    .Build();

                await host.RunAsync();
            }
            catch (Exception ex)
            {
                Log.Fatal(ex, "Service terminated unexpectedly");
            }
            finally
            {
                Log.CloseAndFlush();
            }
        }
    }
}
