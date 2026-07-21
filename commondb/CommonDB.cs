using System.Collections.ObjectModel;
using System.Collections.Generic;
using System.Globalization;
using System.ServiceProcess;
using System.Data;
using System.Management;
using System.Data.Common;
using System.Text;
using System.Text.RegularExpressions;
using System;
using INCLUDIS.Utils.CommonDB.Attributed;

using System.Diagnostics;
using System.Linq;
using System.Reflection;
using System.Threading;
using System.Runtime.InteropServices;

namespace INCLUDIS.Utils.CommonDB
{
    // ReSharper disable InconsistentNaming    
    /// <summary>
    /// Provides a common connection to ALL db types.
    /// </summary>
    public class CommonDB
    {
        //public const string ProviderSQLServer = "System.Data.SqlClient";
        //public const string ProviderOracle = "System.Data.OracleClient";

        public const string ProviderSQLServer = "System.Data.SqlClient";
        public const string ProviderOdbc = "System.Data.Odbc";
        public const string ProviderOracleNet = "Devart.Data.Oracle";
        public const string ProviderOracle = "System.Data.OracleClient";
        public const string ProviderSQLite = "System.Data.SQLite";
        public const string ProviderSQLServerCE = "System.Data.SqlServerCe.3.5";
        public const string ProviderSqlNet = "Devart.Data.SqlServer";

        private string _providerString;

        private readonly string _connectionString;
        public string ConnectionString { get { return _connectionString; } }


        public string DBUser { get; private set; }
        public string DbArcUser { get { return DBUser + "_ARC." + (IsMssql ? "." : String.Empty); } }
        public string DBServer { get; private set; }
        /// <summary>
        /// Wegen Abwärtskompatibiltät dasselbe wie DBServer
        /// </summary>
        public string DBAlias => DBServer;

        public string DBCatalog { get; private set; }
        public DatabaseType DBType { get; private set; }

        private bool _oracleDirectMode;// = false;

        private readonly DbProviderFactory _provider;
        private readonly bool _unicode;
        private const int DefaultPoolSize = 100;
        private const int DefaultConnectionLifeTime = 0;
        private const int DefaultConnTimeOut = 15;

        public Action<string> LogExternal { get; set; }

        public Boolean IsMssql { get { return new[] { DatabaseType.dtMSSQL }.Contains(DBType); } }
        public bool IsUnicode {  get { return _unicode; } }

      //  private Log.Log _log;

        public DbProviderFactory ProviderFactory => _provider;

  //      public Log.Log LOG
   //     {
   //         get { return this._log; }
  //          set { this._log = value; if (value == null || CommonReader.Log == null) CommonReader.Log = this._log; }
   //     }

        public enum DatabaseType
        {
            dtOracle, dtMSSQL, dtSQLite, dtOther, dtOracleNet, dtOdbc, dtMsSqlNet
        }

        private DbProviderFactory GetDbFactory(string aProvider)
        {
            return DbProviderFactories.GetFactory(aProvider);
        }

        // ReSharper restore InconsistentNaming

        #region constructors
        public CommonDB(DatabaseType aDbType, string connectionString)
        {

            this.SetProvider(aDbType);

            _connectionString = connectionString;

            try
            {
                _provider = this.GetDbFactory(_providerString);
            }
            catch (Exception ex)
            {
                this.LogException(ex, "Getting Factory");
                throw;
            }
        }

        public CommonDB(DatabaseType aDbType, string aDbUser, string aDbPass, string aDbAlias, bool unicode = false)
    : this(aDbType, aDbUser, aDbPass, aDbAlias, aDbUser, unicode)
        { }

        public CommonDB(DatabaseType aDbType, string aDbUser, string aDbPass, string aDbAlias, string aCatalog)
            : this(aDbType, aDbUser, aDbPass, aDbAlias, aCatalog, false)
        { }

