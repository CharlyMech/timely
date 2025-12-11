import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:timely/models/time_registration.dart';
import 'package:timely/utils/date_utils.dart';
import 'package:timely/constants/themes.dart';

enum GaugeMode { status, time, none }

class TimeGauge extends StatefulWidget {
  final TimeRegistration? registration;
  final double size;
  final double strokeWidth;
  final GaugeMode mode;
  final MyTheme myTheme;

  const TimeGauge({
    super.key,
    this.registration,
    this.size = 120,
    this.strokeWidth = 25,
    this.mode = GaugeMode.time,
    required this.myTheme,
  });

  @override
  State<TimeGauge> createState() => _TimeGaugeState();
}

class _TimeGaugeState extends State<TimeGauge> {
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _startTimerIfNeeded();
  }

  @override
  void didUpdateWidget(TimeGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Restart timer if registration changed
    if (oldWidget.registration?.id != widget.registration?.id ||
        oldWidget.registration?.isActive != widget.registration?.isActive) {
      _startTimerIfNeeded();
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startTimerIfNeeded() {
    _updateTimer?.cancel();
    // Only start timer if there's an active registration
    if (widget.registration?.isActive == true) {
      _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {
            // This will trigger a rebuild of only this widget
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Gauge
          CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _TimeGaugePainter(
              registration: widget.registration,
              backgroundColor: theme.colorScheme.secondary.withValues(
                alpha: 0.5,
              ),
              gaugeColor: _getGaugeColor(widget.registration, theme),
              strokeWidth: widget.strokeWidth,
            ),
          ),
          Center(
            child: widget.mode == GaugeMode.time
                ? _buildTimeDisplay(widget.registration, theme)
                : widget.mode == GaugeMode.status
                ? _buildStatusDisplay(widget.registration, theme)
                : SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeDisplay(
    TimeRegistration? activeRegistration,
    ThemeData theme,
  ) {
    if (activeRegistration == null) {
      return Text(
        '0:00',
        style: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: widget.size * 0.20,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          DateTimeUtils.minutesToReadable(activeRegistration.totalMinutes),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: widget.size * 0.20,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDisplay(
    TimeRegistration? activeRegistration,
    ThemeData theme,
  ) {
    if (activeRegistration == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.radio_button_unchecked,
            size: widget.size * 0.20,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          SizedBox(height: widget.size * 0.05),
          Text(
            'No iniciado',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: widget.size * 0.09,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      );
    }

    final isActive = activeRegistration.isActive;
    final status = activeRegistration.status;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isActive ? Icons.play_circle_filled : Icons.check_circle,
          size: widget.size * 0.20,
          color: _getColorFromTheme(status),
        ),
        SizedBox(height: widget.size * 0.05),
        Text(
          isActive ? 'En curso' : 'Finalizado',
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: widget.size * 0.09,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  /// Obtiene el color del gauge según el estado del registro
  Color _getGaugeColor(TimeRegistration? activeRegistration, ThemeData theme) {
    if (activeRegistration == null) {
      // Usar inactiveColor del theme para sin registro
      return Color(int.parse(widget.myTheme.inactiveColor.replaceFirst('#', '0xff')));
    }

    // Si la jornada está activa y por debajo del target, siempre verde
    final targetMinutes = 420;
    if (activeRegistration.isActive &&
        activeRegistration.totalMinutes <= targetMinutes) {
      return Color(int.parse(widget.myTheme.colorGreen.replaceFirst('#', '0xff')));
    }

    // En los demás casos, usar el color según el status
    return _getColorFromTheme(activeRegistration.status);
  }

  /// Obtiene el color desde el theme según el estado
  Color _getColorFromTheme(TimeRegistrationStatus status) {
    switch (status) {
      case TimeRegistrationStatus.green:
        return Color(int.parse(widget.myTheme.colorGreen.replaceFirst('#', '0xff')));
      case TimeRegistrationStatus.orange:
        return Color(int.parse(widget.myTheme.colorOrange.replaceFirst('#', '0xff')));
      case TimeRegistrationStatus.red:
        return Color(int.parse(widget.myTheme.colorRed.replaceFirst('#', '0xff')));
    }
  }
}

class _TimeGaugePainter extends CustomPainter {
  final TimeRegistration? registration;
  final Color backgroundColor;
  final Color gaugeColor;
  final double strokeWidth;

  _TimeGaugePainter({
    required this.registration,
    required this.backgroundColor,
    required this.gaugeColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw background arc (270 degrees)
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Start from bottom-left (-225 degrees), sweep 270 degrees clockwise
    const startAngle = -pi * 1.25; // Bottom left - Start point
    const sweepAngle = pi * 1.5;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      backgroundPaint,
    );

    if (registration != null) {
      final totalMinutes = 420.0; // 7 hours = 420 minutes (target)
      final currentMinutes = registration!.totalMinutes.toDouble();
      final progress = (currentMinutes / totalMinutes).clamp(0.0, 1.5);

      final progressPaint = Paint()
        ..color = gaugeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final progressSweep = sweepAngle * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        progressSweep,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_TimeGaugePainter oldDelegate) {
    return oldDelegate.registration != registration ||
        oldDelegate.gaugeColor != gaugeColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
