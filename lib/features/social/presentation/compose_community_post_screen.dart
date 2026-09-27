import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/unsaved_changes_guard.dart';
import '../../blog/presentation/widgets/markdown_toolbar.dart';
import '../../auth/presentation/require_account.dart';
import '../../mascot/providers/buddy_care_provider.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/social_api.dart';
import '../data/social_models.dart';
import '../providers/social_feed_provider.dart';
import 'widgets/community_avatar.dart';
import 'widgets/post_image_field.dart';
import 'widgets/social_markdown_style.dart';

/// Writes a community post, or rewrites one the reader already owns.
///
/// In edit mode the community is fixed: moving a post would also have to
/// satisfy the join-before-posting rule the backend enforces on create.
class ComposeCommunityPostScreen extends ConsumerStatefulWidget {
  const ComposeCommunityPostScreen({
    super.key,
    this.isQuestion = false,
    this.post,
    this.communityId,
    this.imagePicker,
  });

  final bool isQuestion;

  /// The community to preselect, when the author starts from its page.
  final String? communityId;

  /// The post being rewritten. Null starts a new one.
  final SocialPost? post;

  /// Injectable to exercise gallery and camera flows in widget tests.
  final ImagePicker? imagePicker;

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
  bool _previewing = false;

  final List<PostImageDraft> _photos = [];
  int _nextPhotoId = 0;
  bool _showEmptyPostMessage = false;

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
      for (var index = 0; index < post.media.length; index++) {
        final media = post.media[index];
        _photos.add(
          PostImageDraft(
            id: 'existing-$index',
            path: media.url,
            remote: true,
            media: media,
          ),
        );
      }
    } else {
      _categoryId = widget.communityId;
    }
    _titleController.addListener(_syncDirty);
    _contentController.addListener(_syncDirty);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  /// Whether leaving now would lose something the author wrote or attached.
  bool get _isDirty {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final post = _original;
    if (post == null) {
      return title.isNotEmpty || content.isNotEmpty || _photos.isNotEmpty;
    }
    return title != post.title.trim() ||
        content != post.markdownContent.trim() ||
        !_sameMedia(post.media, _photos);
  }

  bool _wasDirty = false;

  void _syncDirty() {
    final dirty = _isDirty;
    final nowHasBodyOrPhotos =
        _contentController.text.trim().isNotEmpty || _photos.isNotEmpty;
    if (dirty != _wasDirty || (_showEmptyPostMessage && nowHasBodyOrPhotos)) {
      setState(() {
        _wasDirty = dirty;
        if (nowHasBodyOrPhotos) _showEmptyPostMessage = false;
      });
    }
  }

  /// Picks up to the remaining four slots and uploads each image immediately.
  Future<void> _pickImages() async {
    if (_photos.length >= 4 || _submitting) return;
    if (!requireAccount(context, ref, reason: 'post')) return;
    final l10n = AppLocalizations.of(context)!;
    final source = await _askImageSource();
    if (source == null || !mounted) return;

    final List<XFile> picked;
    final remaining = 4 - _photos.length;
    try {
      final picker = widget.imagePicker ?? ImagePicker();
      if (source == ImageSource.gallery) {
        picked = await picker.pickMultiImage(
          limit: remaining,
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 85,
        );
      } else {
        final photo = await picker.pickImage(
          source: source,
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 85,
        );
        picked = photo == null ? const [] : [photo];
      }
    } catch (_) {
      if (mounted) _showMessage(l10n.postPhotosUploadFailed);
      return;
    }
    if (picked.isEmpty || !mounted) return;
    final accepted = picked.take(remaining).toList(growable: false);
    final additions = <PostImageDraft>[];
    for (final photo in accepted) {
      additions.add(
        PostImageDraft(id: 'picked-${_nextPhotoId++}', path: photo.path),
      );
    }
    setState(() => _photos.addAll(additions));
    if (picked.length > remaining) _showMessage(l10n.postPhotosLimitReached);
    for (var index = 0; index < accepted.length; index++) {
      unawaited(_uploadPhoto(additions[index].id, accepted[index]));
    }
  }

  Future<void> _uploadPhoto(String id, [XFile? source]) async {
    final current = _photos.where((photo) => photo.id == id).firstOrNull;
    if (current == null) return;
    final file = source;
    if (file == null) {
      _showMessage(AppLocalizations.of(context)!.postPhotosUploadFailed);
      return;
    }
    _updatePhoto(id, (photo) => PostImageDraft(id: photo.id, path: photo.path));
    try {
      final media = await ref
          .read(socialApiProvider)
          .uploadMedia(
            file.path,
            filename: file.name,
            onSendProgress: (sent, total) {
              if (total <= 0 || !mounted) return;
              final progress = (sent / total).clamp(0.0, 1.0).toDouble();
              _updatePhoto(
                id,
                (photo) => PostImageDraft(
                  id: photo.id,
                  path: photo.path,
                  progress: progress,
                ),
              );
            },
          );
      if (!mounted) return;
      _updatePhoto(
        id,
        (photo) => PostImageDraft(id: photo.id, path: photo.path, media: media),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is SocialApiException
          ? error.message
          : AppLocalizations.of(context)!.postPhotosUploadFailed;
      _updatePhoto(
        id,
        (photo) =>
            PostImageDraft(id: photo.id, path: photo.path, error: message),
      );
    }
  }

  void _updatePhoto(String id, PostImageDraft Function(PostImageDraft) update) {
    if (!mounted || !_photos.any((photo) => photo.id == id)) return;
    setState(() {
      final index = _photos.indexWhere((photo) => photo.id == id);
      _photos[index] = update(_photos[index]);
    });
    _syncDirty();
  }

  void _removePhoto(String id) {
    setState(() {
      _photos.removeWhere((photo) => photo.id == id);
      if (_photos.isNotEmpty || _contentController.text.trim().isNotEmpty) {
        _showEmptyPostMessage = false;
      }
    });
    _syncDirty();
  }

  void _retryPhoto(String id) {
    final photo = _photos.where((item) => item.id == id).firstOrNull;
    if (photo == null) return;
    final source = XFile(photo.path);
    unawaited(_uploadPhoto(id, source));
  }

  void _reorderPhotos(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    setState(() {
      final photo = _photos.removeAt(oldIndex);
      _photos.insert(newIndex, photo);
    });
    _syncDirty();
  }

  Future<ImageSource?> _askImageSource() => showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final l10n = AppLocalizations.of(sheetContext)!;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const ValueKey('pick-from-gallery'),
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.photoFromGallery),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
            ListTile(
              key: const ValueKey('pick-from-camera'),
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.photoFromCamera),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
          ],
        ),
      );
    },
  );

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (!requireAccount(context, ref, reason: 'post')) return;
    if (_submitting ||
        _photos.any((photo) => photo.uploading || photo.error != null)) {
      return;
    }
    if (_contentController.text.trim().isEmpty && _photos.isEmpty) {
      setState(() => _showEmptyPostMessage = true);
      return;
    }
    if (_categoryId == null) return;
    setState(() => _submitting = true);
    final notifier = ref.read(socialFeedProvider.notifier);
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final editing = _original;

    final String? failure;
    if (editing == null) {
      failure = await notifier.createPost(
        title: title,
        content: content,
        categoryId: _categoryId!,
        media: [for (final photo in _photos) photo.media!],
      );
    } else {
      final media = _sameMedia(editing.media, _photos)
          ? null
          : [for (final photo in _photos) photo.media!];
      failure = await notifier.updatePost(
        id: editing.id,
        title: title,
        content: content,
        // Null leaves photos unchanged; an empty list explicitly clears them.
        media: media,
      );
    }

    if (!mounted) return;
    setState(() => _submitting = false);
    if (failure == null) {
      if (editing == null) {
        unawaited(ref.read(buddyCareProvider.notifier).refresh());
      }
      Navigator.of(context).pop(true);
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(failure)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = context.riksa;
    final feed = ref.watch(socialFeedProvider);
    final loaded = feed is SocialFeedLoaded;
    // Only members post, so a new post can go to joined communities only.
    final categories = feed is SocialFeedLoaded
        ? feed.categories.where((item) => item.joined).toList()
        : const <SocialCategory>[];
    // Only a loaded list can overrule the choice; while it loads, keep the
    // community the author started from.
    if (loaded &&
        !_isEditing &&
        !categories.any((item) => item.id == _categoryId)) {
      _categoryId = categories.firstOrNull?.id;
    }
    // An edited post keeps its own community even when the feed's category
    // list has not loaded, or no longer contains it.
    final editCategory = _original?.category;
    final options = <SocialCategory>[
      ...categories,
      if (editCategory != null &&
          !categories.any((item) => item.id == editCategory.id))
        editCategory,
    ];
    final selected = options
        .where((item) => item.id == _categoryId)
        .firstOrNull;
    // Posting needs a loaded list with at least one joined community.
    final noCommunity = !_isEditing && (!loaded || categories.isEmpty);
    final communitiesFailed = !_isEditing && feed is SocialFeedFailure;
    final uploadingPhotos = _photos.any((photo) => photo.uploading);
    final failedPhotos = _photos.any((photo) => photo.error != null);
    final busy = _submitting || uploadingPhotos;
    final title = _isEditing
        ? l10n.editPost
        : widget.isQuestion
        ? l10n.askCommunity
        : l10n.createPost;

    // Borderless fields: the page is the writing surface.
    InputDecoration bare(String hint, TextStyle? style) => InputDecoration(
      hintText: hint,
      hintStyle: style?.copyWith(color: palette.inkFaint),
      filled: false,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      contentPadding: EdgeInsets.zero,
      counterText: '',
    );
    final titleStyle = theme.textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w800,
      height: 1.25,
    );
    final bodyStyle = theme.textTheme.bodyLarge?.copyWith(height: 1.5);

    return UnsavedChangesGuard(
      dirty: _isDirty,
      busy: _submitting,
      child: Scaffold(
        backgroundColor: palette.canvas,
        appBar: AppBar(
          backgroundColor: palette.canvas,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            key: const ValueKey('compose-close'),
            onPressed: () => Navigator.maybePop(context),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            style: IconButton.styleFrom(backgroundColor: Colors.transparent),
            icon: const Icon(Icons.close_rounded),
          ),
          titleSpacing: 0,
          title: Text(
            title,
            style: RiksaTypography.titleStyleFor(
              title,
              theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton(
                key: const ValueKey('compose-submit'),
                onPressed: busy || failedPhotos || noCommunity ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(72, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
                child: _submitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? l10n.saveChanges : l10n.publish),
              ),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            // Phone-width column, centred when the window is wider.
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _CommunityChip(
                            community: selected,
                            placeholder:
                                !_isEditing && feed is SocialFeedLoading
                                ? l10n.composeLoadingCommunities
                                : l10n.chooseCommunity,
                            // A post keeps the community it was written in.
                            onTap: _isEditing || busy || categories.isEmpty
                                ? null
                                : () => _pickCommunity(categories),
                          ),
                        ),
                        if (communitiesFailed) ...[
                          const SizedBox(height: 12),
                          _ComposeNotice(
                            key: const ValueKey('compose-communities-failed'),
                            icon: Icons.cloud_off_rounded,
                            message: l10n.composeCommunitiesFailed,
                            actionLabel: l10n.tryAgain,
                            onAction: () =>
                                ref.read(socialFeedProvider.notifier).load(),
                          ),
                        ] else if (loaded && noCommunity) ...[
                          const SizedBox(height: 12),
                          _ComposeNotice(
                            icon: Icons.info_outline_rounded,
                            message: l10n.composeJoinFirst,
                            actionKey: const ValueKey(
                              'compose-browse-communities',
                            ),
                            actionLabel: l10n.composeBrowseCommunities,
                            onAction: () => context.push('/communities'),
                          ),
                        ],
                        const SizedBox(height: 20),
                        TextFormField(
                          key: const ValueKey('compose-title'),
                          controller: _titleController,
                          enabled: !_submitting,
                          maxLength: 200,
                          minLines: 1,
                          maxLines: 4,
                          style: titleStyle,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.next,
                          decoration: bare(
                            widget.isQuestion
                                ? l10n.questionTitleLabel
                                : l10n.postTitleLabel,
                            titleStyle,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Visibility(
                          visible: !_previewing,
                          maintainState: true,
                          child: TextFormField(
                            key: const ValueKey('compose-body'),
                            controller: _contentController,
                            enabled: !_submitting,
                            minLines: 8,
                            maxLines: null,
                            style: bodyStyle,
                            keyboardType: TextInputType.multiline,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: bare(l10n.detailsLabel, bodyStyle),
                          ),
                        ),
                        if (_showEmptyPostMessage &&
                            _contentController.text.trim().isEmpty &&
                            _photos.isEmpty)
                          Padding(
                            key: const ValueKey('compose-empty-post-message'),
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              l10n.postPhotosBodyRequired,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                        if (_previewing)
                          Padding(
                            key: const ValueKey('compose-markdown-preview'),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: MarkdownBody(
                              data: normalizeSocialMarkdown(
                                _contentController.text,
                              ),
                              softLineBreak: true,
                              styleSheet: socialMarkdownStyleSheet(
                                context,
                                _contentController.text,
                              ),
                            ),
                          ),
                        if (_photos.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          PostImageField(
                            photos: _photos,
                            enabled: !_submitting,
                            onRemove: _removePhoto,
                            onRetry: _retryPhoto,
                            onReorder: _reorderPhotos,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Sits above the keyboard, like a mobile editor toolbar.
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.canvas,
                    border: Border(top: BorderSide(color: palette.outline)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!_previewing)
                            BlogMarkdownToolbar(
                              actions: const [
                                BlogMarkdownAction.bold,
                                BlogMarkdownAction.italic,
                                BlogMarkdownAction.bulletList,
                                BlogMarkdownAction.numberedList,
                                BlogMarkdownAction.quote,
                                BlogMarkdownAction.link,
                              ],
                              onAction: _format,
                            ),
                          Row(
                            children: [
                              IconButton(
                                key: const ValueKey('compose-add-photo'),
                                onPressed: _submitting || _photos.length >= 4
                                    ? null
                                    : _pickImages,
                                tooltip: l10n.postPhotosAdd,
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: palette.brand,
                                ),
                                icon: const Icon(Icons.image_outlined),
                              ),
                              Text(
                                l10n.postPhotosAdd,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: palette.inkMuted,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                key: const ValueKey('compose-write'),
                                onPressed: _previewing
                                    ? () {
                                        FocusScope.of(context).unfocus();
                                        setState(() => _previewing = false);
                                      }
                                    : null,
                                child: Text(l10n.composerWrite),
                              ),
                              TextButton(
                                key: const ValueKey('compose-preview'),
                                onPressed: !_previewing
                                    ? () {
                                        FocusScope.of(context).unfocus();
                                        setState(() => _previewing = true);
                                      }
                                    : null,
                                child: Text(l10n.composerPreview),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickCommunity(List<SocialCategory> communities) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) =>
          _CommunitySheet(communities: communities, selectedId: _categoryId),
    );
    if (picked != null && mounted) setState(() => _categoryId = picked);
  }

  void _format(BlogMarkdownAction action) {
    _contentController.value = applyBlogMarkdown(
      _contentController.value,
      action,
    );
  }
}

bool _sameMedia(List<SocialPostMedia> original, List<PostImageDraft> edited) {
  if (original.length != edited.length) return false;
  for (var index = 0; index < original.length; index++) {
    final current = edited[index].media;
    if (current == null ||
        current.url != original[index].url ||
        current.width != original[index].width ||
        current.height != original[index].height) {
      return false;
    }
  }
  return true;
}

/// The "post to" selector at the top of the editor.
class _CommunityChip extends StatelessWidget {
  const _CommunityChip({
    required this.community,
    required this.placeholder,
    required this.onTap,
  });

  final SocialCategory? community;
  final String placeholder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.riksa;
    final community = this.community;
    final label = community?.name ?? placeholder;
    return Material(
      color: palette.surface,
      shape: StadiumBorder(side: BorderSide(color: palette.outline)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const ValueKey('compose-community'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (community != null)
                ClipOval(child: CommunityAvatar(community: community, size: 28))
              else
                CircleAvatar(
                  radius: 14,
                  backgroundColor: palette.brandSoft,
                  child: Icon(
                    Icons.groups_2_outlined,
                    size: 16,
                    color: palette.brand,
                  ),
                ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: RiksaTypography.bodyStyleFor(
                    label,
                    theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: palette.inkMuted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CommunitySheet extends StatelessWidget {
  const _CommunitySheet({required this.communities, required this.selectedId});

  final List<SocialCategory> communities;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = context.riksa;
    final locale = Localizations.localeOf(context).languageCode;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                l10n.chooseCommunity,
                style: RiksaTypography.titleStyleFor(
                  l10n.chooseCommunity,
                  theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 12),
                children: [
                  for (final item in communities)
                    ListTile(
                      key: ValueKey('compose-community-${item.id}'),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      leading: ClipOval(
                        child: CommunityAvatar(community: item, size: 40),
                      ),
                      title: Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        l10n.communityMemberCount(
                          item.memberCount,
                          NumberFormat.compact(
                            locale: locale,
                          ).format(item.memberCount),
                        ),
                      ),
                      trailing: item.id == selectedId
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: palette.brand,
                            )
                          : null,
                      onTap: () => Navigator.of(context).pop(item.id),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// An inline note under the community picker, with one way forward.
class _ComposeNotice extends StatelessWidget {
  const _ComposeNotice({
    super.key,
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.actionKey,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.riksa;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: palette.brandSoft.withValues(alpha: .5),
        borderRadius: AppRadii.largeBorder,
      ),
      child: Row(
        children: [
          Icon(icon, color: palette.brand),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: theme.textTheme.bodyMedium)),
          TextButton(
            key: actionKey,
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
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
      backgroundColor: context.riksa.canvas,
      appBar: AppBar(
        backgroundColor: context.riksa.canvas,
        foregroundColor: context.riksa.brand,
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
                        color: context.riksa.inkMuted,
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
