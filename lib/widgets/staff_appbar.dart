import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:timely/widgets/theme_toggle_button.dart';

class StaffAppBar extends StatefulWidget implements PreferredSizeWidget {
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
  State<StaffAppBar> createState() => _StaffAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(80);
}

class _StaffAppBarState extends State<StaffAppBar> {
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
      actions: const [ThemeToggleButton()],
      title: Row(
        children: [
          // Logo (ahora clickeable para scroll to top)
          GestureDetector(
            onTap: widget.onLogoTap,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: SvgPicture.asset(
                  widget.logoAssetPath,
                  height: 32,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to an icon if logo is not found
                    return Icon(
                      Icons.trending_up,
                      color: theme.primaryColor,
                      size: 28,
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
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
