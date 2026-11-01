# Provenance and redistribution

The project packages the horde implementation from **Zmail / Wildcat Game Studios** for Garrett McNeill's portfolio. The new standalone harness, diagrams and documentation were prepared for this showcase. The zombie artwork was created by Garrett McNeill. Third-party tooling is credited separately.

- `scripts/enemies/horde.gd`, geometry helpers, effect configuration, enums and attack-area script: copied from the working project. See `docs/source-manifest.json` for exact checksums.
- `addons/openvat_animated/`: runtime components copied from the project's OpenVAT integration. The instanced shader credits Antz (2026) in its source. Existing blend-controller changes are preserved. Describe the portfolio work as horde architecture and its VAT integration; attribute OpenVAT tooling separately.
- The existing OpenVAT shader-folder MIT notice is preserved verbatim at `addons/openvat_animated/shaders/LICENSE.txt` and names Luke Stilson (2024). Its stated scope is OpenVAT engine tools; the core OpenVAT tool has a separate license. No Blender addon or core baking tool is bundled here.
- `art/anims/zom/`: zombie artwork created by Garrett McNeill, including the model and texture used by the bundled VAT assets. Garrett confirmed ownership and approved inclusion in the public portfolio demonstration.

The zombie artwork is cleared by its creator for inclusion in this showcase. No blanket license has been assigned to the source project or artwork; preserve the included third-party notices.
