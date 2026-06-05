using INCLService.Database;
using INCLService.Config;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using System.Collections;

namespace INCLService.Services;

public class SignalClass
{
    public int SignalNr { get; set; }
    public int Nr { get; set; }
    public int MaschNr { get; set; }
    public string Istwert { get; set; } = string.Empty;
    public string Oldwert { get; set; } = string.Empty;
    public int Oldlognr { get; set; }
}

public class SignalLogService : BackgroundService
{
    private readonly CommonDB _db;
    private readonly ILogger<SignalLogService> _logger;
    private readonly SQLFunctions _sqlFunctions;
    private ArrayList _entryList = new ArrayList();

    public SignalLogService(
        CommonDB db,
        ILogger<SignalLogService> logger,
        SQLFunctions sqlFunctions)
    {
        _db = db;
        _logger = logger;
        _sqlFunctions = sqlFunctions;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("SignalLogService gestartet");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                _logger.LogInformation("SignalLogService läuft...");
                await Task.Delay(60000, stoppingToken); // Alle 60 Sekunden
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Fehler im SignalLogService: {Message}", ex.Message);
            }
        }

        _logger.LogInformation("SignalLogService beendet");
    }

    private string FloatToPunktStr(double aFloat)
    {
        return aFloat.ToString("0.0000", System.Globalization.CultureInfo.InvariantCulture);
    }

    private SignalClass GetSignalByNumbers(int aMaschnr, int aSignalNr)
    {
        _logger.LogInformation("Signal für Maschine {MaschNr} und SignalNr {SignalNr} wird abgefragt", aMaschnr, aSignalNr);
        return new SignalClass { MaschNr = aMaschnr, SignalNr = aSignalNr };
    }

    private SignalClass GetSignalBySeqNumber(int aNr)
    {
        _logger.LogInformation("Signal für Sequenznummer {Nr} wird abgefragt", aNr);
        return new SignalClass { Nr = aNr };
    }
}
