# Public profile backend requirement

The Flutter app now has a production API seam for:

```http
GET /api/v1/profiles/{userId}
Authorization: Bearer <access-token>
```

This endpoint does **not** exist in the available `riksa-api` repository as of
2026-08-24. `docs/AUTH_API.md` in that repository explicitly describes `bio`
as self-profile data with no public profile API and lists a public profile /
showcase endpoint as outstanding backend work. The Flutter implementation does
not fall back to `GET /auth/me`, authenticated leaderboard responses, or
fabricated profile data.

## Required success response

```json
{
  "user": {
    "id": "uuid",
    "username": "dara",
    "displayName": "Dara",
    "avatarUrl": "https://...",
    "bio": "...",
    "isVerified": false
  },
  "gamification": {
    "totalXp": 2400,
    "currentTier": "SCHOLAR",
    "currentTierIcon": "https://..."
  },
  "achievements": [
    {
      "id": "uuid",
      "name": "...",
      "description": "...",
      "iconUrl": "https://...",
      "rarity": "RARE",
      "unlockedAt": "2026-08-01T12:00:00Z"
    }
  ],
  "rank": {
    "countryRank": 42,
    "provinceRank": 5
  },
  "coverUrl": null
}
```

`achievements` must contain earned achievements only. `rank`, either rank
field, media URLs, and `bio` may be absent or null. `isVerified` is an explicit
public badge decision and must not be derived from `emailVerified` or
`phoneVerified`.

## Privacy boundary

The response must never contain email, phone number, gender, role, login or
verification state, suspension reason, achievement progress, XP transactions,
streak activity, password/auth-provider identifiers, or other private account
fields. The backend should use a dedicated response DTO rather than reusing the
self-profile DTO.

## Access and errors

- Return `404` for missing/deleted users.
- Return `403`, `410`, or `423` for suspended or otherwise inaccessible users,
  according to the backend's chosen policy.
- The app maps those statuses to the same friendly unavailable state.
- Other transport and server failures remain retryable errors.
- Suspended-user visibility must be decided and enforced before returning any
  identity, achievement, or ranking data.

Profile posts continue to use the existing social feed query with
`authorId: userId`; they are not part of this REST response.
