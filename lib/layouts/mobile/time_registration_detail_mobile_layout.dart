import 'package:flutter/material.dart';
import 'package:timely/widgets/custom_card.dart';
import 'package:timely/widgets/custom_text.dart';

class TimeRegistrationDetailMobileLayout extends StatelessWidget {
  final Widget gaugeWidget;
  final Widget actionButtons;
  final Widget? shiftInfo;
  final Widget? registrationDetails;

  const TimeRegistrationDetailMobileLayout({
    super.key,
    required this.gaugeWidget,
    required this.actionButtons,
    this.shiftInfo,
    this.registrationDetails,
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
