import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/moderation_error.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/image_source_sheet.dart';
import '../../../core/widgets/riksa_avatar_image.dart';
import '../../../core/widgets/riksa_back_button.dart';
import '../../../core/widgets/moderation_message.dart';
import '../../../core/widgets/unsaved_changes_guard.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/data/auth_api.dart';
import '../../auth/providers/auth_provider.dart';
import '../../social/data/social_api.dart';
import '../../social/providers/social_feed_provider.dart';
import '../data/blog_api.dart';
import '../data/blog_models.dart';
import '../providers/blog_provider.dart';
import 'widgets/blog_ui.dart';
import 'widgets/markdown_toolbar.dart';

/// Composer for writing a post and for editing one the user already owns.
///
/// Writing comes first: the title and body are plain text on the sheet with
/// no field chrome, and everything else (topic, cover, length) lives in a
/// single footer bar above the keyboard.
///
/// Pops `true` when the feed behind it should reload.
class BlogComposerScreen extends ConsumerStatefulWidget {
  const BlogComposerScreen({super.key, this.post, this.imagePicker});

  /// The post being rewritten. Null starts a new draft.
  final BlogPost? post;

  /// Injectable to exercise the cover photo flow in widget tests.
  final ImagePicker? imagePicker;

  @override
  ConsumerState<BlogComposerScreen> createState() => _BlogComposerScreenState();
}

class _BlogComposerScreenState extends ConsumerState<BlogComposerScreen> {
  static const int _titleLimit = 200;

  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _coverCtrl = TextEditingController();
  final _contentFocus = FocusNode();
  String? _categoryId;
  bool _showCoverField = false;
  bool _uploadingCover = false;
  bool _submitting = false;
  bool _submitted = false;
  BlogStatus? _submittedStatus;
  String? _submittedPostId;
  bool _previewing = false;

  BlogPost? get _original => widget.post;
  bool get _isEditing => _original != null;

