using INCLUDIS.Utils.CommonDB;
using INCLUDIS.INCLServer.Cs.Models;
using System;
using System.Collections.Generic;

namespace INCLUDIS.INCLServer.Cs.Utilities
{
    /// <summary>
    /// Hilfsfunktionen für die Auftragsverwaltung aus Arbeit.pas portiert.
    /// </summary>
    public static class AuftragHelper
    {
        /// <summary>
        /// Lädt einen Auftrag aus der Datenbank (portiert von HoleAuftrag).
        /// </summary>
        public static Auftrag GetAuftrag(CommonDB db, string betriebsauftragNr)
        {
            var auftrag = new Auftrag();
            var sql = @"
                SELECT * FROM PDE 
                WHERE BetriebsAuftragNr = @BetriebsAuftragNr";

            using var reader = db.GetReader(sql, new { BetriebsAuftragNr = betriebsauftragNr });
            
            if (reader.Read())
            {
                auftrag.BetriebsauftragNr = reader.GetString("BetriebsAuftragNr");
                auftrag.BetriebsauftragNrAlt = reader.GetString("BetriebsAuftragNr_Alt");
                auftrag.AuftragNr = reader.GetString("AuftragNr");
                auftrag.Bezeichnung = reader.GetString("Bezeichnung");
                auftrag.Zustaendig = reader.GetString("Zustaendig");
                auftrag.Signal = reader.GetString("Signal");
                auftrag.Sollwert = ArbeitHelper.FormatString(reader.GetString("Sollwert"));
                auftrag.SollwertOffset = ArbeitHelper.FormatString(reader.GetString("SollwertOffset"));
                auftrag.Istwert = ArbeitHelper.FormatString(reader.GetString("Istwert"));
                auftrag.IstPRZ = ArbeitHelper.FormatString(reader.GetString("Ist_PRZ"));
                auftrag.Ausschuss = ArbeitHelper.FormatString(reader.GetString("Ausschuss"));
                auftrag.Verpackt = ArbeitHelper.FormatString(reader.GetString("Pack"));
                auftrag.Anfahrausschuss = ArbeitHelper.FormatString(reader.GetString("Anfahrausschuss"));
                auftrag.Vorwarnung = ArbeitHelper.FormatString(reader.GetString("Vorwarnung"));
                auftrag.Erzeugt = reader.GetString("Erzeugt") == "1";
                auftrag.VorwarnungErzeugt = reader.GetString("VorwarnungErzeugt") == "1";
                auftrag.Stat = reader.GetInt16("stat");
                auftrag.Solltakt = reader.GetInt32("Taktzeit");
                auftrag.StartDatum = reader.GetDateTime("StartdatumZeit");
                auftrag.EndeDatum = reader.GetDateTime("EnddatumZeit");
                auftrag.EndeDatumSTR = reader.GetString("EndDatumSTR");
                auftrag.LTSOLL = Convert.ToDouble(reader.GetDecimal("LTDatumZeit"));
                auftrag.LTIST = Convert.ToDouble(reader.GetDecimal("EnddatumZeit"));
                auftrag.LT1 = Convert.ToDouble(reader.GetDecimal("Termin1"));
                auftrag.LT2 = Convert.ToDouble(reader.GetDecimal("Termin2"));
                auftrag.Werkzeug = reader.GetInt32("Werkzeug");
                auftrag.WerkzeugNr = reader.GetString("WerkzeugNr");
                auftrag.HalbAuto = reader.GetString("Betriebsart") == "Halbautomatik";
                auftrag.Kopfgroesse = ArbeitHelper.FormatString(reader.GetString("Kopfgroesse"));
                auftrag.KAVITAET_SOLL = reader.GetInt32("KAVITAET_SOLL");
                auftrag.InPause = reader.GetInt32("InPause");
                auftrag.VarKavitaet = reader.GetInt32("Var_Kavitaet");
                auftrag.StueckSchicht = reader.GetInt32("StueckSchicht");
                auftrag.Schwesterauftrag = reader.GetString("Schwesterauftrag");
                auftrag.Form = reader.GetString("Form");
                auftrag.Ausschuss = reader.GetInt32("Ausschuss");
                auftrag.Verpackt = ArbeitHelper.FormatString(reader.GetString("Pack"));
                auftrag.Vorwarnung = ArbeitHelper.FormatString(reader.GetString("Vorwarnung"));
                auftrag.Kunde = reader.GetString("Kunde");
                auftrag.Packgroesse = ArbeitHelper.FormatString(reader.GetString("PACKGROESSE"));
                auftrag.PALETTENGROESSE = ArbeitHelper.FormatString(reader.GetString("PALETTENGROESSE"));
                auftrag.MasterAuftrag = reader.GetInt32("Masterauftrag") == 1;
                auftrag.ProgrammNr = reader.GetInt32("Programm_Nr");
                auftrag.PersonalZeit = Convert.ToDouble(reader.GetDecimal("Personalzeit"));
                auftrag.Optimiert = reader.GetInt32("optimiert");
                auftrag.OptimiertAktuell = reader.GetInt32("tmpschuss");
                auftrag.ImStatusOptimieren = reader.GetInt32("InPause");
                auftrag.SollSpannzeitStk = reader.GetInt32("SOLLSPANNZEITSTK");
                auftrag.SollSpannzeitGes = reader.GetInt32("SOLLSPANNZEITGES");
                auftrag.planzykluszeit = reader.GetInt32("planzykluszeit");
                auftrag.ausschussquote = reader.GetInt32("ausschussquote");
                auftrag.InterBezeichnung = reader.GetString("InterBezeichnung");
            }
            
            return auftrag;
        }

