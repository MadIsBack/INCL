// <summary>
// CO_Setup2.cs - C# translation of CO_Setup2.pas
// Configuration management class for setup parameters
// </summary>

using System;
using System.Collections.Generic;
using System.Data;
using System.Globalization;
using System.Threading;

namespace INCLService_CSharp
{
    /// <summary>
    /// Setup value class - represents a single configuration parameter
    /// </summary>
    public class TCO_SetupValue
    {
        public string DefVal { get; set; } = string.Empty;
        public string KeyName { get; set; } = string.Empty;
        public string CurrVal { get; set; } = string.Empty;
        public bool Exists { get; set; } = false;

        public TCO_SetupValue(string aKeyName, string aDefVal)
        {
            KeyName = aKeyName;
            DefVal = aDefVal;
            CurrVal = string.Empty;
        }

        /// <summary>
        /// Save the current value to database
        /// </summary>
        public void Save(CO_Query aQuery)
        {
            try
            {
                string sql = "UPDATE Setup_Par SET Wert = '" + 
                    CurrVal.Replace("'", "''") + 
                    "' WHERE schluessel = '" + 
                    KeyName.Replace("'", "''") + "'";
                aQuery.ExecSQL(sql);
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error saving setup value: " + ex.Message, 0);
            }
        }
    }

    /// <summary>
    /// Setup value list - collection of setup values
    /// </summary>
    public class TCO_SetupList : List<TCO_SetupValue>
    {
        public new void Add(TCO_SetupValue aItem)
        {
            aItem.Exists = false;
            base.Add(aItem);
        }

        public TCO_SetupValue GetItems(int AIndex)
        {
            if (AIndex >= 0 && AIndex < Count)
                return this[AIndex];
            return null;
        }
    }

    /// <summary>
    /// Main setup class - manages configuration parameters
    /// </summary>
    public class TCO_Setup
    {
        private TCO_SetupList fValList;
        private TCO_SetupList fSetupList;
        public CO_Query FQuery { get; private set; }

        private static TCO_Setup CCO_Setup = null;
        private static readonly object CS_CO_Setup = new object();

        /// <summary>
        /// Constructor
        /// </summary>
        public TCO_Setup(CO_Query aQuery)
        {
            FQuery = new CO_Query(aQuery.Owner);
            FQuery.Database = aQuery.Database;
            
            CreateTable();
            
            // Initialize value lists
            fValList = new TCO_SetupList();
            fSetupList = new TCO_SetupList();

            ChangeVals();
            FillList();
            RefreshList();
        }

        /// <summary>
        /// Create the setup table if it doesn't exist
        /// </summary>
        private void CreateTable()
        {
            try
            {
                string sql = "select Nr from SETUP_PAR";
                FQuery.SQL.Text = sql;
                FQuery.Open();
            }
            catch (Exception)
            {
                try
                {
                    string sql = "create table Setup_Par (Nr Integer Primary Key, Schluessel varchar2(50), Wert varchar2(50))";
                    FQuery.ExecSQL(sql);
                    sql = "create index Setup_PAR_Sch on Setup_Par(Schluessel)";
                    FQuery.ExecSQL(sql);
                }
                catch (Exception ex)
                {
                    MainDLL.SchreibeMeldung("Error creating Setup_Par table: " + ex.Message, 0);
                }
            }
        }

