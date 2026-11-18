# 研究 F：≤6GB / 老卡生成式视频情报刷新（第二轮）

- 日期：2026-10-22（A 号报告同日续轮）
- 范围：只写 A 号报告（research_A_lowvram_models.md）之后的新增证据与被修正的结论，不重复 A 的模型逐个核实。先读 A 再读本文件。
- 标注沿用 A 的规则并加一档：**[实测]** = 有公开的实测数字（注明测在哪张卡上）；**[官方]** = 项目方 README/模型卡/文档明示；**[社区声称]** = 指南/帖子声称，未见对应硬件上的实测数据；**[推算]** = 算术估计，必须真机证实或证伪。

## 0. 本轮一句话结论

A 号报告时的问题是“哪个模型的显存数字够小”；本轮最大的变化是**战场从模型移到了引擎**：出现了两个 A 写作时不存在或未成型的执行路径——**stable-diffusion.cpp（ggml 引擎）已能跑 Wan 视频 GGUF**、**WanGP 把“6GB + GTX 10 系”做成了产品化的默认档位**。但必须同时说清：**整个生态的老卡地板已经收敛在 Pascal（GTX 10 系），Maxwell（980 Ti）至今仍是零实测、零官方支持的一代**——本轮所有“老卡可跑”的新证据，严格说都只到 Pascal 为止，980 Ti 仍需真机第一个吃螃蟹。

## 1. 可立即上测试包验证（新增）

### 1.1 stable-diffusion.cpp + Wan2.1-T2V-1.3B GGUF（off-grid-ai 打包）

A 号报告完全没有这条路：当时 sd.cpp 只有图像。现已确认：

- stable-diffusion.cpp（ggml 系引擎，与 llama.cpp 同源）已支持 Wan2.1/Wan2.2 视频生成（`vid_gen`），后端含 **CUDA、Vulkan、CPU、Metal**，权重格式 GGUF [官方 repo 功能表，经 Toolerific 镜像与多处指南交叉确认]。关键意义：**它不依赖 PyTorch**——A 号报告第 3 条硬约束（torch 2.8 起移除 Maxwell 的版本悬崖）在这条路上不存在；ggml 是源码编译，CUDA 架构号可自选（SM52 可显式指定），Vulkan 后端则连 CUDA 都绕开（980 Ti 有 Vulkan 驱动支持）。
- off-grid-ai 已发布专为 sd.cpp 打包的 Wan2.1-T2V-1.3B GGUF 全套，并附带实测基准文件（BENCHMARKS.md，2026-10-21 刚改名整理过，属活跃维护）[官方模型卡]：
- DiT：Q4_K_S（另有校准版 calibrated Q4，带 imatrix）**0.816 GB**；Q8_0 为 1.519 GB。
- 文本编码器：umt5-xxl-encoder **Q4_K_M GGUF 3.655 GB**（独立 companion 包）。
- VAE：wan_2.1_vae 0.254 GB。全套下载 4.725 GB（Q4 档）。
- **实测数字（注意硬件）**：在 RTX PRO 6000 Blackwell 上、832×480、65 帧、20 步、Euler、CFG 6：Q4 Optimized 档总耗时 104 秒，**全组件上 GPU 时峰值显存 7.078 GiB** [实测，off-grid-ai BENCHMARKS.md]。这组数字对本项目的用法：(a) 证明 sd.cpp 的 Wan 管线是真能出片的成品，不是演示；(b) 7.08 GiB 是“编码器也放 GPU”的峰值——把 3.655 GB 的 T5 编码器放 CPU 后（sd.cpp 支持组件级 offload，发布方亦明示 “GPU offload and CPU decoding can help on memory-limited devices”），GPU 侧只剩 0.816 GB DiT + VAE + 激活，**进 6GB 在算术上成立 [推算]**；(c) 速度不可直接搬：Blackwell 与 980 Ti 的 FP32 算力差约一个数量级以上，同负载在 980 Ti 上粗估为数十分钟级一条 [推算]。这条路测的是“能不能跑通”，不是“快不快”。
- 风险点（写进测试规程）：基准命令用了 `--fa`（ggml flash attention）；该开关在 Vulkan/Maxwell 后端上是否可用未验证，测试时应准备关掉 FA 的回退命令。sd.cpp 无 UniPC 采样器（只有 Euler），与官方 Wan 的默认采样行为有差异，画质对比时注意变量。
- 来源：
- 模型包与文件尺寸：https://huggingface.co/off-grid-ai/Wan2.1-T2V-1.3B-GGUF
- 实测基准（Blackwell，含峰值显存与分段耗时）：https://huggingface.co/off-grid-ai/Wan2.1-T2V-1.3B-GGUF/blob/main/BENCHMARKS.md
- sd.cpp 功能面（Wan2.1/2.2、Vulkan、GGUF）：http://toolerific.ai/ai-tools/opensource/leejet-stable-diffusion.cpp
- **建议动作：新增测试项 E6**——在 980 Ti 上装 sd.cpp（优先 Vulkan 构建，失败退 CUDA 源码构建、架构号钉 52），跑 Q4 校准包、T5 强制 CPU、832×480、33 帧、20 步，记录：是否 OOM、峰值显存、总耗时、FA 开关可用性。这是目前唯一一条“每个组件体积都已知、且不撞任何一条 A 号硬约束”的完整现代 DiT 路径。

