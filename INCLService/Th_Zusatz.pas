unit Th_Zusatz;

interface

uses
  Windows, Classes, CO_DataBase, SysUtils, Math, CO_TPM_V63, CO_INCMeldung_V63, CO_AliveTimer;

type
  TThread_Zusatz = class(TThread)
  private
    CDatabase: TCO_Database;
    qSuch, qSuch2, qSuch3, qSuch4: TCO_Query;
    qUpdate, qDurchlauf: TCO_Query;



    LastDate: TDateTime;
    AddonAliveTimer: TCO_AliveClient;

    procedure Palette_Rest_Berechnen;
    procedure TPM_Korrektur_Doppelte_Daten;
    procedure WZReparatur;
    procedure Check_TaktLog;
    procedure CreateAddonAliveTimer;

  protected
    procedure Execute; override;
  public
    procedure StartProgramme;
    procedure CalcPackedlogFromShiftlog;overload;
    procedure CalcPackedlogFromShiftlog(fromdate : TDateTime);overload;
    procedure Book_Short_Delay;
    procedure CheckRuestProt_Stillog;
    procedure Laufzeit_Berechnen;
    procedure Job_No_to_Downtime_Log;
    procedure CheckVerpacktProt;
    function CheckPackSchicht(aTage: Integer) : Integer;
    procedure ArbeitsFrei_Buchen;
    procedure Taktzeit_Personal;
    procedure TaktMitteln(aUpdate: Boolean);
    procedure UnscheduledSetup;
    procedure CheckSollstueck;
    procedure CheckWzWartungen;
    procedure CheckAuftragKette;

    procedure Reschedule;
    procedure BerechnenEndeausIst;
    function Laufende_Auftraege_Terminieren: Boolean;
    function Autoterminierung: Boolean;
    procedure Laufzeit_Berechnen2;
    procedure Status_Beschreibung;
    procedure PlanListeReportParameterSchreiben(Par, Val: string);
    constructor Create(Suspended: Boolean);
    destructor Destroy; override;
  end;

var
  Thread_Zusatz: TThread_Zusatz;

implementation

uses
  DBMain,
  {$IFNDEF AZURE}
  Main,
  {$ELSE}
  MainAzure,
  {$ENDIF}
  Sprache_V63, Arbeit, SQL_fuc, U_SPC, Maindll, IniFiles, CO_Setup2,
  DB, utils, DateUtils;

constructor TThread_Zusatz.Create(Suspended: Boolean);
begin
  inherited Create(Suspended);
  FreeOnTerminate := False;
  Priority := tpNormal;

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

  qSuch.Tag := 1;
  qSuch2.Tag := 1;
  qSuch3.Tag := 1;
  qSuch4.Tag := 1;
  qUpdate.Tag := 1;
  qDurchlauf.Tag := 1;

  LastDate := 0;

  CreateAddonAliveTimer
end;
// *****************************************************************************

destructor TThread_Zusatz.Destroy;
begin
  qSuch.Free;
  qSuch2.Free;
  qSuch3.Free;
  qSuch4.Free;
  qUpdate.Free;
  qDurchlauf.Free;

  AddonAliveTimer.Free;

  CDatabase.Free;

  inherited Destroy;
end;
// *****************************************************************************

procedure TThread_Zusatz.Execute;
begin
  while not Terminated do
  begin
    try
      WaitForSingleObject(Event_Zusatz, INFINITE);

      if INCLUDISDatabaseTyp = dbTypMSSQL then
      begin
        DecimalSeparator := '.';
        ThousandSeparator := ',';
      end;

      if Terminated then
        Exit;

      // Nur wenn die Datenbank online ist dann Thread starten. Wenn nicht einen aussetzen        
      if CheckCO_DatabaseConnect(CDatabase, qUpdate, 3, 'AddOns') then
      begin
        StartProgramme;
      end;
    except
      on E: Exception do
        SchreibeMeldung('Exception : ' + E.message, 3);
    end;
  end;
end;
// *****************************************************************************

procedure TThread_Zusatz.CheckRuestProt_Stillog;
var
  S: string;
  Nr: string;
  Kommt: Extended;
  Geht: Extended;
  BANr: string;
  Lizenz: string;
  Grund: string;
  Werkzeug: Integer;
  SollRuestzeit: Integer;
  userid : integer;
  hostname : string;
  lastchange: Extended;
