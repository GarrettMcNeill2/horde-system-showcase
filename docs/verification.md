# Verification record

Validated on 2026-11-01 with Godot 4.6.1, desktop Compatibility renderer, Apple M2 Pro.

| Check | Result |
|---|---|
| Editor asset import and GDScript parsing | Passed |
| Integration suite | 26 checks passed; 64, 256 and 1,024 agents |
| GPU VAT blend suite | 23 checks passed, including rendered vertex motion |
| Real viewport captures | Four 1600 × 900 PNGs saved successfully |
| Graphic layout review | Three diagrams rasterized in Chrome and visually inspected |
| Fresh-folder portability | Clean import and all 26 integration checks passed from `/tmp`, without parent files or cache |
| Snapshot integrity | Source hashes recorded; copied horde logic unchanged |

The integration suite checks navigation synchronization, spawn count, movement, spatial radius lookup, visible instance count and animation capacity for each population. It then verifies stable-ID compaction, removal of stale IDs, paused animation time, lethal damage and idempotent brain abduction. It waits for initial navigation setup before resetting the population, so no suspended initial setup is discarded during the test.

The inherited VAT suite verifies per-instance metadata, clip requests, source-clip advancement, completion, zero capacity, respawn behavior and actual rendered vertex displacement during crossfades. See `integration-results.txt` and `vat-rendering-results.txt` for the recorded assertions.

Both suites require a desktop renderer. Import assets before running either suite in a fresh clone.

## Run the checks

```sh
godot --headless --editor --path . --import --quit
godot --path . res://tests/smoke.tscn
godot --path . res://tests/open_vat_blend_test.tscn
```

## Capture screenshots

```sh
godot --path . -- --capture
python3 tools/build_diagrams.py
```

The capture command saves four viewport PNGs and exits. The Python command regenerates the SVG diagrams.

## Test coverage

Validation covers Godot 4.6.1 on an Apple M2 Pro using the Compatibility renderer. GPU API traces, GPU timings, sustained benchmarks, executable exports and Windows/Linux runtime checks remain untested. The automated checks exercise the arena methods; manual keyboard and mouse coverage is incomplete. Obstacle navigation and uneven terrain are outside this flat arena's coverage.

`media/capture-observation.json` records one capture run. Screenshot capture can affect frame metrics. For performance comparisons, keep the hardware, renderer, resolution, population, camera and target fixed, allow a warm-up period, and record frame times over a stated duration.

## Spatial-query comparison

The paired benchmark covers six population/layout combinations with identical query results, three warm-up batches and eleven timed batches per implementation. See [performance.md](performance.md) for measurements, assumptions and raw samples. The benchmark runs headless because it only exercises array queries.
