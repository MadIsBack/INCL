using System;
using System.Data;
using System.Data.Common;
using System.Globalization;
using System.IO;
using System.Reflection;
using System.Text;

namespace Komponenten_V63_CSharp
{
    public static class CO_Library_V63
    {
        public const int MaxDateiKB = 1024 * 15;

        // SQL Helper Methods
        public static void SQL_Get(CO_Query Query, string SQLStr)
        {
            bool doDebug = false;
#if DEBUG
            doDebug = true;
#endif
            SQL_Get(Query, SQLStr, doDebug);
        }

        public static bool SQL_Get(CO_Query Query, string SQLStr, bool doDebug)
        {
            try
            {
                Query.Close();
                Query.SQL = SQLStr;
                
                if (doDebug)
                {
                    try
                    {
                        Query.Open();
                        // Query.First(); // In C# we would use reader.Read()
                        return true;
                    }
                    catch (Exception e)
                    {
                        LogMeldung(e.Message + " because of:");
                        LogMeldung(Query.SQL);
                        return false;
                    }
                }
                else
                {
                    Query.Open();
                    // Query.First();
                }
                return true;
            }
            catch
            {
                return false;
            }
        }

        public static int SQLGet(CO_Query Query, string Tabelle, string Feld, string Wert, bool Ergebnis)
        {
            // Simplified implementation
            return 0;
        }

        public static void SQL_Insert(CO_Query Query, string SQLStr)
        {
            Query.SQL = SQLStr;
            Query.ExecSQL();
        }

        public static void UpdateSQL(CO_Query Query, string Tabelle, string UpdateFeld, string UpdateWert, string WhereFeld, string WhereWert)
        {
            string sql = "UPDATE " + Tabelle + " SET " + UpdateFeld + " = '" + UpdateWert + "' WHERE " + WhereFeld + " = '" + WhereWert + "'";
            Query.SQL = sql;
            Query.ExecSQL();
        }

        // Conversion and Formatting Methods
        public static double GFloat(string H)
        {
            if (double.TryParse(H, NumberStyles.Any, CultureInfo.InvariantCulture, out double result))
                return result;
            return 0.0;
        }

        public static string GetDatumZeitString(double DZeit)
        {
            // Convert from Delphi date/time format to string
            DateTime dateTime = DateTime.FromOADate(DZeit);
            return dateTime.ToString("yyyy-MM-dd HH:mm:ss");
        }

        public static string GetDatumString(double DZeit)
        {
            DateTime dateTime = DateTime.FromOADate(DZeit);
            return dateTime.ToString("yyyy-MM-dd");
        }

        public static int GetMaschNr(CO_Query qTmp, string Maschine)
        {
            // Query machine number from database
            qTmp.SQL = "SELECT maschnr FROM maschinen WHERE maschine = '" + Maschine + "'";
            qTmp.Open();
            // In real implementation: return qTmp.FieldByName("maschnr").AsInteger;
            return 0;
        }

        public static bool isMaschOnline(CO_Query qTmp, string Maschine)
        {
            // Check if machine is online
            qTmp.SQL = "SELECT online FROM maschinen WHERE maschine = '" + Maschine + "'";
            qTmp.Open();
            // In real implementation: return qTmp.FieldByName("online").AsBoolean;
            return false;
        }

        public static int GetStillstandNr(CO_Query qTmp, string Stillstand)
        {
            // Get stillstand number
            qTmp.SQL = "SELECT stillstandnr FROM stillstand WHERE stillstand = '" + Stillstand + "'";
            qTmp.Open();
            // In real implementation: return qTmp.FieldByName("stillstandnr").AsInteger;
            return 0;
        }

        public static void InitVersion(out string VerDatum, out string VERSION)
        {
            VerDatum = "";
            VERSION = "";
            // Implementation would read version info
        }

        public static int GetShiftNo(int Shift_Model, DateTime DT)
        {
            // Calculate shift number based on model and datetime
            return 0;
        }

        public static int GetAuftragLaufZeit(CO_Query q1, CO_Query q2, string BANr)
        {
            // Calculate order runtime
            return 0;
        }

        public static int GetAuftragLaufZeitVonBis(CO_Query Q, int MaschNr, double Von, double Bis)
        {
            // Calculate order runtime from/to
            return 0;
        }

        public static string FloatToPunktString(double aFloat)
        {
            return aFloat.ToString("0.000000", CultureInfo.InvariantCulture);
        }

        public static int UpdateIntWZStatus(CO_Query Q)
        {
            // Update internal tool status
            return 0;
        }

