# E10: MiniMax H3 via stable-diffusion.cpp GGUF on GTX 980 Ti (sd.cpp-only path)

Why this is new (2026-11-11 intel): the "H3 runs on 6GB" community
claims were triaged this week. The ComfyUI route is DEAD on SM52
(evidence below) — but the sd.cpp route is NOT dead at build level,
because the ggml pinned by sd.cpp master still compiles Maxwell PTX.
H3 therefore enters the queue as E10, sd.cpp-only, AFTER E9, lowest
priority. It does not replace any existing candidate.

## What is verified vs what is only claimed

VERIFIED (read from source, 2026-11-11):
- sd.cpp CAN build for Maxwell: the ggml pinned by sd.cpp master
  (leejet/ggml@d803c238f67915fb825a9aa4df27b99356d51597,
  src/ggml-cuda/CMakeLists.txt) puts `50-virtual` in its default
  CUDA arch list for CUDA < 13, with the comment "50 == Maxwell,
  lowest CUDA 12 standard". PTX compute_50 JIT-compiles on sm_52.
  (Side effect: this also answers part of E7's engine question —
  sd.cpp's CUDA backend is not Maxwell-blocked at build time.
  Build with CUDA 12.x, never CUDA 13.)
- sd.cpp has a real H3 path with offload: docs/minimax_h3.md
  (official, read 2026-11-11) documents `-M vid_gen` with
  `--diffusion-model` / `--vae` / `--audio-vae` / `--llm`, plus
  `--offload-to-cpu` and `--max-vram` controlling weight residency,
  `--diffusion-fa` for flash attention, and an attention chunk
  budget flag `--model-args minimax_h3_attn_chunk_budget=2` (GiB,
  FP32 Q/K tensor per group). HyperFlow H3 Flash presets give
  4/6/8-step sampling (`hyperflow-h3-flash-4/6/8` sigmas).
- Official GGUF repo file list (leejet/MiniMax-H3-GGUF, HF API,
  2026-11-11): fl2va-pruned Q4_K_M 11.42 GB; ref2va-pruned Q2_K_M
  6.72 GB (smallest DiT file — note it is ref2va, not fl2va);
  encoder qwen3vl_32b_minimax_h3 Q2_K_M 13.10 GB / Q4_K_M 18.22 GB.
  The encoder MUST stay on CPU (sd.cpp doc passes it with
  --offload-to-cpu; Unsloth's card says the same).
- ComfyUI route is DEAD on SM52 (two independent gates):
  (a) The native INT8 ConvRot path runs its GEMMs through
  torch._int_mm (ComfyUI comfy/ops.py + comfy/model_management.py
  `supports_int8_compute` comment: "implements int8 weight-only
  quantized matmul via torch._int_mm"; PyTorch Blas.cpp
  `_int_mm_out_cuda` calls `at::cuda::blas::int8_gemm`, a cuBLAS
  INT8 tensor-core GEMM). NVIDIA's own CUDA Programming Guide
  Table 36: Tensor Core INT8 input starts at compute capability
  7.5 (Turing). SM52 has no INT8 tensor cores — no kernel.
  (b) ComfyUI's default compute dtype for these models is BF16
  (`mixed_precision_ops` default `compute_dtype=torch.bfloat16`);
  BF16 compute needs sm_80+. The model code itself uses generic
  `optimized_attention` (SDPA fallback possible), so attention is
  NOT the gate — the GEMM dtype is.
- WanGP floor is Pascal, not Maxwell: official README (read
  2026-11-11) lists "use GTX 10XX, RTX 20XX, and newer cards";
  "Maxwell" appears nowhere in it; GTX 10xx install pins
  torch 2.7.1 + cu128. E8's positioning is unchanged (record first
  hard failure point only).

CLAIMED ONLY (do not treat as evidence):
- "H3 runs on 6GB": KingsClaw's own measured card is an RTX 5060 Ti
  16GB (Blackwell); the "6GB" video he cites is a face-swap
  workflow, not video generation, with no card model named; his
  6GB/8GB table rows are estimates, not measurements. The
  2026-11-08 forum post cites a Singularity INT8 build at 0.25MP,
  4–8 steps, 16–25 min for 5s, again with no card model.
  artificialguy's guide calls 6GB "Not practical" and notes even
  the smallest GGUF text encoder cannot load there.
- WanGP's author reports 5–6 GB for 15s at 480p (vdf.ai, checked
  2026-11-04) — on Pascal-or-newer cards, with 32GB+ system RAM.
  No Maxwell evidence anywhere: "Maxwell 仍是无人区"维持.

## Arithmetic (not a result)

