import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'riksa_brand.dart';
import 'riksa_interactions.dart';

export 'riksa_interactions.dart';

enum RiksaPastelTone { jade, saffron, blush, cream, surface }

Color riksaPastelColor(BuildContext context, RiksaPastelTone tone) {
  final palette = context.riksa;
  return switch (tone) {
    RiksaPastelTone.jade => palette.jadeSoft,
    RiksaPastelTone.saffron => palette.saffronSoft,
    RiksaPastelTone.blush => palette.blushSoft,
    RiksaPastelTone.cream => palette.creamSoft,
    RiksaPastelTone.surface => palette.surface,
  };
}

class RiksaSearchField extends StatelessWidget {
  const RiksaSearchField({
    super.key,
    required this.hintText,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.trailing,
  });

  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    textInputAction: TextInputAction.search,
    decoration: InputDecoration(
      hintText: hintText,
      prefixIcon: const Icon(Icons.search_rounded),
      suffixIcon: trailing,
      filled: true,
      fillColor: context.riksa.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: RiksaSpacing.md),
      border: OutlineInputBorder(
        borderRadius: AppRadii.fullBorder,
        borderSide: BorderSide(color: context.riksa.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadii.fullBorder,
        borderSide: BorderSide(color: context.riksa.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadii.fullBorder,
        borderSide: BorderSide(color: context.riksa.brand, width: 1.5),
      ),
    ),
  );
}

class RiksaPastelCard extends StatelessWidget {
  const RiksaPastelCard({
    super.key,
    required this.child,
    this.tone = RiksaPastelTone.surface,
    this.padding = const EdgeInsets.all(RiksaSpacing.md),
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final RiksaPastelTone tone;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return Semantics(
      container: true,
      button: onTap != null,
      label: semanticLabel,
      child: RiksaTapFeedback(
        enabled: onTap != null,
        child: Material(
          color: riksaPastelColor(context, tone),
          borderRadius: AppRadii.extraLargeBorder,
          clipBehavior: Clip.antiAlias,
          child: onTap == null
              ? content
              : InkWell(
                  onTap: onTap,
                  borderRadius: AppRadii.extraLargeBorder,
                  child: content,
                ),
        ),
      ),
    );
  }
}

class RiksaStateView extends StatelessWidget {
  const RiksaStateView({
    super.key,
    required this.title,
    required this.body,
    this.icon = Icons.auto_stories_outlined,
    this.actionLabel,
    this.onAction,
    this.loading = false,
  });

  final String title;
  final String body;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool loading;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Padding(
        padding: const EdgeInsets.all(RiksaSpacing.md),
        child: RiksaPastelCard(
          tone: RiksaPastelTone.surface,
          padding: const EdgeInsets.all(RiksaSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                const SizedBox.square(
                  dimension: 36,
                  child: CircularProgressIndicator(strokeWidth: 3),
                )
              else
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: context.riksa.brandSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 34, color: context.riksa.brand),
                ),
              const SizedBox(height: RiksaSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: RiksaSpacing.xs),
              Text(
                body,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: RiksaSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class RiksaPageHeader extends StatelessWidget {
  const RiksaPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        RiksaSpacing.md,
        RiksaSpacing.sm,
        RiksaSpacing.md,
        RiksaSpacing.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: RiksaSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: RiksaSpacing.xxs),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: RiksaSpacing.sm),
            trailing!,
          ],
        ],
      ),
    ),
  );
}

class RiksaSkeleton extends StatefulWidget {
  const RiksaSkeleton({
    super.key,
    this.height = 16,
    this.width = double.infinity,
    this.radius = AppRadii.small,
  });
  final double height;
  final double width;
  final double radius;

  @override
  State<RiksaSkeleton> createState() => _RiksaSkeletonState();
}

class _RiksaSkeletonState extends State<RiksaSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: RiksaMotion.emphasis,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disabled = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disabled) {
      _controller
        ..stop()
        ..value = .5;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) => Opacity(
      opacity: .45 + (_controller.value * .35),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: context.riksa.outline,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    ),
  );
}

