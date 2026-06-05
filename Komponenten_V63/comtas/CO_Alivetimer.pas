unit CO_Alivetimer;

//******************************************************************************
//                                  Klasse CO_AliveTimer
//
//    In der Klasse wird ein Zähler (Lebensmerker) in der Datenbank überwacht.
//    Es können zu jedem Ereignis beliebige Mailadressen und Texte ausgegeben
//    werden.
//    Es wird jede  5 Sekunden auf Veränderung der Lebensmerker geprüft. Sollte
//    der Lebensmerker für 'TimeOut' Sekunden den selben Werten haben, wird
//    eine Down Meldung ausgelöst. Verändert sich der Lebensmerker wieder, wird
//    eine Up Meldung ausgelöst.
//
//
//******************************************************************************
interface

uses
  Classes, ExtCtrls, CO_DataBase, SysUtils, Windows;

type
  TCO_AliveClient = class
  private
    fTimeOut: Integer;
    FApplication: string;
    fDatabase: TCO_Database;
    fOwner: TComponent;
    FQuery: TCO_Query;
    logpath: string;
    displayname: string;
    WithoutTrigger: Boolean;
    fDelete: Boolean;
    _diffTimeZoneDays : Extended;
    diffTimeZone : Boolean;
    dBTimeZone : String;

    function ComputerName : String;
  public
    property Application: string read FApplication;
    property TimeOut: Integer read fTimeOut;

    function tick: Boolean;

    constructor Create(aDatabase: TCO_Database; aApplication: string;
      aTimeOut: Integer; AOwner: TComponent;
      lp: string = ''; dn: string = ''; deleteOnDestroy: boolean = false);
    destructor Destroy; override;
  end;

type
  TCO_AliveTimer = class

  private
    fTimeOut: Integer; // Timeout in Sekunden
    fMsgDown: string; // Message die beim Überschreiten des TO gesendet wird
    fSubjectDown: string; // Subject bei Überschreiten TO
    fMsgUp: string; // Message die bei Wiederaufnahme gesendet wird
    fSubjectUp: string; // Subject bei Wiederaufnahme
    fToList: TStringList; // Liste der Mailadressen To:
    fCCList: TStringList; // Liste der Mailadressen CC:
    fBCCList: TStringList; // Liste der Mailadressen BCC:
    fFromAddress: string; // Mailadresse die als Absender benutzt wird
    fSystem: string; // Eintrag in INC_Meldung welches System überwacht wird
    fAlert: Boolean; // Alarm aktiv, wird nach Abfrage zurück gesetzt
    fAlertMerker: Boolean; // Alarmmerker
    fSystemOK: Boolean; // Meldung nach Alarm, wieder alles OK
    fOwner: TComponent;
    //fLebensmerker: Integer; // Letzter Lebensmerker
    //fFehlerzaehler: Integer; // Anzahl fehlerhaft gelesener Lebensmerker

    fTimer: TTimer;
    fLastTime: TDateTime; // Timer der auf TimeOut wartet
    fLastTimeintern: TDateTime;

    fMaxErrors: Integer;
    FQuery: TCO_Query;

    function getAlert: Boolean;
    function getSystemOK: Boolean;

    procedure OnTimer(Sender: TObject);

  public
    property TimeOut: Integer read fTimeOut write fTimeOut;
    property MsgDown: string read fMsgDown write fMsgDown;
    property SubjectDown: string read fSubjectDown write fSubjectDown;
    property MsgUp: string read fMsgUp write fMsgUp;
    property SubjectUp: string read fSubjectUp write fSubjectUp;
    property ToList: TStringList read fToList write fToList;
    property CCList: TStringList read fCCList write fCCList;
    property BCCList: TStringList read fBCCList write fBCCList;
    property FromAddress: string read fFromAddress write fFromAddress;
    property System: string read fSystem write fSystem;
    property LastTime: TDateTime read fLastTime write fLastTime;
    property LastTimeIntern: TDateTime read fLastTimeintern;

    property MaxErrors: Integer read fMaxErrors write fMaxErrors;

    property Alert: Boolean read getAlert;
    property SystemOK: Boolean read getSystemOK;

    procedure StartTimer;

    procedure Free;

    constructor Create(aDatabase: TCO_Database; AOwner: TComponent);
    destructor Destroy; override;
  end;

  TCO_AliveTimerList = class(TList)
  private
    function getItem(index: Integer): TCO_AliveTimer;
    procedure setItem(index: Integer; const Value: TCO_AliveTimer);

  public
    property Items[index: Integer]: TCO_AliveTimer read getItem write setItem;

    function Add(aAliveTimer: TCO_AliveTimer): Integer;

    constructor Create;
    destructor Destroy; override;
  end;

