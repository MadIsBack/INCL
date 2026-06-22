// <summary>
// U_Metall.cs - C# translation of U_Metall.pas
// Metall-specific functions for order start/end processing
// </summary>

using System;
using System.Collections.Generic;

namespace INCLService_CSharp
{
    public static class U_Metall
    {
        // Constants for signal numbers
        private const int CPROGRAMM_NR = 100;
        private const int SigNoAuftrag_Start = 200;
        private const int SigNoAuftrag_Ende = 201;

        // Status constants
        private const int stLaeuftInt = 0;
        private const int stStartRuestenInt = 1;
        private const int stFreigabeInt = 5;
        private const int stUnterbrochenInt = 6;

        /// <summary>
        /// Check order start
        /// </summary>
        public static void Check_Auftrag_Start()
        {
            try
            {
                string SQLStr, Meldung;
                
                for (int I = 1; I <= DBMain.Anzahl_Masch; I++)
                {
                    if (ArbeitGlobals.Includis[I].IstArchiviert)
                        continue;
                    
                    if (MainDLL.TPM_Signal[I].Istwert > 0 && MainDLL.TPM_Signal[I].Istwert > 0)
                    {
                        // Check if program number exists in PDE
                        SQLStr = "SELECT COUNT(*) CNT from PDE where Programm_Nr = " + 
                            MainDLL.TPM_Signal[I].Istwert + 
                            " AND (stat = 0 or stat = 1 or stat = 5 or stat = 6) AND Lizenz = '" + 
                            ArbeitGlobals.Includis[I].Lizenz + "'";
                        SQL_fuc.SQL_Get(DatenM.Instance.qSuch, SQLStr);
                        
                        if (DatenM.Instance.qSuch.FieldByName("CNT").AsInteger > 0)
                        {
                            SQLStr = "SELECT * from PDE where Programm_Nr = " + 
                                MainDLL.TPM_Signal[I].Istwert + 
                                " AND (stat = 0 or stat = 1 or stat = 5 or stat = 6) AND Lizenz = '" + 
                                ArbeitGlobals.Includis[I].Lizenz + "'";
                            SQL_fuc.SQL_Get(DatenM.Instance.qSuch, SQLStr);

                            switch (DatenM.Instance.qSuch.FieldByName("stat").AsInteger)
                            {
                                case stLaeuftInt:
                                    Schreibe_Protokoll(true, DatenM.Instance.qSuch.FieldByName("Nr").AsInteger, I, MainDLL.TPM_Signal[I].Istwert);
                                    Meldung = "Start OK.";
                                    break;
                                    
                                case stStartRuestenInt:
                                    Schreibe_Protokoll(true, DatenM.Instance.qSuch.FieldByName("Nr").AsInteger, I, MainDLL.TPM_Signal[I].Istwert);
                                    Meldung = "Start OK.";
                                    break;
                                    
                                case stFreigabeInt:
                                    Schreibe_Protokoll(true, DatenM.Instance.qSuch.FieldByName("Nr").AsInteger, I, MainDLL.TPM_Signal[I].Istwert);
                                    AAA_Freigabe_Auftrag_Starten(DatenM.Instance.qSuch2, DatenM.Instance.qSuch.FieldByName("Nr").AsInteger);
                                    Meldung = "Start OK. Auftrag gestartet...";
                                    break;
                                    
                                case stUnterbrochenInt:
                                    Schreibe_Protokoll(true, DatenM.Instance.qSuch.FieldByName("Nr").AsInteger, I, MainDLL.TPM_Signal[I].Istwert);
                                    AAA_Freigabe_Auftrag_Starten(DatenM.Instance.qSuch2, DatenM.Instance.qSuch.FieldByName("Nr").AsInteger);
                                    Meldung = "Start OK. Auftrag gestartet...";
                                    break;
                                default:
                                    Meldung = "Start OK.";
                                    break;
                            }

                            Schreibe_Protokoll_StartEnde(ArbeitGlobals.Includis[I].Lizenz, true, MainDLL.TPM_Signal[I].Istwert, Meldung, "bekannt");
                        }
                        else
                        {
                            // Programm_Nr nicht gefunden
                            if (AAA_CheckWarmlaufProgramm(DatenM.Instance.qUpdate, MainDLL.TPM_Signal[I].Istwert))
                            {
                                Schreibe_Protokoll_Warmlaufprogramm(ArbeitGlobals.Includis[I].Lizenz, MainDLL.TPM_Signal[I].Istwert, I);
                                Schreibe_Protokoll_StartEnde(ArbeitGlobals.Includis[I].Lizenz, true, MainDLL.TPM_Signal[I].Istwert,
                                    "Warmlaufprogramm gestartet...", "bekannt");
                            }
                            else
                            {
                                // Laufende Programme beenden
                                Schreibe_Protokoll(true, -1, I, MainDLL.TPM_Signal[I].Istwert);
                                SQLStr = "SELECT betriebsauftragnr FROM maschinf WHERE lizenz = '" + ArbeitGlobals.Includis[I].Lizenz + "'";
                                SQL_fuc.SQL_Get(DatenM.Instance.qSuch, SQLStr);
                                if (!DatenM.Instance.qSuch.IsEmpty)
                                {
                                    // LogUsrEvent would be called here
                                }
                                // S7Main.S7_Auftrag.Unterbrechen(Includis[I].Lizenz);
                            }
                        }

                        // Reset signals in SPS
                        // S7Main.Schreibe_SPS_Wert(StrToInt(Includis[I].MaschNr), TTT_GetSignalNr(CPROGRAMM_NR), 0);
                        SQL_fuc.UpdateSQL(DatenM.Instance.qSuch, "Signal_Maschine", "Istwert", "0", "nr", MainDLL.TPM_Signal[I].DBNr.ToString());
                        // S7Main.Schreibe_SPS_Wert(StrToInt(Includis[I].MaschNr), SigNoAuftrag_Start, 0);
                        SQL_fuc.UpdateSQL(DatenM.Instance.qSuch, "Signal_Maschine", "Istwert", "0", "nr", MainDLL.TPM_Signal[I].DBNr.ToString());
                        
                        // S7Main.DatenLesen_Metall;
                    }
                }

                // Reset all start signals
                for (int I = 1; I <= DBMain.Anzahl_Masch; I++)
                {
                    if (ArbeitGlobals.Includis[I].IstArchiviert)
                        continue;
                    
                    if (MainDLL.TPM_Signal[I].Istwert > 0)
                    {
                        // S7Main.Schreibe_SPS_Wert(StrToInt(Includis[I].MaschNr), SigNoAuftrag_Start, 0);
                        SQL_fuc.UpdateSQL(DatenM.Instance.qSuch, "Signal_Maschine", "Istwert", "0", "nr", MainDLL.TPM_Signal[I].DBNr.ToString());
                    }
                }
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in Check_Auftrag_Start: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Check order end
        /// </summary>
        public static void Check_Auftrag_Ende()
        {
            try
            {
                string SQLStr;
                
                for (int I = 1; I <= DBMain.Anzahl_Masch; I++)
                {
                    if (ArbeitGlobals.Includis[I].IstArchiviert)
                        continue;
                    
                    if (MainDLL.TPM_Signal[I].Istwert > 0)
                    {
                        SQLStr = "SELECT COUNT(*) CNT from PDE where Programm_Nr = " + 
                            MainDLL.TPM_Signal[I].Istwert + 
                            " AND (stat = 0 or stat = 1) AND Lizenz = '" + ArbeitGlobals.Includis[I].Lizenz + "'";
                        SQL_fuc.SQL_Get(DatenM.Instance.qSuch, SQLStr);
                        
                        if (DatenM.Instance.qSuch.FieldByName("CNT").AsInteger > 0)
                        {
                            SQLStr = "SELECT * from PDE where Programm_Nr = " + 
                                MainDLL.TPM_Signal[I].Istwert + 
                                " AND (stat = 0 or stat = 1) AND Lizenz = '" + ArbeitGlobals.Includis[I].Lizenz + "'";
                            SQL_fuc.SQL_Get(DatenM.Instance.qSuch, SQLStr);

                            Schreibe_Protokoll(false, DatenM.Instance.qSuch.FieldByName("Nr").AsInteger, I, MainDLL.TPM_Signal[I].Istwert);
                            Schreibe_Protokoll_StartEnde(ArbeitGlobals.Includis[I].Lizenz, false, MainDLL.TPM_Signal[I].Istwert,
                                "Ende OK.", "bekannt");
                        }
                        else
                        {
                            Schreibe_Protokoll(false, -1, I, MainDLL.TPM_Signal[I].Istwert);
                            Schreibe_Protokoll_StartEnde(ArbeitGlobals.Includis[I].Lizenz, false, MainDLL.TPM_Signal[I].Istwert,
                                "Programm war nicht gestartet...", "unbekannt");
                        }

                        // Reset signals in SPS
                        // S7Main.Schreibe_SPS_Wert(StrToInt(Includis[I].MaschNr), TTT_GetSignalNr(CPROGRAMM_NR), 0);
                        SQL_fuc.UpdateSQL(DatenM.Instance.qSuch, "Signal_Maschine", "Istwert", "0", "nr", MainDLL.TPM_Signal[I].DBNr.ToString());
                        // S7Main.Schreibe_SPS_Wert(StrToInt(Includis[I].MaschNr), SigNoAuftrag_Ende, 0);
                        SQL_fuc.UpdateSQL(DatenM.Instance.qSuch, "Signal_Maschine", "Istwert", "0", "nr", MainDLL.TPM_Signal[I].DBNr.ToString());
                        
                        // S7Main.DatenLesen_Metall;
                    }
                }
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in Check_Auftrag_Ende: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Write protocol
        /// </summary>
        public static void Schreibe_Protokoll(bool StartEnde, int PDENr, int index, int Programm_Nr)
        {
            try
            {
                int Palettenwechsel = 0, RuestZeit = 0, Laufzeit = 0, Istwert = 0;
                string SQLStr, Liz = string.Empty, BetriebsauftragNr = string.Empty;
                int Taktzeit = 0, laufzeitdiff = 0;
                double TPM_Start = 0;
                int TPM_Stat_Nr = 0;

                if (StartEnde)
                {
                    // Programm wurde gestartet
                    if (SQL_fuc.SQL2GetBool(DatenM.Instance.qSuch2, "PDE", "Nr", PDENr.ToString(), true))
                    {
                        Liz = DatenM.Instance.qSuch2.FieldByName("Lizenz").AsString;
                        BetriebsauftragNr = DatenM.Instance.qSuch2.FieldByName("Betriebsauftragnr").AsString;
                        Taktzeit = (int)Math.Round(DatenM.Instance.qSuch2.FieldByName("Taktzeit").AsInteger / 60.0 / 100.0);
                    }
                    else
                    {
                        Liz = ArbeitGlobals.Includis[index].Maschine;
                        BetriebsauftragNr = "unbekannt";
                        Taktzeit = 0;
                    }

                    // Check if other programs are running on this machine
                    if (SQL_fuc.SQL2GetBool(DatenM.Instance.qSuch3, "PDEPROT", "Maschine", Liz, "EndeDatumZeit", "0", true))
                    {
                        DatenM.Instance.qSuch3.First();
                        while (!DatenM.Instance.qSuch3.EOF)
                        {
                            if (DatenM.Instance.qSuch3.FieldByName("Programm_Nr").AsInteger == Programm_Nr)
                                return;

                            Schreibe_Protokoll(false, DatenM.Instance.qSuch3.FieldByName("PDE_Nr").AsInteger, index, Programm_Nr);
                            DatenM.Instance.qSuch3.Next();
                        }
                    }

                    // Calculate Palettenwechsel
                    SQLStr = "select * from PDEPROT where Maschine = '" + Liz + "' order by StartDatumZeit";
                    SQL_fuc.SQL_Get(DatenM.Instance.qUpdate, SQLStr);
                    DatenM.Instance.qUpdate.Last();
                    Palettenwechsel = (int)Math.Round((MainDLL.JetztFloat - DatenM.Instance.qUpdate.FieldByName("EndeDatumZeit").AsFloat) * 1440);
                    TPM_Start = DatenM.Instance.qUpdate.FieldByName("EndeDatumZeit").AsFloat;

                    // Book last downtime
                    if (Palettenwechsel > 3)
                    {
                        SQLStr = "delete from TPM_Stillog where MaschNr = " + ArbeitGlobals.Includis[index].MaschNr +
                            " AND Stillstandnr = 2 AND Geht = 0";
                        SQL_fuc.SQL_Insert(DatenM.Instance.qUpdate, SQLStr);

                        SQLStr = "delete from TPM_Stillog where MaschNr = " + ArbeitGlobals.Includis[index].MaschNr +
                            " AND Stillstandnr = 2 " +
                            " AND KOMMT > '" + SQL_fuc.FloatToStr2(TPM_Start) + "' AND GEHT < '" + SQL_fuc.FloatToStr2(MainDLL.JetztFloat) + "'";
                        SQL_fuc.SQL_Insert(DatenM.Instance.qUpdate, SQLStr);

                        SQLStr = "INSERT INTO TPM_Stillog (Nr,MaschNr,Schicht,Kommt,Stillstandnr,KommtStr, " +
                            " Reaktionszeit,Geht,GehtStr,Dauer)" +
                            " VALUES(TPM_StillogID.Nextval" +
                            ",'" + ArbeitGlobals.Includis[index].MaschNr +
                            "','" + ArbeitGlobals.Includis[index].Schicht +
                            "','" + SQL_fuc.FloatToStr2(TPM_Start) +
                            "','" + 10 +
                            "','" + MainDLL.DateTimeToStr(MainDLL.ConvertFromFloat(TPM_Start)) + " ' + '" + MainDLL.DateTimeToStr(MainDLL.ConvertFromFloat(MainDLL.Frac(TPM_Start))) +
                            "','0'" +
                            ",'" + SQL_fuc.FloatToStr2(MainDLL.JetztFloat) +
                            "','" + MainDLL.DateTimeToStr(MainDLL.ConvertFromFloat(MainDLL.JetztFloat)) + " ' + '" + MainDLL.DateTimeToStr(MainDLL.ConvertFromFloat(MainDLL.Frac(MainDLL.JetztFloat))) +
                            "','" + Palettenwechsel +
                            "')";
                        SQL_fuc.SQL_Insert(DatenM.Instance.qUpdate, SQLStr);
                    }

                    if (SQL_fuc.SQLGet(DatenM.Instance.qUpdate, "PDE", "Nr", PDENr.ToString(), true) > 0)
                        Istwert = DatenM.Instance.qUpdate.FieldByName("Istwert").AsInteger;
                    else
                        Istwert = -1;
                    Istwert++;

                    if (Palettenwechsel < 0)
                        Palettenwechsel = 0;

                    RuestZeit = 0;
                    Laufzeit = 0;

                    SQLStr = "INSERT INTO PDEPROT (Nr,PDE_Nr,Maschine,Programm_Nr,BetriebsauftragNr,StartDatumZeit,EndeDatumZeit," +
                        "Laufzeit,Sollaufzeit,Palettenwechsel,Ruestzeit, Menge)" +
                        "VALUES(PDEPROTID.NextVal" +
                        ",'" + PDENr +
                        "','" + Liz +
                        "','" + Programm_Nr +
                        "','" + BetriebsauftragNr +
                        "','" + SQL_fuc.FloatToStr2(MainDLL.JetztFloat) +
                        "','0'" +
                        ",'" + Laufzeit +
                        "','" + Taktzeit +
                        "','" + Palettenwechsel +
                        "','" + RuestZeit +
                        "','" + Istwert +
                        "')";
                    SQL_fuc.SQL_Insert(DatenM.Instance.qUpdate, SQLStr);

                    SQL_fuc.UpdateSQL(DatenM.Instance.qUpdate, "MASCHINF", "Programm_Start", SQL_fuc.FloatToStr2(MainDLL.JetztFloat), "Maschine", Liz);
                }
                else
                {
                    // Programm wurde beendet
                    if (PDENr == -1)
                    {
                        // unbekanntes Programm
                        SQLStr = "select COUNT(*) CNT from PDEPROT where (PDE_NR = -1) AND MAschine = '" + ArbeitGlobals.Includis[index].Maschine + "' AND EndeDatumZeit = 0";
                        SQL_fuc.SQL_Get(DatenM.Instance.qSuch4, SQLStr);
                        if (DatenM.Instance.qSuch4.FieldByName("CNT").AsInteger > 0)
                        {
                            SQLStr = "select * from PDEPROT where (PDE_NR = -1) AND MAschine = '" + ArbeitGlobals.Includis[index].Maschine + "' AND EndeDatumZeit = 0";
                            SQL_fuc.SQL_Get(DatenM.Instance.qSuch4, SQLStr);
                            // Continue with protocol writing...
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in Schreibe_Protokoll: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Write warm-up program protocol
        /// </summary>
        public static void Schreibe_Protokoll_Warmlaufprogramm(string Maschine, int Programm_Nr, int index)
        {
            try
            {
                // Simplified implementation
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in Schreibe_Protokoll_Warmlaufprogramm: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Write start/end protocol
        /// </summary>
        public static void Schreibe_Protokoll_StartEnde(string Maschine, bool StartEnde, int Programm_Nr, string Meldung, string Eigenschaft)
        {
            try
            {
                // Simplified implementation
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in Schreibe_Protokoll_StartEnde: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// AAA release order start
        /// </summary>
        public static void AAA_Freigabe_Auftrag_Starten(CO_Query qSuch2, int PDENr)
        {
            try
            {
                // Simplified implementation
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in AAA_Freigabe_Auftrag_Starten: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Check warm-up program
        /// </summary>
        public static bool AAA_CheckWarmlaufProgramm(CO_Query qUpdate, int Programm_Nr)
        {
            try
            {
                // Simplified implementation
                return false;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in AAA_CheckWarmlaufProgramm: " + ex.Message, 0);
                return false;
            }
        }
    }
}
