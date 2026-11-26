---
id: lugouqiao-retry-ask-watcher
title: 卢沟桥重跑提问守望（等EP3自然停顿）
enabled: true
owner: goal:lugouqiao-incident-test-film
mode: task
schedule:
  kind: interval
  timezone: Asia/Shanghai
  at: 2026-11-26T06:50:36
  every: 15m
delivery:
  - chat_id: 8514d6c9-8a3a-4c83-a609-b440133250a5
metadata:
  tags: [cron:automatic-interval-anchor]
  originating_chat_context_json: '{"chat_id":"8514d6c9-8a3a-4c83-a609-b440133250a5","origin_provider":"main","chat_kind":"direct","event_kind":"message","require_mention":false}'
  presentation_locale: en-US
---
你是卢沟桥测试片的传话守望者。任务：等狼人会话（chat_id b54986ae-5a55-4501-8bd2-a14e492581ac）那边出现自然停顿，再把下面这件事发给用户；绝不能在他正审片、等片、或生成进行中时打断他。

每轮检查：
1. 用 chat.read_messages 读狼人会话最近 5 个回合（可带 include_live_work=true 看是否有进行中的工作）。
2. 只有同时满足以下两条才算自然停顿：(a) 用户已经回过话，给出了对刚交付的第12场整场拼片的裁定（通过/驳回/修改意见均可），或对话已明显收束到等待下一步的状态；(b) 没有正在进行的生成或审片流程（没有刚交付还等他看的片、没有进行中的重拍）。
3. 不满足就什么都不发，等下一轮。

发到本会话（8514d6c9-8a3a-4c83-a609-b440133250a5）时，用 muse.create_options 生成两个可点选项，选项文字 exactly：「第一段现在原样重跑」「先不跑」，把返回的 embed_token 原样贴在消息末尾。消息正文如下（照实说，不得夸大）：

「卢沟桥30秒测试片有新情况——生成服务今晨证实恢复了。证据是今晨EP3那边第12场多段都是一次出片、没有再报503。昨天这边是全天503/502过载，第一段反复重试都没出片，停在了等你发话的状态。

三段提示词都还在 ~/workspace/lugouqiao_test/（s1_prompt.txt、s2_prompt.txt、s3_prompt.txt，2026-11-24 15:48存档未动），第一段是9:16竖屏、720×1280、10秒、24帧，超写实历史战争片实拍质感，三段链式：夜袭卢沟桥→桥面争夺→黎明守桥头。不改词，可以原样跑。

这次只问第一段要不要现在原样重跑；第一段过了再接后两段。实话说：服务恢复是凭今晨EP3出片的直接证据推的，卢沟桥段本身还没跑通过；万一重跑又遇503/502，就按老规矩原样挂重试，不改词。」

发完后立即用 cron.remove 删掉本任务（id: lugouqiao-retry-ask-watcher），不要重复发。

兜底：连续 12 轮（约3小时）都没等到自然停顿，就直接发上面这条消息（仍带两个选项），然后同样删掉本任务。
