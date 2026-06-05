unit CO_DataBase;

interface

uses     
  {$IFDEF ODAC}
  Ora, Orasmart,
  {$ELSE}
  {$IFNDEF NONUNI}
   UNi,
  {$ENDIF}

  {$ENDIF}
   Dialogs, ADODB, Classes, SysUtils, DBTables, DBAccess,ActiveX,
{$IFDEF VER180}WideString, {$ENDIF}
{$IFDEF INCL_ZEOS}
  ZAbstractTable, ZDataset, ZAbstractRODataset, ZAbstractDataset, ZConnection,
{$ELSE}
// Bei der Installation der UniDac Komponenten die nächste Zeile auskommentieren.
// Anschließend wieder aktivieren.
  {$IFNDEF ODAC}
  {$IFNDEF NONUNI}
   OracleUniProvider, UniProvider, SQLServerUniProvider,
  {$ENDIF}
  {$ENDIF}
{$ENDIF}

  DB;

const
  dbTypOracle = 0;
  dbTypMSSQL = 1;
  dbTypZeos = 2;

  // Set DatabaseTyp: 0 - Oracle; 1 - ADO MSSQL; 2 - ZeosLIB MSSQL. Fürs Test

{$IFDEF INCL_ORA}
  INCLUDISDatabaseTyp = 0;
{$ENDIF}

{$IFDEF INCL_MSADO}
  INCLUDISDatabaseTyp = 1;
{$ENDIF}

{$IFDEF INCL_ZEOS}
  INCLUDISDatabaseTyp = 2;
{$ENDIF}

{$IFDEF VER180}
{$IF INCLUDISDatabaseTyp = 1}
{$DEFINE D2006}
{$IFEND}
{$ENDIF}

type
  TCO_Database = class(TComponent)
  private
    fUsername: string;
    fPassword: string;
    fServer: string;
    fInitialCatalog : string;
	fSqlProvider : string;

    procedure SetConnected(B: Boolean);
    function GetConnected: Boolean;

{$IF INCLUDISDatabaseTyp = 0}
    //    procedure setOnError(aErrorEvent: TDAConnectionErrorEvent);
    //    function getOnError: TDAConnectionErrorEvent;
{$IFEND}

    procedure DoBeforeConnect(Sender: TObject);
    procedure DoAfterConnect(Sender: TObject);
  protected
  public
{$IF INCLUDISDatabaseTyp < 2}
  {$IFDEF ODAC}
    fDatabase: TOraSession;
  {$ELSE}
    {$IFDEF NONUNI}
      fDatabase: TADOConnection;
    {$ELSE}
      fDatabase: TUniConnection;
    {$ENDIF}
  {$ENDIF}
{$IFEND}

{$IF INCLUDISDatabaseTyp = 2}
    fZDatabase: TZConnection;
{$IFEND}

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure StartTransaction;
    procedure Commit;
    function getConnectionString:string;
  published
    property Connected: Boolean read GetConnected write SetConnected;
    property UserName: string read fUsername write fUsername;
    property Password: string read fPassword write fPassword;
    property Server: string read fServer write fServer;
    property InitialCatalog: string read fInitialCatalog write fInitialCatalog;
	property SqlProvider: string read fSqlProvider write fSqlProvider;
	property ConnectionString : string read getConnectionString;

{$IF INCLUDISDatabaseTyp = 0}
    //    property OnError: TDAConnectionErrorEvent read getOnError write setOnError;
{$IFEND}
  end;

type
  TCO_Query = class(
{$IF INCLUDISDatabaseTyp < 2}
  {$IFDEF ODAC}
    TOraQuery
  {$ELSE}
    {$IFDEF NONUNI}
      TADOQuery
    {$ELSE}
      TUniQuery
    {$ENDIF}
  {$ENDIF}
{$IFEND}

{$IF INCLUDISDatabaseTyp = 2}
      TZQuery
{$IFEND}
      )
  private
    fDatabase: TCO_Database;
    ZusatzSQL: string;

    procedure SetDatabase(D: TCO_Database);

