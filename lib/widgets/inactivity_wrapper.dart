import 'dart:async';
import 'package:flutter/material.dart';
import 'package:timely/config/env.dart';
import 'package:timely/config/router.dart';

/// Global inactivity timer manager.
///
/// This class manages a single timer instance across the entire app,
/// ensuring consistent inactivity detection regardless of navigation.
class _InactivityTimerManager {
  static final _InactivityTimerManager _instance =
      _InactivityTimerManager._internal();
  factory _InactivityTimerManager() => _instance;
  _InactivityTimerManager._internal();

  Timer? _inactivityTimer;

  Duration get _inactivityDuration => Duration(
        minutes: FirebaseEnv.inactivityTimeoutMinutes,
      );

  void startTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityDuration, _onInactivityTimeout);
  }

  void resetTimer() {
    startTimer();
  }

  void _onInactivityTimeout() {
    router.go('/splash');
  }

  void dispose() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }
}

/// Widget that wraps the entire app and manages the inactivity timeout.
///
/// Detects any user interaction (taps, gestures, drags, scrolls) and resets
/// a global timer. When the timer expires without activity, it automatically
/// navigates to the splash screen to refresh the data.
///
/// Uses the global [router] instance directly for navigation, so it can be
/// placed anywhere in the widget tree.
///
/// The inactivity timeout is configured in [FirebaseEnv.inactivityTimeoutMinutes].
class InactivityWrapper extends StatefulWidget {
  final Widget child;
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
  final _timerManager = _InactivityTimerManager();

  @override
  void initState() {
    super.initState();
    _timerManager.startTimer();
  }

  @override
  void dispose() {
    _timerManager.dispose();
    super.dispose();
  }

  void _resetInactivityTimer() {
    _timerManager.resetTimer();
    widget.onActivity?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _resetInactivityTimer(),
      onPointerMove: (_) => _resetInactivityTimer(),
      onPointerUp: (_) => _resetInactivityTimer(),
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}
