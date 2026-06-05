unit CO_SPC_V63;

interface

uses
  CO_DataBase, Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, Variants, sprache_V63;

const
  SPC_BEST_VALUE = 10; //bei identischen Meßwerten CP = CPK = SPC_BEST_VALUE

  COUNT_MIN_VALUES = 10; //Mindestens COUNT_MIN_VALUES Werte zum Berechnen von SPC-Daten

  //Return Values
  SPC_OK = 0; //Alles OK

  SPC_ERROR = -1; //Undefinierter Fehler

  E_NO_MASCHNR = 5000; //FaschNr <= 0 OR NULL  -> Eingabeparameter nicht eingegeben
  E_MASCH_NOT_FOUND = 5001; //Maschine nicht in Tabelle gefunden

  E_NO_ORDERNR = 5010; //FAuftragNr = '' OR NULL  -> Eingabeparameter nicht eingegeben
  E_ORDER_NOT_FOUND = 5011; //AuftragNr nicht in Tabelle gefunden

  E_NOT_ENOUGHT_VALUES = 5100; //Anzahl der Messwert <  COUNT_MIN_VALUES

  E_NO_SETVALUES = 5200; //Keine Sollwerte in QSPCSETUP

type

  TErrorEvent = procedure(Sender: TObject; Msg: string; var Handled: Boolean) of object;
  FuncGetL = function(T: string): string; stdcall;
  ComtasError = class(Exception);

type
  TCO_SPC = class(TComponent)
  private
    { Private-Deklarationen}
    fOraSession: TCO_Database;

    FMaschNr: Integer;
    FAuftragNr: string;
    FArtikelNr: string;
    FSchicht: Integer;

    qSuch, qSuch2, qSuch3, qUpdate: TCO_Query;
    qSuchS, qSuch2S, qSuch3S, qUpdateS: TCO_Query;

    Sollwert: Real;
    Tol1P: Integer; //Toleranz +
    Tol1N: Integer;
    Tol2P: Integer;
    Tol2N: Integer;

    Mittel: Real;
    STDAbw: Real;
    Varianz: Real;
    CP: Real;
    CPK: Real;
    Spann: Real;
    Min: Real;
    MAX: Real;
    AnzMin: Integer;
    AnzMax: Integer;
    FActiveAlarming: Boolean;
    FFehlerMeldung : string;

    procedure SetDatabase(S: TCO_Database);

    procedure SetMaschNr(I: Integer);
    procedure SetAuftragNr(S: string);
    procedure SetArtikelNr(S: string);
    procedure SetSchicht(I: Integer);

    procedure Sollwerte_Schreiben(Masch: string; Sig: string);
  protected
    { Protected-Deklarationen}
  public
    { Public-Deklarationen}
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function Init: Integer;
    procedure SQL_Get(Query: TCO_Query; SQLStr: string);
    procedure SQL_Insert(Query: TCO_Query; SQLStr: string);
    procedure UpdateSQL(Query: TCO_Query; Tabelle: string; UpdateFeld: string; UpdateWert: string;
      WhereFeld: string; WhereWert: string);
    function SQLGet(Query: TCO_Query; Tabelle: string; Feld: string; Wert: string; Ergebnis: Boolean): Integer;

    function GetMaschine(MaschNr: Integer; query : TCO_Query): string;

    function GetCP_Wert(Standardabweichung, Sollwert: Real; TollMin, TollMax: Integer): Real;

    function GetCPK_Wert(CP_Wert, Mittel, Sollwert: Real; TollMin, TollMax: Integer): Real;

    function SPC_Berechnung_Schicht: Integer;
    function SPC_Berechnung_Auftrag: Integer;
    function SPC_NachBerechnung_Auftrag: Integer;

    function SPC_Sollwerte_Aktivieren: Integer;

    procedure Schreibe_SPC_Meldung(MaschNr: Integer; Meldung: string; Stat: Integer; query : TCO_Query);
    function FloatToPunktString ( dateVal:TDateTime):string;
  published
    { Published-Deklarationen }
    property OraSession: TCO_Database read fOraSession write SetDatabase;

    property MaschNr: Integer read FMaschNr write SetMaschNr;
    property AuftragNr: string read FAuftragNr write SetAuftragNr;
    property ArtikelNr: string read FArtikelNr write SetArtikelNr;
    property Schicht: Integer read FSchicht write SetSchicht;
    property Active_Alarming: Boolean read FActiveAlarming write FActiveAlarming;
    property FehlerMeldung : string read FFehlerMeldung;
  end;

var
  CO_SPCGetL: FuncGetL;

procedure Register;
function GetLErsatz(T: string): string; stdcall;

implementation

procedure Register;
begin
  RegisterComponents('comtas', [TCO_SPC]);
end;

constructor TCO_SPC.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  if @CO_SPCGetL = nil then
  begin
    MessageDlg('CO_SPCGetL nicht definiert!', mtWarning, [mbOK], 0);
    CO_SPCGetL := GetLErsatz;
  end;

  qSuch := TCO_Query.Create(AOwner);
  qSuch2 := TCO_Query.Create(AOwner);
  qSuch3 := TCO_Query.Create(AOwner);
  qUpdate := TCO_Query.Create(AOwner);
  qSuchS := TCO_Query.Create(AOwner);
  qSuch2S := TCO_Query.Create(AOwner);
  qSuch3S := TCO_Query.Create(AOwner);
  qUpdateS := TCO_Query.Create(AOwner);
end;

destructor TCO_SPC.Destroy;
begin

  if qSuch <> nil then
    qSuch.Destroy;
  if qSuch2 <> nil then
    qSuch2.Destroy;
  if qSuch3 <> nil then
    qSuch3.Destroy;
  if qUpdate <> nil then
    qUpdate.Destroy;

  if qSuchS <> nil then
    qSuchS.Destroy;
  if qSuch2S <> nil then
    qSuch2S.Destroy;
  if qSuch3S <> nil then
    qSuch3S.Destroy;
  if qUpdateS <> nil then
    qUpdateS.Destroy;
  inherited Destroy;
end;

