import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Touch-Responsive Sliding Screen Navigator with Left/Right Touch Motions.
/// - Keeps each screen's state alive once visited (lazy loading).
/// - Performs silky-smooth horizontal slide transitions between screens.
/// - Screen Touch Motion: Swiping Right navigates back/previous screen, Swiping Left navigates forward/next module.
class LazyScreenSlider extends StatefulWidget {
  final int index;
  final List<WidgetBuilder> builders;
  final bool isGoingBack;
  final VoidCallback? onSwipeRight; // Go back / previous
  final VoidCallback? onSwipeLeft;  // Go forward / next

  const LazyScreenSlider({
    super.key,
    required this.index,
    required this.builders,
    this.isGoingBack = false,
    this.onSwipeRight,
    this.onSwipeLeft,
  });

  @override
  State<LazyScreenSlider> createState() => _LazyScreenSliderState();
}

class _LazyScreenSliderState extends State<LazyScreenSlider>
    with SingleTickerProviderStateMixin {
  late final List<Widget?> _children;
  late int _currentIndex;
  int? _previousIndex;
  late final AnimationController _animController;
  late final Animation<double> _slideAnimation;

  // Interactive horizontal drag tracking
  double _horizontalDragDelta = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    _children = List<Widget?>.filled(widget.builders.length, null);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _slideAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _activate(_currentIndex);
  }

  void _activate(int idx) {
    if (idx >= 0 && idx < _children.length && _children[idx] == null) {
      _children[idx] = widget.builders[idx](context);
    }
  }

  @override
  void didUpdateWidget(LazyScreenSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != oldWidget.index) {
      _previousIndex = oldWidget.index;
      _currentIndex = widget.index;
      _activate(_currentIndex);
      _horizontalDragDelta = 0.0;
      _isDragging = false;
      _animController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Widget _buildScreen(int? idx) {
    if (idx == null || idx < 0 || idx >= _children.length) {
      return const SizedBox.shrink();
    }
    _activate(idx);
    return _children[idx] ?? const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    Widget content = AnimatedBuilder(
      animation: _slideAnimation,
      builder: (ctx, _) {
        final isAnimating = _animController.isAnimating;

        // Transition Animation Active
        if (isAnimating && _previousIndex != null && _previousIndex != _currentIndex) {
          final t = _slideAnimation.value;

          if (widget.isGoingBack) {
            // Popping / Going Left: Current screen slides out to right, previous screen slides in from left
            final incomingOffset = Offset(-0.25 * (1.0 - t) * screenWidth, 0);
            final outgoingOffset = Offset(t * screenWidth, 0);

            return Stack(
              fit: StackFit.expand,
              children: [
                Transform.translate(
                  offset: incomingOffset,
                  child: _buildScreen(_currentIndex),
                ),
                IgnorePointer(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.15 * (1.0 - t)),
                  ),
                ),
                Transform.translate(
                  offset: outgoingOffset,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.20),
                          blurRadius: 20,
                          offset: const Offset(-4, 0),
                        ),
                      ],
                    ),
                    child: _buildScreen(_previousIndex),
                  ),
                ),
              ],
            );
          } else {
            // Pushing / Going Right: Previous screen slides slightly left, current screen slides in from right
            final outgoingOffset = Offset(-0.25 * t * screenWidth, 0);
            final incomingOffset = Offset((1.0 - t) * screenWidth, 0);

            return Stack(
              fit: StackFit.expand,
              children: [
                Transform.translate(
                  offset: outgoingOffset,
                  child: _buildScreen(_previousIndex),
                ),
                IgnorePointer(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.15 * t),
                  ),
                ),
                Transform.translate(
                  offset: incomingOffset,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.20),
                          blurRadius: 20,
                          offset: const Offset(-4, 0),
                        ),
                      ],
                    ),
                    child: _buildScreen(_currentIndex),
                  ),
                ),
              ],
            );
          }
        }

        // Idle: Render current screen directly for 100% 60fps performance
        return _buildScreen(_currentIndex);
      },
    );

    // Screen Touch Motion: Left/Right Horizontal Swipe Gestures
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (details) {
        _horizontalDragDelta = 0.0;
        _isDragging = true;
      },
      onHorizontalDragUpdate: (details) {
        if (_isDragging) {
          _horizontalDragDelta += details.delta.dx;
        }
      },
      onHorizontalDragEnd: (details) {
        if (_isDragging) {
          _isDragging = false;
          final velocity = details.primaryVelocity ?? 0.0;

          // 1) Swipe Right (finger moves left-to-right > 65px or velocity > 300) -> Navigate Back / Previous!
          if ((_horizontalDragDelta > 65.0 || velocity > 300.0) && widget.onSwipeRight != null) {
            HapticFeedback.lightImpact();
            widget.onSwipeRight!();
            return;
          }

          // 2) Swipe Left (finger moves right-to-left < -65px or velocity < -300) -> Navigate Forward / Next!
          if ((_horizontalDragDelta < -65.0 || velocity < -300.0) && widget.onSwipeLeft != null) {
            HapticFeedback.lightImpact();
            widget.onSwipeLeft!();
            return;
          }
        }
      },
      onHorizontalDragCancel: () {
        _isDragging = false;
        _horizontalDragDelta = 0.0;
      },
      child: content,
    );
  }
}
