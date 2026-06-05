using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Common;
using System.Diagnostics;
using System.Globalization;
using System.Linq;
using System.Reflection;
using System.Text.RegularExpressions;
using static INCLUDIS.Utils.CommonDB.CommonDB;

namespace INCLUDIS.Utils.CommonDB
{
    public class CommonCommand : IDisposable, IDbCommand
    {
        public DatabaseType DbType { get; private set; }

        private bool Unicode { get; set; }

        /// <summary>
        /// Gets or sets the command text. Parses the command text to be correct for the <see cref="DbType"/>
        /// </summary>
        /// <value>
        /// The command text.
        /// </value>
        public string CommandText { get { return this.Command.CommandText; } set { this.Command.CommandText = this.Parse(value); } }

        internal DbCommand Command;
        public DbProviderFactory Factory { get; private set; }
        public string ConnectionString { get; private set; }

        public DbParameterCollection Parameters { get { return this.Command.Parameters; } }

        private Log.Log Log;

        public Action<string> LogExternal { get; set; }
        public IDbConnection Connection { get => ((IDbCommand)Command).Connection; set => ((IDbCommand)Command).Connection = value; }
        public IDbTransaction Transaction { get => ((IDbCommand)Command).Transaction; set => ((IDbCommand)Command).Transaction = value; }
        public int CommandTimeout { get => ((IDbCommand)Command).CommandTimeout; set => ((IDbCommand)Command).CommandTimeout = value; }
        public CommandType CommandType { get => ((IDbCommand)Command).CommandType; set => ((IDbCommand)Command).CommandType = value; }

        IDataParameterCollection IDbCommand.Parameters => ((IDbCommand)Command).Parameters;

        public UpdateRowSource UpdatedRowSource { get => ((IDbCommand)Command).UpdatedRowSource; set => ((IDbCommand)Command).UpdatedRowSource = value; }

        private string CommandInitializer = string.Empty;

        public CommonCommand(Log.Log log, DatabaseType dbType, DbProviderFactory factory, string connectionString, bool uniCode = false)
        {
            this.Log = log;
            this.DbType = dbType;
            this.Factory = factory;
            this.ConnectionString = connectionString;

            this.Command = this.Factory.CreateCommand();
            this.Command.Connection = this.Factory.CreateConnection();
            this.Command.Connection.ConnectionString = this.ConnectionString;


            switch (this.DbType)
            {
                case DatabaseType.dtMsSqlNet:
                case DatabaseType.dtMSSQL:
                    CommandInitializer = "set transaction isolation level read uncommitted"; // Transaction Level auf dirty read setzen
                    break;
                case DatabaseType.dtOracle:
                default:
                    break;
            }
        }

        internal void OpenConnection()
        {
            if (this.Command.Transaction == null)
            {
                this.Command.Connection.Open();

                if (this.CommandInitializer != null && !string.IsNullOrEmpty(this.CommandInitializer.Trim()))
                {
                    var command = this.Command.CommandText;
                    this.Command.CommandText = CommandInitializer;
                    this.Command.ExecuteNonQuery();
                    this.Command.CommandText = command;
                }
            }
        }

        internal void CloseConnection(bool forceClose = false)
        {
            if (this.Command.Transaction == null || forceClose) this.Command.Connection.Close();
        }

        public decimal ExecuteScalar(string aCommand)
        {
            decimal i = 0;
            string parsedCommand = "";
            try
            {
                parsedCommand = Parse(aCommand);
                this.Command.CommandText = parsedCommand;
                this.OpenConnection();
                var s = this.Command.ExecuteScalar();
                if (!Decimal.TryParse(s.ToString(), out i))
                    i = 0;
            }
            catch (Exception ex)
            {
                HandleDBException(ex, aCommand + '/' + parsedCommand);
                this.LogCommand(this.Command);
            }
            finally
            {
                this.CloseConnection();
            }

            return i;
        }

        public object ExecuteScalar()
        {
            object i = DBNull.Value;
            string parsedCommand = "";
            try
            {
                this.OpenConnection();
                i = this.Command.ExecuteScalar();
            }
            catch (Exception ex)
            {
                HandleDBException(ex, this.Command.CommandText + '/' + parsedCommand);
                this.LogCommand(this.Command);
            }
            finally
            {
                this.CloseConnection();
            }

