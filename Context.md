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

---

## 📊 Detaillierte Analyse: Delphi vs. C# Implementierungsstand

### 🔍 **DBMain.pas (3760 Zeilen) - Hauptdatei mit TS7Main**

#### **Delphi-Struktur:**
- **TS7Main** Klasse (Hauptkoordinator)
  - Erstellt und verwaltet alle Threads (Schicht, SignalLog, Zusatz, DBBackup)
  - Enthält Timer-Logik für periodische Aufgaben
  - SPS-Werte-Datenbank-Interaktion
  - Schichtwechsel-Logik
  - Fehlerbehandlung und System-Error-Handling
  
- **Konstanten und Variablen:**
  - S7-Signal-Adressen (CSTUECKGESAMT, CBETRIEBSSTUNDEN, etc.)
  - Maschinenstatus-Konstanten
  - TPM-Störgruppen
  - Zeitkonstanten (TAGMINUTEN, Stunde, MINUTEN5, etc.)

- **Datenstrukturen:**
  - `TSPS_Daten_DWord`, `TSPS_Daten_Word`, `TSPS_Daten_Byte`, `TSPS_Daten_Bool` (für S7-Signal-Daten)
  - `TSignalMaschineItem` und `TSignalMaschineList` (für Signal-Maschinen-Zuordnung)

#### **C#-Implementierungsstand:**
✅ **S7MainService.cs** existiert und enthält:
- Grundgerüst als BackgroundService
- Konfigurationseinstellungen (Pruefen, Packen, VerpacktBarcode, etc.)
- Eigene CommonDB-Instanz
- Timer-Intervalle
- ServerNameDesDienstes, IgnorePendingStatement
- Feature-Flags (AuftragstartBarcode, PersonalAnmeldung, etc.)

❌ **Fehlende Implementierungen:**
- **SPS-Datenstrukturen** (TSPS_Daten_*) → Fehlen in C#
- **Signal-Maschinen-Zuordnung** (TSignalMaschineItem/List) → Fehlt
- **Create_Threads** Methode → Teilweise in Program.cs, aber nicht vollständig
- **In_SPSWerteDB** → Fehlt (SPS-Werte in DB schreiben)
- **Schreibe_SPS_Wert** → Fehlt
- **DatenLesen, DatenLesen2, DatenLesen_Metall** → Fehlen
- **Hole_Daten_Tabelle** → Fehlt
- **NeueSchicht** → Fehlt (Schichtwechsel-Logik)
- **CheckRoteLampeAus** → Fehlt
- **GetStueckAuftragAlt** → Fehlt
- **CheckManuelleStueckBuchung** → Fehlt

---

### 🔍 **Main.pas - Windows Service Hauptklasse**

#### **Delphi-Struktur:**
- **TINCLServ** (erbt von TService)
  - ServiceExecute, ServiceCreate, ServiceDestroy
  - Datenbankverbindungsprüfung (CheckDBVerbindung)
  - Logging (SchreibeMeldung mit verschiedenen Modi)
  - DBUser, DBServer, DBPass, DBInitialCatalog aus Registry/INI

#### **C#-Implementierungsstand:**
✅ **Program.cs** und **MainService.cs** enthalten:
- HostBuilder-Setup
- BackgroundService-Integration
- Konfiguration über appsettings.json
- Logging über ILogger

❌ **Fehlende Implementierungen:**
- **ServiceBeforeInstall/ServiceAfterInstall** → Nicht benötigt (kein Windows-Service)
- **Registry/INI-Lesen** → Ersetzt durch appsettings.json ✅
- **SchreibeMeldung mit verschiedenen Log-Dateien** → Teilweise implementiert, aber nicht mandanten-spezifisch

---

### 🔍 **MainAzure.pas - Azure-Kompatibler Service**

#### **Delphi-Struktur:**
- **TINCLServAzure** Klasse
  - Ähnlich zu TINCLServ, aber ohne Windows-Service-Abhängigkeiten
  - CheckShutdownFile für Graceful Shutdown
  - Run-Methode für manuellen Start

#### **C#-Implementierungsstand:**
✅ **Program.cs** unterstützt bereits:
- Konsolenanwendung mit HostBuilder
- Graceful Shutdown über CancellationToken

❌ **Fehlende Implementierungen:**
- **Shutdown-Datei-Prüfung** → Nicht implementiert (könnte optional sein)

---

### 🔍 **Service_Debug.pas - Debug-Formular**

