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
  predicted_connector_permissions:
  - connector: github
    method: push
  originating_chat_context_json: '{"chat_id":"b54986ae-5a55-4501-8bd2-a14e492581ac","origin_provider":"main","chat_kind":"direct","event_kind":"message","require_mention":false,"device_id":"98bd6369-4dba-44fc-b9f6-51473faab499"}'
  presentation_locale: zh-CN
---
执行一次连续性备份（用户 2026-11-19 03:15 令：每 6 小时一次）。把当前账号的关键状态备份到 GitHub 私有仓库 kingparkpark/muse：参照已有的同步记录 ~/workspace/maoshiwu-backup.muse-github-snapshot-sync.json 与仓库 continuity/ 的既有结构，备份 MEMORY.md、USER.md、~/memory/ 全部、~/workspace/custom-skills/、~/workspace/ep2_full/ 下的生产文档与状态（EP2制作诀窍_原账号交接.md、DIRECTOR_REVISION_AND_PLAN.md、PRODUCTION_STATE.json）、~/workspace/goals/ 的目标文件。若 GitHub 推送不可用，改为在本机 ~/workspace/backups/<日期时间>/ 存一份完整快照。备份完成后在当日日志 ~/memory/YYYY-MM-DD.md 追加一行记录（时间、去向、文件数或失败原因）。只报失败与异常，成功不必长篇汇报。
