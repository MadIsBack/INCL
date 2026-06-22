// <summary>
// CO_Library2_V63.cs - C# translation of CO_Library2_V63.pas
// Additional library functions
// </summary>

using System;
using System.Globalization;
using System.IO;

namespace INCLService_CSharp
{
    public static class CO_Library2_V63
    {
        /// <summary>
        /// Execute SQL query
        /// </summary>
        public static void SQL_Get(CO_Query Query, string SQLStr)
        {
            try
            {
                Query.Close();
                Query.SQL.Text = SQLStr;
                Query.Open();
                if (!Query.EOF)
                    Query.Next(); // Move to first record
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in SQL_Get: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Get value from table
        /// </summary>
        public static int SQLGet(CO_Query Query, string Tabelle, string Feld, string Wert, bool Ergebnis)
        {
            try
            {
                string SQLStr;
                if (Ergebnis)
                {
                    SQLStr = "Select COUNT(*) as CNT from " + Tabelle + " where " + Feld + "='" + Wert + "'";
                    SQL_Get(Query, SQLStr);
                    return Query.FieldByName("CNT").AsInteger;
                }
                else
                {
                    return -1;
                }
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in SQLGet: " + ex.Message, 0);
                return -1;
            }
        }

        /// <summary>
        /// Insert SQL
        /// </summary>
        public static void SQL_Insert(CO_Query Query, string SQLStr)
        {
            try
            {
                Query.Active = false;
                Query.SQL.Text = SQLStr;
                Query.ExecSQL();
                Query.Active = false;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in SQL_Insert: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Get machine number
        /// </summary>
        public static int GetMaschNr(CO_Query qTmp, string Maschine)
        {
            try
            {
                int Tmp = SQLGet(qTmp, "MASCHINE", "Lizenz", Maschine, true);
                if (Tmp > 0)
                    return qTmp.FieldByName("MaschNr").AsInteger;
                else
                {
                    Tmp = SQLGet(qTmp, "MaschOffline", "Lizenz", Maschine, true);
                    if (Tmp > 0)
                        return qTmp.FieldByName("MaschNr").AsInteger;
                }
                return -1;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in GetMaschNr: " + ex.Message, 0);
                return -1;
            }
        }

        /// <summary>
        /// Check if machine is online
        /// </summary>
        public static bool isMaschOnline(CO_Query qTmp, string Maschine)
        {
            try
            {
                return SQLGet(qTmp, "MASCHINE", "Lizenz", Maschine, true) > 0;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in isMaschOnline: " + ex.Message, 0);
                return false;
            }
        }

        /// <summary>
        /// Get order runtime
        /// </summary>
        public static int GetAuftragLaufZeit(CO_Query q1, CO_Query q2, string BANr)
        {
            try
            {
                string S, Liz;
                int MaschNr;
                double Start, Ende, lZeit, SZeit;

                if (SQLGet(q1, "AARchiv", "BetriebsAuftragNr", BANr, true) > 0)
                {
                    Liz = q1.FieldByName("Maschine").AsString;
                    MaschNr = GetMaschNr(q1, Liz);
                    if (isMaschOnline(q1, Liz))
                    {
                        lZeit = 0;
                        SQLGet(q1, "LaufzeitLog", "BetriebsAuftragNr", BANr, false);
                        while (!q1.EOF)
                        {
                            Start = q1.FieldByName("AuftragStart").AsFloat;
                            Ende = q1.FieldByName("AuftragEnde").AsFloat;
                            if (Ende == 0)
                                Ende = MainDLL.JetztFloat;
                            if (Start == 0)
                                Start = Ende;

                            S = "select Sum(Least(CASE WHEN Geht = 0 THEN 99999 ELSE Geht END, " +
                                SQL_fuc.FloatToStr2(Ende) + ")) - Greatest(Kommt, " +
                                SQL_fuc.FloatToStr2(Start) + ")) as CNT" +
                                " from TPM_Stillog, TPM_Stillstaende where MaschNr = " + MaschNr +
                                " and TPM_Stillog.StillstandNr = TPM_Stillstaende.StillstandNr and TPM_Stillstaende.StillstandNr = 3" +
                                " and Least(CASE WHEN Geht = 0 THEN 99999 ELSE Geht END, " +
                                SQL_fuc.FloatToStr2(Ende) + ") - Greatest(Kommt, " +
                                SQL_fuc.FloatToStr2(Start) + ") > 0";
                            SQL_Get(q2, S);
                            try
                            {
                                SZeit = q2.FieldByName("CNT").AsFloat;
                            }
                            catch (Exception)
                            {
                                SZeit = 0;
                            }
                            lZeit = lZeit + Ende - Start - SZeit;
                            q1.Next();
                        }
                        return (int)Math.Round(lZeit * 1440);
                    }
                    else // for Offline Maschinen
                    {
                        S = "select Sum(Duration) as CNT from Rework where JobNo = '" + BANr + "'";
                        SQL_Get(q1, S);
                        try
                        {
                            return q1.FieldByName("CNT").AsInteger;
                        }
                        catch (Exception)
                        {
                            return 0;
                        }
                    }
                }
                return 0;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in GetAuftragLaufZeit: " + ex.Message, 0);
                return 0;
            }
        }

        /// <summary>
        /// Convert float to string with point as decimal separator
        /// </summary>
        public static string FloatToPunktString(double aFloat)
        {
            try
            {
                string result = aFloat.ToString(CultureInfo.InvariantCulture);
                if (result.Contains(","))
                {
                    result = result.Replace(",", ".");
                }
                return result;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in FloatToPunktString: " + ex.Message, 0);
                return "0";
            }
        }

        /// <summary>
        /// Handle system error
        /// </summary>
        public static void HandleSystemError(object Sender, Exception E, string aCustomString)
        {
            try
            {
                string ClassThree = E.GetType().Name;
                Type ClassRef = E.GetType();
                while (ClassRef.BaseType != null)
                {
                    ClassRef = ClassRef.BaseType;
                    ClassThree = ClassRef.Name + " => " + ClassThree;
                }

                string S = "--- This report is created by automated reporting system.\n" +
                    "Form            : [" + (Sender != null ? Sender.GetType().Name : "Unknown") + "]\n" +
                    "EXE-File        : [" + System.Reflection.Assembly.GetExecutingAssembly().Location + "]\n" +
                    "DateTime        : [" + MainDLL.DateTimeToStr(DateTime.Now) + "]\n" +
                    "ClassThree      : [" + ClassThree + "]\n" +
                    "Message         : [" + E.Message + "]\n" +
                    "Comment         : [" + aCustomString + "]\n" +
                    "--- End of report ---------------------------------------\n";

                WriteLog(S);
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in HandleSystemError: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Write log to file
        /// </summary>
        public static void WriteLog(string aString)
        {
            try
            {
                string exeName = System.Reflection.Assembly.GetExecutingAssembly().Location;
                string fileName = Path.GetFileNameWithoutExtension(exeName);
                string TRACEFILE = fileName + ".log";
                string logPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, TRACEFILE);

                // Check file size
                if (File.Exists(logPath))
                {
                    FileInfo fileInfo = new FileInfo(logPath);
                    if (fileInfo.Length > (1024 * 1024)) // 1MB
                    {
                        File.WriteAllText(logPath, string.Empty); // Clear file
                    }
                }

                string S = MainDLL.DateTimeToStr(DateTime.Now) + ":   " + aString;
                File.AppendAllText(logPath, S + Environment.NewLine);
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in WriteLog: " + ex.Message, 0);
            }
        }
    }
}
