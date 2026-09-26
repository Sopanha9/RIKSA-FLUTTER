import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/presentation/require_account.dart';
import '../../auth/providers/auth_provider.dart';
import '../../mascot/domain/mascot.dart';
import '../../mascot/presentation/widgets/mascot_face.dart';
import '../data/resource_models.dart';
import '../providers/lesson_resources_provider.dart';

void showLessonResourcesSheet(
  BuildContext routeContext, {
  required String lessonId,
  required String lessonTitle,
}) {
  showModalBottomSheet<void>(
    context: routeContext,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _LessonResourcesSheet(
      routeContext: routeContext,
      lessonId: lessonId,
      lessonTitle: lessonTitle,
    ),
  );
}

class _LessonResourcesSheet extends ConsumerWidget {
  const _LessonResourcesSheet({
    required this.routeContext,
    required this.lessonId,
    required this.lessonTitle,
  });

  final BuildContext routeContext;
  final String lessonId;
  final String lessonTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final resources = ref.watch(lessonResourcesProvider(lessonId));
    final userId = ref.watch(currentUserIdProvider);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .86,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.resourceSectionTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lessonTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  key: const ValueKey('resource-share-open'),
                  tooltip: l10n.resourceShareAction,
                  onPressed: () => _openShareForm(context, ref, l10n),
                  icon: const Icon(Icons.add_link_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: resources.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: TextButton.icon(
                  onPressed: () =>
                      ref.invalidate(lessonResourcesProvider(lessonId)),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.resourceLoadFailed),
                ),
              ),
              data: (page) {
                if (page.resources.isEmpty) {
                  return _EmptyResources(
                    onShare: () => _openShareForm(context, ref, l10n),
                  );
                }
                return NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification.metrics.extentAfter < 180 &&
                        page.hasNextPage &&
                        !page.loadingMore) {
                      ref
                          .read(lessonResourcesProvider(lessonId).notifier)
                          .loadMore();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    key: const ValueKey('lesson-resource-list'),
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                    itemCount:
                        page.resources.length + (page.loadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == page.resources.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final resource = page.resources[index];
                      return _ResourceRow(
                        resource: resource,
                        isOwner: userId == resource.author.id,
                        onOpen: () => _openResource(context, resource),
                        onSave: () => _toggleSave(context, ref, resource, l10n),
                        onLongPress: () =>
                            _showResourceActions(context, ref, resource, l10n),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleSave(
    BuildContext context,
    WidgetRef ref,
    LessonResource resource,
    AppLocalizations l10n,
  ) async {
    if (!requireAccount(routeContext, ref, reason: 'save_resource')) return;
    try {
      await ref
          .read(lessonResourcesProvider(lessonId).notifier)
          .toggleSave(resource);
    } catch (_) {
      if (context.mounted) _showMessage(context, l10n.resourceSaveFailed);
    }
  }

  Future<void> _openShareForm(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    if (!requireAccount(routeContext, ref, reason: 'share_resource')) return;
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) =>
          _ResourceShareForm(routeContext: routeContext, lessonId: lessonId),
    );
  }

  Future<void> _openResource(
    BuildContext context,
    LessonResource resource,
  ) async {
    try {
      final opened = await launchUrl(
        Uri.parse(resource.url),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && context.mounted) {
        _showMessage(context, AppLocalizations.of(context)!.resourceOpenFailed);
      }
    } catch (_) {
      if (context.mounted) {
        _showMessage(context, AppLocalizations.of(context)!.resourceOpenFailed);
      }
    }
  }

  Future<void> _showResourceActions(
    BuildContext context,
    WidgetRef ref,
    LessonResource resource,
    AppLocalizations l10n,
  ) async {
    final isOwner = ref.read(currentUserIdProvider) == resource.author.id;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            if (isOwner)
              ListTile(
                key: const ValueKey('resource-delete-action'),
                leading: const Icon(Icons.delete_outline_rounded),
                title: Text(l10n.resourceDeleteAction),
                onTap: () => Navigator.pop(sheetContext, 'delete'),
              )
            else
              ListTile(
                key: const ValueKey('resource-report-action'),
                leading: const Icon(Icons.flag_outlined),
                title: Text(l10n.resourceReportAction),
                onTap: () => Navigator.pop(sheetContext, 'report'),
              ),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;
    if (action == 'report') {
      if (!requireAccount(routeContext, ref, reason: 'report_resource')) return;
      final confirm = await _confirm(context, l10n.resourceReportConfirm);
      if (confirm != true || !context.mounted) return;
      try {
        await ref.read(resourcesRepositoryProvider).report(resource.id);
        if (context.mounted) _showMessage(context, l10n.resourceReportSent);
      } catch (_) {
        if (context.mounted) _showMessage(context, l10n.resourceReportFailed);
      }
    } else if (action == 'delete') {
      if (!requireAccount(routeContext, ref, reason: 'delete_resource')) return;
      final confirm = await _confirm(context, l10n.resourceDeleteConfirm);
      if (confirm != true || !context.mounted) return;
      try {
        await ref
            .read(lessonResourcesProvider(lessonId).notifier)
            .delete(resource.id);
      } catch (_) {
        if (context.mounted) _showMessage(context, l10n.resourceDeleteFailed);
      }
    }
  }

  Future<bool?> _confirm(BuildContext context, String message) =>
      showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(AppLocalizations.of(context)!.resourceConfirm),
            ),
          ],
        ),
      );
}

