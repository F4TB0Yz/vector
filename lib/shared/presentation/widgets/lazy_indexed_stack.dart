import 'package:flutter/material.dart';

/// A widget that behaves like [IndexedStack] but lazy-loads its children.
/// 
/// Children are only built when they are accessed for the first time.
/// Once built, they are kept in the tree (preserving state) just like [IndexedStack].
class LazyIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final AlignmentGeometry alignment;
  final TextDirection? textDirection;
  final StackFit sizing;

  const LazyIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.alignment = AlignmentDirectional.topStart,
    this.textDirection,
    this.sizing = StackFit.loose,
  });

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  late List<bool> _activated;

  @override
  void initState() {
    super.initState();
    _activated = List<bool>.filled(widget.children.length, false);
    _activateCurrentIndex();
  }

  @override
  void didUpdateWidget(LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.children.length != oldWidget.children.length) {
      _activated = List<bool>.filled(widget.children.length, false);
    }
    _activateCurrentIndex();
  }

  void _activateCurrentIndex() {
    if (widget.index >= 0 && widget.index < _activated.length) {
      if (!_activated[widget.index]) {
        setState(() {
          _activated[widget.index] = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Map the children: if activated, show the child; if not, show empty space.
    // IndexedStack will handle the visibility (off-screen/on-screen).
    final List<Widget> lazyChildren = List.generate(widget.children.length, (i) {
      if (_activated[i]) {
        return widget.children[i];
      }
      return const SizedBox.shrink();
    });

    return IndexedStack(
      index: widget.index,
      alignment: widget.alignment,
      textDirection: widget.textDirection,
      sizing: widget.sizing,
      children: lazyChildren,
    );
  }
}
