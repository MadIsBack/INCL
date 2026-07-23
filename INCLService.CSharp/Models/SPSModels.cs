using System;
using System.Collections.Generic;

namespace INCLService.CSharp.Models
{
    /// <summary>
    /// SPS-Daten für DWORD-Werte
    /// Äquivalent zu TSPS_Daten_DWord in DBMain.pas
    /// </summary>
    public class SPS_Daten_DWord
    {
        public string Maschine { get; set; } = string.Empty;
        public string Signal { get; set; } = string.Empty;
        public int LizenzInt { get; set; } = 0;
        public string Adresse { get; set; } = string.Empty;
        public int Format { get; set; } = 0;
        public int Istwert { get; set; } = 0;
        public int Altwert { get; set; } = 0;
        public int DBNr { get; set; } = 0;
        public int SignalNr { get; set; } = 0;
        
        public SPS_Daten_DWord() { }
        
        public SPS_Daten_DWord(string maschine, string signal, int lizenzInt, string adresse, int format, int istwert, int dbNr, int signalNr)
        {
            Maschine = maschine;
            Signal = signal;
            LizenzInt = lizenzInt;
            Adresse = adresse;
            Format = format;
            Istwert = istwert;
            Altwert = istwert;
            DBNr = dbNr;
            SignalNr = signalNr;
        }
        
        public SPS_Daten_DWord Copy()
        {
            return new SPS_Daten_DWord
            {
                Maschine = Maschine,
                Signal = Signal,
                LizenzInt = LizenzInt,
                Adresse = Adresse,
                Format = Format,
                Istwert = Istwert,
                Altwert = Altwert,
                DBNr = DBNr,
                SignalNr = SignalNr
            };
        }
    }
    
    /// <summary>
    /// SPS-Daten für WORD-Werte
    /// Äquivalent zu TSPS_Daten_Word in DBMain.pas
    /// </summary>
    public class SPS_Daten_Word
    {
        public string Maschine { get; set; } = string.Empty;
        public string Signal { get; set; } = string.Empty;
        public int LizenzInt { get; set; } = 0;
        public string Adresse { get; set; } = string.Empty;
        public int Format { get; set; } = 0;
        public int Istwert { get; set; } = 0;
        public int DBNr { get; set; } = 0;
        public int SignalNr { get; set; } = 0;
        
        public SPS_Daten_Word() { }
        
        public SPS_Daten_Word(string maschine, string signal, int lizenzInt, string adresse, int format, int istwert, int dbNr, int signalNr)
        {
            Maschine = maschine;
            Signal = signal;
            LizenzInt = lizenzInt;
            Adresse = adresse;
            Format = format;
            Istwert = istwert;
            DBNr = dbNr;
            SignalNr = signalNr;
        }
        
        public SPS_Daten_Word Copy()
        {
            return new SPS_Daten_Word
            {
                Maschine = Maschine,
                Signal = Signal,
                LizenzInt = LizenzInt,
                Adresse = Adresse,
                Format = Format,
                Istwert = Istwert,
                DBNr = DBNr,
                SignalNr = SignalNr
            };
        }
    }
    
    /// <summary>
    /// SPS-Daten für BYTE-Werte
    /// Äquivalent zu TSPS_Daten_Byte in DBMain.pas
    /// </summary>
    public class SPS_Daten_Byte
    {
        public string Maschine { get; set; } = string.Empty;
        public string Signal { get; set; } = string.Empty;
        public int LizenzInt { get; set; } = 0;
        public string Adresse { get; set; } = string.Empty;
        public int Format { get; set; } = 0;
        public byte Istwert { get; set; } = 0;
        public int DBNr { get; set; } = 0;
        public int SignalNr { get; set; } = 0;
        
        public SPS_Daten_Byte() { }
        
        public SPS_Daten_Byte(string maschine, string signal, int lizenzInt, string adresse, int format, byte istwert, int dbNr, int signalNr)
        {
            Maschine = maschine;
            Signal = signal;
            LizenzInt = lizenzInt;
            Adresse = adresse;
            Format = format;
            Istwert = istwert;
            DBNr = dbNr;
            SignalNr = signalNr;
        }
        
