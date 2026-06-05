unit VarConst;

interface

var
  Option: record
    ZUSATZ_EXTRUSION: Boolean;
    RechnerNr : Integer;
  end;

  const AppId = -1;
  const stLagerplatzHistorie = -1;

implementation

begin
  Option.ZUSATZ_EXTRUSION := False;
  Option.RechnerNr := -1;
end.
