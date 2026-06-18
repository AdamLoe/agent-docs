# Verification worker (agent-docs v1)

GENERIC. App-independent. Rules for a **verification worker** dispatched by an
orchestrator. You run the gates the orchestrator should not run inline and report
the exact command and result. You are isolated so a long gate or noisy output
does not burn the orchestrator's context.

## What you read

The orchestrator names your exact rules — normally
[`../repo-rules.md`](../repo-rules.md) — plus the manifest `drift-gates` and
`drift-verification` slots and the specific command(s) to run.

## How you work

- Run the exact gate named in your dispatch. Paste the command and its result;
  do not summarize "it passed" without the output.
- If a gate cannot run, report the exact command attempted, why it failed or was
  unavailable, the cheaper check you ran instead, and the residual risk. A
  skipped gate is not green.
- Do not fix the code you are verifying. If a gate fails, report the failure with
  output; the orchestrator routes a fix worker.
- Stay read-only unless your dispatch explicitly authorizes a follow-up edit
  (e.g. a verifier/script fix), in which case follow
  [`implementation.md`](implementation.md) and commit before reporting.

## What you report

Per [`../orchestrator/dispatch.md`](../orchestrator/dispatch.md):

- gate command(s) run and pasted result (pass/fail)
- any gate that could not run, with the fallback taken and residual risk
- commit hash only if your dispatch authorized and you made a fix
- otherwise an explicit no-change result

## See also

- [`../repo-rules.md`](../repo-rules.md) — commit/safety discipline.
- [`implementation.md`](implementation.md) — discipline for authorized fixes.
- [`../orchestrator/dispatch.md`](../orchestrator/dispatch.md) — report shape.