### 1.2 WanGP（deepbeepmeep，原 Wan2GP）：6GB 档位被产品化，但地板是 Pascal

- WanGP（由 Wan2GP 更名）现定位为“给 GPU Poor 的一站式应用”，README 明示：**部分模型最低 6 GB 显存可跑；支持 RTX 10XX、20XX 及更新显卡**（原文 “RTX 10XX”，指 GTX 10 系）；支持 int8 / fp8 / gguf / NV FP4 / Nunchaku 多种量化检查点；按硬件架构自动选装匹配的 PyTorch 与注意力库；底层是同作者的 mmgp 显存管理库（分阶段卸载、profile 档位）[官方 README，经 theresanaiforthat 镜像]。其安装文档按架构分册：**“GTX 10XX through RTX 50XX”** [官方安装文档 DeepWiki 镜像]。
- 对 A 号报告的修正：A 里“Wan 2.1 1.3B 社区只有零散说法”已过时——低显存 Wan 现在有维护方把档位、卸载、量化打包成默认配置，Pascal 卡上是“装完就跑”级别，不再是手工拼凑。
- **边界（必须写进项目档案）**：本轮专门检索了 WanGP 与 GTX 9 系 / Maxwell 的关系——**零结果**：文档、安装分册、检索到的讨论里都没有 Maxwell。WanGP 的“老卡支持”止于 Pascal 一代。980 Ti 在 WanGP 里属于“拿 Pascal 档位去撞一代更老的架构”，预期第一个硬墙是注意力库绑定或 torch 架构检查，这正是测试要测的东西。
- 来源：
- README（6GB、GTX 10XX、量化格式）：https://theresanaiforthat.com/company/deepbeepmeep/repository/Wan2GP/
- 安装文档（架构分册 GTX 10XX 起）：https://deepwiki.com/deepbeepmeep/Wan2GP/2-installation-and-setup
- mmgp 档位表（最低 VerylowRAM_LowVRAM 仍写 10GB+，注意与 WanGP 应用层“6GB”是两套口径，不要混引）：https://deepwiki.com/deepbeepmeep/mmgp/2-installation-and-setup
- **建议动作：新增测试项 E7**——在 980 Ti 上按 WanGP 的 GTX 10XX 档位安装并启动 Wan 2.1 1.3B（GGUF 或 int8 检查点），目标是拿到**第一个硬失败点**的完整日志。跑通是惊喜，跑不通也把墙的位置钉死（注意力绑定 / torch 架构 / 量化内核，三选一），后续所有路线判断都受益。

### 1.3 Wan 2.2 TI2V-5B GGUF：从 A 的“判死（直跑）”修正为“GGUF 路线可测（限 Pascal/Turing 证据）”

