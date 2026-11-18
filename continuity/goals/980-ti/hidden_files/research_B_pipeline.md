# 研究 B：非端到端扩散的「普通软件」组件管线路线

- 日期：2026-10-22
- 目标硬件：GTX 980 Ti（6GB GDDR5、Maxwell GM200、SM52、无 Tensor Core、无 FP16 加速、CUDA 上限 12.x、PyTorch 需用支持 SM52 的旧版本栈）
- 研究问题：不做一个巨型视频大模型，而是把视频生成拆成小组件流水线（关键帧生成 → 运动驱动/传播 → 插帧 → 修复），每个组件单独都轻量。这条管线在 980 Ti 上是否可行？针对固定角色卡通短镜头（墨团团式水墨卡通：液态墨汁小狗、固定场景、短镜头）的质量上限在哪？瓶颈在哪一步？
- 证据等级说明：
  - A 级：官方 repo / 官方文档 / 官方权重页明示
  - B 级：第三方在同档硬件（6GB 卡 / 980 Ti 本人 / GTX 1060 6GB 等）的实测
  - C 级：由权重体积、参数量、架构推算，文档中明确标注「推算，未实测」
- 方法纪律：关键数字尽量给 A/B 级来源；查不到实测的写「未查得」，不编造。

---

## 0. 结论先行

**这条路线成立，而且是目前四条路线里唯一每个组件都有老卡实证的路线。** 原因很朴素：这些组件大多诞生于 2020-2023 年，那个年代的设计目标硬件就是 6-8GB 消费卡甚至 CPU；它们不是被「压缩」到 980 Ti 上的，而是本来就长在这一档。

最可行组合（详见第 7 节）：

> SD1.5（LCM-LoRA 4 步或 Hyper-SD）+ T2I-Adapter（姿态/深度）生成少量定妆关键帧
> → 驱动视频（真人表演 / 手偶 / 3D 粗演 / 骨骼动画渲染）提供运动
> → EbSynth 以关键帧为样式源做 PatchMatch 传播（纯 CPU、零显存）
> → RIFE ncnn-vulkan 版（走 Vulkan 绕开 CUDA，最低只需 Kepler 级 Vulkan 卡）把 12fps 补到 24fps
> → 修复段：SD1.5 低强度 img2img / inpaint 只修遮挡崩坏帧 + 时域去闪烁

质量上限一句话：**「定妆照级别的角色一致性 + 驱动视频级别的运动质量」，在 480p、5 秒内、中小幅度运动的镜头上可以做到成片可用；它不会「发明」运动，运动有多好完全取决于驱动源有多好。**

第一瓶颈：**运动的产生与遮挡/形态突变处的「无中生有」**——所有传播/warp 类组件都只能搬运已有像素，角色转身露出没画过的面、液态变形时拓扑突变，都会崩，必须靠增加关键帧密度 + 修复段兜底（详见第 8 节）。

---

## 1. 关键帧生成：SD1.5 / SDXL / TAESD

### 1.1 SD1.5 —— 本管线的关键帧主力（可行，A/B 级证据齐全）

| 项 | 数据 | 证据 |
|---|---|---|
| 参数量 / 权重 | UNet 约 0.86B；fp16 safetensors 约 2GB（pruned-emaonly）；fp32 约 4-5GB | A：HF runwayml/stable-diffusion-v1-5 权重文件 |
| 基础显存（512×512） | 约 3.8-4.5GB（fp16、batch=1、含 VAE 解码峰值）；ComfyUI `--lowvram` 分块后峰值可压到约 2.5-3GB | A/B：ComfyUI、A1111 官方 wiki |
| 980 Ti 本人实测 | 有。A1111 早期社区实测：512×512、20 步、Euler a，约 1.2-1.6 it/s，即单图约 13-17 秒（fp32 路径） | B：A1111 GitHub Discussions 硬件实测帖 |
| 同档旁证（GTX 1060 6GB） | 512×512、20 步约 25-40 秒（约 0.5-0.8 it/s） | B：社区基准汇总 |
| 同档旁证（GTX 1660 Super 6GB，含 ControlNet） | model offload 下 25 步 + 1 个 ControlNet 约 61.5 秒/张，峰值 5.3GB；Hyper-SD 4 步约 11.1 秒；1 步约 4.9 秒 | B：tech-en.andhandworks.com 2026 实测系列 |
| 许可证 | CreativeML Open RAIL-M（可用、限制有害用途；与纯 Apache/MIT 不同，商用分发需注意条款） | A：HF 模型卡 |

980 Ti 特有坑（必须写进后续工程约束）：

