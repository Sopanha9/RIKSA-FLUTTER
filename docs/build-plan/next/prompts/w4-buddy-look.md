# Task
Make the server the source of truth for the signed-in user's buddy, and add one `BuddyLook` widget that draws the buddy's face/head with equipped items (hat, glasses) everywhere the buddy appears.

# Repo
C:\Users\dvdphobia\Desktop\workspaces\RIKSA-FLUTTER, branch `staging`. Flutter, Riverpod 3, Dio.

# Relevant files
- lib/features/mascot/data/buddy_api.dart — `BuddyMe` (`GET/PUT /buddy/me`), `BuddyApi`.
- lib/features/mascot/providers/buddy_care_provider.dart — per-user sync of buddy care/species/name; caches the server buddy per user in SharedPreferences (`_signedInKeyPrefix`); pushes guest buddy to a new account once.
- lib/features/mascot/providers/mascot_provider.dart — species/name (guest keys after Wave 1).
- lib/features/mascot/domain/mascot.dart — species, moods, `MascotFace`, frame lists.
- lib/features/mascot/presentation/widgets/{mascot_face.dart, mascot_view.dart, sprite_frames.dart, floating_buddy.dart, buddy_companion.dart, buddy_care_card.dart} — current renderers. The floating head was redesigned in Wave 3 (face with no circle, panel from head); its head rendering is in one small widget — swap it to `BuddyLook`.
- assets/images/mascots/<species>/faces/*.png — transparent face frames (~138×101 croc, ~118×92 capybara), 80 per species; assets/images/mascots/<species>/*.png — ~72 body frames.
- Public buddy look arrives on public profile and leaderboard DTOs (see contract); their app models live in lib/features/userProfile/data/public_profile.dart and lib/features/leaderBoard/** / profile_models.dart.

# Context
Decisions: v1 items are **head items only** — slots `HAT` and `EYEWEAR`. Item art is bundled at `assets/images/market/<assetKey>/<species>.png`; placement uses per-species anchor JSON. The item art may not exist yet when you run — the widget must work with **vector placeholders** until PNGs are added. Body clothing is later; don't build it.

API (built in parallel — use a fake in tests):
- `GET /api/v1/buddy/me` → existing fields plus `"equipped": { "HAT": { "itemId", "assetKey" }, "EYEWEAR": {…} }` and `"balance"`.
- `PUT /api/v1/buddy/me/equipped` `{ "slot", "itemId" | null }` → the updated buddy.
- Public look: `"buddy": { "species", "name", "equipped": { "HAT": "hat_straw" } } | null` on the public profile response and on each leaderboard entry.

# Do
1. **Models:** `BuddyEquipped` (slot → assetKey/itemId); extend `BuddyMe` + `BuddyApi` (`equip(slot, itemId?)`); `PublicBuddyLook` parsed from public profile + leaderboard entries (null-safe; old servers without the field still parse).
2. **Pick a buddy once per account:** `GET /buddy/me` now returns `"chosen": true|false` (false = the server's silent default crocodile). After sign-in/sign-up completes and the buddy is loaded: if `chosen == false` and there is **no** local guest pick to send, route to `/mascot-select` once, before the normal landing, with the current default pre-selected (one tap to confirm) and no way to get stuck (back = keep default and mark chosen via PUT). If a guest pick exists, the existing guest merge sends it and no picker is shown. If `chosen == true`, never show the picker and never overwrite. Old servers without the field → treat as `true`. Tests: register directly from login (no first run) → picker shown once, then never again; guest first run → sign up → no picker; existing account on a new device → no picker; back from picker → default kept and `chosen` becomes true.
3. **Server-first:** for signed-in users the server buddy (species, name, equipped) is the truth; SharedPreferences is only a per-user cache shown instantly then replaced. Guest → account sign-up still sends the guest buddy **once, only when the server has no buddy yet** (never overwrite an existing account's buddy). Add `buddyLookProvider` (current user's look) and an `equip` action with optimistic update + rollback on error.
4. **Anchors:** `assets/images/market/anchors/<species>.json`:
   ```json
   { "version": 1,
     "face": { "default": { "HAT": {"x":0.5,"y":0.06,"w":0.62,"rot":0}, "EYEWEAR": {"x":0.5,"y":0.46,"w":0.58,"rot":0} },
               "frames": { "happy_2": { "HAT": {"y":0.04} } } } }
   ```
   Coordinates are fractions of the face image (x,y = item center; w = item width as a fraction of face width; rot in degrees). Per-frame entries override the default partially. Ship sensible defaults for both species by inspecting the face images' visible bounds (compute the alpha bounding box at build/test time or measure once and hard-code; say which). Add a loader with caching.
5. **`BuddyLook` widget** (lib/features/mascot/presentation/widgets/buddy_look.dart): inputs species, face (or current mood), equipped map, size. Draws the face, then EYEWEAR, then HAT at their anchors; items may extend beyond the face box (no clipping; the widget's layout size stays the face size, overflow painted). If `assets/images/market/<assetKey>/<species>.png` is missing, draw a clean vector placeholder per slot (simple hat/glasses shapes via CustomPainter, tinted by rarity if known) — never an error box. Semantics label includes worn items.
6. **Use it** in: the floating head, the buddy panel's speech row, the lesson companion's face if it shows the face, profile header (if the buddy appears there), public profile, and leaderboard rows/podium if they show a buddy. Where a full-body sprite is shown, leave it unchanged (body items are later) but pass through without crashing.
7. Register new asset folders in pubspec.yaml (`assets/images/market/anchors/` and a placeholder `.gitkeep`-backed folder per seeded assetKey is NOT needed — the placeholder path handles missing art; only list folders that exist).
8. Tests: `BuddyMe` parsing with/without `equipped`; server-first (cached look then server look replaces it; guest buddy pushed only when server empty); equip optimistic + rollback; anchor override merge; `BuddyLook` paints placeholders when PNGs are missing (golden for crocodile + capybara, none / hat / glasses / both, light + dark); leaderboard/public profile parse old and new payloads.

# Do NOT
- Do not commit, push, rebase, or switch branches.
- Do not modify the bottom navigation bar.
- Do not build market/shop/wardrobe screens (a later task).
- Do not modify files outside: lib/features/mascot/**, lib/features/userProfile/data/**, lib/features/userProfile/presentation/** (only swapping in `BuddyLook` where a buddy face is shown), lib/features/leaderBoard/** (models + swapping in `BuddyLook`), assets/images/market/anchors/**, pubspec.yaml (asset entries only), lib/l10n/** (prefix `buddyLook…`), and matching tests/goldens.
- Do not add dependencies without stating so.

# Deliverable
Changed files, the real output of `flutter analyze` and `flutter test`, the anchor values chosen and how, a list of every place now using `BuddyLook`, and a checklist for the artist (exact PNG paths/sizes expected).

# Risks
End with a "## Risks" section.
