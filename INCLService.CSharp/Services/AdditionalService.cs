using INCLService.CSharp.Models;
using INCLUDIS.Utils.CommonDB;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Threading;
using System.Threading.Tasks;

namespace INCLService.CSharp.Services
{
    /// <summary>
    /// Service für zusätzliche Funktionen
    /// Äquivalent zu TThread_Zusatz in Delphi (Th_Zusatz.pas)
    /// </summary>
    public class AdditionalService : BackgroundService
    {
        private readonly ILogger<AdditionalService> _logger;
        private readonly IConfiguration _configuration;
        private readonly AppConfig _appConfig;
        
        private CommonDB _database;
        private int _priority = 4; // Default: tpNormal
        private int _timerInterval = 600; // Sekunden (10 Minuten)
        private DateTime _lastExecution = DateTime.MinValue;
        private DateTime _lastDate = DateTime.MinValue;
        
        // Konfigurationseinstellungen aus Setup
        public int TimeZone { get; set; } = 0;
        public bool RUESTPROT_AUS_STILLSTAND { get; set; } = false;
        public bool PaletteRest { get; set; } = false;
        public bool SHORT_DELAY_AUTO_BOOK { get; set; } = false;
        public bool OptionPlanung { get; set; } = false;
        public bool TACKTLOG_CHECK { get; set; } = false;
        public bool VerpacktProtAusSchichtausschuss { get; set; } = false;
        public bool VerpacktProtAusAarchivUndAusschussProt { get; set; } = false;
        public int VerpacktSchichtNachberechnen { get; set; } = 0;
        
        public AdditionalService(
            ILogger<AdditionalService> logger,
            IConfiguration configuration)
        {
            _logger = logger;
            _configuration = configuration;
            
            _appConfig = new AppConfig();
            _configuration.GetSection("Database").Bind(_appConfig.Database);
            _configuration.GetSection("Main").Bind(_appConfig.Main);
            
            LoadConfiguration();
            InitializeDatabase();
        }

        private void LoadConfiguration()
        {
            try
            {
                // Priorität aus Konfiguration laden
                _priority = _configuration.GetValue<int>("Addons:Priority", 4);
                _timerInterval = _configuration.GetValue<int>("Addons:Timer", 600);
                
                // Feature-Flags aus Konfiguration
                RUESTPROT_AUS_STILLSTAND = _configuration.GetValue<bool>("Features:RUESTPROT_AUS_STILLSTAND", false);
                PaletteRest = _configuration.GetValue<bool>("Features:PaletteRest", false);
                SHORT_DELAY_AUTO_BOOK = _configuration.GetValue<bool>("Features:SHORT_DELAY_AUTO_BOOK", false);
                OptionPlanung = _configuration.GetValue<bool>("Features:OptionPlanung", false);
                TACKTLOG_CHECK = _configuration.GetValue<bool>("Features:TACKTLOG_CHECK", false);
                VerpacktProtAusSchichtausschuss = _configuration.GetValue<bool>("Features:VerpacktProtAusSchichtausschuss", false);
                VerpacktProtAusAarchivUndAusschussProt = _configuration.GetValue<bool>("Features:VerpacktProtAusAarchivUndAusschussProt", false);
                VerpacktSchichtNachberechnen = _configuration.GetValue<int>("Features:VerpacktSchichtNachberechnen", 0);
                
                _logger.LogInformation("AdditionalService configured - Priority: {Priority}, Timer: {Timer}s",
                    _priority, _timerInterval);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error loading AdditionalService configuration");
            }
        }

        private void InitializeDatabase()
        {
            try
            {
                _database = new CommonDB
                {
                    UserName = _appConfig.Database.DB_User,
                    Password = _appConfig.Database.DB_Pass,
                    Server = _appConfig.Database.DB_Server,
                    InitialCatalog = _appConfig.Database.InitialCatalog,
                    SqlProvider = _appConfig.Database.Provider
                };
                
                _logger.LogInformation("AdditionalService database initialized");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error initializing AdditionalService database");
            }
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("AdditionalService started with priority {Priority}", _priority);
            
            try
            {
                // Datenbankverbindung herstellen
                if (_database != null)
                {
                    try
                    {
                        _database.Connected = true;
                        _logger.LogInformation("AdditionalService database connected");
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Error connecting AdditionalService database");
                    }
                }
                
                // Zeitzone laden
                await LoadTimeZoneAsync(stoppingToken);
                
                while (!stoppingToken.IsCancellationRequested)
                {
                    // Prüfen, ob es Zeit für die nächste Ausführung ist
                    var now = DateTime.Now;
                    var timeSinceLastExecution = now - _lastExecution;
                    
                    if (_lastExecution == DateTime.MinValue || 
                        timeSinceLastExecution.TotalSeconds >= _timerInterval)
                    {
                        _lastExecution = now;
                        await ExecuteAdditionalTasksAsync(stoppingToken);
                    }
                    
                    // Kurze Pause, um CPU zu schonen
                    await Task.Delay(1000, stoppingToken);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "AdditionalService terminated unexpectedly");
            }
            finally
            {
                // Datenbankverbindung schließen
                if (_database != null && _database.Connected)
                {
                    try
                    {
                        _database.Connected = false;
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Error disconnecting AdditionalService database");
                    }
                }
                _logger.LogInformation("AdditionalService stopped");
            }
        }

