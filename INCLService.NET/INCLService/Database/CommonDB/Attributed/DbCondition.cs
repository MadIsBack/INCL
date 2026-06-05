using System;
using System.Data;
using System.Linq.Expressions;

namespace INCLUDIS.Utils.CommonDB.Attributed
{
    /// <summary>
    /// Bedingungs Klasse für das automatische INSERT, SELECT und UPDATE
    /// </summary>
    public class DbCondition
    {
        public enum ConditionType { Lower, Greater, Equals, UnEquals}

        public string VarName { get { return FieldName.Replace(".", ""); } }
        public string FieldName { get; set; }
        public DbType FieldType { get; set; }
        public ConditionType Condition { get; set; }
        public string ConditionString
        {
            get
            {
                switch (Condition)
                {
                    case ConditionType.Greater:
                        return ">";
                    case ConditionType.Lower:
                        return "<";
                    case ConditionType.UnEquals:
                        return "<>";
                    //case ConditionType.Equals:
                    default:
                        return "=";
                }
            }
        }

        public bool IsLiteralType { get
        {
            return ((FieldType == DbType.AnsiString) || (FieldType == DbType.AnsiStringFixedLength) ||
                    (FieldType == DbType.String) || (FieldType == DbType.StringFixedLength));
        }}

        public object ConditionValue { get; set; }

        public DbCondition(){}

        /// <summary>
        /// Erzeugt einen String-Parameter
        /// </summary>
        /// <param name="fieldName"></param>
        /// <param name="value"></param>
        public DbCondition(string fieldName, string value)
        {
            FieldType = DbType.String;
            Condition = ConditionType.Equals;
            FieldName = fieldName;
            ConditionValue = value;
        }
        /// <summary>
        /// Erzeugt einen Int32-Parameter
        /// </summary>
        /// <param name="fieldName"></param>
        /// <param name="value"></param>
        public DbCondition(string fieldName, Int32 value)
        {
            FieldType = DbType.Int32;
            Condition = ConditionType.Equals;
            FieldName = fieldName;
            ConditionValue = value;
        }
        /// <summary>
        /// Erzeugt einen Double-Parameter
        /// </summary>
        /// <param name="fieldName"></param>
        /// <param name="value"></param>
        public DbCondition(string fieldName, Double value)
        {
            FieldType = DbType.Double;
            Condition = ConditionType.Equals;
            FieldName = fieldName;
            ConditionValue = value;
        }


        public static DbCondition MakeCondition<T>(Expression<Func<T, object>> exp, string value)
        {
            return MakeCondition(exp, DbType.String, value);
        }

        public static DbCondition MakeCondition<T>(Expression<Func<T, object>> exp, double value)
        {
            return MakeCondition(exp, DbType.Double, value);
            
        }

        public static DbCondition MakeCondition<T>(Expression<Func<T, object>> exp, Int32 value)
        {
            return MakeCondition(exp, DbType.Int32, value);
           
        }

        public static DbCondition MakeCondition<T>(Expression<Func<T, object>> exp, DbType fieldType, object value)
        {
            var body = exp.Body as MemberExpression;
            if (body == null)
            {
                var ubody = (UnaryExpression) exp.Body;
                body = ubody.Operand as MemberExpression;
            }
            if (body == null)
                return null;

            return new DbCondition
            {
                FieldType = fieldType,
                Condition = ConditionType.Equals,
                FieldName = body.Member.Name,
                ConditionValue = value,
            };
        }
    }
}
