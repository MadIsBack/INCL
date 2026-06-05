unit CO_Setup2;

interface

uses CO_DataBase, SysUtils, Classes, SyncObjs{$IFDEF DEBUG}, Dialogs{$ENDIF};

type
  TCO_SetupValue = class
  public
    DefVal: string;
    KeyName: string;
    CurrVal: string;
    Exists: Boolean;

    procedure Save(aQuery: TCO_Query);

    constructor Create(aKeyName: string; aDefVal: string);
  end;

type
  TCO_SetupList = class(TList)
  private
    function GetItems(AIndex: Integer): TCO_SetupValue;
  public
    procedure Add(aItem: TCO_SetupValue);
    property Items[AIndex: Integer]: TCO_SetupValue read GetItems;

    constructor Create;
    destructor Destroy; override;
  end;

type
  TCO_Setup = class

  private
    fValList: TCO_SetupList;
    fSetupList: TCO_SetupList;
    procedure FillList;
    procedure ChangeVals;
    procedure CreateTable;
    function GetItem(AIndex: string): TCO_SetupValue;
    function GetCount: Integer;
    function GetItemByNr(AIndex: Integer): TCO_SetupValue;
    class function GetParam(aQuery: TCO_Query; aParameter: string; aDirect: Boolean): string;

  public
    FQuery: TCO_Query;

    procedure RefreshList;
    class function GetParamInt(aQuery: TCO_Query; aParameter: string; aDirect: Boolean = False): Integer;
    class function GetParamStr(aQuery: TCO_Query; aParameter: string; aDirect: Boolean = False): string;
    class function GetParamDouble(aQuery: TCO_Query; aParameter: string; aDirect: Boolean = False): double;
    class function GetParamBool(aQuery: TCO_Query; aParameter: string; aDirect: Boolean = False): Boolean;
    class procedure SetParam(aQuery: TCO_Query; aParameter: string; AValue: Boolean; writeToDb: Boolean = true); overload;
    class procedure SetParam(aQuery: TCO_Query; aParameter: string; AValue: Integer; writeToDb: Boolean = true); overload;
    class procedure SetParam(aQuery: TCO_Query; aParameter: string; AValue: string; writeToDb: Boolean = true); overload;
    class procedure SetParam(aQuery: TCO_Query; aParameter: string; AValue: double; writeToDb: Boolean = true); overload;

    property Value[AIndex: string]: TCO_SetupValue read GetItem;
    property ValueByNr[AIndex: Integer]: TCO_SetupValue read GetItemByNr;
    property Count: Integer read GetCount;
    constructor Create(aQuery: TCO_Query);
    destructor Destroy; override;
  end;

var
  CCO_Setup: TCO_Setup;
  CS_CO_Setup: TCriticalSection;
implementation

{ TCO_Setup }

