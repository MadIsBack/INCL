using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Data.Common;
using System.Diagnostics;
using System.Linq;
using System.Reflection;
using System.Text;

namespace INCLUDIS.Utils.CommonDB.Attributed
{
    public abstract class AttributedClassList<T> : List<T>, IAttributedClassList where T : AttributedClass , new()
    {
        public static bool LogAllInnerExceptions;
        private string _tableName;
        private bool _isView;

        public string TableName => _tableName;

        //public enum PrimaryKeyGeneration
        //{
        //    None,
        //    PreInsert,
        //    OnInsert
        //}

        protected AttributedClassList()
        {
            SetTableName();
        }

        protected void LogEx(Exception ex, Log.Log lg, String action, CommonCommand cmd)
        {
            if (lg != null)
            {
                lg.LogSome(String.Format("action '{0}' threw the following exception", action));
                lg.LogSome(ex.Message);
                lg.LogSome(ex.StackTrace);
                if (cmd != null)
                {
                    //lg.LogCommand(cmd);
                    try
                    {
                        lg.LogSome(cmd.GetCommandLogString());
                    }
                    catch (Exception exception)
                    {
                        lg.LogException(exception, "Logging Command ");
                    }
                }

            }
        }

        private bool CheckIsView()
        {
            if (!_isView)
            {
                foreach (var customAttribute in GetType().GetCustomAttributes(true))
                {
                    var attribute = customAttribute as DbListAttribute;
                    if (attribute != null)
                    {
                        _tableName = attribute.TableName;
                        _isView = attribute.IsView;
                    }
                }
            }
            if (_isView)
            {
                //throw (new Exception(String.Format("You cannot update the view '{0}'", _tableName)));
                //Evtl. wenigsten Log-Ausgabe?
            }
            return _isView;
        }

        private void SetTableName()
        {
            if (_tableName != null)
                return;

            foreach (var customAttribute in GetType().GetCustomAttributes(true))
            {
                var attribute = customAttribute as DbListAttribute;
                if (attribute != null)
                {
                    _tableName = attribute.TableName;
                    _isView = attribute.IsView;
                }
            }
        }

        /// <summary>
        /// Get noch nicht !!!!
        /// </summary>
        /// <param name="cdb"></param>
        /// <param name="conditions"></param>
        protected AttributedClassList(CommonDB cdb, IEnumerable<DbCondition> conditions)
        {
            SetTableName();

            var sql = new StringBuilder("SELECT * FROM " + _tableName);
            bool firstcondition = true;
            foreach (var condition in conditions)
            {
                sql.Append(firstcondition ? " WHERE " : " AND ");
                firstcondition = false;

                sql.Append(condition.FieldName);
                sql.Append(condition.ConditionString);
                if (condition.IsLiteralType)
                    sql.Append(String.Format("'{0}'", condition.ConditionValue));
                else
                {
                    if ((condition.FieldType == DbType.Double) || (condition.FieldType == DbType.Single))
                        sql.Append(
                            Convert.ToDouble(condition.ConditionValue)
                                   .ToString(System.Globalization.CultureInfo.InvariantCulture));
                    if ((condition.FieldType == DbType.Int32) || (condition.FieldType == DbType.Int16))
                        sql.Append(
                            Convert.ToInt32(condition.ConditionValue)
                                   .ToString(System.Globalization.CultureInfo.InvariantCulture));
                }
            }
            using (var reader = cdb.GetReader(sql.ToString()))
            {
                Add((T) Activator.CreateInstance(typeof (T), reader));
            }

        }

        //TODO return type to bool to make sure the update was successfull
        public void DbUpdate(CommonDB cdb)
        {
            DbUpdate(cdb, null);
        }

