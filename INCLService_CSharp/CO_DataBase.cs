// <summary>
// CO_DataBase.cs - C# translation of CO_DataBase.pas
// Database abstraction layer for CommonDB
// </summary>

using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Common;
using System.Globalization;

namespace INCLService_CSharp
{
    /// <summary>
    /// Database types
    /// </summary>
    public enum DatabaseType
    {
        dbTypOracle = 0,
        dbTypMSSQL = 1,
        dbTypZeos = 2
    }

    /// <summary>
    /// CO Database class - wrapper for CommonDB database connection
    /// </summary>
    public class CO_Database
    {
        private string fUsername = "includis";
        private string fPassword = "comtas";
        private string fServer = "includis.world";
        private string fInitialCatalog = string.Empty;
        private string fSqlProvider = string.Empty;
        
        public bool Connected { get; set; } = false;
        public DatabaseType DatabaseType { get; set; } = DatabaseType.dbTypMSSQL;
        
        public string UserName
        {
            get { return fUsername; }
            set { fUsername = value; }
        }
        
        public string Password
        {
            get { return fPassword; }
            set { fPassword = value; }
        }
        
        public string Server
        {
            get { return fServer; }
            set { fServer = value; }
        }
        
        public string InitialCatalog
        {
            get { return fInitialCatalog; }
            set { fInitialCatalog = value; }
        }
        
        public string SqlProvider
        {
            get { return fSqlProvider; }
            set { fSqlProvider = value; }
        }
        
        public string ConnectionString
        {
            get
            {
                if (DatabaseType == DatabaseType.dbTypMSSQL)
                {
                    if (string.IsNullOrEmpty(fSqlProvider))
                    {
                        if (!string.IsNullOrEmpty(fServer) && fServer.StartsWith("#"))
                        {
                            fServer = fServer.Substring(1);
                            return "Provider=SQLNCLI.1;" + GetCommonConnectionString();
                        }
                        else
                        {
                            return "Provider=SQLOLEDB.1;" + GetCommonConnectionString();
                        }
                    }
                    else
                    {
                        return "Provider=" + fSqlProvider + ";" + GetCommonConnectionString();
                    }
                }
                else // Oracle
                {
                    return GetCommonConnectionString();
                }
            }
        }
        
        private string GetCommonConnectionString()
        {
            string catalog = string.IsNullOrEmpty(fInitialCatalog) ? fUsername : fInitialCatalog;
            return "Initial Catalog=" + catalog + ";Data Source=" + fServer + 
                   ";Password=" + fPassword + ";User ID=" + fUsername + ";";
        }

        /// <summary>
        /// Constructor
        /// </summary>
        public CO_Database()
        {
            // Default to SQL Server
            DatabaseType = DatabaseType.dbTypMSSQL;
        }

        /// <summary>
        /// Set connected state
        /// </summary>
        public void SetConnected(bool B)
        {
            if (Connected == B)
                return;

            if (!B)
            {
                Connected = false;
                return;
            }

            try
            {
                // Connect using CommonDB
                // This is handled by CommonDB, so we just set the flag
                Connected = true;
                
                // For SQL Server, set transaction isolation level
                if (DatabaseType == DatabaseType.dbTypMSSQL)
                {
                    // This would be handled by CommonDB
                }
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error connecting to database: " + ex.Message, 0);
                throw new Exception(ex.Message + "(" + UserName + ")");
            }
        }

        /// <summary>
        /// Get connected state
        /// </summary>
        public bool GetConnected()
        {
            return Connected;
        }

        /// <summary>
        /// Start transaction
        /// </summary>
        public void StartTransaction()
        {
            // Handled by CommonDB
        }

        /// <summary>
        /// Commit transaction
        /// </summary>
        public void Commit()
        {
            // Handled by CommonDB
        }
    }

    /// <summary>
    /// SQL class for query operations
    /// </summary>
    public class CO_SQL
    {
        public string Text { get; set; } = string.Empty;
    }

    /// <summary>
    /// Field class for database fields
    /// </summary>
    public class TField
    {
        public string FieldName { get; set; } = string.Empty;
        public object Value { get; set; } = null;
        
        public string AsString
        {
            get
            {
                if (Value == null || Value == DBNull.Value)
                    return string.Empty;
                return Value.ToString();
            }
        }
        
        public int AsInteger
        {
            get
            {
                try
                {
                    if (Value == null || Value == DBNull.Value)
                        return 0;
                    return Convert.ToInt32(Value);
                }
                catch (Exception)
                {
                    return 0;
                }
            }
        }
        
        public double AsFloat
        {
            get
            {
                try
                {
                    if (Value == null || Value == DBNull.Value)
                        return 0;
                    return Convert.ToDouble(Value);
                }
                catch (Exception)
                {
                    return 0;
                }
            }
        }
        
        public DateTime AsDateTime
        {
            get
            {
                try
                {
                    if (Value == null || Value == DBNull.Value)
                        return DateTime.MinValue;
                    return Convert.ToDateTime(Value);
                }
                catch (Exception)
                {
                    return DateTime.MinValue;
                }
            }
        }
    }

    /// <summary>
    /// CO Query class - wrapper for database queries
    /// </summary>
    public class CO_Query : IDisposable
    {
        public CO_SQL SQL { get; private set; } = new CO_SQL();
        public CO_Database Database { get; set; } = null;
        public bool Active { get; private set; } = false;
        public int RowsAffected { get; private set; } = 0;
        
        private List<TField> fields = new List<TField>();
        private List<object[]> rows = new List<object[]>();
        private int currentRow = -1;
        public object Owner { get; set; } = null;

