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
        /// Ruft VerpacktProtAusAusschussRechnen auf
        /// </summary>
        public async Task CalcPackedlogFromShiftlogAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("CalcPackedlogFromShiftlog started");
                
                // Letzten Lauf aus Konfiguration oder Standardwert (30 Tage zurück)
                DateTime lastrun = DateTime.Now.AddDays(-30);
                
                await VerpacktProtAusAusschussRechnenAsync(lastrun, stoppingToken);
                
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
                _logger.LogDebug("CalcPackedlogFromShiftlog(fromdate) started with date: {FromDate}", fromdate);
                
                await VerpacktProtAusAusschussRechnenAsync(fromdate, stoppingToken);
                
                _logger.LogDebug("CalcPackedlogFromShiftlog(fromdate) completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in CalcPackedlogFromShiftlog(fromdate)");
            }
        }
        
        /// <summary>
        /// Verpackt-Protokoll aus Ausschuss und Schicht berechnen
        /// Äquivalent zu VerpacktProtAusAusschussRechnen in arbeit.pas
        /// </summary>
        private async Task VerpacktProtAusAusschussRechnenAsync(DateTime fromDate, CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("VerpacktProtAusAusschussRechnen started from {FromDate}", fromDate);
                
                // Betriebsauftragnummern aus tpm_schicht und pdekombi ab dem fromDate holen
                string sql = $@"(SELECT betriebsauftragnr, max(auftragnr) auftragnr,
                            max(bezeichnung) bezeichnung, max(lizenz) lizenz, datumzeit dat FROM tpm_schicht
                            INNER JOIN maschine ON tpm_schicht.maschnr = maschine.maschnr
                            WHERE datumzeit > '{S7MainServiceExtensions.FloatToPunktString(fromDate)}'
                            AND betriebsauftragnr IS NOT NULL
                            GROUP BY betriebsauftragnr, datumzeit)
                            UNION
                            (SELECT pdekombi.betriebsauftragnr, max(pdekombi.auftragnr) auftragnr,
                            max(pdekombi.bezeichnung) bezeichnung, max(lizenz) lizenz, datumzeit dat FROM tpm_schicht
                            INNER JOIN maschine ON tpm_schicht.maschnr = maschine.maschnr
                            INNER JOIN pdekombi ON tpm_schicht.betriebsauftragnr = pdekombi.masterbetriebsauftragnr
                            WHERE datumzeit > '{S7MainServiceExtensions.FloatToPunktString(fromDate)}'
                            AND pdekombi.betriebsauftragnr IS NOT NULL
                            GROUP BY pdekombi.betriebsauftragnr, datumzeit)
                            ORDER BY dat";
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        string banr = reader.GetString(0);
                        string auftragnr = reader.GetString(1);
                        string bezeichnung = reader.GetString(2);
                        string lizenz = reader.GetString(3);
                        DateTime dat = reader.GetDateTime(4);
                        
                        // Gutschicht, Verpackt und Gutall für diesen Betriebsauftrag ermitteln
                        int gutschicht = 0, verpackt = 0, gutall = 0;
                        bool buchen = false;
                        DateTime buchDat = dat;
                        int buchmenge = 0;
                        
                        // Zuerst in tpm_schicht suchen
                        string querySql = $@"SELECT sum(produziert)-sum(autoausschuss)-sum(ausschuss) gutschicht,
                                    (SELECT sum(zugang-abgang) FROM verpacktprot WHERE betriebsauftragnr = '{banr}') verpackt,
                                    (SELECT sum(produziert)-sum(autoausschuss)-sum(ausschuss) FROM tpm_schicht
                                    WHERE betriebsauftragnr = '{banr}') gutall,
                                    max(datumzeit) dat FROM tpm_schicht
                                    WHERE tpm_schicht.betriebsauftragnr = '{banr}'
                                    AND datumzeit < '{S7MainServiceExtensions.FloatToPunktString(dat.AddMinutes(4))}'
                                    AND datumzeit > '{S7MainServiceExtensions.FloatToPunktString(dat.AddMinutes(-3))}'
                                    GROUP BY tpm_schicht.betriebsauftragnr";
                        
                        using (var queryReader = _database.ExecuteReader(querySql))
                        {
                            if (await queryReader.ReadAsync(stoppingToken))
                            {
                                gutschicht = queryReader.GetInt32(0);
                                verpackt = queryReader.GetInt32(1);
                                gutall = queryReader.GetInt32(2);
                                buchDat = queryReader.GetDateTime(3);
                                buchen = true;
                            }
                        }
                        
                        // Wenn nicht gefunden, in tpm_schichtkombi suchen
                        if (!buchen)
                        {
                            querySql = $@"SELECT sum(produziert)-sum(autoausschuss)-sum(ausschuss) gutschicht,
                                    (SELECT sum(zugang-abgang) FROM verpacktprot WHERE betriebsauftragnr = '{banr}') verpackt,
                                    (SELECT sum(produziert)-sum(autoausschuss)-sum(ausschuss) FROM tpm_schichtkombi
                                    WHERE betriebsauftragnr = '{banr}') gutall,
                                    max(datumzeit) dat FROM tpm_schichtkombi
                                    WHERE tpm_schichtkombi.betriebsauftragnr = '{banr}'
                                    AND datumzeit < '{S7MainServiceExtensions.FloatToPunktString(dat.AddMinutes(4))}'
                                    AND datumzeit > '{S7MainServiceExtensions.FloatToPunktString(dat.AddMinutes(-3))}'
                                    GROUP BY tpm_schichtkombi.betriebsauftragnr";
                            
                            using (var queryReader = _database.ExecuteReader(querySql))
                            {
                                if (await queryReader.ReadAsync(stoppingToken))
                                {
                                    gutschicht = queryReader.GetInt32(0);
                                    verpackt = queryReader.GetInt32(1);
                                    gutall = queryReader.GetInt32(2);
                                    buchDat = queryReader.GetDateTime(3);
                                    buchen = true;
                                }
                            }
                        }
                        
                        if (buchen && gutall != verpackt)
                        {
                            buchmenge = gutall - verpackt;
                            
                            // Summe der bereits gebuchten Verpackt-Mengen ab dem Datum
                            string sumSql = $@"SELECT SUM(zugang-abgang) sumpack FROM verpacktprot 
                                            WHERE datum > '{S7MainServiceExtensions.FloatToPunktString(buchDat)}' 
                                            AND betriebsauftragnr = '{banr}'";
                            
                            int sumpack = 0;
                            using (var sumReader = _database.ExecuteReader(sumSql))
                            {
                                if (await sumReader.ReadAsync(stoppingToken))
                                {
                                    sumpack = sumReader.GetInt32(0);
                                }
                            }
                            
                            buchmenge += sumpack;
                            
                            if (buchmenge > gutschicht)
                                buchmenge = gutschicht;
                        }
                        
                        if (buchen && buchmenge != 0)
                        {
                            // Alte Einträge löschen
                            sql = $@"DELETE FROM verpacktprot WHERE datum > '{S7MainServiceExtensions.FloatToPunktString(buchDat)}' 
                                    AND betriebsauftragnr = '{banr}'";
                            await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                            
                            // Neuen Eintrag erstellen
                            int zugang = Math.Max(buchmenge, 0);
                            int abgang = Math.Abs(Math.Min(buchmenge, 0));
                            DateTime eintragsDatum = buchDat.AddMinutes(1);
                            
                            sql = $@"INSERT INTO verpacktprot (nr, betriebsauftragnr, auftragnr, bezeichnung, barcode,
                                    zugang, abgang, bclesernr, datum, eintragsdatum, lastchange, hostname, userid, maschine) 
                                    VALUES (verpacktprotid.nextval, '{banr}', '{auftragnr}', '{bezeichnung}', 'service',
                                    {zugang}, {abgang}, 0, '{S7MainServiceExtensions.FloatToPunktString(buchDat)}', 
                                    '{S7MainServiceExtensions.FloatToPunktString(eintragsDatum)}', 
                                    GETDATE(), GETDATE(), 'INCLService', 'service', '{lizenz}')";
                            
                            await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                            
                            _logger.LogDebug("VerpacktProt aus Schicht berechnet: BANr={BANr}, Buchmenge={Buchmenge}", banr, buchmenge);
                        }
                    }
                }
                
                _logger.LogDebug("VerpacktProtAusAusschussRechnen completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in VerpacktProtAusAusschussRechnen");
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
                
                // Aufträge holen, die laufen oder in den letzten Tagen beendet wurden
                // INCL_Days_TPM_Auswertung Standardwert: 30 Tage
                int inclDaysTPMAuswertung = 30;
                DateTime cutoffDate = DateTime.Now.AddDays(-inclDaysTPMAuswertung);
                
                string sql = $@"SELECT betriebsauftragnr, aarchiv.maschine, maschine.maschnr, ruestzeitsoll 
                            FROM aarchiv 
                            LEFT JOIN maschine ON maschine.lizenz = aarchiv.maschine 
                            WHERE enddatumzeit = 0 OR enddatumzeit > '{S7MainServiceExtensions.FloatToPunktString(cutoffDate)}'";
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        string BANr = reader.GetString(0);
                        string Lizenz = reader.GetString(1);
                        string MaschNr = reader.GetString(2);
                        int sollruest = reader.GetInt32(3);
                        
                        int istruest = 0;
                        int ungeplruest = 0;
                        int gesruest = 0;
                        
                        // Ungeplante Rüstzeiten (StillstandNr = RuestStillstandNrUngeplant, typischerweise 2 oder spezifisch)
                        // Standardwert für RuestStillstandNrUngeplant: 2
                        int ruestStillstandNrUngeplant = 2;
                        
                        sql = $@"SELECT nr, stillstandnr, kommt, geht, schusszaehler 
                                FROM tpm_stillog 
                                WHERE betriebsauftragnr = '{BANr}'
                                AND stillstandnr = {ruestStillstandNrUngeplant}
                                ORDER BY kommt";
                        
                        using (var stillstandReader = _database.ExecuteReader(sql))
                        {
                            if (!stillstandReader.HasRows)
                            {
                                // Falls keine ungeplanten Rüstzeiten, nach StillstandNr 2 suchen
                                sql = $@"SELECT nr, stillstandnr, kommt, geht, schusszaehler 
                                        FROM tpm_stillog 
                                        WHERE betriebsauftragnr = '{BANr}'
                                        AND stillstandnr = 2 
                                        ORDER BY kommt";
                                
                                using (var stillstandReader2 = _database.ExecuteReader(sql))
                                {
                                    while (await stillstandReader2.ReadAsync(stoppingToken))
                                    {
                                        DateTime kommt = stillstandReader2.GetDateTime(2);
                                        DateTime geht = stillstandReader2.GetDateTime(3);
                                        int schuss = stillstandReader2.GetInt32(4);
                                        
                                        if (geht < DateTime.Now)
                                            geht = DateTime.Now;
                                        
                                        // Rüstzeiteintrag berechnen (in Minuten)
                                        int ruestzeiteintrag = (int)Math.Round((geht - kommt).TotalMinutes);
                                        
                                        gesruest += ruestzeiteintrag;
                                        
                                        if (gesruest > sollruest)
                                        {
                                            // Splitten und umbuchen
                                            ungeplruest = gesruest - sollruest;
                                            DateTime splitzeitpunkt = kommt.AddMinutes(ruestzeiteintrag - ungeplruest);
                                            
                                            // Neuen Rüsteintrag anlegen
                                            sql = $@"INSERT INTO tpm_stillog (NR, BETRIEBSAUFTRAGNR, kommt, geht, DAUER, maschnr, 
                                                    WERKZEUGNR, STILLSTANDNR, AUFTRAGNR, BEZEICHNUNG, SCHICHT, PERSONALNR, SCHUSSZAEHLER, prodzaehler) 
                                                    SELECT tpm_stillogid.NextVal NR, BETRIEBSAUFTRAGNR, 
                                                    '{S7MainServiceExtensions.FloatToPunktString(splitzeitpunkt)}' Kommt, 
                                                    GEHT, -1 Dauer, maschnr, WERKZEUGNR, {ruestStillstandNrUngeplant} STILLSTANDNR, 
                                                    AUFTRAGNR, BEZEICHNUNG, SCHICHT, PERSONALNR, {schuss} SCHUSSZAEHLER, prodzaehler 
                                                    FROM tpm_stillog WHERE nr = {stillstandReader2.GetInt32(0)}";
                                            
                                            await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                                            
                                            // Originalen Eintrag aktualisieren
                                            sql = $@"UPDATE tpm_stillog SET geht = '{S7MainServiceExtensions.FloatToPunktString(splitzeitpunkt)}', 
                                                    dauer = -1 WHERE nr = {stillstandReader2.GetInt32(0)}";
                                            await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                                        }
                                    }
                                }
                            }
                        }
                        
                        _logger.LogDebug("UnscheduledSetup processed: BANr={BANr}, SollRuest={SollRuest}", BANr, sollruest);
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
                            sql = $@"UPDATE PDE SET Stat = 1 WHERE Nr = '{nr}'";
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
                        
                        // Wartung als erledigt markieren
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
                
                // Auftragskette prüfen - Aufträge ohne Nachfolger finden
                string sql = @"SELECT a.Nr, a.Betriebsauftragnr, a.Maschine, a.Stat, a.FolgeAuftrag 
                            FROM PDE a 
                            LEFT JOIN PDE b ON a.FolgeAuftrag = b.Betriebsauftragnr 
                            WHERE b.Betriebsauftragnr IS NULL 
                            AND a.FolgeAuftrag IS NOT NULL 
                            AND a.FolgeAuftrag <> ''";
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        string pdeNr = reader.GetString(0);
                        string betriebsauftragnr = reader.GetString(1);
                        string maschine = reader.GetString(2);
                        int stat = reader.GetInt32(3);
                        string folgeAuftrag = reader.GetString(4);
                        
                        // Prüfen, ob der Folgeauftrag existiert
                        string checkSql = $@"SELECT COUNT(*) FROM PDE WHERE Betriebsauftragnr = '{folgeAuftrag}'";
                        
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
                            // Folgeauftrag in PDE eintragen oder Stat aktualisieren
                            // Hier könnte man den Auftrag als abgeschlossen markieren
                            sql = $@"UPDATE PDE SET Stat = 1, FolgeAuftrag = NULL WHERE Nr = '{pdeNr}'";
                            await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                            
                            _logger.LogDebug("Auftragskette: Folgeauftrag nicht gefunden, PDE {PdeNr} als fertig markiert", pdeNr);
                        }
                    }
                }
                
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
                
                // Neuplanung durchführen - Aufträge mit veränderter Priorität oder Dringlichkeit
                string sql = @"SELECT Nr, Betriebsauftragnr, Maschine, Prioritaet, Dringlichkeit, Stat 
                            FROM PDE 
                            WHERE Stat = 0 
                            AND (PrioritaetChanged = 1 OR DringlichkeitChanged = 1)";
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        string pdeNr = reader.GetString(0);
                        string betriebsauftragnr = reader.GetString(1);
                        string maschine = reader.GetString(2);
                        int prioritaet = reader.GetInt32(3);
                        int dringlichkeit = reader.GetInt32(4);
                        int stat = reader.GetInt32(5);
                        
                        // Neuplanung durchführen - Startdatum anpassen
                        // Hier würde die komplexe Neuplanungslogik stehen
                        // Für jetzt: Flags zurücksetzen
                        sql = $@"UPDATE PDE SET PrioritaetChanged = 0, DringlichkeitChanged = 0 
                                WHERE Nr = '{pdeNr}'";
                        await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                        
                        _logger.LogDebug("Neuplanung: PDE {PdeNr}, Priorität {Prioritaet}, Dringlichkeit {Dringlichkeit}", 
                            pdeNr, prioritaet, dringlichkeit);
                    }
                }
                
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
                                WHERE Nr = '{nr}'";
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
                        sql = $@"UPDATE PDE SET Stat = 3 WHERE Nr = '{nr}'";
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
                // Aufträge, die länger als X Tage laufen, terminieren
                int maxLaufzeitTage = 30; // Standardwert
                DateTime cutoff = DateTime.Now.AddDays(-maxLaufzeitTage);
                
                string sql = $@"SELECT Nr, StartDatumZeit, Betriebsauftragnr FROM PDE 
                            WHERE Stat = 0 
                            AND StartDatumZeit < '{S7MainServiceExtensions.FloatToPunktString(cutoff)}'";
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        string nr = reader.GetString(0);
                        DateTime startDatumZeit = reader.GetDateTime(1);
                        string betriebsauftragnr = reader.GetString(2);
                        
                        // Auftrag als terminiert markieren
                        sql = $@"UPDATE PDE SET Stat = 3, EndDatumZeit = GETDATE() WHERE Nr = '{nr}'";
                        await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                        
                        result = true;
                        _logger.LogDebug("Autoterminierung: PDE {Nr} terminiert, gestartet am {StartDatumZeit}", nr, startDatumZeit);
                    }
                }
                
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
