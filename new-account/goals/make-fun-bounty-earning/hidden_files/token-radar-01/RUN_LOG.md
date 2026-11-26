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
