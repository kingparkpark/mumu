# 研究 A：开源视频扩散模型的低显存极限（面向 GTX 980 Ti / 6GB / SM52）

- 日期：2026-10-22
- 角度：只查“现成开源视频扩散模型”这一族，逐个核实官方 repo / README / 模型卡，不凭印象。
- 标注规则：**[官方]** = 官方 repo/README/模型卡明示；**[社区]** = 社区实现/指南的说法，未经官方背书；**[推算]** = 由参数量/精度做的算术估计，必须实测才能算数；**[未核实]** = 本轮没有找到可靠出处，不下结论。

## 0. 目标硬件的五条硬约束（后面每个模型都按这五条判）

GTX 980 Ti：Maxwell GM200，SM52，2816 CUDA 核，6GB GDDR5（384-bit，约 336GB/s），FP32 约 6.06 TFLOPS，无 Tensor Core [社区规格表]。

1. **精度**：没有 BF16 硬件、没有 FP8 硬件；FP16 在消费级 Maxwell 上没有 2 倍速红利（FP16 主要当存储格式，计算走 FP32 路径）。因此所有“BF16 显存数字”搬到这张卡上都不成立——要么报错/回退 FP32（显存翻倍于 BF16 计划），要么慢到不可用。
2. **FlashAttention**：FlashAttention-2 官方只支持 Ampere / Ada / Hopper，只支持 FP16/BF16 数据类型 [flash-attn 官方 README]。SM52 被排除在外。凡注意力只有 FA2/FA3 一条路的模型，在这张卡上必须先换成 PyTorch SDPA 的 math 后端或切片注意力，而 math 后端会实体化 N×N 注意力矩阵——视频 token 数下这是显存爆点，是最常见的“移植后 OOM”原因。
3. **PyTorch 版本悬崖**：PyTorch 官方 2025-07-14 公告——从 PyTorch 2.8 起，CUDA 12.8 / 12.9 二进制包移除 Maxwell 和 Pascal 支持 [PyTorch dev-discuss 官方公告]。CUDA 13 则整体移除了 CC 7.5 以下的离线编译与库支持。结论：这张卡的可用窗口被钉死在 **PyTorch ≤2.7 的 CUDA 12.6 legacy 构建（稳妥用 2.4–2.6 + CUDA 12.4/12.6）**；任何要求 torch>=2.8 或 CUDA 13 的新代码默认装不上。
4. **Triton 系内核**（SageAttention、各种 fused kernel、torch.compile 的新后端）：主流实现普遍以 SM70/75/80+ 为目标，本轮未找到任何在 SM52 上验证过的记录，一律按“不可用、待证伪”处理。
5. **卸载（offload）的物理账**：980 Ti 是 PCIe 3.0 x16（理论约 16GB/s）。逐阶段卸载（文本编码器→DiT→VAE 轮换驻留）可行；逐步（per-step）把数 GB 权重在 CPU/GPU 之间来回搬，50 步就是上百 GB 的搬运量，直接把生成时间推到小时级以上。凡官方低显存数字依赖 sequential offload 的，都要按这个账打折看速度。

## 1. 结论先行：离 6GB 的距离排名