        //TODO return type to bool to make sure the update was successfull
        public void DbUpdate(CommonDB cdb, DbConditionList conditions)
        {
            SetTableName();
            if (CheckIsView())
                return;
            var dbFieldAttributes = new Dictionary<string, DbFieldAttribute>();
            var propertyInfoList = new List<PropertyInfo>();
            var dbDefaults = new Dictionary<string, DefaultValueAttribute>();
            if (Count > 0)
            {
                foreach (var propertyInfo in this[0].GetType().GetProperties())
                {
                    propertyInfoList.Add(propertyInfo);
                    dbFieldAttributes.Add(propertyInfo.Name,
                        (DbFieldAttribute) Attribute.GetCustomAttribute(propertyInfo, typeof(DbFieldAttribute)));
                    dbDefaults.Add(propertyInfo.Name, (DefaultValueAttribute)
                        Attribute.GetCustomAttribute(propertyInfo, typeof(DefaultValueAttribute)));
                }
            }
            
            // Aufbauen des SQL Statements
            var sql = new StringBuilder("UPDATE " + _tableName + " SET ");
            var cmd = cdb.NewCommonCommand();
            if (Count > 0)
            {
                AttributedClass item = this[0];
                //foreach (PropertyInfo propertyInfo in item.GetType().GetProperties())
                foreach (PropertyInfo propertyInfo in propertyInfoList)
                {
                    var dbFieldAttribute = dbFieldAttributes[propertyInfo.Name];
                        //(DbFieldAttribute) Attribute.GetCustomAttribute(propertyInfo, typeof (DbFieldAttribute));
                    if (dbFieldAttribute != null)
                    {
                        //FIx RS: Es wir die Conditions auf null überprüft
                        Boolean includeCurrentAttribute;
                        if (conditions != null)
                            includeCurrentAttribute = !conditions.ConditionExists(dbFieldAttribute.DbFieldName);
                        else
                        {
                            if (dbFieldAttribute.IsPrimKey)
                            {
                                conditions = new DbConditionList
                                    {
                                        new DbCondition
                                            {
                                                Condition = DbCondition.ConditionType.Equals,
                                                FieldName = dbFieldAttribute.DbFieldName,
                                                FieldType = dbFieldAttribute.DbFieldType
                                            }
                                    };
                                includeCurrentAttribute = false;
                            }
                            else
                                includeCurrentAttribute = !dbFieldAttribute.IsAdditionalReadOnly;
                        }

                        if (includeCurrentAttribute)
                        {
                            sql.Append(dbFieldAttribute.DbFieldName);
                            sql.Append("=");
                            string paramname;
                            switch (cdb.DBType)
                            {
                                case CommonDB.DatabaseType.dtMSSQL:
                                case CommonDB.DatabaseType.dtMsSqlNet:
                                    paramname = "@" + dbFieldAttribute.DbFieldName;
                                    break;
                                case CommonDB.DatabaseType.dtOracleNet:
                                case CommonDB.DatabaseType.dtOracle:
                                    paramname = ":" + dbFieldAttribute.DbFieldName;
                                    break;
                                case CommonDB.DatabaseType.dtOdbc:
                                    paramname = "@" + dbFieldAttribute.DbFieldName;
                                    break;
                                default:
                                    paramname = dbFieldAttribute.DbFieldName;
                                    break;
                            }

                            sql.Append(paramname);
                            sql.Append(", ");
                            cmd.Parameters.Add(cdb.NewParameter(paramname,  (cdb.IsMssql && dbFieldAttribute.DbFieldType == DbType.UInt64) ? DbType.Int64 : dbFieldAttribute.DbFieldType));
                        }
                    }
                }
                sql.Remove(sql.Length - 2, 2);

                bool firstCondition = true;
                if (conditions != null)
                {
                    foreach (var condition in conditions)
                    {
                        sql.Append(firstCondition ? " WHERE " : " AND ");
                        firstCondition = false;
                        sql.Append(condition.FieldName);
                        sql.Append(condition.ConditionString);
                        string paramname;
                        switch (cdb.DBType)
                        {
                            case CommonDB.DatabaseType.dtMSSQL:
                            case CommonDB.DatabaseType.dtMsSqlNet:
                                paramname = "@" + condition.VarName;
                                break;
                            case CommonDB.DatabaseType.dtOracleNet:
                            case CommonDB.DatabaseType.dtOracle:
                                paramname = ":" + condition.VarName;
                                break;
                            case CommonDB.DatabaseType.dtOdbc:
                                paramname = "@" + condition.VarName;
                                break;
                            default:
                                paramname = condition.VarName;
                                break;
                        }
                        sql.Append(paramname);
                        sql.Append(", ");
                        cmd.Parameters.Add(cdb.NewParameter(paramname, (cdb.IsMssql && condition.FieldType == DbType.UInt64) ? DbType.Int64 : condition.FieldType, condition.ConditionValue));

                    }

                    if (conditions.Count > 0)
                        sql.Remove(sql.Length - 2, 2);
                }

                cmd.CommandText = cdb.Parse(sql.ToString());
                foreach (var item2 in this)
                {
                    //foreach (PropertyInfo propertyInfo in item2.GetType().GetProperties())
                    foreach (PropertyInfo propertyInfo in propertyInfoList)
                    {
                        var dbFieldAttribute = dbFieldAttributes[propertyInfo.Name];
                            //(DbFieldAttribute) Attribute.GetCustomAttribute(propertyInfo, typeof (DbFieldAttribute));
                        var dbDefault = dbDefaults[propertyInfo.Name];
                            //(DefaultValueAttribute)Attribute.GetCustomAttribute(propertyInfo, typeof (DefaultValueAttribute));
                        if (dbFieldAttribute != null)
                        {
                            if (!dbFieldAttribute.IsAdditionalReadOnly)
                            {
                                string paramname = string.Empty;
                                try
                                {
                                    switch (cdb.DBType)
                                    {
                                        case CommonDB.DatabaseType.dtMSSQL:
                                        case CommonDB.DatabaseType.dtMsSqlNet:
                                            paramname = "@" + dbFieldAttribute.DbFieldName;
                                            break;
                                        case CommonDB.DatabaseType.dtOracle:
                                            paramname = ":" + dbFieldAttribute.DbFieldName;
                                            break;
                                        case CommonDB.DatabaseType.dtOracleNet:
                                            paramname = dbFieldAttribute.DbFieldName;
                                            break;
                                        case CommonDB.DatabaseType.dtOdbc:
                                            paramname = "@" + dbFieldAttribute.DbFieldName;
                                            break;
                                        default:
                                            paramname = dbFieldAttribute.DbFieldName;
                                            break;
                                    }
                                    Object o = propertyInfo.GetValue(item2, null) ?? dbDefault.Value;
                                    if ((dbFieldAttribute.DbFieldType == DbType.String) ||
                                        (dbFieldAttribute.DbFieldType == DbType.StringFixedLength)
                                        || (dbFieldAttribute.DbFieldType == DbType.AnsiString) ||
                                        (dbFieldAttribute.DbFieldType ==
                                         DbType.AnsiStringFixedLength))
                                    {
                                        if (o == null)
                                        {
                                            cmd.Parameters[paramname].Value = "";
                                        }
                                        else
                                        {
                                            var s = o as string;
                                            if ((s.Length > dbFieldAttribute.DbFieldLength) &&
                                                (dbFieldAttribute.DbFieldLength > 0))
                                                cmd.Parameters[paramname].Value = s.Substring(0,
                                                    dbFieldAttribute.
                                                        DbFieldLength -
                                                    1);
                                            else
                                            {
                                                cmd.Parameters[paramname].Value = o;
                                            }
                                        }
                                    }
                                    else
                                    {
                                        if ((dbFieldAttribute.DbFieldType == DbType.DateTime) &&
                                            ((o as DateTime?) < DateTime.FromOADate(0)))
                                            cmd.Parameters[paramname].Value = DateTime.FromOADate(0);
                                        else
                                        {
                                            if ((dbFieldAttribute.DbFieldType == DbType.Guid)&&(!cdb.IsMssql))
                                            {
                                                // MS SQL nativ, Oracle ist String, wandeln nach Guid
                                                var guid = (Guid)o;
                                                cmd.Parameters[paramname].Value =  BitConverter.ToString(guid.ToByteArray()).Replace("-", string.Empty);
                                            }
                                            else
                                            {
                                                cmd.Parameters[paramname].Value = o;
                                            }
                                        }
                                    }
                                }
                                catch (Exception ex)
                                {
                                    LogEx(ex, cdb.LOG, String.Format("Adding parameter <{0}> to query", paramname), cmd);
                                }
                            }
                        }
                    }
                    try
                    {
                        cmd.ExecuteNonQuery();
                    }
                    catch (Exception ex)
                    {
                        LogEx(ex, cdb.LOG, String.Format("Executing query"), cmd);
                    }
                }
            }
        }

