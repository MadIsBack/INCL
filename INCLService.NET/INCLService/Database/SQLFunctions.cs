using INCLService.Database;
using Microsoft.Extensions.Logging;
using System.Data;
using System.Data.Common;

namespace INCLService.Database;

public class SQLFunctions
{
    private readonly ILogger<SQLFunctions> _logger;

    public SQLFunctions(ILogger<SQLFunctions> logger)
    {
        _logger = logger;
    }

    public bool CheckDatabaseConnection(CommonDB db)
    {
        try
        {
            using (var connection = db.CreateConnection())
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

    public bool SQL_Get(CommonDB db, string sqlStr)
    {
        try
        {
            using (var connection = db.CreateConnection())
            {
                connection.Open();
                using (var command = connection.CreateCommand())
                {
                    command.CommandText = sqlStr;
                    using (var reader = command.ExecuteReader())
                    {
                        return reader.HasRows;
                    }
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Fehler bei SQL_Get: {Message}", ex.Message);
            return false;
        }
    }

    public int SQL_Insert(CommonDB db, string sqlStr)
    {
        try
        {
            using (var connection = db.CreateConnection())
            {
                connection.Open();
                using (var command = connection.CreateCommand())
                {
                    command.CommandText = sqlStr;
                    return command.ExecuteNonQuery();
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Fehler bei SQL_Insert: {Message}", ex.Message);
            return -1;
        }
    }

    public bool SQLGetBool(CommonDB db, string table, string field, string value)
    {
        string sqlStr = $