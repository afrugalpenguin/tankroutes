# Release Checklist

Before each release:

- [ ] Update version in `Core.lua`
- [ ] If Forever has patched, bump `## Interface:` in `TankRoutes.toc` (currently `16001`)
- [ ] Update `CHANGELOG.md` (use `**vX.Y.Z**` bold text, no `###` subheadings)
- [ ] If features changed, update `README.md` (and `CURSEFORGE.md` once the CurseForge project exists)
- [ ] Commit with message: `chore(release): bump version to X.Y.Z`
- [ ] Create and push tag: `git tag vX.Y.Z && git push origin vX.Y.Z`

## Version Tagging Rules

Follow [Semantic Versioning](https://semver.org/):

| Type | When to use | Example |
|------|-------------|---------|
| **Major** (X.0.0) | Breaking changes, major UI overhauls, saved variable resets | 1.4.2 to 2.0.0 |
| **Minor** (X.Y.0) | New features, new dungeons, significant enhancements | 1.3.0 to 1.4.0 |
| **Patch** (X.Y.Z) | Bug fixes, small tweaks, route or map data fixes | 1.4.1 to 1.4.2 |

## Tag Format

Always prefix with `v`: `v0.1.0`

## Quick Release Commands

```bash
# After committing the version bump:
git tag v0.1.0
git push origin v0.1.0
```

The Release workflow packages the tag with the BigWigs packager and publishes a GitHub Release. CurseForge upload is added once the project exists (see `.github/workflows/release.yml`).
