import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../providers/custom_navigation_provider.dart';

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

  final List<RadialMenuItem>? customItems;

  const RadialQuickAccessMenu({
    super.key,
    required this.centerOffset,
    this.dragPosition,
    required this.onSelect,
    required this.onClose,
    this.customItems,
  });

  List<RadialMenuItem> get activeItems => customItems ?? items;

  static List<RadialMenuItem> buildItemsFromConfigs(List<NavItemConfig> configs) {
    if (configs.length != 7) return items;
    return [
      // 0: Left Bottom Leg
      RadialMenuItem(
        id: configs[0].key,
        titleEn: configs[0].titleEn,
        titleMr: configs[0].titleMr,
        icon: configs[0].icon,
        gradient: const [Color(0xFF0284C7), Color(0xFF0369A1)],
        legDy: 34.0,
        isLeftLeg: true,
      ),
      // 1: Left Arc (162 deg)
      RadialMenuItem(
        id: configs[1].key,
        titleEn: configs[1].titleEn,
        titleMr: configs[1].titleMr,
        icon: configs[1].icon,
        gradient: const [Color(0xFF0284C7), Color(0xFF0369A1)],
        angleDeg: 162.0,
      ),
      // 2: Left Upper Arc (126 deg)
      RadialMenuItem(
        id: configs[2].key,
        titleEn: configs[2].titleEn,
        titleMr: configs[2].titleMr,
        icon: configs[2].icon,
        gradient: const [Color(0xFF0284C7), Color(0xFF0369A1)],
        angleDeg: 126.0,
      ),
      // 3: Top Peak Arc (90 deg)
      RadialMenuItem(
        id: configs[3].key,
        titleEn: configs[3].titleEn,
        titleMr: configs[3].titleMr,
        icon: configs[3].icon,
        gradient: const [Color(0xFF0284C7), Color(0xFF0369A1)],
        angleDeg: 90.0,
      ),
      // 4: Right Upper Arc (54 deg)
      RadialMenuItem(
        id: configs[4].key,
        titleEn: configs[4].titleEn,
        titleMr: configs[4].titleMr,
        icon: configs[4].icon,
        gradient: const [Color(0xFF0284C7), Color(0xFF0369A1)],
        angleDeg: 54.0,
      ),
      // 5: Right Arc (18 deg)
      RadialMenuItem(
        id: configs[5].key,
        titleEn: configs[5].titleEn,
        titleMr: configs[5].titleMr,
        icon: configs[5].icon,
        gradient: const [Color(0xFF0284C7), Color(0xFF0369A1)],
        angleDeg: 18.0,
      ),
      // 6: Right Bottom Leg
      RadialMenuItem(
        id: configs[6].key,
        titleEn: configs[6].titleEn,
        titleMr: configs[6].titleMr,
        icon: configs[6].icon,
        gradient: const [Color(0xFF0284C7), Color(0xFF0369A1)],
        legDy: 34.0,
        isLeftLeg: false,
      ),
    ];
  }

  static const List<RadialMenuItem> items = [
    // 0: Left Bottom Leg
    RadialMenuItem(
      id: 'works',
      titleEn: 'Work History',
      titleMr: 'विकास कामे',
      icon: Icons.engineering_rounded,
      gradient: [Color(0xFF0284C7), Color(0xFF0369A1)],
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
      gradient: [Color(0xFF0284C7), Color(0xFF0369A1)],
      angleDeg: 126.0,
    ),
    // 3: Top Peak Arc (90 deg)
    RadialMenuItem(
      id: 'voters',
      titleEn: 'Voter Search',
      titleMr: 'मतदार शोध',
      icon: Icons.person_search_rounded,
      gradient: [Color(0xFF0284C7), Color(0xFF0369A1)],
      angleDeg: 90.0,
    ),
    // 4: Right Upper Arc (54 deg)
    RadialMenuItem(
      id: 'diary',
      titleEn: 'Diary',
      titleMr: 'दैनंदिनी नोंद',
      icon: Icons.event_note_rounded,
      gradient: [Color(0xFF0284C7), Color(0xFF0369A1)],
      angleDeg: 54.0,
    ),
    // 5: Right Arc (18 deg)
    RadialMenuItem(
      id: 'visitors',
      titleEn: 'Visitor Log',
      titleMr: 'कार्यालय भेट',
      icon: Icons.badge_rounded,
      gradient: [Color(0xFF0284C7), Color(0xFF0369A1)],
      angleDeg: 18.0,
    ),
    // 6: Right Bottom Leg
    RadialMenuItem(
      id: 'ai_content',
      titleEn: 'AI Content Studio',
      titleMr: 'AI प्रसिद्धी',
      icon: Icons.auto_awesome_rounded,
      gradient: [Color(0xFF0284C7), Color(0xFF0369A1)],
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
  Offset? _currentPointerPos;

  @override
  void initState() {
    super.initState();
    _currentPointerPos = widget.dragPosition;

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
      _currentPointerPos = widget.dragPosition;
      _updateHoverFromPosition(widget.dragPosition);
    }
  }

  void _updateHoverFromPosition(Offset? pos) {
    _currentPointerPos = pos;
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

    for (int i = 0; i < widget.activeItems.length; i++) {
      final itemPos = widget.activeItems[i].getPosition(
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

  /// Calculates magnetic attraction vector pulling badge towards the touch point
  Offset _getMagneticOffset(int index, Offset basePos) {
    if (_currentPointerPos == null) return Offset.zero;
    final delta = _currentPointerPos! - basePos;
    final dist = delta.distance;

    // Active magnetic field radius: 60px
    if (dist > 60.0 || dist < 0.5) return Offset.zero;

    // Smooth quadratic ease-out pull falloff (max 12px)
    final t = (1.0 - dist / 60.0);
    final pull = 12.0 * t * t;
    return (delta / dist) * pull;
  }

  void _triggerSelection(int index) {
    HapticFeedback.mediumImpact();
    final item = widget.activeItems[index];
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

    return Material(
      type: MaterialType.transparency,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerMove: (e) {
          setState(() => _currentPointerPos = e.position);
          _updateHoverFromPosition(e.position);
        },
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
                  color: Colors.black.withValues(alpha: 0.38),
                ),
              ),
            ),
          ),

          // 2) Synchronized Unified Assembly (Track + 7 Action Items)
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
                        // A1) Soft diffused drop shadow behind the running track
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _RunningTrackShadowPainter(
                              center: Offset(cx, cy),
                              radius: RadialQuickAccessMenu.kArcRadius,
                              trackWidth: RadialQuickAccessMenu.kTrackWidth,
                            ),
                          ),
                        ),

                        // A2) Glassmorphism Frosted Blur & Translucent Sheen
                        Positioned.fill(
                          child: ClipPath(
                            clipper: _RunningTrackClipper(
                              center: Offset(cx, cy),
                              radius: RadialQuickAccessMenu.kArcRadius,
                              trackWidth: RadialQuickAccessMenu.kTrackWidth,
                            ),
                            child: BackdropFilter(
                              filter: ui.ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.65),
                                      Colors.white.withValues(alpha: 0.35),
                                      const Color(0xFFE0F2FE).withValues(alpha: 0.22),
                                    ],
                                    stops: const [0.0, 0.60, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // A3) Glass Specular Borders, Frosted Center Guideline & Dynamic Optic Glow
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _RunningTrackGlassPainter(
                              center: Offset(cx, cy),
                              radius: RadialQuickAccessMenu.kArcRadius,
                              trackWidth: RadialQuickAccessMenu.kTrackWidth,
                              sparkProgress: _sparkAnimation.value,
                              hoveredIndex: _hoveredIndex,
                              activeItems: widget.activeItems,
                            ),
                          ),
                        ),

                        // B) 7 Professional Action Symbols (App Theme Civic Blue with Magnetic Spring & Staggered Blossom)
                        ...List.generate(widget.activeItems.length, (i) {
                          final item = widget.activeItems[i];
                          final basePos = item.getPosition(
                            Offset(cx, cy),
                            RadialQuickAccessMenu.kArcRadius,
                          );
                          final isHovered = _hoveredIndex == i;
                          final magneticOffset = _getMagneticOffset(i, basePos);

                          return Positioned(
                            left: basePos.dx - 44,
                            top: basePos.dy - 44,
                            width: 88,
                            height: 88,
                            child: TweenAnimationBuilder<Offset>(
                              tween: Tween<Offset>(begin: Offset.zero, end: magneticOffset),
                              duration: const Duration(milliseconds: 90),
                              curve: Curves.easeOutCubic,
                              builder: (context, animOffset, child) {
                                return Transform.translate(
                                  offset: animOffset,
                                  child: child,
                                );
                              },
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _triggerSelection(i),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Action Circular Badge (Theme Civic Blue with Ripple Glow & Shimmer)
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 140),
                                      curve: Curves.easeOutBack,
                                      width: isHovered ? 54 : 44,
                                      height: isHovered ? 54 : 44,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: isHovered
                                              ? const [Color(0xFF0284C7), Color(0xFF0EA5E9)] // Active luminous Civic Blue
                                              : const [Color(0xFF0284C7), Color(0xFF0369A1)], // Theme Civic Blue
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF0284C7).withValues(alpha: isHovered ? 0.65 : 0.28),
                                            blurRadius: isHovered ? 18 : 8,
                                            spreadRadius: isHovered ? 3.0 : 0,
                                            offset: isHovered ? const Offset(0, 4) : const Offset(0, 2),
                                          ),
                                          if (isHovered)
                                            BoxShadow(
                                              color: const Color(0xFF38BDF8).withValues(alpha: 0.50),
                                              blurRadius: 10,
                                              spreadRadius: 1.0,
                                            ),
                                        ],
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: isHovered ? 1.0 : 0.88),
                                          width: isHovered ? 2.8 : 1.8,
                                        ),
                                      ),
                                      child: isHovered
                                          ? Icon(
                                              item.icon,
                                              color: Colors.white,
                                              size: 27,
                                            )
                                              .animate(onPlay: (controller) => controller.repeat())
                                              .shimmer(
                                                duration: 1100.ms,
                                                color: Colors.white.withValues(alpha: 0.55),
                                              )
                                          : Icon(
                                              item.icon,
                                              color: Colors.white,
                                              size: 21,
                                            ),
                                    ),
                                    const SizedBox(height: 2),

                                    // Text Label Badge (Simple, Clean & Premium Pill)
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 140),
                                      curve: Curves.easeOutCubic,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isHovered ? 8 : 6,
                                        vertical: isHovered ? 2.5 : 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isHovered
                                              ? const Color(0xFF0284C7)
                                              : const Color(0xFFCBD5E1),
                                          width: isHovered ? 1.4 : 0.8,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isHovered
                                                ? const Color(0xFF0284C7).withValues(alpha: 0.24)
                                                : Colors.black.withValues(alpha: 0.06),
                                            blurRadius: isHovered ? 8 : 3,
                                            offset: const Offset(0, 1.5),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        isMr ? item.titleMr : item.titleEn,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          decoration: TextDecoration.none,
                                          fontSize: isHovered ? 9.6 : 8.8,
                                          fontWeight: isHovered ? FontWeight.w700 : FontWeight.w600,
                                          color: isHovered
                                              ? const Color(0xFF0284C7)
                                              : const Color(0xFF334155),
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                                // Staggered radial blossom entrance
                                .animate()
                                .scale(
                                  begin: const Offset(0.35, 0.35),
                                  end: const Offset(1.0, 1.0),
                                  delay: (i * 26).ms,
                                  duration: 260.ms,
                                  curve: Curves.easeOutBack,
                                )
                                .fadeIn(
                                  delay: (i * 20).ms,
                                  duration: 180.ms,
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
    ),
  );
}
}

