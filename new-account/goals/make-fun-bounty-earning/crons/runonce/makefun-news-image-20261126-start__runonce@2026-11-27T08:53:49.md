---
id: makefun-news-image-20261126-start
title: 新闻图 20261126 期开工（make.fun）
enabled: true
owner: goal:make-fun-bounty-earning
mode: task
schedule:
  kind: runonce
  timezone: Asia/Shanghai
  at: 2026-11-27T08:53:49
delivery:
  - chat_id: 6c739a78-74c8-42a1-b796-d0b826f0c1db
metadata:
  tags: [cron:timing-window:1800s]
  originating_chat_context_json: '{"chat_id":"6c739a78-74c8-42a1-b796-d0b826f0c1db","origin_provider":"main","chat_kind":"direct","provider":"main","event_kind":"message","require_mention":false,"device_id":"5a112f6c-56f1-4776-aa17-381cf98e906d"}'
  presentation_locale: zh-CN
---
任务：为 make.fun 新闻图赏金 news-image-20261126（"Sum up 26 November's world news in one image"，奖池 $100，50 个付费名次：1st $20、2nd $12、3rd $6、4–10 各 $2、11–50 各 $1.20，截止 2026-11-28 08:00 CST）做出参赛成品，备好待提交。不要正式提交（提交须用户点头+用户建空仓），做到「预检全过、随时可交」为止。

先读背景（都在本机）：
1. ~/.makefun/work/PLAYBOOK.md（获奖选手经验：评委在小尺寸下看图、大字少版面胜小字密排、标题写明可验证数字）
2. 前两期成品与管线：~/workspace/goals/make-fun-bounty-earning/hidden_files/news-image-20261124/ 与 .../news-image-20261125/（各有 RUN_LOG.md 与 entry/，含 render.py + stories.json + main.py）。战绩：20261124 期第 3 轮第 124/14,561 名；20261125 期改走大字路线（27 条、头条 29px、简讯 13px、数字条 34px、全页无截断词），本期沿用大字路线，可再针对性微调。
3. 规则（须到本期 kit 原文核对）：整图 PNG ≤1MiB、≤1024×1024；仓库根 main.py 无网络运行、把图写到输出目录；跑两次逐字节一致；图以单行 base64 文本入仓、main.py 运行时解码写出（多行 base64 会挂 thinking_reproduces）。

执行：
- 下载 kit：在 ~/.makefun/work 下跑 curl -sSL "https://make.fun/c/news-image-20261126/kit" | tar xz，读 requirements.json 核对与上期差异。
- 采集 UTC 2026-11-26 全天世界新闻（多路搜索核对日期，警惕日期陷阱），约 27–33 条、覆盖 7 大区域、每条标可信度（CONFIRMED/OFFICIAL/REPORTED/CLAIM），被排除的日期陷阱写进图上 DATE CHECK 框。
- 复用 render.py 出图：报纸头版式、标题写明条数与日期、大字优先；生成后缩到 510px 与 300px 两档自查可读性，迭代到无溢出无截断。
- 参赛目录建在 ~/workspace/goals/make-fun-bounty-earning/hidden_files/news-image-20261126/entry/（git init），含 main.py/render.py/stories.json/单行 base64 图/LICENSE（kit 原装）/README.md/.makefun/owner.json（钱包 BhA7fekocoZA7n4EZT4WKue79tnXD94MWPpPdpSk2cpP）；本地跑两次验逐字节一致；用 kit 的 check 跑本地预检（--worktree），目标除 transcripts_present 外全过。
- 过程写进同目录上层 RUN_LOG.md。
- 红线：私钥/API key 绝不打印、绝不入任何文件或仓库；不要 git push、不要提交、不要建 GitHub 仓库。
交付：向用户报告成品图（附图）、条数/区域数、小尺寸自查结论、预检结果，并提醒提交须用户建空公开仓（建议名 makefun-news-image-20261126，不要勾 README）+ 点头，截止 11-28 08:00、建议 11-27 晚间交。
