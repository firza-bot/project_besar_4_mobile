import 'package:flutter/material.dart';
import '../utils/constants.dart';

class FeatureCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final String gridBadge;
  final Color statusColor;
  final String statsInfo;
  final VoidCallback onTap;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.gridBadge,
    required this.statusColor,
    required this.statsInfo,
    required this.onTap,
  });

  @override
  State<FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<FeatureCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
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
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: AppColors.border,
                width: 0.8,
              ),
            ),
            child: Stack(
              children: [
                // Top accent border line (matching the web card colored line)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 4,
                    color: widget.accentColor,
                  ),
                ),
                
                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md + 4, AppSpacing.md, AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Icon, GRID Badge, and Status Dot
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: widget.accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Icon(
                              widget.icon,
                              color: widget.accentColor,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // GRID badge (e.g. GRID 1)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              widget.gridBadge.toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFFC084FC),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Status Dot indicator (Green / Orange)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: widget.statusColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: widget.statusColor.withValues(alpha: 0.6),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Title
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      
                      // Subtitle / Description
                      Text(
                        widget.subtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: AppColors.border, thickness: 0.5),
                      const SizedBox(height: 8),
                      
                      // Bottom stats / metadata
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 13,
                            color: widget.accentColor.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.statsInfo,
                              style: TextStyle(
                                color: widget.accentColor.withValues(alpha: 0.9),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 11,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
