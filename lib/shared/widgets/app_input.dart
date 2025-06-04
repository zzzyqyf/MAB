import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';

class AppTextFormField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? initialValue;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String?)? onSaved;
  final void Function()? onTap;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final int? maxLines;
  final int? maxLength;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final String? semanticLabel;
  final bool autofocus;

  const AppTextFormField({
    super.key,
    this.label,
    this.hint,
    this.initialValue,
    this.controller,
    this.validator,
    this.onChanged,
    this.onSaved,
    this.onTap,
    this.keyboardType,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.semanticLabel,
    this.autofocus = false,
  });

  @override
  State<AppTextFormField> createState() => _AppTextFormFieldState();
}

class _AppTextFormFieldState extends State<AppTextFormField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTextStyles.textTheme.labelMedium?.copyWith(
              color: _isFocused ? AppColors.primary : AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppDimensions.spacing8),
        ],
        Semantics(
          label: widget.semanticLabel ?? widget.label ?? widget.hint,
          child: TextFormField(
            controller: widget.controller,
            initialValue: widget.initialValue,
            focusNode: _focusNode,
            validator: widget.validator,
            onChanged: widget.onChanged,
            onSaved: widget.onSaved,
            onTap: widget.onTap,
            keyboardType: widget.keyboardType,
            obscureText: widget.obscureText,
            readOnly: widget.readOnly,
            enabled: widget.enabled,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            inputFormatters: widget.inputFormatters,
            textCapitalization: widget.textCapitalization,
            autofocus: widget.autofocus,
            style: AppTextStyles.textTheme.bodyLarge?.copyWith(
              color: widget.enabled ? AppColors.onSurface : AppColors.onSurfaceVariant,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppTextStyles.textTheme.bodyLarge?.copyWith(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      color: _isFocused ? AppColors.primary : AppColors.onSurfaceVariant,
                      size: AppDimensions.iconMedium,
                    )
                  : null,
              suffixIcon: widget.suffixIcon,
              filled: true,
              fillColor: widget.enabled 
                  ? (_isFocused ? AppColors.surfaceVariant.withValues(alpha: 0.8) : AppColors.surfaceVariant)
                  : AppColors.surfaceVariant.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: AppDimensions.inputBorderRadius,
                borderSide: BorderSide(
                  color: AppColors.outline,
                  width: AppDimensions.borderThin,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppDimensions.inputBorderRadius,
                borderSide: BorderSide(
                  color: AppColors.outline,
                  width: AppDimensions.borderThin,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppDimensions.inputBorderRadius,
                borderSide: BorderSide(
                  color: AppColors.primary,
                  width: AppDimensions.borderMedium,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: AppDimensions.inputBorderRadius,
                borderSide: BorderSide(
                  color: AppColors.error,
                  width: AppDimensions.borderThin,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: AppDimensions.inputBorderRadius,
                borderSide: BorderSide(
                  color: AppColors.error,
                  width: AppDimensions.borderMedium,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: AppDimensions.inputBorderRadius,
                borderSide: BorderSide(
                  color: AppColors.outline.withValues(alpha: 0.5),
                  width: AppDimensions.borderThin,
                ),
              ),
              contentPadding: AppDimensions.paddingAllMedium,
              counterStyle: AppTextStyles.textTheme.labelSmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              errorStyle: AppTextStyles.errorText,
            ),
          ),
        ),
      ],
    );
  }
}

class AppSearchField extends StatefulWidget {
  final String? hint;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final TextEditingController? controller;
  final bool autofocus;
  final String? semanticLabel;

  const AppSearchField({
    super.key,
    this.hint,
    this.onChanged,
    this.onSubmitted,
    this.controller,
    this.autofocus = false,
    this.semanticLabel,
  });

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late TextEditingController _controller;
  bool _showClearButton = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
    _showClearButton = _controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onTextChanged);
    }
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (_showClearButton != hasText) {
      setState(() {
        _showClearButton = hasText;
      });
    }
  }

  void _clearText() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel ?? 'Search field',
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        autofocus: widget.autofocus,
        style: AppTextStyles.textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: widget.hint ?? 'Search...',
          hintStyle: AppTextStyles.textTheme.bodyLarge?.copyWith(
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.onSurfaceVariant,
            size: AppDimensions.iconMedium,
          ),
          suffixIcon: _showClearButton
              ? IconButton(
                  onPressed: _clearText,
                  icon: Icon(
                    Icons.clear,
                    color: AppColors.onSurfaceVariant,
                    size: AppDimensions.iconSmall,
                  ),
                  tooltip: 'Clear search',
                )
              : null,
          filled: true,
          fillColor: AppColors.surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMedium,
            vertical: AppDimensions.paddingSmall,
          ),
        ),
      ),
    );
  }
}

class AppDropdownField<T> extends StatelessWidget {
  final String? label;
  final String? hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final bool enabled;
  final IconData? prefixIcon;
  final String? semanticLabel;

  const AppDropdownField({
    super.key,
    this.label,
    this.hint,
    this.value,
    required this.items,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.prefixIcon,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTextStyles.textTheme.labelMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppDimensions.spacing8),
        ],
        Semantics(
          label: semanticLabel ?? label ?? hint,
          child: DropdownButtonFormField<T>(
            value: value,
            items: items,
            onChanged: enabled ? onChanged : null,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.textTheme.bodyLarge?.copyWith(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              prefixIcon: prefixIcon != null
                  ? Icon(
                      prefixIcon,
                      color: AppColors.onSurfaceVariant,
                      size: AppDimensions.iconMedium,
                    )
                  : null,
              filled: true,
              fillColor: enabled 
                  ? AppColors.surfaceVariant
                  : AppColors.surfaceVariant.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: AppDimensions.inputBorderRadius,
                borderSide: BorderSide(
                  color: AppColors.outline,
                  width: AppDimensions.borderThin,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppDimensions.inputBorderRadius,
                borderSide: BorderSide(
                  color: AppColors.outline,
                  width: AppDimensions.borderThin,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppDimensions.inputBorderRadius,
                borderSide: BorderSide(
                  color: AppColors.primary,
                  width: AppDimensions.borderMedium,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: AppDimensions.inputBorderRadius,
                borderSide: BorderSide(
                  color: AppColors.error,
                  width: AppDimensions.borderThin,
                ),
              ),
              contentPadding: AppDimensions.paddingAllMedium,
              errorStyle: AppTextStyles.errorText,
            ),
            style: AppTextStyles.textTheme.bodyLarge?.copyWith(
              color: enabled ? AppColors.onSurface : AppColors.onSurfaceVariant,
            ),
            dropdownColor: AppColors.surface,
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.onSurfaceVariant,
              size: AppDimensions.iconMedium,
            ),
          ),
        ),
      ],
    );
  }
}
