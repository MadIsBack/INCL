using INCLService.CSharp.Models;
using INCLUDIS.Utils.CommonDB;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Threading;
using System.Threading.Tasks;

namespace INCLService.CSharp.Services
{
    /// <summary>
    /// Portierte Methoden aus DBMain.pas für S7MainService
    /// Schritt 14: Implementierung der Hauptmethoden aus DBMain.pas
    /// </summary>
    public static class S7MainServiceDBMainMethods
    {
        private static ILogger _logger;
        private static CommonDB _database;
        private static S7MainData _s7Data;
        private static string _ignorePendingStatement = " AND pending = 0";
        
        /// <summary>
        /// Initialisiert die statischen Felder
        /// </summary>
        public static void Initialize(ILogger logger, CommonDB database, S7MainData s7Data, string ignorePendingStatement)
        {
            _logger = logger;
            _database = database;
            _s7Data = s7Data;
            _ignorePendingStatement = ignorePendingStatement;
        }
        
        // ==================== HAUPTMETHODEN AUS DBMAIN.PAS ====================
        
        /// <summary>
        /// Erstellt die Threads
        /// Äquivalent zu TS7Main.Create_Threads in DBMain.pas (Zeile 1926)
        /// </summary>
        public static void Create_Threads(S7MainService service)
        {
            try
            {
                _logger.LogDebug("Create_Threads started");
                
                // In .NET werden die Threads als BackgroundServices erstellt
                // und über den Host gestartet. Hier nur die Timer initialisieren.
                
                // Thread_Zusatz Timer
                service._threadZusatzTimer = service._configuration.GetValue<int>("Addons:Timer", 600);
                service._threadZusatzLast = DateTime.Now;
                
                // Thread_Signallog Timer
                service._threadSignallogTimer = service._configuration.GetValue<int>("Signallog:Timer", 30);
                service._threadSignallogLast = DateTime.Now;
                
                // Thread_Backup Timer
                service._threadBackupTimer = service._configuration.GetValue<int>("Backup:Timer", 60);
                service._threadBackupLast = DateTime.Now;
                
                _logger.LogDebug("Create_Threads completed - ZusatzTimer: {ZusatzTimer}s, SignallogTimer: {SignallogTimer}s, BackupTimer: {BackupTimer}s",
                    service._threadZusatzTimer, service._threadSignallogTimer, service._threadBackupTimer);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in Create_Threads");
            }
        }
        
