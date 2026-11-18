# 研究 E5：读码裁决 — LTX-2B distilled 能否在 GTX 980 Ti 上以回退路径运行

- 日期：2026-10-22
- 目标硬件：GTX 980 Ti（Maxwell GM200，SM52，6GB GDDR5，336 GB/s，FP32 约 6.1 TFLOPS，无 Tensor Core、无 BF16/FP16 原生算力、无 DP4A）
- 目标软件栈：PyTorch 2.4–2.6 + CUDA 12.x（注：PyTorch 2.1–2.6 的官方支持表仍含 SM_50 家族，2.8 起 cu128 构建去掉 Maxwell；本裁决只在 2.4–2.6 前提下成立）
- 彻查对象：Lightricks/LTX-Video 官方 repo（main 分支，commit 4b2d053）、diffusers 的 LTXPipeline / LTXConditionPipeline、ComfyUI-LTXVideo 及社区 GGUF/Q8 路径、第三方独立实现（candle-video）的实测数据
- 冲突来源：情报 C（research_C_compression.md 第 8.2 节「配置 A」）外推峰值显存 3.9–5.1GB 并称「今天就能动手验证」；情报 A（research_A_lowvram_models.md 第 2.2 节）指出权重 BF16 原生、SM52 无 BF16 硬件、官方显存数字不成立

## 0. 裁决（一句话）

**需改造（且改造量为周级自研，不是改配置）：官方三条现成路径（官方 repo inference.py、diffusers LTXPipeline、ComfyUI 默认工作流）在 980 Ti 上按原样不可跑；存在一条理论上可落地的回退路径（FP16 权重 + 文本编码器预计算/卸载 + 顺序 offload + 分块 VAE 解码 + 降低帧数/分辨率 + 强制非 Flash 注意力后端），显存账在降规格后勉强可入 6GB，但该路径从未在 SM52 上被任何人实测过，「今天可验证」不成立——今天可验证的只有「按官方方式跑不起来」这一半。**

情报 A 与情报 C 的对错分解：

- A 对：官方权重与官方配置均为 BF16；官方从未公布 2B 的显存数字；T5-XXL 是隐藏的大头。这些是代码/原文事实（见第 1–4 节证据）。
- C 的 3.9–5.1GB 账错在何处：它把四个不同实现里各自最乐观的一项拼在一起——Q8 存储（diffusers/ComfyUI 现成实现里不存在「Q8 存储 + FP32 计算」这条路，见 1.4）、FP32 激活 1.2–1.8GB（默认注意力后端在 FP32 下会物化全头注意力矩阵，见第 6 节 P4/P6 行注）、VAE 分块后 0.4–0.8GB（光 VAE 权重 FP32 就 1.68GB，见第 3 节）、且默认这些组件从不共存。它算的是一个「尚待自研的定制运行时」的设计目标，不是任何现成代码今天能跑出的数字。C 自己在第 3.2 节第 2 条其实写了这一点（GGUF 反量化目标须改为 FP32 按块流式，「是自研工作，没有现成节点可用」），但第 8.2/10 节又把配置 A 称为「今天就能动手验证的路线 / 真机冒烟」，自相矛盾。本裁决以 C 第 3.2 节的自我修正为准，推翻其第 8.2 节的口径。

## 1. 问题 1：权重 dtype 是写死还是可配置？改 FP32/FP16 后发生什么？

### 1.1 现成代码里 dtype 的决定点（全部可配置，但所有官方预设都是 BF16）

| 路径 | dtype 决定点 | 官方预设值 | 证据等级 |
| --- | --- | --- | --- |
| 官方 repo | pipeline 的 YAML 配置字段 `precision`，由 `ltx_video/inference.py` 的 InferenceConfig 读取；根目录 inference.py 只是 13 行的 HfArgumentParser 薄包装 | `configs/ltxv-2b-0.9.8-distilled.yaml` 第 20 行：`precision: "bfloat16"`；其余 2B/13B 官方 config 同为 bfloat16（另有 fp8 变体 config） | A（原文读码） |
| diffusers | `LTXPipeline.from_pretrained(..., torch_dtype=...)`，调用方参数，不传则按 diffusers 默认以 FP32 加载 | 官方文档与模型卡所有示例均传 `torch.bfloat16`；模型卡 Notes 原文：「The recommended dtype for the transformer, VAE, and text encoder is torch.bfloat16. The VAE and text encoder can also be torch.float32 or torch.float16.」——注意：官方只给 VAE 和文本编码器列了 FP32/FP16 替代项，**transformer 没有** | A（官方文档原文） |
| ComfyUI-LTXVideo | 检查点文件本身的存储 dtype + 加载节点；社区另有 GGUF/FP8 文件可选 | 官方检查点 `ltxv-2b-0.9.8-distilled.safetensors` 为 BF16 存储（文件约 5.2GB，与 2B DiT + 419M VAE 的 BF16 体积吻合，见 1.2） | A/B |

