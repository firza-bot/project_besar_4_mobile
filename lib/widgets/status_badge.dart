import 'package:flutter/material.dart';
import '../utils/constants.dart';

enum BadgeType { success, warning, error, info, neutral }

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeType type;
  final bool small;

  const StatusBadge({
    super.key,
    required this.label,
    this.type = BadgeType.neutral,
    this.small = false,
  });

  Color get _color {
    switch (type) {
      case BadgeType.success:
        return AppColors.success;
      case BadgeType.warning:
        return AppColors.warning;
      case BadgeType.error:
        return AppColors.error;
      case BadgeType.info:
        return AppColors.info;
      case BadgeType.neutral:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 12,
        vertical: small ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: _color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _color,
          fontSize: small ? 10 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
