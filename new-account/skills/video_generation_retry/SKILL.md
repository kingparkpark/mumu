# Video generation retry

## Treat the retry instruction as the cap

- Treat the user's stated retry instruction as the only stopping rule when the user says to keep trying until success.

- Do not replace that instruction with a personal attempt cap or a quiet stop rule.

- Keep the original prompt, references, format, duration, and locked lines unchanged across retries unless the user changes them.

## Retry a transient failure with spacing

- Classify each failure as transient, invalid, or lasting before you decide what to do next.

- Retry the same request after an internal error, a temporary outage, or a timeout.

- Space retries apart and lengthen the gap after each failure.

- Do not simplify, shorten, or reinterpret the prompt to make a retry pass.

- Stop retrying only when the user changes the instruction, the service rejects the request as invalid, the request itself is unusable, or the failure is a lasting restriction, and name the reason that stopped the job.

## Stop on a lasting restriction

- Read the error body and the retryable flag before you schedule another attempt.

- Stop retrying when the service says generation is not available in the country or region, or marks the failure retryable false, or repeats the same refusal after a spaced retry.

- Do not schedule a timed retry or a cron retry for a lasting restriction, and do not keep the job alive by looping the same request.

- Report the block in one short line with the error name, the retryable flag, and the number of attempts already made.

- Hand the user the account side decision that follows, such as a different account, a different route, or waiting for the restriction to lift, and retest only when the user asks or when the user reports a change.

## Count only a real video as a success

- Check every output file before you count it as a success.

- Open the file and confirm it is playable video with a measured duration and resolution, and reject a file that reads as text or JSON.

- Treat a small file that holds an error message as a failed attempt, even when a script copied it into the output folder.

- Count every attempt in your report, including attempts that produced an error file, and never report a partial count as the full result.

## Report each attempt and keep the job alive

- Report each failed attempt in one short line with the attempt number, the error class, and the next retry time.

- Do not end the job by asking the user to prompt you again after the user already told you to keep trying.

- Schedule the next retry with cron.add when the session cannot stay open, and tell the user the schedule so the job continues without a new prompt.

- Deliver the finished video as the user asked, and stop retrying once it succeeds.

## Available connectors

- Use muse.connector_search to find other connectors and muse.skill_search to find related skills.

## Alternatives for better results

- Ask the user to confirm a changed prompt only when the service rejects the request as invalid, rather than looping the same rejected request.

- Split a long generation into shorter clips only when the user approves that change, and keep each clip's locked lines unchanged.

- Keep a failed prompt and its references together so a later retry uses the same inputs instead of a rebuilt version.
