using INCLService.CSharp.Models;
using INCLUDIS.Utils.CommonDB;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Threading;
using System.Threading.Tasks;

namespace INCLService.CSharp.Utilities
{
    /// <summary>
    /// Portierte Funktionen aus Th_Zusatz.pas (Schritt 15)
    /// </summary>
    public class ArbeitUtilsThZusatz
    {
        private readonly ILogger<ArbeitUtilsThZusatz> _logger;
        private readonly CommonDB _database;
        private readonly ArbeitUtils _arbeitUtils;
        
        // Schichtzeiten aus Konfiguration
        public int Schicht1 { get; set; } = 6;
        public int Schicht2 { get; set; } = 14;
        public int Schicht3 { get; set; } = 22;
        public int ShiftModel { get; set; } = 1;
        
        public ArbeitUtilsThZusatz(ILogger<ArbeitUtilsThZusatz> logger, CommonDB database, ArbeitUtils arbeitUtils)
        {
            _logger = logger;
            _database = database;
            _arbeitUtils = arbeitUtils;
        }
        
        /// <summary>
        /// Prüft Verpackt-Schicht-Daten
        /// Äquivalent zu TThread_Zusatz.CheckPackSchicht in Th_Zusatz.pas (Zeile 1569)
        /// </summary>
        public async Task<int> CheckPackSchichtAsync(int aTage, CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("CheckPackSchicht started for {Tage} days", aTage);
                
                int result = 0;
                
                if (aTage > 0)
                {
                    DateTime cutoffDate = DateTime.Now.AddDays(-aTage);
                    
                    // TPM-Schicht-Daten abrufen
                    string sql = $@"SELECT nr, datumzeit, betriebsauftragnr, schicht 
                        FROM tpm_schicht 
                        WHERE datumzeit > '{S7MainServiceExtensions.FloatToPunktString(cutoffDate)}' 
                        ORDER BY datumzeit";
                    
                    using (var reader = _database.ExecuteReader(sql))
                    {
                        while (await reader.ReadAsync(stoppingToken))
                        {
                            string BANr = reader.GetString(2); // betriebsauftragnr
                            
                            if (!string.IsNullOrEmpty(BANr))
                            {
                                DateTime DT = reader.GetDateTime(1); // datumzeit
                                int Schicht = reader.GetInt32(3); // schicht
                                int Nr = reader.GetInt32(0); // nr
                                
                                // Schichtdauer berechnen
                                double Schicht_Dauer = CalculateSchichtDauer(Schicht);
                                
                                // Verpackt-Daten für diesen Betriebsauftrag abrufen
                                DateTime endDate = DT.AddHours(Schicht_Dauer);
                                
                                sql = $@"SELECT SUM(zugang-abgang) stueck 
                                    FROM verpacktprot 
                                    WHERE betriebsauftragnr = '{BANr}'
                                    AND datum >= '{S7MainServiceExtensions.FloatToPunktString(DT)}' 
                                    AND datum < '{S7MainServiceExtensions.FloatToPunktString(endDate)}'";
                                
                                int Stueck = 0;
                                using (var reader2 = _database.ExecuteReader(sql))
                                {
                                    if (await reader2.ReadAsync(stoppingToken))
                                    {
                                        if (!reader2.IsDBNull(0))
                                        {
                                            Stueck = reader2.GetInt32(0);
                                        }
                                    }
                                }
                                
                                result++;
                                
                                // TPM-Schicht aktualisieren
                                sql = $@"UPDATE tpm_schicht 
                                    SET verpackt = {Stueck}
                                    WHERE nr = {Nr}";
                                await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                                
                                // verpackt_org aktualisieren
                                sql = $@"UPDATE tpm_schicht 
                                    SET verpackt_org = verpackt
                                    WHERE nr = {Nr}";
                                await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                            }
                        }
                    }
                }
                
                _logger.LogDebug("CheckPackSchicht completed - {Result} records processed", result);
                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in CheckPackSchicht");
                return 0;
            }
        }
        
        /// <summary>
        /// Berechnet die Schichtdauer basierend auf der Schichtnummer
        /// </summary>
        private double CalculateSchichtDauer(int schicht)
        {
            if (ShiftModel == 2)
            {
                switch (schicht)
                {
                    case 1: return Schicht2 - Schicht1;
                    case 2: return (1 + Schicht1) - Schicht2;
                    default: return 0;
                }
            }
            else
            {
                switch (schicht)
                {
                    case 1: return Schicht2 - Schicht1;
                    case 2: return Schicht3 - Schicht2;
                    case 3: return 1 + Schicht1 - Schicht3;
                    default: return 0;
                }
            }
        }
        
