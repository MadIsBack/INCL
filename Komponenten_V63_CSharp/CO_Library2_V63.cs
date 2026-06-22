using System;
using System.Data;
using System.Globalization;
using System.IO;

namespace Komponenten_V63_CSharp
{
    public static class CO_Library2_V63
    {
        // SQL Helper Methods
        public static void SQL_Get(CO_Query Query, string SQLStr)
        {
            Query.Close();
            Query.SQL = SQLStr;
            Query.Open();
            // Query.First(); // In C# we would use reader.Read()
        }

        public static int SQLGet(CO_Query Query, string Tabelle, string Feld, string Wert, bool Ergebnis)
        {
            string SQLStr;
            
            if (Ergebnis)
            {
                SQLStr = "Select COUNT(*) as CNT from " + Tabelle + " where " + Feld + "='" + Wert + "'";
                Query.Close();
                SQL_Get(Query, SQLStr);
                // In real implementation: return Query.FieldByName("CNT").AsInteger;
                return 0;
            }
            else
            {
                return -1;
            }
        }

        public static void SQL_Insert(CO_Query Query, string SQLStr)
        {
            Query.Close();
            Query.SQL = SQLStr;
            Query.ExecSQL();
            Query.Close();
        }

        // Machine and Online Status Methods
        public static int GetMaschNr(CO_Query qTmp, string Maschine)
        {
            int Tmp = SQLGet(qTmp, "MASCHINE", "Lizenz", Maschine, true);
            if (Tmp > 0)
            {
                // In real implementation: return qTmp.FieldByName("MaschNr").AsInteger;
                return 0;
            }
            else
            {
                Tmp = SQLGet(qTmp, "MaschOffline", "Lizenz", Maschine, true);
                if (Tmp > 0)
                {
                    // In real implementation: return qTmp.FieldByName("MaschNr").AsInteger;
                    return 0;
                }
            }
            return -1;
        }

        public static bool isMaschOnline(CO_Query qTmp, string Maschine)
        {
            return SQLGet(qTmp, "MASCHINE", "Lizenz", Maschine, true) > 0;
        }

        // Time Calculation Methods
        public static int GetAuftragLaufZeit(CO_Query q1, CO_Query q2, string BANr)
        {
            string S, Liz;
            int MaschNr;
            double Start, Ende, lZeit, SZeit;
            
            if (SQLGet(q1, "AARchiv", "BetriebsAuftragNr", BANr, true) > 0)
            {
                Liz = ""; // In real implementation: q1.FieldByName('Maschine').AsString;
                MaschNr = GetMaschNr(q1, Liz);
                if (isMaschOnline(q1, Liz))
                {
                    lZeit = 0;
                    SQLGet(q1, "LaufzeitLog", "BetriebsAuftragNr", BANr, false);
                    // In real implementation, we would loop through results
                    // while not q1.EOF do
                    // {
                    //   Start = q1.FieldByName('AuftragStart').AsFloat;
                    //   Ende = q1.FieldByName('AuftragEnde').AsFloat;
                    //   if (Ende == 0) Ende = Now;
                    //   if (Start == 0) Start = Ende;
                    //   ...
                    // }
                    return (int)Math.Round(lZeit * 1440);
                }
                else // für Offline Maschinen
                {
                    S = "select Sum(Duration) as CNT from Rework where JobNo = '" + BANr + "'";
                    SQL_Get(q1, S);
                    try
                    {
                        // In real implementation: return q1.FieldByName('CNT').AsInteger;
                        return 0;
                    }
                    catch
                    {
                        return 0;
                    }
                }
            }
            return 0;
        }

        // String Formatting Methods
        public static string FloatToPunktString(double aFloat)
        {
            string result = aFloat.ToString(CultureInfo.InvariantCulture);
            if (result.Contains(","))
            {
                result = result.Replace(",", ".");
            }
            return result;
        }

        // Error Handling Methods
        public static void HandleSystemError(object Sender, Exception E, string aCustomString)
        {
            string S;
            string ClassThree = "";
            
            try
            {
                ClassThree = E.GetType().Name;
                // In Delphi: ClassRef := E.ClassType; while ClassRef.ClassParent <> nil do...
                // In C# we could traverse the inheritance hierarchy
            }
            catch { }

            S = "--- This report is created by automated reporting system.\n" +
                "Form            : [" + (/* SCREEN.ActiveForm.Name */ "Unknown") + "]\n" +
                "EXE-File        : [" + System.Reflection.Assembly.GetExecutingAssembly().Location + "]\n" +
                "DateTime        : [" + DateTime.Now.ToString() + "]\n" +
                "ClassThree      : [" + ClassThree + "]\n" +
                "Message         : [" + E.Message + "]\n" +
                "Comment         : [" + aCustomString + "]\n" +
                "--- End of report ---------------------------------------\n";

            WriteLog(S);
        }

        // Logging Methods
        public static void WriteLog(string aString)
        {
            string TRACEFILE = Path.ChangeExtension(System.Reflection.Assembly.GetExecutingAssembly().Location, ".log");
            
            try
            {
                if (!File.Exists(TRACEFILE))
                {
                    File.WriteAllText(TRACEFILE, "");
                }
                else
                {
                    // Check file size
                    long fileSize = new FileInfo(TRACEFILE).Length;
                    if (fileSize > (1024 * 1024)) // 1MB
                    {
                        File.WriteAllText(TRACEFILE, ""); // Delete file because too large
                    }
                }

                string logEntry = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + ":   " + aString + Environment.NewLine;
                File.AppendAllText(TRACEFILE, logEntry);
            }
            catch { }
        }
    }
}
