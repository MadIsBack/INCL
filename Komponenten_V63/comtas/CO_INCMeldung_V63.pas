unit CO_INCMeldung_V63;

interface

uses
  CO_DataBase, CO_Library_V63, Windows, SysUtils, Classes, Controls, Variants, Forms, comtas_hkomp_V63,
  ComObj, CO_SPC_V63, Types, fKill_V63, CO_INCMeldungForm_V63, ExtCtrls, Idglobal;

const
  //Meldungen
  MSG_KALENDER_CHANGE = 1;
  MSG_SHUTDOWN = 2;
  MSG_PDEUPDATE = 3;
  MSG_Schichtwechsel = 4;

  //Applicationen
  APL_MDE = 1;
  APL_Planung = 2;
  APL_Controlling = 3;
  APL_Werkstatt = 4;
  APL_Starter = 5;
  APL_BDE = 6;
  APL_Werkstatt_RF = 7;
  APL_Werkstatt_CP = 8;
  APL_Datenbank = 9;

  APL_Messenger = 10;
  APL_Wartung = 12;

  APL_INCLService = 50;
  APL_Comm = 51;
  APL_Minibase = 52;
  APL_BCLager = 53;
  APL_BCDruck = 54;
  APL_ERPInterface = 55;

  XORKEY = Byte(137);
  KEYLENGTH = 63;
  ROTATOR = 35;
  CRYPTKEYLENGTH = 13;
  PREWARNDAYS = 26;

type
  TErrorEvent = procedure(Sender: TObject; Msg: string; var Handled: Boolean) of object;
  FuncGetL = function(T: string): string; stdcall;

type
  ComtasError = class(Exception);

type
  TCO_INCMeldung = class(TComponent)
  private
    fOraSession: TCO_Database;
    FApplicationID: Integer;
    FApp_Name: string;
    fRechnerNr: Integer;
    FRechnerName: string;
    FUserName: string;
    FCurrentFile: string;
    FAuto_ShutDown: Boolean;
    FServer_Status: Boolean;
    FClientCounter: Integer;
    FFehlerMeldung: string;
    ClientTimer: TTimer;
    qSuch: TCO_Query;
    qUpdate: TCO_Query;

    procedure SetDatabase(OraSession: TCO_Database);
    procedure SetApplicationID(App: Integer);
    procedure SQL_Get(Query: TCO_Query; SQLStr: string);
    procedure SQL_Insert(Query: TCO_Query; SQLStr: string);
    procedure SetRechnerUserName;
    function GetServerStatus(App: Integer): Integer;
    procedure ClientTimerTimer(Sender: TObject);
  protected
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function Anmelden: Integer;
    function Abmelden: Integer;
    function Meldung_Auswerten: Integer;
    procedure SetShutDown;
    procedure SetWerkskalender;
    procedure ServerStatusOK;

    property FehlerMeldung: string read FFehlerMeldung;
  published
    property Database: TCO_Database read fOraSession write SetDatabase;
    property ApplicationID: Integer read FApplicationID write SetApplicationID;
    property RechnerNr: Integer read fRechnerNr write fRechnerNr;
    property RechnerName: string read FRechnerName;
    property UserName: string read FUserName;
    property CurrentFile: string read FCurrentFile;
  end;

type
  TKeyArray = array of Boolean;

  TCharArray = array of Char;

  {CryptClass Deklaration Anfang}
  {
  Der Key enthält folgende Angaben:

      Optionen (16Bit)
      InstallerNr (16Bit 65535)
      Anzahl Maschinen (10Bit 1024) 0 ist unendlich
      Installdatum (16Bit 65535)
      Parity (2Bit)

      In Summe 60 Bit zu verschlüsseln. Der Einfachheithalber werden 64 Bit abzüglich 1 Vorzeichen
          verwendet.
      Daraus ergeben sich 9.223.372.036.854.775.808 Möglichkeiten
      Zur Anwendung kommen Buchstaben und Zahlen. Pro Stelle 36 Möglichkeiten
      Bei 13 Stellen á 36 Möglichkeiten ergeben sich 170.581.728.179.578.208.256 Möglichkeiten

      Zur Verschlüsselung werden die Arrays negiert, um 13 rechts rotiert und mit dem XORKEY mit
          XOR verrechnet.

  }