        /// <summary>
        /// Initializes a new instance of the <see cref="CommonDB"/> class
        /// </summary>
        /// <param name="aDbType">The <see cref="DatabaseType"/></param>
        /// <param name="aDbUser">The user name</param>
        /// <param name="aDbPass">The password</param>
        /// <param name="aServer">The server</param>
        /// <param name="aCatalog">The db name (Sql Server only)</param>
        /// <param name="unicode">Whether to use unicode or not (Oracle only)</param>
        /// <param name="poolSize">The poolsize</param>
        /// <param name="connectionLifeTime">The connection lifetime</param>
        /// <param name="connectionTimeout">The connection timeout</param>
        /// <param name="sqlAsync"></param>
        public CommonDB(DatabaseType aDbType, string aDbUser, string aDbPass, string aServer, string aCatalog, bool unicode,
            Int32 poolSize, Int32 connectionLifeTime, Int32 connectionTimeout, bool sqlAsync) : this(aDbType, aDbUser, aDbPass, aServer, aCatalog, unicode)
        {
            if (aDbType == DatabaseType.dtMSSQL)
            {
                var connString = new StringBuilder(_connectionString);
                if (poolSize != 100)
                    connString.Append(";Max Pool Size=" + poolSize);
                if (connectionLifeTime > 0)
                    connString.Append(";Connection Lifetime=" + connectionLifeTime);
                if (connectionTimeout != 15)
                    connString.Append(";Connection Timeout=" + connectionTimeout);

                //connString.Append("Persist Security Info=False;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;");

                _connectionString = connString.ToString();
            }

            if (aDbType == DatabaseType.dtOracleNet)
            {
                _connectionString += (poolSize != 100) ? String.Format("Max Pool Size={0};", poolSize) : String.Empty;
                _connectionString += (connectionLifeTime > 0) ? String.Format("Connection Lifetime={0};", connectionLifeTime) : String.Empty;
                _connectionString += (connectionTimeout != 15) ? String.Format("Connection Timeout={0};", connectionTimeout) : String.Empty;               
            }
        }

