# 研究 E6：读码裁决 — CogVideoX-2B 能否在 GTX 980 Ti 上以现成路径运行

- 日期：2026-10-22
- 目标硬件：GTX 980 Ti（Maxwell GM200，SM52，6GB GDDR5，336 GB/s，FP32 约 6.1 TFLOPS，无 Tensor Core、无 FP16/BF16 原生算力单元）
- 目标软件栈：测试包钉死版本 torch==2.6.0（cu126）/ torchvision==0.21.0 / diffusers==0.33.1 / transformers==4.49.0 / accelerate==1.4.0（下文第 5 节核对此组合）
- 彻查对象：HF 官方仓库 THUDM/CogVideoX-2b 的全部权重文件与 config、THUDM/CogVideoX 官方 GitHub README、diffusers 源码（CogVideoXPipeline / CogVideoXTransformer3DModel / attention_processor）、PyTorch 官方 SDPA 后端支持矩阵与版本支持公告、社区实测记录
- 方法论：沿用 E5 对 LTX-2B 的逐项查法（dtype 写死、注意力后端、VAE、文本编码器体积、官方硬件口径、社区老卡实测），证据分级 A=官方原文/源码、B=第三方结构化数据、C=博客自述、D=不可采信

## 0. 裁决（一句话）

**【改配置可跑】：CogVideoX-2B 不存在 LTX 式判死项——权重原生 FP16 存储、官方推荐精度就是 FP16、注意力是无后端钉死的裸 SDPA 调用且存在 SM40+ 可用的 mem-efficient 后端、官方「4GB 起步」数字本身就是 sequential CPU offload 口径、T5-XXL 从不需要全量驻留显存。跑通所需的全部措施（FP16 加载、sequential offload、VAE tiling/slicing、SDPA 后端显式指定、VAE FP32 保险）都是 diffusers/PyTorch 的公开 API 配置，不需要改任何库代码或模型代码。但有两个二元未知数只能由 E2 真机运行关闭（见第 7 节），E2 回传前对外口径只能是「代码级裁决可跑、待真机验证」，不得称「已跑通」。**

与 E5（LTX-2B 判「需周级自研改造」）逐项对照——同一把尺子，结论相反的原因全在证据：

| 检查项 | LTX-2B（E5） | CogVideoX-2B（本裁决） |
| --- | --- | --- |
| 权重存储 dtype | BF16，SM52 无 BF16 硬件 | **FP16**（仓库文件字节数逐个吻合，见 1.1），且官方称 2B 训练精度即 FP16 |
| 官方显存口径 | 从未公布 2B 数字 | FP16 + 优化全开 **4GB 起步**，且该数字就是 offload 口径（见第 3 节） |
| 文本编码器 | T5-XXL 被漏算，FP32 权重 9.68GB 直接超显存 | 同为 T5-XXL（FP16 约 9.52GB），但 sequential offload 下逐块流式、从不全量驻留 GPU；也可预计算 embeds 彻底剥离（见 3.2） |
| 注意力后端 | flash/mem-efficient 对 BF16 要求 SM80 级，逐管线踩雷 | 裸 `F.scaled_dot_product_attention` 不钉后端；mem-efficient 后端官方支持矩阵为 SM40+、FP16 可用（见第 2 节） |
| 官方老卡口径 | 无 | README 明文「可在 GTX 1080 Ti 等老卡上运行 2B」（Pascal，非 Maxwell，见第 4 节） |

## 1. 问题 1：dtype 路径——FP16 是否全程可用，有无 BF16 写死或 FP8 假设

### 1.1 仓库权重就是 FP16 存储（字节数实证，A 级）

HF 官方仓库 THUDM/CogVideoX-2b 文件清单（api/models 接口逐文件字节数）：

| 组件 | 文件字节数 | ÷2 B/参 推得参数量 | 结论 |
| --- | --- | --- | --- |
| text_encoder（T5-XXL 编码器，2 分片） | 4,994,582,104 + 4,530,066,248 = 9,524,648,352 B | 约 4.76B | FP16 存储 |
| transformer | 3,387,650,264 B | 约 1.69B | FP16 存储 |
| VAE | 862,388,596 B | 约 0.43B | FP16 存储 |
| **全套合计** | **约 13.77GB（磁盘/主机内存占用）** | | |

