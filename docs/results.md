# Results

All numbers are from the machine described in `docs/methodology.md`. "World samples" are
per-frame lines with fps < 29 (menus and videos run at the title's own 30 fps).

## The runs

| # | Layer build | Console | Switches | World samples | Frame time median | FPS median | FPS mean | Worst frame |
|---|---|---|---|---|---|---|---|---|
| V4 | fork `d510ee4` | series-x | 14 | 76 | 210 ms | 4.80 | 6.33 | 1,829 ms |
| V5 | fork `f6a09d3` | series-x | 14 (reaper default off) | 205 | 235 ms | 4.30 | 4.54 | 1,307 ms |
| V6 | fork `f6a09d3` | series-x | 14 + `VICTORY_REAPER=1` | 46 | **211 ms** | **4.80** | 6.20 | 1,749 ms |
| V7 | archive `f4b48ad` | series-x | 15 | 34 | **172 ms** | **5.90** | 6.29 | **489 ms** |
| V8 | archive `f4b48ad` | series-x | 15 (repeat of V7) | 34 | 220 ms | 5.80 | 6.11 | 1,323 ms |
| V9 | archive `f4b48ad` | **series-s** | 15 | **551** | **110 ms** | **9.10** | **9.02** | 1,190 ms |

"15 switches" is the 14 listed in `docs/methodology.md` plus `VICTORY_REAPER=1`.

## What each comparison says

### V4 -> V5: a correctness release that costs frame rate

Between those builds the fork fixed two classes of shader arithmetic (legacy multiply-add
semantics, 32-bit integer typed views) and turned two features off by default. The picture
improved; the median got 12 % worse.

Conclusion: **correctness fixes are not free**, and a build that looks better can be
slower.

### V5 -> V6: the regression is the default, not the fixes

One variable (`VICTORY_REAPER=1`) restored the old median exactly (235 -> 211 ms) while
keeping the fixes. The per-frame "write-watch asking and the look for title bytes under
flights" line fell from **137.2 ms to 101.2 ms**.

Conclusion: **check defaults on every upgrade**; they move.

### V6 -> V7/V8: the archive tree is not decisively faster

The archive build (`f4b48ad`, from a project tuned on an RX 7900 XTX) measured 172 ms on
one run and 220 ms on a repeat, with the same 34 samples each time, while being the only
tree of the three with a `land` subsystem (a four-thread pipeline that fetches and merges
what shaders wrote). The worst frame collapsed in one run (489 ms) and not in the other.

Conclusion: **run-to-run variance is comparable to the difference between builds** here.

### V7/V8 -> V9: the console profile is the big lever

Same build, same switches, `--console series-s` instead of `series-x`:

- the title's render target becomes **1920x1080** (logged as a `width=1920 height=1080`
  target; the swap chain stays 3840x2160, so the picture is 1080p upscaled to 4K);
- median frame time **220 -> 110 ms**, median FPS **5.8 -> 9.1**;
- frames at or above 8 fps go from **4/34 (12 %)** to **457/551 (83 %)**;
- this is the configuration that reached **Jason's first mission**.

Conclusion: **on this hardware, the console profile dominates every switch we tried.**

## What the layer's own counters said at 1080p

From the V9 run, at its best:

```
the card's clock per frame: nothing of ours queued 28.4 ms (the card about 15% busy)
the submitting thread stood waiting for the card 0.0 ms
our passes over copies in the card's memory per frame: 31 hash passes, 6 compare passes
shader writes looked for on the CPU per frame: 1.4 MB in 36 ranges (was 28 MB in 300+)
landing per frame (4 threads): merging what was fetched 0.42 ms (1.51 ms on all threads)
```

Compare the Series X runs, where the same lines read about 300 hash passes, 28 MB of
comparison and 200 ms waiting for the card. **The work shrank because there is less to
draw, not because anything got smarter** - which is why the profile change is such a large
lever.

## Cautions

- V7 and V8 are the *same* configuration and differ by 28 % in median frame time.
- V5's 205 samples cover a longer session than V4's 76; means are not comparable across
  different sample counts.
- None of these runs had ray-traced lighting: everything the sun does not hit directly is
  dark, and the layers substitute a constant.
