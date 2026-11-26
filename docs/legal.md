# Legal position

Short version: this repository publishes measurements and configuration, and nothing that
belongs to anybody else.

## What is in the repository

- Numbers measured on one PC: frame times, sample counts, memory figures.
- Configuration: environment variable names and values, and a launcher script.
- Prose explaining how a console x86-64 title is made to run on Windows.
- A CSV of the runs.

All of it is original work, released under the MIT licence in `LICENSE`.

## What is not in the repository

- No game assets, code, audio, video, models or text.
- No game executables, DLLs, archives or encryption keys.
- No links or instructions for obtaining any of the above.
- No compatibility-layer source or binaries; those live in their own repositories under
  their own licences (GPL-3.0-or-later for the layer used here).
- No keys, tokens or credentials of any kind.

## Why this is not circumvention

The trace of a run is:

1. a file the user already has,
2. started by a third-party compatibility layer published elsewhere,
3. on a PC, using the platform APIs Windows already provides.

Nothing is decrypted and no protection measure is bypassed. The layer translates console
GPU programs into programs the local driver can compile; that is a translation problem, not
an access-control problem.

## What a reader still needs

Their own copy of the game, obtained lawfully. This repository cannot help with that and
deliberately does not try.

## If you are a rights holder

If any part of this repository is a problem, open an issue or contact the maintainer and it
will be adjusted or removed. The content is small, and every number in it is reproducible
from public discussion by other people.

## A note on vocabulary

This repository describes translation and measurement only. It does not provide, link or
describe any means of obtaining or unlocking the game, and it deliberately avoids the
vocabulary of doing so.
