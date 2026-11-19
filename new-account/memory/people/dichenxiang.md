---
display_name: "dichenxiang"
summary: "GitHub作者，muse-video-prompt技能包的作者；用户2026-11-11令学其方法，三条接缝与提示词规则已进EP1锁定执行标准。"
rank: 16
updated: "2026-11-18"
---

# dichenxiang

## Facts
- GitHub用户 dichenxiang，muse-video-prompt 仓库（github.com/dichenxiang/muse-video-prompt）的作者。(memory/2026-11-11.md#L763)
- 2026-11-11，用户令学习该仓库；已克隆并装入 ~/workspace/custom-skills/muse-video-prompt/（SKILL.md＋references＋scripts 共26个文件，含 continuity_frames.py、validate_storyboard.py、analyze_video.py）。(memory/2026-11-11.md#L763)
- 其方法与我方实测同向且更成体系，用户方后续视频执行采纳三条：一、连续镜用真实末帧作下一镜首帧参考，并抽末三帧做差异表——只锁稳定项、慢变项写趋势、快变项只写上限，不可判定不进锁单，再压成一句「接缝锚点」写进下一镜提示词开头；二、提示词结构按「最高优先级不变量→概览→分项」排，最关键约束在开头、对应时段、结尾以同一空间关系重申三遍；三、接缝验收要逐项报漂移与幅度，禁用「基本一致」了事。(MEMORY.md)
- 该 skill 默认单段上限10秒、长片拆自包含片段逐段交付，与我方管线实测吻合。(memory/2026-11-11.md)
- 2026-11-13，其方法被定为每拍提示词的固定格式并进入分工：每拍一条，顺序为衔接段（除第一拍外必备，放最开头）→锁定段原样前置→四种视角只选一套→按时间窗写动作→逐句标时间窗的台词→本拍特有反向约束；衔接手法为三层喂图（定妆图＋当拍场景/状态图＋上一拍真实末帧）、末三帧差异表压成一句接缝锚点、过渡只许视角切换或视野遮挡两种、每拍结尾留接点作下一拍首帧参考。(window conversation 2026-11-13T16:08:49Z, message:assistant-msg-1d626b1e-8d7a-4d2a-8e7c-ef11cbbe7a7e)
- 2026-11-13分工：用户（与 GPT）出定稿提示词＋参考图，助理只管生成、组装、验收、交付；接稿先核喂图齐全与接缝锚点在位，发现提示词内部矛盾只报用户、不擅自改。(window conversation 2026-11-13T16:08:29Z, message:15864182-da8f-44fd-9d74-2a0207b1ae40; message:assistant-msg-1d626b1e-8d7a-4d2a-8e7c-ef11cbbe7a7e)

## History
- 2026-11-11：用户指定学习其 muse-video-prompt 仓库并装入技能包；三条方法当日即进入EP1执行标准。
- 2026-11-13：用户令「给我你的提示词格式以及衔接手法，接下来你只配合提示词和参考图进行视频生成工作」；其方法当日被整理为每拍固定格式与衔接手法，作为用户/GPT出稿的对齐标准，助理只负责生成、组装、验收、交付。

## The relationship
- 用户与 dichenxiang 无直接往来证据；用户通过其公开发布的技能包学习方法，其接缝与提示词规则现已成为用户视频制作的执行标准。

## In common
- AI视频生成提示词方法：连续镜承接、末帧参考、接缝验收。

## Open threads

## Strengthening
