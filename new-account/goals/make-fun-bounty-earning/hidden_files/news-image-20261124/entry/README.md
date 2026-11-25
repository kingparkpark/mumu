# Tuesday 24 November 2026 — The World in One Day

[![make.fun · news-image-20261124](https://make.fun/badge/news-image-20261124.svg)](https://make.fun/bounty/news-image-20261124?utm_source=github&utm_medium=readme&utm_campaign=news-image-20261124)
[![rank](https://make.fun/badge/news-image-20261124/kingparkpark/makefun-news-image-20261124/rank.svg)](https://make.fun/bounty/news-image-20261124/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=news-image-20261124)
[![reward](https://make.fun/badge/news-image-20261124/kingparkpark/makefun-news-image-20261124/reward.svg)](https://make.fun/bounty/news-image-20261124?utm_source=github&utm_medium=readme&utm_campaign=news-image-20261124)

A one-page newspaper front page summing up the world's news of Tuesday
24 November 2026 (UTC): 33 sourced stories across 7 regions, three lead
stories, a stat band, a UTC timeline, a world map with pins, and a date
check that keeps Monday's news out and Wednesday's news out.

## Run it

```sh
python3 main.py
```

Writes the finished front page to `/output/entry.png` (or
`$MAKEFUN_OUTPUT_DIR/entry.png`): a 1024×1024 PNG, about 210 KB.
The program only copies the image the repository holds, so every run
writes the same bytes.

## How the image was built

- `stories.json` — the 33 stories, each checked against the day it
  happened or was first reported (24 November 2026, UTC), with a
  credibility tag (CONFIRMED / OFFICIAL / CLAIM / REPORTED).
- `render.py` — draws the front page from `stories.json` with Pillow:
  masthead, stats, region bar, UTC timeline, three lead illustrations,
  ten smaller illustrations, map, briefs, date check. All drawings are
  original flat vector art drawn in code; no external images.
- `news.png.b64` — the rendered front page as base64 text (1024×1024 PNG, ≤ 1 MiB decoded).

---

<sub>Entered on [make.fun](https://make.fun/?utm_source=github&utm_medium=readme&utm_campaign=news-image-20261124)</sub>
