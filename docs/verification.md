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

Both suites require a desktop renderer. A headless trial exercised simulation assertions but Godot's dummy renderer produced MultiMesh buffer diagnostics; it is not the supported validation command. The final graphical suites passed without those diagnostics.

## Commands

```sh
godot --headless --editor --path . --import --quit
godot --path . res://tests/smoke.tscn
godot --path . res://tests/open_vat_blend_test.tscn
godot --path . -- --capture
python3 tools/build_diagrams.py
```

## Limits

No raw GPU API capture, GPU timestamp profile, sustained benchmark, executable export, Windows/Linux run, or public GitHub push was performed. Controls are exercised through the harness and integration methods; a full manual keyboard/mouse acceptance pass was not recorded. The flat arena does not prove obstacle navigation or uneven-terrain behavior. Asset import is required before running tests in a fresh clone.

`capture-observation.json` is one short capture-run observation. FPS and process time in screenshots are transient whole-scene observations, not a comparative performance study. The screenshot process itself can affect frame metrics.

For publishable performance numbers, run each population after warm-up, record hardware/OS/Godot/renderer/resolution, keep camera/target/seed fixed, gather frame-time samples for a stated duration, and compare medians and tail latency. Use the engine profiler to separate scripting, navigation, physics and rendering; use a renderer-compatible graphics debugger for the actual API command stream.
