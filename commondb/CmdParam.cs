using System;
using System.Data;
using System.Linq.Expressions;

namespace INCLUDIS.Utils.CommonDB
{
    public class CmdParam<T>
    {
        private readonly Expression<Func<T, object>> _exp;
        private readonly MemberExpression _me;
        public MemberExpression MemberExpression => _me;

        public CmdParam(Expression<Func<T, object>> exp, DbType dtype)
        {
            _exp = exp;
            FieldType = dtype;
            var body = _exp.Body as MemberExpression;
            if (body == null)
            {
                var ubody = (UnaryExpression)_exp.Body;
                body = ubody.Operand as MemberExpression;
            }

            _me = body;
        }


        public Expression<Func<T, object>> Exp
        {
            get { return _exp; }
/*            set
            {
                _exp = value;
                var body = _exp.Body as MemberExpression;
                if (body == null)
                {
                    var ubody = (UnaryExpression) _exp.Body;
                    body = ubody.Operand as MemberExpression;
                }

                _me = body;
            }*/
        }

        public DbType FieldType { get; private set; }

        public string FieldName => _me?.Member.Name ?? string.Empty;
    }
}
