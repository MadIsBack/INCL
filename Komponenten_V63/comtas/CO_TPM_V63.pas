unit CO_TPM_V63;

interface

uses
  CO_DataBase, SysUtils, DBTables, DB, Classes, CO_Setup2, SchichtUtilLib;

const
  azSchicht = 0;
  azFrei = 1;

  lgSchicht = 0;
  lgTag = 1;
  lgWoche = 2;
  lgMonat = 3;

  CANLAGENAUSFALL = 0;
  CRUESTEN = 1;
  CLOGISTIK = 2;
  CNICHT_GEBUCHT = 3;

  // Stillstandnummern (System_ID !!!!!) als Konstanten
  CSTILLNRNICHTGEBUCHT = 1;
  CSTILLNRRUESTENGEPLANT = 2;
  CSTILLNRARBEITSFREI = 3;
  CSTILLNRVORRICHTUNG = 4;
  CSTILLNRKURZSTOERUNG = 5;
  CSTILLNRMASCHINEBLOCK = 6;
  CSTILLNRPAUSE = 7;
  CSTILLNRRUESTENWZ = 8;
  CSTILLNRMASCHINENICHTVORHANDEN = 9;
  CSTILLNRRUESTENUNGEPLANT = 10;

  CUNGEPLANT = 0;
  CGEPLANT = 1;

type
  TErrorEvent = procedure(Sender: TObject; Msg: string; var Handled: Boolean) of object;
  FuncGetL = function(T: string): string; stdcall;

type
  ComtasError = class(Exception);

type
  TStillstand = record
    Stillstandnr: Integer;
    Bezeichnung: string;
    Aktion: Integer;
    Gruppe: Integer;
    Geplant: Boolean;
  end;

type
  TCO_TPM = class(TComponent)
  private

    fOraSession: TCO_Database;

    FVonDatum: TDateTime;
    FBisDatum: TDateTime;
    FMaschNr: Integer;
    FAlleMaschinen: Boolean;

    FZeitraum: Integer; // Zeitraum für Zeile in Tabelle
    FSchicht: Integer;
    fSchichtMinuten: Integer;
    FShift_Typ: string;
    FListGroup: Integer;

    FNutzung: Real;
    FLeistung: Real;
    FQualitaet: Real;
    FEffektivitaet: Real;
    FAnlagenausfall: Integer;
    FRuesten: Integer;
    FLogistik: Integer;
    FNichtGebucht: Integer;
    FGeplant: Integer;
    FUngeplant: Integer;
    FStops: Integer;
    FSollLaufzeit: Integer;
    FIstLaufzeit: Integer;
    FIstStillstand: Integer;
    FProduziert: Integer;

    FQuery: TCO_Query;

    qSuch, qSuch2, qUpdate: TCO_Query;
    Stillstand: array of TStillstand;

    Shift_Model: Integer;
    FAutoausschuss: Boolean;

    procedure SetDatabase(S: TCO_Database);

    procedure SetZeitraum(Z: Integer);
    procedure SetVonDatum(D: TDateTime);
    procedure SetBisDatum(D: TDateTime);
    procedure SetMaschNr(I: Integer);
    function GetStillIndex(Stillstandnr: Integer): Integer;
    function GetSQLSchichtTyp(Tab: string): string;
    procedure SetShift_Typ(A: string);
    procedure SetSchicht(A: Integer);
    function Format_String(Wert: string): Integer;
    function FloatToStr_Punkt(Value: Extended): string;
    function Get_Daten_aus_Archiv(Table: string; Von: Real; AliasTabelle: Boolean): string;
    function DoInit(force: boolean = True): integer;
  protected
  public
    Schicht1, Schicht2, Schicht3: Integer;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function Calculate(Korrektur: Boolean): Integer;
    function CalculateCached(stilllist : TStillstandEintragsListe): Integer;
    function GetStillZeit(Stillstandnr: Integer): Integer;
    function ReInit: Integer;
    function Init: Integer;
    function GetList(LizSQL: string): Integer;
    function GetProductionStatistics(aLizSQL: string): Integer;
    function GetProductionStatistics_Ext(LizSQL: string; Zeitraum, D1, D2: Integer): Integer;

    function GetProductionStatisticsExtrusion(LizSQL: string): Integer;
    function GetProductionStatistics_613: Integer;
    function GetControllingStatistics(LizSQL: string): Integer;
    procedure performanceprepare(von, bis: double);

    function GetOrderStatistics(LizSQL: string): Integer;
    function GetOrderStatisticsExtrusion(LizSQL: string): Integer;

    function GetOEEStatistics(aLizSQL: string): Integer;
    procedure OEEDetail_Update(aLiz: string; DataSet: TDataSet);

    function GetWerksKalenderSolllaufzeit(Datum: Real; Schi: Integer): Integer;
    procedure StillstandBuchen(Nr: Integer; Stillstand: string; BetriebsauftragNr: string = ''); //Nr = NR von TPM_STILLOG
    procedure StillstandErzeugen(Nr: Integer; Stillstand: string);

    function GetStillstandNr(Stillstand: string): Integer;
    function GetStillstand(Stillstandnr: Integer): string;
    function GetStillstandGruppe(Stillstand: string): Integer;
    function IsStillstandGeplant(Stillstand: string): Boolean;
    procedure SQL_Insert(Query: TCO_Query; SQLStr: string);
    procedure UpdateSQL(Query: TCO_Query; Tabelle: string; UpdateFeld: string; UpdateWert: string;
      WhereFeld: string; WhereWert: string);
    procedure SQL_Get(Query: TCO_Query; SQLStr: string);
    function SQLGet(Query: TCO_Query; Tabelle: string; Feld: string; Wert: string; Ergebnis: Boolean): Integer;
    function SQLGetBool(Query: TCO_Query; Tabelle: string; Feld: string; Wert: string): Boolean;

  published
    { Published-Deklarationen }
    property Database: TCO_Database read fOraSession write SetDatabase;

    property Zeitraum: Integer read FZeitraum write SetZeitraum;
    property Schicht: Integer read FSchicht write SetSchicht;
    property SchichtMinuten: Integer read fSchichtMinuten write fSchichtMinuten;

    property Shift_Typ: string read FShift_Typ write SetShift_Typ;
    property VonDatum: TDateTime read FVonDatum write SetVonDatum;
    property BisDatum: TDateTime read FBisDatum write SetBisDatum;
    property MaschNr: Integer read FMaschNr write SetMaschNr;
    property AlleMaschinen: Boolean read FAlleMaschinen write FAlleMaschinen;

    property ListGroup: Integer read FListGroup write FListGroup;

    property Nutzung: Real read FNutzung;
    property Leistung: Real read FLeistung;
    property Qualitaet: Real read FQualitaet;
    property Effektivitaet: Real read FEffektivitaet;

    property Anlagenausfall: Integer read FAnlagenausfall;
    property Ruesten: Integer read FRuesten;
    property Logistik: Integer read FLogistik;
    property NichtGebucht: Integer read FNichtGebucht;

    property Geplant: Integer read FGeplant;
    property Ungeplant: Integer read FUngeplant;

    property Stops: Integer read FStops;
    property Solllaufzeit: Integer read FSollLaufzeit;
    property IstLaufZeit: Integer read FIstLaufzeit;
    property IstStillstand: Integer read FIstStillstand;
    property Produziert: Integer read FProduziert;
    property AutoAusschuss: Boolean read FAutoausschuss write FAutoAusschuss;

    property Query: TCO_Query read FQuery write FQuery;
  end;

function GetLErsatz(T: string): string; stdcall;

var
  CO_TPMGetL: FuncGetL;

procedure Register;

implementation

uses
  Math, Dialogs, maindll;

procedure Register;
begin
  RegisterComponents('comtas', [TCO_TPM]);
end;

function GetLErsatz(T: string): string;
begin
  Result := T;
end;

constructor TCO_TPM.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  if @CO_TPMGetL = nil then
  begin
    MessageDlg('CO_TPMGetL nicht definiert!', mtWarning, [mbOK], 0);
    CO_TPMGetL := GetLErsatz;
  end;
  qSuch := TCO_Query.Create(AOwner);
  qSuch2 := TCO_Query.Create(AOwner);
  qUpdate := TCO_Query.Create(AOwner);

  Schicht1 := 6 * 60;
  Schicht2 := 14 * 60;
  Schicht3 := 22 * 60;

  SetZeitraum(azFrei);
  SetVonDatum(Date - 2);
  SetBisDatum(Date);
end;

destructor TCO_TPM.Destroy;
begin
  Stillstand := nil;

  if qSuch <> nil then
    qSuch.Destroy;
  if qSuch2 <> nil then
    qSuch2.Destroy;
  if qUpdate <> nil then
    qUpdate.Destroy;

  inherited Destroy;
end;

procedure TCO_TPM.SetDatabase(S: TCO_Database);
begin
  fOraSession := S;
  if qSuch.Active then
    qSuch.Close;
  if qSuch2.Active then
    qSuch2.Close;
  if qUpdate.Active then
    qUpdate.Close;
  qSuch.Database := fOraSession;
  qSuch2.Database := fOraSession;
  qUpdate.Database := fOraSession;
  Init;
end;

procedure TCO_TPM.SetZeitraum(Z: Integer);
begin
  FZeitraum := Z;
end;

procedure TCO_TPM.SetVonDatum(D: TDateTime);
begin
  FVonDatum := D;
end;

procedure TCO_TPM.SetBisDatum(D: TDateTime);
begin
  FBisDatum := D;
end;

procedure TCO_TPM.SetMaschNr(I: Integer);
begin
  FMaschNr := I;
end;

function TCO_TPM.CalculateCached(stilllist : TStillstandEintragsListe): Integer;
var
  I, j: Integer;
  SQLStr: string;
  VonDatum, BisDatum, Kommt, Geht: TDateTime;
  Stillstandnr, StillIndex: Integer;
  LaufzeitSoll: Integer;
  dAnlagenAusfall, dRuesten, dLogistik, dNichtGebucht, dGEplant, dUngeplant: double;
  maschsl : TStillstandEintragsListe;
begin
  Result := -1;
  if fOraSession = nil then
    Exit;
  if FVonDatum = 0 then
    Exit;
  if Zeitraum = azSchicht then
  begin
    VonDatum := FVonDatum;
    BisDatum := FBisDatum;
    if BisDatum > Now then
      BisDatum := Now;

    dAnlagenausfall := 0;
    dRuesten := 0;
    dLogistik := 0;
    dNichtGebucht := 0;
    dGeplant := 0;
    dUngeplant := 0;

    try
      maschsl := stilllist.GetByMaschNr(FMaschNr);
      FStops:=0;
      for i := 0 to maschsl.Count-1 do
        if maschsl.Items[i].Kommt > VonDatum then
          Inc(FStops);
    except
      FStops := -1;
    end;
//    maschsl.Destroy;
    maschsl.Free;
    I := 0;


  j := 0;
    maschsl := stilllist.GetByMaschNr(FMaschNr);
    for i := 0 to maschsl.Count-1 do
    begin
    j := i;
      Kommt := maschsl.Items[i].Kommt;
      Geht := maschsl.Items[i].Geht;
      if Geht = 0 then
        Geht := BisDatum;
      Stillstandnr := maschsl.Items[i].GrundNr;
      if Kommt < VonDatum then
        Kommt := VonDatum;
      if Geht > BisDatum then
        Geht := BisDatum;
      case maschsl.Items[i].Gruppe of
        0: dAnlagenausfall := dAnlagenausfall + ((Geht - Kommt) * 1440);
        1: dRuesten := dRuesten + ((Geht - Kommt) * 1440);
        2: dLogistik := dLogistik + ((Geht - Kommt) * 1440);
        3: dNichtGebucht := dNichtGebucht + ((Geht - Kommt) * 1440);
      end;
      if maschsl.Items[i].Geplant then
        dGeplant := dGeplant + ((Geht - Kommt) * 1440)
      else
        dUngeplant := dUngeplant + ((Geht - Kommt) * 1440);
    end;
    maschsl.Free;
    if dGeplant > fSchichtMinuten then
      dGeplant := fSchichtMinuten;
    if dUngeplant > fSchichtMinuten then
      dUngeplant := fSchichtMinuten;
    if FStops = -1 then
      FStops := j;
    FSollLaufzeit := Round(((BisDatum - VonDatum) * 1440) - dGeplant);
    FIstLaufzeit := Round(((BisDatum - VonDatum) * 1440) - dGeplant - dUngeplant);

    FAnlagenausfall := Round(dAnlagenausfall);
    FRuesten := Round(dRuesten);
    FLogistik := Round(dLogistik);
    FNichtGebucht := Round(dNichtGebucht);
    FGeplant := Round(dGeplant);
    FUngeplant := Round(dUngeplant);


    if ((FIstLaufzeit = 0) or (FIstLaufzeit > fSchichtMinuten)) and (j > 1) then
    begin
      FIstLaufzeit := FSollLaufzeit - FUngeplant;
    end;
  end
  else
  begin
    SQLStr := 'Select Avg(Leistung) as DLeistung, Avg(Qualitaet) as DQualitaet,'
      + ' Sum(Solllaufzeit) as SumSollLaufzeit, Sum(Istlaufzeit) as SumIstLaufzeit,'
      + ' Sum(Stops) as SumStops, Sum(Geplant) as SumGeplant, Sum(Ungeplant) as SumUngeplant,'
      + ' Sum(Anlagenausfall) As SumAnlagenausfall , Sum(Ruesten) as SumRuesten,'
      + ' Sum(Logistik) as SumLogistik, Sum(NichtGebucht) as SumNichtGebucht, Sum(Produziert) as Produziert'
      + ' from tpm_schicht'
      + ' where (DatumZeit between (' + FloatToStr_Punkt(FVonDatum) + ') and (' + FloatToStr_Punkt(FBisDatum + 1) + '))';

    if not FAlleMaschinen then
      SQLStr := SQLStr + ' and (maschnr = ''' + IntToStr(FMaschNr) + ''')';

    SQLStr := SQLStr + GetSQLSchichtTyp('');

    SQL_Get(qSuch, SQLStr);
    if not qSuch.EOF then
    begin
      FSollLaufzeit := qSuch.FieldByName('SumSollLaufzeit').AsInteger;
      FIstLaufzeit := qSuch.FieldByName('SumIstLaufzeit').AsInteger;

      if FSollLaufzeit = 0 then
        LaufzeitSoll := 1
      else
        LaufzeitSoll := FSollLaufzeit;

      FNutzung := FIstLaufzeit / LaufzeitSoll * 100;
      FLeistung := qSuch.FieldByName('DLeistung').AsFloat;
      FQualitaet := qSuch.FieldByName('DQualitaet').AsFloat;
      FEffektivitaet := (FNutzung / 100) * (FLeistung / 100) * FQualitaet;

      FAnlagenausfall := qSuch.FieldByName('SumAnlagenausfall').AsInteger;
      FRuesten := qSuch.FieldByName('SumRuesten').AsInteger;
      FLogistik := qSuch.FieldByName('SumLogistik').AsInteger;
      FNichtGebucht := qSuch.FieldByName('SumNichtGebucht').AsInteger;

      FGeplant := qSuch.FieldByName('SumGeplant').AsInteger;
      FUngeplant := qSuch.FieldByName('SumUngeplant').AsInteger;

      if FGeplant > fSchichtMinuten then
        FGeplant := fSchichtMinuten;
      if FUngeplant > fSchichtMinuten then
        FUngeplant := fSchichtMinuten;

      FStops := qSuch.FieldByName('SumStops').AsInteger;
      FProduziert := qSuch.FieldByName('Produziert').AsInteger;
    end
    else
    begin
      FNutzung := 0;
      FLeistung := 0;
      FQualitaet := 0;
      FEffektivitaet := 0;
      FSollLaufzeit := 0;
      FIstLaufzeit := 0;

      FAnlagenausfall := 0;
      FRuesten := 0;
      FLogistik := 0;
      FNichtGebucht := 0;

      FGeplant := 0;
      FUngeplant := 0;
      FStops := 0;

      FProduziert := 0;
    end;
  end;
  //maschsl.Destroy;
  FIstStillstand := FGeplant + FUngeplant;
  Result := 1;
end;



function TCO_TPM.Calculate(Korrektur: Boolean): Integer;
var
  I: Integer;
  SQLStr: string;
  VonDatum, BisDatum, Kommt, Geht: TDateTime;
  Stillstandnr, StillIndex: Integer;
  LaufzeitSoll: Integer;
  dAnlagenAusfall, dRuesten, dLogistik, dNichtGebucht, dGEplant, dUngeplant: double;
begin
  Result := -1;
  if fOraSession = nil then
    Exit;
  if FVonDatum = 0 then
    Exit;
  if Zeitraum = azSchicht then
  begin
    VonDatum := FVonDatum;
    BisDatum := FBisDatum;
    if BisDatum > Now then
      BisDatum := Now;

    dAnlagenausfall := 0;
    dRuesten := 0;
    dLogistik := 0;
    dNichtGebucht := 0;
    dGeplant := 0;
    dUngeplant := 0;

    try
      SQLStr := 'select count(*) cnt from TPM_STILLOG where MaschNr = ' + IntToStr(FMaschNr)
        + ' and (Kommt >= ' + FloatToStr_Punkt(VonDatum) + ' and Kommt <= ' + FloatToStr_Punkt(BisDatum) + ')';
      SQL_Get(qSuch, SQLStr);
      FStops := qSuch.FieldByName('cnt').AsInteger;
    except
      FStops := -1;
    end;

    I := 0;

    //    SQLStr := 'select * from TPM_STILLOG where MaschNr = ' + IntToStr(FMaschNr)
    //      + ' and'
    //      + ' (Kommt <= ''' + FloatToStr(VonDatum) + ''' and Decode(Geht, 0, ''' + FloatToStr(Now) + ''', Geht) >= '''
    //      + FloatToStr(VonDatum) + ''''
    //      + ' or'
    //      + ' Kommt >= ''' + FloatToStr(VonDatum) + ''' and Kommt <= ''' + FloatToStr(BisDatum) + ''')';