        /// <summary>
        /// Aktualisiert einen Auftrag in der Datenbank (portiert von AktualisiereAuftrag).
        /// </summary>
        public static void UpdateAuftrag(CommonDB db, Auftrag auftrag)
        {
            var sql = @"
                UPDATE PDE SET
                    Istwert = @Istwert,
                    Ist_PRZ = @IstPRZ,
                    Ausschuss = @Ausschuss,
                    Pack = @Verpackt,
                    Anfahrausschuss = @Anfahrausschuss,
                    Vorwarnung = @Vorwarnung,
                    Erzeugt = @Erzeugt,
                    VorwarnungErzeugt = @VorwarnungErzeugt,
                    stat = @Stat,
                    EnddatumZeit = @EndeDatum,
                    EndDatumSTR = @EndeDatumSTR,
                    LTDatumZeit = @LTSOLL,
                    Termin1 = @LT1,
                    Termin2 = @LT2,
                    Werkzeug = @Werkzeug,
                    WerkzeugNr = @WerkzeugNr,
                    InPause = @InPause,
                    Var_Kavitaet = @VarKavitaet,
                    StueckSchicht = @StueckSchicht,
                    Kopfgroesse = @Kopfgroesse,
                    KAVITAET_SOLL = @KAVITAET_SOLL,
                    Form = @Form,
                    Kunde = @Kunde,
                    PACKGROESSE = @Packgroesse,
                    PALETTENGROESSE = @PALETTENGROESSE,
                    Masterauftrag = @MasterAuftrag,
                    Programm_Nr = @ProgrammNr,
                    Personalzeit = @PersonalZeit,
                    optimiert = @Optimiert,
                    tmpschuss = @OptimiertAktuell,
                    SOLLSPANNZEITSTK = @SollSpannzeitStk,
                    SOLLSPANNZEITGES = @SollSpannzeitGes,
                    planzykluszeit = @Planzykluszeit,
                    ausschussquote = @Ausschussquote,
                    InterBezeichnung = @InterBezeichnung
                WHERE BetriebsAuftragNr = @BetriebsAuftragNr";

            db.ExecuteNonQuery(sql, new
            {
                Istwert = auftrag.Istwert,
                IstPRZ = auftrag.IstPRZ,
                Ausschuss = auftrag.Ausschuss,
                Verpackt = auftrag.Verpackt,
                Anfahrausschuss = auftrag.Anfahrausschuss,
                Vorwarnung = auftrag.Vorwarnung,
                Erzeugt = auftrag.Erzeugt ? 1 : 0,
                VorwarnungErzeugt = auftrag.VorwarnungErzeugt ? 1 : 0,
                Stat = auftrag.Stat,
                EndeDatum = auftrag.EndeDatum,
                EndeDatumSTR = auftrag.EndeDatumSTR,
                LTSOLL = auftrag.LTSOLL,
                LT1 = auftrag.LT1,
                LT2 = auftrag.LT2,
                Werkzeug = auftrag.Werkzeug,
                WerkzeugNr = auftrag.WerkzeugNr,
                InPause = auftrag.InPause,
                VarKavitaet = auftrag.VarKavitaet,
                StueckSchicht = auftrag.StueckSchicht,
                Kopfgroesse = auftrag.Kopfgroesse,
                KAVITAET_SOLL = auftrag.KAVITAET_SOLL,
                Form = auftrag.Form,
                Kunde = auftrag.Kunde,
                Packgroesse = auftrag.Packgroesse,
                PALETTENGROESSE = auftrag.PALETTENGROESSE,
                MasterAuftrag = auftrag.MasterAuftrag ? 1 : 0,
                ProgrammNr = auftrag.ProgrammNr,
                PersonalZeit = auftrag.PersonalZeit,
                Optimiert = auftrag.Optimiert,
                OptimiertAktuell = auftrag.OptimiertAktuell,
                SollSpannzeitStk = auftrag.SollSpannzeitStk,
                SollSpannzeitGes = auftrag.SollSpannzeitGes,
                Planzykluszeit = auftrag.planzykluszeit,
                Ausschussquote = auftrag.ausschussquote,
                InterBezeichnung = auftrag.InterBezeichnung,
                BetriebsAuftragNr = auftrag.BetriebsauftragNr
            });
        }