procedure TCO_SPC.SetDatabase(S: TCO_Database);
begin
  fOraSession := S;
  if qSuch.Active then
    qSuch.Close;
  if qSuch2.Active then
    qSuch2.Close;
  if qSuch3.Active then
    qSuch3.Close;
  if qUpdate.Active then
    qUpdate.Close;
  if qSuchS.Active then
    qSuchS.Close;
  if qSuch2S.Active then
    qSuch2S.Close;
  if qSuch3S.Active then
    qSuch3S.Close;
  if qUpdateS.Active then
    qUpdateS.Close;
  qSuchS.Database := fOraSession;
  qSuch2S.Database := fOraSession;
  qSuch3S.Database := fOraSession;
  qUpdateS.Database := fOraSession;
  qSuch.Database := fOraSession;
  qSuch2.Database := fOraSession;
  qSuch3.Database := fOraSession;
  qUpdate.Database := fOraSession;
  Init;
end;

procedure TCO_SPC.SetMaschNr(I: Integer);
begin
  FMaschNr := I;
end;

procedure TCO_SPC.SetAuftragNr(S: string);
begin
  FAuftragNr := S;
end;

procedure TCO_SPC.SetArtikelNr(S: string);
begin
  FArtikelNr := S;
end;

procedure TCO_SPC.SetSchicht(I: Integer);
begin
  FSchicht := I;
end;

function TCO_SPC.Init: Integer;
begin
  Result := 0;
end;

//*****************************************************************
//*****
//*****************************************************************

function TCO_SPC.GetCP_Wert(Standardabweichung, Sollwert: Real; TollMin, TollMax: Integer): Real;
var
  TMin, tMax: Real;
  T, Tmp: Real; //Toleranz
begin
  //Formel siehe "Hanser -> Qualitätssicherung" Seite 209 ff.
  //berechnung von T
  TMin := Sollwert - ((Sollwert * TollMin) / 100);
  tMax := Sollwert + ((Sollwert * TollMax) / 100);
  T := ABS(tMax - TMin);
  //****************

  if Standardabweichung <= 0 then
    // Result:= 9999999 // Unendlicher CP-Wert
    Tmp := 0 // Normalerweise 0, auf Wunsch von Mentor 10 !!
  else
    Tmp := ABS(T / (6 * Standardabweichung));

  if Tmp < 0 then
    Tmp := 0;
  if Tmp > SPC_BEST_VALUE then
    Tmp := SPC_BEST_VALUE;

  Result := Tmp;
end;

function TCO_SPC.GetCPK_Wert(CP_Wert, Mittel, Sollwert: Real; TollMin, TollMax: Integer): Real;
var
  TMin, tMax: Real;
  T: Real; //Toleranz
  M: Real;
  K: Real;
  Tmp: Real;
begin
  //Formel siehe "Hanser -> Qualitätssicherung" Seite 209 ff.
  //berechnung von T
  TMin := Sollwert - ((Sollwert * TollMin) / 100);
  tMax := Sollwert + ((Sollwert * TollMax) / 100);
  T := ABS(tMax - TMin);
  //****************
  M := (TMin + tMax) / 2;

  if T = 0 then
    T := 1;
  // M = Toleranzmitte
  K := (ABS(M - Mittel) / (T / 2)); // T = Toleranzbandmitte
  // Mittel = Mittelwert der Messreihe
  Tmp := (CP_Wert * (1 - K));

  if Tmp < 0 then
    Tmp := 0;
  if Tmp > SPC_BEST_VALUE then
    Tmp := SPC_BEST_VALUE;

  Result := Tmp;

  if CP_Wert = 9999999 then
    Result := 9999999; // Unendlicher CP-Wert!!!
end;

//*****************************************************************
//*****
//*****************************************************************

function TCO_SPC.SPC_Berechnung_Schicht: Integer;
var
  SQLStr, Sig, IST_SIG, Maschine: string;
  SPCAktiv: Boolean;
  Meld: string;
