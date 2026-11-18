# Seedance 2.5 功能全清单（自研模型功能对标表）

核查日期：2026-10-22
核查对象：字节跳动 Seedance 2.5（2026-06-23 于火山引擎 FORCE 大会预览，2026-07-31 正式发布）

## 口径分级（重要，先读）

本清单严格区分三种口径，逐项标注，社区说法不混入官方清单：

- **A 级·官方直读**：字节官方页面原文已直接读取核对。包括：ByteDance Seed 官方发布稿、Seed 官方产品页、Dreamina（即梦国际版）官方产品页、CapCut 官方功能页。
- **B 级·官方文档转录**：BytePlus ModelArk 官方文档（Dreamina Seedance 2.5 tutorial / prompt guide / pricing）确实存在且持续更新（教程页最后更新 2026-10-20、提示词指南 2026-10-16），但页面为 JS 渲染、无法直读正文；以下参数细节由多家独立下游文档（Civitai 开发者文档、Sogni、fal、Kinovi、llm-stats 等，均声称直接对接 ModelArk 官方 API）交叉一致转录，可信度高，但引用时标注为转录口径。
- **C 级·社区/渠道说法**：第三方聚合站、评测、教程的说法，无官方原文支撑，单独收在文末隔离区，不计入官方功能项。

## 三个必须先知道的口径冲突

1. **分辨率**：Seed 官方发布稿与产品页**通篇没有给出分辨率数字**。Dreamina/CapCut 官方产品页宣称「原生 4K」；ModelArk API 口径只有 **480p / 720p**；1080p 出现在部分渠道 API（fal/Runway 于 2026-08-15 新增）与 Draft 样片模式的成片阶段。对标时应以「API 口径 480p/720p、平台口径 4K」分开记录，不能合并成一个数字。
2. **延长次数**：Seed 官方产品页写「可延长两次（extend twice）」；官方发布稿写「多轮延长（multiple rounds of extension）」并称可产出数分钟内容；CapCut/Dreamina 官方页写平台有 beta「长视频模式」上限 **180 秒**。三者是不同层面的表述，本清单分项记录。
3. **帧率**：任何官方发布材料均未写帧率。24 fps 来自 B 级 API 转录口径，多家一致。平台宣传的「升帧至 60 FPS」是 Dreamina 的后期编辑功能，不是模型原生帧率。

## 官方来源清单

- [S1] ByteDance Seed 官方发布稿《One-take Creation, Flexible Referencing: Introducing Seedance 2.5》（2026-07-31）：https://seed.bytedance.com/en/blog/one-take-creation-flexible-referencing-introducing-seedance-2-5
- [S2] Seed 官方产品页 Seedance 2.5：https://seed.bytedance.com/en/seedance2_5
- [S3] Dreamina 官方产品页《Official Seedance 2.5: 4K and 30s AI Video Generator with Audio》：https://dreamina.capcut.com/seedance/seedance-2-5
- [S4] CapCut 官方功能页《Seedance 2.5 for Video Editor》：https://www.capcut.com/features/seedance-2-5-for-video-editor
- [S5] BytePlus ModelArk 官方文档·Dreamina Seedance 2.5 tutorial（最后更新 2026-10-20）：https://docs.byteplus.com/en/docs/modelark/seedance-2-5
- [S6] BytePlus ModelArk 官方文档·Dreamina Seedance 2.5 prompt guide（最后更新 2026-10-16）：https://docs.byteplus.com/en/docs/ModelArk/2607688 （教程编号页，指南与其同级链接）
- [S7] 火山引擎官方发布口径（经澎湃新闻等转述字节跳动与火山引擎官方介绍，2026-07-31）：单次 30 秒、高保真时序延长、最多 50 个多模态参考、白模与绿幕参考、视频局部编辑、原生支持 10 余种语言。
- [S8] 火山引擎 Draft 样片模式官方公告口径（2026-09-22，经快科技/钜亨网/AIBase 等多家一致转述官方数据）：https://news.aibase.com/news/31293

