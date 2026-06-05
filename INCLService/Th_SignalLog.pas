unit Th_SignalLog;

interface

uses
    {$IFNDEF AZURE}
  Main,
  {$ELSE}
  MainAzure,
  {$ENDIF}
Classes, SQL_fuc, CO_DataBase, Windows;

type
  TSignalClass = class
  public
    SignalNr: Integer;
    Nr: Integer;
    MaschNr: Integer;
    Istwert: string;
    oldwert: string;
    oldlognr: Integer;
  end;

type
  TThread_SignalLog = class(TThread)
  private
    { Private declarations }
    CDatabase: TCO_Database;
    qSuch, qSuch2, qUpdate: TCO_Query;
    entryList: TList;

    function FloatToPunktStr(aFloat: Extended): string;
    function getSignalByNumbers(aMaschnr, aSignalNr: Integer): TSignalClass;
    function getSignalBySeqNumber(ANr: Integer): TSignalClass;
  protected
    procedure Execute; override;

  public
    constructor Create(suspended: Boolean);
    destructor Destroy; override;
  end;

var
  Thread_Signallog: TThread_SignalLog;
  Event_SignalLog: THandle;

implementation

uses
  DB, SysUtils, DBMain, Arbeit, CO_Setup2;

{
  Der Thread kümmert sich um die Erzeugung eines Signal Protokolls. Jede Änderung
  von Signalen, die zu protokollieren sind wird hier eingetragen
 }

{ SignalLog }

constructor TThread_SignalLog.Create(suspended: Boolean);
var
  sc: TSignalClass;
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

  qUpdate := TCO_Query.Create(nil);
  qUpdate.Database := CDatabase;

  entryList := TList.Create;

  {$IFDEF INCL_MSADO}
    qSuch.Database.Connected := true;
    qSuch.Database.Connected := false;
  {$ENDIF}

  if TCO_Setup.GetParamInt(qSuch, 'INCL_AutoSetup2Time') > 0 then
  qSuch.SQL.Text := 'SELECT sm.nr nr, sm.maschnr maschnr, s.signalnr signalnr, sm.istwert istwert'
    + ' FROM signale s '
    + ' LEFT JOIN signal_maschine sm ON sm.signalnr = s.signalnr '
    + ' WHERE s.logit=1 OR s.signalart = 24'
  else
  // Signalliste anlegen und aktuelle Werte lesen
  qSuch.SQL.Text := 'SELECT sm.nr nr, sm.maschnr maschnr, s.signalnr signalnr, sm.istwert istwert'
    + ' FROM signale s '
    + ' LEFT JOIN signal_maschine sm ON sm.signalnr = s.signalnr '
    + ' WHERE s.logit=1';
  qSuch.Open;
  {$IFDEF INCL_MSADO}
    qSuch.Open;
  {$ENDIF}
  while not qSuch.EOF do
  begin
    sc := TSignalClass.Create;
    sc.SignalNr := qSuch.FieldByName('signalnr').AsInteger;
    sc.Nr := qSuch.FieldByName('nr').AsInteger;
    sc.MaschNr := qSuch.FieldByName('maschnr').AsInteger;
    sc.Istwert := qSuch.FieldByName('istwert').AsString;
    sc.oldwert := '0';
    entryList.Add(sc);
    qSuch.Next;
  end;

  // Alte Werte in Signalliste eintragen
  qSuch.SQL.Text := 'SELECT * FROM signallog WHERE enddatumzeit IS null';
  qSuch.Open;
  while not qSuch.EOF do
  begin
    sc := getSignalByNumbers(qSuch.FieldByName('maschnr').AsInteger,
      qSuch.FieldByName('signalnr').AsInteger);
    if sc <> nil then
    begin
      sc.oldwert := qSuch.FieldByName('wert').AsString;
      sc.oldlognr := qSuch.FieldByName('nr').AsInteger;
    end;
    qSuch.Next;
  end;
end;

destructor TThread_SignalLog.Destroy;
begin
  qSuch.Free;
  qSuch2.Free;
  qUpdate.Free;

  CDatabase.Free;
  inherited;
end;

procedure TThread_SignalLog.Execute;
var
  sc: TSignalClass;

begin
  { Place thread code here }
  // Zuerst wird der aktuelle Zustand eingelesen

  while not Terminated do
  begin
    WaitForSingleObject(Event_SignalLog, INFINITE);
    try
      // Lesen von aktuellen Werten und Vergleichen
      // Wenn Änderungen, dann neuen Eintrag schreiben
      qSuch.SQL.Text := 'SELECT sm.nr nr, sm.maschnr maschnr, s.signalnr signalnr, sm.istwert istwert'
        + ' FROM signale s '
        + ' LEFT JOIN signal_maschine sm ON sm.signalnr = s.signalnr '
        + ' WHERE s.logit=1';
      qSuch.Open;
      while not qSuch.EOF do
      begin
        sc := getSignalBySeqNumber(qSuch.FieldByName('nr').AsInteger);
        if sc <> nil then
        begin
          sc.Istwert := qSuch.FieldByName('istwert').AsString;
          if sc.Istwert <> sc.oldwert then
          // neuen Eintrag machen und alten beenden
          begin
            if (sc.oldlognr > -1) then
            begin
              qUpdate.SQL.Text := 'UPDATE signallog SET enddatumzeit = ' +
                FloatToPunktStr(N_o_w) + ' WHERE nr = ' + IntToStr(sc.oldlognr);
              qUpdate.ExecSQL;
            end;

            sc.oldwert := sc.Istwert;

            qSuch2.SQL.Text := 'SELECT signallogid.nextval nv FROM dual';
            qSuch2.Open;
            sc.oldlognr := qSuch2.FieldByName('nv').AsInteger;

            qUpdate.SQL.Text := 'INSERT INTO signallog (nr, startdatumzeit, wert, maschnr, signalnr)'
              + ' VALUES (' + IntToStr(sc.oldlognr) + ', ' + FloatToPunktStr(N_o_w) + ', ''' + sc.Istwert
              + ''', ' + IntToStr(sc.MaschNr) + ', ' + IntToStr(sc.SignalNr) + ')';
            qUpdate.ExecSQL;
          end;
          qSuch.Next;
        end;
      end;
    except
    end;
  end;
end;

function TThread_SignalLog.FloatToPunktStr(aFloat: Extended): string;
begin
  Result := FloatToStr2(aFloat);
  if Pos(',', Result) > 0 then
  begin
    Insert('.', Result, Pos(',', Result));
    Delete(Result, Pos(',', Result), 1);
  end;
end;

function TThread_SignalLog.getSignalByNumbers(aMaschnr, aSignalNr: Integer): TSignalClass;
var
  I: Integer;
  sc: TSignalClass;
begin
  Result := nil;
  for I := 0 to entryList.Count - 1 do
  begin
    sc := TSignalClass(entryList.Items[I]);
    if (sc.MaschNr = aMaschNr) and (sc.SignalNr = aSignalNr) then
    begin
      Result := sc;
      Exit;
    end;
  end;
end;

function TThread_SignalLog.getSignalBySeqNumber(ANr: Integer): TSignalClass;
var
  I: Integer;
  sc: TSignalClass;
begin
  Result := nil;
  for I := 0 to entryList.Count - 1 do
  begin
    sc := TSignalClass(entryList.Items[I]);
    if (sc.Nr = ANr) then
    begin
      Result := sc;
      Exit;
    end;
  end;
end;

end.

