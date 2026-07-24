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
                        FROM tpm_stillog 
                        LEFT JOIN tpm_stillstaende ON tpm_stillog.STILLSTANDNR = tpm_stillstaende.STILLSTANDNR
                        WHERE tpm_stillog.RUESTPROT = 0 
                        AND tpm_stillog.GEHT > 0 
                        AND tpm_stillstaende.GRUPPE = 1";
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        int nr = reader.GetInt32(0);
                        DateTime kommt = reader.GetDateTime(1);
                        DateTime geht = reader.GetDateTime(2);
                        int stillstandNr = reader.GetInt32(3);
                        int maschnr = reader.GetInt32(4);
                        int gruppe = reader.GetInt32(5);
                        
                        if (gruppe == 1) // RÜSTEN
                        {
                            // Maschinen-Lizenz ermitteln
                            string lizenz = await GetMaschineLizenzAsync(maschnr, stoppingToken);
                            
                            // PDE-Auftrag für diese Maschine und Zeit finden
                            string pdeSql = $@"SELECT Nr, Betriebsauftragnr FROM PDE 
                                            WHERE Maschine = '{lizenz}' 
                                            AND StartDatumZeit <= '{S7MainServiceExtensions.FloatToPunktString(geht)}' 
                                            AND (EndDatumZeit >= '{S7MainServiceExtensions.FloatToPunktString(kommt)}' OR EndDatumZeit = 0)
                                            AND Stat = 0";
                            
                            string betriebsauftragnr = string.Empty;
                            string pdeNr = string.Empty;
                            
                            using (var pdeReader = _database.ExecuteReader(pdeSql))
                            {
                                if (await pdeReader.ReadAsync(stoppingToken))
                                {
                                    pdeNr = pdeReader.GetString(0);
                                    betriebsauftragnr = pdeReader.GetString(1);
                                }
                            }
                            
                            if (!string.IsNullOrEmpty(betriebsauftragnr))
                            {
                                // Rüstzeit berechnen (in Minuten)
                                double ruestzeit = (geht - kommt).TotalMinutes;
                                
                                // RÜSTPROT = 1 setzen
                                sql = $@"UPDATE tpm_stillog SET RUESTPROT = 1 WHERE NR = {nr}";
                                await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                                
                                // Rüstzeit in PDE eintragen
                                sql = $@"UPDATE PDE SET Ruestzeit = Ruestzeit + {ruestzeit} 
                                        WHERE Nr = '{pdeNr}'";
                                await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                                
                                _logger.LogDebug("Rüstprotokoll: Stillstand {Nr} verbucht, Rüstzeit: {Ruestzeit} Min, PDE: {PdeNr}", 
                                    nr, ruestzeit, pdeNr);
                            }
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
        /// Gibt die Maschinen-Lizenz für eine Maschinen-Nummer zurück
        /// </summary>
        private async Task<string> GetMaschineLizenzAsync(int maschinenNr, CancellationToken stoppingToken)
        {
            try
            {
                string sql = $@"SELECT Lizenz FROM Maschinen WHERE Maschnr = {maschinenNr}";
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
                _logger.LogError(ex, "Error in GetMaschineLizenz for Maschnr {MaschinenNr}", maschinenNr);
                return string.Empty;
            }
        }
        
        /// <summary>
        /// Job-Nummern in Downtime-Log eintragen
        /// Äquivalent zu TThread_Zusatz.Job_No_to_Downtime_Log in Th_Zusatz.pas
        /// </summary>
        public async Task Job_No_to_Downtime_LogAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("Job_No_to_Downtime_Log started");
                
                // Stillstände ohne JobNo finden
                string sql = @"SELECT Nr, MaschineNr, Kommt, Geht, StillstandNr 
                            FROM Stillstand 
                            WHERE JobNo IS NULL OR JobNo = ''";
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        int stillstandNr = reader.GetInt32(0);
                        int maschineNr = reader.GetInt32(1);
                        DateTime kommt = reader.GetDateTime(2);
                        DateTime geht = reader.GetDateTime(3);
                        int stillstandTypNr = reader.GetInt32(4);
                        
                        // Maschinen-Lizenz ermitteln
                        string lizenz = await GetMaschineLizenzAsync(maschineNr, stoppingToken);
                        
                        if (!string.IsNullOrEmpty(lizenz))
                        {
                            // JobNo aus PDE oder Auftrag ermitteln
                            string jobNo = await GetJobNoForMaschineAsync(lizenz, kommt, geht, stoppingToken);
                            
                            if (!string.IsNullOrEmpty(jobNo))
                            {
                                // JobNo in Stillstand eintragen
                                sql = $@"UPDATE Stillstand SET JobNo = '{jobNo}' WHERE Nr = {stillstandNr}";
                                await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                                
                                _logger.LogDebug("JobNo zu Stillstand hinzugefügt: Stillstand {StillstandNr}, JobNo {JobNo}", 
                                    stillstandNr, jobNo);
                            }
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
        /// Ermittelt die JobNo für eine Maschine in einem Zeitbereich
        /// </summary>
        private async Task<string> GetJobNoForMaschineAsync(string lizenz, DateTime kommt, DateTime geht, CancellationToken stoppingToken)
        {
            try
            {
                // Zuerst in PDE suchen
                string sql = $@"SELECT Betriebsauftragnr FROM PDE 
                                WHERE Maschine = '{lizenz}' 
                                AND StartDatumZeit <= '{S7MainServiceExtensions.FloatToPunktString(geht)}' 
                                AND (EndDatumZeit >= '{S7MainServiceExtensions.FloatToPunktString(kommt)}' OR EndDatumZeit = 0)
                                AND Stat = 0";
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    if (await reader.ReadAsync(stoppingToken))
                    {
                        return reader.GetString(0);
                    }
                }
                
                // Dann in AArchiv suchen
                sql = $@"SELECT Betriebsauftragnr FROM AArchiv 
                        WHERE Maschine = '{lizenz}' 
                        AND StartDatumZeit <= '{S7MainServiceExtensions.FloatToPunktString(geht)}' 
                        AND EndDatumZeit >= '{S7MainServiceExtensions.FloatToPunktString(kommt)}'";
                
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
        /// Kurze Verzögerungen automatisch buchen
        /// Äquivalent zu TThread_Zusatz.Book_Short_Delay in Th_Zusatz.pas
        /// </summary>
        public async Task Book_Short_DelayAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("Book_Short_Delay started");
                
                // Ungebuchte Stillstände mit kurzer Dauer finden
                string sql = @"SELECT Nr, MaschineNr, Kommt, Geht, Dauer, StillstandNr 
                            FROM Stillstand 
                            WHERE Gebucht = 0 
                            AND Dauer < @ShortDelayValue";
                
                // Parameter hinzufügen
                sql = sql.Replace("@ShortDelayValue", SHORT_DELAY_AUTO_BOOK_VALUE.ToString());
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        int stillstandNr = reader.GetInt32(0);
                        int maschineNr = reader.GetInt32(1);
                        DateTime kommt = reader.GetDateTime(2);
                        DateTime geht = reader.GetDateTime(3);
                        int dauer = reader.GetInt32(4);
                        int stillstandTypNr = reader.GetInt32(5);
                        
                        // Maschinen-spezifischen Short_Delay-Wert prüfen
                        int machineShortDelay = SHORT_DELAY_AUTO_BOOK_VALUE;
                        string checkSql = $@"SELECT SHORT_DELAY FROM Maschinen WHERE Maschnr = {maschineNr}";
                        
                        using (var checkReader = _database.ExecuteReader(checkSql))
                        {
                            if (await checkReader.ReadAsync(stoppingToken))
                            {
                                int? shortDelay = checkReader.GetValue<int?>(0);
                                if (shortDelay.HasValue && shortDelay.Value > 0)
                                {
                                    machineShortDelay = shortDelay.Value;
                                }
                            }
                        }
                        
                        // Nur buchen, wenn Dauer kleiner als der Maschinen-spezifische Wert
                        if (dauer < machineShortDelay)
                        {
                            // Als SHORT STOP (StillstandNr 5) buchen
                            sql = $@"UPDATE Stillstand SET Gebucht = 1, StillstandNr = 5 WHERE Nr = {stillstandNr}";
                            await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                            
                            _logger.LogDebug("Kurze Verzögerung gebucht: Stillstand {StillstandNr}, Dauer: {Dauer} Min", 
                                stillstandNr, dauer);
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
        /// Verpackt-Protokoll prüfen
        /// Äquivalent zu TThread_Zusatz.CheckVerpacktProt in Th_Zusatz.pas
        /// </summary>
        public async Task CheckVerpacktProtAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("CheckVerpacktProt started");
                
                // VerpacktProt-Einträge ohne Betriebsauftragnr finden
                string sql = @"SELECT Nr, Barcode, ZugangsDatum, ZugangsZeit 
                            FROM VerpacktProt 
                            WHERE Betriebsauftragnr IS NULL OR Betriebsauftragnr = ''";
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        int verpacktProtNr = reader.GetInt32(0);
                        string barcode = reader.GetString(1);
                        DateTime zugangsDatum = reader.GetDateTime(2);
                        DateTime zugangsZeit = reader.GetDateTime(3);
                        
                        // Betriebsauftragnr aus PDE oder AArchiv ermitteln
                        string betriebsauftragnr = await GetBetriebsauftragnrForDateAsync(barcode, zugangsDatum, zugangsZeit, stoppingToken);
                        
                        if (!string.IsNullOrEmpty(betriebsauftragnr))
                        {
                            // Betriebsauftragnr in VerpacktProt eintragen
                            sql = $@"UPDATE VerpacktProt SET Betriebsauftragnr = '{betriebsauftragnr}' WHERE Nr = {verpacktProtNr}";
                            await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                            
                            _logger.LogDebug("Betriebsauftragnr zu VerpacktProt hinzugefügt: VerpacktProt {VerpacktProtNr}, Betriebsauftragnr {Betriebsauftragnr}", 
                                verpacktProtNr, betriebsauftragnr);
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
        /// Ermittelt die Betriebsauftragnr für ein Datum und Barcode
        /// </summary>
        private async Task<string> GetBetriebsauftragnrForDateAsync(string barcode, DateTime datum, DateTime zeit, CancellationToken stoppingToken)
        {
            try
            {
                DateTime datumZeit = new DateTime(datum.Year, datum.Month, datum.Day, zeit.Hour, zeit.Minute, zeit.Second);
                
                // In PDE suchen
                string sql = $@"SELECT Betriebsauftragnr FROM PDE 
                                WHERE (Barcode = '{barcode}' OR Barcode2 = '{barcode}')
                                AND StartDatumZeit <= '{S7MainServiceExtensions.FloatToPunktString(datumZeit)}' 
                                AND (EndDatumZeit >= '{S7MainServiceExtensions.FloatToPunktString(datumZeit)}' OR EndDatumZeit = 0)";
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    if (await reader.ReadAsync(stoppingToken))
                    {
                        return reader.GetString(0);
                    }
                }
                
                // In AArchiv suchen
                sql = $@"SELECT Betriebsauftragnr FROM AArchiv 
                        WHERE (Barcode = '{barcode}' OR Barcode2 = '{barcode}')
                        AND StartDatumZeit <= '{S7MainServiceExtensions.FloatToPunktString(datumZeit)}' 
                        AND EndDatumZeit >= '{S7MainServiceExtensions.FloatToPunktString(datumZeit)}'";
                
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
        /// Arbeitsfrei-Zeiten buchen
        /// Äquivalent zu TThread_Zusatz.ArbeitsFrei_Buchen in Th_Zusatz.pas
        /// </summary>
        public async Task ArbeitsFrei_BuchenAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("ArbeitsFrei_Buchen started");
                
                // Kalender-Einträge mit Arbeitsfrei = 1 laden
                string sql = @"SELECT Nr, KalenderGruppe, Datum, Bezeichnung 
                            FROM Kalender 
                            WHERE Arbeitsfrei = 1 
                            AND Datum >= CAST(GETDATE() AS DATE)";
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        int kalenderNr = reader.GetInt32(0);
                        int kalenderGruppe = reader.GetInt32(1);
                        DateTime datum = reader.GetDateTime(2);
                        string bezeichnung = reader.GetString(3);
                        
                        // Maschinen mit passender KalenderGruppe finden
                        sql = $@"SELECT Nr, Lizenz FROM Maschinen WHERE KalenderGruppe = {kalenderGruppe}";
                        
                        using (var maschinenReader = _database.ExecuteReader(sql))
                        {
                            while (await maschinenReader.ReadAsync(stoppingToken))
                            {
                                int maschinenNr = maschinenReader.GetInt32(0);
                                string lizenz = maschinenReader.GetString(1);
                                
                                // Prüfen, ob bereits ein Stillstand für diese Maschine an diesem Datum existiert
                                string checkSql = $@"SELECT COUNT(*) FROM Stillstand 
                                                    WHERE MaschineNr = {maschinenNr} 
                                                    AND StillstandNr = 99 
                                                    AND Kommt >= '{S7MainServiceExtensions.FloatToPunktString(datum)}' 
                                                    AND Kommt < '{S7MainServiceExtensions.FloatToPunktString(datum.AddDays(1))}'";
                                
                                bool exists = false;
                                using (var checkReader = _database.ExecuteReader(checkSql))
                                {
                                    if (await checkReader.ReadAsync(stoppingToken))
                                    {
                                        exists = checkReader.GetInt32(0) > 0;
                                    }
                                }
                                
                                if (!exists)
                                {
                                    // Arbeitsfrei als Stillstand (StillstandNr 99) buchen
                                    DateTime kommt = datum;
                                    DateTime geht = datum.AddHours(8); // 8 Stunden Arbeitsfrei
                                    
                                    sql = $@"INSERT INTO Stillstand (MaschineNr, StillstandNr, Kommt, Geht, Gebucht, Grund) 
                                            VALUES ({maschinenNr}, 99, 
                                                    '{S7MainServiceExtensions.FloatToPunktString(kommt)}', 
                                                    '{S7MainServiceExtensions.FloatToPunktString(geht)}', 
                                                    1, 'Arbeitsfrei: {bezeichnung}')";
                                    
                                    await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                                    
                                    _logger.LogDebug("Arbeitsfrei gebucht: Maschine {MaschinenNr}, Datum {Datum}, Bezeichnung {Bezeichnung}", 
                                        maschinenNr, datum.ToString("yyyy-MM-dd"), bezeichnung);
                                }
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
        /// TPM-Korrektur für doppelte Daten
        /// Äquivalent zu TThread_Zusatz.TPM_Korrektur_Doppelte_Daten in Th_Zusatz.pas
        /// </summary>
        public async Task TPM_Korrektur_Doppelte_DatenAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("TPM_Korrektur_Doppelte_Daten started");
                
                // Doppelte Einträge in tpm_stillog finden
                string sql = @"SELECT maschnr, datum, schicht, BETRIEBSAUFTRAGNR, COUNT(*) CNT 
                            FROM tpm_stillog 
                            GROUP BY maschnr, datum, schicht, BETRIEBSAUFTRAGNR
                            HAVING COUNT(*) > 1";
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        string maschnr = reader.GetString(0);
                        DateTime datum = reader.GetDateTime(1);
                        int schicht = reader.GetInt32(2);
                        string betriebsauftragnr = reader.GetString(3);
                        int count = reader.GetInt32(4);
                        
                        // Alle bis auf einen löschen (den mit der höchsten Nr behalten)
                        sql = $@"DELETE FROM tpm_stillog 
                                WHERE maschnr = '{maschnr}' 
                                AND datum = '{S7MainServiceExtensions.FloatToPunktString(datum)}' 
                                AND schicht = {schicht} 
                                AND BETRIEBSAUFTRAGNR = '{betriebsauftragnr}'
                                AND Nr <> (SELECT MAX(NR) FROM tpm_stillog 
                                           WHERE maschnr = '{maschnr}' 
                                           AND datum = '{S7MainServiceExtensions.FloatToPunktString(datum)}' 
                                           AND schicht = {schicht} 
                                           AND BETRIEBSAUFTRAGNR = '{betriebsauftragnr}')";
                        
                        int deleted = await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                        
                        _logger.LogDebug("Doppelte TPM-Daten korrigiert: maschnr={Maschnr}, datum={Datum}, schicht={Schicht}, gelöscht={Deleted}", 
                            maschnr, datum.ToString("yyyy-MM-dd"), schicht, deleted);
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
        /// Werkzeug-Reparaturen verarbeiten
        /// Äquivalent zu TThread_Zusatz.WZReparatur in Th_Zusatz.pas
        /// </summary>
        public async Task WZReparaturAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("WZReparatur started");
                
                // Werkzeug-Reparaturen finden
                string sql = @"SELECT Nr, Werkzeug, ReparaturDatum, ReparaturEnde, MaschineNr, Notiz 
                            FROM WerkzeugReparatur 
                            WHERE ReparaturEnde IS NULL 
                            AND ReparaturDatum <= GETDATE()";
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        int reparaturNr = reader.GetInt32(0);
                        int werkzeug = reader.GetInt32(1);
                        DateTime reparaturDatum = reader.GetDateTime(2);
                        int maschineNr = reader.GetInt32(4);
                        string notiz = reader.GetString(5);
                        
                        // Reparatur als abgeschlossen markieren
                        sql = $@"UPDATE WerkzeugReparatur SET ReparaturEnde = GETDATE() WHERE Nr = {reparaturNr}";
                        await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                        
                        // Stillstand für Reparatur eintragen
                        string lizenz = await GetMaschineLizenzAsync(maschineNr, stoppingToken);
                        
                        if (!string.IsNullOrEmpty(lizenz))
                        {
                            sql = $@"INSERT INTO Stillstand (MaschineNr, StillstandNr, Kommt, Geht, Gebucht, Grund) 
                                    VALUES ((SELECT Nr FROM Maschinen WHERE Lizenz = '{lizenz}'), 
                                            101, '{S7MainServiceExtensions.FloatToPunktString(reparaturDatum)}', 
                                            GETDATE(), 1, 'Werkzeugreparatur {Werkzeug}: {Notiz}')";
                            await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                        }
                        
                        _logger.LogDebug("Werkzeugreparatur verarbeitet: Reparatur {ReparaturNr}, Werkzeug {Werkzeug}", 
                            reparaturNr, werkzeug);
                    }
                }
                
                _logger.LogDebug("WZReparatur completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in WZReparatur");
            }
        }
        
        /// <summary>
        /// Paletten-Rest berechnen
        /// Äquivalent zu TThread_Zusatz.Palette_Rest_Berechnen in Th_Zusatz.pas (Zeile 244)
        /// </summary>
        public async Task Palette_Rest_BerechnenAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("Palette_Rest_Berechnen started");
                
                // 1. Null-Werte in PDE aktualisieren
                string sql = "UPDATE PDE SET Istwert = 0 WHERE Istwert IS NULL";
                await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                
                sql = "UPDATE PDE SET Pack = 0 WHERE Pack IS NULL";
                await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                
                // 2. Paletten_Rest und Paletten_Soll berechnen (für MSSQL)
                sql = @"UPDATE PDE SET Paletten_Rest = 
                    CASE 
                        WHEN CAST(Sollwert AS int) - CAST(Pack AS int) < 0 THEN 0 
                        ELSE 
                            CASE 
                                WHEN PackGroesse * Palette = 0 THEN 0 
                                ELSE CAST((CAST(Sollwert AS int) - CAST(Pack AS int)) / PackGroesse / Palette + 0.4999 AS int) 
                            END 
                    END,
                    Paletten_Soll = 
                    CASE 
                        WHEN PackGroesse * Palette = 0 THEN 0 
                        ELSE CAST(CAST(Sollwert AS int) / PackGroesse / Palette + 0.4999 AS int) 
                    END";
                await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                
                // 3. Paletten_Rest in Maschinf aktualisieren
                sql = @"UPDATE Maschinf SET Paletten_Rest = 
                    (SELECT Paletten_Rest FROM PDE WHERE Maschinf.BetriebsAuftragNr = PDE.BetriebsAuftragNr)";
                await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                
                _logger.LogDebug("Palette_Rest_Berechnen completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in Palette_Rest_Berechnen");
            }
        }
    }
}