结论：dtype 不是写死在算子里的，改配置/改参数就能换。但「能换」不等于「换了能跑且结果对」——见 1.3、1.4。

### 1.2 显存账：2B 模型各精度下权重本身多少 GB

参数量口径：DiT 约 2.0B（官方型号名 2B）；VAE 约 419M（LTX 论文对比表给出的 VAE 参数量，arXiv:2512.11293 的对比表转引 LTX-Video VAE 为 419M、latent 通道 128、时空下采样 32x32x8）；文本编码器见第 2 节，单列。

| 组件 | 参数量 | BF16/FP16（2 B/参） | FP32（4 B/参） | INT8 存储（1 B/参） | Q4 存储（约 0.55 B/参含缩放） |
| --- | --- | --- | --- | --- | --- |
| DiT transformer | 约 2.0B | 约 4.0GB | 约 8.0GB | 约 2.0GB | 约 1.1–1.3GB |
| VAE（编码+解码） | 约 0.419B | 约 0.84GB | 约 1.68GB | 约 0.42GB | — |
| 合计（不含文本编码器） | 约 2.42B | 约 4.84GB | 约 9.68GB | 约 2.42GB | — |

直接推论：

- **FP32 全驻留 GPU：权重 9.68GB > 6GB，还没算激活、CUDA 上下文（PyTorch 约 0.3–0.6GB）、latent 与碎片——物理上不可能。** C 配置 A 的「FP32 计算」若要成立，只能是「权重以低比特存储、逐块反量化成 FP32 做前向、算完即弃」的流式运行时；现成代码没有这个东西（1.4）。
- BF16/FP16 全驻留：权重约 4.84GB，剩给激活+上下文的余量只有约 1.1GB——官方规格（1216x704、121 帧）下必然爆；降规格后才有讨论空间（第 5 节总账）。

### 1.3 BF16 在 SM52 上的真实行为：不是「报错退出」，是「静默 FP32 模拟 + 部分算子无内核」

这是 A、C 都没说全的一点，也是最容易产生「我明明跑起来了」错觉的一点：

- PyTorch 官方源码 `torch/cuda/__init__.py` 的 `is_bf16_supported()` 实现：返回 `get_device_properties(...).major >= 8 and cuda >= 11`——SM52 上恒为 False。
- PyTorch 核心维护者 ptrblck 在官方论坛的答复（V100 同理）：老硬件上可以创建 BF16 张量、部分 matmul 能「跑通」，但实际计算由 FP32 模拟（emulate via float32 compute），速度与全 FP32 相当或更慢。
- 因此 BF16 路径在 980 Ti 上的实际后果是三重的：(a) 显存按 BF16 省了一半，但 (b) 计算按 FP32 的速度甚至更慢，且模拟过程中产生的 FP32 中间张量会吃掉一部分省下的显存；(c) 没有 SM52 内核的算子会直接抛 RuntimeError，典型的是 SDPA 的 flash / mem-efficient 后端（两者对 BF16 的支持都要求 SM80 级别；FlashAttention 官方实现仅支持 Ampere 起且仅 FP16/BF16 数据类型）——能否回落到 math 后端取决于每条管线是否显式设置了 attention processor，行为不一致、逐个踩。
- 数值面：BF16 模拟本身不改变数值结果（内部 FP32 算），所以 BF16 路径的问题是**速度与零星报错**，不是精度。

### 1.4 改 FP16 / FP32 时具体哪些地方出问题

FP16（把 transformer 也转 FP16 加载）：

