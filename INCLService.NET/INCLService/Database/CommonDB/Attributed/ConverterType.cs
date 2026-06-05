using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Text;

namespace INCLUDIS.Utils.CommonDB.Attributed
{
    public class ConverterType<T, TProperty>
    {
        public Action<T, TProperty> Lambda { get; set; }
        public Type DestinyType { get; set; }
        public MethodInfo SetterMethod { get; set; } 
    }
}
