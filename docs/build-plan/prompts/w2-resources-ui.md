# Task
Add a "Resources" section to lessons in the app, where learners browse, open, save, and share study resources.

# Repo
C:\Users\dvdphobia\Desktop\workspaces\RIKSA-FLUTTER, Flutter + Riverpod + go_router + Dio.

# Relevant files
- lib/features/learning/presentation/lesson_experience_screen.dart — the lesson; has a "Lesson options" menu and a "Lesson sections" sheet
- lib/features/learning/presentation/subject_roadmap_screen.dart — roadmap with lesson stones
- lib/features/learning/data/learning_api.dart — API client pattern to copy
- lib/features/auth/presentation/require_account.dart — guest gate
- lib/features/learning/presentation/learning_design.dart — the learning visual language to follow

# Context
The backend is built in parallel against this fixed contract:

GET /api/v1/learning/lessons/{lessonId}/resources?cursor=&limit=20 → `{ "edges": [Resource], "hasNextPage", "endCursor" }` (public; guests get savedByMe=false)
Resource: `{ "id", "lessonId", "title", "url", "kind": "LINK|PDF|VIDEO", "author": { "id", "displayName", "avatarUrl" }, "saveCount", "savedByMe", "createdAt" }`
POST /api/v1/learning/lessons/{lessonId}/resources `{ "title", "url", "kind" }` → Resource (auth; 429 after 10/day)
POST / DELETE /api/v1/resources/{id}/save → Resource (auth)
DELETE /api/v1/resources/{id} (author only)

# Do
1. `lib/features/resources/`: models, api, providers (paged list per lesson, optimistic save toggle with rollback on error, add, delete).
2. A "Resources (N)" entry in the lesson's options menu AND at the end of the lesson (after the last section), opening a sheet/page with the list: kind icon, title, domain, author, save count, save button.
3. Tap opens the URL with the system browser (use url_launcher only if already a dependency; otherwise say so under Risks and add it).
4. "Share a resource" form: title, URL, kind; client validation matching the contract; clear errors for 429.
5. Guests can browse; save and share go through require_account.dart.
6. Empty state that invites the first share (buddy line, l10n).
7. Long-press own resource → delete; others → report (reuse the existing report UI if one exists in lib/, otherwise leave a TODO and list it under Risks).
8. Strings in app_en.arb + app_km.arb with the key prefix `resource`; run `flutter gen-l10n`.
9. Tests with a fake API: list, empty, guest gate on save, optimistic save + rollback, form validation, Khmer 200% text scale.

# Do NOT
- Do not commit, push, rebase, or switch branches.
- Do not touch the bottom navigation bar.
- Do not modify files outside: lib/features/resources/**, lib/features/learning/presentation/lesson_experience_screen.dart (menu entry + end-of-lesson entry only), lib/l10n/**, pubspec.yaml/pubspec.lock (only if url_launcher is missing), test/features/resources/**.
- Do not add other dependencies.

# Deliverable
Changed files, real `flutter analyze` and `flutter test` output, anything needing the real API to verify.

# Risks
End with a "## Risks" section.
