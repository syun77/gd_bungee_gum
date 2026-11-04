# 音符アイテム画像

- 配置用画像: `images/items/music_note.png`。32×32px、RGBA透過PNG、単一静止スプライト。Nearestフィルターを使う。
- 生成原画: `images/items/music_note_source.png`。1254×1254px。built-in imagegenで生成し、アルファを保って最近傍補間で32pxへ縮小。
- コーラルピンクの八分音符、バーガンディの輪郭、クリーム色のハイライト。日常的な小得点アイテムの候補。プレイヤー接触で回収できる。得点処理は未実装。
- 検証: 原画/32px版の透過と寸法、32px版を8倍Nearest表示してシルエットを確認。

## 最終生成プロンプト（built-in imagegen）

> Use case: stylized-concept. Asset type: single collectible tile sprite for a side-view 2D pixel-art game featuring a pop-colored family restaurant and a singing heroine. Generate exactly ONE coral-pink eighth music note (♪), isolated and centered on a square truly transparent canvas. Recognizable silhouette: rounded oval notehead at lower left, sturdy upright stem rising on its right, one short flag curling right at the top. Front-facing flat icon, no perspective. Tiny charming SNES-style pixel art on a uniform logical32x32 grid, enlarged nearest-neighbor: complete note occupies about22x26 logical pixels with clear transparent padding. Chunky square pixel clusters, dark muted burgundy stepped outline, saturated coral-pink main fill, one simple pale cream/pink highlight and deeper rose underside; limited 5-color palette, large clean shapes that read at32px. Modest everyday low-score pickup, not a lavish trophy. No tile border or backing plate, no coin, no text, no extra notes, no stars, no particles, no glow, no cast shadow, no gradients, no blur, no antialiasing, no checkerboard baked into image. Actual alpha0 background outside the single complete note.

## 待機アニメーション

- 再利用用シーン: `res://scenes/items/music_note.tscn`。Area2Dに32px等倍のSprite2Dを持ち、通常の子シーンとして配置する。画像は `assets/items/music_note.png`。得点処理は未実装。ステージでは下記の専用TileSetを使う。
- `scripts/music_note.gd` が3秒周期を管理。通常2.4秒、続く0.6秒でsin²の滑らかな山を作り、中央2.7秒で最大になる。シーンツリーのポーズに従う。
- `shaders/music_note_highlight.gdshader` が既存クリーム色の画素だけを最大45%淡いクリームへ混ぜる。輪郭・透過・コーラル色の本体・位置・大きさは固定。外周発光や粒子はない。
- 各インスタンスは独立したマテリアルを持つ。初期ワールド位置から周期の位相を決め、列状配置の一斉点滅を避ける。
- 確認: `scenes/music_note_preview.tscn` を開いてF6。落ち着いたティール背景に3個を表示する。
- 検証: `Godot --headless --path gd-bungee-gum --log-file /tmp/music-note-check.log --script res://tools/verify_music_note.gd`。シーン読み込み・寸法・位相/マテリアル独立・通常区間・ピーク・周期・変形なし・ポーズ/再開を確認する。

## ステージ配置

- 全3ステージの `MusicNotes`（TileMapLayer）に配置。専用TileSetは `assets/items/music_note_tileset.tres`、シーンコレクションの音符を32pxグリッドにペイントできる。レストラン70個、リングテラス25個、はこび屋キッチン22個、合計117個。
- 平地は原則2〜3セル間隔、段差手前とガム上昇箇所は上向きの列にする。大きな料理の周囲は48px以上空け、料理自体も進行の目印として使う。静的な安全空間の確認であり、全音符を連続取得する物理経路は保証しない。
- 配置原本は `scripts/music_note_layout.gd` のRESTAURANT/TERRACE/KITCHEN。保存マップと同時に更新する。レストランの生成ツールも同じRESTAURANT配置を使用する。生成ツールはマップ全体を上書きするため、音符だけの編集には実行しない。
- 音符は移動を遮らないArea2D。中心半径18pxで、物理レイヤー2かつ`player`グループのボディとの接触を検出する。接触すると即座に非表示になり、共通の`item`取得音と`collected()`通知を一度だけ発生させて削除する。得点・能力回復・追加パーティクルは付与しない。ガムの対象外（collision_layer=0）で、箱では回収されない。シーンツリーのポーズに従い、ステージ再読込で配置が復元する。
- 検証: `Godot --headless --path gd-bungee-gum --log-file /tmp/music-note-placement-check.log --script res://tools/verify_music_note_placement.gd`。全保存セルとアニメーションインスタンス数、24×28px範囲の地形/一方通行足場/トゲ非重複、料理中心との48px以上の距離を確認。

## 回収の検証

`Godot --headless --path gd-bungee-gum --log-file /tmp/music-note-pickup.log --script res://tools/verify_music_note_pickup.gd` で全3ステージの実シーンタイルへの物理接触、箱/非playerグループの除外、ガムレイ対象外、ポーズ中の回収停止、再読込復元、同一フレームでの重複要求による二重通知防止を確認する。
