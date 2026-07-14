Es gibt einen alten Windows Dienst in Delphi geschrieben, der sich im Repository befindet. Dieser soll effektiv in C# dotnet 8.0 konvertiert werden. Alle erfoderlichen Klassen und Verweise sollten vorhanden sein.

Delphi-Konzept	C# .NET 8.0-Äquivalent	
Hinweise
Eine S7 Anbindung wird nicht benötigt
TService (Windows-Service)	BackgroundService + IHostedService	Konsolenanwendung mit HostBuilder (kein Windows-Service nötig).
TThread	BackgroundService oder Task.Run	Jeder Thread wird ein BackgroundService.

TCriticalSection	lock oder SemaphoreSlim	Einfache Synchronisation.
TDateTime	DateTime	1:1 Abbildung als Float.
IniFiles / Registry	appsettings.json + IConfiguration	Konfiguration über JSON-Datei.
LogMeldung	ILogger<T> (Microsoft.Extensions.Logging)	Integriert in .NET 8.0.

CommonDb
TCO_Query / TCO_Database	CommonDB (bereits vorhanden!)	Nutze die bestehende CommonDB-Bibliothek aus /commondb/.
CommonDb ist Äquivalent zu TCO_Database. Die Initialisierung sollte aus den Konstruktoren hervor gehen.
CommonReader / CommonCommand sind die Äquivalente zu TCO_Query. Anstatt bei TCO_Query alles einzeln zu machen, kann ein Reader über ExecuteReader(SQLStatement) erzeugt und iteriert werden. Um ein SQL Statement auszuführen reicht ein ExecuteNonQuery(SQLStatement)
Connection Pooling gibt es nicht mehr, Es gibt eine Instanz der CommonDB und dann werden die Reader einzeln erzeugt.

Konfigurationen nur noch über json configs. Keine INI und Registry Sachen.

TCO_SPC kann erst malweggelassen werden.
TCO_TPM hat ein paar Funktionen für StatsistikBerechnungen.
TOC_INCMeldung kann ebenfalls entfallen

Log über Serilog

Thread Kommunikation über Events
