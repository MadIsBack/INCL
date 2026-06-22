using System;

namespace Komponenten_V63_CSharp
{
    public class CO_TPM : IDisposable
    {
        public CO_Database Database { get; set; }
        
        public CO_TPM()
        {
            // Constructor
        }

        public CO_TPM(CO_Database aDatabase)
        {
            Database = aDatabase;
        }

        public void Dispose()
        {
            // Cleanup
        }

        ~CO_TPM()
        {
            Dispose();
        }
    }
}