Path _buildRunningTrackPath({
  required double cx,
  required double cy,
  required double radius,
  required double trackWidth,
  required double bottomY,
}) {
  final rIn = radius - (trackWidth / 2.0); // 76.0px
  final rOut = radius + (trackWidth / 2.0); // 148.0px

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

  return trackPath;
}

class _RunningTrackClipper extends CustomClipper<Path> {
  final Offset center;
  final double radius;
  final double trackWidth;

  _RunningTrackClipper({
    required this.center,
    required this.radius,
    required this.trackWidth,
  });

  @override
  Path getClip(Size size) {
    final bottomY = math.max(size.height, center.dy + 120.0);
    return _buildRunningTrackPath(
      cx: center.dx,
      cy: center.dy,
      radius: radius,
      trackWidth: trackWidth,
      bottomY: bottomY,
    );
  }

  @override
  bool shouldReclip(covariant _RunningTrackClipper oldClipper) {
    return oldClipper.center != center ||
        oldClipper.radius != radius ||
        oldClipper.trackWidth != trackWidth;
  }
}

class _RunningTrackShadowPainter extends CustomPainter {
  final Offset center;
  final double radius;
  final double trackWidth;

  _RunningTrackShadowPainter({
    required this.center,
    required this.radius,
    required this.trackWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bottomY = math.max(size.height, center.dy + 120.0);
    final trackPath = _buildRunningTrackPath(
      cx: center.dx,
      cy: center.dy,
      radius: radius,
      trackWidth: trackWidth,
      bottomY: bottomY,
    );

    // Deep, diffused ambient drop shadow behind the glass running track
    canvas.drawShadow(
      trackPath,
      Colors.black.withValues(alpha: 0.20),
      18,
      false,
    );
  }

  @override
  bool shouldRepaint(covariant _RunningTrackShadowPainter oldDelegate) {
    return oldDelegate.center != center ||
        oldDelegate.radius != radius ||
        oldDelegate.trackWidth != trackWidth;
  }
}

class _RunningTrackGlassPainter extends CustomPainter {
  final Offset center;
  final double radius;
  final double trackWidth;
  final double sparkProgress;
  final int hoveredIndex;
  final List<RadialMenuItem> activeItems;