接入入口（官方发布稿 S1 原文）：即梦 Web（视频生成 → 选择 Seedance 2.5）、豆包 Pro；官方口径（S7）另含扣子、小云雀上线，企业侧经火山引擎/BytePlus ModelArk 开放 API。

---

## 功能全清单（共 49 项，F01–F49）

### A. 输入与生成模式（F01–F08）

| 编号 | 功能项 | 支持 | 规格/说明 | 官方依据 |
|---|---|---|---|---|
| F01 | 文生视频 T2V | 是 | 纯文本提示词生成；发布稿全部示例均含 T2V 用法 | S1 原文示例标注 "T2V prompt"；S3/S4 均列 text-to-video |
| F02 | 图生视频 I2V | 是 | 单图作为画面起点驱动生成 | S1（2.0 架构延续，含图输入）；S3 明列 "Seedance image to video" |
| F03 | 首尾帧生成 | 是（API 口径） | content 中以 role=first_frame / last_frame 传入首帧与尾帧图，中间运动由模型补全；该模式画幅自动跟随源图（adaptive） | B 级：ModelArk 文档转录（fal、Civitai、Kinovi、PoYo 多家一致）；发布稿未单独点名此项 |
| F04 | 参考生视频 R2V | 是 | 以参考素材（图/视频/音频）+ 文本指令生成，素材在提示词中以 @Image N / @Video N / @Audio N 引用 | S1 全文核心能力，示例提示词大量使用 @Image 1…@Video 1 语法 |
| F05 | 纯音频参考生成 | 是（2.5 新增） | 仅给提示词+音频参考即可生成，不要求同时给图或视频参考 | B 级转录多家一致标注为 2.5 相对 2.0 的新增项；S1 确认音频可作参考输入 |
| F06 | 脚本/故事板类参考输入 | 是（平台口径） | 文本脚本、分镜描述、风格指南可与媒体素材一起作为参考输入 | S3 原文："Combine text prompts, scripts, reference photos, videos, music, style guides"；S4 同列 scripts、storyboards |
| F07 | 白模/粘土渲染参考（clay render） | 是 | 用无纹理 3D 白模锁定空间结构、人物姿势、运动路径、机位角度，模型据此生成并按白模空间信息生成符合物理的光影（光源方向、色温、强度、投影） | S1 专段原文 "clay render referencing"；S7 中文口径「白模参考」；S4 称 white-model (clay render) assets |
| F08 | 绿幕素材参考 | 是 | 绿幕拍摄素材可作参考输入，模型理解主体与背景分离关系 | S1 编辑章节绿幕编辑示例；S3 "Use green screen film or white model references"；S7「绿幕参考」 |

### B. 叙事与运镜（F09–F13）

| 编号 | 功能项 | 支持 | 规格/说明 | 官方依据 |
|---|---|---|---|---|
| F09 | 单次生成内多镜头叙事 | 是 | 30 秒内组织多个逻辑关联镜头，按铺垫、推进、转折、收尾展开，而非单一时刻的延长 | S1 原文："organize multiple logically connected shots so that a story unfolds through setup, development, turning points, and resolution" |
| F10 | 时间戳分段提示控制 | 是 | 提示词中按时间段（如 0–5s / 6–10s / 11–20s）分别指定叙事、机位、动作、节奏 | S1 原文："use prompts to control the narrative, camera perspective, movement, and overall rhythm for a specific time frame"，且官方示例提示词即按时间段书写 |
| F11 | 运镜语言控制 | 是 | 自然语言运镜：推近、拉远、环绕、跟踪、手持、FPV 穿越、俯冲、whip pan 等；运镜间过渡更平滑 | S1 多个官方示例提示词（push in / pulls back / arcs around / whip-pans / top-down / handheld 均为原文用词） |
| F12 | 转场与场景切换连贯性 | 是 | 长视频中镜头转场、场景切换的连贯性为本代主打升级项 | S1 原文："improves shot transitions and scene changes for stronger continuity in longer videos" |
| F13 | 一镜到底长镜头 | 是 | 单次连续镜头（one-take）为产品定位核心，官方示例含舞台表演一镜到底全程跟拍 | S1 标题即 "One-take Creation"，正文多个 one-take 示例 |

