import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/riksa_avatar_image.dart';

class RankingListRow extends StatelessWidget {
  const RankingListRow({
    super.key,
    required this.rank,
    required this.name,
    required this.subtitle,
    required this.xp,
    required this.avatarLabel,
    this.avatarUrl,
    this.isCurrentUser = false,
    this.onTap,
  });

  final int rank;
  final String name;
  final String subtitle;
  final int xp;
  final String avatarLabel;
  final String? avatarUrl;
  final bool isCurrentUser;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isCurrentUser ? const Color(0xFFFFF9FC) : Colors.white,
      borderRadius: AppRadii.largeBorder,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.largeBorder,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: AppRadii.largeBorder,
            border: Border.all(
              color: isCurrentUser ? AppColors.editorialPink : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              // Left-aligned fixed width rank column
              SizedBox(
                width: 34,
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: isCurrentUser
                        ? AppColors.editorialPink
                        : const Color(0xFF70695E),
                  ),
                ),
              ),

              // Avatar
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCurrentUser
                        ? AppColors.editorialPink
                        : AppColors.brandJade,
                    width: 2,
                  ),
                ),
                child: RiksaAvatarImage(
                  value: avatarUrl,
                  label: avatarLabel,
                  size: 34,
                  backgroundColor: const Color(0xFFF2EFE9),
                  foregroundColor: const Color(0xFF121212),
                ),
              ),

              const SizedBox(width: 10),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF121212),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.ink,
                              borderRadius: AppRadii.smallBorder,
                            ),
                            child: const Text(
                              'YOU',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF70695E),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // XP pill: pink for current user, black for default
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isCurrentUser ? AppColors.editorialPink : AppColors.ink,
                  borderRadius: AppRadii.fullBorder,
                ),
                child: Text(
                  '$xp XP',
                  style: TextStyle(
                    color: isCurrentUser ? AppColors.ink : Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Action arrow button
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isCurrentUser
                      ? AppColors.ink
                      : AppColors.editorialPinkSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: isCurrentUser ? Colors.white : AppColors.ink,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
