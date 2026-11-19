# Script-to-Shot Engine

Convert scripts and existing art assets into timestamped shot-by-shot video generation prompts optimized for Seedance and advanced AI video generation pipelines.

## When to Use

- When the user asks to turn a script, storyboard, or scene into shot-by-shot video generation prompts.
- When working with Seedance (即梦/火山视频生成模型) or similar video generation workflows.
- When splitting long sequences, fight choreography, or dialogue standoffs into multi-clip structured shot lists with continuous spatial and character state tracking.

## Core Workflow

1. **Analyze Input**: Receive the script, scene description, dialogue, and any available art assets or character/location references.
2. **Breakdown & Clip Management**:
   - Determine total duration and split into continuous 15-second or scene-appropriate video clips when exceeding single-generation limits.
   - For fight choreography / action sequences: split at completed action results, carrying character positions, weapon hands, and scene damage into the next clip.
   - For dialogue / standoff scenes: embed full script lines in individual shots without splitting dialogue across shots (5-8 shots per 15 seconds).
3. **Prompt Generation**:
   - Write prompts primarily in Chinese (optimized for Seedance) combined with precise bilingual cinematography terms (e.g., focal length, aperture, camera movement like push-in, pan, tracking).
   - Assign exact timestamps, camera angles, lighting, and spatial layout per shot.
4. **Output Format**: Present the resulting shot list and prompts clearly in structured markdown tables or blocks ready for direct pasting into video generation tools.

## Gotchas & Guidelines

- Maintain strict consistency across shots (character appearance, clothing, weapon orientation, spatial relative positions).
- Ensure total video length and individual shot duration are treated independently.
- Respect user overrides for shot counts or one-shot long takes.
## Available connectors

Use `muse.connector_search` to find the current connector docs before following
recovered instructions.