- `text_encoder/config.json`：`torch_dtype: "float16"`，架构为 google/t5-v1_1-xxl 编码器（24 层、d_model 4096、词表 32128）。
- `transformer/config.json`：30 层、30 头 × head_dim 64（inner dim 1920）、max_text_seq_length 226、sample 90×60×49、patch_size 2、temporal_compression_ratio 4、2B 用 3D sincos 位置编码（use_rotary_positional_embeddings false）。
- `model_index.json` 的 `_diffusers_version` 为 0.30.0.dev0（即官方以 diffusers 0.30 开发线验证发布，第 5 节用）。

### 1.2 官方精度口径：FP16 是训练精度，不是降级选项（A 级）

官方 README 原文（2026-10-22 查阅）：

- 精度表（L401 一带）列 FP16*（推荐）、BF16、FP32、FP8*、INT8 五档，FP16 带星为推荐项。
- L568–570：「The CogVideoX-2B model was trained in FP16 precision… We recommend using the precision in which the model was trained.」——2B 不存在 LTX 那种「权重按 BF16 训练分布长、转 FP16 有溢出风险」的先天问题，因为它本来就是 FP16 训的。
- FP8 仅出现在 torchao 量化路径且官方注明需 H100+（L578–580）——是可选支线，标准 diffusers 路径不碰，不构成 FP8 假设。
- diffusers 管线 docstring 的官方示例（pipeline_cogvideox.py L94）就是 `CogVideoXPipeline.from_pretrained("THUDM/CogVideoX-2b", torch_dtype=torch.float16)`——整管线（含 T5、VAE）一把 FP16，是官方第一推荐姿势。

### 1.3 管线代码无 dtype 强制点（A 级，源码核查）

对 diffusers 主线 `pipelines/cogvideo/pipeline_cogvideox.py`（1494 行）全文核查：

- 全文检索 `float32` **零命中**、`autocast` **零命中**——管线不在任何环节把张量偷偷上采 FP32 或改精度。
- `_get_t5_prompt_embeds`（L374–448）：`dtype = dtype or self.text_encoder.dtype`（L392），编码后 `prompt_embeds.to(dtype=dtype, device=device)`（L434–436）——精度跟随加载 dtype 传播，不写死。
- VAE 解码（L660）：`frames = self.vae.decode(latents).sample` 裸调用，latent 以 FP16 直入直出，无 cast。
- `model_cpu_offload_seq = "text_encoder->transformer->vae"`（L317）——sequential offload 的组件顺序是管线写明的官方设计，不是民间偏方。

结论：`from_pretrained(torch_dtype=torch.float16)` 后 transformer / VAE / T5 三件全程 FP16，无 BF16 写死、无 FP8 假设。唯一保留项是 Maxwell 上 FP16 的**数值行为**（个别算子在老架构上的内核实现质量）属真机验证范畴，见第 7 节第 2、3 条——这与 LTX 的「FP16 从未被官方支持、溢出风险不可排除」有本质区别：CogVideoX 的 FP16 是官方训练与推荐精度。

## 2. 问题 2：注意力后端——SM52 上走哪条，有无 xformers 硬依赖

### 2.1 处理器实现：裸 SDPA，不钉后端（A 级，源码核查）

- diffusers `models/transformers/cogvideox_transformer_3d.py` L193：CogVideoXBlock 默认注意力处理器就是 `CogVideoXAttnProcessor2_0()`。
- diffusers `attention_processor.py` 中 `CogVideoXAttnProcessor2_0` 类（L4180 起）的核心只有一句（L4272–4276）：

  `F.scaled_dot_product_attention(query, key, value, attn_mask=attention_mask, dropout_p=0.0, is_causal=False)`

  不指定任何后端、不用 xformers 算子，完全交给 PyTorch 的 SDPA 分发器按硬件能力选后端。
- xformers 在该文件中仅于文件头 L61–69 以 `is_xformers_available()` 条件导入，只供另一组 XFormers 专用处理器类使用——**CogVideoX 路径无 xformers 硬依赖**，没装 xformers 也能跑（这点对 SM52 很重要：xformers 官方轮子早已不覆盖 Maxwell）。

### 2.2 三条 SDPA 后端在 SM52 上的命运（A 级，PyTorch 官方口径）

