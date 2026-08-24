import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../providers/social_feed_provider.dart';

class ComposeCommunityPostScreen extends ConsumerStatefulWidget {
  const ComposeCommunityPostScreen({super.key, this.isQuestion = false});

  final bool isQuestion;

  @override
  ConsumerState<ComposeCommunityPostScreen> createState() =>
      _ComposeCommunityPostScreenState();
}

class _ComposeCommunityPostScreenState
    extends ConsumerState<ComposeCommunityPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String? _categoryId;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _categoryId == null) return;
    setState(() => _submitting = true);
    final success = await ref
        .read(socialFeedProvider.notifier)
        .createPost(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          categoryId: _categoryId!,
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (success) {
      Navigator.of(context).pop(true);
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.publishFailed)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final feed = ref.watch(socialFeedProvider);
    final categories = feed is SocialFeedLoaded ? feed.categories : const [];
    _categoryId ??= categories.firstOrNull?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isQuestion ? l10n.askCommunity : l10n.createPost),
      ),
      body: Stack(
        children: [
          Positioned(
            right: -90,
            top: -70,
            child: _AmbientOrb(
              color: AppColors.brandPrimaryHover.withValues(alpha: .16),
              size: 240,
            ),
          ),
          Positioned(
            left: -80,
            bottom: -70,
            child: _AmbientOrb(
              color: AppColors.brandAccent.withValues(alpha: .14),
              size: 220,
            ),
          ),
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
              child: ClipRRect(
                borderRadius: AppRadii.largeBorder,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: .78),
                      borderRadius: AppRadii.largeBorder,
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: .65,
                        ),
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF34443A), Color(0xFF5E7164)],
                              ),
                              borderRadius: AppRadii.mediumBorder,
                            ),
                            child: Icon(
                              widget.isQuestion
                                  ? Icons.help_outline_rounded
                                  : Icons.edit_note_rounded,
                              color: Colors.white,
                              size: 27,
                            ),
                          ),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<String>(
                            initialValue: _categoryId,
                            items: [
                              for (final category in categories)
                                DropdownMenuItem(
                                  value: category.id,
                                  child: Text(category.name),
                                ),
                            ],
                            onChanged: _submitting
                                ? null
                                : (value) =>
                                      setState(() => _categoryId = value),
                            decoration: InputDecoration(
                              labelText: l10n.chooseCommunity,
                              prefixIcon: const Icon(Icons.groups_2_outlined),
                            ),
                            validator: (_) => _categoryId == null
                                ? l10n.chooseCommunity
                                : null,
                          ),
                          if (categories.isEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              l10n.noCommunities,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _titleController,
                            enabled: !_submitting,
                            maxLength: 200,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              labelText: widget.isQuestion
                                  ? l10n.questionTitleLabel
                                  : l10n.postTitleLabel,
                              prefixIcon: const Icon(Icons.title_rounded),
                            ),
                            validator: (value) =>
                                value == null || value.trim().length < 4
                                ? (widget.isQuestion
                                      ? l10n.questionTitleLabel
                                      : l10n.postTitleLabel)
                                : null,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _contentController,
                            enabled: !_submitting,
                            minLines: 6,
                            maxLines: 10,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              labelText: l10n.detailsLabel,
                              alignLabelWithHint: true,
                            ),
                            validator: (value) =>
                                value == null || value.trim().length < 10
                                ? l10n.detailsLabel
                                : null,
                          ),
                          const SizedBox(height: 22),
                          FilledButton.icon(
                            onPressed: _submitting || categories.isEmpty
                                ? null
                                : _submit,
                            icon: _submitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.arrow_upward_rounded),
                            label: Text(l10n.publish),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  const _AmbientOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
