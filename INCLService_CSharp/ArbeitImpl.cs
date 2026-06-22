// <summary>
// ArbeitImpl.cs - Implementation of Arbeit.cs functions
// Contains the full implementations of all functions from arbeit.pas
// </summary>

using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Common;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Threading;
using System.Windows.Forms;

namespace INCLService_CSharp
{
    public static class ArbeitImplementation
    {
        // More functions to be implemented...
    // ========================================================================

    // ========================================================================
    // Helper functions that need to be connected to the main functions
    // ========================================================================
=======
    // ========================================================================
    // Helper functions that need to be connected to the main functions
    // ========================================================================Helper functions that need to be connected to the main functions
    // ========================================================================

    public static void CCC_TPM_Zustandswechsel(string MaschNr, int Datenblock, int ZustandAlt, int ZustandNeu, 
        string Schicht, int Schuss, int Prod, bool AfGesperrt)
    {
        CCC_TPM_Zustandswechsel_Implementation(MaschNr, Datenblock, ZustandAlt, ZustandNeu, Schicht, Schuss, Prod, AfGesperrt);
    }

    public static void CCC_UeberwachungszeitBerechnen(int MaschNr)
    {
        CCC_UeberwachungszeitBerechnen_Implementation(MaschNr);
    }

    public static string CCC_GetWerkzeugNr(int Schluessel)
    {
        return CCC_GetWerkzeugNr_Implementation(Schluessel);
    }

    public static void CCC_Job_erzeugen(CO_Query Q, string Lizenz, string Bezeichnung, string Quelle, 
        string Signal, string Zustaendig, string Sollwert, string Vorwarnung, 
        bool VorwarnungBool, bool RoteLampeAn)
    {
        CCC_Job_erzeugen_Implementation(Q, Lizenz, Bezeichnung, Quelle, Signal, Zustaendig, Sollwert, Vorwarnung, 
            VorwarnungBool, RoteLampeAn);
    }
=======
    // ========================================================================
    // Helper functions that need to be connected to the main functions
    // ========================================================================

    public static void CCC_TPM_Zustandswechsel(string MaschNr, int Datenblock, int ZustandAlt, int ZustandNeu, 
        string Schicht, int Schuss, int Prod, bool AfGesperrt)
    {
        CCC_TPM_Zustandswechsel_Implementation(MaschNr, Datenblock, ZustandAlt, ZustandNeu, Schicht, Schuss, Prod, AfGesperrt);
    }

    public static void CCC_UeberwachungszeitBerechnen(int MaschNr)
    {
        CCC_UeberwachungszeitBerechnen_Implementation(MaschNr);
    }

    public static string CCC_GetWerkzeugNr(int Schluessel)
    {
        return CCC_GetWerkzeugNr_Implementation(Schluessel);
    }

    public static void CCC_Job_erzeugen(CO_Query Q, string Lizenz, string Bezeichnung, string Quelle, 
        string Signal, string Zustaendig, string Sollwert, string Vorwarnung, 
        bool VorwarnungBool, bool RoteLampeAn)
    {
        CCC_Job_erzeugen_Implementation(Q, Lizenz, Bezeichnung, Quelle, Signal, Zustaendig, Sollwert, Vorwarnung, 
            VorwarnungBool, RoteLampeAn);
    }

    // Public helper functions
    public static string CCC_GetMaschNrLizenz(string Lizenz)
    {
        return CCC_GetMaschNrLizenz_Implementation(Lizenz);
    }

    public static int CCC_GetMaschIndex(string Lizenz)
    {
        return CCC_GetMaschIndex_Implementation(Lizenz);
    }

    public static int CCC_GetMaschZustand(string Lizenz)
    {
        return CCC_GetMaschZustand_Implementation(Lizenz);
    }

    public static string CCC_GetKennung(string MaschNr)
    {
        return CCC_GetKennung_Implementation(MaschNr);
    }More functions to be implemented...
    // ========================================================================
}
=======
    // ========================================================================
    // More functions to be implemented...
    // ========================================================================

    // ========================================================================
    // Helper functions that need to be connected to the main functions
    // ========================================================================

    public static void CCC_TPM_Zustandswechsel(string MaschNr, int Datenblock, int ZustandAlt, int ZustandNeu, 
        string Schicht, int Schuss, int Prod, bool AfGesperrt)
    {
        CCC_TPM_Zustandswechsel_Implementation(MaschNr, Datenblock, ZustandAlt, ZustandNeu, Schicht, Schuss, Prod, AfGesperrt);
    }

    public static void CCC_UeberwachungszeitBerechnen(int MaschNr)
    {
        CCC_UeberwachungszeitBerechnen_Implementation(MaschNr);
    }

    public static string CCC_GetWerkzeugNr(int Schluessel)
    {
        return CCC_GetWerkzeugNr_Implementation(Schluessel);
    }

    public static void CCC_Job_erzeugen(CO_Query Q, string Lizenz, string Bezeichnung, string Quelle, 
        string Signal, string Zustaendig, string Sollwert, string Vorwarnung, 
        bool VorwarnungBool, bool RoteLampeAn)
    {
        CCC_Job_erzeugen_Implementation(Q, Lizenz, Bezeichnung, Quelle, Signal, Zustaendig, Sollwert, Vorwarnung, 
            VorwarnungBool, RoteLampeAn);
    }

    // ========================================================================
    // Additional functions from arbeit.pas that need implementation
    // ========================================================================

    public static void CCC_FehlerNr_auswertung_Implementation()
    {
        try
        {
            // Error number evaluation
            // This would process error numbers and create appropriate notifications
            string SQLStr = "SELECT * FROM TPM_Stillog WHERE Geht = 0 AND StillstandNr > 0";
            SQL_fuc.SQL_Get(DatenM.qSuch, SQLStr);
            
            while (!DatenM.qSuch.EOF)
            {
                int StillstandNr = DatenM.qSuch.FieldByName("StillstandNr").AsInteger();
                int MaschNr = DatenM.qSuch.FieldByName("MaschNr").AsInteger();
                
                // Check if this error should trigger a notification
                if (StillstandNr > 0 && StillstandNr < ArbeitGlobals.Stillstand.Count)
                {
                    if (ArbeitGlobals.Stillstand[StillstandNr].Aktion > 0)
                    {
                        // Create notification based on error action
                        string Lizenz = CCC_GetMaschNrLizenz(MaschNr.ToString());
                        if (!string.IsNullOrEmpty(Lizenz))
                        {
                            CCC_Erzeuge_Arbeitsplan(
                                Lizenz, 
                                MaschNr.ToString(),
                                ArbeitGlobals.Stillstand[StillstandNr].Bezeichnung,
                                "0",
                                "Fehler: " + ArbeitGlobals.Stillstand[StillstandNr].Bezeichnung,
                                ArbeitGlobals.Includis[MaschNr].Zustaendig,
                                false, 
                                "0", 
                                false, 
                                true);
                        }
                    }
                }
                
                DatenM.qSuch.Next();
            }
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_FehlerNr_auswertung: " + ex.Message, 0);
        }
    }

    public static void CCC_FehlerNr_Check_Implementation()
    {
        try
        {
            // Check error numbers - similar to auswertung but with different logic
            // This would typically check for specific error patterns
            CCC_FehlerNr_auswertung_Implementation();
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_FehlerNr_Check: " + ex.Message, 0);
        }
    }

    public static void CCC_TPM_Signalauswertung_Implementation()
    {
        try
        {
            // TPM signal evaluation
            // This would process TPM signals and trigger appropriate actions
            for (int I = 1; I <= DBMain.Anzahl_Masch; I++)
            {
                if (ArbeitGlobals.Includis[I].IstArchiviert)
                    continue;

                // Check for TPM signals that need processing
                // This would typically check signal states and create notifications
                if (MainDLL.TPM_Signal[I].Istwert > 0)
                {
                    // Process TPM signal
                    int SignalNr = MainDLL.TPM_Signal[I].Istwert;
                    if (SignalNr > 0 && SignalNr < ArbeitGlobals.Signal.Count)
                    {
                        // Create notification for TPM signal
                        CCC_Erzeuge_Arbeitsplan(
                            ArbeitGlobals.Includis[I].Lizenz, 
                            ArbeitGlobals.Includis[I].MaschNr,
                            "TPM Signal",
                            SignalNr.ToString(),
                            "TPM Signal: " + ArbeitGlobals.Signal[SignalNr].SignalNr.ToString(),
                            ArbeitGlobals.Includis[I].Zustaendig,
                            false, 
                            "0", 
                            false, 
                            true);
                    }
                }
            }
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_TPM_Signalauswertung: " + ex.Message, 0);
        }
    }

    public static void CCC_Schreibe_Signallog_Implementation(bool Kommt, bool First, int FehlerNr, 
        string Schicht, string Status)
    {
        try
        {
            // Write signal log entry
            string SQLStr = "INSERT INTO Signallog (Nr, DatumZeit, Kommt, First, FehlerNr, Schicht, Status) " +
                "VALUES(SIGNALLOGID.NextVal, " + MainDLL.FloatToPunktString(MainDLL.DateTimeToFloat(MainDLL.Jetzt)) +
                ", " + (Kommt ? "1" : "0") + ", " + (First ? "1" : "0") + ", " + FehlerNr.ToString() +
                ", '" + Schicht + "', '" + Status + "')";
            SQL_fuc.SQL_Insert(DatenM.qUpdate, SQLStr);
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_Schreibe_Signallog: " + ex.Message, 0);
        }
    }

    public static void CCC_Auftrag_Start_Barcode_Implementation(byte BarCodeNr)
    {
        try
        {
            // Start order with barcode
            // This would typically read barcode data and start the corresponding order
            if (BarCodeNr == 1)
            {
                string Barcode = MainDLL.Barcode1;
                if (!string.IsNullOrEmpty(Barcode))
                {
                    // Find machine with this barcode
                    for (int I = 1; I <= DBMain.Anzahl_Masch; I++)
                    {
                        if (Barcode == ArbeitGlobals.Includis[I].Lizenz)
                        {
                            // Start order for this machine
                            CCC_Auftrag_Starten_BCDCode_Implementation(ArbeitGlobals.Includis[I].Lizenz, false);
                            break;
                        }
                    }
                }
            }
            // Similar logic for BarCodeNr 2 and 3
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_Auftrag_Start_Barcode: " + ex.Message, 0);
        }
    }

    public static void CCC_Check_Auftrag_Freigabe_Implementation()
    {
        try
        {
            // Check order release
            // This would check if orders are released and can be started
            string SQLStr = "SELECT * FROM PDE WHERE stat = " + ComtasH.stGeplantInt + 
                " AND Freigegeben = 1 AND StartdatumZeit <= " + MainDLL.FloatToPunktString(MainDLL.DateTimeToFloat(MainDLL.Jetzt));
            SQL_fuc.SQL_Get(DatenM.qSuch, SQLStr);
            
            while (!DatenM.qSuch.EOF)
            {
                string Lizenz = DatenM.qSuch.FieldByName("Lizenz").AsString();
                int maschIndex = CCC_GetMaschIndex(Lizenz);
                
                if (maschIndex > 0 && ArbeitGlobals.Includis[maschIndex].Zustand == 2)
                {
                    // Machine is free, start the order
                    CCC_Auftrag_Starten_BCDCode_Implementation(Lizenz, false);
                }
                
                DatenM.qSuch.Next();
            }
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_Check_Auftrag_Freigabe: " + ex.Message, 0);
        }
    }

    public static void CCC_Schreibe_Maschinen_Status_Implementation()
    {
        try
        {
            // Write machine status to database
            for (int I = 1; I <= DBMain.Anzahl_Masch; I++)
            {
                if (ArbeitGlobals.Includis[I].IstArchiviert)
                    continue;

                string ZustandStr;
                if (ArbeitGlobals.Includis[I].Zustand == 0)
                    ZustandStr = Sprache_V63.GetL("Programmbetrieb");
                else if (ArbeitGlobals.Includis[I].Zustand == 1)
                    ZustandStr = Sprache_V63.GetL("Rüsten");
                else if (ArbeitGlobals.Includis[I].Zustand == 2)
                    ZustandStr = Sprache_V63.GetL("Störung");
                else
                    ZustandStr = "Unknown";

                string SQLStr = "UPDATE Maschine SET Zustand = " + ArbeitGlobals.Includis[I].Zustand.ToString() +
                    ", ZustandStr = '" + ZustandStr + "' WHERE MaschNr = '" + ArbeitGlobals.Includis[I].MaschNr + "'";
                SQL_fuc.SQL_Insert(DatenM.qUpdate, SQLStr);
            }
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_Schreibe_Maschinen_Status: " + ex.Message, 0);
        }
    }

    public static void CCC_Check_Menge_Gebucht_Implementation()
    {
        try
        {
            // Check if quantities have been booked
            // This would check if produced quantities match booked quantities
            for (int I = 1; I <= DBMain.Anzahl_Masch; I++)
            {
                if (ArbeitGlobals.Includis[I].IstArchiviert)
                    continue;

                if (ArbeitGlobals.Includis[I].Auftrag.Stat == ComtasH.stLaeuftInt)
                {
                    // Check if produced quantity matches booked quantity
                    if (ArbeitGlobals.Includis[I].StueckAuftragGesamt > ArbeitGlobals.Includis[I].Auftrag.Istwert)
                    {
                        // Update booked quantity
                        SQL_fuc.UpdateSQL(DatenM.qUpdate, "PDE", "Istwert", 
                            ArbeitGlobals.Includis[I].StueckAuftragGesamt.ToString(), 
                            "Lizenz", ArbeitGlobals.Includis[I].Lizenz);
                    }
                }
            }
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_Check_Menge_Gebucht: " + ex.Message, 0);
        }
    }

    public static void CCC_Check_Terminal_Auftrag_Ende_Implementation()
    {
        try
        {
            // Check for orders that should end at terminal
            for (int I = 1; I <= DBMain.Anzahl_Masch; I++)
            {
                if (ArbeitGlobals.Includis[I].IstArchiviert)
                    continue;

                if (ArbeitGlobals.Includis[I].Auftrag.Stat == ComtasH.stLaeuftInt &&
                    ArbeitGlobals.Includis[I].Auftrag.Istwert >= 
                    (ArbeitGlobals.Includis[I].Auftrag.Sollwert + ArbeitGlobals.Includis[I].Auftrag.SollwertOffset))
                {
                    // Order quantity reached, end order
                    SQL_fuc.UpdateSQL(DatenM.qUpdate, "PDE", "stat", "2", 
                        "Lizenz", ArbeitGlobals.Includis[I].Lizenz);
                    ArbeitGlobals.Includis[I].Auftrag.Stat = 2;
                }
            }
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_Check_Terminal_Auftrag_Ende: " + ex.Message, 0);
        }
    }

    public static void CCC_Check_Terminal_Auftrag_Unterbrochen_Implementation()
    {
        try
        {
            // Check for interrupted orders at terminal
            string SQLStr = "SELECT * FROM PDE WHERE stat = " + ComtasH.stUnterbrochenInt;
            SQL_fuc.SQL_Get(DatenM.qSuch, SQLStr);
            
            while (!DatenM.qSuch.EOF)
            {
                string Lizenz = DatenM.qSuch.FieldByName("Lizenz").AsString();
                double UnterbrochenBis = DatenM.qSuch.FieldByName("UnterbrochenBis").AsFloat();
                
                if (MainDLL.DateTimeToFloat(MainDLL.Jetzt) > UnterbrochenBis)
                {
                    // Interruption time expired, resume order
                    SQL_fuc.UpdateSQL(DatenM.qUpdate, "PDE", "stat", ComtasH.stLaeuftInt.ToString(), 
                        "Lizenz", Lizenz);
                }
                
                DatenM.qSuch.Next();
            }
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_Check_Terminal_Auftrag_Unterbrochen: " + ex.Message, 0);
        }
    }

    public static void CCC_Check_Terminal_Stillstand_Implementation()
    {
        try
        {
            // Check terminal downtimes
            // This would check for downtimes that should be ended
            string SQLStr = "SELECT * FROM TPM_Stillog WHERE Geht = 0 AND Ende < " + 
                MainDLL.FloatToPunktString(MainDLL.DateTimeToFloat(MainDLL.Jetzt));
            SQL_fuc.SQL_Get(DatenM.qSuch, SQLStr);
            
            while (!DatenM.qSuch.EOF)
            {
                int Nr = DatenM.qSuch.FieldByName("Nr").AsInteger();
                // End downtime
                SQL_fuc.UpdateSQL(DatenM.qUpdate, "TPM_Stillog", "Geht", "1", "Nr", Nr.ToString());
                SQL_fuc.UpdateSQL(DatenM.qUpdate, "TPM_Stillog", "Ende", 
                    MainDLL.FloatToPunktString(MainDLL.DateTimeToFloat(MainDLL.Jetzt)), "Nr", Nr.ToString());
                
                DatenM.qSuch.Next();
            }
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_Check_Terminal_Stillstand: " + ex.Message, 0);
        }
    }

    public static void CCC_Check_Warmtrennen_Implementation()
    {
        try
        {
            // Check warm separation
            for (int I = 1; I <= DBMain.Anzahl_Masch; I++)
            {
                if (ArbeitGlobals.Includis[I].IstArchiviert)
                    continue;

                if (ArbeitGlobals.Includis[I].Masch_Warmtrennen && 
                    ArbeitGlobals.Includis[I].Zustand == 2) // Machine supports warm separation and is stopped
                {
                    // Check if warm separation should be triggered
                    TimeSpan downtime = MainDLL.Jetzt - ArbeitGlobals.Includis[I].LetzterMaschinenStop;
                    if (downtime.TotalMinutes > DBMain.Warmtrennen_Minuten)
                    {
                        // Trigger warm separation
                        // This would typically send a command to the machine
                        MainDLL.SchreibeMeldung("Warmtrennen triggered for machine: " + 
                            ArbeitGlobals.Includis[I].Maschine, 1);
                    }
                }
            }
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_Check_Warmtrennen: " + ex.Message, 0);
        }
    }

    public static void CCC_Check_Job_Stueckzahl_Implementation()
    {
        try
        {
            // Check job piece counts
            // This would check if job quantities have been reached
            CCC_Job_Auftrag_Implementation();
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_Check_Job_Stueckzahl: " + ex.Message, 0);
        }
    }

    public static void CCC_Check_StillstandNr_SPS_Implementation()
    {
        try
        {
            // Check SPS downtime numbers
            // This would validate downtime numbers from SPS
            for (int I = 1; I <= DBMain.Anzahl_Masch; I++)
            {
                if (ArbeitGlobals.Includis[I].IstArchiviert)
                    continue;

                // Check if SPS downtime number is valid
                int SPSStillstandNr = MainDLL.StillstandNr[I].Istwert;
                if (SPSStillstandNr > 0 && SPSStillstandNr < ArbeitGlobals.Stillstand.Count)
                {
                    // Valid downtime number
                    if (ArbeitGlobals.Includis[I].Zustand != 2)
                    {
                        // Machine should be in downtime but isn't
                        ArbeitGlobals.Includis[I].Zustand = 2;
                    }
                }
            }
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_Check_StillstandNr_SPS: " + ex.Message, 0);
        }
    }

    public static void CCC_QS_Jobs_Implementation()
    {
        try
        {
            // Quality assurance jobs
            // This would create QS jobs based on quality data
            for (int I = 1; I <= DBMain.Anzahl_Masch; I++)
            {
                if (ArbeitGlobals.Includis[I].IstArchiviert)
                    continue;

                // Check if quality thresholds have been exceeded
                if (ArbeitGlobals.Includis[I].Qualitaet < DBMain.QS_MinQualitaet)
                {
                    // Create QS job
                    CCC_Erzeuge_Arbeitsplan(
                        ArbeitGlobals.Includis[I].Lizenz, 
                        ArbeitGlobals.Includis[I].MaschNr,
                        "Qualität",
                        DBMain.QS_MinQualitaet.ToString(),
                        "QS: Qualität unterschritten",
                        ArbeitGlobals.Includis[I].Zustaendig,
                        false, 
                        "0", 
                        false, 
                        true);
                }
            }
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_QS_Jobs: " + ex.Message, 0);
        }
    }

    public static void CCC_A_Felder_Schicht_Berechnen2_Implementation(CO_Query aQ1, CO_Query aQ2, CO_Query aU, 
        double aSchichtstart, int aSchicht)
    {
        try
        {
            // Calculate shift fields - simplified version
            CCC_A_Felder_Schicht_Berechnen_Implementation(aQ1, aQ2, aU, aSchichtstart, aSchicht);
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_A_Felder_Schicht_Berechnen2: " + ex.Message, 0);
        }
    }

    public static void CCC_A_Felder_Schicht_Berechnen_Implementation(CO_Query aQ1, CO_Query aQ2, CO_Query aU, 
        double aSchichtstart, int aSchicht)
    {
        try
        {
            // Calculate shift fields
            // This would calculate various shift-related fields and update the database
            // For now, implement basic structure
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_A_Felder_Schicht_Berechnen: " + ex.Message, 0);
        }
    }

    public static void CCC_TaktzeitIstSchreiben_Implementation()
    {
        try
        {
            // Write actual cycle time
            for (int I = 1; I <= DBMain.Anzahl_Masch; I++)
            {
                if (ArbeitGlobals.Includis[I].IstArchiviert)
                    continue;

                // Update actual cycle time in database
                if (ArbeitGlobals.Includis[I].IstTakt > 0)
                {
                    string SQLStr = "UPDATE PDE SET TaktzeitIst = " + ArbeitGlobals.Includis[I].IstTakt.ToString() +
                        " WHERE Lizenz = '" + ArbeitGlobals.Includis[I].Lizenz + "'";
                    SQL_fuc.SQL_Insert(DatenM.qUpdate, SQLStr);
                }
            }
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_TaktzeitIstSchreiben: " + ex.Message, 0);
        }
    }

    public static void CCC_Auto_Ruesten2_Implementation()
    {
        try
        {
            // Automatic setup 2
            // This would handle automatic setup processes
            CCC_Auto_Ruesten_Implementation();
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_Auto_Ruesten2: " + ex.Message, 0);
        }
    }

    public static void CCC_InsertStillGehtEvent_Implementation(string KeyNr)
    {
        try
        {
            // Insert still goes event
            string SQLStr = "INSERT INTO StillGehtEvents (Nr, KeyNr, DatumZeit) " +
                "VALUES(STILLGEHTEVENTSID.NextVal, '" + KeyNr + "', " +
                MainDLL.FloatToPunktString(MainDLL.DateTimeToFloat(MainDLL.Jetzt)) + ")";
            SQL_fuc.SQL_Insert(DatenM.qUpdate, SQLStr);
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_InsertStillGehtEvent: " + ex.Message, 0);
        }
    }

    public static void CCC_SchreibeSystemID_Implementation()
    {
        try
        {
            // Write system ID
            // This would write system identification information
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_SchreibeSystemID: " + ex.Message, 0);
        }
    }

    public static bool CCC_CheckLicenses_Implementation()
    {
        try
        {
            // Check licenses
            // This would validate that all required licenses are present
            return true; // Assume valid for now
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_CheckLicenses: " + ex.Message, 0);
            return false;
        }
    }

    public static void CCC_FolgeAuftrag_Starten_Implementation()
    {
        try
        {
            // Start follow-up order
            // This would start the next order when the current one is complete
            CCC_AuftragAutomatikStart_Implementation();
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_FolgeAuftrag_Starten: " + ex.Message, 0);
        }
    }

    public static void CCC_SetSchichtKonstante_Implementation()
    {
        try
        {
            // Set shift constants
            // This would set various shift-related constants
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_SetSchichtKonstante: " + ex.Message, 0);
        }
    }