        private async Task LoadTimeZoneAsync(CancellationToken stoppingToken)
        {
            try
            {
                using (var reader = _database.ExecuteReader("SELECT TimeZone FROM Setup WHERE nr = 1"))
                {
                    if (await reader.ReadAsync(stoppingToken))
                    {
                        TimeZone = reader.GetInt32(0);
                        _logger.LogInformation("TimeZone loaded: {TimeZone}", TimeZone);
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error loading TimeZone");
            }
        }

        private async Task ExecuteAdditionalTasksAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("Executing additional tasks...");
                
                if (_database == null || !_database.Connected)
                {
                    _logger.LogWarning("Database not connected, skipping additional tasks");
                    return;
                }
                
                // Datenbankverbindung prüfen
                if (!await CheckDatabaseConnectionAsync(stoppingToken))
                {
                    return;
                }
                
                // Hauptprogramm ausführen (wie StartProgramme in Delphi)
                await StartProgrammeAsync(stoppingToken);
                
                _logger.LogDebug("Additional tasks executed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error executing additional tasks");
            }
        }

        private async Task<bool> CheckDatabaseConnectionAsync(CancellationToken stoppingToken)
        {
            try
            {
                if (_database == null || !_database.Connected)
                {
                    _logger.LogWarning("Database not connected, retrying...");
                    
                    for (int i = 0; i < 10; i++)
                    {
                        if (stoppingToken.IsCancellationRequested)
                        {
                            return false;
                        }
                        
                        await Task.Delay(1000, stoppingToken);
                        
                        try
                        {
                            if (_database != null)
                            {
                                _database.Connected = false;
                                _database.Connected = true;
                            }
                        }
                        catch (Exception ex)
                        {
                            _logger.LogError(ex, "Error reconnecting database");
                        }
                    }
                    
                    return _database != null && _database.Connected;
                }
                
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error checking database connection");
                return false;
            }
        }

        /// <summary>
        /// Startet alle zusätzlichen Programme
        /// Äquivalent zu StartProgramme in Th_Zusatz.pas
        /// </summary>
        private async Task StartProgrammeAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogInformation("*** Start AdditionalService Programs");
                
                // Step 1: Rüstprotokoll aus Stillstandslog
                if (RUESTPROT_AUS_STILLSTAND)
                {
                    _logger.LogInformation("Step 1: CheckRuestProt_Stillog");
                    await CheckRuestProtStillogAsync(stoppingToken);
                }
                
                // Step 2: Paletten-Rest berechnen
                if (PaletteRest)
                {
                    _logger.LogInformation("Step 2: Palette_Rest_Berechnen");
                    await PaletteRestBerechnenAsync(stoppingToken);
                }
                
                // Step 3: TPM-Korrektur für doppelte Daten
                _logger.LogInformation("Step 3: TPM_Korrektur_Doppelte_Daten");
                await TPMKorrekturDoppelteDatenAsync(stoppingToken);
                
                // Step 4: Job-No to Downtime Log
                _logger.LogInformation("Step 4: Job_No_to_Downtime_Log");
                await JobNoToDowntimeLogAsync(stoppingToken);
                
                // Step 5: Arbeitsfrei buchen
                _logger.LogInformation("Step 5: ArbeitsFrei_Buchen");
                await ArbeitsFreiBuchenAsync(stoppingToken);
                
                // Step 5a: Short Delay Auto Book
                if (SHORT_DELAY_AUTO_BOOK)
                {
                    _logger.LogInformation("Step 5a: Book_Short_Delay");
                    await BookShortDelayAsync(stoppingToken);
                }
                
