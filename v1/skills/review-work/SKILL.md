---
name: review-work
description: Review completed or in-progress work against named plans, verify app state when practical, fix obvious misses, and commit fixes when green.
---

You are reviewing work against one or more plan files. The goal is to tell the
user whether the work actually finished the plans, what is left, how good the
work is, and whether the app state appears correct. Keep the review
high-signal: no nitpicks unless they cross a meaningful quality, correctness,
maintainability, or user-facing threshold.

## Bootstrap

Read `~/agent-docs/v1/rules/skill-contracts.md` and run the **Standard Intake
Protocol**: manifest (`code_root`, `change-to-doc`, `drift-gates`,
`drift-verification`) → `index.md` → `overview.md` → stop. The plan paths are
the task; if missing, run the two-question intake and wait.

Once the plans are named:

- Read `docs/plans/index.md`, `~/agent-docs/v1/plan-lifecycle.md`, and
  `~/agent-docs/v1/plan-template.md`.
- Read `~/agent-docs/v1/rules/coding-style.md`,
  `~/agent-docs/v1/rules/authoring-rules.md`, and
  `~/agent-docs/v1/rules/repo-rules.md`.
- Read each named plan in full, then load the smallest relevant architecture,
  decisions, docs, git, and source context needed to judge the work.

Review committed or uncommitted work as needed. Use the plans as the source of
truth for expected outcomes even if plan frontmatter claims the work is
shipped.

## Review Policy

- Inspect existing evidence first: commits, diffs, test logs in the chat or
  repo, plan status, docs migration, and obvious app artifacts.
- Run cheap verification yourself when it will materially improve confidence.
  Run broader or expensive gates only when the plan's risk justifies it or the
  user asks.
- Confirm app state when practical, especially for UI-facing or workflow
  changes. Starting a dev server, taking screenshots, or using browser checks
  is appropriate when the value is worth the cost.
- Use sub-agents for large plan sets or cheap independent review passes.
  Dials and model policy follow `skill-contracts.md`; at `cost-low`, prefer
  cheaper agents for bounded reads and routine verification.
- You may make obvious, non-debatable fixes discovered during review. This can
  change the review outcome. If fixes are made, verify and commit them when
  green.
- Update plan status when it is plainly wrong. If a plan is now truly shipped,
  migrate durable context first, then set `status: shipped` and
  `okay_to_delete: true` only when appropriate. If it is not done, leave or set
  the truthful state.
- Do not turn the review into broad implementation unless the user asks. If
  substantial work remains, provide a next-step path: fix it now, make a new
  plan, or hand off a prompt for a new chat.

## Report Format

Write an editorial memo for the user, not a line-by-line code review:

1. **Verdict** - whether the plan work is done enough to trust, and the most
   important reason.
2. **What It Missed** - meaningful gaps versus the plan, including wrong plan
   status or missing docs migration when relevant.
3. **Review Of The Work** - quality of the implementation at a product,
   architecture, and maintainability level.
4. **App Verification** - what evidence exists, what you checked, and how much
   confidence it gives.
5. **Code Review** - only material code issues, risks, or cleanup worth doing.
6. **Next Steps** - fixes made, remaining work, whether a new plan or new chat
   prompt is warranted, and any commit created.

If a section has no material findings, say so briefly.

Plans to review:

$ARGUMENTS
