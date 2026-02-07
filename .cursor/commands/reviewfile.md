# reviewfile

Use this command to do a *senior-engineer* review of the **currently selected / referenced file**.

## Instructions
- Read the file end-to-end before commenting.
- Be specific and actionable. Prefer referencing **functions/types** and **specific snippets** rather than vague feedback.
- Prioritize issues by **severity** and **impact**.
- If you propose code changes, keep them minimal and consistent with existing patterns.
- Assume Swift/SwiftUI + MVVM conventions unless the file clearly indicates otherwise.

## Checklist
- **Correctness**: logic bugs, off-by-one, state/flow issues, race conditions.
- **Error handling**: missing propagation, swallowed errors, user-facing error states, retries/backoff where appropriate.
- **Edge cases**: empty states, nil/optional safety, invalid inputs, network failures, pagination boundaries.
- **Concurrency** (Swift): `async/await`, `Task` cancellation, `@MainActor` correctness, `Sendable`/thread safety, avoiding blocking work on main thread.
- **SwiftUI state**: `@State`/`@StateObject`/`@ObservedObject` usage, `@Published` updates on main thread, view identity and update behavior.
- **Architecture**: MVVM boundaries, dependency injection, testability, single-responsibility.
- **Security & privacy**: secrets in code, PII logging, unsafe persistence, insecure transport assumptions.
- **Performance**: excessive allocations, repeated work in `body`, unnecessary recomputation, expensive work in view updates.
- **API design & naming**: clarity, consistency, access control, documentation where reasoning is non-obvious.
- **Testing**: gaps in unit tests (networking, validation, state transitions), determinism, mocking strategy.

## Output format (required)
### Issues Found
- Group by severity: **Blocker / High / Medium / Low**
- For each issue:
  - **Where**: function/type name (and snippet reference)
  - **What/Why**: concise root cause
  - **Impact**: user-facing and/or technical impact

### Suggested Fixes
- Provide the **minimal** fix approach first.
- Call out any behavior changes.

### Optional Refactor
- Only if it materially improves maintainability/testability.

### Test Cases to Add
- List concrete tests (XCTest) with:
  - **Given / When / Then**
  - What to mock (e.g., networking client, clock, persistence)

### Review:
- Bullet points of residual risks/considerations after fixes.

### Suggestions:
- Specific follow-ups (docs, refactors, metrics, accessibility checks).
