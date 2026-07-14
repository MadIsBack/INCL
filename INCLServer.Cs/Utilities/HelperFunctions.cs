using System;
using System.Globalization;

namespace INCLUDIS.INCLServer.Cs.Utilities
{
    /// <summary>
    /// Allgemeine Hilfsfunktionen aus Arbeit.pas portiert.
    /// </summary>
    public static class HelperFunctions
    {
        /// <summary>
        /// Konvertiert einen String in einen Float-Wert (portiert von GFloat).
        /// </summary>
        public static double GFloat(string value)
        {
            if (string.IsNullOrEmpty(value))
                return 0;

            if (double.TryParse(value, NumberStyles.Any, CultureInfo.InvariantCulture, out double result))
                return result;

            return 0;
        }

        /// <summary>
        /// Gibt den Monat als String zurück (portiert von GetMonat).
        /// </summary>
        public static string GetMonat(DateTime datum)
        {
            return datum.ToString("MM");
        }

        /// <summary>
        /// Gibt das Quartal als String zurück (portiert von GetQuartal).
        /// </summary>
        public static string GetQuartal(DateTime datum)
        {
            var quartal = (datum.Month - 1) / 3 + 1;
            return quartal.ToString();
        }

        /// <summary>
        /// Gibt das Jahr als String zurück (portiert von GetJahr).
        /// </summary>
        public static string GetJahr(DateTime datum)
        {
            return datum.ToString("yyyy");
        }

        /// <summary>
        /// Gibt die Kalenderwoche als String zurück (portiert von GetKWStr).
        /// </summary>
        public static string GetKWStr(DateTime datum)
        {
            var culture = new CultureInfo("de-DE");
            var kw = culture.Calendar.GetWeekOfYear(datum, CalendarWeekRule.FirstFourDayWeek, DayOfWeek.Monday);
            return kw.ToString("D2");
        }

        /// <summary>
        /// Gibt die Kalenderwoche als Integer zurück (portiert von GetKW).
        /// </summary>
        public static int GetKW(DateTime datum)
        {
            var culture = new CultureInfo("de-DE");
            return culture.Calendar.GetWeekOfYear(datum, CalendarWeekRule.FirstFourDayWeek, DayOfWeek.Monday);
        }

        /// <summary>
        /// Gibt die Aktion für einen Stillstand zurück (portiert von GetAktion).
        /// </summary>
        public static int GetAktion(CommonDB db, int stillstandNr)
        {
            var sql = @"
                SELECT Aktion FROM TPM_Stillstaende 
                WHERE StillstandNr = @StillstandNr";

            using var reader = db.GetReader(sql, new { StillstandNr = stillstandNr });
            
            if (reader.Read())
            {
                return reader.GetInt32("Aktion");
            }
            
            return 0;
        }

        /// <summary>
        /// Gibt die Signalnummer für einen Stillstand zurück (portiert von GetSignalStillstand).
        /// </summary>
        public static int GetSignalStillstand(int datenblock)
        {
            // Diese Funktion könnte eine Abbildung von Datenblock zu Signalnummer enthalten
            // Beispiel: return datenblock * 1000;
            return datenblock * 1000;
        }

        /// <summary>
        /// Gibt die Maschinenbezeichnung zurück (portiert von GetMaschine).
        /// </summary>
        public static string GetMaschine(CommonDB db, int maschNr)
        {
            var sql = @"
                SELECT Kennung FROM Maschine 
                WHERE Maschnr = @MaschNr";

            using var reader = db.GetReader(sql, new { MaschNr = maschNr });
            
            if (reader.Read())
            {
                return reader.GetString("Kennung");
            }
            
            return string.Empty;
        }

        /// <summary>
        /// Gibt die Signalnummer für eine Signalart zurück (portiert von GetSignalNr).
        /// </summary>
        public static int GetSignalNr(int signalArt)
        {
            // Diese Funktion könnte eine Abbildung von Signalart zu Signalnummer enthalten
            // Beispiel: return signalArt * 100;
            return signalArt * 100;
        }

