# Coding style — Frontend (React/TS) idioms (agent-docs v1)

GENERIC. App-independent. Language-level frontend conventions — not app choices.
The app layer adds framework versions, lint baselines, and the named API client
path. Load this overlay only when the task involves frontend (React/TS or
similar) code.

Parent: [`coding-style.md`](coding-style.md).

## Frontend (React/TS) idioms

- Route all API calls through a single client module; no inline `fetch()` in
  components.
- Component-scoped styles (CSS Modules or equivalent); no global stylesheet
  dumping ground.
- Response/DTO types declared in one place and kept in sync with the server
  contract.
