---
id: makefun-news-status-watch
title: make.fun 新闻图提交状态监看
enabled: true
owner: goal:make-fun-bounty-earning
mode: task
schedule:
  kind: interval
  timezone: Asia/Shanghai
  at: 2026-11-25T16:42:52
  every: 3h
delivery:
  - chat_id: 6c739a78-74c8-42a1-b796-d0b826f0c1db
metadata:
  tags: [cron:automatic-interval-anchor]
  originating_chat_context_json: '{"chat_id":"6c739a78-74c8-42a1-b796-d0b826f0c1db","origin_provider":"main","chat_kind":"direct","event_kind":"message","require_mention":false}'
  presentation_locale: zh-CN
---
Check the make.fun news-image submission status and blind-round results; report ONLY on material change.

Run from ~/.makefun/work/news-image-20261124-kit:
- node cli/makefun.mjs status --submission 01a2116b-2aed-7767-91a3-65a0c907520c
- node cli/makefun.mjs rounds news-image-20261124

Context: entry submitted 2026-11-25 14:36 CST, all intake checks passed, grading was queued. Competition news-image-20261124: blind round 3 cutoff 2026-11-25T12:00Z (20:00 CST), final round at the deadline 2026-11-26T00:00Z (08:00 CST), result due by 2026-12-10. Pot $100, 50 paid places (1st $20, 2nd $12, 3rd $6, 4-10 $2 each, 11-50 $1.20 each). Our entry: "Tuesday 24 November 2026 in one page — 33 stories, 7 regions".

Rules for this run:
- If nothing material changed (still processing, no round result yet, all checks still pass): send NO message to the user. End silently.
- If any check FAILED or the entry was rejected: message the user at once with the failed check names and stated fixes.
- When round 3 (or any round) is judged and shows our rank/score: message the user the round, our rank out of the field, and the score, in plain language.
- When the FINAL result is posted (official final rank, prize or no prize): message the user the final rank, whether we placed in the paid top 50 and for how much; then remove this cron job (cron.remove with id makefun-news-status-watch) so it stops.
- If the date is past 2026-12-12 and no final result ever appeared: message the user once that the result is overdue, then remove this job.
- Never resubmit anything. Never print the API key, keypair contents, or the claim code.