            return i;
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
            string parsedCommand = aCommand;
            try
            {
                this.CommandText = this.Parse(aCommand, args);
                this.Command.CommandTimeout = timeout;
                this.OpenConnection();
                var i = this.Command.ExecuteNonQuery();
                return i;
            }
            catch (Exception ex)
            {
                HandleDBException(ex, aCommand + '/' + parsedCommand);
                this.LogCommand(this.Command);

                return -1;
            }
            finally
            {
                this.CloseConnection();
            }
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

        public int ExecuteNonQuery()
        {
            return this.ExecuteNonQuery(this.Command.CommandText);
        }

        /// <summary>
        /// Creates new parameter.
        /// </summary>
        /// <param name="aName">The parameter versoin of the name.</param>
        /// <param name="aType">a type of the data.</param>
        /// <param name="aValue">The value for the parameter.</param>
        /// <returns></returns>
        public DbParameter NewParameter(string aName, DbType aType, object aValue = null)
        {
            var parameter = this.Factory.CreateParameter();

            if (parameter != null)
            {
                parameter.DbType = aType;
                parameter.ParameterName = aName;
                if (aValue != null) parameter.Value = aValue;
            }

            return parameter;
        }

        /// <summary>
        /// Adds the parameter to the command.
        /// </summary>
        /// <param name="aName">The name, this is converted to a Parametername using <see cref="GetParamname(string)"/>.</param>
        /// <param name="aType">The type of data.</param>
        /// <param name="aValue">The value of the parameter.</param>
        public void AddParameter(string aName, DbType aType, object aValue = null)
        {
            this.Parameters.Add(this.NewParameter(this.GetParamname(aName), aType, aValue));
        }

        public bool SafeParamCmdExecution<T>(string baseSql, List<CmdParam<T>> parameterList, List<T> dataList, bool parsePrior)
        {
            try
            {
                var sParams = parameterList.Select(p => GetParamname(p.FieldName) as object).ToArray();
                using (var cmd = this.Command)
                {
                    cmd.CommandText = String.Format(baseSql, sParams);
                    //if (parsePrior)
                    //    cmd.CommandText = Parse(cmd.CommandText);

                    foreach (var p in parameterList)
                        cmd.Parameters.Add(NewParameter(p.FieldName, p.FieldType));
                    foreach (var o in dataList)
                    {
                        foreach (var p in parameterList)
                        {
                            try
                            {
                                var param = cmd.Parameters[p.FieldName];
                                if (param != null)
                                {
                                    var prop = (PropertyInfo)p.MemberExpression.Member;
                                    param.Value = prop.GetValue(o, null);
                                }
                            }
                            catch (Exception ex)
                            {
                                HandleDBException(ex,
                                    "Assigning parameter '" + p.FieldName + "' to query '" + cmd.CommandText + "'",
                                    new StackTrace());
                            }
                        }

                        try
                        {
                            this.OpenConnection();
                            cmd.ExecuteNonQuery();
                        }
                        catch (Exception ex)
                        {
                            HandleDBException(ex, "Executing Command", new StackTrace());
                            LogCommand(cmd);
                            return false;
                        }
                        finally
                        {
                            this.CloseConnection();
                        }
                    }
                }
                return true;
            }
            catch (Exception ex)
            {
                HandleDBException(ex, "Executing Command for a List of objects", new StackTrace());
                return false;
            }
        }

        #region Readers

        public CommonReader GetReader(CommandBehavior behaviour)
        {
            // logging is now down in the Reader
            //try
            //{                
            return new CommonReader(this, behaviour);
            //}
            //catch (Exception ex)
            //{
            //    HandleDBException(ex, "Executing reader", new StackTrace());
            //    LogCommand(this.Command);
            //    this.CloseConnection();
            //    throw;
            //}
        }

        public CommonReader GetReader(string command = null)
        {
            // logging is now down in the Reader
            //try
            //{
            if (command != null && !string.IsNullOrEmpty(command.Trim())) this.CommandText = command;
            return new CommonReader(this);
            //}
            //catch (Exception ex)
            //{
            //    HandleDBException(ex, "Executing reader", new StackTrace());
            //    LogCommand(this.Command);
            //    this.CloseConnection();
            //    throw;
            //}
        }

        #endregion

        #region Transactions
        public bool BeginTransaction()
        {
            try
            {
                this.OpenConnection();
                this.Command.Transaction = this.Command.Connection.BeginTransaction();
                return true;
            }
            catch (Exception ex)
            {
                HandleDBException(ex, "Beginning Transaction");
                return false;
            }
        }

