import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;
    String label = status;

    switch (status.toLowerCase()) {
      case 'pending':
        bg = AppColors.statusPendingLight;
        fg = AppColors.statusPending;
        icon = Icons.error_outline;
        label = 'Pending';
        break;
      case 'inprogress':
      case 'assigned':
        bg = AppColors.statusInProgressLight;
        fg = AppColors.statusInProgress;
        icon = Icons.hourglass_top_outlined;
        label = 'In Progress';
        break;
      case 'resolved':
      case 'closed':
        bg = AppColors.statusResolvedLight;
        fg = AppColors.statusResolved;
        icon = Icons.check_circle_outline;
        label = 'Resolved';
        break;
      default:
        bg = AppColors.surfaceSubtle;
        fg = AppColors.textSecondary;
        icon = Icons.info_outline;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
