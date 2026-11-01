# Website copy and presentation

## Project card

**Horde System — Godot / GDScript / GPU animation**

An isolated demo of my Zmail horde system, combining array-based enemy simulation, budgeted path requests, spatial queries and instanced vertex animation.

## Case study

I built the horde around shared simulation data rather than one scene tree per enemy. The brain coordinates group intent, while individual state machines handle movement, attacks, effects and death. Navigation requests are scheduled across physics ticks so a crowd can share a bounded queued-path budget.

A spatial hash narrows local queries for separation and combat. Stable agent IDs keep deferred work valid when dead agents are removed by swapping the last live entry into their slot. This avoids shifting every surviving entry while preserving animation state.

For rendering, I integrated MultiMesh instancing with the project's OpenVAT runtime. Per-instance clip metadata drives vertex animation on the GPU. The blend controller keeps both source and destination clips advancing during transitions, and render transforms interpolate independently from animation frame metadata.

This standalone version removes the vehicle and terrain dependencies and presents the system in a controlled arena. It includes selectable populations, target placement, pause, damage and brain-abduction controls. The implementation's limits remain visible: AI and navigation run on the CPU, dense spatial cells can be costly, and instancing does not remove extra render passes.

## Captions and alt text

| Asset | Caption | Alt text |
|---|---|---|
| `04-hero.png` | Zmail horde system in a standalone Godot arena. | Animated zombie instances converge on an amber target on a dark gridded arena. |
| `01-overview.png` | 256-agent demonstration with live scene metrics. | Elevated horde view with population, spatial cell, path queue and rendering metrics. |
| `02-close-view.png` | Per-instance movement and animation around the target. | Closer view of animated zombies moving toward and surrounding a target. |
| `03-spatial-grid.png` | A 5 m reference grid aligned with the spatial hash. | Arena viewed from above with grid lines showing the scale of spatial cells. |
| `workflow.svg` | Fixed simulation and render update responsibilities. | Six connected stages from brain behavior through agent updates, navigation, combat, animation and rendering. |
| `gpu-pipeline.svg` | CPU simulation feeds instanced GPU vertex animation. | CPU data and resource updates flow into VAT vertex deformation and fragment rendering. |
| `spatial-and-lifecycle.svg` | Spatial lookup and stable-ID compaction. | Diagram showing cell-based candidates and how stable IDs survive removal of an array slot. |

## Suggested page sequence

1. Hero capture and the short project description.
2. Overview or close view with interaction notes.
3. Simulation workflow and CPU/GPU diagram.
4. Stable IDs, navigation budget and spatial-query tradeoffs.
5. GitHub link, OpenVAT credit, and zombie artwork credit to Garrett McNeill.

## 60–90 second recorded walkthrough

- Launch at 256 agents; click to reposition the target.
- Zoom closer to show independent animation phases and clip transitions.
- Pause and orbit to inspect the crowd; resume.
- Press K near a cluster to show completed death clips and compacted live instances.
- Reset, then abduct the brain to show staggered death scheduling.
- Briefly show 64 and 1,024 agents as supported workloads; do not describe them as a benchmark.
- Finish with the CPU/GPU diagram and the repository's source map.

Use the first-person copy only where it accurately reflects your own contribution. The zombie artwork is credited to Garrett McNeill; retain the OpenVAT credits. Add numerical performance claims only after a separate reproducible benchmark on the hardware you name.
