import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/localization/app_translations.dart';
import '../providers/language_provider.dart';

class BottomBarItemData {
  final IconData icon;
  final String label;

  const BottomBarItemData({
    required this.icon,
    required this.label,
  });
}

class CurvedBottomBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onFabTap;
  final ValueChanged<PointerDownEvent>? onFabPointerDown;
  final ValueChanged<PointerMoveEvent>? onFabPointerMove;
  final ValueChanged<PointerUpEvent>? onFabPointerUp;
  final VoidCallback? onFabPointerCancel;
  final List<BottomBarItemData>? customItems;

  const CurvedBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onFabTap,
    this.onFabPointerDown,
    this.onFabPointerMove,
    this.onFabPointerUp,
    this.onFabPointerCancel,
    this.customItems,
  });

  @override
  State<CurvedBottomBar> createState() => _CurvedBottomBarState();
}

class _CurvedBottomBarState extends State<CurvedBottomBar> {
  bool _isFabPressed = false;

  BottomBarItemData _getItem(int index, String lang) {
    if (widget.customItems != null && index < widget.customItems!.length) {
      final item = widget.customItems![index];
      final translated = AppTranslations.translateDirect(item.label, lang: lang);
      return BottomBarItemData(icon: item.icon, label: translated);
    }
    switch (index) {
      case 0:
        return BottomBarItemData(
          icon: Icons.dashboard_rounded,
          label: AppTranslations.getNavTitle('dashboard', lang),
        );
      case 1:
        return BottomBarItemData(
          icon: Icons.grid_view_rounded,
          label: AppTranslations.pick(lang, en: 'Requests', mr: 'विनंत्या', hi: 'अनुरोध'),
        );
      case 2:
        return BottomBarItemData(
          icon: Icons.notifications_rounded,
          label: AppTranslations.getNavTitle('letters', lang),
        );
      case 3:
      default:
        return BottomBarItemData(
          icon: Icons.person_rounded,
          label: AppTranslations.pick(lang, en: 'Profile', mr: 'प्रोफाईल', hi: 'प्रोफाइल'),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const double kTopOverhang = 22.0;
    const double kBarHeight = 64.0;
    const double kFabOuterSize = 56.0;
    const double kFabInnerSize = 44.0;
    const double kHorizontalMargin = 16.0;
    final double bottomMargin = bottomPadding > 0 ? bottomPadding : 12.0;
    final totalHeight = kTopOverhang + kBarHeight + bottomMargin;

    return ValueListenableBuilder<String>(
      valueListenable: appLanguageValueNotifier,
      builder: (context, lang, _) {
        final item0 = _getItem(0, lang);
        final item1 = _getItem(1, lang);
        final item2 = _getItem(2, lang);
        final item3 = _getItem(3, lang);

        return SizedBox(
          height: totalHeight,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // 1) Floating Curved White Background Bar with Soft Shadow & Border on All Edges
              Positioned(
                left: kHorizontalMargin,
                right: kHorizontalMargin,
                bottom: bottomMargin,
                height: kBarHeight,
                child: CustomPaint(
                  size: const Size(double.infinity, kBarHeight),
                  painter: _CurvedNotchPainter(
                    barColor: Colors.white,
                    borderColor: const Color(0xFFE2E8F0),
                    notchRadius: 38.0,
                    notchDepth: 22.0,
                    cornerRadius: 24.0,
                  ),
                ),
              ),

              // 2) Navigation Tab Items inside Floating Bar
              Positioned(
                left: kHorizontalMargin,
                right: kHorizontalMargin,
                bottom: bottomMargin,
                height: kBarHeight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Tab 0
                    Expanded(
                      child: _buildNavItem(
                        index: 0,
                        icon: item0.icon,
                        label: item0.label,
                      ),
                    ),

                    // Tab 1
                    Expanded(
                      child: _buildNavItem(
                        index: 1,
                        icon: item1.icon,
                        label: item1.label,
                      ),
                    ),

                    // Center gap for the FAB
                    const SizedBox(width: 72),

                    // Tab 2
                    Expanded(
                      child: _buildNavItem(
                        index: 2,
                        icon: item2.icon,
                        label: item2.label,
                      ),
                    ),

                    // Tab 3: Fixed Profile / Settings
                    Expanded(
                      child: _buildNavItem(
                        index: 3,
                        icon: item3.icon,
                        label: item3.label,
                      ),
                    ),
                  ],
                ),
              ),

          // 3) Elevated Center Action Button (+)
          Positioned(
            top: 2.0,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (e) {
                setState(() => _isFabPressed = true);
                HapticFeedback.heavyImpact();
                widget.onFabPointerDown?.call(e);
              },
              onPointerMove: (e) {
                widget.onFabPointerMove?.call(e);
              },
              onPointerUp: (e) {
                setState(() => _isFabPressed = false);
                widget.onFabPointerUp?.call(e);
              },
              onPointerCancel: (_) {
                setState(() => _isFabPressed = false);
                widget.onFabPointerCancel?.call();
              },
              child: AnimatedScale(
                scale: _isFabPressed ? 0.90 : 1.0,
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOutBack,
                child: Container(
                  width: kFabOuterSize,
                  height: kFabOuterSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: _isFabPressed ? 0.40 : 0.25),
                        blurRadius: _isFabPressed ? 18 : 14,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: kFabInnerSize,
                      height: kFabInnerSize,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.bolt_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = widget.currentIndex == index;
    final activeColor = const Color(0xFF0284C7); // Krishnaniti Civic Blue
    final inactiveColor = const Color(0xFF64748B); // Slate grey

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap(index);
        },
        splashColor: activeColor.withValues(alpha: 0.08),
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeColor.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 21,
                  color: isSelected ? activeColor : inactiveColor,
                ),
              ),
              const SizedBox(height: 1.5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? activeColor : inactiveColor,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurvedNotchPainter extends CustomPainter {
  final Color barColor;
  final Color borderColor;
  final double notchRadius;
  final double notchDepth;
  final double cornerRadius;

  _CurvedNotchPainter({
    required this.barColor,
    required this.borderColor,
    required this.notchRadius,
    required this.notchDepth,
    required this.cornerRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final r = cornerRadius;
    final R = notchRadius;
    final D = notchDepth;
    final c = R * 0.45;

    final path = Path();
    // 1. Top-left corner: start at (0, r) and arc to (r, 0)
    path.moveTo(0, r);
    path.arcToPoint(
      Offset(r, 0),
      radius: Radius.circular(r),
      clockwise: true,
    );

    // 2. Flat top line to notch start
    path.lineTo(cx - R, 0);

    // 3. Smooth cubic bezier dip to center bottom of notch (cx, D)
    path.cubicTo(
      cx - R + c, 0,
      cx - c, D,
      cx, D,
    );

    // 4. Smooth cubic bezier rise to notch end (cx + R, 0)
    path.cubicTo(
      cx + c, D,
      cx + R - c, 0,
      cx + R, 0,
    );

    // 5. Flat top line to top-right corner start (w - r, 0)
    path.lineTo(w - r, 0);

    // 6. Top-right rounded corner: arc to (w, r)
    path.arcToPoint(
      Offset(w, r),
      radius: Radius.circular(r),
      clockwise: true,
    );

    // 7. Right vertical edge down to bottom-right corner start (w, h - r)
    path.lineTo(w, h - r);

    // 8. Bottom-right rounded corner: arc to (w - r, h)
    path.arcToPoint(
      Offset(w - r, h),
      radius: Radius.circular(r),
      clockwise: true,
    );

    // 9. Flat bottom edge to bottom-left corner start (r, h)
    path.lineTo(r, h);

    // 10. Bottom-left rounded corner: arc to (0, h - r)
    path.arcToPoint(
      Offset(0, h - r),
      radius: Radius.circular(r),
      clockwise: true,
    );

    // 11. Left vertical edge up to start (0, r)
    path.lineTo(0, r);

    path.close();

    // 1) Soft ambient shadow underneath the floating white bar
    canvas.drawShadow(
      path,
      Colors.black.withValues(alpha: 0.12),
      14,
      false,
    );

    // 2) Fill bar with pure white
    final paint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);

    // 3) Complete border around the ENTIRE perimeter of the floating bar
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _CurvedNotchPainter oldDelegate) {
    return oldDelegate.barColor != barColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.notchRadius != notchRadius ||
        oldDelegate.notchDepth != notchDepth ||
        oldDelegate.cornerRadius != cornerRadius;
  }
}