        //TODO return type to bool to make sure the delete was successfull
        public void DbDelete(CommonDB cdb, DbConditionList conditions)
        {
            SetTableName();
            if (CheckIsView())
                return;


            // Aufbauen des SQL Statements
            var sql = new StringBuilder("DELETE FROM " + _tableName + " ");
            CommonCommand cmd = cdb.NewCommonCommand();
            if (Count > 0)
            {
                if (conditions == null)
                {
                    conditions = new DbConditionList();
                    AttributedClass item = this[0];
                    conditions.AddRange(from propertyInfo in item.GetType().GetProperties()
                                        select (DbFieldAttribute) Attribute.GetCustomAttribute(propertyInfo, typeof (DbFieldAttribute))
                                        into dbFieldAttribute where dbFieldAttribute != null where dbFieldAttribute.IsPrimKey select new DbCondition
                                            {
                                                Condition = DbCondition.ConditionType.Equals, FieldName = dbFieldAttribute.DbFieldName, FieldType = dbFieldAttribute.DbFieldType
                                            });
                }

                bool firstCondition = true;
                foreach (var condition in conditions)
                {
                    sql.Append(firstCondition ? " WHERE " : " AND ");
                    firstCondition = false;
                    sql.Append(condition.FieldName);
                    sql.Append(condition.ConditionString);
                    string paramname;
                    switch (cdb.DBType)
                    {
                        case CommonDB.DatabaseType.dtMSSQL:
                        case CommonDB.DatabaseType.dtMsSqlNet:
                            paramname = "@" + condition.VarName;
                            break;
                        case CommonDB.DatabaseType.dtOdbc:
                            paramname = "@" + condition.VarName;
                            break;
                        default:
                            paramname = ":" + condition.VarName;
                            break;
                    }

                    sql.Append(paramname);
                    sql.Append(", ");
                    cmd.Parameters.Add(cdb.NewParameter(paramname, (cdb.IsMssql && condition.FieldType == DbType.UInt64) ? DbType.Int64 : condition.FieldType, condition.ConditionValue));

                }
                if (conditions.Count > 0)
                    sql.Remove(sql.Length - 2, 2);
            }

            cmd.CommandText = cdb.Parse(sql.ToString());
            foreach (var item in this)
            {
                foreach (PropertyInfo propertyInfo in item.GetType().GetProperties())
                {
                    var dbFieldAttribute =
                        (DbFieldAttribute) Attribute.GetCustomAttribute(propertyInfo, typeof (DbFieldAttribute));
                    if (dbFieldAttribute != null)
                    {
                        if (conditions.ConditionExists(dbFieldAttribute.DbFieldName))
                        {
                            string paramname = string.Empty;
                            try
                            {
                                switch (cdb.DBType)
                                {
                                    case CommonDB.DatabaseType.dtMsSqlNet:
                                    case CommonDB.DatabaseType.dtMSSQL:
                                        paramname = "@" + dbFieldAttribute.DbFieldName;
                                        break;
                                    case CommonDB.DatabaseType.dtOracle:
                                        paramname = ":" + dbFieldAttribute.DbFieldName;
                                        break;
                                    case CommonDB.DatabaseType.dtOracleNet:
                                        paramname = dbFieldAttribute.DbFieldName;
                                        break;
                                    case CommonDB.DatabaseType.dtOdbc:
                                        paramname = "@" + dbFieldAttribute.DbFieldName;
                                        break;
                                    default:
                                        paramname = dbFieldAttribute.DbFieldName;
                                        break;
                                }
                                Object o = propertyInfo.GetValue(item, null);
                                cmd.Parameters[paramname].Value = o;
                            }
                            catch (Exception ex)
                            {
                                LogEx(ex, cdb.LOG, String.Format("Adding parameter <{0}> to query", paramname), cmd);
                            }
                        }
                    }
                }
                try
                {
                    cmd.ExecuteNonQuery();
                }
                catch (Exception ex)
                {
                    LogEx(ex, cdb.LOG, String.Format("Executing query"), cmd);
                }
            }
        }

