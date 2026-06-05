using System;
using System.Collections.Generic;
using System.Text;

namespace INCLUDIS.Utils.CommonDB.Attributed
{
    /// <summary>
    /// DbClassAttribute zum automatischen auslesen und speichern der Klasse in/aus der Datenbank
    /// </summary>
    [AttributeUsage(AttributeTargets.Class)]
    public sealed class  DbClassAttribute: Attribute
    {
        public string TableName;
        public bool IsView;
    }
}