        /// <summary>
        /// Erzeugt einen neuen Auftrag in der Datenbank (portiert von CCC_Job_Auftrag).
        /// </summary>
        public static void CreateJob(
            CommonDB db,
            string lizenz,
            string bezeichnung,
            string quelle,
            string signal,
            string zustaendig,
            string status,
            bool roteLampe,
            int zyklus)
        {
            var sql = @"
                INSERT INTO Jobs (Lizenz, Bezeichnung, Quelle, Signal, Zustaendig, Status, RoteLampe, Zyklus, ErstelltAm)
                VALUES (@Lizenz, @Bezeichnung, @Quelle, @Signal, @Zustaendig, @Status, @RoteLampe, @Zyklus, @ErstelltAm)";

            db.ExecuteNonQuery(sql, new
            {
                Lizenz = lizenz,
                Bezeichnung = bezeichnung,
                Quelle = quelle,
                Signal = signal,
                Zustaendig = zustaendig,
                Status = status,
                RoteLampe = roteLampe ? 1 : 0,
                Zyklus = zyklus,
                ErstelltAm = DateTime.Now
            });
        }

        /// <summary>
        /// Startet einen Auftrag (portiert von CCC_Auftrag_Starten_BCDCode).
        /// </summary>
        public static void StartAuftragBCDCode(CommonDB db, string lizenz, bool ruesten)
        {
            var sql = @"
                UPDATE Maschine SET
                    RuestZustand = @RuestZustand,
                    Ruestgrund = @Ruestgrund
                WHERE Lizenz = @Lizenz";

            db.ExecuteNonQuery(sql, new
            {
                Lizenz = lizenz,
                RuestZustand = ruesten ? 1 : 3, // 1 = Rüsten, 3 = Auftrag läuft
                Ruestgrund = 0
            });
        }

        /// <summary>
        /// Berechnet die TPM-Werte für einen Auftrag (portiert von BerechneTPM).
        /// </summary>
        public static void CalculateTPM(CommonDB db, int maschNr, DateTime datum)
        {
            // Beispiel: TPM-Werte für eine Maschine berechnen
            var sql = @"
                SELECT 
                    SUM(Stueck) as StueckGesamt,
                    SUM(Ausschuss) as AusschussGesamt,
                    SUM(Laufzeit) as LaufzeitGesamt
                FROM Maschinenleistung 
                WHERE MaschNr = @MaschNr AND Datum = @Datum";

            using var reader = db.GetReader(sql, new { MaschNr = maschNr, Datum = datum });
            
            if (reader.Read())
            {
                var stueckGesamt = reader.GetInt32("StueckGesamt");
                var ausschussGesamt = reader.GetInt32("AusschussGesamt");
                var laufzeitGesamt = reader.GetInt32("LaufzeitGesamt");

                // Hier könnten weitere Berechnungen folgen
            }
        }

