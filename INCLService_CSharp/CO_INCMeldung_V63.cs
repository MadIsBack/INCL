// <summary>
// CO_INCMeldung_V63.cs - C# translation of CO_INCMeldung_V63.pas
// INCL message handling
// </summary>

using System;

namespace INCLService_CSharp
{
    /// <summary>
    /// INCL Message class
    /// </summary>
    public class CO_INCMeldung
    {
        // Message handling properties and methods would be implemented here
        public string Message { get; set; } = string.Empty;
        public int Level { get; set; } = 0;
        
        public CO_INCMeldung()
        {
        }
        
        public CO_INCMeldung(string message, int level)
        {
            Message = message;
            Level = level;
        }
        
        /// <summary>
        /// Show message
        /// </summary>
        public void Show()
        {
            try
            {
                MainDLL.SchreibeMeldung(Message, Level);
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine("Error in CO_INCMeldung.Show: " + ex.Message);
            }
        }
    }
}
