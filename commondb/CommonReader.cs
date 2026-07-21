using System;
using System.Data.Common;
using System.Data;
using System.Collections.Generic;
//using INCLUDIS.Utils.Log;
using System.Diagnostics;

namespace INCLUDIS.Utils.CommonDB
{
    /// <summary>
    /// Klasse CommonReader zur einfachen Verwendung von Feldnamen
    /// </summary>
    public class CommonReader : IDataReader, IDisposable
    {
        public DbDataReader Reader;
        private readonly CommonCommand _command;
        public CommonCommand Command { get { return _command; } }
        //private readonly DataTable _table;
        //public static Log.Log Log;

        public CommonReader(CommonCommand cmd) : this(cmd, CommandBehavior.Default)
        {
        }
        /// <summary>
        /// Contains for each Field the Ordinal position
        /// </summary>
        private Dictionary<string, int> fieldCache = new Dictionary<string, int>();

        /// <summary>
        /// Konstruktor der Klasse
        /// </summary>
        /// <param name="cmd">DbCommand das übergeben wird.</param>
        public CommonReader(CommonCommand cmd, CommandBehavior? behaviour = null)
        {
            _command = cmd;            

            try
            {
                this._command.OpenConnection();
                if (behaviour.HasValue) 
                    Reader = cmd.Command.ExecuteReader(behaviour.Value);
                else Reader = cmd.Command.ExecuteReader();
            }
            catch (Exception ex)
            {
                cmd.HandleDBException(ex, "Executing reader", new StackTrace());
                cmd.LogCommand();
                try
                {
                    cmd.CloseConnection();
                }
                catch (Exception) { }
                //throw;
            }
        }

        public void LogException(Exception ex, string cause, DbCommand cmd)
        {
            //if (Log == null)
            //    return;

            //Log.LogException(ex, cause);
            //Log.LogSome(Environment.StackTrace);
            LogCommand(cmd ?? _command.Command);
        }

        private void LogIt(string message, DbCommand cmd)
        {
            //if (Log == null)
            //    return;
            //Log.LogSome(message);
            LogCommand(cmd);
        }

        private void LogCommand(DbCommand cmd)
        {
            //if (Log != null)
            //{
            //    if (cmd != null)
            //    {
            //        try
            //        {
            //            Log.LogSome(cmd.GetCommandLogString());
            //        }
            //        catch (Exception exception)
            //        {
            //            Log.LogException(exception, "Logging Command ");
            //        }
            //    }
            //    else if (_command != null)
            //    {
            //        try
            //        {
            //            Log.LogSome(_command.GetCommandLogString());
            //        }
            //        catch (Exception exception)
            //        {
            //            Log.LogException(exception, "Logging Command ");
            //        }
            //    }
            //}
        }

        public object GetField(string fieldName)
        {
            try
            {
                //if (_table != null && _table.Columns.Contains(fieldName))
                if (this.HasField(fieldName))
                {
                    var o = Reader != null ? Reader[fieldName] : null;
                    return o;
                }

                LogException(new Exception("Field " + fieldName + " does not exist in reader."), String.Format("Getting field '{0}' from reader", fieldName), null);
                return null;
                //else
            }
            catch (Exception ex)
            {
                LogException(ex, String.Format("Getting field '{0}' from reader", fieldName), null);
                return null;
            }
        }




        public String GetString(string fieldName)
        {
            object o = null;
            try
            {
                o = GetField(fieldName);
                return o == null ? String.Empty : o.ToString();
            }
            catch (Exception ex)
            {
                LogException(ex, String.Format("Getting string field '{0}' from reader ({1})", fieldName, o == null ? "null" : "not null"), null);
                return String.Empty;
            }
        }

        public Int64 GetInt64(string fieldName)
        {
            object o = null;
            Int64 value = 0;

            if (IsDBNull(fieldName) || String.IsNullOrEmpty(GetString(fieldName)))
                return value;
            try
            {
                o = GetField(fieldName);
                var s = o.ToString();
                if (Int64.TryParse(s, out value))
                    return value;
                //else
                LogIt(String.Format("Could not parse field '{0}' with string value '{1}' as a Int64", fieldName, s), null);
                return 0;
            }
            catch (Exception ex)
            {
                LogException(ex, String.Format("Getting Int64 field '{0}' from reader ({1})", fieldName, o == null ? "null" : "not null"), null);
                return value;
            }
        }