  @override
  void initState() {
    super.initState();
    final post = _original;
    if (post != null) {
      _titleCtrl.text = post.title;
      _contentCtrl.text = post.markdownContent;
      _coverCtrl.text = post.coverUrl ?? '';
      _categoryId = post.categoryId;
      _showCoverField = post.hasCover;
    }
    _titleCtrl.addListener(_onChanged);
    _contentCtrl.addListener(_onChanged);
    _coverCtrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _coverCtrl.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  /// Rewrites the body around the current selection and hands focus back so
  /// the writer can keep typing where the markup left the caret.
  void _format(BlogMarkdownAction action) {
    _contentCtrl.value = applyBlogMarkdown(_contentCtrl.value, action);
    if (!_contentFocus.hasFocus) _contentFocus.requestFocus();
  }

  void _onChanged() => setState(() {});

  String get _title => _titleCtrl.text.trim();
  String get _content => _contentCtrl.text.trim();
  String get _cover => _coverCtrl.text.trim();

  bool get _canSubmit =>
      !_submitting &&
      !_uploadingCover &&
      _title.isNotEmpty &&
      _title.length <= _titleLimit &&
      _content.isNotEmpty &&
      _categoryId != null &&
      _cover.length <= 2000 &&
      (!_isEditing || _isDirty);

  /// True when the draft differs from what the server currently holds.
  bool get _isDirty {
    final post = _original;
    if (post == null) {
      return _title.isNotEmpty || _content.isNotEmpty || _cover.isNotEmpty;
    }
    return _title != post.title ||
        _content != post.markdownContent.trim() ||
        _cover != (post.coverUrl ?? '') ||
        _categoryId != post.categoryId;
  }

  /// Picks a cover from the gallery or camera, uploads it, and puts the
  /// uploaded link in the cover field.
  Future<void> _pickCover() async {
    if (_uploadingCover || _submitting) return;
    final l10n = AppLocalizations.of(context)!;
    final source = await showImageSourceSheet(context);
    if (source == null || !mounted) return;
    final XFile? photo;
    try {
      photo = await (widget.imagePicker ?? ImagePicker()).pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
    } catch (_) {
      _showCoverError(l10n.postPhotosUploadFailed);
      return;
    }
    if (photo == null || !mounted) return;
    setState(() => _uploadingCover = true);
    try {
      final media = await ref
          .read(socialApiProvider)
          .uploadMedia(photo.path, filename: photo.name);
      if (!mounted) return;
      setState(() {
        _coverCtrl.text = media.url;
        _showCoverField = true;
      });
    } catch (error) {
      _showCoverError(
        error is SocialApiException
            ? error.message
            : l10n.postPhotosUploadFailed,
      );
    } finally {
      if (mounted) setState(() => _uploadingCover = false);
    }
  }

  void _showCoverError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _submitting = true);
    final request = BlogPostRequest(
      title: _title,
      content: _content,
      coverUrl: _cover.isEmpty ? null : _cover,
      categoryId: _categoryId!,
    );
    final api = ref.read(blogApiProvider);
    final editing = _original;
    try {
      final saved = editing == null
          ? await api.createPost(request)
          : await api.updatePost(editing.id, request);
      if (!mounted) return;
      if (editing != null) {
        ref.read(blogFeedProvider.notifier).applyUpdate(saved);
      }
      setState(() {
        _submitting = false;
        _submitted = true;
        _submittedStatus = saved.status;
        _submittedPostId = saved.id;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      final rejection = fromDio(e);
      if (rejection != null) {
        _showError(moderationMessage(context, rejection));
      } else if (editing == null) {
        _showError(dioErrorMessage(e));
      } else {
        _showError(
          blogOwnerActionError(
            e,
            BlogOwnerAction.edit,
            l10n: AppLocalizations.of(context)!,
          ),
        );
      }
    } catch (_) {
      _showError(AppLocalizations.of(context)!.blogSomethingWentWrong);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickCategory() async {
    final l10n = AppLocalizations.of(context)!;
    final topics = ref.read(blogCategoriesProvider);
    final categories = topics.value;
    if (categories == null || categories.isEmpty) {
      if (topics.isLoading) {
        _showMessage(l10n.blogTopicsLoading);
      } else if (topics.hasError) {
        // The draft stays put; retrying only refetches the topic list.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.blogTopicsFailed),
            action: SnackBarAction(
              label: l10n.tryAgain,
              onPressed: () => ref.invalidate(blogCategoriesProvider),
            ),
          ),
        );
      } else {
        _showMessage(l10n.blogTopicsEmpty);
      }
      return;
    }
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) =>
          _TopicSheet(categories: categories, selectedId: _categoryId),
    );
    if (picked != null && mounted) setState(() => _categoryId = picked);
  }

  @override
  Widget build(BuildContext context) {
    return UnsavedChangesGuard(
      dirty: !_submitted && _isDirty,
      busy: _submitting,
      fallbackLocation: _isEditing
          ? '/blog/${Uri.encodeComponent(_original!.id)}'
          : '/blog',
      child: Scaffold(
        backgroundColor: blogSheetColor(context),
        body: SafeArea(
          child: _submitted
              ? _submittedStatus == BlogStatus.approved
                    ? _buildPublished()
                    : _buildPendingReview()
              : _buildComposer(),
        ),
      ),
    );
  }

  Widget _buildPublished() {
    final l10n = AppLocalizations.of(context)!;
    return BlogNotice(
      title: l10n.moderationPublishedTitle,
      body: l10n.moderationPublishedBody,
      icon: Icons.check_circle_outline_rounded,
      actionLabel: l10n.moderationPublishedOpenPost,
      onAction: () =>
          context.push('/blog/${Uri.encodeComponent(_submittedPostId ?? '')}'),
      secondaryLabel: l10n.blogDone,
      onSecondary: () => RiksaBackButton.navigateBack(
        context,
        fallbackLocation: '/blog',
        result: true,
        saved: true,
      ),
    );
  }

  Widget _buildPendingReview() {
    final l10n = AppLocalizations.of(context)!;
    return BlogNotice(
      title: _isEditing
          ? l10n.blogReviewBackTitle
          : l10n.blogReviewPendingTitle,
      body: _isEditing ? l10n.blogReviewBackBody : l10n.blogReviewSubmittedBody,
      icon: Icons.hourglass_top_rounded,
      actionLabel: l10n.blogDone,
      onAction: () => RiksaBackButton.navigateBack(
        context,
        fallbackLocation: '/blog',
        result: true,
      ),
      // The copy above points at Your posts, so give it somewhere to point.
      secondaryLabel: l10n.blogYourPosts,
      onSecondary: () {
        final hasPreviousPage =
            Navigator.of(context).canPop() ||
            (GoRouter.maybeOf(context)?.canPop() ?? false);
        if (hasPreviousPage) {
          context.pushReplacement('/blog/my-posts');
        } else {
          context.go('/blog/my-posts');
        }
      },
    );
  }

  /// Close goes through the same guard as the system back gesture.
  void _cancel() {
    if (_submitting) return;
    unawaited(
      RiksaBackButton.navigateBack(
        context,
        fallbackLocation: _isEditing
            ? '/blog/${Uri.encodeComponent(_original!.id)}'
            : '/blog',
        result: false,
        confirmFallback: (context) async =>
            !_isDirty || await confirmDiscardChanges(context),
      ),
    );
  }

  Widget _buildComposer() {
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.watch(authProvider);
    final user = auth is Authenticated ? auth.user : null;
    // Watched here so the topic list is already in flight by the time the
    // writer reaches for the footer chip.
    final categories = ref.watch(blogCategoriesProvider).value;
    final selected = _selectedCategory(categories);

    return Column(
      children: [
        _ComposerBar(
          label: _isEditing ? l10n.blogSave : l10n.blogPublish,
          canSubmit: _canSubmit,
          submitting: _submitting,
          previewing: _previewing,
          canPreview: _content.isNotEmpty,
          onTogglePreview: () => setState(() => _previewing = !_previewing),
          onCancel: _cancel,
          onSubmit: _submit,
        ),
        const BlogDivider(),
        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              BlogMetrics.gutter,
              RiksaSpacing.md,
              BlogMetrics.gutter,
              RiksaSpacing.lg,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RiksaAvatarImage(
                  value: user?.avatarUrl,
                  label: user?.displayName.isNotEmpty ?? false
                      ? user!.displayName
                      : (user?.username ?? 'R'),
                  size: BlogMetrics.rowAvatar,
                  backgroundColor: blogAvatarBackground(context),
                  foregroundColor: blogAvatarForeground(context),
                ),
                const SizedBox(width: 12),
                Expanded(child: _previewing ? _buildPreview() : _buildFields()),
              ],
            ),
          ),
        ),
        if (!_previewing) ...[
          const BlogDivider(),
          BlogMarkdownToolbar(onAction: _format),
        ],
        _ComposerFooter(
          categoryLabel: selected?.name,
          hasCategory: _categoryId != null,
          coverActive: _showCoverField || _cover.isNotEmpty,
          titleLength: _titleCtrl.text.characters.length,
          titleLimit: _titleLimit,
          onPickCategory: _pickCategory,
          onToggleCover: () =>
              setState(() => _showCoverField = !_showCoverField),
        ),
      ],
    );
  }

  BlogCategory? _selectedCategory(List<BlogCategory>? categories) {
    final id = _categoryId;
    if (id == null || categories == null) return null;
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  /// The draft as readers will meet it, rendered by the same markdown
  /// pipeline the detail screen uses.
  Widget _buildPreview() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = context.riksa;
    final content = normalizeBlogMarkdown(_contentCtrl.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_title.isNotEmpty) ...[
          Text(
            _title,
            style: RiksaTypography.titleStyleFor(
              _title,
              theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.25,
                letterSpacing: 0,
                color: palette.ink,
              ),
            ),
          ),
          const SizedBox(height: RiksaSpacing.sm),
        ],
        if (_cover.isNotEmpty) ...[
          BlogCoverImage(url: _cover),
          const SizedBox(height: RiksaSpacing.sm),
        ],
        if (content.trim().isEmpty)
          Text(
            l10n.blogNothingToPreview,
            style: theme.textTheme.bodyLarge?.copyWith(color: palette.inkFaint),
          )
        else
          MarkdownBody(
            key: const ValueKey('blog-composer-preview'),
            data: content,
            selectable: false,
            styleSheet: blogMarkdownStyleSheet(context, content),
          ),
      ],
    );
  }

  Widget _buildFields() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = context.riksa;
    final showCover = _showCoverField || _cover.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _titleCtrl,
          // A new draft starts in the title; an edit shows the post first.
          autofocus: !_isEditing,
          maxLength: _titleLimit,
          maxLines: null,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          style: RiksaTypography.titleStyleFor(
            _titleCtrl.text,
            theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.25,
              letterSpacing: 0,
            ),
          ),
          decoration: _bareField(
            context,
            l10n.blogTitleHint,
            hintStyle: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.25,
              letterSpacing: 0,
              color: palette.inkFaint,
            ),
          ),
        ),
        const SizedBox(height: RiksaSpacing.xs),
        TextField(
          controller: _contentCtrl,
          focusNode: _contentFocus,
          minLines: 8,
          maxLines: null,
          textCapitalization: TextCapitalization.sentences,
          keyboardType: TextInputType.multiline,
          style: RiksaTypography.bodyStyleFor(
            _contentCtrl.text,
            theme.textTheme.bodyLarge?.copyWith(fontSize: 15, height: 1.6),
          ),
          decoration: _bareField(
            context,
            l10n.blogBodyHint,
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 15,
              height: 1.7,
              color: palette.inkFaint,
            ),
          ),
        ),
        if (showCover) ...[
          const SizedBox(height: RiksaSpacing.md),
          Row(
            children: [
              Icon(Icons.link_rounded, size: 18, color: palette.inkMuted),
              const SizedBox(width: RiksaSpacing.xs),
              Expanded(
                child: TextField(
                  controller: _coverCtrl,
                  keyboardType: TextInputType.url,
                  style: theme.textTheme.bodyMedium,
                  decoration: _bareField(
                    context,
                    AppLocalizations.of(context)!.blogCoverUrlLabel,
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: palette.inkFaint,
                    ),
                  ),
                ),
              ),
              if (_uploadingCover)
                Padding(
                  padding: const EdgeInsets.all(RiksaSpacing.sm),
                  child: SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      semanticsLabel: l10n.photoUploading,
                    ),
                  ),
                )
              else
                IconButton(
                  key: const ValueKey('blog-cover-upload'),
                  onPressed: _pickCover,
                  tooltip: l10n.addPhoto,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: palette.inkMuted,
                  ),
                  icon: const Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 20,
                  ),
                ),
              if (_cover.isNotEmpty && !_uploadingCover)
                IconButton(
                  onPressed: () => setState(() {
                    _coverCtrl.clear();
                    _showCoverField = false;
                  }),
                  tooltip: AppLocalizations.of(context)!.blogRemoveCover,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: palette.inkMuted,
                  ),
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
            ],
          ),
          if (_cover.isNotEmpty) ...[
            const SizedBox(height: RiksaSpacing.sm),
            BlogCoverImage(url: _cover),
          ],
        ],
      ],
    );
  }
}

