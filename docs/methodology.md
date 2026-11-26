# Methodology

The point of this file is to make the numbers in `docs/results.md` checkable and to say
where they stop being trustworthy.

## The machine

| | |
|---|---|
| GPU | NVIDIA GeForce RTX 5070 Ti, 16 GB, driver 32.0.16.2101 |
| CPU | Intel Core Ultra 7 265K (20 cores / 20 threads) |
| RAM | 31 GB |
| OS | Windows 11, build 26200 |
| Storage | game dump on a mechanical disk |

## How a run is made

```bat
victory.exe run "<dump>\\game_scarlett_master.exe" --console <series-x|series-s> --execute
```

- The layer prints a per-frame line (`N fps, M ms/frame ...`) every few seconds and draws
  the same number in the corner of the picture.
- A run is normally ended by closing the window; per-frame samples are parsed from the
  log afterwards.
- "World samples" means per-frame lines with **fps < 29**, i.e. excluding menus and videos,
  which are capped at the title's own 30 fps.

## The 15 switches used for the best result

All are environment variables read by the layer.

| Switch | What it does | Why we keep it |
|---|---|---|
| `VICTORY_ASYNC_SUBMIT=1` | submissions are prepared by a layer thread, not the title's render thread | the title's thread otherwise sits in the submit path |
| `VICTORY_QUEUE2=1` | fetches of what shaders wrote go to a copy queue | removed about 120 ms of copy-back waiting in an earlier build |
| `VICTORY_INDIRECT_WINDOW=1` | indirect draw windows | fewer clamp passes |
| `VICTORY_TEXTURE_NO_WAIT=1` | a texture refresh does not wait while the title remaps memory | removed about 171 ms/frame of waiting |
| `VICTORY_LATE_WAIT=3` | submissions sent ahead of the wait for the card | hides card latency |
| `VICTORY_WIDE_BACK=1` | wider copy-back batching | part of the same bundle |
| `VICTORY_CARD_BUFFERS_MIN_MB=1` | small title buffers get a copy in card memory | moves about 400 MB/frame of CPU hashing onto the card |
| `VICTORY_CARD_BUFFERS_MB=1024` | budget for those copies | 1 GB was enough |
| `VICTORY_CARD_REHASH_RUNS=1` | joins repeated hash passes | 518 passes -> about 150-200 |
| `VICTORY_JOIN_COPIES=1` | joins adjacent copies | fewer submissions |
| `VICTORY_COPY_PLAIN=1` | copies of title memory made in place with a page-fault fallback | submit-thread kernel time about 44 -> 20 ms |
| `VICTORY_JOIN_PARTS=1` | parts of one list that follow each other go as one submission | about 6 % |
| `VICTORY_BACK_OWN_VIEW=1` | what shaders wrote goes back through the layer's own view | about 9 % |
| `VICTORY_INDIRECT_GATHER=1` | scattered indirect records clamped once per list | fewer clamp passes |
| **`VICTORY_REAPER=1`** | host objects are dropped by a thread of their own | a regression fix, not an optimisation |

### Why `VICTORY_REAPER=1` matters here

Newer builds of the fork switched the reaper **off by default**. On a machine with 31 GB
of RAM that is a measurable regression:

| Build | Reaper | Frame time (median) | FPS (median) | Write-watch line |
|---|---|---|---|---|
| `f6a09d3` | default (off) | 235 ms | 4.30 | 137.2 ms |
| `f6a09d3` | `=1` | **211 ms** | **4.80** | **101.2 ms** |
| `d510ee4` (older) | n/a | 210 ms | 4.80 | - |

The log explains it: with the reaper on, one run dropped **46,417,078 host objects in
9,132 ms of that thread's time**. Without it, those drops happen on whichever thread
released them, and the per-frame "look for title bytes" cost absorbs the damage.

## What makes two numbers comparable

We were bitten by this more than once, so the rules are explicit:

1. **Same build.** One commit can move the median by 10 % in either direction.
2. **Same console profile.** `series-x` and `series-s` do not just change resolution; they
   change the device the title thinks it has, so memory and streaming behaviour differ too.
3. **Same scene.** Draw counts per frame are a rough proxy. Two runs in different parts of
   the prologue can differ by 30 % in frame time at identical settings - which is why the
   best configuration was measured twice (172 ms, then 220 ms).
4. **Enough samples.** The sample count is reported every time. A 34-sample run and a
   551-sample run are not the same evidence.
5. **Medians, not averages, for a first look.** This workload has rare 1-2 second frames.

## Known limitations of this data

- One machine, one GPU vendor. Nothing here says how an AMD card behaves.
- Sample counts differ between runs (34 to 551).
- Some switches were adopted as a bundle after an A/B on an older build and were not
  re-measured individually on the newest one.