        public UInt64 GetUInt64(string fieldName)
        {
            object o = null;
            UInt64 value = 0;

            if (IsDBNull(fieldName) || String.IsNullOrEmpty(GetString(fieldName)))
                return value;
            try
            {
                o = GetField(fieldName);
                var s = o.ToString();
                if (UInt64.TryParse(s, out value))
                    return value;
                //else
                LogIt(String.Format("Could not parse field '{0}' with string value '{1}' as a UInt64", fieldName, s), null);
                return 0;
            }
            catch (Exception ex)
            {
                LogException(ex, String.Format("Getting UInt64 field '{0}' from reader ({1})", fieldName, o == null ? "null" : "not null"), null);
                return value;
            }
        }
        public Int32 GetInt32(string fieldName)
        {
            if (Reader == null)
                return 0;
            object o = null;
            Int32 value = 0;

            if (IsDBNull(fieldName) || String.IsNullOrEmpty(GetString(fieldName)))
                return value;
            try
            {
                o = GetField(fieldName);
                var s = o.ToString();
                if (Int32.TryParse(s, out value))
                    return value;
                //else
                LogIt(String.Format("Could not parse field '{0}' with string value '{1}' as a Int32", fieldName, s), null);
                return 0;
            }
            catch (Exception ex)
            {
                try
                {
                    o = Reader.GetProviderSpecificValue(GetOrdinal(fieldName));
                    var s = o.ToString();
                    if (Int32.TryParse(s, out value))
                        return value;
                    //else
                    LogIt(String.Format("Could not parse field '{0}' with string value '{1}' as a Int32",
                                        fieldName, s), null);
                    return 0;
                }
                catch (Exception exI)
                {
                    LogException(ex, String.Format("Getting Int32 field '{0}' from reader ({1})", fieldName,
                                               o == null ? "null" : "not null"), null);
                    LogException(exI,
                                 String.Format("Getting Int32 field '{0}' from reader ({1})", fieldName,
                                               o == null ? "null" : "not null"), null);
                    return value;
                }
            }
        }


        public Int16 GetInt16(string fieldName)
        {
            object o = null;
            Int16 value = 0;

            if (IsDBNull(fieldName) || String.IsNullOrEmpty(GetString(fieldName)))
                return value;
            try
            {
                o = GetField(fieldName);
                var s = o.ToString();
                if (Int16.TryParse(s, out value))
                    return value;
                //else
                LogIt(String.Format("Could not parse field '{0}' with string value '{1}' as a Int16", fieldName, s), null);
                return 0;
            }
            catch (Exception ex)
            {
                LogException(ex, String.Format("Getting Int16 field '{0}' from reader ({1})", fieldName, o == null ? "null" : "not null"), null);
                return value;
            }
        }

        public Double GetDouble(string fieldName)
        {
            object o = null;
            Double value = 0;
            if (Reader == null)
                return value;

            if (IsDBNull(fieldName) || String.IsNullOrEmpty(GetString(fieldName)))
                return value;
            try
            {
                o = GetField(fieldName);
                var s = o.ToString();
                if (Double.TryParse(s, out value))
                    return value;
                //else
                LogIt(String.Format("Could not parse field '{0}' with string value '{1}' as a Double", fieldName, s), null);
                return 0;
            }
            catch (Exception ex)
            {
                try
                {
                    o = Reader.GetProviderSpecificValue(GetOrdinal(fieldName));
                    var s = o.ToString();
                    if (Double.TryParse(s, out value))
                        return value;
                    //else
                    LogIt(String.Format("Could not parse field '{0}' with string value '{1}' as a Double",
                                        fieldName, s), null);
                    return 0;
                }
                catch (Exception exI)
                {
                    LogException(ex, String.Format("Getting Double field '{0}' from reader ({1})", fieldName,
                                               o == null ? "null" : "not null"), null);
                    LogException(exI, String.Format("Getting Double field '{0}' from reader ({1})", fieldName,
                                               o == null ? "null" : "not null"), null);
                    return value;
                }
            }
        }