/// Field with no chrome: the sheet itself is the writing surface.
InputDecoration _bareField(
  BuildContext context,
  String hint, {
  TextStyle? hintStyle,
}) => InputDecoration(
  hintText: hint,
  hintStyle: hintStyle,
  filled: false,
  isDense: true,
  counterText: '',
  contentPadding: EdgeInsets.zero,
  border: InputBorder.none,
  enabledBorder: InputBorder.none,
  focusedBorder: InputBorder.none,
);

class _ComposerBar extends StatelessWidget {
  const _ComposerBar({
    required this.label,
    required this.canSubmit,
    required this.submitting,
    required this.previewing,
    required this.canPreview,
    required this.onTogglePreview,
    required this.onCancel,
    required this.onSubmit,
  });

  final String label;
  final bool canSubmit;
  final bool submitting;
  final bool previewing;
  final bool canPreview;
  final VoidCallback onTogglePreview;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: RiksaSpacing.xs),
        child: Row(
          children: [
            TextButton(
              onPressed: submitting ? null : onCancel,
              style: TextButton.styleFrom(foregroundColor: context.riksa.ink),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            const Spacer(),
            IconButton(
              key: const ValueKey('blog-preview-toggle'),
              onPressed: canPreview && !submitting ? onTogglePreview : null,
              tooltip: previewing
                  ? AppLocalizations.of(context)!.blogBackToWriting
                  : AppLocalizations.of(context)!.blogPreview,
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: previewing
                    ? theme.colorScheme.primary
                    : context.riksa.inkMuted,
              ),
              icon: Icon(
                previewing ? Icons.edit_outlined : Icons.visibility_outlined,
                size: 21,
              ),
            ),
            const SizedBox(width: RiksaSpacing.xs),
            FilledButton(
              onPressed: canSubmit ? onSubmit : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: RiksaSpacing.lg,
                ),
                textStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: submitting
                  ? SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : Text(label),
            ),
            const SizedBox(width: RiksaSpacing.xs),
          ],
        ),
      ),
    );
  }
}