### C. 一致性与参考容量（F14–F21）

| 编号 | 功能项 | 支持 | 规格/说明 | 官方依据 |
|---|---|---|---|---|
| F14 | 主体/角色外观一致性 | 是 | 主体在多次切镜、时空变化中保持稳定 | S1 原文："The main subject remains stable across multiple cuts" |
| F15 | 多角色同时保持 | 是 | 多人物同框/群像叙事时，保持每个角色的外观与声音，各主体特征不串扰 | S1 原文："preserve the appearances and voices of multiple characters while keeping each subject's characteristics stable" |
| F16 | 延长与长视频一致性 | 是 | 延长过程中保持主人公、环境与叙事节奏一致 | S1 原文："maintains the consistency of main characters, environments, and narrative pacing" |
| F17 | 参考元素分解理解 | 是 | 模型分别理解并按指令取用素材中的构图、场景、风格、角色、道具、运镜、动作、音频元素 | S1 原文："comprehensively understands elements such as visual composition, scenes, styles, characters, and props across all materials" |
| F18 | 参考图片上限 | 是 | 单次最多 **30 张**图片 | S1 原文："up to 30 images" |
| F19 | 参考视频上限 | 是 | 单次最多 **10 段**视频；参考视频总时长上限 30 秒（总时长为 B 级转录） | S1 原文："10 video clips"；总时长 ≤30s 为 B 级 |
| F20 | 参考音频上限 | 是 | 单次最多 **10 段**音频；参考音频总时长上限 30 秒（总时长为 B 级转录） | S1 原文："10 audio clips"；总时长 ≤30s 为 B 级 |
| F21 | 参考素材总数上限 | 是 | 图+视频+音频合计最多 **50 个** | S1（30+10+10）；S3/S4 原文 "up to 50 multimodal references/inputs" |

### D. 编辑与延长（F22–F28）

| 编号 | 功能项 | 支持 | 规格/说明 | 官方依据 |
|---|---|---|---|---|
| F22 | 多轮延长 | 是 | 在已有生成结果后顺接续拍后续镜头，多轮后可达数分钟内容；产品页口径为「可延长两次」 | S1 原文 "multiple rounds of extension"、"multi-minute content"；S2 原文 "with the option to extend twice"（两处官方表述并存，见口径冲突 2） |
| F23 | 平台长视频模式 | 是（平台 beta） | Dreamina/CapCut 长视频模式上限 **180 秒**，保持人物、场景、光影、音频一致 | S3 原文 "extend them to 180 seconds with the beta long-video mode"；S4 同 |
| F24 | 时间戳级局部编辑 | 是 | 生成后针对特定时间片段内的人物、动作、剧情元素做定向修改，编辑前后保持连贯与真实 | S1 原文："timestamp-level control for targeted editing"、"targeted modifications to characters, actions, or plot elements within specific clips" |
| F25 | 区域/元素局部编辑 | 是 | 只改局部：换背景、换商品、换人物等，其余画面（光影、构图、运动、音频、时间轴）保持不变；平台称 Smart Edit / Intelligent Edit Mode | S1 编辑章节；S3 原文 "Edit specific video regions without regeneration"；S4 "Intelligent Edit Mode to adjust specific regions or timestamps"；S7「视频局部编辑……对背景、商品、人物等局部元素进行精准修改」 |
| F26 | 绿幕编辑 | 是 | 替换绿幕背景讲全新故事，主体保持不变，且主体对新环境的物理响应（衣物飘动方向、头发状态、步态节奏、光影互动）一并重渲染 | S1 原文专段（含物理响应细节） |
| F27 | 镜头视角/运镜编辑 | 是 | 只改已有视频的运镜/视角，人物、动作、风格不变（官方示例为对一段视频重做 15 秒分段运镜计划） | S1 原文 "camera perspective editing"，附完整示例提示词 "Edit @Video 1. Keep the characters, actions, and visual style unchanged. Adjust only the camera movement…" |
| F28 | 参考式编辑 | 是 | 以参考素材为依据对已有视频做编辑 | S1 原文 "reference-based editing" 列为进阶编辑能力之一 |

