# Befunde 2026-10-10 (--init + --quick, mechanisch)

- rollen: security, kern, doku-tests
- commit: 6fc0fba

## Befunde

### F-01 - Kein gitleaks in CI (History-Gate fehlt)

- schwere: hoch
- rolle: security
- ort: .github/workflows/ci.yml
- regel: ci-gate
- beleg: .github/workflows/ci.yml - kein gitleaks-Step in ci.yml, ci.yml, release.yml
- ausloeser: jeder Push kann ein neues Secret einbringen, das vor dem Release unentdeckt bleibt
- aufwand: S
- fix: .gitleaks.toml aus references/gitleaks-oci.toml ins Repo kopieren, gitleaks-Step
  in ci.yml einbauen; alternativ gitleaks als pre-commit-Hook

### F-02 - .claude/settings.local.json nicht in .gitignore

- schwere: niedrig
- rolle: security
- ort: .gitignore
- regel: claude-hygiene
- beleg: .gitignore:104-121 - .claude/*.md, .claude/settings.json vorhanden, aber nicht
  .claude/settings.local.json
- ausloeser: versehentliches git add -A koennte settings.local.json einchecken (Allowlist
  fuer Hooks - verraet was ohne Rueckfrage ausgefuehrt werden darf)
- aufwand: S
- fix: Zeile `.claude/settings.local.json` in .gitignore ergaenzen

### F-03 - Markdown-Lint-Fehler in Archiv-Releasenote

- schwere: niedrig
- rolle: doku-tests
- ort: doc/releases/v0.19.0.md
- regel: lint-gate
- beleg: doc/releases/v0.19.0.md:350 - MD012 multiple consecutive blank lines
- ausloeser: markdownlint --config .markdownlint.yaml meldet 1 Fehler in Archiv-Datei
- aufwand: S
- fix: leere Zeile 350 oder 351 entfernen

### F-04 - Plugin-Loader: direkte Source-Sites umgehen Isolation-Wrapper (CF-004)

- schwere: hoch
- rolle: kern
- ort: src/bin/oraenv.sh
- orte: src/bin/oraenv.sh, src/bin/oradba_env.sh, src/bin/oradba_dsctl.sh
- regel: abstraction
- beleg: oraenv.sh:857, oraenv.sh:1029, oraenv.sh:1146 - source plugin_file direkt;
  oradba_env.sh:143, oradba_env.sh:478 - direkte Source-Sites; quelle: doc/review/CF-004
- ausloeser: Cross-Plugin-Kontamination wenn direktes Sourcing den State nicht isoliert
- aufwand: L
- fix: execute_plugin_function_v2 als einzigen Einstieg fuer state-aendernde Aufrufe; direkte
  Source nur fuer auditierte, seiteneffektfreie Pfad-Builder (DECISION aus REVIEW.md erledigt)

### F-05 - Kein gitleaks.toml im Repo (OCI-Regeln fehlen in pre-commit)

- schwere: mittel
- rolle: security
- ort: .gitleaks.toml
- regel: ci-gate
- beleg: ls .gitleaks.toml → kein Treffer; gitleaks Default kennt keine PAR-URLs
  oder OCIDs - Pilot oci-labs 2026-10-08 meldete 0 Funde ohne OCI-Regeln
- ausloeser: ein neuer Beitrag mit OCID oder PAR in der Historie wird nicht erkannt
- aufwand: S
- fix: references/gitleaks-oci.toml aus dem repo-audit-Skill als .gitleaks.toml einchecken

### F-06 - Installer-Download ohne Checksum-Verifizierung (CF-006)

- schwere: hoch
- rolle: security
- ort: src/bin/oradba_install.sh
- regel: secret
- beleg: oradba_install.sh:547-570 - sha256sum vorhanden fuer lokale Prufung, aber
  curl-Download (--github-Pfad) vergleicht nicht gegen .sha256-Datei; quelle: doc/review/CF-006
- ausloeser: ein kompromittierter GitHub-Release-Mirror liefert ein praepariertes Tarball;
  der Installer fuehrt es ohne Verifizierung als root aus
- aufwand: M
- fix: nach curl-Download die .sha256-Datei herunterladen und sha256sum -c pruefen,
  bei Abweichung abbrechen; curl-pipe-bash-Einzeiler aus README entfernen oder schuetzen

### F-07 - Kein bash-Version-Guard (CF-011)

- schwere: mittel
- rolle: kern
- ort: src/bin/oraenv.sh
- regel: INV-2
- beleg: oraenv.sh Kopf - kein BASH_VERSINFO-Check; macOS bash 3.2 ist auf dem erklarten
  Default-Target, Bats-Tests skippen explizit bei bash < 4; quelle: doc/review/CF-011
- ausloeser: auf macOS ohne Homebrew bash startet oraenv.sh unter bash 3.2 und schlaegt
  mit einem kryptischen Fehler fehl statt mit einer Meldung
- aufwand: S
- fix: am Skript-Kopf `if (( BASH_VERSINFO[0] < 4 )); then echo "bash 4+ required" >&2;
  exit 1; fi` ergaenzen

### F-08 - Parallele Env-Build-Pfade unvollstaendig migriert (CF-017)

- schwere: mittel
- rolle: kern
- ort: src/lib/oradba_env_builder.sh
- orte: src/bin/oraenv.sh, src/lib/oradba_env_builder.sh
- regel: abstraction
- beleg: oraenv.sh inline-Logik fuer Environment-Aufbau; oradba_build_environment in
  oradba_env_builder.sh existiert aber kein src/bin-Skript ruft es auf;
  quelle: doc/review/CF-017
- ausloeser: zwei unterschiedliche Implementierungen muessen synchron gehalten werden;
  Tests laufen gegen den falsch ausgelieferten Pfad
- aufwand: L
- fix: Migration abschliessen: oraenv.sh delegiert an oradba_build_environment, inline-Logik
  entfernen (DECISION-REQUIRED laut REVIEW.md)