implementation

function FloatToPunktString(aFloat: Extended): string;
begin
  Result := FloatToStr(aFloat);
  if Pos(',', Result) > 0 then
  begin
    Insert('.', Result, Pos(',', Result));
    Delete(Result, Pos(',', Result), 1);
  end;
end;


// *****  private  *****

function TCO_AliveTimer.getAlert: Boolean;
begin
  Result := fAlert;
  fAlert := False;
end;

function TCO_AliveTimer.getSystemOK: Boolean;
begin
  Result := fSystemOK;
  if fSystemOK then
  begin
    fSystemOK := False;
    fAlertMerker := False;
  end;
end;

procedure TCO_AliveTimer.OnTimer(Sender: TObject);
var
  S: string;
begin
  // Feld in Datenbank checken und Lebensmerker merken
  S := 'SELECT * FROM alivetimer WHERE application = ''' + fSystem + '''';
  // fTimeOut ist die Zeit in Sekunden bis ein neues Signal kommen müsste.
  // 3 mal Timeout heißt Alarm
  FQuery.SQL.Text := S;
  FQuery.Open;
  if not FQuery.IsEmpty then
  begin
    fLastTimeintern := FQuery.FieldByName('lasttimer').AsFloat;
    FQuery.Close;
    (*
    if lm <> fLebensmerker then
    begin
      fLebensmerker := lm;
      fFehlerzaehler := 0;
      fLastTimeintern := now;
    end;
      *)
    if ((Now - fLastTimeintern) * 1440 * 60) > (fTimeOut * fMaxErrors) then
      fAlert := (not fAlertMerker) or fAlert
    else
      fSystemOK := fAlertMerker;

    if fAlert then
      fAlertMerker := fAlert;
  end;

end;

// *****  public  *****

procedure TCO_AliveTimer.StartTimer; // Trigger für Timerstart
begin
  OnTimer(nil);
  fTimer.ENABLED := True;
end;

procedure TCO_AliveTimer.Free;
begin
  Self.Destroy;
end;

// Ich weiß dass es Mist ist, aber es gibt nur noch einen Service der unter Delphi läuft. Wenn der nicht USA ist
// dann aTimeZoenDiff auf 0, sonst lesen. Sorry. ML 12.2.21
constructor TCO_AliveTimer.Create(aDatabase: TCO_Database; AOwner: TComponent);
begin
  inherited Create;
  fOwner := AOwner;

  FQuery := TCO_Query.Create(AOwner);
  FQuery.Database := aDatabase;

  fToList := TStringList.Create;
  fCCList := TStringList.Create;
  fBCCList := TStringList.Create;


  fMaxErrors := 3;
  fTimer := TTimer.Create(AOwner);
  fTimer.OnTimer := OnTimer;
  fTimer.Interval := 5000;
  fTimer.ENABLED := False;
  fAlertMerker := False;
  fSystemOK := False;
  fAlert := False;
end;

destructor TCO_AliveTimer.Destroy;

  procedure FreeList(var aStringList: TStringList);
  begin
    while aStringList.Count > 0 do
      aStringList.Delete(0);
    aStringList.Free;
  end;

begin
  fTimer.ENABLED := False;

  FreeList(fToList);
  FreeList(fCCList);
  FreeList(fBCCList);

  fTimer.Free;
  FQuery.Destroy;
  inherited;
end;

{ TCO_AliveClient }

constructor TCO_AliveClient.Create(aDatabase: TCO_Database; aApplication: string;
  aTimeOut: Integer; AOwner: TComponent;
  lp: string = ''; dn: string = ''; deleteOnDestroy: boolean = false);
begin
  logpath := Copy(lp, Pos('\',lp), length(lp) - Pos('\',lp) + 1);
  displayname := dn;
  fTimeOut := aTimeOut;
  FApplication := aApplication;
  fDatabase := aDatabase;
  fOwner := AOwner;
  fDelete := deleteOnDestroy;


  FQuery := TCO_Query.Create(AOwner);
  FQuery.Database := fDatabase;

  try
    FQuery.SQL.Text := 'SELECT * FROM setup_par WHERE SCHLUESSEL IN ' +
      '(''INCL_AliveTimerWithoutTrigger'', ''INCL_AliveTimerWithTimeDifference'')';
    FQuery.Open;
    while not FQuery.Eof do
    begin
      if FQuery.FieldByName('SCHLUESSEL').AsString = 'INCL_AliveTimerWithoutTrigger'  then
        WithoutTrigger := FQuery.FieldByName('Wert').AsInteger = 1;
      if FQuery.FieldByName('SCHLUESSEL').AsString = 'INCL_AliveTimerWithTimeDifference'  then
        diffTimeZone := FQuery.FieldByName('Wert').AsInteger = 1;
      FQuery.Next;
    end;

    if diffTimeZone then
    begin
   {$IFDEF INCL_MSADO}
      // Lokale TimeZone holen und Differenz zu
      FQuery.SQL.Text := 'SELECT CAST(CURRENT_TIMESTAMP as FLOAT) + 2 dbtime FROM dual ';
      FQuery.Open;
      if not FQuery.Eof then
      begin
        _diffTimeZoneDays := FQuery.FieldByName('dbtime').AsFloat - Now;
      end;
  {$ELSE}
      _diffTimeZoneDays :=0;
  {$ENDIF}
    end
    else
    begin
      _diffTimeZoneDays :=0;
    end;
  except
  end;

  tick;
end;

destructor TCO_AliveClient.Destroy;
begin
  if fDelete then
  begin
    FQuery.SQL.Text := 'DELETE FROM alivetimer WHERE Application = ''' + FApplication + '''';
    FQuery.ExecSQL;
  end;
  FQuery.Free;

  inherited;
end;

function TCO_AliveClient.tick: Boolean;
var
  S: string;
begin
  Result := False;
  try
    S := 'SELECT * FROM alivetimer WHERE Application = ''' + FApplication + '''';
    FQuery.SQL.Text := S;
    FQuery.Open;
    if FQuery.IsEmpty then
      if WithoutTrigger then
      begin
        {$IFDEF INCL_MSADO}
          S := 'INSERT INTO alivetimer (Nr, Application, LastTimer, TimeOut, AliveMarker, dbtimestamp, ServiceDisplayName)'
          + ' VALUES (alivetimerID.nextval,''' + FApplication + ''',' + FloatToPunktString(Now+_diffTimeZoneDays)
          + ', ''' + IntToStr(fTimeOut) + ''', 1, CAST(CURRENT_TIMESTAMP as FLOAT) + 2, ''' + displayname + ''')'
        {$ELSE}
          S := 'INSERT INTO alivetimer (Nr, Application, LastTimer, TimeOut, AliveMarker, dbtimestamp, ServiceDisplayName)'
          + ' VALUES (alivetimerID.nextval,''' + FApplication + ''',' + FloatToPunktString(Now+_diffTimeZoneDays)
          + ', ''' + IntToStr(fTimeOut) + ''', 1, Trunc(sysdate - to_date(''30.12.1899'', ''dd.mm.yyyy''),20), ''' + displayname + ''')'
        {$ENDIF}
      end
      else
        S := 'INSERT INTO alivetimer (Nr, Application, LastTimer, TimeOut, AliveMarker, ServiceDisplayName)'
          + ' VALUES (alivetimerID.nextval,''' + FApplication + ''',' + FloatToPunktString(Now)
          + ', ''' + IntToStr(fTimeOut) + ''', 1, ''' + displayname + ''')'
    else
      if WithoutTrigger then
      begin
        {$IFDEF INCL_MSADO}
          S := 'UPDATE alivetimer SET LastTimer=' + FloatToPunktString(Now+_diffTimeZoneDays)
            + ', TimeOut= ''' + IntToStr(fTimeOut)
            + ''', AliveMarker=''' + IntToStr(FQuery.FieldByName('alivemarker').AsInteger + 1) + ''','
            + ' dbtimestamp = CAST(CURRENT_TIMESTAMP as FLOAT) + 2'
            + ' WHERE Application = ''' + FApplication + '''';
        {$ELSE}
          S := 'UPDATE alivetimer SET LastTimer=' + FloatToPunktString(Now+_diffTimeZoneDays)
            + ', TimeOut= ''' + IntToStr(fTimeOut)
            + ''', AliveMarker=''' + IntToStr(FQuery.FieldByName('alivemarker').AsInteger + 1) + ''','
            + ' dbtimestamp = Trunc(sysdate - to_date(''30.12.1899'', ''dd.mm.yyyy''),20)'
            + ' WHERE Application = ''' + FApplication + '''';
        {$ENDIF}
      end
      else
        S := 'UPDATE alivetimer SET LastTimer=' + FloatToPunktString(Now+_diffTimeZoneDays)
          + ', TimeOut= ''' + IntToStr(fTimeOut)
          + ''', AliveMarker=''' + IntToStr(FQuery.FieldByName('alivemarker').AsInteger + 1) + ''''
          + ' WHERE Application = ''' + FApplication + '''';
    FQuery.Close;
    FQuery.SQL.Text := S;
    FQuery.ExecSQL;
    Result := True;
  except
  end;
  if ( (logpath <> '' ) and ( displayname <> '' ) ) then
    try
      S := 'SELECT * FROM ALIVETIMERCOMMENT WHERE Application = ''' + FApplication + '''';
      FQuery.SQL.Text := S;
      FQuery.Open;
      if FQuery.IsEmpty then
      begin
        S := 'INSERT INTO ALIVETIMERCOMMENT (Nr, Application, AliveComment, Logfile)'
          + ' VALUES (ALIVETIMERCOMMENTID.nextval,''' + FApplication + ''', ''Restart Service ' + displayname + ' on '
          + ComputerName + ''', ''\\' + ComputerName  + logpath + ''')';
        FQuery.Close;
        FQuery.SQL.Text := S;
        FQuery.ExecSQL;
      end;
    except
    end;
end;

{ TCO_AliveTimerList }

function TCO_AliveTimerList.Add(aAliveTimer: TCO_AliveTimer): Integer;
begin
  Result := TList(Self).Add(aAliveTimer);
end;

constructor TCO_AliveTimerList.Create;
begin

  inherited;
end;

destructor TCO_AliveTimerList.Destroy;
begin
  while Self.Count > 0 do
  begin
    Self.Items[0].Destroy;
    Self.Delete(0);
  end;
  inherited;
end;

function TCO_AliveTimerList.getItem(index: Integer): TCO_AliveTimer;
begin
  Result := TCO_AliveTimer(TList(Self).Items[index]);
end;

procedure TCO_AliveTimerList.setItem(index: Integer;
  const Value: TCO_AliveTimer);
begin
  Self[index] := Value;
  //  Self.Add(Value);
end;

function TCO_AliveClient.ComputerName : String;
var
  buffer: array[0..255] of char;
  size: dword;
begin
  size := 256;
  if GetComputerName(buffer, size) then
    Result := buffer
  else
    Result := ''
end;


end.

