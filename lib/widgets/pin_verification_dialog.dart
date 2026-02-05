import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timely/constants/themes.dart';
import 'package:timely/services/api/api_auth_service.dart';
import 'package:timely/viewmodels/theme_viewmodel.dart';
import 'package:timely/widgets/custom_card.dart';
import 'package:timely/utils/responsive_utils.dart';

/// Dialog for verifying employee identity using a 6-digit PIN.
///
/// Displays 6 input fields for PIN entry with automatic focus management.
/// Shows error message for incorrect PINs and provides verify/cancel actions.
///
/// When [verifyWithApi] is set (e.g. API flavor), the PIN is verified via
/// POST /auth/pin and the dialog pops with [AuthPinResult] on success.
/// Otherwise [correctPin] is used for local verification and the dialog pops with `true`.
class PinVerificationDialog extends ConsumerStatefulWidget {
  /// PIN to compare against when not using API (Firebase/dev).
  final String? correctPin;

  final String employeeName;

  /// When set, PIN is verified by calling the API; dialog pops with [AuthPinResult] or null.
  final Future<AuthPinResult?> Function(String pin)? verifyWithApi;

  const PinVerificationDialog({
    super.key,
    this.correctPin,
    required this.employeeName,
    this.verifyWithApi,
  }) : assert(
         correctPin != null || verifyWithApi != null,
         'Provide either correctPin or verifyWithApi',
       );

  @override
  ConsumerState<PinVerificationDialog> createState() =>
      _PinVerificationDialogState();
}

