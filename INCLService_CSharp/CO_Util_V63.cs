// <summary>
// CO_Util_V63.cs - C# translation of CO_Util_V63.pas
// Utility functions
// </summary>

using System;
using System.Globalization;

namespace INCLService_CSharp
{
    /// <summary>
    /// CO_Util_V63 class - Utility functions
    /// </summary>
    public static class CO_Util_V63
    {
        /// <summary>
        /// Convert string to integer with default value
        /// </summary>
        public static int StrToIntDef(string S, int Default)
        {
            try
            {
                return int.Parse(S);
            }
            catch (Exception)
            {
                return Default;
            }
        }

        /// <summary>
        /// Convert string to double with default value
        /// </summary>
        public static double StrToFloatDef(string S, double Default)
        {
            try
            {
                S = S.Replace(",", ".");
                return double.Parse(S, CultureInfo.InvariantCulture);
            }
            catch (Exception)
            {
                return Default;
            }
        }

        /// <summary>
        /// Convert string to date with default value
        /// </summary>
        public static DateTime StrToDateDef(string S, DateTime Default)
        {
            try
            {
                return DateTime.Parse(S);
            }
            catch (Exception)
            {
                return Default;
            }
        }

        /// <summary>
        /// Format date as string
        /// </summary>
        public static string FormatDateTime(string Format, DateTime DateTime)
        {
            try
            {
                return DateTime.ToString(Format);
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in FormatDateTime: " + ex.Message, 0);
                return DateTime.ToString();
            }
        }

        /// <summary>
        /// Format float as string
        /// </summary>
        public static string FormatFloat(string Format, double Value)
        {
            try
            {
                return Value.ToString(Format, CultureInfo.InvariantCulture);
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in FormatFloat: " + ex.Message, 0);
                return Value.ToString(CultureInfo.InvariantCulture);
            }
        }

        /// <summary>
        /// Check if string is numeric
        /// </summary>
        public static bool IsNumeric(string S)
        {
            try
            {
                double result;
                return double.TryParse(S, NumberStyles.Any, CultureInfo.InvariantCulture, out result);
            }
            catch (Exception)
            {
                return false;
            }
        }

        /// <summary>
        /// Check if string is integer
        /// </summary>
        public static bool IsInteger(string S)
        {
            try
            {
                int result;
                return int.TryParse(S, out result);
            }
            catch (Exception)
            {
                return false;
            }
        }

        /// <summary>
        /// Get file extension
        /// </summary>
        public static string ExtractFileExt(string FileName)
        {
            try
            {
                int pos = FileName.LastIndexOf('.');
                if (pos >= 0)
                    return FileName.Substring(pos);
                return string.Empty;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in ExtractFileExt: " + ex.Message, 0);
                return string.Empty;
            }
        }

        /// <summary>
        /// Get file name without extension
        /// </summary>
        public static string ExtractFileName(string FileName)
        {
            try
            {
                int pos = FileName.LastIndexOf('.');
                if (pos >= 0)
                    return FileName.Substring(0, pos);
                return FileName;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in ExtractFileName: " + ex.Message, 0);
                return FileName;
            }
        }

        /// <summary>
        /// Get file path
        /// </summary>
        public static string ExtractFilePath(string FileName)
        {
            try
            {
                int pos = FileName.LastIndexOf(System.IO.Path.DirectorySeparatorChar);
                if (pos >= 0)
                    return FileName.Substring(0, pos);
                return string.Empty;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in ExtractFilePath: " + ex.Message, 0);
                return string.Empty;
            }
        }

        /// <summary>
        /// Replace substring
        /// </summary>
        public static string StringReplace(string S, string Old, string New)
        {
            try
            {
                return S.Replace(Old, New);
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in StringReplace: " + ex.Message, 0);
                return S;
            }
        }

        /// <summary>
        /// Convert to uppercase
        /// </summary>
        public static string UpperCase(string S)
        {
            try
            {
                return S.ToUpper();
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in UpperCase: " + ex.Message, 0);
                return S;
            }
        }

        /// <summary>
        /// Convert to lowercase
        /// </summary>
        public static string LowerCase(string S)
        {
            try
            {
                return S.ToLower();
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in LowerCase: " + ex.Message, 0);
                return S;
            }
        }
    }
}
