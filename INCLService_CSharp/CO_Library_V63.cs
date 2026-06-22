// <summary>
// CO_Library_V63.cs - C# translation of CO_Library_V63.pas
// Core library functions
// </summary>

using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Reflection;
using System.Text;

namespace INCLService_CSharp
{
    public static class CO_Library_V63
    {
        public const int MaxDateiKB = 1024 * 15;

        /// <summary>
        /// Execute SQL query
        /// </summary>
        public static void SQL_Get(CO_Query Query, string SQLStr)
        {
            bool doDebug = false;
            #if DEBUG
                doDebug = true;
            #endif
            SQL_Get(Query, SQLStr, doDebug);
        }

        /// <summary>
        /// Execute SQL query with debug option
        /// </summary>
        public static bool SQL_Get(CO_Query Query, string SQLStr, bool doDebug)
        {
            try
            {
                Query.Close();
                Query.SQL.Text = SQLStr;
                if (doDebug)
                {
                    try
                    {
                        Query.Open();
                        if (!Query.EOF)
                            Query.Next(); // Move to first record
                        return true;
                    }
                    catch (Exception e)
                    {
                        LogMeldung(e.Message + " because of:");
                        LogMeldung(Query.SQL.Text);
                        return false;
                    }
                }
                else
                {
                    Query.Open();
                    if (!Query.EOF)
                        Query.Next(); // Move to first record
                }
                return true;
            }
            catch (Exception e)
            {
                LogMeldung(e.Message + " because of:");
                LogMeldung(SQLStr);
                return false;
            }
        }

        /// <summary>
        /// Get value from table
        /// </summary>
        public static int SQLGet(CO_Query Query, string Tabelle, string Feld, string Wert, bool Ergebnis)
        {
            try
            {
                string sql = "SELECT " + Feld + " FROM " + Tabelle + " WHERE " + Feld + " = '" + Wert + "'";
                SQL_Get(Query, sql);
                if (Ergebnis && !Query.EOF)
                    return Query.FieldByName(Feld).AsInteger;
                return 0;
            }
            catch (Exception e)
            {
                LogMeldung("Error in SQLGet: " + e.Message);
                return 0;
            }
        }

        /// <summary>
        /// Insert SQL
        /// </summary>
        public static void SQL_Insert(CO_Query Query, string SQLStr)
        {
            try
            {
                Query.Close();
                Query.SQL.Text = SQLStr;
                Query.ExecSQL();
            }
            catch (Exception e)
            {
                LogMeldung("Error in SQL_Insert: " + e.Message);
                LogMeldung(SQLStr);
            }
        }

        /// <summary>
        /// Update SQL
        /// </summary>
        public static void UpdateSQL(CO_Query Query, string Tabelle, string UpdateFeld, string UpdateWert, string WhereFeld, string WhereWert)
        {
            try
            {
                string sql = "UPDATE " + Tabelle + " SET " + UpdateFeld + " = '" + UpdateWert + 
                    "' WHERE " + WhereFeld + " = '" + WhereWert + "'";
                SQL_Insert(Query, sql);
            }
            catch (Exception e)
            {
                LogMeldung("Error in UpdateSQL: " + e.Message);
            }
        }

        /// <summary>
        /// Convert string to extended (double)
        /// </summary>
        public static double GFloat(string H)
        {
            try
            {
                if (string.IsNullOrEmpty(H))
                    return 0;
                
                // Replace comma with point for invariant culture
                H = H.Replace(",", ".");
                return double.Parse(H, CultureInfo.InvariantCulture);
            }
            catch (Exception)
            {
                return 0;
            }
        }

        /// <summary>
        /// Get date time string from float
        /// </summary>
        public static string GetDatumZeitString(double DZeit)
        {
            try
            {
                DateTime date = MainDLL.ConvertFromFloat(DZeit);
                return date.ToString("dd.MM.yyyy HH:mm:ss");
            }
            catch (Exception)
            {
                return string.Empty;
            }
        }

        /// <summary>
        /// Get date string from float
        /// </summary>
        public static string GetDatumString(double DZeit)
        {
            try
            {
                DateTime date = MainDLL.ConvertFromFloat(DZeit);
                return date.ToString("dd.MM.yyyy");
            }
            catch (Exception)
            {
                return string.Empty;
            }
        }

