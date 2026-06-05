unit MainDLL;

interface

uses
  CO_DataBase, Forms, CO_Setup2;

type
  
  TMaschine = record
    MaschName: string;
    KalenderGruppe: Integer;
    KapazitaetsFaktor : double;
  end;

procedure BringFormToMiddle(Form: TForm);
procedure DateToKw(Datum: TDateTime; var KW, KWJahr: Word);
procedure KWToDate(KW, KWJahr: Word; var Datum: TDateTime);

procedure K_Init(Q: TCO_Query; days : Integer = 0);overload;
procedure K_Init(Q: TCO_Query; days_back, days_to : Integer);overload;
procedure EDPInit(Q: TCO_Query);
procedure KGruppe_Init(Q: TCO_Query);
procedure RefreshKGruppe(Q:TCO_Query);
function GetSchichtDauer(SchichtNR: Integer): Integer;
function GetSchichtDauer2(SchichtNR: Integer; GruppeNr : Integer): Integer;

function GetSchichtDauerDatum(KalGruppe: Integer; DT: TDateTime): Integer; overload;
function GetSchichtDauerDatum(DT: TDateTime): Integer; overload;

function GetSchichtStartString(KalGruppe: Integer; SchichtNR: Integer): string; overload;
function GetSchichtStartString(SchichtNR: Integer): string; overload;

function GetSchichtNr(KalGruppe: Integer; DT: TDateTime): Integer; overload;
function GetSchichtNr(DT: TDateTime): Integer; overload;
function GetSchichtNr(Lizenz: string; DT: TDateTime): Integer; overload;
function GetSchichtTyp(q: TCO_Query; MaschNr: Integer; D: Real; Schicht: Integer): string;

function GetSchichtStartFloat(KalGruppe: Integer; SchichtNR: Integer): Real; overload;
function GetSchichtStartFloat(SchichtNR: Integer): Real; overload;
function GetSchichtStartFloat(Lizenz: string; SchichtNR: Integer): Real; overload;
function GetSchichtStartInt2(KalGruppe : Integer; SchichtNR: Integer): Integer;

function GetFreeArbeitZeitproTag(Lizenz: string; DT: TDateTime; Sch: Integer): TDateTime;
function isMomentArbeitsFrei(KalGruppe: Integer; DT: TDateTime): Boolean;
function Arbeitsfrei(Lizenz: string; Datum: Real): Boolean;
function GetEndeDatumLizenz(Lizenz, AuftragsNr: string; StartDatum: Real; RestZeit_Min: Integer; aHalbautomatik: Boolean = False): Real;
function ZeitInMinuten(Lizenz: string; Datum1, Datum2: TDateTime; aHalbautomatik: Boolean = False): Integer;
function GetSDatum(Lizenz, AuftragsNr: string; EndeDatum: Real; Dauer_Min: Integer; aHalbautomatik: Boolean = False): Real;
function GetNextArbeitMoment(Lizenz: string; DT: TDateTime; aHalbautomatik: Boolean = False): TDateTime; overload;
function GetNextArbeitMoment(KalGruppe: Integer; DT: TDateTime; aHalbautomatik: Boolean = False): TDateTime; overload;
function GetPrevArbeitMoment(Lizenz: string; DT: TDateTime; aHalbautomatik: Boolean = False): TDateTime;

function GetPersonal(DT : TDateTime) : Integer;


function GetGruppe(Lizenz: string): Integer;
function GetGruppenMaschine(Lizenz: string): TMaschine;

const
  HALBAUTOMATIKMASCHINE = 'XX**HALB**XX'; // DUMMY für Halbautomatik Maschine

var
  HALBAUTOMATIKKALENDER: Integer;
  FLEXSCHICHT : Boolean;

implementation

uses
  SysUtils, DateUtils, Dialogs, Math;

const
  MinutenTakt = 5;
  Anzahl_Tage_Kalender = 1200; // 3 Jahre (letztes, laufendes, nächstes)
  MaxKalender = 16;     // 16 ist Standard !!! Änderung zum Test Len 15.10.2014

type
  TWerkskalender = record
    Tag: Integer;
    Schicht: array[1..3, 0..MaxKalender] of Smallint;
    SchichtEnde: array[0..MaxKalender] of Byte;
    Personal: array[1..3] of Integer;
  end;


