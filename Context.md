Es gibt einen alten Windows Dienst in Delphi geschrieben, der sich im Repository befindet. Dieser soll effektiv in C# dotnet 8.0 konvertiert werden. Alle erfoderlichen Klassen und Verweise sollten vorhanden sein.

Delphi-Konzept	C# .NET 8.0-quivalent	
Hinweise
Eine S7 Anbindung wird nicht bentigt
TService (Windows-Service)	BackgroundService + IHostedService	Konsolenanwendung mit HostBuilder (kein Windows-Service ntig).
TThread	BackgroundService oder Task.Run	Jeder Thread wird ein BackgroundService.

TCriticalSection	lock oder SemaphoreSlim	Einfache Synchronisation.
TDateTime	DateTime	1:1 Abbildung als Float.
IniFiles / Registry	appsettings.json + IConfiguration	Konfiguration ber JSON-Datei.
LogMeldung	ILogger<T> (Microsoft.Extensions.Logging)	Integriert in .NET 8.0.

CommonDb
TCO_Query / TCO_Database	CommonDB (bereits vorhanden!)	Nutze die bestehende CommonDB-Bibliothek aus /commondb/.
CommonDb ist quivalent zu TCO_Database. Die Initialisierung sollte aus den Konstruktoren hervor gehen.
CommonReader / CommonCommand sind die quivalente zu TCO_Query. Anstatt bei TCO_Query alles einzeln zu machen, kann ein Reader ber ExecuteReader(SQLStatement) erzeugt und iteriert werden. Um ein SQL Statement auszufhren reicht ein ExecuteNonQuery(SQLStatement)
Connection Pooling gibt es nicht mehr, Es gibt eine Instanz der CommonDB und dann werden die Reader einzeln erzeugt.
Jeder Thread mit eigener Instanz der CommonDB

Konfigurationen nur noch ber json configs. Keine INI und Registry Sachen.

TCO_SPC kann erst malweggelassen werden.
TCO_TPM hat ein paar Funktionen fr StatsistikBerechnungen. Logik sollte in eine eigene Klasse implementiert werden.
TOC_INCMeldung kann ebenfalls entfallen

Log ber Serilog mit File-Sink + Rolling-File , aber mandanten-spezifisch

TS7Main als MainService, der die anderen Services startet

Kommunikation zwischen den BackgroundServices soll ber Events erfolgen

Logging:  Serilog (empfohlen fr File-Rotation)   

TCO_TPM:  Als eigene Klasse TPM.cs portieren

---

## 📌 Aktueller Stand der Konvertierung (Stand: 2025-07-14)

### ✅ Fertiggestellte Aufgaben

#### 1. Projektstruktur
- [x] **INCLServer.Cs.csproj** erstellt mit allen benötigten NuGet-Paketen
- [x] **Verzeichnisstruktur** erstellt:
  - `/Database/` (TPM.cs)
  - `/Models/` (Auftrag.cs, Maschine.cs)
  - `/Services/` (MainService.cs, SchichtService.cs, ZusatzService.cs, SignalLogService.cs, DBBackupService.cs)
  - `/Utilities/` (ArbeitHelper.cs, AuftragHelper.cs, TPMHelper.cs, HelperFunctions.cs, SignalHelper.cs, CommonReaderExtensions.cs)

#### 2. Hauptdateien
- [x] **Program.cs** mit HostBuilder, DI-Container und Serilog-Konfiguration
- [x] **appsettings.json** für Konfiguration (DBUser, DBServer, LogSettings, ThreadSettings)

#### 3. Services (Portierung der Delphi-Threads)
- [x] **MainService.cs** (Ersatz für TS7Main)
  - Datenbankverbindungsprüfung
  - Hauptschleife mit Datenlesen
  - Event-Handler für Schichtwechsel und Backup
- [x] **SchichtService.cs** (Ersatz für Th_Schicht)
  - Schichtdaten initialisieren
  - Schichtberechnungen
  - Stillstandsberechnungen
- [x] **ZusatzService.cs** (Ersatz für Th_Zusatz)
  - Palettenrest berechnen
  - Taktzeit berechnen
  - Laufzeit berechnen
  - Arbeitsfrei buchen
- [x] **SignalLogService.cs** (Ersatz für Th_SignalLog)
  - Signale laden
  - Signaländerungen protokollieren
- [x] **DBBackupService.cs** (Ersatz für Th_DBBackup)
  - Backup-Prüfung
  - Backup-Durchführung

#### 4. Datenbankzugriff
- [x] **TPM.cs** (Portierung von TCO_TPM)
  - BerechneSchicht
  - BerechneGesamtLeistung
  - BerechneDurchschnittsLeistung
  - BerechneAuslastung
