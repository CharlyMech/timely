import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Button that navigates to the data privacy information screen.
///
/// Displays an info icon that when tapped, navigates to `/data-privacy`
/// route. Typically used in app bars for easy access to privacy information.
class DataInfoButton extends StatelessWidget {
  const DataInfoButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: IconButton(
        icon: Icon(Icons.info_outline, color: theme.colorScheme.onSecondary),
        onPressed: () {
          context.push('/data-privacy');
        },
        tooltip: 'Información sobre el uso de datos',
      ),
    );
  }
}
