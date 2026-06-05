using INCLService.Database;
using INCLService.Services;
using INCLService.Config;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;

var host = Host.CreateDefaultBuilder(args)
    .ConfigureAppConfiguration((hostingContext, config) =>
    {
        config.SetBasePath(Directory.GetCurrentDirectory());
        config.AddJsonFile("appsettings.json", optional: false, reloadOnChange: true);
    })
    .ConfigureServices((context, services) =>
    {
        // Configuration
        var configuration = context.Configuration;
        services.Configure<DatabaseConfig>(configuration.GetSection("Database"));
        services.Configure<ShiftSettings>(configuration.GetSection("ShiftSettings"));
        services.Configure<ServiceSettings>(configuration.GetSection("ServiceSettings"));

        // CommonDB initialisieren
        var dbConfig = configuration.GetSection("Database");
        var commonDb = new CommonDB(
            dbConfig["Provider"],
            dbConfig["ConnectionString"]
        );
        services.AddSingleton<CommonDB>(commonDb);

        // Hintergrunddienste registrieren
        services.AddHostedService<SchichtService>();
        services.AddHostedService<ZusatzService>();
        services.AddHostedService<DBBackupService>();
        services.AddHostedService<SignalLogService>();

        // Utilities und Manager
        services.AddSingleton<DatabaseManager>();
        services.AddSingleton<SQLFunctions>();
        services.AddSingleton<Arbeit>();
    })
    .ConfigureLogging(logging =>
    {
        logging.ClearProviders();
        logging.AddConsole();
    })
    .Build();

await host.RunAsync();