var
  SchichtStart: array[1..3, 0..MaxKalender] of Real;
  ISchichtStart: array[1..3, 0..MaxKalender] of Integer;
  ISchichtStart2: array[1..3, 0..MaxKalender] of Integer;
  SDauer: array[1..3, 0..MaxKalender] of Integer;
  SDauer2: array[1..3, 0..MaxKalender] of Integer;


  Werkskalender: array[1..Anzahl_Tage_Kalender] of TWerkskalender;
  Maschine: array of TMaschine;
  EndeDatumPlus: Integer;
  Shift_Model: Integer;
  halbautomatik_berechnen: Boolean;
  withKapaFaktorProMaschine: Boolean;
  KGruppeInitInterval : Integer;
  LastKGruppeInit : TDateTime;

  // -----------------------------------------------------------------------------

procedure EDPInit(Q: TCO_Query);
begin
  Q.Close;
  Q.SQL.Text := 'Select EndeDatumPlus, Shift_Model, Halbautomatikkalender from Setup where nr =1';
  Q.Open;
  EndeDatumPlus := Q.FieldByName('EndeDatumPlus').AsInteger + 100;
  Shift_Model := Q.FieldByName('Shift_Model').AsInteger;

  HALBAUTOMATIKKALENDER := Q.FieldByName('Halbautomatikkalender').AsInteger;
  if HALBAUTOMATIKKALENDER = 0 then
    HALBAUTOMATIKKALENDER := 16;
end;

procedure K_Init(Q: TCO_Query; days : Integer = 0);
begin
  K_Init(Q, 0, days);
end;

procedure K_Init(Q: TCO_Query; days_back, days_to : Integer);
var
  T: TDateTime;
  Heute, Jetzt, start, ende, sstart, sende,dat, schicht: Integer;
  I, J, K, Gr, shiftoffset, shift: Integer;
  Year, Month, Day: Word;
  B: Boolean;
begin
  EDPInit(Q);

  Q.SQL.Text := 'Select GruppeNr, Schicht1, Schicht2, Schicht3 ';
  if FLEXSCHICHT then
    Q.SQL.Text := Q.SQL.Text  + ', startSchicht1, startSchicht2, startSchicht3 ';
  Q.SQL.Text := Q.SQL.Text  + ' from KalenderGruppe where gruppenr <= ' +IntToStr(MaxKalender)
   + ' order by GruppeNr';
  Q.Open;
  while not Q.EOF do
  begin
    for I := 1 to 3 do
    begin
      ISchichtStart[I, Q.FieldByName('GruppeNr').AsInteger] := Q.FieldByName('Schicht' + IntToStr(I)).AsInteger;
      if FLEXSCHICHT then
        ISchichtStart2[I, Q.FieldByName('GruppeNr').AsInteger] := Q.FieldByName('startSchicht' + IntToStr(I)).AsInteger;
    end;
    Q.Next;
  end;

  for I := 0 to MaxKalender do
  begin
    if Shift_Model <> 2 then
    begin
      SDauer[1, I] := Trunc(ISchichtStart[2, I] - ISchichtStart[1, I]);
      SDauer[2, I] := Trunc(ISchichtStart[3, I] - ISchichtStart[2, I]);
      SDauer[3, I] := Trunc(ISchichtStart[1, I] + 1440 - ISchichtStart[3, I]);
      SDauer2[1, I] := Trunc(ISchichtStart2[2, I] - ISchichtStart2[1, I]);
      SDauer2[2, I] := Trunc(ISchichtStart2[3, I] - ISchichtStart2[2, I]);
      SDauer2[3, I] := Trunc(ISchichtStart2[1, I] + 1440 - ISchichtStart2[3, I]);
    end
    else
    begin
      SDauer[1, I] := Trunc(ISchichtStart[2, I] - ISchichtStart[1, I]);
      SDauer[2, I] := Trunc(ISchichtStart[1, I] + 1440 - ISchichtStart[2, I]);
      SDauer[3, I] := 0;
    end;

    SchichtStart[1, I] := ISchichtStart[1, I] / 1440;
    SchichtStart[2, I] := ISchichtStart[2, I] / 1440;
    SchichtStart[3, I] := ISchichtStart[3, I] / 1440;
  end;

  DecodeDate(Date, Year, Month, Day);
  if (days_back =0) then
    T := EncodeDate(Year - 1, 1, 1)
  else
    T := Date - days_back;

  Heute := Trunc(T);

  Q.Close;
  if days_to > 0 then
  begin
    Q.SQL.Text := 'Select * from Kalender where DatumInt >= ' + IntToStr(Heute)
      +' AND datumint < ' + IntToStr(Trunc(Date) + days_to);
  end
  else
    Q.SQL.Text := 'Select * from Kalender where DatumInt >= ' + IntToStr(Heute);
  Q.SQL.Add(' order by DatumInt');
  Q.Open;
  B := False;
  I := 1;
  while (I <= Anzahl_Tage_Kalender) and (not Q.EOF) do
  begin
    Werkskalender[I].Tag := Q.FieldByName('DatumInt').AsInteger;
    Werkskalender[I].Schicht[1, 0] := Q.FieldByName('Schicht1').AsInteger;
    Werkskalender[I].Schicht[2, 0] := Q.FieldByName('Schicht2').AsInteger;
    Werkskalender[I].Schicht[3, 0] := Q.FieldByName('Schicht3').AsInteger;
    try
      Werkskalender[I].Personal[1] := Q.FieldByName('Personal_S1').AsInteger;
      Werkskalender[I].Personal[2] := Q.FieldByName('Personal_S2').AsInteger;
      Werkskalender[I].Personal[3] := Q.FieldByName('Personal_S3').AsInteger;
    except
    end;
    for J := 1 to MaxKalender do
    begin
      Werkskalender[I].Schicht[1, J] := Q.FieldByName('Gruppe' + IntToStr(J) + '_S1').AsInteger;
      Werkskalender[I].Schicht[2, J] := Q.FieldByName('Gruppe' + IntToStr(J) + '_S2').AsInteger;
      Werkskalender[I].Schicht[3, J] := Q.FieldByName('Gruppe' + IntToStr(J) + '_S3').AsInteger;
    end;
    for J := 0 to MaxKalender do
      Werkskalender[I].SchichtEnde[J] := Q.FieldByName('SchichtEnde_G' + IntToStr(J)).AsInteger;

    for J := 0 to MaxKalender do
      for K := 1 to 3 do
        if Werkskalender[I].Schicht[K, J] > SDauer[K, J] then
        begin
          Werkskalender[I].Schicht[K, J] := SDauer[K, J];
          B := True;
        end;

    Q.Next;
    Inc(I);
  end;

