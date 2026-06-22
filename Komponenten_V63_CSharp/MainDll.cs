using System;
using System.Collections.Generic;

namespace Komponenten_V63_CSharp
{
    public static class MainDll
    {
        public const string HALBAUTOMATIKMASCHINE = "XX**HALB**XX"; // DUMMY für Halbautomatik Maschine
        
        public static int HALBAUTOMATIKKALENDER = 16;
        public static bool FLEXSCHICHT = false;

        // Constants
        private const int MinutenTakt = 5;
        private const int Anzahl_Tage_Kalender = 1200; // 3 Jahre (letztes, laufendes, nächstes)
        private const int MaxKalender = 16;     // 16 ist Standard

        // Machine record
        public class TMaschine
        {
            public string MaschName { get; set; } = "";
            public int KalenderGruppe { get; set; } = 0;
            public double KapazitaetsFaktor { get; set; } = 1.0;
        }

        // Work calendar record
        private class TWerkskalender
        {
            public int Tag { get; set; } = 0;
            public short[,] Schicht { get; set; } = new short[4, MaxKalender + 1]; // [1..3, 0..MaxKalender]
            public byte[] SchichtEnde { get; set; } = new byte[MaxKalender + 1]; // [0..MaxKalender]
            public int[] Personal { get; set; } = new int[4]; // [1..3]
        }

        // Global arrays
        private static double[,] SchichtStart = new double[4, MaxKalender + 1]; // [1..3, 0..MaxKalender]
        private static int[,] ISchichtStart = new int[4, MaxKalender + 1]; // [1..3, 0..MaxKalender]
        private static int[,] ISchichtStart2 = new int[4, MaxKalender + 1]; // [1..3, 0..MaxKalender]
        private static int[,] SDauer = new int[4, MaxKalender + 1]; // [1..3, 0..MaxKalender]
        private static int[,] SDauer2 = new int[4, MaxKalender + 1]; // [1..3, 0..MaxKalender]

        private static TWerkskalender[] Werkskalender = new TWerkskalender[Anzahl_Tage_Kalender + 1];
        private static List<TMaschine> Maschine = new List<TMaschine>();
        
        public static int EndeDatumPlus { get; set; } = 0;
        public static int Shift_Model { get; set; } = 0;
        public static bool halbautomatik_berechnen { get; set; } = false;
        public static bool withKapaFaktorProMaschine { get; set; } = false;
        public static int KGruppeInitInterval { get; set; } = 0;
        public static DateTime LastKGruppeInit { get; set; } = DateTime.MinValue;

        static MainDll()
        {
            // Initialize arrays
            for (int i = 0; i <= Anzahl_Tage_Kalender; i++)
            {
                Werkskalender[i] = new TWerkskalender();
            }
        }

        // Form positioning
        public static void BringFormToMiddle(System.Windows.Forms.Form Form)
        {
            if (Form != null)
            {
                Form.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            }
        }

        // Date/Week calculations
        public static void DateToKw(DateTime Datum, out ushort KW, out ushort KWJahr)
        {
            KW = 0;
            KWJahr = 0;
            
            // Calculate week number and year
            var culture = System.Globalization.CultureInfo.CurrentCulture;
            KW = (ushort)culture.Calendar.GetWeekOfYear(Datum, System.Globalization.CalendarWeekRule.FirstFourDayWeek, DayOfWeek.Monday);
            KWJahr = (ushort)Datum.Year;
        }

        public static void KWToDate(ushort KW, ushort KWJahr, out DateTime Datum)
        {
            Datum = new DateTime(KWJahr, 1, 1);
            var culture = System.Globalization.CultureInfo.CurrentCulture;
            
            // Find the first day of the specified week
            DateTime firstDay = new DateTime(KWJahr, 1, 1);
            while (culture.Calendar.GetWeekOfYear(firstDay, System.Globalization.CalendarWeekRule.FirstFourDayWeek, DayOfWeek.Monday) < KW)
            {
                firstDay = firstDay.AddDays(1);
            }
            
            Datum = firstDay;
        }