begin
  //Diese Funktion ermittelt neue Stillstände der Gruppe RÜSTEN, und verbucht
  //diese im Rüstzeitprotokoll
  //*******************************************************************
  S := 'select * from tpm_stillog,tpm_stillstaende where tpm_stillog.STILLSTANDNR = tpm_stillstaende.STILLSTANDNR '
    + ' and tpm_stillstaende.GRUPPE = 1 and tpm_stillog.RUESTPROT = 0 and tpm_stillog.geht > 0';
  SQL_Get(qDurchlauf, S);
  qDurchlauf.First;
  while not qDurchlauf.EOF do
  begin
    Nr := qDurchlauf.FieldByName('NR').AsString;
    Kommt := qDurchlauf.FieldByName('Kommt').AsFloat;
    Geht :=  qDurchlauf.FieldByName('Geht').AsFloat;
    Grund := qDurchlauf.FieldByName('stillstandnr').AsString;
    Lizenz := TTT_GetMaschine(qDurchlauf.FieldByName('MASCHNR').AsInteger);
    userid :=  qDurchlauf.FieldByName('userid').AsInteger;
    hostname :=  qDurchlauf.FieldByName('hostname').AsString;
    lastchange:= qDurchlauf.FieldByName('lastchange').AsFloat; 
    if SQL2GetBool(qSuch, 'PDE', 'LIZENZ', Lizenz, 'stat', '0') then
    begin
      BANr := qSuch.FieldByName('Betriebsauftragnr').AsString;
      Werkzeug := qSuch.FieldByName('Werkzeug').AsInteger;
      SollRuestzeit := Format_String(qSuch.FieldByName('Ruestzeit').AsString);
    end
    else
    begin
      S := 'select * from aarchiv where MASCHINE = ''' + Lizenz +
        ''' and Nr = (select MAX(NR) from aarchiv where MASCHINE = ''' + Lizenz + ''')';
      SQL_Get(qSuch, S);
      BANr := qSuch.FieldByName('Betriebsauftragnr').AsString;
      Werkzeug := Format_String(qSuch.FieldByName('Werkzeug').AsString);
      SollRuestzeit := Format_String(qSuch.FieldByName('RuestzeitSOLL').AsString);
    end;
// userid, hostname, lastchange
    S := 'Insert into RuestProt'
      + ' (Nr, BetriebsAuftragNr, Name, RuestStart, RuestEnde, RuestIst, Grund,'
      + ' RuestSoll, Lizenz, Werkzeug, userid, hostname, lastchange)'
      + ' values (RuestProtId.NextVal,'
      + '''' + BANr + ''','
      + ''''','
      + '''' + FloatToStr2(Kommt) + ''','
      + '''' + FloatToStr2(Geht) + ''','
      + '''-1'','
      + '''' + Grund + ''','
      + '''' + IntToStr(SollRuestzeit) + ''','
      + '''' + Lizenz + ''','
      + '''' + IntToStr(Werkzeug) + ''','
      +  IntToStr(userid) + ','
      + '''' + hostname + ''','
      + FloatToPunktString(lastchange)
      + ')';
    try
      SQL_Insert(qUpdate, S);
    except
    end;

    //Stillstandmerker zurücksetzten
    S := 'update tpm_stillog set RUESTPROT = 1 where Nr = ''' + Nr + '''';
    SQL_Insert(qUpdate, S);

    qDurchlauf.Next;
  end;
end;
// *****************************************************************************

procedure TThread_Zusatz.Palette_Rest_Berechnen;
var
  S: string;
begin
  S := 'update PDE set Istwert = 0 where Istwert is Null';
  SQL_Insert(qUpdate, S);
  S := 'update PDE set Pack = 0 where Pack is Null';
  SQL_Insert(qUpdate, S);
// SQL Extrem langsam. Daher separat Optimiert
  if INCLUDISDatabaseTyp = dbTypMSSQL then
  begin
    S := 'UPDATE pde SET Paletten_Rest = CASE WHEN CAST(Sollwert AS int)-CAST(Pack AS int) < 0 then 0 ELSE '
      + 'CASE WHEN PackGroesse*Palette =0 THEN 0 ELSE '
	  + 'CAST((CAST(Sollwert AS int)-CAST(Pack AS int))/PackGroesse/Palette+0.4999 AS int) END END ';	  
    SQL_Insert(qUpdate, S);
	
	S := 'UPDATE pde SET Paletten_Soll = CASE WHEN PackGroesse*Palette =0 THEN 0 ELSE CAST(CAST(Sollwert AS int)/PackGroesse/Palette+0.4999 AS int) END';
    SQL_Insert(qUpdate, S);
  end
  else
  begin
    S := 'update PDE set Paletten_Rest ='
      + ' Decode(Sign(Sollwert-Pack), -1, 0,'
      + ' Decode(PackGroesse*Palette, 0, 0, Round((Sollwert-Pack)/PackGroesse/Palette+0.4999)))';
    SQL_Insert(qUpdate, S);

    S := 'update PDE set Paletten_Soll ='
      + ' Decode(PackGroesse*Palette, 0, 0, Round(Sollwert/PackGroesse/Palette+0.4999))';
    SQL_Insert(qUpdate, S);
  end;
  
  S := 'update Maschinf set Paletten_Rest ='
    + ' (select Paletten_Rest from PDE where Maschinf.BetriebsAuftragNr = PDE.BetriebsAuftragNr)';
  SQL_Insert(qUpdate, S);
end;
// *****************************************************************************

procedure TThread_Zusatz.TPM_Korrektur_Doppelte_Daten;
var
  S: string;
begin
  try
    S := 'select maschnr, datum, schicht, BETRIEBSAUFTRAGNR, count(*) CNT from tpm_schicht'
      + ' group by maschnr, datum, schicht, BETRIEBSAUFTRAGNR'
      + ' having count(*) > 1';

    SQL_Get(qDurchlauf, S);

    while not qDurchlauf.EOF do
    begin

      S := 'delete from TPM_Schicht where maschnr = ''' + qDurchlauf.FieldByName('maschnr').AsString + ''''
        + ' AND datum = ''' + DateToStrSQL(qDurchlauf.FieldByName('datum').AsDateTime) + ''''
        + ' AND schicht = ''' + qDurchlauf.FieldByName('schicht').AsString + ''''
        + ' AND BETRIEBSAUFTRAGNR = ''' + qDurchlauf.FieldByName('BETRIEBSAUFTRAGNR').AsString + ''''
        + ' AND Nr <> (select MAX(NR) from TPM_Schicht where maschnr = '''
        + qDurchlauf.FieldByName('maschnr').AsString + ''''
        + ' AND datum = ''' + DateToStrSQL(qDurchlauf.FieldByName('datum').AsDateTime) + ''''
        + ' AND schicht = ''' + qDurchlauf.FieldByName('schicht').AsString + ''''
        + ' AND BETRIEBSAUFTRAGNR = ''' + qDurchlauf.FieldByName('BETRIEBSAUFTRAGNR').AsString + ''')';

      SQL_Insert(qUpdate, S);

      qDurchlauf.Next;
    end;
  except
  end;
end;
// *****************************************************************************

procedure TThread_Zusatz.Job_No_to_Downtime_Log;
var
  S, BANr, ANr, Bez, Liz, Notiz, WZNr, s2: string;
  A, B: Extended;
  M, Bl, Nr, kav, grund, maschnr, i : Integer;
  sustk, suzyk, varkav, suscrap: Integer; // su -> Setup
  detailed, Gefunden: Boolean;

  baListe : TStringList;
begin
  //detailed := true;


  //   Zuordnen von Endezeiten bei Aufträgen
  qUpdate.Close;

  (*
  // Das Monster Statement scheint bei großen Datenbanken in Timeouts zu laufen. Es wird für jeden Auftrag einzeln aufgerufen.
  // Zwar nicht so performant aber insgesamt zuverlässiger. ML 15.11.2018
  S := 'UPDATE aarchiv SET enddatumzeit = '
    + ' aarchiv.startdatumzeit + (((CASE WHEN aarchiv.taktzeitist IS NULL THEN 0 ELSE aarchiv.taktzeitist END  / 100) * '
    + ' CASE WHEN aarchiv.produziertint IS NULL THEN 0 ELSE aarchiv.produziertint END / '
    + ' CASE WHEN aarchiv.kavitaet = 0 THEN 1 ELSE aarchiv.kavitaet END ) / 60 /1440) '
{$IF INCLUDISDatabaseTyp = 0}
  + ', enddatumstr = FloatToDateTime(aarchiv.startdatumzeit + (((CASE WHEN aarchiv.taktzeitist IS NULL THEN 0 ELSE aarchiv.taktzeitist END  / 100) * '
    + ' CASE WHEN aarchiv.produziertint IS NULL THEN 0 ELSE aarchiv.produziertint END / '
    + ' CASE WHEN aarchiv.kavitaet = 0 THEN 1 ELSE aarchiv.kavitaet END ) / 60 /1440))  '
{$ELSE}
  + ', enddatumstr = '' '''
{$IFEND}
  + ' WHERE aarchiv.enddatumzeit = 0 AND aarchiv.startdatumzeit > 0 AND betriebsauftragnr NOT IN (SELECT betriebsauftragnr FROM pde)'
  //RS 22.10.2013 Nadfinlo: Damit auch laufende Detail-Aufträge "in Ruhe gelassen" werden
  + ' AND betriebsauftragnr NOT IN (SELECT betriebsauftragnr FROM pdekombi WHERE masterbetriebsauftragnr IN (SELECT betriebsauftragnr FROM pde))';
  try
    SQL_Insert(qUpdate, S);
  except
  end;
    *)

  s := 'SELECT betriebsauftragnr FROM aarchiv '
    + ' WHERE aarchiv.enddatumzeit = 0 AND aarchiv.startdatumzeit > 0 AND betriebsauftragnr NOT IN (SELECT betriebsauftragnr FROM pde)'
    + ' AND betriebsauftragnr NOT IN (SELECT betriebsauftragnr FROM pdekombi WHERE masterbetriebsauftragnr IN (SELECT betriebsauftragnr FROM pde))';
  SQL_Get(qSuch4, s);
  baListe := TStringList.Create;
  try
    while not qSuch4.Eof do
    begin
      baListe.Add(qSuch4.FieldByName('betriebsauftragnr').AsString);
      for i := 0 to baListe.Count-1 do
      begin
        S := 'UPDATE aarchiv SET enddatumzeit = '
          + ' aarchiv.startdatumzeit + (((CASE WHEN aarchiv.taktzeitist IS NULL THEN 0 ELSE aarchiv.taktzeitist END  / 100) * '
          + ' CASE WHEN aarchiv.produziertint IS NULL THEN 0 ELSE aarchiv.produziertint END / '
          + ' CASE WHEN aarchiv.kavitaet = 0 THEN 1 ELSE aarchiv.kavitaet END ) / 60 /1440) '
{$IF INCLUDISDatabaseTyp = 0}
          + ', enddatumstr = FloatToDateTime(aarchiv.startdatumzeit + (((CASE WHEN aarchiv.taktzeitist IS NULL THEN 0 ELSE aarchiv.taktzeitist END  / 100) * '
          + ' CASE WHEN aarchiv.produziertint IS NULL THEN 0 ELSE aarchiv.produziertint END / '
          + ' CASE WHEN aarchiv.kavitaet = 0 THEN 1 ELSE aarchiv.kavitaet END ) / 60 /1440))  '
{$ELSE}
          + ', enddatumstr = '' '''
{$IFEND}
          + ' WHERE aarchiv.betriebsauftragnr = ''' + baListe[i] + '''';
        SQL_Insert(qUpdate, S);
      end;
      qSuch4.Next;
    end;


  finally
    baListe.Free;
  end;




  if detailed then
   SchreibeMeldung('Step 4-293', 3);

  {
        -----------  beim Update dauert es lang und ist nicht nötig. Sascha. 29.07.2009
    S := 'UPDATE tpm_stillog SET betriebsauftragnr = NULL WHERE werkzeugnr = ''-'''
      + ' AND betriebsauftragnr <> ''-'' AND (not betriebsauftragnr is null)';
    SQL_Insert(qUpdate, S);
  }

  {  durch die untere Funktion ersetzt
  S := 'select TPM_Stillog.Nr, TPM_Stillog.MaschNr, Kommt, Geht, Lizenz from TPM_Stillog, Maschine'
    + ' where BetriebsAuftragNr is Null and Geht > 0 and TPM_Stillog.MaschNr = Maschine.MaschNr';
  SQL_Get(qSuch, S);
  while not qSuch.EOF do
  begin
    BANr := '-';
    ANr := '-';
    Bez := '-';
    WZNr := '-';

    S1 := ' where Maschine = ''' + qSuch.FieldByName('Lizenz').AsString + ''''
      + ' and'
      + ' (StartDatumZeit <= ''' + qSuch.FieldByName('Kommt').AsString + ''''
      + ' and Decode(EndDatumZeit, 0, 99999, EndDatumZeit) >= ''' + qSuch.FieldByName('Kommt').AsString + ''''
      + ' or'
      + ' StartDatumZeit >= ''' + qSuch.FieldByName('Kommt').AsString + ''''
      + ' and StartDatumZeit <  ''' + qSuch.FieldByName('Geht').AsString + ''')';

    S := 'select * from AARchiv' + S1 + ' ORDER BY StartDatumZeit DESC';
    SQL_Get(qSuch2, S);
    if not qSuch2.IsEmpty then
    begin
      BANr := qSuch2.FieldByName('BetriebsAuftragNr').AsString;
      ANr := qSuch2.FieldByName('AuftragNr').AsString;
      Bez := qSuch2.FieldByName('Bezeichnung').AsString;
      WZNr := qSuch2.FieldByName('WerkzeugNr').AsString;
    end
    else
    begin
      S1 := ' where Lizenz = ''' + qSuch.FieldByName('Lizenz').AsString + ''''
        + ' and'
        + ' (RuestStart <= ''' + qSuch.FieldByName('Kommt').AsString + ''''
        + ' and Decode(RuestEnde, 0, 99999, '''', ''99999'', RuestEnde) >= ''' + qSuch.FieldByName('Kommt').AsString + ''''
        + ' or'
        + ' RuestStart >= ''' + qSuch.FieldByName('Kommt').AsString + ''''
        + ' and RuestStart <  ''' + qSuch.FieldByName('Geht').AsString + ''')';
      //      S := 'select Count(*) as CNT from RuestProt' + S1;
      S := 'select * from RuestProt' + S1;
      SQL_Get(qSuch2, S);
      if not qSuch2.IsEmpty then
      begin
        BANr := qSuch2.FieldByName('BetriebsAuftragNr').AsString;
        S1 := 'SELECT * FROM aarchiv WHERE betriebsauftragnr = ''' + BANr + '''';
        SQL_Get(qSuch2, S1);
        if not qSuch2.IsEmpty then
        begin
          ANr := qSuch2.FieldByName('AuftragNr').AsString;
          Bez := qSuch2.FieldByName('Bezeichnung').AsString;
          WZNr := qSuch2.FieldByName('WerkzeugNr').AsString;
        end;
      end
    end;

    if (BANr <> '-') and (WZNr = '-') then
      WZNr := GetL('unbekannt');

    S := 'update TPM_Stillog set'
      + ' BetriebsAuftragNr = ''' + BANr + ''','
      + ' AuftragNr = ''' + ANr + ''','
      + ' Bezeichnung = ''' + Bez + ''','
      + ' WerkzeugNr = ''' + WZNr + ''''
      + ' where Nr = ' + qSuch.FieldByName('Nr').AsString;
    SQL_Insert(qUpdate, S);

    qSuch.Next;
  end;
   }

  // Laufzeitlog Korrektur für nicht abgeschlossene Aufträge
  S := 'update LaufzeitLog set AuftragEnde = Decode(AuftragStart, 0, RuestStart, AuftragStart) where Nr in'
    + ' (select Min(Nr) from Laufzeitlog where AuftragEnde = 0 group by MaschNr having Count(*) > 1)';
  SQL_Insert(qUpdate, S);

  S := 'select TPM_Stillog.Nr, AArchiv.BetriebsAuftragNr, AArchiv.AuftragNr, AArchiv.Bezeichnung, AArchiv.WerkzeugNr'
    + ' from TPM_Stillog'
    + ' left join Laufzeitlog on TPM_Stillog.MaschNr = Laufzeitlog.MaschNr'
    + ' and TPM_Stillog.Kommt < Decode(Laufzeitlog.AuftragEnde, 0, 99999, Laufzeitlog.AuftragEnde)'
    + ' and Decode(TPM_Stillog.Geht, 0, 99999, TPM_Stillog.Geht) > Laufzeitlog.RuestStart'
    + ' left join AARchiv on Laufzeitlog.BetriebsAuftragNr = AARchiv.BetriebsAuftragNr'
    + ' where TPM_Stillog.BetriebsAuftragNr is null and TPM_Stillog.Geht > 0'
    + ' order by TPM_Stillog.Kommt';
  SQL_Get(qSuch, S);

  if detailed then
    SchreibeMeldung('Step 4-385', 3);

  while not qSuch.EOF do
  begin
    BANr := qSuch.FieldByName('BetriebsAuftragNr').AsString;
    ANr := qSuch.FieldByName('AuftragNr').AsString;
    Bez := qSuch.FieldByName('Bezeichnung').AsString;
    WZNr := qSuch.FieldByName('WerkzeugNr').AsString;

    if BANr = '' then
    begin
      BANr := '-';
      ANr := '-';
      Bez := '-';
      WZNr := '-';
    end;

    if (BANr <> '-') and (WZNr = '-') then
      WZNr := GetL('unbekannt');

    S := 'update TPM_Stillog set'
      + ' BetriebsAuftragNr = ''' + BANr + ''','
      + ' AuftragNr = ''' + ANr + ''','
      + ' Bezeichnung = ''' + Bez + ''','
      + ' WerkzeugNr = ''' + WZNr + ''''
      + ' where Nr = ' + qSuch.FieldByName('Nr').AsString;
    SQL_Insert(qUpdate, S);

    qSuch.Next;
  end;

  if detailed then
    SchreibeMeldung('Step 4-415', 3);

  S := 'select * from TPM_Stillog where KommtStr is null';
  SQL_Get(qSuch, S);
  while not qSuch.EOF do
  begin
    S := 'update TPM_Stillog set'
      + ' KommtStr = ''' + DateTimeToStr(qSuch.FieldByName('Kommt').AsFloat) + ''''
      + ' where Nr = ' + qSuch.FieldByName('Nr').AsString;
    SQL_Insert(qUpdate, S);
    qSuch.Next;
  end;

  S := 'select * from TPM_Stillog where GehtStr is null and Geht > 0';
  SQL_Get(qSuch, S);
  while not qSuch.EOF do
  begin
    S := 'update TPM_Stillog set GehtStr = ''' + DateTimeToStr(qSuch.FieldByName('Geht').AsFloat) + ''''
      + ' where Nr = ' + qSuch.FieldByName('Nr').AsString;
    SQL_Insert(qUpdate, S);
    qSuch.Next;
  end;

  if detailed then
    SchreibeMeldung('Step 4-437', 3);

  S := 'select * from TPM_Stillog where Kommt > Geht and Geht > 0';
  SQL_Get(qSuch, S);
  while not qSuch.EOF do
  begin
    S := 'update TPM_Stillog set Geht = 0 where Nr = ' + qSuch.FieldByName('Nr').AsString;
    SQL_Insert(qUpdate, S);
    qSuch.Next;
  end;

  S := 'select * from TPM_Stillog where Schicht is null';
  SQL_Get(qSuch, S);
  while not qSuch.EOF do
  begin
    S := 'update TPM_Stillog set'
      + ' Schicht = ' + IntToStr(GetSchichtNr(qSuch.FieldByName('Kommt').AsFloat))
      + ' where Nr = ' + qSuch.FieldByName('Nr').AsString;
    SQL_Insert(qUpdate, S);
    qSuch.Next;
  end;

  if detailed then
    SchreibeMeldung('Step 4-470', 3);

  if barcodepzewerkstatt then
  begin
    S := 'select TPM_Stillog.Nr, PZE_Werkstatt.PersonalNr, Bediener.Name'
      + ' from TPM_Stillog, PZE_Werkstatt, Bediener'
      + ' where TPM_Stillog.MaschNr = PZE_Werkstatt.MaschNr'
      + ' and Bediener.PersonalNr = PZE_Werkstatt.PersonalNr'
      + ' and TPM_Stillog.PersonalNr is null'
      + ' and TPM_Stillog.Kommt < Decode(PZE_Werkstatt.Geht, 0, 99999, PZE_Werkstatt.Geht)'
      + ' and Decode(TPM_Stillog.Geht, 0, 99999, TPM_Stillog.Geht) > PZE_Werkstatt.Kommt';
    SQL_Get(qSuch, S);
    while not qSuch.EOF do
    begin
      S := 'update TPM_Stillog set'
        + ' PersonalNr = ''' + qSuch.FieldByName('PersonalNr').AsString + ''','
        + ' Personal = ''' + qSuch.FieldByName('Name').AsString + ''''
        + ' where Nr = ' + qSuch.FieldByName('Nr').AsString;
      SQL_Insert(qUpdate, S);
      qSuch.Next;
    end;
  end;

  //if Sprache_Format = SP_FORMAT_USA then
  if Shift_Model = 2 then
  begin
    S := 'select Nr, MaschNr, DatumZeit, Schicht from TPM_Schicht where Shift_Typ = ''-'' order by Nr';
    SQL_Get(qSuch, S);
    while not qSuch.EOF do
    begin
      S := 'update TPM_Schicht set'
        + ' Shift_Typ = ''' + TTT_GetSchichtTyp(qSuch4, qSuch.FieldByName('MaschNr').AsInteger,
        qSuch.FieldByName('DatumZeit').AsFloat, 0)
        //        qSuch.FieldByName('Schicht').AsInteger)
      + ''' where Nr = ' + qSuch.FieldByName('Nr').AsString;
      SQL_Insert(qUpdate, S);
      qSuch.Next;
    end;

    S := 'select Nr, MaschNr, Kommt, Schicht from TPM_Stillog where Shift_Typ = ''-'' order by Nr';
    SQL_Get(qSuch, S);
    while not qSuch.EOF do
    begin
      S := 'update TPM_Stillog set'
        + ' Shift_Typ = ''' + TTT_GetSchichtTyp(qSuch4, qSuch.FieldByName('MaschNr').AsInteger,
        qSuch.FieldByName('Kommt').AsFloat,
        qSuch.FieldByName('Schicht').AsInteger)
        + ''' where Nr = ' + qSuch.FieldByName('Nr').AsString;
      SQL_Insert(qUpdate, S);
      qSuch.Next;
    end;

    if detailed then
      SchreibeMeldung('Step 4-522', 3);

    S := 'select Nr, MaschNr, Datumzeit, Schicht from TPM_Auswertung where Shift_Typ = ''-'' order by Nr';
    SQL_Get(qSuch, S);
    while not qSuch.EOF do
    begin
      S := 'update TPM_Auswertung set'
        + ' Shift_Typ = ''' + TTT_GetSchichtTyp(qSuch4, qSuch.FieldByName('MaschNr').AsInteger,
        qSuch.FieldByName('Datumzeit').AsFloat,
        qSuch.FieldByName('Schicht').AsInteger)
        + ''' where Nr = ' + qSuch.FieldByName('Nr').AsString;
      SQL_Insert(qUpdate, S);
      qSuch.Next;
    end;

    S := 'select Nr, Maschine, Datumzeit, Schicht from TPM_Produktionsdetail where Shift_Typ = ''-'' order by Nr';
    SQL_Get(qSuch, S);
    while not qSuch.EOF do
    begin
      S := 'update TPM_Produktionsdetail set'
        + ' Shift_Typ = ''' + TTT_GetSchichtTyp(qSuch4, TTT_GetMaschNr(qSuch.FieldByName('Maschine').AsString),
        qSuch.FieldByName('Datumzeit').AsFloat,
        qSuch.FieldByName('Schicht').AsInteger)
        + ''' where Nr = ' + qSuch.FieldByName('Nr').AsString;
      SQL_Insert(qUpdate, S);
      qSuch.Next;
    end;

    if detailed then
      SchreibeMeldung('Step 4-551', 3);

    S := 'select Nr, maschnr,  Datumzeit, Schicht from Manuelle_buchung where Shift_Typ = ''-'' order by Nr';
    SQL_Get(qSuch, S);
    while not qSuch.EOF do
    begin
      S := 'update Manuelle_buchung set'
        + ' Shift_Typ = ''' + TTT_GetSchichtTyp(qSuch4, qSuch.FieldByName('MaschNr').AsInteger,
        qSuch.FieldByName('Datumzeit').AsFloat,
        qSuch.FieldByName('Schicht').AsInteger)
        + ''' where Nr = ' + qSuch.FieldByName('Nr').AsString;
      SQL_Insert(qUpdate, S);
      qSuch.Next;
    end;

    S := 'select Nr, Lizenz, Datumzeit, Schicht from Taktzeiten where Shift_Typ = ''-'' order by Nr';
    SQL_Get(qSuch, S);
    while not qSuch.EOF do
    begin
      S := 'update Taktzeiten set'
        + ' Shift_Typ = ''' + TTT_GetSchichtTyp(qSuch4, TTT_GetMaschNr(qSuch.FieldByName('Lizenz').AsString),
        qSuch.FieldByName('Datumzeit').AsFloat,
        qSuch.FieldByName('Schicht').AsInteger)
        + ''' where Nr = ' + qSuch.FieldByName('Nr').AsString;
      SQL_Insert(qUpdate, S);
      qSuch.Next;
    end;

    if detailed then
      SchreibeMeldung('Step 4-580', 3);

    S := 'select Nr, Lizenz,  Datum, 0 Schicht from buchungsprot where Shift_Typ = ''-'' order by Nr';
    SQL_Get(qSuch, S);
    while not qSuch.EOF do
    begin
      S := 'update buchungsprot set'
        + ' Shift_Typ = ''' + TTT_GetSchichtTyp(qSuch4, TTT_GetMaschNr(qSuch.FieldByName('Lizenz').AsString),
        qSuch.FieldByName('Datum').AsFloat,
        qSuch.FieldByName('Schicht').AsInteger)
        + ''' where Nr = ' + qSuch.FieldByName('Nr').AsString;
      SQL_Insert(qUpdate, S);
      qSuch.Next;
    end;

    S := 'select Nr, Lizenz, Datum, 0 Schicht from kavprot where Shift_Typ = ''-'' order by Nr';
    SQL_Get(qSuch, S);
    while not qSuch.EOF do
    begin
      S := 'update kavprot set'
        + ' Shift_Typ = ''' + TTT_GetSchichtTyp(qSuch4, TTT_GetMaschNr(qSuch.FieldByName('Lizenz').AsString),
        qSuch.FieldByName('Datum').AsFloat,
        qSuch.FieldByName('Schicht').AsInteger)
        + ''' where Nr = ' + qSuch.FieldByName('Nr').AsString;
      SQL_Insert(qUpdate, S);
      qSuch.Next;
    end;

  end;

  if detailed then
    SchreibeMeldung('Step 4-612', 3);
(*

// Kavprot Zuordnung entfernt. Nur Korrektur. Sollte auch so funktionieren. 

{$IFDEF INCL_MSADO}
  S := 'UPDATE kavprot'
    + ' SET kavprot.form = maschinf.form, kavprot.werkzeugnr = maschinf.werkzeug_nr, '
    + ' kavprot.kav_soll=maschinf.kavitaet_soll FROM '
    + ' maschinf '
    + ' INNER JOIN kavprot ON kavprot.betriebsauftragnr = maschinf.betriebsauftragnr '
    + ' WHERE kavprot.form = ''-''';

{$ELSE}
  S := 'update kavprot set (kavprot.form,kavprot.werkzeugnr,kavprot.kav_soll)='
    + ' (select max(maschinf.form), max(maschinf.werkzeug_nr),max(maschinf.kavitaet_soll)'
    + ' from maschinf'
    + ' where kavprot.betriebsauftragnr=maschinf.betriebsauftragnr'
    + ' group by maschinf.form) where kavprot.form=''-''';
{$ENDIF}
  try
    SQL_Insert(qUpdate, S);
  except
  end;

  s:= 'UPDATE kavprot SET werkzeugnr = '
    + ' (SELECT werkzeugnr FROM aarchiv WHERE aarchiv.betriebsauftragnr = kavprot.betriebsauftragnr) '
    + ' WHERE werkzeugnr IS NULL OR werkzeugnr = '''' ';
  try
    SQL_Insert(qUpdate, S);
  except
  end;
  *)
  if detailed then
    SchreibeMeldung('Step 4-642', 3);
   (* Auch rausgeschmissen. Wenn doch NULL dann ist was anderes faul ML14.10.2022
  s := 'SELECT nr, betriebsauftragnr FROM tpm_schicht WHERE kav_soll IS null';
  SQL_Get(qSuch, S);
  while not qSuch.EOF do
  begin
    baNr := qSuch.FieldByName('betriebsauftragnr').AsString;
    Nr := qSuch.FieldByName('nr').AsInteger;
    if baNr <> '' then
    begin
      s := 'SELECT CASE WHEN max(kavitaet_soll) IS null THEN -1 ELSE max(kavitaet_soll) END mkav '
        + ' FROM aarchiv WHERE betriebsauftragnr = ''' + BANr + '''';
      SQL_Get(qSuch2, S);

      kav := qSuch2.FieldByName('mkav').AsInteger;

      if kav < 1 then
        S := 'Update tpm_schicht SET kav_soll=kavitaet where tpm_schicht.nr = ' + IntToStr(nr)
      else
        S := 'Update tpm_schicht SET kav_soll=' + IntToStr(kav) + ' where tpm_schicht.nr = ' + IntToStr(nr);
      try
        SQL_Insert(qUpdate, S);
      except
      end;
    end
    else
    begin
      S := 'Update tpm_schicht SET kav_soll = 1 where nr = ' + IntToStr(nr);
      try
        SQL_Insert(qUpdate, S);
      except
      end;
    end;
    qSuch.Next;
  end;
        *)
  if detailed then
    SchreibeMeldung('Step 4-681', 3);

  if not TCO_Setup.GetParamBool(qSuch, 'INCL_SkipRecalcAndSetuptimesWithCalendar') then
  begin
  // Rüstdauer berechnen
    Gefunden := False;
    S := 'select lizenz, rueststart, abruest + vorruest + ruestkorr ruefaktor, betriebsauftragnr, grund, '
      + ' CASE WHEN ruestende < 1 THEN ' + FloatToPunktString(N_o_w) + ' ELSE ruestende END ruestende'
      + ' , nr from RuestProt where (RuestIst is null) or (RuestIst < 0) or (RuestEnde is Null) or (RuestEnde = 0)';
    SQL_Get(qSuch, S);
    while not qSuch.EOF do
    begin
      Gefunden := True;
      Liz := qSuch.FieldByName('Lizenz').AsString;
      BANr := qSuch.FieldByName('betriebsauftragnr').AsString;
      A := qSuch.FieldByName('RuestStart').AsFloat;
      grund := qSuch.FieldByName('grund').AsInteger;
      B := GFloat(qSuch.FieldByName('RuestEnde').AsString);
      if B = 0 then
        B := N_o_w;
      M := ZeitInMinuten(Liz, A, B) + qSuch.FieldByName('ruefaktor').AsInteger;

      S := 'update RuestProt set RuestIst = ' + IntToStr(M) + ' where Nr = ' + qSuch.FieldByName('Nr').AsString;
      SQL_Insert(qUpdate, S);

      S := 'update RUESTPROT set RUEST_GESAMT_AUFTRAG ='
        + ' (select sum(RUESTIST) from RUESTPROT x1 where RUESTPROT.BetriebsAuftragNr = x1.BetriebsAuftragNr)'
        + ' where RUEST_GESAMT_AUFTRAG <>'
        + ' (select sum(RUESTIST) from RUESTPROT x1 where RUESTPROT.BetriebsAuftragNr = x1.BetriebsAuftragNr)'
        + ' AND betriebsauftragnr = ''' + qSuch.FieldByName('betriebsauftragnr').AsString + '''';
      SQL_Insert(qUpdate, S);

      // Anfahrausschuss berechnen. Zyklen, Kavität und Var_Kav beachten
      S := 'SELECT pde.anfahr_ausschuss, pde.kopfgroesse, pde.var_kavitaet, maschine.maschnr '
        + ' FROM pde '
        + ' LEFT JOIN MASCHINE on pde.LIZENZ=maschine.lizenz '
        + ' WHERE pde.betriebsauftragnr = ''' + banr + '''';
      SQL_Get(qSuch2,s);
      if not qSuch2.IsEmpty then
      begin
        suscrap := qSuch2.FieldByName('anfahr_ausschuss').AsInteger;
        kav := qSuch2.FieldByName('kopfgroesse').AsInteger;
        varkav := qSuch2.FieldByName('var_kavitaet').AsInteger;
        if not qSuch2.FieldByName('maschnr').IsNull then // wenn null dann offline Maschine
        begin
          maschnr := qSuch2.FieldByName('maschnr').AsInteger;
          S := 'SELECT SUM(zyklen) sumzyk, SUM(STUECK) sumstk FROM ruestprot '
            + ' WHERE betriebsauftragnr = ''' + banr + ''' AND nr <> ' + qSuch.FieldByName('Nr').AsString;
          SQL_Get( qSuch3,s);
          if not qSuch3.IsEmpty then
          begin
            sustk := qSuch3.FieldByName('sumstk').AsInteger;
            suzyk := qSuch3.FieldByName('sumzyk').AsInteger;

            // Anfahrausschuss = anfahrausschussaktuell + sustk;
            sustk := suscrap - sustk; // Jetzt zu buchende Stückzahl
            if sustk < 0 then
              sustk :=0;
            if kav <> 0 then
              suzyk := trunc((sustk / kav) * varkav)
            else
              suzyk := 0;
            if (grund = 0) then
            begin
              S := 'SELECT stillstandnr FROM tpm_stillog WHERE maschnr = ' + IntToStr(maschnr) + ' AND geht < 1';
              SQL_Get(qSuch3, s);
              if not qSuch3.IsEmpty then
                grund := qSuch3.FieldByName('stillstandnr').AsInteger;
            end
            else
              grund := 0;
            S := 'update RuestProt set stueck = ' + IntToStr(sustk)
              + ', zyklen = ' + IntToStr(suzyk);
            if (grund > 0) then
              s := s + ', grund = ' + IntToStr(grund);
            S := s  + ' where Nr = ' + qSuch.FieldByName('Nr').AsString;
            SQL_Insert(qUpdate, S);
          end;
        end;
      end;
      qSuch.Next;
    end;

    if detailed then
      SchreibeMeldung('Step 4-713', 3);

    // Schreiben in AArchiv
    S := 'select * from RuestProt where RuestEnde > 0 and TO_AArchiv = 0 and Length(BetriebsAuftragNr) > 0';
    SQL_Get(qSuch, S);
    while not qSuch.EOF do
    begin
      S := 'update AArchiv set RuestzeitIst = ''' + qSuch.FieldByName('Ruest_Gesamt_Auftrag').AsString + ''''
        + ' where BetriebsAuftragNr = ''' + qSuch.FieldByName('BetriebsAuftragNr').AsString + '''';
      SQL_Insert(qUpdate, S);

      S := 'update AArchiv set RuestzeitDiff = RuestzeitIst - RuestzeitSoll'
        + ' where BetriebsAuftragNr = ''' + qSuch.FieldByName('BetriebsAuftragNr').AsString + '''';
      SQL_Insert(qUpdate, S);

      S := 'update RuestProt set TO_AArchiv = 1'
        + ' where BetriebsAuftragNr = ''' + qSuch.FieldByName('BetriebsAuftragNr').AsString + ''' and RuestEnde > 0';
      SQL_Insert(qUpdate, S);

      qSuch.Close;
      qSuch.Open;
    end;
    qSuch.Close;
  end;

  if detailed then
    SchreibeMeldung('Step 4-740', 3);

  // AuftragNr in TPM_Schicht ausfühlen
  S := 'select TPM_Schicht.Nr, TPM_Schicht.AuftragNr ANr, AArchiv.AuftragNr AANr from TPM_Schicht, AArchiv'
    + ' where TPM_Schicht.BetriebsAuftragNr = AARchiv.BetriebsAuftragNr and TPM_Schicht.AuftragNr is null';
  SQL_Get(qSuch, S);
  while not qSuch.EOF do
  begin
    S := 'update TPM_Schicht set AuftragNr = ''' + qSuch.FieldByName('AANr').AsString + ''''
      + ' where Nr = ' + qSuch.FieldByName('Nr').AsString;
    SQL_Insert(qUpdate, S);
    qSuch.Next;
  end;
  qSuch.Close;

  // Stillstandsblöcke (Novapax)
  SQL_Get(qSuch, 'select * from Setup');
  Bl := qSuch.FieldByName('Stillstandsbloecke').AsInteger;
  if Bl > 0 then
  begin
    S := 'select TP1.Nr Nr1, TP2.Nr Nr2, TP1.Kommt K1, TP1.Geht G1,'
      + ' TP2.Kommt K2, TP2.Geht G2, TP1.Notiz N1, TP2.Notiz N2,'
      + ' TP1.StillstandNr St1, TP2.StillstandNr St2, TS1.Geplant Gp1, TS2.Geplant Gp2'
      + ' from TPM_Stillog TP1, TPM_Stillog TP2, TPM_Stillstaende TS1, TPM_Stillstaende TS2'
      + ' where TP1.MaschNr = TP2.MaschNr'
      + ' and TP1.StillstandNr = TS1.StillstandNr and TP2.StillstandNr = TS2.StillstandNr and TS1.Geplant = TS2.Geplant'
      + ' and TP1.Nr <> TP2.Nr'
      + ' and TP1.Kommt < TP2.Kommt'
      + ' and TP1.Geht > 0 and TP2.Geht > 0 and TP2.Kommt - TP1.Geht < ' + IntToStr(Bl) + '/1440'
      + ' and (TP1.Geht - TP1.Kommt < ' + IntToStr(Bl) + '/1440 or TP2.Geht - TP2.Kommt < ' + IntToStr(Bl) + '/1440)';
    SQL_Get(qSuch, S);

    if detailed then
      SchreibeMeldung('Step 4-771', 3);

    while not qSuch.EOF do
    begin
      Notiz := qSuch.FieldByName('N1').AsString;
      if Notiz = '' then
        Notiz := DateTimeToStr(qSuch.FieldByName('K1').AsFloat) + ' - ' +
          DateTimeToStr(qSuch.FieldByName('G1').AsFloat);
      Notiz := Notiz + #13#10;

      if qSuch.FieldByName('N2').AsString <> '' then
        Notiz := Notiz + qSuch.FieldByName('N2').AsString
      else
        Notiz := Notiz + DateTimeToStr(qSuch.FieldByName('K2').AsFloat) + ' - '
          + DateTimeToStr(qSuch.FieldByName('G2').AsFloat);

      S := 'update TPM_Stillog set Geht = ' + FloatToPunktString(qSuch.FieldByName('G2').AsFloat) + ','
        + ' GehtStr = null, Dauer = 0, Notiz = ''' + Notiz + ''', Block = ''X'','
        + ' StillstandNr = 1'
        + ' where Nr = ' + qSuch.FieldByName('Nr1').AsString;
      SQL_Insert(qUpdate, S);

      S := 'delete from TPM_Stillog'
        + ' where Nr = ' + qSuch.FieldByName('Nr2').AsString;
      SQL_Insert(qUpdate, S);

      qSuch.Next;
    end;
  end;
  qSuch.Close;

  if detailed then
    SchreibeMeldung('Step 4-804', 3);

  // Korrektur für den ersten Takt
  S := 'select Lizenz, Avg(Taktzeit) Takt from Taktzeiten where Schuss > 1 group by Lizenz';
  SQL_Get(qSuch, S);
  while not qSuch.EOF do
  begin
    S := FloatToPunktString(qSuch.FieldByName('Takt').AsFloat);
    s2 :=   S + GetL(' s');
    if (length(s2) > 10) then
      s2 := Copy(s2,1,8) + GetL(' s');
    S := 'update Taktzeiten set Taktzeit = ' + S + ','
      + ' TaktzeitStr = ''' + S2 + ''''
      + ' where Schuss = 1 and Lizenz = ''' + qSuch.FieldByName('Lizenz').AsString + '''';
    SQL_Insert(qUpdate, S);
    qSuch.Next;
  end;

  S := 'update TPM_Stillog set Dauer = Round((Geht-Kommt)*1440)'
    + ' where Geht > 0 and (Dauer is Null or Dauer <= 0)';
  SQL_Insert(qUpdate, S);

  S := 'delete from TPM_Stillog where Kommt = 0';
  SQL_Insert(qUpdate, S);

  S := 'update TPM_Stillog set StillstandNr = 1 where StillstandNr is Null';
  SQL_Insert(qUpdate, S);

  S := 'delete from TPM_Stillog where MaschNr = 0';
  SQL_Insert(qUpdate, S);

  S := 'update PDE set Kavitaet_Soll = Kopfgroesse where Kavitaet_Soll is null';
  SQL_Insert(qUpdate, S);

  S := 'update Maschinf set Kavitaet_Soll = Kavitaet where Kavitaet_Soll=0';
  SQL_Insert(qUpdate, S);

  S := 'delete from Maschinf where Lizenz not in'
    + ' (select Lizenz from Maschine union select Lizenz from MaschOffline)'
    + ' AND Lizenz NOT LIKE ''% W2''';
  SQL_Insert(qUpdate, S);

  if detailed then
    SchreibeMeldung('Step 4-845', 3);

  //23.07.2013 RS: Notnagel SUH: In Tpm_Stillog liegen verwaiste offene Stillstände. Hierüber bereinigen wir
  {$ifdef INCL_ORA}
    try
    (* Funktioniert nicht korrekt !!!
      SQLStr := 'DELETE FROM tpm_stillog WHERE nr IN ('
              + ' SELECT nr'
              + ' FROM'
              + ' ('
              + '  SELECT maschnr,  LAG(maschnr) OVER (ORDER BY maschnr, kommt)prevm,'
              + '         kommt,LAG(kommt) OVER (ORDER BY maschnr, kommt)prevk, '
              + '         geht, LAG(geht) OVER (ORDER BY maschnr, kommt)prevg,'
              + '         nr, LAG(nr) OVER (ORDER BY maschnr, kommt)prevn,'
              + '         stillstandnr,LAG(stillstandnr) OVER (ORDER BY maschnr, kommt)prevs'
              + '         from tpm_stillog'
              + ' ) '
              + ' WHERE prevm = maschnr '
              + ' AND ((kommt > prevk and kommt < case WHEN prevg is null or prevg = 0 THEN 99999 ELSE prevg END ) OR'
              + '      (prevk > kommt and  prevk < case WHEN geht is null or geht = 0 THEN 99999 ELSE geht END) )'
              + ' AND (geht = 0 OR geht is null)'
              + ')' ;
      SQL_Insert(qUpdate, SQLStr);
      *)
    except on e: Exception do
      SchreibeMeldung(e.Message + ' on purging tpm_stillog', 0);
    end;
  if detailed then
      SchreibeMeldung('Step 4-860', 3);
  {$endif}
end;
// *****************************************************************************

procedure TThread_Zusatz.ArbeitsFrei_Buchen;
var
  Stillstandnr, Schicht, LetzteSchicht, MaschNr: Integer;
  KeinWPBeiLZ, B,
  LetzteSchichtArbeitsfrei, AktuellArbeitsfrei, CheckArbeitsfrei, EndeStillUndNeu, VorSchichtStillstandBuchen: Boolean;
  S, Liz, Nr: string;
  kommt, LastZusatzRun, LastShiftChange, LaengeLetzteSchicht, realdummy, schichtstartref: Real;
  StillNr, Nr2: Integer;
  Prod, Schuss, mnr : INteger;
  BUCHEN_ARBEITSFREI_BIS: Boolean;
  Jetzt : TDateTime;
  AFGesperrtArray : array[1..Max_ANZAHL] of Extended;

  Ini : TIniFile;
  //  ARBEITSFREINACHKALENDER: Boolean;
begin
  try
    Ini := TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'incl_' + DBUser + '.ini');
    LastShiftChange := Ini.ReadFloat('System', 'last_shift_change', 0);
    LastZusatzRun := Ini.ReadDateTime('AddOns', 'LastRun', now);
    Ini.Free;
  except
  end;

  SQL_Get(qSuch, 'SELECT maschid, afgesperrtbis FROM maschine');
  while not qSuch.eof do
  begin
    mnr := qSuch.FieldByName('maschid').AsInteger;
    if mnr < Max_Anzahl then
      AFGesperrtArray[mnr] := qSuch.FieldByName('afgesperrtbis').AsFloat;
    qSuch.Next;
  end;

  Jetzt := N_o_w;
  KeinWPBeiLZ := TCO_Setup.GetParamBool(qSuch, 'INCL_KeinWP_Bei_Laufzeit_In_Schicht');
  // Arbeitsfrei nur buchen, wenn kein Laufzeit in der Schicht vorhanden
  // Wenn Laufzeit vorhanden nur den letzten / ersten Stillstand der Schicht
  // der über die Schicht hinaus geht
  // Es werden nur Stillstände Arbeitsfrei gebucht, bei denen das Startdatum < Schichtstart + 1 Minute
  if KeinWPBeiLZ then
    schichtstartref := Trunc(N_o_w) + GetSchichtStartFloat(GetSchichtNr(Jetzt)) + 1 / 1440
  else
    schichtstartref := N_o_w; // Wenn nicht, dann ist kommt immer kleiner als N_o_w

  S := 'select BUCHEN_ARBEITSFREI_BIS from Setup';
  SQL_Get(qSuch, S);

  BUCHEN_ARBEITSFREI_BIS := (qSuch.FieldByName('BUCHEN_ARBEITSFREI_BIS').AsInteger = 1);
  S := 'select * from TPM_Stillog '
   + ' where Geht = 0 AND kommt < '
    + FloatToPunktString(Jetzt) + ' order by MaschNr';
  SQL_Get(qSuch, S);
  if KeinWPBeiLZ then
  begin
    if LastZusatzRun < LastShiftChange then
    begin
      while not qSuch.EOF do
      begin
        MaschNr := qSuch.FieldByName('MaschNr').AsInteger;
        Stillstandnr := qSuch.FieldByName('StillstandNr').AsInteger;
        Liz := TTT_GetMaschine(MaschNr);
        Nr := qSuch.FieldByName('Nr').AsString;
        Nr2 := qSuch.FieldByName('Nr').AsInteger;
        Schuss := qSuch.FieldByName('schusszaehler').AsInteger;
        Prod := qSuch.FieldByName('Prodzaehler').AsInteger;
        AktuellArbeitsfrei := (isMomentArbeitsFrei(GetGruppe(Liz), Jetzt)) and (AFGesperrtArray[MaschNr] < Jetzt);
        Schicht := GetSchichtNr(Liz,Jetzt);
        realdummy := GetSchichtStartFloat(GetGruppe(Liz), Schicht);
        LetzteSchicht := GetSchichtNr(Liz, realdummy - 1/24);
        realdummy := realdummy + trunc(now);
        LetzteSchichtArbeitsfrei := isMomentArbeitsFrei(GetGruppe(Liz),realdummy - 1/24);
        if AFGesperrtArray[MaschNr] > Jetzt then
          LetzteSchichtArbeitsfrei := false;
        if LetzteSchichtArbeitsfrei then // Vorgängerschicht war Arbeitsfrei
        begin
          // Liegt Stillstand Anfang 1/2 in letzter Schicht ?
          LaengeLetzteSchicht := 0;
          if Schicht = 1 then
            LaengeLetzteSchicht := (Schicht1 + 1) -Schicht3;
          if Schicht = 2 then
            LaengeLetzteSchicht := Schicht2  - Schicht1;
          if Schicht = 3 then
            LaengeLetzteSchicht := Schicht3  - Schicht2;
          CheckArbeitsfrei := false;
          EndeStillUndNeu := false;
          VorSchichtStillstandBuchen := false;

        //  if (Jetzt - (LaengeLetzteSchicht / 2)) > qSuch.FieldByName('kommt').AsFloat then
