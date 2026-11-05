import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// iOS style segmented control: a raised thumb slides behind the selected
/// label.
class SegmentedControl extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  const SegmentedControl({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final count = labels.length;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 280);

    return Container(
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: p.fill,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: duration,
            curve: Curves.easeOutCubic,
            alignment: Alignment(
              count == 1 ? 0 : -1 + 2 * selected / (count - 1),
              0,
            ),
            child: FractionallySizedBox(
              widthFactor: 1 / count,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: dark ? const Color(0xFF636366) : Colors.white,
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < count; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == selected,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: i == selected
                          ? null
                          : () {
                              HapticFeedback.selectionClick();
                              onChanged(i);
                            },
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: duration,
                          style: DefaultTextStyle.of(context).style
                              .merge(AppText.footnote)
                              .copyWith(
                                color: p.label,
                                fontWeight: i == selected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                          child: Text(labels[i], maxLines: 1),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