{$IFDEF D2006}
    procedure DoSQL(SQ: TWideStrings);
{$ELSE}
    procedure DoSQL(SQ: TStrings);
{$ENDIF}

    function FuncDecode(S, R: string; var A, B: Integer; var Par: array of string; var Anz: Integer): Integer;
    procedure FuncReplace(var S: string; R: string);
    function CheckIgnore(T: string): string;
    function Normalize(T: string): string;
    function ParseSQL(T: string): string;
    procedure WriteLog(S: string);
  protected

  public
    function ExecSQL :integer;
    procedure Open;
    function FieldByName(const Fieldname: string): TField;
    function FieldByNumber(const FieldNo: integer): TField;

    procedure ParamByNameAsString(Param, Val: string);
    procedure ParamByNameAsInteger(Param: string; Val: Integer);
    procedure ParamByNameAsFloat(Param: string; Val: Real);
    procedure ParamByNameAsDateTime(Param: string; Val: TDateTime);

  published
    property Database: TCO_Database read fDatabase write SetDatabase;
  end;

type
  TCO_Table = class(
{$IF INCLUDISDatabaseTyp = 0}
  {$IFDEF ODAC}
    TOraTable
  {$ELSE}
  {$IFNDEF NONUNI}
       TuniTable
    {$ELSE}
       TAdoTable
    {$ENDIF}
  {$ENDIF}
{$IFEND}

{$IF INCLUDISDatabaseTyp = 1}
      {$IFDEF NONUNI}
      TAdoTable
    {$ELSE}
     TuniTable
    {$ENDIF}
{$IFEND}

{$IF INCLUDISDatabaseTyp = 2}
      TZTable
{$IFEND}

      )
  private
    fDatabase: TCO_Database;
    procedure SetDatabase(D: TCO_Database);

  protected


  public
    function FieldByName(const Fieldname: string): TField;
  published
    property Database: TCO_Database read fDatabase write SetDatabase;
  end;

procedure Register;
function DateToStrSQL(Date: TDateTime): string;

implementation

procedure Register;
begin
  RegisterComponents('comtas', [TCO_Database, TCO_Query, TCO_Table]);
end;
//******************************************************************************

function DateToStrSQL(Date: TDateTime): string;
begin
{$IF INCLUDISDatabaseTyp = 0}
  Result := DateToStr(Date);
//  DateTimeToString(Result,'DD-MMM-YY',Date);
{$ELSE}
  DateTimeToString(Result, 'yyyymmdd', Date);
{$IFEND}
end;

//******************************************************************************

constructor TCO_Database.Create(AOwner: TComponent);
begin
  inherited;
  fUsername := 'includis';
  fPassword := 'comtas';
{$IF INCLUDISDatabaseTyp = 0}
  {$IFDEF ODAC}
  fDatabase := TOraSession.Create(self);
  {$ELSE}
    fDatabase := TUniConnection.Create(self);
    fDatabase.ProviderName := 'Oracle';
  {$ENDIF}
{$IFEND}

{$IF INCLUDISDatabaseTyp = 1}
{$IFDEF NONUNI}
  fDatabase := TADOConnection.Create(self);
//  fDatabase.ProviderName := 'SQL Server';
    {$ELSE}
  fDatabase := TUniConnection.Create(self);
  fDatabase.ProviderName := 'SQL Server';
    {$ENDIF}
{$IFEND}

{$IF INCLUDISDatabaseTyp < 2}
  fServer := 'includis.world';
//  fOraDatabase.ThreadSafety := True;
  fDatabase.BeforeConnect := DoBeforeConnect;
  fDatabase.AfterConnect := DoAfterConnect;
{$IFEND}

{$IF INCLUDISDatabaseTyp = 2}
  fServer := 'Server';
  fZDatabase := TZConnection.Create(Self);
  fZDatabase.BeforeConnect := DoBeforeConnect;
  fZDatabase.AfterConnect := DoAfterConnect;

{$IFEND}
end;
//******************************************************************************

destructor TCO_Database.Destroy;
begin
{$IF INCLUDISDatabaseTyp = 0}
  //  fOraDatabase.Free;
{$IFEND}

{$IF INCLUDISDatabaseTyp = 1}
  // fAdoDatabase.Free;      //Schlag ein Fehler.
{$IFEND}

{$IF INCLUDISDatabaseTyp = 2}
  //  fZDatabase.Free;
{$IFEND}

  inherited;
end;
//******************************************************************************

procedure TCO_Database.DoBeforeConnect(Sender: TObject);
begin
  Connected := True;
