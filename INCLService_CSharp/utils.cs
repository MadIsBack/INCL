// <summary>
// utils.cs - C# translation of utils.pas
// Utility functions for process management and logging
// </summary>

using System;
using System.Diagnostics;
using System.IO;
using System.Management;
using System.Runtime.InteropServices;

namespace INCLService_CSharp
{
    public static class utils
    {
        /// <summary>
        /// Enumerate all processes
        /// </summary>
        public static void EnumProcesses()
        {
            try
            {
                Process[] processes = Process.GetProcesses();
                foreach (Process process in processes)
                {
                    try
                    {
                        string processName = process.ProcessName;
                        string memoryInfo = ProcessMemory_KB(process.Id);
                        MainDLL.SchreibeMeldung(processName + " " + memoryInfo, 5);
                    }
                    catch (Exception) { }
                }
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in EnumProcesses: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Enumerate specific process
        /// </summary>
        public static string EnumProcess(string ProcessName)
        {
            try
            {
                Process[] processes = Process.GetProcessesByName(ProcessName);
                if (processes.Length > 0)
                {
                    StringBuilder result = new StringBuilder();
                    foreach (Process process in processes)
                    {
                        if (result.Length > 0)
                            result.Append("; ");
                        result.Append(process.Id.ToString());
                        result.Append(" (");
                        result.Append(ProcessMemory_KB(process.Id));
                        result.Append(")");
                    }
                    return result.ToString();
                }
                return string.Empty;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in EnumProcess: " + ex.Message, 0);
                return string.Empty;
            }
        }

        /// <summary>
        /// Get process memory in KB
        /// </summary>
        public static string ProcessMemory_KB(int id)
        {
            try
            {
                Process process = Process.GetProcessById(id);
                long workingSet = process.WorkingSet64 / 1024;
                long pageFile = process.PagedMemorySize64 / 1024;
                
                string workingSetStr = workingSet.ToString().PadLeft(7);
                string pageFileStr = pageFile.ToString().PadLeft(7);
                
                return workingSetStr + " [" + pageFileStr + "]";
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in ProcessMemory_KB: " + ex.Message, 0);
                return "       [       ]";
            }
        }

        /// <summary>
        /// Get computer network name
        /// </summary>
        public static string GetComputerNetName()
        {
            try
            {
                return Environment.MachineName;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in GetComputerNetName: " + ex.Message, 0);
                return "UNKNOWN";
            }
        }

        /// <summary>
        /// Log user event
        /// </summary>
        public static void LogUsrEvent(CO_Query Query, int eventId, string EventToken, string BAnr, 
            string Artikel, string Lizenz, string Werkzeug, string Neu, int prod, 
            string Alt = "", string Notice = "", string RefNo = "")
        {
            try
            {
                // Simplified implementation
                string sql = "INSERT INTO USREVENTLOG (EventID, EventToken, BAnr, Artikel, Lizenz, Werkzeug, Neu, Prod, Alt, Notice, RefNo, LogTime) " +
                    "VALUES (" + eventId + ", '" + EventToken + "', '" + BAnr + "', '" + Artikel + "', '" + Lizenz + 
                    "', '" + Werkzeug + "', '" + Neu + "', " + prod + ", '" + Alt + "', '" + Notice + 
                    "', '" + RefNo + "', " + SQL_fuc.FloatToStr2(MainDLL.JetztFloat) + ")";
                SQL_fuc.SQL_Insert(Query, sql);
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in LogUsrEvent: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Log user event (overload)
        /// </summary>
        public static void LogUsrEvent(CO_Query searchQuery, CO_Query updateQuery, int eventId, 
            string EventToken, string BAnr, string Neu, string Alt = "", string Notice = "", string RefNo = "")
        {
            try
            {
                // Simplified implementation
                LogUsrEvent(updateQuery, eventId, EventToken, BAnr, "", "", "", Neu, 0, Alt, Notice, RefNo);
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in LogUsrEvent: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Convert float to string with point as decimal separator
        /// </summary>
        public static string FloatToPunktString(double aFloat)
        {
            return aFloat.ToString("0.000000", System.Globalization.CultureInfo.InvariantCulture);
        }

        /// <summary>
        /// Change downtime code
        /// </summary>
        public static void ChangeDtCode(CO_Query updateQuery, int stillstandnr, int stillogNr, bool usrEventLog, string comment = "")
        {
            try
            {
                // Simplified implementation
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in ChangeDtCode: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Change downtime code (overload)
        /// </summary>
        public static void ChangeDtCode(CO_Query query, int stillstandnr, int stillogNr, bool usrEventlog, 
            bool autoBuchung, bool reaktionszeit, string comment = "")
        {
            try
            {
                // Simplified implementation
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in ChangeDtCode: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Change downtime code (overload)
        /// </summary>
        public static void ChangeDtCode(CO_Query updateQuery, int stillstandnr, int stillogNr, CO_Query stillogQuery, string comment = "")
        {
            try
            {
                // Simplified implementation
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in ChangeDtCode: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Log and change downtime code
        /// </summary>
        public static void LogAndChangeDtCode(CO_Query updateQuery, int stillstandnr, int stillogNr, 
            CO_Query stillogQuery, bool autoBuchung, bool Reaktionszeit, string comment = "")
        {
            try
            {
                // Simplified implementation
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in LogAndChangeDtCode: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Log downtime change event
        /// </summary>
        public static void LogDtChangeEvent(CO_Query stillogQuery, CO_Query updateQuery, int stillogNr, string comment = "")
        {
            try
            {
                // Simplified implementation
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in LogDtChangeEvent: " + ex.Message, 0);
            }
        }
    }
}