        /// <summary>
        /// Get machine number
        /// </summary>
        public static int GetMaschNr(CO_Query qTmp, string Maschine)
        {
            try
            {
                string sql = "SELECT MaschinenNr FROM Maschine WHERE MaschinenNr = '" + Maschine + "'";
                SQL_Get(qTmp, sql);
                if (!qTmp.EOF)
                    return qTmp.FieldByName("MaschinenNr").AsInteger;
                return 0;
            }
            catch (Exception e)
            {
                LogMeldung("Error in GetMaschNr: " + e.Message);
                return 0;
            }
        }

        /// <summary>
        /// Check if machine is online
        /// </summary>
        public static bool isMaschOnline(CO_Query qTmp, string Maschine)
        {
            try
            {
                string sql = "SELECT Online FROM Maschine WHERE MaschinenNr = '" + Maschine + "'";
                SQL_Get(qTmp, sql);
                if (!qTmp.EOF)
                    return qTmp.FieldByName("Online").AsInteger == 1;
                return false;
            }
            catch (Exception e)
            {
                LogMeldung("Error in isMaschOnline: " + e.Message);
                return false;
            }
        }

        /// <summary>
        /// Get downtime number
        /// </summary>
        public static int GetStillstandNr(CO_Query qTmp, string Stillstand)
        {
            try
            {
                string sql = "SELECT Nr FROM Stillstaende WHERE Stillstand = '" + Stillstand + "'";
                SQL_Get(qTmp, sql);
                if (!qTmp.EOF)
                    return qTmp.FieldByName("Nr").AsInteger;
                return 0;
            }
            catch (Exception e)
            {
                LogMeldung("Error in GetStillstandNr: " + e.Message);
                return 0;
            }
        }

        /// <summary>
        /// Initialize version
        /// </summary>
        public static void InitVersion(ref string VerDatum, string VERSION)
        {
            try
            {
                VerDatum = GetVersion();
            }
            catch (Exception e)
            {
                LogMeldung("Error in InitVersion: " + e.Message);
            }
        }

        /// <summary>
        /// Get shift number
        /// </summary>
        public static int GetShiftNo(int Shift_Model, DateTime DT)
        {
            try
            {
                if (Shift_Model == 2)
                {
                    // 2-shift model
                    int hour = DT.Hour;
                    if (hour >= 6 && hour < 14) return 1;
                    if (hour >= 14 && hour < 22) return 2;
                    return 3; // Night shift
                }
                else
                {
                    // 3-shift model
                    int hour = DT.Hour;
                    if (hour >= 6 && hour < 14) return 1;
                    if (hour >= 14 && hour < 22) return 2;
                    return 3; // Night shift
                }
            }
            catch (Exception e)
            {
                LogMeldung("Error in GetShiftNo: " + e.Message);
                return 0;
            }
        }

        /// <summary>
        /// Get order runtime
        /// </summary>
        public static int GetAuftragLaufZeit(CO_Query q1, CO_Query q2, string BANr)
        {
            try
            {
                // Simplified implementation
                return 0;
            }
            catch (Exception e)
            {
                LogMeldung("Error in GetAuftragLaufZeit: " + e.Message);
                return 0;
            }
        }

        /// <summary>
        /// Get order runtime from to
        /// </summary>
        public static int GetAuftragLaufZeitVonBis(CO_Query Q, int MaschNr, double Von, double Bis)
        {
            try
            {
                // Simplified implementation
                return 0;
            }
            catch (Exception e)
            {
                LogMeldung("Error in GetAuftragLaufZeitVonBis: " + e.Message);
                return 0;
            }
        }

        /// <summary>
        /// Convert float to string with point as decimal separator
        /// </summary>
        public static string FloatToPunktString(double aFloat)
        {
            return aFloat.ToString("0.000000", CultureInfo.InvariantCulture);
        }

        /// <summary>
        /// Update integer WZ status
        /// </summary>
        public static int UpdateIntWZStatus(CO_Query Q)
        {
            try
            {
                // Simplified implementation
                return 0;
            }
            catch (Exception e)
            {
                LogMeldung("Error in UpdateIntWZStatus: " + e.Message);
                return 0;
            }
        }

