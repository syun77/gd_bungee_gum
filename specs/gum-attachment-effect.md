# Gum attachment effect

## Behavior

A pink gum patch squashes at the adhesion point, stretches short curved fingers and recoils into the connection over0.30seconds. A small cream highlight and rose outline remain readable on light/dark backgrounds. No hit-stop, shake, impulses, damage or changes to connection timing.

Surface effects face incoming+X with outward normal-X. They rotate to the ray-hit normal and follow the target-local surface tangent as a box rotates. Ring effects use a radial variant at the resolved tile center, independent of off-center ray-hit normals. Both follow Gum.endpoint() every render frame without inheriting target scale.

## Assets and playback

- Source atlases: `images/effects/gum_attach_{surface,ring}.png`; identical runtime copies under `gd-bungee-gum/assets/effects/`.
-256×192 RGBA,4columns×3rows;64×64px frames, pivot(32,32), nearest-neighbor filtering.
- Frames0–8 play at30fps for0.30s. Frame9 is an explicit transparent export endpoint; the final2atlas cells are unused. Runtime hides at0.30s without holding the empty sample.
- Matching JSON contains exported frame rectangles and nominal33ms durations; contact sheets and GIF previews remain under images/effects/.
- `images/effects/gum-attach.mjs` is editable procedural source importing local pixelfx core. Set radial:true for rings. The pixelfx authoring copy is src/fx/impacts/gum-attach.js.
- Included pixelfx MIT license/notices accompany source and runtime assets. No gallery font or stock character is embedded.

## Runtime ownership

Gum._attach_hit emits adhesion_started(normal,is_ring) after resolved target/local endpoint/path initialization. Direct attach_at physics fixtures share this event. Fire/miss/contract do not emit it. Gum.detach emits adhesion_ended after releasing connection state.

Game binds its reusable GumAttachmentEffect Sprite2D to these signals. Its script selects the atlas, resets frame/time and follows the connection. The node is a sibling of Gum with z_index6, above gum line z_index5. It hides on completion, release, restart or invalid/erased target; scene reload frees it with Game. Keeping one reusable node matches the single active connection limit.

All effect logic is presentation-only. Actual shot arrival remains force-free; automatic contraction starts on the following physics tick. Gum rules and reciprocal forces stay in their existing owners.

## Authoring and verification

Three visual review rounds refined rounded lobes, merged roots and curved recoil threads on light/dark backgrounds. pixelfx validation passed bounds, determinism and transparent ending; procedural rendering has a tool-runtime speed warning, with no procedural per-frame cost in Godot because playback uses textures.

Run with local Godot executable:

```bash
/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path gd-bungee-gum --log-file /tmp/gum-effect-check.log --script res://tools/verify_gum_attachment_effect.gd
```

The fixture instantiates Game and checks real outbound arrival, force-free arrival,30fps timing,0.30s expiry, rotating/translating rigid following, floor/wall/ceiling orientation, no retrigger on contraction, detach/restart clearing, miss suppression, centered ring variant and erased-tile lifecycle. Run existing verify_gum.gd, verify_controls.gd and verify_gum_anchors.gd alongside it. Interactive gameplay appearance requires F5 review.
