# MiniMax H3 功能全清单（自研视频生成模型对标表）

核查日期：2026-10-22
核查原则：以 MiniMax 官方来源为准；社区/合作伙伴说法单独标注，不混入官方规格。

来源分级：
- [官方] MiniMax 官方 API 文档（platform.minimax.io）/ MiniMax 官方 GitHub 仓库 MiniMax-AI/MiniMax-H3（含随开源发布的技术说明与官方范例）
- [官方生态] MiniMax 官方文档转引或链接的生态文档（Hugging Face diffusers 集成文档、SGLang 上游基准、ComfyUI 官方工作流说明）
- [合作伙伴] Runway、fal 等官方合作渠道的产品页/说法
- [社区] 第三方媒体、博客、聚合站的报道与实测

---

## 0. 产品确认结论

**用户口中的「MiniMax H3」是真实存在的官方产品，不是社区臆造的名字。**

- 正式产品名：**MiniMax H3**；托管 API 模型 ID：`MiniMax-H3`。MiniMax 官方文档 Models 页原文称其为 "Next-gen open general-purpose multimodal video model"（下一代开放通用多模态视频模型）。[官方]
- 系统构成（官方架构）：三个模块 —— **H3-Context-IR**（多模态上下文理解与提示增强，托管组件，未开源）、**H3-Base**（生成本体，768P 出片）、**H3-Regenerate-2K**（把 768P 结果连同原始上下文回灌模型、上下文内重生成 2K，托管组件，未开源）。[官方]
- 开源权重只有 H3-Base，分两个任务检查点：**FL2VA**（文生/首尾帧）与 **Ref2VA**（全能参考），均为 BF16、CFG 蒸馏权重，许可证为 MiniMax H3 Community License Agreement（非 Apache）。[官方]
- 架构数字（官方仓库）：H3-Omni-Transformer，33B 参数稠密单流 Transformer，其中约 13B 为 AdaLN 分支参数（其输出可预计算缓存，纯推理部署可不加载）；编码器为 Qwen3-VL-32B 全量预训练权重，取第 50 层隐状态；VisualVAE 压缩比 f16t4d24（空间 16 倍、时间 4 倍、24 通道），AudioVAE 把 32 kHz 音频压到 40 Hz latent（左右声道独立同构编码）；位置编码为 3D MM-RoPE。[官方]
- 变体：**MiniMax-H3-Max**（API 模型 ID `MiniMax-H3-Max`），由 fal.ai 在 H3 基础上后训练的高速版，由 MiniMax 与 fal 联合发布，走同一套 content[] 协议；只有它支持 480P、不支持 2K。与 H3 本体是两个模型 ID，对标时不要混。[官方]
- 「Hailuo 3.0 / Hailuo 03 / 海螺3」定性：**别名，非官方型号名**。Hailuo AI（海螺）是 MiniMax 的消费端 App 品牌（官网 hailuoai.video，官方仓库以 Hailuo AI 徽章链接到该 App）；合作伙伴与社区普遍把 H3 称作 Hailuo 3.0（Runway 官方产品页原文："Hailuo 3 is MiniMax's name for the model and H3 is how it appears in Runway's video model picker" [合作伙伴]），但 MiniMax 自己的文档、仓库、模型卡统一只写 **MiniMax H3**，未见其以「Hailuo 3.0」为正式型号名。对标与引用时应以 MiniMax H3 为准。[官方][合作伙伴]
- 易混淆项：MiniMax-M3 / M3.1-Flash 是语言/编程模型，与 H3 无关；Kling O3 是快手可灵的产品，「Hailuo 03」拼法易与其混淆（HF 社区文已特别提醒）。[官方][社区]
- 时间线：2026-07-31 发布并上线托管 API 与 Hailuo AI App [社区多源一致]；官方 GitHub 仓库创建于 2026-07-30 [官方]；H3-Base 开放权重于 2026 年 8 月初发布（8 月 2–3 日，各源日期略有出入）[社区]。

---

## 1. 功能全清单（F01–F45）

### A. 生成模式