begin
  if ((FMaschNr = 0) or (FMaschNr = Null)) then
  begin
    Result := E_NO_MASCHNR;
    Exit;
  end;
  if ((FAuftragNr = '') or (FAuftragNr = Null)) then
  begin
    Result := E_NO_ORDERNR;
    Meld := CO_SPCGetL('Fehler SPC-Schichtberechnung: ungültige AuftragNr');
    Schreibe_SPC_Meldung(FMaschNr, Meld, 0, qUpdateS);
    Exit;
  end;

  SQLStr := 'select COUNT(*) CNT from QSPCSCHICHT where AUFTRAGNR = ''' + FAuftragNr + '''';
  SQL_Get(qSuchS, SQLStr);
  if qSuchS.FieldByName('CNT').AsInteger < COUNT_MIN_VALUES then
  begin
    Result := E_NOT_ENOUGHT_VALUES;
    Meld := CO_SPCGetL('Fehler SPC-Schichtberechnung: zu wenig Meßwerte ( < ') + IntToStr(COUNT_MIN_VALUES) + ' )';
    Schreibe_SPC_Meldung(FMaschNr, Meld, 0, qUpdateS);
    Exit;
  end;

  Maschine := GetMaschine(FMaschNr, qSuch3S);
  if (SQLGet(qSuchS, 'QSPCSETUP', 'Maschine', Maschine, True) = 0) then
  begin
    Result := E_NO_SETVALUES;
    Meld := CO_SPCGetL('Fehler SPC-Schichtberechnung: keine Sollwerte und Toleranzen');
    Schreibe_SPC_Meldung(FMaschNr, Meld, 0,qUpdateS);
    Exit;
  end;

  //***************************************************************
  SQLStr := 'select * from signal_maschine,signale where Signal_maschine.MaschNr = ''' + IntToStr(FMaschNr) +
    ''' AND (Signale.SignalNr = Signal_maschine.SignalNr ) and Signale.SPC = 1 ';
  SQL_Get(qSuch2S, SQLStr);
  qSuch2S.First;
  while not qSuch2S.EOF do
  begin
    Sig := qSuch2S.FieldByName('SIGNAL').AsString;

    //***************************************************************
    SPCAktiv := True;
    SQLGet(qSuchS, 'QSPCSETUP', 'Maschine', Maschine, False);
    if qSuchS.FieldByName('SPCAKT_' + Sig).AsInteger = 0 then
      SPCAktiv := False;
    Sollwert := qSuchS.FieldByName('Sollwert_' + Sig).AsFloat;
    Tol1P := qSuchS.FieldByName('Tol1P_' + Sig).AsInteger;
    Tol1N := qSuchS.FieldByName('Tol1N_' + Sig).AsInteger;
    Tol2P := qSuchS.FieldByName('Tol2P_' + Sig).AsInteger;
    Tol2N := qSuchS.FieldByName('Tol2N_' + Sig).AsInteger;

    //***************************************************************
    if SPCAktiv then
    begin
      IST_SIG := 'IST_' + Sig;
      SQLStr := 'select AVG(' + IST_SIG + ') as Mittel, '
        + 'STDDEV(' + IST_SIG + ') as STDAbw, '
        + 'VARIANCE (' + IST_SIG + ') as VARIANZ, '
        + 'MIN(' + IST_SIG + ') as MIN, '
        + 'MAX(' + IST_SIG + ') as MAX  '
        + 'from QSPCSCHICHT where AUFTRAGNR = ''' + FAuftragNr + '''';

      SQL_Get(qSuchS, SQLStr);
      Mittel := qSuchS.FieldByName('Mittel').AsFloat;
      STDAbw := qSuchS.FieldByName('STDAbw').AsFloat;
      Varianz := qSuchS.FieldByName('VARIANZ').AsFloat;
      Min := qSuchS.FieldByName('MIN').AsFloat;
      MAX := qSuchS.FieldByName('MAX').AsFloat;
      Spann := MAX - Min;

      CP := GetCP_Wert(STDAbw, Sollwert, Tol1N, Tol1P);
      CPK := GetCPK_Wert(CP, Mittel, Sollwert, Tol1N, Tol1P);

      SQLStr := 'select count(*) CNT from  QSPCSCHICHT where AUFTRAGNR = ''' + FAuftragNr + ''''
        + ' AND ' + IST_SIG + ' > ''' + FloatToStr(Sollwert + (Sollwert * Tol1P / 100)) + '''';
      SQL_Get(qSuchS, SQLStr);
      AnzMax := qSuchS.FieldByName('CNT').AsInteger;

      SQLStr := 'select count(*) cnt from  QSPCSCHICHT where AUFTRAGNR = ''' + FAuftragNr + ''''
        + ' AND ' + IST_SIG + ' < ''' + FloatToStr(Sollwert - (Sollwert * Tol1N / 100)) + '''';
      SQL_Get(qSuchS, SQLStr);
      AnzMin := qSuchS.FieldByName('cnt').AsInteger;
    end
    else
    begin //if SPCAktiv then begin
      Mittel := 0;
      STDAbw := 0;
      Varianz := 0;
      Min := 0;
      MAX := 0;
      Spann := 0;
      CP := 0;
      CPK := 0;
      AnzMax := 0;
      AnzMin := 0;
    end;

    //***************************************************************
    //Plausibilität
    if ((CP = 0) and (CPK = 0)
      and (STDAbw = 0) and (Mittel > 0)
      and (AnzMax = 0) and (AnzMin = 0)) then
    begin
      CP := SPC_BEST_VALUE;
      CPK := SPC_BEST_VALUE;
    end;

    //***************************************************************
    SQLStr := 'SELECT COUNT(*) cnt from QSPC where AuftragNr = ''' + FAuftragNr + ''''
      + ' AND Schicht = ''' + IntToStr(FSchicht) + ''' AND Trunc(DatumZeit) = ''' + IntToStr(Trunc(Now)) + '''';
    SQL_Get(qSuchS, SQLStr);
    if qSuchS.FieldByName('cnt').AsInteger = 0 then
    begin

      SQLStr := 'INSERT INTO QSPC (Nr,Maschine,AuftragNr,DatumZeit,'
        + 'Schicht,Mittel_' + Sig + ',STD_ABW_' + Sig + ',VAR_' + Sig + ','
        + 'Sollwert_' + Sig + ', '
        + 'CP_' + Sig + ',CPK_' + Sig + ',SPANN_' + Sig + ','
        + 'Min_' + Sig + ',Max_' + Sig + ',ANZ_Max_' + Sig + ',ANZ_Min_' + Sig + ','
        + 'Tol1P_' + Sig + ',Tol1N_' + Sig + ',Tol2P_' + Sig + ',Tol2N_' + Sig + ')'
        + 'VALUES(QSPCID.NextVal'
        + ',''' + Maschine
        + ''',''' + FAuftragNr
        + ''',''' + FloatToStr(Now)
        + ''',''' + IntToStr(FSchicht)
        + ''',''' + FloatToStr(Mittel)
        + ''',''' + FloatToStr(STDAbw)
        + ''',''' + FloatToStr(Varianz)
        + ''',''' + FloatToStr(Sollwert)

      + ''',''' + FloatToStr(CP)
        + ''',''' + FloatToStr(CPK)
        + ''',''' + FloatToStr(Spann)
        + ''',''' + FloatToStr(Min)
        + ''',''' + FloatToStr(MAX)

      + ''',''' + IntToStr(AnzMax)
        + ''',''' + IntToStr(AnzMin)

      + ''',''' + IntToStr(Tol1P)
        + ''',''' + IntToStr(Tol1N)
        + ''',''' + IntToStr(Tol2P)
        + ''',''' + IntToStr(Tol2N)

      + ''')';

(*      qUpdateS.Close;
      qUpdateS.SQL.Clear;
      qUpdateS.SQL.Add(SQLStr);
      qUpdateS.ExecSQL;*)
      SQL_Insert(qUpdateS, SQLStr);

    end
    else
    begin
      SQLStr := 'update QSPC set '
        + 'Mittel_' + Sig + ' =             ''' + FloatToStr(Mittel)
        + ''',STD_ABW_' + Sig + ' = ''' + FloatToStr(STDAbw)
        + ''',VAR_' + Sig + ' =         ''' + FloatToStr(Varianz)
        + ''',Sollwert_' + Sig + ' =        ''' + FloatToStr(Sollwert)
        + ''',CP_' + Sig + ' =              ''' + FloatToStr(CP)
        + ''',CPK_' + Sig + ' =             ''' + FloatToStr(CPK)
        + ''',SPANN_' + Sig + ' =      ''' + FloatToStr(Spann)
        + ''',Min_' + Sig + ' =             ''' + FloatToStr(Min)
        + ''',Max_' + Sig + ' =             ''' + FloatToStr(MAX)
        + ''',ANZ_Max_' + Sig + ' =         ''' + IntToStr(AnzMax)
        + ''',ANZ_Min_' + Sig + ' =         ''' + IntToStr(AnzMin)
        + ''',TOL1P_' + Sig + ' =           ''' + IntToStr(Tol1P)
        + ''',TOL1N_' + Sig + ' =           ''' + IntToStr(Tol1N)
        + ''',TOL2P_' + Sig + ' =           ''' + IntToStr(Tol2P)
        + ''',TOL2N_' + Sig + ' =           ''' + IntToStr(Tol2N)

      + ''' where AuftragNr = ''' + FAuftragNr + '''';

      try
        SQL_Insert(qUpdateS, SQLStr);
      except
      end; //except
    end; //else begin

    //***************************************************************
    //Schichtdatensätze löschen...

    Meld := CO_SPCGetL('SPC-Schichtberechnung erfolgreich durchgeführt');
    Schreibe_SPC_Meldung(FMaschNr, Meld, 1, qUpdateS);

    qSuch2S.Next;
  end; //while NOT Daten.qSuch2.EOF do begin

  SQLStr := 'delete from qspcschicht where auftragNr = ''' + FAuftragNr + '''';
  SQL_Insert(qUpdateS, SQLStr);

  Result := SPC_OK;
end;

//***************************************************************

function TCO_SPC.SPC_Berechnung_Auftrag: Integer;
var
  SQLStr, Sig, Maschine: string;
  SPCAktiv, keineAktivenSignale, keineSignaleGefunden: Boolean;
  Meld, Bez, Artikel: string;
begin
  FFehlerMeldung := '';
  if ((FMaschNr = 0) or (FMaschNr = Null)) then
  begin
    Result := E_NO_MASCHNR;
    Exit;
  end;
  if ((FAuftragNr = '') or (FAuftragNr = Null)) then
  begin
    Result := E_NO_ORDERNR;
    Meld := CO_SPCGetL('Fehler SPC-Auftragberechnung: ungültige AuftragNr');
    Schreibe_SPC_Meldung(FMaschNr, Meld, 0, qUpdate);
    Exit;
  end;

  //***************************************************************
  //Aktuelle Schicht abschließen...
  SPC_Berechnung_Schicht;

  SQLStr := 'select COUNT(*) cnt from QSPC where AUFTRAGNR = ''' + FAuftragNr + '''';
  SQL_Get(qSuch3, SQLStr);
  if qSuch3.FieldByName('cnt').AsInteger = 0 then
  begin
    Result := E_NOT_ENOUGHT_VALUES;
    Meld := CO_SPCGetL('Fehler SPC-Auftragberechnung: zu wenig Meßwerte ( = 0 )');
    Schreibe_SPC_Meldung(FMaschNr, Meld, 0, qUpdate);
    Exit;
  end;

  Maschine := GetMaschine(FMaschNr, qSuch3);
  if (SQLGet(qSuch3, 'QSPCSETUP', 'Maschine', Maschine, True) = 0) then
  begin
    Result := E_NO_SETVALUES;
    Meld := CO_SPCGetL('Fehler SPC-Auftragberechnung: keine Sollwerte und Toleranzen');
    Schreibe_SPC_Meldung(FMaschNr, Meld, 0, qUpdate);
    Exit;
  end;

  //***************************************************************
  SQLStr := 'select * from signal_maschine,signale where Signal_maschine.MaschNr = '''
    + IntToStr(FMaschNr) + ''' AND (Signale.SignalNr = Signal_maschine.SignalNr ) and Signale.SPC = 1 ';
  SQL_Get(qSuch2, SQLStr);
  qSuch2.First;
  keineAktivenSignale := true;
  keineSignaleGefunden := true;
  while not qSuch2.EOF do
  begin
    keineSignaleGefunden:=false;
    Sig := qSuch2.FieldByName('SIGNAL').AsString;

    //***************************************************************
    SPCAktiv := True;
    SQLGet(qSuch, 'QSPCSETUP', 'Maschine', Maschine, False);
    if qSuch.FieldByName('SPCAKT_' + Sig).AsInteger = 0 then
      SPCAktiv := False;
    Sollwert := qSuch.FieldByName('Sollwert_' + Sig).AsFloat;
    Tol1P := qSuch.FieldByName('Tol1P_' + Sig).AsInteger;
    Tol1N := qSuch.FieldByName('Tol1N_' + Sig).AsInteger;
    Tol2P := qSuch.FieldByName('Tol2P_' + Sig).AsInteger;
    Tol2N := qSuch.FieldByName('Tol2N_' + Sig).AsInteger;

    //***************************************************************
    if SPCAktiv then
    begin
      keineAktivenSignale := false;
      SQLStr := 'select AVG(CP_' + Sig + ') as CP, '
        + 'AVG(CPK_' + Sig + ') as CPK, '
        + 'AVG(VAR_' + Sig + ') as VARIANZ, '
        + 'AVG(STD_ABW_' + Sig + ') as STDAbw, '
        + 'AVG(SPANN_' + Sig + ') as SPANN,  '
        + 'MIN(MIN_' + Sig + ') as MIN, '
        + 'MAX(MAX_' + Sig + ') as MAX,  '
        + 'AVG(MITTEL_' + Sig + ') as MITTEL,  '
        + 'SUM(ANZ_MAX_' + Sig + ') as ANZ_MAX,  '
        + 'SUM(ANZ_MIN_' + Sig + ') as ANZ_MIN  '
        + 'from QSPC where AUFTRAGNR = ''' + FAuftragNr + '''';

      SQL_Get(qSuch, SQLStr);
      Mittel := qSuch.FieldByName('Mittel').AsFloat;
      STDAbw := qSuch.FieldByName('STDAbw').AsFloat;
      Varianz := qSuch.FieldByName('VARIANZ').AsFloat;
      Min := qSuch.FieldByName('MIN').AsFloat;
      MAX := qSuch.FieldByName('MAX').AsFloat;
      Spann := qSuch.FieldByName('SPANN').AsFloat;
      CP := qSuch.FieldByName('CP').AsFloat;
      CPK := qSuch.FieldByName('CPK').AsFloat;
      AnzMax := qSuch.FieldByName('ANZ_MAX').AsInteger;
      AnzMin := qSuch.FieldByName('ANZ_MIN').AsInteger;

    end
    else
    begin //if SPCAktiv then begin
      Mittel := 0;
      STDAbw := 0;
      Varianz := 0;
      Min := 0;
      MAX := 0;
      Spann := 0;
      CP := 0;
      CPK := 0;
      AnzMax := 0;
      AnzMin := 0;
    end;
    //***************************************************************
    SQLStr := 'Select * from PDE where BETRIEBSAuftragNr = ''' + FAuftragNr + '''';
    SQL_Get(qSuch, SQLStr);
    Bez := qSuch.FieldByName('Bezeichnung').AsString;
    Artikel := qSuch.FieldByName('AuftragNr').AsString;

    SQLStr := 'SELECT COUNT(*) cnt from QSPCARCHIV where BETRIEBSAuftragNr = ''' + FAuftragNr + '''';
    SQL_Get(qSuch, SQLStr);
    if qSuch.FieldByName('cnt').AsInteger = 0 then
    begin

      SQLStr := 'INSERT INTO QSPCARCHIV (Nr,Maschine,BETRIEBSAuftragNr,AuftragNr,Bezeichnung,DatumZeit,'
        + 'Mittel_' + Sig + ',STD_ABW_' + Sig + ',VAR_' + Sig + ','
        + 'Sollwert_' + Sig + ', '
        + 'CP_' + Sig + ',CPK_' + Sig + ',SPANN_' + Sig + ','
        + 'Min_' + Sig + ',Max_' + Sig + ',ANZ_Max_' + Sig + ',ANZ_Min_' + Sig + ','
        + 'Tol1P_' + Sig + ',Tol1N_' + Sig + ',Tol2P_' + Sig + ',Tol2N_' + Sig + ')'
        + 'VALUES(QSPCARCHIVID.NextVal'
        + ',''' + Maschine
        + ''',''' + FAuftragNr
        + ''',''' + Artikel
        + ''',''' + Bez
        + ''',''' + FloatToStr(Now)
        + ''',''' + FloatToStr(Mittel)
        + ''',''' + FloatToStr(STDAbw)
        + ''',''' + FloatToStr(Varianz)
        + ''',''' + FloatToStr(Sollwert)

      + ''',''' + FloatToStr(CP)
        + ''',''' + FloatToStr(CPK)
        + ''',''' + FloatToStr(Spann)
        + ''',''' + FloatToStr(Min)
        + ''',''' + FloatToStr(MAX)

      + ''',''' + IntToStr(AnzMax)
        + ''',''' + IntToStr(AnzMin)

      + ''',''' + IntToStr(Tol1P)
        + ''',''' + IntToStr(Tol1N)
        + ''',''' + IntToStr(Tol2P)
        + ''',''' + IntToStr(Tol2N)

      + ''')';

      qUpdate.Close;
      qUpdate.SQL.Clear;
      qUpdate.SQL.Add(SQLStr);
      qUpdate.ExecSQL;

    end
    else
    begin
      SQLStr := 'update QSPCARCHIV set '
        + 'Mittel_' + Sig + ' =             ''' + FloatToStr(Mittel)
        + ''',STD_ABW_' + Sig + ' = ''' + FloatToStr(STDAbw)
        + ''',VAR_' + Sig + ' =         ''' + FloatToStr(Varianz)
        + ''',Sollwert_' + Sig + ' =        ''' + FloatToStr(Sollwert)
        + ''',CP_' + Sig + ' =              ''' + FloatToStr(CP)
        + ''',CPK_' + Sig + ' =             ''' + FloatToStr(CPK)
        + ''',SPANN_' + Sig + ' =      ''' + FloatToStr(Spann)
        + ''',Min_' + Sig + ' =             ''' + FloatToStr(Min)
        + ''',Max_' + Sig + ' =             ''' + FloatToStr(MAX)
        + ''',ANZ_Max_' + Sig + ' =         ''' + IntToStr(AnzMax)
        + ''',ANZ_Min_' + Sig + ' =         ''' + IntToStr(AnzMin)
        + ''',TOL1P_' + Sig + ' =           ''' + IntToStr(Tol1P)
        + ''',TOL1N_' + Sig + ' =           ''' + IntToStr(Tol1N)
        + ''',TOL2P_' + Sig + ' =           ''' + IntToStr(Tol2P)
        + ''',TOL2N_' + Sig + ' =           ''' + IntToStr(Tol2N)
        + ''' where BETRIEBSAuftragNr = ''' + FAuftragNr + '''';

      try
        SQL_Insert(qUpdate, SQLStr);
      except
      end; //except
    end; //else begin

    //***************************************************************

    Meld := CO_SPCGetL('SPC-Auftragberechnung erfolgreich durchgeführt');
    Schreibe_SPC_Meldung(FMaschNr, Meld, 1, qUpdate);

    qSuch2.Next;
  end; //while NOT Daten.qSuch2.EOF do begin
  if keineAktivenSignale then
  begin
    Meld := CO_SPCGetL('Keine aktiven Signale für SPC-Auftragsberechnung (' + FAuftragNr + ') gefunden');
    Schreibe_SPC_Meldung(FMaschNr, Meld, 1, qUpdate);
  end;
  if keineSignaleGefunden then
  begin
    Meld := CO_SPCGetL('Keine Signale für SPC-Auftragsberechnung (' + FAuftragNr + ') gefunden');
    Schreibe_SPC_Meldung(FMaschNr, Meld, 1, qUpdate);
  end;
  Result := SPC_OK;
end;

function TCO_SPC.SPC_NachBerechnung_Auftrag: Integer;
var
  SQLStr, Sig, Maschine: string;
  SPCAktiv: Boolean;
  Meld, Bez, Artikel: string;
  date : extended;
begin
  if ((FMaschNr = 0) or (FMaschNr = Null)) then
  begin
    Result := E_NO_MASCHNR;
    Exit;
  end;
  if ((FAuftragNr = '') or (FAuftragNr = Null)) then
  begin
    Result := E_NO_ORDERNR;
    Meld := CO_SPCGetL('Fehler SPC-Auftragberechnung: ungültige AuftragNr');
    Schreibe_SPC_Meldung(FMaschNr, Meld, 0, qUpdate);
    Exit;
  end;

  SQLStr := 'select COUNT(*) cnt from QSPC where AUFTRAGNR = ''' + FAuftragNr + '''';
  SQL_Get(qSuch3, SQLStr);
  if qSuch3.FieldByName('cnt').AsInteger = 0 then
  begin
    Result := E_NOT_ENOUGHT_VALUES;
    Meld := CO_SPCGetL('Fehler SPC-Auftragberechnung: zu wenig Meßwerte ( = 0 )');
    Schreibe_SPC_Meldung(FMaschNr, Meld, 0, qUpdate);
    Exit;
  end;

  Maschine := GetMaschine(FMaschNr, qSuch3);
  if (SQLGet(qSuch3, 'QSPCSETUP', 'Maschine', Maschine, True) = 0) then
  begin
    Result := E_NO_SETVALUES;
    Meld := CO_SPCGetL('Fehler SPC-Auftragberechnung: keine Sollwerte und Toleranzen');
    Schreibe_SPC_Meldung(FMaschNr, Meld, 0, qUpdate);
    Exit;
  end;

  //***************************************************************
  SQLStr := 'select * from signal_maschine,signale where Signal_maschine.MaschNr = '''
    + IntToStr(FMaschNr) + ''' AND (Signale.SignalNr = Signal_maschine.SignalNr ) and Signale.SPC = 1 ';
  SQL_Get(qSuch2, SQLStr);
  qSuch2.First;
  while not qSuch2.EOF do
  begin
    Sig := qSuch2.FieldByName('SIGNAL').AsString;

    //***************************************************************
    SPCAktiv := True;
    SQLGet(qSuch, 'QSPCSETUP', 'Maschine', Maschine, False);
    if qSuch.FieldByName('SPCAKT_' + Sig).AsInteger = 0 then
      SPCAktiv := False;
    Sollwert := qSuch.FieldByName('Sollwert_' + Sig).AsFloat;
    Tol1P := qSuch.FieldByName('Tol1P_' + Sig).AsInteger;
    Tol1N := qSuch.FieldByName('Tol1N_' + Sig).AsInteger;
    Tol2P := qSuch.FieldByName('Tol2P_' + Sig).AsInteger;
    Tol2N := qSuch.FieldByName('Tol2N_' + Sig).AsInteger;

    //***************************************************************
    if SPCAktiv then
    begin
      SQLStr := 'select AVG(CP_' + Sig + ') as CP, '
        + 'AVG(CPK_' + Sig + ') as CPK, '
        + 'AVG(VAR_' + Sig + ') as VARIANZ, '
        + 'AVG(STD_ABW_' + Sig + ') as STDAbw, '
        + 'AVG(SPANN_' + Sig + ') as SPANN,  '
        + 'MIN(MIN_' + Sig + ') as MIN, '
        + 'MAX(MAX_' + Sig + ') as MAX,  '
        + 'AVG(MITTEL_' + Sig + ') as MITTEL,  '
        + 'SUM(ANZ_MAX_' + Sig + ') as ANZ_MAX,  '
        + 'SUM(ANZ_MIN_' + Sig + ') as ANZ_MIN  '
        + 'from QSPC where AUFTRAGNR = ''' + FAuftragNr + '''';

      SQL_Get(qSuch, SQLStr);
      Mittel := qSuch.FieldByName('Mittel').AsFloat;
      STDAbw := qSuch.FieldByName('STDAbw').AsFloat;
      Varianz := qSuch.FieldByName('VARIANZ').AsFloat;
      Min := qSuch.FieldByName('MIN').AsFloat;
      MAX := qSuch.FieldByName('MAX').AsFloat;
      Spann := qSuch.FieldByName('SPANN').AsFloat;
      CP := qSuch.FieldByName('CP').AsFloat;
      CPK := qSuch.FieldByName('CPK').AsFloat;
      AnzMax := qSuch.FieldByName('ANZ_MAX').AsInteger;
      AnzMin := qSuch.FieldByName('ANZ_MIN').AsInteger;

    end
    else
    begin //if SPCAktiv then begin
      Mittel := 0;
      STDAbw := 0;
      Varianz := 0;
      Min := 0;
      MAX := 0;
      Spann := 0;
      CP := 0;
      CPK := 0;
      AnzMax := 0;
      AnzMin := 0;
    end;
    //***************************************************************
    SQLStr := 'Select * from aarchiv where BETRIEBSAuftragNr = ''' + FAuftragNr + '''';
    SQL_Get(qSuch, SQLStr);
    Bez := qSuch.FieldByName('Bezeichnung').AsString;
    Artikel := qSuch.FieldByName('AuftragNr').AsString;
    date := qSuch.FieldByName('enddatumzeit').AsFloat;
    SQLStr := 'SELECT COUNT(*) cnt from QSPCARCHIV where BETRIEBSAuftragNr = ''' + FAuftragNr + '''';
    SQL_Get(qSuch, SQLStr);
    if qSuch.FieldByName('cnt').AsInteger = 0 then
    begin

      SQLStr := 'INSERT INTO QSPCARCHIV (Nr,Maschine,BETRIEBSAuftragNr,AuftragNr,Bezeichnung,DatumZeit,'
        + 'Mittel_' + Sig + ',STD_ABW_' + Sig + ',VAR_' + Sig + ','
        + 'Sollwert_' + Sig + ', '
        + 'CP_' + Sig + ',CPK_' + Sig + ',SPANN_' + Sig + ','
        + 'Min_' + Sig + ',Max_' + Sig + ',ANZ_Max_' + Sig + ',ANZ_Min_' + Sig + ','
        + 'Tol1P_' + Sig + ',Tol1N_' + Sig + ',Tol2P_' + Sig + ',Tol2N_' + Sig + ')'
        + 'VALUES(QSPCARCHIVID.NextVal'
        + ',''' + Maschine
        + ''',''' + FAuftragNr
        + ''',''' + Artikel
        + ''',''' + Bez
        + ''',' + FloatToPunktString(date)
        + ',' + FloatToPunktString(Mittel)
        + ',' + FloatToPunktString(STDAbw)
        + ',' + FloatToPunktString(Varianz)
        + ',' + FloatToPunktString(Sollwert)

      + ',' + FloatToPunktString(CP)
        + ',' + FloatToPunktString(CPK)
        + ',' + FloatToPunktString(Spann)
        + ',' + FloatToPunktString(Min)
        + ',' + FloatToPunktString(MAX)

      + ',''' + IntToStr(AnzMax)
        + ''',''' + IntToStr(AnzMin)

      + ''',''' + IntToStr(Tol1P)
        + ''',''' + IntToStr(Tol1N)
        + ''',''' + IntToStr(Tol2P)
        + ''',''' + IntToStr(Tol2N)

      + ''')';

      qUpdate.Close;
      qUpdate.SQL.Clear;
      qUpdate.SQL.Add(SQLStr);
      qUpdate.ExecSQL;

    end
    else
    begin
      SQLStr := 'update QSPCARCHIV set '
        + 'Mittel_' + Sig + ' =             ' + FloatToPunktString(Mittel)
        + ',STD_ABW_' + Sig + ' = ' + FloatToPunktString(STDAbw)
        + ',VAR_' + Sig + ' =         ' + FloatToPunktString(Varianz)
        + ',Sollwert_' + Sig + ' =        ' + FloatToPunktString(Sollwert)
        + ',CP_' + Sig + ' =              ' + FloatToPunktString(CP)
        + ',CPK_' + Sig + ' =             ' + FloatToPunktString(CPK)
        + ',SPANN_' + Sig + ' =      ' + FloatToPunktString(Spann)
        + ',Min_' + Sig + ' =             ' + FloatToPunktString(Min)
        + ',Max_' + Sig + ' =             ' + FloatToPunktString(MAX)
        + ',ANZ_Max_' + Sig + ' =         ''' + IntToStr(AnzMax)
        + ''',ANZ_Min_' + Sig + ' =         ''' + IntToStr(AnzMin)
        + ''',TOL1P_' + Sig + ' =           ''' + IntToStr(Tol1P)
        + ''',TOL1N_' + Sig + ' =           ''' + IntToStr(Tol1N)
        + ''',TOL2P_' + Sig + ' =           ''' + IntToStr(Tol2P)
        + ''',TOL2N_' + Sig + ' =           ''' + IntToStr(Tol2N)
        + ''' where BETRIEBSAuftragNr = ''' + FAuftragNr + '''';

      try
        SQL_Insert(qUpdate, SQLStr);
      except
      end; //except
    end; //else begin

    //***************************************************************

    Meld := CO_SPCGetL('SPC-Auftragberechnung erfolgreich durchgeführt');
    Schreibe_SPC_Meldung(FMaschNr, Meld, 1, qUpdate);

    qSuch2.Next;
  end; //while NOT Daten.qSuch2.EOF do begin

  Result := SPC_OK;
end;

//***************************************************************

function TCO_SPC.SPC_Sollwerte_Aktivieren: Integer;
var
  SQLStr, Meld, Maschine, Sig: string;
begin
  Result := SPC_ERROR;

  if ((FMaschNr = 0) or (FMaschNr = Null)) then
  begin
    Result := E_NO_MASCHNR;
    Exit;
  end;
  if ((FArtikelNr = '') or (FArtikelNr = Null)) then
  begin
    Result := E_NO_ORDERNR;
    Meld := CO_SPCGetL('Fehler SPC-Sollwerte lesen: ungültige ArtikelNr');
    Schreibe_SPC_Meldung(FMaschNr, Meld, 0, qUpdate);
    Exit;
  end;

  Maschine := GetMaschine(FMaschNr, qSuch3);
  //1. Prüfung -> Maschine UND ArtikelNr
  SQLStr := 'Select COUNT(*) cnt from QSPCARCHIV where Maschine = ''' + Maschine + ''''
    + ' AND AUFTRAGNR = ''' + FArtikelNr + '''';
  SQL_Get(qSuch, SQLStr);
  if qSuch.FieldByName('cnt').AsInteger > 0 then
    SQLStr := 'Select * from QSPCARCHIV where Maschine = ''' + Maschine + ''''
      + ' AND AUFTRAGNR = ''' + FArtikelNr + ''' order by DATUMZEIT DESC'
  else
  begin
    //2.Prüfung -> ArtikelNr
    SQLStr := 'Select COUNT(*) cnt from QSPCARCHIV where AUFTRAGNR = ''' + FArtikelNr + '''';
    SQL_Get(qSuch, SQLStr);
    if qSuch.FieldByName('cnt').AsInteger = 0 then
    begin
      // 3. Prüfung -> Stammdaten
      SQLStr := 'Select COUNT(*) cnt from QSPCSETUPAUFTRAG where ARTIKELNR = ''' + FArtikelNr + '''';
      SQL_Get(qSuch, SQLStr);
      if qSuch.FieldByName('cnt').AsInteger = 0 then
      begin
        //Kein Auftrag gefunden, also abbrechen!!
        Meld := CO_SPCGetL('SPC-Sollwerte lesen: keine Sollwerte gefunden...');
        Schreibe_SPC_Meldung(FMaschNr, Meld, 0, qUpdate);
        Exit;
      end
      else
      begin
        SQLStr := 'Select * from QSPCSETUPAUFTRAG where ARTIKELNR = ''' + FArtikelNr + ''' ';

      end;
    end
    else
      SQLStr := 'Select * from QSPCARCHIV where AUFTRAGNR = ''' + FArtikelNr + ''' order by DATUMZEIT DESC';
  end;

  //***************************************************************

  SQL_Get(qSuch, SQLStr);
  qSuch.First;
  //***************************************************************
  SQLStr := 'select * from signal_maschine,signale where Signal_maschine.MaschNr = '''
    + IntToStr(FMaschNr) + ''' AND (Signale.SignalNr = Signal_maschine.SignalNr ) and Signale.SPC = 1 ';
  SQL_Get(qSuch2, SQLStr);
  qSuch2.First;
  while not qSuch2.EOF do
  begin
    Sig := qSuch2.FieldByName('SIGNAL').AsString;

    Sollwert := qSuch.FieldByName('Sollwert_' + Sig).AsFloat;
    Tol1P := qSuch.FieldByName('Tol1P_' + Sig).AsInteger;
    Tol1N := qSuch.FieldByName('Tol1N_' + Sig).AsInteger;
    Tol2P := qSuch.FieldByName('Tol2P_' + Sig).AsInteger;
    Tol2N := qSuch.FieldByName('Tol2N_' + Sig).AsInteger;

    Sollwerte_Schreiben(Maschine, Sig);

    qSuch2.Next;
  end; //while NOT qSuch2.EOF do begin

  Meld := CO_SPCGetL('SPC-Sollwerte lesen: Sollwerte wurden übernommen');
  Schreibe_SPC_Meldung(FMaschNr, Meld, 1, qUpdate);

  Result := SPC_OK;
end;

procedure TCO_SPC.Sollwerte_Schreiben(Masch: string; Sig: string);
var
  SQLStr: string;
begin
  SQLStr := 'update QSPCSETUP set '
    + 'SOLLWERT_' + Sig + ' =  ''' + FloatToStr(Sollwert)
    + ''',TOL1P_' + Sig + ' =  ''' + IntToStr(Tol1P)
    + ''',TOL1N_' + Sig + ' =  ''' + IntToStr(Tol1N)
    + ''',TOL2P_' + Sig + ' =  ''' + IntToStr(Tol2P)
    + ''',TOL2N_' + Sig + ' =  ''' + IntToStr(Tol2N)
    + ''' where Maschine = ''' + Masch + '''';

  try
    SQL_Insert(qUpdate, SQLStr);
  except
  end; //except
end;

//***************************************************************

procedure TCO_SPC.Schreibe_SPC_Meldung(MaschNr: Integer; Meldung: string; Stat: Integer; query : TCO_Query);
var
  SQLStr, Maschine, Status: string;
  msgtype: Integer;
begin
  if (Meldung = '') then
    Exit;
  Maschine := GetMaschine(MaschNr, query);

  if Length(Meldung) > 99 then
    SetLength(Meldung, 99);

  Status := '';
  case Stat of
    0: Status := GetL('Fehler');
    1: Status := GetL('Meldung');
  end;

  SQLStr := 'INSERT INTO QSPCMELDUNG (Nr,Maschine,Maschnr,Meldung,DatumZeit,Status)'
    + 'VALUES(QSPCMELDUNGID.NextVal'
    + ',''' + Maschine
    + ''',''' + IntToStr(MaschNr)
    + ''',''' + Meldung
    + ''',' + FloatToPunktString(Now)
    + ',''' + Status
    + ''')';

  query.Close;
  query.SQL.Clear;
  query.SQL.Add(SQLStr);
  query.ExecSQL;

  case Stat of
    0: msgtype := ord(mtError);
    1: msgtype := ord(mtInformation);
  else
    msgtype := ord(mtInformation);
  end;

  if FActiveAlarming then
  begin // Aktive Alarmierung bei Eintrag über PopUp
    try
      SQLStr := 'INSERT INTO alertnotification (Nr, Alertstamp, Message, Typ, Confirmation) VALUES ('
        + 'AlertNotificationId.NextVal, '
         + FloatToPunktString(Now) + ', '
        + '''' + Maschine + ' : ' + Meldung + ''','
        + IntToStr(msgtype) + ', '
        + '0)';

      query.Close;
      query.SQL.Clear;
      query.SQL.Add(SQLStr);
      query.ExecSQL;
    except
    end;
  end;