        /// <summary>
        /// Schreibt SPS-Werte in die Datenbank
        /// Äquivalent zu TS7Main.In_SPSWerteDB in DBMain.pas (Zeile 2020)
        /// </summary>
        public static async Task In_SPSWerteDBAsync(S7MainService service, CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("In_SPSWerteDB started");
                
                // Alle aktuellen SPS-Werte in Datenbank schreiben
                // Jede Maschine in DB
                for (int i = 1; i <= service._s7Data.AnzahlMasch; i++)
                {
                    if (i > service._s7Data.Maschinen.Count || service._s7Data.Maschinen[i - 1].IstArchiviert)
                    {
                        continue;
                    }
                    
                    int maschProgramm = service._s7Data.MaschProgrammbetrieb[i].Istwert ? 1 : 0;
                    int maschStoerung = 0; // Wird in Delphi berechnet
                    
                    // Prüfen, ob der Datensatz existiert
                    bool exists = await SQLGetBoolAsync(service, $"SELECT COUNT(*) FROM SPSWERTE WHERE LizenzInt = {i}", stoppingToken);
                    
                    string sql;
                    if (!exists)
                    {
                        // INSERT
                        sql = $@"INSERT INTO SPSWERTE (Nr, LizenzInt, MaschProgramm, MaschOrg, MaschStoerung,
                            StueckGesamt, StueckAuftragGesamt, StueckAuftragSchicht, StueckSchicht,
                            Betriebsstunden, Taktzeit, LaufzeitGes, LaufzeitSchicht,
                            StueckPruefGesamt, StueckPruefAuftragGesamt, StueckPruefAuftragSchicht, StueckPruefSchicht,
                            StueckPackGesamt, StueckPackAuftragGesamt, StueckPackAuftragSchicht, StueckPackSchicht)
                            VALUES (SPSWERTEID.NextVal, {i}, {maschProgramm}, 0, {maschStoerung},
                            {service._s7Data.StueckGesamt[i].Istwert}, {service._s7Data.StueckAuftragGesamt[i].Istwert}, 
                            {service._s7Data.StueckAuftragSchicht[i].Istwert}, {service._s7Data.StueckSchicht[i].Istwert},
                            {service._s7Data.Betriebsstunden[i].Istwert}, {service._s7Data.Taktzeit[i].Istwert}, 
                            {service._s7Data.LaufzeitGes[i].Istwert}, {service._s7Data.LaufzeitSchicht[i].Istwert},
                            {service._s7Data.StueckPruefGesamt[i].Istwert}, {service._s7Data.StueckPruefAuftragGesamt[i].Istwert}, 
                            {service._s7Data.StueckPruefAuftragSchicht[i].Istwert}, {service._s7Data.StueckPruefSchicht[i].Istwert},
                            {service._s7Data.StueckPackGesamt[i].Istwert}, {service._s7Data.StueckPackAuftragGesamt[i].Istwert}, 
                            {service._s7Data.StueckPackAuftragSchicht[i].Istwert}, {service._s7Data.StueckPackSchicht[i].Istwert})"
                            + service.IgnorePendingStatement;
                    }
                    else
                    {
                        // UPDATE
                        sql = $@"UPDATE SPSWERTE SET 
                            MaschProgramm = {maschProgramm},
                            MaschOrg = 0,
                            MaschStoerung = {maschStoerung},
                            StueckGesamt = {service._s7Data.StueckGesamt[i].Istwert},
                            StueckAuftragGesamt = {service._s7Data.StueckAuftragGesamt[i].Istwert},
                            StueckAuftragSchicht = {service._s7Data.StueckAuftragSchicht[i].Istwert},
                            StueckSchicht = {service._s7Data.StueckSchicht[i].Istwert},
                            Betriebsstunden = {service._s7Data.Betriebsstunden[i].Istwert},
                            Taktzeit = {service._s7Data.Taktzeit[i].Istwert},
                            LaufzeitGes = {service._s7Data.LaufzeitGes[i].Istwert},
                            LaufzeitSchicht = {service._s7Data.LaufzeitSchicht[i].Istwert},
                            StueckPruefGesamt = {service._s7Data.StueckPruefGesamt[i].Istwert},
                            StueckPruefAuftragGesamt = {service._s7Data.StueckPruefAuftragGesamt[i].Istwert},
                            StueckPruefAuftragSchicht = {service._s7Data.StueckPruefAuftragSchicht[i].Istwert},
                            StueckPruefSchicht = {service._s7Data.StueckPruefSchicht[i].Istwert},
                            StueckPackGesamt = {service._s7Data.StueckPackGesamt[i].Istwert},
                            StueckPackAuftragGesamt = {service._s7Data.StueckPackAuftragGesamt[i].Istwert},
                            StueckPackAuftragSchicht = {service._s7Data.StueckPackAuftragSchicht[i].Istwert},
                            StueckPackSchicht = {service._s7Data.StueckPackSchicht[i].Istwert}
                            WHERE LizenzInt = {i}"
                            + service.IgnorePendingStatement;
                    }
                    
                    await service._database.ExecuteNonQueryAsync(sql, stoppingToken);
                }
                
