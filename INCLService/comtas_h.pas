unit comtas_h;

interface

const

  stLaeuftInt = 0;
  stStartRuestenInt = 1;
  stgeplantInt = 2;
  stBeendetInt = 3;
  stSchwesterLaeuftInt = 4;
  stUnterbrochenInt = 5;
  stFreigabeInt = 6;

  // Fehlercodes
  Konnte_Index_nicht_erzeugen = 2601;
  DatenbankName_nicht_definiert = 2602;
  Datenbankanbindung_gescheitert = 2603;

  Auftrag_nicht_gefunden = 2501;
  Werkzeug_nicht_auf_Maschine = 2502;
  Maschine_nicht_frei = 2503;
  Anderer_Auftrag_wird_geruestet = 2504;
  Fehler_Auftragsstart = 2505;
  Werkzeug_nicht_vorhanden = 2506;

  //TPM
  CANLAGENAUSFALL = 0;
  CRUESTEN = 1;
  CLOGISTIK = 2;
  CNICHT_GEBUCHT = 3;

  CUNGEPLANT = 0;
  CGEPLANT = 1;

implementation

end.