end;
//******************************************************************************

procedure TCO_Database.DoAfterConnect(Sender: TObject);
begin
  Connected := GetConnected;
end;
//******************************************************************************
function TCO_Database.getConnectionString:string;
begin
{$IFDEF NONUNUI}
    result := fDatabase.ConnectionString;
{$ENDIF}
end;

procedure TCO_Database.SetConnected(B: Boolean);
var cmd : TCO_Query;
   i : integer;
   colons : integer;
begin
  if Connected = B then
    Exit;

  if not B then
  begin
{$IF INCLUDISDatabaseTyp < 2}
    fDatabase.Connected := False;
{$IFEND}

{$IF INCLUDISDatabaseTyp = 2}
    fZDatabase.Connected := False;
{$IFEND}

    Exit;
  end;
{$IF INCLUDISDatabaseTyp < 2}
  {$IFNDEF NONUNI}
    fDatabase.BeforeConnect := nil;
    fDatabase.UserName := fUsername;
    fDatabase.Password := fPassword;
    fDatabase.Server := fServer;
    {$IF INCLUDISDatabaseTyp = 1}
    if fInitialCatalog = '' then
      fInitialCatalog := fUsername;
    fDatabase.Database := fInitialCatalog;
    {$IFEND}
  // Initialisierungen für Oracle
    if INCLUDISDatabaseTyp = 0 then
    begin
      colons := 0;
      for i := 1 to Length(fServer) do
        if fServer[i] = ':' then
          inc(colons);
//    if Pos(':',fServer) > 0 then
      if colons > 1 then
      begin
        {$IFDEF ODAC}
          fDatabase.Options.Direct := true;
        {$ELSE}
          fDatabase.SpecificOptions.Add('Oracle.Direct=True');
          fDatabase.SpecificOptions.Add('Oracle.ThreadSafety=True');
//          fDatabase.SpecificOptions.Add('Oracle.UseUnicode=True');
        {$ENDIF}
      end;
    end;

  // Initialisierungen für SQL Server
    if INCLUDISDatabaseTyp = 1 then
    begin
      {$IFNDEF ODAC}
        fDatabase.SpecificOptions.Add('Initial Catalog='+fInitialCatalog);
        fDatabase.SpecificOptions.Add('MultipleActiveResultSets=True');
        fDatabase.SpecificOptions.Add('LockTimeout=15000');
//    fDatabase.SpecificOptions.Add('ConnectionTimeout=30');
        fDatabase.SpecificOptions.Values['OLEDBProvider'] := 'prSQL';
      {$ENDIF}
    end;
  {$ELSE}
    fDatabase.BeforeConnect := nil;
    fDatabase.LoginPrompt := False;

    if fSqlProvider = '' then
    begin
      if (Length(fServer) > 0) and (fServer[1] = '#') then
      begin
        System.Delete(fServer, 1, 1);
        fDatabase.ConnectionString := 'Provider=SQLNCLI.1';
      end
      else
        fDatabase.ConnectionString := 'Provider=SQLOLEDB.1';
    end
	else
	begin
        fDatabase.ConnectionString := 'Provider=' + fSqlProvider;
	end;

    if fInitialCatalog <> '' then
    begin
      fInitialCatalog := fUsername;
    end;

    fDatabase.ConnectionString := fDatabase.ConnectionString + ';Initial Catalog=' + fInitialCatalog + ';'
      + 'Data Source=' + fServer + ';Password=' + fPassword + ';User ID=' + fUsername;

    fDatabase.Connected := B;
    fDatabase.BeforeConnect := DoBeforeConnect;

    DecimalSeparator := '.';
    ThousandSeparator := ',';

  {$ENDIF}

  try
    fDatabase.Connected := B;

  except on e: Exception do
  begin
    {$IFNDEF SERVICE}
//      ShowMessage(e.Message);
    {$ENDIF}
    {$IF INCLUDISDatabaseTyp = 1}
    if Pos(UpperCase('Coninitialize'), UpperCase(e.Message))>0 then
      CoInitialize(nil)
    else
    {$IFEND}
      Raise Exception.CreateFmt(e.Message + '(''%s'')', [UserName]);
  end
  end;
  if INCLUDISDatabaseTyp = 1 then
  begin
    cmd := TCO_Query.Create(fDatabase.Owner);
    cmd.Database := self;
    cmd.SQL.Text := 'set transaction isolation level read uncommitted';
    cmd.ExecSQL;
    cmd.Close;
    cmd.Free;
  end;

  fDatabase.BeforeConnect := DoBeforeConnect;
{$IFEND}


