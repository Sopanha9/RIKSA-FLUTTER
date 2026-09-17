import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/unsaved_changes_guard.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/social_api.dart';
import '../providers/social_feed_provider.dart';

/// Mirrors the server's rules so most mistakes show up before a round trip.
/// The server stays the authority and re-checks everything.
abstract final class CommunityNameRules {
  static const minLength = 3;
  static const maxLength = 50;
  static const descriptionMaxLength = 300;

  static final _allowed = RegExp(
    r"^[\p{L}\p{M}\p{N} &'.,()+#-]+$",
    unicode: true,
  );
  static final _letter = RegExp(r'\p{L}', unicode: true);
  static final _notLetterOrDigit = RegExp(r'[^\p{L}\p{N}]', unicode: true);
  static const _reserved = {
    'admin', 'administrator', 'moderator', 'moderators', 'mod', 'mods', //
    'staff', 'support', 'system', 'official', 'help', 'helpdesk', 'root',
    'security', 'teacher', 'teachers', 'null', 'undefined', 'api', 'graphql',
    'communities', 'community', 'settings',
  };

  static String clean(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Null when [raw] is acceptable, otherwise the problem to show.
  static String? validate(AppLocalizations l10n, String? raw) {
    final name = clean(raw ?? '');
    final length = name.runes.length;
    if (length < minLength || length > maxLength) {
      return l10n.createCommunityNameLength;
    }
    if (!_allowed.hasMatch(name)) return l10n.createCommunityNameChars;
    if (!_letter.hasMatch(name)) return l10n.createCommunityNameLetters;
    final compact = name.toLowerCase().replaceAll(_notLetterOrDigit, '');
    if (_reserved.contains(compact) || compact.contains('riksa')) {
      return l10n.createCommunityNameReserved;
    }
    return null;
  }
}

/// Founds a new community. Pops with the created community on success.
class CreateCommunityScreen extends ConsumerStatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  ConsumerState<CreateCommunityScreen> createState() =>
      _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends ConsumerState<CreateCommunityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _iconUrl;
  bool _uploadingIcon = false;
  bool _submitting = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_syncDirty);
    _descriptionController.addListener(_syncDirty);
  }

  void _syncDirty() {
    final dirty =
        _nameController.text.trim().isNotEmpty ||
        _descriptionController.text.trim().isNotEmpty;
    if (dirty != _dirty) setState(() => _dirty = dirty);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickIcon() async {
    final l10n = AppLocalizations.of(context)!;
    final XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        // An icon is shown small; this keeps uploads well under the 2MB cap.
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
    } catch (_) {
      _showMessage(l10n.photoFailed);
      return;
    }
    if (picked == null || !mounted) return;

    setState(() => _uploadingIcon = true);
    try {
      final url = await ref
          .read(socialApiProvider)
          .uploadMedia(picked.path, filename: picked.name);
      if (mounted) setState(() => _iconUrl = url);
    } catch (error) {
      _showMessage(
        error is SocialApiException ? error.message : l10n.photoFailed,
      );
    } finally {
      if (mounted) setState(() => _uploadingIcon = false);
    }
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final l10n = AppLocalizations.of(context)!;
    final description = _descriptionController.text.trim();
    try {
      final created = await ref
          .read(socialApiProvider)
          .createCommunity(
            name: CommunityNameRules.clean(_nameController.text),
            description: description.isEmpty ? null : description,
            iconUrl: _iconUrl,
          );
      if (ref.exists(socialFeedProvider)) {
        ref.read(socialFeedProvider.notifier).syncCategory(created);
      }
      if (mounted) context.pop(created);
    } catch (error) {
      _showMessage(
        error is SocialApiException ? error.message : l10n.actionFailed,
      );
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = context.riksa;
    final busy = _submitting || _uploadingIcon;

    return UnsavedChangesGuard(
      dirty: _dirty || _iconUrl != null,
      busy: _submitting,
      child: Scaffold(
        backgroundColor: palette.canvas,
        appBar: AppBar(
          backgroundColor: palette.canvas,
          titleSpacing: 0,
          title: Text(
            l10n.communitiesCreate,
            style: RiksaTypography.titleStyleFor(
              l10n.communitiesCreate,
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Center(
                  child: _IconPicker(
                    iconUrl: _iconUrl,
                    uploading: _uploadingIcon,
                    onPick: busy ? null : _pickIcon,
                    onRemove: busy
                        ? null
                        : () => setState(() => _iconUrl = null),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.createCommunityIconHint,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.inkMuted,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  key: const ValueKey('create-community-name'),
                  controller: _nameController,
                  enabled: !_submitting,
                  maxLength: CommunityNameRules.maxLength,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.createCommunityName,
                    hintText: l10n.createCommunityNameHint,
                    prefixIcon: const Icon(Icons.groups_2_outlined),
                  ),
                  validator: (value) =>
                      CommunityNameRules.validate(l10n, value),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: const ValueKey('create-community-description'),
                  controller: _descriptionController,
                  enabled: !_submitting,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: CommunityNameRules.descriptionMaxLength,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l10n.createCommunityDescription,
                    hintText: l10n.createCommunityDescriptionHint,
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                _GuidelinesCard(),
                const SizedBox(height: 24),
                FilledButton.icon(
                  key: const ValueKey('create-community-submit'),
                  onPressed: busy ? null : _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  icon: _submitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_rounded),
                  label: Text(l10n.communitiesCreate),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconPicker extends StatelessWidget {
  const _IconPicker({
    required this.iconUrl,
    required this.uploading,
    required this.onPick,
    required this.onRemove,
  });

  final String? iconUrl;
  final bool uploading;
  final VoidCallback? onPick;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.riksa;
    const size = 104.0;
    final radius = BorderRadius.circular(size * .26);
    final url = iconUrl;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Semantics(
          button: true,
          label: l10n.createCommunityIcon,
          child: Material(
            color: palette.brandSoft,
            shape: RoundedRectangleBorder(borderRadius: radius),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: const ValueKey('create-community-icon'),
              onTap: onPick,
              child: SizedBox.square(
                dimension: size,
                child: uploading
                    ? const Center(child: CircularProgressIndicator())
                    : url != null
                    ? Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Icon(
                          Icons.broken_image_outlined,
                          color: palette.brand,
                        ),
                      )
                    : Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 40,
                        color: palette.brand,
                      ),
              ),
            ),
          ),
        ),
        if (url != null && !uploading)
          Positioned(
            right: -8,
            top: -8,
            child: IconButton.filled(
              key: const ValueKey('create-community-icon-remove'),
              onPressed: onRemove,
              tooltip: l10n.removePhoto,
              iconSize: 18,
              style: IconButton.styleFrom(
                backgroundColor: palette.ink,
                foregroundColor: palette.canvas,
                minimumSize: const Size.square(32),
              ),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
      ],
    );
  }
}

class _GuidelinesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = context.riksa;
    final rules = [
      (Icons.public_rounded, l10n.createCommunityRulePublic),
      (Icons.verified_user_outlined, l10n.createCommunityRuleOwner),
      (Icons.gavel_rounded, l10n.createCommunityRuleConduct),
      (Icons.timer_outlined, l10n.createCommunityRuleLimit),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadii.largeBorder,
        border: Border.all(color: palette.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.createCommunityRulesTitle,
            style: RiksaTypography.titleStyleFor(
              l10n.createCommunityRulesTitle,
              theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          for (final (icon, text) in rules)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 18, color: palette.brand),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      text,
                      style: RiksaTypography.bodyStyleFor(
                        text,
                        theme.textTheme.bodySmall?.copyWith(
                          color: palette.inkMuted,
                        ),
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