        public bool RollbackTransaction()
        {
            var result = true;
            try
            {
                this.Command.Transaction.Rollback();
                result = true;
            }
            catch (Exception ex)
            {
                HandleDBException(ex, "Rollback Transaction");
                result = false;
            }
            finally
            {
                this.CloseConnection(true);
            }

            return result;
        }

        public bool CommitTransaction()
        {

            var result = true;
            try
            {
                this.Command.Transaction.Commit();
                result = true;
            }
            catch (Exception ex)
            {
                HandleDBException(ex, "Beginning Transaction");
                result = false;
            }
            finally
            {
                this.CloseConnection(true);
            }

            return result;
        }
        #endregion

        #region Query parsing
        public static string Parse(string query, DatabaseType srcDbType, DatabaseType dstDbType, bool unicode = false)
        {
            return CommonCommand.Parse(query, null, srcDbType, dstDbType, unicode);
        }

        public static string Parse(string query, object[] args, DatabaseType srcDbType, DatabaseType dstDbType, bool unicode = false)
        {
            if (args != null && args.Length > 0)
            {
                query = string.Format(CultureInfo.InvariantCulture, query, args);
            }

            string parsedResult = query;

            if (new[] { DatabaseType.dtMSSQL }.Contains(dstDbType) && (srcDbType == DatabaseType.dtOracle))
            {
                if (query.ToUpper().Contains("ID.NEXTVAL"))
                {
                    if (false)
                    {
                        var pos = query.ToUpper().IndexOf("ID.NEXTVAL", 0, StringComparison.Ordinal);
                        var firstpart = query.Substring(0, pos);
                        var secondpart = query.Substring(pos + 10);
                        var pos2 = firstpart.LastIndexOf(' ');
                        if (firstpart.LastIndexOf('(') > pos2)
                        {
                            pos2 = firstpart.LastIndexOf('(');
                        }
                        var table = firstpart.Substring(pos2 + 1);
                        parsedResult = firstpart.Substring(0, pos2 + 1) + "DBO.NEXTVAL('" + table + "') " + secondpart;
                        if (!parsedResult.EndsWith(";"))
                        {
                            parsedResult += ";";
                        }
                        parsedResult += "EXECUTE SETNEXTVAL @SNAME='" + table + "'";
                        parsedResult = "BEGIN TRAN T1; " + parsedResult + "; COMMIT TRAN T1;";
                    }
                    else
                    {
                        // Neues Konstrukt ML 24.01.2022
                        // EXECNEXTVAL ist Teil der Transaction und damit hoffentlich endgültig Thread-safe.
                        var pos = query.ToUpper().IndexOf("ID.NEXTVAL", 0, StringComparison.Ordinal);
                        var firstpart = query.Substring(0, pos);
                        var secondpart = query.Substring(pos + 10);
                        var pos2 = firstpart.LastIndexOf(' ');
                        if (firstpart.LastIndexOf('(') > pos2)
                        {
                            pos2 = firstpart.LastIndexOf('(');
                        }
                        var table = firstpart.Substring(pos2 + 1);
                        parsedResult = firstpart.Substring(0, pos2 + 1) + "@TABNEXTVALXX" + secondpart;
                        if (!parsedResult.EndsWith(";"))
                        {
                            parsedResult += ";";
                        }
                        parsedResult = "BEGIN TRAN T1; " +
                            "DECLARE @TABNEXTVALXX INTEGER; " +
                            "EXECUTE GETNEXTVAL '" + table + "', @CURRVAL=@TABNEXTVALXX OUTPUT " + 
                             parsedResult + "; " +
                             "COMMIT TRAN T1;";
                    }

                }
                // BITAND gibt es nur in Oracle  BITAND(X,Y) gegen ( X & Y ) ersetzen
                while (parsedResult.ToUpper().Contains("BITAND"))
                {
                    var pos = parsedResult.ToUpper().IndexOf("BITAND", 0, StringComparison.Ordinal);
                    parsedResult = parsedResult.Remove(pos, 6);
                    var pos2 = parsedResult.IndexOf(",", pos, StringComparison.Ordinal); // , durch & ersetzen
                    parsedResult = parsedResult.Remove(pos2, 1);
                    parsedResult = parsedResult.Insert(pos2, " & ");
                }
                /* //FUNKTIONIERT SO LEIDER NICHT
                if (OriginalQuery.ToUpper().Contains("CREATE OR REPLACE VIEW"))
                {
                    Int32 Pos = OriginalQuery.ToUpper().IndexOf("CREATE OR REPLACE VIEW", 0);
                    String firstpart = OriginalQuery.Substring(0, Pos);
                    String secondpart = OriginalQuery.Substring(Pos + 23);
                    Int32 Pos2 = secondpart.IndexOf(' ');
                    String Table = secondpart.Substring(0, Pos2);
                   ParsedResult = " DROP VIEW " + Table + "; CREATE VIEW " + secondpart;
                } */

                if (unicode)
                    parsedResult = UnicodeCompatibleQuery(parsedResult);
            }

            if ((dstDbType == DatabaseType.dtOracle) &&
                (srcDbType == DatabaseType.dtOracle))
            {
                if (unicode)
                    parsedResult = UnicodeCompatibleQuery(parsedResult);
            }
            var myReplist = new ReplaceableList();

            var rpts = myReplist.FindAll(rp => rp.DbTypes != null && rp.DbTypes.Contains(dstDbType));
            foreach (ReplaceableToken rpt in rpts)
            {
                Int32 I = parsedResult.ToUpper().IndexOf(rpt.OraOriginal.ToUpper(), StringComparison.Ordinal);
                while (I > -1)
                {
                    parsedResult = parsedResult.Substring(0, I) + rpt.Substitute + parsedResult.Substring(I + rpt.OraOriginal.Length);
                    I = parsedResult.ToUpper().IndexOf(rpt.OraOriginal.ToUpper(), StringComparison.Ordinal);
                }
            }
            return parsedResult;
        }
        private static string UnicodeCompatibleQuery(string parsedResult)
        {
            //string newString = Regex.Unescape(Regex.Replace(Regex.Escape(parsedResult), @"([\s,\(,\)])'([^',\s])|([^'])'(''')|([\s,\(,\)])'('')", @"$1$3$5N'$2$4$6"));
            /* //ab hier auskommentieren*/
            /*
            string newString = Regex.Replace(Regex.Escape(parsedResult), @"([\s,\(,\)])'([^',\s])|([^'])'(''')|([\s,\(,\)])'('')", @"$1$3$5N'$2$4$6");
            parsedResult = Regex.Replace(newString," varchar", " nvarchar",RegexOptions.IgnoreCase);
            parsedResult = Regex.Unescape(Regex.Replace(parsedResult, "to_char", "to_nchar", RegexOptions.IgnoreCase)).Replace(" '' ", " N'' ");
            */

            /* // neue Vorgehensweise?*/

            parsedResult = Regex.Replace(Regex.Escape(parsedResult), " varchar", " nvarchar", RegexOptions.IgnoreCase);
            parsedResult = Regex.Unescape(Regex.Replace(parsedResult, "to_char", "to_nchar", RegexOptions.IgnoreCase));

            // Zwischenspeichern
            var intermediate = parsedResult;

            // Wir haben noch kein "öffnendes" Hochkomma gefunden
            var opened = false;

            //Offset des Ergebnis-Strings gegenüber Eingangs-String (erhöht sich durch Einfügen der 'N')
            var offset = 0;

            //Unser 'Flag' für das aktuelle/letzte Zeichen
            var lastChar = ' ';

            //Gehe alle Zeichen des Eingangs-Strings durch
            for (int innerIndex = 0; innerIndex < parsedResult.Length; innerIndex++)
            {
                //ermittle den Index für den Egebnis-string
                var realIndex = innerIndex + offset;

                //Wenn das aktuelle Zeichen ein Hochkomma ist
                if (intermediate[realIndex] == '\'')
                {
                    //Wenn wir schon ein "öffnendes" Hochkomma gefunden haben
                    if (opened)
                    {
                        //Sicherheitshalber: ist der Index des Ergebnis-String innerhalb des Strings
                        if (realIndex + 1 < intermediate.Length)
                        {
                            // In Abhängigkeit vom Flag des letzten Zeichens
                            switch (lastChar)
                            {
                                //Das letzte Zeichen war das öffnende Hochkomma. Dann kommt hier entweder das Ende, oder der Anfang eines "escapeten" Hochkommas
                                case 'N':
                                    lastChar = 's';
                                    break;
                                //das letzte Zeichen war der Anfang eines "escapeten" Hochkommas; wir müssen also nichts tun
                                case 's':
                                    lastChar = ' ';
                                    break;
                                //wir haben beim letzten Zeichen kein Flag gesetzt
                                default:
                                    {
                                        if (intermediate[realIndex + 1] == '\'')
                                            //Das Folgezeichen ist ebenfalls ein Hochkomma, also wohl das Ende eines "escapeten" Hochkommas
                                            lastChar = 's';
                                        else
                                            //Wir haben ein "schließendes" Hochkomma gefunden
                                            opened = false;
                                    }
                                    break;
                            }
                        }
                        else
                            //Wir haben das Ende des Ergebnis-STrings erreicht. Das hier müsste also ein schließendes Hochkomma sein (oder ein Fehler)
                            opened = false;
                    }
                    else
                    {
                        //Wir haben ein "öffnendes" Hochkomma gefunden; Merken...
                        lastChar = 'N';
                        //... im Ergebnis-String ein entsprechendes 'N' einfügen...
                        intermediate = intermediate.Insert(realIndex, "N");
                        //... den Offset zwischen Ergebnis- und Eingangs-String erhöhen...
                        offset++;
                        //... und den "Merker" setzen
                        opened = true;
                    }
                }
                else
                {
                    //Wir dachten, dass letzte Zeichen wäre der Anfang eines escapten Hochkommas, lagen damit aber falsch
                    if (lastChar == 's')
                        opened = false;
                    //Das aktuelle Zeichen ist kein Hochkomma, also Flag entsprechend zurücksetzen
                    lastChar = ' ';
                }
            }
            return intermediate;
            /* Ende neue Vorgehensweise ?*/
        }


