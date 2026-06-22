// <summary>
// CO_SPC_V63.cs - C# translation of CO_SPC_V63.pas
// SPC (Statistical Process Control) classes
// </summary>

using System;

namespace INCLService_CSharp
{
    /// <summary>
    /// CO_SPC class - SPC functionality
    /// </summary>
    public class CO_SPC
    {
        // SPC-related properties and methods would be implemented here
        public string Name { get; set; } = string.Empty;
        public int Index { get; set; } = 0;
        
        public CO_SPC()
        {
        }
        
        public CO_SPC(int index)
        {
            Index = index;
        }
    }
}