type
  TCryptClass = class
  private
    { Private-Deklarationen }
    FOnlyDecode: Boolean;

    FKeyNumberCrypt: Int64;

    FCryptKeyArray: TKeyArray;
    FCryptKeyString: string;

    FParity: Integer;

    FCharArray: TCharArray;

    FOption1: Boolean;
    FOption2: Boolean;
    FOption3: Boolean;
    FOption4: Boolean;
    FOption5: Boolean;
    FOption6: Boolean;
    FOption7: Boolean;
    FOption8: Boolean;
    FOption9: Boolean;
    FOption10: Boolean;
    FOption11: Boolean;
    FOption12: Boolean;
    FOption13: Boolean;
    FOption14: Boolean;
    FOption15: Boolean;
    FOption16: Boolean;
    FInstallDate: TDate;
    FInstallerNumber: Word;
    FMashineAmount: Word;
    FValid: Boolean;
    FDay30Over: Boolean;
    FPreWarn: Boolean;
    FSystemID: Cardinal;
    fTestMode : boolean;

    procedure Encode;
    procedure Decode;

    procedure RotateLeft(var aArray: TKeyArray; aCnt: Integer);
    procedure RotateRight(var aArray: TKeyArray; aCnt: Integer);

    procedure ArrayXOR(var aArray: TKeyArray; aXOR: Byte);
    function getCryptString(aArray: TKeyArray): string;
    procedure getCryptArray(aString: string; var aArray: TKeyArray);
    function getCharIndex(aArray: TCharArray; aChar: Char): Integer;
    function hoch(aBasis, aExp: Integer): Int64;
    procedure ClearEntries;

    procedure SetCryptKeyString(const Value: string);
    procedure SetInstallDate(const Value: TDate);
    procedure SetInstallerNumber(const Value: Word);
    procedure SetOption1(const Value: Boolean);
    procedure SetOption10(const Value: Boolean);
    procedure SetOption11(const Value: Boolean);
    procedure SetOption15(const Value: Boolean);
    procedure SetOption16(const Value: Boolean);
    procedure SetOption2(const Value: Boolean);
    procedure SetOption3(const Value: Boolean);
    procedure SetOption4(const Value: Boolean);
    procedure SetOption5(const Value: Boolean);
    procedure SetOption6(const Value: Boolean);
    procedure SetOption7(const Value: Boolean);
    procedure SetOption8(const Value: Boolean);
    procedure SetOption9(const Value: Boolean);
    procedure SetMashineAmount(const Value: Word);
    procedure SetSystemID(const Value: Cardinal);
    function GetisValid: Boolean;
    function GetMashineAmount: Word;
    function GetOption1: Boolean;
    function GetOption15: Boolean;
    function GetOption2: Boolean;
    function GetOption3: Boolean;
    function GetOption4: Boolean;
    function GetOption5: Boolean;
    function GetOption6: Boolean;
    function GetOption7: Boolean;
    function GetOption8: Boolean;
    function GetOption9: Boolean;
    function GetOption10: Boolean;
    function GetOption11: Boolean;
    function GetOption12: Boolean;
    function GetOption13: Boolean;
    function GetOption14: Boolean;
    function GetTrue:Boolean;
    procedure SetOption12(const Value: Boolean);
    procedure SetOption13(const Value: Boolean);
    procedure SetOption14(const Value: Boolean);

  public
    { Public-Deklarationen }

    property CryptKeyString: string read FCryptKeyString write SetCryptKeyString;
    property Maschinendatenerfassung: Boolean read GetOption1 write SetOption1;
    property Betriebsdatenerfassung: Boolean read GetOption2 write SetOption2;
    property Auftragsfeinplanung: Boolean read GetOption3 write SetOption3;
    property Controlling: Boolean read GetOption4 write SetOption4;
    property Werkstatt_IPC: Boolean read GetOption5 write SetOption5;
    property Werkstatt_RF: Boolean read GetOption6 write SetOption6;
    property Werkstatt_CP: Boolean read GetOption7 write SetOption7;
    property Starter: Boolean read GetTrue;// write SetOption8;
    property MessengerExt : Boolean read GetOption8 write SetOption8;
    property Datenbank: Boolean read GetOption9 write SetOption9;
    property ERPInterface: Boolean read FOption10 write SetOption10;
    property Wartung: Boolean read FOption11 write SetOption11;
    property Messenger: Boolean read FOption12 write SetOption12;
    property atMDC: Boolean read FOption13 write SetOption13;
    property SPC: Boolean read FOption14 write SetOption14;
    property Unlimited: Boolean read GetOption15 write SetOption15;
    property Evaluation: Boolean read FOption16 write SetOption16;
    property isValid: Boolean read GetisValid;
    property Day30Over: Boolean read FDay30Over;
    property PreWarn: Boolean read FPreWarn;
    property InstallDate: TDate read FInstallDate write SetInstallDate;
    property MashineAmount: Word read GetMashineAmount write SetMashineAmount;
    property InstallerNumber: Word read FInstallerNumber write SetInstallerNumber;
    property SystemID: Cardinal read FSystemID write SetSystemID;

    property TestMode: boolean read fTestMode write fTestMode;

    constructor Create(aDecode: Boolean);
    destructor Destroy; override;
  end;
  { CryptClass Deklaration Ende }

type
  TVersionClass = class
  private
    fProgramVersion: string;
    fProgramVersionShort: string;
    fProgramDate: string;
    procedure InitProgramVersion;

  public
    constructor Create;

    property ProgramVersion: string read fProgramVersion;
    property ProgramVersionShort: string read fProgramVersionShort;
    property ProgramDate: string read fProgramDAte;
  end;

function GetLErsatz(T: string): string; stdcall;

var
  CO_INCMeldungGetL: FuncGetL;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('comtas', [TCO_INCMeldung]);
end;

function GetLErsatz(T: string): string;
begin
  Result := T;
end;

//****************************************************

constructor TCO_INCMeldung.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  if @CO_INCMeldungGetL = nil then
    CO_INCMeldungGetL := GetLErsatz;

  qSuch := TCO_Query.Create(AOwner);
  qUpdate := TCO_Query.Create(AOwner);

  ClientTimer := TTimer.Create(AOwner);
  ClientTimer.Interval := 600000; //10 min
  ClientTimer.ENABLED := False;
  ClientTimer.OnTimer := ClientTimerTimer;
  if AOwner <> nil then
    fINC_Meldung := TfINC_Meldung.Create(Self);

  SetRechnerUserName;
