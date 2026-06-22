using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Common;
using System.Data.SQLite;
using System.Globalization;

namespace Komponenten_V63_CSharp
{
    public class FlexKalender : IDisposable
    {
        private int schicht1 = 360; // 6:00 AM in minutes
        private int schicht2 = 840; // 2:00 PM in minutes  
        private int schicht3 = 1320; // 10:00 PM in minutes

        private CO_Database fDatabase;
        private CO_Query fQuery1;
        private CO_Query fQuery2;

        private SQLiteConnection fSQLiteDB;
        private SQLiteCommand fSQLiteQuery;
        private SQLiteCommand fSQLiteQuery2;
        private SQLiteCommand fSQLiteUpdate;

        private object fOwner;

        public FlexKalender(object aOwner, CO_Query aQuery)
        {
            fOwner = aOwner;
            fDatabase = aQuery.Database;

            fQuery1 = new CO_Query();
            fQuery1.Database = fDatabase;
            fQuery2 = new CO_Query();
            fQuery2.Database = fDatabase;

            // Create SQLite in-memory database
            fSQLiteDB = new SQLiteConnection("Data Source=:memory:;Version=3;");
            fSQLiteDB.Open();

            fSQLiteQuery = new SQLiteCommand(fSQLiteDB);
            fSQLiteQuery2 = new SQLiteCommand(fSQLiteDB);
            fSQLiteUpdate = new SQLiteCommand(fSQLiteDB);

            Init();
        }

        private void CreateTable()
        {
            try
            {
                fSQLiteQuery.CommandText = "CREATE TABLE kalender_flex(" +
                    " NR Integer Primary Key, " +
                    " kalgruppe INTEGER," +
                    " startdatumzeit FLOAT," +
                    " enddatumzeit FLOAT," +
                    " zeitraum INTEGER" +
                    ")";
                fSQLiteQuery.ExecuteNonQuery();
            }
            catch { }

            try
            {
                fSQLiteQuery.CommandText = "create Index kalender_flex_start on kalender_flex(startdatumzeit)";
                fSQLiteQuery.ExecuteNonQuery();
            }
            catch { }

            try
            {
                fSQLiteQuery.CommandText = "create Index kalender_flex_ende on kalender_flex(enddatumzeit)";
                fSQLiteQuery.ExecuteNonQuery();
            }
            catch { }

            try
            {
                fSQLiteQuery.CommandText = "create Index kalender_flex_gruppe on kalender_flex(kalgruppe)";
                fSQLiteQuery.ExecuteNonQuery();
            }
            catch { }
        }

        private void CreateEntry(double aStart, double aEnde, int aGruppe)
        {
            fSQLiteQuery.CommandText = "INSERT INTO kalender_flex(kalgruppe, startdatumzeit, enddatumzeit, zeitraum) VALUES (" +
                aGruppe + "," +
                FloatToStrPunkt(aStart) + "," +
                FloatToStrPunkt(aEnde) + ",'" +
                Math.Round((aEnde - aStart) * 1440).ToString() + "')";
            fSQLiteQuery.ExecuteNonQuery();
        }

