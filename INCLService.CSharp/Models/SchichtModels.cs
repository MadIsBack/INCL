using System;
using System.Collections.Generic;
using System.Linq;

namespace INCLService.CSharp.Models
{
    /// <summary>
    /// Stillstand-Eintrag
    /// Äquivalent zu TStillstandEintrag in SchichtUtilLib.pas
    /// </summary>
    public class StillstandEintrag
    {
        public int Nr { get; set; } = 0;
        public DateTime Kommt { get; set; } = DateTime.MinValue;
        public DateTime Geht { get; set; } = DateTime.MinValue;
        public int GrundNr { get; set; } = 0;
        public bool Geplant { get; set; } = false;
        public int Maschnr { get; set; } = 0;
        public int Gruppe { get; set; } = 0; // 0 -> Anlagenausfall, 1 -> Rüsten, 2 -> Logistik, 3 -> ungebucht
        public string Stillstand { get; set; } = string.Empty;
        
        /// <summary>
        /// Erstellt eine Kopie dieses Objekts
        /// Äquivalent zu CopyMe in Delphi
        /// </summary>
        public StillstandEintrag CopyMe()
        {
            return new StillstandEintrag
            {
                Nr = this.Nr,
                Kommt = this.Kommt,
                Geht = this.Geht,
                GrundNr = this.GrundNr,
                Geplant = this.Geplant,
                Maschnr = this.Maschnr,
                Gruppe = this.Gruppe,
                Stillstand = this.Stillstand
            };
        }
    }

    /// <summary>
    /// Liste von Stillstand-Einträgen
    /// Äquivalent zu TStillstandEintragsListe in SchichtUtilLib.pas
    /// </summary>
    public class StillstandEintragsListe : List<StillstandEintrag>
    {
        /// <summary>
        /// Gibt eine Zeichenkette mit allen Maschinen-Nummern zurück
        /// Äquivalent zu getMaschNrsString in Delphi
        /// </summary>
        public string GetMaschNrsString()
        {
            var distinctMaschNrs = this.Select(s => s.Maschnr).Distinct().OrderBy(m => m);
            return string.Join(",", distinctMaschNrs);
        }
        
        /// <summary>
        /// Filtert die Liste nach Maschinen-Nummer
        /// Äquivalent zu GetByMaschNr in Delphi
        /// </summary>
        public StillstandEintragsListe GetByMaschNr(int maschNr)
        {
            var result = new StillstandEintragsListe();
            foreach (var item in this.Where(s => s.Maschnr == maschNr))
            {
                result.Add(item.CopyMe());
            }
            return result;
        }
        
        /// <summary>
        /// Fügt einen Eintrag hinzu (mit Duplikatsprüfung)
        /// Äquivalent zu Add in Delphi
        /// </summary>
        public new int Add(StillstandEintrag entry)
        {
            // Prüfen, ob bereits ein Eintrag mit dieser Nr existiert
            for (int i = 0; i < this.Count; i++)
            {
                if (this[i].Nr == entry.Nr)
                {
                    return i; // Bereits vorhanden
                }
            }
            
            base.Add(entry);
            return this.Count - 1;
        }
        
        /// <summary>
        /// Fügt einen Eintrag ohne Duplikatsprüfung hinzu
        /// Äquivalent zu AddRaw in Delphi
        /// </summary>
        public int AddRaw(StillstandEintrag entry)
        {
            base.Add(entry);
            return this.Count - 1;
        }
        
        /// <summary>
        /// Berechnet die Gesamtdauer der Stillstände für eine bestimmte Maschine
        /// Äquivalent zu GetDauerByMaschNr in Delphi
        /// </summary>
        public int GetDauerByMaschNr(int maschNr)
        {
            double dauer = 0;
            
            foreach (var item in this.Where(s => s.Maschnr == maschNr))
            {
                DateTime stillende = item.Geht;
                if (stillende < DateTime.MinValue.AddDays(1)) // Geht < 1
                {
                    stillende = DateTime.Now;
                }
                
                if (item.Kommt < stillende)
                {
                    // Dauer in Minuten berechnen (1440 Minuten pro Tag)
                    dauer += (stillende - item.Kommt).TotalMinutes;
                }
            }
            
            return (int)Math.Round(dauer);
        }
        
        /// <summary>
        /// Berechnet die Dauer der Stillstände für eine bestimmte Maschine ab einem bestimmten Datum
        /// Äquivalent zu GetDauerByMaschNrFromDate in Delphi
        /// </summary>
        public int GetDauerByMaschNrFromDate(DateTime fromDate, int maschNr)
        {
            double dauer = 0;
            
            foreach (var item in this.Where(s => s.Maschnr == maschNr))
            {
                DateTime stillgeht = item.Geht;
                DateTime stillkommt = item.Kommt;
                
                if (stillgeht < DateTime.MinValue.AddDays(1)) // Geht < 1
                {
                    stillgeht = DateTime.Now;
                }
                
                if (stillkommt < fromDate)
                {
                    stillkommt = fromDate;
                }
                
                if (stillkommt > stillgeht)
                {
                    stillkommt = stillgeht;
                }
                
                if (stillkommt < stillgeht)
                {
                    dauer += (stillgeht - stillkommt).TotalMinutes;
                }
            }
            
            return (int)Math.Round(dauer);
        }
        
