unit SPCUtility;

interface

uses Classes, sysUtils;

type
  TSPCSchuss = class;
  TSPCValue = class;
  TSPCSchussList = class;
  TSPCValueList = class;

  TSPCMaschine = class
  public
    MaschNr : Integer;
    Lizenz : string;

    SchussList : TSPCSchussList;

    function IsOKFirst : Boolean;
    function IsOKLast : Boolean;
    function getErrorList : TStringList;
    procedure Clear;

    constructor create;
    destructor Destroy;
  end;

  TSPCSchuss = class
    Nr : Integer;
    Schuss : Integer;
    ValueList : TSPCValueList;

    function IsOK : Boolean;

    constructor create;
    destructor Destroy;
  end;

  TSPCSchussList = class(TList)
  private
    function getItem(index: Integer): TSPCSchuss;
    procedure setItem(index: Integer; const Value: TSPCSchuss);

  public
    property Items[index: Integer]: TSPCSchuss read getItem write setItem;

    function Add(aSchuss: TSPCSchuss): Integer;
    function getByNr(aNr : integer) : TSPCSchuss;

    procedure ClearList;
    constructor Create;
    destructor Destroy; override;
  end;

  TSPCValue = class
  private
    FNr : Integer;
    FName : string;
    FSoll : Extended;
    FIst : Extended;
    FMax : Extended;
    FMin : Extended;

    function getMinInPct : Extended;
    procedure setMinInPct(Value : Extended);
    function getMaxInPct : Extended;
    procedure setMaxInPct(Value : Extended);

  public
    property Nr : Integer read FNr write FNr;
    property Name : string read FName write FName;
    property Soll : Extended read FSoll write FSoll;
    property Ist : Extended read FIst write FIst;
    property MaxInPct : Extended read getMaxInPct write setMaxInPct;
    property MinInPct : Extended read getMinInPct write setMinInPct;

    property MaxValue : Extended read FMax write FMax;
    property MinValue : Extended read FMin write FMin;

    function OK : Boolean;
  end;

  TSPCValueList = class(TList)
  private
    function getItem(index: Integer): TSPCValue;
    procedure setItem(index: Integer; const Value: TSPCValue);

  public
    property Items[index: Integer]: TSPCValue read getItem write setItem;

    function Add(aValue: TSPCValue): Integer;
    function getByNr(aNr : integer) : TSPCValue;

    procedure ClearList;
    constructor Create;
    destructor Destroy; override;

  end;


implementation

constructor TSPCMaschine.create;
begin
  SchussList := TSPCSchussList.Create;
end;

destructor TSPCMaschine.Destroy;
begin
  SchussList.Destroy;
  inherited;
end;


function TSPCMaschine.IsOKFirst : Boolean;
begin
  Result := SchussList.Items[0].IsOK;
end;

function TSPCMaschine.IsOKLast : Boolean;
begin
  Result := SchussList.Items[SchussList.Count-1].IsOK;
end;

function TSPCMaschine.getErrorList : TStringList;
var i : Integer;
begin
  result := TStringList.Create;
  for i := 0 to SchussList.Count-1 do
    if not SchussList.Items[i].IsOK then
      Result.Add(IntToStr(SchussList.Items[i].Nr));
  if result.Count = 0 then
  begin
    Result.Destroy;
    Result := nil;
  end;
end;

procedure TSPCMaschine.Clear;
begin
  Lizenz := '';
  MaschNr := 0;
  SchussList.ClearList;
end;

function TSPCSchuss.IsOK : Boolean;
var i : Integer;
begin
  result := True;
  for i := 0 to ValueList.Count -1 do
    result := result and ValueList.Items[i].OK;
end;

constructor TSPCSchuss.create;
begin
  inherited;
  ValueList := TSPCValueList.Create;
end;

destructor TSPCSchuss.Destroy;
begin
  ValueList.Destroy;
  inherited;
end;

function TSPCSchussList.getItem(index: Integer): TSPCSchuss;
begin
  Result := inherited Items[index];
end;

procedure TSPCSchussList.setItem(index: Integer; const Value: TSPCSchuss);
begin
  inherited Items[index]:= Value;
end;

function TSPCSchussList.Add(aSchuss: TSPCSchuss): Integer;
begin
  result := inherited Add(aSchuss);
end;

function TSPCSchussList.getByNr(aNr : integer) : TSPCSchuss;
var i : Integer;
begin
  result := nil;
  for i:= 0 to Count-1 do
    if Items[i].Nr = aNr then
      Result := Items[i];
end;

procedure TSPCSchussList.ClearList;
var i : Integer;
begin
  for i := 0 to Count -1 do
    Items[i].ValueList.ClearList;
  inherited Clear;
end;

constructor TSPCSchussList.Create;
begin
  inherited;
end;

destructor TSPCSchussList.Destroy;
var i : Integer;
begin
  for i := 0 to Count -1 do
  begin
    if Items[i] <> nil then
    begin
      if Items[i] is TSPCSchuss then
        (Items[i] as TSPCSchuss).Destroy;
      Items[i] := nil;
    end;
  end;

  inherited;
end;


function TSPCValue.getMinInPct : Extended;
begin
  result := (1 - (FMin / FSoll)) * 100;
end;

procedure TSPCValue.setMinInPct(Value : Extended);
begin
  FMin := FSoll *(1- (Value / 100));
end;

function TSPCValue.getMaxInPct : Extended;
begin
  result := ((FMax / FSoll) - 1) * 100;
end;

procedure TSPCValue.setMaxInPct(Value : Extended);
begin
  FMax := FSoll *(1+ (Value / 100));

end;


function TSPCValue.OK : Boolean;
begin
  result := (FIst > FMin) and (FIst <= FMax);
end;


function TSPCValueList.getItem(index: Integer): TSPCValue;
begin
  Result := TSPCValue(inherited Items[index]);
end;

procedure TSPCValueList.setItem(index: Integer; const Value: TSPCValue);
begin
  inherited Items[index]:= Value;
end;

function TSPCValueList.Add(aValue: TSPCValue): Integer;
begin
  result := inherited Add(aValue);
end;

function TSPCValueList.getByNr(aNr : integer) : TSPCValue;
var i : Integer;
begin
  result := nil;
  for i:= 0 to Count-1 do
    if Items[i].FNr = aNr then
      Result := Items[i];
end;

procedure TSPCValueList.ClearList;
begin
  inherited Clear;
end;

constructor TSPCValueList.Create;
begin
  inherited;
end;

destructor TSPCValueList.Destroy;
var i : Integer;
begin
  for i := 0 to Count -1 do
  begin
    if Items[i] <> nil then
    begin
      if Items[i] is TSPCValue then
        (Items[i] as TSPCValue).Destroy;
      Items[i] := nil;
    end;
  end;
  inherited;
end;



end.
