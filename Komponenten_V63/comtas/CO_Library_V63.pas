unit CO_Library_V63;

interface

uses
  CO_DataBase, SysUtils, Windows, Forms, DBTables, StdCtrls, ComCtrls, Dialogs;

procedure SQL_Get(Query: TCO_Query; SQLStr: WideString); overload;
function SQL_Get(Query: TCO_Query; SQLStr: WideString; doDebug: Boolean ): Boolean; overload;
function SQLGet(Query: TCO_Query; Tabelle: string; Feld: string; Wert: string; Ergebnis: Boolean): Integer;
procedure SQL_Insert(Query: TCO_Query; SQLStr: string);
procedure UpdateSQL(Query: TCO_Query; Tabelle: string; UpdateFeld: string; UpdateWert: string; WhereFeld: string; WhereWert: string);

function GFloat(H: string): Extended;
function GetDatumZeitString(DZeit: Real): string;
function GetDatumString(DZeit: Real): string;
function GetMaschNr(qTmp: TCO_Query; Maschine: string): Integer;
function isMaschOnline(qTmp: TCO_Query; Maschine: string): Boolean;

function GetStillstandNr(qTmp: TCO_Query; Stillstand: string): Integer;
procedure InitVersion(var VerDatum, VERSION: string);
function GetShiftNo(Shift_Model: Integer; DT: TDateTime): Integer;
function GetAuftragLaufZeit(q1, q2: TCO_Query; BANr: string): Integer;
function GetAuftragLaufZeitVonBis(Q: TCO_Query; MaschNr: Integer; Von, Bis: Real): Integer;
function FloatToPunktString(aFloat: Extended): string;
function UpdateIntWZStatus(Q: TCO_Query): Integer;
function ManuellZeitBuchen(Query, qTmp: TCO_Query; Maschine: string; Datum1, Datum2: TDateTime; Minuten, Art: Integer): Integer;
function isManuell(Q: TCO_Query; Lizenz: string): Boolean;

function GetCRC: string;
function GetVersion(aDigits: Integer = 3): string;
function GetBuild: string;
function GetVersionProductName: string;
function GetVersionCompanyName: string;
function GetVersionFileDescription: string;
function GetVersionFileVersion: string;
function GetVersionInternalName: string;
function GetVersionLegalCopyright: string;
function GetVersionLegalTradeMarks: string;
function GetVersionOriginalFileName: string;
function GetVersionProductVersion: string;
function GetVersionComment: string;

function GetTimeZone(Q: TCO_Query; withText: Boolean): string;
function CheckBetriebsauftragNr(Q: TCO_Query; BA: string; CheckForDuplicate: Boolean=false): string;
function EANberechnen(Datum: TDateTime; aQuery: TCO_Query; var idx: integer): string; overload
function EANberechnen(Datum: TDateTime; aQuery: TCO_Query): string; overload
function MaterialChargeZubuchen(BANr : string; Materialid : string; GRN : string; aQuery: TCO_Query; Source: string):Boolean; overload;
function MaterialChargeZubuchen(BANr : string; Materialid : string; GRN : string; aQuery: TCO_Query; Source, LogFileName: string; out LogString: string):Boolean; overload;
function SiloBuchen(BANr : string; Materialid : string; GRN : string; aQuery: TCO_Query; bQuery: TCO_Query) : string;  overload;
function SiloBuchen(BANr : string; Materialid : string; GRN : string; aQuery: TCO_Query; bQuery: TCO_Query; LogFileName: string) : string;  overload;
function CopyCavityAndGRN(old, new, maschnr: string; qSuch, qSuch2, qUPdate: TCO_Query):string;
function CopySilo(old, new: string; qSuch, qSuch2: TCO_Query):Integer;
procedure LogMeldung(S: string); overload
procedure LogMeldung(S, FileName: string); overload

const
  MaxDateiKB = 1024 * 15;

implementation

uses
  Sprache_V63, CO_Setup2, Classes, SchichtUtilLib;

//==============================================================================

procedure SQL_Get(Query: TCO_Query; SQLStr: WideString);
var
  doDeb: Boolean;
begin
  {$IFDEF DEBUG}
    doDeb := True;
  {$ELSE}
    doDeb := False;
  {$ENDIF}
  SQL_Get(Query, SQLStr, doDeb);
end;

function SQL_Get(Query: TCO_Query; SQLStr: WideString; doDebug: Boolean ): Boolean;
begin
  Query.Close;
  Query.SQL.Clear;
  Query.SQL.Add(SQLStr);
  if (doDebug) then
    try
      Query.Open;
      Query.First;
      result := true;
    except on e: Exception do
    begin
      result := False;
      LogMeldung(e.Message + ' because of:');
      LogMeldung(Query.SQL.Text);
    end;
    end
  else
  begin
    Query.Open;
    Query.First;
  end;
end;
//==============================================================================

function SQLGet(Query: TCO_Query; Tabelle: string; Feld: string; Wert: string; Ergebnis: Boolean): Integer;
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
//==============================================================================

procedure SQL_Insert(Query: TCO_Query; SQLStr: string);
begin
  Query.Active := False;
  Query.SQL.Clear;
  Query.SQL.Add(SQLStr);
  {$IFDEF DEBUG}
    try
      Query.ExecSQL;
    except on e: Exception do
    begin
      LogMeldung(e.Message + ' because of:');
      LogMeldung(Query.SQL.Text);
    end;
    end;
  {$ELSE}
    Query.ExecSQL;
  {$ENDIF}
  Query.Active := False;
end;
//==============================================================================

function GetMaschNr(qTmp: TCO_Query; Maschine: string): Integer;
var
  Tmp: Integer;
begin
  Result := -1;
  Tmp := SQLGet(qTmp, 'MASCHINE', 'Lizenz', Maschine, True);
  if Tmp > 0 then
    Result := qTmp.FieldByName('MaschNr').AsInteger
  else
  begin
    Tmp := SQLGet(qTmp, 'MaschOffline', 'Lizenz', Maschine, True);
    if Tmp > 0 then
      Result := qTmp.FieldByName('MaschNr').AsInteger
  end;
end;
//==============================================================================

function GetStillstandNr(qTmp: TCO_Query; Stillstand: string): Integer;
var
  Tmp: Integer;
begin
  Tmp := SQLGet(qTmp, 'TPM_STILLSTAENDE', 'Stillstand', Stillstand, True);
  if Tmp > 0 then
    Result := qTmp.FieldByName('StillstandNr').AsInteger
  else
    Result := -1;
end;

//==============================================================================

function GFloat(H: string): Extended;
var
  S: string;
begin
  S := Trim(H);
  if S = '' then
    Result := 0
  else
    if DecimalSeparator = '.' then
      Result := StrToFloat(S)
    else
    begin
      while Pos('.', S) > 0 do
        S[Pos('.', S)] := DecimalSeparator;
      Result := StrToFloat(S);
    end;
end;
//==============================================================================

procedure UpdateSQL(Query: TCO_Query; Tabelle: string; UpdateFeld: string; UpdateWert: string; WhereFeld: string; WhereWert: string);
var
  SQLStr: string;
