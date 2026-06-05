using System.CodeDom;
using System.CodeDom.Compiler;
using System.IO;
using System.Reflection;

namespace INCLUDIS.Utils.CommonDB
{
    public class SetupGenerator
    {
        readonly CodeCompileUnit _targetUnit;
        readonly CodeTypeDeclaration _targetClass;
        private const string OutputFileName = @"..\..\..\INCLUDIS.UTILS.Configuration\Parameters.cs";
        
        public SetupGenerator()
        {
            _targetUnit = new CodeCompileUnit();
            var samples = new CodeNamespace("INCLUDIS.Utils.Configuration");
            samples.Imports.Add(new CodeNamespaceImport("System"));
            _targetClass = new CodeTypeDeclaration("Parameters")
                {
                    IsClass = true,
                    TypeAttributes = TypeAttributes.Public | TypeAttributes.Sealed
                };
            samples.Types.Add(_targetClass);
            _targetUnit.Namespaces.Add(samples);
            /*
            // Declare the read-only Width property.
            var widthProperty = new CodeMemberProperty();
            widthProperty.Attributes =
                MemberAttributes.Public | MemberAttributes.Final;
            widthProperty.Name = "Width";
            widthProperty.HasGet = true;
            widthProperty.Type = new CodeTypeReference(typeof(System.Double));
            widthProperty.Comments.Add(new CodeCommentStatement(
                "The Width property for the object."));
            widthProperty.GetStatements.Add(new CodeMethodReturnStatement(
                new CodeFieldReferenceExpression(
                new CodeThisReferenceExpression(), "widthValue")));
            _targetClass.Members.Add(widthProperty);

            var provider = CodeDomProvider.CreateProvider("CSharp");
            var options = new CodeGeneratorOptions {BracingStyle = "C"};
            using (var sourceWriter = new StreamWriter(OutputFileName))
            {
                provider.GenerateCodeFromCompileUnit(
                    _targetUnit, sourceWriter, options);
            }
             * */
        }
    }
}
