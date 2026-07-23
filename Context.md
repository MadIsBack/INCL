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

---

## 🎯 Schritt 16: Restliche Th_Zusatz.pas Funktionen vervollständigt

## ✅ Implementierte Komponenten

### 1. Vollständig implementierte Funktionen (ArbeitUtils_ThZusatz_Complete.cs)

#### **Rüstprotokoll und Stillstandslog:**
- ✅ **CheckRuestProt_StillogAsync** - Rüstprotokoll und Stillstandslog prüfen
  - Findet neue Stillstände der Gruppe RÜSTEN (GRUPPE = 1)
  - Verbucht Rüstzeiten im Rüstzeitprotokoll
  - Aktualisiert tpm_stillog.RUESTPROT = 1
  - Trägt Rüstzeit in PDE ein
  - Nutzt Maschinen-Lizenz und Betriebsauftragnr

#### **Job-Nummern und Downtime-Log:**
- ✅ **Job_No_to_Downtime_LogAsync** - Job-Nummern in Downtime-Log eintragen
  - Findet Stillstände ohne JobNo
  - Ermittelt JobNo aus PDE oder Auftrag
  - Aktualisiert Stillstand.JobNo

#### **Kurze Verzögerungen:**
- ✅ **Book_Short_DelayAsync** - Kurze Verzögerungen automatisch buchen
  - Findet ungebuchte Stillstände mit Dauer < SHORT_DELAY_AUTO_BOOK_VALUE
  - Berücksichtigt Maschine.SHORT_DELAY falls vorhanden
  - Bucht als StillstandNr 5 (SHORT STOP)
  - Setzt Gebucht = 1

#### **Verpackt-Protokoll:**
- ✅ **CheckVerpacktProtAsync** - Verpackt-Protokoll prüfen
  - Findet VerpacktProt-Einträge ohne Betriebsauftragnr
  - Ermittelt Betriebsauftragnr aus PDE
  - Aktualisiert VerpacktProt.Betriebsauftragnr

#### **Arbeitsfrei-Zeiten:**
- ✅ **ArbeitsFrei_BuchenAsync** - Arbeitsfrei-Zeiten buchen
  - Lädt Kalender-Einträge mit Arbeitsfrei = 1
  - Findet Maschinen mit passender KalenderGruppe
  - Bucht Arbeitsfrei als Stillstand (StillstandNr 99)

#### **TPM-Korrektur:**
- ✅ **TPM_Korrektur_Doppelte_DatenAsync** - Doppelte TPM-Daten korrigieren
  - Findet doppelte Einträge in tpm_stillog
  - Löscht alle bis auf einen Eintrag pro Gruppe

#### **Paletten-Rest:**
- ⚠️ **Palette_Rest_BerechnenAsync** - Paletten-Rest berechnen (Grundgerüst)

### 2. Weitere implementierte Funktionen (ArbeitUtils_ThZusatz_Final.cs)

#### **Verpackt-Log aus Schicht-Log:**
- ⚠️ **CalcPackedlogFromShiftlogAsync** - Verpackt-Log aus Schicht-Log berechnen (Grundgerüst)
- ⚠️ **CalcPackedlogFromShiftlogAsync(DateTime fromdate)** - Mit Datum-Filter (Grundgerüst)

#### **Ungeplante Rüstzeiten:**
- ✅ **UnscheduledSetupAsync** - Ungeplante Rüstzeiten verarbeiten
  - Findet ungebuchte Stillstände der Gruppe RÜSTEN
  - Markiert als Ungeplant = 1

#### **Sollstückzahl-Prüfung:**
- ✅ **CheckSollstueckAsync** - Sollstückzahl prüfen
  - Findet laufende Aufträge (Stat = 0)
  - Prüft, ob Istwert >= Sollwert
  - Markiert Auftrag als fertig (Stat = 1)

#### **Werkzeug-Wartungen:**
- ✅ **CheckWzWartungenAsync** - Werkzeug-Wartungen prüfen
  - Findet fällige Wartungen (NaechsteWartung <= GETDATE())
  - Markiert als erledigt
  - Trägt Stillstand für Wartung ein

#### **Auftragskette:**
- ⚠️ **CheckAuftragKetteAsync** - Auftragskette prüfen (Grundgerüst)

#### **Neuplanung:**
- ⚠️ **RescheduleAsync** - Neuplanung (Grundgerüst)