{$IF INCLUDISDatabaseTyp = 2}
  fZDatabase.BeforeConnect := nil;
  fZDatabase.LoginPrompt := False;
  // fZDatabase.Protocol := 'oracle';
  fZDatabase.Protocol := 'mssql';
  //  fZDatabase.Database := '';
  fZDatabase.Database := 'includis';

  fZDatabase.HostName := fServer;
  fZDatabase.User := fUsername;
  fZDatabase.Password := fPassword;

  fZDatabase.Connected := B;
  fZDatabase.BeforeConnect := DoBeforeConnect;
{$IFEND}
end;
//******************************************************************************

function TCO_Database.GetConnected: Boolean;
begin
{$IF INCLUDISDatabaseTyp < 2}
  if fDatabase = nil then
    Result := False
  else
    Result := fDatabase.Connected;
{$IFEND}

{$IF INCLUDISDatabaseTyp = 2}
  if fZDatabase = nil then
    Result := False
  else
    Result := fZDatabase.Connected;
{$IFEND}
end;
//******************************************************************************

procedure TCO_Database.StartTransaction;
begin
{$IF INCLUDISDatabaseTyp < 2}
  {$IFNDEF NONUNI}
    fDatabase.StartTransaction;
  {$ENDIF}
{$IFEND}

{$IF INCLUDISDatabaseTyp = 2}
  fZDatabase.StartTransaction;
{$IFEND}

end;
//******************************************************************************

procedure TCO_Database.Commit;
begin
{$IF INCLUDISDatabaseTyp < 2}
  {$IFNDEF NONUNI}
    fDatabase.Commit;
  {$ENDIF}
{$ELSE}
  // fAdoDatabase.Commit;
{$IFEND}
end;
//******************************************************************************

{$IF INCLUDISDatabaseTyp = 0}
//procedure TCO_Database.setOnError(aErrorEvent: TDAConnectionErrorEvent);
//begin
//  fOraDatabase.OnError := aErrorEvent;
//end;
//
//function TCO_Database.getOnError: TDAConnectionErrorEvent;
//begin
//  result := fOraDatabase.OnError;
//end;
{$IFEND}
//******************************************************************************

procedure TCO_Query.SetDatabase(D: TCO_Database);
begin
{$IF INCLUDISDatabaseTyp < 2}
  Self.Connection := D.fDatabase;
{$IFEND}

{$IF INCLUDISDatabaseTyp = 2}
  Self.Connection := D.fZDatabase;
{$IFEND}

  fDatabase := D;
end;
//******************************************************************************

function TCO_Query.ExecSQL:integer;
{$IF INCLUDISDatabaseTyp > 0}
var
  S: string;
{$IFEND}
begin
  if not Database.Connected then
    Database.Connected := True;

{$IF INCLUDISDatabaseTyp > 0}
  DoSQL(SQL);
  if ZusatzSQL <> '' then
  begin
    S := SQL.Text;
    SQL.Text := ZusatzSQL;
    ZusatzSQL := '';
    try
      inherited ExecSQL;
      result :=  self.RowsAffected;
    except
    end;
    SQL.Text := S;
  end;
      inherited ExecSQL;
      result :=  self.RowsAffected;
{$ELSE}
  inherited ExecSQL;
  result := -1;
{$IFEND}

end;
//******************************************************************************

procedure TCO_Query.Open;
begin
  try
  {$IF INCLUDISDatabaseTyp = 1}
// Ist das korrekt dass das nur bei SQL Server sein soll ?????
//    if self.Active then
//      inherited Close;
  {$IFEND}
    if self.Active then
      inherited Close;
  except
  end;
  DoSQL(SQL);

  if not Database.Connected then
    Database.Connected := True;

  inherited Open;
end;
//******************************************************************************

function TCO_Query.FieldByName(const Fieldname: string): TField;
var
  S: string;
begin
  S := UpperCase(Fieldname);
{$IF INCLUDISDatabaseTyp = 1}
  if S = 'SHUTDOWN' then
    S := S + '1';
{$IFEND}

 Result := inherited FieldByName(S)