| 编号 | 功能项 | 支持 | 规格 / 说明 | 依据 |
|---|---|---|---|---|
| F01 | 文生视频 T2V | 支持 | 仅提示词生成；API 中提示词为必填且必须非空，否则报参数错误 | [官方] API 参考 Create Video Generation Task |
| F02 | 图生视频（首帧） | 支持 | text + 1 图，role=first_frame（或省略 role） | [官方] API 参考 |
| F03 | 尾帧控制（仅尾帧） | 支持 | text + 1 图，role=last_frame，可单独只给尾帧决定落点 | [官方] API 参考 |
| F04 | 首尾帧生视频 | 支持 | 两图分别标 first_frame / last_frame，模型补中间运动；本地检查点即 FL2VA | [官方] API 参考；[官方] GitHub 仓库变体表 |
| F05 | 全能参考生视频 R2V | 支持 | 参考图 ≤9、参考视频 ≤3、参考音频 ≤3，混合总文件数 ≤12；本地检查点即 Ref2VA | [官方] 视频生成指南输入要求表；[官方] GitHub 仓库 |
| F06 | 视频生视频 V2V | 支持 | 不是独立任务值，而是 Ref2VA 的一种参考输入形态（官方能力矩阵原文） | [官方] 本地部署文档 Capability matrix |

### B. 叙事与控制

| 编号 | 功能项 | 支持 | 规格 / 说明 | 依据 |
|---|---|---|---|---|
| F07 | 多镜头叙事（单次生成内多镜头） | 支持 | 一次生成内可用 [Shot 1] / [Shot 2] 分镜结构并在指定时间点切镜；官方 Context-IR 输出范例中出现 "At 00:04.500, the camera cuts to a close-up" 的多镜头提示结构 | [官方] GitHub 仓库 case-T2VA 范例；[社区] 发布报道称官方口径为 native multi-shot generation |
| F08 | 运镜控制 | 支持（提示词式） | 在关键描述后直接写运镜指令引导镜头，官方指南举例 [pan]、[zoom]、[static] 方括号指令，也可自然语言描述；API 参数中无独立数值化运镜参数 | [官方] 视频生成指南 Text-to-Video 节 |
| F09 | 参考视频运镜 / 剪辑节奏迁移 | 支持 | 参考生成模式的官方典型用途原文包括 reference "character, motion, camera, style, voice, or editing rhythm" | [官方] 视频生成指南模式表 |
| F10 | 任意帧引导（中间帧引导） | 支持（本地生态） | ComfyUI 高级工作流经 MiniMaxH3AddGuide 提供 arbitrary-frame guides；托管 API 参数表中未见对应项 | [官方] 本地部署文档（提及该 ComfyUI 能力） |

### C. 主体与参考一致性

| 编号 | 功能项 | 支持 | 规格 / 说明 | 依据 |
|---|---|---|---|---|
| F11 | 主体 / 角色参考一致性 | 支持 | 官方指南原文：参考生成时 "the model keeps the features of the reference subject or asset consistent throughout the generated video"；参考图上限 9 张 | [官方] 视频生成指南 Reference Generation 节 |
| F12 | 多主体定义与同框 | 支持 | Context-IR 以 subject_definitions 结构逐一定义多个主体（<Subject 1>…）并在分镜中引用 | [官方] GitHub 仓库 case-Ref2VA 范例 |
| F13 | 声音音色参考 | 支持 | 参考音频可作为指定主体的音色参考（官方范例中 <Audio 2> 为 <Subject 1> 的 voice timbre reference，与 F20 对口型联动） | [官方] GitHub 仓库 case-Ref2VA 范例 |
| F14 | 动作 / 运动参考 | 支持 | 参考视频可控制目标视频的运动（与 F09 同源，官方模式表列 motion 为可参考维度） | [官方] 视频生成指南模式表 |

### D. 编辑与后处理

| 编号 | 功能项 | 支持 | 规格 / 说明 | 依据 |
|---|---|---|---|---|
| F15 | 指令式视频编辑（自然语言改现有视频） | 支持 | 官方指南对 H3 的定性即 "supports video generation, reference-based creation, and video editing"；官方 Ref2VA 范例就是一条源视频编辑任务：保留原构图/光线/背景（retention_analysis 标 fully_preserved），只改指定元素、给人物加新台词口型；编辑关系用自然语言表达，没有固定任务菜单 | [官方] 视频生成指南；[官方] GitHub 仓库 case-Ref2VA 范例 |
| F16 | 局部重绘 / 修复（inpainting） | 支持（本地生态） | ComfyUI 高级工作流提供 latent noise masks 用于 inpainting；托管 API 无独立参数 | [官方] 本地部署文档 |
| F17 | 视频延长 / 续拍 | 部分支持（无独立 API 功能） | 托管 API 参数与端点中没有 extend 项；可用的官方机制是组合式的 —— 尾帧衔接再生成（F03/F04）、把上一段成片回灌作参考（diffusers 集成文档明示 a previous generation feeds back in as reference）、ComfyUI 高级工作流的 extension。另有 [社区] 说法称 Hailuo App 有 Extend 工具可拉长到约 30 秒，未在 MiniMax 官方文档中核实到，不作官方规格 | [官方] API 参考（无此参数）；[官方生态] diffusers 集成文档；[官方] 本地部署文档；[社区] 第三方报道 |
| F18 | 2K 再生（768P 升 2K） | 支持 | 独立的 Video Regeneration 任务端点：请求须复现原 768P 任务的全部 content 并恰加一个 role=base_video 的源视频；原理是 in-context regeneration（把低清结果与原始上下文一起回灌重生成），不是传统超分模块 | [官方] 视频生成指南 Video Regeneration 节；[官方] GitHub 仓库 H3-Regenerate-2K 节 |