        public SPS_Daten_Byte Copy()
        {
            return new SPS_Daten_Byte
            {
                Maschine = Maschine,
                Signal = Signal,
                LizenzInt = LizenzInt,
                Adresse = Adresse,
                Format = Format,
                Istwert = Istwert,
                DBNr = DBNr,
                SignalNr = SignalNr
            };
        }
    }
    
    /// <summary>
    /// SPS-Daten für BOOL-Werte
    /// Äquivalent zu TSPS_Daten_Bool in DBMain.pas
    /// </summary>
    public class SPS_Daten_Bool
    {
        public string Maschine { get; set; } = string.Empty;
        public string Signal { get; set; } = string.Empty;
        public int LizenzInt { get; set; } = 0;
        public string Adresse { get; set; } = string.Empty;
        public int Format { get; set; } = 0;
        public bool Istwert { get; set; } = false;
        public int DBNr { get; set; } = 0;
        public int SignalNr { get; set; } = 0;
        
        public SPS_Daten_Bool() { }
        
        public SPS_Daten_Bool(string maschine, string signal, int lizenzInt, string adresse, int format, bool istwert, int dbNr, int signalNr)
        {
            Maschine = maschine;
            Signal = signal;
            LizenzInt = lizenzInt;
            Adresse = adresse;
            Format = format;
            Istwert = istwert;
            DBNr = dbNr;
            SignalNr = signalNr;
        }
        
        public SPS_Daten_Bool Copy()
        {
            return new SPS_Daten_Bool
            {
                Maschine = Maschine,
                Signal = Signal,
                LizenzInt = LizenzInt,
                Adresse = Adresse,
                Format = Format,
                Istwert = Istwert,
                DBNr = DBNr,
                SignalNr = SignalNr
            };
        }
    }
    
    /// <summary>
    /// SPS-Daten für DWORD-Werte (dynamisch)
    /// Äquivalent zu TSPS_Daten_DWORD_Dyn in DBMain.pas
    /// </summary>
    public class SPS_Daten_DWORD_Dyn
    {
        public string Maschine { get; set; } = string.Empty;
        public string Auftrag { get; set; } = string.Empty;
        public List<string> Signal { get; set; } = new List<string>();
        public int LizenzInt { get; set; } = 0;
        public string Adresse { get; set; } = string.Empty;
        public int Format { get; set; } = 0;
        public List<double> Istwert { get; set; } = new List<double>();
        public List<double> Sollwert { get; set; } = new List<double>();
        public List<int> Tol1P { get; set; } = new List<int>();
        public List<int> Tol1N { get; set; } = new List<int>();
        public List<int> Tol2P { get; set; } = new List<int>();
        public List<int> Tol2N { get; set; } = new List<int>();
        public List<int> DBNr { get; set; } = new List<int>();
        public int SignalArt { get; set; } = 0;
        public List<int> SignalNr { get; set; } = new List<int>();
        public List<int> Stichproben { get; set; } = new List<int>();
        public List<bool> Aktiv { get; set; } = new List<bool>();
        public List<double> LetzteAbweichung { get; set; } = new List<double>();
        public List<int> LetzteGuterSchuss { get; set; } = new List<int>();
        public List<int> LetzterSchlechterSchuss { get; set; } = new List<int>();
        public List<int> ErsterSchlechterSchuss { get; set; } = new List<int>();
        public List<int> ErsterGuterSchuss { get; set; } = new List<int>();
        public List<bool> MeldungAktiv { get; set; } = new List<bool>();
        
        public SPS_Daten_DWORD_Dyn() { }
        
