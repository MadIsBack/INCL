// <summary>
// VarConst.cs - C# translation of VarConst.pas
// Variable constants and options
// </summary>

namespace INCLService_CSharp
{
    /// <summary>
    /// Options record
    /// </summary>
    public class TOption
    {
        public bool ZUSATZ_EXTRUSION { get; set; } = false;
        public int RechnerNr { get; set; } = -1;
    }

    /// <summary>
    /// Variable constants
    /// </summary>
    public static class VarConst
    {
        public const int AppId = -1;
        public const int stLagerplatzHistorie = -1;

        public static TOption Option { get; private set; } = new TOption();

        /// <summary>
        /// Static constructor to initialize options
        /// </summary>
        static VarConst()
        {
            Option.ZUSATZ_EXTRUSION = false;
            Option.RechnerNr = -1;
        }
    }
}
