# Review-Linse - oradba

> Fuer /repo-audit. Kurz halten (15-35 Zeilen). Invarianten-IDs nie neu vergeben.

## Kronjuwelen

- Das Framework laeuft als privilegierter Benutzer auf Produktionsdatenbanken von Kunden.
  Ein Fehler (falscher Pfad, ungequotete Variable) ist ein Vorfall beim Kunden.
- Die Marke oradba: Korrektheit und Stabilitaet sind das Versprechen von v1.0.0 aufwaerts.

## Invarianten

- INV-1: Keine Secrets (Passwoerter, Tokens, Keys) in Baum oder Historie; Credentials
  nur via `op read` oder Laufzeit-Input - nie in Variablen-Defaults, Logs oder Prozessargs
- INV-2: `set -euo pipefail` und `#!/usr/bin/env bash` auf allen ausgefuehrten Skripten;
  keine von-Null-Inkremente `(( var++ ))` unter `set -e` ohne Guard
- INV-3: `git ls-files .claude` liefert hoechstens `CLAUDE.md` und `aitk.toml`
- INV-4: Kein Schreiben ausserhalb definierter Pfade (ORADBA_BASE, TMPDIR); temp-Dateien
  via `mktemp`, nicht via vorhersagbare Pfade; EXIT-Trap zum Aufraeumen
- INV-5: Alle Releases tragen die VERSION-Datei; CI prueft VERSION == git-Tag vor dem Build

## Sensible Namen

- Kein Tenant-Name, kein Namespace - reines Bash/SQL-Framework ohne OCI-Umgebungsdaten.
  Hand-Grep auf Platzhalter: `ocid1\.` und `objectstorage\.` (gitleaks-OCI-Config)

## Bedrohungsmodell

Ein Skript wird als oracle/root auf einem Produktionssystem ausgefuehrt. Ein Angreifer
mit Schreibzugriff auf das Repo oder einen abhaengigen Installer-Mirror bringt Code ein.
Ziel: privilege escalation, Datenzugriff oder Sabotage des DBCA-Prozesses.

## Nicht-Ziele

- Kein Mandanten-Framework (keine OCI-Infrastruktur, kein Terraform in diesem Repo)
- Kein eigenes Secret-Management - setzt 1Password CLI (`op`) voraus

## Bekannte Altlasten

- Verweis auf Register: RA-oradba-003 (direkte Plugin-Source-Sites), RA-oradba-011
  (gnu-only Tools), RA-oradba-018 (eval in oraenv), RA-oradba-019 (Wallet Base64)

## Verifikation

- `make lint` (shellcheck + shfmt + markdownlint)
- `make test` (Bats unit tests)
- `aitk repo hygiene .`
- `gitleaks git --config ~/.claude/skills/repo-audit/references/gitleaks-oci.toml --redact --log-opts=--all .`
