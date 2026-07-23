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
        
        // ==================== SPS-DATEN STRUKTUREN ====================
        
        /// <summary>
        /// Initialisiert die SPS-Datenstrukturen
        /// Äquivalent zu den Arrays in DBMain.pas
        /// </summary>
        public static S7MainData InitializeS7Data()
        {
            var s7Data = new S7MainData();
            
            // Maschinen-Liste initialisieren
            s7Data.Maschinen = new System.Collections.Generic.List<MaschinenDaten>();
            s7Data.SignalMaschinen = new SignalMaschineList();
            
            // SPS-Arrays initialisieren
            for (int i = 0; i <= Max_ANZAHL; i++)
            {
                s7Data.StueckGesamt[i] = new SPS_Daten_DWord();
                s7Data.StueckAuftragGesamt[i] = new SPS_Daten_DWord();
                s7Data.StueckAuftragSchicht[i] = new SPS_Daten_DWord();
                s7Data.StueckSchicht[i] = new SPS_Daten_DWord();
                s7Data.Betriebsstunden[i] = new SPS_Daten_DWord();
                s7Data.Taktzeit[i] = new SPS_Daten_DWord();
                s7Data.LaufzeitGes[i] = new SPS_Daten_DWord();
                s7Data.LaufzeitSchicht[i] = new SPS_Daten_DWord();
                s7Data.StueckPruefGesamt[i] = new SPS_Daten_DWord();
                s7Data.StueckPruefAuftragGesamt[i] = new SPS_Daten_DWord();
                s7Data.StueckPruefAuftragSchicht[i] = new SPS_Daten_DWord();
                s7Data.StueckPruefSchicht[i] = new SPS_Daten_DWord();
                s7Data.StueckPackGesamt[i] = new SPS_Daten_DWord();
                s7Data.StueckPackAuftragGesamt[i] = new SPS_Daten_DWord();
                s7Data.StueckPackAuftragSchicht[i] = new SPS_Daten_DWord();
                s7Data.StueckPackSchicht[i] = new SPS_Daten_DWord();
                s7Data.Terminal_AuftragNr[i] = new SPS_Daten_Word();
                
                s7Data.Maschinen_Zustand[i] = new SPS_Daten_Word();
                s7Data.Terminal_Einheit[i] = new SPS_Daten_Word();
                s7Data.Terminal_StoerKommtGeht[i] = new SPS_Daten_Word();
                s7Data.Terminal_Stoer_Nr[i] = new SPS_Daten_Word();
                s7Data.Terminal_Still_Stoer[i] = new SPS_Daten_Word();
                s7Data.Terminal_Etikett[i] = new SPS_Daten_Word();
                s7Data.Programm_Nr[i] = new SPS_Daten_Word();
                s7Data.Terminal_AuftragNr_ASCII[i] = new SPS_Daten_Word();
                
                s7Data.BCD[i] = new SPS_Daten_Byte();
                s7Data.StillstandNr_SPS[i] = new SPS_Daten_DWord();
                s7Data.StillstandNr_SPS_Save[i] = new SPS_Daten_DWord();
                s7Data.Job_Stueckzahl[i] = new SPS_Daten_Byte();
                
                s7Data.BCD_Read[i] = new SPS_Daten_Bool();
                s7Data.HandAuto[i] = new SPS_Daten_Bool();
                s7Data.MaschProgrammbetrieb[i] = new SPS_Daten_Bool();
                s7Data.Auftrag_Freigabe[i] = new SPS_Daten_Bool();
                s7Data.Programm_Start[i] = new SPS_Daten_Bool();
                s7Data.Programm_Ende[i] = new SPS_Daten_Bool();
                s7Data.Terminal_Menge_Gebucht[i] = new SPS_Daten_Bool();
                s7Data.Terminal_Stillstand_Gebucht[i] = new SPS_Daten_Bool();
                s7Data.Terminal_Auftrag_Beendet[i] = new SPS_Daten_Bool();
                s7Data.Terminal_Auftrag_Unterbrochen[i] = new SPS_Daten_Bool();
                s7Data.MaschWarmtrennen[i] = new SPS_Daten_Bool();
                
                s7Data.IndivStillstand[i] = new SPS_Daten_Bool_Dyn();
                s7Data.SPC_Signal[i] = new SPS_Daten_DWORD_Dyn();
            }
            
            // Barcode-Arrays initialisieren
            for (int i = 0; i <= MAX_BARCODE; i++)
            {
                s7Data.Barcode[i] = new SPS_Daten_Word();
                s7Data.Barcode_2[i] = new SPS_Daten_Word();
                s7Data.Barcode_3[i] = new SPS_Daten_Word();
            }
            
            // Einzelne Signale initialisieren
            s7Data.Barcode_Gelesen = new SPS_Daten_Bool();
            s7Data.Barcode_Gelesen_2 = new SPS_Daten_Bool();
            s7Data.Barcode_Gelesen_3 = new SPS_Daten_Bool();
            s7Data.Terminal_Maschine = new SPS_Daten_Word();
            s7Data.Reparatur_Start_Ende = new SPS_Daten_Word();
            s7Data.AuftragStart1 = new SPS_Daten_Byte();
            s7Data.AuftragStart2 = new SPS_Daten_Byte();
            s7Data.AuftragStart3 = new SPS_Daten_Byte();
            s7Data.Terminal_Eingabe = new SPS_Daten_Bool();
            
            return s7Data;
        }
    }
}
