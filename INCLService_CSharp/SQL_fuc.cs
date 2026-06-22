// <summary>
// SQL_fuc.cs - C# translation of SQL_fuc.pas
// Contains SQL helper functions for database operations
// </summary>

using System;
using System.Data;
using System.Data.Common;
using System.Diagnostics;
using System.Globalization;

namespace INCLService_CSharp
{
    public static class SQL_fuc
    {
        // ========================================================================
        // Database Error Handling
        // ========================================================================
        
        /// <summary>
        /// Handle database errors
        /// </summary>
        public static bool Handle_DB_Error(string E)
        {
            // Check for ORA-01000 Max Oper Cursors exceeded
            if (E.ToUpper().Contains("ORA-01000"))
            {
                return RestartDatabase();
            }
            return false;
        }

        /// <summary>
        /// Restart database connection
        /// </summary>
        public static bool RestartDatabase()
        {
            try
            {
                if (DatenM.Instance != null && DatenM.Instance.Database != null)
                {
                    DatenM.Instance.Database.Connected = false;
                    DatenM.Instance.Database.Connected = true;
                    return DatenM.Instance.Database.Connected;
                }
            }
            catch { }
            return false;
        }

        // ========================================================================
        // SQL Query Functions
        // ========================================================================
        
        /// <summary>
        /// Execute SQL query and return result
        /// </summary>
        public static bool SQL_Get(CO_Query Query, string SQLStr)
        {
            string S = "";
            try
            {
                Query.Close();
                Query.SQL = SQLStr;
                Query.Open();
                bool result = !Query.IsEmpty();
                if (result)
                    Query.First();
                return result;
            }
            catch (Exception E)
            {
                DatenM.Instance.Conn = false;
                S = "";
                switch (Query.Tag)
                {
                    case 0: S = "(MAIN)"; break;
                    case 1: S = "(ADDON)"; break;
                    case 2: S = "(SHIFT)"; break;
                }
                MainDLL.SchreibeMeldung(S + " " + Sprache_V63.GetL("Exception. SQL: ") + Query.Name + ": " + SQLStr, 0);
                MainDLL.SchreibeMeldung("Message: " + E.Message, 0);

                if (Handle_DB_Error(E.Message))
                {
                    try
                    {
                        Query.Open();
                        return !Query.IsEmpty();
                    }
                    catch { }
                }
            }
            return false;
        }

        /// <summary>
        /// Execute SQL insert/update/delete and return affected rows
        /// </summary>
        public static int SQL_Insert(CO_Query Query, string SQLStr)
        {
            string S = "";
            try
            {
                Query.Close();
                Query.SQL = SQLStr;
                int result = Query.ExecSQL();
                return result;
            }
            catch (Exception E)
            {
                DatenM.Instance.Conn = false;
                S = "";
                switch (Query.Tag)
                {
                    case 0: S = "(MAIN)"; break;
                    case 1: S = "(ADDON)"; break;
                    case 2: S = "(SHIFT)"; break;
                }
                MainDLL.SchreibeMeldung(S + " " + Sprache_V63.GetL("Exception. SQL: ") + Query.Name + ": " + SQLStr, 0);
                MainDLL.SchreibeMeldung("Message: " + E.Message, 0);

                if (Handle_DB_Error(E.Message))
                {
                    try
                    {
                        Query.ExecSQL();
                    }
                    catch { }
                }
            }
            Query.Close();
            return 0;
        }

        // ========================================================================
        // SQL Get Functions with Conditions
        // ========================================================================
        
        /// <summary>
        /// Get record by single field condition
        /// </summary>
        public static bool SQLGetBool(CO_Query Query, string Tabelle, string Feld, string Wert)
        {
            string SQLStr = "Select * from " + Tabelle + " where " + Feld + "='" + Wert + "'";
            return SQL_Get(Query, SQLStr);
        }

        /// <summary>
        /// Get record by two field conditions
        /// </summary>
        public static bool SQL2GetBool(CO_Query Query, string Tabelle, string Feld, string Wert, string Feld2, string Wert2)
        {
            string SQLStr;
            
            if (string.IsNullOrEmpty(Wert) && string.IsNullOrEmpty(Wert2))
                SQLStr = "Select * from " + Tabelle;
            else if (!string.IsNullOrEmpty(Wert) && string.IsNullOrEmpty(Wert2))
                SQLStr = "Select * from " + Tabelle + " where " + Feld + "='" + Wert + "'";
            else if (string.IsNullOrEmpty(Wert) && !string.IsNullOrEmpty(Wert2))
                SQLStr = "Select * from " + Tabelle + " where " + Feld2 + "='" + Wert2 + "'";
            else
                SQLStr = "Select * from " + Tabelle + " where (" + Feld + "='" + Wert + "') AND (" + Feld2 + "='" + Wert2 + "')";
            
            return SQL_Get(Query, SQLStr);
        }

