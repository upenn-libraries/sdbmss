# Test Remediation Plan — Overview

Four documents cover the remediation work, ordered by dependency:

1. [Tagging](testing/01-tagging.md) — quarantine known failures so the default run is green *(current)*
2. [Infrastructure](testing/02-infrastructure.md) — fix DatabaseCleaner and Capybara timing config
3. [Test quality](testing/03-test-quality.md) — migrate misplaced specs, remove sleep calls, stub external deps
4. [App failures](testing/04-app-failures.md) — investigate failures that require understanding application behavior

Phases 3 and 4 are largely independent of each other and can proceed in parallel.
Phase 2 is foundational — do it before drawing conclusions about what is still broken.
