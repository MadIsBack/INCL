using INCLUDIS.Utils.CommonDB;
using Microsoft.Extensions.Logging;
using System;
using System.Data;

namespace INCLService.CSharp.Utilities
{
    /// <summary>
    /// SQL-Hilfsfunktionen
    /// Äquivalent zu SQL_fuc.pas in Delphi
    /// </summary>
    public class SQLHelper : IDisposable
    {
        private readonly ILogger<SQLHelper> _logger;
        private readonly CommonDB _database;
        
        // Tag-Konstanten für Logging (wie in Delphi)
        public const int TAG_MAIN = 0;
        public const int TAG_ADDON = 1;
        public const int TAG_SHIFT = 2;
        
        public SQLHelper(ILogger<SQLHelper> logger, CommonDB database)
        {
            _logger = logger;
            _database = database ?? throw new ArgumentNullException(nameof(database));
        }
        
        /// <summary>
        /// Behandelt Datenbankfehler
        /// Äquivalent zu Handle_DB_Error in Delphi
        /// </summary>
        public bool HandleDBError(string errorMessage)
        {
            try
            {
                // Prüfen auf ORA-01000 (Max Oper Cursors überschritten)
                if (errorMessage != null && errorMessage.ToUpper().Contains("ORA-01000"))
                {
                    return RestartDatabase();
                }
                
                return false;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in HandleDBError");
                return false;
            }
        }
        
        /// <summary>
        /// Startet die Datenbankverbindung neu
        /// Äquivalent zu RestartDatabase in Delphi
        /// </summary>
        public bool RestartDatabase()
        {
            try
            {
                if (_database.Connected)
                {
                    _database.Connected = false;
                }
                
                _database.Connected = true;
                return _database.Connected;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error restarting database");
                return false;
            }
        }
        
        /// <summary>
        /// Führt eine SQL-Abfrage aus und gibt zurück, ob Ergebnisse vorhanden sind
        /// Äquivalent zu SQL_Get in Delphi
        /// </summary>
        public bool SQLGet(CommonReader reader, string sql, int tag = TAG_MAIN)
        {
            try
            {
                if (reader != null)
                {
                    reader.Close();
                }
                
                reader = _database.ExecuteReader(sql);
                
                if (reader != null && reader.HasRows)
                {
                    return true;
                }
                
                return false;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "[{Tag}] Exception. SQL: {SQL}", GetTagName(tag), sql);
                
                if (HandleDBError(ex.Message))
                {
                    try
                    {
                        reader = _database.ExecuteReader(sql);
                        return reader != null && reader.HasRows;
                    }
                    catch (Exception ex2)
                    {
                        _logger.LogError(ex2, "[{Tag}] Retry failed for SQL: {SQL}", GetTagName(tag), sql);
                    }
                }
                
                return false;
            }
        }
        
        /// <summary>
        /// Führt eine SQL-Insert/Update/Delete-Abfrage aus
        /// Äquivalent zu SQL_Insert in Delphi
        /// </summary>
        public int SQLInsert(string sql, int tag = TAG_MAIN)
        {
            try
            {
                using (var command = _database.CreateCommand(sql))
                {
                    return command.ExecuteNonQuery();
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "[{Tag}] Exception. SQL: {SQL}", GetTagName(tag), sql);
                
                if (HandleDBError(ex.Message))
                {
                    try
                    {
                        using (var command = _database.CreateCommand(sql))
                        {
                            return command.ExecuteNonQuery();
                        }
                    }
                    catch (Exception ex2)
                    {
                        _logger.LogError(ex2, "[{Tag}] Retry failed for SQL: {SQL}", GetTagName(tag), sql);
                    }
                }
                
                return -1;
            }
        }
        