// Werkskalender[0] ist Heute. Und Heute ist aber Start vom Kalender und nicht der aktuelle Tag.
  Q.SQL.Text := 'SELECT kalenderfeiertage.startdate, kalenderfeiertage.enddate, kalenderfeiertage.startdateshift, '
        + ' kalenderfeiertage.enddateshift, kalendergruppe_feiertage.kalendergruppe_nr '
        + ' FROM kalenderfeiertage'
        + ' LEFT JOIN kalendergruppe_feiertage ON kalendergruppe_feiertage.kalenderfeiertage_nr=kalenderfeiertage.nr '
        + ' WHERE kalenderfeiertage.active=1 AND kalenderfeiertage.startdate >= ' + IntToStr(Heute);
  Q.Open;
  while not q.eof do
  begin
  	start := TRUNC(q.FieldByName('startdate').AsFloat);
	  ende := TRUNC(q.FieldByName('enddate').AsFloat);
  	sstart := q.FieldByName('startdateshift').AsInteger;
	  sende := q.FieldByName('enddateshift').AsInteger;
    if (start > Heute) and (ende < (heute+Anzahl_Tage_Kalender)) then
    begin
  	  if q.FieldByName('kalendergruppe_nr').AsInteger=0 then
  	  begin
	  	  for k := 0 to MaxKalender do
  	  	begin
	  	  	for dat := start+1 to ende+1 do
		  	  begin
  			  	if start = ende then
    				begin
	    				for schicht := sstart to sende do
		    				Werkskalender[dat-heute].Schicht[schicht, k] := 0;
			    	end
    				else
	    			begin
		    			if dat = start then
			    			for schicht := sstart to 3 do
				    			Werkskalender[dat-heute].Schicht[schicht, k] := 0
  				  	else if dat = ende then
	  				  	for schicht := 1 to sende do
		  				  	Werkskalender[dat-heute].Schicht[schicht, k] := 0
  			  		else
  				  		for schicht := 1 to 3 do
	  				  		Werkskalender[dat-heute].Schicht[schicht, k] := 0;
  	  			end;
	  	  	end;
  		  end;
    	end
  	  else
    	begin
  	  	k := q.FieldByName('kalendergruppe_nr').AsInteger;
	  	  for dat := start+1 to ende+1 do
  	  	begin
  	  		if start = ende then
	  	  	begin
		  	  	for schicht := sstart to sende do
  				  	Werkskalender[dat-heute].Schicht[schicht, k] := 0;
    			end
	    		else
  		  	begin
    				if dat = start then
	    				for schicht := sstart to 3 do
  		  				Werkskalender[dat-heute].Schicht[schicht, k] := 0
	  		  	else if dat = ende then
		  			for schicht := 1 to sende do
			  			Werkskalender[dat-heute].Schicht[schicht, k] := 0
  				else
	  				for schicht := 1 to 3 do
		  				Werkskalender[dat-heute].Schicht[schicht, k] := 0;
  		  	end;
  	  	end;
    	end;
    end;
    q.Next;
  end;
  
    
  if B then
  begin
    for I := 1 to 3 do
    begin
      Q.Close;
      Q.SQL.Text := 'Update Kalender Set Schicht' + IntToStr(I) + ' = ' + IntToStr(SDauer[I, 0])
        + ' where Schicht' + IntToStr(I) + ' > ' + IntToStr(SDauer[I, 0]);
      Q.ExecSQL;

      for J := 1 to MaxKalender do
      begin
        Q.Close;
        Q.SQL.Text := 'Update Kalender Set Gruppe' + IntToStr(J) + '_S' + IntToStr(I) + ' = ' + IntToStr(SDauer[I, J])
          + ' where Gruppe' + IntToStr(J) + '_S' + IntToStr(I) + ' > ' + IntToStr(SDauer[I, J]);
        Q.ExecSQL;
      end;
    end;
  end;

  Q.Close;
  KGruppe_init(q);