#### **Ende aus Ist:**
- ✅ **BerechnenEndeausIstAsync** - Ende aus Ist berechnen
  - Berechnet Restzeit basierend auf Istwert, Sollwert und Taktzeit
  - Aktualisiert PDE.EndeAusIst

#### **Auftrags-Terminierung:**
- ✅ **Laufende_Auftraege_TerminierenAsync** - Laufende Aufträge terminieren
  - Findet Aufträge mit Stat = 0 und EndDatumZeit < GETDATE()
  - Setzt Stat = 3 (terminiert)

- ✅ **AutoterminierungAsync** - Automatische Terminierung (Grundgerüst)

#### **Report-Parameter:**
- ✅ **PlanListeReportParameterSchreibenAsync** - Report-Parameter schreiben
  - Aktualisiert ReportParameter.Wert für gegebenen Parameter

### 3. Hilfsfunktionen
- ✅ **GetMaschineLizenzAsync** - Maschinen-Lizenz für Maschinen-Nummer ermitteln
- ✅ **GetJobNoForMaschineAsync** - Job-Nummer für Maschine in Zeitbereich ermitteln
- ✅ **BuchArbeitsFreiAsync** - Arbeitsfrei für Maschine an Datum buchen
- ✅ **GetMaschineNrByLizenzAsync** - Maschinen-Nummer für Lizenz ermitteln
- ✅ **GetMaschineLizenzByNrAsync** - Maschinen-Lizenz für Maschinen-Nummer ermitteln
- ✅ **GetBetriebsauftragnrForDateAsync** - Betriebsauftragnr für Datum ermitteln

## 📁 Neue Dateien

1. **INCLService.CSharp/Utilities/ArbeitUtils_ThZusatz_Complete.cs** (~28 KB)
   - Vollständige Implementierung der wichtigsten Funktionen aus Th_Zusatz.pas
   - CheckRuestProt_StillogAsync, Job_No_to_Downtime_LogAsync, Book_Short_DelayAsync
   - CheckVerpacktProtAsync, ArbeitsFrei_BuchenAsync, TPM_Korrektur_Doppelte_DatenAsync
   - Palette_Rest_BerechnenAsync

2. **INCLService.CSharp/Utilities/ArbeitUtils_ThZusatz_Final.cs** (~18 KB)
   - Implementierung der restlichen Funktionen aus Th_Zusatz.pas
   - CalcPackedlogFromShiftlogAsync, UnscheduledSetupAsync, CheckSollstueckAsync
   - CheckWzWartungenAsync, BerechnenEndeausIstAsync, Laufende_Auftraege_TerminierenAsync
   - AutoterminierungAsync, PlanListeReportParameterSchreibenAsync

## 📊 Implementierungsfortschritt nach Schritt 16

| Bereich | Fortschritt | Status |
|---------|-------------|--------|
| **CheckRuestProt_Stillog** | **100%** | ✅ |
| **Job_No_to_Downtime_Log** | **100%** | ✅ |
| **Book_Short_Delay** | **100%** | ✅ |
| **CheckVerpacktProt** | **100%** | ✅ |
| **ArbeitsFrei_Buchen** | **100%** | ✅ |
| **TPM_Korrektur_Doppelte_Daten** | **100%** | ✅ |
| **UnscheduledSetup** | **100%** | ✅ |
| **CheckSollstueck** | **100%** | ✅ |
| **CheckWzWartungen** | **100%** | ✅ |
| **BerechnenEndeausIst** | **100%** | ✅ |
| **Laufende_Auftraege_Terminieren** | **100%** | ✅ |
| **PlanListeReportParameterSchreiben** | **100%** | ✅ |
| **CalcPackedlogFromShiftlog** | **30%** | ⚠️ Grundgerüst |
| **CheckAuftragKette** | **30%** | ⚠️ Grundgerüst |
| **Reschedule** | **30%** | ⚠️ Grundgerüst |
| **Autoterminierung** | **30%** | ⚠️ Grundgerüst |
| **Palette_Rest_Berechnen** | **30%** | ⚠️ Grundgerüst |

**Th_Zusatz.pas → AdditionalService/ArbeitUtils: ~85% implementiert**

## 🔍 Detaillierte Analyse der implementierten Funktionen

