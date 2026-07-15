using INCLUDIS.Utils.CommonDB;
using System;
using System.Data;

namespace INCLUDIS.INCLServer.Cs.Utilities
{
    /// <summary>
    /// Erweiterungsmethoden für CommonReader, um Null-Checks zu vereinfachen.
    /// </summary>
    public static class CommonReaderExtensions
    {
        /// <summary>
        /// Prüft, ob ein Spaltenwert NULL ist.
        /// </summary>
        public static bool IsNull(this CommonReader reader, string columnName)
        {
            try
            {
                return reader[columnName] == DBNull.Value;
            }
            catch
            {
                return true; // Falls die Spalte nicht existiert
            }
        }

        /// <summary>
        /// Liest einen String-Wert mit Null-Check.
        /// </summary>
        public static string GetStringSafe(this CommonReader reader, string columnName)
        {
            return reader.IsNull(columnName) ? string.Empty : reader.GetString(columnName);
        }

        /// <summary>
        /// Liest einen Int32-Wert mit Null-Check.
        /// </summary>
        public static int GetInt32Safe(this CommonReader reader, string columnName)
        {
            return reader.IsNull(columnName) ? 0 : reader.GetInt32(columnName);
        }

        /// <summary>
        /// Liest einen Int16-Wert mit Null-Check.
        /// </summary>
        public static short GetInt16Safe(this CommonReader reader, string columnName)
        {
            return reader.IsNull(columnName) ? (short)0 : reader.GetInt16(columnName);
        }

        /// <summary>
        /// Liest einen Boolean-Wert mit Null-Check.
        /// </summary>
        public static bool GetBooleanSafe(this CommonReader reader, string columnName)
        {
            if (reader.IsNull(columnName))
                return false;
            
            try
            {
                return reader.GetBoolean(columnName);
            }
            catch
            {
                // Falls der Wert als String gespeichert ist (z. B. "1" oder "0")
                var value = reader.GetString(columnName);
                return value == "1" || value.Equals("true", StringComparison.OrdinalIgnoreCase);
            }
        }

        /// <summary>
        /// Liest einen DateTime-Wert mit Null-Check.
        /// </summary>
        public static DateTime GetDateTimeSafe(this CommonReader reader, string columnName)
        {
            return reader.IsNull(columnName) ? DateTime.MinValue : reader.GetDateTime(columnName);
        }

        /// <summary>
        /// Liest einen Decimal-Wert mit Null-Check.
        /// </summary>
        public static decimal GetDecimalSafe(this CommonReader reader, string columnName)
        {
            return reader.IsNull(columnName) ? 0 : reader.GetDecimal(columnName);
        }

        /// <summary>
        /// Liest einen Double-Wert mit Null-Check.
        /// </summary>
        public static double GetDoubleSafe(this CommonReader reader, string columnName)
        {
            return reader.IsNull(columnName) ? 0 : Convert.ToDouble(reader.GetDecimal(columnName));
        }

        /// <summary>
        /// Liest einen Float-Wert mit Null-Check.
        /// </summary>
        public static float GetFloatSafe(this CommonReader reader, string columnName)
        {
            return reader.IsNull(columnName) ? 0 : Convert.ToSingle(reader.GetDecimal(columnName));
        }
    }
}
