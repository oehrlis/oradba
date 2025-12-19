# Release Process Guide

## Overview

The release workflow is designed to ensure CI passes before creating a release.
It has multiple trigger paths to accommodate different scenarios.

## Workflow Triggers

The release workflow (`release.yml`) can be triggered in three ways:

1. **Tag Push** - Pushing a version tag (e.g., `v0.8.1`)
2. **Workflow Run** - Automatically after CI completes on main branch
3. **Manual Dispatch** - Manual trigger from GitHub Actions UI

## ⚠️ Common Issue: Tag Push Before CI Completes

**Problem**: Pushing a tag immediately after pushing commits causes the release
workflow to fail because CI hasn't finished yet.

**What happens**:

```bash
git push origin main        # CI starts running
git push origin v0.8.1      # Release workflow starts immediately
                            # ❌ Release fails: CI not finished yet
```

## ✅ Recommended Release Process

### Option 1: Wait for CI (Recommended)

This is the safest and most straightforward approach.

```bash
# 1. Push your release commit
git push origin main

# 2. Wait for CI to complete
#    Check: https://github.com/oehrlis/oradba/actions/workflows/ci.yml
#    ✅ Wait for green checkmark

# 3. Create and push the tag AFTER CI passes
git tag -a v0.8.1 -m "Release message..."
git push origin v0.8.1

# 4. Release workflow triggers and succeeds (CI already passed)
```

**Timeline**:

- `t=0`: Push commit → CI starts
- `t=2min`: CI finishes ✅
- `t=2min`: Push tag → Release workflow starts
- `t=2min`: Release workflow checks CI (finds passing run) ✅
- `t=3min`: Release created ✅

### Option 2: Use Workflow Run Trigger

Push commit and tag together, then let the workflow handle it.

```bash
# 1. Push both commit and tag
git push origin main
git push origin v0.8.1

# 2. Tag-triggered release will fail (CI not done yet)
#    This is expected - ignore it ❌

# 3. Wait for CI to complete
#    ✅ CI finishes successfully

# 4. CI completion triggers release workflow automatically
#    ✅ Release succeeds (triggered by workflow_run)
```

**Timeline**:

- `t=0`: Push commit → CI starts
- `t=0`: Push tag → Release workflow starts (tag trigger)
- `t=0`: Release workflow fails ❌ (CI not done)
- `t=2min`: CI finishes ✅
- `t=2min`: CI completion triggers release workflow (workflow_run trigger)
- `t=2min`: Release workflow succeeds ✅
- `t=3min`: Release created ✅

**Note**: This creates two workflow runs (one fails, one succeeds). The failed run can be ignored.

### Option 3: Manual Dispatch

For more control, use the manual workflow dispatch.

```bash
# 1. Push commit and wait for CI
git push origin main
# ✅ Wait for CI to pass

# 2. Create and push tag
git tag -a v0.8.1 -m "Release message..."
git push origin v0.8.1

# 3. Go to GitHub Actions UI:
#    https://github.com/oehrlis/oradba/actions/workflows/release.yml
#    Click "Run workflow" → Enter version (e.g., 0.8.1) → Run

# 4. Release workflow runs with manual trigger
#    ✅ Uses latest CI run from main branch
```

## 🎯 Best Practice

**Use Option 1**: Push commit first, wait for CI, then push tag.

This approach:

- ✅ Ensures CI passes before release
- ✅ Only creates one workflow run (no failures)
- ✅ Clear and predictable
- ✅ No confusion about which run succeeded

## 📋 Complete Release Checklist

### Pre-Release

- [ ] All changes committed and pushed to feature branch
- [ ] Pull request reviewed and merged to main
- [ ] Local main branch updated: `git pull origin main`

### Version Updates

- [ ] Update `VERSION` file (e.g., `0.8.1`)
- [ ] Update `CHANGELOG.md` with release notes
- [ ] Update any other version references
- [ ] Create `build/vX.Y.Z.md` with release notes (optional, keep local)

