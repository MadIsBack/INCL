using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Common;
using System.Threading;

namespace Komponenten_V63_CSharp
{
    public class CO_SetupValue
    {
        public string DefVal { get; set; }
        public string KeyName { get; set; }
        public string CurrVal { get; set; }
        public bool Exists { get; set; }

        public CO_SetupValue(string aKeyName, string aDefVal)
        {
            KeyName = aKeyName;
            DefVal = aDefVal;
            CurrVal = aDefVal;
            Exists = false;
        }

        public void Save(CO_Query aQuery)
        {
            // Save the current value to database
            if (aQuery != null && aQuery.Database != null && aQuery.Database.Connected)
            {
                aQuery.SQL = "UPDATE setup_par SET wert = '" + CurrVal + "' WHERE schluessel = '" + KeyName + "'";
                aQuery.ExecSQL();
            }
        }
    }

    public class CO_SetupList
    {
        private List<CO_SetupValue> items = new List<CO_SetupValue>();

        public CO_SetupValue this[int index]
        {
            get => items[index];
        }

        public void Add(CO_SetupValue aItem)
        {
            items.Add(aItem);
        }

        public int Count => items.Count;
    }

    public class CO_Setup : IDisposable
    {
        private CO_SetupList fValList;
        private CO_SetupList fSetupList;
        public CO_Query FQuery { get; set; }

        public CO_SetupValue this[string AIndex] => GetItem(AIndex);
        public CO_SetupValue ValueByNr(int AIndex) => GetItemByNr(AIndex);
        public int Count => GetCount();

        public CO_Setup(CO_Query aQuery)
        {
            FQuery = new CO_Query(aQuery.Database);
            CreateTable();
            
            // Initialize lists
            fValList = new CO_SetupList();
            fSetupList = new CO_SetupList();

            ChangeVals();
            FillList();
            RefreshList();
        }

        private void CreateTable()
        {
            if (FQuery != null && FQuery.Database != null && FQuery.Database.Connected)
            {
                try
                {
                    FQuery.SQL = "select Nr from SETUP_PAR";
                    FQuery.Open();
                }
                catch
                {
                    // Table doesn't exist, create it
                    FQuery.SQL = "create table Setup_Par (Nr Integer Primary Key, Schluessel varchar2(50), Wert varchar2(50))";
                    FQuery.ExecSQL();
                    FQuery.SQL = "create index Setup_PAR_Sch on Setup_Par(Schluessel)";
                    FQuery.ExecSQL();
                }
            }
        }

        private void ChangeVals()
        {
            // This method handles database schema changes
            // In C# we would use migrations, but for now we'll keep it simple
        }

