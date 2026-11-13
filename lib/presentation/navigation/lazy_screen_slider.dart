import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Touch-Responsive Sliding Screen Navigator.
/// - Keeps each screen's state alive once visited (lazy loading).
/// - Performs silky-smooth horizontal slide transitions between screens.
/// - Supports interactive left-edge swipe gesture to drag and pop back like native mobile apps.
class LazyScreenSlider extends StatefulWidget {
  final int index;
  final List<WidgetBuilder> builders;
  final bool isGoingBack;
  final bool canPop;
  final VoidCallback? onPop;

  const LazyScreenSlider({
    super.key,
    required this.index,
    required this.builders,
    this.isGoingBack = false,
    this.canPop = false,
    this.onPop,
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

  // Interactive edge-swipe touch motion state
  bool _isDragging = false;
  double _dragOffset = 0.0;

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
      _dragOffset = 0.0;
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

        // 1) Interactive Edge Drag Active
        if (_isDragging && _previousIndex != null) {
          final progress = (_dragOffset / screenWidth).clamp(0.0, 1.0);
          final prevOffset = -0.25 * (1.0 - progress) * screenWidth;

          return Stack(
            fit: StackFit.expand,
            children: [
              // Screen underneath (previous screen)
              Transform.translate(
                offset: Offset(prevOffset, 0),
                child: _buildScreen(_previousIndex),
              ),
              // Dimming scrim over previous screen
              IgnorePointer(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.15 * (1.0 - progress)),
                ),
              ),
              // Active screen sliding right
              Transform.translate(
                offset: Offset(_dragOffset, 0),
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

        // 2) Transition Animation Active
        if (isAnimating && _previousIndex != null && _previousIndex != _currentIndex) {
          final t = _slideAnimation.value;

          if (widget.isGoingBack) {
            // Popping: Current screen slides out to right, previous screen slides from left
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
            // Pushing: Previous screen slides slightly left, current screen slides from right
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

        // 3) Idle: Render current screen directly for optimal performance
        return _buildScreen(_currentIndex);
      },
    );

    // If screen can pop, allow left edge swipe touch motion to pop back
    if (widget.canPop && widget.onPop != null) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: (details) {
          // Only trigger if touch starts within 36px from left screen edge
          if (details.localPosition.dx <= 36.0) {
            _isDragging = true;
            _dragOffset = 0.0;
            HapticFeedback.selectionClick();
            setState(() {});
          }
        },
        onHorizontalDragUpdate: (details) {
          if (_isDragging) {
            setState(() {
              _dragOffset = (_dragOffset + details.delta.dx).clamp(0.0, screenWidth);
            });
          }
        },
        onHorizontalDragEnd: (details) {
          if (_isDragging) {
            final velocity = details.primaryVelocity ?? 0.0;
            if (_dragOffset > screenWidth * 0.35 || velocity > 380.0) {
              // Successfully triggered edge swipe back!
              HapticFeedback.lightImpact();
              _isDragging = false;
              _dragOffset = 0.0;
              widget.onPop!();
            } else {
              // Cancel drag and snap back
              _isDragging = false;
              _dragOffset = 0.0;
              setState(() {});
            }
          }
        },
        onHorizontalDragCancel: () {
          if (_isDragging) {
            _isDragging = false;
            _dragOffset = 0.0;
            setState(() {});
          }
        },
        child: content,
      );
    }

    return content;
  }
}
