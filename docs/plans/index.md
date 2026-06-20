# Plans index

Plans are temporary coordination surfaces. Durable facts migrate into
`docs/architecture/`; durable rationale migrates into `docs/decisions/`.

Ordinary plan files and `docs/plans/orchestrator/<run-slug>/` folders are both
governed by [`../../v1/plan-lifecycle.md`](../../v1/plan-lifecycle.md). Their
frontmatter or run `hub.md` records status, owner, `last_updated`,
`okay_to_delete`, `long_lived`, and owning docs. Mark them shipped or abandoned
only after useful context is migrated, then set `okay_to_delete: true` when the
surface is disposable.

Do not maintain a live inventory here. List `docs/plans/` when you need to
see current plan files.

## See also

- [`../../v1/plan-lifecycle.md`](../../v1/plan-lifecycle.md)
- [`../../v1/plan-template.md`](../../v1/plan-template.md)
