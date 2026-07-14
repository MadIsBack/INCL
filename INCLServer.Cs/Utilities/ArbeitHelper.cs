using INCLUDIS.Utils.CommonDB;
using INCLUDIS.INCLServer.Cs.Models;
using System;
using System.Collections.Generic;
using System.Globalization;

namespace INCLUDIS.INCLServer.Cs.Utilities
{
    /// <summary>
    /// Hilfsfunktionen aus Arbeit.pas portiert.
    /// </summary>
    public static class ArbeitHelper
    {
        // Globale Variablen aus Arbeit.pas
        public static bool VorSchichtwechsel { get; set; } = false;
        public static bool NachSchichtwechsel { get; set; } = false;
        public static bool VorWerksplanung { get; set; } = false;
        public static int SchichtSpeicher { get; set; } = 0;
        public static bool VerpacktAusAusschussAktiv { get; set; } = false;
        public static int DebugStage { get; set; } = 0;

        // Arrays für Maschinen, Signale, Stillstände
        public static List<Includis> IncludisList { get; set; } = new();
        public static List<MaschZustand> MaschZustandList { get; set; } = new();
        public static List<Stillstand> StillstandList { get; set; } = new();
        public static List<Signal> SignalList { get; set; } = new();
        public static List<MSignal> MSignalList { get; set; } = new();
        public static List<Maschine> MaschineList { get; set; } = new();
        public static ShiftTypeRec[] SchichtTypArray { get; set; } = new ShiftTypeRec[601]; // Max_ANZAHL = 600

        /// <summary>
        /// Initialisiert die Includis-Daten (portiert von CCC_Init).
        /// </summary>
        public static void Init(CommonDB db)
        {
            IncludisList.Clear();
            MaschineList.Clear();

            // Maschinen aus der Datenbank laden
            var sql = "SELECT * FROM Maschine ORDER BY Datenblock";
            using var reader = db.GetReader(sql);

            while (reader.Read())
            {
                var maschine = new Maschine
                {
                    MaschNr = reader.GetInt32("Maschnr"),
                    Lizenz = reader.GetString("Lizenz")
                };
                MaschineList.Add(maschine);

                var includis = new Includis
                {
                    Lizenz = reader.GetString("Lizenz"),
                    Maschine = reader.GetString("Kennung"),
                    KURZKENNUNG = reader.GetString("KURZKENNUNG"),
                    MaschNr = reader.GetString("Datenblock"),
                    MaschNrEcht = reader.GetString("Maschnr"),
                    SORT_MASCHPANEL = reader.GetInt32("SORT_MASCHPANEL"),
                    MaschAktiv = reader.GetInt32("MaschAktiv") != 0,
                    Datenblock = reader.GetInt16("Datenblock"),
                    AutoRuesten = reader.GetInt32("Autoruesten") == 1,
                    MaschWarmtrennen = reader.GetInt32("Warmtrennen") != 0,
                    ProdGleichPack = reader.GetInt32("Prod_Gleich_Pack") != 0,
                    Kopfgroesse = FormatString(reader.GetString("Packgroesse")),
                    Packgroesse = FormatString(reader.GetString("Packgroesse")),
                    MaschinenTyp = reader.GetInt32("manuelle_buchung"),
                    StueckzahlDirekt = reader.GetInt32("stueckzahldirekt") == 1,
                    SpannzeitToleranz = reader.GetInt32("spannzeittol")
                };

                // Standardwerte setzen
                if (includis.Kopfgroesse < 1) includis.Kopfgroesse = 1;
                if (includis.Packgroesse < 1) includis.Packgroesse = 1;

                // Pruefstation bestimmen
                var station = reader.GetString("Station");
                includis.Pruefstation = station switch
                {
                    "" or "einfach" => 1,
                    "zweifach" => 2,
                    "dreifach" => 3,
                    _ => 1
                };

                IncludisList.Add(includis);
            }

            // Laufzeitdaten für Aufträge laden
            sql = @"
                SELECT SUM(a_istlaufzeit) as laufzeit, maschnr, BETRIEBSAUFTRAGNR 
                FROM tpm_schicht 
                WHERE betriebsauftragnr IN (SELECT betriebsauftragnr FROM pde WHERE stat = 0) 
                GROUP BY maschnr, BETRIEBSAUFTRAGNR";

            using var reader2 = db.GetReader(sql);
            while (reader2.Read())
            {
                var maschNr = reader2.GetInt32("maschnr");
                if (maschNr > 0 && maschNr < IncludisList.Count)
                {
                    IncludisList[maschNr].Auftrag.GesamtLaufzeit = reader2.GetInt32("laufzeit");
                    IncludisList[maschNr].Auftrag.BaNrLaufzeit = reader2.GetString("betriebsauftragnr");
                }
            }

            // Standardwerte für Aufträge setzen
            foreach (var includis in IncludisList)
            {
                includis.Auftrag.AuftragNr = string.Empty;
                includis.Auftrag.Schwesterauftrag = string.Empty;
                includis.Auftrag.Form = string.Empty;
                includis.Auftrag.Werkzeug = 0;
                includis.Auftrag.WerkzeugNr = string.Empty;
                includis.Auftrag.EndeDatum = DateTime.MinValue;
                includis.Auftrag.Stat = -1;
            }
        }

