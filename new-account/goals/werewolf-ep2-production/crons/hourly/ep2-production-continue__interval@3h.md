---
id: ep2-production-continue
title: EP2全篇续产（每3小时推进）
enabled: true
owner: goal:werewolf-ep2-production
mode: task
schedule:
  kind: interval
  timezone: Asia/Shanghai
  at: 2026-11-19T04:42:52
  every: 3h
timeout_secs: 7200
delivery:
  - chat_id: b54986ae-5a55-4501-8bd2-a14e492581ac
metadata:
  tags: [cron:automatic-interval-anchor]
  originating_chat_context_json: '{"chat_id":"b54986ae-5a55-4501-8bd2-a14e492581ac","origin_provider":"main","chat_kind":"direct","event_kind":"message","require_mention":false,"device_id":"98bd6369-4dba-44fc-b9f6-51473faab499"}'
  presentation_locale: zh-CN
---
继续制作 EP2《幽暗禁区》全篇（用户 2026-11-19 全权委托；2026-11-20 02:35 用户新口径，本版据此改写）。

【新口径·最高优先】用户剧本只是大纲、演绎脚本（~/workspace/user/files/1.txt）只是参考：处理不好的地方由你以导演身份补全改进，目标是带入感与自然写实。全篇按 30 秒一个单元推进（单元计划见 ~/workspace/ep2_full/UNIT_PLAN_v3.md，U1–U14），单元内为 10 秒链式段；其余时间把控自定。建造段必须详细展示过程，大型建造用延时摄影（固定广角一镜到底、只增不减、步骤链先行、部件吊入、脚手架随建随撤、通电收尾、无对白无烧字）。交付门槛：每段过全量审片（≥3fps 全长条＋动作窗 ≥8fps＋全分辨率细节帧查服装/道具/人数＋逐秒计数＋亮度对照暗状态图＋ASR 16kHz 核词），完全没问题才登记验收、才向用户交付；带 major 的段不许当成品发。接缝按 ~/workspace/user/files/upload.md《衔接手法执行版》验收：写 [0] 前先做末三帧差异表（稳定项锁死、慢变项只写趋势、快变项只写上限），首帧=上段真实末帧，过渡只许视角切换或遮挡，验收逐项报漂移幅度与方向，禁用「基本一致」。

【开工必读】~/workspace/ep2_full/UNIT_PLAN_v3.md（单元计划＋统一地点设计，推进顺序以它为准）、~/workspace/ep2_full/PRODUCTION_STATE.json（验收记录，单一事实源；其中 unit_plan_v3 字段标当前单元进度）、~/workspace/user/files/skill.md（制作法标准）、~/workspace/ep2_full/EP2制作诀窍_原账号交接.md。整合使用用户 2026-11-20 交付的学习材料：镜头语言（~/workspace/user/files/GPT.md：意图先行、恐怖靠信息扣留与静止中的第一次动、强手法一单元≤2 处、动作戏先立地理）、表演系统（~/workspace/custom-skills/local-acting-video-character/：目标是动词、反应错峰、眼神细节、呈现状态而非过渡）、seedance-2.0 包（~/workspace/custom-skills/seedance-20/：序列状态与衔接交接）、导演 skill（~/workspace/custom-skills/cinematic-ai-video-director/）。旧队列 production_queue 与 REVISION_ORDER_v2 只作历史参考，不再据此推进；旧验收段复用前必须逐段比对新地理（统一地点：一栋废弃居民楼——侧巷→生锈铁门→门厅右侧楼梯→二楼一点透视走廊）与新造型（狼人红色三角巾、无花纹、整块布巾尖角垂胸），不合即重拍。

【冻结机制（直接执行，不许另开实验）】①暗场段喂「暗状态图」作曝光权威；②命名站位锁（尖兵/二号/三号/狼人固定位置与扇区，计数锁三处重复，单轮只加一项站位信息）；③开火纪律：潜入/撤退段明写全程零开火、手指离开扳机；战斗段开火绑触发瞬间、全场只一轮齐射、停火不补枪；④丧尸防显形：黑暗段与爆冲段拆开拍，黑暗段全段零丧尸身体，爆冲段第一可见状态即扑进光圈的动作状态、不演从深处走来；门洞写明没有纵深、不是房间、没有后墙；⑤触手用 tentacle_anchor.png＋状态链（缠绕完成态直接出现→瞬间拽离地面）；⑥机位优先架设固定机位；同轴线连续段不许中途换角度；⑦台词在声音锁明写只说一遍，台词段节拍压到最少（台词会被模型前拉 2–5 秒，必要时台词单独拆段）；⑧狼人拟人形态防侵蚀：宽景多人帧里狼人占画面必须够大、单段暴露别拖长，狼人不踏楼梯（上楼跨接缝省略或由队员完成）；⑨图压文字：造型以锚图为准（wolf_tri_sheet.webp 红色三角巾定版）。ASR 用 ~/workspace/ep2_full/asr_venv + asr_en.py（先转 16kHz），近音盲区标注待用户耳判；ASR 在无声段的整句幻听标注疑似误报。

【生产纪律】串行生成，一段验完再下一段；喂图 ≤3 张且注明以谁为准；链式喂上一段真实末帧；产物先验明是真视频（大小＋ffprobe）；不过的段一次只改一个变量、同毛病连出两版换机制、不许原样抽第三次、失败段永不进正片；验收过才登记进 PRODUCTION_STATE.json 并更新 current_unit。本轮最多生成 6 条视频。缺锚先补锚：lab_night.png（U6 前）、site_anchor.png（U7 前）、rider_poncho.png（U11 前，脏黄连帽雨衣＋黄头盔）。

【每轮结束】把进度（完成哪些段、卡在哪、下一步）简报回本旁聊，并更新 PRODUCTION_STATE.json 与当日日志 ~/memory/YYYY-MM-DD.md；教训追加到 ~/workspace/custom-skills/video-production-standard/LESSONS.md。

【收官】U1–U14 全部单元验收完成 → 按单元顺序组装全片（720×1280 lanczos、24fps、setsar 1、hqdn3d=2:1.5:3:2.2、48kHz 立体声、−16 LUFS、CRF 18、不插帧），交付到本旁聊，然后用 cron.remove 删除本任务 ep2-production-continue 并说明全片已完成。若生成服务报错或额度异常，停下如实报告，不许拼未验收的段充数。
