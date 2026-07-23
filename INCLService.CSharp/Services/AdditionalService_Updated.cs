using INCLService.CSharp.Models;
using INCLService.CSharp.Utilities;
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
    /// Zusätzliche Funktionen - Äquivalent zu TThread_Zusatz in Th_Zusatz.pas
    /// Schritt 17: Integration aller Th_Zusatz-Funktionen
    /// </summary>
    public class AdditionalService : BackgroundService
    {
        private readonly ILogger<AdditionalService> _logger;
        private readonly IConfiguration _configuration;
        private readonly AppConfig _appConfig;
        private CommonDB _database;
        private int _priority = 4;
        private ArbeitUtils _arbeitUtils;
        private ArbeitUtilsThZusatz _arbeitUtilsThZusatz;
        private ArbeitUtilsThZusatzComplete _arbeitUtilsThZusatzComplete;
        private ArbeitUtilsThZusatzFinal _arbeitUtilsThZusatzFinal;
        private int _timerInterval = 600;
        private DateTime _lastExecution = DateTime.MinValue;
        
        // Feature-Flags
        public int TimeZone { get; set; } = 0;
        public bool RUESTPROT_AUS_STILLSTAND { get; set; } = false;
        public bool PaletteRest { get; set; } = false;
        public bool SHORT_DELAY_AUTO_BOOK { get; set; } = false;
        public bool OptionPlanung { get; set; } = false;
        public bool TACKTLOG_CHECK { get; set; } = false;
        public int TACKTLOG_CHECK_TOLERANZ { get; set; } = 0;
        public bool INCL_MoldStateFromStateInt { get; set; } = false;
        public bool BUCHEN_ARBEITSFREI_BIS { get; set; } = false;
        public bool INCL_KeinWP_Bei_Laufzeit_In_Schicht { get; set; } = false;
        public bool INCL_Autobuchen_nach_Arbeitsfrei { get; set; } = false;
        public int VerpacktSchichtNachberechnen { get; set; } = 0;
        public int SHORT_DELAY_AUTO_BOOK_VALUE { get; set; } = 5;
        public int Schicht1 { get; set; } = 6;
        public int Schicht2 { get; set; } = 14;
        public int Schicht3 { get; set; } = 22;
        
        // ServiceEventSystem für Kommunikation zwischen Services
        private ServiceEventSystem _serviceEvents;
        
        public AdditionalService(ILogger<AdditionalService> logger, IConfiguration configuration, ServiceEventSystem serviceEvents = null)
        {
            _logger = logger;
            _configuration = configuration;
            _appConfig = new AppConfig();
            _configuration.GetSection("Database").Bind(_appConfig.Database);
            _configuration.GetSection("Main").Bind(_appConfig.Main);
            _serviceEvents = serviceEvents ?? new ServiceEventSystem();
            
            LoadConfiguration();
            InitializeDatabase();
            InitializeUtilities();
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
            TACKTLOG_CHECK_TOLERANZ = _configuration.GetValue<int>("Features:TACKTLOG_CHECK_TOLERANZ", 0);
            INCL_MoldStateFromStateInt = _configuration.GetValue<bool>("Features:INCL_MoldStateFromStateInt", false);
            BUCHEN_ARBEITSFREI_BIS = _configuration.GetValue<bool>("Features:BUCHEN_ARBEITSFREI_BIS", false);
            INCL_KeinWP_Bei_Laufzeit_In_Schicht = _configuration.GetValue<bool>("Features:INCL_KeinWP_Bei_Laufzeit_In_Schicht", false);
            INCL_Autobuchen_nach_Arbeitsfrei = _configuration.GetValue<bool>("Features:INCL_Autobuchen_nach_Arbeitsfrei", false);
            VerpacktSchichtNachberechnen = _configuration.GetValue<int>("Features:VerpacktSchichtNachberechnen", 0);
            SHORT_DELAY_AUTO_BOOK_VALUE = _configuration.GetValue<int>("Features:SHORT_DELAY_AUTO_BOOK_VALUE", 5);
            Schicht1 = _configuration.GetValue<int>("Shift:Schicht1", 6);
            Schicht2 = _configuration.GetValue<int>("Shift:Schicht2", 14);
            Schicht3 = _configuration.GetValue<int>("Shift:Schicht3", 22);
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

        private void InitializeUtilities()
        {
            _arbeitUtils = new ArbeitUtils(_logger, _database);
            
            // ThZusatz-Utility-Klassen initialisieren
            _arbeitUtilsThZusatz = new ArbeitUtilsThZusatz(_logger, _database, _arbeitUtils)
            {
                Schicht1 = Schicht1,
                Schicht2 = Schicht2,
                Schicht3 = Schicht3,
                ShiftModel = _configuration.GetValue<int>("Shift:ShiftModel", 1),
                TACKTLOG_CHECK_TOLERANZ = TACKTLOG_CHECK_TOLERANZ
            };
            
            _arbeitUtilsThZusatzComplete = new ArbeitUtilsThZusatzComplete(_logger, _database, _arbeitUtils)
            {
                SHORT_DELAY_AUTO_BOOK_VALUE = SHORT_DELAY_AUTO_BOOK_VALUE,
                Schicht1 = Schicht1,
                Schicht2 = Schicht2,
                Schicht3 = Schicht3,
                ShiftModel = _configuration.GetValue<int>("Shift:ShiftModel", 1)
            };
            
            _arbeitUtilsThZusatzFinal = new ArbeitUtilsThZusatzFinal(_logger, _database, _arbeitUtils);
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
                    try
                    {
                        // Auf Event warten (wie WaitForSingleObject in Delphi)
                        await _serviceEvents.WaitForEventAsync(ServiceEventSystem.EVENT_ZUSATZ, stoppingToken);
                        
                        if (stoppingToken.IsCancellationRequested)
                            break;
                        
                        if (_database != null && _database.Connected)
                        {
                            await StartProgrammeAsync(stoppingToken);
                        }
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "AdditionalService error");
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "AdditionalService fatal error");
            }
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

        /// <summary>
        /// Hauptmethode - Äquivalent zu TThread_Zusatz.StartProgramme in Th_Zusatz.pas
        /// Schritt 17: Integration aller Th_Zusatz-Funktionen
        /// </summary>
        private async Task StartProgrammeAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("*** Start AdditionalService Programs");
            try
            {
                // Schritt 1: Rüstprotokoll und Stillstandslog prüfen
                if (RUESTPROT_AUS_STILLSTAND)
                {
                    await _arbeitUtilsThZusatzComplete.CheckRuestProt_StillogAsync(stoppingToken);
                }
                
                // Schritt 2: Paletten-Rest berechnen
                if (PaletteRest)
                {
                    await _arbeitUtilsThZusatzComplete.Palette_Rest_BerechnenAsync(stoppingToken);
                }
                
                // Schritt 3: TPM-Korrektur für doppelte Daten
                await _arbeitUtilsThZusatzComplete.TPM_Korrektur_Doppelte_DatenAsync(stoppingToken);
                
                // Schritt 4: Job-Nummern in Downtime-Log eintragen
                await _arbeitUtilsThZusatzComplete.Job_No_to_Downtime_LogAsync(stoppingToken);
                
                // Schritt 5: Arbeitsfrei-Zeiten buchen
                if (BUCHEN_ARBEITSFREI_BIS)
                {
                    await _arbeitUtilsThZusatzComplete.ArbeitsFrei_BuchenAsync(stoppingToken);
                }
                
                // Schritt 6: Kurze Verzögerungen automatisch buchen
                if (SHORT_DELAY_AUTO_BOOK)
                {
                    await _arbeitUtilsThZusatzComplete.Book_Short_DelayAsync(stoppingToken);
                }
                
                // Schritt 7: Werkzeug-Reparaturen verarbeiten
                await _arbeitUtilsThZusatzComplete.WZReparaturAsync(stoppingToken);
                
                // Schritt 8: Verpackt-Protokoll prüfen
                await _arbeitUtilsThZusatzComplete.CheckVerpacktProtAsync(stoppingToken);
                
                // Schritt 9: Verpackt-Schicht-Daten prüfen
                if (VerpacktSchichtNachberechnen > 0)
                {
                    await _arbeitUtilsThZusatz.CheckPackSchichtAsync(VerpacktSchichtNachberechnen, stoppingToken);
                }
                
                // Schritt 10: Laufzeit berechnen
                if (OptionPlanung)
                {
                    await _arbeitUtilsThZusatz.Laufzeit_BerechnenAsync(stoppingToken);
                }
                
                // Schritt 11: Takt-Log prüfen
                if (TACKTLOG_CHECK)
                {
                    await _arbeitUtilsThZusatz.Check_TaktLogAsync(stoppingToken);
                }
                
                // Schritt 12: Laufzeit berechnen (Version 2)
                await _arbeitUtilsThZusatz.Laufzeit_Berechnen2Async(stoppingToken);
                
                // Schritt 13: Status-Beschreibungen aktualisieren
                await _arbeitUtilsThZusatz.Status_BeschreibungAsync(stoppingToken);
                
                // Schritt 14: Sollstückzahl prüfen
                await _arbeitUtilsThZusatzFinal.CheckSollstueckAsync(stoppingToken);
                
                // Schritt 15: Werkzeug-Wartungen prüfen
                await _arbeitUtilsThZusatzFinal.CheckWzWartungenAsync(stoppingToken);
                
                // Schritt 16: Ende aus Ist berechnen
                await _arbeitUtilsThZusatzFinal.BerechnenEndeausIstAsync(stoppingToken);
                
                // Schritt 17: Laufende Aufträge terminieren
                await _arbeitUtilsThZusatzFinal.Laufende_Auftraege_TerminierenAsync(stoppingToken);
                
                // Schritt 18: Automatische Terminierung
                await _arbeitUtilsThZusatzFinal.AutoterminierungAsync(stoppingToken);
                
                // Schritt 19: Ungeplante Rüstzeiten verarbeiten
                await _arbeitUtilsThZusatzFinal.UnscheduledSetupAsync(stoppingToken);
                
                // Schritt 20: Verpackt-Log aus Schicht-Log berechnen
                if (OptionPlanung)
                {
                    await _arbeitUtilsThZusatzFinal.CalcPackedlogFromShiftlogAsync(stoppingToken);
                }
                
                _logger.LogInformation("*** All programs completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in StartProgramme");
            }
        }

        /// <summary>
        /// Setzt das Event für AdditionalService
        /// </summary>
        public void SetEvent()
        {
            _serviceEvents.SetEvent(ServiceEventSystem.EVENT_ZUSATZ);
        }
        
        /// <summary>
        /// Setzt das Event für AdditionalService (Pulse)
        /// </summary>
        public void PulseEvent()
        {
            _serviceEvents.PulseEvent(ServiceEventSystem.EVENT_ZUSATZ);
        }

        // ==================== HILFSMETHODEN (bereits vorhanden) ====================
        
        /// <summary>
        /// Gibt die Maschinen-Lizenz für eine Maschinen-Nummer zurück
        /// </summary>
        private async Task<string> GetMaschineAsync(int maschNr, CancellationToken stoppingToken)
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
                _logger.LogError(ex, "Error in GetMaschine for MaschineNr {MaschNr}", maschNr);
                return string.Empty;
            }
        }
        
        /// <summary>
        /// Konvertiert ein Datum in einen Punkt-String (für SQL)
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
