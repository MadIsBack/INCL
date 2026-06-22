namespace Komponenten_V63_CSharp
{
    public static class CO_Setup
    {
        // Constants for setup parameters
        public const string INCL_Days_TPM_Auswertung = "INCL_Days_TPM_Auswertung";
        public const string INCL_Berech_TPM_Produktion = "INCL_Berech_TPM_Produktion";
        public const string MDE_Show_Material = "MDE_Show_Material";
        public const string MDE_Show_TPM_Grafik = "MDE_Show_TPM_Grafik";
        public const string INCL_Schichtberechnung1 = "INCL_Schichtberechnung1";
        public const string MDE_WZ_Automatich_vom_Reparatur = "MDE_WZ_Automatich_vom_Reparatur";
        public const string FP_Offline_nur_ein_Tag = "FP_Offline_nur_ein_Tag";
        public const string FP_Update_WZ_in_Stamm = "FP_Update_WZ_in_Stamm";
        public const string WS_Personal_und_Zeit_eingeben = "WS_Personal_und_Zeit_eingeben";
        public const string WS_Stillstand_Manuell = "WS_Stillstand_Manuell";
        public const string INCL_Stillog_Arc_Tag = "INCL_Stillog_Arc_Tag";
        public const string INCL_TPM_Schicht_Pruefen_Tag = "INCL_TPM_Schicht_Pruefen_Tag";
        public const string MDE_LZBalken_Width = "MDE_LZBalken_Width";
        public const string CGI_Stillstand_abjetzt = "CGI_Stillstand_abjetzt";
        public const string MDE_Everytime_Signal2 = "MDE_Everytime_Signal2";
        public const string WS_Gewicht_Gramm_Buchen_KG = "WS_Gewicht_Gramm_Buchen_KG";
        public const string WS_Nur_laufende_Buchen = "WS_Nur_laufende_Buchen";
        public const string INCL_Recalculation_am = "INCL_Recalculation_am";
        public const string WS_Ruesten_gesperrt = "WS_Ruesten_gesperrt";
        public const string WS_Ausschuss_Sollwert_hoch = "WS_Ausschuss_Sollwert_hoch";
        public const string WS_AARchiv_Personal_vom_Buchen = "WS_AARchiv_Personal_vom_Buchen";
        public const string WS_Maschinenzustand_Ruesten_Gelb = "WS_Maschinenzustand_Ruesten_Gelb";
        public const string WS_SortStillstandName = "WS_SortStillstandName";
        public const string FP_Infofenster_breiter = "FP_Infofenster_breiter";
        public const string FP_MDE_Navigator_Alle_Maschinen = "FP_MDE_Navigator_Alle_Maschinen";
        public const string MDE_Taktzeit_Pass_Abfrage = "MDE_Taktzeit_Pass_Abfrage";
        public const string FP_Wunschmaschine = "FP_Wunschmaschine";
        public const string FP_UpdateStammDaten = "FP_UpdateStammDaten";
        public const string MDE_Delete_Jobs_Ohne_Wartung = "MDE_Delete_Jobs_Ohne_Wartung";
        public const string FP_MDE_Password_einmal_abfragen = "FP_MDE_Password_einmal_abfragen";
        public const string MDE_Stillstandsprotokoll_Refresh = "MDE_Stillstandsprotokoll_Refresh";
        public const string Minibase_Archive_Backup = "Minibase_Archive_Backup";
        public const string MDE_Ausschuss_Schicht = "MDE_Ausschuss_Schicht";
        public const string INCL_TPM_Verpackt_Ausschuss = "INCL_TPM_Verpackt_Ausschuss";
        public const string INCL_Menge_Schicht_mit_Manuell = "INCL_Menge_Schicht_mit_Manuell";
        public const string MDE_AArchiv_Menge_Korrektur = "MDE_AArchiv_Menge_Korrektur";
        public const string INCL_Verpackt_nicht_Schicht_bezogen = "INCL_Verpackt_nicht_Schicht_bezogen";
        public const string MDE_Zeit_zwischen_AuftragsStart_Ende = "MDE_Zeit_zwischen_AuftragsStart_Ende";
        public const string MDE_gemittelte_Isttakt_zeigen = "MDE_gemittelte_Isttakt_zeigen";
        public const string INCL_Auftragsende_immer_berechnen = "INCL_Auftragsende_immer_berechnen";
        public const string MDE_Maschinf_Report_Hochformat = "MDE_Maschinf_Report_Hochformat";
        public const string FP_Aufloesen_Zwischenauftraege = "FP_Aufloesen_Zwischenauftraege";
        public const string CGI_WS_Ruesten_laufender_Auftrag = "CGI_WS_Ruesten_laufender_Auftrag";
        public const string FP_Mehrstufige_Markieren = "FP_Mehrstufige_Markieren";
        public const string INCL_TPM_Schicht_Verpackt_Ausschuss = "INCL_TPM_Schicht_Verpackt_Ausschuss";
        public const string CTRL_OEELeistung_mit_TE = "CTRL_OEELeistung_mit_TE";
        public const string MDE_OEE_Statistik = "MDE_OEE_Statistik";
        public const string CGI_Show_Only_Current_Job = "CGI_Show_Only_Current_Job";
        public const string Archivsmandant_Tage = "Archivsmandant_Tage";
        public const string CGI_Detail_Auftraege_Verwalten = "CGI_Detail_Auftraege_Verwalten";
        public const string FP_TemperierGeraete = "FP_TemperierGeraete";
        public const string WS_RechnerNr_From_USerID = "WS_RechnerNr_From_USerID";
        public const string CGI_TimeOut_AfterAction = "CGI_TimeOut_AfterAction";
        public const string MDE_Userlist_with_Userright = "MDE_Userlist_with_Userright";

        // Functions that delegate to CO_Setup2
        public static int GetParamInt_to_delete_(CO_Query Q, string Par)
        {
            return CO_Setup2.GetParamInt(Q, Par);
        }

        public static string GetParamStr_to_delete_(CO_Query Q, string Par)
        {
            return CO_Setup2.GetParamStr(Q, Par);
        }

        public static bool GetParamBool_to_delete_(CO_Query Q, string Par)
        {
            return CO_Setup2.GetParamBool(Q, Par);
        }
    }
}
