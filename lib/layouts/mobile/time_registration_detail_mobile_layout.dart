import 'package:flutter/material.dart';
import 'package:timely/widgets/custom_card.dart';
import 'package:timely/widgets/custom_text.dart';

/// Mobile-optimized layout for time registration detail screen.
///
/// Provides a vertical scrollable layout displaying the time gauge,
/// action buttons, and optional shift information in a mobile-friendly
/// arrangement with appropriate spacing and padding.
class TimeRegistrationDetailMobileLayout extends StatelessWidget {
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

  const TimeRegistrationDetailMobileLayout({
    super.key,
    required this.gaugeWidget,
    required this.actionButtons,
    this.shiftInfo,
    this.registrationDetails,
    this.banner,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                spacing: 16,
                children: [
                  // Banner (e.g., no-shift warning)
                  if (banner != null) banner!,

                  // Gauge Card
                  CustomCard(
                    width: double.infinity,
                    child: Column(
                      spacing: 12,
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
            ),
          ),
        );
      },
    );
  }
}
