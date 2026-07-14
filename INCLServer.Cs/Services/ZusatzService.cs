using INCLUDIS.Utils.CommonDB;
using INCLUDIS.INCLServer.Cs.Database;
using INCLUDIS.INCLServer.Cs.Utilities;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using System;
using System.Threading;
using System.Threading.Tasks;

namespace INCLUDIS.INCLServer.Cs.Services
{
    /// <summary>
    /// Service für zusätzliche Berechnungen.
    /// Ersatz für TThread_Zusatz aus Delphi.
    /// </summary>
    public class ZusatzService : BackgroundService
    {
        private readonly ILogger<ZusatzService> _logger;
        private readonly TPM _tpm;
        private readonly Func<CommonDB> _dbFactory;
        private readonly INCLServerConfig _config;
        
        // Status-Flags
        private bool _berechnungAktiv = false;
        private int _errorCount = 0;
        private DateTime _lastDate = DateTime.MinValue;

        public ZusatzService(
            ILogger<ZusatzService> logger,
            TPM tpm,
            Func<CommonDB> dbFactory,
            INCLServerConfig config)
        {
            _logger = logger;
            _tpm = tpm;
            _dbFactory = dbFactory;
            _config = config;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("ZusatzService gestartet.");

            // Initialisierung
            await InitialisiereZusatzDaten(stoppingToken);

            // Hauptschleife
            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    // Regelmäßige Aufgaben ausführen
                    await FuehreZusatzBerechnungenAus(stoppingToken);

                    // Wartezeit aus der Konfiguration
                    var interval = _config.ThreadSettings.ZusatzService.IntervalSeconds;
                    await Task.Delay(interval * 1000, stoppingToken);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Fehler im ZusatzService");
                    _errorCount++;
                    
                    if (_errorCount > 5)
                    {
                        _logger.LogError("Zu viele Fehler im ZusatzService. Warte 60 Sekunden...");
                        await Task.Delay(60000, stoppingToken);
                        _errorCount = 0;
                    }
                    else
                    {
                        await Task.Delay(10000, stoppingToken);
                    }
                }
            }