### Commit Release Changes

```bash
git add VERSION CHANGELOG.md
git commit -m "chore: Release vX.Y.Z

Version bump: X.Y.Z-1 → X.Y.Z

Changes:
- Key feature or fix 1
- Key feature or fix 2"
```

### Push and Wait for CI

```bash
# Push release commit
git push origin main

# WAIT HERE - Check CI status
# https://github.com/oehrlis/oradba/actions/workflows/ci.yml
# ⏳ Wait for green checkmark ✅
```

### Create and Push Tag

```bash
# Create annotated tag with release notes
git tag -a vX.Y.Z -m "Release vX.Y.Z

Summary of changes...

Full changelog: https://github.com/oehrlis/oradba/compare/vX.Y.Z-1...vX.Y.Z"

# Push tag ONLY AFTER CI passes
git push origin vX.Y.Z
```

### Verify Release

- [ ] Check release workflow succeeds: <https://github.com/oehrlis/oradba/actions/workflows/release.yml>
- [ ] Verify release created: <https://github.com/oehrlis/oradba/releases>
- [ ] Download and test installer from release

## 🔧 Troubleshooting

### Issue: Release Failed "No CI run found"

**Cause**: Tag was pushed before CI completed for that commit.

**Solution**:

```bash
# Option A: Wait and let workflow_run trigger handle it
# Do nothing - when CI completes, release will auto-trigger

# Option B: Delete and recreate tag after CI passes
git tag -d vX.Y.Z                    # Delete local tag
git push origin :refs/tags/vX.Y.Z    # Delete remote tag
# Wait for CI to pass ✅
git tag -a vX.Y.Z -m "..."           # Recreate tag
git push origin vX.Y.Z               # Push again
```

### Issue: Multiple Failed Releases

**Cause**: Pushing tag too early, multiple retries.

**Solution**:

```bash
# Clean up failed releases on GitHub (manual)
# Then follow Option 1 process above
```

### Issue: CI Still Running

**Status Check**:

```bash
# Check CI status via GitHub API
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/oehrlis/oradba/commits/$(git rev-parse HEAD)/status

# Or visit GitHub Actions page
open https://github.com/oehrlis/oradba/actions/workflows/ci.yml
```

## 📚 Additional Notes

### Why This Design?

The workflow is designed to:

1. Prevent releases with failing tests
2. Support multiple trigger paths (flexibility)
3. Automatically create releases when CI passes

### Workflow Run Trigger

The `workflow_run` trigger on CI completion ensures that even if you push the tag
early, the release will still be created automatically once CI passes.

### Tag Format

- Use semantic versioning: `vMAJOR.MINOR.PATCH`
- Always include the `v` prefix: `v0.8.1` not `0.8.1`
- Use annotated tags: `git tag -a` not `git tag`

## 🎬 Example: v0.8.1 Release

Here's what should have happened for v0.8.1:

```bash
# 1. Prepare release commit
git add VERSION CHANGELOG.md
git commit -m "chore: Release v0.8.1..."

# 2. Push and WAIT
git push origin main
# ⏳ Wait 2-3 minutes for CI to pass ✅

# 3. After CI passes, create tag
git tag -a v0.8.1 -m "OraDBA v0.8.1..."
git push origin v0.8.1

# 4. Release workflow runs and succeeds ✅
```

## 🚀 Quick Reference

| Step        | Command                                 | Wait for         |
|-------------|-----------------------------------------|------------------|
| 1. Commit   | `git commit -m "chore: Release vX.Y.Z"` | -                |
| 2. Push     | `git push origin main`                  | **CI passes**    |
| 3. Tag      | `git tag -a vX.Y.Z -m "..."`            | -                |
| 4. Push Tag | `git push origin vX.Y.Z`                | Release workflow |
| 5. Verify   | Check GitHub releases                   | -                |

**Key**: Always wait for CI before pushing the tag! 🔑