        private object GetParamvalFromProperty (PropertyInfo propertyInfo, T item, DbFieldAttribute dbFieldAttribute)
        {
            object paramVal;
            var dbDefault =
                (DefaultValueAttribute)
                Attribute.GetCustomAttribute(propertyInfo, typeof(DefaultValueAttribute));
            var o = propertyInfo.GetValue(item, null) ?? dbDefault.Value;
            if ((dbFieldAttribute.DbFieldType == DbType.String) ||
                (dbFieldAttribute.DbFieldType == DbType.StringFixedLength)
                || (dbFieldAttribute.DbFieldType == DbType.AnsiString) ||
                (dbFieldAttribute.DbFieldType ==
                 DbType.AnsiStringFixedLength))
            {
                if (o == null)
                {
                    paramVal = "";
                }
                else
                {
                    var s = o as string;
                    if ((s.Length > dbFieldAttribute.DbFieldLength) &&
                        (dbFieldAttribute.DbFieldLength > 0))
                        paramVal = s.Substring(0,
                            dbFieldAttribute.
                                DbFieldLength -
                            1);
                    else
                    {
                        paramVal = o;
                    }
                }
            }
            else
            {
                if ((dbFieldAttribute.DbFieldType == DbType.DateTime) &&
                    ((o as DateTime?) < DateTime.FromOADate(0)))
                    paramVal = DateTime.FromOADate(0);
                else
                    paramVal = o;
            }
            return paramVal;
        }

        //TODO return type to bool to make sure the insert was successfull
        public void DbInsert(CommonDB cdb)
        {
            DbInsert(cdb, true);
        }

        //TODO return type to bool to make sure the insert was successfull
        public void DbInsert(CommonDB cdb, bool generatePrimaryKey)
        {
            DbInsert(cdb, generatePrimaryKey ? AttributedEnums.PrimaryKeyGeneration.PreInsert : AttributedEnums.PrimaryKeyGeneration.None);
        }

