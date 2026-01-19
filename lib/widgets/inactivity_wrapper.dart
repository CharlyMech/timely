import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timely/config/env.dart';

/// Widget that wraps a screen and manages the inactivity timeout.
///
/// Detects any user interaction (taps, gestures) and resets a timer.
/// When the timer expires without activity, it automatically navigates
/// to the splash screen to refresh the data.
///
/// The inactivity timeout is configured in [FirebaseEnv.inactivityTimeoutMinutes].
///
/// ```dart
/// // Basic usage
/// InactivityWrapper(
///   child: Scaffold(
///     body: MyContent(),
///   ),
/// )
/// ```
class InactivityWrapper extends StatefulWidget {
  /// The child widget that will be wrapped with inactivity detection.
  final Widget child;

  /// Optional callback that executes each time activity is detected.
  ///
  /// Useful for running additional logic when the user interacts,
  /// such as updating local state or logging analytics.
  final VoidCallback? onActivity;

  const InactivityWrapper({
    super.key,
    required this.child,
    this.onActivity,
  });

  @override
  State<InactivityWrapper> createState() => _InactivityWrapperState();
}

class _InactivityWrapperState extends State<InactivityWrapper> {
  Timer? _inactivityTimer;

  Duration get _inactivityDuration => Duration(
        minutes: FirebaseEnv.inactivityTimeoutMinutes,
      );

  @override
  void initState() {
    super.initState();
    _startInactivityTimer();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  /// Starts the inactivity timer.
  ///
  /// Cancels any existing timer and creates a new one that will
  /// trigger [_onInactivityTimeout] when it expires.
  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityDuration, _onInactivityTimeout);
  }

  /// Resets the inactivity timer.
  ///
  /// Should be called on any user interaction to extend the active session.
  void _resetInactivityTimer() {
    _startInactivityTimer();
    widget.onActivity?.call();
  }

  /// Handles the inactivity timeout by navigating to the splash screen.
  ///
  /// Executes when the timer expires without any user interaction.
  void _onInactivityTimeout() {
    if (mounted) {
      context.go('/splash');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _resetInactivityTimer,
      onLongPress: _resetInactivityTimer,
      onScaleStart: (_) => _resetInactivityTimer(),
      onScaleUpdate: (_) => _resetInactivityTimer(),
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}
