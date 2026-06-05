unit Th_Schicht;

interface

uses
  Windows, Classes, CO_DataBase, SysUtils, Math, CO_TPM_V63, CO_INCMeldung_V63, CO_AliveTimer, CO_SPC_V63;

type
  TThread_Schicht = class(TThread)
  private
    CDatabase: TCO_Database;

    qSuch, qSuch2, qSuch3, qSuch4: TCO_Query;
    qUpdate, qDurchlauf: TCO_Query;
    ThTPM: TCO_TPM;
    Th_Meldung: TCO_INCMeldung;
    FNachBerechnung: Boolean;
    LogFile_Mode: Integer;
    SQLStr: string;
    ShiftAliveTimer: TCO_AliveClient;

    function GetSignalNr(Query: TCO_Query; SignalArt: Integer): Integer;
    function Schichtwechsel: Boolean;
    procedure StartSchichtWechsel(AlteSchicht: Integer);
    // procedure Korrektur_Produziert_nach_Schichtwechsel(aSchicht: Integer);
    // procedure TPM_Stillstand_Schichtwechsel;
    procedure Berechne_Extrusion(TPMNr: Integer; AuftragNr: string; Von, Bis: Real);
    procedure TPM_Leistung_Gesamt_Update;    (* Unfug Funktion *)
    procedure TPM_Produziert_Gesamt_Update;     (* Unfug Funktion *)
    procedure GetStillZeit(VonDatum, BisDatum: TDateTime; MaschNr, Stillstandnr: Integer;
      AStart, AEnde: Real; var Dauer, Anzahl, ADauer: Integer);
    function GetArtikelNr(AuftragNr: string): string;
    procedure SetNachBerechnung(const Value: Boolean);


  protected
    procedure Execute; override;

  public
    AlteSchicht: Integer;
    Schicht_Berechnung: Boolean;
    Berechnung_aktiv: Boolean;

    Recalculate_Mode: Boolean;
    ThSPC : TCO_SPC;

    procedure TPM_Schicht_Schicht3; (* Unfug Funktion *)
    procedure Berechne_A_Daten(Von, Bis: Real; MNrs: string);
    procedure TPM_Korrektur(Von, Bis: Real; Berechnen_TPM_Auswertung: Boolean; MNrs: string);
    procedure TPM_Stillog_Korrektur(Arc_Tag, Kor_Tag: Integer);
    procedure TPM_Schicht_Pruefen(Tage: Integer);
    procedure Berechne_Stillstaende_Schicht(aTage: Integer);
    procedure CheckLaufzeitLog;

    procedure Berechne_TPM_Schicht_Verpackt_Ausschuss(Days: Integer; MNrs: string);
    procedure Nachbuchen_aus_AArchiv(Days: Integer; MNrs: string);

    procedure Berechne_TPM_Auftragsdetail(Days: Integer; MNRs: string);
    procedure Berechne_TPM_Auswertung(Von, Bis: TDateTime; MNRs: string);
    procedure TPM_AuswertungKorrektur;
    procedure Berechne_TPM_Produktionsdetail(Days: Integer; MNrs: string);
    procedure Berechne_TPM_ProduktionsdetailDebug(Start : Extended; Days: Integer; MNrs: string);

    function Recalculation: Integer;

    property NachBerechnung: Boolean read FNachBerechnung write SetNachBerechnung;

    constructor Create(Suspended: Boolean);
    destructor Destroy; override;
  end;

var
  Thread_Schicht: TThread_Schicht;

implementation

uses
    {$IFNDEF AZURE}
  Main,
  {$ELSE}
  MainAzure,
  {$ENDIF}

  DBMain,  Sprache_V63, Arbeit, SQL_fuc, CO_Setup2, U_SPC, Maindll, Dialogs,
  CO_Library_V63, IniFiles, DB;

constructor TThread_Schicht.Create(Suspended: Boolean);
var
  LaengsteSchicht: Real;
begin
  inherited Create(Suspended);
  FreeOnTerminate := False;
  Priority := tpNormal;
  FNachBerechnung := False;

  CDatabase := TCO_Database.Create(nil);
  CDatabase.UserName := DBUser;
  CDatabase.Password := DBPass;
  CDatabase.Server := DBServer;
  {$IF INCLUDISDatabaseTyp = 1}
      CDatabase.InitialCatalog := DBInitialCatalog;
  {$IFEND}



  qSuch := TCO_Query.Create(nil);
  qSuch.Database := CDatabase;

  qSuch2 := TCO_Query.Create(nil);
  qSuch2.Database := CDatabase;

  qSuch3 := TCO_Query.Create(nil);
  qSuch3.Database := CDatabase;

  qSuch4 := TCO_Query.Create(nil);
  qSuch4.Database := CDatabase;

  qUpdate := TCO_Query.Create(nil);
  qUpdate.Database := CDatabase;

  qDurchlauf := TCO_Query.Create(nil);
  qDurchlauf.Database := CDatabase;

  qSuch.Tag := 2;
  qSuch2.Tag := 2;
  qSuch3.Tag := 2;
  qSuch4.Tag := 2;
  qUpdate.Tag := 2;
  qDurchlauf.Tag := 2;

  CO_TPMGetL := @GetL;
  ThTPM := TCO_TPM.Create(nil);
  ThTPM.Database := CDatabase;

  if @CO_SPCGetL = nil then
    CO_SPCGetL := @GetL;
  ThSPC := TCO_SPC.Create(nil);
  ThSPC.OraSession := CDatabase;

  Th_Meldung := TCO_INCMeldung.Create(nil);
  Th_Meldung.ApplicationID := INC_Application;
  Th_Meldung.RechnerNr := 0;
  Th_Meldung.Database := CDatabase;

  Schicht_Berechnung := True;

  Recalculate_Mode := False;
  LogFile_Mode := 2;

  LaengsteSchicht := Schicht2 -  Schicht1;
  if (Shift_Model = 2) then
  begin
    if (1 + Schicht1 - Schicht2) > LaengsteSchicht then
      LaengsteSchicht := 1 + Schicht1 - Schicht2;
  end
  else
  begin
    if (Schicht3 - Schicht2) > LaengsteSchicht then
      LaengsteSchicht := Schicht3 - Schicht2;
    if (1 + Schicht1 - Schicht3) > LaengsteSchicht then
      LaengsteSchicht := 1 + Schicht1 - Schicht3;
  end;
  ShiftAliveTimer := TCO_AliveClient.Create(CDatabase, 'ServiceShiftChange', Trunc(LaengsteSchicht * 86400), nil,
  ForceBackSlash(INCLUDIS_HOME + TRACE_DIR) + 'svc_' + LowerCase(DBUser) + '_shift.log',  SERVICE_DISPLAY_NAME + UpperCase(DBUser));
  ShiftAliveTimer.tick;
end;
// *****************************************************************************

destructor TThread_Schicht.Destroy;
begin
  qSuch.Free;
  qSuch2.Free;
  qSuch3.Free;
  qSuch4.Free;
  qUpdate.Free;
  qDurchlauf.Free;
  ThTPM.Free;
  Th_Meldung.Free;

  ShiftAliveTimer.Free;

  CDatabase.Free;

  inherited Destroy;
end;
// *****************************************************************************

procedure TThread_Schicht.Execute;
var
  I: Integer;
  s, terminatedString : string;
begin
  while not Terminated do
  begin
    try
    SchreibeMeldung('Wait for Single Object...', 2);
      WaitForSingleObject(Event_Schicht, INFINITE);
    SchreibeMeldung('Single Object triggered', 2);
      if INCLUDISDatabaseTyp = dbTypMSSQL then
      begin
        DecimalSeparator := '.';
        ThousandSeparator := ',';
      end;

    SchreibeMeldung('Start check Database.' , 2);
      while not CheckCO_DatabaseConnect(CDatabase, qUpdate, 2, 'Shift') do
      begin
        // 30 Sekunden warten
        for i:=1 to 10 do
        begin
          sleep(1000);
          if Terminated then
          begin
    SchreibeMeldung('Shift Calc Terminated - 1'  , 2);
            Exit;
          end;
        end;
      end;
    SchreibeMeldung('Database seems active', 2);
      Berechnung_aktiv := True;
      try
        if Terminated then
         begin
    SchreibeMeldung('Shift Calc Terminated - 2'  , 2);
            Exit;
          end;
        if Recalculate_Mode then
        begin
          LogFile_Mode := 4;
    SchreibeMeldung('Start Recalc', 2);
          I := Recalculation;
    SchreibeMeldung('End Recalc', 2);
        end
        else
        begin
          LogFile_Mode := 2;
    SchreibeMeldung('Start Shift Change', 2);
          StartSchichtWechsel(AlteSchicht);
    SchreibeMeldung('End Shift Change', 2);
        end;
      finally
        Berechnung_aktiv := False;
      end;
     SchreibeMeldung('End of Block', 2);
     SchreibeMeldung('-------------------------------------------------------------------', 2);
   except
      on E: Exception do
      begin
        if Terminated then
          s := 'TERMINATED';
        SchreibeMeldung('Exception (' + IntToStr(I) + ') Schicht.Execute('+s+'): ' + E.message, LogFile_Mode);
      end;
    end;
  end;

  SchreibeMeldung('Shift Calc Terminated. Leaving Block'  , 2);
end;
// *****************************************************************************

function TThread_Schicht.GetSignalNr(Query: TCO_Query; SignalArt: Integer): Integer;
begin
  if SQLGetBool(Query, 'SIGNALE', 'SignalArt', IntToStr(SignalArt)) then
    Result := Query.FieldByName('SignalNr').AsInteger
  else
    Result := -1;
end;
// *****************************************************************************

function TThread_Schicht.Schichtwechsel: Boolean;
var
  SignalNr: Integer;
  MaschNr: Integer;
  manuell: Boolean;
begin
  Result := True;
  MaschNr := 0;
  SignalNr := GetSignalNr(qSuch3, CSCHICHTWECHSEL);

  try
    //Set the database in order for the TPM-class to be properly re-initialized
//{$IF NOT INCLUDISDatabaseTyp = 1}
    ThTPM.ReInit;
//{$IFEND}
  except on ex: Exception do
    SchreibeMeldung(ex.Message + ' on reinit of ShiftTPM', 0);
  end;


  SQLStr := 'SELECT manuelle_Buchung FROM setup WHERE nr = 1';
  try
    SQL_Get(qSuch4, SQLStr);
    manuell := qSuch4.FieldByName('manuelle_Buchung').AsInteger = 1;
  except
    manuell := False;
  end;
  //Prüfen, ob Datensatz schon erzeugt wurde...
  if not manuell then
  begin
    if SQL2GetBool(qSuch4, 'SIGNAL_SCHREIBEN', 'MaschNr', IntToStr(MaschNr), 'SignalNr', IntToStr(SignalNr)) then
      Exit;

    SQLStr := 'INSERT INTO SIGNAL_SCHREIBEN (Nr,MaschNr,SignalNr,Wert)'
      + 'VALUES(SIGNAL_SCHREIBENID.NextVal'
      + ',''' + IntToStr(MaschNr)
      + ''',''' + IntToStr(SignalNr)
      + ''',''1'
      + ''')';
    SQL_Insert(qUpdate, SQLStr);
  end;
  // MAnuelle Buchungen

  if manuell then // Wenn manuelle Buchungen, Schichtbezogene Signale auf 0 setzen
  begin
    SignalNr := GetSignalNr(qSuch3, CSTUECKAUFTRAGSCHICHT);
    SQLStr := 'UPDATE signal_maschine SET istwert = 0 WHERE signalnr = ' + IntToStr(SignalNr);
    SQL_Insert(qUpdate, SQLStr);

    SignalNr := GetSignalNr(qSuch3, CSTUECKSCHICHT);
    SQLStr := 'UPDATE signal_maschine SET istwert = 0 WHERE signalnr = ' + IntToStr(SignalNr);
    SQL_Insert(qUpdate, SQLStr);
  end;

  SchreibeMeldung('Shift change proceeded', LogFile_Mode);
end;

procedure TThread_Schicht.StartSchichtWechsel(AlteSchicht: Integer);
var
  Datum: Integer;
  I: Integer;
  Ini: TIniFile;
  Von, Bis: Real;