//          begin
            if StillstandNr = 1 then
            begin
              ChangeDtCode(qUpdate, 3, Nr2, true, 'AF960');
              CheckArbeitsfrei := True
            end
            else
            begin
              if StillstandNr = 3 then   // Letzter Stillstand Arbeitsfrei gebucht
                CheckArbeitsfrei := True
              else // Nur neuen erzeugen wenn gebuchter Stillstand <> Arbeitsfrei und aktuell Arbeitsfrei anliegt
                EndeStillUndNeu := AktuellArbeitsfrei;
            end;
        //  end
        //  else
        //      CheckArbeitsfrei := True;
          if CheckArbeitsfrei then
            if not AktuellArbeitsfrei then
            begin
              EndeStillUndNeu := true;
              VorSchichtStillstandBuchen := true;
            end;

          if EndeStillUndNeu then
          begin // aktuellen Stillstand zum Schichtwechsel beenden und neuen erzeugen
            S := 'update TPM_Stillog set geht = ' +  FloatToPunktString (LastShiftChange)
              + ' where Nr = ' + Nr;
              SQL_Insert(qUpdate, S);

            S := 'insert into TPM_Stillog (Nr, MaschNr, Kommt, Geht, Stillstandnr, schusszaehler, prodzaehler) values (TPM_StillogID.Nextval,'
              + ' ' + IntToStr(MaschNr) + ','
              + ' ' + FloatToPunktString (LastShiftChange) + ','
              + ' 0,'
              + ' 1, ' + IntToStr(Schuss)
          + ',' + IntToStr(Prod) + ')';
              

            SQL_Insert(qUpdate, S);
          end;

          if VorSchichtStillstandBuchen then // Aktuellen Stillstand mit altem Grund buchen
          begin
            if TCO_Setup.GetParamBool(qSuch, 'INCL_Autobuchen_nach_Arbeitsfrei') then
            begin
              S := 'select * from TPM_Stillog where MaschNr = ' + IntToStr(MaschNr) + ' order by Kommt Desc';
              SQL_Get(qSuch2, S);

              Nr2 := qSuch2.FieldByName('Nr').AsInteger;
              qSuch2.Next;
              if qSuch2.FieldByName('StillstandNr').AsInteger = 3 then
              begin
                while qSuch2.FieldByName('StillstandNr').AsInteger = 3 do
                  qSuch2.Next;
                if qSuch2.FieldByName('StillstandNr').AsInteger = 5 then
                  StillNr := 1
                else
                  StillNr := qSuch2.FieldByName('StillstandNr').AsInteger;
                // Bei letztem Stillstand Kurzstörung Stillstand nicht gebucht buchen
                ChangeDtCode(qUpdate, StillNr, Nr2, true, 'AF1016');
              end;
            end;
          end;
        end
        else
        begin
          if AktuellArbeitsfrei then
          begin
              // Stillstand beenden und neuen ungebuchten hinzufügen
               S := 'update TPM_Stillog set geht = ' +  FloatToPunktString (LastShiftChange)
              + ' where Nr = ' + Nr;
              SQL_Insert(qUpdate, S);

            S := 'insert into TPM_Stillog (Nr, MaschNr, Kommt, Geht, Stillstandnr, schusszaehler, prodzaehler) values (TPM_StillogID.Nextval,'
              +  IntToStr(MaschNr) + ', '
              +  FloatToPunktString (LastShiftChange) + ', '
              + ' 0,'
              + ' 1, ' + IntToStr(Schuss)
          + ',' + IntToStr(Prod) + ')';
              

            SQL_Insert(qUpdate, S);
          end;
        end;

        qSuch.Next;
      end;
    end;
  end
  else
  begin
    while not qSuch.EOF do
    begin
      MaschNr := qSuch.FieldByName('MaschNr').AsInteger;

      if MaschNr <= Max_ANZAHL then
      begin
        Stillstandnr := qSuch.FieldByName('StillstandNr').AsInteger;
        Liz := TTT_GetMaschine(MaschNr);
        Nr := qSuch.FieldByName('Nr').AsString;
        B := isMomentArbeitsFrei(GetGruppe(Liz), Jetzt);

        if AFGesperrtArray[MaschNr] > Jetzt then
          b := false;

        kommt := qSuch.FieldByName('kommt').AsFloat;
        Schuss := qSuch.FieldByName('schusszaehler').AsInteger;
        Prod := qSuch.FieldByName('Prodzaehler').AsInteger;

        if (not b) and (Stillstandnr = 3) and (JetztArbeitsfrei[MaschNr]=0)
          and (kommt < Trunc(N_o_w) + GetSchichtStartFloat(GetSchichtNr(Jetzt)) - 1 / 1440)
          and isMomentArbeitsfrei(GetGruppe(Liz),kommt) then // scheinbar Arbeitsfrei nicht beendet
        begin

          S := 'update TPM_Stillog set Geht = ' + FloatToPunktString(Trunc(N_o_w) + GetSchichtStartFloat(GetSchichtNr(Jetzt))) + ' where Nr = ' + Nr;
        SQL_Insert(qUpdate, S);

        if BUCHEN_ARBEITSFREI_BIS then
          StillNr := 3
        else
          StillNr := 1;

        S := 'insert into TPM_Stillog (Nr, MaschNr, Kommt, Geht, Stillstandnr, schusszaehler, prodzaehler) values (TPM_StillogID.Nextval,'
          + ' ''' + IntToStr(MaschNr) + ''','
          + ' ' + FloatToPunktString(Trunc(N_o_w) + GetSchichtStartFloat(GetSchichtNr(Jetzt))) + ','
          + ' ''0'','
          + ' ''' + IntToStr(StillNr) + ''', ' + IntToStr(Schuss)
          + ',' + IntToStr(Prod) + ')';


        SQL_Insert(qUpdate, S);
        TTT_ErstelldatumEinfuegen(qUpdate, qSuch3, 7);

        if not B then
          if TCO_Setup.GetParamBool(qSuch, 'INCL_Autobuchen_nach_Arbeitsfrei') then
          begin

            S := 'select * from TPM_Stillog where MaschNr = ' + IntToStr(MaschNr) + ' order by Kommt Desc';
            SQL_Get(qSuch2, S);

            Nr := qSuch2.FieldByName('Nr').AsString;
            Nr2 := qSuch2.FieldByName('Nr').AsInteger;
            qSuch2.Next;
            if qSuch2.FieldByName('StillstandNr').AsInteger = 3 then
            begin
              while ((qSuch2.FieldByName('StillstandNr').AsInteger = 3) or
                (qSuch2.FieldByName('StillstandNr').AsInteger = 7)) // Pause natürlich auch ignorieren.
                and (not qSuch2.Eof) do
                qSuch2.Next;
              if qSuch2.FieldByName('StillstandNr').AsInteger = 5 then
                StillNr := 1
              else
                StillNr := qSuch2.FieldByName('StillstandNr').AsInteger;
              // Bei letzztem Stillstand Kurzstörung Stillstand nicht gebucht buchen
              ChangeDtCode(qUpdate, StillNr, Nr2, true, 'AF1103');

            end;
          end;
        end;


        if ((JetztArbeitsfrei[MaschNr] = 1) <> B) and (JetztArbeitsfrei[MaschNr] > -1) then
        begin
          S := 'update TPM_Stillog set Geht = ' + FloatToPunktString(N_o_w) + ' where Nr = ' + Nr;
          SQL_Insert(qUpdate, S);

          if BUCHEN_ARBEITSFREI_BIS then
            StillNr := 3
          else
            StillNr := 1;

          S := 'insert into TPM_Stillog (Nr, MaschNr, Kommt, Geht, Stillstandnr, schusszaehler, prodzaehler) values (TPM_StillogID.Nextval,'
            + ' ''' + IntToStr(MaschNr) + ''','
            + ' ' + FloatToPunktString(Jetzt) + ','
            + ' ''0'','
            + ' ''' + IntToStr(StillNr) + ''', ' + IntToStr(Schuss)
            + ',' + IntToStr(Prod) + ')';


          SQL_Insert(qUpdate, S);

          TTT_ErstelldatumEinfuegen(qUpdate, qSuch3, 7);

          if not B then
            if TCO_Setup.GetParamBool(qSuch, 'INCL_Autobuchen_nach_Arbeitsfrei') then
            begin

              S := 'select * from TPM_Stillog where MaschNr = ' + IntToStr(MaschNr) + ' order by Kommt Desc';
              SQL_Get(qSuch2, S);

              Nr2 := qSuch2.FieldByName('Nr').AsInteger;
              Nr := qSuch2.FieldByName('Nr').AsString;
              qSuch2.Next;
              if qSuch2.FieldByName('StillstandNr').AsInteger = 3 then
              begin
                while (qSuch2.FieldByName('StillstandNr').AsInteger = 3) and (not qSuch2.Eof) do
                  qSuch2.Next;
                if qSuch2.FieldByName('StillstandNr').AsInteger = 5 then
                  StillNr := 1
                else
                  StillNr := qSuch2.FieldByName('StillstandNr').AsInteger;
                // Bei letzztem Stillstand Kurzstörung Stillstand nicht gebucht buchen
                ChangeDtCode(qUpdate, StillNr, Nr2, true, 'AF1152');
              end;
            end;
        end
        else
        begin

          if (LastDate > 0) and (GetSchichtNr(LastDate) <> GetSchichtNr(Now)) then
            if TCO_Setup.GetParamBool(qSuch, 'INCL_Stillstand_beim_Schichtwechsel') then
            begin

              S := 'update TPM_Stillog set Geht = ' + FloatToPunktString(Now) + ' where Nr = ' + Nr;
              SQL_Insert(qUpdate, S);

              S := 'insert into TPM_Stillog (Nr, MaschNr, Kommt, Geht, Stillstandnr, schusszaehler, prodzaehler) values (TPM_StillogID.Nextval,'
                + ' ''' + IntToStr(MaschNr) + ''','
                + ' ' + FloatToPunktString(Jetzt) + ','
                + ' ''0'','
                + ' ''1'', ' + IntToStr(Schuss)
                + ',' + IntToStr(Prod) + ')';

              SQL_Insert(qUpdate, S);

              TTT_ErstelldatumEinfuegen(qUpdate, qSuch3, 7);

            end;

          if (LastDate > 0) and (Trunc(Frac(LastDate) * 24) <> Trunc(Frac(Now) * 24)) then
            if TCO_Setup.GetParamInt(qSuch, 'INCL_Stillstand_24h') = Trunc(Frac(Now) * 24) then
            begin

              S := 'update TPM_Stillog set Geht = ' + FloatToPunktString(Now) + ' where Nr = ' + Nr;
              SQL_Insert(qUpdate, S);

              S := 'insert into TPM_Stillog (Nr, MaschNr, Kommt, Geht, Stillstandnr, schusszaehler, prodzaehler) values (TPM_StillogID.Nextval,'
                + ' ''' + IntToStr(MaschNr) + ''','
                + ' ' + FloatToPunktString(Now) + ','
                + ' ''0'','
                + ' ''' + IntToStr(Stillstandnr) + ''', ' + IntToStr(Schuss)
                + ',' + IntToStr(Prod) + ')';

              SQL_Insert(qUpdate, S);

              TTT_ErstelldatumEinfuegen(qUpdate, qSuch3, 7);

            end;
          end;
      end;
      qSuch.Next;
    end;

    // ARBEITSFREINACHKALENDER := TCO_Setup.GetParamBool(qUpdate, 'INCL_ArbeitsfreiStartNachKalender');

    S := 'select * from TPM_Stillog where Geht = 0 and StillstandNr = 1 '
      + ' order by MaschNr';

    SQL_Get(qSuch, S);
    while not qSuch.EOF do
    begin

      MaschNr := qSuch.FieldByName('MaschNr').AsInteger;
      Liz := TTT_GetMaschine(MaschNr);
      Nr := qSuch.FieldByName('Nr').AsString;
      Nr2 := qSuch.FieldByName('Nr').AsInteger;
      B := isMomentArbeitsFrei(GetGruppe(Liz), Jetzt);

      if AFGesperrtArray[MaschNr] > Jetzt then
        b := false;

      if B then
      begin

        //      if (not ARBEITSFREINACHKALENDER) then
        //begin
        ChangeDtCode(qUpdate, 3, Nr2, True, 'AF1225');

        //end;

        JetztArbeitsfrei[MaschNr] := 1;
      end;
      qSuch.Next;
    end;
  end;

  S := 'select * from Maschine order by MaschId';
  SQL_Get(qSuch, S);

  while not qSuch.EOF do
  begin
    MaschNr := qSuch.FieldByName('MaschNr').AsInteger;
    Liz := TTT_GetMaschine(MaschNr);

    if isMomentArbeitsFrei(GetGruppe(Liz), Jetzt) then
      JetztArbeitsfrei[MaschNr] := 1
    else
      JetztArbeitsfrei[MaschNr] := 0;

    if AFGesperrtArray[MaschNr] > Jetzt then
      JetztArbeitsfrei[MaschNr] := 0;

    qSuch.Next;
  end;

  LastDate := N_o_w;

end;
// *****************************************************************************

procedure TThread_Zusatz.WZReparatur;
var
  S, Nr, Liz: string;
begin
  //18.01.2012 RS: Statusint wird nur gezogen, wenn SetupPar-Schalter "INCL_MoldStateFromStateInt" sitzt
  if TCO_Setup.GetParamBool(qSuch, 'INCL_MoldStateFromStateInt') then
    S := 'select Reparatur.* from Werkzeug, Reparatur'
      + ' where Werkzeug.Werkzeug = Reparatur.WerkzeugIndex'
      //02.12.2011 RS: Ergänzung StatusInt
      + ' and Werkzeug.StatusInt = 0 and Reparatur.EndeRepInt = 0 and Reparatur.AnfangRepInt > 0'
      //+ ' and Werkzeug.Status = ''' + GetL('Lager') + ''' and Reparatur.EndeRepInt = 0'
  else
    S := 'select Reparatur.* from Werkzeug, Reparatur'
      + ' where Werkzeug.Werkzeug = Reparatur.WerkzeugIndex'
      + ' and Werkzeug.Status = ''' + GetL('Lager') + ''' and Reparatur.EndeRepInt = 0 and Reparatur.AnfangRepInt > 0';

  SQL_Get(qSuch, S);
  while not qSuch.EOF do
  begin
    Nr := qSuch.FieldByName('Nr').AsString;
    S := 'update Reparatur set Status = ''' + GetL('Erledigt') + ''','
      + ' EndeRep = ''' + DateToStr(N_o_w) + ''','
      + ' EndeRepInt = ''' + FloatToStr2(N_o_w) + ''''
      + ' where Nr = ' + Nr;
    SQL_Insert(qUpdate, S);
    qSuch.Next;
  end;

  S := 'select * from Wartungen where Job_Erzeugt = 0 and StartDatumZeit <= ''' + FloatToStr2(N_o_w) + '''';
  SQL_Get(qSuch, S);
  while not qSuch.EOF do
  begin
    Nr := qSuch.FieldByName('Nr').AsString;
    Liz := qSuch.FieldByName('AnlageTyp').AsString + '-'+ qSuch.FieldByName('Anlage').AsString;

    CCC_Job_erzeugen(qUpdate, Liz, qSuch.FieldByName('WartungNr').AsString, GetL('Wartung'), GetL('Wartung'), '', '',
      False, 0);

    S := 'update Wartungen set Job_Erzeugt = 1 where Nr = ' + Nr;
    SQL_Insert(qUpdate, S);
    qSuch.Next;
  end;
end;
// *****************************************************************************

procedure TThread_Zusatz.CheckVerpacktProt;
var
  S, S1, B, eNr: string;
  A: Real;
  N: Integer;
begin
  S := 'select VerpacktProt.datum, AARchiv.enddatumzeit, VerpacktProt.Nr, pdekombi.nr pnr'
    + ' from VerpacktProt, AARchiv'
    + ' left join pdekombi on pdekombi.betriebsauftragnr=aarchiv.betriebsauftragnr '
    + ' where VerpacktProt.BetriebsAuftragNr = AARchiv.BetriebsAuftragNr'
    + ' and AARchiv.enddatumzeit > 0 and VerpacktProt.datum > AARchiv.enddatumzeit';
  SQL_Get(qSuch, S);
  while not qSuch.EOF do
  begin
    if not (qSuch.FieldByName('pnr').AsInteger > 0) then
    begin
      A := qSuch.FieldByName('EndDatumZeit').AsFloat - 5 / 1440;
      S := 'update VerpacktProt set datum = ' + FloatToPunktString(A)
        + ' where Nr = ' + qSuch.FieldByName('Nr').AsString;
      SQL_Insert(qUpdate, S);
    end;
    qSuch.Next;
  end;

  S := 'select VerpacktProt.*, AARchiv.Maschine AMaschine, AARchiv.AuftragNr AAuftragNr,'
    + ' AARchiv.Bezeichnung ABezeichnung from VerpacktProt, AArchiv'
    + ' where VerpacktProt.BetriebsAuftragNr = AArchiv.BetriebsAuftragNr and VerpacktProt.AuftragNr is null'
    + ' and Length(Barcode) = 13';
  SQL_Get(qSuch, S);
  while not qSuch.EOF do
  begin
    B := qSuch.FieldByName('Barcode').AsString;
    if Length(B) = 13 then
    begin
      if B[12] = '0' then
        S1 := GetL('Karton')
      else if B[12] = '1' then
        S1 := GetL('Palette')
      else
        S1 := '';

      eNr := Copy(B, 8, 4);

      S := 'select * from BCDruck_Puffer'
        + ' where BetriebsAuftragNr = ''' + qSuch.FieldByName('BetriebsAuftragNr').AsString + ''''
        + ' and StartNr <= ' + eNr + ' and EndeNr >= ' + eNr;
      SQL_Get(qSuch2, S);
      if not qSuch2.EOF then
      begin
        N := StrToInt(eNr) - qSuch2.FieldByName('StartNr').AsInteger + qSuch2.FieldByName('EinheitNr').AsInteger;

        S := 'update VerpacktProt set'
          + ' Art = ''' + S1 + ''','
          + ' EinheitNr = ' + IntToStr(N) + ','
          + ' Zugang = ' + qSuch2.FieldByName('Menge').AsString + ','
          + ' Abgang = 0,'
          + ' Bezeichnung = ''' + qSuch.FieldByName('ABezeichnung').AsString + ''','
          + ' Maschine = ''' + qSuch.FieldByName('AMaschine').AsString + ''','
          + ' AuftragNr = ''' + qSuch.FieldByName('AAuftragNr').AsString + ''''
          + ' where Nr = ' + qSuch.FieldByName('Nr').AsString;
        SQL_Insert(qUpdate, S);
      end;
    end;
    qSuch.Next;
  end;

  if Packen then
  begin
    S := 'update AARchiv set VerpacktInt = 0 where VerpacktInt is null';
    SQL_Insert(qUpdate, S);

    S := 'update AArchiv set Ausschuss = ProduziertInt - VerpacktInt'
      + ' where (EndDatumZeit = 0 or EndDatumZeit >= ''' + FloatToStr2(Trunc(N_o_w - 30)) + ''')';
    SQL_Insert(qUpdate, S);

    S := 'update AArchiv set AusschussPrz = Round(Ausschuss / ProduziertInt * 100) where ProduziertInt > 0'
      + ' and (EndDatumZeit = 0 or EndDatumZeit >= ''' + FloatToStr2(Trunc(N_o_w - 30)) + ''')';
    SQL_Insert(qUpdate, S);

    S := 'update AArchiv set AusschussPrz = 0 where ProduziertInt = 0'
      + ' and (EndDatumZeit = 0 or EndDatumZeit >= ''' + FloatToStr2(Trunc(N_o_w - 30)) + ''')';
    SQL_Insert(qUpdate, S);

    S := 'update AArchiv set Qualitaet = Round(VerpacktInt / ProduziertInt * 100) where ProduziertInt > 0'
      + ' and (EndDatumZeit = 0 or EndDatumZeit >= ''' + FloatToStr2(Trunc(N_o_w - 30)) + ''')';
    SQL_Insert(qUpdate, S);

    S := 'update AArchiv set Qualitaet = 0 where ProduziertInt = 0'
      + ' and (EndDatumZeit = 0 or EndDatumZeit >= ''' + FloatToStr2(Trunc(N_o_w - 30)) + ''')';
    SQL_Insert(qUpdate, S);
  end;
end;
// *****************************************************************************

/// <summary>
/// Funktion überprüft aTage zurück, ob Verpacktbuchungen zu
/// einer früheren Schicht zuzuordnen sind
/// </summary>
/// <param name="aTage">Anzahl der Tage die zurück berechnet werden soll</param>

function TThread_Zusatz.CheckPackSchicht(aTage: Integer): integer;
var
  S, BANr: string;
  DT, Schicht_Dauer: Real;
  Stueck, Schicht, Nr: Integer;
begin
  result := 0;
  if aTage > 0 then
  begin
    S := 'SELECT nr, datumzeit, betriebsauftragnr, schicht FROM tpm_schicht WHERE datumzeit > ' + FloatToPunktString(N_o_w - aTage);
    SQL_Get(qSuch, S);
    while not qSuch.EOF do
    begin
      BANr := qSuch.FieldByName('betriebsauftragnr').AsString;
      if BANr <> '' then
      begin
        DT := qSuch.FieldByName('datumzeit').AsFloat;
        Schicht := qSuch.FieldByName('schicht').AsInteger;
        if Shift_Model = 2 then
        begin
          case Schicht of
            1: Schicht_Dauer := Schicht2 - Schicht1;
            2: Schicht_Dauer := (1 + Schicht1) - Schicht2;
          else
            Schicht_Dauer := 0;
          end;
        end
        else
        begin
          case Schicht of
            1: Schicht_Dauer := Schicht2 - Schicht1;
            2: Schicht_Dauer := Schicht3 - Schicht2;
            3: Schicht_Dauer := 1 + Schicht1 - Schicht3;
          else
            Schicht_Dauer := 0;
          end;
        end;

        Nr := qSuch.FieldByName('nr').AsInteger;
        S := 'SELECT SUM(zugang-abgang) stueck FROM verpacktprot WHERE betriebsauftragnr = ''' + BANr + ''''
          + ' AND datum >= ' + FloatToPunktString(DT) + ' AND datum < ' + FloatToPunktString(DT + Schicht_Dauer);
        SQL_Get(qSuch2, S);
        result := result +1;
        Stueck := qSuch2.FieldByName('stueck').AsInteger;

        S := 'UPDATE tpm_schicht '
           + ' SET verpackt = ' + IntToStr(Stueck)
           + ' WHERE nr = ' + IntToStr(Nr);
        SQL_Insert(qUpdate, S);
        S := 'UPDATE tpm_schicht '
           + ' SET verpackt_org = verpackt'
           + ' WHERE nr = ' + IntToStr(Nr);
        SQL_Insert(qUpdate, S);
      end;
      qSuch.Next;
    end;
  end;
end;

// *****************************************************************************

procedure TThread_Zusatz.Laufzeit_Berechnen;
var
  S, Nr, Liz: string;
  D1, D2: Real;
  Zeit, Zeit_Rest: Integer;
begin
  S := 'select * from PDE';
  SQL_Get(qSuch, S);
  while not qSuch.EOF do
  begin
    Nr := qSuch.FieldByName('Nr').AsString;
    Liz := qSuch.FieldByName('Lizenz').AsString;
    D1 := qSuch.FieldByName('StartDatumZeit').AsFloat;
    D2 := qSuch.FieldByName('EndDatumZeit').AsFloat;

    Zeit := ZeitInMinuten(Liz, D1, D2);
    Zeit_Rest := ZeitInMinuten(Liz, MAX(D1, N_o_w), MAX(D2, N_o_w));

    S := 'update PDE set'
      + ' Laufzeit = ' + IntToStr(Zeit) + ','
      + ' Laufzeit_Rest = ' + IntToStr(Zeit_Rest)
      + ' where Nr = ' + Nr;
    SQL_Insert(qUpdate, S);

    qSuch.Next;
  end;
end;
// *****************************************************************************

procedure TThread_Zusatz.Book_Short_Delay;
var
  S: string;
  i : integer;
begin
  //Diese Funktion bucht automatisch alle Stillstände auf "SHORT STOP",
  //die kleiner als Setup-Parameter SHORT_DELAY_AUTO_BOOK_VALUE sind und die nicht gebucht sind.
  //Es wird die System-StillstandNr 5 verwendet

  // Falls Feld  Maschine.SHORT_DELAY > 0, dann wird das Feld SHORT_DELAY anstatt SHORT_DELAY_AUTO_BOOK_VALUE genommen.
  // Änderung von Sascha. 13.12.2006

  SchreibeMeldung('Start Shortdelay',3);
  S := 'select Sum(Short_Delay) CNT from Maschine';
  SchreibeMeldung('SQL Statement',3);

  SQL_Get(qSuch, S);
  SchreibeMeldung('Search for Config',3);

  i := qSuch.FieldByName('CNT').AsInteger;
  if i = 0 then
  begin
    S := 'SELECT count(*) cnt FROM TPM_Stillog'
      + ' where Geht > 0 and StillstandNr = 1 and (Geht - Kommt)*1440 < '
      + IntToStr(SHORT_DELAY_AUTO_BOOK_VALUE);
    SQL_Get(qSuch, S);
    SchreibeMeldung('Rows 2 update : '+ IntTostr(qSuch.FieldByName('CNT').AsInteger),3);

   S := 'SELECT ts.NR, mi.BETRIEBSAUFTRAGNR, mi.LIZENZ, mi.WERKZEUG, mi.ARTIKELNR, s.stillstand, mi.stueck, s2.stillstand alterstillstand'
      + ' FROM TPM_STILLOG  ts'
      + ' LEFT JOIN MASCHINE m ON m.maschnr = ts.maschnr'
      + ' LEFT JOIN MASCHINF mi ON m.lizenz = mi.lizenz'
      + ' LEFT JOIN TPM_STILLSTAENDE s ON s.STILLSTANDNR = 5'
      + ' LEFT JOIN TPM_STILLSTAENDE s2 ON s2.stillstandnr = ts.stillstandnr'
      + ' WHERE ts.STILLSTANDNR = 1'
      + ' AND Geht > 0 and ts.StillstandNr = 1 and (Geht - Kommt)*1440 < '
      + IntToStr(SHORT_DELAY_AUTO_BOOK_VALUE);
    SQL_Get(qSuch, S);

    i := 0;
    while not qSuch.Eof do
    begin
      ChangeDtCode(qUpdate, 5, qSuch.FieldByName('Nr').AsInteger, qSuch, 'BSD1534');
      qSuch.Next;
      i := i + 1;
    end;
    SchreibeMeldung('Short Delays (0) = ' + IntTostr(i),3);
  end
  else
  begin
   S := 'SELECT count(*) cnt FROM TPM_Stillog ts'
      + ' where ts.Nr IN'
      + ' ( SELECT TPM_Stillog.Nr'
      + '   FROM TPM_Stillog, Maschine'
      + '   WHERE TPM_Stillog.MaschNr = Maschine.MaschNr'
      + '   AND StillstandNr = 1'
      + '   AND Maschine.SHORT_DELAY > 0 and Geht > 0'
      + '   AND (Geht - Kommt)*1440 <= Maschine.SHORT_DELAY'
      + ' )';
    SQL_Get(qSuch, S);
    SchreibeMeldung('Rows 2 update : '+ IntTostr(qSuch.FieldByName('CNT').AsInteger),3);

    S := 'SELECT ts.NR, mi.BETRIEBSAUFTRAGNR, mi.LIZENZ, mi.WERKZEUG, mi.ARTIKELNR, s.stillstand, mi.stueck, s2.stillstand alterstillstand'
      + ' FROM TPM_STILLOG  ts'
      + ' LEFT JOIN MASCHINE m ON m.maschnr = ts.maschnr'
      + ' LEFT JOIN MASCHINF mi ON m.lizenz = mi.lizenz'
      + ' LEFT JOIN TPM_STILLSTAENDE s ON s.STILLSTANDNR = 5 '
      + ' LEFT JOIN TPM_STILLSTAENDE s2 ON s2.stillstandnr = ts.stillstandnr'
      + ' WHERE ts.STILLSTANDNR = 1'
      + ' AND ts.Nr in'
      + ' ( SELECT TPM_Stillog.Nr'
      + '   FROM TPM_Stillog, Maschine'
      + '   WHERE TPM_Stillog.MaschNr = Maschine.MaschNr'
      + '   AND StillstandNr = 1'
      + '   AND Maschine.SHORT_DELAY > 0 and Geht > 0'
      + '   AND (Geht - Kommt)*1440 <= Maschine.SHORT_DELAY'
      + ' )';      
    SQL_Get(qSuch, S);

    i := 0;
    while not qSuch.Eof do
    begin
      ChangeDtCode(qUpdate, 5, qSuch.FieldByName('Nr').AsInteger, qSuch, 'BSD1574');

      qSuch.Next;
      i := i + 1;
    end;
  end;
  SchreibeMeldung('Rows updated : '+ IntTostr(i),3);

  SchreibeMeldung('End Shortdelay',3);
end;
// *****************************************************************************

procedure TThread_Zusatz.Check_TaktLog;
const
  ANZ_WERTE = 20;
var
  ANr, S: string;
  TaktMittel, TolHigh, TolLow: Real;
begin
  //Diese Funktion entfernt Aussreisser im Taktzeitprotokoll.
  //Die Funktion wird über die Setup-Schalter TACKTLOG_CHECK und TACKTLOG_CHECK_TOLERANZ
  //gesteuert.
  //Z.Z. wird diese Funktion bei jedem Durchlauf aufgerufen. Getestet und entwickelt wurde
  //diese Funktion für Rosti NKO, mit nur 12 Maschinen.
  //Die Laufzeit bei Anlagen mit mehreren Maschinen wurde nicht getestet.
  //Möglich ist eine Verlagerung zur Berechnung beim Schichtwechsel und VOR
  //dem Auftrag beenden.

  S := 'select DISTINCT(AUFTRAGNR) AUFTRAGNR from TAKTZEITEN';
  SQL_Get(qDurchlauf, S);
  while not qDurchlauf.EOF do
  begin
    ANr := qDurchlauf.FieldByName('AUFTRAGNR').AsString;

    S := 'select COUNT(*) CNT from TAKTZEITEN where AUFTRAGNR = ''' + ANr + '''';
    SQL_Get(qSuch, S);
    if qSuch.FieldByName('CNT').AsInteger > ANZ_WERTE then
    begin
      S := 'select AVG(TAKTZEIT) TAKTMITTEL from TAKTZEITEN where AUFTRAGNR = ''' + ANr + '''';
      SQL_Get(qSuch, S);
      TaktMittel := qSuch.FieldByName('TAKTMITTEL').AsFloat;

      TolHigh := TaktMittel + (TaktMittel * (TACKTLOG_CHECK_TOLERANZ / 100));
      TolLow := TaktMittel - (TaktMittel * (TACKTLOG_CHECK_TOLERANZ / 100));

      S := 'delete from TAKTZEITEN where TAKTZEIT > ' + FloatToPunktString(TolHigh) + ' and AUFTRAGNR = ''' + ANr + '''';
      SQL_Insert(qUpdate, S);

      S := 'delete from TAKTZEITEN where TAKTZEIT < ' + FloatToPunktString(TolLow) + ' and AUFTRAGNR = ''' + ANr + '''';
      SQL_Insert(qUpdate, S);
    end;

    qDurchlauf.Next;
  end;
end;
// *****************************************************************************

procedure TThread_Zusatz.CreateAddonAliveTimer;
var
  ThreadZusatzTimer: Integer;
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'incl_' + DBUser + '.ini');
  if not Ini.ValueExists('Addons', 'Timer') then
    Ini.WriteInteger('Addons', 'Timer', 600);
  ThreadZusatzTimer := Ini.ReadInteger('Addons', 'Timer', 600);
  Ini.Free;
  AddonAliveTimer := TCO_AliveClient.Create(CDatabase, 'ServiceAddons', ThreadZusatzTimer, nil,
  ForceBackSlash(INCLUDIS_HOME + TRACE_DIR) + 'svc_' + LowerCase(DBUser) + '_addons.log',  SERVICE_DISPLAY_NAME + UpperCase(DBUser));
  AddonAliveTimer.tick;
end;

procedure TThread_Zusatz.StartProgramme;
var ini : TInifile;
    i : Integer;
begin
  MakeEnviroment(qUpdate);
  AddonAliveTimer.tick;

  SchreibeMeldung('*** Start', 3);

  SQL_Get(qSuch, 'select TimeZone from Setup');
  TimeZone := qSuch.FieldByName('TimeZone').AsInteger;

  if RUESTPROT_AUS_STILLSTAND then
  try
    SchreibeMeldung('Step 1', 3);
    CheckRuestProt_Stillog;
  except
    SchreibeMeldung('530915BF-75F1-4F89-B724-DE59E0DF6023', 3);
  end;

  if Palette_Rest then
  try
    SchreibeMeldung('Step 2', 3);
    Palette_Rest_Berechnen;
  except
    SchreibeMeldung('B7E3ECA2-9539-4B10-BB73-359B81B0D05D', 3);
  end;

  try
    SchreibeMeldung('Step 3', 3);
    TPM_Korrektur_Doppelte_Daten;
  except
    SchreibeMeldung('4D41241E-C87D-4ABA-8DFD-AE993D1A6588', 3);
  end;

  try
    SchreibeMeldung('Step 4', 3);
    Job_No_to_Downtime_Log;
  except
    SchreibeMeldung('7CF8D4BC-E526-4253-8CFC-AF621E8AE0B6', 3);
  end;

  try
    SchreibeMeldung('Step 5', 3);
    ArbeitsFrei_Buchen;
  except
    SchreibeMeldung('9C331876-DA36-42B7-A4AB-A7BA614E1A05', 3);
  end;

  if SHORT_DELAY_AUTO_BOOK then
  try
    SchreibeMeldung('Step 5a', 3);
    Book_Short_Delay;
  except
    SchreibeMeldung('1D952875-7E5D-4298-A134-85DB22579E56', 3);
  end;

  try
    SchreibeMeldung('Step 6', 3);
    WZReparatur;
  except
    SchreibeMeldung('12DD22EB-76EA-4C98-A693-403543529838', 3);
  end;

  try
    SchreibeMeldung('Step 7', 3);
    CheckVerpacktProt;
  except
    SchreibeMeldung('327AE9CF-F593-404C-8DEB-17EBC9D974DF', 3);
  end;

  if TCO_Setup.GetParamInt(qSuch, 'INCL_Verpackt_Schicht_Nachberechnen') > 0 then
  try
    SchreibeMeldung('Step 7.1', 3);
    i :=CheckPackSchicht(TCO_Setup.GetParamInt(qSuch, 'INCL_Verpackt_Schicht_Nachberechnen'));
    SchreibeMeldung('Step 7.1 ' + IntToStr(i), 3);
  except
    SchreibeMeldung('C0CAAD1A-F023-4EB0-B4F2-103C0B491B71', 3);
  end;

  if OptionPlanung then
  try
    SchreibeMeldung('Step 8', 3);
    Laufzeit_Berechnen;
  except
    SchreibeMeldung('425CFDF5-4D52-49BB-81C5-2B890E265518', 3);
  end;

  if TACKTLOG_CHECK then
  try
    SchreibeMeldung('Step 9', 3);
    Check_TaktLog;
  except
    SchreibeMeldung('C6A84293-FA92-4E23-BA17-8BC0AB7EAF6F', 3);
  end;

  if TCO_Setup.GetParamBool(qSuch, 'INCL_VerpacktProt_aus_Schichtausschuss') and
    not TCO_Setup.GetParamBool(qSuch, 'INCL_VerpacktProt_aus_Aarchiv_und_AusschussProt', false) then
  try
    SchreibeMeldung('Step 10', 3);
    CalcPackedlogFromShiftlog;
  except
    SchreibeMeldung('5AF9E829-D7EE-48CF-AB89-A6240257068A', 3);
  end;

  if PersonalNr_Signal then
  try
    SchreibeMeldung('Step 11', 3);
    Taktzeit_Personal;
  except
    SchreibeMeldung('29CD1326-7B80-4984-8AD0-75CAABA5D3BB', 3);
  end;

  if OptionPlanung then
  try
    SchreibeMeldung('Step 12', 3);
    TaktMitteln(True);
  except
    SchreibeMeldung('DC1A0614-8483-430C-9FAA-EC140CD3E4A1', 3);
  end;


  if TCO_Setup.GetParamBool(qSuch, 'INCL_UngeplantRuestenBerechnen') then
  begin
    try
      SchreibeMeldung('Step 13', 3);
      UnscheduledSetup;
    except
      SchreibeMeldung('9A3041CF-82D2-4FA2-9B6C-B2E21249AB25', 3);
    end;
  end;

  try
    SchreibeMeldung('Step 14', 3);
    CheckSollstueck;
  except
    SchreibeMeldung('25C3A586-1849-4921-AA91-B8B567B0079D', 3);
  end;

  if TCO_Setup.GetParamInt(qSuch, 'INCL_WZLaufzeitwarnung') > 0 then
  try
    SchreibeMeldung('Step 15', 3);
    CheckWzWartungen;
  except
    SchreibeMeldung('AEF39423-69CA-4468-86C5-0FFE230F6F52', 3);
  end;

  if AuftragKette then
  try
    SchreibeMeldung('Step 16', 3);
    CheckAuftragKette;
  except
    SchreibeMeldung('AEF36583-69CA-6537-86C5-0FAE584F6F52', 3);
  end;

  if TCO_Setup.GetParamBool(qSuch, 'MG_Reschedule_Before_Print') then
  try
    SchreibeMeldung('Step 17', 3);
    Reschedule;
  except
    SchreibeMeldung('D4587614-8523-425D-7DFE-EDF45712A544A1', 3);
  end;


  SchreibeMeldung('*** End', 3);
  SchreibeMeldung('-------------------------------------------------------', 3);

  Ini := TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'incl_' + DBUser + '.ini');
  Ini.WriteDateTime('Addons', 'LastRun', now);
  Ini.Free;

end;

// *****************************************************************************

procedure TThread_Zusatz.Taktzeit_Personal;
var
  S: string;
begin
  S := 'select Taktzeiten.Nr, PersonalMaschine.PersonalName from Taktzeiten, PersonalMaschine'
    + ' where Taktzeiten.Lizenz = PersonalMaschine.Maschine'
    + ' and Taktzeiten.DatumZeit >= PersonalMaschine.Kommt'
    + ' and Taktzeiten.DatumZeit < Decode(PersonalMaschine.Geht, 0, 99999, PersonalMaschine.Geht)'
    + ' and Taktzeiten.Personal is Null';
  SQL_Get(qSuch, S);
  while not qSuch.EOF do
  begin
    S := 'update Taktzeiten set Personal = ''' + qSuch.FieldByName('PersonalName').AsString + ''''
      + ' where Nr = ' + qSuch.FieldByName('Nr').AsString;
    SQL_Insert(qUpdate, S);
    qSuch.Next;
  end;

end;

// Funktion um den gemittelten Takt ins Archiv und in die Tabelle PDE zu schreiben
// aUpdate gibt an ob der Takt komplett neu berechnet werden soll,
//    oder nur ein Update vorgenommen wird

procedure TThread_Zusatz.TaktMitteln(aUpdate: Boolean);
var
  takttol, taktzahl, Stat: Integer;
  BANr: string;
  Schuss, akttakt, Solltakt, avgtakt: Real;
  taktbasis_manuell: Boolean;
  manuelle_buchung : Boolean;
  use_all_cycles : Boolean;
  cycle_filter_extension : string;

  function getPlusToleranz(aTol: Integer): string;
  begin
    // Ausgabe von Multiplikator für Takt in 1/100 Sekunden
    // Bei 10% Ausgabe 0.011
    aTol := 100 + aTol;
    Result := FloatToPunktString(aTol / 100);
  end;

  function getMinusToleranz(aTol: Integer): string;
  begin
    // Ausgabe von Multiplikator für Takt in 1/100 Sekunden
    // Bei 10% Ausgabe 0.009
    aTol := 100 - aTol;
    Result := FloatToPunktString(aTol / 100);
  end;

begin

  {
    Feld taktbasis in PDE und AARCHIV berechnen (in ms)
    Taktbasis ist die Zeit aufgrund welcher Auftragslaufzeiten,
    Materialbereitstellungen usw. berechnet werden. Sollte kein zu berechnender
    Isttakt verfügbar sein, wird der Solltakt verwendet
    Dabei wird ebenfalls vorgegangen wie bei taktmittel
  }

  {
    Feld taktmittel in PDE und AARCHIV berechnen (in ms)
    Taktmittel ist der mittlere Takt über den Auftrag.
    Sollte ein Taktzeitprotokoll geführt sein, dann wird der Durchschnitt aller
    Takte, die sich im Bereich des AVG(taktzeit) +/- takttol befinden gemittelt und
    erneut berechnet. Es sollten min 10 Einträge im Taktprotokoll vorhanden sein.
    Ansonsten wird der Takt über die Auftragslaufzeit und Stückzahl/Kavität berechnet.
   }
  try
    takttol := TCO_Setup.GetParamInt(qUpdate, 'INCL_TaktbasisToleranz'); // in Prozent
    taktzahl := TCO_Setup.GetParamInt(qUpdate, 'INCL_TaktbasisAnzahl'); // in Prozent

    //    takt_aus_plan := TCO_Setup.GetParamInt(qUpdate, 'FP_Plantakt') > 0;
    //    taktbasis_manuell := TCO_Setup.GetParamInt(qUpdate, 'INCL_TaktbasisAnzahl') > 0; // in Prozent
    //    taktbasis_manuell := taktbasis_manuell or takt_aus_plan;
    // Rausgenommen in Absprache mit Herrn Finke. War Zusatzfunktion Fagerdala

//    use_all_cycles := TCO_Setup.GetParamInt(qUpdate, 'INCL_AlleTakteFuerTaktbasisNutzen') >0;

    if not taktbasis_manuell then
    begin
      qUpdate.SQL.Text := 'UPDATE PDE SET taktbasis = taktzeit / 100 '
        + ' WHERE taktbasis=0 or taktbasis is null';
      qUpdate.ExecSQL;
    end;
    if not use_all_cycles then
      cycle_filter_extension := '   AND taktzeiten.taktzeit * 100 between (pde.taktzeit * ' + getMinusToleranz(takttol)
        + ') and (pde.taktzeit * ' + getPlusToleranz(takttol) + ') ';

    qSuch.SQL.Text :=
      'SELECT pde.betriebsauftragnr banr, pde.stat stat, pde.taktzeit  taktzeit,'
      + ' CASE WHEN pde.istwert IS NULL THEN ''0'' ELSE pde.istwert END istwert, '
      + ' pdekombi.betriebsauftragnr kombibanr, pde.kopfgroesse kavitaet, '
      + ' COUNT(taktzeiten.nr) cnt, AVG(taktzeiten.taktzeit) taktavg,'
      + ' maschine.manuelle_buchung '
      + ' FROM pde '
      + ' LEFT JOIN aarchiv ON aarchiv.betriebsauftragnr = pde.betriebsauftragnr '
      + ' LEFT JOIN pdekombi ON pdekombi.masterbetriebsauftragnr = pde.betriebsauftragnr '
      + ' LEFT JOIN maschine ON maschine.lizenz = pde.lizenz '
      + ' LEFT JOIN taktzeiten ON taktzeiten.auftragnr=pde.betriebsauftragnr '
      + cycle_filter_extension
      + ' WHERE pde.stat IN (0,1)'
      + ' GROUP BY taktzeiten.auftragnr , pde.betriebsauftragnr , pde.stat , '
      + '  pdekombi.betriebsauftragnr , pde.kopfgroesse, pde.istwert,pde.taktzeit,pde.lizenz,maschine.manuelle_buchung ';
    qSuch.Open;
    while not qSuch.EOF do
    begin
      // 0 -> läuft -> Isttakzeit von a) TaktzeitProt b) Laufzeit c) Isttakt-Archiv
      // 1 -> rüsten -> keine Ist-Taktzeit
      // 2 -> geplant -> keine Ist-Taktzeit
      // 5 -> unterbrochen

      BANr := qSuch.FieldByName('banr').AsString;
      Stat := qSuch.FieldByName('stat').AsInteger;
      Solltakt := qSuch.FieldByName('taktzeit').AsFloat / 100;
      avgtakt := qSuch.FieldByName('taktavg').AsFloat;
      manuelle_buchung := qSuch.FieldByName('manuelle_buchung').AsInteger > 0;
      if Stat in [1, 2] then // taktbasis = Solltakt aus PDE
      begin
        akttakt := Solltakt;
      end
      else if Stat in [0, 5] then // taktbasis = Isttakt,
      begin //  entweder wenn genügend Stichproben (20 im Toleranzbereich) vorhanden sonst aus Laufzeit, Kavität und Stückzahl
        if manuelle_buchung then
          akttakt := Solltakt
        else
        if qSuch.FieldByName('cnt').AsInteger > taktzahl then
        begin
          akttakt := avgtakt;
        end
        else
        begin
          qSuch2.SQL.Text := 'SELECT SUM(a_istlaufzeit) lz FROM tpm_schicht WHERE betriebsauftragnr = '''
            + BANr + '''';
          qSuch2.Open;
          if not qSuch2.IsEmpty then
          begin
            if qSuch.FieldByName('istwert').AsInteger * qSuch.FieldByName('kavitaet').AsInteger > 0 then
            begin
              //RS 16.06.2015: Kavitätswechsel werden auch hier sauber berücksichtigt
              qSuch3.SQL.Text:= 'SELECT * FROM kavprot WHERE betriebsauftragnr = '
                 + '''' + BANr + ''''
                 + ' ORDER BY datum DESC';
              qSuch3.Open;
              if qSuch3.IsEmpty  OR not Kavitaet_laufender_Auftrag3 then
                Schuss := qSuch.FieldByName('istwert').AsInteger / qSuch.FieldByName('kavitaet').AsInteger
              else
              begin
                if (qSuch3.FieldByName('Schusszaehler').AsInteger = 0) AND (qSuch3.FieldByName('Produziert').AsInteger > 0) then
                  Schuss := qSuch.FieldByName('istwert').AsInteger / qSuch.FieldByName('kavitaet').AsInteger
                else
                begin
                  Schuss := (qSuch.FieldByName('istwert').AsInteger - qSuch3.FieldByName('Produziert').AsInteger)
                          / qSuch3.FieldByName('Wert2').AsInteger;
                  Schuss := Schuss + qSuch3.FieldByName('Schusszaehler').AsInteger;
                end;
              end;
              qSuch3.Close;
              akttakt := (qSuch2.FieldByName('lz').AsInteger * 60) / Schuss;
            end
            else
              akttakt := Solltakt;
          end
          else
            akttakt := Solltakt;
          qSuch2.Close;

        end;
      end;
      // Wenn Isttakt zu sehr von Solltakt abweicht wird auf Taktdurchschnitt, bzw Solltakt zurück gefallen
(*
     if (akttakt > Solltakt * 3) or (akttakt < Solltakt * 0.3) then // Wenn Takt größer als 300% von Soll oder
        akttakt := avgtakt; // kleiner als 30% Soll dann Durchschnitt nehmen

      if (akttakt > Solltakt * 3) or (akttakt < Solltakt * 0.3) then
        // Wenn Durchschnittstakt größer als 300% von Soll oder
        akttakt := Solltakt; // kleiner als 30% Soll dann Soll nehmen
        *)
      // Änderung der Grenzen auf +/- 30%
     if (akttakt > Solltakt * 1.5) or (akttakt < Solltakt * 0.6) then
        akttakt := avgtakt;

      if (akttakt > Solltakt * 1.5) or (akttakt < Solltakt * 0.6) then
        akttakt := Solltakt;


      qUpdate.SQL.Text := 'UPDATE PDE SET taktmittel = ' + FloatToPunktString(akttakt);
      if not taktbasis_manuell then
        qUpdate.SQL.Text := qUpdate.SQL.Text + ', taktbasis = ' + FloatToPunktString(akttakt);
      qUpdate.SQL.Text := qUpdate.SQL.Text + ' WHERE betriebsauftragnr = ''' + BANr + '''';
      qUpdate.ExecSQL;

      qUpdate.SQL.Text := 'UPDATE PDEKOMBI SET taktmittel = ' + FloatToPunktString(akttakt);
      if not taktbasis_manuell then
        qUpdate.SQL.Text := qUpdate.SQL.Text + ', taktbasis = ' + FloatToPunktString(akttakt);
      qUpdate.SQL.Text := qUpdate.SQL.Text + ' WHERE masterbetriebsauftragnr = ''' + BANr + '''';
      qUpdate.ExecSQL;

      qUpdate.SQL.Text := 'UPDATE aarchiv SET taktmittel = ' + FloatToPunktString(akttakt);
      if not taktbasis_manuell then
        qUpdate.SQL.Text := qUpdate.SQL.Text + ', taktbasis = ' + FloatToPunktString(akttakt);
      qUpdate.SQL.Text := qUpdate.SQL.Text + ' WHERE betriebsauftragnr = ''' + BANr + ''' OR masterauftrag = ''' + BANr
        + '''';
      qUpdate.ExecSQL;

      qSuch.Next;
    end;
    qSuch.Close;

  except
  end;

end;

procedure TThread_Zusatz.CheckSollstueck;
var
  BANr: string;
  Soll: Integer;
begin
  // Überprüfe ob Sollstück von PDE mit Sollstück von AARCHIV übereinstimen.
  // PDE ist Master
  qSuch.SQL.Text := 'SELECT pde.betriebsauftragnr banr, pde.sollwert psoll, aarchiv.sollvorgabeint asoll FROM pde '
    + ' JOIN aarchiv ON aarchiv.betriebsauftragnr = pde.betriebsauftragnr '
    + ' WHERE pde.sollwert <> aarchiv.sollvorgabeint ';
  qSuch.Open;
  while not qSuch.EOF do
  begin
    qUpdate.SQL.Text := 'UPDATE aarchiv SET '
      + ' sollvorgabeint = ' + qSuch.FieldByName('psoll').AsString
      + ', sollvorgabe =  ' + qSuch.FieldByName('psoll').AsString
      + ' WHERE betriebsauftragnr = ''' + qSuch.FieldByName('banr').AsString + '''';
    qUpdate.ExecSQL;

    qSuch.Next;
  end;
  qSuch.Close;
  // Überprüfe ob Sollstück von PDE mit Sollstück von AARCHIV übereinstimen.
  // PDE ist Master
  qSuch.SQL.Text := 'SELECT pde.betriebsauftragnr banr, pde.SollWertOffset psoll, aarchiv.SollWertOffset asoll FROM pde '
    + ' JOIN aarchiv ON aarchiv.betriebsauftragnr = pde.betriebsauftragnr '
    + ' WHERE pde.SollWertOffset <> aarchiv.SollWertOffset ';
  qSuch.Open;
  while not qSuch.EOF do
  begin
    qUpdate.SQL.Text := 'UPDATE aarchiv SET '
      + ' SollWertOffset = ' + qSuch.FieldByName('psoll').AsString
      + ' WHERE betriebsauftragnr = ''' + qSuch.FieldByName('banr').AsString + '''';
    qUpdate.ExecSQL;

    qSuch.Next;
  end;
  qSuch.Close;
end;


procedure TThread_Zusatz.CheckWzWartungen;
var monate : Integer;
    s, meldung : string;
    letztewartung, zieldatum : TDateTime;
    d,m,y : word;
    mint, yint : Integer;
    dmy, jobnummer : string;
begin
 // monate := TCO_Setup.GetParamInt(qSuch, 'INCL_WZ_JahreSeitLetzterWartung');
  s := 'SELECT * FROM werkzeug WHERE gesperrt = 0 AND letztewartung IS NOT null AND letztewartung <> '' ''';
  qSuch4.SQL.Text := s;
  qSuch4.Open;
  while not qSuch4.EOF do
  begin
    dmy := qSuch4.FieldByName('letztewartung').AsString;
    monate := qSuch4.FieldByName('lznachwartungmon').AsInteger;
    meldung := qSuch4.FieldByName('lzmeldung').AsString;
    try
      d := StrToInt(Copy(dmy,1,2));
      m := StrToInt(Copy(dmy,4,2));
      if Length(dmy) >9 then
        y := StrToInt(Copy(dmy,7,4))
      else
        y := StrToInt(Copy(dmy,7,2));
         if y < 100 then
        y := 1900 + y;
      if y < 1970 then
        y := 100 + y;
      letztewartung := EncodeDate(y,m,d);
      DecodeDate(Now, y, m, d);
      // Monate runter zählen

      yint := y;
      mint := m - monate;
      while mint <= 0 do
      begin
        yint := yint - 1;
        mint := mint + 12;
      end;

      m := mint;
      y := yint;
      zieldatum := EncodeDate(y,m,d);

      if zieldatum > letztewartung then
      begin
        jobnummer := 'WZ:'+ qSuch4.FieldByName('werkzeugnr').AsString + ' - ' + qSuch4.FieldByName('werkzeugbez').AsString;
        if Length(jobnummer) > 49 then
          jobnummer := Copy(jobnummer,1,49);

        // Meldung erzeugen und Werkzeug auf gesperrt setzen
         S := 'INSERT INTO BDA (Nr,DatumZeit,Bezeichnung,JobNummer,'
          + 'Quelle,Zustand,Signal,Sollwert,RoteLampeAn,NeuerJob)'
          + 'VALUES(BDAID.NextVal'
          + ',' + FloatToPunktString(Now)
          + ',''' + meldung
          + ''',''' + jobnummer
          + ''',''' + 'Werkzeugbau'
          + ''',''' + 'abgelaufen'
          + ''',''' + 'Aufbewahrungsfrist'
          + ''',''' + DateToStr(letztewartung)
          + ''',0,1)';
        SQL_Insert(qUpdate, S);

        SQL_Insert(qUpdate,'UPDATE werkzeug SET gesperrt=1 WHERE nr = ' + qSuch4.FieldByName('nr').asString);
      end;
    except
    end;
    qSuch4.Next;
  end;
end;

procedure TThread_Zusatz.CheckAuftragKette;
var laufzeit : Real;
  kav, varkav : Integer;
  EndeZeitpunkt, start, startalt : TDateTime;
  sqlstr : string;
  startaltSchreiben : Boolean;
begin
  try
  // Alle Maschinen durchgehen bei denen Aufträge verknüpft sind
    SQL_Get(qSuch4, 'SELECT * FROM pde WHERE vorgaengerba <> '''' AND NOT vorgaengerba IS NULL order by lizenz, startdatumzeit');
    while not qSuch4.Eof do
    begin
      SQL_Get(qSuch3, 'SELECT * FROM pde WHERE betriebsauftragnr = ''' + qSuch4.FieldByName('vorgaengerba').AsString + '''');
      if not qSuch3.isEmpty then
      begin
        // Sicherheitscheck ob beide Aufträge auf selber Maschine
        if (qSuch4.FieldByName('lizenz').AsString = qSuch3.FieldByName('lizenz').AsString) then
        begin
          startaltSchreiben := False;
          // manuell_datumzeit wird als Feld für temporäre Speicherung des Datums verwendet.
          // Wenn Unterschied größer als zwei Stunden Event 'E' senden
          startalt := qSuch3.FieldByName('manuell_datumzeit').AsFloat;
          start := qSuch3.FieldByName('startdatumzeit').AsFloat;
          if startalt <1 then
          begin
            startaltSchreiben := True;
            startalt := start;
          end;
          kav := qSuch4.FieldByName('kopfgroesse').AsInteger;
          if kav =0 then
            kav := 1;
          varkav := qSuch4.FieldByName('var_kavitaet').AsInteger;
          if (varkav =0) then
            varkav := 1;
          laufzeit := ((qSuch4.FieldByName('Sollwert').AsInteger * varkav ) / kav) * (qSuch4.FieldByName('taktzeit').AsInteger / 6000);
          EndeZeitpunkt := GetEndeDatumLizenz(qSuch3.FieldByName('Lizenz').AsString,
                    qSuch4.FieldByName('Betriebsauftragnr').AsString, qSuch3.FieldByName('Enddatumzeit').AsFloat, Trunc(laufzeit));
          start := EndeZeitpunkt;

          if (abs(start -startalt) * 24) > 2 then // Wenn Abweichung > 2 Stunden dann Event feuern
          begin
            startaltSchreiben := True;
            startalt := start;
            SQLStr := 'insert into ERPEvents (Nr, BetriebsAuftragNr, Event, Datumzeit)'
                    + ' values (ERPEventsId.NextVal,'
                    + '''' +  qSuch4.FieldByName('Betriebsauftragnr').AsString + ''','
                    + '''E'','
                    + FloatToPunktString(now) + ')';
            SQL_Insert(qUpdate, SQLStr);
          end;

          sqlstr :=  'UPDATE pde SET startdatumzeit = ' + FloatToPunktString(qSuch3.FieldByName('Enddatumzeit').AsFloat) + ', '
            + 'enddatumzeit = ' + FloatToPunktString(EndeZeitpunkt);
          if startaltSchreiben then
          sqlstr := sqlstr + ' , manuelle_datumzeit = ' + FloatToPunktString(startalt);
          sqlstr := sqlstr  + ' WHERE nr = ' + IntToStr(qSuch4.FieldByName('nr').AsInteger);
          SQL_Insert(qUpdate,sqlstr);
        end
        else // Wenn beide auf unterschiedlichen Maschine Kette deaktivieren
        begin
          SQL_Insert(qUpdate, 'UPDATE pde SET vorgaengerba = '''' WHERE nr = ' + IntToStr(qSuch4.FieldByName('nr').AsInteger));
        end;
      end;
      qSuch4.Next;
    end;

  except on e: Exception do
    begin
    end;
  end;
