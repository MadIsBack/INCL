using INCLUDIS.Utils.CommonDB;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;

namespace INCLUDIS.INCLServer.Cs.Services
{
    /// <summary>
    /// Service für die Protokollierung von Signaländerungen.
    /// Ersatz für TThread_SignalLog aus Delphi.
    /// </summary>
    public class SignalLogService : BackgroundService
    {
        private readonly ILogger<SignalLogService> _logger;
        private readonly Func<CommonDB> _dbFactory;
        private readonly INCLServerConfig _config;
        
        // Liste der Signale, die protokolliert werden sollen
        private readonly List<SignalClass> _signalList = new();
        private readonly object _signalLock = new object();
        
        // Status-Flags
        private bool _protokollierungAktiv = false;
        private int _errorCount = 0;

        public SignalLogService(
            ILogger<SignalLogService> logger,
            Func<CommonDB> dbFactory,
            INCLServerConfig config)
        {
            _logger = logger;
            _dbFactory = dbFactory;
            _config = config;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("SignalLogService gestartet.");

            // Initialisierung: Signale laden
            await LadeSignale(stoppingToken);

            // Hauptschleife
            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    // Signaländerungen protokollieren
                    await ProtokolliereSignalAenderungen(stoppingToken);

                    // Wartezeit aus der Konfiguration
                    var interval = _config.ThreadSettings.SignalLogService.IntervalSeconds;
                    await Task.Delay(interval * 1000, stoppingToken);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Fehler im SignalLogService");
                    _errorCount++;
                    
                    if (_errorCount > 5)
                    {
                        _logger.LogError("Zu viele Fehler im SignalLogService. Warte 60 Sekunden...");
                        await Task.Delay(60000, stoppingToken);
                        _errorCount = 0;
                    }
                    else
                    {
                        await Task.Delay(10000, stoppingToken);
                    }
                }
            }

            _logger.LogInformation("SignalLogService wird beendet.");
        }

        /// <summary>
        /// Lädt die zu protokollierenden Signale aus der Datenbank.
        /// </summary>
        private async Task LadeSignale(CancellationToken stoppingToken)
        {
            try
            {
                using var db = _dbFactory();
                _logger.LogInformation("Lade Signale aus der Datenbank...");
                
                // Signale abrufen, die protokolliert werden sollen
                using var reader = db.GetReader(@"
                    SELECT sm.nr, sm.maschnr, s.signalnr, sm.istwert 
                    FROM signale s 
                    LEFT JOIN signal_maschine sm ON sm.signalnr = s.signalnr 
                    WHERE s.logit = 1 OR s.signalart = 24
                ");
                
                lock (_signalLock)
                {
                    _signalList.Clear();
                    
                    while (reader.Read())
                    {
                        var signal = new SignalClass
                        {
                            Nr = reader.GetInt32("nr"),
                            MaschNr = reader.GetInt32("maschnr"),
                            SignalNr = reader.GetInt32("signalnr"),
                            Istwert = reader.GetString("istwert")
                        };
                        
                        _signalList.Add(signal);
                        _logger.LogDebug("Signal geladen: Maschine {MaschNr}, Signal {SignalNr}, Wert: {Istwert}", signal.MaschNr, signal.SignalNr, signal.Istwert);
                    }
                }
                
                _logger.LogInformation("{SignalCount} Signale geladen.", _signalList.Count);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Fehler beim Laden der Signale.");
            }
        }

        /// <summary>
        /// Protokolliert Signaländerungen.
        /// </summary>
        private async Task ProtokolliereSignalAenderungen(CancellationToken stoppingToken)
        {
            if (_protokollierungAktiv)
                return;

            _protokollierungAktiv = true;
            
            try
            {
                using var db = _dbFactory();
                _logger.LogInformation("Protokolliere Signaländerungen...");
                
                // Aktuelle Signalwerte abrufen
                using var reader = db.GetReader(@"
                    SELECT sm.nr, sm.maschnr, s.signalnr, sm.istwert 
                    FROM signale s 
                    LEFT JOIN signal_maschine sm ON sm.signalnr = s.signalnr 
                    WHERE s.logit = 1 OR s.signalart = 24
                ");
                
                lock (_signalLock)
                {
                    while (reader.Read())
                    {
                        var maschNr = reader.GetInt32("maschnr");
                        var signalNr = reader.GetInt32("signalnr");
                        var neuerWert = reader.GetString("istwert");
                        
                        // Signal in der Liste suchen
                        var signal = _signalList.Find(s => s.MaschNr == maschNr && s.SignalNr == signalNr);
                        
                        if (signal != null)
                        {
                            // Prüfen, ob sich der Wert geändert hat
                            if (signal.Istwert != neuerWert)
                            {
                                _logger.LogDebug("Signaländerung: Maschine {MaschNr}, Signal {SignalNr}, Alt: {OldWert}, Neu: {NeuerWert}", maschNr, signalNr, signal.Istwert, neuerWert);
                                
                                // Signaländerung in der Datenbank protokollieren
                                ProtokolliereSignalAenderung(db, maschNr, signalNr, signal.Istwert, neuerWert);
                                
                                // Wert in der Liste aktualisieren
                                signal.Istwert = neuerWert;
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Fehler beim Protokollieren der Signaländerungen.");
            }
            finally
            {
                _protokollierungAktiv = false;
            }
        }

        /// <summary>
        /// Protokolliert eine Signaländerung in der Datenbank.
        /// </summary>
        private void ProtokolliereSignalAenderung(CommonDB db, int maschNr, int signalNr, string alterWert, string neuerWert)
        {
            try
            {
                var sql = @"
                    INSERT INTO SignalProtokoll (MaschNr, SignalNr, AlterWert, NeuerWert, AenderungsZeit) 
                    VALUES (@MaschNr, @SignalNr, @AlterWert, @NeuerWert, @AenderungsZeit)";
                
                db.ExecuteNonQuery(sql, new { MaschNr = maschNr, SignalNr = signalNr, AlterWert = alterWert, NeuerWert = neuerWert, AenderungsZeit = DateTime.Now });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Fehler beim Protokollieren der Signaländerung für Maschine {MaschNr}, Signal {SignalNr}", maschNr, signalNr);
            }
        }

        public override async Task StopAsync(CancellationToken cancellationToken)
        {
            _logger.LogInformation("SignalLogService wird beendet...");
            await base.StopAsync(cancellationToken);
        }
    }

    /// <summary>
    /// Klasse für Signalinformationen.
    /// </summary>
    public class SignalClass
    {
        public int Nr { get; set; }
        public int MaschNr { get; set; }
        public int SignalNr { get; set; }
        public string Istwert { get; set; } = string.Empty;
    }
}
