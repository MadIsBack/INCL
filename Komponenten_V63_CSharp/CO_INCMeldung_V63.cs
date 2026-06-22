using System;

namespace Komponenten_V63_CSharp
{
    public class CO_INCMeldung : IDisposable
    {
        public CO_Database Database { get; set; }
        
        public CO_INCMeldung()
        {
            // Constructor
        }

        public CO_INCMeldung(CO_Database aDatabase)
        {
            Database = aDatabase;
        }

        public void Dispose()
        {
            // Cleanup
        }

        ~CO_INCMeldung()
        {
            Dispose();
        }
    }
}