- 显存与 BF16 相同（约 4.84GB 权重），且 FP16 在 SM52 上至少有完整的 CUDA 内核覆盖（Maxwell 有 FP16 存储与转换指令，缺的是 FP16 算力加速——吞吐按 FP32 计），SDPA 的 mem-efficient 后端对 FP16 在老架构上有现成实现（需真机验证，列为改造验证项 M5）。这是回退路径选 FP16 的理由。
- 数值风险（真实、需验证）：LTX 官方从未发布 FP16 版权重，diffusers 文档也只把 FP16 列为 VAE/文本编码器的备选。FP16 指数位只有 5 位（最大值 65504），BF16 有 8 位（与 FP32 同范围）——DiT 在去噪中段的激活量级是按 BF16 训练分布长的，转 FP16 后个别层溢出成 inf/NaN 或被截断的风险无法靠读码排除，只能真机跑同 seed 对照 BF16 参考输出的 latent 统计量后才能定性。VAE 解码器是 timestep 条件化的（承担最后一步像素空间去噪），对数值扰动更敏感，建议 VAE 单独保留 FP32（多付 0.84GB，靠顺序 offload 摊开，见第 3、5 节）。
- 静默回退点：diffusers/transformers 加载时若 checkpoint 是 BF16 而 torch_dtype 指定 FP16，会做逐张量 cast（有日志警告，不报错）；T5 的 LayerNorm 等在实现里会上采 FP32 计算再采回，这类混合是正常设计，不算故障。

FP32：

- 如 1.2 所述全驻留不可能。只剩两种形态：(a) 逐模块/逐层 CPU offload 流式（diffusers 的 group offload / enable_model_cpu_offload 支持按模块换入换出，可把 GPU 峰值压到「单个最大模块 + 激活」，但 DiT 本体是一个模块，模块级 offload 对它无效；leaf-level group offload 可以按层流式，代价是每步 8–10 次把约 8GB 权重过一遍 PCIe 3.0 x16（约 12GB/s 实测带宽下光搬运约 0.7 秒/步，且 FP32 单步计算本身在 6.1 TFLOPS 上以分钟计）——能跑通、慢到没有使用价值，且这仍是改造不是现成配置）；(b) Q8/Q4 存储 + 逐块反量化 FP32 的自研运行时（C 配置 A 实际假设的东西，不存在于任何现成 LTX 代码中）。

FP8 路径（官方 fp8 检查点、diffusers 文档的 layerwise casting 示例、ComfyUI 的 fp8-scaled）：**判死**。官方 README 对 FP8 内核的原文是「provide performance boost on supported graphics cards (Ada architecture and later)」；SM52 没有 FP8 任何硬件路径，torchao/diffusers 的 FP8 权重转换在老卡上或报错或模拟，无讨论价值。

### 1.5 本节结论

dtype 可配置（改 YAML / 改 torch_dtype 即可），但官方支持矩阵里 transformer 只有 BF16 一条路；SM52 上 BF16 = FP32 模拟速度 + 注意力后端零星无内核；FP16 是唯一有完整内核覆盖的 16 位选项，代价是未经官方验证的数值风险；FP32 只能靠流式 offload 苟活。**「改个 dtype 就能跑」不成立，「改 FP16 + 一串配套改造后也许能跑」才成立。**

## 2. 问题 2：文本编码器是什么？能否 offload / 预计算替代？

### 2.1 身份与体量（读码确认）

- 官方 repo 路径：`configs/ltxv-2b-0.9.8-distilled.yaml` 第 18 行 `text_encoder_model_name_or_path: "PixArt-alpha/PixArt-XL-2-1024-MS"`——即借用 PixArt 的检查点取其中的 **T5-XXL 编码器**。
- diffusers 路径：LTXPipeline 类签名为 `text_encoder: T5EncoderModel`，官方文档参数说明原文：「T5, specifically the google/t5-v1_1-xxl variant」；tokenizer 为 T5TokenizerFast；`encode_prompt` 的 `max_sequence_length` 默认 128。
- 不是 Gemma。Gemma-3-12B 是下一代 LTX-2（19B）的编码器，与本裁决的 LTX-Video 2B（0.9.x）无关，不要混账。
- 体量：T5-XXL 编码器约 4.7B 参数（Wan 侧同源编码器资料给出的编码器参数量与 BF16 约 9.4GB 互相印证）；实际文件：ComfyUI 生态的 `t5xxl_fp16.safetensors` 约 8.9–9.6GB，FP32 约 18.8GB，GGUF Q4_0 约 2.7GB 级。
- 对显存账的含义：**它比 DiT 本体（BF16 约 4.0GB）还大一倍以上。** 任何「LTX-2B 只需约 4–5GB」的账，只要没写明 T5 的去向，就是漏算了最大的一项——这是 C 的 3.9–5.1GB 与 A 的质疑之间最核心的事实差。