1. **FP16 是陷阱**：Maxwell 的 FP16 吞吐只有 FP32 的 1/64，无加速、部分算子还会溢出出黑图。A1111 在 9 系卡上必须加 `--no-half` 走 FP32（或 `--no-half-vae`），代价是显存涨到约 5-5.5GB、速度再慢一截。**「SD1.5 在 6GB 上约 4GB」这个流行数字是 Turing 以后 fp16 卡的数字，980 Ti 要按 FP32 的 5-5.5GB 预算。**
2. **xformers 在 SM52 上不可用**（官方要求 SM70+ 的预编译轮子），只能用 PyTorch 原生 SDPA / split attention。好处是 SDPA 本身也省显存，不必绝望。
3. **解法是步数蒸馏，不是换大模型**：LCM-LoRA（A 级：latent-consistency/lcm-lora-sdv1-5，MIT）把步数从 20-50 步压到 2-4 步，官方示例即 4 步出图；Hyper-SD15 同理（1 步约 5 秒/张，见上表 1660S 实测）。关键帧阶段一张图从「半分钟级」降到「5-15 秒级」，整条管线的耗时结构就变了。
4. ONNX / DirectML / OpenVINO 路线对 Maxwell 是死路或坑路：onnxruntime-gpu 的 CUDA EP 虽可跑但 VAE 易爆显存且无低步数生态；stable-diffusion.cpp（Vulkan/GGUF）可作为备选运行时，其 Vulkan 后端不挑 CUDA 架构，但 ControlNet/LoRA 生态弱于 ComfyUI 主线。

### 1.2 SDXL —— 出局（作为 980 Ti 本地关键帧引擎）

| 项 | 数据 | 证据 |
|---|---|---|
| 参数量 / 权重 | UNet 约 2.6B；fp16 约 6.9GB，单权重文件已超过 6GB 显存 | A：HF stabilityai/stable-diffusion-xl-base-1.0 |
| 实际显存 | 1024×1024 正常推理约 8-10GB；`--lowvram` + CPU offload 可勉强塞进 6GB，靠 PCIe 反复搬运 | A/B：A1111 wiki、ComfyUI 文档 |
| 速度代价 | 同档 6GB 卡 offload 状态下单图 1024 约 2-5 分钟（旁证：Steam Deck 级硬件 SDXL 约 120-360 秒/张） | B |
| 许可证 | CreativeML Open RAIL++-M | A |

判定：SDXL 在 980 Ti 上是「能启动、不能生产」。关键帧质量确实比 SD1.5 好，但本管线的关键帧有 LoRA 锁角色 + 驱动/传播兜底，一致性不靠底模尺寸堆。**SDXL 只保留一个用途：偶尔在云端/别的机器上出定妆图，本地管线不依赖它。**

### 1.3 TAESD —— 免费的解码加速件（必装，但别指望它修画质）

| 项 | 数据 | 证据 |
|---|---|---|
| 本体 | 约 1.2M 参数的微型 VAE（编+解码器权重合计仅数 MB 量级），官方定位就是「live, cheap previews」 | A：github.com/madebyollin/taesd |
| 收益 | 解码比原 VAE 快约两个数量级（官方/集成方口径约 40-100×）、显存约 500× 分之一量级（约 5MB vs 原 VAE 约 330MB fp32 权重口径） | A/B：taesd repo、DeepWiki 整理 |
| 速度实感 | FastSDCPU 集成后报告约 1.4× 整体提速（解码不再是瓶颈后，收益被 UNet 摊薄） | B：github.com/rupeshs/fastsdcpu |
| 画质短板 | 官方明说与原 VAE 输出只是「roughly match」：细节发糊、小字/细线丢失、色偏。对水墨风是双刃：墨迹边缘的糊化有时反而像晕染，但铃铛纹理、眼睛高光这类身份细节会丢——**成片关键帧的最终解码建议仍用原 VAE，TAESD 只做预览/选图/中间帧草稿** | A |
| 许可证 | MIT（代码与权重） | A |

### 1.4 控制条件：ControlNet vs T2I-Adapter（老卡选后者）

| 组件 | 显存增量 | 速度代价 | 证据 / 许可证 |
|---|---|---|---|
| ControlNet 1.1（SD1.5 版，单个） | 权重约 1.4GB（fp16）/ 约 2.9GB（fp32）；运行时峰值 +1-2GB。SD1.5+1 CN 在 6GB 1660S 实测峰值 5.1-5.3GB（model offload）；2 个 CN 即溢出到 6.7GB 并大幅变慢 | 每步多跑一个 UNet 编码器拷贝，约 +30-50%/步 | A：lllyasviel/ControlNet-v1-1 权重与 README（8GB 卡开 save_memory）；B：1660S 实测系列。许可证 Apache-2.0 |
| T2I-Adapter | 每个约 158MB（官方口径约为 ControlNet 的 1/5 到更小），运行时增量约 0.15GB 量级 | 条件只算一次、不逐步重复，速度代价远小于 ControlNet | A：TencentARC/T2I-Adapter repo。许可证 Apache-2.0 |
| 标注器（OpenPose/DWPose、MiDaS 深度等） | 本身小模型，CPU 可跑；DWPose 约数百 MB 级 | 一次性预处理，不进采样循环 | A：ControlNet annotator / openpose repo |

判定：**980 Ti 上姿态/构图控制首选 T2I-Adapter（pose/depth/canny/sketch），ControlNet 只在单个、且配合 offload 时可用**；多 ControlNet 叠加在 6GB 上直接出局。另一个省钱技巧：控制图（姿态骨架、深度）可以在 CPU 上由驱动视频逐帧抽取，GPU 只管生成。

### 1.5 本组小结

关键帧段定版：**SD1.5 + 角色 LoRA（团团身份锁定）+ LCM-LoRA 4 步（或 Hyper-SD）+ TAESD 预览 + 原 VAE 定稿解码 + T2I-Adapter 姿态控制**。预算：峰值显存约 5-5.5GB（FP32 路径），单张关键帧约 5-20 秒（步数蒸馏后），一个 5 秒镜头需要的 4-8 张关键帧在一两分钟量级——这是整条管线里最不愁的一段。


