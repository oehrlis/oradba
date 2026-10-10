# Review-Register - oradba

> Gepflegt von /repo-audit. IDs werden nie neu vergeben. Keine Task-Syntax.

- repo: oradba

## Befunde

### RA-oradba-001 - Kein gitleaks in CI (History-Gate fehlt)

- status: offen
- schwere: hoch
- rolle: security
- ort: .github/workflows/ci.yml
- regel: ci-gate
- gefunden: 2026-10-10
- beleg: .github/workflows/ci.yml - kein gitleaks-Step in ci.yml, ci.yml, release.yml

### RA-oradba-002 - .claude/settings.local.json nicht in .gitignore

- status: behoben
- schwere: niedrig
- rolle: security
- ort: .gitignore
- regel: claude-hygiene
- gefunden: 2026-10-10
- beleg: .gitignore:104-121 - .claude/*.md, .claude/settings.json vorhanden, aber nicht .claude/settings.local.json
- erledigt: 2026-10-10
- commit: 2c00e93

### RA-oradba-003 - Markdown-Lint-Fehler in Archiv-Releasenote

- status: offen
- schwere: niedrig
- rolle: doku-tests
- ort: doc/releases/v0.19.0.md
- regel: lint-gate
- gefunden: 2026-10-10
- beleg: doc/releases/v0.19.0.md:350 - MD012 multiple consecutive blank lines

### RA-oradba-004 - Plugin-Loader: direkte Source-Sites umgehen Isolation-Wrapper (CF-004)

- status: offen
- schwere: hoch
- rolle: kern
- ort: src/bin/oraenv.sh
- orte: src/bin/oraenv.sh, src/bin/oradba_env.sh, src/bin/oradba_dsctl.sh
- regel: abstraction
- gefunden: 2026-10-10
- beleg: oraenv.sh:857, oraenv.sh:1029, oraenv.sh:1146 - source plugin_file direkt; oradba_env.sh:143,
  oradba_env.sh:478 - direkte Source-Sites; quelle: doc/review/CF-004

### RA-oradba-005 - Kein gitleaks.toml im Repo (OCI-Regeln fehlen in pre-commit)

- status: behoben
- schwere: mittel
- rolle: security
- ort: .gitleaks.toml
- regel: ci-gate
- gefunden: 2026-10-10
- beleg: ls .gitleaks.toml → kein Treffer; gitleaks Default kennt keine PAR-URLs oder OCIDs - Pilot oci-labs 2026-10-08
  meldete 0 Funde ohne OCI-Regeln
- erledigt: 2026-10-10
- commit: 07ef898

### RA-oradba-006 - Installer-Download ohne Checksum-Verifizierung (CF-006)

- status: offen
- schwere: hoch
- rolle: security
- ort: src/bin/oradba_install.sh
- regel: secret
- gefunden: 2026-10-10
- beleg: oradba_install.sh:547-570 - sha256sum vorhanden fuer lokale Prufung, aber curl-Download (--github-Pfad)
  vergleicht nicht gegen .sha256-Datei; quelle: doc/review/CF-006

### RA-oradba-007 - Kein bash-Version-Guard (CF-011)

- status: offen
- schwere: mittel
- rolle: kern
- ort: src/bin/oraenv.sh
- regel: inv-2
- gefunden: 2026-10-10
- beleg: oraenv.sh Kopf - kein BASH_VERSINFO-Check; macOS bash 3.2 ist auf dem erklarten Default-Target, Bats-Tests
  skippen explizit bei bash < 4; quelle: doc/review/CF-011

### RA-oradba-008 - Parallele Env-Build-Pfade unvollstaendig migriert (CF-017)

- status: offen
- schwere: mittel
- rolle: kern
- ort: src/lib/oradba_env_builder.sh
- orte: src/bin/oraenv.sh, src/lib/oradba_env_builder.sh
- regel: abstraction
- gefunden: 2026-10-10
- beleg: oraenv.sh inline-Logik fuer Environment-Aufbau; oradba_build_environment in oradba_env_builder.sh existiert
  aber kein src/bin-Skript ruft es auf; quelle: doc/review/CF-017
