# INCL Service - Delphi zu C# .NET 8.0 Konvertierung

## Projektbeschreibung
Ein alter Windows-Dienst in Delphi geschrieben, der in eine moderne C# .NET 8.0 Anwendung konvertiert wird. 

## Konvertierungsrichtlinien

### Delphi-Konzept → C# .NET 8.0-Äquivalent

| Delphi-Konzept | C# .NET 8.0-Äquivalent | Hinweise |
|----------------|------------------------|----------|
| TService (Windows-Service) | BackgroundService + IHostedService | Konsolenanwendung mit HostBuilder (kein Windows-Service nötig). |
| TThread | BackgroundService | Jeder Thread wird ein BackgroundService. |
| TCriticalSection | lock oder SemaphoreSlim | Einfache Synchronisation. |
| TDateTime | DateTime | 1:1 Abbildung als Float. |
| IniFiles / Registry | appsettings.json + IConfiguration | Konfiguration über JSON-Datei. |
| LogMeldung | ILogger<T> (Microsoft.Extensions.Logging) | Integriert in .NET 8.0. |

### CommonDB
| Delphi-Konzept | C# .NET 8.0-Äquivalent | Hinweise |
|----------------|------------------------|----------|
| TCO_Query / TCO_Database | CommonDB (bereits vorhanden!) | Nutze die bestehende CommonDB-Bibliothek aus /commondb/. |
| CommonDb ist Äquivalent zu TCO_Database | Die Initialisierung sollte aus den Konstruktoren hervor gehen. |
| CommonReader / CommonCommand | Äquivalente zu TCO_Query | Anstatt bei TCO_Query alles einzeln zu machen, kann ein Reader über ExecuteReader(SQLStatement) erzeugt und iteriert werden. Um ein SQL Statement auszuführen reicht ein ExecuteNonQuery(SQLStatement) |
| Connection Pooling | Entfällt | Es gibt eine Instanz der CommonDB pro Service und dann werden die Reader einzeln erzeugt. |
| Jeder Thread mit eigener Instanz der CommonDB | ✅ Implementiert | |

### Konfigurationen
- Nur noch über JSON-Configs (appsettings.json)
- Keine INI- und Registry-Sachen mehr

### Komponenten
- **TCO_SPC** kann erst mal weggelassen werden
- **TCO_TPM** hat Funktionen für Statistikberechnungen → Als eigene Klasse TPM.cs portieren
- **TOC_INCMeldung** kann ebenfalls entfallen

### Logging
- Serilog mit File-Sink + Rolling-File
- Mandanten-spezifisch (pro DBUser ein eigenes Log-Verzeichnis)

### Architektur
- **TS7Main** als MainService, der die anderen Services startet
- Kommunikation zwischen den BackgroundServices soll über Events erfolgen

## Implementierungsstand (Schritte 1-13)

### ✅ Schritt 1: C# Projektstruktur erstellt
- `INCLService.CSharp.csproj` für .NET 8.0
- `appsettings.json` für Konfiguration
- `Program.cs` als Haupteinstiegspunkt
- `ConfigurationModel.cs` für Konfigurationsmodell
- `MainService.cs` als BackgroundService (Äquivalent zu TINCLServ)

### ✅ Schritt 2: S7MainService und Thread-Services erstellt
- `S7MainService.cs` als Haupt-Service (Äquivalent zu TS7Main)
- `ShiftService.cs` für Schichtwechsel-Logik (TThread_Schicht)
- `DBBackupService.cs` für Datenbank-Backups (TThread_DBBackup)
- `SignalLogService.cs` für Signal-Logging (TThread_Signallog)
- `AdditionalService.cs` für zusätzliche Funktionen (TThread_Zusatz)

### ✅ Schritt 3: Jeder Service hat eigene CommonDB-Instanz
- Alle Services erstellen und verwalten ihre eigene Datenbankverbindung
- Entspricht dem Delphi-Konzept, wo jeder Thread seine eigene TCO_Database-Instanz hat

### ✅ Schritt 4: TPM-Klasse erstellt
- `TPM.cs` als Grundgerüst für TPM-Berechnungen (Äquivalent zu TCO_TPM)
- Enthält alle wichtigen Eigenschaften und Methoden

### ✅ Schritt 5a: DatenService erstellt
- `DatenService.cs` als zentraler Datenzugriff (Äquivalent zu TDaten in DatenM.pas)
- Enthält alle Query-Objekte als Properties
- Methoden für Connect/Disconnect