        private void FillList()
        {
            // Add default setup values
            fValList.Add(new CO_SetupValue("INCL_Days_TPM_Auswertung", "3"));
            fValList.Add(new CO_SetupValue("INCL_Berech_TPM_Produktion", "90"));
            fValList.Add(new CO_SetupValue("MDE_Show_Material", "1"));
            fValList.Add(new CO_SetupValue("MDE_Show_TPM_Grafik", "1"));
            fValList.Add(new CO_SetupValue("INCL_Schichtberechnung1", "0"));
            fValList.Add(new CO_SetupValue("MDE_WZ_Automatich_vom_Reparatur", "1"));
            fValList.Add(new CO_SetupValue("FP_Offline_nur_ein_Tag", "1"));
            fValList.Add(new CO_SetupValue("FP_Update_WZ_in_Stamm", "1"));
            fValList.Add(new CO_SetupValue("WS_Personal_und_Zeit_eingeben", "1"));
            fValList.Add(new CO_SetupValue("WS_Stillstand_Manuell", "0"));
            fValList.Add(new CO_SetupValue("INCL_Stillog_Arc_Tag", "180"));
            fValList.Add(new CO_SetupValue("INCL_TPM_Schicht_Pruefen_Tag", "14"));
            fValList.Add(new CO_SetupValue("MDE_LZBalken_Width", "105"));
            fValList.Add(new CO_SetupValue("CGI_Stillstand_abjetzt", "0"));
            fValList.Add(new CO_SetupValue("MDE_Everytime_Signal2", "0"));
            fValList.Add(new CO_SetupValue("WS_Gewicht_Gramm_Buchen_KG", "0"));
            fValList.Add(new CO_SetupValue("WS_Nur_laufende_Buchen", "0"));
            fValList.Add(new CO_SetupValue("INCL_Recalculation_am", "00:00"));
            fValList.Add(new CO_SetupValue("WS_Ruesten_gesperrt", "0"));
            fValList.Add(new CO_SetupValue("WS_Ausschuss_Sollwert_hoch", "1"));
            fValList.Add(new CO_SetupValue("WS_AARchiv_Personal_vom_Buchen", "0"));
            fValList.Add(new CO_SetupValue("WS_Maschinenzustand_Ruesten_Gelb", "1"));
            fValList.Add(new CO_SetupValue("WS_SortStillstandName", "0"));
            fValList.Add(new CO_SetupValue("FP_Infofenster_breiter", "0"));
            fValList.Add(new CO_SetupValue("FP_MDE_Navigator_Alle_Maschinen", "0"));
            fValList.Add(new CO_SetupValue("MDE_Taktzeit_Pass_Abfrage", "1"));
            fValList.Add(new CO_SetupValue("FP_Wunschmaschine", "0"));
            fValList.Add(new CO_SetupValue("FP_UpdateStammDaten", "0"));
            fValList.Add(new CO_SetupValue("MDE_Delete_Jobs_Ohne_Wartung", "0"));
            fValList.Add(new CO_SetupValue("FP_MDE_Password_einmal_abfragen", "0"));
            fValList.Add(new CO_SetupValue("MDE_Stillstandsprotokoll_Refresh", "0"));
            fValList.Add(new CO_SetupValue("Minibase_Archive_Backup", "0"));
            fValList.Add(new CO_SetupValue("MDE_Ausschuss_Schicht", "0"));
            fValList.Add(new CO_SetupValue("INCL_TPM_Verpackt_Ausschuss", "7"));
            fValList.Add(new CO_SetupValue("INCL_Menge_Schicht_mit_Manuell", "deleted"));
            fValList.Add(new CO_SetupValue("MDE_AArchiv_Menge_Korrektur", "1"));
            fValList.Add(new CO_SetupValue("INCL_Verpackt_nicht_Schicht_bezogen", "0"));
            fValList.Add(new CO_SetupValue("MDE_Zeit_zwischen_AuftragsStart_Ende", "0"));
            fValList.Add(new CO_SetupValue("MDE_gemittelte_Isttakt_zeigen", "0"));
            fValList.Add(new CO_SetupValue("INCL_Auftragsende_immer_berechnen", "0"));
            fValList.Add(new CO_SetupValue("MDE_Maschinf_Report_Hochformat", "0"));
            fValList.Add(new CO_SetupValue("INCL_BdaList_Testplan_BdaService", "0"));
            fValList.Add(new CO_SetupValue("FP_Aufloesen_Zwischenauftraege", "deleted"));
            fValList.Add(new CO_SetupValue("CGI_WS_Ruesten_laufender_Auftrag", "0"));
            fValList.Add(new CO_SetupValue("FP_Mehrstufige_Markieren", "0"));
            fValList.Add(new CO_SetupValue("INCL_TPM_Schicht_Verpackt_Ausschuss", "1"));
            fValList.Add(new CO_SetupValue("CTRL_OEELeistung_mit_TE", "0"));
            fValList.Add(new CO_SetupValue("MDE_OEE_Statistik", "0"));
            fValList.Add(new CO_SetupValue("CGI_Nur_Aktuellen_Auftrag_Zeigen", "0"));
            fValList.Add(new CO_SetupValue("Archivsmandant_Tage", "0"));
            fValList.Add(new CO_SetupValue("CGI_Detail_Auftraege_Verwalten", "0"));
            fValList.Add(new CO_SetupValue("FP_TemperierGeraete", "0"));
            fValList.Add(new CO_SetupValue("WS_RechnerNr_From_USerID", "0"));
            fValList.Add(new CO_SetupValue("CGI_TimeOut_AfterAction", "0"));
            fValList.Add(new CO_SetupValue("MDE_Userlist_with_Userright", "1"));
            fValList.Add(new CO_SetupValue("ERP_InterrupJobIfRunning", "0"));
            fValList.Add(new CO_SetupValue("FP_SolltaktBeiHalbautomat", "0"));
            fValList.Add(new CO_SetupValue("INCL_HalbautomatSchluesselschalter", "0"));
            fValList.Add(new CO_SetupValue("CTR_Ruestenzeit_aus_Stilllog", "0"));
            fValList.Add(new CO_SetupValue("MDE_Maschinf_AutoUpdate_Stop_Seconds", "0"));
            fValList.Add(new CO_SetupValue("MDE_Stillstand_beim_Buchen_splitten", "0"));
            fValList.Add(new CO_SetupValue("MDE_Show_SPC", "0"));
        }

