import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loki/core/theme/app_theme.dart';

/// Soft, modern elevated card container with warm/dark border and subtle shadow.
class LokiCard extends StatelessWidget {
  const LokiCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 20,
    this.borderColor,
    this.backgroundColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? borderColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colors(context);
    final card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? c.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor ?? c.border, width: 1),
        boxShadow: c.isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.045),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: child,
    );

    if (onTap == null) return card;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: card,
    );
  }
}

/// Tactile primary CTA button with 48px+ touch target and crisp icon + label.
class LokiPrimaryButton extends StatelessWidget {
  const LokiPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colors(context);
    final bg = color ?? c.primary;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: bg,
        borderRadius: BorderRadius.circular(16),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: Colors.white),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact pill badge for streaks, metrics, and status indicators.
class LokiPillBadge extends StatelessWidget {
  const LokiPillBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.backgroundColor,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Friendly empty state with circular icon halo, title, and guidance subtitle.
class LokiEmptyState extends StatelessWidget {
  const LokiEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.accentColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colors(context);
    final accent = accentColor ?? c.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: accent.withValues(alpha: 0.22),
                  width: 1.5,
                ),
              ),
              child: Icon(icon, size: 36, color: accent),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: c.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating action button anchored bottom-right, kept well away from the tab
/// bar to avoid accidental taps. Morphs between an extended pill
/// (icon + label) and a compact circle (icon only).
class LokiFab extends StatelessWidget {
  const LokiFab({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = CupertinoIcons.add,
    this.extended = true,
  });

  static const double size = 56;

  final String label;
  final VoidCallback onPressed;
  final IconData icon;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colors(context);
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 220);
    const curve = Curves.easeOutCubic;
    const iconSize = 24.0;
    const collapsedPad = (size - iconSize) / 2;

    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: const Size(size, size),
        pressedOpacity: 0.85,
        onPressed: onPressed,
        child: AnimatedContainer(
          duration: duration,
          curve: curve,
          height: size,
          constraints: const BoxConstraints(minWidth: size),
          padding: extended
              ? const EdgeInsets.fromLTRB(18, 0, 22, 0)
              : const EdgeInsets.symmetric(horizontal: collapsedPad),
          decoration: BoxDecoration(
            color: c.primary,
            borderRadius: BorderRadius.circular(size / 2),
            boxShadow: [
              BoxShadow(
                color: c.primary.withValues(alpha: c.isDark ? 0.25 : 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: iconSize, color: Colors.white),
              AnimatedSize(
                duration: duration,
                curve: curve,
                alignment: Alignment.centerLeft,
                child: extended
                    ? Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          label,
                          maxLines: 1,
                          softWrap: false,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wraps a vertical scroll view and overlays a [LokiFab] that collapses to a
/// circle while scrolling down and expands again when scrolling up or when
/// returning to the top.
class LokiFabScrollView extends StatefulWidget {
  const LokiFabScrollView({
    super.key,
    required this.child,
    required this.fabLabel,
    required this.onFabPressed,
    this.fabIcon = CupertinoIcons.add,
  });

  final Widget child;
  final String fabLabel;
  final VoidCallback onFabPressed;
  final IconData fabIcon;

  @override
  State<LokiFabScrollView> createState() => _LokiFabScrollViewState();
}

class _LokiFabScrollViewState extends State<LokiFabScrollView> {
  static const double _topThreshold = 8;
  static const double _deltaThreshold = 4;

  bool _extended = true;

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    if (n is! ScrollUpdateNotification) return false;

    final delta = n.scrollDelta ?? 0;
    var next = _extended;
    if (n.metrics.pixels <= _topThreshold) {
      next = true;
    } else if (delta > _deltaThreshold) {
      next = false;
    } else if (delta < -_deltaThreshold) {
      next = true;
    }
    if (next != _extended) setState(() => _extended = next);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: Stack(
        children: [
          Positioned.fill(child: widget.child),
          Positioned(
            right: 16,
            bottom: 20,
            child: LokiFab(
              label: widget.fabLabel,
              icon: widget.fabIcon,
              extended: _extended,
              onPressed: widget.onFabPressed,
            ),
          ),
        ],
      ),
    );
  }
}

/// Clean mobile form field with muted top label, optional red `*` required
/// indicator, bold value text, and bottom hairline divider.
class LokiUnderlineField extends StatefulWidget {
  const LokiUnderlineField({
    super.key,
    required this.label,
    required this.controller,
    this.placeholder,
    this.required = false,
    this.errorText,
    this.autofocus = false,
    this.keyboardType,
    this.minLines = 1,
    this.maxLines = 1,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? placeholder;
  final bool required;
  final String? errorText;
  final bool autofocus;
  final TextInputType? keyboardType;
  final int minLines;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  State<LokiUnderlineField> createState() => _LokiUnderlineFieldState();
}

class _LokiUnderlineFieldState extends State<LokiUnderlineField> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted && _focused != _focusNode.hasFocus) {
        setState(() => _focused = _focusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colors(context);
    final hasError = widget.errorText != null;
    final lineColor = hasError
        ? c.danger
        : _focused
        ? c.primary
        : c.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: widget.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: hasError ? c.danger : c.textSecondary,
            ),
            children: widget.required
                ? [
                    TextSpan(
                      text: '*',
                      style: TextStyle(
                        color: c.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 6),
        CupertinoTextField(
          controller: widget.controller,
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          keyboardType: widget.keyboardType,
          minLines: widget.minLines,
          maxLines: widget.maxLines,
          placeholder: widget.placeholder,
          placeholderStyle: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w400,
            color: c.textSecondary.withValues(alpha: 0.65),
          ),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: c.textPrimary,
          ),
          padding: const EdgeInsets.only(top: 2, bottom: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: lineColor,
                width: _focused || hasError ? 1.6 : 1,
              ),
            ),
          ),
          onChanged: widget.onChanged,
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              widget.errorText!,
              style: TextStyle(
                color: c.danger,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

/// Pinned bottom CTA bar with subtle top divider matching scaffold background.
class LokiBottomCtaBar extends StatelessWidget {
  const LokiBottomCtaBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colors(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: c.background,
        border: Border(top: BorderSide(color: c.border, width: 0.8)),
      ),
      child: child,
    );
  }
}
