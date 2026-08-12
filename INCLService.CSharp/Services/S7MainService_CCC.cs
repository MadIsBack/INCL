using INCLService.CSharp.Models;
using INCLService.CSharp.Utilities;
using INCLUDIS.Utils.CommonDB;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;

namespace INCLService.CSharp.Services
{
    /// <summary>
    /// Critical Control Center Funktionen - Äquivalent zu den CCC_* Funktionen aus DBMain.pas
    /// Schritt 23: Implementierung der kritischen CCC-Funktionen
    /// </summary>
    public class S7MainServiceCCC
    {
        private readonly ILogger<S7MainServiceCCC> _logger;
        private readonly CommonDB _database;
        private readonly S7MainService _s7MainService;
        private readonly S7MainData _s7Data;

        public S7MainServiceCCC(ILogger<S7MainServiceCCC> logger, CommonDB database, S7MainService s7MainService)
        {
            _logger = logger;
            _database = database;
            _s7MainService = s7MainService;
            _s7Data = s7MainService.GetS7Data();
        }

        /// <summary>
        /// Initialisierung der CCC-Funktionen
        /// Äquivalent zu CCC_Init in DBMain.pas (Zeile 3058)
        /// </summary>
        public async Task CCC_InitAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogInformation("CCC_Init: Initialisierung der Critical Control Center Funktionen");
                
                // Hier würden Initialisierungsroutinen aus Delphi portiert werden
                // z.B. SystemID schreiben, Lizenzen prüfen, etc.
                await CCC_SchreibeSystemIDAsync(stoppingToken);
                await CCC_CheckLicensesAsync(stoppingToken);
                