        public decimal GetDecimal(string fieldName)
        {
            object o = null;
            decimal value = 0;

            if (IsDBNull(fieldName) || String.IsNullOrEmpty(GetString(fieldName)))
                return value;
            try
            {
                o = GetField(fieldName);
                var s = o.ToString();
                if (decimal.TryParse(s, out value))
                    return value;
                //else
                LogIt(String.Format("Could not parse field '{0}' with string value '{1}' as a decimal", fieldName, s), null);
                return 0;
            }
            catch (Exception ex)
            {
                LogException(ex, String.Format("Getting decimal field '{0}' from reader ({1})", fieldName, o == null ? "null" : "not null"), null);
                return value;
            }
        }

        public Single GetSingle(string fieldName)
        {
            object o = null;
            Single value = 0;

            if (IsDBNull(fieldName) || String.IsNullOrEmpty(GetString(fieldName)))
                return value;
            try
            {
                o = GetField(fieldName);
                var s = o.ToString();
                if (Single.TryParse(s, out value))
                    return value;
                //else
                LogIt(String.Format("Could not parse field '{0}' with string value '{1}' as a Single", fieldName, s), null);
                return 0;
            }
            catch (Exception ex)
            {
                LogException(ex, String.Format("Getting Single field '{0}' from reader ({1})", fieldName, o == null ? "null" : "not null"), null);
                return value;
            }
        }

        public Object GetValue(string fieldName)
        {
            return GetField(fieldName);
        }

        public DateTime GetDateTime(string fieldName)
        {
            if (IsDBNull(fieldName))
                return new DateTime();
            try { return Convert.ToDateTime(GetValue(fieldName)); }
            catch { return new DateTime(); }
        }

        public DateTime GetDateTimeFromOA(string fieldName)
        {
            if (IsDBNull(fieldName))
                return DateTime.FromOADate(0);

            try { return DateTime.FromOADate(Convert.ToDouble(GetValue(fieldName))); }
            catch { return DateTime.FromOADate(0); }
        }

        public Guid GetGuid(string fieldName)
        {
            object o = null;
            Guid value = Guid.Empty;

            if (IsDBNull(fieldName) || String.IsNullOrEmpty(GetString(fieldName)))
                return value;
            try
            {
                o = GetField(fieldName);

                // auf oracle kommt hier ein string  zurück, auf sql server kommt direkt eine guid
                if (Command !=  null)
                    if (Command.DbType == CommonDB.DatabaseType.dtOracleNet ||
                        Command.DbType == CommonDB.DatabaseType.dtOracle)
                        if(o != null)
                            if (o is string oString)
                            {
                                // manchmal kommt bei oracle dann doch ein string wo die minuszeichen enthalten sind
                                oString = oString.Replace("-", string.Empty);
                                if (oString.Length == 32)
                                {
                                    var result =
                                        $"{oString.Substring(0, 8)}-{oString.Substring(7, 4)}-{oString.Substring(11, 4)}-{oString.Substring(15, 4)}-{oString.Substring(19, 12)}";
                                    o = new Guid(result);
                                }
                            }

                if (!(o is Guid))
                {
                    //else
                    LogIt($"Could not parse field '{fieldName}' with string value '{o}' as a Guid", null);
                    return Guid.Empty;
                }
                return (Guid)o ;

            }
            catch (Exception ex)
            {
                LogException(ex, String.Format("Getting Guid field '{0}' from reader ({1})", fieldName, o == null ? "null" : "not null"), null);
                return value;
            }
        }
        /// <summary>
        /// Synonym for <see cref="CommonReader.GetDateTimeFromOA(string)"/>
        /// </summary>
        /// <param name="fieldName">The name of the field</param>
        /// <returns>The datetime from a OA Field</returns>
        public DateTime GetDateTimeFromINCL(string fieldName)
        {
            return this.GetDateTimeFromOA(fieldName);
        }

