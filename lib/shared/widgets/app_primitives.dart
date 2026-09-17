import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_extras.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
    this.tone = AppButtonTone.primary,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final AppButtonTone tone;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final (bg, fg) = switch (tone) {
      AppButtonTone.primary => (palette.accent, palette.onAccent),
      AppButtonTone.secondary => (palette.elevated, palette.textPrimary),
      AppButtonTone.ghost => (Colors.transparent, palette.accent),
    };
    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: onPressed == null ? palette.textMuted : fg),
          ),
        ),
      ],
    );
    return Material(
      color: onPressed == null ? palette.elevated : bg,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          width: expand ? double.infinity : null,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: compact ? 8 : 12,
          ),
          decoration: tone == AppButtonTone.secondary
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: palette.border),
                )
              : null,
          child: child,
        ),
      ),
    );
  }
}

enum AppButtonTone { primary, secondary, ghost }

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.accent,
    this.filled = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? accent;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: filled ? palette.elevated : palette.card,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: accent ?? palette.border.withValues(alpha: 0.65),
            ),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

class AppProgressBar extends StatelessWidget {
  const AppProgressBar({super.key, required this.value, this.color});

  final double value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: 8,
        backgroundColor: palette.input,
        color: color ?? (value >= 1 ? palette.success : palette.accent),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? 0.14 : 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: dark ? 0.45 : 0.85)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: palette.textMuted),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.label = 'Loading'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: context.palette.accent,
            ),
          ),
          const SizedBox(height: 12),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              color: context.palette.danger,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              AppButton(label: 'Try again', onPressed: onRetry),
            ],
          ],
        ),
      ),
    );
  }
}

class MonoChip extends StatelessWidget {
  const MonoChip({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.palette.elevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.palette.border),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class CodeBlock extends StatefulWidget {
  const CodeBlock({
    super.key,
    required this.code,
    required this.languageLabel,
    this.output,
    this.onRun,
    this.onReset,
    this.editable = false,
    this.onChanged,
  });

  final String code;
  final String languageLabel;
  final String? output;
  final ValueChanged<String>? onRun;
  final VoidCallback? onReset;
  final bool editable;
  final ValueChanged<String>? onChanged;

  @override
  State<CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<CodeBlock> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.code);
  }

  @override
  void didUpdateWidget(covariant CodeBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.code != widget.code && _controller.text != widget.code) {
      _controller.text = widget.code;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final lines = _controller.text.split('\n');
    return Container(
      decoration: BoxDecoration(
        color: palette.code,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
            child: Row(
              children: [
                Text(
                  widget.languageLabel.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: palette.onCode),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Copy',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _controller.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copied')),
                    );
                  },
                  icon: Icon(
                    Icons.copy_rounded,
                    size: 16,
                    color: palette.onCode,
                  ),
                ),
                if (widget.onReset != null)
                  IconButton(
                    tooltip: 'Reset',
                    visualDensity: VisualDensity.compact,
                    onPressed: widget.onReset,
                    icon: Icon(
                      Icons.restart_alt,
                      size: 16,
                      color: palette.onCode,
                    ),
                  ),
                if (widget.onRun != null)
                  TextButton.icon(
                    onPressed: () => widget.onRun!(_controller.text),
                    style: TextButton.styleFrom(
                      foregroundColor: palette.codeAccent,
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Run'),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: palette.border),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    for (var i = 1; i <= lines.length; i++)
                      SizedBox(
                        height: 20,
                        child: Text(
                          '$i',
                          style: AppTypography.mono(
                            palette.onCode.withValues(alpha: 0.45),
                            size: 11,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: widget.editable
                      ? TextField(
                          controller: _controller,
                          onChanged: widget.onChanged,
                          maxLines: null,
                          style: AppTypography.mono(
                            palette.codeAccent,
                            size: 12,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                          ),
                        )
                      : SelectableText(
                          widget.code,
                          style: AppTypography.mono(
                            palette.codeAccent,
                            size: 12,
                          ),
                        ),
                ),
              ],
            ),
          ),
          if (widget.output != null) ...[
            Divider(height: 1, color: palette.border),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'OUTPUT',
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: palette.onCode),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.output!,
                    style: AppTypography.mono(palette.onCode, size: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shared editorial heading for a screen or detail page.
class PageHeading extends StatelessWidget {
  const PageHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    this.icon,
  });
  final String eyebrow;
  final String title;
  final String description;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: context.palette.accent),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  eyebrow.toUpperCase(),
                  style: type.labelSmall?.copyWith(
                    color: context.palette.accent,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: type.headlineLarge?.copyWith(letterSpacing: -0.8)),
          const SizedBox(height: 10),
          Text(description, style: type.bodyMedium),
        ],
      ),
    );
  }
}

class FeaturePanel extends StatelessWidget {
  const FeaturePanel({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          context.palette.accent.withValues(alpha: 0.14),
          context.palette.card,
          context.palette.violet.withValues(alpha: 0.07),
        ],
      ),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: context.palette.accent.withValues(alpha: 0.25)),
    ),
    child: child,
  );
}

/// Keeps reading lines comfortable on tablets and desktop.
EdgeInsets pageInsets(
  BuildContext context, {
  double top = 12,
  double bottom = 40,
}) {
  final width = MediaQuery.sizeOf(context).width;
  final side = width > 840 ? (width - 800) / 2 : 20.0;
  return EdgeInsets.fromLTRB(side, top, side, bottom);
}