| 排名 | 模型 | 官方最低显存 | 离 6GB 还差多少 | SM52 可执行性判断 |
|---|---|---|---|---|
| 1 | CogVideoX-2B（diffusers 路径） | FP16 起步 4GB / INT8 起步 3.6GB [官方] | 数字上已经在 6GB 以内（但见下方脚注） | 有希望：训练精度就是 FP16，官方明说可在 GTX 1080 Ti（Pascal）上跑；未在 Maxwell 上测过 |
| 2 | AnimateDiff（SD1.5 版） | 官方未公布（SDXL 版约 13GB [官方]） | 推算 512×512×16 帧约 5–7GB [推算] | 有希望：SD1.5 生态本身就是 Maxwell 时代的软件栈，无巨型文本编码器；质量上限最低 |
| 3 | Wan 2.1 T2V-1.3B | 8.19GB [官方] | 差 2.19GB，且不含被 CPU 卸载的 T5-XXL 的代价核算 | 需移植验证：DiT 本体小，但 umT5-XXL 编码器约 11GB 文件必须常驻 CPU；注意力需确认 SDPA 回退路径 |
| 4 | LTX-Video 2B distilled（0.9.6/0.9.8） | 官方未公布数字，仅称 “light VRAM usage” [官方] | 社区低显存工作流约 8–12GB [社区] | 风险高：原生 BF16；T5-XXL 编码器是隐藏的显存炸弹；GGUF 路径存在但未见 6GB 记录 |
| 5 | Stable Video Diffusion（XT） | 官方 repo 未给数字；diffusers 文档称全技巧叠加可降到 8GB 以下 [官方文档] | 差约 2GB 以内（在 1024×576、25 帧条件下） | 技术可移植但许可证判死：非商业许可；且只有图生视频、无文本控制 |
| 6 | FramePack（13B，Hunyuan 骨架） | 官方明示最低 6GB [官方] | 显存数字刚好达标 | 被官方硬件门槛判死于本卡：官方要求 RTX 30/40/50 系（支持 FP16+BF16），GTX 10/20 系“未测试”；其“工作量与时长无关”的架构思想可借，权重本身是 BF16 路线 |
| 7 | HunyuanVideo-1.5（8.3B） | 14GB（开卸载）[官方模型卡] | 差 8GB（2.3 倍） | 判死（直跑）：BF16 + 以 FlashAttention-3 为对照基线设计的 SSTA 注意力，非本卡路线 |
| 8 | Wan 2.2 TI2V-5B | 官方命令至少 24GB [官方] | 差 18GB | 判死（直跑）：社区 Comfy 说法约 8GB [社区] 仍超 6GB 且未含速度代价 |
| 9 | Allegro（2.8B） | 9.3GB（BF16 + CPU offload，720p）[官方] | 差 3.3GB | 近判死：DiT 精度官方只列 BF16/FP32/TF32、不列 FP16，Maxwell 上只能 FP32 硬扛 |
| 10 | LTX-2 / 2.3 / 2.5（19–22B） | 官方包下载约 66GiB（BF16）[官方]；社区 GGUF 工作流地板 12GB [社区] | 差一倍以上 | 判死：BF16 全家桶 + Gemma 3/4 12B 编码器，6GB 无任何已报告配置 |
| 11 | Mochi 1（10B） | 单卡约 60GB [官方]；Comfy 优化后 20GB 以下 [官方] | 差 3–10 倍 | 判死 |
| 12 | HunyuanVideo 13B（原版） | 60GB（720p×129f）/ 45GB（544×960×129f）[官方] | 差 7.5–10 倍 | 判死（直跑）；GGUF Q4 社区地板约 24GB [社区]，仍判死 |

一句话结论：**数字上真正摸到 6GB 线的只有 CogVideoX-2B（官方 diffusers 数字）和 FramePack（官方 6GB、但硬件门槛排除 Maxwell）；工程上今天就能在 SM52 软件栈里站住的只有 AnimateDiff-SD1.5 和 CogVideoX-2B 两条。** 其余全部要么差 2GB 以上、要么被 BF16/FP8/FA 硬依赖判死。

## 2. 逐个模型核实

### 2.1 Wan 2.1 T2V-1.3B（阿里 Wan-Video）

- 参数量：DiT 1.3B（dim 1536 / 30 层 / 12 头）[官方]；但系统总账必须加上文本编码器 umT5-XXL（文件约 11GB 级）和 Wan-VAE。只报 DiT 参数量会严重低估整机负担。
- 官方最低显存：**8.19GB**，原文称 T2V-1.3B “requires only 8.19 GB VRAM”，在 RTX 4090 上约 4 分钟生成 5 秒 480P（未用量化等优化）[官方 README]。
- 官方降显存手段：`--offload_model True` + `--t5_cpu`（示例命令本身就是在 4090 上给的）[官方]。即 8.19GB 已经是消费级定位数字，进一步压到 6GB 没有官方配方。
- 社区最低：ComfyUI-GGUF 支持 Wan 2.1 架构的 GGUF 量化加载 [社区 city96/ComfyUI-GGUF]；1.3B 做 Q4/Q5 后 DiT 权重约 0.7–1.0GB [推算]，配合 T5 放 CPU、VAE 分块，社区有 8GB 卡运行记录的说法，但**本轮未找到 6GB、更未找到 Maxwell 的实测记录 [未核实]**。
- 生成规格：480P（832×480），1.3B 官方称也能出 720P 但不稳定、推荐 480P；5 秒级 [官方]。
- 软件栈：torch >= 2.4.0 [官方]；requirements 含 flash_attn（Wan2.2 README 明示 flash_attn 装不上时可最后装，属推荐而非唯一路径，但其注意力实现是否完整回退 SDPA 需读码验证 [未核实]）。
- 精度/注意力风险：权重为 FP16/BF16 体系（有 FP8 量化社区路线，FP8 在本卡直接判死，见第 4 节）；若被迫 FP32 跑 DiT，1.3B 权重约 5.2GB [推算]，加激活必然爆 6GB——所以必须保住 FP16 存储 + FP32 计算的混合路径，这是移植的核心难点，不是显存数字本身。
- 许可证：Apache-2.0 [官方]。干净。
- 速度现实账：4090（FP32 约 82 TFLOPS 级）要 4 分钟；980 Ti FP32 约 6 TFLOPS、带宽约 1/3，同一负载粗估 40 分钟以上 [推算]。能跑 ≠ 能用，速度是第二战场。

