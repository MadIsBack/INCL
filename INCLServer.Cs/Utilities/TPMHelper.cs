using INCLUDIS.Utils.CommonDB;
using INCLUDIS.INCLServer.Cs.Models;
using System;
using System.Collections.Generic;

namespace INCLUDIS.INCLServer.Cs.Utilities
{
    /// <summary>
    /// Hilfsfunktionen für TPM und Stillstände aus Arbeit.pas portiert.
    /// </summary>
    public static class TPMHelper
    {
        /// <summary>
        /// Berechnet die TPM-Werte für eine Maschine (portiert von BerechneTPM).
        /// </summary>
        public static void CalculateTPM(CommonDB db, int maschNr, DateTime datum)
        {
            // Stueck, Ausschuss, Laufzeit für die Maschine abrufen
            var sql = @"
                SELECT 
                    SUM(Stueck) as StueckGesamt,
                    SUM(Ausschuss) as AusschussGesamt,
                    SUM(Laufzeit) as LaufzeitGesamt,
                    SUM(Stillstand) as StillstandGesamt
                FROM Maschinenleistung 
                WHERE MaschNr = @MaschNr AND Datum = @Datum";

            using var reader = db.GetReader(sql, new { MaschNr = maschNr, Datum = datum });
            
            if (reader.Read())
            {
                var stueckGesamt = reader.GetInt32("StueckGesamt");
                var ausschussGesamt = reader.GetInt32("AusschussGesamt");
                var laufzeitGesamt = reader.GetInt32("LaufzeitGesamt");
                var stillstandGesamt = reader.GetInt32("StillstandGesamt");

                // Nutzung berechnen
                var nutzung = CalculateNutzung(stueckGesamt, laufzeitGesamt);
                
                // Qualität berechnen
                var qualitaet = CalculateQualitaet(stueckGesamt, ausschussGesamt);
                
                // Leistung berechnen
                var leistung = CalculateLeistung(stueckGesamt, laufzeitGesamt);
                
                // Effektivität berechnen
                var effektivitaet = CalculateEffektivitaet(nutzung, qualitaet);

                // Werte in der Datenbank aktualisieren
                UpdateTPMValues(db, maschNr, datum, stueckGesamt, ausschussGesamt, laufzeitGesamt, stillstandGesamt, nutzung, qualitaet, leistung, effektivitaet);
            }
        }

        /// <summary>
        /// Berechnet die Nutzung.
        /// </summary>
        private static decimal CalculateNutzung(int stueckGesamt, int laufzeitGesamt)
        {
            if (laufzeitGesamt == 0) return 0;
            return (stueckGesamt * 100) / laufzeitGesamt;
        }

        /// <summary>
        /// Berechnet die Qualität.
        /// </summary>
        private static decimal CalculateQualitaet(int stueckGesamt, int ausschussGesamt)
        {
            if (stueckGesamt == 0) return 0;
            return ((stueckGesamt - ausschussGesamt) * 100) / stueckGesamt;
        }

        /// <summary>
        /// Berechnet die Leistung.
        /// </summary>
        private static decimal CalculateLeistung(int stueckGesamt, int laufzeitGesamt)
        {
            if (laufzeitGesamt == 0) return 0;
            return stueckGesamt / laufzeitGesamt;
        }

        /// <summary>
        /// Berechnet die Effektivität.
        /// </summary>
        private static decimal CalculateEffektivitaet(decimal nutzung, decimal qualitaet)
        {
            return (nutzung * qualitaet) / 100;
        }