(*    SQLStr := 'select * from TPM_STILLOG where MaschNr = ' + IntToStr(FMaschNr)
      + ' and Kommt <= ' + FloatToStr_Punkt(BisDatum)
      + ' and Decode(Geht, 0, ' + FloatToStr_Punkt(Now) + ', Geht) >= ' + FloatToStr_Punkt(VonDatum);
      *)
    SQLStr := 'select * from TPM_STILLOG where MaschNr = ' + IntToStr(FMaschNr)
      + ' and Kommt <= ' + FloatToStr_Punkt(BisDatum)
      + ' and  case when geht = 0 then ' +FloatToStr_Punkt(Now)+ ' else geht end >= ' + FloatToStr_Punkt(VonDatum);
    SQL_Get(qSuch, SQLStr);
    while not qSuch.EOF do
    begin
      Kommt := qSuch.FieldByName('Kommt').AsFloat;
      Geht := qSuch.FieldByName('Geht').AsFloat;
      if Geht = 0 then
        Geht := BisDatum;
      Stillstandnr := qSuch.FieldByName('Stillstandnr').AsInteger;
      if Kommt < VonDatum then
        Kommt := VonDatum;
      if Geht > BisDatum then
        Geht := BisDatum;
      StillIndex := GetStillIndex(Stillstandnr);
      case Stillstand[StillIndex].Gruppe of
        0: dAnlagenausfall := dAnlagenausfall + ((Geht - Kommt) * 1440);
        1: dRuesten := dRuesten + ((Geht - Kommt) * 1440);
        2: dLogistik := dLogistik + ((Geht - Kommt) * 1440);
        3: dNichtGebucht := dNichtGebucht + ((Geht - Kommt) * 1440);
      end;
      if Stillstand[StillIndex].Geplant then
        dGeplant := dGeplant + ((Geht - Kommt) * 1440)
      else
        dUngeplant := dUngeplant + ((Geht - Kommt) * 1440);
      qSuch.Next;
      Inc(I);
    end;
    if dGeplant > fSchichtMinuten then
      dGeplant := fSchichtMinuten;
    if dUngeplant > fSchichtMinuten then
      dUngeplant := fSchichtMinuten;
    if FStops = -1 then
      FStops := I;
    FSollLaufzeit := Round(((BisDatum - VonDatum) * 1440) - dGeplant);
    FIstLaufzeit := Round(((BisDatum - VonDatum) * 1440) - dGeplant - dUngeplant);

    FAnlagenausfall := Round(dAnlagenausfall);
    FRuesten := Round(dRuesten);
    FLogistik := Round(dLogistik);
    FNichtGebucht := Round(dNichtGebucht);
    FGeplant := Round(dGeplant);
    FUngeplant := Round(dUngeplant);


    if ((FIstLaufzeit = 0) or (FIstLaufzeit > fSchichtMinuten)) and (I > 1) then
    begin
      FIstLaufzeit := FSollLaufzeit - FUngeplant;
    end;
  end
  else
  begin
    SQLStr := 'Select Avg(Leistung) as DLeistung, Avg(Qualitaet) as DQualitaet,'
      + ' Sum(Solllaufzeit) as SumSollLaufzeit, Sum(Istlaufzeit) as SumIstLaufzeit,'
      + ' Sum(Stops) as SumStops, Sum(Geplant) as SumGeplant, Sum(Ungeplant) as SumUngeplant,'
      + ' Sum(Anlagenausfall) As SumAnlagenausfall , Sum(Ruesten) as SumRuesten,'
      + ' Sum(Logistik) as SumLogistik, Sum(NichtGebucht) as SumNichtGebucht, Sum(Produziert) as Produziert'
      + ' from tpm_schicht'
      + ' where (DatumZeit between (' + FloatToStr_Punkt(FVonDatum) + ') and (' + FloatToStr_Punkt(FBisDatum + 1) + '))';

    if not FAlleMaschinen then
      SQLStr := SQLStr + ' and (maschnr = ''' + IntToStr(FMaschNr) + ''')';

    SQLStr := SQLStr + GetSQLSchichtTyp('');

    SQL_Get(qSuch, SQLStr);
    if not qSuch.EOF then
    begin
      FSollLaufzeit := qSuch.FieldByName('SumSollLaufzeit').AsInteger;
      FIstLaufzeit := qSuch.FieldByName('SumIstLaufzeit').AsInteger;

      if FSollLaufzeit = 0 then
        LaufzeitSoll := 1
      else
        LaufzeitSoll := FSollLaufzeit;

      FNutzung := FIstLaufzeit / LaufzeitSoll * 100;
      FLeistung := qSuch.FieldByName('DLeistung').AsFloat;
      FQualitaet := qSuch.FieldByName('DQualitaet').AsFloat;
      FEffektivitaet := (FNutzung / 100) * (FLeistung / 100) * FQualitaet;

      FAnlagenausfall := qSuch.FieldByName('SumAnlagenausfall').AsInteger;
      FRuesten := qSuch.FieldByName('SumRuesten').AsInteger;
      FLogistik := qSuch.FieldByName('SumLogistik').AsInteger;
      FNichtGebucht := qSuch.FieldByName('SumNichtGebucht').AsInteger;

      FGeplant := qSuch.FieldByName('SumGeplant').AsInteger;
      FUngeplant := qSuch.FieldByName('SumUngeplant').AsInteger;

      if FGeplant > fSchichtMinuten then
        FGeplant := fSchichtMinuten;
      if FUngeplant > fSchichtMinuten then
        FUngeplant := fSchichtMinuten;

      FStops := qSuch.FieldByName('SumStops').AsInteger;
      FProduziert := qSuch.FieldByName('Produziert').AsInteger;
    end
    else
    begin
      FNutzung := 0;
      FLeistung := 0;
      FQualitaet := 0;
      FEffektivitaet := 0;
      FSollLaufzeit := 0;
      FIstLaufzeit := 0;

      FAnlagenausfall := 0;
      FRuesten := 0;
      FLogistik := 0;
      FNichtGebucht := 0;

      FGeplant := 0;
      FUngeplant := 0;
      FStops := 0;

      FProduziert := 0;
    end;
  end;
  FIstStillstand := FGeplant + FUngeplant;
  Result := 1;
end;

function TCO_TPM.GetStillZeit(Stillstandnr: Integer): Integer;
var
  I: Integer;
  SQLStr: string;
  VonDatum, BisDatum, Kommt, Geht: TDateTime;
  StillIndex: Integer;
  LaufzeitSoll: Integer;
  Dauer: Integer;
begin
  Result := -1;
  if fOraSession = nil then
    Exit;
  if FVonDatum = 0 then
    Exit;
  if Zeitraum = azSchicht then
  begin
    VonDatum := FVonDatum;
    BisDatum := FBisDatum;
    if BisDatum > Now then
      BisDatum := Now;

    FAnlagenausfall := 0;
    FRuesten := 0;
    FLogistik := 0;
    FNichtGebucht := 0;
    FGeplant := 0;
    FUngeplant := 0;

    I := 0;
    try
      SQLStr := 'select count(*) cnt from TPM_STILLOG where MaschNr = ' + IntToStr(FMaschNr)
        + ' and'
        + ' AND StillstandNr = ' + IntToStr(Stillstandnr) + ' and'
        + ' (Kommt >= ''' + FloatToStr(VonDatum) + ''' and Kommt <= ''' + FloatToStr(BisDatum) + ''')';
      SQL_Get(qSuch, SQLStr);
      FStops := qSuch.FieldByName('cnt').AsInteger;
    except
      FStops := -1;
    end;

    SQLStr := 'select Kommt, Decode(Geht, ''0'', ''' + FloatToStr(Now) + ''', Geht) as Geht, Stillstandnr'
      + ' from TPM_STILLOG where MaschNr = ' + IntToStr(FMaschNr)
      + ' AND StillstandNr = ' + IntToStr(Stillstandnr) + ' and'
      + ' (Kommt <= ''' + FloatToStr(VonDatum) + ''''
      + ' and Decode(Geht, ''0'', ''' + FloatToStr(Now) + ''', Geht) >= ''' + FloatToStr(VonDatum) + ''''
      + ' or Kommt >= ''' + FloatToStr(VonDatum) + ''' and Kommt <= ''' + FloatToStr(BisDatum) + ''')'
      + ' order by Kommt';
    SQL_Get(qSuch, SQLStr);

    Dauer := 0;
    while not qSuch.EOF do
    begin
      Kommt := qSuch.FieldByName('Kommt').AsFloat;
      Geht := qSuch.FieldByName('Geht').AsFloat;

      if Geht = 0 then
        Geht := BisDatum;

      Stillstandnr := qSuch.FieldByName('Stillstandnr').AsInteger;
      if Kommt < VonDatum then
        Kommt := VonDatum;
      if Geht > BisDatum then
        Geht := BisDatum;
      StillIndex := GetStillIndex(Stillstandnr);
      Dauer := Dauer + Round((Geht - Kommt) * 1440);

      case Stillstand[StillIndex].Gruppe of
        0: FAnlagenausfall := FAnlagenausfall + Round((Geht - Kommt) * 1440);
        1: FRuesten := FRuesten + Round((Geht - Kommt) * 1440);
        2: FLogistik := FLogistik + Round((Geht - Kommt) * 1440);
        3: FNichtGebucht := FNichtGebucht + Round((Geht - Kommt) * 1440);
      end;
      if Stillstand[StillIndex].Geplant then
        FGeplant := FGeplant + Round((Geht - Kommt) * 1440)
      else
        FUngeplant := FUngeplant + Round((Geht - Kommt) * 1440);
      qSuch.Next;
      Inc(I);
    end;
    if FGeplant > fSchichtMinuten then
      FGeplant := fSchichtMinuten;
    if FUngeplant > fSchichtMinuten then
      FUngeplant := fSchichtMinuten;
    if FStops = -1 then
      FStops := I;
    FSollLaufzeit := Round((BisDatum - VonDatum) * 1440) - FGeplant;
    FIstLaufzeit := FSollLaufzeit - FUngeplant;
    if ((FIstLaufzeit = 0) or (FIstLaufzeit > fSchichtMinuten)) and (I > 1) then
    begin
      FIstLaufzeit := FSollLaufzeit - FUngeplant;
    end;

    Result := Dauer;
    {if F Schicht <> 0 then begin
          WerksKalenderSolllaufzeit:= GetWerksKalenderSolllaufzeit(Trunc(Bisdatum),F Schicht);
          if WerksKalenderSolllaufzeit < FSollLaufzeit then begin

            if Korrektur then begin

            end else begin
              FSollLaufzeit:= WerksKalenderSolllaufzeit;
              FIstlaufzeit := FSolllaufzeit - FUngeplant;
            end;

            if FIstlaufzeit < 0 then FIstlaufzeit:= 0;
          end;
        end;}

  end
  else
  begin
    SQLStr := 'Select Avg(Leistung) as DLeistung, Avg(Qualitaet) as DQualitaet,'
      + ' Sum(Solllaufzeit) as SumSollLaufzeit, Sum(Istlaufzeit) as SumIstLaufzeit,'
      + ' sum(Stops) as SumStops, Sum(Geplant) as SumGeplant, Sum(Ungeplant) as SumUngeplant'
      + ', Sum(Anlagenausfall) As SumAnlagenausfall , Sum(Ruesten) as SumRuesten,'
      + ' Sum(Logistik) as SumLogistik, Sum(NichtGebucht) as SumNichtGebucht, Sum(Produziert) as Produziert '
      + ' from tpm_schicht'
      + ' where (DatumZeit between (' + FloatToStr_Punkt(FVonDatum) + ') and (' + FloatToStr_Punkt(FBisDatum + 1) + '))';
    if not FAlleMaschinen then
      SQLStr := SQLStr + ' and (maschnr = ''' + IntToStr(FMaschNr) + ''')';
    SQLStr := SQLStr + GetSQLSchichtTyp('');

    SQL_Get(qSuch, SQLStr);
    if not qSuch.EOF then
    begin
      FSollLaufzeit := qSuch.FieldByName('SumSollLaufzeit').AsInteger;
      FIstLaufzeit := qSuch.FieldByName('SumIstLaufzeit').AsInteger;

      if FSollLaufzeit = 0 then
        LaufzeitSoll := 1
      else
        LaufzeitSoll := FSollLaufzeit;

      FNutzung := FIstLaufzeit / LaufzeitSoll * 100;
      FLeistung := qSuch.FieldByName('DLeistung').AsFloat;
      FQualitaet := qSuch.FieldByName('DQualitaet').AsFloat;
      FEffektivitaet := (FNutzung / 100) * (FLeistung / 100) * FQualitaet;

      FAnlagenausfall := qSuch.FieldByName('SumAnlagenausfall').AsInteger;
      FRuesten := qSuch.FieldByName('SumRuesten').AsInteger;
      FLogistik := qSuch.FieldByName('SumLogistik').AsInteger;
      FNichtGebucht := qSuch.FieldByName('SumNichtGebucht').AsInteger;

      FGeplant := qSuch.FieldByName('SumGeplant').AsInteger;
      FUngeplant := qSuch.FieldByName('SumUngeplant').AsInteger;

      if FGeplant > fSchichtMinuten then
        FGeplant := fSchichtMinuten;
      if FUngeplant > fSchichtMinuten then
        FUngeplant := fSchichtMinuten;

      FStops := qSuch.FieldByName('SumStops').AsInteger;
      FProduziert := qSuch.FieldByName('Produziert').AsInteger;
    end
    else
    begin
      FNutzung := 0;
      FLeistung := 0;
      FQualitaet := 0;
      FEffektivitaet := 0;
      FSollLaufzeit := 0;
      FIstLaufzeit := 0;

      FAnlagenausfall := 0;
      FRuesten := 0;
      FLogistik := 0;
      FNichtGebucht := 0;

      FGeplant := 0;
      FUngeplant := 0;
      FStops := 0;

      FProduziert := 0;
    end;
  end;
  FIstStillstand := FGeplant + FUngeplant;
end;

function TCO_TPM.DoInit(force: boolean = True): integer;
 var
  s, SQLStr: string;
  I: Integer;
begin
  Result := -1;
  I := 0;
  Stillstand := nil;
  {$IFDEF INCL_MSADO}
    if force then
    begin
      qSuch.Database.Connected := true;
      qSuch.Database.Connected := false;
    end;
  {$ENDIF}
  SQLStr := 'Select Stillstandnr,Stillstand,Aktion,Gruppe,Geplant from tpm_stillstaende';
  try
    SQL_Get(qSuch, SQLStr);
  except on ex: Exception do
    begin
     s := ex.Message;
    end;
  end;
  {$IFDEF INCL_MSADO}
  if force then
    SQL_Get(qSuch, SQLStr);
  {$ENDIF}
  while not qSuch.EOF do
  begin
    SetLength(Stillstand, Length(Stillstand) + 1);
    Stillstand[I].Stillstandnr := qSuch.FieldByName('Stillstandnr').AsInteger;
    Stillstand[I].Bezeichnung := qSuch.FieldByName('Stillstand').AsString;
    Stillstand[I].Aktion := qSuch.FieldByName('Aktion').AsInteger;
    Stillstand[I].Gruppe := qSuch.FieldByName('Gruppe').AsInteger;
    Stillstand[I].Geplant := qSuch.FieldByName('Geplant').AsInteger = 1;

    Inc(I);
    qSuch.Next;
  end;
  qSuch.Close;
  SQLStr := 'Select Shift_Model from Setup';
  SQL_Get(qSuch, SQLStr);
  Shift_Model := qSuch.FieldByName('Shift_Model').AsInteger;
  if Shift_Model <> 2 then
    fSchichtMinuten := 480
  else
    fSchichtMinuten := 720;
  qSuch.Close;
end;

function TCO_TPM.Init: Integer;
begin
  Result := DoInit(true);
end;

function TCO_TPM.ReInit: Integer;
begin
  Result := DoInit(false);
end;

function TCO_TPM.GetStillIndex(Stillstandnr: Integer): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to Length(Stillstand) do
    if Stillstand[I].Stillstandnr = Stillstandnr then
      Result := I
end;

function TCO_TPM.GetList(LizSQL: string): Integer;
var
  S: string;
begin
  if (fOraSession <> nil) and (Query <> nil) then
  begin
    GetProductionStatistics(LizSQL);
    S := 'Select * from Produktionsstatistik';
    SQL_Get(Query, S);
  end;
  Result := 1;
end;

function TCO_TPM.GetProductionStatistics(aLizSQL: string): Integer;
var
  LizSQL, SQLStr, C1, C2: string; // Abgekürzte Namen für Cast1 und Cast2 -> casts für SQL Server
  Schicht1, Schicht2, Schicht3: Real;
begin

//  if AnsiPos('chine.Lizenz',aLizSQL) < 1 then
  if Pos('chine.Lizenz',aLizSQL) < 1 then
    LizSQL := StringReplace(aLizSQL,'Lizenz','maschine.Lizenz',[])
  else
    LizSQL := aLizSQL;

  SQLStr := 'SELECT schicht1, Schicht2, Schicht3 FROM setup WHERE nr=1';
  SQL_Get(qSuch, SQLStr);
  if not qSuch.IsEmpty then
  begin
    Schicht1 := qSuch.FieldByName('schicht1').AsInteger / 1440;
    Schicht2 := qSuch.FieldByName('schicht2').AsInteger / 1440;
    Schicht3 := qSuch.FieldByName('schicht3').AsInteger / 1440;
  end
  else
  begin
    Schicht1 := 0.25;
    Schicht2 := 0.5833;
    Schicht3 := 0.91667;
  end;

  case Schicht of
    1:
      begin
        FVonDatum := Trunc(FVonDatum) + Schicht1 - 1 / 86400;
        FBisDatum := Trunc(FVonDatum) + Schicht2 - 1 / 86400;

      end;
    2:
      begin
        FVonDatum := Trunc(FVonDatum) + Schicht2 - 1 / 86400;
        FBisDatum := Trunc(FVonDatum) + Schicht3 - 1 / 86400;

      end;
    3:
      begin
        FVonDatum := Trunc(FVonDatum) + Schicht3 - 1 / 86400;
        FBisDatum := Trunc(FVonDatum) + 1 + Schicht1 - 1 / 86400;

      end;
  else
    begin
      FVonDatum := Trunc(FVonDatum) + Schicht1 - 1 / 86400;
      FBisDatum := Trunc(FBisDatum) + 1 + Schicht1 - 1 / 86400;

    end;
  end;

  SQLStr := 'update tpm_schicht set leistung = NULL where leistung = 0'
    + ' AND (datumzeit between (' + FloatToStr_Punkt(FVonDatum) + ') and (' + FloatToStr_Punkt(FBisDatum) + '))';
  SQL_Insert(qSuch, SQLStr);

{$IFDEF INCL_MSADO}
  C1 := 'CAST (';
  C2 := ' AS FLOAT)';
{$ELSE}
  C1 := '';
  C2 := '';
{$ENDIF}

  //***************************************************************************
  //Änderung 30.04.04
  //Grund: Nutzungsberechnung für Arbeitsfrei Tage
  //Auslöser Eschenbach
  //***************************************************************************
  SQLStr := 'update tpm_schicht set tmp_istlaufzeit = istlaufzeit'
    + ' where (datumzeit between (' + FloatToStr_Punkt(FVonDatum) + ') and (' + FloatToStr_Punkt(FBisDatum) + '))';
  SQL_Insert(qSuch, SQLStr);

  SQLStr := 'update tpm_schicht set tmp_istlaufzeit = 1, TMP_STATISTIK = 1'
    + ' where istlaufzeit = 0 AND solllaufzeit = 0'
    + ' AND (datumzeit between (' + FloatToStr_Punkt(FVonDatum) + ') and (' + FloatToStr_Punkt(FBisDatum) + '))';
  SQL_Insert(qSuch, SQLStr);

  //***************************************************************************
  //Änderung 17.01.05 (Sascha)
  //Grund: Leistungsberechnung
  //***************************************************************************
  SQLStr := 'UPDATE tpm_schicht SET var_kavitaet = 1 WHERE (var_kavitaet=0 OR var_kavitaet IS NULL) AND '
  + '(datumzeit between (' + FloatToStr_Punkt(FVonDatum) + ') and (' + FloatToStr_Punkt(FBisDatum) + '))';
  SQL_Insert(qUpdate, SQLStr );
  SQLStr := 'update tpm_schicht set tmp_Sollaufzeit = Round((Produziert/Kavitaet*Solltakt/60) * VAR_KAVITAET )'
    + ' where (datumzeit between (' + FloatToStr_Punkt(FVonDatum) + ') and (' + FloatToStr_Punkt(FBisDatum) + '))';
  SQL_Insert(qSuch, SQLStr);
  //***************************************************************************

  if FSchicht = 0 then
  begin
    SQLStr := 'Create or replace view ProdTemp1 as select maschine.Lizenz, sum(tpm_schicht.produziert + CASE WHEN tpm_schichtkombi.produziert IS NULL THEN 0 ELSE tpm_schichtkombi.produziert END) as produziert,'
      + ' sum(tpm_schicht.Verpackt + CASE WHEN tpm_schichtkombi.Verpackt IS NULL THEN 0 ELSE tpm_schichtkombi.Verpackt END) as Verpackt222,'
      + ' (select Sum(Zugang - Abgang) from VerpacktProt'
      + ' where (VerpacktProt.eintragsDatum between (' + FloatToStr_Punkt(FVonDatum) + ') and (' + FloatToStr_Punkt(FBisDatum) + '))'
      + ' and (VerpacktProt.Maschine = Maschine.Lizenz)) Verpackt,'
      + ' ''' + CO_TPMGetL('Tag') + ''' as Schicht,'
      + ' ''' + CO_TPMGetL('Tag') + ''' as shift_typ,'
      + ' sum(tpm_schicht.Ausschuss+tpm_schicht.autoausschuss + CASE WHEN tpm_schichtkombi.ausschuss IS NULL THEN 0 ELSE tpm_schichtkombi.ausschuss + tpm_schichtkombi.autoausschuss END) as Ausschuss,'
//      + ' sum(tmp_Sollaufzeit) as Solllaufzeit2,'
      + ' CASE WHEN count(tpm_schichtkombi.nr) = 0 THEN SUM(tmp_Sollaufzeit) ELSE SUM(tmp_Sollaufzeit) / count(tpm_schichtkombi.nr) * count(distinct(tpm_schichtkombi.masterauftrag)) END  as Solllaufzeit2, '
      + ' Decode(Sign(sum(' + C1 + 'tpm_schicht.Produziert + CASE WHEN tpm_schichtkombi.produziert IS NULL THEN 0 ELSE tpm_schichtkombi.produziert END' + C2 + ') - sum(' + C1 + 'tpm_schicht.Ausschuss+tpm_schicht.autoausschuss + CASE WHEN tpm_schichtkombi.ausschuss IS NULL THEN 0 ELSE tpm_schichtkombi.ausschuss + tpm_schichtkombi.autoausschuss END' + C2 + ')), -1, 0,'
      + ' Round(((sum(' + C1 + 'tpm_schicht.Produziert + CASE WHEN tpm_schichtkombi.produziert IS NULL THEN 0 ELSE tpm_schichtkombi.produziert END' + C2 + ') - sum(' + C1 + 'tpm_schicht.Ausschuss+tpm_schicht.autoausschuss + CASE WHEN tpm_schichtkombi.ausschuss IS NULL THEN 0 ELSE tpm_schichtkombi.ausschuss + tpm_schichtkombi.autoausschuss END' + C2 + '))/ Decode(sum('
      + C1 + 'tpm_schicht.produziert + CASE WHEN tpm_schichtkombi.produziert IS NULL THEN 0 ELSE tpm_schichtkombi.produziert END' + C2 + '),0,1,sum('
      + C1 + 'tpm_schicht.produziert + CASE WHEN tpm_schichtkombi.produziert IS NULL THEN 0 ELSE tpm_schichtkombi.produziert END' + C2 + '))) * 100,2)) as Qualitaet222,'
      + ' Round((select Sum(Zugang - Abgang)+0.0 from VerpacktProt'
      + ' where (VerpacktProt.eintragsDatum between (' + FloatToStr_Punkt(FVonDatum) + ') and (' + FloatToStr_Punkt(FBisDatum) + '))'
      + ' and (VerpacktProt.Maschine = Maschine.Lizenz)) / Decode(sum(tpm_schicht.produziert + CASE WHEN tpm_schichtkombi.produziert IS NULL THEN 0 ELSE tpm_schichtkombi.produziert END)'
      + ', 0, 1, sum(tpm_schicht.produziert + CASE WHEN tpm_schichtkombi.produziert IS NULL THEN 0 ELSE tpm_schichtkombi.produziert END) + 0.0) * 100, 2) Qualitaet,'
      + ' Round((sum(' + C1 + 'istlaufzeit' + C2 + ') / Decode(sum(' + C1 + 'solllaufzeit' + C2 + '),0,1,sum(' + C1 + 'solllaufzeit' + C2 + ')))*avg(' + C1 +
      'Leistung_Schicht' + C2 + ')'
      + ' *((sum(' + C1 + 'tpm_schicht.Produziert + CASE WHEN tpm_schichtkombi.produziert IS NULL THEN 0 ELSE tpm_schichtkombi.produziert END' + C2 + ') - sum(' + C1 + 'tpm_schicht.Ausschuss+tpm_schicht.autoausschuss' + C2 + '))/ Decode(sum('
      + C1 + 'tpm_schicht.produziert + CASE WHEN tpm_schichtkombi.produziert IS NULL THEN 0 ELSE tpm_schichtkombi.produziert END' + C2 + '),0,1,sum(' + C1
      + 'tpm_schicht.produziert' + C2 + '))),2) as Effektivitaet,'
      + ' round(sum(' + C1 + 'ungeplant' + C2 + ') / Decode(sum(' + C1 + 'geplant+ungeplant' + C2 + '),0,1,sum(' + C1 + 'geplant+ungeplant' + C2 +
      '))*100,2) as ungeplant,'
      + ' round(sum(' + C1 + 'geplant' + C2 + ') / Decode(sum(' + C1 + 'geplant+ungeplant' + C2 + '),0,1,sum(' + C1 + 'geplant+ungeplant' + C2 +
      '))*100,2) as geplant,'
      + ' round(sum(' + C1 + 'NichtGebucht' + C2 + ') / Decode(sum(' + C1 + 'geplant+ungeplant' + C2 + '),0,1,sum(' + C1 + 'geplant+ungeplant' + C2 +
      '))*100,2) as NichtGebucht,'
      + ' round(sum(' + C1 + 'Anlagenausfall' + C2 + ') / Decode(sum(' + C1 + 'geplant+ungeplant' + C2 + '),0,1,sum(' + C1 + 'geplant+ungeplant' + C2 +
      '))*100,2) as Anlagenausfall,'
      + ' round(sum(' + C1 + 'Ruesten' + C2 + ') / Decode(sum(' + C1 + 'geplant+ungeplant' + C2 + '),0,1,sum(' + C1 + 'geplant+ungeplant' + C2 +
      '))*100,2) as Ruesten,'
      + ' round(sum(' + C1 + 'Logistik' + C2 + ') / Decode(sum(' + C1 + 'geplant+ungeplant' + C2 + '),0,1,sum(' + C1 + 'geplant+ungeplant' + C2 +
      '))*100,2) as Logistik'
      + ' from ' + Get_Daten_aus_Archiv('tpm_schicht', FVonDatum, True)
      + ' LEFT JOIN maschine ON maschine.maschnr = tpm_schicht.maschnr'
      + ' LEFT OUTER JOIN tpm_schichtkombi ON tpm_schichtkombi.maschnr = maschine.maschnr AND tpm_schicht.datumzeit = tpm_schichtkombi.datumzeit'
      + ' where (tpm_schicht.datumzeit between (' + FloatToStr_Punkt(FVonDatum) + ') and (' + FloatToStr_Punkt(FBisDatum) + '))'
      + LizSQL
      + ' group by maschine.lizenz';
    SQL_Insert(qSuch, SQLStr);

    SQLStr := 'create or Replace View ProdTemp2 as'
      + ' (select Schicht, maschine.Lizenz, Avg(' + C1 + 'geplant+ungeplant' + C2 + ') as gesamtstillstand,'
      + ' Round((max(' + C1 + 'istlaufzeit' + C2 + ') / Decode(max(' + C1 + 'solllaufzeit' + C2 + '),0,1,max(' + C1 + 'solllaufzeit' + C2 +
      '))) * 100,2) as Nutzung,'
      + ' Max(Stops) as Stops, Max(' + C1 + 'solllaufzeit' + C2 + ') as SollLaufZeit, Max(' + C1 + 'Istlaufzeit' + C2 + ') as Istlaufzeit,'
      + ' Sum(' + C1 + 'tmp_Sollaufzeit' + C2 + ') as Solllaufzeit2,'
      + ' Avg(Kavitaet) as Kavitaet, Sum(Produziert) as Produziert, Max(TPM_Schicht.Solltakt) as Solltakt'
      + ' from ' + Get_Daten_aus_Archiv('tpm_schicht', FVonDatum, True) + ', maschine'
      + ' where (maschine.maschnr = tpm_schicht.maschnr)'
      + ' and (datumzeit between (' + FloatToStr_Punkt(FVonDatum) + ') and (' + FloatToStr_Punkt(FBisDatum) + '))'
      + LizSQL
      + ' group by maschine.lizenz, Schicht, Datum)';
    SQL_Insert(qSuch, SQLStr);

    SQLStr := 'create or Replace View ProdTemp3 as '
      + ' (select maschine.Lizenz,'
      + ' Sum(gesamtstillstand) as gesamtstillstand,'
      + ' Sum(Solllaufzeit) as Solllaufzeit,'
      + ' Sum(Istlaufzeit) as Istlaufzeit,'
      + ' Round(avg(nutzung),2) as nutzung2,'
      + ' Round((Sum(' + C1 + 'istlaufzeit' + C2 + ') / Decode(Sum(' + C1 + 'solllaufzeit' + C2 + '),0, 1, Sum(' + C1 + 'solllaufzeit' + C2 +
      '))) * 100,2) as Nutzung,'
      + ' Sum(stops) as Stops,'
      + ' Round(Decode(Sum(' + C1 + 'Istlaufzeit' + C2 + '), 0, 0, Sum(' + C1 + 'Solllaufzeit2' + C2 + ')/Sum(' + C1 + 'istlaufzeit' + C2 +
      ')*100), 2) as Leistung3'
      + ' from ProdTemp2, Maschine'
      + ' where (maschine.Lizenz = ProdTemp2.Lizenz) and (maschine.MaschAktiv = 1)'
      + StringReplace(StringReplace(LizSQL, 'Lizenz', 'maschine.Lizenz', [rfReplaceAll, rfIgnoreCase]),'maschine.maschine.Lizenz','maschine.Lizenz',[rfReplaceAll, rfIgnoreCase])
      + ' group by maschine.lizenz)';
    SQL_Insert(qSuch, SQLStr);

    SQLStr := 'Create or Replace View Produktionsstatistik as'
      + ' (Select ProdTemp1.Lizenz, Produziert, Decode(Verpackt, null, 0, Verpackt) Verpackt,'
      + ' Ausschuss, Schicht, Shift_typ, Nutzung, Leistung3 as Leistung,'
      + ' Decode(Qualitaet, null, 0, Qualitaet) Qualitaet,'
      + ' Round(Decode((' + C1 + 'Nutzung * Leistung3 * Qualitaet' + C2 + ')/10000,NULL,0,(' + C1 + 'Nutzung * Leistung3 * Qualitaet' + C2 +
      ')/10000),2)'
      + ' as Effektivitaet,'
      + ' Stops, Gesamtstillstand, ungeplant, geplant, nichtgebucht, anlagenausfall, ruesten, logistik,'
      + ' Istlaufzeit, Solllaufzeit, Solllaufzeit2'
      + ' from ProdTemp1, ProdTemp3 where ProdTemp1.Lizenz = ProdTemp3.Lizenz)';
    SQL_Insert(qSuch, SQLStr);
  end
  else
  begin
      // Wird dieser Zweig noch verwendet? Hier fehlen verpackte aus Verpacktprot und jetzt auch die Schichtkombi Werte Len 16.01.12
        SQLStr := 'Create or replace view ProdTemp1 as select maschine.Lizenz, sum(tpm_schicht.produziert + CASE WHEN tpm_schichtkombi.produziert IS NULL THEN 0 ELSE tpm_schichtkombi.produziert END) as produziert,'
      + ' sum(tpm_schicht.Verpackt + CASE WHEN tpm_schichtkombi.Verpackt IS NULL THEN 0 ELSE tpm_schichtkombi.Verpackt END) as Verpackt222,'
      + ' (select Sum(Zugang - Abgang) from VerpacktProt'
      + ' where (VerpacktProt.eintragsDatum between (' + FloatToStr_Punkt(FVonDatum) + ') and (' + FloatToStr_Punkt(FBisDatum) + '))'
      + ' and (VerpacktProt.Maschine = Maschine.Lizenz)) Verpackt,'
{$IFDEF INCL_MSADO}
      + ' CAST(tpm_schicht.Schicht as varchar) as Schicht, tpm_schicht.Shift_Typ,'

{$ELSE}
      + ' To_char(tpm_schicht.Schicht) as Schicht, tpm_schicht.Shift_Typ,'
{$ENDIF}
      + ' sum(tpm_schicht.Ausschuss+tpm_schicht.autoausschuss + CASE WHEN tpm_schichtkombi.ausschuss IS NULL THEN 0 ELSE tpm_schichtkombi.ausschuss + tpm_schichtkombi.autoausschuss END) as Ausschuss,'
      + ' sum(tmp_Sollaufzeit) as Solllaufzeit2,'
      + ' Decode(Sign(sum(' + C1 + 'tpm_schicht.Produziert + CASE WHEN tpm_schichtkombi.produziert IS NULL THEN 0 ELSE tpm_schichtkombi.produziert END' + C2 + ') - sum(' + C1 + 'tpm_schicht.Ausschuss+tpm_schicht.autoausschuss + CASE WHEN tpm_schichtkombi.ausschuss IS NULL THEN 0 ELSE tpm_schichtkombi.ausschuss + tpm_schichtkombi.autoausschuss END' + C2 + ')), -1, 0,'
      + ' Round(((sum(' + C1 + 'tpm_schicht.Produziert + CASE WHEN tpm_schichtkombi.produziert IS NULL THEN 0 ELSE tpm_schichtkombi.produziert END' + C2 + ') - sum(' + C1 + 'tpm_schicht.Ausschuss+tpm_schicht.autoausschuss + CASE WHEN tpm_schichtkombi.ausschuss IS NULL THEN 0 ELSE tpm_schichtkombi.ausschuss + tpm_schichtkombi.autoausschuss END' + C2 + '))/ Decode(sum('
      + C1 + 'tpm_schicht.produziert + CASE WHEN tpm_schichtkombi.produziert IS NULL THEN 0 ELSE tpm_schichtkombi.produziert END' + C2 + '),0,1,sum('
      + C1 + 'tpm_schicht.produziert + CASE WHEN tpm_schichtkombi.produziert IS NULL THEN 0 ELSE tpm_schichtkombi.produziert END' + C2 + '))) * 100,2)) as Qualitaet222,'
      + ' Round((select Sum(Zugang - Abgang)+0.0 from VerpacktProt'
      + ' where (VerpacktProt.eintragsDatum between (' + FloatToStr_Punkt(FVonDatum) + ') and (' + FloatToStr_Punkt(FBisDatum) + '))'
      + ' and (VerpacktProt.Maschine = Maschine.Lizenz)) / Decode(sum(tpm_schicht.produziert + CASE WHEN tpm_schichtkombi.produziert IS NULL THEN 0 ELSE tpm_schichtkombi.produziert END)'
      + ', 0, 1, sum(tpm_schicht.produziert + CASE WHEN tpm_schichtkombi.produziert IS NULL THEN 0 ELSE tpm_schichtkombi.produziert END) + 0.0) * 100, 2) Qualitaet,'
      + ' Round((sum(' + C1 + 'istlaufzeit' + C2 + ') / Decode(sum(' + C1 + 'solllaufzeit' + C2 + '),0,1,sum(' + C1 + 'solllaufzeit' + C2 + ')))*avg(' + C1 +
      'Leistung_Schicht' + C2 + ')'
      + ' *((sum(' + C1 + 'tpm_schicht.Produziert + CASE WHEN tpm_schichtkombi.produziert IS NULL THEN 0 ELSE tpm_schichtkombi.produziert END' + C2 + ') - sum(' + C1 + 'tpm_schicht.Ausschuss+tpm_schicht.autoausschuss' + C2 + '))/ Decode(sum('
      + C1 + 'tpm_schicht.produziert + CASE WHEN tpm_schichtkombi.produziert IS NULL THEN 0 ELSE tpm_schichtkombi.produziert END' + C2 + '),0,1,sum(' + C1
      + 'tpm_schicht.produziert' + C2 + '))),2) as Effektivitaet,'
      + ' round(sum(' + C1 + 'ungeplant' + C2 + ') / Decode(sum(' + C1 + 'geplant+ungeplant' + C2 + '),0,1,sum(' + C1 + 'geplant+ungeplant' + C2 +
      '))*100,2) as ungeplant,'
      + ' round(sum(' + C1 + 'geplant' + C2 + ') / Decode(sum(' + C1 + 'geplant+ungeplant' + C2 + '),0,1,sum(' + C1 + 'geplant+ungeplant' + C2 +
      '))*100,2) as geplant,'
      + ' round(sum(' + C1 + 'NichtGebucht' + C2 + ') / Decode(sum(' + C1 + 'geplant+ungeplant' + C2 + '),0,1,sum(' + C1 + 'geplant+ungeplant' + C2 +
      '))*100,2) as NichtGebucht,'
      + ' round(sum(' + C1 + 'Anlagenausfall' + C2 + ') / Decode(sum(' + C1 + 'geplant+ungeplant' + C2 + '),0,1,sum(' + C1 + 'geplant+ungeplant' + C2 +
      '))*100,2) as Anlagenausfall,'
      + ' round(sum(' + C1 + 'Ruesten' + C2 + ') / Decode(sum(' + C1 + 'geplant+ungeplant' + C2 + '),0,1,sum(' + C1 + 'geplant+ungeplant' + C2 +
      '))*100,2) as Ruesten,'
      + ' round(sum(' + C1 + 'Logistik' + C2 + ') / Decode(sum(' + C1 + 'geplant+ungeplant' + C2 + '),0,1,sum(' + C1 + 'geplant+ungeplant' + C2 +
      '))*100,2) as Logistik'
      + ' from ' + Get_Daten_aus_Archiv('tpm_schicht', FVonDatum, True)
      + ' LEFT JOIN maschine ON maschine.maschnr = tpm_schicht.maschnr'
      + ' LEFT OUTER JOIN tpm_schichtkombi ON tpm_schichtkombi.maschnr = maschine.maschnr AND tpm_schicht.datumzeit = tpm_schichtkombi.datumzeit'
      + ' where (tpm_schicht.datumzeit between (' + FloatToStr_Punkt(FVonDatum) + ') and (' + FloatToStr_Punkt(FBisDatum) + '))'
      + LizSQL
        + GetSQLSchichtTyp('tpm_schicht')
        + ' group by maschine.lizenz, tpm_schicht.Schicht, tpm_schicht.Shift_Typ';
    SQL_Insert(qSuch, SQLStr);


    SQLStr := 'create or Replace View ProdTemp2 as'
      + ' (select Schicht, maschine.Lizenz, Avg(geplant+ungeplant) as gesamtstillstand,'
      + ' Max(Stops) as Stops, Max(solllaufzeit) as SollLaufZeit, Max(Istlaufzeit) as Istlaufzeit,'
      + ' Sum(tmp_Sollaufzeit) as Solllaufzeit2,'
      + ' Avg(Kavitaet) as Kavitaet, Sum(Produziert) as Produziert, Max(tpm_schicht.Solltakt) as Solltakt'
      + ' from ' + Get_Daten_aus_Archiv('tpm_schicht', FVonDatum, True) + ', maschine'
      + ' where (maschine.maschnr = tpm_schicht.maschnr)'
      + ' and (datumzeit between (' + FloatToStr_Punkt(FVonDatum) + ') and (' + FloatToStr_Punkt(FBisDatum) + '))'
      + GetSQLSchichtTyp('')
      + LizSQL
      + ' group by maschine.lizenz, Schicht, Datum)';
    SQL_Insert(qSuch, SQLStr);

    SQLStr := 'create or Replace View ProdTemp3 as '
      + ' (select maschine.Lizenz,'
      + ' Sum(gesamtstillstand) as gesamtstillstand,'
      + ' Sum(Solllaufzeit) as Solllaufzeit,'
      + ' Sum(Istlaufzeit) as Istlaufzeit,'
      + ' Round((Sum(' + C1 + 'istlaufzeit' + C2 + ') / Decode(Sum(' + C1 + 'solllaufzeit' + C2 + '),0, 1, Sum(' + C1 + 'solllaufzeit' + C2 +
      '))) * 100,2) as Nutzung,'
      + ' Sum(stops) as Stops,'
      + ' Round(Decode(Sum(' + C1 + 'Istlaufzeit' + C2 + '), 0, 0, Sum(' + C1 + 'Solllaufzeit2' + C2 + ')/Sum(' + C1 + 'istlaufzeit' + C2 +
      ')*100), 2) as Leistung'
      + ' from ProdTemp2, Maschine'
      + ' where (maschine.Lizenz = ProdTemp2.Lizenz) and (maschine.MaschAktiv = 1)'
      + LizSQL
      + ' group by maschine.lizenz)';
    SQL_Insert(qSuch, SQLStr);

    SQLStr := 'Create or Replace View Produktionsstatistik as'
      + ' (Select ProdTemp1.Lizenz, Produziert, Decode(Verpackt, null, 0, Verpackt) Verpackt,'
      + ' Ausschuss, Schicht, Shift_typ, Nutzung, Leistung,'
      + ' Decode(Qualitaet, null, 0, Qualitaet) Qualitaet,'
      + ' Round(Decode((' + C1 + 'Nutzung * Leistung * Qualitaet' + C2 + ')/10000, NULL ,0,(' + C1 + 'Nutzung * Leistung * Qualitaet' + C2 +
      ')/10000),2)'
      + ' as Effektivitaet,'
      + ' Stops, Gesamtstillstand, ungeplant, geplant, nichtgebucht, anlagenausfall, ruesten, logistik,'
      + ' Istlaufzeit, Solllaufzeit, Solllaufzeit2'
      + ' from ProdTemp1, ProdTemp3 where ProdTemp1.Lizenz = ProdTemp3.Lizenz)';

    SQL_Insert(qSuch, SQLStr);
  end;

  SQLStr := 'update tpm_schicht set leistung = 0 where leistung = NULL ';
  SQL_Insert(qSuch, SQLStr);

  Result := 1;
end;

function TCO_TPM.GetProductionStatisticsExtrusion(LizSQL: string): Integer;
var
  SQLStr: string;
begin
  FVonDatum := Trunc(FVonDatum) + Schicht1 / 1440;
  FBisDatum := Trunc(FBisDatum) + 1 + Schicht1 / 1440 - 1 / 86400;

  SQLStr := 'update TPM_Schicht set PRODUZIERT  = Round(FREI_INT_1 / STUECK_NACH_KILO)';
  SQL_Insert(qSuch, SQLStr);

  SQLStr := 'update tpm_schicht set leistung = NULL where leistung = 0'
    + ' AND (datumzeit between (' + FloatToStr_Punkt(FVonDatum) + ') and (' + FloatToStr_Punkt(FBisDatum) + '))';
  SQL_Insert(qSuch, SQLStr);

  if FSchicht = 0 then
  begin
    SQLStr := 'Create or replace view ProdTemp1 as select maschine.Lizenz,sum(produziert) as Stproduziert,sum(FREI_INT_1) as produziert,'
      + '''' + CO_TPMGetL('Tag') + ''' as Schicht,'
      + ' Round((sum(istlaufzeit) / Decode(sum(solllaufzeit),0,1,sum(solllaufzeit))) * 100,2) as Nutzung,'
      + ' Round(avg(Leistung_Schicht),2) as Leistung,'
      + ' Round(((sum(Produziert) - sum(Ausschuss))/ Decode(sum(produziert),0,1,sum(produziert))) * 100,2) as Qualitaet,'
      + ' Round((sum(istlaufzeit) / Decode(sum(solllaufzeit),0,1,sum(solllaufzeit)))*avg(Leistung)*((sum(Produziert) - sum(Ausschuss))/ Decode(sum(produziert),0,1,sum(produziert))),2) as Effektivitaet'
      + ' from tpm_schicht,maschine'
      + ' where (maschine.maschnr = tpm_schicht.maschnr)'
      + ' and (datumzeit between (' + FloatToStr_Punkt(FVonDatum) + ') and (' + FloatToStr_Punkt(FBisDatum) + '))'
      + LizSQL
      + ' group by maschine.lizenz';
    SQL_Insert(qSuch, SQLStr);

    SQLStr := 'create or Replace View ProdTemp2 as '
      + '(select Distinct(Schicht),maschine.Lizenz, '
      + 'avg(geplant+ungeplant) as gesamtstillstand, '
      + 'avg(Stops) as Stops, '
      + 'avg(istlaufzeit) as istlaufzeit, '
      + 'avg(solllaufzeit) as solllaufzeit, '
      + 'avg(ungeplant) as ungeplant, '
      + 'avg(geplant) as geplant, '
      + 'avg(NichtGebucht) as NichtGebucht, '
      + 'avg(Anlagenausfall) as Anlagenausfall, '
      + 'avg(Ruesten) as Ruesten, '
      + 'avg(Logistik) as Logistik '
      + ' from tpm_schicht,maschine '
      + 'where (maschine.maschnr = tpm_schicht.maschnr) '
      + 'and (datumzeit between (' + FloatToStr_Punkt(FVonDatum) + ') and (' + FloatToStr_Punkt(FBisDatum) + '))'
      + LizSQL + 'group by maschine.lizenz,Schicht,Datum,BetriebsauftragNr)';
    SQL_Insert(qSuch, SQLStr);

    SQLStr := 'create or Replace View ProdTemp3 as '
      + '(select maschine.Lizenz,sum(gesamtstillstand) as gesamtstillstand, sum(stops) as stops, '
      + ' sum(istlaufzeit) as istlaufzeit, '
      + ' sum(solllaufzeit) as solllaufzeit, '
      + ' sum(ungeplant) as ungeplant, '
      + ' sum(geplant) as geplant, '
      + ' sum(NichtGebucht) as NichtGebucht, '
      + ' sum(Anlagenausfall) as Anlagenausfall, '
      + ' sum(Ruesten) as Ruesten, '
      + ' sum(Logistik) as Logistik '

    + 'from ProdTemp2, Maschine '
      + 'where (maschine.Lizenz = ProdTemp2.Lizenz) ' + LizSQL
      + 'group by maschine.lizenz)';
    SQL_Insert(qSuch, SQLStr);

    SQLStr := 'Create or Replace View Produktionsstatistik as '
      + '(Select ProdTemp1.Lizenz,Produziert,StProduziert,Schicht,Nutzung,Decode(Leistung,NULL,0,Leistung) as Leistung, '
      //+'Qualitaet,Decode(Effektivitaet,NULL,0,Effektivitaet) as Effektivitaet,'
    + 'Qualitaet,Decode((Nutzung * Leistung * Qualitaet)/10000,NULL,0,(Nutzung * Leistung * Qualitaet)/10000) as Effektivitaet,'
      + 'Stops, '
      + 'istlaufzeit, '
      + 'solllaufzeit, '
      + 'Gesamtstillstand, '
      + 'ungeplant,geplant, nichtgebucht,anlagenausfall, ruesten,logistik '
      + 'from  ProdTemp1,ProdTemp3 where ProdTemp1.Lizenz = ProdTemp3.Lizenz)';
    SQL_Insert(qSuch, SQLStr);
  end
  else
  begin
    SQLStr := 'Create or replace view ProdTemp1 as select maschine.Lizenz,sum(produziert) as Stproduziert,sum(FREI_INT_1) as produziert,'
      + '''' + CO_TPMGetL('Tag') + ''' as Schicht,'
      + ' Round((sum(istlaufzeit) / Decode(sum(solllaufzeit),0,1,sum(solllaufzeit))) * 100,2) as Nutzung,'
      + ' Round(avg(Leistung_Schicht),2) as Leistung,'
      + ' Round(((sum(Produziert) - sum(Ausschuss))/ Decode(sum(produziert),0,1,sum(produziert))) * 100,2) as Qualitaet,'
      + ' Round((sum(istlaufzeit) / Decode(sum(solllaufzeit),0,1,sum(solllaufzeit)))*avg(Leistung)*((sum(Produziert) - sum(Ausschuss))/ Decode(sum(produziert),0,1,sum(produziert))),2) as Effektivitaet'
      + ' from tpm_schicht,maschine'
      + ' where (maschine.maschnr = tpm_schicht.maschnr)'
      + ' and (datumzeit between (' + FloatToStr_Punkt(FVonDatum) + ') and (' + FloatToStr_Punkt(FBisDatum) + '))'
      + GetSQLSchichtTyp('')
      + LizSQL
      + ' group by maschine.lizenz, Schicht';
    SQL_Insert(qSuch, SQLStr);

    SQLStr := 'create or Replace View ProdTemp2 as '
      + '(select Distinct(Schicht),maschine.Lizenz, '
      + 'avg(geplant+ungeplant) as gesamtstillstand, '
      + 'avg(Stops) as Stops, '

    + 'avg(istlaufzeit) as istlaufzeit, '
      + 'avg(solllaufzeit) as solllaufzeit, '
      + 'avg(ungeplant) as ungeplant, '
      + 'avg(geplant) as geplant, '
      + 'avg(NichtGebucht) as NichtGebucht, '
      + 'avg(Anlagenausfall) as Anlagenausfall, '
      + 'avg(Ruesten) as Ruesten, '
      + 'avg(Logistik) as Logistik '
      + ' from tpm_schicht,maschine '
      + ' where (maschine.maschnr = tpm_schicht.maschnr) '
      + ' and (datumzeit between (' + FloatToStr_Punkt(FVonDatum) + ') and (' + FloatToStr_Punkt(FBisDatum) + '))'
      + GetSQLSchichtTyp('')
      + LizSQL
      + 'group by maschine.lizenz,Schicht,Datum,BetriebsauftragNr)';
    SQL_Insert(qSuch, SQLStr);

    SQLStr := 'create or Replace View ProdTemp3 as '
      + '(select maschine.Lizenz,sum(gesamtstillstand) as gesamtstillstand, sum(stops) as stops, '
      + ' sum(istlaufzeit) as istlaufzeit, '
      + ' sum(solllaufzeit) as solllaufzeit, '
      + ' sum(ungeplant) as ungeplant, '
      + ' sum(geplant) as geplant, '
      + ' sum(NichtGebucht) as NichtGebucht, '
      + ' sum(Anlagenausfall) as Anlagenausfall, '
      + ' sum(Ruesten) as Ruesten, '
      + ' sum(Logistik) as Logistik '
      + 'from ProdTemp2, Maschine '
      + 'where (maschine.Lizenz = ProdTemp2.Lizenz) ' + LizSQL
      + 'group by maschine.lizenz)';
    SQL_Insert(qSuch, SQLStr);

    SQLStr := 'Create or Replace View Produktionsstatistik as '
      + '(Select ProdTemp1.Lizenz,Produziert,StProduziert,Schicht,Nutzung,Decode(Leistung,NULL,0,Leistung) as Leistung, '
      //+'Qualitaet,Decode(Effektivitaet,NULL,0,Effektivitaet) as Effektivitaet,'
    + 'Qualitaet,Decode((Nutzung * Leistung * Qualitaet)/10000,NULL,0,(Nutzung * Leistung * Qualitaet)/10000) as Effektivitaet,'
      + 'Stops, '
      + 'istlaufzeit, '
      + 'solllaufzeit, '
      + 'Gesamtstillstand, '
      + 'ungeplant,geplant, nichtgebucht,anlagenausfall, ruesten,logistik '
      + 'from  ProdTemp1,ProdTemp3 where ProdTemp1.Lizenz = ProdTemp3.Lizenz)';
    SQL_Insert(qSuch, SQLStr);
  end;

  SQLStr := 'update tpm_schicht set leistung = 0 where leistung = NULL ';
  SQL_Insert(qSuch, SQLStr);

  Result := 1;
