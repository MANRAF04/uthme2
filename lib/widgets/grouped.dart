import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// iOS inset grouped section: optional header and footer around a rounded
/// card whose rows are split by inset hairlines.
class GroupedSection extends StatelessWidget {
  final String? header;
  final String? footer;
  final List<Widget> children;
  final double separatorInset;

  const GroupedSection({
    super.key,
    this.header,
    this.footer,
    required this.children,
    this.separatorInset = 16,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(
          Padding(
            padding: EdgeInsetsDirectional.only(start: separatorInset),
            child: Container(height: 0.5, color: p.separator),
          ),
        );
      }
      rows.add(children[i]);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 7),
              child: Text(
                header!.toUpperCase(),
                style: AppText.footnote.copyWith(color: p.secondaryLabel),
              ),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: ColoredBox(
              color: p.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: rows,
              ),
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 7, 16, 0),
              child: Text(
                footer!,
                style: AppText.footnote.copyWith(color: p.secondaryLabel),
              ),
            ),
        ],
      ),
    );
  }
}

/// A list row that highlights on touch down, the way iOS table cells do.
class GroupedRow extends StatefulWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final Color? titleColor;
  final bool centerTitle;

  const GroupedRow({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showChevron = false,
    this.titleColor,
    this.centerTitle = false,
  });

  @override
  State<GroupedRow> createState() => _GroupedRowState();
}

class _GroupedRowState extends State<GroupedRow> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = widget.onTap != null;

    final title = Text(
      widget.title,
      textAlign: widget.centerTitle ? TextAlign.center : TextAlign.start,
      style: AppText.body.copyWith(color: widget.titleColor ?? p.label),
    );

    return Semantics(
      button: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _setPressed(true) : null,
        onTapUp: enabled ? (_) => _setPressed(false) : null,
        onTapCancel: enabled ? () => _setPressed(false) : null,
        onTap: widget.onTap,
        child: AnimatedContainer(
          // Highlight lands instantly on press and fades out on release.
          duration: _pressed
              ? Duration.zero
              : const Duration(milliseconds: 250),
          color: _pressed ? p.cardPressed : p.card,
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: widget.subtitle == null
                    ? title
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          title,
                          const SizedBox(height: 1),
                          Text(
                            widget.subtitle!,
                            style: AppText.subheadline.copyWith(
                              color: p.secondaryLabel,
                            ),
                          ),
                        ],
                      ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: 8),
                widget.trailing!,
              ],
              if (widget.showChevron) ...[
                const SizedBox(width: 6),
                Icon(
                  CupertinoIcons.chevron_forward,
                  size: 17,
                  color: p.tertiaryLabel,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Rounded colored square holding a white glyph, like iOS Settings icons.
class IconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const IconTile({
    super.key,
    required this.icon,
    required this.color,
    this.size = 30,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.23),
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.6),
    );
  }
}

/// Coral checkmark used to mark the selected row in a pick list.
class SelectedCheck extends StatelessWidget {
  final bool visible;

  const SelectedCheck({super.key, required this.visible});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 150),
      child: Icon(
        CupertinoIcons.check_mark,
        size: 20,
        color: context.palette.accent,
      ),
    );
  }
}
