# E7: stable-diffusion.cpp + Wan2.1-1.3B GGUF on GTX 980 Ti (new route, bypasses PyTorch)

Why this route: sd.cpp is a ggml engine - it does NOT depend on PyTorch, so the
torch-2.8-drops-Maxwell cliff does not exist here. CUDA arch can be pinned to 52
at build time, and there is a Vulkan backend that skips CUDA entirely (980 Ti
has Vulkan driver support). Every component size is known:
- DiT Q4 (calibrated): 0.816 GB (GPU)
- UMT5-XXL text encoder Q4: 3.655 GB (FORCE TO CPU)
- VAE: 0.254 GB (GPU)
GPU-side total ~1.1 GB + activations -> fits 6GB arithmetically.
Evidence so far only reaches Pascal; the 980 Ti would be the first Maxwell test.

## Steps

### 1. Clone and build (try Vulkan first)

```
git clone --recursive https://github.com/leejet/stable-diffusion.cpp
cd stable-diffusion.cpp && mkdir build && cd build
cmake .. -DSD_VULKAN=ON
cmake --build . --config Release -j
```

Fallback if Vulkan fails: `cmake .. -DCMAKE_CUDA_ARCHITECTURES=52 -DSD_CUDA=ON`

Build must be one that supports Wan 2.1, GGUF, full flash attention, direct VAE
convolutions, and PNG frame export. The upstream-tested engine SHA-256 is
`e6661c1908a586a1352a07f7c2ffe9516e7c6bf1927bd6c50e5bc63a4280be77`.

### 2. Download models (two repos - companion files moved on 2026-10-21)

The text encoder and VAE no longer live in the generator repo; they were moved
to `off-grid-ai/Video-Companions-GGUF`. Use the calibrated Q4 generator - it is
the upstream-recommended one. Commands copied from the upstream repo README
(verified 2026-10-22):

```
pip install huggingface_hub   # for the `hf` CLI
hf download off-grid-ai/Wan2.1-T2V-1.3B-GGUF Wan2.1-T2V-1.3B-calibrated-Q4_K_S.gguf --local-dir .
hf download off-grid-ai/Video-Companions-GGUF umt5-xxl-encoder-Q4_K_M.gguf wan_2.1_vae.safetensors --local-dir .
hf download off-grid-ai/Wan2.1-T2V-1.3B-GGUF --include 'commands/*' --local-dir .
```

### 3. Run the repo's own known-good command FIRST

The repo ships `commands/q4-optimized.sh` - this is the upstream-verified path
(calibrated Q4 + `--fa --vae-conv-direct --vae-tiling`). Read it first (it
contains the example prompt and settings), edit the prompt if you want, then:

```
bash commands/q4-optimized.sh
```

This writes an eight-second MP4 (832x480). Do NOT start with flash attention
disabled - the known-good path runs WITH full `--fa`; that is the baseline.

Only if the known-good run fails, retry with the attention ladder and record
which rung breaks - FA-on-Maxwell is unverified and IS one of the things E7
exists to answer:
- rung 1 (baseline): as shipped, `--fa --vae-conv-direct --vae-tiling`
- rung 2: `--diffusion-fa --vae-tiling` (plain-Q4/Q8 recipe)
- rung 3: `--flash-attn off` (no FA at all)

### 4. Report back

Success/fail (exact error text), which attention rung ran, peak VRAM from
`nvidia-smi`, total wall time, and the output MP4 or one frame from it.
Expected speed: tens of minutes per clip on a 980 Ti (Blackwell did 104s for
the Q4-Optimized run; FP32 compute gap is >10x). This test answers "does it run
at all", not speed.

# E8 (follow-up, only if E7 shows promise or fails informatively): WanGP
WanGP (deepbeepmeep) ships a productized "6GB + GTX 10-series" profile.
Its floor is Pascal. On Maxwell, run its lowest profile and capture the FIRST
hard failure point (backend, dtype, or VRAM) - that failure point is the data
we want; do not spend time tuning past it.
