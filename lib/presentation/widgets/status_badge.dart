import 'package:flutter/material.dart';
import '../../core/localization/app_translations.dart';
import '../../core/services/translation_service.dart';
import '../../core/theme/app_colors.dart';
import '../providers/language_provider.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status.toLowerCase().replaceAll(' ', '')) {
      case 'pending':
        bg = AppColors.statusPendingLight;
        fg = AppColors.statusPending;
        icon = Icons.error_outline;
        break;
      case 'inprogress':
      case 'assigned':
      case 'indiscussion':
        bg = AppColors.statusInProgressLight;
        fg = AppColors.statusInProgress;
        icon = Icons.hourglass_top_outlined;
        break;
      case 'resolved':
      case 'closed':
      case 'completed':
      case 'approved':
        bg = AppColors.statusResolvedLight;
        fg = AppColors.statusResolved;
        icon = Icons.check_circle_outline;
        break;
      case 'rejected':
        bg = AppColors.statusPendingLight;
        fg = AppColors.statusPending;
        icon = Icons.cancel_outlined;
        break;
      default:
        bg = AppColors.surfaceSubtle;
        fg = AppColors.textSecondary;
        icon = Icons.info_outline;
    }

    return ValueListenableBuilder<String>(
      valueListenable: appLanguageValueNotifier,
      builder: (context, lang, _) {
        final mapped = AppTranslations.getStatus(status, lang);
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
              Flexible(
                child: AppTranslatedText(
                  mapped,
                  targetLanguage: lang,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fg,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