end;
//******************************************************************************

function TCO_Query.FieldByNumber(const FieldNo: integer): TField;
begin
  Result := inherited FieldByNumber(FieldNo);
end;
//******************************************************************************

procedure TCO_Query.ParamByNameAsString(Param, Val: string);
begin
{$IF INCLUDISDatabaseTyp < 2}
  {$IFDEF NONUNI}
    Self.Parameters.FindParam(Param).Value := Val;
  {$ELSE}
    Self.ParamByName(Param).AsString := Val;
  {$ENDIF}
{$IFEND}


{$IF INCLUDISDatabaseTyp = 2}
  Self.ParamByName(Param).AsString := Val;
{$IFEND}
end;
//******************************************************************************

procedure TCO_Query.ParamByNameAsInteger(Param: string; Val: Integer);
begin
{$IF INCLUDISDatabaseTyp < 2}
  {$IFDEF NONUNI}
    Self.Parameters.FindParam(Param).Value := Val;
  {$ELSE}
  Self.ParamByName(Param).AsInteger := Val;
  {$ENDIF}

{$IFEND}

{$IF INCLUDISDatabaseTyp = 2}
  Self.ParamByName(Param).AsInteger := Val;
{$IFEND}
end;
//******************************************************************************

procedure TCO_Query.ParamByNameAsFloat(Param: string; Val: Real);
begin
{$IF INCLUDISDatabaseTyp < 2}
  {$IFDEF NONUNI}
    Self.Parameters.FindParam(Param).Value := Val;
  {$ELSE}
  Self.ParamByName(Param).AsFloat := Val;
  {$ENDIF}

{$IFEND}

{$IF INCLUDISDatabaseTyp = 2}
  Self.ParamByName(Param).AsFloat := Val;
{$IFEND}
end;
//******************************************************************************

procedure TCO_Query.ParamByNameAsDateTime(Param: string; Val: TDateTime);
begin
{$IF INCLUDISDatabaseTyp < 2}
    {$IFDEF NONUNI}
    Self.Parameters.FindParam(Param).Value := Val;
  {$ELSE}
  Self.ParamByName(Param).AsDateTime := Val;
  {$ENDIF}
{$IFEND}

{$IF INCLUDISDatabaseTyp = 2}
  Self.ParamByName(Param).AsDateTime := Val;
{$IFEND}
end;
//******************************************************************************

procedure TCO_Table.SetDatabase(D: TCO_Database);
begin
{$IF INCLUDISDatabaseTyp < 2}
  {$IFNDEF NONUNI}
    Self.Connection := D.fDatabase;
  {$ELSE}
    Self.Connection:= D.fDatabase;
  {$ENDIF}
{$IFEND}

{$IF INCLUDISDatabaseTyp = 2}
  Self.Connection := D.fZDatabase;
{$IFEND}

  fDatabase := D;
end;
//******************************************************************************

function TCO_Table.FieldByName(const Fieldname: string): TField;
var
  S: string;
begin
  S := UpperCase(Fieldname);
  Result := inherited FieldByName(S);
end;


{$IFDEF D2006}

procedure TCO_Query.DoSQL(SQ: TWideStrings);
{$ELSE}

procedure TCO_Query.DoSQL(SQ: TStrings);
{$ENDIF}

{$IF INCLUDISDatabaseTyp > 0}
var
  S: string;
  T: TDateTime;
{$IFEND}
begin
  if INCLUDISDatabaseTyp = 0 then
    Exit;

{$IF INCLUDISDatabaseTyp > 0}

  DecimalSeparator := '.';
  ThousandSeparator := ',';

  //  T := Now;
  S := SQ.Text;
  S := ParseSQL(S);
  SQ.Text := S;
  //  WriteLog(FloatToStr((Now - T) * 24 * 60 * 60));
  //  WriteLog('****************************************************************');
{$IFEND}
end;
//******************************************************************************

function TCO_Query.FuncDecode(S, R: string; var A, B: Integer; var Par: array of string; var Anz: Integer): Integer;
var
  I, N, KA: Integer;