PyTorch 官方博客（Accelerating Large Language Models with SDPA）给出的后端支持矩阵：

| 后端 | 架构要求 | dtype | SM52 可用性 |
| --- | --- | --- | --- |
| flash（FlashAttention 内核） | SM80+ | 仅 16-bit | **不可用**（分发器会自动跳过，不报错） |
| mem_efficient（xformers 系 cutlass 内核） | **SM40+** | 32/16-bit 均可 | **可用**——head_dim=64 在其约束内 |
| math（朴素实现） | 任意 | 任意 | 可用但**显存物理不可能**，见 2.3 |

T2V 路径传给 transformer 的 attention_mask 为 None（处理器默认），无 mask 是 mem_efficient 最有利的情形（带任意 mask 时该后端会退化或报错，此处不触发）。

### 2.3 为什么 math 后端是死路、且这件事决定 E2 的头号验证点

CogVideoX 注意力是文本+视频联合注意力，序列长 = 文本 226 + 视频 token 13 潜帧 ×(60/2 × 90/2 = 1350) = 17,550，合计 **17,776**。CFG 在 diffusers 里是 batch 维拼接（batch=2）一次前向。math 后端要物化完整分数张量：

2（batch）× 30（头）× 17,776² × 2 B ≈ **37.9GB** —— 6GB 卡上直接 OOM，不是「慢」，是跑不了。

因此整件事的成败系于一个二元事实：**PyTorch 2.6 的 SDPA 分发器在 SM52 + FP16 + 此形状下是否确实落到 mem_efficient（分块计算、不物化）**。按官方支持矩阵应当落到，但 Maxwell 从未被任何人实测过（第 4 节），故列为 E2 头号验证点，并在第 8 节建议把这一验证前置成一个 1 分钟的独立微基准，不要等整管线跑起来才发现。

## 3. 问题 3：显存账——sequential offload + VAE tiling/slicing 全开

### 3.1 分组件账（估算，与官方数字交叉验证）

sequential CPU offload 的本质：任何时刻 GPU 上只驻留「当前正在执行的子模块」的权重，其余全在主机内存。峰值不由 13.77GB 的整模型决定，由单步工作集决定：

| 项 | 估算 | 依据 |
| --- | --- | --- |
| CUDA 上下文 + PyTorch 运行时开销 | 约 0.5–0.7GB | 常规量级 |
| 流式驻留权重（采样期） | 约 0.1GB | 单个 CogVideoXBlock 约 44.2M 参数（attn 约 14.75M + FFN 约 29.49M，inner 1920 / FFN 7680）≈ 88MB FP16，逐块进出 |
| 流式驻留权重（T5 编码期） | 约 0.4GB | T5-XXL 单层约 193M 参数 ≈ 386MB FP16，是全程最大的单个流式单元；词嵌入表约 263MB |
| transformer 单步激活（batch 2，seq 17,776） | 约 1.0–1.8GB | 单个 hidden 张量 2×17,776×1920×2B ≈ 137MB；FFN 中间 7680 维瞬时张量约 546MB；mem_efficient 注意力不物化分数矩阵 |
| VAE 解码段（tiling+slicing 开） | 约 0.3–0.8GB | 分块解码后激活与帧数解耦，只随 tile 尺寸走 |
| **总峰值估算** | **约 2.5–4.0GB** | 与官方「diffusers FP16 优化全开 4GB 起步」自洽；6GB 内留约 2–3.5GB 余量 |

交叉验证（A 级）：官方 README 的显存数字明确就是这套优化方案（sequential offload + VAE 切分）的口径，且脚注（L540–548）称关掉优化峰值约 3 倍、速度快 3–4 倍——即官方 4GB 与「不开优化约 12GB」互为印证，账面对得上。这与 LTX 的情形根本不同：LTX 官方从未给过 offload 口径的数字，C 路线的账是自己拼的。

### 3.2 T5 放 CPU 的可行性与代价

T5-XXL 的 FP16 权重 9.52GB 是磁盘/内存数字，**不是显存数字**，三种处置：