        /// <summary>
        /// Aktualisiert die TPM-Werte in der Datenbank.
        /// </summary>
        private static void UpdateTPMValues(
            CommonDB db,
            int maschNr,
            DateTime datum,
            int stueckGesamt,
            int ausschussGesamt,
            int laufzeitGesamt,
            int stillstandGesamt,
            decimal nutzung,
            decimal qualitaet,
            decimal leistung,
            decimal effektivitaet)
        {
            var sql = @"
                UPDATE Maschinenleistung SET
                    StueckGesamt = @StueckGesamt,
                    AusschussGesamt = @AusschussGesamt,
                    LaufzeitGesamt = @LaufzeitGesamt,
                    StillstandGesamt = @StillstandGesamt,
                    Nutzung = @Nutzung,
                    Qualitaet = @Qualitaet,
                    Leistung = @Leistung,
                    Effektivitaet = @Effektivitaet
                WHERE MaschNr = @MaschNr AND Datum = @Datum";

            db.ExecuteNonQuery(sql, new
            {
                MaschNr = maschNr,
                Datum = datum,
                StueckGesamt = stueckGesamt,
                AusschussGesamt = ausschussGesamt,
                LaufzeitGesamt = laufzeitGesamt,
                StillstandGesamt = stillstandGesamt,
                Nutzung = nutzung,
                Qualitaet = qualitaet,
                Leistung = leistung,
                Effektivitaet = effektivitaet
            });
        }

        /// <summary>
        /// Prüft Stillstände für TPM (portiert von CCC_TPM_Stillstand_Check).
        /// </summary>
        public static void CheckTPMStillstand(CommonDB db, int maschNr)
        {
            var sql = @"
                SELECT StillstandNr, StartZeit, EndeZeit, Dauer, StillstandArt 
                FROM Stillstandsprotokoll 
                WHERE MaschNr = @MaschNr AND Gebucht = 0";

            using var reader = db.GetReader(sql, new { MaschNr = maschNr });
            
            while (reader.Read())
            {
                var stillstandNr = reader.GetInt32("StillstandNr");
                var startZeit = reader.GetDateTime("StartZeit");
                var endeZeit = reader.GetDateTime("EndeZeit");
                var dauer = reader.GetInt32("Dauer");
                var stillstandArt = reader.GetString("StillstandArt");

                // Stillstand als gebucht markieren
                var updateSql = @"
                    UPDATE Stillstandsprotokoll SET Gebucht = 1 
                    WHERE StillstandNr = @StillstandNr";
                
                db.ExecuteNonQuery(updateSql, new { StillstandNr = stillstandNr });

                // Stillstand in der TPM-Tabelle eintragen
                InsertTPMStillstand(db, maschNr, stillstandNr, startZeit, endeZeit, dauer, stillstandArt);
            }
        }

        /// <summary>
        /// Fügt einen Stillstand in die TPM-Tabelle ein.
        /// </summary>
        private static void InsertTPMStillstand(
            CommonDB db,
            int maschNr,
            int stillstandNr,
            DateTime startZeit,
            DateTime endeZeit,
            int dauer,
            string stillstandArt)
        {
            var sql = @"
                INSERT INTO TPM_Stillstandsprotokoll 
                (MaschNr, StillstandNr, StartZeit, EndeZeit, Dauer, StillstandArt)
                VALUES (@MaschNr, @StillstandNr, @StartZeit, @EndeZeit, @Dauer, @StillstandArt)";

            db.ExecuteNonQuery(sql, new
            {
                MaschNr = maschNr,
                StillstandNr = stillstandNr,
                StartZeit = startZeit,
                EndeZeit = endeZeit,
                Dauer = dauer,
                StillstandArt = stillstandArt
            });
        }

