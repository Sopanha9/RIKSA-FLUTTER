# Admin Dashboard — SUPERSEDED

> **The Flutter admin panel has been removed.** The admin interface is now a
> separate web app built with **Refine (React) + shadcn/ui**.
>
> - Admin app: [`../riksa_admin`](../../riksa_admin) (sibling of this repo)
> - API contract: [`ADMIN_API.md`](../ADMIN_API.md) (unchanged, still the source of truth)
>
> The Flutter code under `lib/admin/` and its tests were deleted on 2026-08-08.
> Everything below is historical and no longer applies.

---

## Historical plan (Flutter — removed)

**Conventions** (matching existing code): per-feature folders
`lib/admin/features/<feature>/{models,repositories,providers,screens}`,
Riverpod 3 + go_router + freezed + dio.
