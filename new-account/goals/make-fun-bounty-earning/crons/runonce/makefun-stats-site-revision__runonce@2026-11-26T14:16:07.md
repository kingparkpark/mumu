---
id: makefun-stats-site-revision
title: 统计站开放后修订轮（make.fun）
enabled: true
owner: goal:make-fun-bounty-earning
mode: task
schedule:
  kind: runonce
  timezone: Asia/Shanghai
  at: 2026-11-26T14:16:07
delivery:
  - chat_id: 6c739a78-74c8-42a1-b796-d0b826f0c1db
metadata:
  tags: [cron:timing-window:1800s]
  originating_chat_context_json: '{"chat_id":"6c739a78-74c8-42a1-b796-d0b826f0c1db","origin_provider":"main","chat_kind":"direct","provider":"main","event_kind":"message","require_mention":false,"device_id":"5a112f6c-56f1-4776-aa17-381cf98e906d"}'
  presentation_locale: zh-CN
---
任务：make.fun 建站赏金 best-national-statistics-site-20261126-0539（国家统计站，奖池 $50、前 10 名各 $5、截止 2026-11-29 13:39 CST）已于今天 13:39 CST 开放。首版成品在 ~/workspace/goals/make-fun-bounty-earning/hidden_files/best-national-statistics-site-20261126-0539/entry/，过程记录在同目录上层 RUN_LOG.md，先读它。

为什么有这一轮：首版是在赏金开放前做出来的，平台的 thinking_in_window 检查会拒收开放前录制的会话。本轮会话在开放后开始——本轮要对站点做一轮真实、实质的修订（不是改个标点）：通读现站，挑出最值得改的 3–5 处（数据可再补 2025 年内最新发布、图表可读性、手机端布局、首屏体积、文案准确性等，以实际问题为准），逐项动手修改 app/ 文件（多次真实写/改），改完重跑 main.ts 验证 dossier 正常、grep 确认零外源引用；若视觉有变化，用 ~/.cache/chs-bin/ 的 Headless Shell 重截受影响的截图（保持 3–4 张、规格同前）。最后在 kit 目录 ~/.makefun/work/best-national-statistics-site-20261126-0539-kit 下跑 node cli/makefun.mjs check --worktree（--repo 指向 entry 目录），确认 competition_open 已转过、其余项与首版一致；把本轮改动与检查结果追加进 RUN_LOG.md。

红线：不要 git push、不要提交、不要建 GitHub 仓库（提交须用户点头+用户建仓）；私钥/API key 绝不打印、绝不入任何文件。
交付：向用户报告本轮改了哪几处、check 结果、成品是否已达「随时可交」状态。
