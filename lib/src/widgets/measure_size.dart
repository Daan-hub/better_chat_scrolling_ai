import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class MeasureSize extends StatefulWidget {
  final Widget child;
  final ValueChanged<Size> onChange;

  const MeasureSize({
    super.key,
    required this.child,
    required this.onChange,
  });

  @override
  State<MeasureSize> createState() => _MeasureSizeState();
}

class _MeasureSizeState extends State<MeasureSize> {
  final _key = GlobalKey();
  Size? _lastSize;

  @override
  void initState() {
    super.initState();
    _scheduleCheck();
  }

  @override
  void didUpdateWidget(MeasureSize oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleCheck();
  }

  void _scheduleCheck() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _checkSize();
    });
  }

  void _checkSize() {
    final renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;
    final newSize = renderBox.size;
    if (_lastSize != newSize) {
      _lastSize = newSize;
      widget.onChange(newSize);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(key: _key, child: widget.child);
  }
}