### E. 音频（F29–F34）

| 编号 | 功能项 | 支持 | 规格/说明 | 官方依据 |
|---|---|---|---|---|
| F29 | 原生音视频联合生成 | 是 | 统一多模态音视频联合生成架构：对白、音效、音乐与画面在同一次生成中产出并保持同步 | S1 原文架构表述 "unified multimodal audio-video joint-generation architecture"、"the audio and visuals remain in sync"；S4 "native audio-video joint generation model" |
| F30 | 对口型/唇形同步 | 是 | 说话与演唱的唇形同步（含官方示例中歌手演唱、多人对唱场景） | S1 示例（歌手登台演唱、R2V 示例 "All subjects lip-sync while singing"，见 S3 示例区）；S4 原文 "lip-sync direction" |
| F31 | 立体声音频 | 是（平台口径） | 同步立体声（synchronized stereo audio），含环境声、音效、节奏对齐的音乐线索 | S4 原文（两处）；模型层发布稿只表述为音视频同步，未提声道数 |
| F32 | 音频参考驱动 | 是 | 参考音频可锚定节奏、音效、发声内容与音色（与 F05、F20 配合） | S1（音频为一等参考模态）；B 级转录：音频参考用于 pacing、beat matching、lip sync |
| F33 | 多语言生成 | 是 | 原生支持 **11 种语言**：中文、英文、西班牙语、印度尼西亚语、马来语、泰语、阿拉伯语、葡萄牙语、越南语、日语、韩语（含多语言对白生成） | S3、S4 原文完整列出 11 种语言；S7 中文口径「原生支持 10 余种语言」 |
| F34 | 音频生成开关 | 是（API 口径） | API 参数 generate_audio，可关闭以输出无声视频 | B 级：ModelArk 参数转录多家一致 |

### F. 输出规格（F35–F42）

| 编号 | 功能项 | 支持 | 规格/说明 | 官方依据 |
|---|---|---|---|---|
| F35 | 单次时长 | 是 | **4–30 秒**，整数秒可选（2.0 为 15 秒，本代翻倍） | S1 原文 "30-second audio-video clips in a single pass"、"extends single-pass video generation from 15 to 30 seconds"；下限 4 秒为 B 级 API 转录，多家一致 |
| F36 | 时长自动决定 | 是（API 口径） | duration 设 -1 由模型按任务选时长（平台称 Smart Duration） | B 级转录多家一致 |
| F37 | 分辨率 | 分层口径 | 发布稿/产品页未给数字；平台（Dreamina/CapCut）称原生 **4K**；ModelArk API 为 **480p / 720p** 两档；1080p 见于部分渠道 API 与 Draft 成片阶段 | S3 标题与正文 "cinematic 4K videos"、"clean 4K video output"；S4 "native 4K resolution"；API 480p/720p 为 B 级转录多家一致；Draft 1080p 见 F41 |
| F38 | 帧率 | 24 fps（API 口径） | 模型输出固定 24 fps；平台另提供升帧至 60 FPS 的后期功能（非模型原生） | 24 fps 为 B 级转录（Civitai/Sogni 等多家一致）；60 FPS 升帧为 S3 套餐权益原文 "Make videos smoother (frame rate to up to 60 FPS)" |
| F39 | 画幅比 | 是 | 文生/参考模式可选 **21:9、16:9、4:3、1:1、3:4、9:16 共 6 种 + adaptive（自适应）**；首尾帧与编辑模式画幅跟随源素材 | B 级转录多家一致（fal 原文 "any of seven aspect ratios"）；S1 示例含 16:9 指定 |
| F40 | 输出格式 | MP4 | 官方 API 输出 MP4；MOV 说法仅见社区转录，未列入官方项（见隔离区） | B 级转录多家一致为 MP4 |
| F41 | Draft 样片模式 | 是（2026-09-22 上线） | 先出 480P 样片低成本试错，选定后凭样片 ID 二次推理出 **1080P 原生**成片，复用样片的提示词、参考素材、seed、画幅、时长；官方数据：5 秒 1080P 镜头抽卡 4 次省成本约 57%、速度提升近一倍，抽卡 20 次省约 77%；API 参数 draft=true，即梦端为「Seedance 2.5（样片模式）」 | S8（火山引擎官方公告口径，多家一致转述，含成本与提速数字） |
| F42 | 输出洁净度与水印控制 | 是 | 模型层主动抑制不受控的随机字幕与背景音乐；API 有 watermark 参数可控制水印 | S1 原文 "minimizes uncontrolled occurrences in subtitles and background music"；S4 "no random subtitles or unwanted background music"；watermark 参数为 B 级转录 |