        public string Parse(string originalQuery, params object[] args)
        {

            return Parse(originalQuery, args, DatabaseType.dtOracle, DbType, this.Unicode);
        }

        #endregion

        #region Helpers

        public string GetParamname(string token)
        {
            return CommonCommand.GetParamname(token, this.DbType);
        }

        public static string GetParamname(string token, DatabaseType dbType)
        {
            switch (dbType)
            {
                case DatabaseType.dtMSSQL:
                case DatabaseType.dtMsSqlNet:
                    return "@" + token;
                case DatabaseType.dtOracle:
                case DatabaseType.dtOracleNet:
                    return ":" + token;
                default:
                    return token;
            }
        }
        #endregion

        #region Logging



        internal void HandleDBException(Exception ex, string sql, StackTrace stackTrace)
        {
            LogIt(String.Format("Query:'{0}' threw exception:", sql));
            LogIt(ex.Message);
            LogIt(ex.StackTrace);

            if ((stackTrace != null) && (Log != null))
                Log.LogCallStack(stackTrace);
            if (ex.InnerException != null)
                HandleDBException(ex.InnerException, "SQL - inner Exception");
        }

        internal void HandleDBException(Exception ex, string sql)
        {
            HandleDBException(ex, sql, new StackTrace());
        }

        private void LogIt(string message)
        {
            if (Log != null)
                Log.LogSome(message);
            LogExternal?.Invoke(message);
        }