end;

procedure RefreshKGruppe(Q:TCO_Query);
begin
  if (LastKGruppeInit + (KGruppeInitInterval / 1440)) < Now then
    KGruppe_Init(Q);
end;

procedure KGruppe_Init(Q: TCO_Query);
var
  i, Gr,J : Integer;
  mm: TMaschine;

begin
  LastKGruppeInit := now;
  withKapaFaktorProMaschine := TCO_Setup.GetParamBool(Q, 'INCL_KapaFaktor_ProMaschine');

  SetLength(Maschine, 0);
  if withKapaFaktorProMaschine then
    Q.SQL.Text := 'SELECT Lizenz, werkskalendergruppe, kapafaktor FROM Maschine UNION'
                + ' SELECT Lizenz, werkskalendergruppe, kapafaktor FROM maschoffline ORDER BY Lizenz'
  else
    Q.SQL.Text := 'SELECT Lizenz, werkskalendergruppe FROM Maschine UNION'
                + ' SELECT Lizenz, werkskalendergruppe FROM maschoffline ORDER BY Lizenz';

  Q.Open;
  while not Q.EOF do
  begin
    I := Length(Maschine);
    SetLength(Maschine, I + 1);
    I := Length(Maschine);
    Maschine[I - 1].MaschName := Q.FieldByName('Lizenz').AsString;
    Gr := Q.FieldByName('WERKSKALENDERGRUPPE').AsInteger;
    if (Gr < 0) or (Gr > MaxKalender) then
      Gr := 0;
    Maschine[I - 1].KalenderGruppe := Gr;
    if (withKapaFaktorProMaschine) then
    begin
      Gr := Q.FieldByName('kapafaktor').AsInteger;
      if (Gr < 1) then
        Gr := 100;
      Maschine[I - 1].KapazitaetsFaktor := Gr / 100;
    end
    else
      Maschine[I - 1].KapazitaetsFaktor := 1;
    Q.Next;
  end;
     {
  Q.Close;
  Q.SQL.Text := 'Select Lizenz, werkskalendergruppe, kapafaktor from Maschoffline order by Lizenz';
  Q.Open;
  while not Q.EOF do
  begin
    SetLength(Maschine, Length(Maschine) + 1);
    Maschine[Length(Maschine) - 1].MaschName := Q.FieldByName('Lizenz').AsString;
    Gr := Q.FieldByName('WERKSKALENDERGRUPPE').AsInteger;
    if (Gr < 0) or (Gr > 16) then
      Gr := 0;
    Maschine[Length(Maschine) - 1].KalenderGruppe := Gr;
    if (withKapaFaktorProMaschine) then
    begin
      Gr := Q.FieldByName('kapafaktor').AsInteger;
      if (Gr < 1) then
        Gr := 100;
      Maschine[I - 1].KapazitaetsFaktor := Gr / 100;
    end
    else
      Maschine[I - 1].KapazitaetsFaktor := 1;    
    Q.Next;
  end;
               }
  //RS 11.12.2015: Sortierung hier noch einmal wichtig, da DB-Server anders als Delphi sortiert!
  for I := 1 to Length(Maschine) - 1 do
    for J := I to Length(Maschine) do
      if Maschine[I - 1].MaschName > Maschine[J - 1].MaschName then
      begin
        mm := Maschine[I - 1];
        Maschine[I - 1] := Maschine[J - 1];
        Maschine[J - 1] := mm;
      end;
  halbautomatik_berechnen := TCO_Setup.GetParamBool(Q, 'FP_Halbautomatikkalender');
  KGruppeInitInterval := TCO_Setup.GetParamInt(Q, 'INCL_KGruppeInitInterval');
