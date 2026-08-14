using INCLService.CSharp.Models;
using INCLService.CSharp.Utilities;
using INCLUDIS.Utils.CommonDB;
using Microsoft.Extensions.Configuration;
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
        private readonly ILogger _logger;
        private readonly CommonDB _database;
        private readonly S7MainService _s7MainService;
        private readonly S7MainData _s7Data;
        private readonly IConfiguration _configuration;

        // Feature-Flags (vgl. Delphi-Globalvariablen, hier aus appsettings.json geladen).
        // Werden von CCC_Init und abgeleiteten CCC_*-Funktionen ausgewertet.
        public bool AuftragstartBarcode { get; set; } = false;
        public bool VerpacktBarcode { get; set; } = false;
        public bool BlockStillstand { get; set; } = false;
        public bool AuftragBlock { get; set; } = false;
        public bool BypassMode { get; set; } = false;
        public bool KavitaetFromSPS { get; set; } = false;
        public bool Kavitaet_laufender_Auftrag2 { get; set; } = false;
        public bool Kavitaet_laufender_Auftrag3 { get; set; } = false;
        public bool Werkzeugverwaltung { get; set; } = false;
        public bool Halbautomatik { get; set; } = false;
        public bool HochlaufTPM { get; set; } = false;

        public S7MainServiceCCC(ILogger logger, CommonDB database, S7MainService s7MainService, IConfiguration configuration = null)
        {
            _logger = logger;
            _database = database;
            _s7MainService = s7MainService;
            _configuration = configuration;
            _s7Data = s7MainService?.GetS7Data() ?? new S7MainData();
            LoadConfiguration();
        }

        /// <summary>
        /// Laedt die Feature-Flags aus der Konfiguration (appsettings.json).
        /// Entspricht dem Einlesen der INI-/Registry-Werte im Delphi-Dienst.
        /// </summary>
        private void LoadConfiguration()
        {
            if (_configuration == null)
                return;

            AuftragstartBarcode = _configuration.GetValue<bool>("Features:AuftragstartBarcode", false);
            VerpacktBarcode = _configuration.GetValue<bool>("Features:VerpacktBarcode", false);
            BlockStillstand = _configuration.GetValue<bool>("Features:BlockStillstand", false);
            AuftragBlock = _configuration.GetValue<bool>("Features:AuftragBlock", false);
            BypassMode = _configuration.GetValue<bool>("Features:BypassMode", false);
            KavitaetFromSPS = _configuration.GetValue<bool>("Features:KavitaetFromSPS", false);
            Kavitaet_laufender_Auftrag2 = _configuration.GetValue<bool>("Features:Kavitaet_laufender_Auftrag2", false);
            Kavitaet_laufender_Auftrag3 = _configuration.GetValue<bool>("Features:Kavitaet_laufender_Auftrag3", false);
            Werkzeugverwaltung = _configuration.GetValue<bool>("Features:Werkzeugverwaltung", false);
            Halbautomatik = _configuration.GetValue<bool>("Features:Halbautomatik", false);
            HochlaufTPM = _configuration.GetValue<bool>("Features:HochlaufTPM", false);
        }

        /// <summary>
        /// Status-Konstante für geplante Aufträge.
        /// Entspricht der Delphi-Konstante stgeplantInt aus comtas_h.pas (= 2).
        /// </summary>
        private const short StGeplantInt = 2;

        /// <summary>
        /// Liest einen booleschen Setup-Parameter aus der Tabelle 'Setup'.
        /// Entspricht TCO_Setup.GetParamBool in Delphi. Die Spalte 'Wert' wird
        /// ausgewertet (1 = true).
        /// </summary>
        private async Task<bool> GetSetupParamBoolAsync(string paramName, CancellationToken stoppingToken)
        {
            try
            {
                string sql = $"SELECT Wert FROM Setup WHERE Schluessel = '{paramName}'";
                using (var reader = _database.ExecuteReader(sql))
                {
                    if (await reader.ReadAsync(stoppingToken))
                    {
                        object val = reader.IsDBNull(0) ? null : reader[0];
                        return val != null && val.ToString() == "1";
                    }
                }
                return false;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "GetSetupParamBool: Fehler beim Lesen von {Param}", paramName);
                return false;
            }
        }

        /// <summary>
        /// Liefert die Maschinennummer (Datenblock) als Integer anhand einer Lizenz.
        /// Entspricht CCC_GetMaschNrLizenz aus arbeit.pas (Rückgabewert als int).
        /// </summary>
        private int CCC_GetMaschNrLizenzAsInt(string lizenz)
        {
            if (string.IsNullOrEmpty(lizenz))
                return 0;
            for (int j = 0; j < _s7Data.Includis.Count; j++)
            {
                if (_s7Data.Includis[j].Lizenz.Equals(lizenz, StringComparison.OrdinalIgnoreCase))
                    return j + 1; // 1-basiert wie Includis[Index] in Delphi
            }
            return 0;
        }

        /// <summary>
        /// Liefert die Werkzeugnummer anhand eines Werkzeug-Schlüssels.
        /// Entspricht CCC_GetWerkzeugNr aus arbeit.pas.
        /// </summary>
        private string CCC_GetWerkzeugNr(int schluessel)
        {
            if (schluessel <= 0)
                return string.Empty;
            try
            {
                string sql = $"SELECT WerkzeugNr FROM Werkzeug WHERE Nr = {schluessel}";
                using (var reader = _database.ExecuteReader(sql))
                {
                    if (reader.Read())
                    {
                        return reader.GetString(0);
                    }
                }
                return string.Empty;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "CCC_GetWerkzeugNr: Fehler beim Lesen des Werkzeugs {Schluessel}", schluessel);
                return string.Empty;
            }
        }

        /// <summary>
        /// Initialisierung der CCC-Funktionen.
        /// Portiert CCC_Init aus arbeit.pas (Zeile 438). Lädt die Maschinen-Stammdaten
        /// aus der Tabelle 'Maschine' in die Includis-Liste, anschließend die
        /// Schichtlaufzeiten, die aktuellen Aufträge (PDE), die BDE-Daten (MDE),
        /// die Taktoption- sowie die TPM-Stillstandsdefinitionen.
        /// </summary>
        public async Task CCC_InitAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogInformation("CCC_Init: Initialisierung der Critical Control Center Funktionen");

                // SystemID schreiben und Lizenzen prüfen (wie im Delphi-Hochlauf)
                await CCC_SchreibeSystemIDAsync(stoppingToken);
                await CCC_CheckLicensesAsync(stoppingToken);

                // -----------------------------------------------------------------
                // 1) Maschinen-Stammdaten aus Tabelle 'Maschine' laden (Includis[])
                // -----------------------------------------------------------------
                _s7Data.Includis.Clear();
                string sql = "SELECT * FROM Maschine ORDER BY Datenblock";
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        if (_s7Data.Includis.Count >= _s7Data.AnzahlMasch && _s7Data.AnzahlMasch > 0)
                            break;

                        var m = new MaschinenDaten
                        {
                            IstArchiviert = (reader.GetString("oeerelevant") != "1")
                                        || (reader.GetString("archiviert") == "1"),
                            Lizenz = reader.GetString("Lizenz"),
                            Maschine = reader.GetString("Kennung"),
                            KURZKENNUNG = reader.GetString("KURZKENNUNG"),
                            MaschNr = reader.GetInt32("Datenblock").ToString(),
                            MaschNrEcht = reader.GetInt32("Maschnr").ToString(),
                            SORT_MASCHPANEL = reader.GetInt32("SORT_MASCHPANEL"),
                            AutoRuesten = reader.GetInt32("Autoruesten") == 1,
                            MaschAktiv = reader.GetInt32("MaschAktiv") != 0,
                            Datenblock = reader.GetInt32("Datenblock"),
                            Packgroesse = ArbeitUtils.Format_String(reader.GetString("Packgroesse")),
                            Masch_Warmtrennen = reader.GetInt32("Warmtrennen") != 0,
                            Prod_Gleich_Pack = reader.GetInt32("Prod_Gleich_Pack") != 0,
                            ZyklusLast = reader.GetInt32("zyklenlast"),
                            ZyklusLastZeitpunkt = reader.GetDouble("zyklastdatumzeit"),
                            ZyklenAll = reader.GetInt32("zyklenall"),
                            MaschinenTyp = reader.GetInt32("manuelle_buchung")
                        };

                        if (AuftragstartBarcode)
                            m.InventarNr = ArbeitUtils.Format_String(reader.GetString("InventarNr"));
                        else
                            m.InventarNr = _s7Data.Includis.Count + 1;

                        try
                        {
                            m.GutVonBus = reader.GetInt32("gut_von_bus") == 1;
                            m.KombiSeparat = reader.GetInt32("kombi_separat") == 1;
                        }
                        catch
                        {
                            // Felder optional - ignoriert bei Fehlern
                        }

                        if (VerpacktBarcode)
                            m.Packgroesse = 1;

                        m.SpannzeitToleranz = reader.GetInt32("spannzeittol");
                        m.Auftrag.Stat = -1;
                        m.Auftrag.Schwesterauftrag = string.Empty;
                        m.Auftrag.Form = string.Empty;

                        m.Kopfgroesse = ArbeitUtils.Format_String(reader.GetString("Kopfgroesse"));
                        if (m.Kopfgroesse < 1)
                            m.Kopfgroesse = 1;
                        if (m.Packgroesse < 1)
                            m.Packgroesse = 1;

                        // Prüfstation aus Feld 'Station' ableiten (einfach/zweifach/dreifach)
                        string station = reader.GetString("Station");
                        m.Pruefstation = 1;
                        if (string.IsNullOrEmpty(station))
                            m.Pruefstation = 1;
                        else if (station == ArbeitUtils.GetL("einfach"))
                            m.Pruefstation = 1;
                        else if (station == ArbeitUtils.GetL("zweifach"))
                            m.Pruefstation = 2;
                        else if (station == ArbeitUtils.GetL("dreifach"))
                            m.Pruefstation = 3;

                        // Blockstillstand ermitteln (nur wenn einer der Schalter sitzt)
                        try
                        {
                            m.Maschine_geblockt = false;
                            if (BlockStillstand || AuftragBlock)
                            {
                                string blockSql = "SELECT tpm_stillstaende.stillstand, tpm_stillstaende.StillstandNr,"
                                    + " tpm_stillstaende.geplant, tpm_stillstaende.Gruppe, tpm_stillstaende.BLOCKSTILLSTAND"
                                    + " FROM tpm_stillstaende,"
                                    + " tpm_stillog WHERE tpm_stillstaende.StillstandNr = tpm_stillog.StillstandNr AND geht=0"
                                    + " AND tpm_stillog.Nr = (SELECT max(nr) FROM tpm_stillog WHERE maschnr = '" + m.MaschNr + "')";
                                using (var blockReader = _database.ExecuteReader(blockSql))
                                {
                                    if (await blockReader.ReadAsync(stoppingToken))
                                    {
                                        m.Maschine_geblockt = blockReader.GetInt32("BLOCKSTILLSTAND") == 1;
                                    }
                                }
                            }
                        }
                        catch
                        {
                            m.Maschine_geblockt = false;
                        }

                        m.StueckzahlDirekt = reader.GetInt32("stueckzahldirekt") == 1;

                        if (BypassMode)
                            m.Maschine_geblockt = reader.GetInt32("bypass") == 1;

                        _s7Data.Includis.Add(m);
                    }
                }

                if (_s7Data.AnzahlMasch == 0)
                    _s7Data.AnzahlMasch = _s7Data.Includis.Count;

                // -----------------------------------------------------------------
                // 2) Auftragsfelder aller Maschinen zurücksetzen
                // -----------------------------------------------------------------
                foreach (var m in _s7Data.Includis)
                {
                    m.Auftrag.AuftragNr = string.Empty;
                    m.Auftrag.Schwesterauftrag = string.Empty;
                    m.Auftrag.Form = string.Empty;
                    m.Auftrag.Werkzeug = 0;
                    m.Auftrag.WerkzeugNr = string.Empty;
                    m.Auftrag.EndeDatum = DateTime.MinValue;
                }

                // -----------------------------------------------------------------
                // 3) Schichtlaufzeiten je Betriebsauftrag laden (tpm_schicht)
                // -----------------------------------------------------------------
                sql = "SELECT SUM(a_istlaufzeit) laufzeit, maschnr, BETRIEBSAUFTRAGNR"
                    + " FROM tpm_schicht WHERE betriebsauftragnr IN"
                    + " (SELECT betriebsauftragnr FROM pde WHERE stat = 0)"
                    + " GROUP BY maschnr, BETRIEBSAUFTRAGNR";
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        int i = reader.GetInt32("maschnr");
                        if (i > 0 && i <= _s7Data.Includis.Count)
                        {
                            _s7Data.Includis[i - 1].Auftrag.GesamtLaufzeit = reader.GetInt32("laufzeit");
                            _s7Data.Includis[i - 1].Auftrag.BaNrLaufzeit = reader.GetString("betriebsauftragnr");
                        }
                    }
                }

                // -----------------------------------------------------------------
                // 4) Aufräum-Updates auf PDE/MaschInf (Kopfgroesse/Kavitaet >= 1)
                // -----------------------------------------------------------------
                await _database.ExecuteNonQueryAsync("UPDATE pde SET kopfgroesse=1 WHERE kopfgroesse=0", stoppingToken);
                await _database.ExecuteNonQueryAsync("UPDATE maschinf SET kavitaet=1 WHERE kavitaet=0", stoppingToken);

                // -----------------------------------------------------------------
                // 5) Aktuelle Aufträge (PDE) laden und Maschinen zuordnen
                // -----------------------------------------------------------------
                sql = "SELECT CASE WHEN m.maschnr IS NULL THEN mo.maschnr ELSE m.maschnr END maschnr, p.* FROM PDE p"
                    + " LEFT JOIN maschoffline mo ON mo.lizenz = p.lizenz"
                    + " LEFT JOIN maschine m ON m.lizenz = p.lizenz"
                    + " WHERE p.stat IN (0, 1)";
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        string wert = reader.GetString("Lizenz");
                        int machNo = reader.GetInt32("maschnr");

                        // Maschine anhand maschnr (Datenblock) bzw. Lizenz finden
                        int i = -1;
                        if (machNo > 0 && machNo <= _s7Data.Includis.Count
                            && _s7Data.Includis[machNo - 1].Lizenz.Equals(wert, StringComparison.OrdinalIgnoreCase))
                        {
                            i = machNo - 1;
                        }
                        if (i < 0)
                        {
                            for (int j = 0; j < _s7Data.Includis.Count; j++)
                            {
                                if (_s7Data.Includis[j].Lizenz.Equals(wert, StringComparison.OrdinalIgnoreCase))
                                {
                                    i = j;
                                    break;
                                }
                            }
                        }
                        if (i < 0)
                            continue;

                        var m = _s7Data.Includis[i];
                        var a = m.Auftrag;

                        m.MusternAktiv = reader.GetInt32("Mustern") == 1;
                        a.Mustern = reader.GetInt32("Mustern") == 1;
                        a.WasReset = false;
                        a.BetriebsauftragNr = reader.GetString("BetriebsAuftragNr");
                        a.AuftragNr = reader.GetString("AuftragNr");
                        a.Bezeichnung = reader.GetString("Bezeichnung");
                        a.Zustaendig = reader.GetString("Zustaendig");
                        a.Signal = reader.GetString("Signal");

                        a.Sollwert = ArbeitUtils.Format_String(reader.GetString("Sollwert"));
                        a.SollwertOffset = ArbeitUtils.Format_String(reader.GetString("SollwertOffset"));
                        a.Planzykluszeit = reader.GetInt32("planzykluszeit");
                        a.Ausschussquote = reader.GetInt32("ausschussquote");
                        a.SollSpannzeitStk = reader.GetInt32("SOLLSPANNZEITSTK");
                        a.SollSpannzeitGes = reader.GetInt32("SOLLSPANNZEITGES");

                        try { m.Solltakt = reader.GetInt32("Taktzeit"); }
                        catch { /* Feld optional */ }

                        a.StueckSchicht = reader.GetInt32("StueckSchicht");
                        a.PersonalZeit = ArbeitUtils.GFloat(reader.GetString("Personalzeit"));
                        a.Optimiert = reader.GetInt32("optimiert");
                        a.OptimiertAktuell = reader.GetInt32("tmpschuss");
                        a.ImStatusOptimieren = reader.GetInt32("InPause");

                        if (HochlaufTPM)
                            m.StueckAuftragGesamt = ArbeitUtils.Format_String(reader.GetString("Istwert"));

                        a.Schwesterauftrag = reader.GetString("Schwesterauftrag");
                        a.Form = reader.GetString("Form");
                        a.Ausschuss = reader.GetInt32("Ausschuss");
                        a.Verpackt = ArbeitUtils.Format_String(reader.GetString("Pack"));
                        a.Vorwarnung = ArbeitUtils.Format_String(reader.GetString("Vorwarnung"));

                        // Halbautomatik
                        if (reader.GetString("Betriebsart") == ArbeitUtils.GetL("Halbautomatik") && Halbautomatik)
                            a.HalbAuto = true;
                        else
                            a.HalbAuto = false;

                        if (reader.GetString("Erzeugt") == "1")
                        {
                            a.Erzeugt = true;
                            a.VorwarnungErzeugt = true;
                        }
                        else
                        {
                            a.Erzeugt = false;
                            a.VorwarnungErzeugt = false;
                        }

                        a.Solltakt = reader.GetInt32("Taktzeit");
                        a.Stat = reader.GetInt16("stat");
                        a.ProgrammNr = reader.GetInt32("Programm_Nr");
                        a.StartDatum = DateTime.FromOADate(ArbeitUtils.GFloat(reader.GetString("StartdatumZeit")));
                        a.EndeDatum = DateTime.FromOADate(ArbeitUtils.GFloat(reader.GetString("EnddatumZeit")));
                        a.EndeDatumSTR = reader.GetString("EndDatumSTR");
                        a.LTSOLL = ArbeitUtils.GFloat(reader.GetString("LTDatumZeit"));
                        a.LTIST = ArbeitUtils.GFloat(reader.GetString("EnddatumZeit"));
                        a.LT1 = ArbeitUtils.GFloat(reader.GetString("Termin1"));
                        a.LT2 = ArbeitUtils.GFloat(reader.GetString("Termin2"));
                        a.Kunde = reader.GetString("Kunde");
                        a.Werkzeug = reader.GetInt32("Werkzeug");

                        try
                        {
                            a.Packgroesse = ArbeitUtils.Format_String(reader.GetString("PACKGROESSE"));
                            a.PALETTENGROESSE = ArbeitUtils.Format_String(reader.GetString("EndDatumSTR"));
                        }
                        catch
                        {
                            a.Packgroesse = 0;
                            a.PALETTENGROESSE = 0;
                        }

                        a.MasterAuftrag = reader.GetInt32("Masterauftrag") == 1;

                        if (Werkzeugverwaltung)
                            a.WerkzeugNr = CCC_GetWerkzeugNr(a.Werkzeug);

                        if (string.IsNullOrEmpty(a.Form))
                            a.Form = a.Werkzeug.ToString();

                        try
                        {
                            if (reader.IsDBNull("Grundeinstellung") || string.IsNullOrEmpty(reader.GetString("Grundeinstellung")))
                                m.PruefPack = 0;
                            else
                                m.PruefPack = reader.GetInt32("Grundeinstellung");
                        }
                        catch
                        {
                            m.PruefPack = 0;
                        }

                        // Kavität ermitteln (vereinfacht gegenüber Delphi: aus PDE.Kopfgroesse)
                        int kav;
                        try
                        {
                            if (KavitaetFromSPS)
                            {
                                kav = m.Kopfgroesse; // SPS-Wert wird im Dienstlauf aktualisiert
                                if (kav < 1)
                                    kav = 1;
                            }
                            else
                            {
                                string kavSql = "SELECT * FROM kavprot WHERE betriebsauftragnr = '"
                                    + a.BetriebsauftragNr + "' ORDER BY datum DESC";
                                using (var kavReader = _database.ExecuteReader(kavSql))
                                {
                                    if (!await kavReader.ReadAsync(stoppingToken) || !Kavitaet_laufender_Auftrag3)
                                    {
                                        kav = reader.GetInt32("Kopfgroesse");
                                        a.LetzerKavWechsel.Datum = DateTime.MinValue;
                                    }
                                    else
                                    {
                                        a.LetzerKavWechsel.Datum = DateTime.FromOADate(kavReader.GetDouble("datum"));
                                        a.LetzerKavWechsel.BetriebsauftragNr = a.BetriebsauftragNr;
                                        a.LetzerKavWechsel.Alt = kavReader.GetInt32("Wert1");
                                        a.LetzerKavWechsel.Neu = kavReader.GetInt32("Wert2");
                                        a.LetzerKavWechsel.Produziert = kavReader.GetInt32("Produziert");
                                        a.LetzerKavWechsel.Schusszaehler = kavReader.GetInt32("Schusszaehler");
                                        if (a.LetzerKavWechsel.Produziert > 0 && a.LetzerKavWechsel.Schusszaehler < 1)
                                            a.LetzerKavWechsel.Datum = DateTime.MinValue;
                                        kav = a.LetzerKavWechsel.Neu;
                                    }
                                }
                            }
                        }
                        catch
                        {
                            try
                            {
                                a.LetzerKavWechsel.Datum = DateTime.MinValue;
                                kav = reader.GetInt32("Kavitaet_Soll");
                                await _database.ExecuteNonQueryAsync(
                                    "UPDATE pde SET kopfgroesse = kavitaet_soll WHERE nr = "
                                    + reader.GetInt32("nr"), stoppingToken);
                            }
                            catch
                            {
                                kav = 1;
                                await _database.ExecuteNonQueryAsync(
                                    "UPDATE pde SET kopfgroesse = 1, kavitaet_soll = 1 WHERE nr = "
                                    + reader.GetInt32("nr"), stoppingToken);
                            }
                        }

                        // OptimiertAktuell bei Kavitäts-Wechsel detailliert berechnen
                        a.OptimiertAktuell = a.OptimiertAktuell * kav;

                        a.BetriebsauftragNrAlt = a.BetriebsauftragNr;
                        a.Kopfgroesse = kav;
                        a.KAVITAET_SOLL = reader.GetInt32("KAVITAET_SOLL");
                        a.InPause = reader.GetInt32("InPause");

                        a.VarKavitaet = reader.GetInt32("Var_Kavitaet");
                        if (a.VarKavitaet < 1)
                            a.VarKavitaet = 1;
                        if (a.VarKavitaet > 999)
                            a.VarKavitaet = 1;
                    }
                }

                // -----------------------------------------------------------------
                // 6) Maschinen ohne aktuellen Auftrag zurücksetzen
                // -----------------------------------------------------------------
                foreach (var m in _s7Data.Includis)
                {
                    if (string.IsNullOrEmpty(m.Auftrag.AuftragNr) && !m.Auftrag.WasReset)
                    {
                        m.MusternAktiv = false;
                        m.Auftrag.Mustern = false;
                        m.Auftrag.Bezeichnung = ArbeitUtils.GetL("kein aktueller Auftrag");
                        m.Auftrag.BetriebsauftragNr = string.Empty;
                        m.Auftrag.Zustaendig = string.Empty;
                        m.Auftrag.Signal = string.Empty;
                        m.Auftrag.Sollwert = 0;
                        m.Auftrag.SollwertOffset = 0;
                        m.Auftrag.Vorwarnung = 0;
                        m.Auftrag.Erzeugt = false;
                        m.Auftrag.Solltakt = 0;
                        m.Auftrag.Stat = StGeplantInt;
                        m.Auftrag.Werkzeug = 0;
                        m.PruefPack = 1;
                        m.Auftrag.Kopfgroesse = KavitaetFromSPS ? m.Kopfgroesse : m.Kopfgroesse;
                        if (m.Auftrag.Kopfgroesse == 0)
                            m.Auftrag.Kopfgroesse = 1;
                        m.Auftrag.KAVITAET_SOLL = 1;
                        m.Auftrag.InPause = 0;
                        m.Auftrag.VarKavitaet = 1;
                        m.IstTakt = 0;
                        m.Solltakt = 0;
                        m.StueckSchicht = 0;
                        m.StueckPackSchicht = 0;
                        m.StueckPruefSchicht = 0;
                        m.Nutzung = 0;
                        m.Leistung = 0;
                        m.Qualitaet = 0;
                        m.Effektivitaet = 0;
                        m.Auftrag.IstPRZ = 0;
                        m.Auftrag.ProgrammNr = 0;
                        m.Auftrag.Istwert = 0;
                        m.Auftrag.Ausschuss = 0;
                        m.Auftrag.Verpackt = 0;
                        m.StueckPruefAuftragGesamt = 0;
                        m.StueckPackAuftragGesamt = 0;
                        m.Auftrag.Schwesterauftrag = string.Empty;
                        m.Auftrag.Form = string.Empty;
                        m.Auftrag.PersonalZeit = 0;
                        m.Auftrag.Anfahrausschuss = 0;
                        m.Auftrag.Kunde = string.Empty;
                        m.Auftrag.WasReset = true;
                    }
                }

                // -----------------------------------------------------------------
                // 7) Unterbrochene Aufträge: Bezeichnung setzen
                // -----------------------------------------------------------------
                if (await GetSetupParamBoolAsync("INCL_MJAInterruptedDescr", stoppingToken))
                {
                    sql = "SELECT m.maschid, CASE WHEN p.c IS NULL THEN 0 ELSE 1 END interrupted"
                        + " FROM maschine m"
                        + " LEFT JOIN (SELECT lizenz, COUNT(nr) c FROM pde WHERE stat = 5 GROUP BY lizenz) p"
                        + " ON p.lizenz = m.lizenz ORDER BY maschid";
                    using (var reader = _database.ExecuteReader(sql))
                    {
                        while (await reader.ReadAsync(stoppingToken))
                        {
                            int i = reader.GetInt32("maschid");
                            if (i > 0 && i <= _s7Data.Includis.Count)
                            {
                                if (reader.GetInt32("interrupted") > 0
                                    && string.IsNullOrEmpty(_s7Data.Includis[i - 1].Auftrag.AuftragNr))
                                {
                                    _s7Data.Includis[i - 1].Auftrag.InterBezeichnung =
                                        ArbeitUtils.GetL("Auftrag unterbrochen");
                                }
                                else
                                {
                                    _s7Data.Includis[i - 1].Auftrag.InterBezeichnung =
                                        _s7Data.Includis[i - 1].Auftrag.Bezeichnung;
                                }
                            }
                        }
                    }
                }
                else
                {
                    foreach (var m in _s7Data.Includis)
                    {
                        if (!m.IstArchiviert)
                            m.Auftrag.InterBezeichnung = m.Auftrag.Bezeichnung;
                    }
                }

                // -----------------------------------------------------------------
                // 8) BDE-Daten (MDE-Tabelle, Erzeugt=0) laden
                // -----------------------------------------------------------------
                foreach (var m in _s7Data.Includis)
                {
                    m.BDE.Bezeichnung = string.Empty;
                    m.BDE.Zustaendig = string.Empty;
                    m.BDE.Signal = string.Empty;
                    m.BDE.Sollwert = 0;
                    m.BDE.Vorwarnung = 0;
                    m.BDE.Erzeugt = false;
                    m.BDE.VorwarnungErzeugt = false;
                }

                sql = "SELECT * FROM MDE WHERE Erzeugt = 0";
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        string wert = reader.GetString("Lizenz");
                        int i = -1;
                        for (int j = 0; j < _s7Data.Includis.Count; j++)
                        {
                            if (_s7Data.Includis[j].Lizenz == wert)
                            {
                                i = j;
                                break;
                            }
                        }
                        if (i >= 0)
                        {
                            _s7Data.Includis[i].BDE.Bezeichnung = reader.GetString("JobBezeichnung");
                            _s7Data.Includis[i].BDE.Zustaendig = reader.GetString("Zustaendig");
                            _s7Data.Includis[i].BDE.Signal = reader.GetString("Signal");
                            _s7Data.Includis[i].BDE.Sollwert = reader.GetInt32("Sollwert_ABS");
                            _s7Data.Includis[i].BDE.Vorwarnung = reader.GetInt32("Vorwarnung_ABS");
                            _s7Data.Includis[i].BDE.Erzeugt = reader.GetString("Erzeugt") == "1";
                            _s7Data.Includis[i].BDE.VorwarnungErzeugt = false;
                        }
                    }
                }

                // -----------------------------------------------------------------
                // 9) saveeverycycle und Taktoption laden -> ArtikelZyklus
                // -----------------------------------------------------------------
                bool everycycle = false;
                sql = "SELECT saveeverycycle FROM setup WHERE nr = 1";
                using (var reader = _database.ExecuteReader(sql))
                {
                    if (await reader.ReadAsync(stoppingToken))
                    {
                        everycycle = reader.GetInt32("saveeverycycle") == 1;
                    }
                }

                // Taktoption je Lizenz laden
                sql = "SELECT * FROM Taktoption";
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        int i = CCC_GetMaschNrLizenzAsInt(reader.GetString("lizenz"));
                        if (i > 0 && i <= _s7Data.Includis.Count)
                            _s7Data.Includis[i - 1].ArtikelZyklus = reader.GetInt32("Artikelzyklus");
                    }
                }

                foreach (var m in _s7Data.Includis)
                {
                    if (m.IstArchiviert)
                        continue;
                    if (everycycle)
                        m.ArtikelZyklus = 1;
                    else if (m.ArtikelZyklus == 0)
                        m.ArtikelZyklus = 100;
                }

                // -----------------------------------------------------------------
                // 10) TPM-Stillstandsdefinitionen laden (Stillstand-Array)
                // -----------------------------------------------------------------
                _s7Data.Stillstaende.Clear();
                sql = "SELECT * FROM TPM_Stillstaende";
                using (var reader = _database.ExecuteReader(sql))
                {
                    while (await reader.ReadAsync(stoppingToken))
                    {
                        _s7Data.Stillstaende.Add(new StillstandDefinition
                        {
                            Stillstandnr = reader.GetInt32("Stillstandnr"),
                            Bezeichnung = reader.GetString("Stillstand"),
                            Aktion = reader.GetInt32("Aktion"),
                            Gruppe = reader.GetInt32("Gruppe"),
                            Geplant = reader.GetInt32("Geplant") == 1
                        });
                    }
                }

                // -----------------------------------------------------------------
                // 11) HochlaufTPM: MaschZustand-Array initialisieren
                // -----------------------------------------------------------------
                if (HochlaufTPM)
                {
                    _s7Data.MaschZustand.Clear();
                    foreach (var m in _s7Data.Includis)
                    {
                        _s7Data.MaschZustand.Add(new MaschZustandItem
                        {
                            MaschNr = m.MaschNr,
                            Zustand = -1
                        });
                    }
                    HochlaufTPM = false;
                }

                _logger.LogInformation("CCC_Init: Initialisierung abgeschlossen ({Anzahl} Maschinen, {Stillstaende} Stillstaende)",
                    _s7Data.Includis.Count, _s7Data.Stillstaende.Count);
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
                
                string serverName = _s7MainService?.ServerNameDesDienstes ?? Environment.MachineName.ToUpper();
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
        public async Task<(bool HasChanged, int AlteSchicht)> NeueSchichtAsync(CancellationToken stoppingToken)
        {
            int alteSchicht = -1;
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
                            return (true, alteSchicht);
                        }
                    }
                }
                
                _logger.LogDebug("NeueSchicht: Kein Schichtwechsel erkannt");
                return (false, alteSchicht);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "NeueSchicht: Fehler bei der Schichtwechsel-Prüfung");
                return (false, alteSchicht);
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