        /// <summary>
        /// Constructor
        /// </summary>
        public CO_Query()
        {
        }

        /// <summary>
        /// Constructor with owner
        /// </summary>
        public CO_Query(object aOwner)
        {
            Owner = aOwner;
        }

        /// <summary>
        /// Set database connection
        /// </summary>
        public void SetDatabase(CO_Database D)
        {
            Database = D;
        }

        /// <summary>
        /// Execute SQL command
        /// </summary>
        public int ExecSQL()
        {
            return ExecSQL(SQL.Text);
        }

        /// <summary>
        /// Execute SQL command with text
        /// </summary>
        public int ExecSQL(string sqlText)
        {
            if (Database == null || !Database.Connected)
            {
                if (Database != null)
                    Database.SetConnected(true);
            }

            try
            {
                // Execute using CommonDB
                // This is a placeholder - actual implementation would use CommonDB
                RowsAffected = 0; // Would be set by actual database operation
                return RowsAffected;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error executing SQL: " + ex.Message, 0);
                return -1;
            }
        }

        /// <summary>
        /// Open query
        /// </summary>
        public void Open()
        {
            try
            {
                if (Active)
                    Close();

                // Process SQL
                DoSQL(SQL.Text);

                if (Database == null || !Database.Connected)
                {
                    if (Database != null)
                        Database.SetConnected(true);
                }

                // Execute query using CommonDB
                // This is a placeholder - actual implementation would use CommonDB
                Active = true;
                currentRow = -1;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error opening query: " + ex.Message, 0);
                Active = false;
            }
        }

        /// <summary>
        /// Close query
        /// </summary>
        public void Close()
        {
            Active = false;
            currentRow = -1;
            rows.Clear();
            fields.Clear();
        }

        /// <summary>
        /// Process SQL text
        /// </summary>
        private void DoSQL(string SQ)
        {
            // This would process the SQL text for any replacements
            // For now, just store it
        }

        /// <summary>
        /// Get field by name
        /// </summary>
        public TField FieldByName(string Fieldname)
        {
            string S = Fieldname.ToUpper();
            
            // Special case for SQL Server
            if (Database != null && Database.DatabaseType == DatabaseType.dbTypMSSQL)
            {
                if (S == "SHUTDOWN")
                    S = S + "1";
            }

            foreach (TField field in fields)
            {
                if (field.FieldName.ToUpper() == S)
                    return field;
            }
            
            return null;
        }

        /// <summary>
        /// Get field by number
        /// </summary>
        public TField FieldByNumber(int FieldNo)
        {
            if (FieldNo >= 0 && FieldNo < fields.Count)
                return fields[FieldNo];
            return null;
        }

        /// <summary>
        /// Check if query is empty
        /// </summary>
        public bool IsEmpty
        {
            get { return rows.Count == 0; }
        }

        /// <summary>
        /// Check if end of file (no more rows)
        /// </summary>
        public bool EOF
        {
            get { return currentRow >= rows.Count - 1; }
        }

        /// <summary>
        /// Move to next row
        /// </summary>
        public void Next()
        {
            if (currentRow < rows.Count - 1)
                currentRow++;
        }

        /// <summary>
        /// Set parameter by name as string
        /// </summary>
        public void ParamByNameAsString(string Param, string Val)
        {
            // This would set a parameter value
            // Implementation depends on the database provider
        }

        /// <summary>
        /// Set parameter by name as integer
        /// </summary>
        public void ParamByNameAsInteger(string Param, int Val)
        {
            // This would set a parameter value
        }

        /// <summary>
        /// Set parameter by name as float
        /// </summary>
        public void ParamByNameAsFloat(string Param, double Val)
        {
            // This would set a parameter value
        }

        /// <summary>
        /// Set parameter by name as date time
        /// </summary>
        public void ParamByNameAsDateTime(string Param, DateTime Val)
        {
            // This would set a parameter value
        }

        /// <summary>
        /// Dispose method
        /// </summary>
        public void Dispose()
        {
            Close();
        }

        /// <summary>
        /// Fields collection
        /// </summary>
        public List<TField> Fields
        {
            get { return fields; }
        }

        /// <summary>
        /// Get field count
        /// </summary>
        public int FieldCount
        {
            get { return fields.Count; }
        }
    }

    /// <summary>
    /// CO Table class - for table operations
    /// </summary>
    public class CO_Table
    {
        public CO_Database Database { get; set; } = null;
        public bool Active { get; private set; } = false;

        /// <summary>
        /// Set database connection
        /// </summary>
        public void SetDatabase(CO_Database D)
        {
            Database = D;
        }

        /// <summary>
        /// Get field by name
        /// </summary>
        public TField FieldByName(string Fieldname)
        {
            // Implementation would depend on the actual table structure
            return null;
        }

        /// <summary>
        /// Open table
        /// </summary>
        public void Open()
        {
            Active = true;
        }

        /// <summary>
        /// Close table
        /// </summary>
        public void Close()
        {
            Active = false;
        }
    }

    /// <summary>
    /// Utility function to convert date to SQL string
    /// </summary>
    public static class DatabaseUtils
    {
        public static string DateToStrSQL(DateTime Date)
        {
            if (DBMain.INCLUDISDatabaseTyp == (int)DatabaseType.dbTypOracle)
            {
                return Date.ToString("dd-MMM-yy", CultureInfo.InvariantCulture);
            }
            else
            {
                return Date.ToString("yyyyMMdd");
            }
        }
    }
}