        private void SplittAllEntries(double aStart, double aEnde, int aGruppe)
        {
            int maxtag = (int)Math.Truncate(DateTime.Now.ToOADate());
            int mintag = (int)Math.Truncate(DateTime.Now.ToOADate());
            double kstart = 0, kende = 0;
            int knr = 0;

            try
            {
                fSQLiteQuery2.CommandText = "SELECT max(enddatumzeit) maxende FROM kalender_flex WHERE kalgruppe = " + aGruppe;
                using (var reader = fSQLiteQuery2.ExecuteReader())
                {
                    if (reader.Read())
                    {
                        maxtag = (int)Math.Truncate(Convert.ToDouble(reader["maxende"]));
                    }
                    reader.Close();
                }

                fSQLiteQuery2.CommandText = "SELECT min(startdatumzeit) minstart FROM kalender_flex WHERE kalgruppe = " + aGruppe;
                using (var reader = fSQLiteQuery2.ExecuteReader())
                {
                    if (reader.Read())
                    {
                        mintag = (int)Math.Truncate(Convert.ToDouble(reader["minstart"]));
                    }
                    reader.Close();
                }

                for (int tag = mintag; tag <= maxtag; tag++)
                {
                    fSQLiteQuery2.CommandText = "SELECT * FROM kalender_flex WHERE kalgruppe = " + aGruppe +
                        " AND startdatumzeit < " + FloatToStrPunkt(tag + aEnde) +
                        " AND enddatumzeit > " + FloatToStrPunkt(tag + aStart);
                    using (var reader = fSQLiteQuery2.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            kstart = Convert.ToDouble(reader["startdatumzeit"]);
                            kende = Convert.ToDouble(reader["enddatumzeit"]);
                            knr = Convert.ToInt32(reader["nr"]);

                            if ((tag + aStart <= kstart) && (tag + aEnde >= kende)) // Pause is larger than entry -> delete
                            {
                                fSQLiteUpdate.CommandText = "DELETE FROM kalender_flex WHERE nr = " + knr;
                                fSQLiteUpdate.ExecuteNonQuery();
                            }
                            else if (tag + aEnde > kende) // Pause starts earlier, move entry end
                            {
                                fSQLiteUpdate.CommandText = "UPDATE kalender_flex SET enddatumzeit = " + FloatToStrPunkt(tag + aStart) + " WHERE nr = " + knr;
                                fSQLiteUpdate.ExecuteNonQuery();
                            }
                            else if (tag + aStart < kstart) // Pause ends later, move entry start
                            {
                                fSQLiteUpdate.CommandText = "UPDATE kalender_flex SET startdatumzeit = " + FloatToStrPunkt(tag + aEnde) + " WHERE nr = " + knr;
                                fSQLiteUpdate.ExecuteNonQuery();
                            }
                            else // Split entry
                            {
                                fSQLiteUpdate.CommandText = "UPDATE kalender_flex SET enddatumzeit = " + FloatToStrPunkt(tag + aStart) + " WHERE nr = " + knr;
                                fSQLiteUpdate.ExecuteNonQuery();
                                CreateEntry(tag + aEnde, kende, aGruppe);
                            }
                        }
                        reader.Close();
                    }
                }
            }
            catch { }
        }

        private string FloatToStrPunkt(double aFloat)
        {
            char sepchar = CultureInfo.CurrentCulture.NumberFormat.NumberDecimalSeparator[0];
            CultureInfo.CurrentCulture.NumberFormat.NumberDecimalSeparator = ".";
            string result = aFloat.ToString(CultureInfo.InvariantCulture);
            CultureInfo.CurrentCulture.NumberFormat.NumberDecimalSeparator = sepchar.ToString();
            return result;
        }

        public int getArbeitsszeit(double aStart, double aEnde, int aGruppe)
        {
            string s = "0";
            
            fSQLiteQuery.CommandText = "SELECT ROUND(SUM( (CASE WHEN enddatumzeit > " + FloatToStrPunkt(aEnde) +
                " THEN " + FloatToStrPunkt(aEnde) +
                " ELSE enddatumzeit END - " +
                "CASE WHEN startdatumzeit < " + FloatToStrPunkt(aStart) +
                " THEN " + FloatToStrPunkt(aStart) +
                " ELSE startdatumzeit END ) * 1440)) sumsum " +
                "FROM kalender_flex WHERE " +
                "kalgruppe = " + aGruppe + " AND startdatumzeit < " +
                FloatToStrPunkt(aEnde) + " AND enddatumzeit > " + FloatToStrPunkt(aStart);
            
            using (var reader = fSQLiteQuery.ExecuteReader())
            {
                if (reader.Read())
                {
                    s = reader["sumsum"].ToString();
                }
                reader.Close();
            }

            if (string.IsNullOrEmpty(s))
                s = "0";
            
            if (s.Contains("."))
            {
                s = s.Replace(".", CultureInfo.CurrentCulture.NumberFormat.NumberDecimalSeparator.ToString());
            }

            return (int)Math.Round(double.Parse(s));
        }