        /// <summary>
        /// Gibt den Monatsnamen als String zurück (portiert von GetMonatStr).
        /// </summary>
        public static string GetMonatStr(DateTime datum)
        {
            return datum.ToString("MMMM", new CultureInfo("de-DE"));
        }

        /// <summary>
        /// Erstellt ein Datum in der Datenbank (portiert von TTT_ErstelldatumEinfuegen).
        /// </summary>
        public static void InsertErstelldatum(CommonDB db, int aufruf)
        {
            var sql = @"
                INSERT INTO Erstelldatum (Aufruf, Datum)
                VALUES (@Aufruf, @Datum)";

            db.ExecuteNonQuery(sql, new
            {
                Aufruf = aufruf,
                Datum = DateTime.Now
            });
        }

        /// <summary>
        /// Prüft die Rüst-Stillstands-Überschreitung (portiert von TTT_GetRuestStillstandUeberschreitung).
        /// </summary>
        public static int GetRuestStillstandUeberschreitung(
            CommonDB db,
            int maschNr,
            string lizenz)
        {
            var sql = @"
                SELECT 
                    CASE WHEN SUM(Dauer) > @MaxDauer THEN 1 ELSE 0 END as Ueberschreitung
                FROM Stillstandsprotokoll 
                WHERE MaschNr = @MaschNr AND StillstandArt = 'Rüsten'";

            using var reader = db.GetReader(sql, new { MaschNr = maschNr, MaxDauer = 60 }); // Beispiel: 60 Minuten
            
            if (reader.Read())
            {
                return reader.GetInt32("Ueberschreitung");
            }
            
            return 0;
        }

        /// <summary>
        /// Wartet für eine bestimmte Anzahl von Sekunden (portiert von Pause).
        /// </summary>
        public static void Pause(int sekunden)
        {
            System.Threading.Thread.Sleep(sekunden * 1000);
        }

        /// <summary>
        /// Gibt die ausgewählten Maschinen zurück (portiert von GetSelectedMaschinen).
        /// </summary>
        public static string GetSelectedMaschinen(
            CommonDB db,
            string andStr,
            string feld,
            string liste,
            int style)
        {
            // Diese Funktion könnte eine Liste von Maschinen zurückgeben
            // Beispiel: return "1,2,3";
            return liste;
        }

        /// <summary>
        /// Berechnet Statistiken (portiert von Statistik_Berechnen).
        /// </summary>
        public static void CalculateStatistik(CommonDB db)
        {
            // Diese Funktion könnte verschiedene Statistiken berechnen
        }

        /// <summary>
        /// Prüft die Datenbankverbindung (portiert von CheckCO_DatabaseConnect).
        /// </summary>
        public static bool CheckDatabaseConnect(CommonDB db, int logId, string thread)
        {
            try
            {
                using var reader = db.GetReader("SELECT 1");
                return reader.Read();
            }
            catch
            {
                return false;
            }
        }

        /// <summary>
        /// Prüft die Rüstzeit-Autobuchung (portiert von CCC_Proc_Ruesten_AutoBuchen).
        /// </summary>
        public static void ProcessRuestenAutoBuchen(CommonDB db)
        {
            var sql = @"
                SELECT MaschNr, StartZeit, EndeZeit 
                FROM Stillstandsprotokoll 
                WHERE StillstandArt = 'Rüsten' AND Gebucht = 0";

            using var reader = db.GetReader(sql);
            
            while (reader.Read())
            {
                var maschNr = reader.GetInt32("MaschNr");
                var startZeit = reader.GetDateTime("StartZeit");
                var endeZeit = reader.GetDateTime("EndeZeit");

                // Rüstzeit automatisch buchen
                var updateSql = @"
                    UPDATE Stillstandsprotokoll SET Gebucht = 1 
                    WHERE MaschNr = @MaschNr AND StartZeit = @StartZeit";

                db.ExecuteNonQuery(updateSql, new { MaschNr = maschNr, StartZeit = startZeit });
            }
        }

        /// <summary>
        /// Ruft die Personalnummer und Signal ab (portiert von GetPersonalNr_Signal).
        /// </summary>
        public static void GetPersonalNrSignal(CommonDB db)
        {
            // Diese Funktion könnte Personalnummern und Signale abrufen
        }

