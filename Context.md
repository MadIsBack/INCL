# INCL Service - Delphi zu C# .NET 8.0 Konvertierung

## Projektbeschreibung
Ein alter Windows-Dienst in Delphi geschrieben, der in eine moderne C# .NET 8.0 Anwendung konvertiert wird.
Das Original (voller Verlauf aller Sitzungen Schritte 1–25) ist unter `Context.md.original` gesichert.

## Konvertierungsrichtlinien

### Delphi-Konzept → C# .NET 8.0-Äquivalent

| Delphi-Konzept | C# .NET 8.0-Äquivalent | Hinweise |
|----------------|------------------------|----------|
| TService (Windows-Service) | BackgroundService + IHostedService | Konsolenanwendung mit HostBuilder (kein Windows-Service nötig). |
| TThread | BackgroundService | Jeder Thread wird ein BackgroundService. |
| TCriticalSection | lock oder SemaphoreSlim | Einfache Synchronisation. |
| TDateTime | DateTime | 1:1 Abbildung als Float. |
| IniFiles / Registry | appsettings.json + IConfiguration | Konfiguration über JSON-Datei. |
| LogMeldung | ILogger<T> (Serilog) | Integriert in .NET 8.0. |

### CommonDB
| Delphi-Konzept | C# .NET 8.0-Äquivalent | Hinweise |
|----------------|------------------------|----------|
| TCO_Query / TCO_Database | CommonDB (bereits vorhanden!) | Nutze die bestehende CommonDB-Bibliothek aus /commondb/. |
| CommonDb ist Äquivalent zu TCO_Database | Die Initialisierung sollte aus den Konstruktoren hervorgehen. |
| CommonReader / CommonCommand | Äquivalente zu TCO_Query | Anstatt bei TCO_Query alles einzeln zu machen, kann ein Reader über ExecuteReader(SQLStatement) erzeugt und iteriert werden. Um ein SQL Statement auszuführen reicht ein ExecuteNonQuery(SQLStatement) |
| Connection Pooling | Entfällt | Es gibt eine Instanz der CommonDB pro Service und dann werden die Reader einzeln erzeugt. |

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

## ✅ Fertiggestellte Schritte

### Schritt 1–15: Grundgerüst und Th_Zusatz-Portierung
- S7MainService.cs als BackgroundService angelegt
- Konfiguration über appsettings.json + IConfiguration
- ServiceEventSystem.cs mit ManualResetEventSlim für Events (EVENT_SCHICHT, EVENT_SIGNALLLOG, EVENT_ZUSATZ, EVENT_DBBACKUP)
- Th_Zusatz.pas → AdditionalService.cs / ArbeitUtils*.cs portiert
  - ArbeitUtils.cs, ArbeitUtils_ThZusatz.cs, ArbeitUtils_ThZusatz_Complete.cs, ArbeitUtils_ThZusatz_Final.cs
  - ZeitInMinuten, GetGruppe, IsMomentArbeitsFrei, ChangeDtCodeAsync, LaufzeitBerechnenAsync, CheckTaktLogAsync, CheckPackSchichtAsync
  - BookShortDelayAsync, ArbeitsFreiBuchenAsync, Palette_Rest_BerechnenAsync, CalcPackedlogFromShiftlogAsync, CheckAuftragKetteAsync, RescheduleAsync, AutoterminierungAsync

### Schritt 16–18: Integration
- Event-System in S7MainService integriert
- AdditionalService durch AdditionalService_Updated.cs ersetzt
- StartProgrammeAsync implementiert

### Schritt 19–21: S7MainService und Analyse
- S7MainModels.cs: SignalMaschineItem/List, MaschinenDaten, BarcodeDaten, S7MainData
- S7MainService.cs erweitert (DatenLesen, LoadMaschinenDaten, UpdateMaschinenSignale, etc.)
- Build-Fehler behoben (Schritt 21)

### Schritt 22: Logging und Deployment-Vorbereitung
- Serilog-Konfiguration für mandanten-spezifische Logs
- Finaler Integrationstest (IntegrationTest.md, TestIntegration.cs)
- Performance-Optimierungen, Deployment-Vorbereitung

### Schritt 23: Critical Control Center (CCC) Funktionen
- **S7MainService_CCC.cs** erstellt (Critical Control Center Funktionen)
- **CCCService.cs** als eigenständiger BackgroundService
- Program.cs um Service-Registrierung erweitert