                _logger.LogDebug("In_SPSWerteDB completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in In_SPSWerteDB");
            }
        }
        
        /// <summary>
        /// Schreibt einen einzelnen SPS-Wert
        /// Äquivalent zu TS7Main.Schreibe_SPS_Wert in DBMain.pas (Zeile 3598)
        /// </summary>
        public static async Task Schreibe_SPS_WertAsync(S7MainService service, int maschNr, int signalNr, int wert, CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("Schreibe_SPS_Wert: Maschine={MaschNr}, SignalNr={SignalNr}, Wert={Wert}", maschNr, signalNr, wert);
                
                // Hier würde der Wert an die S7 geschrieben werden
                // Da S7-Anbindung nicht benötigt wird, nur Loggen
                _logger.LogInformation("SPS-Wert geschrieben: Maschine {MaschNr}, Signal {SignalNr}, Wert {Wert}", maschNr, signalNr, wert);
                
                // Wert in den lokalen Arrays speichern
                switch (signalNr)
                {
                    case 0: // StueckGesamt
                        service._s7Data.StueckGesamt[maschNr].Istwert = wert;
                        break;
                    case 1: // StueckAuftragGesamt
                        service._s7Data.StueckAuftragGesamt[maschNr].Istwert = wert;
                        break;
                    // Weitere Signalnummern hier einfügen
                    default:
                        _logger.LogWarning("Unbekannte SignalNr: {SignalNr}", signalNr);
                        break;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in Schreibe_SPS_Wert");
            }
        }
        
        /// <summary>
        /// Lädt die Daten
        /// Äquivalent zu TS7Main.DatenLesen in DBMain.pas (Zeile 2438)
        /// </summary>
        public static async Task DatenLesenAsync(S7MainService service, CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("DatenLesen started");
                
                // 1. Maschinen-Daten neu laden
                await LoadMaschinenDatenAsync(service, stoppingToken);
                
                // 2. Signal-Daten neu laden
                await DatenLesen2Async(service, stoppingToken);
                
                _logger.LogDebug("DatenLesen completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in DatenLesen");
            }
        }
        
        /// <summary>
        /// Lädt die Maschinen-Daten
        /// Äquivalent zu den Includis-Arrays in DBMain.pas
        /// </summary>
        public static async Task LoadMaschinenDatenAsync(S7MainService service, CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("Loading Maschinen-Daten...");
                
                // Maschinen-Anzahl ermitteln
                string sql = "SELECT COUNT(*) FROM Maschinen WHERE Aktiv = 1";
                using (var reader = service._database.ExecuteReader(sql))
                {
                    if (await reader.ReadAsync(stoppingToken))
                    {
                        service._s7Data.AnzahlMasch = reader.GetInt32(0);
                    }
                }
                
                // Maschinen-Daten laden
                sql = "SELECT Nr, Lizenz, IstArchiviert, Name FROM Maschinen WHERE Aktiv = 1 ORDER BY Nr";
                using (var reader = service._database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        var maschine = new MaschinenDaten
                        {
                            Nr = reader.GetInt32(0),
                            Lizenz = reader.GetString(1),
                            IstArchiviert = reader.GetBoolean(2),
                            Name = reader.GetString(3)
                        };
                        service._s7Data.Maschinen.Add(maschine);
                    }
                }
                
                _logger.LogInformation("Loaded {Count} Maschinen", service._s7Data.Maschinen.Count);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error loading Maschinen-Daten");
            }
        }
        
        /// <summary>
        /// Lädt die Signal-Daten
        /// Äquivalent zu DatenLesen2 in DBMain.pas (Zeile 2183)
        /// </summary>
        public static async Task DatenLesen2Async(S7MainService service, CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("DatenLesen2 started");
                
                // Signal-Liste laden
                service._s7Data.SignalMaschinen.Clear();
                
                string sql = @"SELECT signal_maschine.nr, signal_maschine.istwert, signal_maschine.maschnr, 
                               signal_maschine.signalnr, signale.signalart, signale.signalname
                    FROM signal_maschine 
                    LEFT JOIN signale ON signale.signalnr = signal_maschine.signalnr";
                
                using (var reader = service._database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        var item = new SignalMaschineItem
                        {
                            Nr = reader.GetInt32(0),
                            Istwert = reader.GetInt32(1),
                            IstwertString = reader.GetInt32(1).ToString(),
                            MaschNr = reader.GetInt32(2),
                            SignalNr = reader.GetInt32(3),
                            Signalart = reader.GetInt32(4),
                            SignalName = reader.GetString(5)
                        };
                        service._s7Data.SignalMaschinen.Add(item);
                    }
                }
                
                // Barcode-Signale laden
                await LoadBarcodeSignaleAsync(service, stoppingToken);
                
                // Maschinen-Signale laden
                await LoadMaschinenSignaleAsync(service, stoppingToken);
                
                _logger.LogDebug("DatenLesen2 completed - {Count} signals loaded", service._s7Data.SignalMaschinen.Count);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in DatenLesen2");
            }
        }
        
        /// <summary>
        /// Lädt die Maschinen-Signale
        /// </summary>
        public static async Task LoadMaschinenSignaleAsync(S7MainService service, CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("Loading Maschinen-Signale...");
                
                // Für jede Maschine die Signalwerte laden
                foreach (var maschine in service._s7Data.Maschinen)
                {
                    if (maschine.IstArchiviert) continue;
                    
                    // Signalwerte für diese Maschine laden
                    string sql = $@"SELECT signal_maschine.signalnr, signal_maschine.istwert, signale.signalart
                        FROM signal_maschine 
                        JOIN signale ON signale.signalnr = signal_maschine.signalnr
                        WHERE signal_maschine.maschnr = {maschine.Nr}";
                    
                    using (var reader = service._database.ExecuteReader(sql))
                    {
                        while (await reader.ReadAsync(stoppingToken))
                        {
                            int signalNr = reader.GetInt32(0);
                            int istwert = reader.GetInt32(1);
                            int signalart = reader.GetInt32(2);
                            
                            // Signal in den entsprechenden Arrays speichern
                            StoreSignalValue(service, maschine.Nr, signalNr, istwert, signalart);
                        }
                    }
                }
                
                _logger.LogDebug("Maschinen-Signale loaded");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error loading Maschinen-Signale");
            }
        }
        
        /// <summary>
        /// Speichert einen Signalwert in den entsprechenden Arrays
        /// </summary>
        public static void StoreSignalValue(S7MainService service, int maschNr, int signalNr, int istwert, int signalart)
        {
            try
            {
                // Hier würde der Wert in den entsprechenden SPS-Arrays gespeichert werden
                // basierend auf der Signalart
                switch (signalart)
                {
                    case 0: // StueckGesamt
                        service._s7Data.StueckGesamt[maschNr].Istwert = istwert;
                        break;
                    case 1: // StueckAuftragGesamt
                        service._s7Data.StueckAuftragGesamt[maschNr].Istwert = istwert;
                        break;
                    case 2: // StueckSchicht
                        service._s7Data.StueckSchicht[maschNr].Istwert = istwert;
                        break;
                    case 4: // Betriebsstunden
                        service._s7Data.Betriebsstunden[maschNr].Istwert = istwert;
                        break;
                    case 5: // Taktzeit
                        service._s7Data.Taktzeit[maschNr].Istwert = istwert;
                        break;
                    // Weitere Signalarten hier einfügen
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error storing signal value for Maschine {MaschNr}, SignalNr {SignalNr}", maschNr, signalNr);
            }
        }
        
        /// <summary>
        /// Lädt die Barcode-Signale
        /// </summary>
        public static async Task LoadBarcodeSignaleAsync(S7MainService service, CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("Loading Barcode-Signale...");
                
                // Barcode_Gelesen Signale (SignalArt = 27)
                string sql = "SELECT signal_maschine.nr, signal_maschine.dbnr, signal_maschine.istwert " +
                             "FROM signal_maschine " +
                             "JOIN signale ON signale.signalnr = signal_maschine.signalnr " +
                             "WHERE signale.signalart = 27";
                
                using (var reader = service._database.ExecuteReader(sql))
                {
                    if (await reader.ReadAsync(stoppingToken))
                    {
                        service._s7Data.Barcode_Gelesen.Nr = reader.GetInt32(0);
                        service._s7Data.Barcode_Gelesen.DBNr = reader.GetInt32(1);
                        service._s7Data.Barcode_Gelesen.Istwert = reader.GetInt32(2) != 0;
                    }
                }
                
                // Weitere Barcode-Signale laden (28-49)
                for (int i = 1; i <= 13; i++)
                {
                    sql = $"SELECT signal_maschine.nr, signal_maschine.dbnr, signal_maschine.istwert " +
                          "FROM signal_maschine " +
                          "JOIN signale ON signale.signalnr = signal_maschine.signalnr " +
                          "WHERE signale.signalart = {27 + i}";
                    
                    using (var reader = service._database.ExecuteReader(sql))
                    {
                        if (await reader.ReadAsync(stoppingToken))
                        {
                            service._s7Data.Barcode[i].Nr = reader.GetInt32(0);
                            service._s7Data.Barcode[i].DBNr = reader.GetInt32(1);
                            service._s7Data.Barcode[i].Istwert = reader.GetInt32(2);
                        }
                    }
                }
                
                _logger.LogDebug("Barcode-Signale loaded");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error loading Barcode-Signale");
            }
        }
        
        /// <summary>
        /// Prüft, ob ein SQL-Statement wahr ist
        /// Äquivalent zu SQLGetBool in SQL_fuc.pas
        /// </summary>
        public static async Task<bool> SQLGetBoolAsync(S7MainService service, string sql, CancellationToken stoppingToken)
        {
            try
            {
                using (var reader = service._database.ExecuteReader(sql))
                {
                    if (await reader.ReadAsync(stoppingToken))
                    {
                        return reader.GetInt32(0) > 0;
                    }
                }
                return false;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in SQLGetBool for SQL: {SQL}", sql);
                return false;
            }
        }
        
        /// <summary>
        /// Prüft auf Schichtwechsel
        /// Äquivalent zu TS7Main.NeueSchicht in DBMain.pas (Zeile 3641)
        /// </summary>
        public static async Task<bool> NeueSchichtAsync(S7MainService service, ref int alteSchicht, CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("NeueSchicht started");
                
                // Aktuelle Schicht aus Datenbank ermitteln
                string sql = "SELECT Schicht FROM Setup_Par WHERE Parameter = 'AktuelleSchicht'";
                int neueSchicht = 0;
                
                using (var reader = service._database.ExecuteReader(sql))
                {
                    if (await reader.ReadAsync(stoppingToken))
                    {
                        neueSchicht = reader.GetInt32(0);
                    }
                }
                
                // Prüfen, ob Schicht gewechselt hat
                if (neueSchicht != alteSchicht)
                {
                    alteSchicht = neueSchicht;
                    _logger.LogInformation("Neue Schicht: {NeueSchicht}", neueSchicht);
                    return true;
                }
                
                return false;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in NeueSchicht");
                return false;
            }
        }
        
        /// <summary>
        /// Prüft, ob die rote Lampe aus ist
        /// Äquivalent zu TS7Main.CheckRoteLampeAus in DBMain.pas (Zeile 3660)
        /// </summary>
        public static async Task<bool> CheckRoteLampeAusAsync(S7MainService service, CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("CheckRoteLampeAus started");
                
                // Prüfen, ob alle Maschinen die rote Lampe aus haben
                // In Delphi: Prüft, ob alle Maschinen den Status "MaschLaeuft" haben
                
                bool alleAus = true;
                for (int i = 1; i <= service._s7Data.AnzahlMasch; i++)
                {
                    if (i > service._s7Data.Maschinen.Count || service._s7Data.Maschinen[i - 1].IstArchiviert)
                    {
                        continue;
                    }
                    
                    // Prüfen, ob die Maschine läuft (Status = 0 = MaschLaeuft)
                    if (service._s7Data.Maschinen_Zustand[i].Istwert != 0)
                    {
                        alleAus = false;
                        break;
                    }
                }
                
                _logger.LogDebug("CheckRoteLampeAus: Alle Lampe aus = {AlleAus}", alleAus);
                return alleAus;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in CheckRoteLampeAus");
                return false;
            }
        }
        
        /// <summary>
        /// Gibt die Stückzahl des alten Auftrags zurück
        /// Äquivalent zu TS7Main.GetStueckAuftragAlt in DBMain.pas (Zeile 3734)
        /// </summary>
        public static async Task<long> GetStueckAuftragAltAsync(S7MainService service, int index, CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("GetStueckAuftragAlt: index={Index}", index);
                
                if (index < 1 || index > service._s7Data.AnzahlMasch)
                {
                    return 0;
                }
                
                return service._s7Data.StueckAuftragAlt[index];
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in GetStueckAuftragAlt");
                return 0;
            }
        }
        
        /// <summary>
        /// Prüft, ob eine manuelle Stückbuchung vorliegt
        /// Äquivalent zu TS7Main.CheckManuelleStueckBuchung in DBMain.pas (Zeile 3742)
        /// </summary>
        public static async Task<bool> CheckManuelleStueckBuchungAsync(S7MainService service, int index, CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("CheckManuelleStueckBuchung: index={Index}", index);
                
                if (index < 1 || index > service._s7Data.AnzahlMasch)
                {
                    return false;
                }
                
                // Prüfen, ob eine manuelle Buchung vorliegt
                // In Delphi: Prüft, ob Terminal_Menge_Gebucht für diese Maschine gesetzt ist
                return service._s7Data.Terminal_Menge_Gebucht[index].Istwert;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in CheckManuelleStueckBuchung");
                return false;
            }
        }
        
        /// <summary>
        /// Lädt Daten aus der Datenbank-Tabelle
        /// Äquivalent zu TS7Main.Hole_Daten_Tabelle in DBMain.pas (Zeile 3685)
        /// </summary>
        public static async Task Hole_Daten_TabelleAsync(S7MainService service, int datentyp, CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("Hole_Daten_Tabelle: Datentyp={Datentyp}", datentyp);
                
                string tableName = datentyp switch
                {
                    0 => "Maschinen",
                    1 => "Signale",
                    2 => "Signal_Maschine",
                    _ => "Maschinen"
                };
                
                // Hier würden die Daten aus der Tabelle geladen werden
                _logger.LogDebug("Hole_Daten_Tabelle completed for {TableName}", tableName);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in Hole_Daten_Tabelle");
            }
        }
        
        /// <summary>
        /// Behandelt Systemfehler
        /// Äquivalent zu TS7Main.HandleSystemError in DBMain.pas (Zeile 3567)
        /// </summary>
        public static void HandleSystemError(S7MainService service, Exception e, string aCustomString)
        {
            try
            {
                service._errorCount++;
                _logger.LogError(e, "System Error ({ErrorCount}): {CustomString} - {Message}", service._errorCount, aCustomString, e.Message);
                
                // Hier könnten zusätzliche Fehlerbehandlungsmaßnahmen ergriffen werden
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in HandleSystemError");
            }
        }
        
        /// <summary>
        /// Lädt Metall-Daten
        /// Äquivalent zu TS7Main.DatenLesen_Metall in DBMain.pas (Zeile 2874)
        /// </summary>
        public static async Task DatenLesen_MetallAsync(S7MainService service, CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("DatenLesen_Metall started");
                
                // Hier würde die Metall-spezifische Logik implementiert werden
                // In DBMain.pas: Zeile 2874-2899
                
                if (service.Metall)
                {
                    // Metall-spezifische Daten laden
                    string sql = "SELECT * FROM Metall_Freigabe";
                    using (var reader = service._database.ExecuteReader(sql))
                    {
                        while (await reader.ReadAsync(stoppingToken))
                        {
                            // Metall-Daten verarbeiten
                        }
                    }
                }
                
                _logger.LogDebug("DatenLesen_Metall completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in DatenLesen_Metall");
            }
        }
    }
}