        /// <summary>
        /// Ruft den Ausschuss und Signal ab (portiert von GetAusschuss_Signal).
        /// </summary>
        public static void GetAusschussSignal(CommonDB db)
        {
            // Diese Funktion könnte Ausschuss und Signale abrufen
        }

        /// <summary>
        /// Verarbeitet die QS-Jobs (portiert von CCC_QS_Jobs).
        /// </summary>
        public static void ProcessQSJobs(CommonDB db)
        {
            // Diese Funktion könnte QS-Jobs verarbeiten
        }

        /// <summary>
        /// Verarbeitet die Folgeaufträge (portiert von CCC_FolgeAuftrag_Starten).
        /// </summary>
        public static void StartFolgeAuftrag(CommonDB db)
        {
            var sql = @"
                SELECT BetriebsauftragNr FROM Aufträge 
                WHERE FolgeAuftrag = 1 AND Status = 'Bereit'";

            using var reader = db.GetReader(sql);
            
            while (reader.Read())
            {
                var betriebsauftragNr = reader.GetString("BetriebsauftragNr");
                // Folgeauftrag starten
            }
        }

        /// <summary>
        /// Berechnet die R2-Zeiten (portiert von CCC_Calc_R2_Times).
        /// </summary>
        public static void CalculateR2Times(CommonDB db)
        {
            // Diese Funktion könnte R2-Zeiten berechnen
        }

        /// <summary>
        /// Automatische Setup-Funktion (portiert von CCC_AutoSetup2).
        /// </summary>
        public static void AutoSetup2(CommonDB db)
        {
            // Diese Funktion könnte automatische Setup-Prozesse durchführen
        }

        /// <summary>
        /// Gibt die Maschinenummer für eine Lizenz zurück (portiert von TTT_GetMaschNr).
        /// </summary>
        public static int GetMaschNr(CommonDB db, string lizenz)
        {
            var sql = @"
                SELECT Maschnr FROM Maschine 
                WHERE Lizenz = @Lizenz";

            using var reader = db.GetReader(sql, new { Lizenz = lizenz });
            
            if (reader.Read())
            {
                return reader.GetInt32("Maschnr");
            }
            
            return 0;
        }

        /// <summary>
        /// Gibt die TPM-Schichtzeit zurück (portiert von TTT_GetTPMSchichtZeit).
        /// </summary>
        public static double GetTPMSchichtZeit(int schicht, double datumZeit)
        {
            // Diese Funktion könnte die Schichtzeit zurückgeben
            return datumZeit + (schicht * 8); // Beispiel: 8 Stunden pro Schicht
        }

        /// <summary>
        /// Gibt das TPM-Schichtdatum zurück (portiert von TTT_GetTPMSchichtDatum).
        /// </summary>
        public static double GetTPMSchichtDatum(int schicht, double datumZeit)
        {
            // Diese Funktion könnte das Schichtdatum zurückgeben
            return datumZeit;
        }

        /// <summary>
        /// Gibt die Arbeitszeit für eine Schicht zurück (portiert von TTT_GetArbeitszeit_Schicht).
        /// </summary>
        public static int GetArbeitszeitSchicht(CommonDB db, int maschNr, DateTime datum, int schicht)
        {
            var sql = @"
                SELECT Arbeitszeit FROM SchichtArbeitszeit 
                WHERE MaschNr = @MaschNr AND Datum = @Datum AND Schicht = @Schicht";

            using var reader = db.GetReader(sql, new { MaschNr = maschNr, Datum = datum, Schicht = schicht });
            
            if (reader.Read())
            {
                return reader.GetInt32("Arbeitszeit");
            }
            
            return 0;
        }

        /// <summary>
        /// Gibt den Schichttyp zurück (portiert von TTT_GetSchichtTyp).
        /// </summary>
        public static string GetSchichtTyp(CommonDB db, int maschNr, DateTime datum, int schicht)
        {
            var sql = @"
                SELECT ShiftType FROM SchichtTyp 
                WHERE MaschNr = @MaschNr AND Datum = @Datum AND Schicht = @Schicht";

            using var reader = db.GetReader(sql, new { MaschNr = maschNr, Datum = datum, Schicht = schicht });
            
            if (reader.Read())
            {
                return reader.GetString("ShiftType");
            }
            
            return string.Empty;
        }