        public void Initialize(int count)
        {
            Signal = new List<string>(new string[count]);
            Istwert = new List<double>(new double[count]);
            Sollwert = new List<double>(new double[count]);
            Tol1P = new List<int>(new int[count]);
            Tol1N = new List<int>(new int[count]);
            Tol2P = new List<int>(new int[count]);
            Tol2N = new List<int>(new int[count]);
            DBNr = new List<int>(new int[count]);
            SignalNr = new List<int>(new int[count]);
            Stichproben = new List<int>(new int[count]);
            Aktiv = new List<bool>(new bool[count]);
            LetzteAbweichung = new List<double>(new double[count]);
            LetzteGuterSchuss = new List<int>(new int[count]);
            LetzterSchlechterSchuss = new List<int>(new int[count]);
            ErsterSchlechterSchuss = new List<int>(new int[count]);
            ErsterGuterSchuss = new List<int>(new int[count]);
            MeldungAktiv = new List<bool>(new bool[count]);
        }
    }
    
    /// <summary>
    /// SPS-Daten für BOOL-Werte (dynamisch)
    /// Äquivalent zu TSPS_Daten_Bool_Dyn in DBMain.pas
    /// </summary>
    public class SPS_Daten_Bool_Dyn
    {
        public string Maschine { get; set; } = string.Empty;
        public string Signal { get; set; } = string.Empty;
        public int LizenzInt { get; set; } = 0;
        public string Adresse { get; set; } = string.Empty;
        public int Format { get; set; } = 0;
        public List<bool> Istwert { get; set; } = new List<bool>();
        public List<bool> Istwert_alt { get; set; } = new List<bool>();
        public List<int> DBNr { get; set; } = new List<int>();
        public List<int> SignalNr { get; set; } = new List<int>();
        public List<string> Stillstand { get; set; } = new List<string>();
        
        public SPS_Daten_Bool_Dyn() { }
        
        public void Initialize(int count)
        {
            Istwert = new List<bool>(new bool[count]);
            Istwert_alt = new List<bool>(new bool[count]);
            DBNr = new List<int>(new int[count]);
            SignalNr = new List<int>(new int[count]);
            Stillstand = new List<string>(new string[count]);
        }
    }
    
    /// <summary>
    /// Signal-Maschinen-Eintrag
    /// Äquivalent zu TSignalMaschineItem in DBMain.pas
    /// </summary>
    public class SignalMaschineItem
    {
        public string Maschine { get; set; } = string.Empty;
        public int MaschNr { get; set; } = 0;
        public string Signal { get; set; } = string.Empty;
        public string SignalName { get; set; } = string.Empty;
        public int Signalart { get; set; } = 0;
        public string IstwertString { get; set; } = string.Empty;
        public int Istwert { get; set; } = 0;
        public int MaschNrOriginal { get; set; } = 0;
        public int SignalNr { get; set; } = 0;
        public int Nr { get; set; } = 0;
        
        public SignalMaschineItem() { }
        
        public SignalMaschineItem(string maschine, int maschNr, string signal, string signalName, 
                                  int signalart, string istwertString, int istwert, int maschNrOriginal, 
                                  int signalNr, int nr)
        {
            Maschine = maschine;
            MaschNr = maschNr;
            Signal = signal;
            SignalName = signalName;
            Signalart = signalart;
            IstwertString = istwertString;
            Istwert = istwert;
            MaschNrOriginal = maschNrOriginal;
            SignalNr = signalNr;
            Nr = nr;
        }
        
        /// <summary>
        /// Erstellt eine Kopie dieses Objekts
        /// Äquivalent zu CopyMe in Delphi
        /// </summary>
        public SignalMaschineItem Copy()
        {
            return new SignalMaschineItem
            {
                Maschine = Maschine,
                MaschNr = MaschNr,
                Signal = Signal,
                SignalName = SignalName,
                Signalart = Signalart,
                IstwertString = IstwertString,
                Istwert = Istwert,
                MaschNrOriginal = MaschNrOriginal,
                SignalNr = SignalNr,
                Nr = Nr
            };
        }
    }
    
    /// <summary>
    /// Liste von Signal-Maschinen-Einträgen
    /// Äquivalent zu TSignalMaschineList in DBMain.pas
    /// </summary>
    public class SignalMaschineList
    {
        private List<SignalMaschineItem> _items = new List<SignalMaschineItem>();
        
        public SignalMaschineItem this[int index]
        {
            get => GetItem(index);
            set => SetItem(index, value);
        }
        
