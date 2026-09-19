import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/social_api.dart';
import '../data/social_models.dart';
import '../providers/social_feed_provider.dart';
import 'widgets/post_image_field.dart';
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

  /// The uploaded image's URL. Null means the post carries no picture.
  String? _mediaUrl;
  bool _uploadingImage = false;

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
      _mediaUrl = post.mediaUrl;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  /// Picks an image and uploads it straight away, so a failure surfaces while
  /// the author is still writing rather than when they hit publish.
  Future<void> _pickImage() async {
    final l10n = AppLocalizations.of(context)!;
    final source = await _askImageSource();
    if (source == null || !mounted) return;

    final XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: source,
        // The API caps uploads at 2MB; downscaling here keeps a phone photo
        // comfortably under that instead of failing after the round trip.
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
    } catch (_) {
      if (mounted) _showMessage(l10n.photoFailed);
      return;
    }
    if (picked == null || !mounted) return;

    setState(() => _uploadingImage = true);
    try {
      final url = await ref
          .read(socialApiProvider)
          .uploadMedia(picked.path, filename: picked.name);
      if (!mounted) return;
      setState(() {
        _mediaUrl = url;
        _uploadingImage = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _uploadingImage = false);
      _showMessage(
        error is SocialApiException ? error.message : l10n.photoFailed,
      );
    }
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
    if (!_formKey.currentState!.validate() || _categoryId == null) return;
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
        mediaUrl: _mediaUrl,
      );
    } else {
      failure = await notifier.updatePost(
        id: editing.id,
        title: title,
        content: content,
        // Always explicit on edit: blank tells the API to drop the image.
        mediaUrl: _mediaUrl ?? '',
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = context.riksa;
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
    final canSubmit =
        !_submitting &&
        !_uploadingImage &&
        (_isEditing || categories.isNotEmpty);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip,
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FormField<String>(
                        initialValue: _categoryId,
                        validator: (_) =>
                            _categoryId == null ? l10n.chooseCommunity : null,
                        builder: (field) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownMenu<String>(
                              initialSelection:
                                  options.any((item) => item.id == _categoryId)
                                  ? _categoryId
                                  : null,
                              enabled: !_submitting && !_isEditing && options.isNotEmpty,
                              width: 220,
                              hintText: l10n.chooseCommunity,
                              requestFocusOnTap: false,
                              trailingIcon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 20,
                              ),
                              selectedTrailingIcon: const Icon(
                                Icons.keyboard_arrow_up_rounded,
                                size: 20,
                              ),
                              textStyle: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              menuStyle: MenuStyle(
                                fixedSize: const WidgetStatePropertyAll(
                                  Size.fromWidth(220),
                                ),
                                backgroundColor: WidgetStatePropertyAll(
                                  theme.colorScheme.surface,
                                ),
                                elevation: const WidgetStatePropertyAll(12),
                                shadowColor: WidgetStatePropertyAll(
                                  palette.ink.withValues(alpha: 0.14),
                                ),
                                shape: const WidgetStatePropertyAll(
                                  RoundedRectangleBorder(
                                    borderRadius: AppRadii.largeBorder,
                                  ),
                                ),
                                padding: const WidgetStatePropertyAll(
                                  EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                              inputDecorationTheme: InputDecorationTheme(
                                filled: true,
                                fillColor: theme.colorScheme.surface,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 13,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: AppRadii.fullBorder,
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: AppRadii.fullBorder,
                                  borderSide: BorderSide.none,
                                ),
                                disabledBorder: OutlineInputBorder(
                                  borderRadius: AppRadii.fullBorder,
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              dropdownMenuEntries: options.isEmpty
                                  ? [
                                      DropdownMenuEntry<String>(
                                        value: '',
                                        label: l10n.loading,
                                      ),
                                    ]
                                  : [
                                      for (final category in options)
                                        DropdownMenuEntry<String>(
                                          value: category.id,
                                          label: category.name,
                                          style: ButtonStyle(
                                            textStyle: WidgetStatePropertyAll(
                                              theme.textTheme.labelLarge?.copyWith(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                              onSelected: (value) {
                                if (value == null) return;
                                setState(() => _categoryId = value);
                                field.didChange(value);
                              },
                            ),
                            if (field.hasError) ...[
                              const SizedBox(height: 4),
                              Text(
                                field.errorText!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: canSubmit ? _submit : null,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                      ),
                      child: _submitting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isEditing ? l10n.saveChanges : l10n.publish),
                    ),
                  ],
                ),
                if (categories.isEmpty && !_isEditing) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.noCommunities,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(2, 0, 2, 32),
                    children: [
                      TextFormField(
                        controller: _titleController,
                        enabled: !_submitting,
                        maxLength: 200,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: widget.isQuestion
                              ? l10n.questionTitleLabel
                              : l10n.postTitleLabel,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                        validator: (value) =>
                            value == null || value.trim().length < 4
                            ? (widget.isQuestion
                                  ? l10n.questionTitleLabel
                                  : l10n.postTitleLabel)
                            : null,
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _contentController,
                        enabled: !_submitting,
                        minLines: 10,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: l10n.detailsLabel,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                          height: 1.35,
                        ),
                        validator: (value) =>
                            value == null || value.trim().length < 10
                            ? l10n.detailsLabel
                            : null,
                      ),
                      const SizedBox(height: 16),
                      PostImageField(
                        imageUrl: _mediaUrl,
                        uploading: _uploadingImage,
                        enabled: !_submitting,
                        onPick: _pickImage,
                        onRemove: () => setState(() => _mediaUrl = null),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
          style: const TextStyle(fontWeight: FontWeight.w600),
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
