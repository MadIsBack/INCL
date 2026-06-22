using System;
using System.Collections.Generic;

namespace INCLService_CSharp
{
    public class TSPCMaschine : IDisposable
    {
        public int MaschNr { get; set; } = 0;
        public string Lizenz { get; set; } = "";
        public TSPCSchussList SchussList { get; set; }

        public TSPCMaschine()
        {
            SchussList = new TSPCSchussList();
        }

        public bool IsOKFirst()
        {
            if (SchussList.Count > 0)
                return SchussList[0].IsOK;
            return false;
        }

        public bool IsOKLast()
        {
            if (SchussList.Count > 0)
                return SchussList[SchussList.Count - 1].IsOK;
            return false;
        }

        public List<string> GetErrorList()
        {
            List<string> result = new List<string>();
            for (int i = 0; i < SchussList.Count; i++)
            {
                if (!SchussList[i].IsOK)
                {
                    result.Add(SchussList[i].Nr.ToString());
                }
            }
            return result.Count > 0 ? result : null;
        }

        public void Clear()
        {
            Lizenz = "";
            MaschNr = 0;
            SchussList.ClearList();
        }

        public void Dispose()
        {
            if (SchussList != null)
            {
                SchussList.Dispose();
                SchussList = null;
            }
        }

        ~TSPCMaschine()
        {
            Dispose();
        }
    }

    public class TSPCSchuss : IDisposable
    {
        public int Nr { get; set; } = 0;
        public int Schuss { get; set; } = 0;
        public TSPCValueList ValueList { get; set; }

        public TSPCSchuss()
        {
            ValueList = new TSPCValueList();
        }

        public bool IsOK()
        {
            bool result = true;
            for (int i = 0; i < ValueList.Count; i++)
            {
                result = result && ValueList[i].OK();
            }
            return result;
        }

        public void Dispose()
        {
            if (ValueList != null)
            {
                ValueList.Dispose();
                ValueList = null;
            }
        }

        ~TSPCSchuss()
        {
            Dispose();
        }
    }

    public class TSPCSchussList : List<TSPCSchuss>, IDisposable
    {
        public new TSPCSchuss this[int index]
        {
            get => base[index];
            set => base[index] = value;
        }

        public int Add(TSPCSchuss aSchuss)
        {
            base.Add(aSchuss);
            return base.Count - 1;
        }

        public TSPCSchuss GetByNr(int aNr)
        {
            for (int i = 0; i < base.Count; i++)
            {
                if (base[i].Nr == aNr)
                    return base[i];
            }
            return null;
        }

        public void ClearList()
        {
            for (int i = 0; i < base.Count; i++)
            {
                base[i].ValueList.ClearList();
            }
            base.Clear();
        }

        public void Dispose()
        {
            ClearList();
        }

        ~TSPCSchussList()
        {
            Dispose();
        }
    }

    public class TSPCValue : IDisposable
    {
        private int FNr = 0;
        private string FName = "";
        private double FSoll = 0.0;
        private double FIst = 0.0;
        private double FMax = 0.0;
        private double FMin = 0.0;

        public int Nr { get => FNr; set => FNr = value; }
        public string Name { get => FName; set => FName = value; }
        public double Soll { get => FSoll; set => FSoll = value; }
        public double Ist { get => FIst; set => FIst = value; }

        public double MaxInPct
        {
            get => ((FMax / FSoll) - 1) * 100;
            set => FMax = FSoll * (1 + (value / 100));
        }

        public double MinInPct
        {
            get => (1 - (FMin / FSoll)) * 100;
            set => FMin = FSoll * (1 - (value / 100));
        }

        public double MaxValue { get => FMax; set => FMax = value; }
        public double MinValue { get => FMin; set => FMin = value; }

        public bool OK()
        {
            return (FIst > FMin) && (FIst <= FMax);
        }

        public void Dispose()
        {
            // Nothing to dispose
        }

        ~TSPCValue()
        {
            Dispose();
        }
    }

    public class TSPCValueList : List<TSPCValue>, IDisposable
    {
        public new TSPCValue this[int index]
        {
            get => base[index];
            set => base[index] = value;
        }

        public int Add(TSPCValue aValue)
        {
            base.Add(aValue);
            return base.Count - 1;
        }

        public TSPCValue GetByNr(int aNr)
        {
            for (int i = 0; i < base.Count; i++)
            {
                if (base[i].Nr == aNr)
                    return base[i];
            }
            return null;
        }

        public void ClearList()
        {
            base.Clear();
        }

        public void Dispose()
        {
            ClearList();
        }

        ~TSPCValueList()
        {
            Dispose();
        }
    }
}
