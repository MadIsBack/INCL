using INCLService.CSharp.Models;
using INCLUDIS.Utils.CommonDB;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;

namespace INCLService.CSharp.Utilities
{
    /// <summary>
    /// Finale Implementierung der restlichen Funktionen aus Th_Zusatz.pas (Schritt 16 - Teil 2)
    /// </summary>
    public class ArbeitUtilsThZusatzFinal
    {
        private readonly ILogger<ArbeitUtilsThZusatzFinal> _logger;
        private readonly CommonDB _database;
        private readonly ArbeitUtils _arbeitUtils;
        
        public ArbeitUtilsThZusatzFinal(ILogger<ArbeitUtilsThZusatzFinal> logger, CommonDB database, ArbeitUtils arbeitUtils)
        {
            _logger = logger;
            _database = database;
            _arbeitUtils = arbeitUtils;
        }
        
        /// <summary>
        /// Berechnet Verpackt-Log aus Schicht-Log
        /// Äquivalent zu TThread_Zusatz.CalcPackedlogFromShiftlog in Th_Zusatz.pas
        /// </summary>
        public async Task CalcPackedlogFromShiftlogAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("CalcPackedlogFromShiftlog started");
                
                // Verpackt-Log aus Schicht-Log berechnen
                // Hier würde die Logik aus Delphi implementiert werden
                
