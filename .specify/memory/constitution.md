<!--
Sync Impact Report
- Version change: 1.2.1 -> 1.2.2 (add thumb-zone ergonomics rule for bottom primary CTAs)
- Modified principles: None
- Added / Expanded sections:
  - Technical Constraints & Standards (Thumb-zone bottom primary CTA on forms)
- Removed sections: None
- Follow-up TODOs: None
-->

# loki Constitution

## Core Principles

### I. Clean Architecture & Feature Modularity

Features MUST follow Clean Architecture with strict inward-only dependencies across three layers:
- **Domain**: Entities, repository interfaces (abstract contracts), and use cases in pure Dart with
  zero Flutter or third-party framework imports.
- **Data**: Repository implementations, remote/local data sources, DTOs/models, and mappers.
- **Presentation**: Pages, widgets, and GetX controllers/bindings that depend only on Domain use
  cases and entities.

Shared primitives MUST live in `core/` only after reuse is proven across at least two features.
Cross-feature direct imports of internal data sources or private widgets are prohibited.

### II. GetX State, DI & Navigation Discipline

State management, dependency injection, and routing MUST use **GetX** (`get`) consistently:
- Every route/feature MUST declare a `Bindings` class to register its dependencies lazily; direct
  `Get.put()` calls inside widget `build()` methods are prohibited.
- `GetxController` instances MUST NOT hold `BuildContext` references or contain raw networking,
  database, or serialization logic; they MUST delegate business operations to Domain use cases.
- Navigation MUST use named routes centralized in app route constants with typed arguments.
- Reactive state (`.obs` / `Obx` / `GetBuilder`) MUST be scoped narrowly to the smallest widget
  subtree that needs updates to prevent unnecessary rebuilds.

### III. Test-Driven Quality (NON-NEGOTIABLE)

Every new feature or bug fix MUST include automated tests covering the primary happy path, edge
cases, and failure states:
- Domain use cases and mappers MUST have pure Dart unit tests.
- GetX controllers MUST be unit-tested with mocked use cases (using `Get.testMode = true` and
  proper `Get.reset()` teardown).
- Critical user flows and reusable UI components MUST have widget or integration tests.
Tests MUST be written and verified to fail before or alongside implementation, and all tests MUST
pass before work is considered complete.

### IV. Simplicity & YAGNI

Solutions MUST favor the simplest architecture and smallest dependency footprint that satisfies
current verified requirements. Speculative abstractions, premature generalizations, and unused
configuration layers MUST NOT be introduced. Any new third-party package beyond the approved
tech stack MUST be justified by a concrete capability gap rather than convenience alone.

### V. Observability & Defensive Error Handling

Failures MUST NOT be silently swallowed. Asynchronous boundaries (network, disk, platform channels)
MUST catch low-level exceptions in the Data layer and map them into typed Domain failures (e.g.,
`Failure` / `Either` or sealed result types). Controllers MUST expose explicit loading, success,
empty, and error states to the UI with structured diagnostic logging. Sensitive data (tokens,
credentials, PII) MUST NEVER be written to logs or committed to version control.

## Technical Constraints & Standards

- **Platform & Runtime**: Flutter `3.44.7` (stable channel, sound null-safety, strict lints via
  `flutter_lints`; pin matching `environment.flutter` / `sdk` constraints in `pubspec.yaml`).
- **Approved Standard Libraries**:
  - *State Management, DI & Navigation*: `get` (GetX).
  - *Networking*: `dio` (with interceptors for auth headers, timeout, and structured error mapping).
  - *Local Storage*: `flutter_secure_storage` for sensitive tokens/credentials; `shared_preferences`
    (or `get_storage` / `isar` when structured local DB is required) for non-sensitive preferences.
- **Security & Privacy**: API keys, secrets, and auth tokens MUST NEVER be hardcoded in source code
  or committed to Git; inject environment config via `--dart-define` / `.env` (gitignored) and
  persist user tokens exclusively in `flutter_secure_storage`. Enforce HTTPS/TLS for all network
  traffic and redact sensitive fields from logs.
- **Performance, UI/UX & Accessibility**:
  - UI/UX design MUST follow **iOS / Cupertino Human Interface Guidelines** (`CupertinoTabScaffold`,
    `CupertinoNavigationBar`, `CupertinoListSection.insetGrouped`, `CupertinoSlidingSegmentedControl`,
    `CupertinoDatePicker`, `CupertinoAlertDialog`) inside a `GetMaterialApp` root shell for
    cross-platform chart/localization stability, guided by `ui-ux-pro-max`
    (`.agents/skills/ui-ux-pro-max/SKILL.md`).
  - Layouts MUST be responsive across mobile/tablet breakpoints without overflow errors.
  - Apps MUST support both **Light Mode** and **Dark Mode** via centralized `ThemeData` and
    `CupertinoThemeData` tokens (no hardcoded colors in widgets).
  - All user-facing text MUST support **i18n** (localization via GetX `Translations`—no hardcoded
    display strings).
  - Interactive widgets MUST meet **accessibility & thumb-zone ergonomics** standards:
    `Semantics` labels, minimum 48x48dp touch targets, WCAG-compliant text contrast, and
    primary form actions (Save/Submit) MUST be placed as full-width bottom primary buttons
    inside `SafeArea` rather than small top-corner nav bar text actions.

## Development Workflow & Quality Gates

- **Static Analysis & Formatting**: `dart format --output=none --set-exit-if-changed .` and
  `flutter analyze` MUST pass with zero errors and zero unaddressed warnings before merge.
- **Test Gate**: `flutter test` MUST pass 100% locally and in CI; skipped tests or relaxed
  assertions to force a green build are prohibited.
- **UI & Responsive Verification Gate**: After any UI modification, widget tests MUST verify all
  affected screens across narrow mobile (`360x740`), standard mobile (`390x844`), and tablet
  (`768x1024`) viewports with zero `RenderFlex` overflow errors and valid `DefaultTextStyle`.
- **Branch & Commit Hygiene**: Use feature branches (`feat/...`, `fix/...`) and Conventional
  Commits (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`).
- **Spec-Driven Delivery**: Non-trivial features MUST follow the Spec Kit lifecycle
  (`/speckit-specify` -> `/speckit-plan` -> `/speckit-tasks` -> `/speckit-implement`) and pass a
  Constitution Check during planning.

## Governance

This Constitution supersedes all other informal conventions or ad-hoc practices in the `loki`
repository. Every pull request, implementation plan, and code review MUST verify compliance with
these principles; any intentional deviation MUST be explicitly documented and justified in the
feature's `plan.md` (Complexity Tracking) before implementation begins.

Amendments to this Constitution MUST be proposed via PR, documented with rationale, and recorded
with an updated semantic version:
- **MAJOR**: Backward-incompatible principle removals or fundamental redefinitions.
- **MINOR**: New principles/sections added or materially expanded guidance.
- **PATCH**: Clarifications, wording improvements, or non-semantic refinements.

**Version**: 1.2.2 | **Ratified**: 2026-11-23 | **Last Amended**: 2026-11-23
