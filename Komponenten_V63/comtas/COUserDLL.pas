unit COUserDLL;

{
DLL Zur Verwendung von Benutzerauthentifizierungen

Zuerst muss InitDLL aufgerufen werden um die Instanzen der Querys und der Datenbank
zu initiieren. Der Rückgabewert gibt Auskunft über erfolg / Muisserfolg der
Initialisierung. Nach Beendigung muss ShutDLL aufgerufen werden um die Instanzen
wieder freizugeben.
Es ist wichtig zu jeder Funktion den Rückgabewert anhand der Konstanten
auszuwerten.

 }
interface
uses
  CO_DataBase,
  SysUtils,
  CO_UserLogin,
  Classes,
  SHA1, CO_Setup2;


var qUpdate : TCO_Query;
    qSuch : TCO_Query;
    qSuch2 : TCO_Query;
    Database : TCO_Database;
    userid : integer;
    loginsrc : string;

const
// Gutmeldung
  INCL_USR_OK = 0;

// Fehlermeldungen
  INCL_USR_WRONGPW = -1;
  INCL_USR_UNKNOWNUSER = -2;
  INCL_USR_LOCKED = -3;
  INCL_USR_PWEXPIRED = -4;
  INCL_USR_NOTVALID = -5;
  INCL_USR_INFO = -6;
  INCL_USR_NOINFO = -7;
  INCL_USR_PWNOTCHANGED = -8;
  INCL_USR_PWREADONLY = -9;
  INCL_USR_USERNOTLOGGEDIN = -10;

  INCL_USR_DBNOTCONNECTED = -11;

  INCL_USR_DLLNOLOAD = -253;
  INCL_USR_DLLNOFUNC = -254;
  INCL_USR_ERR = -255;
{$WRITEABLECONST ON}
const
  TUserEventClass_UserEventClass: TUserEventClass = nil;
{$WRITEABLECONST OFF}

function ULogEventInt(aEvent, aNote, aParam: String): Integer;
function UInitDLL(aDBUser, aDBPass, aServer: String): Integer;
function UShutDLL: Integer;
function UVerifyUser(aUsername, aPasswordKey: String): Integer;
function UGetUserInfo(aUsername: String; var aInfo: String): Integer;
function UGetMandant(aUsername: String; var aMandant: String): Integer;
function UGetUserGroup(aUsername: String): Integer;
function UGetValidDays(aUsername: String): Integer;
function UCheckPassword(aPassword: String): Integer;
function UCodePassword(aPassword: String; var aSHA1String: String): Integer;
function UChangePassword(aUsername, aOldPasswordHash, aNewPasswordHash: String): Integer;
function ULogin(aUserName, aPasswordKey, aSrc, aNote: String): Integer;
function ULogout(aUserName, aSrc, aNote: String): Integer;
function ULogEvent(aEvent, aNote, aParam: String): Integer;
function UStartLogging(aSource: String; aDatabase: TCO_Database): Integer;
function UEndLogging: Integer;
function UGetUserEventClass: TUserEventClass;


implementation

uses Dialogs;

function FloatToPunktString(aFloat: Extended): string;
begin
  Result := FloatToStr(aFloat);
  if Pos(',', Result) > 0 then
  begin
    Insert('.', Result, Pos(',', Result));
    Delete(Result, Pos(',', Result), 1);
  end;
end;


  { Freigegebene Funktionen für Benutzung außerhalb DLL }

  // DLL Intitialisieren
  // aDBUser - Benutzername für Datenbank
  // aDBPass - Passwort für Datenbank
  // aServer - Serverstring für Datenbankverbindung
  // Ergebnis :
  //  0 - OK,
  //  -11 - Datenbank nicht verbunden
  //  -255 - Fehler bei Ausführung
function ULogEventInt(aEvent, aNote, aParam: String): Integer;
var s : string;
    i : integer;
