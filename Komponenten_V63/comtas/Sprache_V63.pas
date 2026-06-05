unit Sprache_V63;

interface

uses
  QuickRpt, CO_DataBase, Dialogs, Forms, DBTables, Classes, CheckLst;

const
  {$IFDEF Sprachdebug}
    DEBUGSpracheFILE = 1;
  {$ELSE}
    DEBUGSpracheFILE = 0;
  {$ENDIF}

  SP_DEUTSCH = 0;
  SP_SPANISCH = 5000;
  SP_DAENISCH = 10000;
  SP_USENGLISCH = 15000;
  SP_TSCHECHISCH = 20000;
  SP_SCHWEDISCH = 25000;
  SP_POLNISCH = 30000;

  SP_Anzahl = 7;

  SP_FORMAT_EUROPE = 0;
  SP_FORMAT_USA = 1;

  REPORT_DEUTSCH = 0;
  REPORT_ENGLISCH = 1;

type
  TSpracheWort = record
    DE, Andere: string;
  end;

var
  SprachWortAnzahl: Integer;
  SpracheWort: array of TSpracheWort;

  CustomWort: array of TSpracheWort;

  SpracheNr: Integer;
  Sprache2: Integer;
  Sprache_Format: Integer;

  // Sprache_Format = 0 - EUROPE
  // Sprache_Format = 1 - USA

  // SpracheNr = SP_USENGLISCH
  // Sprache_Format = SP_FORMAT_USA

  // Sprache2 für die default Sprache, wenn Wort nicht übersetzt ist.
  // Muss nur 0 oder 15000 sein.

  DBSeparator: Char;

const
  MaxString = 255;
  Offset = 1000;

function GetL(T: string): string; stdcall;
procedure MakeFormLanguage(Form: TComponent);
procedure MakeReportLanguage(Form: TForm); overload;
procedure MakeReportLanguage(Form: TQuickRep); overload;

procedure MakeEnviroment(Q: TCO_Query);
function MessageDialog(const Msg: string; DlgType: TMsgDlgType; Buttons: TMsgDlgButtons): Integer;
function LoadLanguageArray: Integer;
function GetNext(var D: string): string;

implementation

uses
  QRPrntr, QRCTrls, Buttons, ExtCtrls, Menus, StdCtrls, Windows, SysUtils,
  ComCtrls, DBGrids;

