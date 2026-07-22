namespace INCLService.CSharp.Models
{
    public class DatabaseConfig
    {
        public string DB_Server { get; set; } = "includis.world";
        public string InitialCatalog { get; set; } = "includis";
        public string DB_User { get; set; } = "INCLUDIS";
        public string DB_Pass { get; set; } = "comtas";
        public string Provider { get; set; } = string.Empty;
    }

    public class MainConfig
    {
        public string Home { get; set; } = "d:\\comtas\\";
    }

    public class AppConfig
    {
        public DatabaseConfig Database { get; set; } = new DatabaseConfig();
        public MainConfig Main { get; set; } = new MainConfig();
    }
}