                // Step 6: Werkzeug-Reparatur
                _logger.LogInformation("Step 6: WZReparatur");
                await WZReparaturAsync(stoppingToken);
                
                // Step 7: Verpackt-Protokoll prüfen
                _logger.LogInformation("Step 7: CheckVerpacktProt");
                await CheckVerpacktProtAsync(stoppingToken);
                
                // Step 7.1: Verpackt Schicht Nachberechnen
                if (VerpacktSchichtNachberechnen > 0)
                {
                    _logger.LogInformation("Step 7.1: CheckPackSchicht");
                    int result = await CheckPackSchichtAsync(VerpacktSchichtNachberechnen, stoppingToken);
                    _logger.LogInformation("Step 7.1 Result: {Result}", result);
                }
                
                // Step 8: Laufzeit berechnen
                if (OptionPlanung)
                {
                    _logger.LogInformation("Step 8: Laufzeit_Berechnen");
                    await LaufzeitBerechnenAsync(stoppingToken);
                }
                
                // Step 9: Takt-Log prüfen
                if (TACKTLOG_CHECK)
                {
                    _logger.LogInformation("Step 9: Check_TaktLog");
                    await CheckTaktLogAsync(stoppingToken);
                }
                
                _logger.LogInformation("*** All AdditionalService Programs completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in StartProgramme");
            }
        }

        /// <summary>
        /// Prüft Stillstände der Gruppe RÜSTEN und verbucht sie im Rüstzeitprotokoll
        /// Äquivalent zu CheckRuestProt_Stillog in Th_Zusatz.pas
        /// </summary>
        private async Task CheckRuestProtStillogAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("CheckRuestProt_Stillog started");
                
                string sql = @"SELECT Nr, Kommt, Geht, stillstandnr, userid, hostname, lastchange, MASCHNR 
                    FROM tpm_stillog, tpm_stillstaende 
                    WHERE tpm_stillog.STILLSTANDNR = tpm_stillstaende.STILLSTANDNR 
                    AND tpm_stillstaende.GRUPPE = 1 
                    AND tpm_stillog.RUESTPROT = 0 
                    AND tpm_stillog.geht > 0";
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        string nr = reader.GetString(0);
                        DateTime kommt = reader.GetDateTime(1);
                        DateTime geht = reader.GetDateTime(2);
                        string grund = reader.GetString(3);
                        int userid = reader.GetInt32(4);
                        string hostname = reader.GetString(5);
                        DateTime lastchange = reader.GetDateTime(6);
                        int maschNr = reader.GetInt32(7);
                        
                        // Lizenz (Maschinenname) ermitteln
                        string lizenz = await GetMaschineAsync(maschNr, stoppingToken);
                        
                        // Betriebsauftragsnummer und Werkzeug ermitteln
                        string baNr = string.Empty;
                        int werkzeug = 0;
                        int sollRuestzeit = 0;
                        
                        using (var reader2 = _database.ExecuteReader(
                            "SELECT Betriebsauftragnr, Werkzeug, Ruestzeit FROM PDE WHERE LIZENZ = @Lizenz AND stat = '0'",
                            System.Data.CommandType.Text))
                        {
                            reader2.Parameters.AddWithValue("@Lizenz", lizenz);
                            if (await reader2.ReadAsync(stoppingToken))
                            {
                                baNr = reader2.GetString(0);
                                werkzeug = reader2.GetInt32(1);
                                sollRuestzeit = reader2.GetInt32(2);
                            }
                        }
                        
                        // Falls nicht gefunden, aus Archiv
                        if (string.IsNullOrEmpty(baNr))
                        {
                            using (var reader3 = _database.ExecuteReader(
                                "SELECT TOP 1 BetriebsAuftragNr, Werkzeug, RuestzeitSOLL FROM aarchiv WHERE MASCHINE = @Lizenz ORDER BY NR DESC",
                                System.Data.CommandType.Text))
                            {
                                reader3.Parameters.AddWithValue("@Lizenz", lizenz);
                                if (await reader3.ReadAsync(stoppingToken))
                                {
                                    baNr = reader3.GetString(0);
                                    werkzeug = reader3.GetInt32(1);
                                    sollRuestzeit = reader3.GetInt32(2);
                                }
                            }
                        }
                        
                        // In Rüstprotokoll eintragen
                        await InsertRuestProtAsync(nr, baNr, kommt, geht, grund, lizenz, werkzeug, 
                            sollRuestzeit, userid, hostname, lastchange, stoppingToken);
                        
                        // Stillstandmerker zurücksetzen
                        using (var command = _database.CreateCommand())
                        {
                            command.CommandText = "UPDATE tpm_stillog SET RUESTPROT = 1 WHERE Nr = @Nr";
                            command.Parameters.AddWithValue("@Nr", nr);
                            await command.ExecuteNonQueryAsync(stoppingToken);
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

        private async Task<string> GetMaschineAsync(int maschNr, CancellationToken stoppingToken)
        {
            try
            {
                using (var reader = _database.ExecuteReader(
                    "SELECT Lizenz FROM Maschinen WHERE Nr = @MaschNr",
                    System.Data.CommandType.Text))
                {
                    reader.Parameters.AddWithValue("@MaschNr", maschNr);
                    if (await reader.ReadAsync(stoppingToken))
                    {
                        return reader.GetString(0);
                    }
                }
                return "UNKNOWN";
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting Maschine");
                return "UNKNOWN";
            }
        }

        private async Task InsertRuestProtAsync(string nr, string baNr, DateTime kommt, DateTime geht, 
            string grund, string lizenz, int werkzeug, int sollRuestzeit, 
            int userid, string hostname, DateTime lastchange, CancellationToken stoppingToken)
        {
            try
            {
                // Neue Rüstprotokoll-Nummer generieren
                int nextVal = await GetNextRuestProtNrAsync(stoppingToken);
                
                string sql = $@"INSERT INTO RuestProt 
                    (Nr, BetriebsAuftragNr, Name, RuestStart, RuestEnde, RuestIst, Grund, 
                     RuestSoll, Lizenz, Werkzeug, userid, hostname, lastchange) 
                    VALUES ({nextVal}, '{baNr}', '', '{FloatToPunktStr(kommt)}', 
                    '{FloatToPunktStr(geht)}', -1, '{grund}', {sollRuestzeit}, '{lizenz}', 
                    {werkzeug}, {userid}, '{hostname}', '{FloatToPunktStr(lastchange)}')";
                
                using (var command = _database.CreateCommand(sql))
                {
                    await command.ExecuteNonQueryAsync(stoppingToken);
                }
                
                _logger.LogDebug("Rüstprotokoll Eintrag {Nr} erstellt", nextVal);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error inserting Rüstprotokoll");
            }
        }

        private async Task<int> GetNextRuestProtNrAsync(CancellationToken stoppingToken)
        {
            try
            {
                using (var reader = _database.ExecuteReader("SELECT ISNULL(MAX(Nr), 0) + 1 FROM RuestProt"))
                {
                    if (await reader.ReadAsync(stoppingToken))
                    {
                        return reader.GetInt32(0);
                    }
                }
                return 1;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting next Rüstprotokoll number");
                return 1;
            }
        }

        /// <summary>
        /// Berechnet Paletten-Rest
        /// Äquivalent zu Palette_Rest_Berechnen in Th_Zusatz.pas
        /// </summary>
        private async Task PaletteRestBerechnenAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("Palette_Rest_Berechnen started");
                
                // NULL-Werte auf 0 setzen
                using (var command = _database.CreateCommand("UPDATE PDE SET Istwert = 0 WHERE Istwert IS NULL"))
                {
                    await command.ExecuteNonQueryAsync(stoppingToken);
                }
                
                using (var command = _database.CreateCommand("UPDATE PDE SET Pack = 0 WHERE Pack IS NULL"))
                {
                    await command.ExecuteNonQueryAsync(stoppingToken);
                }
                
                // Paletten_Rest berechnen (SQL Server Version)
                string sql = @"UPDATE pde SET Paletten_Rest = 
                    CASE WHEN CAST(Sollwert AS int)-CAST(Pack AS int) < 0 then 0 
                    ELSE CASE WHEN PackGroesse*Palette =0 THEN 0 
                    ELSE CAST((CAST(Sollwert AS int)-CAST(Pack AS int))/PackGroesse/Palette+0.4999 AS int) END END";
                
                using (var command = _database.CreateCommand(sql))
                {
                    await command.ExecuteNonQueryAsync(stoppingToken);
                }
                
                sql = @"UPDATE pde SET Paletten_Soll = 
                    CASE WHEN PackGroesse*Palette =0 THEN 0 
                    ELSE CAST(CAST(Sollwert AS int)/PackGroesse/Palette+0.4999 AS int) END";
                
                using (var command = _database.CreateCommand(sql))
                {
                    await command.ExecuteNonQueryAsync(stoppingToken);
                }
                
                // Paletten_Rest in Maschinf aktualisieren
                sql = "UPDATE Maschinf SET Paletten_Rest = (SELECT Paletten_Rest FROM PDE WHERE Maschinf.BetriebsAuftragNr = PDE.BetriebsAuftragNr)";
                using (var command = _database.CreateCommand(sql))
                {
                    await command.ExecuteNonQueryAsync(stoppingToken);
                }
                
                _logger.LogDebug("Palette_Rest_Berechnen completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in Palette_Rest_Berechnen");
            }
        }

        /// <summary>
        /// Korrigiert doppelte Daten in TPM_Schicht
        /// Äquivalent zu TPM_Korrektur_Doppelte_Daten in Th_Zusatz.pas
        /// </summary>
        private async Task TPMKorrekturDoppelteDatenAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("TPM_Korrektur_Doppelte_Daten started");
                
                string sql = @"SELECT maschnr, datum, schicht, BETRIEBSAUFTRAGNR, count(*) CNT 
                    FROM tpm_schicht 
                    GROUP BY maschnr, datum, schicht, BETRIEBSAUFTRAGNR 
                    HAVING count(*) > 1";
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        int maschNr = reader.GetInt32(0);
                        DateTime datum = reader.GetDateTime(1);
                        int schicht = reader.GetInt32(2);
                        string betriebsauftragNr = reader.GetString(3);
                        
                        // Alle doppelten Einträge außer dem mit der höchsten Nr löschen
                        sql = $@"DELETE FROM TPM_Schicht 
                            WHERE maschnr = {maschNr} 
                            AND datum = '{FloatToPunktStr(datum)}' 
                            AND schicht = {schicht} 
                            AND BETRIEBSAUFTRAGNR = '{betriebsauftragNr}' 
                            AND Nr <> (SELECT MAX(NR) FROM TPM_Schicht 
                                WHERE maschnr = {maschNr} 
                                AND datum = '{FloatToPunktStr(datum)}' 
                                AND schicht = {schicht} 
                                AND BETRIEBSAUFTRAGNR = '{betriebsauftragNr}')";
                        
                        using (var command = _database.CreateCommand(sql))
                        {
                            await command.ExecuteNonQueryAsync(stoppingToken);
                        }
                    }
                }
                
                _logger.LogDebug("TPM_Korrektur_Doppelte_Daten completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in TPM_Korrektur_Doppelte_Daten");
            }
        }

        // Platzhalter für weitere Methoden
        private async Task JobNoToDowntimeLogAsync(CancellationToken stoppingToken)
        {
            _logger.LogDebug("Job_No_to_Downtime_Log - Not implemented yet");
        }

        private async Task ArbeitsFreiBuchenAsync(CancellationToken stoppingToken)
        {
            _logger.LogDebug("ArbeitsFrei_Buchen - Not implemented yet");
        }

        private async Task BookShortDelayAsync(CancellationToken stoppingToken)
        {
            _logger.LogDebug("Book_Short_Delay - Not implemented yet");
        }

        private async Task WZReparaturAsync(CancellationToken stoppingToken)
        {
            _logger.LogDebug("WZReparatur - Not implemented yet");
        }

        private async Task CheckVerpacktProtAsync(CancellationToken stoppingToken)
        {
            _logger.LogDebug("CheckVerpacktProt - Not implemented yet");
        }

        private async Task<int> CheckPackSchichtAsync(int tage, CancellationToken stoppingToken)
        {
            _logger.LogDebug("CheckPackSchicht - Not implemented yet");
            return 0;
        }

        private async Task LaufzeitBerechnenAsync(CancellationToken stoppingToken)
        {
            _logger.LogDebug("Laufzeit_Berechnen - Not implemented yet");
        }

        private async Task CheckTaktLogAsync(CancellationToken stoppingToken)
        {
            _logger.LogDebug("Check_TaktLog - Not implemented yet");
        }

        /// <summary>
        /// Konvertiert einen DateTime-Wert in einen String mit Punkt als Dezimaltrennzeichen
        /// </summary>
        private string FloatToPunktStr(DateTime dateTime)
        {
            return dateTime.ToString("yyyy-MM-dd HH:mm:ss", CultureInfo.InvariantCulture);
        }

        public override async Task StopAsync(CancellationToken cancellationToken)
        {
            _logger.LogInformation("AdditionalService stopping...");
            await base.StopAsync(cancellationToken);
        }
    }
}