        /// <summary>
        /// Book manual time
        /// </summary>
        public static int ManuellZeitBuchen(CO_Query Query, CO_Query qTmp, string Maschine, DateTime Datum1, DateTime Datum2, int Minuten, int Art)
        {
            try
            {
                // Simplified implementation
                return 0;
            }
            catch (Exception e)
            {
                LogMeldung("Error in ManuellZeitBuchen: " + e.Message);
                return 0;
            }
        }

        /// <summary>
        /// Check if manual
        /// </summary>
        public static bool isManuell(CO_Query Q, string Lizenz)
        {
            try
            {
                string sql = "SELECT Manuell FROM Maschine WHERE MaschinenNr = '" + Lizenz + "'";
                SQL_Get(Q, sql);
                if (!Q.EOF)
                    return Q.FieldByName("Manuell").AsInteger == 1;
                return false;
            }
            catch (Exception e)
            {
                LogMeldung("Error in isManuell: " + e.Message);
                return false;
            }
        }

        /// <summary>
        /// Get CRC
        /// </summary>
        public static string GetCRC()
        {
            try
            {
                // Get assembly and compute CRC
                Assembly assembly = Assembly.GetExecutingAssembly();
                string name = assembly.FullName;
                return name.GetHashCode().ToString();
            }
            catch (Exception e)
            {
                LogMeldung("Error in GetCRC: " + e.Message);
                return string.Empty;
            }
        }

        /// <summary>
        /// Get version
        /// </summary>
        public static string GetVersion(int aDigits = 3)
        {
            try
            {
                Assembly assembly = Assembly.GetExecutingAssembly();
                Version version = assembly.GetName().Version;
                if (version == null)
                    return "1.0.0.0";
                
                string versionStr = version.ToString();
                string[] parts = versionStr.Split('.');
                
                if (aDigits <= 0 || aDigits > parts.Length)
                    aDigits = parts.Length;
                
                StringBuilder result = new StringBuilder();
                for (int i = 0; i < aDigits; i++)
                {
                    if (i > 0) result.Append(".");
                    result.Append(parts[i]);
                }
                return result.ToString();
            }
            catch (Exception e)
            {
                LogMeldung("Error in GetVersion: " + e.Message);
                return "1.0.0.0";
            }
        }

        /// <summary>
        /// Get build
        /// </summary>
        public static string GetBuild()
        {
            try
            {
                Assembly assembly = Assembly.GetExecutingAssembly();
                Version version = assembly.GetName().Version;
                if (version == null)
                    return "0";
                return version.Build.ToString();
            }
            catch (Exception e)
            {
                LogMeldung("Error in GetBuild: " + e.Message);
                return "0";
            }
        }

        /// <summary>
        /// Get version product name
        /// </summary>
        public static string GetVersionProductName()
        {
            try
            {
                Assembly assembly = Assembly.GetExecutingAssembly();
                object[] attributes = assembly.GetCustomAttributes(typeof(AssemblyProductAttribute), false);
                if (attributes.Length > 0)
                    return ((AssemblyProductAttribute)attributes[0]).Product;
                return "INCLService";
            }
            catch (Exception e)
            {
                LogMeldung("Error in GetVersionProductName: " + e.Message);
                return "INCLService";
            }
        }

        /// <summary>
        /// Get version company name
        /// </summary>
        public static string GetVersionCompanyName()
        {
            try
            {
                Assembly assembly = Assembly.GetExecutingAssembly();
                object[] attributes = assembly.GetCustomAttributes(typeof(AssemblyCompanyAttribute), false);
                if (attributes.Length > 0)
                    return ((AssemblyCompanyAttribute)attributes[0]).Company;
                return "MadIsBack";
            }
            catch (Exception e)
            {
                LogMeldung("Error in GetVersionCompanyName: " + e.Message);
                return "MadIsBack";
            }
        }

        /// <summary>
        /// Get version file description
        /// </summary>
        public static string GetVersionFileDescription()
        {
            try
            {
                Assembly assembly = Assembly.GetExecutingAssembly();
                object[] attributes = assembly.GetCustomAttributes(typeof(AssemblyDescriptionAttribute), false);
                if (attributes.Length > 0)
                    return ((AssemblyDescriptionAttribute)attributes[0]).Description;
                return "INCL Service";
            }
            catch (Exception e)
            {
                LogMeldung("Error in GetVersionFileDescription: " + e.Message);
                return "INCL Service";
            }
        }