- A 号报告判 TI2V-5B 直跑死刑（官方 24GB、社区约 8GB）。新证据：社区 GGUF 指南（wan27.org，2026 版）给出了一张按卡选档的配置表，其中 **6 GB 档（RTX 2060 / GTX 1660）：Q4_K_M + LightX2V 4 步蒸馏、文本编码器用 Q3_K_M GGUF、480p、41 帧、必须开 offload、只适合短片** [社区声称]；同指南另一条经验法则：**峰值预算低于 10 GB 时，5B FP16（其口径峰值约 8 GB）比 14B 的 Q3/Q2 画质更好** [社区声称]。TI2V-5B 的 GGUF 文件由 QuantStack/city96 维护，Q4_K_M 按 5B 参数量 × 约 4.8 bpw 推算约 3.0 GB、Q3_K_M 约 2.4 GB、Q2_K 约 1.6 GB [推算，未逐个核对仓库文件表]。
- 证据等级警告：该指南的量化质量百分比（如 “Q4 约 95%”）是无出处的编辑估计，**不可引用**；其 14B 的实测表是在 RTX 4090 上测的（720p/81f 峰值 18 GB），6 GB 档那一行没有给出对应硬件的实测耗时。本节可采信的只有“配置组合存在且被指南作者列为可用”，速度与 Maxwell 兼容性均为未知。
- 对 980 Ti 的额外折扣：指南给低显存档开的关键设置之一是 `fp8_matmul: True`——FP8 在 Maxwell 上不存在，此设置不可照搬（见 3.3）。ComfyUI-GGUF 的反量化内核在 SM52 上同样零验证。
- 来源：https://wan27.org/blog/wan-2-2-gguf-guide （同页含 14B GGUF 各档在 4090 上的实测表与编码器 GGUF 尺寸表：UMT5-XXL Q4_K_M 文件 3.5 GB / 驻留约 1.5 GB、Q3_K_M 2.8 GB / 约 1.0 GB——编码器量化这组数字与 1.1 节 off-grid-ai 的 3.655 GB 互相印证，可采信）
- **建议动作**：不单独开测试项；并入 E6/E7 的后续队列——E6（sd.cpp）若跑通，第二个测的就是把 TI2V-5B GGUF 喂给同一引擎（sd.cpp 已支持 Wan2.2），而不是先去啃 ComfyUI-GGUF 的 SM52 内核问题。

## 2. 值得跟踪（有价值，但现在别投入真机时间）

### 2.1 FastWan 蒸馏家族的新形态：FastWan-QAD-1.3B（2026）——步数红利与内核判死并存

- FastVideo 团队 2026 年新作 FastWan-QAD-1.3B：量化感知蒸馏（QAD），**3 步推理**、无 CFG、TAEHV 快速解码；FP8 变体在 RTX 4090 上 5 秒 480p 约 3.4 秒 [厂商声称，DeepInfra 模型页]；另有 NVFP4 变体面向 RTX 5090。其 2025 年前作 FastWan2.1-1.3B（BF16 + 稀疏蒸馏）官方口径是 4090 上 5 秒 480p 共 21 秒（去噪 2.8 秒）[官方博客]。
- 与本项目的关系要拆开看：**内核层判死**——QAD 依赖 FP8/NVFP4 线性层与 SageAttention2++，全是 Volta 之后的技术（见 3.2）；原版 FastWan 的 VSA 稀疏注意力内核同样是现代栈产物。**权重层值得跟踪**——“1.3B 蒸馏到 3 步”是目前公开产物里步数压得最狠的 Wan 1.3B：慢卡的第一成本就是步数 × 每步时长，20 步 → 3 步是 6 倍以上的杠杆。待核实的问题只有一个：FastWan 的蒸馏权重能否脱离其专用内核、用普通 SDPA 路径（diffusers/ComfyUI 原生 Wan 节点）加载并保持 3 步质量。若能，它可以直接嫁接到 1.1 的 sd.cpp 路线或 A 的 CogVideoX 对照组上。下轮情报专门核这一条。
- 来源：
- QAD 模型页（FP8/3 步/4090 3.4 秒）：http://deepinfra.com/FastVideo/FastWan-QAD-FP8-1.3B
- FastWan 官方发布（4090 21 秒、Apache-2.0 全开源）：https://haoailab.com/blogs/fastvideo_post_training/
- VSA 论文（ NeurIPS 2025，稀疏蒸馏 50.9× 的口径出处）：https://papers.neurips.cc/paper_files/paper/2025/file/dfc310e81992d2e4cedc09ac47eff13e-Paper-Conference.pdf

