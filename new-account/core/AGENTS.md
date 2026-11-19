# AGENTS.md

Your operating manual for this workspace, written by you. Your main instructions cover how you work in general. This file is where you keep the specific, durable lessons and conventions you pick up as you work, the kind of thing you'd want a future session to know. It's not about the user (that goes in `USER.md` and your memory) or your personality (that's `SOUL.md`); it's about how you get work done here.

## Conventions
Add an entry whenever you work something out worth keeping, for example:
- a convention you've settled on ("keep data exports in `workspace/exports/` and clean them up monthly")
- a tool or site quirk worth remembering ("site X hides its form behind a cookie banner; dismiss it first")
- a workflow that worked, or a mistake not to repeat

It starts empty and is meant to grow slowly. Don't pad it; a short, accurate file beats a long, stale one.

## 备份分离（2026-11-19 用户立规）
- GitHub 库 kingparkpark/muse：`original-account/` 是老号专属区，只读，禁止写/改/删；本账号备份只写 `new-account/`，不写仓库根目录、不用根目录旧路径（含「会话纪要/」）；迁移包命名 `Muse-backup-YYYYMMDD-new-account.zip` 并在包内放来源账号标记文件。全文见 MEMORY.md「备份分离约定」。

## Tool quirks
- 用户 2026-10-31 提供的选题辅助技能包实测结论（装在 ~/workspace/custom-skills/）：`douyin-hot-trend` 真能用（直调抖音热榜接口返回真实数据，脚本带封面抓取所以慢，约1分钟）；`china-demand-mining` 的全部 fetch_*.py 都是写死的样例评论（mock），数据不可用，只可借其分析框架/报告模板；`douyin-competitor-analysis` 需第三方 GUAIKEI_API_TOKEN，未配置前跑不了。
- `muse.write` strips `【...】` bracket blocks (brackets AND their contents) from file content — verified 2026-10-09 when a prompt draft lost all 11 `【小节标题】` headers plus a `台词：【...】` dialogue block. Workaround: write with ASCII placeholders (e.g. `@@标题@@`), then replace via `muse.exec` + python (`re.sub(r'@@(.+?)@@', ...)`); the exec path preserves `【】` fine. Always verify bracket survival with python after writing.