### Schritt 24: ShiftService, SignalLogService, DBBackupService
- **ShiftService.cs** – detaillierte Schichtwechsel-Logik
- **SignalLogService.cs** – Signal-Überwachungslogik
- **DBBackupService.cs** – Datenbank-Backup-Logik

### Schritt 25: Finaler Integrationstest
- IntegrationTest.md (~6 KB)
- TestIntegration.cs (~11 KB)
- Testumgebung vorbereitet

### CCC_Init vollständig portiert (diese Sitzung)
**S7MainService_CCC.cs → CCC_InitAsync** portiert die originale `CCC_Init` aus `arbeit.pas` (ab Zeile 438):

1. **LoadMaschinenAsync** – Maschinenstammdaten aus `Maschine`-Tabelle (Lizenz, Kennung, KURZKENNUNG, Datenblock, MaschNr, AutoRuesten, MaschAktiv, Packgroesse, Warmtrennen, ZyklusLast, MaschinenTyp, GutVonBus, KombiSeparat, SpannzeitToleranz, Kopfgroesse, Pruefstation, StueckzahlDirekt)
2. **LoadAuftragsLaufzeitenAsync** – Summe der Laufzeiten aus `tpm_schicht` für geplante Aufträge (stat = 0)
3. **LoadPdeAuftraegeAsync** – Aktuelle PDE-Aufträge laden und Includis-Auftragsdaten füllen (BetriebsauftragNr, Sollwert, Stat, StartDatum, EndeDatum, Werkzeug, Kopfgroesse, KAVITAET_SOLL, etc.)
4. **ResetAuftraegeOhnePde** – Aufträge ohne PDE-Eintrag zurücksetzen ("kein aktueller Auftrag")
5. **LoadBdeDatenAsync** – BDE-Daten aus `MDE`-Tabelle (Erzeugt = '0')
6. **LoadArtikelZyklenAsync** – Artikelzyklen aus `Taktoption`-Tabelle + `saveeverycycle` aus Setup
7. **LoadStillstaendeAsync** – Stillstandsdefinitionen aus `TPM_Stillstaende`
8. **CCC_SchreibeSystemIDAsync** – System-ID in Setup-Tabelle schreiben
9. **CCC_CheckLicensesAsync** – Lizenzprüfung (Stub)

**Erweitertes Datenmodell** (`S7MainModels.cs`):
- `CavChange` – Äquivalent zu TCavChange
- `AuftragDaten` – Äquivalent zu TAuftrag (vollständige Feldliste)
- `BdeDaten` – Äquivalent zu TBDE
- `StillstandDaten` – Äquivalent zu TStillstand
- `MaschinenDaten` – erweitert um alle Felder aus TIncludis, die CCC_Init füllt
- `S7MainData.Stillstaende` und `S7MainData.First` hinzugefügt

Hilfsmethoden: `GetString`/`GetInt32` (DBNull-tolerant), `FormatString` (→Format_String), `GetDouble` (→GFloat), `MapPruefstation`, `EscapeSql`, `FindMaschinenIndexByDatenblock`/`ByLizenz`, `CCC_GetWerkzeugNr`.

---

## 📁 Projektstruktur

```
MadIsBack__INCL/
├── Context.md                  # Diese Datei (bereinigt)
├── Context.md.original         # Gesichertes Original (voller Verlauf Schritte 1–25)
├── commondb/                   # CommonDB-Bibliothek (vorgegeben)
│   ├── CommonDB.cs
│   ├── CommonReader.cs
│   ├── CommonCommand.cs
│   └── INCLUDIS.Utils.CommonDB.csproj
├── INCLService/                # Original-Delphi-Quellcode
│   ├── arbeit.pas              # CCC_Init, TAuftrag, TIncludis, etc.
│   ├── DBMain.pas              # TS7Main
│   └── Th_Schicht.pas, Th_SignalLog.pas, Th_DBBackup.pas, Th_Zusatz.pas
└── INCLService.CSharp/         # C# .NET 8.0 Konvertierung
    ├── INCLService.CSharp.csproj
    ├── Program.cs
    ├── appsettings.json
    ├── IntegrationTest.md
    ├── TestIntegration.cs
    ├── Models/
    │   ├── S7MainModels.cs     # MaschinenDaten, AuftragDaten, BdeDaten, StillstandDaten, CavChange
    │   ├── ArbeitModels.cs
    │   ├── ConfigurationModel.cs
    │   ├── SchichtModels.cs
    │   └── SPSModels.cs
    ├── Services/
    │   ├── S7MainService_CCC.cs   # CCC_Init + CCC-Funktionen (CCC_Init vollständig portiert)
    │   ├── S7MainService.cs
    │   ├── S7MainService_Extensions.cs
    │   ├── CCCService.cs          # BackgroundService für CCC
    │   ├── MainService.cs
    │   ├── ShiftService.cs
    │   ├── SignalLogService.cs
    │   ├── DBBackupService.cs
    │   ├── AdditionalService.cs
    │   ├── DatenService.cs
    │   └── TPM.cs
    └── Utilities/
        ├── SQLHelper.cs
        ├── ServiceEventSystem.cs
        └── ArbeitUtils*.cs
```

