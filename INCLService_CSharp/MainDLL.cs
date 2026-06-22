// <summary>
// MainDLL.cs - C# translation of MainDll.pas
// Main DLL utility functions and global data
// </summary>

using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;

namespace INCLService_CSharp
{
    /// <summary>
    /// Machine record
    /// </summary>
    public class TMaschine
    {
        public string MaschName { get; set; } = string.Empty;
        public int KalenderGruppe { get; set; } = 0;
        public double KapazitaetsFaktor { get; set; } = 1.0;
    }

    /// <summary>
    /// Work calendar record
    /// </summary>
    public class TWerkskalender
    {
        public int Tag { get; set; } = 0;
        public short[,] Schicht { get; set; } = new short[4, 17]; // [1..3, 0..MaxKalender]
        public byte[] SchichtEnde { get; set; } = new byte[17]; // [0..MaxKalender]
        public int[] Personal { get; set; } = new int[4]; // [1..3]
    }

    /// <summary>
    /// Main DLL class with utility functions and global data
    /// </summary>
    public static class MainDLL
    {
        // Constants
        public const int MinutenTakt = 5;
        public const int Anzahl_Tage_Kalender = 1200; // 3 years (last, current, next)
        public const int MaxKalender = 16; // 16 is standard
        public const string HALBAUTOMATIKMASCHINE = "XX**HALB**XX"; // DUMMY for Halbautomatik Maschine
        
        // Global variables
        public static int HALBAUTOMATIKKALENDER { get; set; } = 16;
        public static bool FLEXSCHICHT { get; set; } = false;
        public static int EndeDatumPlus { get; set; } = 0;
        public static int Shift_Model { get; set; } = 0;
        public static bool halbautomatik_berechnen { get; set; } = false;
        public static bool withKapaFaktorProMaschine { get; set; } = false;
        public static int KGruppeInitInterval { get; set; } = 60;
        public static DateTime LastKGruppeInit { get; set; } = DateTime.MinValue;
        
        // Global arrays
        public static double[,] SchichtStart { get; set; } = new double[4, 17]; // [1..3, 0..MaxKalender]
        public static int[,] ISchichtStart { get; set; } = new int[4, 17]; // [1..3, 0..MaxKalender]
        public static int[,] ISchichtStart2 { get; set; } = new int[4, 17]; // [1..3, 0..MaxKalender]
        public static int[,] SDauer { get; set; } = new int[4, 17]; // [1..3, 0..MaxKalender]
        public static int[,] SDauer2 { get; set; } = new int[4, 17]; // [1..3, 0..MaxKalender]
        public static TWerkskalender[] Werkskalender { get; set; } = new TWerkskalender[Anzahl_Tage_Kalender + 1];
        public static List<TMaschine> Maschine { get; set; } = new List<TMaschine>();
        
        // Database type from DBMain
        public static int INCLUDISDatabaseTyp { get; set; } = 1; // Default to SQL Server
        
        // Global variables for time tracking
        public static DateTime Jetzt { get { return DateTime.Now; } }
        public static DateTime N_o_w { get; set; } = DateTime.Now;
        
        // Global arrays for SPS data
        public static int[] StillstandNr { get; set; } = new int[DBMain.Max_ANZAHL + 1];
        public static int[] TPM_Signal { get; set; } = new int[DBMain.Max_ANZAHL + 1];
        
        // Barcode
        public static string Barcode1 { get; set; } = string.Empty;
        
        // Initialization
        static MainDLL()
        {
            // Initialize arrays
            for (int i = 0; i <= Anzahl_Tage_Kalender; i++)
            {
                Werkskalender[i] = new TWerkskalender();
            }
        }

        /// <summary>
        /// Convert DateTime to float (Delphi TDateTime format)
        /// </summary>
        public static double DateTimeToFloat(DateTime dateTime)
        {
            DateTime baseDate = new DateTime(1899, 12, 30); // Delphi date base
            TimeSpan span = dateTime - baseDate;
            return span.TotalDays;
        }

        /// <summary>
        /// Convert float (Delphi TDateTime) to DateTime
        /// </summary>
        public static DateTime ConvertFromFloat(double floatDate)
        {
            DateTime baseDate = new DateTime(1899, 12, 30); // Delphi date base
            return baseDate.AddDays(floatDate);
        }