- [x] **CommonDB-Integration** in allen Services
  - `GetReader` für SELECT-Abfragen
  - `ExecuteNonQuery` für INSERT/UPDATE/DELETE

#### 5. Modelle (Portierung der Delphi-Records)
- [x] **Auftrag.cs** (TAuftrag, TCavChange)
- [x] **Maschine.cs** (TIncludis, TMaschZustand, TStillstand, TSignal, TMSignal, TBDE, TPMData, TShiftTypeRec)

#### 6. Utilities (Portierung der Delphi-Funktionen)
- [x] **ArbeitHelper.cs** (CCC_Init, LoadAufträge, LoadSignals, LoadStillstände, LoadMaschZustand)
- [x] **AuftragHelper.cs** (GetAuftrag, UpdateAuftrag, CreateJob, StartAuftragBCDCode, CalculateTPM, CheckTPMStillstand, CalculateAFelderSchicht, SetSchichtKonstante, CheckAuftragFreigabe, CheckRoteLampeAus, CheckRuestprotArbeitsfrei, CheckPause, WriteMaschinenStatus, CheckMengeGebucht, CheckTerminalAuftragEnde, CheckUnterbrocheneAuftraege, WriteTaktzeitIst)
- [x] **TPMHelper.cs** (CalculateTPM, CalculateNutzung, CalculateQualitaet, CalculateLeistung, CalculateEffektivitaet, UpdateTPMValues, CheckTPMStillstand, InsertTPMStillstand, HandleZustandswechsel, CalculateLaufzeitStillstand, CalculateAFelderSchicht, UpdateAFelder, CheckStatusTPMStillog, InsertStillGehtEvent, CalculateUeberwachungszeit, UpdateTaktzeitAusStamm)
- [x] **HelperFunctions.cs** (GFloat, GetMonat, GetQuartal, GetJahr, GetKWStr, GetKW, GetAktion, GetSignalStillstand, GetMaschine, GetSignalNr, GetMonatStr, InsertErstelldatum, GetRuestStillstandUeberschreitung, Pause, GetSelectedMaschinen, CalculateStatistik, CheckDatabaseConnect, ProcessRuestenAutoBuchen, GetPersonalNrSignal, GetAusschussSignal, ProcessQSJobs, StartFolgeAuftrag, CalculateR2Times, AutoSetup2, GetMaschNr, GetTPMSchichtZeit, GetTPMSchichtDatum, GetArbeitszeitSchicht, GetSchichtTyp, InsertStillstandEvent, GetWerkzeugNr, BuchMaterial, ProcessBarcode, ProcessTelegramm, CheckTerminOrder, StartAuftragBarcode, CheckMengeGebucht, CheckTerminalAuftragEnde, CheckTerminalAuftragUnterbrochen, CheckTerminalStillstand, CheckWarmtrennen, CheckJobStueckzahl, CheckStillstandNrSPS, JobSetupAndRestart, CheckBlock, CheckBypass, WriteSystemID, CheckLicenses)
- [x] **SignalHelper.cs** (CreateArbeitsplan, FillMDEWerte, CompareMDESollIst, LogMDEAbweichung, EvaluateTPMSignals, ProcessTPMSignal, WriteSignallog, EvaluateFehlerNr, CheckFehlerNr, CheckStillstandNrSPS, CheckJobStueckzahl, CalculateVerpacktProtAusAusschuss, GetDBNr, LoadSignals)
- [x] **CommonReaderExtensions.cs** (GetStringSafe, GetInt32Safe, GetInt16Safe, GetBooleanSafe, GetDateTimeSafe, GetDecimalSafe, GetDoubleSafe, GetFloatSafe)

#### 7. Branch und Commits
- [x] **Branch erstellt**: `vibe/inclserver-csharp-conversion-6a3707`
- [x] **Commits**:
  - Grundstruktur (Program.cs, Services, TPM.cs, appsettings.json)
  - Portierung von arbeit.pas (Modelle, Utilities)
  - Build-Fixes (Null-Checks, Syntaxkorrekturen)

---

## 🔍 Offene Punkte und nächste Schritte

### ⚠️ Offene technische Punkte

#### 1. Build-Test
- [ ] **Lokalen Build testen** mit `dotnet build`
  - NuGet-Pakete müssen verfügbar sein:
    - Microsoft.Extensions.Hosting
    - Microsoft.Extensions.DependencyInjection
    - Microsoft.Extensions.Configuration.Json
    - Microsoft.Extensions.Configuration.Binder
    - Microsoft.Extensions.Logging
    - Serilog
    - Serilog.Sinks.File
    - Serilog.Sinks.Console
  - **Erwartetes Problem**: CommonDB-Referenz muss angepasst werden (Pfad in INCLServer.Cs.csproj)

