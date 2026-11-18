# Fish Audio

- `custom.fish-audio` connects Muse to the Fish Audio REST API at `https://api.fish.audio`. It authenticates with the registered `api_key` credential, placed as a bearer header, and calls only `api.fish.audio`.

- Helpers live in `~/workspace/custom-connectors/custom.fish-audio/bin/`. `fish_tts.py` synthesizes speech with `POST /v1/tts` and writes the audio bytes to a file.

## Connect

- The connection was registered with `credentials.request_api_access` and these details. Reuse them to reconnect:

```json
{
  "provider": "fish-audio",
  "auth_scheme": "api_key",
  "placement": "bearer_header",
  "api_hosts": ["api.fish.audio"]
}
```

- Before the first change in a conversation, prove access with a harmless read. No dedicated read endpoint is wrapped yet, so run a one word TTS call to a scratch file and confirm it returns audio bytes.

## Credentials

- The registered connection holds the credential. Helpers import `/opt/muse/skills/custom-connector-setup/bin/dynamic_credentials.py`, which returns an `hsurr:` surrogate and places it where the provider reads the key. Muse swaps in the real credential only on an approved request to a registered host.

- Never put a key, token, password or cookie in this doc, a helper, a command argument, an environment variable or a log. Never ask the user to paste one in chat.

- Keep redirects disabled on authenticated requests.

- On a 401 or 403, check the request first. Confirm that the helper attached the credential, that the host is registered and that the placement and scopes match.

- Only when a request that carried the credential is still rejected, call `credentials.request_api_access` with the details above and `"reconnect": true`.

## Synthesize speech

- Synthesize speech from text and write the audio to a file. Use it for Chinese dubbing lines that the video generation voice cannot pronounce reliably.

```text
python3 ~/workspace/custom-connectors/custom.fish-audio/bin/fish_tts.py --text "<line>" --out <file.mp3> [--model s2.1-pro-free] [--reference-id <voice id>] [--format mp3]
```

- `--text` is required and is spoken verbatim. `--model` defaults to `s2.1-pro-free`, the free developer tier model. Omit `--reference-id` to use the platform default voice, or pass a voice model ID from the user account to use that voice.

- The helper prints a JSON line with the output path, the byte count and the content type. A successful call returns `audio/mpeg` for mp3. Verified 2026-11-18 with the opening line of the wolf series, which returned 86516 bytes and 5.41 seconds of audio.

- The wolf series house voice is the user uploaded voice model `a2faf9c836934b7c8cf3507e35040b76`. Pass it as `--reference-id` for wolf lines. The user approved it on 2026-11-18 as close to the generated voice in earlier videos.

- Expression control on `s2.1-pro-free` uses square bracket tags in the text, verified 2026-11-18. Core tags such as `[panting][shouting]` and free form Chinese tags such as `[喘着粗气，嗓音收紧发哑，扯着嗓子急喊]` are treated as direction and are not spoken. Appended prose direction after the line is spoken aloud by this model, so never use that format with the free model.

## Recover from errors

- An HTTP error prints the status code and the first part of the response body to stderr. Read that body before retrying, because it names the failing field.

- After a failed or timed-out synthesis, check whether the output file exists and has audio bytes before trying again, because the first request may have completed.

## Limits

- The connector only wraps `POST /v1/tts`. Voice cloning uploads, voice model management and ASR are untested and not wrapped.

- The free tier credit balance and its monthly refresh are account facts shown on fish.audio. They were not verified through this connector.

## Related skills

- Use `muse.skill_search` to find other skills and `muse.connector_search` to find other connectors.
