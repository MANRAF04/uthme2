import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

/// Press feedback that starts on touch down, not on release. The scale is
/// driven by a critically damped spring from its current value, so a quick
/// tap or a cancelled press never jumps.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final double pressedOpacity;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.97,
    this.pressedOpacity = 1,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  static final _spring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 600,
    ratio: 1,
  );

  late final AnimationController _press = AnimationController.unbounded(
    vsync: this,
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _press.value = target;
      return;
    }
    _press.animateWith(
      SpringSimulation(_spring, _press.value, target, _press.velocity),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _animateTo(1) : null,
      onTapUp: enabled ? (_) => _animateTo(0) : null,
      onTapCancel: enabled ? () => _animateTo(0) : null,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _press,
        child: widget.child,
        builder: (context, child) {
          final t = _press.value.clamp(0.0, 1.0);
          return Opacity(
            opacity: 1 - (1 - widget.pressedOpacity) * t,
            child: Transform.scale(
              scale: 1 - (1 - widget.pressedScale) * _press.value,
              child: child,
            ),
          );
        },
      ),
    );
  }
}
