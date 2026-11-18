# 980 Ti 真机测试包（E1–E3 / E7）

目的：用实测数据裁决候选路线。每个脚本都会打印峰值显存、耗时，并把结果图/视频存到当前目录。跑完把终端输出整段发回给 Muse 即可，不用自己分析。

## 最快方式：一键运行（Windows / Linux 通用）

系统里装好 Python 3.10 或 3.11 后，在本目录执行：

```
python run_all.py
```

它会自动建 venv、装钉死版本、按 E1 → E3 → E2 顺序全跑完，
全部输出存进 `testkit_results_<时间>.log`。把那个日志发回给 Muse 就行。
E2 单独就要 25–40 分钟；中途显存爆了也别停，爆也是数据，脚本会记录并继续。

E7（stable-diffusion.cpp + Wan2.1，独立路线）按 `e7_sdcpp_wan.md` 单独做。

E9（Wan2.2-TI2V-5B Turbo GGUF，ComfyUI-GGUF 路径）按 `e9_wan22_ti2v5b_gguf.md` 做，仅在 E7 有结论后跟进。

E10（MiniMax H3，stable-diffusion.cpp GGUF 路径，sd.cpp 专属）按 `e10_minimax_h3_sdcpp.md` 做，仅在 E9 有结论后跟进。注意：H3 的 ComfyUI 路线已在 SM52 上判死（INT8 GEMM 无核 + BF16 计算门），E10 只走 sd.cpp，不走 ComfyUI。

## 手动方式

### 环境（版本是钉死的，别升级）

- 显卡驱动：更新到最新版
- Python 3.10 或 3.11，新建虚拟环境
- 安装命令（Windows / Linux 通用）：

```
pip install torch==2.6.0 torchvision==0.21.0 --index-url https://download.pytorch.org/whl/cu126
pip install diffusers==0.33.1 transformers==4.49.0 accelerate==1.4.0 safetensors imageio imageio-ffmpeg psutil
```

为什么钉死：PyTorch 2.8 起是 cu128 构建移除了 Maxwell 架构支持，cu126 构建一直保留到 2.14；2.15 起不再提供 cu126 轮子（CUDA 13 轮子要求 Turing sm_75 及以上），故 Maxwell 上限修正为 torch ≤ 2.14 + cu126（2026-11-04 核实，见 hidden_files/intel_log.md）。本包仍钉 2.6.0 + cu126 作为已知可用组合，不擅自升级；E9 若需更新 torch，上限为 2.14 + cu126，cu128 / CUDA 13 即判墙。

## 运行顺序

1. `python e1_sd15_fp16.py` —— 先裁决 FP16 在这张卡上是否黑图、FP32 要多少显存和时间。这是所有路线的地基。
2. `python e3_animatediff.py` —— AnimateDiff（SD1.5 版）16 帧显存实测，线是 5.5GB。
3. `python e2_cogvideox2b.py` —— CogVideoX-2B 官方规格跑一遍，最慢，做好等很久的准备；中途显存爆了也把报错发回来，爆也是数据。
4. E4（EbSynth，纯 CPU、与显卡无关，任何电脑可跑）：按 `e4_ebsynth_test.md` 做，测传播耗时与崩坏帧位。
5. E7（stable-diffusion.cpp + Wan2.1-1.3B GGUF，绕开 PyTorch 的独立路线）：按 `e7_sdcpp_wan.md` 做，先跑仓库自带的 `commands/q4-optimized.sh` 已知好命令。E8（WanGP）仅在 E7 有结论后跟进。
6. E9（Wan2.2-TI2V-5B Turbo GGUF）仅在 E7 有结论后按 `e9_wan22_ti2v5b_gguf.md` 做；E10（MiniMax H3，sd.cpp 路径）仅在 E9 有结论后按 `e10_minimax_h3_sdcpp.md` 做。

## 判读标准（脚本会自动打印 PASS/FAIL）

- 峰值显存 ≤ 5.5GB：过线
- E1 FP16 输出图标准差过低（近全黑）：FP16 判死，后续全部走 FP32 预算
- 任何一步 OOM 或算子报错：原样记录，该候选按当前形态判死，换下一个
