# Mermaid Diagram Audit — Plan

> Branch: `test/fix-broken-tests-220` | Created: 2026-06-28

## Befund

### Gesamt: 22 Mermaid-Diagramme

- **15 standalone Dateien** in `doc/images/`
- **7 eingebettet** in anderen Docs (architecture.md ×4, datasafe-status-workflow.md ×1, development.md ×1, architecture.md embedded in registry link)

---

## 1. Referenzierte Diagramme (in Verwendung)

Diese 6 Dateien in `doc/images/` sind aus anderen Docs verlinkt:

| Datei | Referenziert von | Inhalt | Genauigkeit |
|-------|------------------|--------|-------------|
| `config-workflow-highlevel.md` | `doc/architecture.md` | 5-layer Config-Hierarchie | ✅ Korrekt |
| `oraenv-workflow-highlevel.md` | `doc/architecture.md` | oraenv Workflow High-Level | ✅ Korrekt |
| `oraup-workflow-highlevel.md` | `doc/architecture.md` | oraup Workflow High-Level | ✅ Korrekt |
| `plugin-system.md` | `doc/architecture.md`, `doc/README.md` | Plugin-Lifecycle, 13 Funktionen | ✅ Korrekt |
| `registry-api-flow.md` | `doc/architecture.md`, `doc/README.md` | Registry API Datenfluss | ✅ Korrekt |
| `README.md` (Index) | `doc/architecture.md` | Index aller 14 Diagramme | ✅ Korrekt |

---

## 2. Verwaiste Diagramme (keine Verlinkung)

Diese 9 Dateien existieren in `doc/images/`, werden aber nirgends referenziert:

| Datei | Inhalt | Empfehlung |
|-------|--------|------------|
| `architecture-system.md` | Vollständige Systemarchitektur (8 Subsysteme) | Einbetten in `doc/architecture.md` |
| `phase1-3-libraries.md` | 9 Plugins + Env Management Libraries | Einbetten in `doc/architecture.md` |
| `config-sequence.md` | Sequenzdiagramm: Parser→Builder→Validator | Einbetten in `doc/architecture.md` |
| `config-workflow-detailed.md` | Detail-Flow mit Funktionsnamen | Einbetten in `doc/architecture.md` |
| `config-hierarchy.md` | 6-Level Config (Duplikat von -highlevel) | **Löschen** (redundant) |
| `installation-flow.md` | 3-Mode Installer-Flow | Einbetten in `doc/development.md` |
| `oraenv-workflow-detailed.md` | Detail-Flow mit Funktionsnamen | Einbetten in `doc/architecture.md` |
| `oraenv-flow.md` | Kompletter oraenv-Flow | **Löschen** (Duplikat von -workflow-*) |
| `oraup-workflow-detailed.md` | Detail-Flow mit Variablennamen | Einbetten in `doc/architecture.md` |

---

## 3. Korrekturbedarf

| # | Datei | Problem | Fix |
|---|-------|---------|-----|
| A | `doc/images/architecture-system.md` | `weblogic_plugin.sh (planned)` — existiert bereits als Stub | → `(stub)` |
| B | Alle Diagramme mit "6 Environment Libraries" | `oradba_env_output.sh` fehlt (existiert, wird geladen) | → "7 Environment Libraries" |
| C | `doc/architecture.md` Zeile mit `![Registry API Flow](images/registry-api-flow.md)` | Kaputte Bildsyntax — .md-Dateien rendern nicht als Bilder | → In normalen Link umwandeln |

---

## Aufgaben

### Phase 1 — Korrekturen (Quick Wins)

- [x] Fix A: `architecture-system.md` — weblogic `(planned)` → `(stub)`
- [x] Fix B: Alle Diagramme — `oradba_env_output.sh` als 7. Env Library ergänzen (architecture-system.md + architecture.md)
- [x] Fix C: `doc/architecture.md` — kaputten `![...](.md)` Link reparieren
- [x] Fix D (bonus): `doc/architecture.md` embedded Diagramm — 6 Plugins → 9, 8 Funktionen → 13

### Phase 2 — Verwaiste Diagramme verlinken

- [x] `architecture-system.md` + `phase1-3-libraries.md` — Link in "Interactive Architecture Diagrams"
- [x] `config-sequence.md` + `config-workflow-detailed.md` — Link in "Interactive Architecture Diagrams"
- [x] `oraenv-workflow-detailed.md` + `oraup-workflow-detailed.md` — Link in "Interactive Architecture Diagrams"
- [x] `installation-flow.md` — Link in `doc/development.md` (Sektion "Build Process")

### Phase 3 — Bereinigung

- [x] `doc/images/config-hierarchy.md` gelöscht (Duplikat von config-workflow-highlevel)
- [x] `doc/images/oraenv-flow.md` gelöscht (Duplikat von oraenv-workflow-*)
- [x] `doc/images/README.md` aktualisiert (gelöschte Dateien entfernt, Output-Farbe ergänzt)

---

## Zusammenfassung

```
Gesamt Diagramme:   22
Referenziert:        6  (standalone, korrekt verlinkt)
Eingebettet:         7  (direkt in Doc-Dateien)
Verwaist:            9  (kein eingehender Link)
  → Einbetten:       7
  → Löschen:         2  (Duplikate)
Korrekturbedarf:     3  (A: weblogic-Status, B: Lib-Anzahl, C: kaputte Syntax)
```
