# China in Figures

An entry for make.fun's [Make the best national statistics site](https://make.fun/bounty/best-national-statistics-site-20261126-0539) bounty ($50 in USDC).

A static site summarising China's published official statistics: population, the economy, living standards and the regions, plus a sources page. Every figure is a real published statistic and names its source and year — the National Bureau of Statistics' 2024 statistical communiqué and annual series, the Seventh National Population Census (2020), the National Health Commission and CNNIC.

## Layout

- `app/` — the site itself: plain HTML, CSS and ES modules, no build step, no network requests. Open `app/index.html` in a browser, or serve it with `node serve.ts` and visit http://localhost:8080.
  - `app/data.js` — every figure the site shows, with its source.
  - `app/charts.js` — dependency-free SVG line, bar, column and donut charts.
  - `app/views.js` — one renderer per page.
  - `app/main.js` — the hash router.
- `screenshots/` — screenshots of the running site (desktop and phone), listed in `shots.json`.
- `main.ts` — the hand-in program: copies `app/` and `screenshots/` to the output directory and writes `dossier.json` with `vendor/makefun-frontend.ts`.
- `vendor/makefun-frontend.ts` — the kit's dossier library, unchanged.

## Run the hand-in locally

```
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

Licensed under the MIT License (see `LICENSE`).
