using INCLService.CSharp.Models;
using INCLService.CSharp.Services;
using INCLService.CSharp.Utilities;
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

            // Serilog konfigurieren mit mandanten-spezifischen Logs
            // DB_User aus Konfiguration oder Command-Line-Argumenten extrahieren
            string dbUser = configuration.GetValue<string>("Database:DB_User", "INCLUDIS").ToUpper();
            var cmdArgs = Environment.GetCommandLineArgs();
            for (int i = 0; i < cmdArgs.Length; i++)
            {
                var arg = cmdArgs[i].ToUpper();
                if (arg.StartsWith("DBUSER="))
                    dbUser = arg.Substring("DBUSER=".Length).Trim().ToUpper();
            }
            
            Log.Logger = new LoggerConfiguration()
                .ReadFrom.Configuration(configuration)
                .Enrich.FromLogContext()
                .Enrich.WithProperty("DBUser", dbUser)
                .CreateLogger();

            try
            {
                Log.Information("Starting INCL Service for user {DBUser}...", dbUser);

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

                        // ServiceEventSystem als Singleton registrieren
                        // Dies ermglicht die Kommunikation zwischen den Services
                        services.AddSingleton<ServiceEventSystem>();

                        // Services registrieren
                        // Jeder Service erstellt seine eigene CommonDB-Instanz
                        services.AddHostedService<MainService>();
                        services.AddHostedService<S7MainService>();
                        services.AddHostedService<ShiftService>();
                        services.AddHostedService<DBBackupService>();
                        services.AddHostedService<SignalLogService>();
                        services.AddHostedService<AdditionalService>();
                        
                        // DatenService als Singleton registrieren (wird von mehreren Services genutzt)
                        services.AddSingleton<DatenService>();
                        services.AddHostedService<CCCService>();

                        // S7MainServiceCCC als Singleton registrieren (wird von S7MainService genutzt)
                        services.AddSingleton<S7MainServiceCCC>();
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
