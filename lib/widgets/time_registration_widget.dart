import 'dart:math';
import 'package:flutter/material.dart';
import 'package:timely/models/time_registration.dart';
import 'package:intl/intl.dart';

class TimeRegistrationWidget extends StatelessWidget {
  final TimeRegistration? registration;
  final double size;
  final bool showDetails;

  const TimeRegistrationWidget({
    super.key,
    this.registration,
    this.size = 120,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (registration == null) {
      return _buildEmptyState(theme);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Círculo de progreso
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _TimeCirclePainter(
              registration: registration!,
              backgroundColor: theme.colorScheme.surface,
              strokeWidth: size * 0.12,
            ),
            child: Center(
              child: Text(
                _formatTime(registration!.totalMinutes),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: size * 0.20,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
        if (showDetails) ...[
          const SizedBox(height: 16),
          _buildTimeDetails(theme),
        ],
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _EmptyCirclePainter(
              backgroundColor: theme.colorScheme.surface,
              strokeWidth: size * 0.12,
            ),
            child: Center(
              child: Text(
                '0:00',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: size * 0.20,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeDetails(ThemeData theme) {
    return Column(
      children: [
        Text(
          'Registro de hoy:',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatTimestamp(registration!.startTime),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        if (registration!.endTime != null) ...[
          const SizedBox(height: 4),
          Text(
            'Registro final',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          Text(
            _formatTimestamp(registration!.endTime!),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ],
    );
  }

  String _formatTime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '$hours:${mins.toString().padLeft(2, '0')}';
  }

  String _formatTimestamp(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }
}

/// Painter para dibujar el círculo de progreso
class _TimeCirclePainter extends CustomPainter {
  final TimeRegistration registration;
  final Color backgroundColor;
  final double strokeWidth;

  _TimeCirclePainter({
    required this.registration,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Círculo de fondo
    final backgroundPaint = Paint()
      ..color = backgroundColor.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Círculo de progreso
    final totalMinutes = 420.0; // 7 horas = 420 minutos
    final currentMinutes = registration.totalMinutes.toDouble();
    final progress = (currentMinutes / totalMinutes).clamp(0.0, 1.5);

    final progressPaint = Paint()
      ..color = _getColor()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // Comenzar desde arriba
      sweepAngle,
      false,
      progressPaint,
    );
  }

  Color _getColor() {
    switch (registration.status) {
      case TimeRegistrationStatus.green:
        return const Color(0xFF46B56C);
      case TimeRegistrationStatus.orange:
        return const Color(0xFFFFAB2E);
      case TimeRegistrationStatus.red:
        return const Color(0xFFD64C4C);
    }
  }

  @override
  bool shouldRepaint(_TimeCirclePainter oldDelegate) {
    return oldDelegate.registration != registration;
  }
}

/// Painter para el círculo vacío (sin registro)
class _EmptyCirclePainter extends CustomPainter {
  final Color backgroundColor;
  final double strokeWidth;

  _EmptyCirclePainter({
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = backgroundColor.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_EmptyCirclePainter oldDelegate) => false;
}