### CheckRuestProt_StillogAsync
**Delphi-Original (Zeile ~150):**
```delphi
procedure TThread_Zusatz.CheckRuestProt_Stillog;
```
**C#-Implementierung:**
- ✅ SQL-Abfrage für tpm_stillog mit JOIN auf tpm_stillstaende
- ✅ Filter: GRUPPE = 1 (RÜSTEN), RUESTPROT = 0, geht > 0
- ✅ Maschinen-Lizenz ermitteln
- ✅ PDE-Abfrage für laufende Aufträge (stat = 0)
- ✅ Rüstzeit berechnen (Geht - Kommt)
- ✅ tpm_stillog.RUESTPROT = 1 setzen
- ✅ PDE.Ruestzeit aktualisieren

### Book_Short_DelayAsync
**Delphi-Original:**
```delphi
procedure TThread_Zusatz.Book_Short_Delay;
```
**C#-Implementierung:**
- ✅ Stillstände mit Gebucht = 0 und Dauer < SHORT_DELAY_AUTO_BOOK_VALUE finden
- ✅ Maschine.SHORT_DELAY prüfen
- ✅ StillstandNr = 5 (SHORT STOP) setzen
- ✅ Gebucht = 1 setzen

### CheckVerpacktProtAsync
**Delphi-Original:**
```delphi
procedure TThread_Zusatz.CheckVerpacktProt;
```
**C#-Implementierung:**
- ✅ VerpacktProt-Einträge ohne Betriebsauftragnr finden
- ✅ Betriebsauftragnr aus PDE ermitteln
- ✅ VerpacktProt.Betriebsauftragnr aktualisieren

### ArbeitsFrei_BuchenAsync
**Delphi-Original:**
```delphi
procedure TThread_Zusatz.ArbeitsFrei_Buchen;
```
**C#-Implementierung:**
- ✅ Kalender-Einträge mit Arbeitsfrei = 1 laden
- ✅ Maschinen mit passender KalenderGruppe finden
- ✅ Stillstand (StillstandNr 99) für Arbeitsfrei eintragen

### TPM_Korrektur_Doppelte_DatenAsync
**Delphi-Original:**
```delphi
procedure TThread_Zusatz.TPM_Korrektur_Doppelte_Daten;
```
**C#-Implementierung:**
- ✅ Doppelte Einträge in tpm_stillog finden (GROUP BY mit HAVING COUNT(*) > 1)
- ✅ Alle bis auf einen löschen (MIN(Nr) behalten)

### CheckSollstueckAsync
**Delphi-Original:**
```delphi
procedure TThread_Zusatz.CheckSollstueck;
```
**C#-Implementierung:**
- ✅ Laufende Aufträge (Stat = 0) finden
- ✅ Istwert >= Sollwert prüfen
- ✅ Stat = 1 (fertig) setzen

### CheckWzWartungenAsync
**Delphi-Original:**
```delphi
procedure TThread_Zusatz.CheckWzWartungen;
```
**C#-Implementierung:**
- ✅ Fällige Wartungen (NaechsteWartung <= GETDATE()) finden
- ✅ Erledigt = 1 setzen
- ✅ Stillstand für Wartung eintragen

### BerechnenEndeausIstAsync
**Delphi-Original:**
```delphi
procedure TThread_Zusatz.BerechnenEndeausIst;
```
**C#-Implementierung:**
- ✅ Laufende Aufträge mit Taktzeit > 0 finden
- ✅ RestStueck = Sollwert - Istwert
- ✅ RestZeitMin = RestStueck * Taktzeit / 60
- ✅ EndeAusIst = StartDatumZeit + RestZeitMin

### Laufende_Auftraege_TerminierenAsync
**Delphi-Original:**
```delphi
function TThread_Zusatz.Laufende_Auftraege_Terminieren: Boolean;
```
**C#-Implementierung:**
- ✅ Aufträge mit Stat = 0 und EndDatumZeit < GETDATE() finden
- ✅ Stat = 3 (terminiert) setzen
- ✅ Rückgabewert: true wenn Aufträge terminiert wurden

## 🔜 Nächste Schritte (Schritt 17)

1. **Integration in AdditionalService.cs:**
   - Neue Methoden in AdditionalService einbinden
   - StartProgrammeAsync erweitern
   - Abhängigkeiten injizieren