---

## 2. 帧间插值：RIFE / FILM / GMFSS

先说清定位差异：插值组件**不产生新运动信息**，它把已有的 8-12fps 运动补密到 24fps。它的价值是让管线可以只生产一半帧数，省一半的传播/修复成本。

### 2.1 RIFE —— 唯一有 980 Ti 本人实证的插帧器（首选）

| 项 | 数据 | 证据 |
|---|---|---|
| 本体 | ECCV 2022，IFNet 直接估计中间光流；PyTorch 版权重约 20-50MB 量级（v4.6 约 21MB） | A：github.com/hzwer/ECCV2022-RIFE |
| PyTorch 版速度（官方表，V100） | 720p 约 61fps、1080p 约 29fps（rife4090 变体口径不同）；2080Ti 上 720p 约 42fps | A：repo README 性能表 |
| 显存 | 官方未公布；社区/发行说明口径：720p 约 1-1.5GB、1080p 约 2-2.5GB（fp32 推算区间，未逐项实测核验） | B/C |
| **ncnn-vulkan 版（关键）** | nihui/rife-ncnn-vulkan：走 Vulkan、完全绕开 CUDA 和 Tensor Core；`-g -1` 可纯 CPU 跑。FlowFrames 官方系统要求明示 NCNN 路线最低只需「支持 Vulkan 的 GPU（Kepler 或更新）」 | A：github.com/nihui/rife-ncnn-vulkan、github.com/n00mkrad/flowframes |
| **980 Ti 本人实证** | SVP 官方兼容列表把 GTX 980 Ti 列入 RIFE 可用 GPU，条件为 471.11+ 驱动；同期 9 系卡（GTX 970）用户报告 1080p24→48 无法实时、降到 720p 处理约 15fps——即 980 Ti 在 720p 大致处于「准实时到慢于实时之间」，480p 只会更快 | B：svp-team.com 官方兼容页与论坛实测 |
| 专用变体 | rife-anime（FlowFrames 内置，针对动画线条/平涂）、Practical-RIFE 4.26（腾讯，权重约 400MB 级，补了 4K 与推理加速） | A/B |
| 画质短板 | 训练数据以真人视频为主：遮挡边缘重影、快速运动拖影；平涂卡通的大色块无纹理区光流难锁定，线条易抖。缓解法：管线侧把基础帧率做到 12fps 只做 2× 插值（不要 4× 硬拉），并优先 rife-anime 变体 | A/B |
| 许可证 | 官方 repo 为 MIT；注意部分国内打包版（如 RIFE-App）另行声明仅非商业，打包选型时避开 | A |

### 2.2 FILM —— 大运动质量标杆，但工程上出局

| 项 | 数据 | 证据 |
|---|---|---|
| 本体 | Google Research，ECCV 2022，专为大运动设计（尺度无关特征金字塔 + Gram loss 补遮挡） | A：github.com/google-research/frame-interpolation |
| 实现 | 只有 TensorFlow 2 版官方实现；社区有 PyTorch 移植（FILM_pytorch，非官方） | A/B |
| 显存/速度 | 官方未公布显存与速度表（未查得 A 级数据）；TF 版依赖重、部署成本高 | — |
| 画质 | 大位移、宽遮挡场景质量优于同期 RIFE，这正是它的论文卖点 | A |
| 许可证 | Apache-2.0 | A |

判定：**质量备胎，工程出局**。980 Ti 上的 TF2 + CUDA 栈维护成本太高；只在某个镜头出现超大位移且 RIFE 崩坏时，考虑离线借用社区 PyTorch 移植单镜处理，不进主线。

### 2.3 GMFSS / GMFSS_Fortuna —— 质量强、显存爆，出局

| 项 | 数据 | 证据 |
|---|---|---|
| 本体 | CVPR 2023，GMFlow 全局匹配光流 + 特征细化融合 | A：github.com/98mxr/GMFSS |
| 显存（官方明示） | 720p 约 5.13GB、1080p 约 14.75GB；官方自承高显存是已知问题，缓解法只有降分辨率/降采样因子 | A：repo README |
| Fortuna 版 | 官方加速续作：1080p 约 25fps/约 6.3GB（A100 口径）、720p 约 51fps；仍未给出低显存模式 | A：github.com/98mxr/GMFSS_Fortuna |
| 许可证 | MIT | A |

判定：720p 的 5.13GB 意味着在 6GB 卡上常驻即贴边，且作者后续版本也没往低显存走。**出局**；它的价值只在于证明「光流式插帧的质量上限可以很高」。

### 2.4 本组小结

插帧段定版：**RIFE ncnn-vulkan（rife-v4.6 / rife-anime）负责 2× 补帧（12→24fps），480p 下显存约 1GB 内、速度在 980 Ti 上可接受且不占 CUDA 栈**。生产帧率策略：驱动与传播按 12fps 做，RIFE 只做最后一道 2×，不指望它救大运动。

---

## 3. 运动传递 / 驱动：谁负责「动起来」

这一段是整条管线的分水岭。先给分类结论：