### 2.2 能否不驻留 GPU：能，且有三条现成程度不同的路

| 方案 | 机制 | 现成程度 | 代价 |
| --- | --- | --- | --- |
| CPU offload | diffusers `enable_model_cpu_offload()` / group offloading（官方 diffusers 文档示例就对 text_encoder 用了 block-level group offload）；官方 repo 0.9.1 起 README 明示「Support offloading unused parts to CPU」 | 现成 API，配置级 | 编码阶段 T5 在 CPU 上跑：FP16 文件约 9.4GB 占系统内存，CPU 编码一条提示词为分钟级（一次性成本）；GPU 峰值不受 T5 影响 |
| 预计算 embedding（推荐） | diffusers 的 `LTXPipeline.__call__` 与 `encode_prompt` 签名原生接受 `prompt_embeds` / `negative_prompt_embeds` / `prompt_attention_mask` 参数——在任意机器（或本机 CPU）上离线算好、存成 .pt，推理机上不再加载 T5 本体 | 参数级现成；「推理时不加载 text_encoder」需要一层薄封装（构造 pipeline 时置空/跳过该组件，diffusers 无官方开关）——约 0.5–1 天改造 | 失去自由文本输入的即时性；但 distilled 版 guidance_scale=1（第 4 节），diffusers 在 guidance 不大于 1 时不做 CFG，negative embedding 不需要，只需缓存正向一条，又省一半 |
| GGUF T5（ComfyUI 路） | city96 的 t5-v1_1-xxl-encoder GGUF（Q4_0 等档位），由 ComfyUI-GGUF 的 CLIP 加载器在 CPU/GPU 混合跑 | 社区现成节点 | 与 GGUF DiT 同路，SM52 内核覆盖问题与 5.3 一并验证 |

结论：文本编码器**不是** 980 Ti 路径的否决项——它可以完全不进 GPU 显存。但它必须从账里显式划走（预计算）或显式付账（CPU 内存约 9–19GB + 编码延迟），C 的账两者都没写。

## 3. 问题 3：VAE 的 dtype 与解码显存峰值，分块解码是否现成？

- 身份：diffusers 中为 `AutoencoderKLLTXVideo`，约 419M 参数，latent 128 通道，时空压缩 32x32x8；0.9.1 起为 timestep 条件化解码器（解码时以 decode_timestep 约 0.05、decode_noise_scale 约 0.025 做最后一步像素空间去噪）——这意味着 VAE 解码不只是查表还原，它本身带一次去噪计算，对 dtype 扰动比普通 VAE 更敏感，是第 1.4 节建议 VAE 保 FP32 的原因。
- dtype：跟随管线 dtype；官方文档明确 VAE 可用 FP32 或 FP16 替代 BF16（第 1.1 节引文），这是官方给过的口子。权重账：BF16/FP16 约 0.84GB，FP32 约 1.68GB。
- 解码峰值（不分块）：解码要把全部 latent 帧一次展开为像素帧并做 3D 卷积上采样，是整条管线公认的峰值段。第三方独立实现 candle-video（Rust/Candle，非官方代码）给出的实测表：512x768、97 帧、BF16，不分块约 8–12GB、开 VAE tiling 约 8GB（整管线口径，证据等级 B）；低显存博客口径称标准 VAE Decode 在该规格下尖峰 7GB 以上（等级 C，仅作量级旁证）。无论取哪家，**不分块解码在 6GB 内无望**。
- 分块解码是否现成：**是，三条路都有，不需要自研**：
  - diffusers：`pipe.vae.enable_tiling()` 出现在官方 LTX 文档示例里（LTXConditionPipeline 示例原文即有此行）；另有长视频管线的 `vae_decode_tiled`（含 temporal_tile_size / temporal_overlap 参数）。
  - ComfyUI-LTXVideo：专用节点 `LTXVTiledVAEDecode`（tiled_vae_decode.py），参数 tile_sample_min_height/width、tile_overlap_factor，按空间切块解码再加权拼接；新版核心 ComfyUI 另有空时联合分块的解码节点。
  - 分块后的峰值量级：权重（0.84–1.68GB，取决于 dtype）+ 单块激活（数百 MB 级，随块大小可调）。但注意：分块只压激活，**权重那 0.84–1.68GB 不会消失**——C 的账把 VAE 一项写成 0.4–0.8GB，连 FP16 权重都装不下，这是其总账偏低约 0.5–1GB 的第二处来源（第一处见 1.4/2.1）。