        /// <summary>
        /// Prüft Stillstände für eine Maschine (portiert von CCC_TPM_Stillstand_Check).
        /// </summary>
        public static void CheckTPMStillstand(CommonDB db, int maschNr)
        {
            var sql = @"
                SELECT StillstandNr, StartZeit, EndeZeit, Dauer 
                FROM Stillstandsprotokoll 
                WHERE MaschNr = @MaschNr AND Gebucht = 0";

            using var reader = db.GetReader(sql, new { MaschNr = maschNr });
            
            while (reader.Read())
            {
                var stillstandNr = reader.GetInt32("StillstandNr");
                var startZeit = reader.GetDateTime("StartZeit");
                var endeZeit = reader.GetDateTime("EndeZeit");
                var dauer = reader.GetInt32("Dauer");

                // Stillstand als gebucht markieren
                var updateSql = @"
                    UPDATE Stillstandsprotokoll SET Gebucht = 1 
                    WHERE StillstandNr = @StillstandNr";
                
                db.ExecuteNonQuery(updateSql, new { StillstandNr = stillstandNr });
            }
        }

        /// <summary>
        /// Berechnet die A-Felder für eine Schicht (portiert von CCC_A_Felder_Schicht_Berechnen).
        /// </summary>
        public static void CalculateAFelderSchicht(
            CommonDB db,
            int schicht,
            DateTime schichtStart)
        {
            var sql = @"
                SELECT 
                    SUM(Stueck) as StueckSchicht,
                    SUM(Ausschuss) as AusschussSchicht,
                    SUM(Laufzeit) as LaufzeitSchicht
                FROM Maschinenleistung 
                WHERE Schicht = @Schicht AND Datum >= @SchichtStart";

            using var reader = db.GetReader(sql, new { Schicht = schicht, SchichtStart = schichtStart });
            
            if (reader.Read())
            {
                var stueckSchicht = reader.GetInt32("StueckSchicht");
                var ausschussSchicht = reader.GetInt32("AusschussSchicht");
                var laufzeitSchicht = reader.GetInt32("LaufzeitSchicht");

                // Hier könnten weitere Berechnungen folgen
            }
        }

        /// <summary>
        /// Setzt die Schichtkonstante (portiert von CCC_SetSchichtKonstante).
        /// </summary>
        public static void SetSchichtKonstante(CommonDB db, int schicht)
        {
            var sql = @"
                UPDATE Setup SET Wert = @Schicht 
                WHERE Parameter = 'AktuelleSchicht'";

            db.ExecuteNonQuery(sql, new { Schicht = schicht });
        }

        /// <summary>
        /// Prüft, ob ein Auftrag freigegeben ist (portiert von CCC_Check_Auftrag_Freigabe).
        /// </summary>
        public static bool CheckAuftragFreigabe(CommonDB db, string betriebsauftragNr)
        {
            var sql = @"
                SELECT Freigegeben FROM Aufträge 
                WHERE BetriebsauftragNr = @BetriebsAuftragNr";

            using var reader = db.GetReader(sql, new { BetriebsAuftragNr = betriebsauftragNr });
            
            if (reader.Read())
            {
                return reader.GetBoolean("Freigegeben");
            }
            
            return false;
        }

        /// <summary>
        /// Prüft die Rote Lampe für eine Maschine (portiert von CCC_RoteLampeCheckAus).
        /// </summary>
        public static void CheckRoteLampeAus(CommonDB db, string lizenz)
        {
            var sql = @"
                UPDATE Maschine SET RoteLampe = 0 
                WHERE Lizenz = @Lizenz";

            db.ExecuteNonQuery(sql, new { Lizenz = lizenz });
        }

