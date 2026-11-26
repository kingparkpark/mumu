# token-radar-01 运行日志

## 2026-11-26 第一阶段：保底条目（未提交，提交配额 0/10 未动）

按 SCOUT.md 阶段 0 执行：从 kit starter 的形态起步，代码全部在本会话亲手写/改
（main.ts、lib/model.ts、dashboard 三件套、README 均为原创；仅 vendor/makefun-board.ts
与 LICENSE 按 kit 要求逐字节携带）。参赛目录 entry/，本地 git commit 320edac，无 remote。

### 做了什么

- **模型（radar-2-comps）**：用快照内 128 个有正市值已发币协议做 log-log comps 拟合
  （log10(mcap) ~ log10(tvl)，OLS），隐含价值 = comps 基值 × 类别乘子（类别内
  actual/fitted 中位比，按 n/(n+4) 向 1 收缩，n<4 的类别取 1）× 增长乘子
  （change_7d 钳制 −50%…+100%、权重 0.35）× 成熟度乘子（0.85+0.30×min(age,1095)/1095）。
  拟合实测：slope 0.5223、intercept 3.0247、R² 0.1939、中位绝对误差 0.527（log10，约 ×3.4）。
  注：SCOUT 记拟合样本 129，实测第 129 个（autofinance）mcap_usd = −1 为哨兵值，
  本模型以 mcap>0 过滤，n=128，README 已注明。
- **榜面**：198 行（watchlist 40 全覆盖 + early 158），ranks 1..198 不重不漏，
  implied 随名次不增、198 个互不相同。每行 6 条农场步骤（类别化动作 + 美元成本 + 耗时，
  末步汇总全计划 gas 并给跳过线）。
- **关键修正（首跑后自查发现并已改）**：首版榜首被 WBTC、Coinbase Bridge、Base Bridge
  占据——它们不是 watchlist，而是经「可排名」通道混入的已发币代币的包装/桥接产品。
  按 input/README 的 watchlist 原始规则（类别 Bridge/Canonical Bridge/Liquid Staking/
  Liquid Restaking/Restaked BTC/CEX、名称含整词 wrapped/staked/staking、交易
  所名前缀）把这类产品从 early 集合剔除：共 133 个另置，11 个版本化池另置，
  审计对账 198+133+11+416(live) = 758 全合。改后榜首为 Steakhouse Financial 等真未发币协议。
- **仪表盘**：深色账本风静态页（原创 CSS/JS），四视图：榜单（搜索/类别/链/排序/
  watchlist 开关）、详情（模型拆解表 + 农场计划）、Live（已发币单列、按市值）、
  Model & method（公式、拟合诊断、类别乘子表、覆盖审计）。数据走 ../data.js，
  与 board.json 同源生成；dashboard 源码无任何 http(s) 引用。
- **截图**：Headless Shell（~/.cache/chs-bin）以 1280×960 渲染自家仪表盘三张：
  1-board 205,336B、2-detail（榜首 Steakhouse Financial）183,549B、
  3-filtered（Lending 筛选态）189,052B；三张均已逐张目检，数字与 board.json 一致
  （详情页拆解 $90.20M ×1.00 ×0.99 ×1.00 = $89.39M 对得上）。

### 七项 gate 自查（对 /tmp 输出实测）

| gate | 结果 | 证据 |
| --- | --- | --- |
| dashboard_files | 过 | 3 文件（html+css+js）、22KB 级、无 http(s) 引用、≤400 文件/4MiB |
| board_file | 过 | 198 行 ∈ [100,4000]、390KB ≤8MiB、slug 全在快照内、implied 为正整数 ≤1e14 且不全相同 |
| sorted_by_value | 过 | ranks 恰 1..198、implied 随 rank 不增（脚本验） |
| coverage | 过 | watchlist 40/40 |
| farm_steps | 过 | 每行 6 条、修剪后 20–600 字符（脚本逐条验） |
| screenshots | 过 | 3 张真渲染 PNG、1280×960（长边 ≤1440、短边 ≥800）、每张 ≤512KiB |
| dossier_matches | 过 | 由 vendor buildDossier 以评分端同参数生成；dossier 793,982B ≤1.5MiB、text 22,197B ≤65,536B |

