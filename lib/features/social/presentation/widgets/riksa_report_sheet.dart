import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/social_api.dart';
import '../../providers/social_feed_provider.dart';

/// Shows the moderation report sheet for any post, comment, or blog article.
Future<void> showRiksaReportSheet(
  BuildContext context, {
  required String targetType,
  required String targetId,
  String? targetTitle,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  backgroundColor: Theme.of(context).colorScheme.surface,
  constraints: const BoxConstraints(maxWidth: 640),
  builder: (context) => RiksaReportSheet(
    targetType: targetType,
    targetId: targetId,
    targetTitle: targetTitle,
  ),
);

class RiksaReportSheet extends ConsumerStatefulWidget {
  const RiksaReportSheet({
    super.key,
    required this.targetType,
    required this.targetId,
    this.targetTitle,
  });

  final String targetType;
  final String targetId;
  final String? targetTitle;

  @override
  ConsumerState<RiksaReportSheet> createState() => _RiksaReportSheetState();
}

class _RiksaReportSheetState extends ConsumerState<RiksaReportSheet> {
  final _detailsCtrl = TextEditingController();
  String _selectedReason = 'SPAM';
  bool _submitting = false;

  static const _reasons = [
    (
      'SPAM',
      'Spam or unwanted advertising',
      'សារឥតបានការ ឬការផ្សាយពាណិជ្ជកម្មរំខាន',
    ),
    (
      'HARASSMENT',
      'Harassment or abusive speech',
      'ការបៀតបៀន ឬពាក្យប្រមាថ',
    ),
    (
      'NSFW',
      'Inappropriate or explicit content',
      'ខ្លឹមសារមិនសមរម្យ ឬរសើប',
    ),
    (
      'MISINFORMATION',
      'Misinformation or false claims',
      'ព័ត៌មានមិនពិត ឬបំភ័ន្តការពិត',
    ),
    (
      'OTHER',
      'Other violation',
      'ការបំពានផ្សេងទៀត',
    ),
  ];

  @override
  void dispose() {
    _detailsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final isKm = Localizations.localeOf(context).languageCode == 'km';
    try {
      await ref.read(socialApiProvider).fileReport(
        targetType: widget.targetType,
        targetId: widget.targetId,
        reason: _selectedReason,
        details: _detailsCtrl.text.trim().isEmpty ? null : _detailsCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isKm
                ? 'ការរាយការណ៍ត្រូវបានផ្ញើជូនក្រុមត្រួតពិនិត្យ។ សូមអរគុណ!'
                : 'Report submitted for review. Thank you for keeping Riksa safe!',
          ),
          backgroundColor: context.riksa.jadeStrong,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      final message = e is SocialApiException ? e.message : e.toString();
      final isAlreadyReported = message.toLowerCase().contains('already reported');
      if (isAlreadyReported) {
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isKm
                  ? 'អ្នកបានរាយការណ៍ខ្លឹមសារនេះរួចហើយ។'
                  : 'You have already reported this content.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.riksa;
    final isKm = Localizations.localeOf(context).languageCode == 'km';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: palette.blushSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.flag_rounded,
                      color: theme.colorScheme.error,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isKm ? 'រាយការណ៍ខ្លឹមសារ' : 'Report Content',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (widget.targetTitle?.isNotEmpty == true) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.targetTitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: palette.inkMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                isKm
                    ? 'សូមជ្រើសរើសមូលហេតុដែលអ្នករាយការណ៍៖'
                    : 'Why are you reporting this content?',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ..._reasons.map((item) {
                final (key, enLabel, kmLabel) = item;
                final label = isKm ? kmLabel : enLabel;
                final selected = _selectedReason == key;
                return InkWell(
                  key: ValueKey('report-reason-$key'),
                  onTap: () => setState(() => _selectedReason = key),
                  borderRadius: AppRadii.mediumBorder,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: selected ? palette.brandSoft.withValues(alpha: .3) : Colors.transparent,
                      borderRadius: AppRadii.mediumBorder,
                      border: Border.all(
                        color: selected ? palette.brand : palette.outline.withValues(alpha: .5),
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                          size: 20,
                          color: selected ? palette.brand : palette.inkMuted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                              color: selected ? palette.ink : palette.inkMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
              Text(
                isKm ? 'ព័ត៌មានបន្ថែម (ជម្រើស)' : 'Additional details (optional)',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: palette.inkMuted,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                key: const ValueKey('report-details-input'),
                controller: _detailsCtrl,
                maxLines: 3,
                maxLength: 1000,
                decoration: InputDecoration(
                  hintText: isKm
                      ? 'ពិពណ៌នាបន្ថែមអំពីបញ្ហានេះ...'
                      : 'Provide extra context to help our moderators...',
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                    child: Text(isKm ? 'បោះបង់' : 'Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    key: const ValueKey('report-submit-button'),
                    onPressed: _submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: Colors.white,
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(isKm ? 'ផ្ញើការរាយការណ៍' : 'Submit Report'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
