using System;
using System.ComponentModel;
using System.Collections.Generic;
using System.Data;
using System.Reflection;
using INCLUDIS.Utils.Log;
using System.Text;


namespace INCLUDIS.Utils.CommonDB.Attributed
{
    /// <summary>
    /// Abstract Classe von der abgeleitet werden kann wenn DbFieldAttribute und die Methoden aus der CommonDb zum Einsatz kommen sollen.
    /// </summary>
    public abstract class AttributedClass
    {
        /// <summary>
        /// Lesen von zugeordenten Werten aus der Datenbank
        /// </summary>
        /// <param name="commonReader"></param>
        protected AttributedClass(CommonReader commonReader)
        {
            // Daten auslesen
            DbRefresh(commonReader);

            //// Obsolete. Object wird über Constructor erzeugt und per Dbrefresh zugewiesen.
            //foreach (PropertyInfo propertyInfo in GetType().GetProperties())
            //{
            //    DbFieldAttribute dbFieldAttribute;
            //    try
            //    {

            //        dbFieldAttribute =
            //            (DbFieldAttribute) Attribute.GetCustomAttribute(propertyInfo, typeof (DbFieldAttribute));
            //        if (dbFieldAttribute != null)
            //        {
            //            if (propertyInfo.CanWrite)
            //            {
            //                if (!commonReader.IsDBNull(dbFieldAttribute.DbFieldName))
            //                {
            //                    Object o = commonReader[dbFieldAttribute.DbFieldName];
            //                    if (propertyInfo.PropertyType == typeof(Int32))
            //                        propertyInfo.SetValue(this, Convert.ToInt32(o), null);
            //                    else
            //                    {
            //                        if (propertyInfo.PropertyType == typeof(Double))
            //                            propertyInfo.SetValue(this, Convert.ToDouble(o), null);
            //                        else
            //                            propertyInfo.SetValue(this, o, null);
            //                    }
            //                }
            //                else
            //                {
            //                    if (dbFieldAttribute.DbFieldType == DbType.DateTime)
            //                        propertyInfo.SetValue(this, DateTime.FromOADate(0), null);
            //                }
            //            }
            //        }
            //    }
            //    catch (Exception ex)
            //    {
            //        var s = ex.Message;
            //    }
            //}
        }

        /// <summary>
        /// Zuordnen von Default Werten
        /// </summary>
        protected AttributedClass()
        {
            foreach (PropertyDescriptor property in TypeDescriptor.GetProperties(this))
            {
                DefaultValueAttribute myAttribute = (DefaultValueAttribute)property.Attributes[typeof(DefaultValueAttribute)];
                DbFieldAttribute dbFieldAttribute = (DbFieldAttribute)property.Attributes[typeof(DbFieldAttribute)];

                if (myAttribute != null)
                {
                    try
                    {
                        if (dbFieldAttribute.DbFieldType == DbType.DateTime)
                            property.SetValue(this, DateTime.FromOADate(Convert.ToInt32(myAttribute.Value)));
                        else
                            property.SetValue(this, myAttribute.Value);
                    }
                    catch (Exception ex)
                    {


                    }
                }
            }
        }

        protected List<object> GetAttributedClassLists()
        {
            List<object> o = new List<object>();
            Type generic = typeof(AttributedClassList<>);
            Type specific = generic.MakeGenericType(GetType());

            List<Type> classes = new List<Type>();
            classes.AddRange(Assembly.GetAssembly(GetType()).GetTypes());
            classes.RemoveAll(c => !c.IsSubclassOf(specific));
            foreach (Type t in classes)
            {
                ConstructorInfo ci = t.GetConstructor(Type.EmptyTypes);
                try
                {
                    if (ci != null)
                    {
                        o.Add(ci.Invoke(new object[0]));
                    }
                    else
                    {
                        o.Add(Activator.CreateInstance(t));
                    }
                }
                catch (Exception ex)
                {
                    o.Add(ex);
                }
            }
            return o;
        }

