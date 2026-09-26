# Task
Connect social to learning: the server posts a learner's milestones (streaks, rank-ups, finished units) to the feed, and the app shows them as celebration cards.

# Repos
- API: C:\Users\dvdphobia\Desktop\workspaces\RIKSA (Spring Boot, GraphQL schema in src/main/resources/graphql/social.graphqls). Read AGENTS.md first.
- App: C:\Users\dvdphobia\Desktop\workspaces\RIKSA-FLUTTER (Flutter + Riverpod).
You are running in ONE of these repos (the one passed with -C). Do only that repo's half, described below.

# Relevant files
API:
- src/main/java/com/riksa/social/entity/Post.java, dto/PostResponse.java, dto/SocialMapper.java
- src/main/resources/graphql/social.graphqls — `type Post`, `feed(...)`
- src/main/java/com/riksa/gamification/event/StreakUpdatedEvent.java, RankChangedEvent.java; StreakMilestone entity
- src/main/java/com/riksa/learning/event/LessonCompletedEvent.java; roadmap units in RoadmapUnit / RoadmapService
- src/main/java/com/riksa/auth/dto/UpdateProfileRequest.java — profile settings
App:
- lib/features/social/data/social_models.dart, social_api.dart
- lib/features/social/presentation/widgets/social_post_card.dart
- lib/features/userProfile/presentation/profile_settings_screen.dart

# Context
Fixed contract:
- GraphQL: `enum PostKind { USER MILESTONE }`, `Post.kind: PostKind!` (existing posts = USER), `Post.milestone: Milestone` where `type Milestone { type: MilestoneType!, title: String!, titleKm: String!, value: Int }` and `enum MilestoneType { STREAK RANK_UP UNIT_COMPLETE }`.
- Created only for: reaching a StreakMilestone, a rank-up, finishing the last lesson of a roadmap unit. Never for single lessons.
- Opt-out: `shareMilestones: Boolean` on the profile (default true), settable via the existing profile update.
- Milestone posts need a home: if posts require a category, seed a system category "Wins / ជ័យជម្នះ" and post there; users can react and comment like any post but cannot edit it.

# Do — API half (-C RIKSA)
1. Migration V37 (V35 quests, V36 resources are taken): post.kind, post.milestone_* columns, user share_milestones, system category if needed.
2. Listener(s) with @TransactionalEventListener(AFTER_COMMIT) creating MILESTONE posts; idempotent per (user, type, value).
3. Expose kind + milestone in GraphQL and mapper; reject updatePost on MILESTONE posts.
4. Tests for each trigger, opt-out, idempotency, update rejection.

# Do — App half (-C RIKSA-FLUTTER)
1. Parse `kind` and `milestone` in social_models.dart (default USER when absent so older servers still work) and request them in the feed/post queries.
2. A `MilestonePostCard` variant in social_post_card.dart: big emoji/icon per type, "Dara hit a 7-day streak 🔥", reactions and comments as usual, no edit menu.
3. "Share my milestones" switch in profile settings.
4. Strings with key prefix `milestone` in app_en.arb + app_km.arb; `flutter gen-l10n`.
5. Widget tests for each milestone type, missing-kind fallback, Khmer 200% text scale.

# Do NOT
- Do not commit, push, rebase, or switch branches.
- API: do not modify files outside src/main/java/com/riksa/social/**, the new listener package, src/main/resources/graphql/social.graphqls, V37 migration, UpdateProfileRequest + its user entity/mapper field, src/test/java/**/milestone*/**.
- App: do not modify files outside lib/features/social/data/**, lib/features/social/presentation/widgets/social_post_card.dart (+ a new milestone_post_card.dart), profile_settings_screen.dart (one switch), lib/l10n/**, test/features/social/**.
- Do not touch the bottom navigation bar.

# Deliverable
Changed files and real test output for your half.

# Risks
End with a "## Risks" section.