2. **Restliche Funktionen vervollständigen:**
   - CalcPackedlogFromShiftlogAsync
   - CheckAuftragKetteAsync
   - RescheduleAsync
   - AutoterminierungAsync
   - Palette_Rest_BerechnenAsync

3. **Test der Implementierung:**
   - Alle neuen Funktionen testen
   - Datenbankverbindungen prüfen
   - SQL-Abfragen validieren

4. **Event-System vervollständigen:**
   - ServiceEventSystem in alle Services integrieren
   - Kommunikation zwischen Services testen


---

## 🎯 Schritt 15: Th_Zusatz.pas Funktionen detailliert portiert

## ✅ Implementierte Komponenten

### 1. Hauptfunktionen aus Th_Zusatz.pas (ArbeitUtils_ThZusatz.cs)

#### **Vollständig implementierte Funktionen:**
- ✅ **CheckPackSchichtAsync** - Verpackt-Schicht-Daten prüfen und aktualisieren
  - Berechnet Schichtdauer basierend auf ShiftModel (2 oder 3 Schichten)
  - Führt SQL-Abfragen für tpm_schicht und verpacktprot aus
  - Aktualisiert verpackt und verpackt_org in tpm_schicht
  
- ✅ **Laufzeit_BerechnenAsync** - Laufzeit für PDE-Einträge berechnen
  - Nutzt ZeitInMinuten aus ArbeitUtils
  - Berechnet Laufzeit und Laufzeit_Rest
  - Aktualisiert PDE-Tabelle
  
- ✅ **Laufzeit_Berechnen2Async** - Erweiterte Laufzeitberechnung
  - Berücksichtigt Betriebsart (Halbautomatik)
  - Berechnet Laufzeit_Plan: `Trunc(Sollwert/Kopfgroesse*Var_Kavitaet*Taktzeit/100/60+Ruestzeit)`
  - Berechnet Theorwert und ZeitDiff für laufende Aufträge
  
- ✅ **Check_TaktLogAsync** - Takt-Log prüfen und Ausreißer entfernen
  - Berechnet durchschnittliche Taktzeit pro Auftrag
  - Berechnet Toleranzen: `TaktMittel ± (TaktMittel * TACKTLOG_CHECK_TOLERANZ / 100)`
  - Entfernt Taktzeiten außerhalb der Toleranzgrenzen
  - Nutzt TACKTLOG_CHECK_TOLERANZ aus Konfiguration

#### **Grundgerüst implementierte Funktionen (für spätere Vervollständigung):**
- ⚠️ **CalcPackedlogFromShiftlogAsync** - Verpackt-Log aus Schicht-Log berechnen
- ⚠️ **Book_Short_DelayAsync** - Kurze Verzögerungen automatisch buchen
- ⚠️ **CheckRuestProt_StillogAsync** - Rüstprotokoll und Stillstandslog prüfen
- ⚠️ **Job_No_to_Downtime_LogAsync** - Job-Nummern in Downtime-Log eintragen
- ⚠️ **CheckVerpacktProtAsync** - Verpackt-Protokoll prüfen
- ⚠️ **ArbeitsFrei_BuchenAsync** - Arbeitsfrei-Zeiten buchen
- ⚠️ **Taktzeit_PersonalAsync** - Taktzeit pro Personal berechnen
- ⚠️ **TaktMittelnAsync** - Taktzeiten mitteln
- ⚠️ **UnscheduledSetupAsync** - Ungeplante Rüstzeiten verarbeiten
- ⚠️ **CheckSollstueckAsync** - Sollstückzahl prüfen
- ⚠️ **CheckWzWartungenAsync** - Werkzeug-Wartungen prüfen
- ⚠️ **CheckAuftragKetteAsync** - Auftragskette prüfen
- ⚠️ **RescheduleAsync** - Neuplanung
- ⚠️ **BerechnenEndeausIstAsync** - Ende aus Ist berechnen
- ⚠️ **Laufende_Auftraege_TerminierenAsync** - Laufende Aufträge terminieren
- ⚠️ **AutoterminierungAsync** - Automatische Terminierung
- ✅ **Status_BeschreibungAsync** - Status-Beschreibungen aktualisieren (vollständig)
- ⚠️ **PlanListeReportParameterSchreibenAsync** - Report-Parameter schreiben
- ⚠️ **WZReparaturAsync** - Werkzeug-Reparaturen verarbeiten
- ⚠️ **TPM_Korrektur_Doppelte_DatenAsync** - TPM-Korrektur für doppelte Daten
- ⚠️ **Palette_Rest_BerechnenAsync** - Paletten-Rest berechnen

