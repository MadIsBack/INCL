using System;
using System.Data;

namespace INCLUDIS.Utils.CommonDB.Attributed
{
    /// <summary>
    /// DbFieldAttribute zum automatischen auslesen von Daten aus der Datenbank
    /// </summary>
    [AttributeUsage(AttributeTargets.Property)]
    public sealed class DbFieldAttribute : Attribute
    {
        public bool IsPrimKey;
        public string DbFieldName;
        public string RealDbFieldType;
        public DbType DbFieldType;
        public int DbFieldLength;
        public bool IsIndex;
        public bool IsAdditionalReadOnly;
        public bool IsSecondaryKeyBasedOnMaxValue;
    }
}
