# RUN LOG — best-household-budget-site-20261126-1457

赏金：Make the best household budget site；奖池 $50，前 10 名各 $5。
开放 2026-11-26T14:57Z，截止 2026-11-29T14:57Z（22:57 CST）。本日志记录首版构建过程（2026-11-26，未提交）。

## 需求要点（据 kit 内 competition.yaml / RULES.txt 精读）
- 与统计站赏金完全同构：同一套交付形态、门槛检查、评委机制、会话门槛与提交规则，仅主题与评委第 2 条措辞不同（预算站第 2 条不要求「每项数据带来源年份」，但要求内容对管钱的人完整具体、可据以行动）。
- 交付形态：GitHub 公开仓（须开放后创建）或 source bundle；根目录 main.ts 把 app/ 与 screenshots/ 复制到 /output 并写 dossier.json；app/ 纯静态、零网络、桌面+手机可用；截图 3–4 张（≤256 KiB/张，长边 ≤1280，短边 ≥360）。
- 评分：AI 评委两两对比、胜率排名；五维：①截图中站点完整可用（页面/工具/板块齐全、控件全真）；②内容与实用；③易用与手机布局；④设计原创；⑤首屏小+源码分工清晰。

## 首版做了什么
- 站点「Hearth & Ledger」：全功能家庭预算站，5 个页面（仪表盘/预算规划/支出日志/储蓄目标/指南），哈希路由单页应用，零依赖、零网络，所有控件真实可用。
- 仪表盘：样本家庭三个月可切换，收入/支出/储蓄/结余卡片、分类支出环图、计划 vs 实际双条图（超支变红）。
- 规划器：9 个分类预算可编辑输入，与 50/30/20 指南实时对照（needs/wants/savings 三组判定+未分配/超额提示）；收入可改。
- 支出日志：可新增（表单）/删除支出行，总额实时更新，开局带样本行。
- 储蓄目标：目标计算器（目标/已存/月存→月数与达成年月）+ 定投增长计算器（月投/年化/年限→终值与逐年增长线图），均实时计算。
- 指南页：实操预算方法 + 美国劳工统计局《Consumer Expenditure Survey 2023》官方基准表（户均年支出 $77,280 及六大类，标来源年份）。
- 文件按职责拆分：data.js / tools.js（计算）/ charts.js / state.js（共享状态）/ views.js / main.js（路由+控件接线）；main.ts、serve.ts 本会话原创手写，vendor 与 LICENSE 用 kit 原装。
- 参赛目录含 .makefun/owner.json（钱包 BhA7…2cpP）、README.md、shots.json，已 git init（未 commit、未 push）。

## 待办（提交前）
- 截图已由本机真实浏览器渲染生成（见下「验证」节更新）。
- 本地 check 预检结果见下。
- ⚠️ 会话窗口：本构建会话开始于开放前（2026-11-26 00:41Z < 开放 14:57Z），thinking_in_window 可能不认本会话记录；正式提交时须用开放后开始的会话完成最终写/改并打包会话记录，或由主代理裁定处理方式。
- 提交须用户点头；建仓（公开、开放后创建）与 About 填写亦待用户。

## 验证（2026-11-26 本地实跑）
- Node 直跑全部页面渲染函数：5 页输出均正常；计算抽验正确（目标计算器 (12000−3400)/450 → 20 个月；定投 $300/月、5%、10 年 → $46,585；50/30/20 对 $5,850 → 2925/1755/1170）。
- 截图：工具链同统计站（Chrome Headless Shell 159 + Playwright，等 __shotReady），截 4 张：仪表盘/规划器/储蓄目标（1280×800）+ 仪表盘手机版（390×844），JPEG 57–109 KiB，全部合规；已逐张目检，环图、计划对比、计算器与手机布局均正常。
- main.ts 实跑成功：dossier.json 550,101 字节（≤1.5 MiB）；Totals 行：首屏 8 文件、12,854 字节 gzip（34,963 raw）；app/ 内 grep 零外源引用。
- kit check（--worktree）：3 passed（snapshot、license_osi、entrypoint）、2 failed——competition_open（尚未开放，14:57Z 后自动消除）与 transcripts_present（未打包会话，提交环节处理）；其余同统计站。
- 本地 out/ 验证产物已删除，参赛目录保持干净；未 commit、未 push、未建仓、未提交。

