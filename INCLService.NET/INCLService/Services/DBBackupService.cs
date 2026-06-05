using INCLService.Database;
using INCLService.Config;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Microsoft.Win32;

namespace INCLService.Services;

public class DBBackupService : BackgroundService
{
    private readonly CommonDB _db;
    private readonly ILogger<DBBackupService> _logger;

    public DBBackupService(CommonDB db, ILogger<DBBackupService> logger)
    {
        _db = db;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("DBBackupService gestartet");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                _logger.LogInformation("Warte auf Backup-Event...");
                await Task.Delay(3600000, stoppingToken); // Alle 60 Minuten prüfen

                if (stoppingToken.IsCancellationRequested)
                {
                    _logger.LogInformation("DBBackupService beendet - Abbruch angefordert");
                    break;
                }

                if (ProceedBackup())
                {
                    _logger.LogInformation("Backup wurde erstellt");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Fehler im DBBackupService: {Message}", ex.Message);
            }
        }

        _logger.LogInformation("DBBackupService beendet");
    }

    private bool ProceedBackup()
    {
        _logger.LogInformation("Prüfe, ob Backup durchgeführt werden muss...");
        // Hier die Logik einfügen, ob ein Backup durchgeführt werden soll
        return true;
    }

    private string GetBackupAppl()
    {
        _logger.LogInformation("Backup-Anwendung wird abgefragt...");
        // Hier die Backup-Anwendung aus der Registry oder Konfiguration abfragen
        return "backup_app.exe";
    }

    private DateTime GetCronNextRun(string aMinute, string aStunde, string aMonatstag, string aMonat, string aWochentag)
    {
        _logger.LogInformation("Nächste Cron-Ausführung wird berechnet...");
        // Hier die Logik für die nächste Cron-Ausführung einfügen
        return DateTime.Now.AddHours(1);
    }
}
