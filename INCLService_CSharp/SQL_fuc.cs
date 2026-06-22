using System;
using System.Data;
using System.Data.Common;
using System.Diagnostics;
using System.Globalization;

namespace INCLService_CSharp
{
    public static class SQL_fuc
    {
        public static bool Handle_DB_Error(string E)
        {
            // Check for ORA-01000 Max Oper Cursors exceeded
            if (E.ToUpper().Contains("ORA-01000"))
            {
                // Daten.Database.Connected = false;
                return RestartDatabase();
            }
            return false;
        }

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

        public static bool SQL_Get(CO_Query Query, string SQLStr)
        {
            string S = "";
            try
            {
                Query.Close();
                Query.SQL = SQLStr;
                Query.Open();
                bool result = /* !Query.IsEmpty */ false; // Simplified
                // Query.First();
                return result;
            }
            catch (Exception E)
            {
                if (DatenM.Instance != null)
                    DatenM.Instance.Conn = false;
                
                S = "";
                switch (Query.Tag)
                {
                    case 0: S = "(MAIN)"; break;
                    case 1: S = "(ADDON)"; break;
                    case 2: S = "(SHIFT)"; break;
                }
                
                // SchreibeMeldung(S + ' ' + GetL('Exception. SQL: ') + Query.Name + ': ' + SQLStr, 0);
                // SchreibeMeldung('Message: ' + E.Message, 0);
                
                if (Handle_DB_Error(E.Message))
                {
                    try
                    {
                        Query.Open();
                        return !/* Query.IsEmpty */ false; // Simplified
                    }
                    catch { }
                }
                return false;
            }
        }

        public static int SQL_Insert(CO_Query Query, string SQLStr)
        {
            try
            {
                Query.Close();
                Query.SQL = SQLStr;
                return Query.ExecSQL();
            }
            catch
            {
                return -1;
            }
        }

        public static bool SQLGetBool(CO_Query Query, string Tabelle, string Feld, string Wert)
        {
            return SQL_Get(Query, "SELECT * FROM " + Tabelle + " WHERE " + Feld + " = '" + Wert + "'");
        }

        public static bool SQL2GetBool(CO_Query Query, string Tabelle, string Feld, string Wert, string Feld2, string Wert2)
        {
            return SQL_Get(Query, "SELECT * FROM " + Tabelle + " WHERE " + Feld + " = '" + Wert + "' AND " + Feld2 + " = '" + Wert2 + "'");
        }

        public static bool SQL3GetBool(CO_Query Query, string Tabelle, string Feld, string Wert, string Feld2, string Wert2, string Feld3, string Wert3)
        {
            return SQL_Get(Query, "SELECT * FROM " + Tabelle + " WHERE " + Feld + " = '" + Wert + "' AND " + Feld2 + " = '" + Wert2 + "' AND " + Feld3 + " = '" + Wert3 + "'");
        }

        public static int SQLGet(CO_Query Query, string Tabelle, string Feld, string Wert, bool Ergebnis)
        {
            string SQLStr = "";
            if (Ergebnis)
            {
                SQLStr = "Select COUNT(*) as CNT from " + Tabelle + " where " + Feld + "='" + Wert + "'";
                SQL_Get(Query, SQLStr);
                // In real implementation: return Query.FieldByName("CNT").AsInteger;
                return 0;
            }
            else
            {
                SQLStr = "Select * from " + Tabelle + " where " + Feld + "='" + Wert + "'";
                SQL_Get(Query, SQLStr);
                return -1;
            }
        }