        public static int ManuellZeitBuchen(CO_Query Query, CO_Query qTmp, string Maschine, DateTime Datum1, DateTime Datum2, int Minuten, int Art)
        {
            // Manual time booking
            return 0;
        }

        public static bool isManuell(CO_Query Q, string Lizenz)
        {
            // Check if manual
            return false;
        }

        // Version Information Methods
        public static string GetCRC()
        {
            return "";
        }

        public static string GetVersion(int aDigits = 3)
        {
            return Assembly.GetExecutingAssembly().GetName().Version.ToString(aDigits);
        }

        public static string GetBuild()
        {
            return Assembly.GetExecutingAssembly().GetName().Version.Revision.ToString();
        }

        public static string GetVersionProductName()
        {
            var assembly = Assembly.GetExecutingAssembly();
            var attribute = assembly.GetCustomAttribute<AssemblyProductAttribute>();
            return attribute?.Product ?? "";
        }

        public static string GetVersionCompanyName()
        {
            var assembly = Assembly.GetExecutingAssembly();
            var attribute = assembly.GetCustomAttribute<AssemblyCompanyAttribute>();
            return attribute?.Company ?? "";
        }

        public static string GetVersionFileDescription()
        {
            var assembly = Assembly.GetExecutingAssembly();
            var attribute = assembly.GetCustomAttribute<AssemblyDescriptionAttribute>();
            return attribute?.Description ?? "";
        }

        public static string GetVersionFileVersion()
        {
            return Assembly.GetExecutingAssembly().GetName().Version.ToString();
        }

        public static string GetVersionInternalName()
        {
            return Assembly.GetExecutingAssembly().GetName().Name;
        }

        public static string GetVersionLegalCopyright()
        {
            var assembly = Assembly.GetExecutingAssembly();
            var attribute = assembly.GetCustomAttribute<AssemblyCopyrightAttribute>();
            return attribute?.Copyright ?? "";
        }

        public static string GetVersionLegalTradeMarks()
        {
            var assembly = Assembly.GetExecutingAssembly();
            var attribute = assembly.GetCustomAttribute<AssemblyTrademarkAttribute>();
            return attribute?.Trademark ?? "";
        }

        public static string GetVersionOriginalFileName()
        {
            return Assembly.GetExecutingAssembly().Location;
        }

        public static string GetVersionProductVersion()
        {
            return Assembly.GetExecutingAssembly().GetName().Version.ToString();
        }

        public static string GetVersionComment()
        {
            var assembly = Assembly.GetExecutingAssembly();
            var attribute = assembly.GetCustomAttribute<AssemblyDescriptionAttribute>();
            return attribute?.Description ?? "";
        }

        public static string GetTimeZone(CO_Query Q, bool withText)
        {
            return "";
        }

        public static string CheckBetriebsauftragNr(CO_Query Q, string BA, bool CheckForDuplicate = false)
        {
            return BA;
        }

        public static string EANberechnen(DateTime Datum, CO_Query aQuery, ref int idx)
        {
            return "";
        }

        public static string EANberechnen(DateTime Datum, CO_Query aQuery)
        {
            int dummy = 0;
            return EANberechnen(Datum, aQuery, ref dummy);
        }

        public static bool MaterialChargeZubuchen(string BANr, string Materialid, string GRN, CO_Query aQuery, string Source)
        {
            return false;
        }

        public static bool MaterialChargeZubuchen(string BANr, string Materialid, string GRN, CO_Query aQuery, string Source, string LogFileName, out string LogString)
        {
            LogString = "";
            return false;
        }

        public static string SiloBuchen(string BANr, string Materialid, string GRN, CO_Query aQuery, CO_Query bQuery)
        {
            return "";
        }

        public static string SiloBuchen(string BANr, string Materialid, string GRN, CO_Query aQuery, CO_Query bQuery, string LogFileName)
        {
            return "";
        }

        public static string CopyCavityAndGRN(string old, string newVal, string maschnr, CO_Query qSuch, CO_Query qSuch2, CO_Query qUpdate)
        {
            return "";
        }

        public static int CopySilo(string old, string newVal, CO_Query qSuch, CO_Query qSuch2)
        {
            return 0;
        }

        // Logging Methods
        public static void LogMeldung(string S)
        {
            LogMeldung(S, "");
        }

        public static void LogMeldung(string S, string FileName)
        {
            try
            {
                if (string.IsNullOrEmpty(FileName))
                    FileName = "log.txt";
                
                File.AppendAllText(FileName, DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + " - " + S + Environment.NewLine);
            }
            catch { }
        }
    }
}