        /// <summary>
        /// Gibt den offenen Stillstand für eine bestimmte Maschine zurück
        /// Äquivalent zu GetOpenByMaschNr in Delphi
        /// </summary>
        public StillstandEintrag GetOpenByMaschNr(int maschNr)
        {
            foreach (var item in this.Where(s => s.Maschnr == maschNr))
            {
                if (item.Geht < DateTime.MinValue.AddDays(1)) // Geht < 1
                {
                    return item;
                }
            }
            return null;
        }
        
        /// <summary>
        /// Löscht alle Einträge und gibt den Speicher frei
        /// Äquivalent zu Clear in Delphi
        /// </summary>
        public new void Clear()
        {
            base.Clear();
        }
    }

    /// <summary>
    /// Start-Stop-Eintrag
    /// Äquivalent zu TStartStopEintrag in SchichtUtilLib.pas
    /// </summary>
    public class StartStopEintrag
    {
        public string AuftragNr { get; set; } = string.Empty;
        public DateTime RuestStart { get; set; } = DateTime.MinValue;
        public DateTime Start { get; set; } = DateTime.MinValue;
        public DateTime Stop { get; set; } = DateTime.MinValue;
        
        /// <summary>
        /// Erstellt eine Kopie dieses Objekts
        /// Äquivalent zu CopyMe in Delphi
        /// </summary>
        public StartStopEintrag CopyMe()
        {
            return new StartStopEintrag
            {
                AuftragNr = this.AuftragNr,
                RuestStart = this.RuestStart,
                Start = this.Start,
                Stop = this.Stop
            };
        }
    }

    /// <summary>
    /// Liste von Start-Stop-Einträgen
    /// Äquivalent zu TStartStopEintragsListe in SchichtUtilLib.pas
    /// </summary>
    public class StartStopEintragsListe : List<StartStopEintrag>
    {
        /// <summary>
        /// Filtert die Liste nach Betriebsauftrags-Nummer
        /// Äquivalent zu GetByBetriebsauftragNr in Delphi
        /// </summary>
        public StartStopEintragsListe GetByBetriebsauftragNr(string baNr)
        {
            var result = new StartStopEintragsListe();
            foreach (var item in this.Where(s => s.AuftragNr == baNr))
            {
                result.Add(item.CopyMe());
            }
            return result;
        }
        
        /// <summary>
        /// Fügt einen Eintrag hinzu
        /// Äquivalent zu Add in Delphi
        /// </summary>
        public new int Add(StartStopEintrag entry)
        {
            base.Add(entry);
            return this.Count - 1;
        }
        
        /// <summary>
        /// Löscht alle Einträge
        /// Äquivalent zu Clear in Delphi
        /// </summary>
        public new void Clear()
        {
            base.Clear();
        }
    }

    /// <summary>
    /// Signal-Log-Eintrag
    /// Äquivalent zu TSignalLogEintrag in SchichtUtilLib.pas
    /// </summary>
    public class SignalLogEintrag
    {
        public int Maschnr { get; set; } = 0;
        public int Wert { get; set; } = 0;
        public DateTime Start { get; set; } = DateTime.MinValue;
        public DateTime Stop { get; set; } = DateTime.MinValue;
        
        /// <summary>
        /// Erstellt eine Kopie dieses Objekts
        /// Äquivalent zu CopyMe in Delphi
        /// </summary>
        public SignalLogEintrag CopyMe()
        {
            return new SignalLogEintrag
            {
                Maschnr = this.Maschnr,
                Wert = this.Wert,
                Start = this.Start,
                Stop = this.Stop
            };
        }
    }

    /// <summary>
    /// Liste von Signal-Log-Einträgen
    /// Äquivalent zu TSignalLogEintragListe in SchichtUtilLib.pas
    /// </summary>
    public class SignalLogEintragListe : List<SignalLogEintrag>
    {
        /// <summary>
        /// Filtert die Liste nach Maschinen-Nummer
        /// Äquivalent zu GetByMaschNr in Delphi
        /// </summary>
        public SignalLogEintragListe GetByMaschNr(int maschNr)
        {
            var result = new SignalLogEintragListe();
            foreach (var item in this.Where(s => s.Maschnr == maschNr))
            {
                result.Add(item.CopyMe());
            }
            return result;
        }
        
        /// <summary>
        /// Fügt einen Eintrag hinzu
        /// Äquivalent zu Add in Delphi
        /// </summary>
        public new int Add(SignalLogEintrag entry)
        {
            base.Add(entry);
            return this.Count - 1;
        }
        
        /// <summary>
        /// Löscht alle Einträge
        /// Äquivalent zu Clear in Delphi
        /// </summary>
        public new void Clear()
        {
            base.Clear();
        }
    }
}
