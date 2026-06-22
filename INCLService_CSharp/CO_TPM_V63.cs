// <summary>
// CO_TPM_V63.cs - C# translation of CO_TPM_V63.pas
// Total Productive Maintenance classes
// </summary>

using System;
using System.Collections.Generic;

namespace INCLService_CSharp
{
    /// <summary>
    /// Time period constants
    /// </summary>
    public enum TPM_Zeitraum
    {
        azSchicht = 0,
        azFrei = 1
    }

    /// <summary>
    /// Log period constants
    /// </summary>
    public enum TPM_LogPeriod
    {
        lgSchicht = 0,
        lgTag = 1,
        lgWoche = 2,
        lgMonat = 3
    }

    /// <summary>
    /// Downtime type constants
    /// </summary>
    public enum TPM_DowntimeType
    {
        CANLAGENAUSFALL = 0,
        CRUESTEN = 1,
        CLOGISTIK = 2,
        CNICHT_GEBUCHT = 3
    }

    /// <summary>
    /// System downtime numbers (System_ID)
    /// </summary>
    public static class TPM_Constants
    {
        public const int CSTILLNRNICHTGEBUCHT = 1;
        public const int CSTILLNRRUESTENGEPLANT = 2;
        public const int CSTILLNRARBEITSFREI = 3;
        public const int CSTILLNRVORRICHTUNG = 4;
        public const int CSTILLNRKURZSTOERUNG = 5;
        public const int CSTILLNRMASCHINEBLOCK = 6;
        public const int CSTILLNRPAUSE = 7;
        public const int CSTILLNRRUESTENWZ = 8;
        public const int CSTILLNRMASCHINENICHTVORHANDEN = 9;
        public const int CSTILLNRRUESTENUNGEPLANT = 10;

        public const int CUNGEPLANT = 0;
        public const int CGEPLANT = 1;
    }

    /// <summary>
    /// Downtime record
    /// </summary>
    public class TStillstand
    {
        public int Stillstandnr { get; set; } = 0;
        public string Bezeichnung { get; set; } = string.Empty;
        public int Aktion { get; set; } = 0;
        public int Gruppe { get; set; } = 0;
        public bool Geplant { get; set; } = false;
    }

    /// <summary>
    /// Error event delegate
    /// </summary>
    public delegate void TErrorEvent(object Sender, string Msg, ref bool Handled);

    /// <summary>
    /// Get language string function
    /// </summary>
    public delegate string FuncGetL(string T);

    /// <summary>
    /// Comtas error exception
    /// </summary>
    public class ComtasError : Exception
    {
        public ComtasError() : base() { }
        public ComtasError(string message) : base(message) { }
        public ComtasError(string message, Exception inner) : base(message, inner) { }
    }

    /// <summary>
    /// CO_TPM class - Total Productive Maintenance
    /// </summary>
    public class TCO_TPM : IDisposable
    {
        private CO_Database fOraSession = null;
        private DateTime FVonDatum = DateTime.MinValue;
        private DateTime FBisDatum = DateTime.MinValue;
        private int FMaschNr = 0;
        private bool FAlleMaschinen = false;
        private int FZeitraum = 0; // Zeitraum für Zeile in Tabelle
        private int FSchicht = 0;
        private int fSchichtMinuten = 0;
        private string FShift_Typ = string.Empty;
        private int FListGroup = 0;

        private double FNutzung = 0;
        private double FLeistung = 0;
        private double FQualitaet = 0;
        private double FEffektivitaet = 0;
        private int FAnlagenausfall = 0;
        private int FRuesten = 0;
        private int FLogistik = 0;
        private int FNichtGebucht = 0;
        private int FGeplant = 0;
        private int FUngeplant = 0;
        private int FStops = 0;
        private int FSollLaufzeit = 0;
        private int FIstLaufzeit = 0;
        private int FIstStillstand = 0;
        private int FProduziert = 0;

        private CO_Query FQuery = null;
        private CO_Query qSuch = null, qSuch2 = null, qUpdate = null;
        private List<TStillstand> Stillstand = new List<TStillstand>();
        private int Shift_Model = 0;
        private bool FAutoausschuss = false;

        private object fOwner = null;

        /// <summary>
        /// Constructor
        /// </summary>
        public TCO_TPM(object owner)
        {
            fOwner = owner;
            FQuery = new CO_Query(owner);
            qSuch = new CO_Query(owner);
            qSuch2 = new CO_Query(owner);
            qUpdate = new CO_Query(owner);
        }

        /// <summary>
        /// Set database
        /// </summary>
        public void SetDatabase(CO_Database S)
        {
            fOraSession = S;
            FQuery.Database = S;
            qSuch.Database = S;
            qSuch2.Database = S;
            qUpdate.Database = S;
        }