### E. 音频

| 编号 | 功能项 | 支持 | 规格 / 说明 | 依据 |
|---|---|---|---|---|
| F19 | 原生立体声音频（音画同 pass 生成） | 支持 | 视频与声轨在同一个去噪过程中联合预测、一次出片；规格 32 kHz 立体声；无单独配音/混音后处理环节 | [官方] GitHub 仓库 System Overview 与架构节；[官方生态] diffusers 集成文档（no separate vocoder, no audio post-hoc pass） |
| F20 | 对白生成与对口型 | 支持 | 台词在提示结构中以 <d>[语言] 台词</d> 标注；口型随台词生成/编辑同步 —— 官方编辑范例原文称人物 "mouth movements naturally syncing to the new dialogue"、retention 分析称 "his mouth newly animated to speak" | [官方] GitHub 仓库 case-Ref2VA 范例 |
| F21 | 对白语言 | 支持 | 稳定支持 11 种：阿拉伯语、中文、英语、法语、德语、意大利语、日语、韩语、葡萄牙语、俄语、西班牙语；其他语言亦有不同程度支持 | [官方] GitHub 仓库规格表 |
| F22 | 音效与环境声 | 支持 | 提示结构含 overall_soundscape 段，描述环境声/动作音效并与画面事件对齐 | [官方] GitHub 仓库官方范例 |
| F23 | 音乐（配乐） | 支持 | 提示结构含 non_diegetic_music 段，与对白、音效同为一条音频流建模 | [官方] GitHub 仓库官方范例 |
| F24 | 音频复用 / 参考音频驱动 | 支持 | 参考音频可被部分复用为成片背景音乐（官方范例标 partially_copy）、或作节奏与音色参考；参考音频上限 3 段、每段 2–15 秒、总时长 ≤15 秒 | [官方] GitHub 仓库 case-Ref2VA 范例；[官方] 视频生成指南 |
| F25 | 音频开关 | 不支持（无此参数） | API 参数表中没有音频开关项，所有输出恒带原生音频 | [官方] API 参考参数表；[社区] 第三方页面亦称无法关闭 |

### F. 输出规格

| 编号 | 功能项 | 支持 | 规格 / 说明 | 依据 |
|---|---|---|---|---|
| F26 | 分辨率 | 支持 | 托管 API 两档：768P / 2K；本地 H3-Base 仅 768P（短边 768 像素，16:9 原生画布 1344×768，尺寸须为 32 的倍数），2K 须走托管 Regenerate-2K（模块未开源）。注：2K 的具体像素数官方未给数字，[合作伙伴/社区] 普遍称 16:9 为 2560×1440，不作官方规格 | [官方] 视频生成指南；[官方] 本地部署文档 |
| F27 | 帧率 | 支持 | 24 FPS（输出固定） | [官方] Models 页；[官方] GitHub 仓库规格表 |
| F28 | 时长 | 支持 | 托管 API：4–15 秒、仅整数秒；本地 diffusers 工作流文档写作 5–15 秒且帧数按 17k+5 网格对齐，属本地实现约束，与 API 口径要分开 | [官方] 视频生成指南；[官方生态] diffusers 集成文档 |
| F29 | 画幅 | 支持 | adaptive（自适应）+ 21:9、16:9、4:3、1:1、3:4、9:16 六种；T2V 时 ratio 必填且不可为 adaptive，I2V 时画幅由输入图决定，R2V 时可选、默认 adaptive；输入图/视频宽高比须在 [0.4, 2.5] | [官方] API 参考 ratio 参数 |
| F30 | 提示词规格 | 支持 | 上限 7000 字符；每次请求必填一个非空 text 项（包括图生/参考模式） | [官方] 视频生成指南；[官方] API 参考 |