        public int Count => _items.Count;
        
        /// <summary>
        /// Fügt einen neuen Eintrag hinzu
        /// Äquivalent zu Add in Delphi
        /// </summary>
        public int Add(SignalMaschineItem aSignalEintrag)
        {
            _items.Add(aSignalEintrag);
            return _items.Count - 1;
        }
        
        /// <summary>
        /// Gibt einen Eintrag nach Index zurück
        /// Äquivalent zu getItem in Delphi
        /// </summary>
        public SignalMaschineItem GetItem(int index)
        {
            if (index >= 0 && index < _items.Count)
                return _items[index];
            return null;
        }
        
        /// <summary>
        /// Setzt einen Eintrag nach Index
        /// Äquivalent zu setItem in Delphi
        /// </summary>
        public void SetItem(int index, SignalMaschineItem value)
        {
            if (index >= 0 && index < _items.Count)
                _items[index] = value;
        }
        
        /// <summary>
        /// Gibt Einträge nach Maschinen-Nummer zurück
        /// Äquivalent zu GetByMaschNr in Delphi
        /// </summary>
        public SignalMaschineList GetByMaschNr(int aMaschNr)
        {
            var result = new SignalMaschineList();
            foreach (var item in _items)
            {
                if (item.MaschNr == aMaschNr || item.MaschNrOriginal == aMaschNr)
                {
                    result.Add(item.Copy());
                }
            }
            return result;
        }
        
        /// <summary>
        /// Gibt einen Eintrag nach Maschinen-Nummer und Signalart zurück
        /// Äquivalent zu GetByMaschNrSignalart in Delphi
        /// </summary>
        public SignalMaschineItem GetByMaschNrSignalart(int aMaschNr, int aSignalart)
        {
            foreach (var item in _items)
            {
                if ((item.MaschNr == aMaschNr || item.MaschNrOriginal == aMaschNr) && 
                    item.Signalart == aSignalart)
                {
                    return item;
                }
            }
            return null;
        }
        
        /// <summary>
        /// Gibt einen Eintrag nach Nummer zurück
        /// Äquivalent zu GetNr in Delphi
        /// </summary>
        public SignalMaschineItem GetNr(int aNr)
        {
            foreach (var item in _items)
            {
                if (item.Nr == aNr)
                    return item;
            }
            return null;
        }
        
        /// <summary>
        /// Gibt den Istwert nach Nummer zurück
        /// Äquivalent zu GetIstwertByNr in Delphi
        /// </summary>
        public int GetIstwertByNr(int aNr)
        {
            var item = GetNr(aNr);
            return item != null ? item.Istwert : 0;
        }
        
        /// <summary>
        /// Gibt den Bool-Wert nach Nummer zurück
        /// Äquivalent zu GetBoolByNr in Delphi
        /// </summary>
        public bool GetBoolByNr(int aNr)
        {
            var item = GetNr(aNr);
            return item != null && item.Istwert != 0;
        }
        
        /// <summary>
        /// Löscht alle Einträge
        /// Äquivalent zu Clear in Delphi
        /// </summary>
        public void Clear()
        {
            _items.Clear();
        }
        
        /// <summary>
        /// Fügt mehrere Einträge hinzu
        /// </summary>
        public void AddRange(IEnumerable<SignalMaschineItem> items)
        {
            _items.AddRange(items);
        }
        
        /// <summary>
        /// Gibt alle Einträge zurück
        /// </summary>
        public List<SignalMaschineItem> GetAll()
        {
            return new List<SignalMaschineItem>(_items);
        }
    }
    
    /// <summary>
    /// Maschinen-Daten
    /// Äquivalent zu den Includis-Arrays in DBMain.pas
    /// </summary>
    public class MaschinenDaten
    {
        public int Nr { get; set; } = 0;
        public string Lizenz { get; set; } = string.Empty;
        public bool IstArchiviert { get; set; } = false;
        public string Name { get; set; } = string.Empty;
    }
    
    /// <summary>
    /// Hauptdaten für S7Main
    /// Enthält alle wichtigen Arrays und Variablen aus DBMain.pas
    /// </summary>
    public class S7MainData
    {
        // Maschinen-Anzahl
        public int AnzahlMasch { get; set; } = 0;
        
