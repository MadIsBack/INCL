namespace INCLService.Config;

public class DatabaseConfig
{
    public string? Provider { get; set; }
    public string? ConnectionString { get; set; }
}

public class ShiftSettings
{
    public int ShiftModel { get; set; } = 1;
    public double Shift1Start { get; set; } = 0.0;
    public double Shift2Start { get; set; } = 0.375;
    public double Shift3Start { get; set; } = 0.625;
    public int MaxShiftTime { get; set; } = 1440;
}

public class ServiceSettings
{
    public int RecalculationDays { get; set; } = 30;
    public int StillstaendeSchicht { get; set; } = 7;
    public int RecalculationTime { get; set; } = 0;
    public bool SPC { get; set; } = false;
    public bool Metall { get; set; } = false;
    public bool StillstandWerksplanung { get; set; } = false;
}