        /// <summary>
        /// Lädt Aufträge aus der Datenbank (portiert von CCC_Daten_Aktualisieren).
        /// </summary>
        public static void LoadAufträge(CommonDB db)
        {
            var sql = @"
                SELECT * FROM PDE 
                WHERE stat IN (0, 1)";

            using var reader = db.GetReader(sql);
            while (reader.Read())
            {
                var lizenz = reader.GetString("Lizenz");
                var maschNr = reader.GetInt32("maschnr");

                // Maschine in IncludisList finden
                var includis = IncludisList.Find(i => i.Lizenz.Equals(lizenz, StringComparison.OrdinalIgnoreCase));
                if (includis == null) continue;

                // Auftragsdaten laden
                includis.Auftrag.AuftragNr = reader.GetString("betriebsauftragnr");
                includis.Auftrag.Bezeichnung = reader.GetString("bezeichnung");
                includis.Auftrag.Zustaendig = reader.GetString("zustaendig");
                includis.Auftrag.Signal = reader.GetString("signal");
                includis.Auftrag.Sollwert = reader.GetInt32("sollwert");
                includis.Auftrag.SollwertOffset = reader.GetInt32("sollwert_offset");
                includis.Auftrag.Istwert = reader.GetInt32("istwert");
                includis.Auftrag.IstPRZ = reader.GetInt32("ist_prz");
                includis.Auftrag.Ausschuss = reader.GetInt32("ausschuss");
                includis.Auftrag.Verpackt = reader.GetInt32("verpackt");
                includis.Auftrag.Anfahrausschuss = reader.GetInt32("anfahrausschuss");
                includis.Auftrag.Vorwarnung = reader.GetInt32("vorwarnung");
                includis.Auftrag.Erzeugt = reader.GetBoolean("erzeugt");
                includis.Auftrag.VorwarnungErzeugt = reader.GetBoolean("vorwarnung_erzeugt");
                includis.Auftrag.Stat = reader.GetInt16("stat");
                includis.Auftrag.Solltakt = reader.GetInt32("solltakt");
                includis.Auftrag.StartDatum = reader.GetDateTime("startdatum");
                includis.Auftrag.EndeDatum = reader.GetDateTime("endedatum");
                includis.Auftrag.Werkzeug = reader.GetInt32("werkzeug");
                includis.Auftrag.WerkzeugNr = reader.GetString("werkzeugnr");
                includis.Auftrag.HalbAuto = reader.GetBoolean("halbauto");
                includis.Auftrag.Kopfgroesse = reader.GetInt32("kopfgroesse");
                includis.Auftrag.KAVITAET_SOLL = reader.GetInt32("kavitaet_soll");
                includis.Auftrag.Packgroesse = reader.GetInt32("packgroesse");
                includis.Auftrag.PALETTENGROESSE = reader.GetInt32("palettengroesse");
                includis.Auftrag.Kunde = reader.GetString("kunde");
                includis.Auftrag.Form = reader.GetString("form");
                includis.Auftrag.ProgrammNr = reader.GetInt32("programm_nr");
                includis.Auftrag.MasterAuftrag = reader.GetBoolean("masterauftrag");
            }
        }

        /// <summary>
        /// Formatiert eine String-Zahl (portiert von Format_String).
        /// </summary>
        public static int FormatString(string value)
        {
            if (string.IsNullOrEmpty(value))
                return 0;

            if (int.TryParse(value, NumberStyles.Any, CultureInfo.InvariantCulture, out int result))
                return result;

            return 0;
        }

        /// <summary>
        /// Konvertiert einen Delphi-TDateTime (Float) in ein C#-DateTime.
        /// </summary>
        public static DateTime DelphiDateTimeToDateTime(double delphiDateTime)
        {
            // Delphi TDateTime: 1 = 1 Tag, 0.5 = 12 Stunden
            return DateTime.FromOADate(delphiDateTime);
        }

        /// <summary>
        /// Konvertiert ein C#-DateTime in einen Delphi-TDateTime (Float).
        /// </summary>
        public static double DateTimeToDelphiDateTime(DateTime dateTime)
        {
            return dateTime.ToOADate();
        }

