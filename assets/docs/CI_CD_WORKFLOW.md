# CI/CD Workflow Documentation

[Ver versión en español](./CI_CD_WORKFLOW.esp.md)

## Overview

Timely uses **GitHub Actions** for Continuous Integration and Continuous Deployment (CI/CD). The workflow automates version management, building, testing, and releasing the application.

## Workflow Files

### 1. **Release Workflow** (`.github/workflows/release.yml`)

Triggered when code is merged to `main` branch.

**Purpose:**
- Automatically bump version based on commit messages
- Create git tags
- Build production-ready artifacts (APK, AAB, IPA)
- Create GitHub Release with downloadable artifacts

### 2. **PR Checks Workflow** (`.github/workflows/pr-checks.yml`)

Triggered on pull requests to `dev` or `main` branches.

**Purpose:**
- Lint and format code
- Run static analysis
- Execute tests
- Verify builds
- Validate commit messages

---

## Release Workflow (Detailed)

### Trigger

```yaml
on:
  push:
    branches:
      - main
```

Activates when:
- A pull request is merged to `main`
- A direct push is made to `main` (not recommended)

### Jobs

#### Job 1: Version Bump and Release

**Runs on:** `ubuntu-latest`

**Steps:**

1. **Checkout Code**
   - Fetches full git history
   - Required for semantic-release to analyze commits

2. **Setup Node.js**
   - Installs Node.js 20
   - Required for semantic-release tools

3. **Install semantic-release**
   - Installs semantic-release and plugins:
     - `@semantic-release/commit-analyzer` - Analyzes commits
     - `@semantic-release/release-notes-generator` - Generates changelog
     - `@semantic-release/changelog` - Updates CHANGELOG.md
     - `@semantic-release/exec` - Executes version update script
     - `@semantic-release/git` - Commits version changes
     - `@semantic-release/github` - Creates GitHub Release

4. **Create Configuration**
   - Generates `.releaserc.json` with release rules:

```json
{
  "releaseRules": [
    {"type": "chore", "release": "major"},     // x.0.0
    {"type": "feat", "release": "minor"},      // 0.x.0
    {"type": "fix", "release": "patch"},       // 0.0.x
    {"type": "perf", "release": "patch"},      // 0.0.x
    {"type": "docs", "release": false},        // No release
    {"type": "style", "release": false},       // No release
    {"type": "refactor", "release": false},    // No release
    {"type": "test", "release": false}         // No release
  ]
}
```

5. **Create Version Update Script**
   - Generates `scripts/update-version.sh`
   - Updates version in multiple files:
     - `pubspec.yaml` - Flutter version
     - `android/app/build.gradle` - Android version
     - `ios/Runner/Info.plist` - iOS version

6. **Run semantic-release**
   - Analyzes commits since last release
   - Determines new version
   - Updates version files
   - Creates git tag
   - Commits changes
   - Creates GitHub Release

**Outputs:**
- `version`: New version number (e.g., "1.2.3")
- `released`: Boolean, true if new version was released

#### Job 2: Build Android

**Runs on:** `ubuntu-latest`
**Depends on:** Version Bump
**Condition:** Only if new version was released

**Steps:**

1. **Checkout Code**
   - Fetches latest code from `main`

2. **Setup Java 17**
   - Required for Android builds

3. **Setup Flutter**
   - Installs Flutter 3.10.0 stable

4. **Install Dependencies**
   ```bash
   flutter pub get
   ```

5. **Run Tests**
   ```bash
   flutter test
   ```

6. **Build APK**
   ```bash
   flutter build apk --release --dart-define=FLAVOR=prod
   ```
   - Generates: `app-release.apk`
   - For testing and sideloading

7. **Build App Bundle (AAB)**
   ```bash
   flutter build appbundle --release --dart-define=FLAVOR=prod
   ```
   - Generates: `app-release.aab`
   - For Google Play Store distribution

8. **Rename Artifacts**
   - Renames to include version:
     - `timely-v1.2.3.apk`
     - `timely-v1.2.3.aab`

9. **Upload Artifacts**
   - Stores in GitHub Actions artifacts (90 days)
   - Uploads to GitHub Release

**Artifacts:**
- `timely-v{version}.apk` - ~50-100 MB
- `timely-v{version}.aab` - ~30-50 MB

#### Job 3: Build iOS

**Runs on:** `macos-latest`
**Depends on:** Version Bump
**Condition:** Only if new version was released

**Steps:**

1. **Checkout Code**

2. **Setup Flutter**

3. **Install Dependencies**

4. **Run Tests**