        public float GetFloat(string fieldName)
        {
            if (IsDBNull(fieldName))
                return 0;
            try { return Convert.ToSingle(GetValue(fieldName)); }
            catch
            {
                try { return Convert.ToSingle(Reader.GetProviderSpecificValue(GetOrdinal(fieldName))); }
                catch { return 0; }
            }
        }

        public void Close()
        {
            if (Reader != null)
                Reader.Close();
        }

        public int Depth
        {
            get { return Reader != null ? Reader.Depth : 0; }
        }

        public int FieldCount
        {
            get { return Reader != null ? Reader.FieldCount : 0; }
        }

        public T Get<T>(string columnName)
        {
            return Get(columnName, default(T));
        }

        public T Get<T>(string columnName, T defaultValue)
        {
            var value = GetField(columnName);
            return (value is T ? (T)value : defaultValue);
        }

        public bool GetBoolean(string fieldName)
        {
            if (Reader == null || IsDBNull(fieldName))
                return false;
            try { return Convert.ToBoolean(Reader[fieldName]); }
            catch { return false; }
        }

        public bool GetBoolean(int ordinal)
        {
            return Reader != null && Reader.GetBoolean(ordinal);
        }

        public byte GetByte(int ordinal)
        {
            return Reader != null ? Reader.GetByte(ordinal) : (byte)0;
        }

        public long GetBytes(int ordinal, long dataOffset, byte[] buffer, int bufferOffset, int length)
        {
            return Reader != null ? Reader.GetBytes(ordinal, dataOffset, buffer, bufferOffset, length) : 0;
        }

        public char GetChar(int ordinal)
        {
            return Reader != null ? Reader.GetChar(ordinal) : ' ';
        }

        public long GetChars(int ordinal, long dataOffset, char[] buffer, int bufferOffset, int length)
        {
            return Reader != null ? Reader.GetChars(ordinal, dataOffset, buffer, bufferOffset, length) : 0;
        }

        public string GetDataTypeName(int ordinal)
        {
            return Reader != null ? Reader.GetDataTypeName(ordinal) : "";
        }

        public DateTime GetDateTime(int ordinal)
        {
            return Reader != null ? Reader.GetDateTime(ordinal) : new DateTime(1899, 12, 31);
        }

        public IDataReader GetData(int i)
        {
            return Reader != null ? Reader.GetData(i) : null;
        }

        public decimal GetDecimal(int ordinal)
        {
            return Reader != null ? Reader.GetDecimal(ordinal) : 0;
        }

        public double GetDouble(int ordinal)
        {
            return Reader != null ? Reader.GetDouble(ordinal) : 0;
        }

        public System.Collections.IEnumerator GetEnumerator()
        {
            return Reader != null ? Reader.GetEnumerator() : null;
        }

        public Type GetFieldType(int ordinal)
        {
            return Reader != null ? Reader.GetFieldType(ordinal) : typeof(Type);
        }

        public float GetFloat(int ordinal)
        {
            return Reader != null ? Reader.GetFloat(ordinal) : 0;
        }

        public Guid GetGuid(int ordinal)
        {
            return Reader != null ? Reader.GetGuid(ordinal) : new Guid();
        }

        public short GetInt16(int ordinal)
        {
            return Reader != null ? Reader.GetInt16(ordinal) : (short)0;
        }

        public int GetInt32(int ordinal)
        {
            if (Reader == null)
                return 0;
            try
            {
                return Reader.GetInt32(ordinal);
            }
            catch
            {
                try
                {
                    return Int32.Parse(Reader.GetValue(ordinal).ToString());
                }
                catch
                {
                    {
                        return 0;
                    }
                }
            }
        }

        public long GetInt64(int ordinal)
        {
            return Reader != null ? Reader.GetInt64(ordinal) : 0;
        }