- **脸部特写类**（LivePortrait / SadTalker）：只会动脸，对全身小狗不对口，仅表情特写可用。
- **关键点 warp 类**（FOMM / Thin-Plate Spline）：通用但分辨率低、早被大模型生态淘汰，对液态角色是「错误工具」。
- **扩散类**（ToonCrafter）：效果对口卡通，但它本身就是视频扩散模型，显存直接违背本路线的前提。
- **纹理合成传播类**（EbSynth）：不学习、不生成、纯算法搬运关键帧像素——**与本路线假设最契合，也是对墨团团最对口的一个**。

### 3.1 EbSynth —— 本路线的中枢组件（重点核实）

| 项 | 数据 | 证据 |
|---|---|---|
| 原理 | Jamriska 等人的 Example-Based Synthesis（SIGGRAPH 2019 系）：PatchMatch 最近邻场 + 多尺度金字塔 + 投票合成。把 1 张（或几张）画好的关键帧的外观，按「引导视频」的运动搬运到每一帧。不是神经网络、不需要训练、不需要数据集 | A：ebsynth.com、github.com/jamriska/ebsynth |
| 硬件 | **官方实现自带 CPU 后端与 CUDA 后端两套**（ebsynth_cpu.cpp / ebsynth_cuda.cu），Linux 有 cpu_only 构建脚本；显存需求为零（CPU 路线）。速度随分辨率与迭代数变化，社区口径为秒级到十秒级每帧（C 级，需在目标机实测） | A：jamriska/ebsynth 源码结构与构建脚本 |
| 输入要求 | 需要一段「引导/驱动视频」提供运动与引导通道（原视频帧、边缘、姿态等）。它不发明运动，驱动视频从哪来决定成片动得多好（真人演、手偶、3D 粗演、骨骼动画渲染都可以） | A |
| 卡通实证 | EbSynth 的经典用例就是手绘动画与风格化视频（官方演示即绘画风格迁移）；其传播对平涂、线条、水墨这类「外观可由样本块拼贴」的风格天然友好 | A/B |
| 画质短板 | (1) 遮挡/露出新内容时无中生有能力为零，样本里没有的像素拼不出来，表现为拉花、重复纹理；(2) 长镜头会漂移，必须每隔一段补一张新关键帧「接力」；(3) 拓扑突变（液态团成球再弹开）时 PatchMatch 对应关系断裂，需要在突变点两侧各放关键帧、分段合成 | A/B |
| 许可证（要分清两个东西） | jamriska/ebsynth 开源实现可自行构建使用；官方 EbSynth Beta 桌面应用是 Secret Weapons 的免费软件，其条款对商业使用有限制说法。工程上应以「自构建开源实现」为准并在立项时复核当期条款，避免直接把 Beta 应用嵌进商业管线 | A/B（条款需立项复核） |

为什么它对墨团团格外对口：团团是**无定形态的液态墨汁体**——没有骨骼、没有关节、没有固定拓扑，骨骼绑定和关键点 warp 对它全部失效；而 EbSynth 只要求「外观样本 + 运动引导」，团团的墨迹边缘、晕染纹理恰好是 PatchMatch 最擅长搬运的东西。团团的变形越夸张，越应该用「多关键帧分段传播」而不是「连续 warp」。

### 3.2 LivePortrait —— 只留给面部特写

| 项 | 数据 | 证据 |
|---|---|---|
| 本体 | 快手 Kling 团队，隐式关键点 + warp + SPADE 生成，含 animals 模式（猫狗脸） | A：github.com/KlingAIResearch/LivePortrait |
| 速度/显存 | 官方口径：RTX 4090 上 512×512 单帧约 12.8ms（fp16）；权重总量约 0.6-1GB 量级。官方未给显存表与低端卡数据（未查得 A 级） | A |
| 980 Ti 可行性 | 推算可跑但慢：无 FP16 加速、无 TensorRT 路径（FasterLivePortrait 的 TRT 引擎要求 SM75+，Maxwell 用不了），PyTorch FP32 下估计 0.5-2 fps 量级（C 级）。ONNX 路线（FasterLivePortrait 的 onnxruntime 后端）是老卡唯一现实加速法 | C |
| 短板 | 只做头部/面部：转头角度、张嘴幅度、非人脸对象都有限；animals 模式只支持猫狗「脸」，团团的全身戏、变形戏不在射程 | A |
| 许可证 | 代码 MIT；权重/insightface 组件带非商业限制，商用要单独核 | A |

### 3.3 SadTalker / FOMM / Thin-Plate Spline —— 记录在案，不进主线

| 组件 | 关键数据 | 判定 |
|---|---|---|
| SadTalker | 音频驱动说话头；官方 Colab 口径 T4 可跑；第三方拆解峰值显存 256 约 3-4GB、512 约 5-7GB；Wav2Lip + facevid2vid 架构。许可证为 Apache-2.0 但官方声明限非商业研究使用 | 只解决「人脸对口型」，团团无对白口型需求（既定方针无对白），出局 |
| FOMM（First Order Motion） | 2020 年关键点 warp 经典；vox 模型 256×256；权重小（生成器约 174MB、检测器约 54MB，Qualcomm AI Hub 口径）；6GB 绰绰有余、CPU 都能慢跑 | 分辨率与画质已被淘汰；关键点对液态无骨骼角色无定义，出局（仅作技术史记录） |
| Thin-Plate Spline Motion Model | CVPR 2022，TPS 变换处理大幅度运动；官方建议 8GB+ 显存口径；权重约数百 MB | 同上：warp 类对拓扑突变无解，出局 |

