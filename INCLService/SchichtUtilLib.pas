unit SchichtUtilLib;

interface

uses Classes, SysUtils;

type
  TStillstandEintrag = class
  public
    Nr : integer;
    Kommt: TDateTime;
    Geht: TDateTime;
    GrundNr: Integer;
    Geplant: Boolean;
    Maschnr : Integer;
    Gruppe: Integer; // 0 -> Anlagenausfall, 1 -> Rüsten 2 ->  Logistik 3 -> ungebucht
    Stillstand : string;
    function CopyMe : TStillstandEintrag;
  end;

  TStillstandEintragsListe = class(TList)
  private
    function getItem(index: Integer): TStillstandEintrag;
    procedure setItem(index: Integer; const Value: TStillstandEintrag);

  public
    property Items[index: Integer]: TStillstandEintrag read getItem write setItem;

    function getMaschNrsString : string;
    function GetByMaschNr(aMaschNr : Integer) : TStillstandEintragsListe;
    function Add(aStillstandEintrag: TStillstandEintrag): Integer;
    function AddRaw(aStillstandEintrag: TStillstandEintrag): Integer;
    function GetDauerByMaschNr(aMaschNr : Integer) : Integer;
    function GetDauerByMaschNrFromDate(aFromDate : TDatetime; aMaschNr : Integer) : Integer;
    function GetOpenByMaschNr(aMaschNr : Integer) : TStillstandEintrag;
    procedure Clear;
    destructor Destroy;

  end;

  TStartStopEintrag = class
  private
    function CopyMe : TStartStopEintrag;
  public
    AuftragNr: string;
    RuestStart: TDateTime;
    Start: TDateTime;
    Stop: TDateTime;

  end;

  TStartStopEintragsListe = class(TList)
  private
    function getItem(index: Integer): TStartStopEintrag;
    procedure setItem(index: Integer; const Value: TStartStopEintrag);

  public
    property Items[index: Integer]: TStartStopEintrag read getItem write setItem;
    function Add(aStartStopEintrag: TStartStopEintrag): Integer;
    function GetByBetriebsauftragNr(aBANr : string) : TStartStopEintragsListe;
    procedure Clear;
    destructor Destroy;
  end;
type
  TSignalLogEintrag = class
  public
    maschnr: integer;
    wert : integer;
    Start: TDateTime;
    Stop: TDateTime;

    function CopyMe : TSignalLogEintrag;
  end;
type
  TSignalLogEintragListe = class(TList)
  private
    function getItem(index: Integer): TSignalLogEintrag;
    procedure setItem(index: Integer; const Value: TSignalLogEintrag);
  public
    property Items[index: Integer]: TSignalLogEintrag read getItem write setItem;
    function Add(aSignalLogEintrag: TSignalLogEintrag): Integer;
    function GetByMaschNr(aMaschNr : Integer) : TSignalLogEintragListe;
    procedure Clear;
    destructor Destroy;
  end;

implementation

{ TStillstandEintragsListe }

function TStillstandEintragsListe.Add(
  aStillstandEintrag: TStillstandEintrag): Integer;
var found : boolean;
    i : integer;
begin
  for i := 0 to Self.Count-1 do
  begin
    found := Items[i].Nr = aStillstandEintrag.Nr;
    if found then
    begin
      Result := i;
      exit;
    end;
  end;
  // Um zu vermeiden dass doppelte drin sein könnten wird geprüft
  Result := TList(Self).Add(aStillstandEintrag);
end;

function TStillstandEintragsListe.AddRaw(aStillstandEintrag: TStillstandEintrag): Integer;
begin
  Result := TList(Self).Add(aStillstandEintrag);
end;


function TStillstandEintragsListe.GetDauerByMaschNr(aMaschNr : Integer) : Integer;
var dauer : Extended;
  i : Integer;
    stillende : extended;
begin
  dauer := 0;
  for i := 0 to Count-1 do
  begin
    if Items[i].Maschnr = aMaschNr then
    begin
      stillende := Items[i].Geht;
      if Items[i].geht < 1 then
        stillende := Now;
      if Items[i].kommt < stillende then
        dauer := dauer + ((stillende - Items[i].kommt)*1440);
    end;
  end;
  result := round(dauer);
end;

function TStillstandEintragsListe.GetDauerByMaschNrFromDate(aFromDate : TDatetime; aMaschNr : Integer) : Integer;
var dauer : Extended;
  i : Integer;
    stillgeht : extended;
    stillkommt : extended;
begin
  dauer := 0;
  for i := 0 to Count-1 do
  begin
    if Items[i].Maschnr = aMaschNr then
    begin
      stillgeht := Items[i].Geht;
      stillkommt := items[i].Kommt;
      if stillgeht < 1 then
        stillgeht := Now;
      if stillkommt < aFromDate then
        stillkommt := aFromDate;
      if stillkommt > stillgeht then
        stillkommt := stillgeht;
      dauer := dauer + ((stillgeht - stillkommt)*1440);
    end;
  end;
  result := round(dauer);
end;


procedure TStillstandEintragsListe.Clear;
begin
  while Self.Count > 0 do
  begin
    Self.Items[0].Free;
    Self.Delete(0);
  end;
  inherited;
end;

destructor TStillstandEintragsListe.Destroy;
begin
  while Self.Count > 0 do
  begin
    Self.Items[0].Free;
    Self.Delete(0);
  end;
  inherited;
end;

function TStillstandEintragsListe.GetByMaschNr(
  aMaschNr: Integer): TStillstandEintragsListe;