        private void IterateProps(StringBuilder sb, object parent, int level)
        {
            var props = parent.GetType().GetProperties();
            var pre = "";
            for(int i=0;i<level;i++)
            { pre += "\t"; }
            foreach (var propertyInfo in props)
            {
                var result = propertyInfo.GetValue(parent, null);
                var value = result == null ? $"<null>({propertyInfo.PropertyType.FullName})" : result;
                sb.Append($"{pre}{propertyInfo.Name} => {value}\r\n");
                if (propertyInfo.PropertyType.FullName.ToUpper().StartsWith("INCLUDIS"))  // Dann ist das unser und wir holen uns die Eigenschaften dessen
                {
                    if (result != null)
                    {
                        IterateProps(sb, result, level+1);
                    }
                }
            }
        }
        private string GetClassAndInstanceForDebug()
        {
            var sb = new StringBuilder();
            IterateProps(sb, this, 0);
            return sb.ToString(); 
        }       
        public int SaveDebugObject(CommonDB cdb, string note)
        {
            try
            {
                Type t = GetType();
                var app = "";
                var ass = Assembly.GetEntryAssembly();
                if (ass == null)
                    ass = Assembly.GetExecutingAssembly();
                if (ass==null)
                    app = "unknown";
                else 
                    app = ass.GetName().Name;
                var sql = "INSERT INTO debugobject (nr, klasse, anwendung, datumzeit, notiz, instanz) " +
                    $"VALUES (debugobjectid.nextval, '{t.FullName}', '{app}', " +
                    $"{DateTime.Now.ToOADate().ToString(System.Globalization.CultureInfo.InvariantCulture)}," +
                    $"'{note}', '{GetClassAndInstanceForDebug()}')";
                cdb.ExecuteNonQuery(sql);

                // Und um die DB nicht überlaufen zu lassen, nur ein halbes Jahr mitschreiben
                cdb.ExecuteNonQuery($"DELETE FROM debugobject WHERE datumzeit < {DateTime.Now.AddMonths(-6).ToOADate().ToString(System.Globalization.CultureInfo.InvariantCulture)}");
            }
            catch(Exception ex) // Da passiert mal nix. Vorerst ML 18.07.24
            {
                return -1;
            }
            return 0;
        }
        public string GetTableName()
        {
            foreach (PropertyInfo propertyInfo in GetType().GetProperties())
            {
                DbClassAttribute dbClassAttribute;
                try
                {
                    dbClassAttribute =
                        (DbClassAttribute)Attribute.GetCustomAttribute(propertyInfo, typeof(DbClassAttribute));

                    if (dbClassAttribute != null)
                        return dbClassAttribute.TableName;
                }
                catch
                { }
            }


            string tn = string.Empty;
            try
            {
                List<object> olist = GetAttributedClassLists();
                foreach (object o in olist)
                    if ((o.GetType() != typeof(Exception)) && (!o.GetType().IsSubclassOf(typeof(Exception))))
                    {
                        List<PropertyInfo> pis = new List<PropertyInfo>();
                        pis.AddRange(o.GetType().GetProperties());
                        PropertyInfo propertyInfo = pis.Find(pi => pi.Name == "TableName");
                        if (propertyInfo != null)
                        {
                            tn = propertyInfo.GetValue(o, null).ToString();
                        }
                    }
            }
            catch (Exception ex)
            {
                tn = ex.Message;
            }
            return tn;
        }

        [Obsolete("Noch keine Einschränkung auf Primary Key")]
        public void DbRefresh(CommonDB cdb)
        {
            string tn = GetTableName();
            using (var reader = cdb.GetReader("SELECT * FROM " + tn))
                if (reader.Read())
                    DbRefresh(reader);

        }

        private class MyPropertyInfo 
        {
            public PropertyInfo pi;
            public DbFieldAttribute dbFieldAttribute;
        }