- 时序维度注意：老版 LTXVTiledVAEDecode 只切空间、时间维整段保留；帧数高时仍要靠降帧数或用带 temporal tiling 的实现控峰值。

## 4. 问题 4：distilled 版步数与 guidance；官方最低硬件表述原文

### 4.1 步数与 guidance（官方原文/配置）

0.9.6 distilled（官方 repo 新闻原文）：

- 「Release a new distilled model ltxv-2b-0.9.6-distilled — 15x faster inference than non-distilled model. Does not require classifier-free guidance and spatio-temporal guidance. Supports sampling with 8 (recommended), or less diffusion steps.」
- 「New default resolution and FPS: 1216 x 704 pixels at 30 FPS — Still real time on H100 with the distilled model.」

0.9.8 distilled（官方 config `configs/ltxv-2b-0.9.8-distilled.yaml` 逐行）：

- `pipeline_type: multi-scale`，`downscale_factor: 0.6666666`，且第一遍之后要用 `ltxv-spatial-upscaler-0.9.8.safetensors` 做 latent 空间上采样再跑第二遍——**多一个模型文件要进账**，C 的账里没有这一项。
- first_pass：timesteps 共 7 个（1.0000, 0.9937, 0.9875, 0.9812, 0.9750, 0.9094, 0.7250），`guidance_scale: 1`，`stg_scale: 0`，`rescaling_scale: 1`，`skip_block_list: [42]`。
- second_pass：timesteps 共 3 个（0.9094, 0.7250, 0.4219），`guidance_scale: 1`，`stg_scale: 0`。
- 即 0.9.8 的实际总步数是约 7+3=10 次前向、分布在两个尺度上，不是单遍 8 步；diffusers 的 LTXConditionPipeline 文档示例对 distilled 用同样的显式 timesteps 列表 + `guidance_scale=1.0`。
- diffusers 模型卡 Notes 原文：「For guidance-distilled variants of LTX-Video, set guidance_scale to 1.0.」
- 对显存的利好是真的：guidance=1 意味着无 CFG 双路、无 STG 额外前向，激活峰值与编码器工作量都减半——这是 distilled 版在低显存讨论中唯一实打实的优势，A、C 对此无分歧。

### 4.2 官方「最低硬件」表述原文（结论：不存在）

逐项核过官方 repo README、模型卡与 config 后确认：

- 型号表对 ltxv-2b-0.9.8-distilled 的全部描述只有：「Smaller model, slight quality reduction compared to 13b distilled. Ideal for fast generation with light VRAM usage」——**没有任何 GB 数字**。
- 安装一节只有软件环境：「The codebase was tested with Python 3.10.5, CUDA version 12.2, and supports PyTorch >= 2.1.2.」——没有 GPU 型号或显存下限。
- 一切速度表述都锚在 H100：「Still real time on H100 with the distilled model」「generates HD videos in 10 seconds, with low-res preview after just 3 seconds (on H100)」。
- FP8 内核一节：「provide performance boost on supported graphics cards (Ada architecture and later)」——这是官方文本里唯一一处硬件代际门槛，反过来说明官方心智里的目标硬件从 Ada 起步。

因此：任何「LTX-2B 需要 X GB」的具体数字（包括 C 的 3.9–5.1GB、也包括各种博客的 8GB/12GB）都不是官方数字，前者是外推、后者是社区实测，必须分开标注，不得互相背书。

## 5. 问题 5：SM52 / Maxwell / 1080 Ti 级别社区实测记录

### 5.1 检索结果：零条直接记录

在本轮检索范围内（官方 repo issue/讨论、ComfyUI-LTXVideo、GGUF 工作流发布页、Civitai 工作流、博客与论坛，关键词覆盖 GTX 970/980 Ti/1060/1070/1080 Ti + LTX、Maxwell + LTX、Pascal + LTX）：