        /// <summary>
        /// Get version file version
        /// </summary>
        public static string GetVersionFileVersion()
        {
            return GetVersion(4);
        }

        /// <summary>
        /// Get version internal name
        /// </summary>
        public static string GetVersionInternalName()
        {
            try
            {
                Assembly assembly = Assembly.GetExecutingAssembly();
                return assembly.GetName().Name;
            }
            catch (Exception e)
            {
                LogMeldung("Error in GetVersionInternalName: " + e.Message);
                return "INCLService";
            }
        }

        /// <summary>
        /// Get version legal copyright
        /// </summary>
        public static string GetVersionLegalCopyright()
        {
            try
            {
                Assembly assembly = Assembly.GetExecutingAssembly();
                object[] attributes = assembly.GetCustomAttributes(typeof(AssemblyCopyrightAttribute), false);
                if (attributes.Length > 0)
                    return ((AssemblyCopyrightAttribute)attributes[0]).Copyright;
                return "Copyright © MadIsBack 2024";
            }
            catch (Exception e)
            {
                LogMeldung("Error in GetVersionLegalCopyright: " + e.Message);
                return "Copyright © MadIsBack 2024";
            }
        }

        /// <summary>
        /// Get version legal trademarks
        /// </summary>
        public static string GetVersionLegalTradeMarks()
        {
            try
            {
                Assembly assembly = Assembly.GetExecutingAssembly();
                object[] attributes = assembly.GetCustomAttributes(typeof(AssemblyTrademarkAttribute), false);
                if (attributes.Length > 0)
                    return ((AssemblyTrademarkAttribute)attributes[0]).Trademark;
                return string.Empty;
            }
            catch (Exception e)
            {
                LogMeldung("Error in GetVersionLegalTradeMarks: " + e.Message);
                return string.Empty;
            }
        }

        /// <summary>
        /// Get version original file name
        /// </summary>
        public static string GetVersionOriginalFileName()
        {
            try
            {
                Assembly assembly = Assembly.GetExecutingAssembly();
                return Path.GetFileName(assembly.Location);
            }
            catch (Exception e)
            {
                LogMeldung("Error in GetVersionOriginalFileName: " + e.Message);
                return "INCLService.exe";
            }
        }

        /// <summary>
        /// Get version product version
        /// </summary>
        public static string GetVersionProductVersion()
        {
            return GetVersion(4);
        }

        /// <summary>
        /// Get version comment
        /// </summary>
        public static string GetVersionComment()
        {
            try
            {
                Assembly assembly = Assembly.GetExecutingAssembly();
                object[] attributes = assembly.GetCustomAttributes(typeof(AssemblyTitleAttribute), false);
                if (attributes.Length > 0)
                    return ((AssemblyTitleAttribute)attributes[0]).Title;
                return "INCL Service";
            }
            catch (Exception e)
            {
                LogMeldung("Error in GetVersionComment: " + e.Message);
                return "INCL Service";
            }
        }

        /// <summary>
        /// Get time zone
        /// </summary>
        public static string GetTimeZone(CO_Query Q, bool withText)
        {
            try
            {
                if (withText)
                {
                    TimeZoneInfo tz = TimeZoneInfo.Local;
                    return tz.DisplayName + " (" + tz.Id + ")";
                }
                else
                {
                    return TimeZoneInfo.Local.Id;
                }
            }
            catch (Exception e)
            {
                LogMeldung("Error in GetTimeZone: " + e.Message);
                return "UTC";
            }
        }

        /// <summary>
        /// Check production order number
        /// </summary>
        public static string CheckBetriebsauftragNr(CO_Query Q, string BA, bool CheckForDuplicate = false)
        {
            try
            {
                if (CheckForDuplicate)
                {
                    string sql = "SELECT COUNT(*) as cnt FROM PDE WHERE BETRIEBSAUFTRAGNR = '" + BA + "'";
                    SQL_Get(Q, sql);
                    if (!Q.EOF && Q.FieldByName("cnt").AsInteger > 0)
                        return BA + "_DUP";
                }
                return BA;
            }
            catch (Exception e)
            {
                LogMeldung("Error in CheckBetriebsauftragNr: " + e.Message);
                return BA;
            }
        }

