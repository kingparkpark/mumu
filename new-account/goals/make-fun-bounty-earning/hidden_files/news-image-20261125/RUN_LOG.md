# news-image-20261125 — run log (built 2026-11-26 08:41–09:00 CST)

## Bounty verified from this edition's kit (RULES.txt + competition.yaml)
- Slug: `news-image-20261125` — "Sum up 25 November's world news in one image"
- Opens 2026-11-25T00:00Z; deadline 2026-11-27T00:00Z = 2026-11-27 08:00 CST
- Pot $100, 50 paid places (1st $20, 2nd $12, 3rd $6, 4–10 $2, 11–50 $1.20); free entry
- Image PNG/JPEG ≤1 MiB, ≤1024×1024; main.py (Python 3.13) at repo root; no network; two runs byte-identical
- Judge: z-ai/glm-5.3-flash, pairwise; criteria order: names the day > breadth > reads clearly > faithful > craft, "legible at about 300 pixels across" (last edition's text said ~510px viewing; this edition's judge text stresses 300px — type went even bigger)
- Final heat: 3 Swiss rounds + playoff of top 52; playoff entries place above all others
- Repo must be created at/after 2026-11-25T00:00Z; transcripts required; handed_over_places = none
- No structural differences from the 20261124 edition beyond the above

## Design changes vs the Nov 24 edition (which placed 124 / 14,561, 740288)
- Stories 33 -> 27, but every size up: date 58->64px, lead headlines 24->29px, medium headlines 14->18px, briefs 11->13px, stat numbers 28->34px, region bar 12->14px
- Mediums 10 -> 8 larger cards (2 rows x 4); briefs 20 -> 16, each shortened to fit one full line (no mid-word truncation anywhere on the page)
- Region bar widths now guarantee each label's full text width (last edition's approach would have clipped OCEANIA / LATIN AMERICA)
- Same winning skeleton kept: broadsheet masthead with counts in the title line, stat band, UTC timeline, world map with numbered pins, DATE CHECK box, credibility tags + legend, sources line

## News collected (UTC Wed 25 Nov 2026; each cross-checked in search results)
Leads: (1) Hormuz — IRGC says two tankers struck naval mines and caught fire (CLAIM, via Just Security early edition); (2) New York — Dow erased a 1,105-point intraday plunge to close +0.33% at 50,182.95, Nasdaq -0.62%, Nvidia -4% (CONFIRMED, WSJ/AP/Investopedia); (3) Cairo — fuel tanker crash fire kills at least 31 (CONFIRMED, Egypt Health Ministry via LA Post).
Mediums: Houthis claim Ras Tanura refinery strike (CLAIM); Israeli strike kills Hamas interior-security chief Mohammad Abuelouf + wife and two children (CONFIRMED — NOT the Abu Nahel killing, which was Tue 24); Russian overnight strikes kill 2 in Odesa region, Kyiv flats ablaze (CONFIRMED); US proposes Section 301 tariffs on 14 partners (OFFICIAL); Solomon Islands–Australia no-foreign-base treaty signed (OFFICIAL); Champions League Wed night — Lille 2-1 Bayern, Paris 2-2 Roma, Liverpool 3-0 Brugge, Barcelona 4-1 Sabah (CONFIRMED, UEFA); Sudan RSF drone strikes kill 19 civilians (REPORTED, Emergency Lawyers); Bangladesh garment wage +36% to $139 (CONFIRMED, Reuters).
Briefs 12–27: US Q3 GDP +4.3% revised, Oct PCE 3.8% y/y (BEA); chess Game 2 drawn in 20 moves, match 1-1 (Chess.com); IS attack kills 2 in Hasaka (Reuters); KOSPI -6% (Reuters Morning Bid); Japan No.3 AI power plan; China official death sentence for leaking 100+ secrets; CIA/ODNI unclassified breach (Reuters); Macy's parade postponed (storm); judges urge dropping one Netanyahu bribery case; Pope Leo laments COP31 failure (his statement is Nov 25; the collapse itself was Sun 22 — date-check box says so); Hungary–Ukraine 'fresh start'; UN evacuates Ebola workers in Ituri; Nigeria $200m meth seizure; Ecuador–US military review; UK watchdog AI warning / Meta UK-tuned Muse; Poland eastern no-fly zone plan.
Date traps caught and excluded: Real Madrid 5-1 PSV (Tue 24); Riyadh PIF Tower strike (Tue 24); Abu Nahel killing (Tue 24); Nvidia reinstatement (Mon 23); COP31 collapse (Sun 22); Niger kidnapping (21–22 Nov, only reported on the 25th); Huawei verdict (Just Security dates it "yesterday" = Nov 24 — dropped as unsafe); Shenzhou-24 astronaut story (already Nov 24 news — dropped).

## Entry built (local only — NOT published, NOT submitted)
- Dir: `entry/` — local git repo, commit a98c6f6, NO remote
- Files: main.py, render.py, stories.json, news.png.b64 (single line, 297,452 bytes, 0 line breaks in content), LICENSE (kit starter, MIT), README.md, .makefun/owner.json (wallet BhA7...)
- news.png: 1024×1024, 223,088 bytes, sha256 1e883c21d5cfef7ff39b6f6ff51fbb6622a7420fa9d90f41f5fd20dd6bf3dc95; copy at ../news-final.png
- main.py run twice locally: both outputs sha256-identical to the rendered PNG
- 510px self-check: date, subhead, stats, lead + medium headlines all legible; briefs readable as bold-place one-liners; no overflow, no truncated words, no overlaps (three render iterations to get there)

## Local check (kit CLI, --worktree, no transcripts — same staging as last edition)
- pass: competition_open, snapshot (7 files, 327,058 bytes), license_osi, entrypoint
- FAIL (expected at this stage): transcripts_present — no bundle supplied; the bundle must be made by the top-level agent from the real session files at submit time (last edition: bundle + check passed 13/13 in the submit turn)
- skip: all other transcript-gate items (nothing to read yet); 5 items are site-side at submission (repo_public, repo_owner — owner.json is committed, repo_created_after_open, commit_in_repo, duplicate_snapshot)

## What remains (needs the user's word — same as last edition)
1. User creates an EMPTY PUBLIC GitHub repo (suggested name: makefun-news-image-20261125; must be created after 2026-11-25T00:00Z — any time now qualifies).
2. On approval: push commit a98c6f6, set repo About (website https://make.fun/bounty/news-image-20261125, topics makefun/ai-agents/bounties/code, description stating 27 stories / 7 regions), then bundle (with --muse-usage, --prompt-file etc. as in the 20261124 submit turn) + check with --transcripts + submit.
3. Timing: deadline 2026-11-27 08:00 CST; field-guide median winner arrived 1.78h before close — aim to submit by ~06:00 CST 2026-11-27 at the latest, earlier is safer.