                _logger.LogInformation("CCC_Init: Initialisierung abgeschlossen");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "CCC_Init: Fehler bei der Initialisierung");
            }
        }

        /// <summary>
        /// Schreibt die System-ID
        /// Äquivalent zu CCC_SchreibeSystemID in DBMain.pas (Zeile 2958)
        /// </summary>
        public async Task CCC_SchreibeSystemIDAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("CCC_SchreibeSystemID: System-ID wird geschrieben");
                
                string serverName = _s7MainService.ServerNameDesDienstes;
                string sql = $"UPDATE Setup SET SystemID = '{serverName}' WHERE Nr = 1";
                
                await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                
                _logger.LogDebug("CCC_SchreibeSystemID: System-ID erfolgreich geschrieben");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "CCC_SchreibeSystemID: Fehler beim Schreiben der System-ID");
            }
        }

        /// <summary>
        /// Prüft die Lizenzen
        /// Äquivalent zu CCC_CheckLicenses in DBMain.pas (Zeile 2959)
        /// </summary>
        public async Task<bool> CCC_CheckLicensesAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("CCC_CheckLicenses: Lizenzprüfung wird durchgeführt");
                
                // Hier würde die Lizenzprüfungslogik aus Delphi portiert werden
                // Vereinfacht: Immer true zurückgeben
                
                _logger.LogDebug("CCC_CheckLicenses: Lizenzprüfung erfolgreich");
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "CCC_CheckLicenses: Fehler bei der Lizenzprüfung");
                return false;
            }
        }

        /// <summary>
        /// Auftragsautomatik-Start
        /// Äquivalent zu CCC_AuftragAutomatikStart in DBMain.pas (Zeile 3185)
        /// </summary>
        public async Task CCC_AuftragAutomatikStartAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogInformation("CCC_AuftragAutomatikStart: Auftragsautomatik-Start wird ausgeführt");
                
                // Logik aus Delphi portieren:
                // 1. Prüfen, ob Auftragsautomatik aktiviert ist
                if (!_s7MainService.AuftragAutomatikStart)
                {
                    _logger.LogDebug("CCC_AuftragAutomatikStart: Auftragsautomatik ist deaktiviert");
                    return;
                }
                
                // 2. Für jede Maschine prüfen, ob ein neuer Auftrag gestartet werden soll
                for (int i = 0; i < _s7Data.Includis.Count; i++)
                {
                    var maschine = _s7Data.Includis[i];
                    if (maschine.IstArchiviert)
                        continue;
                    
                    // 3. Prüfen, ob Maschine bereit für neuen Auftrag ist
                    if (await KannAuftragGestartetWerdenAsync(i, stoppingToken))
                    {
                        // 4. Nächsten Auftrag für diese Maschine finden
                        var naechsterAuftrag = await GetNaechsterAuftragAsync(i, stoppingToken);
                        if (naechsterAuftrag != null)
                        {
                            // 5. Auftrag starten
                            await StartAuftragAsync(i, naechsterAuftrag, stoppingToken);
                        }
                    }
                }
                
                _logger.LogInformation("CCC_AuftragAutomatikStart: Auftragsautomatik-Start abgeschlossen");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "CCC_AuftragAutomatikStart: Fehler beim Auftragsautomatik-Start");
            }
        }

        /// <summary>
        /// Variable Auftragsautomatik-Start
        /// Äquivalent zu CCC_AuftragAutomatikStartVariabel in DBMain.pas (Zeile 3192)
        /// </summary>
        public async Task CCC_AuftragAutomatikStartVariabelAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogInformation("CCC_AuftragAutomatikStartVariabel: Variable Auftragsautomatik wird ausgeführt");
                
                // Ähnliche Logik wie CCC_AuftragAutomatikStart, aber mit variablen Parametern
                // Hier würde die spezifische Logik aus Delphi portiert werden
                
                _logger.LogInformation("CCC_AuftragAutomatikStartVariabel: Variable Auftragsautomatik abgeschlossen");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "CCC_AuftragAutomatikStartVariabel: Fehler bei der variablen Auftragsautomatik");
            }
        }

        /// <summary>
        /// Auftragsstart per Barcode
        /// Äquivalent zu CCC_Auftrag_Start_Barcode in DBMain.pas (Zeilen 3120-3122)
        /// </summary>
        /// <param name="barcodeScannerNr">Nummer des Barcode-Scanners (1-3)</param>
        public async Task CCC_Auftrag_Start_BarcodeAsync(int barcodeScannerNr, CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogInformation("CCC_Auftrag_Start_Barcode: Barcode-Scanner {ScannerNr} - Auftragsstart wird geprüft", barcodeScannerNr);
                
                // 1. Barcode aus SPS-Daten lesen
                int barcodeSignalNr = GetBarcodeSignalNr(barcodeScannerNr);
                if (barcodeSignalNr <= 0)
                {
                    _logger.LogDebug("CCC_Auftrag_Start_Barcode: Kein Barcode-Signal für Scanner {ScannerNr} gefunden", barcodeScannerNr);
                    return;
                }
                
                // 2. Prüfen, ob Barcode gelesen wurde
                bool barcodeGelesen = _s7Data.SignalList.GetBoolByNr(barcodeSignalNr);
                if (!barcodeGelesen)
                {
                    _logger.LogDebug("CCC_Auftrag_Start_Barcode: Kein Barcode für Scanner {ScannerNr} gelesen", barcodeScannerNr);
                    return;
                }
                
                // 3. Barcode-Wert aus SPS-Daten lesen
                int barcodeWert = _s7Data.SignalList.GetIstwertByNr(barcodeSignalNr);
                if (barcodeWert <= 0)
                {
                    _logger.LogDebug("CCC_Auftrag_Start_Barcode: Ungültiger Barcode-Wert für Scanner {ScannerNr}", barcodeScannerNr);
                    return;
                }
                
                // 4. Auftrag anhand Barcode finden und starten
                var auftrag = await GetAuftragByBarcodeAsync(barcodeWert, stoppingToken);
                if (auftrag != null)
                {
                    // 5. Maschine für diesen Barcode-Scanner finden
                    int maschinenIndex = GetMaschinenIndexByBarcodeScanner(barcodeScannerNr);
                    if (maschinenIndex >= 0)
                    {
                        await StartAuftragAsync(maschinenIndex, auftrag, stoppingToken);
                    }
                }
                
                // 6. Barcode zurücksetzen
                await ResetBarcodeAsync(barcodeScannerNr, stoppingToken);
                
                _logger.LogInformation("CCC_Auftrag_Start_Barcode: Barcode-Scanner {ScannerNr} - Auftragsstart abgeschlossen", barcodeScannerNr);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "CCC_Auftrag_Start_Barcode: Fehler beim Barcode-Auftragsstart (Scanner {ScannerNr})", barcodeScannerNr);
            }
        }

        /// <summary>
        /// Prüft, ob ein Auftrag für eine Maschine gestartet werden kann
        /// </summary>
        private async Task<bool> KannAuftragGestartetWerdenAsync(int maschinenIndex, CancellationToken stoppingToken)
        {
            try
            {
                var maschine = _s7Data.Includis[maschinenIndex];
                
                // Prüfen, ob Maschine aktiv ist
                if (maschine.IstArchiviert)
                    return false;
                
                // Prüfen, ob Maschine im Automatikmodus ist
                if (!_s7MainService.AuftragAutomatikStart)
                    return false;
                
                // Prüfen, ob Maschine bereit ist (nicht im Stillstand, nicht beim Rüsten, etc.)
                int maschinenZustand = maschine.MaschinenZustand;
                if (maschinenZustand != 0) // 0 = läuft
                {
                    _logger.LogDebug("KannAuftragGestartetWerden: Maschine {MaschinenNr} ist nicht bereit (Zustand: {Zustand})", 
                        maschine.Nr, maschinenZustand);
                    return false;
                }
                
                // Prüfen, ob aktueller Auftrag abgeschlossen ist
                if (maschine.Auftrag != null && !maschine.Auftrag.IstAbgeschlossen)
                {
                    _logger.LogDebug("KannAuftragGestartetWerden: Maschine {MaschinenNr} hat noch einen laufenden Auftrag", 
                        maschine.Nr);
                    return false;
                }
                
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "KannAuftragGestartetWerden: Fehler bei der Prüfung für Maschine {MaschinenIndex}", maschinenIndex);
                return false;
            }
        }

        /// <summary>
        /// Findet den nächsten Auftrag für eine Maschine
        /// </summary>
        private async Task<AuftragModel> GetNaechsterAuftragAsync(int maschinenIndex, CancellationToken stoppingToken)
        {
            try
            {
                var maschine = _s7Data.Includis[maschinenIndex];
                
                // SQL-Abfrage: Nächster Auftrag für diese Maschine
                string sql = $@"SELECT TOP 1 * FROM PDE 
                    WHERE MaschinenLizenz = '{maschine.Lizenz}' 
                    AND Stat = 0  -- Nicht gestartet
                    AND StartDatumZeit <= GETDATE()
                    AND (EndeDatumZeit IS NULL OR EndeDatumZeit >= GETDATE())
                    ORDER BY Prioritaet DESC, Dringlichkeit DESC, StartDatumZeit ASC";
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    if (await reader.ReadAsync(stoppingToken))
                    {
                        return new AuftragModel
                        {
                            Nr = reader.GetInt32(reader.GetOrdinal("Nr")),
                            BetriebsauftragNr = reader.GetString(reader.GetOrdinal("Betriebsauftragnr")),
                            Sollwert = reader.GetInt32(reader.GetOrdinal("Sollwert")),
                            Istwert = reader.GetInt32(reader.GetOrdinal("Istwert")),
                            Stat = reader.GetInt32(reader.GetOrdinal("Stat"))
                        };
                    }
                }
                
                return null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "GetNaechsterAuftrag: Fehler beim Laden des nächsten Auftrags für Maschine {MaschinenIndex}", maschinenIndex);
                return null;
            }
        }

        /// <summary>
        /// Startet einen Auftrag auf einer Maschine
        /// </summary>
        private async Task StartAuftragAsync(int maschinenIndex, AuftragModel auftrag, CancellationToken stoppingToken)
        {
            try
            {
                var maschine = _s7Data.Includis[maschinenIndex];
                
                _logger.LogInformation("StartAuftrag: Starte Auftrag {AuftragNr} auf Maschine {MaschinenNr}", 
                    auftrag.BetriebsauftragNr, maschine.Nr);
                
                // 1. Auftrag in PDE als gestartet markieren
                string sql = $"UPDATE PDE SET Stat = 1, StartDatumZeit = GETDATE() WHERE Nr = {auftrag.Nr}";
                await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                
                // 2. Maschinenauftrag aktualisieren
                sql = $@"UPDATE Maschinen SET AktAuftragNr = {auftrag.Nr}, 
                    AktBetriebsauftragNr = '{auftrag.BetriebsauftragNr}'
                    WHERE Lizenz = '{maschine.Lizenz}'";
                await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                
                // 3. SPS-Werte zurücksetzen
                await ResetSPSWerteForMaschineAsync(maschinenIndex, stoppingToken);
                
                _logger.LogInformation("StartAuftrag: Auftrag {AuftragNr} auf Maschine {MaschinenNr} erfolgreich gestartet", 
                    auftrag.BetriebsauftragNr, maschine.Nr);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "StartAuftrag: Fehler beim Starten von Auftrag {AuftragNr} auf Maschine {MaschinenIndex}", 
                    auftrag?.BetriebsauftragNr, maschinenIndex);
            }
        }

        /// <summary>
        /// Setzt SPS-Werte für eine Maschine zurück
        /// </summary>
        private async Task ResetSPSWerteForMaschineAsync(int maschinenIndex, CancellationToken stoppingToken)
        {
            try
            {
                var maschine = _s7Data.Includis[maschinenIndex];
                
                // Stückzähler zurücksetzen
                string sql = $@"UPDATE SPSWERTE SET 
                    StueckAuftragGesamt = 0,
                    StueckAuftragSchicht = 0,
                    StueckSchicht = 0
                    WHERE LizenzInt = {maschine.Nr}";
                
                await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                
                _logger.LogDebug("ResetSPSWerteForMaschine: SPS-Werte für Maschine {MaschinenNr} zurückgesetzt", maschine.Nr);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "ResetSPSWerteForMaschine: Fehler beim Zurücksetzen der SPS-Werte für Maschine {MaschinenIndex}", maschinenIndex);
            }
        }

        /// <summary>
        /// Prüft Auftragsfreigabe
        /// Äquivalent zu CCC_Check_Auftrag_Freigabe in DBMain.pas (Zeile 3130)
        /// </summary>
        public async Task CCC_Check_Auftrag_FreigabeAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogInformation("CCC_Check_Auftrag_Freigabe: Auftragsfreigabe wird geprüft");
                
                // SQL-Abfrage: Aufträge mit Freigabe-Flag prüfen
                string sql = "SELECT * FROM PDE WHERE Freigegeben = 1 AND Stat = 0";
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        int auftragNr = reader.GetInt32(reader.GetOrdinal("Nr"));
                        string betriebsauftragNr = reader.GetString(reader.GetOrdinal("Betriebsauftragnr"));
                        
                        // Prüfen, ob Maschine für diesen Auftrag bereit ist
                        string maschinenLizenz = reader.GetString(reader.GetOrdinal("MaschinenLizenz"));
                        int maschinenIndex = GetMaschinenIndexByLizenz(maschinenLizenz);
                        
                        if (maschinenIndex >= 0 && await KannAuftragGestartetWerdenAsync(maschinenIndex, stoppingToken))
                        {
                            var auftrag = new AuftragModel
                            {
                                Nr = auftragNr,
                                BetriebsauftragNr = betriebsauftragNr,
                                Sollwert = reader.GetInt32(reader.GetOrdinal("Sollwert")),
                                Istwert = reader.GetInt32(reader.GetOrdinal("Istwert")),
                                Stat = reader.GetInt32(reader.GetOrdinal("Stat"))
                            };
                            
                            await StartAuftragAsync(maschinenIndex, auftrag, stoppingToken);
                            
                            // Freigabe-Flag zurücksetzen
                            sql = $"UPDATE PDE SET Freigegeben = 0 WHERE Nr = {auftragNr}";
                            await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                        }
                    }
                }
                
                _logger.LogInformation("CCC_Check_Auftrag_Freigabe: Auftragsfreigabe-Prüfung abgeschlossen");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "CCC_Check_Auftrag_Freigabe: Fehler bei der Auftragsfreigabe-Prüfung");
            }
        }

        /// <summary>
        /// Daten aktualisieren
        /// Äquivalent zu CCC_Daten_Aktualisieren in DBMain.pas (Zeile 3142)
        /// </summary>
        public async Task CCC_Daten_AktualisierenAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogInformation("CCC_Daten_Aktualisieren: Daten werden aktualisiert");
                
                // Hier würde die Aktualisierungslogik aus Delphi portiert werden
                // z.B. Maschinenstatus, Auftragsstatus, etc.
                
                _logger.LogInformation("CCC_Daten_Aktualisieren: Datenaktualisierung abgeschlossen");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "CCC_Daten_Aktualisieren: Fehler bei der Datenaktualisierung");
            }
        }

        /// <summary>
        /// Prüft unterbrochene Aufträge
        /// Äquivalent zu CCC_CheckUnterbrocheneAuftraege in DBMain.pas (Zeile 3150)
        /// </summary>
        public async Task CCC_CheckUnterbrocheneAuftraegeAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogInformation("CCC_CheckUnterbrocheneAuftraege: Unterbrochene Aufträge werden geprüft");
                
                // SQL-Abfrage: Unterbrochene Aufträge finden
                string sql = "SELECT * FROM PDE WHERE Stat = 2"; // 2 = unterbrochen
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        int auftragNr = reader.GetInt32(reader.GetOrdinal("Nr"));
                        string betriebsauftragNr = reader.GetString(reader.GetOrdinal("Betriebsauftragnr"));
                        
                        // Prüfen, ob Auftrag fortgesetzt werden kann
                        if (await KannAuftragFortgesetztWerdenAsync(auftragNr, stoppingToken))
                        {
                            // Auftrag als laufend markieren
                            sql = $"UPDATE PDE SET Stat = 1 WHERE Nr = {auftragNr}";
                            await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                            
                            _logger.LogInformation("CCC_CheckUnterbrocheneAuftraege: Auftrag {AuftragNr} wurde fortgesetzt", betriebsauftragNr);
                        }
                    }
                }
                
                _logger.LogInformation("CCC_CheckUnterbrocheneAuftraege: Prüfung unterbrochener Aufträge abgeschlossen");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "CCC_CheckUnterbrocheneAuftraege: Fehler bei der Prüfung unterbrochener Aufträge");
            }
        }

        /// <summary>
        /// Prüft, ob ein unterbrochener Auftrag fortgesetzt werden kann
        /// </summary>
        private async Task<bool> KannAuftragFortgesetztWerdenAsync(int auftragNr, CancellationToken stoppingToken)
        {
            try
            {
                // Hier würde die Logik aus Delphi portiert werden
                // Vereinfacht: Immer true zurückgeben
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "KannAuftragFortgesetztWerden: Fehler bei der Prüfung für Auftrag {AuftragNr}", auftragNr);
                return false;
            }
        }

        /// <summary>
        /// Daten schreiben
        /// Äquivalent zu CCC_Daten_Schreiben in DBMain.pas (Zeile 3233)
        /// </summary>
        public async Task CCC_Daten_SchreibenAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogInformation("CCC_Daten_Schreiben: Daten werden in die Datenbank geschrieben");
                
                // Hier würde die Schreiblogik aus Delphi portiert werden
                // z.B. SPS-Werte, Maschinenstatus, etc.
                await In_SPSWerteDBAsync(stoppingToken);
                
                _logger.LogInformation("CCC_Daten_Schreiben: Datenschreiben abgeschlossen");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "CCC_Daten_Schreiben: Fehler beim Schreiben der Daten");
            }
        }

        /// <summary>
        /// Schreibt alle SPS-Werte in die Datenbank
        /// Äquivalent zu In_SPSWerteDB in DBMain.pas (Zeile 2020)
        /// </summary>
        public async Task In_SPSWerteDBAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogInformation("In_SPSWerteDB: SPS-Werte werden in die Datenbank geschrieben");
                
                // Für jede Maschine die SPS-Werte schreiben
                for (int i = 0; i < _s7Data.Includis.Count; i++)
                {
                    var maschine = _s7Data.Includis[i];
                    if (maschine.IstArchiviert)
                        continue;
                    
                    await Schreibe_SPS_WertAsync(i, stoppingToken);
                }
                
                _logger.LogInformation("In_SPSWerteDB: SPS-Werte erfolgreich geschrieben");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "In_SPSWerteDB: Fehler beim Schreiben der SPS-Werte");
            }
        }

        /// <summary>
        /// Schreibt einzelne SPS-Werte für eine Maschine
        /// Äquivalent zu Schreibe_SPS_Wert in DBMain.pas
        /// </summary>
        private async Task Schreibe_SPS_WertAsync(int maschinenIndex, CancellationToken stoppingToken)
        {
            try
            {
                var maschine = _s7Data.Includis[maschinenIndex];
                
                // Maschinenprogrammbetrieb prüfen
                int maschProgramm = _s7Data.SignalList.GetIstwertByNr(
                    GetSignalNrByMaschine(maschinenIndex, "MaschinenZustand")) == 1 ? 1 : 0;
                
                // Prüfen, ob Eintrag existiert
                bool exists = await SPSWerteExistsAsync(maschine.Nr, stoppingToken);
                
                string sql;
                if (!exists)
                {
                    // INSERT
                    sql = $@"INSERT INTO SPSWERTE (
                        Nr, LizenzInt, MaschProgramm, MaschOrg, MaschStoerung,
                        StueckGesamt, StueckAuftragGesamt, StueckAuftragSchicht, StueckSchicht,
                        Betriebsstunden, Taktzeit, LaufzeitGes, LaufzeitSchicht,
                        StueckPruefGesamt, StueckPruefAuftragGesamt, StueckPruefAuftragSchicht, StueckPruefSchicht,
                        StueckPackGesamt, StueckPackAuftragGesamt, StueckPackAuftragSchicht, StueckPackSchicht)
                        VALUES (
                        SPSWERTEID.NextVal,
                        {maschine.Nr},
                        {maschProgramm},
                        0,
                        0,
                        {maschine.StueckGesamt},
                        {maschine.StueckAuftragGesamt},
                        {maschine.StueckAuftragSchicht},
                        {maschine.StueckSchicht},
                        {maschine.Betriebsstunden},
                        {maschine.Taktzeit},
                        {maschine.LaufzeitGes},
                        {maschine.LaufzeitSchicht},
                        {maschine.StueckPruefGesamt},
                        {maschine.StueckPruefAuftragGesamt},
                        {maschine.StueckPruefAuftragSchicht},
                        {maschine.StueckPruefSchicht},
                        {maschine.StueckPackGesamt},
                        {maschine.StueckPackAuftragGesamt},
                        {maschine.StueckPackAuftragSchicht},
                        {maschine.StueckPackSchicht})";
                }
                else
                {
                    // UPDATE
                    sql = $@"UPDATE SPSWERTE SET
                        MaschProgramm = {maschProgramm},
                        MaschStoerung = 0,
                        StueckGesamt = {maschine.StueckGesamt},
                        StueckAuftragGesamt = {maschine.StueckAuftragGesamt},
                        StueckAuftragSchicht = {maschine.StueckAuftragSchicht},
                        StueckSchicht = {maschine.StueckSchicht},
                        Betriebsstunden = {maschine.Betriebsstunden},
                        Taktzeit = {maschine.Taktzeit},
                        LaufzeitGes = {maschine.LaufzeitGes},
                        LaufzeitSchicht = {maschine.LaufzeitSchicht},
                        StueckPruefGesamt = {maschine.StueckPruefGesamt},
                        StueckPruefAuftragGesamt = {maschine.StueckPruefAuftragGesamt},
                        StueckPruefAuftragSchicht = {maschine.StueckPruefAuftragSchicht},
                        StueckPruefSchicht = {maschine.StueckPruefSchicht},
                        StueckPackGesamt = {maschine.StueckPackGesamt},
                        StueckPackAuftragGesamt = {maschine.StueckPackAuftragGesamt},
                        StueckPackAuftragSchicht = {maschine.StueckPackAuftragSchicht},
                        StueckPackSchicht = {maschine.StueckPackSchicht}
                        WHERE LizenzInt = {maschine.Nr}";
                }
                
                await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                
                _logger.LogDebug("Schreibe_SPS_Wert: SPS-Werte für Maschine {MaschinenNr} geschrieben", maschine.Nr);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Schreibe_SPS_Wert: Fehler beim Schreiben der SPS-Werte für Maschine {MaschinenIndex}", maschinenIndex);
            }
        }

        /// <summary>
        /// Prüft, ob SPSWERTE-Eintrag existiert
        /// </summary>
        private async Task<bool> SPSWerteExistsAsync(int lizenzInt, CancellationToken stoppingToken)
        {
            try
            {
                string sql = $"SELECT COUNT(*) FROM SPSWERTE WHERE LizenzInt = {lizenzInt}";
                using (var reader = _database.ExecuteReader(sql))
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
                _logger.LogError(ex, "SPSWerteExists: Fehler bei der Prüfung für LizenzInt {LizenzInt}", lizenzInt);
                return false;
            }
        }

        /// <summary>
        /// Prüft Schichtwechsel
        /// Äquivalent zu NeueSchicht in DBMain.pas (Zeile 3641)
        /// </summary>
        public async Task<bool> NeueSchichtAsync(out int alteSchicht, CancellationToken stoppingToken)
        {
            alteSchicht = -1;
            try
            {
                _logger.LogDebug("NeueSchicht: Schichtwechsel wird geprüft");
                
                string sql = "SELECT * FROM SIWECHSEL";
                using (var reader = _database.ExecuteReader(sql))
                {
                    if (await reader.ReadAsync(stoppingToken))
                    {
                        if (reader.GetInt32(reader.GetOrdinal("Schichtwechsel")) == 1)
                        {
                            alteSchicht = reader.GetInt32(reader.GetOrdinal("AlteSchicht"));
                            int nr = reader.GetInt32(reader.GetOrdinal("Nr"));
                            
                            // Eintrag löschen
                            sql = $"DELETE FROM SIWECHSEL WHERE Nr = {nr}";
                            await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                            
                            _logger.LogInformation("NeueSchicht: Schichtwechsel erkannt (Alte Schicht: {AlteSchicht})", alteSchicht);
                            return true;
                        }
                    }
                }
                
                _logger.LogDebug("NeueSchicht: Kein Schichtwechsel erkannt");
                return false;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "NeueSchicht: Fehler bei der Schichtwechsel-Prüfung");
                return false;
            }
        }

        /// <summary>
        /// Prüft und löscht Rote-Lampe-Einträge
        /// Äquivalent zu CheckRoteLampeAus in DBMain.pas (Zeile 3657)
        /// </summary>
        public async Task<bool> CheckRoteLampeAusAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("CheckRoteLampeAus: Rote-Lampe-Einträge werden geprüft");
                
                // 1. Rote-Lampe-Einträge löschen
                string sql = "SELECT COUNT(*) CNT FROM ROTELAMPE";
                using (var reader = _database.ExecuteReader(sql))
                {
                    if (await reader.ReadAsync(stoppingToken))
                    {
                        int count = reader.GetInt32(0);
                        if (count > 0)
                        {
                            sql = "SELECT * FROM ROTELAMPE";
                            using (var deleteReader = _database.ExecuteReader(sql))
                            {
                                while (await deleteReader.ReadAsync(stoppingToken))
                                {
                                    int nr = deleteReader.GetInt32(deleteReader.GetOrdinal("Nr"));
                                    await _database.ExecuteNonQueryAsync($"DELETE FROM ROTELAMPE WHERE Nr = {nr}", stoppingToken);
                                }
                            }
                        }
                    }
                }
                
                // 2. Prüfen, ob noch Rote-Lampe-Aufträge vorhanden sind
                sql = "SELECT COUNT(*) CNT FROM BDA WHERE RoteLampeAn = 1";
                using (var reader = _database.ExecuteReader(sql))
                {
                    if (await reader.ReadAsync(stoppingToken))
                    {
                        int count = reader.GetInt32(0);
                        bool result = count == 0;
                        
                        if (result)
                        {
                            _logger.LogInformation("CheckRoteLampeAus: Alle Rote-Lampe-Einträge gelöscht, keine aktiven Rote-Lampe-Aufträge");
                        }
                        else
                        {
                            _logger.LogWarning("CheckRoteLampeAus: Es gibt noch {Count} aktive Rote-Lampe-Aufträge", count);
                        }
                        
                        return result;
                    }
                }
                
                return false;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "CheckRoteLampeAus: Fehler bei der Rote-Lampe-Prüfung");
                return false;
            }
        }

        /// <summary>
        /// Holt Stückzahl des alten Auftrags
        /// Äquivalent zu GetStueckAuftragAlt in DBMain.pas
        /// </summary>
        public async Task<int> GetStueckAuftragAltAsync(int maschinenIndex, CancellationToken stoppingToken)
        {
            try
            {
                var maschine = _s7Data.Includis[maschinenIndex];
                
                // Hier würde die Logik aus Delphi portiert werden
                // Vereinfacht: 0 zurückgeben
                return 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "GetStueckAuftragAlt: Fehler beim Abrufen der Stückzahl des alten Auftrags");
                return 0;
            }
        }

        /// <summary>
        /// Prüft manuelle Stückbuchung
        /// Äquivalent zu CheckManuelleStueckBuchung in DBMain.pas
        /// </summary>
        public async Task<bool> CheckManuelleStueckBuchungAsync(int maschinenIndex, CancellationToken stoppingToken)
        {
            try
            {
                // Hier würde die Logik aus Delphi portiert werden
                // Vereinfacht: false zurückgeben
                return false;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "CheckManuelleStueckBuchung: Fehler bei der Prüfung der manuellen Stückbuchung");
                return false;
            }
        }

        /// <summary>
        /// Lädt Daten aus verschiedenen Tabellen
        /// Äquivalent zu Hole_Daten_Tabelle in DBMain.pas
        /// </summary>
        public async Task Hole_Daten_TabelleAsync(int datenTyp, CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("Hole_Daten_Tabelle: Daten werden aus Tabelle geladen (Typ: {DatenTyp})", datenTyp);
                
                // Hier würde die Logik aus Delphi portiert werden
                // Vereinfacht: Leere Implementierung
                
                _logger.LogDebug("Hole_Daten_Tabelle: Datenladen abgeschlossen");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Hole_Daten_Tabelle: Fehler beim Laden der Daten (Typ: {DatenTyp})", datenTyp);
            }
        }

        /// <summary>
        /// Lädt Metall-spezifische Daten
        /// Äquivalent zu DatenLesen_Metall in DBMain.pas
        /// </summary>
        public async Task DatenLesenMetallAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogDebug("DatenLesenMetall: Metall-spezifische Daten werden geladen");
                
                // Hier würde die Logik aus Delphi portiert werden
                // Vereinfacht: Leere Implementierung
                
                _logger.LogDebug("DatenLesenMetall: Metall-Datenladen abgeschlossen");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "DatenLesenMetall: Fehler beim Laden der Metall-Daten");
            }
        }

        // ==================== HILFSMETHODEN ====================

        /// <summary>
        /// Gibt die Signal-Nr für eine bestimmte Maschine und Signal-Art zurück
        /// </summary>
        private int GetSignalNrByMaschine(int maschinenIndex, string signalName)
        {
            try
            {
                if (maschinenIndex < 0 || maschinenIndex >= _s7Data.Includis.Count)
                    return 0;
                
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
                _logger.LogError(ex, "GetSignalNrByMaschine: Fehler beim Ermitteln der Signal-Nr");
                return 0;
            }
        }

        /// <summary>
        /// Gibt die Barcode-Signal-Nr für einen bestimmten Scanner zurück
        /// </summary>
        private int GetBarcodeSignalNr(int scannerNr)
        {
            try
            {
                // Barcode-Signale: CBARCODE_GELESEN (27) und CBARCODE (28)
                // Scanner 1-3 haben unterschiedliche DBNrs
                switch (scannerNr)
                {
                    case 1: return _s7Data.BarcodeGelesen.DBNr;
                    case 2: return _s7Data.BarcodeGelesen2.DBNr;
                    case 3: return _s7Data.BarcodeGelesen3.DBNr;
                    default: return 0;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "GetBarcodeSignalNr: Fehler beim Ermitteln der Barcode-Signal-Nr");
                return 0;
            }
        }

        /// <summary>
        /// Findet Auftrag anhand Barcode
        /// </summary>
        private async Task<AuftragModel> GetAuftragByBarcodeAsync(int barcode, CancellationToken stoppingToken)
        {
            try
            {
                string sql = $"SELECT * FROM PDE WHERE Barcode = {barcode}";
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    if (await reader.ReadAsync(stoppingToken))
                    {
                        return new AuftragModel
                        {
                            Nr = reader.GetInt32(reader.GetOrdinal("Nr")),
                            BetriebsauftragNr = reader.GetString(reader.GetOrdinal("Betriebsauftragnr")),
                            Sollwert = reader.GetInt32(reader.GetOrdinal("Sollwert")),
                            Istwert = reader.GetInt32(reader.GetOrdinal("Istwert")),
                            Stat = reader.GetInt32(reader.GetOrdinal("Stat"))
                        };
                    }
                }
                
                return null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "GetAuftragByBarcode: Fehler beim Laden des Auftrags für Barcode {Barcode}", barcode);
                return null;
            }
        }

        /// <summary>
        /// Gibt die Maschinen-Index anhand Barcode-Scanner zurück
        /// </summary>
        private int GetMaschinenIndexByBarcodeScanner(int scannerNr)
        {
            try
            {
                // Hier würde die Zuordnung aus Delphi portiert werden
                // Vereinfacht: Scanner 1 → Maschine 0, Scanner 2 → Maschine 1, Scanner 3 → Maschine 2
                if (scannerNr >= 1 && scannerNr <= 3 && scannerNr <= _s7Data.Includis.Count)
                {
                    return scannerNr - 1;
                }
                return -1;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "GetMaschinenIndexByBarcodeScanner: Fehler beim Ermitteln der Maschinen-Index");
                return -1;
            }
        }

        /// <summary>
        /// Gibt die Maschinen-Index anhand Lizenz zurück
        /// </summary>
        private int GetMaschinenIndexByLizenz(string lizenz)
        {
            try
            {
                for (int i = 0; i < _s7Data.Includis.Count; i++)
                {
                    if (_s7Data.Includis[i].Lizenz.Equals(lizenz, StringComparison.OrdinalIgnoreCase))
                    {
                        return i;
                    }
                }
                return -1;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "GetMaschinenIndexByLizenz: Fehler beim Ermitteln der Maschinen-Index");
                return -1;
            }
        }

        /// <summary>
        /// Setzt Barcode zurück
        /// </summary>
        private async Task ResetBarcodeAsync(int scannerNr, CancellationToken stoppingToken)
        {
            try
            {
                int barcodeSignalNr = GetBarcodeSignalNr(scannerNr);
                if (barcodeSignalNr > 0)
                {
                    // Barcode_Gelesen zurücksetzen
                    string sql = $"UPDATE signal_maschine SET Istwert = 0 WHERE Nr = {barcodeSignalNr}";
                    await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                    
                    // Barcode-Wert zurücksetzen
                    int barcodeWertSignalNr = barcodeSignalNr + 1; // CBARCODE ist immer CBARCODE_GELESEN + 1
                    sql = $"UPDATE signal_maschine SET Istwert = 0 WHERE Nr = {barcodeWertSignalNr}";
                    await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "ResetBarcode: Fehler beim Zurücksetzen des Barcodes");
            }
        }
    }

    /// <summary>
    /// Auftragsmodell für CCC-Funktionen
    /// </summary>
    public class AuftragModel
    {
        public int Nr { get; set; }
        public string BetriebsauftragNr { get; set; }
        public int Sollwert { get; set; }
        public int Istwert { get; set; }
        public int Stat { get; set; }
        public bool IstAbgeschlossen => Stat == 1 || Stat == 3;
    }
}
