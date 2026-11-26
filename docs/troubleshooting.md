# Troubleshooting - everything that bit us

Each entry is something we hit, with the symptom, the cause as far as we could establish
it, and what worked.

## Black window with a frame counter

**Symptom.** The window is black; the title bar reads something like
`0.0 FPS | compiling shaders: 0 running, 543 done, 57693 pipelines queued`.

**Cause.** The layer is building pipelines ahead of first use - in our case the whole
recorded set. At roughly one pipeline per second that is a 16-hour job.

**Fix.** `XCL_PSO_PRELOAD=0` on XCL. The queue disappears. What remains is a different
failure (next entry) - which is the point: the compile queue was masking it.

## The title stops presenting and never returns

**Symptom.** Frames stop during world load; no crash, no watchdog, no device removal; the
process sits there indefinitely.

**Cause.** Five `Wait64BitValueX` calls on one value that nothing claims to write:

```
Wait64BitValueX at 0x... >= 0x1a63
  bridged to GPU queue.Wait
  prod=qNone/tySome(0); wait-before-signal, after_write64=false
```

`prod=qNone` means no recorded producer for that address; `wait-before-signal` means the
title started waiting before any producer was submitted.

**Fix.** None found by us. This is the state of the art at the time of writing.

## A per-frame stall that grows without bound

**Symptom.** During load, one "write-watch" pass grows: 5 ms -> 1.7 s -> 10.6 s -> 25.9 s.

**Cause.** The layer scans title memory for writes. Dirty pages grow with what the title has
committed: 2.4 million in our run, and the scan is proportional to that.

**Fix.** None on our side; an upstream proposal exists but is unmerged at the time of
writing.

## Frame rate drops after an update, picture gets better

**Symptom.** After updating the layer, colours and surfaces look more correct, but the
median frame time goes from 210 ms to 235 ms.

**Cause.** The build changed two defaults (`VICTORY_REAPER` and the skin-bake sources) to
off. With the reaper off, about 46 million host objects per run are released on the calling
thread.

**Fix.** `VICTORY_REAPER=1`. Median returns to 211 ms with the picture fixes intact.

## Resolution cannot be changed from the command line

**Symptom.** `--help` offers only `--console`, `--strict`, `--unimplemented`. The log shows
the swap chain is created at 3840x2160.

**Cause.** The title decides the size; the layer builds a swap chain to match.

**Fix.** `--console series-s`. The title then renders at 1920x1080 (still presented on a 4K
swap chain). Worth about 2x frame rate on our machine.

## Series S profile crashes at startup on the other layer

**Symptom.** With `lockhart` / series-s on XCL, the title dies with `E_INVALIDARG` on an
`R9G9B9E5_SHAREDEXP` resource that carries render-target or UAV flags.

**Cause.** PC D3D12 forbids those flags on that format; consoles allow it.

**Fix.** Upstream promotes format 67 to `R11G11B10_FLOAT` when those flags are set. The
fork used for the best result did not hit this at all, so the layers differ here.

## "The menus never appear"

**Symptom.** Our early notes said one layer ran menus at 30 fps. A screenshot taken later
showed a **completely black window**; the 30 fps came from the intro videos.

**Cause.** Frame counters are not evidence of picture. Bink videos present at 30 fps on a
black or nearly black window, and the counter looks identical to a working menu.

**Fix.** Take a screenshot. This entry exists because we got it wrong in public.

## Run-to-run variance

**Symptom.** Two runs of the same build with the same switches: 172 ms and 220 ms median.

**Cause.** Different parts of the prologue, different draw counts, and a workload with long
tails.

**Fix.** Report the sample count, repeat the run, and never quote a single run as
representative.
