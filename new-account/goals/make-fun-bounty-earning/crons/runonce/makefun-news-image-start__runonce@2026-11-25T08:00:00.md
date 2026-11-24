---
id: makefun-news-image-start
title: make.fun 新闻图赏金：明早开始采集
enabled: true
owner: goal:make-fun-bounty-earning
mode: task
schedule:
  kind: runonce
  timezone: Asia/Shanghai
  at: 2026-11-25T08:00:00
delivery:
  - chat_id: 6c739a78-74c8-42a1-b796-d0b826f0c1db
metadata:
  tags: [cron:exact-time]
  originating_chat_context_json: '{"origin_provider":"main","chat_kind":"direct","event_kind":"message","require_mention":false}'
  presentation_locale: zh-CN
---
Start the make.fun news-image bounty work for news day UTC 2026-11-24, in the make.fun side chat (delivery chat 6c739a78-74c8-42a1-b796-d0b826f0c1db).

First verify the bounty itself from make.fun (name, rules, deadline — the side chat stated deadline 2026-11-26 08:00 Beijing, image ≤1024×1024 and ≤1 MiB in a public repo plus a small program that outputs it verbatim; if the bounty, deadline or rules differ from that, report the difference to the user instead of proceeding on stale assumptions).

Then: collect the full UTC 2026-11-24 news day, and build the newspaper-front-page image following the saved winner playbook (judges view ~510px wide, big text with few sections, blind-test the image mixed in with rivals' images, ~50 sourced items, 7 regions, headline + briefs, credibility marks, UTC timeline). Aim to have the entry ready tomorrow evening (2026-11-25), well ahead of the deadline.

Do NOT publish the repo or submit the entry without the user's explicit go-ahead in that chat — the standing rule for every bounty after the stack VM is never to publish or submit without his word. When the entry is ready, message the user in the side chat with the image, the repo state, and what remains (his submit approval). If anything blocks the work, say so plainly once with what it stops. Stop after this run; do not create follow-up schedules from it.
