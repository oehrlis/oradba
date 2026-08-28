# Evolve Promotions - oradba

> Proposal from `/evolve`, run 2026-08-28 in `~/Repos/own/oehrlis/oradba`.
> CWD is not ai-toolkit, so nothing was written there. Apply with:
> `cd ~/Repos/own/oehrlis/ai-toolkit && claude`, then `/evolve`.

## Input

- `tasks/corrections.jsonl` - 7 entries, **all `resolved: true`**, 4 already promoted
- `tasks/lessons.md` - 4 lessons, **all already promoted**

The existing backlog is fully processed. Everything below comes from the
verification sweep and from the v1.1.0 session, which produced no correction
entries at the time.

## Verification sweep - 2 FAIL

<!-- markdownlint-disable MD013 MD060 -->

| Lesson | Result | Evidence |
|---|---|---|
| L1 `cmd; var=$?` under `set -e` | **FAIL** | `src/bin/oradba_services_root.sh:111-113` and `src/bin/oradba_dbctl.sh:264-268` |
| L2 `${!var}` under `set -u` | **FAIL** | `src/bin/oraenv.sh:141` called from `oraenv.sh:1222` with `"SQLPATH"` |
| L3 release notes before tag | PASS | `doc/releases/v1.1.0.md` exists |
| L4 subagent worktree diff | N/A | no subagent code changes this session |

<!-- markdownlint-restore -->

### L1 FAIL - detail

`oradba_services_root.sh` is the systemd entry point and runs under
`set -euo pipefail`:

```bash
su - "${ORACLE_USER}" -c "${SERVICES_SCRIPT} ${action} --force"

local rc=$?

if [[ ${rc} -eq 0 ]]; then
```

If `su` fails the script exits at the `su` line. `local rc=$?` never runs and the
entire `if` below is unreachable for the failure case - the one case it exists
for. A failed service start therefore produces none of the intended logging.
`oradba_dbctl.sh:268` has the same shape after a sqlplus heredoc.

This is a live defect on the boot path, found by L1's own verify line. It is not
fixed here: it needs its own verified change and a release.

### L2 FAIL - detail

```bash
_oradba_path_contains() {
    local dir="$1" pathvar="${2:-PATH}"
    [[ ":${!pathvar}:" == *":${dir}:"* ]]
}
```

Called as `_oradba_path_contains "${ORADBA_BASE}/sql" "SQLPATH"`. `${!pathvar}`
expands to `${SQLPATH}` with no `:-`, so an unset `SQLPATH` aborts under
`set -u`. Reachable in basenv coexistence mode.

L2's verify line also needs narrowing: it matches `${!array[@]}` index
expansions, which are safe. Suggested replacement:

verify: `grep -rn '\${!' src/ --include="*.sh" | grep -v '\[@\]' | grep -v ':-\|-}' | grep -v '#'`

## Proposed new lessons for this repo

To append to `tasks/lessons.md` (rung 2), and as corrections with
`times_corrected` reflecting the count actually observed:

- **L5 - A check that cannot fail reports success.** `make test-full` derived its
  verdict from a TAP report without asserting the report existed; `make
  format-check` printed failure and success in the same run and exited 0.
  verify: every check that derives a verdict from an artifact asserts the
  artifact exists and is non-empty before reading it
- **L6 - `grep -A<N>` as a test assertion is a time bomb.** 19 instances
  converted in this repo, windows from 5 to 120 lines. Two broke from unrelated
  comment additions. **7 remain** in `test_extensions.bats` and
  `test_oraup.bats` - listed under "Open" below.
  verify: `grep -rEn 'grep -A ?[0-9]+ .\^?[a-z_]+\(\)' tests/*.bats` -> 0 matches
  (the bare `grep -A[0-9]` form matches 27 lines, most of them legitimate greps
  over data rather than over a function body - anchoring on the function header
  is what makes this check actionable)
- **L7 - A test that spawns a new shell tests a different shell.** `run bash -c
  "alias sq"` can never see an alias, because aliases are not exported. Applies
  to aliases, `shopt`, functions and anything else not in the environment.
  verify: `grep -rEn 'run bash -c "(alias|shopt|declare -f|type )' tests/*.bats`
  -> 0 matches (currently PASS; the bare `run bash -c` form matches 204 lines and
  is almost all legitimate, so it is useless as a gate)