end;


function TCO_SPC.FloatToPunktString (dateVal:TDateTime):string;
begin
 Result := FloatToStr(dateVal);
  if Pos(',', Result) > 0 then
  begin
    Insert('.', Result, Pos(',', Result));
    Delete(Result, Pos(',', Result), 1);
  end;
end;

//*****************************************************************
//*****
//*****************************************************************

function TCO_SPC.GetMaschine(MaschNr: Integer; query : TCO_Query): string;
var
  Tmp: Integer;
begin
  Tmp := SQLGet(query, 'MASCHINE', 'Datenblock', IntToStr(MaschNr), True);
  if Tmp > 0 then
    Result := query.FieldByName('Lizenz').AsString
  else
    Result := 'error';
end;

procedure TCO_SPC.SQL_Get(Query: TCO_Query; SQLStr: string);
begin
  Query.Close;
  with Query do
  begin
    //Screen.Cursor:= crSQLWait;
    SQL.Clear;
    SQL.Add(SQLStr);
    {if not Prepared then
       Prepare; }
    Open;
    //Screen.Cursor:= crDefault;
  end;
end;

procedure TCO_SPC.SQL_Insert(Query: TCO_Query; SQLStr: string);
begin
  Query.Close;
  with Query do
  begin
    //Screen.Cursor:= crSQLWait;
    SQL.Clear;
    SQL.Add(SQLStr);
    {if not Prepared then
       Prepare; }
    ExecSQL;
    Close;
    //Screen.Cursor:= crDefault;
  end;