### 2.2 LTX-Video 2B（Lightricks，0.9.6 / 0.9.8 distilled）

- 参数量：DiT 2B；文本编码器为 T5-XXL（社区 Comfy 工作流中 t5xxl FP16 文件约 9–10GB 级 [社区]），编码器比 DiT 本体还大，这是所有 LTX 低显存讨论里最容易被漏算的一块。
- 官方最低显存：**官方没有给 2B 的显存数字**。README 对 ltxv-2b-0.9.8-distilled 的描述只有 “Smaller model… Ideal for fast generation with light VRAM usage”；0.9.6 distilled 称比非蒸馏快 15 倍、8 步采样、不需要 CFG/STG [官方]。任何“LTX 2B 只需 X GB”的具体数字都不是官方的。
- 社区最低：LTX-VideoQ8（8-bit 模型，官方 README 在社区贡献里收录）；ComfyUI-GGUF 支持 LTXV 架构 [社区]。本轮找到的低显存工作流记录集中在 8–12GB 区间，**没有 6GB 成功记录 [未核实]**。
- 生成规格：默认 1216×704 @30FPS（0.9.6）[官方]，可降分辨率/帧数；蒸馏版 8 步。
- 软件栈：官方测试环境 Python 3.10.5 + CUDA 12.2 + PyTorch >= 2.1.2 [官方]——版本窗口对 SM52 友好（2.1–2.6 都还有 SM52 构建，这点比新模型强）。
- 精度/注意力风险：**原生 BF16** 是最大问题。BF16 权重在这张卡上只能转 FP16 或 FP32 使用：转 FP16 有数值行为变化风险（未验证），转 FP32 则 DiT 约 8GB [推算] 直接爆。Q8 路径是权重 INT8、计算仍需反量化回浮点，速度与数值都待实测。
- 许可证：0.9.5 起改为 OpenRail-M [官方 README 新闻]；后续 0.9.x 社区通称为 LTX Open Weights（含年收入 1000 万美元触发条款的说法 [社区]）。逐 checkpoint 核对，不可一概而论。
- 判断：步数少（8 步）对慢卡极有吸引力，但 BF16 + T5-XXL 两座大山在前，排在 Wan 之后。

### 2.3 LTX-2 / 2.3 / 2.5（19–22B）

- 参数量：LTX-2 为 19B 级，2.3/2.5 为 22B 音视频 DiT；文本编码器 Gemma 3（2.3）/ Gemma 4 12B（2.5）[官方]。
- 官方形态：LTX-2.5 官方快速开始光下载就是约 66GiB 的 BF16 文件组 [官方 LTX-2 repo]；官方优化提示只有 FP8 量化 + CPU/disk offload，以及在 Blackwell 上装 FlashAttention 4 / Hopper 上装 FA3、其余 CUDA 卡用 SDPA [官方]。
- 社区最低：GGUF Q4 工作流地板 **12GB VRAM + 48GB 内存** [社区 Civitai 工作流]；Unsloth GGUF 的推荐档 UD-Q4_K_XL 本身就是 14.0GB 文件、最小的 UD-Q2_K_XL 也要 9.5GB [社区 Unsloth 模型卡]。连权重文件都装不进 6GB 显存，卸载后速度无从谈起。
- 许可证：LTX-2.x Community License（非 Apache）[官方]。
- 判断：**判死**。不是“差一点”，是权重体积、编码器体积、BF16 三项同时超标。

### 2.4 CogVideoX-2B（智谱 / THUDM，现 zai-org）