        // Maschinen-Liste
        public List<MaschinenDaten> Maschinen { get; set; } = new List<MaschinenDaten>();
        
        // SPS-Daten Arrays (fest definiert für Max_ANZAHL = 600)
        public const int Max_Anzahl = 600;
        public const int Max_Barcode = 13;
        
        // SPS-Werte Arrays
        public SPS_Daten_DWord[] StueckGesamt { get; set; } = new SPS_Daten_DWord[Max_Anzahl + 1];
        public SPS_Daten_DWord[] StueckAuftragGesamt { get; set; } = new SPS_Daten_DWord[Max_Anzahl + 1];
        public int[] StueckAuftragAlt { get; set; } = new int[Max_Anzahl + 1];
        public int[] Diff_Stueck { get; set; } = new int[Max_Anzahl + 1];
        public SPS_Daten_DWord[] StueckAuftragSchicht { get; set; } = new SPS_Daten_DWord[Max_Anzahl + 1];
        public SPS_Daten_DWord[] StueckSchicht { get; set; } = new SPS_Daten_DWord[Max_Anzahl + 1];
        
        public SPS_Daten_DWord[] Betriebsstunden { get; set; } = new SPS_Daten_DWord[Max_Anzahl + 1];
        public SPS_Daten_DWord[] Taktzeit { get; set; } = new SPS_Daten_DWord[Max_Anzahl + 1];
        public SPS_Daten_DWord[] LaufzeitGes { get; set; } = new SPS_Daten_DWord[Max_Anzahl + 1];
        public SPS_Daten_DWord[] LaufzeitSchicht { get; set; } = new SPS_Daten_DWord[Max_Anzahl + 1];
        
        public SPS_Daten_DWord[] StueckPruefGesamt { get; set; } = new SPS_Daten_DWord[Max_Anzahl + 1];
        public SPS_Daten_DWord[] StueckPruefAuftragGesamt { get; set; } = new SPS_Daten_DWord[Max_Anzahl + 1];
        public SPS_Daten_DWord[] StueckPruefAuftragSchicht { get; set; } = new SPS_Daten_DWord[Max_Anzahl + 1];
        public SPS_Daten_DWord[] StueckPruefSchicht { get; set; } = new SPS_Daten_DWord[Max_Anzahl + 1];
        
        public SPS_Daten_DWord[] StueckPackGesamt { get; set; } = new SPS_Daten_DWord[Max_Anzahl + 1];
        public SPS_Daten_DWord[] StueckPackAuftragGesamt { get; set; } = new SPS_Daten_DWord[Max_Anzahl + 1];
        public SPS_Daten_DWord[] StueckPackAuftragSchicht { get; set; } = new SPS_Daten_DWord[Max_Anzahl + 1];
        public SPS_Daten_DWord[] StueckPackSchicht { get; set; } = new SPS_Daten_DWord[Max_Anzahl + 1];
        
        public SPS_Daten_Word[] Terminal_AuftragNr { get; set; } = new SPS_Daten_Word[Max_Anzahl + 1];
        
        // SPC-Daten
        public SPS_Daten_DWORD_Dyn[] SPC_Signal { get; set; } = new SPS_Daten_DWORD_Dyn[Max_Anzahl + 1];
        public int[] Stich_Zaehler { get; set; } = new int[Max_Anzahl + 1];
        
        // Maschinen-Zustand
        public SPS_Daten_Word[] Maschinen_Zustand { get; set; } = new SPS_Daten_Word[Max_Anzahl + 1];
        public SPS_Daten_Word[] Terminal_Einheit { get; set; } = new SPS_Daten_Word[Max_Anzahl + 1];
        public SPS_Daten_Word[] Terminal_StoerKommtGeht { get; set; } = new SPS_Daten_Word[Max_Anzahl + 1];
        public SPS_Daten_Word[] Terminal_Stoer_Nr { get; set; } = new SPS_Daten_Word[Max_Anzahl + 1];
        public SPS_Daten_Word[] Terminal_Still_Stoer { get; set; } = new SPS_Daten_Word[Max_Anzahl + 1];
        public SPS_Daten_Word[] Terminal_Etikett { get; set; } = new SPS_Daten_Word[Max_Anzahl + 1];
        public SPS_Daten_Word[] Programm_Nr { get; set; } = new SPS_Daten_Word[Max_Anzahl + 1];
        public SPS_Daten_Word[] Terminal_AuftragNr_ASCII { get; set; } = new SPS_Daten_Word[Max_Anzahl + 1];
        