end;
// -----------------------------------------------------------------------------

function GetSchichtNr(KalGruppe: Integer; DT: TDateTime): Integer;
var
  T: Extended;
  s1, s2, s3 : integer;
  fracked : integer;
begin
  if Shift_Model <> 2 then
  begin
    fracked := round((Frac(DT)*1440));
    s1 := round(SchichtStart[1, KalGruppe] * 1440);
    s2 := round(SchichtStart[2, KalGruppe] * 1440);
    s3 := round(SchichtStart[3, KalGruppe] * 1440);

    if (fracked < s1) or (fracked >= s3) then
      Result := 3
    else
      if fracked < s2 then
        Result := 1
      else
        Result := 2;
  end
  else
  begin
  if Shift_Model <> 2 then
  begin
    T := Frac(DT);
    if (T < SchichtStart[1, KalGruppe]) or (T >= SchichtStart[3, KalGruppe]) then
      Result := 3
    else
      if T < SchichtStart[2, KalGruppe] then
        Result := 1
      else
        Result := 2;
  end
  else
  begin
    T := Frac(DT);
    if (T < SchichtStart[1, KalGruppe]) or (T >= SchichtStart[2, KalGruppe]) then
      Result := 2
    else
      Result := 1;
  end;
  end;
end;

function GetSchichtNr(DT: TDateTime): Integer;
begin
  Result := GetSchichtNr(0, DT);
end;

function GetSchichtNr(Lizenz: string; DT: TDateTime): Integer; overload;
begin
  Result := GetSchichtNr(GetGruppe(Lizenz), DT);
end;
// -----------------------------------------------------------------------------
function GetSchichtTyp(q: TCO_Query; MaschNr: Integer; D: Real; Schicht: Integer): string;
var
  Gruppe: Integer;
//  D: Real;
  schichtnr : Integer;
begin
    q.SQL.Text := 'SELECT * FROM maschine WHERE maschnr = ' +IntToStr(MaschNr);
    q.open;
    if not q.IsEmpty then
    begin
      Gruppe := q.FieldByName('WERKSKALENDERGRUPPE').AsInteger;

      q.SQL.Text := 'SELECT * FROM kalender WHERE DatumInt = ' +IntToStr(Trunc(D));
      q.open;
      if not q.IsEmpty then
      begin
        if Gruppe = 0 then
          case Schicht of
            1: Result := q.FieldByName('SHIFT_TYP_S1').AsString;
            2: Result := q.FieldByName('SHIFT_TYP_S2').AsString;
            3: Result := q.FieldByName('SHIFT_TYP_S3').AsString;
          end;

        if Gruppe > 0 then
        try
          case Schicht of
            1: Result := q.FieldByName('SHIFT_TYP_' + IntToStr(Gruppe) + '_S1').AsString;
            2: Result := q.FieldByName('SHIFT_TYP_' + IntToStr(Gruppe) + '_S2').AsString;
            3: Result := q.FieldByName('SHIFT_TYP_' + IntToStr(Gruppe) + '_S3').AsString;
          end;
        except
          Result := '';
        end;
      end;
    end;
end;

function GetSchichtDauer(SchichtNR: Integer): Integer;
begin
  if Shift_Model <> 2 then
  begin
    if SchichtNR in [1..3] then
      Result := SDauer[SchichtNR, 0]
    else
      Result := 0;
  end
  else
    Result := 720;
end;
// -----------------------------------------------------------------------------

function GetSchichtDauer2(SchichtNR: Integer; GruppeNr : Integer): Integer;
begin
  if Shift_Model <> 2 then
  begin
    if SchichtNR in [1..3] then
      Result := SDauer2[SchichtNR, GruppeNr]
    else
      Result := 0;
  end
  else
    Result := 720;
end;
// -----------------------------------------------------------------------------