- 参数量：2B（DiT）+ T5-XXL 文本编码器 + 3D Causal VAE。同样要小心：官方 4GB 数字是整条 diffusers 管线全优化后的“起步”值，不是只装 DiT。
- 官方最低显存（本节最关键的一组数字）：SAT 路径 FP16 为 18GB；**diffusers 路径 FP16 起步 4GB、INT8（torchao）起步 3.6GB** [官方 README 模型表]。
- 官方脚注（必须一起读）：该方案“只在 A100/H100 上测过实际显存，一般可适配 Ampere 及以上设备；关掉优化峰值约为表中 3 倍” [官方]。也就是说 4GB 的前提是 sequential CPU offload + VAE slicing + VAE tiling 全部打开，且从未在 Pascal/Maxwell 上验证。
- 官方兼容性背书：发布说明明说 “You can run CogVideoX-2B on older GPUs like GTX 1080TI” [官方]——这是本轮所有模型里**唯一一句官方点名老卡**的话。1080 Ti 是 Pascal（SM61），离 Maxwell 只差一代。
- 生成规格：720×480（固定，不支持其他分辨率，含微调）[官方]；帧数 8N+1、最多 49 帧；8 FPS；6 秒 [官方]。竖屏 480×720 的用法需注意其固定分辨率约束（旋转/裁切后处理另算）。
- 精度：**训练精度就是 FP16，官方推荐 FP16** [官方]——在本卡上这是决定性优势：不存在 BF16 移植问题。FP8* 只限 H100 以上 [官方]，INT4 明确不支持 [官方]。
- 软件栈：Python 3.10–3.12 [官方]；diffusers 路径。风险点：torchao 的 INT8 内核对 SM52 的支持未验证 [未核实]，所以本卡应先走 FP16 diffusers 路径，不要指望 INT8 的 3.6GB。
- 速度：官方 A100 约 90 秒 / H100 约 45 秒（50 步、全优化）[官方]。A100 的 FP16 Tensor 算力与 980 Ti 不是一个量级，搬到本卡粗估为数十分钟到数小时级 [推算]，且 sequential offload 会再拖慢（官方亦提示 INT8/卸载以速度换显存）。
- 许可证：**CogVideoX-2B 已改 Apache-2.0** [官方]；注意 5B 及 1.5 系列是另一套 CogVideoX 模型许可，不要混用。
- 判断：**第一候选（现代 DiT 路线）**。显存数字达标、精度对路、有老卡背书；未验证项只剩“SM52 上 diffusers 全优化链是否完整跑通 + 速度是否可忍”。

### 2.5 AnimateDiff（SD1.5 版 / SDXL 版）

- 结构：不是独立视频模型，而是给 SD1.5/SDXL 图像模型插一个运动模块。运动模块 v2 为 453M 参数 / 1.7GB 文件，v1 为 417M / 1.6GB [官方 Model Zoo]；底座 SD1.5 UNet 约 0.86B，文本编码器只是 CLIP ViT-L（约 0.12B）——**全表唯一没有巨型文本编码器的方案**。
- 官方最低显存：官方 repo 只对 SDXL-Beta 给过数字：1024×1024×16 帧“usually requires ~13GB VRAM” [官方]。**SD1.5 版官方没有显存数字 [官方缺失]**。
- 社区/生态数字：集成方普遍称 8GB 起步 [社区]；作为参照，diffusers 官方优化文档称 SD 图像管线用注意力切片可低到约 3.2GB 级 [官方文档，图像管线]。AnimateDiff 在 512×512×16 帧、开 forward chunking / 注意力切片时，整管线推算约 5–7GB [推算]，是全表最接近“今天就能在 SM52 上装起来”的组合，因为 SD1.5 的整个软件生态（PyTorch 1.13–2.x、xformers 可选、纯 PyTorch 注意力可用）就是在 Maxwell/Pascal 时代成熟的。
- 生成规格：典型 512×512 或 512×768、16 帧（约 2 秒 @8FPS），可外推/插帧拉长；质量是 2023 年水平，运动幅度与一致性明显弱于 DiT 系。
- 精度/注意力：FP16 原生（SD1.5 时代标准），无 BF16 依赖，无 FA 硬依赖（xformers 是可选加速）——五条硬约束里它一条都不撞。
- 许可证：代码 Apache-2.0，但 repo 自带 “released for academic use” 声明，且底座 SD1.5 是 CreativeML Open RAIL-M [官方]。做商用/商单前必须法务核对，不能当 Apache 用。
- 判断：**并列第一候选（可执行性路线）**。画质天花板最低，但它是唯一能把“6GB + SM52”从推算变成实测最快的路径，也天然适合窄域卡通（社区 SD1.5 动漫底模生态最厚）。

### 2.6 Stable Video Diffusion（SVD / SVD-XT）

