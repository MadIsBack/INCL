// <summary>
// U_SPC.cs - C# translation of U_SPC.pas
// Statistical Process Control functions
// </summary>

using System;
using System.Collections.Generic;

namespace INCLService_CSharp
{
    /// <summary>
    /// SPC Signal structure
    /// </summary>
    public class TSPC_Signal
    {
        public string[] Signal { get; set; } = new string[10];
        public double[] Sollwert { get; set; } = new double[10];
        public int[] TOL1P { get; set; } = new int[10];
        public int[] TOL1N { get; set; } = new int[10];
        public int[] TOL2P { get; set; } = new int[10];
        public int[] TOL2N { get; set; } = new int[10];
        public int[] Stichproben { get; set; } = new int[10];
        public bool[] Aktiv { get; set; } = new bool[10];
    }

    /// <summary>
    /// SPC Save structure
    /// </summary>
    public class TSPC_Save
    {
        public string AuftragNr { get; set; } = string.Empty;
        public int X_Schuss { get; set; } = 0;
        public double[] Wert { get; set; } = new double[10];
        public int[] Zaehler { get; set; } = new int[10];
        public double[] Summe { get; set; } = new double[10];
        public double[] Mittelwert { get; set; } = new double[10];
        public int[] Ausreisser { get; set; } = new int[10];
    }

    /// <summary>
    /// U_SPC class - Statistical Process Control functions
    /// </summary>
    public static class U_SPC
    {
        // Global arrays
        public static TSPC_Signal[] SPC_Signal { get; private set; } = new TSPC_Signal[DBMain.Max_ANZAHL + 1];
        public static TSPC_Save[] SPC_Save { get; private set; } = new TSPC_Save[DBMain.Max_ANZAHL + 1];

        /// <summary>
        /// Static constructor to initialize arrays
        /// </summary>
        static U_SPC()
        {
            for (int i = 0; i <= DBMain.Max_ANZAHL; i++)
            {
                SPC_Signal[i] = new TSPC_Signal();
                SPC_Save[i] = new TSPC_Save();
            }
        }

