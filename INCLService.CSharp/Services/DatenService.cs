using INCLUDIS.Utils.CommonDB;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System;

namespace INCLService.CSharp.Services
{
    /// <summary>
    /// Daten-Service - Zentraler Datenzugriff
    /// Äquivalent zu TDaten in DatenM.pas
    /// </summary>
    public class DatenService : IDisposable
    {
        private readonly ILogger<DatenService> _logger;
        private readonly IConfiguration _configuration;
        
        // Datenbankverbindung
        private CommonDB _database;
        
        // Query-Objekte (Äquivalent zu TCO_Query in Delphi)
        public CommonReader QSuch { get; private set; }
        public CommonCommand QUpdate { get; private set; }
        public CommonReader QWerte { get; private set; }
        public CommonReader QCount { get; private set; }
        public CommonCommand QCreateDB { get; private set; }
        public CommonReader QSuch2 { get; private set; }
        public CommonReader QSuch4 { get; private set; }
        public CommonReader QIstwert { get; private set; }
        public CommonReader QDurchlauf { get; private set; }
        public CommonReader QTMP { get; private set; }
        public CommonReader QSuch5 { get; private set; }
        public CommonReader QSuch3 { get; private set; }
        public CommonCommand QUpdateS { get; private set; }
        public CommonCommand QLog { get; private set; }
        public CommonReader QSetupPar { get; private set; }
        
        // Verbindungsstatus
        public bool Conn { get; private set; } = false;
        
        public CommonDB Database => _database;
        
        public DatenService(ILogger<DatenService> logger, IConfiguration configuration)
        {
            _logger = logger;
            _configuration = configuration;
            
            InitializeDatabase();
            InitializeQueries();
        }
        
        private void InitializeDatabase()
        {
            try
            {
                var dbConfig = new {
                    DB_Server = _configuration["Database:DB_Server"],
                    InitialCatalog = _configuration["Database:InitialCatalog"],
                    DB_User = _configuration["Database:DB_User"],
                    DB_Pass = _configuration["Database:DB_Pass"],
                    Provider = _configuration["Database:Provider"]
                };
                
                _database = new CommonDB
                {
                    UserName = dbConfig.DB_User,
                    Password = dbConfig.DB_Pass,
                    Server = dbConfig.DB_Server,
                    InitialCatalog = dbConfig.InitialCatalog,
                    SqlProvider = dbConfig.Provider
                };
                
                _logger.LogInformation("DatenService database initialized");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error initializing DatenService database");
            }
        }
        
        private void InitializeQueries()
        {
            try
            {
                // Alle Query-Objekte initialisieren
                // In C# erstellen wir die Reader/Command-Objekte bei Bedarf
                // Hier werden nur die Properties initialisiert
                _logger.LogInformation("DatenService queries initialized");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error initializing DatenService queries");
            }
        }
        
        /// <summary>
        /// Stellt die Datenbankverbindung her
        /// </summary>
        public bool Connect()
        {
            try
            {
                if (_database != null)
                {
                    _database.Connected = true;
                    Conn = _database.Connected;
                }
                
                _logger.LogInformation("DatenService connected: {Connected}", Conn);
                return Conn;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error connecting DatenService");
                Conn = false;
                return false;
            }
        }
        
        /// <summary>
        /// Trennt die Datenbankverbindung
        /// </summary>
        public void Disconnect()
        {
            try
            {
                if (_database != null && _database.Connected)
                {
                    _database.Connected = false;
                }
                Conn = false;
                _logger.LogInformation("DatenService disconnected");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error disconnecting DatenService");
            }
        }
        
        /// <summary>
        /// Erstellt einen neuen CommonReader für eine SQL-Abfrage
        /// </summary>
        public CommonReader CreateReader(string sql)
        {
            if (_database == null || !_database.Connected)
            {
                Connect();
            }
            
            return _database.ExecuteReader(sql);
        }
        
        /// <summary>
        /// Erstellt einen neuen CommonCommand für eine SQL-Abfrage
        /// </summary>
        public CommonCommand CreateCommand(string sql)
        {
            if (_database == null || !_database.Connected)
            {
                Connect();
            }
            
            return _database.CreateCommand(sql);
        }
        
        /// <summary>
        /// Führt eine SQL-Abfrage aus und gibt einen Reader zurück
        /// Äquivalent zu SQLGet in Delphi
        /// </summary>
        public CommonReader SQLGet(string table, string field, string value, bool exactMatch = true)
        {
            try
            {
                string sql = exactMatch 
                    ? $"SELECT * FROM {table} WHERE {field} = '{value}'"
                    : $"SELECT * FROM {table} WHERE {field} LIKE '%{value}%' ";
                
                return CreateReader(sql);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in SQLGet");
                return null;
            }
        }
        
        /// <summary>
        /// Führt eine SQL-Abfrage aus und gibt die Anzahl der Ergebnisse zurück
        /// </summary>
        public int SQLGetCount(string table, string field, string value)
        {
            try
            {
                using (var reader = SQLGet(table, field, value, true))
                {
                    if (reader != null)
                    {
                        int count = 0;
                        while (reader.Read())
                        {
                            count++;
                        }
                        return count;
                    }
                    return 0;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in SQLGetCount");
                return 0;
            }
        }
        
        public void Dispose()
        {
            Disconnect();
            
            // Reader/Command-Objekte müssen nicht explizit disposed werden,
            // da sie von CommonDB verwaltet werden
            
            _database = null;
        }
    }
}