        //TODO return type to bool to make sure the insert was successfull
        public void DbInsert(CommonDB cdb, AttributedEnums.PrimaryKeyGeneration typeOfGeneration)
        {
            var fields = new StringBuilder();
            var vals = new StringBuilder();
            var cmd = cdb.NewCommonCommand();
            SetTableName();
            if (CheckIsView())
                return;

            if (Count > 0)
            {
                var dbFieldAttributes = new Dictionary<string, DbFieldAttribute>();
                var propertyInfoList = new List<PropertyInfo>();
                var dbDefaults = new Dictionary<string, DefaultValueAttribute>();
                if (Count > 0)
                {
                    foreach (var propertyInfo in this[0].GetType().GetProperties())
                    {
                        propertyInfoList.Add(propertyInfo);
                        dbFieldAttributes.Add(propertyInfo.Name,
                            (DbFieldAttribute)Attribute.GetCustomAttribute(propertyInfo, typeof(DbFieldAttribute)));
                        dbDefaults.Add(propertyInfo.Name, (DefaultValueAttribute)
                            Attribute.GetCustomAttribute(propertyInfo, typeof(DefaultValueAttribute)));
                    }
                }

                if (typeOfGeneration == AttributedEnums.PrimaryKeyGeneration.PreInsert)
                {
                    GeneratePrimaryKeys(cdb, propertyInfoList, dbFieldAttributes);
                }

                AttributedClass item = this[0];
                //foreach (PropertyInfo propertyInfo in item.GetType().GetProperties())
                foreach (PropertyInfo propertyInfo in propertyInfoList)
                {
                    var dbFieldAttribute = dbFieldAttributes[propertyInfo.Name];
                        //(DbFieldAttribute) Attribute.GetCustomAttribute(propertyInfo, typeof (DbFieldAttribute));
                    if (dbFieldAttribute != null)
                    {
                        if (!dbFieldAttribute.IsAdditionalReadOnly)
                        {
                            fields.Append(dbFieldAttribute.DbFieldName);
                            fields.Append(", ");
                            if ((dbFieldAttribute.IsPrimKey) && (typeOfGeneration == AttributedEnums.PrimaryKeyGeneration.OnInsert))
                                vals.Append(_tableName + "id.nextval, ");
                            else
                            {
                                string paramname;
                                switch (cdb.DBType)
                                {
                                    case CommonDB.DatabaseType.dtMSSQL:
                                    case CommonDB.DatabaseType.dtMsSqlNet:
                                        paramname = "@" + dbFieldAttribute.DbFieldName;
                                        break;
                                    case CommonDB.DatabaseType.dtOracle:
                                        paramname = ":" + dbFieldAttribute.DbFieldName;
                                        break;
                                    case CommonDB.DatabaseType.dtOracleNet:
                                        paramname = ":" + dbFieldAttribute.DbFieldName;
                                        break;
                                    case CommonDB.DatabaseType.dtOdbc:
                                        paramname = "@" + dbFieldAttribute.DbFieldName;
                                        break;
                                    default:
                                        paramname = dbFieldAttribute.DbFieldName;
                                        break;
                                }
                                vals.Append(cdb.DBType == CommonDB.DatabaseType.dtOdbc ? "?" : paramname);
                                vals.Append(", ");
                                cmd.Parameters.Add(cdb.NewParameter(paramname, (cdb.IsMssql && dbFieldAttribute.DbFieldType == DbType.UInt64) ? DbType.Int64 : dbFieldAttribute.DbFieldType));
                            }
                        }
                    }
                }

                fields = fields.Remove(fields.Length - 2, 2);
                vals = vals.Remove(vals.Length - 2, 2);
                var sql =
                    new StringBuilder("INSERT INTO " + _tableName + " ( " + fields + ") VALUES (" + vals + ")");
                cmd.CommandText = cdb.Parse(sql.ToString());
                try
                {
                    foreach (var tup in this)
                    {
                        //foreach (PropertyInfo propertyInfo in tup.GetType().GetProperties())
                        foreach (PropertyInfo propertyInfo in propertyInfoList)
                        {
                            var dbFieldAttribute = dbFieldAttributes[propertyInfo.Name];
                                //(DbFieldAttribute)Attribute.GetCustomAttribute(propertyInfo, typeof (DbFieldAttribute));
                            if (dbFieldAttribute != null)
                            {
                                if (((!dbFieldAttribute.IsPrimKey) ||
                                     (typeOfGeneration != AttributedEnums.PrimaryKeyGeneration.OnInsert)) &&
                                    (!dbFieldAttribute.IsAdditionalReadOnly))
                                {
                                    string paramname = string.Empty;
                                    try
                                    {
                                        switch (cdb.DBType)
                                        {
                                            case CommonDB.DatabaseType.dtMSSQL:
                                            case CommonDB.DatabaseType.dtMsSqlNet:
                                                paramname = "@" + dbFieldAttribute.DbFieldName;
                                                break;
                                            case CommonDB.DatabaseType.dtOracle:
                                                paramname = ":" + dbFieldAttribute.DbFieldName;
                                                break;
                                            case CommonDB.DatabaseType.dtOracleNet:
                                                paramname = dbFieldAttribute.DbFieldName;
                                                break;
                                            case CommonDB.DatabaseType.dtOdbc:
                                                paramname = "@" + dbFieldAttribute.DbFieldName;
                                                break;
                                            default:
                                                paramname = dbFieldAttribute.DbFieldName;
                                                break;
                                        }


                                        Object o = propertyInfo.GetValue(tup, null);
                                        if ((dbFieldAttribute.DbFieldType == DbType.String) ||
                                            (dbFieldAttribute.DbFieldType == DbType.StringFixedLength)
                                            || (dbFieldAttribute.DbFieldType == DbType.AnsiString) ||
                                            (dbFieldAttribute.DbFieldType ==
                                             DbType.AnsiStringFixedLength))
                                        {
                                            if (o == null)
                                            {
                                                cmd.Parameters[paramname].Value = "";
                                            }
                                            else
                                            {
                                                var s = o as string;
                                                if ((s.Length > dbFieldAttribute.DbFieldLength) &&
                                                    (dbFieldAttribute.DbFieldLength > 0))
                                                    cmd.Parameters[paramname].Value = s.Substring(0,
                                                        dbFieldAttribute.
                                                            DbFieldLength -
                                                        1);
                                                else
                                                {
                                                    cmd.Parameters[paramname].Value = o;
                                                }
                                            }
                                        }
                                        else
                                        {
                                            if ((dbFieldAttribute.DbFieldType == DbType.DateTime) &&
                                                ((o as DateTime?) < DateTime.FromOADate(0)))
                                                cmd.Parameters[paramname].Value = DateTime.FromOADate(0);
                                            else
                                            {
                                                if (cdb.IsMssql && dbFieldAttribute.DbFieldType == DbType.UInt64)
                                                    cmd.Parameters[paramname].Value = Convert.ToInt64(o);
                                                else
                                                    cmd.Parameters[paramname].Value = o;
                                            }
                                        }
                                    }
                                    catch (Exception ex)
                                    {
                                            LogEx(ex, cdb.LOG, String.Format("Adding parameter <{0}> to query", paramname), cmd);
                                        // Zu Debug Zwecken
                                        //throw;
                                    }
                                }
                            }
                        }
                        cmd.ExecuteNonQuery();
                    }
                }
                catch (Exception ex)
                {
                    LogEx(ex, cdb.LOG, "Executing query", cmd);
                }
            }

        }