        /// <summary>
        /// Führt eine SQL-Abfrage aus und gibt zurück, ob Ergebnisse vorhanden sind
        /// Äquivalent zu SQLGetBool in Delphi
        /// </summary>
        public bool SQLGetBool(string table, string field, string value)
        {
            try
            {
                string sql = $"SELECT * FROM {table} WHERE {field}='{value}'";
                using (var reader = _database.ExecuteReader(sql))
                {
                    return reader != null && reader.HasRows;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in SQLGetBool");
                return false;
            }
        }
        
        /// <summary>
        /// Führt eine SQL-Abfrage mit zwei Bedingungen aus
        /// Äquivalent zu SQL2GetBool in Delphi
        /// </summary>
        public bool SQL2GetBool(string table, string field1, string value1, string field2, string value2)
        {
            try
            {
                string sql;
                
                if (string.IsNullOrEmpty(value1) && string.IsNullOrEmpty(value2))
                {
                    sql = $"SELECT * FROM {table}";
                }
                else if (!string.IsNullOrEmpty(value1) && string.IsNullOrEmpty(value2))
                {
                    sql = $"SELECT * FROM {table} WHERE {field1}='{value1}'";
                }
                else if (string.IsNullOrEmpty(value1) && !string.IsNullOrEmpty(value2))
                {
                    sql = $"SELECT * FROM {table} WHERE {field2}='{value2}'";
                }
                else
                {
                    sql = $"SELECT * FROM {table} WHERE ({field1}='{value1}') AND ({field2}='{value2}')";
                }
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    return reader != null && reader.HasRows;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in SQL2GetBool");
                return false;
            }
        }
        
        /// <summary>
        /// Führt eine SQL-Abfrage mit drei Bedingungen aus
        /// Äquivalent zu SQL3GetBool in Delphi
        /// </summary>
        public bool SQL3GetBool(string table, string field1, string value1, 
                                string field2, string value2, 
                                string field3, string value3)
        {
            try
            {
                string sql;
                
                if (string.IsNullOrEmpty(value1) && string.IsNullOrEmpty(value2))
                {
                    sql = $"SELECT * FROM {table}";
                }
                else if (!string.IsNullOrEmpty(value1) && string.IsNullOrEmpty(value2))
                {
                    sql = $"SELECT * FROM {table} WHERE {field1}='{value1}'";
                }
                else if (string.IsNullOrEmpty(value1) && !string.IsNullOrEmpty(value2))
                {
                    sql = $"SELECT * FROM {table} WHERE {field2}='{value2}'";
                }
                else
                {
                    sql = $"SELECT * FROM {table} WHERE ({field1}='{value1}') AND ({field2}='{value2}') AND ({field3}='{value3}')";
                }
                
                using (var reader = _database.ExecuteReader(sql))
                {
                    return reader != null && reader.HasRows;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in SQL3GetBool");
                return false;
            }
        }
        
        /// <summary>
        /// Führt eine SQL-Abfrage aus und gibt die Anzahl der Ergebnisse zurück
        /// Äquivalent zu SQLGet in Delphi (mit Ergebnis-Parameter)
        /// </summary>
        public int SQLGetCount(string table, string field, string value)
        {
            try
            {
                string sql = $"SELECT COUNT(*) as CNT FROM {table} WHERE {field}='{value}'";
                using (var reader = _database.ExecuteReader(sql))
                {
                    if (reader != null && reader.Read())
                    {
                        return reader.GetInt32(reader.GetOrdinal("CNT"));
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
        
        /// <summary>
        /// Aktualisiert einen Datensatz
        /// Äquivalent zu UpdateSQL in Delphi
        /// </summary>
        public void UpdateSQL(string table, string updateField, string updateValue, 
                             string whereField, string whereValue)
        {
            try
            {
                string sql = $"UPDATE {table} SET {updateField}='{updateValue}' WHERE {whereField}='{whereValue}'";
                using (var command = _database.CreateCommand(sql))
                {
                    command.ExecuteNonQuery();
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in UpdateSQL");
            }
        }
        
        /// <summary>
        /// Aktualisiert einen Datensatz mit zwei Bedingungen
        /// Äquivalent zu Update2SQL in Delphi
        /// </summary>
        public void Update2SQL(string table, string updateField, string updateValue,
                               string whereField1, string whereValue1,
                               string whereField2, string whereValue2)
        {
            try
            {
                string sql = $"UPDATE {table} SET {updateField}='{updateValue}' WHERE {whereField1}='{whereValue1}' AND {whereField2}='{whereValue2}'";
                using (var command = _database.CreateCommand(sql))
                {
                    command.ExecuteNonQuery();
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in Update2SQL");
            }
        }
        
        /// <summary>
        /// Löscht einen Datensatz
        /// Äquivalent zu DeleteSQL in Delphi
        /// </summary>
        public void DeleteSQL(string table, string field, string value)
        {
            try
            {
                string sql = $"DELETE FROM {table} WHERE {field}='{value}'";
                using (var command = _database.CreateCommand(sql))
                {
                    command.ExecuteNonQuery();
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in DeleteSQL");
            }
        }
        
        /// <summary>
        /// Gibt den Tag-Namen zurück
        /// </summary>
        private string GetTagName(int tag)
        {
            return tag switch
            {
                TAG_MAIN => "(MAIN)",
                TAG_ADDON => "(ADDON)",
                TAG_SHIFT => "(SHIFT)",
                _ => "(UNKNOWN)"
            };
        }
        
        /// <summary>
        /// Konvertiert einen Double-Wert in einen String mit Punkt als Dezimaltrennzeichen
        /// Äquivalent zu FloatToStr_Punkt in Delphi
        /// </summary>
        public string FloatToStrPunkt(double value)
        {
            return value.ToString("0.00", System.Globalization.CultureInfo.InvariantCulture);
        }
        
        /// <summary>
        /// Konvertiert einen Double-Wert in einen String mit angegebenem Format
        /// Äquivalent zu FloatToStrF2 in Delphi
        /// </summary>
        public string FloatToStrF2(double value, int precision = 2)
        {
            return value.ToString("F" + precision, System.Globalization.CultureInfo.InvariantCulture);
        }
        
        public void Dispose()
        {
            // Nothing to dispose explicitly
        }
    }
}