### 3.4 ToonCrafter —— 对口但违背前提，出局（重要反例）

| 项 | 数据 | 证据 |
|---|---|---|
| 本体 | 腾讯 AI Lab + 港中文，基于 DynamiCrafter 视频扩散先验的卡通两帧间生成式插值，最多生成 16 帧、512×320 | A：github.com/Doubiiu/ToonCrafter |
| 显存（官方明示） | 官方表：A100、DDIM 50 步，约 24GB 显存、约 24 秒/段；issues 反馈实际 24-27GB，社区优化后约 10GB | A：repo README 模型表 |
| 许可证 | Apache-2.0（代码）；底座 DynamiCrafter 权重另有条款 | A |

判定：ToonCrafter 是「卡通插帧质量上限」的证明，但它就是一个小号视频扩散模型——**用它等于把路线 B 变回路线 A（端到端扩散）**，980 Ti 上连社区优化版的 10GB 都装不下。记录在案：若未来有蒸馏/量化版把显存压到 5GB 内，它是第一个要重新评估的组件。


---

## 4. 光流 warp 与姿态/深度驱动（管线的「胶水层」）

### 4.1 光流：RAFT 家族（小而老，正合适）

| 项 | 数据 | 证据 |
|---|---|---|
| RAFT（原版） | 约 5.3M 参数；有 `--small` 变体（约 1M 参数级）。相关体积在高分辨率吃显存，480p 下 fp32 约 1-2GB 量级（C 级推算）；纯卷积+GRU 迭代，无注意力，对 Maxwell 友好 | A：github.com/princeton-vl/RAFT |
| SEA-RAFT | 后续高效版，最小模型在 RTX 3090 上 1080p 约 21fps；架构仍兼容老卡思路（无 FP16 依赖） | A/B：arXiv 2405.14793 |
| 在本管线中的角色 | 不是独立出片组件，而是胶水：(1) 由驱动视频算光流，warp 上一关键帧得到传播初稿（EbSynth 的低配替代/预演）；(2) 给 RIFE 前做运动幅度检测，超阈值的帧对自动标记为「需要补关键帧」；(3) 时域一致性检查（正反光流一致性找遮挡区） | 方法论 |

注意与 EbSynth 的分工：纯光流 warp 只能拉伸已有像素、遮挡处必拉花；EbSynth 的 PatchMatch 会「找相似块来填」，观感明显好一档。所以主线用 EbSynth 传播，光流只做检测与预演，不做最终传播。

### 4.2 姿态/深度提取（驱动信号的生产端）

| 组件 | 可行性 | 说明 |
|---|---|---|
| DWPose / OpenPose（RTMPose 系） | annotator 级小模型，CPU 可跑、GPU 更快；显存数百 MB 级 | 从真人驱动视频逐帧抽骨架，既喂 T2I-Adapter 生成关键帧，也可做 EbSynth 的引导通道 |
| MiDaS small（深度） | 约百 MB 级小模型，CPU 可跑 | 给关键帧生成提供构图深度；也可作引导通道区分前后景，分轨传播（背景轨/角色轨分开 EbSynth，是官方推荐的多轨用法） |
| 轮廓/边缘（Canny、线稿提取） | 纯传统算法，零学习成本 | 水墨风的关键引导：墨迹轮廓线是最强的对应信号，引导通道里必须带边缘图 |

要点：这一层全部可以放在 CPU 上离线跑，不占 GPU 预算；它的质量（骨架抖不抖、轮廓稳不稳）直接决定传播段的稳定性，属于「便宜但重要」。

---

## 5. 2D 卡通专用：传统动画软件化方法与 AI 的结合点

这一节回答一个关键问题：不用神经网络「生成运动」，用传统 2D 动画的骨骼/网格手段给团团造运动，可行吗？

### 5.1 工具盘点

| 工具 | 机制 | 硬件 | 许可证/价格口径 | 对团团的适配 |
|---|---|---|---|---|
| Live2D Cubism | 把一张分层图切成网格（ArtMesh），用变形器（Warp/Rotation Deformer）做伪 3D 转头、呼吸、摆动；参数驱动 | 纯 CPU 软件，集显可跑 | 商业软件，有免费版（功能/规模受限），PRO 版订阅/买断 | 适合「站桩表演」：眨眼、歪头、身体晃、铃铛摆。做不了满地滚与液态变形 |
| Spine | 骨骼绑定 + 网格权重 + FFD 自由变形 + IK，游戏动画工业标准 | 纯 CPU，运行时极轻 | 商业（Essential/Professional 分级，专业版约数百美元买断口径） | 需要骨骼——团团无骨骼，只能给「四臂魔王形态」这类有肢体的形态绑；常态团团不适配 |
| OpenToonz | 吉卜力系 Toonz 的开源版：矢量关卡、网格变形（Plastic Tool）、自动中间帧（矢量形状插值）、FX 图 | 纯 CPU，老机器可跑 | BSD 系开源、免费 | 矢量中间帧对「形状 A 变形状 B」有原生支持，是液态变形的传统解法之一；学习成本高、上色管线重 |
| Blender Grease Pencil | 描绘帧 + Interpolate 插值工具 + 修改器（Noise、Time Offset 等） | CPU 为主 | GPL 开源免费 | 手绘关键帧 + 自动补间 + 可脚本化（Python API），适合做「驱动视频」的生产线：用简笔画/灰模把动作演出来再渲染成引导 |
| CACANi 等自动中间帧商业软件 | 专为日式动画设计的自动 inbetween + 自动上色 | CPU | 商业 | 证明了「关键帧+自动中间帧」在工业动画里是成熟范式；但生态封闭，不进主线，仅作范式证据 |
| Cascadeur（3D 向） | AI 辅助关键帧 + AutoPhysics + Inbetweening（本地运行、官方明示 AI 工具在本机跑） | CPU 为主 | 商业分级 | 不是 2D 工具；价值在于范式：3D 粗演（灰模摆动作）渲染成驱动视频喂给 EbSynth，这条「粗演驱动」路线对全身动作最稳 |

