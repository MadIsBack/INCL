using System;
using System.Diagnostics;

namespace INCLUDIS.Utils.Log
{
    /// <summary>
    /// Minimale Log-Implementierung, die die von CommonDB genutzte API-Oberfläche
    /// von INCLUDIS.Utils.Log bereitstellt. Die originale Bibliothek ist nicht Teil
    /// dieses Repositories; dieser Stub leitet Aufrufe an Debug weiter, sodass
    /// CommonDB eigenstaendig unter .NET 8 baut.
    /// </summary>
    public class Log
    {
        public Log()
        {
        }

        /// <summary>Protokolliert eine Meldung.</summary>
        public void LogSome(string message)
        {
            Debug.WriteLine(message);
        }

        /// <summary>Protokolliert eine Ausnahme mit Kontext.</summary>
        public void LogException(Exception exception, string cause)
        {
            Debug.WriteLine($"{cause}: {exception}");
        }

        /// <summary>Protokolliert eine Ausnahme inklusive Call-Stack.</summary>
        public void LogException(Exception exception, string cause, StackTrace stackTrace)
        {
            Debug.WriteLine($"{cause}: {exception}{Environment.NewLine}{stackTrace}");
        }

        /// <summary>Protokolliert den uebergebenen Call-Stack.</summary>
        public void LogCallStack(StackTrace stackTrace)
        {
            Debug.WriteLine(stackTrace?.ToString());
        }
    }

    /// <summary>
    /// Basisklasse, die urspruenglich aus INCLUDIS.Utils.Log stammt.
    /// CommonDB : DLLBase erbt hiervon. Stellt die von CommonDB genutzten
    /// LogException-Methoden bereit und delegiert an eine interne Log-Instanz.
    /// </summary>
    public class DLLBase
    {
        private bool _connected;
        private readonly Log _log = new Log();

        public bool Connected
        {
            get => _connected;
            set => _connected = value;
        }

        public string UserName { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public string Server { get; set; } = string.Empty;
        public string InitialCatalog { get; set; } = string.Empty;
        public string SqlProvider { get; set; } = string.Empty;

        protected void LogException(Exception exception, string cause)
        {
            _log.LogException(exception, cause);
        }

        protected void LogException(Exception exception, string cause, StackTrace stackTrace)
        {
            _log.LogException(exception, cause, stackTrace);
        }

        /// <summary>
        /// Zentrale Ausnahmebehandlung (urspruenglich aus INCLUDIS.Utils.Log).
        /// </summary>
        protected void HandleDBException(Exception ex, string cause)
        {
            _log.LogException(ex, cause);
        }

        protected void HandleDBException(Exception ex, string cause, StackTrace stackTrace)
        {
            _log.LogException(ex, cause, stackTrace);
        }
    }
}