end;

/// Funktion ausgelagert nach Arbeit.
procedure TThread_Zusatz.CalcPackedlogFromShiftlog;//overload;
begin
  VerpacktProtAusAusschussRechnen(qSuch, qSuch2, qUpdate, DBUser);
end;

procedure TThread_Zusatz.CalcPackedlogFromShiftlog(fromdate : TDateTime);//overload;
begin
  VerpacktProtAusAusschussRechnen(qSuch, qSuch2, qUpdate, DBUser, fromdate);
end;
// Rüstzeitenvergleich

procedure TThread_Zusatz.UnscheduledSetup;
var
  S: string;
  Lizenz, BANr, MaschNr: string;
  sollruest, istruest, gesruest, geplruest, schuss, Prod, NrInt,
  ungeplruest, ruestzeiteintrag, ruestgrund: Integer;
  isgeplant: Boolean;
  Kommt, Geht, splitzeitpunkt: Extended;
begin
  if not RuestenIstGeplant then
    Exit;
  // Aufträge holen, die laufen oder in den letzten 'INCL_Days_TPM_Auswertung' Tagen beendet wurden
  S := 'SELECT betriebsauftragnr, aarchiv.maschine, maschine.maschnr, ruestzeitsoll '
    + ' FROM aarchiv '
    + ' LEFT JOIN maschine ON maschine.lizenz = aarchiv.maschine '
    + ' WHERE enddatumzeit = 0 OR enddatumzeit > '
    + FloatToPunktString(N_o_w - TCO_Setup.GetParamInt(qSuch, 'INCL_Days_TPM_Auswertung'));
  qSuch.SQL.Text := S;
  qSuch.Open;
  while not qSuch.EOF do
  begin
    BANr := qSuch.FieldByName('betriebsauftragnr').AsString;
    Lizenz := qSuch.FieldByName('maschine').AsString;
    MaschNr := qSuch.FieldByName('maschnr').AsString;
    sollruest := qSuch.FieldByName('ruestzeitsoll').AsInteger;

    istruest := 0;
    ungeplruest := 0;
    gesruest := 0;

    qSuch2.SQL.Text := 'SELECT kommt FROM tpm_stillog '
      + ' WHERE betriebsauftragnr = ''' + BANr + ''''
      + ' AND stillstandnr = ' + IntToStr(RuestStillstandNrUngeplant)
      + ' order by Kommt';
    qSuch2.Open;
    if qSuch2.IsEmpty then
    begin
      S := 'SELECT nr, stillstandnr, kommt , geht, schusszaehler FROM tpm_stillog '
        + ' WHERE betriebsauftragnr = ''' + BANr + ''''
        + ' AND stillstandnr = 2 '
        + ' ORDER BY kommt';
      qSuch2.SQL.Text := S;
      qSuch2.Open;
      while not qSuch2.EOF do
      begin
        // Summe Rüstzeiten aus Stillstandsprotokoll holen
        // Vergleich Soll- und Ist-Rüstzeit
        // Ggf Splitten und Ändern der Stillstandsgründe (keine offenen Stillstände bearbeiten)
        Kommt := qSuch2.FieldByName('kommt').AsFloat;
        Schuss := qSuch2.FieldByName('SCHUSSZAEHLER').AsInteger;
        Geht := qSuch2.FieldByName('geht').AsFloat;
        if Geht < 1 then
          Geht := N_o_w;
        // ruestzeiteintrag := (qSuch2.FieldByName('ruestist').AsInteger - qSuch2.FieldByName('arbeitsfrei').AsInteger);
        ruestzeiteintrag := Round((Geht - Kommt) * 1440);

        gesruest := gesruest + ruestzeiteintrag;
        if gesruest > sollruest then // Erster Datensatz, der gesplittet oder umgebucht werden muss
        begin
          ungeplruest := gesruest - sollruest; // Länge des neuen Rüsteintrags
          splitzeitpunkt := Kommt + (ruestzeiteintrag - ungeplruest) / 1440;

          // Neuen Rüsteintrag anlegen
          qUpdate.SQL.Text := 'INSERT INTO tpm_stillog (NR, BETRIEBSAUFTRAGNR, kommt, '
            + ' geht, DAUER, maschnr, WERKZEUGNR, STILLSTANDNR,  '
            + ' AUFTRAGNR, BEZEICHNUNG, SCHICHT, PERSONALNR, SCHUSSZAEHLER, prodzaehler) '
            + ' SELECT tpm_stillogid.NextVal NR, BETRIEBSAUFTRAGNR, '
            + FloatToPunktString(splitzeitpunkt) + ' Kommt, '
            + ' GEHT, -1 Dauer, maschnr, WERKZEUGNR, ' + IntToStr(RuestStillstandNrUngeplant) + ' STILLSTANDNR, '
            + ' AUFTRAGNR, BEZEICHNUNG, SCHICHT, PERSONALNR, ' + IntToStr(Schuss)           + ',' + IntToStr(Prod) +' FROM tpm_stillog WHERE nr = '
            + IntToStr(qSuch2.FieldByName('nr').AsInteger);
          qUpdate.ExecSQL;

          qUpdate.SQL.Text := 'UPDATE tpm_stillog SET geht = '
            + FloatToPunktString(splitzeitpunkt) + ', dauer = -1'
            + ' WHERE nr = ' + qSuch2.FieldByName('nr').AsString;
          qUpdate.ExecSQL;

          qSuch2.Last;
        end;

        qSuch2.Next;
      end;
      qSuch2.Close;

    end
    else
    begin
     qSuch2.SQL.Text := 'SELECT ts.NR, mi.BETRIEBSAUFTRAGNR, mi.LIZENZ, mi.WERKZEUG, mi.ARTIKELNR, s.stillstand, mi.stueck, s2.stillstand alterstillstand'
              + ' FROM TPM_STILLOG  ts'
              + ' LEFT JOIN MASCHINE m ON m.maschnr = ts.maschnr'
              + ' LEFT JOIN MASCHINF mi ON m.lizenz = mi.lizenz'
              + ' LEFT JOIN TPM_STILLSTAENDE s ON s.STILLSTANDNR = ' + IntToStr(RuestStillstandNrUngeplant)
              + ' LEFT JOIN TPM_STILLSTAENDE s2 ON s2.stillstandnr = ts.stillstandnr'
              + ' WHERE ts.Kommt > ' + FloatToPunktString(qSuch2.FieldByName('Kommt').AsFloat)
              + ' and ts.betriebsauftragnr = ''' + BANr + ''' and ts.Stillstandnr = 2';
      qSuch2.Open;
      while not qSuch2.EOF do
      begin
        NrInt := qSuch2.FieldByName('nr').AsInteger;
        ChangeDtCode(qUpdate, RuestStillstandNrUngeplant, NrInt, qSuch2, 'US2223');
        qSuch2.Next;
      end;
    end;

    qSuch2.SQL.Text := 'SELECT Round(sum(CASE WHEN geht = 0 THEN ' + FloatToPunktString(N_o_w) + ' ELSE geht END - kommt)*1440) summe'
      + ' FROM tpm_stillog WHERE betriebsauftragnr = ''' + BANr + ''' AND stillstandnr = 2';
    qSuch2.Open;
    geplruest := qSuch2.FieldByName('summe').AsInteger;
    qSuch2.Close;

    qSuch2.SQL.Text := 'SELECT Round(sum(CASE WHEN geht = 0 THEN ' + FloatToPunktString(N_o_w) + ' ELSE geht END - kommt)*1440) summe'
      + ' FROM tpm_stillog WHERE betriebsauftragnr = ''' + BANr + ''' AND stillstandnr = ' + IntToStr(RuestStillstandNrUngeplant);
    qSuch2.Open;
    ungeplruest := qSuch2.FieldByName('summe').AsInteger;
    qSuch2.Close;

    qUpdate.SQL.Text := 'UPDATE aarchiv SET ruestenungepl = ' + IntToStr(ungeplruest) + ','
      + ' ruestengepl = ' + IntToStr(geplruest) + ','
      + ' RuestzeitIst = ' + IntToStr(geplruest + ungeplruest) + ','
      + ' RuestzeitDiff = - RuestzeitSoll + ' + IntToStr(geplruest + ungeplruest)
      + ' WHERE betriebsauftragnr = ''' + BANr + '''';
    qUpdate.ExecSQL;

    qUpdate.SQL.Text := 'UPDATE pde SET ruestenungepl = ' + IntToStr(ungeplruest)
      + ', ruestengepl = ' + IntToStr(geplruest) + ' WHERE betriebsauftragnr = ''' + BANr + '''';
    qUpdate.ExecSQL;

    qSuch.Next;
  end;
  qSuch.Close;

end;

procedure TThread_Zusatz.Reschedule;
var
  SQLStr, S, Liz: string;
  Ende, LT1, LT2: Real;
  Soll, Ist: Real;
  Kav, WZNr: Integer;
begin
  S := 'delete from Warnung where Application = 3';
  SQL_Insert(qUpdate, S);
  S := 'update PDE set Festdatum = 0 where Stat = 0 or Stat = 1';
  SQL_Insert(qUpdate, S);
  // Bug bei Kavität = 0
  S := 'update PDE set Kopfgroesse = 1 where Kopfgroesse = 0';
  SQL_Insert(qUpdate, S);
  (*   Macht riesige Probleme !!!
  (* Alte Funktion deaktiviert. Macht Probleme
  S := 'select * from PDE order by Lizenz, StartDatumZeit';
  SQL_Get(qSuch, S);
  while not qSuch.EOF do
  begin
    if qSuch.FieldByName('Stat').AsInteger < 2 then
    begin
      Liz := qSuch.FieldByName('Lizenz').AsString;
      WZNr := qSuch.FieldByName('Werkzeug').AsInteger;
      Kav := qSuch.FieldByName('Kopfgroesse').AsInteger;
      qSuch.Next;
      if (Liz = qSuch.FieldByName('Lizenz').AsString)
        and (WZNr = qSuch.FieldByName('Werkzeug').AsInteger) and (WZNr <> 0) then
      begin
        S := 'update PDE set Kopfgroesse = ' + IntToStr(Kav)
          + ' where Nr = ' + qSuch.FieldByName('Nr').AsString;
        SQL_Insert(qUpdate, S);
      end;
    end
    else
      qSuch.Next;
  end;
  *)
  if False then // Für aktuellen Zweck nicht notwendig. Bei Konvertierung nach .Net muss diese Option ausgewertet werden.
  //if Option.NoSetup_SameFollowPart then // Bei Folgeauftrag gleiches Werkzeug Rüstzeit auf 0 setzen

  begin
    S := 'select * from PDE order by Lizenz, StartDatumZeit';
    SQL_Get(qSuch, S);
    while not qSuch.EOF do
    begin
      Liz := qSuch.FieldByName('Lizenz').AsString;
      WZNr := qSuch.FieldByName('Werkzeug').AsInteger;
      qSuch.Next;
      if (Liz = qSuch.FieldByName('Lizenz').AsString)
        and (WZNr = qSuch.FieldByName('Werkzeug').AsInteger) and (WZNr <> 0) then
      begin
        S := 'update PDE set Ruestzeit = 0 where Nr = ' + qSuch.FieldByName('Nr').AsString;
        SQL_Insert(qUpdate, S);
      end;
    end;
  end;

  if TCO_Setup.GetParamBool(qSuch4, 'INCL_UpdateTaktzeitFolgeauftraege') then
    BerechnenendeausIst;

  Laufende_Auftraege_Terminieren;

  Autoterminierung;

  Laufzeit_Berechnen;

  Status_Beschreibung;

  PlanListeReportParameterSchreiben('Terminierung', DateTimeToStr(Now));
(*
  S := 'select * from PDE';
  SQL_Get(qSuch, S);
  while not qSuch.EOF do
  begin
    Ende := GFloat(qSuch.FieldByName('EndDatumZeit').AsString);
    LT1 := GFloat(qSuch.FieldByName('Termin1').AsString);
    LT2 := GFloat(qSuch.FieldByName('Termin2').AsString);
    Soll := GFloat(qSuch.FieldByName('SollWert').AsString);
    Ist := GFloat(qSuch.FieldByName('IstWert').AsString);
    WZNr := qSuch.FieldByName('Werkzeug').AsInteger;
    Liz := qSuch.FieldByName('Lizenz').AsString;

    if Ende > LT2 then
    begin
      SQLStr := 'insert into Warnung (Nr, Application, Lizenz, BetriebsAuftragNr,'
        + ' GRUND, DETAIL, AuftragNr, Bezeichnung, DATUMZEIT) values (WarnungId.NextVal, 3,'
        + '''' + Liz + ''','
        + '''' + qSuch.FieldByName('BetriebsAuftragNr').AsString + ''','
        + '''' + GetL('LT2 Warn. ') + DateToStr(LT2) + ''','
        + '''' + GetL('Verzug - ') + IntToStr(Round(Ende - LT2))
        + GetL(' Tage ') + DateToStr(Ende) + ''','
        + '''' + qSuch.FieldByName('AuftragNr').AsString + ''','
        + '''' + qSuch.FieldByName('Bezeichnung').AsString + ''','
        +  FloatToPunktString(Now) + ')';
      SQL_Insert(qUpdate, SQLStr);
    end
    else
      if Ende > LT1 then
      begin
        SQLStr := 'insert into Warnung (Nr, Application, Lizenz, BetriebsAuftragNr,'
          + ' GRUND, DETAIL, AuftragNr, Bezeichnung, DATUMZEIT) values (WarnungId.NextVal, 3,'
          + '''' + Liz + ''','
          + '''' + qSuch.FieldByName('BetriebsAuftragNr').AsString + ''','
          + '''' + GetL('LT1 Warn. ') + DateToStr(LT1) + ''','
          + '''' + GetL('Verzug - ') + IntToStr(Round(Ende - LT1))
          + GetL(' Tage ') + DateToStr(Ende) + ''','
          + '''' + qSuch.FieldByName('AuftragNr').AsString + ''','
          + '''' + qSuch.FieldByName('Bezeichnung').AsString + ''','
          + FloatToPunktString(Now) + ')';
        SQL_Insert(qUpdate, SQLStr);
      end;
    if Ist > Soll then
    begin
      SQLStr := 'insert into Warnung (Nr, Application, Lizenz, BetriebsAuftragNr,'
        + ' GRUND, DETAIL, AuftragNr, Bezeichnung, DATUMZEIT) values (WarnungId.NextVal, 3,'
        + '''' + Liz + ''','
        + '''' + qSuch.FieldByName('BetriebsAuftragNr').AsString + ''','
        + '''' + GetL('produzierte Menge > Sollvorgabe!') + ''','
        + '''' + GetL('produzierte Menge ++ ') + FloatToStr(Ist - Soll) + ''','
        + '''' + qSuch.FieldByName('AuftragNr').AsString + ''','
        + '''' + qSuch.FieldByName('Bezeichnung').AsString + ''','
        + FloatToPunktString(Now) + ')';
      SQL_Insert(qUpdate, SQLStr);
    end;

    if WZ_Warnung_Sperren then
      if SQLGet(qSuch2, 'Werkzeug', 'Werkzeug', IntToStr(WZNr), True) > 0 then
        if SQLGet(qSuch3, 'Maschine', 'Lizenz', Liz, True) > 0 then
          case qSuch2.FieldByName('WARNUNG_SPERREN').AsInteger of
            0:
              begin
                if SQL2Get(qSuch4, 'AARchiv', 'Werkzeug',
                  qSuch2.FieldByName('Werkzeug').AsString, 'Maschine', Liz, True) = 0 then
                begin
                  SQLStr := 'insert into Warnung (Nr, Application, Lizenz, BetriebsAuftragNr,'
                    + ' GRUND, DETAIL, AuftragNr, Bezeichnung, DATUMZEIT) values (WarnungId.NextVal, 3,'
                    + '''' + Liz + ''','
                    + '''' + qSuch.FieldByName('BetriebsAuftragNr').AsString + ''','
                    + '''' + GetL('WZ-Warnung') + ''','

                  + '''' + GetL('WZ "')
                    + qSuch2.FieldByName('WerkzeugNr').AsString
                    + GetL('", Maschine "') + Liz + '"'','
                    + '''' + qSuch.FieldByName('AuftragNr').AsString + ''','
                    + '''' + qSuch.FieldByName('Bezeichnung').AsString + ''','
                    + FloatToPunktString(Now) + ')';
                  SQL_Insert(qUpdate, SQLStr);
                end;
              end;
            2:
              begin
                if SQL2Get(qSuch4, 'Werkzeug_Maschine', 'Werkzeug',
                  qSuch2.FieldByName('Werkzeug').AsString, 'Lizenz', Liz, True) > 0 then
                begin
                  if SQL2Get(qSuch4, 'WERKZEUG_MASCHINE', 'Werkzeug', IntToStr(WZNr),
                    'Lizenz', Liz, True) > 0 then
                    SQLStr := 'insert into Warnung (Nr, Application, Lizenz, BetriebsAuftragNr,'
                      + ' GRUND, DETAIL, AuftragNr, Bezeichnung, DATUMZEIT) values (WarnungId.NextVal, 3,'
                      + '''' + Liz + ''','
                      + '''' + qSuch.FieldByName('BetriebsAuftragNr').AsString + ''','
                      + '''' + GetL('WZ-Sperren') + ''','

                    + '''' + GetL('WZ "')
                      + qSuch2.FieldByName('WerkzeugNr').AsString
                      + GetL('", Maschine "') + Liz + '"'','
                      + '''' + qSuch.FieldByName('AuftragNr').AsString + ''','
                      + '''' + qSuch.FieldByName('Bezeichnung').AsString + ''','
                      +  FloatToPunktString(Now) + ')';
                  SQL_Insert(qUpdate, SQLStr);
                end;
              end;
          end;
    qSuch.Next;
  end;
  *)
