using System;
using System.Collections.Generic;

namespace INCLService_CSharp
{
    public class TStillstandEintrag
    {
        public int Nr { get; set; } = 0;
        public DateTime Kommt { get; set; } = DateTime.MinValue;
        public DateTime Geht { get; set; } = DateTime.MinValue;
        public int GrundNr { get; set; } = 0;
        public bool Geplant { get; set; } = false;
        public int Maschnr { get; set; } = 0;
        public int Gruppe { get; set; } = 0; // 0 -> Anlagenausfall, 1 -> Rüsten 2 -> Logistik 3 -> ungebucht
        public string Stillstand { get; set; } = "";

        public TStillstandEintrag CopyMe()
        {
            return new TStillstandEintrag
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

    public class TStillstandEintragsListe : List<TStillstandEintrag>
    {
        public new TStillstandEintrag this[int index]
        {
            get => base[index];
            set => base[index] = value;
        }

        public int Add(TStillstandEintrag aStillstandEintrag)
        {
            bool found = false;
            for (int i = 0; i < base.Count; i++)
            {
                if (base[i].Nr == aStillstandEintrag.Nr)
                {
                    found = true;
                    base[i] = aStillstandEintrag;
                    break;
                }
            }
            
            if (!found)
            {
                base.Add(aStillstandEintrag);
            }
            
            return base.Count - 1;
        }

        public int AddRaw(TStillstandEintrag aStillstandEintrag)
        {
            base.Add(aStillstandEintrag);
            return base.Count - 1;
        }

        public string getMaschNrsString()
        {
            System.Text.StringBuilder sb = new System.Text.StringBuilder();
            for (int i = 0; i < base.Count; i++)
            {
                if (i > 0) sb.Append(",");
                sb.Append(base[i].Maschnr);
            }
            return sb.ToString();
        }

        public TStillstandEintragsListe GetByMaschNr(int aMaschNr)
        {
            TStillstandEintragsListe result = new TStillstandEintragsListe();
            for (int i = 0; i < base.Count; i++)
            {
                if (base[i].Maschnr == aMaschNr)
                {
                    result.Add(base[i]);
                }
            }
            return result;
        }

        public int GetDauerByMaschNr(int aMaschNr)
        {
            int dauer = 0;
            for (int i = 0; i < base.Count; i++)
            {
                if (base[i].Maschnr == aMaschNr)
                {
                    TimeSpan span = base[i].Geht - base[i].Kommt;
                    dauer += (int)span.TotalMinutes;
                }
            }
            return dauer;
        }

        public int GetDauerByMaschNrFromDate(DateTime aFromDate, int aMaschNr)
        {
            int dauer = 0;
            for (int i = 0; i < base.Count; i++)
            {
                if (base[i].Maschnr == aMaschNr && base[i].Kommt >= aFromDate)
                {
                    TimeSpan span = base[i].Geht - base[i].Kommt;
                    dauer += (int)span.TotalMinutes;
                }
            }
            return dauer;
        }

        public TStillstandEintrag GetOpenByMaschNr(int aMaschNr)
        {
            for (int i = 0; i < base.Count; i++)
            {
                if (base[i].Maschnr == aMaschNr && base[i].Geht == DateTime.MinValue)
                {
                    return base[i];
                }
            }
            return null;
        }

        public new void Clear()
        {
            base.Clear();
        }
    }

    public class TStartStopEintrag
    {
        public string AuftragNr { get; set; } = "";
        public DateTime RuestStart { get; set; } = DateTime.MinValue;
        public DateTime Start { get; set; } = DateTime.MinValue;
        public DateTime Stop { get; set; } = DateTime.MinValue;

        private TStartStopEintrag CopyMe()
        {
            return new TStartStopEintrag
            {
                AuftragNr = this.AuftragNr,
                RuestStart = this.RuestStart,
                Start = this.Start,
                Stop = this.Stop
            };
        }
    }

    public class TStartStopEintragsListe : List<TStartStopEintrag>
    {
        public new TStartStopEintrag this[int index]
        {
            get => base[index];
            set => base[index] = value;
        }

        public int Add(TStartStopEintrag aStartStopEintrag)
        {
            base.Add(aStartStopEintrag);
            return base.Count - 1;
        }

        public TStartStopEintragsListe GetByBetriebsauftragNr(string aBANr)
        {
            TStartStopEintragsListe result = new TStartStopEintragsListe();
            for (int i = 0; i < base.Count; i++)
            {
                if (base[i].AuftragNr == aBANr)
                {
                    result.Add(base[i]);
                }
            }
            return result;
        }

        public new void Clear()
        {
            base.Clear();
        }
    }

    public class TSignalLogEintrag
    {
        public int maschnr { get; set; } = 0;
        public int wert { get; set; } = 0;
        public DateTime Start { get; set; } = DateTime.MinValue;
        public DateTime Stop { get; set; } = DateTime.MinValue;

        public TSignalLogEintrag CopyMe()
        {
            return new TSignalLogEintrag
            {
                maschnr = this.maschnr,
                wert = this.wert,
                Start = this.Start,
                Stop = this.Stop
            };
        }
    }

    public class TSignalLogEintragListe : List<TSignalLogEintrag>
    {
        public new TSignalLogEintrag this[int index]
        {
            get => base[index];
            set => base[index] = value;
        }

        public int Add(TSignalLogEintrag aSignalLogEintrag)
        {
            base.Add(aSignalLogEintrag);
            return base.Count - 1;
        }

        public TSignalLogEintragListe GetByMaschNr(int aMaschNr)
        {
            TSignalLogEintragListe result = new TSignalLogEintragListe();
            for (int i = 0; i < base.Count; i++)
            {
                if (base[i].maschnr == aMaschNr)
                {
                    result.Add(base[i]);
                }
            }
            return result;
        }

        public new void Clear()
        {
            base.Clear();
        }
    }
}