procedure TCO_Setup.ChangeVals;

  procedure ChangeIt(aOldVal, aNewVal: string);
  begin
    FQuery.SQL.Text := 'UPDATE setup_par SET schluessel = '''
      + aNewVal + ''' WHERE schluessel = '''
      + aOldVal + '''';
    FQuery.ExecSQL;
  end;

begin
  ChangeIt('INCL_HalbautomatSchlüsselschalter', 'INCL_HalbautomatSchluesselschalter');
  FQuery.SQL.Text := 'DELETE FROM setup_par WHERE nr NOT IN (SELECT MIN(nr) FROM'
    + ' setup_par GROUP BY schluessel)';
  FQuery.ExecSQL;
end;

constructor TCO_Setup.Create(aQuery: TCO_Query);
begin
  inherited Create;
  FQuery := TCO_Query.Create(aQuery.Owner);
  FQuery.Database := aQuery.Database;
  CreateTable;
  // Werte vorbelegen
  fValList := TCO_SetupList.Create;
  fSetupList := TCO_SetupList.Create;

  ChangeVals;

  FillList;


  RefreshList;
end;

procedure TCO_Setup.CreateTable;
begin
  FQuery.SQL.Text := 'select Nr from SETUP_PAR';
  try
    FQuery.Open;
  except
    FQuery.SQL.Text := 'create table Setup_Par'
      + ' (Nr Integer Primary Key,'
      + ' Schluessel varchar2(50),'
      + ' Wert varchar2(50))';
    FQuery.ExecSQL;
    FQuery.SQL.Text := 'create index Setup_PAR_Sch on Setup_Par(Schluessel)';
    FQuery.ExecSQL;
  end;

end;

destructor TCO_Setup.Destroy;
var i : integer;
begin
  //  fQuery.Destroy;
  for i := 0 to fValList.Count-1 do
    fValList.Items[i].Destroy;
  fValList.Destroy;
  inherited;
end;

procedure TCO_Setup.FillList;
var
  I: Integer;
begin
  fValList.Add(TCO_SetupValue.Create('INCL_Days_TPM_Auswertung', '3'));
  fValList.Add(TCO_SetupValue.Create('INCL_Berech_TPM_Produktion', '90'));
  fValList.Add(TCO_SetupValue.Create('MDE_Show_Material', '1'));
  fValList.Add(TCO_SetupValue.Create('MDE_Show_TPM_Grafik', '1'));
  fValList.Add(TCO_SetupValue.Create('INCL_Schichtberechnung1', '0'));
  fValList.Add(TCO_SetupValue.Create('MDE_WZ_Automatich_vom_Reparatur', '1'));
  fValList.Add(TCO_SetupValue.Create('FP_Offline_nur_ein_Tag', '1'));
  fValList.Add(TCO_SetupValue.Create('FP_Update_WZ_in_Stamm', '1'));
  fValList.Add(TCO_SetupValue.Create('WS_Personal_und_Zeit_eingeben', '1'));
  fValList.Add(TCO_SetupValue.Create('WS_Stillstand_Manuell', '0')); // 10
  fValList.Add(TCO_SetupValue.Create('INCL_Stillog_Arc_Tag', '180'));
  fValList.Add(TCO_SetupValue.Create('INCL_TPM_Schicht_Pruefen_Tag', '14'));
  fValList.Add(TCO_SetupValue.Create('MDE_LZBalken_Width', '105'));
  fValList.Add(TCO_SetupValue.Create('CGI_Stillstand_abjetzt', '0'));
  fValList.Add(TCO_SetupValue.Create('MDE_Everytime_Signal2', '0'));
  fValList.Add(TCO_SetupValue.Create('WS_Gewicht_Gramm_Buchen_KG', '0'));
  fValList.Add(TCO_SetupValue.Create('WS_Nur_laufende_Buchen', '0'));
  fValList.Add(TCO_SetupValue.Create('INCL_Recalculation_am', '00:00'));
  fValList.Add(TCO_SetupValue.Create('WS_Ruesten_gesperrt', '0'));
  fValList.Add(TCO_SetupValue.Create('WS_Ausschuss_Sollwert_hoch', '1')); // 20
  fValList.Add(TCO_SetupValue.Create('WS_AARchiv_Personal_vom_Buchen', '0'));
  fValList.Add(TCO_SetupValue.Create('WS_Maschinenzustand_Ruesten_Gelb', '1'));
  fValList.Add(TCO_SetupValue.Create('WS_SortStillstandName', '0'));
  fValList.Add(TCO_SetupValue.Create('FP_Infofenster_breiter', '0'));
  fValList.Add(TCO_SetupValue.Create('FP_MDE_Navigator_Alle_Maschinen', '0'));
  fValList.Add(TCO_SetupValue.Create('MDE_Taktzeit_Pass_Abfrage', '1'));
  fValList.Add(TCO_SetupValue.Create('FP_Wunschmaschine', '0'));
  fValList.Add(TCO_SetupValue.Create('FP_UpdateStammDaten', '0'));
  fValList.Add(TCO_SetupValue.Create('MDE_Delete_Jobs_Ohne_Wartung', '0'));
  fValList.Add(TCO_SetupValue.Create('FP_MDE_Password_einmal_abfragen', '0')); // 30
  fValList.Add(TCO_SetupValue.Create('MDE_Stillstandsprotokoll_Refresh', '0'));
  fValList.Add(TCO_SetupValue.Create('Minibase_Archive_Backup', '0'));
  fValList.Add(TCO_SetupValue.Create('MDE_Ausschuss_Schicht', '0'));
  fValList.Add(TCO_SetupValue.Create('INCL_TPM_Verpackt_Ausschuss', '7'));
  fValList.Add(TCO_SetupValue.Create('INCL_Menge_Schicht_mit_Manuell', 'deleted'));
  fValList.Add(TCO_SetupValue.Create('MDE_AArchiv_Menge_Korrektur', '1'));
  fValList.Add(TCO_SetupValue.Create('INCL_Verpackt_nicht_Schicht_bezogen', '0'));
  fValList.Add(TCO_SetupValue.Create('MDE_Zeit_zwischen_AuftragsStart_Ende', '0'));
  fValList.Add(TCO_SetupValue.Create('MDE_gemittelte_Isttakt_zeigen', '0'));
  fValList.Add(TCO_SetupValue.Create('INCL_Auftragsende_immer_berechnen', '0')); // 40
  fValList.Add(TCO_SetupValue.Create('MDE_Maschinf_Report_Hochformat', '0'));
  fValList.Add(TCO_SetupValue.Create('INCL_BdaList_Testplan_BdaService', '0'));    
  fValList.Add(TCO_SetupValue.Create('FP_Aufloesen_Zwischenauftraege', 'deleted'));
  fValList.Add(TCO_SetupValue.Create('CGI_WS_Ruesten_laufender_Auftrag', '0'));
  fValList.Add(TCO_SetupValue.Create('FP_Mehrstufige_Markieren', '0'));
  fValList.Add(TCO_SetupValue.Create('INCL_TPM_Schicht_Verpackt_Ausschuss', '1'));
  fValList.Add(TCO_SetupValue.Create('CTRL_OEELeistung_mit_TE', '0'));
  fValList.Add(TCO_SetupValue.Create('MDE_OEE_Statistik', '0'));
  fValList.Add(TCO_SetupValue.Create('CGI_Nur_Aktuellen_Auftrag_Zeigen', '0'));
  fValList.Add(TCO_SetupValue.Create('Archivsmandant_Tage', '0'));
  fValList.Add(TCO_SetupValue.Create('CGI_Detail_Auftraege_Verwalten', '0')); // 50
  fValList.Add(TCO_SetupValue.Create('FP_TemperierGeraete', '0'));
  fValList.Add(TCO_SetupValue.Create('WS_RechnerNr_From_USerID', '0'));
  fValList.Add(TCO_SetupValue.Create('CGI_TimeOut_AfterAction', '0'));
  fValList.Add(TCO_SetupValue.Create('MDE_Userlist_with_Userright', '1'));
  fValList.Add(TCO_SetupValue.Create('ERP_InterrupJobIfRunning', '0'));
  fValList.Add(TCO_SetupValue.Create('FP_SolltaktBeiHalbautomat', '0'));
  fValList.Add(TCO_SetupValue.Create('INCL_HalbautomatSchluesselschalter', '0'));
  fValList.Add(TCO_SetupValue.Create('CTR_Ruestenzeit_aus_Stilllog', '0'));
  fValList.Add(TCO_SetupValue.Create('MDE_Maschinf_AutoUpdate_Stop_Seconds', '0'));
  fValList.Add(TCO_SetupValue.Create('MDE_Stillstand_beim_Buchen_splitten', '0'));
  fValList.Add(TCO_SetupValue.Create('MDE_Show_SPC', '0'));
  fValList.Add(TCO_SetupValue.Create('MDE_Arbeitsfrei_nicht_umbuchen', '1'));
  fValList.Add(TCO_SetupValue.Create('FP_Fertigungsauftrag_Kombi', '0'));
  fValList.Add(TCO_SetupValue.Create('FP_Splitten_ohne_Route', '0'));
  fValList.Add(TCO_SetupValue.Create('MDC_OEE_FROM_PACKED', '1'));
  fValList.Add(TCO_SetupValue.Create('Stueckzahl_laufender_Auftrag_nicht_abnullen', '0'));
  fValList.Add(TCO_SetupValue.Create('INCL_VerpacktProt_aus_Schichtausschuss', '0'));
  fValList.Add(TCO_SetupValue.Create('MDE_Gutmenge_Grafik_anzeigen', '0'));
  fValList.Add(TCO_SetupValue.Create('MDE_Hallenspiegel_Artikel_Bezeichnung', '0'));
  fValList.Add(TCO_SetupValue.Create('MDE_Hallenspiegel_Temperatur', '0'));
  fValList.Add(TCO_SetupValue.Create('MG_Stillstand_Meldungszeit', '10'));
  fValList.Add(TCO_SetupValue.Create('INCL_CheckUnterbrocheneAuftraege', '0'));
  fValList.Add(TCO_SetupValue.Create('MDE_WZ_Maschine_Reparatur', '0'));
  fValList.Add(TCO_SetupValue.Create('INCL_Autobuchen_nach_Arbeitsfrei', '1'));
  fValList.Add(TCO_SetupValue.Create('INCL_Stillstand_beim_Schichtwechsel', '0'));
  fValList.Add(TCO_SetupValue.Create('FP_WS_Notiz_in_WS', '0'));
  fValList.Add(TCO_SetupValue.Create('FP_Eingabe_ohne_Zusatz', '0'));
  fValList.Add(TCO_SetupValue.Create('MDE_Etikett_beim_Beenden', '0'));
  fValList.Add(TCO_SetupValue.Create('FP_Ruesten_mit_Einrichter', '1'));
  fValList.Add(TCO_SetupValue.Create('INCL_Verpackt_manuell_autom', '0'));
  fValList.Add(TCO_SetupValue.Create('FP_AuftragNR_aenderbar', '0'));
  fValList.Add(TCO_SetupValue.Create('WS_Ruestgrund_aendern', '0'));
  fValList.Add(TCO_SetupValue.Create('FP_BenutzerAuftragFarbeMaster', '0'));
  fValList.Add(TCO_SetupValue.Create('MDE_Multibuchung', '0'));
  fValList.Add(TCO_SetupValue.Create('FP_PlanlisteArtikelBuchen', '0'));
  fValList.Add(TCO_SetupValue.Create('INCL_TaktbasisToleranz', '35'));
  fValList.Add(TCO_SetupValue.Create('INCL_TaktbasisAnzahl', '20'));
  fValList.Add(TCO_SetupValue.Create('FP_AuftragFreigabeDirekt', '0'));
  fValList.Add(TCO_SetupValue.Create('INCL_UeberproduktionAusVerpackt', '0'));
  fValList.Add(TCO_SetupValue.Create('ERP_WZ_Sollstandzeit', '100000'));
  fValList.Add(TCO_SetupValue.Create('WS_EtikettenProMaschine', '0'));
  fValList.Add(TCO_SetupValue.Create('INCL_Pausen', '0'));
  fValList.Add(TCO_SetupValue.Create('MDE_Export_Taktzeit_to_Excel', '1'));
  fValList.Add(TCO_SetupValue.Create('FP_Plangrafik_Report_Row_Height', '10'));
  fValList.Add(TCO_SetupValue.Create('CGI_W-Lager', '0'));
  fValList.Add(TCO_SetupValue.Create('FP_Halbautomatikkalender', '0'));
  fValList.Add(TCO_SetupValue.Create('CTR_SchichtBezeichnung_aus_Zeit', '0'));
  fValList.Add(TCO_SetupValue.Create('INCL_TaktmeldungNurBeiUeberschreiten', '0'));
  fValList.Add(TCO_SetupValue.Create('INCL_TaktmeldungNichtWiederholen', '0'));
  fValList.Add(TCO_SetupValue.Create('MDE_BeschreibungNurMaschine', '0'));
  fValList.Add(TCO_SetupValue.Create('MDE_WerkzeugStillstaende', '0'));
  fValList.Add(TCO_SetupValue.Create('MSG_RuestueberschreitungMelden', '1'));
  fValList.Add(TCO_SetupValue.Create('MSG_StillstaendeMelden', '1'));
  fValList.Add(TCO_SetupValue.Create('FP_Ausschussquote', '0'));
  fValList.Add(TCO_SetupValue.Create('FP_Plantakt', '0'));
  fValList.Add(TCO_SetupValue.Create('FP_LT2_Minus_LT1', '2'));
  fValList.Add(TCO_SetupValue.Create('FP_Werkzeugliste_Sort_Maschine', '0'));
  fValList.Add(TCO_SetupValue.Create('INCL_Stillstand_24h', '-1'));
  fValList.Add(TCO_SetupValue.Create('FP_GP_Maschinenzustand_Heigt', '4'));
  fValList.Add(TCO_SetupValue.Create('FP_GP_Terminierung_Reihenfolge', '0'));
  fValList.Add(TCO_SetupValue.Create('FP_GP_Taktbasis', '1'));
  fValList.Add(TCO_SetupValue.Create('FP_Auftragseingabe_Loadlist_FormCreate', '0'));
  fValList.Add(TCO_SetupValue.Create('FP_GP_Balken_linksbuendig', '0'));
  fValList.Add(TCO_SetupValue.Create('FP_Eingabe_Ref_Zyklus', '0'));
  fValList.Add(TCO_SetupValue.Create('FP_Artikelnotiz_beim_Planen', '0'));
  fValList.Add(TCO_SetupValue.Create('FP_Editieren_beim_Planen', '0'));
  fValList.Add(TCO_SetupValue.Create('CTR_OEE_Auftragsmangel_SillstandNr', '0'));
  fValList.Add(TCO_SetupValue.Create('MDE_SAP_Log', '0'));
  fValList.Add(TCO_SetupValue.Create('INCL_VerpacktInSchichtProt', '0'));
  fValList.Add(TCO_SetupValue.Create('CGI_StillstandNachStartBuchen', '0'));
  fValList.Add(TCO_SetupValue.Create('INCL_ArbeitsfreiStartNachKalender', '0'));
  fValList.Add(TCO_SetupValue.Create('SPEZ_Pruefplan', '0'));
  fValList.Add(TCO_SetupValue.Create('WS_Save_Password_Sec', '0'));
  fValList.Add(TCO_SetupValue.Create('MG_Stillstand_PDAExt', '0'));
  fValList.Add(TCO_SetupValue.Create('WS_ScanAndCheckPreformBarcode', '0'));
  fValList.Add(TCO_SetupValue.Create('CTR_Nutzung_mit_WS_Arbeitsfrei', '0'));
  fValList.Add(TCO_SetupValue.Create('IF_MatList_DeleteLast4DigitsOfJobNo', '0'));
  fValList.Add(TCO_SetupValue.Create('SPC_AutoConfirmMessageAfterNGoodCycles', '0'));
  fValList.Add(TCO_SetupValue.Create('SPC_StartCompareNCyclesAfterSetup', '0'));
  fValList.Add(TCO_SetupValue.Create('SPC_DeleteMessageAfterNMinutesDowntime', '0'));
  fValList.Add(TCO_SetupValue.Create('FP_Alternativ_Variante', '0'));
  fValList.Add(TCO_SetupValue.Create('NotizInWZListe', '0'));
  fValList.Add(TCO_SetupValue.Create('FP_GP_Show_AG_Info', '0'));
  fValList.Add(TCO_SetupValue.Create('FP_Werkzeug_Tagesreport', '0'));
  fValList.Add(TCO_SetupValue.Create('FP_Artikel_Tagesreport', '0'));
  fValList.Add(TCO_SetupValue.Create('WS_Etikett_Downtimes_Check', '0'));
  fValList.Add(TCO_SetupValue.Create('INCL_Verpackt_Schicht_Nachberechnen', '0'));
  fValList.Add(TCO_SetupValue.Create('INCL_KeinWP_Bei_Laufzeit_In_Schicht', '0'));
  fValList.Add(TCO_SetupValue.Create('IF_DelayTimeAfterJobHandleInSec', '0'));
  fValList.Add(TCO_SetupValue.Create('WS_Etikett_Layout_Drucker', '0'));
  fValList.Add(TCO_SetupValue.Create('SPC_Zeit_zum_Auftrag', '10'));
  fValList.Add(TCO_SetupValue.Create('WS_Etikett_drucken beim_Ruesten', '0'));
  fValList.Add(TCO_SetupValue.Create('CGI_IMMER_Nur_Aktuellen_Auftrag_Zeigen', '0'));


  fValList.Add(TCO_SetupValue.Create('INCL_TaktzeitProtokollVonComm', '0'));
  fValList.Add(TCO_SetupValue.Create('SPC_Delimiter', ';'));
  fValList.Add(TCO_SetupValue.Create('MSG_PlanungReportFlach', '0'));
  fValList.Add(TCO_SetupValue.Create('SPC_SAP_Protokoll', '1'));
  fValList.Add(TCO_SetupValue.Create('CTRL_ProduziertGleichGutMinusAusschuss', '0'));
  fValList.Add(TCO_SetupValue.Create('SPC_Rollenwechsel', '1'));
  fValList.Add(TCO_SetupValue.Create('INCL_UngeplantRuestenBerechnen', '0'));
  fValList.Add(TCO_SetupValue.Create('MDE_AnfahrAusschussKorrigieren', '0'));
  fValList.Add(TCO_SetupValue.Create('CTRL_StatMinutenVorZeitraum', '15'));
  fValList.Add(TCO_SetupValue.Create('SPC_DBGridMachineSpecific', '0'));
  fValList.Add(TCO_SetupValue.Create('SPC_IncDisplayEnddate', '0'));
  fValList.Add(TCO_SetupValue.Create('SPC_AuftragNr_Index', '0'));
  fValList.Add(TCO_SetupValue.Create('SPC_ShowPrinterDialog', '0'));
  fValList.Add(TCO_SetupValue.Create('MG_Stillstand_EMail', '0'));
  fValList.Add(TCO_SetupValue.Create('MG_Reschedule_Before_Print', '1'));
  fValList.Add(TCO_SetupValue.Create('SYS_PingDBAndLog', '0'));
  fValList.Add(TCO_SetupValue.Create('INCL_WorkorderMustRunBeforeStop','0'));
  fValList.Add(TCO_SetupValue.Create('INCL_Update_Masterdata_JobStop','0'));
  fValList.Add(TCO_SetupValue.Create('GLO_mehrstationenmaschine','0'));
  fValList.Add(TCO_SetupValue.Create('INCL_TaktlogWaehrendRuesten','0'));
  fValList.Add(TCO_SetupValue.Create('SPC_Index_Formula', 'val(1)'));
  fValList.Add(TCO_SetupValue.Create('SPC_LinePen_Width','1'));
  fValList.Add(TCO_SetupValue.Create('MDE_ManualRefresh','0'));
  fValList.Add(TCO_SetupValue.Create('MDE_WS_FolgeAuftragTaktzeitUpdate','0'));
  fValList.Add(TCO_SetupValue.Create('MG_DTDetail_not_from_shift','0'));
  fValList.Add(TCO_SetupValue.Create('MDE_WS_AuftragAutoBeenden','0'));

  fValList.Add(TCO_SetupValue.Create('INCL_SupressJobEvents','0'));
  fValList.Add(TCO_SetupValue.Create('JobSetupAndRestart','0'));
  fValList.Add(TCO_SetupValue.Create('WS_MDE_VorabRuestenZeit','0'));
  fValList.Add(TCO_SetupValue.Create('FP_WZB_Anfrage','0'));
  fValList.Add(TCO_SetupValue.Create('FP_Energiebedarf','0'));
  fValList.Add(TCO_SetupValue.Create('IF_UpdateStammGewichtAusMaterialListe','0'));
  fValList.Add(TCO_SetupValue.Create('FP_GrundEnergiebedarf','0'));
  fValList.Add(TCO_SetupValue.Create('FP_MaximalEnergiebedarf','0'));
  fValList.Add(TCO_SetupValue.Create('INCL_AfterCheckDowntime','1'));
  fValList.Add(TCO_SetupValue.Create('FP_Menue_Planung_Only_From_Setup','1'));
  fValList.Add(TCO_SetupValue.Create('INCL_AutoSetup2Time','0'));
  fValList.Add(TCO_SetupValue.Create('FP_Menue_Planung_Limited_By_Setup','0'));
  fValList.Add(TCO_SetupValue.Create('MDE_CTR_FP_ProduziertBuchen','0'));
  fValList.Add(TCO_SetupValue.Create('MDE_RuestProtokoll_Kumuliert','0'));
  fValList.Add(TCO_SetupValue.Create('ERP_GeplanteAuftraegeLoeschen','1'));
  fValList.Add(TCO_SetupValue.Create('MDE_AusschussProt_NurInParetoSichtbareGrunde','0'));
  fValList.Add(TCO_SetupValue.Create('FP_AnzahlPruefwerteInPruefplan','8')); (*Anpassung: Anzahl Prüfplan-werte kann dynamisch erweitert werden*)
  fValList.Add(TCO_SetupValue.Create('SPC_TargetFromPruefplan','0')); (*Die SPC-Sollwerte und Grenzen werden von Prüfplänen übernommen*)
  fValList.Add(TCO_SetupValue.Create('FP_BasispfadZeichnungen',''));
  fValList.Add(TCO_SetupValue.Create('ERP_VorhandenAuftraegeIgnorieren','0'));
  fValList.Add(TCO_SetupValue.Create('ERP_BookAbsolutePackScrapVals','1'));
  fValList.Add(TCO_SetupValue.Create('INCL_InsertDowntimeWOStart','0'));
  fValList.Add(TCO_SetupValue.Create('CGI_PruefplanAnzeige','0')); (*Beim Rüsten in der CGITerm werden Prüfpläne angezeigt*)
  fValList.Add(TCO_SetupValue.Create('FP_FolgeStufen_Automatisch_Einplanen_Ab','-1')); (*Beim Einplanen eines Auftrags mit dieser Stufe werden nachfolgende Stufen automatisch auf ihre WunschMaschinen geplant und fixiert gemäß ERP-Vorgaben*)
  fValList.Add(TCO_SetupValue.Create('CGI_Auftraege_nicht_unterbrechen','0')); (*Blendet den Unterbrechen-Button für Aufträge aus*)
  fValList.Add(TCO_SetupValue.Create('CGI_Material_und_GRN','0')); (*Weiterer Menüpunkt, über den Material-Chargen-nummern eingegeben werden können*)
  fValList.Add(TCO_SetupValue.Create('CGI_KavitaetAendern','1')); (*Weiterer Menüpunkt, über den die Ist-Kavität geändert werden kann*)
  fValList.Add(TCO_SetupValue.Create('CGI_FollowUpOrderOnMainScreen','0')); (*Auf dem Anzeige-Screen wird unten tabellarisch der Folgeauftrag angezeigt (BAnr, Auftragnr, Bezeichnung, SollMenge, StartdatumStr*)
  fValList.Add(TCO_SetupValue.Create('MDE_MaterialDeliveryToSiloForMaterialGroup','-1')); (*Bei MaterialLieferung im MDE wird eine Kombo-Box angezeigt statt Lagerort, mit den SIlos. Außerdem kann Material nur für diese Gruppe vereinnahmt werden*)
  fValList.Add(TCO_SetupValue.Create('MDE_PutMoreThanCurrentLevel','1')); (*FIf true, the operator can book a larger quantity to the silo then there is currently inside*)
  fValList.Add(TCO_SetupValue.Create('MDE_SiloThresholdForMaterialChange','0')); (*If the current level of the silo is below this value, its assigned material can be changed*)
  fValList.Add(TCO_SetupValue.Create('Drucken_aus_BCDruckProt_in_MDE','1')); (*This switch is mainly for Schröder und Heidler which can (re)print labels from the protocol in RTM via the SPC-Comm*)
  fValList.Add(TCO_SetupValue.Create('CGI_MinutesToStartScheduledJobEarlier','0')); (*this indicates a timespan in minutes that a operator can start a job earlier than actually planned without getting a question in cgi-term *)
  fValList.Add(TCO_SetupValue.Create('CGI_ForceGRNEntryAfterSetupIfNotBooked','0')); (*if true then the system checks if any GRN codes have been booked to the MO when setting up. if not then the user will be redirected to the GRN screen*)
  fValList.Add(TCO_SetupValue.Create('CGI_CycleAdditionallyInBottlesPerHour','0')); (*if true, cycletime information is also displayed in bottles/hour*)
  fValList.Add(TCO_SetupValue.Create('FP_ScrapCoefficientONPlanning','0')); (*if true, the scrapcoefficient pdeneu.ausschussquote will be taken into account on planning MOs by increasing the amount*)
  fValList.Add(TCO_SetupValue.Create('INCL_SSCC_PREFIX','0')); (*indicates the SSCC prefix (company code)*)
  fValList.Add(TCO_SetupValue.Create('INCL_SSCC_IncrementResetAt','0')); (*this is the maximum sscc-postfix + 1, so the postfix will be always 'postfix MOD INCL_SSCC_IncrementResetAt'*)
  fValList.Add(TCO_SetupValue.Create('FP_LabelCopyPerJob','0')); (*if true the copy of labels per printout is stored in the job not in the article (pde instead of pdestamm)*)
  fValList.Add(TCO_SetupValue.Create('MDE_PackenBuchen','0')); 
  fValList.Add(TCO_SetupValue.Create('MDC_defaultdtfilter','0')); (*this indicates which dtfilter will be used by default in the runtimebar. If zero then the shortstop-book-time will be used from SETUP*)
  fValList.Add(TCO_SetupValue.Create('CGI_DowntimesPastBooking','0'));  (*No of days that downtimes can be booke retrospectively in WebPR*)
  fValList.Add(TCO_SetupValue.Create('ERP_DisablePDEUpdateOnJobEvents','0')); (* Updates auf Jobs nur für 'G','S' und 'T' Event zulassen *)
  fValList.Add(TCO_SetupValue.Create('ERP_CheckLicenseBeforeBookGood','0')); (* Check if License is correct before book good *)
  fValList.Add(TCO_SetupValue.Create('MDE_MJANote','0')); (* Notes for MJA *)
  fValList.Add(TCO_SetupValue.Create('FP_MDE_CycleTimeInMinutes','0')); (* Show Cycletime in Minutes *)
  fValList.Add(TCO_SetupValue.Create('FP_AuftragReaktivieren','1')); (* Auftrag reaktivieren *)
  fValList.Add(TCO_SetupValue.Create('CGI_ShowAdditionalInfoForSignalsGreaterThan','0')); (*if > 0 then there is an additional, customizable screen in the webPR Module showing additional signal information for signals with a signal number greater than this parameter*)
  fValList.Add(TCO_SetupValue.Create('INCL_KGruppeInitInterval','60')); (* Interval für die Aktualisierung der Kalndergruppenzuordnung *)
  fValList.Add(TCO_SetupValue.Create('INCL_FolgeStufenSollWertAutomatischErhoehen','0')); (*this indicates whether the target amount or delivery dates of following stages of a multi-stage job should also be changed if a stage is changed*)
  fValList.Add(TCO_SetupValue.Create('MDE_WerkzeugInReparaturWaehrendBetriebsauftrag','0')); (*If true then repair orders for mold currently being used on a machine will be marked appropriately and yield an according message in the ProductionReporting module*)
  fValList.Add(TCO_SetupValue.Create('MDE_EtikettenPetainer','0')); (*this gives Petainer the option to reprint a damaged label from RTM module just the same way it was originally printed (except for the print date/time)*)
  fValList.Add(TCO_SetupValue.Create('CGI_ShowAmountsIncludingScrap','0')); (*if enabled, the webPR shows the actual/original amounts for the job instead of deducting scrap*)
  fValList.Add(TCO_SetupValue.Create('CGI_ForceRefreshButton','0')); (*if enabled, the webPR always shows the RefreshButton*)
  fValList.Add(TCO_SetupValue.Create('MDC_ShowMaterialList','0')); (*Shows a material list sorted by machine and starting date*)
  fValList.Add(TCO_SetupValue.Create('INCL_YearsForMonthlyScrapStatistic','-1')); (*Number of years additional to the current year that the monthly scrap statistic is shown for*)
  fValList.Add(TCO_SetupValue.Create('MDE_Show_ProductScrap','0')); (*Number of years additional to the current year that the monthly scrap statistic is shown for*)
  fValList.Add(TCO_SetupValue.Create('FP_BetriebsauftragnrAlphaNumeric','1')); (*If 0 then the MO No can only by numeric, otherwise alphanumeric*)
  fValList.Add(TCO_SetupValue.Create('FP_BetriebsauftragNrMaxLength','0')); (*if greater then 0 then this is the maximum length of a MO No*)
  fValList.Add(TCO_SetupValue.Create('FP_BetriebsauftragNrForceLength','0')); (*if greater then 0 then this is the exactly required length of a MO No*)
  fValList.Add(TCO_SetupValue.Create('MDC_JobListOrderClause','ORDER BY PDE.Lizenz, PDE.Startdatumzeit')); (*this is the order by clause for the job list in MDC; if emtpy they will be sorted by MO number*)
  fValList.Add(TCO_SetupValue.Create('MDC_ShowRemainingPalettsInMJA','0')); (*Shows the remaining pallets in the machine job allocation in MDC*)
  fValList.Add(TCO_SetupValue.Create('CGI_ScrapCodesFROMBookingParam','0')); (*If true then only scrap codes are shown where AUSSCHUSS_GRUNDE.grund_buchen = 1 else only scrap codes are shown where AUSSCHUSS_GRUNDE.rep_anzeige = 1 *)
  fValList.Add(TCO_SetupValue.Create('CGI_StartWithoutJob','0')); (*If true then new MOs can be generated on the fly from the cgiSF-module from the master data*)
  fValList.Add(TCO_SetupValue.Create('CGI_NOJOBEnterJobNoOnStart','0')); (*If true then the MO-Number can be entered when creating a new MO on the fly from the cgiSF-module from the master data*)
  fValList.Add(TCO_SetupValue.Create('CGI_NOJOBCycleFromMasterData','0')); (*If true then the cycletime is taken from the master data when creating a new MO on the fly from the cgiSF-module from the master data*)
  fValList.Add(TCO_SetupValue.Create('MDE_EditVirtualMachineGroups','0')); (*If true then the virtual machine groups can be edited from the RTM module*)
  fValList.Add(TCO_SetupValue.Create('CGI_BookScrap','1')); (*Enables / disables the scrap book button in webSF*)
  fValList.Add(TCO_SetupValue.Create('CGI_ShowCavityInMachine','1')); (*Enables / disables the cavity display in the machine in webSF*)
  fValList.Add(TCO_SetupValue.Create('CGI_BigBagsName','')); (*Enables / disables the input of GRNs for SiloMaterial in webSF. The parameter serves as the displayed Option, e.g. 'BigBag -  manual entry'*)
  fValList.Add(TCO_SetupValue.Create('CGI_JobListOrderClause','order by pde.Startdatumzeit')); (*this is the order by clause for the job list in webSF; if emtpy they will be sorted by startdate*)
  fValList.Add(TCO_SetupValue.Create('CGI_JoblistAsTable','0')); (*RS: 24.11.2011 - Woodward - if true then all planned jobs are displayed in a table. Jobs can be even fetched from another machine*)
  fValList.Add(TCO_SetupValue.Create('WS_Ausschuss_auf_VorgaengerStufe','0')); (*RS: 28.11.2011 - Eschenbach - if true then you have an additional button in the scrap booking dialogue in the OLD shopfloor module to book scrap to the predecessor*)
  fValList.Add(TCO_SetupValue.Create('FP_KeepSetupTimeOnUnSched','0')); (*RS: 29.11.2011 - Gizeh - if true and not Setup.Metal then the setup time is transferred to PDENEU when a scheduled job is put back into unscheduled mode*)
  fValList.Add(TCO_SetupValue.Create('FP_CloseMultiStageConfirmAfterSecs','0')); (*RS: 29.11.2011 - Eschenbach - if > 0 than number of seconds to wait before closing the confirmation window*)
  fValList.Add(TCO_SetupValue.Create('CGI_ShowMoldInMachine','0')); (*RS 30.11.2011 - petainer - Enables / disables the mold display in the machine in webSF*)
  fValList.Add(TCO_SetupValue.Create('CGI_ShowMaterialComment','0')); (*RS 30.11.2011 - petainer - Enables / disables the display of the material comment field in the material list in webSF*)
  fValList.Add(TCO_SetupValue.Create('MDC_ShowMoldInMaterialDemand','0')); (*RS 30.11.2011 - petainer - Enables / disables the display of the mold information in the material demand in MDC*)
  fValList.Add(TCO_SetupValue.Create('FP_JobnoSplitPoint','15')); (*RS 02.12.2011 - TKV - This is the maximum length of the base jobno in PS for splitting. additional parts of the string will be treated as numeric and tried to be increased*)
  fValList.Add(TCO_SetupValue.Create('FP_JobnoSplitSuffixLength','2')); (*RS 02.12.2011 - TKV - This is the count of digits for the suffix part of a splitted jobno*)
  fValList.Add(TCO_SetupValue.Create('FP_DeleteOnlyifPartNo','1')); (*RS 02.12.2011 - TKV - if true then only jobs with a partno can be deleted*)
  fValList.Add(TCO_SetupValue.Create('INCL_RunningChangeOnPrintRequest','0')); (*RS 07.12.2011 - petainer - Enables / disables running change by print request. If a running change request exists, it will only be executed by CoreService. Other modules won't be able to start/stop job on the corresponding machine*)
  fValList.Add(TCO_SetupValue.Create('RF_AllowMachineChange','0')); (*RS 08.12.2011 - TKV - Enables / disables starting a job on another job with the RF-Terminal*)
  fValList.Add(TCO_SetupValue.Create('MDE_AuftragsArchivProduziertBuchen','0')); (*RS 09.12.2011 - TKV - Enables / disables booking of produced parts on a job in the RTM job archive*)
  fValList.Add(TCO_SetupValue.Create('FP_MoveKombiStages','0')); (*RS 15.12.2011 - Eschenbach - Enables / disables reallocation of the follow-up stages of detail jobs*)
  fValList.Add(TCO_SetupValue.Create('INCL_InternalMaterialEANFromSequence','0')); (*RS 15.12.2011 - petainer - if 1 then materialzuor.eancode ist taken from a sequence, otherwise it is derived from the date*)
  fValList.Add(TCO_SetupValue.Create('MDE_TagesWochen_Statistik','0')); (*RS 22.12.2011 - ttb - weekly / daily report*)
  fValList.Add(TCO_SetupValue.Create('MDE_Schicht_Statistik','0')); (*RS 22.12.2011 - ttb - shiftreport*)
  fValList.Add(TCO_SetupValue.Create('INCL_CustomerReportLogo','0')); (*RS 03.01.2012 - Eschenbach - bitmap id in the table bitmap for the customer specific logo for quickreport*)
  fValList.Add(TCO_SetupValue.Create('FP_ModifyMaintenanceJobs','1')); (*RS 11.01.2012 - etm - if false maitenance jobs cannot be manipulated in the PS module*)
  fValList.Add(TCO_SetupValue.Create('MDE_ShowPhysStateOnSetup','0')); (*RS 12.01.2012 - etm - shows physical state on setup*)
  fValList.Add(TCO_SetupValue.Create('INCL_MoldStateFromStateInt','0')); (*RS 18.01.2012 - eschenbach - if true then the mold/tool state is derived from werkzeug.statusint and not from the string field status !WARNING! ONLY ACTIVATE IF ALL MODULE EMPLOYING CO_AUFTRAG are > 02.12.2011 (MDE/WS/ERP_Interface/BCTerminal...)!*)
  fValList.Add(TCO_SetupValue.Create('MDC_flexibleDashboard','0')); (*RS 31.01.2012 - etm - if true then  the user can set the periods for the dashframe in the mdc module in a flexible way*)
  fValList.Add(TCO_SetupValue.Create('CGI_DowntimesPastBookingCount','10')); (*RS 06.02.2012 - petainer - count of downtime displayed for the past*)
  fValList.Add(TCO_SetupValue.Create('MDC_OEETargetPerMachine','0')); (*RS 14.02.2012 - petainer - target and minimum OEE values for OEE-chart in MDC can be defined via the RTM-module => machine settings*)
  fValList.Add(TCO_SetupValue.Create('INCL_PersonalKalender','0')); (* RS 16.02.2012 - ETM - Personal kann zu vom Schichtkalender abweichenden Zeichen abgmeldet werden; dazu können Kalender hinterlegt werden*)
  fValList.Add(TCO_SetupValue.Create('CGI_BlockedAndApproved','0')); (* RS 29.02.2012 - Petainer - show blocked and approved parts and pallets from the ERP system*)
  fValList.Add(TCO_SetupValue.Create('CGI_GRNFromPrecedessor','0')); (* RS 29.02.2012 - Petainer - Get the GRNs from the previous job as default for the current job on the first booking *)
  fValList.Add(TCO_SetupValue.Create('MSG_SaveReportCopy','0')); (* RS 05.03.2012 - Eschenbach - reports and sql statements can also be saved to a network drive *)
  fValList.Add(TCO_SetupValue.Create('INCL_RetropectiveScrap','0')); (* RS 09.03.2012 - Eschenbach - Scrap can be booke to a shift in the past in the ShopFloor-Module *)
  fValList.Add(TCO_SetupValue.Create('CGI_ShowShiftProductivity','0')); (* RS 28.03.2012 - Petainer - Show productivity from shift log *)
  fValList.Add(TCO_SetupValue.Create('FP_MoldFromStage','0')); (* RS 16.04.2012 - Eschenbach - On Automated planning this activates the tool/mold being taken from the masterdata instead of the mo data from the interface *)
  fValList.Add(TCO_SetupValue.Create('FP_MeldungBeiUmplanen','0')); (* Beim Umplanen auf eine andere Maschine Stammdaten prüfen *)
  fValList.Add(TCO_SetupValue.Create('ERP_WerkzeugProMaschine','0')); (* Für jede Maschine wird ein eigenes Werkzeug angelegt *)
  fValList.Add(TCO_SetupValue.Create('MDC_ShowCycles','0')); (* Anzeige für Hubzahl in MDC *)
  fValList.Add(TCO_SetupValue.Create('MDC_ShowProducedInDashboard','1')); (* Anzeige produzierte in Dashboard *)
  fValList.Add(TCO_SetupValue.Create('FP_StammdatenAnlegenBeimPlanen','0'));
  fValList.Add(TCO_SetupValue.Create('INCL_SkipRecalcAndSetuptimesWithCalendar', '0')); // Überspringen von Rüstprotkorrektur
  fValList.Add(TCO_SetupValue.Create('MDC_JobListWithTool','0')); (* RS 24.05.2012 - petainer - you can display the necessary tool on the job list in MDC *)
  fValList.Add(TCO_SetupValue.Create('CGI_DTFromMachineType','0')); (* RS 24.05.2012 - petainer - if true then the first letters of the Downtime code need to be the same as maschine.typ *)
  fValList.Add(TCO_SetupValue.Create('MJA_SurpressSFHeader','0')); (* RS 14.06.2012 - MJA if true then there is no grey header line on shopfloor*)
  fValList.Add(TCO_SetupValue.Create('MJA_ShowDetailRow','0')); (* RS 14.06.2012 - MJA if true the detailrow in the mja is visible*)
  fValList.Add(TCO_SetupValue.Create('MJA_OfflineInSF','0')); (* RS 14.06.2012 - MJA Fagerdala: Show Offlinemachines in SF*)
  fValList.Add(TCO_SetupValue.Create('MJA_SFDefaultGroup','-1')); (* RS 14.06.2012 - defalt group for DNS / user if it is a new user. if -1 then the user / DNS won't have a group and needs configuration by admin*)
  fValList.Add(TCO_SetupValue.Create('MJA_DefaultPage','Default.aspx')); (* RS 14.06.2012 - MJA default page for perstype <> 1*)
  fValList.Add(TCO_SetupValue.Create('MJA_SFGroupsFromUser','0')); (* RS 14.06.2012 - MJA if true then the sF groups in MJA are taken per user not DNS name of machine*)
  fValList.Add(TCO_SetupValue.Create('MDE_ArtArchBuAlleBAs','0')); (* RS 15.06.2012 - MDE aus performanz-Gründen wird die Auftrags-Kombo-Box im Auftragsarchiv nachbuchen deaktiviert*)
  fValList.Add(TCO_SetupValue.Create('FP_CheckExistingWorkorder','1')); (* ML 06.07.2012 - Möglichkeit die Abfrage ob Auftrag existiert zu unterbinden*)
  fValList.Add(TCO_SetupValue.Create('INCL_ZeroProducedMaschinfDuringSetup','0')); (* ML 06.07.2012 - Produziert wird als 0 während Rüsten angezeigt*)
  fValList.Add(TCO_SetupValue.Create('CGI_BPHSTDSTDCav','0')); (* RS 13.07.2012 - cgiterm Petainer: If 1 then the STD cycle in bottles per hour will be derived from the STD cavity, else from the ACT cavity*)
  fValList.Add(TCO_SetupValue.Create('SVC_ForceAutoStartAtPCNT','0')); (* RS 13.07.2012 - MainService Nadfinlo: if > 0 then this indicates the percentage; If this percentage of the STD-amount has been produced on a workorder and the followup is the same part, then it will be automatically started if setup.folgeauftrag_autostart = 1*)
  fValList.Add(TCO_SetupValue.Create('MJA_SFJobListConfirmation','0')); (* RS 19.07.2012 - Nadfinlo: if > 0 then a operator can confirm an open order on the SF*)
  fValList.Add(TCO_SetupValue.Create('MJA_MSFLANGUAGE','de-DE')); (* DJ 3.8.2012 - eingestellte sprache für mobile SF*)
  fValList.Add(TCO_SetupValue.Create('FP_PartAndTool_FromMJA', '0'));  (* DJ 24.8.2012 - möglichkeit stammdaten aus der MJA zu holen, zeigt direkt die WebSeite innerhalb der FP an*)
  fValList.Add(TCO_SetupValue.Create('FP_PartAndTool_FromMJA_BaseURL', 'http://localhost/mdc/'));  (* DJ 24.8.2012 - BasisURL unter der die WebMDC erreichbar ist*)
  fValList.Add(TCO_SetupValue.Create('INCL_RecoverInterruptSignals','0')); (* RS 08.08.2012 - RPC/ETM: Interrupt-Signals werden nur gezogen, wenn dieser Schalter steht*)
  fValList.Add(TCO_SetupValue.Create('MDE_SchichtWerteKorrigieren','0')); (* RS 10.08.2012 - Petainer: if > 0 then you can edit the shift values of the past in the shift log in RTM. However, this is password protected*)
  fValList.Add(TCO_SetupValue.Create('WS_DirectMultiOpt','0')); (* RS 27.08.2012 - Eschenbach: if > 0 then you can directly switch betwen optimizing and production in the old ShopFloor multiple times *)
  fValList.Add(TCO_SetupValue.Create('CGI_CavityChangeComment','0')); (* RS 28.08.2012 - petainer: if > 0 then you can enter a comment in the old WebSF on changing the cavity*)
  fValList.Add(TCO_SetupValue.Create('MJA_SFDefaultScrapValue','')); (* RS 30.08.2012 - Nadfinlo: Default value for Scrap Bookings in the mShopFloor*)
  fValList.Add(TCO_SetupValue.Create('INCL_BDAFromSignals','0')); (* RS 31.08.2012 - Nadfinlo: If > 0 then there are BDA-jobs which are created by signals. Effect: MSG can send, CO_Auftrag doesn't delete these*)
  fValList.Add(TCO_SetupValue.Create('MJA_mShopFlorRaisableBDA','')); (* RS 31.08.2012 - Nadfinlo: These are signals which can be "raised" from the mSHopFloor*)
  fValList.Add(TCO_SetupValue.Create('INCL_ReportUpdateDTANDScrapCodes','0')); (* RS 12.09.2012 - Nadfinlo: if > 0 then the DT codes and Scrap codes in the pareto tables will be refreshed after creation from the master tables (tpm_stillstaende / ausschuss_grunde*)
  fValList.Add(TCO_SetupValue.Create('MJA_FetchNullUser','0')); (* RS 17.09.2012 - Nadfinlo: if > 0 MJA tries to retrieve the currentuser from usr_eventlog if it finds that the session variable is empty*)
  fValList.Add(TCO_SetupValue.Create('MJA_DefaultUserID','')); (* RS 17.09.2012 - Nadfinlo: if the parameter is not empty and no user can be retrieved, default to the user with this id *)
  fValList.Add(TCO_SetupValue.Create('MJA_SFShowAllJobsInList','0')); (* RS 18.09.2012 - Nadfinlo: if the parameter is > 0 then all jobs (also for other machines) can be selected*)
  fValList.Add(TCO_SetupValue.Create('INCL_MoldLifeTimeInGraphic','0')); (* RS 11.10.2012 - Eschenbach: if the parameter is > 0 then the tool information in the scheduler graphic includes lifetime information and the triangle's border is red if < 1 and yellow if < 10% of STD lifetime*)
  fValList.Add(TCO_SetupValue.Create('ERP_BookAlsoNegativeGood','0')); (* RS 17.10.2012 - CEFEG: if the parameter is > 0 then the ERP interface will also book negativ amounts ("Abgang") in verpacktprot*)
  fValList.Add(TCO_SetupValue.Create('INCL_CopySiloOnStart','0')); (* RS 26.10.2012 - Petainer: if the parameter is > 1 then after a successful start the Cavity settings and GRNs will be copied from the precedessor (logpos(66))*)
  fValList.Add(TCO_SetupValue.Create('FP_MaterialStufenverwaltung','0')); (* ML 19.11.2012 - Fagerdala: Zuordnung von ArtikelNr / Stufe zu Auftrag bei Materialbereitstellunge*)
  fValList.Add(TCO_SetupValue.Create('CGI_DTCodeLength','25')); (* RS 05.11.2012 - Petainer: indicates the max length of DT codes displayed in CGITerm; if -1 then the whole DTCode will be displayed*)
  fValList.Add(TCO_SetupValue.Create('CGI_RuestenNichtMehrfach','0')); (* ML 06.12.2012 - RPC: es darf nur ein Mal gerüstet werden*)
  fValList.Add(TCO_SetupValue.Create('CGI_WebWSNurWSGruppenVonDNS','0')); (* RS 15.11.2012 - CEFEG: indicates whether only SF-Groups should be displayed in the old WebWS, then they are taking from WS_DNS_MApping; if no entry then rechnernr = 1*)
  fValList.Add(TCO_SetupValue.Create('IF_KMaterialInStammdaten','0')); (* ML 06.12.2012 - Mentor: Erstes Material aus Liste wird als Material in PDE und PDEStamm übernommen *)
  fValList.Add(TCO_SetupValue.Create('MDE_ChargenZuordnungLoeschen','0')); (* RS 26.11.2012 - Petainer: indicates whether GRN bookings assigned to workorders can be deleted from within the material log in RTM module*)
  fValList.Add(TCO_SetupValue.Create('INCL_PrescheduledJobStart','0')); (* ML 18.12.2012 - Phoenix: Auftrag kann als nächster zum Starten markiert werden *)
  fValList.Add(TCO_SetupValue.Create('CGI_PreDefNotes','0')); (* RS 28.11.2012 - CEFEG: If 1 then you can predefine Notes in the RTM module which can be selected in the old web shopfloor *)
  fValList.Add(TCO_SetupValue.Create('ERP_ArchivAuftraegeLoeschen','1')); (* ML 18.12.2012 - Bei Event D werden Aufträge auch im Aarchiv gelöscht *)
  fValList.Add(TCO_SetupValue.Create('CGI_SortDTCodes','0')); (* RS 28.11.2012 - CEFEG: If 1 then you can define the sortorder of the DT-Codes in the old web shopfloor *)
  fValList.Add(TCO_SetupValue.Create('CGI_BPHFROMIF','0')); (* RS 28.11.2012 - petainer: if 1 then the STD speed in bottles per hour ist taken from the field pde.etikett *)
  fValList.Add(TCO_SetupValue.Create('INCL_CavityChangePeriod','60')); (* RS 30.11.2012 - if you change the cavity, this is the number of seconds that the system will look in the past for cavity changes so that no problems arise with the counter*)
  fValList.Add(TCO_SetupValue.Create('FP_BetriebsAuftragnrSperren','0')); (* RS 3.12.2012 -  rieke - if 1 this overrides the registry settings and creates a new job no on invoking the form. There will be an empty dataset in pdeneu, which will be deleted after insertion of the the actual dataset or on canceling the form.*)
  fValList.Add(TCO_SetupValue.Create('CGI_Auftraege_Starten','1')); (* RS 5.12.2012 - CEFEG - if 1 then operator can start jobs in old webSF.*)
  fValList.Add(TCO_SetupValue.Create('CGI_Auftraege_Beenden','1')); (* RS 5.12.2012 - CEFEG - if 1 then operator can finish jobs in old webSF.*)
  fValList.Add(TCO_SetupValue.Create('INCL_ConventionalExcelExport','0')); (* RS 13.12.2012 - RIEKE - if 1 not nExcel is used but the conventional way to export to excel*)
  fValList.Add(TCO_SetupValue.Create('MDC_ffGeneralAsFormat','0')); (* RS 13.12.2012 - Petainer - if 1 then ffGeneral is used for formatting in MDC, not ffNumber => so no thousand separators*)
  fValList.Add(TCO_SetupValue.Create('MDC_DecimalSeparator', DecimalSeparator)); (* RS 13.12.2012 - Petainer - overrides the decimal separator in MDC*)
  fValList.Add(TCO_SetupValue.Create('WWS_RefreshPeriodSecMain', '30')); (* RS 18.12.2012 - Nadfinlo - this it the timeout after which the main page in WebWerkstatt.exe will be refreshed. If -1 then no automatic refresh will take place*)
  fValList.Add(TCO_SetupValue.Create('WWS_RefreshPeriodSecPMMain', '15')); (* RS 18.12.2012 - Nadfinlo - this it the timeout after which the pmmain page in WebWerkstatt.exe will be refreshed. If -1 then no automatic refresh will take place*)
  fValList.Add(TCO_SetupValue.Create('INCL_MJAInterruptedDescr', '0')); (* RS 18.01.2012 - Eschenbach - if 1 then you can see a text "job interrupted" in the mja instead of "no job" if there is at least one interrupted job for this machine*)
  fValList.Add(TCO_SetupValue.Create('MDC_IncludePerfVars', '0')); (* RS 21.01.2013 - Petainer As - if 1 you will see expected produced and expected runtime based on STD cycle in the OEE table*)
  fValList.Add(TCO_SetupValue.Create('INCL_AliveTimerWithoutTrigger', '0')); (* RS 22.02.2013 - Geck - if 1 then each alivetimerClient will automatically set the DB-Date*)
  fValList.Add(TCO_SetupValue.Create('IF_MaterialPosErsetzen', '0')); (* ML 27.02.2013 - Mentor - Material auf Stücklistenposition ersetzen*)
  fValList.Add(TCO_SetupValue.Create('IF_MaterialKeinUpdate', '0')); (* ML 27.02.2013 - Mentor - Material nur hinzufügen, nicht updaten*)
  fValList.Add(TCO_SetupValue.Create('FP_NeuAuftrag_Artikel_Bezeichnung_Mutex', '0')); (* ML 14.03.2013 - Rieke, bei Neuer Auftrag Auswahl Artikel kann Bezeichnung nicht geändert werden, ebenfalls umgekehrt*)
  fValList.Add(TCO_SetupValue.Create('CGI_ShowPackSize', '0')); (* RS 06.03.2013 - petainer show the packsize on operator screen*)
  fValList.Add(TCO_SetupValue.Create('MDE_NoEditFinishedRepair', '0')); (* RS 14.03.2013 - Eschenbach  - finished repair jobs for mold/tool can't be edited but only displayed*)

  fValList.Add(TCO_SetupValue.Create('ERP_RuestenUnterbrechenBeiEvent_E', '0')); (* ML 20.03.2013 - Koetke, bei Eingang Event E und Auftrag im Zustand Rüsten, Rüsten unterbrechen*)
  fValList.Add(TCO_SetupValue.Create('ERP_RuestgrundNachUnterbrechen_E', '0')); (* ML 20.03.2013 - Koetke, nach unterbrechen bei Event E, Grund buchen*)
  fValList.Add(TCO_SetupValue.Create('INCL_ZellenfertigungLinieSimultan', '0')); (* ML 20.03.2013 - Bucher, bei Zellenfertigung Auftrag auf einzelne Maschinen splitten und ggf. Folgestufen starten*)
  fValList.Add(TCO_SetupValue.Create('FP_EditRunningJobs', '1')); (* RS 23.05.2013 - Eschenbach, if 0 then running jobs or jobs in setup can't be edited in the graphic scheduler*)
  fValList.Add(TCO_SetupValue.Create('INCL_VerpacktProt_aus_Aarchiv_und_AusschussProt', '0')); (* RS 19.06.2013 - Nadfinlo, if 1 then VerpacktProtAusAusschussRechnen will exit since the core Service is computing packed *)
  fValList.Add(TCO_SetupValue.Create('INCL_SpcStichInDB', '1')); (* RS 24.06.2013 - suh - if 0 than the SPC spot data is taken from files rather then the database*)
  fValList.Add(TCO_SetupValue.Create('INCL_SpcStichExportPfad', ' ')); (* RS 24.06.2013 - suh - path to the SPC spot files*)
  fValList.Add(TCO_SetupValue.Create('INCL_SpcSollGleichMittelwert', '0')); (* RS 24.06.2013 - suh - if 1 then the average is taken as STD for SPC spot check*)
  fValList.Add(TCO_SetupValue.Create('INCL_SPCSchussProKarton', '0')); (* RS 24.06.2013 - suh - if 1 then pdestamm.spcschuss is considered as the count of shots per carton, not as every x-th shot*)
  fValList.Add(TCO_SetupValue.Create('FP_PDEStammDefaultLayout', '')); (* RS 25.06.2013 - suh - contains the default layout for the new entry in pdestamm*)
  fValList.Add(TCO_SetupValue.Create('FP_PDEStammDefaultLayout2', '')); (* RS 25.06.2013 - suh - contains the default layout2 for the new entry in pdestamm*)
  fValList.Add(TCO_SetupValue.Create('ERP_KundenReferenzAlsBinaerBool', '0')); (* ML 12.09.2013 - Mentor - Wenn in Kundereferenz etwas steht dann 1 sonst 0 *)
  fValList.Add(TCO_SetupValue.Create('INCL_NurSollWertOffsetErhoehen', '0')); (* RS 18.07.2013 - JBR - if 1 then the user cannot increment the STD value directly in V8.1 *)
  fValList.Add(TCO_SetupValue.Create('FP_ForcePdeKudetail', '0')); (* RS 23.07.2013 - rieke - if 1 then there is an automatic entry in pde_ku_detail on creation of a new entry in pdeneu *)
  fValList.Add(TCO_SetupValue.Create('INCL_JobStartWithoutMOldState', '0')); (* RS 05.08.2013 - nadfinlo - if 1 then a job can be started regardless whether the mold is available or not*)
  fValList.Add(TCO_SetupValue.Create('MDC_CustomerReferenceInShiftLog', '0')); (* RS 06.08.2013 - petainer - if 1 then the field aarchiv.kundenreferenz is visible in MDC shift log*)
  fValList.Add(TCO_SetupValue.Create('MDE_ReparaturArten', '0')); (* RS 26.08.2013 - Eschenbach - if 1 then there will be a list of repair types in the OLD RTM module*)
  fValList.Add(TCO_SetupValue.Create('INCL_RepairWithoutMoldStateChange', '0')); (* RS 27.08.2013 - Eschenbach - if 1 then on entering a repair the user can choose whether the tool/mold's location is changed to repair or not*)
  fValList.Add(TCO_SetupValue.Create('INCL_MoldRepairWithMoldList', '0')); (* RS 29.08.2013 - Eschenbach - if > 1 then there automatically will be a moldlist (derived from werkzeugstueckliste) in the repair's note field*)
  fValList.Add(TCO_SetupValue.Create('FP_MoldRepairOnScheduled', '')); (* RS 29.08.2013 - Eschenbach - if not an empty string then this is parsed  in order to schedule specific mold repairs related to a job. e.g. V,1,7;W,1,8 will result in a repair job with finish date one day after job start for each mold of type 'V' in the mold list with the reason with PK 7 from werkzeugbau and a repair job with finish date one day prior to job start for each mold of type 'W' in the part's mold list  with the reason with PK 8 from werkzeugbau *)
  fValList.Add(TCO_SetupValue.Create('MDE_ChaoticMoldStore', '0')); (* RS 30.08.2013 - Eschenbach - if 1 then there is an chaotic warehouse logic implemented for molds*)
  fValList.Add(TCO_SetupValue.Create('MDE_MoldRepairChoosePart', '0')); (* RS 30.08.2013 - Eschenbach - if 1 then you can choose the part for which repair is done *)
  fValList.Add(TCO_SetupValue.Create('INCL_GRNOncePerMO', '0')); (* RS 02.09.2013 - Petainer - if 1 then a GRN is only assigned once per MO*)
  fValList.Add(TCO_SetupValue.Create('INCL_SuppresMoldList', '1')); (* RS 02.09.2013 - Eschenbach - if 1 there are no joins on werkzeugstueckliste*)
  fValList.Add(TCO_SetupValue.Create('MDE_ChoosePartForScrapPareto', '0')); (* RS 04.09.2013 - Eschenbach - if 1 then in RTM module you can choose the part you want the part based scrap pareto for*)
  fValList.Add(TCO_SetupValue.Create('INCL_LeaveDownTimeOnJobStart', '0')); (* RS 05.09.2013 - SUH - if 1 then an existing downtime is not finished*)
  fValList.Add(TCO_SetupValue.Create('MDE_ReadOnly', '0')); (* RS 14.09.2013 - if 1 then the RTM module will only operate in readonly mode*)
  fValList.Add(TCO_SetupValue.Create('FP_NoteSizeInReport', '7')); (* RS 14.09.2013 - Heine - indicates the Font size for the graphic scheduler's report Notes below the jobs*)
  fValList.Add(TCO_SetupValue.Create('INCL_CheckAddToolsOnStart', '0')); (* RS 18.09.2013 - Eschenbach - if 1 then all additional molds from werkzeugstueckliste will be checked on repair*)
  fValList.Add(TCO_SetupValue.Create('FP_MoldRepairOnScheduledDeletion', '0')); (* RS 16.12.2013 - Eschenbach - if 1 then scheduled repair jobs can be deleted directly from the graphic scheduler*)
  fValList.Add(TCO_SetupValue.Create('MDE_ReparaturStufen', '0')); (* RS 29.01.2014 - Eschenbach - if 1 you can define and edit predecessor and successor repairs for a mold repair job*)
  fValList.Add(TCO_SetupValue.Create('MDE_AlleReparaturenSchliessen', '0')); (* RS 29.01.2014 - Eschenbach - if 2 then only the open repair can be closed from the repair tables, if 1 the user has to confirm if 0 then always all open repairs are closed from the repair table*)
  fValList.Add(TCO_SetupValue.Create('MJA_XtraReportWebServiceURL', '')); (* RS 31.01.2014 - Eschenbach - default value for XtraReport-SERVICE (URL), only set it, if the WebService really exists!*)
  fValList.Add(TCO_SetupValue.Create('INCL_SVCDontWriteCavityForXminutes', '0')); (* RS 07.02.2014 - Petainer - Number of minutes after runningchange before service will try to set the shots into the coupler after detecting a cavity change*)
  fValList.Add(TCO_SetupValue.Create('INCL_MoldCycleFromCoreSvc', '0')); (* ML 13.02.2014 - Quarder Espel -> Werkzeugschüsse von CoreSVC *)
  fValList.Add(TCO_SetupValue.Create('FP_HideZeroScheduledReport', '0')); (* ML 26.02.2014 - Rieke -> Wenn Auftrag geplant wird in Report Grafische Planung nichts anstelle 0 für Istwert angezeigt *)
  fValList.Add(TCO_SetupValue.Create('FP_PlanReportShowCalendar', '0')); (* RS 17.03.2014 - Quarder CZ - If 1, then times in the graphic scheduler's report without capacity due to the plant calendar will be colored gray *)
  fValList.Add(TCO_SetupValue.Create('FP_ReparaturPlanung', '0')); (* ML 10.04.2014 - Quarder CZ - Planung von Reparaturen *)
  fValList.Add(TCO_SetupValue.Create('FP_AuftragsGrafikFarbeausWerkzeug', '0')); (* RS 08.05.2014 - Dietz - If 1, then you can enter a color per mold which a scheduled workorder inherits per default *)
  fValList.Add(TCO_SetupValue.Create('FP_WZBarBigSize', '0')); (* ML 08.04.2014 - Quarder CZ - Werkzeugbalken über den gesamten Auftrag zeigen *)
  fValList.Add(TCO_SetupValue.Create('FP_GraphicReportLegend', '0')); (* ML 08.04.2014 - Quarder CZ - Legende in Feinplanung report anzeigen *)
  fValList.Add(TCO_SetupValue.Create('FP_DetailKavitaetAusERP', '0')); (* RS 04.06.2014 - Quarder CZ - Kavität für Detail-Aufträge kommt aus pdeneu.erpsollkavitaet *)
  fValList.Add(TCO_SetupValue.Create('MSG_MaxScrapPerShift', '0')); (* RS 10.06.2014 - Etimex CZ - Wenn > 0 dann wird beim Überschreiten dieses Ausschuss-Wertes eine Email versendet *)
  fValList.Add(TCO_SetupValue.Create('MSG_WarnOnMachineRunningWithoutJob', '0')); (* RS 10.06.2014 - Etimex CZ - Wenn = 1 dann wird für Maschinen, die ohne Auftrag laufen, eine Email versendet *)
  fValList.Add(TCO_SetupValue.Create('FP_PersKalenderOhnePW', '0')); (* RS 08.07.2014 - Quarder CZ - Wenn = 1 dann muss für den Personal-Kalender kein Passwort eingegeben werden *)
  fValList.Add(TCO_SetupValue.Create('FP_PDEStammDefaultLayout3', '')); (* RS 24.07.2014 - suh - contains the default layout3 for the new entry in pdestamm*)
  fValList.Add(TCO_SetupValue.Create('INCL_AvgCycleTolerancePercent', '50')); (* RS 29.07.2014 - Optoflux/Eschenbach - Es wird aus Taktzeiten noch ein gemittelter Takt über den Toleranz-Bereich ermittelt *)
  fValList.Add(TCO_SetupValue.Create('MDE_Taktzeit_Show_Filtered_Average', '1')); (* RS 29.07.2014 - optoflus/eschenbach: Gemittelteter Isttakt wird nur gefiltert angezeigt *)
  fValList.Add(TCO_SetupValue.Create('INCL_StartenMitReparatur', '0')); (* RS 29.07.2014 - Optoflux/Eschenbach - Wenn = 1 können Aufträge trotz anliegender Reparatur für das Werkzeug gestartet werden *)
  fValList.Add(TCO_SetupValue.Create('MDE_ScrapTopFive', '0')); (* RS 29.07.2014 - Optoflux/Eschenbach - Wenn = 1 Wird eine Top5-Auswertung vom ReportService geholt*)
  fValList.Add(TCO_SetupValue.Create('MSG_Messenger2', '0')); (* ML 04.11.2014 - Verwendung für Messenger2 (.Net) nur für Administration*)
  fValList.Add(TCO_SetupValue.Create('INCL_ProducedInShiftWithoutSetup', '0')); (* ML 04.11.2014 - keine Produziert Zahlen wenn Auftrag in Rüsten*)
  fValList.Add(TCO_SetupValue.Create('INCL_WZLager', '1')); (* ML 15.12.2014 - Lagerverwaltung für Werkzeuge*)
  fValList.Add(TCO_SetupValue.Create('INCL_WZLaufzeitwarnung', '0')); (* ML 05.02.2015 - Meldung bei Überschreitung letzte Wartung *)
  fValList.Add(TCO_SetupValue.Create('INCL_TaktToleranz_AbsolutInSekunden', '-1')); (* RS 09.12.2014 - SLM - anstelle von prozentualenn Toleranzen können absolute Toleranzen für die taktzeitkontrolle verwendet werden*)
  fValList.Add(TCO_SetupValue.Create('INCL_Negative_Mold_Lifetime', '0')); (* RS 26.01.2015 - Optoflux - negative Iststandzeit wird für Werkzeuge zugegelassen *)
  fValList.Add(TCO_SetupValue.Create('INCL_RemainTime_Gross', '0')); (* RS 26.01.2015 - SuH - Nur wenn dieser Schalter auf 1 sitzt, wird maschinf.remaintime (Restlaufzeit) als Brutto-Laufzeit berechnet *)
  fValList.Add(TCO_SetupValue.Create('INCL_Correct_MasterAuftrag', '0')); (* RS 27.01.2015 - Quarder-CZ - pde.masterauftrag wird korrigiert, falls 'verwaiste' Einträge in pdekombi existieren *)
  fValList.Add(TCO_SetupValue.Create('FP_PlanReportShowCalendarOnTop', '0')); (* RS 30.01.2015 - Quarder CZ - Soll der Kalender im Vordergrund gezeigt werden, so dass deutlich sichtbar ist, wenn ein Auftrag "unterbrochen" sein soll *)
  fValList.Add(TCO_SetupValue.Create('INCL_Restlaufzeit_Aus_AuftragsKav', '0')); (* RS 13.02.2015 - SuH - Restlaufzeit wird im Dienst aus Auftrags-ist-Kavität berechnet; z.B. Wenn Werkzeugschalter aktiv ist, aber Dummy-Werkzeuge verwendet werden *)
  fValList.Add(TCO_SetupValue.Create('FP_AlivetimerApps', '''''SAPInterface'''',''''ERPInterface''''')); (* RS 05.03.2015 - Optoflux / Kautex: Die Alivetimer-Einträge für die Signalisierung des Schnittstellen-Stillstands können parametrisiert werden *)
  fValList.Add(TCO_SetupValue.Create('WS_Immer_Rahmen', '0')); (* RS 18.03.2015 - Optoflux - Die alte Werkstatt kann global mit Fensterrahmen erzwungen werden *)
  fValList.Add(TCO_SetupValue.Create('FP_WarnungTaktNull', '0')); (* RS 19.03.2015 - Optoflux - Warnung in FP falls Takzeit = 0 beim Einplanen *)
  fValList.Add(TCO_SetupValue.Create('SPC_MittelWertAnzahl', '10')); (* RS 25.03.2015 - SuH - Anzahl der Schüsse, die nach Freigabe-Button drücken gemittelt werden*)
  fValList.Add(TCO_SetupValue.Create('SPC_MittelWertMaxStilllDauer', '0')); (* RS 25.03.2015 - SuH - Maximale Stillstandsdauer während Freigabe-Prozess, bevor Freigabe neu startet*)
  fValList.Add(TCO_SetupValue.Create('SPC_MittelWertMaxAbweichung_Prozent', '10')); (* RS 25.03.2015 - SuH - Anzahl der zulässigen Ausreißer während Freigabe *)
  fValList.Add(TCO_SetupValue.Create('SPC_Abweichung_Nachfolgend', '5')); (* RS 25.03.2015 - SuH - Anzahl der unmittelbar nachfolgenden Abweichungen bevor Alarmierung erfolgt*)
  fValList.Add(TCO_SetupValue.Create('SPC_Abweichung_AnzahlIn_Stichprobe', '10')); (* RS 25.03.2015 - SuH - Anzahl der Abweichungen in Stichprobe bevor Alarmierung erfolgt*)
  fValList.Add(TCO_SetupValue.Create('SPC_Groesse_Stichprobe', '100')); (* RS 25.03.2015 - SuH - Stichproben-Größe für Stichproben-Größe für Abweichung/Mittelwert-Berechnung*)
  fValList.Add(TCO_SetupValue.Create('SVC_BuchungBeiKavWechsel', '1')); (* RS 25.03.2015 - ESW - Bei AP33210 wurde fälschlicherweise regelmäßig "aus Versehen" der Zähler abgenullt*)
  fValList.Add(TCO_SetupValue.Create('INCL_AutoPauseNurBeiUngebuchtemStillstand', '1')); (* ML 11.05.2015 - Theta - Automatische Pausenbuchung passiert nur wenn Stillstand ungebucht oder rüsten ist*)
  fValList.Add(TCO_SetupValue.Create('MDE_ZeigeWerkzeugErinnerung', '1')); (* ML 11.05.2015 - Pezet - Erinnerung bei Werkzeug Repa zeigen*)
  fValList.Add(TCO_SetupValue.Create('INCL_NewDownTimeOnJobStart', '0')); (* RS 21.04.2015 - ESW - Bei Auftragstart wird auf jeden Fall ein neuer Stillstand angelegt, wenn die Maschine schon steht *)
  fValList.Add(TCO_SetupValue.Create('INCL_Increment_Mold_Lifetime2', '1')); (* RS 28.05.2015 - SUH - Man kann die Iststandzeit2 auch dekrementieren lassen wie iststandzeit. Dann wird sie aber nicht mehr automatisch abgenullt *)
  fValList.Add(TCO_SetupValue.Create('FP_Days_Past', '60')); (* RS 02.06.2015 - Optoflux, man kann auch weiter als 60 Tage zurück in der Plangrafik *)
  fValList.Add(TCO_SetupValue.Create('FP_Days_Future', '365')); (* RS 02.06.2015 - Optoflux, man kann auch weiter als 365 Tage in die Zukunft in der Plangrafik *)
  fValList.Add(TCO_SetupValue.Create('MJA_Repair_Email_Categories', '')); (* RS 24.06.2015 - Optoflux, die Kategorien, aus denen der Nutzer beim Abschließen einer Grundreinigung wählen kann *)
  fValList.Add(TCO_SetupValue.Create('MJA_Repair_Show_Preparationtime', '0')); (* RS 25.06.2015 (Optoflux) Beim Beenden einer Reparatur wird gefragt, ob alle Reparaturen dieses Werkzeugs beendet werden sollen *)
  fValList.Add(TCO_SetupValue.Create('FP_ChangeProductionOrderAmount', '0')); (* ML 10.09.2015 (Rotho) Ändern der Kopfmenge (Sollmenge in Produktionsauftrag) in FP *)
  fValList.Add(TCO_SetupValue.Create('FP_WerkzeugAendern_BeimEinplanen', '1')); (* RS 03.08.2015 (SuH) Das Werkzeug eines Auftrags kann nicht verändert werden *)
  fValList.Add(TCO_SetupValue.Create('INCL_KapaFaktor_ProMaschine', '0')); (* RS 11.12.2015 (Optoflux) Je Arbeitsplatz kann ein Kapazitätsfaktor (Anzahl Arbeitsplätze) hinterlegt werden *)
  fValList.Add(TCO_SetupValue.Create('FP_WzStatusStattKommentar', '0')); (* RS 15.12.2015 (Dietz) Beim Einplanen wird statt des Kommentar-Felds der Status des Werkzeugs angezeigt *)
  fValList.Add(TCO_SetupValue.Create('INCL_AutostartZeitNachRuesten', '0')); (* ??? *)
  fValList.Add(TCO_SetupValue.Create('IF_ExportAllePdeEventESchichtwechsel', '0')); (* ML 15.02.2016 (Mentor) zyklischer  Export aller Aufträge nach ProAlpha *)
  fValList.Add(TCO_SetupValue.Create('INCL_UpdateTaktzeitFolgeauftraege', '0')); (* ML 29.02.2016 (Theta) Nur Taktzeit auf Folgeaufträge übernehmen wenn aktiv *)
  fValList.Add(TCO_SetupValue.Create('INCL_ShiftProducedWithoutRuntime', '0')); (* RS 31.03.2016 (Kienle) Wenn 1, dann wird auch bei Schicht-Einträgen ohne Laufzeit die Menge nicht abgenullt *)
  fValList.Add(TCO_SetupValue.Create('ERP_VorhandeneAuftraegeErneutUebertragen', '0')); (* ML 20.12.2016 Einträge in ERPIMPORT auch durchführen wenn Auftrag bereits vorhanden *)
  fValList.Add(TCO_SetupValue.Create('INCL_SOAHandling', '0')); (* ML 13.02.2017 SOA Faktor Verwalten (GSH) *)
  fValList.Add(TCO_SetupValue.Create('INCL_MoldPrewarningsFromBdaSvc', '0'));
  fValList.Add(TCO_SetupValue.Create('Wartung_Verlaengert_Auftrag', '0')); (* ML 19.04.2021 Wartung verlängert Auftrag bei Überlappung (Technoform) *)
  fValList.Add(TCO_SetupValue.Create('FP_TimeStepFilterCustomSteps', '')); (* ML 19.10.2021 Zusätzliche Auswahl an Tagen für Feinplanung (z.B. 365, 450,) *)
  fValList.Add(TCO_SetupValue.Create('MJA_Activate_Mustern', '0')); (* ML 07.01.2022 Mustern Funktion (Rotho) *)
  FQuery.SQL.Text := 'SELECT * FROM setup';
  FQuery.Open;
  if not FQuery.IsEmpty then
    for I := 0 to FQuery.Fields.Count - 1 do
      fSetupList.Add(TCO_SetupValue.Create(FQuery.Fields[I].Fieldname, FQuery.Fields[I].AsString));
end;

function TCO_Setup.GetCount: Integer;
begin
  Result := fValList.Count;
end;

function TCO_Setup.GetItem(AIndex: string): TCO_SetupValue;
var
  _i: Integer;
begin
  Result := nil;
  for _i := 0 to fValList.Count - 1 do
    if fValList.Items[_i].KeyName = AIndex then
      Result := fValList.Items[_i];

  if Result = nil then
    for _i := 0 to fSetupList.Count - 1 do
      if fSetupList.Items[_i].KeyName = AIndex then
        Result := fSetupList.Items[_i];

 { if Result = nil then
    raise Exception.Create('No Parameter named ' + AIndex + ' exists');}
end;

function TCO_Setup.GetItemByNr(AIndex: Integer): TCO_SetupValue;
begin
  Result := fValList.GetItems(AIndex);
end;

class function TCO_Setup.GetParam(aQuery: TCO_Query; aParameter: string; aDirect: Boolean): string;
var val : TCO_SetupValue;
begin
  CS_CO_Setup.Enter;
  try
    if CCO_Setup = nil then
      CCO_Setup := TCO_Setup.Create(aQuery);
    if aDirect then
      CCO_Setup.RefreshList;
    val :=CCO_Setup.GetItem(aParameter);
    if val <> nil then
      Result := val.CurrVal
    else
      Result := '';
  except
    Result := '';
  end;
  CS_CO_Setup.Leave;
end;

class function TCO_Setup.GetParamBool(aQuery: TCO_Query; aParameter: string; aDirect: Boolean): Boolean;
var
  S: string;
begin
{$IFDEF DEBUG}
  try
    S := GetParam(aQuery, aParameter, aDirect);
    Result := (S <> '0') and (S <> '') and (S <> ' ');
  except
    on ex: Exception do
    begin
      ShowMessage('Exeption in CO_Setup:' + ex.Message + ' - S: ' + S);
    end;
  end;
{$ELSE}
  S := GetParam(aQuery, aParameter, aDirect);
  Result := (S <> '0') and (S <> '') and (S <> ' ');
{$ENDIF}
end;


class function TCO_Setup.GetParamInt(aQuery: TCO_Query; aParameter: string; aDirect: Boolean): Integer;
var
  S: string;
  A: Integer;
begin
  S := GetParam(aQuery, aParameter, aDirect);
  try
    A := StrToInt(S);
  except
    A := 0;
  end;
  Result := A;
end;

class function TCO_Setup.GetParamDouble(aQuery: TCO_Query; aParameter: string; aDirect: Boolean): double;
var
  S: string;
  A: Double;
begin
  S := GetParam(aQuery, aParameter, aDirect);
  try
    S := StringReplace(S,'.',DecimalSeparator,[]);
    A := StrToFloat(S);
  except
    A := 0;
  end;
  Result := A;
end;

class function TCO_Setup.GetParamStr(aQuery: TCO_Query; aParameter: string; aDirect: Boolean): string;
begin
  Result := GetParam(aQuery, aParameter, aDirect);
end;

class procedure TCO_Setup.SetParam(aQuery: TCO_Query; aParameter: string; AValue: Boolean; writeToDb: Boolean = true);
begin
  if AValue then
    SetParam(aQuery, aParameter, '1', writeToDb)
  else
    SetParam(aQuery, aParameter, '0', writeToDb);
end;

class procedure TCO_Setup.SetParam(aQuery: TCO_Query; aParameter: string; AValue: Integer; writeToDb: Boolean = true);
begin
  SetParam(aQuery, aParameter, IntToStr(AValue), writeToDb);
end;

class procedure TCO_Setup.SetParam(aQuery: TCO_Query; aParameter: string; AValue: double; writeToDb: Boolean = true);
begin
  SetParam(aQuery, aParameter, FloatToStr(AValue), writeToDb);
end;

class procedure TCO_Setup.SetParam(aQuery: TCO_Query; aParameter: string; AValue: string; writeToDb: Boolean = true);
var
  V: TCO_SetupValue;
begin
  CS_CO_Setup.Enter;
  try
    if CCO_Setup = nil then
      CCO_Setup := TCO_Setup.Create(aQuery);
    V := CCO_Setup.GetItem(aParameter);
    V.CurrVal := AValue;
    if writeToDb then
      V.Save(aQuery);
  except
  end;
  CS_CO_Setup.Leave;
end;

procedure TCO_Setup.RefreshList;
var
  _s: string;
  _i, _j: Integer;
  _val: TCO_SetupValue;
begin
  _s := 'SELECT * FROM setup_par order by nr';
  FQuery.SQL.Text := _s;
  FQuery.Open;
  while not FQuery.EOF do
  begin
    try
      _val := GetItem(FQuery.FieldByName('schluessel').AsString);
    except
      _val := nil;
    end;

    if _val <> nil then
    begin
      try
        _val.CurrVal := FQuery.FieldByName('wert').AsString;// AsVariant; //.AsString;
      except
        _val.CurrVal := '';
      end;
      _val.Exists := True;
    end;
    FQuery.Next;
  end;

  for _i := 0 to fValList.Count - 1 do
  begin
    if not fValList.Items[_i].Exists then
    begin
     FQuery.SQL.Text := 'SELECT MAX(Nr)+1 cnt FROM Setup_Par';
        FQuery.Open;
        _j := FQuery.FieldByName('CNT').AsInteger;
      FQuery.SQL.Text := 'insert into Setup_Par (Nr, Schluessel, Wert) values (' + IntToStr(_j)
        + ', ''' + fValList.Items[_i].KeyName + ''', ''' + fValList.Items[_i].DefVal + ''')';
      try
        FQuery.ExecSQL;
      except
       FQuery.SQL.Text := 'SELECT MAX(Nr)+1 cnt FROM Setup_Par';
        FQuery.Open;
        _j := FQuery.FieldByName('CNT').AsInteger;
        FQuery.SQL.Text := 'insert into Setup_Par (Nr, Schluessel, Wert) values (' + IntToStr(_j)
          + ', ''' + fValList.Items[_i].KeyName + ''', ''' + fValList.Items[_i].DefVal + ''')';
        FQuery.ExecSQL;
      end;
    end;
  end;
end;

{ TCO_SetupList }

procedure TCO_SetupList.Add(aItem: TCO_SetupValue);
begin
  aItem.Exists := False;
  inherited Add(aItem);
end;

constructor TCO_SetupList.Create;
begin
  inherited;
end;

destructor TCO_SetupList.Destroy;
begin
  inherited;
end;

function TCO_SetupList.GetItems(AIndex: Integer): TCO_SetupValue;
begin
  Result := Get(AIndex);
end;

{ TCO_SetupValue }

constructor TCO_SetupValue.Create(aKeyName, aDefVal: string);
begin
  inherited Create;
  KeyName := aKeyName;
  DefVal := aDefVal;
  CurrVal := '';
end;

procedure TCO_SetupValue.Save(aQuery: TCO_Query);
begin
  aQuery.SQL.Text := 'UPDATE Setup_Par SET Wert = ''' + CurrVal
    + ''' WHERE schluessel = ''' + KeyName + '''';
  try
    aQuery.ExecSQL;
  except
  end;
end;

initialization

  CCO_Setup := nil;
  CS_CO_Setup := TCriticalSection.Create;
finalization

  if CCO_setup <> nil then
  try
    CCO_Setup.Destroy;
  except
  end;
  CS_CO_Setup.Release;
  CS_CO_Setup.Free;

end.