- DiT file alone: fl2va-pruned Q4_K_M 11.42 GB, ref2va-pruned
  Q2_K_M 6.72 GB. Neither fits in 6GB VRAM whole — this test ONLY
  makes sense with `--offload-to-cpu` + `--max-vram` streaming
  weights from system RAM. That means 32GB+ system RAM is a
  precondition (the ComfyUI 8GB reports all stress 32GB RAM);
  record the machine's RAM first — under 32GB, expect swap
  thrash and stop, do not tune past it.
- Encoder (13–18 GB) is CPU-only by design; it costs RAM and
  disk, not VRAM. VAE is FP16 5.21 GB on disk; use `--vae-tiling`
  and `--temporal-tiling` if offered.
- Speed: even if it runs, expect tens of minutes per short clip
  (offload streaming over PCIe 3.0 + FP32-emulated FP16 compute on
  SM52). This test answers "does it run at all", not speed.

## Hard walls to record (this test exists to find them)

1. Build: sd.cpp must be built with CUDA 12.x (or Vulkan);
   CUDA 13 drops sm_50/sm_52 offline compilation entirely.
   If the build itself refuses sm_52, that IS the verdict.
2. ggml FP16 kernels on SM52: FP16 intrinsics need sm_53+;
   ggml falls back to FP32 paths on sm_50/52 — slow but should
   run. If a kernel hard-requires a newer arch, record the exact
   error; that kills the sd.cpp route too.
3. `--diffusion-fa` (flash attention) on SM52 is unverified —
   try the doc's example WITH it first (known-good path), then
   without it, and record which rung breaks (same ladder logic
   as E7).
4. License: MiniMax H3's community license excludes the US, EU,
   UK and South Korea. Personal use in China is unaffected, but
   flag it before any commercial use.

## Steps

1. Build sd.cpp from master with CUDA 12.x (or Vulkan first, as
   in E7). Record CUDA version, cmake arch flags used, and any
   sm_52 warnings at build time.
2. Download, in this order:
   - DiT: leejet/MiniMax-H3-GGUF,
     minimax_h3_fl2va_pruned-Q4_K_M.gguf (11.42 GB, plain T2V)
   - Text encoder: same repo,
     qwen3vl_32b_minimax_h3-Q2_K_M.gguf (13.10 GB, CPU-only)
   - VAEs: Comfy-Org/MiniMax-H3, vae/
     minimax_h3_video_vae_fp16.safetensors and
     minimax_h3_audio_vae_fp32.safetensors
   (Optional second config only if the first fails on VRAM, not
   on kernels: ref2va-pruned-Q2_K_M.gguf, 6.72 GB.)
3. Run the doc's own T2VA command, adapted to the 6GB budget
   (start SMALL — 512x480 or below, 22 frames ≈ 1s, NOT the
   doc's 864x480/56-frame example):

```
sd-cli.exe -M vid_gen --diffusion-model minimax_h3_fl2va_pruned-Q4_K_M.gguf \
  --vae minimax_h3_video_vae_fp16.safetensors \
  --audio-vae minimax_h3_audio_vae_fp32.safetensors \
  --llm qwen3vl_32b_minimax_h3-Q2_K_M.gguf \
  -p "a cat sits on a windowsill, turns its head" \
  --cfg-scale 1.0 -v -W 512 -H 480 --offload-to-cpu --max-vram 5 \
  --rng cpu --fps 24 --video-frames 22
```

   Confirm the `--max-vram` unit from `sd-cli --help` on the
   machine first (assumed GiB here). If `--max-vram` is rejected,
   drop it and rely on `--offload-to-cpu` alone, and say so.
4. Attention ladder (only if the baseline fails): rung 1 as above
   (with `--diffusion-fa`); rung 2 without `--diffusion-fa`;
   rung 3 with `--model-args minimax_h3_attn_chunk_budget=0.25`.
   Record which rung ran.
5. Report back: success/fail with exact error text, peak VRAM
   from nvidia-smi, wall time, system RAM size, output clip or
   one frame. OOM or a kernel error IS the result — do not tune
   past the first hard failure without recording it.

## Judgement line (same as all tests)

- Peak VRAM <= 5.5 GB and a real generated clip (video + audio
  counts extra, video alone still counts): PASS, goes to the next
  round (quality / character-lock check).
- OOM / kernel / dtype error at any step: FAIL as-tested, record
  the exact wall. A VRAM-capacity failure may retry with the
  ref2va Q2_K_M file; a kernel/dtype failure ends E10 — do not
  retry the same wall through ComfyUI (that route is already
  dead on SM52, see above).
