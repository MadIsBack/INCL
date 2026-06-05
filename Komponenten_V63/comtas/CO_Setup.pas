unit CO_Setup;

(*
  Neue Parameter nur über CO_Setup2 !!!
  CO_Setup nur noch für Kompatibilität mit altem Quellcode
*)

interface

uses
  CO_DataBase, SysUtils, CO_Setup2;

// const

  {
    INCL_Days_TPM_Auswertung = 'INCL_Days_TPM_Auswertung';
    INCL_Berech_TPM_Produktion = 'INCL_Berech_TPM_Produktion';
    MDE_Show_Material = 'MDE_Show_Material';
    MDE_Show_TPM_Grafik = 'MDE_Show_TPM_Grafik';
    INCL_Schichtberechnung1 = 'INCL_Schichtberechnung1';
    MDE_WZ_Automatich_vom_Reparatur = 'MDE_WZ_Automatich_vom_Reparatur';
    FP_Offline_nur_ein_Tag = 'FP_Offline_nur_ein_Tag';
    FP_Update_WZ_in_Stamm = 'FP_Update_WZ_in_Stamm';
    WS_Personal_und_Zeit_eingeben = 'WS_Personal_und_Zeit_eingeben';
    WS_Stillstand_Manuell = 'WS_Stillstand_Manuell';
    INCL_Stillog_Arc_Tag = 'INCL_Stillog_Arc_Tag';
    INCL_TPM_Schicht_Pruefen_Tag = 'INCL_TPM_Schicht_Pruefen_Tag';
    MDE_LZBalken_Width = 'MDE_LZBalken_Width';
    CGI_Stillstand_abjetzt = 'CGI_Stillstand_abjetzt';
    MDE_Everytime_Signal2 = 'MDE_Everytime_Signal2';
    WS_Gewicht_Gramm_Buchen_KG = 'WS_Gewicht_Gramm_Buchen_KG';
    WS_Nur_laufende_Buchen = 'WS_Nur_laufende_Buchen';
    INCL_Recalculation_am = 'INCL_Recalculation_am';
    WS_Ruesten_gesperrt = 'WS_Ruesten_gesperrt';
    WS_Ausschuss_Sollwert_hoch = 'WS_Ausschuss_Sollwert_hoch';
    WS_AARchiv_Personal_vom_Buchen = 'WS_AARchiv_Personal_vom_Buchen';
    WS_Maschinenzustand_Ruesten_Gelb = 'WS_Maschinenzustand_Ruesten_Gelb';
    WS_SortStillstandName = 'WS_SortStillstandName';
    FP_Infofenster_breiter = 'FP_Infofenster_breiter';
    FP_MDE_Navigator_Alle_Maschinen = 'FP_MDE_Navigator_Alle_Maschinen';
    MDE_Taktzeit_Pass_Abfrage = 'MDE_Taktzeit_Pass_Abfrage';
    FP_Wunschmaschine = 'FP_Wunschmaschine';
    FP_UpdateStammDaten = 'FP_UpdateStammDaten';
    MDE_Delete_Jobs_Ohne_Wartung = 'MDE_Delete_Jobs_Ohne_Wartung';
    FP_MDE_Password_einmal_abfragen = 'FP_MDE_Password_einmal_abfragen';
    MDE_Stillstandsprotokoll_Refresh = 'MDE_Stillstandsprotokoll_Refresh';
    Minibase_Archive_Backup = 'Minibase_Archive_Backup';
    MDE_Ausschuss_Schicht = 'MDE_Ausschuss_Schicht';
    INCL_TPM_Verpackt_Ausschuss = 'INCL_TPM_Verpackt_Ausschuss';
    INCL_Menge_Schicht_mit_Manuell = 'INCL_Menge_Schicht_mit_Manuell';
    MDE_AArchiv_Menge_Korrektur = 'MDE_AArchiv_Menge_Korrektur';
    INCL_Verpackt_nicht_Schicht_bezogen = 'INCL_Verpackt_nicht_Schicht_bezogen';
    MDE_Zeit_zwischen_AuftragsStart_Ende = 'MDE_Zeit_zwischen_AuftragsStart_Ende';
    MDE_gemittelte_Isttakt_zeigen = 'MDE_gemittelte_Isttakt_zeigen';
    INCL_Auftragsende_immer_berechnen = 'INCL_Auftragsende_immer_berechnen';
    MDE_Maschinf_Report_Hochformat = 'MDE_Maschinf_Report_Hochformat';
    FP_Aufloesen_Zwischenauftraege = 'FP_Aufloesen_Zwischenauftraege';
    CGI_WS_Ruesten_laufender_Auftrag = 'CGI_WS_Ruesten_laufender_Auftrag';
    FP_Mehrstufige_Markieren = 'FP_Mehrstufige_Markieren';
    INCL_TPM_Schicht_Verpackt_Ausschuss = 'INCL_TPM_Schicht_Verpackt_Ausschuss';
    CTRL_OEELeistung_mit_TE = 'CTRL_OEELeistung_mit_TE';
    MDE_OEE_Statistik = 'MDE_OEE_Statistik';
    CGI_Show_Only_Current_Job = 'CGI_Show_Only_Current_Job';
    Archivsmandant_Tage = 'Archivsmandant_Tage';
    CGI_Detail_Auftraege_Verwalten = 'CGI_Detail_Auftraege_Verwalten';
    FP_TemperierGeraete = 'FP_TemperierGeraete';
    WS_RechnerNr_From_USerID = 'WS_RechnerNr_From_USerID';
    CGI_TimeOut_AfterAction = 'CGI_TimeOut_AfterAction';
    MDE_Userlist_with_Userright = 'MDE_Userlist_with_Userright';

  function GetParamInt_to_delete_(Q: TCO_Query; Par: string): Integer;
  function GetParamStr_to_delete_(Q: TCO_Query; Par: string): string;
  function GetParamBool_to_delete_(Q: TCO_Query; Par: string): Boolean;

  }

implementation

{
function GetParamInt_to_delete_(Q: TCO_Query; Par: string): Integer;
begin
  Result := TCO_Setup.GetParamInt(Q, Par);
end;

function GetParamStr_to_delete_(Q: TCO_Query; Par: string): string;
begin
  Result := TCO_Setup.GetParamStr(Q, Par);
end;

function GetParamBool_to_delete_(Q: TCO_Query; Par: string): Boolean;
begin
  Result := TCO_Setup.GetParamBool(Q, Par);
end;
}

end.