begin
  MakeEnviroment(qUpdate);
  ShiftAliveTimer.tick;

  if not Schicht_Berechnung then
  begin
    SchreibeMeldung('*** Start recalculation', LogFile_Mode);

    Von := Trunc(N_o_w - TCO_Setup.GetParamInt(qSuch, 'INCL_Days_TPM_Auswertung'));
    Bis := N_o_w;

    TPM_Korrektur(Von, Bis, True, '');
    CheckLaufzeitLog;
    SchreibeMeldung('*** End recalculation', LogFile_Mode);
    SchreibeMeldung('----------------------------------------------------', LogFile_Mode);
    Exit;
  end;

  SchreibeMeldung('*** Start shift recalculation (' + IntToStr(AlteSchicht) + ')', LogFile_Mode);

  Datum := Trunc(N_o_w);
  if AlteSchicht = 3 then
    Datum := Datum - 1;
  Nach_Schichtwechsel := True;

  //  Abweichungen_saeubern
  SQLStr := 'Delete from SPCAus Where DatumZeit < ''' + FloatToStr2(Trunc(Datum - 1)) + '''';
  SQL_Insert(qUpdate, SQLStr);

  Schichtwechsel;
  SchreibeMeldung('Shift change', LogFile_Mode);

  // Korrektur_Produziert_nach_Schichtwechsel(AlteSchicht);
  // SchreibeMeldung(GetL('Korrektur_Produziert'), LogFile_Mode);

  Th_Meldung.ServerStatusOK;

  for I := 1 to Anzahl_Masch do
  begin
    if Includis[I].IstArchiviert then
      Continue;
    if SQLGetBool(qSuch4, 'PACKMASCH', 'Lizenz', Includis[I].Lizenz) then
      UpdateSQL(qUpdate, 'PACKMASCH', 'StueckPackSchicht', '0', 'Lizenz', Includis[I].Lizenz);
    if SQLGet(qSuch4, 'PACKAUFTRAG', 'Betriebsauftragnr', Includis[I].Auftrag.BetriebsauftragNr, True) > 0 then
      UpdateSQL(qUpdate, 'PACKAUFTRAG', 'StueckPackAuftragSchicht', '0', 'Betriebsauftragnr',
        Includis[I].Auftrag.BetriebsauftragNr);
  end;

  // aus der Funktion Daten-Schreiben geschoben
  // Sascha. 06.04.2005
  (* rausgeschmissen wegen Optmierungsversuch. NULL Werte sollte es nicht mehr geben ML 14.10.2022
  SQLStr := 'update tpm_schicht set leistung = 0 where leistung is NULL';
  SQL_Insert(qSuch, SQLStr);
  SQLStr := 'update tpm_schicht set PRODUZIERT = 0 where PRODUZIERT is NULL';
  SQL_Insert(qSuch, SQLStr);
  SQLStr := 'update tpm_schicht set PRODUZIERT_ORG = 0 where PRODUZIERT_ORG is NULL';
  SQL_Insert(qSuch, SQLStr);
  SQLStr := 'update tpm_schicht set STOPS = 0 where STOPS is NULL';
  SQL_Insert(qSuch, SQLStr);
  SQLStr := 'update tpm_schicht set GEPLANT = 0 where GEPLANT is NULL';
  SQL_Insert(qSuch, SQLStr);
  SQLStr := 'update tpm_schicht set UNGEPLANT = 0 where UNGEPLANT is NULL';
  SQL_Insert(qSuch, SQLStr);
  SQLStr := 'update tpm_schicht set NICHTGEBUCHT = 0 where NICHTGEBUCHT is NULL';
  SQL_Insert(qSuch, SQLStr);

  SQLStr := 'update tpm_schicht set PRODUZIERT = 0 where BetriebsAuftragNr is NULL and Produziert > 0';
  SQL_Insert(qSuch, SQLStr);
  SQLStr := 'update tpm_schicht set PRODUZIERT_ORG = 0 where BetriebsAuftragNr is NULL and PRODUZIERT_ORG > 0';
  SQL_Insert(qSuch, SQLStr);

  SQLStr := 'update AARCHIV set TAKTZEITSOLL = 0 where TAKTZEITSOLL is NULL';
  SQL_Insert(qSuch, SQLStr);
  SQLStr := 'update AARCHIV set TAKTZEITIST = 0 where TAKTZEITIST is NULL';
  SQL_Insert(qSuch, SQLStr);
  SQLStr := 'update AARCHIV set LAUFZEITSOLL = 0 where LAUFZEITSOLL is NULL';
  SQL_Insert(qSuch, SQLStr);
  SQLStr := 'update AARCHIV set LAUFZEITIST = 0 where LAUFZEITIST is NULL';
  SQL_Insert(qSuch, SQLStr);
  SQLStr := 'update AARCHIV set SOLLVORGABEINT = 0 where SOLLVORGABEINT is NULL';
  SQL_Insert(qSuch, SQLStr);
  SQLStr := 'update AARCHIV set AUFTRAGNR = 0 where AUFTRAGNR is NULL';
  SQL_Insert(qSuch, SQLStr);
  SQLStr := 'update AARCHIV set BEZEICHNUNG = 0 where BEZEICHNUNG is NULL';
  SQL_Insert(qSuch, SQLStr);
  SQLStr := 'update AARCHIV set WERKZEUGNR = 0 where WERKZEUGNR is NULL';
  SQL_Insert(qSuch, SQLStr);

  SQLStr := 'update tpm_schicht set ungeplant = ' + IntToStr(MaxSchichtTime) + ' where ungeplant > ' + IntToStr(MaxSchichtTime) + '';
  SQL_Insert(qUpdate, SQLStr);
  SQLStr := 'update tpm_schicht set geplant = ' + IntToStr(MaxSchichtTime) + ' where geplant > ' + IntToStr(MaxSchichtTime) + '';
  SQL_Insert(qUpdate, SQLStr);
  SQLStr := 'update tpm_schicht set anlagenausfall = ' + IntToStr(MaxSchichtTime) + ' where anlagenausfall > '
    + IntToStr(MaxSchichtTime) + '';
  SQL_Insert(qUpdate, SQLStr);
  SQLStr := 'update tpm_schicht set RUESTEN = ' + IntToStr(MaxSchichtTime) + ' where RUESTEN > ' + IntToStr(MaxSchichtTime) + '';
  SQL_Insert(qUpdate, SQLStr);
  SQLStr := 'update tpm_schicht set LOGISTIK = ' + IntToStr(MaxSchichtTime) + ' where LOGISTIK > ' + IntToStr(MaxSchichtTime) + '';
  SQL_Insert(qUpdate, SQLStr);
  SQLStr := 'update tpm_schicht set NICHTGEBUCHT = ' + IntToStr(MaxSchichtTime) + ' where NICHTGEBUCHT > ' + IntToStr(MaxSchichtTime) + '';
  SQL_Insert(qUpdate, SQLStr);
   *)
  SchreibeMeldung('SQL adjustment', LogFile_Mode);

  if Stillstaende_Schicht > 0 then // Zum Schichtwechsel Stillstände Schicht-bezogen berechnen
  try
    Berechne_Stillstaende_Schicht(Stillstaende_Schicht);
  except
    SchreibeMeldung(GetL('Reason: Stillstaende_Schicht'), LogFile_Mode);
  end;

  //Ausführung morgens 6:00 Uhr oder (und) zwichen Schicht 1 und 2
  if (AlteSchicht = 3)
    or ((Shift_Model = 2) and (AlteSchicht = 2))
    or ((AlteSchicht = 1) and TCO_Setup.GetParamBool(qSuch, 'INCL_Schichtberechnung1')) then
  begin
    if Recalculation_Time > 0 then
    begin
      Von := Trunc(N_o_w - 2);
      if Shift_Model = 2 then
        Von := Von + Schicht2 - 10 / 1440
      else
        Von := Von + Schicht3 - 10 / 1440;
    end
    else
      Von := Trunc(N_o_w - TCO_Setup.GetParamInt(qSuch, 'INCL_Days_TPM_Auswertung'));

    Bis := N_o_w;
    try
      TPM_Korrektur(Von, Bis, True, '');
      SchreibeMeldung('TPM adjustment proceeded ...', LogFile_Mode);
    except on ex:exception do
      SchreibeMeldung('TPM adjustment exception : ' + ex.Message, LogFile_Mode);
    end;

  end;

  if SPC then
  begin
    try
      SPC_Schichtberechnung(AlteSchicht, ThSPC);
      SchreibeMeldung('SPC shift calculation', LogFile_Mode);
    except on e:Exception do
      SchreibeMeldung('Exception during SPC shift calculation : ' + e.Message, LogFile_Mode);
    end;
  end;

  //*********************************************************************
  //** Änderung 27.05.04
  //*********************************************************************
  //Manuelles zurücksetzten der Schichtzähler
  //für STUECKAUFTRAGSCHICHT
  SQLStr := 'update signal_maschine set istwert = 0 where 2 = '
    + ' (select signalart from signale where signale.signalnr =  signal_maschine.signalnr)';
  SQL_Insert(qUpdate, SQLStr);
  SchreibeMeldung(GetL('STUECKAUFTRAGSCHICHT'), LogFile_Mode);

  //für STUECKSCHICHT
  SQLStr := 'update signal_maschine set istwert = 0 where 3 = '
    + ' (select signalart from signale where signale.signalnr =  signal_maschine.signalnr)';
  SQL_Insert(qUpdate, SQLStr);
  SchreibeMeldung(GetL('STUECKSCHICHT'), LogFile_Mode);
  //*********************************************************************

  Th_Meldung.ServerStatusOK;
  SchreibeMeldung(GetL('ServerStatus OK'), LogFile_Mode);

  if Metall then
  begin
    for I := 1 to Anzahl_Masch do
    begin
      Includis[I].StueckAuftragSchicht := 0;
      Includis[I].StueckSchicht := 0;
    end;
    SQLStr := 'update pde set stueckschicht = 0';
    SQL_Insert(qUpdate, SQLStr);
  end;

  {
  if Stillstand_Werksplanung then
    begin
      TPM_Stillstand_Schichtwechsel;
      SchreibeMeldung(GetL('TPM_Stillstand_Schichtwechsel'), LogFile_Mode);
    end;
    }

  SQLStr := 'update INC_Meldung set SchichtWechsel = 1';
  SQL_Insert(qUpdate, SQLStr);
  SchreibeMeldung('*** End of shift change', LogFile_Mode);
  SchreibeMeldung('----------------------------------------------------', LogFile_Mode);
  try
    Ini := TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'incl_' + DBUser + '.ini');
    Ini.WriteFloat('System', 'last_shift_change', N_o_w);
    Ini.Free;
  except
    SchreibeMeldung('Unable to write INI File', LogFile_Mode);
  end;

end;
// *****************************************************************************

procedure TThread_Schicht.Berechne_Stillstaende_Schicht(aTage: Integer);
var
  S: string;
  dt_anfang, dt_ende: Extended;
  zr_anfang, zr_ende: Extended;
  Schicht: Integer;
  I, J, K: Integer;
  anzahl_schichten: Integer;

  function GetSchicht(aDateTime: Extended): Integer;
  begin
    if Shift_Model = 2 then
    begin
      Result := 1;
      if Frac(aDateTime) < Schicht1 then
        Result := 2;
      if Frac(aDateTime) > Schicht2 then
        Result := 2;
    end
    else
    begin
      Result := 3;
      if Frac(aDateTime) + 0.0001 >= Schicht1 then
        Result := 1;
      if Frac(aDateTime) + 0.0001 >= Schicht2 then
        Result := 2;
      if Frac(aDateTime) + 0.0001 >= Schicht3 then
        Result := 3;
    end;
  end;

  function next_schicht(aSchicht: Integer): Integer;
  begin
    Result := aSchicht + 1;
    if (Shift_Model = 2) and (Result = 3) then
      Result := 1;
    if (Shift_Model = 1) and (Result = 4) then
      Result := 1;
  end;

begin
  if Shift_Model = 2 then
    anzahl_schichten := aTage * 2
  else
    anzahl_schichten := aTage * 3;

  zr_ende := N_o_w;
  // runden Von zr_Ende auf Schichtende
  if Shift_Model = 2 then
  begin
    Schicht := 2;
    if Frac(zr_ende) > Schicht1 then
      Schicht := 1;
    if Frac(zr_ende) > Schicht2 then
      Schicht := 2;
  end
  else
  begin
    Schicht := 3;
    if Frac(zr_ende) > Schicht1 then
      Schicht := 1;
    if Frac(zr_ende) > Schicht2 then
      Schicht := 2;
    if Frac(zr_ende) > Schicht3 then
      Schicht := 3;
  end;
  // Schicht := Schicht - 1;   //  Warum? Wir sind doch kurz im Schichtanfang (N_o_w)  26.04.07 Sascha

  if Schicht = 0 then
    if Shift_Model = 2 then
      Schicht := 2
    else
      Schicht := 3;

  case Schicht of
    1: zr_ende := Trunc(zr_ende) + Schicht1;
    2:
      if Shift_Model = 2 then
        zr_ende := Trunc(zr_ende) + Schicht2 - 1
      else
        zr_ende := Trunc(zr_ende) + Schicht2;
    3: zr_ende := Trunc(zr_ende) + Schicht3 - 1;
  end;
  zr_anfang := zr_ende - aTage;

  for I := 1 to Anzahl_Masch do
  begin
    if Includis[I].IstArchiviert then
      Continue;
    //Abgleichen der Stillstände mit geht = 0
    S := 'SELECT ts.geht, tss.kommt tsskommt, tss.nr tssnr FROM tpm_stillog_schicht tss, tpm_stillog ts'
      + ' WHERE tss.maschnr = ''' + IntToStr(I) + ''' AND tss.geht = 0 AND '
      + ' ts.nr = tss.tpm_stillnr AND ts.geht > 0';
    SQL_Get(qSuch, S);
    if not qSuch.IsEmpty then
    begin
      S := 'UPDATE tpm_stillog_schicht SET geht = ''' + qSuch.FieldByName('geht').AsString
        + ''', gehtstr = ''' + DateTimeToStr(qSuch.FieldByName('geht').AsFloat) + ''','
        + ' dauer = ''' + IntToStr(Round((qSuch.FieldByName('geht').AsFloat
        - qSuch.FieldByName('tsskommt').AsFloat) * 1440)) + ''' WHERE nr = '''
        + qSuch.FieldByName('tssnr').AsString + '''';
      SQL_Insert(qUpdate, S);
    end;

    // Update der Störgründe
    S := 'update tpm_stillog_schicht set stillstandnr = '
      + ' (select stillstandnr from tpm_stillog where nr = tpm_stillog_schicht.tpm_stillnr)'
      + ' WHERE maschnr = ''' + IntToStr(I) + '''';
    SQL_Insert(qUpdate, S);

    // Stillstände holen, die in diesem bereich liegen
    S := 'SELECT tpm_stillog.* FROM tpm_stillog '
      + ' LEFT OUTER JOIN tpm_stillog_schicht ON '
      + ' tpm_stillog.nr = tpm_stillog_schicht.tpm_stillnr '
      + ' WHERE tpm_stillog.kommt <= ''' + FloatToStr2(zr_ende)
      + ''' AND (tpm_stillog.geht >= ''' + FloatToStr2(zr_anfang)
      + ''' OR tpm_stillog.geht = 0 OR tpm_stillog.geht IS NULL) '
      + ' AND tpm_stillog.maschnr = ' + IntToStr(I)
      + ' AND tpm_stillog_schicht.tpm_stillnr IS NULL';
    (*
        S := 'SELECT * FROM tpm_stillog WHERE kommt <= ''' + FloatToStr2(zr_ende)
          + ''' AND (geht >= ''' + FloatToStr2(zr_anfang)
          + ''' OR geht = 0 OR geht IS NULL) AND maschnr = ''' + IntToStr(I)
          + ''' AND nr NOT IN (SELECT tpm_stillnr FROM tpm_stillog_schicht)';
          *)
    SQL_Get(qSuch, S);

    // Stillstände kopieren nach TPM_Stillog_Schicht
    while not qSuch.EOF do
    begin
      S := 'INSERT INTO tpm_stillog_schicht (Nr,Maschnr, Kommt, Geht, Schicht, '
        + 'StillstandNr, Dauer, Reaktionszeit, Erstellungsdatum, STOERUNG, '
        + 'AutoBuchung, RUESTPROT, BetriebsAuftragNr, '
        + 'AuftragNr, Bezeichnung, Shift_Typ, tpm_stillnr, KommtStr, GehtStr) VALUES ('
        + 'tpm_stillog_schichtid.nextval, '''
        + qSuch.FieldByName('Maschnr').AsString + ''', '''
        + qSuch.FieldByName('Kommt').AsString + ''', '''
        + qSuch.FieldByName('Geht').AsString + ''', '''
        + qSuch.FieldByName('Schicht').AsString + ''', '''
        + qSuch.FieldByName('StillstandNr').AsString + ''', '''
        + qSuch.FieldByName('Dauer').AsString + ''', '''
        + qSuch.FieldByName('Reaktionszeit').AsString + ''', '''
        + qSuch.FieldByName('Erstellungsdatum').AsString + ''', '''
        + qSuch.FieldByName('STOERUNG').AsString + ''', '''
        + qSuch.FieldByName('AutoBuchung').AsString + ''', '''
        + qSuch.FieldByName('RUESTPROT').AsString + ''', '''
        + qSuch.FieldByName('BetriebsAuftragNr').AsString + ''', '''
        + qSuch.FieldByName('AuftragNr').AsString + ''', '''
        + qSuch.FieldByName('Bezeichnung').AsString + ''', '''
        + '-'', '''
        + qSuch.FieldByName('nr').AsString + ''', '''
        + qSuch.FieldByName('KommtStr').AsString + ''', '''
        + qSuch.FieldByName('GehtStr').AsString + ''')';
      SQL_Insert(qUpdate, S);

      // Nachgucken, ob Stillstand über Schichtgrenzen hinausgeht
(*
      dt_anfang := frac(qSuch.FieldByName('Kommt').AsFloat);
      dt_ende := frac(qSuch.FieldByName('Geht').AsFloat);

      if GetSchicht(dtAnfang) <> GetSchicht(dt_Ende) then
      begin
        // Grenze ansehen

      end;
*)

      qSuch.Next;
    end;

    //Alle auf Geht auf 0 setzen die null als geht haben
    S := 'UPDATE tpm_stillog_schicht SET geht = 0 WHERE geht IS NULL AND maschnr = '''
      + IntToStr(I) + '''';
    SQL_Insert(qUpdate, S);

    // Jede Schicht für den Zeitraum ansehen
    dt_anfang := zr_anfang;

    for J := 1 to anzahl_schichten do
    begin
      for K := 1 to 2 do ///  Was bedeutet das? Warum zweimal? 26.04.07 Sascha
      begin
        if Shift_Model = 2 then
        begin
          Schicht := 1;
          if Frac(dt_anfang) + 0.001 < Schicht1 then
            Schicht := 2;
          if Frac(dt_anfang) + 0.001 > Schicht2 then
            Schicht := 2;
        end
        else
        begin
          Schicht := 3;
          if Frac(dt_anfang) + 0.001 >= Schicht1 then
            Schicht := 1;
          if Frac(dt_anfang) + 0.001 >= Schicht2 then
            Schicht := 2;
          if Frac(dt_anfang) + 0.001 >= Schicht3 then
            Schicht := 3;
        end;

        if Shift_Model = 1 then
        begin
          case Schicht of
            1: dt_ende := Trunc(dt_anfang) + Schicht2;
            2: dt_ende := Trunc(dt_anfang) + Schicht3;
            3: dt_ende := Trunc(dt_anfang) + 1 + Schicht1;
          else
            dt_ende := Trunc(dt_anfang) + Schicht2;
          end;

        end
        else
        begin
          case Schicht of
            1: dt_ende := Trunc(dt_anfang) + Schicht2;
            2: dt_ende := Trunc(dt_anfang) + 1 + Schicht1;
          else
            dt_ende := Trunc(dt_anfang) + Schicht2;
          end;
        end;
        // Nachsehen, ob Stillstände über Grenzen gehen

        S := 'SELECT * FROM tpm_stillog_schicht WHERE maschnr = ''' + IntToStr(I)
          + ''' AND kommt < ''' + FloatToStr2(dt_ende)
          + ''' AND (geht > ''' + FloatToStr2(dt_anfang)
          + ''' OR geht = 0)'
          + ' AND NOT (kommt >= ''' + FloatToStr2(dt_anfang)
          + ''' AND geht <= ''' + FloatToStr2(dt_ende) + ''')';

        SQL_Get(qSuch, S);

        while not qSuch.EOF do
        begin
          // Wenn ja, Stillstand splitten
          if not ((qSuch.FieldByName('kommt').AsFloat >= dt_anfang - 0.00001) and
            (qSuch.FieldByName('geht').AsFloat <= dt_ende + 0.00001)) then
          begin
            if (qSuch.FieldByName('kommt').AsFloat < dt_anfang - 0.00001)
              and (qSuch.FieldByName('geht').AsFloat > dt_anfang - 0.00001) then
              // Update aktuellen geht auf Anfang und erzeugen neuen kommt = anfang geht = Geht(alter)
            begin
              S := 'INSERT INTO tpm_stillog_schicht (Nr,Maschnr, Kommt, Geht, Schicht, '
                + 'StillstandNr, Dauer, Reaktionszeit, Erstellungsdatum, STOERUNG, '
                + 'AutoBuchung, RUESTPROT, BetriebsAuftragNr, '
                + 'AuftragNr, Bezeichnung, Shift_Typ, tpm_stillnr, KommtStr, GehtStr) VALUES ('
                + 'tpm_stillog_schichtid.nextval, '''
                + qSuch.FieldByName('Maschnr').AsString + ''', '''
                + FloatToStr2(dt_anfang) + ''', '''
                + qSuch.FieldByName('Geht').AsString + ''', '''
                + IntToStr(next_schicht(qSuch.FieldByName('schicht').AsInteger)) + ''', '''
                + qSuch.FieldByName('StillstandNr').AsString + ''', '''
                + IntToStr(Round((qSuch.FieldByName('geht').AsFloat - dt_anfang) * 1440)) + ''', '''
                + qSuch.FieldByName('Reaktionszeit').AsString + ''', '''
                + qSuch.FieldByName('Erstellungsdatum').AsString + ''', '''
                + qSuch.FieldByName('STOERUNG').AsString + ''', '''
                + qSuch.FieldByName('AutoBuchung').AsString + ''', '''
                + qSuch.FieldByName('RUESTPROT').AsString + ''', '''
                + qSuch.FieldByName('BetriebsAuftragNr').AsString + ''', '''
                + qSuch.FieldByName('AuftragNr').AsString + ''', '''
                + qSuch.FieldByName('Bezeichnung').AsString + ''', '''
                + '-'', '''
                + qSuch.FieldByName('tpm_stillnr').AsString + ''', '''
                + DateTimeToStr(dt_anfang) + ''', '''
                + qSuch.FieldByName('GehtStr').AsString + ''')';
              SQL_Insert(qUpdate, S);

              S := 'UPDATE tpm_stillog_schicht SET geht = ''' + FloatToStr2(dt_anfang) + ''', '
                + ' gehtstr = ''' + DateTimeToStr(dt_anfang) + ''', dauer = '''
                + IntToStr(Round((dt_anfang - qSuch.FieldByName('kommt').AsFloat) * 1440))
                + ''' WHERE nr = ''' + qSuch.FieldByName('nr').AsString + '''';
              SQL_Insert(qUpdate, S);

            end;
            if ((qSuch.FieldByName('geht').AsFloat > dt_ende + 0.00001)
              or (qSuch.FieldByName('geht').AsFloat = 0))
              and (qSuch.FieldByName('kommt').AsFloat < dt_ende + 0.00001) then
              // Update aktuellen geht auf Ende und erzeugen neuen kommt = ende geht = geht(alter)
            begin
              S := 'INSERT INTO tpm_stillog_schicht (Nr,Maschnr, Kommt, Geht, Schicht, '
                + 'StillstandNr, Dauer, Reaktionszeit, Erstellungsdatum, STOERUNG, '
                + 'AutoBuchung, RUESTPROT, BetriebsAuftragNr, '
                + 'AuftragNr, Bezeichnung, Shift_Typ, tpm_stillnr, KommtStr, GehtStr) VALUES ('
                + 'tpm_stillog_schichtid.nextval, '''
                + qSuch.FieldByName('Maschnr').AsString + ''', '''
                + FloatToStr2(dt_ende) + ''', '''
                + qSuch.FieldByName('geht').AsString + ''', '''
                + IntToStr(next_schicht(qSuch.FieldByName('schicht').AsInteger)) + ''', '''
                + qSuch.FieldByName('StillstandNr').AsString + ''', '''
                + IntToStr(Round((qSuch.FieldByName('geht').AsFloat - dt_ende) * 1440)) + ''', '''
                + qSuch.FieldByName('Reaktionszeit').AsString + ''', '''
                + qSuch.FieldByName('Erstellungsdatum').AsString + ''', '''
                + qSuch.FieldByName('STOERUNG').AsString + ''', '''
                + qSuch.FieldByName('AutoBuchung').AsString + ''', '''
                + qSuch.FieldByName('RUESTPROT').AsString + ''', '''
                + qSuch.FieldByName('BetriebsAuftragNr').AsString + ''', '''
                + qSuch.FieldByName('AuftragNr').AsString + ''', '''
                + qSuch.FieldByName('Bezeichnung').AsString + ''', '''
                + '-'', '''
                + qSuch.FieldByName('tpm_stillnr').AsString + ''', '''
                + DateTimeToStr(dt_ende) + ''', '''
                + qSuch.FieldByName('GehtStr').AsString + ''')';
              SQL_Insert(qUpdate, S);

              S := 'UPDATE tpm_stillog_schicht SET geht = ''' + FloatToStr2(dt_ende) + ''', '
                + ' gehtstr = ''' + DateTimeToStr(dt_ende) + ''', dauer = '''
                + IntToStr(Round((dt_ende - qSuch.FieldByName('kommt').AsFloat) * 1440))
                + ''' WHERE nr = ''' + qSuch.FieldByName('nr').AsString + '''';
              SQL_Insert(qUpdate, S);

            end;
          end;
          qSuch.Next;
        end;
      end;
      dt_anfang := dt_ende;
    end;
    S := 'DELETE FROM tpm_stillog_schicht WHERE dauer < 1 AND geht > 0 AND maschnr = ''' + IntToStr(I) + '''';
    SQL_Insert(qUpdate, S);
    S := 'UPDATE tpm_stillog_schicht SET geht = 0 WHERE geht is null AND maschnr = ''' + IntToStr(I) + '''';
    SQL_Insert(qUpdate, S);
    S := 'UPDATE tpm_stillog_schicht SET dauer = 0 WHERE geht = 0 AND maschnr = ''' + IntToStr(I) + '''';
    SQL_Insert(qUpdate, S);
    S := 'DELETE FROM tpm_stillog_schicht WHERE nr NOT IN '
      + ' (SELECT MIN(nr) FROM tpm_stillog_schicht GROUP BY maschnr, kommt, geht)';
    SQL_Insert(qUpdate, S);
  end;

  if Shift_Model = 2 then
  begin // Schicht Typ ermitteln
    S := 'select Nr, MaschNr, Kommt, Schicht from TPM_Stillog_Schicht where Shift_Typ = ''-'' order by Nr';
    SQL_Get(qSuch, S);
    while not qSuch.EOF do
    begin
      S := 'update TPM_Stillog_Schicht set'
        + ' Shift_Typ = ''' + TTT_GetSchichtTyp(qSuch4, qSuch.FieldByName('MaschNr').AsInteger,
        qSuch.FieldByName('Kommt').AsFloat,
        qSuch.FieldByName('Schicht').AsInteger)
        + ''' where Nr = ' + qSuch.FieldByName('Nr').AsString;
      SQL_Insert(qUpdate, S);
      qSuch.Next;
    end;
  end;

  try
    S := 'SELECT ss.nr ssnr, s.stillstandnr stillnr FROM tpm_stillog s, tpm_stillog_schicht ss '
      + 'WHERE s.nr = ss.tpm_stillnr AND s.stillstandnr <> ss.stillstandnr';
    SQL_Get(qSuch, S);
    while not qSuch.EOF do
    begin
      S := 'update TPM_Stillog_Schicht set'
        + ' stillstandnr = ''' + qSuch.FieldByName('stillnr').AsString
        + ''' where Nr = ' + qSuch.FieldByName('ssnr').AsString;
      SQL_Insert(qUpdate, S);
      qSuch.Next;
    end;
  except
  end;
  // Änderung während Umstellung !!! ML 02.09.2005 Anfang
  try
    // NAchsehen ob Stillstände in Stillog_Schicht über die Grenzen Von Stillog hinaus gehen (Stillstandsplit)
    S := 'SELECT ss.nr ssnr, s.geht sgeht, ss.kommt sskommt FROM tpm_stillog s, tpm_stillog_schicht ss '
      + 'WHERE s.nr = ss.tpm_stillnr AND ss.geht > s.geht AND s.geht > 1';
    SQL_Get(qSuch, S);
    while not qSuch.EOF do
    begin
      S := 'update TPM_Stillog_Schicht set'
        + ' geht = ''' + FloatToStr2(qSuch.FieldByName('sgeht').AsFloat) + ''', '
        + ' gehtstr = ''' + DateTimeToStr(qSuch.FieldByName('sgeht').AsFloat) + ''', '
        + ' dauer = ''' + IntToStr(Round((qSuch.FieldByName('sgeht').AsFloat -
        qSuch.FieldByName('sskommt').AsFloat) * 1440)) + ''''
        + ' where Nr = ' + qSuch.FieldByName('ssnr').AsString;
      SQL_Insert(qUpdate, S);
      qSuch.Next;
    end;

    // Noch bereinigen wo geht < kommt
    S := 'DELETE FROM tpm_stillog_schicht WHERE geht < kommt AND geht > 1';
    SQL_Insert(qUpdate, S);

    //Stillstände vergessen? Dann löschen und beim nächsten mal berechnen

    S := 'SELECT MAX(s.nr) snr, SUM(ss.dauer)-MAX(s.dauer) diff FROM '
      + 'tpm_stillog_schicht ss, tpm_stillog s WHERE '
      + 'ss.tpm_stillnr=s.nr group by ss.tpm_stillnr ORDER BY diff ASC';
    SQL_Get(qSuch, S);
    while not qSuch.EOF do
    begin
      if ABS(qSuch.FieldByName('diff').AsInteger) > 5 then
      begin
        S := 'DELETE FROM tpm_stillog_schicht WHERE tpm_stillnr=' + IntToStr(qSuch.FieldByName('snr').AsInteger);
        SQL_Insert(qUpdate, S);
        qSuch.Next;
      end
      else
        break;
    end;
  except
  end;
  // Änderung während Umstellung !!! ML 02.09.2005 Ende
end;
// *****************************************************************************

procedure TThread_Schicht.TPM_Schicht_Schicht3;
var
  S: string;
  D: TDateTime;
begin
  if Shift_Model = 2 then
    Exit;

  S := 'select * from tpm_schicht Where Schicht = 3'
    + ' and DatumZeit - Trunc(DatumZeit) < ''' + FloatToStr2(Schicht3 - 1 / 1440) + ''''
    + ' order by Nr';
  SQL_Get(qSuch, S);
  while not qSuch.EOF do
  begin
    D := qSuch.FieldByName('Datum').AsDateTime + Schicht3;
    S := 'update TPM_Schicht set DatumZeit = ''' + FloatToStr2(D) + ''''
      + ' where Nr = ' + qSuch.FieldByName('Nr').AsString;
    SQL_Insert(qUpdate, S);
    qSuch.Next;
  end;
end;
// *****************************************************************************

procedure TThread_Schicht.TPM_Schicht_Pruefen(Tage: Integer);
var
  N, I, K: Integer;
  S: string;
  D: TDateTime;

  function SQLDateString(dd: TDateTime): string;
  begin
{$IF INCLUDISDatabaseTyp = 0}
    DateTimeToString(Result, 'DD-MM-YY', dd);
    Result := ' to_date(''' + Result + ''',''dd-mm-yy'')';
{$ELSE}
    Result := '''' + DateToStrSQL(dd) + '''';
{$IFEND}

  end;

begin
  if Shift_Model = 2 then
    Exit;

  S := 'select Max(MaschId) CNT from Maschine';
  SQL_Get(qSuch, S);
  N := qSuch.FieldByName('CNT').AsInteger;
  D := Trunc(N_o_w - Tage);

  while D < Trunc(N_o_w) do
  begin
    for I := 1 to 3 do
      for K := 1 to N do
      begin
        S := 'Select Count(*) as CNT from TPM_SCHICHT'
          + ' where Datum = ' + SQLDateString(D) + ' and Schicht = ' + IntToStr(I) + ' and MaschNr = ' + IntToStr(K);
        SQL_Get(qSuch, S);
        if qSuch.FieldByName('CNT').AsInteger = 0 then
        begin
          S := 'Insert into tpm_schicht (nr, maschnr, Datum, schicht, SHIFT_TYP, datumzeit, KW, Monat,'
            + ' nutzung, leistung, qualitaet, effektivitaet,'
            + ' Personalzeit, produziert, geprueft, verpackt, stops,'
            + ' anlagenausfall, ruesten, logistik,'
            + ' nichtgebucht, geplant, ungeplant, solLlaufzeit, istlaufzeit, solltakt,isttakt,'
            + ' Ausschuss, Kavitaet, Anfahrausschuss, AUTOAUSSCHUSS, Manuell_Erzeugt)'
            + ' values (tpm_schichtID.Nextval'
            + ',''' + IntToStr(K)
            + ''',' + SQLDateString(D)
            + ',''' + IntToStr(I)
            + ''',''-'
            + ''',' + FloatToPunktString(TTT_GetTPMSchichtZeit(I, D))
            + ',''' + GetKWStr(D)
            + ''',''' + TTT_GetMonatStr(D)
            + ''',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,1)';
          SQL_Insert(qUpdate, S);
        end;
      end;
    D := D + 1;
  end;
end;
// *****************************************************************************

procedure TThread_Schicht.Berechne_A_Daten(Von, Bis: Real; MNrs: string);
var
  S: string;
  D: Real;
  SchiNr: Integer;
begin
  if Shift_Model = 2 then
  begin
    S := 'update TPM_Schicht set A_Solllaufzeit ='
      + ' (select A_Solllaufzeit from TPM_Auswertung'
      + ' where TPM_Schicht.Datum = TPM_Auswertung.Datum and'
      + ' TPM_Schicht.Schicht = TPM_Auswertung.Schicht and'
      + ' TPM_Schicht.MaschNr = TPM_Auswertung.MaschNr and'
      + ' TPM_Schicht.BetriebsAuftragNr = TPM_Auswertung.AuftragNr)'
      + ' where DatumZeit between (''' + FloatToStr2(Von) + ''') and (''' + FloatToStr2(Bis) + ''')'
      + GetSelectedMaschinen(qUpdate, 'and', 'MaschNr', MNrs, 0);
    SQL_Insert(qUpdate, S);

    S := 'update TPM_Schicht set A_Istlaufzeit ='
      + ' (select A_Istlaufzeit from TPM_Auswertung'
      + ' where TPM_Schicht.Datum = TPM_Auswertung.Datum and'
      + ' TPM_Schicht.Schicht = TPM_Auswertung.Schicht and'
      + ' TPM_Schicht.MaschNr = TPM_Auswertung.MaschNr and'
      + ' TPM_Schicht.BetriebsAuftragNr = TPM_Auswertung.AuftragNr)'
      + ' where DatumZeit between (''' + FloatToStr2(Von) + ''') and (''' + FloatToStr2(Bis) + ''')'
      + GetSelectedMaschinen(qUpdate, 'and', 'MaschNr', MNrs, 0);
    SQL_Insert(qUpdate, S);

    S := 'update TPM_Schicht set A_Geplant ='
      + ' (select A_Geplant from TPM_Auswertung'
      + ' where TPM_Schicht.Datum = TPM_Auswertung.Datum and'
      + ' TPM_Schicht.Schicht = TPM_Auswertung.Schicht and'
      + ' TPM_Schicht.MaschNr = TPM_Auswertung.MaschNr and'
      + ' TPM_Schicht.BetriebsAuftragNr = TPM_Auswertung.AuftragNr)'
      + ' where DatumZeit between (''' + FloatToStr2(Von) + ''') and (''' + FloatToStr2(Bis) + ''')'
      + GetSelectedMaschinen(qUpdate, 'and', 'MaschNr', MNrs, 0);
    SQL_Insert(qUpdate, S);

    S := 'update TPM_Schicht set A_Ungeplant ='
      + ' (select A_Ungeplant from TPM_Auswertung'
      + ' where TPM_Schicht.Datum = TPM_Auswertung.Datum and'
      + ' TPM_Schicht.Schicht = TPM_Auswertung.Schicht and'
      + ' TPM_Schicht.MaschNr = TPM_Auswertung.MaschNr and'
      + ' TPM_Schicht.BetriebsAuftragNr = TPM_Auswertung.AuftragNr)'
      + ' where DatumZeit between (''' + FloatToStr2(Von) + ''') and (''' + FloatToStr2(Bis) + ''')'
      + GetSelectedMaschinen(qUpdate, 'and', 'MaschNr', MNrs, 0);
    SQL_Insert(qUpdate, S);

    S := 'update TPM_Schicht set A_Anlagenausfall ='
      + ' (select A_Anlagenausfall from TPM_Auswertung'
      + ' where TPM_Schicht.Datum = TPM_Auswertung.Datum and'
      + ' TPM_Schicht.Schicht = TPM_Auswertung.Schicht and'
      + ' TPM_Schicht.MaschNr = TPM_Auswertung.MaschNr and'
      + ' TPM_Schicht.BetriebsAuftragNr = TPM_Auswertung.AuftragNr)'
      + ' where DatumZeit between (''' + FloatToStr2(Von) + ''') and (''' + FloatToStr2(Bis) + ''')'
      + GetSelectedMaschinen(qUpdate, 'and', 'MaschNr', MNrs, 0);
    SQL_Insert(qUpdate, S);

    S := 'update TPM_Schicht set A_Ruesten ='
      + ' (select A_Ruesten from TPM_Auswertung'
      + ' where TPM_Schicht.Datum = TPM_Auswertung.Datum and'
      + ' TPM_Schicht.Schicht = TPM_Auswertung.Schicht and'
      + ' TPM_Schicht.MaschNr = TPM_Auswertung.MaschNr and'
      + ' TPM_Schicht.BetriebsAuftragNr = TPM_Auswertung.AuftragNr)'
      + ' where DatumZeit between (''' + FloatToStr2(Von) + ''') and (''' + FloatToStr2(Bis) + ''')'
      + GetSelectedMaschinen(qUpdate, 'and', 'MaschNr', MNrs, 0);
    SQL_Insert(qUpdate, S);

    S := 'update TPM_Schicht set A_Logistik ='
      + ' (select A_Logistik from TPM_Auswertung'
      + ' where TPM_Schicht.Datum = TPM_Auswertung.Datum and'
      + ' TPM_Schicht.Schicht = TPM_Auswertung.Schicht and'
      + ' TPM_Schicht.MaschNr = TPM_Auswertung.MaschNr and'
      + ' TPM_Schicht.BetriebsAuftragNr = TPM_Auswertung.AuftragNr)'
      + ' where DatumZeit between (''' + FloatToStr2(Von) + ''') and (''' + FloatToStr2(Bis) + ''')'
      + GetSelectedMaschinen(qUpdate, 'and', 'MaschNr', MNrs, 0);
    SQL_Insert(qUpdate, S);

    S := 'update TPM_Schicht set A_Nichtgebucht ='
      + ' (select A_Nichtgebucht from TPM_Auswertung'
      + ' where TPM_Schicht.Datum = TPM_Auswertung.Datum and'
      + ' TPM_Schicht.Schicht = TPM_Auswertung.Schicht and'
      + ' TPM_Schicht.MaschNr = TPM_Auswertung.MaschNr and'
      + ' TPM_Schicht.BetriebsAuftragNr = TPM_Auswertung.AuftragNr)'
      + ' where DatumZeit between (''' + FloatToStr2(Von) + ''') and (''' + FloatToStr2(Bis) + ''')'
      + GetSelectedMaschinen(qUpdate, 'and', 'MaschNr', MNrs, 0);
    SQL_Insert(qUpdate, S);
  end
  else
  begin
    D := Von;
    SchiNr := GetSchichtNr(Von);
    while Trunc(D) + GetSchichtStartFloat(SchiNr) <= Bis do
    begin
      CCC_A_Felder_Schicht_Berechnen(qSuch, qSuch2, qUpdate, D, SchiNr);

      Inc(SchiNr);
      if SchiNr > 3 then
      begin
        SchiNr := 1;
        D := D + 1;
      end;
    end;
  end;
end;
// *****************************************************************************

procedure TThread_Schicht.TPM_Stillog_Korrektur(Arc_Tag, Kor_Tag: Integer);
var
  S, Nr: string;
  stage, turn, Cnt, MaschNr, MaschNr2: Integer;
  X, Kommt, Kommt2, Geht: Real;
begin
  // Archivierung in TPM_STILLOG_Arc
  stage:=0;
  turn :=0;
  try
    if Arc_Tag < 20 then
      SchreibeMeldung('Warning: Arc_Tag < 20', LogFile_Mode);

{$IF INCLUDISDatabaseTyp = 0}
    S := 'select Max(Kommt) MaxNr, Min(Kommt) MinNr, Count(*) CNT from TPM_Stillog'
      + ' where Geht > 0 and Kommt < ' + IntToStr(Trunc(N_o_w) - Arc_Tag);
    SQL_Get(qSuch, S);
    stage := 1;
    while qSuch.FieldByName('CNT').AsInteger > 0 do
    begin
      Cnt := qSuch.FieldByName('CNT').AsInteger;
      Kommt := qSuch.FieldByName('MinNr').AsFloat;
      Geht := qSuch.FieldByName('MaxNr').AsFloat;

      X := (Geht - Kommt) * 2000 / Cnt + Kommt;
      if X > Geht then
        X := Geht;
      try

        S := 'insert into TPM_Stillog_Arc '
          + '(AUFTRAGNR, AUTOBUCHUNG, BETRIEBSAUFTRAGNR, BEZEICHNUNG, BLOCK, DAUER, ERPSTATE, ERSTELLUNGSDATUM, GEHT, GEHTSTR, HOSTNAME,'
          + ' KOMMT, KOMMTSTR, LASTCHANGE, MASCHNR, MESSENGERSTATE, NOTIZ, NOTIZID, NR, PERSNO, PERSONAL, PERSONALNR, PRODZAEHLER, QUELLE,'
          + ' REAKTIONSZEIT, RUESTPROT, SCHICHT, SCHUSSZAEHLER, SHIFT_TYP, STILLSTANDNR, STOERUNG, USERID, WERKZEUGNR)'
          + ' select AUFTRAGNR, AUTOBUCHUNG, BETRIEBSAUFTRAGNR, BEZEICHNUNG, BLOCK, DAUER, ERPSTATE, ERSTELLUNGSDATUM, GEHT, GEHTSTR,'
          + ' HOSTNAME, KOMMT, KOMMTSTR, LASTCHANGE, MASCHNR, MESSENGERSTATE, NOTIZ, NOTIZID, NR, PERSNO, PERSONAL, PERSONALNR,'
          + ' PRODZAEHLER, QUELLE, REAKTIONSZEIT, RUESTPROT, SCHICHT, SCHUSSZAEHLER, SHIFT_TYP, STILLSTANDNR, STOERUNG, USERID, WERKZEUGNR '
          + ' from TPM_Stillog where Geht > 0 and Kommt <= ' + FloatToPunktString(X); // '' + FloatToStr2(X) + '''';
        SQL_Insert(qUpdate, S);
        S := 'delete from TPM_Stillog where Geht > 0 and Kommt <= ' + FloatToPunktString(X); // '' + FloatToStr2(X) + '''';
        SQL_Insert(qUpdate, S);
      except on e: Exception do
        begin
          SchreibeMeldung('EXCEPTION tpm_stillog_arc: ' + e.Message, LogFile_Mode);
          S := 'delete from tpm_stillog where nr <= (select max(nr) from tpm_stillog_arc)';
          SQL_Insert(qUpdate, S);
        end
      end;

      qSuch.Close;
      qSuch.Open;
    end;
    qSuch.Close;