begin
  try
    i := 0;
    s := 'SELECT * FROM usr_events WHERE token = ''' + String(aEvent) + '''';
    qSuch.SQL.Text := s;
    qSuch.Open;
    if not qSuch.IsEmpty then
      i := qSuch.FieldByName('ID').AsInteger;

    s := 'INSERT INTO usr_eventlog (nr, eventdatetime, userid, source, eventid) '
      + ' VALUES (usr_eventlogid.nextval, ' + FloatToPunktString(Now) + ', ' + IntToStr(userid) + ','''
      + loginsrc + ''', ' + IntToStr(i)+ ')';
    qUpdate.SQL.Text := s;
    qUpdate.ExecSQL;
    result := INCL_USR_OK;
  except
    result := INCL_USR_ERR;
  end;
end;


function UInitDLL(aDBUser, aDBPass, aServer: String): Integer;
begin
  try
    Result := INCL_USR_ERR;
    Database := TCO_Database.Create(nil);
    Database.UserName := aDBUser;
    Database.Password := aDBPass;
    Database.Server := aServer;
    Database.Connected := True;

    if Database.Connected then
    begin
      qSuch := TCO_Query.Create(nil);
      qSuch.Database := Database;
      qSuch2 := TCO_Query.Create(nil);
      qSuch2.Database := Database;
      qUpdate := TCO_Query.Create(nil);
      qUpdate.Database := Database;
    end;

    if Database.Connected then
      Result := INCL_USR_OK
    else
      Result := INCL_USR_DBNOTCONNECTED;
  except
    Result := INCL_USR_ERR;
  end;
end;

// DLL Ende
// Ergebnis:
//  0 - OK,
//  -255 - Fehler in Ausführung

function UShutDLL: Integer;
begin
  try
    Result := INCL_USR_ERR;
    if Database <> nil then
      Database.Connected := False;
    if qUpdate <> nil then
      qUpdate.Destroy;
    if qSuch <> nil then
      qSuch.Destroy;
    if qSuch2 <> nil then
      qSuch2.Destroy;
    if Database <> nil then
      Database.Destroy;
    Result := INCL_USR_OK;
  except
    Result := INCL_USR_ERR;
  end;
end;

// Benutzer überprüfen
// aUsername - Benutzername des Benutzers
// aPasswordKey - Passwort des Benutzers als SHA-1 Key
// Ergebnis :
//   0 - OK,
//  -1 - falsches Passwort,
//  -2 - Benutzer unbekannt,
//  -3 - Benutzer gesperrt,
//  -4 - Passwort abgelaufen,
//  -5 - Info liegt vor
//  -255 - Fehler bei Ausführung

function UVerifyUser(aUsername, aPasswordKey: String): Integer;
var
  S: string;
begin
  try
    S := 'SELECT * FROM incl_user WHERE login = ''' + aUsername + '''';
    qSuch.SQL.Text := S;
    qSuch.Open;
    if qSuch.IsEmpty then
    begin
      Result := INCL_USR_UNKNOWNUSER;
      Exit;
    end;

    if qSuch.FieldByName('islocked').AsInteger = 1 then
    begin
      Result := INCL_USR_LOCKED;
      Exit;
    end;

    if qSuch.FieldByName('password').AsString <> string(aPasswordKey) then
    begin
      s := 'UPDATE incl_user SET wrongpwcounter = wrongpwcounter + 1 WHERE '
        + ' login = ''' + aUsername + '''';
      qUpdate.SQL.Text := s;
      qUpdate.ExecSQL;

      qUpdate.SQL.Text := 'UPDATE incl_user SET islocked = 1 , lockedat=' + FloatToPunktString(Now)
        + ' WHERE wrongpwcounter > ' + IntToStr(TCO_Setup.GetParamInt(qSuch2,'INCL_UserMaxInvalidPasswordAttempts'));
      qUpdate.ExecSQL;
      Result := INCL_USR_WRONGPW;
      Exit;
    end;

    if (qSuch.FieldByName('expires').AsFloat - Now) < 0 then
    begin
      Result := INCL_USR_PWEXPIRED;
      Exit;
    end;
    userid := qSuch.FieldByName('userid').asInteger;

    Result := INCL_USR_OK;

    s := 'UPDATE incl_user SET wrongpwcounter = 0, lastuse=' + FloatToPunktString(now) + ' WHERE '
      + ' login = ''' + aUsername + '''';
    qUpdate.SQL.Text := s;
    qUpdate.ExecSQL;
  except
    Result := INCL_USR_ERR;
  end;
end;

// Info für Benutzer abrufen
// aUsername - Benutzername des Benutzers
// aInfo - Rückgabewert der Info als Text
// Ergebnis :
//   0 - OK
//  -7 - Es liegt keine Meldung vor
//  -255 - Fehler bei Ausführung

function UGetUserInfo(aUsername: String; var aInfo: String): Integer;
begin
  aInfo := '';

  Result := INCL_USR_NOINFO;
end;

// Mandant für Benutzer abrufen
// aUsername - Benutzername des Benutzers
// aMandant - Mandant für den Benutzer
// Ergebnis :
//   0 - OK
//   -2 - Benutzer unbekannt
//  -255 - Fehler bei Ausführung

function UGetMandant(aUsername: String; var aMandant: String): Integer;
var
  S: string;
begin
  try
    Result := INCL_USR_ERR;
    S := 'SELECT * FROM incl_user WHERE login = ''' + aUsername + '''';
    qSuch.SQL.Text := S;
    qSuch.Open;
    if qSuch.IsEmpty then
    begin
      Result := INCL_USR_UNKNOWNUSER;
      Exit;
    end;
    aMandant := qSuch.FieldByName('Mandant').AsString;
    Result := INCL_USR_OK;
  except
    Result := INCL_USR_ERR;
  end;
end;

// Benutzergruppe als Integer
// aUsername - Benutzername des Benutzers
// Ergebnis :
//   Benutzergruppe
//  -2 - Benutzer unbekannt
//  -255 - Fehler bei Ausführung
function UGetUserGroup(aUsername: String): Integer;
var
  S: string;
begin
  try
    Result := INCL_USR_ERR;
{$IFDEF INCL_MSADO}
    S := 'SELECT perstype FROM incl_user WHERE login = ''' + aUsername + '''';
{$ELSE}
    S := 'SELECT perstype FROM incl_user WHERE login = ''' + aUsername + '''';
{$ENDIF}
    qSuch.SQL.Text := S;
    qSuch.Open;
    if qSuch.IsEmpty then
    begin
      Result := INCL_USR_UNKNOWNUSER;
      Exit;
    end;
    Result := qSuch.FieldByName('perstype').AsInteger;
  except on e:Exception do
    ShowMessage(e.Message);
  end;
end;

// Anzahl der Tage bis das Passwort abläuft
// aUsername - Benutzername des Benutzers
// Ergebnis :
//   Anzahl der Tage bis das Passwort abläuft
//  -2 - Benutzer unbekannt
//  -255 - Fehler bei Ausführung

function UGetValidDays(aUsername: String): Integer;
var
  S: string;
begin
  try
    Result := INCL_USR_ERR;
{$IFDEF INCL_MSADO}
    S := 'SELECT expires FROM incl_user WHERE login = ''' + aUsername + '''';
{$ELSE}
    S := 'SELECT expires FROM incl_user WHERE login = ''' + aUsername + '''';
{$ENDIF}
    qSuch.SQL.Text := S;
    qSuch.Open;
    if qSuch.IsEmpty then
    begin
      Result := INCL_USR_UNKNOWNUSER;
      Exit;
    end;
    Result := Trunc(qSuch.FieldByName('expires').AsFloat - Now);
  except
  end;
end;

// Passwort auf Gültigkeit überprüfen (3 Kriterien aus 4 müssen erfüllt sein)
// aPassword - zu überprüfendes Passwort
// Ergebnis :
//   0 - OK
//  -5 - Password ist nicht gültig
//  -255 - Fehler bei Ausführung

function UCheckPassword(aPassword: String): Integer;
const
  cNumber = 0;
  cSmall = 1;
  cLarge = 2;
  cSpecial = 3;

var
  typearray: array[0..3] of Boolean;
  I: Integer;
  C: Char;
  invalid: Boolean;
  typecount: Integer;
  _pw: string;
begin
  // Testen ob Passwort aus 3 von 4 Kreterien erfüllt
  // Länge >= 8 Zeichen
  // Ziffern, Großschreibung, Kleinschreibung, Sonderzeichen
  try
    for I := 0 to 3 do
      typearray[I] := False;

    invalid := False;
    _pw := aPassword;
    for I := 0 to Length(_pw) - 1 do
    begin
      C := _pw[I + 1];
      if C in ['0'..'9'] then
        typearray[cNumber] := True
      else
        if C in ['a'..'z'] then
          typearray[cSmall] := True
        else
          if C in ['A'..'Z'] then
            typearray[cLarge] := True
          else
            if C in ['`', '~', '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '_', '-',
            '+', '=', '{', '}', '[', ']', '\', '|', ':', ';', '"', '''', '<', '>', ',', '.', '?', '/'] then
              typearray[cSpecial] := True
            else
              invalid := True;
    end;
    typecount := 0;
    for I := 0 to 3 do
      if typearray[I] then
        Inc(typecount);

    if Length(_pw) < 8 then
      invalid := True;
    if (typecount > 2) and not invalid then
      Result := INCL_USR_OK
    else
      Result := INCL_USR_NOTVALID;
  except
    Result := INCL_USR_ERR;
  end;