end;

//****************************************************

destructor TCO_INCMeldung.Destroy;
begin
  Abmelden;

  if qSuch <> nil then
    qSuch.Destroy;
  if qUpdate <> nil then
    qUpdate.Destroy;
  ClientTimer.Destroy;

  if fINC_Meldung <> nil then
    fINC_Meldung.Free;

  inherited Destroy;
end;

//****************************************************

procedure TCO_INCMeldung.SetDatabase(OraSession: TCO_Database);
begin
  fOraSession := OraSession;
  if qSuch.Active then
    qSuch.Close;
  qSuch.Database := fOraSession;

  if qUpdate.Active then
    qUpdate.Close;
  qUpdate.Database := fOraSession;
end;

//****************************************************

procedure TCO_INCMeldung.SetApplicationID(App: Integer);
begin
  FApplicationID := App;
  case FApplicationID of
    APL_MDE: FApp_Name := 'MDE';
    APL_Planung: FApp_Name := 'Planung';
    APL_Controlling: FApp_Name := 'Controlling';
    APL_Werkstatt: FApp_Name := 'Werkstatt';
    APL_Starter: FApp_Name := 'Starter';
    APL_Messenger: FApp_Name := 'Messenger';
    APL_Wartung: FApp_Name := 'Wartung';

    APL_INCLService: FApp_Name := 'INCLService';
    APL_Comm: FApp_Name := 'INCLUDIS_Comm';
    APL_Minibase: FApp_Name := 'Minibase';
    APL_BCLager: FApp_Name := 'Barcode Lager';
    APL_ERPInterface: FApp_Name := 'ERP Interface';
  else
    FApp_Name := 'error';
  end;
end;

//****************************************************

procedure TCO_INCMeldung.SQL_Get(Query: TCO_Query; SQLStr: string);
begin
  Query.Close;
  with Query do
  begin
    SQL.Clear;
    SQL.Add(SQLStr);
    try
      Open;
    except
      on E: Exception do
      begin
        Exit;
      end;
    end;
  end;

end;

//****************************************************

procedure TCO_INCMeldung.SQL_Insert(Query: TCO_Query; SQLStr: string);
begin
  Query.Close;
  with Query do
  begin
    SQL.Clear;
    SQL.Add(SQLStr);
    try
      ExecSQL;
    except
      on E: Exception do
      begin
        Exit;
      end;
    end;
    Close;
  end;
end;

//****************************************************

procedure TCO_INCMeldung.SetRechnerUserName;
var
  ComputerName: array[0..20] of Char;
  UserName: array[0..512] of Char;
  arrSize: DWORD;
begin
  try
    arrSize := SizeOf(ComputerName);
    GetComputerName(@ComputerName, arrSize);
    FRechnerName := StrPas(ComputerName);
  except
    FRechnerName := 'error';
  end;

  try
    arrSize := SizeOf(UserName);
    GetUserName(@UserName, arrSize);
    FUserName := StrPas(UserName);
  except
    FUserName := 'error';
  end;

  try
    FCurrentFile := Application.GetNamePath + Application.ExeName;
  except
    FCurrentFile := 'error';
  end;
end;

//****************************************************

function TCO_INCMeldung.Anmelden: Integer;
var
  S: string;
  cc: TCryptClass;
  codeok, Ende: Boolean;
  sid: Cardinal;
  Buffer: array[0..255] of Char;
  A, B, SerialNum: LongWord;
  Vers: string;