        /// <summary>
        /// Set time period
        /// </summary>
        public void SetZeitraum(int Z)
        {
            FZeitraum = Z;
        }

        /// <summary>
        /// Set from date
        /// </summary>
        public void SetVonDatum(DateTime D)
        {
            FVonDatum = D;
        }

        /// <summary>
        /// Set to date
        /// </summary>
        public void SetBisDatum(DateTime D)
        {
            FBisDatum = D;
        }

        /// <summary>
        /// Set machine number
        /// </summary>
        public void SetMaschNr(int I)
        {
            FMaschNr = I;
        }

        /// <summary>
        /// Get downtime index
        /// </summary>
        public int GetStillIndex(int Stillstandnr)
        {
            for (int i = 0; i < Stillstand.Count; i++)
            {
                if (Stillstand[i].Stillstandnr == Stillstandnr)
                    return i;
            }
            return -1;
        }

        /// <summary>
        /// Load downtime data
        /// </summary>
        public void LoadStillstand(CO_Query query)
        {
            try
            {
                Stillstand.Clear();
                string sql = "SELECT * FROM TPM_Stillstaende ORDER BY Stillstandnr";
                SQL_fuc.SQL_Get(query, sql);
                
                while (!query.EOF)
                {
                    TStillstand stillstand = new TStillstand();
                    stillstand.Stillstandnr = query.FieldByName("Stillstandnr").AsInteger;
                    stillstand.Bezeichnung = query.FieldByName("Bezeichnung").AsString;
                    stillstand.Aktion = query.FieldByName("Aktion").AsInteger;
                    stillstand.Gruppe = query.FieldByName("Gruppe").AsInteger;
                    stillstand.Geplant = query.FieldByName("Geplant").AsInteger == 1;
                    Stillstand.Add(stillstand);
                    query.Next();
                }
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in LoadStillstand: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Calculate TPM values
        /// </summary>
        public void CalculateTPM()
        {
            try
            {
                // Implementation would calculate TPM values
                // This is a placeholder for the actual implementation
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in CalculateTPM: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Get utilization
        /// </summary>
        public double Nutzung { get { return FNutzung; } }

        /// <summary>
        /// Get performance
        /// </summary>
        public double Leistung { get { return FLeistung; } }

        /// <summary>
        /// Get quality
        /// </summary>
        public double Qualitaet { get { return FQualitaet; } }

        /// <summary>
        /// Get effectiveness (OEE)
        /// </summary>
        public double Effektivitaet { get { return FEffektivitaet; } }

        /// <summary>
        /// Get system failure time
        /// </summary>
        public int Anlagausfall { get { return FAnlagenausfall; } }

        /// <summary>
        /// Get setup time
        /// </summary>
        public int Ruesten { get { return FRuesten; } }

        /// <summary>
        /// Get logistics time
        /// </summary>
        public int Logistik { get { return FLogistik; } }

        /// <summary>
        /// Get unbooked time
        /// </summary>
        public int NichtGebucht { get { return FNichtGebucht; } }

        /// <summary>
        /// Get planned time
        /// </summary>
        public int Geplant { get { return FGeplant; } }

        /// <summary>
        /// Get unplanned time
        /// </summary>
        public int Ungeplant { get { return FUngeplant; } }

        /// <summary>
        /// Get stops count
        /// </summary>
        public int Stops { get { return FStops; } }

        /// <summary>
        /// Get target runtime
        /// </summary>
        public int SollLaufzeit { get { return FSollLaufzeit; } }

        /// <summary>
        /// Get actual runtime
        /// </summary>
        public int IstLaufzeit { get { return FIstLaufzeit; } }

        /// <summary>
        /// Get actual downtime
        /// </summary>
        public int IstStillstand { get { return FIstStillstand; } }

        /// <summary>
        /// Get produced count
        /// </summary>
        public int Produziert { get { return FProduziert; } }

        /// <summary>
        /// Dispose method
        /// </summary>
        public void Dispose()
        {
            try
            {
                if (FQuery != null)
                {
                    FQuery.Close();
                    FQuery = null;
                }
                if (qSuch != null)
                {
                    qSuch.Close();
                    qSuch = null;
                }
                if (qSuch2 != null)
                {
                    qSuch2.Close();
                    qSuch2 = null;
                }
                if (qUpdate != null)
                {
                    qUpdate.Close();
                    qUpdate = null;
                }
            }
            catch (Exception ex)
            {
                MainDLL.SchreibeMeldung("Error in TCO_TPM.Dispose: " + ex.Message, 0);
            }
        }

        /// <summary>
        /// Destructor
        /// </summary>
        ~TCO_TPM()
        {
            Dispose();
        }
    }
}
