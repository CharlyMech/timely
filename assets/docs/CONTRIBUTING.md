# Contributing to Timely

[Ver versión en español](./CONTRIBUTING.esp.md)

Thank you for your interest in contributing to Timely! This document provides guidelines for contributing to the project through issues and pull requests.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting Features](#suggesting-features)
  - [Submitting Pull Requests](#submitting-pull-requests)
- [Development Guidelines](#development-guidelines)
- [Coding Standards](#coding-standards)
- [Commit Messages](#commit-messages)
- [License](#license)

---

## Code of Conduct

By participating in this project, you agree to maintain a respectful and collaborative environment. Please:

- Be respectful and constructive in discussions
- Focus on the technical aspects of contributions
- Accept constructive criticism gracefully
- Help others learn and grow

---

## Getting Started

Before contributing, ensure you have:

1. **Read the documentation**
   - [README.md](../../README.md) - Project overview
   - [ARCHITECTURE.md](./ARCHITECTURE.md) - System architecture
   - [USAGE.md](./USAGE.md) - How to use the project

2. **Set up your development environment**
   ```bash
   git clone https://github.com/your-username/timely.git
   cd timely
   flutter pub get
   flutter run --dart-define=FLAVOR=dev
   ```

3. **Understand the project structure**
   - Review the codebase organization
   - Familiarize yourself with the architecture
   - Understand state management with Riverpod 3.0

---

## How to Contribute

### Reporting Bugs

Found a bug? Help us fix it by creating a detailed issue.

#### Before Submitting a Bug Report

- Check if the bug has already been reported
- Verify the bug exists in the latest version
- Try to reproduce the bug consistently

#### Bug Report Template

```markdown
**Description**
A clear description of the bug.

**Steps to Reproduce**
1. Go to '...'
2. Click on '...'
3. Scroll down to '...'
4. See error

**Expected Behavior**
What you expected to happen.

**Actual Behavior**
What actually happened.

**Screenshots**
If applicable, add screenshots.

**Environment**
- Device: [e.g., Pixel 6]
- OS: [e.g., Android 13]
- Flutter version: [e.g., 3.10.0]
- App version: [e.g., 1.0.0]
- Mode: [dev/prod]

**Additional Context**
Any other relevant information.

**Logs**
```
Paste relevant logs here
```
```

### Suggesting Features

Have an idea to improve Timely? We'd love to hear it!

#### Feature Request Template

```markdown
**Feature Description**
A clear description of the feature.

**Problem it Solves**
Explain the problem this feature would solve.

**Proposed Solution**
Describe how you envision this feature working.

**Alternatives Considered**
Other solutions you've considered.

**Additional Context**
Mockups, examples, or references.

**Implementation Complexity**
Your estimate: Low / Medium / High / Unknown
```

### Submitting Pull Requests

Ready to contribute code? Follow these steps:

#### 1. Fork and Clone

```bash
# Fork the repository on GitHub
# Clone your fork
git clone https://github.com/YOUR-USERNAME/timely.git
cd timely

# Add upstream remote
git remote add upstream https://github.com/original-owner/timely.git
```

#### 2. Create a Branch

```bash
# Update main branch
git checkout main
git pull upstream main

# Create feature branch
git checkout -b feature/your-feature-name

# Or for bug fixes
git checkout -b fix/bug-description
```

#### 3. Make Your Changes

- Follow the [coding standards](#coding-standards)
- Write tests for new functionality
- Update documentation if needed
- Ensure all tests pass

```bash
# Run tests
flutter test

# Run code analysis
flutter analyze

# Format code
flutter format .
```

#### 4. Commit Your Changes

Follow our [commit message guidelines](#commit-messages):

```bash
git add .
git commit -m "feat: add dark mode toggle to settings"
```

#### 5. Push and Create Pull Request

```bash
# Push to your fork
git push origin feature/your-feature-name
```

Then create a pull request on GitHub with:

- **Clear title** following conventional commits format
- **Detailed description** of changes
- **Reference to related issues** (e.g., "Closes #123")
- **Screenshots/videos** if applicable
- **Testing instructions** for reviewers

#### Pull Request Template

```markdown
**Description**
Brief description of changes.

**Related Issues**
Closes #123
Related to #456

**Type of Change**
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

**Testing**
- [ ] All existing tests pass
- [ ] Added new tests for changes
- [ ] Manually tested on device/emulator

**Screenshots/Videos**
If applicable.

**Checklist**
- [ ] Code follows project style guidelines
- [ ] Self-reviewed my code
- [ ] Commented complex logic
- [ ] Updated documentation
- [ ] No new warnings
```

---

## Development Guidelines

### Architecture

Timely follows Clean Architecture principles:

```
Presentation (UI) → ViewModels → Repositories → Services
```

When adding features:

1. **Create models** in `lib/models/`
2. **Define service interface** in `lib/services/`
3. **Implement mock service** in `lib/services/mock/`
4. **Implement Firebase service** (optional) in `lib/services/firebase/`
5. **Create repository** in `lib/repositories/`
6. **Create ViewModel** in `lib/viewmodels/`
7. **Create UI** in `lib/screens/` and `lib/widgets/`
8. **Add routes** in `lib/config/router.dart`
9. **Write tests** in `test/`

### State Management

- Use **Riverpod 3.0** with `Notifier` API
- Keep state immutable
- Use `copyWith` for state updates
- Avoid modifying providers in `initState` (use `Future.microtask`)

### Testing

- Write unit tests for ViewModels and Repositories
- Write widget tests for complex UI components
- Aim for high code coverage
- Test edge cases and error scenarios

---

## Coding Standards

### Dart/Flutter Style

Follow the [official Dart style guide](https://dart.dev/guides/language/effective-dart/style):

- Use `lowerCamelCase` for variables and functions
- Use `UpperCamelCase` for classes
- Use `lowercase_with_underscores` for file names
- Prefix private members with `_`

### Code Organization

```dart
// 1. Imports (sorted)
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/employee.dart';
import '../repositories/employee_repository.dart';

// 2. Provider definitions
final employeeProvider = ...;

// 3. Class definition
class EmployeeViewModel extends Notifier<EmployeeState> {
  // 3.1. Static members
  static const maxRetries = 3;

  // 3.2. Instance variables
  late EmployeeRepository _repository;

  // 3.3. Constructor
  EmployeeViewModel();

  // 3.4. Overrides
  @override
  EmployeeState build() => const EmployeeState();

  // 3.5. Public methods
  Future<void> loadEmployees() async { }

  // 3.6. Private methods
  void _handleError(Object error) { }
}
```

### Documentation

- Document public APIs with dartdoc comments
- Add inline comments for complex logic only
- Keep comments up-to-date with code changes

```dart
/// Loads employees with their today's registration.
///
/// Returns a list of employees sorted by name.
/// Throws [EmployeeException] if loading fails.
Future<List<Employee>> loadEmployees() async {
  // Complex logic deserves a comment
  final registrations = await _getActiveRegistrations();
  return _combineEmployeesAndRegistrations(registrations);
}
```

---

## Commit Messages

We follow [Conventional Commits](https://www.conventionalcommits.org/):

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, missing semicolons, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks
- `perf`: Performance improvements

### Examples

```bash
feat(auth): add biometric authentication

fix(timer): correct calculation of working hours

docs(readme): update installation instructions

refactor(viewmodel): simplify employee loading logic

test(repository): add tests for edge cases

chore(deps): update dependencies to latest versions
```

### Best Practices

- Use imperative mood ("add" not "added")
- Keep subject line under 50 characters
- Capitalize subject line
- Don't end subject with a period
- Separate subject from body with blank line
- Wrap body at 72 characters
- Explain what and why, not how

---

## License

By contributing to Timely, you agree that your contributions will be licensed under the project's Custom Open Source License with Commercial Restrictions.

### Key Points

- You retain copyright to your contributions
- You grant the project owner (Carlos) rights to use your contributions
- You grant the project owner commercial distribution rights
- Your contributions will be available to others under the same license terms

See the [LICENSE](../../LICENSE) file for complete details.

---

## Questions?

If you have questions about contributing:

- Open a [GitHub Discussion](https://github.com/your-username/timely/discussions)
- Email: contacto@timely.app
- Check existing documentation in `assets/docs/`

---

Thank you for contributing to Timely! 🎉

---

**Last Updated:** December 2025
