using System;

namespace Komponenten_V63_CSharp
{
    public class CO_SPC : IDisposable
    {
        public CO_Database Database { get; set; }
        
        public CO_SPC()
        {
            // Constructor
        }

        public CO_SPC(CO_Database aDatabase)
        {
            Database = aDatabase;
        }

        public void Dispose()
        {
            // Cleanup
        }

        ~CO_SPC()
        {
            Dispose();
        }
    }
}