        /// <summary>
        /// Change old parameter names to new ones
        /// </summary>
        private void ChangeVals()
        {
            try
            {
                string aOldVal = "INCL_HalbautomatSchlüsselschalter";
                string aNewVal = "INCL_HalbautomatSchluesselschalter";
                string sql = "UPDATE setup_par SET schluessel = '" + aNewVal + "' WHERE schluessel = '" + aOldVal + "'";
                FQuery.ExecSQL(sql);
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in ChangeVals: " + ex.Message, 0);
            }

            try
            {
                string sql = "DELETE FROM setup_par WHERE nr NOT IN (SELECT MIN(nr) FROM setup_par GROUP BY schluessel)";
                FQuery.ExecSQL(sql);
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error cleaning up duplicate setup parameters: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Fill the default value list
        /// </summary>
        private void FillList()
        {
            // Add all default setup parameters
            fValList.Add(new TCO_SetupValue("INCL_Days_TPM_Auswertung", "3"));
            fValList.Add(new TCO_SetupValue("INCL_Berech_TPM_Produktion", "90"));
            fValList.Add(new TCO_SetupValue("MDE_Show_Material", "1"));
            fValList.Add(new TCO_SetupValue("MDE_Show_TPM_Grafik", "1"));
            fValList.Add(new TCO_SetupValue("INCL_Schichtberechnung1", "0"));
            fValList.Add(new TCO_SetupValue("MDE_WZ_Automatich_vom_Reparatur", "1"));
            fValList.Add(new TCO_SetupValue("FP_Offline_nur_ein_Tag", "1"));
            fValList.Add(new TCO_SetupValue("FP_Update_WZ_in_Stamm", "1"));
            fValList.Add(new TCO_SetupValue("WS_Personal_und_Zeit_eingeben", "1"));
            fValList.Add(new TCO_SetupValue("WS_Stillstand_Manuell", "0"));
            fValList.Add(new TCO_SetupValue("INCL_Stillog_Arc_Tag", "180"));
            fValList.Add(new TCO_SetupValue("INCL_TPM_Schicht_Pruefen_Tag", "14"));
            fValList.Add(new TCO_SetupValue("MDE_LZBalken_Width", "105"));
            fValList.Add(new TCO_SetupValue("CGI_Stillstand_abjetzt", "0"));
            fValList.Add(new TCO_SetupValue("MDE_Everytime_Signal2", "0"));
            fValList.Add(new TCO_SetupValue("WS_Gewicht_Gramm_Buchen_KG", "0"));
            fValList.Add(new TCO_SetupValue("WS_Nur_laufende_Buchen", "0"));
            fValList.Add(new TCO_SetupValue("INCL_Recalculation_am", "00:00"));
            fValList.Add(new TCO_SetupValue("WS_Ruesten_gesperrt", "0"));
            fValList.Add(new TCO_SetupValue("WS_Ausschuss_Sollwert_hoch", "1"));
            fValList.Add(new TCO_SetupValue("WS_AARchiv_Personal_vom_Buchen", "0"));
            fValList.Add(new TCO_SetupValue("WS_Maschinenzustand_Ruesten_Gelb", "1"));
            fValList.Add(new TCO_SetupValue("WS_SortStillstandName", "0"));
            fValList.Add(new TCO_SetupValue("FP_Infofenster_breiter", "0"));
            fValList.Add(new TCO_SetupValue("FP_MDE_Navigator_Alle_Maschinen", "0"));
            fValList.Add(new TCO_SetupValue("MDE_Taktzeit_Pass_Abfrage", "1"));
            fValList.Add(new TCO_SetupValue("FP_Wunschmaschine", "0"));
            fValList.Add(new TCO_SetupValue("FP_UpdateStammDaten", "0"));
            fValList.Add(new TCO_SetupValue("MDE_Delete_Jobs_Ohne_Wartung", "0"));
            fValList.Add(new TCO_SetupValue("FP_MDE_Password_einmal_abfragen", "0"));
            fValList.Add(new TCO_SetupValue("MDE_Stillstandsprotokoll_Refresh", "0"));
            fValList.Add(new TCO_SetupValue("Minibase_Archive_Backup", "0"));
            fValList.Add(new TCO_SetupValue("MDE_Ausschuss_Schicht", "0"));
            fValList.Add(new TCO_SetupValue("INCL_TPM_Verpackt_Ausschuss", "7"));
            fValList.Add(new TCO_SetupValue("INCL_Menge_Schicht_mit_Manuell", "deleted"));
            fValList.Add(new TCO_SetupValue("MDE_AArchiv_Menge_Korrektur", "1"));
            fValList.Add(new TCO_SetupValue("INCL_Verpackt_nicht_Schicht_bezogen", "0"));
            fValList.Add(new TCO_SetupValue("MDE_Zeit_zwischen_AuftragsStart_Ende", "0"));
            fValList.Add(new TCO_SetupValue("MDE_gemittelte_Isttakt_zeigen", "0"));
            fValList.Add(new TCO_SetupValue("INCL_Auftragsende_immer_berechnen", "0"));
            fValList.Add(new TCO_SetupValue("MDE_Maschinf_Report_Hochformat", "0"));
            fValList.Add(new TCO_SetupValue("INCL_BdaList_Testplan_BdaService", "0"));
            fValList.Add(new TCO_SetupValue("FP_Aufloesen_Zwischenauftraege", "deleted"));
            fValList.Add(new TCO_SetupValue("CGI_WS_Ruesten_laufender_Auftrag", "0"));
            fValList.Add(new TCO_SetupValue("FP_Mehrstufige_Markieren", "0"));
            fValList.Add(new TCO_SetupValue("INCL_TPM_Schicht_Verpackt_Ausschuss", "1"));
            fValList.Add(new TCO_SetupValue("CTRL_OEELeistung_mit_TE", "0"));
            fValList.Add(new TCO_SetupValue("MDE_OEE_Statistik", "0"));
            fValList.Add(new TCO_SetupValue("CGI_Nur_Aktuellen_Auftrag_Zeigen", "0"));
            fValList.Add(new TCO_SetupValue("Archivsmandant_Tage", "0"));
            fValList.Add(new TCO_SetupValue("CGI_Detail_Auftraege_Verwalten", "0"));
            fValList.Add(new TCO_SetupValue("FP_TemperierGeraete", "0"));
            fValList.Add(new TCO_SetupValue("WS_RechnerNr_From_USerID", "0"));
            fValList.Add(new TCO_SetupValue("CGI_TimeOut_AfterAction", "0"));
            fValList.Add(new TCO_SetupValue("MDE_Userlist_with_Userright", "1"));
            fValList.Add(new TCO_SetupValue("ERP_InterrupJobIfRunning", "0"));
            fValList.Add(new TCO_SetupValue("FP_SolltaktBeiHalbautomat", "0"));
            fValList.Add(new TCO_SetupValue("INCL_HalbautomatSchluesselschalter", "0"));
            fValList.Add(new TCO_SetupValue("CTR_Ruestenzeit_aus_Stilllog", "0"));
            fValList.Add(new TCO_SetupValue("MDE_Maschinf_AutoUpdate_Stop_Seconds", "0"));
            fValList.Add(new TCO_SetupValue("MDE_Stillstand_beim_Buchen_splitten", "0"));
            fValList.Add(new TCO_SetupValue("MDE_Show_SPC", "0"));
            fValList.Add(new TCO_SetupValue("MDE_Arbeitsfrei_nicht_umbuchen", "1"));
            fValList.Add(new TCO_SetupValue("FP_Fertigungsauftrag_Kombi", "0"));
            fValList.Add(new TCO_SetupValue("FP_Splitten_ohne_Route", "0"));
            fValList.Add(new TCO_SetupValue("MDC_OEE_FROM_PACKED", "1"));
            fValList.Add(new TCO_SetupValue("Stueckzahl_laufender_Auftrag_nicht_abnullen", "0"));
            fValList.Add(new TCO_SetupValue("INCL_VerpacktProt_aus_Schichtausschuss", "0"));
            fValList.Add(new TCO_SetupValue("MDE_Gutmenge_Grafik_anzeigen", "0"));
            fValList.Add(new TCO_SetupValue("MDE_Hallenspiegel_Artikel_Bezeichnung", "0"));
            fValList.Add(new TCO_SetupValue("MDE_Hallenspiegel_Temperatur", "0"));
            fValList.Add(new TCO_SetupValue("MG_Stillstand_Meldungszeit", "10"));
            fValList.Add(new TCO_SetupValue("INCL_CheckUnterbrocheneAuftraege", "0"));
            fValList.Add(new TCO_SetupValue("MDE_WZ_Maschine_Reparatur", "0"));
            fValList.Add(new TCO_SetupValue("INCL_Autobuchen_nach_Arbeitsfrei", "1"));
            fValList.Add(new TCO_SetupValue("INCL_Stillstand_beim_Schichtwechsel", "0"));
            fValList.Add(new TCO_SetupValue("FP_WS_Notiz_in_WS", "0"));
            fValList.Add(new TCO_SetupValue("FP_Eingabe_ohne_Zusatz", "0"));
            fValList.Add(new TCO_SetupValue("MDE_Etikett_beim_Beenden", "0"));
            fValList.Add(new TCO_SetupValue("FP_Ruesten_mit_Einrichter", "1"));
            fValList.Add(new TCO_SetupValue("INCL_Verpackt_manuell_autom", "0"));
            fValList.Add(new TCO_SetupValue("FP_AuftragNR_aenderbar", "0"));
            fValList.Add(new TCO_SetupValue("WS_Ruestgrund_aendern", "0"));
            fValList.Add(new TCO_SetupValue("FP_BenutzerAuftragFarbeMaster", "0"));
            fValList.Add(new TCO_SetupValue("MDE_Multibuchung", "0"));
            fValList.Add(new TCO_SetupValue("FP_PlanlisteArtikelBuchen", "0"));
            fValList.Add(new TCO_SetupValue("INCL_TaktbasisToleranz", "35"));
            fValList.Add(new TCO_SetupValue("INCL_TaktbasisAnzahl", "20"));
            fValList.Add(new TCO_SetupValue("FP_AuftragFreigabeDirekt", "0"));
            fValList.Add(new TCO_SetupValue("INCL_UeberproduktionAusVerpackt", "0"));
            fValList.Add(new TCO_SetupValue("ERP_WZ_Sollstandzeit", "100000"));
            fValList.Add(new TCO_SetupValue("WS_EtikettenProMaschine", "0"));
            fValList.Add(new TCO_SetupValue("INCL_Pausen", "0"));
            fValList.Add(new TCO_SetupValue("MDE_Export_Taktzeit_to_Excel", "1"));
            fValList.Add(new TCO_SetupValue("FP_Plangrafik_Report_Row_Height", "10"));
            fValList.Add(new TCO_SetupValue("CGI_W-Lager", "0"));
            fValList.Add(new TCO_SetupValue("FP_Halbautomatikkalender", "0"));
            fValList.Add(new TCO_SetupValue("CTR_SchichtBezeichnung_aus_Zeit", "0"));
            fValList.Add(new TCO_SetupValue("INCL_TaktmeldungNurBeiUeberschreiten", "0"));
            fValList.Add(new TCO_SetupValue("INCL_TaktmeldungNichtWiederholen", "0"));
            fValList.Add(new TCO_SetupValue("MDE_BeschreibungNurMaschine", "0"));
            fValList.Add(new TCO_SetupValue("MDE_WerkzeugStillstaende", "0"));
            fValList.Add(new TCO_SetupValue("MSG_RuestueberschreitungMelden", "1"));
            fValList.Add(new TCO_SetupValue("MSG_StillstaendeMelden", "1"));
            fValList.Add(new TCO_SetupValue("FP_Ausschussquote", "0"));
            fValList.Add(new TCO_SetupValue("FP_Plantakt", "0"));
            fValList.Add(new TCO_SetupValue("FP_LT2_Minus_LT1", "2"));
            fValList.Add(new TCO_SetupValue("FP_Werkzeugliste_Sort_Maschine", "0"));
            fValList.Add(new TCO_SetupValue("INCL_Stillstand_24h", "-1"));
            fValList.Add(new TCO_SetupValue("FP_GP_Maschinenzustand_Heigt", "4"));
            fValList.Add(new TCO_SetupValue("FP_GP_Terminierung_Reihenfolge", "0"));
            fValList.Add(new TCO_SetupValue("FP_GP_Taktbasis", "1"));
            fValList.Add(new TCO_SetupValue("FP_Auftragseingabe_Loadlist_FormCreate", "0"));
            fValList.Add(new TCO_SetupValue("FP_GP_Balken_linksbuendig", "0"));
            fValList.Add(new TCO_SetupValue("FP_Eingabe_Ref_Zyklus", "0"));
            fValList.Add(new TCO_SetupValue("FP_Artikelnotiz_beim_Planen", "0"));
            fValList.Add(new TCO_SetupValue("FP_Editieren_beim_Planen", "0"));
            fValList.Add(new TCO_SetupValue("CTR_OEE_Auftragsmangel_SillstandNr", "0"));
            fValList.Add(new TCO_SetupValue("MDE_SAP_Log", "0"));
            fValList.Add(new TCO_SetupValue("INCL_VerpacktInSchichtProt", "0"));
            fValList.Add(new TCO_SetupValue("CGI_StillstandNachStartBuchen", "0"));
            fValList.Add(new TCO_SetupValue("INCL_ArbeitsfreiStartNachKalender", "0"));
            fValList.Add(new TCO_SetupValue("SPEZ_Pruefplan", "0"));
            fValList.Add(new TCO_SetupValue("WS_Save_Password_Sec", "0"));
            fValList.Add(new TCO_SetupValue("MG_Stillstand_PDAExt", "0"));
            fValList.Add(new TCO_SetupValue("WS_ScanAndCheckPreformBarcode", "0"));
            fValList.Add(new TCO_SetupValue("CTR_Nutzung_mit_WS_Arbeitsfrei", "0"));
            fValList.Add(new TCO_SetupValue("IF_MatList_DeleteLast4DigitsOfJobNo", "0"));
            fValList.Add(new TCO_SetupValue("SPC_AutoConfirmMessageAfterNGoodCycles", "0"));
            fValList.Add(new TCO_SetupValue("SPC_StartCompareNCyclesAfterSetup", "0"));
            fValList.Add(new TCO_SetupValue("SPC_DeleteMessageAfterNMinutesDowntime", "0"));
            fValList.Add(new TCO_SetupValue("FP_Alternativ_Variante", "0"));
            fValList.Add(new TCO_SetupValue("NotizInWZListe", "0"));
            fValList.Add(new TCO_SetupValue("FP_GP_Show_AG_Info", "0"));
            fValList.Add(new TCO_SetupValue("FP_Werkzeug_Tagesreport", "0"));
            fValList.Add(new TCO_SetupValue("FP_Artikel_Tagesreport", "0"));
            fValList.Add(new TCO_SetupValue("WS_Etikett_Downtimes_Check", "0"));
            fValList.Add(new TCO_SetupValue("INCL_Verpackt_Schicht_Nachberechnen", "0"));
            fValList.Add(new TCO_SetupValue("INCL_KeinWP_Bei_Laufzeit_In_Schicht", "0"));
            fValList.Add(new TCO_SetupValue("IF_DelayTimeAfterJobHandleInSec", "0"));
            fValList.Add(new TCO_SetupValue("WS_Etikett_Layout_Drucker", "0"));
            fValList.Add(new TCO_SetupValue("SPC_Zeit_zum_Auftrag", "10"));
            fValList.Add(new TCO_SetupValue("WS_Etikett_drucken beim_Ruesten", "0"));
            fValList.Add(new TCO_SetupValue("CGI_IMMER_Nur_Aktuellen_Auftrag_Zeigen", "0"));
            fValList.Add(new TCO_SetupValue("INCL_TaktzeitProtokollVonComm", "0"));
            fValList.Add(new TCO_SetupValue("SPC_Delimiter", ";"));
            fValList.Add(new TCO_SetupValue("MSG_PlanungReportFlach", "0"));
            fValList.Add(new TCO_SetupValue("SPC_SAP_Protokoll", "1"));
            fValList.Add(new TCO_SetupValue("CTRL_ProduziertGleichGutMinusAusschuss", "0"));
            fValList.Add(new TCO_SetupValue("SPC_Rollenwechsel", "1"));
            fValList.Add(new TCO_SetupValue("INCL_UngeplantRuestenBerechnen", "0"));
            fValList.Add(new TCO_SetupValue("MDE_AnfahrAusschussKorrigieren", "0"));
            fValList.Add(new TCO_SetupValue("CTRL_StatMinutenVorZeitraum", "15"));
            fValList.Add(new TCO_SetupValue("SPC_DBGridMachineSpecific", "0"));
            fValList.Add(new TCO_SetupValue("SPC_IncDisplayEnddate", "0"));
            fValList.Add(new TCO_SetupValue("SPC_AuftragNr_Index", "0"));
            fValList.Add(new TCO_SetupValue("SPC_ShowPrinterDialog", "0"));
            fValList.Add(new TCO_SetupValue("MG_Stillstand_EMail", "0"));
            fValList.Add(new TCO_SetupValue("MG_Reschedule_Before_Print", "1"));
            fValList.Add(new TCO_SetupValue("SYS_PingDBAndLog", "0"));
            fValList.Add(new TCO_SetupValue("INCL_WorkorderMustRunBeforeStop", "0"));
            fValList.Add(new TCO_SetupValue("INCL_Update_Masterdata_JobStop", "0"));
            fValList.Add(new TCO_SetupValue("GLO_mehrstationenmaschine", "0"));
            fValList.Add(new TCO_SetupValue("INCL_TaktlogWaehrendRuesten", "0"));
            fValList.Add(new TCO_SetupValue("SPC_Index_Formula", "val(1)"));
            fValList.Add(new TCO_SetupValue("SPC_LinePen_Width", "1"));
            fValList.Add(new TCO_SetupValue("MDE_ManualRefresh", "0"));
            fValList.Add(new TCO_SetupValue("MDE_WS_FolgeAuftragTaktzeitUpdate", "0"));
            fValList.Add(new TCO_SetupValue("MG_DTDetail_not_from_shift", "0"));
            fValList.Add(new TCO_SetupValue("MDE_WS_AuftragAutoBeenden", "0"));
            fValList.Add(new TCO_SetupValue("INCL_SupressJobEvents", "0"));
            fValList.Add(new TCO_SetupValue("JobSetupAndRestart", "0"));
            fValList.Add(new TCO_SetupValue("WS_MDE_VorabRuestenZeit", "0"));
            fValList.Add(new TCO_SetupValue("FP_WZB_Anfrage", "0"));
            fValList.Add(new TCO_SetupValue("FP_Energiebedarf", "0"));
            fValList.Add(new TCO_SetupValue("IF_UpdateStammGewichtAusMaterialListe", "0"));
            fValList.Add(new TCO_SetupValue("FP_GrundEnergiebedarf", "0"));
            fValList.Add(new TCO_SetupValue("FP_MaximalEnergiebedarf", "0"));
            fValList.Add(new TCO_SetupValue("INCL_AfterCheckDowntime", "1"));
            fValList.Add(new TCO_SetupValue("FP_Menue_Planung_Only_From_Setup", "1"));
            fValList.Add(new TCO_SetupValue("INCL_AutoSetup2Time", "0"));
            fValList.Add(new TCO_SetupValue("FP_Menue_Planung_Limited_By_Setup", "0"));
            fValList.Add(new TCO_SetupValue("MDE_CTR_FP_ProduziertBuchen", "0"));
            fValList.Add(new TCO_SetupValue("MDE_RuestProtokoll_Kumuliert", "0"));
            fValList.Add(new TCO_SetupValue("ERP_GeplanteAuftraegeLoeschen", "1"));
            fValList.Add(new TCO_SetupValue("MDE_AusschussProt_NurInParetoSichtbareGrunde", "0"));
            fValList.Add(new TCO_SetupValue("FP_AnzahlPruefwerteInPruefplan", "8"));
            fValList.Add(new TCO_SetupValue("SPC_TargetFromPruefplan", "0"));
            fValList.Add(new TCO_SetupValue("FP_BasispfadZeichnungen", ""));
            fValList.Add(new TCO_SetupValue("ERP_VorhandenAuftraegeIgnorieren", "0"));
            fValList.Add(new TCO_SetupValue("ERP_BookAbsolutePackScrapVals", "1"));
            fValList.Add(new TCO_SetupValue("INCL_InsertDowntimeWOStart", "0"));
            fValList.Add(new TCO_SetupValue("CGI_PruefplanAnzeige", "0"));
            fValList.Add(new TCO_SetupValue("FP_FolgeStufen_Automatisch_Einplanen_Ab", "-1"));
            fValList.Add(new TCO_SetupValue("CGI_Auftraege_nicht_unterbrechen", "0"));
            fValList.Add(new TCO_SetupValue("CGI_Material_und_GRN", "0"));
            fValList.Add(new TCO_SetupValue("CGI_KavitaetAendern", "1"));
            fValList.Add(new TCO_SetupValue("CGI_FollowUpOrderOnMainScreen", "0"));
            fValList.Add(new TCO_SetupValue("MDE_MaterialDeliveryToSiloForMaterialGroup", "-1"));
            fValList.Add(new TCO_SetupValue("MDE_PutMoreThanCurrentLevel", "1"));
            fValList.Add(new TCO_SetupValue("MDE_SiloThresholdForMaterialChange", "0"));
            fValList.Add(new TCO_SetupValue("Drucken_aus_BCDruckProt_in_MDE", "1"));
            fValList.Add(new TCO_SetupValue("CGI_MinutesToStartScheduledJobEarlier", "0"));
            fValList.Add(new TCO_SetupValue("CGI_ForceGRNEntryAfterSetupIfNotBooked", "0"));
            fValList.Add(new TCO_SetupValue("CGI_CycleAdditionallyInBottlesPerHour", "0"));
            fValList.Add(new TCO_SetupValue("FP_ScrapCoefficientONPlanning", "0"));
            fValList.Add(new TCO_SetupValue("INCL_SSCC_PREFIX", "0"));
            fValList.Add(new TCO_SetupValue("INCL_SSCC_IncrementResetAt", "0"));
            fValList.Add(new TCO_SetupValue("FP_LabelCopyPerJob", "0"));
            fValList.Add(new TCO_SetupValue("MDE_PackenBuchen", "0"));
            fValList.Add(new TCO_SetupValue("MDC_defaultdtfilter", "0"));
            fValList.Add(new TCO_SetupValue("CGI_DowntimesPastBooking", "0"));
            fValList.Add(new TCO_SetupValue("ERP_DisablePDEUpdateOnJobEvents", "0"));
            fValList.Add(new TCO_SetupValue("ERP_CheckLicenseBeforeBookGood", "0"));
            fValList.Add(new TCO_SetupValue("MDE_MJANote", "0"));
            fValList.Add(new TCO_SetupValue("FP_MDE_CycleTimeInMinutes", "0"));
            fValList.Add(new TCO_SetupValue("FP_AuftragReaktivieren", "1"));
            fValList.Add(new TCO_SetupValue("CGI_ShowAdditionalInfoForSignalsGreaterThan", "0"));
            fValList.Add(new TCO_SetupValue("INCL_KGruppeInitInterval", "60"));
            fValList.Add(new TCO_SetupValue("INCL_FolgeStufenSollWertAutomatischErhoehen", "0"));
            fValList.Add(new TCO_SetupValue("MDE_WerkzeugInReparaturWaehrendBetriebsauftrag", "0"));
            fValList.Add(new TCO_SetupValue("MDE_EtikettenPetainer", "0"));
            fValList.Add(new TCO_SetupValue("CGI_ShowAmountsIncludingScrap", "0"));
            fValList.Add(new TCO_SetupValue("CGI_ForceRefreshButton", "0"));
            fValList.Add(new TCO_SetupValue("MDC_ShowMaterialList", "0"));
            fValList.Add(new TCO_SetupValue("INCL_YearsForMonthlyScrapStatistic", "-1"));
            fValList.Add(new TCO_SetupValue("MDE_Show_ProductScrap", "0"));
            fValList.Add(new TCO_SetupValue("FP_BetriebsauftragnrAlphaNumeric", "1"));
            fValList.Add(new TCO_SetupValue("FP_BetriebsauftragNrMaxLength", "0"));
            fValList.Add(new TCO_SetupValue("FP_BetriebsauftragNrForceLength", "0"));
            fValList.Add(new TCO_SetupValue("MDC_JobListOrderClause", "ORDER BY PDE.Lizenz, PDE.Startdatumzeit"));
            fValList.Add(new TCO_SetupValue("MDC_ShowRemainingPalettsInMJA", "0"));
            fValList.Add(new TCO_SetupValue("CGI_ScrapCodesFROMBookingParam", "0"));
            fValList.Add(new TCO_SetupValue("CGI_StartWithoutJob", "0"));
            fValList.Add(new TCO_SetupValue("CGI_NOJOBEnterJobNoOnStart", "0"));
            fValList.Add(new TCO_SetupValue("CGI_NOJOBCycleFromMasterData", "0"));
            fValList.Add(new TCO_SetupValue("MDE_EditVirtualMachineGroups", "0"));
            fValList.Add(new TCO_SetupValue("CGI_BookScrap", "1"));
            fValList.Add(new TCO_SetupValue("CGI_ShowCavityInMachine", "1"));
            fValList.Add(new TCO_SetupValue("CGI_BigBagsName", ""));
            fValList.Add(new TCO_SetupValue("CGI_JobListOrderClause", "order by pde.Startdatumzeit"));
            fValList.Add(new TCO_SetupValue("CGI_JoblistAsTable", "0"));
            fValList.Add(new TCO_SetupValue("WS_Ausschuss_auf_VorgaengerStufe", "0"));
            fValList.Add(new TCO_SetupValue("FP_KeepSetupTimeOnUnSched", "0"));
            fValList.Add(new TCO_SetupValue("FP_CloseMultiStageConfirmAfterSecs", "0"));
            fValList.Add(new TCO_SetupValue("CGI_ShowMoldInMachine", "0"));
            fValList.Add(new TCO_SetupValue("CGI_ShowMaterialComment", "0"));
            fValList.Add(new TCO_SetupValue("MDC_ShowMoldInMaterialDemand", "0"));
            fValList.Add(new TCO_SetupValue("FP_JobnoSplitPoint", "15"));
            fValList.Add(new TCO_SetupValue("FP_JobnoSplitSuffixLength", "2"));
            fValList.Add(new TCO_SetupValue("FP_DeleteOnlyifPartNo", "1"));
            fValList.Add(new TCO_SetupValue("INCL_RunningChangeOnPrintRequest", "0"));
            fValList.Add(new TCO_SetupValue("RF_AllowMachineChange", "0"));
            fValList.Add(new TCO_SetupValue("MDE_AuftragsArchivProduziertBuchen", "0"));
            fValList.Add(new TCO_SetupValue("FP_MoveKombiStages", "0"));
            fValList.Add(new TCO_SetupValue("INCL_InternalMaterialEANFromSequence", "0"));
            fValList.Add(new TCO_SetupValue("MDE_TagesWochen_Statistik", "0"));
            fValList.Add(new TCO_SetupValue("MDE_Schicht_Statistik", "0"));
            fValList.Add(new TCO_SetupValue("INCL_CustomerReportLogo", "0"));
            fValList.Add(new TCO_SetupValue("FP_ModifyMaintenanceJobs", "1"));
            fValList.Add(new TCO_SetupValue("MDE_ShowPhysStateOnSetup", "0"));
            fValList.Add(new TCO_SetupValue("INCL_MoldStateFromStateInt", "0"));
            fValList.Add(new TCO_SetupValue("MDC_flexibleDashboard", "0"));
            fValList.Add(new TCO_SetupValue("CGI_DowntimesPastBookingCount", "10"));
            fValList.Add(new TCO_SetupValue("MDC_OEETargetPerMachine", "0"));
            fValList.Add(new TCO_SetupValue("INCL_PersonalKalender", "0"));
            fValList.Add(new TCO_SetupValue("CGI_BlockedAndApproved", "0"));
            fValList.Add(new TCO_SetupValue("CGI_GRNFromPrecedessor", "0"));
            fValList.Add(new TCO_SetupValue("MSG_SaveReportCopy", "0"));
            fValList.Add(new TCO_SetupValue("INCL_RetropectiveScrap", "0"));
            fValList.Add(new TCO_SetupValue("CGI_ShowShiftProductivity", "0"));
            fValList.Add(new TCO_SetupValue("FP_MoldFromStage", "0"));
            fValList.Add(new TCO_SetupValue("FP_MeldungBeiUmplanen", "0"));
            fValList.Add(new TCO_SetupValue("ERP_WerkzeugProMaschine", "0"));
            fValList.Add(new TCO_SetupValue("MDC_ShowCycles", "0"));
            fValList.Add(new TCO_SetupValue("MDC_ShowProducedInDashboard", "1"));
            fValList.Add(new TCO_SetupValue("FP_StammdatenAnlegenBeimPlanen", "0"));
            fValList.Add(new TCO_SetupValue("INCL_SkipRecalcAndSetuptimesWithCalendar", "0"));
            fValList.Add(new TCO_SetupValue("MDC_JobListWithTool", "0"));
            fValList.Add(new TCO_SetupValue("CGI_DTFromMachineType", "0"));
            fValList.Add(new TCO_SetupValue("MJA_SurpressSFHeader", "0"));
            fValList.Add(new TCO_SetupValue("MJA_ShowDetailRow", "0"));
            fValList.Add(new TCO_SetupValue("MJA_OfflineInSF", "0"));
            fValList.Add(new TCO_SetupValue("MJA_SFDefaultGroup", "-1"));
            fValList.Add(new TCO_SetupValue("MJA_DefaultPage", "Default.aspx"));
            fValList.Add(new TCO_SetupValue("MJA_SFGroupsFromUser", "0"));
            fValList.Add(new TCO_SetupValue("MDE_ArtArchBuAlleBAs", "0"));
            fValList.Add(new TCO_SetupValue("FP_CheckExistingWorkorder", "1"));
            fValList.Add(new TCO_SetupValue("INCL_ZeroProducedMaschinfDuringSetup", "0"));
            fValList.Add(new TCO_SetupValue("CGI_BPHSTDSTDCav", "0"));
            fValList.Add(new TCO_SetupValue("SVC_ForceAutoStartAtPCNT", "0"));
            fValList.Add(new TCO_SetupValue("MJA_SFJobListConfirmation", "0"));
            fValList.Add(new TCO_SetupValue("MJA_MSFLANGUAGE", "de-DE"));
            fValList.Add(new TCO_SetupValue("FP_PartAndTool_FromMJA", "0"));
            fValList.Add(new TCO_SetupValue("FP_PartAndTool_FromMJA_BaseURL", "http://localhost/mdc/"));
            fValList.Add(new TCO_SetupValue("INCL_RecoverInterruptSignals", "0"));
            fValList.Add(new TCO_SetupValue("MDE_SchichtWerteKorrigieren", "0"));
            fValList.Add(new TCO_SetupValue("WS_DirectMultiOpt", "0"));
            fValList.Add(new TCO_SetupValue("CGI_CavityChangeComment", "0"));
            fValList.Add(new TCO_SetupValue("MJA_SFDefaultScrapValue", ""));
            fValList.Add(new TCO_SetupValue("INCL_BDAFromSignals", "0"));
            fValList.Add(new TCO_SetupValue("MJA_mShopFlorRaisableBDA", ""));
            fValList.Add(new TCO_SetupValue("INCL_ReportUpdateDTANDScrapCodes", "0"));
            fValList.Add(new TCO_SetupValue("MJA_FetchNullUser", "0"));
            fValList.Add(new TCO_SetupValue("MJA_DefaultUserID", ""));
            fValList.Add(new TCO_SetupValue("MJA_SFShowAllJobsInList", "0"));
            fValList.Add(new TCO_SetupValue("INCL_MoldLifeTimeInGraphic", "0"));
            fValList.Add(new TCO_SetupValue("ERP_BookAlsoNegativeGood", "0"));
            fValList.Add(new TCO_SetupValue("INCL_CopySiloOnStart", "0"));
            fValList.Add(new TCO_SetupValue("FP_MaterialStufenverwaltung", "0"));
            fValList.Add(new TCO_SetupValue("CGI_DTCodeLength", "25"));
            fValList.Add(new TCO_SetupValue("CGI_RuestenNichtMehrfach", "0"));
            fValList.Add(new TCO_SetupValue("CGI_WebWSNurWSGruppenVonDNS", "0"));
            fValList.Add(new TCO_SetupValue("IF_KMaterialInStammdaten", "0"));
            fValList.Add(new TCO_SetupValue("MDE_ChargenZuordnungLoeschen", "0"));
            fValList.Add(new TCO_SetupValue("INCL_PrescheduledJobStart", "0"));
            fValList.Add(new TCO_SetupValue("CGI_PreDefNotes", "0"));
            fValList.Add(new TCO_SetupValue("ERP_ArchivAuftraegeLoeschen", "1"));
            fValList.Add(new TCO_SetupValue("CGI_SortDTCodes", "0"));
            fValList.Add(new TCO_SetupValue("CGI_BPHFROMIF", "0"));
            fValList.Add(new TCO_SetupValue("INCL_CavityChangePeriod", "60"));
            fValList.Add(new TCO_SetupValue("FP_BetriebsAuftragnrSperren", "0"));
            fValList.Add(new TCO_SetupValue("CGI_Auftraege_Starten", "1"));
            fValList.Add(new TCO_SetupValue("CGI_Auftraege_Beenden", "1"));
            fValList.Add(new TCO_SetupValue("INCL_ConventionalExcelExport", "0"));
            fValList.Add(new TCO_SetupValue("MDC_ffGeneralAsFormat", "0"));
            fValList.Add(new TCO_SetupValue("MDC_DecimalSeparator", ","));
            fValList.Add(new TCO_SetupValue("WWS_RefreshPeriodSecMain", "30"));
            fValList.Add(new TCO_SetupValue("WWS_RefreshPeriodSecPMMain", "15"));
            fValList.Add(new TCO_SetupValue("INCL_MJAInterruptedDescr", "0"));
            fValList.Add(new TCO_SetupValue("MDC_IncludePerfVars", "0"));
            fValList.Add(new TCO_SetupValue("INCL_AliveTimerWithoutTrigger", "0"));
            fValList.Add(new TCO_SetupValue("IF_MaterialPosErsetzen", "0"));
            fValList.Add(new TCO_SetupValue("IF_MaterialKeinUpdate", "0"));
            fValList.Add(new TCO_SetupValue("FP_NeuAuftrag_Artikel_Bezeichnung_Mutex", "0"));
            fValList.Add(new TCO_SetupValue("CGI_ShowPackSize", "0"));
            fValList.Add(new TCO_SetupValue("MDE_NoEditFinishedRepair", "0"));
            fValList.Add(new TCO_SetupValue("ERP_RuestenUnterbrechenBeiEvent_E", "0"));
            fValList.Add(new TCO_SetupValue("ERP_RuestgrundNachUnterbrechen_E", "0"));
            fValList.Add(new TCO_SetupValue("INCL_ZellenfertigungLinieSimultan", "0"));
            fValList.Add(new TCO_SetupValue("FP_EditRunningJobs", "1"));
            fValList.Add(new TCO_SetupValue("INCL_VerpacktProt_aus_Aarchiv_und_AusschussProt", "0"));
            fValList.Add(new TCO_SetupValue("INCL_SpcStichInDB", "1"));
            fValList.Add(new TCO_SetupValue("INCL_SpcStichExportPfad", " "));
            fValList.Add(new TCO_SetupValue("INCL_SpcSollGleichMittelwert", "0"));
            fValList.Add(new TCO_SetupValue("INCL_SPCSchussProKarton", "0"));
            fValList.Add(new TCO_SetupValue("FP_PDEStammDefaultLayout", ""));
            fValList.Add(new TCO_SetupValue("FP_PDEStammDefaultLayout2", ""));
            fValList.Add(new TCO_SetupValue("ERP_KundenReferenzAlsBinaerBool", "0"));
            fValList.Add(new TCO_SetupValue("INCL_NurSollWertOffsetErhoehen", "0"));
            fValList.Add(new TCO_SetupValue("FP_ForcePdeKudetail", "0"));
            fValList.Add(new TCO_SetupValue("INCL_JobStartWithoutMOldState", "0"));
            fValList.Add(new TCO_SetupValue("MDC_CustomerReferenceInShiftLog", "0"));
            fValList.Add(new TCO_SetupValue("MDE_ReparaturArten", "0"));
            fValList.Add(new TCO_SetupValue("INCL_RepairWithoutMoldStateChange", "0"));
            fValList.Add(new TCO_SetupValue("INCL_MoldRepairWithMoldList", "0"));
            fValList.Add(new TCO_SetupValue("FP_MoldRepairOnScheduled", ""));
            fValList.Add(new TCO_SetupValue("MDE_ChaoticMoldStore", "0"));
            fValList.Add(new TCO_SetupValue("MDE_MoldRepairChoosePart", "0"));
            fValList.Add(new TCO_SetupValue("INCL_GRNOncePerMO", "0"));
            fValList.Add(new TCO_SetupValue("INCL_SuppresMoldList", "1"));
            fValList.Add(new TCO_SetupValue("MDE_ChoosePartForScrapPareto", "0"));
            fValList.Add(new TCO_SetupValue("INCL_LeaveDownTimeOnJobStart", "0"));
            fValList.Add(new TCO_SetupValue("MDE_ReadOnly", "0"));
            fValList.Add(new TCO_SetupValue("FP_NoteSizeInReport", "7"));
            fValList.Add(new TCO_SetupValue("INCL_CheckAddToolsOnStart", "0"));
            fValList.Add(new TCO_SetupValue("FP_MoldRepairOnScheduledDeletion", "0"));
            fValList.Add(new TCO_SetupValue("MDE_ReparaturStufen", "0"));
            fValList.Add(new TCO_SetupValue("MDE_AlleReparaturenSchliessen", "0"));
            fValList.Add(new TCO_SetupValue("MJA_XtraReportWebServiceURL", ""));
            fValList.Add(new TCO_SetupValue("INCL_SVCDontWriteCavityForXminutes", "0"));
            fValList.Add(new TCO_SetupValue("INCL_MoldCycleFromCoreSvc", "0"));
            fValList.Add(new TCO_SetupValue("FP_HideZeroScheduledReport", "0"));
            fValList.Add(new TCO_SetupValue("FP_PlanReportShowCalendar", "0"));
            fValList.Add(new TCO_SetupValue("FP_ReparaturPlanung", "0"));
            fValList.Add(new TCO_SetupValue("FP_AuftragsGrafikFarbeausWerkzeug", "0"));
            fValList.Add(new TCO_SetupValue("FP_WZBarBigSize", "0"));
            fValList.Add(new TCO_SetupValue("FP_GraphicReportLegend", "0"));
            fValList.Add(new TCO_SetupValue("FP_DetailKavitaetAusERP", "0"));
            fValList.Add(new TCO_SetupValue("MSG_MaxScrapPerShift", "0"));
            fValList.Add(new TCO_SetupValue("MSG_WarnOnMachineRunningWithoutJob", "0"));
            fValList.Add(new TCO_SetupValue("FP_PersKalenderOhnePW", "0"));
            fValList.Add(new TCO_SetupValue("FP_PDEStammDefaultLayout3", ""));
            fValList.Add(new TCO_SetupValue("INCL_AvgCycleTolerancePercent", "50"));
            fValList.Add(new TCO_SetupValue("MDE_Taktzeit_Show_Filtered_Average", "1"));
            fValList.Add(new TCO_SetupValue("INCL_StartenMitReparatur", "0"));
            fValList.Add(new TCO_SetupValue("MDE_ScrapTopFive", "0"));
            fValList.Add(new TCO_SetupValue("MSG_Messenger2", "0"));
            fValList.Add(new TCO_SetupValue("INCL_ProducedInShiftWithoutSetup", "0"));
            fValList.Add(new TCO_SetupValue("INCL_WZLager", "1"));
            fValList.Add(new TCO_SetupValue("INCL_WZLaufzeitwarnung", "0"));
            fValList.Add(new TCO_SetupValue("INCL_TaktToleranz_AbsolutInSekunden", "-1"));
            fValList.Add(new TCO_SetupValue("INCL_Negative_Mold_Lifetime", "0"));
            fValList.Add(new TCO_SetupValue("INCL_RemainTime_Gross", "0"));
            fValList.Add(new TCO_SetupValue("INCL_Correct_MasterAuftrag", "0"));
            fValList.Add(new TCO_SetupValue("FP_PlanReportShowCalendarOnTop", "0"));
            fValList.Add(new TCO_SetupValue("INCL_Restlaufzeit_Aus_AuftragsKav", "0"));
            fValList.Add(new TCO_SetupValue("FP_AlivetimerApps", "'SAPInterface','ERPInterface'"));
            fValList.Add(new TCO_SetupValue("WS_Immer_Rahmen", "0"));
            fValList.Add(new TCO_SetupValue("FP_WarnungTaktNull", "0"));
            fValList.Add(new TCO_SetupValue("SPC_MittelWertAnzahl", "10"));
            fValList.Add(new TCO_SetupValue("SPC_MittelWertMaxStilllDauer", "0"));
            fValList.Add(new TCO_SetupValue("SPC_MittelWertMaxAbweichung_Prozent", "10"));
            fValList.Add(new TCO_SetupValue("SPC_Abweichung_Nachfolgend", "5"));
            fValList.Add(new TCO_SetupValue("SPC_Abweichung_AnzahlIn_Stichprobe", "10"));
            fValList.Add(new TCO_SetupValue("SPC_Groesse_Stichprobe", "100"));
            fValList.Add(new TCO_SetupValue("SVC_BuchungBeiKavWechsel", "1"));
            fValList.Add(new TCO_SetupValue("INCL_AutoPauseNurBeiUngebuchtemStillstand", "1"));
            fValList.Add(new TCO_SetupValue("MDE_ZeigeWerkzeugErinnerung", "1"));
            fValList.Add(new TCO_SetupValue("INCL_NewDownTimeOnJobStart", "0"));
            fValList.Add(new TCO_SetupValue("INCL_Increment_Mold_Lifetime2", "1"));
            fValList.Add(new TCO_SetupValue("FP_Days_Past", "60"));
            fValList.Add(new TCO_SetupValue("FP_Days_Future", "365"));
            fValList.Add(new TCO_SetupValue("MJA_Repair_Email_Categories", ""));
            fValList.Add(new TCO_SetupValue("MJA_Repair_Show_Preparationtime", "0"));
            fValList.Add(new TCO_SetupValue("FP_ChangeProductionOrderAmount", "0"));
            fValList.Add(new TCO_SetupValue("FP_WerkzeugAendern_BeimEinplanen", "1"));
            fValList.Add(new TCO_SetupValue("INCL_KapaFaktor_ProMaschine", "0"));
            fValList.Add(new TCO_SetupValue("FP_WzStatusStattKommentar", "0"));
            fValList.Add(new TCO_SetupValue("INCL_AutostartZeitNachRuesten", "0"));
            fValList.Add(new TCO_SetupValue("IF_ExportAllePdeEventESchichtwechsel", "0"));
            fValList.Add(new TCO_SetupValue("INCL_UpdateTaktzeitFolgeauftraege", "0"));
            fValList.Add(new TCO_SetupValue("INCL_ShiftProducedWithoutRuntime", "0"));
            fValList.Add(new TCO_SetupValue("ERP_VorhandeneAuftraegeErneutUebertragen", "0"));
            fValList.Add(new TCO_SetupValue("INCL_SOAHandling", "0"));
            fValList.Add(new TCO_SetupValue("INCL_MoldPrewarningsFromBdaSvc", "0"));
            fValList.Add(new TCO_SetupValue("Wartung_Verlaengert_Auftrag", "0"));
            fValList.Add(new TCO_SetupValue("FP_TimeStepFilterCustomSteps", ""));
            fValList.Add(new TCO_SetupValue("MJA_Activate_Mustern", "0"));
        }

        /// <summary>
        /// Get setup value by key name
        /// </summary>
        public TCO_SetupValue Value(string AIndex)
        {
            return GetItem(AIndex);
        }

        /// <summary>
        /// Get setup value by index
        /// </summary>
        public TCO_SetupValue ValueByNr(int AIndex)
        {
            return GetItemByNr(AIndex);
        }

        /// <summary>
        /// Get count of setup values
        /// </summary>
        public int Count
        {
            get { return GetCount(); }
        }

        private int GetCount()
        {
            return fValList.Count;
        }

        private TCO_SetupValue GetItem(string AIndex)
        {
            TCO_SetupValue result = null;
            
            for (int i = 0; i < fValList.Count; i++)
            {
                if (fValList[i].KeyName == AIndex)
                {
                    result = fValList[i];
                    break;
                }
            }

            if (result == null)
            {
                for (int i = 0; i < fSetupList.Count; i++)
                {
                    if (fSetupList[i].KeyName == AIndex)
                    {
                        result = fSetupList[i];
                        break;
                    }
                }
            }

            // If not found, don't throw exception (as in Delphi code)
            return result;
        }

        private TCO_SetupValue GetItemByNr(int AIndex)
        {
            if (AIndex >= 0 && AIndex < fValList.Count)
                return fValList[AIndex];
            return null;
        }

        /// <summary>
        /// Get parameter value as string
        /// </summary>
        public static string GetParam(CO_Query aQuery, string aParameter, bool aDirect = false)
        {
            lock (CS_CO_Setup)
            {
                try
                {
                    if (CCO_Setup == null)
                    {
                        CCO_Setup = new TCO_Setup(aQuery);
                    }
                    if (aDirect)
                    {
                        CCO_Setup.RefreshList();
                    }
                    TCO_SetupValue val = CCO_Setup.GetItem(aParameter);
                    if (val != null)
                        return val.CurrVal;
                    else
                        return string.Empty;
                }
                catch (Exception)
                {
                    return string.Empty;
                }
            }
        }

        /// <summary>
        /// Get parameter value as boolean
        /// </summary>
        public static bool GetParamBool(CO_Query aQuery, string aParameter, bool aDirect = false)
        {
            string S = GetParam(aQuery, aParameter, aDirect);
            return (S != "0") && (S != "") && (S != " ");
        }

        /// <summary>
        /// Get parameter value as integer
        /// </summary>
        public static int GetParamInt(CO_Query aQuery, string aParameter, bool aDirect = false)
        {
            string S = GetParam(aQuery, aParameter, aDirect);
            try
            {
                return int.Parse(S);
            }
            catch (Exception)
            {
                return 0;
            }
        }

        /// <summary>
        /// Get parameter value as double
        /// </summary>
        public static double GetParamDouble(CO_Query aQuery, string aParameter, bool aDirect = false)
        {
            string S = GetParam(aQuery, aParameter, aDirect);
            try
            {
                S = S.Replace(".", CultureInfo.CurrentCulture.NumberFormat.NumberDecimalSeparator);
                return double.Parse(S, CultureInfo.CurrentCulture);
            }
            catch (Exception)
            {
                return 0;
            }
        }

        /// <summary>
        /// Get parameter value as string
        /// </summary>
        public static string GetParamStr(CO_Query aQuery, string aParameter, bool aDirect = false)
        {
            return GetParam(aQuery, aParameter, aDirect);
        }

        /// <summary>
        /// Set parameter value (boolean)
        /// </summary>
        public static void SetParam(CO_Query aQuery, string aParameter, bool AValue, bool writeToDb = true)
        {
            SetParam(aQuery, aParameter, AValue ? "1" : "0", writeToDb);
        }

        /// <summary>
        /// Set parameter value (integer)
        /// </summary>
        public static void SetParam(CO_Query aQuery, string aParameter, int AValue, bool writeToDb = true)
        {
            SetParam(aQuery, aParameter, AValue.ToString(), writeToDb);
        }

        /// <summary>
        /// Set parameter value (double)
        /// </summary>
        public static void SetParam(CO_Query aQuery, string aParameter, double AValue, bool writeToDb = true)
        {
            SetParam(aQuery, aParameter, AValue.ToString(CultureInfo.InvariantCulture), writeToDb);
        }

        /// <summary>
        /// Set parameter value (string)
        /// </summary>
        public static void SetParam(CO_Query aQuery, string aParameter, string AValue, bool writeToDb = true)
        {
            lock (CS_CO_Setup)
            {
                try
                {
                    if (CCO_Setup == null)
                    {
                        CCO_Setup = new TCO_Setup(aQuery);
                    }
                    TCO_SetupValue V = CCO_Setup.GetItem(aParameter);
                    if (V != null)
                    {
                        V.CurrVal = AValue;
                        if (writeToDb)
                        {
                            V.Save(aQuery);
                        }
                    }
                }
                catch (Exception ex)
                {
                    MainDLL.SchreibeMeldung("Error in SetParam: " + ex.Message, 0);
                }
            }
        }

        /// <summary>
        /// Refresh the setup list from database
        /// </summary>
        public void RefreshList()
        {
            try
            {
                string sql = "SELECT * FROM setup_par order by nr";
                FQuery.SQL.Text = sql;
                FQuery.Open();
                
                while (!FQuery.EOF)
                {
                    TCO_SetupValue _val = null;
                    try
                    {
                        _val = GetItem(FQuery.FieldByName("schluessel").AsString);
                    }
                    catch (Exception)
                    {
                        _val = null;
                    }

                    if (_val != null)
                    {
                        try
                        {
                            _val.CurrVal = FQuery.FieldByName("wert").AsString;
                            _val.Exists = true;
                        }
                        catch (Exception)
                        {
                            _val.CurrVal = string.Empty;
                        }
                    }
                    FQuery.Next();
                }

                // Add missing parameters to database
                for (int i = 0; i < fValList.Count; i++)
                {
                    if (!fValList[i].Exists)
                    {
                        string sql2 = "SELECT MAX(Nr)+1 cnt FROM Setup_Par";
                        FQuery.SQL.Text = sql2;
                        FQuery.Open();
                        int j = FQuery.FieldByName("CNT").AsInteger;
                        
                        sql2 = "insert into Setup_Par (Nr, Schluessel, Wert) values (" + j + 
                            ", '" + fValList[i].KeyName.Replace("'", "''") + 
                            ", '" + fValList[i].DefVal.Replace("'", "''") + "')";
                        try
                        {
                            FQuery.ExecSQL(sql2);
                        }
                        catch (Exception)
                        {
                            // Retry with new max
                            sql2 = "SELECT MAX(Nr)+1 cnt FROM Setup_Par";
                            FQuery.SQL.Text = sql2;
                            FQuery.Open();
                            j = FQuery.FieldByName("CNT").AsInteger;
                            sql2 = "insert into Setup_Par (Nr, Schluessel, Wert) values (" + j + 
                                ", '" + fValList[i].KeyName.Replace("'", "''") + 
                                ", '" + fValList[i].DefVal.Replace("'", "''") + "')";
                            FQuery.ExecSQL(sql2);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in RefreshList: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Static initialization
        /// </summary>
        public static void Initialize()
        {
            CCO_Setup = null;
        }

        /// <summary>
        /// Static cleanup
        /// </summary>
        public static void FinalizeSetup()
        {
            if (CCO_Setup != null)
            {
                try
                {
                    CCO_Setup = null;
                }
                catch (Exception) { }
            }
        }
    }
}
