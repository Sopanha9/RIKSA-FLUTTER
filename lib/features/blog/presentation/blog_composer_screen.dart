import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_avatar_image.dart';
import '../../auth/data/auth_api.dart';
import '../../auth/providers/auth_provider.dart';
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
  const BlogComposerScreen({super.key, this.post});

  /// The post being rewritten. Null starts a new draft.
  final BlogPost? post;

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
  bool _submitting = false;
  bool _submitted = false;
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
      // The server decides whether an edit goes back through moderation.
      if (editing != null) {
        ref.read(blogFeedProvider.notifier).applyUpdate(saved);
        if (saved.status == BlogStatus.approved) {
          context.pop(true);
          return;
        }
      }
      setState(() {
        _submitting = false;
        _submitted = true;
      });
    } on DioException catch (e) {
      _showError(
        editing == null
            ? dioErrorMessage(e)
            : blogOwnerActionError(e, BlogOwnerAction.edit),
      );
    } catch (_) {
      _showError('Something went wrong');
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
    final categories = ref.read(blogCategoriesProvider).value;
    if (categories == null || categories.isEmpty) {
      _showMessage('Topics are still loading. Try again in a moment.');
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
    return Scaffold(
      backgroundColor: blogSheetColor(context),
      body: SafeArea(
        child: _submitted ? _buildPendingReview() : _buildComposer(),
      ),
    );
  }

  Widget _buildPendingReview() => BlogNotice(
    title: _isEditing ? 'Back in review' : 'In review',
    body: _isEditing
        ? 'Your changes were saved. The post returns to the blog once a '
              'moderator approves this version.'
        : 'Your post was submitted. It appears in the blog once a moderator '
              'approves it, and you can follow its status under Your posts.',
    icon: Icons.hourglass_top_rounded,
    actionLabel: 'Done',
    onAction: () => context.pop(true),
    // The copy above points at Your posts, so give it somewhere to point.
    secondaryLabel: 'Your posts',
    onSecondary: () {
      context.pop(true);
      context.push('/blog/my-posts');
    },
  );

  /// Guards the back gesture: leaving with unsaved words should be a choice.
  Future<void> _cancel() async {
    if (_submitting) return;
    if (!_isDirty) {
      context.pop(false);
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isEditing ? 'Discard changes?' : 'Discard draft?'),
        content: Text(
          _isEditing
              ? 'Your edits to this post will be lost.'
              : 'This draft will not be saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep writing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) context.pop(false);
  }

  Widget _buildComposer() {
    final auth = ref.watch(authProvider);
    final user = auth is Authenticated ? auth.user : null;
    // Watched here so the topic list is already in flight by the time the
    // writer reaches for the footer chip.
    final categories = ref.watch(blogCategoriesProvider).value;
    final selected = _selectedCategory(categories);

    return Column(
      children: [
        _ComposerBar(
          label: _isEditing ? 'Save' : 'Post',
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
                fontWeight: FontWeight.w800,
                height: 1.25,
                letterSpacing: -.4,
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
            'Nothing to preview yet.',
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
              fontWeight: FontWeight.w800,
              height: 1.25,
              letterSpacing: -.4,
            ),
          ),
          decoration: _bareField(
            context,
            'Title',
            hintStyle: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.25,
              letterSpacing: -.4,
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
            theme.textTheme.bodyLarge?.copyWith(fontSize: 17, height: 1.7),
          ),
          decoration: _bareField(
            context,
            'Share what you learned. Markdown works here.',
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 17,
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
                    'Cover image URL (optional)',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: palette.inkFaint,
                    ),
                  ),
                ),
              ),
              if (_cover.isNotEmpty)
                IconButton(
                  onPressed: () => setState(() {
                    _coverCtrl.clear();
                    _showCoverField = false;
                  }),
                  tooltip: 'Remove cover',
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
              child: const Text('Cancel'),
            ),
            const Spacer(),
            IconButton(
              key: const ValueKey('blog-preview-toggle'),
              onPressed: canPreview && !submitting ? onTogglePreview : null,
              tooltip: previewing ? 'Back to writing' : 'Preview',
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
                minimumSize: const Size(0, 38),
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
                      categoryLabel ?? 'Choose a topic',
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
                  tooltip: 'Cover image',
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
              'Choose a topic',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
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
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
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
        _error = 'Could not open this post for editing';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = _post;
    if (post != null) return BlogComposerScreen(post: post);
    return Scaffold(
      backgroundColor: blogSheetColor(context),
      body: SafeArea(
        child: Column(
          children: [
            BlogTopBar(title: 'Edit post', onBack: () => context.pop(false)),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : BlogNotice(
                      title: 'Post unavailable',
                      body: _error ?? 'This post could not be loaded.',
                      icon: Icons.cloud_off_outlined,
                      actionLabel: 'Try again',
                      onAction: _load,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
