# 980 Ti 视频模型研发 · 情报日志

只记有来源、可核验的发现与裁决。SNG 程序动画路线（P0–P6）已于 2026-10-22 归档为参考，不再记入本日志主线。

## 2026-10-22 · 用户裁决与路线重启

- 用户看过 P4《追蝶》成片与设定图驱动测试后明确否定："这他妈根本不是视频好吗"。口径：SDF 团块动画＋设定图傀儡摆动属于程序动画，不承认为"视频生成"，更不算达成目标。SNG 全部原型（P0–P6，含双团团同场片）仅存档参考，不再作为主线推进或成果口径。
- 用户指示"继续研究"：重心回到真·生成式视频——能在 980 Ti（Maxwell SM52 / 6GB）上真实跑出生成视频的模型与管线。汇报纪律：只在有真实可跑成果或关键裁决时汇报。
- 每周三 10:46 持续研发任务（cron `video-model-980ti-research`）已同步改到新方向（2026-10-22）。

## 2026-10-22 · 关键裁决：FramePack 在 980 Ti 上判死（官方来源）

- 来源：FramePack 官方 GitHub README（lllyasviel/FramePack，2026-10-22 实测可读）：Requirements 原文——"Nvidia GPU in RTX 30XX, 40XX, 50XX series that supports fp16 and bf16. The GTX 10XX/20XX are not tested." / "At least 6GB GPU memory."
- 裁决：6GB 显存门槛是真的（13B HunyuanVideo，O(1) 显存），但架构门槛把 980 Ti 挡在门外——官方要求 RTX 30XX 及以上且支持 fp16+bf16，GTX 10XX/20XX 均未测试，9XX Maxwell 更不在支持范围；13B 权重为 BF16，Maxwell（SM52）无 BF16 原生支持。结论：FramePack 在 980 Ti 上判死，不再投入；除非将来出现 Maxwell 实测反例。
- 速度参考（官方）：RTX 4090 上 2.5 秒/帧（无优化）或 1.5 秒/帧（TeaCache）；3060/3070Ti 笔记本慢 4–8 倍。即使能跑，Maxwell 无 Tensor Core 也只会更慢。

## 2026-10-22 · 候选清单现状（待 980 Ti 真机实测）

1. **EbSynth 管线**（SD1.5 锁定关键帧 → EbSynth 纯 CPU 传播 → RIFE 插帧）：SD1.5 在 6GB 上实证最多；身份来自关键帧、无漂移，契合墨团团"设定图即身份"。当前最稳的"今天就能跑"路线。测试包 E4（`files/testkit_980ti/e4_ebsynth_test.md`）已就绪。
2. **CogVideoX-2B**：官方（README，经 deepwiki/AlphaNeural 镜像核对）diffusers FP16 "starting from 4GB"、INT8（torchao）3.6GB；但官方最小硬件写的是 GTX 1080Ti（11GB 显存卡）——4GB 是全优化下限，不等于 6GB 稳跑，且官方优化主要在 Ampere 及以上测试。规格：T2V、720×480、≤49 帧 @8fps（6 秒）、英文提示词、50 步在 A100 上约 90 秒。待真机实测（测试包 E2 `e2_cogvideox2b.py`）。
3. **Wan2.1-T2V-1.3B**：社区 Gradio 方案宣称 3.5GB VRAM 可跑 480×832（来源：huggingface.co/Wan-AI/Wan2.1-T2V-1.3B/discussions/3，社区帖，非官方）；官方 repo 文档有 --offload_model / --t5_cpu 降显存选项。待真机实测，可增补为 E5。
4. **AnimateDiff（SD1.5 版）**：16 帧，6GB 上路数最熟。待真机实测（测试包 E3 `e3_animatediff.py`）。
- 真机测试包：`files/testkit_980ti/`（E1 SD1.5 FP16 地基测试 → E3 AnimateDiff → E2 CogVideoX-2B → E4 EbSynth），软件栈钉死 PyTorch 2.6.0 + cu126（PyTorch 2.8 起官方包移除 Maxwell，CUDA 13 同样移除——这是 980 Ti 能用的最后一代窗口）。判读线：峰值显存 ≤5.5GB 过线；E1 若 FP16 输出近全黑则 FP16 判死、后续走 FP32 预算。
- 硬依赖：我方无 GPU，以上全部待用户在其 980 Ti 上跑测试包回传数据后做最终裁决。

