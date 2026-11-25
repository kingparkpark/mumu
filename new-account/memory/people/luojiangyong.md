---
display_name: "LuoJiangYong"
summary: "GitHub作者，muse-video-skill前期策划引擎的作者；2026-11-18其编译提示词生成的30秒试验片用户评「算准确了不少」，策划层有用，但2026-11-19用户裁定撤销该skill、改用自备导演skill，隔离目录保留；2026-11-20用户令EP2只按三份指定文件执行，其借用亦暂时搁置、不再引用。"
rank: 21
updated: "2026-11-20"
---

# LuoJiangYong

## Facts
- GitHub用户 LuoJiangYong，muse-video-skill 仓库（https://github.com/LuoJiangYong/muse-video-skill）的作者。(message:6b0699b7-5873-4fd4-ac10-6735589cf0f8)
- 2026-11-18，用户发来该仓库链接，令「换这个试试」。(message:6b0699b7-5873-4fd4-ac10-6735589cf0f8; memory/2026-11-18.md#L537)
- muse-video-skill 是一套前期策划引擎，不是视频生成模型：六个角色（导演／编剧／摄影／美术／特效／声音）走 8+1 阶段 Default 管线，全部产出只进一份 Project State JSON，每阶段有脚本门禁校验，Phase 7.5 把策划编译成 Seedance 的六段式提示词（Subject→Action→Scene→Camera→Lighting→Style）；按其宪法明文不生成视频，生成是下游的事。(message:assistant-msg-d86d7f99-acab-43fa-ba55-e329eed28784; memory/2026-11-18.md)
- 隔离测试（记录存 ~/workspace/video_quality_lab/_test_muse-video-skill/INSTALL_LOG.md）：仅在该目录内 git clone --depth 1，commit e01a6cf04dbcd2b8adf18194c46a2cc55b522086，74M；无 pip 依赖，未改系统／PATH，未注册为全局技能（未复制进 ~/workspace/custom-skills、不进其他会话）。(memory/2026-11-18.md)
- 已按其 Default 管线为试验1同一题材（特种部队夜袭30秒：部署→破门→入室）走完 Phase 1–7.5：门禁 Phase 2–6 一次通过，Phase 7 被拦下一次（3 个分镜 panel 缺 Director 批准标记，补上才放行），门禁实测有效；Phase 7.5 编译出三镜六段式提示词，质量标记镜1、镜2 是 GOOD，镜3 是 DEGRADED（因含一句必须喊清楚的「不许动！」）。(message:assistant-msg-5a5c84bc-c70f-4a30-9258-9ed250a908c5; message:assistant-msg-5a5c84bc-c70f-4a30-9258-9ed250a908c5; memory/2026-11-18.md)
- 与 dichenxiang 的 muse-video-prompt 不是同一个项目。(memory/2026-11-18.md)
- 2026-11-18，用户确认「按编译提示词生成30秒」，助理按编译提示词生成 30.04 秒试验片，三镜各 10 秒、带音轨，只有拼接、没做其他后期。(message:876437f5-8907-418d-b413-7312e771a197; message:assistant-msg-92945aad-9598-40a5-bc88-ffb4599b433f)
- 该试验片逐帧验收：破门只抡一锤、破门锤守恒到段尾、殿后队员全程背对一次没回头、第3镜嫌疑人反应弧线完整、队员面罩头盔全程没掉；仍坏的：倒数三下没读出来、第3镜够枪一步被跳、桌上步枪超数、每镜内有一次机位漂移／推近。(message:assistant-msg-92945aad-9598-40a5-bc88-ffb4599b433f; message:assistant-msg-f57341b7-0408-4c33-a912-1141c525c8a2)
- 用户对该试验片的评价逐字：「算准确了不少」；助理裁定该 skill 策划层有用（产出的提示词是五版里动作信息最完整、最能执行的），但治不了生成端老病：数量守恒、节拍内子动作不许跳步、镜内机位漂移。(message:145a8e8a-668e-4a34-b9d2-327e430b8db7; message:assistant-msg-f57341b7-0408-4c33-a912-1141c525c8a2)
- 用户令保留隔离目录，隔离目录保留在试验区（75M），不注册成全局技能、不进其他会话；测试片存 ~/workspace/video_quality_lab/mvs_test_30s.mp4，策划包在隔离目录下 projects/night-raid/。(message:0e13862b-1197-4828-9f13-98f989811ff2; message:assistant-msg-d1663bc0-08d0-47ee-acd3-ca57e88e32d9; MEMORY.md)
- 用户令把两个试验结果推送给狼人异世界求生会话，助理已推送 muse-video-skill 的结论（门禁、六段式编译、三条硬规则、实测成绩、治不了的老病、可借鉴到狼人线的策划骨架、存档位置），结论已记入长期记忆、不再重复测试。(message:145a8e8a-668e-4a34-b9d2-327e430b8db7; message:assistant-msg-93b1df68-240a-4e99-9d81-606d1e63603a; message:assistant-msg-032a69c8-7fb0-426b-9349-725b4e61985a; MEMORY.md)
- 2026-11-18晚，用户令重新制作前30秒，助理套用其策划骨架（角色圣经先行、每段只装一个节拍、动作发力顺序写到身体部位级、情绪锚点词逐字保留、交付前过门禁式自查清单）重制，重制版待用户判词。(message:481d354f-3602-4f34-aa64-f873555570d1; message:assistant-msg-4448d5b0-8f5c-40f1-abb1-d7a559beb067; message:assistant-msg-e228dd42-40a3-477b-a4fd-7e8fd335e38f)
- 2026-11-18晚，用户对重制前30秒的评价是「总体还凑合」，但指出不少穿帮镜头：开门时小队应严阵以待，结果在那排队，狼人还看错方向有点发呆；队友被触手抓走的镜头也出现了穿帮镜头。用户令把该 skill 装上作为自查，要求懂得自查不对的地方，以代入感与真实感判断什么时候该做什么、不该做什么，剧本不足处可稍加修改再试。(message:82e1ac44-24b5-409f-b5f1-3ffceffec046)
- 2026-11-19 02:24，用户令把该 skill 装入 ~/workspace/custom-skills/muse-video-skill 作自查门禁，助理已安装并为 EP2 前30秒建 Project State 实跑门禁：Phase 2–6 一次通过，Phase 7 首跑被拦（3 个分镜 panel 缺导演批准标记，补上后通过）；按用户意见小改剧本三处（场1改扇形半包围严阵以待、场2开场承接戒备姿势结尾倒退后撤、场3装备先脱手落地人再被拖走），自查细查抓出场2多出一只丧尸与绿浆混红并废弃重跑，成片为 EP2 前30秒自查修正版。(message:assistant-msg-089931e9-f55e-47b0-a1cf-12c06d4cb12e; memory/2026-11-19.md; MEMORY.md)
- 2026-11-19 02:36，用户裁定「不行」，令撤销该 skill，改用用户自备的《通用电影级AI视频导演》（源文件 workspace/user/files/AI.txt，已装 ~/workspace/custom-skills/cinematic-ai-video-director/SKILL.md）。muse-video-skill 已移入回收站（trash_id 20261118-183641-ffb0c58f6ec240c8812aba75b5a8add1，2026-12-18 到期），不再作为自查门禁使用；试验区隔离目录副本仍在。(message:725c79ba-d168-47d8-b14f-24c86cbf798e; message:assistant-msg-26beb373-67c9-4d7e-916e-fbfed48a65f7; memory/2026-11-19.md; MEMORY.md)
- 按替代 skill 试跑 EP2 场1–3 的自查结论：新写法画面语言更顺，但硬锁明显变弱，场2、场3两版均验收不过未拼进成片，成片场2、场3仍用上一轮已验证的版本顶上。(message:assistant-msg-26beb373-67c9-4d7e-916e-fbfed48a65f7)
- 2026-11-20，用户令 EP2 生产只遵循三份指定文件（《狼人系列视频制作法》《衔接手法执行版》《EP2制作执行手册》），muse-video-skill 等其他学习材料暂时全部不参考、不引用，此前拿它们得出的结论也不再作数。(message:d59a351a-d80d-4fe3-aab7-c7491b7df23e; message:assistant-msg-f1972737-f9d8-4916-9881-66d09e7bd12c; MEMORY.md)

## History
- 2026-11-18：用户发链接令换测；当日已在隔离目录走完 Default 管线并编译出三镜提示词，停在用户确认门禁，下游 30 秒生成尚未执行。
- 2026-11-18晚：用户确认按编译提示词生成30秒，试验片生成完成（30.04 秒），用户评「算准确了不少」；用户令保留隔离目录并把结论推送给狼人异世界求生会话，助理已推送并记入长期记忆；当日又套用其策划骨架重制前30秒，当晚用户判「总体还凑合」，指出多处穿帮镜头，令把该 skill 装上作为自查、修改后重试。
- 2026-11-19 02:24：用户令正式装入自定义技能目录作自查门禁，助理实跑 EP2 Project State 门禁并交付自查修正版前30秒。
- 2026-11-19 02:36：用户裁定「不行」撤销该 skill，移入回收站（2026-12-18 到期），改用用户自备的 cinematic-ai-video-director；试验区隔离目录副本保留，策划层有用的判定不变。
- 2026-11-20：用户令 EP2 只按三份指定文件执行，muse-video-skill 明确列入暂时搁置、不再引用的材料，其策划骨架的借用也就此搁置，此前拿它得出的结论不再作数。

## The relationship
- 用户与 LuoJiangYong 无直接往来证据；用户通过其公开发布的 skill 试用前期策划方法，30 秒生成结果已裁定：策划层有用，隔离目录保留、不注册为全局技能；其策划骨架曾借用到狼人线。
- 该 skill 曾短暂装入自定义技能目录作 EP2 自查门禁，但 2026-11-19 02:36 已被用户撤销，不再是自查工具；2026-11-20 用户进一步令 EP2 只按三份指定文件执行，其策划骨架的借用也暂时搁置、不再引用。

## In common
- AI视频前期策划：角色圣经、每镜单一节拍、锚点词编译不丢失、Seedance 六段式提示词。

## Open threads
- [x] 待用户确认门禁：按编译提示词生成 30 秒试验片（2026-11-18）；用户已确认，试验片已生成，用户评「算准确了不少」。
- [x] 用 muse-video-skill 作自查，重审并修正重制前30秒的穿帮镜头（开门队形、狼人视线方向、触手拖人镜头），以代入感与真实感判断何时该做什么、不该做什么，剧本不足处可稍加修改后重试（2026-11-18晚，用户令）。已于 2026-11-19 02:24 安装并实跑门禁、交付自查修正版；同日 02:36 用户裁定撤销该 skill，改用自备导演 skill，该自查用法就此终止。

## Strengthening
