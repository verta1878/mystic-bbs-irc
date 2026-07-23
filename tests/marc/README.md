# MARC test suite

Verifies `marc` (the built-in ZIP archiver + media-tag reader) end to end.

## Running

```
MARC=/path/to/marc ./tests/marc/run.sh
```

If `marc` is on your PATH or in the current directory, just:

```
./tests/marc/run.sh
```

To also exercise media tags, point at a sample file:

```
MARC=./marc MARC_MP3=/path/to/song.mp3 ./tests/marc/run.sh
```

## What it checks

1. **ZIP round-trip** - pack two files, extract, compare byte-for-byte.
2. **List** - `marc l` shows the packed entries.
3. **FILE_ID.DIZ** - the exact extraction Mystic does on upload.
4. **FidoNet bundle** - a fake `.pkt` packed into a `.mo0` bundle and back;
   proves the `.pkt` (FTS-0001, opaque to marc) survives compression intact.
5. **QWK packet** - CONTROL.DAT + MESSAGES.DAT round-trip (QWK = ZIP).
6. **Media tags** - optional; reads MP3/MP4 tags if a sample is supplied.

No live 4MB packet is needed: each case uses a small controlled fixture and
checks the round-trip, which is what actually matters.

## Why this matters

FidoNet bundling, QWK packets and FILE_ID.DIZ extraction all flow through
Mystic's `ExecuteArchive()`. Dropping a `marc` entry into the Archive Editor
makes all three use the built-in engine with no external tool, on every target
(Windows / Linux / Darwin / FreeBSD / OS/2 / DOS-go32v2).