        /// <summary>
        /// Get current date as float
        /// </summary>
        public static double JetztFloat { get { return DateTimeToFloat(DateTime.Now); } }

        /// <summary>
        /// Truncate date to day (remove time part)
        /// </summary>
        public static double Trunc(double dateValue)
        {
            return Math.Floor(dateValue);
        }

        /// <summary>
        /// Get fractional part of date
        /// </summary>
        public static double Frac(double dateValue)
        {
            return dateValue - Math.Floor(dateValue);
        }

        /// <summary>
        /// Convert DateTime to string
        /// </summary>
        public static string DateTimeToStr(DateTime dateTime)
        {
            return dateTime.ToString("dd.MM.yyyy HH:mm:ss");
        }

        /// <summary>
        /// Convert float date to string
        /// </summary>
        public static string FloatToStr(double value)
        {
            return value.ToString(CultureInfo.InvariantCulture);
        }

        /// <summary>
        /// Convert float to string with point as decimal separator
        /// </summary>
        public static string FloatToPunktString(double value)
        {
            return value.ToString("0.000000", CultureInfo.InvariantCulture);
        }

        /// <summary>
        /// Write message to log
        /// </summary>
        public static void SchreibeMeldung(string Meldung, int Modus)
        {
            try
            {
                string timestamp = DateTimeToStr(Jetzt);
                string message = timestamp + " : " + Meldung;
                
                // Log to console or file based on Modus
                switch (Modus)
                {
                    case 0: // Error
                        Console.Error.WriteLine("ERROR: " + message);
                        break;
                    case 1: // Warning
                        Console.WriteLine("WARNING: " + message);
                        break;
                    case 2: // Info
                        Console.WriteLine("INFO: " + message);
                        break;
                    case 3: // Debug
                        Console.WriteLine("DEBUG: " + message);
                        break;
                    case 4: // Trace
                        Console.WriteLine("TRACE: " + message);
                        break;
                    default:
                        Console.WriteLine(message);
                        break;
                }
                
                // Also write to log file
                string logPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "INCLService.log");
                File.AppendAllText(logPath, message + Environment.NewLine);
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine("Error writing log: " + ex.Message);
            }
        }

