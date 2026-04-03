# Figma Replication Progress Plan (Frontend + Backend)

Date: 2026-03-25
Status: In Progress

## Approved Decisions

1. Source of truth: `.external/Kinsuhealthappdesign` flow mapping.
2. Replace phone/OTP auth with Firebase Email + Google login.
3. Persist profile setup in backend DB with migration.
4. Web-first parity, then mobile polish.

## Stage Tracker

| Stage | Scope | Repo(s) | Status |
|---|---|---|---|
| S0 | Flow audit and decisions | Frontend + Backend | Done |
| S1 | Auth migration (email signup/signin + Google login) | Frontend | Done |
| S2 | Post-login consent/profile setup persistence | Frontend + Backend | Done |
| S3 | Onboarding/profile API contracts + migration | Backend | Done |
| S4 | Validate and regressions | Frontend + Backend | Done |
| S5 | Full tab-by-tab Figma parity sweep (Home/Vault/Track/Family/AI) | Frontend (+ backend deltas) | Pending |
| S6 | Missing intermediate flows and polish pass | Frontend | Pending |
| S7 | Release hardening and UAT checklist | Frontend + Backend | Pending |

## Completed in This Iteration

### Frontend
- Added new auth flow:
  - Splash
  - Onboarding slides
  - Auth choice screen
  - Email sign in
  - Email sign up
  - Google sign in
- Replaced `AuthGate` logic to:
  - Bootstrap backend login after Firebase auth
  - Fetch profile state
  - Route incomplete users into profile setup
- Added post-login setup wizard:
  - Consent
  - Basic profile
  - Optional details
  - Goals
  - Final save to backend with onboarding completion marker
- Added new auth/profile client model + service.
- Added dependencies:
  - `google_sign_in`
  - `shared_preferences`
- Updated widget tests for current provider dependencies.

### Backend
- Added onboarding/profile fields to user model.
- Added endpoints:
  - `GET /api/v1/auth/profile`
  - `PUT /api/v1/auth/profile`
  - `POST /api/v1/auth/consent`
- Extended `/api/v1/auth/login` upsert behavior to track auth provider and last login.
- Added Alembic migration:
  - `20260325_0003_user_onboarding_profile_fields.py`
- Extended route-group tests for profile + consent paths.

## Validation Results

- Backend tests: `19 passed`
- Backend compile check: pass
- Frontend targeted analyze (new files): pass
- Frontend widget tests: pass

## Next Stage (S5)

1. Mirror all remaining Figma tab flows screen-by-screen.
2. Add missing intermediate navigation steps currently skipped.
3. Add backend support only where the flow requires new persisted state.
4. Keep existing tracking/vault/family APIs backward-compatible.