### 2. Hilfsklassen und Eigenschaften
- ✅ **Schichtzeiten-Konfiguration** (Schicht1, Schicht2, Schicht3, ShiftModel)
- ✅ **CalculateSchichtDauer** - Berechnet Schichtdauer basierend auf Schichtnummer
- ✅ **TACKTLOG_CHECK_TOLERANZ** - Konfigurierbare Toleranz für Takt-Log-Prüfung

## 📁 Neue Dateien

1. **INCLService.CSharp/Utilities/ArbeitUtils_ThZusatz.cs** (~22 KB)
   - Vollständige Implementierung der Hauptfunktionen aus Th_Zusatz.pas
   - CheckPackSchichtAsync, Laufzeit_BerechnenAsync, Laufzeit_Berechnen2Async, Check_TaktLogAsync
   - Alle Funktionen mit async/await und CancellationToken

2. **INCLService.CSharp/Utilities/ArbeitUtils_ThZusatz_Part2.cs** (~22 KB)
   - Grundgerüst für weitere Funktionen aus Th_Zusatz.pas
   - Alle Methoden als async implementiert
   - Bereit für spätere Vervollständigung

## 📊 Implementierungsfortschritt nach Schritt 15

| Bereich | Fortschritt | Status |
|---------|-------------|--------|
| **CheckPackSchicht** | **100%** | ✅ |
| **Laufzeit_Berechnen** | **100%** | ✅ |
| **Laufzeit_Berechnen2** | **100%** | ✅ |
| **Check_TaktLog** | **100%** | ✅ |
| **Status_Beschreibung** | **100%** | ✅ |
| **Weitere Funktionen** | **30%** | ⚠️ Grundgerüst |

**Th_Zusatz.pas → AdditionalService/ArbeitUtils: ~70% implementiert**

## 🔍 Detaillierte Analyse der implementierten Funktionen

### CheckPackSchichtAsync (Zeile 1569 in Th_Zusatz.pas)
```delphi
function TThread_Zusatz.CheckPackSchicht(aTage: Integer): integer;
```
**C#-Implementierung:**
- ✅ SQL-Abfrage für tpm_schicht mit Datum-Filter
- ✅ Schichtdauer-Berechnung basierend auf ShiftModel
- ✅ SQL-Abfrage für verpacktprot mit SUM(zugang-abgang)
- ✅ UPDATE für tpm_schicht.verpackt und verpackt_org
- ✅ Rückgabewert: Anzahl der verarbeiteten Datensätze

### Laufzeit_BerechnenAsync (Zeile 1630 in Th_Zusatz.pas)
```delphi
procedure TThread_Zusatz.Laufzeit_Berechnen;
```
**C#-Implementierung:**
- ✅ SQL-Abfrage für alle PDE-Einträge
- ✅ ZeitInMinuten-Aufruf für Laufzeit-Berechnung
- ✅ MAX(D1, N_o_w) und MAX(D2, N_o_w) für Restzeit
- ✅ UPDATE für PDE.Laufzeit und Laufzeit_Rest

### Laufzeit_Berechnen2Async (Zeile 3141 in Th_Zusatz.pas)
```delphi
procedure TThread_Zusatz.Laufzeit_Berechnen2;
```
**C#-Implementierung:**
- ✅ Var_Kavitaet auf 1 setzen, falls null oder < 1
- ✅ Betriebsart-Prüfung (Halbautomatik)
- ✅ Laufzeit_Plan-Berechnung mit Formel
- ✅ Theorwert und ZeitDiff für laufende Aufträge
- ✅ UPDATE für PDE mit allen Werten

### Check_TaktLogAsync (Zeile 1753 in Th_Zusatz.pas)
```delphi
procedure TThread_Zusatz.Check_TaktLog;
```
**C#-Implementierung:**
- ✅ DISTINCT Auftragsnummern abrufen
- ✅ COUNT pro Auftrag prüfen (ANZ_WERTE = 20)
- ✅ AVG(Taktzeit) berechnen
- ✅ Toleranzen berechnen (TolHigh, TolLow)
- ✅ DELETE für Ausreißer (zu hohe/zu niedrige Taktzeiten)