## 2026-10-28 · 本周情报与新增测试项 E9

- 本周检索（2026-10-22 至 10-28）：未发现任何 Maxwell / 980 Ti 实测反例——"Maxwell 仍是无人区"的结论维持；Wan 2.7 / Wan 3.0 只出现在云端商业产品线（AI FILMS Studio 托管），不是开源可本地跑的权重，不进候选。
- 新候选 Wan2.2-TI2V-5B Turbo GGUF（hum-ma/Wan2.2-TI2V-5B-Turbo-GGUF）：4 步、CFG 1 的蒸馏模型，步数杠杆是队列里最大的（相对 E7 的 20 步约 5 倍）。仓库文件表已实测核对（2026-10-28）：Q4_K_M 3.44 GB、Q3_K_M 2.55 GB、Q2_K 1.86 GB、Q8_0 5.4 GB；由 Kijai FP16 Turbo 检查点经 city96 ComfyUI-GGUF 工具转换。已打包为测试项 E9（`files/testkit_980ti/e9_wan22_ti2v5b_gguf.md`），排在 E7 之后：引擎是 ComfyUI-GGUF 而非 sd.cpp，SM52 反量化内核零验证；编码器必须放 CPU（UMT5-XXL Q4 约 3.66 GB，放 GPU 即超预算）；fp8_matmul 必须关闭。
- 证伪一条本周流传的说法：2026-10-17 一篇博客称 Wan2.2 TI2V-5B GGUF"三文件共 6.1 GB 磁盘、6 GB 显存"，但该仓库根本不含编码器与 VAE（需另从 city96 与 QuantStack 下载），且其所列的 BF16 UMT5 编码器单文件就约 11 GB——6.1 GB 总数在算术上不成立，该博客列为不可靠来源，不引用其数字。仓库 README 自称"old 4GB GPU 可用"同样无机型、无显存日志，仅记为[社区声称]。
- 另核实：stable-diffusion.cpp 官方功能表仍含 Wan 2.2 视频支持（DeepWiki 镜像），但 E9 走 ComfyUI-GGUF 路径，不因 sd.cpp 支持 Wan 2.2 就默认其能吃 TI2V-5B Turbo GGUF——两者是不同引擎，需 E9 实测裁决。
- 测试包维护：E1/E2/E3/run_all.py 本机 py_compile 全过；E1–E4、E7 保持可用，新增 E9。仍无真机数据回传，全部候选继续处于"待 980 Ti 实测"状态。
- 按汇报纪律：本周无真实可跑成果、无关键裁决（E9 是新增候选不是裁决），本次运行静默留档，不向用户汇报。

## 判死区（有证据，不再投入）

- FramePack：见上（2026-10-22，官方架构门槛）。
- LTX-2B 直跑：官方写死 BF16，改 FP32 光权重 9.68GB 超显存，且此前外推漏算 9.4GB 文本编码器（E5，2026-10-21）。
- FP8 / BF16 直跑 / FlashAttention / Mochi / Hunyuan 本体：2026-10-21 已判死。
- MiniMax H3 的 ComfyUI 路线：INT8 GEMM（torch._int_mm → cuBLAS INT8 张量核）需 CC 7.5+、默认 BF16 计算需 sm_80+，SM52 两门皆无（2026-11-11，源码链 + NVIDIA 表格核实）。sd.cpp 路线未死，见 E10。
- Kandinsky 6.0 Video Lite（3B）：注意力后端只有 FA3（Hopper）/ SageAttention（Ampere+）两档，SM52 无路；最低实测卡 RTX 5060 Ti 16GB（2026-11-11，官方 README 性能表核实）。
- LongCat-Video：FlashAttention 2.7.4 硬要求 + 13.6B 致密、实测最低约 40GB 显存（2026-11-11）。
- Kandinsky S2V 1.0：Lite 2B 仍要求 48GB+ 显存（2026-11-11）。
- WanGP：地板为 GTX 10XX（Pascal），不支持 Maxwell（2026-11-11，官方 README 核实）；E8 只记录首个硬失败点。

