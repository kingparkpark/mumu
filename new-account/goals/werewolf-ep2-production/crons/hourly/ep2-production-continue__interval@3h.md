---
id: ep2-production-continue
title: EP2全篇续产（每3小时推进）
enabled: false
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
继续制作 EP2《幽暗禁区》全篇（用户 2026-11-19 03:15 全权委托）。步骤：1) 读 ~/workspace/ep2_full/DIRECTOR_REVISION_AND_PLAN.md（导演修订+分段表+验收清单v2）、~/workspace/ep2_full/PRODUCTION_STATE.json（已验收段与下一段）、~/workspace/ep2_full/EP2制作诀窍_原账号交接.md（打法九条）。2) 从 next_segment 开始串行生产：每段先按分段表备齐锚图（缺锚先生成图片），提示词存 ~/workspace/ep2_full/user_fmt_v1/ 对应 txt，喂图≤3张且注明以谁为准，链式喂上一段真实末帧；生成后 ffprobe 验真，抽帧拼图按验收清单v2逐项对照提示词原文验收（含环境同一性、道具状态过程、粒子物理三项新规）；不过的段按重抽纪律修（一段只改一变量、同毛病两版换机制），验收过的段才登记进 PRODUCTION_STATE.json。本轮最多生成 6 条视频。3) 每轮结束把进度（完成哪些段、卡在哪、下一步）简报回本旁聊，并更新 PRODUCTION_STATE.json 与当日日志。4) 当分段表全部段验收完成：按顺序组装全片（只拼接+响度归一 -16 LUFS），交付到本旁聊，然后用 cron.remove 删除本任务 ep2-production-continue 并说明全片已完成。若生成服务报错或额度异常，停下并如实报告，不许拼未验收的段充数。
