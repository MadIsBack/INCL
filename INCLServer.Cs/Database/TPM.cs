using INCLUDIS.Utils.CommonDB;
using System;
using System.Data;

namespace INCLUDIS.INCLServer.Cs.Database
{
    /// <summary>
    /// Portierung der TCO_TPM-Klasse aus Delphi.
    /// Enthält Statistikfunktionen für Maschinenleistung, Stillstandszeiten, etc.
    /// </summary>
    public class TPM
    {
        private readonly Func<CommonDB> _dbFactory;
        
        public TPM(Func<CommonDB> dbFactory)
        {
            _dbFactory = dbFactory;
        }

        /// <summary>
        /// Berechnet die Schichtleistung für eine bestimmte Schicht.
        /// </summary>
        /// <param name="schichtId">ID der Schicht</param>
        public void BerechneSchicht(int schichtId)
        {
            using var db = _dbFactory();
            
            // Beispiel: Leistung für die Schicht berechnen
            var sql = @"
                UPDATE Schichtwechsel 
                SET Berechnet = 1,
                    Leistung = @Leistung
                WHERE Id = @SchichtId";

            db.ExecuteNonQuery(sql, new { SchichtId = schichtId, Leistung = BerechneLeistung(schichtId, db) });
        }

        /// <summary>
        /// Berechnet die Leistung für eine Schicht.
        /// </summary>
        private decimal BerechneLeistung(int schichtId, CommonDB db)
        {
            using var reader = db.GetReader("SELECT SUM(Stueck) FROM Maschinenleistung WHERE SchichtId = @SchichtId", new { SchichtId = schichtId });
            
            if (reader.Read() && !reader.IsDBNull(0))
            {
                return reader.GetDecimal(0);
            }
            return 0;
        }

        /// <summary>
        /// Berechnet die Stillstandszeiten für eine Maschine.
        /// </summary>
        /// <param name="maschNr">Maschinennummer</param>
        /// <param name="vonDatum">Startdatum</param>
        /// <param name="bisDatum">Enddatum</param>
        public void BerechneStillstandszeiten(int maschNr, DateTime vonDatum, DateTime bisDatum)
        {
            using var db = _dbFactory();
            
            var sql = @"
                SELECT StillstandNr, StartZeit, EndeZeit 
                FROM Stillstandsprotokoll 
                WHERE MaschNr = @MaschNr 
                AND StartZeit BETWEEN @VonDatum AND @BisDatum";

            using var reader = db.GetReader(sql, new { MaschNr = maschNr, VonDatum = vonDatum, BisDatum = bisDatum });
            
            while (reader.Read())
            {
                var stillstandNr = reader.GetInt32("StillstandNr");
                var startZeit = reader.GetDateTime("StartZeit");
                var endeZeit = reader.GetDateTime("EndeZeit");
                
                // Dauer berechnen
                var dauer = (int)(endeZeit - startZeit).TotalMinutes;
                
                // Stillstandszeit aktualisieren
                AktualisiereStillstandsDauer(db, stillstandNr, dauer);
            }
        }

        /// <summary>
        /// Aktualisiert die Dauer eines Stillstands.
        /// </summary>
        private void AktualisiereStillstandsDauer(CommonDB db, int stillstandNr, int dauer)
        {
            var sql = @"UPDATE Stillstandsprotokoll SET Dauer = @Dauer WHERE StillstandNr = @StillstandNr";
            db.ExecuteNonQuery(sql, new { StillstandNr = stillstandNr, Dauer = dauer });
        }

        /// <summary>
        /// Berechnet die Gesamtleistung für eine Maschine.
        /// </summary>
        public decimal BerechneGesamtLeistung(int maschNr)
        {
            using var db = _dbFactory();
            
            var sql = @"
                SELECT SUM(Stueck) as GesamtStueck 
                FROM Maschinenleistung 
                WHERE MaschNr = @MaschNr";

            using var reader = db.GetReader(sql, new { MaschNr = maschNr });
            return reader.Read() && !reader.IsDBNull(0) ? reader.GetDecimal(0) : 0;
        }

        /// <summary>
        /// Berechnet die Durchschnittsleistung für eine Maschine.
        /// </summary>
        public decimal BerechneDurchschnittsLeistung(int maschNr, DateTime vonDatum, DateTime bisDatum)
        {
            using var db = _dbFactory();
            
            var sql = @"
                SELECT AVG(StueckProStunde) as AvgLeistung 
                FROM Maschinenleistung 
                WHERE MaschNr = @MaschNr 
                AND Datum BETWEEN @VonDatum AND @BisDatum";

            using var reader = db.GetReader(sql, new { MaschNr = maschNr, VonDatum = vonDatum, BisDatum = bisDatum });
            return reader.Read() && !reader.IsDBNull(0) ? reader.GetDecimal(0) : 0;
        }

        /// <summary>
        /// Berechnet die Auslastung für eine Maschine.
        /// </summary>
        public decimal BerechneAuslastung(int maschNr, DateTime datum)
        {
            using var db = _dbFactory();
            
            var sql = @"
                SELECT 
                    (SUM(Laufzeit) * 100.0 / (24 * 60)) as Auslastung 
                FROM Maschinenprotokoll 
                WHERE MaschNr = @MaschNr AND Datum = @Datum";

            using var reader = db.GetReader(sql, new { MaschNr = maschNr, Datum = datum });
            return reader.Read() && !reader.IsDBNull(0) ? reader.GetDecimal(0) : 0;
        }
    }
}