end;

function TCO_TPM.GetProductionStatistics_613: Integer;
var
  SQLStr: string;
begin
  FVonDatum := Trunc(FVonDatum) + Schicht1 / 1440;
  FBisDatum := Trunc(FBisDatum) + 1 + Schicht1 / 1440 - 1 / 86400;

  SQLStr := 'update tpm_schicht set leistung = NULL where leistung = 0'
    + ' AND (datumzeit between (' + FloatToStr_Punkt(FVonDatum) + ') and (' + FloatToStr_Punkt(FBisDatum) + '))';
  SQL_Insert(qSuch, SQLStr);

  if FSchicht = 0 then
  begin // Tagebetrachtung
    SQLStr := 'Create or replace view ProdTemp1 as select maschine.Lizenz,sum(produziert) as produziert,''Tag'' as Schicht,'
      + ' Round((sum(istlaufzeit) / Decode(sum(solllaufzeit),0,1,sum(solllaufzeit))) * 100,2) as Nutzung,'
      + ' Round(avg(Leistung_Schicht),2) as Leistung,'
      + ' Round(((sum(Produziert) - sum(Ausschuss))/ Decode(sum(produziert),0,1,sum(produziert))) * 100,2) as Qualitaet,'
      + ' Round((sum(istlaufzeit) / Decode(sum(solllaufzeit),0,1,sum(solllaufzeit)))*avg(Leistung)*((sum(Produziert) - sum(Ausschuss))/ Decode(sum(produziert),0,1,sum(produziert))),2) as Effektivitaet,'
      + ' round(sum(ungeplant) / Decode(sum(geplant+ungeplant),0,1,sum(geplant+ungeplant))*100,2) as ungeplant,'
      + ' round(sum(geplant) / Decode(sum(geplant+ungeplant),0,1,sum(geplant+ungeplant))*100,2) as geplant,'
      + ' round(sum(NichtGebucht) / Decode(sum(geplant+ungeplant),0,1,sum(geplant+ungeplant))*100,2) as NichtGebucht,'
      + ' round(sum(Anlagenausfall) / Decode(sum(geplant+ungeplant),0,1,sum(geplant+ungeplant))*100,2) as Anlagenausfall,'
      + ' round(sum(Ruesten) / Decode(sum(geplant+ungeplant),0,1,sum(geplant+ungeplant))*100,2) as Ruesten,'
      + ' round(sum(Logistik) / Decode(sum(geplant+ungeplant),0,1,sum(geplant+ungeplant))*100,2) as Logistik'
      + ' from tpm_schicht,maschine'
      + ' where (maschine.maschnr = tpm_schicht.maschnr)'
      + ' and (datumzeit between (' + FloatToStr_Punkt(FVonDatum) + ') and (' + FloatToStr_Punkt(FBisDatum) + '))'
      + ' group by maschine.lizenz';
    SQL_Insert(qSuch, SQLStr);

    SQLStr := 'create or Replace View ProdTemp2 as '
      + '(select Distinct(Schicht),maschine.Lizenz, '
      + 'avg(geplant+ungeplant) as gesamtstillstand, '
      + 'avg(Stops) as Stops '
      + 'from tpm_schicht,maschine '
      + 'where (maschine.maschnr = tpm_schicht.maschnr) '
      + 'and (datumzeit between (' + FloatToStr_Punkt(FVonDatum) + ') and (' + FloatToStr_Punkt(FBisDatum) + ')) '
      + 'group by maschine.lizenz,Schicht,Datum,BetriebsauftragNr)';
    SQL_Insert(qSuch, SQLStr);

    SQLStr := 'create or Replace View ProdTemp3 as '
      + '(select maschine.Lizenz,sum(gesamtstillstand) as gesamtstillstand, sum(stops) as stops '
      + 'from ProdTemp2, Maschine '
      + 'where (maschine.Lizenz = ProdTemp2.Lizenz) '
      + 'group by maschine.lizenz)';
    SQL_Insert(qSuch, SQLStr);

    SQLStr := 'Create or Replace View Produktionsstatistik as '
      + '(Select ProdTemp1.Lizenz,Produziert,Schicht,Nutzung,Decode(Leistung,NULL,0,Leistung) as Leistung, '
      //+'Qualitaet,Decode(Effektivitaet,NULL,0,Effektivitaet) as Effektivitaet,'
    + 'Qualitaet,Decode((Nutzung * Leistung * Qualitaet)/10000,NULL,0,(Nutzung * Leistung * Qualitaet)/10000) as Effektivitaet,'
      + 'Stops, '
      + 'Gesamtstillstand, '
      + 'ungeplant,geplant, nichtgebucht,anlagenausfall, ruesten,logistik '
      + 'from  ProdTemp1,ProdTemp3 where ProdTemp1.Lizenz = ProdTemp3.Lizenz)';
    SQL_Insert(qSuch, SQLStr);
  end
  else
  begin
    SQLStr := 'Create or replace view ProdTemp1 as select maschine.Lizenz,sum(produziert) as produziert, '
{$IFDEF INCL_ORA}
    + ' To_char(Schicht) as Schicht,'
{$ELSE}
    + ' CAST(Schicht AS VARCHAR(25)) as Schicht,'
{$ENDIF}
    + ' Round((sum(istlaufzeit) / Decode(sum(solllaufzeit),0,1,sum(solllaufzeit))) * 100,2) as Nutzung,'
      + ' Round(avg(Leistung_Schicht),2) as Leistung,'
      + ' Round(((sum(Produziert) - sum(Ausschuss))/ Decode(sum(produziert),0,1,sum(produziert))) * 100,2) as Qualitaet,'
      + ' Round((sum(istlaufzeit) / Decode(sum(solllaufzeit),0,1,sum(solllaufzeit)))*avg(Leistung)*((sum(Produziert) - sum(Ausschuss))/ Decode(sum(produziert),0,1,sum(produziert))),2) as Effektivitaet,'
      + ' round(sum(ungeplant) / Decode(sum(geplant+ungeplant),0,1,sum(geplant+ungeplant))*100,2) as ungeplant,'
      + ' round(sum(geplant) / Decode(sum(geplant+ungeplant),0,1,sum(geplant+ungeplant))*100,2) as geplant,'
      + ' round(sum(NichtGebucht) / Decode(sum(geplant+ungeplant),0,1,sum(geplant+ungeplant))*100,2) as NichtGebucht,'
      + ' round(sum(Anlagenausfall) / Decode(sum(geplant+ungeplant),0,1,sum(geplant+ungeplant))*100,2) as Anlagenausfall,'
      + ' round(sum(Ruesten) / Decode(sum(geplant+ungeplant),0,1,sum(geplant+ungeplant))*100,2) as Ruesten,'
      + ' round(sum(Logistik) / Decode(sum(geplant+ungeplant),0,1,sum(geplant+ungeplant))*100,2) as Logistik'
      + ' from tpm_schicht,maschine'
      + ' where (maschine.maschnr = tpm_schicht.maschnr)'
      + ' and (datumzeit between (' + FloatToStr_Punkt(FVonDatum) + ') and (' + FloatToStr_Punkt(FBisDatum) + '))'
      + GetSQLSchichtTyp('')
      + ' group by maschine.lizenz, Schicht';
    SQL_Insert(qSuch, SQLStr);

    SQLStr := 'create or Replace View ProdTemp2 as '
      + '(select Distinct(Schicht),maschine.Lizenz, '
      + 'avg(geplant+ungeplant) as gesamtstillstand, '
      + 'avg(Stops) as Stops '
      + 'from tpm_schicht,maschine '
      + 'where (maschine.maschnr = tpm_schicht.maschnr) '
      + 'and (datumzeit between (' + FloatToStr_Punkt(FVonDatum) + ') and (' + FloatToStr_Punkt(FBisDatum) + '))'
      + GetSQLSchichtTyp('')
      + 'group by maschine.lizenz,Schicht,Datum,BetriebsauftragNr)';
    SQL_Insert(qSuch, SQLStr);

    SQLStr := 'create or Replace View ProdTemp3 as '
      + '(select maschine.Lizenz,sum(gesamtstillstand) as gesamtstillstand, sum(stops) as stops '
      + 'from ProdTemp2, Maschine '
      + 'where (maschine.Lizenz = ProdTemp2.Lizenz) '
      + 'group by maschine.lizenz)';
    SQL_Insert(qSuch, SQLStr);

    SQLStr := 'Create or Replace View Produktionsstatistik as '
      + '(Select ProdTemp1.Lizenz,Produziert,Schicht,Nutzung,Decode(Leistung,NULL,0,Leistung) as Leistung, '
      //+'Qualitaet,Decode(Effektivitaet,NULL,0,Effektivitaet) as Effektivitaet,'
    + 'Qualitaet,Decode((Nutzung * Leistung * Qualitaet)/10000,NULL,0,(Nutzung * Leistung * Qualitaet)/10000) as Effektivitaet,'
      + 'Stops, '
      + 'Gesamtstillstand, '
      + 'ungeplant,geplant, nichtgebucht,anlagenausfall, ruesten,logistik '
      + 'from  ProdTemp1,ProdTemp3 where ProdTemp1.Lizenz = ProdTemp3.Lizenz)';
    SQL_Insert(qSuch, SQLStr);
  end;

  SQLStr := 'update tpm_schicht set leistung = 0 where leistung = NULL ';
  SQL_Insert(qSuch, SQLStr);

  Result := 1;
