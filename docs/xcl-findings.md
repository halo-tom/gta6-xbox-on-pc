# XCL notes - separate layer, separate wall

XCL is a general-purpose layer (it runs more than this title) and its shader route is HLSL
plus DXC rather than direct DXIL. We measured it separately; these notes are what remained
after the fixes of 25-26 November landed upstream.

## What was fixed upstream and confirmed here

| Change | Before | After |
|---|---|---|
| upstream fix - the title's `Sleep` no longer counts time a bind waits for a pipeline build | the title kills itself 7.7 s after the world-load call (`GPU Loc Sig` watchdog) | 0 watchdogs in 900 s runs |
| upstream fix - oversized structured code falls back to `pc` blocks | one program became 148 MB of HLSL; longest bind wait 626 s | longest bind wait 135-187 s |
| local revert of the structured-jump commit (memory regression) | memory grew about 1 GB/s | 25-31 GB, stable |

With those in place the title no longer dies. It simply never presents again.

## The pipeline queue

Window title during a run:

```
0.0 FPS | compiling shaders: 0 running, 543 done, 57693 pipelines queued
```

543 in about 9 minutes. The queue is the layer building "the pipelines of an earlier run"
ahead of first use.

Setting `XCL_PSO_PRELOAD=0` removes it. Then:

| | preload on | preload off |
|---|---|---|
| queued | 57,693 | none |
| binds waiting for a build | 20+ | **0** |
| frames presented | stop at about 270 s | stop at **242 s** |
| total frames | 6,751 | 6,751 |

So the compile queue was not what held the picture back. With it off, nothing waits on a
pipeline at all.

## What it actually stops on

At 240.5 s, five waits on one address family:

```
Wait64BitValueX at 0x...158 >= 0x1a63   waiter=q1 prod=qNone/tySome(0)
                                       wait-before-signal, after_write64=false
Wait64BitValueX at 0x...110 >= 0x1a63   waiter=q2 ...
Wait64BitValueX at 0x...1e8 >= 0x1a63   waiter=q2 ...
Wait64BitValueX at 0x...120 >= 0x1a63   waiter=q0 ...
Wait64BitValueX at 0x...138 >= 0x1a63   waiter=q0 ...
```

Two seconds later presenting stops; the next 658 seconds contain 13 draws and no presents.

Upstream tracks this in the "waits with no producer" family of issues. The mechanism is that
a bridged wait should be released from the CPU side after a timeout; in our runs the title
never recovered even after that.

## The scan that grows

The layer prints its own timing for keeping its memory windows in sync:

```
write-watch      5 ms  (6,811 dirty pages)
write-watch  1,679 ms  (396,949)
write-watch  4,642 ms  (403,350)
write-watch 10,635 ms  (1,122,885)
write-watch 25,872 ms  (2,405,382)
```

One pass costs 25.9 seconds once the title has committed 2.4 million dirty pages. This is the
same family of cost as the fork's "look for title bytes", measured differently.

## The Intel penalty

The title paces itself by spinning on a value in memory with `monitorx` / `mwaitx`, which
are AMD instructions. On our Intel CPU every one of them traps:

```
console CPU instructions, exceptions a second:
  monitorx 223,112   mwaitx 223,109   others 587
mwaitx waits ended a second: 4, 537.6 ms of thread time a second
  of 20 ms and more: 3.8, 531.4 ms
```

More than half a core, every second, spent emulating four waits. On an AMD CPU this would
not exist.

## Summary

- The death is fixed; the stall is not.
- The stall has a precise address and value (`0x1a63`) and no producer.
- Disabling preloading is a good diagnostic and probably should be the default for this
  title.
- Two independent costs (pipeline build time and memory-scan time) both scale with how much
  the title has committed, which is why a smaller console profile helps both layers.