begin
  Anz := 0;

  A := Pos(R, S);
  Result := A;
  if A < 1 then
    Exit;

  I := A;
  while S[I] <> '(' do
    Inc(I);
  KA := I + 1;
  N := 1;
  while N > 0 do
  begin
    Inc(I);
    if S[I] = '(' then
      Inc(N);
    if S[I] = ')' then
      Dec(N);
    if (S[I] = ',') and (N = 1) or (N = 0) then
    begin
      Inc(Anz);

      Par[Anz - 1] := Copy(S, KA, I - KA);
      KA := I + 1;
    end;
  end;
  B := I;
end;
//******************************************************************************

procedure TCO_Query.FuncReplace(var S: string; R: string);
var
  P: array of string;
  A, B, I, L: Integer;
  S1: string;
begin
  if Pos('TRUNCATE_ONLY', S) > 0 then // Aänerung wegen TRUNCATE_ONLY
    Exit;

  if (R <> 'TRUNC') and (R <> 'ROUND') and (R <> 'DECODE') and (R <> 'GREATEST') and (R <> 'LEAST') then
    Exit;

  SetLength(P, 20);

  if R = 'TRUNC' then
  begin
    A := Pos('TRUNC(', S);
    while A > 0 do
    begin
      System.Delete(S, A, 6);
      System.Insert('CONVERT(INTEGER, ', S, A);
      A := Pos('TRUNC(', S);
    end;
  end;

  while FuncDecode(S, R, A, B, P, L) > 0 do
  begin
    System.Delete(S, A, B - A + 1);

    if R = 'ROUND' then
    begin
      if L = 1 then
      begin
        P[1] := '0';
        L := 2;
      end;
      S1 := R + '(';
      S1[1] := LowerCase(S1[1])[1];
      for I := 1 to L do
        S1 := S1 + P[I - 1] + ',';
      S1[Length(S1)] := ')';
    end;

    if R = 'DECODE' then
    begin
      S1 := 'CASE ' + P[0];
      for I := 1 to (L - 1) div 2 do
        S1 := S1 + ' WHEN ' + P[I * 2 - 1] + ' THEN ' + P[I * 2];
      S1 := S1 + ' ELSE ' + P[L - 1] + ' END';
    end;

    if R = 'GREATEST' then
    begin
      S1 := 'CASE '
        + ' WHEN ' + P[0] + ' < ' + P[1] + ' THEN ' + P[1]
        + ' ELSE ' + P[0]
        + ' END'
    end;

    if R = 'LEAST' then
    begin
      S1 := 'CASE '
        + ' WHEN ' + P[0] + ' > ' + P[1] + ' THEN ' + P[1]
        + ' ELSE ' + P[0]
        + ' END'
    end;

    System.Insert(S1, S, A);
  end;
end;
//******************************************************************************