end;

procedure TCO_TPM.performanceprepare(von, bis: double);
var
  SQLStr: string;
begin
  SQLStr := 'update tpm_schicht set leistung = NULL where leistung = 0'
    + ' AND (datumzeit between (' + FloatToStr_Punkt(von) + ') and (' + FloatToStr_Punkt(bis) + '))';
  SQL_Insert(qSuch, SQLStr);

  SQLStr := 'update tpm_schicht set tmp_Sollaufzeit = Round((Produziert/Kavitaet*Solltakt/60) * VAR_KAVITAET )'
    + ' where (datumzeit between (' + FloatToStr_Punkt(von) + ') and (' + FloatToStr_Punkt(bis) + '))';
  SQL_Insert(qSuch, SQLStr);
// alt
//  SQLStr := 'update tpm_schicht set tmp_Sollaufzeit = Round(Produziert/Kavitaet*Solltakt/60)'
//    + ' where (datumzeit between (' + FloatToStr_Punkt(von) + ') and (' + FloatToStr_Punkt(bis) + '))';
//  SQL_Insert(qSuch, SQLStr);
end;

function TCO_TPM.GetControllingStatistics(LizSQL: string): Integer;
var
  SQLStr: string;
  C1, C2: string; //Casts für MSSQL;
begin
  FVonDatum := Trunc(FVonDatum) + Schicht1 / 1440;
  FBisDatum := Trunc(FBisDatum) + 1 + Schicht1 / 1440 - 1 / 86400;

  performanceprepare(FVonDatum, FBisDatum);

  {$IFDEF INCL_MSADO}
    C1 := 'CAST (';
    C2 := ' AS FLOAT)';
  {$ELSE}
    C1 := '';
    C2 := '';
  {$ENDIF}

  SQLStr := 'Create or replace view contemp1 as select tpm_schicht.datum,sum(produziert) as produziert,'
    + '''' + CO_TPMGetL('Tag') + ''' as Schicht,'
    + ' sum(tmp_Sollaufzeit) as Solllaufzeit2,'
    + ' (sum(' + C1 + 'Produziert' + C2 + ') - sum(' + C1 + 'Ausschuss' + C2 + ') )verpackt,'
    + ' Round(((sum(' + C1 + 'Produziert' + C2 + ') - sum(' + C1 + 'Ausschuss' + C2 + '))/ Decode(sum(produziert),0,1,sum(produziert))) * 100,2) as Qualitaet,'
    + ' round(sum(ungeplant) / Decode(sum(geplant+ungeplant),0,1,sum(geplant+ungeplant))*100,2) as ungeplant,'
    + ' round(sum(geplant) / Decode(sum(geplant+ungeplant),0,1,sum(geplant+ungeplant))*100,2) as geplant,'
    + ' round(sum(NichtGebucht) / Decode(sum(geplant+ungeplant),0,1,sum(geplant+ungeplant))*100,2) as NichtGebucht,'
    + ' round(sum(Anlagenausfall) / Decode(sum(geplant+ungeplant),0,1,sum(geplant+ungeplant))*100,2) as Anlagenausfall,'
    + ' round(sum(Ruesten) / Decode(sum(geplant+ungeplant),0,1,sum(geplant+ungeplant))*100,2) as Ruesten,'
    + ' round(sum(Logistik) / Decode(sum(geplant+ungeplant),0,1,sum(geplant+ungeplant))*100,2) as Logistik'
    + ' from ' + Get_Daten_aus_Archiv('tpm_schicht', FVonDatum, true)
    + ' where (datumzeit between (' + FloatToStr_Punkt(FVonDatum) + ') and (' + FloatToStr_Punkt(FBisDatum) + '))'
    + LizSQL + GetSQLSchichtTyp('')
    + ' group by tpm_schicht.datum';
  SQL_Insert(qSuch, SQLStr);

  SQLStr := 'create or Replace View contemp2 as '
    + ' (select Max(Schicht) Schicht, Max(datum) Datum,'
    + ' Max(geplant) geplant, Max(ungeplant) ungeplant,'
    + ' Max(istlaufzeit) istlaufzeit, Max(solllaufzeit) solllaufzeit,'
    + ' Sum(tmp_Sollaufzeit) as Solllaufzeit2,'
    + ' Max(Stops) Stops'
    + ' from ' + Get_Daten_aus_Archiv('tpm_schicht', FVonDatum, true)
    + ' where (datumzeit between (' + FloatToStr_Punkt(FVonDatum) + ') and (' + FloatToStr_Punkt(FBisDatum) + '))'
    + LizSQL + GetSQLSchichtTyp('')
    + ' group by DatumZeit, MaschNr)';
  SQL_Insert(qSuch, SQLStr);

  SQLStr := 'create or Replace View contemp3 as'
    + ' (select datum, sum(Geplant+Ungeplant) as gesamtstillstand,'
    + '  sum(' + C1 + 'solllaufzeit' + C2 + ') solllz, sum(' + C1 + 'istlaufzeit' + C2 + ') istlz, Sum(' + C1 + 'Solllaufzeit2' + C2 + ') solllz2,'
    + ' Round((Sum(' + C1 + 'istlaufzeit' + C2 + ') / Decode(Sum(' + C1 + 'solllaufzeit' + C2+ '),0, 1, Sum(' + C1 + 'solllaufzeit' + C2 + '))) * 100,2) as Nutzung,'
    + ' Round(Decode(Sum(' + C1 + 'Istlaufzeit' + C2 + '), 0, 0, Sum(' + C1 + 'Solllaufzeit2' + C2 + ')/Sum(' + C1 + 'istlaufzeit' + C2 + ')*100), 2) as Leistung,'
    + ' sum(stops) as stops'
    + ' from contemp2'
    + ' group by datum)';

  SQL_Insert(qSuch, SQLStr);

  SQLStr := 'Create or Replace View ControllingView as '
    + '(Select contemp3.datum, Produziert, Schicht, Nutzung, Leistung, Qualitaet,'
    + ' istlz, solllz, solllz2, verpackt,'
    + ' Round(Decode((Nutzung * Leistung * Qualitaet)/10000,NULL,0,(Nutzung * Leistung * Qualitaet)/10000),2) as Effektivitaet,'
    + 'Stops, '
    + 'Gesamtstillstand, '
    + 'ungeplant,geplant, nichtgebucht,anlagenausfall, ruesten,logistik '
    + 'from  contemp1, contemp3 where contemp3.datum = contemp1.datum) ';
  SQL_Insert(qSuch, SQLStr);

  Result := 1;
  Exit;

  //****************************************************************************
  //** EINZELMASCHINE **********************************************************
  //****************************************************************************

  {
  SQLStr := 'Create or replace view contemp1 as select maschine.Lizenz,tpm_schicht.datum,sum(produziert) as produziert,'
    + '''' + CO_TPMGetL('Tag') + ''' as Schicht,'
    + ' sum(tmp_Sollaufzeit) as Solllaufzeit2,'
    + ' Round(((sum(Produziert) - sum(Ausschuss))/ Decode(sum(produziert),0,1,sum(produziert))) * 100,2) as Qualitaet,'
    + ' round(sum(ungeplant) / Decode(sum(geplant+ungeplant),0,1,sum(geplant+ungeplant))*100,2) as ungeplant,'
    + ' round(sum(geplant) / Decode(sum(geplant+ungeplant),0,1,sum(geplant+ungeplant))*100,2) as geplant,'
    + ' round(sum(NichtGebucht) / Decode(sum(geplant+ungeplant),0,1,sum(geplant+ungeplant))*100,2) as NichtGebucht,'
    + ' round(sum(Anlagenausfall) / Decode(sum(geplant+ungeplant),0,1,sum(geplant+ungeplant))*100,2) as Anlagenausfall,'
    + ' round(sum(Ruesten) / Decode(sum(geplant+ungeplant),0,1,sum(geplant+ungeplant))*100,2) as Ruesten,'
    + ' round(sum(Logistik) / Decode(sum(geplant+ungeplant),0,1,sum(geplant+ungeplant))*100,2) as Logistik'
    + ' from tpm_schicht,maschine'
    + ' where (maschine.maschnr = tpm_schicht.maschnr)'
    + ' and (datumzeit between (' + FloatToStr_Punkt(FVonDatum) + ') and (' + FloatToStr_Punkt(FBisDatum) + '))'
    + LizSQL + GetSQLSchichtTyp('')
    + ' group by maschine.lizenz, tpm_schicht.datum';
  SQL_Insert(qSuch, SQLStr);

  SQLStr := 'create or Replace View contemp2 as '
    + '(select Distinct(Schicht),maschine.Lizenz,datum, '
    + 'avg(geplant+ungeplant) as gesamtstillstand, '
    + ' Max(solllaufzeit) as SollLaufZeit, Max(Istlaufzeit) as Istlaufzeit,'
    + ' Sum(tmp_Sollaufzeit) as Solllaufzeit2,'
    + ' avg(Stops) as Stops'
    + ' from tpm_schicht,maschine '
    + ' where (maschine.maschnr = tpm_schicht.maschnr) '
    + ' and (datumzeit between (' + FloatToStr_Punkt(FVonDatum) + ') and (' + FloatToStr_Punkt(FBisDatum) + '))'
    + LizSQL + GetSQLSchichtTyp('')
    + ' group by maschine.lizenz,Schicht,Datum,BetriebsauftragNr)';
  SQL_Insert(qSuch, SQLStr);

  SQLStr := 'create or Replace View contemp3 as '
    + '(select maschine.Lizenz,datum, sum(gesamtstillstand) as gesamtstillstand,'
    + ' Round((Sum(istlaufzeit) / Decode(Sum(solllaufzeit),0, 1, Sum(solllaufzeit))) * 100,2) as Nutzung,'
    + ' Round(Decode(Sum(Istlaufzeit), 0, 0, Sum(Solllaufzeit2)/Sum(istlaufzeit)*100), 2) as Leistung,'
    + ' sum(stops) as stops '
    + 'from contemp2, Maschine '
    + 'where (maschine.Lizenz = contemp2.Lizenz) ' + LizSQL
    + 'group by maschine.lizenz,datum)';
  SQL_Insert(qSuch, SQLStr);

  SQLStr := 'Create or Replace View ControllingView as '
    + '(Select contemp1.Lizenz, contemp3.datum, Produziert, Schicht, Nutzung, Leistung, Qualitaet,'
    + ' Round(Decode((Nutzung * Leistung * Qualitaet)/10000,NULL,0,(Nutzung * Leistung * Qualitaet)/10000),2) as Effektivitaet,'
    + 'Stops, '
    + 'Gesamtstillstand, '
    + 'ungeplant,geplant, nichtgebucht,anlagenausfall, ruesten,logistik '
    + 'from  contemp1,contemp3 where contemp1.Lizenz = contemp3.Lizenz and contemp3.datum = contemp1.datum) ';
  SQL_Insert(qSuch, SQLStr);

  SQLStr := 'update tpm_schicht set leistung = 0 where leistung = NULL ';
  SQL_Insert(qSuch, SQLStr);

  Result := 1;    }
