# 980 Ti 视频生成研发路线图 v1（2026-10-22 汇总）

依据：research_A_lowvram_models.md / research_B_pipeline.md / research_C_compression.md（三份均为逐项核实、带证据分级）

## 硬约束（不接受更改）
- 目标硬件：GTX 980 Ti，6GB GDDR5，Maxwell SM52，无 Tensor Core，无 BF16/FP8/DP4A，FP16 仅存储无加速（原生 FP16 指令 Pascal 才有）。
- 软件栈窗口被钉死：PyTorch 2.4–2.6 + CUDA 12.4/12.6 legacy。PyTorch 2.8 起官方构建移除 Maxwell，CUDA 13 移除 CC 7.5 以下。跟最新栈走 = 判死。
- 本机（Muse 的 VM）无 GPU、7GB RAM、2 核：只能做读码、写原型、CPU 极小规模试验。真机显存/速度数据必须在用户的 980 Ti 上跑测试脚本取得——这是原型阶段的硬依赖。
- 蒸馏/训练是云端量级工作（约数十 A100 小时），980 Ti 只承担推理。

## 成功标准 v1（先达成这一档，再谈往上）
- 在 980 Ti 上本地跑通，峰值显存不超过 5.5GB
- 产出 9:16、480p 级、3–5 秒、固定角色卡通短镜头，角色身份不漂移
- 单条生成时间进入可用量级（目标分钟级，实测后定线）

## 路线排序

### 路线 1：现成小模型硬压（最先实测，实测决定去留）
- 候选 1a CogVideoX-2B（diffusers）：官方 FP16 起步 4GB、INT8 3.6GB（仅 A100/H100 测过），官方点名可在 GTX 1080 Ti 跑，推荐精度就是 FP16，无 BF16 移植问题。未知：SM52 上 offload 链是否跑通、PCIe 3.0 下速度惩罚（粗估数十分钟到数小时级，可能因此判死）。
- 候选 1b AnimateDiff（SD1.5 版）：SD1.5 UNet 0.86B + 运动模块 453M + CLIP ViT-L，FP16 原生、无 FlashAttention 硬依赖，整个栈是 Maxwell 时代的。512 方图 16 帧推算 5–7GB，必须实测证实/证伪。画质是 2023 年水平。
- 候选 1c LTX-2B distilled：E5 读码裁决已出（research_E5_ltx_verdict.md）——官方三条现成路径在 980 Ti 上原样不可跑，C 路 3.9–5.1GB 的账有三处硬伤（漏算 T5-XXL 约 9.4GB、VAE FP32 权重 1.68GB、Q8 存储+FP32 计算在现成代码中不存在），「今天可验证」不成立。降级为后备路线 P4：FP16 DiT + FP32 VAE + T5 预计算剥离 + 分块解码，估 6–11 工程日到真机首片，且 FP16 溢出与 SM52 注意力后端是可能推翻整路的生死点。排序降至路线 1 末位。
- 紧随：Wan 2.1 1.3B（官方 8.19GB，差 2.19GB；GGUF + T5 放 CPU 理论可补，无 6GB/Maxwell 实测）。

### 路线 2：组件管线 B-1 传播式（证据最扎实，与路线 1 并行）
驱动视频（真人/手偶/灰模粗演，CPU 抽引导信号）→ SD1.5 + 角色 LoRA + LCM-LoRA 4 步出关键帧（T2I-Adapter 控制，额外显存仅约 0.15GB；同档 6GB 卡实测 SD1.5+ControlNet 峰值 5.3GB）→ EbSynth 纯 CPU 零显存把关键帧外观按运动传播到每帧 → RIFE ncnn-vulkan 插帧 12→24fps（官方推荐配置含 Maxwell + 6GB）→ RAFT 光流标记崩坏帧 + SD1.5 inpaint 小修 + ffmpeg deflicker。
- 对墨团团格外对口：无骨骼无拓扑，骨骼/关键点 warp 全失效，而墨迹纹理正是 PatchMatch 最擅长搬运的；身份来自锁定关键帧，零漂移，一致性可反超扩散视频。
- 瓶颈：运动源质量（管线不发明运动）> 形态突变处对应断裂（突变点双关键帧+分段传播解）> EbSynth CPU 耗时（5 秒镜头全管线估 0.5–1 小时，C 级估算待实测）。
- 注意：980 Ti 上 SD1.5 的 FP16 可能溢出黑图，必须备 FP32 回退并按 5–5.5GB 预算。

### 路线 3：窄域蒸馏学生（长期主线，配置 B/C）
杠杆叠加（已按重叠打折）：步数蒸馏 50→4 步去 CFG（前向 100→4）+ LTX 式高压缩 latent 几何（token 量约 1/7，注意力显存从 GB 级降到约 80MB）+ 学生剪枝 2B→0.6B 并删除文本编码器（模板提示词 embedding 预计算查表）+ TeaCache 类缓存 1.2–1.6 倍 + Token 合并 1.3–1.8 倍 + TAESD 式 TinyVAE 砍解码尖峰 + INT8/Q4 仅作存储压缩。
- 配置 B 外推：峰值 2.3–3.3GB，480p 5 秒约 30 秒–2 分钟/条（正负 3 倍误差，锚点法外推）。
- 配置 C：B + 320x576 低清生成 + 插帧 + CNN 超分，约 10–60 秒/条，仅卡通色块画面成立。
- SnapGen-V 已证明 0.6B 视频模型质量可不输 1.2–1.6B 模型——窄域小模型不是幻想，有先例。

## 已判死总清单（有证据，不再重试）
FP8 全部路径；BF16 原生权重直跑（LTX 全系、CogVideoX-5B/1.5、Mochi、Hunyuan 全系、Wan A14B）；FlashAttention 1/2/3 与 FlashMLA 现成内核；SageAttention/Triton 生态节点；DP4A INT8 加速（仅存储意义）；LTX-2/2.3/2.5 本体（文件 9.5–14GB 起）；Mochi 本体（约 60GB）；HunyuanVideo 13B 本体；Wan 2.2 TI2V-5B 直跑（24GB）；ToonCrafter（24GB）；SVD 用于本项目（非商业许可冲突）；DeepInfer 本体代码（SM100/Ascend 专用，其推测解码直译到扩散不存在，置信度调度的扩散对应物是 AdaDiff/TeaCache，已计入路线 3）；在 980 Ti 上做训练/蒸馏。

## 验证顺序（下一步就按这个跑）
- E1 环境与 FP16 真伪：在 980 Ti 上装钉死版软件栈，测 SD1.5 FP16 是否黑图、512x768/25 步真实秒数。
- E2 CogVideoX-2B：sequential offload 最小规格跑通与计时，超时即判死。
- E3 AnimateDiff：512x512x16 帧显存实测，超 5.5GB 即判死或降规格。
- E4 EbSynth：480p 单镜头传播耗时与质量（CPU 即可测，不依赖 GPU 到位）。
- E5 LTX-2B distilled：读码裁决 BF16 回退路径，再决定是否实测。
每项只认实测数据：过线进下一轮，不过线当场换下一候选，不恋战。