### 2.2 LightX2V 生态的打包化（降低一切 Wan 测试的装配成本）

- A 号报告时 LightX2V 还是“LoRA + 自己拼工作流”。本轮变化：出现**预打包 GGUF+LightX2V 4 步**的发布（如 Abiray/Wan2.2-LightX2V-4STEP-GGUF，Q4_K_M/Q8_0 两档）、**编码器专用 GGUF 包**（wangkanai/wan22-qx-encoders-gguf，Q3–Q8），以及指南称 Ollama、ktransformers 也已加入 Wan 2.2 支持 [社区汇总，wan27.org 指南]。ktransformers 是 CPU/GPU 混合推理引擎，若其 Wan 支持成熟，它是又一条绕开纯 GPU 显存账的引擎路线（本轮未深挖，列名跟踪）。
- Wan2.2-Lightning LoRA 本身的口径更新：官方 ComfyUI 模板已内置 turbo 开关；RunPod 指南给出 4090D 640×640 实测：20 步约 513 秒 → 4 步 Lightning 约 71 秒 [实测，24GB 卡]。步数蒸馏的收益在实测里是 5–7 倍，这组数字可作为本项目估算“蒸馏后慢卡耗时”的锚点之一。
- 来源：https://wan27.org/blog/wan-2-2-gguf-guide ；https://www.runpod.io/articles/guides/comfyui-wan-2-2

### 2.3 EbSynth 2 发布（2025-10）：传播引擎有了官方续作，但本地版仍是旧二进制

- Secret Weapons 于 2025 年 10 月发布 EbSynth 2：核心纹理合成算法**约 10 倍加速、可实时预览**（厂商声称）；形态改为**浏览器端服务**（自托管版只向工作室提供）；免费账号可导出 720p MP4，Pro 20 美元/月升 4K 并含每月 100 张 SDXL 生成图（其唯一的生成式 AI 功能）[行业报道 cgchannel]。厂商称上传的帧在合成后立即删除、不用于训练。
- 对 B 号管线（SD1.5 关键帧 + EbSynth 传播 + RIFE）的含义：传播环节的“官方维护版本”现在是云端服务——若项目接受“帧上传第三方服务器”，EbSynth 2 免费档可直接替换本地传播步且速度大涨；若坚持全本地，老版桌面 EbSynth（2020）仍是唯一选择，其 CPU 耗时口径本轮**仍未找到新的实测报告**（教程类内容只给“数周手工 → 数小时”的定性说法 [社区]）。B 号报告的 E4（EbSynth 纯 CPU 实测）继续有效、继续欠账。
- 来源：https://www.cgchannel.com/2025/10/ebsynth-2-can-turn-video-into-animation-without-using-ai/ ；定性耗时说法：https://ai-review.com/video-generator/ebsynth/

### 2.4 GTX 1060 6GB 实操指南对软件栈结论的旁证（仅图像，无视频行）

- Hugging Face 论坛有一篇 GTX 1060 6GB 实操长帖（作者逐个实测）：Pascal 上必须用 **ComfyUI cu126 便携包**（cu121 太旧、CUDA 13 包无 Pascal 支持）；其表格里 SD1.5 约 4 GB / 约 30 秒、SDXL 峰值约 5.7 GB 可跑 [实测，GTX 1060 6GB，Windows]。两个使用注意：(a) 该帖结果重度依赖 **Windows 的共享显存溢出**机制（12 GB 模型靠系统内存分阶段驻留），作者明示 Linux/macOS 不保证同样行为——把这类“6GB 跑大模型”的帖子搬到 Linux/Maxwell 时要再打折；(b) 表格只有图像模型，**没有视频行**，只能旁证软件栈，不能旁证视频可行性。
- 来源：https://discuss.huggingface.co/t/running-modern-ai-image-models-on-a-gtx-1060-6gb-a-practical-guide/176079

## 3. 判死或证伪（本轮新增证据）

### 3.1 FramePack 在 Pascal 上：从“未测试”升级为“生态口径明确不推荐，且仍无一例成功实测”

