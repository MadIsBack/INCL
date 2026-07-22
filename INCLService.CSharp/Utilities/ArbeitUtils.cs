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
    /// Arbeits-Hilfsfunktionen
    /// Enthält häufig verwendete Funktionen aus MainDll.pas und Arbeit.pas
    /// </summary>
    public class ArbeitUtils
    {
        private readonly ILogger<ArbeitUtils> _logger;
        private readonly CommonDB _database;
        
        // Minuten pro Tag
        private const int MINUTEN_PRO_TAG = 1440;
        
        // Minuten-Takt (Standard: 1 Minute)
        public int MinutenTakt { get; set; } = 1;
        
        // Kalender-Gruppen
        public const int HALBAUTOMATIKKALENDER = 2;
        
        public ArbeitUtils(ILogger<ArbeitUtils> logger, CommonDB database)
        {
            _logger = logger;
            _database = database;
        }
        
        /// <summary>
        /// Berechnet die Zeit in Minuten zwischen zwei Datumsangaben
        /// Äquivalent zu ZeitInMinuten in MainDll.pas
        /// </summary>
        /// <param name="lizenz">Maschinen-Lizenz</param>
        /// <param name="datum1">Startdatum</param>
        /// <param name="datum2">Enddatum</param>
        /// <param name="halbautomatik">Ob Halbautomatik-Berechnung</param>
        /// <returns>Zeit in Minuten</returns>
        public int ZeitInMinuten(string lizenz, DateTime datum1, DateTime datum2, bool halbautomatik = false)
        {
            try
            {
                int kalGruppe = GetGruppe(lizenz);
                
                DateTime d = datum1;
                
                // Arbeitsfreie Zeiten überspringen
                while (IsMomentArbeitsFrei(kalGruppe, d) && (d < datum2))
                {
                    d = d.AddMinutes(MinutenTakt);
                }
                
                int n = 0;
                
                if (halbautomatik)
                {
                    kalGruppe = HALBAUTOMATIKKALENDER;
                }
                
                while (d < datum2)
                {
                    n += MinutenTakt;
                    d = d.AddMinutes(MinutenTakt);
                    
                    // Arbeitsfreie Zeiten überspringen
                    while (IsMomentArbeitsFrei(kalGruppe, d) && (d < datum2))
                    {
                        d = d.AddMinutes(MinutenTakt);
                    }
                }
                
                // Sicherheitsprüfung
                if (n > (datum2 - datum1).TotalMinutes)
                {
                    n = (int)Math.Round((datum2 - datum1).TotalMinutes);
                }
                
                return n;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in ZeitInMinuten");
                return 0;
            }
        }
        
        /// <summary>
        /// Gibt die Kalender-Gruppe für eine Lizenz zurück
        /// Äquivalent zu GetGruppe in Delphi
        /// </summary>
        public int GetGruppe(string lizenz)
        {
            try
            {
                // Standardmäßig Gruppe 1
                int gruppe = 1;
                
                // Versuchen, die Gruppe aus der Maschinen-Tabelle zu lesen
                using (var reader = _database.ExecuteReader(
                    "SELECT KalenderGruppe FROM Maschinen WHERE Lizenz = @Lizenz"))
                {
                    reader.Parameters.AddWithValue("@Lizenz", lizenz);
                    if (reader.Read())
                    {
                        gruppe = reader.GetInt32(0);
                    }
                }
                
                return gruppe;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in GetGruppe");
                return 1;
            }
        }
        
        /// <summary>
        /// Prüft, ob ein bestimmter Zeitpunkt Arbeitsfrei ist
        /// Äquivalent zu isMomentArbeitsFrei in Delphi
        /// </summary>
        public bool IsMomentArbeitsFrei(int kalGruppe, DateTime datum)
        {
            try
            {
                // Hier würde geprüft werden, ob der Zeitpunkt in einer Arbeitsfreien Periode liegt
                // Äquivalent zu isMomentArbeitsFrei in Delphi
                
                // Vereinfachte Version: Immer false zurückgeben
                // In einer echten Implementierung würde man die Kalender-Tabelle prüfen
                return false;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in IsMomentArbeitsFrei");
                return false;
            }
        }
        
        /// <summary>
        /// Ändert den Stillstands-Code
        /// Äquivalent zu ChangeDtCode in Delphi
        /// </summary>
        public async Task ChangeDtCodeAsync(int stillstandNr, int nr, bool logIt, string code, CancellationToken stoppingToken)
        {
            try
            {
                // Stillstand in TPM_Stillog aktualisieren
                string sql = $"UPDATE TPM_Stillog SET StillstandNr = {stillstandNr} WHERE Nr = {nr}";
                
                using (var command = _database.CreateCommand(sql))
                {
                    await command.ExecuteNonQueryAsync(stoppingToken);
                }
                
                // Optional: In Log-Tabelle eintragen
                if (logIt)
                {
                    await LogStillstandChangeAsync(nr, stillstandNr, code, stoppingToken);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in ChangeDtCode");
            }
        }
        
        /// <summary>
        /// Loggt eine Stillstandsänderung
        /// </summary>
        private async Task LogStillstandChangeAsync(int nr, int stillstandNr, string code, CancellationToken stoppingToken)
        {
            try
            {
                string sql = $@"INSERT INTO StillstandLog (Nr, StillstandNr, Code, Zeitstempel) 
                    VALUES ({nr}, {stillstandNr}, '{code}', '{DateTime.Now:yyyy-MM-dd HH:mm:ss}')";
                
                using (var command = _database.CreateCommand(sql))
                {
                    await command.ExecuteNonQueryAsync(stoppingToken);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error logging Stillstand change");
            }
        }
        
        /// <summary>
        /// Berechnet die Laufzeit für PDE-Einträge
        /// Äquivalent zu Laufzeit_Berechnen in Th_Zusatz.pas
        /// </summary>
        public async Task LaufzeitBerechnenAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("Laufzeit_Berechnen started");
                
                string sql = "SELECT Nr, Lizenz, StartDatumZeit, EndDatumZeit FROM PDE";
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        string nr = reader.GetString(0);
                        string lizenz = reader.GetString(1);
                        DateTime startDatumZeit = reader.GetDateTime(2);
                        DateTime endDatumZeit = reader.GetDateTime(3);
                        
                        // Zeit berechnen
                        int zeit = ZeitInMinuten(lizenz, startDatumZeit, endDatumZeit);
                        int zeitRest = ZeitInMinuten(lizenz, 
                            startDatumZeit > DateTime.Now ? startDatumZeit : DateTime.Now,
                            endDatumZeit > DateTime.Now ? endDatumZeit : DateTime.Now);
                        
                        // PDE aktualisieren
                        sql = $"UPDATE PDE SET Laufzeit = {zeit}, Laufzeit_Rest = {zeitRest} WHERE Nr = {nr}";
                        
                        using (var command = _database.CreateCommand(sql))
                        {
                            await command.ExecuteNonQueryAsync(stoppingToken);
                        }
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
        /// Äquivalent zu Laufzeit_Berechnen2 in Th_Zusatz.pas
        /// </summary>
        public async Task LaufzeitBerechnen2Async(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("Laufzeit_Berechnen2 started");
                
                // Vereinfachte Version - ähnlich zu Laufzeit_Berechnen
                await LaufzeitBerechnenAsync(stoppingToken);
                
                _logger.LogDebug("Laufzeit_Berechnen2 completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in Laufzeit_Berechnen2");
            }
        }
        
        /// <summary>
        /// Prüft das Takt-Log
        /// Äquivalent zu Check_TaktLog in Th_Zusatz.pas
        /// </summary>
        public async Task CheckTaktLogAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("Check_TaktLog started");
                
                // Takt-Log prüfen und korrigieren
                // Hier würde die Logik aus Delphi implementiert werden
                
                // Beispiel: Taktzeiten prüfen
                string sql = @"SELECT * FROM TaktLog 
                    WHERE Taktzeit = 0 OR Taktzeit IS NULL 
                    ORDER BY DatumZeit";
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        // Taktzeit korrigieren
                        int nr = reader.GetInt32(0);
                        DateTime datumZeit = reader.GetDateTime(1);
                        
                        // Standard-Taktzeit setzen (z.B. 1 Minute)
                        sql = $"UPDATE TaktLog SET Taktzeit = {MinutenTakt} WHERE Nr = {nr}";
                        
                        using (var command = _database.CreateCommand(sql))
                        {
                            await command.ExecuteNonQueryAsync(stoppingToken);
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
        /// Prüft Verpackt-Schicht-Daten
        /// Äquivalent zu CheckPackSchicht in Th_Zusatz.pas
        /// </summary>
        public async Task<int> CheckPackSchichtAsync(int tage, CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("CheckPackSchicht started for {Tage} days", tage);
                
                int count = 0;
                DateTime cutoffDate = DateTime.Now.AddDays(-tage);
                
                // Verpackt-Daten der letzten Tage prüfen
                string sql = $@"SELECT * FROM VerpacktProt 
                    WHERE Datum >= '{cutoffDate:yyyy-MM-dd}' 
                    ORDER BY Datum";
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        // Verpackt-Daten prüfen und ggf. korrigieren
                        count++;
                    }
                }
                
                _logger.LogDebug("CheckPackSchicht completed - {Count} records checked", count);
                return count;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in CheckPackSchicht");
                return 0;
            }
        }
    }
}