end;

// Passwort auf Gültigkeit überprüfen (3 Kriterien aus 4 müssen erfüllt sein)
// aPassword - zu verschlüsselndes Passwort
// aSHA1String - PasswortHash als Rückgabe
// Ergebnis :
//   0 - OK
//  -255 - Fehler bei Ausführung

function UCodePassword(aPassword: String; var aSHA1String: String): Integer;
var
  _s, s2: string;
  i : Integer;
begin
  try
    // Nachgucken ob PW verschlüsselt ist.
    _s := 'SELECT * FROM setup_par WHERE schluessel = ''INCL_UserPasswordHashed''';
    qSuch.SQL.Text := _s;
    qSuch.Open;
    s2 := '1';
    if not qSuch.IsEmpty then
      s2 := qSuch.FieldByName('wert').AsString;
//    _s := GetHashedString(string(aPassword));
    if s2 <> '0' then
      _s := FunSHA1(aPassword)
    else
      _s := aPassword;
    //aSHA1String := GetMemory(length(_s));
    aSHA1String := _s;
//    StrPCopy(aSHA1String, _s);
    Result := INCL_USR_OK;
  except
    Result := INCL_USR_ERR;
  end;

end;

// Passwort ändern
// aUsername - Benutzername das Benutzers dessen Password geändert werden soll
// aOldPasswordHash - Passwort Hash des alten Passwortes
// aNewPasswordHash - Passwort Hash des neuen Passwortes
// aSHA1String - PasswortHash als Rückgabe
// Ergebnis :
//   0 - OK, Passwort erfolgreich geändert
//   -2 - Benutzer unbekannt
//   -8 - Passwort wurde nicht geändert
//   -9 - Passwort kann nicht geändert werden
//  -255 - Fehler bei Ausführung