## 诚实缺口

- 以上候选即使全跑通，画质与 Seedance 2.5 / MiniMax H3 仍有代差；"媲美"是远期目标，里程碑按"先让这张卡跑出第一段真生成的视频、再迭代逼近"来定。
- "属于我们自己的全新模型"在当前现实下的诚实形态：小模型在墨团团卡通域上的微调/蒸馏（如 Wan 1.3B / CogVideoX-2B 的域 LoRA），而非从零发明新架构——后者需要训练集群，我方没有。

## 2026-11-04 · 本周情报与一项上限修正（无真机数据，仍静默）

- 检索范围（2026-10-28 至 11-04）：未发现任何 Maxwell / 980 Ti 实测反例——"Maxwell 仍是无人区"维持；所有 6GB 实跑报告仍以 RTX 20/30 系（Pascal 及更新）为机型，无 SM52 证据。
- **上限修正（关键澄清，非判死/判活）**：此前日志与测试包写"PyTorch 2.8 起移除 Maxwell、栈钉死 ≤2.6 + cu126"，表述过粗。核实后修正为分构建口径——PyTorch 官方开发者邮件（2025-07-14，dev-discuss）原文：自 2.8 起"removing Maxwell and Pascal GPU support from CUDA-12.8 binaries"，即只针对 cu128 构建；torch 2.15 发行说明（经 newreleases 镜像核对）："2.15 wheels are cu132 and cu134; cu126 and cu130 are no longer built. CUDA 13 wheels need … a GPU of Turing (sm_75) or newer, so Maxwell, Pascal and Volta GPUs … should stay on 2.14"，并给出 `pip install torch==2.14.0 --index-url https://download.pytorch.org/whl/cu126`。结论：**Maxwell 官方预编译轮子的真实上限是 torch ≤ 2.14 + cu126**，不是 2.6。意义：E9（ComfyUI-GGUF）若需高于 2.6 的 torch，只要 ≤2.14 + cu126 就不构成墙；只有 >2.14 或 cu128 / CUDA 13 构建才是硬墙。测试包处理：E1–E3 仍钉 2.6.0 + cu126 作为已知可用组合不擅自升级（README 与 E9 说明已同步修正措辞），2.14 + 新版 diffusers/ComfyUI-GGUF 的组合未经验证，留待真机或后续核验，不直接改安装命令。
- 驱动悬崖佐证（2026-11-01，bigiron.cc《Salvaged GPUs in 2026》，引 NVIDIA 弃用通知）：580 驱动分支是 Maxwell / Pascal / Volta 的最后一支；CUDA 13 仅支持 Turing 起；PyTorch 2.14 为最后一版含 Maxwell/Pascal/Volta 预编译轮子——与上一条互相印证。另注意：驱动 580 并不救 CUDA 13，因为 CUDA 13 轮子本身要求 sm_75+。
- Wan2GP（deepbeepmeep）：Bright Coding 文章更新于 2026-11-03，但仍是 2025-09 项目的再介绍，宣称"6GB、10 系卡"，地板仍是 Pascal，无 Maxwell 实测；E8 的定位不变（仅在 E7 有结论后跟进，记录首个硬失败点）。
- 本周新模型核查（均不进候选）：MiniMax H3（33B DiT + 32B 编码器，最小 W6A8 剪枝文件仍需 19.4GB 级显存，2026-11-03 测算）——超预算且许可证不覆盖美/欧/英/韩；HunyuanVideo 1.5（8.3B，官方 offload 约 14GB）——超预算；LTX-2.5（22B，官方 32GB）——超预算；Wan 2.7（2026-04，4K 档，实际最低 24GB）——不是开源可本地跑的小模型，不进候选；Kandinsky 6.0 Video Lite（3B，公司给出的预设为 16GB）——超预算。Wan 2.1-1.3B GGUF Q4（社区表 4–6GB、编码器放 CPU）与 Wan 2.2-5B GGUF（RTX 3070 Ti 8GB 实测 49 帧约 60 秒，alexanderharte.com）仍是"6GB 数字成立、SM52 零验证"的状态，候选顺序不变。
- 代码级测算（本机验算，非真机结果）：E7 GPU 侧权重仅 1.07GB（DiT Q4 0.816 + VAE 0.254），距 5.5GB 线余量约 4.4GB，仍是余量最大的候选；E9 GPU 侧 3.44GB（DiT Q4）+ VAE + 激活，余量约 1.5–1.8GB，显著更紧；Wan 832×480 / 81 帧潜空间本身仅约 4MB，但不分块的自注意力 QK^T 单张量可达约 32GB——E7/E9 依赖 tiling/分块注意力是结构必需，不是可选项。CogVideoX-2B INT8（torchao weight-only）权重约 1.9GB，属存储压缩、计算仍反量化，速度惩罚待 E2 实测，官方"GTX 1080Ti 或更好"仍以 Pascal 为底线。
- 测试包维护：E1/E2/E3/run_all.py 本机 py_compile 全过；README、E9 的 torch 上限措辞已修正为 ≤2.14 + cu126；E1–E4、E7、E9 保持可用。仍无真机数据回传，全部候选继续处于"待 980 Ti 实测"状态。
- 按汇报纪律：本周无真实可跑成果、无关键裁决（上限修正是澄清不是裁决），本次运行静默留档，不向用户汇报；未在 Goals 时间线记条目。