function GetSchichtDauerDatum(KalGruppe: Integer; DT: TDateTime): Integer;
var
  SchichtNR: Integer;
begin
  if Shift_Model <> 2 then
  begin
    SchichtNR := GetSchichtNr(KalGruppe, DT);
    if SchichtNR in [1..3] then
      Result := SDauer[SchichtNR, KalGruppe]
    else
      Result := 0;
  end
  else
    Result := 720;
end;

function GetSchichtDauerDatum(DT: TDateTime): Integer;
begin
  Result := GetSchichtDauerDatum(0, DT);
end;
// -----------------------------------------------------------------------------

function GetSchichtStartInt(KalGruppe: Integer; SchichtNR: Integer): Integer;
begin
  Result := 0;
  case SchichtNR of
    1: Result := ISchichtStart[1, KalGruppe];
    2: Result := ISchichtStart[2, KalGruppe];
    3: Result := ISchichtStart[3, KalGruppe];
  end;
end;
// -----------------------------------------------------------------------------

function GetSchichtStartFloat(KalGruppe: Integer; SchichtNR: Integer): Real;
begin
  Result := GetSchichtStartInt(KalGruppe, SchichtNR) / 1440;
end;

function GetSchichtStartFloat(SchichtNR: Integer): Real;
begin
  Result := GetSchichtStartFloat(0, SchichtNR);
end;

function GetSchichtStartFloat(Lizenz: string; SchichtNR: Integer): Real; overload;
begin
  Result := GetSchichtStartFloat(GetGruppe(Lizenz), SchichtNR);
end;

function GetSchichtStartInt2(KalGruppe : Integer; SchichtNR: Integer): Integer;
begin
  result := ISchichtStart2[SchichtNr, KalGruppe];
end;
// -----------------------------------------------------------------------------

function GetSchichtStartString(KalGruppe: Integer; SchichtNR: Integer): string;
var
  S: string;
begin
  S := TimeToStr(GetSchichtStartFloat(KalGruppe, SchichtNR));
  Result := S;
end;

function GetSchichtStartString(SchichtNR: Integer): string;
begin
  Result := GetSchichtStartString(0, SchichtNR);
end;
// -----------------------------------------------------------------------------

function isMomentArbeitsFrei(KalGruppe: Integer; DT: TDateTime): Boolean;
var
  Tag, Idx: Integer;
  Stunde: Real;
  NrSch, BitMaske: Integer;
begin
  Tag := Trunc(DT);
  Idx := Tag - Werkskalender[1].Tag + 1;

  if Idx > Anzahl_Tage_Kalender then
    Idx := Anzahl_Tage_Kalender;
  if Idx < 2 then
    Idx := 2;

  Stunde := Frac(DT);

  if Shift_Model <> 2 then
  begin
    if Stunde > SchichtStart[3, KalGruppe] then
    begin
      Stunde := Stunde - SchichtStart[3, KalGruppe];
      NrSch := 3;
    end
    else
      if Stunde > SchichtStart[2, KalGruppe] then
      begin
        Stunde := Stunde - SchichtStart[2, KalGruppe];
        NrSch := 2;
      end
      else
        if Stunde > SchichtStart[1, KalGruppe] then
        begin
          Stunde := Stunde - SchichtStart[1, KalGruppe];
          NrSch := 1;
        end
        else
        begin
          Stunde := Stunde + 1 - SchichtStart[3, KalGruppe];
          NrSch := 3;
          Idx := Idx - 1;
        end;

    BitMaske := NrSch;
    if BitMaske = 3 then
      BitMaske := 4;
  end
  else
  begin
    if Stunde > SchichtStart[2, KalGruppe] then
    begin
      Stunde := Stunde - SchichtStart[2, KalGruppe];
      NrSch := 2;
    end
    else
      if Stunde > SchichtStart[1, KalGruppe] then
      begin
        Stunde := Stunde - SchichtStart[1, KalGruppe];
        NrSch := 1;
      end
      else
      begin
        Stunde := Stunde + 1 - SchichtStart[2, KalGruppe];
        NrSch := 2;
        Idx := Idx - 1;
      end;

    BitMaske := NrSch;
  end;

  Stunde := Stunde * 1440;

  if (Werkskalender[Idx].SchichtEnde[KalGruppe] and BitMaske = BitMaske) and (KalGruppe > 0) then
    Result := Stunde < (SDauer[NrSch, KalGruppe] - Werkskalender[Idx].Schicht[NrSch, KalGruppe])
  else
    Result := Stunde > Werkskalender[Idx].Schicht[NrSch, KalGruppe];
