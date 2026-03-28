import 'package:flutter/material.dart';
import 'package:timely/widgets/custom_card.dart';
import 'package:timely/widgets/custom_text.dart';

/// Tablet-optimized layout for time registration detail screen.
///
/// Provides a vertical scrollable layout with larger spacing and padding
/// compared to mobile. Displays the time gauge, action buttons, and optional
/// shift information optimized for tablet screen sizes.
class TimeRegistrationDetailTabletLayout extends StatelessWidget {
  /// Widget displaying the circular time progress gauge.
  final Widget gaugeWidget;

  /// Widget containing action buttons (start, pause, resume, end).
  final Widget actionButtons;

  /// Optional widget showing shift schedule information.
  final Widget? shiftInfo;

  /// Optional widget displaying detailed registration information.
  final Widget? registrationDetails;

  /// Optional banner widget displayed at the top (e.g., no-shift warning).
  final Widget? banner;

  const TimeRegistrationDetailTabletLayout({
    super.key,
    required this.gaugeWidget,
    required this.actionButtons,
    this.shiftInfo,
    this.registrationDetails,
    this.banner,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Column(
        spacing: 24,
        children: [
          // Banner (e.g., no-shift warning)
          if (banner != null) banner!,

          // Gauge Card
          CustomCard(
            width: double.infinity,
            child: Column(
              spacing: 20,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TitleText("Registro actual:"),
                Center(child: gaugeWidget),
              ],
            ),
          ),

          // Action buttons
          actionButtons,

          // Shift info (expected times)
          if (shiftInfo != null) shiftInfo!,

          // Registration details
          if (registrationDetails != null) registrationDetails!,
        ],
      ),
    );
  }
}