        public static int SQL2Get(CO_Query Query, string Tabelle, string Feld, string Wert, string Feld2, string Wert2, bool Ergebnis)
        {
            string SQLStr = "";
            if (Ergebnis)
            {
                SQLStr = "Select COUNT(*) as CNT from " + Tabelle + " where " + Feld + "='" + Wert + "' AND " + Feld2 + "='" + Wert2 + "'";
                SQL_Get(Query, SQLStr);
                // In real implementation: return Query.FieldByName("CNT").AsInteger;
                return 0;
            }
            else
            {
                SQLStr = "Select * from " + Tabelle + " where " + Feld + "='" + Wert + "' AND " + Feld2 + "='" + Wert2 + "'";
                SQL_Get(Query, SQLStr);
                return -1;
            }
        }

        public static int SQL3Get(CO_Query Query, string Tabelle, string Feld, string Wert, string Feld2, string Wert2, string Feld3, string Wert3, bool Ergebnis)
        {
            string SQLStr = "";
            if (Ergebnis)
            {
                SQLStr = "Select COUNT(*) as CNT from " + Tabelle + " where " + Feld + "='" + Wert + "' AND " + Feld2 + "='" + Wert2 + "' AND " + Feld3 + "='" + Wert3 + "'";
                SQL_Get(Query, SQLStr);
                // In real implementation: return Query.FieldByName("CNT").AsInteger;
                return 0;
            }
            else
            {
                SQLStr = "Select * from " + Tabelle + " where " + Feld + "='" + Wert + "' AND " + Feld2 + "='" + Wert2 + "' AND " + Feld3 + "='" + Wert3 + "'";
                SQL_Get(Query, SQLStr);
                return -1;
            }
        }

        public static void UpdateSQL(CO_Query Query, string Tabelle, string UpdateFeld, string UpdateWert, string WhereFeld, string WhereWert)
        {
            string sql = "UPDATE " + Tabelle + " SET " + UpdateFeld + " = '" + UpdateWert + "' WHERE " + WhereFeld + " = '" + WhereWert + "'";
            Query.SQL = sql;
            Query.ExecSQL();
        }

        public static void Update2SQL(CO_Query Query, string Tabelle, string UpdateFeld, string UpdateWert, string WhereFeld, string WhereWert, string WhereFeld2, string WhereWert2)
        {
            string sql = "UPDATE " + Tabelle + " SET " + UpdateFeld + " = '" + UpdateWert + "' WHERE " + WhereFeld + " = '" + WhereWert + "' AND " + WhereFeld2 + " = '" + WhereWert2 + "'";
            Query.SQL = sql;
            Query.ExecSQL();
        }

        public static void DeleteSQL(CO_Query Query, string Tabelle, string Feld, string Wert)
        {
            string sql = "DELETE FROM " + Tabelle + " WHERE " + Feld + " = '" + Wert + "'";
            Query.SQL = sql;
            Query.ExecSQL();
        }

        public static string GetGlobalMemory_MB()
        {
            try
            {
                Process currentProcess = Process.GetCurrentProcess();
                long memoryUsed = currentProcess.WorkingSet64 / (1024 * 1024);
                return memoryUsed.ToString();
            }
            catch
            {
                return "0";
            }
        }

        public static int CurrentProcessMemory_KBInt()
        {
            try
            {
                Process currentProcess = Process.GetCurrentProcess();
                return (int)(currentProcess.WorkingSet64 / 1024);
            }
            catch
            {
                return 0;
            }
        }

        public static string CurrentProcessMemory_KB()
        {
            return CurrentProcessMemory_KBInt().ToString();
        }

        public static string FloatToStr2(double Value)
        {
            return Value.ToString("0.00", CultureInfo.InvariantCulture);
        }

        public static string FloatToStrF2(double Value, System.Globalization.NumberFormatInfo Format, int Precision, int Digits)
        {
            // Simplified implementation
            return Value.ToString();
        }

        public static string FloatToPunktStringF2(double Value, System.Globalization.NumberFormatInfo Format, int Precision, int Digits)
        {
            string result = FloatToStrF2(Value, Format, Precision, Digits);
            if (result.Contains(","))
            {
                result = result.Replace(",", ".");
            }
            return result;
        }
    }
}