#### **Delphi-Struktur:**
- **TForm1** mit UI-Elementen
- Manuelles Starten/Stoppen von S7Main
- Memory-Monitoring
- DB-Verbindungs-Test

#### **C#-Implementierungsstand:**
❌ **Nicht implementiert** (Debug-UI nicht benötigt für Service)
- Kann entfallen, da .NET 8.0 mit Debugging-Tools arbeitet

---

### 🔍 **Th_Zusatz.pas (124550 Bytes) - Zusätzliche Funktionen**

#### **Delphi-Struktur - TThread_Zusatz:**
- **Hauptmethoden:**
  - `StartProgramme` → Haupt-Einstiegspunkt
  - `Execute` → Thread-Hauptschleife
  
- **Funktionen (alle analysiert):**
  - ✅ `Palette_Rest_Berechnen` → **PaletteRestBerechnenAsync** in AdditionalService.cs
  - ✅ `TPM_Korrektur_Doppelte_Daten` → **TPMKorrekturDoppelteDatenAsync** in AdditionalService.cs
  - ✅ `WZReparatur` → **WZReparaturAsync** in AdditionalService.cs
  - ✅ `CheckRuestProt_Stillog` → **CheckRuestProtStillogAsync** in AdditionalService.cs
  - ✅ `Job_No_to_Downtime_Log` → **JobNoToDowntimeLogAsync** in AdditionalService.cs
  - ✅ `CheckVerpacktProt` → **CheckVerpacktProtAsync** in AdditionalService.cs
  - ✅ `ArbeitsFrei_Buchen` → **ArbeitsFreiBuchenAsync** in AdditionalService.cs
  - ✅ `Book_Short_Delay` → **BookShortDelayAsync** in AdditionalService.cs
  - ⚠️ `Laufzeit_Berechnen` → **LaufzeitBerechnenAsync** in ArbeitUtils.cs (✅ Grundgerüst, ❌ Details fehlen)
  - ⚠️ `Laufzeit_Berechnen2` → **LaufzeitBerechnen2Async** in ArbeitUtils.cs (✅ Grundgerüst, ❌ Details fehlen)
  - ⚠️ `Check_TaktLog` → **CheckTaktLogAsync** in ArbeitUtils.cs (✅ Grundgerüst, ❌ Delphi-Logik fehlt)
  - ⚠️ `CheckPackSchicht` → **CheckPackSchichtAsync** in ArbeitUtils.cs (✅ Grundgerüst, ❌ Delphi-Logik fehlt)
  
- **Weitere Funktionen:**
  - `CalcPackedlogFromShiftlog` → ❌ Fehlt
  - `Taktzeit_Personal` → ❌ Fehlt
  - `TaktMitteln` → ❌ Fehlt
  - `UnscheduledSetup` → ❌ Fehlt
  - `CheckSollstueck` → ❌ Fehlt
  - `CheckWzWartungen` → ❌ Fehlt
  - `CheckAuftragKette` → ❌ Fehlt
  - `Reschedule` → ❌ Fehlt
  - `BerechnenEndeausIst` → ❌ Fehlt
  - `Laufende_Auftraege_Terminieren` → ❌ Fehlt
  - `Autoterminierung` → ❌ Fehlt
  - `Status_Beschreibung` → ❌ Fehlt
  - `PlanListeReportParameterSchreiben` → ❌ Fehlt

#### **C#-Implementierungsstand:**
✅ **AdditionalService.cs** enthält:
- StartProgrammeAsync
- Alle Hauptfunktionen als async Methoden
- Konfiguration aus appsettings.json
- Eigene CommonDB-Instanz

⚠️ **ArbeitUtils.cs** enthält:
- Grundgerüst für LaufzeitBerechnenAsync, CheckTaktLogAsync, CheckPackSchichtAsync
- **ABER:** Die Delphi-Logik ist nicht 1:1 portiert

---

### 🔍 **Th_Schicht.pas - Schichtwechsel-Logik**

#### **Delphi-Struktur - TThread_Schicht:**
- Schichtwechsel-Erkennung
- Stillstandsberechnungen
- TPM-Berechnungen
- Signal-Überwachung

#### **C#-Implementierungsstand:**
✅ **ShiftService.cs** existiert und enthält:
- Grundgerüst als BackgroundService
- CheckSchichtwechsel
- GetSignalNr
- Stillstandsberechnungen

❌ **Fehlende Implementierungen:**
- **Detaillierte Schichtwechsel-Logik** aus Delphi
- **TPM-Integration** (teilweise vorhanden)

---

### 🔍 **Th_SignalLog.pas - Signal-Logging**

