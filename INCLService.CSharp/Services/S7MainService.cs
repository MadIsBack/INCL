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
    /// Haupt-Service, der alle anderen Services koordiniert
    /// Äquivalent zu TS7Main in Delphi (DBMain.pas)
    /// </summary>
    public class S7MainService : BackgroundService
    {
        private readonly ILogger<S7MainService> _logger;
        private readonly IConfiguration _configuration;
        private readonly AppConfig _appConfig;
        private readonly ServiceEventSystem _serviceEvents;
        
        private CommonDB _database;
        private bool _hochlauf = true;
        private bool _firstLauf = true;
        private bool _datenEnabled = true;
        private int _errorCount = 0;
        
        // Timer-Intervalle aus Konfiguration
        private int _mainTimerInterval = 15; // Sekunden
        private int _aliveTimerInterval = 15; // Sekunden
        
        // Konfigurationseinstellungen
        public bool Pruefen { get; set; } = false;
        public bool Packen { get; set; } = false;
        public bool VerpacktBarcode { get; set; } = false;
        public bool VerpacktAusAusschuss { get; set; } = false;
        public bool EndeAusVerpackt { get; set; } = false;
        public bool BCDSchalter { get; set; } = false;
        public bool SPC { get; set; } = false;
        public bool SPCStich { get; set; } = false;
        public bool Halbautomatik { get; set; } = false;
        public bool PruefGleichPack { get; set; } = false;
        public bool Werkzeugverwaltung { get; set; } = false;
        public bool Maschinenreinigung { get; set; } = false;
        public bool WerkstattAusschuss { get; set; } = false;
        public bool Differenzliste { get; set; } = false;
        public bool RuntimeLog { get; set; } = false;
        public bool RuestzeitAuftragFolgeAuftrag { get; set; } = false;
        
        // S7Main-Daten
        private S7MainData _s7Data = new S7MainData();
        
        // TPM-Instanz
        private TPM _thTPM;
        
        public string ServerNameDesDienstes { get; private set; } = "LOCALHOST";
        public string IgnorePendingStatement { get; private set; } = " AND pending = 0";
        
        // Feature-Flags
        public bool AuftragstartBarcode { get; set; } = false;
        public bool PersonalAnmeldung { get; set; } = false;
        public bool ReparaturAnmeldung { get; set; } = false;
        public bool MaschinenStatusSchreiben { get; set; } = false;
        public bool AuftragAutomatikStart { get; set; } = false;
        public bool LogSignals { get; set; } = false;
        public bool Extrusion { get; set; } = false;
        public bool TPMAuswertung { get; set; } = false;
        public bool TaktzeitAusStamm { get; set; } = false;
        public bool RuestenAutobuchen { get; set; } = false;
        public bool BarcodePzeWerkstatt { get; set; } = false;
        public bool StillstandMinuteLoeschen { get; set; } = false;
        public int StillstandMinuteWert { get; set; } = 0;
        public bool AutoRuesten { get; set; } = false;
        public int ShiftModel { get; set; } = 1;
        public int MaxSchichtTime { get; set; } = 480; // 8 Stunden
        public int SchichtDauer { get; set; } = 480;
        public int StillstaendeSchicht { get; set; } = 0;
        public bool ActiveAlarming { get; set; } = false;
        public bool MengeSchichtBerechnen { get; set; } = false;
        public bool MengeSchichtMinus { get; set; } = false;
        public bool MachineCycleCount { get; set; } = false;
        
        public S7MainService(
            ILogger<S7MainService> logger,
            IConfiguration configuration)
            : this(logger, configuration, null)
        {
        }
        
        public S7MainService(
            ILogger<S7MainService> logger,
            IConfiguration configuration,
            ServiceEventSystem serviceEvents)
        {
            _logger = logger;
            _configuration = configuration;
            _serviceEvents = serviceEvents ?? ServiceEvents.Instance;
            
            _appConfig = new AppConfig();
            _configuration.GetSection("Database").Bind(_appConfig.Database);
            _configuration.GetSection("Main").Bind(_appConfig.Main);
            
            // Servername setzen
            ServerNameDesDienstes = Environment.MachineName.ToUpper();
            
            // Eigene Datenbankverbindung initialisieren
            InitializeDatabase();
            InitializeTPM();
            
            // Konfiguration aus appsettings.json laden
            LoadConfiguration();
        }

        /// <summary>
        /// Setzt das Event für S7MainService
        /// </summary>
        public void SetEvent(string eventName)
        {
            _serviceEvents.SetEvent(eventName);
        }
        
        /// <summary>
        /// Pulses das Event für S7MainService
        /// </summary>
        public void PulseEvent(string eventName)
        {
            _serviceEvents.PulseEvent(eventName);
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
                
                _logger.LogInformation("S7MainService database initialized");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error initializing S7MainService database");
            }
        }

        private void InitializeTPM()
        {
            try
            {
                _thTPM = new TPM(_database);
                _logger.LogInformation("S7MainService TPM initialized");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error initializing S7MainService TPM");
            }
        }

        private void LoadConfiguration()
        {
            try
            {
                // Timer-Intervalle
                _mainTimerInterval = _configuration.GetValue<int>("Main:Timer", 15);
                _aliveTimerInterval = _configuration.GetValue<int>("Main:AliveTimerInterval", 15);
                
                // IgnorePending-Einstellung
                var ignorePending = _configuration.GetValue<bool>("Main:IgnorePending", true);
                IgnorePendingStatement = ignorePending ? " AND pending = 0" : string.Empty;
                
                // Feature-Flags
                Pruefen = _configuration.GetValue<bool>("Features:Pruefen", false);
                Packen = _configuration.GetValue<bool>("Features:Packen", false);
                VerpacktBarcode = _configuration.GetValue<bool>("Features:VerpacktBarcode", false);
                VerpacktAusAusschuss = _configuration.GetValue<bool>("Features:VerpacktAusAusschuss", false);
                EndeAusVerpackt = _configuration.GetValue<bool>("Features:EndeAusVerpackt", false);
                BCDSchalter = _configuration.GetValue<bool>("Features:BCDSchalter", false);
                SPC = _configuration.GetValue<bool>("Features:SPC", false);
                SPCStich = _configuration.GetValue<bool>("Features:SPCStich", false);
                Halbautomatik = _configuration.GetValue<bool>("Features:Halbautomatik", false);
                PruefGleichPack = _configuration.GetValue<bool>("Features:PruefGleichPack", false);
                Werkzeugverwaltung = _configuration.GetValue<bool>("Features:Werkzeugverwaltung", false);
                Maschinenreinigung = _configuration.GetValue<bool>("Features:Maschinenreinigung", false);
                WerkstattAusschuss = _configuration.GetValue<bool>("Features:WerkstattAusschuss", false);
                Differenzliste = _configuration.GetValue<bool>("Features:Differenzliste", false);
                RuntimeLog = _configuration.GetValue<bool>("Features:RuntimeLog", false);
                RuestzeitAuftragFolgeAuftrag = _configuration.GetValue<bool>("Features:RuestzeitAuftragFolgeAuftrag", false);
                
                // Weitere Feature-Flags
                AuftragstartBarcode = _configuration.GetValue<bool>("Features:AuftragstartBarcode", false);
                PersonalAnmeldung = _configuration.GetValue<bool>("Features:PersonalAnmeldung", false);
                ReparaturAnmeldung = _configuration.GetValue<bool>("Features:ReparaturAnmeldung", false);
                MaschinenStatusSchreiben = _configuration.GetValue<bool>("Features:MaschinenStatusSchreiben", false);
                AuftragAutomatikStart = _configuration.GetValue<bool>("Features:AuftragAutomatikStart", false);
                LogSignals = _configuration.GetValue<bool>("Features:LogSignals", false);
                Extrusion = _configuration.GetValue<bool>("Features:Extrusion", false);
                TPMAuswertung = _configuration.GetValue<bool>("Features:TPMAuswertung", false);
                TaktzeitAusStamm = _configuration.GetValue<bool>("Features:TaktzeitAusStamm", false);
                RuestenAutobuchen = _configuration.GetValue<bool>("Features:RuestenAutobuchen", false);
                BarcodePzeWerkstatt = _configuration.GetValue<bool>("Features:BarcodePzeWerkstatt", false);
                StillstandMinuteLoeschen = _configuration.GetValue<bool>("Features:StillstandMinuteLoeschen", false);
                StillstandMinuteWert = _configuration.GetValue<int>("Features:StillstandMinuteWert", 0);
                AutoRuesten = _configuration.GetValue<bool>("Features:AutoRuesten", false);
                ShiftModel = _configuration.GetValue<int>("Shift:ShiftModel", 1);
                MaxSchichtTime = _configuration.GetValue<int>("Features:MaxSchichtTime", 480);
                SchichtDauer = _configuration.GetValue<int>("Features:SchichtDauer", 480);
                StillstaendeSchicht = _configuration.GetValue<int>("Features:StillstaendeSchicht", 0);
                ActiveAlarming = _configuration.GetValue<bool>("Features:ActiveAlarming", false);
                MengeSchichtBerechnen = _configuration.GetValue<bool>("Features:MengeSchichtBerechnen", false);
                MengeSchichtMinus = _configuration.GetValue<bool>("Features:MengeSchichtMinus", false);
                MachineCycleCount = _configuration.GetValue<bool>("Features:MachineCycleCount", false);
                
                _logger.LogInformation("S7MainService configuration loaded. MainTimer: {Timer}s, AliveTimer: {AliveTimer}s",
                    _mainTimerInterval, _aliveTimerInterval);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error loading S7MainService configuration");
            }
        }

        /// <summary>
        /// Setzt die Dezimal- und Tausendertrennzeichen
        /// Äquivalent zu MakeEnviroment in Sprache_V63.pas
        /// </summary>
        private void MakeEnviroment()
        {
            try
            {
                // In C# verwenden wir InvariantCulture für Datenbankoperationen
                // Die System-Kultur wird nicht geändert, da .NET anders funktioniert als Delphi
                _logger.LogDebug("MakeEnviroment - Using InvariantCulture for database operations");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in MakeEnviroment");
            }
        }

        /// <summary>
        /// Lädt die Maschinen-Daten
        /// Äquivalent zu den Includis-Arrays in DBMain.pas
        /// </summary>
        private async Task LoadMaschinenDatenAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("Loading Maschinen-Daten...");
                
                // Maschinen-Anzahl ermitteln
                string sql = "SELECT COUNT(*) FROM Maschinen WHERE Aktiv = 1";
                using (var reader = _database.ExecuteReader(sql))
                {
                    if (await reader.ReadAsync(stoppingToken))
                    {
                        _s7Data.AnzahlMasch = reader.GetInt32(0);
                    }
                }
                
                // Maschinen-Daten laden
                sql = "SELECT Nr, Lizenz, IstArchiviert FROM Maschinen WHERE Aktiv = 1 ORDER BY Nr";
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        var maschine = new MaschinenDaten
                        {
                            Nr = reader.GetInt32(0),
                            Lizenz = reader.GetString(1),
                            IstArchiviert = reader.GetBoolean(2)
                        };
                        _s7Data.Includis.Add(maschine);
                    }
                }
                
                _logger.LogInformation("Loaded {Count} Maschinen", _s7Data.Includis.Count);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error loading Maschinen-Daten");
            }
        }

        /// <summary>
        /// Lädt die Signal-Daten
        /// Äquivalent zu DatenLesen2 in DBMain.pas
        /// </summary>
        private async Task DatenLesen2Async(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("DatenLesen2 started");
                
                // Signal-Liste laden
                _s7Data.SignalList.Clear();
                
                string sql = @"SELECT signal_maschine.nr, signal_maschine.istwert, signal_maschine.maschnr, signale.signalart
                    FROM signal_maschine 
                    LEFT JOIN signale ON signale.signalnr = signal_maschine.signalnr";
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        var item = new SignalMaschineItem
                        {
                            Nr = reader.GetInt32(0),
                            Istwert = reader.GetInt32(1),
                            IstwertString = reader.GetString(1),
                            Maschnr = reader.GetInt32(2),
                            Signalart = reader.GetInt32(3)
                        };
                        _s7Data.SignalList.Add(item);
                    }
                }
                
                // Barcode-Signale laden
                await LoadBarcodeSignaleAsync(stoppingToken);
                
                // Maschinen-Daten laden
                await LoadMaschinenDatenAsync(stoppingToken);
                
                // Signalwerte in Maschinen-Daten speichern
                await UpdateMaschinenSignaleAsync(stoppingToken);
                
                _logger.LogDebug("DatenLesen2 completed - {Count} signals loaded", _s7Data.SignalList.Count);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in DatenLesen2");
            }
        }

        /// <summary>
        /// Lädt die Barcode-Signale
        /// </summary>
        private async Task LoadBarcodeSignaleAsync(CancellationToken stoppingToken)
        {
            try
            {
                // Barcode_Gelesen Signale
                string sql = "SELECT DBNr FROM Signal_Maschine WHERE SignalNr IN (SELECT SignalNr FROM Signale WHERE SignalArt = 24)";
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    if (await reader.ReadAsync(stoppingToken))
                    {
                        _s7Data.BarcodeGelesen.DBNr = reader.GetInt32(0);
                    }
                }
                
                // Weitere Barcode-Signale laden
                // Hier würden die DBNrs für alle Barcode-Signale geladen werden
                _logger.LogDebug("Barcode-Signale loaded");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error loading Barcode-Signale");
            }
        }

        /// <summary>
        /// Aktualisiert die Maschinen-Daten mit Signalwerten
        /// </summary>
        private async Task UpdateMaschinenSignaleAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("Updating Maschinen-Signale...");
                
                // Für jede Maschine die Signalwerte aktualisieren
                for (int i = 0; i < _s7Data.Includis.Count; i++)
                {
                    var maschine = _s7Data.Includis[i];
                    if (maschine.IstArchiviert)
                    {
                        continue;
                    }
                    
                    // StueckGesamt
                    maschine.StueckGesamt = _s7Data.SignalList.GetIstwertByNr(GetSignalNrByMaschine(i, "StueckGesamt"));
                    
                    // StueckAuftragGesamt
                    maschine.StueckAuftragGesamt = _s7Data.SignalList.GetIstwertByNr(GetSignalNrByMaschine(i, "StueckAuftragGesamt"));
                    
                    // StueckSchicht
                    maschine.StueckSchicht = _s7Data.SignalList.GetIstwertByNr(GetSignalNrByMaschine(i, "StueckSchicht"));
                    
                    // Betriebsstunden
                    maschine.Betriebsstunden = _s7Data.SignalList.GetIstwertByNr(GetSignalNrByMaschine(i, "Betriebsstunden"));
                    
                    // Taktzeit
                    maschine.Taktzeit = _s7Data.SignalList.GetIstwertByNr(GetSignalNrByMaschine(i, "Taktzeit"));
                    
                    // LaufzeitGes
                    maschine.LaufzeitGes = _s7Data.SignalList.GetIstwertByNr(GetSignalNrByMaschine(i, "LaufzeitGes"));
                    
                    // LaufzeitSchicht
                    maschine.LaufzeitSchicht = _s7Data.SignalList.GetIstwertByNr(GetSignalNrByMaschine(i, "LaufzeitSchicht"));
                    
                    // MaschinenZustand
                    maschine.MaschinenZustand = _s7Data.SignalList.GetIstwertByNr(GetSignalNrByMaschine(i, "MaschinenZustand"));
                    
                    // TerminalAuftragNr
                    maschine.TerminalAuftragNr = _s7Data.SignalList.GetIstwertByNr(GetSignalNrByMaschine(i, "TerminalAuftragNr"));
                }
                
                _logger.LogDebug("Maschinen-Signale updated");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating Maschinen-Signale");
            }
        }

        /// <summary>
        /// Gibt die Signal-Nr für eine bestimmte Maschine und Signal-Art zurück
        /// </summary>
        private int GetSignalNrByMaschine(int maschinenIndex, string signalName)
        {
            try
            {
                if (maschinenIndex < 0 || maschinenIndex >= _s7Data.Includis.Count)
                {
                    return 0;
                }
                
                string lizenz = _s7Data.Includis[maschinenIndex].Lizenz;
                
                // Signal-Nr aus Datenbank ermitteln
                string sql = $@"SELECT signal_maschine.Nr 
                    FROM signal_maschine 
                    JOIN signale ON signale.SignalNr = signal_maschine.SignalNr
                    JOIN maschinen ON maschinen.Lizenz = signal_maschine.MaschinenLizenz
                    WHERE maschinen.Lizenz = '{lizenz}' 
                    AND signale.Bezeichnung = '{signalName}'";
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    if (reader.Read())
                    {
                        return reader.GetInt32(0);
                    }
                }
                
                return 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in GetSignalNrByMaschine");
                return 0;
            }
        }

        /// <summary>
        /// Lädt die Setup-Daten
        /// Äquivalent zu den Setup-Parametern in DBMain.pas
        /// </summary>
        private async Task LoadSetupDataAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("Loading Setup data...");
                
                string sql = "SELECT * FROM SETUP WHERE Nr = 1";
                using (var reader = _database.ExecuteReader(sql))
                {
                    if (await reader.ReadAsync(stoppingToken))
                    {
                        // Sprache und andere Einstellungen laden
                        int spracheNr = reader.GetInt32(reader.GetOrdinal("Sprache"));
                        int sprache2 = reader.GetInt32(reader.GetOrdinal("Sprache2"));
                        
                        // Feature-Flags aus Setup laden
                        Pruefen = reader.GetInt32(reader.GetOrdinal("Pruefen")) == 1;
                        Packen = reader.GetInt32(reader.GetOrdinal("Packen")) == 1;
                        
                        _logger.LogDebug("Setup data loaded - Sprache: {Sprache}, Pruefen: {Pruefen}, Packen: {Packen}",
                            spracheNr, Pruefen, Packen);
                    }
                    else
                    {
                        _logger.LogError("Error: Setup data not found");
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error loading setup data");
            }
        }

        /// <summary>
        /// Haupt-Datenlesemethode
        /// Äquivalent zu DatenLesen in DBMain.pas
        /// </summary>
        private async Task DatenLesenAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("DatenLesen started");
                
                // Zuerst DatenLesen2 aufrufen (wie in Delphi)
                await DatenLesen2Async(stoppingToken);
                
                // Dann spezifische Daten laden
                await LoadSetupDataAsync(stoppingToken);
                
                _logger.LogDebug("DatenLesen completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in DatenLesen");
            }
        }

        /// <summary>
        /// Lädt die Daten für Metall-Bearbeitung
        /// Äquivalent zu DatenLesen_Metall in DBMain.pas
        /// </summary>
        private async Task DatenLesenMetallAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("DatenLesen_Metall started");
                
                // Metall-spezifische Daten laden
                // Hier würde die Logik aus Delphi implementiert werden
                
                _logger.LogDebug("DatenLesen_Metall completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in DatenLesen_Metall");
            }
        }

        /// <summary>
        /// Prüft, ob eine manuelle Stückbuchung vorliegt
        /// Äquivalent zu CheckManuelleStueckBuchung in DBMain.pas
        /// </summary>
        private bool CheckManuelleStueckBuchung(int maschinenIndex)
        {
            try
            {
                // Hier würde geprüft werden, ob eine manuelle Stückbuchung vorliegt
                // Vereinfachte Version: Immer false zurückgeben
                return false;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in CheckManuelleStueckBuchung");
                return false;
            }
        }

        /// <summary>
        /// Gibt den alten Stückauftragswert zurück
        /// Äquivalent zu GetStueckAuftragAlt in DBMain.pas
        /// </summary>
        private int GetStueckAuftragAlt(int maschinenIndex)
        {
            try
            {
                // Hier würde der alte Wert aus der Datenbank gelesen werden
                return 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in GetStueckAuftragAlt");
                return 0;
            }
        }

        private async Task Timer1TimerAsync(CancellationToken stoppingToken)
        {
            try
            {
                // Hier würde die Haupt-Logik ausführen
                // Daten lesen, verarbeiten, etc.
                
                if (_hochlauf)
                {
                    _hochlauf = false;
                    _logger.LogInformation("Hochlaufphase abgeschlossen");
                }
                
                if (_firstLauf)
                {
                    _firstLauf = false;
                    _logger.LogInformation("Erster Lauf abgeschlossen");
                }
                
                // Datenbank-Operationen
                if (_datenEnabled && _database != null && _database.Connected)
                {
                    // Daten lesen und verarbeiten
                    await DatenLesenAsync(stoppingToken);
                    
                    // Metall-Daten laden (falls aktiviert)
                    if (METALL_BEARBEITUNG)
                    {
                        await DatenLesenMetallAsync(stoppingToken);
                    }
                }
                else if (_database != null && !_database.Connected)
                {
                    // Versuchen, die Verbindung wiederherzustellen
                    await ReconnectDatabaseAsync(stoppingToken);
                }
            }
            catch (Exception ex)
            {
                _errorCount++;
                _logger.LogError(ex, "Error in Timer1Timer (Count: {Count})", _errorCount);
            }
        }

        private async Task ReconnectDatabaseAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogWarning("Attempting to reconnect database...");
                _database.Connected = false;
                await Task.Delay(5000, stoppingToken); // 5 Sekunden warten
                _database.Connected = true;
                _logger.LogInformation("Database reconnected successfully");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error reconnecting database");
            }
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("S7MainService started");
            
            try
            {
                // Datenbankverbindung herstellen
                if (_database != null)
                {
                    try
                    {
                        _database.Connected = true;
                        _logger.LogInformation("S7MainService database connected");
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Error connecting S7MainService database");
                    }
                }
                
                // Initialisierung
                await InitializeAsync(stoppingToken);
                
                // Hauptschleife
                while (!stoppingToken.IsCancellationRequested)
                {
                    await Timer1TimerAsync(stoppingToken);
                    
                    // Warten bis zum nächsten Zyklus
                    await Task.Delay(_mainTimerInterval * 1000, stoppingToken);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "S7MainService terminated unexpectedly");
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
                        _logger.LogError(ex, "Error disconnecting S7MainService database");
                    }
                }
                _logger.LogInformation("S7MainService stopped");
            }
        }

        private async Task InitializeAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogInformation("S7MainService initializing...");
                
                // Datenbankverbindung prüfen
                if (_database == null || !_database.Connected)
                {
                    _logger.LogWarning("Database not connected");
                    return;
                }
                
                // MakeEnviroment aufrufen
                MakeEnviroment();
                
                // Setup-Daten laden
                await LoadSetupDataAsync(stoppingToken);
                
                // Maschinen-Daten laden
                await LoadMaschinenDatenAsync(stoppingToken);
                
                // Erste Datenlesung
                await DatenLesenAsync(stoppingToken);
                
                _logger.LogInformation("S7MainService initialized successfully");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error initializing S7MainService");
            }
        }

        public override async Task StopAsync(CancellationToken cancellationToken)
        {
            _logger.LogInformation("S7MainService stopping...");
            await base.StopAsync(cancellationToken);
        }
    }
}