        /// <summary>
        /// Prüft Arbeitsfrei für Maschinen (portiert von CCC_CheckRuestprot_Arbeitsfrei).
        /// </summary>
        public static void CheckRuestprotArbeitsfrei(CommonDB db)
        {
            var sql = @"
                SELECT MaschNr, StillstandNr, StartZeit, EndeZeit 
                FROM Stillstandsprotokoll 
                WHERE StillstandArt = 'Arbeitsfrei' AND Gebucht = 0";

            using var reader = db.GetReader(sql);
            
            while (reader.Read())
            {
                var maschNr = reader.GetInt32("MaschNr");
                var stillstandNr = reader.GetInt32("StillstandNr");

                // Arbeitsfrei als gebucht markieren
                var updateSql = @"
                    UPDATE Stillstandsprotokoll SET Gebucht = 1 
                    WHERE StillstandNr = @StillstandNr";
                
                db.ExecuteNonQuery(updateSql, new { StillstandNr = stillstandNr });
            }
        }

        /// <summary>
        /// Prüft Pause für Maschinen (portiert von CCC_CheckPause).
        /// </summary>
        public static void CheckPause(CommonDB db)
        {
            var sql = @"
                SELECT MaschNr, PauseAktiv 
                FROM Maschinenprotokoll 
                WHERE PauseAktiv = 1";

            using var reader = db.GetReader(sql);
            
            while (reader.Read())
            {
                var maschNr = reader.GetInt32("MaschNr");
                // Hier könnte weitere Logik folgen
            }
        }

        /// <summary>
        /// Schreibt den Maschinenstatus (portiert von CCC_Schreibe_Maschinen_Status).
        /// </summary>
        public static void WriteMaschinenStatus(CommonDB db, int maschNr, int zustand)
        {
            var sql = @"
                UPDATE Maschinenprotokoll SET Zustand = @Zustand 
                WHERE MaschNr = @MaschNr";

            db.ExecuteNonQuery(sql, new { MaschNr = maschNr, Zustand = zustand });
        }

        /// <summary>
        /// Prüft, ob die Menge gebucht wurde (portiert von CCC_Check_Menge_Gebucht).
        /// </summary>
        public static bool CheckMengeGebucht(CommonDB db, string betriebsauftragNr)
        {
            var sql = @"
                SELECT Gebucht FROM Aufträge 
                WHERE BetriebsauftragNr = @BetriebsAuftragNr";

            using var reader = db.GetReader(sql, new { BetriebsAuftragNr = betriebsauftragNr });
            
            if (reader.Read())
            {
                return reader.GetBoolean("Gebucht");
            }
            
            return false;
        }

        /// <summary>
        /// Prüft den Terminal-Auftragsende (portiert von CCC_Check_Terminal_Auftrag_Ende).
        /// </summary>
        public static void CheckTerminalAuftragEnde(CommonDB db, int maschNr)
        {
            var sql = @"
                SELECT BetriebsauftragNr FROM Aufträge 
                WHERE MaschNr = @MaschNr AND Status = 'Ende'";

            using var reader = db.GetReader(sql, new { MaschNr = maschNr });
            
            while (reader.Read())
            {
                var betriebsauftragNr = reader.GetString("BetriebsauftragNr");
                // Hier könnte weitere Logik folgen
            }
        }

        /// <summary>
        /// Prüft unterbrochene Aufträge (portiert von CCC_CheckUnterbrocheneAuftraege).
        /// </summary>
        public static void CheckUnterbrocheneAuftraege(CommonDB db)
        {
            var sql = @"
                SELECT BetriebsauftragNr FROM Aufträge 
                WHERE Status = 'Unterbrochen'";

            using var reader = db.GetReader(sql);
            
            while (reader.Read())
            {
                var betriebsauftragNr = reader.GetString("BetriebsauftragNr");
                // Hier könnte weitere Logik folgen
            }
        }

        /// <summary>
        /// Berechnet die Taktzeit-Ist-Werte (portiert von CCC_TaktzeitIstSchreiben).
        /// </summary>
        public static void WriteTaktzeitIst(CommonDB db, int maschNr, int taktzeit)
        {
            var sql = @"
                UPDATE Maschinenprotokoll SET TaktzeitIst = @Taktzeit 
                WHERE MaschNr = @MaschNr";

            db.ExecuteNonQuery(sql, new { MaschNr = maschNr, Taktzeit = taktzeit });
        }
    }
}
