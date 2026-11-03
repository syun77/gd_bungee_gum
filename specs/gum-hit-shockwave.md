# Gum hit shockwave

Actual `adhesion_started` emits one full circular screen-refraction wave centered at `gum.endpoint()`, for surfaces and rings alike. Firing, misses and contraction do not emit waves. The world-space center stays frozen when the target moves or gum releases.

`gum_hit_shockwave.gd` owns at most four independent Polygon2D ShaderMaterials. The canvas shader expands a soft annulus with eased radius, radial screen-texture displacement and a faint pink rim. It renders at Z4 beneath gum, hit particles and adhesion artwork; HUD is later in its CanvasLayer. It affects presentation only. Overlapping waves use Godot's shared screen snapshot rather than recursively refracting each other.

Shared settings group **Gum Hit Shockwave**: enabled true, radius56 world px, duration0.32s, strength4 screen px, opacity0.3. Duration0 disables emission. Radius bounds the quad; visible wave reaches88% of that radius. Progress uses process delta; each burst snapshots settings on emission. Disabling clears active waves; restart stops all waves before scene reload.

Verification: `Godot --headless --path gd-bungee-gum --log-file /tmp/gum-shockwave.log --script res://tools/verify_gum_hit_shockwave.gd` checks real arrival, exact center, force-free arrival, frozen residue, shader progress, expiry, cap, disable and cleanup. F5 visual QA should inspect refraction against painted frames/tiles at multiple camera zooms; headless logic checks do not verify rendered appearance.