begin
  Result := 0;
  cc := TCryptClass.Create(True);

  Vers := CO_Library_V63.GetVersion(4);
  if GetVersionComment <> '' then
    Vers := Vers + ' (' + GetVersionComment + ')';

  try
    S := 'delete from INC_Meldung where Application = ' + IntToStr(FApplicationID)
      + ' AND RechnerName = ''' + FRechnerName + '''';
    SQL_Insert(qUpdate, S);

    S := 'insert into Inc_Meldung (Nr, RechnerNr, Application, App_Name, FileVersion,'
      + ' RechnerName, UserName, CurrentFile, StartZeit, PDEUPDATE, SCHICHTWECHSEL,'
      + ' WERKSKALENDER, SHUTDOWN) values (Inc_MeldungId.NextVal,'
      + '''' + IntToStr(fRechnerNr) + ''','
      + '''' + IntToStr(FApplicationID) + ''','
      + '''' + FApp_Name + ''','
      + '''' + Vers + ''','
      + '''' + FRechnerName + ''','
      + '''' + FUserName + ''','
      + '''' + FCurrentFile + ''','
      + '''' + DateTimeToStr(Now) + ''','
      + '''' + IntToStr(0) + ''','
      + '''' + IntToStr(0) + ''','
      + '''' + IntToStr(0) + ''','
      + '''' + IntToStr(0) + ''')';
    SQL_Insert(qSuch, S);
  except
    Result := -1;
  end;

  //Setup auslesen
  S := 'select * from setup where Nr = 1';
  SQL_Get(qSuch, S);
  FAuto_ShutDown := qSuch.FieldByName('Auto_Shutdown').AsInteger = 1;
  FServer_Status := qSuch.FieldByName('SERVER_STATUS').AsInteger = 1;

  try
    S := qSuch.FieldByName('licensekey').AsString;
  except
    S := '';
  end;
  try
    sid := qSuch.FieldByName('systemid').AsInteger;
  except
    sid := 0;
  end;

  if S <> '' then
  begin
    cc.SystemID := sid;
    cc.CryptKeyString := S;

    codeok := False;
    case FApplicationID of
      APL_MDE: codeok := cc.Maschinendatenerfassung;
      APL_Planung: codeok := cc.Auftragsfeinplanung;
      APL_Controlling: codeok := cc.Controlling;
      APL_Werkstatt: codeok := cc.Werkstatt_IPC;
      APL_Starter: codeok := cc.Starter;
      APL_BDE: codeok := cc.Betriebsdatenerfassung;
      APL_Werkstatt_RF: codeok := cc.Werkstatt_RF;
      APL_Werkstatt_CP: codeok := cc.Werkstatt_CP;
      APL_Datenbank: codeok := cc.Datenbank;

      APL_Messenger: codeok := cc.Messenger;
      APL_Wartung: codeok := cc.Wartung;
    end;

    // -------------------------------------------------------------------------
    GetVolumeInformation('c:\', Buffer, SizeOf(Buffer), @SerialNum, A, B, nil, 0);
    // -------------------------------------------------------------------------

    if cc.Day30Over then
      FFehlerMeldung := CO_INCMeldungGetL('Testperiode abgelaufen')
    else
      if cc.PreWarn then
      begin
        FFehlerMeldung := CO_INCMeldungGetL('Testversion läuft ab in ') + ' ' + IntToStr(Round(cc.InstallDate - Now + 30))
          + CO_INCMeldungGetL(' Tagen');
        Result := -3;
      end;

    if not cc.isValid then
      FFehlerMeldung := CO_INCMeldungGetL('Lizenzschlüssel ungültig');
    if not codeok then
      FFehlerMeldung := CO_INCMeldungGetL('Applikation nicht freigeschaltet') + '(' + IntToStr(cc.SystemID) + '-' + cc.CryptKeyString+')';
    Ende := cc.Day30Over or not codeok;
  end
  else
  begin
    FFehlerMeldung := CO_INCMeldungGetL('Lizenzschlüssel nicht vorhanden');
    Ende := True;
  end;
   FFehlerMeldung := '';
   codeok := true;
   Ende := false;

  FreeAndNil(cc);
  if Ende then
    Result := -2;
  //Server_Status
  if FServer_Status then
  begin
    //Überwachung nur bei den Clients aktivieren
    if FApplicationID < 50 then
    begin
      FClientCounter := GetServerStatus(APL_INCLService); //Initialisierung
      ClientTimer.ENABLED := True; //Überwachung starten
    end;

    if FApplicationID >= 50 then
    begin
      //Prüfen, ob die Status-Tabelle bereit ist
      S := 'select count(*) as CNT from SERVER_STATUS where APPLICATION = ' + IntToStr(FApplicationID);
      SQL_Get(qSuch, S);
      if qSuch.FieldByName('CNT').AsInteger = 0 then
      begin
        //Der erste Start eines Server-Moduls, also Datensatz erzeugen
        S := 'insert into SERVER_STATUS (Nr, Application,App_Name,'
          + 'ACT_DATE,COUNTER)'
          + ' values (SERVER_STATUSId.NextVal,'
          + '''' + IntToStr(FApplicationID) + ''','
          + '''' + FApp_Name + ''','
          + '''' + FloatToStr(Now) + ''','
          + '''' + IntToStr(1) + ''')';
        SQL_Insert(qUpdate, S);
      end;
    end; //if FApplicationID >= 50 then begin
  end; //if FServer_Status then begin
end;

//****************************************************

function TCO_INCMeldung.Abmelden: Integer;
var
  S: string;