        public UInt64 GetUInt64(int ordinal)
        {
            object o = null;
            UInt64 value = 0;
            try
            {
                o = GetValue(ordinal);
                var s = o.ToString();
                if (UInt64.TryParse(s, out value))
                    return value;
                //else
                LogIt(String.Format("Could not parse field ordinal '{0}' with string value '{1}' as a UInt64", ordinal, s), null);
                return 0;
            }
            catch (Exception ex)
            {
                LogException(ex, String.Format("Getting UInt64 field ordinal '{0}' from reader ({1})", ordinal, o == null ? "null" : "not null"), null);
                return value;
            }
        }

        public string GetName(int ordinal)
        {
            return Reader.GetName(ordinal);
        }

        public int GetOrdinal(string name)
        {
            if (Reader == null || name == null)
                return -1;


            BuildFieldCache();
            var fieldName = name.ToUpper();
            if (fieldCache.ContainsKey(fieldName))
            {
                return fieldCache[fieldName];
            }

            return -1;
        }

        public bool HasField(string fieldName)
        {
            if (Reader == null || fieldName == null)
                return false;

            BuildFieldCache();
            return fieldCache.ContainsKey(fieldName.ToUpper());
        }

        // Stores all Field names in the FieldCach if the Cache is empty.
        private void BuildFieldCache()
        {
            if (fieldCache.Count == 0)
            {
                for (var i = 0; i < Reader.FieldCount; i++)
                {
                    string field = Reader.GetName(i).ToUpper();
                    if (!fieldCache.ContainsKey(field))
                    {
                        fieldCache.Add(field, i);
                    }
                }
            }
        }

        public DataTable GetSchemaTable()
        {
            return Reader != null ? Reader.GetSchemaTable() : null;
        }

        public string GetString(int ordinal)
        {
            return Reader != null ? Reader[ordinal].ToString() : "";
        }

        public object GetValue(int ordinal)
        {
            return Reader != null && ordinal < Reader.FieldCount ? Reader.GetValue(ordinal) : null;
        }

        public int GetValues(object[] values)
        {
            return Reader != null ? Reader.GetValues(values) : 0;
        }

        public bool HasRows
        {
            get { return Reader != null && Reader.HasRows; }
        }

        public bool IsClosed
        {
            get { return Reader == null || Reader.IsClosed; }
        }

        // ReSharper disable InconsistentNaming
        public bool IsDBNull(string fieldName)
        // ReSharper restore InconsistentNaming
        {
            if (Reader == null)
                return true;
            try
            {
                var i = GetOrdinal(fieldName);
                if (i > -1)
                    return IsDBNull(i);
                //else
                return true;
            }
            catch (Exception ex)
            {
                LogException(ex, String.Format("Checking whether field '{0}' is null in reader", fieldName), null);
                return true;
            }
        }

        // ReSharper disable InconsistentNaming
        public bool IsDBNull(int i)
        // ReSharper restore InconsistentNaming
        {
            if (Reader == null || Reader.GetProviderSpecificValue(i) == null)
                return true;
            return Reader.IsDBNull(i);
        }

        public bool NextResult()
        {
            return Reader != null && Reader.NextResult();
        }

        public bool Read()
        {
            if (Reader == null || Reader.IsClosed)
                return false;
            //else
            return Reader.Read();
        }

        public int RecordsAffected
        {
            get { return Reader != null ? Reader.RecordsAffected : 0; }
        }

        public object this[string name]
        {
            get { return Reader != null && this.HasField(name) ? Reader[name] : null; }
        }

        public object this[int ordinal]
        {
            get { return Reader != null && ordinal < Reader.FieldCount ? Reader[ordinal] : null; }
        }

        public int ReadAll(Action<CommonReader> action)
        {
            int count = 0;
            if (Reader != null)
            {
                while (Reader.Read())
                {
                    action(this);
                    count++;
                }
            }
            return count;
        }

        #region IDisposable Members

        public void Dispose()
        {
            if (Reader != null)
            {
                try
                {
                    this._command.Cancel();
                }
                catch (Exception) { }

                try
                {                    
                    Reader.Close();
                }
                catch (Exception ex) { this.LogException(ex, "Error closing the DbDataReader.", this._command.Command); };
            }

            this._command.CloseConnection();
            this._command.Parameters.Clear();
        }

        #endregion
    }
}