        /// <summary>
        /// Get record by three field conditions
        /// </summary>
        public static bool SQL3GetBool(CO_Query Query, string Tabelle, string Feld, string Wert, 
            string Feld2, string Wert2, string Feld3, string Wert3)
        {
            string SQLStr;
            
            if (string.IsNullOrEmpty(Wert) && string.IsNullOrEmpty(Wert2))
                SQLStr = "Select * from " + Tabelle;
            else if (!string.IsNullOrEmpty(Wert) && string.IsNullOrEmpty(Wert2))
                SQLStr = "Select * from " + Tabelle + " where " + Feld + "='" + Wert + "'";
            else if (string.IsNullOrEmpty(Wert) && !string.IsNullOrEmpty(Wert2))
                SQLStr = "Select * from " + Tabelle + " where " + Feld2 + "='" + Wert2 + "'";
            else
                SQLStr = "Select * from " + Tabelle + " where (" + Feld + "='" + Wert + "') AND(" + Feld2 + "='" + Wert2 + "')AND(" + Feld3 + "='" + Wert3 + "')";
            
            return SQL_Get(Query, SQLStr);
        }

        /// <summary>
        /// Get count of records by field condition
        /// </summary>
        public static int SQLGet(CO_Query Query, string Tabelle, string Feld, string Wert, bool Ergebnis)
        {
            if (Ergebnis)
            {
                string SQLStr = "Select COUNT(*) CNT from " + Tabelle + " where " + Feld + "='" + Wert + "'";
                SQL_Get(Query, SQLStr);
                if (!Query.IsEmpty())
                    return Query.FieldByName("CNT").AsInteger();
            }
            return -1;
        }

        /// <summary>
        /// Get count of records by two field conditions
        /// </summary>
        public static int SQL2Get(CO_Query Query, string Tabelle, string Feld, string Wert, 
            string Feld2, string Wert2, bool Ergebnis)
        {
            if (Ergebnis)
            {
                string SQLStr = "Select COUNT(*) CNT from " + Tabelle + " where " + Feld + "='" + Wert + "' AND " + Feld2 + "='" + Wert2 + "'";
                SQL_Get(Query, SQLStr);
                if (!Query.IsEmpty())
                    return Query.FieldByName("CNT").AsInteger();
            }
            return -1;
        }

        /// <summary>
        /// Get count of records by three field conditions
        /// </summary>
        public static int SQL3Get(CO_Query Query, string Tabelle, string Feld, string Wert, 
            string Feld2, string Wert2, string Feld3, string Wert3, bool Ergebnis)
        {
            if (Ergebnis)
            {
                string SQLStr = "Select COUNT(*) CNT from " + Tabelle + 
                    " where " + Feld + "='" + Wert + "' AND " + Feld2 + "='" + Wert2 + "' AND " + Feld3 + "='" + Wert3 + "'";
                SQL_Get(Query, SQLStr);
                if (!Query.IsEmpty())
                    return Query.FieldByName("CNT").AsInteger();
            }
            return -1;
        }

        // ========================================================================
        // SQL Update/Delete Functions
        // ========================================================================
        
        /// <summary>
        /// Update single field in table
        /// </summary>
        public static void UpdateSQL(CO_Query Query, string Tabelle, string UpdateFeld, string UpdateWert, 
            string WhereFeld, string WhereWert)
        {
            string SQLStr = "UPDATE " + Tabelle + " SET " + UpdateFeld + "='" + UpdateWert + "' WHERE " + WhereFeld + "='" + WhereWert + "'";
            SQL_Insert(Query, SQLStr);
        }

        /// <summary>
        /// Update single field in table with two conditions
        /// </summary>
        public static void Update2SQL(CO_Query Query, string Tabelle, string UpdateFeld, string UpdateWert, 
            string WhereFeld, string WhereWert, string WhereFeld2, string WhereWert2)
        {
            string SQLStr = "UPDATE " + Tabelle + " SET " + UpdateFeld + "='" + UpdateWert + 
                "' WHERE " + WhereFeld + "='" + WhereWert + "' AND " + WhereFeld2 + "='" + WhereWert2 + "'";
            SQL_Insert(Query, SQLStr);
        }

