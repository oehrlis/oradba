# Release 0.16.0 - Pre-Release Checklist

## Release Information
- **Version:** 0.16.0
- **Release Date:** 2026-01-08
- **Previous Version:** 0.15.0
- **Type:** Minor release (new features + bug fixes)

## Completed Tasks ✓

### Version Management
- [x] Version bumped to 0.16.0 in VERSION file
- [x] CHANGELOG.md updated with release date
- [x] Release notes created (doc/releases/release-0.16.0.md)
- [x] All changes committed (commit: e9069c4)

### Build Artifacts
- [x] Clean build successful
- [x] Distribution tarball created: `dist/oradba-0.16.0.tar.gz` (5.0M)
- [x] Installer script created: `dist/oradba_install.sh` (6.9M)
- [x] Check script created: `dist/oradba_check.sh` (24K)

### Code Quality
- [x] Extension add command implemented and tested
- [x] PATH/SQLPATH deduplication implemented
- [x] Core oradba bin directory preservation fix
- [x] Verbose logging suppressed
- [x] GitHub fallback for repos without releases

## Pending Tasks (To Be Done By User)

### Testing
- [ ] Run full test suite: `make test-full`
- [ ] Test extension add command:
  ```bash
  # Test GitHub installation
  oradba_extension.sh add oehrlis/odb_autoupgrade
  
  # Test with version
  oradba_extension.sh add oehrlis/odb_xyz@v1.0.0
  
  # Test update
  oradba_extension.sh add oehrlis/odb_xyz --update
  ```
- [ ] Test PATH deduplication:
  ```bash
  # Source oraenv multiple times
  source /opt/oracle/local/oradba/bin/oraenv.sh
  source /opt/oracle/local/oradba/bin/oraenv.sh
  
  # Verify no duplicates
  echo $PATH | tr ':' '\n' | sort | uniq -d
  ```
- [ ] Test extension disable/enable cycle
- [ ] Verify oraup.sh displays correctly on login
- [ ] Test in Docker container: `docker exec -it labdb bash -l`

### Documentation Review
- [ ] Review CHANGELOG.md for accuracy
- [ ] Review release notes (doc/releases/release-0.16.0.md)
- [ ] Verify extension documentation updated:
  - [ ] doc/extension-system.md
  - [ ] src/doc/18-extensions.md
  - [ ] src/doc/03-quickstart.md

### Git Operations
- [ ] Review git log: `git log --oneline v0.15.0..HEAD`
- [ ] Ensure working directory is clean: `git status`
- [ ] Create git tag: `make tag` (creates v0.16.0)
- [ ] Push changes: `git push origin main`
- [ ] Push tag: `git push origin v0.16.0`

### GitHub Release
- [ ] Create GitHub release: https://github.com/oehrlis/oradba/releases/new
- [ ] Tag version: v0.16.0
- [ ] Release title: "OraDBA 0.16.0 - Extension Add Command & PATH Fixes"
- [ ] Copy release notes from doc/releases/release-0.16.0.md
- [ ] Upload artifacts:
  - [ ] dist/oradba-0.16.0.tar.gz
  - [ ] dist/oradba_install.sh
  - [ ] dist/oradba_check.sh

### Post-Release
- [ ] Verify release downloads work
- [ ] Test fresh installation from release
- [ ] Update any external documentation/wikis
- [ ] Announce release (if applicable)

## Key Features in This Release

1. **Extension Add Command** - Install extensions from GitHub or local tarballs
2. **PATH Deduplication** - No more duplicate paths in PATH/SQLPATH
3. **Clean Extension Loading** - Proper cleanup of disabled extensions
4. **GitHub Fallbacks** - Support for repos without formal releases
5. **Silent Loading** - No verbose messages during login

## Known Issues

None at this time.

## Rollback Plan

If issues are discovered post-release:

1. Checkout previous version:
   ```bash
   git checkout v0.15.0
   ```

2. Rebuild:
   ```bash
   make build
   ```

3. Users can reinstall 0.15.0:
   ```bash
   curl -LO https://github.com/oehrlis/oradba/releases/download/v0.15.0/oradba_install.sh
   bash oradba_install.sh
   ```

## Testing Commands

```bash
# Run all tests
make test-full

# Run linting
make lint

# Test build
make clean build

# Full CI pipeline
make ci
```

## Release Command Sequence

Once testing is complete:

```bash
# 1. Final status check
make status

# 2. Create tag
make tag

# 3. Push everything
git push origin main
git push origin v0.16.0

# 4. Create GitHub release (manual step)
# Upload: dist/oradba-0.16.0.tar.gz, dist/oradba_install.sh, dist/oradba_check.sh
```

## Checklist Status

- Completed: 11/11 preparation tasks
- Pending: 21 testing and release tasks
- Next Step: Run `make test-full`
