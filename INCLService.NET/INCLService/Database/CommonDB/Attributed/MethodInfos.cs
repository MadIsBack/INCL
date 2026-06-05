using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Reflection;
using System.Text;

namespace INCLUDIS.Utils.CommonDB.Attributed
{
    public class MethodInfos<T>
    {
        //public Action<T, object> Setter { get; set; }
        //public MethodInfo Converter { get; set; }
        public MethodInfo ConvSetter { get; set; }
        public TypeConverter Converter { get; set; }
        public ConversionDirection Flag { get; set; }
        public object DefaultValue { get; set; }
        public Type SourceType { get; set; }
        public Type DestinyType { get; set; }
        public string ColumnName { get; set; }

    }
}