#### **Delphi-Struktur - TThread_Signallog:**
- Signal-Wert-Überwachung
- Wertänderungs-Erkennung
- Logging in Datenbank

#### **C#-Implementierungsstand:**
✅ **SignalLogService.cs** existiert und enthält:
- SignalClass für Signal-Daten
- InitializeSignalListAsync
- ExecuteSignalLoggingAsync
- HandleSignalChangeAsync

❌ **Fehlende Implementierungen:**
- **Komplette Signal-Überwachungslogik** aus Delphi

---

### 🔍 **Th_DBBackup.pas - Datenbank-Backup**

#### **Delphi-Struktur - TThread_DBBackup:**
- Periodische Backups
- Backup-Verwaltung

#### **C#-Implementierungsstand:**
✅ **DBBackupService.cs** existiert

❌ **Fehlende Implementierungen:**
- **Backup-Logik** aus Delphi

---

### 🔍 **DatenM.pas - Datenzugriff**

#### **Delphi-Struktur - TDaten:**
- Zentrale Datenbankverbindung
- Query-Objekte (qAuftrag, qBDE, qTPM, etc.)
- Connect/Disconnect

#### **C#-Implementierungsstand:**
✅ **DatenService.cs** existiert und enthält:
- CommonDB-Instanz
- Query-Properties
- Connect/Disconnect

---

### 🔍 **SQL_fuc.pas - SQL-Hilfsfunktionen**

#### **Delphi-Struktur:**
- SQL_Get, SQL_Insert, SQLGetBool
- UpdateSQL, DeleteSQL
- HandleDBError, RestartDatabase

#### **C#-Implementierungsstand:**
✅ **SQLHelper.cs** existiert und enthält:
- ExecuteReader, ExecuteNonQuery
- Fehlerbehandlung

---

## 📋 ToDo-Liste (Priorisiert)

### 🔴 **Hochpriorität - Kritische Lücken**

1. **📌 DBMain.pas → S7MainService.cs**
   - [ ] **SPS-Datenstrukturen** implementieren (TSPS_Daten_DWord, TSPS_Daten_Word, etc.)
   - [ ] **TSignalMaschineItem/TSignalMaschineList** als C#-Klassen portieren
   - [ ] **Create_Threads** Methode vollständig implementieren
   - [ ] **In_SPSWerteDB** - SPS-Werte in Datenbank schreiben
   - [ ] **Schreibe_SPS_Wert** - Einzelne SPS-Werte schreiben
   - [ ] **DatenLesen, DatenLesen2, DatenLesen_Metall** - Datenabfrage-Logik
   - [ ] **Hole_Daten_Tabelle** - Tabellendaten abrufen
   - [ ] **NeueSchicht** - Schichtwechsel-Logik
   - [ ] **CheckRoteLampeAus** - Rote Lampe Status prüfen
   - [ ] **GetStueckAuftragAlt** - Stückzahl abrufen
   - [ ] **CheckManuelleStueckBuchung** - Manuelle Stückbuchung prüfen

2. **📌 Th_Zusatz.pas → AdditionalService.cs + ArbeitUtils.cs**
   - [ ] **Laufzeit_Berechnen** - Komplette Logik aus Delphi portieren (ZeitInMinuten, MAX-Funktion, etc.)
   - [ ] **Laufzeit_Berechnen2** - Erweiterte Version implementieren
   - [ ] **Check_TaktLog** - Komplette Takt-Log-Prüfung mit Toleranzberechnung
   - [ ] **CheckPackSchicht** - Verpackt-Schicht-Prüfung mit Schichtdauer-Berechnung
   - [ ] **CalcPackedlogFromShiftlog** - Verpackt-Log aus Schicht-Log berechnen
   - [ ] **Taktzeit_Personal** - Taktzeit pro Personal berechnen
   - [ ] **TaktMitteln** - Taktzeit mitteln
   - [ ] **UnscheduledSetup** - Ungeplante Rüstzeiten
   - [ ] **CheckSollstueck** - Sollstückzahl prüfen
   - [ ] **CheckWzWartungen** - Werkzeug-Wartungen prüfen
   - [ ] **CheckAuftragKette** - Auftragskette prüfen
   - [ ] **Reschedule** - Neuplanung
   - [ ] **BerechnenEndeausIst** - Ende aus Ist berechnen
   - [ ] **Laufende_Auftraege_Terminieren** - Laufende Aufträge terminieren
   - [ ] **Autoterminierung** - Automatische Terminierung
   - [ ] **Status_Beschreibung** - Status-Beschreibungen aktualisieren

