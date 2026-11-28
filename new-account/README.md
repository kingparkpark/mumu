# Muse 迁移包（新账号）
打包时间：2026-11-28 14:36 CST
来源账号：新账号（new-account）。包内另有 SOURCE-ACCOUNT.txt 为来源标记。

## 包里有什么
- core/：人设与规则原文 —— AGENTS.md、SOUL.md、IDENTITY.md、USER.md、TOOLS.md、MEMORY.md、PROACTIVE_PREFERENCES.md
- memory/：每日记录、people/groups 索引与细则（本机 ~/memory 全量，含 bank/index 派生数据；含 2026-11-21 新建的 INHERITANCE_GUIDE.md 新账号继承引导）
- skills/：自定义技能（~/workspace/custom-skills 全量，含 video-production-standard/LESSONS.md 生产教训流水）
- ep2/：EP2 生产文档与状态（仅 .md/.json/.txt，不含视频与图片二进制；已排除 asr_venv、.hf_cache、__pycache__ 等缓存目录；含 PRODUCTION_STATE.json）
- goals/：目标工作区文档（仅 .md/.json/.txt）

## 怎么恢复
1. core/ 各文件按原名放回新账号家目录（~/），MEMORY.md 不要覆盖新账号已有更新时先比对。
2. memory/ 整目录放回 ~/memory/；skills/ 放回 ~/workspace/custom-skills/。
3. ep2/、goals/ 放回 ~/workspace/ 对应位置，仅作生产状态接续参考。
4. 恢复后先读 memory/INHERITANCE_GUIDE.md，按其必读顺序接手；另开一条新对话验证（问称呼、问一条常用规则），能照做才算恢复成功。

## 排除项（按备份法约定）
密码、验证码、API Key、Cookie、浏览器登录数据、*.muse-github-snapshot-sync.json 同步记录，一律不入包。
视频成片、参考图等二进制不在本包内（在本机 ~/workspace/ep1_full、ep2_full 与老机备份中）。
缓存目录（asr_venv、.hf_cache、__pycache__、.venv、node_modules）一律不入包。

## 文件计数
{"core": 7, "memory": 100, "skills": 476, "ep2": 664, "goals": 46, "total_incl_readme_marker": 1295}
GitHub 镜像（new-account/）为同批文本文件，唯独不含 memory/bank 派生数据；技能包内的图片素材（.png/.svg）仅在本机 ZIP 内，不入 GitHub 文本镜像。