### G. 速度与价格

| 编号 | 功能项 | 支持 | 规格 / 说明 | 依据 |
|---|---|---|---|---|
| F31 | 生成速度（托管 API 时延） | 官方未公布 | 官方文档不给单条渲染时延承诺；只公布限流：Video Generation V2（MiniMax-H3）RPM 300、最大并发任务 30 | [官方] Rate Limits 页 |
| F32 | 生成速度（自托管基准） | 有官方转引数据 | 负载统一为 5 秒 T2VA、1344×768、124 帧、50 步：4×H200 平均推理时延 75.10 秒（Cache-DiT 路径 53.70 秒）；8×B300 单节点 BF16：FL2VA 19.04 秒 / Ref2VA 29.12 秒（FP8 约 18.03 / 27.12 秒）。均为 SGLang 上游基准、由 MiniMax 官方部署文档转引，非托管 API 速度 | [官方] 本地部署文档性能表 |
| F33 | 快速变体 H3 Max | 支持 | fal.ai 后训练加速版，官方定性 "generates faster than MiniMax H3"，480P/768P、5–15 秒；[合作伙伴/社区] fal Research 称 5 秒 768P 可在 3 秒内出片、约 35 倍于官方端点（fal 口径，经第三方转述，未在 MiniMax 官方文档核实） | [官方] 视频生成指南；[合作伙伴] fal（经 explainx 转述） |
| F34 | API 价格 | 已公布 | 输出：768P $0.08/秒、2K $0.13/秒；输入素材：参考图前 5 张免费、其后 $0.04/张，参考视频按秒计（768P $0.08/秒、2K $0.13/秒），参考音频免费；Regeneration $0.05/秒；Context-IR $0.90 / $3.60 每百万 token（入/出） | [官方] Pricing Overview 页 |

### H. API 与开发者能力

| 编号 | 功能项 | 支持 | 规格 / 说明 | 依据 |
|---|---|---|---|---|
| F35 | 异步任务制 | 支持 | 创建任务返回 task_id，经 Query Task / List Tasks 轮询，状态机 queued / running / succeeded / failed / cancelled，成功后从 content.url 取成片；另有 Cancel or Delete Task | [官方] API Overview；[官方] API 参考 |
| F36 | 三类创建端点 | 支持 | Create Video Generation Task、Create H3-Context-IR Task、Create Video Regeneration Task（H3-Max 仅支持第一个） | [官方] API Overview |
| F37 | H3-Context-IR 提示增强 | 支持 | 独立端点：深度解读文本/图/视频/音频多模态上下文与相互关系，产出结构化增强提示（integrated_multimodal_description + overall_soundscape + non_diegetic_music 等结构），只返回提示、不生成视频；托管组件，未开源 | [官方] 视频生成指南；[官方] GitHub 仓库 |
| F38 | 回调 webhook | 支持 | callback_url：先发 challenge 验证（须 3 秒内原样返回），之后每次状态变化 POST 推送，推送体与 Query Task 响应同构 | [官方] API 参考 |
| F39 | 输入格式与大小限制 | 已规格化 | 图 JPG/JPEG/PNG/WEBP/HEIC/HEIF ≤30 MB、宽高 [256, 5760]；视频 MP4/MOV（H.264/H.265，内嵌音频 AAC/MP3）≤50 MB、帧率 [23.976, 60]；音频 WAV/MP3 ≤15 MB；请求体 ≤64 MB，大文件建议用 URL | [官方] API 参考 |
| F40 | content[] 协议与 role 体系 | 支持 | 元素 type 为 text / image_url / video_url / audio_url，role 为 first_frame / last_frame / reference_image / reference_video / reference_audio / base_video；首尾帧模式与参考模式互斥、不可混用；H3 与 H3-Max 共用协议、只改 model 字段切换 | [官方] API 参考；[官方] API Overview |
| F41 | 负向提示词 / CFG 参数 | 不支持 | 开源检查点为 CFG 蒸馏（guidance 已烘进权重），实现中无 negative_prompt、无 guidance_scale，每步只跑一次前向 | [官方] GitHub 仓库（CFG-distilled）；[官方生态] diffusers 集成文档 |
| F42 | 种子可复现 | 支持（本地） | 同一 generator 状态两次运行返回相同的视频与声轨；也可直接注入 latents / audio_latents 替换随机抽取 | [官方生态] diffusers 集成文档 |
| F43 | 开源权重与本地部署 | 支持 | H3-Base FL2VA / Ref2VA 的 BF16 权重开放（Community License）；官方部署路径：SGLang（文档基准为 8×B200 节点）、vLLM-Omni（社区维护 recipe）；ComfyUI 0.30.0 起原生 T2V/I2V/R2V 模板，使用 Comfy-Org 发布的剪枝 INT8 转换权重 | [官方] 本地部署文档；[官方] GitHub 仓库 License 节 |
| F44 | Turbo 加速 LoRA | 支持（本地） | 官方模板带可选 Turbo LoRA：FL2VA 8 步版、Ref2VA 4 步版，更快但官方明示可降低运动与音频质量 | [官方] 本地部署文档 |
| F45 | 画面内文字渲染 | 社区口径 | 多家第三方称可读文字/招牌/品牌信息渲染是其强项；MiniMax 官方文档未单列此规格（官方范例提示中含招牌等文字元素描述），暂只作社区能力记录，不作官方对标项 | [社区] 第三方测评多源 |

