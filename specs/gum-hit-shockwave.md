# Gum hit shockwave

Actual `adhesion_started` emits one full circular screen-refraction wave centered at `gum.endpoint()`, for surfaces and rings alike. Firing, misses and contraction do not emit waves. The world-space center stays frozen when the target moves or gum releases.

`gum_hit_shockwave.gd` owns at most four independent Polygon2D ShaderMaterials. The canvas shader expands a soft annulus with eased radius, radial screen-texture displacement and a pink rim with a narrow near-white core. It renders at Z4 beneath gum, hit particles and adhesion artwork; HUD is later in its CanvasLayer. It affects presentation only. Overlapping waves use Godot's shared screen snapshot rather than recursively refracting each other.

Shared settings group **Gum Hit Shockwave**: confirmed defaults enabled true, radius80 world px, duration0.6s, strength5 screen px, opacity0.18. The wider refraction band and bright core hold through the first45% of expansion, then smoothly fade; the annulus masks the screen sample only once. Duration0 disables emission. Radius bounds the quad; visible wave reaches88% of that radius. Progress uses process delta; each burst snapshots settings on emission. Disabling clears active waves; restart stops all waves before scene reload.

Verification: `Godot --headless --path gd-bungee-gum --log-file /tmp/gum-shockwave.log --script res://tools/verify_gum_hit_shockwave.gd` checks real arrival, exact center, force-free arrival, frozen residue, shader progress, expiry, cap, disable and cleanup. F5 visual QA should inspect refraction against painted frames/tiles at multiple camera zooms; headless logic checks do not verify rendered appearance.

Radial coordinates come from local `VERTEX / quad_radius` passed as a varying, independent of texture UVs. Godot4.5 does not forward Polygon2D UVs without a texture. The expanding annulus masks the radial screen-sample displacement (same principle as the linked Qiita example); the pink/white core is additional visual feedback.

Rendered regression: run `Godot --path gd-bungee-gum --log-file /tmp/shockwave-render.log --script res://tools/verify_gum_hit_shockwave_render.gd` without headless mode. A checkerboard fixture captures before/after PNGs under `/tmp/shockwave-{before,after}.png` and asserts changed pixels. Inspect the captures for the radial distortion; lifecycle tests alone cannot detect missing shader coordinates.