5. **Build iOS**
   ```bash
   flutter build ios --release --dart-define=FLAVOR=prod --no-codesign
   ```
   - Builds without code signing
   - For development and testing

6. **Create IPA Archive**
   ```bash
   cd build/ios/iphoneos
   mkdir Payload
   cp -r Runner.app Payload/
   zip -r app-release.ipa Payload
   ```

7. **Rename and Upload**
   - Renames to: `timely-v{version}.ipa`
   - Uploads to GitHub Release

**Note:** For App Store distribution, you'll need to:
- Set up code signing certificates
- Configure provisioning profiles
- Use Fastlane or Xcode Cloud

**Artifacts:**
- `timely-v{version}.ipa` - ~50-100 MB

#### Job 4: Notify Completion

**Runs on:** `ubuntu-latest`
**Depends on:** All previous jobs
**Condition:** Always runs if version was released

**Purpose:**
- Creates build summary in GitHub Actions UI
- Shows status of all builds
- Provides link to release page

---

## PR Checks Workflow (Detailed)

### Trigger

```yaml
on:
  pull_request:
    branches:
      - dev
      - main
```

### Jobs

#### Job 1: Lint and Test

**Steps:**

1. **Format Check**
   ```bash
   flutter format --set-exit-if-changed .
   ```
   - Ensures code follows Dart formatting

2. **Static Analysis**
   ```bash
   flutter analyze
   ```
   - Checks for potential errors and warnings

3. **Run Tests with Coverage**
   ```bash
   flutter test --coverage
   ```
   - Executes all unit and widget tests
   - Generates coverage report

4. **Upload Coverage**
   - Sends coverage to Codecov (optional)

#### Job 2: Build Check

**Purpose:**
- Verifies the app builds successfully
- Uses dev flavor to speed up builds

```bash
flutter build apk --debug --dart-define=FLAVOR=dev
```

#### Job 3: Commit Message Check

**Purpose:**
- Validates commit messages follow Conventional Commits

**Valid types:**
- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation
- `style:` - Code style
- `refactor:` - Code refactoring
- `perf:` - Performance improvements
- `test:` - Tests
- `chore:` - Maintenance

**Example validation:**
```bash
✓ feat(auth): add biometric login
✓ fix(timer): resolve calculation error
✗ updated readme  # Missing type
✗ Fixed bug       # Wrong format
```

---

## Version Management

### Semantic Versioning

