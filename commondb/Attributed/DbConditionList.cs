using System.Collections.Generic;

namespace INCLUDIS.Utils.CommonDB.Attributed
{
    public class DbConditionList : List<DbCondition>
    {
        public bool ConditionExists(string fieldName)
        {
            return (Find(c => c.FieldName == fieldName) != null);
        }
    }
}
