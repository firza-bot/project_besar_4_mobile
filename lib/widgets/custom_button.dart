import 'package:flutter/material.dart';
import '../utils/constants.dart';

class CustomButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final double? width;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.width,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null && !widget.isLoading;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => _controller.forward() : null,
      onTapUp: isEnabled ? (_) => _controller.reverse() : null,
      onTapCancel: isEnabled ? () => _controller.reverse() : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isEnabled ? _scaleAnimation.value : 1.0,
            child: child,
          );
        },
        child: SizedBox(
          width: widget.width ?? double.infinity,
          height: 52,
          child: widget.isOutlined
              ? OutlinedButton(
                  onPressed: isEnabled ? widget.onPressed : null,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isEnabled
                          ? AppColors.primary
                          : AppColors.border.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: _buildChild(isEnabled),
                )
              : Container(
                  decoration: BoxDecoration(
                    gradient: isEnabled ? AppColors.primaryGradient : null,
                    color: isEnabled
                        ? null
                        : AppColors.border.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: isEnabled
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: ElevatedButton(
                    onPressed: isEnabled ? widget.onPressed : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: _buildChild(isEnabled),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildChild(bool isEnabled) {
    if (widget.isLoading) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppColors.textPrimary,
        ),
      );
    }

    final Color textColor = isEnabled ? Colors.white : AppColors.textMuted;

    Widget childContent;
    if (widget.icon != null) {
      childContent = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.icon, size: 20, color: textColor),
          const SizedBox(width: 8),
          Text(
            widget.label,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
        ],
      );
    } else {
      childContent = Text(
        widget.label,
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      );
    }
    return childContent;
  }
}
