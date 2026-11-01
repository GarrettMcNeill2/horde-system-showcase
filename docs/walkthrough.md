# Try the demo

Start the project with F5. The arena opens with 256 zombies and an amber target.

1. Click an empty part of the arena to move the target. Watch the horde change direction as queued paths are processed.
2. Use the mouse wheel to zoom in. Individual zombies play the same animation at different phases and blend between clips as their state changes.
3. Press Space to pause. Use the arrow keys to orbit the camera, then press Space to resume.
4. Press K with a crowd near the target. Zombies finish their death animation before their instances are removed.
5. Press R to reset, then B to abduct the brain. The horde dies in a staggered sequence.
6. Press 1, 2 or 3 to compare populations of 64, 256 and 1,024 agents. The panel shows live agent count, occupied cells, pending paths and whole-scene rendering metrics.

Press G to toggle the grid and Tab to hide the panel. F12 saves a screenshot in `media/`.

For the implementation behind these behaviors, see [architecture.md](architecture.md). The [test instructions](verification.md) cover simulation and rendered animation checks.