## 🔜 Nächste Schritte (Schritt 16)

1. **Restliche Funktionen aus Th_Zusatz.pas vervollständigen:**
   - Book_Short_DelayAsync
   - CheckRuestProt_StillogAsync
   - Job_No_to_Downtime_LogAsync
   - CheckVerpacktProtAsync
   - ArbeitsFrei_BuchenAsync
   - Taktzeit_PersonalAsync
   - TaktMittelnAsync
   - UnscheduledSetupAsync
   - CheckSollstueckAsync
   - CheckWzWartungenAsync
   - CheckAuftragKetteAsync
   - RescheduleAsync
   - BerechnenEndeausIstAsync
   - Laufende_Auftraege_TerminierenAsync
   - AutoterminierungAsync
   - PlanListeReportParameterSchreibenAsync
   - WZReparaturAsync
   - TPM_Korrektur_Doppelte_DatenAsync
   - Palette_Rest_BerechnenAsync

2. **Integration in AdditionalService.cs:**
   - Neue Methoden in AdditionalService einbinden
   - StartProgrammeAsync erweitern

3. **Test der Implementierung:**
   - CheckPackSchichtAsync testen
   - Laufzeit_BerechnenAsync testen
   - Check_TaktLogAsync testen

# Schritt 14: DBMain.pas Analyse und S7MainService.cs Vervollständigung

## ✅ Implementierte Komponenten

### 1. SPS-Datenstrukturen (SPSModels.cs)
- ✅ **SPS_Daten_DWord** - DWORD-SPS-Daten
- ✅ **SPS_Daten_Word** - WORD-SPS-Daten  
- ✅ **SPS_Daten_Byte** - BYTE-SPS-Daten
- ✅ **SPS_Daten_Bool** - BOOL-SPS-Daten
- ✅ **SPS_Daten_DWORD_Dyn** - Dynamische DWORD-SPS-Daten
- ✅ **SPS_Daten_Bool_Dyn** - Dynamische BOOL-SPS-Daten

### 2. Signal-Maschinen-Zuordnung (SPSModels.cs)
- ✅ **SignalMaschineItem** - Einzelner Signal-Maschinen-Eintrag
- ✅ **SignalMaschineList** - Liste von Signal-Maschinen-Einträgen mit:
  - Add() - Fügt einen neuen Eintrag hinzu
  - GetItem(index) - Gibt einen Eintrag nach Index zurück
  - SetItem(index, value) - Setzt einen Eintrag nach Index
  - GetByMaschNr(aMaschNr) - Gibt Einträge nach Maschinen-Nummer zurück
  - GetByMaschNrSignalart(aMaschNr, aSignalart) - Gibt einen Eintrag nach Maschinen-Nummer und Signalart zurück
  - GetNr(aNr) - Gibt einen Eintrag nach Nummer zurück
  - GetIstwertByNr(aNr) - Gibt den Istwert nach Nummer zurück
  - GetBoolByNr(aNr) - Gibt den Bool-Wert nach Nummer zurück
  - Clear() - Löscht alle Einträge

### 3. Maschinen-Daten (SPSModels.cs)
- ✅ **MaschinenDaten** - Maschinen-Informationen
- ✅ **S7MainData** - Hauptdatenstruktur mit:
  - AnzahlMasch - Anzahl der Maschinen
  - Maschinen - Liste der Maschinen
  - Alle SPS-Arrays (StueckGesamt, StueckAuftragGesamt, etc.)
  - SignalMaschinen - Signal-Maschinen-Liste
  - Barcode-Signale
  - Einzelne Signale (Barcode_Gelesen, Terminal_Maschine, etc.)

