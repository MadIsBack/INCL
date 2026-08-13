# 🧪 Finaler Integrationstest - Schritt 25

## Übersicht
Dieses Dokument beschreibt den finalen Integrationstest für den INCL-Service nach Schritt 24.

## Testumgebung

### Voraussetzungen
- .NET 8.0 SDK installiert
- Datenbankverbindung konfiguriert (appsettings.json)
- Alle NuGet-Pakete wiederhergestellt

### Testdatenbank
- Server: `includis.world` (oder lokaler Testserver)
- Datenbank: `includis` (oder Testdatenbank)
- Benutzer: `INCLUDIS` (oder Testbenutzer)
- Passwort: `comtas` (oder Testpasswort)

## Testschritte

---

## 1. Build-Test

### Ziel: Alle Projekte kompilieren ohne Fehler

```bash
cd INCLService.CSharp
dotnet restore
dotnet build --configuration Release
```

### Erwartetes Ergebnis
✅ **Keine Kompilierungsfehler**
✅ **Alle Projekte erfolgreich gebaut**

### Mögliche Fehler und Lösungen
| Fehler | Lösung |
|--------|--------|
| Fehlende NuGet-Pakete | `dotnet restore` ausführen |
| Syntaxfehler in Dateien | Dateien überprüfen und korrigieren |
| Abhängigkeitsprobleme | Projektreferenzen prüfen |

---

## 2. Unit-Tests (manuell)

### 2.1 S7MainService_CCC Tests

#### Test: CCC_InitAsync
```csharp
var ccc = new S7MainServiceCCC(logger, database, s7MainService);
await ccc.CCC_InitAsync(stoppingToken);
```
**Erwartet**: System-ID wird geschrieben, Lizenzen werden geprüft

#### Test: CCC_AuftragAutomatikStartAsync
```csharp
await ccc.CCC_AuftragAutomatikStartAsync(stoppingToken);
```
**Erwartet**: Aufträge werden automatisch gestartet (wenn AuftragAutomatikStart = true)

#### Test: In_SPSWerteDBAsync
```csharp
await ccc.In_SPSWerteDBAsync(stoppingToken);
```
**Erwartet**: SPS-Werte werden in die Datenbank geschrieben

#### Test: NeueSchichtAsync
```csharp
int alteSchicht;
bool result = await ccc.NeueSchichtAsync(out alteSchicht, stoppingToken);
```
**Erwartet**: Schichtwechsel wird erkannt (wenn SIWECHSEL-Eintrag existiert)

#### Test: CheckRoteLampeAusAsync
```csharp
bool result = await ccc.CheckRoteLampeAusAsync(stoppingToken);
```
**Erwartet**: Rote-Lampe-Einträge werden gelöscht, Rückgabewert = true wenn keine aktiven Einträge

---

## 3. Integrationstest (alle Services zusammen)

### 3.1 Services starten
```bash
cd INCLService.CSharp
dotnet run
```

### 3.2 Erwartetes Verhalten

#### MainService
- ✅ Startet als erster
- ✅ Initialisiert Datenbankverbindung
- ✅ Startet Event-Trigger-Timer
- ✅ Trigger Events für andere Services

#### S7MainService
- ✅ Startet nach MainService
- ✅ Lädt Konfiguration
- ✅ Initialisiert S7MainData
- ✅ Führt Timer1TimerAsync aus

#### CCCService
- ✅ Startet nach S7MainService
- ✅ Initialisiert CCC-Funktionen
- ✅ Führt periodisch CCC-Funktionen aus

#### ShiftService
- ✅ Wartet auf EVENT_SCHICHT
- ✅ Führt Schichtwechsel-Logik aus
- ✅ Ruft TPM_KorrekturAsync auf

#### SignalLogService
- ✅ Wartet auf EVENT_SIGNALLLOG
- ✅ Initialisiert Signal-Liste
- ✅ Führt Signal-Logging aus

#### AdditionalService
- ✅ Wartet auf EVENT_ZUSATZ
- ✅ Führt alle 20 Th_Zusatz-Funktionen aus

#### DBBackupService
- ✅ Wartet auf EVENT_DBBACKUP
- ✅ Erstellt Datenbank-Backups

---

## 4. Event-Kommunikation testen

### 4.1 Manuell Events triggern

#### Shift-Event triggern
```csharp
_serviceEvents.PulseEvent(ServiceEventSystem.EVENT_SCHICHT);
```
**Erwartet**: ShiftService führt Schichtwechsel-Logik aus