class _EmptyResources extends StatelessWidget {
  const _EmptyResources({required this.onShare});
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MascotFaceAvatar(face: MascotFace.happy, size: 74, loops: 1),
            const SizedBox(height: 14),
            Text(
              l10n.resourceEmptyTitle,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.resourceEmptyBody,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.riksa.inkMuted),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const ValueKey('resource-empty-share'),
              onPressed: onShare,
              icon: const Icon(Icons.add_link_rounded),
              label: Text(l10n.resourceShareAction),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResourceRow extends StatelessWidget {
  const _ResourceRow({
    required this.resource,
    required this.isOwner,
    required this.onOpen,
    required this.onSave,
    required this.onLongPress,
  });

  final LessonResource resource;
  final bool isOwner;
  final VoidCallback onOpen;
  final VoidCallback onSave;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final kindIcon = switch (resource.kind) {
      LessonResourceKind.link => Icons.link_rounded,
      LessonResourceKind.pdf => Icons.picture_as_pdf_outlined,
      LessonResourceKind.video => Icons.play_circle_outline_rounded,
    };
    return GestureDetector(
      onLongPress: onLongPress,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        child: ListTile(
          onTap: onOpen,
          leading: CircleAvatar(child: Icon(kindIcon)),
          title: Text(
            resource.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${resource.domain}\n${resource.author.displayName} · ${l10n.resourceSaveCount(resource.saveCount)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          isThreeLine: true,
          trailing: IconButton(
            key: ValueKey('resource-save-${resource.id}'),
            tooltip: resource.savedByMe
                ? l10n.resourceUnsaveAction
                : l10n.resourceSaveAction,
            onPressed: onSave,
            icon: Icon(
              resource.savedByMe
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
            ),
          ),
        ),
      ),
    );
  }
}

class _ResourceShareForm extends ConsumerStatefulWidget {
  const _ResourceShareForm({
    required this.routeContext,
    required this.lessonId,
  });
  final BuildContext routeContext;
  final String lessonId;

  @override
  ConsumerState<_ResourceShareForm> createState() => _ResourceShareFormState();
}

class _ResourceShareFormState extends ConsumerState<_ResourceShareForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _url = TextEditingController();
  LessonResourceKind _kind = LessonResourceKind.link;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .76,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.resourceShareTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('resource-title-input'),
                controller: _title,
                maxLength: 120,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l10n.resourceTitleLabel),
                validator: (value) =>
                    ResourceShareRules.titleError(value ?? '') == null
                    ? null
                    : l10n.resourceTitleError,
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const ValueKey('resource-url-input'),
                controller: _url,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: l10n.resourceUrlLabel,
                  hintText: 'https://',
                ),
                validator: (value) =>
                    ResourceShareRules.urlError(value ?? '') == null
                    ? null
                    : l10n.resourceUrlError,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<LessonResourceKind>(
                initialValue: _kind,
                decoration: InputDecoration(labelText: l10n.resourceKindLabel),
                items: [
                  DropdownMenuItem(
                    value: LessonResourceKind.link,
                    child: Text(l10n.resourceKindLink),
                  ),
                  DropdownMenuItem(
                    value: LessonResourceKind.pdf,
                    child: Text(l10n.resourceKindPdf),
                  ),
                  DropdownMenuItem(
                    value: LessonResourceKind.video,
                    child: Text(l10n.resourceKindVideo),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _kind = value);
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                key: const ValueKey('resource-share-submit'),
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const CircularProgressIndicator()
                    : Text(l10n.resourceShareAction),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!requireAccount(widget.routeContext, ref, reason: 'share_resource')) {
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(lessonResourcesProvider(widget.lessonId).notifier)
          .create(title: _title.text, url: _url.text, kind: _kind);
      if (mounted) Navigator.of(context).pop(true);
    } on DioException catch (error) {
      if (!mounted) return;
      setState(
        () => _error = error.response?.statusCode == 429
            ? l10n.resourceRateLimit
            : l10n.resourceShareFailed,
      );
    } catch (_) {
      if (mounted) setState(() => _error = l10n.resourceShareFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