        /// <summary>
        /// Gibt den aktuellen Zeitstempel zurück (portiert von N_o_w).
        /// </summary>
        public static DateTime Now => DateTime.Now;

        /// <summary>
        /// Lädt Signale aus der Datenbank.
        /// </summary>
        public static void LoadSignals(CommonDB db)
        {
            SignalList.Clear();
            MSignalList.Clear();

            var sql = @"
                SELECT s.signalnr, s.signalart 
                FROM signale s 
                WHERE s.logit = 1 OR s.signalart = 24";

            using var reader = db.GetReader(sql);
            while (reader.Read())
            {
                SignalList.Add(new Signal
                {
                    SignalNr = reader.GetInt32("signalnr"),
                    SignalArt = reader.GetInt32("signalart")
                });
            }

            sql = @"
                SELECT sm.nr, sm.maschnr, sm.signalnr 
                FROM signal_maschine sm";

            using var reader2 = db.GetReader(sql);
            while (reader2.Read())
            {
                MSignalList.Add(new MSignal
                {
                    Nr = reader2.GetInt32("nr"),
                    MaschNr = reader2.GetInt32("maschnr"),
                    SignalNr = reader2.GetInt32("signalnr")
                });
            }
        }

        /// <summary>
        /// Lädt Stillstände aus der Datenbank.
        /// </summary>
        public static void LoadStillstände(CommonDB db)
        {
            StillstandList.Clear();

            var sql = @"
                SELECT stillstandnr, bezeichnung, aktion, gruppe, geplant 
                FROM tpm_stillstaende";

            using var reader = db.GetReader(sql);
            while (reader.Read())
            {
                StillstandList.Add(new Stillstand
                {
                    Stillstandnr = reader.GetInt32("stillstandnr"),
                    Bezeichnung = reader.GetString("bezeichnung"),
                    Aktion = reader.GetInt32("aktion"),
                    Gruppe = reader.GetInt32("gruppe"),
                    Geplant = reader.GetBoolean("geplant")
                });
            }
        }

        /// <summary>
        /// Lädt Maschinen-Zustände aus der Datenbank.
        /// </summary>
        public static void LoadMaschZustand(CommonDB db)
        {
            MaschZustandList.Clear();

            var sql = @"
                SELECT maschnr, zustand 
                FROM maschinen_zustand";

            using var reader = db.GetReader(sql);
            while (reader.Read())
            {
                MaschZustandList.Add(new MaschZustand
                {
                    MaschNr = reader.GetString("maschnr"),
                    Zustand = reader.GetInt32("zustand")
                });
            }
        }

        /// <summary>
        /// Berechnet die Leistung für eine Maschine.
        /// </summary>
        public static decimal BerechneLeistung(CommonDB db, int maschNr, DateTime vonDatum, DateTime bisDatum)
        {
            var sql = @"
                SELECT SUM(Stueck) as GesamtStueck 
                FROM Maschinenleistung 
                WHERE MaschNr = @MaschNr 
                AND Datum BETWEEN @VonDatum AND @BisDatum";

            using var reader = db.GetReader(sql, new { MaschNr = maschNr, VonDatum = vonDatum, BisDatum = bisDatum });
            return reader.Read() && !reader.IsDBNull(0) ? reader.GetDecimal(0) : 0;
        }

        /// <summary>
        /// Berechnet die Auslastung für eine Maschine.
        /// </summary>
        public static decimal BerechneAuslastung(CommonDB db, int maschNr, DateTime datum)
        {
            var sql = @"
                SELECT (SUM(Laufzeit) * 100.0 / (24 * 60)) as Auslastung 
                FROM Maschinenprotokoll 
                WHERE MaschNr = @MaschNr AND Datum = @Datum";

            using var reader = db.GetReader(sql, new { MaschNr = maschNr, Datum = datum });
            return reader.Read() && !reader.IsDBNull(0) ? reader.GetDecimal(0) : 0;
        }

        /// <summary>
        /// Berechnet die Qualität für eine Maschine.
        /// </summary>
        public static decimal BerechneQualitaet(CommonDB db, int maschNr, DateTime datum)
        {
            var sql = @"
                SELECT (SUM(Stueck) - SUM(Ausschuss)) * 100.0 / SUM(Stueck) as Qualitaet 
                FROM Maschinenleistung 
                WHERE MaschNr = @MaschNr AND Datum = @Datum";

            using var reader = db.GetReader(sql, new { MaschNr = maschNr, Datum = datum });
            return reader.Read() && !reader.IsDBNull(0) ? reader.GetDecimal(0) : 0;
        }
    }
}
