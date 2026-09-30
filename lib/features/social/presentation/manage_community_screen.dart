import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_avatar_image.dart';
import '../../../core/widgets/riksa_back_button.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../learning/presentation/learning_design.dart';
import '../../userProfile/presentation/public_profile_navigation.dart';
import '../data/social_api.dart';
import '../data/social_models.dart';
import '../providers/social_feed_provider.dart';
import 'create_community_screen.dart' show CommunityNameRules;
import 'widgets/community_avatar.dart';
import 'widgets/community_banner_art.dart';

/// A community's control room. The owner edits settings, rules and
/// moderators; moderators handle members and bans.
class ManageCommunityScreen extends ConsumerStatefulWidget {
  const ManageCommunityScreen({
    super.key,
    required this.communityId,
    this.community,
    this.initialTab,
  });

  final String communityId;
  final SocialCategory? community;

  /// settings, rules, members or banned.
  final String? initialTab;

  @override
  ConsumerState<ManageCommunityScreen> createState() =>
      _ManageCommunityScreenState();
}

class _ManageCommunityScreenState extends ConsumerState<ManageCommunityScreen> {
  SocialCategory? _community;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _community = widget.community;
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final community = await ref
          .read(socialApiProvider)
          .community(widget.communityId);
      if (mounted) setState(() => _community = community);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = context.riksa;
    final community = _community;
    final fallback = '/communities/${widget.communityId}';

    Widget scaffold({required Widget body, PreferredSizeWidget? bottom}) =>
        Scaffold(
          backgroundColor: palette.canvas,
          appBar: AppBar(
            backgroundColor: palette.canvas,
            leading: Center(child: RiksaBackButton(fallbackLocation: fallback)),
            titleSpacing: 0,
            title: Text(
              l10n.communityManage,
              style: RiksaTypography.titleStyleFor(
                l10n.communityManage,
                theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            bottom: bottom,
          ),
          body: body,
        );

    if (community == null) {
      return scaffold(
        body: Center(
          child: _failed
              ? TextButton(onPressed: _load, child: Text(l10n.tryAgain))
              : const CircularProgressIndicator(),
        ),
      );
    }
    if (!community.canModerate) {
      return scaffold(body: Center(child: Text(l10n.actionFailed)));
    }

    final owner = community.isOwner;
    final tabs = [
      if (owner) Tab(text: l10n.communityTabSettings),
      if (owner) Tab(text: l10n.communityTabRules),
      Tab(text: l10n.communityTabMembers),
      Tab(text: l10n.communityTabBanned),
    ];
    final views = [
      if (owner)
        _SettingsTab(
          community: community,
          onSaved: (updated) => setState(() => _community = updated),
        ),
      if (owner)
        _RulesTab(
          community: community,
          onSaved: (updated) => setState(() => _community = updated),
        ),
      _MembersTab(community: community),
      _BansTab(community: community),
    ];

    final names = [
      if (owner) 'settings',
      if (owner) 'rules',
      'members',
      'banned',
    ];
    return DefaultTabController(
      length: tabs.length,
      initialIndex: names.contains(widget.initialTab)
          ? names.indexOf(widget.initialTab!)
          : 0,
      child: scaffold(
        bottom: TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: tabs,
        ),
        body: TabBarView(children: views),
      ),
    );
  }
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

String _errorText(BuildContext context, Object error) =>
    error is SocialApiException
    ? error.message
    : AppLocalizations.of(context)!.actionFailed;

// ── Settings ──────────────────────────────────────────────

class _SettingsTab extends ConsumerStatefulWidget {
  const _SettingsTab({required this.community, required this.onSaved});

  final SocialCategory community;
  final ValueChanged<SocialCategory> onSaved;

  @override
  ConsumerState<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<_SettingsTab>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.community.name);
  late final _description = TextEditingController(
    text: widget.community.description ?? '',
  );
  late var _permission = widget.community.postPermission;
  late String? _bannerUrl = widget.community.bannerUrl;
  late String? _bannerColor = widget.community.bannerColor;
  late String? _iconUrl = widget.community.iconUrl;
  bool _saving = false;
  bool _uploading = false;

