/// Custom Input Field with floating label and validation animation
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shapes.dart';
import '../../theme/app_typography.dart';
import '../../animations/app_animations.dart';

class AppInputField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final bool enabled;
  final int maxLines;
  final int? maxLength;
  final IconData? prefixIcon;
  final Widget? suffix;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final bool showClearButton;

  const AppInputField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.focusNode,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffix,
    this.inputFormatters,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.autofocus = false,
    this.showClearButton = false,
  });

  @override
  State<AppInputField> createState() => _AppInputFieldState();
}

class _AppInputFieldState extends State<AppInputField>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  bool _obscureText = true;
  bool _hasError = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
    _obscureText = widget.obscureText;

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _shakeController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {});
    if (!_focusNode.hasFocus && widget.validator != null) {
      _validate();
    }
  }

  void _validate() {
    final error = widget.validator?.call(_controller.text);
    setState(() {
      _hasError = error != null;
      _errorText = error;
    });
    if (_hasError) {
      _shakeController.forward().then((_) => _shakeController.reset());
    }
  }

  void _clearText() {
    _controller.clear();
    widget.onChanged?.call('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) => Transform.translate(
        offset: Offset(
          _shakeAnimation.value *
              (_shakeController.status == AnimationStatus.forward ? 1 : -1),
          0,
        ),
        child: child,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: AppAnimations.fast,
            decoration: BoxDecoration(
              color: widget.enabled
                  ? (_focusNode.hasFocus
                        ? AppColors.surface
                        : AppColors.surfaceVariant)
                  : AppColors.surfaceVariant.withValues(alpha: 0.5),
              borderRadius: AppShapes.inputRadius,
              border: Border.all(
                color: _hasError
                    ? AppColors.error
                    : _focusNode.hasFocus
                    ? AppColors.primary
                    : Colors.transparent,
                width: _focusNode.hasFocus || _hasError ? 2 : 0,
              ),
              boxShadow: _focusNode.hasFocus && !_hasError
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: TextFormField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              obscureText: widget.obscureText && _obscureText,
              enabled: widget.enabled,
              maxLines: widget.maxLines,
              maxLength: widget.maxLength,
              autofocus: widget.autofocus,
              inputFormatters: widget.inputFormatters,
              style: AppTypography.bodyLarge.copyWith(
                color: widget.enabled
                    ? AppColors.textPrimary
                    : AppColors.textDisabled,
              ),
              decoration: InputDecoration(
                labelText: widget.label,
                hintText: widget.hint,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                prefixIcon: widget.prefixIcon != null
                    ? Icon(
                        widget.prefixIcon,
                        color: _focusNode.hasFocus
                            ? AppColors.primary
                            : AppColors.textTertiary,
                        size: 22,
                      )
                    : null,
                suffixIcon: _buildSuffix(),
                counterText: '',
              ),
              onChanged: (value) {
                widget.onChanged?.call(value);
                if (_hasError) {
                  _validate();
                }
                setState(() {});
              },
              onEditingComplete: widget.onEditingComplete,
              onFieldSubmitted: widget.onSubmitted,
            ),
          ),
          if (_hasError && _errorText != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                _errorText!,
                style: AppTypography.bodySmall.copyWith(color: AppColors.error),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget? _buildSuffix() {
    final List<Widget> suffixWidgets = [];

    // Clear button
    if (widget.showClearButton && _controller.text.isNotEmpty) {
      suffixWidgets.add(
        IconButton(
          icon: const Icon(Icons.close, size: 20),
          color: AppColors.textTertiary,
          onPressed: _clearText,
        ),
      );
    }

    // Password visibility toggle
    if (widget.obscureText) {
      suffixWidgets.add(
        IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility_off : Icons.visibility,
            size: 22,
          ),
          color: AppColors.textTertiary,
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
      );
    }

    // Custom suffix
    if (widget.suffix != null) {
      suffixWidgets.add(widget.suffix!);
    }

    if (suffixWidgets.isEmpty) return null;
    if (suffixWidgets.length == 1) return suffixWidgets.first;

    return Row(mainAxisSize: MainAxisSize.min, children: suffixWidgets);
  }
}

/// Phone Number Input with country code
class PhoneInputField extends StatelessWidget {
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const PhoneInputField({
    super.key,
    this.controller,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: AppShapes.inputRadius,
          ),
          child: Center(
            child: Text(
              '+62',
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppInputField(
            label: 'Nomor Telepon',
            hint: '812 3456 7890',
            controller: controller,
            keyboardType: TextInputType.phone,
            validator: validator,
            onChanged: onChanged,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(13),
            ],
          ),
        ),
      ],
    );
  }
}
