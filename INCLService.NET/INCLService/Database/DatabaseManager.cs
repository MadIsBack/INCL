using INCLService.Database;
using Microsoft.Extensions.Logging;

namespace INCLService.Database;

public class DatabaseManager
{
    private readonly CommonDB _db;
    private readonly ILogger<DatabaseManager> _logger;

    public DatabaseManager(CommonDB db, ILogger<DatabaseManager> logger)
    {
        _db = db;
        _logger = logger;
    }

    public bool CheckDatabaseConnection()
    {
        try
        {
            using (var connection = _db.CreateConnection())
            {
                connection.Open();
                return true;
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Datenbankverbindung fehlerhaft: {Message}", ex.Message);
            return false;
        }
    }

    public void InitializeDatabase()
    {
        _logger.LogInformation("Datenbank wird initialisiert");
        // Hier die Initialisierungslogik einfügen
    }

    public void CloseDatabase()
    {
        _logger.LogInformation("Datenbank wird geschlossen");
        // Hier die Schließlogik einfügen
    }
}