end;
// -----------------------------------------------------------------------------

function GetNextArbeitMoment(Lizenz: string; DT: TDateTime; aHalbautomatik: Boolean = False): TDateTime;
var
  D: TDateTime;
  KalGruppe: Integer;
begin
  KalGruppe := GetGruppe(Lizenz);

  Result := GetNextArbeitMoment(KalGruppe, DT, aHalbautomatik);
end;

function GetNextArbeitMoment(KalGruppe: Integer; DT: TDateTime; aHalbautomatik: Boolean = False): TDateTime;
var
  D: TDateTime;
begin
  if aHalbautomatik and halbautomatik_berechnen then
    KalGruppe := HALBAUTOMATIKKALENDER;

  D := DT;
  while isMomentArbeitsFrei(KalGruppe, D) and (D < Now + 365) do
    D := D + MinutenTakt / 1440;

  Result := D;
end;

// -----------------------------------------------------------------------------

function GetPrevArbeitMoment(Lizenz: string; DT: TDateTime; aHalbautomatik: Boolean = False): TDateTime;
var
  D: TDateTime;
  KalGruppe: Integer;
begin
  KalGruppe := GetGruppe(Lizenz);

  if aHalbautomatik and halbautomatik_berechnen then
    KalGruppe := HALBAUTOMATIKKALENDER;

  D := DT;
  while isMomentArbeitsFrei(KalGruppe, D) and (D > Now - 365) do
    D := D - MinutenTakt / 1440;

  Result := D;
end;
// -----------------------------------------------------------------------------
function GetPersonal(DT : TDateTime) : Integer;
var
  Tag, Idx: Integer;
  Stunde: Real;

begin
  Tag := Trunc(DT);
  Stunde := Frac(DT);
  Idx := Tag - Werkskalender[1].Tag + 1;
  if Stunde < SchichtStart[1,0] then
    Result := Werkskalender[Idx-1].Personal[3];
  if Stunde >= SchichtStart[1,0] then
    Result := Werkskalender[Idx].Personal[1];
  if Stunde >= SchichtStart[2,0] then
    Result := Werkskalender[Idx].Personal[2];
  if Stunde >= SchichtStart[3,0] then
    Result := Werkskalender[Idx].Personal[3];
end;

function GetEndeDatumLizenz(Lizenz, AuftragsNr: string; StartDatum: Real; RestZeit_Min: Integer; aHalbautomatik: Boolean = False): Real;
var
  D: TDateTime;
  I: Integer;
  Min: Integer;
  kg: TMaschine;
begin
  Min := RestZeit_Min;
  kg := GetGruppenMaschine(Lizenz);
  if (withKapaFaktorProMaschine and (kg.KapazitaetsFaktor > 0) ) then
    Min := Round(Min / kg.KapazitaetsFaktor);
  Min := Min * EndeDatumPlus div 100;

  if Min > 60 * 24 * 365 then
    Min := 60 * 24 * 365;

  D := StartDatum;
  for I := 1 to Min div MinutenTakt do
  begin
    D := D + MinutenTakt / 1440;
    D := GetNextArbeitMoment(kg.KalenderGruppe, D, aHalbautomatik);
  end;
  Result := D;
end;
// -----------------------------------------------------------------------------

function Arbeitsfrei(Lizenz: string; Datum: Real): Boolean;
var
  KalGruppe, Idx: Integer;
begin
  KalGruppe := GetGruppe(Lizenz);
  Idx := Trunc(Datum) - Werkskalender[1].Tag + 1;
  if Shift_Model <> 2 then
    Result := Werkskalender[Idx].Schicht[1, KalGruppe] + Werkskalender[Idx].Schicht[2, KalGruppe] + Werkskalender[Idx].Schicht[3, KalGruppe] = 0
  else
    Result := Werkskalender[Idx].Schicht[1, KalGruppe] + Werkskalender[Idx].Schicht[2, KalGruppe] = 0;
end;
// -----------------------------------------------------------------------------

function GetFreeArbeitZeitproTag(Lizenz: string; DT: TDateTime; Sch: Integer): TDateTime;
var
  Tag, Idx: Integer;
begin
  Tag := Trunc(DT);
  Idx := Tag - Werkskalender[1].Tag + 1;
  Result := (SDauer[Sch, 0] - Werkskalender[Idx].Schicht[Sch, GetGruppe(Lizenz)]) / 1440