- 结构与规格：图生视频（无文本输入）。SVD 生成 14 帧、SVD-XT 25 帧，分辨率 576×1024 [官方 generative-models repo]。权重文件 svd.safetensors 约 9.56GB（FP32 存储）[模型卡文件列表]。
- 显存：官方 repo 未给显存表，只给低显存建议（decoding_t=1 等）；diffusers 官方文档称 model CPU offload + UNet forward chunking + decode_chunk_size=2 全开可把需求降到 **8GB 以下** [官方文档]。社区实现的 decoding_t=1 约 20GB 是另一种实现口径，不要混淆 [社区]。
- 精度：FP16 variant 官方提供 [模型卡]，无 BF16 硬依赖，技术移植性其实不差。
- 判死原因不在技术在许可与形态：许可证为 Stable Video Diffusion (NC) Community License——**非商业** [模型卡]。用户目标含抖音商单，此路直接出局；且纯 I2V、无文本控制，无法独立承担 T2V 目标。仅可作为“关键帧图生视频”技术参照，不立项。

### 2.7 Mochi 1（Genmo，10B）

- 参数量：AsymmDiT 10B + AsymmVAE 362M，文本编码器 T5-XXL [官方]。
- 官方显存：单卡约 **60GB**；官方同时承认 ComfyUI 可优化到 20GB 以下，但本 repo 实现以灵活性优先、推荐至少 1 张 H100 [官方]。
- 规格：480p（848×480 级）、官方示例 31–85 帧；DiT 精度 BF16 [官方示例代码 model_dtype="bf16"]。
- 许可证：Apache-2.0 [官方]（这点是干净的，但救不了显存）。
- 判断：**判死**。离 6GB 差 3–10 倍，且 BF16。

### 2.8 HunyuanVideo 13B（腾讯，原版）与 HunyuanVideo-1.5（8.3B）

- 原版参数/显存：13B 以上 [官方]；官方要求表：720×1280×129f 峰值 **60GB**，544×960×129f 为 **45GB** [官方]。有 FP8 权重（本卡无效）、GGUF 社区版、HunyuanVideoGP（GPU Poor 版）等社区路线 [官方社区列表]，但社区 GGUF Q4 的现实地板仍在 24GB 级 [社区]。
- 1.5 版：8.3B DiT + 3D 因果 VAE，官方模型卡明示**最低 14GB（开模型卸载）**，480p/720p、默认 121 帧约 5 秒 [官方模型卡]；其 SSTA 注意力以“比 FlashAttention-3 快 1.87 倍”为对照设计 [官方模型卡]，即整个加速叙事建立在 FA3/Hopper 生态上。
- 许可证：Tencent Hunyuan Community License（有地域与 MAU 条款，非 Apache）[社区汇总，未逐字核对许可原文，立项前需复核]。
- 判断：原版与 1.5 **均判死（直跑）**。1.5 的价值只在观察名单：它是“官方显存从 60GB 压到 14GB”的最新样本，证明上游在往低显存走，但还差 8GB 且精度/注意力路线不对。

### 2.9 Wan 2.2 TI2V-5B

- 参数量：5B 稠密模型 + Wan2.2-VAE（压缩比 16×16×4）[官方]。
- 官方显存：TI2V-5B 单卡命令（已带 --offload_model、--convert_model_dtype）官方注“至少 24GB（如 RTX 4090）”，OOM 时再加 --t5_cpu [官方]。A14B 系列官方单卡口径是 80GB [官方]。
- 社区说法：Comfy 原生卸载“应可塞进 8GB” [社区汇总]——仍超 6GB，且无 Maxwell 记录。
- 许可证：Apache-2.0 [官方]。
- 判断：**判死（直跑）**。其高压缩 VAE（16×16×4）是值得单独拆出来研究/借用的组件，但不属本角度结论，留给组件路线研究。

### 2.10 Allegro（Rhymes AI，2.8B）

- 参数量：DiT 2.8B + VAE 175M [官方]。
- 官方显存：单卡 **9.3GB（BF16 + CPU offload）**，不开 offload 为 27.5GB；规格 720×1280、88 帧、6 秒 @15FPS、100 步、单 H100 约 20 分钟 [官方]。
- 致命项：官方精度表 DiT/T5 只列 **BF16/FP32/TF32**（TF32 是 Ampere+ 特性），不列 FP16；环境要求 PyTorch >= 2.4、CUDA >= 12.4 [官方]。
- 有低分辨率研究版（40 帧 ×360P）[官方]，理论上能再压显存，但 BF16 依赖不变。
- 许可证：Apache-2.0 [官方]。
- 判断：**近判死**。参数量不大，但精度路线与本卡正面冲突；除非有人做出 FP16 移植版，否则不投入。