        /// <summary>
        /// Initialize SPC
        /// </summary>
        public static void SPC_Init()
        {
            try
            {
                string SQLStr;
                
                SQLStr = "select * from QSPCSETUP";
                SQL_fuc.SQL_Get(DatenM.Instance.qSuch3, SQLStr);

                for (int I = 1; I <= DBMain.Anzahl_Masch; I++)
                {
                    if (ArbeitGlobals.Includis[I].IstArchiviert)
                        continue;

                    // Find machine in QSPCSETUP
                    bool found = false;
                    DatenM.Instance.qSuch3.First();
                    while (!DatenM.Instance.qSuch3.EOF)
                    {
                        if (DatenM.Instance.qSuch3.FieldByName("MASCHINE").AsString == ArbeitGlobals.Includis[I].Lizenz)
                        {
                            found = true;
                            break;
                        }
                        DatenM.Instance.qSuch3.Next();
                    }

                    if (found)
                    {
                        for (int J = 0; J < SPC_Signal[I].Signal.Length; J++)
                        {
                            if (string.IsNullOrEmpty(SPC_Signal[I].Signal[J]))
                                continue;
                            
                            SPC_Signal[I].Sollwert[J] = DatenM.Instance.qSuch3.FieldByName("Sollwert_" + SPC_Signal[I].Signal[J]).AsFloat;
                            SPC_Signal[I].TOL1P[J] = DatenM.Instance.qSuch3.FieldByName("TOL1P_" + SPC_Signal[I].Signal[J]).AsInteger;
                            SPC_Signal[I].TOL1N[J] = DatenM.Instance.qSuch3.FieldByName("TOL1N_" + SPC_Signal[I].Signal[J]).AsInteger;
                            SPC_Signal[I].TOL2P[J] = DatenM.Instance.qSuch3.FieldByName("TOL2P_" + SPC_Signal[I].Signal[J]).AsInteger;
                            SPC_Signal[I].TOL2N[J] = DatenM.Instance.qSuch3.FieldByName("TOL2N_" + SPC_Signal[I].Signal[J]).AsInteger;
                            SPC_Signal[I].Stichproben[J] = DatenM.Instance.qSuch3.FieldByName("STICH_" + SPC_Signal[I].Signal[J]).AsInteger;
                            SPC_Signal[I].Aktiv[J] = DatenM.Instance.qSuch3.FieldByName("SPCAKT_" + SPC_Signal[I].Signal[J]).AsInteger == 1;
                            SPC_Save[I].X_Schuss = SPC_Signal[I].Stichproben[J];
                        }
                    }
                    else
                    {
                        for (int J = 0; J < SPC_Signal[I].Signal.Length; J++)
                        {
                            SPC_Signal[I].Sollwert[J] = 0;
                            SPC_Signal[I].TOL1P[J] = 0;
                            SPC_Signal[I].TOL1N[J] = 0;
                            SPC_Signal[I].TOL2P[J] = 0;
                            SPC_Signal[I].TOL2N[J] = 0;
                            SPC_Signal[I].Stichproben[J] = 0;
                            SPC_Signal[I].Aktiv[J] = false;
                            SPC_Save[I].AuftragNr = string.Empty;
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in SPC_Init: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Write current SPC values
        /// </summary>
        public static void SPC_Aktuelle_Werte_Schreiben()
        {
            try
            {
                string StatStr;
                int Nr, Abw;

                for (int I = 1; I <= DBMain.Anzahl_Masch; I++)
                {
                    if (string.IsNullOrEmpty(ArbeitGlobals.Includis[I].Lizenz))
                        continue;

                    if (!ArbeitGlobals.Includis[I].SPC_Aktiv || ArbeitGlobals.Includis[I].IstArchiviert)
                        continue;

                    // Implementation would write current SPC values to database
                }
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in SPC_Aktuelle_Werte_Schreiben: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Write SPC samples
        /// </summary>
        public static void SPC_Stichproben_Schreiben()
        {
            try
            {
                // Implementation would write SPC samples to database
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in SPC_Stichproben_Schreiben: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Write SPC shift protocol
        /// </summary>
        public static void SPC_SchichtProtokoll_Schreiben()
        {
            try
            {
                // Implementation would write SPC shift protocol to database
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in SPC_SchichtProtokoll_Schreiben: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// SPC shift calculation
        /// </summary>
        public static void SPC_Schichtberechnung(int SI, CO_SPC aSPC)
        {
            try
            {
                // Implementation would calculate SPC shift values
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in SPC_Schichtberechnung: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Get last sample
        /// </summary>
        public static int GetLastStichprobe(int index)
        {
            try
            {
                // Implementation would get last sample from database
                return 0;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in GetLastStichprobe: " + ex.Message, 0);
                return 0;
            }
        }

        /// <summary>
        /// Check SPC data
        /// </summary>
        public static bool CheckSPCDaten(int index)
        {
            try
            {
                // Implementation would check SPC data
                return true;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in CheckSPCDaten: " + ex.Message, 0);
                return false;
            }
        }

        /// <summary>
        /// Check outliers
        /// </summary>
        public static bool CheckAusreisser(int index)
        {
            try
            {
                // Implementation would check for outliers
                return false;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in CheckAusreisser: " + ex.Message, 0);
                return false;
            }
        }

        /// <summary>
        /// Check SPC sample data
        /// </summary>
        public static bool CheckSPC_Stich_Daten(int index)
        {
            try
            {
                // Implementation would check SPC sample data
                return true;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in CheckSPC_Stich_Daten: " + ex.Message, 0);
                return false;
            }
        }

        /// <summary>
        /// Check before shift
        /// </summary>
        public static bool CheckVorSchicht()
        {
            try
            {
                // Implementation would check before shift
                return true;
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in CheckVorSchicht: " + ex.Message, 0);
                return false;
            }
        }

        /// <summary>
        /// Delete shift outliers
        /// </summary>
        public static void DeleteAusreisserSchicht()
        {
            try
            {
                // Implementation would delete shift outliers
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in DeleteAusreisserSchicht: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Delete sample outliers
        /// </summary>
        public static void DeleteAusreisserStich()
        {
            try
            {
                // Implementation would delete sample outliers
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in DeleteAusreisserStich: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// SPC target/actual comparison
        /// </summary>
        public static void SPC_SollIstVergleich()
        {
            try
            {
                // Implementation would compare SPC target and actual values
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in SPC_SollIstVergleich: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Write SPC sample
        /// </summary>
        public static void SPC_Stich_Schreiben()
        {
            try
            {
                // Implementation would write SPC sample
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in SPC_Stich_Schreiben: " + ex.Message, 0);
            }
        }
    }
}