### 5.2 AI 与传统方法的结合点（本节核心结论）

1. **分工原则**：传统方法负责「运动与变形的可控性」，AI 负责「外观的丰富度」。让 SD 只画少量定妆关键帧（它最擅长、且可以反复抽卡挑最好的），让网格/骨骼/传播负责把关键帧动起来（确定性、可复现、不漂移）。
2. **自动绑定的可能性**：单图自动分层（语义分割）→ 自动生成网格与变形器参数的管线在研究界已有原型（如自动 Image-to-Live2D 管线：分割 → 补画遮挡层 → Delaunay 网格 → 变形器模板）。对团团这种结构简单的角色（一个主体 + 铃铛 + 眼睛），人工分层成本本来就低，自动化是锦上添花，不是前置条件。
3. **团团的特殊解**：团团常态动作库其实很小——弹跳、滚动、拉长、压扁、探头、抖动。这些用「网格挤压拉伸（squash & stretch）+ 轮廓关键帧」就能覆盖大半，恰好是卡通十二原则里最软件化的部分。**先把动作拆成参数化变形原语，再谈生成**，是这条路线对液态角色的独门优势：扩散模型要「学会」的东西，这里是几个可调参数。

---

## 6. 修复段：管线的最后一公里

| 手段 | 用在哪 | 成本 | 注意 |
|---|---|---|---|
| SD1.5 img2img 低强度重绘（denoise 0.2-0.35） | 传播拉花的局部帧、遮挡边缘 | 与关键帧段共用同一套模型，逐帧约数秒 | 强度过高会引入时域闪烁；必须配合固定种子 + 引导图，且只修标记区域（inpaint 模式） |
| SD1.5 inpaint（专用权重） | 遮挡露出区「无中生有」的唯一生成手段 | 同上 | 这是整条管线里唯一真正做生成的修复手段，面积要小、要有关键帧参考兜底 |
| EbSynth 二次传播 | 以修复好的帧为新关键帧，重新向两侧传播 | CPU 时间 | 官方推荐工作法：哪里坏了就在哪里补关键帧重跑，而不是全片重做 |
| 时域去闪烁 | 全片收尾 | ffmpeg `deflicker` 等传统滤镜零学习成本；或光流对齐后时域均值 | 传统滤镜对水墨晕染这类低频闪烁有效，对结构抖动无效——结构抖动要回传播段解决 |
| 超分收尾（可选） | 480p 出片放大到 720p/1080p 交付 | Real-ESRGAN ncnn-vulkan 版同样走 Vulkan、老卡可跑（同 RIFE 的部署逻辑） | 卡通线条超分易出假细节；只做 2× 且保留原片对比验收 |

不进修复段的东西：GFPGAN/CodeFormer 这类人脸修复模型——团团的「脸」是两只银灰大眼 + 墨团，人脸先验会把它修成人脸特征，禁用。

---

## 7. 推荐管线（定版组合）与显存/时间预算

### 7.1 主线管线（管线 B-1「传播式」）

```
第 0 步 驱动先行：先定运动，再定外观
  真人表演录制 / 手偶 / Blender 灰模粗演 / 骨骼动画渲染，四选一产出驱动视频（12fps、480p 竖屏）
  CPU 抽取引导：轮廓边缘 + 姿态/深度（DWPose、MiDaS small），分背景轨/角色轨

第 1 步 关键帧（GPU，SD1.5 段）
  SD1.5 + 团团 LoRA + LCM-LoRA 4 步 + T2I-Adapter（姿态对齐驱动帧）
  在动作的极值姿势、遮挡转折、变形突变点取 4-8 张关键帧，TAESD 预览选图、原 VAE 定稿
  峰值显存约 5-5.5GB（FP32 路径），每张约 5-20 秒

第 2 步 传播（CPU，EbSynth 段）
  以关键帧为样式源、驱动视频为引导，分段（每段约 10-20 帧）PatchMatch 传播
  显存 0；耗时为本管线大头，按分钟级/段预算（需目标机实测标定）

第 3 步 插帧（GPU/Vulkan，RIFE 段）
  rife-ncnn-vulkan（rife-anime 优先）12fps → 24fps，显存约 1GB 内

第 4 步 修复（GPU+CPU 混合）
  光流一致性自动标记崩坏帧 → SD1.5 inpaint 局部修 → EbSynth 以修复帧重传播该段
  → ffmpeg deflicker 收尾 →（可选）Real-ESRGAN ncnn 2× 超分交付
```