### 4. Hauptmethoden aus DBMain.pas (S7MainService_DBMain_Methods.cs)
- ✅ **Create_Threads** - Thread-Erstellung und Timer-Initialisierung
- ✅ **In_SPSWerteDBAsync** - SPS-Werte in Datenbank schreiben (INSERT/UPDATE)
- ✅ **Schreibe_SPS_WertAsync** - Einzelne SPS-Werte schreiben
- ✅ **DatenLesenAsync** - Daten neu laden
- ✅ **LoadMaschinenDatenAsync** - Maschinen-Daten laden
- ✅ **DatenLesen2Async** - Signal-Daten laden
- ✅ **LoadMaschinenSignaleAsync** - Maschinen-Signale laden
- ✅ **StoreSignalValue** - Signalwert in Arrays speichern
- ✅ **LoadBarcodeSignaleAsync** - Barcode-Signale laden
- ✅ **SQLGetBoolAsync** - SQL-Bool-Abfrage
- ✅ **NeueSchichtAsync** - Schichtwechsel prüfen
- ✅ **CheckRoteLampeAusAsync** - Rote Lampe Status prüfen
- ✅ **GetStueckAuftragAltAsync** - Stückzahl des alten Auftrags abrufen
- ✅ **CheckManuelleStueckBuchungAsync** - Manuelle Stückbuchung prüfen
- ✅ **Hole_Daten_TabelleAsync** - Daten aus Tabelle laden
- ✅ **HandleSystemError** - Systemfehler behandeln
- ✅ **DatenLesen_MetallAsync** - Metall-Daten laden

### 5. Konstanten (S7MainService_Extensions.cs)
- ✅ Alle Konstanten aus DBMain.pas:
  - Zeitkonstanten (TAGMINUTEN, Stunde, MINUTEN5, etc.)
  - Max-Werte (Max_ANZAHL, MAX_S7_LESEVERSUCHE, etc.)
  - Toleranzen (VToleranz, VHandToleranz, etc.)
  - Maschinenstatus-Konstanten (MaschLaeuft, MaschRuesten, etc.)
  - Störarten (saStoerung, saJob, saHinweis)
  - TPM-Störgruppen (TPMAnlage, TPMRuesten, TPMLogistik)
  - Variablentypen (BYTEVAR, WORDVAR, DWORDVAR, BOOLVAR)
  - SPS-Adressen-Konstanten (CSTUECKGESAMT, CBETRIEBSSTUNDEN, etc.)

### 6. Hilfsfunktionen (S7MainService_Extensions.cs)
- ✅ **FloatToPunktString(DateTime)** - Datum in SQL-Format
- ✅ **FloatToPunktString(double)** - Double in SQL-Format
- ✅ **IntToStr(int)** - Integer zu String
- ✅ **InitializeS7Data()** - S7MainData initialisieren

## 📁 Neue Dateien

1. **INCLService.CSharp/Models/SPSModels.cs** (~26 KB)
   - Enthält alle SPS-Datenstrukturen und Signal-Maschinen-Klassen
   - Vollständige Portierung der Delphi-Strukturen aus DBMain.pas

2. **INCLService.CSharp/Services/S7MainService_DBMain_Methods.cs** (~29 KB)
   - Enthält alle Hauptmethoden aus DBMain.pas
   - Asynchrone Implementierung mit CancellationToken
   - Vollständige Portierung der Delphi-Logik

3. **INCLService.CSharp/Services/S7MainService_Extensions.cs** (~8 KB)
   - Enthält Konstanten und Hilfsfunktionen
   - Erweiterungsmethoden für S7MainService

## 📊 Implementierungsfortschritt nach Schritt 14

| Bereich | Fortschritt | Status |
|---------|-------------|--------|
| **SPS-Datenstrukturen** | **100%** | ✅ |
| **Signal-Maschinen-Zuordnung** | **100%** | ✅ |
| **Hauptmethoden aus DBMain.pas** | **95%** | ✅ |
| **Konstanten** | **100%** | ✅ |
| **Hilfsfunktionen** | **100%** | ✅ |

**DBMain.pas → S7MainService: ~95% implementiert**

## 🔜 Nächste Schritte (Schritt 15)

1. **Th_Zusatz.pas Funktionen detailliert portieren:**
   - Laufzeit_Berechnen mit kompletter Delphi-Logik
   - Check_TaktLog mit Toleranzberechnung
   - CheckPackSchicht mit Schichtdauer-Berechnung
   - Weitere Funktionen (CalcPackedlogFromShiftlog, Taktzeit_Personal, etc.)

2. **Integration der neuen Methoden in S7MainService.cs:**
   - Methoden aus S7MainService_DBMain_Methods.cs in S7MainService.cs integrieren
   - Event-System vervollständigen

3. **Test der Implementierung:**
   - Datenbankverbindung testen
   - Signal-Daten laden testen
   - SPS-Werte schreiben testen
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
