unit DatenM;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls,
  DB, MemDS, DBAccess, CO_DataBase, ADODB
  {$IFDEF ODAC}
    ,Ora;
  {$ELSE}
    {$IFNDEF NONUNI}
      ,Uni;
    {$ELSE}
      ;
    {$ENDIF}
  {$ENDIF}  

type
  TDaten = class(TDataModule)
    qSuch: TCO_Query;
    qUpdate: TCO_Query;
    qWerte: TCO_Query;
    qCount: TCO_Query;
    qCreateDB: TCO_Query;
    qSuch2: TCO_Query;
    qSuch4: TCO_Query;
    qIstwert: TCO_Query;
    qDurchlauf: TCO_Query;
    Database: TCO_Database;
    qTMP: TCO_Query;
    qSuch5: TCO_Query;
    qSuch3: TCO_Query;
    qUpdateS: TCO_Query;
    qLog: TCO_Query;
    qSetupPar: TCO_Query;
  private
  public
    Conn: Boolean;
  end;

var
  Daten: TDaten;

implementation

//uses Main;

{$R *.DFM}

end.