class _PinVerificationDialogState extends ConsumerState<PinVerificationDialog> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  String _errorMessage = '';
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    // Auto-focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onDigitChanged(int index, String value) {
    if (value.isEmpty) {
      // Handle backspace - move to previous field
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    } else {
      // Move to next field if not last
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // All fields filled, verify PIN
        _verifyPin();
      }
    }
  }

  void _handleBackspace() {
    // Find current focused field
    int? focusedIndex;
    for (int i = 0; i < _focusNodes.length; i++) {
      if (_focusNodes[i].hasFocus) {
        focusedIndex = i;
        break;
      }
    }

    if (focusedIndex != null) {
      if (_controllers[focusedIndex].text.isEmpty && focusedIndex > 0) {
        // Current field is empty, clear and move to previous
        _controllers[focusedIndex - 1].clear();
        _focusNodes[focusedIndex - 1].requestFocus();
      } else {
        // Current field has value, clear it
        _controllers[focusedIndex].clear();
      }
    }
  }

  Future<void> _verifyPin() async {
    final enteredPin = _controllers.map((c) => c.text).join();
    if (enteredPin.length != 6) return;

    final verifyWithApi = widget.verifyWithApi;
    if (verifyWithApi != null) {
      setState(() {
        _errorMessage = '';
        _isVerifying = true;
      });
      try {
        final result = await verifyWithApi(enteredPin);
        if (!mounted) return;
        if (result != null) {
          Navigator.of(context).pop(result);
          return;
        }
        setState(() {
          _errorMessage = 'PIN incorrecto. Inténtalo de nuevo.';
          _isVerifying = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Error de conexión. Inténtalo de nuevo.';
          _isVerifying = false;
        });
      }
      for (var controller in _controllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
      return;
    }

    if (enteredPin == widget.correctPin) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _errorMessage = 'PIN incorrecto. Inténtalo de nuevo.';
      });
      for (var controller in _controllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeState = ref.watch(themeViewModelProvider);
    final brightness = MediaQuery.of(context).platformBrightness;
    final currentThemeType = themeState.themeType == ThemeType.system
        ? (brightness == Brightness.dark ? ThemeType.dark : ThemeType.light)
        : themeState.themeType;
    final myTheme = themes[currentThemeType]!;
    final responsive = context.responsive;
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    // Responsive sizes
    final iconSize = responsive.isMobile ? 40.0 : (isLandscape ? 32.0 : 48.0);
    final titleSize = responsive.isMobile ? 20.0 : (isLandscape ? 20.0 : 24.0);
    final bodySize = responsive.isMobile ? 13.0 : 14.0;
    final pinWidth = responsive.isMobile ? 38.0 : 45.0;
    final pinHeight = responsive.isMobile ? 48.0 : 55.0;
    final pinMargin = responsive.isMobile ? 3.0 : 4.0;
    final padding = responsive.isMobile ? 16.0 : (isLandscape ? 16.0 : 24.0);
    final spacing = responsive.isMobile ? 6.0 : (isLandscape ? 4.0 : 8.0);

    return KeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace) {
          _handleBackspace();
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: EdgeInsets.symmetric(
          horizontal: responsive.isMobile ? 24 : 40,
          vertical: 24,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: responsive.isMobile ? 340 : 550,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: spacing,
                children: [
                  if (isLandscape && !responsive.isMobile)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 12,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: iconSize,
                          color: theme.colorScheme.primary,
                        ),
                        Text(
                          'Verificación de Identidad',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: titleSize,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    Icon(
                      Icons.lock_outline,
                      size: iconSize,
                      color: theme.colorScheme.primary,
                    ),
                    Text(
                      'Verificación de Identidad',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: titleSize,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  Text(
                    'Ingresa tu PIN de 6 dígitos para acceder a tus registros horarios',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: bodySize,
                    ),
                  ),
                  SizedBox(height: responsive.isMobile ? 10 : 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      return Container(
                        width: pinWidth,
                        height: pinHeight,
                        margin: EdgeInsets.symmetric(horizontal: pinMargin),
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          obscureText: true,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: responsive.isMobile ? 20 : 24,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                            contentPadding: EdgeInsets.zero,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary,
                                width: 2,
                              ),
                            ),
                          ),
                          onChanged: (value) => _onDigitChanged(index, value),
                        ),
                      );
                    }),
                  ),
                  if (_errorMessage.isNotEmpty) ...[
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.isMobile ? 10 : 12,
                        vertical: responsive.isMobile ? 6 : 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        spacing: 8,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: theme.colorScheme.error,
                            size: responsive.isMobile ? 18 : 20,
                          ),
                          Flexible(
                            child: Text(
                              _errorMessage,
                              style: TextStyle(
                                color: theme.colorScheme.error,
                                fontSize: responsive.isMobile ? 12 : 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: responsive.isMobile ? 10 : 16),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.isMobile ? 0 : 20.0,
                    ),
                    child: Row(
                      spacing: responsive.isMobile ? 12 : 16,
                      children: [
                        Expanded(
                          child: CustomCard(
                            onTap: () => Navigator.of(context).pop(false),
                            elevation: 0,
                            color: Color(
                              int.parse(
                                myTheme.inactiveColor.replaceFirst('#', '0xee'),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsetsGeometry.symmetric(
                                vertical: 4,
                                horizontal: 8,
                              ),
                              child: Text(
                                'Cancelar',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(
                                    int.parse(
                                      myTheme.onInactiveColor.replaceFirst(
                                        '#',
                                        '0xff',
                                      ),
                                    ),
                                  ),
                                  fontWeight: FontWeight.w500,
                                  fontSize: responsive.isMobile ? 13 : 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: CustomCard(
                            onTap: _isVerifying ? null : _verifyPin,
                            elevation: 0,
                            color: Color(
                              int.parse(
                                myTheme.primaryColor.replaceFirst('#', '0xee'),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsetsGeometry.symmetric(
                                vertical: 4,
                                horizontal: 8,
                              ),
                              child: _isVerifying
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(
                                            int.parse(
                                              myTheme.onPrimaryColor.replaceFirst(
                                                '#',
                                                '0xff',
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Text(
                                      'Verificar',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Color(
                                          int.parse(
                                            myTheme.onPrimaryColor.replaceFirst(
                                              '#',
                                              '0xff',
                                            ),
                                          ),
                                        ),
                                        fontWeight: FontWeight.w500,
                                        fontSize: responsive.isMobile ? 13 : 14,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
