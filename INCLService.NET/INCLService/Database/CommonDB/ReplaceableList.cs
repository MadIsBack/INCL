using System.Collections.Generic;

namespace INCLUDIS.Utils.CommonDB
{
    public class ReplaceableList : List<ReplaceableToken>
    {
        public ReplaceableList()
        {
            var sqlTypes = new List<CommonDB.DatabaseType>{CommonDB.DatabaseType.dtMSSQL, CommonDB.DatabaseType.dtMsSqlNet};
            Add(new ReplaceableToken
            {
                DbTypes = sqlTypes,
                OraOriginal = "VARCHAR2(",
                Substitute = "VARCHAR("
            });
            Add(new ReplaceableToken
            {
                DbTypes = sqlTypes,
                OraOriginal ="BLOB",
                Substitute ="IMAGE"
            });
            Add(new ReplaceableToken
            {
                DbTypes = sqlTypes,
                OraOriginal ="CLOB",
                Substitute ="TEXT"
            });
            Add(new ReplaceableToken
            {
                DbTypes = sqlTypes,
                OraOriginal =" DATE ",
                Substitute =" DATETIME "
            });
            Add(new ReplaceableToken
            {
                DbTypes = sqlTypes,
                OraOriginal =" DATE,",
                Substitute =" DATETIME,"
            });
            Add(new ReplaceableToken
            {
                DbTypes = sqlTypes,
                OraOriginal =" LENGTH(",
                Substitute =" LEN("
            });
            Add(new ReplaceableToken
            {
                DbTypes = sqlTypes,
                OraOriginal =" TO_NUMBER(",
                Substitute =" CONVERT(NUMERIC,"
            });
            Add(new ReplaceableToken
            {
                DbTypes = sqlTypes,
                OraOriginal =" TO_CHAR(",
                Substitute =" CONVERT(VARCHAR(300),"
            });
            Add(new ReplaceableToken
            {
                DbTypes = sqlTypes,
                OraOriginal = " TO_NCHAR(",
                Substitute = " CONVERT(NVARCHAR(300),"
            }); Add(new ReplaceableToken
            {
                DbTypes = sqlTypes,
                OraOriginal =" QQQTOP",
                Substitute =" TOP1"
            });
            Add(new ReplaceableToken
            {
                DbTypes = sqlTypes,
                OraOriginal ="QQQLEFT",
                Substitute ="LEFT1"
            });
            Add(new ReplaceableToken
            {
                DbTypes = sqlTypes,
                OraOriginal = " TOP INTEGER, LEFT INTEGER",
                Substitute = " TOP1 INTEGER, LEFT1 INTEGER"
            });
            Add(new ReplaceableToken
            {
                DbTypes = sqlTypes,
                OraOriginal = " TOP, LEFT",
                Substitute = " TOP1, LEFT1"
            });
            Add(new ReplaceableToken
            {
                DbTypes = sqlTypes,
                OraOriginal = " SHUTDOWN",
                Substitute = " SHUTDOWN1"
            });
            Add(new ReplaceableToken
            {
                DbTypes = sqlTypes,
                OraOriginal = " SHUTDOWN)",
                Substitute = " SHUTDOWN1)"
            });
            Add(new ReplaceableToken
            {
                DbTypes = sqlTypes,
                OraOriginal = "SET SHUTDOWN = ",
                Substitute = "SET SHUTDOWN1 = "
            });
            Add(new ReplaceableToken
            {
                DbTypes = sqlTypes,
                OraOriginal = " IS NOT NULL",
                Substitute = " <> ''"
            });
            Add(new ReplaceableToken
            {
                DbTypes = sqlTypes,
                OraOriginal = " PRINT ",
                Substitute = " PRINT1 "
            });
            Add(new ReplaceableToken
            {
                DbTypes = sqlTypes,
                OraOriginal = "USER_TABLES",
                Substitute = "INFORMATION_SCHEMA.TABLES"
            });
            Add(new ReplaceableToken
            {
                DbTypes = sqlTypes,
                OraOriginal = "USER_VIEWS",
                Substitute = "INFORMATION_SCHEMA.VIEWS"
            });
            Add(new ReplaceableToken
            {
                DbTypes = sqlTypes,
                OraOriginal = "VIEW_NAME",
                Substitute = "TABLE_NAME"
            });
            Add(new ReplaceableToken
            {
                DbTypes = sqlTypes,
                OraOriginal = "USER_COL_COMMENTS",
                Substitute = "INFORMATION_SCHEMA.COLUMNS"
            });
            Add(new ReplaceableToken
            {
                DbTypes = sqlTypes,
                OraOriginal = ",TOP,LEFT",
                Substitute = ",TOP1,LEFT1"
            });
            Add(new ReplaceableToken
            {
                DbTypes = sqlTypes,
                OraOriginal = ",BEGIN,END",
                Substitute = ",BEGINN,ENDE"
            });
            Add(new ReplaceableToken
            {
                DbTypes = sqlTypes,
                OraOriginal = ",SHUTDOWN,",
                Substitute = ",SHUTDOWN1,"
            });
            Add(new ReplaceableToken
            {
                DbTypes = sqlTypes,
                OraOriginal = "Trunc(",
                Substitute = "Convert(Integer, "
            });
            Add(new ReplaceableToken
            {
                DbTypes = sqlTypes,
                OraOriginal = "STDDEV",
                Substitute = "STDEV"
            }); Add(new ReplaceableToken
            {
                DbTypes = sqlTypes,
                OraOriginal = "SUBSTR(",
                Substitute = "SUBSTRING("
            });
            Add(new ReplaceableToken
            {
                DbTypes = sqlTypes,
                OraOriginal = "VARIANCE",
                Substitute = "VAR"
            }); 
        }
    }
}