end;

procedure TThread_Zusatz.BerechnenEndeausIst;
var
  S, Liz, ArtNr, TZeit: string;
begin
  S := 'select * from PDE where Stat = 0 AND taktzeit > 0';
  SQL_Get(qSuch, S);
  while not qSuch.EOF do
  begin
    Liz := qSuch.FieldByName('Lizenz').AsString;
    ArtNr := qSuch.FieldByName('AuftragNr').AsString;
    TZeit := qSuch.FieldByName('Taktzeit').AsString;
    if SQLGet(qSuch2, 'Maschinf', 'Lizenz', Liz, True) > 0 then
      TZeit := IntToStr(qSuch2.FieldByName('Taktzeit').AsInteger div 10);
    S := 'select * from PDE where Stat > 1 and Lizenz = ''' + Liz + ''' order by StartDatumZeit';
    SQL_Get(qSuch2, S);
    while not qSuch2.EOF and (qSuch2.FieldByName('AuftragNr').AsString = ArtNr) do
    begin
      S := 'update PDE set Kopfgroesse =  ' + qSuch.FieldByName('Kopfgroesse').AsString + ','
        + ' TaktZeit = ' + TZeit
        + ' where Nr = ' + qSuch2.FieldByName('Nr').AsString;
      SQL_Insert(qUpdate, S);
      qSuch2.Next;
    end;

    qSuch.Next;
  end;
end;

function TThread_Zusatz.Laufende_Auftraege_Terminieren: Boolean;
var
  SQLStr, Lizenz: string;
  StartDatum, EndDatum: Real;
  Takt, Soll, SollA, Nr, SNR: Integer;
  KopfStr: string;
  Kopf, VarKav: Integer;
  EndeZeitpunkt, Sollausstoss, spannzeittoleranz: Real;
  Schwesterauftrag, banr: string;
  Dauer, DauerA, IstPack: Integer;
  verpacktausschicht , wartunginende: boolean;
begin
  wartunginende := TCO_Setup.GetParamBool(qSuch2,  'Wartung_Verlaengert_Auftrag', False);
  verpacktausschicht := TCO_Setup.GetParamBool(qSuch2, 'INCL_VerpacktProt_aus_Schichtausschuss');
  SQLStr := 'Select DISTINCT(Lizenz) from PDE Order by Lizenz';
  SQL_Get(qSuch2, SQLStr);
  qSuch2.First;
  while not qSuch2.EOF do
  begin
    Lizenz := qSuch2.FieldByName('Lizenz').AsString;

    spannzeittoleranz := 1;

    SQLStr := 'select * from PDE where Lizenz = ''' + Lizenz + ''' AND (Stat = 0 or Stat = 1)';
    SQL_Get(qSuch, SQLStr);
    qSuch.First;

    while not qSuch.EOF do
    begin
      Nr := qSuch.FieldByName('Nr').AsInteger;
      StartDatum := GFloat(qSuch.FieldByName('StartDatumZeit').AsString);
      if StartDatum > Now then
      begin
        StartDatum := Now;
        UpdateSQL(qUpdate, 'PDE', 'StartDatumZeit', FloatToStr(StartDatum), 'Nr', IntToStr(Nr));
        UpdateSQL(qUpdate, 'PDE', 'StartDatumStr', DateTimeToStr(StartDatum), 'Nr', IntToStr(Nr));
      end;

      EndDatum := GFloat(qSuch.FieldByName('EndDatumZeit').AsString);

      Takt := qSuch.FieldByName('Taktzeit').AsInteger;

      if Ende_Aus_Isttakt or Ende_Aus_Isttakt_IstKav then
        Takt := Trunc(qSuch.FieldByName('taktmittel').AsFloat * 100);

      if Takt < 10 then
        Takt := qSuch.FieldByName('Taktzeit').AsInteger;

      if TCO_Setup.GetParamBool(qSuch4, 'FP_Plantakt', False) then
        if qSuch.FieldByName('Planzykluszeit').AsInteger > 0 then

          Takt := qSuch.FieldByName('Planzykluszeit').AsInteger;
      if TCO_Setup.GetParamBool(qSuch4, 'FP_Ausschussquote', False) then
        Takt := Trunc(Takt * (1 + (qSuch.FieldByName('Ausschussquote').AsInteger / 10000)));

      if Ende_Aus_Verpackt then
      begin
        if verpacktausschicht then
          IstPack := Format_String(qSuch.FieldByName('Istwert').AsString)-Format_String(qSuch.FieldByName('Ausschuss').AsString)
        else
          IstPack := Format_String(qSuch.FieldByName('Pack').AsString);
      end
      else
        IstPack := Format_String(qSuch.FieldByName('Istwert').AsString);



      Soll := Format_String(qSuch.FieldByName('Sollwert').AsString) - IstPack;

      if Soll < 0 then
        Soll := 0;

      Schwesterauftrag := qSuch.FieldByName('Schwesterauftrag').AsString;

      KopfStr := qSuch.FieldByName('Kopfgroesse').AsString;
      Kopf := Format_String(KopfStr);
      if Kopf = 0 then
        Kopf := 1;

      VarKav := qSuch.FieldByName('Var_Kavitaet').AsInteger;
      if VarKav = 0 then
        VarKav := 1;

      Dauer := Trunc(Soll / 6000 / Kopf * VarKav * Takt);

      if Dauer < 0 then
        Dauer := 10;
      banr :=qSuch.FieldByName('BetriebsAuftragNr').AsString;
      EndeZeitpunkt := GetEndeDatumLizenz(Lizenz, banr, Now, Dauer);

      if wartunginende then // Check ob Wartung um Zeitraum. Dann Endezeitpunkt ggf. mehrfach verlängern
      begin
        repeat
          SQLStr := 'SELECT * FROM wartung WHERE startdatumzeit < '+ FloatToStr(EndeZeitpunkt)
            +  ' AND enddatumzeit > '+FloatToPunktString(EndeZeitpunkt) + ' AND stat = 0 AND lizenz = ''' + Lizenz + '''';
          SQL_Get(qSuch3, SQLStr);
          if not qSuch3.IsEmpty then
          begin
            Dauer := Dauer + trunc((qSuch3.FieldByName('enddatumzeit').AsFloat - qSuch3.FieldByName('startdatumzeit').AsFloat)*1440);
            EndeZeitpunkt := GetEndeDatumLizenz(Lizenz, banr, Now, Dauer);
          end;
        until (qSuch3.IsEmpty)
      end;

      if EndeZeitpunkt <> EndDatum then
      begin
        SQLStr := 'select Count(*) as CNT from PDE where FestDatum > 0'
          + ' and Lizenz = ''' + Lizenz + '''';
        SQL_Get(qSuch3, SQLStr);
        if qSuch3.FieldByName('CNT').AsInteger > 0 then
        begin
          SQLStr := 'select Min(StartDatumZeit) as CNT from PDE where FestDatum > 0'
            + ' and Lizenz = ''' + Lizenz + '''';
          SQL_Get(qSuch3, SQLStr);
          if qSuch3.FieldByName('CNT').AsFloat < EndeZeitpunkt then
          begin
            EndeZeitpunkt := qSuch3.FieldByName('CNT').AsFloat;
            DauerA := ZeitInMinuten(Lizenz, Now, EndeZeitpunkt);
            SollA := Trunc((6000 * Kopf / VarKav) * DauerA / Takt);
            SQLStr := 'insert into Warnung (Nr, Application, Lizenz, BetriebsAuftragNr,'
              + ' GRUND, DETAIL, AuftragNr, Bezeichnung, DATUMZEIT) values (WarnungId.NextVal, 3,'
              + '''' + Lizenz + ''','
              + '''' + qSuch.FieldByName('BetriebsAuftragNr').AsString + ''','
              + '''' + GetL('Folgeauftrag festgesetzt') + ''','
              + '''' + GetL('noch zu produzierende Menge - ') + IntToStr(Soll - SollA) + ''','
              + '''' + qSuch.FieldByName('AuftragNr').AsString + ''','
              + '''' + qSuch.FieldByName('Bezeichnung').AsString + ''','
              + FloatToPunktString(Now) + ')';
            SQL_Insert(qUpdate, SQLStr);
          end;
        end;

        SQLStr := 'update PDE set'
          + ' EndDatumZeit = ' + FloatToPunktString(EndeZeitpunkt)
          + ', Change_Art = ''P'', PlanNr = ''1'''
          + ' where Nr = ''' + IntToStr(Nr) + '''';
        SQL_Insert(qUpdate, SQLStr);

        SQLStr := 'update Maschinf set '
          + 'ENDEDATUM = ''' + DateTimeToStr(EndeZeitpunkt)
          + ''' where Lizenz = ''' + Lizenz + '''';
        SQL_Insert(qUpdate, SQLStr);

        if Schwesterauftrag <> '' then
          if SQLGet(qUpdate, 'PDE', 'BetriebsauftragNr', Schwesterauftrag, True) > 0 then
          begin
            SNR := qUpdate.FieldByName('Nr').AsInteger;
            SQLStr := 'update PDE set'
              + ' EndDatumZeit = ' + FloatToPunktString(EndeZeitpunkt)
              + ', Change_Art = ''' + 'P'
              + ''' where (Nr = ''' + IntToStr(SNR) + ''')';
            SQL_Insert(qUpdate, SQLStr);
            SQLStr := 'update Maschinf set '
              + 'ENDEDATUM = ''' + DateTimeToStr(EndeZeitpunkt)
              + ''' where BetriebsauftragNr = ''' + Schwesterauftrag + '''';
            SQL_Insert(qUpdate, SQLStr);
          end;
      end;

      qSuch.Next;
    end;
    qSuch2.Next;
  end;
  Result := True;
end;

function TThread_Zusatz.Autoterminierung: Boolean;
var
  SQLStr, Lizenz: string;
  I, K, M, Nummer: Integer;
  StartDatum, EndDatum, OldEnd: Real;
  Takt, Soll, Nr, SNR: Integer;
  KopfStr: string;
  Kopf, varkav: Integer;
  EndeZeitpunkt: Real;
  Ins, wartunginende: Boolean;
  Schwesterauftrag, banr: string;
  H, RuestZeit, Dauer: Integer;
begin
  wartunginende := TCO_Setup.GetParamBool(qSuch4,  'Wartung_Verlaengert_Auftrag', False);
  SQLStr := 'Select DISTINCT(Lizenz) Lizenz from PDE'
    + ' Order by Lizenz';
  SQL_Get(qSuch2, SQLStr);
  qSuch2.First;
  while not qSuch2.EOF do
  begin
    Lizenz := qSuch2.FieldByName('Lizenz').AsString;


    I := 2;
    K := 2;
    for M := 1 to K do
    begin
      if K = 2 then
        SQLStr := 'select * from PDE where Lizenz = ''' + Lizenz + ''' and (Stat < 2)';
      if (K = 1) or (M = 2) then
        SQLStr := 'select * from PDE where Lizenz = ''' + Lizenz + ''' AND (stat > 1)';
      SQLStr := SQLStr + ' order by StartDatumZeit';

      SQL_Get(qSuch, SQLStr);
      qSuch.First;
      while not qSuch.EOF do
      begin
        Nummer := qSuch.FieldByName('Nr').AsInteger;
        UpdateSQL(qUpdate, 'PDE', 'PlanNr', IntToStr(I), 'Nr', IntToStr(Nummer));
        Inc(I);
        qSuch.Next;
      end;
    end;

    Ins := False;
    SQLStr := 'select Nr, Lizenz, BetriebsAuftragNr, Plannr, SAuftrag,'
      + ' Schwesterauftrag, StartDatumZeit, Festdatum, Sollausstoss,'
      + ' EndDatumZeit, Taktzeit, Sollwert, Istwert, RuestZeit, Kopfgroesse, '
      + ' Var_Kavitaet, Stat, Betriebsart, planzykluszeit, ausschussquote, sollspannzeitstk from PDE'
      + ' where Lizenz = ''' + Lizenz + '''  Order by PlanNr';


    SQL_Get(qSuch, SQLStr);
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

      EndDatum := GFloat(qSuch.FieldByName('EndDatumZeit').AsString);
      if qSuch.FieldByName('Stat').AsInteger > 1 then    // Auftrag geplant oder unterbrochen
      begin
        StartDatum := GFloat(qSuch.FieldByName('StartDatumZeit').AsString);
        if StartDatum < Now then
        begin
          StartDatum := Now;
          Nr := qSuch.FieldByName('Nr').AsInteger;
          Takt := qSuch.FieldByName('Taktzeit').AsInteger;

          if TCO_Setup.GetParamBool(qSuch4, 'FP_Plantakt', False) then
            if qSuch.FieldByName('Planzykluszeit').AsInteger > 0 then
              Takt := qSuch.FieldByName('Planzykluszeit').AsInteger;
          if TCO_Setup.GetParamBool(qSuch4, 'FP_Ausschussquote', False) then
            Takt := Trunc(Takt * (1 + (qSuch.FieldByName('Ausschussquote').AsInteger / 10000)));

          varkav := qSuch.FieldByName('var_kavitaet').AsInteger;
          if varkav = 0 then
            varkav := 1;
          Soll := Format_String(qSuch.FieldByName('Sollwert').AsString) - Format_String(qSuch.FieldByName('Istwert').AsString);
          KopfStr := qSuch.FieldByName('Kopfgroesse').AsString;
          Kopf := Format_String(KopfStr);
          if Kopf = 0 then
            Kopf := 1;
          RuestZeit := Format_String(qSuch.FieldByName('RuestZeit').AsString);
          Dauer := Trunc ( ( ( (Soll/6000) * Takt) / Kopf) *varkav);
//          Dauer := Trunc((Soll * Takt / (6000 * Kopf)) * varkav);

          if Dauer = 0 then
            Dauer := 10;
          banr := qSuch.FieldByName('BetriebsAuftragNr').AsString;
          EndeZeitpunkt := GetEndeDatumLizenz(qSuch.FieldByName('Lizenz').AsString,
            banr,
            StartDatum, Dauer + RuestZeit);
          SQLStr := 'update PDE set'
            + ' StartDatumSTR = ''' + DateTimeToStr(StartDatum) + ''','
            + ' EndDatumSTR = ''' + DateTimeToStr(EndeZeitpunkt) + ''','
            + ' StartDatumZeit = ' + FloatToPunktString(StartDatum) + ','
            + ' EndDatumZeit = ' + FloatToPunktString(EndeZeitpunkt)
            + ' where (Nr = ''' + IntToStr(Nr) + ''')';
          SQL_Insert(qUpdate, SQLStr);
          EndDatum := EndeZeitpunkt;
        end;
      end;

      qSuch.Next;
      if qSuch.EOF then
        break;

      if qSuch.FieldByName('SAuftrag').AsInteger = 1 then
      begin
        qSuch.Next;
        if qSuch.EOF then
          break;
      end;

      Takt := qSuch.FieldByName('Taktzeit').AsInteger;

      if TCO_Setup.GetParamBool(qSuch4, 'FP_Plantakt', False) then
        if qSuch.FieldByName('Planzykluszeit').AsInteger > 0 then
          Takt := qSuch.FieldByName('Planzykluszeit').AsInteger;
      if TCO_Setup.GetParamBool(qSuch4, 'FP_Ausschussquote', False) then
        Takt := Trunc(Takt * (1 + (qSuch.FieldByName('Ausschussquote').AsInteger / 10000)));

      Soll := Format_String(qSuch.FieldByName('Sollwert').AsString) - Format_String(qSuch.FieldByName('Istwert').AsString);
      Nr := qSuch.FieldByName('Nr').AsInteger;
      Schwesterauftrag := qSuch.FieldByName('Schwesterauftrag').AsString;

      KopfStr := qSuch.FieldByName('Kopfgroesse').AsString;
      Kopf := Format_String(KopfStr);
      if Kopf = 0 then
        Kopf := 1;
      RuestZeit := Format_String(qSuch.FieldByName('RuestZeit').AsString);
          if varkav = 0 then
            varkav := 1;
          Dauer := Trunc ( ( ( (Soll/6000) * Takt) / Kopf) *varkav);
//      Dauer := Trunc(Soll * Takt / (6000 * Kopf));
//          Dauer := Trunc((Soll * Takt / (6000 * Kopf)) * varkav);

      EndDatum := MAX(EndDatum, Now);

      EndDatum := GetNextArbeitMoment(qSuch.FieldByName('Lizenz').AsString, EndDatum);

      if Dauer = 0 then
        Dauer := 10;
      banr := qSuch.FieldByName('BetriebsAuftragNr').AsString;
      EndeZeitpunkt := GetEndeDatumLizenz(qSuch.FieldByName('Lizenz').AsString,
        banr,
        EndDatum, Dauer + RuestZeit);

      if wartunginende then // Check ob Wartung um Zeitraum. Dann Endezeitpunkt ggf. mehrfach verlängern
      begin
        SQLStr := 'SELECT * FROM wartung WHERE startdatumzeit < '+ FloatToStr(EndeZeitpunkt)
          +  ' AND enddatumzeit > '+FloatToPunktString(StartDatum) +' AND stat = 0  AND lizenz = ''' + Lizenz + '''';
        repeat
          SQL_Get(qSuch3, SQLStr);
          if not qSuch3.IsEmpty then
          begin
            Dauer := Dauer + trunc((qSuch3.FieldByName('enddatumzeit').AsFloat - qSuch3.FieldByName('startdatumzeit').AsFloat)*1440);
            OldEnd := qSuch3.FieldByName('enddatumzeit').AsFloat;
            EndeZeitpunkt := GetEndeDatumLizenz(qSuch.FieldByName('Lizenz').AsString, banr, EndDatum, Dauer + Ruestzeit);
          end;
          SQLStr := 'SELECT * FROM wartung WHERE startdatumzeit < '+ FloatToStr(EndeZeitpunkt)
            +  ' AND enddatumzeit > '+FloatToPunktString(OldEnd) +' AND stat = 0  AND lizenz = ''' + qSuch.FieldByName('Lizenz').AsString + '''';
        until (qSuch3.IsEmpty)
      end;

      StartDatum := GFloat(qSuch.FieldByName('StartDatumZeit').AsString);
            // Wenn StartDatum vor dem berechneten Ende liegt, dann muss das berechnete Ende angepasst werden.
      if StartDatum > qSuch.FieldByName('EndDatumZeit').AsFloat then
      begin
         EndeZeitpunkt := GetEndeDatumLizenz(qSuch.FieldByName('Lizenz').AsString,
           banr, StartDatum, Dauer + RuestZeit);
           SQLStr := 'update PDE set'
            + ' EndDatumSTR = ''' + DateTimeToStr(EndeZeitpunkt) + ''','
            + ' EndDatumZeit = ' + FloatToPunktString(EndeZeitpunkt)
            + ' where Nr = ' + IntToStr(Nr);
          SQL_Insert(qUpdate, SQLStr);
      end;


      if qSuch.FieldByName('Festdatum').AsInteger = 0 then
      begin
        if (StartDatum < EndDatum) then
        begin
          if Nr = 2064 then
            Lizenz := Lizenz;
          SQLStr := 'update PDE set'
            + ' StartDatumSTR = ''' + DateTimeToStr(EndDatum) + ''','
            + ' EndDatumSTR = ''' + DateTimeToStr(EndeZeitpunkt) + ''','
            + ' StartDatumZeit = ''' + FloatToStr(EndDatum) + ''','
            + ' EndDatumZeit = ''' + FloatToStr(EndeZeitpunkt) + ''','
            + ' Change_Art = ''' + 'P' + ''''
            + ' where (Nr = ''' + IntToStr(Nr) + ''')';
          SQL_Insert(qUpdate, SQLStr);
        end;
      end;

      Ins := True;
      if Schwesterauftrag <> '' then
        if SQLGet(qUpdate, 'PDE', 'BetriebsauftragNr', Schwesterauftrag, True) > 0 then
        begin
          SNR := qUpdate.FieldByName('Nr').AsInteger;

          SQLStr := 'update PDE set '
            + 'StartDatumSTR = ''' + DateTimeToStr(EndDatum)
            + ''',EndDatumSTR = ''' + DateTimeToStr(EndeZeitpunkt)
            + ''',StartDatumZeit = ' + FloatToPunktString(EndDatum)
            + ',EndDatumZeit = ' + FloatToPunktString(EndeZeitpunkt)
            + ' where (Nr = ''' + IntToStr(SNR) + ''')';

          SQL_Insert(qUpdate, SQLStr);
        end;

     SQLStr := 'select Nr, Lizenz, BetriebsAuftragNr, Plannr, SAuftrag,'
      + ' Schwesterauftrag, StartDatumZeit, Festdatum, Sollausstoss,'
      + ' EndDatumZeit, Taktzeit, Sollwert, Istwert, RuestZeit, Kopfgroesse, '
      + ' Var_Kavitaet, Stat, Betriebsart, planzykluszeit, ausschussquote, sollspannzeitstk from PDE'
      + ' where Lizenz = ''' + Lizenz + '''  Order by PlanNr';

      SQL_Get(qSuch, SQLStr);
      qSuch.Locate('Nr', Nr, []);
    end;

    if not Ins then
      qSuch2.Next;

  end;
  Result := True;
end;


procedure TThread_Zusatz.Laufzeit_Berechnen2;
var
  S, betrart, Nr, Liz: string;
  D1, D2: Real;
  Menge, Zeit, Zeit_Theor, Zeit_Rest: Integer;
begin
  S := 'update pde set Var_Kavitaet = 1 where Var_Kavitaet is null or Var_Kavitaet < 1';
  SQL_Insert(qUpdate, S);

  S := 'select * from PDE';
  SQL_Get(qSuch, S);
  while not qSuch.EOF do
  begin
    Nr := qSuch.FieldByName('Nr').AsString;
    Liz := qSuch.FieldByName('Lizenz').AsString;
    D1 := qSuch.FieldByName('StartDatumZeit').AsFloat;
    D2 := qSuch.FieldByName('EndDatumZeit').AsFloat;
    betrart := qSuch.FieldByName('Betriebsart').AsString;

    Zeit := ZeitInMinuten(Liz, D1, D2, betrart = GetL('Halbautomatik'));
    Zeit_Rest := ZeitInMinuten(Liz, MAX(D1, Now), MAX(D2, Now), betrart = GetL('Halbautomatik'));

    S := 'update PDE set'
      + ' Laufzeit = ' + IntToStr(Zeit) + ','
      + ' Laufzeit_Rest = ' + IntToStr(Zeit_Rest) + ','
      + ' Laufzeit_Plan = Trunc(Sollwert/Kopfgroesse*Var_Kavitaet*Taktzeit/100/60+Ruestzeit)'
      + ' where Nr = ' + Nr;
    SQL_Insert(qUpdate, S);

    if (qSuch.FieldByName('Stat').AsInteger = 0) and (qSuch.FieldByName('Taktzeit').AsFloat > 0) then
    begin
      Zeit := ZeitInMinuten(Liz, D1, Now, betrart = GetL('Halbautomatik'));
      Menge := Round(Zeit * 60 / qSuch.FieldByName('Taktzeit').AsFloat * 100
        * qSuch.FieldByName('Kopfgroesse').AsFloat
        / qSuch.FieldByName('Var_Kavitaet').AsFloat);

      Zeit_Theor := Round(qSuch.FieldByName('Istwert').AsFloat / qSuch.FieldByName('Kopfgroesse').AsFloat
        * qSuch.FieldByName('Var_Kavitaet').AsFloat
        * qSuch.FieldByName('Taktzeit').AsFloat / 100 / 60);

      S := 'update PDE set'
        + ' Theorwert = ' + IntToStr(Menge) + ','
        + ' ZeitDiff = ' + IntToStr(Zeit_Theor - Zeit)
        + ' where Nr = ' + Nr;
      SQL_Insert(qUpdate, S);
    end;

    qSuch.Next;
  end;
end;

procedure TThread_Zusatz.Status_Beschreibung;
var
  S, ST: string;
begin
  S := 'select Nr, Stat, Status, Festdatum, Optimiert, Mustern from PDE';
  SQL_Get(qSuch, S);
  while not qSuch.EOF do
  begin
    ST := '';
    case qSuch.FieldByName('Stat').AsInteger of
      0:if qSuch.FieldByName('Mustern').AsInteger =1 then
        begin
          ST := GetL('Mustern');
        end
        else
        begin
          case qSuch.FieldByName('Optimiert').AsInteger of
            0: ST := GetL('läuft');
            1: ST := GetL('optimiert');
          end;
        end;
      1: ST := GetL('rüsten');
      2:
        case qSuch.FieldByName('FestDatum').AsInteger of
          0: ST := GetL('geplant');
          1: ST := GetL('gepl./fest.');
        end;
      3:
        case qSuch.FieldByName('FestDatum').AsInteger of
          0: ST := GetL('terminiert');
          1: ST := GetL('term./fest.');
        end;
      4:
        case qSuch.FieldByName('FestDatum').AsInteger of
          0: ST := GetL('Wartung');
          1: ST := GetL('Wartung/fest.');
        end;
      5:
        case qSuch.FieldByName('FestDatum').AsInteger of
          0: ST := GetL('unterbrochen');
          1: ST := GetL('unterbr./fest.');
        end;
    end;
    S := 'update PDE set Status = ''' + ST + ''' where Nr = '
      + qSuch.FieldByName('Nr').AsString;
    SQL_Insert(qUpdate, S);
    qSuch.Next;
  end;
end;

procedure TThread_Zusatz.PlanListeReportParameterSchreiben(Par, Val: string);
var
  P, S: string;
begin
  P := UpperCase(Par);
  if SQLGet(qSuch, 'PlanGrafik_Report', 'Parameter', P, True) > 0 then
    S := 'update PlanGrafik_Report set Value = ''' + Val + ''' where Nr = '''
      + qSuch.FieldByName('Nr').AsString + ''''
  else
    S := 'insert into PlanGrafik_Report (Nr, Parameter, Value) values'
      + ' (PlanGrafik_ReportId.NextVal, '
      + '''' + P + ''','
      + '''' + Val + ''')';
  SQL_Insert(qUpdate, S);
end;


end.

