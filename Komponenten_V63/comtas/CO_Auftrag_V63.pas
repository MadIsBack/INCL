unit CO_Auftrag_V63;

interface

uses
  CO_DataBase, CO_Library_V63, CO_Setup2, SysUtils, Classes, Controls, CO_Werkzeug,
  Variants, XlsLib_V63, Forms, comtas_hkomp_V63, ComObj, CO_SPC_V63, CO_Laufzeit, CO_HistorischerAusschuss
  {$IFDEF ODAC}
    ,Ora
  {$ELSE}
    {$IFNDEF NONUNI}
      ,Uni
    {$ENDIF}
  {$ENDIF}
    ;

const
  Auftrag_nicht_gefunden = 2501;
  Werkzeug_nicht_auf_Maschine = 2502;
  Maschine_nicht_frei = 2503;
  Anderer_Auftrag_wird_geruestet = 2504;
  Fehler_Auftragsstart = 2505;
  Werkzeug_nicht_vorhanden = 2506;
  Auftrag_terminiert = 2507;
  Maschine_Optimiert = 2508;
  Kurze_Laufzeit = 2509;
  Werkzeug_nicht_im_Standort = 2510;
  Auftrag_nicht_gestartet = 2511;
  Auftrag_nur_geruestet = 2512;
  Maschine_wartet_auf_FliegendenWechsel = 2513;
  Fehler_Beim_Material_Kopieren = 2514;
  Einsatz_in_Reparatur = 2515;

  Konnte_Index_nicht_erzeugen = 2601;
  DatenbankName_nicht_definiert = 2602;
  Datenbankanbindung_gescheitert = 2603;

  Werkzeug_Muss_zur_Reparatur = 2701;

  stLaeuftInt = 0;
  stStartRuestenInt = 1;
  stgeplantInt = 2;
  stBeendetInt = 3;
  stSchwesterLaeuftInt = 4;
  stUnterbrochen = 5;

  MASCHBEZ_UNTERAUFTRAG = ' W2';

  CSTUECKAUFTRAGGESAMT = 1;
  CAUFTRAGRESETSTUECK = 21;
  CAUFTRAGRESETPRUEF = 22;
  CAUFTRAGRESETPACK = 23;
  CLABELRESET = 128;

type
  TErrorEvent = procedure(Sender: TObject; Msg: string; var Handled: Boolean) of object;
  FuncGetL = function(T: string): string; stdcall;

type
  ComtasError = class(Exception);

type
  TCO_Auftrag = class(TComponent)
  private

    fOraSession: TCO_Database;
    fOpt_WerkZeug: Boolean;
    fOpt_Schwesterauftraege: Boolean;
    FDifferenzListe: Boolean;
    FOption_Ruestzeit_Auftrag_Folgeauftrag: Boolean;
    FOpt_SPC: Boolean;
    FOpt_Metall: Boolean;
    FOpt_TaktLog: Boolean;
    FOpt_SolltaktAenderung: Boolean;
    fAuftrag_Optimieren: Boolean;
    fIgnoreWaitingRepair: Boolean;
    fSpracheNr: Integer;
    FVersion: string;
    FModul: string;

    fTaktVergleichToleranz: Integer;
    fTaktVergleichToleranzAbsolut: Integer;
    fZellenfertigung: Boolean;
    fZellenfertigungSimultan : Boolean;
    fProduktionsLinie:Boolean;
    fRuestAusStillstand: Boolean;
    fExtrusion: Boolean;
    fAuftragsEnde_Close: Boolean;
    fLaufzeitLog: Boolean;
    fTaktzeitkontrolleStammdaten: Boolean;
    fPruefen: Boolean;
    fPacken: Boolean;
    fVerpackt_Barcode: Boolean;
    fWZKavitaet_Update: Boolean;
    fKavitaet_laufender_Auftrag: Integer;
    fMaterial : Boolean;
    fFolgeAuftragTaktzeitUpdate : Boolean;

    fLogStagesPath : string;
    fLogStages : Boolean;
    fSupressEvents : Boolean;
    fExecuteRC : Boolean;

    fTLaufzeit : TCO_Laufzeit;
    fKommissionieren : Boolean;
    fWZStatusInt : Boolean;
    fDontDeleteBDAFromSignals : Boolean;

    qSuch: TCO_Query;
    qSuch2: TCO_Query;
    qUpdate: TCO_Query;
    qCount: TCO_Query;

    CO_SPC: TCO_SPC;

    cWerkzeug : TCO_Werkzeug;

    procedure checkcWerkzeug;

    procedure SetDatabase(DB: TCO_Database);
    procedure SetOpt_Werkzeug(B: Boolean);
    procedure SetOpt_Schwesterauftraege(B: Boolean);

    function Format_String(Wert: string): Integer;
    function SQL2Get(Query: TCO_Query; Tabelle: string; Feld: string; Wert: string; Feld2: string; Wert2: string;
      Ergebnis: Boolean): Integer;
    procedure SQL_Get(Query: TCO_Query; SQLStr: string);
    procedure SQL_Insert(Query: TCO_Query; SQLStr: string);
    function SQLGet(Query: TCO_Query; Tabelle: string; Feld: string; Wert: string; Ergebnis: Boolean): Integer;
    procedure UpdateSQL(Query: TCO_Query; Tabelle: string; UpdateFeld: string; UpdateWert: string;
      WhereFeld: string; WhereWert: string);
    procedure UpdateSQLPunkt(Query: TCO_Query; Tabelle: string; UpdateFeld: string; UpdateWert: string;
      WhereFeld: string; WhereWert: string);

    function SetActionResult(ResultNo: Integer; lineNo: string) : Integer;

    function Werkzeug_Abspannen(Werkzeug: Integer): Integer;
    function Werkzeug_Ruesten(Werkzeug: Integer; Lizenz: string; Betriebsauftragnr: string): Integer;

    function GetDatumZeitString(DZeit: TDateTime): string;

    procedure CheckWerkzeugAarchiv(banr : string);

    function Takt2Excel(Auftrag: string; Pfad: string; ArtikelNr: string): Integer;
    function GetTaktzeitToleranz: Integer;
    procedure Maschinf_Kein_Auftrag(Lizenz: string);
    procedure InsertFehlerDB(Query: TCO_Query; BANr, Liz, Func, SQLStr, SQLError: string);
    function isZellenMaster(aQuery: TCO_Query; aLizenz: string): Boolean;
    function isZellenFertigungSimultan: Boolean;
    function isZellenFertigung(aQuery: TCO_Query): Boolean;
    function isPLMaster(aQuery: TCO_Query; aAuftrag, aLizenz: string): Boolean;
    function GetBANrRaw(aAuftrag : string): string;
    function isProduktionsLinie(aQuery:TCO_Query):Boolean;
    function CheckWerkzeug(aLizenz, aBANr: string): Integer;

    procedure StartOptimieren(aLizenz, aBANr: string);
    procedure EndOptimieren(aLizenz, aBaNr: string; aStueck: Integer);

    procedure SchliesseRuesteintrag(aBaNr, aLizenz: string);
    function Check_Lizenz_In_Pause(Lizenz: string): Boolean;
    function FloatToPunktString(aFloat: Extended): string;
    function FloatToPunktStringF(aFloat: Extended; format: TFloatFormat; prec, digits: Integer): string;
    procedure SendJobdata(aAuftragNr : string; aMaschNr : Integer);
    procedure ResetJobdata(aAuftragNr : string; aMaschNr : Integer);
    procedure AbruestenBuchen(aLizenz : string; aBanr : string);
    function RetrieveToolState(query: TCO_Query): Integer;
    function Get_Daten_aus_Archiv(Table: string; Von: Real; AliasTabelle: Boolean): string;
    function StoreInterruptSignals(MaschNr : string; BANr : string) :integer;
    function RecoverInterruptSignals(MaschNr : string; BANr : string; Lizenz : string) : integer;
    function StringIsNumber(src : string):boolean;
    function StringIsInteger(src : string):boolean;
  protected
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function Tabelle2Excel2(DateiName: string; Path: string; SQLStr: string): Integer;

    function Beenden(Lizenz: string): Integer;
    function BeendenAuftrag(aAuftragNr: string): Integer;
    function FliegenderWechsel(Lizenz: string): Integer;
    function Unterbrechen(Lizenz: string): Integer;
    function UnterbrechenAuftrag(aAuftragNr: string): Integer;

    function GeplantLoeschen(aAuftrag: string): Integer;
    function UngeplantLoeschen(aAuftrag: string): Integer;

    function GetBARumpf(BA: string): string;

    function Buchen(Lizenz: string; BetriebsauftragNr : string; Stueck : Integer;  Bediener : string; D: Real = 0):Integer;
    function Starten(Lizenz: string; BetriebsauftragNr: string; Ruesten: Boolean; StartDatumZeit: TDateTime = 0): Integer;
    function Ruesten(Lizenz: string; BetriebsauftragNr: string; RuestgrundNr: Integer; StartDatumZeit: TDateTime = 0): Integer;
    function LaufendRuesten(Lizenz: string; BetriebsauftragNr: string): Integer;
    function Abschliessen(BetriebsauftragNr: string): Integer;
    function KavProt_Insertf(BANr: string; Alt, Neu: Integer): Integer;

    function Autoterminierung: Boolean;
    function Laufende_Auftraege_Terminieren: Boolean;

    function CheckMaster(Betriebsauftragnr: string; defaultValue: Boolean): Boolean;
    function GetIstTakt(Maschine: string): Integer;
    procedure InsertOfflineMaschinen(Maschine: string);
    function Verpacken(BAuftragnr: string; Menge: Integer; bar: string; aBuchungsTermin: TDateTime; PersonalNr, BCId: string; ForcePackLogDate: string = ''): Integer;
    function Verpacken13(BAuftragnr: string; Menge: Integer; bar: string; D: TDateTime; PersonalNr, BCId, Art: string; EinheitNr: Integer): Integer;
    function Ausschuss(BAuftragnr: string; Menge: Integer; D: TDateTime; GrundNr, PersonalNr: string): Integer;
    procedure InPause(BetriebsauftragNr: string; Pause: Boolean);
    procedure AuftragBuchen(BetriebsauftragNr: string; Stueck: Integer);
    procedure Mengenabgleich(BetriebsauftragNr: string);
    procedure KavProt_Insert(BANr: string; Wert1, Wert2: Integer; Bediener: string = ''; CommentID: integer = -1);
    function GetError(A: Integer): string;
    procedure EndDatumPlusInit;
  published

    property Database: TCO_Database read fOraSession write SetDatabase;
    property Option_Werkzeug: Boolean read fOpt_WerkZeug write SetOpt_Werkzeug;
    property Option_Schwesterauftraege: Boolean read fOpt_Schwesterauftraege write SetOpt_Schwesterauftraege;
    property Option_DifferenzListe: Boolean read FDifferenzListe write FDifferenzListe;
    property Option_Ruestzeit_Auftrag_Folgeauftrag: Boolean read FOption_Ruestzeit_Auftrag_Folgeauftrag write FOption_Ruestzeit_Auftrag_Folgeauftrag;
    property Option_SPC: Boolean read FOpt_SPC write FOpt_SPC;
    property Option_Metall: Boolean read FOpt_Metall write FOpt_Metall default False;
    property Option_TaktLog: Boolean read FOpt_TaktLog write FOpt_TaktLog default False;
    property Option_SolltaktAenderung: Boolean read FOpt_SolltaktAenderung write FOpt_SolltaktAenderung default True;
    property Auftrag_Optimieren: Boolean read fAuftrag_Optimieren write fAuftrag_Optimieren default False;
    property IgnoreWaitingRepair: Boolean read fIgnoreWaitingRepair write fIgnoreWaitingRepair default False;
    property SupressEvents : Boolean read fSupressEvents write fSupressEvents default False;
    property ExecutingRunningChange: Boolean read fExecuteRC write fExecuteRC default False;
    property FolgeAuftragTaktzeitUpdate : Boolean read fFolgeAuftragTaktzeitUpdate write fFolgeAuftragTaktzeitUpdate;

    property CO_SpracheNr: Integer read fSpracheNr write fSpracheNr default 0;
    property CO_Modul: string read FModul write FModul;
    property CO_Version: string read FVersion write FVersion;

    property LogStages: boolean read fLogStages write fLogStages;

  end;

procedure Register;

function GetLErsatz(T: string): string; stdcall;

var
  CO_AuftragGetL: FuncGetL;

implementation

uses
  Maindll, Dialogs, DB {$IFDEF DEBUG}
  ,ExceptLog
{$ENDIF};

procedure Register;
begin
  RegisterComponents('comtas', [TCO_Auftrag]);
end;

function GetLErsatz(T: string): string;
begin
  Result := T;
end;


procedure TCO_Auftrag.InsertFehlerDB(Query: TCO_Query; BANr, Liz, Func, SQLStr, SQLError: string);
var
  S: string;
begin
  S := 'insert into INC_Error (Nr, DatumZeit, BetriebsAuftragNr, Lizenz, Func, SQLText, SQLFehler)'
    + ' values (INC_ErrorId.NextVal,'
    + ' ''' + DateTimeToStr(Now) + ''','
    + ' ''' + BANr + ''','
    + ' ''' + Liz + ''','
    + ' ''' + Func + ''','
    + ' :SQLText, :SQLFehler)';
  Query.SQL.Text := S;
  Query.ParamByNameAsString('SQLText', SQLStr);
  Query.ParamByNameAsString('SQLFehler', SQLError);
  Query.ExecSQL;
  Query.SQL.Clear;
end;

function TCO_Auftrag.isZellenMaster(aQuery: TCO_Query; aLizenz: string): Boolean;
begin
  Result := False;
  try
    if SQLGet(aQuery, 'MASCHINE', 'LIZENZ', aLizenz, True) > 0 then
      Result := aQuery.FieldByName('MASTERMASCHINE').AsInteger > 0;
  except
  end;
end;


function TCO_Auftrag.isZellenFertigungSimultan: Boolean;
begin
  Result := False;
  try
    Result := fZellenfertigungSimultan;
  except
  end;
end;

function TCO_Auftrag.isZellenFertigung(aQuery: TCO_Query): Boolean;
begin
  Result := False;
  try
    Result := fZellenfertigung;
  except
  end;
end;

function TCO_Auftrag.isPLMaster(aQuery: TCO_Query; aAuftrag, aLizenz: string): Boolean;
var s : String;
begin
  Result := False;
  try
    s := 'SELECT ismaster FROM prodline '
      + ' LEFT JOIN maschine ON maschine.maschnr=prodline.maschnr '
      + ' LEFT JOIN prodlinename ON prodlinename.nr = prodline.prodline_nr AND prodlinename.pl_name = ''' + GetBANrRaw(aAuftrag) + ''''
      + ' WHERE maschine.lizenz = ''' + aLizenz + '''';
    SQL_Get(aQuery,s);
    Result := aQuery.FieldByName('ismaster').AsInteger > 0;
  except
  end;
end;

function TCO_Auftrag.GetBANrRaw(aAuftrag : string): string;
var s : String;
begin
  if Pos('_POS',aAuftrag) >0 then
  begin
    Delete(aAuftrag,Pos('_POS',aAuftrag), (length(aAuftrag)-Pos('_POS',aAuftrag))+1);
    result := aAuftrag;
  end;
end;

function TCO_Auftrag.isProduktionslinie(aQuery: TCO_Query): Boolean;
begin
  Result := False;
  try
    Result := fProduktionsLinie;
  except
  end;
end;

function TCO_Auftrag.CheckWerkzeug(aLizenz, aBANr: string): Integer;
var
  S, WZNr: string;
  InWarehouse: Boolean;
begin
  // Checken on Werkzeug noch auf Maschine oder im Lager;
  Result := 0;
  try
    // Mit welchem Werkzeug lief der Auftrag
    S := 'SELECT werkzeugnr FROM aarchiv WHERE betriebsauftragnr = ''' + aBANr + ''''
      + ' AND maschine = ''' + aLizenz + '''';
    SQL_Get(qSuch, S);
    // Welchen Status hat das Werkzeug
    S := 'SELECT Werkzeug, statusexakt, Statusint FROM werkzeug WHERE werkzeugnr = ''' + WZNr + '''';
    SQL_Get(qSuch, S);

    //18.01.2011 RS: Statusint wird nur gezogen, wenn SetupPar-Schalter "INCL_MoldStateFromStateInt" sitzt
    //02.12.2011 RS: Ergänzung StatusInt
    if fWZStatusInt then
      InWarehouse := qSuch.FieldByName('statusInt').AsInteger <> 0
    else
      InWarehouse := qSuch.FieldByName('statusexakt').AsString <> CO_AuftragGetL('Lager');

    if InWarehouse then
    begin
      Result := 1;
      S := 'Update WERKZEUG set Status = ''' + CO_AuftragGetL('Lager') + ''', Statusexakt = '''
        + CO_AuftragGetL('Lager') + '''';
      //18.01.2011 RS: Statusint wird nur gezogen, wenn SetupPar-Schalter "INCL_MoldStateFromStateInt" sitzt
      if fWZStatusInt then
        //02.12.2011 RS: Ergänzung StatusInt
        S := S + ', StatusInt = 0';
      S := S
        + ' WHERE Werkzeug = ''' + qSuch.FieldByName('Werkzeug').AsString
        + '''';
      SQL_Insert(qUpdate, S);
    end;
  except
    Result := 2;
  end;
end;

procedure TCO_Auftrag.StartOptimieren(aLizenz, aBANr: string);
var
  S: string;
  ANr, Bez: string;
begin
  // Eintrag in Optimierungsprotokoll machen. Ggf offene für diese MAschine oder
  // Auftrag schließen
  EndOptimieren(aLizenz, aBANr, 0);

  S := 'SELECT auftragnr, bezeichnung FROM pde WHERE betriebsauftragnr= ''' + aBANr + '''';
  qUpdate.SQL.Text := S;
  qUpdate.Open;
  if not qUpdate.IsEmpty then
  begin
    ANr := qUpdate.FieldByName('auftragnr').AsString;
    Bez := qUpdate.FieldByName('bezeichnung').AsString;
  end;

  S := 'INSERT INTO optimierungsprot (nr, lizenz, betriebsauftragnr, auftragnr, '
    + ' bezeichnung, istwert, startdatumzeit) VALUES ( optimierungsprotid.nextval, '
    + ' ''' + aLizenz + ''', ''' + aBANr + ''', ''' + ANr + ''', ''' + Bez + ''', -1 ,'
    + FloatToPunktString(Now) + ') ';
  qUpdate.SQL.Text := S;
  qUpdate.ExecSQL;
end;

procedure TCO_Auftrag.EndOptimieren(aLizenz, aBaNr: string; aStueck: Integer);
var
  S: string;
begin
  // Eintrag in Optimierungsprotokoll machen. Ggf offene für diese MAschine oder
  // Auftrag schließen
  S := 'UPDATE optimierungsprot SET enddatumzeit = ' + FloatToPunktString(Now)
    + ' WHERE (lizenz = ''' + aLizenz + ''' OR betriebsauftragnr = ''' + aBANr + ''')'
    + ' AND istwert=-1';
  qUpdate.SQL.Text := S;
  qUpdate.ExecSQL;

  S := 'UPDATE optimierungsprot SET dauer = round((enddatumzeit - startdatumzeit)*1440) '
    + ' WHERE (lizenz = ''' + aLizenz + ''' OR betriebsauftragnr = ''' + aBANr + ''')'
    + ' AND istwert = -1';
  qUpdate.SQL.Text := S;
  qUpdate.ExecSQL;

  if aStueck > 0 then
    S := 'UPDATE optimierungsprot SET istwert = ' + IntToStr(aStueck)
      + ' WHERE (lizenz = ''' + aLizenz + ''' OR betriebsauftragnr = ''' + aBANr + ''')'
      + ' AND istwert = -1'
  else
    S := 'UPDATE optimierungsprot SET istwert = 0'
      + ' WHERE (lizenz = ''' + aLizenz + ''' OR betriebsauftragnr = ''' + aBANr + ''')'
      + ' AND istwert = -1';

  qUpdate.SQL.Text := S;
  qUpdate.ExecSQL;
end;

procedure TCO_Auftrag.SchliesseRuesteintrag(aBaNr, aLizenz: string);
var
  S: string;
  Nr: string;
  Istwert, Kopfgroesse: Integer;
begin
  try
    // Gucken ob ein Rüsteintrag offen ist ??????
    S := 'SELECT MAX(nr) nr FROM ruestprot WHERE lizenz = ''' + aLizenz + ''' AND betriebsauftragnr = '''
      + aBANr + '''';
    qSuch.SQL.Text := S;
    qSuch.Open;
    if not qSuch.IsEmpty then
    begin
      Nr := qSuch.FieldByName('nr').AsString;
      if Nr <> '' then
      begin
        S := 'SELECT * FROM ruestprot WHERE nr = ' + Nr;
        qSuch.SQL.Text := S;
        qSuch.Open;

        // Zyklen und Stück eintragen.  // + ' WHERE s.signal = ''STUECKAUFTRAGGESAMT'' ' ???
        //        S := 'SELECT sm.istwert istwert FROM signal_maschine sm '
        //          + ' LEFT JOIN signale s ON s.signalnr=sm.signalnr '
        //          + ' LEFT JOIN maschine m ON sm.maschnr=m.maschnr '
        //          + ' WHERE s.signal = ''STUECKAUFTRAGGESAMT'' '
        //          + ' AND m.lizenz = ''' + aLizenz + '''';

        // Korrigiert Sascha. 08.10.08
        S := 'SELECT sm.Istwert FROM signal_maschine sm, signale s, maschine m'
          + ' WHERE s.signalnr = sm.signalnr and sm.maschnr = m.maschnr and s.signalArt = 1'
          + ' AND m.lizenz = ''' + aLizenz + '''';
        qSuch.SQL.Text := S;
        qSuch.Open;
        if not qSuch.IsEmpty then
          Istwert := qSuch.FieldByName('istwert').AsInteger
        else
          Istwert := 0;

        S := 'SELECT kopfgroesse FROM pde WHERE betriebsauftragnr = ''' + aBANr + '''';
        qSuch.SQL.Text := S;
        qSuch.Open;
        if not qSuch.IsEmpty then
          Kopfgroesse := qSuch.FieldByName('kopfgroesse').AsInteger
        else
          Kopfgroesse := 1;

        S := 'UPDATE ruestprot SET zyklen = ' + IntToStr(Istwert) + ', stueck = '
          + IntToStr(Kopfgroesse * Istwert) + ' WHERE nr = ' + Nr;
        qUpdate.SQL.Text := S;
        qUpdate.ExecSQL;
      end;
    end;
  except
  end;
end;

constructor TCO_Auftrag.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  fSpracheNr := 0;
  if @CO_AuftragGetL = nil then
  begin
    MessageDlg('CO_AuftragGetL nicht definiert!', mtWarning, [mbOK], 0);
    CO_AuftragGetL := GetLErsatz;
  end;

  qSuch := TCO_Query.Create(AOwner);
  qSuch2 := TCO_Query.Create(AOwner);
  qUpdate := TCO_Query.Create(AOwner);
  qCount := TCO_Query.Create(AOwner);

  CO_SPCGetL := CO_AuftragGetL;
  CO_SPC := TCO_SPC.Create(AOwner);

  // Schnittstelleninitialisierung
  fOpt_WerkZeug := False;
  fOpt_Schwesterauftraege := False;
  FOpt_TaktLog := True;
  FDifferenzListe := False;
  FOption_Ruestzeit_Auftrag_Folgeauftrag := False;
  fAuftrag_Optimieren := False;
  fIgnoreWaitingRepair := False;

  fLogStages := False;

  fLogStagesPath := ExtractFilePath(Application.ExeName);
  repeat
    Delete(fLogStagesPath, Length(fLogStagesPath), 1);
  until fLogStagesPath[Length(fLogStagesPath)] = '\';

  fLogStagesPath := fLogStagesPath + 'WorkorderLog\';

  if not DirectoryExists(fLogStagesPath) then
    CreateDir(fLogStagesPath);
end;

destructor TCO_Auftrag.Destroy;
begin
  if qSuch <> nil then
    qSuch.Destroy;
  if qSuch2 <> nil then
    qSuch2.Destroy;
  if qUpdate <> nil then
    qUpdate.Destroy;
  if qCount <> nil then
    qCount.Destroy;
  if CO_SPC <> nil then
    CO_SPC.Destroy;
  inherited Destroy;
end;

procedure TCO_Auftrag.CheckcWerkzeug;
begin
  if (cWerkzeug = nil ) then
  begin
    cWerkzeug := TCO_Werkzeug.Create(self);
    cWerkzeug.Database := fOraSession;
    cWerkzeug.WerkzeugIndex := -1;
  end;
end;

procedure TCO_Auftrag.SetDatabase(DB: TCO_Database);
begin
  fOraSession := DB;
  if qSuch.Active then
    qSuch.Close;
  if qSuch2.Active then
    qSuch2.Close;
  if qCount.Active then
    qCount.Close;
  if qUpdate.Active then
    qUpdate.Close;

  qSuch.Database := fOraSession;
  qSuch2.Database := fOraSession;
  qCount.Database := fOraSession;
  qUpdate.Database := fOraSession;

  CO_SPC.OraSession := fOraSession;

  SQL_Get(qSuch, 'SELECT * FROM SETUP WHERE nr = 1');
  fTaktVergleichToleranz := qSuch.FieldByName('TAKT_VERGLEICH_TOLERANZ').AsInteger;
 fZellenfertigung := qSuch.FieldByName('ZELLENFERTIGUNG').AsInteger = 1;
  try
    fKommissionieren := qSuch.FieldByName('kommissionierung').AsInteger = 1;
  except
  end;
  try
  fProduktionsLinie := qSuch.FieldByName('PRODUKTIONSLINIE').AsInteger = 1;
  if fProduktionsLinie then
    fZellenfertigung := false;
  except
  end;
  fRuestAusStillstand := qSuch.FieldByName('RuestProt_aus_stillstand').AsInteger = 1;
  fExtrusion := qSuch.FieldByName('Extrusion').AsInteger = 1;
  fAuftragsEnde_Close := qSuch.FieldByName('AuftragsEnde_Close').AsInteger = 1;
  fLaufzeitLog := qSuch.FieldByName('laufzeitauslog').AsInteger = 1;
  fTaktzeitkontrolleStammdaten := qSuch.FieldByName('TAKTZEITKONTROLLE_STAMMDATEN').AsInteger = 1;
  fPruefen := qSuch.FieldByName('Pruefen').AsInteger = 1;
  fPacken := qSuch.FieldByName('Packen').AsInteger = 1;
  fVerpackt_Barcode := qSuch.FieldByName('Verpackt_Barcode').AsInteger = 1;
  fWZKavitaet_Update := qSuch.FieldByName('WZKavitaet_Update').AsInteger = 1;
  fKavitaet_laufender_Auftrag := qSuch.FieldByName('Kavitaet_laufender_Auftrag').AsInteger;
  fMaterial := qSuch.FieldByName('material').AsInteger = 1;
  fMaterial := fMaterial AND (TCO_Setup.GetParamInt(qUpdate, 'MDE_MaterialDeliveryToSiloForMaterialGroup') < 0);
  fWZStatusInt := TCO_Setup.GetParamBool(qUpdate,'INCL_MoldStateFromStateInt');
  fDontDeleteBDAFromSignals := TCO_Setup.GetParamBool(qUpdate,'INCL_BDAFromSignals');
  fZellenfertigungSimultan := TCO_Setup.GetParamBool(qUpdate,'INCL_ZellenfertigungLinieSimultan');
  fTaktVergleichToleranzAbsolut := TCO_Setup.GetParamInt(qUpdate,'INCL_TaktToleranz_AbsolutInSekunden');

end;

procedure TCO_Auftrag.SetOpt_Werkzeug(B: Boolean);
begin
  fOpt_WerkZeug := B;
end;

procedure TCO_Auftrag.SetOpt_Schwesterauftraege(B: Boolean);
begin
  fOpt_Schwesterauftraege := B;
end;

function TCO_Auftrag.BeendenAuftrag(aAuftragNr: string): Integer;
var
  SQLStr: string;
  Lizenz: string;
begin
  SQLStr := 'SELECT lizenz FROM pde WHERE betriebsauftragnr = ''' + aAuftragNr + '''';
  SQL_Get(qSuch, SQLStr);
  if not qSuch.IsEmpty then
  begin
    Lizenz := qSuch.FieldByName('lizenz').AsString;
    Result := Beenden(Lizenz);
  end
  else
    Result := Auftrag_nicht_gefunden;
end;

function TCO_Auftrag.FliegenderWechsel(Lizenz: string): Integer;
var
  error: Integer;
  RunningNr, SQlstr, Maschnr: String;
  AuftragNeu, AuftragAlt: string;
begin
  fExecuteRC := True;
  SQLGet(qSuch,'Maschine','Lizenz',Lizenz,false);
  Maschnr := qSuch.FieldByName('Maschnr').AsString;

  SQlstr := ' SELECT * FROM RUnningchangeevents'
          + ' WHERE Maschnr = ' + Maschnr
          + ' AND ( Executed = 0 OR Executed IS NULL )'
          + ' ORDER BY Created';
  SQL_Get(qSuch, SQLStr);
  if not qSuch.IsEmpty then
  begin

    RunningNr := qSuch.FieldByName('Nr').AsString;
    AuftragNeu := qSuch.FieldByName('BANEW').AsString;
    AuftragAlt := qSuch.FieldByName('BAOLD').AsString;

    SQlstr := 'UPDATE RUnningchangeevents'
            + ' SET Started = ' + FloatToPunktString(Now) + ', '
            + ' Module = ''' + FMOdul + ''''
            + ' WHERE NR = ' + RunningNr;
    SQL_Insert(qUpdate, SQLstr);

    error :=  Beenden(Lizenz);
    SQL_Insert(qUpdate,'UPDATE RUnningchangeevents SET Stopresult = ' + IntToStr(error) + ' WHERE NR = ' + RunningNr);
    if error = 0 then
    begin
      fExecuteRC := True;
      error := Starten(Lizenz, AuftragNeu, false);
      CopyCavityAndGRN(AuftragAlt, AuftragNeu,Maschnr , qSuch, qSuch2, qUpdate);
    end;

    if error = 0 then
      SQlstr := ' UPDATE RUnningchangeevents'
              + ' SET Executed = ' + FloatToPunktString(Now) + ', '
              + ' Startresult = ' + IntToStr(error)
              + ' WHERE NR = ' + RunningNr
    else
      SQlstr := ' UPDATE RUnningchangeevents'
              + ' SET Executed = -' + FloatToPunktString(Now) + ', '
              + ' Startresult = ' + IntToStr(error)
              + ' WHERE NR = ' + RunningNr;
    try
      SQL_Insert(qUpdate ,SQLSTr);
    finally
      SQlstr := ' UPDATE RUnningchangeevents'
              + ' SET Executed = -' + FloatToPunktString(Now) + ', '
              + ' Module = ''' + FMOdul + ''''
              + ' WHERE Maschnr = ' + Maschnr
              + ' AND Executed = 0';
      try
        SQL_Insert(qUpdate ,SQLSTr);
      except
      end;
    end;
  fExecuteRC := False;
 end;
end;

function TCO_Auftrag.Beenden(Lizenz: string): Integer;
var
  SQLStr: string;
  PDE_Nummer, Maschinf_Nummer, Nummer, AktSchuss: Integer;
  Maschine, BetriebsauftragNr, ArtikelNr: string;
  Schwesterauftrag: string;
  Takt_Durch, Takt_DurchFilter, Takt_Soll, Takt_Ist, Takt_Diff: Integer;
  Kavitaet, Sollwert, Optimiert: Integer;
  MinRunTime, StartDatumZeit: Real;
  Werkzeug: Integer;
  Istwert, Produziert, Verpackt, DownTime, Stops: Integer;
  Error: Integer;
  Nutzung, Leistung, Qualitaet, Effektivitaet: Real;
  Ausschuss: Integer;
  TPM_SollLaufzeit, TPM_IstLaufZeit: Integer;
  Auftrag_SolLlaufzeit: Integer;
  Auftrag_IstLaufzeit, Auftrag_DiffLaufzeit: Integer;
  Name, Bezeichnung: string;
  MaschNr: Integer;
  Schicht, Dauer, Stat, Anfahr_Ausschuss: Integer;
  MasterAuftrag: Boolean;
  Einheit: string;
  Sollausstoss, Istausstoss, Stueck_nach_Kilo, Meter_nach_kilo: Real;
  Extrusion, AuftragsEnde_Close: Boolean;
  Etikett_Prod: string;
  ETIKETT_CHNR: string;
  KundenReferenz2: string;
  ETIKETT_UN_ZULASSUNG: string;
  Jetzt: Real;
  protpfad: string;
  qZelle: TCO_Query;
  l_nr: string;
  l_posarray: array[0..80] of Char;
  SignalNr: Integer;
  tf : TextFile;

  procedure SetEnd(BA: string);
  var
    BARumpf, S: string;
  begin
    BARumpf := GetBARumpf(BA);
    S := 'SELECT *'
            + ' FROM PA_ARBEITSGANG PAA'
            + ' INNER JOIN'
            + ' ('
            + '   SELECT betriebsauftragnr, ''p'' t FROM pde p UNION'
            + '   SELECT pk.betriebsauftragnr, p.t FROM pdekombi pk'
            + '          INNER JOIN ('
            + '                 SELECT betriebsauftragnr, ''pkp'' t FROM pde UNION'
            + '                 SELECT betriebsauftragnr, ''pkn'' FROM pdeneu'
            + '           ) p ON p.betriebsauftragnr = pk.masterbetriebsauftragnr UNION'
            + '   SELECT betriebsauftragnr, ''pn'' FROM pdeneu'
            + ' ) p ON p.betriebsauftragnr = PAA.betriebsauftragnr'
            + ' WHERE paa.produktionsauftragnr = ''' + BARumpf + '''';
      SQL_Get(qSuch, S);
    //Es gibt keine AGs mehr für diesen Auftrag in PDE, pdeneu, bzw. pdekombi (mit master in pde oder pdeneu)
    if (qSuch.IsEmpty) then
      S := 'UPDATE PA_Auftrag SET status = -1, enddatumzeit = ' + FloatToPunktString(Now)
              + ' WHERE Produktionsauftragnr = ''' + BArumpf + ''''
    else
    begin
      S := 'SELECT *'
              + ' FROM PA_ARBEITSGANG PAA'
              + ' LEFT JOIN pde p ON p.betriebsauftragnr = PAA.betriebsauftragnr'
              + ' WHERE paa.produktionsauftragnr = ''' + BArumpf + ''' AND p.stat IN (0,1)';
      SQL_Get(qSuch, S);
      //Es gibt keine anderen laufenden Arbeitsgänge zu diesem Auftrag
      if (qSuch.IsEmpty) then
        S := 'UPDATE PA_Auftrag SET status = 5'
                + ' WHERE Produktionsauftragnr = ''' + BArumpf + ''''
      else
        S := '';
    end;
    if (S <> '') then
      SQL_Insert(qUpdate, S);
  end;

  procedure logpos(ANr: Integer);
  var
    S, posstring, MNr: string;
    I: Integer;
  begin
    try
      if ANr = 0 then
      begin

        S := 'SELECT log_startid.nextval nval FROM setup WHERE nr = 1';
        SQL_Get(qSuch, S);

        l_nr := qSuch.FieldByName('nval').AsString;

        S := 'SELECT maschnr FROM maschine WHERE lizenz = ''' + Lizenz + '''';
        SQL_Get(qSuch, S);
        MNr := qSuch.FieldByName('maschnr').AsString;
        if MNr = '' then
          MNr := '0';
        l_posarray[0] := 'B';
        for I := 1 to 80 do
          l_posarray[I] := '_';

        S := 'INSERT INTO log_start (Nr,Datumzeit ,Betriebsauftragnr, maschnr, lizenz) VALUES ('
          + l_nr + ', '''
          + DateTimeToStr(Now) + ''', '''
          + BetriebsauftragNr + ''', '
          + '''' + MNr + ''', '''
          + Lizenz + ''')';
        SQL_Insert(qUpdate, S);
      end
      else
      begin
        l_posarray[ANr] := IntToStr(ANr mod 10)[1];
        posstring := 'B ';
        for I := 1 to 80 do
          posstring := posstring + l_posarray[I];
        S := 'UPDATE log_start SET meldung = ''' + posstring + ''' WHERE nr = ' + l_nr;
        {$IFNDEF SUPLOGSTAR}
        SQL_Insert(qUpdate, S);
        {$ENDIF}
        if fLogStages then
        begin
          try
            System.Append(tf);
          except
            Rewrite(tf);
          end;
          WriteLn(tf, DateTimeToStr(now) + ' : ' + IntToStr(ANr));
          CloseFile(tf);
        end;
      end;
    except
    end;
  end;
begin

  if isZellenFertigung(qSuch) then
  begin
    if isZellenMaster(qSuch, Lizenz) then
    begin // Alle Maschinen holen und ebenfals starten
      SQLStr := 'SELECT lizenz FROM maschine WHERE maschgroupid = '
        + '(SELECT maschgroupid FROM maschine WHERE lizenz = '''
        + Lizenz + ''') AND lizenz <> ''' + Lizenz + '''';
      qZelle := TCO_Query.Create(Owner);
      try
        qZelle.Database := fOraSession;
        SQL_Get(qZelle, SQLStr);
        while not qZelle.EOF do
        begin
          Beenden(qZelle.FieldByName('Lizenz').AsString);
          qZelle.Next;
        end;
        qZelle.Close;
      finally
        qZelle.Free;
      end;
    end;
  end;

  if isZellenFertigungSimultan then
  begin
    try
      fZellenfertigungSimultan := False;
      qZelle := TCO_Query.Create(Owner);
      qZelle.Database := fOraSession;
     // Nachsehen ob der Auftrag auf einer Maschine für Simultanfertigung läuft
      SQLStr := 'SELECT * FROM maschine WHERE ag_gruppe = '
      + ' (SELECT ag_gruppe FROM maschine WHERE lizenz = ''' + Lizenz + ''')'
      + ' AND ag_gruppe <> 0 AND not ag_gruppe is null';
      SQL_Get(qZelle, SQLStr);
      while not qZelle.Eof do
      begin
        Beenden(qZelle.FieldByName('lizenz').AsString);
        qZelle.Next;
      end;
      qZelle.Close;
    finally
      fZellenfertigungSimultan := True;
      qZelle.Free;
    end
  end;


  if isProduktionsLinie(qSuch) then
  begin
    try
      qZelle := TCO_Query.Create(Owner);
      qZelle.Database := fOraSession;
      qZelle.SQL.Text := 'SELECT betriebsauftragnr FROM pde WHERE lizenz = ''' + Lizenz + ''' AND stat IN (0,1)';
      qZelle.Open;
      if not qZelle.IsEmpty then
        BetriebsauftragNr := qZelle.FieldByName('betriebsauftragnr').AsString;

    if isPLMaster(qZelle, BetriebsauftragNr, Lizenz) then
    begin
      SQLStr := 'SELECT lizenz, m_order FROM maschine '
        + ' LEFT JOIN prodlinename ON prodlinename.pl_name = ''' + GetBANrRaw(BetriebsauftragNr) + ''''
        + ' LEFT JOIN prodline ON prodline.maschnr = maschine.maschnr AND prodline.prodline_nr = prodlinename.nr'
        + ' WHERE prodline.ismaster = 0';
      try
        SQL_Get(qZelle, SQLStr);
        while not qZelle.EOF do
        begin
          Beenden(qZelle.FieldByName('Lizenz').AsString);
          qZelle.Next;
        end;
        qZelle.Close;
        SQLStr := 'DELETE FROM prodline WHERE prodline_nr = (SELECT nr FROM prodline WHERE pl_name = ''' + GetBANrRaw(BetriebsauftragNr) + ''')';
        qZelle.SQL.Text := SQLStr;
        qZelle.ExecSQL;
        SQLStr := 'DELETE FROM prodlinename WHERE pl_name = ''' + GetBANrRaw(BetriebsauftragNr) + '''';
        qZelle.SQL.Text := SQLStr;
        qZelle.ExecSQL;
      finally
        qZelle.Free;
      end;
    end;
    except
    end;
  end;

  SQLStr := 'SELECT betriebsauftragnr, stat FROM PDE WHERE lizenz = ''' + Lizenz + ''' AND stat IN (0,1)';
  SQL_Get(qSuch, SQLStr);
  if not qSuch.IsEmpty then
  begin
    BetriebsauftragNr := qSuch.FieldByName('betriebsauftragnr').AsString;
    if TCO_Setup.GetParamBool(qUpdate, 'INCL_WorkorderMustRunBeforeStop') then
      if qSuch.FieldByName('stat').AsInteger = 1 then
      begin
        Result := SetActionResult(Auftrag_nur_geruestet, l_nr);
        exit;
      end;
  end;


  if fLogStages then
  begin
    DateTimeToString(SQLStr,'yymmddhhnnss',now);
    AssignFile(tf, fLogStagesPath + BetriebsauftragNr + '_' + SQLStr +'.log');
    ReWrite(tf);
    WriteLn(tf, DateTimeToStr(now) + ' : End ' + BetriebsauftragNr);
    CloseFile(tf);
  end;

  logpos(0);
  Takt_Ist := 100;
  Takt_Diff := 0;
  Jetzt := Now;

  Result := 0;
  Werkzeug := 0;
  if fOraSession = nil then
  begin
    Result := SetActionResult(DatenbankName_nicht_definiert, l_nr);
    logpos(80);
    Exit;
  end;

  if Check_Lizenz_In_Pause(Lizenz) then
  begin
    Result := SetActionResult(Maschine_Optimiert , l_nr);
    logpos(80);
    Exit;
  end;

  logpos(1);

  if TCO_Setup.GetParamBool(qSuch,'INCL_RunningChangeOnPrintRequest') then
  begin
    if SQL2Get(qSuch,'RUnningchangeevents RCE INNER JOIN MASCHINE ON RCE.maschnr = maschine.maschid', 'Lizenz', Lizenz, 'Executed', '0', true) > 0 then
    begin
      if not fExecuteRC then
      begin
        Result := SetActionResult(Maschine_wartet_auf_FliegendenWechsel , l_nr) ;
        logpos(80);
        Exit;
      end;
    end;
  end;

  SQLStr := 'Select count(*) as CNT from PDE where (Lizenz = ''' + Lizenz + ''') and (stat in (0, 1, 5))';
  SQL_Get(qSuch, SQLStr);
  if qSuch.FieldByName('CNT').AsInteger > 0 then
  begin
    SQLStr := 'Select count(*) as CNT from PDE where (Lizenz = ''' + Lizenz + ''') and ((stat = 0) or (stat = 1))';
    SQL_Get(qSuch, SQLStr);
    if qSuch.FieldByName('CNT').AsInteger > 0 then
      SQLStr := 'Select * from PDE where (Lizenz = ''' + Lizenz + ''') and ((stat = 0) or (stat = 1))'
    else
      SQLStr := 'Select * from PDE where (Lizenz = ''' + Lizenz + ''') and (stat = 5)';

    SQL_Get(qSuch, SQLStr);
    logpos(2);

    PDE_Nummer := qSuch.FieldByName('Nr').AsInteger;
    BetriebsauftragNr := qSuch.FieldByName('Betriebsauftragnr').AsString;
    ArtikelNr := qSuch.FieldByName('Auftragnr').AsString;
    Bezeichnung := qSuch.FieldByName('Bezeichnung').AsString;
    Schwesterauftrag := qSuch.FieldByName('Schwesterauftrag').AsString;
    Takt_Soll := qSuch.FieldByName('Taktzeit').AsInteger;
    Kavitaet := qSuch.FieldByName('Kopfgroesse').AsInteger;
    Sollwert := Format_String(qSuch.FieldByName('Sollwert').AsString);
    if qSuch.FieldByName('SOLL_GEPLANT').AsInteger <> 0 then
      Sollwert := qSuch.FieldByName('SOLL_GEPLANT').AsInteger;
    Istwert := Format_String(qSuch.FieldByName('Istwert').AsString);
    Anfahr_Ausschuss := Format_String(qSuch.FieldByName('Anfahr_Ausschuss').AsString);
    StartDatumZeit := qSuch.FieldByName('StartDatumZeit').AsFloat;
    Ausschuss := qSuch.FieldByName('Ausschuss').AsInteger;
   (* RS 27.01.2015 - Quarder CZ: Wir korrigieren hier pde.masterauftrag, falls es nicht sauber ist*)
    MasterAuftrag := CheckMaster(BetriebsauftragNr, qSuch.FieldByName('MasterAuftrag').AsInteger = 1);

    Stat := qSuch.FieldByName('Stat').AsInteger;
    Optimiert := qSuch.FieldByName('Optimiert').AsInteger;

    Sollausstoss := qSuch.FieldByName('Sollausstoss').AsFloat;
    Stueck_nach_Kilo := qSuch.FieldByName('Stueck_nach_Kilo').AsFloat;
    Meter_nach_kilo := qSuch.FieldByName('Meter_nach_kilo').AsFloat;
    Einheit := qSuch.FieldByName('Einheit').AsString;

    Etikett_Prod := qSuch.FieldByName('Etikett_Prod').AsString;
    ETIKETT_CHNR := qSuch.FieldByName('ETIKETT_CHNR').AsString;
    KundenReferenz2 := qSuch.FieldByName('KundenReferenz2').AsString;
    ETIKETT_UN_ZULASSUNG := qSuch.FieldByName('ETIKETT_UN_ZULASSUNG').AsString;
    logpos(3);

    SQLStr := 'Update RuestProt set'
      + ' RuestEnde = ' + FloatToPunktString(Jetzt) + ','
      + ' RuestIst = -1'
      + ' where Betriebsauftragnr = ''' + BetriebsauftragNr + ''' AND Ruestende = 0';
    SQL_Insert(qUpdate, SQLStr);

    // Falsch. Es wir vom Dienst berechnet. Sascha 09.10.08
    // SQLStr := 'Update RuestProt set'
    //  + ' RuestIst = round((ruestende-rueststart)*1440)'
    //  + ' where Betriebsauftragnr = ''' + BetriebsauftragNr + ''' AND RuestIst = -1';
    // SQL_Insert(qUpdate, SQLStr);
    MinRunTime := TCO_Setup.GetParamInt(qUpdate, 'MDE_Zeit_zwischen_AuftragsStart_Ende') / 1440;
    if (MinRunTime > 0 ) then
    begin
      if (StartDatumZeit > Now) then
      begin
        SQL_Get(qSuch2, ' SELECT MAX(startdatum) StartDatumZeit'
                      + ' FROM  auftragstartprot '
                      + ' WHERE betriebsauftragnr = ''' + BetriebsauftragNr + ''''
                      + ' GROUP BY betriebsauftragnr');
        StartDatumZeit := qSuch2.FieldByName('StartDatumZeit').AsFloat;
      end;
      if Now - StartDatumZeit < MinRunTime then
      begin
        Result := SetActionResult( Kurze_Laufzeit, l_nr); // Laufzeit < MDE_Zeit_zwischen_AuftragsStart_Ende min.
       logpos(80);
        Exit;
      end;
    end;

    if fOpt_WerkZeug then
      Werkzeug := qSuch.FieldByName('Werkzeug').AsInteger;

    if SQL2Get(qSuch, 'MASCHINF', 'Lizenz', Lizenz, 'Betriebsauftragnr', BetriebsauftragNr, True) > 0 then
    begin
      Maschinf_Nummer := qSuch.FieldByName('Nr').AsInteger;
      // Produziert := Format_String(qSuch.FieldByName('Stueck').AsString); später steht Produziert := Istwert
      Verpackt := Format_String(qSuch.FieldByName('Pack').AsString);
    end
    else
    begin
      Maschinf_Nummer := -1;
      // Produziert := 0; später steht Produziert := Istwert
      Verpackt := 0;
    end;
    logpos(4);

    if (Stat = 0) and (Optimiert = 1) then
    begin
      SQLStr := 'insert into OptimierungsProt (Nr, Lizenz, BetriebsAuftragNr, AuftragNr, Bezeichnung,'
        + ' Istwert, StartDatumZeit, EndDatumZeit) values (OptimierungsProtId.NextVal,'
        + ' ''' + Lizenz + ''','
        + ' ''' + BetriebsauftragNr + ''','
        + ' ''' + ArtikelNr + ''','
        + ' ''' + Bezeichnung + ''','
        + ' ''' + IntToStr(Istwert) + ''','
        + FloatToPunktString(StartDatumZeit) + ','
        + FloatToPunktString(Jetzt) + ')';
      SQL_Insert(qUpdate, SQLStr);
      SQLStr := 'update OptimierungsProt set Dauer = Trunc((EndDatumZeit - StartDatumZeit)*1440)';
      SQL_Insert(qUpdate, SQLStr);
    end;
    logpos(5);

    SQLGet(qSuch, 'Maschine', 'Lizenz', Lizenz, False);
    Maschine := qSuch.FieldByName('Kennung').AsString;
    MaschNr := qSuch.FieldByName('Datenblock').AsInteger;
    AktSchuss := 0;
    SQLStr := 'SELECT istwert FROM signal_maschine WHERE maschnr = ' +  IntToStr(MaschNr)
      + ' AND signalnr IN (SELECT signalnr FROM signale WHERE signalart=2)';
    SQL_Get(qSuch, SQLStr);
    if not qSuch.IsEmpty then
      AktSchuss := qSuch.fieldByName('istwert').AsInteger;

    if SQLGet(qSuch, 'SIGNALE', 'SignalArt', IntToStr(CLABELRESET), True) > 0 then
    begin
      SignalNr := qSuch.FieldByName('SignalNr').AsInteger;
      SQLStr := 'INSERT INTO SIGNAL_SCHREIBEN (Nr, MaschNr, SignalNr, Wert)'
        + ' VALUES (SIGNAL_SCHREIBENID.NextVal'
        + ',''' + IntToStr(MaschNr)
        + ''',''' + IntToStr(SignalNr)
        + ''',''1'
        + ''')';
      SQL_Insert(qUpdate, SQLStr);

      SQLStr := 'INSERT INTO Log_SIGNAL_SCHREIBEN (Nr, DatumZeit, Datumexakt, BetriebsAuftragNr, Lizenz, MaschNr, '
        + 'MODUL,VERSION,SignalNr, Wert)'
        + ' VALUES (Log_SIGNAL_SCHREIBENID.NextVal,'
        + ' ''' + DateTimeToStr(Now) + ''','
        + FloatToPunktString(Now) + ','
        + ' ''' + BetriebsauftragNr + ''','
        + ' ''' + Lizenz + ''','
        + ' ''' + IntToStr(MaschNr) + ''','
        + ' ''' + FModul + ''','
        + ' ''' + FVersion + ''','
        + ' ''' + IntToStr(SignalNr) + ''','
        + ' ''1'')';
      SQL_Insert(qUpdate, SQLStr);
    end;

    logpos(6);

    //  if FOpt_Metall then // Richtige Stückzahl immer in PDE
    Produziert := Istwert;

    if Produziert = 0 then
      Produziert := 1;
    if Kavitaet = 0 then
      Kavitaet := 1;

    if fOpt_WerkZeug then
    begin
      Error := Werkzeug_Abspannen(Werkzeug);
      if Error <> 0 then
        Result := SetActionResult( Error, l_nr);
    end;
    logpos(7);

    if not fRuestAusStillstand then
    begin
      if Stat = 1 then
      begin
        SQLStr := 'Update RuestProt set'
          + ' RuestEnde = ' + FloatToPunktString(Jetzt) + ','
          + ' RuestIst = -1'
          + ' where Betriebsauftragnr = ''' + BetriebsauftragNr + ''' AND Ruestende = 0';
        SQL_Insert(qUpdate, SQLStr);
      end;
      logpos(8);
    end;

    //Unteraufträge löschen
    SQLStr := 'delete from maschinf where LIZENZ = ''' + Lizenz + MASCHBEZ_UNTERAUFTRAG + '''';
    SQL_Insert(qUpdate, SQLStr);
    logpos(9);

    if FOption_Ruestzeit_Auftrag_Folgeauftrag then
    begin
      qSuch.Close;
      SQLStr := 'select schicht from tpm_schicht where nr = (select max(nr) from tpm_schicht)';
      SQL_Get(qSuch, SQLStr);
      Schicht := qSuch.FieldByName('Schicht').AsInteger;

      SQLStr := 'select COUNT(*) CNT from tpm_Stillog where ((Geht is NULL)OR (Geht = 0)) AND(maschnr = ''' +
        IntToStr(MaschNr) + ''')';
      SQL_Get(qSuch, SQLStr);
      if qSuch.FieldByName('CNT').AsInteger > 0 then
      begin
        //Zuerst anstehende Störungen beenden
        SQLStr := 'select * from tpm_Stillog where ((Geht is NULL)OR (Geht = 0)) AND(maschnr = '''
          + IntToStr(MaschNr) + ''')';
        SQL_Get(qSuch, SQLStr);
        qSuch.First;
        while not qSuch.EOF do
        begin
          Nummer := qSuch.FieldByName('Nr').AsInteger;
          Dauer := Trunc((Jetzt - qSuch.FieldByName('Kommt').AsFloat) * 1440);
          if Dauer = 0 then
            Dauer := 1;

          UpdateSQLPunkt(qUpdate, 'tpm_Stillog', 'Geht', FloatToPunktString(Jetzt), 'Nr', IntToStr(Nummer));
          UpdateSQL(qUpdate, 'tpm_Stillog', 'GehtStr', DateToStr(Date) + '  ' + TimeToStr(Frac(Jetzt)), 'Nr',
            IntToStr(Nummer));
          UpdateSQL(qUpdate, 'tpm_Stillog', 'dauer', IntToStr(Dauer), 'Nr', IntToStr(Nummer));
          qSuch.Next;
        end;
      end;
      logpos(10);

    end
    else //if Ruesten then
    begin
      qSuch.Close;
      SQLStr := 'select * from tpm_Stillog, tpm_stillstaende where tpm_Stillog.Stillstandnr = (tpm_stillstaende.Stillstandnr)'
        + ' AND (Gruppe = 1) AND ((Geht is NULL) OR (Geht = 0)) AND (maschnr = ''' + IntToStr(MaschNr) + ''')';
      SQL_Get(qSuch, SQLStr);
      qSuch.First;
      while not qSuch.EOF do
      begin
        Nummer := qSuch.FieldByName('Nr').AsInteger;
        Dauer := Trunc((Jetzt - qSuch.FieldByName('Kommt').AsFloat) * 1440);
        if Dauer = 0 then
          Dauer := 1;

        UpdateSQLPunkt(qUpdate, 'tpm_Stillog', 'Geht', FloatToPunktString(Jetzt), 'Nr', IntToStr(Nummer));
        UpdateSQL(qUpdate, 'tpm_Stillog', 'GehtStr', DateToStr(Date) + ' ' + TimeToStr(Frac(Jetzt)), 'Nr', IntToStr(Nummer));
        UpdateSQL(qUpdate, 'tpm_Stillog', 'dauer', IntToStr(Dauer), 'Nr', IntToStr(Nummer));
        qSuch.Next;
      end;
      logpos(11);
    end;

    // Wenn Block Stillstand, dann beenden den Stillstand
    SQLStr := 'select tpm_Stillog.Nr, tpm_Stillog.Kommt from tpm_Stillog, tpm_stillstaende'
      + ' where tpm_Stillog.Stillstandnr =  tpm_stillstaende.Stillstandnr AND BlockStillstand = 1 AND Geht = 0'
      + ' AND maschnr = ' + IntToStr(MaschNr);
    SQL_Get(qSuch, SQLStr);
    qSuch.First;
    while not qSuch.EOF do
    begin
      Nummer := qSuch.FieldByName('Nr').AsInteger;
      Dauer := Trunc((Jetzt - qSuch.FieldByName('Kommt').AsFloat) * 1440);
      if Dauer = 0 then
        Dauer := 1;

      UpdateSQLPunkt(qUpdate, 'tpm_Stillog', 'Geht', FloatToPunktString(Jetzt), 'Nr', IntToStr(Nummer));
      UpdateSQL(qUpdate, 'tpm_Stillog', 'GehtStr', DateToStr(Date) + ' ' + TimeToStr(Frac(Jetzt)), 'Nr', IntToStr(Nummer));
      UpdateSQL(qUpdate, 'tpm_Stillog', 'dauer', IntToStr(Dauer), 'Nr', IntToStr(Nummer));
      qSuch.Next;
    end;

    //**********************************************************************
    //            SPC
    //**********************************************************************
    if FOpt_SPC then
    begin
      //      EingabeParam2Excel(Betriebsauftragnr, 'd:\comtas\SPC\');
      //      SQLSTR := 'DELETE from QSPCSTICH where AUFTRAGNR = ''' + Betriebsauftragnr + '''';
      //      SQL_Insert(qUpdate, SQLSTR);
      try
        SQLStr := 'select schicht from tpm_schicht where nr = (select max(nr) from tpm_schicht)';
        SQL_Get(qSuch, SQLStr);
        CO_SPC.Schicht := qSuch.FieldByName('Schicht').AsInteger;
        CO_SPC.MaschNr := MaschNr;
        CO_SPC.AuftragNr := BetriebsauftragNr;
        CO_SPC.SPC_Berechnung_Auftrag;

        SQLStr := 'DELETE from QSPC20 where Maschine = ''' + Lizenz + '''';
        SQL_Insert(qUpdate, SQLStr);
        SQLStr := 'DELETE from QSPC20PROT where Maschine = ''' + Lizenz + '''';
        SQL_Insert(qUpdate, SQLStr);
        logpos(12);
      except on e:Exception do
        begin
          InsertFehlerDB(qUpdate, BetriebsauftragNr, Lizenz, 'SVC finish workorder','Calc SPC', e.Message);
        end;
      end;
    end;

    //**********************************************************************
    //            TAKTZEITEN
    //**********************************************************************
    if FOpt_TaktLog then
    begin
      SQLStr := 'SELECT AVG(TAKTZEIT) AS TAKT from Taktzeiten where AUFTRAGNR = ''' + BetriebsauftragNr + '''';
      SQL_Get(qSuch, SQLStr);
      qSuch.First;
      Takt_Ist := Round(qSuch.FieldByName('TAKT').AsFloat * 100);
      Takt_Durch := Takt_Ist;
      Takt_Diff := Takt_Ist - Takt_Soll;
      logpos(13);
      SQLStr := 'SELECT AVG(TAKTZEIT) AS TAKT from Taktzeiten where AUFTRAGNR = ''' + BetriebsauftragNr + ''' AND taktzeit * 100 >= '
             + FloatToPunktString(Takt_Soll * (1 - TCO_Setup.GetParamInt(qUpdate, 'INCL_AvgCycleTolerancePercent') / 100))
             + ' AND taktzeit <= '
             + FloatToPunktString(Takt_Soll * (1 + TCO_Setup.GetParamInt(qUpdate, 'INCL_AvgCycleTolerancePercent') / 100));

      SQL_Get(qSuch, SQLStr);
      qSuch.First;
      Takt_DurchFilter := Round(qSuch.FieldByName('TAKT').AsFloat * 100);

      if (Takt_Ist > 1) and FOpt_SolltaktAenderung then
      begin
        if fFolgeAuftragTaktzeitUpdate then
        begin
          SQLStr := 'update pde set Taktzeit = ''' + IntToStr(Takt_Ist) + ''', TaktzeitStr = '''
            + FloatToStr(Takt_Ist / 100) + ''' '
            + ' where Lizenz = ''' + Lizenz + ''' AND AuftragNr = ''' + ArtikelNr + '''';
          SQL_Insert(qUpdate, SQLStr); //Mentor (EIN)!!
        end;

        SQLStr := 'update aarchiv set TaktzeitIst = ''' + IntToStr(Takt_Ist)
             + ''', takt_durchschnitt = ''' + IntToStr(Takt_Durch)
             + ''', takt_durchschnitt_filter = ''' + IntToStr(Takt_DurchFilter)  + ''' '
          + ' WHERE BetriebsauftragNr = ''' + BetriebsauftragNr + '''';
        SQL_Insert(qUpdate, SQLStr); //Mentor (EIN)!!

      end;
      // else Takt_Ist := Takt_Soll;  20.08.03
      logpos(14);

      if TCO_Setup.GetParamBool(qSuch, 'MDE_Export_Taktzeit_to_Excel') then
      try
        protpfad := ExtractFilePath(Application.ExeName);
        repeat
          Delete(protpfad, Length(protpfad), 1);
        until protpfad[Length(protpfad)] = '\';

        protpfad := protpfad + CO_AuftragGetL('Taktlog') + '\';

        if not DirectoryExists(protpfad) then
          CreateDir(protpfad);

        if not DirectoryExists(protpfad) then
          protpfad := ExtractFilePath(Application.ExeName);

        Takt2Excel(BetriebsauftragNr, protpfad, ArtikelNr);
      except
      end;

      logpos(15);

      // SQLStr := 'DELETE from Taktzeiten where AUFTRAGNR = ''' + BetriebsauftragNr + '''';
      SQLStr := 'DELETE from Taktzeiten where Lizenz = ''' + Lizenz + '''';
      SQL_Insert(qUpdate, SQLStr);
    end;
    logpos(16);

    //**********************************************************************
    //            QS
    //**********************************************************************
    if SQLGet(qSuch, 'PRUEFPLAN', 'AuftragNr', ArtikelNr, True) > 0 then
    begin
      SQLStr := 'DELETE from Terminorder where Lizenz = ''' + Lizenz + ''' AND Bezeichnung Like ''QS%''';
      SQL_Insert(qUpdate, SQLStr);

      SQLStr := 'DELETE from BDA where Lizenz = ''' + Lizenz + ''' AND Bezeichnung Like ''QS%''';
      SQL_Insert(qUpdate, SQLStr);
    end;
    logpos(17);

    //**********************************************************************
    //            Personal (Schichtführer ermitteln)
    //**********************************************************************

    if TCO_Setup.GetParamBool(qUpdate, 'WS_AARchiv_Personal_vom_Buchen') then
      SQLStr := 'select Bediener Name from BuchungsProt where BetriebsAuftragNr = ''' + BetriebsauftragNr + ''''
        + ' order by Datum Desc'
    else
      SQLStr := 'select Name from Personalanmeldung order by DatumZeit Desc';

    SQL_Get(qSuch, SQLStr);
    try
      Name := qSuch.FieldByName('Name').AsString;
    except
      Name := '';
    end;
    logpos(18);

    // Erfassung / Berechnung der Auftrags Soll- und Istwerte
    // Sascha. 13.06.2008. Martin, in TPM_Schicht stehen die Maschinendaten und keine Auftragsdaten.
    // Wie kann man Auftrag_IstLaufzeit aus TPM_Schicht berechnen? Falsch gedacht?

    SQLStr := 'Select sum(Stops) as Stops, Sum(geplant+ungeplant) as Downtime, Sum(Solllaufzeit) as SSollaufzeit, Sum(IstLaufzeit) as SIstlaufzeit, Avg(Leistung) as DLeistung, Avg(Qualitaet) as DQualitaet, sum(Ruesten) as Ruesten'
      + ' from tpm_schicht where (betriebsauftragnr = ''' + BetriebsauftragNr + ''') and (datumzeit between (' +
      FloatToPunktString(StartDatumZeit) + ') and (' + FloatToPunktString(Jetzt) + '))';
    SQL_Get(qSuch, SQLStr);
    DownTime := qSuch.FieldByName('DownTime').AsInteger;
    Stops := qSuch.FieldByName('Stops').AsInteger;
    // Auftrags_IstLaufzeit muss unterbrochene Aufträge berücksichtigen
    // Evtl. Einführung von Netto und BruttoLaufzeit.
    Auftrag_SolLlaufzeit := Round(Sollwert * (Takt_Soll / 100) / 60 / Kavitaet);
    Auftrag_IstLaufzeit := Round((Jetzt - StartDatumZeit) * 1440) - DownTime;
    Auftrag_DiffLaufzeit := Auftrag_IstLaufzeit - Auftrag_SolLlaufzeit;
    logpos(19);

    { Takt_Ist := Round(Auftrag_IstLaufzeit / Produziert * Kavitaet * 100 * 60);
    if Produziert = 1 then Takt_Ist := 0;
    Takt_Diff := Takt_Ist - Takt_Soll;
    }
    // Neuberechnung Nutzung, Qualität, Effektivität

    TPM_SollLaufzeit := qSuch.FieldByName('SSollaufzeit').AsInteger;
    if TPM_SollLaufzeit = 0 then
      TPM_SollLaufzeit := 1;
    TPM_IstLaufZeit := qSuch.FieldByName('SIstlaufzeit').AsInteger;

    Nutzung := TPM_IstLaufZeit / TPM_SollLaufzeit * 100;
    if Nutzung > 100 then
      Nutzung := 100;
    if Nutzung < 0 then
      Nutzung := 0;
    Leistung := qSuch.FieldByName('DLeistung').AsFloat;
    Qualitaet := (Produziert - Ausschuss) / Produziert * 100;
    if Qualitaet < 0 then
      Qualitaet := 0;
    if (Leistung > 0) and (Qualitaet > 0) then
      Effektivitaet := (Nutzung / 100) * (Leistung / 100) * Qualitaet
    else
      Effektivitaet := 0;

    SQLStr := 'Delete from PDE where Nr = ''' + IntToStr(PDE_Nummer) + '''';
    SQL_Insert(qUpdate, SQLStr);
    if Maschinf_Nummer > 0 then
    begin
      SQLStr := 'Update MASCHINF Set stat = 2 where Nr = ''' + IntToStr(Maschinf_Nummer) + '''';
      SQL_Insert(qUpdate, SQLStr);
    end;
    logpos(21);

    SQLStr := 'Delete from BDA where Lizenz = ''' + Lizenz
      + ''' AND (Signal <> ''' + CO_AuftragGetL('Betriebsstunden') + ''') and (Signal <> '''
      + CO_AuftragGetL('Termin') + ''')';
    if fDontDeleteBDAFromSignals then
      SQLStr := SQLStr + 'AND (signal not in (SELECT to_char(signalnr) FROM SIGNALE))';
      
    SQL_Insert(qUpdate, SQLStr);

    if (not FOpt_TaktLog) or (Takt_Ist = 0) then
      if Produziert > 0 then
      begin
        Takt_Ist := Round(Auftrag_IstLaufzeit * 60 * 100 / (Produziert / Kavitaet));
        Takt_Diff := Takt_Ist - Takt_Soll;
      end;
    logpos(22);

    //********************************************************
    //EXTRUSION
    //********************************************************
    //    SQLGet(qSuch, 'SETUP', 'Nr', '1', False);
    Extrusion := fExtrusion;
    AuftragsEnde_Close := fAuftragsEnde_Close;

    logpos(23);

    if Extrusion then
    begin
      //Berechnung von Istausstoss
      //Standard -> Einheit = Stück
      if Auftrag_IstLaufzeit < 1 then
        Auftrag_IstLaufzeit := 1;

      Istausstoss := (Produziert * Stueck_nach_Kilo) / (Auftrag_IstLaufzeit / 60);

      if Einheit = CO_AuftragGetL('Meter') then
        Istausstoss := (Produziert * Meter_nach_kilo) / (Auftrag_IstLaufzeit / 60);

    end;
    logpos(24);

    //********************************************************
    if (SQL2Get(qSuch, 'AARCHIV', 'Maschine', Maschine, 'BetriebsAuftragnr', BetriebsauftragNr, True) > 0) then
    begin
      qSuch.First;
      while not qSuch.EOF do
      begin
        (* if (qSuch.FieldByName('EndDatumStr').AsString = CO_AuftragGetL('läuft'))
                  or (qSuch.FieldByName('EndDatumStr').AsString = CO_AuftragGetL('Rüsten')) then
             begin *)
        Nummer := qSuch.FieldByName('Nr').AsInteger;
        SQLStr := 'update AARCHIV set '
          + 'EndDatumZeit = ' + FloatToPunktString(Jetzt)
          + ',EndDatumStr = ''' + GetDatumZeitString(Jetzt)
          + ''',ProduziertINT = ''' + IntToStr(Produziert)
          + ''',ProduziertSTR = ''' + IntToStr(Produziert)
          + ''',SollvorgabeINT = ''' + IntToStr(Sollwert)
          + ''',Sollvorgabe = ''' + IntToStr(Sollwert)
          + ''',LaufzeitSoll = ''' + IntToStr(Auftrag_SolLlaufzeit)
          + ''',LaufzeitIst = ''' + IntToStr(Auftrag_IstLaufzeit)
          + ''',LaufzeitDiff = ''' + IntToStr(Auftrag_DiffLaufzeit)
          + ''',Werkzeug = ''' + IntToStr(Werkzeug)
          + ''',TaktzeitSoll = ''' + IntToStr(Takt_Soll)
          + ''',TaktzeitIst = ''' + IntToStr(Takt_Ist)
          + ''',TaktzeitDiff = ''' + IntToStr(Takt_Diff)
          + ''',StopsINT = ''' + IntToStr(Stops)
          + ''',AusschussPRZ = ''' + IntToStr(100 - Round(Qualitaet))
          + ''',VerpacktINT = ''' + IntToStr(Verpackt)
          + ''',StillstandINT = ''' + IntToStr(DownTime)
          + ''',Schwesterauftrag = ''' + Schwesterauftrag
          + ''',Nutzung = ' + FloatToPunktString(Nutzung)
          + ', Leistung = ' + FloatToPunktString(Leistung)
          + ', Qualitaet = ' + FloatToPunktString(Qualitaet)
          + ', Effektivitaet = ' + FloatToPunktString(Effektivitaet)
          + ', Ausschuss = ''' + IntToStr(Ausschuss)
          + ''',Kavitaet = ''' + IntToStr(Kavitaet)
          + ''',Name = ''' + Name
          + ''',Change_Art = ''E'
          + ''',SOLLAUSSTOSS = ' + FloatToPunktString(Sollausstoss)
          + ',ISTAUSSTOSS = '+ FloatToPunktStringF(Istausstoss, ffFixed, 15, 2)
          + ',Stueck_nach_Kilo = ' + FloatToPunktString(Stueck_nach_Kilo)
          + ',Meter_nach_Kilo = ' + FloatToPunktString(Meter_nach_kilo)
          + ' where (Nr = ''' + IntToStr(Nummer) + ''')';
        SQL_Insert(qUpdate, SQLStr);
        logpos(25);

        SQLStr := 'update AARCHIV set '
          + ' Anfahr_Ausschuss = ''' + IntToStr(Anfahr_Ausschuss)
          + ''' where (Nr = ''' + IntToStr(Nummer) + ''')';
        SQL_Insert(qUpdate, SQLStr);

        logpos(26);

        {Begin INCLUDE CO_AuftragKBeenden.pas}
        if MasterAuftrag then
        begin
          SQLGet(qSuch2, 'PDEKombi', 'MasterBetriebsAuftragNr', BetriebsauftragNr, False);
          while not qSuch2.EOF do
          begin
            SQLStr := 'update AARCHIV set '
              + 'EndDatumZeit = ' + FloatToPunktString(Jetzt)
              + ',EndDatumStr = ''' + GetDatumZeitString(Jetzt)
              + ''',ProduziertINT = ''' + qSuch2.FieldByName('IstWert').AsString
              + ''',ProduziertSTR = ''' + qSuch2.FieldByName('IstWert').AsString
              + ''',SollvorgabeINT = ''' + qSuch2.FieldByName('SollWert').AsString
              + ''',Sollvorgabe = ''' + qSuch2.FieldByName('SollWert').AsString
              + ''',LaufzeitSoll = ''' + IntToStr(Auftrag_SolLlaufzeit)
              + ''',LaufzeitIst = ''' + IntToStr(Auftrag_IstLaufzeit)
              + ''',LaufzeitDiff = ''' + IntToStr(Auftrag_DiffLaufzeit)
              + ''',Werkzeug = ''' + IntToStr(Werkzeug)
              + ''',TaktzeitSoll = ''' + IntToStr(Takt_Soll)
              + ''',TaktzeitIst = ''' + IntToStr(Takt_Ist)
              + ''',TaktzeitDiff = ''' + IntToStr(Takt_Diff)
              + ''',StopsINT = ''' + IntToStr(Stops)
              + ''',AusschussPRZ = CASE produziertInt WHEN 0 THEN ''' + IntToStr(100 - Round(Qualitaet)) + ''''
              + ' ELSE to_char(ROUND(ausschuss*100/produziertInt,2)) END '
              + ',VerpacktINT = ''' + IntToStr(Verpackt)
              + ''',StillstandINT = ''' + IntToStr(DownTime)
              + ''',Schwesterauftrag = ''' + Schwesterauftrag
              + ''',Nutzung = ' +FloatToPunktString(Nutzung)
              + ',Leistung = '+ FloatToPunktString(Leistung)
              + ',Qualitaet = CASE produziertInt WHEN 0 THEN ''' + FloatToStr(Qualitaet)
              + ''' ELSE to_char(ROUND((produziertint-ausschuss)*100/produziertInt,2)) END '
              + ',Effektivitaet = ' + FloatToPunktString(Effektivitaet)
              //              + ',Ausschuss = ''' + IntToStr(Ausschuss)
            + ',Kavitaet = ''' + qSuch2.FieldByName('Kavitaet').AsString
              + ''',Name = ''' + Name
              + ''',Change_Art = ''E'
              + ''' where (BetriebsAuftragNr = ''' + qSuch2.FieldByName('BetriebsAuftragNr').AsString + ''')';
            SQL_Insert(qUpdate, SQLStr);

            try
              SQLStr := 'update AARCHIV set Anfahr_Ausschuss = '''
                + IntToStr((Anfahr_Ausschuss div Kavitaet) * qSuch2.FieldByName('Kavitaet').AsInteger)
                + ''' where (BetriebsAuftragNr = ''' + qSuch2.FieldByName('BetriebsAuftragNr').AsString + ''')';
              SQL_Insert(qUpdate, SQLStr);
            except
              SQLStr := 'update AARCHIV set Anfahr_Ausschuss = ''' + IntToStr(Anfahr_Ausschuss)
                + ''' where (BetriebsAuftragNr = ''' + qSuch2.FieldByName('BetriebsAuftragNr').AsString + ''')';
              SQL_Insert(qUpdate, SQLStr);
            end;
            qSuch2.Next;
          end;
        end;
        qSuch.Next;
      end;
      logpos(27);
    end;

    // Stückzahl abnullen. Nur jetzt.
    AuftragBuchen(BetriebsauftragNr, 0); //qqq
    SQLStr := 'update Maschine set StueckMaschine0 = ' + IntToStr(Istwert) + ' where Lizenz = ''' + Lizenz + '''';
    SQL_Insert(qUpdate, SQLStr);

    // unnötig
    //    SQLStr := 'INSERT INTO AStart (Nr,Lizenz,Signal)'
    //      + 'VALUES(AStartId.NextVal'
    //      + ',''' + Lizenz
    //      + ''',''' + CO_AuftragGetL('Stückzahl Maschine')
    //      + ''')';
    //    SQL_Insert(qUpdate, SQLStr);
    logpos(28);

    SQLStr := 'delete from MDE_VER where Lizenz = ''' + Lizenz + ''' AND SignalKod = 0';
    SQL_Insert(qUpdate, SQLStr);
    logpos(29);

    if fOpt_WerkZeug then
      CheckWerkzeugAarchiv(BetriebsauftragNr);

    if AuftragsEnde_Close then
    begin
      SQLStr := 'update AArchiv set Endestatus = ''' + CO_AuftragGetL('abgeschlossen') + ''','
        + ' ENDESTATUSDATUM = ' + FloatToPunktString(Jetzt)
        + ' where BetriebsAuftragNr = ''' + BetriebsauftragNr + '''';
      SQL_Insert(qUpdate, SQLStr);
      logpos(30);
      if not fSupressEvents then
      begin
        SQLStr := 'select Count(*) as CNT from ERPEvents'
          + ' where BetriebsAuftragNr = ''' + BetriebsauftragNr + ''''
          + ' and Event = ''A''';
        SQL_Get(qUpdate, SQLStr);
        if qUpdate.FieldByName('CNT').AsInteger = 0 then
        begin
          SQLStr := 'insert into ERPEvents (Nr, BetriebsAuftragNr, Event, Datumzeit)'
            + ' values (ERPEventsId.NextVal,'
            + '''' + BetriebsauftragNr + ''','
            + '''A'','
            + FloatToPunktString(Jetzt) + ')';
          SQL_Insert(qUpdate, SQLStr);
        end;
      end;
    end;
    logpos(31);

    InsertOfflineMaschinen(Lizenz);

    if not fSupressEvents then
    begin
      SQLStr := 'select Count(*) as CNT from ERPEvents'
        + ' where BetriebsAuftragNr = ''' + BetriebsauftragNr + ''''
        + ' and Event = ''B''';
      SQL_Get(qUpdate, SQLStr);
      if qUpdate.FieldByName('CNT').AsInteger = 0 then
      begin
        SQLStr := 'insert into ERPEvents (Nr, BetriebsAuftragNr, Event, Datumzeit)'
          + ' values (ERPEventsId.NextVal,'
          + '''' + BetriebsauftragNr + ''','
          + '''B'','
          + FloatToPunktString(Jetzt) + ')';
        SQL_Insert(qUpdate, SQLStr);
        // Auch für Kombi Aufträge !!!
        qSuch.SQL.Text := 'SELECT betriebsauftragnr FROM pdekombi '
          + ' WHERE MASTERBETRIEBSAUFTRAGNR = ''' + BetriebsauftragNr + '''';
        qSuch.Open;
        while not qSuch.EOF do
        begin
          SQLStr := 'insert into ERPEvents (Nr, BetriebsAuftragNr, Event, Datumzeit)'
            + ' values (ERPEventsId.NextVal,'
            + '''' + qSuch.FieldByName('betriebsauftragnr').AsString + ''','
            + '''B'','
            + FloatToPunktString(Jetzt) + ')';
          SQL_Insert(qUpdate, SQLStr);
          qSuch.Next;
        end;
      end;
    end;
    Maschinf_Kein_Auftrag(Lizenz);
  end
  else
  begin
    Result := SetActionResult( Auftrag_nicht_gefunden, l_nr);
    Exit;
  end;
  logpos(32);

  // Korrektur Laufzeitlog, bei Auftrag Start Rüsten und gleich beenden
  try
    SQLStr := 'UPDATE LaufzeitLog SET Auftragstart = AuftragEnde, '
      + ' Ruestzeit = ((AuftragEnde - RuestStart)*1440) WHERE AuftragStart = 0 '
      + ' AND AuftragEnde > 0 AND Betriebsauftragnr = ''' + BetriebsauftragNr + '''';
    SQL_Insert(qUpdate, SQLStr);
  except
  end;
  logpos(33);

  // Höchsten Eintrag suchen und Laufzeit berechnen
  SQLStr := 'SELECT * FROM LaufzeitLog WHERE nr = '
    + ' (SELECT MAX(nr) FROM LaufzeitLog WHERE Betriebsauftragnr = ''' + BetriebsauftragNr + ''')';
  SQL_Get(qSuch, SQLStr);
  if not qSuch.IsEmpty then
  begin
    if qSuch.FieldByName('AuftragStart').AsFloat = 0 then
      SQLStr := 'UPDATE LaufzeitLog SET AuftragStart = ' + FloatToPunktString(Jetzt)
        + ', AuftragEnde = ' + FloatToPunktString(Jetzt) + ', Ruestzeit = '''
        + IntToStr(Round((Jetzt - qSuch.FieldByName('RuestStart').AsFloat) * 1440))
        + ''' WHERE nr = ' + qSuch.FieldByName('nr').AsString
    else
      SQLStr := 'UPDATE LaufzeitLog SET AuftragEnde = ' + FloatToPunktString(Jetzt)
        + ', Laufzeit = '''
        + IntToStr(Round((Jetzt - qSuch.FieldByName('AuftragStart').AsFloat) * 1440))
        + ''' WHERE nr = ' + qSuch.FieldByName('nr').AsString;
    SQL_Insert(qUpdate, SQLStr);
    logpos(34);

    SQLStr := 'UPDATE laufzeitlog SET gesamtlaufzeit = '
      + IntToStr(GetAuftragLaufZeit(qSuch, qSuch2, BetriebsauftragNr))
      + ' WHERE betriebsauftragnr = ''' + BetriebsauftragNr + '''';
    SQL_Insert(qUpdate, SQLStr);
    logpos(35);

    try
      if fRuestAusStillstand then
      begin // Wenn Ruestzeiten aus dem Stillstandsprot erzeugt werden, dann aus Ruestprot die Gesamtruestzeit holen
        SQLStr := 'UPDATE laufzeitlog SET '
          + 'gesamtruestzeit = (SELECT SUM(ruestist) FROM ruestprot WHERE'
          + ' betriebsauftragnr = ''' + BetriebsauftragNr + ''') '
          + 'WHERE betriebsauftragnr = ''' + BetriebsauftragNr + '''';
      end
      else
      begin
        SQLStr := 'UPDATE laufzeitlog SET '
          + 'gesamtruestzeit = (SELECT SUM(ruestzeit) FROM laufzeitlog WHERE'
          + ' betriebsauftragnr = ''' + BetriebsauftragNr + ''') '
          + 'WHERE betriebsauftragnr = ''' + BetriebsauftragNr + '''';
      end;
      SQL_Insert(qUpdate, SQLStr);
    except
    end;
  end;
  logpos(36);

  try
    if fLaufzeitLog then
    begin
      logpos(76);
      SQLStr := 'SELECT MAX(ll.gesamtlaufzeit) lz, MAX(ll.gesamtruestzeit) rz, '
        + ' MAX(decode(aa.laufzeitsoll,null,0,aa.laufzeitsoll)) ls, '
        + ' MAX(decode(aa.ruestzeitsoll,null,0,aa.ruestzeitsoll)) rs, '
        + ' MAX(produziertint) pi'
        + ' FROM laufzeitlog ll, aarchiv aa  WHERE '
        + ' ll.betriebsauftragnr = aa.betriebsauftragnr and ll.betriebsauftragnr = '
        + '''' + BetriebsauftragNr + '''';
      SQL_Get(qSuch, SQLStr);
      logpos(77);
      if not qSuch.IsEmpty then
      begin
        SQLStr := 'UPDATE aarchiv SET ruestzeitist = ''' + qSuch.FieldByName('rz').AsString
          + ''', ruestzeitdiff = '''
          + IntToStr(qSuch.FieldByName('rz').AsInteger - qSuch.FieldByName('rs').AsInteger)
          + ''' WHERE betriebsauftragnr = ''' + BetriebsauftragNr + '''';
        SQL_Insert(qUpdate, SQLStr);
        logpos(78);

        fTLaufzeit := TCO_Laufzeit.Create(qSuch2);
        fTLaufzeit.BetriebsauftragNr := BetriebsauftragNr;
        SQLStr := 'UPDATE aarchiv SET laufzeitist = ' + IntToStr(fTLaufzeit.Laufzeit)
          + ', laufzeitsoll = ' +  IntToStr(fTLaufzeit.SollLaufzeitArchiv)
          + ', laufzeitdiff = '+  IntToStr(fTLaufzeit.Laufzeit - fTLaufzeit.SollLaufzeitArchiv)
          + ', taktzeitsoll = '+  IntToStr(round(fTLaufzeit.SollTakt * 100))
          + ', taktzeitist = '+  IntToStr(round(fTLaufzeit.IstTakt * 100))
          + ', taktzeitdiff = '+  IntToStr(round((fTLaufzeit.IstTakt - fTLaufzeit.SollTakt) * 100))
          + ', Nutzung = ' + FloatToPunktString(fTLaufzeit.Nutzung)
          + ', Leistung = ' + FloatToPunktString(fTLaufzeit.Leistung)
          + ', Qualitaet = ' + FloatToPunktString(fTLaufzeit.Qualitaet)
          + ', Effektivitaet = ' + FloatToPunktString(fTLaufzeit.OEE)
          + ' WHERE betriebsauftragnr = ''' + BetriebsauftragNr + ''''
          + ' OR masterauftrag =  ''' + BetriebsauftragNr + '''';
        SQL_Insert(qUpdate, SQLStr);
        logpos(79);

        if TCO_Setup.GetParamBool(qSuch,'INCL_Update_Masterdata_JobStop') then
        begin
           SQLStr := 'UPDATE pdestamm SET solltaktstr = ''' + FloatToStr(fTLaufzeit.SollTakt)
            + ''', solltaktzeit = ' +  IntToStr(Round(fTLaufzeit.SollTakt * 100))
            + ' WHERE auftragnr = ''' + fTLaufzeit.ArtikelNr + '''' ;
          SQL_Insert(qUpdate, SQLStr);
        end;
        (* Hinfällig und nie aufgefallen. Werte werden über CO_Laufzeit berechnet und geschrieben. ML 12.3.2013
        else
        begin
          SQLStr := 'UPDATE aarchiv SET laufzeitist = ''' + qSuch.FieldByName('lz').AsString
            + ''', laufzeitdiff = '''
            + IntToStr(qSuch.FieldByName('lz').AsInteger - qSuch.FieldByName('ls').AsInteger)
            + ''' WHERE betriebsauftragnr = ''' + BetriebsauftragNr + '''';
          SQL_Insert(qUpdate, SQLStr);

          logpos(37);

          if not FOpt_TaktLog then
            if qSuch.FieldByName('pi').AsInteger > 0 then
            begin
              try
                Takt_Ist := Round(qSuch.FieldByName('lz').AsInteger * 60 * 100 / qSuch.FieldByName('pi').AsInteger);
                Takt_Diff := Takt_Ist - Takt_Soll;
                SQLStr := 'UPDATE aarchiv SET taktzeitist = ''' + IntToStr(Takt_Ist)
                  + ''', taktzeitdiff = ''' + IntToStr(takt_diff)
                  + ''' WHERE betriebsauftragnr = ''' + BetriebsauftragNr + '''';
                SQL_Insert(qUpdate, SQLStr);
              except
              end;
            end;
        end;
        *)
        fTLaufzeit.Destroy;
      end;
    end;
  except
  end;

  SQLStr := 'UPDATE laufzeitlog SET gesamtlaufzeit = ' + IntToStr(GetAuftragLaufZeit(qSuch, qSuch2, BetriebsauftragNr))
    + ' WHERE betriebsauftragnr = ''' + BetriebsauftragNr + '''';
  SQL_Insert(qUpdate, SQLStr);

  if SQLGet(qSuch, 'Laufzeitlog', 'BetriebsauftragNr', BetriebsauftragNr, True) > 0 then
  begin
    if TCO_Setup.GetParamBool(qSuch,'INCL_Update_Masterdata_JobStop') then
    begin
      fTLaufzeit := TCO_Laufzeit.Create(qSuch2);
      fTLaufzeit.BetriebsauftragNr := BetriebsauftragNr;
      SQLStr := 'UPDATE aarchiv SET laufzeitist = ' + IntToStr(fTLaufzeit.Laufzeit)
        + ', laufzeitsoll = ' +  IntToStr(fTLaufzeit.SollLaufzeitArchiv)
        + ', laufzeitdiff = '+  IntToStr(fTLaufzeit.Laufzeit - fTLaufzeit.SollLaufzeitArchiv)
        + ', taktzeitsoll = '+  IntToStr(round(fTLaufzeit.SollTakt * 100))
        + ', taktzeitist = '+  IntToStr(round(fTLaufzeit.IstTakt * 100))
        + ', taktzeitdiff = '+  IntToStr(round((fTLaufzeit.IstTakt - fTLaufzeit.SollTakt) * 100))
        + ' WHERE betriebsauftragnr = ''' + BetriebsauftragNr + ''''
        + ' OR masterauftrag =  ''' + BetriebsauftragNr + '''';
      SQL_Insert(qUpdate, SQLStr);
      fTLaufzeit.Destroy;
    end
    else
    begin
      SQLStr := 'UPDATE aarchiv SET laufzeitist = ''' + qSuch.FieldByName('Gesamtlaufzeit').AsString + ''''
        + ' where Betriebsauftragnr = ''' + BetriebsauftragNr + '''';
      SQL_Insert(qUpdate, SQLStr);
    end;
  end;

  logpos(37);
  CheckWerkzeug(Lizenz, BetriebsauftragNr);

  logpos(38);

  if TCO_Setup.GetParamBool(qSuch, 'MDE_Etikett_beim_Beenden') then
  begin
    SQLStr := 'insert into BCDruckEvent (Nr, BetriebsAuftragNr, EinheitNr, BeginnenMit, Manuell)'
      + ' values (BCDruckEventId.NextVal,'
      + ' ''' + BetriebsauftragNr + ''','
      + ' -1,'
      + ' ' + IntToStr(Istwert) + ','
      + ' 0)';
    SQL_Insert(qUpdate, SQLStr);
  end;

  // Stückazhl in Koppler auf 0 setzen wenn Auftrag beendet Len 30.01.09

  if SQLGet(qSuch, 'SIGNALE', 'SignalArt', IntToStr(CAUFTRAGRESETSTUECK), True) > 0 then
  begin
    SignalNr := qSuch.FieldByName('SignalNr').AsInteger;
    SQLStr := 'INSERT INTO SIGNAL_SCHREIBEN (Nr, MaschNr, SignalNr, Wert)'
      + ' VALUES (SIGNAL_SCHREIBENID.NextVal'
      + ',''' + IntToStr(MaschNr)
      + ''',''' + IntToStr(SignalNr)
      + ''',''1'
      + ''')';
    SQL_Insert(qUpdate, SQLStr);

    SQLStr := 'INSERT INTO Log_SIGNAL_SCHREIBEN (Nr, DatumZeit, Datumexakt, BetriebsAuftragNr, Lizenz, MaschNr, '
      + 'MODUL,VERSION,SignalNr, Wert)'
      + ' VALUES (Log_SIGNAL_SCHREIBENID.NextVal,'
      + ' ''' + DateTimeToStr(Now) + ''','
      + FloatToPunktString(Now) + ','
      + ' ''' + BetriebsauftragNr + ''','
      + ' ''' + Lizenz + ''','
      + ' ''' + IntToStr(MaschNr) + ''','
      + ' ''' + FModul + ''','
      + ' ''' + FVersion + ''','
      + ' ''' + IntToStr(SignalNr) + ''','
      + ' ''1'')';
    SQL_Insert(qUpdate, SQLStr);
  end;

  if TCO_Setup.GetParamBool(qCount, 'JobSetupAndRestart') then
  begin
    try
      ResetJobdata(BetriebsauftragNr, MaschNr);
      logpos(65);
    except
    end;
  end;

  // Charge checken
  SQLStr := 'SELECT nr FROM chargen WHERE lizenz = ''' + Lizenz
    + ''' AND betriebsauftragnr = ''' + BetriebsauftragNr
    + ''' AND enddatumzeit =0 ORDER BY startdatumzeit';
  SQL_Get(qSuch2, SQLStr);
  if not qSuch2.IsEmpty then
  begin
    SQLStr := 'UPDATE chargen SET enddatumzeit = ' + FloatToPunktString(Now)
      + ', schussende = ' + IntToStr(AktSchuss)
      + ' WHERE nr = ' + qSuch2.FieldByName('nr').AsString;
    SQL_Insert(qUpdate, SQLStr);
  end;
  logpos(66);
  // Wenn Lizenz = K-+BANr dann Konfektionsauftrag auf Offline Maschine
  // Maschine bei Auftragende löschen (Anpassung FAG ML 120607)
  if Lizenz = 'K-' + BetriebsauftragNr then
  begin
    SQLStr := 'DELETE FROM maschoffline WHERE lizenz = ''' + lizenz + '''';
    SQL_Insert(qUpdate, SQLStr);
    SQLStr := 'DELETE FROM maschinf WHERE lizenz = ''' + lizenz + '''';
    SQL_Insert(qUpdate, SQLStr);
  end;

  try
    SetEnd(Betriebsauftragnr);
    logpos(67);
    if MasterAuftrag then
    begin
      SQLGet(qSuch2, 'PDEKombi', 'MasterBetriebsAuftragNr', BetriebsauftragNr, False);
      while not qSuch2.EOF do
      begin
        SetEnd(qSuch2.FieldByName('Betriebsauftragnr').AsString);
        qSuch2.Next;
      end;
    end;
    logpos(68);

  except
  end;

  fExecuteRC := false;

  SetActionResult( 0, l_nr);
  logpos(80);
end;

function TCO_Auftrag.UnterbrechenAuftrag(aAuftragNr: string): Integer;
var
  SQLStr: string;
  Lizenz: string;
begin
  SQLStr := 'SELECT lizenz FROM pde WHERE betriebsauftragnr = ''' + aAuftragNr + '''';
  SQL_Get(qSuch, SQLStr);
  if not qSuch.IsEmpty then
  begin
    Lizenz := qSuch.FieldByName('lizenz').AsString;
    Result := Unterbrechen(Lizenz);
  end
  else
    Result := Auftrag_nicht_gefunden;
end;

function TCO_Auftrag.Unterbrechen(Lizenz: string): Integer;
var
  SQLStr, Bezeichnung: string;
  PDE_Nummer, Maschinf_Nummer, Nummer2, AktSchuss: Integer;
  Maschine, BetriebsauftragNr: string;
  ArtikelNr, Schwesterauftrag: string;
  Takt_Soll, Takt_Ist, Takt_Diff: Integer;
  Kavitaet, Sollwert: Integer;
  MinRunTime, StartDatumZeit: Real;
  Werkzeug: Integer;
  Istwert, Produziert, Verpackt, DownTime, Stops: Integer;
  Error: Integer;
  Nutzung, Leistung, Qualitaet, Effektivitaet: Real;
  Ausschuss: Integer;
  TPM_SollLaufzeit, TPM_IstLaufZeit: Integer;
  Auftrag_SolLlaufzeit, Auftrag_IstLaufzeit: Integer;
  Auftrag_DiffLaufzeit: Integer;
  MaschNr, Stat, Optimiert: Integer;
  Schicht, Dauer, Anfahr_Ausschuss: Integer;
  MasterAuftrag: Boolean;
  EndDatum: TDateTime;
  Jetzt: Real;
  protpfad: string;
  qZelle: TCO_Query;
  l_nr: string;
  l_posarray: array[0..80] of Char;
  tf :TextFile;

  procedure logpos(ANr: Integer);
  var
    S, posstring, MNr: string;
    I: Integer;
  begin
    try
      if ANr = 0 then
      begin

        S := 'SELECT log_startid.nextval nval FROM setup WHERE nr = 1';
        SQL_Get(qSuch, S);

        l_nr := qSuch.FieldByName('nval').AsString;

        S := 'SELECT maschnr FROM maschine WHERE lizenz = ''' + Lizenz + '''';
        SQL_Get(qSuch, S);
        MNr := qSuch.FieldByName('maschnr').AsString;
        if MNr = '' then
          MNr := '0';
        l_posarray[0] := 'U';
        for I := 1 to 80 do
          l_posarray[I] := '_';

        S := 'INSERT INTO log_start (Nr,Datumzeit ,Betriebsauftragnr, maschnr, lizenz) VALUES '
          + '('
          + l_nr + ', '''
          + DateTimeToStr(Now) + ''', '''
          + BetriebsauftragNr + ''', '
          + '''' + MNr + ''', '''
          + Lizenz + ''')';
        SQL_Insert(qUpdate, S);
      end
      else
      begin
        l_posarray[ANr] := IntToStr(ANr mod 10)[1];
        posstring := 'U ';
        for I := 1 to 80 do
          posstring := posstring + l_posarray[I];
        S := 'UPDATE log_start SET meldung = ''' + posstring + ''' WHERE nr = ' + l_nr;
        {$IFNDEF SUPLOGSTAR}
        SQL_Insert(qUpdate, S);
        {$ENDIF}

        if fLogStages then
        begin
          Append(tf);
          WriteLn(tf, DateTimeToStr(now) + ' : ' + IntToStr(ANr));
          CloseFile(tf);
        end;
      end;
    except
    end;
  end;

  procedure SetInterrupt(BA: string);
  var
    BARumpf, S: string;
  begin
    BArumpf := GetBARumpf(BA);
    S := 'SELECT *'
            + ' FROM PA_ARBEITSGANG PAA'
            + ' LEFT JOIN pde p ON p.betriebsauftragnr = PAA.betriebsauftragnr'
            + ' WHERE paa.produktionsauftragnr = ''' + BArumpf + ''''
            + ' AND p.betriebsauftragnr <> ''' + BA + ''''
            + ' AND p.stat IN (0,1)';
    SQL_Get(qSuch, S);
    //Es gibt keine anderen laufenden Arbeitsgänge zu diesem Auftrag
    if (qSuch.IsEmpty) then
    begin
      S := 'UPDATE PA_Auftrag SET status = 5'
              + ' WHERE Produktionsauftragnr = ''' + BArumpf + '''';
      SQL_Insert(qUpdate, S);
    end;
  end;
begin

  if isZellenFertigung(qSuch) then
  begin
    if isZellenMaster(qSuch, Lizenz) then
    begin // Alle Maschinen holen und ebenfals starten
      SQLStr := 'SELECT lizenz FROM maschine WHERE maschgroupid = '
        + '(SELECT maschgroupid FROM maschine WHERE lizenz = '''
        + Lizenz + ''') AND lizenz <> ''' + Lizenz + '''';
      qZelle := TCO_Query.Create(Owner);
      try
        qZelle.Database := fOraSession;
        SQL_Get(qZelle, SQLStr);
        while not qZelle.EOF do
        begin
          Unterbrechen(qZelle.FieldByName('Lizenz').AsString);
          qZelle.Next;
        end;
        qZelle.Close;
      finally
        qZelle.Free;
      end;
    end;
  end;

  if isZellenFertigungSimultan then
  begin
    try
      fZellenfertigungSimultan := False;
      qZelle := TCO_Query.Create(Owner);
      qZelle.Database := fOraSession;
     // Nachsehen ob der Auftrag auf einer Maschine für Simultanfertigung läuft
      SQLStr := 'SELECT * FROM maschine WHERE ag_gruppe = '
      + ' (SELECT ag_gruppe FROM maschine WHERE lizenz = ''' + Lizenz + ''')'
      + ' AND ag_gruppe <> 0 AND not ag_gruppe is null';
      SQL_Get(qZelle, SQLStr);
      while not qZelle.Eof do
      begin
        Unterbrechen(qZelle.FieldByName('lizenz').AsString);
        qZelle.Next;
      end;
      qZelle.Close;
    finally
      fZellenfertigungSimultan := True;
      qZelle.Free;
    end
  end;

  if isProduktionsLinie(qSuch) then
  begin
    try
      qZelle := TCO_Query.Create(Owner);
      qZelle.Database := fOraSession;
      qZelle.SQL.Text := 'SELECT betriebsauftragnr FROM pde WHERE lizenz = ''' + Lizenz + ''' AND stat IN (0,1)';
      qZelle.Open;
    if not qZelle.IsEmpty then
      BetriebsauftragNr := qZelle.FieldByName('betriebsauftragnr').AsString;
    if isPLMaster(qZelle, BetriebsauftragNr, Lizenz) then
    begin
     SQLStr := 'SELECT lizenz, m_order FROM maschine '
        + ' LEFT JOIN prodlinename ON prodlinename.pl_name = ''' + GetBANrRaw(BetriebsauftragNr) + ''''
        + ' LEFT JOIN prodline ON prodline.maschnr = maschine.maschnr AND prodline.prodline_nr = prodlinename.nr'
        + ' WHERE prodline.ismaster = 0';
      try
        SQL_Get(qZelle, SQLStr);
        while not qZelle.EOF do
        begin
          Unterbrechen(qZelle.FieldByName('Lizenz').AsString);
          qZelle.Next;
        end;
        qZelle.Close;
      finally
        qZelle.Free;
      end;
    end;
    except
    end;
  end;

  SQLStr := 'SELECT betriebsauftragnr, stat FROM PDE WHERE lizenz = ''' + Lizenz
    + ''' AND stat IN (0,1)';
  SQL_Get(qSuch, SQLStr);
  if not qSuch.IsEmpty then
  begin
    BetriebsauftragNr := qSuch.FieldByName('betriebsauftragnr').AsString;
    if TCO_Setup.GetParamBool(qUpdate, 'INCL_WorkorderMustRunBeforeStop') then
      if qSuch.FieldByName('stat').AsInteger = 1 then
      begin
        Result := SetActionResult( Auftrag_nur_geruestet, l_nr) ;
        exit;
      end;
  end;

  if fLogStages then
  begin
    DateTimeToString(SQLStr,'yymmddhhnnss',now);
    AssignFile(tf, fLogStagesPath + BetriebsauftragNr + '_' + SQLStr +'.log');
    ReWrite(tf);
    WriteLn(tf, DateTimeToStr(now) + ' : Interrupt ' + BetriebsauftragNr);
    CloseFile(tf);
  end;

  logpos(0);
  Takt_Ist := 100;
  Takt_Diff := 0;
  Jetzt := Now;
  Result := 0;
  Werkzeug := 0;
  if fOraSession = nil then
  begin
    Result := SetActionResult( DatenbankName_nicht_definiert, l_nr);
    Exit;
  end;

  if Check_Lizenz_In_Pause(Lizenz) then
  begin
    Result := Maschine_Optimiert;
    Exit;
  end;

  logpos(1);

  if TCO_Setup.GetParamBool(qSuch,'INCL_RunningChangeOnPrintRequest') then
  begin
    if SQL2Get(qSuch,'RUnningchangeevents RCE INNER JOIN MASCHINE ON RCE.maschnr = maschine.maschid', 'Lizenz', Lizenz, 'Executed', '0', true) > 0 then
    begin
      if not fExecuteRC then
      begin
        Result := SetActionResult( Maschine_wartet_auf_FliegendenWechsel, l_nr);
        logpos(80);
        Exit;
      end;
    end;
  end;

  SQLStr := 'Select count(*) CNT from PDE where (Lizenz = ''' + Lizenz + ''') and ((stat = 0) or (stat = 1))';
  SQL_Get(qSuch, SQLStr);
  if qSuch.FieldByName('CNT').AsInteger > 0 then
  begin
    SQLStr := 'Select * from PDE where (Lizenz = ''' + Lizenz + ''') and ((stat = 0) or (stat = 1))';
    SQL_Get(qSuch, SQLStr);
    PDE_Nummer := qSuch.FieldByName('Nr').AsInteger;
    BetriebsauftragNr := qSuch.FieldByName('Betriebsauftragnr').AsString;
    ArtikelNr := qSuch.FieldByName('Auftragnr').AsString;
    Schwesterauftrag := qSuch.FieldByName('Schwesterauftrag').AsString;
    Takt_Soll := qSuch.FieldByName('Taktzeit').AsInteger;
    Kavitaet := qSuch.FieldByName('Kopfgroesse').AsInteger;
    Sollwert := Format_String(qSuch.FieldByName('Sollwert').AsString);
    Istwert := Format_String(qSuch.FieldByName('Istwert').AsString);
    Anfahr_Ausschuss := Format_String(qSuch.FieldByName('Anfahr_Ausschuss').AsString);
    StartDatumZeit := qSuch.FieldByName('StartDatumZeit').AsFloat;
    Ausschuss := qSuch.FieldByName('Ausschuss').AsInteger;
    (* RS 27.01.2015 - Quarder CZ: Wir korrigieren hier pde.masterauftrag, falls es nicht sauber ist*)
    MasterAuftrag := CheckMaster(BetriebsauftragNr, qSuch.FieldByName('MasterAuftrag').AsInteger = 1);

    Stat := qSuch.FieldByName('Stat').AsInteger;
    Optimiert := qSuch.FieldByName('Optimiert').AsInteger;
    Bezeichnung := qSuch.FieldByName('Bezeichnung').AsString;
    logpos(2);

    MinRunTime := TCO_Setup.GetParamInt(qUpdate, 'MDE_Zeit_zwischen_AuftragsStart_Ende') / 1440;
    if (MinRunTime > 0 ) then
    begin
      if (StartDatumZeit > Now) then
      begin
        SQL_Get(qSuch2, ' SELECT MAX(startdatum) StartDatumZeit'
                      + ' FROM  auftragstartprot '
                      + ' WHERE betriebsauftragnr = ''' + BetriebsauftragNr + ''''
                      + ' GROUP BY betriebsauftragnr');
        StartDatumZeit := qSuch2.FieldByName('StartDatumZeit').AsFloat;
      end;
      if Now - StartDatumZeit < MinRunTime then
      begin
        Result := SetActionResult( Kurze_Laufzeit, l_nr);
        logpos(80);
        Exit;
      end;
    end;

    SQLStr := 'Update RuestProt set'
      + ' RuestEnde = ' + FloatToPunktString(Jetzt) + ','
      + ' RuestIst = -1'
      + ' where Betriebsauftragnr = ''' + BetriebsauftragNr + ''' AND Ruestende = 0';
    SQL_Insert(qUpdate, SQLStr);
    SQLStr := 'Update RuestProt set'
      + ' RuestIst = round((ruestende-rueststart)*1440)'
      + ' where Betriebsauftragnr = ''' + BetriebsauftragNr + ''' AND RuestIst = -1';
    SQL_Insert(qUpdate, SQLStr);

    if (Stat = 0) and (Optimiert = 1) then
    begin
      SQLStr := 'insert into OptimierungsProt (Nr, Lizenz, BetriebsAuftragNr, AuftragNr, Bezeichnung,'
        + ' Istwert, StartDatumZeit, EndDatumZeit) values (OptimierungsProtId.NextVal,'
        + ' ''' + Lizenz + ''','
        + ' ''' + BetriebsauftragNr + ''','
        + ' ''' + ArtikelNr + ''','
        + ' ''' + Bezeichnung + ''','
        + ' ''' + IntToStr(Istwert) + ''','
        + FloatToPunktString(StartDatumZeit) + ','
        + FloatToPunktString(Jetzt) + ')';
      SQL_Insert(qUpdate, SQLStr);
      SQLStr := 'update OptimierungsProt set Dauer = Trunc((EndDatumZeit - StartDatumZeit)*1440)';
      SQL_Insert(qUpdate, SQLStr);
    end;
    logpos(3);

    if fOpt_WerkZeug then
    begin
      Werkzeug := qSuch.FieldByName('Werkzeug').AsInteger;
    end;
    logpos(4);

    if SQL2Get(qSuch, 'MASCHINF', 'Lizenz', Lizenz, 'Betriebsauftragnr', BetriebsauftragNr, True) > 0 then
    begin
      Maschinf_Nummer := qSuch.FieldByName('Nr').AsInteger;
      // Produziert := Format_String(qSuch.FieldByName('Stueck').AsString); Später steht Produziert := Istwert;
      Verpackt := Format_String(qSuch.FieldByName('Pack').AsString);
    end
    else
    begin
      Maschinf_Nummer := -1;
      // Produziert := 0; Später steht Produziert := Istwert;
      Verpackt := 0;
    end;
    logpos(5);

    SQLGet(qSuch, 'Maschine', 'Lizenz', Lizenz, False);
    Maschine := qSuch.FieldByName('Kennung').AsString;
    MaschNr := qSuch.FieldByName('Datenblock').AsInteger;

    AktSchuss := 0;
    SQLStr := 'SELECT istwert FROM signal_maschine WHERE maschnr = ' +  IntToStr(MaschNr)
      + ' AND signalnr IN (SELECT signalnr FROM signale WHERE signalart=2)';
    SQL_Get(qSuch, SQLStr);
    if not qSuch.IsEmpty then
      AktSchuss := qSuch.fieldByName('istwert').AsInteger;

    //    if FOpt_Metall then
    Produziert := Istwert; // Produziert soll IMMER aus PDE genommen werden. In Maschinf kann Anfahrausschuss stehen.
    SQL_Get(qSuch,' SELECT SUM(produziert) prod FROM TPM_SCHICHT WHERE Betriebsauftragnr = ''' + BetriebsauftragNr + '''');
    if not qSuch.IsEmpty then
      Produziert := qSuch.FieldByName('prod').AsInteger;

    if Produziert = 0 then
      Produziert := 1;
    if Kavitaet = 0 then
      Kavitaet := 1;

    if fOpt_WerkZeug then
    begin
      Error := Werkzeug_Abspannen(Werkzeug);
      if Error <> 0 then
        Result := SetActionResult( Error, l_nr) ;
    end;

    if not fRuestAusStillstand then
    begin
      if Stat = 1 then
      begin
        SQLStr := 'Update RuestProt set'
          + ' RuestEnde = ' + FloatToPunktString(Jetzt) + ','
          + ' RuestIst = -1'
          + ' where Betriebsauftragnr = ''' + BetriebsauftragNr + ''' AND Ruestende = 0';
        SQL_Insert(qUpdate, SQLStr);
      end;
      logpos(6);
    end;

    //Unteraufträge löschen
    SQLStr := 'delete from maschinf where LIZENZ = ''' + Lizenz + MASCHBEZ_UNTERAUFTRAG + '''';
    SQL_Insert(qUpdate, SQLStr);
    logpos(7);

    if FOption_Ruestzeit_Auftrag_Folgeauftrag then
    begin
      qSuch.Close;
      SQLStr := 'select schicht from tpm_schicht where nr = (select max(nr) from tpm_schicht)';
      SQL_Get(qSuch, SQLStr);
      Schicht := qSuch.FieldByName('Schicht').AsInteger;
      logpos(8);

      SQLStr := 'select COUNT(*) CNT from tpm_Stillog where ((Geht is NULL)OR (Geht = 0)) AND(maschnr = ''' +
        IntToStr(MaschNr) + ''')';
      SQL_Get(qSuch, SQLStr);
      if qSuch.FieldByName('CNT').AsInteger = 0 then
      begin
        SQLStr := 'SELECT TPM_StillogID.Nextval AS nval FROM setup';
        SQL_Get(qSuch2, SQLStr);
        Nummer2 := qSuch2.FieldByName('nval').AsInteger;
      end
      else
      begin
        //Zuerst anstehende Störungen beenden
        SQLStr := 'select * from tpm_Stillog where ((Geht is NULL)OR (Geht = 0)) AND(maschnr = ''' + IntToStr(MaschNr) + ''')';
        SQL_Get(qSuch, SQLStr);
        qSuch.First;
        while not qSuch.EOF do
        begin
          Nummer2 := qSuch.FieldByName('Nr').AsInteger;
          Dauer := Trunc((Jetzt - qSuch.FieldByName('Kommt').AsFloat) * 1440);
          if Dauer = 0 then
            Dauer := 1;

          UpdateSQLPunkt(qUpdate, 'tpm_Stillog', 'Geht', FloatToPunktString(Jetzt), 'Nr', IntToStr(Nummer2));
          UpdateSQL(qUpdate, 'tpm_Stillog', 'GehtStr', DateToStr(Date) + '  ' + TimeToStr(Frac(Jetzt)), 'Nr', IntToStr(Nummer2));
          UpdateSQL(qUpdate, 'tpm_Stillog', 'dauer', IntToStr(Dauer), 'Nr', IntToStr(Nummer2));
          UpdateSQL(qUpdate, 'tpm_Stillog', 'BetriebsauftragNr', BetriebsauftragNr, 'Nr', IntToStr(Nummer2));

          if not fSupressEvents then
          begin
            SQLStr := 'insert into ERPEvents (Nr, BetriebsAuftragNr, Event, Datumzeit)'
              + ' values (ERPEventsId.NextVal,'
              + '''' + IntToStr(Nummer2) + ''','
              + '''G'','
              + FloatToPunktString(Jetzt) + ')';
            SQL_Insert(qUpdate, SQLStr);
            qSuch.Next;
          end;
        end;
        logpos(9);

        SQLStr := 'SELECT TPM_StillogID.Nextval AS nval FROM(SELECT COUNT(*) FROM setup)';
        SQL_Get(qSuch2, SQLStr);
        Nummer2 := qSuch2.FieldByName('nval').AsInteger;
      end;
    end
    else //if Ruesten then
    begin
      qSuch.Close;
      SQLStr := 'select * from tpm_Stillog,tpm_stillstaende  where tpm_Stillog.Stillstandnr = tpm_stillstaende.Stillstandnr'
        + ' AND Gruppe = 1 AND (Geht is NULL OR Geht = 0) AND maschnr = ''' + IntToStr(MaschNr) + '''';
      SQL_Get(qSuch, SQLStr);
      logpos(10);
      qSuch.First;
      while not qSuch.EOF do
      begin
        Nummer2 := qSuch.FieldByName('Nr').AsInteger;
        Dauer := Trunc((Jetzt - qSuch.FieldByName('Kommt').AsFloat) * 1440);
        if Dauer = 0 then
          Dauer := 1;

        UpdateSQLPunkt(qUpdate, 'tpm_Stillog', 'Geht', FloatToPunktString(Jetzt), 'Nr', IntToStr(Nummer2));
        UpdateSQL(qUpdate, 'tpm_Stillog', 'GehtStr', DateToStr(Date) + '  ' + TimeToStr(Frac(Jetzt)), 'Nr', IntToStr(Nummer2));
        UpdateSQL(qUpdate, 'tpm_Stillog', 'dauer', IntToStr(Dauer), 'Nr', IntToStr(Nummer2));

        if not fSupressEvents then
        begin
          SQLStr := 'insert into ERPEvents (Nr, BetriebsAuftragNr, Event, Datumzeit)'
            + ' values (ERPEventsId.NextVal,'
            + '''' + IntToStr(Nummer2) + ''','
            + '''G'','
            + FloatToPunktString(Jetzt) + ')';
          SQL_Insert(qUpdate, SQLStr);
        end;

        qSuch.Next;
      end;
      logpos(11);
    end;

    // Wenn Block Stillstand, dann beenden den Stillstand
    SQLStr := 'select tpm_Stillog.Nr, tpm_Stillog.Kommt from tpm_Stillog, tpm_stillstaende'
      + ' where tpm_Stillog.Stillstandnr =  tpm_stillstaende.Stillstandnr AND BlockStillstand = 1 AND Geht = 0'
      + ' AND maschnr = ' + IntToStr(MaschNr);
    SQL_Get(qSuch, SQLStr);
    qSuch.First;
    while not qSuch.EOF do
    begin
      Nummer2 := qSuch.FieldByName('Nr').AsInteger;
      Dauer := Trunc((Jetzt - qSuch.FieldByName('Kommt').AsFloat) * 1440);
      if Dauer = 0 then
        Dauer := 1;

      UpdateSQLPunkt(qUpdate, 'tpm_Stillog', 'Geht', FloatToPunktString(Jetzt), 'Nr', IntToStr(Nummer2));
      UpdateSQL(qUpdate, 'tpm_Stillog', 'GehtStr', DateToStr(Date) + ' ' + TimeToStr(Frac(Jetzt)), 'Nr', IntToStr(Nummer2));
      UpdateSQL(qUpdate, 'tpm_Stillog', 'dauer', IntToStr(Dauer), 'Nr', IntToStr(Nummer2));
      qSuch.Next;
    end;

    // AuftragBuchen(BetriebsauftragNr, 0);  // es wird nach hinten geschoben. Sascha 11.03.2008

    //**********************************************************************
    //            SPC
    //**********************************************************************
    if FOpt_SPC then
    begin
      //      EingabeParam2Excel(Betriebsauftragnr, 'd:\comtas\SPC\');
      //      SQLSTR := 'DELETE from QSPCSTICH where AUFTRAGNR = ''' + Betriebsauftragnr + '''';
      //      SQL_Insert(qUpdate, SQLSTR);
      try
        SQLStr := 'select schicht from tpm_schicht where nr = (select max(nr) from tpm_schicht)';
        SQL_Get(qSuch, SQLStr);
        CO_SPC.Schicht := qSuch.FieldByName('Schicht').AsInteger;
        CO_SPC.MaschNr := MaschNr;
        CO_SPC.AuftragNr := BetriebsauftragNr;
        CO_SPC.SPC_Berechnung_Auftrag;

        SQLStr := 'DELETE from QSPC20 where Maschine = ''' + Lizenz + '''';
        SQL_Insert(qUpdate, SQLStr);
        SQLStr := 'DELETE from QSPC20PROT where Maschine = ''' + Lizenz + '''';
        SQL_Insert(qUpdate, SQLStr);
        logpos(12);
      except
      end;
    end;

    //**********************************************************************
    //            QS
    //**********************************************************************
    if SQLGet(qSuch, 'PRUEFPLAN', 'AuftragNr', ArtikelNr, True) > 0 then
    begin
      SQLStr := 'DELETE from Terminorder where Lizenz = ''' + Lizenz + ''' AND Bezeichnung Like ''QS%''';
      SQL_Insert(qUpdate, SQLStr);

      SQLStr := 'DELETE from BDA where Lizenz = ''' + Lizenz + ''' AND Bezeichnung Like ''QS%''';
      SQL_Insert(qUpdate, SQLStr);
    end;
    logpos(13);

    //**********************************************************************
    //            TAKTZEITEN
    //**********************************************************************
    if FOpt_TaktLog then
    begin
      SQLStr := 'SELECT AVG(TAKTZEIT) AS TAKT from Taktzeiten where AUFTRAGNR = ''' + BetriebsauftragNr + '''';
      SQL_Get(qSuch, SQLStr);
      qSuch.First;
      Takt_Ist := Round(qSuch.FieldByName('TAKT').AsFloat * 100);
      Takt_Diff := Takt_Ist - Takt_Soll;
      logpos(14);

      if (Takt_Ist > 1) and FOpt_SolltaktAenderung then
      begin
        if fFolgeAuftragTaktzeitUpdate then
        begin
          SQLStr := 'update pde set Taktzeit = ''' + IntToStr(Takt_Ist) + ''', TaktzeitStr = ''' + FloatToStr(Takt_Ist /
            100) + ''''
            + ' where Lizenz = ''' + Lizenz + ''' AND AuftragNr = ''' + ArtikelNr + '''';
          SQL_Insert(qUpdate, SQLSTR);  //Mentor (EIN)!!
        end;
      end;
      // else Takt_Ist := Takt_Soll;  20.08.03

     // Taktzeitprotokoll in Unterordner Taktzeitprotokolle ablegen

      if TCO_Setup.GetParamBool(qSuch, 'MDE_Export_Taktzeit_to_Excel') then
      try
        protpfad := ExtractFilePath(Application.ExeName);
        repeat
          Delete(protpfad, Length(protpfad), 1);
        until protpfad[Length(protpfad)] = '\';
        logpos(15);

        protpfad := protpfad + CO_AuftragGetL('Taktlog') + '\';

        if not DirectoryExists(protpfad) then
        try
          CreateDir(protpfad)
        except
        end;

        if not DirectoryExists(protpfad) then
          protpfad := ExtractFilePath(Application.ExeName);
        Takt2Excel(BetriebsauftragNr, protpfad, ArtikelNr);
      except
      end;
(*
      if not DirectoryExists(protpfad) then
        protpfad := ExtractFilePath(Application.ExeName);
      Takt2Excel(BetriebsauftragNr, protpfad, ArtikelNr);
*)
      // SQLStr := 'DELETE from Taktzeiten where AUFTRAGNR = ''' + BetriebsauftragNr + '''';
      SQLStr := 'DELETE from Taktzeiten where Lizenz = ''' + Lizenz + '''';
      SQL_Insert(qUpdate, SQLStr);
    end;
    logpos(16);

    // Erfassung / Berechnung der Auftrags Soll- und Istwerte
    SQLStr := 'Select sum(Stops) as Stops, Sum(A_geplant+A_ungeplant) as Downtime,'
      + ' Sum(A_Solllaufzeit) as SSollaufzeit, Sum(A_IstLaufzeit) as SIstlaufzeit,'
      + ' Avg(Leistung) as DLeistung, Avg(Qualitaet) as DQualitaet, sum(A_Ruesten) as Ruesten,'
      + ' Sum(verpackt) as verpackt '
      + ' from tpm_schicht'
      + ' where (betriebsauftragnr = ''' + BetriebsauftragNr + ''') ';
//      + ' and (datumzeit between ('
//      + FloatToPunktString(StartDatumZeit) + ') and (' + + FloatToPunktString(Jetzt) + '))';
    SQL_Get(qSuch, SQLStr);
    DownTime := qSuch.FieldByName('DownTime').AsInteger;
    Stops := qSuch.FieldByName('Stops').AsInteger;
    logpos(17);

    Auftrag_SolLlaufzeit := Round(Sollwert * (Takt_Soll / 100) / 60 / Kavitaet);
    Auftrag_IstLaufzeit := Round((Jetzt - StartDatumZeit) * 1440) - DownTime;
    Auftrag_DiffLaufzeit := Auftrag_IstLaufzeit - Auftrag_SolLlaufzeit;

    // Neuberechnung Nutzung, Qualität, Effektivität
    TPM_SollLaufzeit := qSuch.FieldByName('SSollaufzeit').AsInteger;
    if TPM_SollLaufzeit = 0 then
      TPM_SollLaufzeit := 1;
    TPM_IstLaufZeit := qSuch.FieldByName('SIstlaufzeit').AsInteger;

    Nutzung := TPM_IstLaufZeit / TPM_SollLaufzeit * 100;
    if Nutzung > 100 then
      Nutzung := 100;
    if Nutzung < 0 then
      Nutzung := 0;
    Leistung := qSuch.FieldByName('DLeistung').AsFloat;
    Qualitaet := (Produziert - Ausschuss) / Produziert * 100;
    if Qualitaet < 0 then
      Qualitaet := 0;
    if (Leistung > 0) and (Qualitaet > 0) then
      Effektivitaet := (Nutzung / 100) * (Leistung / 100) * Qualitaet
    else
      Effektivitaet := 0;
    logpos(18);

    try
      EndDatum := GetEndeDatumLizenz(Lizenz, BetriebsauftragNr, Now,
        Trunc((Sollwert - Istwert) * (Takt_Soll / 100) / 60 / Kavitaet));
    except
      EndDatum := Now + 2;
    end;

    SQLStr := 'Update PDE Set stat = 5,'
      + ' StartDatumzeit = ' + FloatToPunktString(Now) + ','
      + ' EndDatumZeit = ' + FloatToPunktString(EndDatum) + ','
      + ' Status = ''' + CO_AuftragGetL('unterbrochen') + ''','
      + ' Optimiert = 0'
      + ' where Nr = ' + IntToStr(PDE_Nummer);
    SQL_Insert(qUpdate, SQLStr);
    logpos(19);

    if not FOpt_TaktLog then
      if Produziert > 0 then
      begin
        Takt_Ist := Round(Auftrag_IstLaufzeit * 60 * 100 / Produziert);
        Takt_Diff := Takt_Ist - Takt_Soll;
      end;

    if not FOpt_Metall then
    begin
      SQLStr := 'Update PDE Set SOLL_GEPLANT = ''' + IntToStr(Sollwert) + ''' where Nr = ' + IntToStr(PDE_Nummer);
      SQL_Insert(qUpdate, SQLStr);
      SQLStr := 'Update PDE Set Sollwert = ''' + IntToStr(Sollwert - Istwert) + ''' where Nr = ' + IntToStr(PDE_Nummer);
      //SQL_Insert(qUpdate, SQLSTR);
    end;
    logpos(20);

    if Maschinf_Nummer > 0 then
    begin
      SQLStr := 'Update MASCHINF Set stat = 2 where Nr = ' + IntToStr(Maschinf_Nummer); // Nr ist nicht eindeutlich. !!!!!
      SQL_Insert(qUpdate, SQLStr);
    end;
    logpos(21);

    SQLStr := 'Delete from BDA where Lizenz = ''' + Lizenz
      + ''' AND (Signal <> ''' + CO_AuftragGetL('Betriebsstunden') + ''') and (Signal <> ''Termin'')';
    if fDontDeleteBDAFromSignals then
      SQLStr := SQLStr + 'AND (signal not in (SELECT to_char(signalnr) FROM SIGNALE))';
    SQL_Insert(qUpdate, SQLStr);
    logpos(22);

    if (SQL2Get(qSuch, 'AARCHIV', 'Maschine', Maschine, 'BetriebsAuftragnr', BetriebsauftragNr, True) > 0) then
    begin
      qSuch.First;
      while not qSuch.EOF do
      begin
        if (qSuch.FieldByName('EndDatumStr').AsString = CO_AuftragGetL('läuft'))
          or (qSuch.FieldByName('EndDatumStr').AsString = CO_AuftragGetL('Rüsten')) then
        begin
          Nummer2 := qSuch.FieldByName('Nr').AsInteger;
          //               else if Ruestzeit < qSuch.FieldByName('RuestzeitIST').AsInteger then RuestZeit := qSuch.FieldByName('RuestzeitIST').AsInteger;
          SQLStr := 'update AARCHIV set '
            + 'EndDatumZeit =     ' + FloatToPunktString(Jetzt)
            + ',EndDatumStr =   ''' + GetDatumZeitString(Jetzt)
            + ''',ProduziertINT = ''' + IntToStr(Produziert)
            + ''',ProduziertSTR = ''' + IntToStr(Produziert)
            + ''',SollvorgabeINT = ''' + IntToStr(Sollwert)
            + ''',Sollvorgabe = ''' + IntToStr(Sollwert)
            + ''',LaufzeitSoll = ''' + IntToStr(Auftrag_SolLlaufzeit)
            + ''',LaufzeitIst = ''' + IntToStr(Auftrag_IstLaufzeit)
            + ''',LaufzeitDiff = ''' + IntToStr(Auftrag_DiffLaufzeit)
            + ''',Werkzeug = ''' + IntToStr(Werkzeug)
            + ''',TaktzeitSoll = ''' + IntToStr(Takt_Soll)
            + ''',TaktzeitIst = ''' + IntToStr(Takt_Ist)
            + ''',TaktzeitDiff = ''' + IntToStr(Takt_Diff)
            + ''',StopsINT = ''' + IntToStr(Stops)
            + ''',AusschussPRZ = ''' + IntToStr(100 - Round(Qualitaet))
            + ''',VerpacktINT = ''' + IntToStr(Verpackt)
            + ''',StillstandINT = ''' + IntToStr(DownTime)
            + ''',Schwesterauftrag = ''' + Schwesterauftrag
            + ''',Nutzung = ' + FloatToPunktString(Nutzung)
            + ',Leistung = ' + FloatToPunktString(Leistung)
            + ',Qualitaet = ' + FloatToPunktString(Qualitaet)
            + ',Effektivitaet = ' + FloatToPunktString(Effektivitaet)
            + ',Ausschuss = ''' + IntToStr(Ausschuss)
            + ''',Kavitaet = ''' + IntToStr(Kavitaet)
            + ''',Change_Art = ''U'
            + ''' where (Nr = ''' + IntToStr(Nummer2) + ''')';
          SQL_Insert(qUpdate, SQLStr);
          logpos(24);

          SQLStr := 'update AARCHIV set '
            + ' Anfahr_Ausschuss = ''' + IntToStr(Anfahr_Ausschuss)
            + ''' where (Nr = ''' + IntToStr(Nummer2) + ''')';
          SQL_Insert(qUpdate, SQLStr);

          logpos(25);

          {Begin INCLUDE CO_AuftragKUnterbrechen.pas}
          if MasterAuftrag then
          begin
            SQLGet(qSuch2, 'PDEKombi', 'MasterBetriebsAuftragNr', BetriebsauftragNr, False);
            while not qSuch2.EOF do
            begin
              SQLStr := 'update AARCHIV set '
                + 'EndDatumZeit =     ' + FloatToPunktString(Jetzt)
                + ',EndDatumStr =   ''' + GetDatumZeitString(Jetzt)
                + ''',ProduziertINT = ''' + qSuch2.FieldByName('IstWert').AsString
                + ''',ProduziertSTR = ''' + qSuch2.FieldByName('IstWert').AsString + CO_AuftragGetL(' Artikel')
                + ''',SollvorgabeINT = ''' + qSuch2.FieldByName('SollWert').AsString
                + ''',Sollvorgabe = ''' + qSuch2.FieldByName('SollWert').AsString + CO_AuftragGetL(' Artikel')
                + ''',LaufzeitSoll = ''' + IntToStr(Auftrag_SolLlaufzeit)
                + ''',LaufzeitIst = ''' + IntToStr(Auftrag_IstLaufzeit)
                + ''',LaufzeitDiff = ''' + IntToStr(Auftrag_DiffLaufzeit)
                + ''',Werkzeug = ''' + IntToStr(Werkzeug)
                + ''',TaktzeitSoll = ''' + IntToStr(Takt_Soll)
                + ''',TaktzeitIst = ''' + IntToStr(Takt_Ist)
                + ''',TaktzeitDiff = ''' + IntToStr(Takt_Diff)
                + ''',StopsINT = ''' + IntToStr(Stops)
                + ''',AusschussPRZ = CASE produziertInt WHEN 0 THEN ''' + IntToStr(100 - Round(Qualitaet))
                + ''' ELSE to_char(ROUND(ausschuss*100/produziertInt,2)) END '
                + ',VerpacktINT = ''' + IntToStr(Verpackt)
                + ''',StillstandINT = ''' + IntToStr(DownTime)
                + ''',Schwesterauftrag = ''' + Schwesterauftrag
                + ''',Nutzung = ' + FloatToPunktString(Nutzung)
                + ',Leistung = ' + FloatToPunktString(Leistung)
                + ',Qualitaet = CASE produziertInt WHEN 0 THEN ''' + FloatToStr(Qualitaet)
                + ''' ELSE to_char(ROUND((produziertint-ausschuss)*100/produziertInt,2)) END '
                + ',Effektivitaet = ' + FloatToPunktString(Effektivitaet)
                //                + ',Ausschuss = ''' + IntToStr(Ausschuss)
              + ',Kavitaet = ''' + qSuch2.FieldByName('Kavitaet').AsString
                + ''',Change_Art = ''U'
                + ''' where (BetriebsAuftragNr = ''' + qSuch2.FieldByName('BetriebsAuftragNr').AsString + ''')';
              SQL_Insert(qUpdate, SQLStr);
              qSuch2.Next;
            end;
          end;
          {Ende INCLUDE CO_AuftragKUnterbrechen.pas}

        end;
        qSuch.Next;
      end;
      logpos(26);
    end;

    // nicht benützt
    //    SQLStr := 'INSERT INTO AStart (Nr,Lizenz,Signal)'
    //      + 'VALUES(AStartID.NextVal'
    //      + ',''' + Lizenz
    //      + ''',''' + CO_AuftragGetL('Stückzahl Maschine')
    //      + ''')';
    //    SQL_Insert(qUpdate, SQLStr);
    //    logpos(27);

    SQLStr := 'delete from MDE_VER where Lizenz = ''' + Lizenz + ''' AND SignalKod = 0';
    SQL_Insert(qUpdate, SQLStr);
    logpos(28);

    if fOpt_WerkZeug then
      CheckWerkzeugAarchiv(BetriebsauftragNr);

    InsertOfflineMaschinen(Lizenz);

    if not fSupressEvents then
    begin

      SQLStr := 'select Count(*) as CNT from ERPEvents'
        + ' where BetriebsAuftragNr = ''' + BetriebsauftragNr + ''''
        + ' and Event = ''U''';
      SQL_Get(qUpdate, SQLStr);
      if qUpdate.FieldByName('CNT').AsInteger = 0 then
      begin
        SQLStr := 'insert into ERPEvents (Nr, BetriebsAuftragNr, Event, Datumzeit)'
          + ' values (ERPEventsId.NextVal,'
          + '''' + BetriebsauftragNr + ''','
          + '''U'','
          + FloatToPunktString(Jetzt) + ')';
        SQL_Insert(qUpdate, SQLStr);
      end;
    end;
    logpos(29);
    Maschinf_Kein_Auftrag(Lizenz);
    // Nur wenn Auftrag nicht im Rüsten ist
    if Stat <> 1 then
      StoreInterruptSignals(IntToStr(Maschnr), BetriebsauftragNr);
    AuftragBuchen(BetriebsauftragNr, 0); // Stückzahl Abnullen muss ganz am Ende stehen. Sascha. 11.03.2008

    SQLStr := 'update Maschine set StueckMaschine0 = ' + IntToStr(Istwert) + ' where Lizenz = ''' + Lizenz + '''';
    SQL_Insert(qUpdate, SQLStr);
  end
  else
    Result := SetActionResult( Auftrag_nicht_gefunden, l_nr);
  (* // Wenn ein Auftrag unterbrochen ist und wird erneut unterbrochen kann hier verzweigt werden
  begin
    SQLStr := 'Select count(* ) CNT from PDE where (Lizenz = ''' + Lizenz + ''')';
    SQL_Get(qSuch, SQLStr);
    if qSuch.FieldByName('cnt').AsInteger = 0 then
      Result := Auftrag_nicht_gefunden
    else
      Result :=
  end;
  *)
  //**************************************************************************
  //   LaufzeitLog
  //**************************************************************************
  logpos(30);

  // Höchsten Eintrag suchen und Laufzeit berechnen
  SQLStr := 'SELECT * FROM LaufzeitLog WHERE nr = '
    + ' (SELECT MAX(nr) FROM LaufzeitLog WHERE Betriebsauftragnr = '''
    + BetriebsauftragNr + ''')';
  SQL_Get(qSuch, SQLStr);
  if not qSuch.IsEmpty then
  begin
    if qSuch.FieldByName('AuftragStart').AsFloat = 0 then
      SQLStr := 'UPDATE LaufzeitLog SET AuftragStart = '+ FloatToPunktString(Jetzt)
        + ', AuftragEnde = ' + FloatToPunktString(Jetzt) + ', Ruestzeit = '''
        + IntToStr(Round((Jetzt - qSuch.FieldByName('RuestStart').AsFloat) * 1440))
        + ''' WHERE nr = ' + qSuch.FieldByName('nr').AsString
    else
      SQLStr := 'UPDATE LaufzeitLog SET AuftragEnde = ' + FloatToPunktString(Jetzt)
        + ', Laufzeit = '''
        + IntToStr(Round((Jetzt - qSuch.FieldByName('AuftragStart').AsFloat) * 1440))
        + ''' WHERE nr = ' + qSuch.FieldByName('nr').AsString;
    SQL_Insert(qUpdate, SQLStr);
    logpos(31);

    // Martin. Was ist das? Wie kann man die Laufzeit aus Schichtprotokoll holen?
    // Im Schichtprotokoll ist die Zeit Maschinen bezogen. Sascha. 23.05.2008
    try
      if fRuestAusStillstand then
      begin // Wenn Ruestzeiten aus dem Stillstandsprot erzeugt werden, dann aus Ruestprot die Gesamtruestzeit holen
        SQLStr := 'UPDATE laufzeitlog SET gesamtlaufzeit = '
          + '(SELECT((SELECT SUM(laufzeit) FROM laufzeitlog  WHERE betriebsauftragnr = '''
          + BetriebsauftragNr + ''') - (SELECT '
          + 'DECODE(sum(solllaufzeit) - SUM(istlaufzeit),null,0,sum(solllaufzeit) - '
          + 'SUM(istlaufzeit)) '
          + 'FROM tpm_schicht WHERE betriebsauftragnr = ''' + BetriebsauftragNr + '''))'
          + 'FROM setup), '
          + 'gesamtruestzeit = (SELECT SUM(ruestist) FROM ruestprot WHERE'
          + ' betriebsauftragnr = ''' + BetriebsauftragNr + ''') '
          + 'WHERE betriebsauftragnr = ''' + BetriebsauftragNr + '''';
      end
      else
      begin
        SQLStr := 'UPDATE laufzeitlog SET gesamtlaufzeit = '
          + '(SELECT((SELECT SUM(laufzeit) FROM laufzeitlog  WHERE betriebsauftragnr = '''
          + BetriebsauftragNr + ''') - (SELECT '
          + 'DECODE(sum(solllaufzeit) - SUM(istlaufzeit),null,0,sum(solllaufzeit) - '
          + 'SUM(istlaufzeit)) '
          + 'FROM tpm_schicht WHERE betriebsauftragnr = ''' + BetriebsauftragNr + '''))'
          + 'FROM setup), '
          + 'gesamtruestzeit = (SELECT SUM(ruestzeit) FROM laufzeitlog WHERE'
          + ' betriebsauftragnr = ''' + BetriebsauftragNr + ''') '
          + 'WHERE betriebsauftragnr = ''' + BetriebsauftragNr + '''';
      end;
      SQL_Insert(qUpdate, SQLStr);
      logpos(32);
    except
    end;
    try

      if fLaufzeitLog then
      begin
        SQLStr := 'SELECT MAX(ll.gesamtlaufzeit) lz, MAX(ll.gesamtruestzeit) rz, '
          + ' MAX(decode(aa.laufzeitsoll,null,0,aa.laufzeitsoll)) ls, '
          + ' MAX(decode(aa.ruestzeitsoll,null,0,aa.ruestzeitsoll)) rs '
          + ' FROM laufzeitlog ll, aarchiv aa  WHERE '
          + ' ll.betriebsauftragnr = aa.betriebsauftragnr and ll.betriebsauftragnr = '
          + '''' + BetriebsauftragNr + '''';
        SQL_Get(qSuch, SQLStr);
        if not qSuch.IsEmpty then
        begin
          SQLStr := 'UPDATE aarchiv SET ruestzeitist = ''' + qSuch.FieldByName('rz').AsString
            + ''', ruestzeitdiff = '''
            + IntToStr(qSuch.FieldByName('rz').AsInteger - qSuch.FieldByName('rs').AsInteger)
            + ''' WHERE betriebsauftragnr = ''' + BetriebsauftragNr + '''';
          SQL_Insert(qUpdate, SQLStr);
          logpos(33);
          if TCO_Setup.GetParamBool(qSuch,'INCL_Update_Masterdata_JobStop') then
          begin
            fTLaufzeit := TCO_Laufzeit.Create(qSuch2);
            fTLaufzeit.BetriebsauftragNr := BetriebsauftragNr;
            SQLStr := 'UPDATE aarchiv SET laufzeitist = ' + IntToStr(fTLaufzeit.Laufzeit)
              + ', laufzeitsoll = ' +  IntToStr(fTLaufzeit.SollLaufzeitArchiv)
              + ', laufzeitdiff = '+  IntToStr(fTLaufzeit.Laufzeit - fTLaufzeit.SollLaufzeitArchiv)
              + ', taktzeitsoll = '+  IntToStr(round(fTLaufzeit.SollTakt * 100))
              + ', taktzeitist = '+  IntToStr(round(fTLaufzeit.IstTakt * 100))
              + ', taktzeitdiff = '+  IntToStr(round((fTLaufzeit.IstTakt - fTLaufzeit.SollTakt) * 100))
              + ', Nutzung = ' + FloatToPunktString(fTLaufzeit.Nutzung)
              + ', Leistung = ' + FloatToPunktString(fTLaufzeit.Leistung)
              + ', Qualitaet = ' + FloatToPunktString(fTLaufzeit.Qualitaet)
              + ', Effektivitaet = ' + FloatToPunktString(fTLaufzeit.OEE) + ' WHERE betriebsauftragnr = ''' + BetriebsauftragNr + ''''
              + ' OR masterauftrag =  ''' + BetriebsauftragNr + '''';

            SQL_Insert(qUpdate, SQLStr);
            fTLaufzeit.Destroy;
          end
          else
          begin
            SQLStr := 'UPDATE aarchiv SET laufzeitist = ''' + qSuch.FieldByName('lz').AsString
              + ''', laufzeitdiff = '''
              + IntToStr(qSuch.FieldByName('lz').AsInteger - qSuch.FieldByName('ls').AsInteger)
              + ''' WHERE betriebsauftragnr = ''' + BetriebsauftragNr + '''';
            SQL_Insert(qUpdate, SQLStr);

            logpos(34);
          end;
        end;
      end;
    except
    end;
  end;

  SQLStr := 'UPDATE laufzeitlog SET gesamtlaufzeit = ' + IntToStr(GetAuftragLaufZeit(qSuch, qSuch2, BetriebsauftragNr))
    + ' WHERE betriebsauftragnr = ''' + BetriebsauftragNr + '''';
  SQL_Insert(qUpdate, SQLStr);


  if SQLGet(qSuch, 'Laufzeitlog', 'BetriebsauftragNr', BetriebsauftragNr, True) > 0 then
  begin
      fTLaufzeit := TCO_Laufzeit.Create(qSuch2);
      fTLaufzeit.BetriebsauftragNr := BetriebsauftragNr;
      SQLStr := 'UPDATE aarchiv SET laufzeitist = ' + IntToStr(fTLaufzeit.Laufzeit)
        + ', laufzeitsoll = ' +  IntToStr(fTLaufzeit.SollLaufzeitArchiv)
        + ', laufzeitdiff = '+  IntToStr(fTLaufzeit.Laufzeit - fTLaufzeit.SollLaufzeitArchiv)
        + ', taktzeitsoll = '+  IntToStr(round(fTLaufzeit.SollTakt * 100))
        + ', taktzeitist = '+  IntToStr(round(fTLaufzeit.IstTakt * 100))
        + ', taktzeitdiff = '+  IntToStr(round((fTLaufzeit.IstTakt - fTLaufzeit.SollTakt) * 100))
        + ' WHERE betriebsauftragnr = ''' + BetriebsauftragNr + ''''
        + ' OR masterauftrag =  ''' + BetriebsauftragNr + '''';
      SQL_Insert(qUpdate, SQLStr);


    if TCO_Setup.GetParamBool(qSuch,'INCL_Update_Masterdata_JobStop') then
    begin
     SQLStr := 'UPDATE pdestamm SET solltaktstr = ''' + FloatToStr(fTLaufzeit.SollTakt)
        + ''', solltaktzeit = ' +  IntToStr(Round(fTLaufzeit.SollTakt * 100))
        + ' WHERE auftragnr = ''' + fTLaufzeit.ArtikelNr + '''' ;
      SQL_Insert(qUpdate, SQLStr);
    end
    else
    begin
      SQLStr := 'UPDATE aarchiv SET laufzeitist = ''' + qSuch.FieldByName('Gesamtlaufzeit').AsString + ''''
        + ' where Betriebsauftragnr = ''' + BetriebsauftragNr + '''';
      SQL_Insert(qUpdate, SQLStr);
    end;
     fTLaufzeit.Destroy;

   end;
  logpos(35);

  if TCO_Setup.GetParamBool(qCount, 'JobSetupAndRestart') then
  begin
    try
      ResetJobdata(BetriebsauftragNr, MaschNr);
      logpos(36);
    except
    end;
  end;

  // Charge checken
  SQLStr := 'SELECT nr FROM chargen WHERE lizenz = ''' + Lizenz
    + ''' AND betriebsauftragnr = ''' + BetriebsauftragNr
    + ''' AND enddatumzeit =0 ORDER BY startdatumzeit';
  SQL_Get(qSuch2, SQLStr);
  if not qSuch2.IsEmpty then
  begin
    SQLStr := 'UPDATE chargen SET enddatumzeit = ' + FloatToPunktString(Now)
      + ', schussende = ' + IntToStr(AktSchuss)
      + ' WHERE nr = ' + qSuch2.FieldByName('nr').AsString;
    SQL_Insert(qUpdate, SQLStr);
  end;
   logpos(37);
  CheckWerkzeug(Lizenz, BetriebsauftragNr);

  try
    SetInterrupt(Betriebsauftragnr);
    logpos(38);
    if MasterAuftrag then
    begin
      SQLGet(qSuch2, 'PDEKombi', 'MasterBetriebsAuftragNr', BetriebsauftragNr, False);
      while not qSuch2.EOF do
      begin
        SetInterrupt(qSuch2.FieldByName('Betriebsauftragnr').AsString);
        qSuch2.Next;
      end;
    end;
    logpos(39);
  except
  end;

  fExecuteRC := false;

  logpos(80);
  SetActionResult( 0, l_nr)
end;

function TCO_Auftrag.KavProt_Insertf(BANr: string; Alt, Neu: Integer): Integer;
begin
  KavProt_Insert(BANr, Alt, Neu);
end;


function TCO_Auftrag.Buchen(Lizenz : string; BetriebsauftragNr : string; Stueck:Integer; Bediener : string; D: Real = 0):Integer;
var soll, ist, diff, schicht, stat : Integer;
  artikel, bezeichnung, s :string;
begin


  s := 'SELECT auftragnr, bezeichnung, sollwert, istwert, stat FROM pde WHERE betriebsauftragnr = ''' + BetriebsauftragNr +'''';
  qSuch.SQL.Text := s;
  qSuch.Open;
  if qSuch.IsEmpty then
    exit;

  soll := qSuch.FieldByName('sollwert').AsInteger;
  ist := qSuch.FieldByName('istwert').AsInteger;
  stat := qSuch.FieldByName('stat').AsInteger;
  artikel := qSuch.FieldByName('auftragnr').AsString;
  bezeichnung := qSuch.FieldByName('bezeichnung').AsString;
  qSuch.Close;


  diff := stueck;
  ist := ist + stueck;

  if soll = 0 then
    soll := 1;

  s := 'UPDATE maschinf SET stueck = ' + IntToStr(ist) + ', Istwert_Prz = '''
    + IntTostr( Ist * 100 div Soll) + ' %'' WHERE betriebsauftragnr = '''
    + BetriebsauftragNr + '''';
  qUpdate.SQL.Text := s;
  qUpdate.ExecSQL;

  s := 'UPDATE pde SET istwert = ' + IntToStr(ist) + ', Ist_prz = '''
    + IntToStr(Ist * 100 div Soll) + ''' WHERE betriebsauftragnr = '''
    + BetriebsauftragNr + '''';
  qUpdate.SQL.Text := s;
  qUpdate.ExecSQL;

  s := 'UPDATE aarchiv SET ProduziertInt = ' + IntToStr(ist) + ', ProduziertStr = '
    + IntToStr(ist) + ' WHERE betriebsauftragnr = ''' + BetriebsauftragNr + '''';
  qUpdate.SQL.Text := s;
  qUpdate.ExecSQL;

  if stat < 2 then
    AuftragBuchen(BetriebsauftragNr, ist);

  if D = 0 then
  begin
    D := Now;
    s := 'select Schicht from TPM_SCHICHT where nr = (select max(nr) from TPM_SCHICHT)';
  end
  else
  begin
    S := 'SELECT ABS(datumzeit - ' + FloatToPunktString(D) + ') dtdiff, Schicht'
       + ' FROM TPM_SCHICHT'
       + ' ORDER BY ABS(datumzeit - ' + FloatToPunktString(D) + ')';
  end;

  try
    SQL_Get(qSuch, s);
    Schicht := qSuch.FieldByName('Schicht').AsInteger;
  except
    Schicht := 1;
  end;
  qSuch.Close;
  s := 'INSERT INTO MENGE_BUCH_PROT (Nr,Maschine,BETRIEBSAUFTRAGNR,Mengeges,menge,Einheit,'
        + ' DatumZeitStr,DatumZeit,Etikett,Name,Schicht,Status)'
        + 'VALUES(MENGE_BUCH_PROTID.NextVal'
        + ',''' + Lizenz
        + ''',''' + BetriebsauftragNr

        + ''',''' + IntTostr(ist)
        + ''',''' + IntToStr(diff)
        + ''',''' + 'Stck.'
        + ''',''' + DateTimeToStr(D)
        + ''',' + FloatToPunktString(D)
        + ','''
        + ''',''' + Bediener
        + ''',''' + IntToStr(Schicht)
        + ''',''' + CO_AuftragGetL('Übergeben')
        + ''')';
      SQL_Insert(qUpdate, s);

      S := 'insert into BuchungsProt (Nr, BETRIEBSAUFTRAGNR, AUFTRAGNR,'
        + ' BEZEICHNUNG, LIZENZ, MENGE,'
        + ' WERT1, WERT2, BEDIENER, DATUM, Schicht, EINTRAGDATUM)'
        + ' values (BuchungsProtId.NextVal,'
        + ' ''' + BetriebsauftragNr + ''','
        + ' ''' + artikel + ''','
        + ' ''' + bezeichnung + ''','
        + ' ''' + Lizenz + ''','
        + ' ''' + IntTostr(diff) + ''','
        + ' ''' + IntToStr(Ist-diff) + ''','
        + ' ''' + IntToStr(ist) + ''','
        + ' ''' + Bediener + ''','
        + FloatToPunktString(D) + ','
        + ' ''' + IntToStr(Schicht) + ''','
        + FloatToPunktString(Now)
        + ')';
      SQL_Insert(qUpdate, S);
end;


function TCO_Auftrag.GeplantLoeschen(aAuftrag: string): Integer;
var
  S: string;
begin // Gucken ob AUftrag vorhanden ist.
  // Wenn ja löschen
  // Wenn nein Fehlermeldung
  S := 'SELECT stat FROM pde WHERE betriebsauftragnr = ''' + aAuftrag + '''';
  SQL_Get(qSuch, S);
  if qSuch.IsEmpty then
  begin
    Result := Auftrag_nicht_gefunden;
    Exit;
  end;
  if qSuch.FieldByName('stat').AsInteger <> 2 then
  begin
    Result := Auftrag_nicht_gefunden;
    Exit;
  end;

  S := 'SELECT betriebsauftragnr FROM pde WHERE betriebsauftragnr = ''' + aAuftrag + '''';
  SQL_Get(qSuch, S);
  if qSuch.IsEmpty then
    Result := Auftrag_nicht_gefunden
  else
  begin
    S := 'DELETE FROM pde WHERE betriebsauftragnr = ''' + aAuftrag + '''';
    try
      SQL_Insert(qUpdate, S);
      Result := 0;
    except
      Result := Auftrag_nicht_gefunden;
    end;
  end;
end;

function TCO_Auftrag.UngeplantLoeschen(aAuftrag: string): Integer;
var
  S: string;
begin // Gucken ob AUftrag vorhanden ist.
  // Wenn ja löschen
  // Wenn nein Fehlermeldung
  S := 'SELECT stat FROM pde WHERE betriebsauftragnr = ''' + aAuftrag + '''';
  SQL_Get(qSuch, S);
  if qSuch.IsEmpty then
  begin
    Result := Auftrag_nicht_gefunden;
    Exit;
  end;
  if qSuch.FieldByName('stat').AsInteger <> 2 then
  begin
    Result := Auftrag_nicht_gefunden;
    Exit;
  end;

  S := 'SELECT betriebsauftragnr FROM pdeneu WHERE betriebsauftragnr = ''' + aAuftrag + '''';
  SQL_Get(qSuch, S);
  if qSuch.IsEmpty then
    Result := Auftrag_nicht_gefunden
  else
  begin
    S := 'DELETE FROM pdeneu WHERE betriebsauftragnr = ''' + aAuftrag + '''';
    try
      SQL_Insert(qUpdate, S);
      Result := 0;
    except
      Result := Auftrag_nicht_gefunden;
    end;
  end;
end;

function TCO_Auftrag.GetBARumpf(BA: string): string;
begin
  if(Pos('POS', BA) > 0) then
    result := Copy(BA, 0, Pos('POS', BA) - 1)
  else
    result := BA;
end;

function TCO_Auftrag.Starten(Lizenz: string; BetriebsauftragNr: string; Ruesten: Boolean; StartDatumZeit: TDateTime = 0): Integer;
var
  VorgaengerAuftrag : string;
  SQLStr: string;
  HalbAuto: Boolean;
  Status, dummy: string;
  StatInt, Tmp: Integer;
  Werkzeug, Nummer, Kopfgroesse, KavSoll, Solltakt, ERPSoll, ERPSollKav: Integer;
  SollStueck, Programm_Nr, Istwert: Integer;
  ArtikelNummer, Schwesterauftrag: string;
  Arbeitsgang, Packgroesse, Bezeichnung: string;
  MaterialNr, WerkzeugNr, Maschine: string;
  EndDatum: TDateTime;
  ToleranzInt: Integer;
  PDEDiffNr, SollRuestzeit: Integer;
  Termin1, Termin2, Termin3: Real;
  MinRunTime, EndeVorgaenger: Real;
  RuestzeitIST, RuestzeitDiff: Integer;
  Termin_Bez: string;
  I: Integer;
  Termin: Real;
  RNR, ZustandInt, status_alt: Integer;
  MaschNr: string;
  Dauer: Integer;
  Schicht: Integer;
  Name, PersonalNr: string;
  Prot_Nr: Integer;
  Prot_Start_Ruest: Real;
  A_Gang: string;
  Betriebsauftrag, Layout: string;
  Druckbeschreibung: string;
  MasterAuftrag: Boolean;
  ANFAHR_AUSSCHUSS, Schuss, SignalNr, Ausschuss: Integer;
  Sollausstoss, Istausstoss: Real;
  Stueck_nach_Kilo, Meter_nach_kilo: Real;
  Etikett_Prod: string;
  ETIKETT_CHNR: string;
  KundenReferenz2: string;
  ETIKETT_UN_ZULASSUNG: string;
  Layout2, Etikett1, Etikett2, Etikett3: string;
  Etikett4, Etikett5, Etikett6, EAN13: string;
  Etikett7, Etikett8, Etikett9, EAN128, Kunde: string;
  OfflineMaschine: Boolean;
  ZH: Char;
  RuestZeit, Nummer2: Integer;
  aarchivnr: string;
  AktiveKavitaet: string;
  qZelle: TCO_Query;
  l_nr: string;
  l_posarray: array[0..80] of Char;
  Ruesten_laufender_Auftrag: Boolean;
  Stueckzahl_laufender_Auftrag_nicht_abnullen: Boolean;
  Spannzeit, InsertStill: Boolean;
  SollSpannzeit: Integer;
  SpannzeitToleranz: Integer;
  tf : TextFile;
  verpackt : integer;
  Lagerort : integer;
  VarKav : Integer;
  AStartDatumZeit: TDateTime;

  procedure logpos(ANr: Integer);
  var
    S, posstring, MNr: string;
    I: Integer;
    C: Char;
  begin
    try
      if Ruesten then
        C := 'R'
      else
        C := 'S';
      if fAuftrag_Optimieren then
        C := 'O';

      if ANr = 0 then
      begin

        S := 'SELECT log_startid.nextval nval FROM setup WHERE nr = 1';
        SQL_Get(qSuch, S);

        l_nr := qSuch.FieldByName('nval').AsString;

        S := 'SELECT maschnr FROM maschine WHERE lizenz = ''' + Lizenz + '''';
        SQL_Get(qSuch, S);
        MNr := qSuch.FieldByName('maschnr').AsString;
        if MNr = '' then
          MNr := '0';
        l_posarray[0] := C;
        for I := 1 to 80 do
          l_posarray[I] := '_';

        S := 'INSERT INTO log_start (Nr,Datumzeit ,Betriebsauftragnr, maschnr, lizenz) VALUES '
          + '('
          + l_nr + ', '''
          + DateTimeToStr(Now) + ''', '''
          + BetriebsauftragNr + ''', '
          + '''' + MNr + ''', '''
          + Lizenz + ''')';
        SQL_Insert(qUpdate, S);
      end
      else
      begin
        l_posarray[ANr] := IntToStr(ANr mod 10)[1];
        posstring := C + ' ';
        for I := 1 to 80 do
          posstring := posstring + l_posarray[I];
        S := 'UPDATE log_start SET meldung = ''' + posstring + ''' WHERE nr = ' + l_nr;
        {$IFNDEF SUPLOGSTAR}
        SQL_Insert(qUpdate, S);
        {$ENDIF}
      end;
        if fLogStages then
        begin
          try
            System.Append(tf);
          except
            Rewrite(tf);
          end;
          WriteLn(tf, DateTimeToStr(now) + ' : ' + IntToStr(ANr));
          CloseFile(tf);
        end;
    except
    end;
  end;

  procedure SetStart(BA: string; stat: integer);
  var
    BArumpf, S: string;
  begin
    BArumpf := GetBaRumpf(BA);

    S := 'UPDATE PA_Auftrag SET Startdatumzeit = ' + FloatToPunktString(Now)
            + ' WHERE Status = 2 AND Produktionsauftragnr = '''
            + BArumpf + '''';
    SQL_Insert(qUpdate, S);
    S := 'UPDATE PA_Auftrag SET Status = '
            + IntToStr(stat)
            + ' WHERE STATUS > ' + IntToStr(stat)
            + ' AND Produktionsauftragnr = '''
            + BArumpf + '''' ;
    SQL_Insert(qUpdate, S);

  end;

begin
  if isZellenFertigung(qSuch) then
  begin
    if isZellenMaster(qSuch, Lizenz) then
    begin // Alle Maschinen holen und ebenfals starten
      SQLStr := 'SELECT lizenz, maschnr FROM maschine WHERE maschgroupid = '
        + '(SELECT maschgroupid FROM maschine WHERE lizenz = ''' + Lizenz + ''') AND lizenz <> ''' + Lizenz + '''';
      qZelle := TCO_Query.Create(Owner);
      try
        qZelle.Database := fOraSession;
        SQL_Get(qZelle, SQLStr);
        while not qZelle.EOF do
        begin
          Starten(qZelle.FieldByName('Lizenz').AsString, BetriebsauftragNr + '_'
            + qZelle.FieldByName('maschnr').AsString, Ruesten, StartDatumZeit);
          qZelle.Next;
        end;
        qZelle.Close;
      finally
        qZelle.Free;
      end;
    end;
  end;

  if isZellenFertigungSimultan then
  begin
    try
      fZellenfertigungSimultan := False;
      qZelle := TCO_Query.Create(Owner);
      qZelle.Database := fOraSession;
     // Nachsehen ob der Auftrag auf einer Maschine für Simultanfertigung läuft
      SQLStr := 'SELECT * FROM maschine WHERE ag_gruppe = '
      + ' (SELECT ag_gruppe FROM maschine WHERE lizenz = ''' + Lizenz + ''')'
      + ' AND ag_gruppe <> 0 AND not ag_gruppe is null';
      SQL_Get(qZelle, SQLStr);
      while not qZelle.Eof do
      begin
        dummy := Copy(BetriebsauftragNr , 1, POS('POS', BetriebsauftragNr)-1);
        dummy := dummy + 'POS' + qZelle.FieldByName('AFO').AsString;
        if qZelle.FieldByName('ag_gr_id').AsInteger > 0 then
          dummy := dummy + '.' +qZelle.FieldByName('ag_gr_id').AsString;
        if dummy <> BetriebsauftragNr then
          Starten(qZelle.FieldByName('lizenz').AsString, dummy, Ruesten, StartDatumZeit);
        qZelle.Next;
      end;
      qZelle.Close;
    finally
      fZellenfertigungSimultan := True;
      qZelle.Free;
    end
  end;

  if isProduktionsLinie(qSuch) then
  begin
    try
      qZelle := TCO_Query.Create(Owner);
      qZelle.Database := fOraSession;
      if isPLMaster(qZelle, BetriebsauftragNr, Lizenz) then
      begin
        SQLStr := 'SELECT lizenz, m_order FROM maschine '
          + ' LEFT JOIN prodlinename ON prodlinename.pl_name = ''' + GetBANrRaw(BetriebsauftragNr) + ''''
          + ' LEFT JOIN prodline ON prodline.maschnr = maschine.maschnr AND prodline.prodline_nr = prodlinename.nr'
          + ' WHERE prodline.ismaster = 0';
        try
          SQL_Get(qZelle, SQLStr);
          while not qZelle.EOF do
          begin
            Starten(qZelle.FieldByName('Lizenz').AsString, GetBANrRaw(BetriebsauftragNr) + '_POS'
              + qZelle.FieldByName('m_order').AsString, Ruesten, StartDatumZeit);
            qZelle.Next;
          end;
          qZelle.Close;
        finally
          qZelle.Free;
        end;
      end;
    except
    end;
  end;

  if fLogStages then
  begin
    DateTimeToString(SQLStr,'yymmddhhnnss',now);
    AssignFile(tf, fLogStagesPath + BetriebsauftragNr + '_' + SQLStr +'.log');
    ReWrite(tf);
    WriteLn(tf, DateTimeToStr(now) + ' : Start ' + BetriebsauftragNr);
    CloseFile(tf);
  end;


  logpos(0);
  StartDatumZeit := Now;

  Result := 0;
  if fOraSession = nil then
  begin
    Result := SetActionResult( DatenbankName_nicht_definiert, l_nr);
    logpos(80);
    Exit;
  end;
  logpos(1);

  if Check_Lizenz_In_Pause(Lizenz) then
  begin
    Result := SetActionResult( Maschine_Optimiert, l_nr);
    logpos(80);
    Exit;
  end;

  if TCO_Setup.GetParamBool(qSuch,'INCL_RunningChangeOnPrintRequest') then
  begin
    if SQL2Get(qSuch,'RUnningchangeevents RCE INNER JOIN MASCHINE ON RCE.maschnr = maschine.maschid', 'Lizenz', Lizenz, 'Executed', '0', true) > 0 then
    begin
      if not fExecuteRC then
      begin
        Result := SetActionResult( Maschine_wartet_auf_FliegendenWechsel, l_nr);
        logpos(80);
        Exit;
      end;
    end;
  end;


  SQL_Insert(qUpdate, 'UPDATE maschine SET bypass = 0 WHERE lizenz = ''' + Lizenz + '''');

  logpos(2);

  SQLStr := 'Select Count(*) CNT from PDE where Lizenz = ''' + Lizenz + ''' and BetriebsAuftragNr = ''' + BetriebsauftragNr + '''';
  SQL_Get(qSuch, SQLStr);
  if qSuch.FieldByName('CNT').AsInteger = 0 then
  begin
    Result := SetActionResult( Auftrag_nicht_gefunden, l_nr);
    logpos(80);
    Exit;
  end;

  if SQLGet(qSuch, 'AArchiv', 'BetriebsAuftragNr', BetriebsauftragNr, True) > 0 then
  begin
    AStartDatumZeit := qSuch.FieldByName('StartDatumZeit').AsFloat;
    MinRunTime := TCO_Setup.GetParamInt(qUpdate, 'MDE_Zeit_zwischen_AuftragsStart_Ende') / 1440;
    if (MinRunTime > 0 ) then
    begin
      if (AStartDatumZeit > Now) then
      begin
        SQL_Get(qSuch2, ' SELECT MAX(startdatum) StartDatumZeit'
                      + ' FROM  auftragstartprot '
                      + ' WHERE betriebsauftragnr = ''' + BetriebsauftragNr + ''''
                      + ' GROUP BY betriebsauftragnr');
        AStartDatumZeit := qSuch2.FieldByName('StartDatumZeit').AsFloat;
      end;
      if Now - AStartDatumZeit < MinRunTime then
      begin
        Result := SetActionResult( Kurze_Laufzeit, l_nr);
        logpos(80);
        Exit;
      end;
    end;
  end;

  if not fAuftrag_Optimieren then
  begin
    SQLStr := 'Select Count(*) CNT from PDE where Lizenz = ''' + Lizenz + ''' and BetriebsAuftragNr = '''
      + BetriebsauftragNr + ''' and Stat = 0 and Optimiert = 1';
    SQL_Get(qSuch, SQLStr);
    if qSuch.FieldByName('CNT').AsInteger = 1 then
    begin
      SQLStr := 'update PDE set Optimiert = 0 where BetriebsAuftragNr = ''' + BetriebsauftragNr + '''';
      SQL_Insert(qUpdate, SQLStr);
      logpos(3);

      SQLStr := 'select * from PDE where BetriebsAuftragNr = ''' + BetriebsauftragNr + '''';
      SQL_Get(qSuch, SQLStr);
      logpos(4);

      status_alt := qSuch.FieldByName('stat').AsInteger;

      SQLStr := 'insert into OptimierungsProt (Nr, Lizenz, BetriebsAuftragNr, AuftragNr, Bezeichnung,'
        + ' Istwert, StartDatumZeit, EndDatumZeit) values (OptimierungsProtId.NextVal,'
        + ' ''' + qSuch.FieldByName('Lizenz').AsString + ''','
        + ' ''' + BetriebsauftragNr + ''','
        + ' ''' + qSuch.FieldByName('AuftragNr').AsString + ''','
        + ' ''' + qSuch.FieldByName('Bezeichnung').AsString + ''','
        + ' ''' + qSuch.FieldByName('Istwert').AsString + ''','
        + ' ''' + qSuch.FieldByName('Startdatumzeit').AsString + ''','
        + FloatToPunktString(StartDatumZeit) + ')';
      SQL_Insert(qUpdate, SQLStr);
      logpos(5);
      SQLStr := 'update OptimierungsProt set Dauer = Trunc((EndDatumZeit - StartDatumZeit)*1440)';
      SQL_Insert(qUpdate, SQLStr);
      logpos(6);

      Result := SetActionResult(0 , l_nr);
      logpos(80);
      Exit;
    end;
  end;

  Ruesten_laufender_Auftrag := TCO_Setup.GetParamBool(qSuch, 'CGI_WS_Ruesten_laufender_Auftrag');
  Stueckzahl_laufender_Auftrag_nicht_abnullen := TCO_Setup.GetParamBool(qSuch, 'Stueckzahl_laufender_Auftrag_nicht_abnullen');

  if SQL2Get(qSuch, 'PDE', 'Lizenz', Lizenz, 'stat', '0', True) > 0 then
  begin
    if (not Ruesten_laufender_Auftrag) or (qSuch.FieldByName('BetriebsauftragNr').AsString <> BetriebsauftragNr) then
    begin
      Result := SetActionResult( Maschine_nicht_frei, l_nr);
      logpos(80);
      Exit;
    end;
    Unterbrechen(Lizenz);
    Starten(Lizenz, BetriebsauftragNr, Ruesten);
    logpos(78);
    logpos(79);
    logpos(80);
    Exit;
  end;

  logpos(7);

  if SQL2Get(qSuch, 'PDE', 'Lizenz', Lizenz, 'stat', '1', True) > 0 then
  begin
    if UpperCase(qSuch.FieldByName('BetriebsauftragNr').AsString) <> UpperCase(BetriebsauftragNr) then
    begin
      Result := SetActionResult(Anderer_Auftrag_wird_geruestet , l_nr);
      logpos(80);
      Exit;
    end;
  end;
  logpos(8);

  if SQL2Get(qSuch, 'PDE', 'BetriebsauftragNr', BetriebsauftragNr, 'Terminiert', '1', True) > 0 then
  begin
    Result := SetActionResult( Auftrag_terminiert, l_nr);
    logpos(80);
    Exit;
  end;
  logpos(9);

  OfflineMaschine := False;
  if SQLGet(qSuch, 'MASCHOFFLINE', 'Lizenz', Lizenz, True) > 0 then
    OfflineMaschine := True;
  logpos(10);

  if OfflineMaschine then
  begin
    SQLStr := 'Select Lizenz, MaschNr from MaschOffline where Lizenz = ''' + Lizenz + '''';
    SQL_Get(qSuch, SQLStr);
    Maschine := qSuch.FieldByName('Lizenz').AsString;
    MaschNr := qSuch.FieldByName('MaschNr').AsString;
  end
  else
  begin
    SQLStr := 'Select Kennung, Datenblock, spannzeittol from Maschine where Lizenz = ''' + Lizenz + '''';
    SQL_Get(qSuch, SQLStr);
    Maschine := qSuch.FieldByName('Kennung').AsString;
    MaschNr := qSuch.FieldByName('Datenblock').AsString;
    SpannzeitToleranz := qSuch.FieldByName('spannzeittol').AsInteger;
  end;
  logpos(11);

  try
    // Probleme bei Stückbuchung und sofortigem beenden des Auftrags (Phoenix) 30.01.2009 Len
    SQL_Insert(qUpdate, 'DELETE FROM SIGNAL_SCHREIBEN'
                        + ' WHERE maschnr = ''' + MaschNr + ''''
                        + ' AND signalnr NOT IN ('
                        + ' SELECT signalnr'
                        + ' FROM SIGNALE'
                        + ' WHERE SIGNALART IN ('
                        + IntToStr(CLABELRESET) + '))');
  except
  end;
  //Differenz suchen (Differenzliste)
  //Es wird nur ein einzelnere Auftrag gesucht, mögliche wären natürlich n Aufträge
  //-> Rosti verlangt nur einen...
  SQLStr := 'select * from PDE where Lizenz = ''' + Lizenz + ''' Order by Startdatumzeit';
  SQL_Get(qSuch, SQLStr);
  if qSuch.FieldByName('BetriebsauftragNr').AsString <> BetriebsauftragNr then
    PDEDiffNr := qSuch.FieldByName('Nr').AsInteger
  else
    PDEDiffNr := 0;
  logpos(12);

  SQLStr := 'select Name, PersonalNr from Personalanmeldung order by DatumZeit Desc';
  SQL_Get(qSuch, SQLStr);
  try
    Name := qSuch.FieldByName('Name').AsString;
    PersonalNr := qSuch.FieldByName('PersonalNr').AsString;
  except
    Name := '';
    PersonalNr := '';
  end;

  if FOption_Ruestzeit_Auftrag_Folgeauftrag and not OfflineMaschine then
  begin
    if SQLGet(qSuch, 'AARCHIV', 'Maschine', Lizenz, True) > 0 then
    begin
      SQL_Get(qSuch, 'select * from aarchiv where Maschine = ''' + Lizenz + ''' order by enddatumzeit desc');
      qSuch.First;
      try
        if not qSuch.EOF then
          //EndeDatum des letzten Auftrages
          EndeVorgaenger := StrToFloat(qSuch.FieldByName('enddatumzeit').AsString)
        else
          EndeVorgaenger := StartDatumZeit;
      except
        EndeVorgaenger := StartDatumZeit;
      end;
    end
    else
      EndeVorgaenger := StartDatumZeit;
    logpos(13);

    Tmp := Trunc(Date + 1);

    try
      RuestzeitIST := ZeitInMinuten(Lizenz, EndeVorgaenger, StartDatumZeit);
    except
      RuestzeitIST := 0;
    end;

    if RuestzeitIST < 0 then
      RuestzeitIST := Trunc((StartDatumZeit - EndeVorgaenger) * 1440);
    logpos(14);

    SQLStr := 'select * from PDE where Lizenz = ''' + Lizenz + ''' AND BetriebsauftragNr = '''
      + BetriebsauftragNr + '''';
    SQL_Get(qSuch, SQLStr);
    try
      Werkzeug := Format_String(qSuch.FieldByName('Werkzeug').AsString);
      SollRuestzeit := Format_String(qSuch.FieldByName('Ruestzeit').AsString);
    except
      Werkzeug := 0;
      SollRuestzeit := 0;
    end;
    logpos(15);


    if not fRuestAusStillstand then
    begin
      SQLStr := 'Insert into RuestProt (Nr, BetriebsAuftragNr, Name, PersonalNr, RuestStart,'
        + ' RuestIst, RuestEnde, RuestSoll, Lizenz, Werkzeug) values (RuestProtId.NextVal,'
        + '''' + BetriebsauftragNr + ''','
        + '''' + Name + ''','
        + '''' + PersonalNr + ''','
        + FloatToPunktString(EndeVorgaenger) + ','
        + FloatToPunktString(StartDatumZeit) + ','
        + '''-1'','
        + '''' + IntToStr(SollRuestzeit) + ''','
        + '''' + Lizenz + ''','
        + '''' + IntToStr(Werkzeug) + ''''
        + ')';
      SQL_Insert(qUpdate, SQLStr);
      logpos(16);
    end;

    logpos(17);
    //*****************************************************

    SQLStr := 'select * from tpm_Stillog where ((Geht is NULL) OR (Geht = 0)) AND (maschnr = ''' + MaschNr + ''')';
    SQL_Get(qSuch, SQLStr);
    qSuch.First;
    while not qSuch.EOF do
    begin
      Nummer := qSuch.FieldByName('Nr').AsInteger;
      Dauer := Trunc((StartDatumZeit - qSuch.FieldByName('Kommt').AsFloat) * 1440);
      if Dauer = 0 then
        Dauer := 1;


      UpdateSQLPunkt(qUpdate, 'tpm_Stillog', 'Geht', FloatToPunktString(StartDatumZeit), 'Nr', IntToStr(Nummer));
      UpdateSQL(qUpdate, 'tpm_Stillog', 'GehtStr', DateToStr(Date) + '  ' + TimeToStr(Frac(StartDatumZeit)), 'Nr',
        IntToStr(Nummer));
      UpdateSQL(qUpdate, 'tpm_Stillog', 'dauer', IntToStr(Dauer), 'Nr', IntToStr(Nummer));

      if not fSupressEvents then
      begin
        SQLStr := 'insert into ERPEvents (Nr, BetriebsAuftragNr, Event, Datumzeit)'
          + ' values (ERPEventsId.NextVal,'
          + '''' + IntToStr(Nummer) + ''','
          + '''G'','
          + FloatToPunktString(StartDatumZeit) + ')';
        SQL_Insert(qUpdate, SQLStr);

      end;
      qSuch.Next;
    end; //while not Daten.qSuch.EOF do begin
    logpos(18);

  end
  else
  begin
    RuestzeitIST := 0;
    if fLaufzeitLog then
    begin
      SQLStr := 'SELECT MAX(ll.gesamtlaufzeit) lz, MAX(ll.gesamtruestzeit) rz, '
        + ' MAX(decode(aa.laufzeitsoll,null,0,aa.laufzeitsoll)) ls, '
        + ' MAX(decode(aa.ruestzeitsoll,null,0,aa.ruestzeitsoll)) rs '
        + ' FROM laufzeitlog ll, aarchiv aa  WHERE '
        + ' ll.betriebsauftragnr = aa.betriebsauftragnr and ll.betriebsauftragnr = '
        + '''' + BetriebsauftragNr + '''';
      SQL_Get(qSuch, SQLStr);
      if not qSuch.IsEmpty then
      begin
        RuestzeitIST := qSuch.FieldByName('rz').AsInteger;
        SQLStr := 'UPDATE aarchiv SET ruestzeitist = ''' + IntToStr(RuestzeitIST)
          + ''', ruestzeitdiff = '''
          + IntToStr(qSuch.FieldByName('rz').AsInteger - qSuch.FieldByName('rs').AsInteger)
          + ''' WHERE betriebsauftragnr = ''' + BetriebsauftragNr + '''';
        SQL_Insert(qUpdate, SQLStr);
        logpos(19);
      end
    end
    else
    begin
      SQLStr := 'select * from tpm_Stillog, tpm_stillstaende where tpm_Stillog.Stillstandnr = (tpm_stillstaende.Stillstandnr)'
        + ' AND (Gruppe = 1) AND ((Geht is NULL)OR (Geht = 0)) AND(maschnr = ''' + MaschNr + ''')';
      SQL_Get(qSuch, SQLStr);
      qSuch.First;
      while not qSuch.EOF do
      begin
        try
          RuestzeitIST := ZeitInMinuten(Lizenz, qSuch.FieldByName('Kommt').AsFloat, StartDatumZeit);
        except
          RuestzeitIST := 0;
        end;
        qSuch.Next;
      end;
      logpos(19);
    end;
  end;

  SQLStr := 'select * from PDE where Lizenz = ''' + Lizenz + ''' AND BetriebsauftragNr = ''' + BetriebsauftragNr + '''';
  SQL_Get(qSuch, SQLStr);
  logpos(20);

  if qSuch.FieldByName('Stat').AsInteger = 3 then
  begin
    Result := SetActionResult( Auftrag_terminiert, l_nr) ;
    logpos(80);
    Exit;
  end;

  HalbAuto := qSuch.FieldByName('Betriebsart').AsString = CO_AuftragGetL('Halbautomatik');
  logpos(21);





  ToleranzInt := fTaktVergleichToleranz;
  if fTaktzeitkontrolleStammdaten then
  begin
    if SQLGet(qSuch2, 'PDEStamm', 'AuftragNr', qSuch.FieldByName('AuftragNr').AsString, True) > 0 then
      ToleranzInt := qSuch2.FieldByName('TAKTZEIT_TOLERANZ').AsInteger;
  end
  else
    if HalbAuto then
      ToleranzInt := 35
    else
      ToleranzInt := GetTaktzeitToleranz;
  logpos(22);

  if not (qSuch.FieldByName('stat').AsInteger = stStartRuestenInt) then
  begin
    if Ruesten then
    begin
      Status := CO_AuftragGetL('Rüsten');
      StatInt := stStartRuestenInt;
      Ruesten := True;
    end
    else
    begin
      Status := CO_AuftragGetL('läuft');
      StatInt := stLaeuftInt;
      Ruesten := False;
    end;
  end
  else
  begin
    if not Ruesten then
      SchliesseRuesteintrag(BetriebsauftragNr, Lizenz);

    Status := CO_AuftragGetL('läuft');
    StatInt := stLaeuftInt;
    Ruesten := False;
  end;
  logpos(23);

  SQLStr := 'select * from PDE where Lizenz = ''' + Lizenz + ''' AND BetriebsauftragNr = ''' + BetriebsauftragNr + '''';
  SQL_Get(qSuch, SQLStr);
  if fOpt_WerkZeug then
  begin
    if not (qSuch.FieldByName('stat').AsInteger = stStartRuestenInt) then
    begin
      Werkzeug := qSuch.FieldByName('Werkzeug').AsInteger;
      Tmp := Werkzeug_Ruesten(Werkzeug, Lizenz, BetriebsauftragNr);
      if Tmp <> 0 then
      begin
        Result := SetActionResult( Tmp, l_nr);
        logpos(80);
        Exit;
      end;
    end;
  end;
  logpos(24);

  try
      if SQLGet(qSuch2, 'Pde_termine', 'Betriebsauftragnr', BetriebsauftragNr, true) > 0 then
      begin
        if not (qSuch2.FieldByName('ERSTERSTART_DATUMZEIT').AsFloat > 0) then
        begin
          SQLStr := 'UPDATE pde_termine '
          + ' SET ERSTERSTART_DATUMZEIT = ' +  FloatToPunktString(Now)
          + ', ERSTERSTART_PLANSTART = ' +  FloatToPunktString(qSuch.FieldByName('startdatumzeit').AsFloat)
          + ', ERSTERSTART_PLANENDE = ' +  FloatToPunktString(qSuch.FieldByName('Enddatumzeit').AsFloat)
          + ', ERSTERSTART_LIZENZ = ''' +  qSuch.FieldByName('Lizenz').AsString
          + ''' WHERE betriebsauftragnr = ''' + BetriebsauftragNr + '''';
          SQL_Insert(qUpdate, SQLStr);
          logpos(67);
        end
        else
          logpos(68);
      end
      else
      begin
        SQLStr := 'INSERT INTO pde_termine (NR, BETRIEBSAUFTRAGNR, ERSTERSTART_DATUMZEIT,'
                + ' ERSTERSTART_LIZENZ, ERSTERSTART_PLANSTART, ERSTERSTART_PLANENDE)'
                + ' VALUES (pde_termineid.nextval, ''' + BetriebsauftragNr + ''','
                +  FloatToPunktString(Now) + ', ''' + qSuch.FieldByName('Lizenz').AsString + ''', ' +  FloatToPunktString(qSuch.FieldByName('startdatumzeit').AsFloat) + ', '
                +  FloatToPunktString(qSuch.FieldByName('Enddatumzeit').AsFloat) + ')';
          SQL_Insert(qUpdate, SQLStr);
        logpos(69);
      end;
    except
    end;

  Nummer := qSuch.FieldByName('Nr').AsInteger;
  ArtikelNummer := qSuch.FieldByName('AuftragNr').AsString;
  Schwesterauftrag := qSuch.FieldByName('Schwesterauftrag').AsString;
  Bezeichnung := qSuch.FieldByName('Bezeichnung').AsString;
  Arbeitsgang := qSuch.FieldByName('Arbeitsgang').AsString;
  Packgroesse := qSuch.FieldByName('Packgroesse').AsString;
  Kopfgroesse := Format_String(qSuch.FieldByName('Kopfgroesse').AsString);
  if Kopfgroesse = 0 then
    Kopfgroesse := 1;
  VarKav :=  qSuch.FieldByName('Var_Kavitaet').AsInteger;
  Solltakt := qSuch.FieldByName('Taktzeit').AsInteger;
  SollStueck := Format_String(qSuch.FieldByName('Sollwert').AsString);
  Istwert := Format_String(qSuch.FieldByName('Istwert').AsString);

  Anfahr_Ausschuss := Format_String(qSuch.FieldByName('Anfahr_Ausschuss').AsString);
  Ausschuss := qSuch.FieldByName('Ausschuss').AsInteger;
  Programm_Nr := qSuch.FieldByName('Programm_Nr').AsInteger;
  MaterialNr := IntToStr(qSuch.FieldByName('Material').AsInteger);
  SollRuestzeit := Format_String(qSuch.FieldByName('Ruestzeit').AsString);
  RuestzeitDiff := RuestzeitIST - SollRuestzeit;
  Termin1 := qSuch.FieldByName('Termin1').AsFloat;
  Termin2 := qSuch.FieldByName('Termin2').AsFloat;
  Termin3 := qSuch.FieldByName('Termin3').AsFloat;
  RNR := qSuch.FieldByName('RNR').AsInteger;
  Werkzeug := qSuch.FieldByName('Werkzeug').AsInteger;
  A_Gang := qSuch.FieldByName('A_Gang').AsString;
  Betriebsauftrag := qSuch.FieldByName('Betriebsauftrag').AsString;
  (* RS 27.01.2015 - Quarder CZ: Wir korrigieren hier pde.masterauftrag, falls es nicht sauber ist*)
  MasterAuftrag := CheckMaster(BetriebsauftragNr, qSuch.FieldByName('MasterAuftrag').AsInteger = 1);

  try
    if qSuch.FieldByName('pack').IsNull then
      verpackt := 0
    else
      verpackt := qSuch.FieldByName('pack').AsInteger;
  except
    verpackt := 0;
  end;

  Sollausstoss := qSuch.FieldByName('Sollausstoss').AsFloat;
  Stueck_nach_Kilo := qSuch.FieldByName('Stueck_nach_Kilo').AsFloat;
  Meter_nach_kilo := qSuch.FieldByName('Meter_nach_kilo').AsFloat;
  Layout := qSuch.FieldByName('Layout').AsString;

  Etikett_Prod := qSuch.FieldByName('Etikett_Prod').AsString;
  ETIKETT_CHNR := qSuch.FieldByName('ETIKETT_CHNR').AsString;
  KundenReferenz2 := qSuch.FieldByName('KundenReferenz2').AsString;
  ETIKETT_UN_ZULASSUNG := qSuch.FieldByName('ETIKETT_UN_ZULASSUNG').AsString;

  Druckbeschreibung := qSuch.FieldByName('Druckbeschreibung').AsString;
  Layout2 := qSuch.FieldByName('Layout2').AsString;
  EAN13 := qSuch.FieldByName('EAN13').AsString;
  EAN128 := qSuch.FieldByName('EAN128').AsString;
  Etikett1 := qSuch.FieldByName('Etikett1').AsString;
  Etikett2 := qSuch.FieldByName('Etikett2').AsString;
  Etikett3 := qSuch.FieldByName('Etikett3').AsString;
  Etikett4 := qSuch.FieldByName('Etikett4').AsString;
  Etikett5 := qSuch.FieldByName('Etikett5').AsString;
  Etikett6 := qSuch.FieldByName('Etikett6').AsString;
  Etikett7 := qSuch.FieldByName('Etikett7').AsString;
  Etikett8 := qSuch.FieldByName('Etikett8').AsString;
  Etikett9 := qSuch.FieldByName('Etikett9').AsString;
  Kunde := qSuch.FieldByName('Kunde').AsString;
  KavSoll := qSuch.FieldByName('Kavitaet_soll').AsInteger;
  ERPSoll := qSuch.FieldByName('ERPSollwert').AsInteger;
  ERPSollKav := qSuch.FieldByName('ERPSollKavitaet').AsInteger;
  If KavSoll < 0 then
    KavSoll := Kopfgroesse;

  Lagerort := qSuch.fieldByName('Lagerort').AsInteger;
  try
    SollSpannzeit := qSuch.FieldByName('SOLLSPANNZEITSTK').AsInteger;
  except
    SollSpannzeit := 0;
  end;

  SQLStr := 'Select WerkzeugNr from Werkzeug where Werkzeug = ''' + IntToStr(Werkzeug) + '''';
  SQL_Get(qSuch, SQLStr);
  WerkzeugNr := qSuch.FieldByName('WerkzeugNr').AsString;
  logpos(25);

  try
   i := Trunc((Solltakt / 100) * SollStueck / (60 * Kopfgroesse));
    EndDatum := GetEndeDatumLizenz(Lizenz, BetriebsauftragNr, StartDatumZeit, i);
  except
    EndDatum := StartDatumZeit + 2;
  end;
  logpos(26);

  SQLStr := 'Update PDE set Status = ''' + Status + ''' , EnddatumZeit = ' + FloatToPunktString(EndDatum)
    + ', StartDatumStr = ''' + GetDatumZeitString(StartDatumZeit) + ''''
    + ', StartDatumZeit = ' + FloatToPunktString(StartDatumZeit) + ', EndDatumStr = ''' + GetDatumZeitString(EndDatum) +
    ''''
    + ', LTStr = ''' + GetDatumZeitString(EndDatum) + ''', LTDatumZeit = ' + FloatToPunktString(EndDatum)
    + ', Diff = ''0 min'', StatusDiff = ''OK'', Stat = ' + IntToStr(StatInt)
    + ', Erzeugt = ''0'', Change_Art = ''B'''
    + ', Istwert = ''' + IntToStr(Istwert) + ''''
    + ' Where Nr = ''' + IntToStr(Nummer) + '''';
  SQL_Insert(qUpdate, SQLStr);
  logpos(27);

  logpos(28);

  logpos(29);

  if fAuftrag_Optimieren then
  begin
    SQLStr := 'update PDE set Optimiert = 1, Status = ''' + CO_AuftragGetL('optimieren')
      + ''' where Nr = ''' + IntToStr(Nummer) + '''';
    SQL_Insert(qUpdate, SQLStr);
  end;
  logpos(30);

  // Wenn Auftrag im Archiv vorhanden ist, dann, Nr merken und bei erfolgtem INSERT löschen
  aarchivnr := '0';
  if SQLGet(qSuch, 'AARchiv', 'Betriebsauftragnr', BetriebsauftragNr, True) > 0 then
    aarchivnr := qSuch.FieldByName('Nr').AsString;
  logpos(31);

  SQLStr := 'INSERT INTO AArchiv (Nr,Maschine,RNR,'
    + ' BetriebsauftragNr,AuftragNr,Bezeichnung,Arbeitsgang,A_Gang,PDENR,'
    + ' Betriebsauftrag,WerkzeugNr,Werkzeug,MaterialNr,MaterialMenge,Dauer,'
    + ' StartDatumZeit,EndDatumZeit,StartDatumStr,EndDatumStr,'
    + ' Sollvorgabe, SollvorgabeINT,ProduziertInt,Programm_Nr,PackGroesse,'
    + ' Taktzeitsoll, Ruestzeitsoll,Ruestzeitist, RuestzeitDiff, Kavitaet,'
    + ' Schwesterauftrag, Ausschuss, ANFAHR_AUSSCHUSS,Sollausstoss,Layout,'
    + ' Druckbeschreibung, Stueck_nach_Kilo,Meter_nach_kilo,'
    + ' Etikett_Prod, ETIKETT_CHNR, KundenReferenz2, Kunde, ETIKETT_UN_ZULASSUNG,'
    + ' Layout2, EAN13, EAN128, Etikett1, Etikett2, Etikett3,'
    + ' Etikett4, Etikett5, Etikett6, Etikett7, Etikett8, Etikett9, Aktive_Kavitaet, lagerort,'
    + ' Termin1, Termin2, Termin3, kavitaet_soll, ERPSollwert, ERPSollKavitaet, Var_Kavitaet'
    + ') VALUES (AArchivID.NextVal'
    + ',''' + Maschine
    + ''',''' + IntToStr(RNR)
    + ''',''' + BetriebsauftragNr
    + ''',''' + ArtikelNummer
    + ''',''' + Bezeichnung
    + ''',''' + Arbeitsgang
    + ''',''' + A_Gang
    + ''',''' + IntToStr(Nummer)
    + ''',''' + Betriebsauftrag
    + ''',''' + WerkzeugNr
    + ''',''' + IntToStr(Werkzeug)
    + ''',''' + MaterialNr
    + ''','' ' //MaterialMenge
  + ''',''0' //Dauer
  + ''',' + FloatToPunktString(StartDatumZeit)
    + ',''0' //EndDatumZeit
  + ''',''' + GetDatumZeitString(StartDatumZeit)
    + ''',''' + Status
    + ''', ''' + IntToStr(SollStueck) + CO_AuftragGetL(' Artikel')
    + ''',''' + IntToStr(SollStueck)
    + ''',''' + IntToStr(Istwert)
    + ''',''' + IntToStr(Programm_Nr)
    + ''',''' + IntToStr(Format_String(Packgroesse))
    + ''',''' + IntToStr(Solltakt)
    + ''',''' + IntToStr(SollRuestzeit)
    + ''',''' + IntToStr(RuestzeitIST)
    + ''',''' + IntToStr(RuestzeitDiff)
    + ''',''' + IntToStr(Kopfgroesse)
    + ''',''' + Schwesterauftrag
    + ''',''' + IntToStr(Ausschuss)
    + ''',''' + IntToStr(ANFAHR_AUSSCHUSS)
    + ''',' + FloatToPunktString(Sollausstoss)
    + ',''' + Layout
    + ''',''' + Druckbeschreibung
    + ''',' + FloatToPunktString(Stueck_nach_Kilo)
    + ',' + FloatToPunktString(Meter_nach_kilo)
    + ',''' + Etikett_Prod
    + ''',''' + ETIKETT_CHNR
    + ''',''' + KundenReferenz2
    + ''',''' + Kunde
    + ''',''' + ETIKETT_UN_ZULASSUNG
    + ''',''' + Layout2
    + ''',''' + EAN13
    + ''',''' + EAN128
    + ''',''' + Etikett1
    + ''',''' + Etikett2
    + ''',''' + Etikett3
    + ''',''' + Etikett4
    + ''',''' + Etikett5
    + ''',''' + Etikett6
    + ''',''' + Etikett7
    + ''',''' + Etikett8
    + ''',''' + Etikett9
    + ''', ''' + AktiveKavitaet
    + ''', ''' + IntToStr(Lagerort)
    + ''',' + FloatToPunktString(Termin1)
    + ',' + FloatToPunktString(Termin2)
    + ',' + FloatToPunktString(Termin3)
    + ',' + IntToStr(KavSoll)
    + ',' + IntToStr(ERPSoll)
    + ',' + IntToStr(ERPSollkav)
    + ',' + IntToStr(VarKav)
    + ')';
  try
    SQL_Insert(qUpdate, SQLStr);
    logpos(32);

    if aarchivnr <> '0' then // Nur wenn INSERT korrekt durchgeführt, wird der alte DAtensatz aus dem Archiv gelöscht
    begin
      SQLStr := 'SELECT startsoll FROM aarchiv WHERE BetriebsauftragNr = ''' + BetriebsauftragNr + ''' '
        + ' AND nr = ''' + aarchivnr + '''';
      SQL_Get(qUpdate, SQLStr);
      if not qUpdate.IsEmpty then
      begin
        SQLStr := 'UPDATE aarchiv SET startsoll = ''' + qUpdate.FieldByName('startsoll').AsString
          + ''' WHERE BetriebsauftragNr = ''' + BetriebsauftragNr + '''';
        SQL_Insert(qUpdate, SQLStr);
      end
      else
      begin
        SQLStr := 'UPDATE aarchiv SET startsoll = ''' + IntToStr(SollStueck)
          + ''' WHERE BetriebsauftragNr = ''' + BetriebsauftragNr + '''';
        SQL_Insert(qUpdate, SQLStr);
      end;
      SQLStr := 'Delete from AARCHIV where Nr = ''' + aarchivnr + '''';
      SQL_Insert(qUpdate, SQLStr);
    end
    else
    begin
      SQLStr := 'UPDATE aarchiv SET startsoll = ''' + IntToStr(SollStueck)
        + ''' WHERE BetriebsauftragNr = ''' + BetriebsauftragNr + '''';
      SQL_Insert(qUpdate, SQLStr);
    end;

    SQLStr := 'UPDATE aarchiv SET SOLLSPANNZEITSTK = ''' + IntToStr(SollSpannzeit)
      + ''' WHERE BetriebsauftragNr = ''' + BetriebsauftragNr + '''';
    SQL_Insert(qUpdate, SQLStr);
    SQLStr := 'UPDATE aarchiv SET SOLLSPANNZEITGES =  ROUND((SOLLSPANNZEITSTK * SollvorgabeINT)/6000)  '
      + ' WHERE BetriebsauftragNr = ''' + BetriebsauftragNr + '''';
    SQL_Insert(qUpdate, SQLStr);
  except
    on E: Exception do
      InsertFehlerDB(qUpdate, BetriebsauftragNr, Lizenz, CO_AuftragGetL('Starten'), SQLStr, E.message);
  end;
  logpos(33);
  //********************************************************************

  try
    SQLStr := 'Update MaschInf set'
      + ' Sollwert = ''' + IntToStr(SollStueck) + ''', ISTWERT_PRZ = ''' + FloatToStr(Round((Istwert / SollStueck) * 100)) + ' %'''
      + ', STUECK = ' + FloatToPunktString(Istwert)
      + ', PACK = ''' + IntToStr(verpackt) + ''', ENDEDATUM = ''' + GetDatumZeitString(EndDatum) + ''''
      + ', STUECKSCHICHT = ''0'', PACKSCHICHT = ''0'''
      + ', PRUEFSCHICHT = ''0'', PRUEF = ''0'', ArtikelNr = ''' + ArtikelNummer + ''''
      + ', BetriebsAuftragNr = ''' + BetriebsauftragNr + ''''
      + ', Bezeichnung = ''' + Bezeichnung + ''''
      + ', AUSSCHUSS = ''' + IntToStr(Ausschuss) + ''''
      + ' Where Lizenz = ''' + Maschine + '''';
    SQL_Insert(qUpdate, SQLStr);
    logpos(34);
  except
    on E: Exception do
      InsertFehlerDB(qUpdate, BetriebsauftragNr, Lizenz, CO_AuftragGetL('Starten'), SQLStr, E.message);
  end;

  try
    SQLStr := 'UPDATE MaschInf SET SOLLSPANNZEITSTK = ''' + IntToStr(SollSpannzeit)
      + ''' WHERE Lizenz = ''' + Maschine + '''';
    SQL_Insert(qUpdate, SQLStr);
    SQLStr := 'UPDATE MaschInf SET SOLLSPANNZEITGES = ROUND((SOLLSPANNZEITSTK * Sollwert)/6000) '
      + ' WHERE Lizenz = ''' + Maschine + '''';
    SQL_Insert(qUpdate, SQLStr);

  except
  end;
  if SQLGet(qSuch, 'Maschinf', 'Lizenz', Maschine, True) > 0 then
  begin
    if (qSuch.FieldByName('ZustandInt').AsInteger = 1) and not Ruesten
        and not TCO_Setup.GetParamBool(qSuch,'INCL_LeaveDownTimeOnJobStart') then
    begin
      SQLStr := 'Update MaschInf set ZustandInt = 0 where Lizenz = ''' + Maschine + '''';
      SQL_Insert(qUpdate, SQLStr);
    end;
    if Ruesten then
    begin
      SQLStr := 'Update MaschInf set ZustandInt = 1 where Lizenz = ''' + Maschine + '''';
      SQL_Insert(qUpdate, SQLStr);
    end;
  end;
  logpos(35);

  //********************************************************************

  if MasterAuftrag then
  begin
    SQL_Insert(qUpdate, 'UPDATE aarchiv SET masterauftrag = ''' + BetriebsauftragNr
      + ''' WHERE betriebsauftragNr = ''' + BetriebsauftragNr + '''');

    SQLGet(qSuch, 'PDEKombi', 'MasterBetriebsAuftragNr', BetriebsauftragNr, False);
    if not qSuch.IsEmpty then
    begin
      SQLStr := 'delete from maschinf where LIZENZ = ''' + Lizenz + MASCHBEZ_UNTERAUFTRAG + '''';
      SQL_Insert(qUpdate, SQLStr);
    end;

    while not qSuch.EOF do
    begin
      if SQLGet(qUpdate, 'AARchiv', 'BetriebsAuftragNr', qSuch.FieldByName('Betriebsauftragnr').AsString, True) = 0 then
      begin
        SQLStr := 'INSERT INTO AArchiv (Nr, Maschine, RNR, BetriebsauftragNr, AuftragNr,'
          + ' Masterauftrag,'
          + ' Bezeichnung, Arbeitsgang, A_Gang, PDENR, Betriebsauftrag, WerkzeugNr, Werkzeug,'
          + ' MaterialNr, MaterialMenge, Dauer, StartDatumZeit,'
          + ' EndDatumZeit, StartDatumStr, EndDatumStr, Sollvorgabe, SollvorgabeINT, ProduziertInt,'
          + ' Programm_Nr, PackGroesse, Taktzeitsoll, Ruestzeitsoll,'
          + ' Ruestzeitist, RuestzeitDiff, Kavitaet, Schwesterauftrag, Ausschuss, Kavitaet_soll)'
          + ' VALUES (AArchivID.NextVal'
          + ',''' + Maschine
          + ''',''' + qSuch.FieldByName('RNR').AsString // + ''',''' + IntToStr(RNR)
        + ''',''' + qSuch.FieldByName('Betriebsauftragnr').AsString
          + ''',''' + qSuch.FieldByName('Auftragnr').AsString
          + ''',''' + BetriebsauftragNr
          + ''',''' + qSuch.FieldByName('Bezeichnung').AsString
          + ''',''' + Arbeitsgang
          + ''',''' + A_Gang
          + ''',''' + IntToStr(Nummer)
          + ''',''' + Betriebsauftrag
          + ''',''' + WerkzeugNr
          + ''',''' + IntToStr(Werkzeug)
          + ''',''' + MaterialNr
          + ''','' ' //MaterialMenge
        + ''',''0' //Dauer
        + ''',' + FloatToPunktString(StartDatumZeit)
          + ',''0' //EndDatumZeit
        + ''',''' + GetDatumZeitString(StartDatumZeit)
          + ''',''' + Status
          + ''',''' + qSuch.FieldByName('Sollwert').AsString + CO_AuftragGetL(' Artikel')
          + ''',''' + qSuch.FieldByName('Sollwert').AsString
          + ''',''' + qSuch.FieldByName('Istwert').AsString
          + ''',''' + IntToStr(Programm_Nr)
          + ''',''' + IntToStr(Format_String(Packgroesse))
          + ''',''' + IntToStr(Solltakt)

        // Keine Rüstzeit bei Unteraufträgen
        //          + ''',''' + IntToStr(SollRuestzeit)
        //          + ''',''' + IntToStr(RuestzeitIST)
        //          + ''',''' + IntToStr(RuestzeitDiff)

        + ''',''' + IntToStr(0)
          + ''',''' + IntToStr(0)
          + ''',''' + IntToStr(0)

        + ''',''' + qSuch.FieldByName('Kavitaet').AsString
          + ''',''' + Schwesterauftrag
          + ''',''0'
          + ''',' + qSuch.FieldByName('Kavitaet').AsString + ')';
        SQL_Insert(qUpdate, SQLStr);
      end
      else
      begin
        SQLStr := ' UPDATE AARCHIV SET StartDatumZeit = ' + FloatToPunktString(StartDatumZeit) + ', '
                + ' StartDatumStr = + ''' + GetDatumZeitString(StartDatumZeit) + ''', '
                + ' Enddatumzeit = 0, EndDatumStr = ''' + Status + ''', '
                + ' Maschine = ''' + Maschine + ''' '
                + ' WHERE betriebsauftragnr = ''' + qSuch.FieldByName('Betriebsauftragnr').AsString
                + '''';
        SQL_Insert(qUpdate, SQLStr);
      end;
      SQLStr := 'insert Into MaschInf ('
        + 'Nr, Lizenz, DatumZeit, Maschine,MaschNr,MaschNrInt, ZUSTAND, ZUSTANDINT, Taktzeit,'
        + ' Sollwert, ISTWERT_PRZ, STUECK,PACK,STUECKSCHICHT,PACKSCHICHT,PRUEFSCHICHT,PRUEF,'
        + ' LTSOLL, LTIST, Stat, ArtikelNr,'
        + ' BetriebsAuftragNr, Bezeichnung, AUSSCHUSS,'
        + ' Werkzeug, WERKZEUG_NR,'
        + ' TAKTZEIT_STR) values (MaschinfId.NextVal,'
        + ' ''' + Maschine + MASCHBEZ_UNTERAUFTRAG + ''','
        + FloatToPunktString(StartDatumZeit) + ','
        + ' ''' + Maschine + MASCHBEZ_UNTERAUFTRAG + ''','
        + ' ''' + MaschNr + ''','
        + ' ''' + MaschNr + ''','
        + ' ''' + CO_AuftragGetL('offline') + ''','
        + ' ''3'','
        + ' ''' + IntToStr(0) + ''','
        + ' ''' + qSuch.FieldByName('Sollwert').AsString + ''','
        + ' ''' + IntToStr(0) + ' %'','
        + ' ''' + IntToStr(0) + ''',' //STUECK
      + ' ''' + IntToStr(0) + ''',' //PACK
      + ' ''' + IntToStr(0) + ''','
        + ' ''' + IntToStr(0) + ''','
        + ' ''' + IntToStr(0) + ''','
        + ' ''' + IntToStr(0) + ''','
        + ' ''' + IntToStr(0) + ''','
        + ' ''' + IntToStr(0) + ''','
        + ' ''' + IntToStr(0) + ''','
        + ' ''' + qSuch.FieldByName('AuftragNr').AsString + ''','
        + ' ''' + qSuch.FieldByName('BetriebsAuftragNr').AsString + ''','
        + ' ''' + qSuch.FieldByName('Bezeichnung').AsString + ''','
        + ' ''0'','
        + ' ''0'','
        + ' ''0'','
        + ' ''0'')';
      try
        SQL_Insert(qUpdate, SQLStr);
        logpos(36);
      except
      end;

      qSuch.Next;
    end;
  end;

  if Ruesten then
  begin
    SQLStr := 'select schicht from tpm_schicht where nr = (select max(nr) from tpm_schicht)';
    SQL_Get(qSuch, SQLStr);
    Schicht := qSuch.FieldByName('Schicht').AsInteger;
    logpos(37);
    try
	   SQLStr := 'select COUNT(*) as CNT from tpm_Stillog where ((Geht is NULL) OR (Geht = 0))'
	      + ' AND (maschnr = ''' + MaschNr + ''')';
	    SQL_Get(qSuch, SQLStr);
	    if qSuch.FieldByName('CNT').AsInteger > 0 then
	    begin
	      InsertStill := TCO_Setup.GetParamBool(qSuch, 'INCL_InsertDowntimeWOStart');
	
	      SQLStr := 'select * from tpm_Stillog where ((Geht is NULL) OR (Geht = 0))'
	        + ' AND (maschnr = ''' + MaschNr + ''')';
	      SQL_Get(qSuch, SQLStr);
	      qSuch.First;
	      while not qSuch.EOF do
	      begin
	
	        Nummer := qSuch.FieldByName('Nr').AsInteger;
	        Dauer := Trunc((StartDatumZeit - qSuch.FieldByName('Kommt').AsFloat) * 1440);
	        if Dauer = 0 then
	          Dauer := 1;
	        if InsertStill then
	        begin
	          SQLStr := 'INSERT INTO TPM_Stillog (Nr,MaschNr,Schicht,Erstellungsdatum,Kommt,Stillstandnr,KommtStr)'
	            + ' VALUES(TPM_StillogID.Nextval'
	            + ',''' + MaschNr
	            + ''',''' + IntToStr(Schicht)
	            + ''',' + FloatToPunktString(now)
	            + ',' + FloatToPunktString(now)
	            + ',1'
	            + ',''' + DateTimeToStr(now)
	            + ''')';
	          SQL_Insert(qUpdate,sqlstr);
	        end;
	
	        SQLStr := 'UPDATE tpm_stillog SET geht = ' + FloatToPunktString(StartDatumZeit)
	          + ', GehtStr = ''' + DateToStr(Date) + ''', Dauer = ' +  IntToStr(Dauer)
	          + ' WHERE nr = ' + IntToStr(Nummer);
	        SQL_Insert(qUpdate,sqlstr);
	
	
	(*
	        UpdateSQLPunkt(qUpdate, 'tpm_Stillog', 'Geht', FloatToPunktString(StartDatumZeit), 'Nr', IntToStr(Nummer));
	        UpdateSQL(qUpdate, 'tpm_Stillog', 'GehtStr', DateToStr(Date) + '  ' + TimeToStr(Frac(StartDatumZeit)), 'Nr',
	          IntToStr(Nummer));
	        UpdateSQL(qUpdate, 'tpm_Stillog', 'Dauer', IntToStr(Dauer), 'Nr', IntToStr(Nummer));
	        *)
	        qSuch.Next;
	        // Wenn Stillstand beendet wurde, dann neuen Event Stillgeht auslösen.
	
	        if not fSupressEvents then
	        begin
	          if InsertStill then
	          begin
	            SQLStr := 'select nr from tpm_Stillog where ((Geht is NULL) OR (Geht = 0))'
	              + ' AND (maschnr = ''' + MaschNr + ''')';
	            SQL_Get(qSuch2, SQLStr);
	            Nummer2 := qSuch2.FieldByName('nr').AsInteger;
	
	            SQLStr := 'insert into ERPEvents (Nr, BetriebsAuftragNr, Event, Datumzeit)'
	              + ' values (ERPEventsId.NextVal,'
	              + '''' + IntToStr(Nummer2) + ''','
	              + '''H'','
	              + FloatToPunktString(StartDatumZeit) + ')';
	          end;
	
	          SQLStr := 'insert into ERPEvents (Nr, BetriebsAuftragNr, Event, Datumzeit)'
	            + ' values (ERPEventsId.NextVal,'
	            + '''' + IntToStr(Nummer) + ''','
	            + '''G'','
	            + FloatToPunktString(StartDatumZeit) + ')';
	          SQL_Insert(qUpdate, SQLStr);
	        end;
	      end;
	    end
	    else
	    begin
	      if InsertStill then
	      begin
	        SQLStr := 'INSERT INTO TPM_Stillog (Nr,MaschNr,Schicht,Erstellungsdatum,Kommt,Stillstandnr,KommtStr)'
	          + ' VALUES(TPM_StillogID.Nextval'
	          + ',''' + MaschNr
	          + ''',''' + IntToStr(Schicht)
	          + ''',' + FloatToPunktString(now)
	          + ',' + FloatToPunktString(now)
	          + ',1'
	          + ',''' + DateTimeToStr(now)
	          + ''')';
	        SQL_Insert(qUpdate,sqlstr);
	      end;
	    end;
	    logpos(38);
    except on e: exception do
      begin
        //ShowMessage(e.Message);

      end;
    end;

  end
  else //if Ruesten then
  begin
    if ( (not TCO_Setup.GetParamBool(qSuch,'INCL_LeaveDownTimeOnJobStart')) or TCO_Setup.GetParamBool(qSuch,'INCL_NewDownTimeOnJobStart')) then
    begin
      SQLStr := 'select * from tpm_Stillog, tpm_stillstaende where tpm_Stillog.Stillstandnr = (tpm_stillstaende.Stillstandnr)'
        + ' AND (Geht is NULL OR Geht = 0) AND (maschnr = ''' + MaschNr + ''')';
        if not TCO_Setup.GetParamBool(qSuch,'INCL_NewDownTimeOnJobStart') then
          SQLStr := SQLStr + ' AND (Gruppe = 1) ';
      SQL_Get(qSuch, SQLStr);
      qSuch.First;
      while not qSuch.EOF do
      begin
        Nummer := qSuch.FieldByName('Nr').AsInteger;
        Dauer := Trunc((StartDatumZeit - qSuch.FieldByName('Kommt').AsFloat) * 1440);
        if Dauer = 0 then
          Dauer := 1;

        UpdateSQLPunkt(qUpdate, 'tpm_Stillog', 'Geht', FloatToPunktString(StartDatumZeit), 'Nr', IntToStr(Nummer));
        UpdateSQL(qUpdate, 'tpm_Stillog', 'GehtStr', DateToStr(Date) + '  ' + TimeToStr(Frac(StartDatumZeit)), 'Nr',
          IntToStr(Nummer));
        UpdateSQL(qUpdate, 'tpm_Stillog', 'dauer', IntToStr(Dauer), 'Nr', IntToStr(Nummer));

        if not fSupressEvents then
        begin
          SQLStr := 'insert into ERPEvents (Nr, BetriebsAuftragNr, Event, Datumzeit)'
            + ' values (ERPEventsId.NextVal,'
            + '''' + IntToStr(Nummer) + ''','
            + '''G'','
            + FloatToPunktString(StartDatumZeit) + ')';
          SQL_Insert(qUpdate, SQLStr);
        end;

        qSuch.Next;
      end; //while not Daten.qSuch.EOF do begin
      logpos(39);
    end;
  end; //end else begin

  //*****************************************************************
  //  PROTOKOLL Schreiben
  //*****************************************************************
  //**********************************************************************
  //            Personal (Schichtführer ermitteln)
  //**********************************************************************

  // Auskommentiert und oben eingebaut.

//  SQLStr := 'select Name, PersonalNr from Personalanmeldung order by DatumZeit Desc';
//  SQL_Get(qSuch, SQLStr);
//  try
//    Name := qSuch.FieldByName('Name').AsString;
//    PersonalNr := qSuch.FieldByName('PersonalNr').AsString;
//  except
//    Name := '';
//    PersonalNr := '';
//  end;

  logpos(40);
  if Ruesten then
  begin
    SQLStr := 'INSERT INTO AuftragstartProt (Nr,Maschine,BetriebsauftragNr,AuftragNr,'
      + ' Bezeichnung,DatumZeitStr,DatumZeit,Modul,Status, Name, Ruestzeit,'
      + ' STARTRUESTSTR, STARTRUEST)'
      + 'VALUES(AuftragstartProtID.NextVal'
      + ',''' + Lizenz
      + ''',''' + BetriebsauftragNr
      + ''',''' + ArtikelNummer
      + ''',''' + Bezeichnung
      + ''',''' + DateTimeToStr(StartDatumZeit)
      + ''',' + FloatToPunktString(StartDatumZeit)
      + ','''
      + ''','''
      + ''',''' + Name
      + ''',''' + IntToStr(RuestzeitIST)
      + ''',''' + DateTimeToStr(StartDatumZeit)
      + ''',' + FloatToPunktString(StartDatumZeit)
      + ')';
    SQL_Insert(qUpdate, SQLStr);
    logpos(41);

    // Wenn Rüsten, muss man immer neue Datensatz erzeugen. Die alte Datensätze sollen ungeändert bleiben.
    //    if not Ruesten_laufender_Auftrag then
    //    begin
    //      SQLStr := 'Delete from RuestProt where BetriebsAuftragNr = ''' + BetriebsauftragNr + '''';
    //      SQL_Insert(qUpdate, SQLStr);
    //    end;

    if not fRuestAusStillstand then
    begin
      SQLStr := 'Insert into RuestProt'
        + ' (Nr, BetriebsAuftragNr, Name , PersonalNr, RuestStart, RuestSoll, Lizenz, Werkzeug) values '
        + '(RuestProtId.NextVal,'
        + '''' + BetriebsauftragNr + ''','
        + '''' + Name + ''','
        + '''' + PersonalNr + ''','
        + FloatToPunktString(StartDatumZeit) + ','
        + '''' + IntToStr(SollRuestzeit) + ''','
        + '''' + Lizenz + ''','
        + '''' + IntToStr(Werkzeug) + ''''
        + ')';
      SQL_Insert(qUpdate, SQLStr);
      logpos(42);
    end;
  end
  else
  begin //if Ruesten then begin    //BaNr 0413988/1492902  //RP
    if SQLGet(qSuch, 'AuftragstartProt', 'BetriebsauftragNr', BetriebsauftragNr, True) > 0 then
    begin
      Prot_Start_Ruest := qSuch.FieldByName('STARTRUEST').AsFloat;
      Prot_Nr := qSuch.FieldByName('Nr').AsInteger;
      SQL_Insert(qUpdate, 'delete from AuftragstartProt where nr = ' + IntToStr(Prot_Nr));
      logpos(43);
    end
    else
    begin
      Prot_Start_Ruest := StartDatumZeit;
    end;

    try
      RuestZeit := ZeitInMinuten(Lizenz, Prot_Start_Ruest, StartDatumZeit);
    except
      RuestZeit := 0;
    end;

    SQLStr := 'INSERT INTO AuftragstartProt (Nr,Maschine,BetriebsauftragNr,AuftragNr,'
      + ' Bezeichnung,DatumZeitStr,DatumZeit,Modul,Status, Name, Ruestzeit,'
      + ' STARTDATUMSTR, STARTDATUM,STARTRUESTSTR, STARTRUEST)'
      + 'VALUES(AuftragstartProtID.NextVal'
      + ',''' + Lizenz
      + ''',''' + BetriebsauftragNr
      + ''',''' + ArtikelNummer
      + ''',''' + Bezeichnung
      + ''',''' + DateTimeToStr(StartDatumZeit)
      + ''',' + FloatToPunktString(StartDatumZeit)
      + ','''
      + ''','''
      + ''',''' + Name
      + ''',''' + IntToStr(RuestZeit)
      + ''',''' + DateTimeToStr(StartDatumZeit)
      + ''',' + FloatToPunktString(StartDatumZeit)
      + ',''' + DateTimeToStr(Prot_Start_Ruest)
      + ''',' + FloatToPunktString(Prot_Start_Ruest)
      + ')';
    SQL_Insert(qUpdate, SQLStr);
    logpos(44);

    if not fRuestAusStillstand then
    begin
      SQLStr := 'Update RuestProt set'
        + ' RuestEnde = ' + FloatToPunktString(StartDatumZeit) + ','
        + ' RuestIst = -1'
        + ' where Betriebsauftragnr = ''' + BetriebsauftragNr + ''' AND Ruestende = 0';
      SQL_Insert(qUpdate, SQLStr);

      SQLStr := 'Update RuestProt set'
        + ' RuestIst = trunc((ruestende-rueststart)*1440)'
        + ' where Betriebsauftragnr = ''' + BetriebsauftragNr + '''';
      SQL_Insert(qUpdate, SQLStr);

      SQLStr := 'Update RuestProt set'
        + ' Ruest_Gesamt_Auftrag = '
        + ' (SELECT SUM (trunc((ruestende-rueststart)*1440)) + sum(vorruest) FROM ruestprot '
        + ' WHERE betriebsauftragNr = ''' + BetriebsauftragNr + ''')'
        + ' where Betriebsauftragnr = ''' + BetriebsauftragNr + '''';
      SQL_Insert(qUpdate, SQLStr);
      logpos(45);
    end;
  end;

  //*****************************************************************
  //  SQLStr := 'INSERT INTO AStart (Nr,Lizenz,Signal)'
  //    + 'VALUES(AStartID.NextVal'
  //    + ',''' + Lizenz
  //    + ''',''' + CO_AuftragGetL('Stückzahl Maschine')
  //    + ''')';
  //  SQL_Insert(qUpdate, SQLStr);
  logpos(46);

  //Verpackungsgroesse und Kopfgroesse in Maschinendatenbank einstellen
  SQLStr := 'Select Count(*) CNT from Maschine where Lizenz = ''' + Lizenz + '''';
  SQL_Get(qSuch, SQLStr);
  if qSuch.FieldByName('CNT').AsInteger > 0 then
  begin
    SQLStr := 'Update Maschine Set Packgroesse = ''' + Packgroesse + ''',Kopfgroesse = ''' + IntToStr(Kopfgroesse)
      + ''' where Lizenz = ''' + Lizenz + '''';
    SQL_Insert(qUpdate, SQLStr);
  end;
  logpos(47);

  if not OfflineMaschine then
  begin
    SQLStr := 'Select Count(*) CNT from MDE_Ver where (Jobbezeichnung = ''' + CO_AuftragGetL('Taktzeitkontrolle ')
            + Maschine + ''''  + ' OR (SignalKod = 0 AND Lizenz = ''' + Maschine  + ''')) ';
    SQL_Get(qSuch, SQLStr);
    if qSuch.FieldByName('CNT').AsInteger > 0 then
    begin
      SQLStr := 'Delete from MDE_Ver where ( Jobbezeichnung = ''' + CO_AuftragGetL('Taktzeitkontrolle ')
              + Maschine + ''''  + ' OR (SignalKod = 0 AND Lizenz = ''' + Maschine  + ''')) ';
      SQL_Insert(qUpdate, SQLStr);
    end;
    logpos(48);
  if (fTaktVergleichToleranzAbsolut > - 1) then
  begin
    ToleranzInt := Round(fTaktVergleichToleranzAbsolut / SollTakt * 10000);
  end;


    SQLStr := 'INSERT INTO MDE_Ver (Nr,Lizenz,Erzeugt,Signal1, SignalKod, Signal2,Einheit,'
      + 'JobBezeichnung, Zeit,DatumZeit,APNr,Sollwert,SollwertInt,'
      + 'Zustaendig,Istwert,IstwertInt,Abweichung,AbweichungPRZ,Toleranz, ToleranzInt, Poolgroesse,SPC, TOLERANZABSOLUT, TOLERANZABSOLUTINT)'
      + 'VALUES(MDE_VerID.NextVal'
      + ',''' + Lizenz
      + ''',''0'
      + ''',''' + CO_AuftragGetL('Soll-Takt')
      + ''',''0'
      + ''',''' + CO_AuftragGetL('Ist-Takt')
      + ''',''' + CO_AuftragGetL('s')
      + ''',''' + CO_AuftragGetL('Taktzeitkontrolle ') + Maschine
      + ''',''' + TimeToStr(Time)
      + ''',' + FloatToPunktString(StartDatumZeit)
      + ',''1' //APNr
    + ''',''' + FloatToStr(Solltakt / 100) + CO_AuftragGetL(' s')
      + ''',''' + IntToStr(Solltakt)
      + ''','''
      + ''',''' + CO_AuftragGetL('0 s')
      + ''',''0'
      + ''',''' + CO_AuftragGetL('0 s')
      + ''',''0 %'
      + ''',''' + IntToStr(ToleranzInt) + ' %'
      + ''',''' + IntToStr(ToleranzInt)
      + ''','''
      + ''',''0'
      + ''',' + IntToStr(fTaktVergleichToleranzAbsolut)
      + ',' + IntToStr(fTaktVergleichToleranzAbsolut * 100)
      + ')';

    SQL_Insert(qUpdate, SQLStr);
    logpos(49);
  end;

  //**********************************************************************
  //            QS
  //**********************************************************************

  if SQLGet(qSuch, 'PRUEFPLAN', 'AuftragNr', ArtikelNummer, True) > 0 then
  begin

    for I := 1 to 8 do
    begin
      if qSuch.FieldByName('Job_Wert' + IntToStr(I)).AsInteger = 1 then
      begin
        try
          Termin_Bez := 'QS  "' + qSuch.FieldByName('Bez_Wert' + IntToStr(I)).AsString + '"';
          Termin := qSuch.FieldByName('Intervall_Wert' + IntToStr(I)).AsInteger / 1440;
          Termin := Termin + Date + Time;

          SQLStr := 'INSERT INTO TerminOrder (Nr, Lizenz, Bezeichnung, Datum, Uhrzeit, DatumZeit, VWDatumZeit, VWZeit,'
            + ' VWEinheit, Wiederholung, Wiederholungsintervall, Wiederholungseinheit, Erzeugt, Zustaendig) '
            + 'VALUES(TerminOrderID.NextVal'
            + ',''' + Lizenz
            + ''',''' + Termin_Bez
            + ''',''' + DateToStr(Termin)
            + ''',''' + TimeToStr(Termin)
            + ''',' + FloatToPunktStringF(Termin, ffFixed, 15, 8)
            + ',''' + IntToStr(0)
            + ''',''' + IntToStr(0)
            + ''','''
            + ''',''1' // Wiederholung
          + ''',''' + IntToStr(qSuch.FieldByName('Intervall_Wert' + IntToStr(I)).AsInteger)
            + ''',''Minuten'
            + ''',''1' //Erzeugt -> Vorwarnug erzeugt !!
          + ''',''' + CO_AuftragGetL('Bediener')
            + ''')';
          SQL_Insert(qUpdate, SQLStr);
        except
        end;

      end; //if qSuch.FieldbyName('Job_Wert'+InttoStr(i)).AsInteger = 1 then
    end; //for i:= 1 to 5 do begin
    logpos(50);
  end; // if SQLGET(qSuch,'PRUEFPLAN','AuftragNr',Artikelnummer,True) > 0 then begin

  //**********************************************************************
  //            DIFFERENZLISTE
  //**********************************************************************
  if FDifferenzListe and (PDEDiffNr > 0) then
  begin
    if SQLGet(qSuch, 'PDE', 'Nr', IntToStr(PDEDiffNr), True) > 0 then
    begin
      SQLStr := 'INSERT INTO DIFFERENZ (Nr,Lizenz,Betriebsauftragnr,Auftragnr,Bezeichnung,Datumzeit,'
        + 'Startdatumzeit,enddatumzeit,Termin1,Termin2,Termin3,'
        + 'Betriebsauftragnr_plan,Auftragnr_plan,Bezeichnung_plan,Termin1_plan,Termin2_plan,Termin3_plan)'
        + 'VALUES(DIFFERENZID.NextVal'
        + ',''' + Lizenz
        + ''',''' + BetriebsauftragNr
        + ''',''' + ArtikelNummer
        + ''',''' + Bezeichnung
        + ''',' + FloatToPunktString(StartDatumZeit)
        + ',' + FloatToPunktString(StartDatumZeit)
        + ',' + FloatToPunktString(EndDatum)
        + ',' + FloatToPunktString(Termin1)
        + ',' + FloatToPunktString(Termin2)
        + ',' + FloatToPunktString(Termin3)

      + ',''' + qSuch.FieldByName('Betriebsauftragnr').AsString
        + ''',''' + qSuch.FieldByName('Auftragnr').AsString
        + ''',''' + qSuch.FieldByName('Bezeichnung').AsString
        + ''',' + FloatToPunktString(qSuch.FieldByName('Termin1').AsFloat)
        + ',' + FloatToPunktString(qSuch.FieldByName('Termin2').AsFloat)
        + ',' + FloatToPunktString(qSuch.FieldByName('Termin3').AsFloat)
        + ')';

      SQL_Insert(qUpdate, SQLStr);

      logpos(51);
    end;
  end;

  //**********************************************************************
  //**********************************************************************
  //            SPC
  //**********************************************************************
  if FOpt_SPC then
  begin
    try
      CO_SPC.MaschNr := StrToInt(MaschNr);
      CO_SPC.ArtikelNr := ArtikelNummer;
      CO_SPC.SPC_Sollwerte_Aktivieren;
    except
    end;
  end;

  InsertOfflineMaschinen(Lizenz);
  logpos(52);

  if fOpt_WerkZeug then
    CheckWerkzeugAarchiv(BetriebsauftragNr);

  if Ruesten then
    Schuss := Anfahr_Ausschuss
  else
    Schuss := Istwert;

  if TCO_Setup.GetParamBool(qUpdate, 'Stueckzahl_laufender_Auftrag_nicht_abnullen') then
  begin // Evtl. Stückzahl nur beim Übergang neu-Rüsten oder unterbrochen-rüsten setzen
    Schuss := Istwert;
    AuftragBuchen(BetriebsauftragNr, Schuss);
  (*
    if (status_alt = 2) or (status_alt = 0) then // Auftrag war geplant oder lief
    begin
      Schuss := Istwert;
      AuftragBuchen(BetriebsauftragNr, Schuss);
    end;
    if status_alt = 5 then // Auftrag war unterbrochen
    begin
      Schuss := Istwert;
      AuftragBuchen(BetriebsauftragNr, Schuss);
    end;
    *)
  end
  else
  begin
    if TCO_Setup.GetParamBool(qUpdate,'INCL_RecoverInterruptSignals') then
      RecoverInterruptSignals(Maschnr, BetriebsauftragNr, Lizenz);
    AuftragBuchen(BetriebsauftragNr, Schuss);
  end;

  logpos(53);

  if Ruesten then
    ZH := 'Z'
  else
    ZH := 'C';

  if not fSupressEvents then
  begin
    SQLStr := 'select Count(*) as CNT from ERPEvents'
      + ' where BetriebsAuftragNr = ''' + BetriebsauftragNr + ''''
      + ' and Event = ''' + ZH + '''';
    SQL_Get(qUpdate, SQLStr);
    if qUpdate.FieldByName('CNT').AsInteger = 0 then
    begin
      SQLStr := 'insert into ERPEvents (Nr, BetriebsAuftragNr, Event, Datumzeit)'
        + ' values (ERPEventsId.NextVal,'
        + '''' + BetriebsauftragNr + ''','
        + '''' + ZH + ''','
        + FloatToPunktString(StartDatumZeit) + ')';
      SQL_Insert(qUpdate, SQLStr);
    end;
  end;
  logpos(54);

  if SQLGet(qSuch, 'PDEStamm', 'AuftragNr', ArtikelNummer, True) > 0 then
  begin
    SQLStr := 'update Maschine set'
      + ' Takt_pro_Stueck = ''' + qSuch.FieldByName('Takt_pro_Stueck').AsString + ''','
      + ' Offset_in_sek = ''' + qSuch.FieldByName('Offset_in_sek').AsString + ''''
      + ' where Lizenz = ''' + Lizenz + '''';
    SQL_Insert(qUpdate, SQLStr);
  end;
  logpos(56);
  // ***************************************************************************
  //                    LaufzeitLog schreiben
  // ***************************************************************************
  // Höchsten Eintrag des Auftrages in LaufzeitLog suchen
  SQLStr := 'SELECT * FROM LaufzeitLog WHERE nr = '
    + ' (SELECT MAX(nr) FROM LaufzeitLog WHERE Betriebsauftragnr = ''' + BetriebsauftragNr + ''')';
  SQL_Get(qSuch, SQLStr);
  if Ruesten then
  begin // Wenn Ende
    if qSuch.IsEmpty then // Kein Eintrag vorhanden, neuen erzeugen
    begin
      SQLStr := 'INSERT INTO LaufzeitLog (Nr, BetriebsauftragNr, ErsterStart, RuestStart, '
        + 'AuftragStart, AuftragEnde, Laufzeit, GesamtLaufzeit,MaschNr, RuestZeit)'
        + ' VALUES (LaufzeitLogID.NextVal, ''' + BetriebsauftragNr + ''', '
        + FloatToPunktString(StartDatumZeit) + ', ' + FloatToPunktString(StartDatumZeit) + ','
        + '0,0,0,0,' + MaschNr + ',0)';
      SQL_Insert(qUpdate, SQLStr);
      logpos(57);
    end
    else // Nachsehen ob Eintrag schon beendet
    begin
      if qSuch.FieldByName('AuftragEnde').AsInteger = 0 then // Nicht beendet, zweites Rüsten
      begin

      end
      else
      begin // Ist schon beendet, neuen Eintrag einfügen
        SQLStr := 'INSERT INTO LaufzeitLog (Nr, BetriebsauftragNr, ErsterStart, RuestStart, '
          + 'AuftragStart, AuftragEnde, Laufzeit, GesamtLaufzeit,MaschNr, RuestZeit)'
          + ' VALUES (LaufzeitLogID.NextVal, ''' + BetriebsauftragNr + ''', '
          + FloatToPunktString(qSuch.FieldByName('ErsterStart').AsFloat) + ', '
          + FloatToPunktString(StartDatumZeit) + ','
          + '0,0,0,0,' + MaschNr + ',0)';
        SQL_Insert(qUpdate, SQLStr);
        logpos(58);

      end;
    end;

  end
  else
  begin
    if qSuch.IsEmpty then // Kein Eintrag vorhanden, neuen erzeugen
    begin
      SQLStr := 'INSERT INTO LaufzeitLog (Nr, BetriebsauftragNr, ErsterStart, RuestStart, '
        + 'AuftragStart, AuftragEnde, Laufzeit, GesamtLaufzeit,MaschNr,RuestZeit)'
        + ' VALUES (LaufzeitLogID.NextVal, ''' + BetriebsauftragNr + ''', '
        + FloatToPunktString(StartDatumZeit) + ', ' + FloatToPunktString(StartDatumZeit) + ','
        + FloatToPunktString(StartDatumZeit) + ',0,0,0,' + MaschNr + ',0)';
      SQL_Insert(qUpdate, SQLStr);
      logpos(59);
    end
    else // Nachsehen ob Eintrag schon beendet
    begin
      if qSuch.FieldByName('AuftragEnde').AsInteger = 0 then // Nicht beendet, Start einfügen
      begin
        SQLStr := 'UPDATE LaufzeitLog SET AuftragStart = ' + FloatToPunktString(StartDatumZeit)
          + ', RuestZeit = '''
          + IntToStr(Round((StartDatumZeit - qSuch.FieldByName('RuestStart').AsFloat) * 1440))
          + ''' WHERE Nr = ' + qSuch.FieldByName('nr').AsString;
        SQL_Insert(qUpdate, SQLStr);
        logpos(60);
      end
      else
      begin // Ist schon beendet, neuen Eintrag einfügen
        SQLStr := 'INSERT INTO LaufzeitLog (Nr, BetriebsauftragNr, ErsterStart, RuestStart, '
          + 'AuftragStart, AuftragEnde, Laufzeit, GesamtLaufzeit,MaschNr,RuestZeit)'
          + ' VALUES (LaufzeitLogID.NextVal, ''' + BetriebsauftragNr + ''', '
          + FloatToPunktString(qSuch.FieldByName('ErsterStart').AsFloat) + ', '
          + FloatToPunktString(StartDatumZeit) + ',' + FloatToPunktString(StartDatumZeit) + ','
          + '0,0,0,' + MaschNr + ',0)';
        SQL_Insert(qUpdate, SQLStr);
      end;
      logpos(61);
    end;
  end;
  // Bei Halbautomatik Kalendergruppe, Gruppe in Maschine umstellen
  logpos(62);
  // ggf. Spannzeit Soll schreiben

  SignalNr := 125; // Signal Spannzeitaktuell
  if SQLGet(qSuch, 'SIGNALE', 'SignalArt', IntToStr(SignalNr), True) > 0 then
  begin
    SignalNr := qSuch.FieldByName('SignalNr').AsInteger;
    SQL_Insert(qUpdate, 'INSERT INTO SIGNAL_SCHREIBEN (Nr, MaschNr, SignalNr, Wert)'
      + ' VALUES (SIGNAL_SCHREIBENID.NextVal'
      + ',''' + MaschNr
      + ''',''' + IntToStr(SignalNr)
      + ''',''' + IntToStr(Round((SollSpannzeit * Kopfgroesse) * (1 + (SpannzeitToleranz / 100))))
      + ''')');
  end;
  logpos(63);
  // Materialchargen Zuordnung vornehmen
  if fMaterial then
  begin
    try
      SQLStr := 'SELECT materialbuchungen.eancode ean, materialzuor.betriebsauftragnr banr'
        + ' FROM materialchargen '
        + ' RIGHT JOIN materialbuchungen ON materialbuchungen.eancode=materialchargen.eancode '
        + ' LEFT JOIN materialzuor ON materialzuor.eancode=materialchargen.eancode'
        + ' AND materialzuor.betriebsauftragnr = ''' + BetriebsauftragNr + ''''
        + ' WHERE materialchargen.materialid = ''' + MaterialNr + ''''
        + ' ORDER BY entnahmedatum DESC ';
      SQL_Get(qSuch, SQLStr);
      LogMeldung(SQLStr);
      if qSuch.FieldByName('banr').IsNull then
      begin
        SQLStr := 'INSERT INTO materialzuor (nr, betriebsauftragnr, eancode) '
          + ' VALUES (MATERIALZUORID.nextval, ''' + BetriebsauftragNr + ''','
          + '''' + qSuch.FieldByName('ean').AsString + ''')';
        SQL_Insert(qUpdate, SQLStr);
      end
    except on ex : exception do
      LogMeldung(ex.Message);
    end;
    logpos(64);
  end;

  if Ruesten and TCO_Setup.GetParamBool(qCount, 'JobSetupAndRestart') then
  begin
    try
      SendJobdata(BetriebsauftragNr, StrToInt(MaschNr));
      logpos(65);
    except
    end;
  end;
  AbruestenBuchen(Lizenz, BetriebsauftragNr);


  fAuftrag_Optimieren := False;
  fIgnoreWaitingRepair := False;

  if TCO_Setup.GetParamBool(qSuch,'INCL_RunningChangeOnPrintRequest') and fExecuteRC then
  begin
    SQL_Insert(qUpdate,'UPDATE RUnningchangeevents SET Executed = ' + FloatToPunktString(Now) + ' WHERE Maschnr = ' + Maschnr + ' AND BANEW = ''' + Betriebsauftragnr + '''');
  end;

  
  if TCO_Setup.GetParamBool(qSuch, 'INCL_CopySiloOnStart') then
  begin
    VorgaengerAuftrag := '';
    SQLStr := ' SELECT *'
            + ' FROM laufzeitlog'
            + ' WHERE maschnr = ''' + MaschNr + ''''
            + ' ORDER BY auftragende DESC';
    SQL_Get(qSuch, SQLStr);
    if not qSuch.IsEmpty then
      VorgaengerAuftrag := qSuch.FieldByName('betriebsauftragnr').AsString;
    if VorgaengerAuftrag <> '' then
    begin
      if CopySilo(VorgaengerAuftrag, BetriebsauftragNr, qSuch, qSuch2) <> 1 then
        SetActionResult(Fehler_Beim_Material_Kopieren, l_nr);
      logpos(66);
    end;
  end;

  try
    SetStart(Betriebsauftragnr, StatInt);
    logpos(67);
    if MasterAuftrag then
    begin
      SQLGet(qSuch2, 'PDEKombi', 'MasterBetriebsAuftragNr', BetriebsauftragNr, False);
      while not qSuch2.EOF do
      begin
        SetStart(qSuch2.FieldByName('Betriebsauftragnr').AsString, StatInt);
        qSuch2.Next;
      end;
    end;
    logpos(68);
  except
  end;

  fExecuteRC := false;

  logpos(80);
end;

function TCO_Auftrag.Format_String(Wert: string): Integer;
var
  X, Y: array[0..100] of Char;
  I: Integer;
  Nummer: string;
  neg: Boolean;
begin
  Result := 0;
  neg := False;
  if (Wert = '') then
  begin
    Result := 0;
    Exit;
  end;

  I := 0;
  StrPCopy(X, Wert);
  while I < 99 do
  begin
    if (X[I] = #45) then
    begin
      neg := True;
      X[I] := '0';
    end;
    if not (X[I] in [#48..#57]) then
      break;
    Y[I] := X[I];
    Inc(I);
  end;
  Y[I] := #0;
  Nummer := StrPas(Y);
  if not (Nummer = '') then
  begin
    Result := StrToInt(Nummer);
    if neg then
      Result := Result * (-1);
  end;
end;

function TCO_Auftrag.SQL2Get(Query: TCO_Query;
  Tabelle: string; Feld: string; Wert: string; Feld2: string; Wert2: string; Ergebnis: Boolean): Integer;
var
  SQLStr: string;
begin
  SQLStr := 'Select * from ' + Tabelle + ' where (' + Feld + '=''' + Wert + ''') AND(' + Feld2 + '=''' + Wert2 + ''')';

  if (Wert = '') and (Wert2 = '') then
    SQLStr := 'Select * from ' + Tabelle;

  if (not (Wert = '')) and (Wert2 = '') then
    SQLStr := 'Select * from ' + Tabelle + ' where ' + Feld + '=''' + Wert + '''';

  if (Wert = '') and (not (Wert2 = '')) then
    SQLStr := 'Select * from ' + Tabelle + ' where ' + Feld2 + '=''' + Wert2 + '''';

  SQL_Get(Query, SQLStr);

  if Ergebnis then
  begin
    SQLStr := 'Select COUNT(*) CNT from ' + Tabelle + ' where (' + Feld + '=''' + Wert + ''') AND(' + Feld2 + '=''' +
      Wert2
      + ''')';

    if (Wert = '') and (Wert2 = '') then
      SQLStr := 'Select COUNT(*) CNT from ' + Tabelle;

    if (not (Wert = '')) and (Wert2 = '') then
      SQLStr := 'Select COUNT(*) CNT from ' + Tabelle + ' where ' + Feld + '=''' + Wert + '''';

    if (Wert = '') and (not (Wert2 = '')) then
      SQLStr := 'Select COUNT(*) CNT from ' + Tabelle + ' where ' + Feld2 + '=''' + Wert2 + '''';

    qCount.Close;
    SQL_Get(qCount, SQLStr);
    Result := qCount.FieldByName('CNT').AsInteger;
  end
  else
    Result := -1;
end;

function TCO_Auftrag.SetActionResult(ResultNo: integer; lineNo: string) : Integer;
begin
  {$IFNDEF SUPLOGSTAR}
  try
    SQL_Insert(qUpdate, 'UPDATE log_start SET actionresult = ''' + IntToStr(ResultNo) + ''' WHERE nr = ' + LineNo);
  except
  end;
  {$ENDIF}
  Result := ResultNo;
end;

function TCO_Auftrag.Werkzeug_Abspannen(Werkzeug: Integer): Integer;
var
  Status: string;
  SQLStr: string;
procedure StandardAbspannen(Werkzeug: Integer);
begin
    //18.01.2011 RS: Statusint wird nur gezogen, wenn SetupPar-Schalter "INCL_MoldStateFromStateInt" sitzt
    if fWZStatusInt then
      UpdateIntWZStatus(qSuch);

    if SQLGet(qSuch, 'Werkzeug', 'werkzeug', IntToStr(Werkzeug), True) > 0 then
    begin
      Status := qSuch.FieldByName('Status').AsString;
      SQLStr := 'Update WERKZEUG set Status = ''' + CO_AuftragGetL('Lager') + ''', Statusexakt = '''
        + CO_AuftragGetL('Lager') + '''';
      //18.01.2011 RS: Statusint wird nur gezogen, wenn SetupPar-Schalter "INCL_MoldStateFromStateInt" sitzt
      if fWZStatusInt then
        //02.12.2011 RS: Ergänzung StatusInt
        SQLStr := SQLStr + ', StatusInt = 0';
      SQLStr := SQLStr
        + ' WHERE Werkzeug = ''' + IntToStr(Werkzeug) + '''';
      SQL_Insert(qUpdate, SQLStr);
      SQLStr := ' UPDATE Reparatur '
              + ' SET wzaufmaschine = 0'
              + ' WHERE WERKZEUGINDEX = ''' + IntToStr(Werkzeug) + '''';
      try
        SQL_Insert(qUpdate, SQLStr);
      except
      end;
    end;
end;
begin
  Result := 0;
  if TCO_Setup.GetParamBool(qSuch,'MDE_WerkzeugInReparaturWaehrendBetriebsauftrag',True) and not fIgnoreWaitingRepair then
  begin
    //RS 12.03.2015 Nach Rücksprache mit Frau Krüger wird immer abgespannt.
    StandardAbspannen(Werkzeug);
    SQLStr := ' SELECT *'
            + ' FROM REPARATUR'
            + ' WHERE WERKZEUGINDEX = ''' + IntToStr(Werkzeug) + ''''
            + ' AND ENDEREP IS NULL';
    SQL_Get(qSuch, SQLStr);
    if not qSuch.IsEmpty then
    begin
      SQLStr := ' UPDATE Reparatur '
              + ' SET SCHUSSZAHL = ('
              + '       SELECT Einsatzdauer'
              + '       FROM WERKZEUG'
              + '       WHERE WERKZEUG = ''' + IntToStr(Werkzeug) + ''''
              + ' )'
              + ' WHERE WERKZEUGINDEX = ''' + IntToStr(Werkzeug) + ''''
              + ' AND ENDEREP IS NULL';
      SQL_Insert(qUpdate, SQLStr);
      try
        SQLStr := ' UPDATE Reparatur '
                + ' SET wzaufmaschine = 0'
                + ' WHERE WERKZEUGINDEX = ''' + IntToStr(Werkzeug) + ''''
                + ' AND ENDEREP IS NULL';
        SQL_Insert(qUpdate, SQLStr);
      except
      end;
      Result := Werkzeug_Muss_zur_Reparatur;
    end;
  end
  else
    StandardAbspannen(Werkzeug);
  if TCO_Setup.GetParamBool(qSuch2, 'INCL_WZLager') then
  begin
    //RS 29.01.2014 - Eschenbach - Nur, wenn keine chaotische Lagerführung, dann hier wieder einlagern, da sonst in der Oberfläche der Lagerplatz ermittelt / ausgegeben werden muss!
    if not TCO_Setup.GetParamBool(qUpdate, 'MDE_ChaoticMoldStore') then
    begin
      checkcWerkzeug;
      cWerkzeug.WerkzeugIndex := Werkzeug;
      cWerkzeug.Werkzeug_Einlagern;
    end;
  end;
end;

function TCO_Auftrag.Werkzeug_Ruesten(Werkzeug: Integer; Lizenz: string; Betriebsauftragnr: string): Integer;
var
  // Geändert RS 02.12.2011
  StatusInt: Integer;
  SQLStr, WZBez, WZStandort: string;
begin
  Result := 0;

  if TCO_Setup.GetParamInt(qUpdate, 'INCL_JobStartWithoutMOldState') = 1 then
    Exit;

  //18.01.2011 RS: Statusint wird nur gezogen, wenn SetupPar-Schalter "INCL_MoldStateFromStateInt" sitzt
  if fWZStatusInt then
  begin
    UpdateIntWZStatus(qSuch2);
    SQLStr := 'Update WERKZEUG set Status = ''' + CO_AuftragGetL('Lager')
      + ''', StatusExakt = ''' + CO_AuftragGetL('Lager') + ''''
      + ', StatusInt = 0'
      // Geändert RS 02.12.2011
      //+ ' WHERE  Status = ''' + CO_AuftragGetL('Maschine')
      + ' WHERE StatusInt = ''1'
      + ''' AND StatusExakt = ''' + Lizenz + '''';
  end
  else
    SQLStr := 'Update WERKZEUG set Status = ''' + CO_AuftragGetL('Lager')
      + ''', StatusExakt = ''' + CO_AuftragGetL('Lager') + ''''
      + ' WHERE  Status = ''' + CO_AuftragGetL('Maschine')
      + ''' AND StatusExakt = ''' + Lizenz + '''';

  try
    SQL_Insert(qUpdate, SQLStr);
  except
  end;

  if SQLGet(qUpdate, 'WERKZEUG', 'werkzeug', IntToStr(Werkzeug), True) = 0 then
  begin
    Result := Werkzeug_nicht_vorhanden;
    Exit;
  end;

  //18.01.2011 RS: Statusint wird nur gezogen, wenn SetupPar-Schalter "INCL_MoldStateFromStateInt" sitzt
  StatusInt := RetrieveToolState(qUpdate);

  WZBez := qUpdate.FieldByName('werkzeugbez').AsString;
  WZStandort := qUpdate.FieldByName('WZStandort').AsString;

  if Pos('DUMMY', UpperCase(WzBez)) + Pos('OFFLINE', UpperCase(WzBez)) > 0 then
    Exit;

  if WZStandort <> '' then
  begin
    SQLStr := 'select Maschstandort.Standort from Maschine, MaschStandort'
      + ' where Maschine.StandortId = MaschStandort.StandortId'
      + ' and Maschine.Lizenz = ''' + Lizenz + '''';
    SQL_Get(qUpdate, SQLStr);
    if qUpdate.FieldByName('Standort').AsString <> WZStandort then
    begin
      Result := Werkzeug_nicht_im_Standort;
      Exit;
    end;
  end;

  // Geändert RS 02.12.2011
  //if Status = CO_AuftragGetL('Maschine') then
  if StatusInt = 1 then
  begin
    if Pos('Dummy', wzbez) = 0 then
    begin
      Result := Werkzeug_nicht_auf_Maschine;
      Exit;
    end;
  end;

  if TCO_Setup.GetParamBool(qUpdate, 'MDE_WZ_Automatich_vom_Reparatur') then
  begin
    // Geändert RS 02.12.2011
    //if Status = CO_AuftragGetL('Reparatur') then
    if StatusInt = 2 then
    begin
      SQLStr := 'Update REPARATUR set EndeRep = ''' + DateToStr(Date) + ''', EndeRepINT = '
        + FloatToPunktString(Now) + ' where (WerkzeugIndex = ''' + IntToStr(Werkzeug) + ''') and (EndeRepINT is Null)';
      SQL_Insert(qUpdate, SQLStr);
      SQLStr := 'Update WERKZEUG set Status = ''' + CO_AuftragGetL('Lager') + ''', StatusExakt = '''
        + CO_AuftragGetL('Lager') + ''', LetzteWartung = ''' + DateToStr(Date) + '''';
      //18.01.2011 RS: Statusint wird nur gezogen, wenn SetupPar-Schalter "INCL_MoldStateFromStateInt" sitzt
      if fWZStatusInt then
        //02.12.2011 RS: Ergänzung StatusInt
        SQLStr := SQLStr + ', StatusInt = 0';
      SQLStr := SQLStr + ' WHERE Werkzeug = ''' + IntToStr(Werkzeug) + '''';
      SQL_Insert(qUpdate, SQLStr);

      StatusInt := 0;
    end;
  end
  else
  begin
    SQLStr := ' SELECT *'
            + ' FROM reparatur'
            + ' WHERE  ( (WerkzeugIndex = ''' + IntToStr(Werkzeug) + ''') and (EndeRepINT is Null OR Enderepint = 0) )'
            + ' AND ( Betriebsauftragnr IS NULL OR betriebsauftragnr = '''' OR betriebsauftragnr = ''' + Betriebsauftragnr + ''')';
    SQL_Get(qCount, SQLStr);
    if not qCount.IsEmpty then
      StatusInt := 2;
  end;

  if StatusInt <> 0 then
  begin
    Result := Werkzeug_nicht_auf_Maschine;
    Exit;
  end;

  //18.09.2013 Eschenbach. Es werden alle werkzeuge aus der Stückliste auf Reparatur geprüft, die in Werkzeug_typ entsprechend gekennzeichnet sind
  if TCO_Setup.GetParamBool(qSuch, 'INCL_CheckAddToolsOnStart') then
  begin
    SQLStr := 'SELECT wsl.werkzeug, wt.*'
            + ' FROM PDE p'
            + ' INNER JOIN werkzeugstueckliste wsl ON wsl.auftragnr = p.auftragnr'
            + ' INNER JOIN werkzeug_typ wt on wsl.typnr = wt.nr'
            + ' INNER JOIN reparatur r ON r.werkzeugindex = wsl.werkzeug'
            + ' WHERE p.betriebsauftragnr = '''+ Betriebsauftragnr + ''''
            + ' AND wt.startrelevant = 1'
            + ' AND ( r.enderepint = 0 OR r.enderepint IS NULL)'
            + ' AND (r.betriebsauftragnr IS NULL OR r.betriebsauftragnr = '''' OR r.betriebsauftragnr = '''+ Betriebsauftragnr + ''')';
    SQL_Get(qCount, SQLStr);
    if not qCount.IsEmpty then
    begin
      Result := Einsatz_in_Reparatur;
      Exit;
    end;
  end;
  SQLStr := 'Update WERKZEUG set Status = ''' + CO_AuftragGetL('Maschine')
    + ''', StatusExakt = ''' + Lizenz + '''';
  //18.01.2011 RS: Statusint wird nur gezogen, wenn SetupPar-Schalter "INCL_MoldStateFromStateInt" sitzt
  if fWZStatusInt then
    //02.12.2011 RS: Ergänzung StatusInt
    SQLStr := SQLStr + ', StatusInt = 1';
  SQLStr := SQLStr
    + ' WHERE Werkzeug = ''' + IntToStr(Werkzeug) + '''';
  SQL_Insert(qUpdate, SQLStr);

  //RS 29.01.2014 - Eschenbach - Lagerplatz-Historie wird geschrieben
  if TCO_Setup.GetParamBool(qSuch2, 'INCL_WZLager') then
  begin
    checkcWerkzeug;
    cWerkzeug.WerkzeugIndex := Werkzeug;
    cWerkzeug.Werkzeug_Auslagern(Lizenz);
  end;
  Exit;
end;

procedure TCO_Auftrag.SQL_Get(Query: TCO_Query; SQLStr: string);
begin
  if Query.Active then
    Query.Close;
  Query.SQL.Clear;
  Query.SQL.Add(SQLStr);
  Query.Open;
  Query.First;
end;

procedure TCO_Auftrag.SQL_Insert(Query: TCO_Query; SQLStr: string);
var
  f: TextFile;
begin
  Query.Close;
  Query.SQL.Clear;
  Query.SQL.Add(SQLStr);
{$IFDEF DEBUG}
  try
    Query.ExecSQL;
  except
    on ex: Exception do
    begin
      try
        System.Assign( f, ExOutputFile);
        System.Append( f);
        Writeln( f, ex.Message);
        Writeln( f, SQLStr);
        Close( f);
      except
        Close( f);
        ShowMessage('Exeption in CO_AUFTRAG:' + ex.Message + ' - SQL: ' + SQLStr);
      end;
    end;
  end;
{$ELSE}
  Query.ExecSQL;
{$ENDIF}
  Query.Close;
end;

function TCO_Auftrag.SQLGet(Query: TCO_Query;
  Tabelle: string; Feld: string; Wert: string; Ergebnis: Boolean): Integer;
var
  SQLStr: string;
begin
  if Ergebnis then
  begin
    SQLStr := 'Select COUNT(*) CNT from ' + Tabelle + ' where ' + Feld + '=''' + Wert + '''';
    Query.Close;
    SQL_Get(Query, SQLStr);
    Result := Query.FieldByName('CNT').AsInteger;
  end
  else
    Result := -1;

  SQLStr := 'Select * from ' + Tabelle + ' where ' + Feld + '=''' + Wert + '''';
  SQL_Get(Query, SQLStr);
end;

procedure TCO_Auftrag.UpdateSQL(Query: TCO_Query;
  Tabelle: string; UpdateFeld: string; UpdateWert: string; WhereFeld: string; WhereWert: string);
var
  SQLStr: string;
begin
  SQLStr := 'UPDATE ' + Tabelle + ' SET ' + UpdateFeld + '=''' + UpdateWert + ''' where ' + WhereFeld + '=''' +
    WhereWert + '''';
  SQL_Insert(Query, SQLStr);
end;

procedure TCO_Auftrag.UpdateSQLPunkt(Query: TCO_Query;
  Tabelle: string; UpdateFeld: string; UpdateWert: string; WhereFeld: string; WhereWert: string);
var
  SQLStr: string;
begin
  SQLStr := 'UPDATE ' + Tabelle + ' SET ' + UpdateFeld + '=' + UpdateWert + ' where ' + WhereFeld + '=''' +
    WhereWert + '''';
  SQL_Insert(Query, SQLStr);
end;

function TCO_Auftrag.GetDatumZeitString(DZeit: TDateTime): string;
var
  Year, Month, Day, Hour, Min, Sec, MSec: Word;
  Wert, MinStr, APM: string;
begin
  DecodeDate(DZeit, Year, Month, Day);
  DecodeTime(DZeit, Hour, Min, Sec, MSec);
  if fSpracheNr = 15000 then
  begin
    Wert := IntToStr(Month) + '/' + IntToStr(Day) + '/' + IntToStr(Year);
    APM := 'AM';
    if Hour > 11 then
    begin
      Hour := Hour - 12;
      APM := 'PM';
    end;
    if Hour = 0 then
      Hour := 12;
    MinStr := IntToStr(Min);
    if Min < 10 then
      MinStr := '0' + MinStr;
    Wert := Wert + ' ' + IntToStr(Hour) + ':' + MinStr + ' ' + APM;
  end
  else
  begin
    Wert := IntToStr(Day) + '.' + IntToStr(Month) + '.' + IntToStr(Year);
    MinStr := IntToStr(Min);
    if Min < 10 then
      MinStr := '0' + MinStr;
    Wert := Wert + ' / ' + IntToStr(Hour) + ':' + MinStr;
  end;
  Result := Wert;
end;

procedure TCO_Auftrag.CheckWerkzeugAarchiv(banr : string);
var
  SQLStr: string;
begin
  try
    SQLStr := 'update aarchiv set werkzeug = (select werkzeug from werkzeug'
      + ' where werkzeugduplo = aarchiv.werkzeugnr or WerkzeugNr = aarchiv.werkzeugnr) where werkzeug is null';
    SQL_Insert(qUpdate, SQLStr);
  except
    try
      SQLStr := 'update aarchiv set werkzeug = (select werkzeug from werkzeug'
        + ' where werkzeugduplo = aarchiv.werkzeugnr or WerkzeugNr = aarchiv.werkzeugnr) '
        + ' where betriebsauftragnr = ''' + banr + ''' AND werkzeug is null';
      SQL_Insert(qUpdate, SQLStr);
    except

    end;
  end;
  try
    SQLStr := 'update aarchiv set werkzeug = 0 where werkzeug is null ';
    SQL_Insert(qUpdate, SQLStr);
  except
  end;
end;

function TCO_Auftrag.Autoterminierung: Boolean;
var
  SQLStr, Lizenz: string;
  I, Nummer: Integer;
  EndDatum: Real;
  Takt, Soll, Nr, SNR: Integer;
  KopfStr: string;
  Kopf: Integer;
  EndeZeitpunkt: Real;
  Ins: Boolean;
  Schwesterauftrag: string;
  Dauer: Integer;
begin
  Result := True;
  SQLStr := 'Select COUNT(DISTINCT(Lizenz)) from PDE';
  SQL_Get(qSuch, SQLStr);
  SQLStr := 'Select DISTINCT(Lizenz) from PDE Order by Lizenz';
  qSuch2.Close;
  qSuch2.SQL.Clear;
  qSuch2.SQL.Add(SQLStr);
  qSuch2.Open;
  qSuch2.First;
  while not qSuch2.EOF do
  begin
    Lizenz := qSuch2.FieldByName('Lizenz').AsString;

    if not FOpt_Metall then
      SQLStr := 'select * from PDE where Lizenz = '''
        + Lizenz + ''' Order by stat,StartDatumZeit'
    else
      SQLStr := 'select * from PDE where Lizenz = '''
        + Lizenz + ''' AND (stat > 1) Order by StartDatumZeit';

    qSuch.Close;
    qSuch.SQL.Clear;
    qSuch.SQL.Add(SQLStr);
    qSuch.Open;
    qSuch.First;
    I := 2;
    while not qSuch.EOF do
    begin
      Nummer := qSuch.FieldByName('Nr').AsInteger;
      UpdateSQL(qUpdate, 'PDE', 'PlanNr', IntToStr(I),
        'Nr', IntToStr(Nummer));
      Inc(I);
      qSuch.Next;
    end;

    Ins := False;
    SQLStr := 'select Nr, Lizenz, Betriebsauftragnr, Plannr, SAuftrag, Schwesterauftrag,'
      + ' StartDatumZeit, EndDatumZeit, Taktzeit, Sollwert, Kopfgroesse from PDE'
      + ' where Lizenz = ''' + Lizenz + '''  Order by PlanNr';
    qSuch.Close;
    qSuch.SQL.Clear;
    qSuch.SQL.Add(SQLStr);
    qSuch.Open;
    qSuch.First;
    while not qSuch.EOF do
    begin

      if qSuch.FieldByName('SAuftrag').AsInteger = 1 then
      begin
        qSuch.Next;
        if qSuch.EOF then
          break;
      end;

      Ins := False;

      EndDatum := StrToFloat(qSuch.FieldByName('EndDatumZeit').AsString);

      qSuch.Next;
      if qSuch.EOF then
        break;
      //if Daten.qSuch.EOF then Daten.qSuch.Prior;

      if qSuch.FieldByName('SAuftrag').AsInteger = 1 then
      begin
        qSuch.Next;
        if qSuch.EOF then
          break;
      end;

      Takt := qSuch.FieldByName('Taktzeit').AsInteger;

      if TCO_Setup.GetParamBool(qSuch2, 'FP_Plantakt', False) then
        Takt := qSuch.FieldByName('Planzykluszeit').AsInteger;
      if TCO_Setup.GetParamBool(qSuch2, 'FP_Ausschussquote', False) then
        Takt := Trunc(Takt * (1 + (qSuch.FieldByName('Ausschussquote').AsInteger / 10000)));

      Soll := Format_String(qSuch.FieldByName('Sollwert').AsString);
      Nr := qSuch.FieldByName('Nr').AsInteger;
      Schwesterauftrag := qSuch.FieldByName('Schwesterauftrag').AsString;

      // if (StartDatumNext < EndDatum) OR Option.Term_All then begin
      //Startzeiten und Endzeiten neu berechnen
      KopfStr := qSuch.FieldByName('Kopfgroesse').AsString;
      Kopf := Format_String(KopfStr);

      Dauer := Trunc(Soll * Takt / (6000 * Kopf));
      if Dauer = 0 then
        Dauer := 10;
      EndeZeitpunkt := GetEndeDatumLizenz(Lizenz, qSuch.FieldByName('Betriebsauftragnr').AsString,
        EndDatum, Dauer);

      SQLStr := 'update PDE set '
        + 'StartDatumSTR = ''' + GetDatumZeitString(EndDatum)
        + ''',EndDatumSTR = ''' + GetDatumZeitString(EndeZeitpunkt)
        + ''',StartDatumZeit = ' + FloatToPunktString(EndDatum)
        + ',EndDatumZeit = ' + FloatToPunktString(EndeZeitpunkt)
        + ',Change_Art = ''P'
        + ''' where (Nr = ''' + IntToStr(Nr) + ''')';

      SQL_Insert(qUpdate, SQLStr);
      Ins := True;

      //Schwesterauftrag ändern
      if Schwesterauftrag <> '' then
        if SQLGet(qUpdate, 'PDE', 'BetriebsauftragNr', Schwesterauftrag, True) > 0 then
        begin
          SNR := qUpdate.FieldByName('Nr').AsInteger;
          SQLStr := 'update PDE set '
            + 'StartDatumSTR = ''' + GetDatumZeitString(EndDatum)
            + ''',EndDatumSTR = ''' + GetDatumZeitString(EndeZeitpunkt)
            + ''',StartDatumZeit = ' + FloatToPunktString(EndDatum)
            + ',EndDatumZeit = ' + FloatToPunktString(EndeZeitpunkt)
            + ' where (Nr = ''' + IntToStr(SNR) + ''')';

          SQL_Insert(qUpdate, SQLStr);
        end;
      // Tabelle Aktualisieren
      SQLStr := 'select Nr, BetriebsauftragNr, Lizenz, Plannr, SAuftrag, Schwesterauftrag,'
        + ' StartDatumZeit,EndDatumZeit,Taktzeit,Sollwert,Kopfgroesse from PDE'
        + ' where Lizenz = ''' + Lizenz + '''  Order by PlanNr';
      qSuch.Close;
      qSuch.SQL.Clear;
      qSuch.SQL.Add(SQLStr);
      qSuch.Open;
      qSuch.Locate('Nr', Nr, []);
      //  end; //if (StartDatumNext < EndDatum) then begin
    end;

    if not Ins then
      qSuch2.Next;
  end; // while not Daten.qSuch2.EOF

end;

function TCO_Auftrag.Laufende_Auftraege_Terminieren: Boolean;
var
  SQLStr, Lizenz: string;
  StartDatum, EndDatum: Real;
  Takt, Soll, Nr, SNR: Integer;
  KopfStr: string;
  Kopf: Integer;
  EndeZeitpunkt: Real;
  Schwesterauftrag: string;
  Dauer: Integer;
begin
  Result := True;
  SQLStr := 'Select COUNT(DISTINCT(Lizenz)) from PDE';
  SQL_Get(qSuch, SQLStr);
  SQLStr := 'Select DISTINCT(Lizenz) from PDE Order by Lizenz';
  qSuch2.Close;
  qSuch2.SQL.Clear;
  qSuch2.SQL.Add(SQLStr);
  qSuch2.Open;
  qSuch2.First;
  while not qSuch2.EOF do
  begin
    Lizenz := qSuch2.FieldByName('Lizenz').AsString;
    SQLStr := 'select * from PDE where Lizenz = ''' + Lizenz + ''' AND STAT = 0';
    qSuch.Close;
    qSuch.SQL.Clear;
    qSuch.SQL.Add(SQLStr);
    qSuch.Open;
    qSuch.First;
    while not qSuch.EOF do
    begin
      Nr := qSuch.FieldByName('Nr').AsInteger;
      StartDatum := StrToFloat(qSuch.FieldByName('StartDatumZeit').AsString);
      if StartDatum > Now then
      begin
        StartDatum := Now;
        UpdateSQLPunkt(qUpdate, 'PDE', 'StartDatumZeit', FloatToPunktString(StartDatum), 'Nr', IntToStr(Nr));
        UpdateSQL(qUpdate, 'PDE', 'StartDatumStr', GetDatumZeitString(StartDatum), 'Nr', IntToStr(Nr));
      end;
      EndDatum := StrToFloat(qSuch.FieldByName('EndDatumZeit').AsString);
      Takt := qSuch.FieldByName('Taktzeit').AsInteger;

      if TCO_Setup.GetParamBool(qSuch2, 'FP_Plantakt', False) then
        Takt := qSuch.FieldByName('Planzykluszeit').AsInteger;
      if TCO_Setup.GetParamBool(qSuch2, 'FP_Ausschussquote', False) then
        Takt := Trunc(Takt * (1 + (qSuch.FieldByName('Ausschussquote').AsInteger / 10000)));

      Soll := Format_String(qSuch.FieldByName('Sollwert').AsString) -
        Format_String(qSuch.FieldByName('Istwert').AsString);
      if Soll < 1 then
      begin //solmenge bereits erreicht
        UpdateSQL(qUpdate, 'PDE', 'Plannr', '1', 'Nr', IntToStr(Nr));
        qSuch.Next;
        Continue;
      end;
      Schwesterauftrag := qSuch.FieldByName('Schwesterauftrag').AsString;
      KopfStr := qSuch.FieldByName('Kopfgroesse').AsString;
      Kopf := Format_String(KopfStr);
      if Kopf = 0 then
        Kopf := 1;
      Dauer := Trunc(Soll * Takt / (6000 * Kopf));
      if Dauer = 0 then
        Dauer := 10;
      EndeZeitpunkt := GetEndeDatumLizenz(Lizenz, qSuch.FieldByName('Betriebsauftragnr').AsString, Now, Dauer);
      if EndeZeitpunkt <> EndDatum then
      begin
        SQLStr := 'update PDE set '
          + 'EndDatumSTR = ''' + GetDatumZeitString(EndeZeitpunkt)
          + ''',EndDatumZeit = ' + FloatToPunktString(EndeZeitpunkt)
          + ',Change_Art = ''P'
          + ''',PlanNr = ''1'
          + ''' where (Nr = ''' + IntToStr(Nr) + ''')';
        SQL_Insert(qUpdate, SQLStr);

        if Schwesterauftrag <> '' then
          if SQLGet(qUpdate, 'PDE', 'BetriebsauftragNr', Schwesterauftrag, True) > 0 then
          begin
            SNR := qUpdate.FieldByName('Nr').AsInteger;
            SQLStr := 'update PDE set '
              + 'EndDatumSTR = ''' + GetDatumZeitString(EndeZeitpunkt)
              + ''',EndDatumZeit = ' + FloatToPunktString(EndeZeitpunkt)
              + ',Change_Art = ''P'
              + ''' where (Nr = ''' + IntToStr(SNR) + ''')';

            SQL_Insert(qUpdate, SQLStr);
          end;
      end;
      qSuch.Next;
    end;
    qSuch2.Next;
  end;
end;

function TCO_Auftrag.Takt2Excel(Auftrag: string; Pfad: string; ArtikelNr: string): Integer;
var
  Datei, fneu: string;
  SQLStr: string;
  Tmp, I: Integer;
  Fehler: string;
  F: TextFile;
begin
  Result := 0;
  Datei := CO_AuftragGetL('TAKT_') + Auftrag + '_' + ArtikelNr;
  for I := 1 to Length(Datei) do
    if Datei[I] in ['/', '*', '\', '?'] then
      Datei[I] := '_';

  SQLStr := 'Select Lizenz,AUFTRAGNR,DATUMSTR,Taktzeit,Schuss from Taktzeiten where Auftragnr=''' + Auftrag + ''''
    + ' ORDER BY schuss';
  SQL_Get(qSuch, SQLStr);
  I := 0;
  repeat
    fneu := Datei;
    if I > 0 then
      fneu := Datei + '_' + IntToStr(I);
    I := I + 1;
  until not FileExists(Pfad + fneu + '.xls');

  Datei := fneu + '.xls';

  try
    Tmp := Tabelle2Excel2(Datei, Pfad, SQLStr);
  except
    Tmp := -1;
  end;

  if Tmp <> 0 then
    Fehler := CO_AuftragGetL('Fehler:') + #13#10
      + '' + #13#10
      + CO_AuftragGetL('Es ist ein Fehler beim Excelexport aufgetreten.') + #13#10
      + CO_AuftragGetL('Ereigniss-Nr: ') + IntToStr(Tmp);

  if not FileExists(Pfad + 'Export_to_excel.txt') then
  begin
    AssignFile(F, Pfad + 'Export_to_excel.txt');
    Rewrite(F);
    WriteLn(F, CO_AuftragGetL('Datei erstellt ') + DateTimeToStr(Now) + #13#10);
    CloseFile(F);
  end;

  if FileExists(Pfad + 'Export_to_excel.txt') then
  begin
    AssignFile(F, Pfad + 'Export_to_excel.txt');
    Append(F);
    WriteLn(F, Fehler + #13#10 + CO_AuftragGetL('Eintrag vom:') + DateTimeToStr(Now));
    Flush(F);
    CloseFile(F);
  end;
end;

function TCO_Auftrag.Tabelle2Excel2(DateiName: string; Path: string; SQLStr: string): Integer;
var
  I: Integer;
  Datei, S, NewPath, NewDateiname: string;
  FStream: TFileStream;
  J, K, Tp: Integer;
  T: string;
begin
  Result := 0;

  if DateiName = '' then
  begin
    Result := 4;
    Exit;
  end;
  if Path = '' then
  begin
    Result := 5;
    Exit;
  end;
  if SQLStr = '' then
  begin
    Result := 6;
    Exit;
  end;

  if Path[Length(Path)] <> '\' then
    NewPath := Path + '\'
  else
    NewPath := Path;

  if DateiName[Length(DateiName) - 3] <> '.' then
    NewDateiname := DateiName + '.xls'
  else
    NewDateiname := DateiName;

  Datei := NewPath + NewDateiname;

  FStream := TFileStream.Create(Datei, fmCreate);

  XlsBeginStream(FStream, 0);

  SQL_Get(qSuch, SQLStr);
  qSuch.First;

  J := 1;
  try
    for I := 0 to qSuch.FieldCount - 1 do
    begin
      S := qSuch.Fields[I].Fieldname;
      XlsWriteCellLabel(FStream, I + 1, J, CO_AuftragGetL(S));
    end;
  except
  end;
  Inc(J);
  qSuch.Close;

  qSuch.Open;
  K := qSuch.FieldCount - 1;
  try
    while not qSuch.EOF do
    begin
      for I := 0 to K do
      begin
        T := qSuch.Fields[I].AsString;
        Tp := 0;
        if StringIsNumber(T) then
        begin
          if Length(T) < 10 then
          try
            if StringIsInteger(T) then
            begin
              StrToInt(T);
              Tp := 1;
            end
            else
            begin
              StrToFloat(T);
              Tp := 2;
            end;
          except
            try
              StrToFloat(T);
              Tp := 2;
            except
            end;
          end;
        end;
        case Tp of
          0: XlsWriteCellLabel(FStream, I + 1, J, T);
          1: XlsWriteCellRk(FStream, I + 1, J, StrToInt(T));
          2: XlsWriteCellNumber(FStream, I + 1, J, StrToFloat(T));
        end;
      end;
      Inc(J);
      qSuch.Next;
    end;
  finally
    qSuch.Close;
  end;

  XlsEndStream(FStream);
  FStream.Free;
end;

function TCO_Auftrag.GetTaktzeitToleranz: Integer;
var
  Tmp: Integer;
begin
  Tmp := fTaktVergleichToleranz;
  if Tmp <= 0 then
    Tmp := 10;
  if Tmp >= 100 then
    Tmp := 10;
  Result := Tmp;
end;

function TCO_Auftrag.CheckMaster(Betriebsauftragnr: string; defaultValue: Boolean): Boolean;
begin
  result := defaultValue;
  if not result and TCO_Setup.GetParamBool(qSuch2, 'INCL_Correct_MasterAuftrag')then
  begin
    SQL_Get(qSuch2, 'Select * from pdekombi where masterbetriebsauftragnr = ''' + BetriebsauftragNr + '''');
    if not qSuch2.IsEmpty then
    begin
      SQL_Insert(qSuch2, 'UPDATE pde set masterauftrag = 1 WHERE betriebsauftragnr = ''' + BetriebsauftragNr + '''');
      result := True;
    end;
  end;
end;

function TCO_Auftrag.GetIstTakt(Maschine: string): Integer; //Ausgabe des Isttaktes (1000 = 10 sek.)
var
  SQLStr: string;
  Takt: Integer;
begin
  SQLStr := 'select taktmittel as Takt from pde where Lizenz = ''' + Maschine + ''' and stat < 2';
  SQL_Get(qSuch2, SQLStr);
  Takt := Round(qSuch2.FieldByName('TAKT').AsFloat * 100);
  if Takt < 1 then
  begin
    SQLStr := 'select avg(Taktzeit) as Takt from Taktzeiten where Lizenz = ''' + Maschine + '''';
    SQL_Get(qSuch2, SQLStr);
    Takt := Trunc(qSuch2.FieldByName('TAKT').AsFloat * 100);

    if Takt < 1 then
    begin
      //Keine Taktzeiten im Protokoll verfügbar, also Solltakt ermitteln...
      SQLStr := 'select Taktzeit from PDE where Lizenz = ''' + Maschine + ''' AND stat < 2';
      SQL_Get(qSuch2, SQLStr);

      Takt := qSuch2.FieldByName('Taktzeit').AsInteger;
      if Takt < 1 then
        Takt := 1000; //ERROR: keine Taktzeit gefunden, also Standard Wert
    end;
  end;

  Result := Takt;

end;

procedure TCO_Auftrag.InsertOfflineMaschinen(Maschine: string);
var
  S: string;
  Soll, Ist, PRZ: Integer;
  WZ: string;
  MaschNr: string;
begin
  S := 'select Count(*) as CNT from Maschoffline where Lizenz = ''' + Maschine + '''';
  SQL_Get(qSuch2, S);
  if qSuch2.FieldByName('CNT').AsInteger = 0 then
    Exit; //keine OfflineMAschine !!

  S := 'select MASCHNR from Maschoffline where Lizenz = ''' + Maschine + '''';
  SQL_Get(qSuch2, S);
  MaschNr := qSuch2.FieldByName('MaschNr').AsString;

  S := 'Delete from Maschinf where Lizenz = ''' + Maschine + '''';
  SQL_Insert(qUpdate, S);
  S := 'select Count(*) as CNT from PDE where Lizenz = ''' + Maschine + ''''
    + ' and (Stat = 0 or Stat = 1)';
  SQL_Get(qSuch2, S);
  if qSuch2.FieldByName('CNT').AsInteger > 0 then
  begin
    S := 'select * from PDE where Lizenz = ''' + Maschine + ''''
      + ' and (Stat = 0 or Stat = 1)';
    SQL_Get(qSuch2, S);
    Soll := qSuch2.FieldByName('Sollwert').AsInteger;
    try
      Ist := qSuch2.FieldByName('Istwert').AsInteger;
    except
      Ist := 0;
    end;
    if SQLGet(qUpdate, 'Werkzeug', 'Werkzeug',
      qSuch2.FieldByName('Werkzeug').AsString, True) > 0 then
      WZ := qUpdate.FieldByName('WerkzeugNr').AsString
    else
      WZ := '';
    try
      PRZ := Ist * 100 div Soll;
    except
      PRZ := 0;
    end;
    S := 'insert Into MaschInf ('
      + 'Nr, Lizenz, DatumZeit, Maschine,MaschNr,MaschNrInt, ZUSTAND, ZUSTANDINT, Taktzeit,'
      + ' Sollwert, ISTWERT_PRZ, STUECK,'
      + ' LTSOLL, LTIST, Stat, ArtikelNr,'
      + ' BetriebsAuftragNr, Bezeichnung, AUSSCHUSS,'
      + ' Werkzeug, WERKZEUG_NR,'
      + ' TAKTZEIT_STR) values (MaschinfId.NextVal,'
      + ' ''' + Maschine + ''','
      + FloatToPunktString(Now) + ','
      + ' ''' + Maschine + ''','
      + ' ''' + MaschNr + ''','
      + ' ''' + MaschNr + ''','
      + ' ''' + CO_AuftragGetL('offline') + ''','
      + ' ''3'','
      + ' ''' + qSuch2.FieldByName('Taktzeit').AsString + ''','
      + ' ''' + IntToStr(Soll) + ''','
      + ' ''' + IntToStr(PRZ) + ' %'','
      + ' ''' + IntToStr(Ist) + ''','
      + ' ''' + qSuch2.FieldByName('Termin2').AsString + ''','
      + ' ''' + qSuch2.FieldByName('EndDatumZeit').AsString + ''','
      + ' ''' + qSuch2.FieldByName('Stat').AsString + ''','
      + ' ''' + qSuch2.FieldByName('AuftragNr').AsString + ''','
      + ' ''' + qSuch2.FieldByName('BetriebsAuftragNr').AsString + ''','
      + ' ''' + qSuch2.FieldByName('Bezeichnung').AsString + ''','
      + ' ''' + qSuch2.FieldByName('Ausschuss').AsString + ''','
      + ' ''' + WZ + ''','
      + ' ''' + WZ + ''','
      + ' ''' + qSuch2.FieldByName('TaktzeitStr').AsString + ''')';
    try
      SQL_Insert(qUpdate, S);
    except
    end;
  end
  else
  begin
    S := 'insert Into MaschInf ('
      + 'Nr, Lizenz,Bezeichnung,Pack, DatumZeit, Maschine,MaschNr,MaschNrInt, ZUSTAND, ZUSTANDINT, Taktzeit,'
      + ' Sollwert, ISTWERT_PRZ, STUECK, Stat, AUSSCHUSS, TAKTZEIT_STR) values (MaschinfId.NextVal,'
      + ' ''' + Maschine + ''','
      + ' ''' + CO_AuftragGetL('kein aktueller Auftrag') + ''','
      + ' ''0'','
      + FloatToPunktString(Now) + ','
      + ' ''' + Maschine + ''','
      + ' ''' + MaschNr + ''','
      + ' ''' + MaschNr + ''','
      + ' ''' + CO_AuftragGetL('offline') + ''','
      + ' ''3'','
      + ' ''0'','
      + ' ''0'','
      + ' ''0 %'','
      + ' ''0'','
      + ' ''0'','
      + ' ''0'','
      + ' ''0'')';
    try
      SQL_Insert(qUpdate, S);
    except
    end;
  end;
end;

function TCO_Auftrag.Verpacken(BAuftragnr: string; Menge: Integer;
  bar: string; aBuchungsTermin: TDateTime; PersonalNr, BCId: string; ForcePackLogDate: string= ''): Integer;
const
  Err_fehlerlos = 0;
  Err_Auftrag_abgesclossen = 1;
  Err_Auftrag_nicht_angemeldet = 2;
var
  BetriebsauftragNr, Lizenz: string;
  S, SQLStr, SQLCountSTR: string;
  Status: Integer;
  Produziert, Verpackt: Integer;
  Packgroesse, Ausschuss: Integer;
  sTxt, Maschine, Bez, AuftragNr, Kunde: string;
  Differenz: Integer;
  Zeit, Buchungszeitpunkt: TDateTime;
  Zg, AG, BCNr: Integer;
  Find: Boolean;
  ErrorMsg: Integer;
  EDatum: Real;
begin
  EDatum := Now;
  Find := False;
  Packgroesse := 0;
  ErrorMsg := Err_fehlerlos;
    Buchungszeitpunkt := Now;
  Buchungszeitpunkt := aBuchungsTermin;
  if (aBuchungsTermin < 40000) or (aBuchungsTermin > 60000) then
    Buchungszeitpunkt := Now
  else
    Buchungszeitpunkt := aBuchungsTermin;
  sTxt := CO_AuftragGetL('Artikel erfolgreich gebucht...');

  Zg := 0;
  AG := 0;
  if Menge > 0 then
    Zg := Menge
  else
    AG := -Menge;

  if SQLGet(qSuch, 'BCLeser', 'Serial', BCId, True) = 0 then
  begin
    S := 'insert into BCLeser (Nr, Serial) values (BCLeserId.NextVal,'
      + '''' + BCId + ''')';
    SQL_Insert(qUpdate, S);
    SQLGet(qSuch, 'BCLeser', 'Serial', BCId, False);
  end;
  BCNr := qSuch.FieldByName('Nr').AsInteger;

  AuftragNr := '';

  if SQLGet(qSuch, 'AArchiv', 'Betriebsauftragnr', BAuftragnr, True) > 0 then
  begin
    if qSuch.FieldByName('ENDESTATUS').AsString = CO_AuftragGetL('abgeschlossen') then
    begin
      ErrorMsg := Err_Auftrag_abgesclossen;
    end
    else
    begin
      Find := True;
      qSuch.Last;

      BetriebsauftragNr := qSuch.FieldByName('Betriebsauftragnr').AsString;
      Maschine := qSuch.FieldByName('Maschine').AsString;
      AuftragNr := qSuch.FieldByName('Auftragnr').AsString;
      Bez := qSuch.FieldByName('Bezeichnung').AsString;
      Kunde := qSuch.FieldByName('Kunde').AsString;
      try
        EDatum := qSuch.FieldByName('EndDatumZeit').AsFloat;
      except
        EDatum := 0;
      end;
      if EDatum = 0 then
        EDatum := Now;

      if qSuch.FieldByName('EndeStatus').AsString <> '' then
      try
        Packgroesse := StrToInt(qSuch.FieldByName('Packgroesse').AsString);
      except
        Packgroesse := 0;
      end;
    end;
  end
  else
  begin
    Result := Err_Auftrag_nicht_angemeldet;
    Exit;
  end;

  if SQLGet(qSuch, 'PDE', 'Betriebsauftragnr', BAuftragnr, True) > 0 then
  begin
    EDatum := Now;
    Find := True;
    Lizenz := qSuch.FieldByName('Lizenz').AsString;
    Maschine := Lizenz;
    AuftragNr := qSuch.FieldByName('Auftragnr').AsString;
    Bez := qSuch.FieldByName('Bezeichnung').AsString;
    Kunde := qSuch.FieldByName('Kunde').AsString;
    Packgroesse := Format_String(qSuch.FieldByName('Packgroesse').AsString);

    try
      Status := StrToInt(qSuch.FieldByName('Stat').AsString);
    except
      Status := 0;
    end;
    BetriebsauftragNr := BAuftragnr;
    if not (Status in [0, 1, 4]) then
    begin
      SQLCountSTR := 'Select count(*) CNT from PDE where Lizenz = ''' + Lizenz + ''' AND (stat = 0 or stat = 1)';
      SQL_Get(qCount, SQLCountSTR);
      if qCount.FieldByName('CNT').AsInteger > 0 then
      begin
        SQLStr := 'Insert Into AUFTRAGENDE (Nr, Lizenz) Values ('
          + 'AUFTRAGENDEID.Nextval,'
          + '''' + Lizenz + ''')';
        SQLCountSTR := 'Select Count(*) as CNT from AUFTRAGENDE where Lizenz=''' + Lizenz + '''';
        SQL_Get(qCount, SQLCountSTR);
        if qCount.FieldByName('CNT').AsInteger = 0 then
          SQL_Insert(qUpdate, SQLStr);
      end;
      SQLStr := 'Insert Into AUFTRAGSTART (Nr, Betriebsauftragnr) Values (AUFTRAGSTARTID.Nextval,'
        + '''' + BetriebsauftragNr + ''')';
      SQLCountSTR := 'Select Count(*) as CNT from AUFTRAGSTART where Betriebsauftragnr='''
        + BetriebsauftragNr + '''';
      SQL_Get(qCount, SQLCountSTR);
      if qCount.FieldByName('CNT').AsInteger = 0 then
        SQL_Insert(qUpdate, SQLStr);
    end;

    if SQLGet(qSuch, 'PACKMASCH', 'Lizenz', Lizenz, True) > 0 then
    begin
      try
        Verpackt := StrToInt(qSuch.FieldByName('StueckPackSchicht').AsString);
      except
        Verpackt := 0;
      end;
      UpdateSQL(qUpdate, 'PACKMASCH', 'StueckPackSchicht', IntToStr(Verpackt + Menge), 'Lizenz', Lizenz);
      try
        Verpackt := StrToInt(qSuch.FieldByName('StueckPackGesamt').AsString);
      except
        Verpackt := 0;
      end;
      UpdateSQL(qUpdate, 'PACKMASCH', 'StueckPackGesamt', IntToStr(Verpackt + Menge), 'Lizenz', Lizenz);
    end
    else
    begin
      SQLStr := 'Insert into PACKMASCH (Nr,Lizenz,StueckPackGesamt,StueckPackSchicht) Values ('
        + 'PACKMASCHID.Nextval,'
        + '''' + Lizenz + ''','
        + '''' + IntToStr(Menge) + ''','
        + '''' + IntToStr(Menge) + ''')';
      SQL_Insert(qUpdate, SQLStr);
    end;
    if SQLGet(qSuch, 'PACKAUFTRAG', 'Betriebsauftragnr', BetriebsauftragNr, True) > 0 then
    begin
      try
        Verpackt := StrToInt(qSuch.FieldByName('StueckPackAuftragSchicht').AsString);
      except
        Verpackt := 0;
      end;
      UpdateSQL(qUpdate, 'PACKAUFTRAG', 'StueckPackAuftragSchicht', IntToStr(Verpackt + Menge), 'Betriebsauftragnr',
        BetriebsauftragNr);
      try
        Verpackt := StrToInt(qSuch.FieldByName('StueckPackAuftragGesamt').AsString);
      except
        Verpackt := 0;
      end;
      UpdateSQL(qUpdate, 'PACKAUFTRAG', 'StueckPackAuftragGesamt', IntToStr(Verpackt + Menge), 'Betriebsauftragnr',
        BetriebsauftragNr);
    end
    else
    begin
      SQLStr := 'Insert into PACKAUFTRAG (Nr,Betriebsauftragnr,StueckPackAuftragGesamt,StueckPackAuftragSchicht) Values ('
        + 'PACKAUFTRAGID.Nextval,'
        + '''' + BetriebsauftragNr + ''','
        + '''' + IntToStr(Menge) + ''','
        + '''' + IntToStr(Menge) + ''')';
      SQL_Insert(qUpdate, SQLStr);
    end;
  end;

  if Find then
  begin
    Differenz := Menge - Packgroesse;
    Zeit := Buchungszeitpunkt;
    try
      if ForcePackLogDate = '' then
        ForcePackLogDate := '''' + DateToStr(Zeit) + '''';
      SQLStr := 'Insert into PACKLOG (Nr,Maschine,Schicht,Betriebsauftragnr,Auftragnr,Verpackungseinheit,VerpackungseinheitINT,'
        + 'Verpackt,VerpacktINT,Differenz,DifferenzINT,GebuchtVon,Personalnummer,DatumZeit,DatumZeitStr,Datum,DatumStr,Zeit,ZeitStr)'
        + ' VALUES (PACKLOGID.NextVal'
        + ',''' + Maschine
        + ''',''0'
        + ''',''' + BetriebsauftragNr
        + ''',''' + AuftragNr
        + ''',''' + IntToStr(Packgroesse) + CO_AuftragGetL(' Artikel')
        + ''',''' + IntToStr(Packgroesse)
        + ''',''' + IntToStr(Menge) + CO_AuftragGetL(' Artikel')
        + ''',''' + IntToStr(Menge)
        + ''',''' + IntToStr(Differenz) + CO_AuftragGetL(' Artikel')
        + ''',''' + IntToStr(Differenz)
        + ''',''' + Name
        + ''','''
        + ''',' + FloatToPunktStringF(Zeit, ffFixed, 10, 10)
        + ',''' + DateTimeToStr(Zeit)
        + ''',' + ForcePackLogDate
        + ',''' + DateToStr(Zeit)
        + ''',''' + TimeToStr(Zeit)
        + ''',''' + TimeToStr(Zeit)
        + ''')';
      SQL_Insert(qUpdate, SQLStr);
    except ON e: Exception do
      sTxt := e.message;
    end;

    S := 'insert into VerpacktProt (Nr, BetriebsAuftragNr, AuftragNr, Bezeichnung,'
      + ' Barcode, ZUGANG, ABGANG, BCLeserNr, DATUM, Bemerkung, Maschine, Kunde, EINTRAGSDATUM, PersonalNr)'
      + ' values (VerpacktProtId.NextVal,'
      + '''' + BAuftragnr + ''','
      + '''' + AuftragNr + ''','
      + '''' + Bez + ''','
      + '''' + bar + ''','
      + '''' + IntToStr(Zg) + ''','
      + '''' + IntToStr(AG) + ''','
      + '''' + IntToStr(BCNr) + ''','
     + FloatToPunktString(Buchungszeitpunkt) + ','
      + '''' + sTxt + ''','
      + '''' + Maschine + ''','
      + '''' + Kunde + ''','
      + FloatToPunktString(Buchungszeitpunkt) + ',' //      + FloatToPunktString(EDatum) + ',' geändert, weil in Dienst nicht DATUM, sondern Eintragsdatum ausgwertet wird . Len 180909
      + '''' + PersonalNr + ''')';
    SQL_Insert(qUpdate, S);

    if SQLGet(qSuch, 'VerpacktLager', 'Auftragnr', AuftragNr, True) = 0 then
    begin
      S := 'insert into VerpacktLager (Nr, AuftragNr, Bezeichnung, Bestand)'
        + ' values (VerpacktLagerId.NextVal,'
        + '''' + AuftragNr + ''','
        + '''' + Bez + ''','
        + '''' + IntToStr(Menge) + ''')';
      SQL_Insert(qUpdate, S);
    end
    else
    begin
      try
        Verpackt := StrToInt(qSuch.FieldByName('Bestand').AsString);
      except
        Verpackt := 0;
      end;
      S := 'update VerpacktLager set Bestand = '
        + IntToStr(Verpackt + Menge)
        + ' where Auftragnr = ''' + AuftragNr + '''';
      SQL_Insert(qUpdate, S);
    end;
  end
  else
  begin

    sTxt := '';
    case ErrorMsg of
      Err_fehlerlos:
        sTxt := CO_AuftragGetL('Artikel erfolgreich verbucht...');
      Err_Auftrag_abgesclossen:
        sTxt := CO_AuftragGetL('Fehler: Auftrag abgeschlossen.');
      Err_Auftrag_nicht_angemeldet:
        sTxt := CO_AuftragGetL('Fehler: Auftrag nicht bekannt.');
    end;

    S := 'insert into VerpacktProt (Nr, BetriebsAuftragNr, AuftragNr, Bezeichnung,'
      + ' Barcode, ZUGANG, ABGANG, BCLeserNr, DATUM, Bemerkung, Maschine, Kunde, EINTRAGSDATUM)'
      + ' values (VerpacktProtId.NextVal,'
      + '''' + BAuftragnr + ''','
      + '''' + AuftragNr + ''','
      + '''' + CO_AuftragGetL('Unbekannter Auftrag') + ''','
      + '''' + bar + ''','
      + '''' + IntToStr(Zg) + ''','
      + '''' + IntToStr(AG) + ''','
      + '''' + IntToStr(BCNr) + ''','
      + FloatToPunktString(Buchungszeitpunkt) + ','
      + '''' + sTxt + ''','
      + '''' + Maschine + ''','
      + '''' + Kunde + ''','
      + FloatToPunktString(Buchungszeitpunkt) + ')';//      + FloatToPunktString(Now) + ')'; geändert, weil in Dienst nicht DATUM, sondern Eintragsdatum ausgwertet wird . Len 180909
    SQL_Insert(qUpdate, S);
  end;

  S := 'SELECT SUM(Zugang-Abgang) CNT'
     + ' FROM ' + Get_Daten_aus_Archiv('VERPACKTPROT', 0, true)
     + ' WHERE BetriebsAuftragNr = ''' + BAuftragnr + '''';
  SQL_Get(qSuch, S);
  try
    Verpackt := qSuch.FieldByName('CNT').AsInteger;
  except
    Verpackt := 0;
  end;

  if SQLGet(qSuch, 'AArchiv', 'Betriebsauftragnr', BAuftragnr, True) > 0 then
  begin
    try
      Produziert := StrToInt(qSuch.FieldByName('ProduziertINT').AsString);
    except
      Produziert := 0;
    end;

    if Produziert = 0 then
      Ausschuss := 0
    else
      Ausschuss := Round(100 / Produziert * (Produziert - Verpackt));
    if Ausschuss < 0 then
      Ausschuss := 0;

    if ErrorMsg <> Err_Auftrag_abgesclossen then
    begin
      UpdateSQL(qUpdate, 'AArchiv', 'Verpacktint', IntToStr(Verpackt), 'Betriebsauftragnr', BAuftragnr);
      UpdateSQL(qUpdate, 'AArchiv', 'AusschussPRZ', IntToStr(Ausschuss), 'Betriebsauftragnr', BAuftragnr);
    end;
  end;

  if SQLGet(qSuch, 'Maschinf', 'BetriebsAuftragNr', BAuftragnr, True) > 0 then
    UpdateSQL(qUpdate, 'Maschinf', 'Pack', IntToStr(Verpackt), 'BetriebsAuftragNr', BAuftragnr);

  if SQLGet(qSuch, 'PDE', 'Betriebsauftragnr', BAuftragnr, True) > 0 then
    UpdateSQL(qUpdate, 'PDE', 'Pack', IntToStr(Verpackt), 'Betriebsauftragnr', BAuftragnr);
             
  Result := 0;
end;

function TCO_Auftrag.Abschliessen(BetriebsauftragNr: string): Integer;
var
  BANr, S: string;
  ST: TStringList;
  D: Real;
  I: Integer;
begin
  Result := 0;
  D := Now;
  BANr := BetriebsauftragNr;

  ST := TStringList.Create;
  ST.Add(BANr);

  if SQLGet(qSuch, 'PDEKombi', 'BetriebsAuftragNr', BANr, True) > 0 then
  begin
    BANr := qSuch.FieldByName('MasterBetriebsAuftragNr').AsString;
    ST.Add(BANr);
  end;

  if SQLGet(qSuch, 'PDEKombi', 'MasterBetriebsAuftragNr', BANr, True) > 0 then
    while not qSuch.EOF do
    begin
      ST.Add(qSuch.FieldByName('BetriebsAuftragNr').AsString);
      qSuch.Next;
    end;

  ST.Sort;

  for I := 0 to ST.Count - 1 do
  begin
    S := 'update AArchiv set EndeStatus = ''' + CO_AuftragGetL('abgeschlossen') + ''','
      + ' EndeStatusDatum = ' + FloatToPunktString(D) + ' where Betriebsauftragnr = ''' + ST[I] + '''';
    SQL_Insert(qUpdate, S);

    if not fSupressEvents then
    begin
      S := 'select Count(*) CNT from ERPEvents where BetriebsAuftragNr = ''' + ST[I] + ''' and Event = ''A''';
      SQL_Get(qUpdate, S);
      if qUpdate.FieldByName('CNT').AsInteger = 0 then
      begin
        S := 'insert into ERPEvents (Nr, BetriebsAuftragNr, Event, Datumzeit)'
          + ' values (ERPEventsId.NextVal,'
          + '''' + ST[I] + ''','
          + '''A'','
          + FloatToPunktString(D) + ')';
        SQL_Insert(qUpdate, S);
      end;
    end;
  end;
  ST.Free;
end;

function TCO_Auftrag.Verpacken13(BAuftragnr: string; Menge: Integer;
  bar: string; D: TDateTime; PersonalNr, BCId, Art: string; EinheitNr: Integer): Integer;
const
  Err_fehlerlos = 0;
  Err_Auftrag_abgesclossen = 1;
  Err_Auftrag_nicht_angemeldet = 2;
var
  BetriebsauftragNr, Lizenz: string;
  S, SQLStr, SQLCountSTR: string;
  Status: Integer;
  Produziert, Verpackt: Integer;
  Packgroesse, Ausschuss: Integer;
  sTxt, Maschine, Bez, AuftragNr, Kunde: string;
  Differenz: Integer;
  Zeit: TDateTime;
  Zg, AG, BCNr: Integer;
  Find: Boolean;
  ErrorMsg: Integer;
  EDatum: Real;
begin
  EDatum := Now;
  Find := False;
  Packgroesse := 0;
  ErrorMsg := Err_fehlerlos;

  sTxt := CO_AuftragGetL('Artikel erfolgreich gebucht...');

  Zg := 0;
  AG := 0;
  if Menge > 0 then
    Zg := Menge
  else
    AG := -Menge;

  if SQLGet(qSuch, 'BCLeser', 'Serial', BCId, True) = 0 then
  begin
    S := 'insert into BCLeser (Nr, Serial) values (BCLeserId.NextVal,'
      + '''' + BCId + ''')';
    SQL_Insert(qUpdate, S);
    SQLGet(qSuch, 'BCLeser', 'Serial', BCId, False);
  end;
  BCNr := qSuch.FieldByName('Nr').AsInteger;

  AuftragNr := '';

  if SQLGet(qSuch, 'AArchiv', 'Betriebsauftragnr', BAuftragnr, True) > 0 then
  begin
    if qSuch.FieldByName('ENDESTATUS').AsString = CO_AuftragGetL('abgeschlossen') then
    begin
      ErrorMsg := Err_Auftrag_abgesclossen;
    end
    else
    begin
      Find := True;
      qSuch.Last;

      BetriebsauftragNr := qSuch.FieldByName('Betriebsauftragnr').AsString;
      Maschine := qSuch.FieldByName('Maschine').AsString;
      AuftragNr := qSuch.FieldByName('Auftragnr').AsString;
      Bez := qSuch.FieldByName('Bezeichnung').AsString;
      Kunde := qSuch.FieldByName('Kunde').AsString;
      try
        EDatum := qSuch.FieldByName('EndDatumZeit').AsFloat;
      except
        EDatum := 0;
      end;
      if EDatum = 0 then
        EDatum := Now;

      if qSuch.FieldByName('EndeStatus').AsString <> '' then
      try
        Packgroesse := StrToInt(qSuch.FieldByName('Packgroesse').AsString);
      except
        Packgroesse := 0;
      end;
    end;
  end
  else
  begin
    Result := Err_Auftrag_nicht_angemeldet;
    Exit;
  end;

  if SQLGet(qSuch, 'PDE', 'Betriebsauftragnr', BAuftragnr, True) > 0 then
  begin
    EDatum := Now;
    Find := True;
    Lizenz := qSuch.FieldByName('Lizenz').AsString;
    Maschine := Lizenz;
    AuftragNr := qSuch.FieldByName('Auftragnr').AsString;
    Bez := qSuch.FieldByName('Bezeichnung').AsString;
    Packgroesse := Format_String(qSuch.FieldByName('Packgroesse').AsString);
    Kunde := qSuch.FieldByName('Kunde').AsString;

    try
      Status := StrToInt(qSuch.FieldByName('Stat').AsString);
    except
      Status := 0;
    end;
    BetriebsauftragNr := BAuftragnr;
    if not (Status in [0, 1, 4]) then
    begin
      SQLCountSTR := 'Select count(*) as CNT from PDE where Lizenz = ''' + Lizenz + ''' AND (stat = 0 or stat = 1)';
      SQL_Get(qCount, SQLCountSTR);
      if qCount.FieldByName('CNT').AsInteger > 0 then
      begin
        SQLStr := 'Insert Into AUFTRAGENDE (Nr, Lizenz) Values ('
          + 'AUFTRAGENDEID.Nextval,'
          + '''' + Lizenz + ''')';
        SQLCountSTR := 'Select Count(*) as CNT from AUFTRAGENDE where Lizenz=''' + Lizenz + '''';
        SQL_Get(qCount, SQLCountSTR);
        if qCount.FieldByName('CNT').AsInteger = 0 then
          SQL_Insert(qUpdate, SQLStr);
      end;
      SQLStr := 'Insert Into AUFTRAGSTART (Nr, Betriebsauftragnr) Values (AUFTRAGSTARTID.Nextval,'
        + '''' + BetriebsauftragNr + ''')';
      SQLCountSTR := 'Select Count(*) as CNT from AUFTRAGSTART where Betriebsauftragnr='''
        + BetriebsauftragNr + '''';
      SQL_Get(qCount, SQLCountSTR);
      if qCount.FieldByName('CNT').AsInteger = 0 then
        SQL_Insert(qUpdate, SQLStr);
    end;

    if SQLGet(qSuch, 'PACKMASCH', 'Lizenz', Lizenz, True) > 0 then
    begin
      try
        Verpackt := StrToInt(qSuch.FieldByName('StueckPackSchicht').AsString);
      except
        Verpackt := 0;
      end;
      UpdateSQL(qUpdate, 'PACKMASCH', 'StueckPackSchicht', IntToStr(Verpackt + Menge), 'Lizenz', Lizenz);
      try
        Verpackt := StrToInt(qSuch.FieldByName('StueckPackGesamt').AsString);
      except
        Verpackt := 0;
      end;
      UpdateSQL(qUpdate, 'PACKMASCH', 'StueckPackGesamt', IntToStr(Verpackt + Menge), 'Lizenz', Lizenz);
    end
    else
    begin
      SQLStr := 'Insert into PACKMASCH (Nr,Lizenz,StueckPackGesamt,StueckPackSchicht) Values ('
        + 'PACKMASCHID.Nextval,'
        + '''' + Lizenz + ''','
        + '''' + IntToStr(Menge) + ''','
        + '''' + IntToStr(Menge) + ''')';
      SQL_Insert(qUpdate, SQLStr);
    end;
    if SQLGet(qSuch, 'PACKAUFTRAG', 'Betriebsauftragnr', BetriebsauftragNr, True) > 0 then
    begin
      try
        Verpackt := StrToInt(qSuch.FieldByName('StueckPackAuftragSchicht').AsString);
      except
        Verpackt := 0;
      end;
      UpdateSQL(qUpdate, 'PACKAUFTRAG', 'StueckPackAuftragSchicht', IntToStr(Verpackt + Menge), 'Betriebsauftragnr',
        BetriebsauftragNr);
      try
        Verpackt := StrToInt(qSuch.FieldByName('StueckPackAuftragGesamt').AsString);
      except
        Verpackt := 0;
      end;
      UpdateSQL(qUpdate, 'PACKAUFTRAG', 'StueckPackAuftragGesamt', IntToStr(Verpackt + Menge), 'Betriebsauftragnr',
        BetriebsauftragNr);
    end
    else
    begin
      SQLStr := 'Insert into PACKAUFTRAG (Nr,Betriebsauftragnr,StueckPackAuftragGesamt,StueckPackAuftragSchicht) Values ('
        + 'PACKAUFTRAGID.Nextval,'
        + '''' + BetriebsauftragNr + ''','
        + '''' + IntToStr(Menge) + ''','
        + '''' + IntToStr(Menge) + ''')';
      SQL_Insert(qUpdate, SQLStr);
    end;
  end;

  if Find then
  begin
    Differenz := Menge - Packgroesse;
    Zeit := Now;
    SQLStr := 'Insert into PACKLOG (Nr,Maschine,Schicht,Betriebsauftragnr,Auftragnr,Verpackungseinheit,VerpackungseinheitINT,'
      + 'Verpackt,VerpacktINT,Differenz,DifferenzINT,GebuchtVon,Personalnummer,DatumZeit,DatumZeitStr,Datum,DatumStr,Zeit,ZeitStr)'
      + ' VALUES (PACKLOGID.NextVal'
      + ',''' + Maschine
      + ''',''0'
      + ''',''' + BetriebsauftragNr
      + ''',''' + AuftragNr
      + ''',''' + IntToStr(Packgroesse) + CO_AuftragGetL(' Artikel')
      + ''',''' + IntToStr(Packgroesse)
      + ''',''' + IntToStr(Menge) + CO_AuftragGetL(' Artikel')
      + ''',''' + IntToStr(Menge)
      + ''',''' + IntToStr(Differenz) + CO_AuftragGetL(' Artikel')
      + ''',''' + IntToStr(Differenz)
      + ''',''' + Name
      + ''','''
      + ''',' + FloatToPunktStringF(Zeit, ffFixed, 10, 10)
      + ',''' + DateTimeToStr(Zeit)
      + ''',''' + DateToStr(Zeit)
      + ''',''' + DateToStr(Zeit)
      + ''',''' + TimeToStr(Zeit)
      + ''',''' + TimeToStr(Zeit)
      + ''')';
    SQL_Insert(qUpdate, SQLStr);

    S := 'insert into VerpacktProt (Nr, BetriebsAuftragNr, AuftragNr, Bezeichnung,'
      + ' Barcode, ZUGANG, ABGANG, BCLeserNr, DATUM, Bemerkung, Maschine, Kunde,'
      + ' EINTRAGSDATUM, Art, EinheitNr, PersonalNr)'
      + ' values (VerpacktProtId.NextVal,'
      + '''' + BAuftragnr + ''','
      + '''' + AuftragNr + ''','
      + '''' + Bez + ''','
      + '''' + bar + ''','
      + '''' + IntToStr(Zg) + ''','
      + '''' + IntToStr(AG) + ''','
      + '''' + IntToStr(BCNr) + ''','
      + FloatToPunktString(D) + ','
      + '''' + sTxt + ''','
      + '''' + Maschine + ''','
      + '''' + Kunde + ''','
      + FloatToPunktString(EDatum) + ','
      + '''' + Art + ''','
      + '''' + IntToStr(EinheitNr) + ''','
      + '''' + PersonalNr + ''')';
    SQL_Insert(qUpdate, S);

    if SQLGet(qSuch, 'VerpacktLager', 'Auftragnr', AuftragNr, True) = 0 then
    begin
      S := 'insert into VerpacktLager (Nr, AuftragNr, Bezeichnung, Bestand)'
        + ' values (VerpacktLagerId.NextVal,'
        + '''' + AuftragNr + ''','
        + '''' + Bez + ''','
        + '''' + IntToStr(Menge) + ''')';
      SQL_Insert(qUpdate, S);
    end
    else
    begin
      try
        Verpackt := StrToInt(qSuch.FieldByName('Bestand').AsString);
      except
        Verpackt := 0;
      end;
      S := 'update VerpacktLager set Bestand = '
        + IntToStr(Verpackt + Menge)
        + ' where Auftragnr = ''' + AuftragNr + '''';
      SQL_Insert(qUpdate, S);
    end;
  end
  else
  begin

    sTxt := '';
    case ErrorMsg of
      Err_fehlerlos:
        sTxt := CO_AuftragGetL('Artikel erfolgreich verbucht...');
      Err_Auftrag_abgesclossen:
        sTxt := CO_AuftragGetL('Fehler: Auftrag abgeschlossen.');
      Err_Auftrag_nicht_angemeldet:
        sTxt := CO_AuftragGetL('Fehler: Auftrag nicht bekannt.');
    end;

    S := 'insert into VerpacktProt (Nr, BetriebsAuftragNr, AuftragNr, Bezeichnung,'
      + ' Barcode, ZUGANG, ABGANG, BCLeserNr, DATUM, Bemerkung, Maschine, Kunde, EINTRAGSDATUM)'
      + ' values (VerpacktProtId.NextVal,'
      + '''' + BAuftragnr + ''','
      + '''' + AuftragNr + ''','
      + '''' + CO_AuftragGetL('Unbekannter Auftrag') + ''','
      + '''' + bar + ''','
      + '''' + IntToStr(Zg) + ''','
      + '''' + IntToStr(AG) + ''','
      + '''' + IntToStr(BCNr) + ''','
      + FloatToPunktString(D) + ','
      + '''' + Maschine + ''','
      + '''' + Kunde + ''','
      + '''' + sTxt + ''','
      + FloatToPunktString(Now) + ')';
    SQL_Insert(qUpdate, S);
  end;

  S := 'SELECT SUM(Zugang-Abgang) CNT'
     + ' FROM ' + Get_Daten_aus_Archiv('VERPACKTPROT', 0, true)
     + ' WHERE BetriebsAuftragNr = ''' + BAuftragnr + '''';
  SQL_Get(qSuch, S);
  try
    Verpackt := qSuch.FieldByName('CNT').AsInteger;
  except
    Verpackt := 0;
  end;

  if SQLGet(qSuch, 'AArchiv', 'Betriebsauftragnr', BAuftragnr, True) > 0 then
  begin
    try
      Produziert := StrToInt(qSuch.FieldByName('ProduziertINT').AsString);
    except
      Produziert := 0;
    end;

    if Produziert = 0 then
      Ausschuss := 0
    else
      Ausschuss := Round(100 / Produziert * (Produziert - Verpackt));
    if Ausschuss < 0 then
      Ausschuss := 0;

    if ErrorMsg <> Err_Auftrag_abgesclossen then
    begin
      UpdateSQL(qUpdate, 'AArchiv', 'Verpacktint', IntToStr(Verpackt), 'Betriebsauftragnr', BAuftragnr);
      UpdateSQL(qUpdate, 'AArchiv', 'AusschussPRZ', IntToStr(Ausschuss), 'Betriebsauftragnr', BAuftragnr);
    end;
  end;

  if SQLGet(qSuch, 'Maschinf', 'BetriebsAuftragNr', BAuftragnr, True) > 0 then
    UpdateSQL(qUpdate, 'Maschinf', 'Pack', IntToStr(Verpackt), 'BetriebsAuftragNr', BAuftragnr);

  if SQLGet(qSuch, 'PDE', 'Betriebsauftragnr', BAuftragnr, True) > 0 then
    UpdateSQL(qUpdate, 'PDE', 'Pack', IntToStr(Verpackt), 'Betriebsauftragnr', BAuftragnr);

  Result := 0;
end;

function TCO_Auftrag.Ausschuss(BAuftragnr: string; Menge: Integer; D: TDateTime; GrundNr, PersonalNr:string): Integer;
var
  Shifts : TShiftList;
  TimeStamp: double;
begin
  TimeStamp := D;
  Shifts := Shifts.Create;
  Result := Shifts.BookHistoricScrap(qUpdate, BAuftragnr, Menge, GrundNr, PersonalNr, FMOdul, true, TimeStamp);
  Shifts.Free;
end;

procedure TCO_Auftrag.InPause(BetriebsauftragNr: string; Pause: Boolean);
var
  MaschNr, Liz, S, PDENr: string;
  Schuss, Schuss2, Kav, Opt: Integer;
begin
  if SQLGet(qSuch, 'PDE', 'BetriebsAuftragNr', BetriebsauftragNr, True) = 0 then
    Exit;
  Liz := qSuch.FieldByName('Lizenz').AsString;
  PDENr := qSuch.FieldByName('Nr').AsString;
  Kav := qSuch.FieldByName('kopfgroesse').AsInteger;

  if not (qSuch.FieldByName('Stat').AsInteger in [0, 1]) then
    Exit;
  if SQLGet(qSuch2, 'Maschine', 'Lizenz', Liz, True) = 0 then
    Exit;
  MaschNr := qSuch2.FieldByName('MaschNr').AsString;

  if Pause = (qSuch.FieldByName('InPause').AsInteger = 1) then
    Exit;

  if Pause then
  begin
    StartOptimieren(Liz, BetriebsauftragNr);
    if SQL2Get(qSuch2, 'Signal_Maschine', 'MaschNr', MaschNr, 'SignalNr', '2', True) = 0 then
      Schuss := 0
    else
      Schuss := qSuch2.FieldByName('IstWert').AsInteger;
    S := 'update PDE set'
      + ' TMPSchuss = ' + IntToStr(Schuss) + ','
      + ' InPause = 1'
      + ' where Nr = ' + PDENr;
    SQL_Insert(qUpdate, S);
  end
  else
  begin
    if SQL2Get(qUpdate, 'Signal_Maschine', 'MaschNr', MaschNr, 'SignalNr', '2', True) = 0 then
      Schuss2 := 0
    else
      Schuss2 := qUpdate.FieldByName('IstWert').AsInteger;

    Schuss := qSuch.FieldByName('TMPSchuss').AsInteger;
    EndOptimieren(Liz, BetriebsauftragNr, (schuss2 - Schuss) * Kav);
    if not TCO_Setup.GetParamBool(qUpdate, 'Stueckzahl_laufender_Auftrag_nicht_abnullen') then
    begin
      S := 'update SPSWerte set MASCHORG = 1,'
        + ' STUECKAUFTRAGGESAMT = ''' + IntToStr(Schuss) + ''','
        + ' STUECKAUFTRAGSCHICHT = ''' + IntToStr(Schuss) + ''','
        + ' STUECKSCHICHT = ''' + IntToStr(Schuss) + ''''
        + ' where LIZENZINT = ''' + MaschNr + '''';
      SQL_Insert(qUpdate, S);

      S := 'INSERT INTO SIGNAL_SCHREIBEN (Nr, MaschNr, SignalNr, Wert)'
        + 'VALUES(SIGNAL_SCHREIBENID.NextVal'
        + ', ''' + MaschNr
        + ''', ''2'
        + ''', ''' + IntToStr(Schuss)
        + ''')';
      SQL_Insert(qUpdate, S);

      S := 'INSERT INTO Log_SIGNAL_SCHREIBEN (Nr, DatumZeit, Datumexakt, BetriebsAuftragNr, Lizenz, MaschNr, '
        + 'MODUL,VERSION,KAV,VAR_KAV,SignalNr, Wert)'
        + ' VALUES (Log_SIGNAL_SCHREIBENID.NextVal,'
        + ' ''' + DateTimeToStr(Now) + ''','
        + FloatToPunktString(Now) + ','
        + ' ''' + BetriebsauftragNr + ''','
        + ' ''' + Liz + ''','
        + ' ''' + MaschNr + ''','
        + ' ''' + FModul + ''','
        + ' ''' + FVersion + ''','
        + ' ''' + IntToStr(-1) + ''','
        + ' ''' + IntToStr(-1) + ''','
        + ' ''2'','
        + ' ''' + IntToStr(Schuss) + ''')';
      SQL_Insert(qUpdate, S);
    end;
    S := 'update PDE set TMPSchuss = 0, InPause = 0 where Nr = ' + PDENr;
    SQL_Insert(qUpdate, S);
  end;

  if Pause then
    Opt := 1
  else
    Opt := 0;
  S := 'update Maschinf set InPause = ' + IntToStr(Opt) + ' where Lizenz = ''' + Liz + '''';
  SQL_Insert(qUpdate, S);
end;

procedure TCO_Auftrag.Maschinf_Kein_Auftrag(Lizenz: string);
var
  S: string;
begin
  try
    s := ' UPDATE maschinf SET '
                + ' Taktzeit = 0, '
                + ' StueckSchicht = 0, '
                + ' PackSchicht = 0, '
                + ' PruefSchicht = 0, '
                + ' Sollwert = 1, '
                + ' Istwert_Prz = ''0 %'', '
                + ' Stueck = 0, '
                + ' Pack = 0, '
                + ' Pruef = 0, '
                + ' StartDatum = '''', '
                + ' EndeDatum = '''', '
                + ' LTSOLL = '''', '
                + ' LTIST = '''', '
                + ' ArtikelNr = '''', '
                + ' BetriebsauftragNr = '''', '
                + ' Bezeichnung = '''', '
                + ' AnzJob = 0, '
                + ' TaktZeit_Str = '''', '
                + ' Reststandzeit = 0, '
                + ' Werkzeug_Nr = '''', '
                + ' Werkzeug = '''', '
                + ' Ausschuss = 0, '
                + ' InPause = 0, '
                + ' Form = '''' '
                + ' WHERE lizenz = ''' + Lizenz + '''';
    SQL_Insert(qUpdate,s);

  except
  end;
end;

function TCO_Auftrag.Ruesten(Lizenz: string; BetriebsauftragNr: string; RuestgrundNr: Integer; StartDatumZeit: TDateTime = 0): Integer;
var
  ruestet: Boolean;
  MaschNr : String;
  SQLStr : string;
  Nummer, Dauer, schicht : Integer;
begin

  MaschNr := '0';
  qSuch.SQL.Text := 'SELECT maschnr FROM maschine WHERE lizenz = ''' + Lizenz + '''';
  qSuch.Open;
  if not qSuch.IsEmpty then
    Maschnr :=  qSuch.FieldByName('maschnr').AsString;

  qSuch.SQL.Text := 'SELECT * FROM PDE WHERE betriebsauftragnr = '''
    + BetriebsauftragNr + ''' AND lizenz = ''' + Lizenz + ''' AND stat = 1';
  qSuch.Open;
  ruestet := not qSuch.IsEmpty; // Wenn Eintrag vorhanden, wird aktueller Auftrag gerüstet

  if ruestet then  // Ruestprot Eintrag und Eintrag Stillstandprotokoll splitten
  begin
    SQLStr := 'select schicht from tpm_schicht where nr = (select max(nr) from tpm_schicht)';
    SQL_Get(qSuch, SQLStr);
      Schicht := qSuch.FieldByName('Schicht').AsInteger;

    SQLStr := 'select nr, kommt from tpm_Stillog where ((Geht is NULL) OR (Geht = 0))'
      + ' AND (maschnr = ''' + MaschNr + ''')';
    SQL_Get(qSuch, SQLStr);
    if not qSuch.IsEmpty then
    begin
      Nummer := qSuch.FieldByName('Nr').AsInteger;
      Dauer := Trunc((now - qSuch.FieldByName('Kommt').AsFloat) * 1440);
      if Dauer = 0 then
        Dauer := 1;
      // Doppelt ausgeführt, damit Statement auf jeden Fall vor dem Update ausgeführt wird, damit
      // der Dienst nicht dazwischenfunkt
      SQLStr := 'INSERT INTO TPM_Stillog (Nr,MaschNr,Schicht,Erstellungsdatum, Kommt,Stillstandnr,KommtStr)'
        + ' VALUES(TPM_StillogID.Nextval'
        + ',''' + MaschNr
        + ''',''' + IntToStr(Schicht)
        + ''',' + FloatToPunktString(now)
        + ',' + FloatToPunktString(now)
        + ','+IntToStr(RuestgrundNr)
        + ',''' + DateTimeToStr(now)
        + ''')';
      SQL_Insert(qUpdate,sqlstr);

      SQLStr := 'UPDATE tpm_stillog SET geht = ' + FloatToPunktString(now)
        + ', GehtStr = ''' + DateTimeToStr(now) + ''', Dauer = ' +  IntToStr(Dauer)
        + ' WHERE nr = ' + IntToStr(Nummer);
      SQL_Insert(qUpdate,sqlstr);
    end
    else
    begin
      SQLStr := 'INSERT INTO TPM_Stillog (Nr,MaschNr,Schicht,Kommt,Stillstandnr,KommtStr)'
        + ' VALUES(TPM_StillogID.Nextval'
        + ',''' + MaschNr
        + ''',''' + IntToStr(Schicht)
        + ''',' + FloatToPunktString(now)
        + ','+ IntToStr(RuestgrundNr)
        + ',''' + DateTimeToStr(now)
        + ''')';
      SQL_Insert(qUpdate,sqlstr);
    end;

    result := 0;
  end
  else
  begin
    Result := Starten(Lizenz, BetriebsauftragNr, True, StartDatumZeit);
    SQLStr := 'UPDATE tpm_stillog SET stillstandnr = ' + IntToStr(RuestgrundNr)
      + ' WHERE nr = (SELECT nr from tpm_Stillog where ((Geht is NULL) OR (Geht = 0))'
      + ' AND (maschnr = ''' + MaschNr + '''))';
    SQL_Insert(qUpdate,sqlstr);
  end;
  Exit;

  // Wenn Auftrag rüstet, dann LaufendRüsten aufrufen
  if ruestet then
  begin
    if not TCO_Setup.GetParamBool(qSuch, 'Stueckzahl_laufender_Auftrag_nicht_abnullen') then
      SchliesseRuesteintrag(BetriebsauftragNr, Lizenz);
    Result := LaufendRuesten(Lizenz, BetriebsauftragNr);
  end
  else
    Result := Starten(Lizenz, BetriebsauftragNr, True, StartDatumZeit);

  if not TCO_Setup.GetParamBool(qSuch, 'Stueckzahl_laufender_Auftrag_nicht_abnullen') then
    AuftragBuchen(BetriebsauftragNr, 0);

  qUpdate.SQL.Text := 'UPDATE ruestprot SET grund = ' + IntToStr(RuestgrundNr)
    + ' WHERE lizenz = ''' + Lizenz + ''' AND betriebsauftragnr = '''
    + BetriebsauftragNr + ''' AND ruestende = 0';
  qUpdate.ExecSQL;

  qSuch.SQL.Text := 'SELECT maschnr FROM maschine WHERE lizenz = ''' + Lizenz + '''';
  qSuch.Open;
  if not qSuch.IsEmpty then
  begin
    qUpdate.SQL.Text := 'UPDATE tpm_stillog SET stillstandnr = ' + IntToStr(RuestgrundNr)
      + ' WHERE maschnr = ' + qSuch.FieldByName('maschnr').AsString + ' geht = 0';
    qUpdate.ExecSQL;
  end;


end;

function TCO_Auftrag.LaufendRuesten(Lizenz: string; BetriebsauftragNr: string): Integer;
var
  StatStr, S: string;
  Schuss: Integer;
begin
  Result := UnterbrechenAuftrag(BetriebsauftragNr);
  if Result = 0 then
    Result := Starten(Lizenz, BetriebsauftragNr, True);
  Exit;

  Result := 0;
  if fOraSession = nil then
  begin
    Result := DatenbankName_nicht_definiert;
    Exit;
  end;

  if SQL2Get(qSuch, 'PDE', 'Lizenz', Lizenz, 'stat', '0', True) > 0 then
  begin
    if qSuch.FieldByName('Betriebsauftragnr').AsString = BetriebsauftragNr then
    begin
      Schuss := qSuch.FieldByName('Istwert').AsInteger;
      if not TCO_Setup.GetParamBool(qSuch, 'Stueckzahl_laufender_Auftrag_nicht_abnullen') then
        AuftragBuchen(BetriebsauftragNr, Schuss);

      S := 'UPDATE pde SET stat = 1, Status = ''' + CO_AuftragGetL('Rüsten') + ''''
        + ' WHERE betriebsauftragnr = ''' + BetriebsauftragNr + '''';
      SQL_Insert(qUpdate, S);

      S := 'UPDATE maschinf SET stat = 1, Zustand = ''' + CO_AuftragGetL(StatStr) + ''''
        + ' WHERE lizenz = ''' + Lizenz + '''';
      SQL_Insert(qUpdate, S);

      Exit;
    end
    else
    begin
      Result := Auftrag_nicht_gefunden;
      Exit;
    end;
  end;

  if SQL2Get(qSuch, 'PDE', 'Lizenz', Lizenz, 'stat', '1', True) > 0 then
    if qSuch.FieldByName('Betriebsauftragnr').AsString <> BetriebsauftragNr then
      Result := Anderer_Auftrag_wird_geruestet;
end;

function TCO_Auftrag.Check_Lizenz_In_Pause(Lizenz: string): Boolean;
begin
  qSuch.SQL.Text := 'select Count(*) CNT from Maschinf where Lizenz = ''' + Lizenz + ''' and InPause = 1';
  qSuch.Open;
  Result := qSuch.FieldByName('CNT').AsInteger > 0;
  qSuch.Close;
end;

procedure TCO_Auftrag.AuftragBuchen(BetriebsauftragNr: string; Stueck: Integer);
var
  MaschNr, Lizenz, S: string;
  Schuss, Kav, Var_Kav, SignalNr, SignalNr2: Integer;
  Packen, Verpackt_Barcode, Pruefen: Boolean;
begin
  if SQLGet(qSuch, 'PDE', 'BetriebsAuftragNr', BetriebsauftragNr, True) > 0 then
  begin
    Kav := qSuch.FieldByName('KopfGroesse').AsInteger;
    Var_Kav := qSuch.FieldByName('Var_Kavitaet').AsInteger;
    if Var_Kav < 1 then
      Var_Kav := 1;
    if Kav < 1 then
      Kav := 1;
    Lizenz := qSuch.FieldByName('Lizenz').AsString;

    if SQLGet(qSuch, 'Maschine', 'Lizenz', Lizenz, True) > 0 then
      MaschNr := qSuch.FieldByName('MaschNr').AsString
    else
      MaschNr := '0';

    if MaschNr <> '0' then
    begin
      Schuss := Stueck div Kav * Var_Kav;

      if (Schuss = 0) and TCO_Setup.GetParamBool(qSuch, 'MDE_Everytime_Signal2') then
        Schuss := 1;

      if Schuss = 0 then
        SignalNr := CAUFTRAGRESETSTUECK
      else
        SignalNr := CSTUECKAUFTRAGGESAMT;
      if SQLGet(qSuch, 'SIGNALE', 'SignalArt', IntToStr(SignalNr), True) > 0 then
        SignalNr := qSuch.FieldByName('SignalNr').AsInteger
      else
        SignalNr := -1;

      SignalNr2 := CSTUECKAUFTRAGGESAMT;
      if SQLGet(qSuch, 'SIGNALE', 'SignalArt', IntToStr(SignalNr2), True) > 0 then
        SignalNr2 := qSuch.FieldByName('SignalNr').AsInteger
      else
        SignalNr2 := -1;

      if Schuss = 0 then
      begin
        S := 'INSERT INTO SIGNAL_SCHREIBEN (Nr, MaschNr, SignalNr, Wert)'
          + ' VALUES (SIGNAL_SCHREIBENID.NextVal'
          + ',''' + MaschNr
          + ''',''' + IntToStr(SignalNr)
          + ''',''1'
          + ''')';
        SQL_Insert(qUpdate, S);

        S := 'INSERT INTO Log_SIGNAL_SCHREIBEN (Nr, DatumZeit, Datumexakt, BetriebsAuftragNr, Lizenz, MaschNr, '
          + 'MODUL,VERSION,KAV,VAR_KAV,SignalNr, Wert)'
          + ' VALUES (Log_SIGNAL_SCHREIBENID.NextVal,'
          + ' ''' + DateTimeToStr(Now) + ''','
          + FloatToPunktString(Now) + ','
          + ' ''' + BetriebsauftragNr + ''','
          + ' ''' + Lizenz + ''','
          + ' ''' + MaschNr + ''','
          + ' ''' + FModul + ''','
          + ' ''' + FVersion + ''','
          + ' ''' + IntToStr(Kav) + ''','
          + ' ''' + IntToStr(VAR_KAV) + ''','
          + ' ''' + IntToStr(SignalNr) + ''','
          + ' ''1'')';
        SQL_Insert(qUpdate, S);
      end
      else
      begin
        if SQLGet(qSuch2, 'SPSWerte', 'LIZENZINT', MaschNr, True) > 0 then
          S := 'update spswerte set'
            + ' MASCHORG = 1,'
            + ' STUECKAUFTRAGGESAMT = ''' + IntToStr(Schuss) + ''','
            + ' STUECKAUFTRAGSCHICHT = ''' + IntToStr(Schuss) + ''','
            + ' STUECKSCHICHT = ''' + IntToStr(Schuss) + ''''
            + ' where LIZENZINT = ''' + MaschNr + ''''
        else
          S := 'insert into SPSWerte (Nr, MASCHORG, STUECKAUFTRAGGESAMT, STUECKAUFTRAGSCHICHT,'
            + ' STUECKSCHICHT, LizenzInt) values (SPSWerteId.NextVal,'
            + ' ''1'','
            + ' ''' + IntToStr(Schuss) + ''','
            + ' ''' + IntToStr(Schuss) + ''','
            + ' ''' + IntToStr(Schuss) + ''','
            + ' ''' + MaschNr + ''')';
        SQL_Insert(qUpdate, S);

        S := 'INSERT INTO SIGNAL_SCHREIBEN (Nr,MaschNr,SignalNr,Wert)'
          + ' VALUES (SIGNAL_SCHREIBENID.NextVal'
          + ',''' + MaschNr
          + ''',''' + IntToStr(SignalNr)
          + ''',''' + IntToStr(Schuss)
          + ''')';
        SQL_Insert(qUpdate, S);

        S := 'INSERT INTO Log_SIGNAL_SCHREIBEN (Nr, DatumZeit, Datumexakt, BetriebsAuftragNr, Lizenz, MaschNr, '
          + 'MODUL,VERSION,KAV,VAR_KAV,SignalNr, Wert)'
          + ' VALUES (Log_SIGNAL_SCHREIBENID.NextVal,'
          + ' ''' + DateTimeToStr(Now) + ''','
          + FloatToPunktString(Now) + ','
          + ' ''' + BetriebsauftragNr + ''','
          + ' ''' + Lizenz + ''','
          + ' ''' + MaschNr + ''','
          + ' ''' + FModul + ''','
          + ' ''' + FVersion + ''','
          + ' ''' + IntToStr(Kav) + ''','
          + ' ''' + IntToStr(VAR_KAV) + ''','
          + ' ''' + IntToStr(SignalNr) + ''','
          + ' ''' + IntToStr(Schuss) + ''')';
        SQL_Insert(qUpdate, S);
      end;

      S := 'update Signal_Maschine set Istwert = ' + IntToStr(Schuss)
        + ' where SignalNr = ' + IntToStr(SignalNr2) + ' and MaschNr = ' + MaschNr;
      SQL_Insert(qUpdate, S);

      Pruefen := fPruefen;
      Packen := fPacken;
      Verpackt_Barcode := fVerpackt_Barcode;

      if Pruefen then
      begin
        SignalNr := CAUFTRAGRESETPRUEF;
        if SQLGet(qSuch, 'SIGNALE', 'SignalArt', IntToStr(SignalNr), True) > 0 then
          SignalNr := qSuch.FieldByName('SignalNr').AsInteger
        else
          SignalNr := -1;
        S := 'INSERT INTO SIGNAL_SCHREIBEN (Nr,MaschNr,SignalNr,Wert)'
          + 'VALUES(SIGNAL_SCHREIBENID.NextVal'
          + ',''' + MaschNr
          + ''',''' + IntToStr(SignalNr)
          + ''',''1'
          + ''')';
        SQL_Insert(qUpdate, S);

        S := 'INSERT INTO Log_SIGNAL_SCHREIBEN (Nr, DatumZeit, Datumexakt, BetriebsAuftragNr, Lizenz, MaschNr, '
          + 'MODUL,VERSION,KAV,VAR_KAV,SignalNr, Wert)'
          + ' VALUES (Log_SIGNAL_SCHREIBENID.NextVal,'
          + ' ''' + DateTimeToStr(Now) + ''','
          + FloatToPunktString(Now) + ','
          + ' ''' + BetriebsauftragNr + ''','
          + ' ''' + Lizenz + ''','
          + ' ''' + MaschNr + ''','
          + ' ''' + FModul + ''','
          + ' ''' + FVersion + ''','
          + ' ''' + IntToStr(Kav) + ''','
          + ' ''' + IntToStr(VAR_KAV) + ''','
          + ' ''' + IntToStr(SignalNr) + ''','
          + ' ''1'')';
        SQL_Insert(qUpdate, S);
      end;

      if Packen and not Verpackt_Barcode then
      begin
        SignalNr := CAUFTRAGRESETPACK;
        if SQLGet(qSuch, 'SIGNALE', 'SignalArt', IntToStr(SignalNr), True) > 0 then
          SignalNr := qSuch.FieldByName('SignalNr').AsInteger
        else
          SignalNr := -1;
        S := 'INSERT INTO SIGNAL_SCHREIBEN (Nr,MaschNr,SignalNr,Wert)'
          + 'VALUES(SIGNAL_SCHREIBENID.NextVal'
          + ',''' + MaschNr
          + ''',''' + IntToStr(SignalNr)
          + ''',''1'
          + ''')';
        SQL_Insert(qUpdate, S);

        S := 'INSERT INTO Log_SIGNAL_SCHREIBEN (Nr, DatumZeit, Datumexakt, BetriebsAuftragNr, Lizenz, MaschNr, '
          + 'MODUL,VERSION,KAV,VAR_KAV,SignalNr, Wert)'
          + ' VALUES (Log_SIGNAL_SCHREIBENID.NextVal,'
          + ' ''' + DateTimeToStr(Now) + ''','
          + FloatToPunktString(Now) + ','
          + ' ''' + BetriebsauftragNr + ''','
          + ' ''' + Lizenz + ''','
          + ' ''' + MaschNr + ''','
          + ' ''' + FModul + ''','
          + ' ''' + FVersion + ''','
          + ' ''' + IntToStr(Kav) + ''','
          + ' ''' + IntToStr(VAR_KAV) + ''','
          + ' ''' + IntToStr(SignalNr) + ''','
          + ' ''1'')';
        SQL_Insert(qUpdate, S);
      end;
    end;
  end;
end;

procedure TCO_Auftrag.Mengenabgleich(BetriebsauftragNr: string);
var
  S: string;
  Nr: Integer;
  AProduz, AVerp, AAussch: Integer;
  SProduz, SVerp, SAussch: Integer;
  Packen: Boolean;
begin
  if SQLGet(qSuch, 'AARchiv', 'BetriebsauftragNr', BetriebsauftragNr, True) > 0 then
  begin
    AProduz := qSuch.FieldByName('ProduziertInt').AsInteger;
    AVerp := qSuch.FieldByName('VerpacktInt').AsInteger;
    AAussch := qSuch.FieldByName('Ausschuss').AsInteger;

    S := 'select * from TPM_Schicht'
      + ' where BetriebsauftragNr = ''' + BetriebsauftragNr + ''' order by DatumZeit Desc';
    SQL_Get(qSuch, S);
    qSuch.First;
    Nr := qSuch.FieldByName('Nr').AsInteger;
    S := 'select Sum(Produziert) P, Sum(Verpackt) V, Sum(Ausschuss) A from TPM_Schicht'
      + ' where BetriebsauftragNr = ''' + BetriebsauftragNr + ''' and Nr <> ' + IntToStr(Nr);
    SQL_Get(qSuch, S);
    SProduz := qSuch.FieldByName('P').AsInteger;
    SVerp := qSuch.FieldByName('V').AsInteger;
    SAussch := qSuch.FieldByName('A').AsInteger;

    if AProduz - SProduz > 0 then
    begin
      S := 'update TPM_Schicht set Produziert = ' + IntToStr(AProduz - SProduz) + ' where Nr = ' + IntToStr(Nr);
      SQL_Insert(qUpdate, S);
    end;

    Packen := fPacken;
    if Packen then
    begin
      if AProduz - SProduz > 0 then
      begin
        S := 'update TPM_Schicht set Verpackt = ' + IntToStr(AVerp - SVerp) + ' where Nr = ' + IntToStr(Nr);
        SQL_Insert(qUpdate, S);
      end;
      S := 'update TPM_Schicht set Ausschuss = Produziert - Verpackt'
        + ' where BetriebsAuftragNr = ''' + BetriebsauftragNr + ''''
        + ' and Produziert - Verpackt > 0';
      SQL_Insert(qUpdate, S);
    end
    else
    begin
      if AAussch - SAussch > 0 then
      begin
        S := 'update TPM_Schicht set Ausschuss = ' + IntToStr(AAussch - SAussch) + ' where Nr = ' + IntToStr(Nr);
        SQL_Insert(qUpdate, S);
      end;
      S := 'update TPM_Schicht set Verpackt = Produziert - Ausschuss'
        + ' where BetriebsAuftragNr = ''' + BetriebsauftragNr + ''''
        + ' and Produziert - Ausschuss > 0';
      SQL_Insert(qUpdate, S);
    end;
  end;
end;

procedure TCO_Auftrag.KavProt_Insert(BANr: string; Wert1, Wert2: Integer; Bediener: string = ''; CommentID: integer = -1);
var
  MaschNr, Lizenz, S: string;
  SignalNr2, schuss, Prod2, Prod: Integer;
begin
  if SQLGet(qSuch, 'PDE', 'BetriebsAuftragNr', BANr, True) > 0 then
  begin
    try
      Lizenz := qSuch.FieldByName('Lizenz').AsString;
      Prod := qSuch.FieldByName('Istwert').AsInteger;
    except begin
      Lizenz := '';
      Prod := 0;
    end;
    end;


    if SQLGet(qSuch2, 'Maschine', 'Lizenz', Lizenz, True) > 0 then
      MaschNr := qSuch2.FieldByName('MaschNr').AsString
    else
      MaschNr := '0';

    SignalNr2 := CSTUECKAUFTRAGGESAMT;
    if SQLGet(qSuch2, 'SIGNALE', 'SignalArt', IntToStr(SignalNr2), True) > 0 then
      SignalNr2 := qSuch2.FieldByName('SignalNr').AsInteger
    else
      SignalNr2 := -1;
    S := 'SELECT istwert FROM signal_maschine WHERE signalnr = ' + IntToStr(SignalNr2) + ' AND maschnr = ' + MaschNr;
    SQL_Get(qSuch2,S);
    if not qSuch2.IsEmpty then
      Schuss := qSuch2.FieldByName('istwert').AsInteger
    else
      Schuss := 0;


    S := 'SELECT * FROM kavProt WHERE betriebsauftragnr = ''' + BANr + ''' AND Datum > ' + FloatToPunktString(Now - TCO_Setup.GetParamInt(qSuch,'INCL_CavityChangePeriod')/ 86400) + ' ORDER BY datum DESC';
    SQL_Get(qSuch2,S);
    if not qSuch2.IsEmpty then
    begin
      try
        Prod2 := qSUch2.FieldByName('Produziert').AsInteger;
      except
        Prod2 := 0;
      end;
      if Prod < Prod2 then
        Prod := Prod2;
    end;

    if CommentID > -1 then
      S := 'insert into KavProt (Nr, BetriebsAuftragNr, AuftragNr, Bezeichnung,'
        + ' Lizenz, Wert1, Wert2, Produziert, Bediener, Datum, EintragDatum, notizid, schusszaehler) values (KavProtId.NextVal,'
        + ' ''' + BANr + ''','
        + ' ''' + qSuch.FieldByName('AuftragNr').AsString + ''','
        + ' ''' + qSuch.FieldByName('Bezeichnung').AsString + ''','
        + ' ''' + qSuch.FieldByName('Lizenz').AsString + ''','
        + ' ''' + IntToStr(Wert1) + ''','
        + ' ''' + IntToStr(Wert2) + ''','
        + ' ''' + IntToStr(Prod) + ''','
        + ' ''' + Bediener + ''','
        + FloatToPunktString(Now) + ','
        + FloatToPunktString(Now) + ','
        + IntToStr(CommentID) + ','
        + IntToStr(schuss) + ')'
    else
      S := 'insert into KavProt (Nr, BetriebsAuftragNr, AuftragNr, Bezeichnung,'
        + ' Lizenz, Wert1, Wert2, Produziert, Bediener, Datum, EintragDatum, Schusszaehler) values (KavProtId.NextVal,'
        + ' ''' + BANr + ''','
        + ' ''' + qSuch.FieldByName('AuftragNr').AsString + ''','
        + ' ''' + qSuch.FieldByName('Bezeichnung').AsString + ''','
        + ' ''' + qSuch.FieldByName('Lizenz').AsString + ''','
        + ' ''' + IntToStr(Wert1) + ''','
        + ' ''' + IntToStr(Wert2) + ''','
        + ' ''' + IntToStr(Prod) + ''','
        + ' ''' + Bediener + ''','
        + FloatToPunktString(Now) + ','
        + FloatToPunktString(Now) + ','
        + IntToStr(schuss) + ')' ;
    SQL_Insert(qUpdate, S);

    if fWZKavitaet_Update then
    begin
      S := 'update Werkzeug set WZKavitaet = ' + IntToStr(Wert2)
        + ' where Werkzeug = ''' + qSuch.FieldByName('Werkzeug').AsString + '''';
      try
        SQL_Insert(qUpdate, S);
      except
      end;
    end;

    if fKavitaet_laufender_Auftrag = 2 then
      AuftragBuchen(BANr, Prod);
  end;
end;

procedure TCO_Auftrag.EndDatumPlusInit;
begin
  EDPInit(qSuch);
end;

function TCO_Auftrag.GetError(A: Integer): string;
begin
  case A of
    Auftrag_nicht_gefunden:
      Result := IntToStr(A) + ': ' + CO_AuftragGetL('Auftrag nicht gefunden');
    Werkzeug_nicht_auf_Maschine:
      Result := IntToStr(A) + ': ' + CO_AuftragGetL('Werkzeug nicht auf Maschine');
    Maschine_nicht_frei:
      Result := IntToStr(A) + ': ' + CO_AuftragGetL('Maschine nicht frei');
    Anderer_Auftrag_wird_geruestet:
      Result := IntToStr(A) + ': ' + CO_AuftragGetL('Anderer Auftrag wird gerüstet');
    Fehler_Auftragsstart:
      Result := IntToStr(A) + ': ' + CO_AuftragGetL('Fehler Auftragsstart');
    Werkzeug_nicht_vorhanden:
      Result := IntToStr(A) + ': ' + CO_AuftragGetL('Werkzeug nicht vorhanden');
    Auftrag_terminiert:
      Result := IntToStr(A) + ': ' + CO_AuftragGetL('Auftrag terminiert');
    Maschine_Optimiert:
      Result := IntToStr(A) + ': ' + CO_AuftragGetL('Maschine optimiert');
    Kurze_Laufzeit:
      Result := IntToStr(A) + ': ' + CO_AuftragGetL('Kurze Laufzeit');
    Werkzeug_nicht_im_Standort :
      Result := IntToStr(A) + ': ' + CO_AuftragGetL('Werkzeug nicht im Standort');
    Auftrag_nur_geruestet :
      Result := IntToStr(A) + ': ' + CO_AuftragGetL('Der Auftrag lief bisher nur im Rüsten. Mindestlaufzeit beachten!');
    Maschine_wartet_auf_FliegendenWechsel :
      Result := IntToStr(A) + ': ' + CO_AuftragGetL('Es liegt noch ein Ereignis für einen fliegenden Wechsel an!');
    Auftrag_nicht_gestartet:
      Result := IntToStr(A) + ': ' + CO_AuftragGetL('Auftrag nicht gestartet');
    Konnte_Index_nicht_erzeugen:
      Result := IntToStr(A) + ': ' + CO_AuftragGetL('Konnte Index nicht erzeugen');
    DatenbankName_nicht_definiert:
      Result := IntToStr(A) + ': ' + CO_AuftragGetL('DatenbankName nicht definiert');
    Datenbankanbindung_gescheitert:
      Result := IntToStr(A) + ': ' + CO_AuftragGetL('Datenbankanbindung gescheitert');
    Einsatz_in_Reparatur:
      Result := IntToStr(A) + ': ' + CO_AuftragGetL('Einsatz in Reparatur');
  else
    Result := IntToStr(A) + ': ' + CO_AuftragGetL('Fehler unbekannt');
  end;
end;

function TCO_Auftrag.FloatToPunktString(aFloat: Extended): string;
begin
  Result := FloatToStr(aFloat);
  if Pos(',', Result) > 0 then
  begin
    Insert('.', Result, Pos(',', Result));
    Delete(Result, Pos(',', Result), 1);
  end;
end;

function TCO_Auftrag.FloatToPunktStringF(aFloat: Extended; format: TFloatFormat; prec, digits: Integer): string;
begin
  Result := FloatToStrF(aFloat, format, prec, digits);
  if Pos(',', Result) > 0 then
  begin
    Insert('.', Result, Pos(',', Result));
    Delete(Result, Pos(',', Result), 1);
  end;
end;

procedure TCO_Auftrag.SendJobdata(aAuftragNr : string; aMaschNr : Integer);
var s : string;
begin
  s := 'INSERT INTO job_start_request (nr, betriebsauftragnr, maschnr, requestdatetime, responsedatetime, response) '
    + ' VALUES (job_start_requestid.nextval, ''' + aAuftragNr + ''', ' + IntToStr(aMaschNr) + ', '
    + FloatToPunktString(Now) + ', 0, 0)';
  SQL_Insert(qUpdate,s);
end;

procedure TCO_Auftrag.ResetJobdata(aAuftragNr : string; aMaschNr : Integer);
var s : string;
begin
  s := 'INSERT INTO job_stop_request (nr, betriebsauftragnr, maschnr, requestdatetime, responsedatetime, response) '
    + ' VALUES (job_stop_requestid.nextval, ''' + aAuftragNr + ''', ' + IntToStr(aMaschNr) + ', '
    + FloatToPunktString(Now) + ', 0, 0)';
  SQL_Insert(qUpdate,s);
end;

procedure TCO_Auftrag.AbruestenBuchen(aLizenz : string; aBanr : string);
var start, ende : TDateTime;
    diff : Integer;
    s, banr : string;
    vorabzeit : Integer;
begin
  vorabzeit := TCO_Setup.GetParamInt(qSuch,'WS_MDE_VorabRuestenZeit');
  if vorabzeit = 0 then
    exit;
  // Nachsehen wann der vorherige Auftrag beendet wurde
  s := 'SELECT MIN(ersterstart) ersterstart, aarchiv.startdatumzeit, aarchiv.enddatumzeit, aarchiv.betriebsauftragnr FROM aarchiv '
    + ' LEFT JOIN laufzeitlog ON laufzeitlog.betriebsauftragnr = aarchiv.betriebsauftragnr '
    + ' WHERE maschine = ''' + aLizenz + ''''
    + ' GROUP BY laufzeitlog.betriebsauftragnr, aarchiv.startdatumzeit, aarchiv.enddatumzeit,  aarchiv.betriebsauftragnr '
    + ' ORDER BY startdatumzeit DESC ';
  qSuch.SQL.Text := s;
  qSuch.Open;
  start := 0;
  ende := 0;
  if not qSuch.Eof then // Erster Auftrag ist aktuell gestarteter Auftrag
  begin
    start := qSuch.FieldByName('ersterstart').AsFloat;
    banr := qSuch.FieldByName('betriebsauftragnr').AsString;
  end;
  if banr = aBanr then
  begin
    qSuch.Next;
    if not qSuch.Eof then
      ende := qSuch.FieldByName('enddatumzeit').AsFloat;
  end
  else
  begin
    start := Now;
    ende := qSuch.FieldByName('enddatumzeit').AsFloat;
  end;
  qSuch.Close;

  diff := Round((ende - start) * 1440);

  if (diff < vorabzeit) and (diff > 0) then
  begin
    // Stillstand buchen
    s := 'UPDATE tpm_stillog SET stillstandnr = 2'
      + ' WHERE stillstandnr < 2 '
      + ' AND maschnr = (SELECT maschnr FROM maschine WHERE lizenz = '''+aLizenz+''')'
      + ' AND (geht > ' + FloatToPunktString(start) + ' OR geht = 0) AND kommt < ' + FloatToPunktString(ende);
    qUpdate.SQL.Text := s;
    qUpdate.ExecSQL;

    // Abrüstzeit von 'diff' Minuten zu letztem Rüsteintrag hinzuzählen
    s := 'UPDATE ruestprot SET abruest = ' + IntToStr(diff)
      + ' WHERE nr = (SELECT MAX(nr) FROM ruestprot WHERE lizenz = ''' + aLizenz + ''''
      + ' AND ruestende > 0)';
    qUpdate.SQL.Text := s;
    qUpdate.ExecSQL;

  end;


end;

function TCO_Auftrag.RetrieveToolState(query: TCO_Query): Integer;
var
  ToolState: Integer;
  ToolStateString: string;
begin
  ToolState := 0;
  if fWZStatusInt then
    Toolstate := query.FieldByName('Statusint').AsInteger
  else
  begin
    ToolStateString := query.FieldByName('Status').AsString;
    if ToolStateString = CO_AuftragGetL('Lager') then
      ToolState := 0
    else
      if ToolStateString = CO_AuftragGetL('Maschine') then
        ToolState := 1
      else
        if ToolStateString = CO_AuftragGetL('Reparatur') then
          ToolState := 2
        else
          if ToolStateString = '' then
            ToolState := -1;
  end;
  Result := ToolState;
end;

function TCO_Auftrag.Get_Daten_aus_Archiv(Table: string; Von: Real; AliasTabelle: Boolean): string;
const
  TabsCount = 2;
  ATab: array[1..TabsCount] of string = ('AARCHIV', 'TPM_STILLOG');
  AFeld: array[1..TabsCount] of string = ('SETTINGDATE', 'NOTIZ');
var
  I, J, Tage: Integer;
  S, F: string;
begin
  Tage := TCO_Setup.GetParamInt(qSuch, 'Archivsmandant_Tage');
  if (Now - Von < Tage) or (Tage = 0) then
    Result := Table
  else
  begin
    SQL_Get(qSuch, 'select * from ' + Table);
    S := '';
    for I := 0 to qSuch.FieldCount - 1 do
    begin
      F := qSuch.Fields[I].Fieldname;

      for J := 1 to TabsCount do
        if (UpperCase(Table) = UpperCase(ATab[J])) and (UpperCase(F) = UpperCase(AFeld[J])) then
{$IFDEF INCL_ORA}
          F := 'to_char(' + F + ') ' + F;
{$ELSE}
          F := 'CAST(' + F + ' AS VARCHAR(25)) ' + F;
{$ENDIF}

      S := S + F + ', ';
    end;
    System.Delete(S, Length(S) - 1, 2);
    S := '(SELECT ''live'' sourcemandant, ' + S + ' FROM ' + Table
       + ' UNION SELECT ''archive'' sourcemandant, ' + S
       + ' FROM ' + fOraSession.UserName + '_Arc.' + Table + ')';
    if AliasTabelle then
      S := S + ' ' + Table;

    Result := S;
  end;
end;

function  TCO_Auftrag.StoreInterruptSignals(MaschNr : string; BANr : string) : integer;
var s : string;
begin
  result := 0;
  s := 'DELETE FROM interruptsignals WHERE betriebsauftragnr = ''' + BANr + '''';
  SQL_Insert(qUpdate, s);
  s := 'SELECT * FROM signal_maschine WHERE maschnr = ' + maschnr + ' AND storeoninterrupt > 0';
  SQL_Get(qSuch2, s);
  while not qSuch2.Eof do
  begin
    s := 'INSERT INTO interruptsignals (nr, datumzeit, maschnr, signalnr, istwert, betriebsauftragnr) '
      + ' VALUES (interruptsignalsid.NextVal, ' + FloatToPunktString(Now) + ' , ' + maschnr + ', '
      + qSuch2.FieldByName('signalnr').AsString + ',' + FloatToPunktString(qSuch2.FieldByName('istwert').AsFloat)
      + ',''' + BANr + ''')';
    SQL_Insert(qUpdate, s);
    inc(result);
    qSuch2.Next;
  end;
end;

function TCO_Auftrag.RecoverInterruptSignals(MaschNr : string; BANr : string; Lizenz : string) : integer;
var s : string;
    istwert : integer;
begin
  result :=0;
  s := 'DELETE FROM signal_schreiben WHERE maschnr = ''' + Maschnr + '''';
  SQL_Insert(qUpdate, s);
  AuftragBuchen(BANr, 0);
  s := 'SELECT * FROM interruptsignals WHERE betriebsauftragnr = ''' + BANr + '''';
  SQL_Get(qSuch2, s);
  while not qSuch2.Eof do
  begin
    istwert  :=  qSuch2.FieldByName('istwert').AsInteger;
    if istwert = 0 then
      istwert := 1;
    s := 'INSERT INTO signal_schreiben (nr, maschnr, signalnr, wert, counter) '
      + ' VALUES (signal_schreibenid.NextVal, '+ maschnr + ', '
      + qSuch2.FieldByName('signalnr').AsString + ',' + IntToStr(istwert)
      + ',0)';
    SQL_Insert(qUpdate, s);

    s := 'INSERT INTO Log_SIGNAL_SCHREIBEN (Nr, DatumZeit, Datumexakt, BetriebsAuftragNr, Lizenz, MaschNr, '
        + 'MODUL,VERSION,SignalNr, Wert)'
        + ' VALUES (Log_SIGNAL_SCHREIBENID.NextVal,'
        + ' ''' + DateTimeToStr(Now) + ''','
        + FloatToPunktString(Now) + ','
        + ' ''' + BAnr + ''','
        + ' ''' + Lizenz + ''','
        + ' ''' + maschnr + ''','
        + ' ''' + FModul + ''','
        + ' ''' + FVersion + ''','
        + ' ''' + qSuch2.FieldByName('signalnr').AsString + ''','
        + ' ''' + IntToStr(qSuch2.FieldByName('istwert').AsInteger)+ ''')';
      SQL_Insert(qUpdate, s);
    inc(result);
    qSuch2.Next;
  end;
end;

function TCO_Auftrag.StringIsNumber(src : string):boolean;
var i :Integer;
begin
  try
    result := true;
    for i := 1 to length(src)do
      if not(src[i] in ['1','2','3','4','5','6','7','8','9','0',',','.']) then
        result := false;

  except
    result := false;
  end;
end;

function TCO_Auftrag.StringIsInteger(src : string):boolean;
var i :Integer;
begin
  try
    result := true;
    for i := 1 to length(src)do
      if not(src[i] in ['1','2','3','4','5','6','7','8','9','0']) then
        result := false;

  except
    result := false;
  end;
end;

end.