        /// <summary>
        /// PrimaryKeys aus DB erzeugen ohne zu schreiben
        /// </summary>
        public void GeneratePrimaryKeys(CommonDB cdb, List<PropertyInfo> propertyInfoList, Dictionary<string, DbFieldAttribute> dbFieldAttributes)
        {
            if (propertyInfoList==null)
                if (Count > 0)
                {
                    propertyInfoList = new List<PropertyInfo>();
                    propertyInfoList.AddRange(this[0].GetType().GetProperties());
                }
            if (dbFieldAttributes == null)
            {
                dbFieldAttributes = new Dictionary<string, DbFieldAttribute>();
                foreach (var propertyInfo in propertyInfoList)
                {
                    dbFieldAttributes.Add(propertyInfo.Name, (DbFieldAttribute)Attribute.GetCustomAttribute(propertyInfo, typeof(DbFieldAttribute)));
                }
            }
            Int32 c = 0;
            foreach (var tup in this)
            {
                c++;
                //foreach (PropertyInfo propertyInfo in tup.GetType().GetProperties())
                foreach (PropertyInfo propertyInfo in propertyInfoList)
                {
                    var dbFieldAttribute = dbFieldAttributes[propertyInfo.Name];
                        //(DbFieldAttribute) Attribute.GetCustomAttribute(propertyInfo, typeof (DbFieldAttribute));
                    if (dbFieldAttribute != null)
                    {
                        if (dbFieldAttribute.IsPrimKey)
                        {
                            string sql = "SELECT " + _tableName + "ID.Nextval nextnr FROM DUAL";
                            using (var reader = cdb.GetReader(sql))
                            {
                                if (reader != null)
                                {
                                    if (reader.Read())
                                    {
                                        if (propertyInfo.PropertyType == typeof (UInt64))
                                            propertyInfo.SetValue(tup, reader.GetUInt64(0), null);
                                        else
                                            propertyInfo.SetValue(tup, reader.GetInt32(0), null);
                                    }
                                }
                            }
                        }
                        if (dbFieldAttribute.IsSecondaryKeyBasedOnMaxValue)
                        {
                            string sql = String.Format("SELECT CASE WHEN  MAX({0})  IS NULL THEN 0 ELSE  MAX({0}) END nextnr FROM {1}", dbFieldAttribute.DbFieldName,
                                                       _tableName);
                            using (var reader = cdb.GetReader(sql))
                            {
                                if (reader != null)
                                {
                                    if (reader.Read())
                                    {
                                        if (!reader.IsDBNull(0))
                                        {
                                            if (propertyInfo.PropertyType == typeof(UInt64))
                                                propertyInfo.SetValue(tup, reader.GetUInt64(0) + (ulong)c, null);
                                            else
                                                propertyInfo.SetValue(tup, reader.GetInt32(0) + c, null);

                                        }
                                        else
                                        {
                                            var defValue =
                                                Attribute.GetCustomAttribute(propertyInfo,
                                                    typeof (DefaultValueAttribute)) as
                                                    DefaultValueAttribute;
                                            if (defValue != null) propertyInfo.SetValue(tup, defValue.Value, null);
                                        }
                                    }
                                }
                            }
                        }

                    }
                }
            }
        }

