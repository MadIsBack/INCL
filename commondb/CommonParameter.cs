using System;
using System.Data;

namespace INCLUDIS.Utils.CommonDB
{
    public class CommonParameter
    {
        public string ParamName { get; set; }
        public object ParamValue { get; set; }
        public DbType DbType
        {
            get
            {
                if ( ParamValue.GetType() == typeof(Int32))
                    return System.Data.DbType.Int32;
                else
                {
                    if (ParamValue.GetType() == typeof(double))
                    {
                        return System.Data.DbType.Double;
                    }
                    else
                    {
                        if (ParamValue.GetType() == typeof(DateTime))
                        {
                            return System.Data.DbType.DateTime;
                        }
                        else
                        {
                            return System.Data.DbType.String;
                        }
                    }
                }
            }
        }
    }
}