- A 号报告的判死依据是官方硬件门槛。本轮补充：FramePack 的主要维护分支 **FramePack-eichi** 的安装文档把兼容矩阵写死为：RTX 30/40 系官方支持、**GTX 10XX/20XX 为 “❌ Unofficial/Untested（May work but not recommended）”**，且该文档的 VRAM 地板是 8 GB [社区文档，DeepWiki 镜像]。本轮多路检索（GitHub issue、论坛、视频站）**依然没有找到任何一例 Pascal 成功跑通 FramePack 的一手记录，Maxwell 更是零**。
- 结论：A 的判死维持，且举证状态从“官方没测”加强为“维护分支明确不推荐 + 社区零成功样本”。除非出现带硬件信息的成功实测帖，不再投入检索。
- 来源：https://deepwiki.com/git-ai-code/FramePack-eichi/2-installation-and-setup

### 3.2 FastWan-QAD 的 FP8/NVFP4 + SageAttention2++ 组合：对 Maxwell 判死（防标题党误报）

- “1.3B、3 步、3.4 秒出 5 秒视频”只发生在 RTX 4090 + FP8 量化线性层 + SageAttention2++ 上 [厂商声称，DeepInfra]；NVFP4 变体只面向 Blackwell。FP8、NVFP4、SageAttention 全部是 Volta/Ampere 之后的技术栈，与 A 号报告判死清单第 1、9 条同族。**在本卡上判死的是这套权重+内核组合，不是 FastWan 的蒸馏权重本身**（权重层见 2.1 跟踪项）。后续任何人拿 QAD 数字来主张“1.3B 已经能在老卡飞起来”，按此条驳回。
- 来源：http://deepinfra.com/FastVideo/FastWan-QAD-FP8-1.3B

### 3.3 低显存指南的两个不可照搬点（证伪预备）

- **fp8_matmul 开关**：wan27.org 指南建议 GGUF ≤Q5 时开 `fp8_matmul: True` 省显存——这是 Ampere+ 的能力，Maxwell/Turing 上该设置无对应硬件路径，照搬轻则无效、重则报错。本项目任何 ComfyUI-GGUF 测试规程里此开关应明确关闭并记录原因。（来源同 1.3。）
- **“质量百分比”数字**：同指南给各量化档打的 “约 95%/92%” 等质量分无测试方法与出处，属编辑估计。本项目档案不得引用；量化画质代价目前唯一可引的硬数据是 1.1 节 off-grid-ai 的同种子对照图（FP16/Q8/Q4/Q4 Optimized 四格对比，Blackwell 上出图）。

### 3.4 “WanGP 支持老卡”不覆盖 Maxwell（口径纠正）

- 见 1.2：WanGP 的支持下限是 GTX 10 系（Pascal）。任何把 WanGP 的 6 GB 宣传直接读成“980 Ti 有救”的说法，本轮证据不支持。980 Ti 在 WanGP 路线上的状态是**未验证**，由 E7 测试项负责给出第一个数据点；在此之前不得写成“可跑”。

### 3.5 SnapGen-V 后续：无新进展，观察名单降级

- 本轮检索未发现 SnapGen-V 的后续模型、官方权重或代码发布的新消息，可检索到的仍是 2024-12 的原论文（0.6B、4 步、VBench 81.14、iPhone 16 Pro Max 上 5 秒出 5 秒）[论文]。A/C 号报告把它当“0.6B 窄域学生可行性”的论文证据引用——该用法不变；但“等它放权重就能用”的期待本轮无任何新支撑，降级为低频观察。
- 来源：https://arxiv.org/pdf/2412.10494

## 4. 与 A 号报告结论的对账表