### 2.11 FramePack（Lvmin Zhang，13B Hunyuan 骨架）——最重要的“例外样本”

- 机制：下一帧（段）预测结构，把输入上下文压缩为定长，使**生成工作量与视频时长无关**；官方称可用 13B 模型处理大量帧 [官方]。
- 官方显存：**最低 6GB**——原文：“To generate 1-minute video (60 seconds) at 30fps (1800 frames) using 13B model, the minimal required GPU memory is 6GB. (Yes 6 GB, not a typo.)” [官方]
- 官方硬件门槛（判死依据）：要求 “Nvidia GPU in RTX 30XX, 40XX, 50XX series that supports fp16 and bf16. The GTX 10XX/20XX are not tested.” [官方]；官方一键包是 CUDA 12.6 + PyTorch 2.6 [官方]。
- 许可证：代码 Apache-2.0 [官方]（底座 Hunyuan 权重许可另计）。
- 判断：**权重直跑判死，但它是全轮最有价值的情报**——它用官方实测证明了“13B 级模型 + 6GB 显存”在显存账上是可能的，靠的是架构（定长上下文 + 流式卸载）而不是把模型缩小。这条证据直接支撑后续“做成普通软件”的路线：显存不是参数量的函数，而是内存管理设计的函数。但要注意，它的速度口径是 4090 上 1.5–2.5 秒/帧、笔记本 3060 慢 4–8 倍 [官方]；换到 980 Ti 且被迫 FP32，速度账要重算，大概率是其立项生死线而非显存。

### 2.12 其他扫过但不够格单列的

- Pyramid Flow（miniFLUX / SD3 系）：第三方指南称最低 8GB（开 offload）[社区]，官方 repo 本轮未核到显存表；底座是 FLUX/SD3 的 BF16 生态，>6GB 且精度不对，不立项，证据等级不足，仅留名。
- Open-Sora / Latte 等早期小模型：质量与生态已被上述模型覆盖，本轮未逐个核实，不下结论 [未核实]。

## 3. 横向总表

| 模型 | DiT/UNet 参数 | 文本编码器 | 官方最低显存 | 社区最低（量化/卸载后） | 典型规格 | 训练/推荐精度 | FA 硬依赖 | 许可证 |
|---|---|---|---|---|---|---|---|---|
| CogVideoX-2B | 2B | T5-XXL | 4GB（diffusers FP16）/ 3.6GB（INT8） | 未见低于官方的可靠记录 | 720×480、49f、8fps、6s | FP16 | 否（FP8 路径需 H100，但非必选） | Apache-2.0 |
| AnimateDiff SD1.5 | UNet 0.86B + 运动模块 0.45B | CLIP ViT-L | 未公布 | 约 8GB 起 [社区]；512²×16f 推算 5–7GB | 512²、16f | FP16 | 否 | 代码 Apache + 学术声明；底座 OpenRAIL-M |
| Wan 2.1 1.3B | 1.3B | umT5-XXL | 8.19GB | GGUF+卸载，8GB 级说法 [社区] | 832×480、5s | FP16/BF16 | 推荐非唯一（待读码） | Apache-2.0 |
| LTX-Video 2B distilled | 2B | T5-XXL | 未公布 | 约 8–12GB [社区] | 1216×704、30fps、8 步 | BF16 | 否（有 Q8/GGUF 替代） | OpenRail-M / LTX Open Weights（逐版核对） |
| SVD-XT | UNet 约 1.5B 级 [未逐字核实] | CLIP 图编码 | 未公布；diffusers 全技巧 <8GB | — | 576×1024、25f、仅 I2V | FP16 | 否 | 非商业社区许可 |
| FramePack | 13B（Hunyuan 骨架） | Hunyuan 系 MLLM+CLIP | 6GB | — | I2V、最长 60s/1800f | FP16+BF16（官方限 RTX 30 系+） | 否（默认 PyTorch 注意力） | 代码 Apache-2.0 |
| HunyuanVideo-1.5 | 8.3B | MLLM 系 | 14GB（卸载） | GGUF 等社区路线未核到 <14GB 记录 | 720p、121f、约 5s | BF16 | 设计对照 FA3 | 腾讯混元社区许可 |
| Wan 2.2 TI2V-5B | 5B | umT5-XXL | 24GB | 约 8GB [社区] | 720p、24fps | FP16/BF16 | 推荐 | Apache-2.0 |
| Allegro | 2.8B | T5 | 9.3GB（BF16+卸载） | — | 720×1280、88f、15fps、6s | BF16（DiT 不列 FP16） | 否 | Apache-2.0 |
| LTX-2/2.3/2.5 | 19–22B | Gemma 3/4 12B | 未公布（BF16 文件约 66GiB） | GGUF 地板 12GB | 最高 4K、音视频 | BF16 | 新卡路线 FA3/FA4 | LTX-2.x 社区许可 |
| Mochi 1 | 10B | T5-XXL | 约 60GB | Comfy <20GB [官方转述] | 480p | BF16 | 可选 flash | Apache-2.0 |
| HunyuanVideo 13B | 13B+ | MLLM | 45–60GB | GGUF Q4 约 24GB [社区] | 720p、129f | BF16/FP8 权重 | 否（xDiT 等生态） | 腾讯混元社区许可 |

