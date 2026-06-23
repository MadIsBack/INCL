using System;
using INCLUDIS.Utils.CommonDB;

namespace INCLService_Sharp
{
    /// <summary>
    /// Data module for database operations
    /// </summary>
    public class DatenM : IDisposable
    {
        public CommonDB Database { get; set; }
        public CommonCommand qSuch { get; set; }
        public CommonCommand qUpdate { get; set; }
        public CommonCommand qWerte { get; set; }
        public CommonCommand qCount { get; set; }
        public CommonCommand qCreateDB { get; set; }
        public CommonCommand qSuch2 { get; set; }
        public CommonCommand qSuch4 { get; set; }
        public CommonCommand qIstwert { get; set; }
        public CommonCommand qDurchlauf { get; set; }
        public CommonCommand qTMP { get; set; }
        public CommonCommand qSuch5 { get; set; }
        public CommonCommand qSuch3 { get; set; }
        public CommonCommand qUpdateS { get; set; }
        public CommonCommand qLog { get; set; }
        public CommonCommand qSetupPar { get; set; }

        public bool Conn { get; set; }

        public DatenM()
        {
            Database = new CommonDB();
            
            qSuch = new CommonCommand(Database);
            qUpdate = new CommonCommand(Database);
            qWerte = new CommonCommand(Database);
            qCount = new CommonCommand(Database);
            qCreateDB = new CommonCommand(Database);
            qSuch2 = new CommonCommand(Database);
            qSuch4 = new CommonCommand(Database);
            qIstwert = new CommonCommand(Database);
            qDurchlauf = new CommonCommand(Database);
            qTMP = new CommonCommand(Database);
            qSuch5 = new CommonCommand(Database);
            qSuch3 = new CommonCommand(Database);
            qUpdateS = new CommonCommand(Database);
            qLog = new CommonCommand(Database);
            qSetupPar = new CommonCommand(Database);
        }

        public void Dispose()
        {
            qSuch?.Dispose();
            qUpdate?.Dispose();
            qWerte?.Dispose();
            qCount?.Dispose();
            qCreateDB?.Dispose();
            qSuch2?.Dispose();
            qSuch4?.Dispose();
            qIstwert?.Dispose();
            qDurchlauf?.Dispose();
            qTMP?.Dispose();
            qSuch5?.Dispose();
            qSuch3?.Dispose();
            qUpdateS?.Dispose();
            qLog?.Dispose();
            qSetupPar?.Dispose();
            Database?.Dispose();
        }
    }

    /// <summary>
    /// Global data module instance
    /// </summary>
    public static class Daten
    {
        public static DatenM Instance { get; } = new DatenM();
    }
}
