---
id: maoshiwu-daily-github-backup
title: 猫事屋会话每日备份到 GitHub
enabled: true
owner: goal:maoshiwu-daily-github-backup
mode: task
schedule:
  kind: daily
  timezone: Asia/Shanghai
  time: 23:40:00
delivery:
  - chat_id: 0f92b9e3-c1ab-42ee-9969-06660e96461f
metadata:
  originating_chat_context_json: '{"chat_id":"0f92b9e3-c1ab-42ee-9969-06660e96461f","origin_provider":"main","chat_kind":"direct","event_kind":"message","require_mention":false,"device_id":"c37bfc96-042e-4b35-a254-c451027b9070"}'
  presentation_locale: zh-CN
---
每日备份任务（用户 昕之助 2026-10-30 要求，为防会话丢失）：把专职编剧对话的成果备份到 GitHub 私有库 kingparkpark/muse（分支 main）。

执行步骤：
1. 同步文件：把 ~/workspace/script-study/ 根目录下所有 .md 成果文件、watch-notes-part*.md（进 观看笔记/ 子目录）、transcripts/*.txt（进 转写稿/ 子目录）复制到备份源目录 ~/workspace/maoshiwu-backup/ 对应位置（保持与首次备份相同的目录结构，README.md 不动）。
2. 会话纪要：在 ~/workspace/maoshiwu-backup/会话纪要/ 下新建或更新当天日期文件（如 2026-10-30.md），用本对话今天的消息内容写一页纪要：用户今天给了哪些指令/纠正、我交付了哪些成果、哪些决定已锁定、哪些事还没办完。写事实，不写流水账套话。
3. 推送：严格按 GitHub 连接器文档的快照推送流程（/opt/hatch/connectors/github/references/snapshot-push.md）：先用 list_commits 核对 main 分支当前 head 与同步记录 ~/workspace/maoshiwu-backup.muse-github-snapshot-sync.json 中最新条目是否一致；为本次全部文件生成 NUL 分隔清单（写到源目录之外），用 /opt/hatch/bin/github push-files --owner kingparkpark --repo muse --branch main --source-dir /home/hatch/workspace/maoshiwu-backup --paths-file <清单> 推送，提交信息写「每日备份（日期）：当日要点一句」。成功后把新条目（commit SHA + 本次路径）追加进同步记录（先写 .tmp 再原子替换）。
4. 只推新增或有变化的文件即可；若当天与上次相比毫无变化，跳过推送、不打扰用户。
5. 汇报：成功且有实际变更时，在本对话简短报一句「今日备份完成」+提交要点；失败（权限、冲突、推送被拒）时必须在本对话说明失败在哪一步、需要用户做什么，不许静默失败。不要重复推送已确认成功的内容。
