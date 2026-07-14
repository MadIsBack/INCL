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
        /// Liest einen String-Wert mit Null-Check.
        /// </summary>
        public static string GetStringSafe(this CommonReader reader, string name)
        {
            return reader.IsDBNull(name) ? string.Empty : reader.GetString(name);
        }

        /// <summary>
        /// Liest einen Int32-Wert mit Null-Check.
        /// </summary>
        public static int GetInt32Safe(this CommonReader reader, string name)
        {
            return reader.IsDBNull(name) ? 0 : reader.GetInt32(name);
        }

        /// <summary>
        /// Liest einen Int16-Wert mit Null-Check.
        /// </summary>
        public static short GetInt16Safe(this CommonReader reader, string name)
        {
            return reader.IsDBNull(name) ? (short)0 : reader.GetInt16(name);
        }

        /// <summary>
        /// Liest einen Boolean-Wert mit Null-Check.
        /// </summary>
        public static bool GetBooleanSafe(this CommonReader reader, string name)
        {
            if (reader.IsDBNull(name))
                return false;
            
            try
            {
                return reader.GetBoolean(name);
            }
            catch
            {
                // Falls der Wert als String gespeichert ist (z. B. "1" oder "0")
                var value = reader.GetString(name);
                return value == "1" || value.Equals("true", StringComparison.OrdinalIgnoreCase);
            }
        }

        /// <summary>
        /// Liest einen DateTime-Wert mit Null-Check.
        /// </summary>
        public static DateTime GetDateTimeSafe(this CommonReader reader, string name)
        {
            return reader.IsDBNull(name) ? DateTime.MinValue : reader.GetDateTime(name);
        }

        /// <summary>
        /// Liest einen Decimal-Wert mit Null-Check.
        /// </summary>
        public static decimal GetDecimalSafe(this CommonReader reader, string name)
        {
            return reader.IsDBNull(name) ? 0 : reader.GetDecimal(name);
        }

        /// <summary>
        /// Liest einen Double-Wert mit Null-Check.
        /// </summary>
        public static double GetDoubleSafe(this CommonReader reader, string name)
        {
            return reader.IsDBNull(name) ? 0 : Convert.ToDouble(reader.GetDecimal(name));
        }

        /// <summary>
        /// Liest einen Float-Wert mit Null-Check.
        /// </summary>
        public static float GetFloatSafe(this CommonReader reader, string name)
        {
            return reader.IsDBNull(name) ? 0 : Convert.ToSingle(reader.GetDecimal(name));
        }
    }
}
