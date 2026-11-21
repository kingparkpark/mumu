---
id: continuity-backup-6h
title: 每6小时连续性备份
enabled: true
owner: goal:werewolf-ep2-production
mode: task
schedule:
  kind: interval
  timezone: Asia/Shanghai
  at: 2026-11-19T08:36:54
  every: 6h
timeout_secs: 3600
delivery:
  - chat_id: b54986ae-5a55-4501-8bd2-a14e492581ac
metadata:
  tags: [cron:automatic-interval-anchor]
  originating_chat_context_json: '{"chat_id":"8514d6c9-8a3a-4c83-a609-b440133250a5","origin_provider":"main","chat_kind":"direct","event_kind":"message","require_mention":false,"device_id":"98bd6369-4dba-44fc-b9f6-51473faab499"}'
  presentation_locale: zh-CN
---
执行一次连续性备份（用户 2026-11-19 03:15 令：每 6 小时一次；2026-11-19 15:08 起执行备份分离约定与迁移包备份法；2026-11-22 用户定点授权：本任务向 new-account/ 的备份推送已获常驻授权，直接执行、不再在聊天里另行请示用户；GitHub 写入的系统审批卡是平台硬性流程，照常走卡即可，不要因为等卡而停摆或重复发问）。

分离铁规：GitHub 私库 kingparkpark/muse 的 original-account/ 是老号专属区，禁止写入、修改、删除其中任何文件；仓库根目录与根目录旧路径（包括根目录的「会话纪要/」与 continuity/）一律不再写；本账号只写自己的标记目录 new-account/。

备份法（迁移包制）：①在本机 ~/workspace/backups/ 按固定清单重建迁移包，命名 Muse-backup-YYYYMMDD-new-account.zip（日期取当天）：core（AGENTS.md、SOUL.md、IDENTITY.md、USER.md、TOOLS.md、MEMORY.md、PROACTIVE_PREFERENCES.md 原文）、~/memory/ 全量、~/workspace/custom-skills/ 全量、~/workspace/ep2_full/ 与 ~/workspace/goals/ 的 .md/.json/.txt 文档；包内必须含 README.md（内容清单＋逐项恢复说明）与 SOURCE-ACCOUNT.txt（来源账号标记：新账号 new-account，与老号 -original-account 包区分）。排除密码、验证码、API Key、Cookie、浏览器登录数据、*.muse-github-snapshot-sync.json 同步记录，以及一切缓存目录（如 ep2_full 里的 .hf_cache、__pycache__、asr_venv）。②把同一批文本文件镜像推送到仓库 new-account/ 下（保持相对目录结构；memory/bank 派生数据只进本机 ZIP、不入镜像；推送前逐条核对路径前缀必须是 new-account/，推送后读回核对文件名与存放位置；单次推送内容过大会被服务端拒绝，必须分批推、每批约 1MB 以内，变化不大时尽量合并成一批，减少审批卡次数）。③GitHub 推送不可用时，只保留本机 ZIP 与镜像目录，并在报告中写明卡在哪一步。

备份完成后在当日日志 ~/memory/YYYY-MM-DD.md 追加一行记录（时间、ZIP 名、文件数、推送结果或失败步）。只报失败与异常，成功不必长篇汇报。
