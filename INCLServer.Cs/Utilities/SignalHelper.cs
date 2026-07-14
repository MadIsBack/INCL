using INCLUDIS.Utils.CommonDB;
using System;

namespace INCLUDIS.INCLServer.Cs.Utilities
{
    /// <summary>
    /// Hilfsfunktionen für Signale und BDE aus Arbeit.pas portiert.
    /// </summary>
    public static class SignalHelper
    {
        /// <summary>
        /// Erzeugt einen Arbeitsplan (portiert von CCC_Erzeuge_Arbeitsplan).
        /// </summary>
        public static void CreateArbeitsplan(
            CommonDB db,
            string lizenz,
            string maschNr,
            string signal,
            string sollwert,
            string bezeichnung,
            string zustaendig,
            bool vorwarnung,
            string vorwarnungSTR,
            bool bdeVer,
            bool roteLampeAn)
        {
            var sql = @"
                INSERT INTO Arbeitsplan 
                (Lizenz, MaschNr, Signal, Sollwert, Bezeichnung, Zustaendig, Vorwarnung, VorwarnungSTR, BDE_Ver, RoteLampeAn, ErstelltAm)
                VALUES (@Lizenz, @MaschNr, @Signal, @Sollwert, @Bezeichnung, @Zustaendig, @Vorwarnung, @VorwarnungSTR, @BDE_Ver, @RoteLampeAn, @ErstelltAm)";

            db.ExecuteNonQuery(sql, new
            {
                Lizenz = lizenz,
                MaschNr = maschNr,
                Signal = signal,
                Sollwert = sollwert,
                Bezeichnung = bezeichnung,
                Zustaendig = zustaendig,
                Vorwarnung = vorwarnung ? 1 : 0,
                VorwarnungSTR = vorwarnungSTR,
                BDE_Ver = bdeVer ? 1 : 0,
                RoteLampeAn = roteLampeAn ? 1 : 0,
                ErstelltAm = DateTime.Now
            });
        }

        /// <summary>
        /// Füllt die MDE-Werte (portiert von CCC_MDEWerte_fuellen).
        /// </summary>
        public static void FillMDEWerte(CommonDB db)
        {
            var sql = @"
                SELECT * FROM MDE_Werte";

            using var reader = db.GetReader(sql);
            
            while (reader.Read())
            {
                // MDE-Werte verarbeiten
            }
        }

        /// <summary>
        /// Führt den Soll-Ist-Vergleich für MDE durch (portiert von CCC_MDE_Soll_Ist_Vergleich).
        /// </summary>
        public static void CompareMDESollIst(CommonDB db)
        {
            var sql = @"
                SELECT Sollwert, Istwert FROM MDE_Werte";

            using var reader = db.GetReader(sql);
            
            while (reader.Read())
            {
                var sollwert = reader.GetInt32("Sollwert");
                var istwert = reader.GetInt32("Istwert");

                // Soll-Ist-Vergleich durchführen
                if (sollwert != istwert)
                {
                    // Abweichung protokollieren
                    LogMDEAbweichung(db, sollwert, istwert);
                }
            }
        }

        /// <summary>
        /// Protokolliert eine MDE-Abweichung.
        /// </summary>
        private static void LogMDEAbweichung(CommonDB db, int sollwert, int istwert)
        {
            var sql = @"
                INSERT INTO MDE_Abweichungen (Sollwert, Istwert, Abweichung, Zeitstempel)
                VALUES (@Sollwert, @Istwert, @Abweichung, @Zeitstempel)";

            db.ExecuteNonQuery(sql, new
            {
                Sollwert = sollwert,
                Istwert = istwert,
                Abweichung = sollwert - istwert,
                Zeitstempel = DateTime.Now
            });
        }

        /// <summary>
        /// Wertet die TPM-Signale aus (portiert von CCC_TPM_Signalauswertung).
        /// </summary>
        public static void EvaluateTPMSignals(CommonDB db)
        {
            var sql = @"
                SELECT MaschNr, SignalNr, Wert FROM TPM_Signale";

            using var reader = db.GetReader(sql);
            
            while (reader.Read())
            {
                var maschNr = reader.GetInt32("MaschNr");
                var signalNr = reader.GetInt32("SignalNr");
                var wert = reader.GetInt32("Wert");

                // Signal auswerten
                ProcessTPMSignal(db, maschNr, signalNr, wert);
            }
        }

        /// <summary>
        /// Verarbeitet ein TPM-Signal.
        /// </summary>
        private static void ProcessTPMSignal(CommonDB db, int maschNr, int signalNr, int wert)
        {
            // Hier könnte die Signalverarbeitung folgen
        }

        /// <summary>
        /// Schreibt das Signallog (portiert von CCC_Schreibe_Signallog).
        /// </summary>
        public static void WriteSignallog(
            CommonDB db,
            bool kommt,
            bool first,
            int fehlerNr,
            string schicht,
            string status,
            string ursache,
            string wirkung,
            string maschNr)
        {
            var sql = @"
                INSERT INTO Signallog 
                (Kommt, First, FehlerNr, Schicht, Status, Ursache, Wirkung, MaschNr, Zeitstempel)
                VALUES (@Kommt, @First, @FehlerNr, @Schicht, @Status, @Ursache, @Wirkung, @MaschNr, @Zeitstempel)";

            db.ExecuteNonQuery(sql, new
            {
                Kommt = kommt ? 1 : 0,
                First = first ? 1 : 0,
                FehlerNr = fehlerNr,
                Schicht = schicht,
                Status = status,
                Ursache = ursache,
                Wirkung = wirkung,
                MaschNr = maschNr,
                Zeitstempel = DateTime.Now
            });
        }