        internal void LogCommand()
        {
            this.LogCommand(this.Command);
        }

        internal void LogCommand(DbCommand cmd)
        {
            try
            {
                if (Log != null)
                    Log.LogSome(cmd.GetCommandLogString());
                LogExternal?.Invoke(cmd.GetCommandLogString());
            }
            catch (Exception exception)
            {
                if (Log != null)
                    Log.LogException(exception, "Logging Command ");
                throw;
            }
        }
        #endregion

        #region IDbCommand implementations
        public void Prepare()
        {
            ((IDbCommand)Command).Prepare();
        }

        public void Cancel()
        {
            ((IDbCommand)Command).Cancel();
        }

        public IDbDataParameter CreateParameter()
        {
            return ((IDbCommand)Command).CreateParameter();
        }

        public IDataReader ExecuteReader()
        {
            return this.GetReader();
        }

        public IDataReader ExecuteReader(CommandBehavior behavior)
        {
            return this.GetReader(behavior);
            //return ((IDbCommand)Command).ExecuteReader(behavior);
        }
        #endregion

        #region Disposal
        public void Dispose()
        {
            if (this.Command != null && this.Command.Connection != null && this.Command.Connection.State == ConnectionState.Open)
            {
                this.CloseConnection(true);
            }

            this.Parameters.Clear();
        }

        #endregion
    }
}
