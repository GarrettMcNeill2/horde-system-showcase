# Task change report

All files below are additions under `portfolio/horde_showcase/`. No parent game scene, script, setting or instruction file was changed by this task. `portfolio/.gdignore` is also new and keeps the nested Godot project out of the parent resource scan. The sibling ZIP is a distributable copy, without `.godot/`.

## How it works

The harness builds a flat navigable arena and instantiates the unchanged Horde implementation. Its player adapter supplies the small contract consumed by the horde. Physics updates write agent data and previous/current transforms; rendering interpolates transforms and uploads VAT clip metadata to the instanced vertex shader. This isolates the real horde logic without importing the vehicle, terrain, game manager or save systems. Spatial hashing narrows local queries and the queued path budget spreads work; CPU per-agent work, dense-cell candidates and extra rendering passes still scale with workload.

## Scenes, scripts, shaders and UID files

| Added project-relative path | Purpose |
|---|---|
| `portfolio/horde_showcase/addons/openvat_animated/shaders/openvat_instanced.gdshader` | Unchanged source shader: VAT interpolation, clip crossfades and material rendering. |
| `portfolio/horde_showcase/addons/openvat_animated/shaders/openvat_instanced.gdshader.uid` | New standalone resource identity for `addons/openvat_animated/shaders/openvat_instanced.gdshader`. |
| `portfolio/horde_showcase/addons/openvat_animated/src/open_vat_animation_track.gd` | Unchanged source snapshot: animation track metadata. |
| `portfolio/horde_showcase/addons/openvat_animated/src/open_vat_animation_track.gd.uid` | New standalone resource identity for `addons/openvat_animated/src/open_vat_animation_track.gd`. |
| `portfolio/horde_showcase/addons/openvat_animated/src/open_vat_blend_controller.gd` | Unchanged source snapshot: advancing-clip transitions, metadata upload and animation compaction. |
| `portfolio/horde_showcase/addons/openvat_animated/src/open_vat_blend_controller.gd.uid` | New standalone resource identity for `addons/openvat_animated/src/open_vat_blend_controller.gd`. |
| `portfolio/horde_showcase/addons/openvat_animated/src/open_vat_multi_mesh_instance_3d.gd` | Unchanged source snapshot: runtime MultiMesh and VAT JSON loading. |
| `portfolio/horde_showcase/addons/openvat_animated/src/open_vat_multi_mesh_instance_3d.gd.uid` | New standalone resource identity for `addons/openvat_animated/src/open_vat_multi_mesh_instance_3d.gd`. |
| `portfolio/horde_showcase/scenes/enemies/horde.tscn` | New minimal horde scene using source logic, runtime mesh loading and required lifecycle children. |
| `portfolio/horde_showcase/scripts/custom_objects/dev_settings.gd` | Unchanged source snapshot: effect configuration autoload. |
| `portfolio/horde_showcase/scripts/custom_objects/dev_settings.gd.uid` | New standalone resource identity for `scripts/custom_objects/dev_settings.gd`. |
| `portfolio/horde_showcase/scripts/custom_objects/enums.gd` | Unchanged source snapshot: shared enums. |
| `portfolio/horde_showcase/scripts/custom_objects/enums.gd.uid` | New standalone resource identity for `scripts/custom_objects/enums.gd`. |
| `portfolio/horde_showcase/scripts/enemies/horde.gd` | Unchanged source snapshot: brain/agent state, movement, navigation scheduling, spatial queries, combat, compaction and VAT integration. |
| `portfolio/horde_showcase/scripts/enemies/horde.gd.uid` | New standalone resource identity for `scripts/enemies/horde.gd`. |
| `portfolio/horde_showcase/scripts/enemies/horde_hit_geometry.gd` | Unchanged source snapshot: exact overlap helpers. |
| `portfolio/horde_showcase/scripts/enemies/horde_hit_geometry.gd.uid` | New standalone resource identity for `scripts/enemies/horde_hit_geometry.gd`. |
| `portfolio/horde_showcase/scripts/player/player_attack_area.gd` | Unchanged source snapshot: shape contract and stable-ID hit bookkeeping. |
| `portfolio/horde_showcase/scripts/player/player_attack_area.gd.uid` | New standalone resource identity for `scripts/player/player_attack_area.gd`. |
| `portfolio/horde_showcase/showcase/grid.gdshader` | New antialiased reference grid in one shader plane. |
| `portfolio/horde_showcase/showcase/grid.gdshader.uid` | New standalone resource identity for `showcase/grid.gdshader`. |
| `portfolio/horde_showcase/showcase/main.tscn` | New standalone entry scene. |
| `portfolio/horde_showcase/showcase/player.gd` | New minimal Player adapter: target hook, physics RID, discovery and damage reception. |
| `portfolio/horde_showcase/showcase/player.gd.uid` | New standalone resource identity for `showcase/player.gd`. |
| `portfolio/horde_showcase/showcase/showcase.gd` | New arena, navigation surface, population presets, controls, live counters and repeatable viewport capture harness. |
| `portfolio/horde_showcase/showcase/showcase.gd.uid` | New standalone resource identity for `showcase/showcase.gd`. |
| `portfolio/horde_showcase/tests/open_vat_blend_test.gd` | Unchanged inherited 23-check test script, including rendered crossfade motion. |
| `portfolio/horde_showcase/tests/open_vat_blend_test.gd.uid` | New standalone resource identity for `tests/open_vat_blend_test.gd`. |
| `portfolio/horde_showcase/tests/open_vat_blend_test.tscn` | New minimal runner for inherited VAT checks. |
| `portfolio/horde_showcase/tests/smoke.gd` | New 26-check graphical integration suite for all populations and lifecycle invariants. |
| `portfolio/horde_showcase/tests/smoke.gd.uid` | New standalone resource identity for `tests/smoke.gd`. |
| `portfolio/horde_showcase/tests/smoke.tscn` | New integration test runner. |
| `portfolio/horde_showcase/tools/build_diagrams.py` | New standard-library SVG diagram generator. |