function TCO_Query.CheckIgnore(T: string): string;
const
  LenRepBeg = 8;
  RepBeg: array[1..LenRepBeg, 1..2] of string = (
    ('ALTER SESSION ', 'UPDATE SETUP SET SPRACHE = SPRACHE WHERE NR = -1'),
    ('CREATE OR REPLACE TRIGGER ', 'UPDATE SETUP SET SPRACHE = SPRACHE WHERE NR = -1'),
    ('ALTER SEQUENCE ', 'UPDATE SETUP SET SPRACHE = SPRACHE WHERE NR = -1'),
    ('CREATE SEQUENCE ', 'UPDATE SETUP SET SPRACHE = SPRACHE WHERE NR = -1'),

    ('SELECT * FROM USER_SEQUENCES', 'SELECT * FROM SETUP WHERE NR < -1'),

    ('SELECT BANNER FROM SYS.GV_$VERSION', 'SELECT @@VERSION BANNER'),
    ('SELECT * FROM SYS.V_$VERSION WHERE BANNER LIKE #1#', 'SELECT @@VERSION BANNER'),

    ('SELECT TABLE_NAME, COLUMN_NAME FROM USER_IND_COLUMNS',
    'SELECT T.NAME TABLE_NAME, C.NAME COLUMN_NAME FROM SYSINDEXKEYS K'
    + ' INNER JOIN SYSINDEXES I ON K.ID = I.ID AND K.INDID = I.INDID'
    + ' INNER JOIN SYSCOLUMNS C ON K.ID = C.ID AND K.COLID = C.COLID'
    + ' INNER JOIN SYSOBJECTS T ON K.ID = T.ID'
    + ' INNER JOIN SYSUSERS U ON U.UID = T.UID'
    + ' ORDER BY I.NAME')

    );

  LenRepMit = 27;
  RepMit: array[1..LenRepMit, 1..2] of string = (
    {$IFDEF INCL_MSADO}
      {$IFDEF UNICODE}
        ('VARCHAR2(', 'NVARCHAR('),
      {$ELSE}
        {$IFDEF UNIC}
          ('VARCHAR2(', 'NVARCHAR('),
        {$ELSE}
          ('VARCHAR2(', 'VARCHAR('),
        {$ENDIF}
      {$ENDIF}
    {$ELSE}
      ('VARCHAR2(', 'VARCHAR('),
    {$ENDIF}


    ('BLOB', 'IMAGE'),
    ('CLOB', 'TEXT'),

    (' DATE ', ' DATETIME '),
    (' DATE,', ' DATETIME,'),

    (' LENGTH(', ' LEN('),
    (' TO_NUMBER(', ' CONVERT(NUMERIC,'),
    (' TO_CHAR(', ' CONVERT(VARCHAR,'),

    (' QQQTOP ', ' TOP1 '),
    (' QQQLEFT ', ' LEFT1 '),

    (' TOP INTEGER, LEFT INTEGER', ' TOP1 INTEGER, LEFT1 INTEGER'),
    (' TOP, LEFT ', ' TOP1, LEFT1 '),

    (' SHUTDOWN ', ' SHUTDOWN1 '),
    (' SHUTDOWN)', ' SHUTDOWN1)'),
    ('SET SHUTDOWN =', 'SET SHUTDOWN1 ='),

    (' IS NOT NULL', ' <> '''''),

    (' PRINT ', ' PRINT1 '),

    ('USER_TABLES', 'INFORMATION_SCHEMA.TABLES'),
    ('USER_VIEWS', 'INFORMATION_SCHEMA.VIEWS'),
    ('VIEW_NAME', 'TABLE_NAME'),
    ('USER_COL_COMMENTS', 'INFORMATION_SCHEMA.COLUMNS'),
    ('SUBSTR(', 'SUBSTRING('),
    ('||', '+'),
    ('CHR(10)', 'CHAR(10)'),
    ('CHR(13)', 'CHAR(13)'),
    ('STDDEV', 'STDEV'),
    ('VARIANCE', 'VAR')

    );

  IDNextVal = 'ID.NEXTVAL';

var
  S, S1: string;
  A, B, I: Integer;
begin
  S := T;
  for I := 1 to LenRepBeg do
    if Copy(S, 1, Length(RepBeg[I, 1])) = RepBeg[I, 1] then
      S := RepBeg[I, 2];

  for I := 1 to LenRepMit do
    while Pos(RepMit[I, 1], S) > 0 do
    begin
      A := Pos(RepMit[I, 1], S);
      System.Delete(S, A, Length(RepMit[I, 1]));
      System.Insert(RepMit[I, 2], S, A);
    end;

  A := Pos(IDNextVal, S);
  if A > 0 then
  begin
    B := A;
    while S[B] in ['A'..'Z', '_', '0'..'9'] do
      Dec(B);
    Inc(B);
    S1 := Copy(S, B, A - B);
    System.Delete(S, B, A - B + Length(IDNextVal));
    System.Insert('DBO.NEXTVAL(''' + S1 + ''')', S, B);
    S := S + ' EXECUTE SETNEXTVAL @SNAME=''' + S1 + '''';
    S := 'BEGIN TRAN T1;' + S + '; COMMIT TRAN T1;';
    //    System.Insert('()', S, A + 10);
    //    System.Delete(S, A + 2, 1);
    //    System.Insert('DBO.', S, B + 1);
  end;

  if Copy(S, 1, Length('ALTER TABLE ')) = 'ALTER TABLE ' then
  begin
    A := Pos(' MODIFY ', S);
    B := Pos(' DEFAULT ', S);
    if (A > 0) and (B = 0) then
    begin
      System.Delete(S, A, Length(' MODIFY '));
      System.Insert(' ALTER COLUMN ', S, A);
    end;

    if (A > 0) and (B > 0) then
    begin
      S1 := Copy(S, B, Length(S));
      System.Delete(S, B, Length(S));
      System.Delete(S, A, Length(' MODIFY '));
      System.Insert(' ADD ' + S1 + ' FOR ', S, A);
    end;
  end;

  //  if Copy(S, 1, Length('CREATE SEQUENCE ')) = 'CREATE SEQUENCE ' then
  //  begin
  //    System.Delete(S, 1, Length('CREATE SEQUENCE '));
  //    System.Delete(S, Pos('ID ', S), Length(S));
  //    S := 'CREATE FUNCTION ' + S + 'IDNEXTVAL() RETURNS Integer AS BEGIN'
  //      + ' Declare @C integer, @B integer'
  //      + ' set @C = (Select Count(*) from ' + S
  //      + ' ) if @C > 0 set @B = (Select Max(Nr)+1 from ' + S
  //      + ' ) else set @B = 1'
  //      + ' Return @B'
  //      + ' END';
  //  end;

  ZusatzSQL := '';
  if Copy(S, 1, Length('CREATE OR REPLACE VIEW ')) = 'CREATE OR REPLACE VIEW ' then
  begin
    System.Delete(S, 8, 11);
    A := Pos(' VIEW ', S);
    B := Pos(' AS ', S);
    {$IFDEF INCL_MSADO}
      ZusatzSQL := Copy(S, A + 6, B - A - 6);
      ZusatzSQL := 'IF EXISTS(SELECT * FROM sysobjects WHERE xtype = ''V'' AND name = ''' + ZusatzSQL + ''') DROP VIEW ' + ZusatzSQL;
    {$ELSE}
      ZusatzSQL := Copy(S, A, B - A);
      ZusatzSQL := 'DROP ' + ZusatzSQL;
    {$ENDIF}
  end;

  Result := S;
end;
//******************************************************************************

function TCO_Query.Normalize(T: string): string;
var
  S: string;
  I: Integer;
begin
  S := T;
  I := 1;
  while I <= Length(S) do
  begin
    if S[I] = ',' then
    begin
      System.Insert(#32, S, I + 1);
      while S[I - 1] = #32 do
      begin
        System.Delete(S, I - 1, 1);
        Dec(I);
      end;
    end;

    Inc(I);
  end;

  while Pos(')VALUES', S) > 0 do
    System.Insert(#32, S, Pos(')VALUES', S) + 1);
  while Pos('VALUES(', S) > 0 do
    System.Insert(#32, S, Pos('VALUES(', S) + 6);

  while Pos(#32#32, S) > 0 do
    System.Delete(S, Pos(#32#32, S), 1);
  Result := S;
end;
//******************************************************************************

function TCO_Query.ParseSQL(T: string): string;
var
  S, S1: string;
  A, I, L: Integer;
  Kon: array of string;
begin
  S := T;

  while (Length(S) > 0) and (S[Length(S)] in [#13, #10, #32]) do
    System.Delete(S, Length(S), 1);

  WriteLog(S);

  L := 0;
  while Pos('''', S) > 0 do
  begin
    A := Pos('''', S);
    I := A + 1;
    while S[I] <> '''' do
      Inc(I);
    Inc(L);
    SetLength(Kon, L);
    Kon[L - 1] := Copy(S, A, I - A + 1);
    System.Delete(S, A, I - A + 1);
    System.Insert('#' + IntToStr(L) + '#', S, A);
  end;

  S := UpperCase(S);
  S := Normalize(S);
  S := CheckIgnore(S);

  
  FuncReplace(S, 'TRUNC');
  FuncReplace(S, 'ROUND');
  FuncReplace(S, 'DECODE');
  FuncReplace(S, 'GREATEST');
  FuncReplace(S, 'LEAST');

  for I := 1 to L do
  begin
    S1 := '#' + IntToStr(I) + '#';
    A := Pos(S1, S);
    while A > 0 do
    begin
      System.Delete(S, A, Length(S1));
      System.Insert(Kon[I - 1], S, A);
      A := Pos(S1, S);
    end;
  end;
  WriteLog(S);
  WriteLog('--------------------------');
  Result := S;
end;
//******************************************************************************

procedure TCO_Query.WriteLog(S: string);
var
  F: TextFile;
begin
  Exit;

  AssignFile(F, 'd:\1\INCLUDIS_SQL.txt');
  try
    System.Append(F);
  except
    System.Rewrite(F);
  end;
  WriteLn(F, S);
  CloseFile(F);
end;

end.