        private double incDatum(double aDatetime, int aMinuten)
        {
            // Add minutes to datetime
            DateTime dateTime = DateTime.FromOADate(aDatetime);
            dateTime = dateTime.AddMinutes(aMinuten);
            return dateTime.ToOADate();
        }

        public void Init()
        {
            CreateTable();
            
            try
            {
                fSQLiteQuery.CommandText = "delete from kalender_flex";
                fSQLiteQuery.ExecuteNonQuery();
            }
            catch { }

            fQuery1.SQL = "select * from setup";
            fQuery1.Open();
            
            if (/* !fQuery1.IsEmpty */ false) // Simplified for now
            {
                schicht1 = 0; // fQuery1.FieldByName('schicht1').AsInteger;
                schicht2 = 0; // fQuery1.FieldByName('schicht2').AsInteger;
                schicht3 = 0; // fQuery1.FieldByName('schicht3').AsInteger;
            }
            else
            {
                schicht1 = 360;
                schicht2 = 840;
                schicht3 = 1320;
            }
            
            Refresh();
        }

        public void Refresh()
        {
            int[] zeitarray = new int[17];
            bool[] zustandakt = new bool[17]; // true = aktiv, false = nicht aktiv
            bool[] zustandlast = new bool[17]; // true = aktiv, false = nicht aktiv
            double[] start = new double[17];
            double[] ende = new double[17];
            int zeit12, zeit23, zeit31, bitfilter, pgruppe;
            double pstart = 0, pende = 0;
            int i, schichtzeit, schicht, sollschichtzeit, schichtstart = 0;

            try
            {
                fSQLiteQuery.CommandText = "DELETE FROM kalender_flex";
                fSQLiteQuery.ExecuteNonQuery();
            }
            catch { }

            zeit12 = schicht2 - schicht1;
            zeit23 = schicht3 - schicht2;
            zeit31 = 1440 - schicht3 + schicht1;

            for (i = 0; i <= 16; i++)
            {
                zeitarray[i] = 0;
                zustandakt[i] = false;
                zustandlast[i] = false;
            }

            // Convert from old to new calendar
            fQuery1.SQL = "SELECT * FROM kalender ORDER BY datumint";
            fQuery1.Open();
            
            // In a real implementation, we would process the query results
            // For now, this is a simplified version
            
            // Get pause times and split entries accordingly
            fQuery1.SQL = "SELECT * FROM pause ORDER BY kalendergruppe, startzeit";
            fQuery1.Open();
            
            // In a real implementation, we would process pause data
            // while not fQuery1.Eof do
            // {
            //   pstart = fQuery1.FieldByName('startzeit').AsFloat;
            //   pende = fQuery1.FieldByName('endzeit').AsFloat;
            //   pgruppe = fQuery1.FieldByName('kalendergruppenr').AsInteger;
            //   SplittAllEntries(pstart, pende, pgruppe);
            //   fQuery1.Next;
            // }
        }

        public void Dispose()
        {
            if (fSQLiteQuery != null)
            {
                fSQLiteQuery.Dispose();
                fSQLiteQuery = null;
            }
            
            if (fSQLiteQuery2 != null)
            {
                fSQLiteQuery2.Dispose();
                fSQLiteQuery2 = null;
            }
            
            if (fSQLiteUpdate != null)
            {
                fSQLiteUpdate.Dispose();
                fSQLiteUpdate = null;
            }
            
            if (fSQLiteDB != null)
            {
                if (fSQLiteDB.State == ConnectionState.Open)
                    fSQLiteDB.Close();
                fSQLiteDB.Dispose();
                fSQLiteDB = null;
            }
            
            if (fQuery1 != null)
            {
                fQuery1.Dispose();
                fQuery1 = null;
            }
            
            if (fQuery2 != null)
            {
                fQuery2.Dispose();
                fQuery2 = null;
            }
        }

        ~FlexKalender()
        {
            Dispose();
        }
    }
}
