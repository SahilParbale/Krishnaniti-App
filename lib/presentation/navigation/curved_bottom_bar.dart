import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CurvedBottomBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onFabTap;
  final ValueChanged<PointerDownEvent>? onFabPointerDown;
  final ValueChanged<PointerMoveEvent>? onFabPointerMove;
  final ValueChanged<PointerUpEvent>? onFabPointerUp;
  final VoidCallback? onFabPointerCancel;

  const CurvedBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onFabTap,
    this.onFabPointerDown,
    this.onFabPointerMove,
    this.onFabPointerUp,
    this.onFabPointerCancel,
  });

  @override
  State<CurvedBottomBar> createState() => _CurvedBottomBarState();
}

class _CurvedBottomBarState extends State<CurvedBottomBar> {
  bool _isFabPressed = false;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const double kTopOverhang = 26.0;
    const double kBarHeight = 66.0;
    const double kFabOuterSize = 58.0;
    const double kFabInnerSize = 44.0;
    final totalHeight = kTopOverhang + kBarHeight + bottomPadding;

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // 1) Curved White Background Bar with Soft Shadow & Top Border
          Positioned.fill(
            child: CustomPaint(
              size: Size(double.infinity, totalHeight),
              painter: _CurvedNotchPainter(
                topOverhang: kTopOverhang,
                barHeight: kBarHeight + bottomPadding,
                barColor: Colors.white,
                borderColor: const Color(0xFFE2E8F0),
                notchRadius: 42.0,
                notchDepth: 26.0,
                cornerRadius: 24.0,
              ),
            ),
          ),

          // 2) Navigation Tab Items
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomPadding,
            height: kBarHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Tab 0: Dashboard
                Expanded(
                  child: _buildNavItem(
                    index: 0,
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                  ),
                ),

                // Tab 1: Requests (4-square grid icon)
                Expanded(
                  child: _buildNavItem(
                    index: 1,
                    icon: Icons.grid_view_rounded,
                    label: 'Requests',
                  ),
                ),

                // Center gap for the FAB
                const SizedBox(width: 76),

                // Tab 2: Letters / Notifications (bell icon)
                Expanded(
                  child: _buildNavItem(
                    index: 2,
                    icon: Icons.notifications_rounded,
                    label: 'Letters',
                  ),
                ),

                // Tab 3: Profile (person silhouette)
                Expanded(
                  child: _buildNavItem(
                    index: 3,
                    icon: Icons.person_rounded,
                    label: 'Profile',
                  ),
                ),
              ],
            ),
          ),

          // 3) Elevated Center Action Button (+)
          Positioned(
            top: 0,
            child: Listener(
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
                scale: _isFabPressed ? 0.92 : 1.0,
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOutCubic,
                  child: Container(
                    width: kFabOuterSize,
                    height: kFabOuterSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                        BoxShadow(
                          color: const Color(0xFF0284C7).withOpacity(0.20),
                          blurRadius: 14,
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
                              color: const Color(0xFF0284C7).withOpacity(0.35),
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
        splashColor: activeColor.withOpacity(0.08),
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
                curve: Curves.easeOut,
                child: Icon(
                  icon,
                  size: 24,
                  color: isSelected ? activeColor : inactiveColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
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
  final double topOverhang;
  final double barHeight;
  final Color barColor;
  final Color borderColor;
  final double notchRadius;
  final double notchDepth;
  final double cornerRadius;

  _CurvedNotchPainter({
    required this.topOverhang,
    required this.barHeight,
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
    final y0 = topOverhang;
    final cx = w / 2;
    final r = cornerRadius;
    final R = notchRadius;
    final D = notchDepth;
    final c = R * 0.45;

    final path = Path();
    // 1. Start on left edge at corner start
    path.moveTo(0, y0 + r);

    // 2. Top-left rounded corner
    path.arcToPoint(
      Offset(r, y0),
      radius: Radius.circular(r),
      clockwise: true,
    );

    // 3. Flat top line to notch start
    path.lineTo(cx - R, y0);

    // 4. Smooth cubic bezier dip to center bottom of notch
    path.cubicTo(
      cx - R + c,
      y0,
      cx - c,
      y0 + D,
      cx,
      y0 + D,
    );

    // 5. Smooth cubic bezier rise to notch end
    path.cubicTo(
      cx + c,
      y0 + D,
      cx + R - c,
      y0,
      cx + R,
      y0,
    );

    // 6. Flat top line to top-right corner
    path.lineTo(w - r, y0);

    // 7. Top-right rounded corner
    path.arcToPoint(
      Offset(w, y0 + r),
      radius: Radius.circular(r),
      clockwise: true,
    );

    // 8. Right vertical edge down
    path.lineTo(w, h);

    // 9. Bottom edge
    path.lineTo(0, h);

    // 10. Left vertical edge up
    path.close();

    // 1) Soft ambient shadow underneath the white bar
    canvas.drawShadow(path, Colors.black.withOpacity(0.08), 10, false);

    // 2) Fill bar with pure white
    final paint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);

    // 3) Crisp top boundary border line
    final topBorderPath = Path();
    topBorderPath.moveTo(0, y0 + r);
    topBorderPath.arcToPoint(
      Offset(r, y0),
      radius: Radius.circular(r),
      clockwise: true,
    );
    topBorderPath.lineTo(cx - R, y0);
    topBorderPath.cubicTo(
      cx - R + c,
      y0,
      cx - c,
      y0 + D,
      cx,
      y0 + D,
    );
    topBorderPath.cubicTo(
      cx + c,
      y0 + D,
      cx + R - c,
      y0,
      cx + R,
      y0,
    );
    topBorderPath.lineTo(w - r, y0);
    topBorderPath.arcToPoint(
      Offset(w, y0 + r),
      radius: Radius.circular(r),
      clockwise: true,
    );

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(topBorderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _CurvedNotchPainter oldDelegate) {
    return oldDelegate.barColor != barColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.topOverhang != topOverhang ||
        oldDelegate.barHeight != barHeight;
  }
}