        private static Dictionary<string, List<MyPropertyInfo>> objectInformation = new Dictionary<string, List<MyPropertyInfo>>();
        private static object objectInformationLock = new object();
        public void DbRefresh(CommonReader reader)
        {
            Type t = GetType();
            var typeName = t.AssemblyQualifiedName;
            List<MyPropertyInfo> props;
            lock (objectInformationLock)
            {
                if (!objectInformation.ContainsKey(typeName))
                {
                    var p = t.GetProperties();
                    List<MyPropertyInfo> data = new List<MyPropertyInfo>();
                    foreach (var pi in p)
                    {
                        var dbFieldAttribute =
                            (DbFieldAttribute)Attribute.GetCustomAttribute(pi, typeof(DbFieldAttribute));
                        data.Add(new MyPropertyInfo() { pi = pi, dbFieldAttribute = dbFieldAttribute });
                    }

                    objectInformation.Add(typeName, data);
                }

                props = objectInformation[typeName]; //GetType().GetProperties();
            }

            
            foreach (var p in props)
            {
                var propertyInfo = p.pi; //p;
                
                try
                {
                    DbFieldAttribute dbFieldAttribute = p.dbFieldAttribute;
                    //var dbFieldAttribute = (DbFieldAttribute)Attribute.GetCustomAttribute(propertyInfo, typeof(DbFieldAttribute));
                    if (dbFieldAttribute != null)
                    {
                        if (propertyInfo.CanWrite)
                        {
                            if (!reader.IsDBNull(dbFieldAttribute.DbFieldName))
                            {
                                switch (propertyInfo.PropertyType.Name)
                                {
                                    case "Int32":
                                        propertyInfo.SetValue(this, reader.GetInt32(dbFieldAttribute.DbFieldName), null);
                                        break;
                                    case "Int64":
                                        propertyInfo.SetValue(this, reader.GetInt64(dbFieldAttribute.DbFieldName), null);
                                        break;
                                    case "UInt64":
                                        propertyInfo.SetValue(this, reader.GetUInt64(dbFieldAttribute.DbFieldName), null);
                                        break;
                                    case "Double":
                                        propertyInfo.SetValue(this, reader.GetDouble(dbFieldAttribute.DbFieldName), null);
                                        break;
                                    case "Float":
                                        propertyInfo.SetValue(this, reader.GetFloat(dbFieldAttribute.DbFieldName), null);
                                        break;
                                    case "Boolean":
                                        propertyInfo.SetValue(this, reader.GetInt32(dbFieldAttribute.DbFieldName) == 1, null);
                                        break;
                                    case "Guid":
                                        if ((reader.Command.DbType == CommonDB.DatabaseType.dtOracle) || (reader.Command.DbType == CommonDB.DatabaseType.dtOracleNet))
                                        {
                                            try
                                            {
                                                var guidstr = reader.GetString("checkguid").Replace("-", string.Empty);
                                                var rawBytesFromOracle = new byte[16];
                                                for (var i = 0; i < 16; i++)
                                                {
                                                    var b = byte.Parse(guidstr.Substring(i * 2, 2), System.Globalization.NumberStyles.HexNumber);
                                                    rawBytesFromOracle[i] = b;
                                                }
                                                propertyInfo.SetValue(this, new Guid(rawBytesFromOracle), null);
                                            }
                                            catch
                                            {
                                                propertyInfo.SetValue(this, Guid.NewGuid(), null); // Oracle zickt manchmal. Ist aber auch nicht so wichtig.
                                            }                                        
                                        }
                                        else
                                        {
                                            propertyInfo.SetValue(this, reader.GetGuid(dbFieldAttribute.DbFieldName), null);
                                        }
                                        break;
                                    default:
                                        propertyInfo.SetValue(this, reader[dbFieldAttribute.DbFieldName], null);
                                        break;
                                }                               
                            }
                            else
                            {
                                if (dbFieldAttribute.DbFieldType == DbType.DateTime)
                                    propertyInfo.SetValue(this, DateTime.FromOADate(0), null);
                            }
                        }
                    }
                }
                catch (Exception ex)
                {
                    reader.LogException(ex, GetType().ToString(), null);
                }
            }
        }
        
