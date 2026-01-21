import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timely/viewmodels/employee_viewmodel.dart';
import 'package:timely/widgets/staff_appbar.dart';
import 'package:timely/widgets/pin_verification_dialog.dart';
import 'package:timely/utils/responsive_utils.dart';
import 'package:timely/layouts/mobile/staff_screen_mobile_layout.dart';
import 'package:timely/layouts/tablet/staff_screen_tablet_layout.dart';

/// Main staff management screen that displays employees in a responsive grid.
///
/// This screen provides search functionality to filter employees by name,
/// PIN verification when selecting an employee, automatic timeout after 5 minutes
/// of inactivity (redirecting to splash), and adapts its layout based on device
/// type (mobile/tablet). It handles loading states, errors, and empty search results.
class StaffScreen extends ConsumerStatefulWidget {
  const StaffScreen({super.key});

  @override
  ConsumerState<StaffScreen> createState() => _StaffScreenState();
}

/// State for [StaffScreen] that manages UI state and user interactions.
class _StaffScreenState extends ConsumerState<StaffScreen> {
  String _searchQuery = '';

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Handles search query changes and updates the filtered employee list.
  ///
  /// Converts the query to lowercase for case-insensitive matching.
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  /// Handles the search clear action by resetting the search query.
  void _onSearchCleared() {
    setState(() {
      _searchQuery = '';
    });
  }

  /// Scrolls the employee list to the top with smooth animation.
  ///
  /// Triggered when the user taps the logo in the app bar, providing
  /// a quick way to return to the top of a long employee list.
  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  /// Handles employee card tap by showing PIN verification dialog.
  ///
  /// Shows a PIN verification dialog for the tapped employee. On successful
  /// verification, navigates to the employee's time registration detail screen.
  Future<void> _onEmployeeTap(dynamic employee) async {
    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => PinVerificationDialog(
        correctPin: employee.pin,
        employeeName: employee.fullName,
      ),
    );

    if (verified == true && mounted) {
      context.push('/employee/${employee.id}');
    }
  }

  /// Normalizes a string by removing diacritics (accents) and converting to lowercase.
  ///
  /// This allows searching for names with accents
  String _normalizeText(String text) {
    const accents = 'áàäâãéèëêíìïîóòöôõúùüûñçÁÀÄÂÃÉÈËÊÍÌÏÎÓÒÖÔÕÚÙÜÛÑÇ';
    const normalized = 'aaaaaeeeeiiiiooooouuuuncAAAAAEEEEIIIIOOOOOUUUUNC';

    String result = text.toLowerCase();
    for (int i = 0; i < accents.length; i++) {
      result = result.replaceAll(accents[i], normalized[i]);
    }
    return result;
  }

  /// Filters employees based on the current search query.
  ///
  /// Returns all employees if the query is empty, otherwise returns only
  /// employees whose first name, last name, or full name contains the search
  /// query. The search is case-insensitive and accent-insensitive, so searching
  List<dynamic> _filterEmployees(List<dynamic> employees) {
    if (_searchQuery.isEmpty) {
      return employees;
    }

    final normalizedQuery = _normalizeText(_searchQuery);

    return employees.where((employee) {
      try {
        final firstName = _normalizeText(employee.firstName?.toString() ?? '');
        final lastName = _normalizeText(employee.lastName?.toString() ?? '');
        final fullName = '$firstName $lastName';

        return firstName.contains(normalizedQuery) ||
            lastName.contains(normalizedQuery) ||
            fullName.contains(normalizedQuery);
      } catch (e) {
        if (kDebugMode) {
          print('Error filtering employee: $e');
        }
        return false;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final employeeState = ref.watch(employeeViewModelProvider);

    return Scaffold(
      appBar: StaffAppBar(
        onSearchChanged: _onSearchChanged,
        onSearchCleared: _onSearchCleared,
        onLogoTap: _scrollToTop,
      ),
      body: employeeState.isLoading
          ? _buildLoadingState(theme)
          : employeeState.error != null
          ? _buildErrorState(theme, employeeState.error!)
          : _buildEmployeeGrid(_filterEmployees(employeeState.employees)),
    );
  }

  /// Builds the loading state widget with progress indicator.
  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        spacing: 16,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
          ),
          Text(
            'Cargando personal...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the error state widget with error message and retry button.
  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          spacing: 16,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(employeeViewModelProvider.notifier).loadEmployees();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the employee grid or list layout based on device type.
  ///
  /// Uses [StaffScreenMobileLayout] for mobile devices (vertical list) or
  /// [StaffScreenTabletLayout] for tablets (responsive grid). Includes
  /// pull-to-refresh and handles empty search results.
  Widget _buildEmployeeGrid(List<dynamic> employees) {
    if (employees.isEmpty && _searchQuery.isNotEmpty) {
      return _buildEmptySearchState();
    }

    final responsive = context.responsive;

    if (responsive.isMobile) {
      return StaffScreenMobileLayout(
        employees: employees,
        scrollController: _scrollController,
        onRefresh: () {
          ref.read(employeeViewModelProvider.notifier).refreshEmployees();
        },
        onEmployeeTap: _onEmployeeTap,
      );
    }

    return StaffScreenTabletLayout(
      employees: employees,
      scrollController: _scrollController,
      onRefresh: () {
        ref.read(employeeViewModelProvider.notifier).refreshEmployees();
      },
      onEmployeeTap: _onEmployeeTap,
    );
  }

  /// Builds the empty search results state widget.
  ///
  /// Displayed when the search query doesn't match any employees.
  Widget _buildEmptySearchState() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          spacing: 16,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            Text(
              'No se encontraron resultados',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Intenta con otros términos de búsqueda',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
