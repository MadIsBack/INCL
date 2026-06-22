// <summary>
// FlexKalender.cs - C# translation of FlexKalender.pas
// Flexible calendar functions
// </summary>

using System;

namespace INCLService_CSharp
{
    /// <summary>
    /// Flexible calendar class
    /// </summary>
    public static class FlexKalender
    {
        /// <summary>
        /// Check if date is work day
        /// </summary>
        public static bool IsWorkDay(DateTime date)
        {
            try
            {
                // Implementation would check calendar database
                // For now, return true for weekdays
                return date.DayOfWeek >= DayOfWeek.Monday && date.DayOfWeek <= DayOfWeek.Friday;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in IsWorkDay: " + ex.Message, 0);
                return true;
            }
        }

        /// <summary>
        /// Check if date is holiday
        /// </summary>
        public static bool IsHoliday(DateTime date)
        {
            try
            {
                // Implementation would check holiday database
                return false;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in IsHoliday: " + ex.Message, 0);
                return false;
            }
        }

        /// <summary>
        /// Get next work day
        /// </summary>
        public static DateTime GetNextWorkDay(DateTime date)
        {
            try
            {
                DateTime nextDay = date.AddDays(1);
                while (!IsWorkDay(nextDay) || IsHoliday(nextDay))
                {
                    nextDay = nextDay.AddDays(1);
                }
                return nextDay;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in GetNextWorkDay: " + ex.Message, 0);
                return date.AddDays(1);
            }
        }

        /// <summary>
        /// Get previous work day
        /// </summary>
        public static DateTime GetPreviousWorkDay(DateTime date)
        {
            try
            {
                DateTime prevDay = date.AddDays(-1);
                while (!IsWorkDay(prevDay) || IsHoliday(prevDay))
                {
                    prevDay = prevDay.AddDays(-1);
                }
                return prevDay;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in GetPreviousWorkDay: " + ex.Message, 0);
                return date.AddDays(-1);
            }
        }

        /// <summary>
        /// Get work days between two dates
        /// </summary>
        public static int GetWorkDaysBetween(DateTime startDate, DateTime endDate)
        {
            try
            {
                int count = 0;
                DateTime current = startDate;
                while (current <= endDate)
                {
                    if (IsWorkDay(current) && !IsHoliday(current))
                        count++;
                    current = current.AddDays(1);
                }
                return count;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in GetWorkDaysBetween: " + ex.Message, 0);
                return 0;
            }
        }

        /// <summary>
        /// Add work days to date
        /// </summary>
        public static DateTime AddWorkDays(DateTime date, int days)
        {
            try
            {
                DateTime result = date;
                int added = 0;
                while (added < days)
                {
                    result = result.AddDays(1);
                    if (IsWorkDay(result) && !IsHoliday(result))
                        added++;
                }
                return result;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in AddWorkDays: " + ex.Message, 0);
                return date.AddDays(days);
            }
        }
    }
}