        public virtual void DbInsert(CommonDB cdb)
        {
            DbInsert(cdb, true);
        }

        private List<MethodInfo> GetMethodsOfAttributesClassLists(object o)
        {
            List<MethodInfo> mis = new List<MethodInfo>();
            if (o != null)
            {
                mis.AddRange(o.GetType().GetMethods());
            }
            return mis;
        }

        private void ExecuteMethodOfAttributedClassList(string MethodName, object[] miparams)
        {
            List<object> olist = GetAttributedClassLists();
            if (olist.Count > 0)
            {
                List<MethodInfo> mis = new List<MethodInfo>();
                mis.AddRange(olist[0].GetType().GetMethods());

                MethodInfo methodInfo = mis.Find(mi => (mi.Name == "Add") && (mi.GetParameters().Length == 1));
                methodInfo.Invoke(olist[0], new object[1] { this });

                methodInfo = mis.Find(mi => (mi.Name == MethodName) && (mi.GetParameters().Length == miparams.Length));
                methodInfo.Invoke(olist[0], miparams);
            }
        }

        public virtual void DbInsert(CommonDB cdb, Boolean generateKey)
        {
            object[] miparams = { cdb, generateKey };
            ExecuteMethodOfAttributedClassList("DbInsert", miparams);
        }

        public virtual void DbUpdate(CommonDB cdb, DbConditionList conditions)
        {
            object[] miparams = { cdb, conditions };
            ExecuteMethodOfAttributedClassList("DbUpdate", miparams);
        }

        public virtual void DbDelete(CommonDB cdb, DbConditionList conditions)
        {
            object[] miparams = { cdb, conditions };
            ExecuteMethodOfAttributedClassList("DbDelete", miparams);
        }

        public void GeneratePrimaryKey(CommonDB cdb)
        {
            object[] miparams = { cdb };
            ExecuteMethodOfAttributedClassList("GeneratePrimaryKeys", miparams);
        }

        public object Clone()
        {
            return this.MemberwiseClone();
        }



        /// <summary>
        /// Tabellenlayout anpassen
        /// Sollte das Tabellenlayout nicht stimmen wird eine Exception ausgelöst. 
        ///     Anschließend kann das Layout automatisch korrigiert werden.
        ///     Es zusätzlich wird ein Feld in der Tabelle Setup erstellt in welches die AssemblyVersion der  
        ///     Tabledefinitions DLL gespeichert wird.
        ///     Es dürfen nur Änderungen am Layout vorgenommen werden wenn die DLL neuer ist.
        /// </summary>
        private void AlterTable()
        {

        }

        [Obsolete]
        private void GeneratePrimaryKeySelf(CommonDB cdb)
        {
            string tn = GetTableName();
            foreach (PropertyInfo propertyInfo in GetType().GetProperties())
            {
                DbFieldAttribute dbFieldAttribute =
                    (DbFieldAttribute)Attribute.GetCustomAttribute(propertyInfo, typeof(DbFieldAttribute));
                if (dbFieldAttribute.IsPrimKey)
                {
                    string SQL = "SELECT " + tn + "ID.Nextval nextnr FROM DUAL";
                    using (var reader = cdb.GetReader(SQL))
                    {
                        if (reader != null)
                        {
                            if (reader.Read())
                            {
                                Object o = reader[dbFieldAttribute.DbFieldName];
                                if (propertyInfo.PropertyType == typeof(Int32))
                                    propertyInfo.SetValue(this, Convert.ToInt32(o), null);
                                else
                                {
                                    if (propertyInfo.PropertyType == typeof(Double))
                                        propertyInfo.SetValue(this, Convert.ToDouble(o), null);
                                    else
                                        propertyInfo.SetValue(this, o, null);
                                }
                            }
                        }
                    }
                }
            }

        }

    }
}
