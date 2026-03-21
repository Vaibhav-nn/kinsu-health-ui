# Kinsu Design Flow Migration Plan

## Status
- No functional Flutter screens were modified yet.
- External design repo cloned at:
  - `.external/Kinsuhealthappdesign`

## Goal
Adopt the screen components and navigation flow from `vyom22/Kinsuhealthappdesign` into this Flutter app (`kinsu_health_app`) while keeping existing functionality stable.

## Source Design Coverage (from cloned repo)
- App shell + bottom tabs: Home, Vault, Track, Family, AI
- Home: quick actions, health cards, appointments, meds progress, notifications/search overlays
- Vault: records list/detail/upload/lab trends/filter flow
- Track: vitals, symptoms, chronic tracker, episode timeline, med adherence flow
- Family: member list, caregiver permissions, add member
- AI: summary cards, grounded chat, context advice, refusal handling
- Onboarding flow (React route-based version)

## Current Flutter Baseline
- Tabs:
  - `Home`: partially built custom screen
  - `Vault`: placeholder
  - `Track`: basic hub + existing feature screens
  - `Family`: placeholder
  - `AI`: placeholder
- Auth gate + Firebase email/password sign-in already implemented.
- Existing track feature screens (vitals/symptoms/illness/medications/reminders) are present and should remain working.

## Planned Changes (Before Coding)

## 1) Navigation + Shell
- Update [main_shell.dart](/Users/deovratsingh/Code/kinsu_health_app/lib/screens/shell/main_shell.dart):
  - Replace placeholder `Vault`, `Family`, `AI` pages with real screens.
  - Keep bottom nav labels/icons and existing tab behavior.
  - Preserve non-breaking `IndexedStack` pattern.

## 2) Reusable Flutter Component Layer
- Add a small reusable UI layer in `lib/screens/shared/`:
  - App section headers
  - Quick action tile
  - Status badge pill
  - Card wrappers
  - Optional bottom sheet wrappers
- Purpose: map repeated React design patterns to Flutter without duplicating code.

## 3) Home Flow Upgrade
- Expand [home_screen.dart](/Users/deovratsingh/Code/kinsu_health_app/lib/screens/home/home_screen.dart) to align with design:
  - Keep existing search + notifications/profile + theme mode controls.
  - Add quick action grid + secondary action row.
  - Add appointments section.
  - Add medicine adherence summary strip.
  - Add health insight cards + AI CTA.
- Keep existing behavior and routes to already-available Flutter screens.

## 4) Vault Flow Implementation
- Add:
  - `lib/screens/vault/vault_screen.dart`
  - `lib/screens/vault/record_detail_screen.dart`
  - `lib/screens/vault/upload_record_screen.dart`
  - `lib/screens/vault/lab_trends_screen.dart`
- Start with local/mock state + reuse existing theme.
- Non-breaking: do not remove existing service layer; wire backend integration incrementally.

## 5) Track Flow Rework (Non-breaking)
- Update [track_home.dart](/Users/deovratsingh/Code/kinsu_health_app/lib/screens/track/track_home.dart):
  - Reorganize sections to reflect design flow hierarchy.
  - Keep links to existing implemented screens (vitals/symptoms/illness/medications/reminders).
  - Add new lightweight tracker entry points only when they do not conflict with existing providers.

## 6) Family Flow Implementation
- Add:
  - `lib/screens/family/family_screen.dart`
  - `lib/screens/family/caregiver_permissions_screen.dart`
  - `lib/screens/family/add_family_member_screen.dart`
- Initial version: UI-first flow with local state, then provider integration.

## 7) AI Flow Implementation
- Add:
  - `lib/screens/ai/ai_screen.dart`
  - `lib/screens/ai/ai_chat_screen.dart`
  - `lib/screens/ai/context_advice_screen.dart`
  - `lib/screens/ai/ai_refusal_screen.dart`
- Keep explicit disclaimer and grounded-source sections in UI.

## 8) Theme + Styling Alignment
- Keep [theme.dart](/Users/deovratsingh/Code/kinsu_health_app/lib/core/theme.dart) as source of truth.
- Only add tokens/helpers where needed for parity (spacing/badge/background shades).
- Avoid risky global theme rewrites.

## 9) Data & Integration Strategy
- Phase 1: UI/flow parity with controlled local/mock data for new screens.
- Phase 2: connect to existing providers/services where already available.
- Phase 3: API extensions only after screen-level behavior is stable.

## 10) Validation Plan
- Run:
  - `dart format` on changed files
  - `flutter analyze --no-fatal-infos`
  - targeted `flutter test`
- Manual checks:
  - tab switching
  - auth gate + sign-in route
  - no crash when opening each new screen
  - existing Vitals/Symptoms/Medications flows still open and render

## Risk Controls
- Preserve existing screen classes and provider contracts.
- Avoid deleting current flows until replacements are verified.
- Add screens incrementally behind existing navigation points.

## Confirmations Required Before I Start Code Changes
1. Scope approval: Should I implement **all 5 tabs** (`Home`, `Vault`, `Track`, `Family`, `AI`) in this pass using the cloned design as reference?
2. Flow choice: Keep current Firebase email/password auth gate as-is (no onboarding import yet), correct?
3. Data policy: For new `Vault/Family/AI` screens, should I start with local mock UI data first, then integrate APIs in a second pass?

If approved, I will proceed with the implementation in small, non-breaking commits of work (navigation first, then each tab).