begin
  Result := 0;
  try
    S := 'delete from INC_Meldung where Application = ' + IntToStr(FApplicationID)
      + ' AND RechnerName = ''' + FRechnerName + '''';
    SQL_Insert(qUpdate, S);
  except
    Result := -1;
  end;
end;

//****************************************************

function TCO_INCMeldung.Meldung_Auswerten: Integer;
var
  S: string;
  Nr: string;
begin
  Result := 0;
  if qSuch = nil then
    Exit;

  S := 'select * from INC_Meldung where RechnerNr = '
    + IntToStr(fRechnerNr) + ' and Application = ' + IntToStr(FApplicationID)
    + ' AND RechnerName = ''' + FRechnerName + '''';

  SQL_Get(qSuch, S);
  if qSuch.EOF then
    Exit;

  Nr := qSuch.FieldByName('Nr').AsString;
  //Meldungen auswerten
  if qSuch.FieldByName('Werkskalender').AsInteger > 0 then
  begin
    S := 'update Inc_Meldung set Werkskalender = 0 where Nr = ' + Nr;
    SQL_Insert(qUpdate, S);
    Result := MSG_KALENDER_CHANGE;
  end;

  if qSuch.FieldByName('ShutDown').AsInteger > 0 then
  begin
    S := 'update Inc_Meldung set Shutdown = 0 where Nr = ' + Nr;
    SQL_Insert(qUpdate, S);

    if FAuto_ShutDown then
    begin
      if FApplicationID >= 50 then //Alle Server-Programme
      begin
        Application.Terminate;
        Exit;
      end;

      kill := Tkill.Create(nil);
      try
        //BringFormtoMiddle(Kill);
        kill.SHOW;
      except
        kill.Free;
      end;
    end; //if FAuto_ShutDown then begin
  end;

  if qSuch.FieldByName('PDEUpdate').AsInteger > 0 then
  begin
    S := 'update Inc_Meldung set PDEUpdate = 0 where Nr = ' + Nr;
    SQL_Insert(qUpdate, S);
    Result := MSG_PDEUPDATE;
  end;

  if qSuch.FieldByName('Schichtwechsel').AsInteger > 0 then
  begin
    S := 'update Inc_Meldung set Schichtwechsel = 0 where Nr = ' + Nr;
    SQL_Insert(qUpdate, S);
    Result := MSG_Schichtwechsel;
  end;
end;

//****************************************************

procedure TCO_INCMeldung.SetShutDown;
var
  S: string;
begin
  S := 'update Inc_Meldung Set ShutDown = 1';
  SQL_Insert(qUpdate, S);
end;

//****************************************************

procedure TCO_INCMeldung.SetWerkskalender;
var
  S: string;
begin
  S := 'update Inc_Meldung Set WERKSKALENDER = 1';
  SQL_Insert(qUpdate, S);
end;

//****************************************************
//****************************************************
//****************************************************
//Server-Status: Client-Funktionen

function TCO_INCMeldung.GetServerStatus(App: Integer): Integer;
var
  S: string;
begin
  S := 'select counter from  SERVER_STATUS where APPLICATION = ' + IntToStr(APP);
  SQL_Get(qSuch, S);
  Result := qSuch.FieldByName('counter').AsInteger;
end;

//****************************************************

procedure TCO_INCMeldung.ClientTimerTimer(Sender: TObject);
begin
  if Owner = nil then
    Exit;
  if FServer_Status then
  begin

    if FClientCounter >= GetServerStatus(APL_INCLService) then
    begin
      //Server nicht aktiv...
      fINC_Meldung.lMeldung.Caption := 'Server-Dienst nicht aktiv...';
      fINC_Meldung.lDatum.Caption := DateTimeToStr(Now);
      fINC_Meldung.SHOW;
    end
    else
    begin
      fINC_Meldung.Close;
    end;

  end;
end;

//****************************************************
//****************************************************
//****************************************************
//Server-Status: Server-Funktionen

procedure TCO_INCMeldung.ServerStatusOK;
var
  S: string;
begin
  S := 'update SERVER_STATUS set counter = counter + 1, ACT_DATE = ''' + FloatToStr(Now) + ''' where APPLICATION = '
    + IntToStr(FApplicationID);
  try
    SQL_Insert(qUpdate, S);
  except
  end;
end;

{ TCryptClass }

procedure TCryptClass.ArrayXOR(var aArray: TKeyArray; aXOR: Byte);
var
  I: Integer;
  xorrer: Boolean;
  S: string;
begin
  for I := 0 to KEYLENGTH - 1 do
  begin
    S := IntToBin(aXOR);
    xorrer := (S[(I mod 8) + 1]) = '1';
    aArray[I] := aArray[I] xor xorrer;
  end;
end;

procedure TCryptClass.ClearEntries;
begin
  FOption1 := False;
  FOption2 := False;
  FOption3 := False;
  FOption4 := False;
  FOption5 := False;
  FOption6 := False;
  FOption7 := False;
  FOption8 := False;
  FOption9 := False;
  FOption10 := False;
  FOption11 := False;
  FOption12 := False;
  FOption13 := False;
  FOption14 := False;
  FOption15 := False;
  FOption16 := False;
  FInstallDate := 0;
  FInstallerNumber := 0;
  FMashineAmount := 1;
  FDay30Over := False;
  FPreWarn := False;
end;

constructor TCryptClass.Create(aDecode: Boolean);
var
  I: Integer;
  C: Char;
begin
  inherited Create;
  FOnlyDecode := aDecode;
  SetLength(FCryptKeyArray, KEYLENGTH);

  SetLength(FCharArray, 36);
  for I := 0 to 35 do
  begin
    if I < 10 then
      C := Char(I + 48)
    else
      C := Char(I + 55);
    FCharArray[I] := C;

  end;
end;

procedure TCryptClass.Decode;
var
  I: Integer;
begin
  FValid := True;
  if Length(FCryptKeyString) > CRYPTKEYLENGTH + 2 then
    FValid := False;
  if Length(FCryptKeyString) < CRYPTKEYLENGTH then
    FValid := False;
  // KeyString to Int64
  getCryptArray(FCryptKeyString, fCryptKeyArray);

  ArrayXOR(FCryptKeyArray, XORKEY);
  // In64 To Array
  RotateLeft(FCryptKeyArray, ROTATOR);
  // Parity Test
  FParity := 0;
  for I := 0 to 57 do
  begin
    if FCryptKeyArray[I] then
      Inc(FParity);
    FCryptKeyArray[I] := not FCryptKeyArray[I];
  end;

  FParity := FParity mod 4;
  if not ((FCryptKeyArray[58] = ((FParity and 2) = 2)) and
    (FCryptKeyArray[59] = ((FParity and 1) = 1))) then
    FValid := False;
  // GetInstallDate
  FInstallDate := 0;
  for I := 42 to 57 do
  begin
    if FCryptKeyArray[I] then
      FInstallDate := FInstallDate + hoch(2, I - 42);
  end;

  // GetMashine Amount
  FMashineAmount := 0;
  for I := 32 to 41 do
  begin
    if FCryptKeyArray[I] then
      FMashineAmount := FMashineAmount + hoch(2, I - 32);
  end;

  // GetInstallerNumber
  FInstallerNumber := 0;
  for I := 16 to 31 do
  begin
    if FCryptKeyArray[I] then
      FInstallerNumber := FInstallerNumber + hoch(2, I - 16);
  end;

  // GetOptions
  FOption1 := FCryptKeyArray[0];
  FOption2 := FCryptKeyArray[1];
  FOption3 := FCryptKeyArray[2];
  FOption4 := FCryptKeyArray[3];
  FOption5 := FCryptKeyArray[4];
  FOption6 := FCryptKeyArray[5];
  FOption7 := FCryptKeyArray[6];
  FOption8 := FCryptKeyArray[7];
  FOption9 := FCryptKeyArray[8];
  FOption10 := FCryptKeyArray[9];
  FOption11 := FCryptKeyArray[10];
  FOption12 := FCryptKeyArray[11];
  FOption13 := FCryptKeyArray[12];
  FOption14 := FCryptKeyArray[13];
  FOption15 := FCryptKeyArray[14];
  FOption16 := FCryptKeyArray[15];

  FSystemID := 0;
  //  if FCryptKeyArray[11] then
  //    FSystemID := FSystemID + hoch(2, 0);
  //  if FCryptKeyArray[12] then
  //    FSystemID := FSystemID + hoch(2, 1);
  //  if FCryptKeyArray[13] then
  //    FSystemID := FSystemID + hoch(2, 2);
  if FCryptKeyArray[60] then
    FSystemID := FSystemID + hoch(2, 3);
  if FCryptKeyArray[61] then
    FSystemID := FSystemID + hoch(2, 4);
  if FCryptKeyArray[62] then
    FSystemID := FSystemID + hoch(2, 5);

  if FOption16 then
  begin
    FDay30Over := ((Round(Now) - FInstallDate) >= 30);
    FPreWarn := ((Round(Now) - FInstallDate) >= PREWARNDAYS);
  end;

  if (FInstallDate - Round(Now)) > 14 then
    FValid := False;

  if not FValid then
    ClearEntries;

end;

destructor TCryptClass.Destroy;
begin
  Finalize(FCryptKeyArray);

  Finalize(fCharArray);
  inherited;
end;

procedure TCryptClass.Encode;
var
  DateInt: Word;
  InstNr: Word;
  sysid: Word;

  MaschAnz: Integer;
  I: Integer;
begin
  if not FOnlyDecode then
  begin
    FCryptKeyArray[0] := FOption1;
    FCryptKeyArray[1] := FOption2;
    FCryptKeyArray[2] := FOption3;
    FCryptKeyArray[3] := FOption4;
    FCryptKeyArray[4] := FOption5;
    FCryptKeyArray[5] := FOption6;
    FCryptKeyArray[6] := FOption7;
    FCryptKeyArray[7] := FOption8;
    FCryptKeyArray[8] := FOption9;
    FCryptKeyArray[9] := FOption10;
    FCryptKeyArray[10] := FOption11;
    FCryptKeyArray[11] := FOption12;
    FCryptKeyArray[12] := FOption13;
    FCryptKeyArray[13] := FOption14;
    FCryptKeyArray[14] := FOption15;
    FCryptKeyArray[15] := FOption16;



    sysid := FSystemID;
    //    FCryptKeyArray[11] := (sysid mod 2) = 1;
    //    sysid := sysid div 2;
    //    FCryptKeyArray[12] := (sysid mod 2) = 1;
    //    sysid := sysid div 2;
    //    FCryptKeyArray[13] := (sysid mod 2) = 1;
    //    sysid := sysid div 2;
    FCryptKeyArray[60] := (sysid mod 2) = 1;
    sysid := sysid div 2;
    FCryptKeyArray[61] := (sysid mod 2) = 1;
    sysid := sysid div 2;
    FCryptKeyArray[62] := (sysid mod 2) = 1;

    InstNr := FInstallerNumber;

    for I := 16 to 31 do
    begin
      FCryptKeyArray[I] := (InstNr mod 2) = 1;
      InstNr := InstNr div 2;
    end;

    MaschAnz := FMashineAmount;
    for I := 32 to 41 do
    begin
      FCryptKeyArray[I] := (MaschAnz mod 2) = 1;
      MaschAnz := MaschAnz div 2;
    end;

    dateint := Trunc(FInstallDate);
    for I := 42 to 57 do
    begin
      FCryptKeyArray[I] := (dateint mod 2) = 1;
      dateint := dateint div 2;
    end;

     if fTestMode then
    begin
      for i := 0 to 14 do
        FCryptKeyArray[i] := true;

    end;

    FParity := 0;
    for I := 0 to 57 do
    begin
      FCryptKeyArray[I] := not FCryptKeyArray[I];
      if FCryptKeyArray[I] then
        Inc(FParity);
    end;

    FParity := FParity mod 4;
    FCryptKeyArray[58] := (FParity and 2) = 2;
    FCryptKeyArray[59] := (FParity and 1) = 1;

    RotateRight(FCryptKeyArray, ROTATOR);

    ArrayXOR(FCryptKeyArray, XORKEY);

    FCryptKeyString := getCryptString(fCryptKeyArray);
    //Umsetzen in Buchstaben
  end;
end;

function TCryptClass.getCharIndex(aArray: TCharArray;
  aChar: Char): Integer;

var
  I: Integer;

begin
  Result := -1;
  for I := 0 to Length(aArray) - 1 do
  begin
    Result := I;
    if ord(aChar) > 92 then
      aChar := Char(ord(aChar) - 32);
    if aArray[I] = aChar then
      break;
  end;
end;

procedure TCryptClass.getCryptArray(aString: string;
  var aArray: TKeyArray);
var
  mykn: Int64;
  I: Integer;
  B: Byte;
begin
  mykn := 0;
  FCryptKeyString := aString;
  Delete(aString, Pos('-', aString), 1);
  Delete(aString, Pos('-', aString), 1);
  for I := 1 to CRYPTKEYLENGTH do
  begin
    B := getCharIndex(fCharArray, aString[I]);
    mykn := mykn + (hoch(36, I - 1) * B);

  end;
  FKeyNumberCrypt := mykn;

  for I := 0 to KEYLENGTH - 1 do
  begin
    aArray[I] := (mykn mod 2) = 1;
    mykn := mykn div 2;
  end;
end;

function TCryptClass.getCryptString(aArray: TKeyArray): string;
var
  I: Integer;
  mykn: Int64;
begin
  FKeyNumberCrypt := 0;
  for I := KEYLENGTH - 1 downto 0 do
    if aArray[I] then
      FKeyNumberCrypt := FKeyNumberCrypt + hoch(2, I);
  mykn := FKeyNumberCrypt;
  Result := '';

  for I := 0 to CRYPTKEYLENGTH - 1 do
  begin
    Result := Result + fCharArray[mykn mod 36];
    mykn := mykn div 36;
  end;

  Insert('-', Result, 5);
  Insert('-', Result, 10);

  FCryptKeyString := Result;
end;

function TCryptClass.GetisValid: Boolean;
begin
  Result := FValid;
end;

function TCryptClass.GetMashineAmount: Word;
begin
  Result := FMashineAmount;
end;

function TCryptClass.GetOption1: Boolean;
begin
  Result := FOption1;
end;

function TCryptClass.GetOption10: Boolean;
begin
  Result := FOption10;
end;

function TCryptClass.GetOption11: Boolean;
begin
  Result := FOption11;
end;

function TCryptClass.GetOption12: Boolean;
begin
  Result := FOption12;
end;

function TCryptClass.GetOption13: Boolean;
begin
  Result := FOption13;
end;

function TCryptClass.GetOption14: Boolean;
begin
  Result := FOption14;
end;

function TCryptClass.GetOption15: Boolean;
begin
  Result := FOption15;
end;

function TCryptClass.GetOption2: Boolean;
begin
  Result := FOption2;
end;

function TCryptClass.GetOption3: Boolean;
begin
  Result := FOption3;
end;

function TCryptClass.GetOption4: Boolean;
begin
  Result := FOption4;
end;

function TCryptClass.GetOption5: Boolean;
begin
  Result := FOption5;
end;

function TCryptClass.GetOption6: Boolean;
begin
  Result := FOption6;
end;

function TCryptClass.GetOption7: Boolean;
begin
  Result := FOption7;
end;

function TCryptClass.GetOption8: Boolean;
begin
  Result := FOption8;
end;

function TCryptClass.GetOption9: Boolean;
begin
  Result := FOption9;
end;

function TCryptClass.GetTrue: Boolean;
begin
  Result := true;
end;


function TCryptClass.hoch(aBasis, aExp: Integer): Int64;
var
  I: Integer;
begin
  Result := 1;
  for I := 1 to aExp do
    Result := Result * aBasis;

end;

procedure TCryptClass.RotateLeft(var aArray: TKeyArray; aCnt: Integer);
var
  Dummy: Boolean;
  I, J: Integer;
begin
  for J := 0 to aCnt - 1 do
  begin
    Dummy := aArray[0];
    for I := 1 to KEYLENGTH - 1 do
    begin
      aArray[I - 1] := aArray[I];

    end;
    aArray[KEYLENGTH - 1] := Dummy;

  end;
end;

procedure TCryptClass.RotateRight(var aArray: TKeyArray; aCnt: Integer);
var
  Dummy: Boolean;
  I, J: Integer;
begin
  for J := 0 to aCnt - 1 do
  begin
    Dummy := aArray[KEYLENGTH - 1];
    for I := KEYLENGTH - 2 downto 0 do
    begin
      aArray[I + 1] := aArray[I];

    end;
    aArray[0] := Dummy;

  end;
end;

procedure TCryptClass.SetCryptKeyString(const Value: string);
begin
  FCryptKeyString := Value;
  Decode;
end;

procedure TCryptClass.SetInstallDate(const Value: TDate);
begin
  if not FOnlyDecode then
    FInstallDate := Value;
  Encode;
end;

procedure TCryptClass.SetInstallerNumber(const Value: Word);
begin
  if not FOnlyDecode then
    FInstallerNumber := Value;
  Encode;
end;

procedure TCryptClass.SetMashineAmount(const Value: Word);
begin
  if not FOnlyDecode then
    FMashineAmount := Value;
  Encode;
end;

procedure TCryptClass.SetOption1(const Value: Boolean);
begin
  if not FOnlyDecode then
    FOption1 := Value;
  Encode;
end;

procedure TCryptClass.SetOption10(const Value: Boolean);
begin
  if not FOnlyDecode then
    FOption10 := Value;
  Encode;
end;

procedure TCryptClass.SetOption11(const Value: Boolean);
begin
  if not FOnlyDecode then
    FOption11 := Value;
  Encode;
end;

procedure TCryptClass.SetOption12(const Value: Boolean);
begin
  if not FOnlyDecode then
    FOption12 := Value;
  Encode
end;

procedure TCryptClass.SetOption13(const Value: Boolean);
begin
  if not FOnlyDecode then
    FOption13 := Value;
  Encode;
end;

procedure TCryptClass.SetOption14(const Value: Boolean);
begin
  FOption14 := Value;
end;

procedure TCryptClass.SetOption15(const Value: Boolean);
begin
  if not FOnlyDecode then
    FOption15 := Value;
  Encode;
end;

procedure TCryptClass.SetOption16(const Value: Boolean);
begin
  if not FOnlyDecode then
    FOption16 := Value;
  Encode;
end;

procedure TCryptClass.SetOption2(const Value: Boolean);
begin
  if not FOnlyDecode then
    FOption2 := Value;
  Encode;
end;

procedure TCryptClass.SetOption3(const Value: Boolean);
begin
  if not FOnlyDecode then
    FOption3 := Value;
  Encode;
end;

procedure TCryptClass.SetOption4(const Value: Boolean);
begin
  if not FOnlyDecode then
    FOption4 := Value;
  Encode;
end;

procedure TCryptClass.SetOption5(const Value: Boolean);
begin
  if not FOnlyDecode then
    FOption5 := Value;
  Encode;
end;

procedure TCryptClass.SetOption6(const Value: Boolean);
begin
  if not FOnlyDecode then
    FOption6 := Value;
  Encode;
end;

procedure TCryptClass.SetOption7(const Value: Boolean);
begin
  if not FOnlyDecode then
    FOption7 := Value;
  Encode;
end;

procedure TCryptClass.SetOption8(const Value: Boolean);
begin
  if not FOnlyDecode then
    FOption8 := Value;
  Encode;
end;

procedure TCryptClass.SetOption9(const Value: Boolean);
begin
  if not FOnlyDecode then
    FOption9 := Value;
  Encode;
end;

procedure TCryptClass.SetSystemID(const Value: Cardinal);
begin
  if not FOnlyDecode then
    FSystemID := Value mod 64;
  Encode;
end;

constructor TVersionClass.Create;
begin
  inherited;
  InitProgramVersion;
end;

procedure TVersionClass.InitProgramVersion;
var
  VerInfoSize: Integer;
  VerValueSize: Cardinal;
  Dummy: Cardinal;
  VerInfo: Pointer;
  VerValue: PVSFixedFileInfo;
  v1, v2, v3, v4: Word;
  I, J: Integer;

begin
  V1 := 0;
  V2 := 0;
  V3 := 0;
  V4 := 0;
  try
    VerInfoSize := GetFileVersionInfoSize(PChar(Application.ExeName), Dummy);
    if VerInfoSize <> 0 then
    begin
      GetMem(VerInfo, VerInfoSize);
      try
        if GetFileVersionInfo(PChar(Application.ExeName), 0, VerInfoSize, VerInfo) then
        begin
          if VerQueryValue(VerInfo, '\', Pointer(VerValue), VerValueSize) then
            with VerValue^ do
            begin
              V1 := dwFileVersionMS shr 16;
              V2 := dwFileVersionMS and $FFFF;
              V3 := dwFileVersionLS shr 16;
              V4 := dwFileVersionLS and $FFFF;
            end;
        end;
      finally
        FreeMem(VerInfo, VerInfoSize);
      end;
    end;
    fProgramDate := DateToStr(FileDateToDateTime(FileAge(Application.ExeName)));
    // Versionsnummer aus Applikation extrahieren
    fProgramVersion := IntToStr(v1) + '.' + IntToStr(v2) + '.' + IntToStr(v3) + '.' + IntToStr(v4);
    fProgramVersionShort := '';
    J := 0;
    for I := 1 to Length(fProgramVersion) do
    begin
      if fProgramVersion[I] = '.' then
      begin
        Inc(J);
        if J = 2 then
          break;
        fProgramVersionShort := fProgramVersionShort + '.';
      end
      else
        fProgramVersionShort := fProgramVersionShort + fProgramVersion[I];
    end;

  except
  end;
end;

end.