        // BCD und Stillstand
        public SPS_Daten_Byte[] BCD { get; set; } = new SPS_Daten_Byte[Max_Anzahl + 1];
        public SPS_Daten_DWord[] StillstandNr_SPS { get; set; } = new SPS_Daten_DWord[Max_Anzahl + 1];
        public SPS_Daten_DWord[] StillstandNr_SPS_Save { get; set; } = new SPS_Daten_DWord[Max_Anzahl + 1];
        public SPS_Daten_Byte[] Job_Stueckzahl { get; set; } = new SPS_Daten_Byte[Max_Anzahl + 1];
        
        // Bool-Arrays
        public SPS_Daten_Bool[] BCD_Read { get; set; } = new SPS_Daten_Bool[Max_Anzahl + 1];
        public SPS_Daten_Bool[] HandAuto { get; set; } = new SPS_Daten_Bool[Max_Anzahl + 1];
        public SPS_Daten_Bool[] MaschProgrammbetrieb { get; set; } = new SPS_Daten_Bool[Max_Anzahl + 1];
        public SPS_Daten_Bool[] Auftrag_Freigabe { get; set; } = new SPS_Daten_Bool[Max_Anzahl + 1];
        public SPS_Daten_Bool[] Programm_Start { get; set; } = new SPS_Daten_Bool[Max_Anzahl + 1];
        public SPS_Daten_Bool[] Programm_Ende { get; set; } = new SPS_Daten_Bool[Max_Anzahl + 1];
        public SPS_Daten_Bool[] Terminal_Menge_Gebucht { get; set; } = new SPS_Daten_Bool[Max_Anzahl + 1];
        public SPS_Daten_Bool[] Terminal_Stillstand_Gebucht { get; set; } = new SPS_Daten_Bool[Max_Anzahl + 1];
        public SPS_Daten_Bool[] Terminal_Auftrag_Beendet { get; set; } = new SPS_Daten_Bool[Max_Anzahl + 1];
        public SPS_Daten_Bool[] Terminal_Auftrag_Unterbrochen { get; set; } = new SPS_Daten_Bool[Max_Anzahl + 1];
        public SPS_Daten_Bool[] MaschWarmtrennen { get; set; } = new SPS_Daten_Bool[Max_Anzahl + 1];
        
        // Individuelle Stillstände
        public SPS_Daten_Bool_Dyn[] IndivStillstand { get; set; } = new SPS_Daten_Bool_Dyn[Max_Anzahl + 1];
        
        // Barcode-Daten
        public SPS_Daten_Bool Barcode_Gelesen { get; set; } = new SPS_Daten_Bool();
        public SPS_Daten_Bool Barcode_Gelesen_2 { get; set; } = new SPS_Daten_Bool();
        public SPS_Daten_Bool Barcode_Gelesen_3 { get; set; } = new SPS_Daten_Bool();
        public SPS_Daten_Word[] Barcode { get; set; } = new SPS_Daten_Word[Max_Barcode + 1];
        public SPS_Daten_Word[] Barcode_2 { get; set; } = new SPS_Daten_Word[Max_Barcode + 1];
        public SPS_Daten_Word[] Barcode_3 { get; set; } = new SPS_Daten_Word[Max_Barcode + 1];
        