        public CommonDB(DatabaseType aDbType, string aDbUser, string aDbPass, string aServer, string initialCatalog, bool unicode,
           Int32 poolSize, Int32 connectionLifeTime, Int32 connectionTimeout, bool validateConnection, bool sqlAsync) :
            this(aDbType, aDbUser, aDbPass, aServer, initialCatalog, unicode,
               poolSize, connectionLifeTime, connectionTimeout, sqlAsync)
        {
            if (aDbType == DatabaseType.dtOracleNet)
            {
                _connectionString += validateConnection ? "Validate Connection=true;" : String.Empty;
            }
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="CommonDB"/> class
        /// </summary>
        /// <param name="aDbType">The <see cref="DatabaseType"/></param>
        /// <param name="aDbUser">The user name</param>
        /// <param name="aDbPass">The password</param>
        /// <param name="aServer">The server</param>
        /// <param name="aCatalog">The db name (Sql Server only)</param>
        /// <param name="unicode">Whether to use unicode or not (Oracle only)</param>
        public CommonDB(DatabaseType aDbType, string aDbUser, string aDbPass, string aServer, string aCatalog, bool unicode)
        {
            DBType = aDbType;
            _unicode = unicode;



            //switch (aDbType)
            //{
            //    case DatabaseType.dtMSSQL:
            //        provider = ProviderSQLServer;
            //        break;
            //    case DatabaseType.dtOracle:
            //        provider = ProviderOracle;
            //        break;
            //    default:
            //        provider = string.Empty;
            //        break;
            //}
            this.SetProvider(aDbType);

            DBUser = aDbUser;
            DBServer = aServer;
            DBCatalog = aCatalog;
            _connectionString = GetConnectionString(aDbType, aDbUser, aDbPass, aServer, aCatalog, _unicode);

            try
            {
                _provider = this.GetDbFactory(_providerString);
            }
            catch (Exception ex)
            {
                this.LogException(ex, "Getting Factory");
                throw;
            }

        }

        private void SetProvider(DatabaseType aDbType)
        {
            string provider;
            switch (aDbType)
            {
                case DatabaseType.dtMsSqlNet:
                    provider = ProviderSqlNet;
                    break;
                case DatabaseType.dtMSSQL:
                    provider = ProviderSQLServer;
                    break;
                case DatabaseType.dtOracle:
                    provider = ProviderOracle;
                    break;
                case DatabaseType.dtOracleNet:
                    provider = ProviderOracleNet;
                    break;
                case DatabaseType.dtSQLite:
                    provider = ProviderSQLite;
                    break;
                case DatabaseType.dtOdbc:
                    provider = ProviderOdbc;
                    break;
                default:
                    provider = string.Empty;
                    break;
            }

            _providerString = provider;
        }
        #endregion
        /*
        private void CheckDbType(string aProvider)
        {
            switch (aProvider)
            {
                case ProviderSQLServer:
                    DBType = DatabaseType.dtMSSQL;
                    break;
                case ProviderOracle:
                    DBType = DatabaseType.dtOracle;
                    break;
                default:
                    DBType = DatabaseType.dtOther;
                    break;
            }
        }*/

        public static DataTable GetAllProvidersDataTable()
        {
            return DbProviderFactories.GetFactoryClasses();
        }

        public static Collection<string> GetAllProviders()
        {
            var strList = new Collection<string>();
            DataTable providers = DbProviderFactories.GetFactoryClasses();
            foreach (DataRow provider in providers.Rows)
            {
                int i = 0;
                foreach (DataColumn c in providers.Columns)
                {
                    string s = string.Empty;
                    for (int j = 0; j < i; j++)
                    {
                        s += "  ";
                    }

                    strList.Add(s + c.ColumnName + ":" + provider[c]);
                    i++;
                }
            }

            return strList;
        }

        #region GetConnectionStrings      


        public static string GetConnectionString(DatabaseType aDbType, string aUsername, string aPassword, string aServer, string aCatalog, bool unicode)
        {
            
            string aProvider;
            switch (aDbType)
            {
                case DatabaseType.dtMsSqlNet:
                    aProvider = ProviderSqlNet;
                    break;
                case DatabaseType.dtMSSQL:
                    aProvider = ProviderSQLServer;
                    break;
                case DatabaseType.dtOracle:
                    aProvider = ProviderOracle;
                    break;
                case DatabaseType.dtOracleNet:
                    aProvider = ProviderOracleNet;
                    break;
                case DatabaseType.dtSQLite:
                    aProvider = ProviderSQLite;
                    break;
                case DatabaseType.dtOdbc:
                    aProvider = ProviderOdbc;
                    break;
                default:
                    aProvider = string.Empty;
                    break;
            }

            if (aProvider == ProviderOracle)
                return
                    $"Data Source={aServer};User Id={aUsername};Password={aPassword};{(unicode ? "Unicode=true;" : "")}";
            if (aProvider == ProviderOracleNet)
            {
                var user = aUsername.ToLower() == "sys" ? aUsername + ";Mode=SysDba" : aUsername;
                string constring = $"User Id={user};Password={aPassword};{(unicode ? "Unicode=true;" : "")}direct=";
                if (aServer.Contains(":"))
                {
                    var serversplits = aServer.Split(':');
                    if (serversplits.Length == 3)
                    {
                        constring += $"true;Server={serversplits[0]};Port={serversplits[1]};Sid={serversplits[2]};";
                    }
                }
                else
                {
                    constring += $"false;Server={aServer};";
                }
                return constring;
            }
            if ((aProvider == ProviderSQLServer) || (aProvider == ProviderSqlNet))
                return
                    $"Data Source={aServer};Initial Catalog={aCatalog};User Id={aUsername};Password={aPassword};MultipleActiveResultSets=True;TransparentNetworkIPResolution=False;{(/*sqlAsync*/false ? "async=true;" : "")}";

            if (aProvider == ProviderSQLite)
                return "Provider=sqlite;Data Source=" + aServer + ";Initial Catalog=" + aCatalog
                       + ";User Id=" + aUsername + ";Password=" + aPassword + ";";
            if (aProvider == ProviderOdbc)
                return $"DSN={aServer};Uid={aUsername};Pwd={aPassword};";
            return string.Empty;

            /*switch (aDbType)
            {
                case DatabaseType.dtMSSQL:
                    return $"Data Source={aServer};Initial Catalog={aCatalog};User Id={aUsername};Password={aPassword};MultipleActiveResultSets=True;";
                case DatabaseType.dtOracle:
                    return
                        $"Data Source={aServer};User Id={aUsername};Password={aPassword};{(unicode ? "Unicode=true;" : "")}";
                default: return string.Empty;
            }*/
        }

        #endregion
        // ReSharper disable UnusedMethodReturnValue.Local
        private bool ParseConnectionString(string inputString, out string userName, out string serverName)
        // ReSharper restore UnusedMethodReturnValue.Local
        {
            string connectionStringPattern;
            _oracleDirectMode = inputString.IndexOf("direct=true", StringComparison.Ordinal) > -1;
            switch (_providerString)
            {
                case ProviderOracle:
                    connectionStringPattern = @"Data Source=(?<ServerName>.+);Password=(?<password>\w+);User Id=(?<userName>\w+)";
                    break;
                //case ProviderOracleNet:
                //    connectionStringPattern = _oracleDirectMode ? @"User Id=(?<userName>\w+);Password=(?<password>\w+);direct=true;Server=(?<ServerName>.+);Port=(?<Port>.+);Sid=(?<Sid>.+);"
                //                                                : @"User Id=(?<userName>\w+);Password=(?<password>\w+);direct=false;Server=(?<ServerName>.+);";
                //    break;
                //case ProviderOdbc:
                //    connectionStringPattern = @"DSN=(?<ServerName>.+);Uid=(?<userName>\w+);Pwd=(?<password>\w+)";
                //    break;
                default:
                    connectionStringPattern = @"Data Source=(?<ServerName>.+);Initial Catalog=(?<databaseName>\w+);User Id=(?<userName>\w+)";
                    break;
            }

            var connectionStringRegex = new Regex(connectionStringPattern, RegexOptions.IgnoreCase);
            var match = connectionStringRegex.Match(inputString);
            userName = match.Groups["userName"].Value;
            serverName = match.Groups["ServerName"].Value;
            return !userName.Equals("") && !serverName.Equals("");
        }

        public CommonCommand NewCommonCommand(string query = null)
        {
            var command = new CommonCommand(LogIt, this.DBType, this._provider, this._connectionString, this._unicode);
            command.LogExternal = this.LogExternal;
            if (query != null && !string.IsNullOrEmpty(query.Trim())) command.CommandText = query;
            return command;
        }

        /// <summary>
        /// Creates new common command.
        /// BREAKING CHANGE:
        /// This no longer returns a DbCommand but an CommonCommand. This is due to the connection now being opened when needed and cloed when execution is complete or the object is cleand up by the GC.
        /// </summary>
        /// <param name="aCommand">a command.</param>
        /// <returns></returns>
        public IDbCommand NewCommand(string query = null)
        {
            return NewCommonCommand(query);
        }

        public DbParameter NewParameter(string aName, DbType aType, object aValue = null)
        {
            var parameter = _provider.CreateParameter();

            if (parameter != null)
            {
                parameter.DbType = aType;
                parameter.ParameterName = aName;
                parameter.Value = aValue;
            }
            return parameter;
        }

        public decimal ExecuteScalar(string aCommand)
        {
            return this.NewCommonCommand().ExecuteScalar(aCommand);
        }

        /// <summary>
        /// SQL Execute
        /// </summary>
        /// <param name="timeout">Command timeout in sec.</param>
        /// <param name="aCommand">SQL command</param>
        /// <param name="args">opt. args</param>
        /// <returns></returns>
        public int ExecuteNonQuery(int timeout, string aCommand, params object[] args)
        {
            return this.NewCommonCommand().ExecuteNonQuery(timeout, aCommand, args);
        }

        /// <summary>
        /// SQL Execute
        /// </summary>
        /// <param name="aCommand">SQL command</param>
        /// <param name="args">opt. args</param>
        /// <returns></returns>
        public int ExecuteNonQuery(string aCommand, params object[] args)
        {
            return ExecuteNonQuery(30, aCommand, args);
        }

        /// <summary>
        /// Unparsed SQL Execute
        /// </summary>
        /// <param name="aCommand">SQL Statemant</param>
        /// <param name="args">SQL Statement args</param>
        /// <returns>Amount of changed Entries</returns>
        public int ExecuteUnparsedNonQuery(string aCommand, params object[] args)
        {
            return ExecuteUnparsedNonQuery(30, aCommand, args);
        }

        /// <summary>
        /// Unparsed SQL Execute
        /// </summary>
        /// <param name="timeout">Command timeout in sec.</param>
        /// <param name="aCommand">SQL Statemant</param>
        /// <param name="args">SQL Statement args</param>
        /// <returns>Amount of changed Entries</returns>

        public int ExecuteUnparsedNonQuery(int timeout, string aCommand, params object[] args)
        {

            var cmd = NewCommonCommand().Command;
            int i = 0;
            try
            {
                cmd.CommandTimeout = timeout;
                cmd.CommandText = aCommand;
                cmd.Connection.Open();
                i = cmd.ExecuteNonQuery();
                cmd.Connection.Close();

            }
            catch (Exception ex)
            {
                //HandleDBException(ex, cmd.CommandText);
                this.LogException(ex, aCommand);
                i = -1;
            }
            finally
            {
                cmd.Connection.Close();
            }

            return i;
        }
        /*
        public Boolean IsOpen { get { return ((State == ConnectionState.Open) || (State == ConnectionState.Executing)); } }

        public ConnectionState State
        {
            get
            {
                return _sqlConn.State;
            }
        }

        public DbConnection Connection
        {
            get
            {
                return _sqlConn;
            }
        }
        */
        public CommonReader GetUnparsedCommonReader(string aCommand)
        {
            return this.NewCommonCommand().GetReader(aCommand);
        }
        /// <summary>
        /// Unsafe Query with Parsed SQL Statement
        /// </summary>
        /// <param name="aCommand">SQL Command</param>
        /// <param name="args">User Arguments</param>
        /// <returns>CommonReader with result</returns>
        public CommonReader GetReader(string aCommand, params object[] args)
        {
            return this.NewCommonCommand().GetReader(GetQuery(aCommand, args));
        }
        public CommonReader GetCommonReader(string aCommand, params object[] args)
        {
            return (GetReader(aCommand, args));
        }
        /// <summary>
        /// Gets an IDataReader of this reader
        /// </summary>
        /// <param name="aCommand"></param>
        /// <returns></returns>
        public CommonReader GetReader(string aCommand)
        {
            return this.GetReader(aCommand, null);
        }
        public CommonReader GetCommonReader(string aCommand)
        {
            return (GetReader(aCommand));
        }
        public bool CheckDbState()
        {
            //try
            //{
            // Zuerst proüfen ob Datenbank online                
            var realopen = false;
            try
            {
                using (var reader = GetReader("SELECT * FROM dual"))
                {
                    realopen = reader.Read();
                }
                
                return realopen;
            }
            catch (Exception ex)
            {
                // Wenn es keine Includis DB ist dann gibt es kein DUAL !!!
                try
                {
                    using (var reader = GetReader("SELECT COUNT(*) FROM sys.tables"))
                    {
                        if (reader.Read())
                        {
                            realopen = reader.GetInt32(0) > 0;
                        }
                    }
                    return realopen;
                }
                catch (Exception ex2)
                {
                    ex = ex2;
                }
                //HandleDBException(ex, "Checking real state of DB connection");
                return false;
            }            
        }

        private void LogIt(string message)
        {
            //if (LOG != null)
            //    LOG.LogSome(message);
            LogExternal?.Invoke(message);
        }

        // ReSharper disable InconsistentNaming
        public bool SafeDBWrite(string query)
        {
            return SafeDBWrite(query, null);
        }

        public bool SafeDBWrite(string baseQuery, DbConditionList conditions)
        // ReSharper restore InconsistentNaming
        {
            string parsedCommand = "";

            try
            {
                parsedCommand = CommonCommand.Parse(baseQuery, DatabaseType.dtOracle, this.DBType, this._unicode);

                if ((new[] { DatabaseType.dtMSSQL }.Contains(DBType)) && (parsedCommand.ToUpper().Contains("CREATE OR REPLACE VIEW")))
                {
                    var pos = parsedCommand.ToUpper().IndexOf("CREATE OR REPLACE VIEW", 0, StringComparison.Ordinal);
                    var secondpart = parsedCommand.Substring(pos + 23);
                    var pos2 = secondpart.IndexOf(' ');
                    var table = secondpart.Substring(0, pos2);

                    this.NewCommonCommand().ExecuteNonQuery(String.Format("IF EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME = '{0}') DROP VIEW {0}", table));

                    parsedCommand = "CREATE VIEW " + secondpart;
                }

                var cmd = (conditions != null && conditions.Count > 0) ? GetParametrizedCommand(parsedCommand, conditions) : this.NewCommonCommand(parsedCommand);
                cmd.ExecuteNonQuery();
                return true;
            }
            catch (Exception ex)
            {
                //HandleDBException(ex, baseQuery);
                this.LogException(ex, baseQuery);
                return false;
            }
        }

        public DataTable GetDataTableByTable(string tableName)
        {
            return GetDataTable(String.Format("SELECT * FROM {0}", tableName), tableName);
        }

        public DataTable GetDataTableByTable(string tableName, bool replaceColumnNames)
        {
            return GetDataTable(String.Format("SELECT * FROM {0}", tableName), replaceColumnNames, tableName);
        }

        public DataTable GetDataTable(string basequery, DbConditionList conditions, string tableName = "")
        {
            return GetDataTable(basequery, conditions, true, tableName);
        }

        public DataTable GetDataTable(string basequery, DbConditionList conditions, bool replaceColumnNames, string tableName = "")
        {
            if (conditions == null || conditions.Count == 0)
                return GetDataTable(basequery, tableName);
            //else
            return GetDataTableInternal(GetParametrizedCommand(basequery, conditions), tableName, true);

        }

        public DataTable GetDataTable(string query, string tableName = "")
        {
            return GetDataTableInternal(this.NewCommonCommand(query), tableName, true);
        }


        public DataTable GetDataTable(string query, bool replaceColumnNames, string tableName = "")
        {
            return GetDataTableInternal(this.NewCommonCommand(query), tableName, replaceColumnNames);
        }
        private DataTable GetDataTableInternal(CommonCommand cmd, string tableName, bool replaceColumnNames)
        {

            var ds = new DataSet();

            using (var reader = cmd.GetReader())
            {
                if (reader.HasRows)
                {
                    ds.Load(reader, LoadOption.PreserveChanges, tableName);
                    if (ds.Tables.Count > 0 && replaceColumnNames)
                    {
                        var cols = ds.Tables[0].Columns;
                        for (var c = 0; c < cols.Count; c++)
                        {
                            cols[c].ColumnName = Thread.CurrentThread.CurrentCulture.TextInfo
                                                        .ToTitleCase(cols[c].ColumnName.ToLower())
                                                        .Replace("_", "")
                                                        .Replace(" ", "");
                        }
                    }
                }
            }

            return (ds.Tables.Count > 0) ? ds.Tables[0] : null;
        }

        private string GetQuery(string baseString, object[] tokens)
        {
            string query;
            try
            {
                query = (tokens != null && tokens.Length > 0) ? String.Format(CultureInfo.InvariantCulture, baseString, tokens) : baseString;
            }
            catch (Exception ex)
            {
                query = baseString;
                var tokenString = String.Empty;
                if (tokens != null)
                {
                    foreach (var t in tokens)
                    {
                        try
                        {
                            tokenString += String.Format(CultureInfo.InvariantCulture, "'{0}', ", t);
                        }
                        catch
                        {
                            tokenString += "'n.n.', ";
                        }
                    }
                }

                if (tokenString.Length > 2)
                    tokenString = tokenString.Remove(tokenString.Length - 2);
                LogException(ex, String.Format("Formatting String '{0}' with '{1}' tokens ({2})", baseString, tokens != null ? tokens.Length : 0, tokenString));
                throw;
            }
            return query;
        }

        // ReSharper disable InconsistentNaming
        public string getArchiveExpression()
        // ReSharper restore InconsistentNaming
        {
            if (IsMssql)
                return String.Format("[{0}].{1}_arc.dbo", DBServer, DBUser);
            //else
            return DBUser + "_arc";
        }

        public bool HasRows(string query)
        {
            using (var reader = GetReader(query))
            {
                return reader.HasRows;
            }
        }

        public CommonReader GetParametrizedReader(string baseQuery, DbCondition onlyCondition, bool hasWhereInBaseQuery)
        {
            return GetParametrizedReader(baseQuery, new DbConditionList { onlyCondition }, hasWhereInBaseQuery);
        }

        public CommonReader GetParametrizedReader(string baseQuery, DbCondition onlyCondition)
        {
            return GetParametrizedReader(baseQuery, new DbConditionList { onlyCondition }, false);
        }

        public CommonReader GetParametrizedReader(string baseQuery, DbConditionList conditions)
        {
            return GetParametrizedReader(baseQuery, conditions, false);
        }

        public CommonReader GetParametrizedReader(string baseQuery, DbConditionList conditions, Boolean hasWhereClauseInBaseQuery)
        {
            var cmd = GetParametrizedCommand(baseQuery, conditions, hasWhereClauseInBaseQuery);

            CommonReader reader = null;
            reader = cmd.GetReader();
            return reader;
        }

        public int ExecuteParametrizedQuery(string baseQuery, DbConditionList conditions)
        {
            var result = 0;

            var cmd = GetParametrizedCommand(baseQuery, conditions);
            result = cmd.ExecuteNonQuery();

            return result;
        }

        public CommonCommand GetCommandWithTimeFrame(string baseQuery, string timeField, DateTime start, DateTime end,
                                                 IEnumerable<DbCondition> otherConditions, bool withOpenEnd)
        {
            return GetCommandWithTimeFrameAndMachineFilter(baseQuery, timeField, start, end, String.Empty,
                                                           new List<Int32>(), otherConditions, withOpenEnd);
        }


        public CommonCommand GetCommandWithTimeFrameAndMachineFilter(string baseQuery, string timeField, DateTime start, DateTime end, string machField, List<Int32> machNos, IEnumerable<DbCondition> otherConditions, bool withOpenEnd)
        {
            var cmd = NewCommonCommand();
            try
            {
                var pStart = CommonCommand.GetParamname("startbz", this.DBType);
                var pEnd = CommonCommand.GetParamname("endbz", this.DBType);
                var sb = new StringBuilder(baseQuery);
                sb.Append(String.Format(" WHERE {0} >= {2} AND " + ((withOpenEnd)
                                                ? "( {0} IS NULL OR {0} = 0 OR {0} < {1})"
                                                : "{0} < {1}"), timeField, pEnd, pStart));
                cmd.Parameters.Add(NewParameter(pStart, DbType.Double, start.ToOADate()));
                cmd.Parameters.Add(NewParameter(pEnd, DbType.Double, end.ToOADate()));
                if (!String.IsNullOrEmpty(machField) && machNos.Count > 0)
                {
                    sb.Append(String.Format(" AND {0} IN (", machField));
                    foreach (var m in machNos)
                    {
                        var pName = CommonCommand.GetParamname(machField.Replace(".", "") + m.ToString(CultureInfo.InvariantCulture), this.DBType);
                        sb.Append(String.Format("{0}, ", pName));
                        cmd.Parameters.Add(NewParameter(pName, DbType.Int32, m));
                    }
                    sb.Remove(sb.Length - 2, 2);
                    sb.Append(")");
                }
                AddParametersToCommand(cmd, sb, otherConditions, false);
            }
            catch (Exception ex)
            {
                //HandleDBException(ex, cmd.CommandText);
                LogException(ex, String.Format("Creating parametrized query based on '{0}'", baseQuery));
                throw;
            }

            return cmd;
        }


        private CommonCommand GetParametrizedCommand(string baseQuery, IEnumerable<DbCondition> conditions, bool hasWhereInBaseQuery)
        {
            var cmd = NewCommonCommand();
            return AddParametersToCommand(cmd, new StringBuilder(baseQuery), conditions, !hasWhereInBaseQuery);
        }

        private CommonCommand GetParametrizedCommand(string baseQuery, IEnumerable<DbCondition> conditions)
        {
            // ReSharper disable once IntroduceOptionalParameters.Local
            return GetParametrizedCommand(baseQuery, conditions, false);
        }

        private CommonCommand AddParametersToCommand(CommonCommand cmd, StringBuilder sql, IEnumerable<DbCondition> conditions, bool firstCondition = true)
        {

            try
            {
                if (conditions != null)
                {
                    foreach (var condition in conditions)
                    {
                        sql.Append(firstCondition ? " WHERE " : " AND ");
                        firstCondition = false;
                        sql.Append(condition.FieldName);
                        sql.Append(condition.ConditionString);
                        string paramname = CommonCommand.GetParamname(condition.VarName, this.DBType);
                        sql.Append(paramname);
                        cmd.Parameters.Add(NewParameter(paramname, condition.FieldType, condition.ConditionValue));

                    }
                }

                cmd.CommandText = sql.ToString();
            }
            catch (Exception ex)
            {
                LogException(ex, String.Format("Creating parametrized query based on '{0}'", sql));
                throw;
            }
            return cmd;
        }

        public string GetArchiveExpression(bool isArchive, string tableName, string innerQuery = "")
        {
            var retString = (String.IsNullOrEmpty(innerQuery) ? String.Empty : innerQuery + " ") + tableName;
            if (!isArchive)
                return retString;
            //else
            return retString + " UNION " + (String.IsNullOrEmpty(innerQuery) ? String.Empty : innerQuery + " ") +
                   DbArcUser + tableName;

        }

        public string Parse(string originalQuery)
        {
            return Parse(originalQuery, DatabaseType.dtOracle, DBType, _unicode);
        }

        public static string Parse(string query, DatabaseType srcDbType, DatabaseType dstDbType, bool unicode = false)
        {
            return CommonCommand.Parse(query, srcDbType, dstDbType, unicode);
        }

        public bool SafeParamCmdExecution<T>(string baseSql, List<CmdParam<T>> parameterList, List<T> dataList, bool parsePrior)
        {
            var cmd = this.NewCommonCommand();
            return cmd.SafeParamCmdExecution<T>(baseSql, parameterList, dataList, parsePrior);
        }

        internal void LogException(Exception ex, string sql, StackTrace stackTrace)
        {
            LogIt(String.Format("Query:'{0}' threw exception:", sql));
            LogIt(ex.Message);
            LogIt(ex.StackTrace);

            //if ((stackTrace != null) && (LOG != null))
            //    LOG.LogCallStack(stackTrace);
            if (ex.InnerException != null)
                LogException(ex.InnerException, "SQL - inner Exception");
        }

        internal void LogException(Exception ex, string sql)
        {
            LogException(ex, sql, new StackTrace());
        }

        public string GetParamname(string token)
        {
            return CommonCommand.GetParamname(token, this.DBType);
        }

        public string GetSetupParParameter(string key, string defaultval = "")
        {
            var value = defaultval;
            Boolean read = false;
            using (var reader = this.GetReader(String.Format("SELECT * FROM setup_par WHERE schluessel ='{0}'", key)))
            {
                if (reader != null)
                {
                    if (reader.Read())
                    {
                        value = reader.GetString("Wert");
                        read = true;
                    }
                }
            }
            if (!read && !String.IsNullOrEmpty(defaultval))
                SafeDBWrite(
                    String.Format(
                        "INSERT INTO SETUP_PAR (NR, Schluessel, Wert, testwert) SELECT MAX(NR) + 1, '{0}', '{1}', '{1}' FROM SETUP_PAR",
                        key, defaultval));
            return value;
        }

        public bool SafeExecuteCommand(CommonCommand cmd)
        {
            try
            {
                return cmd.ExecuteNonQuery() > -1;                
            }
            catch (Exception ex)
            {
               // HandleDBException(ex, cmd.CommandText);
                this.LogException(ex, "Safe Executing Command", new StackTrace());
                return false;
            }
        }

        public bool SafeExecuteCommand(IDbCommand cmd)
        {
            if(cmd is CommonCommand)
            {
                return this.SafeExecuteCommand((CommonCommand)cmd);
            }

            try
            {
                cmd.Connection.Open();
                cmd.ExecuteNonQuery();
                cmd.Connection.Close();
                return true;
            }
            catch (Exception ex)
            {
                //HandleDBException(ex, cmd.CommandText);
                this.LogException(ex, "Safe Executing Command", new StackTrace());
                return false;
            }
        }
    }
}