  _RunningTrackGlassPainter({
    required this.center,
    required this.radius,
    required this.trackWidth,
    required this.sparkProgress,
    this.hoveredIndex = -1,
    this.activeItems = RadialQuickAccessMenu.items,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = center.dx;
    final cy = center.dy;

    // 1) Expanding spark ripple wave on hold (Theme Civic Blue)
    if (sparkProgress < 1.0) {
      final rippleRadius = 28.0 + sparkProgress * 120.0;
      final rippleOpacity = (1.0 - sparkProgress).clamp(0.0, 1.0);
      final ripplePaint = Paint()
        ..color = const Color(0xFF0284C7).withValues(alpha: rippleOpacity * 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5 * (1.0 - sparkProgress);
      canvas.drawCircle(center, rippleRadius, ripplePaint);
    }

    final rIn = radius - (trackWidth / 2.0);  // 76.0px
    final rOut = radius + (trackWidth / 2.0); // 148.0px
    final bottomY = math.max(size.height, cy + 120.0);

    // 2) Center running track lane guideline (Frosted Civic Blue tint)
    final laneGuidePaint = Paint()
      ..color = const Color(0xFF0284C7).withValues(alpha: 0.20)
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

    // 3) Outer glass contour border with specular highlight
    final outerBorderPath = Path();
    outerBorderPath.moveTo(cx - rOut, bottomY);
    outerBorderPath.lineTo(cx - rOut, cy);
    outerBorderPath.arcToPoint(
      Offset(cx + rOut, cy),
      radius: Radius.circular(rOut),
      clockwise: true,
    );
    outerBorderPath.lineTo(cx + rOut, bottomY);

    final outerBorderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(outerBorderPath, outerBorderPaint);

    // 4) Inner glass contour border
    final innerBorderPath = Path();
    innerBorderPath.moveTo(cx - rIn, bottomY);
    innerBorderPath.lineTo(cx - rIn, cy);
    innerBorderPath.arcToPoint(
      Offset(cx - rIn, cy),
      radius: Radius.circular(rIn),
      clockwise: false,
    );
    innerBorderPath.lineTo(cx - rIn, bottomY);

    final innerBorderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(innerBorderPath, innerBorderPaint);

    // 5) Dynamic Optic Fiber Illumination & Glow when hovering over items
    if (hoveredIndex >= 0 && hoveredIndex < activeItems.length) {
      final activeItem = activeItems[hoveredIndex];
      final itemPos = activeItem.getPosition(center, radius);

      // Ambient radial bloom behind the active glass track zone
      final bloomPaint = Paint()
        ..shader = ui.Gradient.radial(
          itemPos,
          44.0,
          [
            const Color(0xFF38BDF8).withValues(alpha: 0.40),
            const Color(0xFF0284C7).withValues(alpha: 0.16),
            Colors.transparent,
          ],
          [0.0, 0.55, 1.0],
        );
      canvas.drawCircle(itemPos, 44.0, bloomPaint);

      // Illuminated guideline pulse along the active segment
      final activeGuidePaint = Paint()
        ..color = const Color(0xFF38BDF8).withValues(alpha: 0.70)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;

      if (activeItem.legDy != null) {
        final legX = activeItem.isLeftLeg ? cx - radius : cx + radius;
        canvas.drawLine(
          Offset(legX, cy),
          Offset(legX, bottomY),
          activeGuidePaint,
        );
      } else if (activeItem.angleDeg != null) {
        final activeRad = activeItem.angleDeg! * math.pi / 180.0;
        final sweepSpan = 0.32; // ~18 degrees span
        final startAngle = -activeRad - sweepSpan / 2.0;
        final arcRect = Rect.fromCircle(center: center, radius: radius);
        canvas.drawArc(
          arcRect,
          startAngle,
          sweepSpan,
          false,
          activeGuidePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RunningTrackGlassPainter oldDelegate) {
    return oldDelegate.sparkProgress != sparkProgress ||
        oldDelegate.radius != radius ||
        oldDelegate.trackWidth != trackWidth ||
        oldDelegate.center != center ||
        oldDelegate.hoveredIndex != hoveredIndex;
  }
}
