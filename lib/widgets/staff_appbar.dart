import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:timely/constants/themes.dart';
import 'package:timely/utils/responsive_utils.dart';
import 'package:timely/viewmodels/theme_viewmodel.dart';
import 'package:timely/widgets/data_info_button.dart';
import 'package:timely/widgets/theme_toggle_button.dart';

class StaffAppBar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  final String logoAssetPath;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchCleared;
  final VoidCallback? onLogoTap;

  const StaffAppBar({
    super.key,
    this.logoAssetPath = 'assets/images/logo.svg',
    this.onSearchChanged,
    this.onSearchCleared,
    this.onLogoTap,
  });

  @override
  ConsumerState<StaffAppBar> createState() => _StaffAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(80);
}

class _StaffAppBarState extends ConsumerState<StaffAppBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    widget.onSearchChanged?.call(_searchController.text);
  }

  void _clearSearch() {
    _searchController.clear();
    widget.onSearchCleared?.call();
    _searchFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 1,
      toolbarHeight: 80,
      backgroundColor: theme.appBarTheme.backgroundColor,
      titleSpacing: 16,
      actions: [
        if (context.responsive.isMobile)
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.more_vert,
              color: theme.colorScheme.onSurface,
            ),
            onSelected: (value) {
              if (value == 'theme') {
                final themeViewModel = ref.read(themeViewModelProvider.notifier);
                final themeState = ref.read(themeViewModelProvider);
                final brightness = MediaQuery.of(context).platformBrightness;

                final currentTheme = themeState.themeType == ThemeType.system
                    ? (brightness == Brightness.dark ? ThemeType.dark : ThemeType.light)
                    : themeState.themeType;

                final isDark = currentTheme == ThemeType.dark;
                themeViewModel.setTheme(isDark ? ThemeType.light : ThemeType.dark);
              } else if (value == 'info') {
                context.push('/data-privacy');
              }
            },
            itemBuilder: (context) {
              final themeState = ref.watch(themeViewModelProvider);
              final brightness = MediaQuery.of(context).platformBrightness;

              final currentTheme = themeState.themeType == ThemeType.system
                  ? (brightness == Brightness.dark ? ThemeType.dark : ThemeType.light)
                  : themeState.themeType;

              final isDark = currentTheme == ThemeType.dark;

              return [
                PopupMenuItem<String>(
                  value: 'theme',
                  child: Row(
                    children: [
                      Icon(
                        isDark ? Icons.light_mode : Icons.dark_mode,
                        size: 20,
                        color: theme.colorScheme.onSurface,
                      ),
                      const SizedBox(width: 12),
                      Text(isDark ? 'Modo claro' : 'Modo oscuro'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'info',
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: theme.colorScheme.onSurface,
                      ),
                      const SizedBox(width: 12),
                      const Text('Información de datos'),
                    ],
                  ),
                ),
              ];
            },
          )
        else ...[
          const ThemeToggleButton(),
          const DataInfoButton(),
        ],
      ],
      title: Row(
        children: [
          // Logo (ahora clickeable para scroll to top)
          GestureDetector(
            onTap: widget.onLogoTap,
            child: SizedBox(
              width: context.responsive.isMobile ? 40 : 48,
              height: context.responsive.isMobile ? 40 : 48,
              child: Center(
                child: SvgPicture.asset(
                  widget.logoAssetPath,
                  height: context.responsive.isMobile ? 28 : 32,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to an icon if logo is not found
                    return Icon(
                      Icons.trending_up,
                      color: theme.primaryColor,
                      size: context.responsive.isMobile ? 24 : 28,
                    );
                  },
                ),
              ),
            ),
          ),
          SizedBox(width: context.responsive.isMobile ? 12 : 16),
          // Search Bar
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Buscar empleado...',
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          onPressed: _clearSearch,
                        )
                      : Icon(
                          Icons.search,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                ),
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
