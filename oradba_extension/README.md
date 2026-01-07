# OraDBA Extension Template

Reusable template to bootstrap new OraDBA extensions. It mirrors the recommended structure from `doc/extension-system.md` and `src/doc/18-extensions.md` and ships with workflows, packaging helpers, and sample content you can adapt.

## Quick Start
- Clone this repository and switch into it.
- Rename the template to your extension name: `./scripts/rename-extension.sh --name myext --description "My OraDBA add-ons"`
- Customize the extension content under `extension-template/` (bin/sql/rcv/etc/lib).
- Build a distributable tarball and checksum: `./scripts/build.sh`
- Publish the repo to GitHub and keep CI enabled (lint, shell tests, markdown linting, tarball release).

## Structure
```text
oradba_extension/
├── extension-template/       # Rename to your extension name
│   ├── .extension            # Metadata (name, version, priority, description)
│   ├── README.md             # Extension-specific docs
│   ├── bin/                  # Scripts added to PATH
│   ├── sql/                  # SQL scripts added to SQLPATH
│   ├── rcv/                  # RMAN scripts
│   ├── etc/                  # Config examples (not auto-loaded)
│   └── lib/                  # Optional shared helpers
├── scripts/
│   ├── build.sh              # Package tarball + SHA256 checksum
│   └── rename-extension.sh   # Rename template after clone/fork
├── tests/                    # BATS tests for the helpers
├── .github/workflows/        # CI (lint/tests) and release workflow
├── CHANGELOG.md
├── LICENSE
└── VERSION
```

## Packaging
- `scripts/build.sh` reads `VERSION` and the `.extension` metadata to create `dist/<name>-<version>.tar.gz` plus a matching `.sha256`.
- Use `--dist` to override the output directory and `--extension` to point at a differently named extension folder.
- The tarball preserves the extension directory as the root so it can be extracted directly into `${ORADBA_LOCAL_BASE}`.

## Rename Helper
- `scripts/rename-extension.sh --name <newname> [--description "..."] [--workdir <path>]`
- Updates the directory name, `.extension` metadata, config example filename, and documentation references.
- Run it once right after cloning to avoid manual edits and naming drift.

## CI and Releases
- CI runs shellcheck on scripts, BATS tests, and markdownlint on all Markdown files.
- Release workflow triggers on tags (`v*.*.*`) or manual dispatch, runs lint/tests, builds the tarball + checksum, and publishes them as GitHub release assets.

## Using the Template
1. Customize the sample script/query/RCV/config files with your logic.
2. Add configuration guidance in `extension-template/etc/<name>.conf.example`; users should copy required settings into `${ORADBA_PREFIX}/etc/oradba_customer.conf`.
3. Keep `.extension` metadata updated (name, version, priority). Extensions are auto-discovered in `${ORADBA_LOCAL_BASE}` when they contain `bin/`, `sql/`, or `rcv/`.

## References
- OraDBA Extension System: `doc/extension-system.md`
- User documentation chapter: `src/doc/18-extensions.md`
- Example extension: `doc/examples/extensions/customer`
