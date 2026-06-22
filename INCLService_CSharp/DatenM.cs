using System;

namespace INCLService_CSharp
{
    public class DatenM
    {
        public CO_Query qSuch { get; set; }
        public CO_Query qUpdate { get; set; }
        public CO_Query qWerte { get; set; }
        public CO_Query qCount { get; set; }
        public CO_Query qCreateDB { get; set; }
        public CO_Query qSuch2 { get; set; }
        public CO_Query qSuch4 { get; set; }
        public CO_Query qIstwert { get; set; }
        public CO_Query qDurchlauf { get; set; }
        public CO_Database Database { get; set; }
        public CO_Query qTMP { get; set; }
        public CO_Query qSuch5 { get; set; }
        public CO_Query qSuch3 { get; set; }
        public CO_Query qUpdateS { get; set; }
        public CO_Query qLog { get; set; }
        public CO_Query qSetupPar { get; set; }

        public bool Conn { get; set; }

        public static DatenM Instance { get; set; }
    }

    // Forward declarations for types used in this file
    public class CO_Database { }
    public class CO_Query { }
}