        // Initialization methods
        public static void EDPInit(CO_Query Q)
        {
            Q.Close();
            Q.SQL = "Select EndeDatumPlus, Shift_Model, Halbautomatikkalender from Setup where nr =1";
            Q.Open();
            
            // In real implementation:
            // EndeDatumPlus = Q.FieldByName("EndeDatumPlus").AsInteger + 100;
            // Shift_Model = Q.FieldByName("Shift_Model").AsInteger;
            // HALBAUTOMATIKKALENDER = Q.FieldByName("Halbautomatikkalender").AsInteger;
            
            if (HALBAUTOMATIKKALENDER == 0)
                HALBAUTOMATIKKALENDER = 16;
        }

        public static void K_Init(CO_Query Q, int days = 0)
        {
            K_Init(Q, 0, days);
        }

        public static void K_Init(CO_Query Q, int days_back, int days_to)
        {
            EDPInit(Q);

            Q.SQL = "Select GruppeNr, Schicht1, Schicht2, Schicht3 ";
            if (FLEXSCHICHT)
                Q.SQL += ", startSchicht1, startSchicht2, startSchicht3 ";
            Q.SQL += " from KalenderGruppe where gruppenr <= " + MaxKalender + " order by GruppeNr";
            Q.Open();
            
            // In real implementation, we would process the query results
            // while not Q.EOF do
            // {
            //   for I := 1 to 3 do
            //   begin
            //     ISchichtStart[I, Q.FieldByName('GruppeNr').AsInteger] := Q.FieldByName('Schicht' + IntToStr(I)).AsInteger;
            //     if FLEXSCHICHT then
            //       ISchichtStart2[I, Q.FieldByName('GruppeNr').AsInteger] := Q.FieldByName('startSchicht' + IntToStr(I)).AsInteger;
            //   end;
            //   Q.Next;
            // }

            for (int I = 0; I <= MaxKalender; I++)
            {
                for (int J = 1; J <= 3; J++)
                {
                    SchichtStart[J, I] = ISchichtStart[J, I] / 1440.0;
                    SDauer[J, I] = ISchichtStart[J, I];
                    
                    if (FLEXSCHICHT)
                    {
                        ISchichtStart2[J, I] = ISchichtStart[J, I] + ISchichtStart2[J, I];
                        SDauer2[J, I] = ISchichtStart2[J, I] - ISchichtStart[J, I];
                    }
                    else
                    {
                        ISchichtStart2[J, I] = ISchichtStart[J, I];
                        SDauer2[J, I] = SDauer[J, I];
                    }
                }
            }

            // Load calendar data
            // This would be a complex implementation with database queries
            // For now, we'll leave it as a placeholder
        }

        public static void KGruppe_Init(CO_Query Q)
        {
            // Initialize machine groups
            Maschine.Clear();
            
            Q.SQL = "SELECT Lizenz, KalenderGruppe, KapazitaetsFaktor FROM Maschine WHERE Lizenz <> '' ORDER BY Lizenz";
            Q.Open();
            
            // In real implementation, we would read machine data
            // while not Q.EOF do
            // {
            //   TMaschine maschine = new TMaschine();
            //   maschine.MaschName = Q.FieldByName("Lizenz").AsString;
            //   maschine.KalenderGruppe = Q.FieldByName("KalenderGruppe").AsInteger;
            //   maschine.KapazitaetsFaktor = Q.FieldByName("KapazitaetsFaktor").AsFloat;
            //   Maschine.Add(maschine);
            //   Q.Next;
            // }
        }

        public static void RefreshKGruppe(CO_Query Q)
        {
            // Refresh machine group data
            KGruppe_Init(Q);
        }

        // Shift duration methods
        public static int GetSchichtDauer(int SchichtNR)
        {
            return SDauer[SchichtNR, 0];
        }