| A 号结论 | F 号修正 |
|---|---|
| Wan 2.1 1.3B GGUF “社区有 8GB 级说法，6GB/Maxwell 未核实” | GGUF 生态已成型且尺寸全公开（DiT Q4 0.816 GB + T5 Q4 3.655 GB + VAE 0.254 GB）；新增 sd.cpp 第二引擎与成套命令；问题从“格式存不存在”变为“哪个引擎能在 SM52 上跑” → 新增 E6 |
| Wan 2.2 TI2V-5B 直跑判死 | 维持直跑判死；GGUF Q4 + 编码器 GGUF + LightX2V 的组合在 6 GB Turing/Pascal 上有指南级配置表，升级为“可测候选”（Maxwell 仍零证据）→ 并入 E6 后续队列 |
| CogVideoX-2B 第一候选 | 不变。本轮未检索到 CogVideoX 在 Pascal/Maxwell 上的新一手实测，其排名依据（FP16 原生、官方点名 1080 Ti）仍是存量证据 |
| AnimateDiff 并列第一候选 | 不变。1060 6GB 实操帖对 SD1.5 图像侧的实测（约 4 GB）间接加固其软件栈判断，但视频侧实测仍缺 |
| FramePack 权重判死、架构可借 | 判死加强（见 3.1）；“可借的架构思想”不变 |
| LTX-2B distilled 排 Wan 之后 | 不变；本轮无 LTX 在 6 GB 级硬件上的新实测 |
| 实验队列 E1–E4 | 新增 **E6（sd.cpp + Wan 1.3B GGUF）** 与 **E7（WanGP Pascal 档位撞 Maxwell）**，优先级建议：E6 > E7 > 原队列（E6 是唯一全组件尺寸已知且不撞版本悬崖的现代 DiT 路径） |

## 5. 本轮主要来源清单

- off-grid-ai Wan2.1-T2V-1.3B-GGUF 模型卡：https://huggingface.co/off-grid-ai/Wan2.1-T2V-1.3B-GGUF
- 同上 BENCHMARKS（Blackwell 实测：峰值显存/耗时/四档对比）：https://huggingface.co/off-grid-ai/Wan2.1-T2V-1.3B-GGUF/blob/main/BENCHMARKS.md
- stable-diffusion.cpp 功能表（Wan 视频、Vulkan、GGUF）：http://toolerific.ai/ai-tools/opensource/leejet-stable-diffusion.cpp
- WanGP README 镜像（6 GB、GTX 10XX、量化格式）：https://theresanaiforthat.com/company/deepbeepmeep/repository/Wan2GP/
- WanGP 安装文档（架构分册）：https://deepwiki.com/deepbeepmeep/Wan2GP/2-installation-and-setup
- mmgp 档位表：https://deepwiki.com/deepbeepmeep/mmgp/2-installation-and-setup
- Wan 2.2 GGUF 指南（6 GB 配置行、编码器 GGUF 尺寸、4090 实测表；质量百分比不可引）：https://wan27.org/blog/wan-2-2-gguf-guide
- RunPod Wan 2.2 指南（4090D Lightning 71 秒 vs 20 步 513 秒实测）：https://www.runpod.io/articles/guides/comfyui-wan-2-2
- FastWan-QAD-FP8-1.3B 模型页：http://deepinfra.com/FastVideo/FastWan-QAD-FP8-1.3B
- FastWan 官方发布博客：https://haoailab.com/blogs/fastvideo_post_training/
- VSA / 稀疏蒸馏论文（NeurIPS 2025）：https://papers.neurips.cc/paper_files/paper/2025/file/dfc310e81992d2e4cedc09ac47eff13e-Paper-Conference.pdf
- FramePack-eichi 兼容矩阵（GTX 10XX/20XX 不推荐）：https://deepwiki.com/git-ai-code/FramePack-eichi/2-installation-and-setup
- EbSynth 2 发布报道（cgchannel，2025-10）：https://www.cgchannel.com/2025/10/ebsynth-2-can-turn-video-into-animation-without-using-ai/
- GTX 1060 6GB 实操指南（HF 论坛，cu126 便携包、SD1.5/SDXL 实测）：https://discuss.huggingface.co/t/running-modern-ai-image-models-on-a-gtx-1060-6gb-a-practical-guide/176079
- SnapGen-V 论文（状态复核用）：https://arxiv.org/pdf/2412.10494

---
注：本文件是 A 号报告的增量刷新。凡标 [推算] 与 [社区声称] 的数字，在 E6/E7 真机数据回来之前不得升级为结论；本轮最重要的纪律提醒是——**所有“6 GB 可跑”的新证据都止步于 Pascal/Turing，Maxwell 仍是无人区，980 Ti 的第一个数据点只能由本项目自己产生。**
