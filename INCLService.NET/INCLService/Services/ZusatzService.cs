using INCLService.Database;
using INCLService.Config;
using INCLService.Utilities;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace INCLService.Services;

public class ZusatzService : BackgroundService
{
    private readonly CommonDB _db;
    private readonly ILogger<ZusatzService> _logger;
    private readonly SQLFunctions _sqlFunctions;
    private readonly Arbeit _arbeit;

    public ZusatzService(
        CommonDB db,
        ILogger<ZusatzService> logger,
        SQLFunctions sqlFunctions,
        Arbeit arbeit)
    {
        _db = db;
        _logger = logger;
        _sqlFunctions = sqlFunctions;
        _arbeit = arbeit;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("ZusatzService gestartet");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                _logger.LogInformation("ZusatzService läuft...");
                await Task.Delay(60000, stoppingToken); // Alle 60 Sekunden
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Fehler im ZusatzService: {Message}", ex.Message);
            }
        }

        _logger.LogInformation("ZusatzService beendet");
    }

    public void StartProgramme()
    {
        _logger.LogInformation("StartProgramme wird ausgeführt");
    }

    public void CalcPackedlogFromShiftlog()
    {
        _logger.LogInformation("CalcPackedlogFromShiftlog wird ausgeführt");
    }

    public void CalcPackedlogFromShiftlog(DateTime fromDate)
    {
        _logger.LogInformation("CalcPackedlogFromShiftlog mit Datum {FromDate} wird ausgeführt", fromDate);
    }

    public void Book_Short_Delay()
    {
        _logger.LogInformation("Book_Short_Delay wird ausgeführt");
    }

    public void CheckRuestProt_Stillog()
    {
        _logger.LogInformation("CheckRuestProt_Stillog wird ausgeführt");
    }

    public void Laufzeit_Berechnen()
    {
        _logger.LogInformation("Laufzeit_Berechnen wird ausgeführt");
    }

    public void Job_No_to_Downtime_Log()
    {
        _logger.LogInformation("Job_No_to_Downtime_Log wird ausgeführt");
    }

    public void CheckVerpacktProt()
    {
        _logger.LogInformation("CheckVerpacktProt wird ausgeführt");
    }

    public int CheckPackSchicht(int aTage)
    {
        _logger.LogInformation("CheckPackSchicht mit {ATage} Tagen wird ausgeführt", aTage);
        return 0;
    }

    public void ArbeitsFrei_Buchen()
    {
        _logger.LogInformation("ArbeitsFrei_Buchen wird ausgeführt");
    }

    public void Taktzeit_Personal()
    {
        _logger.LogInformation("Taktzeit_Personal wird ausgeführt");
    }

    public void TaktMitteln(bool aUpdate)
    {
        _logger.LogInformation("TaktMitteln mit Update={AUpdate} wird ausgeführt", aUpdate);
    }

    public void UnscheduledSetup()
    {
        _logger.LogInformation("UnscheduledSetup wird ausgeführt");
    }

    public void CheckSollstueck()
    {
        _logger.LogInformation("CheckSollstueck wird ausgeführt");
    }

    public void CheckWzWartungen()
    {
        _logger.LogInformation("CheckWzWartungen wird ausgeführt");
    }

    public void CheckAuftragKette()
    {
        _logger.LogInformation("CheckAuftragKette wird ausgeführt");
    }

    public void Reschedule()
    {
        _logger.LogInformation("Reschedule wird ausgeführt");
    }

    public void BerechnenEndeausIst()
    {
        _logger.LogInformation("BerechnenEndeausIst wird ausgeführt");
    }

    public bool Laufende_Auftraege_Terminieren()
    {
        _logger.LogInformation("Laufende_Auftraege_Terminieren wird ausgeführt");
        return true;
    }

    public bool Autoterminierung()
    {
        _logger.LogInformation("Autoterminierung wird ausgeführt");
        return true;
    }

    public void Laufzeit_Berechnen2()
    {
        _logger.LogInformation("Laufzeit_Berechnen2 wird ausgeführt");
    }

    public void Status_Beschreibung()
    {
        _logger.LogInformation("Status_Beschreibung wird ausgeführt");
    }

    public void PlanListeReportParameterSchreiben(string par, string val)
    {
        _logger.LogInformation("PlanListeReportParameterSchreiben mit Par={Par}, Val={Val} wird ausgeführt", par, val);
    }
}