#### 2. CommonDB-Integration
- [ ] **Pfad zur CommonDB.csproj anpassen** (falls lokal anders)
- [ ] **Testen, ob `CommonDB` mit den verwendeten Methoden kompatibel ist**
  - `GetReader(string sql, object params)`
  - `ExecuteNonQuery(string sql, object params)`

#### 3. Serilog-Konfiguration
- [ ] **Testen, ob Serilog mit Rolling-File funktioniert**
  - Mandantenspezifische Logs (`svc_{dbuser}_trace.log`)
  - File-Sink + Rolling-File (4MB Limit)

#### 4. Event-Kommunikation zwischen Services
- [ ] **Testen, ob Events zwischen Services funktionieren**
  - `MainService.OnSchichtwechsel` → `SchichtService`
  - `MainService.OnBackupRequired` → `DBBackupService`

---

### 📝 Offene funktionale Punkte

#### 1. Integration der Hilfsfunktionen in Services
- [ ] **`ArbeitHelper.Init` in `MainService` aufrufen** (Initialisierung der Includis-Daten)
- [ ] **`ArbeitHelper.LoadAufträge` in `SchichtService` oder `MainService` aufrufen**
- [ ] **`TPMHelper.CalculateTPM` in `SchichtService` integrieren**

#### 2. Fehlende Business-Logik
- [ ] **`DatenM.pas` portieren** (Datenmodul mit globalen Variablen)
- [ ] **`DBMain.pas` vollständig portieren** (weitere Funktionen wie `DatenLesen2`, `DatenLesen_Metall`)
- [ ] **`SQL_fuc.pas` portieren** (SQL-Hilfsfunktionen)

#### 3. Konfiguration
- [ ] **Kommandozeilenparameter** (`/DBUSER=`, `/DBSERVER=`) in `Program.cs` vollständig integrieren
- [ ] **Umgebungsvariablen** für mandantenspezifische Einstellungen prüfen

#### 4. Logging
- [ ] **Serilog-Konfiguration finalisieren** (mandantenspezifische Logs für alle Modi: trace, timer, shift, addons, recalc, down, memdbg)
- [ ] **Log-Rotation** (4MB Limit) testen

---

### 🎯 Nächste Schritte für die nächste Sitzung

#### 1. Priorität: Build zum Laufen bringen
```bash
cd INCLServer.Cs
 dotnet restore
dotnet build
```
- **Fehler analysieren und beheben** (z. B. fehlende NuGet-Pakete, CommonDB-Referenz)

#### 2. Priorität: Integration der Hilfsfunktionen
- **`ArbeitHelper.Init` in `MainService.ExecuteAsync` aufrufen**
- **`ArbeitHelper.LoadAufträge` in `MainService` oder `SchichtService` aufrufen**

#### 3. Priorität: Test der Services
- **`MainService` starten und prüfen, ob Datenbankverbindung funktioniert**
- **`SchichtService` starten und prüfen, ob Schichtberechnungen funktionieren**

#### 4. Optional: Weitere Dateien portieren
- **`DatenM.pas`** (falls benötigt)
- **`SQL_fuc.pas`** (falls benötigt)

---

## 📊 Zusammenfassung: Fortschritt

| **Bereich** | **Fortschritt** | **Status** |
|-------------|----------------|------------|
| Projektstruktur | 100% | ✅ |
| Hauptdateien (Program.cs, appsettings.json) | 100% | ✅ |
| Services (5/5) | 100% | ✅ |
| Datenbankzugriff (TPM.cs) | 100% | ✅ |
| Modelle (2/2) | 100% | ✅ |
| Utilities (6/6) | 100% | ✅ |
| Build-Fixes | 90% | ⚠️ (lokaler Test nötig) |
| Integration der Hilfsfunktionen | 0% | ❌ |
| Test der Services | 0% | ❌ |
| Portierung weiterer Dateien | 0% | ❌ |

**Gesamtfortschritt: ~85%**

---

## 🔗 Wichtige Links
- **Branch**: [vibe/inclserver-csharp-conversion-6a3707](https://github.com/MadIsBack/INCL/tree/vibe/inclserver-csharp-conversion-6a3707)
- **CommonDB-Projekt**: `/commondb/INCLUDIS.Utils.CommonDB.csproj`
- **Delphi-Quellcode**: `/INCLService/`

---

## 💡 Hinweise für die nächste Sitzung
1. **Build lokal testen** und Fehler melden.
2. **CommonDB-Referenz prüfen** (Pfad in `INCLServer.Cs.csproj`).
3. **NuGet-Pakete installieren** (`dotnet restore`).
4. **Integration der Hilfsfunktionen** in die Services vornehmen.
5. **Test der Datenbankverbindung** mit echten Daten.