- **L8 - Reinterpreting a return code means grepping every caller.**
  `generate_sid_lists` returns non-zero for "no oratab"; tolerated in
  `oradba_standard.conf` but not in `oradba_homes.sh`, which shipped `add`
  exiting 1 after succeeding.
  verify: after changing how a function's return code is treated, `grep -rn
  '<function>' src/` and check each call site
- **L9 - Local green is not evidence.** The developer shell exports 71
  `ORADBA_*`/`ORACLE_*` variables and the machine has a populated `/etc/oratab`.
  Two defects passed locally and failed in CI for exactly that reason.
  verify: full suite additionally run in a clean non-root Linux container with
  no `/etc/oratab` before tagging

## Proposed rule promotions - ai-toolkit

Two files, one section each. Deliberately not five new rules: L5/L9 are the
inverse and the extension of patterns Stefan already has, so they belong in the
existing sections rather than as new top-level rules.

<!-- markdownlint-disable MD013 MD060 -->

| Target | Change | Version | Type |
|---|---|---|---|
| `ai-toolkit/claude/rules/claude-code.md` | extend "Ein Filter, der still zurueckhaelt" with the silent-PASS inverse (L5); extend "Verification Patterns" with L8 and L9 | 0.8.0 -> 0.9.0 | minor |
| `ai-toolkit/claude/rules/shell-scripts.md` | new short section: test assertions must not depend on line windows (L6) or on a fresh shell (L7) | 0.5.0 -> 0.6.0 | minor |

<!-- markdownlint-restore -->

### Proposed text - claude-code.md, appended to the silent-filter section

```markdown
Die Umkehrung ist genauso teuer: **ein Check, der nicht fehlschlagen kann, meldet
Erfolg.** Wer ein Urteil aus einem Artefakt ableitet, muss zuerst pruefen, dass
das Artefakt existiert und nicht leer ist - sonst ist "keine Fehler gefunden"
nicht von "nichts geprueft" zu unterscheiden.

- `make test-full` las die Fehlerzahl aus einem TAP-Report, den es nie erzwang.
  Im frischen Clone fehlte das Verzeichnis, bats brach ab, der grep scheiterte,
  `[ "" -gt 0 ]` war false - Ausgabe "All tests passed", Exit 0, kein Test
  gelaufen. Sieben rote Tests erreichten so drei Tags.
- `make format-check` gab "needs formatting" UND "properly formatted" aus und
  endete auf 0: `|| (echo; exit 1)` lief im Subshell und fiel danach in die
  Erfolgsmeldung.
- Ein fehlender Linter ist ein Fehler, keine Warnung. `shfmt not found` als
  Warnung durchzulassen macht einen abwesenden Linter von einem zufriedenen
  ununterscheidbar.

verify: jeder Check, der ein Urteil aus einer Datei liest, bricht ab, wenn die
Datei fehlt oder leer ist - nicht erst, wenn sie Fehler enthaelt
```

### Proposed text - claude-code.md, appended to Verification Patterns

```markdown
- **Nicht auf der eigenen Maschine verifizieren.** Die Entwickler-Shell traegt
  Zustand, den kein Zielsystem hat. In oradba exportiert sie 71
  `ORADBA_*`/`ORACLE_*`-Variablen und die Maschine hat eine populierte
  `/etc/oratab`; zwei Defekte waren lokal gruen und in CI rot, genau deswegen.
  Vor einem Release zusaetzlich in einer sauberen, non-root Umgebung laufen.
- **Wer einen Returncode neu interpretiert, greppt alle Aufrufer.** Eine
  Funktion, deren "nichts zu tun" als Fehler gilt, reisst unter `set -e` jeden
  Aufrufer mit. In oradba an einer Stelle entschaerft, an zwei weiteren nicht -
  `oradba_homes.sh add` legte den Home an, meldete Erfolg und endete auf 1.

verify: nach Aenderung an der Returncode-Semantik einer Funktion
`grep -rn '<funktion>' src/` und jede Fundstelle einzeln pruefen
```

### Proposed text - shell-scripts.md, new section

```markdown
## Test-Assertions duerfen nicht an Zeilenfenster oder an eine neue Shell haengen

- `grep -A<N> "fn()" datei | grep -q X` bricht, sobald jemand einen Kommentar in
  die Funktion schreibt. In oradba waren 19 solche Assertions im Einsatz, Fenster
  von 5 bis 120 Zeilen; zwei fielen durch fremde Aenderungen. Stattdessen den
  Funktionskoerper extrahieren:
  `sed -n "/^fn() {/,/^}/p" datei`
- `run bash -c "alias sq"` kann den Alias nie sehen - Aliase werden nicht
  exportiert. Gleiches gilt fuer `shopt`, Funktionen und alles, was nicht in der
  Umgebung steht: eine neue Shell prueft eine andere Shell. In der aktuellen
  Shell abfragen (`run alias sq`).

verify: `grep -rEn 'grep -A ?[0-9]+ .\^?[a-z_]+\(\)' tests/*.bats` -> 0 Treffer
verify: `grep -rEn 'run bash -c "(alias|shopt|declare -f|type )' tests/*.bats` -> 0 Treffer
```

## Open - found while validating the proposed verify lines

Writing a verify line and not running it is how a check ends up crying wolf.
Both proposed lines were tested; two had to be narrowed, and one revealed work:

- [ ] 7 function-window assertions still to convert:
      `test_extensions.bats:537,541,545`, `test_oraenv.bats:122` (a 70-line
      window) and `test_oraup.bats:120,121,191`. Mechanical, same helper pattern
      as the 19 already done [P3]
- [ ] L1 FAIL: `oradba_services_root.sh:111-113` and `oradba_dbctl.sh:264-268`
      capture `$?` on the line after the command under `set -e`. The first is the
      systemd entry point and its error handling is unreachable [P1]
- [ ] L2 FAIL: `oraenv.sh:141` `${!pathvar}` unguarded, reachable from `:1222`
      with `"SQLPATH"` [P2]

## Not proposed

- A separate rule for "gate must run in CI, not only locally" - covered by L9 in
  Verification Patterns; a third near-duplicate section would only cost tokens.
- Anything about the M6 asset question. Out of scope by design.
