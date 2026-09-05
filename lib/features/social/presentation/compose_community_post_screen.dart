import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/social_api.dart';
import '../data/social_models.dart';
import '../providers/social_feed_provider.dart';
import 'widgets/social_palette.dart';

/// Writes a community post, or rewrites one the reader already owns.
///
/// In edit mode the community is fixed: moving a post would also have to
/// satisfy the join-before-posting rule the backend enforces on create.
class ComposeCommunityPostScreen extends ConsumerStatefulWidget {
  const ComposeCommunityPostScreen({
    super.key,
    this.isQuestion = false,
    this.post,
  });

  final bool isQuestion;

  /// The post being rewritten. Null starts a new one.
  final SocialPost? post;

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

  SocialPost? get _original => widget.post;
  bool get _isEditing => _original != null;

  @override
  void initState() {
    super.initState();
    final post = _original;
    if (post != null) {
      _titleController.text = post.title;
      _contentController.text = post.markdownContent;
      _categoryId = post.category.id;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _categoryId == null) return;
    setState(() => _submitting = true);
    final notifier = ref.read(socialFeedProvider.notifier);
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final editing = _original;

    final String? failure;
    if (editing == null) {
      final created = await notifier.createPost(
        title: title,
        content: content,
        categoryId: _categoryId!,
      );
      failure = created ? null : _publishFailure();
    } else {
      failure = await notifier.updatePost(
        id: editing.id,
        title: title,
        content: content,
      );
    }

    if (!mounted) return;
    setState(() => _submitting = false);
    if (failure == null) {
      Navigator.of(context).pop(true);
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(failure)));
  }

  String _publishFailure() => AppLocalizations.of(context)!.publishFailed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final feed = ref.watch(socialFeedProvider);
    final categories = feed is SocialFeedLoaded
        ? feed.categories
        : const <SocialCategory>[];
    _categoryId ??= _original?.category.id ?? categories.firstOrNull?.id;
    // An edited post keeps its own community even when the feed's category
    // list has not loaded, or no longer contains it.
    final editCategory = _original?.category;
    final options = <SocialCategory>[
      ...categories,
      if (editCategory != null &&
          !categories.any((item) => item.id == editCategory.id))
        editCategory,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? l10n.editPost
              : widget.isQuestion
              ? l10n.askCommunity
              : l10n.createPost,
        ),
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
                              _isEditing
                                  ? Icons.edit_outlined
                                  : widget.isQuestion
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
                              for (final category in options)
                                DropdownMenuItem(
                                  value: category.id,
                                  child: Text(category.name),
                                ),
                            ],
                            // A post keeps the community it was written in.
                            onChanged: _submitting || _isEditing
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
                          if (categories.isEmpty && !_isEditing) ...[
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
                            onPressed:
                                _submitting ||
                                    (categories.isEmpty && !_isEditing)
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
                            label: Text(
                              _isEditing ? l10n.saveChanges : l10n.publish,
                            ),
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

/// Route target for `/community/posts/:id/edit`.
///
/// In-app navigation hands the post over through `extra`; a cold deep link
/// has to fetch it before the composer has anything to prefill.
class SocialPostEditScreen extends ConsumerStatefulWidget {
  const SocialPostEditScreen({super.key, required this.id, this.post});

  final String id;
  final SocialPost? post;

  @override
  ConsumerState<SocialPostEditScreen> createState() =>
      _SocialPostEditScreenState();
}

class _SocialPostEditScreenState extends ConsumerState<SocialPostEditScreen> {
  SocialPost? _post;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    if (_post == null) unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final post = await ref.read(socialApiProvider).post(widget.id);
      if (!mounted) return;
      setState(() {
        _post = post;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is SocialApiException ? error.message : null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = _post;
    if (post != null) return ComposeCommunityPostScreen(post: post);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: SocialPalette.canvas(context),
      appBar: AppBar(
        backgroundColor: SocialPalette.canvas(context),
        foregroundColor: SocialPalette.aubergine(context),
        surfaceTintColor: Colors.transparent,
        title: Text(
          l10n.editPost,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator(color: AppColors.editorialPink)
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error ?? l10n.actionFailed,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: SocialPalette.muted(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _load,
                      child: Text(l10n.tryAgain),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
