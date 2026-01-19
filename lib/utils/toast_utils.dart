import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Utility class for displaying toast messages throughout the app.
///
/// Provides standardized toast notifications with consistent styling
/// for info, success, warning, and error messages.
class ToastUtils {
  static final FToast _fToast = FToast();

  /// Initializes FToast with the given context. Call this once in your app.
  static void init(BuildContext context) {
    _fToast.init(context);
  }

  /// Shows an informational toast message.
  static void showInfo(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.grey[800],
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  /// Shows a success toast message with green background and close button.
  static void showSuccess(String message, {BuildContext? context}) {
    if (context != null) {
      _fToast.init(context);
      _fToast.showToast(
        toastDuration: const Duration(seconds: 4),
        gravity: ToastGravity.BOTTOM,
        child: _buildToastWidget(
          message: message,
          backgroundColor: const Color(0xFF46B56C),
          textColor: Colors.white,
          showCloseButton: true,
        ),
      );
    } else {
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: const Color(0xFF46B56C),
        textColor: Colors.white,
        fontSize: 14.0,
      );
    }
  }

  /// Shows a warning toast message with orange background.
  static void showWarning(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: const Color(0xFFFFAB2E),
      textColor: Colors.black87,
      fontSize: 14.0,
    );
  }

  /// Shows an error toast message with red background.
  static void showError(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: const Color(0xFFD64C4C),
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  /// Builds a custom toast widget with optional close button.
  static Widget _buildToastWidget({
    required String message,
    required Color backgroundColor,
    required Color textColor,
    bool showCloseButton = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: backgroundColor,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
              ),
            ),
          ),
          if (showCloseButton) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => _fToast.removeCustomToast(),
              child: Icon(
                Icons.close,
                color: textColor.withValues(alpha: 0.8),
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
