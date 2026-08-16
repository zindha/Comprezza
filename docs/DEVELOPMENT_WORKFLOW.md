# Development Workflow

## Before every phase

1. Read `PROJECT_RULES.md`.
2. Read the latest `PROJECT_CHANGELOG.md` entry.
3. Read relevant `TECH_DEBT.md` entries.
4. Read relevant `BUG_TRACKER.md` entries.
5. Read `ROADMAP.md`.
6. Inspect the current code and tests.
7. State the phase scope, non-goals, risks, and approval gate.

## Required phase sequence

### 1. Planning

Define the smallest coherent deliverable, dependencies, non-goals, validation commands, and rollback/migration implications.

### 2. Design Decisions

Record architecture, package, API, state, performance, security, accessibility, localization, and Play Store decisions before coding.

### 3. Generate Code

Implement only the approved scope. Do not silently add future features. Reuse existing abstractions and tokens.

### 4. Self Review

Inspect the diff, imports, lifecycle ownership, error paths, null safety, naming, and documentation.

### 5. Bug Hunt

Look specifically for race conditions, stale state, memory leaks, unhandled exceptions, file lifecycle issues, accessibility regressions, and platform edge cases.

### 6. Performance Review

Check rebuild scope, synchronous work, isolate/native work boundaries, memory allocation, concurrency, cache growth, and battery implications.

### 7. Play Store Compliance Check

Check manifest permissions, data access, storage APIs, privacy claims, target API compatibility, offline behavior, and policy-sensitive dependencies.

### 8. Flutter Best Practices Review

Check null safety, disposal, async context safety, Provider scope, Material 3 usage, localization, routing, analyzer/lints, and testability.

### 9. Senior Engineer Review

Ask a Principal Flutter Architect to review only the current implementation using the prompt in `PROJECT_RULES.md`. No new features may be generated during this review.

### 10. Wait for Approval

Do not begin the next phase until the project owner approves the current phase.

## After every phase

Append to `PROJECT_CHANGELOG.md`:

- Version
- Date
- Files Added
- Files Modified
- Architecture Decisions
- Breaking Changes
- Future TODOs
- Known Risks
- Performance Improvements
- Technical Debt
- Senior Engineer Review status
- Validation status
- Approval status

Update as appropriate:

- `TECH_DEBT.md`
- `BUG_TRACKER.md`
- `ROADMAP.md`

Never overwrite earlier changelog entries.

## Final release review

Before publishing, do not release immediately. Run the following review:

> Act as a Google Play review team, Senior Flutter Engineer, Security Engineer, UX Designer, Performance Engineer, QA Engineer, and top-tier app reviewer.
>
> Review the entire project.
>
> Find every possible weakness.
>
> Review:
>
> - Architecture
> - UI
> - Performance
> - Accessibility
> - Animations
> - Memory
> - Battery
> - Play Store compliance
> - Privacy
> - Security
> - Error handling
> - Localization
> - Theme
> - Code duplication
> - Testing
> - Maintainability
> - Scalability
> - Monetization readiness
> - Premium architecture
> - Ads placement
>
> Suggest improvements.
>
> Give a score out of 100 for every category.
>
> Only approve if it is truly production ready.

The final review must include actual analyzer/test/build evidence and device validation. A score is not a substitute for fixing release-blocking findings.
