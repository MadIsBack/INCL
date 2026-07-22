using System;
using System.Threading;
using System.Threading.Tasks;

namespace INCLService.CSharp.Utilities
{
    /// <summary>
    /// Event-System für Kommunikation zwischen Services
    /// Ersetzt die Delphi-Events (Event_Schicht, Event_SignalLog, Event_Zusatz, etc.)
    /// </summary>
    public class ServiceEventSystem : IDisposable
    {
        private readonly ManualResetEventSlim _shiftEvent = new ManualResetEventSlim(false);
        private readonly ManualResetEventSlim _signalLogEvent = new ManualResetEventSlim(false);
        private readonly ManualResetEventSlim _additionalEvent = new ManualResetEventSlim(false);
        private readonly ManualResetEventSlim _dbBackupEvent = new ManualResetEventSlim(false);
        
        // Event-Namen (wie in Delphi)
        public const string EVENT_SCHICHT = "Event_Schicht";
        public const string EVENT_SIGNALLLOG = "Event_SignalLog";
        public const string EVENT_ZUSATZ = "Event_Zusatz";
        public const string EVENT_DBBACKUP = "Event_DBBackup";
        
        /// <summary>
        /// Wartet auf ein bestimmtes Event
        /// Äquivalent zu WaitForSingleObject in Delphi
        /// </summary>
        public async Task WaitForEventAsync(string eventName, CancellationToken stoppingToken)
        {
            var eventSlim = GetEvent(eventName);
            if (eventSlim != null)
            {
                eventSlim.Reset(); // Zurücksetzen, falls bereits gesetzt
                await Task.Run(() => eventSlim.Wait(stoppingToken), stoppingToken);
            }
        }
        
        /// <summary>
        /// Wartet auf ein bestimmtes Event mit Timeout
        /// </summary>
        public bool WaitForEvent(string eventName, int timeoutMilliseconds, CancellationToken stoppingToken)
        {
            var eventSlim = GetEvent(eventName);
            if (eventSlim != null)
            {
                eventSlim.Reset();
                return eventSlim.Wait(timeoutMilliseconds, stoppingToken);
            }
            return false;
        }
        
        /// <summary>
        /// Setzt ein Event
        /// Äquivalent zu SetEvent in Delphi
        /// </summary>
        public void SetEvent(string eventName)
        {
            var eventSlim = GetEvent(eventName);
            eventSlim?.Set();
        }
        
        /// <summary>
        /// Setzt ein Event und benachrichtigt alle Wartenden
        /// </summary>
        public void PulseEvent(string eventName)
        {
            var eventSlim = GetEvent(eventName);
            if (eventSlim != null)
            {
                eventSlim.Set();
                // Sofort zurücksetzen, damit das nächste Wait blockiert
                eventSlim.Reset();
            }
        }
        
        /// <summary>
        /// Gibt das ManualResetEventSlim für einen Event-Namen zurück
        /// </summary>
        private ManualResetEventSlim GetEvent(string eventName)
        {
            return eventName switch
            {
                EVENT_SCHICHT => _shiftEvent,
                EVENT_SIGNALLLOG => _signalLogEvent,
                EVENT_ZUSATZ => _additionalEvent,
                EVENT_DBBACKUP => _dbBackupEvent,
                _ => null
            };
        }
        
        /// <summary>
        /// Setzt alle Events zurück
        /// </summary>
        public void ResetAllEvents()
        {
            _shiftEvent.Reset();
            _signalLogEvent.Reset();
            _additionalEvent.Reset();
            _dbBackupEvent.Reset();
        }
        
        /// <summary>
        /// Setzt alle Events
        /// </summary>
        public void SetAllEvents()
        {
            _shiftEvent.Set();
            _signalLogEvent.Set();
            _additionalEvent.Set();
            _dbBackupEvent.Set();
        }
        
        public void Dispose()
        {
            _shiftEvent.Dispose();
            _signalLogEvent.Dispose();
            _additionalEvent.Dispose();
            _dbBackupEvent.Dispose();
        }
    }
    
    /// <summary>
    /// Singleton-Instanz des Event-Systems
    /// </summary>
    public static class ServiceEvents
    {
        private static ServiceEventSystem _instance;
        private static readonly object _lock = new object();
        
        public static ServiceEventSystem Instance
        {
            get
            {
                lock (_lock)
                {
                    if (_instance == null)
                    {
                        _instance = new ServiceEventSystem();
                    }
                    return _instance;
                }
            }
        }
        
        public static void SetEvent(string eventName)
        {
            Instance.SetEvent(eventName);
        }
        
        public static void PulseEvent(string eventName)
        {
            Instance.PulseEvent(eventName);
        }
        
        public static async Task WaitForEventAsync(string eventName, CancellationToken stoppingToken)
        {
            await Instance.WaitForEventAsync(eventName, stoppingToken);
        }
        
        public static bool WaitForEvent(string eventName, int timeoutMilliseconds, CancellationToken stoppingToken)
        {
            return Instance.WaitForEvent(eventName, timeoutMilliseconds, stoppingToken);
        }
    }
}
