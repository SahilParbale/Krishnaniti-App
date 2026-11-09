import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class RadialMenuItem {
  final String id;
  final String titleEn;
  final String titleMr;
  final IconData icon;
  final List<Color> gradient;
  final double? angleDeg;
  final double? legDy;
  final bool isLeftLeg;

  const RadialMenuItem({
    required this.id,
    required this.titleEn,
    required this.titleMr,
    required this.icon,
    required this.gradient,
    this.angleDeg,
    this.legDy,
    this.isLeftLeg = false,
  });

  Offset getPosition(Offset center, double radius) {
    if (legDy != null) {
      final x = isLeftLeg ? center.dx - radius : center.dx + radius;
      final y = center.dy + legDy!;
      return Offset(x, y);
    }
    final rad = (angleDeg ?? 90.0) * math.pi / 180.0;
    return Offset(
      center.dx + radius * math.cos(rad),
      center.dy - radius * math.sin(rad),
    );
  }
}

class RadialQuickAccessMenu extends ConsumerStatefulWidget {
  final Offset centerOffset;
  final Offset? dragPosition;
  final ValueChanged<String> onSelect;
  final VoidCallback onClose;

  static const double kArcRadius = 112.0;
  static const double kTrackWidth = 72.0;

  const RadialQuickAccessMenu({
    super.key,
    required this.centerOffset,
    this.dragPosition,
    required this.onSelect,
    required this.onClose,
  });

  static const List<RadialMenuItem> items = [
    // 0: Left Bottom Leg
    RadialMenuItem(
      id: 'works',
      titleEn: 'Work History',
      titleMr: 'विकास कामे',
      icon: Icons.engineering_rounded,
      gradient: [Color(0xFF0D9488), Color(0xFF0F766E)],
      legDy: 34.0,
      isLeftLeg: true,
    ),
    // 1: Left Arc (162 deg)
    RadialMenuItem(
      id: 'request',
      titleEn: 'Requests & Complaints',
      titleMr: 'तक्रारी आणि विनंती',
      icon: Icons.add_task_rounded,
      gradient: [Color(0xFF0284C7), Color(0xFF0369A1)],
      angleDeg: 162.0,
    ),
    // 2: Left Upper Arc (126 deg)
    RadialMenuItem(
      id: 'letters',
      titleEn: 'Letters',
      titleMr: 'पत्र व्यवहार',
      icon: Icons.mark_email_unread_rounded,
      gradient: [Color(0xFF6366F1), Color(0xFF4F46E5)],
      angleDeg: 126.0,
    ),
    // 3: Top Peak Arc (90 deg)
    RadialMenuItem(
      id: 'voters',
      titleEn: 'Voter Search',
      titleMr: 'मतदार शोध',
      icon: Icons.person_search_rounded,
      gradient: [Color(0xFF10B981), Color(0xFF059669)],
      angleDeg: 90.0,
    ),
    // 4: Right Upper Arc (54 deg)
    RadialMenuItem(
      id: 'diary',
      titleEn: 'Diary',
      titleMr: 'दैनंदिनी नोंद',
      icon: Icons.event_note_rounded,
      gradient: [Color(0xFFF59E0B), Color(0xFFD97706)],
      angleDeg: 54.0,
    ),
    // 5: Right Arc (18 deg)
    RadialMenuItem(
      id: 'visitors',
      titleEn: 'Visitor Log',
      titleMr: 'कार्यालय भेट',
      icon: Icons.badge_rounded,
      gradient: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
      angleDeg: 18.0,
    ),
    // 6: Right Bottom Leg
    RadialMenuItem(
      id: 'ai_content',
      titleEn: 'AI Content Studio',
      titleMr: 'AI प्रसिद्धी',
      icon: Icons.auto_awesome_rounded,
      gradient: [Color(0xFFEC4899), Color(0xFFBE185D)],
      legDy: 34.0,
      isLeftLeg: false,
    ),
  ];

  @override
  ConsumerState<RadialQuickAccessMenu> createState() => _RadialQuickAccessMenuState();
}

