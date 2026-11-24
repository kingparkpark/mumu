---
id: makefun-vm-status-watch
title: make.fun VM 提交状态监看
enabled: true
owner: goal:make-fun-bounty-earning
mode: task
schedule:
  kind: interval
  timezone: Asia/Shanghai
  at: 2026-11-24T16:42:52
  every: 3h
delivery:
  - chat_id: 6c739a78-74c8-42a1-b796-d0b826f0c1db
metadata:
  tags: [cron:automatic-interval-anchor]
  originating_chat_context_json: '{"chat_id":"6c739a78-74c8-42a1-b796-d0b826f0c1db","origin_provider":"main","chat_kind":"direct","event_kind":"message","require_mention":false}'
  presentation_locale: zh-CN
---
Check the make.fun submission status for our tiny stack VM entry and report ONLY on material change.

Run: cd ~/.makefun/work/tiny-stack-vm-01-run-20261122-kit && node cli/makefun.mjs status --submission 01a20c3d-ad5c-7324-91f0-36ac521189cf

Context: entry submitted 2026-11-24, all intake checks passed at last look, grading was queued ("still processing"). Competition: tiny-stack-vm-01-run-20261122, entries closed 2026-11-25T04:00Z, final window from 2026-11-25T04:10Z, result due by 2026-12-16. Places 1-10 pay $10 each; score = hidden-set run, ties broken by smaller entry size.

Rules for this run:
- If status is unchanged (still processing / all checks pass, no score, no verdict, no failure): send NO message to the user. End silently.
- If any check FAILED or the entry was rejected: message the user at once with the failed check names, their stated fixes, and the deadline pressure.
- If a server score or stage verdict appears (graded / round complete): message the user the score and stage in plain language.
- If the FINAL result is posted (official rank, prize or no prize, result on chain): message the user the final rank, whether we placed in the paid top 10, and the score; then remove this cron job (cron.remove with id makefun-vm-status-watch) so it stops.
- If the date is past 2026-12-20 and no final result ever appeared: message the user once that the result is overdue, then remove this job.
- Never resubmit anything. Never print the API key, keypair contents, or the claim code.
