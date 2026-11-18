# 导演 DSL v0 规范（SNG 镜头程序）

导演层（语言模型）输出一份 JSON 程序，渲染器只负责求值。导演不许碰渲染参数，只许用下面的动作词汇编排表演。

## 程序结构

- shot_id: 字符串
- duration_s: 总时长（秒），表演在此时长内循环或停在末态
- actors: 资产引用列表（v0 只有一个主演 sdf_ink_puppy_v1）
- timeline: 动作数组，按 at 升序

## 动作词汇（v0，每轨同时只许一个动作占用）

位移轨（x 位置，取值约 -1.2..1.2，0 为画面中心）：
- enter: {at, dur, from_x, to_x, hop_amp, hop_hz} 跳着入场到位移终点
- hop_to: {at, dur, to_x, hops, hop_amp} 从当前位置跳到 to_x，分 hops 跳
  位移动作结束后，x 停在 to_x（状态保持，不回弹）

姿态轨（sq 压扁量，正=压扁，负=拉伸）：
- startle: {at, dur, jump, squash} 先蓄力压扁再弹起，弹起高度 jump
- settle: {at, dur, squash_rest} 缓缓落到 squash_rest 并保持（坐下/瘫倒/收尾）
  settle 结束后压扁量保持在 squash_rest，直到下一个姿态动作

形态轨（morph 0=小狗 1=魔王）：
- transform: {at, dur, to} 从当前形态值平滑变到 to，结束后保持

悬浮轨（yOff 附加高度偏移）：
- hover: {at, dur, amp, hz} 正弦浮动，结束归零

视线轨（look 偏移，约 -0.08..0.08）：
- look_around: {at, dur, range, speed} 眼睛与头一起左右张望，结束回正

不同轨的动作可以重叠（如落座同时张望）；同轨动作不许重叠。

## 约束（校验器强制）

- 所有 at+dur 不得超过 duration_s
- hop_amp 0..0.25，jump 0..0.45，squash -0.1..0.35，squash_rest -0.05..0.3
- transform 的 to 只能 0 或 1
- 时间轴必须覆盖到 duration_s 的 85% 以上（不许编排一半就没了）

## 表演语法（给导演的导演手册，一句话版）

喜剧节奏靠对比：动之后要有静，变身前要有蓄力，受惊前要有张望。每个大动作前留 0.3 秒以上的预备（压扁或停顿），大动作后留 0.8 秒以上的反应（落座、张望、泄气）。这不是渲染限制，是表演规律，写程序时当硬约束用。
