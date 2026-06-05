using System;

namespace INCLUDIS.Utils.CommonDB.Attributed
{
    [AttributeUsage(AttributeTargets.Class)]
    public sealed class DbListAttribute : Attribute
    {
        public string TableName;
        public bool IsView;
    }
}