- **没有任何一条在 SM52（Maxwell）或 SM61（Pascal，1080 Ti）上跑通 LTX-Video（任意版本、任意精度）的可核查记录。** 证据等级：检索阴性结果——它不能证明「不可能」，但足以推翻「今天可验证」：可验证的前提是有人验证过。
- 最接近的低端记录（按硬件代际由近及远）：
  - RTX 2060 Super 8GB（Turing SM75，有 FP16 Tensor Core）：Civitai 工作流作者自述 768x512、97 帧、30 步约 10 秒/步、单条约 5 分钟，降到约 50 帧、20 步后约 1 分 30 秒；同页建议「6GB 及以下显卡试 FP8 版 DiT + FP8 版 T5」——是建议口吻，无 6GB 实测附后。证据等级 C（作者自述、单一来源、非 distilled 0.9.8 口径）。
  - RTX 4060 8GB（Ada）：官方 README 收录的社区 LTX-VideoQ8 称 720x480、121 帧一分钟内——Ada 有 FP8/INT8 硬件路径，与 SM52 不可比。等级 B/C。
  - 「4/6/8GB 低配跑 LTX」类博客（如低配 LTX-2.5 指南）：给出 GGUF Q4 约 1.7GB + T5 FP8 卸载 + 分块 VAE 约 1.1GB 的组合账，但文中模型代际混乱（把 2.5 的 DiT 与 0.9.x 的 T5 混在一张表里）、无日志无截图证据、无 GPU 型号实测对应。等级 D，不可采信为显存证据，仅证明「社区在往这个方向拼」。
  - candle-video（独立 Rust 实现，非 PyTorch 生态）：512x768、97 帧 BF16 实测约 8–12GB、VAE tiling 后约 8GB，并注「GGUF T5 编码器可再省约 8–12GB」——这是与实现无关性最强的一条显存旁证：换了一套代码、换了一个语言生态，BF16 全管线的地板仍在 8GB 级。等级 B。
- PyTorch 侧的代际事实（非 LTX 专属，但决定回退路径形态）：PyTorch 2.1–2.6 支持表含 SM_50 家族、2.8 起去掉（等级 A，支持表）；BF16 在 CC 小于 8.0 时为 FP32 模拟（等级 A，官方论坛维护者答复 + is_bf16_supported 源码）。

### 5.2 由上述记录能推出的唯一稳健结论

现有全部低显存成功记录都建立在至少一项 SM52 没有的东西上：Turing 起的 FP16 Tensor Core、Ada 起的 FP8、或 8GB 起的显存。把这些记录向 SM52 外推时，每一项都要单独打折或替换实现，没有一条记录可以直接充当 980 Ti 的「已验证」证据。

## 6. 总账：各候选路径在 6GB 内的显存与可行性

口径：GB 为十进制近似；激活估算基于 LTX 的 latent 几何（32x32x8 压缩）。目标规格分两档：官方档（1216x704、121 帧，token 约 13.4k）与降规格档（768x512、49 帧或 512x768、49 帧，token 约 2.5–3.1k；或 480x848 竖屏 49 帧，token 约 2.7k）。

| 路径 | 权重驻留 | T5 去向 | 激活/其他 | 峰值估算 | 裁决 |
| --- | --- | --- | --- | --- | --- |
| P0 官方 repo 原样（BF16，multi-scale，含 upscaler） | DiT+VAE 约 4.84GB + upscaler 另计 | 随管线加载，BF16 约 9.4GB 无处放 | BF16 模拟的 FP32 中间量 + math 注意力物化 | 远超 6GB，且 T5 一项即爆 | 不可跑 |
| P1 diffusers 原样（BF16 全驻留 .to(cuda)） | 约 4.84GB | 同上 | 同上 + CUDA 上下文约 0.5GB | 超 6GB | 不可跑 |
| P2 FP32 全驻留 | 约 9.68GB | — | — | 权重 alone 超限 | 不可跑（物理） |
| P3 FP8 检查点 / layerwise casting 示例 | 约 2.4GB | — | 无 SM52 内核 | — | 不可跑（硬件无路径） |
| P4 FP16 DiT + FP32 VAE + T5 预计算 + 顺序 offload（采样时只驻留 DiT，解码前卸 DiT 换入 VAE）+ 分块解码 + SDPA 非 flash 后端，降规格档 | 采样段 DiT FP16 约 4.0GB；解码段 VAE FP32 约 1.68GB（两段不共存） | 预计算，GPU 占用 0 | 采样段激活约 0.7–1.5GB（token 约 3k、mem-efficient FP16 若可用取下限、math 物化取上限以上）+ 上下文约 0.5GB + 碎片余量 | 采样段约 5.2–6.0GB，临界；解码段约 2.5–3.5GB，宽松 | **需改造后可试，未验证**；官方档规格下采样段激活翻数倍，直接出局 |
| P5 ComfyUI-GGUF：DiT Q4_K/Q5_K + T5 GGUF CPU + LTXVTiledVAEDecode | DiT Q4 约 1.1–1.3GB / Q5 约 1.4GB | GGUF 在 CPU，GPU 约 0 | 激活同 P4 量级但权重省约 2.7GB，余量最足 | 约 3.0–4.5GB（若 ggml CUDA 内核在 SM52 可用） | **需验证的备选**：风险不在显存，在 ComfyUI-GGUF/ggml 的 CUDA 反量化内核对 SM52 的覆盖——若回落 CPU 反量化，速度崩坏；且 2B 小模型上 Q4 的质量损失比大模型更显著 |
| P6 C 的配置 A（Q8 存储 + FP32 计算 + 分块注意力） | 约 2.0GB（存储口径） | CPU/预计算（与本裁决一致） | 其自设激活 1.2–1.8GB 假设了不存在的分块 FP32 注意力与逐块反量化运行时 | 其自报 3.9–5.1GB | 不是现成路径，是自研运行时的设计目标；工作量见第 7 节 M7，不能标「今天可验证」 |

