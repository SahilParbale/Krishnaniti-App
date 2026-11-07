import 'package:flutter/material.dart';

/// A lazy-loading IndexedStack that builds its children on-demand when first visited,
/// and preserves their exact State throughout the user's session without re-instantiation or resets.
class LazyIndexedStack extends StatefulWidget {
  final int index;
  final List<WidgetBuilder> builders;

  const LazyIndexedStack({
    super.key,
    required this.index,
    required this.builders,
  });

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  late final List<Widget?> _children;

  @override
  void initState() {
    super.initState();
    _children = List<Widget?>.filled(widget.builders.length, null);
    _activate(widget.index);
  }

  @override
  void didUpdateWidget(LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != oldWidget.index) {
      _activate(widget.index);
    }
  }

  void _activate(int index) {
    if (index >= 0 && index < _children.length && _children[index] == null) {
      _children[index] = widget.builders[index](context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.index,
      children: List<Widget>.generate(
        widget.builders.length,
        (i) => _children[i] ?? const SizedBox.shrink(),
      ),
    );
  }
}