#### SignalLog-Event triggern
```csharp
_serviceEvents.PulseEvent(ServiceEventSystem.EVENT_SIGNALLLOG);
```
**Erwartet**: SignalLogService führt Signal-Logging aus

#### Additional-Event triggern
```csharp
_serviceEvents.PulseEvent(ServiceEventSystem.EVENT_ZUSATZ);
```
**Erwartet**: AdditionalService führt alle Funktionen aus

#### DBBackup-Event triggern
```csharp
_serviceEvents.PulseEvent(ServiceEventSystem.EVENT_DBBACKUP);
```
**Erwartet**: DBBackupService erstellt Backup

---

## 5. Datenbankverbindungen prüfen

### 5.1 CommonDB-Instanzen
- ✅ Jeder Service hat eigene CommonDB-Instanz
- ✅ Verbindung wird beim Start hergestellt
- ✅ Verbindung wird beim Stoppen geschlossen

### 5.2 SQL-Abfragen testen

#### Test: Maschinen-Daten laden
```csharp
string sql = "SELECT * FROM Maschinen WHERE Aktiv = 1";
using (var reader = _database.ExecuteReader(sql))
{
    while (await reader.ReadAsync(stoppingToken))
    {
        // Maschinen verarbeiten
    }
}
```
**Erwartet**: Alle aktiven Maschinen werden geladen

#### Test: SPSWERTE schreiben
```csharp
string sql = "INSERT INTO SPSWERTE (...) VALUES (...)";
await _database.ExecuteNonQueryAsync(sql, stoppingToken);
```
**Erwartet**: SPS-Werte werden erfolgreich geschrieben

#### Test: SIGNALLOG schreiben
```csharp
string sql = "INSERT INTO SIGNALLOG (...) VALUES (...)";
await _database.ExecuteNonQueryAsync(sql, stoppingToken);
```
**Erwartet**: Signal-Logs werden erfolgreich geschrieben

---

## 6. Logging testen

### 6.1 Serilog-Konfiguration
- ✅ Logs werden in `LOG\svc_{DBUser}_trace.log` geschrieben
- ✅ Fehler-Logs in `LOG\svc_{DBUser}_error.log`
- ✅ Debug-Logs in `LOG\svc_{DBUser}_debug.log`

### 6.2 Log-Inhalte prüfen
```bash
# Log-Dateien anzeigen
tail -f LOG\svc_INCLUDIS_trace.log
```

**Erwartet**:
- Startmeldungen aller Services
- Event-Trigger-Meldungen
- Datenbankverbindungsmeldungen
- Funktionsaufruf-Meldungen

---

## 7. Performance-Test

### 7.1 Timer-Intervalle prüfen
- ✅ MainService: 15 Sekunden
- ✅ S7MainService: 15 Sekunden
- ✅ ShiftService: 60 Sekunden
- ✅ SignalLogService: 30 Sekunden
- ✅ AdditionalService: 600 Sekunden
- ✅ DBBackupService: 3600 Sekunden

### 7.2 SQL-Abfragen optimieren
- ✅ INDEX auf häufig abgefragte Tabellen
- ✅ WHERE-Klauseln optimiert
- ✅ JOINs statt Unterabfragen

### 7.3 Connection Pooling
- ✅ Jeder Service hat eigene CommonDB-Instanz
- ✅ Verbindungen werden wiederverwendet

---

## 8. Fehlerbehandlung testen

### 8.1 Datenbankverbindungsfehler
- ✅ Service versucht, Verbindung wiederherzustellen
- ✅ Fehler werden geloggt
- ✅ Service läuft weiter

### 8.2 SQL-Fehler
- ✅ Fehler werden geloggt
- ✅ Service läuft weiter

### 8.3 Event-Timeouts
- ✅ Services warten auf Events
- ✅ Keine Deadlocks

---

## Testprotokoll

| Test | Datum | Ergebnis | Bemerkungen |
|------|-------|----------|-------------|
| Build-Test | | ❌ / ✅ | |
| Unit-Tests | | ❌ / ✅ | |
| Integrationstest | | ❌ / ✅ | |
| Event-Kommunikation | | ❌ / ✅ | |
| Datenbankverbindungen | | ❌ / ✅ | |
| Logging | | ❌ / ✅ | |
| Performance | | ❌ / ✅ | |
| Fehlerbehandlung | | ❌ / ✅ | |

---

## Nächste Schritte

1. **Fehler beheben** (falls vorhanden)
2. **Performance optimieren** (falls nötig)
3. **Deployment vorbereiten**
4. **Dokumentation finalisieren**