## 2026-11-11 · 本周情报：H3 "6GB" 说法核查、ComfyUI 路线判死、Kandinsky 6.0 Lite 注意力门判死、新增 E10

- 检索范围（2026-11-04 至 11-11）：仍无 Maxwell / 980 Ti 实测反例——"Maxwell 仍是无人区"维持；所有 6GB 实跑报告的机型仍是 Turing 及更新（RTX 3060/3070/4060/5060 Ti 等）。
- PyTorch 2.15 正式发布（2026-10-28 左右，11 月 4 日官宣）：轮子只剩 cu132/cu134，cu126/cu130 不再构建；官方发行说明原文 "CUDA 13 wheels need … a GPU of Turing (sm_75) or newer, so Maxwell, Pascal and Volta GPUs … should stay on 2.14"，并给出 torch==2.14.0 + cu126。印证 11-04 的上限结论（Maxwell 官方预编译轮子真实上限 torch ≤ 2.14 + cu126），无变化。另有一家第三方博客称 Maxwell 应钉在 2.12，与官方发行说明冲突，以官方为准。
- MiniMax H3 "6GB 可跑"说法核查（本周新线索，来源：2026-11-08 论坛帖 + KingsClaw 实测文）：证伪其证据强度——KingsClaw 自测卡是 RTX 5060 Ti 16GB，他引用的 "6GB" 视频是换脸工作流（非视频生成）、未给机型；其 6GB/8GB 表格行是估算不是实测。论坛帖同样无机型。artificialguy 指南称 6GB "Not practical"、最小 GGUF 文本编码器都装不下。结论：H3 的 6GB 说法是 [社区声称，未核实机型]，不进候选口径。
- 代码级裁决 1：H3 的 ComfyUI 路线在 SM52 上判死（两道独立门）：(a) 原生 INT8 ConvRot 路径的 GEMM 走 torch._int_mm（ComfyUI 源码注释明示；PyTorch Blas.cpp `_int_mm_out_cuda` → `at::cuda::blas::int8_gemm`，cuBLAS INT8 张量核 GEMM），NVIDIA CUDA 编程指南 Table 36：张量核 INT8 输入自 CC 7.5（Turing）起，SM52 无 INT8 张量核——无内核可跑；(b) 默认计算精度 BF16（ComfyUI `mixed_precision_ops` 默认 `compute_dtype=torch.bfloat16`），BF16 计算需 sm_80+。模型本体用通用 `optimized_attention`（可退 SDPA），注意力不是门，GEMM 精度才是。注：torch._int_mm 的公开文档页在 stable 版中不存在（浏览器核查 404，私有算子未进公开文档），故以源码链 + NVIDIA 表格为证据。
- 代码级裁决 2：sd.cpp 路线未死——sd.cpp master 钉住的 ggml（leejet/ggml@d803c238f67915fb825a9aa4df27b99356d51597，`src/ggml-cuda/CMakeLists.txt`）默认 CUDA 架构表含 `50-virtual`（CUDA < 13 时，注释 "50 == Maxwell, lowest CUDA 12 standard"），PTX compute_50 可在 sm_52 上 JIT。附带回答了 E7 的引擎问题的一部分：sd.cpp 的 CUDA 后端在构建层不挡 Maxwell（须用 CUDA 12.x，CUDA 13 已删 sm_50/52 离线编译）。FP16 内核在 SM52 上走 FP32 回退（慢但应能跑），待真机验证。
- 新增测试项 E10：MiniMax H3 经 sd.cpp GGUF（`files/testkit_980ti/e10_minimax_h3_sdcpp.md`），排在 E9 之后、最低优先级。依据：sd.cpp 官方 H3 文档（docs/minimax_h3.md）有 --offload-to-cpu / --max-vram 控权重驻留、HyperFlow 4/6/8 步预设；官方 GGUF 仓库（leejet/MiniMax-H3-GGUF，HF API 核对）最小 DiT 文件为 ref2va-pruned Q2_K_M 6.72 GB，fl2va-pruned Q4_K_M 11.42 GB，编码器 Q2_K_M 13.10 GB（须放 CPU）。前提：32GB+ 内存；许可证排除美/欧/英/韩。
- 代码级裁决 3：Kandinsky 6.0 Video Lite（3B）判死——官方 README 性能表（2026-11-11 实读）：注意力后端只有两档，H100 用 FlashAttention 3、其余卡用 SageAttention（Qwen 编码器 BF16/NF4）；最低实测卡为 RTX 5060 Ti 16GB，Lite 在该卡上 5 秒片仍需 834.9 秒（50 步）/ 173.7 秒（蒸馏）。FA3 需 Hopper、SageAttention 需 Ampere+，SM52 两档皆无；叠加 16GB 实测下限。注：该模型上周已因 16GB 预设被排除，本周是架构门补强，不是新候选变动。
- 新模型核查（均不进候选）：LongCat-Video（美团，13.6B 致密，MIT，2025-10 发布）：54.32GB 权重文件、官方要求 FlashAttention 2.7.4、实测最低约 40GB 显存——FA 门 + 体量门双死；daVinci-MagiHuman（Sand.ai + 交大，15B，Apache 2.0，2026-03 论文）：H100 级基准，无消费卡路径；Kandinsky S2V 1.0（2026-11-03 发布，Lite 2B）：官方要求 48GB+ 显存——出生即死。Wan 2.5+ 仍无开源权重（vdf.ai 2026-11-04 核对）。
- WanGP 地板再确认：官方 README（2026-11-11 实读）支持 GPU 下限为 GTX 10XX（Pascal），"Maxwell" 全文未出现；GTX 10xx 手动安装钉 torch 2.7.1 + cu128；SageAttention 说明 "GTX 10XX should use SDPA"。E8 定位不变（只记录首个硬失败点）。
- 测试包维护：新增 E10；README 队列说明已同步；E1–E4、E7、E9 保持可用。仍无真机数据回传，全部候选继续处于"待 980 Ti 实测"状态。
- 按汇报纪律：本周无真实可跑成果；裁决均为已排除模型（Kandinsky Lite）或单一路线的死刑（H3 ComfyUI 路线，sd.cpp 路线仍活并转为 E10），候选队列顺序未变（E10 为队尾新增），故本次运行静默留档，不向用户汇报；未在 Goals 时间线记条目。
