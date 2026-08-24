import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/riksa_avatar_image.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/data/auth_models.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import 'widgets/profile_ui.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  String? _gender;
  String? _avatarPath;
  bool _saving = false;

  AuthUser? get _user {
    final auth = ref.read(authProvider);
    return auth is Authenticated ? auth.user : null;
  }

  @override
  void initState() {
    super.initState();
    final user = _user;
    _nameController = TextEditingController(text: user?.displayName);
    _bioController = TextEditingController(text: user?.bio);
    _gender = user?.gender;
    _avatarPath = user?.avatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.watch(authProvider);
    final user = auth is Authenticated ? auth.user : null;

    return Scaffold(
      backgroundColor: ProfilePalette.canvas(context),
      appBar: AppBar(
        backgroundColor: ProfilePalette.canvas(context),
        centerTitle: true,
        title: Text(
          l10n.editProfile,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
                      children: [
                        Center(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              RiksaProfileAvatar(
                                user: user,
                                radius: 52,
                                avatarPath: _avatarPath,
                              ),
                              PositionedDirectional(
                                end: -2,
                                bottom: 1,
                                child: IconButton.filled(
                                  key: const ValueKey('edit-avatar'),
                                  style: IconButton.styleFrom(
                                    backgroundColor: ProfilePalette.green,
                                    foregroundColor: Colors.black,
                                  ),
                                  onPressed: () => _chooseAvatar(context),
                                  icon: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 19,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        ProfilePanel(
                          child: Column(
                            children: [
                              TextFormField(
                                key: const ValueKey('edit-display-name'),
                                controller: _nameController,
                                maxLength: 100,
                                decoration: InputDecoration(
                                  labelText: l10n.fullName,
                                  prefixIcon: const Icon(Icons.badge_outlined),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return l10n.requiredField;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _bioController,
                                maxLength: 160,
                                minLines: 2,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  labelText: l10n.bio,
                                  prefixIcon: const Icon(Icons.notes_rounded),
                                ),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String?>(
                                initialValue: _gender,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: l10n.gender,
                                  prefixIcon: const Icon(Icons.person_outline),
                                ),
                                items: [
                                  DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text(l10n.genderUnspecified),
                                  ),
                                  const DropdownMenuItem(
                                    value: 'FEMALE',
                                    child: Text('Female'),
                                  ),
                                  const DropdownMenuItem(
                                    value: 'MALE',
                                    child: Text('Male'),
                                  ),
                                  const DropdownMenuItem(
                                    value: 'OTHER',
                                    child: Text('Other'),
                                  ),
                                ],
                                onChanged: (value) => _gender = value,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ProfilePanel(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              _ReadOnlyAccountRow(
                                icon: Icons.alternate_email_rounded,
                                label: l10n.username,
                                value: '@${user.username}',
                              ),
                              Divider(
                                height: 1,
                                indent: 58,
                                color: ProfilePalette.border(context),
                              ),
                              _ReadOnlyAccountRow(
                                icon: Icons.email_outlined,
                                label: l10n.email,
                                value: user.email ?? l10n.notProvided,
                              ),
                              Divider(
                                height: 1,
                                indent: 58,
                                color: ProfilePalette.border(context),
                              ),
                              _ReadOnlyAccountRow(
                                icon: Icons.phone_outlined,
                                label: l10n.phoneNumber,
                                value: user.phoneNumber ?? l10n.notProvided,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.accountIdentifiersReadOnly,
                          style: TextStyle(
                            color: ProfilePalette.muted(context),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          key: const ValueKey('save-profile'),
                          style: FilledButton.styleFrom(
                            backgroundColor: ProfilePalette.green,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(l10n.saveChanges),
                        ),
                        const SizedBox(height: 34),
                        TextButton(
                          key: const ValueKey('delete-account'),
                          style: TextButton.styleFrom(
                            foregroundColor: ProfilePalette.muted(context),
                            backgroundColor: ProfilePalette.panel(context),
                            minimumSize: const Size.fromHeight(50),
                          ),
                          onPressed: () => _confirmDelete(context),
                          child: Text(l10n.deleteAccount),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final success = await ref
        .read(authProvider.notifier)
        .updateProfile(
          UpdateProfileRequest(
            displayName: _nameController.text.trim(),
            bio: _bioController.text.trim(),
            gender: _gender,
            avatarUrl: _avatarPath,
          ),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? l10n.changesSaved : l10n.profileSaveFailed),
      ),
    );
    if (success) ref.invalidate(profileDashboardProvider);
  }

  Future<void> _chooseAvatar(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final user = _user;
    if (user == null) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: ProfilePalette.panel(context),
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: .72,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.chooseAvatar,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: ProfilePalette.greenSoft(context),
                        borderRadius: AppRadii.smallBorder,
                      ),
                      child: const Text(
                        'Humation',
                        style: TextStyle(
                          color: ProfilePalette.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  l10n.humationAvatarSubtitle,
                  style: TextStyle(
                    color: ProfilePalette.muted(context),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    key: const ValueKey('humation-avatar-grid'),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 11,
                          crossAxisSpacing: 11,
                        ),
                    itemCount: humationAvatarCount,
                    itemBuilder: (context, index) {
                      final path = humationAvatarValue(index);
                      final selected = path == _avatarPath;
                      return Semantics(
                        button: true,
                        selected: selected,
                        label: '${l10n.chooseAvatar} ${index + 1}',
                        child: Material(
                          color: selected
                              ? ProfilePalette.greenSoft(context)
                              : ProfilePalette.panelSoft(context),
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadii.mediumBorder,
                            side: BorderSide(
                              color: selected
                                  ? ProfilePalette.green
                                  : ProfilePalette.border(context),
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: InkWell(
                            key: ValueKey('humation-avatar-option-$index'),
                            onTap: () => Navigator.of(sheetContext).pop(path),
                            child: Stack(
                              children: [
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: RiksaAvatarImage(
                                      value: path,
                                      label: user.displayName,
                                      size: 66,
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: ProfilePalette.text(
                                        context,
                                      ),
                                    ),
                                  ),
                                ),
                                if (selected)
                                  const PositionedDirectional(
                                    top: 5,
                                    end: 5,
                                    child: CircleAvatar(
                                      radius: 9,
                                      backgroundColor: ProfilePalette.green,
                                      child: Icon(
                                        Icons.check_rounded,
                                        size: 13,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (selected != null && mounted) setState(() => _avatarPath = selected);
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteAccountTitle),
        content: Text(l10n.deleteAccountConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.continueLabel),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.deleteUnavailable)));
    }
  }
}

class _ReadOnlyAccountRow extends StatelessWidget {
  const _ReadOnlyAccountRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: ProfilePalette.muted(context)),
    title: Text(
      label,
      style: TextStyle(color: ProfilePalette.muted(context), fontSize: 12),
    ),
    subtitle: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
    trailing: Icon(
      Icons.lock_outline_rounded,
      color: ProfilePalette.muted(context),
      size: 17,
    ),
  );
}
