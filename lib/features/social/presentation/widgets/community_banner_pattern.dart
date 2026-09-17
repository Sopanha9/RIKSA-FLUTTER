import 'package:flutter/material.dart';

import '../../../learning/presentation/learning_design.dart';

/// Faint, rotated subject glyphs scattered across a community banner.
class CommunityBannerPattern extends StatelessWidget {
  const CommunityBannerPattern({
    super.key,
    required this.subject,
    required this.color,
  });

  final StemSubject subject;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final icon = stemSubjectIcon(subject);
    return ClipRect(
      child: OverflowBox(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: Transform.rotate(
          angle: -.25,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var row = 0; row < 6; row++)
                Padding(
                  padding: EdgeInsets.only(left: row.isEven ? 0 : 44),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var col = 0; col < 12; col++)
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Icon(
                            icon,
                            size: 32,
                            color: color.withValues(alpha: .16),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
