# Installation in Docker

**Purpose:** How to install OraDBA inside a running Oracle Free 26ai database container (or similar
Oracle Database containers) using the published installer.

**Audience:** DBAs/devs running Oracle in Docker who want OraDBA inside the container.

## Prerequisites

- A running Oracle Database container (example: Oracle Free 26ai image)
- Docker CLI access on the host
- Network egress from the container to GitHub (for installer download), or a pre-downloaded installer
- Container user `oracle` exists (typical for Oracle images)

## Helpful Variables

Set these on the host to simplify commands:

```bash
CTR=free26ai            # container name or ID
INSTALLER_URL="https://github.com/oehrlis/oradba/releases/latest/download/oradba_install.sh"
PREFIX="/opt/oradba"    # install target inside container
```

## Step 1: Ensure Required Tools Inside the Container

If the container is missing curl/wget/tar, install them as root:

```bash
docker exec -it -u root "$CTR" microdnf install -y curl tar gzip shadow-utils findutils
```

(Use `dnf`/`yum`/`apt` if microdnf is unavailable.)

## Step 2: Download and Run the Installer

Run as the `oracle` user inside the container:

```bash
docker exec -it "$CTR" bash -lc "
  curl -L -o /tmp/oradba_install.sh \"$INSTALLER_URL\" &&
  chmod +x /tmp/oradba_install.sh &&
  /tmp/oradba_install.sh --prefix \"$PREFIX\"
"
```

## Step 3: Verify Installation

```bash
docker exec -it "$CTR" bash -lc "
  test -x \"$PREFIX/bin/oraenv.sh\" &&
  echo \"OraDBA installed at $PREFIX\"
"
```

Optional: run the prerequisites checker inside the container:

```bash
docker exec -it "$CTR" bash -lc "
  curl -L -o /tmp/oradba_check.sh https://github.com/oehrlis/oradba/releases/latest/download/oradba_check.sh &&
  chmod +x /tmp/oradba_check.sh &&
  /tmp/oradba_check.sh --dir \"$PREFIX\"
"
```

## Step 4: Use OraDBA Inside the Container

Source the environment and start using the tools:

```bash
docker exec -it "$CTR" bash -lc "
  source \"$PREFIX/bin/oraenv.sh\" FREE &&
  oradba_extension.sh list
"
```

Replace `FREE` with your SID if different.

## Notes and Tips

- Persisting install: Mount a host volume to `$PREFIX` (e.g., `-v /opt/oradba:/opt/oradba`) so the
  install survives container rebuilds.
- Air-gapped: Download `oradba_install.sh` on the host, copy it into the container
  (`docker cp oradba_install.sh $CTR:/tmp/`), then run it as above.
- Missing root access: If you cannot use root in the container, ensure required tools are already
  present or bake them into a custom image.