## Other additions

| Added project-relative path | Purpose |
|---|---|
| `portfolio/horde_showcase/.gitignore` | Standalone documentation or ignore rules. |
| `portfolio/horde_showcase/CREDITS.md` | Standalone documentation or ignore rules. |
| `portfolio/horde_showcase/README.md` | Standalone documentation or ignore rules. |
| `portfolio/horde_showcase/addons/openvat_animated/shaders/LICENSE.txt` | Preserved third-party license notice. |
| `portfolio/horde_showcase/art/anims/zom/Zombie_Mesh.003-remap_info.json` | Copied existing zombie model, texture, VAT bake or remap metadata. |
| `portfolio/horde_showcase/art/anims/zom/Zombie_Mesh.003_vat.exr` | Copied existing zombie model, texture, VAT bake or remap metadata. |
| `portfolio/horde_showcase/art/anims/zom/Zombie_Mesh.003_vat.exr.import` | Godot import metadata for copied asset. |
| `portfolio/horde_showcase/art/anims/zom/zombie.glb` | Copied existing zombie model, texture, VAT bake or remap metadata. |
| `portfolio/horde_showcase/art/anims/zom/zombie.glb.import` | Godot import metadata for copied asset. |
| `portfolio/horde_showcase/art/anims/zom/zombie.png` | Copied existing zombie model, texture, VAT bake or remap metadata. |
| `portfolio/horde_showcase/art/anims/zom/zombie.png.import` | Godot import metadata for copied asset. |
| `portfolio/horde_showcase/docs/.gdignore` | Documentation, provenance, recorded verification or Godot import exclusion. |
| `portfolio/horde_showcase/docs/architecture.md` | Documentation, provenance, recorded verification or Godot import exclusion. |
| `portfolio/horde_showcase/docs/integration-results.txt` | Documentation, provenance, recorded verification or Godot import exclusion. |
| `portfolio/horde_showcase/docs/portfolio-copy.md` | Documentation, provenance, recorded verification or Godot import exclusion. |
| `portfolio/horde_showcase/docs/source-manifest.json` | Documentation, provenance, recorded verification or Godot import exclusion. |
| `portfolio/horde_showcase/docs/vat-rendering-results.txt` | Documentation, provenance, recorded verification or Godot import exclusion. |
| `portfolio/horde_showcase/docs/verification.md` | Documentation, provenance, recorded verification or Godot import exclusion. |
| `portfolio/horde_showcase/media/.gdignore` | Godot import exclusion for website media. |
| `portfolio/horde_showcase/media/01-overview.png` | Actual Godot viewport capture. |
| `portfolio/horde_showcase/media/02-close-view.png` | Actual Godot viewport capture. |
| `portfolio/horde_showcase/media/03-spatial-grid.png` | Actual Godot viewport capture. |
| `portfolio/horde_showcase/media/04-hero.png` | Actual Godot viewport capture. |
| `portfolio/horde_showcase/media/capture-observation.json` | Single-run scene observation; not a benchmark. |
| `portfolio/horde_showcase/media/gpu-pipeline.png` | Workflow graphic; SVG source or rasterized PNG. |
| `portfolio/horde_showcase/media/gpu-pipeline.svg` | Workflow graphic; SVG source or rasterized PNG. |
| `portfolio/horde_showcase/media/spatial-and-lifecycle.png` | Workflow graphic; SVG source or rasterized PNG. |
| `portfolio/horde_showcase/media/spatial-and-lifecycle.svg` | Workflow graphic; SVG source or rasterized PNG. |
| `portfolio/horde_showcase/media/workflow.png` | Workflow graphic; SVG source or rasterized PNG. |
| `portfolio/horde_showcase/media/workflow.svg` | Workflow graphic; SVG source or rasterized PNG. |
| `portfolio/horde_showcase/project.godot` | New Godot 4.6 Compatibility configuration with standalone entry and copied effect-settings autoload. |
| `portfolio/horde_showcase/resources/mats/zombie.tres` | Copied zombie appearance with parent resource UIDs removed. |
| `portfolio/horde_showcase/tools/.gdignore` | Keep nonruntime files out of the Godot resource scan. |
| `portfolio/horde_showcase/docs/change-report.md` | This complete task-specific inventory. |

## Verification

Godot 4.6.1 import passed. Desktop integration: 26/26 checks. VAT controller and real-rendering tests: 23/23. Four actual screenshots saved. All three diagrams rendered and visually checked. Fresh-folder import and 26/26 integration checks passed without the parent project or cache. Source snapshots checked against recorded SHA-256 hashes.

No raw GPU API trace, GPU timings, sustained benchmark, executable export, cross-platform runtime test or public push was performed. Garrett McNeill confirmed that he created the zombie artwork and approved its inclusion in the portfolio demonstration. Earlier headless dummy-renderer diagnostics are excluded from the supported test workflow; final desktop checks passed cleanly.

## Artwork attribution follow-up

Updated `CREDITS.md` and `docs/portfolio-copy.md` to credit Garrett McNeill for the zombie artwork and record his approval to include it. Updated this report and rebuilt `portfolio/horde-showcase.zip`. No scenes, scripts, shaders, UID files or runtime assets changed in this follow-up. Verified that outdated artwork-clearance warnings were removed and the ZIP matches the current project files.