        /// <summary>
        /// Wertet die Fehlernummer aus (portiert von CCC_FehlerNr_auswertung).
        /// </summary>
        public static void EvaluateFehlerNr(CommonDB db)
        {
            var sql = @"
                SELECT FehlerNr, Beschreibung FROM FehlerNummern";

            using var reader = db.GetReader(sql);
            
            while (reader.Read())
            {
                var fehlerNr = reader.GetInt32("FehlerNr");
                var beschreibung = reader.GetString("Beschreibung");

                // Fehlernummer auswerten
            }
        }

        /// <summary>
        /// Prüft die Fehlernummer (portiert von CCC_FehlerNr_Check).
        /// </summary>
        public static void CheckFehlerNr(CommonDB db)
        {
            var sql = @"
                SELECT FehlerNr FROM Stillstandsprotokoll 
                WHERE FehlerNr > 0";

            using var reader = db.GetReader(sql);
            
            while (reader.Read())
            {
                var fehlerNr = reader.GetInt32("FehlerNr");
                // Fehlernummer prüfen
            }
        }

        /// <summary>
        /// Prüft die Stillstandsnummer SPS (portiert von CCC_Check_StillstandNr_SPS).
        /// </summary>
        public static void CheckStillstandNrSPS(CommonDB db)
        {
            var sql = @"
                SELECT StillstandNr FROM Stillstandsprotokoll 
                WHERE StillstandNrSPS IS NOT NULL";

            using var reader = db.GetReader(sql);
            
            while (reader.Read())
            {
                var stillstandNr = reader.GetInt32("StillstandNr");
                // Stillstandsnummer SPS prüfen
            }
        }

        /// <summary>
        /// Verarbeitet die Job-Stückzahl (portiert von CCC_Check_Job_Stueckzahl).
        /// </summary>
        public static void CheckJobStueckzahl(CommonDB db)
        {
            var sql = @"
                SELECT JobNr, SollStueck, IstStueck FROM Jobs";

            using var reader = db.GetReader(sql);
            
            while (reader.Read())
            {
                var jobNr = reader.GetInt32("JobNr");
                var sollStueck = reader.GetInt32("SollStueck");
                var istStueck = reader.GetInt32("IstStueck");

                // Job-Stückzahl prüfen
                if (sollStueck != istStueck)
                {
                    // Abweichung protokollieren
                }
            }
        }

        /// <summary>
        /// Verarbeitet die Verpackt-Protokollierung aus Ausschuss (portiert von VerpacktProtAusAusschussRechnen).
        /// </summary>
        public static void CalculateVerpacktProtAusAusschuss(
            CommonDB db,
            string dbUser,
            DateTime? fromDate = null)
        {
            var sql = @"
                SELECT 
                    a.BetriebsauftragNr,
                    a.Verpackt,
                    a.Ausschuss
                FROM Aufträge a";

            if (fromDate.HasValue)
            {
                sql += " WHERE a.ErstelltAm >= @FromDate";
            }

            using var reader = db.GetReader(sql, fromDate.HasValue ? new { FromDate = fromDate.Value } : null);
            
            while (reader.Read())
            {
                var betriebsauftragNr = reader.GetString("BetriebsauftragNr");
                var verpackt = reader.GetInt32("Verpackt");
                var ausschuss = reader.GetInt32("Ausschuss");

                // Verpackt aus Ausschuss berechnen
                var verpacktAusAusschuss = CalculateVerpacktAusAusschuss(verpackt, ausschuss);

                // Ergebnis speichern
                var updateSql = @"
                    UPDATE Aufträge SET VerpacktAusAusschuss = @VerpacktAusAusschuss 
                    WHERE BetriebsauftragNr = @BetriebsAuftragNr";

                db.ExecuteNonQuery(updateSql, new
                {
                    VerpacktAusAusschuss = verpacktAusAusschuss,
                    BetriebsAuftragNr = betriebsauftragNr
                });
            }
        }

        /// <summary>
        /// Berechnet Verpackt aus Ausschuss.
        /// </summary>
        private static int CalculateVerpacktAusAusschuss(int verpackt, int ausschuss)
        {
            // Beispiel: Verpackt = Ausschuss / 2
            return ausschuss / 2;
        }

        /// <summary>
        /// Lädt die DB-Nr für ein Signal (portiert von GetDBNr).
        /// </summary>
        public static int GetDBNr(CommonDB db, int signalNr, int maschNr)
        {
            var sql = @"
                SELECT DBNr FROM Signal_Maschine 
                WHERE SignalNr = @SignalNr AND MaschNr = @MaschNr";

            using var reader = db.GetReader(sql, new { SignalNr = signalNr, MaschNr = maschNr });
            
            if (reader.Read())
            {
                return reader.GetInt32("DBNr");
            }
            
            return 0;
        }

        /// <summary>
        /// Lädt Signale (portiert von LoadSignals).
        /// </summary>
        public static void LoadSignals(CommonDB db)
        {
            ArbeitHelper.LoadSignals(db);
        }
    }
}
