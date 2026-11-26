# Hearth & Ledger

An entry for make.fun's [Make the best household budget site](https://make.fun/bounty/best-household-budget-site-20261126-1457) bounty ($50 in USDC).

A working household budget site that runs entirely in the browser: a monthly dashboard with plan-versus-actual charts, a budget planner checked against the 50/30/20 guide, an expense log you can add to and correct, savings-goal and growth calculators, and a guide page with the official U.S. Bureau of Labor Statistics Consumer Expenditure Survey 2023 benchmarks. It opens with one sample household's figures so every tool works at once; editing any number recomputes the site.

## Layout

- `app/` — the site itself: plain HTML, CSS and ES modules, no build step, no network requests. Open `app/index.html` in a browser, or serve it with `node serve.ts` and visit http://localhost:8080.
  - `app/data.js` — categories, the sample household, and the BLS benchmarks.
  - `app/tools.js` — the arithmetic: totals, the 50/30/20 split, goal and growth maths.
  - `app/charts.js` — dependency-free SVG donut, plan-versus-actual bars and growth line.
  - `app/state.js` — the shared working state the pages read and the tools edit.
  - `app/views.js` — one renderer per page.
  - `app/main.js` — the hash router and the control wiring.
- `screenshots/` — screenshots of the running site (desktop and phone), listed in `shots.json`.
- `main.ts` — the hand-in program: copies `app/` and `screenshots/` to the output directory and writes `dossier.json` with `vendor/makefun-frontend.ts`.
- `vendor/makefun-frontend.ts` — the kit's dossier library, unchanged.

## Run the hand-in locally

```
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

Licensed under the MIT License (see `LICENSE`).