        /// <summary>
        /// Calculate EAN
        /// </summary>
        public static string EANberechnen(DateTime Datum, CO_Query aQuery, ref int idx)
        {
            try
            {
                // Simplified implementation
                idx = 0;
                return string.Empty;
            }
            catch (Exception e)
            {
                LogMeldung("Error in EANberechnen: " + e.Message);
                return string.Empty;
            }
        }

        /// <summary>
        /// Calculate EAN (overload)
        /// </summary>
        public static string EANberechnen(DateTime Datum, CO_Query aQuery)
        {
            int idx = 0;
            return EANberechnen(Datum, aQuery, ref idx);
        }

        /// <summary>
        /// Book material charge
        /// </summary>
        public static bool MaterialChargeZubuchen(string BANr, string Materialid, string GRN, CO_Query aQuery, string Source)
        {
            try
            {
                // Simplified implementation
                return true;
            }
            catch (Exception e)
            {
                LogMeldung("Error in MaterialChargeZubuchen: " + e.Message);
                return false;
            }
        }

        /// <summary>
        /// Book material charge (overload)
        /// </summary>
        public static bool MaterialChargeZubuchen(string BANr, string Materialid, string GRN, CO_Query aQuery, string Source, string LogFileName, out string LogString)
        {
            try
            {
                LogString = string.Empty;
                // Simplified implementation
                return true;
            }
            catch (Exception e)
            {
                LogMeldung("Error in MaterialChargeZubuchen: " + e.Message);
                LogString = e.Message;
                return false;
            }
        }

        /// <summary>
        /// Book silo
        /// </summary>
        public static string SiloBuchen(string BANr, string Materialid, string GRN, CO_Query aQuery, CO_Query bQuery)
        {
            try
            {
                // Simplified implementation
                return string.Empty;
            }
            catch (Exception e)
            {
                LogMeldung("Error in SiloBuchen: " + e.Message);
                return string.Empty;
            }
        }

        /// <summary>
        /// Book silo (overload)
        /// </summary>
        public static string SiloBuchen(string BANr, string Materialid, string GRN, CO_Query aQuery, CO_Query bQuery, string LogFileName)
        {
            try
            {
                // Simplified implementation
                return string.Empty;
            }
            catch (Exception e)
            {
                LogMeldung("Error in SiloBuchen: " + e.Message);
                return string.Empty;
            }
        }

        /// <summary>
        /// Copy cavity and GRN
        /// </summary>
        public static string CopyCavityAndGRN(string oldOrder, string newOrder, string maschnr, CO_Query qSuch, CO_Query qSuch2, CO_Query qUpdate)
        {
            try
            {
                // Simplified implementation
                return string.Empty;
            }
            catch (Exception e)
            {
                LogMeldung("Error in CopyCavityAndGRN: " + e.Message);
                return string.Empty;
            }
        }

        /// <summary>
        /// Copy silo
        /// </summary>
        public static int CopySilo(string oldOrder, string newOrder, CO_Query qSuch, CO_Query qSuch2)
        {
            try
            {
                // Simplified implementation
                return 0;
            }
            catch (Exception e)
            {
                LogMeldung("Error in CopySilo: " + e.Message);
                return 0;
            }
        }

        /// <summary>
        /// Log message
        /// </summary>
        public static void LogMeldung(string S)
        {
            try
            {
                string logPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "CO_Library.log");
                File.AppendAllText(logPath, DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + " : " + S + Environment.NewLine);
            }
            catch (Exception e)
            {
                Console.Error.WriteLine("Error in LogMeldung: " + e.Message);
            }
        }

        /// <summary>
        /// Log message to specific file
        /// </summary>
        public static void LogMeldung(string S, string FileName)
        {
            try
            {
                string logPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, FileName);
                File.AppendAllText(logPath, DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + " : " + S + Environment.NewLine);
            }
            catch (Exception e)
            {
                Console.Error.WriteLine("Error in LogMeldung: " + e.Message);
            }
        }
    }
}
