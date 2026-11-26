# GTA VI (Xbox Series build) on PC — measurements, configs and notes

Field notes from running the **Xbox Series X|S console build of GTA VI (1.0.2.1)** on a
single Windows PC through community compatibility layers, and from measuring what
actually limits it.

This repository contains **no game files, no keys, no binaries and no layer source code.**
It is a record of measurements, environment switches and conclusions, so that other
people can reproduce the numbers or avoid the same dead ends.

> **Disclaimer.** Grand Theft Auto VI and related marks belong to their owners. This is
> unofficial technical research by a player. It is not affiliated with Rockstar Games,
> Take-Two, Microsoft or any of the layer projects below. You need your own copy of the
> game; nothing here helps you obtain one.

## Legal position

- **No copyrighted game content is hosted here**: no assets, no code, no keys, no
  executables, and **no links to anywhere those can be obtained**.
- **Nothing here circumvents a protection measure.** The script starts a file the user
  already has, through a third-party compatibility layer that is published separately
  under its own licence. This repository does not contain that layer either.
- The measurements, configurations and prose are original work, released under the MIT
  licence (see `LICENSE`).
- This is unofficial research. It is not affiliated with, endorsed by or sponsored by the
  game's publisher or platform holder.
- If you are a rights holder and want something here changed or removed, open an issue and
  it will be adjusted or taken down. The content is small and reproducible from public
  discussion.

---

## TL;DR

On one machine (RTX 5070 Ti 16 GB, Intel Core Ultra 7 265K, 31 GB RAM, Windows 11 26200),
the same layer build runs **twice as fast** when the title is told it is on a Series S:

| Profile | Render target | Frame time (median) | FPS (median) | Frames >= 8 fps |
|---|---|---|---|---|
| Series X | 3840x2160 swap chain, 1440p-class targets | **172-220 ms** | 4.8-5.9 | 11 % |
| **Series S** | **1920x1080** | **110 ms** | **9.1** | **83 %** |

It reached **Jason's first mission** ("Gone Fishing") this way.

Three findings that cost us the most time:

1. **`VICTORY_REAPER=1` is not optional on a 31 GB machine.** Newer builds default it off;
   without it one build lost 12 % and the per-frame "look for title bytes" cost went from
   101 ms to 137 ms, because about 46 million objects per run then get dropped on the
   calling thread.
2. **`--console series-s` is the only real resolution lever.** The layer has no resolution
   switch; the title asks for the swap chain size itself. Series S makes it render at
   1920x1080 (still presented at 4K).
3. **"Compile queue" is not the wall on XCL.** With pipeline preloading disabled the title
   stops waiting on pipelines entirely (0 gated binds) and instead stops on five
   `Wait64BitValueX` on a value nothing claims to write.

---

## What is in here

| Path | What it is |
|---|---|
| `scripts/run_BEST_1080p.cmd` | the best configuration we found, ready to run |
| `data/results.csv` | every measured run, machine-readable |
| `docs/methodology.md` | how the runs were made and what makes two numbers comparable |
| `docs/results.md` | the runs, with interpretation |
| `docs/how-it-works.md` | why an Xbox x86-64 title can run on Windows at all |
| `docs/troubleshooting.md` | every failure we hit and what fixed it |
| `docs/xcl-findings.md` | separate notes on the generic layer (XCL) |
| `docs/scene-timeline.md` | dated timeline of the release, the build and the takedowns |
| `docs/legal.md` | what this repository does and does not contain |

---

## Reproducing the best result

1. Get a layer build that has the `land` subsystem (see `docs/results.md` for which tree).
2. Put your own dump somewhere and point the script at it.
3. Run:

```bat
set "VICTORY_GAME_DIR=D:\your\own\dump"
run_BEST_1080p.cmd
```

The script sets 15 switches (listed and explained in `docs/methodology.md`) and passes
`--console series-s`. Frame rate is drawn in the corner of the picture by the layer.

**Expect the first launch to be slow**: the layer translates shaders and builds pipelines
on demand, and the pipeline library is written to disk for the next run.

---

## Why the numbers here are conservative

- Every switch set is reported, not just the winning one.
- Runs are compared at the **same build**, the **same console profile** and the same
  switch set; where that was impossible it is said so explicitly.
- Medians are given with the sample count, because run-to-run variance on this workload
  is large (one configuration measured 172 ms and 220 ms on two consecutive runs).
- Anything taken from another person's report is labelled as such and never mixed into
  our own medians.

---

## Status of the scene at the time of writing

The layer projects move in hours, not weeks. Anything in `docs/` is a snapshot: treat
version numbers and switch names as things that may already have changed.

| Project | Route | State when measured |
|---|---|---|
| VIctory forks (several) | console code -> DXIL directly | prologue renders, 5-10 fps, shadows dark |
| XCL | console code -> HLSL -> DXC -> DXIL | menus and loading screen, then black |
| TuxBox | Wine/Proton on Linux | first screen |

See `docs/results.md` for the exact builds used.
