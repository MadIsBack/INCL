using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace INCLUDIS.Utils.CommonDB
{
    public static class CommonDbExtensions
    {
        /// <summary>
        /// Konvertierung von DateTime nach Invariant Culture OA Date
        /// </summary>
        /// <param name="dateTime"></param>
        /// <returns></returns>
        public static string ToSqlOa(this DateTime dateTime)
        {
            return dateTime.ToOADate().ToString(System.Globalization.CultureInfo.InvariantCulture);
        }
    }
}