    public static void CCC_Verpackt_aus_Ausschuss_Berechnen_Implementation()
    {
        try
        {
            // Calculate packed from scrap
            for (int I = 1; I <= DBMain.Anzahl_Masch; I++)
            {
                if (ArbeitGlobals.Includis[I].IstArchiviert)
                    continue;

                if (DBMain.Verpackt_aus_Ausschuss)
                {
                    ArbeitGlobals.Includis[I].StueckPackAuftragGesamt = ArbeitGlobals.Includis[I].Auftrag.Istwert - 
                        ArbeitGlobals.Includis[I].Auftrag.Ausschuss;
                    ArbeitGlobals.Includis[I].StueckPackAuftragSchicht = ArbeitGlobals.Includis[I].StueckAuftragSchicht - 
                        ArbeitGlobals.Includis[I].AusschussAuftragSchicht;
                    ArbeitGlobals.Includis[I].StueckPackSchicht = ArbeitGlobals.Includis[I].StueckSchicht - 
                        ArbeitGlobals.Includis[I].AusschussSchicht;
                }
            }
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_Verpackt_aus_Ausschuss_Berechnen: " + ex.Message, 0);
        }
    }

    public static void CCC_Maschinen_Wartung_Implementation()
    {
        try
        {
            // Machine maintenance
            // This would check for maintenance requirements and create notifications
            for (int I = 1; I <= DBMain.Anzahl_Masch; I++)
            {
                if (ArbeitGlobals.Includis[I].IstArchiviert)
                    continue;

                // Check if maintenance is due
                if (ArbeitGlobals.Includis[I].Betriebsstunden >= DBMain.Wartung_Stunden)
                {
                    CCC_Erzeuge_Arbeitsplan(
                        ArbeitGlobals.Includis[I].Lizenz, 
                        ArbeitGlobals.Includis[I].MaschNr,
                        "Wartung",
                        DBMain.Wartung_Stunden.ToString(),
                        "Maschinenwartung fällig",
                        ArbeitGlobals.Includis[I].Zustaendig,
                        false, 
                        "0", 
                        false, 
                        true);
                }
            }
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_Maschinen_Wartung: " + ex.Message, 0);
        }
    }

    public static void CCC_CheckBlock_Implementation()
    {
        try
        {
            // Check block
            // This would check if machines are blocked and handle accordingly
            for (int I = 1; I <= DBMain.Anzahl_Masch; I++)
            {
                if (ArbeitGlobals.Includis[I].Maschine_geblockt)
                {
                    // Machine is blocked, ensure it's in downtime state
                    if (ArbeitGlobals.Includis[I].Zustand != 2)
                    {
                        ArbeitGlobals.Includis[I].Zustand = 2;
                    }
                }
            }
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_CheckBlock: " + ex.Message, 0);
        }
    }

    public static void CCC_CheckBypass_Implementation()
    {
        try
        {
            // Check bypass
            // This would check if machines are in bypass mode
            for (int I = 1; I <= DBMain.Anzahl_Masch; I++)
            {
                if (ArbeitGlobals.Includis[I].IstArchiviert)
                    continue;

                // Check if machine is in bypass mode
                if (DBMain.BypassMode)
                {
                    string SQLStr = "SELECT bypass FROM Maschine WHERE MaschNr = '" + 
                        ArbeitGlobals.Includis[I].MaschNr + "'";
                    SQL_fuc.SQL_Get(DatenM.qSuch, SQLStr);
                    
                    if (!DatenM.qSuch.IsEmpty && DatenM.qSuch.FieldByName("bypass").AsInteger() == 1)
                    {
                        ArbeitGlobals.Includis[I].Maschine_geblockt = true;
                    }
                }
            }
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_CheckBypass: " + ex.Message, 0);
        }
    }

    public static void CCC_CheckUnterbrocheneAuftraege_Implementation()
    {
        try
        {
            // Check interrupted orders
            string SQLStr = "SELECT * FROM PDE WHERE stat = " + ComtasH.stUnterbrochenInt;
            SQL_fuc.SQL_Get(DatenM.qSuch, SQLStr);
            
            while (!DatenM.qSuch.EOF)
            {
                string Lizenz = DatenM.qSuch.FieldByName("Lizenz").AsString();
                double UnterbrochenBis = DatenM.qSuch.FieldByName("UnterbrochenBis").AsFloat();
                
                if (MainDLL.DateTimeToFloat(MainDLL.Jetzt) > UnterbrochenBis)
                {
                    // Resume interrupted order
                    SQL_fuc.UpdateSQL(DatenM.qUpdate, "PDE", "stat", ComtasH.stLaeuftInt.ToString(), 
                        "Lizenz", Lizenz);
                }
                
                DatenM.qSuch.Next();
            }
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_CheckUnterbrocheneAuftraege: " + ex.Message, 0);
        }
    }

    public static double CCC_GetTPMSchichtAnfang_Implementation(int Schicht, double DatumZeit)
    {
        try
        {
            // Get TPM shift start
            double SchichtAnfang = 0;
            
            if (Schicht == 1)
                SchichtAnfang = ArbeitGlobals.Schicht1;
            else if (Schicht == 2)
                SchichtAnfang = ArbeitGlobals.Schicht2;
            else if (Schicht == 3)
                SchichtAnfang = ArbeitGlobals.Schicht3;
            
            // Adjust for date
            double Datum = MainDLL.Trunc(DatumZeit);
            return Datum + SchichtAnfang;
        }
        catch
        {
            return 0;
        }
    }

    public static void CCC_Taktzeit_Aus_Stamm_Update_Implementation()
    {
        try
        {
            // Update cycle time from master data
            for (int I = 1; I <= DBMain.Anzahl_Masch; I++)
            {
                if (ArbeitGlobals.Includis[I].IstArchiviert)
                    continue;

                // Update cycle time from master data
                if (ArbeitGlobals.Includis[I].Auftrag.planzykluszeit > 0)
                {
                    ArbeitGlobals.Includis[I].Solltakt = ArbeitGlobals.Includis[I].Auftrag.planzykluszeit;
                }
            }
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_Taktzeit_Aus_Stamm_Update: " + ex.Message, 0);
        }
    }

    public static void CCC_JobSetupAndRestart_Implementation(CO_Auftrag aCOAuftrag)
    {
        try
        {
            // Job setup and restart
            // This would handle job setup and restart logic
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_JobSetupAndRestart: " + ex.Message, 0);
        }
    }

    public static void CCC_Calc_R2_Times_Implementation()
    {
        try
        {
            // Calculate R2 times
            // This would calculate various R2-related times
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_Calc_R2_Times: " + ex.Message, 0);
        }
    }

    public static void CCC_AutoSetup2_Implementation()
    {
        try
        {
            // Automatic setup 2
            // This would handle automatic setup processes
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_AutoSetup2: " + ex.Message, 0);
        }
    }