begin
  SQLStr := 'UPDATE ' + Tabelle + ' SET ' + UpdateFeld + '=''' + UpdateWert + ''' where ' + WhereFeld + '=''' + WhereWert + '''';
  SQL_Insert(Query, SQLStr);
end;
//==============================================================================

function GetDatumZeitString(DZeit: Real): string;
var
  DFormat: string;
begin
  if Sprache_Format = SP_FORMAT_USA then
    DFormat := 'm/d/yy h:nn AM/PM'
  else
    DFormat := 'dd.mm.yy hh:nn';
  DateTimeToString(Result, DFormat, DZeit);
end;
//==============================================================================

function GetDatumString(DZeit: Real): string;
var
  Year, Month, Day: Word;
begin
  DecodeDate(DZeit, Year, Month, Day);
  if Sprache_Format = SP_FORMAT_USA then
    Result := IntToStr(Month) + '/' + IntToStr(Day) + '/' + IntToStr(Year)
  else
    Result := IntToStr(Day) + '.' + IntToStr(Month) + '.' + IntToStr(Year);
end;
//==============================================================================

procedure InitVersion(var VerDatum, VERSION: string);
var
  VerInfoSize: Integer;
  VerValueSize: Cardinal;
  Dummy: Cardinal;
  VerInfo: Pointer;
  VerValue: PVSFixedFileInfo;
  v1, v2, v3, v4: Word;
begin
  V1 := 0;
  V2 := 0;
  V3 := 0;
  V4 := 0;
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
  VerDatum := DateToStr(FileDateToDateTime(FileAge(Application.ExeName)));
  VERSION := IntToStr(v1) + '.' + IntToStr(v2) + '.' + IntToStr(v3) + '.' + IntToStr(v4);
end;
//==============================================================================

function GetShiftNo(Shift_Model: Integer; DT: TDateTime): Integer;
begin
  if Shift_Model = 1 then
  begin
    Result := 3;
    if (Frac(DT) >= 0.25) and (Frac(DT) < 14 / 24) then
      Result := 1;
    if (Frac(DT) > 14 / 24) and (Frac(DT) < 22 / 24) then
      Result := 2;
  end
  else
  begin
    Result := 2;
    if (Frac(DT) >= 0.25) and (Frac(DT) < 0.75) then
      Result := 1;
  end;
end;
//==============================================================================

function isMaschOnline(qTmp: TCO_Query; Maschine: string): Boolean;
begin
  Result := SQLGet(qTmp, 'MASCHINE', 'Lizenz', Maschine, True) > 0;
end;

function ManuellZeitBuchen(Query, qTmp: TCO_Query; Maschine: string; Datum1, Datum2: TDateTime; Minuten, Art: Integer): Integer;
var
  KStr, S, MaschNr, Nr: string;
  Kommt, Geht: TDateTime;
  Dauer: Integer;
  B: Boolean;
begin
  // Art: 0 - Stillstand; 1 - Laufzeit

  if SQLGet(Query, 'Maschine', 'Lizenz', Maschine, True) = 0 then
  begin
    Result := 1; // Maschine nicht gefunden
    Exit;
  end;

  MaschNr := Query.FieldByName('MaschNr').AsString;

  Dauer := Round((Datum2 - Datum1) * 1440);

  if Minuten > Dauer then
  begin
    Result := 2; // Falsche_Eingabe;
    Exit;
  end;

  S := 'select Count(*) as CNT from TPM_Stillog where Geht = 0 and MaschNr = ' + MaschNr;
  SQL_Get(Query, S);
  B := Query.FieldByName('CNT').AsInteger > 0;

  S := 'delete from TPM_Stillog where'
    + ' Kommt >= ' + FloatToPunktString(Datum1) + ' and Decode(Geht, 0, ' + FloatToPunktString(Now) + ', Geht) <= '
    + FloatToPunktString(Datum2)  + ' and MaschNr = ' + MaschNr;
  SQL_Insert(Query, S);

  S := 'select * from TPM_Stillog where'
    + ' Kommt >= ' + FloatToPunktString(Datum1) + ' and Kommt < '
    + FloatToPunktString(Datum2) + ' and Decode(Geht, 0, ' + FloatToPunktString(Now) + ', Geht) > '
    + FloatToPunktString(Datum2) + ' and MaschNr = ' + MaschNr;
  SQL_Get(Query, S);
  if not Query.IsEmpty then
  begin
    S := 'update TPM_Stillog set Kommt = ' + FloatToPunktString(Datum2) + ' where Nr = ' + Query.FieldByName('Nr').AsString;
    SQL_Insert(Query, S);
  end;

  if Art = 1 then
    Minuten := Dauer - Minuten;

  Kommt := Datum2 - Minuten / 1440;

  S := 'insert into TPM_Stillog (Nr, MaschNr, Kommt, Geht, StillstandNr) values (TPM_StillogId.NextVal,'
    + ' ''' + MaschNr + ''','
    + FloatToPunktString(Datum1) + ','
    + FloatToPunktString(Kommt) + ','
    + ' ''' + '-1' + ''')';
  SQL_Insert(Query, S);

  S := 'insert into TPM_Stillog (Nr, MaschNr, Kommt, Geht, StillstandNr) values (TPM_StillogId.NextVal,'
    + ' ''' + MaschNr + ''','
    + FloatToPunktString(Kommt) + ','
    + FloatToPunktString(Datum2) + ','
    + ' ''' + '1' + ''')';
  SQL_Insert(Query, S);

  // TPM_Stillog Überprüfung
  Geht := 0;
  S := 'select * from TPM_Stillog where MaschNr = ' + MaschNr + ' order by Kommt';
  SQL_Get(Query, S);
  if not Query.EOF then
  begin
    Kommt := Query.FieldByName('Kommt').AsFloat;
    Geht := Query.FieldByName('Geht').AsFloat;
    if Geht = 0 then
      Geht := Now;
    Query.Next;
  end;

  while not Query.EOF do
  begin
    if (Kommt < Query.FieldByName('Kommt').AsFloat) and (Geht > Query.FieldByName('Geht').AsFloat) then
    begin
      Query.Prior;
      Nr := Query.FieldByName('Nr').AsString;
      Query.Next;
      KStr := Query.FieldByName('KOMMTSTR').AsString;
      S := 'update TPM_STILLOG set Geht = ''' + Query.FieldByName('KOMMT').AsString + ''' where Nr = ' + Nr;
      SQL_Insert(qTmp, S);
      Query.Prior;
      S := 'update TPM_STILLOG'
        + ' set Dauer = Round((Geht-Kommt)*1440),'
        + ' GehtStr = ''' + KStr + ''''
        + ' where NR = ' + Nr;
      SQL_Insert(qTmp, S);
      Query.Next;
    end;
    Kommt := Query.FieldByName('Kommt').AsFloat;
    Geht := Query.FieldByName('Geht').AsFloat;
    if Geht = 0 then
      Geht := Now;
    Query.Next;
  end;

  S := 'delete from TPM_Stillog where StillstandNr < 0';
  SQL_Insert(Query, S);

  if B then
  begin
    S := 'select Count(*) as CNT from TPM_Stillog where Geht = 0 and MaschNr = ' + MaschNr;
    SQL_Get(Query, S);
    if Query.FieldByName('CNT').AsInteger = 0 then
    begin
      S := 'select Max(Geht) as CNT from TPM_Stillog where MaschNr = ' + MaschNr;
      SQL_Get(Query, S);
      S := 'insert into TPM_Stillog (Nr, MaschNr, Kommt, Geht, StillstandNr) values (TPM_StillogId.NextVal,'
        + ' ''' + MaschNr + ''','
        + ' ''' + Query.FieldByName('CNT').AsString + ''','
        + ' ''' + '0' + ''','
        + ' ''' + '1' + ''')';
      SQL_Insert(Query, S);
    end;
  end;

  Result := 0; // Ok
end;
//==============================================================================

function isManuell(Q: TCO_Query; Lizenz: string): Boolean;
var
  S: string;
begin
  S := 'select Count(*) as CNT from Maschine where Lizenz = ''' + Lizenz + ''''
    + ' and Manuelle_Buchung IN (1,3)';
  SQL_Get(Q, S);
  Result := Q.FieldByName('CNT').AsInteger > 0;
end;
//==============================================================================

function GetCRC: string;
const
  Table: array[0..255] of LongWord =
  ($00000000, $77073096, $EE0E612C, $990951BA,
    $076DC419, $706AF48F, $E963A535, $9E6495A3,
    $0EDB8832, $79DCB8A4, $E0D5E91E, $97D2D988,
    $09B64C2B, $7EB17CBD, $E7B82D07, $90BF1D91,
    $1DB71064, $6AB020F2, $F3B97148, $84BE41DE,
    $1ADAD47D, $6DDDE4EB, $F4D4B551, $83D385C7,
    $136C9856, $646BA8C0, $FD62F97A, $8A65C9EC,
    $14015C4F, $63066CD9, $FA0F3D63, $8D080DF5,
    $3B6E20C8, $4C69105E, $D56041E4, $A2677172,
    $3C03E4D1, $4B04D447, $D20D85FD, $A50AB56B,
    $35B5A8FA, $42B2986C, $DBBBC9D6, $ACBCF940,
    $32D86CE3, $45DF5C75, $DCD60DCF, $ABD13D59,
    $26D930AC, $51DE003A, $C8D75180, $BFD06116,
    $21B4F4B5, $56B3C423, $CFBA9599, $B8BDA50F,
    $2802B89E, $5F058808, $C60CD9B2, $B10BE924,
    $2F6F7C87, $58684C11, $C1611DAB, $B6662D3D,

    $76DC4190, $01DB7106, $98D220BC, $EFD5102A,
    $71B18589, $06B6B51F, $9FBFE4A5, $E8B8D433,
    $7807C9A2, $0F00F934, $9609A88E, $E10E9818,
    $7F6A0DBB, $086D3D2D, $91646C97, $E6635C01,
    $6B6B51F4, $1C6C6162, $856530D8, $F262004E,
    $6C0695ED, $1B01A57B, $8208F4C1, $F50FC457,
    $65B0D9C6, $12B7E950, $8BBEB8EA, $FCB9887C,
    $62DD1DDF, $15DA2D49, $8CD37CF3, $FBD44C65,
    $4DB26158, $3AB551CE, $A3BC0074, $D4BB30E2,
    $4ADFA541, $3DD895D7, $A4D1C46D, $D3D6F4FB,
    $4369E96A, $346ED9FC, $AD678846, $DA60B8D0,
    $44042D73, $33031DE5, $AA0A4C5F, $DD0D7CC9,
    $5005713C, $270241AA, $BE0B1010, $C90C2086,
    $5768B525, $206F85B3, $B966D409, $CE61E49F,
    $5EDEF90E, $29D9C998, $B0D09822, $C7D7A8B4,
    $59B33D17, $2EB40D81, $B7BD5C3B, $C0BA6CAD,
    $EDB88320, $9ABFB3B6, $03B6E20C, $74B1D29A,

    $EAD54739, $9DD277AF, $04DB2615, $73DC1683,
    $E3630B12, $94643B84, $0D6D6A3E, $7A6A5AA8,
    $E40ECF0B, $9309FF9D, $0A00AE27, $7D079EB1,
    $F00F9344, $8708A3D2, $1E01F268, $6906C2FE,
    $F762575D, $806567CB, $196C3671, $6E6B06E7,
    $FED41B76, $89D32BE0, $10DA7A5A, $67DD4ACC,
    $F9B9DF6F, $8EBEEFF9, $17B7BE43, $60B08ED5,
    $D6D6A3E8, $A1D1937E, $38D8C2C4, $4FDFF252,
    $D1BB67F1, $A6BC5767, $3FB506DD, $48B2364B,
    $D80D2BDA, $AF0A1B4C, $36034AF6, $41047A60,
    $DF60EFC3, $A867DF55, $316E8EEF, $4669BE79,
    $CB61B38C, $BC66831A, $256FD2A0, $5268E236,
    $CC0C7795, $BB0B4703, $220216B9, $5505262F,
    $C5BA3BBE, $B2BD0B28, $2BB45A92, $5CB36A04,
    $C2D7FFA7, $B5D0CF31, $2CD99E8B, $5BDEAE1D,

    $9B64C2B0, $EC63F226, $756AA39C, $026D930A,
    $9C0906A9, $EB0E363F, $72076785, $05005713,
    $95BF4A82, $E2B87A14, $7BB12BAE, $0CB61B38,
    $92D28E9B, $E5D5BE0D, $7CDCEFB7, $0BDBDF21,
    $86D3D2D4, $F1D4E242, $68DDB3F8, $1FDA836E,
    $81BE16CD, $F6B9265B, $6FB077E1, $18B74777,
    $88085AE6, $FF0F6A70, $66063BCA, $11010B5C,
    $8F659EFF, $F862AE69, $616BFFD3, $166CCF45,
    $A00AE278, $D70DD2EE, $4E048354, $3903B3C2,
    $A7672661, $D06016F7, $4969474D, $3E6E77DB,
    $AED16A4A, $D9D65ADC, $40DF0B66, $37D83BF0,
    $A9BCAE53, $DEBB9EC5, $47B2CF7F, $30B5FFE9,
    $BDBDF21C, $CABAC28A, $53B39330, $24B4A3A6,
    $BAD03605, $CDD70693, $54DE5729, $23D967BF,
    $B3667A2E, $C4614AB8, $5D681B02, $2A6F2B94,
    $B40BBE37, $C30C8EA1, $5A05DF1B, $2D02EF8D);

type
  TBuffer = array[1..65521] of Byte;

var
  IOBuffer: TBuffer;
  crc, err: LongWord;
  BytesRead, CRCvalue: LongWord;
  FromFile: file;
  FromName: string;

  procedure CalcCRC32(var P: TBuffer; nbyte: Word; var CRCvalue: Longword);
  var
    I: Integer;
  begin
    for I := 1 to nBYTE do
      CRCvalue := (CRCvalue shr 8) xor Table[P[I] xor (CRCvalue and $000000FF)];
  end;

begin
  FromName := ParamStr(0);
  FileMode := 0; {Read only}
  CRCValue := $FFFFFFFF;
  AssignFile(FromFile, FromName);
{$I-}Reset(FromFile, 1);
{$I+}
  err := IOResult;
  if err = 0 then
  begin
    repeat
      BlockRead(FromFile, IOBuffer, SizeOf(IOBuffer), BytesRead);
      CalcCRC32(IOBuffer, BytesRead, CRCvalue);
    until BytesRead = 0;
    CloseFile(FromFile);
  end;
  crc := not CRCvalue;

  Result := IntToHex(crc, 8);
end;

function GetVersion(aDigits: Integer = 3): string;
var
  VerInfoSize: DWORD;
  VerInfo: Pointer;
  VerValueSize: DWORD;
  VerValue: PVSFixedFileInfo;
  Dummy: DWORD;
  firstparam : string;
  firstpchar : PChar;
begin
  Result := '';
  try
    firstparam := ParamStr(0);
    firstpchar := PChar(firstparam);
    VerInfoSize := GetFileVersionInfoSize(firstpchar, Dummy);
//    Dummy := GetLastError;
    if VerInfoSize = 0 then
    begin
      Result := '';
      Exit;
    end;
    GetMem(VerInfo, VerInfoSize);
    GetFileVersionInfo(PChar(ParamStr(0)), 0, VerInfoSize, VerInfo);
    VerQueryValue(VerInfo, '\', Pointer(VerValue), VerValueSize);
    with VerValue^ do
    begin
      Result := IntToStr(dwFileVersionMS shr 16);
      Result := Result + '.' + IntToStr(dwFileVersionMS and $FFFF);
      if aDigits > 2 then
        Result := Result + '.' + IntToStr(dwFileVersionLS shr 16);
      if aDigits > 3 then
        Result := Result + '.' + IntToStr(dwFileVersionLS and $FFFF);
    end;
    FreeMem(VerInfo, VerInfoSize);
  except
  end;
end;

function GetBuild: string;
var
  VerInfoSize: DWORD;
  VerInfo: Pointer;
  VerValueSize: DWORD;
  VerValue: PVSFixedFileInfo;
  Dummy: DWORD;
begin
  Result := '';
  try
    VerInfoSize := GetFileVersionInfoSize(PChar(ParamStr(0)), Dummy);
    GetMem(VerInfo, VerInfoSize);
    GetFileVersionInfo(PChar(ParamStr(0)), 0, VerInfoSize, VerInfo);
    VerQueryValue(VerInfo, '\', Pointer(VerValue), VerValueSize);
    Result := IntToStr((VerValue^.dwFileVersionLS) and $FFFF);
    FreeMem(VerInfo, VerInfoSize);
  except
  end;
end;

function GetVersionData(aField: string): string;
var
  N, Len: DWORD;
  Buf: PChar;
  Value: PChar;
begin
  N := GetFileVersionInfoSize(PChar(ParamStr(0)), N);
  if N > 0 then
  begin
    Buf := AllocMem(N);
    GetFileVersionInfo(PChar(ParamStr(0)), 0, N, Buf);
    if VerQueryValue(Buf, PChar('StringFileInfo\040704E4\' + aField), Pointer(Value), Len) then // deutsche Sprache
      Result := Value
    else
      if VerQueryValue(Buf, PChar('StringFileInfo\040904E4\' + aField), Pointer(Value), Len) then // US Sprache
        Result := Value
      else // andere Sprache
        Result := '';
    FreeMem(Buf, N);
  end
  else
    Result := '';
end;

function GetVersionProductName: string;
begin
  Result := GetVersionData('ProductName');
end;

function GetVersionCompanyName: string;
begin
  Result := GetVersionData('CompanyNam');
end;

function GetVersionFileDescription: string;
begin
  Result := GetVersionData('FileDescription');
end;

function GetVersionFileVersion: string;
begin
  Result := GetVersionData('FileVersion');
end;

function GetVersionInternalName: string;
begin
  Result := GetVersionData('InternalName');
end;

function GetVersionLegalCopyright: string;
begin
  Result := GetVersionData('LegalCopyright');
end;

function GetVersionLegalTradeMarks: string;
begin
  Result := GetVersionData('LegalTradeMarks');
end;

function GetVersionOriginalFileName: string;
begin
  Result := GetVersionData('OriginalFileName');
end;

function GetVersionProductVersion: string;
begin
  Result := GetVersionData('ProductVersion');
end;

function GetVersionComment: string;
begin
  Result := GetVersionData('Comments');
end;

function CheckBetriebsauftragNr(Q: TCO_Query; BA: string; CheckForDuplicate: Boolean=false): string;
var
  ForceLength, MaxLength: integer;
{$Warnings off}
function IsInteger(s: string): boolean;
var i, e: integer;
begin
  Val(s, i, e);
  result := e = 0;
end;
{$Warnings on}

begin
  result := '';

  if CheckForDuplicate then
  begin
    if SQLGet(Q, 'PDE', 'BetriebsAuftragNr', BA, True) > 0 then
    begin
      Result := GetL('Auftragsnummer ') + BA + GetL(' bereits vorhanden! (Gepl. Auftrag)');
      Exit;
    end;

    if SQLGet(Q, 'PDENEU', 'BetriebsAuftragNr', BA, True) > 0 then
    begin
      result := GetL('Auftragsnummer ') + BA + GetL(' bereits vorhanden! (Ungepl. Auftrag)');
      Exit;
    end;

    if SQLGet(Q, 'PDEKOMBI', 'BetriebsAuftragNr', BA, True) > 0 then
    begin
      result := GetL('Auftragsnummer ') + BA + GetL(' bereits vorhanden! (Detailauftrag)');
      Exit;
    end;

    if SQLGet(Q, 'AARCHIV', 'BetriebsAuftragNr', BA, True) > 0 then
    begin
      Result := GetL('Auftragsnummer ') + BA + GetL(' bereits vorhanden! (Archiv)');
      Exit;
    end;
  end;

  if not TCO_Setup.GetParamBool(Q,'FP_BetriebsauftragnrAlphaNumeric', true) then
  begin
    if not isInteger(BA) then
      result := GetL('Fehler: Auftragnr ') + BA + GetL(' muss rein numerisch sein!');
  end;

  if result <> '' then
    result := result + #10#13;

  MaxLength := TCO_Setup.GetParamInt(Q,'FP_BetriebsauftragNrMaxLength', true);
  ForceLength := TCO_Setup.GetParamInt(Q,'FP_BetriebsauftragNrForceLength', true);
  If ForceLength > 0 then
  begin
    if ForceLength <> Length(BA) then
      result := result + GetL('Fehler: Erforderliche Länge Auftragnr: ') + IntToStr(ForceLength) + Getl(' - Ist: ')
                       + IntToStr(Length(BA));
    if MaxLength > 0 then
    begin
      MaxLength := 0;
      TCO_Setup.SetParam(Q,'FP_BetriebsauftragNrMaxLength', MaxLength);
    end;
  end;


  if MaxLength > 0 then
  begin
    if MaxLength < Length(BA) then
      result := result + GetL('Fehler: maximale Länge Auftragnr: ') + IntToStr(MaxLength) + Getl(' - Ist: ')
                       + IntToStr(Length(BA));
  end;

end;

function GetTimeZone(Q: TCO_Query; withText: Boolean): string;
var
  S: string;
begin
  try
    SQL_Get(Q, 'select TimeZone_Text from Setup');
    S := Q.FieldByName('TimeZone_Text').AsString;
    if S <> '' then
      if withText then
        Result := 'Time zone: [' + S + '] '
      else
        Result := ' [' + S + '] '
    else
      Result := '';
  except
    Result := '';
  end;
end;

function GetAuftragLaufZeit(q1, q2: TCO_Query; BANr: string): Integer;
var
  S, Liz: string;
  MaschNr: Integer;
  lZeit: Real;
begin
  Result := 0;
  if SQLGet(q1, 'AARchiv', 'BetriebsAuftragNr', BANr, True) > 0 then
  begin
    Liz := q1.FieldByName('Maschine').AsString;
    MaschNr := GetMaschNr(q1, Liz);
    if isMaschOnline(q1, Liz) then
    begin
      lZeit := 0;
      SQLGet(q1, 'LaufzeitLog', 'BetriebsAuftragNr', BANr, False);
      while not q1.EOF do
      begin
        lZeit := lZeit + GetAuftragLaufZeitVonBis(q2, MaschNr, q1.FieldByName('AuftragStart').AsFloat, q1.FieldByName('AuftragEnde').AsFloat);
        q1.Next;
      end;
      Result := Round(lZeit);
    end
    else
    begin
      S := 'select Sum(Duration) CNT from Rework where JobNo = ''' + BANr + '''';
      SQL_Get(q1, S);
      try
        Result := q1.FieldByName('CNT').AsInteger;
      except
        Result := 0;
      end;
    end;
  end;
end;

function DateOverlap(aZRStart, aZREnd, aItemStart, aItemEnd: TDateTime): Integer;
begin
  if (aZRStart <= aItemEnd) and (aZREnd >= aItemStart) then // Item befindet sich in ZR
  begin
    if aItemStart < aZRStart then
      aItemStart := aZRStart;
    if aItemEnd > aZREnd then
      aItemEnd := aZREnd;
    Result := Round((aItemEnd - aItemStart) * 1440);
  end
  else
    Result := 0;
end;


function GetAuftragLaufZeitVonBis(Q: TCO_Query; MaschNr: Integer; Von, Bis: Real): Integer;
var
  S: string;
  lZeit, SZeit: Real;
  still : TStillstandEintrag;
  stilllist : TStillstandEintragsListe;
  i, minutes : Integer;
begin
  if Bis = 0 then
    Bis := Now;
  if Von = 0 then
    Von := Bis;
   minutes :=0;
  if Bis > Von then
  begin
    stilllist := TStillstandEintragsListe.Create;

    s := 'SELECT SUM(CASE WHEN geht = 0 THEN ' + FloatToPunktString(Bis)
      + ' ELSE geht END - CASE WHEN kommt < ' + FloatToPunktString(Von)
      + ' THEN ' + FloatToPunktString(Von) + ' ELSE kommt END) CNT'
      + ' FROM tpm_stillog WHERE maschnr = ' + IntToStr(MaschNr)
      + ' AND kommt <= ' + FloatToPunktString(Bis) + ' AND (geht=0 OR geht >= '
      + FloatToPunktString(Von) + ')';
    SQL_Get(Q, s);
(*
  // Überschneidungen filtern !!!
    s := 'SELECT CASE WHEN geht = 0 THEN ' + FloatToPunktString(Bis)
      + ' ELSE CASE WHEN geht > ' + FloatToPunktString(Bis) + ' THEN '
      + FloatToPunktString(Bis) + ' ELSE geht END END geht1, '
      + ' CASE WHEN kommt < ' + FloatToPunktString(Von)
      + ' THEN ' + FloatToPunktString(Von) + ' ELSE kommt END kommt1 '
      + ' FROM tpm_stillog WHERE maschnr = ' + IntToStr(MaschNr)
      + ' AND kommt <= ' + FloatToPunktString(Bis) + ' AND (geht=0 OR geht >= '
      + FloatToPunktString(Von) + ') ORDER BY kommt';
    SQL_Get(Q, s);
    while not q.Eof do
    begin
      still := TStillstandEintrag.Create;
      still.Kommt := q.FieldByName('kommt1').AsFloat;
      still.Geht := q.FieldByName('geht1').AsFloat;
      stilllist.add(still);
      q.Next;
    end;

    for I := 1 to stilllist.Count-1 do
    begin
      if stilllist.Items[i].Kommt < stilllist.items[i-1].Geht then
        stilllist.Items[i].Kommt := stilllist.items[i-1].Geht;
      if stilllist.Items[i].Geht < stilllist.items[i-1].Geht then
        stilllist.Items[i].Geht := stilllist.items[i-1].Geht;
      if stilllist.Items[i].Geht < stilllist.items[i].Kommt then
        stilllist.Items[i].Geht := stilllist.items[i].Kommt;
    end;

    minutes := stilllist.GetTotalMinutes;
    stilllist.Destroy;
  end;
  result := minutes;
  *)
   S := 'select Sum(Least(Decode(Geht, 0, 99999, Geht), ' + FloatToPunktString(Bis) + ')'
      + ' - Greatest(Kommt, ' + FloatToPunktString(Von) + ')) CNT'
      + ' from TPM_Stillog where MaschNr = ' + IntToStr(MaschNr)
      + ' and Kommt <= ' + FloatToPUnktString(Bis) + ' and Decode(Geht, 0, 99999, Geht) >= ' + FloatToPunktString(Von);

    SQL_Get(Q, S);
    try
      SZeit := Q.FieldByName('CNT').AsFloat;
    except
      SZeit := 0;
    end;
    lZeit := Bis - Von - SZeit;
  end
  else
    lZeit := 0;

  if lZeit > (Bis-von) then
    Result := Round((Bis-von) * 1440)
  else if lZeit < 0 then
    Result := Round((Bis-von) * 1440)
  else
    Result := Round(lZeit * 1440);

end;

function FloatToPunktString(aFloat: Extended): string;
begin
  Result := FloatToStr(aFloat);
  if Pos(',', Result) > 0 then
  begin
    Insert('.', Result, Pos(',', Result));
    Delete(Result, Pos(',', Result), 1);
  end;
end;


function UpdateIntWZStatus(Q: TCO_Query): Integer;
var
  SQLStr: string;
  NullCount, resultvar: Integer;
  fieldnames: TStrings;
const
  WZ_Warehouse_States = '''Lager'',''Warehouse'',''Storage'',''Tool warehouse'',''Almacén''';
  WZ_Machine_States = '''Maschine'',''Machine'',''Maskine'',''Máquina'',''Maskin''';
  WZ_Repair_States = '''Reparatur'',''Repair'',''Reparation'',''Reparación'',''Reparation''';
begin

  resultvar := 0;

  //Check if there are tools with no statusint;
  SQLStr := ' SELECT count(nr) AS CNT'
          + ' FROM WERKZEUG'
          + ' WHERE Statusint is null';
  Q.SQL.Text := SQLStr;
  try
    Q.ExecSQL;
    NullCount := Q.FieldByName('CNT').AsInteger;
  except
    try
      NullCount := SQLGet(Q,'Werkzeug','Statusint','',True);
    except
      //-1: there was an error on retrieving statusint. TableCreate?
      resultvar := resultvar -1;
      Exit;
    end;
  end;

  {
  fieldnames := TStrings.Create;
  Q.Fields.GetFieldNames(fieldnames);
  }
  if Nullcount = 0 then
  begin
    //0: No tools without statusint
    Result := 0;
    Exit;
  end
  else
  begin
    //resultvar := Q.FieldByName('CNT').AsInteger;

    //Lager bekommt statusint = 0
    SQLStr := ' UPDATE WErkzeug'
            + ' SET statusint = 0'
            + ' WHERE Status IN (' + WZ_Warehouse_States + ')';
    Q.SQL.Text := SQLStr;
    try
      Q.ExecSQL;
    except
    end;

    //Maschine bekommt statusint = 1
    SQLStr := ' UPDATE WErkzeug'
            + ' SET statusint = 1'
            + ' WHERE Status IN (' + WZ_Machine_States + ')'
            + ' AND StatusInt is null';
    Q.SQL.Text := SQLStr;
    try
      Q.ExecSQL;
    except
    end;


    //Reparatur bekommt statusint = 2
    SQLStr := ' UPDATE WErkzeug'
            + ' SET statusint = 2'
            + ' WHERE Status IN (' + WZ_Repair_States + ')'
            + ' AND StatusInt is null';
    Q.SQL.Text := SQLStr;
    try
      Q.ExecSQL;
    except
    end;

    //Alle anderen bekommen statusint = -1
    SQLStr := ' SELECT COUNT(nr) AS CNT'
            + ' FROM WErkzeug'
            + ' WHERE ( Status NOT IN (' + WZ_Repair_States + ', ' + WZ_Warehouse_States + ', ' + WZ_Machine_States + ')'
            + '         OR Status IS NULL)'
            + ' AND StatusInt is null';
    Q.SQL.Text := SQLStr;
    try
      Q.ExecSQL;
      NullCount := Q.FieldByName('CNT').AsInteger;
    except
      try
        NullCount := SQLGet(Q,'Werkzeug','Statusint','',True);
      except
        //-1: there was an error on retrieving statusint. TableCreate?
        resultvar := resultvar -1;
        Exit;
      end;
    end;

    SQLStr := ' UPDATE WErkzeug'
            + ' SET statusint = -1'
            + ' WHERE ( Status NOT IN (' + WZ_Repair_States + ', ' + WZ_Warehouse_States + ', ' + WZ_Machine_States + ')'
            + '         OR Status IS NULL)'
            + ' AND StatusInt is null';
    Q.SQL.Text := SQLStr;
    try
      Q.ExecSQL;
    except
    end;

    {SQLStr := ' SELECT count(nr) AS CNT'
            + ' FROM WERKZEUG'
            + ' WHERE Statusint is null';
    Q.SQL.Text := SQLStr;

    try
      Q.ExecSQL;
    except
      Result := -1;
      Exit;
    end;

    if not Q.IsEmpty then
    begin
      // number of tools we were able to correct
      resultvar := resultvar - Q.FieldByName('CNT').AsInteger;
      if resultvar < 0 then
        // if mod resultvar /1000 = 0 then for some reason there are now more tools with out statusint then before
        resultvar := resultvar * 1000;
    end;
}
    Result := resultvar;
  end;
end;

function  EANberechnen(Datum: TDateTime; aQuery: TCO_Query; var idx: integer): string; overload
var
  SQLStr: string;
begin
  SQLStr := 'Select count(*) CNT from MaterialChargen where LieferdatumSTR = ''' + DateToStr(Datum) + '''';
  SQL_Get(aQuery, SQLStr);
  idx := aQuery.FieldByName('CNT').AsInteger;
  result := EANberechnen(Datum, aQuery);
end;
function EANberechnen(Datum: TDateTime; aQuery: TCO_Query): string; overload
var
  SQLStr: string;
  index: Integer;
  Tag, Monat, Jahr: Word;
  EANSTR: string;
  Summe, I, LieferIDX: Integer;
begin
  if TCO_Setup.GetParamBool(aQuery,'INCL_InternalMaterialEANFromSequence') then
    begin
      SQLStr := 'SELECT MaterialEANId.Nextval CNT'
              + ' FROM dual';
      SQL_Get(aQuery, SQLStr);
      EANSTR := aQuery.FieldByName('CNT').AsString;
    end
  else
    begin
      SQLStr := 'Select count(*) CNT from MaterialChargen where LieferdatumSTR = ''' + DateToStr(Datum) + '''';
      SQL_Get(aQuery, SQLStr);
      index := aQuery.FieldByName('CNT').AsInteger;
      LieferIDX := index;
      index := index + 1;
      DecodeDate(Datum, Jahr, Monat, Tag);
      // Wenn Tag < 10 dann wird mit 9 nicht mit 0 aufgefüllt. Bug in AISCI Scanner
      if Tag in [1..9] then
        EANSTR := '9' + IntToStr(Tag)
      else
        EANSTR := IntToStr(Tag);
      if Monat in [1..9] then
        EANSTR := EANSTR + '0' + IntToStr(Monat)
      else
        EANSTR := EANSTR + IntToStr(Monat);
      EANSTR := EANSTR + IntToStr(Jahr);
      if index < 10 then
        EANSTR := EANSTR + '000' + IntToStr(index);
      if ((index > 9) and (index < 100)) then
        EANSTR := EANSTR + '00' + IntToStr(index);
      if ((index > 99) and (index < 1000)) then
        EANSTR := EANSTR + '0' + IntToStr(index);
      if ((index > 999) and (index < 10000)) then
        EANSTR := EANSTR + IntToStr(index);
      Summe := 0;
      for I := 1 to 12 do
        if (I mod 2) = 0 then
          Summe := Summe + ((ord(EANSTR[I]) - 48) * 3)
        else
          Summe := Summe + (ord(EANSTR[I]) - 48);

      if (Summe mod 10) = 0 then
        EANSTR := EANSTR + '0'
      else
        EANSTR := EANSTR + IntToStr((10 - (Summe mod 10)));
    end;
  Result := EANSTR;
end;

function MaterialChargeZubuchen(BANr : string; Materialid : string; GRN : string; aQuery: TCO_Query; Source: string):Boolean; overload;
var
  logstring: string;
begin
  logString := '';
  Result := MaterialChargeZubuchen(BANr, Materialid, GRN, aQuery, Source, '', logString);
end;

function MaterialChargeZubuchen(BANr : string; Materialid : string; GRN : string; aQuery: TCO_Query; Source, LogFileName: String; out LogString: string):Boolean; overload;
procedure LogIt(lMessage, fn: string; out rString: string);
begin
  rString := rString +  lMessage;
  if (fn <> '') then
    LogMeldung(lMessage, fn);
end;

var
  onlyOnce, GRNExists: Boolean;
  message, SQLStr, EANCode: string;
begin
  if LogString <> '' then
    LogString := LogString + '<br>';
  SQLStr := 'SELECT *'
          + ' FROM Materialchargen'
          + ' WHERE materialid = ' + Materialid
          + ' AND Chargennr = ''' + GRN + '''';
  SQL_Get(aQuery, SQLStr);

  if aQuery.IsEmpty then
  begin
    EANCode := EANberechnen(Now, aQuery);
    SQLStr := 'Insert into MATERIALCHARGEN (Nr,Materialid, CHARGENNR, LAGERPLATZ,  EANCode, LIEFERDATUMSTR, LIEFERDATUM)'
            + ' VALUES (Materialchargenid.nextval'
            + ', ' + Materialid
            + ', ''' + GRN + ''''
            + ', ''' + Source + ''''
            + ', ''' + EANCode
            + ''',''' + DateToStr(Now)
            + ''',' + FloatToPunktString(Now) + ')';
    SQL_Insert(aQuery, SQLStr);
    GRNExists := false;
    LogIt('Created batch ''' + GRN + ''' (' + EANCode + ')', LogFileName, LogString);
  end
  else
  begin
    EANCode := aQuery.FieldByName('EANCode').AsString;
    LogIt('Batch ''' + GRN + ''' (' + EANCode + ') exists', LogFileName, LogString);
    GRNExists := true;
  end;
  SQLStr := 'SELECT * FROM MATERIALZUOR WHERE betriebsauftragnr = ''' + BANr + ''' AND eancode = ''' + EANCode + '''';
  SQL_Get(aQuery, SQLStr);

  onlyOnce := TCO_Setup.GetParamBool(aQuery, 'INCL_GRNOncePerMO');
  if aQuery.IsEmpty or not onlyOnce then
  begin
    SQLStr := 'Insert into MaterialZuor (Nr,Betriebsauftragnr, ts_reported, ts_assigned, EANCode, copied) '
        + ' VALUES (MATERIALZUORID.nextval'
        + ',''' + BANr
        + ''',0,' + FloatToPunktString(Now)
        + ',''' + EANCode + ''', 0)';
    SQL_Insert(aQuery, SQLStr);
    LogIt('Assigned Batch ''' + GRN + ''' (' + EANCode + ') to MO ' + BANr, LogFileName, LogString);
  end
  else
    LogIt('Batch ''' + GRN + ''' (' + EANCode + ') had already been assigned to MO ' + BANr + ' on ' + DateTimeToStr(aQuery.FieldByName('ts_assigned').AsFloat), LogFileName, LogString);

  result := GRNExists;
end;

function SiloBuchen(BANr : string; Materialid : string; GRN : string; aQuery: TCO_Query; bQuery: TCO_Query) : string; overload
begin
  Result := SiloBuchen(BANr, Materialid, GRN, aQuery, bQuery, '');
end;
function SiloBuchen(BANr : string; Materialid : string; GRN : string; aQuery: TCO_Query; bQuery: TCO_Query; LogFileName: string) : string; overload
var
  SQLStr: String;
  CurrentLevel, Liefermenge: double;
  SiloName, mString, returnstring: string;
begin
  SQLStr := 'SELECT siloname, currentlevel, fulllevel, emptylevel, emptysignalvalue, fullsignalvalue, liefermenge, chargennr'
          + ' FROM SILOS'
          + ' LEFT JOIN MATERIALCHARGEN ON materialchargen.lagerplatz = silos.siloname'
          + ' WHERE silos.nr = ''' + GRN + ''''
          + ' ORDER BY Lieferdatum DESC';
  SQL_GET(aQuery, SQLStr);
  if not aQuery.IsEmpty then
  begin
    try
      CurrentLevel := StrToFloat(aQuery.FieldByName('currentlevel').AsString) * 1000;
    except
      CurrentLevel := -1;
    end;
    SiloName := aQuery.FieldByName('siloname').AsString;
    returnstring := SiloName + ' has as current level of: ' +  FloatToStr(CurrentLevel);//+ '-' + aQuery.FieldByName('currentlevel').AsString + '<br>';
    while not aQuery.EOF do
    begin
      if CurrentLevel > -1 then
      begin
        try
          Liefermenge := StrToFloat(aQuery.FieldByName('liefermenge').AsString);
        except
          Liefermenge := 0;
        end;
        GRN := aQuery.FieldByName('Chargennr').AsString;
        mstring := '';
        MaterialChargeZubuchen(BANr, Materialid, GRN, bQuery, Getl('manuell'), LogFileName, mstring);
        returnstring := returnstring + '<br>' + SiloName + ': ' + mstring;
        SQLStr := 'UPDATE PDE'
                + ' SET SiloName = ''' + SiloName + ''''
                + ' WHERE betriebsauftragnr = ''' + BANr + '''';
        SQL_Insert(bQuery, SQLStr);
        //returnstring := returnstring + 'Added: ' + GRN + '<br>';
        SQLStr := 'UPDATE aarchiv'
                + ' SET SiloName = ''' + SiloName + ''''
                + ' WHERE betriebsauftragnr = ''' + BANr + '''';
        SQL_Insert(bQuery, SQLStr);
        CurrentLevel := CurrentLevel - Liefermenge;
        aQuery.Next;
      end
      else
        break;
    end;
  end;
  if (LogFileName <> '' ) then
    LogMeldung(returnstring, LogFileName);
  Result := returnstring;
end;

function CopyCavityAndGRN(old, new, maschnr: string; qSuch, qSuch2, qUPdate: TCO_Query):string;
var
  Materialid, SiloNr, SollKavitaet, ResString, SQLString: string;
  GRNsCopied: integer;
begin
  ResString := '';

  SQLString := 'SELECT aarchiv.*, SILOS.materialid silomaterial, SILOS.Nr silonr'
             + ' FROM aarchiv'
             + ' LEFT JOIN SILOS on aarchiv.SILONAME = SILOS.SILONAME'
             + ' WHERE betriebsauftragnr = ''' + old + '''';
  try
    SQL_Get(qSuch, SQLString);
  except on e: Exception do
    ResString := ResString + 'Exception: ' + e.Message + '|' + SQLString;
  end;

  if not qSuch.IsEmpty then
  begin
    try
      //Get the SIloNumber and it's materialid just in case while we have the right query
      SiloNr := qSuch.FieldByName('SiloNr').AsString;
      Materialid := qSuch.FieldByName('SiloMaterial').AsString;

      //Copy Cavity from old to new job (multiple tables affected)
      SollKavitaet := qSuch.FieldByName('kavitaet').AsString;
      SQLString := 'UPDATE pde SET Kopfgroesse = ' + SollKavitaet
                 + ' WHERE betriebsauftragnr = ''' + new + '''';
      try
        SQL_Insert(qUpdate, SQLString);
      except on e: Exception do
        ResString := ResString + 'Exception: ' + e.Message + '|' + SQLString;
      end;

      SQLString := 'insert into ERPEvents (Nr, BetriebsAuftragNr, Event, Datumzeit)'
                  + ' values (ERPEventsId.NextVal,'
                  + '''' + new + ''','
                  + '''K'','
                  + FloatToPunktString(Now) + ')';
      try
        SQL_Insert(qUpdate, SQLString);
      except on e: Exception do
        ResString := ResString + 'Exception: ' + e.Message + '|' + SQLString;
      end;

      SQLString := 'UPDATE maschine SET Kopfgroesse = ' + SollKavitaet
                 + ' WHERE maschid = ''' + MaschNr + '''';
      try
        SQL_Insert(qUpdate, SQLString);
      except on e: Exception do
        ResString := ResString + 'Exception: ' + e.Message + '|' + SQLString;
      end;

      SQLString := 'UPDATE maschinf SET Kavitaet = ' + SollKavitaet
                 + ' WHERE betriebsauftragnr = ''' + new + '''';
      try
        SQL_Insert(qUpdate, SQLString);
      except on e: Exception do
        ResString := ResString + 'Exception: ' + e.Message + '|' + SQLString;
      end;

      SQLString := 'UPDATE aarchiv SET Kavitaet = ' + SollKavitaet
                 + ' WHERE betriebsauftragnr = ''' + new + '''';
      try
        SQL_Insert(qUpdate, SQLString);
      except on e: Exception do
        ResString := ResString + 'Exception: ' + e.Message + '|' + SQLString;
      end;

      SQLString := 'SELECT *'
                 + ' FROM PDE'
                 + ' WHERE betriebsauftragnr = ''' + new + '''';
      try
        SQL_Get(qSuch2, SQLString);
      except on e: Exception do
        ResString := ResString + 'Exception: ' + e.Message + '|' + SQLString;
      end;
      if not qSuch2.IsEmpty then
        begin
          SQLString := 'insert into KavProt (Nr, BetriebsAuftragNr, AuftragNr, Bezeichnung,'
                    + ' Lizenz, Wert1, Wert2, Produziert, Datum, EintragDatum) values (KavProtId.NextVal,'
                    + ' ''' + new + ''','
                    + ' ''' + qSuch2.FieldByName('AuftragNr').AsString + ''','
                    + ' ''' + qSuch2.FieldByName('Bezeichnung').AsString + ''','
                    + ' ''' + qSuch2.FieldByName('Lizenz').AsString + ''','
                    + ' ''' + qSuch2.FieldByName('kavitaet_soll').AsString + ''','
                    + ' ''' + SollKavitaet + ''','
                    + ' ''0'','
                    + FloatToPunktString(Now) + ','
                    + FloatToPunktString(Now) + ')';
          try
            SQL_Insert(qUpdate, SQLString);
          except on e: Exception do
            ResString := ResString + 'Exception: ' + e.Message + '|' + SQLString;
          end;

          if SQLGet(qUpdate,'Setup','WZKavitaet_Update','1', true) > 0 then
          begin
            SQLString := 'update Werkzeug set WZKavitaet = ' + SollKavitaet
                       + ' where Werkzeug = ''' + qSuch2.FieldByName('Werkzeug').AsString + '''';
            try
              SQL_Insert(qUpdate, SQLString);
            except
              ResString := ResString + '<br>' + GetL('Fehler ') + GetL('bei ') + GetL('Kavität: ') + SollKavitaet + GetL('(Werkzeug)');
            end;
          end;
        end
      else
        ResString := ResString + '<br>' + GetL('Fehler ') + GetL('keine ') + GetL('Kavität? (') + new + ')';
      ResString := ResString + '<br>' + GetL('Kavität ') + GetL('eingestellt auf: ') + SollKavitaet;
    except
      ResString := ResString + '<br>' + GetL('Fehler ') + GetL('bei ') + GetL('Kavität: ') + SollKavitaet;
    end;

    //Now copy GRNs and also set the Silo accordingly!

    //THESE ARE the latest GRNs per Material excluding Material from Silos;
    SQLString := ' SELECT mz.*'
               + ' FROM MATERIALZUOR mz'
               + ' INNER JOIN materialchargen mc ON mz.eancode = mc.eancode'
               + ' INNER JOIN materialstueckliste msl ON msl.materialid = mc.materialid'
               + ' WHERE NR IN'
               + '   ('
               + '        SELECT max(MZ.Nr)'
               + '        FROM MATERIALCHARGEN MC'
               + '        INNER JOIN MATERIALZUOR MZ ON MC.EANCODE = MZ.EANCODE'
               + '        WHERE betriebsauftragnr = ''' + old + '''';
    if Materialid <> '' then
      SQLString := SQLString + '        AND materialid <> ' + Materialid;
    SQLString := SQLString
               + '        GROUP BY materialid'
               + '    )'
               + ' AND msl.betriebsauftragnr = ''' + new + '''';
    try
      SQL_Get(qSuch2, SQLString);
    except on e: Exception do
      ResString := ResString + 'Exception: ' + e.Message + '|' + SQLString;
    end;
    if not qSuch2.IsEmpty then
    begin
      GRNsCopied := 0;
      while not qSuch2.Eof do
      begin
                SQLString := 'Insert into MaterialZuor (Nr,Betriebsauftragnr, ts_reported, ts_assigned, EANCode, copied) '
                   + ' VALUES (MATERIALZUORID.nextval'
                   + ',''' + new
                   + ''',0,' + FloatToPunktString(Now)
                   + ',''' + qSuch2.FieldByName('EANCode').AsString + ''', 1)';
        try
          SQL_Insert(qUpdate, SQLString);
          GRNsCopied := GRNsCopied + 1;
        except
          ResString := ResString + '<br>' + GetL('Fehler ') + GetL('bei ') + GetL('Charge: ') + qSuch2.FieldByName('EANCode').AsString;
        end;
        qSuch2.Next;
      end;
      ResString := ResString + '<br>' + IntToStr(GRNsCopied) +  GetL('Chargen ') + GetL('gebucht.');
    end
    else
      ResString := ResString + '<br>' + GetL('Keine ') + GetL('Chargen ') + GetL('gebucht.');

    //And Now we do the Silo
    if not TCO_Setup.GetParamBool(qSuch, 'INCL_CopySiloOnStart') then
    begin
      try
        ResString := ResString + '<br>' + SiloBuchen(new, Materialid, SiloNr, qSuch, qUpdate);
      except on e: Exception do
        ResString := ResString + 'Exception: ' + e.Message + '|' + SQLString;
      end;
    end;

  end
  else
    ResString := ResString + '<br>' + GetL('Fehler (') + old + ')';

  Result := ResString;
end;

function CopySilo(old, new: string; qSuch, qSuch2: TCO_Query):Integer;
var
  MaterialidNeu, MaterialidAlt, SiloNr, SollKavitaet, ResString, SQLString: string;
begin
  ResString := '';

  SQLString := 'SELECT aarchiv.*, SILOS.materialid silomaterial, SILOS.Nr silonr'
             + ' FROM aarchiv'
             + ' LEFT JOIN SILOS on aarchiv.SILONAME = SILOS.SILONAME'
             + ' WHERE betriebsauftragnr = ''' + old + '''';
  try
    SQL_Get(qSuch, SQLString);
  except on e: Exception do
    ResString := ResString + 'Exception: ' + e.Message + '|' + SQLString;
  end;

  if not qSuch.IsEmpty then
  begin
    try
      //Get the SIloNumber and it's materialid just in case while we have the right query
      SiloNr := qSuch.FieldByName('SiloNr').AsString;
      MaterialidAlt := qSuch.FieldByName('SiloMaterial').AsString;
      //RS 06.01.2014 (Petainer SWE): Auskommentiert, weil hier noch nicht sicher, dass das Silo-Material des alten Auftrags auch das richtige für den neuen Auftrag ist!
      //SiloBuchen(new,MaterialidAlt,SiloNr, qSuch, qSuch2);
      Result := 1;
    except
      Result := -1;
    end;
  end;
  if (Result = 1) then
  begin
    try
      Result := -2;
      SQLString := 'SELECT mn.materialid'
                 + ' FROM materialstueckliste msl'
                 + ' INNER join materialnummern mn on mn.materialid = msl.materialid '
                 + ' WHERE BetriebsAuftragnr = ''' + new + ''''
                 + ' AND mn.materialgruppe = ''' + TCO_Setup.GetParamStr( qSuch, 'MDE_MaterialDeliveryToSiloForMaterialGroup') + '''';
      SQL_Get(qSuch, SQLString);
      while not qSuch.Eof do
      begin
        if MaterialidAlt = qSuch.FieldByName('materialid').AsString then
        begin
          SiloBuchen(new,MaterialidAlt,SiloNr, qSuch, qSuch2);
          Result := 1;
          break;
        end;
        qSuch.Next;
      end;
    except
    end;
  end;
end;


function GetComputerNetName: string;
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


Function GetUserFromWindows: string;
var
   UserName : string;
   UserNameLen : Dword;
Begin
   UserNameLen := 255;
   SetLength(userName, UserNameLen) ;
   If GetUserName(PChar(UserName), UserNameLen) Then
     Result := Copy(UserName,1,UserNameLen - 1)
   Else
     Result := 'Unknown';
End;

procedure LogMeldung(S: string); overload
begin
  LogMeldung(S, 'Reporting.log');
end;
procedure LogMeldung(S, FileName: string); overload
var
  F: TextFile;
  TSe: TSearchRec;
begin
  try
    AssignFile(F, FileName);
    if FindFirst(FileName, faAnyFile, TSe) = 0 then
      if TSe.SIZE > MaxDateiKB * 1024 then
        SysUtils.DeleteFile(FileName);
    SysUtils.FindClose(TSe);

    if FileExists(FileName) then
      Append(F)
    else
      Rewrite(F);
    WriteLn(F, DateTimeToStr(Now) +  ': ' + S);
    CloseFile(F);

  except
  end;
end;

end.