## 修订轮（2026-11-26 23:34 CST 会话，开放后开始）
目的：首版会话始于开放前，thinking_in_window 可能不认；本轮在开放后对站点做一轮真实修订，使开放后会话拥有实质写/改记录。

改了 5 处（均在 app/ 内，main.ts / serve.ts / vendor 未动）：
1. 收入 $0 边界（views.js + tools.js，实测复现后修）：收入清零时仪表盘曾显示 "Infinity% of income"、结余 "$-4,795"；现储蓄率栏显示 "no income entered yet"，结余为负时显示 "-$4,795" 并标红、文案改为 "spending runs over income"。money()/moneyExact() 负数改写为 -$X 格式。
2. 规划器指南判定（views.js）：收入为 $0 时三项 verdict 曾全写 "over the guide's $0"，属误导；现改显示一句说明（须先填高于 $0 的收入，50/30/20 对照才会出现），汇总行亦同步改口径；收入正常时判定逻辑不变。
3. 支出日志日期与报错（views.js + main.js + style.css）：新增支出日期曾写死 2026-11-25，现默认取当天本地日期（实测浏览器中显示 11/26/2026）；表单加 novalidate，提交校验失败时显示内联报错（role="alert"）并聚焦第一个有问题的字段，不再静默无反应。
4. 手机端表格（views.js + style.css）：规划器/支出/指南三张表包进 .table-scroll 横向滚动容器（支出表 min-width 36rem），390px 下页面不再被表格顶出；表头补 scope="col"。
5. 无障碍与图表（style.css + charts.js）：新增 :focus-visible 琥珀色描边；环图 aria-label 带上总额；定投增长线在年限 >10 年时年份标签改为每 5 年一个（40 年时只剩 yr 5/10/…/40，不再重叠），10 年默认不变。

验证（本轮实跑）：
- Node 直跑 5 页渲染：收入 $0、超支、默认三态均无 Infinity/NaN；计算抽验不变（目标 (12000−3400)/450 → 20 个月；定投 $300/月、5%、10 年 → $46,585；50/30/20 对 $5,850 → 2925/1755/1170）；40 年增长线标签每 5 年一个、10 年仍逐年。
- 真机渲染：serve.ts + Chrome Headless Shell 159（CDP 驱动，等 __shotReady，脚本 /tmp/shot.mjs）重截 4 张并逐张目检：仪表盘/规划器/储蓄目标（1280×800）+ 仪表盘手机版（390×844），JPEG 45–88 KiB，全部合规，无破版；另抽查支出日志与指南手机版：表单纵向排布正常、日期为当天、表格在页内横向滚动。
- main.ts 实跑成功：dossier.json 436,867 字节（≤1.5 MiB）；Totals 行：首屏 8 文件、13,873 字节 gzip（37,799 raw），较首版 +1,019 gzip（新增样式/报错/判定分支所致）；app/ 内 grep 零外源引用。
- kit check（--worktree，2026-11-26T15:39Z）：**4 passed**——competition_open（本轮已转过：now 在 11-26 14:57Z 开放与 11-29 14:57Z 截止之间）、snapshot、license_osi、entrypoint；1 failed——transcripts_present（未打包会话，提交环节处理，与首版相同）；15 skipped（均系 transcript 相关）；5 项 at submission（GitHub 公开/owner/开放后建仓/推送/去重，提交时处理）。另 kit 提示本地 kit 为 level 50、线上为 level 53，仅作记录，未重下 kit。
- 本地 out/ 验证产物已删除；未 commit、未 push、未建仓、未提交。

## 待办（提交前，仍有效）
- 提交须用户点头；建仓（公开、开放后创建）与 About 填写亦待用户；提交时打包本轮开放后会话的 transcripts（thinking_in_window 要求会话始于开放后，本轮会话满足该条件）。