        // Weitere Signale
        public SPS_Daten_Word Terminal_Maschine { get; set; } = new SPS_Daten_Word();
        public SPS_Daten_Word Reparatur_Start_Ende { get; set; } = new SPS_Daten_Word();
        public SPS_Daten_Byte AuftragStart1 { get; set; } = new SPS_Daten_Byte();
        public SPS_Daten_Byte AuftragStart2 { get; set; } = new SPS_Daten_Byte();
        public SPS_Daten_Byte AuftragStart3 { get; set; } = new SPS_Daten_Byte();
        public SPS_Daten_Bool Terminal_Eingabe { get; set; } = new SPS_Daten_Bool();
        
        // Signal-Maschinen-Liste
        public SignalMaschineList SignalMaschinen { get; set; } = new SignalMaschineList();
        
        public S7MainData()
        {
            // Initialisierung der Arrays
            for (int i = 0; i <= Max_Anzahl; i++)
            {
                StueckGesamt[i] = new SPS_Daten_DWord();
                StueckAuftragGesamt[i] = new SPS_Daten_DWord();
                StueckAuftragSchicht[i] = new SPS_Daten_DWord();
                StueckSchicht[i] = new SPS_Daten_DWord();
                Betriebsstunden[i] = new SPS_Daten_DWord();
                Taktzeit[i] = new SPS_Daten_DWord();
                LaufzeitGes[i] = new SPS_Daten_DWord();
                LaufzeitSchicht[i] = new SPS_Daten_DWord();
                StueckPruefGesamt[i] = new SPS_Daten_DWord();
                StueckPruefAuftragGesamt[i] = new SPS_Daten_DWord();
                StueckPruefAuftragSchicht[i] = new SPS_Daten_DWord();
                StueckPruefSchicht[i] = new SPS_Daten_DWord();
                StueckPackGesamt[i] = new SPS_Daten_DWord();
                StueckPackAuftragGesamt[i] = new SPS_Daten_DWord();
                StueckPackAuftragSchicht[i] = new SPS_Daten_DWord();
                StueckPackSchicht[i] = new SPS_Daten_DWord();
                Terminal_AuftragNr[i] = new SPS_Daten_Word();
                
                SPC_Signal[i] = new SPS_Daten_DWORD_Dyn();
                Maschinen_Zustand[i] = new SPS_Daten_Word();
                Terminal_Einheit[i] = new SPS_Daten_Word();
                Terminal_StoerKommtGeht[i] = new SPS_Daten_Word();
                Terminal_Stoer_Nr[i] = new SPS_Daten_Word();
                Terminal_Still_Stoer[i] = new SPS_Daten_Word();
                Terminal_Etikett[i] = new SPS_Daten_Word();
                Programm_Nr[i] = new SPS_Daten_Word();
                Terminal_AuftragNr_ASCII[i] = new SPS_Daten_Word();
                
                BCD[i] = new SPS_Daten_Byte();
                StillstandNr_SPS[i] = new SPS_Daten_DWord();
                StillstandNr_SPS_Save[i] = new SPS_Daten_DWord();
                Job_Stueckzahl[i] = new SPS_Daten_Byte();
                
                BCD_Read[i] = new SPS_Daten_Bool();
                HandAuto[i] = new SPS_Daten_Bool();
                MaschProgrammbetrieb[i] = new SPS_Daten_Bool();
                Auftrag_Freigabe[i] = new SPS_Daten_Bool();
                Programm_Start[i] = new SPS_Daten_Bool();
                Programm_Ende[i] = new SPS_Daten_Bool();
                Terminal_Menge_Gebucht[i] = new SPS_Daten_Bool();
                Terminal_Stillstand_Gebucht[i] = new SPS_Daten_Bool();
                Terminal_Auftrag_Beendet[i] = new SPS_Daten_Bool();
                Terminal_Auftrag_Unterbrochen[i] = new SPS_Daten_Bool();
                MaschWarmtrennen[i] = new SPS_Daten_Bool();
                
                IndivStillstand[i] = new SPS_Daten_Bool_Dyn();
            }
            
            for (int i = 0; i <= Max_Barcode; i++)
            {
                Barcode[i] = new SPS_Daten_Word();
                Barcode_2[i] = new SPS_Daten_Word();
                Barcode_3[i] = new SPS_Daten_Word();
            }
        }
    }
}
