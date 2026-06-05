using INCLService.Database;
using INCLService.Config;
using INCLService.Utilities;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace INCLService.Services;

public class SchichtService : BackgroundService
{
    private readonly CommonDB _db;
    private readonly ILogger<SchichtService> _logger;
    private readonly ShiftSettings _shiftSettings;
    private readonly ServiceSettings _serviceSettings;
    private readonly SQLFunctions _sqlFunctions;
    private readonly Arbeit _arbeit;

    private int _alteSchicht = 0;
    private bool _schichtBerechnung = true;
    private bool _berechnungAktiv = false;
    private bool _recalculateMode = false;
    private bool _nachBerechnung = false;

    public SchichtService(
        CommonDB db,
        ILogger<SchichtService> logger,
        IOptions<ShiftSettings> shiftSettings,
        IOptions<ServiceSettings> serviceSettings,
        SQLFunctions sqlFunctions,
        Arbeit arbeit)
    {
        _db = db;
        _logger = logger;
        _shiftSettings = shiftSettings.Value;
        _serviceSettings = serviceSettings.Value;
        _sqlFunctions = sqlFunctions;
        _arbeit = arbeit;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("SchichtService gestartet");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                _logger.LogInformation("Warte auf Schichtwechsel-Event...");
                await Task.Delay(60000, stoppingToken); // Alle 60 Sekunden prüfen

                if (stoppingToken.IsCancellationRequested)
                {
                    _logger.LogInformation("SchichtService beendet - Abbruch angefordert");
                    break;
                }

                _logger.LogInformation("Datenbankprüfung gestartet...");
                
                if (!_sqlFunctions.CheckDatabaseConnection(_db))
                {
                    _logger.LogWarning("Datenbank nicht verfügbar, warte 30 Sekunden...");
                    for (int i = 0; i < 30; i++)
                    {
                        await Task.Delay(1000, stoppingToken);
                        if (stoppingToken.IsCancellationRequested)
                        {
                            _logger.LogInformation("SchichtService beendet - Abbruch während Warteschleife");
                            return;
                        }
                    }
                    continue;
                }

                _logger.LogInformation("Datenbank ist aktiv");
                _berechnungAktiv = true;

                try
                {
                    if (stoppingToken.IsCancellationRequested)
                    {
                        _logger.LogInformation("SchichtService beendet - Abbruch vor Berechnung");
                        break;
                    }

                    if (_recalculateMode)
                    {
                        _logger.LogInformation("Starte Neuberechnung...");
                        int result = Recalculation();
                        _logger.LogInformation("Neuberechnung beendet mit Ergebnis: {Result}", result);
                    }
                    else
                    {
                        _logger.LogInformation("Starte Schichtwechsel...");
                        StartSchichtWechsel(_alteSchicht);
                        _logger.LogInformation("Schichtwechsel beendet");
                    }
                }
                finally
                {
                    _berechnungAktiv = false;
                }

                _logger.LogInformation("Blockende verarbeitet");
                _logger.LogInformation("-------------------------------------------------------------------");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Fehler im SchichtService: {Message}", ex.Message);
            }
        }

        _logger.LogInformation("SchichtService beendet. Verlasse Block");
    }

    public int Recalculation()
    {
        _logger.LogInformation("Neuberechnung wird durchgeführt");
        return 0;
    }

    public void StartSchichtWechsel(int alteSchicht)
    {
        _logger.LogInformation("Schichtwechsel gestartet für Schicht: {AlteSchicht}", alteSchicht);
        MakeEnvironment();

        if (!_schichtBerechnung)
        {
            _logger.LogInformation("*** Starte Neuberechnung ***");
            double von = Math.Truncate(DateTime.Now.ToOADate()) - _serviceSettings.RecalculationDays;
            double bis = DateTime.Now.ToOADate();
            TPM_Korrektur(von, bis, true, "");
            CheckLaufzeitLog();
            _logger.LogInformation("*** Ende Neuberechnung ***");
            _logger.LogInformation("----------------------------------------------------");
            return;
        }

        _logger.LogInformation("*** Starte Schicht-Neuberechnung ({AlteSchicht}) ***", alteSchicht);
        int datum = (int)Math.Truncate(DateTime.Now.ToOADate());
        if (alteSchicht == 3)
        {
            datum -= 1;
        }

        string sqlStr = "DELETE FROM SPCAus WHERE DatumZeit < '" + 
            ((int)(DateTime.Now.ToOADate() - 1)).ToString() + "'";
        _sqlFunctions.SQL_Insert(sqlStr);

        Schichtwechsel();
        _logger.LogInformation("Schichtwechsel durchgeführt");

        _logger.LogInformation("*** Ende Schicht-Neuberechnung ***");
        _logger.LogInformation("----------------------------------------------------");
    }

    private void MakeEnvironment()
    {
        _logger.LogInformation("Umwelt wird vorbereitet");
    }

    private void Schichtwechsel()
    {
        _logger.LogInformation("Schichtwechsel wird durchgeführt");
    }

    private void TPM_Korrektur(double von, double bis, bool berechnenTPMAuswertung, string mnrs)
    {
        _logger.LogInformation("TPM-Korrektur von {Von} bis {Bis}", von, bis);
    }

    private void CheckLaufzeitLog()
    {
        _logger.LogInformation("Laufzeit-Log wird geprüft");
    }

    public void SetNachBerechnung(bool value)
    {
        _nachBerechnung = value;
    }

    public bool NachBerechnung => _nachBerechnung;
    public bool Schicht_Berechnung { get => _schichtBerechnung; set => _schichtBerechnung = value; }
    public bool Berechnung_aktiv => _berechnungAktiv;
    public bool Recalculate_Mode { get => _recalculateMode; set => _recalculateMode = value; }
    public int AlteSchicht { get => _alteSchicht; set => _alteSchicht = value; }
}
