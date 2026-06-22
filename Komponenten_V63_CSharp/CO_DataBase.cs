using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Common;
using System.Globalization;

namespace Komponenten_V63_CSharp
{
    public enum DatabaseType
    {
        dbTypOracle = 0,
        dbTypMSSQL = 1,
        dbTypZeos = 2
    }

    public class CO_Database : IDisposable
    {
        private string fUsername = "includis";
        private string fPassword = "comtas";
        private string fServer = "includis.world";
        private string fInitialCatalog = "";
        private string fSqlProvider = "";
        private bool fConnected = false;
        
        private DbConnection fDatabase;
        private DatabaseType databaseType = DatabaseType.dbTypMSSQL;

        public event EventHandler BeforeConnect;
        public event EventHandler AfterConnect;

        public CO_Database()
        {
            // Default to MSSQL for this implementation
            databaseType = DatabaseType.dbTypMSSQL;
            fServer = "includis.world";
        }

        public bool Connected
        {
            get => GetConnected();
            set => SetConnected(value);
        }

        public string UserName
        {
            get => fUsername;
            set => fUsername = value;
        }

        public string Password
        {
            get => fPassword;
            set => fPassword = value;
        }

        public string Server
        {
            get => fServer;
            set => fServer = value;
        }

        public string InitialCatalog
        {
            get => fInitialCatalog;
            set => fInitialCatalog = value;
        }

        public string SqlProvider
        {
            get => fSqlProvider;
            set => fSqlProvider = value;
        }

        public string ConnectionString => GetConnectionString();

        private string GetConnectionString()
        {
            if (fDatabase != null)
                return fDatabase.ConnectionString;
            return "";
        }

        private bool GetConnected()
        {
            if (fDatabase == null)
                return false;
            return fDatabase.State == ConnectionState.Open;
        }

        private void SetConnected(bool B)
        {
            if (Connected == B)
                return;

            if (!B)
            {
                if (fDatabase != null)
                    fDatabase.Close();
                return;
            }

            try
            {
                // Create connection based on database type
                if (fDatabase == null || fDatabase.State != ConnectionState.Open)
                {
                    CreateConnection();
                }

                if (fDatabase != null)
                {
                    BeforeConnect?.Invoke(this, EventArgs.Empty);
                    fDatabase.Open();
                    AfterConnect?.Invoke(this, EventArgs.Empty);
                }

                // Set decimal separators for SQL Server
                if (databaseType == DatabaseType.dbTypMSSQL)
                {
                    CultureInfo.CurrentCulture.NumberFormat.NumberDecimalSeparator = ".";
                    CultureInfo.CurrentCulture.NumberFormat.NumberGroupSeparator = ",";
                }

                // Execute initial command for SQL Server
                if (databaseType == DatabaseType.dbTypMSSQL && fDatabase != null)
                {
                    using (var cmd = fDatabase.CreateCommand())
                    {
                        cmd.CommandText = "set transaction isolation level read uncommitted";
                        cmd.ExecuteNonQuery();
                    }
                }
            }
            catch (Exception e)
            {
                // Handle connection errors
                throw new Exception($"{e.Message} ({UserName})");
            }
        }

        private void CreateConnection()
        {
            // Dispose existing connection if any
            if (fDatabase != null)
            {
                fDatabase.Close();
                fDatabase.Dispose();
            }

            // Create new connection based on type
            switch (databaseType)
            {
                case DatabaseType.dbTypOracle:
                    // For Oracle, we'd use Oracle.DataAccess or similar
                    // This is a placeholder - actual implementation would need Oracle client libraries
                    break;
                case DatabaseType.dbTypMSSQL:
                default:
                    // Use SQL Server connection
                    if (string.IsNullOrEmpty(fSqlProvider))
                    {
                        if (!string.IsNullOrEmpty(fServer) && fServer.StartsWith("#"))
                        {
                            fServer = fServer.Substring(1);
                            fDatabase = CreateSqlConnection("SQLNCLI.1");
                        }
                        else
                        {
                            fDatabase = CreateSqlConnection("SQLOLEDB.1");
                        }
                    }
                    else
                    {
                        fDatabase = CreateSqlConnection(fSqlProvider);
                    }
                    break;
                case DatabaseType.dbTypZeos:
                    // Zeos connection would be implemented here
                    break;
            }

            // Set connection properties
            if (fDatabase != null)
            {
                var connectionStringBuilder = new System.Data.Common.DbConnectionStringBuilder
                {
                    ["Data Source"] = fServer,
                    ["User ID"] = fUsername,
                    ["Password"] = fPassword
                };

                if (!string.IsNullOrEmpty(fInitialCatalog))
                {
                    connectionStringBuilder["Initial Catalog"] = fInitialCatalog;
                }
                else if (databaseType == DatabaseType.dbTypMSSQL)
                {
                    connectionStringBuilder["Initial Catalog"] = fUsername;
                }

                // Set additional options for SQL Server
                if (databaseType == DatabaseType.dbTypMSSQL)
                {
                    connectionStringBuilder["MultipleActiveResultSets"] = "True";
                    connectionStringBuilder["LockTimeout"] = "15000";
                }

                fDatabase.ConnectionString = connectionStringBuilder.ConnectionString;
            }
        }

        private DbConnection CreateSqlConnection(string provider)
        {
            // This is a simplified implementation
            // In a real application, you would use the appropriate provider
            try
            {
                // For System.Data.SqlClient (modern .NET)
                var connection = new System.Data.SqlClient.SqlConnection();
                return connection;
            }
            catch
            {
                // Fallback or alternative providers could be tried here
                return null;
            }
        }