        public static int GetSchichtDauer2(int SchichtNR, int GruppeNr)
        {
            return SDauer2[SchichtNR, GruppeNr];
        }

        public static int GetSchichtDauerDatum(int KalGruppe, DateTime DT)
        {
            return GetSchichtDauerDatum(DT);
        }

        public static int GetSchichtDauerDatum(DateTime DT)
        {
            // Calculate shift duration for specific date
            return 0;
        }

        // Shift start methods
        public static string GetSchichtStartString(int KalGruppe, int SchichtNR)
        {
            return GetSchichtStartString(SchichtNR);
        }

        public static string GetSchichtStartString(int SchichtNR)
        {
            // Return shift start time as string
            return "";
        }

        // Shift number methods
        public static int GetSchichtNr(int KalGruppe, DateTime DT)
        {
            return GetSchichtNr(DT);
        }

        public static int GetSchichtNr(DateTime DT)
        {
            // Calculate current shift number
            return 0;
        }

        public static int GetSchichtNr(string Lizenz, DateTime DT)
        {
            // Get shift number for specific machine
            return 0;
        }

        public static string GetSchichtTyp(CO_Query q, int MaschNr, double D, int Schicht)
        {
            // Get shift type
            return "";
        }

        // Shift start float methods
        public static double GetSchichtStartFloat(int KalGruppe, int SchichtNR)
        {
            return GetSchichtStartFloat(SchichtNR);
        }

        public static double GetSchichtStartFloat(int SchichtNR)
        {
            return SchichtStart[SchichtNR, 0];
        }

        public static double GetSchichtStartFloat(string Lizenz, int SchichtNR)
        {
            // Get shift start for specific machine
            return 0.0;
        }

        public static int GetSchichtStartInt2(int KalGruppe, int SchichtNR)
        {
            return ISchichtStart2[SchichtNR, KalGruppe];
        }

        // Working time calculation methods
        public static DateTime GetFreeArbeitZeitproTag(string Lizenz, DateTime DT, int Sch)
        {
            return DT;
        }

        public static bool isMomentArbeitsFrei(int KalGruppe, DateTime DT)
        {
            return false;
        }

        public static bool Arbeitsfrei(string Lizenz, double Datum)
        {
            return false;
        }

        public static double GetEndeDatumLizenz(string Lizenz, string AuftragsNr, double StartDatum, int RestZeit_Min, bool aHalbautomatik = false)
        {
            return StartDatum;
        }

        public static int ZeitInMinuten(string Lizenz, DateTime Datum1, DateTime Datum2, bool aHalbautomatik = false)
        {
            return 0;
        }

        public static double GetSDatum(string Lizenz, string AuftragsNr, double EndeDatum, int Dauer_Min, bool aHalbautomatik = false)
        {
            return EndeDatum;
        }

        public static DateTime GetNextArbeitMoment(string Lizenz, DateTime DT, bool aHalbautomatik = false)
        {
            return DT;
        }

        public static DateTime GetNextArbeitMoment(int KalGruppe, DateTime DT, bool aHalbautomatik = false)
        {
            return DT;
        }

        public static DateTime GetPrevArbeitMoment(string Lizenz, DateTime DT, bool aHalbautomatik = false)
        {
            return DT;
        }

        // Personnel methods
        public static int GetPersonal(DateTime DT)
        {
            return 0;
        }

        // Group methods
        public static int GetGruppe(string Lizenz)
        {
            // Get calendar group for machine
            foreach (var maschine in Maschine)
            {
                if (maschine.MaschName == Lizenz)
                    return maschine.KalenderGruppe;
            }
            return 0;
        }

        public static TMaschine GetGruppenMaschine(string Lizenz)
        {
            // Get machine by license
            foreach (var maschine in Maschine)
            {
                if (maschine.MaschName == Lizenz)
                    return maschine;
            }
            return null;
        }
    }
}