### G. API 与工程能力（F43–F49）

| 编号 | 功能项 | 支持 | 规格/说明 | 官方依据 |
|---|---|---|---|---|
| F43 | 异步任务制 API | 是 | 提交任务 → 返回 task_id → 轮询查询或 callback_url 回调通知；状态含 queued / running / succeeded / failed / expired | B 级转录；回调与状态机另见火山方舟官方 API 参考（视频生成 API 通用口径） |
| F44 | 模型 ID 与端点 | 是 | 模型 ID：**dreamina-seedance-2-5-260628**；端点：POST https://ark.ap-southeast.bytepluses.com/api/v3/contents/generations/tasks（BytePlus 区域） | B 级转录多家一致 |
| F45 | content role 素材体系 | 是 | content 数组以 role 区分素材用途：reference_image / reference_video / reference_audio / first_frame / last_frame；素材可先上传注册后以 asset:// 引用 | B 级转录多家一致；火山方舟官方 API 参考确认 asset:// 素材 ID 形式 |
| F46 | 尾帧返回与链式续接 | 是 | 参数 return_last_frame=true 时返回尾帧图（PNG、与视频同尺寸、无水印），可作下一任务首帧实现连续生成 | 火山方舟官方 API 参考原文（视频生成 API 通用参数）；B 级转录亦一致 |
| F47 | seed 随机种子 | 存疑 | 多家 B 级转录称 API 含 seed 参数（Draft 模式官方口径明确提到复用 seed）；但亦有对接文档表格标注 2.5「不支持 seed」。官方原文未能直读，此项标存疑，对标时按「Draft 链路内 seed 有效、开放 API 是否可设未证实」处理 | S8（seed 复用为官方口径）；冲突见隔离区 |
| F48 | 计费口径 | 是 | 按视频 token 计费：token 量随输出时长、分辨率与参考视频时长增长；参考视频输入使单价下降。转录数字（BytePlus 定价页口径）：无视频输入约 $10.70 / 百万 token，有视频输入约 $6.40 / 百万 token；5 秒 16:9 示例约 $0.514（480p）/ $1.156（720p） | B 级转录（llm-stats 引 BytePlus 定价文档 S5 同级 pricing 页）；S3 平台口径另有 $0.01–0.05/sec 的 Dreamina 套餐价，非 API 价 |
| F49 | 生成速度 | 官方未公布 | 官方发布材料与产品页均未给出单条生成耗时数字；仅 Draft 模式给出相对提速（近一倍，见 F41）。社区实测为分钟级（见隔离区），不对标官方承诺 | S1–S4 通篇无耗时数字，此为核查结论本身 |

---

## 社区/渠道说法隔离区（非官方，不计入 49 项）