        /// <summary>
        /// Initialize EDP (Enterprise Data Processing)
        /// </summary>
        public static void EDPInit(CO_Query Q)
        {
            try
            {
                Q.Close();
                Q.SQL.Text = "Select EndeDatumPlus, Shift_Model, Halbautomatikkalender from Setup where nr =1";
                Q.Open();
                EndeDatumPlus = Q.FieldByName("EndeDatumPlus").AsInteger + 100;
                Shift_Model = Q.FieldByName("Shift_Model").AsInteger;
                HALBAUTOMATIKKALENDER = Q.FieldByName("Halbautomatikkalender").AsInteger;
                if (HALBAUTOMATIKKALENDER == 0)
                    HALBAUTOMATIKKALENDER = 16;
            }
            catch (Exception ex)
            {
                SchreibeMeldung("Error in EDPInit: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Initialize calendar data
        /// </summary>
        public static void K_Init(CO_Query Q, int days = 0)
        {
            K_Init(Q, 0, days);
        }

        /// <summary>
        /// Initialize calendar data with date range
        /// </summary>
        public static void K_Init(CO_Query Q, int days_back, int days_to)
        {
            try
            {
                EDPInit(Q);
                
                // Load calendar group data
                string sql = "Select GruppeNr, Schicht1, Schicht2, Schicht3 ";
                if (FLEXSCHICHT)
                    sql += ", startSchicht1, startSchicht2, startSchicht3 ";
                sql += " from KalenderGruppe where gruppenr <= " + MaxKalender + " order by GruppeNr";
                
                Q.SQL.Text = sql;
                Q.Open();
                
                while (!Q.EOF)
                {
                    int groupNr = Q.FieldByName("GruppeNr").AsInteger;
                    for (int i = 1; i <= 3; i++)
                    {
                        ISchichtStart[i, groupNr] = Q.FieldByName("Schicht" + i).AsInteger;
                        if (FLEXSCHICHT)
                            ISchichtStart2[i, groupNr] = Q.FieldByName("startSchicht" + i).AsInteger;
                    }
                    Q.Next();
                }
                
                // Calculate shift durations
                for (int i = 0; i <= MaxKalender; i++)
                {
                    if (Shift_Model != 2)
                    {
                        SDauer[1, i] = (int)(ISchichtStart[2, i] - ISchichtStart[1, i]);
                        SDauer[2, i] = (int)(ISchichtStart[3, i] - ISchichtStart[2, i]);
                        SDauer[3, i] = (int)(ISchichtStart[1, i] + 1440 - ISchichtStart[3, i]);
                        SDauer2[1, i] = (int)(ISchichtStart2[2, i] - ISchichtStart2[1, i]);
                        SDauer2[2, i] = (int)(ISchichtStart2[3, i] - ISchichtStart2[2, i]);
                        SDauer2[3, i] = (int)(ISchichtStart2[1, i] + 1440 - ISchichtStart2[3, i]);
                    }
                    else
                    {
                        SDauer[1, i] = (int)(ISchichtStart[2, i] - ISchichtStart[1, i]);
                        SDauer[2, i] = (int)(ISchichtStart[1, i] + 1440 - ISchichtStart[2, i]);
                        SDauer[3, i] = 0;
                    }
                    
                    SchichtStart[1, i] = ISchichtStart[1, i] / 1440.0;
                    SchichtStart[2, i] = ISchichtStart[2, i] / 1440.0;
                    SchichtStart[3, i] = ISchichtStart[3, i] / 1440.0;
                }
                
                // Load calendar data
                DateTime today = DateTime.Today;
                DateTime startDate = days_back == 0 ? new DateTime(today.Year - 1, 1, 1) : today.AddDays(-days_back);
                int heute = (int)DateTimeToFloat(startDate);
                
                Q.Close();
                if (days_to > 0)
                {
                    Q.SQL.Text = "Select * from Kalender where DatumInt >= " + heute + 
                        " AND datumint < " + (int)DateTimeToFloat(today.AddDays(days_to));
                }
                else
                {
                    Q.SQL.Text = "Select * from Kalender where DatumInt >= " + heute;
                }
                Q.SQL.Text += " order by DatumInt";
                Q.Open();
                
                int i = 1;
                while (i <= Anzahl_Tage_Kalender && !Q.EOF)
                {
                    Werkskalender[i].Tag = Q.FieldByName("DatumInt").AsInteger;
                    Werkskalender[i].Schicht[1, 0] = (short)Q.FieldByName("Schicht1").AsInteger;
                    Werkskalender[i].Schicht[2, 0] = (short)Q.FieldByName("Schicht2").AsInteger;
                    Werkskalender[i].Schicht[3, 0] = (short)Q.FieldByName("Schicht3").AsInteger;
                    
                    try
                    {
                        Werkskalender[i].Personal[1] = Q.FieldByName("Personal_S1").AsInteger;
                        Werkskalender[i].Personal[2] = Q.FieldByName("Personal_S2").AsInteger;
                        Werkskalender[i].Personal[3] = Q.FieldByName("Personal_S3").AsInteger;
                    }
                    catch (Exception) { }
                    
                    for (int j = 1; j <= MaxKalender; j++)
                    {
                        Werkskalender[i].Schicht[1, j] = (short)Q.FieldByName("Gruppe" + j + "_S1").AsInteger;
                        Werkskalender[i].Schicht[2, j] = (short)Q.FieldByName("Gruppe" + j + "_S2").AsInteger;
                        Werkskalender[i].Schicht[3, j] = (short)Q.FieldByName("Gruppe" + j + "_S3").AsInteger;
                    }
                    
                    for (int j = 0; j <= MaxKalender; j++)
                    {
                        Werkskalender[i].SchichtEnde[j] = (byte)Q.FieldByName("SchichtEnde_G" + j).AsInteger;
                    }
                    
                    Q.Next();
                    i++;
                }
            }
            catch (Exception ex)
            {
                SchreibeMeldung("Error in K_Init: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Initialize KGruppe (calendar groups)
        /// </summary>
        public static void KGruppe_Init(CO_Query Q)
        {
            try
            {
                // Load machine data
                Maschine.Clear();
                Q.SQL.Text = "Select MaschinenNr, KalenderGruppe, KapazitaetsFaktor from Maschine order by MaschinenNr";
                Q.Open();
                
                while (!Q.EOF)
                {
                    TMaschine maschine = new TMaschine();
                    maschine.MaschName = Q.FieldByName("MaschinenNr").AsString;
                    maschine.KalenderGruppe = Q.FieldByName("KalenderGruppe").AsInteger;
                    maschine.KapazitaetsFaktor = Q.FieldByName("KapazitaetsFaktor").AsFloat;
                    Maschine.Add(maschine);
                    Q.Next();
                }
            }
            catch (Exception ex)
            {
                SchreibeMeldung("Error in KGruppe_Init: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Refresh calendar groups
        /// </summary>
        public static void RefreshKGruppe(CO_Query Q)
        {
            KGruppe_Init(Q);
        }

        /// <summary>
        /// Get shift duration in minutes
        /// </summary>
        public static int GetSchichtDauer(int SchichtNR)
        {
            return GetSchichtDauer2(SchichtNR, 0);
        }

        /// <summary>
        /// Get shift duration for specific group
        /// </summary>
        public static int GetSchichtDauer2(int SchichtNR, int GruppeNr)
        {
            if (SchichtNR >= 1 && SchichtNR <= 3 && GruppeNr >= 0 && GruppeNr <= MaxKalender)
                return SDauer[SchichtNR, GruppeNr];
            return 0;
        }

        /// <summary>
        /// Get shift duration for specific date
        /// </summary>
        public static int GetSchichtDauerDatum(int KalGruppe, DateTime DT)
        {
            int dayIndex = (int)(DateTimeToFloat(DT) - DateTimeToFloat(DateTime.Today) + Anzahl_Tage_Kalender / 2);
            if (dayIndex >= 1 && dayIndex <= Anzahl_Tage_Kalender)
                return Werkskalender[dayIndex].SchichtEnde[KalGruppe];
            return 0;
        }

        /// <summary>
        /// Get shift duration for specific date (overload)
        /// </summary>
        public static int GetSchichtDauerDatum(DateTime DT)
        {
            return GetSchichtDauerDatum(0, DT);
        }

        /// <summary>
        /// Get shift start time as string
        /// </summary>
        public static string GetSchichtStartString(int KalGruppe, int SchichtNR)
        {
            int startMinutes = ISchichtStart[SchichtNR, KalGruppe];
            int hours = startMinutes / 60;
            int minutes = startMinutes % 60;
            return hours.ToString("00") + ":" + minutes.ToString("00");
        }

        /// <summary>
        /// Get shift start time as string (overload)
        /// </summary>
        public static string GetSchichtStartString(int SchichtNR)
        {
            return GetSchichtStartString(0, SchichtNR);
        }

        /// <summary>
        /// Get shift number for date and group
        /// </summary>
        public static int GetSchichtNr(int KalGruppe, DateTime DT)
        {
            int dayIndex = (int)(DateTimeToFloat(DT) - DateTimeToFloat(DateTime.Today) + Anzahl_Tage_Kalender / 2);
            if (dayIndex >= 1 && dayIndex <= Anzahl_Tage_Kalender)
            {
                DateTime dateOnly = DT.Date;
                TimeSpan timeOfDay = DT.TimeOfDay;
                int totalMinutes = (int)timeOfDay.TotalMinutes;
                
                // Check each shift
                for (int shift = 1; shift <= 3; shift++)
                {
                    int shiftStart = ISchichtStart[shift, KalGruppe];
                    int shiftEnd = shiftStart + SDauer[shift, KalGruppe];
                    
                    if (shiftEnd > 1440) // Wraps to next day
                    {
                        if (totalMinutes >= shiftStart || totalMinutes < (shiftEnd % 1440))
                            return shift;
                    }
                    else
                    {
                        if (totalMinutes >= shiftStart && totalMinutes < shiftEnd)
                            return shift;
                    }
                }
            }
            return 0;
        }

        /// <summary>
        /// Get shift number for date (overload)
        /// </summary>
        public static int GetSchichtNr(DateTime DT)
        {
            return GetSchichtNr(0, DT);
        }

        /// <summary>
        /// Get shift number for license and date
        /// </summary>
        public static int GetSchichtNr(string Lizenz, DateTime DT)
        {
            int group = GetGruppe(Lizenz);
            return GetSchichtNr(group, DT);
        }

        /// <summary>
        /// Get shift type
        /// </summary>
        public static string GetSchichtTyp(CO_Query q, int MaschNr, double D, int Schicht)
        {
            return ""; // Implementation would query database
        }

        /// <summary>
        /// Get shift start as float
        /// </summary>
        public static double GetSchichtStartFloat(int KalGruppe, int SchichtNR)
        {
            if (SchichtNR >= 1 && SchichtNR <= 3 && KalGruppe >= 0 && KalGruppe <= MaxKalender)
                return SchichtStart[SchichtNR, KalGruppe];
            return 0;
        }

        /// <summary>
        /// Get shift start as float (overload)
        /// </summary>
        public static double GetSchichtStartFloat(int SchichtNR)
        {
            return GetSchichtStartFloat(0, SchichtNR);
        }

        /// <summary>
        /// Get shift start as float (overload)
        /// </summary>
        public static double GetSchichtStartFloat(string Lizenz, int SchichtNR)
        {
            int group = GetGruppe(Lizenz);
            return GetSchichtStartFloat(group, SchichtNR);
        }

        /// <summary>
        /// Get shift start as integer
        /// </summary>
        public static int GetSchichtStartInt2(int KalGruppe, int SchichtNR)
        {
            if (SchichtNR >= 1 && SchichtNR <= 3 && KalGruppe >= 0 && KalGruppe <= MaxKalender)
                return ISchichtStart[SchichtNR, KalGruppe];
            return 0;
        }

        /// <summary>
        /// Get free work time per day
        /// </summary>
        public static DateTime GetFreeArbeitZeitproTag(string Lizenz, DateTime DT, int Sch)
        {
            return DT; // Simplified implementation
        }

        /// <summary>
        /// Check if moment is work-free
        /// </summary>
        public static bool isMomentArbeitsFrei(int KalGruppe, DateTime DT)
        {
            return false; // Simplified implementation
        }

        /// <summary>
        /// Check if date is work-free
        /// </summary>
        public static bool Arbeitsfrei(string Lizenz, double Datum)
        {
            return false; // Simplified implementation
        }

        /// <summary>
        /// Get end date for license
        /// </summary>
        public static double GetEndeDatumLizenz(string Lizenz, string AuftragsNr, double StartDatum, int RestZeit_Min, bool aHalbautomatik = false)
        {
            return StartDatum; // Simplified implementation
        }

        /// <summary>
        /// Get time in minutes
        /// </summary>
        public static int ZeitInMinuten(string Lizenz, DateTime Datum1, DateTime Datum2, bool aHalbautomatik = false)
        {
            return (int)(Datum2 - Datum1).TotalMinutes;
        }

        /// <summary>
        /// Get start date
        /// </summary>
        public static double GetSDatum(string Lizenz, string AuftragsNr, double EndeDatum, int Dauer_Min, bool aHalbautomatik = false)
        {
            return EndeDatum - (Dauer_Min / DBMain.TAGMINUTEN);
        }

        /// <summary>
        /// Get next work moment
        /// </summary>
        public static DateTime GetNextArbeitMoment(string Lizenz, DateTime DT, bool aHalbautomatik = false)
        {
            return DT.AddHours(1); // Simplified implementation
        }

        /// <summary>
        /// Get next work moment (overload)
        /// </summary>
        public static DateTime GetNextArbeitMoment(int KalGruppe, DateTime DT, bool aHalbautomatik = false)
        {
            return DT.AddHours(1); // Simplified implementation
        }

        /// <summary>
        /// Get previous work moment
        /// </summary>
        public static DateTime GetPrevArbeitMoment(string Lizenz, DateTime DT, bool aHalbautomatik = false)
        {
            return DT.AddHours(-1); // Simplified implementation
        }

        /// <summary>
        /// Get personnel count
        /// </summary>
        public static int GetPersonal(DateTime DT)
        {
            return 0; // Simplified implementation
        }

        /// <summary>
        /// Get group for license
        /// </summary>
        public static int GetGruppe(string Lizenz)
        {
            foreach (TMaschine maschine in Maschine)
            {
                if (maschine.MaschName == Lizenz)
                    return maschine.KalenderGruppe;
            }
            return 0;
        }

        /// <summary>
        /// Get machine for group
        /// </summary>
        public static TMaschine GetGruppenMaschine(string Lizenz)
        {
            foreach (TMaschine maschine in Maschine)
            {
                if (maschine.MaschName == Lizenz)
                    return maschine;
            }
            return null;
        }
    }
}
