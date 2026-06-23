using System;
using System.Data;
using INCLUDIS.Utils.CommonDB;

namespace INCLService_Sharp
{
    /// <summary>
    /// Data module for database operations - 1:1 translation from DatenM.pas
    /// </summary>
    public class DatenM : IDisposable
    {
        public CommonDB Database { get; set; }
        public CommonCommand qSuch { get; set; }
        public CommonCommand qUpdate { get; set; }
        public CommonCommand qWerte { get; set; }
        public CommonCommand qCount { get; set; }
        public CommonCommand qCreateDB { get; set; }
        public CommonCommand qSuch2 { get; set; }
        public CommonCommand qSuch4 { get; set; }
        public CommonCommand qIstwert { get; set; }
        public CommonCommand qDurchlauf { get; set; }
        public CommonCommand qTMP { get; set; }
        public CommonCommand qSuch5 { get; set; }
        public CommonCommand qSuch3 { get; set; }
        public CommonCommand qUpdateS { get; set; }
        public CommonCommand qLog { get; set; }
        public CommonCommand qSetupPar { get; set; }

        public bool Conn { get; set; }

        public DatenM()
        {
            try
            {
                Database = new CommonDB();
                
                qSuch = new CommonCommand(Database);
                qUpdate = new CommonCommand(Database);
                qWerte = new CommonCommand(Database);
                qCount = new CommonCommand(Database);
                qCreateDB = new CommonCommand(Database);
                qSuch2 = new CommonCommand(Database);
                qSuch4 = new CommonCommand(Database);
                qIstwert = new CommonCommand(Database);
                qDurchlauf = new CommonCommand(Database);
                qTMP = new CommonCommand(Database);
                qSuch5 = new CommonCommand(Database);
                qSuch3 = new CommonCommand(Database);
                qUpdateS = new CommonCommand(Database);
                qLog = new CommonCommand(Database);
                qSetupPar = new CommonCommand(Database);
                
                Conn = true;
            }
            catch (Exception ex)
            {
                INCLService.WriteMessage("Error initializing DatenM: " + ex.Message, 0);
                Conn = false;
            }
        }

        /// <summary>
        /// Execute a query and return the number of records - 1:1 translation from Delphi SQLGet
        /// </summary>
        public int SQLGet(CommonCommand query, string tableName, string fieldName, string keyValue, bool openQuery)
        {
            try
            {
                string sql = "SELECT * FROM " + tableName + " WHERE " + fieldName + " = '" + keyValue + "'" + S7Main.IgnorePendingStatement;
                
                if (openQuery)
                {
                    query.CommandText = sql;
                    query.ExecuteReader();
                    return query.RecordsAffected;
                }
                else
                {
                    using (var reader = Database.GetReader(sql))
                    {
                        if (reader.Read())
                        {
                            return 1;
                        }
                        return 0;
                    }
                }
            }
            catch (Exception ex)
            {
                INCLService.WriteMessage("Error in SQLGet: " + ex.Message, 0);
                return -1;
            }
        }

        /// <summary>
        /// Execute a query and return a boolean value - 1:1 translation from Delphi SQLGetBool
        /// </summary>
        public bool SQLGetBool(CommonCommand query, string tableName, string fieldName, string keyValue)
        {
            try
            {
                string sql = "SELECT " + fieldName + " FROM " + tableName + " WHERE Nr = '" + keyValue + "'" + S7Main.IgnorePendingStatement;
                var result = Database.ExecuteScalar(sql);
                
                if (result != null && result != DBNull.Value)
                {
                    return Convert.ToInt32(result) == 1;
                }
                return false;
            }
            catch (Exception ex)
            {
                INCLService.WriteMessage("Error in SQLGetBool: " + ex.Message, 0);
                return false;
            }
        }

        /// <summary>
        /// Execute an INSERT, UPDATE, or DELETE statement - 1:1 translation from Delphi SQL_Insert
        /// </summary>
        public int SQL_Insert(CommonCommand query, string sqlStatement)
        {
            try
            {
                query.CommandText = sqlStatement;
                return query.ExecuteNonQuery();
            }
            catch (Exception ex)
            {
                INCLService.WriteMessage("Error in SQL_Insert: " + ex.Message, 0);
                return -1;
            }
        }

