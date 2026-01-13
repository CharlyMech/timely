# Contributing to Timely

[Ver versión en español](./CONTRIBUTING.esp.md)

## Overview

Welcome! We're excited you're interested in contributing to Timely. This document provides guidelines for contributing to the project through issues and pull requests.

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
- Focus on technical aspects of contributions
- Accept constructive criticism gracefully
- Help others learn and grow

---

## Getting Started

Before contributing, ensure you have:

### 1. **Read the documentation**
- [README.md](../../README.md) - Project overview
- [ARCHITECTURE.md](./ARCHITECTURE.md) - System architecture
- [USAGE.md](./USAGE.md) - How to use the project
- Familiarize yourself with the codebase organization

### 2. **Set up your development environment**
```bash
# Clone repository
git clone https://github.com/your-username/timely.git
cd timely

# Install dependencies
flutter pub get

# Run in development mode
flutter run --dart-define=FLAVOR=dev
```

### 3. **Understand the project structure**
- Review the Clean Architecture pattern
- Understand state management with Riverpod 3.0
- Learn about the dual environment setup (dev/prod)
- Study the models and their relationships

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
A clear description of what the bug is.

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
# Fork repository on GitHub
git clone https://github.com/YOUR-USERNAME/timely.git
cd timely

# Add upstream remote
git remote add upstream https://github.com/actual-owner/timely.git
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

- Follow our [coding standards](#coding-standards)
- Write tests for new functionality
- Update documentation if needed
- Ensure all tests pass

#### 4. Commit Your Changes

```bash
# Run tests
flutter test

# Run code analysis
flutter analyze

# Format code
flutter format .

# Stage your changes
git add .

# Commit with conventional message
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
7. **Create UI components** in `lib/screens/` and `lib/widgets/`

### State Management

- Use **Riverpod 3.0** with `Notifier` API
- Keep state **immutable** with `copyWith` methods
- Use `NotifierProvider.family` for parameterized state
- Use `ref.watch` in build methods
- Use `ref.read` in callbacks
- Use `Future.microtask` in `initState` for provider modifications

### Testing

- Write unit tests for ViewModels and Repositories
- Write widget tests for complex UI components
- Test error scenarios and edge cases
- Aim for high code coverage
- Test both mock and Firebase services when applicable

---

## Coding Standards

### Dart/Flutter Style

Follow the [official Dart style guide](https://dart.dev/guides/language/effective-dart/style):

```dart
// 1. Imports (sorted)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/employee.dart';
import '../repositories/employee_repository.dart';

// 2. Provider definitions
final employeeProvider = Provider<Employee>((ref) {
  throw UnimplementedError('Must be overridden');
});

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

### Code Organization

```dart
// 1. Documentation
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

We follow [Conventional Commits](https://www.conventionalcommits.org/) specification:

### Format

```
<type>(<scope>): <subject>

<body>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, missing semicolons, etc.)
- `refactor`: Code refactoring without functional changes
- `test`: Adding or updating tests
- `chore`: Maintenance tasks (dependency updates, etc.)
- `perf`: Performance improvements

### Examples

```bash
feat(auth): add biometric authentication
fix(timer): correct calculation of working hours
docs(readme): update installation instructions
style: format code with dart formatter
refactor(viewmodel): simplify employee loading logic
test(employee): add tests for edge cases
chore(deps): update flutter dependencies
perf(grid): optimize employee grid rendering
```

### Best Practices

- Use imperative mood ("add" not "added")
- Keep subject line under 50 characters
- Capitalize subject line
- Separate subject from body with blank line
- Wrap body at 72 characters
- Explain what and why, not how

---

## Testing

### Unit Tests

```dart
void main() {
  test('EmployeeViewModel loads employees', () async {
    // 1. Arrange
    final mockRepository = MockEmployeeRepository();
    when(mockRepository.getEmployeesWithTodayRegistration())
        .thenAnswer((_) async => [employee1, employee2]);

    final container = ProviderContainer(
      overrides: [
        employeeRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );

    // 2. Act
    await container
        .read(employeeViewModelProvider.notifier)
        .loadEmployees();

    // 3. Assert
    final state = container.read(employeeViewModelProvider);
    expect(state.employees.length, 2);
    expect(state.isLoading, false);
    expect(state.error, null);
  });
}
```

### Widget Tests

```dart
void main() {
  testWidgets('StaffScreen displays employees', (tester) async {
    // 1. Arrange
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          employeeViewModelProvider.overrideWith(
            () => MockEmployeeViewModel(),
          ),
        ],
        child: MaterialApp(
          home: StaffScreen(),
        ),
      ),
    );

    // 2. Act
    await tester.pumpAndSettle();

    // 3. Assert
    expect(find.text('Personal'), findsOneWidget);
    expect(find.byType(EmployeeCard), findsNWidgets(6));
  });
}
```

---

## Code Review Process

### For Reviewers

1. **Check functionality**: Does the code work as intended?
2. **Review architecture**: Does it follow Clean Architecture?
3. **Test coverage**: Are tests adequate for the changes?
4. **Code style**: Does it follow our coding standards?
5. **Performance**: Are there any performance implications?
6. **Documentation**: Is the code well documented?

### For Contributors

1. **Self-review**: Review your own code before submitting
2. **Test thoroughly**: Test happy path and edge cases
3. **Keep it small**: Smaller PRs are easier to review
4. **Address feedback**: Respond to review comments promptly

---

## Development Environment

### Required Tools

- Flutter SDK 3.10+
- Dart SDK 3.10+
- Git
- VS Code or Android Studio

### Recommended Extensions

- Dart extension for VS Code
- Flutter extension for VS Code
- GitLens for Git history visualization

### Environment Setup

```bash
# Development mode (mock data)
flutter run --dart-define=FLAVOR=dev

# Production mode (Firebase)
flutter run --dart-define=FLAVOR=prod

# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
flutter format .
```

---

## License

By contributing to Timely, you agree that your contributions will be licensed under the project's Custom Open Source License with Commercial Restrictions.

### Key Points

- You retain copyright to your contributions
- You grant the project owner (Carlos) rights to use your contributions
- Your contributions will be available to others under the same license
- The project owner maintains commercial distribution rights

See the [LICENSE](../../LICENSE) file for complete details.

---

## Questions?

If you have questions about contributing:

- Open a [GitHub Discussion](https://github.com/your-username/timely/discussions)
- Check existing documentation in `assets/docs/`
- Email: contacto@timely.app

---

Thank you for contributing to Timely! 🎉

---

**Last Updated:** January 2026