### ✅ Schritt 5b: SQLHelper erstellt
- `SQLHelper.cs` mit SQL-Hilfsfunktionen (Äquivalent zu SQL_fuc.pas)
- Enthält SQL_Get, SQL_Insert, SQLGetBool, UpdateSQL, DeleteSQL
- Fehlerbehandlung mit HandleDBError und RestartDatabase

### ✅ Schritt 6a: ArbeitModels erstellt
- `ArbeitModels.cs` mit CavChange, Auftrag, BDE, TPMData Klassen
- Äquivalent zu TCavChange, TAuftrag, TBDE, TTPM in Arbeit.pas

### ✅ Schritt 7: SchichtModels erstellt
- `SchichtModels.cs` mit StillstandEintrag, StartStopEintrag, SignalLogEintrag
- Enthält alle Listenoperationen und Berechnungen
- Äquivalent zu SchichtUtilLib.pas

### ✅ Schritt 8: ShiftService erweitert
- Integration von TPM-Klasse
- Schichtwechsel-Logik implementiert
- Stillstandsberechnungen hinzugefügt
- GetSignalNr, CheckSchichtwechsel Methoden

### ✅ Schritt 10: SignalLogService erweitert
- SignalClass für Signal-Daten
- InitializeSignalListAsync für Initialisierung
- ExecuteSignalLoggingAsync für Hauptlogik
- HandleSignalChangeAsync für Wertänderungen

### ✅ Schritt 11: AdditionalService erweitert
- StartProgrammeAsync als Hauptmethode
- CheckRuestProtStillogAsync für Rüstprotokoll
- PaletteRestBerechnenAsync für Palettenberechnung
- TPMKorrekturDoppelteDatenAsync für Datenbereinigung

### ✅ Schritt 12: AdditionalService mit detaillierten Implementierungen
- JobNoToDowntimeLogAsync: Job-Nummern in Downtime-Log eintragen
- ArbeitsFreiBuchenAsync: Arbeitsfrei-Zeiten buchen (vereinfacht)
- BookShortDelayAsync: Kurze Verzögerungen automatisch buchen
- WZReparaturAsync: Werkzeug-Reparaturen verarbeiten

### ✅ Schritt 13: AdditionalService mit allen Funktionen aus Th_Zusatz.pas
- CheckVerpacktProtAsync: Verpackt-Protokoll prüfen und aktualisieren
- Alle Konfigurationseinstellungen hinzugefügt
- FloatToPunktStr für Datumskonvertierung

## Projektstruktur

```
INCLService.CSharp/
├── appsettings.json              # Konfiguration
├── INCLService.CSharp.csproj     # Projektdatei
│
├── Models/
│   ├── ArbeitModels.cs           # Auftrag, BDE, TPMData, CavChange
│   ├── ConfigurationModel.cs     # DatabaseConfig, MainConfig
│   └── SchichtModels.cs          # Stillstand-, StartStop-, SignalLog-Einträge
│
├── Services/
│   ├── AdditionalService.cs      # Zusätzliche Funktionen (TThread_Zusatz)
│   ├── DatenService.cs           # Zentraler Datenzugriff (TDaten)
│   ├── DBBackupService.cs        # Datenbank-Backups (TThread_DBBackup)
│   ├── MainService.cs            # Haupt-Service (TINCLServ)
│   ├── S7MainService.cs          # Hauptkoordinator (TS7Main)
│   ├── ShiftService.cs           # Schichtwechsel-Logik (TThread_Schicht)
│   ├── SignalLogService.cs       # Signal-Logging (TThread_Signallog)
│   └── TPM.cs                    # TPM-Berechnungen (TCO_TPM)
│
└── Utilities/
    └── SQLHelper.cs               # SQL-Hilfsfunktionen (SQL_fuc.pas)
```

## Nächste Schritte

### 🔜 Offene Punkte
1. **Event-System** für Kommunikation zwischen Services implementieren
2. **Restliche Funktionen** detailliert implementieren:
   - LaufzeitBerechnenAsync
   - CheckTaktLogAsync
   - CheckPackSchichtAsync
3. **Integration und Test** der Services
4. **Fehlende Delphi-Dateien** analysieren und portieren:
   - DBMain.pas (detaillierte Analyse)
   - MainAzure.pas
   - Service_Debug.pas

### 📝 Hinweise
- Alle Haupt-Threads sind als BackgroundServices umgesetzt
- Jeder Service hat seine eigene CommonDB-Instanz
- Konfiguration erfolgt über appsettings.json
- Logging über Serilog mit File-Rotation
- Die meisten Funktionen sind implementiert, einige als Platzhalter

## GitHub Information
- **Repository**: MadIsBack/INCL
- **Branch**: main
- **Commits**: 13 Schritte
- **Status**: Alle Schritte 1-13 in main gemerged