        /// <summary>
        /// Delete record from table
        /// </summary>
        public static void DeleteSQL(CO_Query Query, string Tabelle, string Feld, string Wert)
        {
            string SQLStr = "DELETE FROM " + Tabelle + " WHERE " + Feld + "='" + Wert + "'";
            SQL_Insert(Query, SQLStr);
        }

        // ========================================================================
        // Memory Functions
        // ========================================================================
        
        /// <summary>
        /// Get global memory usage in MB
        /// </summary>
        public static string GetGlobalMemory_MB()
        {
            try
            {
                using (PerformanceCounter counter = new PerformanceCounter("Memory", "Available MBytes"))
                {
                    return counter.NextValue().ToString();
                }
            }
            catch
            {
                return "0";
            }
        }

        /// <summary>
        /// Get current process memory usage in KB (integer)
        /// </summary>
        public static int CurrentProcessMemory_KBInt()
        {
            try
            {
                using (Process process = Process.GetCurrentProcess())
                {
                    return (int)(process.WorkingSet64 / 1024);
                }
            }
            catch
            {
                return 0;
            }
        }

        /// <summary>
        /// Get current process memory usage in KB (string)
        /// </summary>
        public static string CurrentProcessMemory_KB()
        {
            return CurrentProcessMemory_KBInt().ToString();
        }

        // ========================================================================
        // String Formatting Functions
        // ========================================================================
        
        /// <summary>
        /// Convert float to string with 2 decimal places
        /// </summary>
        public static string FloatToStr2(double Value)
        {
            return Value.ToString("0.00", CultureInfo.InvariantCulture);
        }

        /// <summary>
        /// Convert float to string with specified format
        /// </summary>
        public static string FloatToStrF2(double Value, int Format, int Precision, int Digits)
        {
            // Simplified version - Format parameter would control formatting style
            return Value.ToString("0." + new string('0', Digits), CultureInfo.InvariantCulture);
        }

        /// <summary>
        /// Convert float to string with point as decimal separator
        /// </summary>
        public static string FloatToPunktString(double Value)
        {
            return Value.ToString(CultureInfo.InvariantCulture);
        }

        /// <summary>
        /// Convert float to string with point as decimal separator and specified format
        /// </summary>
        public static string FloatToPunktStringF2(double Value, int Format, int Precision, int Digits)
        {
            return Value.ToString("0." + new string('0', Digits), CultureInfo.InvariantCulture);
        }

        // ========================================================================
        // Additional SQL Helper Functions
        // ========================================================================
        
        /// <summary>
        /// Get SQL query for specific table and conditions
        /// </summary>
        public static bool SQLGet(CO_Query Query, string Tabelle, string Feld, string Wert)
        {
            return SQLGetBool(Query, Tabelle, Feld, Wert);
        }

        /// <summary>
        /// Get SQL query for specific table and conditions with result flag
        /// </summary>
        public static int SQLGet(CO_Query Query, string Tabelle, string Feld, string Wert, bool Ergebnis)
        {
            return SQLGet(Query, Tabelle, Feld, Wert, Ergebnis);
        }

        /// <summary>
        /// Get SQL query for specific table and two conditions
        /// </summary>
        public static bool SQLGet(CO_Query Query, string Tabelle, string Feld, string Wert, string Feld2, string Wert2)
        {
            return SQL2GetBool(Query, Tabelle, Feld, Wert, Feld2, Wert2);
        }

        /// <summary>
        /// Get SQL query for specific table and two conditions with result flag
        /// </summary>
        public static int SQLGet(CO_Query Query, string Tabelle, string Feld, string Wert, 
            string Feld2, string Wert2, bool Ergebnis)
        {
            return SQL2Get(Query, Tabelle, Feld, Wert, Feld2, Wert2, Ergebnis);
        }

        /// <summary>
        /// Get SQL query for specific table and three conditions
        /// </summary>
        public static bool SQLGet(CO_Query Query, string Tabelle, string Feld, string Wert, 
            string Feld2, string Wert2, string Feld3, string Wert3)
        {
            return SQL3GetBool(Query, Tabelle, Feld, Wert, Feld2, Wert2, Feld3, Wert3);
        }

        /// <summary>
        /// Get SQL query for specific table and three conditions with result flag
        /// </summary>
        public static int SQLGet(CO_Query Query, string Tabelle, string Feld, string Wert, 
            string Feld2, string Wert2, string Feld3, string Wert3, bool Ergebnis)
        {
            return SQL3Get(Query, Tabelle, Feld, Wert, Feld2, Wert2, Feld3, Wert3, Ergebnis);
        }
    }
}