/// Topic, cover, and length controls, pinned above the keyboard.
class _ComposerFooter extends StatelessWidget {
  const _ComposerFooter({
    required this.categoryLabel,
    required this.hasCategory,
    required this.coverActive,
    required this.titleLength,
    required this.titleLimit,
    required this.onPickCategory,
    required this.onToggleCover,
  });

  final String? categoryLabel;
  final bool hasCategory;
  final bool coverActive;
  final int titleLength;
  final int titleLimit;
  final VoidCallback onPickCategory;
  final VoidCallback onToggleCover;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.riksa;
    final remaining = titleLimit - titleLength;
    final showCounter = titleLength > titleLimit - 60;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BlogDivider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              BlogMetrics.gutter,
              RiksaSpacing.xs,
              RiksaSpacing.xs,
              RiksaSpacing.xs,
            ),
            child: Row(
              children: [
                Flexible(
                  child: ActionChip(
                    onPressed: onPickCategory,
                    avatar: Icon(
                      hasCategory
                          ? Icons.tag_rounded
                          : Icons.add_circle_outline_rounded,
                      size: 17,
                      color: theme.colorScheme.primary,
                    ),
                    label: Text(
                      categoryLabel ??
                          AppLocalizations.of(context)!.blogChooseTopicRequired,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    labelStyle: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                    backgroundColor: palette.surfaceRaised,
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                  ),
                ),
                IconButton(
                  onPressed: onToggleCover,
                  tooltip: AppLocalizations.of(context)!.blogCoverImage,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: coverActive
                        ? theme.colorScheme.primary
                        : palette.inkMuted,
                  ),
                  icon: const Icon(Icons.image_outlined, size: 21),
                ),
                const Spacer(),
                if (showCounter)
                  Padding(
                    padding: const EdgeInsets.only(right: RiksaSpacing.sm),
                    child: Text(
                      '$remaining',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: remaining < 0
                            ? theme.colorScheme.error
                            : palette.inkMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicSheet extends StatelessWidget {
  const _TopicSheet({required this.categories, required this.selectedId});

  final List<BlogCategory> categories;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.riksa;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              RiksaSpacing.lg,
              0,
              RiksaSpacing.lg,
              RiksaSpacing.xs,
            ),
            child: Text(
              AppLocalizations.of(context)!.blogChooseTopic,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: RiksaSpacing.md),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final selected = category.id == selectedId;
                return ListTile(
                  onTap: () => Navigator.of(context).pop(category.id),
                  title: Text(
                    category.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w600,
                    ),
                  ),
                  subtitle: category.description == null
                      ? null
                      : Text(
                          category.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: palette.inkMuted,
                          ),
                        ),
                  trailing: selected
                      ? Icon(
                          Icons.check_rounded,
                          color: theme.colorScheme.primary,
                        )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Route target for `/blog/:id/edit`.
///
/// In-app navigation hands the post over through `extra`; a cold deep link
/// has to fetch it before the composer has anything to prefill.
class BlogPostEditScreen extends ConsumerStatefulWidget {
  const BlogPostEditScreen({super.key, required this.id, this.post});

  final String id;
  final BlogPost? post;

  @override
  ConsumerState<BlogPostEditScreen> createState() => _BlogPostEditScreenState();
}

class _BlogPostEditScreenState extends ConsumerState<BlogPostEditScreen> {
  BlogPost? _post;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    if (_post == null) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final post = await ref.read(blogApiProvider).getPost(widget.id);
      if (!mounted) return;
      setState(() {
        _post = post;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context)!.blogOpenForEditFailed;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = _post;
    if (post != null) {
      if (ref.watch(currentUserIdProvider) != post.authorId) {
        final l10n = AppLocalizations.of(context)!;
        return Scaffold(
          backgroundColor: blogSheetColor(context),
          body: SafeArea(
            child: Column(
              children: [
                BlogTopBar(
                  title: l10n.blogEditPost,
                  fallbackLocation: '/blog/${Uri.encodeComponent(widget.id)}',
                  result: false,
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Padding(
                        padding: const EdgeInsets.all(RiksaSpacing.lg),
                        child: Text(
                          l10n.blogOwnerEditFailed,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: context.riksa.inkMuted),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return BlogComposerScreen(post: post);
    }
    return Scaffold(
      backgroundColor: blogSheetColor(context),
      body: SafeArea(
        child: Column(
          children: [
            BlogTopBar(
              title: AppLocalizations.of(context)!.blogEditPost,
              fallbackLocation: '/blog/${Uri.encodeComponent(widget.id)}',
              result: false,
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : BlogNotice(
                      title: AppLocalizations.of(
                        context,
                      )!.blogPostUnavailableTitle,
                      body:
                          _error ??
                          AppLocalizations.of(context)!.blogPostUnavailableBody,
                      icon: Icons.cloud_off_outlined,
                      actionLabel: AppLocalizations.of(context)!.tryAgain,
                      onAction: _load,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
