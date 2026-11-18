# 换账号续工包（2026-11-18）

目的：更换 Muse 账号后，靠这一包 + 本地备份即可无缝继续全部创作工作。应用户要求：成片不入此包。

## 内容
- core/：MEMORY.md、USER.md、AGENTS.md、SOUL.md、IDENTITY.md、TOOLS.md、PROACTIVE_PREFERENCES.md（账号级核心文件）
- memory/：全部记忆（人物档案、每日记录）——~/memory 下所有 .md
- skills/：全部自制技能（custom-skills 的 .md/.py/.yaml/.txt）
- connectors/：自制连接器文档（Fish Audio）
- ep1/：狼人 EP1《一口泡面》全部提示词 .txt + gen.py/assemble 脚本（98+ 条，含修订轮次）
- ep2/：狼人 EP2《幽暗禁区》全部提示词 .txt + REVISION_ORDER_v2.md（修订组装顺序）+ audit 记录 + 脚本
- alang/：狼人通用锁定现行版等 .md/.txt/.json（ alang_ep1 根目录文本）
- goals/：全部目标文档（各 GOAL.md 与 files/ 下的 .md/.txt，含 EP1 纯剧本、系列范式、强子拆解存档）
- dreams/：对齐合成文档

## 未入包（及去处）
- 成片与原始视频片段：用户明确不要成片入仓；视频亦无法经此通道推送。全量在本机 ~/backups/2026-11-18_full/ 三个 tar 内（SHA256 已验）。
- 关键参考图（定妆图、世界母图、扫描仪、各设备图、骑手三视图与定妆锚图、泡面包装图、EP2 夜战狼/废墟/丧尸骑手/采样台锚图）：二进制图片无法经 GitHub 连接器的文本快照通道推送，本机另备一份图片包（见用户文件区「关键参考图包」），可自行网页上传到本仓库 continuity/images/。
- 虚拟环境、__pycache__、gpt-sovits 程序本体：可重建，不入包。

## 续工方法
新账号下：取回 core/ 与 memory/ 恢复记忆与规则；skills/ 放回 workspace/custom-skills/；ep1/ep2 提示词与脚本放回对应目录；参考图就位后即可按 REVISION_ORDER_v2.md 续跑 EP2 修订（12 条提示词已备齐，待生成通道恢复）。