---

## 2. 官方明确「没有 / 未公布」的项（对标时勿臆测）

1. 没有独立的视频延长（extend）API 端点或参数（F17 只能靠组合机制）。
2. 没有音频关闭开关（F25），没有负向提示词与 CFG 参数（F41），没有数值化运镜参数（F08 为提示词式）。
3. 没有公布托管 API 的单条生成时延（F31），也没有公布 2K 档的具体像素尺寸（F26）。
4. Context-IR 与 Regenerate-2K 未开源：本地能拿到的只有 768P 的 H3-Base，官方完整 2K 效果不可本地复现（F18/F37/F43）。

## 3. 最难复刻的 3 项（针对自研路线）

1. **F19 + F20 原生音画联合生成与对口型**：单个 Transformer 在同一次去噪里同时预测视频 latent 与音频 latent，对白、口型、音效、配乐天然对齐。这不是「视频模型 + TTS + 对口型工具」的拼装能等价的——它要求音画联合预训练的数据与架构（AudioVAE + 联合调度），也是 H3 区别于上一代 Hailuo 2.3（无原生音频）的代际核心。
2. **F05 + F11 + F13 全能参考理解与一致性**：一次吃最多 12 份混合参考（图/视频/音频），并由自然语言逐份指定每份参考控制什么（身份、运镜、动作、音色、节奏），成片里还要保住主体特征一致。这背后是 Ref2VA 条件架构 + Context-IR 级的多模态关系推理，两层都难：前者是模型能力，后者干脆是未开源的托管系统。
3. **F07 + F15 多镜头叙事与指令编辑的任务泛化**：多镜头分镜（含时间点切镜）和「只改指定元素、其余 fully_preserved」的编辑，都不是独立功能模块，而是预训练阶段就把参考/编辑关系全部表达为自然语言的任务泛化设计，再加 Context-IR 的 retention 分析。复刻它等于复刻一整套「理解—结构化—生成」的提示工程体系，而非单个生成器。
（次难候选：F18 的 2K 上下文内重生成——思路可借鉴，但效果依赖基模本身的生成能力回灌。）

## 4. 出处链接（原文）

官方：
- 视频生成指南：https://platform.minimax.io/docs/guides/video-generation
- 创建视频任务 API 参考：https://platform.minimax.io/docs/api-reference/video-generation-v2-create
- API Overview：https://platform.minimax.io/docs/api-reference/api-overview?utm_source=chatgpt.com
- Models 页：https://platform.minimax.io/docs/guides/models-intro?utm_source=chatgpt.com
- 本地部署（自托管）文档：https://platform.minimax.io/docs/guides/local-deploy-h3
- 限流页：https://platform.minimax.io/docs/guides/rate-limits
- 价目页：https://platform.minimax.io/docs/pricing/overview
- 官方 GitHub 仓库（含技术说明与官方范例）：https://github.com/MiniMax-AI/MiniMax-H3

官方生态：
- diffusers 集成文档（MiniMax-H3）：https://huggingface.co/docs/diffusers/v0.40.0/en/api/pipelines/minimax_h3

合作伙伴 / 社区（仅作标注来源，不作官方规格）：
- Runway 产品页（Hailuo 3 别名与规格）：https://runway.com/product/models/minimax-h3
- HF 社区解析文（命名与别名说明）：https://huggingface.co/blog/ResterChed/minimax-h3-hailuo-3-0
- explainx（H3 Max 速度与许可证社区解读）：https://explainx.ai/blog/minimax-h3-open-video-model-hailuo-july-2026