3. **📌 Event-System vervollständigen**
   - [ ] **ServiceEventSystem.cs** in alle Services integrieren
   - [ ] Event-Kommunikation zwischen Services testen
   - [ ] Event-Namen standardisieren (EVENT_SCHICHT, EVENT_SIGNALLLOG, etc.)

4. **📌 Logging verbessern**
   - [ ] **Serilog-Konfiguration** für mandanten-spezifische Logs
   - [ ] **Log-Rotation** pro DBUser
   - [ ] **Log-Level-Konfiguration** aus appsettings.json

---

### 🟡 **Mittelpriorität - Wichtige Ergänzungen**

5. **📌 Th_Schicht.pas → ShiftService.cs**
   - [ ] **Detaillierte Schichtwechsel-Logik** aus Delphi portieren
   - [ ] **TPM-Integration** vervollständigen
   - [ ] **Stillstandsberechnungen** optimieren

6. **📌 Th_SignalLog.pas → SignalLogService.cs**
   - [ ] **Komplette Signal-Überwachungslogik** implementieren
   - [ ] **Wertänderungs-Erkennung** verbessern
   - [ ] **Signal-Datenbank-Logging** vervollständigen

7. **📌 Th_DBBackup.pas → DBBackupService.cs**
   - [ ] **Backup-Logik** aus Delphi portieren
   - [ ] **Backup-Verwaltung** implementieren

8. **📌 MainAzure.pas**
   - [ ] **Shutdown-Datei-Prüfung** optional implementieren

---

### 🟢 **Niedrigpriorität - Optional**

9. **📌 Service_Debug.pas**
   - [ ] **Debug-UI** (kann entfallen, da .NET Debugging-Tools)

10. **📌 SPCUtility.pas, U_SPC.pas**
    - [ ] **SPC-Funktionen** (können entfallen, da S7-Anbindung nicht benötigt)

11. **📌 U_Metall.pas**
    - [ ] **Metall-spezifische Funktionen** (falls benötigt)

---

## 📁 Datei-zu-Datei Zuordnung

| Delphi-Datei | C#-Datei | Status | Priorität |
|--------------|----------|--------|-----------|
| Main.pas | Program.cs + MainService.cs | ✅ 90% | 🟢 |
| MainAzure.pas | Program.cs | ⚠️ 50% | 🟡 |
| DBMain.pas | S7MainService.cs | ⚠️ 30% | 🔴 |
| Service_Debug.pas | - | ❌ 0% | 🟢 |
| Th_Zusatz.pas | AdditionalService.cs + ArbeitUtils.cs | ⚠️ 60% | 🔴 |
| Th_Schicht.pas | ShiftService.cs | ⚠️ 50% | 🟡 |
| Th_SignalLog.pas | SignalLogService.cs | ⚠️ 40% | 🟡 |
| Th_DBBackup.pas | DBBackupService.cs | ⚠️ 20% | 🟡 |
| DatenM.pas | DatenService.cs | ✅ 80% | 🟢 |
| SQL_fuc.pas | SQLHelper.cs | ✅ 70% | 🟢 |
| Arbeit.pas | ArbeitModels.cs + ArbeitUtils.cs | ✅ 75% | 🟢 |
| SchichtUtilLib.pas | SchichtModels.cs | ✅ 80% | 🟢 |
| CO_TPM_V63.pas | TPM.cs | ✅ 85% | 🟢 |

---

## 🎯 Nächste konkrete Schritte

### Schritt 14: DBMain.pas analysieren und S7MainService.cs vervollständigen
- [ ] SPS-Datenstrukturen implementieren
- [ ] Signal-Maschinen-Zuordnung portieren
- [ ] Hauptmethoden (Create_Threads, In_SPSWerteDB, etc.) implementieren

### Schritt 15: Th_Zusatz.pas Funktionen detailliert portieren
- [ ] Laufzeit_Berechnen mit kompletter Delphi-Logik
- [ ] Check_TaktLog mit Toleranzberechnung
- [ ] CheckPackSchicht mit Schichtdauer

### Schritt 16: Event-System integrieren
- [ ] ServiceEventSystem in alle Services einbinden
- [ ] Kommunikation testen

### Schritt 17: Logging mit Serilog vervollständigen
- [ ] Mandanten-spezifische Log-Konfiguration
- [ ] Log-Rotation einrichten

### Schritt 18: Integrationstests
- [ ] Alle Services gemeinsam testen
- [ ] Datenbankverbindungen prüfen
- [ ] Fehlerbehandlung testen