---

## 📌 Datei-zu-Datei-Implementierungsstatus

| Delphi-Datei | C#-Äquivalent | Status |
|--------------|---------------|--------|
| DBMain.pas (TS7Main) | S7MainService.cs, S7MainService_Extensions.cs | ✅ Grundgerüst portiert |
| arbeit.pas (CCC_*) | S7MainService_CCC.cs | ✅ CCC_Init vollständig portiert; restliche CCC_* als Stubs |
| Th_Schicht.pas | ShiftService.cs | ✅ Portiert |
| Th_SignalLog.pas | SignalLogService.cs | ✅ Portiert |
| Th_DBBackup.pas | DBBackupService.cs | ✅ Portiert |
| Th_Zusatz.pas | AdditionalService.cs, ArbeitUtils*.cs | ✅ Portiert |
| TCO_TPM | TPM.cs | ✅ Portiert |
| TCO_SPC | – | ⏭️ Entfällt (bewusst weggelassen) |
| TOC_INCMeldung | – | ⏭️ Entfällt (bewusst weggelassen) |

---

## 🚧 Offene Punkte

### Bekanntes Blocker-Problem: Build nicht kompilierbar
Das C#-Projekt lässt sich aktuell **nicht** kompilieren. Der gesamte C#-Code (S7MainService_CCC.cs, ArbeitUtils*.cs, SQLHelper.cs, etc.) verwendet eine API, die nicht zur CommonDB-Bibliothek passt:
- `_database.ExecuteReader(sql)` → CommonDB bietet nur `GetReader(sql)` / `GetCommonReader(sql)`
- `reader.ReadAsync(stoppingToken)` → CommonReader bietet nur synchrones `Read()`
- `_database.ExecuteNonQueryAsync(sql, stoppingToken)` → CommonDB bietet nur synchrones `ExecuteNonQuery(sql)`

**Lösungsmöglichkeiten:**
1. **Extension-Methods hinzufügen** in `commondb/CommonDbExtensions.cs`:
   - `ExecuteReader` als Alias für `GetReader`
   - `ReadAsync(CancellationToken)` als `Task.Run(() => reader.Read())`-Wrapper
   - `ExecuteNonQueryAsync(string, CancellationToken)` als Wrapper um `ExecuteNonQuery`
2. **Oder gesamten C#-Code umstellen** auf die native CommonDB-API (`GetReader`, `Read`, `ExecuteNonQuery`).

> Hinweis: dotnet SDK ist in der Sandbox nicht installiert, daher kann der Build nicht verifiziert werden.