Timely follows [SemVer](https://semver.org/): `MAJOR.MINOR.PATCH`

**Automated version bumps:**

| Commit Type | Version Change | Example |
|-------------|----------------|---------|
| `chore:` | MAJOR (x.0.0) | 1.2.0 → 2.0.0 |
| `feat:` | MINOR (0.x.0) | 1.2.0 → 1.3.0 |
| `fix:` | PATCH (0.0.x) | 1.2.0 → 1.2.1 |
| `perf:` | PATCH (0.0.x) | 1.2.0 → 1.2.1 |

### Version Files Updated

1. **`pubspec.yaml`**
   ```yaml
   version: 1.2.3+45
   ```
   - Format: `version+build`
   - Build number auto-increments

2. **`android/app/build.gradle`**
   ```gradle
   versionName "1.2.3"
   versionCode 45
   ```
   - `versionName`: Displayed to users
   - `versionCode`: Internal, must increment

3. **`ios/Runner/Info.plist`**
   ```xml
   <key>CFBundleShortVersionString</key>
   <string>1.2.3</string>
   <key>CFBundleVersion</key>
   <string>45</string>
   ```
   - `CFBundleShortVersionString`: Displayed version
   - `CFBundleVersion`: Build number

---

## Build Artifacts

### Android

**APK (Android Package)**
- **File:** `timely-v{version}.apk`
- **Size:** ~50-100 MB
- **Use case:**
  - Direct installation on devices
  - Testing and QA
  - Distribution outside Play Store

**AAB (Android App Bundle)**
- **File:** `timely-v{version}.aab`
- **Size:** ~30-50 MB
- **Use case:**
  - **Google Play Store** (required format)
  - Optimized for device configurations
  - Dynamic delivery

### iOS

**IPA (iOS App Store Package)**
- **File:** `timely-v{version}.ipa`
- **Size:** ~50-100 MB
- **Use case:**
  - Testing on devices
  - TestFlight distribution
  - App Store distribution (with signing)

---

## Publishing to Stores

### Google Play Store

1. **Prepare AAB**
   - Download `timely-v{version}.aab` from GitHub Release

2. **Upload to Play Console**
   - Go to [Google Play Console](https://play.google.com/console)
   - Select your app
   - Production → Create new release
   - Upload AAB file

3. **Configure Release**
   - Add release notes
   - Set rollout percentage
   - Submit for review

**Automation (Future):**
```yaml
# Can be automated with:
- Fastlane + Supply plugin
- Google Play Developer API
```

### Apple App Store

1. **Code Sign IPA**
   - Requires Apple Developer account
   - Configure certificates and provisioning profiles
   - Use Xcode or Fastlane

2. **Upload to App Store Connect**
   - Use Xcode or Transporter app
   - Submit for TestFlight or review

3. **App Store Review**
   - Add screenshots, description
   - Submit for review

**Automation (Future):**
```yaml
# Can be automated with:
- Fastlane + Deliver plugin
- Xcode Cloud
```

---

## Workflow Diagram

```
┌─────────────────────────────────────────┐
│     Developer creates PR to dev         │
└────────────────┬────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────┐
│      PR Checks Workflow runs            │
│  - Lint & Format                        │
│  - Analyze                              │
│  - Test                                 │
│  - Build check                          │
│  - Commit message validation            │
└────────────────┬────────────────────────┘
                 │
                 ↓ (All checks pass)
┌─────────────────────────────────────────┐
│     PR merged to dev                    │
│     (No deployment, tests only)         │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│     Create PR from dev to main          │
└────────────────┬────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────┐
│      PR Checks run again                │
└────────────────┬────────────────────────┘
                 │
                 ↓ (All checks pass)
┌─────────────────────────────────────────┐
│     PR merged to main                   │
└────────────────┬────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────┐
│     Release Workflow triggers           │
└────────────────┬────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────┐
│   semantic-release analyzes commits     │
│   - Determines version bump             │
│   - Updates version files               │
│   - Creates CHANGELOG.md                │
│   - Creates git tag                     │
│   - Commits changes [skip ci]           │
└────────────────┬────────────────────────┘
                 │
                 ├─────────────┬─────────────┐
                 ↓             ↓             ↓
        ┌────────────┐ ┌──────────┐ ┌──────────┐
        │Build Android│ │Build iOS │ │ Notify   │
        │  APK + AAB  │ │   IPA    │ │          │
        └──────┬──────┘ └────┬─────┘ └────┬─────┘
               │             │            │
               └─────────────┴────────────┘
                            │
                            ↓
               ┌────────────────────────┐
               │  GitHub Release Created │
               │  - Tag: v1.2.3          │
               │  - Changelog            │
               │  - APK download         │
               │  - AAB download         │
               │  - IPA download         │
               └────────────────────────┘
```

---

## Configuration

### Required Secrets

None required for basic workflow. Optional:

- `CODECOV_TOKEN` - For code coverage reports
- `SLACK_WEBHOOK` - For build notifications
- `FIREBASE_TOKEN` - For Firebase App Distribution

### Branch Protection Rules

**`main` branch:**
- ✅ Require pull request reviews
- ✅ Require status checks to pass:
  - `Lint and Test`
  - `Build Check`
  - `Commit Message Check`
- ✅ Require conversation resolution
- ❌ Allow force pushes

**`dev` branch:**
- ✅ Require pull request reviews
- ✅ Require status checks to pass
- ❌ Allow force pushes

---

## Troubleshooting

### Build Fails

**Check:**
1. Flutter version compatibility
2. Dependency issues (`flutter pub get`)
3. Test failures (`flutter test`)
4. Build configuration

**View logs:**
- GitHub Actions → Failed workflow → Job logs

### Version Not Bumping

**Possible causes:**
1. No commits with version-bumping types (`feat`, `fix`, etc.)
2. Only `docs` or `style` commits
3. Semantic-release configuration error

**Solution:**
- Ensure commits follow Conventional Commits format
- Check `.releaserc.json` configuration

### Artifacts Not Uploading

**Check:**
1. Build completed successfully
2. Artifacts exist in expected paths
3. GitHub token permissions

---

## Best Practices

### 1. Meaningful Commits

```bash
# Good
feat(auth): add fingerprint authentication
fix(timer): resolve calculation rounding error

# Bad
updated code
fixed bug
```

### 2. Test Before PR

```bash
# Run locally before creating PR
flutter format .
flutter analyze
flutter test
flutter build apk --debug --dart-define=FLAVOR=dev
```

### 3. Small, Focused PRs

- One feature per PR
- Easier to review
- Faster CI/CD execution

### 4. Monitor Workflow Runs

- Check GitHub Actions tab
- Review build logs
- Verify artifacts

---

## License

This documentation is part of the Timely project, licensed under a Custom Open Source License with Commercial Restrictions.

For complete terms, see the [LICENSE](../../LICENSE) file.

---

**Last Updated:** December 2025
