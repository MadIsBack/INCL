namespace INCLUDIS.INCLServer.Cs
{
    /// <summary>
    /// Konfigurationsklasse für den INCLServer.
    /// Wird aus appsettings.json deserialisiert.
    /// </summary>
    public class INCLServerConfig
    {
        public string DBUser { get; set; } = "includis";
        public string DBPass { get; set; } = "comtas";
        public string DBServer { get; set; } = "db";
        public string DBInitialCatalog { get; set; } = "includis";
        public string DBProvider { get; set; } = "";
        public string INCLUDIS_HOME { get; set; } = "D:\\comtas\\";
        public LogSettings LogSettings { get; set; } = new LogSettings();
        public ThreadSettings ThreadSettings { get; set; } = new ThreadSettings();
    }

    /// <summary>
    /// Einstellungen für das Logging.
    /// </summary>
    public class LogSettings
    {
        public int MaxFileSizeMB { get; set; } = 4;
        public string LogDirectory { get; set; } = "LOG";
        public int RetainedFileCount { get; set; } = 7;
    }

    /// <summary>
    /// Einstellungen für die Thread-Intervalle.
    /// </summary>
    public class ThreadSettings
    {
        public ServiceInterval SchichtService { get; set; } = new ServiceInterval();
        public ServiceInterval ZusatzService { get; set; } = new ServiceInterval();
        public ServiceInterval SignalLogService { get; set; } = new ServiceInterval();
        public ServiceInterval DBBackupService { get; set; } = new ServiceInterval();
    }

    /// <summary>
    /// Intervall-Einstellungen für einen Service.
    /// </summary>
    public class ServiceInterval
    {
        public int IntervalSeconds { get; set; } = 60;
    }
}
