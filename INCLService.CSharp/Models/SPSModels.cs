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
}
