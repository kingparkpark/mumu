# Launch Radar — token-radar-01 entry

Ranks the snapshot's pre-token protocols by implied launch value, where the
implied value is an **expected value**: the launch market cap a validated
comparables fit assigns *if the protocol launches*, times the launch odds the
snapshot's own token record supports. Every row carries a value interval, a
rank interval and a priced farm plan with a farm / thin / skip verdict.

## What it produces

- `board.json` — 198 rows: all 40 watchlist protocols plus 158 early finds
  (ranked by implied value; `rank_interval`, `verdict` and the plan economics
  are in every row)
- `dashboard/` — static site, no build step, no network: board with search,
  category / chain / verdict filters and seven sorts, per-protocol detail
  (model decomposition, value and rank intervals, verdict economics, farm
  plan), the 416 already-live protocols with their actual caps, and a model
  page that prints the validation the model choice rests on
- `screenshots/` — board, top-protocol detail, a Lending filter view, model page
- `dossier.json` — built with the kit's `vendor/makefun-board.ts`, unchanged

## The model (radar-3-validated)

- **Value if it launches**: log-log OLS of market cap on TVL over the 128 live
  protocols in the snapshot that have both (slope 0.4997, intercept 3.1848),
  fitted **jointly** with per-category multipliers — each category's median
  actual/fitted ratio, shrunk toward 1 by n/(n+16), fitted in two alternating
  rounds; categories with fewer than 4 fitted members stay neutral.
  Full-model R² 0.2259.
- **Launch odds**: the share of comparable protocols that record a token —
  same category, same age band (under 180 days / 180–730 / over 730 / no
  date) — with cell rates shrunk toward category rates and category rates
  toward the snapshot-wide 54.9%. An empirical base rate read off the
  snapshot, not a forecast.
- **Validation, computed on every run**: three candidate structures scored by
  leave-one-out over all 128 fit protocols and by a walk-forward split on
  listing date (fit on the 57 listed up to 2024-07-25, score the 38 listed
  from 2024-08-22). Median absolute errors:
  - radar-2 (previous model: line + category shrink 4 + hand-set growth and
    maturity multipliers): LOO ×3.63, walk-forward ×3.22
  - five-feature regression (TVL, chains, growth, age, age-missing):
    LOO ×3.99, walk-forward ×3.79 — rejected, it overfits
  - radar-3 (this model): **LOO ×3.28, walk-forward ×3.00** — won both tests,
    so growth and age multipliers were dropped; those features enter only
    through the launch odds, where the evidence supports them
- **Intervals**: each row's value interval is its implied value ×/÷ the 75th
  percentile of the leave-one-out error (×8.88; the band contained 75% of
  held-out predictions). Rank intervals count how far a row could move if
  every row stood at an end of its own band — wide, because the held-out
  evidence says launch caps are only predictable within about a factor of
  nine; the verdicts, not the exact order, are the actionable output.
- **Verdicts**: a plan's cost is its gas plus active minutes at $15/hour,
  set against an expected allocation of 0.02% of implied value. FARM needs
  the expected net to stay at least $100 positive even at the low end of the
  value interval; SKIP is launch odds under 0.20 or a negative expected net;
  everything else is THIN. This board: 36 farm, 128 thin, 34 skip. Every
  plan's closing step repeats its verdict with its numbers.
- **Board hygiene**: wrapped / staked / bridged products of tokens that
  already trade, versioned pools of other protocols and exchange records are
  set aside by field-derived rules (144 records), so the board ranks
  protocols, not re-exports of listed tokens. 758 = 198 ranked + 144 set
  aside + 416 already live.

## Run

```sh
node main.ts            # reads /input/snapshot.json, writes /output
node main.ts --input <snapshot.json>   # MAKEFUN_OUTPUT_DIR overrides /output
```

Node 22, standard library only, no network. Deterministic: two runs on the
same snapshot produce byte-identical output.