        private IEnumerable<string> GetFieldNames(IDataReader reader)
        {
            var list = new List<string>();
            for (int i = 0; i < reader.FieldCount; i++)
                list.Add(reader.GetName(i));
            return list;
        }

        private int GetPropIndex(string fieldname, List<DbFieldAttribute> atts)
        {
            for (int i = 0; i < atts.Count(); i++)
                if (atts[i] != null)
                    if (atts[i].DbFieldName.ToUpper() == fieldname.ToUpper())
                        return i;
            return -1;
        }

        public void FastFetch(CommonDB cdb, string whereclause = "")
        {
            var sql = String.Format("SELECT * FROM {0} {1}", _tableName,
                                    whereclause.ToUpper().Trim().StartsWith("WHERE") ? whereclause : string.Empty);
            
            using (var reader = cdb.GetReader(sql))
                if (reader != null)
                {
                    // Vorbeitung
                    var fieldNames = GetFieldNames(reader.Reader);
                    List<Action<T, object>> setterList = new List<Action<T, object>>();

                    // Aus den Feldnamen des Readers die "Property-Setter" erzeugen
                    // und in einem Array merken

                    var props = typeof (T).GetProperties();
                    var props2 = new List<PropertyInfo>();
                    //var fieldAtts = new DbFieldAttribute[props.Count()];
                    var fieldAtts = new List<DbFieldAttribute>();

                    for (int i = 0; i < props.Count(); i++)
                        if (Attribute.GetCustomAttribute(props[i], typeof (DbFieldAttribute)) != null)
                        {
                            fieldAtts.Add(
                                (DbFieldAttribute) Attribute.GetCustomAttribute(props[i], typeof (DbFieldAttribute)));
                            props2.Add(props[i]);
                        }
//                            fieldAtts[i] = (DbFieldAttribute)Attribute.GetCustomAttribute(props[i], typeof(DbFieldAttribute));                    

                    foreach (var field in fieldNames)
                    {
                        int i = GetPropIndex(field, fieldAtts);
                        setterList.Add(i > -1 ? FastInvoke.BuildUntypedSetter<T>(props2[i]) : null);
                    }
                    Action<T, object>[] setterArray = setterList.ToArray();

                    // Objekte in einer Schleife erzeugen
                    while (reader.Read())
                    {
                        var xclass = (T) Activator.CreateInstance(typeof (T)); //, reader);
                        for (int i = 0; i < setterArray.Length; i++)
                        {
                            if (setterArray[i] != null)
                                if (!reader.IsDBNull(i))
                                {
                                    // Für Debug zwecke
                                    var fieldname = reader.GetName(i);
                                    setterArray[i](xclass, reader.GetValue(i));
                                }
                        }
                        Add(xclass);
                    }
                }

        }


        public virtual void FetchAll(CommonDB cdb, DbConditionList conditions, bool useDataTable = false)
        {
            FetchAll(cdb, String.Format("SELECT * FROM {0} ", _tableName), conditions, useDataTable);
        }

