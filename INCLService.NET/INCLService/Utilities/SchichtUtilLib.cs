namespace INCLService.Utilities;

public static class SchichtUtilLib
{
    public static int GetSchichtNr(double dateTime)
    {
        double frac = dateTime - Math.Truncate(dateTime);
        
        // Standard: 3 Schichten
        if (frac < 0.375) // Schicht 1: 00:00 - 09:00
            return 1;
        else if (frac < 0.625) // Schicht 2: 09:00 - 15:00
            return 2;
        else // Schicht 3: 15:00 - 24:00
            return 3;
    }

    public static double GetSchichtStartFloat(int schicht)
    {
        switch (schicht)
        {
            case 1: return 0.0;
            case 2: return 0.375; // 09:00
            case 3: return 0.625; // 15:00
            default: return 0.0;
        }
    }

    public static int GetSchichtDauer(int schicht)
    {
        switch (schicht)
        {
            case 1: return 540; // 9 Stunden in Minuten
            case 2: return 360; // 6 Stunden in Minuten
            case 3: return 540; // 9 Stunden in Minuten
            default: return 1440; // 24 Stunden in Minuten
        }
    }

    public static double GetSchichtDauerDatum(int kalGruppe, double dateTime)
    {
        return GetSchichtDauer(GetSchichtNr(dateTime));
    }

    public static string GetKWStr(double dateTime)
    {
        var date = DateTime.FromOADate(dateTime);
        var culture = System.Globalization.CultureInfo.CurrentCulture;
        return culture.Calendar.GetWeekOfYear(date, System.Globalization.CalendarWeekRule.FirstDay, DayOfWeek.Monday).ToString();
    }

    public static string GetMonatStr(double dateTime)
    {
        return DateTime.FromOADate(dateTime).Month.ToString();
    }

    public static string GetSchichtTyp(int maschnr, double kommt, int schicht)
    {
        return "-";
    }

    public static double TTT_GetTPMSchichtZeit(int schicht, double datum)
    {
        return GetSchichtDauer(schicht) / 1440.0;
    }
}
