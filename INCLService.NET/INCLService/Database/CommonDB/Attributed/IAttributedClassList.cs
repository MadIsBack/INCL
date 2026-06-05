using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Text;

namespace INCLUDIS.Utils.CommonDB.Attributed
{
    public interface IAttributedClassList : IList
    {

        string TableName { get; }

        void DbUpdate(CommonDB cdb);
        void DbUpdate(CommonDB cdb, DbConditionList conditions);
        void DbDelete(CommonDB cdb, DbConditionList conditions);

        void DbInsert(CommonDB cdb);
        void DbInsert(CommonDB cdb, bool generatePrimaryKey);
        void DbInsert(CommonDB cdb, AttributedEnums.PrimaryKeyGeneration typeOfGeneration);

        void GeneratePrimaryKeys(CommonDB cdb, List<PropertyInfo> propertyInfoList,
            Dictionary<string, DbFieldAttribute> dbFieldAttributes);

        void FastFetch(CommonDB cdb, string whereclause = "");

        void FetchAll(CommonDB cdb, DbConditionList conditions, bool useDataTable = false);

        void FetchAll(CommonDB cdb, string whereclause = "", bool useDataTable = false);
        void Refresh(CommonDB cdb, string whereclause = "", bool useDataTable = false);

    }
}
