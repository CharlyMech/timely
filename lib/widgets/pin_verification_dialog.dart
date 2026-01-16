import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timely/constants/themes.dart';
import 'package:timely/viewmodels/theme_viewmodel.dart';
import 'package:timely/widgets/custom_card.dart';
import 'package:timely/utils/responsive_utils.dart';

/// Dialog for verifying employee identity using a 6-digit PIN.
///
/// Displays 6 input fields for PIN entry with automatic focus management.
/// Shows error message for incorrect PINs and provides verify/cancel actions.
class PinVerificationDialog extends ConsumerStatefulWidget {
  final String correctPin;
  final String employeeName;

  const PinVerificationDialog({
    super.key,
    required this.correctPin,
    required this.employeeName,
  });

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

  void _verifyPin() {
    final enteredPin = _controllers.map((c) => c.text).join();
    if (enteredPin.length == 6) {
      if (enteredPin == widget.correctPin) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _errorMessage = 'PIN incorrecto. Inténtalo de nuevo.';
        });
        // Clear all fields
        for (var controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      }
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

    // Tamaños responsivos
    final iconSize = responsive.isMobile ? 40.0 : 48.0;
    final titleSize = responsive.isMobile ? 20.0 : 24.0;
    final bodySize = responsive.isMobile ? 13.0 : 14.0;
    final pinWidth = responsive.isMobile ? 38.0 : 45.0;
    final pinHeight = responsive.isMobile ? 48.0 : 55.0;
    final pinMargin = responsive.isMobile ? 3.0 : 4.0;
    final padding = responsive.isMobile ? 16.0 : 24.0;

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
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: responsive.isMobile ? 340 : 550,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: iconSize,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(height: responsive.isMobile ? 12 : 16),
                  Text(
                    'Verificación de Identidad',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: titleSize,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: responsive.isMobile ? 6 : 8),
                  Text(
                    'Ingresa tu PIN de 6 dígitos para acceder a tus registros horarios',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: bodySize,
                    ),
                  ),
                  SizedBox(height: responsive.isMobile ? 16 : 24),
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
                            FilteringTextInputFormatter.digitsOnly
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
                    SizedBox(height: responsive.isMobile ? 12 : 16),
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: theme.colorScheme.error,
                            size: responsive.isMobile ? 18 : 20,
                          ),
                          const SizedBox(width: 8),
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
                  SizedBox(height: responsive.isMobile ? 16 : 24),
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
                            onTap: _verifyPin,
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
                              child: Text(
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