以下说法流传较广，但无字节官方原文支撑，或与官方口径冲突，自研对标时不得当作官方规格：

1. **「API 支持 1080p」**：fal、Runway 等渠道 API 自行提供 1080p 档（Runway 2026-08-15 新增、09-28 新增 Draft 升级工作流），属渠道侧能力，非 ModelArk 原生口径（原生为 480p/720p）。
2. **生成耗时约 150 秒**：来自第三方 API 商页面（VideoGenAPI 自述平均处理时长），Civitai 文档亦仅称「每条任务跑数分钟」。官方从未公布。
3. **MOV 输出（H.264 yuv444p / PCM）**：仅见第三方提示词指南站点转述，未见官方文档原文。
4. **真人/数字人专用型号 dreamina-seedance-2-5-hc**：仅见第三方中转 API 文档提及（与 2.0 的 hc 型号类推），官方发布材料未点名。
5. **seed 参数冲突**：Puter 开发者文档表格标注 Seedance 2.5「Seed: No」，与多家称有 seed 的转录冲突（见 F47）。
6. **「发布时承诺 4K 但未交付」**：多家指南称 FORCE 大会预告含原生 4K、实际 API 只到 720p。此说法的时间线可注意，但「预告原文」未能直读官方存档，标社区口径；可确认的事实只有：平台产品页现仍宣称 4K、API 现为 480p/720p。
7. **白模 Blender/Maya 插件**：见于 Dreamina 合作伙伴视频文案，官方发布稿只提 clay render 参考本身，未提插件。
8. **参考素材文件级限制**（图片 ≤30MB、视频 480p–4K 且单段 2–30s、音频 ≤15MB 等具体字节数）：见于第三方 API 游乐场页面（SeeGen 等），数值各家略有出入，未见官方原文。

## 附：与 Seedance 2.0 的代际差异（官方口径速览）

| 维度 | 2.0（官方） | 2.5（官方） |
|---|---|---|
| 单次时长 | 15 秒 | 30 秒 |
| 参考容量 | 9 图 + 3 视频 + 3 音频（S-2.0 发布稿原文） | 30 图 + 10 视频 + 10 音频（合计 50） |
| 纯音频参考 | 不支持（须搭配其他参考） | 支持（B 级） |
| 编辑 | 延长与编辑（基础） | 时间戳级局部编辑、绿幕编辑、视角编辑、参考式编辑 |
| 白模参考 | 未见官方提及 | 新增 clay render 参考 |

---

## 最难复刻的 3 项（评估结论）

1. **F29+F30+F32+F33 原生音视频联合生成与多语言对口型**：对白、音效、音乐与画面在同一次生成中同步产出，且 11 种语言的发声与唇形对齐。这不是「生成视频再配音」的拼接，而是音视频联合架构 + 海量音画对齐数据 + 多语言语音数据的三重门槛；任何单点技术突破都补不上数据与架构的联合缺口。
2. **F09+F14+F15+F17–F21 30 秒多镜头长叙事下的多主体一致性与 50 路参考理解**：在半分钟、多镜头切换、多角色同框的条件下，让每个主体的外观与声音不漂移、不串扰，还要能分别取用 50 个参考素材中各自的元素（构图取 A、角色取 B、运镜取 C）。这是长程时序一致性 + 大容量多模态条件控制的叠加难题，是扩散类架构最吃算力与数据规模的部分。
3. **F24–F28+F22/F41 时间戳级局部编辑、延长与样片复刻**：在「只改此处、其余一切（光影、运动、音频、节奏）不变」的约束下做定向修改，且延长与 Draft 成片要复用 seed 与全部条件重推理并保持结构一致。这要求模型具备可寻址的时间-空间可控性，而非整体重采样；对自研的软件原生路线而言，这一项反而提示了另一条路：当生成过程本身是可执行的时间轴程序时，局部编辑与参数复用是构造上自带的，但要达到其「任意内容可改」的泛化程度仍然最难。
