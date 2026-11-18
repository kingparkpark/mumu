# E9: Wan2.2-TI2V-5B Turbo GGUF on GTX 980 Ti (new candidate, ComfyUI-GGUF path)

Why this is new (2026-10-28 intel): the Turbo GGUF repo for Wan2.2-TI2V-5B
is a 4-step, CFG-1 distilled model — step count is the biggest lever on a
slow card (4 steps vs Wan2.1's 20). DiT Q4_K_M is 3.44 GB on disk
(verified against the repo file list 2026-10-28). This does NOT replace E7;
it is the next queue item after E7, because its engine differs.

## What is verified vs what is only claimed

VERIFIED (repo file list, hum-ma/Wan2.2-TI2V-5B-Turbo-GGUF, 2026-10-28):
- Wan2_2-TI2V-5B-Turbo-Q4_K_M.gguf = 3.44 GB; Q3_K_M = 2.55 GB;
  Q2_K = 1.86 GB; Q8_0 = 5.4 GB. Converted from Kijai's FP16 Turbo
  checkpoint with city96 ComfyUI-GGUF tools.
- The repo contains NO text encoder and NO VAE. Any article claiming
  "three files totaling 6.1 GB on disk" for this pipeline is wrong on
  its face: encoder (city96 umt5-xxl-encoder-gguf) and VAE
  (QuantStack Wan2.2-TI2V-5B-GGUF/VAE) are separate downloads.
  Do NOT cite the 6.1 GB figure.

CLAIMED ONLY (do not treat as evidence):
- Repo README: "usable with an old 4GB GPU" — no GPU model, no VRAM
  log, no settings attached. [社区声称]
- README usage advice (via Civitai): 4 steps, CFG 1, Euler / SA_Solver /
  UniPC, simple/normal/beta scheduler, latent multiplier 0.8 against
  oversaturation, preferred sizes 1280x704 / 704x1280.
- A 2026-10-17 blog repeats the 6 GB claim but lists a BF16 UMT5
  encoder as part of the "6.1 GB" set, which is arithmetically
  impossible (UMT5-XXL BF16 alone is ~11 GB). Treat that blog as
  unreliable; use only the repo file list above.

## Arithmetic (not a result)

- GPU side if the encoder is forced to CPU/offload: DiT Q4_K_M 3.44 GB
  + Wan2.2 VAE + activations. The 5.5 GB line is plausible but TIGHT —
  much tighter than E7's Wan2.1 (DiT 0.816 GB). If Q4_K_M OOMs,
  drop to Q3_K_M (2.55 GB) before touching anything else.
- Encoder must NOT sit on GPU: UMT5-XXL Q4_K_M is ~3.66 GB (same
  figure as E7's companion encoder). GPU-resident encoder + DiT
  already exceeds the budget before activations.
- Speed lever: 4 steps is ~5x fewer denoising steps than E7's 20.
  If per-step cost is comparable, this is the fastest modern-DiT
  candidate in the queue — IF it runs at all.

## Hard walls to record (this test exists to find them)

1. ComfyUI-GGUF dequant kernels on SM52: zero verification anywhere.
   This is the same class of wall as E7's FA-on-Maxwell question.
2. fp8_matmul must stay OFF (Maxwell has no FP8 path; see research_F 3.3).
   Any guide telling you to turn it on for low VRAM does not apply here.
3. PyTorch stack for ComfyUI-GGUF on this card is capped at
   torch <= 2.14 + cu126 (corrected 2026-11-04: 2.8 removed Maxwell
   only from cu128 builds; cu126 builds run through 2.14, and 2.15
   drops cu126 wheels). E1–E3 stay pinned to the known-good
   torch 2.6.0 + cu126; for E9, only a demand for torch > 2.14 or
   a cu128 / CUDA 13 build is a hard wall — record it and stop.

## Steps

1. Install ComfyUI + ComfyUI-GGUF pinned to the torch <= 2.6 / cu126
   stack (see testkit README). Record the exact versions installed.
2. Download, in this order:
   - DiT: hum-ma/Wan2.2-TI2V-5B-Turbo-GGUF,
     Wan2_2-TI2V-5B-Turbo-Q4_K_M.gguf
   - Text encoder: city96/umt5-xxl-encoder-gguf, Q4_K_M variant
   - VAE: QuantStack/Wan2.2-TI2V-5B-GGUF, VAE folder file
3. Workflow: image-to-video or text-to-video, 832x480 (NOT the
   README's 1280x704 — start small), 4 steps, CFG 1, Euler, simple
   scheduler, latent multiplier 0.8, encoder offloaded to CPU,
   fp8_matmul OFF, VAE tiled if the node offers it.
4. Report back: success/fail with exact error text, peak VRAM from
   nvidia-smi, wall time, output clip or one frame. OOM or a kernel
   error IS the result — do not tune past the first hard failure
   without recording it.

## Judgement line (same as all tests)

- Peak VRAM <= 5.5 GB and a real generated clip: PASS, goes to the
  next round (quality / character-lock check).
- OOM / kernel / dtype error at any step: FAIL as-tested, record the
  exact wall; Q3_K_M retry only if the failure was VRAM capacity,
  not a kernel/dtype wall.