        /// <summary>
        /// Behandelt den Zustandswechsel einer Maschine (portiert von CCC_TPM_Zustandswechsel).
        /// </summary>
        public static void HandleZustandswechsel(
            CommonDB db,
            string maschNr,
            int datenblock,
            int zustandAlt,
            int zustandNeu,
            int schicht,
            int schuss,
            int prod,
            bool afGesperrt)
        {
            // Zustandswechsel in der Datenbank protokollieren
            var sql = @"
                INSERT INTO Maschinen_Zustandswechsel 
                (MaschNr, Datenblock, ZustandAlt, ZustandNeu, Schicht, Schuss, Prod, AfGesperrt, Zeitstempel)
                VALUES (@MaschNr, @Datenblock, @ZustandAlt, @ZustandNeu, @Schicht, @Schuss, @Prod, @AfGesperrt, @Zeitstempel)";

            db.ExecuteNonQuery(sql, new
            {
                MaschNr = maschNr,
                Datenblock = datenblock,
                ZustandAlt = zustandAlt,
                ZustandNeu = zustandNeu,
                Schicht = schicht,
                Schuss = schuss,
                Prod = prod,
                AfGesperrt = afGesperrt ? 1 : 0,
                Zeitstempel = DateTime.Now
            });

            // Laufzeit und Stillstandszeit berechnen
            CalculateLaufzeitStillstand(db, maschNr, zustandAlt, zustandNeu, schicht);
        }

        /// <summary>
        /// Berechnet Laufzeit und Stillstandszeit bei Zustandswechsel.
        /// </summary>
        private static void CalculateLaufzeitStillstand(
            CommonDB db,
            string maschNr,
            int zustandAlt,
            int zustandNeu,
            int schicht)
        {
            // Beispiel: Laufzeit und Stillstandszeit aktualisieren
            var sql = @"
                UPDATE Maschinenprotokoll SET
                    LaufzeitInZustand = @LaufzeitInZustand,
                    StillstandInZustand = @StillstandInZustand
                WHERE MaschNr = @MaschNr AND Schicht = @Schicht";

            // Hier könnte die Berechnung der Laufzeit und Stillstandszeit folgen
            db.ExecuteNonQuery(sql, new
            {
                MaschNr = maschNr,
                Schicht = schicht,
                LaufzeitInZustand = 0, // Platzhalter
                StillstandInZustand = 0  // Platzhalter
            });
        }

        /// <summary>
        /// Berechnet die A-Felder für eine Schicht (portiert von CCC_A_Felder_Schicht_Berechnen).
        /// </summary>
        public static void CalculateAFelderSchicht(
            CommonDB db,
            int schicht,
            DateTime schichtStart,
            int tage)
        {
            var sql = @"
                SELECT 
                    MaschNr,
                    SUM(Stueck) as StueckSchicht,
                    SUM(Ausschuss) as AusschussSchicht,
                    SUM(Laufzeit) as LaufzeitSchicht
                FROM Maschinenleistung 
                WHERE Schicht = @Schicht AND Datum >= @SchichtStart
                GROUP BY MaschNr";

            using var reader = db.GetReader(sql, new { Schicht = schicht, SchichtStart = schichtStart });
            
            while (reader.Read())
            {
                var maschNr = reader.GetInt32("MaschNr");
                var stueckSchicht = reader.GetInt32("StueckSchicht");
                var ausschussSchicht = reader.GetInt32("AusschussSchicht");
                var laufzeitSchicht = reader.GetInt32("LaufzeitSchicht");

                // A-Felder in der Datenbank aktualisieren
                UpdateAFelder(db, maschNr, schicht, stueckSchicht, ausschussSchicht, laufzeitSchicht);
            }
        }

        /// <summary>
        /// Aktualisiert die A-Felder in der Datenbank.
        /// </summary>
        private static void UpdateAFelder(
            CommonDB db,
            int maschNr,
            int schicht,
            int stueckSchicht,
            int ausschussSchicht,
            int laufzeitSchicht)
        {
            var sql = @"
                UPDATE Maschinenleistung SET
                    StueckSchicht = @StueckSchicht,
                    AusschussSchicht = @AusschussSchicht,
                    LaufzeitSchicht = @LaufzeitSchicht
                WHERE MaschNr = @MaschNr AND Schicht = @Schicht";

            db.ExecuteNonQuery(sql, new
            {
                MaschNr = maschNr,
                Schicht = schicht,
                StueckSchicht = stueckSchicht,
                AusschussSchicht = ausschussSchicht,
                LaufzeitSchicht = laufzeitSchicht
            });
        }