            _logger.LogInformation("ZusatzService wird beendet.");
        }

        /// <summary>
        /// Initialisiert die Zusatzdaten.
        /// </summary>
        private async Task InitialisiereZusatzDaten(CancellationToken stoppingToken)
        {
            try
            {
                using var db = _dbFactory();
                _logger.LogInformation("Initialisiere Zusatzdaten...");
                
                // Aufträge laden
                ArbeitHelper.LoadAufträge(db);
                
                // Letztes Berechnungsdatum abrufen
                using var reader = db.GetReader("SELECT TOP 1 BerechnungsDatum FROM ZusatzBerechnungen ORDER BY Id DESC");
                if (reader.Read())
                {
                    _lastDate = reader.GetDateTime("BerechnungsDatum");
                    _logger.LogInformation("Letztes Berechnungsdatum: {LastDate}", _lastDate);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Fehler bei der Initialisierung der Zusatzdaten.");
            }
        }

        /// <summary>
        /// Führt zusätzliche Berechnungen aus.
        /// </summary>
        private async Task FuehreZusatzBerechnungenAus(CancellationToken stoppingToken)
        {
            if (_berechnungAktiv)
                return;

            _berechnungAktiv = true;
            
            try
            {
                using var db = _dbFactory();
                _logger.LogInformation("Führe zusätzliche Berechnungen aus...");
                
                // Aufträge aktualisieren
                ArbeitHelper.LoadAufträge(db);
                
                // Palettenrest berechnen
                await PaletteRestBerechnen(db, stoppingToken);
                
                // Taktzeit berechnen
                await TaktzeitBerechnen(db, stoppingToken);
                
                // Laufzeit berechnen
                await LaufzeitBerechnen(db, stoppingToken);
                
                // Arbeitsfrei buchen
                await ArbeitsFreiBuchen(db, stoppingToken);
                
                // Rüstzeit-Autobuchung prüfen
                HelperFunctions.ProcessRuestenAutoBuchen(db);
                
                // Statistiken berechnen
                HelperFunctions.CalculateStatistik(db);
                
                // Aktuelles Datum speichern
                _lastDate = DateTime.Now;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Fehler bei den zusätzlichen Berechnungen.");
            }
            finally
            {
                _berechnungAktiv = false;
            }
        }

        /// <summary>
        /// Berechnet den Palettenrest.
        /// </summary>
        private async Task PaletteRestBerechnen(CommonDB db, CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogInformation("Berechne Palettenrest...");
                
                // Beispiel: Palettenrest abrufen und aktualisieren
                using var reader = db.GetReader(@"
                    SELECT AuftragNr, SollStueck, IstStueck 
                    FROM Aufträge 
                    WHERE Status = 'Aktiv' 
                    AND PaletteRestBerechnet = 0
                ");
                
                while (reader.Read())
                {
                    var auftragNr = reader.GetString("AuftragNr");
                    var sollStueck = reader.GetInt32("SollStueck");
                    var istStueck = reader.GetInt32("IstStueck");
                    var restStueck = sollStueck - istStueck;
                    
                    _logger.LogDebug("Auftrag {AuftragNr}: Soll={SollStueck}, Ist={IstStueck}, Rest={RestStueck}", auftragNr, sollStueck, istStueck, restStueck);
                    
                    // Rest in der Datenbank aktualisieren
                    var updateSql = @"
                        UPDATE Aufträge 
                        SET PaletteRest = @RestStueck, 
                            PaletteRestBerechnet = 1 
                        WHERE AuftragNr = @AuftragNr";
                    
                    db.ExecuteNonQuery(updateSql, new { AuftragNr = auftragNr, RestStueck = restStueck });
                    
                    // Auftrag in der Liste aktualisieren
                    var auftrag = ArbeitHelper.IncludisList.Find(i => i.Auftrag.AuftragNr == auftragNr)?.Auftrag;
                    if (auftrag != null)
                    {
                        auftrag.Sollwert = sollStueck;
                        auftrag.Istwert = istStueck;
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Fehler beim Berechnen des Palettenrests.");
            }
        }

        /// <summary>
        /// Berechnet die Taktzeit.
        /// </summary>
        private async Task TaktzeitBerechnen(CommonDB db, CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogInformation("Berechne Taktzeit...");
                
                // Taktzeit aus Stammdaten aktualisieren
                TPMHelper.UpdateTaktzeitAusStamm(db);
                
                // Beispiel: Taktzeit für Maschinen berechnen
                using var reader = db.GetReader(@"
                    SELECT MaschNr, SollTakt, IstTakt 
                    FROM Maschinen 
                    WHERE TaktzeitBerechnet = 0
                ");
                
                while (reader.Read())
                {
                    var maschNr = reader.GetInt32("MaschNr");
                    var sollTakt = reader.GetDecimal("SollTakt");
                    var istTakt = reader.GetDecimal("IstTakt");
                    
                    _logger.LogDebug("Maschine {MaschNr}: SollTakt={SollTakt}, IstTakt={IstTakt}", maschNr, sollTakt, istTakt);
                    
                    // Taktzeit in der Datenbank aktualisieren
                    var updateSql = @"
                        UPDATE Maschinen 
                        SET TaktzeitBerechnet = 1 
                        WHERE MaschNr = @MaschNr";
                    
                    db.ExecuteNonQuery(updateSql, new { MaschNr = maschNr });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Fehler beim Berechnen der Taktzeit.");
            }
        }

        /// <summary>
        /// Berechnet die Laufzeit.
        /// </summary>
        private async Task LaufzeitBerechnen(CommonDB db, CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogInformation("Berechne Laufzeit...");
                
                // Beispiel: Laufzeit für Maschinen berechnen
                using var reader = db.GetReader(@"
                    SELECT MaschNr, StartZeit, EndeZeit 
                    FROM Maschinenprotokoll 
                    WHERE LaufzeitBerechnet = 0
                ");
                
                while (reader.Read())
                {
                    var maschNr = reader.GetInt32("MaschNr");
                    var startZeit = reader.GetDateTime("StartZeit");
                    var endeZeit = reader.GetDateTime("EndeZeit");
                    var laufzeit = (int)(endeZeit - startZeit).TotalMinutes;
                    
                    _logger.LogDebug("Maschine {MaschNr}: Laufzeit={Laufzeit} Minuten", maschNr, laufzeit);
                    
                    // Laufzeit in der Datenbank aktualisieren
                    var updateSql = @"
                        UPDATE Maschinenprotokoll 
                        SET Laufzeit = @Laufzeit, 
                            LaufzeitBerechnet = 1 
                        WHERE MaschNr = @MaschNr 
                        AND StartZeit = @StartZeit";
                    
                    db.ExecuteNonQuery(updateSql, new { MaschNr = maschNr, StartZeit = startZeit, Laufzeit = laufzeit });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Fehler beim Berechnen der Laufzeit.");
            }
        }

        /// <summary>
        /// Bucht Arbeitsfrei.
        /// </summary>
        private async Task ArbeitsFreiBuchen(CommonDB db, CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogInformation("Buche Arbeitsfrei...");
                
                // Beispiel: Arbeitsfrei für Maschinen buchen
                using var reader = db.GetReader(@"
                    SELECT MaschNr, StillstandNr, Dauer 
                    FROM Stillstandsprotokoll 
                    WHERE StillstandArt = 'Arbeitsfrei' 
                    AND ArbeitsfreiGebucht = 0
                ");
                
                while (reader.Read())
                {
                    var maschNr = reader.GetInt32("MaschNr");
                    var stillstandNr = reader.GetInt32("StillstandNr");
                    var dauer = reader.GetInt32("Dauer");
                    
                    _logger.LogDebug("Maschine {MaschNr}: Stillstand {StillstandNr}, Dauer={Dauer} Minuten", maschNr, stillstandNr, dauer);
                    
                    // Arbeitsfrei in der Datenbank markieren
                    var updateSql = @"
                        UPDATE Stillstandsprotokoll 
                        SET ArbeitsfreiGebucht = 1 
                        WHERE StillstandNr = @StillstandNr";
                    
                    db.ExecuteNonQuery(updateSql, new { StillstandNr = stillstandNr });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Fehler beim Buchen von Arbeitsfrei.");
            }
        }

        public override async Task StopAsync(CancellationToken cancellationToken)
        {
            _logger.LogInformation("ZusatzService wird beendet...");
            await base.StopAsync(cancellationToken);
        }
    }
}
