# Git Flow Strategy

[Ver versión en español](./GIT_FLOW.esp.md)

## Overview

Timely uses **Git Flow** as its branching strategy. This approach provides a robust framework for managing releases, features, and hotfixes in a structured way.

Git Flow is a set of git extensions that provide high-level repository operations based on [Vincent Driessen's branching model](https://nvie.com/posts/a-successful-git-branching-model/). It uses a merge-based solution that doesn't rebase feature branches.

### Installing Git Flow

**macOS:**
```bash
# Using Homebrew
brew install git-flow-avh

# Using Macports
port install git-flow-avh
```

**Linux:**
```bash
apt-get install git-flow
```

**Windows (Cygwin):**
Installation via bash script (requires wget and util-linux).

### Initialize Git Flow

```bash
git flow init
```

This command customizes your project setup with branch naming conventions. We recommend using the default settings, which align with Timely's structure (`main` for production, `dev` for development).

## Branch Structure

```
main (production)
  ↑
  └─ dev (development)
       ↑
       ├─ feature/feature-name
       ├─ feature/another-feature
       └─ bugfix/bug-description
```

### Main Branches

#### `main`
- **Purpose**: Production-ready code.
- **Protection**: Protected branch, requires pull request and reviews.
- **Deployment**: Automatically triggers version bump and release builds.
- **Direct commits**: ❌ Never commit directly to main.
- **Merges from**: `dev` branch only (via pull request).

#### `dev`
- **Purpose**: Integration branch for ongoing development.
- **Protection**: Protected branch, requires pull request.
- **Direct commits**: ❌ Never commit directly to dev.
- **Merges from**: `feature/*`, `bugfix/*`, `hotfix/*` branches.

### Supporting Branches

#### `feature/*`
- **Purpose**: Develop new features.
- **Naming**: `feature/short-description` (e.g., `feature/dark-mode-toggle`).
- **Branches from**: `dev`.
- **Merges into**: `dev`.
- **Lifetime**: Until feature is complete and merged.

#### `bugfix/*`
- **Purpose**: Fix bugs found during development.
- **Naming**: `bugfix/short-description` (e.g., `bugfix/timer-calculation`).
- **Branches from**: `dev`.
- **Merges into**: `dev`.
- **Lifetime**: Until fix is complete and merged.

#### `hotfix/*`
- **Purpose**: Emergency fixes for production issues.
- **Naming**: `hotfix/short-description` (e.g., `hotfix/crash-on-startup`).
- **Branches from**: `main`.
- **Merges into**: Both `main` and `dev`.
- **Lifetime**: Until hotfix is deployed.

---

## Workflows

### 1. Working with Features

#### Starting a New Feature

**Using git-flow:**
```bash
# Start new feature (creates branch from dev and switches to it)
git flow feature start user-authentication

# Work on your feature
git add .
git commit -m "feat(auth): add login screen"

# Publish feature to remote (for collaboration)
git flow feature publish user-authentication
```

**Using standard git:**
```bash
# 1. Ensure dev is up to date
git checkout dev
git pull origin dev

# 2. Create feature branch
git checkout -b feature/user-authentication

# 3. Work on your feature
git add .
git commit -m "feat(auth): add login screen"

# 4. Push feature branch
git push origin feature/user-authentication
```

#### Collaborating on Features

```bash
# Pull remote feature to track it locally
git flow feature track user-authentication

# Get latest changes from remote feature
git flow feature pull origin user-authentication
```

#### Completing a Feature

**Using git-flow:**
```bash
# Finish feature (merges into dev, removes branch, switches to dev)
git flow feature finish user-authentication

# Push updated dev branch
git push origin dev

# Delete remote feature branch
git push origin --delete feature/user-authentication
```

**Using standard git:**
```bash
# 1. Update feature branch with latest dev
git checkout feature/user-authentication
git pull origin dev

# 2. Resolve any conflicts
# If conflicts exist, resolve them and commit

# 3. Push updated branch
git push origin feature/user-authentication

# 4. Merge via Pull Request
# Complete PR on GitHub after review and approval

# 5. Delete feature branch (after merge)
git checkout dev
git pull origin dev
git branch -d feature/user-authentication
git push origin --delete feature/user-authentication
```

### 2. Working with Releases

#### Starting a Release

**Using git-flow:**
```bash
# Start release branch (creates from dev)
git flow release start 1.2.0

# Optionally specify base commit
git flow release start 1.2.0 [BASE]

# Publish release for team collaboration
git flow release publish 1.2.0
```

**Using standard git:**
```bash
# 1. Ensure dev is stable and tested
git checkout dev
git pull origin dev

# 2. Create release branch
git checkout -b release/1.2.0

# 3. Update version numbers and prepare release
# Make any final adjustments

# 4. Push release branch
git push origin release/1.2.0
```

#### Finishing a Release

**Using git-flow:**
```bash
# Finish release (merges to main, tags, back-merges to dev, removes branch)
git flow release finish 1.2.0

# Push everything including tags
git push origin main
git push origin dev
git push origin --tags
```

**Using standard git (Timely's GitHub workflow):**
```bash
# 1. Create Pull Request
# Go to GitHub and create PR: dev → main
# Title: "Release v1.2.0" or similar

# 2. Review and approve PR
# Ensure all CI checks pass
# Review changelog and version bump

# 3. Merge to main
# Use "Squash and merge" or "Create a merge commit"
# GitHub Actions will automatically:
#   - Bump version based on commits
#   - Create git tag
#   - Build APK and AAB for Android
#   - Build IPA for iOS
#   - Create GitHub Release with artifacts

# 4. Update dev with main
git checkout dev
git pull origin main
git push origin dev
```

### 3. Working with Hotfixes

#### Starting a Hotfix

**Using git-flow:**
```bash
# Start hotfix from main (production)
git flow hotfix start 1.2.1

# Optionally specify base version
git flow hotfix start 1.2.1 [BASENAME]

# Fix the issue
git add .
git commit -m "fix(critical): resolve crash on app startup"
```

**Using standard git:**
```bash
# 1. Create hotfix branch from main
git checkout main
git pull origin main
git checkout -b hotfix/critical-crash-fix

# 2. Fix the issue
git add .
git commit -m "fix(critical): resolve crash on app startup"

# 3. Push hotfix branch
git push origin hotfix/critical-crash-fix
```

#### Finishing a Hotfix

**Using git-flow:**
```bash
# Finish hotfix (merges to both main and dev, tags, removes branch)
git flow hotfix finish 1.2.1

# Push everything
git push origin main
git push origin dev
git push origin --tags
```

**Using standard git:**
```bash
# 1. Create PR to main
# Go to GitHub and create PR: hotfix/critical-crash-fix → main

# 2. After merge to main, also merge to dev
git checkout dev
git pull origin main
git push origin dev

# 3. Delete hotfix branch
git branch -d hotfix/critical-crash-fix
git push origin --delete hotfix/critical-crash-fix
```

---

## Commit Message Convention

Follow [Conventional Commits](https://www.conventionalcommits.org/) for all commits.

### Format

```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

### Types and Version Impact

| Type | Description | Version Bump | Example |
|------|-------------|--------------|---------|
| `feat` | New feature | **MINOR** (0.x.0) | `feat(auth): add biometric login` |
| `fix` | Bug fix | **PATCH** (0.0.x) | `fix(timer): correct hours calculation` |
| `chore` | Maintenance | **PATCH** (0.0.x) | `chore(deps): update dependencies` |
| `docs` | Documentation | No version bump | `docs(readme): update installation steps` |
| `style` | Code style | No version bump | `style: format code with prettier` |
| `refactor` | Code refactoring | No version bump | `refactor(auth): simplify login logic` |
| `test` | Tests | No version bump | `test(auth): add login unit tests` |
| `perf` | Performance | **PATCH** (0.0.x) | `perf(list): optimize rendering` |

### Breaking Changes

For breaking changes, add `BREAKING CHANGE:` in the commit footer or use `!` after type:

```bash
feat(auth)!: redesign authentication flow

BREAKING CHANGE: Old authentication tokens are no longer valid
```

This will trigger a **MAJOR** version bump (x.0.0).

### Examples

```bash
# Minor version bump (new feature)
git commit -m "feat(notifications): add push notification support"

# Patch version bump (bug fix)
git commit -m "fix(registration): resolve timezone calculation error"

# Patch version bump (maintenance)
git commit -m "chore(deps): update riverpod to 3.1.0"

# No version bump (documentation)
git commit -m "docs(api): document authentication endpoints"

# Major version bump (breaking change)
git commit -m "feat(api)!: migrate to REST API v2

BREAKING CHANGE: API v1 endpoints are deprecated and removed"
```

---

## Branch Protection Rules

### `main` Branch

- ✅ Require pull request before merging
- ✅ Require approvals (1 reviewer minimum)
- ✅ Require status checks to pass
- ✅ Require conversation resolution
- ❌ Allow force pushes
- ❌ Allow deletions

### `dev` Branch

- ✅ Require pull request before merging
- ✅ Require status checks to pass
- ✅ Require conversation resolution
- ❌ Allow force pushes
- ❌ Allow deletions

---

## Versioning Strategy

Timely follows [Semantic Versioning](https://semver.org/) (SemVer):

```
MAJOR.MINOR.PATCH

Example: 1.2.3
```

- **MAJOR** (1.x.x): Breaking changes, incompatible API changes
- **MINOR** (x.2.x): New features, backwards compatible
- **PATCH** (x.x.3): Bug fixes, backwards compatible

### Version Sources

Version is managed in multiple files:
- `pubspec.yaml` - Flutter project version
- Android: `android/app/build.gradle` - `versionCode` and `versionName`
- iOS: `ios/Runner/Info.plist` - `CFBundleShortVersionString` and `CFBundleVersion`

GitHub Actions automatically updates all version files when merging to `main`.

---

## Best Practices

### 1. Read Command Help Output

Always read git flow command help output carefully before executing:
```bash
git flow feature help
git flow release help
git flow hotfix help
```

### 2. Git Flow and Standard Git Work Together

Git Flow is just a wrapper around standard git commands. You can use regular git commands alongside git flow commands:
```bash
# These work together seamlessly
git flow feature start my-feature
git add .
git commit -m "feat: add new functionality"
git push origin feature/my-feature
```

### 3. Keep Branches Short-Lived

- Feature branches should be merged within a few days.
- Don't let branches diverge too far from dev.
- Regularly sync with dev to avoid merge conflicts.

### 4. Meaningful Commit Messages

- Write clear, descriptive commit messages.
- Follow conventional commits format.
- Explain the "why" not just the "what".

### 5. Small, Focused Pull Requests

- One feature or fix per PR.
- Easier to review and test.
- Reduces merge conflicts.

### 6. Regular Updates

```bash
# Daily: update your feature branch with dev
git checkout feature/my-feature
git pull origin dev

# Resolve conflicts early and often
```

### 7. Clean Commit History

```bash
# Before creating PR, consider squashing commits
git rebase -i dev

# Or use "Squash and merge" option in GitHub
```

### 8. GUI Tools

For developers who prefer GUI tools, consider using:
- **Sourcetree** (macOS/Windows) - Has built-in git flow support.
- **GitKraken** - Visual git flow interface.
- **SourceTree** - Free Git GUI with git flow integration.

---

## Troubleshooting

### Merge Conflicts

```bash
# 1. Update branch with latest dev
git checkout feature/my-feature
git pull origin dev

# 2. Resolve conflicts in your editor
# Look for conflict markers: <<<<<<<, =======, >>>>>>>

# 3. Mark as resolved
git add .
git commit -m "resolve: merge conflicts with dev"

# 4. Push
git push origin feature/my-feature
```

### Accidental Commit to Wrong Branch

```bash
# If you committed to dev instead of a feature branch

# 1. Create feature branch from current state
git branch feature/my-feature

# 2. Reset dev to previous state
git checkout dev
git reset --hard origin/dev

# 3. Switch to feature branch
git checkout feature/my-feature

# 4. Push feature branch
git push origin feature/my-feature
```

### Need to Update Dev from Main

```bash
# After a hotfix or manual change to main

git checkout dev
git pull origin main
git push origin dev
```

---

## CI/CD Integration

Timely uses GitHub Actions for continuous integration and deployment:

- **On PR to dev**: Run tests, linting, code analysis
- **On merge to dev**: Run full test suite
- **On merge to main**:
  - Bump version automatically
  - Create git tag
  - Build Android APK/AAB
  - Build iOS IPA
  - Create GitHub Release
  - Attach build artifacts

See [CI_CD_WORKFLOW.md](./CI_CD_WORKFLOW.md) for detailed workflow documentation.

---

## Quick Reference

### Git Flow Commands

#### Feature Workflow
```bash
# Start feature
git flow feature start <name>

# Publish feature
git flow feature publish <name>

# Get remote feature
git flow feature track <name>

# Finish feature
git flow feature finish <name>
```

#### Release Workflow
```bash
# Start release
git flow release start <version>

# Publish release
git flow release publish <version>

# Finish release
git flow release finish <version>
```

#### Hotfix Workflow
```bash
# Start hotfix
git flow hotfix start <version>

# Finish hotfix
git flow hotfix finish <version>
```

### Standard Git Commands

#### Create Feature Branch
```bash
git checkout dev && git pull origin dev
git checkout -b feature/feature-name
```

#### Push Feature Branch
```bash
git push origin feature/feature-name
```

#### Delete Local Branch
```bash
git branch -d feature/feature-name
```

#### Delete Remote Branch
```bash
git push origin --delete feature/feature-name
```

#### Update Feature with Dev
```bash
git checkout feature/feature-name
git pull origin dev
```

#### List All Branches
```bash
git branch -a
```

---

## License

This documentation is part of the Timely project, licensed under a Custom Open Source License with Commercial Restrictions.

For complete terms, see the [LICENSE](../../LICENSE) file.

---

**Last Updated:** December 2025
