using INCLService.CSharp.Models;
using INCLUDIS.Utils.CommonDB;
using Microsoft.Extensions.Logging;
using System;
using System.Globalization;
using System.Threading;
using System.Threading.Tasks;

namespace INCLService.CSharp.Services
{
    /// <summary>
    /// Erweiterungsmethoden für S7MainService
    /// Enthält die portierten Methoden aus DBMain.pas (Schritt 14)
    /// </summary>
    public static class S7MainServiceExtensions
    {
        // ==================== KONSTANTEN AUS DBMAIN.PAS ====================
        
        public const int TAGMINUTEN = 1440;
        public const double Stunde = 1.0 / 24.0;
        public const double MINUTEN5 = 5.0 / TAGMINUTEN;
        public const double MINUTEN10 = 10.0 / TAGMINUTEN;
        public const double MINUTEN60 = Stunde;
        public const int INC_Application = 50;
        public const int Max_ANZAHL = 600;
        public const int MAX_S7_LESEVERSUCHE = 100;
        public const int Max_Nutzung = 100;
        public const int Max_Leistung = 200;
        public const int MAX_BARCODE = 13;
        public const int VToleranz = 5;
        public const int VHandToleranz = 5;
        public const int SchichtZeitHandbetrieb = 60;
        public const double Zeit_zum_MDEAuftrag = 0.003472; // entspricht 5 Minuten
        public const double Zeit_zum_AutoStart = 0.006944; // entspricht 10 Minuten
        public const double Zeit_zur_Meldung = 0.041664; // entspricht 60 Minuten
        public const int StatusPlanDiff = 1440;
        public const int BYTEVAR = 0;
        public const int WORDVAR = 1;
        public const int DWORDVAR = 2;
        public const int BOOLVAR = 3;
        
        // Maschinenstatus-Konstanten
        public const int MaschLaeuft = 0;
        public const int MaschRuesten = 1;
        public const int MaschStillStoer = 2;
        public const int MaschStillundefeniert = 4;
        public const int MaschStillOrg = 5;
        
        // Störarten
        public const int saStoerung = 0;
        public const int saJob = 1;
        public const int saHinweis = 2;
        
        // TPM-Störgruppen
        public const int TPMAnlage = 0;
        public const int TPMRuesten = 1;
        public const int TPMLogistik = 2;
        
        // ==================== HILFSMETHODEN ====================
        
        /// <summary>
        /// Konvertiert ein Datum in einen Punkt-String (für SQL)
        /// Äquivalent zu FloatToPunktString in Delphi
        /// </summary>
        public static string FloatToPunktString(DateTime dateTime)
        {
            return dateTime.ToString("yyyy-MM-dd HH:mm:ss", CultureInfo.InvariantCulture);
        }
        
        /// <summary>
        /// Konvertiert einen Double-Wert in einen Punkt-String (für SQL)
        /// Äquivalent zu FloatToPunktString in Delphi
        /// </summary>
        public static string FloatToPunktString(double value)
        {
            return value.ToString(CultureInfo.InvariantCulture);
        }
        
        /// <summary>
        /// Konvertiert einen Integer-Wert in einen String
        /// Äquivalent zu IntToStr in Delphi
        /// </summary>
        public static string IntToStr(int value)
        {
            return value.ToString();
        }
        
    }
}
