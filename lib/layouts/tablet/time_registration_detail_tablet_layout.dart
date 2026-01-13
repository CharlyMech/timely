import 'package:flutter/material.dart';
import 'package:timely/widgets/custom_card.dart';
import 'package:timely/widgets/custom_text.dart';

class TimeRegistrationDetailTabletLayout extends StatelessWidget {
  final Widget gaugeWidget;
  final Widget actionButtons;
  final Widget? shiftInfo;
  final Widget? registrationDetails;

  const TimeRegistrationDetailTabletLayout({
    super.key,
    required this.gaugeWidget,
    required this.actionButtons,
    this.shiftInfo,
    this.registrationDetails,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Column(
        spacing: 24,
        children: [
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