---

## 📊 Implementierungsfortschritt

| Bereich | Fortschritt | Status |
|---------|-------------|--------|
| Projektstruktur | 100% | ✅ |
| Services (Grundgerüst) | 100% | ✅ |
| CommonDB-Integration | 100% | ✅ |
| Konfiguration (appsettings.json) | 100% | ✅ |
| Modelle (Arbeit, Schicht, etc.) | 90% | ✅ |
| **DBMain.pas → S7MainService.cs** | **30%** | ⚠️ |
| **Th_Zusatz.pas → AdditionalService** | **60%** | ⚠️ |
| **Th_Schicht.pas → ShiftService** | **50%** | ⚠️ |
| **Th_SignalLog.pas → SignalLogService** | **40%** | ⚠️ |
| **Th_DBBackup.pas → DBBackupService** | **20%** | ⚠️ |
| Event-System | 80% | ✅ |
| Logging (Serilog) | 50% | ⚠️ |

**Gesamtfortschritt: ~65%**

---

## 🔗 Abhängigkeiten zwischen Dateien

```
DBMain.pas (TS7Main)
├── Th_Schicht.pas (TThread_Schicht)
├── Th_SignalLog.pas (TThread_Signallog)
├── Th_Zusatz.pas (TThread_Zusatz)
├── Th_DBBackup.pas (TThread_DBBackup)
├── DatenM.pas (TDaten)
└── SQL_fuc.pas (SQL-Hilfsfunktionen)

Main.pas (TINCLServ)
└── DBMain.pas (S7Main erstellen)

MainAzure.pas (TINCLServAzure)
└── DBMain.pas (S7Main erstellen)
```

---

## 📝 Notizen zur Portierung

### Wichtige Delphi-Funktionen und ihre C#-Äquivalente

| Delphi | C# | Hinweise |
|--------|----|----------|
| `FloatToPunktString` | `ToString(CultureInfo.InvariantCulture)` | Datumskonvertierung |
| `SQL_Get(q, sql)` | `using (var reader = db.ExecuteReader(sql))` | Query ausführen |
| `SQL_Insert(q, sql)` | `db.ExecuteNonQuery(sql)` | SQL ausführen |
| `N_o_w` | `DateTime.Now` | Aktuelles Datum |
| `TDateTime` | `DateTime` | 1:1 Abbildung |
| `MAX(a, b)` | `Math.Max(a, b)` | Maximum |
| `IntToStr(i)` | `i.ToString()` | Integer zu String |
| `Pos(sub, str)` | `str.IndexOf(sub)` | Position suchen |

### Wichtige Konstanten aus DBMain.pas

```csharp
// Zeitkonstanten
public const int TAGMINUTEN = 1440;
public const double Stunde = 1.0 / 24.0;
public const double MINUTEN5 = 5.0 / TAGMINUTEN;
public const double MINUTEN10 = 10.0 / TAGMINUTEN;
public const double MINUTEN60 = Stunde;

// Maschinenstatus
public const int MaschLaeuft = 0;
public const int MaschRuesten = 1;
public const int MaschStillStoer = 2;
public const int MaschStillundefeniert = 4;
public const int MaschStillOrg = 5;

// Störarten
public const int saStoerung = 0;
public const int saJob = 1;
public const int saHinweis = 2;

// TPM-Störgruppen
public const int TPMAnlage = 0;
public const int TPMRuesten = 1;
public const int TPMLogistik = 2;
```

---

## 🔧 Technische Hinweise

1. **TDateTime in Delphi** ist ein Float (Tage seit 30.12.1899)
   - In C#: `DateTime` verwenden
   - Konvertierung: `DateTime.FromOADate(delphiDateTime)` und `delphiDateTime.ToOADate()`

2. **SQL-Funktionen** in Delphi verwenden oft `TCO_Query`
   - In C#: `CommonDB.ExecuteReader()` und `CommonDB.ExecuteNonQuery()`

3. **Thread-Synchronisation** in Delphi mit `TCriticalSection`
   - In C#: `lock` oder `SemaphoreSlim` verwenden

4. **INI-Dateien** in Delphi
   - In C#: `IConfiguration` mit appsettings.json

---

## GitHub Information
- **Repository**: MadIsBack/INCL
- **Branch**: main
- **Commits**: 13 Schritte
- **Status**: Alle Schritte 1-13 in main gemerged
- **Nächster Branch**: vibe/analyse-und-todos-8f8058