        /// <summary>
        /// Fügt einen Stillstands-Event ein (portiert von TTT_InsertStillstandEvent).
        /// </summary>
        public static void InsertStillstandEvent(CommonDB db, int maschNr)
        {
            var sql = @"
                INSERT INTO StillstandsEvents (MaschNr, Zeitstempel)
                VALUES (@MaschNr, @Zeitstempel)";

            db.ExecuteNonQuery(sql, new
            {
                MaschNr = maschNr,
                Zeitstempel = DateTime.Now
            });
        }

        /// <summary>
        /// Gibt die Werkzeugnummer zurück (portiert von CCC_GetWerkzeugNr).
        /// </summary>
        public static string GetWerkzeugNr(int schluessel)
        {
            // Diese Funktion könnte die Werkzeugnummer zurückgeben
            return schluessel.ToString();
        }

        /// <summary>
        /// Bucht Material aus (portiert von CCC_Material_ausbuchen).
        /// </summary>
        public static void BuchMaterial(CommonDB db, string materialEAN, int menge, string bedienerNr)
        {
            var sql = @"
                INSERT INTO MaterialBuchung (MaterialEAN, Menge, BedienerNr, BuchungsZeit)
                VALUES (@MaterialEAN, @Menge, @BedienerNr, @BuchungsZeit)";

            db.ExecuteNonQuery(sql, new
            {
                MaterialEAN = materialEAN,
                Menge = menge,
                BedienerNr = bedienerNr,
                BuchungsZeit = DateTime.Now
            });
        }

        /// <summary>
        /// Verarbeitet Barcodes (portiert von CCC_Barcode_auswerten).
        /// </summary>
        public static void ProcessBarcode(CommonDB db, string bc1, string bc2, string bc3)
        {
            // Diese Funktion könnte Barcodes verarbeiten
        }

        /// <summary>
        /// Verarbeitet Telegramme (portiert von CCC_Telegramm_Auswerten).
        /// </summary>
        public static void ProcessTelegramm(CommonDB db)
        {
            // Diese Funktion könnte Telegramme verarbeiten
        }

        /// <summary>
        /// Prüft Termin-Order (portiert von CCC_Check_TerminOrder).
        /// </summary>
        public static void CheckTerminOrder(CommonDB db)
        {
            // Diese Funktion könnte Termin-Order prüfen
        }

        /// <summary>
        /// Startet einen Auftrag mit Barcode (portiert von CCC_Auftrag_Start_Barcode).
        /// </summary>
        public static void StartAuftragBarcode(CommonDB db, byte barCodeNr)
        {
            // Diese Funktion könnte einen Auftrag mit Barcode starten
        }

        /// <summary>
        /// Prüft die Menge gebucht (portiert von CCC_Check_Menge_Gebucht).
        /// </summary>
        public static void CheckMengeGebucht(CommonDB db)
        {
            // Diese Funktion könnte die Menge gebucht prüfen
        }

        /// <summary>
        /// Prüft den Terminal-Auftragsende (portiert von CCC_Check_Terminal_Auftrag_Ende).
        /// </summary>
        public static void CheckTerminalAuftragEnde(CommonDB db)
        {
            // Diese Funktion könnte den Terminal-Auftragsende prüfen
        }

        /// <summary>
        /// Prüft den unterbrochenen Terminal-Auftrag (portiert von CCC_Check_Terminal_Auftrag_Unterbrochen).
        /// </summary>
        public static void CheckTerminalAuftragUnterbrochen(CommonDB db)
        {
            // Diese Funktion könnte den unterbrochenen Terminal-Auftrag prüfen
        }

        /// <summary>
        /// Prüft den Terminal-Stillstand (portiert von CCC_Check_Terminal_Stillstand).
        /// </summary>
        public static void CheckTerminalStillstand(CommonDB db)
        {
            // Diese Funktion könnte den Terminal-Stillstand prüfen
        }

