# Task
Build the buddy market (browse, try on, buy with XP) and the wardrobe (equip owned items), reachable from the buddy panel and the profile — not from the bottom nav bar.

# Repo
C:\Users\dvdphobia\Desktop\workspaces\RIKSA-FLUTTER, branch `staging`. Flutter, Riverpod 3, go_router, Dio.

# Relevant files
- lib/features/mascot/presentation/widgets/buddy_look.dart — `BuddyLook` (species, face/mood, equipped map, size) with vector placeholders when item PNGs are missing (Wave 4).
- lib/features/mascot/data/buddy_api.dart, lib/features/mascot/providers/** — `buddyLookProvider`, `equip(slot, itemId?)` with optimistic update (Wave 4).
- lib/features/mascot/presentation/widgets/floating_buddy.dart + buddy_panel/** — the quest panel (Wave 3); the weekly chest can return `rewardItem`.
- lib/features/userProfile/presentation/user_profile_screen.dart — own profile; add an entry point near the buddy/XP area (read the screen first; keep its layout).
- lib/features/userProfile/data/profile_models.dart — `GamificationProfile` (`totalXp` …; add `xpBalance`).
- lib/app/router/app_router.dart — add routes (signed-in only; guests are sent through `require_account.dart`).
- lib/features/auth/presentation/require_account.dart; lib/core/theme/app_theme.dart (`context.riksa`, reduced motion).

# Context
API (live after Wave 4; use a fake in tests):
- `GET /api/v1/market/items?slot=HAT|EYEWEAR` → `{ "balance", "items": [ { "id", "slot", "name", "nameKm", "price", "rarity": "COMMON|RARE|EPIC", "assetKey", "owned", "equipped", "locked", "lockReason", "availableUntil" } ] }`
- `POST /api/v1/market/items/{id}/purchase` with header `Idempotency-Key: <uuid>` → `{ "item", "balance" }`; errors `{ "code", "message" }`: 409 `INSUFFICIENT_BALANCE` / `ALREADY_OWNED`, 410 `NOT_AVAILABLE`, 403 `LOCKED`. Retrying with the same key never double-charges.
- `PUT /api/v1/buddy/me/equipped` `{ "slot", "itemId" | null }`; `GET /api/v1/gamification/me` has `xpBalance`.
Spending lowers only the spendable balance — rank and total XP never drop. Say so in the UI once ("Spending XP never lowers your rank").

# Do
1. `lib/features/market/`: models, `MarketApi`, providers (`marketItemsProvider(slot)`, `purchase(item)` generating one idempotency key per purchase attempt and reusing it on retry, refreshing balance + buddy + gamification profile after success). Providers watch `currentUserIdProvider` (Wave 1 pattern).
2. **Market screen** `/market`: big live `BuddyLook` preview at top (current equipped + the item being tried on), balance chip, the "never lowers your rank" note, slot tabs (Hats / Glasses), grid of item cards (art or placeholder via `BuddyLook`-style item render, name in the current language, price, rarity accent, owned/equipped badges, availability countdown if `availableUntil`). Tap a card → try it on in the preview (no purchase). A bottom action: `Buy for 300 XP` / `Equip` / `Equipped` / `Not enough XP (need 60 more)` / locked reason.
3. **Buy confirmation sheet**: item, price, balance after; confirm → purchase; success → celebrate (buddy happy/celebrate face, light haptic, small confetti; reduced motion → static) and offer `Wear it now`. Map each error code to a friendly localized message; on network failure allow retry with the same key.
4. **Wardrobe** `/market/wardrobe`: owned items by slot, tap to equip/unequip with optimistic update + rollback, preview on top.
5. **Entry points**: a "Spend XP · 1,240" link in the buddy panel footer, a market button on the own-profile screen near XP, and the chest result ("You got Straw hat! Wear it") linking to the wardrobe. No new bottom-nav tab.
6. Guests: market is browsable in preview mode with sample balance hidden and buy buttons routing to `requireAccount`.
7. Strings: prefixes `market…`, `wardrobe…` (en + km draft).
8. Tests (fake APIs): list + slot filter; try-on doesn't call the API; buy success updates balance and owned state; each error code message; retry after a network error sends the same Idempotency-Key; double tap on confirm sends one request; equip/unequip optimistic + rollback; guest gating; entry points navigate; Khmer at 200% text scale without overflow; goldens for market (light/dark) and wardrobe.

# Do NOT
- Do not commit, push, rebase, or switch branches.
- Do not modify the bottom navigation bar or add a nav tab.
- Do not change `BuddyLook` rendering rules or anchors (only use them); if a change is truly needed, keep it minimal and explain it.
- Do not modify files outside: lib/features/market/** (new), lib/app/router/app_router.dart (routes only), lib/features/mascot/presentation/widgets/buddy_panel/** + floating_buddy.dart (entry link + chest result link only), lib/features/userProfile/presentation/user_profile_screen.dart (entry button only), lib/features/userProfile/data/profile_models.dart (`xpBalance`), lib/l10n/**, test/features/market/**, related tests/goldens.
- Do not add dependencies without stating so.

# Deliverable
Changed files, the real output of `flutter analyze` and `flutter test`, a description of each screen state (golden list), and anything needing the real API or a device to verify.

# Risks
End with a "## Risks" section.