## 4. 已判死的路线清单（附判死证据）

1. **一切 FP8 路径**（Wan FP8、CogVideoX FP8、LTX fp8、Hunyuan FP8 权重、LTX-2 的 fp8-scaled-mm）：FP8 需要 Hopper/Ada 级硬件支持；官方亦明示如 CogVideoX“FP8 必须用 H100 以上、CUDA 12.4” [官方]。Maxwell 无 FP8 单元，软件模拟等于自杀式减速。此路判死。
2. **FlashAttention 2/3 作为唯一注意力实现**：FA2 官方支持列表只有 Ampere/Ada/Hopper + FP16/BF16 [flash-attn 官方 README]。凡锁死 FA 的代码在 SM52 上第一步就起不来；可移植的模型必须有 SDPA math / 切片注意力回退，且回退后要重新算显存（N² 矩阵实体化）。此路判死（指“原样照搬 FA 代码”判死，不是模型本身）。
3. **BF16 原生权重直跑**（LTX 全系、LTX-2、CogVideoX-5B/1.5、Mochi、Hunyuan 全系、Allegro DiT、Wan A14B）：SM52 无 BF16 硬件，官方显存数字全部建立在 BF16 驻留上，搬过来要么 FP32 翻倍爆显存、要么算子不支持。判死的是“直跑官方权重+官方代码”，逐个做 FP16 转换移植是另一个工程问题（数值风险自担）。
4. **LTX-2/2.3/2.5 本体**：BF16 文件组约 66GiB、GGUF 最小可用档文件本身 9.5–14GB、社区工作流地板 12GB VRAM + 48GB 内存 [官方/社区]。6GB 内无任何已报告配置。判死。
5. **Mochi 1、HunyuanVideo 13B、Wan 2.2 A14B 本体直跑**：官方显存 45–80GB 量级，社区极限压缩后仍在 24GB 级。判死。
6. **HunyuanVideo-1.5 直跑**：官方地板 14GB（已开卸载）且注意力设计以 FA3 为基线。判死（保留观察：等其更小蒸馏版或 FP16 移植版出现再重估）。
7. **SVD 用于本项目目标**：技术能跑、许可判死——非商业社区许可与“抖音商单”目标冲突；且无文本控制。判死（项目维度）。
8. **依赖最新软件栈的新模型发行版**：要求 torch>=2.8（cu128/cu130 构建）或 CUDA 13 的一切默认安装路径，在 SM52 上装不上 [PyTorch 官方公告]。这不是某个模型的错，是整条“跟着最新版走”的路线判死——本项目必须冻结在 torch 2.4–2.6 + CUDA 12.4/12.6 的 legacy 窗口里开发。
9. **SageAttention / Triton 融合内核类加速**：主流实现面向 SM75/80+，本轮零 SM52 验证记录。按判死处理，除非有人拿出 SM52 实测（举证责任在主张可用的一方）。

## 5. 没有判死、但必须实测才能升级为“可行”的

- CogVideoX-2B 的 diffusers FP16 全优化链在 SM52 上是否完整跑通（torchao 不要碰、先纯 FP16）；跑通后实测峰值显存与单条耗时。
- AnimateDiff SD1.5 在 512×768（竖屏近似）×16–24 帧下的真实峰值显存（推算 5–7GB 必须被实测证实或证伪）。
- Wan 2.1 1.3B 的注意力回退路径（读码确认无 FA 时走什么）与 GGUF Q5/Q4 + T5 CPU + VAE tiling 的 6GB 挑战（差 2.19GB，理论上靠量化 DiT 权重可补，但激活峰值未知）。
- LTX-Video 2B distilled 转 FP16 的数值可行性（BF16→FP16 不是无损操作，官方从未提供 FP16 版）。

## 6. 给下一阶段的实验队列（按性价比排序）

