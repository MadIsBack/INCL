using System;
using System.Data;
using System.Data.Common;

namespace Komponenten_V63_CSharp
{
    public static class CO_Util_V63
    {
        private static string fDBUSER = "";
        private static string fDBPASS = "";
        private static DbConnection fDatabase;
        private static DbCommand fQuery;

        public static string DBUSER
        {
            get => fDBUSER;
            set => fDBUSER = value;
        }

        public static string DBPASS
        {
            get => fDBPASS;
            set => fDBPASS = value;
        }

        public static bool BeginDatabaseConnection()
        {
            try
            {
                // Create database connection
                fDatabase = new System.Data.SqlClient.SqlConnection();
                
                if (string.IsNullOrEmpty(fDBUSER))
                    fDBUSER = "includis";
                if (string.IsNullOrEmpty(fDBPASS))
                    fDBPASS = "comtas";

                // Set up connection string
                var connectionStringBuilder = new DbConnectionStringBuilder
                {
                    ["Data Source"] = "ora1",
                    ["Initial Catalog"] = "AINCSSS",
                    ["User ID"] = fDBUSER,
                    ["Password"] = fDBPASS
                };
                fDatabase.ConnectionString = connectionStringBuilder.ConnectionString;

                fDatabase.Open();

                // Create query command
                fQuery = fDatabase.CreateCommand();
                fQuery.CommandText = "SELECT dbuser FROM setup";
                
                using (var reader = fQuery.ExecuteReader())
                {
                    var result = reader.HasRows;
                    reader.Close();
                    return result;
                }
            }
            catch
            {
                return false;
            }
        }

        public static bool EndDatabaseConnection()
        {
            try
            {
                if (fQuery != null)
                {
                    fQuery.Dispose();
                    fQuery = null;
                }
                
                if (fDatabase != null)
                {
                    if (fDatabase.State == ConnectionState.Open)
                        fDatabase.Close();
                    fDatabase.Dispose();
                    fDatabase = null;
                }
                
                return true;
            }
            catch
            {
                return false;
            }
        }

        public static bool GetSetupOption(DbCommand aQuery, string aFieldName, bool aDefault = false)
        {
            bool result = false;
            bool connectDatabase = (aQuery == null);
            bool connected = connectDatabase ? BeginDatabaseConnection() : true;

            if (connected)
            {
                string fieldname = aFieldName.ToUpper();
                string s = "SELECT * FROM SYS.ALL_TAB_COLUMNS WHERE tablename = 'SETUP' AND column_name = '" + fieldname + "'";
                
                if (fQuery != null)
                {
                    fQuery.CommandText = s;
                    using (var reader = fQuery.ExecuteReader())
                    {
                        if (!reader.HasRows)
                        {
                            result = false;
                        }
                        else
                        {
                            reader.Close();
                            s = "SELECT '" + fieldname + "' FROM setup WHERE nr = 1";
                            fQuery.CommandText = s;
                            using (var reader2 = fQuery.ExecuteReader())
                            {
                                if (reader2.Read())
                                {
                                    result = (Convert.ToInt32(reader2[fieldname]) != 0);
                                }
                                reader2.Close();
                            }
                        }
                        reader.Close();
                    }
                }
            }
            
            if (connectDatabase)
                EndDatabaseConnection();
                
            return result;
        }

        public static int GetSetupOption(DbCommand aQuery, string aFieldName, int aDefault = 0)
        {
            int result = 0;
            bool connectDatabase = (aQuery == null);
            bool connected = connectDatabase ? BeginDatabaseConnection() : true;

            if (connected)
            {
                string fieldname = aFieldName.ToUpper();
                string s = "SELECT * FROM SYS.ALL_TAB_COLUMNS WHERE tablename = 'SETUP' AND column_name = '" + fieldname + "'";
                
                if (fQuery != null)
                {
                    fQuery.CommandText = s;
                    using (var reader = fQuery.ExecuteReader())
                    {
                        if (!reader.HasRows)
                        {
                            result = 0;
                        }
                        else
                        {
                            reader.Close();
                            s = "SELECT '" + fieldname + "' FROM setup WHERE nr = 1";
                            fQuery.CommandText = s;
                            using (var reader2 = fQuery.ExecuteReader())
                            {
                                if (reader2.Read())
                                {
                                    result = Convert.ToInt32(reader2[fieldname]);
                                }
                                reader2.Close();
                            }
                        }
                        reader.Close();
                    }
                }
            }
            
            if (connectDatabase)
                EndDatabaseConnection();
                
            return result;
        }

        public static string GetSetupOption(DbCommand aQuery, string aFieldName, string aDefault = "")
        {
            string result = "";
            bool connectDatabase = (aQuery == null);
            bool connected = connectDatabase ? BeginDatabaseConnection() : true;

            if (connected)
            {
                string fieldname = aFieldName.ToUpper();
                string s = "SELECT * FROM SYS.ALL_TAB_COLUMNS WHERE tablename = 'SETUP' AND column_name = '" + fieldname + "'";
                
                if (fQuery != null)
                {
                    fQuery.CommandText = s;
                    using (var reader = fQuery.ExecuteReader())
                    {
                        if (!reader.HasRows)
                        {
                            result = "";
                        }
                        else
                        {
                            reader.Close();
                            s = "SELECT '" + fieldname + "' FROM setup WHERE nr = 1";
                            fQuery.CommandText = s;
                            using (var reader2 = fQuery.ExecuteReader())
                            {
                                if (reader2.Read())
                                {
                                    result = Convert.ToString(reader2[fieldname]);
                                }
                                reader2.Close();
                            }
                        }
                        reader.Close();
                    }
                }
            }
            
            if (connectDatabase)
                EndDatabaseConnection();
                
            return result;
        }
    }
}