### 确定性

main.ts 连跑两次（独立输出目录），diff -r 全目录逐字节一致。
board.json sha256 7d422adf…、data.js 59b20c02…、dossier.json 2d3d2d7e…。

### kit 本地预检（check --worktree）

4 通过（competition_open / snapshot / license_osi / entrypoint）；
唯一 FAIL 为 transcripts_present（未打包会话——提交环节的事，按计划除外）；
其余 transcript 项 skip、5 项为提交时站点侧检查（repo_public / repo_owner /
repo_created_after_open / commit_in_repo / duplicate_snapshot），与预期一致。

### 离第二阶段还差什么

1. **估值真拟合升级**：当前是单变量 log-log + 类别收缩中位比，R² 0.19；
   阶段 1 按 SCOUT 做多特征（TVL、change_7d、age、类别、链数）分层/收缩拟合 +
   LOO 与 walk-forward 双检验、价值区间（分位残差）与名次区间、发币概率项，
   并把检验数字印上 Model 页（现页已留诊断位）。
2. **农场计划再成本化**：现为类别模板 + TVL 定资本 + 链定 gas 的规则生成；
   阶段 2 做逐协议净额裁决（farm/thin/skip + 预期总成本/预期收益口径）。
3. **完整性表演**：已有覆盖审计（758 全归类）；可再加逐协议归类明细导出。
4. **提交环节**（须用户点头）：建开赛后公开仓 → push → bundle 会话包
   （--system-prompt 用 ~/workspace/system/system_prompt.md、--redact 用户姓名）
   → 带 --transcripts 复检 → 提交。提交配额 10 次至今 0 次未用。

---

## 第二阶段（2026-11-26，用户批准后执行）：估值真拟合 + 逐协议农场裁决

本地 commit **7e00c70**（叠在 320edac 之上）。未提交、未 push、未建仓，配额仍 0/10。

### 原型先行（/tmp 原型脚本，Python，与快照同数据）

先在原型里把候选结构跑出双检验再动 TS，结论：
- 五特征回归（TVL、链数、增长、年龄、年龄缺失）+ 类别偏移：LOO ×4.03 /
  walk-forward ×3.78，**过拟合，不如旧模型**（增长系数拟合出 −1.6、年龄系数为负，不稳健）。
- 旧管线消融：手设增长乘子、成熟度乘子在样本外均无贡献（去掉成熟度 LOO ×3.43、两者都去 ×3.56）。
- 类别收缩加大有效（K=12–16）；**胜出结构 = 线与类别乘子联合迭代拟合（2 轮）+ 收缩 K=16**：
  原型 LOO ×3.24、walk-forward ×3.00。

### 新模型 radar-3-validated（lib/model.ts 整体重写）

- 条件价值：联合拟合 log-log 线 + 类别中位比乘子（K=16、min_n=4、迭代 2 轮）；
  slope 0.4997、intercept 3.1848、全模型 R² 0.2259（旧 0.1939）。
- **删除增长与成熟度乘子**（验证否决）；增长与年龄只经发币概率进入。
- 发币概率：快照内经验基率——全局 0.5488；年龄带 <180d 0.264 / 180–730d 0.387 /
  ≥730d 0.679 / 无日期 0.788；按 类别×年龄带 单元格（β=6 向类别）→ 类别（α=10 向全局）级联收缩。
  implied = 条件价值 × p_launch；p 分布 min 0.131 / 中位 0.571 / max 0.930。
- 区间：价值区间 = implied ×/÷ 10^(LOO |残差| p75)=×8.88（留一法实测覆盖率恰 75%）；
  名次区间由各行区间重叠计数推出（宽——如实反映 ×9 级不确定性，Model 页明说）。
- 三候选（radar-2 / 五特征回归 / radar-3）的 LOO+WF 由程序**每次运行重算**并写入
  data.js 与 Model 页验证表，非手抄数字。

### 双检验结果（TS 出货版实测，即页面所印）