1. AnimateDiff SD1.5：最快拿到“6GB/SM52 真实出片”的是非判定（预计工作量最小，软件栈年代对口）。
2. CogVideoX-2B diffusers FP16：现代 DiT 质量基准的是非判定；重点记录 sequential offload 在 PCIe 3.0 上的速度惩罚。
3. Wan 2.1 1.3B GGUF：前两条有任一跑通后再投入，先读码确认注意力回退。
4. FramePack 只做架构拆解阅读（定长上下文/流式权重管理），不做权重移植尝试——它的价值在设计不在权重。

## 7. 主要来源（均为本轮实际打开/检索到的页面）

- Wan 2.1 官方 repo：https://github.com/Wan-Video/Wan2.1 （8.19GB、4090 约 4 分钟、offload/t5_cpu 示例、Apache-2.0、torch>=2.4）
- Wan 2.2 官方 repo：https://github.com/Wan-Video/Wan2.2 （TI2V-5B 至少 24GB、A14B 至少 80GB、flash_attn 安装说明、VAE 压缩 16×16×4）
- LTX-Video 官方 repo：https://github.com/Lightricks/LTX-Video （2B/13B 型号表、distilled 8 步、Q8 社区版、测试环境 CUDA 12.2 / PyTorch>=2.1.2、0.9.5 起 OpenRail-M）
- LTX-2 官方 repo：https://github.com/Lightricks/LTX-2 （2.5 下载约 66GiB BF16、Gemma 4 12B 编码器、FP8/offload 优化提示、FA4/FA3/SDPA 分工）
- CogVideo 官方 repo：https://github.com/zai-org/CogVideo （2B：diffusers FP16 起步 4GB / INT8 起步 3.6GB、GTX 1080 Ti 可跑、Ampere 以上脚注、2B 改 Apache-2.0、FP8 需 H100+）
- AnimateDiff 官方 repo：https://github.com/guoyww/AnimateDiff （运动模块 453M/1.7GB、SDXL 版约 13GB、学术使用声明）
- Stability generative-models 官方 repo：https://github.com/Stability-AI/generative-models （SVD 14 帧 / XT 25 帧、576×1024、低显存 decoding_t 建议）
- diffusers SVD 文档：https://huggingface.co/docs/diffusers/main/en/api/pipelines/stable_diffusion/svd （全技巧叠加 <8GB）
- HunyuanVideo 官方 repo：https://github.com/Tencent-Hunyuan/HunyuanVideo （13B、60GB/45GB 要求表、FP8 权重、社区 GGUF/GP 版列表）
- HunyuanVideo-1.5 模型卡：https://huggingface.co/tencent/HunyuanVideo-1.5 （8.3B、最低 14GB 开卸载、SSTA 对照 FA3 的 1.87 倍）
- FramePack 官方 repo：https://github.com/lllyasviel/FramePack （最低 6GB 原文、限 RTX 30/40/50 系、CUDA 12.6 + PyTorch 2.6 一键包、默认 PyTorch 注意力）
- Mochi 官方 repo：https://github.com/genmoai/mochi （10B、单卡约 60GB、Comfy <20GB、BF16、Apache-2.0）
- Allegro 官方 repo：https://github.com/rhymes-ai/Allegro （2.8B、9.3GB BF16+offload、DiT 精度不列 FP16、PyTorch>=2.4 / CUDA>=12.4、Apache-2.0）
- PyTorch 官方公告（2.8 起 cu128/cu129 移除 Maxwell/Pascal）：https://dev-discuss.pytorch.org/t/cuda-toolkit-version-and-architecture-support-update-maxwell-and-pascal-architecture-support-removed-in-cuda-12-8-and-12-9-builds/3128
- flash-attn 官方说明（FA2 仅 Ampere/Ada/Hopper、仅 FP16/BF16）：https://www.pypi.org/project/flash-attn/2.6.2
- ComfyUI-GGUF（city96，支持 Wan 2.1 / LTXV / Hunyuan 架构量化）：https://deepwiki.com/city96/ComfyUI-GGUF
- LTX-2.5 GGUF（Unsloth，UD-Q4_K_XL 14.0GB / UD-Q2_K_XL 9.5GB）：https://huggingface.co/unsloth/LTX-2.5-GGUF/blob/main/README.md

---
注：本文件只覆盖角度 A（现成开源扩散模型的低显存极限）。非扩散组件管线、极端压缩/窄域蒸馏分别见研究 B、C。文中所有 [推算] 数字在实测前不得引用为结论。