const
  SetSym = ['0'..'9', '=', ':', ';', '!', '.', #32, '&', '?', ',', '-', '>', '<',
    '^', '_', '"', '''', '#', '(', ')', '[', ']', '*', '+', '/', '\', '%', '+'];

function MessageDialog(const Msg: string; DlgType: TMsgDlgType; Buttons: TMsgDlgButtons): Integer;
var
  Cap: string;
  Fl: Longint;
begin
  Cap := '';
  Fl := 0;
  case DlgType of
    mtWarning:
      begin
        Cap := GetL('Warnung');
        Fl := MB_ICONEXCLAMATION;
      end;
    mtError:
      begin
        Cap := GetL('Fehler');
        Fl := MB_ICONHAND;
      end;
    mtInformation:
      begin
        Cap := GetL('Information');
        Fl := MB_ICONASTERISK;
      end;
    mtConfirmation:
      begin
        Cap := GetL('Bestätigung');
        Fl := MB_ICONQUESTION;
      end;
  end;
  if Buttons = [mbOK] then
    Fl := Fl + MB_OK;
  if Buttons = [mbYes, mbNo] then
    Fl := Fl + MB_YESNO;
  if Buttons = [mbOK, mbCancel] then
    Fl := Fl + MB_OKCANCEL;
  if Buttons = [mbYes, mbAbort, mbNo] then
    Fl := Fl + MB_YESNOCANCEL;

  Result := Application.MESSAGEBOX(PChar(Msg), PChar(Cap), Fl);
end;

procedure MakeFormLanguage(Form: TComponent);
var
  I, J: Integer;
begin
  Application.ProcessMessages;
  if Form is TForm then
  begin
    if (Form as TForm).Tag = 0 then
    begin
      (Form as TForm).Hint := GetL((Form as TForm).Hint);
      (Form as TForm).Caption := GetL((Form as TForm).Caption);
    end;
  end;

  for I := 0 to Form.ComponentCount - 1 do
  begin
    if Form.Components[I] is TLabel then
      with Form.Components[I] as TLabel do
        if Tag = 0 then
        begin
          Hint := GetL(Hint);
          Caption := GetL(Caption);
        end;

    if Form.Components[I] is TEdit then
      with Form.Components[I] as TEdit do
        if Tag = 0 then
        begin
          Hint := GetL(Hint);
          Text := GetL(Text);
        end;

    if Form.Components[I] is TLabeledEdit then
      with Form.Components[I] as TLabeledEdit do
        if Tag = 0 then
        begin
          EditLabel.Caption := GetL(EditLabel.Caption);
          EditLabel.Hint := GetL(EditLabel.Hint);
          Hint := GetL(Hint);
          Text := GetL(Text);
        end;

    if Form.Components[I] is TToolButton then
      with Form.Components[I] as TToolButton do
        if Tag = 0 then
        begin
          Hint := GetL(Hint);
          Caption := GetL(Caption);
        end;

    if Form.Components[I] is TMenuItem then
      with Form.Components[I] as TMenuItem do
        if Tag = 0 then
        begin
          Hint := GetL(Hint);
          Caption := GetL(Caption);
        end;

    if Form.Components[I] is TButton then
      with Form.Components[I] as TButton do
        if Tag = 0 then
        begin
          Hint := GetL(Hint);
          Caption := GetL(Caption);
        end;

    if Form.Components[I] is TCheckBox then
      with Form.Components[I] as TCheckBox do
        if Tag = 0 then
        begin
          Hint := GetL(Hint);
          Caption := GetL(Caption);
        end;

    if Form.Components[I] is TRadioButton then
      with Form.Components[I] as TRadioButton do
        if Tag = 0 then
        begin
          Hint := GetL(Hint);
          Caption := GetL(Caption);
        end;

    if Form.Components[I] is TBitBtn then
      with Form.Components[I] as TBitBtn do
        if Tag = 0 then
        begin
          Hint := GetL(Hint);
          Caption := GetL(Caption);
        end;

    if Form.Components[I] is TSpeedButton then
      with Form.Components[I] as TSpeedButton do
        if Tag = 0 then
        begin
          Hint := GetL(Hint);
          Caption := GetL(Caption);
        end;

    if Form.Components[I] is TPanel then
      with Form.Components[I] as TPanel do
        if Tag = 0 then
        begin
          Hint := GetL(Hint);
          Caption := GetL(Caption);
        end;

    if Form.Components[I] is TStaticText then
      with Form.Components[I] as TStaticText do
        if Tag = 0 then
        begin
          Hint := GetL(Hint);
          Caption := GetL(Caption);
        end;

    if Form.Components[I] is TComboBox then
      with Form.Components[I] as TComboBox do
        if Tag = 0 then
        begin
          Text := GetL(Text);
          Hint := GetL(Hint);
          for J := 1 to Items.Count do
            Items[J - 1] := GetL(Items[J - 1]);
        end;

    if Form.Components[I] is TListBox then
      with Form.Components[I] as TListBox do
        if Tag = 0 then
        begin
          Hint := GetL(Hint);
          for J := 1 to Items.Count do
            Items[J - 1] := GetL(Items[J - 1]);
        end;

    if Form.Components[I] is TCheckListBox then
      with Form.Components[I] as TCheckListBox do
        if Tag = 0 then
        begin
          Hint := GetL(Hint);
          for J := 1 to Items.Count do
            Items[J - 1] := GetL(Items[J - 1]);
        end;

    if Form.Components[I] is TMemo then
      with Form.Components[I] as TMemo do
        if Tag = 0 then
        begin
          Hint := GetL(Hint);
          for J := 1 to Lines.Count do
            Lines[J - 1] := GetL(Lines[J - 1]);
        end;

    if Form.Components[I] is TTabSheet then
      with Form.Components[I] as TTabSheet do
        if Tag = 0 then
        begin
          Hint := GetL(Hint);
          Caption := GetL(Caption);
        end;

    if Form.Components[I] is TGroupBox then
      with Form.Components[I] as TGroupBox do
        if Tag = 0 then
        begin
          Hint := GetL(Hint);
          Caption := GetL(Caption);
        end;

    if Form.Components[I] is TRadioGroup then
      with Form.Components[I] as TRadioGroup do
        if Tag = 0 then
        begin
          Hint := GetL(Hint);
          Caption := GetL(Caption);
          for J := 1 to Items.Count do
            Items[J - 1] := GetL(Items[J - 1]);
        end;

    if Form.Components[I] is TListView then
      with Form.Components[I] as TListView do
        if Tag = 0 then
        begin
          Hint := GetL(Hint);
          for J := 1 to Columns.Count do
            Columns[J - 1].Caption := GetL(Columns[J - 1].Caption);
        end;

    if Form.Components[I] is TDBGrid then
      with Form.Components[I] as TDBGrid do
        if Tag = 0 then
        begin
          Hint := GetL(Hint);
          for J := 1 to Columns.Count do
            Columns[J - 1].Title.Caption := GetL(Columns[J - 1].Title.Caption);
        end;
  end;
end;

procedure MakeReportLanguage(Form: TForm);
var
  I: Integer;
begin
  for I := 0 to Form.ComponentCount - 1 do
  begin
    if Form.Components[I] is TQRLabel then
      with Form.Components[I] as TQRLabel do
        Caption := GetL(Caption);

    if Form.Components[I] is TQuickRep then
    begin
      if Sprache_Format = SP_FORMAT_USA then
        (Form.Components[I] as TQuickRep).Page.PaperSize := Letter
      else
        (Form.Components[I] as TQuickRep).Page.PaperSize := A4;
    end;
  end;
end;

procedure MakeReportLanguage(Form: TQuickRep);
var
  I: Integer;
begin
  for I := 0 to Form.ComponentCount - 1 do
  begin
    if Form.Components[I] is TQRLabel then
      with Form.Components[I] as TQRLabel do
        Caption := GetL(Caption);

    if Form.Components[I] is TQuickRep then
    begin
      if Sprache_Format = SP_FORMAT_USA then
        (Form.Components[I] as TQuickRep).Page.PaperSize := Letter
      else
        (Form.Components[I] as TQuickRep).Page.PaperSize := A4;
    end;
  end;
end;

procedure MakeEnviroment(Q: TCO_Query);
var
  STer, SLang, SDate: string;
begin
  // Sprache_Format := 0;

  if INCLUDISDatabaseTyp > 0 then
  begin
    DecimalSeparator := '.';
    ThousandSeparator := ',';
  end;

  STer := '';
  SLang := '';
  SDate := '';
  case SysLocale.DefaultLCID of
    $0405:
      begin
        STer := 'CZECH REPUBLIC';
        SLang := 'CZECH'
      end;
    $0406:
      begin
        STer := 'DENMARK';
        SLang := 'DANISH';
        SDate := 'DD-MM-YY';
      end;
    $0407:
      begin
        STer := 'GERMANY';
        SLang := 'GERMAN';
      end;
    $0409:
      begin
        STer := 'AMERICA';
        SLang := 'AMERICAN';
        SDate := 'MM/DD/YY';
        Sprache_Format := 1;
      end;
    $041D:
      begin
        STer := 'SWEDEN';
        SLang := 'SWEDISH';
      end;
    $0807:
      begin
        STer := 'SWITZERLAND';
        SLang := 'GERMAN';
      end;
    $0809:
      begin
        STer := 'UNITED KINGDOM';
        SLang := 'ENGLISH';
      end;
    $0C07:
      begin
        STer := 'AUSTRIA';
        SLang := 'GERMAN';
      end;
    $0C0A:
      begin
        STer := 'SPAIN';
        SLang := 'SPANISH';
      end;
    $1009:
      begin
        STer := 'CANADA';
        SLang := 'ENGLISH';
        SDate := 'MM/DD/YY';
        Sprache_Format := 1;
      end;
    $0441:
      begin
        STer := 'FINLAND';
        SLang := 'FINNISH';
      end;
    $0408:
      begin
        STer := 'GREECE';
        SLang := 'GREEK';
      end;
    $040E:
      begin
        STer := 'HUNGARY';
        SLang := 'HUNGARIAN';
      end;
    $0410:
      begin
        STer := 'ITALY';
        SLang := 'ITALIAN';
      end;
    $080A:
      begin
        STer := 'MEXICO';
        SLang := 'MEXICAN SPANISH';
      end;
    $041B:
      begin
        STer := 'SLOVAKIA';
        SLang := 'SLOVAK';
      end;
    $0424:
      begin
        STer := 'SLOVENIA';
        SLang := 'SLOVENIAN';
      end;
    $0415:
      begin
        STer := 'POLAND';
        SLang := 'POLISH';
      end;
    $040C:
      begin
        STer := 'FRANCE';
        SLang := 'FRENCH';
      end;
  else
    begin
      STer := 'GERMANY';
      SLang := 'GERMAN';
    end;

  end;
  if STer <> '' then
  begin
    try
    Q.SQL.Text := 'Alter Session Set NLS_LANGUAGE=' + SLang;
    Q.ExecSQL;
    Q.SQL.Clear;
    Q.SQL.Text := 'Alter Session Set NLS_TERRITORY=''' + STer + '''';
    Q.ExecSQL;
    if SDate <> '' then
    begin
      Q.SQL.Text := 'Alter Session Set NLS_DATE_FORMAT=''' + SDate + '''';
      Q.ExecSQL;
    end;
    Q.SQL.Clear;
    except
    end;
  end;
end;

function GetNext(var D: string): string;
var
  S: string;
begin
  if Pos(';', D) = 0 then
  begin
    S := D;
    D := '';
  end
  else
  begin
    S := Copy(D, 1, Pos(';', D) - 1);
    System.Delete(D, 1, Pos(';', D));
  end;
  while (Length(S) > 0) and (S[1] = #32) do
    System.Delete(S, 1, 1);
  while (Length(S) > 0) and (S[Length(S)] = #32) do
    System.Delete(S, Length(S), 1);
  Result := S;
end;

function LoadLanguageArray: Integer;
var
  I, J, SpNr: Integer;
  ST: TStringList;
  S: string;

  procedure QuickSort(iLo, iHi: Integer);
  var
    Lo, Hi: Integer;
    MId, T: string;
  begin
    Lo := iLo;
    Hi := iHi;
    MId := SpracheWort[(Lo + Hi) div 2].DE;
    repeat
      while SpracheWort[Lo].DE < MId do
        Inc(Lo);
      while SpracheWort[Hi].DE > MId do
        Dec(Hi);
      if Lo <= Hi then
      begin
        T := SpracheWort[Lo].DE;
        SpracheWort[Lo].DE := SpracheWort[Hi].DE;
        SpracheWort[Hi].DE := T;
        T := SpracheWort[Lo].Andere;
        SpracheWort[Lo].Andere := SpracheWort[Hi].Andere;
        SpracheWort[Hi].Andere := T;

        Inc(Lo);
        Dec(Hi);
      end;
    until Lo > Hi;
    if Hi > iLo then
      QuickSort(iLo, Hi);
    if Lo < iHi then
      QuickSort(Lo, iHi);
  end;

begin
  Result := 0;
  if SprachWortAnzahl = -1 then
  begin
    SprachWortAnzahl := 0;

    SpNr := 0;
    case SpracheNr of
      SP_DEUTSCH: SpNr := 0;
      SP_USENGLISCH: SpNr := 1;
      SP_DAENISCH: SpNr := 2;
      SP_SPANISCH: SpNr := 3;
      SP_TSCHECHISCH: SpNr := 4;
      SP_SCHWEDISCH: SpNr := 5;
      SP_POLNISCH: SpNr := 6;
    end;

    ST := TStringList.Create;
    try
      if FileExists(ExtractFilePath(ParamStr(0)) + 'lang.dat') then
        ST.LOADFROMFILE(ExtractFilePath(ParamStr(0)) + 'lang.dat')
      else
        Result := -1;
    except
      ST.Free;
      Exit;
    end;

    SetLength(SpracheWort, ST.Count);
    SprachWortAnzahl := ST.Count - 1;

    try
      for I := 1 to SprachWortAnzahl do
      begin
        S := ST[I];
        while Pos('~', S) > 0 do
          S[Pos('~', S)] := '"';
        SpracheWort[I].DE := GetNext(S);
        SpracheWort[I].Andere := SpracheWort[I].DE;
        for J := 1 to SpNr do
          SpracheWort[I].Andere := GetNext(S);
      end;
    except
      SprachWortAnzahl := 0;
      Exit;
    end;
    ST.Free;

    if SprachWortAnzahl > 0 then
      QuickSort(1, SprachWortAnzahl);
  end;

  ST := TStringList.Create;
  if FileExists(ExtractFilePath(ParamStr(0)) + 'custom.dat') then
    ST.LOADFROMFILE(ExtractFilePath(ParamStr(0)) + 'custom.dat');

  SetLength(CustomWort, ST.Count);

  for I := 0 to ST.Count - 1 do
  begin
    S := ST[I];
    while Pos('~', S) > 0 do
      S[Pos('~', S)] := '"';
    CustomWort[I].DE := GetNext(S);
    CustomWort[I].Andere := GetNext(S);
  end;

  ST.Free;
end;

function GetL(T: string): string;
var
  I, A, B, C: Integer;
  S, Txt1: string;
  TXT, Txt2, AsciiTXT: string;
  F: TextFile;
begin
  S := T;

  LoadLanguageArray;

  // custom.dat
  for I := 0 to Length(CustomWort) - 1 do
    if T = CustomWort[I].DE then
    begin
      Result := CustomWort[I].Andere;
      Exit;
    end;

  if SprachWortAnzahl < 1 then
  begin
    Result := S;
    Exit;
  end;

  TXT := S;
  Txt1 := '';
  Txt2 := '';

  while (Length(TXT) > 0) and (TXT[Length(TXT)] in SetSym) do
  begin
    Txt2 := TXT[Length(TXT)] + Txt2;
    SetLength(TXT, Length(TXT) - 1);
  end;

  while (Length(TXT) > 0) and (TXT[1] in SetSym) do
  begin
    Txt1 := Txt1 + TXT[1];
    System.Delete(TXT, 1, 1);
  end;

  if Length(TXT) = 0 then
  begin
    Result := T;
    Exit;
  end;

  A := 1;
  B := SprachWortAnzahl;
  C := (B + A) div 2;
  while B - A > 1 do
  begin
    C := (B + A) div 2;
    if TXT > SpracheWort[C].DE then
      A := C
    else
      B := C;
  end;

  if TXT = SpracheWort[A].DE then
    C := A
  else
    if TXT = SpracheWort[B].DE then
      C := B;

  if TXT = SpracheWort[C].DE then
  begin
    S := SpracheWort[C].Andere;
    if (S = '-') or (S = '') then
      S := TXT;

    Result := Txt1 + S + Txt2;
  end
  else
  begin
    if DEBUGSpracheFILE = 1 then
    begin
      AssignFile(F, 'd:\comtas\wort.txt');
      try
        System.Append(F);
      except
        Rewrite(F);
      end;

      AsciiTXT := '';
      For I := 1 to length(TXT) do
      begin
        AsciiTXT := AsciiTXT + 'd' + IntToSTr(Ord(TXT[I]));
      end;
      WriteLn(F, TXT + ' - ' + AsciiTXT);

      CloseFile(F);
    end;

    Result := Txt1 + TXT + Txt2;

    if DEBUGSpracheFILE = 1 then
      Result := '*' + Result;
  end;
end;

begin
  SprachWortAnzahl := -1;

end.

