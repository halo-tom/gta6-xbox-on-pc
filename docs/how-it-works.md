# Why an Xbox Series title runs on a Windows PC at all

Four layers, in the order that matters.

## 1. The CPU is not emulated

Xbox One and Xbox Series are x86-64 machines. The title's own executable runs **as-is**
inside the layer's process. There is no instruction translation and no guest CPU.

This is the most important fact about the whole exercise, and the reason a playable state
can be reached in days rather than years. Xbox 360 emulation is a different problem:
PowerPC, an unusual GPU with an eDRAM daughter die, and no documentation - that work began
in 2008 and is still incomplete.

## 2. The platform is re-implemented

The title calls thousands of console-side functions: files, saves, input, audio and the
Xbox flavour of D3D12. Each one has to exist on Windows or be answered with something
plausible.

Our logs show how much of this is still inert. In a single run, "not on PC" entry points
were counted like this:

```
ID3D12GraphicsCommandList10::#142   6,862 calls
ID3D12GraphicsCommandList10::#75    6,797 calls
ID3D12GraphicsCommandList10::#126   6,796 calls
ID3D12CommandAllocator::#9          6,871 calls
ID3D12GraphicsCommandList10::#101      10 calls   (world load)
```

Every one of those returns a default. Some are harmless; some are why a frame is missing a
draw, or why a wait never completes.

## 3. Shaders: two routes, two worlds

The console GPU is a custom RDNA2 part. PC GPUs do not run its programs, so they have to be
translated. Two routes exist:

| | Route A (XCL) | Route B (VIctory forks) |
|---|---|---|
| Step 1 | console program -> **HLSL text** | console program -> **DXIL directly** |
| Step 2 | HLSL -> **Microsoft DXC** -> DXIL | - |
| Step 3 | DXIL -> driver | DXIL -> driver |

Route A's extra text stage can explode. We measured one program that came out as **148 MB
of HLSL**, of which **99 MB was guard code** (3,861 skip flags, up to 597 conditions on a
single statement), then became a 2 MB DXIL that the driver took **360 seconds** to
compile.

Route B's programs stay small: the same kind of title builds **about 1,800 pipelines** for
the prologue, at roughly **0.4 s each**.

The practical consequence: a layer that builds pipelines **on demand** reaches the world; a
layer that tries to build the **whole set** (57,693 pipelines in our XCL run) does not
finish in any useful time.

## 4. Unified memory is faked

Consoles share one physical memory between CPU and GPU. The title assumes a write from the
CPU is immediately visible to a shader, and the other way round.

On a PC with separate VRAM the layer has to simulate that. Both layers we measured do it by
copying and comparing:

- per frame at Series X settings: about 208 MB copied in place, about 28 MB compared, 300+
  hash passes over copies in card memory;
- at Series S settings the same counters drop by roughly an order of magnitude, simply
  because less is on screen.

This is where the two projects converge on the same wall: "which bytes did the title write"
is expensive to answer, and every answer is a scan.

## What the layers are not doing

- They are not breaking encryption. Nothing is decrypted; the executable runs.
- They are not emulating a GPU. They are translating programs.
- They are not a port. A port is recompiled and re-tuned; a layer keeps the console build
  and pays for the translation on every frame.