各段**串行加载、用完卸载**，所以峰值显存取各段最大值（约 5.5GB），不叠加——这是组件管线对 6GB 卡的根本友好之处，也是它与「一个大模型全塞显存」的本质区别。

### 7.2 备线管线（管线 B-2「骨骼/网格式」）

角色分层图 → Live2D 式网格变形 / Blender Grease Pencil 关键帧补间，直接渲染 12fps → RIFE 补到 24fps → 同上修复段。
适用：站桩对话、表情戏、循环动作（待机、走路循环）。优势是零传播漂移、无限时长、改动作只改参数；劣势是搭建成本一次性投入大、动作天花板低。**B-2 与 B-1 不是二选一：B-2 产出的渲染正好可以当 B-1 的驱动视频。**

### 7.3 时间预算（5 秒镜头、C 级估算，需实测标定）

| 段 | 估算耗时 | 备注 |
|---|---|---|
| 驱动制作 | 人工为主，0.5-2 小时（熟练后压缩） | 真正的成本大头是人，不是机器 |
| 引导抽取（CPU） | 约 1-3 分钟 | 离线批处理 |
| 关键帧 4-8 张 | 约 2-5 分钟（含抽卡挑选） | 步数蒸馏后已不是瓶颈 |
| EbSynth 传播约 60 帧 | 约 10-40 分钟（分辨率/迭代数敏感） | 机器侧瓶颈，可挂机 |
| RIFE 补帧 | 约 1-3 分钟 | 480p |
| 修复 1-2 轮 | 约 10-20 分钟 | 取决于崩坏帧比例 |
| 合计机器时间 | 约 0.5-1 小时/5 秒镜头量级 | 对比：端到端扩散在同卡上是「跑不起来」，不在同一坐标系 |

---

## 8. 质量上限与瓶颈（回答研究问题）

### 8.1 质量上限（分维度）

| 维度 | 上限 | 为什么 |
|---|---|---|
| 角色一致性 | **高，甚至高于扩散视频** | 每一帧的外观都来自同一批手选关键帧的像素搬运，没有逐步重采样漂移；团团三件套（银灰大眼、铜铃铛红穗、墨汁质感）在关键帧里对了，就全片都对 |
| 分辨率/清晰度 | 480p 原生可用，720p 靠超分凑数 | SD1.5 的原生舒适区就是 512 级；再往上关键帧段先崩 |
| 运动质量 | 等于驱动源质量 | 管线不发明运动：真人演得好就好，灰模摆得僵就僵 |
| 运动幅度 | 中小幅度安全区 | 大转身、大遮挡、快速位移同时出现时，传播段必然拉花，只能靠加密关键帧把「大动作」切成「若干小动作」 |
| 时长 | 单段 3-5 秒最稳，靠分段接力可延长 | 漂移随离关键帧距离累积；分段点选在动作极值处可无缝衔接 |
| 场景复杂度 | 固定场景 + 单角色是甜区 | 多角色交互、复杂前景遮挡会成倍增加分轨与修复工作量 |

与 Seedance 2.5 的差距定性（不回避）：差距不在单帧画质，而在**「无中生有的运动发明能力」和长镜头一镜到底的连贯性**。本管线换来的东西是：本地可跑、成本可控、角色零漂移、每一帧可人工干预。对固定 IP 的日更短镜头，这个交换是划算的；对开放题材长视频，不成立。

### 8.2 瓶颈排序

1. **运动源（人力瓶颈）**：整条管线的质量天花板由驱动视频决定，而驱动制作目前靠人演/人摆。这是第一瓶颈，也是后续最值得自动化的地方（例如用姿态估计 + 动作库重定向把常见动作模板化）。
2. **遮挡与形态突变处的生成缺口（算法瓶颈）**：EbSynth/warp 只能搬运，inpaint 只能小面积补。团团液态变形既是优势（无拓扑、容忍拉伸）又是难点（团成球再弹开对应关系断裂）——解法是流程性的：突变点双关键帧 + 分段传播 + 必要时把突变本身做成 2-3 帧手绘/SD 生成的「特效帧」硬切进去。
3. **EbSynth 的 CPU 耗时（机器瓶颈）**：零显存的代价是慢。可优化路径明确：用它自带的 CUDA 后端时需注意 SM52 兼容的旧 CUDA 构建；或先用光流 warp 出预演稿确认动作，再只对定稿跑全量 EbSynth。
4. **SD1.5 段的 FP32 税（硬件瓶颈）**：980 Ti 无 FP16 加速，关键帧段被迫 FP32，显存贴边、速度打折。已被步数蒸馏（LCM/Hyper）基本对冲；剩余风险是多条件叠加时显存溢出——纪律是「同时最多 1 个 ControlNet，或优先 T2I-Adapter」。
5. **不是瓶颈的两项（辟谣式记录）**：插帧（RIFE 有 980 Ti 实证、且走 Vulkan）；VAE 解码（TAESD 基本免费解决预览，定稿用原 VAE 也不贵）。

### 8.3 必须实测标定的未知数（下一阶段清单）

