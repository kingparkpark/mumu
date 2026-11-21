# Generation iteration escalation

## Count content failures apart from service failures

- Treat a playable video with wrong content as a content failure when the costume, action, timing, dialogue, or a required beat is wrong.

- Treat a service error, a timeout, or an error file as a service failure and keep it under the video generation retry skill instead of counting it here.

- Count consecutive content failures per segment and reset the count only when a version passes or when you change the approach as this skill defines it.

- Log each failed version with its number, the exact failure, and the approach you used so the count stays visible across rounds.

- Treat this skill as counting content failures only, and leave service failures and the keep trying stopping rule to the video generation retry skill.

## Change the approach after three failures

- Stop re-prompting the same wording after three consecutive content failures on one segment.

- Keep the original prompt, references, format, duration, and locked lines unchanged across retries unless the user approves a change.

- Change exactly one approach variable for the next version and name it in the log before you generate.

- Choose an approach change that leaves the locked prompt and references unchanged, or get user approval first when the change needs different locked inputs.

- Split a multi stage segment into chained small segments only when the user approves that change.

- Change the first frame only when the user approves it, and feed a dark frame for a dark opening with the team out of frame.

- Feed a dedicated reference image only when the user approves it, and feed each character its own sheet instead of one shared image.

- Re-block positions, camera, or staging only within the locked prompt and references, or get user approval first when re-blocking needs a different prompt or reference.

- Do not run the same prompt wording a fourth time for the same failure unless the user approved the approach change behind it.

## Escalate the cost after five failures

- Stop generating the segment after five consecutive content failures and report to the user before you spend more versions.

- Yield this stop to an explicit user instruction to keep trying until success, and when that instruction stands, keep trying under it and report the cost at five failures instead of stopping.

- Report in plain language the seconds and the scene, the versions spent, what failed in each one, which approaches you already tried, and the decision you need.

- Name the options for the user such as accepting a compromise, changing the beat, waiting, or approving a different approach.

- Keep unblocked segments moving while the failed segment waits for a decision.

- Never advance a downstream segment that needs the failed segment tail frame, and say plainly that the downstream work is blocked on it.

## Available connectors

- Use `muse.connector_search` to find other connectors and `muse.skill_search` to find related skills.

- If nothing here fits, look on the web for a maintained API or MCP server and set it up with [Custom Connectors and MCPs](/opt/muse/skills/custom-connector-setup/SKILL.md), or build a custom connector.

## Alternatives for better results

- Generate three parallel variants of a segment in one round when the user approved parallel variants, so one round tests three approaches instead of one.

- Ask the user to pick the best of the parallel variants before you generate the next segment, so a pick carries a real tail frame forward.

- Rebuild the first frame from the previous accepted tail frame when a segment must chain, instead of describing the chain in words alone.