function UChangePassword(aUsername, aOldPasswordHash, aNewPasswordHash: String): Integer;
var
  S, Nr, opw: string;
  days: Integer;
begin
  try
    result := INCL_USR_ERR;

    // Nachgucken ob dies eins der letzten 5 Passwörter ist
    s := 'SELECT count(*) cnt FROM usr_passwordhistory WHERE pwhash = ''' + aNewPasswordHash + '''';
    qSuch.SQl.Text := s;
    qSuch.Open;
    if not qSuch.IsEmpty then
    begin
      if qSuch.FieldByName('cnt').AsInteger > 0 then
      begin
        result := INCL_USR_WRONGPW;
        exit;
      end;
    end;

    s := 'SELECT nr, validdays, userid FROM incl_user WHERE login = ''' + aUsername + ''' AND '
     + ' password = ''' + String(aOldPasswordHash) + '''';
    qSuch.SQl.Text := s;
    qSuch.Open;
    if qSuch.IsEmpty then
    begin
      Result := INCL_USR_UNKNOWNUSER;
      Exit;
    end;
    days := qSuch.FieldByName('validdays').AsInteger;
    nr := qSuch.FieldByName('nr').AsString;
    userid := qSuch.FieldByName('userid').AsInteger;
    s := 'UPDATE incl_user SET password = ''' + aNewPasswordHash + ''', expires='''
      + IntToStr(trunc(now) + days)+ ''' WHERE nr = ''' + nr + '''';
    qSuch.SQL.Text := s;
    qSuch.ExecSQL;


    result := INCL_USR_OK;

    // Neues Passwort eintragen
    s := 'INSERT INTO usr_passwordhistory (nr, userid, firstusedate, pwhash) VALUES ('
      +  ' usr_passwordhistoryid.nextval, ' + IntToStr(userid) + ', ' + FloatToPunktString(now)
      + ', ''' + aNewPasswordHash + ''')';
    qUpdate.SQl.Text := s;
    qUpdate.ExecSQL;

    s := 'SELECT COUNT(*) cnt FROM usr_passwordhistory WHERE userid = ' + IntToStr(userid);
    qSuch.SQL.Text := s;
    qSuch.Open;
    if not qSuch.IsEmpty then
    begin
      if qSuch.FieldByName('cnt').AsInteger > TCO_Setup.GetParamInt(qSuch2, 'USR_Password_History') then
      begin
        s := 'DELETE FROM usr_passwordhistory WHERE nr = '
          + ' (SELECT MIN(nr) FROM usr_passwordhistory WHERE userid = '
          + IntToStr(userid) + ')';
        qUpdate.SQl.Text := s;
        qUpdate.ExecSQL;
      end;
    end;
  except
    Result := INCL_USR_ERR;
  end;

end;

// Benutzer anmelden
// Funktion wie VerifyUser, jedoch mit zusätzlichem Log in der Datenbank
// aUsername - Benutzername des Benutzers
// aPasswordKey - Passwort des Benutzers als SHA-1 Key
// aSRC - von wo wurde angemeldet
// aNote - zusätzliche Notizen für Anmeldevorgang
// Ergebnis :
//   0 - OK,
//  -1 - falsches Passwort,
//  -2 - Benutzer unbekannt,
//  -3 - Benutzer gesperrt,
//  -4 - Passwort abgelaufen,
//  -5 - Info liegt vor
//  -255 - Fehler bei Ausführung

function ULogin(aUserName, aPasswordKey, aSrc, aNote: String): Integer;
var _pchar : pchar;
    s : string;
begin
  result := UVerifyUser(aUsername, aPasswordKey);
  loginsrc := aSrc;
  if result = INCL_USR_OK then
  begin
    try
      ULogEventInt(PCHAR('SLI'),aSRC,aNote);
      s := 'INSERT INTO usr_logontime (nr, userid, logon, src_login, notice) '
        + ' VALUES(usr_logontimeid.nextval,' + IntToStr(userid) + ','
        + FloatToPunktString(now) + ',''' + aSRC + ''',''' + aNote + ''')';
      qUpdate.SQL.Text := s;
      qUpdate.ExecSQL;

      s := 'UPDATE Incl_User SET Wrongpwcounter = 0, '
        + ' lastuse = ' + FloatToPunktString(now) + ' WHERE login = ''' + aUsername + '''';
      qUpdate.SQL.Text := s;
      qUpdate.ExecSQL;
    except
    end;
  end;

end;

// Benutzer abmelden
// aUsername - Benutzername des Benutzers
// aSRC - von wo wurde angemeldet
// aNote - zusätzliche Notizen für Anmeldevorgang
// Ergebnis :
//   0 - OK,
//  -10 - Benutzer ist nicht angemeldet,
//  -255 - Fehler bei Ausführung

function ULogout(aUserName, aSrc, aNote: String): Integer;
var s : string;
begin
  result := ULogEventInt('SLO', aNote, '');
  begin
    try
      s := 'UPDATE usr_logontime SET logout = ''' + FloatTostr(now) + ''','
        + ' src_logout = ''' + aSrc + ''' WHERE userid = ' + IntToStr(userid);
    qUpdate.SQL.Text := s;
    qUpdate.ExecSQL;
    except
    end;
  end;

  Result := INCL_USR_OK;
end;

// Userevent loggen
// aEvent - Event der zu loggen ist
// aNote - Notiz dazu
// aParam - Parameter lt. Eventliste

function ULogEvent(aEvent, aNote, aParam: String): Integer;
begin
  result := ULogEventInt(aEvent, aNote, aParam);
end;

{ Interne Funktionen }

// Start und Init der Log Prozesse

function UStartLogging(aSource: String; aDatabase: TCO_Database): Integer;
var
  evc: TUserEventClass;
begin
  Result := -1;
  if TUserEventClass_UserEventClass = nil then
    TUserEventClass_UserEventClass := TUserEventClass.Create;
  evc := TUserEventClass_UserEventClass;
  //  evc.fSource := aSource;
  //  evc.fDatabase := aDatabase;
  //  evc.fQuery := TCO_Query.Create(evc.fDatabase.Owner);
end;

// Ende des Log Prozesses

function UEndLogging: Integer;
begin
  Result := 0;
  if TUserEventClass_UserEventClass = nil then
    Exit;
  if TUserEventClass_UserEventClass <> nil then
    TUserEventClass_UserEventClass.Free;
end;

function UGetUserEventClass: TUserEventClass;
begin
  Result := TUserEventClass_UserEventClass;
end;


begin
end.

(*
  Eventliste zum loggen

  Eventaufbau : ID,Kurzbezeichnung,Beschreibung,Parameter notwendig(Parameter)

  // System Token mit S am Anfang
  1,'SLI','Anmeldung am System',false   // SystemLogIn
  2,'SLO','Abmeldung vom System',false  // SystemLogOut
  3,'SCP','Systempasswort geändert',false  // SystemChangePassword
  4,'SWP','Systempasswort falsch eingegeben',false  // SystemWrongPassword
  5,'SSL','Start Systemprotokollierung',true  // SystemStartLog
  6,'SFl','Ende Systemprokollierung',false  // SystemFinishLog

// Auftrags Token mit W (workorder) am Anfang
  101,'WST','Auftrag gestartet',true(AuftragNr / Maschine) // WorkorderSTart
  102,'WFI','Auftrag beendet',true(AuftragNr) // WorkorderFInish
  102,'WSU','Auftrag gerüstet',true(AuftragNr) // WorkorderSetUp
  104,'WIR','Auftrag unterbrochen',true(AuftragNr) // WorkorderInteRupt
  105,'WCA','Auftragsmenge geändert',true(AuftragNr / Alte Menge / Neue Menge) // WorkorderChangeAmount
  106,'WCC','Auftragskavität geändert',true(AuftragNr / Alte Kavität / Neue Kavität) // WorkorderChangeCavity
  107,'WCM','Maschine geändert',true(AuftragNr / Alte Maschine / neue Maschine) // WorkorderChangeMachine
  108,'WCD','Liefertermin verändert',true(AuftragNr) // WorkorderChangeDeliverydate
  109,'WCS','Starttermin verändert',true(AuftragNr / Alter Starttermin / Neuer Starttermin) // WorkorderChangeStarttime
  110,'WCT','Werkzeug verändert',true(AuftragNr / Altes Werkzeug / Neues Werkzeug) // WorkorderChangeTool
  111,'WPR','Auftrag gedruckt',true(AuftragNr) // WorkorderPRint
  112,'WRL','Auftrag freigegeben',true(AuftragNr) // WorkorderReLease
  113,'WCL','Auftrag abgeschlossen',true(AuftragNr) // WorkorderCLose
  114,'WRA','Auftrag reaktiviert',true(AuftragNr) // WorkorderReActivated
  115,'WBS','Ausschuss auf Auftrag gebucht',true(AuftragNr) // WorkorderBookScrap
  116,'WCY','Auftrag Solltaktzeit geändert',true(AuftragNr / Alte Zeit / Neue Zeit) // WorkorderChangecYcletime

// Stillstands Token mit D (downtime) am Anfang
  201,'DBK','Stillstand gebucht',true(Maschine / Grundbezeichnung)// DowntimeBooKed
  202,'DSP','Stillstand gesplittet',true(Maschine / StillstandNr alt / Stillstandnr neu) // DowntimeSPlitted
  203,'DCS','Anfangszeit vom Stillstand verändert(Maschine / Alte Zeit / Neue Zeit)',true // DowntimeChangeStart
  204,'DCE','Endezeit vom Stillstand verändert(Maschine / Alte Zeit / Neue Zeit)',true // DowntimeChangeEnd
  205,'DCR','Stillstandsgrund verändert(Maschine / Alte Grundbez. / Neue Grundbez.)',true // DowntimeChangeReason

// Artikel Token mit P (part) am Anfang
  301,'PCC','Artikelkavität geändert',false  // PartChangeCavity
  302,'PCW','Artikelgewicht geändert',false  // PartChangeWeight

// Werkzeug Token mit T (tool) am Anfang
  401,'TCC','Werkzeugkavität geändert',true(WerkzeugNr / Alte Kavität / Neue Kavität)  // ToolChangeCavity
  402,'TRL','Werkzeugstandzeit zurück gesetzt(WerkzeugNr)',true  // ToolResetLifetime

// Maschinen Token mit M am Anfang
  501,'MCC','Maschinenkavität geändert',true(Maschine / Alte Kavität / Neue Kavität) // MachineChangeCavity
  502,'MCY','Maschinenzykluszeit geändert',true(Maschine / Alte Zykluszeit / Neue Zykluszeit) // MachineChangecYcletime
  511,'MLI','Anmeldung an Maschine',true(Maschine) // MachineLogIn
  512,'MLO','Abmeldung von Maschine',true(Maschine) // MachineLogOut
  
  // Anwendung Token mit A am Anfang
  601, 'ACC', 'Werkskalender geändert', false // ApplicationChangeCalendar
  602, 'ACD', 'Stillstand geändert', true(Stillstandnr / Wert / Alt / Neu) // ApplicationChangeDowntime
  603, 'ACS', 'Ausschuss geändert', true(Ausschuss / Wert / Alt / Neu) // ApplicationChangeScrap

*)