class _RadialQuickAccessMenuState extends ConsumerState<RadialQuickAccessMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _sparkAnimation;

  int _hoveredIndex = -1;

  @override
  void initState() {
    super.initState();
    // Fast, responsive 240ms animation for zero lag
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _sparkAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _animController.forward();
    _updateHoverFromPosition(widget.dragPosition);
  }

  @override
  void didUpdateWidget(covariant RadialQuickAccessMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dragPosition != oldWidget.dragPosition) {
      _updateHoverFromPosition(widget.dragPosition);
    }
  }

  void _updateHoverFromPosition(Offset? pos) {
    if (pos == null) return;

    final centerDist = (pos - widget.centerOffset).distance;

    // If pointer is within 38px of center button, neutral (cancel)
    if (centerDist < 38.0) {
      if (_hoveredIndex != -1) {
        setState(() => _hoveredIndex = -1);
      }
      return;
    }

    int closestIdx = -1;
    double minDist = 999999.0;

    for (int i = 0; i < RadialQuickAccessMenu.items.length; i++) {
      final itemPos = RadialQuickAccessMenu.items[i].getPosition(
        widget.centerOffset,
        RadialQuickAccessMenu.kArcRadius,
      );
      final dist = (pos - itemPos).distance;
      if (dist < minDist) {
        minDist = dist;
        closestIdx = i;
      }
    }

    // Activate item if finger is within 50px of item center
    if (minDist <= 50.0 && closestIdx != -1) {
      if (_hoveredIndex != closestIdx) {
        HapticFeedback.selectionClick();
        setState(() => _hoveredIndex = closestIdx);
      }
    } else {
      if (_hoveredIndex != -1) {
        setState(() => _hoveredIndex = -1);
      }
    }
  }

  void _triggerSelection(int index) {
    HapticFeedback.mediumImpact();
    final item = RadialQuickAccessMenu.items[index];
    _animController.reverse().then((_) {
      widget.onSelect(item.id);
    });
  }

  void _handleDismiss() {
    _animController.reverse().then((_) {
      if (mounted) widget.onClose();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMr = ref.watch(isMarathiProvider);
    final cx = widget.centerOffset.dx;
    final cy = widget.centerOffset.dy;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerMove: (e) => _updateHoverFromPosition(e.position),
      onPointerUp: (e) {
        if (_hoveredIndex != -1) {
          _triggerSelection(_hoveredIndex);
        } else {
          _handleDismiss();
        }
      },
      onPointerCancel: (_) => _handleDismiss(),
      child: Stack(
        children: [
          // 1) Dark translucent backdrop scrim
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _handleDismiss,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  color: Colors.black.withOpacity(0.38),
                ),
              ),
            ),
          ),

        // 2) Synchronized Unified Assembly (Track + 5 Action Items)
        // Scaled as a single unit from origin (cx, cy) so there is zero lag or blinking
        AnimatedBuilder(
          animation: _animController,
          builder: (ctx, _) {
            final scaleVal = _scaleAnimation.value;
            final fadeVal = _fadeAnimation.value;

            return Positioned.fill(
              child: Opacity(
                opacity: fadeVal.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: scaleVal,
                  origin: Offset(cx, cy),
                  alignment: Alignment.topLeft,
                  child: Stack(
                    children: [
                      // A) Playground Running Track (Inner semicircle completely EMPTY)
                      CustomPaint(
                        size: MediaQuery.of(context).size,
                        painter: _RunningTrackPainter(
                          center: Offset(cx, cy),
                          radius: RadialQuickAccessMenu.kArcRadius,
                          trackWidth: RadialQuickAccessMenu.kTrackWidth,
                          sparkProgress: _sparkAnimation.value,
                        ),
                      ),

                      // B) 7 Action Symbols placed along the running track
                      ...List.generate(RadialQuickAccessMenu.items.length, (i) {
                        final item = RadialQuickAccessMenu.items[i];
                        final pos = item.getPosition(
                          Offset(cx, cy),
                          RadialQuickAccessMenu.kArcRadius,
                        );
                        final x = pos.dx;
                        final y = pos.dy;
                        final isHovered = _hoveredIndex == i;

                        return Positioned(
                          left: x - 44,
                          top: y - 44,
                          width: 88,
                          height: 88,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _triggerSelection(i),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Action Circular Badge
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 140),
                                  curve: Curves.easeOutBack,
                                  width: isHovered ? 52 : 44,
                                  height: isHovered ? 52 : 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: item.gradient,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: item.gradient.first.withOpacity(isHovered ? 0.6 : 0.35),
                                        blurRadius: isHovered ? 16 : 8,
                                        spreadRadius: isHovered ? 3 : 0,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Colors.white,
                                      width: isHovered ? 3.0 : 2.0,
                                    ),
                                  ),
                                  child: Icon(
                                    item.icon,
                                    color: Colors.white,
                                    size: isHovered ? 26 : 21,
                                  ),
                                ),
                                const SizedBox(height: 2),

                                // Text Label Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isHovered
                                        ? const Color(0xFF0F172A)
                                        : Colors.white.withOpacity(0.95),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.10),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    isMr ? item.titleMr : item.titleEn,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: isHovered ? 10.0 : 8.8,
                                      fontWeight: FontWeight.w700,
                                      color: isHovered ? Colors.white : const Color(0xFF1E293B),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    ),
  );
  }
}

class _RunningTrackPainter extends CustomPainter {
  final Offset center;
  final double radius;
  final double trackWidth;
  final double sparkProgress;

  _RunningTrackPainter({
    required this.center,
    required this.radius,
    required this.trackWidth,
    required this.sparkProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = center.dx;
    final cy = center.dy;

    // 1) Expanding spark ripple wave on hold
    if (sparkProgress < 1.0) {
      final rippleRadius = 28.0 + sparkProgress * 120.0;
      final rippleOpacity = (1.0 - sparkProgress).clamp(0.0, 1.0);
      final ripplePaint = Paint()
        ..color = const Color(0xFF0284C7).withOpacity(rippleOpacity * 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5 * (1.0 - sparkProgress);
      canvas.drawCircle(center, rippleRadius, ripplePaint);
    }

    // 2) Playground Running Track extending down to touch the bottom of the screen
    final rIn = radius - (trackWidth / 2.0);  // 78.0px
    final rOut = radius + (trackWidth / 2.0); // 146.0px
    final bottomY = math.max(size.height, cy + 120.0);

    final trackPath = Path();

    // Start at bottom-left outer foot (at the bottom of the screen)
    trackPath.moveTo(cx - rOut, bottomY);

    // 1. Line up along left outer edge to the arc baseline
    trackPath.lineTo(cx - rOut, cy);

    // 2. Outer top semicircle arc (9 o'clock -> 12 o'clock -> 3 o'clock: CLOCKWISE UPWARDS)
    trackPath.arcToPoint(
      Offset(cx + rOut, cy),
      radius: Radius.circular(rOut),
      clockwise: true,
    );

    // 3. Line down along right outer edge to the bottom of the screen
    trackPath.lineTo(cx + rOut, bottomY);

    // 4. Line across the right foot to inner edge
    trackPath.lineTo(cx + rIn, bottomY);

    // 5. Line up along right inner edge to the arc baseline
    trackPath.lineTo(cx + rIn, cy);

    // 6. Inner top semicircle arc back to left (3 o'clock inner -> 12 o'clock inner -> 9 o'clock inner: COUNTER-CLOCKWISE UPWARDS)
    trackPath.arcToPoint(
      Offset(cx - rIn, cy),
      radius: Radius.circular(rIn),
      clockwise: false,
    );

    // 7. Line down along left inner edge to the bottom of the screen
    trackPath.lineTo(cx - rIn, bottomY);

    // 8. Line across the left foot back to outer start
    trackPath.close();

    // Soft drop shadow underneath the running track
    canvas.drawShadow(trackPath, Colors.black.withOpacity(0.12), 12, false);

    // Solid clean white fill for the running track
    final trackFillPaint = Paint()
      ..color = Colors.white.withOpacity(0.96)
      ..style = PaintingStyle.fill;
    canvas.drawPath(trackPath, trackFillPaint);

    // Center running track lane guideline (from bottom-left, around top, down to bottom-right)
    final laneGuidePaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final laneGuidePath = Path();
    laneGuidePath.moveTo(cx - radius, bottomY);
    laneGuidePath.lineTo(cx - radius, cy);
    laneGuidePath.arcToPoint(
      Offset(cx + radius, cy),
      radius: Radius.circular(radius),
      clockwise: true,
    );
    laneGuidePath.lineTo(cx + radius, bottomY);
    canvas.drawPath(laneGuidePath, laneGuidePaint);

    // Crisp outline borders for outer and inner boundaries
    final borderPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Outer contour border touching the bottom
    final outerBorderPath = Path();
    outerBorderPath.moveTo(cx - rOut, bottomY);
    outerBorderPath.lineTo(cx - rOut, cy);
    outerBorderPath.arcToPoint(
      Offset(cx + rOut, cy),
      radius: Radius.circular(rOut),
      clockwise: true,
    );
    outerBorderPath.lineTo(cx + rOut, bottomY);
    canvas.drawPath(outerBorderPath, borderPaint);

    // Inner contour border touching the bottom
    final innerBorderPath = Path();
    innerBorderPath.moveTo(cx - rIn, bottomY);
    innerBorderPath.lineTo(cx - rIn, cy);
    innerBorderPath.arcToPoint(
      Offset(cx + rIn, cy),
      radius: Radius.circular(rIn),
      clockwise: true,
    );
    innerBorderPath.lineTo(cx + rIn, bottomY);
    canvas.drawPath(innerBorderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _RunningTrackPainter oldDelegate) {
    return oldDelegate.sparkProgress != sparkProgress ||
        oldDelegate.radius != radius ||
        oldDelegate.trackWidth != trackWidth ||
        oldDelegate.center != center;
  }
}