1. **sequential offload（默认，推荐）**：T5 逐层流式上 GPU 做一次编码（226 token，计算量可忽略），编完即整件退回主机内存，去噪全程不再出现。代价：一次性 PCIe 搬运 9.52GB ≈ 1 秒量级，可忽略。
2. **prompt_embeds 预计算剥离**：管线原生支持传入 `prompt_embeds` / `negative_prompt_embeds` 跳过文本编码器（encode_prompt 签名自带这两个参数）。可在 CPU 上（甚至别的机器上）预先算好每个提示词的 embeds 缓存，运行时 T5 根本不加载。代价：CPU 跑 T5-XXL FP16 一次前向在弱 CPU 上是分钟级，但一次性、可缓存。
3. **代价的真正所在——主机内存**：offload 模式下全套 13.77GB 权重常驻主机 RAM（from_pretrained 先全量载入内存）。**主机 RAM ≥16GB 是勉强线（须留系统余量、防 swap 抖动），32GB 稳妥。** 这是 E2 机器的隐含前提，现有 E2 脚本未写明（第 8 节建议补）。

## 4. 问题 4：Maxwell / Pascal 实测与失败记录

逐条注明出处与可信度；先说总结：**SM52 上的 CogVideoX 记录为零——既无跑通也无失败，可核查记录一条都没有。**

| # | 记录 | 出处 | 等级 | 说明 |
| --- | --- | --- | --- | --- |
| 1 | 「You can run CogVideoX-2B on older GPUs like GTX 1080TI」 | 官方 README 更新日志，2024-08-27 条目（L102 一带） | A（官方声明）/ 但无实测日志 | 唯一官方老卡背书。注意：1080 Ti 是 **Pascal SM61、11GB**，比 Maxwell 新一代且显存近两倍——证明「官方认为老卡路径成立」，不证明 SM52/6GB 成立 |
| 2 | diffusers 性能数字「has not been tested for actual memory usage on devices outside of NVIDIA A100 / H100… this scheme can be adapted to all NVIDIA Ampere architecture and above devices」 | 官方 README 脚注（L540–546） | A | 官方口径的下限明说到 Ampere 为止；Ampere 以下属「未测区」，不是「明确不支持」 |
| 3 | 5B 管线 sequential offload 峰值 <4GB、tiling+model offload 11GB | HF diffusers CogVideoX 文档页 | A（机制量级旁证） | 证明 offload 机制的量级真实，非 2B 数字，不直接移植 |
| 4 | 2B 单条约 2–3 分钟、5B 约 9 分钟 | ominousindustries 民间博客 | C | 硬件未明示（现代卡），仅作「模型本身算量不大」的量级旁证，不用于 980 Ti 外推 |
| 5 | **Maxwell（SM50/52）跑通或失败记录：零条** | 本次检索范围：GitHub（diffusers / CogVideoX / ComfyUI issue）、Reddit、论坛，多轮关键词检索只返回硬件规格页 | 阴性证据 | 与 E5 对 LTX 的结论同型：不能证明不可能，只证明**无人验证过**——E2 就是第一个验证者 |

## 5. 问题 5：软件栈窗口——钉死版本与 SM52 是否冲突

- **torch 上限是硬墙**（A 级）：PyTorch 官方 dev-discuss（2025-07-14）宣布自 2.8 起，CUDA 12.8/12.9 构建移除 Maxwell 与 Pascal 支持；第三方支持表（B 级，journal.qualiteg.com）与之吻合：torch 2.1–2.7 的轮子含 SM_50 家族，2.8+ 的 cu128 轮子只剩 SM_70 起。CUDA 13 本身更移除 CC<7.5。**推论：排障时绝不能靠「升级 torch」解决——升过 2.8/cu128 等于直接判死。**
- **测试包钉死组合在窗口内且自洽**：torch 2.6.0（cu126，含 SM_52 内核）+ diffusers 0.33.1 + transformers 4.49.0 + accelerate 1.4.0，均为 2025 年初同期版本，互无已知冲突。
- **CogVideoX 对 diffusers 的版本要求**：仓库 model_index 标注 `_diffusers_version 0.30.0.dev0`，即需要 diffusers ≥0.30；0.33.1 满足且留有余量。反向也成立：没有理由为 CogVideoX 去动 diffusers 大版本。
- 结论：软件栈**无冲突、无需调整**，维持测试包钉死版本原样。

## 6. 问题 6：速度外推（估算，方法与假设全公开）

### 6.1 算量模型（先用官方数字校准，再外推）

720×480、49 帧、50 步、CFG 开：