        /// <summary>
        /// Get a field value as integer from the current query result
        /// </summary>
        public int FieldByNameAsInteger(CommonCommand query, string fieldName)
        {
            try
            {
                if (query.CurrentReader != null && !query.CurrentReader.IsDBNull(fieldName))
                {
                    return query.CurrentReader.GetInt32(fieldName);
                }
                return 0;
            }
            catch (Exception ex)
            {
                INCLService.WriteMessage("Error in FieldByNameAsInteger: " + ex.Message, 0);
                return 0;
            }
        }

        /// <summary>
        /// Get a field value as string from the current query result
        /// </summary>
        public string FieldByNameAsString(CommonCommand query, string fieldName)
        {
            try
            {
                if (query.CurrentReader != null && !query.CurrentReader.IsDBNull(fieldName))
                {
                    return query.CurrentReader.GetString(fieldName);
                }
                return string.Empty;
            }
            catch (Exception ex)
            {
                INCLService.WriteMessage("Error in FieldByNameAsString: " + ex.Message, 0);
                return string.Empty;
            }
        }

        /// <summary>
        /// Get a field value as double from the current query result
        /// </summary>
        public double FieldByNameAsDouble(CommonCommand query, string fieldName)
        {
            try
            {
                if (query.CurrentReader != null && !query.CurrentReader.IsDBNull(fieldName))
                {
                    return query.CurrentReader.GetDouble(fieldName);
                }
                return 0.0;
            }
            catch (Exception ex)
            {
                INCLService.WriteMessage("Error in FieldByNameAsDouble: " + ex.Message, 0);
                return 0.0;
            }
        }

        /// <summary>
        /// Get a field value as boolean from the current query result
        /// </summary>
        public bool FieldByNameAsBoolean(CommonCommand query, string fieldName)
        {
            try
            {
                if (query.CurrentReader != null && !query.CurrentReader.IsDBNull(fieldName))
                {
                    return query.CurrentReader.GetInt32(fieldName) == 1;
                }
                return false;
            }
            catch (Exception ex)
            {
                INCLService.WriteMessage("Error in FieldByNameAsBoolean: " + ex.Message, 0);
                return false;
            }
        }

        /// <summary>
        /// Get a field value as DateTime from the current query result
        /// </summary>
        public DateTime FieldByNameAsDateTime(CommonCommand query, string fieldName)
        {
            try
            {
                if (query.CurrentReader != null && !query.CurrentReader.IsDBNull(fieldName))
                {
                    return query.CurrentReader.GetDateTime(fieldName);
                }
                return DateTime.MinValue;
            }
            catch (Exception ex)
            {
                INCLService.WriteMessage("Error in FieldByNameAsDateTime: " + ex.Message, 0);
                return DateTime.MinValue;
            }
        }

        public void Dispose()
        {
            try
            {
                qSuch?.Dispose();
                qUpdate?.Dispose();
                qWerte?.Dispose();
                qCount?.Dispose();
                qCreateDB?.Dispose();
                qSuch2?.Dispose();
                qSuch4?.Dispose();
                qIstwert?.Dispose();
                qDurchlauf?.Dispose();
                qTMP?.Dispose();
                qSuch5?.Dispose();
                qSuch3?.Dispose();
                qUpdateS?.Dispose();
                qLog?.Dispose();
                qSetupPar?.Dispose();
                Database?.Dispose();
            }
            catch (Exception ex)
            {
                INCLService.WriteMessage("Error disposing DatenM: " + ex.Message, 0);
            }
        }
    }

    /// <summary>
    /// Global data module instance - 1:1 translation from Delphi
    /// </summary>
    public static class Daten
    {
        private static DatenM _instance;
        
        public static DatenM Instance
        {
            get
            {
                if (_instance == null)
                {
                    _instance = new DatenM();
                }
                return _instance;
            }
            set
            {
                _instance = value;
            }
        }
    }
}
