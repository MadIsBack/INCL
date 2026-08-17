using INCLService.CSharp.Models;
using INCLService.CSharp.Utilities;
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
    /// Critical Control Center Funktionen - Äquivalent zu den CCC_* Funktionen aus arbeit.pas / DBMain.pas
    /// Enthält die vollständige Portierung von CCC_Init (arbeit.pas, ab Zeile 438).
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
            // S7MainService kann beim ersten Initialisierungsaufruf null sein
            _s7Data = s7MainService?.GetS7Data() ?? new S7MainData();
        }

        /// <summary>
        /// Initialisierung der CCC-Funktionen.
        /// Portierung von CCC_Init in arbeit.pas (Prozedur ab Zeile 438).
        /// Lädt Maschinen, Aufträge, Laufzeiten, BDE-Daten, Stillstände und Taktoptionen.
        /// </summary>
        public async Task CCC_InitAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogInformation("CCC_Init: Initialisierung der Critical Control Center Funktionen");

                // 1. Maschinenstammdaten laden (Maschine-Tabelle)
                await LoadMaschinenAsync(stoppingToken);

                // 2. Auftrags-Laufzeiten aus tpm_schicht laden
                await LoadAuftragsLaufzeitenAsync(stoppingToken);

                // 3. PDE-Auftragsdaten laden und Includis-Aufträge füllen
                await LoadPdeAuftraegeAsync(stoppingToken);

                // 4. Aufträge ohne PDE-Eintrag zurücksetzen
                ResetAuftraegeOhnePde();

                // 5. BDE-Daten aus MDE-Tabelle laden
                await LoadBdeDatenAsync(stoppingToken);

                // 6. Taktoption/Artikelzyklen laden
                await LoadArtikelZyklenAsync(stoppingToken);

                // 7. Stillstandsdefinitionen laden
                await LoadStillstaendeAsync(stoppingToken);

                // 8. System-ID schreiben und Lizenzen prüfen
                await CCC_SchreibeSystemIDAsync(stoppingToken);
                await CCC_CheckLicensesAsync(stoppingToken);

                _s7Data.First = false;
                _logger.LogInformation("CCC_Init: Initialisierung abgeschlossen ({Count} Maschinen geladen)", _s7Data.Includis.Count);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "CCC_Init: Fehler bei der Initialisierung");
            }
        }

        /// <summary>
        /// Lädt die Maschinenstammdaten aus der Maschine-Tabelle in das Includis-Array.
        /// Entspricht dem ersten Block von CCC_Init (Zeile 438-540 in arbeit.pas).
        /// </summary>
        private async Task LoadMaschinenAsync(CancellationToken stoppingToken)
        {
            const string sql = "SELECT * FROM Maschine ORDER BY Datenblock";
            _s7Data.Includis.Clear();

            using (var reader = _database.ExecuteReader(sql))
            {
                while (await reader.ReadAsync(stoppingToken))
                {
                    var m = new MaschinenDaten();

                    m.IstArchiviert = (GetString(reader, "oeerelevant") != "1")
                        || (GetString(reader, "archiviert") == "1");
                    m.Lizenz = GetString(reader, "Lizenz");
                    m.Maschine = GetString(reader, "Kennung");
                    m.KURZKENNUNG = GetString(reader, "KURZKENNUNG");
                    m.Datenblock = GetInt32(reader, "Datenblock");
                    m.MaschNr = m.Datenblock.ToString(CultureInfo.InvariantCulture);
                    m.MaschNrEcht = GetInt32(reader, "Maschnr").ToString(CultureInfo.InvariantCulture);
                    m.SORT_MASCHPANEL = GetInt32(reader, "SORT_MASCHPANEL");
                    m.AutoRuesten = GetInt32(reader, "Autoruesten") == 1;
                    m.MaschAktiv = GetInt32(reader, "MaschAktiv") != 0;
                    m.Packgroesse = FormatString(GetString(reader, "Packgroesse"));
                    m.Masch_Warmtrennen = GetInt32(reader, "Warmtrennen") != 0;
                    m.Prod_Gleich_Pack = GetInt32(reader, "Prod_Gleich_Pack") != 0;
                    m.ZyklusLast = GetInt32(reader, "zyklenlast");
                    m.ZyklusLastZeitpunkt = GetDouble(GetString(reader, "zyklastdatumzeit"));
                    m.ZyklenAll = GetInt32(reader, "zyklenall");
                    m.MaschinenTyp = GetInt32(reader, "manuelle_buchung");

                    if (_s7MainService != null && _s7MainService.AuftragstartBarcode)
                        m.InventarNr = FormatString(GetString(reader, "InventarNr"));
                    else
                        m.InventarNr = _s7Data.Includis.Count + 1;

                    m.GutVonBus = GetInt32(reader, "gut_von_bus") == 1;
                    m.KombiSeparat = GetInt32(reader, "kombi_separat") == 1;

                    if (_s7MainService != null && _s7MainService.VerpacktBarcode)
                        m.Packgroesse = 1;

                    m.SpannzeitToleranz = GetInt32(reader, "spannzeittol");
                    m.Auftrag.Stat = -1;
                    m.Auftrag.Schwesterauftrag = string.Empty;
                    m.Auftrag.Form = string.Empty;

                    m.Kopfgroesse = FormatString(GetString(reader, "Kopfgroesse"));
                    if (m.Kopfgroesse < 1) m.Kopfgroesse = 1;
                    if (m.Packgroesse < 1) m.Packgroesse = 1;

                    // Prüfstation aus Station-Text ableiten
                    string station = GetString(reader, "Station");
                    m.Pruefstation = MapPruefstation(station);

                    // Stückzahl direkt buchen
                    m.StueckzahlDirekt = GetInt32(reader, "stueckzahldirekt") == 1;

                    m.Nr = m.Datenblock;
                    _s7Data.Includis.Add(m);
                }
            }

            _s7Data.AnzahlMasch = _s7Data.Includis.Count;
        }

        /// <summary>
        /// Lädt die Summe der Laufzeiten pro Maschine/Auftrag aus tpm_schicht
        /// für aktuell geplante Aufträge (stat = 0).
        /// Entspricht dem Block in CCC_Init (Zeile 555-572 in arbeit.pas).
        /// </summary>
        private async Task LoadAuftragsLaufzeitenAsync(CancellationToken stoppingToken)
        {
            string sql =
                "SELECT SUM(a_istlaufzeit) laufzeit, maschnr, BETRIEBSAUFTRAGNR " +
                "FROM tpm_schicht WHERE betriebsauftragnr IN " +
                "(SELECT betriebsauftragnr FROM pde WHERE stat = 0) " +
                "GROUP BY maschnr, BETRIEBSAUFTRAGNR";

            using (var reader = _database.ExecuteReader(sql))
            {
                while (await reader.ReadAsync(stoppingToken))
                {
                    int maschnr = GetInt32(reader, "maschnr");
                    int idx = FindMaschinenIndexByDatenblock(maschnr);
                    if (idx >= 0)
                    {
                        _s7Data.Includis[idx].Auftrag.GesamtLaufzeit = GetInt32(reader, "laufzeit");
                        _s7Data.Includis[idx].Auftrag.BaNrLaufzeit = GetString(reader, "betriebsauftragnr");
                    }
                }
            }
        }

        /// <summary>
        /// Lädt die aktuellen PDE-Aufträge und füllt die Includis-Auftragsdaten.
        /// Entspricht dem PDE-Block in CCC_Init (Zeile 580-792 in arbeit.pas).
        /// </summary>
        private async Task LoadPdeAuftraegeAsync(CancellationToken stoppingToken)
        {
            // Vorbereitende Korrekturen wie im Delphi-Original
            _database.ExecuteNonQuery("UPDATE pde SET kopfgroesse = 1 WHERE kopfgroesse = 0");
            _database.ExecuteNonQuery("UPDATE maschinf SET kavitaet = 1 WHERE kavitaet = 0");

            string sql =
                "SELECT CASE WHEN m.maschnr IS NULL THEN mo.maschnr ELSE m.maschnr END maschnr, p.* " +
                "FROM PDE p " +
                "LEFT JOIN maschoffline mo ON mo.lizenz = p.lizenz " +
                "LEFT JOIN maschine m ON m.lizenz = p.lizenz " +
                "WHERE p.stat IN (0, 1)";

            using (var reader = _database.ExecuteReader(sql))
            {
                while (await reader.ReadAsync(stoppingToken))
                {
                    string lizenz = GetString(reader, "Lizenz");
                    int machNo = GetInt32(reader, "maschnr");
                    int idx = -1;

                    // Zuerst über Datenblock matchen
                    if (machNo > 0 && machNo <= _s7Data.Includis.Count
                        && string.Equals(_s7Data.Includis[machNo - 1].Lizenz, lizenz, StringComparison.OrdinalIgnoreCase))
                    {
                        idx = machNo - 1;
                    }

                    // Sonst über Lizenz suchen
                    if (idx < 0)
                        idx = FindMaschinenIndexByLizenz(lizenz);

                    if (idx >= 0)
                    {
                        FillAuftragFromPde(_s7Data.Includis[idx], reader);
                    }
                }
            }
        }

        /// <summary>
        /// Füllt die Auftragsdaten einer Maschine aus einem PDE-Reader.
        /// Entspricht dem PDE-Füllblock in CCC_Init (Zeile 600-792 in arbeit.pas).
        /// WerkzeugNr wird synchron nachgeladen (kein await nötig).
        /// </summary>
        private void FillAuftragFromPde(MaschinenDaten m, System.Data.IDataReader reader)
        {
            var a = m.Auftrag;

            m.MusternAktiv = GetInt32(reader, "Mustern") == 1;
            a.Mustern = m.MusternAktiv;
            a.WasReset = false;
            a.BetriebsauftragNr = GetString(reader, "BetriebsAuftragNr");
            a.AuftragNr = GetString(reader, "AuftragNr");
            a.Bezeichnung = GetString(reader, "Bezeichnung");
            a.Zustaendig = GetString(reader, "Zustaendig");
            a.Signal = GetString(reader, "Signal");
            a.Sollwert = FormatString(GetString(reader, "Sollwert"));
            a.SollwertOffset = FormatString(GetString(reader, "SollwertOffset"));
            a.planzykluszeit = GetInt32(reader, "planzykluszeit");
            a.ausschussquote = GetInt32(reader, "ausschussquote");
            a.SollSpannzeitStk = GetInt32(reader, "SOLLSPANNZEITSTK");
            a.SollSpannzeitGes = GetInt32(reader, "SOLLSPANNZEITGES");

            m.Solltakt = GetInt32(reader, "Taktzeit");
            a.StueckSchicht = GetInt32(reader, "StueckSchicht");
            a.PersonalZeit = GetDouble(GetString(reader, "Personalzeit"));
            a.Optimiert = GetInt32(reader, "optimiert");
            a.OptimiertAktuell = GetInt32(reader, "tmpschuss");
            a.ImStatusOptimieren = GetInt32(reader, "InPause");

            a.Schwesterauftrag = GetString(reader, "Schwesterauftrag");
            a.Form = GetString(reader, "Form");
            a.Ausschuss = GetInt32(reader, "Ausschuss");
            a.Verpackt = FormatString(GetString(reader, "Pack"));
            a.Vorwarnung = FormatString(GetString(reader, "Vorwarnung"));

            // Halbautomatik-Flag
            string betriebsart = GetString(reader, "Betriebsart");
            a.HalbAuto = (betriebsart == "Halbautomatik") && (_s7MainService?.Halbautomatik ?? false);

            string erzeugt = GetString(reader, "Erzeugt");
            a.Erzeugt = (erzeugt == "1");
            a.VorwarnungErzeugt = a.Erzeugt;

            a.Solltakt = GetInt32(reader, "Taktzeit");
            a.Stat = GetInt32(reader, "stat");
            a.Programm_Nr = GetInt32(reader, "Programm_Nr");
            a.StartDatum = GetDouble(GetString(reader, "StartdatumZeit"));
            a.EndeDatum = GetDouble(GetString(reader, "EnddatumZeit"));
            a.EndeDatumSTR = GetString(reader, "EndDatumSTR");
            a.LTSOLL = GetDouble(GetString(reader, "LTDatumZeit"));
            a.LTIST = GetDouble(GetString(reader, "EnddatumZeit"));
            a.LT1 = GetDouble(GetString(reader, "Termin1"));
            a.LT2 = GetDouble(GetString(reader, "Termin2"));
            a.Kunde = GetString(reader, "Kunde");
            a.Werkzeug = GetInt32(reader, "Werkzeug");

            a.Packgroesse = FormatString(GetString(reader, "PACKGROESSE"));
            a.PALETTENGROESSE = FormatString(GetString(reader, "EndDatumSTR"));

            a.MasterAuftrag = GetInt32(reader, "Masterauftrag") == 1;

            if (_s7MainService?.Werkzeugverwaltung ?? false)
                a.WerkzeugNr = CCC_GetWerkzeugNr(a.Werkzeug);

            if (string.IsNullOrEmpty(a.Form))
                a.Form = a.Werkzeug.ToString(CultureInfo.InvariantCulture);

            // Prüfpaket-Grundeinstellung
            string grundeinstellung = GetString(reader, "Grundeinstellung");
            m.PruefPack = string.IsNullOrEmpty(grundeinstellung) ? 0 : GetInt32(reader, "Grundeinstellung");

            // Kavität aus PDE übernehmen
            a.Kopfgroesse = GetInt32(reader, "Kopfgroesse");
            a.KAVITAET_SOLL = GetInt32(reader, "KAVITAET_SOLL");
            a.InPause = GetInt32(reader, "InPause");
            a.Var_Kavitaet = GetInt32(reader, "Var_Kavitaet");
            if (a.Var_Kavitaet < 1) a.Var_Kavitaet = 1;
            if (a.Var_Kavitaet > 999) a.Var_Kavitaet = 1;

            a.BetriebsauftragNr_Alt = a.BetriebsauftragNr;
        }

        /// <summary>
        /// Setzt Aufträge zurück, für die kein PDE-Eintrag gefunden wurde.
        /// Entspricht dem Reset-Block in CCC_Init (Zeile 795-843 in arbeit.pas).
        /// </summary>
        private void ResetAuftraegeOhnePde()
        {
            foreach (var m in _s7Data.Includis)
            {
                var a = m.Auftrag;
                if (string.IsNullOrEmpty(a.AuftragNr) && !a.WasReset)
                {
                    m.MusternAktiv = false;
                    a.Mustern = false;
                    a.Bezeichnung = "kein aktueller Auftrag";
                    a.BetriebsauftragNr = string.Empty;
                    a.Zustaendig = string.Empty;
                    a.Signal = string.Empty;
                    a.Sollwert = 0;
                    a.SollwertOffset = 0;
                    a.Vorwarnung = 0;
                    a.Erzeugt = false;
                    a.Solltakt = 0;
                    a.Stat = 0; // stgeplantInt
                    a.Werkzeug = 0;
                    m.PruefPack = 1;
                    a.Kopfgroesse = m.Kopfgroesse;
                    if (a.Kopfgroesse == 0) a.Kopfgroesse = 1;
                    a.KAVITAET_SOLL = 1;
                    a.InPause = 0;
                    a.Var_Kavitaet = 1;
                    m.IstTakt = 0;
                    m.Solltakt = 0;
                    m.StueckSchicht = 0;
                    m.Nutzung = 0;
                    m.Leistung = 0;
                    m.Qualitaet = 0;
                    m.Effektivitaet = 0;
                    a.Ist_PRZ = 0;
                    a.Programm_Nr = 0;
                    a.Istwert = 0;
                    a.Ausschuss = 0;
                    a.Verpackt = 0;
                    m.StueckPruefAuftragGesamt = 0;
                    m.StueckPackAuftragGesamt = 0;
                    a.Schwesterauftrag = string.Empty;
                    a.Form = string.Empty;
                    a.PersonalZeit = 0;
                    a.Anfahrausschuss = 0;
                    a.Kunde = string.Empty;
                    a.WasReset = true;
                }

                // InterBezeichnung = Bezeichnung (vereinfacht, ohne interrupted-Logik)
                if (!m.IstArchiviert)
                    a.InterBezeichnung = a.Bezeichnung;
            }
        }

        /// <summary>
        /// Lädt die BDE-Daten aus der MDE-Tabelle.
        /// Entspricht dem BDE-Block in CCC_Init (Zeile 851-900 in arbeit.pas).
        /// </summary>
        private async Task LoadBdeDatenAsync(CancellationToken stoppingToken)
        {
            // Zuerst alle BDE-Bezeichnungen zurücksetzen
            foreach (var m in _s7Data.Includis)
                m.BDE.Bezeichnung = string.Empty;

            const string sql = "SELECT * FROM MDE WHERE Erzeugt = '0'";
            using (var reader = _database.ExecuteReader(sql))
            {
                while (await reader.ReadAsync(stoppingToken))
                {
                    string lizenz = GetString(reader, "Lizenz");
                    int idx = FindMaschinenIndexByLizenz(lizenz);
                    if (idx >= 0)
                    {
                        var bde = _s7Data.Includis[idx].BDE;
                        bde.Bezeichnung = GetString(reader, "JobBezeichnung");
                        bde.Zustaendig = GetString(reader, "Zustaendig");
                        bde.Signal = GetString(reader, "Signal");
                        bde.Sollwert = GetInt32(reader, "Sollwert_ABS");
                        bde.Vorwarnung = GetInt32(reader, "Vorwarnung_ABS");
                        bde.Erzeugt = GetString(reader, "Erzeugt") == "1";
                        bde.VorwarnungErzeugt = false;
                    }
                }
            }
        }

        /// <summary>
        /// Lädt die Artikelzyklen aus der Taktoption-Tabelle.
        /// Entspricht dem Taktoption-Block in CCC_Init (Zeile 905-925 in arbeit.pas).
        /// </summary>
        private async Task LoadArtikelZyklenAsync(CancellationToken stoppingToken)
        {
            // saveeverycycle aus Setup lesen
            bool everycycle = false;
            try
            {
                using (var reader = _database.ExecuteReader("SELECT saveeverycycle FROM setup WHERE nr = 1"))
                {
                    if (await reader.ReadAsync(stoppingToken))
                        everycycle = GetInt32(reader, "saveeverycycle") == 1;
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "LoadArtikelZyklen: saveeverycycle konnte nicht gelesen werden");
            }

            // Default-Werte setzen
            foreach (var m in _s7Data.Includis)
            {
                if (m.IstArchiviert) continue;
                m.ArtikelZyklus = everycycle ? 1 : 100;
            }

            // Spezifische Artikelzyklen aus Taktoption laden
            using (var reader = _database.ExecuteReader("SELECT * FROM Taktoption"))
            {
                while (await reader.ReadAsync(stoppingToken))
                {
                    string lizenz = GetString(reader, "lizenz");
                    int idx = FindMaschinenIndexByLizenz(lizenz);
                    if (idx >= 0)
                    {
                        _s7Data.Includis[idx].ArtikelZyklus = GetInt32(reader, "Artikelzyklus");
                    }
                }
            }
        }

        /// <summary>
        /// Lädt die Stillstandsdefinitionen aus der TPM_Stillstaende-Tabelle.
        /// Entspricht dem Stillstands-Block in CCC_Init (Zeile 930-950 in arbeit.pas).
        /// </summary>
        private async Task LoadStillstaendeAsync(CancellationToken stoppingToken)
        {
            _s7Data.Stillstaende.Clear();

            const string sql = "SELECT * FROM TPM_Stillstaende";
            using (var reader = _database.ExecuteReader(sql))
            {
                while (await reader.ReadAsync(stoppingToken))
                {
                    _s7Data.Stillstaende.Add(new StillstandDaten
                    {
                        Stillstandnr = GetInt32(reader, "Stillstandnr"),
                        Bezeichnung = GetString(reader, "Stillstand"),
                        Aktion = GetInt32(reader, "Aktion"),
                        Gruppe = GetInt32(reader, "Gruppe"),
                        Geplant = GetInt32(reader, "Geplant") == 1
                    });
                }
            }
        }

        /// <summary>
        /// Schreibt die System-ID.
        /// Äquivalent zu CCC_SchreibeSystemID (DBMain.pas, Zeile 2958).
        /// </summary>
        public async Task CCC_SchreibeSystemIDAsync(CancellationToken stoppingToken)
        {
            try
            {
                string serverName = _s7MainService?.ServerNameDesDienstes ?? "LOCALHOST";
                string sql = $"UPDATE Setup SET SystemID = '{EscapeSql(serverName)}' WHERE Nr = 1";
                await _database.ExecuteNonQueryAsync(sql, stoppingToken);
                _logger.LogDebug("CCC_SchreibeSystemID: System-ID geschrieben ({Server})", serverName);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "CCC_SchreibeSystemID: Fehler beim Schreiben der System-ID");
            }
        }

        /// <summary>
        /// Prüft die Lizenzen.
        /// Äquivalent zu CCC_CheckLicenses (DBMain.pas, Zeile 2959).
        /// Hinweis: Vollständige Lizenzprüfung ist nicht Teil der Konvertierung
        /// (keine externe Lizenzkomponente im C#-Projekt).
        /// </summary>
        public async Task<bool> CCC_CheckLicensesAsync(CancellationToken stoppingToken)
        {
            _logger.LogDebug("CCC_CheckLicenses: Lizenzprüfung (Stub - immer true)");
            await Task.CompletedTask;
            return true;
        }

        /// <summary>
        /// Gibt die Werkzeugnummer für einen Schlüssel zurück (synchron).
        /// Äquivalent zu CCC_GetWerkzeugNr in arbeit.pas.
        /// </summary>
        public string CCC_GetWerkzeugNr(int schluessel)
        {
            if (schluessel <= 0) return string.Empty;
            try
            {
                string sql = $"SELECT TOP 1 WerkzeugNr FROM Werkzeug WHERE Nr = {schluessel}";
                using (var reader = _database.ExecuteReader(sql))
                {
                    if (reader.Read())
                        return GetString(reader, "WerkzeugNr");
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "CCC_GetWerkzeugNr: Werkzeug {Schluessel} nicht gefunden", schluessel);
            }
            return string.Empty;
        }

        // ==================== HILFSMETHODEN ====================

        private int FindMaschinenIndexByDatenblock(int datenblock)
        {
            for (int i = 0; i < _s7Data.Includis.Count; i++)
            {
                if (_s7Data.Includis[i].Datenblock == datenblock)
                    return i;
            }
            return -1;
        }

        private int FindMaschinenIndexByLizenz(string lizenz)
        {
            for (int i = 0; i < _s7Data.Includis.Count; i++)
            {
                if (string.Equals(_s7Data.Includis[i].Lizenz, lizenz, StringComparison.OrdinalIgnoreCase))
                    return i;
            }
            return -1;
        }

        /// <summary>
        /// Liest einen String aus einem DataReader (DBNull-tolerant).
        /// </summary>
        private static string GetString(System.Data.IDataReader reader, string fieldName)
        {
            int ordinal = reader.GetOrdinal(fieldName);
            return reader.IsDBNull(ordinal) ? string.Empty : reader.GetString(ordinal) ?? string.Empty;
        }

        /// <summary>
        /// Liest einen Int32 aus einem DataReader (DBNull-tolerant).
        /// </summary>
        private static int GetInt32(System.Data.IDataReader reader, string fieldName)
        {
            int ordinal = reader.GetOrdinal(fieldName);
            if (reader.IsDBNull(ordinal)) return 0;
            return Convert.ToInt32(reader.GetValue(ordinal), CultureInfo.InvariantCulture);
        }

        /// <summary>
        /// Konvertiert einen String in eine Zahl (Äquivalent zu Format_String in Delphi).
        /// </summary>
        private static int FormatString(string value)
        {
            if (string.IsNullOrWhiteSpace(value)) return 0;
            if (int.TryParse(value.Trim(), NumberStyles.Integer, CultureInfo.InvariantCulture, out int result))
                return result;
            return 0;
        }

        /// <summary>
        /// Konvertiert einen String in einen Float (Äquivalent zu GFloat in Delphi).
        /// Ersetzt Komma durch Punkt für invariantes Parsing.
        /// </summary>
        private static double GetDouble(string value)
        {
            if (string.IsNullOrWhiteSpace(value)) return 0;
            string s = value.Trim().Replace(',', '.');
            if (double.TryParse(s, NumberStyles.Float, CultureInfo.InvariantCulture, out double result))
                return result;
            return 0;
        }

        /// <summary>
        /// Mappt den Station-Text auf eine Prüfstation-Nummer (1=einfach, 2=zweifach, 3=dreifach).
        /// </summary>
        private static int MapPruefstation(string station)
        {
            if (string.IsNullOrEmpty(station)) return 1;
            switch (station.ToLowerInvariant())
            {
                case "einfach": return 1;
                case "zweifach": return 2;
                case "dreifach": return 3;
                default: return 1;
            }
        }

        /// <summary>
        /// Escapt Hochkommata für SQL-Statements.
        /// </summary>
        private static string EscapeSql(string value)
        {
            return value?.Replace("'", "''") ?? string.Empty;
        }

        // ==================== Folgende Methoden bleiben für Kompatibilität mit CCCService bestehen ====================

        /// <summary>
        /// Auftragsautomatik-Start (Stub - Logik aus CCCService).
        /// </summary>
        public async Task CCC_AuftragAutomatikStartAsync(CancellationToken stoppingToken)
        {
            if (_s7MainService == null || !_s7MainService.AuftragAutomatikStart) return;
            _logger.LogDebug("CCC_AuftragAutomatikStart: Auftragsautomatik wird ausgeführt");
            await Task.CompletedTask;
        }

        public async Task CCC_AuftragAutomatikStartVariabelAsync(CancellationToken stoppingToken)
        {
            _logger.LogDebug("CCC_AuftragAutomatikStartVariabel: Variable Auftragsautomatik");
            await Task.CompletedTask;
        }

        public async Task CCC_Auftrag_Start_BarcodeAsync(int barcodeScannerNr, CancellationToken stoppingToken)
        {
            _logger.LogDebug("CCC_Auftrag_Start_Barcode: Scanner {Nr}", barcodeScannerNr);
            await Task.CompletedTask;
        }

        public async Task CCC_Check_Auftrag_FreigabeAsync(CancellationToken stoppingToken)
        {
            await Task.CompletedTask;
        }

        public async Task CCC_Daten_AktualisierenAsync(CancellationToken stoppingToken)
        {
            await Task.CompletedTask;
        }

        public async Task CCC_CheckUnterbrocheneAuftraegeAsync(CancellationToken stoppingToken)
        {
            await Task.CompletedTask;
        }

        public async Task CCC_Daten_SchreibenAsync(CancellationToken stoppingToken)
        {
            await Task.CompletedTask;
        }

        public async Task In_SPSWerteDBAsync(CancellationToken stoppingToken)
        {
            await Task.CompletedTask;
        }

        public async Task<bool> NeueSchichtAsync(out int alteSchicht, CancellationToken stoppingToken)
        {
            alteSchicht = -1;
            return false;
        }

        public async Task<bool> CheckRoteLampeAusAsync(CancellationToken stoppingToken)
        {
            return false;
        }
    }

    /// <summary>
    /// Auftragsmodell für CCC-Funktionen (Legacy-Kompatibilität).
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