{$IFEND}
    stage := 2;

  // Check Überlappungen in TPM_Stillog
    S := 'select TPM_Stillog.*, maschine.manuelle_buchung from TPM_Stillog, Maschine'
      + ' where (Kommt > ''' + IntToStr(Trunc(N_o_w) - Kor_Tag) + ''''
      + ' or Decode(Geht, 0, ''99999'', Geht) > ''' + IntToStr(Trunc(N_o_w) - Kor_Tag) + ''')'
      + ' and maschine.maschnr = tpm_stillog.maschnr and maschine.manuelle_buchung <> 1 '
      + ' order by tpm_stillog.MaschNr, tpm_stillog.Kommt';

    SQL_Get(qSuch, S);
    stage := 3;

    MaschNr := qSuch.FieldByName('MASCHNR').AsInteger;
    Kommt := qSuch.FieldByName('KOMMT').AsFloat;
    Geht := qSuch.FieldByName('GEHT').AsFloat;
    Nr := qSuch.FieldByName('Nr').AsString;
    if Geht = 0 then
      Geht := N_o_w;
    stage := 4;
    qSuch.Next;
    stage := 5;
    while not qSuch.EOF do
    begin
      turn := turn +1;
      MaschNr2 := qSuch.FieldByName('MASCHNR').AsInteger;
      Kommt2 := qSuch.FieldByName('KOMMT').AsFloat;
      if (MaschNr = MaschNr2) and (Kommt2 >= Kommt) and (Kommt2 < Geht) then
      begin
        S := 'update TPM_STILLOG set Geht = ' + FloatToPunktString(Kommt2) + ','
          + ' Dauer = null, GehtStr = Null where NR = ' + Nr;
        SQL_Insert(qUpdate, S);
      end;
      MaschNr := MaschNr2;
      Kommt := Kommt2;
      Geht := qSuch.FieldByName('GEHT').AsFloat;
      Nr := qSuch.FieldByName('Nr').AsString;
      if Geht = 0 then
        Geht := N_o_w;
      qSuch.Next;
    end;
    stage :=6;
    S := 'delete from TPM_STILLOG where Kommt = Geht';
    SQL_Insert(qUpdate, S);
    stage := 7;
  // Wenn Stilllog_schicht, dann auch arc_tage löschen
    if Stillstaende_Schicht > 0 then
    begin
    // Nach erstem Stillstand suchen, dann tagesweise löschen
      S := 'SELECT MIN(nr) minnr FROM tpm_stillog_schicht';
      qSuch.SQL.Text := S;
      qSuch.Open;
      turn :=0;
      if not qSuch.IsEmpty then
      begin
        qSuch.SQL.Text := 'SELECT * FROM tpm_stillog_schicht WHERE nr = ' + qSuch.FieldByName('minnr').AsString;
        qSuch.Open;
        stage := 8;
        Kommt := qSuch.FieldByName('kommt').AsFloat;
        qSuch.Close;
        stage :=9;
        while Kommt < N_o_w - Arc_Tag do
        begin
          turn := turn +1;
          qUpdate.SQL.Text := 'DELETE FROM tpm_stillog_schicht WHERE kommt < ' + FloatToPunktString(Kommt);
          qUpdate.ExecSQL;
          Kommt := Kommt + 1;
        end;
      end;
    end;
  except on e: Exception do
    SchreibeMeldung('EXCEPTION tpm_stillog_korrektur (stage: ' +IntToStr(stage)+ ' - turn:' + IntToStr(turn) + '/ arc:' + IntToStr(Arc_Tag) + ' - kor:' + IntToStr(Kor_Tag) + '): ' + e.Message, LogFile_Mode);
  end;
end;
// *****************************************************************************

procedure TThread_Schicht.Berechne_TPM_Produktionsdetail(Days: Integer; MNrs: string);
var
  Nr, S, S1, F: string;
  Verp, I, MaschNr: Integer;
  DT, DTE, AStart, AEnde, TimeNoJob: Double;
begin
  S := 'delete from TPM_Produktionsdetail where DatumZeit > ' + FloatToPunktString(Date - Days) + ' '
    + GetSelectedMaschinen(qUpdate, 'and', 'Maschine', MNrs, 1);
  SQL_Insert(qUpdate, S);

  S := 'select Count(*) CNT, Datum, Schicht, Min(DatumZeit) DatumZeit,'
    + ' Min(KW) KW, Min(Monat) Monat, Min(Quartal) Quartal, Min(Jahr) Jahr,'
    + ' Maschine, Max(MaschNr) MaschNr, Min(Cal_Group) KAL_GRUPPE,'
    + ' ' + IntToStr(MaxSchichtTime) + ' Gesamt_Kap,'
    + ' Max(Solllaufzeit) Werkspl_Kap,'
    + ' Max(Nettolaufzeit) M_Nutz,'
    + ' Decode(Sum(TaktZeit_Mittel_Ist), 0, 0, Round(Sum(TaktZeit_Soll)/Sum(TaktZeit_Mittel_Ist) * 100, 2)) Leistung,'
    + ' Sum(Produzierte_Menge) Produziert,'
    + ' Sum(Produziert_Soll) Produziert_Soll,'
    + ' Sum(Packed) Verpackt,'
    + ' Sum(Gutteile) Gutteile,'
    + ' Sum(zyklen) zyklen,'
    + ' Sum(Ausschuss) Ausschuss'
    + ' from TPM_Auswertung'
    + ' where DatumZeit > ' + FloatToPunktString(Date - Days) + ' '
    + GetSelectedMaschinen(qUpdate, 'and', 'MaschNr', MNrs, 0)
    + ' group by Maschine, Datum, Schicht'
    + ' order by DatumZeit, Maschine';
  SQL_Get(qSuch, S);

  while not qSuch.EOF do
  begin
    S := 'select TPM_ProduktionsdetailId.NextVal as CNT from Setup';
    SQL_Get(qSuch2, S);
    Nr := qSuch2.FieldByName('CNT').AsString;

    S := 'Insert into TPM_Produktionsdetail(Nr, Cnt, Datum, Schicht,'
      + ' KW, Monat, Quartal, Jahr, DatumZeit,'
      + ' Maschine, KAL_GRUPPE, GESAMT_KAP, WERKSPL_KAP,'
      + ' M_NUTZ, Leistung_Prz, Produziert, Produziert_Soll, Verpackt, Gutteile, zyklen, Ausschuss)'
      + ' values (' + Nr + ','
      + ' ''' + qSuch.FieldByName('CNT').AsString + ''','
      + ' ''' + qSuch.FieldByName('Datum').AsString + ''','
      + ' ''' + qSuch.FieldByName('Schicht').AsString + ''','
      + ' ''' + qSuch.FieldByName('KW').AsString + ''','
      + ' ''' + qSuch.FieldByName('Monat').AsString + ''','
      + ' ''' + qSuch.FieldByName('Quartal').AsString + ''','
      + ' ''' + qSuch.FieldByName('Jahr').AsString + ''','
      + ' ' + FloatToPunktString(qSuch.FieldByName('DatumZeit').AsFloat) + ','
      + ' ''' + qSuch.FieldByName('Maschine').AsString + ''','
      + ' ''' + qSuch.FieldByName('KAL_GRUPPE').AsString + ''','
      + ' ''' + IntToStr(GetSchichtDauer(qSuch.FieldByName('Schicht').AsInteger)) + ''','
      + ' ''' + qSuch.FieldByName('Werkspl_Kap').AsString + ''','
      + ' ''' + qSuch.FieldByName('M_Nutz').AsString + ''','
      + ' ''' + qSuch.FieldByName('Leistung').AsString + ''','
      + ' ''' + qSuch.FieldByName('Produziert').AsString + ''','
      + ' ''' + qSuch.FieldByName('Produziert_Soll').AsString + ''','
      + ' ''' + qSuch.FieldByName('Verpackt').AsString + ''','
      + ' ''' + qSuch.FieldByName('Gutteile').AsString + ''','
      + ' ''' + qSuch.FieldByName('Zyklen').AsString + ''','
      + ' ''' + qSuch.FieldByName('Ausschuss').AsString + ''')';
    SQL_Insert(qUpdate, S);

    DT := qSuch.FieldByName('DatumZeit').AsFloat;
    DTE := DT + GetSchichtDauerDatum(qSuch.FieldByName('KAL_GRUPPE').AsInteger, DT + 10 / 1440) / 1440;
    MaschNr := qSuch.FieldByName('MaschNr').AsInteger;

    S := 'select Sum(Zugang-Abgang) as CNT from VerpacktProt'
      + ' where datum >= ' + FloatToPunktString(DT) + ' and datum < ' + FloatToPunktString(DTE) + ''
      + ' and Maschine = ''' + qSuch.FieldByName('Maschine').AsString + '''';
    SQL_Get(qSuch2, S);

    try
      Verp := qSuch2.FieldByName('CNT').AsInteger;
    except
      Verp := 0;
    end;

    S := '(select RuestStart AStart, Decode(AuftragEnde, 0, 99999.0, AuftragEnde) AEnde'
      + ' from Laufzeitlog where MaschNr = ' + IntToStr(MaschNr)
      + ' and RuestStart < ' + FloatToPunktString(DTE) + ' and Decode(AuftragEnde, 0, 99999.0, AuftragEnde) > ' + FloatToPunktString(DT)
      + ' union'
      + ' select Kommt AStart, Decode(Geht, 0, 99999.0, Geht) AEnde from TPM_Stillog where MaschNr = ' + IntToStr(MaschNr)
      + ' and Kommt < ' + FloatToPunktString(DTE) + ' and Decode(Geht, 0, 99999.0, Geht) > ' + FloatToPunktString(DT)
      + ' union'
      + ' select 0 AStart, ' + FloatToPunktString(DT) + ' AEnde from dual'
      + ' union'
      + ' select ' + FloatToPunktString(DTE) + ' AStart, 0 AEnde from dual)'
      + ' order by AStart';
    SQL_Get(qSuch2, S);

    TimeNoJob := 0;
    AStart := qSuch2.FieldByName('AEnde').AsFloat;
    qSuch2.Next;
    while not qSuch2.EOF do
    begin
      AEnde := qSuch2.FieldByName('AStart').AsFloat;

      if AEnde > AStart then
        TimeNoJob := TimeNoJob + AEnde - AStart;

      if AStart < qSuch2.FieldByName('AEnde').AsFloat then
        AStart := qSuch2.FieldByName('AEnde').AsFloat;

      qSuch2.Next;
    end;

    S := 'update TPM_Produktionsdetail set Verpackt = ' + IntToStr(Verp) + ','
      + ' LZ_No_Job = ' + IntToStr(Round(TimeNoJob * 1440)) + ' where Nr = ' + Nr;
    SQL_Insert(qUpdate, S);

    qSuch.Next;
  end;

  S := 'update TPM_Produktionsdetail set M_NUTZ = ' + IntToStr(MaxSchichtTime)
    + ' where M_NUTZ > ' + IntToStr(MaxSchichtTime) + ''
    + ' and DatumZeit > ' + FloatToPunktString(Date - Days);
  SQL_Insert(qUpdate, S);

  // Anlagenausfall, Ruesten, Logistik, NICHT_GEBUCHT
(*
  for I := 0 to 3 do
  begin
    S := 'select * from TPM_Stillstaende where Gruppe = ' + IntToStr(I);
    SQL_Get(qSuch, S);
    S1 := '';
    while not qSuch.EOF do
    begin
      S1 := S1 + '+Max(STILL_' + qSuch.FieldByName('StillStandNr').AsString + ')';
      qSuch.Next;
    end;
    if Length(S1) > 0 then
      System.Delete(S1, 1, 1)
    else
      S1 := '0';
    S := 'update TPM_Produktionsdetail set ';
    case I of
      0: F := 'Anlagenausfall';
      1: F := 'Ruesten';
      2: F := 'Logistik';
      3: F := 'NICHT_GEBUCHT';
    end;
    S := S + F;

    S := S + ' = (select ' + S1 + ' from TPM_Auswertung'
      + ' where'
      + ' TPM_Produktionsdetail.Maschine = TPM_Auswertung.Maschine'
      + ' and TPM_Produktionsdetail.Datum = TPM_Auswertung.Datum'
      + ' and TPM_Produktionsdetail.Schicht = TPM_Auswertung.Schicht'
      + ' group by Maschine, Datum, Schicht)'
      + ' where ' + F + ' is null';

    SQL_Insert(qUpdate, S);
  end;
  *)
  // Geplant & ungeplant
  (*
  for I := 0 to 1 do
  begin
    S := 'select * from TPM_Stillstaende where Geplant = ' + IntToStr(I);
    SQL_Get(qSuch, S);
    S1 := '';
    while not qSuch.EOF do
    begin
      S1 := S1 + '+Max(STILL_' + qSuch.FieldByName('StillStandNr').AsString + ')';
      qSuch.Next;
    end;
    if Length(S1) > 0 then
      System.Delete(S1, 1, 1)
    else
      S1 := '0';
    S := 'update TPM_Produktionsdetail set ';
    case I of
      0: F := 'UNGEPL_STILL';
      1: F := 'GEPL_STILL';
    end;
    S := S + F;

    S := S + ' = (select ' + S1 + ' from TPM_Auswertung'
      + ' where'
      + ' TPM_Produktionsdetail.Maschine = TPM_Auswertung.Maschine'
      + ' and TPM_Produktionsdetail.Datum = TPM_Auswertung.Datum'
      + ' and TPM_Produktionsdetail.Schicht = TPM_Auswertung.Schicht'
      + ' group by Maschine, Datum, Schicht)'
      + ' where ' + F + ' is null';

    SQL_Insert(qUpdate, S);
  end;

  // Rüster geplant & Rüsten ungeplant
  for I := 0 to 1 do
  begin
    S := 'select * from TPM_Stillstaende where Gruppe = 1 and Geplant = ' + IntToStr(I);
    SQL_Get(qSuch, S);
    S1 := '';
    while not qSuch.EOF do
    begin
      S1 := S1 + '+Max(STILL_' + qSuch.FieldByName('StillStandNr').AsString + ')';
      qSuch.Next;
    end;
    if Length(S1) > 0 then
      System.Delete(S1, 1, 1)
    else
      S1 := '0';
    S := 'update TPM_Produktionsdetail set ';
    case I of
      0: F := 'RUESTEN_UNGEPL';
      1: F := 'RUESTEN_GEPL';
    end;
    S := S + F;

    S := S + ' = (select ' + S1 + ' from TPM_Auswertung'
      + ' where'
      + ' TPM_Produktionsdetail.Maschine = TPM_Auswertung.Maschine'
      + ' and TPM_Produktionsdetail.Datum = TPM_Auswertung.Datum'
      + ' and TPM_Produktionsdetail.Schicht = TPM_Auswertung.Schicht'
      + ' group by Maschine, Datum, Schicht)'
      + ' where ' + F + ' is null';
    SQL_Insert(qUpdate, S);
  end;
      *)
  S := 'update TPM_Produktionsdetail set EFF_KAP = Gesamt_Kap - Gepl_Still'
    + ' where EFF_KAP is null';
  SQL_Insert(qUpdate, S);

  S := 'update TPM_Produktionsdetail set EFF_KAP = 0 where EFF_KAP < 0';
  SQL_Insert(qUpdate, S);

  S := 'update TPM_Produktionsdetail set Ges_Still = Gepl_Still + Ungepl_Still'
    + ' where Ges_Still is null';
  SQL_Insert(qUpdate, S);

  S := 'update TPM_Produktionsdetail set'
    + ' EFF_KAP_PRZ = Round(Eff_Kap / Decode(WERKSPL_KAP, 0, -1, WERKSPL_KAP)*100, 2)'
    + ' where EFF_KAP_PRZ is null';
  SQL_Insert(qUpdate, S);

  S := 'update TPM_Produktionsdetail set EFF_KAP_PRZ = 0 where EFF_KAP_PRZ < 0';
  SQL_Insert(qUpdate, S);

  S := 'update TPM_Produktionsdetail set'
    + ' VERPACK_PRZ = Round(Verpackt / Decode(Produziert, 0, -1, Produziert)*100, 2)'
    + ' where VERPACK_PRZ is null';
  try
    SQL_Insert(qUpdate, S);
  except
    SchreibeMeldung('730E89BB-29EC-43D9-B4B7-45787B6D68E5', LogFile_Mode);
    S := 'update TPM_Produktionsdetail set'
      + ' VERPACK_PRZ = Round(Verpackt / Decode(Produziert, 0, -1, Produziert)*100, 2)'
      + ' where VERPACK_PRZ is null'
      + ' AND VERPACKT < 10 * produziert AND VERPACKT > -10 * produziert';
    try
      SQL_Insert(qUpdate, S);
    except
      SchreibeMeldung('730E89BB-29EC-43D9-B4B7-45787B6D68E6', LogFile_Mode);
    end;

  end;

  S := 'update TPM_Produktionsdetail set VERPACK_PRZ = 0 where VERPACK_PRZ < 0';
  SQL_Insert(qUpdate, S);

  S := 'update TPM_Produktionsdetail set'
    + ' M_NUTZ_PRZ = Round(M_NUTZ / Decode(Gesamt_Kap, 0, -1, Gesamt_Kap)*100, 2)'
    + ' where M_NUTZ_PRZ is null';
  SQL_Insert(qUpdate, S);

  S := 'update TPM_Produktionsdetail set M_NUTZ_PRZ = 0 where M_NUTZ_PRZ < 0';
  SQL_Insert(qUpdate, S);

  S := 'update TPM_Produktionsdetail set'
    + ' EFF_NUTZ_PRZ = Round(M_NUTZ / Decode(Eff_Kap, 0, -1, Eff_Kap)*100, 2)'
    + ' where EFF_NUTZ_PRZ is null';
  SQL_Insert(qUpdate, S);

  S := 'update TPM_Produktionsdetail set EFF_NUTZ_PRZ = 0 where EFF_NUTZ_PRZ < 0';
  SQL_Insert(qUpdate, S);

  S := 'update TPM_Produktionsdetail set'
    + ' NICHT_GEBUCHT_PRZ = Round(NICHT_GEBUCHT / Decode(Ges_Still, 0, -1, Ges_Still)*100, 2)'
    + ' where NICHT_GEBUCHT_PRZ is null';
  SQL_Insert(qUpdate, S);

  S := 'update TPM_Produktionsdetail set NICHT_GEBUCHT_PRZ = 0 where NICHT_GEBUCHT_PRZ < 0';
  SQL_Insert(qUpdate, S);

  S := 'update TPM_Produktionsdetail set'
    + ' ANLAGENAUSFALL_PRZ = Round(ANLAGENAUSFALL / Decode(Ges_Still, 0, -1, Ges_Still)*100, 2)'
    + ' where ANLAGENAUSFALL_PRZ is null';
  SQL_Insert(qUpdate, S);

  S := 'update TPM_Produktionsdetail set ANLAGENAUSFALL_PRZ = 0 where ANLAGENAUSFALL_PRZ < 0';
  SQL_Insert(qUpdate, S);

  S := 'update TPM_Produktionsdetail set'
    + ' RUESTEN_PRZ = Round(RUESTEN / Decode(Ges_Still, 0, -1, Ges_Still)*100, 2)'
    + ' where RUESTEN_PRZ is null';
  SQL_Insert(qUpdate, S);

  S := 'update TPM_Produktionsdetail set RUESTEN_PRZ = 0 where RUESTEN_PRZ < 0';
  SQL_Insert(qUpdate, S);

  S := 'update TPM_Produktionsdetail set'
    + ' LOGISTIK_PRZ = Round(LOGISTIK / Decode(Ges_Still, 0, -1, Ges_Still)*100, 2)'
    + ' where LOGISTIK_PRZ is null';
  SQL_Insert(qUpdate, S);

  S := 'update TPM_Produktionsdetail set LOGISTIK_PRZ = 0 where LOGISTIK_PRZ < 0';
  SQL_Insert(qUpdate, S);

  S := 'update TPM_Produktionsdetail set M_OEE_PRZ = Round(M_Nutz_PRZ*Leistung_Prz/100, 2)'
    + ' where M_OEE_PRZ is null';
  SQL_Insert(qUpdate, S);

  S := 'update TPM_Produktionsdetail set EFF_OEE_PRZ = Round(Eff_Nutz_PRZ*Leistung_Prz/100, 2)'
    + ' where EFF_OEE_PRZ is null';
  SQL_Insert(qUpdate, S);

  S := 'update TPM_Produktionsdetail set M_Nutz = Eff_Kap where M_Nutz > Eff_Kap';
  SQL_Insert(qUpdate, S);

  S := 'update TPM_Auswertung set Produziert_Soll = 0 where Produziert_Soll < 0';
  SQL_Insert(qUpdate, S);
end;
// *****************************************************************************

procedure TThread_Schicht.Berechne_TPM_ProduktionsdetailDebug(Start : Extended; Days: Integer; MNrs: string);
var
  Nr, S, S1, F: string;
  Verp, I, MaschNr: Integer;
  DT, DTE, AStart, AEnde, TimeNoJob: Double;
  StartDate : Extended;
begin
  StartDate  := Start;
  S := 'delete from TPM_Produktionsdetail where DatumZeit > ' + FloatToPunktString(StartDate)
    + ' and datumzeit < ' + FloatToPunktString(StartDate + Days)
    + GetSelectedMaschinen(qUpdate, 'and', 'Maschine', MNrs, 1);
  SQL_Insert(qUpdate, S);

  S := 'select Count(*) CNT, Datum, Schicht, Min(DatumZeit) DatumZeit,'
    + ' Min(KW) KW, Min(Monat) Monat, Min(Quartal) Quartal, Min(Jahr) Jahr,'
    + ' Maschine, Max(MaschNr) MaschNr, Min(Cal_Group) KAL_GRUPPE,'
    + ' ' + IntToStr(MaxSchichtTime) + ' Gesamt_Kap,'
    + ' Max(Solllaufzeit) Werkspl_Kap,'
    + ' Max(Nettolaufzeit) M_Nutz,'
    + ' Decode(Sum(TaktZeit_Mittel_Ist), 0, 0, Round(Sum(TaktZeit_Soll)/Sum(TaktZeit_Mittel_Ist) * 100, 2)) Leistung,'
    + ' Sum(Produzierte_Menge) Produziert,'
    + ' Sum(Produziert_Soll) Produziert_Soll,'
    + ' Sum(Packed) Verpackt,'
    + ' Sum(Gutteile) Gutteile,'
    + ' Sum(zyklen) zyklen,'
    + ' Sum(Ausschuss) Ausschuss'
    + ' from TPM_Auswertung'
    + ' where DatumZeit > ' + FloatToPunktString(StartDate)
    + ' and datumzeit < ' + FloatToPunktString(StartDate + Days)
    + GetSelectedMaschinen(qUpdate, 'and', 'MaschNr', MNrs, 0)
    + ' group by Maschine, Datum, Schicht'
    + ' order by DatumZeit, Maschine';
  SQL_Get(qSuch, S);

  while not qSuch.EOF do
  begin
    S := 'select TPM_ProduktionsdetailId.NextVal as CNT from Setup';
    SQL_Get(qSuch2, S);
    Nr := qSuch2.FieldByName('CNT').AsString;

    S := 'Insert into TPM_Produktionsdetail(Nr, Cnt, Datum, Schicht,'
      + ' KW, Monat, Quartal, Jahr, DatumZeit,'
      + ' Maschine, KAL_GRUPPE, GESAMT_KAP, WERKSPL_KAP,'
      + ' M_NUTZ, Leistung_Prz, Produziert, Produziert_Soll, Verpackt, Gutteile, zyklen, Ausschuss)'
      + ' values (' + Nr + ','
      + ' ''' + qSuch.FieldByName('CNT').AsString + ''','
      + ' ''' + qSuch.FieldByName('Datum').AsString + ''','
      + ' ''' + qSuch.FieldByName('Schicht').AsString + ''','
      + ' ''' + qSuch.FieldByName('KW').AsString + ''','
      + ' ''' + qSuch.FieldByName('Monat').AsString + ''','
      + ' ''' + qSuch.FieldByName('Quartal').AsString + ''','
      + ' ''' + qSuch.FieldByName('Jahr').AsString + ''','
      + ' ' + FloatToPunktString(qSuch.FieldByName('DatumZeit').AsFloat) + ','
      + ' ''' + qSuch.FieldByName('Maschine').AsString + ''','
      + ' ''' + qSuch.FieldByName('KAL_GRUPPE').AsString + ''','
      + ' ''' + IntToStr(GetSchichtDauer(qSuch.FieldByName('Schicht').AsInteger)) + ''','
      + ' ''' + qSuch.FieldByName('Werkspl_Kap').AsString + ''','
      + ' ''' + qSuch.FieldByName('M_Nutz').AsString + ''','
      + ' ''' + qSuch.FieldByName('Leistung').AsString + ''','
      + ' ''' + qSuch.FieldByName('Produziert').AsString + ''','
      + ' ''' + qSuch.FieldByName('Produziert_Soll').AsString + ''','
      + ' ''' + qSuch.FieldByName('Verpackt').AsString + ''','
      + ' ''' + qSuch.FieldByName('Gutteile').AsString + ''','
      + ' ''' + qSuch.FieldByName('Zyklen').AsString + ''','
      + ' ''' + qSuch.FieldByName('Ausschuss').AsString + ''')';
    SQL_Insert(qUpdate, S);

    DT := qSuch.FieldByName('DatumZeit').AsFloat;
    DTE := DT + GetSchichtDauerDatum(qSuch.FieldByName('KAL_GRUPPE').AsInteger, DT + 10 / 1440) / 1440;
    MaschNr := qSuch.FieldByName('MaschNr').AsInteger;

    S := 'select Sum(Zugang-Abgang) as CNT from VerpacktProt'
      + ' where datum >= ' + FloatToPunktString(DT) + ' and datum < ' + FloatToPunktString(DTE) + ''
      + ' and Maschine = ''' + qSuch.FieldByName('Maschine').AsString + '''';
    SQL_Get(qSuch2, S);

    try
      Verp := qSuch2.FieldByName('CNT').AsInteger;
    except
      Verp := 0;
    end;

    S := '(select RuestStart AStart, Decode(AuftragEnde, 0, 99999.0, AuftragEnde) AEnde'
      + ' from Laufzeitlog where MaschNr = ' + IntToStr(MaschNr)
      + ' and RuestStart < ' + FloatToPunktString(DTE) + ' and Decode(AuftragEnde, 0, 99999.0, AuftragEnde) > ' + FloatToPunktString(DT)
      + ' union'
      + ' select Kommt AStart, Decode(Geht, 0, 99999.0, Geht) AEnde from TPM_Stillog where MaschNr = ' + IntToStr(MaschNr)
      + ' and Kommt < ' + FloatToPunktString(DTE) + ' and Decode(Geht, 0, 99999.0, Geht) > ' + FloatToPunktString(DT)
      + ' union'
      + ' select 0 AStart, ' + FloatToPunktString(DT) + ' AEnde from dual'
      + ' union'
      + ' select ' + FloatToPunktString(DTE) + ' AStart, 0 AEnde from dual)'
      + ' order by AStart';
    SQL_Get(qSuch2, S);

    TimeNoJob := 0;
    AStart := qSuch2.FieldByName('AEnde').AsFloat;
    qSuch2.Next;
    while not qSuch2.EOF do
    begin
      AEnde := qSuch2.FieldByName('AStart').AsFloat;

      if AEnde > AStart then
        TimeNoJob := TimeNoJob + AEnde - AStart;

      if AStart < qSuch2.FieldByName('AEnde').AsFloat then
        AStart := qSuch2.FieldByName('AEnde').AsFloat;

      qSuch2.Next;
    end;

    S := 'update TPM_Produktionsdetail set Verpackt = ' + IntToStr(Verp) + ','
      + ' LZ_No_Job = ' + IntToStr(Round(TimeNoJob * 1440)) + ' where Nr = ' + Nr;
    SQL_Insert(qUpdate, S);

    qSuch.Next;
  end;

  S := 'update TPM_Produktionsdetail set M_NUTZ = ' + IntToStr(MaxSchichtTime)
    + ' where M_NUTZ > ' + IntToStr(MaxSchichtTime) + ''
    + ' and DatumZeit > ' + FloatToPunktString(StartDate)
    + ' and datumzeit < ' + FloatToPunktString(StartDate + Days);
  SQL_Insert(qUpdate, S);

  // Anlagenausfall, Ruesten, Logistik, NICHT_GEBUCHT
  for I := 0 to 3 do
  begin
    S := 'select * from TPM_Stillstaende where Gruppe = ' + IntToStr(I);
    SQL_Get(qSuch, S);
    S1 := '';
    while not qSuch.EOF do
    begin
      S1 := S1 + '+Max(STILL_' + qSuch.FieldByName('StillStandNr').AsString + ')';
      qSuch.Next;
    end;
    if Length(S1) > 0 then
      System.Delete(S1, 1, 1)
    else
      S1 := '0';
    S := 'update TPM_Produktionsdetail set ';
    case I of
      0: F := 'Anlagenausfall';
      1: F := 'Ruesten';
      2: F := 'Logistik';
      3: F := 'NICHT_GEBUCHT';
    end;
    S := S + F;

    S := S + ' = (select ' + S1 + ' from TPM_Auswertung'
      + ' where'
      + ' TPM_Produktionsdetail.Maschine = TPM_Auswertung.Maschine'
      + ' and TPM_Produktionsdetail.Datum = TPM_Auswertung.Datum'
      + ' and TPM_Produktionsdetail.Schicht = TPM_Auswertung.Schicht'
      + ' group by Maschine, Datum, Schicht)'
      + ' where ' + F + ' is null';

    SQL_Insert(qUpdate, S);
  end;

  // Geplant & ungeplant
  for I := 0 to 1 do
  begin
    S := 'select * from TPM_Stillstaende where Geplant = ' + IntToStr(I);
    SQL_Get(qSuch, S);
    S1 := '';
    while not qSuch.EOF do
    begin
      S1 := S1 + '+Max(STILL_' + qSuch.FieldByName('StillStandNr').AsString + ')';
      qSuch.Next;
    end;
    if Length(S1) > 0 then
      System.Delete(S1, 1, 1)
    else
      S1 := '0';
    S := 'update TPM_Produktionsdetail set ';
    case I of
      0: F := 'UNGEPL_STILL';
      1: F := 'GEPL_STILL';
    end;
    S := S + F;

    S := S + ' = (select ' + S1 + ' from TPM_Auswertung'
      + ' where'
      + ' TPM_Produktionsdetail.Maschine = TPM_Auswertung.Maschine'
      + ' and TPM_Produktionsdetail.Datum = TPM_Auswertung.Datum'
      + ' and TPM_Produktionsdetail.Schicht = TPM_Auswertung.Schicht'
      + ' group by Maschine, Datum, Schicht)'
      + ' where ' + F + ' is null';

    SQL_Insert(qUpdate, S);
  end;

  // Rüster geplant & Rüsten ungeplant
  for I := 0 to 1 do
  begin
    S := 'select * from TPM_Stillstaende where Gruppe = 1 and Geplant = ' + IntToStr(I);
    SQL_Get(qSuch, S);
    S1 := '';
    while not qSuch.EOF do
    begin
      S1 := S1 + '+Max(STILL_' + qSuch.FieldByName('StillStandNr').AsString + ')';
      qSuch.Next;
    end;
    if Length(S1) > 0 then
      System.Delete(S1, 1, 1)
    else
      S1 := '0';
    S := 'update TPM_Produktionsdetail set ';
    case I of
      0: F := 'RUESTEN_UNGEPL';
      1: F := 'RUESTEN_GEPL';
    end;
    S := S + F;

    S := S + ' = (select ' + S1 + ' from TPM_Auswertung'
      + ' where'
      + ' TPM_Produktionsdetail.Maschine = TPM_Auswertung.Maschine'
      + ' and TPM_Produktionsdetail.Datum = TPM_Auswertung.Datum'
      + ' and TPM_Produktionsdetail.Schicht = TPM_Auswertung.Schicht'
      + ' group by Maschine, Datum, Schicht)'
      + ' where ' + F + ' is null';
    SQL_Insert(qUpdate, S);
  end;

  S := 'update TPM_Produktionsdetail set EFF_KAP = Gesamt_Kap - Gepl_Still'
    + ' where EFF_KAP is null';
  SQL_Insert(qUpdate, S);

  S := 'update TPM_Produktionsdetail set EFF_KAP = 0 where EFF_KAP < 0';
  SQL_Insert(qUpdate, S);

  S := 'update TPM_Produktionsdetail set Ges_Still = Gepl_Still + Ungepl_Still'
    + ' where Ges_Still is null';
  SQL_Insert(qUpdate, S);

  S := 'update TPM_Produktionsdetail set'
    + ' EFF_KAP_PRZ = Round(Eff_Kap / Decode(WERKSPL_KAP, 0, -1, WERKSPL_KAP)*100, 2)'
    + ' where EFF_KAP_PRZ is null';
  SQL_Insert(qUpdate, S);

  S := 'update TPM_Produktionsdetail set EFF_KAP_PRZ = 0 where EFF_KAP_PRZ < 0';
  SQL_Insert(qUpdate, S);

  S := 'update TPM_Produktionsdetail set'
    + ' VERPACK_PRZ = Round(Verpackt / Decode(Produziert, 0, -1, Produziert)*100, 2)'
    + ' where VERPACK_PRZ is null';
  try
    SQL_Insert(qUpdate, S);
  except
    SchreibeMeldung('730E89BB-29EC-43D9-B4B7-45787B6D68E5', LogFile_Mode);
    S := 'update TPM_Produktionsdetail set'
      + ' VERPACK_PRZ = Round(Verpackt / Decode(Produziert, 0, -1, Produziert)*100, 2)'
      + ' where VERPACK_PRZ is null'
      + ' AND VERPACKT < 10 * produziert AND VERPACKT > -10 * produziert';
    try
      SQL_Insert(qUpdate, S);
    except
      SchreibeMeldung('730E89BB-29EC-43D9-B4B7-45787B6D68E6', LogFile_Mode);
    end;

  end;

  S := 'update TPM_Produktionsdetail set VERPACK_PRZ = 0 where VERPACK_PRZ < 0';
  SQL_Insert(qUpdate, S);

  S := 'update TPM_Produktionsdetail set'
    + ' M_NUTZ_PRZ = Round(M_NUTZ / Decode(Gesamt_Kap, 0, -1, Gesamt_Kap)*100, 2)'
    + ' where M_NUTZ_PRZ is null';
  SQL_Insert(qUpdate, S);

  S := 'update TPM_Produktionsdetail set M_NUTZ_PRZ = 0 where M_NUTZ_PRZ < 0';
  SQL_Insert(qUpdate, S);

  S := 'update TPM_Produktionsdetail set'
    + ' EFF_NUTZ_PRZ = Round(M_NUTZ / Decode(Eff_Kap, 0, -1, Eff_Kap)*100, 2)'
    + ' where EFF_NUTZ_PRZ is null';
  SQL_Insert(qUpdate, S);

  S := 'update TPM_Produktionsdetail set EFF_NUTZ_PRZ = 0 where EFF_NUTZ_PRZ < 0';
  SQL_Insert(qUpdate, S);

  S := 'update TPM_Produktionsdetail set'
    + ' NICHT_GEBUCHT_PRZ = Round(NICHT_GEBUCHT / Decode(Ges_Still, 0, -1, Ges_Still)*100, 2)'
    + ' where NICHT_GEBUCHT_PRZ is null';
  SQL_Insert(qUpdate, S);

  S := 'update TPM_Produktionsdetail set NICHT_GEBUCHT_PRZ = 0 where NICHT_GEBUCHT_PRZ < 0';
  SQL_Insert(qUpdate, S);

  S := 'update TPM_Produktionsdetail set'
    + ' ANLAGENAUSFALL_PRZ = Round(ANLAGENAUSFALL / Decode(Ges_Still, 0, -1, Ges_Still)*100, 2)'
    + ' where ANLAGENAUSFALL_PRZ is null';
  SQL_Insert(qUpdate, S);

  S := 'update TPM_Produktionsdetail set ANLAGENAUSFALL_PRZ = 0 where ANLAGENAUSFALL_PRZ < 0';
  SQL_Insert(qUpdate, S);

  S := 'update TPM_Produktionsdetail set'
    + ' RUESTEN_PRZ = Round(RUESTEN / Decode(Ges_Still, 0, -1, Ges_Still)*100, 2)'
    + ' where RUESTEN_PRZ is null';
  SQL_Insert(qUpdate, S);

  S := 'update TPM_Produktionsdetail set RUESTEN_PRZ = 0 where RUESTEN_PRZ < 0';
  SQL_Insert(qUpdate, S);

  S := 'update TPM_Produktionsdetail set'
    + ' LOGISTIK_PRZ = Round(LOGISTIK / Decode(Ges_Still, 0, -1, Ges_Still)*100, 2)'
    + ' where LOGISTIK_PRZ is null';
  SQL_Insert(qUpdate, S);

  S := 'update TPM_Produktionsdetail set LOGISTIK_PRZ = 0 where LOGISTIK_PRZ < 0';
  SQL_Insert(qUpdate, S);

  S := 'update TPM_Produktionsdetail set M_OEE_PRZ = Round(M_Nutz_PRZ*Leistung_Prz/100, 2)'
    + ' where M_OEE_PRZ is null';
  SQL_Insert(qUpdate, S);

  S := 'update TPM_Produktionsdetail set EFF_OEE_PRZ = Round(Eff_Nutz_PRZ*Leistung_Prz/100, 2)'
    + ' where EFF_OEE_PRZ is null';
  SQL_Insert(qUpdate, S);

  S := 'update TPM_Produktionsdetail set M_Nutz = Eff_Kap where M_Nutz > Eff_Kap';
  SQL_Insert(qUpdate, S);

  S := 'update TPM_Auswertung set Produziert_Soll = 0 where Produziert_Soll < 0';
  SQL_Insert(qUpdate, S);
end;
// *****************************************************************************


procedure TThread_Schicht.Berechne_Extrusion(TPMNr: Integer; AuftragNr: string; Von, Bis: Real);
begin
  SQLStr := 'update TPM_Schicht set SOLLAUSSTOSS = (select SOLLAUSSTOSS from AARCHIV '
    + ' where TPM_Schicht.BetriebsauftragNr = AARCHIV.BetriebsauftragNr)'
    + ' where Nr = ''' + IntToStr(TPMNr) + '''';
  SQL_Insert(qUpdate, SQLStr);

  SQLStr := 'update TPM_Schicht set ISTAUSSTOSS = (select ISTAUSSTOSS from AARCHIV '
    + ' where TPM_Schicht.BetriebsauftragNr = AARCHIV.BetriebsauftragNr)'
    + ' where Nr = ''' + IntToStr(TPMNr) + '''';
  SQL_Insert(qUpdate, SQLStr);

  SQLStr := 'update TPM_Schicht set STUECK_NACH_KILO = (select STUECK_NACH_KILO from AARCHIV '
    + ' where  TPM_Schicht.BetriebsauftragNr = AARCHIV.BetriebsauftragNr)'
    + ' where Nr = ''' + IntToStr(TPMNr) + '''';
  SQL_Insert(qUpdate, SQLStr);

  SQLStr := 'update TPM_Schicht set METER_NACH_KILO = (select METER_NACH_KILO from AARCHIV '
    + ' where  TPM_Schicht.BetriebsauftragNr = AARCHIV.BetriebsauftragNr)'
    + ' where Nr = ''' + IntToStr(TPMNr) + '''';
  SQL_Insert(qUpdate, SQLStr);

  SQLStr := 'update TPM_Schicht set PRODUZIERT = '
    + ' (select sum(Menge) as MENGE from MENGE_BUCH_PROT where BETRIEBSAUFTRAGNR = ''' + AuftragNr + ''''
    + ' AND DatumZeit between ''' + FloatToStr2(Von) + ''' and ''' + FloatToStr2(Bis) + ''')'
    + ' where Nr = ''' + IntToStr(TPMNr) + '''';
  SQL_Insert(qUpdate, SQLStr);
  SQLStr := 'update TPM_Schicht set PRODUZIERT_ORG = produziert'
    + ' where Nr = ''' + IntToStr(TPMNr) + '''';
  SQL_Insert(qUpdate, SQLStr);

  SQLStr := 'update TPM_Schicht set FREI_INT_1 = PRODUZIERT * STUECK_NACH_KILO where ''' + GetL('Stück') + ''' = '
    + ' (select max(Einheit) as EINHEIT from MENGE_BUCH_PROT where BETRIEBSAUFTRAGNR = TPM_SCHICHT.BETRIEBSAUFTRAGNR)'
    + ' and Nr = ''' + IntToStr(TPMNr) + '''';
  SQL_Insert(qUpdate, SQLStr);

  SQLStr := 'update TPM_Schicht set FREI_INT_1 = PRODUZIERT where ''' + GetL('Kg') + ''' = '
    + ' (select max(Einheit) as EINHEIT from MENGE_BUCH_PROT where BETRIEBSAUFTRAGNR = TPM_SCHICHT.BETRIEBSAUFTRAGNR)'
    + ' and Nr = ''' + IntToStr(TPMNr) + '''';
  SQL_Insert(qUpdate, SQLStr);
end;
// *****************************************************************************

procedure TThread_Schicht.Berechne_TPM_Auftragsdetail(Days: Integer; MNRs: string);
var
  BANr, Nr, S, Status, Liz, S1: string;
  A, Prod, Start, Ende: Real;
  MaschNr: Integer;
begin
//  S := 'select * from aarchiv where Decode(EndDatumZeit, 0, 99999, EndDatumZeit) > '''
  S := 'select * from aarchiv where enddatumzeit < 1 or enddatumzeit > '
    + FloatToPunktString(N_o_w - Days) + ' '
    + GetSelectedMaschinen(qUpdate, 'and', 'Maschine', MNrs, 1);
  SQL_Get(qSuch, S);

  while not qSuch.EOF do
  begin
    BANr := qSuch.FieldByName('BetriebsAuftragNr').AsString;

    Start := GFloat(qSuch.FieldByName('StartDatumZeit').AsString);
    Liz := qSuch.FieldByName('Maschine').AsString;

    if SQLGet(qSuch2, 'Maschine', 'Lizenz', Liz, True) > 0 then
      MaschNr := qSuch2.FieldByName('MaschNr').AsInteger
    else
      MaschNr := 0;

    if SQLGet(qSuch2, 'TPM_Auftragsdetail', 'BetriebsAuftragNr', BANr, True) > 0 then
    begin
      S := 'delete from TPM_Auftragsdetail where Nr = ' + qSuch2.FieldByName('Nr').AsString;
      SQL_Insert(qUpdate, S);
    end;

    S := 'select TPM_AuftragsdetailId.NextVal as CNT from Setup';
    SQL_Get(qSuch2, S);
    Nr := qSuch2.FieldByName('CNT').AsString;

    S := 'insert into TPM_Auftragsdetail (Nr, Lizenz, BetriebsAuftragNr, AuftragNr, Job_Start,'
      + ' Pieces_Per_Carton, Produced_CURR, Produced_Set, Scrap_Setup, Scrap_Production,'
      + ' Scrap_Production_Pcnt, CYCLE_TIME_CURR, CYCLE_TIME_SET, CAVITY_CURR, CAVITY_SET,'
      + ' UTILISATION_PCNT, EFFECIENTCY_PCNT, QUALITY_PCNT, PRODUCTIVITY_PCNT, zyklen) values ('
      + ' ''' + Nr + ''','
      + ' ''' + Liz + ''','
      + ' ''' + BANr + ''','
      + ' ''' + qSuch.FieldByName('AuftragNr').AsString + ''','
      + ' ''' + FloatToStr2(Start) + ''','
      + ' ''' + qSuch.FieldByName('PackGroesse').AsString + ''','
      + ' ''' + qSuch.FieldByName('ProduziertInt').AsString + ''','
      + ' ''' + qSuch.FieldByName('SollvorgabeInt').AsString + ''','
      + ' ''' + qSuch.FieldByName('Anfahr_Ausschuss').AsString + ''','
      + ' ''' + qSuch.FieldByName('Ausschuss').AsString + ''','
      + ' ''' + qSuch.FieldByName('AusschussPRZ').AsString + ''','
      + ' ''' + FloatToStr2(qSuch.FieldByName('TaktzeitIst').AsInteger / 100) + ''','
      + ' ''' + FloatToStr2(qSuch.FieldByName('TaktZeitSoll').AsInteger / 100) + ''','
      + ' ''' + qSuch.FieldByName('Kavitaet').AsString + ''','
      + ' ''' + qSuch.FieldByName('Kavitaet_Soll').AsString + ''','
      + ' ''' + qSuch.FieldByName('Nutzung').AsString + ''','
      + ' ''' + qSuch.FieldByName('Effektivitaet').AsString + ''','
      + ' ''' + qSuch.FieldByName('Qualitaet').AsString + ''','
      + ' ''' + qSuch.FieldByName('Leistung').AsString + ''','
      + ' ''' + qSuch.FieldByName('zyklen').AsString
      + ''')';
    SQL_Insert(qUpdate, S);

    if SQLGet(qSuch2, 'PDE', 'BetriebsAuftragNr', BANr, True) > 0 then
    begin
      case qSuch2.FieldByName('Stat').AsInteger of
        0: Status := GetL('läuft');
        1: Status := GetL('rüsten');
        2: Status := GetL('geplant');
        5: Status := GetL('unterbrochen');
      end;
      Ende := GFloat(qSuch2.FieldByName('EndDatumZeit').AsString);
    end
    else
    begin
      Status := GetL('beendet');
      Ende := GFloat(qSuch.FieldByName('EndDatumZeit').AsString);
    end;

    S := 'update TPM_Auftragsdetail set JOB_STATUS = ''' + Status + ''','
      + ' JOB_END = ''' + FloatToStr2(Ende) + ''''
      + ' where Nr = ' + Nr;
    SQL_Insert(qUpdate, S);

    S := 'update TPM_Auftragsdetail set'
      + ' RUN_CURR = ''' + qSuch.FieldByName('LaufzeitIst').AsString + ''','
      + ' RUN_SET = ''' + qSuch.FieldByName('LaufzeitSoll').AsString + ''','
      + ' SETUP_CURR = ''' + qSuch.FieldByName('RuestzeitIst').AsString + ''','
      + ' SETUP_SET = ''' + qSuch.FieldByName('RuestzeitSoll').AsString + ''''
      + ' where Nr = ' + Nr;
    SQL_Insert(qUpdate, S);

    S := 'update TPM_Auftragsdetail set'
      + ' OPERATION_CURR = RUN_CURR + SETUP_CURR,'
      + ' OPERATION_SET = RUN_SET + SETUP_SET'
      + ' where Nr = ' + Nr;
    SQL_Insert(qUpdate, S);

    S := 'update TPM_Auftragsdetail set'
      + ' SETUP_PCNT_CURR = Decode(OPERATION_CURR, 0, 0, Round(SETUP_CURR / OPERATION_CURR * 100, 2)),'
      + ' SETUP_PCNT_SET = Decode(OPERATION_SET, 0, 0, Round(SETUP_SET / OPERATION_SET * 100, 2))'
      + ' where Nr = ' + Nr;
    SQL_Insert(qUpdate, S);

    S := 'select Sum((Decode(Geht, 0, ''' + FloatToStr2(N_o_w) + ''', Geht) - Kommt) * 1440) as CNT'
      + ' from TPM_Stillog'
      + ' where (Kommt <= ''' + FloatToStr2(Start) + ''' and Decode(Geht, 0, ''99999'', Geht) > ''' + FloatToStr2(Start)
      +
      ''''
      + ' or Kommt >= ''' + FloatToStr2(Start) + ''' and Kommt < ''' + FloatToStr2(Ende) + ''') and MaschNr = ' +
      IntToStr(MaschNr);
    SQL_Get(qSuch2, S);

    S := 'update TPM_Auftragsdetail set'
      + ' DOWNTIME_CURR = ' + IntToStr(Round(GFloat(qSuch2.FieldByName('CNT').AsString)))
      + ' where Nr = ' + Nr;
    SQL_Insert(qUpdate, S);

    S1 := 'select Sum((Decode(Geht, 0, ''' + FloatToStr2(N_o_w) + ''', Geht) - Kommt) * 1440) as CNT'
      + ' from TPM_Stillog, TPM_Stillstaende'
      + ' where (TPM_Stillog.StillstandNr = TPM_Stillstaende.StillstandNr)'
      + ' and (Kommt <= ''' + FloatToStr2(Start) + ''' and Decode(Geht, 0, ''99999'', Geht) > ''' + FloatToStr2(Start) +
      ''''
      + ' or Kommt >= ''' + FloatToStr2(Start) + ''' and Kommt < ''' + FloatToStr2(Ende) + ''') and MaschNr = ' +
      IntToStr(MaschNr);

    S := S1 + ' and TPM_Stillstaende.Geplant = 1';
    SQL_Get(qSuch2, S);

    S := 'update TPM_Auftragsdetail set'
      + ' DOWNTIME_SET = ' + IntToStr(Round(GFloat(qSuch2.FieldByName('CNT').AsString)))
      + ' where Nr = ' + Nr;
    SQL_Insert(qUpdate, S);

    S := 'update TPM_Auftragsdetail set'
      + ' TOTAL_JOB_CURR = OPERATION_CURR + DOWNTIME_CURR,'
      + ' TOTAL_JOB_SET = OPERATION_SET + DOWNTIME_SET'
      + ' where Nr = ' + Nr;
    SQL_Insert(qUpdate, S);

    S := 'update TPM_Auftragsdetail set'
      + ' DOWNTIME_PCNT_CURR = Decode(TOTAL_JOB_CURR, 0, 0, Round(DOWNTIME_CURR / TOTAL_JOB_CURR * 100, 2)),'
      + ' DOWNTIME_PCNT_SET = Decode(TOTAL_JOB_SET, 0, 0, Round(DOWNTIME_SET / TOTAL_JOB_SET * 100, 2))'
      + ' where Nr = ' + Nr;
    SQL_Insert(qUpdate, S);

    S := 'update TPM_Auftragsdetail set'
      + ' Good = Produced_Curr - Scrap_Production'
      + ' where Nr = ' + Nr;
    SQL_Insert(qUpdate, S);

    S := 'update TPM_Auftragsdetail set'
      + ' CARTON_CURR = Decode(Pieces_Per_Carton, 0, 0, Round(Good / Pieces_Per_Carton))'
      + ' where Nr = ' + Nr;
    SQL_Insert(qUpdate, S);

    S := 'update TPM_Auftragsdetail set'
      + ' CARTON_Set = Decode(Pieces_Per_Carton, 0, 0, Round(Produced_Set / Pieces_Per_Carton))'
      + ' where Nr = ' + Nr;
    SQL_Insert(qUpdate, S);

    S := S1 + ' and TPM_Stillstaende.Geplant = 1';
    SQL_Get(qSuch2, S);

    S := 'update TPM_Auftragsdetail set'
      + ' DOWNTIME_SCHEDULED = ' + IntToStr(Round(GFloat(qSuch2.FieldByName('CNT').AsString)))
      + ' where Nr = ' + Nr;
    SQL_Insert(qUpdate, S);

    S := S1 + ' and TPM_Stillstaende.Geplant = 0';
    SQL_Get(qSuch2, S);

    S := 'update TPM_Auftragsdetail set'
      + ' DOWNTIME_UNSCHEDULED = ' + IntToStr(Round(GFloat(qSuch2.FieldByName('CNT').AsString)))
      + ' where Nr = ' + Nr;
    SQL_Insert(qUpdate, S);

    S := S1 + ' and TPM_Stillstaende.Gruppe = 3';
    SQL_Get(qSuch2, S);

    S := 'update TPM_Auftragsdetail set'
      + ' NOT_BOOKED = ' + IntToStr(Round(GFloat(qSuch2.FieldByName('CNT').AsString)))
      + ' where Nr = ' + Nr;
    SQL_Insert(qUpdate, S);

    S := S1 + ' and TPM_Stillstaende.Gruppe = 0';
    SQL_Get(qSuch2, S);

    S := 'update TPM_Auftragsdetail set'
      + ' SYSTEM_FAILURE = ' + IntToStr(Round(GFloat(qSuch2.FieldByName('CNT').AsString)))
      + ' where Nr = ' + Nr;
    SQL_Insert(qUpdate, S);

    S := S1 + ' and TPM_Stillstaende.Gruppe = 2';
    SQL_Get(qSuch2, S);

    S := 'update TPM_Auftragsdetail set'
      + ' LOGISTIC = ' + IntToStr(Round(GFloat(qSuch2.FieldByName('CNT').AsString)))
      + ' where Nr = ' + Nr;
    SQL_Insert(qUpdate, S);

    S := S1 + ' and TPM_Stillstaende.Gruppe = 1';
    SQL_Get(qSuch2, S);

    S := 'update TPM_Auftragsdetail set'
      + ' SETUP = ' + IntToStr(Round(GFloat(qSuch2.FieldByName('CNT').AsString)))
      + ' where Nr = ' + Nr;
    SQL_Insert(qUpdate, S);

    S := 'select Count(*) as CNT'
      + ' from TPM_Stillog'
      + ' where'
      + ' (Kommt >= ''' + FloatToStr2(Start) + ''' and Kommt < ''' + FloatToStr2(Ende) + ''') and MaschNr = ' +
      IntToStr(MaschNr);
    SQL_Get(qSuch2, S);

    S := 'update TPM_Auftragsdetail set'
      + ' TOTAL_NO_STOPS = ' + IntToStr(Round(GFloat(qSuch2.FieldByName('CNT').AsString)))
      + ' where Nr = ' + Nr;
    SQL_Insert(qUpdate, S);

    S := 'update TPM_Auftragsdetail set'
      + ' OPER_CAVITY_SET = ''' + qSuch.FieldByName('LaufzeitSoll').AsString + ''''
      + ' where Nr = ' + Nr;
    SQL_Insert(qUpdate, S);

    S := 'select * from KAVProt where BetriebsAuftragNr = ''' + BANr + ''''
      + ' and Wert1 = ''' + qSuch.FieldByName('Kavitaet_Soll').AsString + ''''
      + ' and Wert2 = ''' + qSuch.FieldByName('Kavitaet').AsString + '''';
    SQL_Get(qSuch2, S);
    if not qSuch2.EOF then
    begin
      S := 'update TPM_Auftragsdetail set'
        + ' OPER_CAVITY_CURR = ''' + IntToStr(Trunc((qSuch2.FieldByName('Datum').AsFloat - Start) * 1440)) + ''''
        + ' where Nr = ' + Nr;
      Prod := qSuch2.FieldByName('Produziert').AsInteger;
    end
    else
    begin
      S := 'update TPM_Auftragsdetail set'
        + ' OPER_CAVITY_CURR = OPER_CAVITY_SET'
        + ' where Nr = ' + Nr;
      Prod := 0;
    end;
    SQL_Insert(qUpdate, S);

    try
      if qSuch.FieldByName('Kavitaet_Soll').AsFloat <> 0 then
        A := qSuch.FieldByName('Kavitaet').AsFloat * 100 / qSuch.FieldByName('Kavitaet_Soll').AsFloat
      else
        A := 0;
    except
      A := 0;
    end;
    S := 'update TPM_Auftragsdetail set'
      + ' CAVITY_EFF_PCNT = ''' + FloatToStrF2(A, ffFixed, 10, 1) + ''''
      + ' where Nr = ' + Nr;
    SQL_Insert(qUpdate, S);

    A := (qSuch.FieldByName('SollvorgabeInt').AsInteger - Prod) * (100 - A) / 100;
    A := Round(A);

    S := 'update TPM_Auftragsdetail set'
      + ' PIECES_CAVITY_LOST = ''' + FloatToStr2(A) + ''''
      + ' where Nr = ' + Nr;
    SQL_Insert(qUpdate, S);

    qSuch.Next;
  end;
end;
// *****************************************************************************

procedure TThread_Schicht.GetStillZeit(VonDatum, BisDatum: TDateTime; MaschNr, Stillstandnr: Integer;
  AStart, AEnde: Real; var Dauer, Anzahl, ADauer: Integer);
var
  Kommt, Geht, kommtdb: TDateTime;
  kDauer, lDauer: Real;
  K: Integer;
begin
  if BisDatum > N_o_w then
    BisDatum := N_o_w;
  kDauer := 0;
  ADauer := 0;
  lDauer := 0;
  K := 0;
  SQLStr := 'select Kommt, Decode(Geht, ''0'', ' + FloatToPunktString(N_o_w) + ', Geht) as Geht, Stillstandnr'
    + ' from TPM_STILLOG where MaschNr = ' + IntToStr(MaschNr)
    + ' AND StillstandNr = ' + IntToStr(Stillstandnr) + ' and'
    + ' (Kommt <= ' + FloatToPunktString(VonDatum) + ' '
    + ' and Decode(Geht, ''0'', ' + FloatToPunktString(N_o_w) + ', Geht) >= ' + FloatToPunktString(VonDatum) + ' '
    + ' or Kommt >= ' + FloatToPunktString(VonDatum) + ' and Kommt <= ' + FloatToPunktString(BisDatum) + ')';

  // Bei Nachberechnung auch alte Stillstände mit einbeziehen. Achtung sehr langsam, da Tabelle nicht indiziert.
  // Bei vielen Maschinen und Stilltsänden, Tabelle indizieren.
  if fNachBerechnung then
    SQLStr := SQLStr
      + ' union select Kommt, Decode(Geht, ''0'', ' + FloatToPunktString(N_o_w) + ', Geht) as Geht, Stillstandnr'
      + ' from TPM_STILLOG_ARC where MaschNr = ' + IntToStr(MaschNr)
      + ' AND StillstandNr = ' + IntToStr(Stillstandnr) + ' and'
      + ' (Kommt <= ' + FloatToPunktString(VonDatum) + ' '
      + ' and Decode(Geht, ''0'', ' + FloatToPunktString(N_o_w) + ', Geht) >= ' + FloatToPunktString(VonDatum) + ' '
      + ' or Kommt >= ' + FloatToPunktString(VonDatum) + ' and Kommt <= ' + FloatToPunktString(BisDatum) + ')';

  SQLStr := SQLStr + ' order by Kommt';
  SQL_Get(qSuch4, SQLStr);
  while not qSuch4.EOF do
  begin
    kommtdb :=qSuch4.FieldByName('Kommt').AsFloat;
    Kommt := MAX(kommtdb, VonDatum);
    Geht := Min(qSuch4.FieldByName('Geht').AsFloat, BisDatum);
    if Kommt > Geht then
      Kommt := Geht;
    kDauer := kDauer + (Geht - Kommt) * 1440;
    if kommtdb >= VonDatum then  // NUr wenn Innerhalb des Betrachtungszeitraums der Stillstand aufgetreten ist zählen
      Inc(K);

    Kommt := MAX(Kommt, AStart);
    Geht := Min(Geht, AEnde);
    if Kommt > Geht then
      Kommt := Geht;
    lDauer := lDauer + (Geht - Kommt) * 1440;

    qSuch4.Next;
  end;

  Dauer := Round(kDauer);
  ADauer := Round(lDauer);
  Anzahl := K;
end;
// *****************************************************************************

procedure TThread_Schicht.Berechne_TPM_Auswertung(Von, Bis: TDateTime; MNRs: string);
var
  S, NrStr, BANr, MaschNr: string;
  Dat, SchichtDatum: Real;
  D, Dauer, Anzahl, ADauer, Nr, I, Schicht: Integer;

  AGeplant, AUngeplant, AAnlagenAusfall, ARuesten: Integer;
  ALogistik, ANichtGebucht, ASollLaufZeit, AIstLaufZeit: Integer;

  AAnlagenAusfall_Ungepl, AAnlagenAusfall_Gepl, ARuesten_Ungepl, ARuesten_Gepl,
    ALogistik_Ungepl, ALogistik_Gepl, ANichtGebucht_Ungepl, ANichtGebucht_Gepl: Integer;

  Sollaufzeit: Integer;
  STUECKZAHL_PRO_STUNDE, Verpackt_Korr, Prod_Soll: Integer;
  MAX_GUTTEILE_Schicht, ZyklenSchicht: Integer;
  MAX_GUTTEILE_STUNDE: Integer;
  DT, VonDat, BisDat, TAKTZEIT_MITTEL_IST, SchichtZeit: Real;
  calgroup, Verpackt: Integer;
  Ruest, Gepl, UnGepl, effkap, mnutz, alldowns: Integer;
  effkap_pcnt, musetime_pcnt, eff_use, mach_oee, eff_oee: Real;
  UnBooked, breakdown, setuptime, logistics, perf: Real;
  AStart, AEnde: Real;
  r2_plcrun, r2_plcdown, r2_plcparts : Integer;

  Stillst: array of record
    StillNr, StillGepl, StillGruppe, ZrVorhanden: Integer;
  end;
  Maschinendaten_Ohne_Auftrag: Boolean;

  StartTime: Real;
  EstimatedEnd: string;
begin
  // TPM_Schicht_Schicht3; // Korrektur DatumZeit in TPM_Schicht für Schicht 3

  S := 'Select Maschinendaten_Ohne_Auftrag from Setup';
  SQL_Get(qSuch, S);
  Maschinendaten_Ohne_Auftrag := qSuch.FieldByName('Maschinendaten_Ohne_Auftrag').AsInteger = 1;

  BANr := '';
  S := 'select Count(*) as CNT from TPM_Stillstaende';
  SQL_Get(qSuch, S);
  SetLength(Stillst, qSuch.FieldByName('CNT').AsInteger);
  I := 0;
  S := 'Select * from TPM_Stillstaende';
  SQL_Get(qSuch, S);
  while not qSuch.EOF do
  begin
    Stillst[I].StillNr := qSuch.FieldByName('StillstandNr').AsInteger;
    Stillst[I].StillGepl := qSuch.FieldByName('Geplant').AsInteger;
    Stillst[I].StillGruppe := qSuch.FieldByName('Gruppe').AsInteger;
    Stillst[I].ZrVorhanden := 0;
    qSuch.Next;
    Inc(I);
  end;

  // Nur Stillstände, die auch wirklich in dem Zeitraum gebucht wurden
    SQLStr := 'SELECT distinct(stillstandnr) stillnr FROM TPM_STILLOG where '
      + ' Kommt <= ' + FloatToPunktString(Bis)
      + ' and (Geht >= '+ FloatToPunktString(Von) + ' or geht < 1)';

    qSuch4.SQL.Text := SQLStr;
    qSuch4.Open;
    while not qSuch4.Eof do
    begin
      for i := 0 to Length(Stillst) - 1 do
        if Stillst[i].StillNr = qSuch4.FieldByName('stillnr').AsInteger then
          Stillst[i].ZrVorhanden := 1;
      qSuch4.Next;
    end;

  // Daten löschen

  S := 'delete from TPM_AUSWERTUNG where DatumZeit between (' + FloatToPunktString(Von) + ') and (' + FloatToPunktString(Bis) + ')'
    + GetSelectedMaschinen(qUpdate, 'and', 'MaschNr', MNrs, 0);
  SQL_Insert(qUpdate, S);
  S := 'Select * from TPM_SCHICHT where DatumZeit between (' + FloatToPunktString(Von) + ') and (' + FloatToPunktString(Bis) + ')'
    + GetSelectedMaschinen(qUpdate, 'and', 'MaschNr', MNrs, 0)
    + ' order by DatumZeit, MaschNr';

  if not Recalculate_Mode then
    SchreibeMeldung('Recalculation from ' + DateTimeToStr(Von) + ' to ' + DateTimeToStr(Bis), LogFile_Mode);

  SQL_Get(qDurchlauf, S);

  SchichtDatum := 0;
  StartTime := N_o_w;
  while not qDurchlauf.EOF do
  begin
    if BANr <> '*' then
      BANr := qDurchlauf.FieldByName('BetriebsAuftragNr').AsString;

    Dat := qDurchlauf.FieldByName('Datum').AsDateTime;
    VonDat := 0;
    BisDat := 0;
    case qDurchlauf.FieldByName('Schicht').AsInteger of
      1:
        begin
          if Shift_Model <> 2 then
          begin
            VonDat := Trunc(qDurchlauf.FieldByName('DatumZeit').AsFloat) + Frac(Schicht1);
            BisDat := Trunc(qDurchlauf.FieldByName('DatumZeit').AsFloat) + Frac(Schicht2);
          end
          else
          begin
            VonDat := Trunc(qDurchlauf.FieldByName('DatumZeit').AsFloat) + Frac(Schicht1);
            BisDat := Trunc(qDurchlauf.FieldByName('DatumZeit').AsFloat) + Frac(Schicht2);
          end;
        end;
      2:
        begin
          if Shift_Model <> 2 then
          begin
            VonDat := Trunc(qDurchlauf.FieldByName('DatumZeit').AsFloat) + Frac(Schicht2);
            BisDat := Trunc(qDurchlauf.FieldByName('DatumZeit').AsFloat) + Frac(Schicht3);
          end
          else
          begin
            VonDat := Trunc(qDurchlauf.FieldByName('DatumZeit').AsFloat) + Frac(Schicht2);
            BisDat := Trunc(qDurchlauf.FieldByName('DatumZeit').AsFloat) + Frac(Schicht1) + 1;
          end;
        end;
      3:
        begin
          VonDat := Trunc(qDurchlauf.FieldByName('DatumZeit').AsFloat) + Frac(Schicht3);
          BisDat := Trunc(qDurchlauf.FieldByName('DatumZeit').AsFloat) + Frac(Schicht1) + 1;
        end;
    end;
    SQLGet(qSuch, 'maschine', 'maschnr', qDurchlauf.FieldByName('MASCHNR').AsString, False);
    calgroup := qSuch.FieldByName('werkskalendergruppe').AsInteger;
    qSuch.Close;

    Sollaufzeit := TTT_GetArbeitszeit_Schicht(qSuch4, qDurchlauf.FieldByName('MASCHNR').AsInteger, Dat,
      qDurchlauf.FieldByName('Schicht').AsInteger);
    SchichtDauer := GetSchichtDauer(qDurchlauf.FieldByName('Schicht').AsInteger);
    if (Sollaufzeit < 0) or (Sollaufzeit > SchichtDauer) then
      Sollaufzeit := SchichtDauer;

    if qDurchlauf.FieldByName('ISTLAUFZEIT').AsInteger > 0 then
    begin
      try
        STUECKZAHL_PRO_STUNDE := Trunc((qDurchlauf.FieldByName('PRODUZIERT').AsInteger
          - qDurchlauf.FieldByName('AUSSCHUSS').AsInteger)
          / (qDurchlauf.FieldByName('ISTLAUFZEIT').AsInteger / 60));
      except
        STUECKZAHL_PRO_STUNDE := 0;
      end;
    end
    else
      STUECKZAHL_PRO_STUNDE := 0;

    if qDurchlauf.FieldByName('SOLLTAKT').AsFloat > 0 then
    begin
      try
        MAX_GUTTEILE_Schicht := Trunc(((Sollaufzeit * 60) / qDurchlauf.FieldByName('SOLLTAKT').AsFloat) *
          qDurchlauf.FieldByName('KAVITAET').AsInteger);
      except
        MAX_GUTTEILE_Schicht := 0;
      end;
    end
    else
      MAX_GUTTEILE_Schicht := 0;

    MAX_GUTTEILE_STUNDE := Trunc(MAX_GUTTEILE_Schicht / 8);

    S := 'select TPM_AUSWERTUNGID.nextval as nr from setup';
    SQL_Get(qSuch, S);
    Nr := qSuch.FieldByName('Nr').AsInteger;

    TAKTZEIT_MITTEL_IST := qDurchlauf.FieldByName('IstTakt').AsFloat;

    r2_plcrun := qDurchlauf.FieldByName('r2_plcruntime').AsInteger;
    r2_plcdown := qDurchlauf.FieldByName('r2_plcdown').AsInteger;
    r2_plcparts := qDurchlauf.FieldByName('r2_plcparts').AsInteger;

    ZyklenSchicht := qDurchlauf.FieldByName('zyklen').AsInteger;

    if DateToStr(SchichtDatum) <> DateToStr(qDurchlauf.FieldByName('DatumZeit').AsFloat) then
    begin
      SchichtDatum := qDurchlauf.FieldByName('DatumZeit').AsFloat;
      if SchichtDatum <> Von then
        EstimatedEnd := DateTimeToStr(StartTime + (Bis - Von) * (N_o_w - StartTime) / (SchichtDatum - Von))
      else
        EstimatedEnd := '-';
      SchreibeMeldung('recalculation: ' + DateToStr(SchichtDatum) + ' [' + EstimatedEnd + ']', LogFile_Mode);
    end;

    SchichtDatum := qDurchlauf.FieldByName('DatumZeit').AsFloat;

    Ruest := qDurchlauf.FieldByName('RUESTEN').AsInteger;
    Gepl := qDurchlauf.FieldByName('GEPLANT').AsInteger;
    ungepl := qDurchlauf.FieldByName('UNGEPLANT').AsInteger;

    mnutz := SchichtDauer - Gepl - ungepl;
    effkap := SchichtDauer - Gepl;

    if TAKTZEIT_MITTEL_IST > 0 then
      perf := (qDurchlauf.FieldByName('SOLLTAKT').AsFloat / TAKTZEIT_MITTEL_IST) * 100
    else
      perf := 0;
    if Sollaufzeit <> 0 then
    begin
      effkap_pcnt := Gepl / Sollaufzeit * 100;
      musetime_pcnt := mnutz / Sollaufzeit * 100;
      mach_oee := perf * mnutz / Sollaufzeit;
    end
    else
    begin
      effkap_pcnt := 0;
      musetime_pcnt := 0;
      mach_oee := 0;
    end;

    if effkap <> 0 then
    begin
      eff_use := mnutz / effkap * 100;
      eff_oee := perf * mnutz / effkap;
    end
    else
    begin
      eff_use := 0;
      eff_oee := 0;
    end;

    if (ungepl + Ruest) <> 0 then
    begin
      unbooked := (qDurchlauf.FieldByName('NICHTGEBUCHT').AsInteger / (ungepl + Ruest)) * 100;
      breakdown := (qDurchlauf.FieldByName('ANLAGENAUSFALL').AsInteger / (ungepl + Ruest)) * 100;
      setuptime := (qDurchlauf.FieldByName('RUESTEN').AsInteger / (ungepl + Ruest)) * 100;
      logistics := (qDurchlauf.FieldByName('LOGISTIK').AsInteger / (ungepl + Ruest)) * 100;
    end
    else
    begin
      unbooked := 0;
      breakdown := 0;
      setuptime := 0;
      logistics := 0;
    end;

    S := 'Insert into TPM_AUSWERTUNG (nr, Maschine, maschnr, schicht, DatumZeit, AUFTRAGNR,'
      + ' ARTIKELNR, DATUM, KW, MONAT, QUARTAL, JAHR, SOLLLAUFZEIT, NETTOLAUFZEIT,'
      + ' AUSFALLZEIT, STILLSTANDSZEIT, TAKTZEIT_SOLL, TAKTZEIT_MITTEL_IST,'
      + ' PRODUZIERTE_MENGE, GUTTEILE, AUSSCHUSS, ANFAHRAUSSCHUSS, STUECKZAHL_PRO_STUNDE,'
      + ' MAX_GUTTEILE_SCHICHT, MAX_GUTTEILE_STUNDE, KAV_SOLL, KAV_IST, AUTOAUSSCHUSS,'
      + ' CAL_GROUP, CAPACITY_SHIFT, EFF_CAPACITY, EFF_CAPACITY_PCNT, MACH_USETIME, '
      + ' MACH_USETIME_PCNT, EFF_USE, PERFORMANCE, MACH_OEE, EFF_OEE,'
      + ' DOWNTIME_ALL, DOWNTIME_CAL, UNSCHED, SCHEDULED, UNBOOKED, BREAKDOWN,'
      + ' SETUPTIME, LOGISTICS, STOPS, r2_plcruntime, r2_plcdown, r2_plcparts, zyklen)'
      + ' values (' + IntToStr(Nr)
      + ',''' + TTT_GetMaschine(qDurchlauf.FieldByName('MASCHNR').AsInteger)
      + ''',''' + IntToStr(qDurchlauf.FieldByName('MASCHNR').AsInteger)
      + ''',''' + IntToStr(qDurchlauf.FieldByName('SCHICHT').AsInteger)
      + ''',' + FloatToPunktString(SchichtDatum)
      + ',''' + BANr
      + ''',''' + GetArtikelNr(BANr)
      + ''',''' + DateToStr(SchichtDatum) // Datum
    + ''',''' + GetKW(SchichtDatum) //KW
    + ''',''' + GetMonat(SchichtDatum) //Monat
    + ''',''' + GetQuartal(SchichtDatum) // QUARTAL
    + ''',''' + GetJahr(SchichtDatum) //Jahr
    + ''',''' + IntToStr(Sollaufzeit) //SOLLLAUFZEIT
    + ''',''' + IntToStr(qDurchlauf.FieldByName('ISTLAUFZEIT').AsInteger) //NETTOLAUFZEIT
    + ''',''' + IntToStr(qDurchlauf.FieldByName('UNGEPLANT').AsInteger
      + qDurchlauf.FieldByName('RUESTEN').AsInteger) //AUSFALLZEIT
    + ''',''' + IntToStr(qDurchlauf.FieldByName('GEPLANT').AsInteger
      - qDurchlauf.FieldByName('RUESTEN').AsInteger) //STILLSTANDSZEIT
    + ''',' + FloatToPunktString(qDurchlauf.FieldByName('SOLLTAKT').AsFloat) //TAKTZEIT_SOLL
    + ',' + FloatToPunktString(TAKTZEIT_MITTEL_IST) //TAKTZEIT_MITTEL_IST
    + ',''' + IntToStr(qDurchlauf.FieldByName('PRODUZIERT').AsInteger) //PRODUZIERTE_MENGE
    + ''',''' + IntToStr(qDurchlauf.FieldByName('PRODUZIERT').AsInteger
      - qDurchlauf.FieldByName('AUSSCHUSS').AsInteger) //GUTTEILE
    + ''',''' + IntToStr(qDurchlauf.FieldByName('AUSSCHUSS').AsInteger) //AUSSCHUSS
    + ''',''' + IntToStr(qDurchlauf.FieldByName('ANFAHRAUSSCHUSS').AsInteger) //ANFAHRAUSSCHUSS
    + ''',''' + IntToStr(STUECKZAHL_PRO_STUNDE) //STUECKZAHL_PRO_STUNDE
    + ''',''' + IntToStr(MAX_GUTTEILE_Schicht) //MAX_GUTTEILE_SCHICHT
    + ''',''' + IntToStr(MAX_GUTTEILE_STUNDE) //MAX_GUTTEILE_STUNDE
    + ''',''' + IntToStr(qDurchlauf.FieldByName('KAV_SOLL').AsInteger) //KAV_SOLL
    + ''',''' + IntToStr(qDurchlauf.FieldByName('KAVITAET').AsInteger) //KAV_IST
    + ''',''' + IntToStr(qDurchlauf.FieldByName('AUTOAUSSCHUSS').AsInteger
      * qDurchlauf.FieldByName('KAVITAET').AsInteger) //AUTOAUSSCHUSS
    + ''',''' + IntToStr(calgroup) //CAL_GROUP
    + ''',''' + IntToStr(SchichtDauer) //CAPACITY_SHIFT
    + ''',''' + IntToStr(effkap) //EFF_CAPACITY
    + ''',' + FloatToPunktString(Round(effkap_pcnt)) // EFF_CAPACITY_PCNT
    + ',''' + IntToStr(mnutz) // MACH_USETIME
    + ''',' + FloatToPunktString(Round(musetime_pcnt)) // MACH_USETIME_PCNT
    + ',' + FloatToPunktString(Round(eff_use)) // EFF_USE
    + ',' + FloatToPunktString(Round(perf)) // PERFORMANCE
    + ',' + FloatToPunktString(Round(mach_oee)) // MACH_OEE
    + ',' + FloatToPunktString(Round(eff_oee)) // EFF_OEE
    + ',''' + IntToStr(Gepl + ungepl) // DOWNTIME_ALL
    + ''',''' + IntToStr(SchichtDauer - effkap) // DOWNTIME_CAL
    + ''',''' + IntToStr(qDurchlauf.FieldByName('UNGEPLANT').AsInteger) // UNSCHED
    + ''',''' + IntToStr(qDurchlauf.FieldByName('GEPLANT').AsInteger) // UNSCHED
    + ''',' + FloatToPunktString(unbooked) // UNBOOKED
    + ',' + FloatToPunktString(Round(breakdown)) // BREAKDOWN
    + ',' + FloatToPunktString(Round(setuptime)) // SETUPTIME
    + ',' + FloatToPunktString(Round(logistics)) // LOGISTICS
    + ',' + IntToStr(qDurchlauf.FieldByName('STOPS').AsInteger) // STOPS
    + ',' + IntToStr(r2_plcrun) //
    + ',' + IntToStr(r2_plcdown) //
    + ',' + IntToStr(r2_plcparts) //
    + ',' + IntToStr(ZyklenSchicht) //
    + ')';

    SQL_Insert(qUpdate, S);
    // ********************** verpackt ****************************
    if BANr <> '*' then
    begin
      S := 'select Sum(Zugang-Abgang) as CNT from VerpacktProt where BetriebsAuftragNr = '
        + '''' + BANr + ''' and Barcode = ''' + GetL('Manuell') + ''' and datum between ('
        + FloatToPunktString(DT) + ') and (' + FloatToPunktString(DT + 1 / 3) + ')';
      SQL_Get(qSuch2, S);
      try
        Verpackt_Korr := qSuch2.FieldByName('CNT').AsInteger;
      except
        Verpackt_Korr := 0;
      end;

      if verpackt_aus_ausschuss then
        Verpackt := qDurchlauf.FieldByName('Verpackt').AsInteger
      else
      begin
        S := 'select Sum(Zugang-Abgang) as CNT from VerpacktProt where BetriebsAuftragNr = ''' + BANr + ''''
          + ' and (datum between (' + FloatToPunktString(VonDat)
          + ') and (' + FloatToPunktString(BisDat) + '))';
        SQL_Get(qSuch, S);
        Verpackt := qSuch.FieldByName('CNT').AsInteger;
      end;
    end
    else
    begin
      Verpackt_Korr := 0;
      Verpackt := 0;
    end;

    //***********  Start, Ende  ***************************
    AStart := VonDat;
    AEnde := BisDat;
    if BANr <> '*' then
      if SQLGet(qSuch2, 'AARchiv', 'BetriebsAuftragNr', BANr, True) > 0 then
      begin
        AStart := GFloat(qSuch2.FieldByName('StartDatumZeit').AsString);
        AEnde := GFloat(qSuch2.FieldByName('EndDatumZeit').AsString);
        if AEnde = 0 then
          AEnde := N_o_w;
      end;

    AStart := MAX(AStart, VonDat);
    AEnde := Min(AEnde, BisDat);
    if AStart > AEnde then
      AStart := AEnde;

    //***********  Stillstaende  ***************************

    AGeplant := 0;
    AUngeplant := 0;

    AAnlagenAusfall := 0;
    ARuesten := 0;
    ALogistik := 0;
    ANichtGebucht := 0;

    AAnlagenAusfall_Ungepl := 0;
    AAnlagenAusfall_Gepl := 0;
    ARuesten_Ungepl := 0;
    ARuesten_Gepl := 0;
    ALogistik_Ungepl := 0;
    ALogistik_Gepl := 0;
    ANichtGebucht_Ungepl := 0;
    ANichtGebucht_Gepl := 0;

    AIstLaufZeit :=0;
    ASollLaufZeit := 0;


    S := '';
    for I := 0 to Length(Stillst) - 1 do
    begin
      if Stillst[i].ZrVorhanden =0 then
      begin
        ADauer :=0;
        Anzahl :=0;
        Dauer := 0;
      end
      else
      begin
        GetStillZeit(VonDat, BisDat, qDurchlauf.FieldByName('MaschNr').AsInteger, Stillst[I].StillNr,
          AStart, AEnde, Dauer, Anzahl, ADauer);
      end;
	
	// Stillstände werden nicht mehr in den einzelnen Spalten in TPM_AUSWERTUNG berechnet. Dauert zu lange und ist nicht notwendig.
    //  S := S + ' STILL_' + IntToStr(Stillst[I].StillNr) + ' = ' + IntToStr(Dauer)
    //   + ', COUNT_' + IntToStr(Stillst[I].StillNr) + ' = ' + IntToStr(Anzahl) + ', ';

      case Stillst[I].StillGepl of
        0: AUngeplant := AUngeplant + ADauer;
        1: AGeplant := AGeplant + ADauer;
      end;

      case Stillst[I].StillGruppe of
        0: AAnlagenAusfall := AAnlagenAusfall + ADauer;
        1: ARuesten := ARuesten + ADauer;
        2: ALogistik := ALogistik + ADauer;
        3: ANichtGebucht := ANichtGebucht + ADauer;
      end;

      case Stillst[I].StillGruppe of
        0:
          case Stillst[I].StillGepl of
            0: AAnlagenAusfall_Ungepl := AAnlagenAusfall_Ungepl + ADauer;
            1: AAnlagenAusfall_Gepl := AAnlagenAusfall_Gepl + ADauer;
          end;
        1:
          case Stillst[I].StillGepl of
            0: ARuesten_Ungepl := ARuesten_Ungepl + ADauer;
            1: ARuesten_Gepl := ARuesten_Gepl + ADauer;
          end;
        2:
          case Stillst[I].StillGepl of
            0: ALogistik_Ungepl := ALogistik_Ungepl + ADauer;
            1: ALogistik_Gepl := ALogistik_Gepl + ADauer;
          end;
        3:
          case Stillst[I].StillGepl of
            0: ANichtGebucht_Ungepl := ANichtGebucht_Ungepl + ADauer;
            1: ANichtGebucht_Gepl := ANichtGebucht_Gepl + ADauer;
          end;
      end;
    end;

    ASollLaufzeit := Round((AEnde - AStart) * 1440) - AGeplant;
    AIstLaufzeit := ASollLaufzeit - AUngeplant;

    if ASollLaufzeit = -1 then
      ASollLaufzeit := 0;
    if AIstLaufzeit = -1 then
      AIstLaufzeit := 0;

    Prod_Soll := 0;
    try
      if qDurchlauf.FieldByName('SOLLTAKT').AsFloat > 0 then
        Prod_Soll := Trunc(ASollLaufzeit * 60 / qDurchlauf.FieldByName('SOLLTAKT').AsFloat * qDurchlauf.FieldByName('KAVITAET').AsInteger);
    except
    end;

    S := 'Update TPM_AUSWERTUNG set'
      + S
      + ' PACKED = ' + IntToStr(Verpackt) + ','
      + ' Verpackt_Korr = ' + IntToStr(Verpackt_Korr) + ','
      + ' A_SOLLLAUFZEIT = ' + IntToStr(ASollLaufzeit) + ','
      + ' A_ISTLAUFZEIT = ' + IntToStr(AIstLaufzeit) + ','
      + ' A_GEPLANT = ' + IntToStr(AGeplant) + ','
      + ' A_UNGEPLANT = ' + IntToStr(AUngeplant) + ','
      + ' A_ANLAGENAUSFALL = ' + IntToStr(AAnlagenAusfall) + ','
      + ' A_RUESTEN = ' + IntToStr(ARuesten) + ','
      + ' A_LOGISTIK = ' + IntToStr(ALogistik) + ','
      + ' A_NICHTGEBUCHT = ' + IntToStr(ANichtGebucht) + ','
      + ' A_AnlagenAusfall_Ungepl = ' + IntToStr(AAnlagenAusfall_Ungepl) + ','
      + ' A_AnlagenAusfall_Gepl = ' + IntToStr(AAnlagenAusfall_Gepl) + ','
      + ' A_Ruesten_Ungepl = ' + IntToStr(ARuesten_Ungepl) + ','
      + ' A_Ruesten_Gepl = ' + IntToStr(ARuesten_Gepl) + ','
      + ' A_Logistik_Ungepl = ' + IntToStr(ALogistik_Ungepl) + ','
      + ' A_Logistik_Gepl = ' + IntToStr(ALogistik_Gepl) + ','
      + ' A_NichtGebucht_Ungepl = ' + IntToStr(ANichtGebucht_Ungepl) + ','
      + ' A_NichtGebucht_Gepl = ' + IntToStr(ANichtGebucht_Gepl) + ','
      + ' Produziert_Soll = ' + IntToStr(Prod_Soll)
      + ' where Nr = ' + IntToStr(Nr);
    SQL_Insert(qUpdate, S);

    if (AIstLaufzeit + AGeplant + AUngeplant < (BisDat - VonDat) * 1440) and (BANr <> '*') then
      BANr := '*'
    else
    begin
      BANr := '';
      qDurchlauf.Next;
    end;
  end;

  S := 'Select Min(Nr) N, DatumZeit, MaschNr, Count(*) CNT from TPM_Auswertung'
    + ' where AuftragNr = ''*'''
    + ' Group by DatumZeit, MaschNr having Count(*)>1';
  SQL_Get(qSuch, S);
  while not qSuch.EOF do
  begin
    S := 'delete from TPM_Auswertung where Nr = ' + qSuch.FieldByName('N').AsString;
    SQL_Insert(qUpdate, S);
    qSuch.Next;
  end;

  S := 'select * from TPM_Auswertung where AuftragNr = ''*''';
  SQL_Get(qSuch, S);
  while not qSuch.EOF do
  begin
    MaschNr := qSuch.FieldByName('MaschNr').AsString;
    SchichtDatum := qSuch.FieldByName('DatumZeit').AsFloat;

    S := 'select'
      + ' Sum(A_SOLLLAUFZEIT) A_SOLLLAUFZEIT,'
      + ' Sum(A_ISTLAUFZEIT) A_ISTLAUFZEIT,'
      + ' Sum(A_GEPLANT) A_GEPLANT,'
      + ' Sum(A_UNGEPLANT) A_UNGEPLANT,'
      + ' Sum(A_ANLAGENAUSFALL) A_ANLAGENAUSFALL,'
      + ' Sum(A_RUESTEN) A_RUESTEN,'
      + ' Sum(A_LOGISTIK) A_LOGISTIK,'
      + ' Sum(A_NICHTGEBUCHT) A_NICHTGEBUCHT,'
      + ' Sum(A_AnlagenAusfall_Ungepl) A_AnlagenAusfall_Ungepl,'
      + ' Sum(A_AnlagenAusfall_Gepl) A_AnlagenAusfall_Gepl,'
      + ' Sum(A_Ruesten_Ungepl) A_Ruesten_Ungepl,'
      + ' Sum(A_Ruesten_Gepl) A_Ruesten_Gepl,'
      + ' Sum(A_Logistik_Ungepl) A_Logistik_Ungepl,'
      + ' Sum(A_Logistik_Gepl) A_Logistik_Gepl,'
      + ' Sum(A_NichtGebucht_Ungepl) A_NichtGebucht_Ungepl,'
      + ' Sum(A_NichtGebucht_Gepl) A_NichtGebucht_Gepl'
      + ' from TPM_Auswertung'
      + ' where MaschNr = ' + MaschNr + ' and DatumZeit = ' + FloatToPunktString(SchichtDatum)
      + ' and (AuftragNr <> ''*'' or AuftragNr is Null)';
    SQL_Get(qSuch2, S);

    S := 'update TPM_Auswertung set'
      + ' A_SOLLLAUFZEIT = A_SOLLLAUFZEIT - ' + qSuch2.FieldByName('A_SOLLLAUFZEIT').AsString + ','
      + ' A_ISTLAUFZEIT = A_ISTLAUFZEIT - ' + qSuch2.FieldByName('A_ISTLAUFZEIT').AsString + ','
      + ' A_GEPLANT = A_GEPLANT - ' + qSuch2.FieldByName('A_GEPLANT').AsString + ','
      + ' A_UNGEPLANT = A_UNGEPLANT - ' + qSuch2.FieldByName('A_UNGEPLANT').AsString + ','
      + ' A_ANLAGENAUSFALL = A_ANLAGENAUSFALL - ' + qSuch2.FieldByName('A_ANLAGENAUSFALL').AsString + ','
      + ' A_RUESTEN = A_RUESTEN - ' + qSuch2.FieldByName('A_RUESTEN').AsString + ','
      + ' A_LOGISTIK = A_LOGISTIK - ' + qSuch2.FieldByName('A_LOGISTIK').AsString + ','
      + ' A_NICHTGEBUCHT = A_NICHTGEBUCHT - ' + qSuch2.FieldByName('A_NICHTGEBUCHT').AsString + ','
      + ' A_AnlagenAusfall_Ungepl = A_AnlagenAusfall_Ungepl - ' + qSuch2.FieldByName('A_AnlagenAusfall_Ungepl').AsString + ','
      + ' A_AnlagenAusfall_Gepl = A_AnlagenAusfall_Gepl - ' + qSuch2.FieldByName('A_AnlagenAusfall_Gepl').AsString + ','
      + ' A_Ruesten_Ungepl = A_Ruesten_Ungepl - ' + qSuch2.FieldByName('A_Ruesten_Ungepl').AsString + ','
      + ' A_Ruesten_Gepl = A_Ruesten_Gepl - ' + qSuch2.FieldByName('A_Ruesten_Gepl').AsString + ','
      + ' A_Logistik_Ungepl = A_Logistik_Ungepl - ' + qSuch2.FieldByName('A_Logistik_Ungepl').AsString + ','
      + ' A_Logistik_Gepl = A_Logistik_Gepl - ' + qSuch2.FieldByName('A_Logistik_Gepl').AsString + ','
      + ' A_NichtGebucht_Ungepl = A_NichtGebucht_Ungepl - ' + qSuch2.FieldByName('A_NichtGebucht_Ungepl').AsString + ','
      + ' A_NichtGebucht_Gepl = A_NichtGebucht_Gepl - ' + qSuch2.FieldByName('A_NichtGebucht_Gepl').AsString
      + ' where Nr = ' + qSuch.FieldByName('Nr').AsString;
    SQL_Insert(qUpdate, S);

    S := 'update TPM_Auswertung set'
      + ' AuftragNr = null,'
      + ' Kav_Soll = 0,'
      + ' Kav_Ist = 0,'
      + ' Produzierte_Menge = 0,'
      + ' PACKED = 0,'
      + ' Ausschuss = 0,'
      + ' GutTeile = 0,'
      + ' TaktZeit_Soll = 0,'
      + ' Taktzeit_Mittel_Ist = 0,'
      + ' Zyklen = 0'
      + ' where Nr = ' + qSuch.FieldByName('Nr').AsString;
    SQL_Insert(qUpdate, S);

    qSuch.Next;
  end;




  SchreibeMeldung('Recalculation end: TPM-Statistic', LogFile_Mode);
end;
// *****************************************************************************
procedure TThread_Schicht.TPM_AuswertungKorrektur;
var s : String;
begin
  S := 'Select Maschinendaten_Ohne_Auftrag from Setup';
  SQL_Get(qSuch, S);
  if qSuch.FieldByName('Maschinendaten_Ohne_Auftrag').AsInteger =0 then
  begin
    S := 'update TPM_Auswertung set'
      + ' Kav_Soll = 0,'
      + ' Kav_Ist = 0,'
      + ' Produzierte_Menge = 0,'
      + ' Ausschuss = 0,'
      + ' GutTeile = 0,'
      + ' TaktZeit_Soll = 0,'
      + ' Taktzeit_Mittel_Ist = 0'
      + ' where AuftragNr is null and'
      + ' (Kav_Soll<>0 or Kav_Ist<>0 or Produzierte_Menge<>0 or Ausschuss<>0 or GutTeile<>0 or TaktZeit_Soll<>0 or Taktzeit_Mittel_Ist<>0)';
    SQL_Insert(qUpdate, S);
  end;

  S := 'update TPM_Auswertung set A_IstlaufZeit = 0 where A_IstlaufZeit < 0';
  SQL_Insert(qUpdate, S);
  S := 'update TPM_Auswertung set A_Ungeplant = 0 where A_Ungeplant < 0';
  SQL_Insert(qUpdate, S);
  S := 'update TPM_Auswertung set A_Geplant = 0 where A_Geplant < 0';
  SQL_Insert(qUpdate, S);
  S := 'delete from TPM_Auswertung where A_Ungeplant+A_Geplant+A_Istlaufzeit = 0 and AuftragNr is Null';
  SQL_Insert(qUpdate, S);

  S := 'delete from TPM_Auswertung where Nr in'
    + ' (select Max(Nr) from TPM_Auswertung'
    + ' group by MaschNr, Datum, Schicht, AuftragNr'
    + ' having Count(*) > 1)';
  SQL_Insert(qUpdate, S);
  SchreibeMeldung('Recalculation correct: TPM-Statistic', LogFile_Mode);
end;

procedure TThread_Schicht.TPM_Leistung_Gesamt_Update;
var
  Nr: Integer;
  OEE_Leistung_Schicht: Real;
begin
  //*******************************************************************
  OEE_Leistung_Schicht := 0;

  SQLStr := 'select * from tpm_schicht where leistung_schicht is NULL';
  SQL_Get(qSuch, SQLStr);
  qSuch.First;
  while not qSuch.EOF do
  begin
    Nr := qSuch.FieldByName('Nr').AsInteger;
    SQLStr := 'select sum(Leistung) as CNT from TPM_Schicht where '
      + ' Schicht = ''' + qSuch.FieldByName('Schicht').AsString + ''''
      + ' AND Datum = ''' + DateToStrSQL(StrToDate(qSuch.FieldByName('Datum').AsString)) + ''''
      + ' AND MaschNr = ''' + qSuch.FieldByName('MaschNr').AsString + ''''
      + ' Group by Schicht, Datum, MAschnr ';
    SQL_Get(qUpdate, SQLStr);
    try
      OEE_Leistung_Schicht := qUpdate.FieldByName('CNT').AsFloat;
    except
      SchreibeMeldung('18DDB3B5-F268-437E-BD3C-9F7C29D4108F, NR=' + IntToStr(Nr), 0);
      Exit;
    end;
    UpdateSQL(qUpdate, 'TPM_Schicht', 'LEISTUNG_SCHICHT',
      FloatToStrF2(OEE_Leistung_Schicht, ffFixed, 10, 2), 'Nr', IntToStr(Nr));
    qSuch.Next;
  end;

  SQLStr := 'update tpm_schicht set leistung_schicht = 200 where leistung_schicht > 200';
  SQL_Insert(qUpdate, SQLStr);
end;
// *****************************************************************************

procedure TThread_Schicht.TPM_Produziert_Gesamt_Update;
begin
  SQLStr := 'select maschnr,datum,schicht,count(*) CNT from tpm_schicht'
    + ' where Datumzeit > ' + IntToStr(Trunc(N_o_w - 10))
    + ' group by Datum,schicht,maschnr'
    + ' having count(*) > 1';
  SQL_Get(qSuch, SQLStr);
  qSuch.First;
  while not qSuch.EOF do
  begin
    SQLStr := 'delete from TPM_Schicht where BetriebsauftragNr is null'
      + ' AND Schicht = ''' + qSuch.FieldByName('Schicht').AsString + ''''
      + ' AND Datum = ''' + DateToStrSQL(StrToDate(qSuch.FieldByName('Datum').AsString)) + ''''
      + ' AND MaschNr = ''' + qSuch.FieldByName('MaschNr').AsString + '''';
    SQL_Insert(qUpdate, SQLStr);
    qSuch.Next;
  end;
end;
// *****************************************************************************

procedure TThread_Schicht.TPM_Korrektur(Von, Bis: Real; Berechnen_TPM_Auswertung: Boolean; MNrs: string);
var
  Nr, MaschNr: Integer;
  Anlage, Ruest, Logistik, nichtgeb: Integer;
  Geplant, Ungeplant: Integer;
  Stops, Solllaufzeit, IstLaufZeit: Integer;
  Werkskalender: Integer;
  IfChanged: Boolean;
  Zyklen, OEE_Nutzung, OEE_Leistung, OEE_Qualitaet, OEE_Effektivitaet: Real;
  Solltakt: Real;
  Kavitaet: Integer;
  Produziert: Integer;
  Ausschuss: Integer;
  Verpackt : Integer;
  varkav : Integer;
  VonDat, BisDat: Real;
  Dat: Real;
  MaschAktiv: Boolean;
  AuftragNr: string;
  s, SqlStr2 : string;
  stage, turn : Integer;
  kdnr : string;
begin
  try
    try
      s := 'SELECT kundennummer FROM setup';
      SQL_Get(qSuch, s);
      if not qSuch.IsEmpty then
      begin
        kdnr := qSuch.FieldByName('kundennummer').AsString;
      end;
    except
    end;


  if not Recalculate_Mode then
  begin
    stage := -4;
    SqlStr2 := 'update tpm_stillog set geht = 0 where geht is null';
    SQL_Insert(qUpdate, SqlStr2);
    SchreibeMeldung('Step 1', LogFile_Mode);
    stage := -3;

    TPM_Stillog_Korrektur(TCO_Setup.GetParamInt(qUpdate, 'INCL_Stillog_Arc_Tag'), 30);
    stage := -2;
    TPM_Schicht_Pruefen(TCO_Setup.GetParamInt(qUpdate, 'INCL_TPM_Schicht_Pruefen_Tag'));
    stage := -1;
    SchreibeMeldung('Step 2', LogFile_Mode);
  end;
  if (MNrs = '') or (MNrs = ' ') or (MNrs = '0') then
    s := ''
  else
    s := GetSelectedMaschinen(qSuch, 'and', 'MaschNr', MNrs, 0);
  SqlStr2 := 'select * from tpm_schicht where'
    + ' DatumZeit between (' + FloatToPunktString(Von) + ') and (' + FloatToPunktString(Bis) + ')'
    + s
    + ' order by Nr';

//  SchreibeMeldung('Step 2a', LogFile_Mode);
  qSuch.SQL.Text := SqlStr2;
  qSuch.Open;

//  SQL_Get(qSuch, SqlStr2);
//  qSuch.First;
  turn := 1;
  while not qSuch.EOF do
  begin
    stage := 0;
    Th_Meldung.ServerStatusOK;

    Nr := qSuch.FieldByName('Nr').AsInteger;
    MaschNr := qSuch.FieldByName('MaschNr').AsInteger;
    AuftragNr := qSuch.FieldByName('BETRIEBSAUFTRAGNR').AsString;
    stage := 1;

    MaschAktiv := True;
    if SQLGet(qUpdate, 'Maschine', 'Datenblock', qSuch.FieldByName('MaschNr').AsString, True) > 0 then
      if qUpdate.FieldByName('MaschAktiv').AsInteger = 0 then
        MaschAktiv := False;

      stage := 2;
        Dat := qSuch.FieldByName('Datum').AsDateTime;
    Werkskalender := TTT_GetArbeitszeit_Schicht(qSuch4, MaschNr, Dat, qSuch.FieldByName('Schicht').AsInteger);
    SchichtDauer := GetSchichtDauer(qSuch.FieldByName('Schicht').AsInteger);
    if (Werkskalender < 0) or (Werkskalender > SchichtDauer) then
      Werkskalender := SchichtDauer;
    stage := 3;

    case qSuch.FieldByName('Schicht').AsInteger of
      1:
        begin
          VonDat := Trunc(qSuch.FieldByName('DatumZeit').AsFloat) + Frac(Schicht1);
          BisDat := Trunc(qSuch.FieldByName('DatumZeit').AsFloat) + Frac(Schicht2);
        end;
      2:
        begin
          if Shift_Model <> 2 then
          begin
            VonDat := Trunc(qSuch.FieldByName('DatumZeit').AsFloat) + Frac(Schicht2);
            BisDat := Trunc(qSuch.FieldByName('DatumZeit').AsFloat) + Frac(Schicht3);
          end
          else
          begin
            VonDat := qSuch.FieldByName('DatumZeit').AsFloat;
            BisDat := VonDat + 1 / 2;
          end;
        end;
      3:
        begin
          VonDat := Trunc(qSuch.FieldByName('DatumZeit').AsFloat) + Frac(Schicht3);
          BisDat := Trunc(qSuch.FieldByName('DatumZeit').AsFloat + 1) + Frac(Schicht1);
        end;
    else
      begin
        VonDat := 0;
        BisDat := 0;
      end;
    end;
    stage := 4;

    ThTPM.VonDatum := VonDat;
    ThTPM.BisDatum := BisDat;
    ThTPM.Zeitraum := 0;
    ThTPM.Schicht := qSuch.FieldByName('Schicht').AsInteger;
    ThTPM.SchichtMinuten := GetSchichtDauer(ThTPM.Schicht);
    ThTPM.MaschNr := qSuch.FieldByName('MaschNr').AsInteger;
    ThTPM.AlleMaschinen := False;
stage := 5;

    if ThTPM.Calculate(True) = 1 then
    begin
      Geplant := ThTPM.Geplant;
      Ungeplant := ThTPM.Ungeplant;
      Solllaufzeit := ThTPM.Solllaufzeit;
      IstLaufZeit := ThTPM.IstLaufZeit;

      Anlage := ThTPM.Anlagenausfall;
      Ruest := ThTPM.Ruesten;
      Logistik := ThTPM.Logistik;
      nichtgeb := ThTPM.NichtGebucht;
      Stops := ThTPM.Stops;
      stage := 6;
    end
    else
    begin
      Geplant := qSuch.FieldByName('geplant').AsInteger;
      Ungeplant := qSuch.FieldByName('ungeplant').AsInteger;

      Solllaufzeit := qSuch.FieldByName('Solllaufzeit').AsInteger;
      IstLaufZeit := qSuch.FieldByName('Istlaufzeit').AsInteger;

      Anlage := qSuch.FieldByName('anlagenausfall').AsInteger;
      Ruest := qSuch.FieldByName('ruesten').AsInteger;
      Logistik := qSuch.FieldByName('logistik').AsInteger;
      nichtgeb := qSuch.FieldByName('nichtgebucht').AsInteger;
      Stops := qSuch.FieldByName('Stops').AsInteger;
      stage := 7;
    end;

    Solltakt := qSuch.FieldByName('SOLLTAKT').AsFloat;
    Kavitaet := qSuch.FieldByName('KAVITAET').AsInteger;
    varkav := qSuch.FieldByName('var_kavitaet').AsInteger;

    if Kavitaet = 0 then
      Kavitaet := 1;
    Produziert := qSuch.FieldByName('PRODUZIERT').AsInteger;

    if Kavitaet_laufender_Auftrag3 then
      Zyklen := qSuch.FieldByName('Zyklen').AsInteger
    else
    begin
      Zyklen :=  Produziert / Kavitaet;
      if varkav > 1 then
        Zyklen := Zyklen * varkav;
    end;

    Ausschuss := qSuch.FieldByName('Ausschuss').AsInteger;

    Verpackt := Produziert - Ausschuss; // NUr für Kienle

    stage := 8;

    if Solllaufzeit > Werkskalender then
      Solllaufzeit := Werkskalender;
    if IstLaufZeit > Solllaufzeit then
      Solllaufzeit := IstLaufZeit;

    try
      s := ' UPDATE tpm_schicht SET '
        + ' Geplant =' + IntToStr(Geplant) + ', '
        + ' UnGeplant = ' + IntToStr(Ungeplant) + ', '
        + ' Stops = ' + IntToStr(Stops) + ', '
        + ' Solllaufzeit = ' + IntToStr(Solllaufzeit) + ', '
        + ' Istlaufzeit = ' + IntToStr(IstLaufZeit) + ', '
        + ' anlagenausfall = ' + IntToStr(Anlage) + ', '
        + ' ruesten = ' + IntToStr(Ruest) + ', '
        + ' logistik = ' + IntToStr(Logistik) + ', ' ;
      if kdnr = '80057' then // kienle
        s := s + ' verpackt = ' + IntToStr(Verpackt) + ', ';
      s := s + ' nichtgebucht = ' + IntToStr(nichtgeb)
        + ' WHERE nr = ' + IntToStr(Nr);
      SQL_Insert(qUpdate, s);
    except on e2:Exception do
      SchreibeMeldung('Exception (Stage '+IntToStr(stage)+', Turn '+IntToStr(turn)+' - ' +s+ ') : '+  e2.Message, LogFile_Mode);
    end;
    stage := 9;

    (*
    UpdateSQL(qUpdate, 'TPM_Schicht', 'Geplant', IntToStr(Geplant), 'Nr', IntToStr(Nr));
    UpdateSQL(qUpdate, 'TPM_Schicht', 'UnGeplant', IntToStr(Ungeplant), 'Nr', IntToStr(Nr));
    UpdateSQL(qUpdate, 'TPM_Schicht', 'Stops', IntToStr(Stops), 'Nr', IntToStr(Nr));

    UpdateSQL(qUpdate, 'TPM_Schicht', 'Solllaufzeit', IntToStr(Solllaufzeit), 'Nr', IntToStr(Nr));
    UpdateSQL(qUpdate, 'TPM_Schicht', 'Istlaufzeit', IntToStr(IstLaufZeit), 'Nr', IntToStr(Nr));
    UpdateSQL(qUpdate, 'TPM_Schicht', 'Stops', IntToStr(Stops), 'Nr', IntToStr(Nr));

    UpdateSQL(qUpdate, 'TPM_Schicht', 'anlagenausfall', IntToStr(Anlage), 'Nr', IntToStr(Nr));
    UpdateSQL(qUpdate, 'TPM_Schicht', 'ruesten', IntToStr(Ruest), 'Nr', IntToStr(Nr));
    UpdateSQL(qUpdate, 'TPM_Schicht', 'logistik', IntToStr(Logistik), 'Nr', IntToStr(Nr));
    UpdateSQL(qUpdate, 'TPM_Schicht', 'nichtgebucht', IntToStr(nichtgeb), 'Nr', IntToStr(Nr));
    UpdateSQL(qUpdate, 'TPM_Schicht', 'Stops', IntToStr(Stops), 'Nr', IntToStr(Nr));
    *)
    //*****************************************************************
    //***** Neuberechnung von Nutzung, Leistung, Qualität...
    //*****************************************************************

    IfChanged := True;
    if IfChanged then
    begin
      stage := 10;

      if Solllaufzeit <> 0 then
        OEE_Nutzung := (IstLaufZeit / Solllaufzeit) * 100
      else
        OEE_Nutzung := (IstLaufZeit / 1) * 100;

      //RS 16.06.2015: Kavitätswechsel wird  sauber berücksichtigt, indem über tpm_schicht.Zyklen ermittelt wird
      if IstLaufZeit <> 0 then
        OEE_Leistung := (Solltakt * Zyklen / (IstLaufZeit * 60)) * 100
      else
        OEE_Leistung := (Solltakt * Zyklen / 60 ) * 100;

      if Produziert > 0 then
        OEE_Qualitaet := (Produziert - Ausschuss) / Produziert * 100
      else
        OEE_Qualitaet := 100;

      if OEE_Nutzung > Max_Nutzung then
        OEE_Nutzung := Max_Nutzung;
      if OEE_Leistung > Max_Leistung then
        OEE_Leistung := Max_Leistung;
      if OEE_Nutzung < 0 then
        OEE_Nutzung := 0;
      if OEE_Leistung < 0 then
        OEE_Leistung := 0;
      if OEE_Qualitaet < 0 then
        OEE_Qualitaet := 0;

      if OEE_Nutzung < 1 then
      begin
        OEE_Leistung := 0;
        OEE_Qualitaet := 0;
      end;

      OEE_Effektivitaet := OEE_Nutzung * OEE_Leistung * OEE_Qualitaet / 10000;
      qUpdate.SQL.Text := 'UPDATE tpm_schicht SET '
        + ' NUTZUNG = ' + FloatToPunktString(OEE_Nutzung) + ', '
        + ' LEISTUNG = ' + FloatToPunktString(OEE_Leistung) + ', '
        + ' QUALITAET = ' + FloatToPunktString(OEE_Qualitaet) + ', '
        + ' EFFEKTIVITAET = ' + FloatToPunktString(OEE_Effektivitaet) + ', '
        + ' Stops = ' + IntToStr(Stops)
        + ' WHERE nr = ' + IntToStr(Nr);
      qUpdate.ExecSQL;
      stage := 11;

      (*
      UpdateSQL(qUpdate, 'TPM_Schicht', 'NUTZUNG', FloatToStrF2(OEE_Nutzung, ffFixed, 10, 2), 'Nr', IntToStr(Nr));
      UpdateSQL(qUpdate, 'TPM_Schicht', 'LEISTUNG', FloatToStrF2(OEE_Leistung, ffFixed, 10, 2), 'Nr',
        IntToStr(Nr));
      UpdateSQL(qUpdate, 'TPM_Schicht', 'QUALITAET', FloatToStrF2(OEE_Qualitaet, ffFixed, 10, 2), 'Nr',
        IntToStr(Nr));
      UpdateSQL(qUpdate, 'TPM_Schicht', 'EFFEKTIVITAET', FloatToStrF2(OEE_Effektivitaet, ffFixed, 10, 2), 'Nr',
        IntToStr(Nr));
      UpdateSQL(qUpdate, 'TPM_Schicht', 'Stops', IntToStr(Stops), 'Nr', IntToStr(Nr));
      *)
    end;

    //*****************************************************************
    //***** Update von Produzierten Artikeln
    //*****************************************************************
    if (IstLaufZeit = 0) and (Produziert > 0) then
    begin
      // if loesch then
      //  UpdateSQL( qUpdate, 'TPM_Schicht', 'Produziert', '0', 'Nr', IntToStr(Nr));
      if not Metall then
        SchreibeMeldung('Shift log : produced > 0 / runtime = 0. MachNo = '
          + IntToStr(MaschNr) + '  No: ' + IntToStr(Nr), LogFile_Mode);
      stage := 12;
    end;

    if (Produziert = 0) then
    begin
      qUpdate.SQL.Text := 'UPDATE tpm_schicht SET'
        + ' LEISTUNG = 0, '
        + ' QUALITAET = 0, '
        + ' EFFEKTIVITAET = 0 '
        + ' WHERE nr = ' + IntToStr(Nr);
      qUpdate.ExecSQL;
      (*
      UpdateSQL(qUpdate, 'TPM_Schicht', 'LEISTUNG', '0', 'Nr', IntToStr(Nr));
      UpdateSQL(qUpdate, 'TPM_Schicht', 'QUALITAET', '0', 'Nr', IntToStr(Nr));
      UpdateSQL(qUpdate, 'TPM_Schicht', 'EFFEKTIVITAET', '0', 'Nr', IntToStr(Nr));
      *)
    end;

    stage := 13;
    if not MaschAktiv then
    begin
      UpdateSQL(qUpdate, 'TPM_Schicht', 'Geplant', '0', 'Nr', IntToStr(Nr));
      UpdateSQL(qUpdate, 'TPM_Schicht', 'UnGeplant', '0', 'Nr', IntToStr(Nr));
      UpdateSQL(qUpdate, 'TPM_Schicht', 'Solllaufzeit', '0', 'Nr', IntToStr(Nr));
      UpdateSQL(qUpdate, 'TPM_Schicht', 'Istlaufzeit', '0', 'Nr', IntToStr(Nr));
      UpdateSQL(qUpdate, 'TPM_Schicht', 'anlagenausfall', '0', 'Nr', IntToStr(Nr));
      UpdateSQL(qUpdate, 'TPM_Schicht', 'ruesten', '0', 'Nr', IntToStr(Nr));
      UpdateSQL(qUpdate, 'TPM_Schicht', 'logistik', '0', 'Nr', IntToStr(Nr));
      UpdateSQL(qUpdate, 'TPM_Schicht', 'nichtgebucht', '0', 'Nr', IntToStr(Nr));
      UpdateSQL(qUpdate, 'TPM_Schicht', 'NUTZUNG', '0', 'Nr', IntToStr(Nr));
      UpdateSQL(qUpdate, 'TPM_Schicht', 'LEISTUNG', '0', 'Nr', IntToStr(Nr));
      UpdateSQL(qUpdate, 'TPM_Schicht', 'QUALITAET', '0', 'Nr', IntToStr(Nr));
      UpdateSQL(qUpdate, 'TPM_Schicht', 'EFFEKTIVITAET', '0', 'Nr', IntToStr(Nr));
      UpdateSQL(qUpdate, 'TPM_Schicht', 'Produziert', '0', 'Nr', IntToStr(Nr));
      UpdateSQL(qUpdate, 'TPM_Schicht', 'Stops', '0', 'Nr', IntToStr(Nr));
    end;

    if Extrusion then
      Berechne_Extrusion(Nr, AuftragNr, VonDat, BisDat);

    qSuch.Next;
    turn := turn + 1;
  end;

  if not Recalculate_Mode then
    SchreibeMeldung('Step 3', LogFile_Mode);
(*
  SqlStr2 := 'update tpm_schicht set Maschinennutzung = 0 where Solllaufzeit + Geplant = 0'
    + ' and DatumZeit between (' + FloatToPunktString(Von) + ') and (' + FloatToPunktString(Bis) + ')';
  SQL_Insert(qSuch, SqlStr2);

  SqlStr2 := 'update tpm_schicht set Maschinennutzung = ((Istlaufzeit / (Solllaufzeit + Geplant))*100)'
    + ' where (Solllaufzeit + Geplant) > 0'
    + ' and DatumZeit between (' + FloatToPunktString(Von) + ') and (' + FloatToPunktString(Bis) + ')';
  SQL_Insert(qSuch, SqlStr2);

  SqlStr2 := 'update tpm_schicht set Maschinennutzung = 0 where Maschinennutzung < 0';
  SQL_Insert(qSuch, SqlStr2);

  SQLStr := 'update tpm_schicht set Maschinennutzung = 100 where Maschinennutzung > 100';
  SQL_Insert(qSuch, SQLStr);

  //Nachkorrektur
  SqlStr2 := 'update tpm_schicht set anlagenausfall = 0 where '
    + '((anlagenausfall+ruesten+logistik+nichtgebucht) <> (geplant+ungeplant))'
    + ' and (anlagenausfall = 1)'
    + ' and DatumZeit between (' + FloatToPunktString(Von) + ') and (' + FloatToPunktString(Bis) + ')';
  SQL_Insert(qSuch, SqlStr2);

  SqlStr2 := 'update tpm_schicht set ruesten = 0 where '
    + '((anlagenausfall+ruesten+logistik+nichtgebucht) <> (geplant+ungeplant))'
    + ' and (ruesten = 1)'
    + ' and DatumZeit between (' + FloatToPunktString(Von) + ') and (' + FloatToPunktString(Bis) + ')';
   SQL_Insert(qSuch, SqlStr2);

  SqlStr2 := 'update tpm_schicht set logistik = 0 where '
    + '((anlagenausfall+ruesten+logistik+nichtgebucht) <> (geplant+ungeplant))'
    + ' and (logistik = 1)'
    + ' and DatumZeit between (' + FloatToPunktString(Von) + ') and (' + FloatToPunktString(Bis) + ')';
   SQL_Insert(qSuch, SqlStr2);

  SqlStr2 := 'update tpm_schicht set nichtgebucht = 0 where '
    + '((anlagenausfall+ruesten+logistik+nichtgebucht) <> (geplant+ungeplant))'
    + ' and (nichtgebucht = 1)'
    + ' and DatumZeit between (' + FloatToPunktString(Von) + ') and (' + FloatToPunktString(Bis) + ')';
  SQL_Insert(qSuch, SqlStr2);

  SqlStr2 := 'update tpm_schicht set stops = 0 where nutzung = 0 and stops = 1'
    + ' and DatumZeit between (' + FloatToPunktString(Von) + ') and (' + FloatToPunktString(Bis) + ')';
  SQL_Insert(qSuch, SqlStr2);

  SqlStr2 := 'update tpm_schicht set Leistung = 0 where BetriebsauftragNr is NULL'
    + ' and DatumZeit between (' + FloatToPunktString(Von) + ') and (' + FloatToPunktString(Bis) + ')';
  SQL_Insert(qSuch, SqlStr2);
  *)
(*  Aufträge gibt es so seit 2004 nicht mehr. Funktion wird entfernt ML 25.05.2020
  // Bock
  SqlStr2 := 'update tpm_schicht set frei_int_1 = istlaufzeit where Betriebsauftragnr like ''06%'''
    + ' and DatumZeit between (' + FloatToPunktString(Von) + ') and (' + FloatToPunktString(Bis) + ')';
  SQL_Insert(qSuch, SqlStr2);

  SqlStr2 := 'update tpm_schicht set frei_int_2 = istlaufzeit where Betriebsauftragnr like ''07%'''
    + ' and DatumZeit between (' + FloatToPunktString(Von) + ') and (' + FloatToPunktString(Bis) + ')';
  SQL_Insert(qSuch, SqlStr2);

  SqlStr2 := 'update tpm_schicht set frei_int_3 = istlaufzeit where Betriebsauftragnr like ''08%'''
    + ' and DatumZeit between (' + FloatToPunktString(Von) + ') and (' + FloatToPunktString(Bis) + ')';
  SQL_Insert(qSuch, SqlStr2);
  // Bock
  *)
  if not Recalculate_Mode then
  begin
    SchreibeMeldung('Step 4', LogFile_Mode);
    try
    // Funktion wird nicht mehr verwendet. Schicht Leistung wird anders ermittelt.
