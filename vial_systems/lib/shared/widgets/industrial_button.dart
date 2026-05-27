import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/visual_features.dart';

class IndustrialButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;

  const IndustrialButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
  });

  @override
  State<IndustrialButton> createState() => _IndustrialButtonState();
}

class _IndustrialButtonState extends State<IndustrialButton> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed == null || widget.isLoading) return;
    if (VisualFeatures.enableExperimentalAnimations) {
      setState(() {
        _scale = 0.96;
      });
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed == null || widget.isLoading) return;
    if (VisualFeatures.enableExperimentalAnimations) {
      setState(() {
        _scale = 1.0;
      });
    }
  }

  void _onTapCancel() {
    if (widget.onPressed == null || widget.isLoading) return;
    if (VisualFeatures.enableExperimentalAnimations) {
      setState(() {
        _scale = 1.0;
      });
    }
  }

  void _handlePress() {
    if (widget.onPressed == null || widget.isLoading) return;
    HapticFeedback.lightImpact();
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    final primaryColor = widget.backgroundColor ?? 
        (widget.isOutlined ? Colors.transparent : AppColors.yellowIndustrial);
    final onPrimaryColor = widget.foregroundColor ?? 
        (widget.isOutlined ? AppColors.darkGraphite : AppColors.darkGraphite);

    Widget buttonContent = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            height: AppSpacing.lg,
            width: AppSpacing.lg,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(onPrimaryColor),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: AppIconSize.sm, color: onPrimaryColor),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(
          widget.isLoading ? 'PROCESANDO...' : widget.label.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            letterSpacing: 0.5,
            color: isDisabled 
                ? Colors.grey.shade500 
                : onPrimaryColor,
          ),
        ),
      ],
    );

    Widget buttonShape;

    if (widget.isOutlined) {
      buttonShape = OutlinedButton(
        onPressed: isDisabled ? null : _handlePress,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isDisabled ? Colors.grey.shade300 : onPrimaryColor,
            width: 1.5,
          ),
          minimumSize: const Size(88, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        child: buttonContent,
      );
    } else {
      buttonShape = ElevatedButton(
        onPressed: isDisabled ? null : _handlePress,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled ? Colors.grey.shade200 : primaryColor,
          foregroundColor: onPrimaryColor,
          elevation: isDisabled ? 0.0 : AppElevation.low,
          minimumSize: const Size(88, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        child: buttonContent,
      );
    }

    if (widget.width != null) {
      buttonShape = SizedBox(
        width: widget.width,
        height: 50,
        child: buttonShape,
      );
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: AppAnimations.fast,
        curve: Curves.easeOutBack,
        child: buttonShape,
      ),
    );
  }
}