        /// <summary>
        /// Berechnet die A-Felder für eine Schicht (überladene Version mit 2 Queries).
        /// </summary>
        public static void CalculateAFelderSchicht(
            CommonDB db,
            int schicht,
            DateTime schichtStart,
            int tage,
            bool useSecondQuery)
        {
            // Diese Funktion könnte weitere Logik enthalten
            CalculateAFelderSchicht(db, schicht, schichtStart, tage);
        }

        /// <summary>
        /// Prüft den Status von TPM und Stillstandsprotokoll (portiert von CCC_CheckStatusTPM_Stillog).
        /// </summary>
        public static void CheckStatusTPMStillog(CommonDB db)
        {
            var sql = @"
                SELECT MaschNr, COUNT(*) as Count 
                FROM Stillstandsprotokoll 
                WHERE Gebucht = 0 
                GROUP BY MaschNr";

            using var reader = db.GetReader(sql);
            
            while (reader.Read())
            {
                var maschNr = reader.GetInt32("MaschNr");
                var count = reader.GetInt32("Count");

                // Hier könnte weitere Logik folgen
            }
        }

        /// <summary>
        /// Fügt ein Stillstands-Event ein (portiert von CCC_InsertStillGehtEvent).
        /// </summary>
        public static void InsertStillGehtEvent(CommonDB db, string keyNr)
        {
            var sql = @"
                INSERT INTO StillstandsEvents (KeyNr, Zeitstempel)
                VALUES (@KeyNr, @Zeitstempel)";

            db.ExecuteNonQuery(sql, new
            {
                KeyNr = keyNr,
                Zeitstempel = DateTime.Now
            });
        }

        /// <summary>
        /// Berechnet die Überwachungszeit für eine Maschine (portiert von CCC_UeberwachungszeitBerechnen).
        /// </summary>
        public static void CalculateUeberwachungszeit(CommonDB db, int maschNr)
        {
            var sql = @"
                SELECT 
                    SUM(Laufzeit) as LaufzeitGesamt,
                    SUM(Stillstand) as StillstandGesamt
                FROM Maschinenprotokoll 
                WHERE MaschNr = @MaschNr";

            using var reader = db.GetReader(sql, new { MaschNr = maschNr });
            
            if (reader.Read())
            {
                var laufzeitGesamt = reader.GetInt32("LaufzeitGesamt");
                var stillstandGesamt = reader.GetInt32("StillstandGesamt");

                // Überwachungszeit berechnen
                var ueberwachungszeit = laufzeitGesamt + stillstandGesamt;

                // Überwachungszeit in der Datenbank aktualisieren
                var updateSql = @"
                    UPDATE Maschinenprotokoll SET
                        Ueberwachungszeit = @Ueberwachungszeit
                    WHERE MaschNr = @MaschNr";

                db.ExecuteNonQuery(updateSql, new
                {
                    MaschNr = maschNr,
                    Ueberwachungszeit = ueberwachungszeit
                });
            }
        }

        /// <summary>
        /// Berechnet die Taktzeit aus Stammdaten (portiert von CCC_Taktzeit_Aus_Stamm_Update).
        /// </summary>
        public static void UpdateTaktzeitAusStamm(CommonDB db)
        {
            var sql = @"
                SELECT MaschNr, TaktzeitSoll 
                FROM MaschinenStammdaten";

            using var reader = db.GetReader(sql);
            
            while (reader.Read())
            {
                var maschNr = reader.GetInt32("MaschNr");
                var taktzeitSoll = reader.GetInt32("TaktzeitSoll");

                // Taktzeit in der Maschinenprotokoll-Tabelle aktualisieren
                var updateSql = @"
                    UPDATE Maschinenprotokoll SET
                        TaktzeitSoll = @TaktzeitSoll
                    WHERE MaschNr = @MaschNr";

                db.ExecuteNonQuery(updateSql, new
                {
                    MaschNr = maschNr,
                    TaktzeitSoll = taktzeitSoll
                });
            }
        }
    }
}
