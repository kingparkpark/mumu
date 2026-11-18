# Generated video delivery check

## Build the lock list first

- Copy every locked element from the request into a short list before you generate or check anything.

- List each character with costume, distinctive features, and scale relative to other characters and furniture.

- List each prop with its count, position, and any state change it must or must not undergo.

- List each contact point exactly, naming the body part, the target, and the final resting pose.

- List duration, aspect ratio, resolution, dialogue lines in order, and the required ending state.

- Treat a user supplied reference image as the source for appearance and do not substitute a similar look.

## Watch the whole film at full resolution

- Watch the finished film from start to end at full resolution before you deliver it.

- Step through the film at one frame per second and read each change in sequence, because a change happens between sampled frames and a frame sample certifies parts instead of the film.

- Never accept a film from thumbnail frames, because a 270 pixel wide thumbnail cannot tell a thin fire layer from a lava river, a kettle from a canteen, or a fire disc from a standing bonfire.

- Play the film through in real time and watch for flicker and boiling texture, because still frames cannot show a defect that only appears over time.

- Resample audio to 16kHz before you transcribe it, because the transcription tool only reads 16kHz input and a higher rate sounds slowed and transcribes as gibberish.

## Sample frames at decisive moments

- Measure duration, resolution, aspect ratio, and audible dialogue before you look at frames.

- Sample frames at the opening, at each dialogue line, at each contact moment, and at the final held pose.

- Sample at least one frame from every generated segment when a video was assembled from several clips.

- Treat a sampled frame as a supplement to the sequential watch and never as a replacement for it.

- Compare the same character across sampled frames and flag any costume piece that appears, disappears, or changes color.

- Compare the same prop across sampled frames and flag any count change that the script did not require.

- Check scale and grounding in each sampled frame and flag any character that floats, stretches, or changes size relative to furniture.

- Check the final frame against the required ending state and do not accept a different ending as close enough.

## Judge each lock before you deliver

- Pass the video only when every lock in your list matches in every sampled frame.

- Label a video as a failed preview when any lock fails and list each failure with its timestamp.

- Do not present a failed preview as finished and do not soften a failure into a minor difference.

- Regenerate the failing segment or the whole video when regeneration is available and the request still stands.

- Keep the original locked prompt and references unchanged for a regeneration unless the user changes them.

- Hand the user a corrected prompt for outside generation only when in session generation is unavailable and say plainly that the video itself is not delivered.

- Deliver only the directly generated video when the user asked for direct generation.

- Never replace a failed direct generation with a pixel rotation, a reoriented clip, a spliced audio track, or any other post processing that fakes a motion the model did not generate.

- Treat post processing as limited to denoise and loudness normalisation unless the user approved more, and regenerate instead when the model cannot do the requested motion.

- Label a post processed version as post processed before you deliver it and name exactly what was changed, instead of presenting it as a direct generation.

## Report the check with the video

- Deliver the video together with its measured duration and resolution.

- State the frame check result in one short line naming what passed or what failed.

- State that the film was watched from start to end at full resolution and played through in real time.

- Name any segment that could not be generated instead of letting a partial video stand for the whole request.

- Report audio volume or audibility when dialogue was required and do not claim spoken dialogue from subtitles alone.

- State whether the delivered video is a direct generation or a post processed version and name any post processing beyond denoise and loudness normalisation.

## Available connectors

- Use `muse.connector_search` to find other connectors and `muse.skill_search` to find related skills.

- If nothing here fits, look on the web for a maintained API or MCP server and set it up with [Custom Connectors and MCPs](/opt/muse/skills/custom-connector-setup/SKILL.md), or build a custom connector.

## Alternatives for better results

- Split a long video into shorter clips and check each clip before assembly when single generation cannot hold the full duration.

- Reuse the lock list for the next segment in the same project so later clips inherit the same costume, scale, and prop counts.

- Keep a failed frame beside its timestamp so a regeneration prompt can name the exact failure instead of repeating a general instruction.