end;

function TCO_TPM.GetOrderStatistics(LizSQL: string): Integer;
var
  SQLStr: string;
  sqlfile: TStringList;
begin
  if FSchicht = 0 then
    SQLStr := 'create or replace view auftragsstatistik as select Maschine.Lizenz,'
      + ' tpm_schicht.betriebsauftragnr,'

    + ' aarchiv.auftragnr,'
      + ' aarchiv.Schwesterauftrag,'
{$IF INCLUDISDatabaseTyp <> 1}
      + ' substr(aarchiv.Bezeichnung,1,50) as Bezeichnung ,'
{$ELSE}
      + ' aarchiv.Bezeichnung ,'
{$IFEND}

    + ' Max(AArchiv.Etikett1) Etikett1, Max(AArchiv.Etikett2) Etikett2, Max(AArchiv.Etikett3) Etikett3,'
      + ' Max(AArchiv.Etikett4) Etikett4, Max(AArchiv.Etikett5) Etikett5, Max(AArchiv.Etikett6) Etikett6,'
      + ' Max(AArchiv.Etikett7) Etikett7, Max(AArchiv.Etikett8) Etikett8, Max(AArchiv.Etikett9) Etikett9,'

    + ' aarchiv.Sollvorgabeint as Sollvorgabe, Max(AArchiv.WerkzeugNr) WerkzeugNr, '
      + ' (aarchiv.TaktZeitSoll / 100) as TaktZeitSoll,'
      + ' Decode(aarchiv.taktzeitIst, 0,'
      + ' Decode((select Count(*) CNT from Taktzeiten where Taktzeiten.AuftragNr=tpm_schicht.betriebsauftragnr), 0, null,' // aenderung bei rüsten
    + ' (select Round(Avg(Taktzeit),2) from Taktzeiten where Taktzeiten.AuftragNr=tpm_schicht.betriebsauftragnr)),'
      + ' aarchiv.taktzeitIst/100) as taktzeitist,'

    + ' ((aarchiv.TaktZeitSoll - aarchiv.taktzeitIst) / 100) as cycletime_dev'
      + ' ,(((aarchiv.TaktZeitSoll -aarchiv.taktzeitIst) / Decode(aarchiv.TaktZeitSoll,0,1,aarchiv.TaktZeitSoll)) * 100) as cycletime_dev_pcnt'

    + ' , aarchiv.ruestzeitsoll/60 as ruestzeitsoll'

    + ' ,(aarchiv.ruestzeitsoll - sum(tpm_schicht.ruesten)) as setuptime_dev'
      + ' ,(((aarchiv.ruestzeitsoll -sum(tpm_schicht.ruesten)) / Decode(aarchiv.ruestzeitsoll,0,1,aarchiv.ruestzeitsoll)) * 100) as setuptime_dev_pcnt'

    + ' ,aarchiv.endestatusdatum as finished'

    + ' ,aarchiv.laufzeitsoll'
      + ' ,aarchiv.laufzeitist'

    + ' , (aarchiv.laufzeitsoll - aarchiv.laufzeitist) as runtime_dev'
      + ' , (((aarchiv.laufzeitsoll - aarchiv.laufzeitist) / Decode(aarchiv.laufzeitsoll,0,1,aarchiv.laufzeitsoll))*100) as runtime_dev_pcnt'

    + ' ,aarchiv.MATERIALVERBRAUCH,'
      + ' aarchiv.NAME,'
      + ' SUM(nshift.wcurr)  w_total, '
      + ' SUM(nshift.aircurr) air_total, '

    //    + ' aarchiv.StartDatumZeit as startdatum, '
    + ' (SELECT min(ersterstart) FROM ' + Get_Daten_aus_Archiv('LAUFZEITLOG', FVonDatum, True) + ' WHERE laufzeitlog.betriebsauftragnr = tpm_schicht.betriebsauftragnr) as startdatum, ' // Geändert. Auftragstart wird aus Laufzeitlog und nicht aus Archiv genommen Len. 23.11.09
    + ' aarchiv.EndDatumZeit as enddatumZeit,'

    + ' sum(tpm_schicht.ruesten)/60 as Ruestzeitist, '
      + ' sum(tpm_schicht.Produziert) as Produziert'
      + ' ,(sum(tpm_schicht.Produziert) / Decode(aarchiv.Sollvorgabeint,0,1,aarchiv.Sollvorgabeint) * 100) as produced_pcnt'
      + ' ,aarchiv.kavitaet as cavity'
      + ' ,aarchiv.kavitaet_soll as cavitystd'
      + ' ,aarchiv.ausschuss as scrap'
      + ' ,aarchiv.verpacktint as packed'
      + ' , pdestamm.gewicht as gewicht'
      + ' ,(aarchiv.verpacktint / Decode(sum(tpm_schicht.Produziert),0,1,sum(tpm_schicht.Produziert)) * 100) as packed_pcnt'
      + ' ,sum(Stops) as Stops'
      + ' from ' + Get_Daten_aus_Archiv('TPM_SCHICHT', FVonDatum, True)  (*'tpm_schicht'*)
      + ' join maschine on tpm_schicht.Maschnr = Maschine.Maschnr'
      + ' left join ' + Get_Daten_aus_Archiv('AARCHIV', FVonDatum, True) + (*' aarchiv *) ' on tpm_schicht.Betriebsauftragnr = aarchiv.Betriebsauftragnr '
      + ' left join (SELECT tpmshiftno, sum(w_curr) wcurr, sum(air_curr) aircurr FROM nrg_shift group by tpmshiftno) nshift on tpm_schicht.nr=nshift.tpmshiftno'
      + ' left join (SELECT auftragnr artikel, max(gewicht) gewicht FROM pdestamm group by auftragnr) pdestamm on pdestamm.artikel=aarchiv.auftragnr '
      + ' where (tpm_schicht.betriebsauftragnr is not null)'
      + ' and (datumzeit between (' + FloatToStr_Punkt(Trunc(FVonDatum)) + ') and (' + FloatToStr_Punkt(Trunc(FBisDatum + 1)) + '))'
      + LizSQL
      + ' group by maschine.Lizenz, tpm_schicht.betriebsauftragnr, aarchiv.auftragnr,'
      + ' schwesterauftrag, aarchiv.bezeichnung, sollvorgabeint,'
      + ' aarchiv.StartDatumZeit, aarchiv.EndDatumZeit,'
      + ' taktzeitsoll, taktzeitist, aarchiv.ruestzeitSoll, aarchiv.laufzeitsoll,'
      + ' aarchiv.laufzeitist, aarchiv.MATERIALVERBRAUCH, aarchiv.NAME,'
      + ' aarchiv.kavitaet, aarchiv.ausschuss,aarchiv.verpacktint,aarchiv.kavitaet_soll,'
      + ' aarchiv.endestatusdatum, pdestamm.gewicht'
  else

    SQLStr := 'create or replace view auftragsstatistik as select Maschine.Lizenz'
      + ' ,tpm_schicht.betriebsauftragnr'
      + ' ,aarchiv.auftragnr'
      + ' , tpm_schicht.datumzeit as actdate'
      + ' , aarchiv.Schwesterauftrag'
{$IF INCLUDISDatabaseTyp <> 1}
      + ', substr(aarchiv.Bezeichnung,1,50) as Bezeichnung '
{$ELSE}
      + ', aarchiv.Bezeichnung '
{$IFEND}
    + ' ,Max(AArchiv.Etikett1) Etikett1, Max(AArchiv.Etikett2) Etikett2, Max(AArchiv.Etikett3) Etikett3,'
      + ' Max(AArchiv.Etikett4) Etikett4, Max(AArchiv.Etikett5) Etikett5, Max(AArchiv.Etikett6) Etikett6,'
      + ' Max(AArchiv.Etikett7) Etikett7, Max(AArchiv.Etikett8) Etikett8, Max(AArchiv.Etikett9) Etikett9'

    + ' ,aarchiv.Sollvorgabeint as Sollvorgabe, Max(AArchiv.WerkzeugNr) WerkzeugNr'
      + ' ,(aarchiv.TaktZeitSoll / 100) as TaktZeitSoll,'
      + ' Decode(aarchiv.taktzeitIst, 0,'
      + ' Decode((select Count(*) CNT from Taktzeiten where Taktzeiten.AuftragNr=tpm_schicht.betriebsauftragnr), 0, -1,'
      + ' (select Round(Avg(Taktzeit),2) from Taktzeiten where Taktzeiten.AuftragNr=tpm_schicht.betriebsauftragnr)),'
      + ' aarchiv.taktzeitIst/100) as taktzeitist,'

    + ' ((aarchiv.TaktZeitSoll - aarchiv.taktzeitIst) / 100) as cycletime_dev'
      + ' ,(((aarchiv.TaktZeitSoll -aarchiv.taktzeitIst) / Decode(aarchiv.TaktZeitSoll,0,1,aarchiv.TaktZeitSoll)) * 100) as cycletime_dev_pcnt'

    + ' , aarchiv.ruestzeitsoll/60 as ruestzeitsoll'

    + ' ,(aarchiv.ruestzeitsoll - sum(tpm_schicht.ruesten)) as setuptime_dev'
      + ' ,(((aarchiv.ruestzeitsoll -sum(tpm_schicht.ruesten)) / Decode(aarchiv.ruestzeitsoll,0,1,aarchiv.ruestzeitsoll)) * 100) as setuptime_dev_pcnt'

    + ' ,aarchiv.endestatusdatum as finished'

    + ' ,aarchiv.laufzeitsoll'
      + ' ,aarchiv.laufzeitist'

    + ' ,(aarchiv.laufzeitsoll - aarchiv.laufzeitist) as runtime_dev'
      + ' ,(((aarchiv.laufzeitsoll - aarchiv.laufzeitist) / Decode(aarchiv.laufzeitsoll,0,1,aarchiv.laufzeitsoll))*100) as runtime_dev_pcnt'

    + ' ,aarchiv.MATERIALVERBRAUCH'
      + ' ,aarchiv.NAME,'

      + ' SUM(nshift.wcurr)  w_total, '
      + ' SUM(nshift.aircurr) air_total, '

//    + ' aarchiv.StartDatumZeit as startdatum, '
    + ' (SELECT min(ersterstart) FROM ' + Get_Daten_aus_Archiv('LAUFZEITLOG', FVonDatum, True) + '  WHERE laufzeitlog.betriebsauftragnr = tpm_schicht.betriebsauftragnr) as startdatum, ' // Geändert. Auftragstart wird aus Laufzeitlog und nicht aus Archiv genommen Len. 23.11.09
    + ' aarchiv.EndDatumZeit as enddatumZeit,'

    + ' Decode((select Count(*) CNT from RuestProt'
      + ' where RuestProt.betriebsauftragnr=tpm_schicht.betriebsauftragnr), 0, 0,'
      + ' (select Sum(Decode(RuestIst, null, 0, RuestIst/60)) from RuestProt'
      + ' where RuestProt.betriebsauftragnr=tpm_schicht.betriebsauftragnr)) as RuestZeitIst,'
      + ' sum(tpm_schicht.Produziert) as Produziert'
      + ' ,((sum(tpm_schicht.Produziert) / Decode(aarchiv.Sollvorgabeint,0,1,aarchiv.Sollvorgabeint)) * 100) as produced_pcnt'
      + ' ,aarchiv.kavitaet as cavity'
      + ' ,aarchiv.kavitaet_soll as cavitystd'
      + ' ,aarchiv.ausschuss as scrap'
      + ' ,aarchiv.verpacktint as packed'
      + ' , pdestamm.gewicht as gewicht'
      + ' ,((aarchiv.verpacktint / Decode(sum(tpm_schicht.Produziert),0,1,sum(tpm_schicht.Produziert))) * 100) as packed_pcnt'
      + ' ,sum(Stops) as Stops'
      + ' from ' + Get_Daten_aus_Archiv('TPM_SCHICHT', FVonDatum, True)  (*'tpm_schicht'*)
      + ' join maschine on tpm_schicht.Maschnr = Maschine.Maschnr'
      + ' left join (SELECT tpmshiftno, sum(w_curr) wcurr, sum(air_curr) aircurr FROM nrg_shift group by tpmshiftno) nshift on tpm_schicht.nr=nshift.tpmshiftno'
      + ' left join ' + Get_Daten_aus_Archiv('AARCHIV', FVonDatum, True) + (*' aarchiv *) ' on tpm_schicht.Betriebsauftragnr = aarchiv.Betriebsauftragnr'
      + ' left join (SELECT auftragnr artikel, max(gewicht) gewicht FROM pdestamm group by auftragnr) pdestamm on pdestamm.artikel=aarchiv.auftragnr '
      + ' where (tpm_schicht.betriebsauftragnr is not null)'
      + ' and (tpm_schicht.datumzeit between (' + FloatToStr_Punkt(Trunc(FVonDatum)) + ') and (' + FloatToStr_Punkt(Trunc(FBisDatum + 1)) + '))'
      + GetSQLSchichtTyp('Tpm_Schicht') + LizSQL
      + ' group by maschine.Lizenz, tpm_schicht.betriebsauftragnr, aarchiv.auftragnr,'
      + ' schwesterauftrag, aarchiv.bezeichnung, sollvorgabeint, '
      + ' aarchiv.StartDatumZeit, aarchiv.EndDatumZeit,'
      + ' taktzeitsoll, taktzeitist, aarchiv.ruestzeitSoll, aarchiv.laufzeitsoll,'
      + ' aarchiv.laufzeitist, aarchiv.MATERIALVERBRAUCH, aarchiv.NAME,'
      + ' tpm_schicht.datumzeit,aarchiv.endestatusdatum, aarchiv.kavitaet_soll,'
      + ' aarchiv.kavitaet, aarchiv.ausschuss,aarchiv.verpacktint, pdestamm.gewicht ';
   (*
  sqlfile := TStringList.Create;
  try
    sqlfile.Add(SQLStr);
    sqlfile.SaveToFile('d:\1\sqlfile.sql');
  finally
    sqlfile.Free;
  end;
     *)
  SQL_Insert(qSuch, SQLStr);

  Result := 1;
end;

function TCO_TPM.GetOrderStatisticsExtrusion(LizSQL: string): Integer;
var
  SQLStr: string;
begin
  if FSchicht = 0 then
    SQLStr := 'create or replace view auftragsstatistik as select Maschine.Lizenz,'
      + ' tpm_schicht.betriebsauftragnr,'
      + ' aarchiv.auftragnr,'
      + ' aarchiv.Schwesterauftrag,'
      + ' substr(aarchiv.Bezeichnung,1,50) as Bezeichnung ,'
      + ' aarchiv.Sollvorgabeint as Sollvorgabe,'
      + ' (aarchiv.TaktZeitSoll / 100) as TaktZeitSoll,'
      + ' aarchiv.taktzeitIst / 100 as taktzeitist,'
      + ' aarchiv.ruestzeitsoll,'
      + ' aarchiv.laufzeitsoll,'
      + ' aarchiv.laufzeitist,'

    + ' aarchiv.ISTAUSSTOSS,'
      + ' aarchiv.SOLLAUSSTOSS,'
      + ' sum(tpm_schicht.FREI_INT_1) as produziertKG,'

    + ' aarchiv.MATERIALVERBRAUCH,'
      + ' aarchiv.NAME,'
      + ' substr(enddatumstr,0,  instr(enddatumstr,'' /'',1,1) + instr(enddatumstr,'''
      + CO_TPMGetL('läuft') + ''',1,1)*5'
      + ' + instr(enddatumstr,'''
      + CO_TPMGetL('unterbrochen') + ''',1,1)*12 + instr(enddatumstr,'''
      + CO_TPMGetL('Rüsten') + ''',1,1)*6) As enddatumZeit,'
      + ' aarchiv.startdatum,'
      + ' sum(tpm_schicht.ruesten) as RuestZeitIst,'
      + ' sum(tpm_schicht.Produziert) as Produziert,'
      + ' sum(Stops) as Stops'
      + ' from tpm_schicht'
      + ' join maschine on tpm_schicht.Maschnr = Maschine.Maschnr'
      + ' left join aarchiv on tpm_schicht.Betriebsauftragnr = aarchiv.Betriebsauftragnr'
      + ' where (tpm_schicht.betriebsauftragnr is not null)'
      + ' and (datumzeit between (' + FloatToStr_Punkt(Trunc(FVonDatum)) + ') and (' + FloatToStr_Punkt(Trunc(FBisDatum + 1)) + '))'
      + LizSQL
      + ' group by maschine.Lizenz, tpm_schicht.betriebsauftragnr, auftragnr,'
      + ' schwesterauftrag, aarchiv.bezeichnung, sollvorgabeint,aarchiv.ISTAUSSTOSS,aarchiv.SOLLAUSSTOSS,'
      + ' taktzeitsoll, taktzeitist, aarchiv.ruestzeitSoll, aarchiv.laufzeitsoll,'
      + ' aarchiv.laufzeitist, aarchiv.MATERIALVERBRAUCH, aarchiv.NAME, aarchiv.enddatumStr, aarchiv.startdatum'
  else

    SQLStr := 'create or replace view auftragsstatistik as select Maschine.Lizenz'
      + ' ,tpm_schicht.betriebsauftragnr'
      + ' ,aarchiv.auftragnr'
      + ' , aarchiv.Schwesterauftrag'
      + ' , aarchiv.Bezeichnung'
      + ' ,aarchiv.Sollvorgabeint as Sollvorgabe'
      + ' ,(aarchiv.TaktZeitSoll / 100) as TaktZeitSoll'
      + ' ,aarchiv.taktzeitIst / 100 as taktzeitist'
      + ' ,aarchiv.ruestzeitsoll'
      + ' ,aarchiv.laufzeitsoll'
      + ' ,aarchiv.laufzeitist'
      + ' ,aarchiv.MATERIALVERBRAUCH'
      + ' ,aarchiv.NAME'
      + ' ,substr(enddatumstr,0,  instr(enddatumstr,'' /'',1,1)'
      + ' + instr(enddatumstr,'''
      + CO_TPMGetL('läuft') + ''',1,1)*5 + instr(enddatumstr,'''
      + CO_TPMGetL('unterbrochen') + ''',1,1)*12'
      + ' + instr(enddatumstr,'''
      + CO_TPMGetL('Rüsten') + ''',1,1)*6) As enddatumZeit'
      + ' ,aarchiv.startdatum'
      + ' ,sum(tpm_schicht.ruesten) as RuestZeitIst'
      + ' ,sum(tpm_schicht.Produziert) as Produziert'
      + ' ,sum(Stops) as Stops'
      + ' from tpm_schicht'
      + ' join maschine on tpm_schicht.Maschnr = Maschine.Maschnr'
      + ' left join aarchiv on tpm_schicht.Betriebsauftragnr = aarchiv.Betriebsauftragnr'
      + ' where (tpm_schicht.betriebsauftragnr is not null)'
      + ' and (datumzeit between (' + FloatToStr_Punkt(Trunc(FVonDatum)) + ') and (' + FloatToStr_Punkt(Trunc(FBisDatum + 1)) + '))'
      + GetSQLSchichtTyp('Tpm_Schicht')
      + LizSQL
      + ' group by maschine.Lizenz, tpm_schicht.betriebsauftragnr, auftragnr,'
      + ' schwesterauftrag, aarchiv.bezeichnung, sollvorgabeint, '
      + ' taktzeitsoll, taktzeitist, aarchiv.ruestzeitSoll, aarchiv.laufzeitsoll,'
      + ' aarchiv.laufzeitist, aarchiv.MATERIALVERBRAUCH, aarchiv.NAME, aarchiv.enddatumstr, aarchiv.startdatum';
  SQL_Insert(qSuch, SQLStr);
  Result := 1;
end;

function TCO_TPM.GetWerksKalenderSolllaufzeit(Datum: Real; Schi: Integer): Integer;
var
  SQLStr: string;
begin
  SQLStr := 'select * from kalender where DatumInt = ' + IntToStr(Trunc(Datum));
  SQL_Get(qSuch, SQLStr);

  case Schi of
    1: Result := qSuch.FieldByName('Schicht1').AsInteger;
    2: Result := qSuch.FieldByName('Schicht2').AsInteger;
    3: Result := qSuch.FieldByName('Schicht3').AsInteger;
  else
    Result := 0;
  end;
end;

procedure TCO_TPM.StillstandBuchen(Nr: Integer; Stillstand: string; BetriebsauftragNr: string = '');
var
  SQLStr, S, Lizenz, BANr, ANr, Bez: string;
  Stillstandnr, Werkzeug, SOllRuestZeit, StillNr: Integer;
  // MaschNr: Integer;
  Tmp: Integer;
  DauerAlt: Integer;
  ungeplantAlt: Integer;
  geplantAlt: Integer;
  ChangeGeplantUngeplant: Boolean;
  Reaktionszeit: Integer;

  KommtDatumZeit: TDateTime;
  GehtDatumZeit: TDateTime;
  tmpGruppe: Integer;
  tmpDauer: Integer;
  tmpSchicht: Integer;
  tmpMaschNr: Integer;
  tmpGeplant: Boolean;
  RuestGrund: Boolean;
  Nummer: Integer;
begin
  Stillstandnr := GetStillstandNr(Stillstand);

  if Stillstandnr = -1 then
    Exit;

  SQLStr := 'SELECT RuestGrund FROM setup WHERE nr = 1';
  SQL_Get(qSuch, SQLStr);
  RuestGrund := qSuch.FieldByName('RuestGrund').AsInteger = 1;

  SQLStr := 'select * from TPM_STILLOG, TPM_Stillstaende where TPM_STILLOG.StillstandNr = TPM_STILLSTAENDE.StillstandNr'
    + ' AND TPM_STILLOG.Nr = ' + IntToStr(Nr);
  SQL_Get(qSuch, SQLStr);

  StillNr := qSuch.FieldByName('StillstandNr').AsInteger;
  // MaschNr := qSuch.FieldByName('MaschNr').AsInteger;

  Reaktionszeit := qSuch.FieldByName('Reaktionszeit').AsInteger;

  KommtDatumZeit := qSuch.FieldByName('Kommt').AsFloat;
  GehtDatumZeit := qSuch.FieldByName('Geht').AsFloat;

  tmpGruppe := qSuch.FieldByName('Gruppe').AsInteger;
  tmpDauer := qSuch.FieldByName('Dauer').AsInteger;
  tmpSchicht := qSuch.FieldByName('Schicht').AsInteger;
  tmpMaschNr := qSuch.FieldByName('MaschNr').AsInteger;
  tmpGeplant := qSuch.FieldByName('Geplant').AsInteger = 1;

  if (StillNr <> 1) and (GehtDatumZeit = 0) and TCO_Setup.GetParamBool(qSuch2, 'MDE_Stillstand_beim_Buchen_splitten') then
  begin
    StillstandErzeugen(Nr, Stillstand);
    Exit;

    //    SQLStr := 'Update TPM_STILLOG set Geht = ''' + FloatToStr(Now) + ''' Where Nr = ''' + IntToStr(Nr) + '''';
    //    SQL_Insert(qUpdate, SQLStr);
    //
    //    SQLStr := 'select TPM_STILLOGId.NextVal CNT from Dual';
    //    SQL_Get(qSuch2, SQLStr);
    //    Nr := qSuch2.FieldByName('CNT').AsInteger;
    //
    //    SQLStr := 'insert into TPM_STILLOG (Nr, MaschNr, Kommt, Geht) values (' + IntToStr(Nr) + ','
    //      + ' ' + IntToStr(MaschNr) + ','
    //      + ' ''' + FloatToStr(Now) + ''','
    //      + ' 0)';
    //    SQL_Insert(qUpdate, SQLStr);
  end;

  SQLStr := 'Update TPM_STILLOG set'
    + ' StillstandNr = ''' + IntToStr(Stillstandnr) + ''','
    + ' Reaktionszeit = ''' + IntToStr(Reaktionszeit) + ''''
    + ' where Nr = ''' + IntToStr(Nr) + '''';
  SQL_Insert(qUpdate, SQLStr);

  SQLStr := 'INSERT INTO ERPEvents (Nr, BetriebsAuftragNr, Event, Datumzeit)'
    + ' values (ERPEventsId.NextVal,'
    + ' ''' + IntToStr(Nr) + ''','
    + ' ''Q'','
    + ' ''' + FloatToStr(Now) + ''')';
  SQL_Insert(qUpdate, SQLStr);

  if BetriebsauftragNr <> '' then
    if SQLGet(qSuch, 'AARchiv', 'BetriebsAuftragNr', BetriebsauftragNr, True) > 0 then
    begin
      ANr := qSuch.FieldByName('AuftragNr').AsString;
      Bez := qSuch.FieldByName('Bezeichnung').AsString;
      SQLStr := 'Update TPM_STILLOG set'
        + ' BetriebsAuftragNr = ''' + BetriebsauftragNr + ''','
        + ' AuftragNr = ''' + ANr + ''','
        + ' Bezeichnung = ''' + Bez + ''''
        + ' where Nr = ' + IntToStr(Nr);
      SQL_Insert(qUpdate, SQLStr);
    end;

  ChangeGeplantUngeplant := False;

  //************************************************
  //    TPM_SCHICHT umbuchen
  //************************************************
  DauerAlt := 0;
  if GehtDatumZeit > 0 then
  begin

    Tmp := GetStillstandGruppe(Stillstand);
    if (tmpGruppe <> Tmp) and (Tmp <> -1) then
    begin

      //Stillstandgruppe wurde geändert, also Protokoll umschreiben
      //Datensatz in TPM_Schicht ermitteln
      SQLStr := 'select * from TPM_SCHICHT where Datum = ''' + DateToStr(KommtDatumZeit)
        + ''' AND Schicht = ' + IntToStr(tmpSchicht) + ' AND MaschNr = ' + IntToStr(tmpMaschNr);
      SQLStr := 'select * from TPM_SCHICHT where TRUNC(Datumzeit) = ''' + IntToStr(Trunc(KommtDatumZeit))
        + ''' AND Schicht = ' + IntToStr(tmpSchicht) + ' AND MaschNr = ' + IntToStr(tmpMaschNr);
      SQL_Get(qSuch, SQLStr);
      if qSuch.EOF then
        Exit;
      Nummer := qSuch.FieldByName('Nr').AsInteger;

      //Zeiten des Stillstandes berechnen und anpassen
      case tmpGruppe of
        CANLAGENAUSFALL: DauerAlt := qSuch.FieldByName('ANLAGENAUSFALL').AsInteger;
        CRUESTEN: DauerAlt := qSuch.FieldByName('RUESTEN').AsInteger;
        CLOGISTIK: DauerAlt := qSuch.FieldByName('LOGISTIK').AsInteger;
        CNICHT_GEBUCHT: DauerAlt := qSuch.FieldByName('NICHTGEBUCHT').AsInteger;
      end;
      geplantAlt := qSuch.FieldByName('Geplant').AsInteger;
      ungeplantAlt := qSuch.FieldByName('UnGeplant').AsInteger;

      if IsStillstandGeplant(Stillstand) <> tmpGeplant then
      begin
        ChangeGeplantUngeplant := True;
        if tmpGeplant then
          geplantAlt := geplantAlt - tmpDauer
        else
          ungeplantAlt := ungeplantAlt - tmpDauer;
      end;

      //neue Stillstandszeit in TPM_Schicht schreiben
      DauerAlt := DauerAlt - tmpDauer;
      if DauerAlt < 1 then
        DauerAlt := 0;

      case tmpGruppe of
        CANLAGENAUSFALL: UpdateSQL(qUpdate, 'TPM_SCHICHT', 'ANLAGENAUSFALL', IntToStr(DauerAlt), 'Nr', IntToStr(Nummer));
        CRUESTEN: UpdateSQL(qUpdate, 'TPM_SCHICHT', 'RUESTEN', IntToStr(DauerAlt), 'Nr', IntToStr(Nummer));
        CLOGISTIK: UpdateSQL(qUpdate, 'TPM_SCHICHT', 'LOGISTIK', IntToStr(DauerAlt), 'Nr', IntToStr(Nummer));
        CNICHT_GEBUCHT: UpdateSQL(qUpdate, 'TPM_SCHICHT', 'NICHTGEBUCHT', IntToStr(DauerAlt), 'Nr', IntToStr(Nummer));
      end;

      if ChangeGeplantUngeplant then
        if tmpGeplant then
          UpdateSQL(qUpdate, 'TPM_SCHICHT', 'Geplant', IntToStr(geplantAlt), 'Nr', IntToStr(Nummer))
        else
          UpdateSQL(qUpdate, 'TPM_SCHICHT', 'UnGeplant', IntToStr(ungeplantAlt), 'Nr', IntToStr(Nummer));

      //Stillstand in neue Gruppe buchen
      case Tmp of
        CANLAGENAUSFALL: DauerAlt := qSuch.FieldByName('ANLAGENAUSFALL').AsInteger;
        CRUESTEN: DauerAlt := qSuch.FieldByName('RUESTEN').AsInteger;
        CLOGISTIK: DauerAlt := qSuch.FieldByName('LOGISTIK').AsInteger;
        CNICHT_GEBUCHT: DauerAlt := qSuch.FieldByName('NICHTGEBUCHT').AsInteger;
      end;
      geplantAlt := qSuch.FieldByName('Geplant').AsInteger;
      ungeplantAlt := qSuch.FieldByName('UnGeplant').AsInteger;

      if ChangeGeplantUngeplant then
        if tmpGeplant then
          ungeplantAlt := ungeplantAlt + tmpDauer
        else
          geplantAlt := geplantAlt + tmpDauer;

      //neue Stillstandszeit in TPM_Schicht schreiben
      DauerAlt := DauerAlt + tmpDauer;
      if DauerAlt > 0 then
      begin

        case Tmp of
          CANLAGENAUSFALL: UpdateSQL(qUpdate, 'TPM_SCHICHT', 'ANLAGENAUSFALL', IntToStr(DauerAlt), 'Nr', IntToStr(Nummer));
          CRUESTEN: UpdateSQL(qUpdate, 'TPM_SCHICHT', 'RUESTEN', IntToStr(DauerAlt), 'Nr', IntToStr(Nummer));
          CLOGISTIK: UpdateSQL(qUpdate, 'TPM_SCHICHT', 'LOGISTIK', IntToStr(DauerAlt), 'Nr', IntToStr(Nummer));
          CNICHT_GEBUCHT: UpdateSQL(qUpdate, 'TPM_SCHICHT', 'NICHTGEBUCHT', IntToStr(DauerAlt), 'Nr', IntToStr(Nummer));
        end;

        if ChangeGeplantUngeplant then
          if tmpGeplant then
            UpdateSQL(qUpdate, 'TPM_SCHICHT', 'UnGeplant', IntToStr(ungeplantAlt), 'Nr', IntToStr(Nummer))
          else
            UpdateSQL(qUpdate, 'TPM_SCHICHT', 'Geplant', IntToStr(geplantAlt), 'Nr', IntToStr(Nummer));
      end; //if DauerAlt > 0 then
    end; //if ((tmpGruppe <> tmp) AND (tmp <> -1))  then
  end; //if GehtDatumZeit > 0 then begin

  if RuestGrund then // Wenn Schalter Rüstgrund aktiviert ist
  begin
    if tmpGruppe = CRUESTEN then // Eintrag ins Ruestprotokoll machen
    begin
      S := 'SELECT lizenz FROM maschine WHERE maschnr = ''' + IntToStr(tmpMaschNr) + '''';
      qSuch2.SQL.Text := S;
      qSuch2.Open;
      if not qSuch2.IsEmpty then
      begin
        Lizenz := qSuch2.FieldByName('lizenz').AsString;
        S := 'SELECT * FROM ruestprot WHERE lizenz = ''' + Lizenz + ''''
          + ' AND ((RuestEnde = '''') OR (RuestEnde is null) OR (RuestEnde = ''0''))';
        qSuch2.SQL.Text := S;
        qSuch2.Open;
        if qSuch2.IsEmpty then // Wenn kein offener Stillstand dann Rueststillstand einfügen
        begin
          S := 'SELECT * FROM pde WHERE lizenz = ''' + Lizenz + ''' AND stat = 0';
          qSuch2.SQL.Text := S;
          qSuch2.Open;
          if not qSuch2.IsEmpty then

          begin
            BANr := qSuch2.FieldByName('Betriebsauftragnr').AsString;
            Werkzeug := qSuch2.FieldByName('Werkzeug').AsInteger;
            SollRuestzeit := Format_String(qSuch2.FieldByName('Ruestzeit').AsString);
          end
          else
          begin
            S := 'select * from aarchiv where MASCHINE = ''' + Lizenz +
              ''' and Nr = (select MAX(NR) from aarchiv where MASCHINE = ''' + Lizenz +
              ''')';
            qSuch2.SQL.Text := S;
            qSuch2.Open;
            BANr := qSuch2.FieldByName('Betriebsauftragnr').AsString;
            Werkzeug := qSuch2.FieldByName('Werkzeug').AsInteger;
            SollRuestzeit := Format_String(qSuch2.FieldByName('RuestzeitSOLL').AsString);
          end;

          S := 'Insert into RuestProt'
            + ' (Nr, BetriebsAuftragNr,Name , RuestStart,RuestEnde, RuestIst, Grund,'
            + ' RuestSoll, Lizenz, Werkzeug)'
            + ' values (RuestProtId.NextVal,'
            + '''' + BANr + ''','
            + ''''','
            + '''' + FloatToStr(KommtDatumZeit) + ''','
            + '''' + FloatToStr(GehtDatumZeit) + ''','
            + '''' + IntToStr(DauerAlt) + ''','
            + '''' + IntToStr(Stillstandnr) + ''','
            + '''' + IntToStr(SollRuestzeit) + ''','
            + '''' + Lizenz + ''','
            + '''' + IntToStr(Werkzeug) + ''''
            + ')';
          try
            SQL_Insert(qUpdate, S);
          except
          end;
        end
        else // Offener Ruesteintrag
        begin
          Nr := qSuch2.FieldByName('Nr').AsInteger;
          S := 'UPDATE RuestProt SET grund = ''' + IntToStr(Stillstandnr)
            + ''' WHERE Nr = ''' + IntToStr(Nr) + '''';
          SQL_Insert(qUpdate, S);
        end;
      end;
    end;
  end;
end;

procedure TCO_TPM.StillstandErzeugen(Nr: Integer; Stillstand: string);
var
  SQLStr: string;
  Stillstandnr: Integer;
  Dauer: Integer;

  KommtDatumZeit: TDateTime;
  tmpSchicht: Integer;
  tmpMaschNr: Integer;
begin
  Stillstandnr := GetStillstandNr(Stillstand);

  if Stillstandnr = -1 then
    Exit;

  //Daten vom Stillstand speichern
  SQLStr := 'select * from TPM_STILLOG, TPM_Stillstaende'
    + ' where TPM_STILLOG.StillstandNr = TPM_STILLSTAENDE.StillstandNr AND TPM_STILLOG.Nr = ' + IntToStr(Nr);
  SQL_Get(qSuch, SQLStr);

  //Stillstand nicht gebucht
  if qSuch.FieldByName('Stillstandnr').AsInteger = 1 then
  begin
    StillstandBuchen(Nr, Stillstand, '');
    Exit;
  end;

  if qSuch.FieldByName('Geht').AsFloat > 0 then // Stillstand abgeschlossen
    Exit;

  if qSuch.FieldByName('Stillstandnr').AsInteger = 3 then // Arbeitsfrei Werksplanung nicht umbuchen
    if TCO_Setup.GetParamBool(qSuch2, 'MDE_Arbeitsfrei_nicht_umbuchen') then
      Exit; // 30.07.2004 Sascha für MPT

  KommtDatumZeit := qSuch.FieldByName('Kommt').AsFloat;

  tmpSchicht := qSuch.FieldByName('Schicht').AsInteger;
  tmpMaschNr := qSuch.FieldByName('MaschNr').AsInteger;

  Dauer := Trunc((Now - KommtDatumZeit) * 1440);
  if Dauer = 0 then
    Dauer := 1;

  UpdateSQL(qUpdate, 'tpm_Stillog', 'Geht', FloatToStr(Now), 'Nr', IntToStr(Nr));
  UpdateSQL(qUpdate, 'tpm_Stillog', 'GehtStr', DateTimeToStr(Now), 'Nr', IntToStr(Nr));
  UpdateSQL(qUpdate, 'tpm_Stillog', 'dauer', IntToStr(Dauer), 'Nr', IntToStr(Nr));

  //Neuen Stillstand erzeugen
  SQLStr := 'INSERT INTO TPM_Stillog (Nr,MaschNr,Schicht,Kommt,Geht,Stillstandnr,KommtStr)'
    + ' VALUES(TPM_StillogID.Nextval'
    + ',''' + IntToStr(tmpMaschNr)
    + ''',''' + IntToStr(tmpSchicht)
    + ''',''' + FloatToStr(Now)
    + ''',''' + '0'
    + ''',''' + IntToStr(Stillstandnr)
    + ''',''' + DateTimeToStr(Now)
    + ''')';
  SQL_Insert(qUpdate, SQLStr);
end;

function TCO_TPM.GetStillstandNr(Stillstand: string): Integer;
begin
  if SQLGetBool(qSuch2, 'TPM_STILLSTAENDE', 'Stillstand', Stillstand) then
    Result := qSuch2.FieldByName('StillstandNr').AsInteger
  else
    Result := -1;
end;

function TCO_TPM.GetStillstand(Stillstandnr: Integer): string;
begin
  if SQLGetBool(qSuch2, 'TPM_STILLSTAENDE', 'StillstandNr', IntToStr(Stillstandnr)) then
    Result := qSuch2.FieldByName('Stillstand').AsString
  else
    Result := '';
end;

function TCO_TPM.GetStillstandGruppe(Stillstand: string): Integer;
begin
  if SQLGetBool(qSuch2, 'TPM_STILLSTAENDE', 'Stillstand', Stillstand) then
    Result := qSuch2.FieldByName('Gruppe').AsInteger
  else
    Result := -1;
end;

function TCO_TPM.IsStillstandGeplant(Stillstand: string): Boolean;
begin
  Result := False;
  if SQLGetBool(qSuch2, 'TPM_STILLSTAENDE', 'Stillstand', Stillstand) then
    if qSuch2.FieldByName('Geplant').AsInteger = 1 then
      Result := True;
end;

procedure TCO_TPM.SQL_Insert(Query: TCO_Query; SQLStr: string);
begin
  Query.Close;
  Query.SQL.Clear;
  Query.SQL.Add(SQLStr);
  Query.ExecSQL;
  Query.Close;
end;

procedure TCO_TPM.UpdateSQL(Query: TCO_Query; Tabelle: string; UpdateFeld: string; UpdateWert: string;
  WhereFeld: string; WhereWert: string);
var
  SQLStr: string;
begin
  SQLStr := 'UPDATE ' + Tabelle + ' SET ' + UpdateFeld + '=''' + UpdateWert + ''' where ' + WhereFeld + '='''
    + WhereWert + '''';
  SQL_Insert(Query, SQLStr);
end;

function TCO_TPM.SQLGet(Query: TCO_Query; Tabelle: string; Feld: string; Wert: string; Ergebnis: Boolean): Integer;
var
  SQLStr: string;
begin
  if Ergebnis then
  begin
    SQLStr := 'Select COUNT(*) CNT from ' + Tabelle + ' where ' + Feld + '=''' + Wert + '''';
    SQL_Get(Query, SQLStr);
    Result := Query.FieldByName('CNT').AsInteger;
  end
  else
    Result := -1;

  SQLStr := 'Select * from ' + Tabelle + ' where ' + Feld + '=''' + Wert + '''';
  SQL_Get(Query, SQLStr);
end;

function TCO_TPM.SQLGetBool(Query: TCO_Query; Tabelle: string; Feld: string; Wert: string): Boolean;
var
  SQLStr: string;
begin
  SQLStr := 'Select * from ' + Tabelle + ' where ' + Feld + '=''' + Wert + '''';
  SQL_Get(Query, SQLStr);
  Result := not Query.IsEmpty;
end;

procedure TCO_TPM.SQL_Get(Query: TCO_Query; SQLStr: string);
var s : string;
begin
  Query.Close;
  try
    Query.SQL.Text := SQLStr;
  except on ex: Exception do
    begin
     s := ex.Message;
    end;
  end;
  Query.Open;
  Query.First;
end;

function TCO_TPM.GetProductionStatistics_Ext(LizSQL: string; Zeitraum, D1, D2: Integer): Integer;
var
  S, MSQL: string;
begin
  S := 'create or Replace view Produktionsstatistik_Ext1 as'
    + ' select Datum, Maschine, Schicht,'
    + ' Max(DatumZeit) as DatumZeit,'
    + ' Max(KW) as KW,'
    + ' Max(Monat) as Monat,'
    + ' Max(Cal_Group) as Cal_Group,'
    + ' Max(CAPACITY_SHIFT) as CAPACITY_SHIFT,'
    + ' Max(Solllaufzeit) as Solllaufzeit,'
    + ' Max(Stillstandszeit) as Stillstandszeit,'
    + ' Max(Nettolaufzeit) as Nettolaufzeit,'
    + ' Max(DOWNTIME_CAL) as DOWNTIME_CAL,'
    + ' Max(EFF_CAPACITY) as EFF_CAPACITY,'
    + ' Max(EFF_CAPACITY_PCNT) as EFF_CAPACITY_PCNT,'
    + ' Sum(PRODUZIERTE_MENGE) as PRODUZIERTE_MENGE,'
    + ' Sum(PACKED) as PACKED,'
    + ' Max(PACKED_PCNT) as PACKED_PCNT,'
    + ' Max(MACH_USETIME) as MACH_USETIME,'
    + ' Max(MACH_USETIME_PCNT) as MACH_USETIME_PCNT,'
    + ' Max(EFF_USE) as EFF_USE,'
    + ' Max(PERFORMANCE) as PERFORMANCE,'
    + ' Max(MACH_OEE) as MACH_OEE,'
    + ' Max(EFF_OEE) as EFF_OEE,'
    + ' Max(STOPS) as STOPS,'
    + ' Max(DOWNTIME_ALL) as DOWNTIME_ALL,'
    + ' Max(UNSCHED) as UNSCHED,'
    + ' Max(SCHEDULED) as SCHEDULED,'
    + ' Max(UNBOOKED) as UNBOOKED,'
    + ' Max(BREAKDOWN) as BREAKDOWN,'
    + ' Max(SETUPTIME) as SETUPTIME,'
    + ' Max(LOGISTICS) as LOGISTICS'
    + ' from TPM_Auswertung';

  case Zeitraum of
    -1, 0:
      S := S + ' where Trunc(DatumZeit) = ' + IntToStr(D1);
    1:
      S := S + ' where KW = ' + IntToStr(D1) + ' and Jahr = ' + IntToStr(D2);
    2:
      S := S + ' where Monat = ' + IntToStr(D1) + ' and Jahr = ' + IntToStr(D2);
    3:
      S := S + ' where Schicht = ' + IntToStr(D1) + ' and Trunc(DatumZeit) = ' + IntToStr(D2);
  end;

  S := S + LizSQL + ' group by Datum, Maschine, Schicht';
  SQL_Insert(qUpdate, S);

  MSQL := ' Maschine,'
    + ' Max(DatumZeit) as DatumZeit,'
    + ' Max(KW) as KW,'
    + ' Max(Monat) as Monat,'
    + ' Max(Cal_Group) as Cal_Group,'
    + ' Sum(CAPACITY_SHIFT) as CAPACITY_SHIFT,'
    + ' Sum(Solllaufzeit) as Solllaufzeit,'
    + ' Sum(Stillstandszeit) as Stillstandszeit,'
    + ' Sum(Nettolaufzeit) as Nettolaufzeit,'
    + ' Sum(DOWNTIME_CAL) as DOWNTIME_CAL,'
    + ' Sum(EFF_CAPACITY) as EFF_CAPACITY,'
    + ' Avg(EFF_CAPACITY_PCNT) as EFF_CAPACITY_PCNT,'
    + ' Sum(PRODUZIERTE_MENGE) as PRODUZIERTE_MENGE,'
    + ' Sum(PACKED) as PACKED,'
    + ' Avg(PACKED_PCNT) as PACKED_PCNT,'
    + ' Sum(MACH_USETIME) as MACH_USETIME,'
    + ' Avg(MACH_USETIME_PCNT) as MACH_USETIME_PCNT,'
    + ' Sum(EFF_USE) as EFF_USE,'
    + ' Avg(PERFORMANCE) as PERFORMANCE,'
    + ' Avg(MACH_OEE) as MACH_OEE,'
    + ' Avg(EFF_OEE) as EFF_OEE,'
    + ' Sum(STOPS) as STOPS,'
    + ' Sum(DOWNTIME_ALL) as DOWNTIME_ALL,'
    + ' Sum(UNSCHED) as UNSCHED,'
    + ' Sum(SCHEDULED) as SCHEDULED,'
    + ' Avg(UNBOOKED) as UNBOOKED,'
    + ' Avg(BREAKDOWN) as BREAKDOWN,'
    + ' Avg(SETUPTIME) as SETUPTIME,'
    + ' Avg(LOGISTICS) as LOGISTICS'
    + ' from Produktionsstatistik_Ext1';
  SQL_Insert(qUpdate, S);

  case Zeitraum of
    -1, 0:
      begin
        S := 'create or Replace view Produktionsstatistik_Ext as select Datum,' + MSQL
          + ' group by Datum, Maschine';
      end;
    1:
      begin
        S := 'create or Replace view Produktionsstatistik_Ext as select ''' + CO_TPMGetL('KW ')
          + '''|| KW as Datum,' + MSQL
          + ' group by KW, Maschine';
      end;
    2:
      begin
        S := 'create or Replace view Produktionsstatistik_Ext as select Monat as Datum,' + MSQL
          + ' group by Monat, Maschine';
      end;
    3:
      begin
        S := 'create or Replace view Produktionsstatistik_Ext as select Datum,' + MSQL
          + ' group by Schicht, Datum, Maschine';
      end;
  end;
  SQL_Insert(qUpdate, S);

  Result := 1;
end;

function TCO_TPM.GetSQLSchichtTyp(Tab: string): string;
begin
  if Tab <> '' then
    Tab := Tab + '.';
  if FShift_Typ = '' then
  begin
    if FSchicht = 0 then
      Result := ''
    else
      Result := ' and (' + Tab + 'Schicht = ''' + IntToStr(FSchicht) + ''')';
  end
  else
  begin
    if FShift_Typ = CO_TPMGetL('Tag') then
      Result := ''
    else
      Result := ' and (' + Tab + 'Shift_Typ = ''' + FShift_Typ + ''')';
  end;
end;

procedure TCO_TPM.SetShift_Typ(A: string);
begin
  if A <> '' then
    FSchicht := -1;
  FShift_Typ := A;
end;

procedure TCO_TPM.SetSchicht(A: Integer);
begin
  FShift_Typ := '';
  FSchicht := A;
end;

function TCO_TPM.Format_String(Wert: string): Integer;
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

function TCO_TPM.FloatToStr_Punkt(Value: Extended): string;
var
  S: string;
begin
  S := FloatToStr(Value);
  if Pos(',', S) > 0 then
    S[Pos(',', S)] := '.';
  Result := S;
end;

function TCO_TPM.Get_Daten_aus_Archiv(Table: string; Von: Real; AliasTabelle: Boolean): string;
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
    if INCLUDISDatabaseTyp = 0 then
      S := '(SELECT ''live'' sourcemandant, ' + S + ' FROM ' + Table
        + ' UNION SELECT ''archive'' sourcemandant, ' + S
        + ' FROM ' + fOraSession.UserName  + '_Arc.' + Table + ')'
    else
      S := '(SELECT ''live'' sourcemandant, ' + S + ' FROM ' + Table
        + ' UNION SELECT ''archive'' sourcemandant, ' + S
        + ' FROM ' + fOraSession.UserName  + '_Arc.dbo.' + Table + ')';
    if AliasTabelle then
      S := S + ' ' + Table;

    Result := S;
  end;
end;

procedure loggy(str : string; create : boolean = false);
var  f : TextFile;
    s : string;
begin
  Exit;
  s := 'C:\1\co_tpm_oee.log';
  AssignFile(f,s);
  if (not Fileexists(s)) and create then
    Append(f)
  else
    Rewrite(f);
  writeln(f,DateTimeToStr(Now) + ':'+str);
  CloseFile(F);

end;

function TCO_TPM.GetOEEStatistics(aLizSQL: string): Integer;
var
  S, S1, Liz, Nr, bLizSQL: string;
  A, Still, LZ_NO_JOB, V, MangelNr, Zyklen: Integer;
  R: Real;
begin
loggy('1');
  S := 'update TPM_Schicht set IstTakt = SollTakt where Produziert <> 0 and IstTakt = 0';
  SQL_Insert(qUpdate, S);
loggy('2');

  S := 'delete from ControllingOEE';
  SQL_Insert(qUpdate, S);

  MangelNr := TCO_Setup.GetParamInt(qSuch2, 'CTR_OEE_Auftragsmangel_SillstandNr');
  if MangelNr = 0 then
    if SQLGet(qSuch, 'TPM_Stillstaende', 'Stillstand', CO_TPMGetL('Auftragsmangel'), True) > 0 then
    begin
      MangelNr := qSuch.FieldByName('StillstandNr').AsInteger;
      S := 'update Setup_Par set Wert = ' + IntToStr(MangelNr)
        + ' where Schluessel = ''CTR_OEE_Auftragsmangel_SillstandNr''';
      SQL_Insert(qUpdate, S);
    end
    else
      MangelNr := 0;
loggy('3');

  GetProductionStatistics(aLizSQL);
loggy('4');
  if AnsiPos('chine.Lizenz',aLizSQL) < 1 then
    bLizSQL := StringReplace(aLizSQL,'Lizenz','maschine.Lizenz',[])
  else
    bLizSQL := aLizSQL;

  S := 'select * from Maschine, Produktionsstatistik'
    + ' where Maschine.Lizenz = Produktionsstatistik.Lizenz'
    + bLizSQL + ' AND maschine.maschaktiv = 1';
  SQL_Get(qSuch2, S);
  while not qSuch2.EOF do
  begin
    Nr := qSuch2.FieldByName('MaschNr').AsString;
    Liz := qSuch2.FieldByName('Lizenz').AsString;

    S := 'insert into ControllingOEE (Nr, Maschine) values (' + Nr + ', ''' + Liz + ''')';
    SQL_Insert(qUpdate, S);

    A := qSuch2.FieldByName('Solllaufzeit').AsInteger;

    S := 'update ControllingOEE set WERKSPL_KAP = ' + FloatToStr_Punkt(A) + ' where Nr = ' + Nr;
    SQL_Insert(qUpdate, S);
    if MangelNr > 0 then
    begin
      S1 := 'STILL_' + IntToStr(MangelNr);
      S := 'select Max(' + S1 + ') CNT from TPM_Auswertung where Maschine = ''' + Liz + ''''
        + ' and Datumzeit >= ' + FloatToStr_Punkt(VonDatum) + ' and DatumZeit < ' + FloatToStr_Punkt(BisDatum)
        + ' group by DatumZeit';
      S := 'select Sum(CNT) CNT2 from (' + S + ') Tab';
      SQL_Get(qSuch, S);
      try
        A := qSuch.FieldByName('CNT2').AsInteger;
      except
        A := 0;
      end;
      S := 'update ControllingOEE set AUFTRAGSMANGEL = ' + FloatToStr_Punkt(A) + ' where Nr = ' + Nr;
      SQL_Insert(qUpdate, S);
    end;

    S := 'update ControllingOEE set Avaibility = Round((' + FloatToStr_Punkt(qSuch2.FieldByName('Istlaufzeit').AsFloat)
      + ' + 0.0) / WERKSPL_KAP * 100, 1)'
      + ' where WERKSPL_KAP > 0 and Nr = ' + Nr;
    SQL_Insert(qUpdate, S);

    A := ZeitInMinuten(Liz, VonDatum, BisDatum);
    S := 'update ControllingOEE set Utilisation = Round((1 - AUFTRAGSMANGEL / ('
      + IntToStr(A) + ' + 0.0)) * 100, 1) where ' + IntToStr(A) + ' > 0 and Nr = ' + Nr;
    SQL_Insert(qUpdate, S);

    try
      S := 'select Sum(Zugang-Abgang) CNT'
        + ' FROM ' + Get_Daten_aus_Archiv('VerpacktProt', VonDatum, True)
        + ' WHERE Maschine = ''' + Liz + ''''
        + ' AND Datum >= ' + FloatToStr_Punkt(VonDatum)
        + ' AND Datum < ' + FloatToStr_Punkt(BisDatum);
      SQL_Get(qSuch, S);
      V := qSuch.FieldByName('CNT').AsInteger;
    except
      V := 0;
    end;

    try
      R := qSuch2.FieldByName('Produziert').AsInteger;
      if R <> 0 then
        R := (V / R) * 100;
    except
      R := 0;
    end;

    S :=
{$IF INCLUDISDatabaseTyp <> 1}
    'SELECT Round(SUM(LEAST(CASE geht WHEN 0 THEN '
      + ' To_Number(' + FloatToStr_Punkt(BisDatum) + ') '
      + ' ELSE geht END,' + FloatToStr_Punkt(BisDatum) + ')'
      + '-GREATEST(kommt, ' + FloatToStr_Punkt(VonDatum)
      + '))*1440) '
{$ELSE}
    'SELECT CONVERT(INTEGER,CAST(SUM(CASE WHEN CASE geht WHEN 0 THEN CAST('
      + FloatToStr_Punkt(BisDatum) + ' AS FLOAT) '
      + ' ELSE geht END > ' + FloatToStr_Punkt(BisDatum) + ' THEN '
      + FloatToStr_Punkt(BisDatum) + ' ELSE (CASE geht WHEN 0 THEN CAST('
      + FloatToStr_Punkt(BisDatum) + ' AS FLOAT) ELSE geht END) END'
      + '- CASE WHEN kommt > ' + FloatToStr_Punkt(VonDatum) +' THEN kommt ELSE ' + FloatToStr_Punkt(VonDatum)
      + ' END )*1440 AS FLOAT)) '
{$IFEND}
    + 'dauer,'
      + ' COUNT(*) stops FROM tpm_stillog'
      + ' WHERE MaschNr = ' + Nr + ' and kommt < ' + FloatToStr_Punkt(BisDatum)
      + ' AND (geht >= ' + FloatToStr_Punkt(VonDatum)
      + ' OR geht = 0)';

    try
      SQL_Get(qSuch, S);
      Still := qSuch.FieldByName('Dauer').AsInteger;
    except
      Still := 0;
    end;

    S := 'update ControllingOEE set TMP_KAL = '
      + FloatToStr(qSuch2.FieldByName('istlaufzeit').AsInteger
      + qSuch2.FieldByName('gesamtstillstand').AsInteger) + ' where Nr = ' + Nr;
    try
      SQL_Insert(qUpdate, S);
    except on e: exception do
        raise Exception.Create(e.Message  + ' ' + liz+ '@tmp_kal');
    end;
    S := 'select SUM(LZ_NO_JOB) CNT, SUM(zyklen) zyk from TPM_Produktionsdetail where Maschine = ''' + Liz + ''''
      + ' and DatumZeit >= ' + FloatToStr_Punkt(VonDatum) + ' and DatumZeit < ' + FloatToStr_Punkt(BisDatum);
    try
      SQL_Get(qSuch, S);
      LZ_NO_JOB := qSuch.FieldByName('CNT').AsInteger;
      Zyklen := qSuch.FieldByName('zyk').AsInteger;
    except
      LZ_NO_JOB := 0;
      Zyklen := 0;
    end;

    S := 'update ControllingOEE set'
      + ' Qualitaet = ' + FloatToStr_Punkt(RoundTo(R,-1)) + ','
      + ' Leistung = ' + FloatToStr_Punkt(RoundTo(qSuch2.FieldByName('Leistung').AsFloat,-1)) + ','
      + ' TMP_S = ''' + qSuch2.FieldByName('Solllaufzeit').AsString + ''','
      + ' TMP_S2 = ''' + qSuch2.FieldByName('Solllaufzeit2').AsString + ''','
      + ' TMP_I = ''' + qSuch2.FieldByName('Istlaufzeit').AsString + ''','
      + ' TMP_P = ''' + qSuch2.FieldByName('Produziert').AsString + ''','
      + ' TMP_V = ''' + IntToStr(V) + ''','
      + ' TMP_WS = ''' + IntToStr(A) + ''','
      + ' Still_Dauer = ''' + IntToStr(Still) + ''','
      + ' LZ_NO_JOB = ''' + IntToStr(LZ_NO_JOB) + ''','
      + ' Zyklen = ''' + IntToStr(Zyklen) + ''','
      + ' TMP_A = ''' + qSuch2.FieldByName('Ausschuss').AsString + ''''
      + ' where Nr = ' + Nr;
    try
      SQL_Insert(qUpdate, S);
    except on e: exception do
        raise Exception.Create(e.Message  + ' ' + liz+ '@tmp_kal:<br>' + S);
    end;
    SQL_Insert(qUpdate, S);

    if TCO_Setup.GetParamBool(qSuch, 'CTRL_ProduziertGleichGutMinusAusschuss') then
    begin
      try
        R := qSuch2.FieldByName('Ausschuss').AsInteger;
        if V <> 0 then
          R := ((V - R) / V) * 100
        else
          R := 0;
      except
        R := 0;
      end;

      S := 'update ControllingOEE set Qualitaet = ' + FloatToStr_Punkt(R) + ','
        + ' TMP_P = ''' + IntToStr(V - qSuch2.FieldByName('Ausschuss').AsInteger) + ''''
        + ' where Nr = ' + Nr;
      SQL_Insert(qUpdate, S);
    end;

    if TCO_Setup.GetParamBool(qSuch, 'CTRL_OEELeistung_mit_TE') then
    begin
      S := 'select Sum(SollTakt*Produziert) Soll3, Sum(IstTakt*Produziert) Ist3'
        + ' from TPM_Schicht'
        + ' where DatumZeit between (' + FloatToStr_Punkt(VonDatum) + ') and (' + FloatToStr_Punkt(BisDatum) + ') and MaschNr = ' + Nr;
      SQL_Get(qSuch, S);

      if qSuch.FieldByName('Ist3').AsFloat <> 0 then
        R := qSuch.FieldByName('Soll3').AsFloat / qSuch.FieldByName('Ist3').AsFloat * 100
      else
        R := 0;

      S := 'update ControllingOEE set'
        + ' Leistung = ' + FloatToStr_Punkt(R) + ','
        + ' TMP_Soll3 = ''' + qSuch.FieldByName('Soll3').AsString + ''','
        + ' TMP_Ist3 = ''' + qSuch.FieldByName('Ist3').AsString + ''''
        + ' where Nr = ' + Nr;
    end
    else
      S := 'update ControllingOEE set'
        + ' TMP_Soll3 = tmp_s2,'
        + ' TMP_Ist3 = tmp_i'
        + ' where Nr = ' + Nr;
    SQL_Insert(qUpdate, S);

    qSuch2.Next;
  end;

  S := 'update ControllingOEE set Ausschuss_Berech = TMP_P - TMP_V';
  SQL_Insert(qUpdate, S);

  S := 'update ControllingOEE set TMP_AV_PI = CASE WHEN TMP_WS > 0 THEN Round((TMP_I / TMP_WS)*100,1) ELSE 100 END';
  SQL_Insert(qUpdate, S);

  S := 'update ControllingOEE set TMP_OEE_PI = Round(Leistung /100 * Qualitaet /100 * TMP_AV_PI, 1)';
  SQL_Insert(qUpdate, S);

  S := 'update ControllingOEE set Effektivitaet = Round(Leistung /100 * Qualitaet /100 * Avaibility, 1)';
  SQL_Insert(qUpdate, S);

  S := 'select Count(*) CNT from ControllingOEE';
  SQL_Get(qSuch, S);

  A := Round((BisDatum - VonDatum) * 1440);
  Result := A * qSuch.FieldByName('CNT').AsInteger;
end;

procedure TCO_TPM.OEEDetail_Update(aLiz: string; DataSet: TDataSet);
var
  S: string;
begin
  // GetBetrachtungszeitraum;

  S := 'select '
{$IFDEF INCL_MSADO}
  + ' TOP 20000 '
{$ENDIF}
  + ' Max(TPM_Auswertung.DatumZeit) as DatumZeit, TPM_Auswertung.AuftragNr,'
    + ' Max(TPM_Auswertung.Maschine) Maschine, Max(AArchiv.AuftragNr) ArtikelNr,'
    + ' Max(AArchiv.Bezeichnung) Bezeichnung,'

  + ' Max(AARchiv.SollVorgabeInt) Produziert_Soll,'
    + ' Max(AARchiv.ProduziertINT) Produziert,'
    + ' Sum(Produziert_Soll) Produziert_Soll_BZ,'
    + ' Sum(Produzierte_Menge) Produziert_BZ,'

  // + ' case when Max(AArchiv.VerpacktInt) is null then 0 else Max(AArchiv.VerpacktInt) end Verpackt,'

  + ' (SELECT CASE WHEN SUM(Zugang-Abgang) IS NULL THEN 0'
  + '              ELSE SUM(zugang-abgang) END as CNT'
  + ' FROM ' + Get_Daten_aus_Archiv('VerpacktProt', 0, True)
  + ' WHERE BetriebsAuftragNr = TPM_Auswertung.AuftragNr'
  + ' AND VerpacktProt.Maschine = ''' + aLiz + ''') Verpackt,'

  + ' (SELECT CASE WHEN SUM(Zugang-Abgang) IS NULL THEN 0'
  + '              ELSE SUM(zugang-abgang) END AS CNT'
  + ' FROM ' + Get_Daten_aus_Archiv('VerpacktProt', VonDatum, True)
  + ' WHERE BetriebsAuftragNr = TPM_Auswertung.AuftragNr'
  + ' AND Datum >= ' + FloatToStr_Punkt(VonDatum)
  + ' AND Datum < ' + FloatToStr_Punkt(BisDatum)
  + ' AND VerpacktProt.Maschine = ''' + aLiz + ''') Verpackt_BZ,'

  + ' Max(AARchiv.Kavitaet_Soll) Kavitaet_Soll,'
    + ' Max(Kav_Ist) Kavitaet_Ist,'
    + ' Max(AARchiv.StartDatumZeit) StartDatum,'
    + ' Max(AARchiv.EndDatumZeit) EndeDatum,'
    + ' Max(AARchiv.EndeStatusDatum) AbschlussDatum,'
    + ' Max(AArchiv.LaufzeitSoll) LaufzeitSoll_Gesamt,'
    + ' Max(AArchiv.LaufzeitIst) LaufzeitIst_Gesamt,'
    + ' Sum(TPM_Auswertung.A_SollLaufzeit) LaufzeitSoll,'
    + ' Sum(TPM_Auswertung.A_IstLaufzeit) LaufzeitIst,'
    + ' CASE WHEN Sum(Produzierte_Menge) = 0 then 0 '
    + ' ELSE SUM(TPM_Auswertung.A_IstLaufzeit) / Sum(Produzierte_Menge) * 60 * Max(Kav_Ist) END TaktBZ,'
    + ' SUM( CASE WHEN Produzierte_Menge = 0 THEN 0 ELSE'
    + ' TPM_Auswertung.A_IstLaufzeit / Produzierte_Menge * 60 * Kav_Ist END) DurchschnittTakt_BZ,'
    + ' Max(AArchiv.Ausschuss) Ausschuss,'
    + ' Max(AArchiv.TaktzeitSoll)/100 Taktzeit_Soll,'
    + ' case when Max(AArchiv.TaktzeitIst) = 0 then  Avg(TPM_Auswertung.Taktzeit_Mittel_Ist) '
    + ' else Max(AArchiv.TaktzeitIst)/100 end Taktzeit_Ist,'

  + ' Max(AArchiv.RuestzeitSoll) RuestzeitSoll,'
    + ' Max(AArchiv.RuestzeitIst) RuestzeitIst,'
    + ' Max(AArchiv.Leistung) Leistung,'
    + ' Max(AArchiv.Nutzung) Nutzung,'
    + ' Max(AArchiv.Qualitaet) Qualitaet,'
    + ' Max(AArchiv.Effektivitaet) Effektivitaet'
    + ' from TPM_Auswertung, AARchiv'
    + ' where DatumZeit >= ' + FloatToStr_Punkt(VonDatum) + ' and DatumZeit < ' + FloatToStr_Punkt(BisDatum)
    + ' and not (TPM_Auswertung.AuftragNr is null)'
    + ' and AARchiv.BetriebsAuftragNr = TPM_Auswertung.AuftragNr'
    + ' and TPM_Auswertung.Maschine = ''' + aLiz + ''''
    + ' group By TPM_Auswertung.AuftragNr';

  try
    SQL_Insert(qUpdate, 'drop view TMP_OEE_Detail');
  except
  end;
  try
    SQL_Insert(qUpdate, 'drop table TMP_OEE_Detail');
  except
  end;

{$IFDEF INCL_MSADO}
  S := 'create view TMP_OEE_Detail as (' + S + ')';
{$ELSE}
  S := 'create table TMP_OEE_Detail as (' + S + ')';
  S := S + ' order by DatumZeit';
{$ENDIF}

  SQL_Insert(qUpdate, S);
end;

end.