end;

procedure TCO_SPC.UpdateSQL(Query: TCO_Query; Tabelle: string; UpdateFeld: string; UpdateWert: string;
  WhereFeld: string; WhereWert: string);
var
  SQLStr: string;
begin
  SQLStr := 'UPDATE ' + Tabelle + ' SET ' + UpdateFeld + '=''' + UpdateWert + ''' where ' + WhereFeld + '=''' + WhereWert + '''';
  SQL_Insert(Query, SQLStr);
end;

function TCO_SPC.SQLGet(Query: TCO_Query; Tabelle: string; Feld: string; Wert: string; Ergebnis: Boolean): Integer;
var
  SQLStr: string;
begin

  if Ergebnis then
  begin
    SQLStr := 'Select COUNT(*) cnt from ' + Tabelle + ' where ' + Feld + '=''' + Wert + '''';
    Query.Close;
    Query.SQL.Clear;
    Query.SQL.Add(SQLStr);
    Query.Open;
    Result := Query.FieldByName('cnt').AsInteger;
  end
  else
    Result := -1;

  SQLStr := 'Select * from ' + Tabelle + ' where ' + Feld + '=''' + Wert + '''';
  Query.Close;
  Query.SQL.Clear;
  Query.SQL.Add(SQLStr);
  Query.Open;
end;

function GetLErsatz(T: string): string;
begin
  Result := T;
end;

end.

