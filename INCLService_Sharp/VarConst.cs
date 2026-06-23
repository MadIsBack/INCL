namespace INCLService_Sharp
{
    /// <summary>
    /// Global constants and options
    /// </summary>
    public static class VarConst
    {
        public static class Option
        {
            public static bool ZUSATZ_EXTRUSION = false;
            public static int RechnerNr = -1;
        }

        public const int AppId = -1;
        public const int stLagerplatzHistorie = -1;

        static VarConst()
        {
            Option.ZUSATZ_EXTRUSION = false;
            Option.RechnerNr = -1;
        }
    }
}
