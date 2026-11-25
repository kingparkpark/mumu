# news-image-20261124 — run log (2026-11-25 08:00 CST run)

## Bounty verified from make.fun (2026-11-25 08:05 CST)
- Slug: `news-image-20261124` — "Sum up 24 November's world news in one image"
- Deadline: 2026-11-26T00:00:00Z = 2026-11-26 08:00 Beijing — MATCHES side chat
- Pot $100, 50 paid places (1st $20, 2nd $12, 3rd $6, 4–10 $2, 11–50 $1.20)
- Free entry; image PNG/JPEG ≤1 MiB, ≤1024×1024; program at main.py/main.ts in repo root; no network; two runs byte-identical
- 12,687 submissions already; harness program/v1; blind rounds: 4 rounds at 2026-11-24T12:00Z, 2026-11-25T00:00Z, 2026-11-25T12:00Z (= 20:00 CST tonight), 2026-11-26T00:00Z (final)
- Result due 2026-12-10T08:00Z
- Repo must be created AFTER 2026-11-24T00:00Z (repo_created_after_open check)
- Transcripts bundle required (transcripts_present + thinking_* checks); handed_over_places = none

## Winner study (Nov 23 edition, rounds/board)
- Rank 1 (kevin, 864465): "33 stories, 7 regions" — broadsheet front page, 3 big illustrated leads + 10 illustrated + 20 one-line briefs, stat band, UTC timeline, world map with pins, DATE CHECK box, credibility legend, sources line
- Rank 2 (cenzer0, 836009): 33 stories, 6 regions — same skeleton
- Rank 3 (nazwakhoerina, 833864): 36 stories, 7 regions
- Artifacts saved as winner23-rank-*.webp in this directory

## News collected (UTC 24 Nov 2026, all verified in search results)
Leads: Riyadh PIF Tower Houthi strike (11 hurt, 2nd in 5 days, Reuters); Shanghai Chen Jining probe (Xinhua 11:48 UTC, 4th Politburo member since 2025); Dow first close above 50,000 (50,018.70 +0.85%, Nasdaq −1.48%, Nvidia −5.9%).
Mediums: ECHR migrant-expulsion ruling; Poland permanent-US-troops push; Medvedev nuclear warning; Gaza strike kills Hamas security chief Naeem Abu Nahel; Zaporizhzhia strike (2 dead, 40 wounded); chess Game 1 draw (38 moves, Berlin); Real Madrid 5–1 PSV; US states sue Musk firms over Grok; Nepal 5.6 quake; Colombia car bomb (23 hurt).
Briefs 14–33: UN Gaza 77-years report; Germany Delta access; UK sabotage warning; 7-states visa curbs; EU hybrid quotas; Sanofi–Insmed $41bn; Korea ADIZ scramble; AI exam-cheat rewards; Tiangong first foreign astronaut; Hanoi gas blast (6 dead); Australia digital duty (5% fines); Ituri Ebola teams trapped; Zanzibar hotel fire; Ghana forest patrol attack; 47,000 women killed (UN); Ras Al Khaimah coach crash (11 dead); Iraq Kurdish oilfields; Iran Hormuz order; El Chapo Isidro trial; US measles status lost.
Date-check traps caught and excluded: ICJ Rohingya ruling was 19 Nov (not 24th); Guterres AI-safety call was Mon 23 Nov; Nvidia reinstatement was Mon 23 Nov (only Tuesday's market verdict shown); COP31 collapse Sun 22 Nov.

## Entry built (local only — NOT published, NOT submitted)
- Dir: `entry/` — git repo, local commit 84c31eb, NO remote configured
- news.png: 1024×1024, 213,551 bytes (limit 1,048,576); render.py + stories.json build it (Pillow, original flat drawings, no external images)
- main.py: copies news.png to $MAKEFUN_OUTPUT_DIR/entry.png verbatim; tested twice — sha256 identical to news.png both runs
- README.md (make.fun badges; repo name placeholder kingparkpark/news-image-20261124 — update if user names it differently), LICENSE (MIT), .makefun/owner.json (wallet BhA7...)
- Blind-test self-check: viewed at 510px (judge width); hierarchy holds; fixed region-bar overlap, chart label collision, legend/date-check overlap

## What remains (needs the user's word)
1. User creates an EMPTY PUBLIC GitHub repo (suggested name: news-image-20261124; must be created after 2026-11-24T00:00Z — any time now qualifies). Do NOT use the old VM repo.
2. On approval: push local commit, set repo About (website https://make.fun/bounty/news-image-20261124, topics makefun/ai-agents/bounties/code — same pattern as VM entry), then bundle + check + submit via kit CLI.
3. Bundle dry-run findings (fix at submit time): needs --prompt-file (scheduled task text, --prompt-origin scheduled), --mcp none, --provider meta --model muse-spark-1.3 --effort default --harness/--harness-version flags, and --muse-usage <file> (usage rows attach only after this turn is delivered — copy from muse.db in the submit turn, as done for the VM entry).
4. Timing: submit before 20:00 CST tonight (2026-11-25T12:00Z) to be judged in blind round 3; hard deadline 2026-11-26 08:00 CST.

## 2026-11-26 01:42 CST status watch
- status: scored, outcome not decided; all checks pass.
- rounds: round 3 judged (14,561 ranked), our entry 124 / 740288 — same as already recorded 2026-11-25; no material change, no user message.
- next: final round at 2026-11-26T00:00Z.
