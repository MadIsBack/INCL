namespace INCLService_CSharp
{
    public static class ComtasH
    {
        // Status codes
        public const int stLaeuftInt = 0;
        public const int stStartRuestenInt = 1;
        public const int stgeplantInt = 2;
        public const int stBeendetInt = 3;
        public const int stSchwesterLaeuftInt = 4;
        public const int stUnterbrochenInt = 5;
        public const int stFreigabeInt = 6;

        // Error codes
        public const int Konnte_Index_nicht_erzeugen = 2601;
        public const int DatenbankName_nicht_definiert = 2602;
        public const int Datenbankanbindung_gescheitert = 2603;

        public const int Auftrag_nicht_gefunden = 2501;
        public const int Werkzeug_nicht_auf_Maschine = 2502;
        public const int Maschine_nicht_frei = 2503;
        public const int Anderer_Auftrag_wird_geruestet = 2504;
        public const int Fehler_Auftragsstart = 2505;
        public const int Werkzeug_nicht_vorhanden = 2506;

        // TPM
        public const int CANLAGENAUSFALL = 0;
        public const int CRUESTEN = 1;
        public const int CLOGISTIK = 2;
        public const int CNICHT_GEBUCHT = 3;

        public const int CUNGEPLANT = 0;
        public const int CGEPLANT = 1;
    }
}