- 每步前向 FLOPs：线性部分 ≈ 2 × 1.69e9 参数 × 17,776 token ≈ 60 TFLOP；注意力二次项 ≈ 4 × 17,776² × 1920 × 30 层 ≈ 36 TFLOP；合计约 96 TFLOP/次前向，CFG 双份 ≈ **193 TFLOP/步**。
- 校准：A100 FP16 峰值 312 TFLOPS，按约 35% 实际利用率（约 110 TFLOPS 有效）→ 50 步 ≈ 88 秒 ≈ 官方公布的 A100 约 90 秒（H100 约 45 秒，出处：官方 README 性能表 L436–441、L582–584，A 级）。模型与官方锚点吻合，外推方法可用。

### 6.2 搬到 980 Ti（估算，C 级方法论）

- 980 Ti FP32 峰值约 6.06 TFLOPS。Maxwell 无 FP16 算力单元：FP16 GEMM 经 cuBLAS 以 FP32 数据通路执行（无 FP16 加速；消费级 Pascal 的 FP16 1/64 悬崖是 `__half2` 内联路径问题，GEMM 不走该路——此点为 B/C 级推断，E2 实测可证伪）。按有效算力 3.0–4.5 TFLOPS 估：
- **每步约 43–64 秒 → 50 步（官方规格）约 36–54 分钟；E2 的 30 步约 22–32 分钟。**
- 附加项：T5 编码（流式搬运+小计算）约 1 分钟内；分块 VAE 解码 49 帧估约 1–4 分钟；sequential offload 每步流式搬运 transformer 权重 3.39GB ÷ PCIe 3.0 约 12GB/s ≈ 0.3 秒/步，相对 43–64 秒的计算可忽略——offload 在此不构成速度瓶颈，瓶颈纯在 FP32 速率的算力。
- **总量级：单条数十分钟（E2 配置约 25–40 分钟，官方 50 步配置约 40–60 分钟），约为 A100 的 25–40 倍慢，不是数小时。** 若真机每步时间落在预测带外（尤其 FP16 GEMM 走了慢路径），按上限再乘约 1.5 倍仍在 1.5 小时内——可用，但只适合夜间批处理式生产，不适合交互迭代。

## 7. 真机验证清单（E2 必须关闭的二元未知数）

以下四条读码无法定论，任何一条翻车都不改变「代码路径成立」的裁决，但决定「实际能跑/不能跑」：

1. **SDPA 后端分发**：torch 2.6 在 SM52 + FP16 + (2, 30, 17776, 64) 形状下是否落 mem_efficient。落 math = OOM 判死当场；落 mem_efficient = 全线打通。（第 2.3 节）
2. **FP16 GEMM 的速度与数值**：每步秒数是否落在 43–64 秒带内；去噪全程有无 NaN/inf。
3. **VAE FP16 解码数值**：Maxwell 上 FP16 VAE 解码是历史上有名的黑帧/NaN 高发点。翻车处置是现成的：`pipe.vae.to(torch.float32)` 单独把 VAE 升 FP32（多付约 0.86GB 瞬时，账内有余量）——这是配置项，不是补丁。
4. **主机 RAM**：运行机 RAM <16GB 时 offload 会 swap 抖动，表现为「慢到像卡死」而非报错，须先排除再下结论。

## 8. 对 E2 测试脚本的修改建议（只建议，不改本体）

现脚本（files/testkit_980ti/e2_cogvideox2b.py）姿势正确：`torch_dtype=torch.float16` + `enable_sequential_cpu_offload()` + `vae.enable_tiling()/enable_slicing()`，720×480×49 帧、30 步、guidance 6.0、seed 42 均合官方规格。建议改动如下，按重要性排序：

