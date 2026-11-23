import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Reusable Desktop Stat Card mirroring Nagarsevak-Managment Tailwind KPI cards
class DesktopStatCard extends StatefulWidget {
  final String title;
  final String titleMr;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String? subtitle;
  final VoidCallback? onTap;

  const DesktopStatCard({
    super.key,
    required this.title,
    required this.titleMr,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    this.subtitle,
    this.onTap,
  });

  @override
  State<DesktopStatCard> createState() => _DesktopStatCardState();
}

class _DesktopStatCardState extends State<DesktopStatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered ? AppColors.brand300 : AppColors.slate200,
              width: _isHovered ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? AppColors.brand600.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: _isHovered ? 16 : 8,
                offset: Offset(0, _isHovered ? 6 : 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: widget.iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: widget.iconColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.iconColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate500,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.value,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.slate900,
                        fontFamily: 'Inter',
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.slate400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