速度量级（外推，非实测，误差带大）：以 RTX 2060 Super 的社区自述为锚（FP16 Tensor 约 52 TFLOPS 级、30 步 97 帧约 5 分钟），980 Ti 有效算力只有 FP32 约 6.1 TFLOPS 且带宽 336GB/s，distilled 约 10 次前向、降规格 token 约减半——P4 路径单条 49 帧短片估在**数分钟到数十分钟**量级。任何「实时/秒级」表述在 SM52 上不成立。

## 7. 改造点清单与工作量估计（P4 为主线）

| 编号 | 改造点 | 内容 | 工作量 | 风险 |
| --- | --- | --- | --- | --- |
| M1 | dtype 迁移 | 以 diffusers 为底：transformer 加载为 FP16、VAE 加载为 FP32（diffusers 支持 per-component 的 torch_dtype 字典/分别加载后组装）；官方 repo 的 YAML 路线只给单一 precision 字段，不用它 | 0.5–1 天 | 低（机械工作） |
| M2 | 数值验证 | 同 seed、同提示词，在任意新卡上出 BF16 参考，再在目标路径出 FP16 结果，比对 latent 均值/方差/NaN 率与成片主观质量；重点测 VAE 解码段（FP32 已隔离）与 DiT 中段激活溢出 | 1–2 天 | **高**：若 FP16 溢出显著，此路降级为「DiT FP32 流式」或作废，这是全项目第一个生死验证点 |
| M3 | 文本编码器剥离 | 离线预计算脚本（CPU FP16 跑 T5-XXL，约 9.4GB 系统内存，单条分钟级）产出 prompt_embeds 缓存；推理封装允许 pipeline 无 text_encoder 运行（利用 __call__ 原生 prompt_embeds 参数 + 组件置空） | 1–2 天 | 低 |
| M4 | 分段驻留 | 用 enable_model_cpu_offload / group offload 实现「采样段只驻留 DiT、解码段只驻留 VAE」；关掉 multi-scale 第二遍与 spatial upscaler（改用 0.9.6 distilled 的单遍 8 步口径或 0.9.8 的 first-pass-only），省去 upscaler 文件与第二遍激活 | 1 天 | 低；代价是画质档位下降（单遍低尺度直出） |
| M5 | 注意力后端落位 | 显式指定 SDPA 处理器并禁用 flash 路径；在 SM52 上实测 mem-efficient 后端对 FP16 是否可用，不可用则接受 math 后端并把 token 上限压到约 3k（即降规格档成为硬约束），或实现按头循环的分块注意力 | 1–3 天 | 中高：决定降规格档的上限与速度 |
| M6 | VAE 分块解码接线 | 启用 vae.enable_tiling() 并扫 tile 参数；帧数 49 起步，必要时换带 temporal tiling 的解码实现 | 0.5 天 | 低 |
| M7 | （备选）GGUF 路验证 | ComfyUI-GGUF 在 SM52 上装配 Q4/Q5 DiT + GGUF T5 + LTXVTiledVAEDecode，验证 ggml CUDA 内核是否真在 GPU 上跑（而非静默 CPU 回落），并做 Q4 质量对照 | 3–7 天 | 高：二元结果，可能整路作废 |
| M8 | 真机冒烟与峰值标定 | 必须有一张实物 980 Ti：nvidia-smi 峰值记录、分阶段计时、OOM 边界扫描（帧数/分辨率阶梯） | 1 天（不含备卡） | 无卡则一切停留在纸面——本裁决即是纸面裁决 |

