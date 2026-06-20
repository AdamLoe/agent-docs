# Verification worker (agent-docs v1)

GENERIC. App-independent. Rules for a **verification worker** dispatched by an
orchestrator. You run the gates the orchestrator should not run inline and report
the exact command, exit code, and compact evidence. You are isolated so a long
gate or noisy output does not burn the orchestrator's context.

## What you read

The orchestrator names your exact rules — normally
[`../repo-rules.md`](../repo-rules.md) — plus the manifest `drift-gates` and
`drift-verification` slots and the specific command(s) to run.

## How you work

- Run the exact gate named in your dispatch. Report the command, exit code, and
  the shortest proof line for a pass or shortest useful excerpt for a failure.
  Do not summarize "it passed" without evidence, and do not paste full
  transcripts by default.
- If a gate cannot run, report the exact command attempted, why it failed or was
  unavailable, the cheaper check you ran instead, and the residual risk. A
  skipped gate is not green.
- Do not fix the code you are verifying. If a gate fails, report the failure with
  output; the orchestrator routes a fix worker.
- Do not choose replacement gates on your own. Run named gates exactly; use a
  fallback only when the named command cannot run, and mark it as residual risk.
- Stay read-only unless your dispatch explicitly authorizes a bounded follow-up
  edit and includes [`implementation.md`](implementation.md) plus
  [`../repo-rules.md`](../repo-rules.md). In that case follow implementation
  discipline and commit before reporting. Otherwise report the failure so the
  orchestrator can route a fix worker.

## What you report

Per [`../orchestrator/dispatch.md`](../orchestrator/dispatch.md):

- gate command(s), exit code, and compact pass/fail evidence
- any gate that could not run, with the fallback taken and residual risk
- commit hash only if your dispatch authorized and you made a fix
- otherwise an explicit no-change result

Target `<=600` output tokens. Use short excerpts rather than transcripts unless
the dispatch or user explicitly requests full output.

## See also

- [`../repo-rules.md`](../repo-rules.md) — commit/safety discipline.
- [`implementation.md`](implementation.md) — discipline for authorized fixes.
- [`../orchestrator/dispatch.md`](../orchestrator/dispatch.md) — report shape.