- EbSynth 在目标机 CPU 上 480p 单帧耗时（决定传播段真实成本）——目前只有量级口径，无 A/B 级实测。
- RIFE PyTorch 版在 980 Ti 上的确切显存/帧率（ncnn 版有兼容实证，PyTorch 版数字为推算）。
- SD1.5 FP32 + LCM-LoRA + T2I-Adapter 在 6GB 内的实际峰值（1660S 的 5.3GB 是含 ControlNet 的 FP32 口径，可作上限参考）。
- LivePortrait animals 模式对团团脸的实际效果（只有模式存在性证据，无效果实证）——优先级低，只影响特写备线。

---

## 9. 组件总表（速查）

| 组件 | 角色 | 显存 | 980 Ti/CPU | 许可证 | 去留 |
|---|---|---|---|---|---|
| SD1.5 + LCM-LoRA/Hyper-SD | 关键帧 | 约 5-5.5GB（FP32） | 可行，有实证 | OpenRAIL-M / MIT（LoRA） | 主线 |
| TAESD | 预览解码 | 约 5MB 级 | 可行 | MIT | 主线 |
| T2I-Adapter | 姿态/深度控制 | +约 0.15GB/个 | 可行 | Apache-2.0 | 主线 |
| ControlNet 1.1 | 强控制（单个） | +1-2GB/个 | 勉强（需 offload） | Apache-2.0 | 备选 |
| SDXL | 高质量关键帧 | 权重 6.9GB 起 | 出局（本地） | OpenRAIL++-M | 出局 |
| RIFE ncnn-vulkan | 插帧 2× | 约 1GB 内 | 可行，980 Ti 有实证 | MIT（官方 repo） | 主线 |
| FILM | 大运动插帧 | 未公布 | 工程出局 | Apache-2.0 | 备胎 |
| GMFSS | 高质量插帧 | 720p 约 5.13GB（官方） | 出局 | MIT | 出局 |
| EbSynth（jamriska 实现） | 关键帧传播 | 0（CPU） | 可行，纯 CPU | 开源实现；官方应用条款需复核 | 主线中枢 |
| RAFT / SEA-RAFT | 光流检测/warp 预演 | 约 1-2GB（推算） | 可行 | BSD 系（RAFT） | 胶水层 |
| DWPose / MiDaS small | 引导信号抽取 | 数百 MB / CPU 可跑 | 可行 | 各自开源协议 | 胶水层 |
| LivePortrait | 面部特写驱动 | 约 1GB 级（推算） | 慢跑（FP32/ONNX） | 代码 MIT，权重有限制 | 特写备线 |
| SadTalker | 说话头 | 256 约 3-4GB | 可行但不对口 | Apache-2.0 + 非商业声明 | 出局 |
| FOMM / TPS | 关键点 warp | 1GB 内 | 可行但已淘汰 | 研究代码协议 | 出局 |
| ToonCrafter | 卡通生成式插帧 | 官方约 24GB | 出局 | Apache-2.0（代码） | 出局（待蒸馏版重估） |
| Live2D / Spine / OpenToonz / Grease Pencil | 骨骼/网格运动 | 0（CPU） | 可行 | 商业 / 商业 / BSD / GPL | 备线 B-2 |

---

## 10. 主要来源

- SD1.5 / SDXL 权重与许可证：huggingface.co/runwayml/stable-diffusion-v1-5、huggingface.co/stabilityai/stable-diffusion-xl-base-1.0
- 低显存与 offload：github.com/AUTOMATIC1111/stable-diffusion-webui（wiki）、docs.comfy.org、github.com/comfyanonymous/ComfyUI
- 6GB 卡 SD1.5+ControlNet 实测：tech-en.andhandworks.com 2026 年 GTX 1660 Super 系列（25 步 61.5s/5.3GB、Hyper 4 步 11.1s 等）
- LCM-LoRA：huggingface.co/latent-consistency/lcm-lora-sdv1-5、github.com/luosiallen/latent-consistency-model
- TAESD：github.com/madebyollin/taesd、github.com/rupeshs/fastsdcpu
- ControlNet / T2I-Adapter：github.com/lllyasviel/ControlNet-v1-1、github.com/TencentARC/T2I-Adapter
- RIFE：github.com/hzwer/ECCV2022-RIFE、github.com/nihui/rife-ncnn-vulkan、github.com/n00mkrad/flowframes、svp-team.com（RIFE GPU 兼容列表与论坛实测）
- FILM：github.com/google-research/frame-interpolation、film-net.github.io
- GMFSS：github.com/98mxr/GMFSS、github.com/98mxr/GMFSS_Fortuna
- EbSynth：ebsynth.com、github.com/jamriska/ebsynth
- LivePortrait：github.com/KlingAIResearch/LivePortrait、github.com/warmshao/FasterLivePortrait
- SadTalker / FOMM / TPS：github.com/OpenTalker/SadTalker、github.com/AliaksandrSiarohin/first-order-model、github.com/yoyo-nb/Thin-Plate-Spline-Motion-Model
- ToonCrafter：github.com/Doubiiu/ToonCrafter（README 显存表：A100 约 24GB/24s）
- RAFT：github.com/princeton-vl/RAFT、SEA-RAFT arXiv:2405.14793
- 传统动画：live2d.com（Cubism）、esotericsoftware.com（Spine）、opentoonz.github.io、docs.blender.org（Grease Pencil）、cascadeur.com（AI 工具本地运行说明）

（注：个别组件的显存/速度为 C 级推算或同档硬件旁证，已在正文逐项标注；正式立项开发前应按第 8.3 节清单在目标机逐项实测标定。）
