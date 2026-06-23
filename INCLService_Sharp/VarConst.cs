namespace INCLService_Sharp
{
    /// <summary>
    /// Global constants and options - 1:1 translation from VarConst.pas
    /// </summary>
    public static class VarConst
    {
        /// <summary>
        /// Option record - 1:1 translation from Delphi
        /// </summary>
        public static class Option
        {
            public static bool ZUSATZ_EXTRUSION = false;
            public static int RechnerNr = -1;
        }

        public const int AppId = -1;
        public const int stLagerplatzHistorie = -1;

        /// <summary>
        /// Static constructor to initialize default values - 1:1 translation from Delphi
        /// </summary>
        static VarConst()
        {
            Option.ZUSATZ_EXTRUSION = false;
            Option.RechnerNr = -1;
        }
    }
}
