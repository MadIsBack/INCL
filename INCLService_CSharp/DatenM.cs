// <summary>
// DatenM.cs - C# translation of DatenM.pas
// Data module with query objects and database connection
// </summary>

using System;

namespace INCLService_CSharp
{
    /// <summary>
    /// Data module class - contains query objects and database connection
    /// </summary>
    public class DatenM
    {
        public CO_Query qSuch { get; set; } = new CO_Query();
        public CO_Query qUpdate { get; set; } = new CO_Query();
        public CO_Query qWerte { get; set; } = new CO_Query();
        public CO_Query qCount { get; set; } = new CO_Query();
        public CO_Query qCreateDB { get; set; } = new CO_Query();
        public CO_Query qSuch2 { get; set; } = new CO_Query();
        public CO_Query qSuch4 { get; set; } = new CO_Query();
        public CO_Query qIstwert { get; set; } = new CO_Query();
        public CO_Query qDurchlauf { get; set; } = new CO_Query();
        public CO_Database Database { get; set; } = new CO_Database();
        public CO_Query qTMP { get; set; } = new CO_Query();
        public CO_Query qSuch5 { get; set; } = new CO_Query();
        public CO_Query qSuch3 { get; set; } = new CO_Query();
        public CO_Query qUpdateS { get; set; } = new CO_Query();
        public CO_Query qLog { get; set; } = new CO_Query();
        public CO_Query qSetupPar { get; set; } = new CO_Query();

        public bool Conn { get; set; } = false;

        public static DatenM Instance { get; set; } = new DatenM();

        /// <summary>
        /// Constructor
        /// </summary>
        public DatenM()
        {
            // Initialize all query objects with database reference
            qSuch.Database = Database;
            qUpdate.Database = Database;
            qWerte.Database = Database;
            qCount.Database = Database;
            qCreateDB.Database = Database;
            qSuch2.Database = Database;
            qSuch4.Database = Database;
            qIstwert.Database = Database;
            qDurchlauf.Database = Database;
            qTMP.Database = Database;
            qSuch5.Database = Database;
            qSuch3.Database = Database;
            qUpdateS.Database = Database;
            qLog.Database = Database;
            qSetupPar.Database = Database;
        }
    }
}