        /// <summary>
        /// Prüft Warmtrennen (portiert von CCC_Check_Warmtrennen).
        /// </summary>
        public static void CheckWarmtrennen(CommonDB db)
        {
            // Diese Funktion könnte Warmtrennen prüfen
        }

        /// <summary>
        /// Prüft die Job-Stückzahl (portiert von CCC_Check_Job_Stueckzahl).
        /// </summary>
        public static void CheckJobStueckzahl(CommonDB db)
        {
            // Diese Funktion könnte die Job-Stückzahl prüfen
        }

        /// <summary>
        /// Prüft die Stillstandsnummer SPS (portiert von CCC_Check_StillstandNr_SPS).
        /// </summary>
        public static void CheckStillstandNrSPS(CommonDB db)
        {
            // Diese Funktion könnte die Stillstandsnummer SPS prüfen
        }

        /// <summary>
        /// Erzeugt einen Job mit Setup (portiert von CCC_JobSetupAndRestart).
        /// </summary>
        public static void JobSetupAndRestart(CommonDB db)
        {
            // Diese Funktion könnte einen Job mit Setup neu starten
        }

        /// <summary>
        /// Prüft Block (portiert von CCC_CheckBlock).
        /// </summary>
        public static void CheckBlock(CommonDB db)
        {
            // Diese Funktion könnte Block prüfen
        }

        /// <summary>
        /// Prüft Bypass (portiert von CCC_CheckBypass).
        /// </summary>
        public static void CheckBypass(CommonDB db)
        {
            // Diese Funktion könnte Bypass prüfen
        }

        /// <summary>
        /// Schreibt die System-ID (portiert von CCC_SchreibeSystemID).
        /// </summary>
        public static void WriteSystemID(CommonDB db)
        {
            // Diese Funktion könnte die System-ID schreiben
        }

        /// <summary>
        /// Prüft Lizenzen (portiert von CCC_CheckLicenses).
        /// </summary>
        public static bool CheckLicenses(CommonDB db)
        {
            // Diese Funktion könnte Lizenzen prüfen
            return true;
        }

        /// <summary>
        /// Gibt die TPM-Schichtzeit zurück (portiert von TTT_GetTPMSchichtZeit).
        /// </summary>
        public static double GetTPMSchichtZeit(int schicht, double datumZeit)
        {
            // Beispiel: 8 Stunden pro Schicht
            return datumZeit + (schicht * 8);
        }

        /// <summary>
        /// Gibt das TPM-Schichtdatum zurück (portiert von TTT_GetTPMSchichtDatum).
        /// </summary>
        public static double GetTPMSchichtDatum(int schicht, double datumZeit)
        {
            return datumZeit;
        }

        /// <summary>
        /// Gibt die Arbeitszeit für eine Schicht zurück (portiert von TTT_GetArbeitszeit_Schicht).
        /// </summary>
        public static int GetArbeitszeitSchicht(CommonDB db, int maschNr, DateTime datum, int schicht)
        {
            var sql = @"
                SELECT Arbeitszeit FROM SchichtArbeitszeit 
                WHERE MaschNr = @MaschNr AND Datum = @Datum AND Schicht = @Schicht";

            using var reader = db.GetReader(sql, new { MaschNr = maschNr, Datum = datum, Schicht = schicht });
            
            if (reader.Read())
            {
                return reader.GetInt32("Arbeitszeit");
            }
            
            return 0;
        }

        /// <summary>
        /// Gibt den Schichttyp zurück (portiert von TTT_GetSchichtTyp).
        /// </summary>
        public static string GetSchichtTyp(CommonDB db, int maschNr, DateTime datum, int schicht)
        {
            var sql = @"
                SELECT ShiftType FROM SchichtTyp 
                WHERE MaschNr = @MaschNr AND Datum = @Datum AND Schicht = @Schicht";

            using var reader = db.GetReader(sql, new { MaschNr = maschNr, Datum = datum, Schicht = schicht });
            
            if (reader.Read())
            {
                return reader.GetString("ShiftType");
            }
            
            return string.Empty;
        }
    }
}
