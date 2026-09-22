# Qaati — Phase 1 Build Recovery Report

## Scope

Phase 1 was performed against the Phase 0 baseline. Because the project is being continued as a sanitized, non-operational demo, no changes were made to the production marketplace logic.

## Changes made

1. Added `qaati_demo/`, a dependency-minimal Flutter demonstration client.
2. The demo has no backend/API integration and no authentication, ordering, payment, wallet, delivery, or external-provider functionality.
3. Added documentation describing the safety boundary and build-verification limitation.
4. The original `backend/` and `qaati_app/` source trees were left intact.

## Build observations

### Backend

The backend package metadata and lockfile are inconsistent: `@nestjs/throttler`, `express`, and `helmet` are declared in `package.json` but are absent from the root dependency map in `package-lock.json`.

An attempted lockfile-only dependency reconciliation could not complete within the available execution window because dependency resolution required external package access. No partial lockfile modification was retained.

The environment does contain Node.js and npm, but `backend/node_modules` is absent. Therefore a truthful backend compile could not be performed without installing dependencies.

### Flutter

The execution environment does not contain `flutter` or `dart`. Therefore `flutter pub get`, `flutter analyze`, tests, and release builds could not be executed.

The original Flutter application is also missing its platform directories and referenced asset directories. Those remain unresolved in the original application tree rather than being silently fabricated.

## Phase 1 gate

**PARTIAL / BLOCKED BY TOOLCHAIN**

The sanitized demo artifact has been prepared, but the project cannot honestly be marked build-verified until the required toolchains and dependencies are available.

## Required next verification

- Install/use the pinned Node/npm toolchain and resolve the backend lockfile.
- Run backend dependency installation, TypeScript compilation, and Jest.
- Install/use the Flutter SDK and run `flutter pub get`, `flutter analyze`, tests, and a platform build for `qaati_demo`.
- Keep the original marketplace source isolated from the sanitized demo during QA.