//      TPM_Leistung_Gesamt_Update;
    except
      SchreibeMeldung('320DE5D8-63D8-40B6-A777-565EE9440196', LogFile_Mode);
    end;
    if not Recalculate_Mode then
      SchreibeMeldung('Step 5', LogFile_Mode);

    try
      TPM_Produziert_Gesamt_Update;
    except
      SchreibeMeldung('00F0550D-327A-47D3-AD4D-86773DBFFD53', LogFile_Mode);
    end;
    if not Recalculate_Mode then
      SchreibeMeldung('Step 6', LogFile_Mode);

    if Packen then
      if TCO_Setup.GetParamBool(qSuch, 'INCL_TPM_Schicht_Verpackt_Ausschuss') then
      try
        Berechne_TPM_Schicht_Verpackt_Ausschuss(TCO_Setup.GetParamInt(qSuch, 'INCL_TPM_Verpackt_Ausschuss'), '');
      except
        SchreibeMeldung('DFE59B75-C048-42AC-9F0F-255260958682', LogFile_Mode);
      end;
    SchreibeMeldung('Step 7', LogFile_Mode);

    if Menge_Schicht_Berechnen then
    try
      Nachbuchen_aus_AArchiv(TCO_Setup.GetParamInt(qSuch, 'INCL_TPM_Verpackt_Ausschuss'), '');
    except
      SchreibeMeldung('BCC0890F-0BEF-4F75-96C0-BAAC3D55F382', LogFile_Mode);
    end;

    SchreibeMeldung('Step 8', LogFile_Mode);
  end;

  if TPM_Auswertung and Berechnen_TPM_Auswertung then
  begin
    try
      if not TCO_Setup.GetParamBool(qSuch, 'INCL_TpmAuswertFromCoreSvc') then
      begin
        Berechne_TPM_Auswertung(Von, Bis, MNRs);
      end;
    except
      SchreibeMeldung('83E17ACB-6CBF-452A-95CC-9634AA2D78AF', LogFile_Mode);
    end;
    SchreibeMeldung('Step 9', LogFile_Mode);

    try
      Berechne_TPM_Produktionsdetail(TCO_Setup.GetParamInt(qSuch, 'INCL_Berech_TPM_Produktion'), '');
    except
      SchreibeMeldung('730E89BB-29EC-43D9-B4B7-45787B6D68E7', LogFile_Mode);
    end;
    SchreibeMeldung('Step 10', LogFile_Mode);

    try
      Berechne_TPM_Auftragsdetail(TCO_Setup.GetParamInt(qSuch, 'INCL_Berech_TPM_Produktion'), '');
    except
      SchreibeMeldung('61E5E254-5CB1-4F72-B104-E28A93728BCB', LogFile_Mode);
    end;
    SchreibeMeldung('Step 11', LogFile_Mode);

    try
      Berechne_A_Daten(Von, Bis, '');
    except
      SchreibeMeldung('5B8FEC08-F5DC-43C9-B67F-E58F867FB820', LogFile_Mode);
    end;
    SchreibeMeldung('Step 12', LogFile_Mode);
  end;
  except on e : Exception do
    begin
      SchreibeMeldung('Exception (TPM_Korrektur: Stage '+IntToStr(stage)+', Turn '+IntToStr(turn)+' - ''' +SQLStr2+ ''') : '+  e.Message, LogFile_Mode);
      raise e;
    end;
  end;
end;

function TThread_Schicht.GetArtikelNr(AuftragNr: string): string;
var
  Tmp: Integer;
begin
  Tmp := SQLGet(qSuch3, 'AARCHIV', 'BETRIEBSAUFTRAGNR', AuftragNr, True);
  if Tmp > 0 then
    Result := qSuch3.FieldByName('AUFTRAGNR').AsString
  else
    Result := '';
end;

procedure TThread_Schicht.SetNachBerechnung(const Value: Boolean);
begin
  FNachBerechnung := Value;
end;

procedure TThread_Schicht.Berechne_TPM_Schicht_Verpackt_Ausschuss(Days: Integer; MNrs: string);
var
  S: string;
  D: Real;
  Nr: Integer;
begin
  D := Trunc(N_o_w - Days) + Schicht1 - 1 / 1440;
  S := 'update TPM_Schicht set Verpackt = 0 where DatumZeit >= ''' + FloatToStr2(D) + ''''
    + GetSelectedMaschinen(qUpdate, 'and', 'MaschNr', MNrs, 0);
  SQL_Insert(qUpdate, S);

  S := 'select BetriebsAuftragNr, datum, Zugang - Abgang P from VerpacktProt'
    + ' where datum >= ' + FloatToPunktString(D) + ' and BetriebsAuftragNr is not null'
    + GetSelectedMaschinen(qUpdate, 'and', 'Maschine', MNrs, 1)
    + ' order by Nr';
  SQL_Get(qSuch, S);
  while not qSuch.EOF do
  begin
    S := 'select * from TPM_Schicht where Datumzeit < ' + FloatToPunktString(qSuch.FieldByName('datum').AsFloat)
      + ' and BetriebsAuftragNr = ''' + qSuch.FieldByName('BetriebsAuftragNr').AsString + ''' order by Datumzeit Desc';
    SQL_Get(qSuch2, S);
    if not qSuch2.EOF then
    begin
      S := 'select * from TPM_Schicht where Datumzeit < ' + FloatToPunktString(qSuch.FieldByName('datum').AsFloat)
        + ' and BetriebsAuftragNr = ''' + qSuch.FieldByName('BetriebsAuftragNr').AsString + ''' order by Datumzeit Desc';
      SQL_Get(qSuch2, S);
      if not qSuch2.EOF then
      begin
        try
          Nr := qSuch2.FieldByName('Nr').AsInteger;
        except
          Nr := 0;
        end;
        if Nr > 0 then
        begin
          S := 'update TPM_Schicht set Verpackt = Verpackt + (' + qSuch.FieldByName('P').AsString + ')'
            + ' where Nr = ' + IntToStr(Nr);
          SQL_Insert(qUpdate, S);
          S := 'update TPM_Schicht set Verpackt_Org = Verpackt + (' + qSuch.FieldByName('P').AsString + ')'
            + ' where Nr = ' + IntToStr(Nr);
          SQL_Insert(qUpdate, S);
        end;
      end;
    end;
    qSuch.Next;

  end;
  S := 'update TPM_Schicht set Ausschuss = Produziert - Verpackt where DatumZeit >= ' + FloatToPunktString(D);
  SQL_Insert(qUpdate, S);

  S := 'update AArchiv set Ausschuss = ProduziertInt - VerpacktInt'
    + ' where EndDatumZeit = 0 or EndDatumZeit >= ' + FloatToPunktString(D);
  SQL_Insert(qUpdate, S);
end;

procedure TThread_Schicht.Nachbuchen_aus_AArchiv(Days: Integer; MNrs: string);
var
  Nr, BANr, S: string;
  D: Real;
  Prod, Prod2: Integer;
begin
  D := Trunc(N_o_w - Days) + Schicht1 - 1 / 1440;
  S := 'select * from AARchiv where EndDatumZeit > ' + FloatToPunktString(D)
    + GetSelectedMaschinen(qSuch, 'and', 'Maschine', MNrs, 1);
  SQL_Get(qSuch, S);
  while not qSuch.EOF do
  begin
    BANr := qSuch.FieldByName('BetriebsAuftragNr').AsString;
    S := 'select Count(*) CNT from PDE where BetriebsAuftragNr = ''' + BANr + '''';
    SQL_Get(qSuch2, S);
    if qSuch2.FieldByName('CNT').AsInteger = 0 then
    begin
      Prod := qSuch.FieldByName('ProduziertInt').AsInteger;
      S := 'select Sum(Produziert) P from TPM_Schicht where betriebsAuftragNr = ''' + BANr + '''';
      SQL_Get(qSuch2, S);
      Prod2 := qSuch2.FieldByName('P').AsInteger;
      if Prod <> Prod2 then
      begin
        S := 'select * from TPM_Schicht where BetriebsAuftragNr = ''' + BANr + ''' order by DatumZeit Desc';
        SQL_Get(qSuch2, S);
        if not qSuch2.EOF then
        begin
          Nr := qSuch2.FieldByName('Nr').AsString;
          S := 'update TPM_Schicht set Produziert = Produziert + (' + IntToStr(Prod - Prod2) + ') where Nr = ' + Nr;
          SQL_Insert(qUpdate, S);
          S := 'update TPM_Schicht set Produziert_ORG = Produziert where Nr = ' + Nr;
          SQL_Insert(qUpdate, S);
        end;
      end;
    end;

    S := 'select Sum(Zugang-Abgang) CNT from VerpacktProt where BetriebsAuftragNr = ''' + BANr + '''';
    SQL_Get(qSuch2, S);
    try
      Prod := qSuch2.FieldByName('CNT').AsInteger;
    except
      Prod := 0;
    end;
    S := 'update AARchiv set VerpacktInt = ' + IntToStr(Prod) + ' where Nr = ' + qSuch.FieldByName('Nr').AsString;
    SQL_Insert(qUpdate, S);

    S := 'update maschinf set pack= ' + IntToStr(Prod) + ' where betriebsauftragnr=''' + BANr + '''';
    SQL_Insert(qUpdate, S);
    qSuch.Next;
  end;
end;

function TThread_Schicht.Recalculation: Integer;
var
  MaschListe, MNr, Nr, S: string;
  Von, Bis, MinD, DT: TDateTime;
  Days: Integer;
  stage, turn, idx ,i : Integer;
  sqlList : TStringList;
  logList : TStringList;
begin
  if Recalculate_Mode then
  begin
    try
      // Nicht vorhandene Datensätze in TPM_Auswertung
      s := 'SELECT COUNT(*) cnt FROM stat_recalc2';
      SQL_Get(qSuch, S);
      idx := 0;
      if not qSuch.Eof then
      begin
        idx := qSuch.FieldByName('cnt').AsInteger;
      end;
      SchreibeMeldung(IntToStr(idx) + ' entries in stat_recalc2', 4);
      idx := 100 - idx;

      Days := Trunc(N_o_w);
      if idx > 0 then
      begin
        sqlList := TStringList.Create;
        logList := TStringList.Create;
        S := 'select TPM_Auswertung.Nr, TPM_Schicht.* from TPM_Schicht'
          + ' left join TPM_Auswertung on trunc(TPM_Schicht.Datumzeit) = trunc(TPM_Auswertung.DatumZeit)'
          + ' and TPM_Schicht.Schicht = TPM_Auswertung.Schicht'
          + ' and TPM_Schicht.MaschNr = TPM_Auswertung.MaschNr'
          + ' where TPM_Schicht.datumZeit between (' + IntToStr(Days - 120) + ') and (' + IntToStr(Days) + ')'
          + ' and TPM_Auswertung.Nr is null'
          + ' and tpm_schicht.maschnr IN (SELECT maschid FROM maschine WHERE OEERELEVANT=1)'
          + ' order by TPM_Schicht.datumZeit desc';
        SQL_Get(qSuch, S);
      // Maximal 100 Einträge !
        while (not qSuch.EOF) and (idx > 0) do
        begin
          S := 'insert into STAT_RECALC2 (Nr, Frei, MaschNr, DatumZeit) values (STAT_RECALC2ID.NextVal,1,'
            + ' ''' + qSuch.FieldByName('MaschNr').AsString + ''','
            + FloatToPunktString(qSuch.FieldByName('Datumzeit').AsFloat) + ')';
          sqlList.Add(s);
          logList.Add(DateTimeToStr(qSuch.FieldByName('Datumzeit').AsFloat) + ' - ' + qSuch.FieldByName('MaschNr').AsString);
          dec(idx);
          qSuch.Next;
        end;
        if sqlList.Count>0 then
        begin
          for i:=0 to sqlList.Count-1 do
          begin
            SQL_Insert(qUpdate, sqlList[i]);
            SchreibeMeldung('Entry recalced:'+logList[i], 4);
          end;
        end;
        FreeAndNil(sqlList);
        FreeAndNil(logList);
      end;

      S := 'delete from Stat_Recalc2 where Nr not in'
        + ' (select Max(Nr) from Stat_Recalc2 group by MaschNr, DatumZeit having Count(*) > 1)';
      SQL_Insert(qUpdate, S);

      MinD := N_o_w;
      MaschListe := ' ';
      SQL_Get(qSuch, 'select * from Stat_Recalc2 order by Nr');
     while not qSuch.EOF do
      begin
        if MinD > qSuch.FieldByName('DatumZeit').AsFloat then
          MinD := qSuch.FieldByName('DatumZeit').AsFloat;
        MaschListe := MaschListe + qSuch.FieldByName('MaschNr').AsString + ' ';
        qSuch.Next;
      end;

      Days := Round(N_o_w - MinD + 1);
      SchreibeMeldung('-------------------------------------------------------------', 4);
      stage := 1;
      TPM_Stillog_Korrektur(TCO_Setup.GetParamInt(qUpdate, 'INCL_Stillog_Arc_Tag'), 30);
      stage := 2;
      TPM_Schicht_Pruefen(TCO_Setup.GetParamInt(qUpdate, 'INCL_TPM_Schicht_Pruefen_Tag'));
      stage := 3;

      SQL_Get(qSuch, 'select * from Stat_Recalc2 order by DatumZeit desc');
      stage := 4;
      turn:=1;
      while not qSuch.EOF do
      begin
      stage := 5;
        Nr := qSuch.FieldByName('Nr').AsString;
        MNr := ' ' + qSuch.FieldByName('MaschNr').AsString + ' ';
        DT := qSuch.FieldByName('DatumZeit').AsFloat;
      stage := 6;

        SchreibeMeldung(GetSelectedMaschinen(qUpdate, '', '', MNr, 1) + '   ' + DateTimeToStr(DT), 4);
        Von := DT - 1 / 24;
        Bis := DT + 1 / 24;

      stage := 7;
        TPM_Korrektur(Von, Bis, False, MNr);
      stage := 8;
        if not TCO_Setup.GetParamBool(qUpdate, 'INCL_TpmAuswertFromCoreSvc') then
        begin
          Berechne_TPM_Auswertung(Von, Bis, MNr);
        end;

      stage := 9;
        SQL_Insert(qUpdate, 'delete from Stat_Recalc2 where Nr = ' + Nr);
        SQL_Get(qSuch, 'select * from Stat_Recalc2 order by DatumZeit desc');
      stage := 10;
        turn := turn+1;
      end;
    stage := 11;
      TPM_AuswertungKorrektur;
    stage := 12;
      SchreibeMeldung('6', 4);

      Berechne_TPM_Produktionsdetail(Days, MaschListe);
      SchreibeMeldung('7', 4);
      Berechne_TPM_Auftragsdetail(Days, MaschListe);
      SchreibeMeldung('8', 4);
      Berechne_A_Daten(Von, Bis, MaschListe);
      SchreibeMeldung('9', 4);

      if Menge_Schicht_Berechnen then
        Nachbuchen_aus_AArchiv(Days, MaschListe);
      SchreibeMeldung('10', 4);

      if Packen then
        Berechne_TPM_Schicht_Verpackt_Ausschuss(Days, MaschListe);
      SchreibeMeldung('11 ', 4);

      Recalculate_Mode := False;
      SchreibeMeldung('-------------------------------------------------------------', 4);
    except on e : Exception do
      begin
        SchreibeMeldung('!! Exception (Stage '+IntTostr(stage)+', Turn '+IntToStr(turn)+'): ' + e.Message,4);
        raise e;
      end;
    end;
  end;
end;

procedure TThread_Schicht.CheckLaufzeitLog;
var
  S, Nr: string;
  MaschNr, MaschNr2: Integer;
  Kommt, Geht, Kommt2: Double;
begin
  // Check Überlappungen in LaufzeitLog
  S := 'select Nr, MaschNr, RuestStart, AuftragEnde from LaufzeitLog order by MaschNr, RuestStart';
  SQL_Get(qSuch, S);

  MaschNr := qSuch.FieldByName('MASCHNR').AsInteger;
  Kommt := qSuch.FieldByName('RuestStart').AsFloat;
  Geht := qSuch.FieldByName('AuftragEnde').AsFloat;
  Nr := qSuch.FieldByName('Nr').AsString;
  if Geht = 0 then
    Geht := N_o_w;
  qSuch.Next;
  while not qSuch.EOF do
  begin
    MaschNr2 := qSuch.FieldByName('MASCHNR').AsInteger;
    Kommt2 := qSuch.FieldByName('RuestStart').AsFloat;
    if (MaschNr = MaschNr2) and (Kommt2 >= Kommt) and (Kommt2 < Geht) then
    begin
      S := 'update LaufzeitLog set AuftragEnde = ''' + FloatToStr2(Kommt2) + ''','
        + ' Laufzeit = -1, Ruestzeit = -1, GesamtLaufzeit = -1, GesamtRuestzeit = -1'
        + ' where NR = ' + Nr;
      SQL_Insert(qUpdate, S);
    end;
    MaschNr := MaschNr2;
    Kommt := Kommt2;
    Geht := qSuch.FieldByName('AuftragEnde').AsFloat;
    Nr := qSuch.FieldByName('Nr').AsString;
    if Geht = 0 then
      Geht := N_o_w;
    qSuch.Next;
  end;

  S := 'update LaufzeitLog set AuftragStart = RuestStart, Laufzeit = -1, RuestZeit = -1,'
    + ' GesamtLaufzeit = -1, GesamtRuestZeit = -1 where Auftragstart < RuestStart and AuftragEnde > 0';
  SQL_Insert(qUpdate, S);
  S := 'update LaufzeitLog set AuftragStart = RuestStart, Laufzeit = -1, RuestZeit = -1,'
    + ' GesamtLaufzeit = -1, GesamtRuestZeit = -1 where Auftragstart > AuftragEnde and AuftragEnde > 0';
  SQL_Insert(qUpdate, S);

  S := 'select Laufzeitlog.*, Maschine.Lizenz from Laufzeitlog, Maschine where Maschine.MaschNr = LaufzeitLog.MaschNr and Laufzeit < 0';
  SQL_Get(qSuch, S);
  while not qSuch.EOF do
  begin
    S := 'update Laufzeitlog set Laufzeit = ' + IntToStr(GetAuftragLaufZeitVonBis(qSuch2, qSuch.FieldByName('MaschNr').AsInteger,
      qSuch.FieldByName('AuftragStart').AsFloat, qSuch.FieldByName('AuftragEnde').AsFloat)) + ','
      + ' RuestZeit = ' + IntToStr(ZeitInMinuten(qSuch.FieldByName('Lizenz').AsString,
      qSuch.FieldByName('RuestStart').AsFloat, qSuch.FieldByName('AuftragStart').AsFloat))
      + ' where Nr = ' + qSuch.FieldByName('Nr').AsString;
    SQL_Insert(qUpdate, S);

    S := 'Update Laufzeitlog SET GesamtLaufZeit = (SELECT SUM(LaufZeit) FROM laufzeitlog'
      + ' WHERE betriebsauftragnr = ''' + qSuch.FieldByName('BetriebsAuftragNr').AsString + ''')'
      + ' WHERE betriebsauftragnr = ''' + qSuch.FieldByName('BetriebsAuftragNr').AsString + '''';
    SQL_Insert(qUpdate, S);

    S := 'Update Laufzeitlog SET gesamtruestzeit = (SELECT SUM(ruestzeit) FROM laufzeitlog'
      + ' WHERE betriebsauftragnr = ''' + qSuch.FieldByName('BetriebsAuftragNr').AsString + ''')'
      + ' WHERE betriebsauftragnr = ''' + qSuch.FieldByName('BetriebsAuftragNr').AsString + '''';
    SQL_Insert(qUpdate, S);

    qSuch.Next;
  end;
end;

end.