主线合计（M1+M2+M3+M4+M5+M6+M8）：约 **6–11 个工程日**到「第一条真机成片 + 峰值实测」，其中 M2、M5 是可能推翻整条路的验证点。C 配置 A 假设的自研流式 FP32 运行时（P6）另计，量级为数周，不在本清单内。

## 8. 最终裁决

- 对「LTX-2B distilled 今天就能在 980 Ti 上验证能跑（峰值约 3.9–5.1GB）」：**否决**。该数字漏算 T5（约 9.4GB，必须预计算/卸载且账上未写）、低算 VAE（光 FP32 权重 1.68GB）、默认了不存在的 Q8+FP32 流式运行时与分块 FP32 注意力，且全网无一条 SM52/Pascal 实测记录可作旁证。
- 对「LTX-2B distilled 在 980 Ti 上原理上彻底不可跑」：**同样否决**。dtype 可配置、T5 可剥离成分外预计算、VAE 分块解码现成、guidance=1 无 CFG 的蒸馏特性真实存在——降规格（约 49 帧、768x512 级、单遍采样）后，FP16 路径的显存账在纸面上可以压进 6GB 临界区。
- 落点：**需改造（P4 主线，P5 备选），改造前不可跑，改造后仍须真机冒烟才有资格改称「可跑」。** 在拿到实物卡实测之前，对外口径只能是「纸面可行、临界、未验证」。

## 9. 主要来源

官方（等级 A）：

- LTX-Video 官方 repo README 与型号表、安装环境、FP8 内核说明：https://github.com/Lightricks/LTX-Video
- 0.9.8 distilled 配置（precision、text_encoder、timesteps、guidance、upscaler 逐行）：https://github.com/Lightricks/LTX-Video/blob/main/configs/ltxv-2b-0.9.8-distilled.yaml
- diffusers LTX 文档（LTXPipeline 类签名、encode_prompt 的 prompt_embeds 参数、Notes 的 dtype 与 guidance 原文、group offloading 示例、vae.enable_tiling 示例）：https://huggingface.co/docs/diffusers/api/pipelines/ltx_video
- LTX-Video 模型卡（型号表「Ideal for light VRAM usage」、diffusers 示例）：https://huggingface.co/Lightricks/LTX-Video
- PyTorch 官方论坛：老硬件 BF16 为 FP32 模拟（ptrblck 答复）：https://discuss.pytorch.org/t/bfloat16-on-nvidia-v100-gpu/201629 ；is_bf16_supported 源码（CC 大于等于 8.0 判定）：https://docs.pytorch.org/docs/1.13/_modules/torch/cuda.html

第三方实测/资料（等级 B/C，已在正文逐条标注）：

- candle-video（LTX-2B 0.9.8 distilled 独立实现，BF16 512x768 97 帧约 8–12GB、VAE tiling 约 8GB、GGUF T5 省约 8–12GB）：https://huggingface.co/oxide-lab/LTX-Video-0.9.8-2B-distilled/blob/main/README.md
- ComfyUI-LTXVideo 的 LTXVTiledVAEDecode 节点说明（DeepWiki 转引 repo 源码）：https://deepwiki.com/Lightricks/ComfyUI-LTXVideo/5.4-vae-operations
- Civitai 工作流自述（RTX 2060 Super 8GB 的步时与时长、6GB 以下用 FP8 的建议口吻）：https://civitai.com/models/1019703/emlltxttvitvv10
- T5-XXL 编码器参数量与 BF16 体量（约 4.7B / 约 9.4GB）：https://deepwiki.com/ff2416/WanFM/6.1-t5-text-encoder
- LTX VAE 参数量 419M、latent 128 通道（对比论文转引）：https://arxiv.org/html/2512.11293v1

内部对照文件：

- 情报 A：~/workspace/goals/980-ti/hidden_files/research_A_lowvram_models.md（第 2.2 节）
- 情报 C：~/workspace/goals/980-ti/hidden_files/research_C_compression.md（第 3.2、5.2、8.2 节）
