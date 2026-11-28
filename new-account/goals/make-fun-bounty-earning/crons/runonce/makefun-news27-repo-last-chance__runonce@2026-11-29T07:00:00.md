---
id: makefun-news27-repo-last-chance
title: make.fun 新闻图27期建仓最后提醒（仅一次）
enabled: true
owner: goal:make-fun-bounty-earning
mode: task
schedule:
  kind: runonce
  timezone: Asia/Shanghai
  at: 2026-11-29T07:00:00
delivery:
  - chat_id: 6c739a78-74c8-42a1-b796-d0b826f0c1db
metadata:
  tags: [cron:exact-time]
  originating_chat_context_json: '{"origin_provider":"main","chat_kind":"direct","event_kind":"message","require_mention":false}'
  presentation_locale: zh-CN
---
One-off last-chance check for the make.fun news-image 27期 submission. The finished image was built in-session on 2026-11-28 by comparing against the 24期 top-10 winners (38 news items / 10 regions, per-item sources, continuous numbering, legend, black top bar, in-image banner) and passed its blind-review self-test; only submission is left. It needs the user to create the empty public GitHub repo makefun-news-image-20261127 (no README ticked) and nod approval — only the user can create repos under kingparkpark. Hard deadline: 2026-11-29 08:00 CST (2026-11-29 00:00 UTC). This is the last checkpoint before the deadline: the existing 09:00 last-chance job covers only the two building sites and runs after this deadline, so this job covers the news image alone.

Steps:
1. First read the recent messages in the make.fun side chat for anything the user said overnight about creating the repo or approving submission.
2. Check whether the repo exists publicly under kingparkpark: makefun-news-image-20261127 (open its GitHub page; a public repo page loads, a missing one 404s). Do NOT create the repo, push, or submit anything yourself — repo creation and the submit nod are the user's.
3. If the repo exists, stay completely silent: no message, no further action. This run is done.
4. If it is still missing, send ONE short message in this chat naming only the missing repo, the 08:00 deadline today (one hour left), and that creating the empty public repo (no README ticked) plus a nod is the only step needed — after that, the assistant pushes and submits. Do not re-explain the whole earnings ledger; the user already got it on 2026-11-28 evening.
5. This is a one-off runonce job: never reschedule or repeat it.