var i : Integer;
begin
  result := TStillstandEintragsListe.Create;
  for i := 0 to self.Count-1 do
  begin
    if self.Items[i].maschnr = aMaschnr then
    begin
//      result.Add(self.Items[i].CopyMe);
        result.Add(self.Items[i]);
    end;
  end;

end;


function TStillstandEintragsListe.getItem(
  index: Integer): TStillstandEintrag;
begin
  Result := TStillstandEintrag(TList(Self).Items[index]);

end;

function TStillstandEintragsListe.getMaschNrsString: string;
var s : string;
    i : Integer;
begin
  s := '';
  for i := 0 to self.Count-1 do
  begin
    if Pos(' ' + IntTostr(self.Items[i].Maschnr) + ',', s) = 0 then
      s := s + ' ' + IntTostr(self.Items[i].Maschnr) + ',';
  end;
  if s <> '' then
    system.Delete(s, length(s),1);
  result := s;
end;

procedure TStillstandEintragsListe.setItem(index: Integer;
  const Value: TStillstandEintrag);
begin
  Self[index] := Value;
end;

function TStillstandEintragsListe.GetOpenByMaschNr(
  aMaschNr: Integer): TStillstandEintrag;
var i : Integer;
begin
  result := nil;
  for i := 0 to self.Count-1 do
  begin
    if (self.Items[i].maschnr = aMaschnr)and (self.Items[i].Geht < 1) then
    begin
      result :=self.Items[i];
      exit;
    end;
  end;
end;

{ TStartStopEintragsListe }

function TStartStopEintragsListe.Add(
  aStartStopEintrag: TStartStopEintrag): Integer;
begin
  Result := TList(Self).Add(aStartStopEintrag);
end;

procedure TStartStopEintragsListe.Clear;
begin
  while Self.Count > 0 do
  begin
    Self.Items[0].Destroy;
    Self.Delete(0);
  end;
  inherited;

end;

destructor TStartStopEintragsListe.Destroy;
begin
  while Self.Count > 0 do
  begin
    Self.Items[0].Destroy;
    Self.Delete(0);
  end;
  inherited;
end;

function TStartStopEintragsListe.GetByBetriebsauftragNr(
  aBANr: string): TStartStopEintragsListe;
var i : Integer;
begin
  result := TStartStopEintragsListe.Create;
  for i := 0 to self.Count-1 do
  begin
    if self.Items[i].AuftragNr = aBANr then
    begin
//      result.Add(self.Items[i].CopyMe);
      result.Add(self.Items[i]);
    end;
  end;
end;

function TStartStopEintragsListe.getItem(
  index: Integer): TStartStopEintrag;
begin
  Result := TStartStopEintrag(TList(Self).Items[index]);

end;

procedure TStartStopEintragsListe.setItem(index: Integer;
  const Value: TStartStopEintrag);
begin
  Self[index] := Value;
end;

{ TSignalLogEintragListe }

function TSignalLogEintragListe.Add(
  aSignalLogEintrag: TSignalLogEintrag): Integer;
begin
  Result := TList(Self).Add(aSignalLogEintrag);

end;

procedure TSignalLogEintragListe.Clear;
begin
  while Self.Count > 0 do
  begin
    Self.Items[0].Destroy;
    Self.Delete(0);
  end;
  inherited;

end;

destructor TSignalLogEintragListe.Destroy;
begin
  while Self.Count > 0 do
  begin
//    Self.Items[0].Destroy;
    Self.Items[0].Free;
    Self.Delete(0);
  end;
  inherited;

end;

function TSignalLogEintragListe.GetByMaschNr(
  aMaschNr: Integer): TSignalLogEintragListe;
var i : Integer;
begin
  result := nil;
        result := TSignalLogEintragListe.Create;
  for i := 0 to self.Count-1 do
  begin
    if self.Items[i].maschnr = aMaschnr then
    begin
//      if result = nil then
  //      result := TSignalLogEintragListe.Create;
//      result.Add(self.Items[i].CopyMe);
      result.Add(self.Items[i]);
    end;
  end;
end;

function TSignalLogEintragListe.getItem(index: Integer): TSignalLogEintrag;
begin
  Result := TSignalLogEintrag(TList(Self).Items[index]);

end;

procedure TSignalLogEintragListe.setItem(index: Integer;
  const Value: TSignalLogEintrag);
begin
  Self[index] := Value;

end;

{ TSignalLogEintrag }

function TSignalLogEintrag.CopyMe: TSignalLogEintrag;
begin
  Result := TSignalLogEintrag.Create;
  Result.maschnr := self.maschnr;
  Result.wert := self.wert;
  Result.Start := self.Start;
  Result.Stop := self.Stop;
end;

{ TStillstandEintrag }

function TStillstandEintrag.CopyMe: TStillstandEintrag;
begin
  result := TStillstandEintrag.Create;
  result.Kommt := self.Kommt;
  result.Geht := self.Geht;
  result.GrundNr := self.GrundNr;
  result.Geplant := self.Geplant;
  result.Maschnr := self.Maschnr;
  result.Gruppe := self.Gruppe;
  result.Stillstand := self.Stillstand;
end;

{ TStartStopEintrag }

function TStartStopEintrag.CopyMe: TStartStopEintrag;
begin
  result := TStartStopEintrag.Create;
  result.Start := self.Start;
  result.Stop := self.Stop;
  result.AuftragNr := self.AuftragNr;
  result.RuestStart := self.RuestStart;
end;

end.