  /// Uploads a photo from the gallery and returns its link, or null.
  Future<String?> _upload({
    required double maxWidth,
    required double maxHeight,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: 85,
      );
    } catch (_) {
      if (mounted) _toast(context, l10n.photoFailed);
      return null;
    }
    if (picked == null || !mounted) return null;
    setState(() => _uploading = true);
    try {
      final media = await ref
          .read(socialApiProvider)
          .uploadMedia(picked.path, filename: picked.name);
      return media.url;
    } catch (error) {
      if (mounted) _toast(context, _errorText(context, error));
      return null;
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _pickBanner() async {
    final url = await _upload(maxWidth: 1600, maxHeight: 800);
    if (url != null && mounted) setState(() => _bannerUrl = url);
  }

  Future<void> _pickIcon() async {
    final url = await _upload(maxWidth: 512, maxHeight: 512);
    if (url != null && mounted) setState(() => _iconUrl = url);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context)!;
    final name = _name.text.trim();
    try {
      final updated = await ref
          .read(socialApiProvider)
          .updateCommunity(
            id: widget.community.id,
            name: name == widget.community.name ? null : name,
            description: _description.text.trim(),
            postPermission: _permission,
            iconUrl: _iconUrl != widget.community.iconUrl ? _iconUrl : null,
            clearIcon: _iconUrl == null && widget.community.iconUrl != null,
            bannerUrl: _bannerUrl != widget.community.bannerUrl
                ? _bannerUrl
                : null,
            clearBanner:
                _bannerUrl == null && widget.community.bannerUrl != null,
            bannerColor: _bannerColor != widget.community.bannerColor
                ? (_bannerColor ?? '')
                : null,
          );
      if (!mounted) return;
      widget.onSaved(updated);
      _toast(context, l10n.communitySaved);
    } catch (error) {
      if (mounted) _toast(context, _errorText(context, error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<Widget> _look(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = context.riksa;
    final community = widget.community;
    final subject = stemSubjectFor(community.name);
    final tone = subjectTone(context, subject);
    final busy = _saving || _uploading;
    final preview = SocialCategory(
      id: community.id,
      name: community.name,
      slug: community.slug,
      memberCount: community.memberCount,
      joined: community.joined,
      iconUrl: _iconUrl,
    );

    Widget swatch(String? hex) {
      final selected = _bannerColor == hex;
      final color = parseBannerColor(hex) ?? tone.surface;
      return Semantics(
        button: true,
        selected: selected,
        label: hex ?? l10n.communityBannerAuto,
        child: GestureDetector(
          key: ValueKey('banner-color-${hex ?? 'auto'}'),
          onTap: busy ? null : () => setState(() => _bannerColor = hex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? palette.ink : palette.outline,
                width: selected ? 3 : 1,
              ),
            ),
            child: hex == null
                ? Icon(stemSubjectIcon(subject), size: 18, color: tone.accent)
                : selected
                ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                : null,
          ),
        ),
      );
    }

    final heading = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
    );
    return [
      Text(l10n.communityLook, style: heading),
      const SizedBox(height: 10),
      ClipRRect(
        borderRadius: AppRadii.mediumBorder,
        child: SizedBox(
          height: 140,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CommunityBannerArt(
                subject: subject,
                bannerUrl: _bannerUrl,
                bannerColor: _bannerColor,
              ),
              Positioned(
                left: 14,
                bottom: 14,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: palette.canvas,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: CommunityAvatar(community: preview, size: 58),
                ),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Row(
                  children: [
                    if (_bannerUrl != null) ...[
                      IconButton.filledTonal(
                        key: const ValueKey('manage-remove-banner'),
                        tooltip: l10n.communityRemoveBanner,
                        onPressed: busy
                            ? null
                            : () => setState(() => _bannerUrl = null),
                        icon: const Icon(Icons.close_rounded),
                      ),
                      const SizedBox(width: 6),
                    ],
                    FilledButton.tonalIcon(
                      key: const ValueKey('manage-change-banner'),
                      onPressed: busy ? null : _pickBanner,
                      icon: _uploading
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.photo_camera_outlined, size: 18),
                      label: Text(l10n.communityChangeBanner),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
      Text(
        l10n.communityBannerColor,
        style: theme.textTheme.labelLarge?.copyWith(color: palette.inkMuted),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          swatch(null),
          for (final hex in communityBannerColors) swatch(hex),
        ],
      ),
      const SizedBox(height: 14),
      if (subject == StemSubject.other)
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            key: const ValueKey('manage-change-icon'),
            onPressed: busy ? null : _pickIcon,
            icon: const Icon(Icons.image_outlined, size: 18),
            label: Text(l10n.communityChangeIcon),
          ),
        )
      else
        Text(
          l10n.communityIconSubjectHint,
          style: theme.textTheme.bodySmall?.copyWith(color: palette.inkMuted),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = context.riksa;

    Widget permissionOption(
      CommunityPostPermission value,
      String title,
      String body,
      IconData icon,
    ) {
      final selected = _permission == value;
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        color: selected
            ? palette.brand.withValues(alpha: .08)
            : palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.mediumBorder,
          side: BorderSide(color: selected ? palette.brand : palette.outline),
        ),
        child: ListTile(
          key: ValueKey('manage-permission-${value.name}'),
          onTap: _saving ? null : () => setState(() => _permission = value),
          leading: Icon(icon, color: selected ? palette.brand : palette.ink),
          title: Text(title),
          subtitle: Text(body),
          trailing: selected
              ? Icon(Icons.check_circle_rounded, color: palette.brand)
              : null,
        ),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          ..._look(context),
          const SizedBox(height: 20),
          TextFormField(
            key: const ValueKey('manage-name'),
            controller: _name,
            enabled: !_saving,
            maxLength: CommunityNameRules.maxLength,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.communityFieldName,
              prefixIcon: const Icon(Icons.groups_2_outlined),
            ),
            validator: (value) => CommunityNameRules.validate(l10n, value),
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: const ValueKey('manage-description'),
            controller: _description,
            enabled: !_saving,
            minLines: 3,
            maxLines: 5,
            maxLength: CommunityNameRules.descriptionMaxLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.communityFieldDescription,
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.communityWhoCanPost,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          permissionOption(
            CommunityPostPermission.members,
            l10n.communityPostAllMembers,
            l10n.communityPostAllMembersBody,
            Icons.forum_outlined,
          ),
          permissionOption(
            CommunityPostPermission.moderators,
            l10n.communityPostModsOnly,
            l10n.communityPostModsOnlyBody,
            Icons.campaign_outlined,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const ValueKey('manage-save-settings'),
            onPressed: _saving || _uploading ? null : _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(l10n.communitySaveChanges),
          ),
        ],
      ),
    );
  }
}

// ── Rules ─────────────────────────────────────────────────

class _RulesTab extends ConsumerStatefulWidget {
  const _RulesTab({required this.community, required this.onSaved});

