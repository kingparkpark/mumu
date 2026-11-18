#!/usr/bin/env python3
"""Fish Audio TTS helper.

Usage:
  fish_tts.py --text "要合成的文本" --out out.mp3 [--model s2.1-pro-free]
              [--reference-id VOICE_ID] [--format mp3]

The API key is never read here: a surrogate credential for custom.fish-audio
is placed in the Authorization header and swapped for the real key on egress.
"""
import argparse
import json
import sys
import urllib.request

sys.path.insert(0, "/opt/muse/skills/custom-connector-setup/bin")
from dynamic_credentials import add_surrogate_to_request


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *args):
        raise RuntimeError("redirect refused, verify the endpoint")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--text", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--model", default="s2.1-pro-free")
    ap.add_argument("--reference-id", default=None)
    ap.add_argument("--format", default="mp3")
    args = ap.parse_args()

    body = {"text": args.text, "format": args.format, "latency": "normal"}
    if args.reference_id:
        body["reference_id"] = args.reference_id

    request = urllib.request.Request(
        "https://api.fish.audio/v1/tts",
        data=json.dumps(body, ensure_ascii=False).encode("utf-8"),
        method="POST",
    )
    request.add_header("Content-Type", "application/json")
    request.add_header("model", args.model)
    add_surrogate_to_request(request, "custom.fish-audio", allowed_hosts=["api.fish.audio"])

    try:
        with urllib.request.build_opener(NoRedirect()).open(request, timeout=120) as resp:
            data = resp.read()
            ctype = resp.headers.get("Content-Type", "")
    except urllib.error.HTTPError as e:
        detail = e.read().decode("utf-8", errors="replace")[:500]
        print(f"HTTP {e.code}: {detail}", file=sys.stderr)
        return 1

    if "audio" not in ctype and len(data) < 1000:
        print(f"unexpected response ({ctype}): {data[:300]!r}", file=sys.stderr)
        return 1

    with open(args.out, "wb") as f:
        f.write(data)
    print(json.dumps({"out": args.out, "bytes": len(data), "content_type": ctype}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