end;
// -----------------------------------------------------------------------------

function GetSDatum(Lizenz, AuftragsNr: string; EndeDatum: Real; Dauer_Min: Integer; aHalbautomatik: Boolean = False): Real;
var
  D: TDateTime;
  I: Integer;
  KalGruppe: Integer;
begin
  D := EndeDatum;
  KalGruppe := GetGruppe(Lizenz);
  if aHalbautomatik and halbautomatik_berechnen then
    KalGruppe := HALBAUTOMATIKKALENDER;

  Dauer_Min := Dauer_Min * EndeDatumPlus div 100;
  for I := 1 to Dauer_Min div MinutenTakt do
  begin
    D := D - MinutenTakt / 1440;
    while isMomentArbeitsFrei(KalGruppe, D) and (D > 0) do
      D := D - MinutenTakt / 1440;
  end;
  Result := D;
end;
// -----------------------------------------------------------------------------

function ZeitInMinuten(Lizenz: string; Datum1, Datum2: TDateTime; aHalbautomatik: Boolean = False): Integer;
var
  D: TDateTime;
  N: Integer;
  KalGruppe: Integer;
begin
  KalGruppe := GetGruppe(Lizenz);

  D := Datum1;
  while isMomentArbeitsFrei(KalGruppe, D) and (D < Datum2) do
    D := D + MinutenTakt / 1440;

  N := 0;

  if aHalbautomatik and halbautomatik_berechnen then
    KalGruppe := HALBAUTOMATIKKALENDER;

  try
    while D < Datum2 do
    begin
      N := N + MinutenTakt;
      D := D + MinutenTakt / 1440;
      while isMomentArbeitsFrei(KalGruppe, D) and (D < Datum2) do
        D := D + MinutenTakt / 1440;
    end;
  except
    N := 0;
  end;
  if N > (Datum2 - Datum1) * 1440 then
    N := Round((Datum2 - Datum1) * 1440);
  Result := N;
end;
// -----------------------------------------------------------------------------

procedure BringFormToMiddle(Form: TForm);
var
  X, Y: Integer;
begin
  X := SCREEN.Width;
  Y := SCREEN.Height;
  Form.Left := (X - Form.Width) div 2;
  Form.Top := (Y - Form.Height) div 2;
end;
// -----------------------------------------------------------------------------

procedure KWToDate(KW, KWJahr: Word; var Datum: TDateTime);
var
  TempDate: TDateTime;
  Dw, I: Integer;
begin
  TempDate := EncodeDate(KWJahr, 1, 1);
  Dw := DayOfWeek(TempDate);
  Dec(Dw);
  if Dw = 0 then
    Dw := 7;
  if Dw in [5..7] then
    Dw := 8 - Dw
  else
    Dw := 1 - Dw;

  TempDate := TempDate + Dw;
  for I := 2 to KW do
    TempDate := TempDate + 7;
  Datum := TempDate;
end;
// -----------------------------------------------------------------------------

procedure DateToKw(Datum: TDateTime; var KW, KWJahr: Word);
begin
  KW := WeekOfTheYear(Datum, KWJahr);
end;
// -----------------------------------------------------------------------------

function GetGruppe(Lizenz: string): Integer;
var
  A, B, C: Integer;
  mm: TMaschine;
begin
//  RefreshKGruppe();
  if Lizenz = '' then
    Result := 0
  else
  begin
    if Lizenz = HALBAUTOMATIKMASCHINE then
      Result := HALBAUTOMATIKKALENDER
    else
    begin
      mm := GetGruppenMaschine(Lizenz);
      Result := mm.KalenderGruppe
    end;
  end;
  if (Result < 0) or (Result > 16) then
    Result := 0;
end;

function GetGruppenMaschine(Lizenz: string): TMaschine;
var
  A, B, C: Integer;
  mm: TMaschine;
begin
//  RefreshKGruppe();
  mm.KapazitaetsFaktor := 1;
  if Lizenz = '' then
    mm.KalenderGruppe := 0
  else
  begin
    A := 0;
    B := Length(Maschine) - 1;
    while A < B - 1 do
    begin
      C := (A + B) div 2;
      if Maschine[C].MaschName < Lizenz then
        A := C
      else
        B := C;
    end;
    if Maschine[A].MaschName = Lizenz then
      mm := Maschine[A]
    else
      if Maschine[B].MaschName = Lizenz then
        mm := Maschine[B]
      else
        mm.KalenderGruppe := 0
  end;
  Result := mm;
end;

end.