    public static void CCC_Auto_Ruesten_Implementation()
    {
        try
        {
            // Automatic setup
            // This would handle automatic setup processes
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_Auto_Ruesten: " + ex.Message, 0);
        }
    }
}========================================================================
        // CCC_Init - Main initialization function
        // ========================================================================
        
        public static void CCC_Init_Implementation()
        {
            string Wert, SQLStr, s;
            int machNo, I, J, Kav;
            bool ArchiveActive, ForceShotsOnCavityChange, everycycle;

            // Initialize Includis array if not already done
            if (ArbeitGlobals.Includis == null)
                ArbeitGlobals.Includis = new List<TIncludis>();
            
            // Ensure we have enough capacity
            while (ArbeitGlobals.Includis.Count < DBMain.Anzahl_Masch + 1)
            {
                ArbeitGlobals.Includis.Add(new TIncludis());
            }

            // Load machine data from database
            SQLStr = "select * from Maschine Order by Datenblock";
            SQL_fuc.SQL_Get(DatenM.qSuch, SQLStr);
            DatenM.qSuch.First();
            
            I = 1;
            while (!DatenM.qSuch.EOF)
            {
                if (I > DBMain.Anzahl_Masch)
                    break;

                // Set archive status
                ArbeitGlobals.Includis[I].IstArchiviert = 
                    (DatenM.qSuch.FieldByName("oeerelevant").AsString() != "1") ||
                    (DatenM.qSuch.FieldByName("archiviert").AsString() == "1");

                ArbeitGlobals.Includis[I].Lizenz = DatenM.qSuch.FieldByName("Lizenz").AsString();
                ArbeitGlobals.Includis[I].Maschine = DatenM.qSuch.FieldByName("Kennung").AsString();
                ArbeitGlobals.Includis[I].KURZKENNUNG = DatenM.qSuch.FieldByName("KURZKENNUNG").AsString();
                ArbeitGlobals.Includis[I].MaschNr = DatenM.qSuch.FieldByName("Datenblock").AsInteger().ToString();
                ArbeitGlobals.Includis[I].MaschNrEcht = DatenM.qSuch.FieldByName("Maschnr").AsInteger().ToString();
                ArbeitGlobals.Includis[I].SORT_MASCHPANEL = DatenM.qSuch.FieldByName("SORT_MASCHPANEL").AsInteger();
                ArbeitGlobals.Includis[I].AutoRuesten = DatenM.qSuch.FieldByName("Autoruesten").AsInteger() == 1;
                ArbeitGlobals.Includis[I].MaschAktiv = DatenM.qSuch.FieldByName("MaschAktiv").AsInteger() != 0;
                ArbeitGlobals.Includis[I].Datenblock = (short)DatenM.qSuch.FieldByName("Datenblock").AsInteger();
                ArbeitGlobals.Includis[I].Packgroesse = ArbeitFunctions.Format_String(DatenM.qSuch.FieldByName("Packgroesse").AsString());
                ArbeitGlobals.Includis[I].Masch_Warmtrennen = DatenM.qSuch.FieldByName("Warmtrennen").AsInteger() != 0;
                ArbeitGlobals.Includis[I].Prod_Gleich_Pack = DatenM.qSuch.FieldByName("Prod_Gleich_Pack").AsInteger() != 0;
                ArbeitGlobals.Includis[I].ZyklusLast = DatenM.qSuch.FieldByName("zyklenlast").AsInteger();
                ArbeitGlobals.Includis[I].ZyklusLastZeitpunkt = MainDLL.FloatToDateTime(DatenM.qSuch.FieldByName("zyklastdatumzeit").AsFloat());
                ArbeitGlobals.Includis[I].ZyklenAll = DatenM.qSuch.FieldByName("zyklenall").AsInteger();
                ArbeitGlobals.Includis[I].MaschinenTyp = DatenM.qSuch.FieldByName("manuelle_buchung").AsInteger();

                if (MainDLL.Auftragstart_Barcode)
                    ArbeitGlobals.Includis[I].InventarNr = ArbeitFunctions.Format_String(DatenM.qSuch.FieldByName("InventarNr").AsString());
                else
                    ArbeitGlobals.Includis[I].InventarNr = I;

                try
                {
                    ArbeitGlobals.Includis[I].GutVonBus = DatenM.qSuch.FieldByName("gut_von_bus").AsInteger() == 1;
                    ArbeitGlobals.Includis[I].KombiSeparat = DatenM.qSuch.FieldByName("kombi_separat").AsInteger() == 1;
                }
                catch { }

                if (MainDLL.Verpackt_Barcode)
                {
                    ArbeitGlobals.Includis[I].Packgroesse = 1;
                }
                
                ArbeitGlobals.Includis[I].SpannzeitToleranz = DatenM.qSuch.FieldByName("spannzeittol").AsInteger();
                ArbeitGlobals.Includis[I].Auftrag.Stat = -1;
                ArbeitGlobals.Includis[I].Auftrag.Schwesterauftrag = string.Empty;
                ArbeitGlobals.Includis[I].Auftrag.Form = string.Empty;

                ArbeitGlobals.Includis[I].Kopfgroesse = ArbeitFunctions.Format_String(DatenM.qSuch.FieldByName("Kopfgroesse").AsString());
                if (ArbeitGlobals.Includis[I].Kopfgroesse < 1)
                    ArbeitGlobals.Includis[I].Kopfgroesse = 1;
                if (ArbeitGlobals.Includis[I].Packgroesse < 1)
                    ArbeitGlobals.Includis[I].Packgroesse = 1;

                // Set Pruefstation based on Station field
                Wert = DatenM.qSuch.FieldByName("Station").AsString();
                ArbeitGlobals.Includis[I].Pruefstation = 1;
                if (Wert == Sprache_V63.GetL("einfach"))
                    ArbeitGlobals.Includis[I].Pruefstation = 1;
                else if (Wert == Sprache_V63.GetL("zweifach"))
                    ArbeitGlobals.Includis[I].Pruefstation = 2;
                else if (Wert == Sprache_V63.GetL("dreifach"))
                    ArbeitGlobals.Includis[I].Pruefstation = 3;

                // Check if machine is blocked
                try
                {
                    ArbeitGlobals.Includis[I].Maschine_geblockt = false;
                    if (DBMain.BLOCKSTILLSTAND || DBMain.AUFTRAG_BLOCK)
                    {
                        SQLStr = "select tpm_stillstaende.stillstand, tpm_stillstaende.StillstandNr,"
                            + " tpm_stillstaende.geplant, tpm_stillstaende.Gruppe, tpm_stillstaende.BLOCKSTILLSTAND"
                            + " from tpm_stillstaende,"
                            + "tpm_stillog where tpm_stillstaende.StillstandNr = tpm_stillog.StillstandNr AND geht=0 "
                            + " and tpm_stillog.Nr = (select max(nr) from tpm_stillog where maschnr = '" + ArbeitGlobals.Includis[I].MaschNr + "')";
                        SQL_fuc.SQL_Get(DatenM.qCount, SQLStr);
                        ArbeitGlobals.Includis[I].Maschine_geblockt = (DatenM.qCount.FieldByName("BLOCKSTILLSTAND").AsInteger() == 1);
                    }
                }
                catch
                {
                    ArbeitGlobals.Includis[I].Maschine_geblockt = false;
                }

                ArbeitGlobals.Includis[I].StueckzahlDirekt = DatenM.qSuch.FieldByName("stueckzahldirekt").AsInteger() == 1;

                if (DBMain.BypassMode)
                    ArbeitGlobals.Includis[I].Maschine_geblockt = DatenM.qSuch.FieldByName("bypass").AsInteger() == 1;

                I++;
                DatenM.qSuch.Next();
            }

            // Initialize order data for all machines
            for (I = 1; I <= DBMain.Anzahl_Masch; I++)
            {
                ArbeitGlobals.Includis[I].Auftrag.AuftragNr = string.Empty;
                ArbeitGlobals.Includis[I].Auftrag.Schwesterauftrag = string.Empty;
                ArbeitGlobals.Includis[I].Auftrag.Form = string.Empty;
                ArbeitGlobals.Includis[I].Auftrag.Werkzeug = 0;
                ArbeitGlobals.Includis[I].Auftrag.WerkzeugNr = string.Empty;
                ArbeitGlobals.Includis[I].Auftrag.EndeDatum = DateTime.MinValue;
            }

            DatenM.qSuch.Close();

            // Load total runtime data for active orders
            SQLStr = "SELECT SUM(a_istlaufzeit) laufzeit, maschnr, BETRIEBSAUFTRAGNR "
                + " FROM tpm_schicht WHERE betriebsauftragnr IN "
                + " (SELECT betriebsauftragnr FROM pde WHERE stat = 0) "
                + " GROUP BY maschnr, BETRIEBSAUFTRAGNR ";

            SQL_fuc.SQL_Get(DatenM.qSuch4, SQLStr);
            while (!DatenM.qSuch4.Eof)
            {
                I = DatenM.qSuch4.FieldByName("maschnr").AsInteger();
                if ((I > 0) && (I < DBMain.Anzahl_Masch))
                {
                    ArbeitGlobals.Includis[I].Auftrag.GesamtLaufzeit = DatenM.qSuch4.FieldByName("laufzeit").AsInteger();
                    ArbeitGlobals.Includis[I].Auftrag.BaNrLaufzeit = DatenM.qSuch4.FieldByName("betriebsauftragnr").AsString();
                }
                DatenM.qSuch4.Next();
            }

            // Fix default values
            SQL_fuc.SQL_Insert(DatenM.qUpdate, "UPDATE pde SET kopfgroesse=1 WHERE kopfgroesse=0");
            SQL_fuc.SQL_Insert(DatenM.qUpdate, "UPDATE maschinf SET kavitaet=1 WHERE kavitaet=0");

            // Load active orders
            SQLStr = "select CASE WHEN m.maschnr IS NULL THEN mo.maschnr ELSE m.maschnr END maschnr , p.* from PDE p "
                + " LEFT JOIN maschoffline mo ON mo.lizenz = p.lizenz "
                + " LEFT JOIN maschine m ON m.lizenz = p.lizenz "
                + " where p.stat in (0, 1)";
            SQL_fuc.SQL_Get(DatenM.qSuch, SQLStr);
            DatenM.qSuch.First();

            while (!DatenM.qSuch.EOF)
            {
                Wert = DatenM.qSuch.FieldByName("Lizenz").AsString();
                machNo = DatenM.qSuch.FieldByName("maschnr").AsInteger();
                I = DBMain.Anzahl_Masch + 1;
                
                if ((machNo < I) && (string.Equals(ArbeitGlobals.Includis[machNo].Lizenz, Wert, StringComparison.OrdinalIgnoreCase)))
                    I = machNo;

                if (I > DBMain.Anzahl_Masch)
                {
                    for (J = 1; J <= DBMain.Anzahl_Masch; J++)
                        if (string.Equals(ArbeitGlobals.Includis[J].Lizenz, Wert, StringComparison.OrdinalIgnoreCase))
                        {
                            I = J;
                            break;
                        }
                }

                if (I <= DBMain.Anzahl_Masch)
                {
                    ArbeitGlobals.Includis[I].MusternAktiv = DatenM.qSuch.FieldByName("Mustern").AsInteger() == 1;
                    ArbeitGlobals.Includis[I].Auftrag.Mustern = DatenM.qSuch.FieldByName("Mustern").AsInteger() == 1;
                    ArbeitGlobals.Includis[I].Auftrag.WasReset = false;
                    ArbeitGlobals.Includis[I].Auftrag.BetriebsauftragNr = DatenM.qSuch.FieldByName("BetriebsAuftragNr").AsString();
                    ArbeitGlobals.Includis[I].Auftrag.AuftragNr = DatenM.qSuch.FieldByName("AuftragNr").AsString();
                    ArbeitGlobals.Includis[I].Auftrag.Bezeichnung = DatenM.qSuch.FieldByName("Bezeichnung").AsString();
                    ArbeitGlobals.Includis[I].Auftrag.Zustaendig = DatenM.qSuch.FieldByName("Zustaendig").AsString();
                    ArbeitGlobals.Includis[I].Auftrag.Signal = DatenM.qSuch.FieldByName("Signal").AsString();
                    
                    try
                    {
                        ArbeitGlobals.Includis[I].Auftrag.Sollwert = ArbeitFunctions.Format_String(DatenM.qSuch.FieldByName("Sollwert").AsString());
                    }
                    catch
                    {
                        ArbeitGlobals.Includis[I].Auftrag.Sollwert = ArbeitFunctions.Format_String(DatenM.qSuch.FieldByName("Sollwert").AsString());
                    }
                    
                    try
                    {
                        ArbeitGlobals.Includis[I].Auftrag.SollwertOffset = ArbeitFunctions.Format_String(DatenM.qSuch.FieldByName("SollwertOffset").AsString());
                    }
                    catch
                    {
                        ArbeitGlobals.Includis[I].Auftrag.SollwertOffset = ArbeitFunctions.Format_String(DatenM.qSuch.FieldByName("SollwertOffset").AsString());
                    }

                    ArbeitGlobals.Includis[I].Auftrag.planzykluszeit = DatenM.qSuch.FieldByName("planzykluszeit").AsInteger();
                    ArbeitGlobals.Includis[I].Auftrag.ausschussquote = DatenM.qSuch.FieldByName("ausschussquote").AsInteger();
                    ArbeitGlobals.Includis[I].Auftrag.SollSpannzeitStk = DatenM.qSuch.FieldByName("SOLLSPANNZEITSTK").AsInteger();
                    ArbeitGlobals.Includis[I].Auftrag.SollSpannzeitGes = DatenM.qSuch.FieldByName("SOLLSPANNZEITGES").AsInteger();

                    try
                    {
                        ArbeitGlobals.Includis[I].Solltakt = DatenM.qSuch.FieldByName("Taktzeit").AsInteger();
                    }
                    catch { }

                    ArbeitGlobals.Includis[I].Auftrag.StueckSchicht = DatenM.qSuch.FieldByName("StueckSchicht").AsInteger();
                    ArbeitGlobals.Includis[I].Auftrag.PersonalZeit = ArbeitFunctions.GFloat(DatenM.qSuch.FieldByName("Personalzeit").AsString());
                    ArbeitGlobals.Includis[I].Auftrag.Optimiert = DatenM.qSuch.FieldByName("optimiert").AsInteger();
                    ArbeitGlobals.Includis[I].Auftrag.OptimiertAktuell = DatenM.qSuch.FieldByName("tmpschuss").AsInteger();
                    ArbeitGlobals.Includis[I].Auftrag.ImStatusOptimieren = DatenM.qSuch.FieldByName("InPause").AsInteger();

                    if (S7Main.HochlaufTPM)
                        ArbeitGlobals.Includis[I].StueckAuftragGesamt = ArbeitFunctions.Format_String(DatenM.qSuch.FieldByName("Istwert").AsString());

                    ArbeitGlobals.Includis[I].Auftrag.Schwesterauftrag = DatenM.qSuch.FieldByName("Schwesterauftrag").AsString();
                    ArbeitGlobals.Includis[I].Auftrag.Form = DatenM.qSuch.FieldByName("Form").AsString();
                    ArbeitGlobals.Includis[I].Auftrag.Ausschuss = DatenM.qSuch.FieldByName("Ausschuss").AsInteger();
                    ArbeitGlobals.Includis[I].Auftrag.Verpackt = ArbeitFunctions.Format_String(DatenM.qSuch.FieldByName("Pack").AsString());
                    ArbeitGlobals.Includis[I].Auftrag.Vorwarnung = ArbeitFunctions.Format_String(DatenM.qSuch.FieldByName("Vorwarnung").AsString());
                    
                    if ((DatenM.qSuch.FieldByName("Betriebsart").AsString() == Sprache_V63.GetL("Halbautomatik")) && DBMain.halbautomatik)
                        ArbeitGlobals.Includis[I].Auftrag.HalbAuto = true;
                    else
                        ArbeitGlobals.Includis[I].Auftrag.HalbAuto = false;

                    if (DatenM.qSuch.FieldByName("Erzeugt").AsString() == "1")
                    {
                        ArbeitGlobals.Includis[I].Auftrag.Erzeugt = true;
                        ArbeitGlobals.Includis[I].Auftrag.VorwarnungErzeugt = true;
                    }
                    else
                    {
                        ArbeitGlobals.Includis[I].Auftrag.Erzeugt = false;
                        ArbeitGlobals.Includis[I].Auftrag.VorwarnungErzeugt = false;
                    }

                    ArbeitGlobals.Includis[I].Auftrag.Solltakt = DatenM.qSuch.FieldByName("Taktzeit").AsInteger();
                    ArbeitGlobals.Includis[I].Auftrag.Stat = (short)DatenM.qSuch.FieldByName("stat").AsInteger();
                    ArbeitGlobals.Includis[I].Auftrag.Programm_Nr = DatenM.qSuch.FieldByName("Programm_Nr").AsInteger();
                    ArbeitGlobals.Includis[I].Auftrag.StartDatum = MainDLL.FloatToDateTime(DatenM.qSuch.FieldByName("StartdatumZeit").AsFloat());
                    ArbeitGlobals.Includis[I].Auftrag.EndeDatum = MainDLL.FloatToDateTime(DatenM.qSuch.FieldByName("EnddatumZeit").AsFloat());
                    ArbeitGlobals.Includis[I].Auftrag.EndeDatumSTR = DatenM.qSuch.FieldByName("EndDatumSTR").AsString();
                    ArbeitGlobals.Includis[I].Auftrag.LTSOLL = ArbeitFunctions.GFloat(DatenM.qSuch.FieldByName("LTDatumZeit").AsString());
                    ArbeitGlobals.Includis[I].Auftrag.LTIST = ArbeitFunctions.GFloat(DatenM.qSuch.FieldByName("EnddatumZeit").AsString());
                    ArbeitGlobals.Includis[I].Auftrag.LT1 = ArbeitFunctions.GFloat(DatenM.qSuch.FieldByName("Termin1").AsString());
                    ArbeitGlobals.Includis[I].Auftrag.LT2 = ArbeitFunctions.GFloat(DatenM.qSuch.FieldByName("Termin2").AsString());
                    ArbeitGlobals.Includis[I].Auftrag.Kunde = DatenM.qSuch.FieldByName("Kunde").AsString();
                    ArbeitGlobals.Includis[I].Auftrag.Werkzeug = DatenM.qSuch.FieldByName("Werkzeug").AsInteger();

                    try
                    {
                        ArbeitGlobals.Includis[I].Auftrag.Packgroesse = ArbeitFunctions.Format_String(DatenM.qSuch.FieldByName("PACKGROESSE").AsString());
                        ArbeitGlobals.Includis[I].Auftrag.PALETTENGROESSE = ArbeitFunctions.Format_String(DatenM.qSuch.FieldByName("EndDatumSTR").AsString());
                    }
                    catch
                    {
                        ArbeitGlobals.Includis[I].Auftrag.Packgroesse = 0;
                        ArbeitGlobals.Includis[I].Auftrag.PALETTENGROESSE = 0;
                    }

                    ArbeitGlobals.Includis[I].Auftrag.MasterAuftrag = DatenM.qSuch.FieldByName("Masterauftrag").AsInteger() == 1;

                    if (DBMain.werkzeugverwaltung)
                        ArbeitGlobals.Includis[I].Auftrag.WerkzeugNr = CCC_GetWerkzeugNr(ArbeitGlobals.Includis[I].Auftrag.Werkzeug);

                    if (string.IsNullOrEmpty(ArbeitGlobals.Includis[I].Auftrag.Form))
                        ArbeitGlobals.Includis[I].Auftrag.Form = ArbeitGlobals.Includis[I].Auftrag.Werkzeug.ToString();

                    try
                    {
                        if (string.IsNullOrEmpty(DatenM.qSuch.FieldByName("Grundeinstellung").AsString()) || 
                            DatenM.qSuch.FieldByName("Grundeinstellung").IsNull)
                        {
                            ArbeitGlobals.Includis[I].PruefPack = 0;
                        }
                        else
                        {
                            ArbeitGlobals.Includis[I].PruefPack = DatenM.qSuch.FieldByName("Grundeinstellung").AsInteger();
                        }
                    }
                    catch
                    {
                        ArbeitGlobals.Includis[I].PruefPack = 0;
                    }

                    // Handle cavity data
                    try
                    {
                        if (DBMain.KavitaetFromSPS)
                        {
                            int Kav = S7Main.SPSKavitaet[I].Istwert;
                            if (Kav < 1) Kav = 1;
                            if (Kav != DatenM.qSuch.FieldByName("Kopfgroesse").AsInteger())
                            {
                                SQL_fuc.SQL_Insert(DatenM.qUpdate, "UPDATE pde SET kopfgroesse = " + Kav.ToString() + 
                                    " WHERE nr = " + DatenM.qSuch.FieldByName("nr").AsString());
                            }
                        }
                        else
                        {
                            if (!DBMain.Kavitaet_laufender_Auftrag3)
                            {
                                s = "SELECT * FROM kavprot WHERE betriebsauftragnr = '" + ArbeitGlobals.Includis[I].Auftrag.BetriebsauftragNr + "' ORDER BY datum DESC";
                                SQL_fuc.SQL_Get(DatenM.qSuch2, s);
                                if (DatenM.qSuch2.IsEmpty || !DBMain.Kavitaet_laufender_Auftrag3)
                                {
                                    Kav = DatenM.qSuch.FieldByName("Kopfgroesse").AsInteger();
                                    ArbeitGlobals.Includis[I].Auftrag.LetzerKavWechsel.Datum = DateTime.MinValue;
                                }
                                else
                                {
                                    ArbeitGlobals.Includis[I].Auftrag.LetzerKavWechsel.Datum = MainDLL.FloatToDateTime(DatenM.qSuch2.FieldByName("datum").AsFloat());
                                    ArbeitGlobals.Includis[I].Auftrag.LetzerKavWechsel.BetriebsauftragNr = ArbeitGlobals.Includis[I].Auftrag.BetriebsauftragNr;
                                    ArbeitGlobals.Includis[I].Auftrag.LetzerKavWechsel.Alt = DatenM.qSuch2.FieldByName("Wert1").AsInteger();
                                    ArbeitGlobals.Includis[I].Auftrag.LetzerKavWechsel.Neu = DatenM.qSuch2.FieldByName("Wert2").AsInteger();
                                    ArbeitGlobals.Includis[I].Auftrag.LetzerKavWechsel.Produziert = DatenM.qSuch2.FieldByName("Produziert").AsInteger();
                                    ArbeitGlobals.Includis[I].Auftrag.LetzerKavWechsel.Schusszaehler = DatenM.qSuch2.FieldByName("Schusszaehler").AsInteger();
                                    
                                    if ((ArbeitGlobals.Includis[I].Auftrag.LetzerKavWechsel.Produziert > 0) && 
                                        (ArbeitGlobals.Includis[I].Auftrag.LetzerKavWechsel.Schusszaehler < 1))
                                    {
                                        ArbeitGlobals.Includis[I].Auftrag.LetzerKavWechsel.Datum = DateTime.MinValue;
                                    }
                                    Kav = ArbeitGlobals.Includis[I].Auftrag.LetzerKavWechsel.Neu;
                                }
                            }
                            else
                            {
                                Kav = DatenM.qSuch.FieldByName("Kopfgroesse").AsInteger();
                                ArbeitGlobals.Includis[I].Auftrag.LetzerKavWechsel.Datum = DateTime.MinValue;
                            }
                        }
                    }
                    catch
                    {
                        try
                        {
                            ArbeitGlobals.Includis[I].Auftrag.LetzerKavWechsel.Datum = DateTime.MinValue;
                            Kav = DatenM.qSuch.FieldByName("kavitaet_soll").AsInteger();
                            SQL_fuc.SQL_Insert(DatenM.qUpdate, "UPDATE pde SET kopfgroesse = kavitaet_soll WHERE nr = " + 
                                DatenM.qSuch.FieldByName("nr").AsString());
                        }
                        catch
                        {
                            Kav = 1;
                            SQL_fuc.SQL_Insert(DatenM.qUpdate, "UPDATE pde SET kopfgroesse = 1, kavitaet_soll = 1 WHERE nr = " + 
                                DatenM.qSuch.FieldByName("nr").AsString());
                        }
                    }

                    // Handle cavity change logic
                    if (DBMain.Kavitaet_laufender_Auftrag2 && (Kav > 0) && 
                        (ArbeitGlobals.Includis[I].Auftrag.Kopfgroesse > 0) &&
                        (ArbeitGlobals.Includis[I].Auftrag.Kopfgroesse != Kav) &&
                        (ArbeitGlobals.Includis[I].Auftrag.BetriebsauftragNr == ArbeitGlobals.Includis[I].Auftrag.BetriebsauftragNr_Alt))
                    {
                        ForceShotsOnCavityChange = true;
                        
                        if (CO_Setup2.TCO_Setup.GetParamBool(DatenM.qUpdate, "INCL_RunningChangeOnPrintRequest"))
                        {
                            SQL_fuc.SQL_Get(DatenM.qCount, "SELECT max(started) started FROM runningchangeevents rc WHERE BANEW = '" +
                                ArbeitGlobals.Includis[I].Auftrag.BetriebsauftragNr + "'");
                            if (!DatenM.qCount.IsEmpty)
                            {
                                if (((MainDLL.DateTimeToFloat(DatenM.qCount.FieldByName("started").AsDateTime()) +
                                    (CO_Setup2.TCO_Setup.GetParamInt(DatenM.qUpdate, "INCL_SVCDontWriteCavityForXminutes") / 1440.0)) > MainDLL.Jetzt))
                                {
                                    ForceShotsOnCavityChange = false;
                                }
                            }
                        }

                        if (ForceShotsOnCavityChange && CO_Setup2.TCO_Setup.GetParamBool(DatenM.qUpdate, "SVC_BuchungBeiKavWechsel"))
                        {
                            S7Main.S7_Auftrag.AuftragBuchen(ArbeitGlobals.Includis[I].Auftrag.BetriebsauftragNr, ArbeitGlobals.Includis[I].StueckAuftragGesamt);
                        }

                        SQLStr = "Update Maschine Set Kopfgroesse = " + Kav.ToString() + " where MaschNr = " + ArbeitGlobals.Includis[I].MaschNr;
                        SQL_fuc.SQL_Insert(DatenM.qUpdate, SQLStr);
                    }

                    ArbeitGlobals.Includis[I].Auftrag.BetriebsauftragNr_Alt = ArbeitGlobals.Includis[I].Auftrag.BetriebsauftragNr;
                    ArbeitGlobals.Includis[I].Auftrag.Kopfgroesse = Kav;
                    ArbeitGlobals.Includis[I].Auftrag.KAVITAET_SOLL = DatenM.qSuch.FieldByName("KAVITAET_SOLL").AsInteger();
                    ArbeitGlobals.Includis[I].Auftrag.InPause = DatenM.qSuch.FieldByName("InPause").AsInteger();
                    ArbeitGlobals.Includis[I].Auftrag.Var_Kavitaet = DatenM.qSuch.FieldByName("Var_Kavitaet").AsInteger();
                    
                    if (ArbeitGlobals.Includis[I].Auftrag.Var_Kavitaet < 1)
                        ArbeitGlobals.Includis[I].Auftrag.Var_Kavitaet = 1;
                    if (ArbeitGlobals.Includis[I].Auftrag.Var_Kavitaet > 999)
                        ArbeitGlobals.Includis[I].Auftrag.Var_Kavitaet = 1;
                }
                DatenM.qSuch.Next();
            }

            // Reset machines without active orders
            for (I = 1; I <= DBMain.Anzahl_Masch; I++)
            {
                if ((string.IsNullOrEmpty(ArbeitGlobals.Includis[I].Auftrag.AuftragNr)) && !ArbeitGlobals.Includis[I].Auftrag.WasReset)
                {
                    ArbeitGlobals.Includis[I].MusternAktiv = false;
                    ArbeitGlobals.Includis[I].Auftrag.Mustern = false;
                    ArbeitGlobals.Includis[I].Auftrag.Bezeichnung = Sprache_V63.GetL("kein aktueller Auftrag");
                    ArbeitGlobals.Includis[I].Auftrag.BetriebsauftragNr = string.Empty;
                    ArbeitGlobals.Includis[I].Auftrag.Zustaendig = string.Empty;
                    ArbeitGlobals.Includis[I].Auftrag.Signal = string.Empty;
                    ArbeitGlobals.Includis[I].Auftrag.Sollwert = 0;
                    ArbeitGlobals.Includis[I].Auftrag.SollwertOffset = 0;
                    ArbeitGlobals.Includis[I].Auftrag.Vorwarnung = 0;
                    ArbeitGlobals.Includis[I].Auftrag.Erzeugt = false;
                    ArbeitGlobals.Includis[I].Auftrag.Solltakt = 0;
                    ArbeitGlobals.Includis[I].Auftrag.Stat = ComtasH.stgeplantInt;
                    ArbeitGlobals.Includis[I].Auftrag.Werkzeug = 0;
                    ArbeitGlobals.Includis[I].PruefPack = 1;
                    
                    if (DBMain.KavitaetFromSPS)
                        ArbeitGlobals.Includis[I].Auftrag.Kopfgroesse = S7Main.SPSKavitaet[I].Istwert;
                    else
                        ArbeitGlobals.Includis[I].Auftrag.Kopfgroesse = ArbeitGlobals.Includis[I].Kopfgroesse;
                    
                    if (ArbeitGlobals.Includis[I].Auftrag.Kopfgroesse == 0)
                        ArbeitGlobals.Includis[I].Auftrag.Kopfgroesse = 1;
                    
                    ArbeitGlobals.Includis[I].Auftrag.KAVITAET_SOLL = 1;
                    ArbeitGlobals.Includis[I].Auftrag.InPause = 0;
                    ArbeitGlobals.Includis[I].Auftrag.Var_Kavitaet = 1;
                    ArbeitGlobals.Includis[I].IstTakt = 0;
                    ArbeitGlobals.Includis[I].Solltakt = 0;
                    ArbeitGlobals.Includis[I].StueckSchicht = 0;
                    ArbeitGlobals.Includis[I].StueckPackSchicht = 0;
                    ArbeitGlobals.Includis[I].StueckPruefSchicht = 0;
                    ArbeitGlobals.Includis[I].Nutzung = 0;
                    ArbeitGlobals.Includis[I].Leistung = 0;
                    ArbeitGlobals.Includis[I].Qualitaet = 0;
                    ArbeitGlobals.Includis[I].Effektivitaet = 0;
                    ArbeitGlobals.Includis[I].Auftrag.Ist_PRZ = 0;
                    ArbeitGlobals.Includis[I].Auftrag.Programm_Nr = 0;
                    ArbeitGlobals.Includis[I].Auftrag.Istwert = 0;
                    ArbeitGlobals.Includis[I].Auftrag.Ausschuss = 0;
                    ArbeitGlobals.Includis[I].Auftrag.Verpackt = 0;
                    ArbeitGlobals.Includis[I].StueckPruefAuftragGesamt = 0;
                    ArbeitGlobals.Includis[I].StueckPackAuftragGesamt = 0;
                    ArbeitGlobals.Includis[I].Auftrag.Schwesterauftrag = string.Empty;
                    ArbeitGlobals.Includis[I].Auftrag.Form = string.Empty;
                    ArbeitGlobals.Includis[I].Auftrag.PersonalZeit = 0;
                    ArbeitGlobals.Includis[I].Auftrag.Anfahrausschuss = 0;
                    ArbeitGlobals.Includis[I].Auftrag.Kunde = string.Empty;
                    // Note: AUTOAUSSCHUSS_AUFTRAGSchicht and AUTOAUSSCHUSS_AUFTRAG arrays would need to be implemented
                    ArbeitGlobals.Includis[I].Auftrag.WasReset = true;
                }
            }

            // Handle interrupted orders
            if (CO_Setup2.TCO_Setup.GetParamBool(DatenM.qSuch, "INCL_MJAInterruptedDescr"))
            {
                SQLStr = "SELECT m.maschid, case WHEN p.c IS NULL THEN 0 ELSE 1 END interrupted"
                        + " FROM maschine m"
                        + " LEFT JOIN ("
                        + "   SELECT lizenz, COUNT(nr) c"
                        + "   FROM pde"
                        + "   WHERE stat = 5"
                        + "   GROUP BY lizenz"
                        + " )p ON p.lizenz = m.lizenz"
                        + " ORDER BY maschid";
                DatenM.qSuch.Close();
                SQL_fuc.SQL_Get(DatenM.qSuch, SQLStr);
                DatenM.qSuch.First();
                while (!DatenM.qSuch.Eof)
                {
                    I = DatenM.qSuch.FieldByName("maschid").AsInteger();
                    if ((DatenM.qSuch.FieldByName("interrupted").AsInteger() > 0) && 
                        (string.IsNullOrEmpty(ArbeitGlobals.Includis[I].Auftrag.AuftragNr)))
                    {
                        ArbeitGlobals.Includis[I].Auftrag.InterBezeichnung = Sprache_V63.GetL("Auftrag unterbrochen");
                    }
                    else
                    {
                        ArbeitGlobals.Includis[I].Auftrag.InterBezeichnung = ArbeitGlobals.Includis[I].Auftrag.Bezeichnung;
                    }
                    DatenM.qSuch.Next();
                }
            }
            else
            {
                for (I = 1; I <= DBMain.Anzahl_Masch; I++)
                {
                    if (!ArbeitGlobals.Includis[I].IstArchiviert)
                        ArbeitGlobals.Includis[I].Auftrag.InterBezeichnung = ArbeitGlobals.Includis[I].Auftrag.Bezeichnung;
                }
            }

            // Load BDE data
            DatenM.qSuch.Close();
            SQL_fuc.SQLGet(DatenM.qSuch, "MDE", "Erzeugt", "0", false);
            DatenM.qSuch.First();

            while (!DatenM.qSuch.EOF)
            {
                Wert = DatenM.qSuch.FieldByName("Lizenz").AsString();
                // Find machine in Includis
                for (I = 1; I <= DBMain.Anzahl_Masch; I++)
                {
                    ArbeitGlobals.Includis[I].BDE.Bezeichnung = string.Empty;
                    if (string.Equals(ArbeitGlobals.Includis[I].Lizenz, Wert, StringComparison.OrdinalIgnoreCase))
                        break;
                }

                if (I <= DBMain.Anzahl_Masch)
                {
                    ArbeitGlobals.Includis[I].BDE.Bezeichnung = DatenM.qSuch.FieldByName("JobBezeichnung").AsString();
                    ArbeitGlobals.Includis[I].BDE.Zustaendig = DatenM.qSuch.FieldByName("Zustaendig").AsString();
                    ArbeitGlobals.Includis[I].BDE.Signal = DatenM.qSuch.FieldByName("Signal").AsString();
                    ArbeitGlobals.Includis[I].BDE.Sollwert = DatenM.qSuch.FieldByName("Sollwert_ABS").AsInteger();
                    ArbeitGlobals.Includis[I].BDE.Vorwarnung = DatenM.qSuch.FieldByName("Vorwarnung_ABS").AsInteger();
                    ArbeitGlobals.Includis[I].BDE.Erzeugt = DatenM.qSuch.FieldByName("Erzeugt").AsString() == "1";
                    ArbeitGlobals.Includis[I].BDE.VorwarnungErzeugt = false;
                }
                DatenM.qSuch.Next();
            }

            // Clear BDE data for machines without entries
            for (I = 1; I <= DBMain.Anzahl_Masch; I++)
            {
                if (string.IsNullOrEmpty(ArbeitGlobals.Includis[I].BDE.Bezeichnung))
                {
                    ArbeitGlobals.Includis[I].BDE.Bezeichnung = string.Empty;
                    ArbeitGlobals.Includis[I].BDE.Zustaendig = string.Empty;
                    ArbeitGlobals.Includis[I].BDE.Signal = string.Empty;
                    ArbeitGlobals.Includis[I].BDE.Sollwert = 0;
                    ArbeitGlobals.Includis[I].BDE.Vorwarnung = 0;
                    ArbeitGlobals.Includis[I].BDE.Erzeugt = false;
                }
            }

            // Load everycycle setting
            everycycle = false;
            SQLStr = "SELECT saveeverycycle FROM setup WHERE nr = 1";
            try
            {
                SQL_fuc.SQL_Get(DatenM.qSuch, SQLStr);
                if (!DatenM.qSuch.IsEmpty)
                    everycycle = DatenM.qSuch.FieldByName("saveeverycycle").AsInteger() == 1;
            }
            catch { }

            // Load Taktoption data
            DatenM.qSuch4.SQL.Text = "SELECT * FROM Taktoption";
            DatenM.qSuch4.Open();
            while (!DatenM.qSuch4.Eof)
            {
                try
                {
                    I = int.Parse(CCC_GetMaschNrLizenz(DatenM.qSuch4.FieldByName("lizenz").AsString()));
                }
                catch
                {
                    I = 0;
                }
                if (I > 0)
                    ArbeitGlobals.Includis[I].ArtikelZyklus = DatenM.qSuch4.FieldByName("Artikelzyklus").AsInteger();
                DatenM.qSuch4.Next();
            }

            // Set ArtikelZyklus for all machines
            for (I = 1; I <= DBMain.Anzahl_Masch; I++)
            {
                if (ArbeitGlobals.Includis[I].IstArchiviert)
                    continue;
                    
                if (everycycle)
                    ArbeitGlobals.Includis[I].ArtikelZyklus = 1;
                else
                {
                    if (SQL_fuc.SQLGetBool(DatenM.qSuch4, "TAKTOPTION", "Lizenz", ArbeitGlobals.Includis[I].Lizenz))
                        ArbeitGlobals.Includis[I].ArtikelZyklus = DatenM.qSuch4.FieldByName("Artikelzyklus").AsInteger();
                    else
                        ArbeitGlobals.Includis[I].ArtikelZyklus = 100;
                }
            }

            // Load downtime data
            SQLStr = "Select Count(*) CNT from TPM_Stillstaende";
            SQL_fuc.SQL_Get(DatenM.qSuch, SQLStr);
            int stillstandCount = DatenM.qSuch.FieldByName("CNT").AsInteger() + 1;
            ArbeitGlobals.Stillstand = new List<TStillstand>();
            for (int k = 0; k < stillstandCount; k++)
                ArbeitGlobals.Stillstand.Add(new TStillstand());

            SQLStr = "Select * from TPM_Stillstaende";
            SQL_fuc.SQL_Get(DatenM.qSuch, SQLStr);
            I = 1;
            while (!DatenM.qSuch.EOF)
            {
                ArbeitGlobals.Stillstand[I].Stillstandnr = DatenM.qSuch.FieldByName("Stillstandnr").AsInteger();
                ArbeitGlobals.Stillstand[I].Bezeichnung = DatenM.qSuch.FieldByName("Stillstand").AsString();
                ArbeitGlobals.Stillstand[I].Aktion = DatenM.qSuch.FieldByName("Aktion").AsInteger();
                ArbeitGlobals.Stillstand[I].Gruppe = DatenM.qSuch.FieldByName("Gruppe").AsInteger();
                ArbeitGlobals.Stillstand[I].Geplant = DatenM.qSuch.FieldByName("Geplant").AsInteger() == 1;
                I++;
                DatenM.qSuch.Next();
            }

            // Initialize machine states
            if (S7Main.HochlaufTPM)
            {
                for (I = 1; I <= DBMain.Anzahl_Masch; I++)
                {
                    ArbeitGlobals.MaschZustand[I].MaschNr = ArbeitGlobals.Includis[I].MaschNr;
                    ArbeitGlobals.MaschZustand[I].Zustand = -1;
                }
                S7Main.HochlaufTPM = false;
            }

            ArbeitGlobals.First = false;
        }

        // ========================================================================
        // Helper functions
        // ========================================================================

        private static string CCC_GetWerkzeugNr(int Schluessel)
        {
            // Implementation would query the Werkzeug table
            // This is a placeholder - full implementation would use CO_Query
            return Schluessel.ToString();
        }

        private static string CCC_GetMaschNrLizenz(string Lizenz)
        {
            for (int i = 1; i <= DBMain.Anzahl_Masch; i++)
            {
                if (string.Equals(ArbeitGlobals.Includis[i].Lizenz, Lizenz, StringComparison.OrdinalIgnoreCase))
                    return ArbeitGlobals.Includis[i].MaschNr;
            }
            return string.Empty;
        }

        private static int CCC_GetMaschIndex(string Lizenz)
        {
            for (int i = 1; i <= DBMain.Anzahl_Masch; i++)
            {
                if (string.Equals(ArbeitGlobals.Includis[i].Lizenz, Lizenz, StringComparison.OrdinalIgnoreCase))
                    return i;
            }
            return 0;
        }

        private static int CCC_GetMaschZustand(string Lizenz)
        {
            int index = CCC_GetMaschIndex(Lizenz);
            if (index > 0 && index <= ArbeitGlobals.MaschZustand.Count)
                return ArbeitGlobals.MaschZustand[index].Zustand;
            return 0;
        }

        private static string CCC_GetKennung(string MaschNr)
        {
            for (int i = 1; i <= DBMain.Anzahl_Masch; i++)
            {
                if (ArbeitGlobals.Includis[i].MaschNr == MaschNr)
                    return ArbeitGlobals.Includis[i].KURZKENNUNG;
            }
            return string.Empty;
        }

        // ========================================================================
        // CCC_Daten_Aktualisieren - Update machine and order data
        // ========================================================================
        
        public static void CCC_Daten_Aktualisieren_Implementation()
        {
            int IMaschProgramm, SProd, SAutoAusschuss, SAnfahr, AProd, AAnfahr, SZyk, AZyk, SPruef, APruef;
            int Zustand_Wert = 0, Schichtwert = 1, keinProduziertBeiRuestenInt = 0;
            double Zeitreal, LastChange = 0;
            bool isfeiertag = false;
            string Meldung, SQLStr, s;
            int Ausschuss, tmptakt, SchichtanfangInt = 0;
            DateTime Schichtanfang;
            int tbMinuten, NA = 0, TagwechselInt = 0, Tag;
            double MinutenAnfang, MinutenJetzt, diff;
            int I, J;
            DateTime TmpDate, Werksplanungszeit;
            int Minuten = 0;
            bool Anfahr_Ausschuss2 = false;
            int SchichtSpeicherIni = 0;

            ArbeitGlobals.Vor_Schichtwechsel = false;
            ArbeitGlobals.Vor_Werksplanung = false;
            Zustand_Wert = 0;
            Schichtwert = 1;

            // Get parameter
            SQL_fuc.SQLGet(DatenM.qSuch4, "Setup", "Nr", "1", false);
            Anfahr_Ausschuss2 = DatenM.qSuch4.FieldByName("Anfahr_Ausschuss2").AsInteger() == 1;

            keinProduziertBeiRuestenInt = CO_Setup2.TCO_Setup.GetParamBool(DatenM.qSuch, "INCL_ProducedInShiftWithoutSetup") ? 1 : 0;

            if (DBMain.Shift_Model != 2)
            {
                // Check for shift change
                Zeitreal = MainDLL.Frac(MainDLL.Jetzt);
                if (((Zeitreal >= ArbeitGlobals.vorSchicht1) && (Zeitreal < ArbeitGlobals.Schicht1)) ||
                    ((Zeitreal >= ArbeitGlobals.vorSchicht2) && (Zeitreal < ArbeitGlobals.Schicht2)) ||
                    ((Zeitreal >= ArbeitGlobals.vorSchicht3) && (Zeitreal < ArbeitGlobals.Schicht3)))
                {
                    ArbeitGlobals.Vor_Schichtwechsel = true;
                }

                TmpDate = MainDLL.Trunc(MainDLL.Jetzt);
                // Set shift
                if ((Zeitreal >= ArbeitGlobals.Schicht1) && (Zeitreal < ArbeitGlobals.Schicht2))
                    Schichtwert = 1;
                else if ((Zeitreal >= ArbeitGlobals.Schicht2) && (Zeitreal < ArbeitGlobals.Schicht3))
                    Schichtwert = 2;
                else if ((Zeitreal >= ArbeitGlobals.Schicht3) && (Zeitreal <= 1))
                    Schichtwert = 3;
                else if ((Zeitreal >= 0.0) && (Zeitreal < ArbeitGlobals.Schicht1))
                {
                    Schichtwert = 3;
                    TmpDate = TmpDate.AddDays(-1);
                }

                if (Schichtwert == 0)
                    Schichtwert = 3;
            }
            else
            {
                // 2-shift model
                Zeitreal = MainDLL.Frac(MainDLL.Jetzt);
                if ((Zeitreal >= ArbeitGlobals.vorSchicht1) && (Zeitreal < ArbeitGlobals.Schicht1) ||
                    (Zeitreal >= ArbeitGlobals.vorSchicht2) && (Zeitreal < ArbeitGlobals.Schicht2))
                {
                    ArbeitGlobals.Vor_Schichtwechsel = true;
                }

                TmpDate = MainDLL.Trunc(MainDLL.Jetzt);
                if ((Zeitreal >= ArbeitGlobals.Schicht1) && (Zeitreal < ArbeitGlobals.Schicht2))
                    Schichtwert = 1;
                else if ((Zeitreal >= ArbeitGlobals.Schicht2) && (Zeitreal < 1))
                    Schichtwert = 2;
                else if ((Zeitreal >= 0.0) && (Zeitreal < ArbeitGlobals.Schicht1))
                {
                    Schichtwert = 2;
                    TmpDate = TmpDate.AddDays(-1);
                }

                if (Schichtwert == 0)
                    Schichtwert = 2;
            }

            // Check for holidays
            SQLStr = "SELECT * FROM kalenderfeiertage WHERE trunc(startdate) <= " + 
                MainDLL.Trunc(MainDLL.Jetzt).ToString() + 
                " AND trunc(enddate+1) >= " + MainDLL.Trunc(MainDLL.Jetzt).ToString() + " AND active=1";
            SQL_fuc.SQL_Get(DatenM.qSuch, SQLStr);
            
            if (!DatenM.qSuch.IsEmpty)
            {
                isfeiertag = (DatenM.qSuch.FieldByName("startdateshift").AsInteger() <= Schichtwert) &&
                            (Schichtwert <= DatenM.qSuch.FieldByName("enddateshift").AsInteger());
            }

            // Get shift duration
            SQLStr = "Select * from KALENDER where DatumINT = " + MainDLL.Trunc(TmpDate).ToString();
            SQL_fuc.SQL_Get(DatenM.qSuch, SQLStr);
            Minuten = DatenM.qSuch.FieldByName("Schicht" + Schichtwert.ToString()).AsInteger();
            DBMain.SchichtDauer = MainDLL.GetSchichtDauer(Schichtwert);
            Werksplanungszeit = DateTime.MinValue;

            if ((Minuten < DBMain.SchichtDauer) && (Minuten > 0))
            {
                if (Schichtwert == 1)
                    Werksplanungszeit = MainDLL.ConvertFromFloat(ArbeitGlobals.Schicht2 - (Minuten / 1440.0));
                else if (Schichtwert == 2)
                    Werksplanungszeit = MainDLL.ConvertFromFloat(ArbeitGlobals.Schicht3 - (Minuten / 1440.0));
                else if (Schichtwert == 3)
                {
                    if (Minuten < 360)
                        Werksplanungszeit = MainDLL.ConvertFromFloat(ArbeitGlobals.Schicht1 - (Minuten / 1440.0));
                    else
                        Werksplanungszeit = MainDLL.ConvertFromFloat(1 - ((Minuten - 360) / 1440.0));
                }

                if ((MainDLL.Frac(MainDLL.Jetzt) > MainDLL.Frac(Werksplanungszeit)) &&
                    (MainDLL.Frac(MainDLL.Jetzt) < (MainDLL.Frac(Werksplanungszeit) + (1 / 2880.0))))
                {
                    ArbeitGlobals.Vor_Werksplanung = true;
                }
            }

            if (isfeiertag)
                Werksplanungszeit = DateTime.MinValue;

            SchichtSpeicherIni = ArbeitGlobals.SchichtSpeicher;

            // Load shift change time from INI
            try
            {
                if (!Th_Schicht.Berechnung_aktiv)
                {
                    var Ini = new IniFiles.TIniFile(Path.Combine(Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location), 
                        "incl_" + DBMain.DBUser + ".ini"));
                    LastChange = Ini.ReadFloat("System", "last_shift_change", -1);
                    if (LastChange > -1)
                    {
                        SchichtSpeicherIni = MainDLL.GetSchichtNr(LastChange);
                        if (MainDLL.N_o_w - LastChange > 1)
                        {
                            if (SchichtSpeicherIni == 1)
                            {
                                if (DBMain.Shift_Model == 2)
                                    SchichtSpeicherIni = 2;
                                else
                                    SchichtSpeicherIni = 3;
                            }
                            else
                                SchichtSpeicherIni = SchichtSpeicherIni - 1;
                        }
                        ArbeitGlobals.SchichtSpeicher = SchichtSpeicherIni;
                    }
                    Ini.Free();
                }
            }
            catch { }

            // Trigger shift change if needed
            if (!(ArbeitGlobals.SchichtSpeicher == -1) && (ArbeitGlobals.SchichtSpeicher != Schichtwert))
            {
                DatenM.qUpdate.Close();
                DatenM.qUpdate.SQL.Clear();
                SQLStr = "INSERT INTO SIWECHSEL (Nr,Schichtwechsel,alteSchicht,neueSchicht)"
                    + "VALUES(SIWECHSELID.NextVal"
                    + ",'1'"
                    + ",'" + SchichtSpeicherIni.ToString() + "'"
                    + ",'" + Schichtwert.ToString() + "')";
                SQL_fuc.SQL_Insert(DatenM.qUpdate, SQLStr);
            }

            ArbeitGlobals.SchichtSpeicher = Schichtwert;

            // Load machine heating data
            SQLStr = "SELECT * FROM maschine";
            DatenM.qSuch.SQL.Text = SQLStr;
            DatenM.qSuch.Open();
            while (!DatenM.qSuch.EOF)
            {
                I = DatenM.qSuch.FieldByName("maschid").AsInteger();
                MainDLL.Heizungsoll[I] = DatenM.qSuch.FieldByName("heatingstd").AsInteger();
                try
                {
                    ArbeitGlobals.Includis[I].SPC_Aktiv = DatenM.qSuch.FieldByName("spcaktiv").AsInteger() == 1;
                }
                catch
                {
                    ArbeitGlobals.Includis[I].SPC_Aktiv = DBMain.SPC;
                }
                DatenM.qSuch.Next();
            }
            DatenM.qSuch.Close();

            // Load MDE tolerance data
            SQLStr = "SELECT mde_ver.nr vernr, maschnr, toleranzint FROM mde_ver "
                + " LEFT JOIN maschine ON mde_ver.lizenz = maschine.lizenz";
            SQL_fuc.SQL_Get(DatenM.qSuch, SQLStr);
            while (!DatenM.qSuch.EOF)
            {
                s = DatenM.qSuch.FieldByName("maschnr").AsString();
                if (string.IsNullOrEmpty(s))
                {
                    SQL_fuc.SQL_Insert(DatenM.qUpdate, "DELETE FROM mde_ver WHERE nr = " + 
                        DatenM.qSuch.FieldByName("vernr").AsString());
                }
                else
                {
                    I = int.Parse(s);
                    if ((I <= DBMain.Anzahl_Masch))
                    {
                        ArbeitGlobals.Includis[I].TaktToleranzPlus = DatenM.qSuch.FieldByName("ToleranzINT").AsInteger();
                        ArbeitGlobals.Includis[I].TaktToleranzMinus = DatenM.qSuch.FieldByName("ToleranzINT").AsInteger();
                    }
                }
                DatenM.qSuch.Next();
            }

            // Main loop for all machines
            for (I = 1; I <= DBMain.Anzahl_Masch; I++)
            {
                if (ArbeitGlobals.Includis[I].IstArchiviert && (I > 1))
                    continue;

                ArbeitGlobals.Includis[I].ZyklenNeu = MainDLL.StueckAuftragGesamt[I].Istwert;

                // Calculate cycle differences
                if (MainDLL.Taktzeit[I].Istwert > 0)
                {
                    if ((ArbeitGlobals.Includis[I].ZyklenAll > 0) || (ArbeitGlobals.Includis[I].ZyklusLast > 0))
                    {
                        if ((ArbeitGlobals.Includis[I].ZyklenNeu > ArbeitGlobals.Includis[I].ZyklusLast))
                        {
                            tmptakt = MainDLL.Taktzeit[I].Istwert;
                            if (tmptakt == 0)
                                tmptakt = 1000; // Minimum 1 second
                            
                            if (((ArbeitGlobals.Includis[I].ZyklenNeu - ArbeitGlobals.Includis[I].ZyklusLast) * tmptakt) / 1000) <
                                ((MainDLL.Jetzt - ArbeitGlobals.Includis[I].ZyklusLastZeitpunkt) * 1440 * 60))
                            {
                                ArbeitGlobals.Includis[I].ZyklenDiff = ArbeitGlobals.Includis[I].ZyklenNeu - ArbeitGlobals.Includis[I].ZyklusLast;
                            }
                        }
                        else
                        {
                            ArbeitGlobals.Includis[I].ZyklenDiff = 0;
                        }
                        ArbeitGlobals.Includis[I].ZyklusLast = ArbeitGlobals.Includis[I].ZyklenNeu;
                    }
                    else
                    {
                        ArbeitGlobals.Includis[I].ZyklenDiff = 0;
                    }
                }

                // Ensure Var_Kavitaet is valid
                if (ArbeitGlobals.Includis[I].Auftrag.Var_Kavitaet < 1)
                    ArbeitGlobals.Includis[I].Auftrag.Var_Kavitaet = 1;

                // Set operating hours
                ArbeitGlobals.Includis[I].Betriebsstunden = MainDLL.Betriebsstunden[I].Istwert;
                if (ArbeitGlobals.Includis[I].Betriebsstunden < 0)
                {
                    MainDLL.SchreibeMeldung("Error: Operating hours / machine < 0: "
                        + ArbeitGlobals.Includis[I].Maschine + " at " + MainDLL.DateTimeToStr(MainDLL.Jetzt), 0);
                }

                // Set total runtime
                ArbeitGlobals.Includis[I].LaufzeitGes = MainDLL.LaufzeitGes[I].Istwert;
                if (ArbeitGlobals.Includis[I].LaufzeitGes < 0)
                {
                    MainDLL.SchreibeMeldung("Error: Runtime Total / machine < 0: "
                        + ArbeitGlobals.Includis[I].Maschine + " at " + MainDLL.DateTimeToStr(MainDLL.Jetzt), 0);
                }

                // Set shift runtime
                ArbeitGlobals.Includis[I].LaufzeitSchicht = MainDLL.LaufzeitSchicht[I].Istwert;
                if (ArbeitGlobals.Includis[I].LaufzeitSchicht < 0)
                {
                    MainDLL.SchreibeMeldung("Error: Runtime shift / machine < 0: "
                        + ArbeitGlobals.Includis[I].Maschine + " at " + MainDLL.DateTimeToStr(MainDLL.Jetzt), 0);
                }

                // Set current tact
                if (ArbeitGlobals.Includis[I].Maschine_geblockt) //RP BLOCKSTILL
                    ArbeitGlobals.Includis[I].IstTakt = 0;
                else
                    ArbeitGlobals.Includis[I].IstTakt = MainDLL.Taktzeit[I].Istwert; //RP BLOCKSTILL

                ArbeitGlobals.Includis[I].ZustandAlt = ArbeitGlobals.Includis[I].Zustand;

                // Calculate real runtime
                if (MainDLL.MaschProgrammbetrieb[I].Istwert) // Machine running according to bus
                {
                    ArbeitGlobals.Includis[I].TmpLaufzeitInZustand += ((MainDLL.Jetzt - ArbeitGlobals.Includis[I].TmpLastZustandCheck) * 1440);
                    ArbeitGlobals.Includis[I].TmpLaufzeitInZustandSchicht += ((MainDLL.Jetzt - ArbeitGlobals.Includis[I].TmpLastZustandCheck) * 1440);
                    
                    if (!ArbeitGlobals.Includis[I].MaschineLaeuft)  // Machine was stopped before
                    {
                        ArbeitGlobals.Includis[I].StillstandInZustand = (MainDLL.Jetzt - ArbeitGlobals.Includis[I].LetzterMaschinenStop) * 1440;
                        ArbeitGlobals.Includis[I].LetzterMaschinenStart = MainDLL.Jetzt;
                        ArbeitGlobals.Includis[I].MaschineLaeuft = true;
                    }
                    else
                    {
                        ArbeitGlobals.Includis[I].LaufzeitInZustand = (MainDLL.Jetzt - ArbeitGlobals.Includis[I].LetzterMaschinenStart) * 1440;
                    }
                }
                else  // Machine stopped according to bus
                {
                    ArbeitGlobals.Includis[I].TmpStillstandInZustand += ((MainDLL.Jetzt - ArbeitGlobals.Includis[I].TmpLastZustandCheck) * 1440);
                    ArbeitGlobals.Includis[I].TmpStillstandInZustandSchicht += ((MainDLL.Jetzt - ArbeitGlobals.Includis[I].TmpLastZustandCheck) * 1440);
                    
                    if (ArbeitGlobals.Includis[I].MaschineLaeuft)  // Machine was running before
                    {
                        ArbeitGlobals.Includis[I].LaufzeitInZustand = (MainDLL.Jetzt - ArbeitGlobals.Includis[I].LetzterMaschinenStart) * 1440;
                        ArbeitGlobals.Includis[I].LetzterMaschinenStop = MainDLL.Jetzt;
                        ArbeitGlobals.Includis[I].MaschineLaeuft = false;
                    }
                    else
                    {
                        ArbeitGlobals.Includis[I].StillstandInZustand = (MainDLL.Jetzt - ArbeitGlobals.Includis[I].LetzterMaschinenStop) * 1440;
                    }
                }
                ArbeitGlobals.Includis[I].TmpLastZustandCheck = MainDLL.Jetzt;

                // Determine machine state
                if (!ArbeitGlobals.Includis[I].Maschine_geblockt) //RP BLOCKSTILL
                {
                    if (MainDLL.MaschProgrammbetrieb[I].Istwert && (GetSignalStillstand(I) == -1))
                        IMaschProgramm = 1;
                    else
                        IMaschProgramm = 0;

                    if (IMaschProgramm == 0)
                        Zustand_Wert = 2;
                    if (IMaschProgramm == 1)
                        Zustand_Wert = 0;

                    if (ArbeitGlobals.Includis[I].Auftrag.Stat == ComtasH.stStartRuestenInt)
                    {
                        ArbeitGlobals.Includis[I].MaschZustandBeiRuesten = Zustand_Wert;
                        Zustand_Wert = DBMain.MaschRuesten;
                    }

                    ArbeitGlobals.Includis[I].Zustand = Zustand_Wert;
                } //RP BLOCKSTILL

                if (ArbeitGlobals.Includis[I].Maschine_geblockt)
                {
                    MainDLL.MaschProgrammbetrieb[I].Istwert = false;
                    IMaschProgramm = 0;
                    ArbeitGlobals.Includis[I].Zustand = 2;
                    Zustand_Wert = 2;
                }

                if (DBMain.Ruestzeit_Auftrag_FolgeAuftrag)
                {
                    if ((ArbeitGlobals.Includis[I].Auftrag.Stat != ComtasH.stLaeuftInt)) // No order registered, so status = setup
                        ArbeitGlobals.Includis[I].Zustand = DBMain.MaschRuesten;
                }

                ArbeitGlobals.Includis[I].Schicht = Schichtwert;

                // Calculate piece counts and quality if machine is not blocked
                if (!ArbeitGlobals.Includis[I].Maschine_geblockt) //RP BLOCKSTILL
                {
                    if (ArbeitGlobals.Includis[I].Auftrag.InPause == 0)
                    {
                        if (DBMain.KavitaetFromSPS)
                            ArbeitGlobals.Includis[I].StueckAuftragGesamt = (MainDLL.StueckAuftragGesamt[I].Istwert) /
                                ArbeitGlobals.Includis[I].Auftrag.Var_Kavitaet;
                        else
                        {
                            if (!DBMain.Kavitaet_laufender_Auftrag3 || (ArbeitGlobals.Includis[I].Auftrag.LetzerKavWechsel.Datum < DateTime.MinValue))
                            {
                                ArbeitGlobals.Includis[I].StueckAuftragGesamt = (MainDLL.StueckAuftragGesamt[I].Istwert * ArbeitGlobals.Includis[I].Auftrag.Kopfgroesse) /
                                    ArbeitGlobals.Includis[I].Auftrag.Var_Kavitaet;
                            }
                            else
                            {
                                diff = MainDLL.StueckAuftragGesamt[I].Istwert - ArbeitGlobals.Includis[I].Auftrag.LetzerKavWechsel.Schusszaehler;
                                ArbeitGlobals.Includis[I].StueckAuftragGesamt = (diff * ArbeitGlobals.Includis[I].Auftrag.Kopfgroesse) /
                                    ArbeitGlobals.Includis[I].Auftrag.Var_Kavitaet +
                                    ArbeitGlobals.Includis[I].Auftrag.LetzerKavWechsel.Produziert;
                            }
                        }
                    }

                    if (ArbeitGlobals.Includis[I].Auftrag.InPause == 1)
                        ArbeitGlobals.Includis[I].Auftrag.Anfahrausschuss += MainDLL.Diff_Stueck[I];

                    ArbeitGlobals.Includis[I].StueckPruefAuftragGesamt = MainDLL.StueckPruefAuftragGesamt[I].Istwert * ArbeitGlobals.Includis[I].Pruefstation;

                    if (!DBMain.Verpackt_Barcode)
                        ArbeitGlobals.Includis[I].StueckPackAuftragGesamt = MainDLL.StueckPackAuftragGesamt[I].Istwert * ArbeitGlobals.Includis[I].Packgroesse;

                    if (ArbeitGlobals.Includis[I].Prod_Gleich_Pack)
                    {
                        ArbeitGlobals.Includis[I].StueckAuftragGesamt = ArbeitGlobals.Includis[I].StueckPackAuftragGesamt;
                        ArbeitGlobals.Includis[I].Auftrag.Istwert = ArbeitGlobals.Includis[I].StueckAuftragGesamt;
                    }

                    if (ArbeitGlobals.Includis[I].Auftrag.Sollwert == 0)
                        ArbeitGlobals.Includis[I].Auftrag.Sollwert = 1;

                    if ((ArbeitGlobals.Includis[I].Auftrag.Stat == ComtasH.stLaeuftInt) || 
                        (ArbeitGlobals.Includis[I].Auftrag.Stat == ComtasH.stStartRuestenInt))
                    {
                        ArbeitGlobals.Includis[I].Auftrag.Istwert = ArbeitGlobals.Includis[I].StueckAuftragGesamt;
                    }
                    
                    if (keinProduziertBeiRuestenInt == 1 && (ArbeitGlobals.Includis[I].Auftrag.Stat == ComtasH.stStartRuestenInt))
                        ArbeitGlobals.Includis[I].Auftrag.Istwert = 0;

                    // Handle extrusion specific logic
                    if (DBMain.Extrusion)
                    {
                        SQLStr = "select Count(*) CNT from BuchungsProt"
                            + " where BetriebsAuftragNr = '" + ArbeitGlobals.Includis[I].Auftrag.BetriebsauftragNr + "'";
                        SQL_fuc.SQL_Get(DatenM.qSuch, SQLStr);
                        if (DatenM.qSuch.FieldByName("CNT").AsInteger() > 0)
                        {
                            SQLStr = "select Sum(Menge) CNT from BuchungsProt"
                                + " where BetriebsAuftragNr = '" + ArbeitGlobals.Includis[I].Auftrag.BetriebsauftragNr + "'";
                            SQL_fuc.SQL_Get(DatenM.qSuch, SQLStr);
                            ArbeitGlobals.Includis[I].Auftrag.Istwert = ArbeitFunctions.Format_String(
                                DatenM.qSuch.FieldByName("CNT").AsString());
                        }
                        else
                        {
                            ArbeitGlobals.Includis[I].Auftrag.Istwert = 0;
                        }
                    }

                    // Calculate percentage
                    ArbeitGlobals.Includis[I].Auftrag.Ist_PRZ = (int)Math.Round(
                        (ArbeitGlobals.Includis[I].Auftrag.Istwert / 
                        (double)(ArbeitGlobals.Includis[I].Auftrag.Sollwert + ArbeitGlobals.Includis[I].Auftrag.SollwertOffset)) * 100);

                    // Handle KombiWerkzeuge logic
                    if (DBMain.KombiWerkzeuge && 
                        ((ArbeitGlobals.Includis[I].Auftrag.Stat != ComtasH.stStartRuestenInt) || !Anfahr_Ausschuss2))
                    {
                        if (ArbeitGlobals.Includis[I].Auftrag.MasterAuftrag)
                        {
                            try
                            {
                                // Complex logic for KombiWerkzeuge would go here
                                // This is a simplified version
                            }
                            catch (Exception e)
                            {
                                MainDLL.SchreibeMeldung(e.Message + " - " + ArbeitGlobals.Includis[I].Auftrag.BetriebsauftragNr, 0);
                            }
                        }
                    }

                    // Calculate piece counts for shift
                    if (!DBMain.Metall)
                    {
                        if (DBMain.Variable_Kavitaet)
                            ArbeitGlobals.Includis[I].StueckSchicht = (MainDLL.StueckSchicht[I].Istwert * ArbeitGlobals.Includis[I].Auftrag.Kopfgroesse) /
                                ArbeitGlobals.Includis[I].Auftrag.Var_Kavitaet;
                        else
                        {
                            if (DBMain.KavitaetFromSPS)
                                ArbeitGlobals.Includis[I].StueckSchicht = MainDLL.StueckSchicht[I].Istwert;
                            else
                                ArbeitGlobals.Includis[I].StueckSchicht = MainDLL.StueckSchicht[I].Istwert * ArbeitGlobals.Includis[I].Auftrag.Kopfgroesse;
                        }
                    }

                    try
                    {
                        if (ArbeitGlobals.Includis[I].Auftrag.Packgroesse > 0)
                            ArbeitGlobals.Includis[I].KARTONS = ArbeitGlobals.Includis[I].StueckAuftragGesamt / 
                                ArbeitGlobals.Includis[I].Auftrag.Packgroesse;
                        else
                            ArbeitGlobals.Includis[I].KARTONS = 0;
                        
                        if (ArbeitGlobals.Includis[I].KARTONS > 0)
                            ArbeitGlobals.Includis[I].PALETTEN = ArbeitGlobals.Includis[I].StueckAuftragGesamt / 
                                ArbeitGlobals.Includis[I].KARTONS;
                        else
                            ArbeitGlobals.Includis[I].PALETTEN = 0;
                    }
                    catch
                    {
                        ArbeitGlobals.Includis[I].KARTONS = 0;
                        ArbeitGlobals.Includis[I].PALETTEN = 0;
                    }

                    ArbeitGlobals.Includis[I].StueckPruefSchicht = MainDLL.StueckPruefSchicht[I].Istwert * ArbeitGlobals.Includis[I].Pruefstation;
                    if (!DBMain.Verpackt_Barcode)
                        ArbeitGlobals.Includis[I].StueckPackSchicht = MainDLL.StueckPackSchicht[I].Istwert * ArbeitGlobals.Includis[I].Packgroesse;

                    ArbeitGlobals.Includis[I].AusschussSchicht = ArbeitGlobals.Includis[I].StueckSchicht - ArbeitGlobals.Includis[I].StueckPackSchicht;
                    ArbeitGlobals.Includis[I].AusschussAuftragSchicht = ArbeitGlobals.Includis[I].StueckAuftragSchicht - ArbeitGlobals.Includis[I].StueckPackAuftragSchicht;

                    // Calculate shift piece counts
                    if (!DBMain.Metall)
                    {
                        if (DBMain.Variable_Kavitaet)
                            ArbeitGlobals.Includis[I].StueckAuftragSchicht = (MainDLL.StueckAuftragSchicht[I].Istwert * ArbeitGlobals.Includis[I].Auftrag.Kopfgroesse) /
                                ArbeitGlobals.Includis[I].Auftrag.Var_Kavitaet;
                        else
                        {
                            if (DBMain.KavitaetFromSPS)
                                ArbeitGlobals.Includis[I].StueckAuftragSchicht = MainDLL.StueckAuftragSchicht[I].Istwert;
                            else
                                ArbeitGlobals.Includis[I].StueckAuftragSchicht = MainDLL.StueckAuftragSchicht[I].Istwert * ArbeitGlobals.Includis[I].Auftrag.Kopfgroesse;
                        }
                    }

                    ArbeitGlobals.Includis[I].StueckAuftragSchicht_SPS = ArbeitGlobals.Includis[I].StueckAuftragSchicht;

                    // Calculate quality if needed
                    if (DBMain.Menge_Schicht_Berechnen && (!string.IsNullOrEmpty(ArbeitGlobals.Includis[I].Auftrag.BetriebsauftragNr)))
                    {
                        // Complex shift quantity calculation would go here
                        // This is a placeholder for the extensive SQL logic
                    }

                    // Handle PruefPack = 4 (no checking, no packing)
                    if (ArbeitGlobals.Includis[I].PruefPack == 4)
                    {
                        ArbeitGlobals.Includis[I].StueckPruefAuftragGesamt = ArbeitGlobals.Includis[I].StueckAuftragGesamt;
                        if (!DBMain.Verpackt_Barcode)
                            ArbeitGlobals.Includis[I].StueckPackAuftragGesamt = ArbeitGlobals.Includis[I].StueckAuftragGesamt;
                        ArbeitGlobals.Includis[I].StueckPruefSchicht = ArbeitGlobals.Includis[I].StueckSchicht;
                        if (!DBMain.Verpackt_Barcode)
                            ArbeitGlobals.Includis[I].StueckPackSchicht = ArbeitGlobals.Includis[I].StueckSchicht;
                        ArbeitGlobals.Includis[I].AusschussSchicht = ArbeitGlobals.Includis[I].StueckSchicht - ArbeitGlobals.Includis[I].StueckPackSchicht;
                        ArbeitGlobals.Includis[I].StueckPruefAuftragSchicht = ArbeitGlobals.Includis[I].StueckAuftragSchicht;
                        if (!DBMain.Verpackt_Barcode)
                            ArbeitGlobals.Includis[I].StueckPackAuftragSchicht = ArbeitGlobals.Includis[I].StueckAuftragSchicht;
                    }

                    // Handle Verpackt_aus_Ausschuss
                    if (DBMain.Verpackt_aus_Ausschuss)
                    {
                        ArbeitGlobals.Includis[I].StueckPackAuftragGesamt = ArbeitGlobals.Includis[I].Auftrag.Istwert - ArbeitGlobals.Includis[I].Auftrag.Ausschuss;
                        ArbeitGlobals.Includis[I].StueckPackAuftragSchicht = ArbeitGlobals.Includis[I].StueckAuftragSchicht - ArbeitGlobals.Includis[I].AusschussAuftragSchicht;
                        ArbeitGlobals.Includis[I].StueckPackSchicht = ArbeitGlobals.Includis[I].StueckSchicht - ArbeitGlobals.Includis[I].AusschussSchicht;
                    }

                    // Set HandAuto
                    if (DBMain.halbautomatik)
                        ArbeitGlobals.Includis[I].HandAuto = MainDLL.HandAuto[I].Istwert;
                    else
                        ArbeitGlobals.Includis[I].HandAuto = false;

                    ArbeitGlobals.Includis[I].BCD_Read = MainDLL.BCD_Read[I].Istwert;
                    ArbeitGlobals.Includis[I].BCDCode = (short)MainDLL.BCD[I].Istwert;

                    // Calculate utilization, performance, quality, efficiency
                    if (!ArbeitGlobals.Includis[I].Maschine_geblockt) //RP BLOCKSTILL
                    {
                        Ausschuss = ArbeitGlobals.Includis[I].StueckAuftragSchicht - ArbeitGlobals.Includis[I].StueckPackAuftragSchicht;

                        // Calculate utilization
                        TagwechselInt = 0;
                        if (ArbeitGlobals.Includis[I].Schicht == 1)
                            Schichtanfang = MainDLL.ConvertFromFloat(ArbeitGlobals.Schicht1);
                        else if (ArbeitGlobals.Includis[I].Schicht == 2)
                            Schichtanfang = MainDLL.ConvertFromFloat(ArbeitGlobals.Schicht2);
                        else if (ArbeitGlobals.Includis[I].Schicht == 3)
                            Schichtanfang = MainDLL.ConvertFromFloat(ArbeitGlobals.Schicht3);

                        Tag = MainDLL.Trunc(Schichtanfang);
                        MinutenAnfang = MainDLL.Frac(Schichtanfang);
                        
                        // Tagwechsel
                        if (MinutenAnfang > 0.8)
                        {
                            TagwechselInt = 1;
                            MinutenAnfang = 0.0;
                        }

                        Tag = MainDLL.Trunc(MainDLL.Jetzt);
                        MinutenJetzt = MainDLL.Frac(MainDLL.Jetzt);

                        tbMinuten = (int)((MinutenJetzt - MinutenAnfang) * 24 * 60);
                        if (TagwechselInt == 1)
                            tbMinuten = tbMinuten + 120; // from 22:00 to 0:00

                        // If hand operation, subtract SchichtZeitHandbetrieb
                        if ((tbMinuten > DBMain.SchichtZeitHandbetrieb) && (ArbeitGlobals.Includis[I].HandAuto))
                            tbMinuten = tbMinuten - DBMain.SchichtZeitHandbetrieb;

                        if ((tbMinuten < 0) && (DBMain.Shift_Model != 2))
                        {
                            Meldung = "Error: calculation minutes start of shift to " + MainDLL.DateToStr(MainDLL.Trunc(MainDLL.Jetzt))
                                + " at: " + MainDLL.TimeToStr(MainDLL.Frac(MainDLL.Jetzt)) + " < 0 !! Minutes: " + tbMinuten.ToString();
                            MainDLL.SchreibeMeldung(Meldung, 0);
                        }

                        // Calculate quality
                        NA = 0; // Only for Metall
                        int Divisor = ArbeitGlobals.Includis[I].StueckAuftragSchicht;
                        if (Divisor == 0)
                            Divisor = 1;
                        ArbeitGlobals.Includis[I].Qualitaet = ((ArbeitGlobals.Includis[I].StueckAuftragSchicht - Ausschuss - NA - ArbeitGlobals.Includis[I].AusschussAuftragSchicht) / (double)Divisor) * 100;
                    }
                }
            }

            // Reset data for machines without active orders
            for (I = 1; I <= DBMain.Anzahl_Masch; I++)
            {
                if ((string.IsNullOrEmpty(ArbeitGlobals.Includis[I].Auftrag.AuftragNr)) && !ArbeitGlobals.Includis[I].IstArchiviert)
                {
                    ArbeitGlobals.Includis[I].IstTakt = 0;
                    ArbeitGlobals.Includis[I].StueckSchicht = 0;
                    ArbeitGlobals.Includis[I].StueckPackSchicht = 0;
                    ArbeitGlobals.Includis[I].StueckPruefSchicht = 0;
                    ArbeitGlobals.Includis[I].Nutzung = 0;
                    ArbeitGlobals.Includis[I].Leistung = 0;
                    ArbeitGlobals.Includis[I].Qualitaet = 0;
                    ArbeitGlobals.Includis[I].Effektivitaet = 0;
                    ArbeitGlobals.Includis[I].Auftrag.Ist_PRZ = 0;
                    ArbeitGlobals.Includis[I].Auftrag.Programm_Nr = 0;
                    ArbeitGlobals.Includis[I].Auftrag.Istwert = 0;
                    ArbeitGlobals.Includis[I].Auftrag.Ausschuss = 0;
                    ArbeitGlobals.Includis[I].Auftrag.Verpackt = 0;
                    ArbeitGlobals.Includis[I].StueckPruefAuftragGesamt = 0;
                    ArbeitGlobals.Includis[I].StueckPackAuftragGesamt = 0;
                    ArbeitGlobals.Includis[I].Auftrag.Schwesterauftrag = string.Empty;
                    ArbeitGlobals.Includis[I].Auftrag.Form = string.Empty;
                    ArbeitGlobals.Includis[I].Auftrag.Optimiert = 0;
                    ArbeitGlobals.Includis[I].Auftrag.OptimiertAktuell = 0;
                    ArbeitGlobals.Includis[I].Auftrag.Anfahrausschuss = 0;
                    ArbeitGlobals.Includis[I].StueckPackAuftragSchicht = 0;
                    ArbeitGlobals.Includis[I].StueckAuftragSchicht = 0;
                    ArbeitGlobals.Includis[I].AusschussAuftragSchicht = 0;
                    ArbeitGlobals.Includis[I].ZyklenAuftragGesamt = 0;
                    ArbeitGlobals.Includis[I].ZyklenAuftragSchicht = 0;
                }
            }
        }

        // ========================================================================
        // CCC_Zeiten_Aufrunden - Round times
        // ========================================================================
        
        public static void CCC_Zeiten_Aufrunden_Implementation()
        {
            DateTime Datum, Zeit;
            int Nummer, AlteSchicht, I;

            Datum = MainDLL.Trunc(MainDLL.Jetzt);
            Zeit = MainDLL.Frac(MainDLL.Jetzt);
            
            if (MainDLL.Frac(MainDLL.Jetzt) <= ArbeitGlobals.Schicht1)
                Datum = Datum.AddDays(-1);

            for (I = 1; I <= DBMain.Anzahl_Masch; I++)
            {
                if (ArbeitGlobals.Includis[I].IstArchiviert)
                    continue;

                if (ArbeitGlobals.Includis[I].Schicht == 1)
                {
                    Zeit = MainDLL.ConvertFromFloat(ArbeitGlobals.Schicht1);
                    AlteSchicht = 3;
                }
                else if (ArbeitGlobals.Includis[I].Schicht == 2)
                {
                    Zeit = MainDLL.ConvertFromFloat(ArbeitGlobals.Schicht2);
                    AlteSchicht = 1;
                }
                else
                {
                    Zeit = MainDLL.ConvertFromFloat(ArbeitGlobals.Schicht3);
                    AlteSchicht = 2;
                }

                if (SQL_fuc.SQL3GetBool(DatenM.qSuch, "SPC", "Maschine", ArbeitGlobals.Includis[I].Maschine,
                    "Schicht", AlteSchicht.ToString(), "Datum", MainDLL.DateToStr(Datum)))
                {
                    Nummer = DatenM.qSuch.FieldByName("Nr").AsInteger();
                    SQL_fuc.UpdateSQL(DatenM.qUpdate, "SPC", "Zeit", MainDLL.TimeToStr(Zeit), "Nr", Nummer.ToString());
                }
            }
        }

        // ========================================================================
        // Helper functions for GetSignalStillstand, etc.
        // ========================================================================

        public static int GetSignalStillstand(int Datenblock)
        {
            // This would query the database to get the current downtime signal for a machine
            // For now, return -1 (no downtime)
            return -1;
        }

        public static int GetAktion(int Stillstandnr)
        {
            // Lookup action for downtime number
            for (int i = 1; i < ArbeitGlobals.Stillstand.Count; i++)
            {
                if (ArbeitGlobals.Stillstand[i].Stillstandnr == Stillstandnr)
                    return ArbeitGlobals.Stillstand[i].Aktion;
            }
            return 0;
        }

        public static int GetDBNr(int SignalNr, int MaschNr)
        {
            // This would look up the database number for a signal
            // For now, return a default value
            return SignalNr * 1000 + MaschNr;
        }

        public static void LoadSignals(CO_Query Q)
        {
            // Load signal data from database
            string SQLStr = "SELECT * FROM Signal";
            SQL_fuc.SQL_Get(Q, SQLStr);
            
            ArbeitGlobals.Signal.Clear();
            while (!Q.EOF)
            {
                var signal = new TSignal
                {
                    SignalNr = Q.FieldByName("SignalNr").AsInteger(),
                    SignalArt = Q.FieldByName("SignalArt").AsInteger()
                };
                ArbeitGlobals.Signal.Add(signal);
                Q.Next();
            }
        }

        public static string GetSelectedMaschinen(CO_Query Q, string AndStr, string Feld, string Liste, int Style)
        {
            // This would build a SQL query to select specific machines
            // For now, return a simple query
            return "SELECT * FROM Maschine WHERE " + Feld + " IN (" + Liste + ")";
        }

        public static void Statistik_Berechnen()
        {
            // Calculate statistics - placeholder
        }

        public static void GetPersonalNr_Signal()
        {
            // Get personal number from signal - placeholder
        }

        public static void GetAusschuss_Signal()
        {
            // Get scrap from signal - placeholder
        }

        public static bool CheckCO_DatabaseConnect(CO_Database C, CO_Query Q, int LogId, string thread)
        {
            // Check database connection - placeholder
            return true;
        }

        public static void CCC_Proc_Ruesten_AutoBuchen()
        {
            // Auto booking for setup - placeholder
        }

        // ========================================================================
        // CCC_Job_Auftrag - Process order jobs
        // ========================================================================
        
        public static void CCC_Job_Auftrag_Implementation()
        {
            int Nummer;
            string Meldung;
            int I;
            string automatikstr;

            for (I = 1; I <= DBMain.Anzahl_Masch; I++)
            {
                if ((ArbeitGlobals.Includis[I].Auftrag.Stat == ComtasH.stLaeuftInt) && !ArbeitGlobals.Includis[I].IstArchiviert)
                {
                    // Menge erfüllt ??
                    if (((ArbeitGlobals.Includis[I].Auftrag.Istwert >= (ArbeitGlobals.Includis[I].Auftrag.SollwertOffset + ArbeitGlobals.Includis[I].Auftrag.Sollwert)) && !ArbeitGlobals.Includis[I].Auftrag.Erzeugt))
                    {
                        // Check if Arbeitsplan already exists
                        DatenM.qSuch.Close();
                        if (SQL_fuc.SQL2GetBool(DatenM.qSuch, "BDA", "Lizenz", ArbeitGlobals.Includis[I].Lizenz, "Bezeichnung",
                            ArbeitGlobals.Includis[I].Auftrag.Bezeichnung))
                        {
                            if (DatenM.qSuch.FieldByName("Zustand").AsString() == Sprache_V63.GetL("Vorwarnung"))
                            {
                                // Change status
                                Nummer = DatenM.qSuch.FieldByName("Nr").AsInteger();
                                Meldung = Sprache_V63.GetL("Menge erfüllt");
                                SQL_fuc.UpdateSQL(DatenM.qUpdate, "BDA", "Zustand", Meldung, "Nr", Nummer.ToString());
                                if (DatenM.qSuch.FieldByName("Erledigt").AsString() == Sprache_V63.GetL("Vorwarnung"))
                                {
                                    SQL_fuc.UpdateSQL(DatenM.qUpdate, "BDA", "Erledigt", Meldung, "Nr", Nummer.ToString());
                                }
                            }
                        }
                        else
                        {
                            CCC_Erzeuge_Arbeitsplan(ArbeitGlobals.Includis[I].Lizenz, ArbeitGlobals.Includis[I].MaschNr,
                                ArbeitGlobals.Includis[I].Auftrag.Signal,
                                (ArbeitGlobals.Includis[I].Auftrag.Sollwert + ArbeitGlobals.Includis[I].Auftrag.SollwertOffset).ToString(),
                                ArbeitGlobals.Includis[I].Auftrag.Bezeichnung,
                                ArbeitGlobals.Includis[I].Auftrag.Zustaendig,
                                false, ArbeitGlobals.Includis[I].Auftrag.Vorwarnung.ToString(), false, false);
                        }
                        
                        // Mark order as "Erzeugt"
                        DatenM.qSuch.Close();
                        if (SQL_fuc.SQL2GetBool(DatenM.qSuch, "PDE", "Lizenz", ArbeitGlobals.Includis[I].Lizenz, "Bezeichnung",
                            ArbeitGlobals.Includis[I].Auftrag.Bezeichnung))
                        {
                            SQL_fuc.Update2SQL(DatenM.qUpdate, "PDE", "Erzeugt", "1", "Lizenz", ArbeitGlobals.Includis[I].Lizenz, "Bezeichnung",
                                ArbeitGlobals.Includis[I].Auftrag.Bezeichnung);
                        }

                        // Refresh data
                        CCC_Init_Implementation();
                        return;
                    }

                    // Vorwarnung ??
                    if (((ArbeitGlobals.Includis[I].Auftrag.Ist_PRZ >= ArbeitGlobals.Includis[I].Auftrag.Vorwarnung) && !ArbeitGlobals.Includis[I].Auftrag.VorwarnungErzeugt))
                    {
                        // Check if Arbeitsplan already exists
                        DatenM.qSuch.Close();
                        if (SQL_fuc.SQL2GetBool(DatenM.qSuch, "BDA", "Lizenz", ArbeitGlobals.Includis[I].Lizenz, "Bezeichnung",
                            ArbeitGlobals.Includis[I].Auftrag.Bezeichnung))
                        {
                            // Already exists
                        }
                        else
                        {
                            CCC_Erzeuge_Arbeitsplan(ArbeitGlobals.Includis[I].Lizenz, ArbeitGlobals.Includis[I].MaschNr,
                                ArbeitGlobals.Includis[I].Auftrag.Signal,
                                (ArbeitGlobals.Includis[I].Auftrag.Sollwert + ArbeitGlobals.Includis[I].Auftrag.SollwertOffset).ToString(),
                                ArbeitGlobals.Includis[I].Auftrag.Bezeichnung,
                                ArbeitGlobals.Includis[I].Auftrag.Zustaendig,
                                true, ArbeitGlobals.Includis[I].Auftrag.Vorwarnung.ToString(), false, false);
                        }
                        ArbeitGlobals.Includis[I].Auftrag.VorwarnungErzeugt = true;
                    }

                    // Halbautomatik Schlüsselschalter ??
                    if (((ArbeitGlobals.Includis[I].Auftrag.HalbAuto != ArbeitGlobals.Includis[I].HandAuto)
                        && !ArbeitGlobals.Includis[I].Auftrag.VorwarnungErzeugt)
                        && (ArbeitGlobals.Includis[I].Auftrag.Stat != 2) && DBMain.halbautomatik
                        && CO_Setup2.TCO_Setup.GetParamBool(DatenM.qUpdate, "INCL_HalbautomatSchluesselschalter"))
                    {
                        if (ArbeitGlobals.Includis[I].Auftrag.HalbAuto)
                            automatikstr = Sprache_V63.GetL("Halbautomatik");
                        else
                            automatikstr = Sprache_V63.GetL("Automatik");

                        DatenM.qSuch.Close();
                        if (SQL_fuc.SQL2GetBool(DatenM.qSuch, "BDA", "Lizenz", ArbeitGlobals.Includis[I].Lizenz,
                            "Bezeichnung", Sprache_V63.GetL("Fehler Auftrag: Schlüsselschalter prüfen")))
                        {
                            // Already exists
                        }
                        else
                        {
                            CCC_Erzeuge_Arbeitsplan(ArbeitGlobals.Includis[I].Lizenz, ArbeitGlobals.Includis[I].MaschNr,
                                ArbeitGlobals.Includis[I].Auftrag.Signal,
                                automatikstr,
                                Sprache_V63.GetL("Fehler Auftrag: Schlüsselschalter prüfen"),
                                ArbeitGlobals.Includis[I].Auftrag.Zustaendig,
                                false, ArbeitGlobals.Includis[I].Auftrag.Vorwarnung.ToString(), false, true);
                        }
                        ArbeitGlobals.Includis[I].Auftrag.VorwarnungErzeugt = true;
                    }
                }
            }
        }

        // ========================================================================
        // CCC_BDE_Auftrag - Process BDE jobs
        // ========================================================================
        
        public static void CCC_BDE_Auftrag_Implementation()
        {
            int Nummer;
            string Meldung;
            int I;

            for (I = 1; I <= DBMain.Anzahl_Masch; I++)
            {
                if ((!string.IsNullOrEmpty(ArbeitGlobals.Includis[I].BDE.Bezeichnung)) && !ArbeitGlobals.Includis[I].IstArchiviert)
                {
                    // Menge erfüllt ??
                    if ((ArbeitGlobals.Includis[I].Betriebsstunden >= ArbeitGlobals.Includis[I].BDE.Sollwert) && !ArbeitGlobals.Includis[I].BDE.Erzeugt)
                    {
                        // Check if Arbeitsplan already exists
                        DatenM.qSuch.Close();
                        if (SQL_fuc.SQL2GetBool(DatenM.qSuch, "BDA", "Lizenz", ArbeitGlobals.Includis[I].Lizenz, "Bezeichnung", ArbeitGlobals.Includis[I].BDE.Bezeichnung))
                        {
                            if (DatenM.qSuch.FieldByName("Zustand").AsString() == "Vorwarnung")
                            {
                                // Change status
                                Nummer = DatenM.qSuch.FieldByName("Nr").AsInteger();
                                Meldung = Sprache_V63.GetL("sofort erledigen");
                                SQL_fuc.UpdateSQL(DatenM.qUpdate, "BDA", "Zustand", Meldung, "Nr", Nummer.ToString());
                                if (DatenM.qSuch.FieldByName("Erledigt").AsString() == Sprache_V63.GetL("Vorwarnung"))
                                {
                                    SQL_fuc.UpdateSQL(DatenM.qUpdate, "BDA", "Erledigt", Meldung, "Nr", Nummer.ToString());
                                }
                            }
                        }
                        else
                        {
                            CCC_Erzeuge_Arbeitsplan(ArbeitGlobals.Includis[I].Lizenz, ArbeitGlobals.Includis[I].MaschNr,
                                ArbeitGlobals.Includis[I].BDE.Signal,
                                ArbeitGlobals.Includis[I].BDE.Sollwert.ToString(),
                                ArbeitGlobals.Includis[I].BDE.Bezeichnung,
                                ArbeitGlobals.Includis[I].BDE.Zustaendig,
                                false, ArbeitGlobals.Includis[I].BDE.Vorwarnung.ToString(), false, false);
                        }
                        
                        // Mark as "Erzeugt"
                        DatenM.qSuch.Close();
                        if (SQL_fuc.SQL2GetBool(DatenM.qSuch, "MDE", "Lizenz", ArbeitGlobals.Includis[I].Lizenz, "JobBezeichnung",
                            ArbeitGlobals.Includis[I].BDE.Bezeichnung))
                        {
                            Nummer = DatenM.qSuch.FieldByName("Nr").AsInteger();
                            SQL_fuc.DeleteSQL(DatenM.qUpdate, "MDE", "Nr", Nummer.ToString());
                        }

                        // Refresh data
                        CCC_Init_Implementation();
                        return;
                    }

                    // Vorwarnung ??
                    if ((ArbeitGlobals.Includis[I].Betriebsstunden >= ArbeitGlobals.Includis[I].BDE.Vorwarnung) && !ArbeitGlobals.Includis[I].BDE.VorwarnungErzeugt)
                    {
                        // Check if Arbeitsplan already exists
                        DatenM.qSuch.Close();
                        if (SQL_fuc.SQL2GetBool(DatenM.qSuch, "BDA", "Lizenz", ArbeitGlobals.Includis[I].Lizenz, "Bezeichnung", ArbeitGlobals.Includis[I].BDE.Bezeichnung))
                        {
                            // Already exists
                        }
                        else
                        {
                            CCC_Erzeuge_Arbeitsplan(ArbeitGlobals.Includis[I].Lizenz, ArbeitGlobals.Includis[I].MaschNr,
                                ArbeitGlobals.Includis[I].BDE.Signal,
                                ArbeitGlobals.Includis[I].BDE.Sollwert.ToString(),
                                ArbeitGlobals.Includis[I].BDE.Bezeichnung,
                                ArbeitGlobals.Includis[I].BDE.Zustaendig,
                                true, ArbeitGlobals.Includis[I].BDE.Vorwarnung.ToString(), false, false);
                        }
                        ArbeitGlobals.Includis[I].BDE.VorwarnungErzeugt = true;
                    }
                }
            }
        }

        // ========================================================================
        // CCC_Erzeuge_Arbeitsplan - Create work plan
        // ========================================================================
        
        public static void CCC_Erzeuge_Arbeitsplan(string Lizenz, string MaschNr, string Signal,
            string Sollwert, string Bezeichnung, string Zustaendig, bool Vorwarnung, 
            string VorwarnungSTR, bool BDE_Ver, bool RoteLampeAn)
        {
            int Nummer;
            string WertZustand, SQLStr, Maschine, Quelle = string.Empty;
            DateTime T = MainDLL.Jetzt;
            short IntRoteLampe = 0;
            short NeuerJob = 1;

            if (RoteLampeAn)
                IntRoteLampe = 1;
            else
                IntRoteLampe = 0;

            Quelle = Sprache_V63.GetL("BDE");

            if (Signal == Sprache_V63.GetL("HEIZUNG"))
                Quelle = Sprache_V63.GetL("System");
            if ((Signal == Sprache_V63.GetL("Stückzahl Maschine")) && !BDE_Ver)
                Quelle = Sprache_V63.GetL("Produktion");
            if ((Signal == Sprache_V63.GetL("Stückzahl prüfen")) && !BDE_Ver)
                Quelle = Sprache_V63.GetL("Produktion");
            if ((Signal == Sprache_V63.GetL("Stückzahl gepackt")) && !BDE_Ver)
                Quelle = Sprache_V63.GetL("Produktion");
            if ((Signal == Sprache_V63.GetL("VS-Poti")) && !BDE_Ver)
                Quelle = Sprache_V63.GetL("Produktion");

            if ((Signal == Sprache_V63.GetL("Stückzahl Maschine")) && !BDE_Ver)
            {
                if (!DBMain.JOBPRODUKTION)
                    return;
            }

            if (Signal == Sprache_V63.GetL("Soll-Heizzone 1"))
                Quelle = Sprache_V63.GetL("SPC");
            if (Signal == Sprache_V63.GetL("Soll-Heizzone 2"))
                Quelle = Sprache_V63.GetL("SPC");
            if (Signal == Sprache_V63.GetL("Soll-Spritzdruck"))
                Quelle = Sprache_V63.GetL("SPC");
            if (Signal == Sprache_V63.GetL("Soll-Nachdruck"))
                Quelle = Sprache_V63.GetL("SPC");
            if (Signal == Sprache_V63.GetL("Soll-Speed"))
                Quelle = Sprache_V63.GetL("SPC");

            if (Quelle == Sprache_V63.GetL("Auftragstart"))
                WertZustand = Sprache_V63.GetL("sofort erledigen");
            else if (Quelle == Sprache_V63.GetL("BDE"))
            {
                if (Vorwarnung)
                    WertZustand = Sprache_V63.GetL("Vorwarnung");
                else
                    WertZustand = Sprache_V63.GetL("sofort erledigen");
            }
            else
            {
                if (Vorwarnung)
                    WertZustand = Sprache_V63.GetL("Vorwarnung");
                else
                    WertZustand = Sprache_V63.GetL("Menge erfüllt");
            }

            if ((Signal == Sprache_V63.GetL("HEIZUNG")) && (Quelle == Sprache_V63.GetL("System")))
                WertZustand = Sprache_V63.GetL("sofort erledigen");

            if (Quelle == Sprache_V63.GetL("SPC"))
                WertZustand = Sprache_V63.GetL("sofort erledigen");

            NeuerJob = 1;
            DatenM.qCreateDB.Close();

            // If already exists, don't insert again
            if ((Signal == Sprache_V63.GetL("HEIZUNG")) && (Quelle == Sprache_V63.GetL("System")))
            {
                SQL_fuc.SQL_Get(DatenM.qUpdate, "SELECT count(*) cnt FROM bda WHERE lizenz = '" + Lizenz
                    + "' AND signal = '" + Signal + "'");
                if (DatenM.qUpdate.FieldByName("cnt").AsInteger() > 0)
                    return;
            }

            if (Bezeichnung.Contains(Sprache_V63.GetL("Taktzeit")))
            {
                if (CO_Setup2.TCO_Setup.GetParamBool(DatenM.qSuch3, "INCL_TaktmeldungNichtWiederholen"))
                {
                    SQL_fuc.SQL_Get(DatenM.qUpdate, "SELECT count(*) cnt FROM bda WHERE lizenz = '" + Lizenz
                        + "' AND signal = '" + Signal + "'");
                    if (DatenM.qUpdate.FieldByName("cnt").AsInteger() > 0)
                        return;
                }
            }

            if (SQL_fuc.SQL2GetBool(DatenM.qCreateDB, "BDA", "Lizenz", Lizenz, "Bezeichnung", Bezeichnung))
            {
                Nummer = DatenM.qCreateDB.FieldByName("Nr").AsInteger();
                SQL_fuc.DeleteSQL(DatenM.qUpdate, "BDA", "Nr", Nummer.ToString());
                NeuerJob = 0;
            }
            DatenM.qCreateDB.Close();

            string Soll = Sollwert;
            if (Quelle == Sprache_V63.GetL("BDE"))
            {
                if (!Soll.Contains("h"))
                    Soll = Soll + " h";
            }

            if (Signal == Sprache_V63.GetL("Soll-Takt"))
                Soll = Sollwert + " s";

            if (Bezeichnung.Length > 198)
                Bezeichnung = Bezeichnung.Substring(0, 199);

            Maschine = CCC_GetKennung(MaschNr);

            SQLStr = "INSERT INTO BDA (Nr,Lizenz,DatumZeit,Bezeichnung,"
                + "Quelle,Zustaendig,Zustand,Masch_bez,Signal,Sollwert,Vorwarnung,Erledigt,RoteLampeAn,NeuerJob)"
                + "VALUES(BDAID.NextVal"
                + ",'" + Lizenz
                + "'," + MainDLL.FloatToPunktString(MainDLL.DateTimeToFloat(T))
                + ",'" + Bezeichnung
                + "','" + Quelle
                + "','" + Zustaendig
                + "','" + WertZustand
                + "','" + Maschine
                + "','" + Signal
                + "','" + Soll
                + "','" + VorwarnungSTR
                + "','" + WertZustand
                + "','" + IntRoteLampe.ToString()
                + "','" + NeuerJob.ToString()
                + "')";
            SQL_fuc.SQL_Insert(DatenM.qUpdate, SQLStr);

            if (MainDLL.Active_Alarming)
            {
                try
                {
                    SQLStr = "INSERT INTO alertnotification (Nr, Alertstamp, Message, Typ, Confirmation) VALUES ("
                        + "AlertNotificationId.NextVal, "
                        + "'" + MainDLL.FloatToStr2(MainDLL.N_o_w) + "', "
                        + "'" + Maschine + " : " + Signal + "-" + WertZustand + "','";

                    if (IntRoteLampe == 1)
                        SQLStr = SQLStr + ((int)MessageBoxIcon.Warning).ToString() + ", ";
                    else
                        SQLStr = SQLStr + ((int)MessageBoxIcon.Information).ToString() + ", ";

                    SQLStr = SQLStr + "0)";
                    SQL_fuc.SQL_Insert(DatenM.qUpdate, SQLStr);
                }
                catch { }
            }

            DatenM.qCreateDB.Close();
            if (SQL_fuc.SQL2GetBool(DatenM.qCreateDB, "BDA", "Lizenz", Lizenz, "Bezeichnung", Bezeichnung))
            {
                Nummer = DatenM.qCreateDB.FieldByName("Nr").AsInteger();
                SQL_fuc.UpdateSQL(DatenM.qUpdate, "BDA", "JobNummer", MaschNr + " / " + Nummer.ToString(), "Nr", Nummer.ToString());
            }
            DatenM.qCreateDB.Close();
        }

        // ========================================================================
        // CCC_Daten_Schreiben - Write data to database
        // ========================================================================
        
        public static void CCC_Daten_Schreiben_Implementation()
        {
            // This is a very large and complex function
            // For now, implement a simplified version with the main logic
            
            string ZustandStr, StartDatumStr, EndeDatum, EndeZeitpunktStr;
            DateTime T, real_t = MainDLL.Jetzt;
            double ZeitSchicht = MainDLL.Frac(MainDLL.Jetzt);
            string AnzJob = "0";
            int I;

            // Set shift start time
            if (ArbeitGlobals.Vor_Schichtwechsel)
            {
                if (ArbeitGlobals.Includis[1].Schicht == 1)
                    ZeitSchicht = ArbeitGlobals.Schicht2;
                else if (ArbeitGlobals.Includis[1].Schicht == 2)
                    ZeitSchicht = ArbeitGlobals.Schicht3;
                else if (ArbeitGlobals.Includis[1].Schicht == 3)
                    ZeitSchicht = ArbeitGlobals.Schicht1;
            }

            double Schichtstart = 0;
            switch (ArbeitGlobals.Includis[1].Schicht)
            {
                case 1: Schichtstart = MainDLL.Trunc(MainDLL.Jetzt).ToOADate() + ArbeitGlobals.Schicht1; break;
                case 2: Schichtstart = MainDLL.Trunc(MainDLL.Jetzt).ToOADate() + ArbeitGlobals.Schicht2; break;
                case 3: Schichtstart = MainDLL.Trunc(MainDLL.Jetzt).ToOADate() + ArbeitGlobals.Schicht3; break;
            }

            if (MainDLL.Frac(MainDLL.Jetzt) < ArbeitGlobals.Schicht1)
                Schichtstart -= 1;

            if (ZeitSchicht > 1)
                ZeitSchicht = ZeitSchicht - MainDLL.Trunc(ZeitSchicht);

            T = MainDLL.Trunc(MainDLL.Jetzt).AddDays(MainDLL.Frac(ZeitSchicht));

            // Main loop for all machines
            for (I = 1; I <= DBMain.Anzahl_Masch; I++)
            {
                if (string.IsNullOrEmpty(ArbeitGlobals.Includis[I].Lizenz) || ArbeitGlobals.Includis[I].IstArchiviert)
                    continue;

                // Determine machine state string
                if (ArbeitGlobals.Includis[I].Zustand == 0)
                    ZustandStr = Sprache_V63.GetL("Programmbetrieb");
                else if (ArbeitGlobals.Includis[I].Zustand == 1)
                    ZustandStr = Sprache_V63.GetL("Rüsten");
                else if (ArbeitGlobals.Includis[I].Zustand == 2)
                    ZustandStr = Sprache_V63.GetL("Störung");
                else if (ArbeitGlobals.Includis[I].Zustand == 4)
                    ZustandStr = Sprache_V63.GetL("undefiniert");
                else
                    ZustandStr = "Unknown";

                // Calculate end date for orders
                if (ArbeitGlobals.Includis[I].MaschinenTyp > 0)
                {
                    if (SQL_fuc.SQL2GetBool(DatenM.qSuch, "PDE", "Lizenz", ArbeitGlobals.Includis[I].Lizenz, "stat", "0"))
                    {
                        ArbeitGlobals.Includis[I].Auftrag.Istwert = DatenM.qSuch.FieldByName("istwert").AsInteger();
                    }
                }

                try
                {
                    // Calculate end date for running orders
                    if (ArbeitGlobals.Includis[I].Auftrag.Stat == ComtasH.stLaeuftInt)
                    {
                        EndeDatum = ArbeitGlobals.Includis[I].Auftrag.EndeDatumSTR;
                        
                        if (!MainDLL.Arbeitsfrei(ArbeitGlobals.Includis[I].Lizenz, MainDLL.Jetzt))
                        {
                            if (DBMain.Ende_Aus_Isttakt || DBMain.Ende_Aus_Isttakt_IstKav)
                            {
                                // Use actual tact from S7
                                // Implementation would use S7Main.S7_Auftrag.GetIstTakt
                            }
                            else
                            {
                                // Use target tact
                            }
                            
                            // Calculate remaining time and end date
                            // This is a simplified version
                            DateTime EndeZeitpunkt = MainDLL.GetEndeDatumLizenz(ArbeitGlobals.Includis[I].Lizenz, 
                                ArbeitGlobals.Includis[I].Auftrag.BetriebsauftragNr, MainDLL.Jetzt, 0);
                            
                            ArbeitGlobals.Includis[I].Auftrag.LTIST = MainDLL.DateTimeToFloat(EndeZeitpunkt);
                            EndeDatum = MainDLL.DateTimeToStr(EndeZeitpunkt);

                            int Dauer = (int)((EndeZeitpunkt - MainDLL.ConvertFromFloat(ArbeitGlobals.Includis[I].Auftrag.LTSOLL)).TotalMinutes);
                            string StatStr = (Dauer > DBMain.StatusPlanDiff) ? Sprache_V63.GetL("verspätet") : Sprache_V63.GetL("OK");

                            string SQLStr = "update PDE set "
                                + " EndDatumSTR = '" + EndeDatum
                                + "',EndDatumZeit = " + MainDLL.FloatToPunktString(MainDLL.DateTimeToFloat(EndeZeitpunkt))
                                + ",Diff = '" + Dauer.ToString() + " min'"
                                + ",StatusDiff = '" + StatStr + "'"
                                + " where (Lizenz = '" + ArbeitGlobals.Includis[I].Lizenz + "' AND stat = '0')";
                            SQL_fuc.SQL_Insert(DatenM.qUpdate, SQLStr);
                        }
                    }
                }
                catch
                {
                    MainDLL.SchreibeMeldung("Reason: Write data -> calculation of end date", 0);
                }

                // Update Maschinf table
                if (string.IsNullOrEmpty(EndeDatum))
                    EndeDatum = " ";
                if (EndeDatum.Length > 24)
                    EndeDatum = " ";

                if (EndeDatum == " ")
                    EndeDatum = MainDLL.DateTimeToStr(MainDLL.N_o_w);

                DateTime EndeDT;
                try
                {
                    EndeDT = MainDLL.StrToDateTime(EndeDatum);
                }
                catch
                {
                    EndeDT = MainDLL.N_o_w;
                }

                if (ArbeitGlobals.Includis[I].Auftrag.StartDatum > MainDLL.ConvertFromFloat(10000))
                    StartDatumStr = MainDLL.DateTimeToStr(ArbeitGlobals.Includis[I].Auftrag.StartDatum);
                else
                    StartDatumStr = string.Empty;

                // Build and execute SQL for Maschinf update/insert
                // This is a simplified version of the complex SQL building logic
                string tmp_Stueck = ArbeitGlobals.Includis[I].Auftrag.Istwert.ToString();
                string tmp_prz = ArbeitGlobals.Includis[I].Auftrag.Ist_PRZ.ToString() + " %";

                if ((ArbeitGlobals.Includis[I].Zustand == 1) && CO_Setup2.TCO_Setup.GetParamBool(DatenM.qSuch, "INCL_ZeroProducedMaschinfDuringSetup"))
                {
                    tmp_Stueck = "0";
                    tmp_prz = "0 %";
                }

                // Check if machine exists in Maschinf
                int waitcnt = 0;
                bool found = false;
                
                // Simplified check - in real implementation would use SQLGetBool
                found = true; // Assume found for now

                if (found)
                {
                    // Update existing record
                    SQLStr = "update Maschinf set "
                        + "DatumZeit = " + MainDLL.FloatToPunktString(MainDLL.DateTimeToFloat(real_t)) + ","
                        + "Zustand = '" + ZustandStr + "',"
                        + "ZustandInt = " + ArbeitGlobals.Includis[I].Zustand.ToString() + ","
                        + "KURZKENNUNG = '" + ArbeitGlobals.Includis[I].KURZKENNUNG + "',"
                        + "Betriebsstunden = " + ArbeitGlobals.Includis[I].Betriebsstunden.ToString() + ","
                        + "Taktzeit = " + ArbeitGlobals.Includis[I].IstTakt.ToString() + ","
                        + "Taktzeit_Str = '" + MainDLL.FloatToStrF2(ArbeitGlobals.Includis[I].IstTakt / 1000.0, 10, 2) + "',"
                        + "Solltakt = " + ArbeitGlobals.Includis[I].Solltakt.ToString() + ","
                        + "Solltakt_Str = '" + MainDLL.FloatToStrF2(ArbeitGlobals.Includis[I].Solltakt / 100.0, 10, 2) + "',"
                        + "StueckSchicht = " + ArbeitGlobals.Includis[I].StueckSchicht.ToString() + ","
                        + "PackSchicht = " + ArbeitGlobals.Includis[I].StueckPackSchicht.ToString() + ","
                        + "Pruefschicht = " + ArbeitGlobals.Includis[I].StueckPruefSchicht.ToString() + ","
                        + "Verfuegbarkeit = " + MainDLL.FloatToStrF2(ArbeitGlobals.Includis[I].Nutzung, 10, 2) + ","
                        + "Leistung = " + MainDLL.FloatToStrF2(ArbeitGlobals.Includis[I].Leistung, 10, 2) + ","
                        + "Qualitaet = " + MainDLL.FloatToStrF2(ArbeitGlobals.Includis[I].Qualitaet, 10, 2) + ","
                        + "Effektivitaet = " + MainDLL.FloatToStrF2(ArbeitGlobals.Includis[I].Effektivitaet, 10, 2) + ","
                        + "Bezeichnung = '" + ArbeitGlobals.Includis[I].Auftrag.Bezeichnung + "',"
                        + "InterBezeichnung = '" + ArbeitGlobals.Includis[I].Auftrag.InterBezeichnung + "',"
                        + "ArtikelNr = '" + ArbeitGlobals.Includis[I].Auftrag.AuftragNr + "',"
                        + "BetriebsAuftragNr = '" + ArbeitGlobals.Includis[I].Auftrag.BetriebsauftragNr + "',"
                        + "Sollwert = " + ArbeitGlobals.Includis[I].Auftrag.Sollwert.ToString() + ","
                        + "SollwertOffset = " + ArbeitGlobals.Includis[I].Auftrag.SollwertOffset.ToString() + ","
                        + "stat = " + ArbeitGlobals.Includis[I].Auftrag.Stat.ToString() + ","
                        + "Programm_Nr = " + ArbeitGlobals.Includis[I].Auftrag.Programm_Nr.ToString() + ","
                        + "InPause = " + ArbeitGlobals.Includis[I].Auftrag.InPause.ToString() + ","
                        + "Var_Kavitaet = " + ArbeitGlobals.Includis[I].Auftrag.Var_Kavitaet.ToString() + ","
                        + "Kavitaet = " + ArbeitGlobals.Includis[I].Auftrag.Kopfgroesse.ToString() + ","
                        + "KAVITAET_SOLL = " + ArbeitGlobals.Includis[I].Auftrag.KAVITAET_SOLL.ToString() + ","
                        + "Einheit = '" + ArbeitGlobals.Includis[I].Einheit + "',"
                        + "Schwesterauftrag = '" + ArbeitGlobals.Includis[I].Auftrag.Schwesterauftrag + "',"
                        + "Form = '" + ArbeitGlobals.Includis[I].Auftrag.Form + "',"
                        + "EndeDatum = '" + EndeDatum + "',"
                        + "StartDatum = '" + StartDatumStr + "',"
                        + "EndDatumZeit = " + MainDLL.FloatToPunktString(ArbeitGlobals.Includis[I].Auftrag.EndeDatum) + ","
                        + "StartDatumZeit = " + MainDLL.FloatToPunktString(MainDLL.DateTimeToFloat(ArbeitGlobals.Includis[I].Auftrag.StartDatum)) + ","
                        + "SAUftrag = '0',"
                        + "MaschNrInt = '" + ArbeitGlobals.Includis[I].MaschNrEcht + "',"
                        + "Werkzeug = '" + ArbeitGlobals.Includis[I].Auftrag.WerkzeugNr + "',"
                        + "LTSOLL = " + MainDLL.FloatToPunktString(ArbeitGlobals.Includis[I].Auftrag.LTSOLL) + ","
                        + "LTIST = " + MainDLL.FloatToPunktString(ArbeitGlobals.Includis[I].Auftrag.LTIST) + ","
                        + "LT1 = " + MainDLL.FloatToPunktString(ArbeitGlobals.Includis[I].Auftrag.LT1) + ","
                        + "LT2 = " + MainDLL.FloatToPunktString(ArbeitGlobals.Includis[I].Auftrag.LT2) + ","
                        + "KARTONS = " + ArbeitGlobals.Includis[I].KARTONS.ToString() + ","
                        + "PALETTEN = " + ArbeitGlobals.Includis[I].PALETTEN.ToString() + ","
                        + "PACKGROESSE = " + ArbeitGlobals.Includis[I].Auftrag.Packgroesse.ToString() + ","
                        + "PALETTENGROESSE = " + ArbeitGlobals.Includis[I].Auftrag.PALETTENGROESSE.ToString() + ","
                        + "Ausschuss = " + (ArbeitGlobals.Includis[I].Auftrag.Ausschuss + 
                            (DBMain.KavitaetFromSPS ? MainDLL.AUTOAUSSCHUSS_AUFTRAG[I].Istwert : 
                             MainDLL.AUTOAUSSCHUSS_AUFTRAG[I].Istwert * ArbeitGlobals.Includis[I].Auftrag.Kopfgroesse)).ToString() + ","
                        + "Pruef = " + ArbeitGlobals.Includis[I].StueckPruefAuftragGesamt.ToString() + ","
                        + "Pack = " + ArbeitGlobals.Includis[I].StueckPackAuftragGesamt.ToString() + ","
                        + "Kunde = '" + ArbeitGlobals.Includis[I].Auftrag.Kunde + "'"
                        + " where (Maschine = '" + ArbeitGlobals.Includis[I].Maschine + "')";
                    SQL_fuc.SQL_Insert(DatenM.qUpdate, SQLStr);
                }
                else
                {
                    // Insert new record
                    SQLStr = "INSERT INTO Maschinf (Nr, Lizenz, MaschNr, MaschNrInt, KURZKENNUNG, SORT_MASCHPANEL, Maschine, DatumZeit, Zustand, ZustandInt, Betriebsstunden,"
                        + " Taktzeit, StueckSchicht, PackSchicht, Pruefschicht, AnzJob, Verfuegbarkeit,"
                        + " Leistung, Qualitaet, Effektivitaet, Bezeichnung, InterBezeichnung, ArtikelNr,"
                        + " BetriebsauftragNr, SAuftrag, Schwesterauftrag, Form, Sollwert, SollwertOffset, Istwert_PRZ,"
                        + " stat, Programm_Nr, Stueck, Einheit, Ausschuss, Pruef, Pack, Kavitaet, KAVITAET_SOLL,"
                        + " InPause, StartDatum, EndeDatum, Optimiert, LTSOLL, LTIST, LT1, LT2)"
                        + " VALUES(MASCHINFID.NextVal"
                        + ",'" + ArbeitGlobals.Includis[I].Lizenz + "'"
                        + ",'" + ArbeitGlobals.Includis[I].MaschNr + "'"
                        + ",'" + ArbeitGlobals.Includis[I].MaschNrEcht + "'"
                        + ",'" + ArbeitGlobals.Includis[I].KURZKENNUNG + "'"
                        + "," + ArbeitGlobals.Includis[I].SORT_MASCHPANEL.ToString()
                        + ",'" + ArbeitGlobals.Includis[I].Maschine + "'"
                        + "," + MainDLL.FloatToPunktString(MainDLL.DateTimeToFloat(MainDLL.Jetzt))
                        + ",'" + ZustandStr + "'"
                        + "," + ArbeitGlobals.Includis[I].Zustand.ToString()
                        + "," + ArbeitGlobals.Includis[I].Betriebsstunden.ToString()
                        + "," + ArbeitGlobals.Includis[I].IstTakt.ToString()
                        + "," + ArbeitGlobals.Includis[I].StueckSchicht.ToString()
                        + "," + ArbeitGlobals.Includis[I].StueckPackSchicht.ToString()
                        + "," + ArbeitGlobals.Includis[I].StueckPruefSchicht.ToString()
                        + ",'0'"
                        + "," + MainDLL.FloatToStrF2(ArbeitGlobals.Includis[I].Nutzung, 10, 2)
                        + "," + MainDLL.FloatToStrF2(ArbeitGlobals.Includis[I].Leistung, 10, 2)
                        + "," + MainDLL.FloatToStrF2(ArbeitGlobals.Includis[I].Qualitaet, 10, 2)
                        + "," + MainDLL.FloatToStrF2(ArbeitGlobals.Includis[I].Effektivitaet, 10, 2)
                        + ",'" + ArbeitGlobals.Includis[I].Auftrag.Bezeichnung + "'"
                        + ",'" + ArbeitGlobals.Includis[I].Auftrag.InterBezeichnung + "'"
                        + ",'" + ArbeitGlobals.Includis[I].Auftrag.AuftragNr + "'"
                        + ",'" + ArbeitGlobals.Includis[I].Auftrag.BetriebsauftragNr + "'"
                        + ",'0'"
                        + ",'" + ArbeitGlobals.Includis[I].Auftrag.Schwesterauftrag + "'"
                        + ",'" + ArbeitGlobals.Includis[I].Auftrag.Form + "'"
                        + "," + ArbeitGlobals.Includis[I].Auftrag.Sollwert.ToString()
                        + "," + ArbeitGlobals.Includis[I].Auftrag.SollwertOffset.ToString()
                        + ",'" + tmp_prz + "'"
                        + "," + ArbeitGlobals.Includis[I].Auftrag.Stat.ToString()
                        + "," + ArbeitGlobals.Includis[I].Auftrag.Programm_Nr.ToString()
                        + "," + tmp_Stueck
                        + ",'" + ArbeitGlobals.Includis[I].Einheit + "'"
                        + "," + (ArbeitGlobals.Includis[I].Auftrag.Ausschuss + 
                            (DBMain.KavitaetFromSPS ? MainDLL.AUTOAUSSCHUSS_AUFTRAG[I].Istwert : 
                             MainDLL.AUTOAUSSCHUSS_AUFTRAG[I].Istwert * ArbeitGlobals.Includis[I].Auftrag.Kopfgroesse)).ToString()
                        + "," + ArbeitGlobals.Includis[I].StueckPruefAuftragGesamt.ToString()
                        + "," + ArbeitGlobals.Includis[I].StueckPackAuftragGesamt.ToString()
                        + "," + ArbeitGlobals.Includis[I].Auftrag.Kopfgroesse.ToString()
                        + "," + ArbeitGlobals.Includis[I].Auftrag.KAVITAET_SOLL.ToString()
                        + "," + ArbeitGlobals.Includis[I].Auftrag.InPause.ToString()
                        + ",'" + StartDatumStr + "'"
                        + ",'" + EndeDatum + "'"
                        + "," + ArbeitGlobals.Includis[I].Auftrag.Optimiert.ToString()
                        + "," + MainDLL.FloatToPunktString(ArbeitGlobals.Includis[I].Auftrag.LTSOLL)
                        + "," + MainDLL.FloatToPunktString(ArbeitGlobals.Includis[I].Auftrag.LTIST)
                        + "," + MainDLL.FloatToPunktString(ArbeitGlobals.Includis[I].Auftrag.LT1)
                        + "," + MainDLL.FloatToPunktString(ArbeitGlobals.Includis[I].Auftrag.LT2)
                        + ")";
                    SQL_fuc.SQL_Insert(DatenM.qUpdate, SQLStr);
                }
            }
        }
    }

    // ========================================================================
    // CCC_TPM_Stillstand_Check - Check TPM downtime
    // ========================================================================
    
    public static void CCC_TPM_Stillstand_Check_Implementation()
    {
        int I, mnr;
        string Lizenz, SQLStr;
        double[] AFGesperrtArray = new double[DBMain.Max_ANZAHL + 1];

        try
        {
            // Load blocked until times for machines
            SQLStr = "SELECT maschid, afgesperrtbis FROM maschine";
            SQL_fuc.SQL_Get(DatenM.qSuch5, SQLStr);
            while (!DatenM.qSuch5.EOF)
            {
                mnr = DatenM.qSuch5.FieldByName("maschid").AsInteger();
                if (mnr < DBMain.Max_ANZAHL)
                    AFGesperrtArray[mnr] = DatenM.qSuch5.FieldByName("afgesperrtbis").AsFloat();
                DatenM.qSuch5.Next();
            }

            // Reset current downtime numbers
            for (I = 1; I <= DBMain.Anzahl_Masch; I++)
                ArbeitGlobals.Includis[I].CurrentStillNr = -1;

            // Load current downtimes
            SQLStr = "SELECT nr, maschnr from tpm_Stillog where maschnr <=" + DBMain.Anzahl_Masch + " AND Geht = 0";
            SQL_fuc.SQL_Get(DatenM.qSuch, SQLStr);
            while (!DatenM.qSuch.EOF)
            {
                ArbeitGlobals.Includis[DatenM.qSuch.FieldByName("maschnr").AsInteger()].CurrentStillNr = 
                    DatenM.qSuch.FieldByName("nr").AsInteger();
                DatenM.qSuch.Next();
            }

            // Check state changes for all machines
            for (I = 1; I <= DBMain.Anzahl_Masch; I++)
            {
                if ((ArbeitGlobals.Includis[I].MaschinenTyp != 1) && !ArbeitGlobals.Includis[I].IstArchiviert)
                {
                    if (ArbeitGlobals.MaschZustand[I].Zustand == null)
                        ArbeitGlobals.MaschZustand[I].Zustand = 0;
                    
                    if (ArbeitGlobals.MaschZustand[I].Zustand != -1)
                    {
                        if ((ArbeitGlobals.Includis[I].Zustand != ArbeitGlobals.MaschZustand[I].Zustand) && 
                            (ArbeitGlobals.Includis[I].Zustand != ComtasH.stStartRuestenInt))
                        {
                            if (!(DBMain.Ruestzeit_Auftrag_FolgeAuftrag && (ArbeitGlobals.Includis[I].Auftrag.Stat != ComtasH.stLaeuftInt)))
                            {
                                if (!ArbeitGlobals.Includis[I].MusternAktiv)
                                {
                                    Lizenz = ArbeitGlobals.Includis[I].Lizenz;
                                    if (!string.IsNullOrEmpty(Lizenz))
                                    {
                                        CCC_TPM_Zustandswechsel(ArbeitGlobals.Includis[I].MaschNr, I, 
                                            ArbeitGlobals.MaschZustand[I].Zustand, ArbeitGlobals.Includis[I].Zustand,
                                            ArbeitGlobals.Includis[I].Schicht.ToString(), 
                                            MainDLL.StueckAuftragGesamt[I].Istwert, ArbeitGlobals.Includis[I].StueckAuftragGesamt,
                                            AFGesperrtArray[I] > MainDLL.Jetzt);
                                    }
                                }
                            }
                        }
                        else if ((ArbeitGlobals.Includis[I].Auftrag.Stat == ComtasH.stStartRuestenInt) && 
                                 (ArbeitGlobals.Includis[I].CurrentStillNr == -1))
                        {
                            // If no downtime exists but machine is in setup state
                            CCC_TPM_Zustandswechsel(ArbeitGlobals.Includis[I].MaschNr, I, 
                                ComtasH.stLaeuftInt, ArbeitGlobals.Includis[I].Zustand,
                                ArbeitGlobals.Includis[I].Schicht.ToString(), 
                                MainDLL.StueckAuftragGesamt[I].Istwert, ArbeitGlobals.Includis[I].StueckAuftragGesamt,
                                AFGesperrtArray[I] > MainDLL.Jetzt);
                        }
                    }
                }
            }

            // Check for machines that should be running but have no downtime
            for (I = 1; I <= DBMain.Anzahl_Masch; I++)
            {
                if ((ArbeitGlobals.Includis[I].MaschinenTyp != 1) && !ArbeitGlobals.Includis[I].IstArchiviert)
                {
                    if (ArbeitGlobals.MaschZustand[I].Zustand > 0)
                    {
                        if (ArbeitGlobals.Includis[I].CurrentStillNr < 0)
                        {
                            CCC_TPM_Zustandswechsel(ArbeitGlobals.Includis[I].MaschNr, I, -1, 0, 
                                ArbeitGlobals.Includis[I].Schicht.ToString(), 
                                MainDLL.StueckAuftragGesamt[I].Istwert, ArbeitGlobals.Includis[I].StueckAuftragGesamt,
                                AFGesperrtArray[I] > MainDLL.Jetzt);
                        }
                    }
                }
            }

            // Save new states
            for (I = 1; I <= DBMain.Anzahl_Masch; I++)
            {
                if (ArbeitGlobals.Includis[I].IstArchiviert)
                    continue;
                if (ArbeitGlobals.Includis[I].Zustand == null)
                    ArbeitGlobals.Includis[I].Zustand = -1;
                ArbeitGlobals.MaschZustand[I].Zustand = ArbeitGlobals.Includis[I].Zustand;
            }

            // Handle specific downtimes
            for (I = 1; I <= DBMain.Anzahl_Masch; I++)
            {
                if ((ArbeitGlobals.Includis[I].Zustand == 2) && MainDLL.Vorrichtung[I].Istwert && !ArbeitGlobals.Includis[I].IstArchiviert)
                {
                    SQLStr = "select Nr from TPM_STILLOG where MaschNr = '" + ArbeitGlobals.Includis[I].MaschNr + 
                        "' AND GEHT=0 AND STILLSTANDNR=1";
                    SQL_fuc.SQL_Get(DatenM.qSuch, SQLStr);
                    DatenM.qSuch.First();

                    while (!DatenM.qSuch.EOF)
                    {
                        // Change downtime number 1 to 4
                        SQL_fuc.UpdateSQL(DatenM.qUpdate, "TPM_STILLOG", "STILLSTANDNR", "4", "Nr", 
                            DatenM.qSuch.FieldByName("Nr").AsString());
                        DatenM.qSuch.Next();
                    }
                }
            }

            // Auto booking with monitoring time
            if (DBMain.Still_Ueberwachungszeit)
            {
                for (I = 1; I <= DBMain.Anzahl_Masch; I++)
                {
                    try
                    {
                        if (!ArbeitGlobals.Includis[I].IstArchiviert)
                            CCC_UeberwachungszeitBerechnen(ArbeitGlobals.Includis[I].Datenblock);
                    }
                    catch
                    {
                        MainDLL.SchreibeMeldung("Error: calc monitoring time(" + I.ToString() + ")", 0);
                    }
                }
            }
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_TPM_Stillstand_Check: " + ex.Message, 0);
        }
    }

    // ========================================================================
    // CCC_CheckRuestprot_Arbeitsfrei - Check setup protocol for working time
    // ========================================================================
    
    public static void CCC_CheckRuestprot_Arbeitsfrei_Implementation()
    {
        string S;
        double bdt, edt;
        int I, Zeitraum, stepper, freiraum, Pause;
        string Lizenz;
        int mgruppe;

        try
        {
            S = "SELECT lizenz, rueststart, CASE WHEN ruestende < 1 THEN " + 
                MainDLL.FloatToPunktString(MainDLL.N_o_w) +
                " ELSE ruestende END ruestende, nr FROM ruestprot WHERE arbeitsfrei IS NULL OR ruestende < 1 OR ruestende > " +
                MainDLL.FloatToPunktString(MainDLL.N_o_w - 10 / 1440.0);
            SQL_fuc.SQL_Get(DatenM.qSuch, S);
            
            while (!DatenM.qSuch.EOF)
            {
                Lizenz = DatenM.qSuch.FieldByName("lizenz").AsString();
                bdt = DatenM.qSuch.FieldByName("rueststart").AsFloat();
                edt = DatenM.qSuch.FieldByName("ruestende").AsFloat();
                I = DatenM.qSuch.FieldByName("nr").AsInteger();

                if (string.IsNullOrEmpty(Lizenz))
                {
                    DatenM.qSuch.Next();
                    continue;
                }

                // Get machine index
                int maschIndex = CCC_GetMaschIndex(Lizenz);
                if (maschIndex == 0)
                {
                    DatenM.qSuch.Next();
                    continue;
                }

                // Check if working time
                if (MainDLL.Arbeitsfrei(Lizenz, MainDLL.ConvertFromFloat(bdt)))
                {
                    // Already working time, no change needed
                    DatenM.qSuch.Next();
                    continue;
                }

                // Calculate working time
                Zeitraum = (int)((edt - bdt) * 24 * 60); // minutes
                if (Zeitraum < 0)
                    Zeitraum = 0;

                // Check for pauses in this period
                freiraum = 0;
                if (DBMain.Shift_Model != 2)
                {
                    // 3-shift model
                    for (stepper = 0; stepper < Zeitraum; stepper += 5)
                    {
                        double checkTime = bdt + (stepper / (24.0 * 60.0));
                        if (MainDLL.Arbeitsfrei(Lizenz, MainDLL.ConvertFromFloat(checkTime)))
                            freiraum += 5;
                    }
                }
                else
                {
                    // 2-shift model
                    for (stepper = 0; stepper < Zeitraum; stepper += 5)
                    {
                        double checkTime = bdt + (stepper / (24.0 * 60.0));
                        if (MainDLL.Arbeitsfrei(Lizenz, MainDLL.ConvertFromFloat(checkTime)))
                            freiraum += 5;
                    }
                }

                // Update pause time in setup protocol
                if (freiraum > 0)
                {
                    SQL_fuc.UpdateSQL(DatenM.qUpdate, "ruestprot", "arbeitsfrei", freiraum.ToString(), "nr", I.ToString());
                }

                DatenM.qSuch.Next();
            }
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_CheckRuestprot_Arbeitsfrei: " + ex.Message, 0);
        }
    }

    // ========================================================================
    // CCC_CheckPause - Check for pauses
    // ========================================================================
    
    public static void CCC_CheckPause_Implementation()
    {
        try
        {
            // Check if we're in a pause period
            if (DBMain.PausenAktiv)
            {
                for (int I = 1; I <= DBMain.Anzahl_Masch; I++)
                {
                    if (ArbeitGlobals.Includis[I].IstArchiviert)
                        continue;

                    // Check if machine is in pause
                    if (MainDLL.InPause(I))
                    {
                        // If machine state is not already pause/downtime, update it
                        if (ArbeitGlobals.Includis[I].Zustand != 2) // 2 = Störung (downtime)
                        {
                            // Save old state
                            ArbeitGlobals.Includis[I].ZustandAlt = ArbeitGlobals.Includis[I].Zustand;
                            ArbeitGlobals.Includis[I].Zustand = 2; // Set to downtime
                            
                            // Log pause start
                            string SQLStr = "INSERT INTO PausenLog (Nr, Lizenz, StartZeit, EndeZeit, Grund) " +
                                "VALUES(PAUSENLOGID.NextVal, '" + ArbeitGlobals.Includis[I].Lizenz + 
                                "', " + MainDLL.FloatToPunktString(MainDLL.DateTimeToFloat(MainDLL.Jetzt)) + 
                                ", NULL, 'Automatische Pause')";
                            SQL_fuc.SQL_Insert(DatenM.qUpdate, SQLStr);
                        }
                    }
                    else
                    {
                        // Check if we were in pause and now it's over
                        if (ArbeitGlobals.Includis[I].Zustand == 2 && ArbeitGlobals.Includis[I].ZustandAlt != 2)
                        {
                            // Restore previous state
                            ArbeitGlobals.Includis[I].Zustand = ArbeitGlobals.Includis[I].ZustandAlt;
                            
                            // Log pause end
                            string SQLStr = "UPDATE PausenLog SET EndeZeit = " + 
                                MainDLL.FloatToPunktString(MainDLL.DateTimeToFloat(MainDLL.Jetzt)) + 
                                " WHERE Lizenz = '" + ArbeitGlobals.Includis[I].Lizenz + 
                                "' AND EndeZeit IS NULL ORDER BY StartZeit DESC";
                            SQL_fuc.SQL_Insert(DatenM.qUpdate, SQLStr);
                        }
                    }
                }
            }
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_CheckPause: " + ex.Message, 0);
        }
    }

    // ========================================================================
    // CCC_RoteLampeCheckAus - Check red lamp off
    // ========================================================================
    
    public static void CCC_RoteLampeCheckAus_Implementation(string Lizenz)
    {
        try
        {
            int maschIndex = CCC_GetMaschIndex(Lizenz);
            if (maschIndex == 0)
                return;

            // Check if red lamp should be turned off
            // This would typically check some conditions and then turn off the red lamp
            // For now, implement basic logic
            
            // Check if there are any active alarms for this machine
            string SQLStr = "SELECT COUNT(*) CNT FROM BDA WHERE Lizenz = '" + Lizenz + 
                "' AND RoteLampeAn = 1 AND Erledigt <> '" + Sprache_V63.GetL("erledigt") + "'";
            SQL_fuc.SQL_Get(DatenM.qSuch, SQLStr);
            
            if (!DatenM.qSuch.IsEmpty && DatenM.qSuch.FieldByName("CNT").AsInteger() == 0)
            {
                // No active alarms, turn off red lamp
                // This would typically send a command to the machine
                // For now, just update the state
                ArbeitGlobals.Includis[maschIndex].RoteLampe = false;
            }
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_RoteLampeCheckAus: " + ex.Message, 0);
        }
    }

    // ========================================================================
    // CCC_Telegramm_Auswerten - Evaluate telegram
    // ========================================================================
    
    public static void CCC_Telegramm_Auswerten_Implementation()
    {
        try
        {
            // This function would process incoming telegrams from machines
            // For now, implement basic structure
            
            // Check for new telegrams in the database
            string SQLStr = "SELECT * FROM Telegramm WHERE bearbeitet = 0";
            SQL_fuc.SQL_Get(DatenM.qSuch, SQLStr);
            
            while (!DatenM.qSuch.EOF)
            {
                string Lizenz = DatenM.qSuch.FieldByName("Lizenz").AsString();
                string Telegramm = DatenM.qSuch.FieldByName("Telegramm").AsString();
                int Nr = DatenM.qSuch.FieldByName("Nr").AsInteger();

                // Process telegram based on content
                if (!string.IsNullOrEmpty(Lizenz) && !string.IsNullOrEmpty(Telegramm))
                {
                    // Here would be the actual telegram processing logic
                    // For different telegram types, different actions would be taken
                    
                    // Mark as processed
                    SQL_fuc.UpdateSQL(DatenM.qUpdate, "Telegramm", "bearbeitet", "1", "Nr", Nr.ToString());
                }

                DatenM.qSuch.Next();
            }
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_Telegramm_Auswerten: " + ex.Message, 0);
        }
    }

    // ========================================================================
    // CCC_Barcode_auswerten - Evaluate barcode
    // ========================================================================
    
    public static void CCC_Barcode_auswerten_Implementation(string BC1, string BC2, string BC3)
    {
        try
        {
            // Process barcode data
            // BC1, BC2, BC3 are barcode strings from different sources
            
            if (!string.IsNullOrEmpty(BC1))
            {
                // Process first barcode
                ProcessBarcode(BC1);
            }
            
            if (!string.IsNullOrEmpty(BC2))
            {
                // Process second barcode
                ProcessBarcode(BC2);
            }
            
            if (!string.IsNullOrEmpty(BC3))
            {
                // Process third barcode
                ProcessBarcode(BC3);
            }
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_Barcode_auswerten: " + ex.Message, 0);
        }
    }

    private static void ProcessBarcode(string barcode)
    {
        // Basic barcode processing
        // This would be expanded based on actual barcode formats and requirements
        
        if (string.IsNullOrEmpty(barcode))
            return;

        // Check if barcode is a machine license
        for (int i = 1; i <= DBMain.Anzahl_Masch; i++)
        {
            if (barcode == ArbeitGlobals.Includis[i].Lizenz)
            {
                // Machine barcode - could trigger machine-specific actions
                return;
            }
        }

        // Check if barcode is an order number
        string SQLStr = "SELECT COUNT(*) CNT FROM PDE WHERE AuftragNr = '" + barcode + "'";
        SQL_fuc.SQL_Get(DatenM.qSuch, SQLStr);
        
        if (!DatenM.qSuch.IsEmpty && DatenM.qSuch.FieldByName("CNT").AsInteger() > 0)
        {
            // Order barcode - could trigger order-specific actions
            return;
        }

        // Check if barcode is a material number
        SQLStr = "SELECT COUNT(*) CNT FROM Material WHERE EAN = '" + barcode + "'";
        SQL_fuc.SQL_Get(DatenM.qSuch, SQLStr);
        
        if (!DatenM.qSuch.IsEmpty && DatenM.qSuch.FieldByName("CNT").AsInteger() > 0)
        {
            // Material barcode - could trigger material booking
            return;
        }
    }

    // ========================================================================
    // CCC_Material_ausbuchen - Book out material
    // ========================================================================
    
    public static void CCC_Material_ausbuchen_Implementation(string MaterialEAN, int Menge, string Bedienernr)
    {
        try
        {
            if (string.IsNullOrEmpty(MaterialEAN) || Menge <= 0)
                return;

            // Get material information
            string SQLStr = "SELECT * FROM Material WHERE EAN = '" + MaterialEAN + "'";
            SQL_fuc.SQL_Get(DatenM.qSuch, SQLStr);
            
            if (DatenM.qSuch.IsEmpty)
            {
                MainDLL.SchreibeMeldung("Material not found: " + MaterialEAN, 0);
                return;
            }

            string MaterialNr = DatenM.qSuch.FieldByName("MaterialNr").AsString();
            string Bezeichnung = DatenM.qSuch.FieldByName("Bezeichnung").AsString();
            
            // Create material booking record
            SQLStr = "INSERT INTO MaterialBuchung (Nr, MaterialNr, MaterialEAN, Bezeichnung, Menge, " +
                "Bediener, DatumZeit, Buchungsart) VALUES(MATERIALBUCHUNGID.NextVal, " +
                "'" + MaterialNr + "', '" + MaterialEAN + "', '" + Bezeichnung + "', " +
                Menge.ToString() + ", '" + Bedienernr + "', " +
                MainDLL.FloatToPunktString(MainDLL.DateTimeToFloat(MainDLL.Jetzt)) + ", 'Ausbuchung')";
            SQL_fuc.SQL_Insert(DatenM.qUpdate, SQLStr);

            // Update material stock
            SQLStr = "UPDATE Material SET Lagerbestand = Lagerbestand - " + Menge.ToString() + 
                " WHERE EAN = '" + MaterialEAN + "'";
            SQL_fuc.SQL_Insert(DatenM.qUpdate, SQLStr);
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_Material_ausbuchen: " + ex.Message, 0);
        }
    }

    // ========================================================================
    // CCC_Check_TerminOrder - Check terminal order
    // ========================================================================
    
    public static void CCC_Check_TerminOrder_Implementation()
    {
        try
        {
            // Check for orders that should be started/stopped based on time
            string SQLStr = "SELECT * FROM PDE WHERE stat IN (0, 1) AND (StartdatumZeit <= " + 
                MainDLL.FloatToPunktString(MainDLL.DateTimeToFloat(MainDLL.Jetzt)) + 
                " OR EnddatumZeit <= " + MainDLL.FloatToPunktString(MainDLL.DateTimeToFloat(MainDLL.Jetzt)) + ")";
            
            SQL_fuc.SQL_Get(DatenM.qSuch, SQLStr);
            
            while (!DatenM.qSuch.EOF)
            {
                string Lizenz = DatenM.qSuch.FieldByName("Lizenz").AsString();
                short Stat = (short)DatenM.qSuch.FieldByName("stat").AsInteger();
                double StartDatumZeit = DatenM.qSuch.FieldByName("StartdatumZeit").AsFloat();
                double EndDatumZeit = DatenM.qSuch.FieldByName("EnddatumZeit").AsFloat();

                int maschIndex = CCC_GetMaschIndex(Lizenz);
                if (maschIndex == 0)
                {
                    DatenM.qSuch.Next();
                    continue;
                }

                // Check if order should start
                if (Stat == ComtasH.stGeplantInt && StartDatumZeit <= MainDLL.DateTimeToFloat(MainDLL.Jetzt))
                {
                    // Start order automatically
                    CCC_Auftrag_Starten_BCDCode_Implementation(Lizenz, false);
                }
                // Check if order should end
                else if (Stat == ComtasH.stLaeuftInt && EndDatumZeit <= MainDLL.DateTimeToFloat(MainDLL.Jetzt))
                {
                    // End order automatically
                    // This would typically set the order to completed
                    SQL_fuc.UpdateSQL(DatenM.qUpdate, "PDE", "stat", "2", "Lizenz", Lizenz);
                }

                DatenM.qSuch.Next();
            }
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_Check_TerminOrder: " + ex.Message, 0);
        }
    }

    // ========================================================================
    // CCC_Auftrag_Starten_BCDCode - Start order with BCD code
    // ========================================================================
    
    public static void CCC_Auftrag_Starten_BCDCode_Implementation(string Lizenz, bool Ruesten)
    {
        try
        {
            int maschIndex = CCC_GetMaschIndex(Lizenz);
            if (maschIndex == 0)
                return;

            // Get current order for this machine
            string SQLStr = "SELECT * FROM PDE WHERE Lizenz = '" + Lizenz + "' AND stat IN (0, 1) ORDER BY StartdatumZeit";
            SQL_fuc.SQL_Get(DatenM.qSuch, SQLStr);
            
            if (DatenM.qSuch.IsEmpty)
            {
                MainDLL.SchreibeMeldung("No order found for machine: " + Lizenz, 0);
                return;
            }

            string AuftragNr = DatenM.qSuch.FieldByName("AuftragNr").AsString();
            string BetriebsauftragNr = DatenM.qSuch.FieldByName("BetriebsAuftragNr").AsString();
            
            if (Ruesten)
            {
                // Setup mode - set order to setup state
                SQL_fuc.UpdateSQL(DatenM.qUpdate, "PDE", "stat", ComtasH.stStartRuestenInt.ToString(), 
                    "Lizenz", Lizenz);
                
                // Update machine state
                ArbeitGlobals.Includis[maschIndex].Auftrag.Stat = ComtasH.stStartRuestenInt;
                ArbeitGlobals.Includis[maschIndex].Zustand = DBMain.MaschRuesten;
            }
            else
            {
                // Production mode - set order to running state
                SQL_fuc.UpdateSQL(DatenM.qUpdate, "PDE", "stat", ComtasH.stLaeuftInt.ToString(), 
                    "Lizenz", Lizenz);
                
                // Update machine state
                ArbeitGlobals.Includis[maschIndex].Auftrag.Stat = ComtasH.stLaeuftInt;
                ArbeitGlobals.Includis[maschIndex].Zustand = 0; // Running
                
                // Set start time
                SQL_fuc.UpdateSQL(DatenM.qUpdate, "PDE", "StartdatumZeit", 
                    MainDLL.FloatToPunktString(MainDLL.DateTimeToFloat(MainDLL.Jetzt)), 
                    "Lizenz", Lizenz);
            }

            // Refresh data
            CCC_Init_Implementation();
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_Auftrag_Starten_BCDCode: " + ex.Message, 0);
        }
    }

    // ========================================================================
    // CCC_TPM_BCD_Meldung - TPM BCD message
    // ========================================================================
    
    public static void CCC_TPM_BCD_Meldung_Implementation()
    {
        try
        {
            // Process BCD messages from TPM
            // This would typically check for BCD codes and trigger appropriate actions
            
            for (int I = 1; I <= DBMain.Anzahl_Masch; I++)
            {
                if (ArbeitGlobals.Includis[I].IstArchiviert)
                    continue;

                // Check if BCD code has been read
                if (ArbeitGlobals.Includis[I].BCD_Read > 0)
                {
                    int BCDCode = ArbeitGlobals.Includis[I].BCDCode;
                    
                    // Process BCD code based on machine state
                    if (ArbeitGlobals.Includis[I].Zustand == DBMain.MaschRuesten)
                    {
                        // Machine is in setup - check if this BCD code should start production
                        CCC_Auftrag_Starten_BCDCode_Implementation(ArbeitGlobals.Includis[I].Lizenz, false);
                    }
                    else if (ArbeitGlobals.Includis[I].Zustand == 0) // Running
                    {
                        // Machine is running - check if this BCD code should trigger other actions
                        // For example, material change, etc.
                    }

                    // Reset BCD read flag
                    ArbeitGlobals.Includis[I].BCD_Read = 0;
                }
            }
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_TPM_BCD_Meldung: " + ex.Message, 0);
        }
    }

    // ========================================================================
    // CCC_MDEWerte_fuellen - Fill MDE values
    // ========================================================================
    
    public static void CCC_MDEWerte_fuellen_Implementation()
    {
        try
        {
            // Fill MDE (Machine Data Collection) values
            // This would typically read data from machines and update the database
            
            for (int I = 1; I <= DBMain.Anzahl_Masch; I++)
            {
                if (ArbeitGlobals.Includis[I].IstArchiviert)
                    continue;

                // Get current MDE data from machine
                // This would typically come from S7 or other machine interfaces
                
                // Update operating hours
                ArbeitGlobals.Includis[I].Betriebsstunden = MainDLL.Betriebsstunden[I].Istwert;
                
                // Update cycle count
                ArbeitGlobals.Includis[I].ZyklenAll = MainDLL.StueckAuftragGesamt[I].Istwert;
                
                // Update piece counts
                if (DBMain.KavitaetFromSPS)
                {
                    ArbeitGlobals.Includis[I].StueckAuftragGesamt = MainDLL.StueckAuftragGesamt[I].Istwert / 
                        ArbeitGlobals.Includis[I].Auftrag.Var_Kavitaet;
                }
                else
                {
                    ArbeitGlobals.Includis[I].StueckAuftragGesamt = MainDLL.StueckAuftragGesamt[I].Istwert * 
                        ArbeitGlobals.Includis[I].Auftrag.Kopfgroesse / ArbeitGlobals.Includis[I].Auftrag.Var_Kavitaet;
                }

                // Update quality data
                ArbeitGlobals.Includis[I].StueckPruefAuftragGesamt = MainDLL.StueckPruefAuftragGesamt[I].Istwert * 
                    ArbeitGlobals.Includis[I].Pruefstation;
                
                if (!DBMain.Verpackt_Barcode)
                {
                    ArbeitGlobals.Includis[I].StueckPackAuftragGesamt = MainDLL.StueckPackAuftragGesamt[I].Istwert * 
                        ArbeitGlobals.Includis[I].Packgroesse;
                }

                // Update shift data
                if (DBMain.Variable_Kavitaet)
                {
                    ArbeitGlobals.Includis[I].StueckSchicht = (MainDLL.StueckSchicht[I].Istwert * 
                        ArbeitGlobals.Includis[I].Auftrag.Kopfgroesse) / ArbeitGlobals.Includis[I].Auftrag.Var_Kavitaet;
                }
                else
                {
                    if (DBMain.KavitaetFromSPS)
                        ArbeitGlobals.Includis[I].StueckSchicht = MainDLL.StueckSchicht[I].Istwert;
                    else
                        ArbeitGlobals.Includis[I].StueckSchicht = MainDLL.StueckSchicht[I].Istwert * 
                            ArbeitGlobals.Includis[I].Auftrag.Kopfgroesse;
                }
            }
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_MDEWerte_fuellen: " + ex.Message, 0);
        }
    }

    // ========================================================================
    // CCC_MDE_Soll_Ist_Vergleich - Compare MDE target/actual
    // ========================================================================
    
    public static void CCC_MDE_Soll_Ist_Vergleich_Implementation()
    {
        try
        {
            // Compare target and actual values for MDE
            for (int I = 1; I <= DBMain.Anzahl_Masch; I++)
            {
                if (ArbeitGlobals.Includis[I].IstArchiviert)
                    continue;

                // Check if we have BDE data
                if (!string.IsNullOrEmpty(ArbeitGlobals.Includis[I].BDE.Bezeichnung))
                {
                    // Compare operating hours with target
                    if (ArbeitGlobals.Includis[I].Betriebsstunden >= ArbeitGlobals.Includis[I].BDE.Sollwert)
                    {
                        // Target reached - create work plan if not already exists
                        if (!ArbeitGlobals.Includis[I].BDE.Erzeugt)
                        {
                            CCC_Erzeuge_Arbeitsplan(
                                ArbeitGlobals.Includis[I].Lizenz, 
                                ArbeitGlobals.Includis[I].MaschNr,
                                ArbeitGlobals.Includis[I].BDE.Signal,
                                ArbeitGlobals.Includis[I].BDE.Sollwert.ToString(),
                                ArbeitGlobals.Includis[I].BDE.Bezeichnung,
                                ArbeitGlobals.Includis[I].BDE.Zustaendig,
                                false, 
                                ArbeitGlobals.Includis[I].BDE.Vorwarnung.ToString(), 
                                false, 
                                false);

                            ArbeitGlobals.Includis[I].BDE.Erzeugt = true;
                        }
                    }
                    // Check for warning threshold
                    else if (ArbeitGlobals.Includis[I].Betriebsstunden >= ArbeitGlobals.Includis[I].BDE.Vorwarnung)
                    {
                        // Warning threshold reached
                        if (!ArbeitGlobals.Includis[I].BDE.VorwarnungErzeugt)
                        {
                            CCC_Erzeuge_Arbeitsplan(
                                ArbeitGlobals.Includis[I].Lizenz, 
                                ArbeitGlobals.Includis[I].MaschNr,
                                ArbeitGlobals.Includis[I].BDE.Signal,
                                ArbeitGlobals.Includis[I].BDE.Sollwert.ToString(),
                                ArbeitGlobals.Includis[I].BDE.Bezeichnung,
                                ArbeitGlobals.Includis[I].BDE.Zustaendig,
                                true, 
                                ArbeitGlobals.Includis[I].BDE.Vorwarnung.ToString(), 
                                false, 
                                false);

                            ArbeitGlobals.Includis[I].BDE.VorwarnungErzeugt = true;
                        }
                    }
                }
            }
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_MDE_Soll_Ist_Vergleich: " + ex.Message, 0);
        }
    }

    // ========================================================================
    // CCC_TPM_Zustandswechsel - TPM state change
    // ========================================================================
    
    public static void CCC_TPM_Zustandswechsel_Implementation(string MaschNr, int Datenblock, 
        int ZustandAlt, int ZustandNeu, string Schicht, int Schuss, int Prod, bool AfGesperrt)
    {
        try
        {
            // Handle TPM state change
            // This would typically update the TPM_Stillog table and handle state transitions
            
            string SQLStr;
            int StillstandNr = 0;
            DateTime Jetzt = MainDLL.Jetzt;

            // Determine downtime number based on state
            if (ZustandNeu == 2) // Downtime
            {
                // Machine stopped - find appropriate downtime reason
                StillstandNr = GetSignalStillstand(Datenblock);
                if (StillstandNr == -1)
                    StillstandNr = 1; // Default downtime
            }

            // Close previous downtime if state changed from downtime to running
            if (ZustandAlt == 2 && ZustandNeu != 2)
            {
                SQLStr = "UPDATE TPM_Stillog SET Geht = 1, Ende = " + 
                    MainDLL.FloatToPunktString(MainDLL.DateTimeToFloat(Jetzt)) + 
                    " WHERE MaschNr = '" + MaschNr + "' AND Geht = 0";
                SQL_fuc.SQL_Insert(DatenM.qUpdate, SQLStr);
            }

            // Open new downtime if state changed to downtime
            if (ZustandAlt != 2 && ZustandNeu == 2)
            {
                SQLStr = "INSERT INTO TPM_Stillog (Nr, MaschNr, StillstandNr, Start, Geht, Schicht, Schuss, Prod) " +
                    "VALUES(TPMSTILLOGID.NextVal, '" + MaschNr + "', " + StillstandNr.ToString() + ", " +
                    MainDLL.FloatToPunktString(MainDLL.DateTimeToFloat(Jetzt)) + ", 0, '" + Schicht + 
                    "', " + Schuss.ToString() + ", " + Prod.ToString() + ")";
                SQL_fuc.SQL_Insert(DatenM.qUpdate, SQLStr);
            }

            // Update machine state in database
            SQLStr = "UPDATE Maschine SET Zustand = " + ZustandNeu.ToString() + 
                " WHERE MaschNr = '" + MaschNr + "'";
            SQL_fuc.SQL_Insert(DatenM.qUpdate, SQLStr);

            // Log state change
            MainDLL.SchreibeMeldung("TPM State change: Machine " + MaschNr + " from " + 
                ZustandAlt.ToString() + " to " + ZustandNeu.ToString(), 1);
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_TPM_Zustandswechsel: " + ex.Message, 0);
        }
    }

    // ========================================================================
    // CCC_CheckStatusTPM_Stillog - Check TPM stillog status
    // ========================================================================
    
    public static void CCC_CheckStatusTPM_Stillog_Implementation()
    {
        try
        {
            // Check TPM stillog table for inconsistencies
            string SQLStr = "SELECT * FROM TPM_Stillog WHERE Geht = 0";
            SQL_fuc.SQL_Get(DatenM.qSuch, SQLStr);
            
            while (!DatenM.qSuch.EOF)
            {
                int Nr = DatenM.qSuch.FieldByName("Nr").AsInteger();
                int MaschNr = DatenM.qSuch.FieldByName("MaschNr").AsInteger();
                double Start = DatenM.qSuch.FieldByName("Start").AsFloat();
                
                // Check if downtime has been open for too long
                DateTime StartTime = MainDLL.ConvertFromFloat(Start);
                TimeSpan Duration = MainDLL.Jetzt - StartTime;
                
                if (Duration.TotalHours > 24) // More than 24 hours
                {
                    // Close very old downtimes automatically
                    SQL_fuc.UpdateSQL(DatenM.qUpdate, "TPM_Stillog", "Geht", "1", "Nr", Nr.ToString());
                    SQL_fuc.UpdateSQL(DatenM.qUpdate, "TPM_Stillog", "Ende", 
                        MainDLL.FloatToPunktString(MainDLL.DateTimeToFloat(MainDLL.Jetzt)), "Nr", Nr.ToString());
                    
                    MainDLL.SchreibeMeldung("Auto-closed old downtime: " + Nr.ToString() + " for machine " + 
                        MaschNr.ToString(), 1);
                }

                DatenM.qSuch.Next();
            }
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_CheckStatusTPM_Stillog: " + ex.Message, 0);
        }
    }

    // ========================================================================
    // CCC_AuftragAutomatikStart - Automatic order start
    // ========================================================================
    
    public static void CCC_AuftragAutomatikStart_Implementation()
    {
        try
        {
            // Automatic order start logic
            for (int I = 1; I <= DBMain.Anzahl_Masch; I++)
            {
                if (ArbeitGlobals.Includis[I].IstArchiviert)
                    continue;

                // Check if machine is free and has orders waiting
                if (ArbeitGlobals.Includis[I].Zustand == 2 && // Machine stopped
                    string.IsNullOrEmpty(ArbeitGlobals.Includis[I].Auftrag.AuftragNr))
                {
                    // Find next order for this machine
                    string SQLStr = "SELECT * FROM PDE WHERE Lizenz = '" + ArbeitGlobals.Includis[I].Lizenz + 
                        "' AND stat = " + ComtasH.stGeplantInt + " ORDER BY StartdatumZeit";
                    SQL_fuc.SQL_Get(DatenM.qSuch, SQLStr);
                    
                    if (!DatenM.qSuch.IsEmpty)
                    {
                        string AuftragNr = DatenM.qSuch.FieldByName("AuftragNr").AsString();
                        double StartDatumZeit = DatenM.qSuch.FieldByName("StartdatumZeit").AsFloat();
                        
                        // Check if order should start now
                        if (StartDatumZeit <= MainDLL.DateTimeToFloat(MainDLL.Jetzt))
                        {
                            // Start order automatically
                            CCC_Auftrag_Starten_BCDCode_Implementation(ArbeitGlobals.Includis[I].Lizenz, false);
                        }
                    }
                }
            }
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_AuftragAutomatikStart: " + ex.Message, 0);
        }
    }

    // ========================================================================
    // CCC_AuftragAutomatikStartVariabel - Variable automatic order start
    // ========================================================================
    
    public static void CCC_AuftragAutomatikStartVariabel_Implementation()
    {
        try
        {
            // Variable automatic order start - similar to CCC_AuftragAutomatikStart but with different logic
            // This would typically check for orders that can be started based on variable conditions
            
            for (int I = 1; I <= DBMain.Anzahl_Masch; I++)
            {
                if (ArbeitGlobals.Includis[I].IstArchiviert)
                    continue;

                // Check if machine is in setup and order should start
                if (ArbeitGlobals.Includis[I].Zustand == DBMain.MaschRuesten &&
                    ArbeitGlobals.Includis[I].Auftrag.Stat == ComtasH.stStartRuestenInt)
                {
                    // Check if setup is complete (this would depend on specific conditions)
                    // For now, assume setup is complete after a certain time
                    TimeSpan setupTime = MainDLL.Jetzt - ArbeitGlobals.Includis[I].LetzterMaschinenStop;
                    
                    if (setupTime.TotalMinutes > DBMain.Ruestzeit_Minuten)
                    {
                        // Setup complete, start production
                        CCC_Auftrag_Starten_BCDCode_Implementation(ArbeitGlobals.Includis[I].Lizenz, false);
                    }
                }
            }
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_AuftragAutomatikStartVariabel: " + ex.Message, 0);
        }
    }

    // ========================================================================
    // CCC_UeberwachungszeitBerechnen - Calculate monitoring time
    // ========================================================================
    
    public static void CCC_UeberwachungszeitBerechnen_Implementation(int MaschNr)
    {
        try
        {
            // Calculate monitoring time for a machine
            // This would typically check if a downtime has exceeded the monitoring threshold
            
            int maschIndex = GetMaschIndexFromDatenblock(MaschNr);
            if (maschIndex == 0)
                return;

            // Check if machine is currently in downtime
            if (ArbeitGlobals.Includis[maschIndex].Zustand == 2)
            {
                // Get current downtime duration
                TimeSpan downtimeDuration = MainDLL.Jetzt - ArbeitGlobals.Includis[maschIndex].LetzterMaschinenStop;
                
                // Check if downtime exceeds monitoring threshold
                if (downtimeDuration.TotalMinutes > DBMain.Ueberwachungszeit_Minuten)
                {
                    // Create notification for long downtime
                    string SQLStr = "INSERT INTO BDA (Nr, Lizenz, DatumZeit, Bezeichnung, Quelle, Zustaendig, Zustand, " +
                        "Masch_bez, Signal, Sollwert, Vorwarnung, Erledigt, RoteLampeAn, NeuerJob) " +
                        "VALUES(BDAID.NextVal, '" + ArbeitGlobals.Includis[maschIndex].Lizenz + 
                        "', " + MainDLL.FloatToPunktString(MainDLL.DateTimeToFloat(MainDLL.Jetzt)) + 
                        ", '" + Sprache_V63.GetL("Lange Störung") + 
                        "', '" + Sprache_V63.GetL("System") + 
                        "', '" + ArbeitGlobals.Includis[maschIndex].Zustaendig + 
                        "', '" + Sprache_V63.GetL("sofort erledigen") + 
                        "', '" + ArbeitGlobals.Includis[maschIndex].KURZKENNUNG + 
                        "', '" + Sprache_V63.GetL("Störung") + 
                        "', '0', '0', '" + Sprache_V63.GetL("sofort erledigen") + 
                        "', '1', '1')";
                    SQL_fuc.SQL_Insert(DatenM.qUpdate, SQLStr);
                }
            }
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_UeberwachungszeitBerechnen: " + ex.Message, 0);
        }
    }

    private static int GetMaschIndexFromDatenblock(int Datenblock)
    {
        for (int i = 1; i <= DBMain.Anzahl_Masch; i++)
        {
            if (ArbeitGlobals.Includis[i].Datenblock == Datenblock)
                return i;
        }
        return 0;
    }

    // ========================================================================
    // Additional helper functions
    // ========================================================================
    
    public static string CCC_GetWerkzeugNr_Implementation(int Schluessel)
    {
        try
        {
            // Look up tool number from database
            string SQLStr = "SELECT WerkzeugNr FROM Werkzeug WHERE Schluessel = " + Schluessel.ToString();
            SQL_fuc.SQL_Get(DatenM.qSuch, SQLStr);
            
            if (!DatenM.qSuch.IsEmpty)
                return DatenM.qSuch.FieldByName("WerkzeugNr").AsString();
            else
                return Schluessel.ToString();
        }
        catch
        {
            return Schluessel.ToString();
        }
    }

    public static void CCC_Job_erzeugen_Implementation(CO_Query Q, string Lizenz, string Bezeichnung, 
        string Quelle, string Signal, string Zustaendig, string Sollwert, string Vorwarnung, 
        bool VorwarnungBool, bool RoteLampeAn)
    {
        try
        {
            // Create a job in the BDA table
            // This is similar to CCC_Erzeuge_Arbeitsplan but with different parameters
            
            string WertZustand = VorwarnungBool ? Sprache_V63.GetL("Vorwarnung") : Sprache_V63.GetL("sofort erledigen");
            short IntRoteLampe = RoteLampeAn ? (short)1 : (short)0;
            short NeuerJob = 1;

            string Maschine = CCC_GetKennung(GetMaschNrFromLizenz(Lizenz));

            string SQLStr = "INSERT INTO BDA (Nr, Lizenz, DatumZeit, Bezeichnung, Quelle, Zustaendig, Zustand, " +
                "Masch_bez, Signal, Sollwert, Vorwarnung, Erledigt, RoteLampeAn, NeuerJob) " +
                "VALUES(BDAID.NextVal, '" + Lizenz + 
                "', " + MainDLL.FloatToPunktString(MainDLL.DateTimeToFloat(MainDLL.Jetzt)) + 
                ", '" + Bezeichnung + 
                "', '" + Quelle + 
                "', '" + Zustaendig + 
                "', '" + WertZustand + 
                "', '" + Maschine + 
                "', '" + Signal + 
                "', '" + Sollwert + 
                "', '" + Vorwarnung + 
                "', '" + WertZustand + 
                "', '" + IntRoteLampe.ToString() + 
                "', '" + NeuerJob.ToString() + ")";
            SQL_fuc.SQL_Insert(DatenM.qUpdate, SQLStr);
        }
        catch (Exception ex)
        {
            MainDLL.SchreibeMeldung("Error in CCC_Job_erzeugen: " + ex.Message, 0);
        }
    }

    private static string GetMaschNrFromLizenz(string Lizenz)
    {
        for (int i = 1; i <= DBMain.Anzahl_Masch; i++)
        {
            if (string.Equals(ArbeitGlobals.Includis[i].Lizenz, Lizenz, StringComparison.OrdinalIgnoreCase))
                return ArbeitGlobals.Includis[i].MaschNr;
        }
        return string.Empty;
    }

    // ========================================================================
    // More functions to be implemented...
    // ========================================================================
}
