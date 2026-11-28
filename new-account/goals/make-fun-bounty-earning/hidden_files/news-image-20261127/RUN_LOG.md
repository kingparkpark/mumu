# RUN_LOG — news-image-20261127（2026-11-28 本会话内完成）

## 第一步：学赢家（详见同目录 WINNERS.md）
- 读 PLAYBOOK + 拉 20261124 期最终榜前 10 的 artifact 图逐张看（第 3 轮榜公开接口已关闭，最终榜即付费名次）。
- 核心差异：赢家每条新闻都标出处（图版来源行＋简讯来源签）、连续编号可数验、条数 34–40、区域 9–10（亚洲拆三＋GLOBAL）、图内大字横幅、白色卡片硬边框、HOW SURE 图例、黑顶栏左品牌右声明。
- 与 25 期大字路线冲突处以赢家为准：条数改回高密度（38 条），字号保留 25 期下限。

## 成品
- 图：../news-final.png（同时在 entry 外的上层目录），1024×1024，257,987 字节，sha256 007c4537b0a96aac812d80a4d7fd0fdb5aeb5a745463f6fb4620cd3c44eb8cf1。
- 内容：38 条（13 图版＋25 简讯）、10 区域（EUROPE 6 / MIDDLE EAST 5 / AFRICA 5 / EAST ASIA 4 / SE ASIA 4 / SOUTH ASIA 3 / N. AMERICA 4 / LATIN AMERICA 4 / OCEANIA 1 / GLOBAL 2，计数之和=38）；头条三件：霍尔木兹封锁拦截（Pacific Archer）、欧盟峰会无果、泽连斯基评特朗普-普京「友谊」。
- 新闻采集：多路搜索（AJP、OneTurn、Candid Dragon、Reuters、h.ua 时间线、Rio Times 等）交叉核对日期；DATE CHECK 框排除 5 个日期陷阱（台湾选举 28 日、西班牙投票 29 日、印尼副总统 26 日辞职、曼谷炼油厂火灾 26 日、Norse 停飞 26 日）。
- 迭代：三轮修版（截断标题逐条削短、摘要按句截断防溢出、插图改离屏绘制防越界、时间线防出界、图例改单行＋定义行、简讯按来源宽度自适应）。

## 自查
- 510px：标题、数字条、区域条、头条标题全清晰；300px：头条与横幅仍可读，层级不乱。
- 盲评：与第 1/2/3/9 名图混排 300px 对比——层级与可读性已与赢家同档；输项只剩插图生动度（赢家场景更满、图内文字与画面融合更深）与第 3 名的留白感，属边际项，本期未再改。
- main.py 连跑两次逐字节一致（sha256 与成品图相同）。

## 预检
- kit check --worktree：4 passed，1 failed = transcripts_present（提交时打包会话处理，与前两期同阶段），其余全过。
- entry 本地 commit 2d122a3aacf2b098c98e3f7f9f29e9d38aad3bf9（makefun agent <agent@make.fun>），未 push、未提交、未建仓。

## 待用户
- 建空公开仓 makefun-news-image-20261127（不要勾 README）＋点头 → 推仓、设 About、打包会话、正式提交。截止 2026-11-29 08:00 CST。