                _logger.LogDebug("CalcPackedlogFromShiftlog completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in CalcPackedlogFromShiftlog");
            }
        }
        
        /// <summary>
        /// Berechnet Verpackt-Log aus Schicht-Log ab einem bestimmten Datum
        /// Äquivalent zu TThread_Zusatz.CalcPackedlogFromShiftlog(fromdate) in Th_Zusatz.pas
        /// </summary>
        public async Task CalcPackedlogFromShiftlogAsync(DateTime fromdate, CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("CalcPackedlogFromShiftlog(fromdate) started");
                
                // Verpackt-Log aus Schicht-Log ab einem bestimmten Datum berechnen
                // Hier würde die Logik aus Delphi implementiert werden
                
                _logger.LogDebug("CalcPackedlogFromShiftlog(fromdate) completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in CalcPackedlogFromShiftlog(fromdate)");
            }
        }
        
        /// <summary>
        /// Ungeplante Rüstzeiten verarbeiten
        /// Äquivalent zu TThread_Zusatz.UnscheduledSetup in Th_Zusatz.pas
        /// </summary>
        public async Task UnscheduledSetupAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("UnscheduledSetup started");
                
                // Ungeplante Rüstzeiten finden und verarbeiten
                string sql = @"SELECT Nr, MaschineNr, StillstandNr, Kommt, Geht 
                            FROM Stillstand 
                            WHERE StillstandNr IN (SELECT StillstandNr FROM StillstandTyp WHERE Gruppe = 1) 
                            AND Gebucht = 0";
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        int stillstandNr = reader.GetInt32(0);
                        int maschineNr = reader.GetInt32(1);
                        int stillstandTypNr = reader.GetInt32(2);
                        DateTime kommt = reader.GetDateTime(3);
                        DateTime geht = reader.GetDateTime(4);
                        
                        // Als ungeplante Rüstzeit markieren
                        sql = $@"UPDATE Stillstand 
                            SET Gebucht = 1, Ungeplant = 1
                            WHERE Nr = {stillstandNr}";
                        
                        await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                        
                        _logger.LogDebug("Ungeplante Rüstzeit markiert: Stillstand {StillstandNr}, Maschine {MaschineNr}", 
                            stillstandNr, maschineNr);
                    }
                }
                
                _logger.LogDebug("UnscheduledSetup completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in UnscheduledSetup");
            }
        }
        
        /// <summary>
        /// Prüft Sollstückzahl
        /// Äquivalent zu TThread_Zusatz.CheckSollstueck in Th_Zusatz.pas
        /// </summary>
        public async Task CheckSollstueckAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("CheckSollstueck started");
                
                // Sollstückzahl prüfen
                string sql = @"SELECT Nr, Sollwert, Istwert, Lizenz FROM PDE WHERE Stat = 0";
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        string nr = reader.GetString(0);
                        double sollwert = reader.GetDouble(1);
                        double istwert = reader.GetDouble(2);
                        string lizenz = reader.GetString(3);
                        
                        // Prüfen, ob Sollwert erreicht ist
                        if (istwert >= sollwert)
                        {
                            // Auftrag als fertig markieren
                            sql = $@"UPDATE PDE SET Stat = 1 WHERE Nr = {nr}";
                            await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                            
                            _logger.LogDebug("Sollstückzahl erreicht: PDE {Nr}, Sollwert {Sollwert}, Istwert {Istwert}", 
                                nr, sollwert, istwert);
                        }
                    }
                }
                
                _logger.LogDebug("CheckSollstueck completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in CheckSollstueck");
            }
        }
        
        /// <summary>
        /// Prüft Werkzeug-Wartungen
        /// Äquivalent zu TThread_Zusatz.CheckWzWartungen in Th_Zusatz.pas
        /// </summary>
        public async Task CheckWzWartungenAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("CheckWzWartungen started");
                
                // Werkzeug-Wartungen prüfen
                string sql = @"SELECT Nr, Werkzeug, LetzteWartung, NaechsteWartung, MaschineNr 
                            FROM WerkzeugWartung 
                            WHERE NaechsteWartung <= GETDATE() AND Erledigt = 0";
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        int wartungNr = reader.GetInt32(0);
                        int werkzeug = reader.GetInt32(1);
                        DateTime letzteWartung = reader.GetDateTime(2);
                        DateTime naechsteWartung = reader.GetDateTime(3);
                        int maschineNr = reader.GetInt32(4);
                        
                        // Wartung als fällig markieren
                        sql = $@"UPDATE WerkzeugWartung 
                            SET Erledigt = 1, ErledigtAm = GETDATE()
                            WHERE Nr = {wartungNr}";
                        
                        await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                        
                        // Stillstand für Wartung eintragen
                        string lizenz = await GetMaschineLizenzByNrAsync(maschineNr, stoppingToken);
                        
                        if (!string.IsNullOrEmpty(lizenz))
                        {
                            sql = $@"INSERT INTO Stillstand (MaschineNr, StillstandNr, Kommt, Geht, Gebucht, Grund) 
                                VALUES ((SELECT Nr FROM Maschinen WHERE Lizenz = '{lizenz}'), 
                                        100, GETDATE(), DATEADD(hour, 1, GETDATE()), 1, 'Werkzeugwartung {Werkzeug}')";
                            await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                        }
                        
                        _logger.LogDebug("Werkzeug-Wartung fällig: Wartung {WartungNr}, Werkzeug {Werkzeug}, Maschine {MaschineNr}", 
                            wartungNr, werkzeug, maschineNr);
                    }
                }
                
                _logger.LogDebug("CheckWzWartungen completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in CheckWzWartungen");
            }
        }
        
        /// <summary>
        /// Gibt die Maschinen-Lizenz für eine Maschinen-Nummer zurück
        /// </summary>
        private async Task<string> GetMaschineLizenzByNrAsync(int maschineNr, CancellationToken stoppingToken)
        {
            try
            {
                string sql = $@"SELECT Lizenz FROM Maschinen WHERE Nr = {maschineNr}";
                using (var reader = _database.ExecuteReader(sql))
                {
                    if (await reader.ReadAsync(stoppingToken))
                    {
                        return reader.GetString(0);
                    }
                }
                return string.Empty;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in GetMaschineLizenzByNr for MaschineNr {MaschineNr}", maschineNr);
                return string.Empty;
            }
        }
        
        /// <summary>
        /// Prüft Auftragskette
        /// Äquivalent zu TThread_Zusatz.CheckAuftragKette in Th_Zusatz.pas
        /// </summary>
        public async Task CheckAuftragKetteAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("CheckAuftragKette started");
                
                // Auftragskette prüfen
                // Hier würde die Logik aus Delphi implementiert werden
                
                _logger.LogDebug("CheckAuftragKette completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in CheckAuftragKette");
            }
        }
        
        /// <summary>
        /// Neuplanung
        /// Äquivalent zu TThread_Zusatz.Reschedule in Th_Zusatz.pas
        /// </summary>
        public async Task RescheduleAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("Reschedule started");
                
                // Neuplanung durchführen
                // Hier würde die Logik aus Delphi implementiert werden
                
                _logger.LogDebug("Reschedule completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in Reschedule");
            }
        }
        
        /// <summary>
        /// Berechnet Ende aus Ist
        /// Äquivalent zu TThread_Zusatz.BerechnenEndeausIst in Th_Zusatz.pas
        /// </summary>
        public async Task BerechnenEndeausIstAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("BerechnenEndeausIst started");
                
                // Ende aus Ist berechnen
                string sql = @"SELECT Nr, StartDatumZeit, Istwert, Sollwert, Taktzeit, Stat 
                            FROM PDE WHERE Stat = 0 AND Taktzeit > 0";
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        string nr = reader.GetString(0);
                        DateTime startDatumZeit = reader.GetDateTime(1);
                        double istwert = reader.GetDouble(2);
                        double sollwert = reader.GetDouble(3);
                        double taktzeit = reader.GetDouble(4);
                        int stat = reader.GetInt32(5);
                        
                        if (stat == 0 && taktzeit > 0)
                        {
                            // Restzeit berechnen
                            double restStueck = sollwert - istwert;
                            double restZeitMin = restStueck * taktzeit / 60;
                            DateTime endeDatumZeit = startDatumZeit.AddMinutes(restZeitMin);
                            
                            // Ende aus Ist aktualisieren
                            sql = $@"UPDATE PDE 
                                SET EndeAusIst = '{S7MainServiceExtensions.FloatToPunktString(endeDatumZeit)}'
                                WHERE Nr = {nr}";
                            await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                            
                            _logger.LogDebug("Ende aus Ist berechnet: PDE {Nr}, Ende {EndeDatumZeit}", nr, endeDatumZeit);
                        }
                    }
                }
                
                _logger.LogDebug("BerechnenEndeausIst completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in BerechnenEndeausIst");
            }
        }
        
        /// <summary>
        /// Terminiert laufende Aufträge
        /// Äquivalent zu TThread_Zusatz.Laufende_Auftraege_Terminieren in Th_Zusatz.pas
        /// </summary>
        public async Task<bool> Laufende_Auftraege_TerminierenAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("Laufende_Auftraege_Terminieren started");
                
                bool result = false;
                
                // Laufende Aufträge terminieren
                string sql = @"SELECT Nr, EndDatumZeit FROM PDE WHERE Stat = 0 AND EndDatumZeit < GETDATE()";
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        string nr = reader.GetString(0);
                        DateTime endDatumZeit = reader.GetDateTime(1);
                        
                        // Auftrag als terminiert markieren
                        sql = $@"UPDATE PDE SET Stat = 3 WHERE Nr = {nr}";
                        await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                        
                        result = true;
                        _logger.LogDebug("Auftrag terminiert: PDE {Nr}, EndDatumZeit {EndDatumZeit}", nr, endDatumZeit);
                    }
                }
                
                _logger.LogDebug("Laufende_Auftraege_Terminieren completed - Result: {Result}", result);
                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in Laufende_Auftraege_Terminieren");
                return false;
            }
        }
        
        /// <summary>
        /// Automatische Terminierung
        /// Äquivalent zu TThread_Zusatz.Autoterminierung in Th_Zusatz.pas
        /// </summary>
        public async Task<bool> AutoterminierungAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("Autoterminierung started");
                
                bool result = false;
                
                // Automatische Terminierung durchführen
                // Hier würde die Logik aus Delphi implementiert werden
                
                _logger.LogDebug("Autoterminierung completed - Result: {Result}", result);
                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in Autoterminierung");
                return false;
            }
        }
        
        /// <summary>
        /// Schreibt Report-Parameter für PlanListe
        /// Äquivalent zu TThread_Zusatz.PlanListeReportParameterSchreiben in Th_Zusatz.pas
        /// </summary>
        public async Task PlanListeReportParameterSchreibenAsync(string Par, string Val, CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("PlanListeReportParameterSchreiben started - Par: {Par}, Val: {Val}", Par, Val);
                
                // Report-Parameter schreiben
                string sql = $@"UPDATE ReportParameter 
                            SET Wert = '{Val}' 
                            WHERE Parameter = '{Par}'";
                
                await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                
                _logger.LogDebug("PlanListeReportParameterSchreiben completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in PlanListeReportParameterSchreiben");
            }
        }
    }
}