### CCC_*-Funktionen (Priority 1 – produktionskritisch, nur CCC_Init ist vollständig)
Folgende CCC-Funktionen aus `arbeit.pas` sind in `S7MainService_CCC.cs` aktuell nur als **Stubs** vorhanden und müssen portiert werden:
- `CCC_Daten_Aktualisieren`
- `CCC_Daten_Schreiben` / `In_SPSWerteDB` / `Schreibe_SPS_Wert`
- `CCC_AuftragAutomatikStart` / `CCC_AuftragAutomatikStartVariabel`
- `CCC_Auftrag_Start_Barcode` (3 Scanner)
- `CCC_Check_Auftrag_Freigabe`
- `CCC_CheckUnterbrocheneAuftraege`
- `CCC_NeueSchicht` (Schichtwechsel-Erkennung)
- `CCC_CheckRoteLampeAus`
- `CCC_Job_Auftrag`, `CCC_BDE_Auftrag`, `CCC_Job_erzeugen`
- `CCC_TPM_*` (Stillstand, BCD-Meldung, Zustandswechsel, Signalauswertung)
- `CCC_Schreibe_Signallog`, `CCC_Schreibe_Maschinen_Status`
- `CCC_Check_*` (Menge_Gebucht, TerminOrder, Terminal_*, Warmtrennen, Job_Stueckzahl, StillstandNr_SPS, Block, Bypass, Pause)
- `CCC_MDEWerte_fuellen`, `CCC_MDE_Soll_Ist_Vergleich`
- `CCC_Erzeuge_Arbeitsplan`, `CCC_GetKennung`, `CCC_GetMaschIndex`, `CCC_GetMaschZustand`, `CCC_GetMaschNrLizenz`
- `CCC_Telegramm_Auswerten`, `CCC_Barcode_auswerten`
- `CCC_FehlerNr_auswertung`, `CCC_FehlerNr_Check`
- `CCC_A_Felder_Schicht_Berechnen` / `_Berechnen2`, `CCC_TaktzeitIstSchreiben`, `CCC_Taktzeit_Aus_Stamm_Update`
- `CCC_Auto_Ruesten2`, `CCC_AutoSetup2`, `CCC_Calc_R2_Times`
- `CCC_SetSchichtKonstante`, `CCC_Verpackt_aus_Ausschuss_Berechnen`, `CCC_Maschinen_Wartung`
- `CCC_FolgeAuftrag_Starten`, `CCC_InsertStillGehtEvent`
- `CCC_GetTPMSchichtAnfang`, `CCC_UeberwachungszeitBerechnen`, `CCC_QS_Jobs`
- `CCC_Auftrag_Starten_BCDCode`, `CCC_CheckRuestprot_Arbeitsfrei`, `CCC_Proc_Ruesten_AutoBuchen`
- `CheckJobPrestart`

### Lizenzprüfung
`CCC_CheckLicensesAsync` ist ein Stub (gibt immer true). Die originale Lizenzlogik aus Delphi muss portiert werden, falls Lizenzen relevant sind.

### Kavität-/Running-Change-Logik
Der komplexe Kavitätswechsel-Block in CCC_Init (KavitaetFromSPS, Kavitaet_laufender_Auftrag2/3, kavprot-Tabelle, RunningChangeEvents) ist vereinfacht portiert. Falls diese Logik produktiv benötigt wird, muss der Block aus `arbeit.pas` (Zeile ~700–780) detailliert nachportiert werden.

### Blockstillstand / Bypass
`Maschine_geblockt`-Logik (BLOCKSTILLSTAND, AUFTRAG_BLOCK, BypassMode) ist in CCC_Init aktuell nicht aktiviert. Original in `arbeit.pas` (Zeile ~515–535).

### Interrupted-Aufträge
`InterBezeichnung` wird vereinfacht gesetzt (= Bezeichnung). Die Original-Logik mit `INCL_MJAInterruptedDescr` und unterbrochenen Aufträgen (stat = 5) ist nicht portiert.

### Infrastruktur (optional)
- Docker-Container
- CI/CD-Pipeline
- Monitoring
- Produktionstest

---

## 🔧 Technische Hinweise

- **Delphi-Original**: `INCLService/` (arbeit.pas, DBMain.pas, Th_*.pas)
- **Konstanten** aus DBMain.pas (CSTUECKGESAMT, CBETRIEBSSTUNDEN, TAGMINUTEN, etc.) → in C# als Konstanten definieren
- **Anzahl_Masch** → `S7MainData.AnzahlMasch`
- **Includis[]** → `S7MainData.Includis` (List<MaschinenDaten>)
- **Stillstand[]** → `S7MainData.Stillstaende` (List<StillstandDaten>)
- **MaschZustand[]** → noch nicht portiert (falls benötigt)
- **First**-Flag → `S7MainData.First`
- **GFloat** → `GetDouble` (ersetzt Komma durch Punkt)
- **Format_String** → `FormatString` (int.TryParse)
- **SQL_Get / SQL_Insert** → `_database.ExecuteReader` / `_database.ExecuteNonQuery`

## GitHub Information
- Repository: `MadIsBack/INCL`
- URL: https://github.com/MadIsBack/INCL
- Branch: `main`