  final SocialCategory community;
  final ValueChanged<SocialCategory> onSaved;

  @override
  ConsumerState<_RulesTab> createState() => _RulesTabState();
}

class _RulesTabState extends ConsumerState<_RulesTab>
    with AutomaticKeepAliveClientMixin {
  static const _maxRules = 15;

  late List<CommunityRule> _rules = [...widget.community.rules];
  bool _dirty = false;
  bool _saving = false;

  @override
  bool get wantKeepAlive => true;

  Future<void> _edit([int? index]) async {
    final rule = await showDialog<CommunityRule>(
      context: context,
      builder: (context) =>
          _RuleDialog(rule: index == null ? null : _rules[index]),
    );
    if (rule == null || !mounted) return;
    setState(() {
      _rules = [..._rules];
      if (index == null) {
        _rules.add(rule);
      } else {
        _rules[index] = rule;
      }
      _dirty = true;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final updated = await ref
          .read(socialApiProvider)
          .updateCommunity(id: widget.community.id, rules: _rules);
      if (!mounted) return;
      widget.onSaved(updated);
      setState(() => _dirty = false);
      _toast(context, l10n.communitySaved);
    } catch (error) {
      if (mounted) _toast(context, _errorText(context, error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = context.riksa;

    return Column(
      children: [
        Expanded(
          child: _rules.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      l10n.communityRulesEmpty,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: palette.inkMuted,
                      ),
                    ),
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  itemCount: _rules.length,
                  onReorderItem: (from, to) => setState(() {
                    _rules = [..._rules];
                    _rules.insert(to, _rules.removeAt(from));
                    _dirty = true;
                  }),
                  itemBuilder: (context, index) {
                    final rule = _rules[index];
                    return Card(
                      key: ObjectKey(rule),
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      color: palette.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadii.mediumBorder,
                        side: BorderSide(color: palette.outline),
                      ),
                      child: ListTile(
                        onTap: () => _edit(index),
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: palette.brand.withValues(alpha: .12),
                          foregroundColor: palette.brand,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        title: Text(rule.title),
                        subtitle: (rule.body ?? '').isEmpty
                            ? null
                            : Text(
                                rule.body!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: l10n.delete,
                              icon: const Icon(Icons.delete_outline_rounded),
                              onPressed: () => setState(() {
                                _rules = [..._rules]..removeAt(index);
                                _dirty = true;
                              }),
                            ),
                            ReorderableDragStartListener(
                              index: index,
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(Icons.drag_handle_rounded),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('manage-add-rule'),
                    onPressed: _rules.length >= _maxRules || _saving
                        ? null
                        : () => _edit(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l10n.communityAddRule),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('manage-save-rules'),
                    onPressed: _dirty && !_saving ? _save : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: Text(l10n.communitySaveChanges),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RuleDialog extends StatefulWidget {
  const _RuleDialog({this.rule});

  final CommunityRule? rule;

  @override
  State<_RuleDialog> createState() => _RuleDialogState();
}

class _RuleDialogState extends State<_RuleDialog> {
  late final _title = TextEditingController(text: widget.rule?.title ?? '');
  late final _body = TextEditingController(text: widget.rule?.body ?? '');

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(
        widget.rule == null ? l10n.communityAddRule : l10n.communityEditRule,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const ValueKey('rule-title'),
            controller: _title,
            autofocus: true,
            maxLength: 100,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l10n.communityRuleTitle),
            onChanged: (_) => setState(() {}),
          ),
          TextField(
            key: const ValueKey('rule-body'),
            controller: _body,
            minLines: 2,
            maxLines: 4,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l10n.communityRuleBody),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _title.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop(
                  CommunityRule(
                    title: _title.text.trim(),
                    body: _body.text.trim().isEmpty ? null : _body.text.trim(),
                  ),
                ),
          child: Text(l10n.communitySaveChanges),
        ),
      ],
    );
  }
}

// ── Members ───────────────────────────────────────────────

enum _MemberAction { promote, demote, remove, ban }

class _MembersTab extends ConsumerStatefulWidget {
  const _MembersTab({required this.community});

  final SocialCategory community;

  @override
  ConsumerState<_MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends ConsumerState<_MembersTab>
    with AutomaticKeepAliveClientMixin {
  List<CommunityMember>? _members;
  bool _failed = false;
  String _query = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final query = _query;
    setState(() => _failed = false);
    try {
      final members = await ref
          .read(socialApiProvider)
          .communityMembers(
            widget.community.id,
            query: query.isEmpty ? null : query,
          );
      if (mounted && query == _query) setState(() => _members = members);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  bool _canAct(CommunityMember member) {
    final mine = widget.community.myRole;
    if (mine == null || member.role == CommunityRole.owner) return false;
    // A moderator can act on members only; the owner on everyone else.
    return mine == CommunityRole.owner || member.role == CommunityRole.member;
  }

  Future<void> _act(CommunityMember member, _MemberAction action) async {
    final l10n = AppLocalizations.of(context)!;
    final api = ref.read(socialApiProvider);
    final name = member.user.displayName.trim().isEmpty
        ? member.user.username
        : member.user.displayName;
    try {
      switch (action) {
        case _MemberAction.promote:
          await api.setCommunityMemberRole(
            widget.community.id,
            member.user.id,
            CommunityRole.moderator,
          );
        case _MemberAction.demote:
          await api.setCommunityMemberRole(
            widget.community.id,
            member.user.id,
            CommunityRole.member,
          );
        case _MemberAction.remove || _MemberAction.ban:
          final ban = action == _MemberAction.ban;
          final reason = await _confirmRemoval(context, name: name, ban: ban);
          if (reason == null) return;
          await api.removeCommunityMember(
            widget.community.id,
            member.user.id,
            ban: ban,
            reason: reason.isEmpty ? null : reason,
          );
      }
      if (!mounted) return;
      _toast(context, l10n.communitySaved);
      _load();
    } catch (error) {
      if (mounted) _toast(context, _errorText(context, error));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final members = _members;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            key: const ValueKey('manage-member-search'),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.communitySearchMembers,
              prefixIcon: const Icon(Icons.search_rounded),
            ),
            onSubmitted: (value) {
              _query = value.trim();
              _load();
            },
          ),
        ),
        Expanded(
          child: members == null
              ? Center(
                  child: _failed
                      ? TextButton(onPressed: _load, child: Text(l10n.tryAgain))
                      : const CircularProgressIndicator(),
                )
              : members.isEmpty
              ? Center(child: Text(l10n.communityNoMembers))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      final owner = widget.community.isOwner;
                      return _PersonTile(
                        key: ValueKey('manage-member-${member.user.id}'),
                        user: member.user,
                        badge: member.role == CommunityRole.member
                            ? null
                            : CommunityRoleBadge(role: member.role),
                        trailing: !_canAct(member)
                            ? null
                            : PopupMenuButton<_MemberAction>(
                                key: ValueKey(
                                  'manage-member-menu-${member.user.id}',
                                ),
                                onSelected: (action) => _act(member, action),
                                itemBuilder: (context) => [
                                  if (owner &&
                                      member.role == CommunityRole.member)
                                    PopupMenuItem(
                                      value: _MemberAction.promote,
                                      child: Text(l10n.communityMakeModerator),
                                    ),
                                  if (owner &&
                                      member.role == CommunityRole.moderator)
                                    PopupMenuItem(
                                      value: _MemberAction.demote,
                                      child: Text(
                                        l10n.communityRemoveModerator,
                                      ),
                                    ),
                                  PopupMenuItem(
                                    value: _MemberAction.remove,
                                    child: Text(l10n.communityRemoveMember),
                                  ),
                                  PopupMenuItem(
                                    value: _MemberAction.ban,
                                    child: Text(
                                      l10n.communityBanMember,
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

/// Asks before removing or banning; returns the reason ('' for none), or
/// null when cancelled.
Future<String?> _confirmRemoval(
  BuildContext context, {
  required String name,
  required bool ban,
}) {
  final l10n = AppLocalizations.of(context)!;
  final reason = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        ban
            ? l10n.communityBanConfirm(name)
            : l10n.communityRemoveConfirm(name),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ban ? l10n.communityBanBody : l10n.communityRemoveBody),
          if (ban) ...[
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('ban-reason'),
              controller: reason,
              maxLength: 200,
              decoration: InputDecoration(labelText: l10n.communityBanReason),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey('confirm-removal'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(reason.text.trim()),
          child: Text(ban ? l10n.communityBan : l10n.communityRemove),
        ),
      ],
    ),
  ).whenComplete(reason.dispose);
}

// ── Bans ──────────────────────────────────────────────────

class _BansTab extends ConsumerStatefulWidget {
  const _BansTab({required this.community});

  final SocialCategory community;

  @override
  ConsumerState<_BansTab> createState() => _BansTabState();
}

class _BansTabState extends ConsumerState<_BansTab> {
  List<CommunityBanEntry>? _bans;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final bans = await ref
          .read(socialApiProvider)
          .communityBans(widget.community.id);
      if (mounted) setState(() => _bans = bans);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _unban(CommunityBanEntry entry) async {
    try {
      await ref
          .read(socialApiProvider)
          .unbanCommunityMember(widget.community.id, entry.user.id);
      if (mounted) _load();
    } catch (error) {
      if (mounted) _toast(context, _errorText(context, error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bans = _bans;
    if (bans == null) {
      return Center(
        child: _failed
            ? TextButton(onPressed: _load, child: Text(l10n.tryAgain))
            : const CircularProgressIndicator(),
      );
    }
    if (bans.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            const SizedBox(height: 120),
            Center(child: Text(l10n.communityNoBans)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: bans.length,
        itemBuilder: (context, index) {
          final entry = bans[index];
          return _PersonTile(
            key: ValueKey('manage-ban-${entry.user.id}'),
            user: entry.user,
            subtitle: entry.reason,
            trailing: OutlinedButton(
              onPressed: () => _unban(entry),
              child: Text(l10n.communityUnban),
            ),
          );
        },
      ),
    );
  }
}

// ── Shared pieces ─────────────────────────────────────────

class _PersonTile extends StatelessWidget {
  const _PersonTile({
    super.key,
    required this.user,
    this.badge,
    this.subtitle,
    this.trailing,
  });

  final SocialAuthor user;
  final Widget? badge;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.riksa;
    final name = user.displayName.trim().isEmpty
        ? user.username
        : user.displayName;
    final line = subtitle ?? '@${user.username}';
    return ListTile(
      onTap: publicProfilePath(user.id) == null
          ? null
          : () => openUserProfile(context, user.id),
      leading: RiksaAvatarImage(
        value: user.avatarUrl,
        label: name,
        size: 40,
        backgroundColor: palette.brand.withValues(alpha: .12),
        foregroundColor: palette.brand,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          if (badge != null) ...[const SizedBox(width: 6), badge!],
        ],
      ),
      subtitle: Text(line, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: trailing,
    );
  }
}

/// A small "Owner" / "Moderator" pill.
class CommunityRoleBadge extends StatelessWidget {
  const CommunityRoleBadge({super.key, required this.role});

  final CommunityRole role;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.riksa;
    final owner = role == CommunityRole.owner;
    final color = owner ? const Color(0xFFE0A100) : palette.brand;
    final label = switch (role) {
      CommunityRole.owner => l10n.communityRoleOwner,
      CommunityRole.moderator => l10n.communityRoleModerator,
      CommunityRole.member => l10n.communityRoleMember,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: AppRadii.fullBorder,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            owner ? Icons.workspace_premium_rounded : Icons.shield_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