class LessonCardSkeleton extends StatelessWidget {
  const LessonCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.riksa.surface,
      borderRadius: AppRadii.largeBorder,
    ),
    child: const Padding(
      padding: EdgeInsets.all(RiksaSpacing.md),
      child: Row(
        children: [
          RiksaSkeleton(width: 70, height: 70, radius: AppRadii.medium),
          SizedBox(width: RiksaSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RiksaSkeleton(width: 88, height: 10),
                SizedBox(height: RiksaSpacing.xs),
                RiksaSkeleton(height: 18),
                SizedBox(height: RiksaSpacing.xs),
                RiksaSkeleton(width: 170, height: 12),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class IllustratedEmptyState extends StatelessWidget {
  const IllustratedEmptyState({
    super.key,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(RiksaSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const RiksaContentReveal(
              identity: 'empty-artwork',
              child: RiksaEmptyArtwork(),
            ),
            const SizedBox(height: RiksaSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: RiksaTypography.titleStyleFor(
                title,
                Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: RiksaSpacing.xs),
            Text(
              body,
              textAlign: TextAlign.center,
              style: RiksaTypography.bodyStyleFor(
                body,
                Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.riksa.inkMuted,
                  height: 1.6,
                ),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: RiksaSpacing.md),
              RiksaTapFeedback(
                child: FilledButton(
                  onPressed: onAction,
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 54)),
                  child: Text(actionLabel!),
                ),
              ),
            ],
            if (secondaryLabel != null && onSecondary != null) ...[
              const SizedBox(height: RiksaSpacing.xs),
              TextButton(
                onPressed: onSecondary,
                style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
                child: Text(secondaryLabel!),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

/// A number that counts up to its value the first time it is shown.
///
/// Progress the learner earned should arrive, not appear. A rank that is simply
/// painted at #3 reads as a fact about the database; a rank that climbs to #3
/// reads as something they did.
///
/// Assistive technology is given the final value only: announcing every
/// interpolated frame would be noise.
class RiksaCountUp extends StatelessWidget {
  const RiksaCountUp({
    super.key,
    required this.value,
    required this.format,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.duration,
  });

  final int value;

  /// Renders one frame of the count. Called with interpolated values, so keep
  /// it cheap and free of side effects.
  final String Function(int) format;

  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final Duration? duration;

  @override
  Widget build(BuildContext context) {
    final label = format(value);
    Widget text(String data) => Text(
      data,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );

    final resolved = RiksaMotion.resolve(
      context,
      duration ?? RiksaMotion.emphasisLong,
    );
    if (resolved == Duration.zero) return text(label);

    return Semantics(
      label: label,
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        // A begin is what makes this animate on first paint. Without it the
        // builder starts at the end value and only moves on later changes,
        // which is exactly the inert case this widget exists to fix.
        tween: Tween<double>(begin: 0, end: value.toDouble()),
        duration: resolved,
        curve: RiksaMotion.standardCurve,
        builder: (context, animated, _) => text(format(animated.round())),
      ),
    );
  }
}

/// Fades and lifts one row into place, offset by its position in the list.
///
/// [index] is the row's position, and the delay is capped so a long list still
/// finishes assembling promptly instead of trickling in for a second.
class RiksaEntrance extends StatefulWidget {
  const RiksaEntrance({
    super.key,
    required this.index,
    required this.child,
    this.rise = 12,
  });

  final int index;
  final Widget child;

  /// How far the row travels up into position, in logical pixels.
  final double rise;

  /// Rows past this position all start together.
  static const maxStaggered = 8;

  @override
  State<RiksaEntrance> createState() => _RiksaEntranceState();
}

class _RiksaEntranceState extends State<RiksaEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    final delay =
        RiksaMotion.stagger * widget.index.clamp(0, RiksaEntrance.maxStaggered);
    final total = delay + RiksaMotion.standard;
    _controller = AnimationController(vsync: this, duration: total);
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: RiksaMotion.standardCurve,
      ),
    );
    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Honoured here rather than by skipping the widget, so a learner who turns
    // reduced motion on mid-session still lands on the finished layout.
    if (MediaQuery.disableAnimationsOf(context)) _controller.value = 1;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _progress,
    builder: (context, child) {
      // Once the row has landed it is handed back unwrapped. Opacity composites
      // through a saveLayer even at 1.0, and a feed of fifty posts should not
      // carry fifty of those for the rest of the session on a cheap phone.
      if (_progress.isCompleted) return child!;
      return Opacity(
        opacity: _progress.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _progress.value) * widget.rise),
          child: child,
        ),
      );
    },
    child: widget.child,
  );
}

/// Riksa's empty-state motif: an open book, a tucked-in bookmark and two
/// small sparkles. Vector shapes stay sharp without an image download.
/// The mascot on a lavender blob with a couple of sparks: the illustration
/// for every empty state.
class RiksaEmptyArtwork extends StatelessWidget {
  const RiksaEmptyArtwork({super.key});
  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    return ExcludeSemantics(
      child: SizedBox(
        width: 156,
        height: 132,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 132,
              height: 112,
              decoration: BoxDecoration(
                color: palette.brandSoft,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(56),
                  topRight: Radius.circular(40),
                  bottomLeft: Radius.circular(44),
                  bottomRight: Radius.circular(60),
                ),
              ),
            ),
            const RiksaMascot(size: 104),
            Positioned(
              right: 4,
              top: 6,
              child: RiksaDoodle(
                RiksaDoodleKind.star,
                size: 22,
                color: palette.brand,
              ),
            ),
            const Positioned(
              left: 0,
              bottom: 16,
              child: RiksaDoodle(
                RiksaDoodleKind.squiggle,
                size: 24,
                color: AppColors.lime,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