        public void StartTransaction()
        {
            if (fDatabase != null && fDatabase.State == ConnectionState.Open)
            {
                fDatabase.BeginTransaction();
            }
        }

        public void Commit()
        {
            if (fDatabase != null && fDatabase.State == ConnectionState.Open)
            {
                var transaction = fDatabase.BeginTransaction();
                transaction.Commit();
            }
        }

        private void DoBeforeConnect(object sender, EventArgs e)
        {
            fConnected = true;
        }

        private void DoAfterConnect(object sender, EventArgs e)
        {
            fConnected = GetConnected();
        }

        public void Dispose()
        {
            if (fDatabase != null)
            {
                if (fDatabase.State == ConnectionState.Open)
                    fDatabase.Close();
                fDatabase.Dispose();
                fDatabase = null;
            }
        }

        ~CO_Database()
        {
            Dispose();
        }
    }

    public class CO_Query : IDisposable
    {
        private CO_Database fDatabase;
        private string zusatzSQL = "";
        private DbCommand command;
        private DbConnection connection;

        public CO_Database Database
        {
            get => fDatabase;
            set => SetDatabase(value);
        }

        public string SQL { get; set; }

        public CO_Query()
        {
            // Initialize command
        }

        public CO_Query(CO_Database database)
        {
            fDatabase = database;
            if (database != null)
            {
                connection = database.fDatabase;
                if (connection != null)
                {
                    command = connection.CreateCommand();
                }
            }
        }

        private void SetDatabase(CO_Database D)
        {
            if (D != null)
            {
                connection = D.fDatabase;
                if (connection != null)
                {
                    command = connection.CreateCommand();
                }
            }
            fDatabase = D;
        }

        public int ExecSQL()
        {
            if (fDatabase == null || !fDatabase.Connected)
            {
                if (fDatabase != null)
                    fDatabase.Connected = true;
            }

            if (command == null)
                return -1;

            command.CommandText = SQL;
            DoSQL(command.CommandText);

            if (!string.IsNullOrEmpty(zusatzSQL))
            {
                var tempSql = command.CommandText;
                command.CommandText = zusatzSQL;
                zusatzSQL = "";
                try
                {
                    command.ExecuteNonQuery();
                }
                catch { }
                command.CommandText = tempSql;
            }

            var result = command.ExecuteNonQuery();
            return result;
        }

        public void Open()
        {
            if (command == null)
                return;

            try
            {
                if (command.Connection != null && command.Connection.State == ConnectionState.Open)
                {
                    // Close if already open
                    // Note: This is a simplification - actual behavior may vary
                }
            }
            catch { }

            DoSQL(SQL);

            if (fDatabase != null && !fDatabase.Connected)
            {
                fDatabase.Connected = true;
            }

            // Execute reader
            if (command != null)
            {
                command.CommandText = SQL;
                using (var reader = command.ExecuteReader())
                {
                    // Process results if needed
                }
            }
        }

        public object FieldByName(string Fieldname)
        {
            // Simplified implementation - in real code this would work with a DataReader or DataTable
            return null;
        }

        public object FieldByNumber(int FieldNo)
        {
            // Simplified implementation
            return null;
        }

        public void ParamByNameAsString(string Param, string Val)
        {
            if (command != null)
            {
                var param = command.CreateParameter();
                param.ParameterName = Param;
                param.Value = Val;
                command.Parameters.Add(param);
            }
        }

        public void ParamByNameAsInteger(string Param, int Val)
        {
            if (command != null)
            {
                var param = command.CreateParameter();
                param.ParameterName = Param;
                param.Value = Val;
                command.Parameters.Add(param);
            }
        }

        public void ParamByNameAsFloat(string Param, double Val)
        {
            if (command != null)
            {
                var param = command.CreateParameter();
                param.ParameterName = Param;
                param.Value = Val;
                command.Parameters.Add(param);
            }
        }

        public void ParamByNameAsDateTime(string Param, DateTime Val)
        {
            if (command != null)
            {
                var param = command.CreateParameter();
                param.ParameterName = Param;
                param.Value = Val;
                command.Parameters.Add(param);
            }
        }

        private void DoSQL(string SQ)
        {
            // Parse and normalize SQL
            var parsedSql = ParseSQL(SQ);
            if (command != null)
            {
                command.CommandText = parsedSql;
            }
        }

        private string ParseSQL(string T)
        {
            // Simplified SQL parsing - would need to handle database-specific functions
            return T;
        }

        private void WriteLog(string S)
        {
            // Logging implementation
            Console.WriteLine(S);
        }

        public void Dispose()
        {
            if (command != null)
            {
                command.Dispose();
                command = null;
            }
        }

        ~CO_Query()
        {
            Dispose();
        }
    }

    public class CO_Table : IDisposable
    {
        private CO_Database fDatabase;
        private DbCommand command;
        private DbConnection connection;

        public CO_Database Database
        {
            get => fDatabase;
            set => SetDatabase(value);
        }

        private void SetDatabase(CO_Database D)
        {
            if (D != null)
            {
                connection = D.fDatabase;
                if (connection != null)
                {
                    command = connection.CreateCommand();
                }
            }
            fDatabase = D;
        }

        public object FieldByName(string Fieldname)
        {
            // Simplified implementation
            return null;
        }

        public void Dispose()
        {
            if (command != null)
            {
                command.Dispose();
                command = null;
            }
        }

        ~CO_Table()
        {
            Dispose();
        }
    }

    public static class CO_DataBaseUtils
    {
        public static string DateToStrSQL(DateTime Date)
        {
            // For SQL Server: yyyymmdd format
            return Date.ToString("yyyyMMdd");
        }
    }
}