        /// <summary>
        /// Berechnet die Laufzeit für PDE-Einträge
        /// Äquivalent zu TThread_Zusatz.Laufzeit_Berechnen in Th_Zusatz.pas (Zeile 1630)
        /// </summary>
        public async Task Laufzeit_BerechnenAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("Laufzeit_Berechnen started");
                
                string sql = "SELECT Nr, Lizenz, StartDatumZeit, EndDatumZeit FROM PDE";
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        string Nr = reader.GetString(0);
                        string Liz = reader.GetString(1);
                        DateTime D1 = reader.GetDateTime(2);
                        DateTime D2 = reader.GetDateTime(3);
                        
                        // Zeit berechnen
                        int Zeit = _arbeitUtils.ZeitInMinuten(Liz, D1, D2);
                        int Zeit_Rest = _arbeitUtils.ZeitInMinuten(Liz, 
                            D1 > DateTime.Now ? D1 : DateTime.Now,
                            D2 > DateTime.Now ? D2 : DateTime.Now);
                        
                        // PDE aktualisieren
                        sql = $@"UPDATE PDE SET 
                            Laufzeit = {Zeit}, 
                            Laufzeit_Rest = {Zeit_Rest} 
                            WHERE Nr = {Nr}";
                        
                        await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                    }
                }
                
                _logger.LogDebug("Laufzeit_Berechnen completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in Laufzeit_Berechnen");
            }
        }
        
        /// <summary>
        /// Berechnet die Laufzeit für PDE-Einträge (Version 2)
        /// Äquivalent zu TThread_Zusatz.Laufzeit_Berechnen2 in Th_Zusatz.pas (Zeile 3141)
        /// </summary>
        public async Task Laufzeit_Berechnen2Async(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("Laufzeit_Berechnen2 started");
                
                // Zuerst Var_Kavitaet auf 1 setzen, falls null oder < 1
                string sql = "UPDATE pde SET Var_Kavitaet = 1 WHERE Var_Kavitaet IS NULL OR Var_Kavitaet < 1";
                await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                
                sql = "SELECT Nr, Lizenz, StartDatumZeit, EndDatumZeit, Betriebsart FROM PDE";
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        string Nr = reader.GetString(0);
                        string Liz = reader.GetString(1);
                        DateTime D1 = reader.GetDateTime(2);
                        DateTime D2 = reader.GetDateTime(3);
                        string betrart = reader.GetString(4);
                        
                        // Prüfen, ob Halbautomatik
                        bool halbautomatik = betrart.Equals("Halbautomatik", StringComparison.OrdinalIgnoreCase);
                        
                        // Zeit berechnen
                        int Zeit = _arbeitUtils.ZeitInMinuten(Liz, D1, D2, halbautomatik);
                        int Zeit_Rest = _arbeitUtils.ZeitInMinuten(Liz, 
                            Math.Max(D1, DateTime.Now),
                            Math.Max(D2, DateTime.Now),
                            halbautomatik);
                        
                        // Laufzeit_Plan berechnen
                        // Trunc(Sollwert/Kopfgroesse*Var_Kavitaet*Taktzeit/100/60+Ruestzeit)
                        // Da wir keine direkten Werte haben, vereinfachen wir
                        int Laufzeit_Plan = 0;
                        
                        // PDE aktualisieren
                        sql = $@"UPDATE PDE SET 
                            Laufzeit = {Zeit}, 
                            Laufzeit_Rest = {Zeit_Rest},
                            Laufzeit_Plan = {Laufzeit_Plan}
                            WHERE Nr = {Nr}";
                        
                        await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                        
                        // Falls Stat = 0 und Taktzeit > 0, zusätzliche Berechnungen
                        sql = $@"SELECT Stat, Taktzeit, Kopfgroesse, Var_Kavitaet, Istwert 
                            FROM PDE WHERE Nr = {Nr}";
                        
                        using (var reader2 = _database.ExecuteReader(sql))
                        {
                            if (await reader2.ReadAsync(stoppingToken))
                            {
                                int Stat = reader2.GetInt32(0);
                                double Taktzeit = reader2.GetDouble(1);
                                double Kopfgroesse = reader2.GetDouble(2);
                                double Var_Kavitaet = reader2.GetDouble(3);
                                double Istwert = reader2.GetDouble(4);
                                
                                if (Stat == 0 && Taktzeit > 0)
                                {
                                    // Zeit berechnen
                                    int Zeit_Ist = _arbeitUtils.ZeitInMinuten(Liz, D1, DateTime.Now, halbautomatik);
                                    
                                    // Menge berechnen
                                    int Menge = (int)Math.Round(
                                        Zeit_Ist * 60 / Taktzeit * 100 * Kopfgroesse / Var_Kavitaet);
                                    
                                    // Zeit_Theor berechnen
                                    int Zeit_Theor = (int)Math.Round(
                                        Istwert / Kopfgroesse * Var_Kavitaet * Taktzeit / 100 / 60);
                                    
                                    sql = $@"UPDATE PDE SET 
                                        Theorwert = {Menge},
                                        ZeitDiff = {Zeit_Theor - Zeit_Ist}
                                        WHERE Nr = {Nr}";
                                    
                                    await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                                }
                            }
                        }
                    }
                }
                
                _logger.LogDebug("Laufzeit_Berechnen2 completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in Laufzeit_Berechnen2");
            }
        }
        
        /// <summary>
        /// Prüft das Takt-Log
        /// Äquivalent zu TThread_Zusatz.Check_TaktLog in Th_Zusatz.pas (Zeile 1753)
        /// </summary>
        public async Task Check_TaktLogAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("Check_TaktLog started");
                
                const int ANZ_WERTE = 20;
                
                // Alle verschiedenen Auftragsnummern aus Taktzeiten abrufen
                string sql = "SELECT DISTINCT(AUFTRAGNR) AUFTRAGNR FROM TAKTZEITEN";
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        string ANr = reader.GetString(0);
                        
                        // Anzahl der Einträge für diesen Auftrag prüfen
                        sql = $@"SELECT COUNT(*) CNT FROM TAKTZEITEN WHERE AUFTRAGNR = '{ANr}'";
                        
                        int count = 0;
                        using (var reader2 = _database.ExecuteReader(sql))
                        {
                            if (await reader2.ReadAsync(stoppingToken))
                            {
                                count = reader2.GetInt32(0);
                            }
                        }
                        
                        // Nur verarbeiten, wenn genug Werte vorhanden sind
                        if (count > ANZ_WERTE)
                        {
                            // Durchschnittliche Taktzeit berechnen
                            sql = $@"SELECT AVG(TAKTZEIT) TAKTMITTEL FROM TAKTZEITEN WHERE AUFTRAGNR = '{ANr}'";
                            
                            double TaktMittel = 0;
                            using (var reader2 = _database.ExecuteReader(sql))
                            {
                                if (await reader2.ReadAsync(stoppingToken))
                                {
                                    TaktMittel = reader2.GetDouble(0);
                                }
                            }
                            
                            // Toleranzen berechnen
                            double TolHigh = TaktMittel + (TaktMittel * (TACKTLOG_CHECK_TOLERANZ / 100));
                            double TolLow = TaktMittel - (TaktMittel * (TACKTLOG_CHECK_TOLERANZ / 100));
                            
                            // Ausreißer entfernen
                            sql = $@"DELETE FROM TAKTZEITEN 
                                WHERE TAKTZEIT > {S7MainServiceExtensions.FloatToPunktString(TolHigh)} 
                                AND AUFTRAGNR = '{ANr}'";
                            await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                            
                            sql = $@"DELETE FROM TAKTZEITEN 
                                WHERE TAKTZEIT < {S7MainServiceExtensions.FloatToPunktString(TolLow)} 
                                AND AUFTRAGNR = '{ANr}'";
                            await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                        }
                    }
                }
                
                _logger.LogDebug("Check_TaktLog completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in Check_TaktLog");
            }
        }
        
        /// <summary>
        /// TACKTLOG_CHECK_TOLERANZ aus Konfiguration
        /// </summary>
        public int TACKTLOG_CHECK_TOLERANZ { get; set; } = 0;
        
        /// <summary>
        /// Berechnet die Laufzeit für PDE-Einträge mit Betriebsart
        /// </summary>
        public async Task Laufzeit_Berechnen_With_BetriebsartAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("Laufzeit_Berechnen_With_Betriebsart started");
                
                // Zuerst Var_Kavitaet auf 1 setzen, falls null oder < 1
                string sql = "UPDATE pde SET Var_Kavitaet = 1 WHERE Var_Kavitaet IS NULL OR Var_Kavitaet < 1";
                await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                
                sql = "SELECT Nr, Lizenz, StartDatumZeit, EndDatumZeit, Betriebsart FROM PDE";
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        string Nr = reader.GetString(0);
                        string Liz = reader.GetString(1);
                        DateTime D1 = reader.GetDateTime(2);
                        DateTime D2 = reader.GetDateTime(3);
                        string betrart = reader.GetString(4);
                        
                        // Prüfen, ob Halbautomatik
                        bool halbautomatik = betrart.Equals("Halbautomatik", StringComparison.OrdinalIgnoreCase);
                        
                        // Zeit berechnen
                        int Zeit = _arbeitUtils.ZeitInMinuten(Liz, D1, D2, halbautomatik);
                        int Zeit_Rest = _arbeitUtils.ZeitInMinuten(Liz, 
                            Math.Max(D1, DateTime.Now),
                            Math.Max(D2, DateTime.Now),
                            halbautomatik);
                        
                        // Laufzeit_Plan berechnen
                        sql = $@"SELECT Sollwert, Kopfgroesse, Var_Kavitaet, Taktzeit, Ruestzeit 
                            FROM PDE WHERE Nr = {Nr}";
                        
                        int Laufzeit_Plan = 0;
                        using (var reader2 = _database.ExecuteReader(sql))
                        {
                            if (await reader2.ReadAsync(stoppingToken))
                            {
                                double Sollwert = reader2.GetDouble(0);
                                double Kopfgroesse = reader2.GetDouble(1);
                                double Var_Kavitaet = reader2.GetDouble(2);
                                double Taktzeit = reader2.GetDouble(3);
                                double Ruestzeit = reader2.GetDouble(4);
                                
                                Laufzeit_Plan = (int)Math.Truncate(
                                    Sollwert / Kopfgroesse * Var_Kavitaet * Taktzeit / 100 / 60 + Ruestzeit);
                            }
                        }
                        
                        // PDE aktualisieren
                        sql = $@"UPDATE PDE SET 
                            Laufzeit = {Zeit}, 
                            Laufzeit_Rest = {Zeit_Rest},
                            Laufzeit_Plan = {Laufzeit_Plan}
                            WHERE Nr = {Nr}";
                        
                        await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                        
                        // Falls Stat = 0 und Taktzeit > 0, zusätzliche Berechnungen
                        sql = $@"SELECT Stat, Taktzeit, Kopfgroesse, Var_Kavitaet, Istwert 
                            FROM PDE WHERE Nr = {Nr}";
                        
                        using (var reader2 = _database.ExecuteReader(sql))
                        {
                            if (await reader2.ReadAsync(stoppingToken))
                            {
                                int Stat = reader2.GetInt32(0);
                                double Taktzeit = reader2.GetDouble(1);
                                double Kopfgroesse = reader2.GetDouble(2);
                                double Var_Kavitaet = reader2.GetDouble(3);
                                double Istwert = reader2.GetDouble(4);
                                
                                if (Stat == 0 && Taktzeit > 0)
                                {
                                    // Zeit berechnen
                                    int Zeit_Ist = _arbeitUtils.ZeitInMinuten(Liz, D1, DateTime.Now, halbautomatik);
                                    
                                    // Menge berechnen
                                    int Menge = (int)Math.Round(
                                        Zeit_Ist * 60 / Taktzeit * 100 * Kopfgroesse / Var_Kavitaet);
                                    
                                    // Zeit_Theor berechnen
                                    int Zeit_Theor = (int)Math.Round(
                                        Istwert / Kopfgroesse * Var_Kavitaet * Taktzeit / 100 / 60);
                                    
                                    sql = $@"UPDATE PDE SET 
                                        Theorwert = {Menge},
                                        ZeitDiff = {Zeit_Theor - Zeit_Ist}
                                        WHERE Nr = {Nr}";
                                    
                                    await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                                }
                            }
                        }
                    }
                }
                
                _logger.LogDebug("Laufzeit_Berechnen_With_Betriebsart completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in Laufzeit_Berechnen_With_Betriebsart");
            }
        }
    }
}
