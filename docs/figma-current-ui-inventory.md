# Figma current-UI inventory — Riksa

Generated: 2026-09-20
Source: ui_map.json + screenshots/ (not FIGMA_MAKE_PROMPTS.md)

## Totals
- Mapped screens in ui_map: **35**
- Capture screenshots/: **200**
- screenshots_redesign_reference/: **26** (ignore for current-UI rebuild)

## All screens (from ui_map)

### Launch / onboarding / auth
| Type | Route | Name |
|------|-------|------|
| launch | /splash | Splash |
| onboarding | /language-select | Language Select |
| onboarding | /onboarding | Onboarding (3 pages) |
| onboarding | /province-select | Province Select |
| auth | /auth/login | Login / Register switcher |
| auth | /auth/register | Register (deep link) |
| auth | /auth/recover | Account Recovery |
| auth | /auth/verify-email?token= | Email Verification |
| auth | /auth/telegram?register=true|false | Telegram OTP |

### Home / community / blog
| Type | Route | Name |
|------|-------|------|
| tabRoot | /home | Community Feed (Home) |
| pushed | /dashboard | Home Dashboard |
| pushed | /communities | Communities |
| pushed | /progress | Progress History |
| pushed | /community/create?type=question | Compose Community Post / Question |
| pushed | /community/posts/:id/edit | Edit Community Post |
| pushed | /community/posts/:id | Community Post Detail |
| pushed | /blog | Blog Feed |
| pushed | /blog/create | Blog Composer |
| pushed | /blog/:id/edit | Blog Edit |
| pushed | /blog/my-posts | My Posts |
| pushed | /blog/:id | Blog Detail |

### Learn
| Type | Route | Name |
|------|-------|------|
| tabRoot | /learn | Learning Home |
| pushed | /learn/saved | Saved Lessons |
| pushed | /learn/resume | Resume Learning |
| pushed | /learn/roadmap/:categoryId | Subject Roadmap |
| pushed | /learn/:id | Lesson Player |
| pushed | /learn/completion?roadmapCategoryId= | Lesson Completion |

### AI / leaderboard / profile
| Type | Route | Name |
|------|-------|------|
| tabRoot | /ai | AI Tutor |
| pushed | /ai/chat/:id | AI Chat |
| tabRoot | /leaderboard | Leaderboard |
| tabRoot | /profile | My Profile |
| pushed | /profile/settings | Settings |
| pushed | /profile/edit | Edit Profile |
| pushed | /profile/setup | Profile Setup Overview |
| standalone | /profile/:userId | Public Profile |

## Priority batch for first Figma frames (current UI)
1. Splash
2. Language Select
3. Onboarding (3 pages as 3 frames)
4. Login
5. Register
6. Home feed (default + nav collapsed)
7. Learning Home
8. Subject Roadmap
9. Lesson Player
10. Lesson Completion
11. AI Tutor list + AI Chat
12. Profile + Settings

## Blocker
Box browser cannot open the Figma file (CloudFront 403). Rebuild into Figma requires either public edit link that works from this environment, or user-side import of assets.
