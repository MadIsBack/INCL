using System;
using System.Data;
using System.Data.Common;
using System.Text;

namespace INCLUDIS.Utils.CommonDB
{
    public static class DbCommandExtension
    {
        /*
        public static string GetCommandLogString(this CommonCommand cmd)
        {
            var sb = new StringBuilder();
            sb.Append(String.Format("DBCommand: '{0}'{1}Parameters:{1}", cmd.CommandText, Environment.NewLine));
            foreach (DbParameter p in cmd.Parameters)
            {
                sb.Append(String.Format("{0} = {1}({2}){3}", p.ParameterName,
                                        p.Value != null ? p.Value.ToString() : "null", p.DbType, Environment.NewLine));
            }
            return sb.ToString();
        }

        public static string GetCommandLogString(this DbCommand cmd)
        {
            var sb = new StringBuilder();
            sb.Append(String.Format("DBCommand: '{0}'{1}Parameters:{1}", cmd.CommandText, Environment.NewLine));
            foreach (DbParameter p in cmd.Parameters)
            {
                sb.Append(String.Format("{0} = {1}({2}){3}", p.ParameterName,
                                        p.Value != null ? p.Value.ToString() : "null", p.DbType, Environment.NewLine));
            }
            return sb.ToString();
        }*/

        public static string GetCommandLogString(this IDbCommand cmd)
        {
            var sb = new StringBuilder();
            sb.Append(String.Format("DBCommand: '{0}'{1}Parameters:{1}", cmd.CommandText, Environment.NewLine));
            foreach (DbParameter p in cmd.Parameters)
            {
                sb.Append(String.Format("{0} = {1}({2}){3}", p.ParameterName,
                                        p.Value != null ? p.Value.ToString() : "null", p.DbType, Environment.NewLine));
            }
            return sb.ToString();
        }
    }
}
