using System;
using System.Collections.Generic;

namespace INCLUDIS.Utils.CommonDB
{
    public class ReplaceableToken
    {
        public List<CommonDB.DatabaseType> DbTypes { get; set; }
        public String OraOriginal;
        public String Substitute;
    }
}