| 结构 | LOO 中位误差 | walk-forward 中位误差 |
|---|---|---|
| radar-2（旧：线+类别K4+手设增长/成熟度） | ×3.63 | ×3.22 |
| 五特征回归 | ×3.99 | ×3.79 |
| **radar-3（新）** | **×3.28** | **×3.00** |

walk-forward 口径：按 listed_at 排序，前 60%（57 个，截至 2024-07-25）训练、
后 40%（38 个，自 2024-08-22）测试；训练集内部再按同法重拟合类别乘子。
**误差对比口径说明**：第一阶段所报「中位误差 ×3.4」是样本内口径；同口径下旧管线
LOO 为 ×3.63，新模型 LOO ×3.28——样本外中位误差约收窄 10%，walk-forward ×3.22→×3.00。

### 逐协议农场裁决（farm/thin/skip）

- 期望净额 = implied × 0.02%（ALLOC_SHARE）− 计划总成本（gas + 活跃分钟 × $15/h；
  活跃分钟由持有窗派生：30/45/60 天 → 4/6/9 周 × 15 分钟 + 15 分钟开仓）。
- 规则：skip 若 p_launch < 0.20 或期望净额 < 0；farm 若区间低端净额
  （低端 implied × 0.02% − 成本）≥ $100；其余 thin。
- 分布：**farm 36 / thin 128 / skip 34**（共 198 行）。裁决与全套经济学逐行写入
  board.json（verdict、economics{}）与 data.js；详情页有分解表 + 裁决经济学表；
  每行计划第 6 步以裁决句收尾（含 p、区间低端、期望净额三数字，可逐行复核）。

### 页面与截图

- 榜单新增 Launch odds 列与 Verdict 徽章列、Verdict 筛选、按期望净额/发币概率排序；
  KPI 增 farm/skip 裁决数；详情页新增 条件价值→×发币概率→implied 分解、价值/名次区间、
  裁决框；Model 页新增验证表、发币概率（年龄带表 + 类别前 12 表）、裁决规则与分布。
- 截图重截 **4 张**（Headless Shell 1280×960）：1-board（191KB）、2-detail 榜首
  BitFi Basis（141KB）、3-filtered Lending（190KB）、4-model（185KB），逐张目检通过。
- 仪表盘↔board.json 交叉抽查 10 行（首/中/尾抽样）：implied、区间、名次区间、裁决、
  成本、净额逐项一致；分解算术（base×类别≈条件价值、×p≈implied、gross=implied×0.02%、
  net=gross−cost）与裁决规则复算全过；farm step 最长 553 字符 ≤600。

### 回归验证

- main.ts 连跑两次：全目录逐字节一致（DETERMINISTIC）。
- 七项 gate 逐项复测全过：dashboard_files（3 文件 29,161B、无外源引用）/ board_file
  （198 行、464KB）/ sorted_by_value / coverage 40/40 / farm_steps（3–12 条、20–600 字符）/
  screenshots（4 张全合规）/ dossier_matches（以 vendor 函数独立复算逐字节相等；
  dossier 974,590B ≤1.5MiB、text 29,427B ≤65,536B）。
- kit check --worktree：4 passed / 1 failed（仅 transcripts_present，提交环节项）/
  15 skipped / 5 at-submission——与第一阶段同 profile。
- 注意：kit 提示本机 kit 为 level 50、站点已 level 51；提交前须重下 kit 并复核
  vendor 逐字节一致性、重跑与复检（属提交环节）。

### 还差什么才能提交（须用户点头）

1. 用户建开赛后（2026-11-14 10:00 UTC 后）公开仓并点头；
2. 刷新 kit 至 level 51 → 复核 vendor/makefun-board.ts 逐字节不变（变了则替换+重跑+复检）；
3. push 7e00c70 → bundle 会话包（--system-prompt ~/workspace/system/system_prompt.md、
   --redact 用户姓名）→ 带 --transcripts 复检 → 正式提交（配额 10 次，计划首交后视
   dev 榜迭代，截止 2026-12-14 18:00 CST）。
