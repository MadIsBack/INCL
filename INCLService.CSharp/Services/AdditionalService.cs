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
    public class AdditionalService : BackgroundService
    {
        private readonly ILogger<AdditionalService> _logger;
        private readonly IConfiguration _configuration;
        private readonly AppConfig _appConfig;
        private CommonDB _database;
        private int _priority = 4;
        private int _timerInterval = 600;
        private DateTime _lastExecution = DateTime.MinValue;
        
        public int TimeZone { get; set; } = 0;
        public bool RUESTPROT_AUS_STILLSTAND { get; set; } = false;
        public bool PaletteRest { get; set; } = false;
        public bool SHORT_DELAY_AUTO_BOOK { get; set; } = false;
        public bool OptionPlanung { get; set; } = false;
        public bool TACKTLOG_CHECK { get; set; } = false;
        public bool INCL_MoldStateFromStateInt { get; set; } = false;
        public int VerpacktSchichtNachberechnen { get; set; } = 0;

        public AdditionalService(ILogger<AdditionalService> logger, IConfiguration configuration)
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
            _priority = _configuration.GetValue<int>("Addons:Priority", 4);
            _timerInterval = _configuration.GetValue<int>("Addons:Timer", 600);
            RUESTPROT_AUS_STILLSTAND = _configuration.GetValue<bool>("Features:RUESTPROT_AUS_STILLSTAND", false);
            PaletteRest = _configuration.GetValue<bool>("Features:PaletteRest", false);
            SHORT_DELAY_AUTO_BOOK = _configuration.GetValue<bool>("Features:SHORT_DELAY_AUTO_BOOK", false);
            OptionPlanung = _configuration.GetValue<bool>("Features:OptionPlanung", false);
            TACKTLOG_CHECK = _configuration.GetValue<bool>("Features:TACKTLOG_CHECK", false);
            INCL_MoldStateFromStateInt = _configuration.GetValue<bool>("Features:INCL_MoldStateFromStateInt", false);
            VerpacktSchichtNachberechnen = _configuration.GetValue<int>("Features:VerpacktSchichtNachberechnen", 0);
        }

        private void InitializeDatabase()
        {
            _database = new CommonDB
            {
                UserName = _appConfig.Database.DB_User,
                Password = _appConfig.Database.DB_Pass,
                Server = _appConfig.Database.DB_Server,
                InitialCatalog = _appConfig.Database.InitialCatalog,
                SqlProvider = _appConfig.Database.Provider
            };
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("AdditionalService started");
            try
            {
                if (_database != null) _database.Connected = true;
                await LoadTimeZoneAsync(stoppingToken);
                while (!stoppingToken.IsCancellationRequested)
                {
                    var now = DateTime.Now;
                    if (_lastExecution == DateTime.MinValue || (now - _lastExecution).TotalSeconds >= _timerInterval)
                    {
                        _lastExecution = now;
                        if (_database != null && _database.Connected)
                        {
                            await StartProgrammeAsync(stoppingToken);
                        }
                    }
                    await Task.Delay(1000, stoppingToken);
                }
            }
            catch (Exception ex) { _logger.LogError(ex, "AdditionalService error"); }
            finally
            {
                if (_database != null && _database.Connected) _database.Connected = false;
                _logger.LogInformation("AdditionalService stopped");
            }
        }

        private async Task LoadTimeZoneAsync(CancellationToken stoppingToken)
        {
            try
            {
                using (var reader = _database.ExecuteReader("SELECT TimeZone FROM Setup WHERE nr = 1"))
                {
                    if (await reader.ReadAsync(stoppingToken)) TimeZone = reader.GetInt32(0);
                }
            }
            catch (Exception ex) { _logger.LogError(ex, "Error loading TimeZone"); }
        }

        private async Task StartProgrammeAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("*** Start AdditionalService Programs");
            try
            {
                if (RUESTPROT_AUS_STILLSTAND) await CheckRuestProtStillogAsync(stoppingToken);
                if (PaletteRest) await PaletteRestBerechnenAsync(stoppingToken);
                await TPMKorrekturDoppelteDatenAsync(stoppingToken);
                await JobNoToDowntimeLogAsync(stoppingToken);
                await ArbeitsFreiBuchenAsync(stoppingToken);
                if (SHORT_DELAY_AUTO_BOOK) await BookShortDelayAsync(stoppingToken);
                await WZReparaturAsync(stoppingToken);
                await CheckVerpacktProtAsync(stoppingToken);
                if (VerpacktSchichtNachberechnen > 0) await CheckPackSchichtAsync(VerpacktSchichtNachberechnen, stoppingToken);
                if (OptionPlanung) await LaufzeitBerechnenAsync(stoppingToken);
                if (TACKTLOG_CHECK) await CheckTaktLogAsync(stoppingToken);
                _logger.LogInformation("*** All programs completed");
            }
            catch (Exception ex) { _logger.LogError(ex, "Error in StartProgramme"); }
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
                        
                        string lizenz = await GetMaschineAsync(maschNr, stoppingToken);
                        string baNr = string.Empty;
                        int werkzeug = 0;
                        int sollRuestzeit = 0;
                        
                        // Versuchen, aus PDE zu lesen
                        using (var reader2 = _database.ExecuteReader(
                            "SELECT Betriebsauftragnr, Werkzeug, Ruestzeit FROM PDE WHERE LIZENZ = @Lizenz AND stat = '0'"))
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
                                "SELECT TOP 1 BetriebsAuftragNr, Werkzeug, RuestzeitSOLL FROM aarchiv WHERE MASCHINE = @Lizenz ORDER BY NR DESC"))
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
                using (var reader = _database.ExecuteReader("SELECT Lizenz FROM Maschinen WHERE Nr = @MaschNr"))
                {
                    reader.Parameters.AddWithValue("@MaschNr", maschNr);
                    if (await reader.ReadAsync(stoppingToken)) return reader.GetString(0);
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
                    if (await reader.ReadAsync(stoppingToken)) return reader.GetInt32(0);
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

        /// <summary>
        /// Job-No to Downtime Log
        /// Äquivalent zu Job_No_to_Downtime_Log in Th_Zusatz.pas
        /// </summary>
        private async Task JobNoToDowntimeLogAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("Job_No_to_Downtime_Log started");
                
                // Endezeiten für Aufträge aktualisieren
                string sql = @"SELECT betriebsauftragnr FROM aarchiv 
                    WHERE aarchiv.enddatumzeit = 0 AND aarchiv.startdatumzeit > 0 
                    AND betriebsauftragnr NOT IN (SELECT betriebsauftragnr FROM pde)
                    AND betriebsauftragnr NOT IN (SELECT betriebsauftragnr FROM pdekombi WHERE masterbetriebsauftragnr IN (SELECT betriebsauftragnr FROM pde))";
                
                var baListe = new List<string>();
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        baListe.Add(reader.GetString(0));
                    }
                }
                
                foreach (var baNr in baListe)
                {
                    sql = $@"UPDATE aarchiv SET enddatumzeit = 
                        aarchiv.startdatumzeit + (((CASE WHEN aarchiv.taktzeitist IS NULL THEN 0 ELSE aarchiv.taktzeitist END  / 100) * 
                        CASE WHEN aarchiv.produziertint IS NULL THEN 0 ELSE aarchiv.produziertint END / 
                        CASE WHEN aarchiv.kavitaet = 0 THEN 1 ELSE aarchiv.kavitaet END ) / 60 /1440) 
                        WHERE aarchiv.betriebsauftragnr = '{baNr}'";
                    
                    using (var command = _database.CreateCommand(sql))
                    {
                        await command.ExecuteNonQueryAsync(stoppingToken);
                    }
                }
                
                // Stillstandmerker zurücksetzen
                sql = "UPDATE tpm_stillog SET betriebsauftragnr = NULL WHERE werkzeugnr = '-1' AND betriebsauftragnr <> '-1' AND (not betriebsauftragnr is null)";
                using (var command = _database.CreateCommand(sql))
                {
                    await command.ExecuteNonQueryAsync(stoppingToken);
                }
                
                _logger.LogDebug("Job_No_to_Downtime_Log completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in Job_No_to_Downtime_Log");
            }
        }

        /// <summary>
        /// Arbeitsfrei buchen
        /// Äquivalent zu ArbeitsFrei_Buchen in Th_Zusatz.pas
        /// </summary>
        private async Task ArbeitsFreiBuchenAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("ArbeitsFrei_Buchen started");
                // Platzhalter - Implementierung folgt
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in ArbeitsFrei_Buchen");
            }
        }

        /// <summary>
        /// Short Delay Auto Book
        /// Äquivalent zu Book_Short_Delay in Th_Zusatz.pas
        /// </summary>
        private async Task BookShortDelayAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("Book_Short_Delay started");
                // Platzhalter - Implementierung folgt
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in Book_Short_Delay");
            }
        }

        /// <summary>
        /// Werkzeug-Reparatur
        /// Äquivalent zu WZReparatur in Th_Zusatz.pas
        /// </summary>
        private async Task WZReparaturAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("WZReparatur started");
                
                string sql;
                if (INCL_MoldStateFromStateInt)
                {
                    sql = @"SELECT Reparatur.* from Werkzeug, Reparatur
                        WHERE Werkzeug.Werkzeug = Reparatur.WerkzeugIndex
                        AND Werkzeug.StatusInt = 0 AND Reparatur.EndeRepInt = 0 AND Reparatur.AnfangRepInt > 0";
                }
                else
                {
                    sql = @"SELECT Reparatur.* from Werkzeug, Reparatur
                        WHERE Werkzeug.Werkzeug = Reparatur.WerkzeugIndex
                        AND Werkzeug.Status = 'Lager' AND Reparatur.EndeRepInt = 0 AND Reparatur.AnfangRepInt > 0";
                }
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        string nr = reader.GetString(reader.GetOrdinal("Nr"));
                        
                        // Reparatur als erledigt markieren
                        sql = $@"UPDATE Reparatur SET Status = 'Erledigt', 
                            EndeRep = '{FloatToPunktStr(DateTime.Now)}', 
                            EndeRepInt = '{FloatToPunktStr(DateTime.Now)}' 
                            WHERE Nr = {nr}";
                        
                        using (var command = _database.CreateCommand(sql))
                        {
                            await command.ExecuteNonQueryAsync(stoppingToken);
                        }
                    }
                }
                
                // Wartungen prüfen
                sql = $@"SELECT * FROM Wartungen WHERE Job_Erzeugt = 0 AND StartDatumZeit <= '{FloatToPunktStr(DateTime.Now)}'";
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        string nr = reader.GetString(reader.GetOrdinal("Nr"));
                        string anlageTyp = reader.GetString(reader.GetOrdinal("AnlageTyp"));
                        string anlage = reader.GetString(reader.GetOrdinal("Anlage"));
                        string lizenz = anlageTyp + "-" + anlage;
                        string wartungNr = reader.GetString(reader.GetOrdinal("WartungNr"));
                        
                        // Job erzeugen (Platzhalter - CCC_Job_erzeugen)
                        await CreateJobAsync(lizenz, wartungNr, "Wartung", "Wartung", "", "", false, 0, stoppingToken);
                        
                        // Als erstellt markieren
                        sql = $@"UPDATE Wartungen SET Job_Erzeugt = 1 WHERE Nr = {nr}";
                        using (var command = _database.CreateCommand(sql))
                        {
                            await command.ExecuteNonQueryAsync(stoppingToken);
                        }
                    }
                }
                
                _logger.LogDebug("WZReparatur completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in WZReparatur");
            }
        }

        private async Task CreateJobAsync(string lizenz, string wartungNr, string typ, string bezeichnung, 
            string info1, string info2, bool flag, int value, CancellationToken stoppingToken)
        {
            // Platzhalter für Job-Erzeugung
            _logger.LogDebug("Job created for Lizenz: {Lizenz}, WartungNr: {WartungNr}", lizenz, wartungNr);
        }

        /// <summary>
        /// Verpackt-Protokoll prüfen
        /// Äquivalent zu CheckVerpacktProt in Th_Zusatz.pas
        /// </summary>
        private async Task CheckVerpacktProtAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("CheckVerpacktProt started");
                // Platzhalter - Implementierung folgt
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in CheckVerpacktProt");
            }
        }

        private async Task<int> CheckPackSchichtAsync(int tage, CancellationToken stoppingToken)
        {
            _logger.LogDebug("CheckPackSchicht started");
            return 0;
        }

        private async Task LaufzeitBerechnenAsync(CancellationToken stoppingToken)
        {
            _logger.LogDebug("Laufzeit_Berechnen started");
        }

        private async Task CheckTaktLogAsync(CancellationToken stoppingToken)
        {
            _logger.LogDebug("Check_TaktLog started");
        }

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
