# Contributing to Timely

Thank you for your interest in contributing to Timely! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

- [Before You Start](#before-you-start)
- [License Acknowledgment](#license-acknowledgment)
- [Getting Started](#getting-started)
  - [Development Setup](#development-setup)
  - [Running the Application](#running-the-application)
- [Development Workflow](#development-workflow)
  - [Branch Naming Conventions](#branch-naming-conventions)
  - [Commit Message Guidelines](#commit-message-guidelines)
- [Code Standards](#code-standards)
  - [Flutter Style Guide](#flutter-style-guide)
  - [Code Formatting](#code-formatting)
  - [Linting](#linting)
- [Pull Request Process](#pull-request-process)
  - [Before Submitting](#before-submitting)
  - [PR Template](#pr-template)
  - [Review Process](#review-process)
- [Issue Reporting](#issue-reporting)
  - [Bug Reports](#bug-reports)
  - [Feature Requests](#feature-requests)
  - [Issue Labels](#issue-labels)
- [Testing Guidelines](#testing-guidelines)
- [Documentation](#documentation)

---

## Before You Start

### Important Notes

1. **Read the Documentation**: Familiarize yourself with the project by reading:
   - [README.md](./README.md) - Project overview and setup
   - [DATA.md](./DATA.md) - Data architecture
   - [APP_FLOW.md](./APP_FLOW.md) - Application flow and navigation
   - [GLOBAL_STATE.md](./GLOBAL_STATE.md) - State management

2. **Check Existing Issues**: Before starting work, check if an issue already exists for your proposed change.

3. **Discuss Major Changes**: For significant features or architectural changes, open an issue to discuss the approach before implementing.

---

## License Acknowledgment

**IMPORTANT**: Timely is licensed under the **PolyForm Noncommercial License 1.0.0**, which is a source-available license, NOT an open source license.

### What This Means for Contributors

By contributing to Timely, you acknowledge and agree that:

1. **Your contributions will be licensed under the same terms** as the project (PolyForm Noncommercial License 1.0.0)
2. **You grant the project maintainer** (Carlos Sánchez Recio) the right to incorporate your contributions into the project
3. **No additional rights or ownership** are granted to contributors beyond those in the license
4. **Commercial use** of the project (including your contributions) requires a separate commercial license from the project owner
5. **You retain copyright** to your original contributions, but license them to the project under the PolyForm Noncommercial License

### Contribution Agreement

By submitting a pull request, you agree that:

- You have the right to submit the contribution
- Your contribution does not violate any third-party rights
- Your contribution may be used, modified, and distributed as part of Timely under the PolyForm Noncommercial License
- The project maintainer may include your contribution in commercial versions under a commercial license

### License References

- **Main License**: [LICENSE](../LICENSE)
- **Commercial License Information**: [COMMERCIAL_LICENSE.md](../COMMERCIAL_LICENSE.md)

If you have questions about the license or contribution terms, please contact the project maintainer before submitting contributions.

---

## Getting Started

### Development Setup

1. **Fork the Repository**:
   ```bash
   # Fork on GitHub, then clone your fork
   git clone https://github.com/YOUR_USERNAME/timely.git
   cd timely
   ```

2. **Add Upstream Remote**:
   ```bash
   git remote add upstream https://github.com/charlymech/timely.git
   ```

3. **Install Dependencies**:
   ```bash
   # Flutter dependencies
   flutter pub get

   # (Optional) Node.js dependencies for Firebase scripts
   cd scripts
   npm install
   cd ..
   ```

4. **Verify Setup**:
   ```bash
   flutter doctor
   flutter analyze
   ```

### Running the Application

**Development Mode** (Mock data):
```bash
flutter run --dart-define=FLAVOR=dev
```

**Production Mode** (Firebase):
```bash
# Ensure Firebase is configured first
flutter run --dart-define=FLAVOR=prod
```

**Run Tests**:
```bash
flutter test
```

**Run Linter**:
```bash
flutter analyze
```

---

## Development Workflow

### Branch Naming Conventions

Create a new branch for each feature or fix using the following format:

```
<type>/<short-description>
```

**Branch Types**:

| Type | Description | Example |
|------|-------------|---------|
| `feat/` | New feature | `feat/shift-calendar-view` |
| `fix/` | Bug fix | `fix/time-calculation-error` |
| `chore/` | Maintenance tasks | `chore/update-dependencies` |
| `docs/` | Documentation only | `docs/update-contributing-guide` |
| `refactor/` | Code refactoring | `refactor/employee-viewmodel` |
| `test/` | Adding tests | `test/time-registration-service` |
| `style/` | Code style/formatting | `style/fix-linting-errors` |
| `perf/` | Performance improvements | `perf/optimize-employee-list` |

**Examples**:
```bash
git checkout -b feat/export-registrations
git checkout -b fix/pin-verification-dialog
git checkout -b chore/upgrade-flutter-3.11
git checkout -b docs/add-api-documentation
```

### Workflow Steps

1. **Sync with Upstream**:
   ```bash
   git fetch upstream
   git checkout main
   git merge upstream/main
   ```

2. **Create Branch**:
   ```bash
   git checkout -b feat/your-feature-name
   ```

3. **Make Changes**:
   - Write code following [Code Standards](#code-standards)
   - Test your changes thoroughly
   - Update documentation if needed

4. **Commit Changes**:
   ```bash
   git add .
   git commit -m "feat: add export to CSV functionality"
   ```

5. **Push to Fork**:
   ```bash
   git push origin feat/your-feature-name
   ```

6. **Create Pull Request**:
   - Go to GitHub and create a PR from your fork to the main repository
   - Fill out the PR template completely
   - Wait for review

### Commit Message Guidelines

Follow the **Conventional Commits** specification:

```
<type>(<scope>): <short description>

<optional body>

<optional footer>
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, semicolons, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks (dependencies, config, etc.)
- `perf`: Performance improvements

**Examples**:

```bash
feat: add monthly registration report

feat(registrations): implement CSV export functionality

fix: correct time calculation when pause spans midnight

fix(gauge): prevent division by zero in progress calculation

docs: update installation instructions for Firebase setup

chore: upgrade Riverpod to version 3.0.4

test: add unit tests for TimeRegistration model

refactor(viewmodels): extract common loading logic
```

**Guidelines**:
- Use present tense ("add" not "added")
- Use imperative mood ("move" not "moves")
- First line should be 50 characters or less
- Separate subject from body with blank line
- Wrap body at 72 characters
- Explain what and why, not how

---

## Code Standards

### Flutter Style Guide

Follow the [official Flutter style guide](https://dart.dev/guides/language/effective-dart/style) and these project-specific conventions:

1. **File Organization**:
   ```
   lib/
   ├── models/          # Data models
   ├── services/        # Business logic
   ├── repositories/    # Data orchestration
   ├── viewmodels/      # State management
   ├── screens/         # UI screens
   ├── widgets/         # Reusable components
   ├── layouts/         # Responsive layouts
   ├── utils/           # Helper functions
   ├── config/          # App configuration
   └── constants/       # Constants
   ```

2. **Naming Conventions**:
   - **Files**: `snake_case.dart` (e.g., `employee_service.dart`)
   - **Classes**: `PascalCase` (e.g., `EmployeeService`)
   - **Variables/Methods**: `camelCase` (e.g., `loadEmployees`)
   - **Constants**: `camelCase` (e.g., `primaryColor`)
   - **Private members**: `_leadingUnderscore` (e.g., `_loadData`)

3. **Import Organization**:
   ```dart
   // Dart imports
   import 'dart:async';
   import 'dart:convert';

   // Flutter imports
   import 'package:flutter/material.dart';

   // Package imports
   import 'package:flutter_riverpod/flutter_riverpod.dart';
   import 'package:go_router/go_router.dart';

   // Project imports
   import 'package:timely/models/employee.dart';
   import 'package:timely/services/employee_service.dart';
   ```

4. **Code Structure**:
   - Maximum line length: 80 characters
   - Use trailing commas for better diffs
   - Prefer `const` constructors when possible
   - Use named parameters for clarity
   - Avoid deep nesting (max 3-4 levels)

### Code Formatting

**Auto-format Before Committing**:
```bash
flutter format .
```

**VS Code Settings** (recommended):
```json
{
  "editor.formatOnSave": true,
  "dart.lineLength": 80,
  "[dart]": {
    "editor.rulers": [80],
    "editor.selectionHighlight": false,
    "editor.suggest.snippetsPreventQuickSuggestions": false,
    "editor.suggestSelection": "first",
    "editor.tabCompletion": "onlySnippets",
    "editor.wordBasedSuggestions": false
  }
}
```

### Linting

The project uses `flutter_lints` for static analysis.

**Run Linter**:
```bash
flutter analyze
```

**Fix Auto-fixable Issues**:
```bash
dart fix --apply
```

**Common Lint Rules**:
- No unused imports
- Prefer `const` constructors
- Avoid `print()` statements (use proper logging)
- Always use curly braces for control flow
- Prefer single quotes for strings
- No implicit dynamic types

---

## Pull Request Process

### Before Submitting

Ensure your PR meets these requirements:

- [ ] Code follows the [Code Standards](#code-standards)
- [ ] All tests pass (`flutter test`)
- [ ] No linting errors (`flutter analyze`)
- [ ] Code is formatted (`flutter format .`)
- [ ] Documentation is updated (if applicable)
- [ ] Commit messages follow [guidelines](#commit-message-guidelines)
- [ ] Branch is up to date with `main`

### PR Template

When creating a pull request, include:

```markdown
## Description
Brief description of what this PR does and why.

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Related Issues
Closes #[issue number]

## Changes Made
- Change 1
- Change 2
- Change 3

## Testing
Describe how you tested your changes:
- Test scenario 1
- Test scenario 2

## Screenshots (if applicable)
Add screenshots for UI changes.

## Checklist
- [ ] My code follows the project's code style
- [ ] I have performed a self-review of my code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have updated the documentation accordingly
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes

## Additional Notes
Any additional information for reviewers.
```

### Review Process

1. **Automated Checks**: GitHub Actions will run tests and linting
2. **Code Review**: Maintainer will review your code
3. **Feedback**: Address any requested changes
4. **Approval**: Once approved, maintainer will merge

**Response Time**:
- Initial review: Within 1 week
- Follow-up reviews: Within 3-5 days

**Review Criteria**:
- Code quality and readability
- Adherence to project architecture
- Test coverage
- Documentation completeness
- Performance impact

---

## Issue Reporting

### Bug Reports

Use the bug report template when creating an issue:

```markdown
**Describe the Bug**
A clear and concise description of the bug.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '...'
3. Scroll down to '...'
4. See error

**Expected Behavior**
What you expected to happen.

**Screenshots**
If applicable, add screenshots.

**Environment**
- Device: [e.g., iPhone 12, Pixel 5]
- OS: [e.g., iOS 15.0, Android 12]
- App Version: [e.g., 1.0.0]
- Mode: [Dev/Prod]

**Additional Context**
Any other context about the problem.

**Logs**
```
Paste relevant error logs here
```
```

### Feature Requests

Use the feature request template:

```markdown
**Feature Description**
A clear description of the feature you'd like to see.

**Problem It Solves**
Explain the problem this feature would solve.

**Proposed Solution**
Describe how you envision this feature working.

**Alternatives Considered**
Any alternative solutions you've thought about.

**Additional Context**
Any other context, mockups, or examples.
```

### Issue Labels

Issues are categorized with labels:

| Label | Description |
|-------|-------------|
| `bug` | Something isn't working |
| `enhancement` | New feature or request |
| `documentation` | Documentation improvements |
| `good first issue` | Good for newcomers |
| `help wanted` | Extra attention needed |
| `question` | Further information requested |
| `duplicate` | Already exists |
| `wontfix` | Will not be worked on |
| `priority: high` | High priority issue |
| `priority: medium` | Medium priority |
| `priority: low` | Low priority |

---

## Testing Guidelines

### Unit Tests

Write unit tests for:
- Data models (serialization, validation, computed properties)
- Service methods (Firebase and Mock implementations)
- ViewModels (state changes, business logic)
- Utility functions

**Example**:
```dart
// test/models/time_registration_test.dart
void main() {
  group('TimeRegistration', () {
    test('calculates total minutes correctly', () {
      final registration = TimeRegistration(
        id: '1',
        employeeId: 'emp1',
        shiftId: 'shift1',
        startTime: DateTime(2025, 1, 1, 8, 0),
        endTime: DateTime(2025, 1, 1, 16, 0),
        date: '01/01/2025',
      );

      expect(registration.totalMinutes, 480);
    });

    test('subtracts pause time from total', () {
      final registration = TimeRegistration(
        id: '1',
        employeeId: 'emp1',
        shiftId: 'shift1',
        startTime: DateTime(2025, 1, 1, 8, 0),
        endTime: DateTime(2025, 1, 1, 17, 0),
        pauseTime: DateTime(2025, 1, 1, 12, 0),
        resumeTime: DateTime(2025, 1, 1, 13, 0),
        date: '01/01/2025',
      );

      expect(registration.totalMinutes, 480); // 9h - 1h pause = 8h
    });
  });
}
```

### Widget Tests

Write widget tests for:
- Custom widgets
- Screen layouts
- User interactions

**Example**:
```dart
// test/widgets/employee_card_test.dart
void main() {
  testWidgets('EmployeeCard displays employee name', (tester) async {
    final employee = Employee(
      id: '1',
      firstName: 'John',
      lastName: 'Doe',
      pin: '123456',
      status: EmployeeStatus.active,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmployeeCard(
            employee: employee,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('John Doe'), findsOneWidget);
  });
}
```

### Integration Tests

Write integration tests for:
- Complete user flows
- Navigation between screens
- State synchronization

**Run Tests**:
```bash
# Unit tests
flutter test

# Widget tests
flutter test test/widgets/

# Integration tests
flutter test integration_test/
```

---

## Documentation

### When to Update Documentation

Update documentation when you:
- Add or modify features
- Change architecture or patterns
- Add new dependencies
- Change configuration or setup steps
- Add or change APIs

### Documentation Files

| File | Purpose |
|------|---------|
| [README.md](./README.md) | Project overview, setup, usage |
| [DATA.md](./DATA.md) | Data models, services, repositories |
| [APP_FLOW.md](./APP_FLOW.md) | Navigation, screens, layouts, theming |
| [GLOBAL_STATE.md](./GLOBAL_STATE.md) | State management, ViewModels |
| [CONTRIBUTING.md](./CONTRIBUTING.md) | This file |
| [CONTACT.md](./CONTACT.md) | Author and contact information |

### Code Comments

**Use Comments For**:
- Complex algorithms or business logic
- Non-obvious design decisions
- Workarounds or temporary solutions
- Public APIs and interfaces

**Don't Comment**:
- Self-explanatory code
- Redundant information
- Commented-out code (delete it)

**Example**:
```dart
// ✅ Good - explains why
// We round to nearest 5 minutes to match company policy
final roundedMinutes = (minutes / 5).round() * 5;

// ❌ Bad - states the obvious
// Increment counter by 1
counter = counter + 1;
```

---

## Getting Help

If you need help:

1. **Check Documentation**: Read the docs in the `/docs` folder
2. **Search Issues**: Look for existing issues on GitHub
3. **Ask Questions**: Open a GitHub issue with the `question` label
4. **Contact Maintainer**: See [CONTACT.md](./CONTACT.md) for contact information

---

## Code of Conduct

### Expected Behavior

- Be respectful and considerate
- Welcome newcomers and help them learn
- Accept constructive criticism gracefully
- Focus on what is best for the project
- Show empathy towards others

### Unacceptable Behavior

- Harassment or discrimination of any kind
- Trolling, insulting, or derogatory comments
- Publishing others' private information
- Other conduct inappropriate in a professional setting

### Enforcement

Violations of the code of conduct may result in:
1. Warning
2. Temporary ban from the project
3. Permanent ban from the project

Report violations to: sanchezreciocarlos99@outlook.com

---

## Recognition

Contributors will be acknowledged in:
- GitHub contributors list
- Release notes for significant contributions
- Project README (for major features)

---

## Thank You!

Thank you for contributing to Timely! Your efforts help make this project better for everyone.

For questions about contributing, please open an issue or contact the maintainer via [CONTACT.md](./CONTACT.md).

---

**Project Maintainer**: Carlos Sánchez Recio (CharlyMech)

**Repository**: https://github.com/charlymech/timely

**License**: PolyForm Noncommercial License 1.0.0 (see [LICENSE](../LICENSE))