        protected void FetchAll(CommonDB cdb, string sql, DbConditionList conditions, bool useDataTable)
        {
            if (cdb == null) return;
            if (useDataTable)
                GetFromDataTable(cdb.GetDataTable(sql, conditions), cdb.LOG);

            else
            {

                using (
                    var reader = cdb.GetParametrizedReader(sql, conditions))
                {
                    if (reader != null)
                    {
                        while (reader.Read())
                        {
                            Add((T) Activator.CreateInstance(typeof (T), reader));
                        }
                    }
                }
            }
        }


        public virtual void FetchAll(CommonDB cdb, string whereclause = "", bool useDataTable = false)
        {
            FetchAll(cdb, String.Format("SELECT * FROM {0} ", _tableName), whereclause, useDataTable);
        }

        protected void FetchAll(CommonDB cdb, string externalSql, string whereclause, bool useDataTable)
        {

            if (cdb == null) return;

            var sql = externalSql + (whereclause.ToUpper().Trim().StartsWith("WHERE") ? whereclause : string.Empty);

            if (useDataTable)
                GetFromDataTable(cdb.GetDataTable(sql), cdb.LOG);

            else
            {
                using (var reader = cdb.GetReader(sql))
                {
                    if (reader != null)
                    {
                        while (reader.Read())
                        {
                            Add((T) Activator.CreateInstance(typeof (T), reader));
                        }
                    }
                }
            }
        }

        private void GetFromDataTable(DataTable data, Log.Log lg)
        {

            //Memorize count of new items
            var newDataCount = data.Rows.Count;

            //Memorize count of items in the list previous to adding the new ones (NOrmally this should yield 0, but for backward's compatibility's sake...
            var previousListItemsCount = Count;

            //Generate the according amount of new instances 
            for (var i = 0; i < newDataCount; i++)
                Add((T) Activator.CreateInstance(typeof (T)));

            //make lists of missing fields in both object and reader1
            var missingDbFields = new List<string>();
            var missingObjectFields = new List<string>();
            for (int i = 0; i < data.Columns.Count; i++)
                missingObjectFields.Add(data.Columns[i].ColumnName);

            foreach (var propertyInfo in typeof (T).GetProperties())
            {
                try
                {
                    var dbFieldAttribute =
                        Attribute.GetCustomAttribute(propertyInfo, typeof (DbFieldAttribute)) as DbFieldAttribute;
                    if (dbFieldAttribute != null)
                    {
                        if (propertyInfo.CanWrite)
                        {
                            if (data.Columns.IndexOf(dbFieldAttribute.DbFieldName) > -1)
                            {
                                missingObjectFields.Remove(dbFieldAttribute.DbFieldName);
                                var destinyType = dbFieldAttribute.DbFieldType;
                                for (var i = 0; i < newDataCount; i++)
                                {
                                    try
                                    {
                                        var sourceType = data.Rows[i][dbFieldAttribute.DbFieldName].GetType();
                                        if (sourceType != typeof (DBNull))
                                        {
                                            if (sourceType != typeof (Int32) && destinyType == DbType.Int32)
                                                propertyInfo.SetValue(this[i + previousListItemsCount],
                                                    Convert.ToInt32(
                                                        data.Rows[i][dbFieldAttribute.DbFieldName]),
                                                    null);
                                            else
                                            {
                                                if (sourceType != typeof (Double) && destinyType == DbType.Double)
                                                    propertyInfo.SetValue(this[i + previousListItemsCount],
                                                        Convert.ToDouble(
                                                            data.Rows[i][
                                                                dbFieldAttribute.DbFieldName]),
                                                        null);
                                                else
                                                    propertyInfo.SetValue(this[i + previousListItemsCount],
                                                        data.Rows[i][dbFieldAttribute.DbFieldName],
                                                        null);
                                            }
                                        }
                                    }
                                    catch (Exception ex)
                                    {
                                        if (LogAllInnerExceptions)
                                            LogEx(ex, lg,
                                                String.Format("retrieving value for column '{0}' for type '{1}'",
                                                    dbFieldAttribute.DbFieldName, TableName), null);
                                    }
                                }
                            }
                            else
                                missingDbFields.Add(dbFieldAttribute.DbFieldName);
                        }
                    }
                }
                catch (Exception ex)
                {
                    if (LogAllInnerExceptions)
                        LogEx(ex, lg, String.Format("retrieving values for type '{0}", TableName), null);
                }
            }
        }

        public void Refresh(CommonDB cdb, string whereclause = "", bool useDataTable = false)
        {
            Clear();
            FetchAll(cdb, whereclause, useDataTable);
        }
    }
}