1. **前置 SDPA 微基准（最重要）**：在加载管线之前，先以 CogVideoX 真实形状（batch 2、30 头、seq 17776、head_dim 64、FP16、cuda）单独跑一次 `F.scaled_dot_product_attention`，打印实际可用后端与单次耗时。把头号二元风险（第 7 节第 1 条）变成 1 分钟出结果的独立检查，与模型加载失败解耦。
2. **显存测量改峰值统计**：现脚本用 0.5 秒采样线程读 `memory_allocated()`——会漏掉采样间隙的瞬时峰值，且只计 allocated 不计 reserved。建议生成前 `torch.cuda.reset_peak_stats()`，生成后以 `torch.cuda.max_memory_allocated()` 为主数字打印（采样线程可保留作旁证）。脚本头注释已自承「sampled, not exact」，此改即把它变 exact。
3. **显式指定 SDPA 后端并记录**：主调用外包一层后端上下文（torch 2.6 用 `torch.nn.attention.sdpa_kernel`，指定 EFFICIENT_ATTENTION 优先、MATH 兜底），并把 `torch.backends.cuda.mem_efficient_sdp_enabled()` 等状态打进脚本头部的环境行。目的：后端选择从「分发器默认行为」变成「日志里可核查的事实」。
4. **每步进度打印**：给 `pipe(...)` 加 `callback_on_step_end`，每 5 步打印累计耗时。30 步预计跑 25–40 分钟，没有进度输出时「慢」与「挂死」无法区分，容易被误杀。
5. **VAE FP32 保险开关 + 输出体检**：预留一个常量开关，开启时在调用前执行 `pipe.vae.to(torch.float32)`；无论开关与否，生成后把帧的 mean/std/min/max 打进 E2_RESULT——让回传日志能区分「跑通了」与「跑通且画面正常」（黑帧 NaN 的 std 会接近 0）。
6. **OOM 定位**：单独捕获 `torch.cuda.OutOfMemoryError`，打印失败时 `max_memory_allocated`，以便定位是哪一阶段爆的，而不是只回一句 FAILED。
7. **脚本头补前提注释**：主机 RAM ≥16GB（推荐 32GB）、权重下载约 13.8GB、预计墙钟 25–40 分钟、torch 必须保持 2.6.0+cu126（禁止升级，2.8+ cu128 移除 SM52）。

## 9. 最终裁决

**【改配置可跑】**

理由汇总：与 LTX-2B 的判死项逐项对照，CogVideoX-2B 全部反转——FP16 原生权重与官方推荐精度一致（第 1 节）、注意力无硬依赖且有 SM40+ 后端可用（第 2 节）、官方 4GB 数字本身就是 offload 口径且分组件账自洽（第 3 节）、软件栈钉死版本无冲突（第 5 节）、速度量级为数十分钟可用区（第 6 节）。所需措施全部是公开 API 配置（第 8 节），不构成「补丁」，更够不上「判死」。唯一保留：Maxwell 实测记录为零（第 4 节），第 7 节四条二元未知数须由 E2 真机关闭；E2 回传前，本裁决的对外表述上限是「代码级裁决可跑」。

## 来源清单

A 级（官方原文/源码，2026-10-22 查阅）：
- HF 仓库 THUDM/CogVideoX-2b：文件字节清单（api/models 接口）、text_encoder/config.json、transformer/config.json、model_index.json
- THUDM/CogVideoX GitHub README：精度表与 FP16 训练精度声明（L401、L568–570）、FP8 torchao 需 H100+（L578–580）、1080 Ti 老卡条目（L102）、性能表（L436–441、L582–584）、显存数字适用范围脚注（L540–548）
- diffusers 源码（main）：pipelines/cogvideo/pipeline_cogvideox.py（L94、L317、L374–448、L660，全文 float32/autocast 检索零命中）、models/transformers/cogvideox_transformer_3d.py（L193）、attention_processor.py（L61–69、L4180、L4272–4276）
- PyTorch 官方博客《Accelerating Large Language Models》：SDPA 后端架构/dtype 支持矩阵
- PyTorch 官方 dev-discuss（2025-07-14）：2.8 起 cu128/cu129 构建移除 Maxwell/Pascal
- HF diffusers CogVideoX 文档页：offload 显存量级（5B 口径，机制旁证）

B 级：
- journal.qualiteg.com《PyTorch Versions and Supported NVIDIA GPU Compute Capability Levels》：版本×SM 支持表（与官方公告互证）

C 级：
- ominousindustries 博客 CogVideoX 实测（硬件未明示，仅量级旁证）
- 本报告第 6 节速度外推（方法经 A100 官方锚点校准，数值本体为估算）

阴性证据：
- 2026-10-22 对 GitHub issue / Reddit / 论坛的多轮检索：Maxwell（SM50/52）上 CogVideoX 的跑通与失败记录均为零；Pascal 上无独立可核查的计时日志（仅官方声明）