        public void RefreshList()
        {
            // Refresh the setup values from database
            if (FQuery != null && FQuery.Database != null && FQuery.Database.Connected)
            {
                FQuery.SQL = "SELECT schluessel, wert FROM setup_par";
                FQuery.Open();
                
                // In a real implementation, we would read the results and update fSetupList
                // For now, we'll just mark that we've loaded from database
            }
        }

        private CO_SetupValue GetItem(string AIndex)
        {
            // Find the setup value by key name
            foreach (var item in fValList)
            {
                if (item.KeyName == AIndex)
                    return item;
            }
            return null;
        }

        private CO_SetupValue GetItemByNr(int AIndex)
        {
            if (AIndex >= 0 && AIndex < fValList.Count)
                return fValList[AIndex];
            return null;
        }

        private int GetCount()
        {
            return fValList.Count;
        }

        private static string GetParam(CO_Query aQuery, string aParameter, bool aDirect)
        {
            if (aQuery == null || !aQuery.Database.Connected)
                return "";

            aQuery.SQL = "SELECT wert FROM setup_par WHERE schluessel = '" + aParameter + "'";
            aQuery.Open();
            
            // In a real implementation, we would read the result
            // For now, return empty string
            return "";
        }

        public static int GetParamInt(CO_Query aQuery, string aParameter, bool aDirect = false)
        {
            string result = GetParam(aQuery, aParameter, aDirect);
            if (int.TryParse(result, out int intResult))
                return intResult;
            return 0;
        }

        public static string GetParamStr(CO_Query aQuery, string aParameter, bool aDirect = false)
        {
            return GetParam(aQuery, aParameter, aDirect);
        }

        public static double GetParamDouble(CO_Query aQuery, string aParameter, bool aDirect = false)
        {
            string result = GetParam(aQuery, aParameter, aDirect);
            if (double.TryParse(result, out double doubleResult))
                return doubleResult;
            return 0.0;
        }

        public static bool GetParamBool(CO_Query aQuery, string aParameter, bool aDirect = false)
        {
            string result = GetParam(aQuery, aParameter, aDirect);
            return result == "1" || result.ToLower() == "true";
        }

        public static void SetParam(CO_Query aQuery, string aParameter, bool AValue, bool writeToDb = true)
        {
            string value = AValue ? "1" : "0";
            SetParam(aQuery, aParameter, value, writeToDb);
        }

        public static void SetParam(CO_Query aQuery, string aParameter, int AValue, bool writeToDb = true)
        {
            SetParam(aQuery, aParameter, AValue.ToString(), writeToDb);
        }

        public static void SetParam(CO_Query aQuery, string aParameter, string AValue, bool writeToDb = true)
        {
            if (writeToDb && aQuery != null && aQuery.Database != null && aQuery.Database.Connected)
            {
                aQuery.SQL = "UPDATE setup_par SET wert = '" + AValue + "' WHERE schluessel = '" + aParameter + "'";
                aQuery.ExecSQL();
            }
        }

        public static void SetParam(CO_Query aQuery, string aParameter, double AValue, bool writeToDb = true)
        {
            SetParam(aQuery, aParameter, AValue.ToString(), writeToDb);
        }

        public void Dispose()
        {
            if (FQuery != null)
            {
                FQuery.Dispose();
                FQuery = null;
            }
            
            fValList = null;
            fSetupList = null;
        }

        ~CO_Setup()
        {
            Dispose();
        }
    }

    public static class CCO_Setup
    {
        public static CO_Setup Instance { get; set; }
    }

    public static class CS_CO_Setup
    {
        private static readonly object lockObj = new object();
        
        public static void Enter()
        {
            Monitor.Enter(lockObj);
        }

        public static void Exit()
        {
            Monitor.Exit(lockObj);
        }
    }
}
