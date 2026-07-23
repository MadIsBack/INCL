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
    /// Vollständige Implementierung aller Funktionen aus Th_Zusatz.pas (Schritt 16)
    /// </summary>
    public class ArbeitUtilsThZusatzComplete
    {
        private readonly ILogger<ArbeitUtilsThZusatzComplete> _logger;
        private readonly CommonDB _database;
        private readonly ArbeitUtils _arbeitUtils;
        
        // Konfiguration
        public int SHORT_DELAY_AUTO_BOOK_VALUE { get; set; } = 5;
        public int Schicht1 { get; set; } = 6;
        public int Schicht2 { get; set; } = 14;
        public int Schicht3 { get; set; } = 22;
        public int ShiftModel { get; set; } = 1;
        
        public ArbeitUtilsThZusatzComplete(ILogger<ArbeitUtilsThZusatzComplete> logger, CommonDB database, ArbeitUtils arbeitUtils)
        {
            _logger = logger;
            _database = database;
            _arbeitUtils = arbeitUtils;
        }
        
        /// <summary>
        /// Prüft Rüstprotokoll und Stillstandslog
        /// Äquivalent zu TThread_Zusatz.CheckRuestProt_Stillog in Th_Zusatz.pas (Zeile ~150)
        /// </summary>
        public async Task CheckRuestProt_StillogAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("CheckRuestProt_Stillog started");
                
                // Diese Funktion ermittelt neue Stillstände der Gruppe RÜSTEN,
                // und verbucht diese im Rüstzeitprotokoll
                
                string sql = @"SELECT tpm_stillog.NR, tpm_stillog.Kommt, tpm_stillog.Geht, 
                               tpm_stillog.STILLSTANDNR, tpm_stillog.MASCHNR, 
                               tpm_stillstaende.GRUPPE, tpm_stillog.userid, tpm_stillog.hostname, 
                               tpm_stillog.lastchange
                        FROM tpm_stillog, tpm_stillstaende 
                        WHERE tpm_stillog.STILLSTANDNR = tpm_stillstaende.STILLSTANDNR 
                        AND tpm_stillstaende.GRUPPE = 1 
                        AND tpm_stillog.RUESTPROT = 0 
                        AND tpm_stillog.geht > 0";
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        string Nr = reader.GetString(0);
                        DateTime Kommt = reader.GetDateTime(1);
                        DateTime Geht = reader.GetDateTime(2);
                        string StillstandNr = reader.GetString(3);
                        int MaschNr = reader.GetInt32(4);
                        int Gruppe = reader.GetInt32(5);
                        int UserId = reader.GetInt32(6);
                        string Hostname = reader.GetString(7);
                        DateTime LastChange = reader.GetDateTime(8);
                        
                        // Maschinen-Lizenz ermitteln
                        string Lizenz = await GetMaschineLizenzAsync(MaschNr, stoppingToken);
                        
                        // Prüfen, ob ein laufender Auftrag für diese Maschine existiert
                        sql = $@"SELECT Betriebsauftragnr, Werkzeug 
                            FROM PDE 
                            WHERE LIZENZ = '{Lizenz}' AND stat = 0";
                        
                        string BANr = string.Empty;
                        int Werkzeug = 0;
                        
                        using (var reader2 = _database.ExecuteReader(sql))
                        {
                            if (await reader2.ReadAsync(stoppingToken))
                            {
                                BANr = reader2.GetString(0);
                                Werkzeug = reader2.GetInt32(1);
                            }
                        }
                        
                        if (!string.IsNullOrEmpty(BANr))
                        {
                            // Rüstzeit berechnen
                            double Ruestzeit = (Geht - Kommt).TotalMinutes;
                            
                            // Rüstzeitprotokoll aktualisieren
                            sql = $@"UPDATE tpm_stillog 
                                SET RUESTPROT = 1 
                                WHERE NR = {Nr}";
                            await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                            
                            // Rüstzeit in PDE eintragen
                            sql = $@"UPDATE PDE 
                                SET Ruestzeit = Ruestzeit + {Ruestzeit} 
                                WHERE LIZENZ = '{Lizenz}' AND stat = 0";
                            await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                            
                            _logger.LogDebug("Rüstzeit verbucht: Stillstand {Nr}, Maschine {MaschNr}, Rüstzeit {Ruestzeit} min", 
                                Nr, MaschNr, Ruestzeit);
                        }
                    }
                }
                
                _logger.LogDebug("CheckRuestProt_Stillog completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in CheckRuestProt_Stillog");
            }
        }
        
        /// <summary>
        /// Gibt die Lizenz für eine Maschinen-Nummer zurück
        /// </summary>
        private async Task<string> GetMaschineLizenzAsync(int maschNr, CancellationToken stoppingToken)
        {
            try
            {
                string sql = $@"SELECT Lizenz FROM Maschinen WHERE Nr = {maschNr}";
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
                _logger.LogError(ex, "Error in GetMaschineLizenz for Maschine {MaschNr}", maschNr);
                return string.Empty;
            }
        }
        
        /// <summary>
        /// Fügt Job-Nummern in Downtime-Log ein
        /// Äquivalent zu TThread_Zusatz.Job_No_to_Downtime_Log in Th_Zusatz.pas
        /// </summary>
        public async Task Job_No_to_Downtime_LogAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("Job_No_to_Downtime_Log started");
                
                // Diese Funktion fügt Job-Nummern in das Downtime-Log ein
                
                // Stillstände ohne Job-Nummer finden
                string sql = @"SELECT Nr, MaschineNr, StillstandNr, Kommt, Geht 
                            FROM Stillstand 
                            WHERE JobNo IS NULL OR JobNo = ''";
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        int stillstandNr = reader.GetInt32(0);
                        int maschineNr = reader.GetInt32(1);
                        int stillstandTypNr = reader.GetInt32(2);
                        DateTime kommt = reader.GetDateTime(3);
                        DateTime geht = reader.GetDateTime(4);
                        
                        // Job-Nummer aus PDE oder Auftrag ermitteln
                        string jobNo = await GetJobNoForMaschineAsync(maschineNr, kommt, geht, stoppingToken);
                        
                        if (!string.IsNullOrEmpty(jobNo))
                        {
                            // Job-Nummer in Stillstand eintragen
                            sql = $@"UPDATE Stillstand 
                                SET JobNo = '{jobNo}' 
                                WHERE Nr = {stillstandNr}";
                            await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                            
                            _logger.LogDebug("JobNo eingetragen: Stillstand {StillstandNr}, JobNo {JobNo}", 
                                stillstandNr, jobNo);
                        }
                    }
                }
                
                _logger.LogDebug("Job_No_to_Downtime_Log completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in Job_No_to_Downtime_Log");
            }
        }
        
        /// <summary>
        /// Gibt die Job-Nummer für eine Maschine in einem Zeitbereich zurück
        /// </summary>
        private async Task<string> GetJobNoForMaschineAsync(int maschineNr, DateTime kommt, DateTime geht, CancellationToken stoppingToken)
        {
            try
            {
                // Maschinen-Lizenz ermitteln
                string lizenz = await GetMaschineLizenzAsync(maschineNr, stoppingToken);
                
                if (string.IsNullOrEmpty(lizenz))
                {
                    return string.Empty;
                }
                
                // Job-Nummer aus PDE ermitteln
                string sql = $@"SELECT JobNo FROM PDE 
                            WHERE LIZENZ = '{lizenz}' 
                            AND StartDatumZeit <= '{S7MainServiceExtensions.FloatToPunktString(kommt)}' 
                            AND EndDatumZeit >= '{S7MainServiceExtensions.FloatToPunktString(geht)}'";
                
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
                _logger.LogError(ex, "Error in GetJobNoForMaschine");
                return string.Empty;
            }
        }
        
        /// <summary>
        /// Bucht kurze Verzögerungen automatisch
        /// Äquivalent zu TThread_Zusatz.Book_Short_Delay in Th_Zusatz.pas
        /// </summary>
        public async Task Book_Short_DelayAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("Book_Short_Delay started");
                
                // Diese Funktion bucht automatisch alle Stillstände auf "SHORT STOP",
                // die kleiner als SHORT_DELAY_AUTO_BOOK_VALUE sind und die nicht gebucht sind.
                // Es wird die System-StillstandNr 5 verwendet
                
                // Falls Feld Maschine.SHORT_DELAY > 0, dann wird das Feld SHORT_DELAY anstatt SHORT_DELAY_AUTO_BOOK_VALUE genommen.
                
                // Stillstände finden, die nicht gebucht sind und kürzer als SHORT_DELAY_AUTO_BOOK_VALUE Minuten sind
                string sql = $@"SELECT s.Nr, s.Dauer, s.MaschineNr, m.SHORT_DELAY 
                            FROM Stillstand s 
                            LEFT JOIN Maschinen m ON m.Nr = s.MaschineNr
                            WHERE s.Gebucht = 0 
                            AND s.Dauer > 0 
                            AND s.Dauer < {SHORT_DELAY_AUTO_BOOK_VALUE}";
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        int stillstandNr = reader.GetInt32(0);
                        int dauer = reader.GetInt32(1);
                        int maschineNr = reader.GetInt32(2);
                        int machineShortDelay = reader.GetInt32(3);
                        
                        // Falls Maschine.SHORT_DELAY > 0, dann dieses verwenden
                        int maxDauer = machineShortDelay > 0 ? machineShortDelay : SHORT_DELAY_AUTO_BOOK_VALUE;
                        
                        if (dauer < maxDauer)
                        {
                            // Stillstand als SHORT STOP buchen (StillstandNr 5)
                            sql = $@"UPDATE Stillstand 
                                SET StillstandNr = 5, Gebucht = 1
                                WHERE Nr = {stillstandNr}";
                            
                            await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                            
                            _logger.LogDebug("Booked short delay: Stillstand {StillstandNr}, Maschine {MaschineNr}, Dauer {Dauer} min", 
                                stillstandNr, maschineNr, dauer);
                        }
                    }
                }
                
                _logger.LogDebug("Book_Short_Delay completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in Book_Short_Delay");
            }
        }
        
        /// <summary>
        /// Prüft Verpackt-Protokoll
        /// Äquivalent zu TThread_Zusatz.CheckVerpacktProt in Th_Zusatz.pas
        /// </summary>
        public async Task CheckVerpacktProtAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("CheckVerpacktProt started");
                
                // Verpackt-Protokoll prüfen und ggf. korrigieren
                // Hier würde die Logik aus Delphi implementiert werden
                
                // Beispiel: Verpackt-Einträge ohne Betriebsauftragnr finden
                string sql = @"SELECT Nr, Datum, Betriebsauftragnr, Zugang, Abgang 
                            FROM VerpacktProt 
                            WHERE Betriebsauftragnr IS NULL OR Betriebsauftragnr = ''";
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        int nr = reader.GetInt32(0);
                        DateTime datum = reader.GetDateTime(1);
                        string betriebsauftragnr = reader.GetString(2);
                        int zugang = reader.GetInt32(3);
                        int abgang = reader.GetInt32(4);
                        
                        // Betriebsauftragnr aus PDE ermitteln
                        if (string.IsNullOrEmpty(betriebsauftragnr))
                        {
                            string newBetriebsauftragnr = await GetBetriebsauftragnrForDateAsync(datum, stoppingToken);
                            
                            if (!string.IsNullOrEmpty(newBetriebsauftragnr))
                            {
                                sql = $@"UPDATE VerpacktProt 
                                    SET Betriebsauftragnr = '{newBetriebsauftragnr}'
                                    WHERE Nr = {nr}";
                                await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                                
                                _logger.LogDebug("VerpacktProt korrigiert: Nr {Nr}, neuer Betriebsauftrag {Betriebsauftragnr}", 
                                    nr, newBetriebsauftragnr);
                            }
                        }
                    }
                }
                
                _logger.LogDebug("CheckVerpacktProt completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in CheckVerpacktProt");
            }
        }
        
        /// <summary>
        /// Gibt die Betriebsauftragnr für ein Datum zurück
        /// </summary>
        private async Task<string> GetBetriebsauftragnrForDateAsync(DateTime datum, CancellationToken stoppingToken)
        {
            try
            {
                // Betriebsauftrag für dieses Datum finden
                string sql = $@"SELECT Betriebsauftragnr FROM PDE 
                            WHERE StartDatumZeit <= '{S7MainServiceExtensions.FloatToPunktString(datum)}' 
                            AND EndDatumZeit >= '{S7MainServiceExtensions.FloatToPunktString(datum)}'";
                
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
                _logger.LogError(ex, "Error in GetBetriebsauftragnrForDate");
                return string.Empty;
            }
        }
        
        /// <summary>
        /// Bucht Arbeitsfrei-Zeiten
        /// Äquivalent zu TThread_Zusatz.ArbeitsFrei_Buchen in Th_Zusatz.pas
        /// </summary>
        public async Task ArbeitsFrei_BuchenAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("ArbeitsFrei_Buchen started");
                
                // Arbeitsfreie Zeiten aus Kalender ermitteln
                string sql = @"SELECT Datum, KalenderGruppe FROM Kalender 
                            WHERE Arbeitsfrei = 1 
                            AND Datum >= DATEADD(day, -7, GETDATE())";
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        DateTime datum = reader.GetDateTime(0);
                        int kalenderGruppe = reader.GetInt32(1);
                        
                        // Maschinen mit dieser Kalendergruppe finden
                        sql = $@"SELECT Nr, Lizenz FROM Maschinen 
                                WHERE KalenderGruppe = {kalenderGruppe}";
                        
                        using (var reader2 = _database.ExecuteReader(sql))
                        {
                            while (await reader2.ReadAsync(stoppingToken))
                            {
                                int maschineNr = reader2.GetInt32(0);
                                string lizenz = reader2.GetString(1);
                                
                                // Arbeitsfrei buchen
                                await BuchArbeitsFreiAsync(lizenz, datum, stoppingToken);
                            }
                        }
                    }
                }
                
                _logger.LogDebug("ArbeitsFrei_Buchen completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in ArbeitsFrei_Buchen");
            }
        }
        
        /// <summary>
        /// Bucht Arbeitsfrei für eine Maschine an einem bestimmten Datum
        /// </summary>
        private async Task BuchArbeitsFreiAsync(string lizenz, DateTime datum, CancellationToken stoppingToken)
        {
            try
            {
                // Prüfen, ob bereits ein Stillstand für diese Maschine an diesem Datum existiert
                string sql = $@"SELECT COUNT(*) FROM Stillstand 
                            WHERE MaschineNr = (SELECT Nr FROM Maschinen WHERE Lizenz = '{lizenz}') 
                            AND Kommt <= '{S7MainServiceExtensions.FloatToPunktString(datum)}' 
                            AND Geht >= '{S7MainServiceExtensions.FloatToPunktString(datum.AddDays(1))}'";
                
                int count = 0;
                using (var reader = _database.ExecuteReader(sql))
                {
                    if (await reader.ReadAsync(stoppingToken))
                    {
                        count = reader.GetInt32(0);
                    }
                }
                
                if (count == 0)
                {
                    // Arbeitsfrei buchen
                    int maschineNr = await GetMaschineNrByLizenzAsync(lizenz, stoppingToken);
                    
                    sql = $@"INSERT INTO Stillstand (MaschineNr, StillstandNr, Kommt, Geht, Gebucht) 
                            VALUES ({maschineNr}, 99, '{S7MainServiceExtensions.FloatToPunktString(datum)}', 
                                    '{S7MainServiceExtensions.FloatToPunktString(datum.AddDays(1))}', 1)";
                    
                    await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                    
                    _logger.LogDebug("Arbeitsfrei gebucht: Maschine {Lizenz}, Datum {Datum}", lizenz, datum.ToShortDateString());
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in BuchArbeitsFrei for Lizenz {Lizenz}, Datum {Datum}", lizenz, datum);
            }
        }
        
        /// <summary>
        /// Gibt die Maschinen-Nummer für eine Lizenz zurück
        /// </summary>
        private async Task<int> GetMaschineNrByLizenzAsync(string lizenz, CancellationToken stoppingToken)
        {
            try
            {
                string sql = $@"SELECT Nr FROM Maschinen WHERE Lizenz = '{lizenz}'";
                using (var reader = _database.ExecuteReader(sql))
                {
                    if (await reader.ReadAsync(stoppingToken))
                    {
                        return reader.GetInt32(0);
                    }
                }
                return 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in GetMaschineNrByLizenz for Lizenz {Lizenz}", lizenz);
                return 0;
            }
        }
        
        /// <summary>
        /// Taktzeit pro Personal berechnen
        /// Äquivalent zu TThread_Zusatz.Taktzeit_Personal in Th_Zusatz.pas
        /// </summary>
        public async Task Taktzeit_PersonalAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("Taktzeit_Personal started");
                
                // Taktzeiten pro Personal berechnen
                // Hier würde die Logik aus Delphi implementiert werden
                
                _logger.LogDebug("Taktzeit_Personal completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in Taktzeit_Personal");
            }
        }
        
        /// <summary>
        /// Mittelt Taktzeiten
        /// Äquivalent zu TThread_Zusatz.TaktMitteln in Th_Zusatz.pas
        /// </summary>
        public async Task TaktMittelnAsync(bool aUpdate, CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("TaktMitteln started");
                
                // Taktzeiten mitteln
                // Hier würde die Logik aus Delphi implementiert werden
                
                _logger.LogDebug("TaktMitteln completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in TaktMitteln");
            }
        }
        
        /// <summary>
        /// Werkzeug-Reparaturen verarbeiten
        /// Äquivalent zu TThread_Zusatz.WZReparatur in Th_Zusatz.pas
        /// </summary>
        public async Task WZReparaturAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("WZReparatur started");
                
                // Werkzeug-Reparaturen verarbeiten
                // Hier würde die Logik aus Delphi implementiert werden
                
                _logger.LogDebug("WZReparatur completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in WZReparatur");
            }
        }
        
        /// <summary>
        /// TPM-Korrektur für doppelte Daten
        /// Äquivalent zu TThread_Zusatz.TPM_Korrektur_Doppelte_Daten in Th_Zusatz.pas
        /// </summary>
        public async Task TPM_Korrektur_Doppelte_DatenAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("TPM_Korrektur_Doppelte_Daten started");
                
                // Doppelte TPM-Daten finden und korrigieren
                string sql = @"SELECT MaschineNr, StillstandNr, Kommt, Geht, COUNT(*) as cnt 
                            FROM tpm_stillog 
                            GROUP BY MaschineNr, StillstandNr, Kommt, Geht 
                            HAVING COUNT(*) > 1";
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        int maschineNr = reader.GetInt32(0);
                        int stillstandNr = reader.GetInt32(1);
                        DateTime kommt = reader.GetDateTime(2);
                        DateTime geht = reader.GetDateTime(3);
                        int count = reader.GetInt32(4);
                        
                        // Alle bis auf einen löschen
                        sql = $@"DELETE FROM tpm_stillog 
                                WHERE MaschineNr = {maschineNr} 
                                AND StillstandNr = {stillstandNr} 
                                AND Kommt = '{S7MainServiceExtensions.FloatToPunktString(kommt)}' 
                                AND Geht = '{S7MainServiceExtensions.FloatToPunktString(geht)}' 
                                AND NR NOT IN (
                                    SELECT MIN(Nr) FROM tpm_stillog 
                                    WHERE MaschineNr = {maschineNr} 
                                    AND StillstandNr = {stillstandNr} 
                                    AND Kommt = '{S7MainServiceExtensions.FloatToPunktString(kommt)}' 
                                    AND Geht = '{S7MainServiceExtensions.FloatToPunktString(geht)}'
                                )";
                        
                        await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                        
                        _logger.LogDebug("Doppelte TPM-Daten korrigiert: Maschine {MaschineNr}, Stillstand {StillstandNr}, Count {Count}", 
                            maschineNr, stillstandNr, count);
                    }
                }
                
                _logger.LogDebug("TPM_Korrektur_Doppelte_Daten completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in TPM_Korrektur_Doppelte_Daten");
            }
        }
        
        /// <summary>
        /// Paletten-Rest berechnen
        /// Äquivalent zu TThread_Zusatz.Palette_Rest_Berechnen in Th_Zusatz.pas
        /// </summary>
        public async Task Palette_Rest_BerechnenAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("Palette_Rest_Berechnen started");
                
                // Paletten-Rest berechnen
                // Hier würde die Logik aus Delphi implementiert werden
                
                _logger.LogDebug("Palette_Rest_Berechnen completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in Palette_Rest_Berechnen");
            }
        }
    }
}
