# 音符アイテム画像

- 配置用画像: `images/items/music_note.png`。32×32px、RGBA透過PNG、単一静止スプライト。Nearestフィルターを使う。
- 生成原画: `images/items/music_note_source.png`。1254×1254px。built-in imagegenで生成し、アルファを保って最近傍補間で32pxへ縮小。
- コーラルピンクの八分音符、バーガンディの輪郭、クリーム色のハイライト。日常的な小得点アイテムの候補。プレイヤー接触で回収できる。取得時に10点を加算する。
- 検証: 原画/32px版の透過と寸法、32px版を8倍Nearest表示してシルエットを確認。

## 最終生成プロンプト（built-in imagegen）

> Use case: stylized-concept. Asset type: single collectible tile sprite for a side-view 2D pixel-art game featuring a pop-colored family restaurant and a singing heroine. Generate exactly ONE coral-pink eighth music note (♪), isolated and centered on a square truly transparent canvas. Recognizable silhouette: rounded oval notehead at lower left, sturdy upright stem rising on its right, one short flag curling right at the top. Front-facing flat icon, no perspective. Tiny charming SNES-style pixel art on a uniform logical32x32 grid, enlarged nearest-neighbor: complete note occupies about22x26 logical pixels with clear transparent padding. Chunky square pixel clusters, dark muted burgundy stepped outline, saturated coral-pink main fill, one simple pale cream/pink highlight and deeper rose underside; limited 5-color palette, large clean shapes that read at32px. Modest everyday low-score pickup, not a lavish trophy. No tile border or backing plate, no coin, no text, no extra notes, no stars, no particles, no glow, no cast shadow, no gradients, no blur, no antialiasing, no checkerboard baked into image. Actual alpha0 background outside the single complete note.

## 待機アニメーション

- 再利用用シーン: `res://scenes/items/music_note.tscn`。Area2Dに32px等倍のSprite2Dを持ち、通常の子シーンとして配置する。画像は `assets/items/music_note.png`。取得時に10点を加算する。ステージでは下記の専用TileSetを使う。
- `scripts/music_note.gd` がハイライト3秒周期と縦軸回転4秒周期を管理。ハイライトは通常2.4秒、続く0.6秒でsin²の滑らかな山を作り、中央2.7秒で最大になる。シーンツリーのポーズに従う。
- `shaders/music_note.gdshader` が既存クリーム色の画素だけを最大45%淡いクリームへ混ぜる。外周発光や粒子はない。
- 縦軸回転は正面→右32度→正面→左32度→正面を4秒で往復する。横向きになるまで一周させず、圧縮補正で正面幅を94%以上保つ。最大約2pxの暗い側面と弱い遠近/陰影をシェーダーで描き、奥行きを表現する。元PNGとSprite/Area2Dのscaleは変更しない。Nearestの画素単位サンプリング、透明余白内で完結。
- 回収判定の位置・半径18px・ルートの変形は固定。見た目の回転は物理に影響しない。
- 各インスタンスは独立したマテリアルを持つ。初期ワールド位置から周期の位相を決め、列状配置の一斉点滅と回転同期を避ける。
- 確認: `scenes/music_note_preview.tscn` を開いてF6。落ち着いたティール背景に3個を表示する。
- 検証: `Godot --headless --path gd-bungee-gum --log-file /tmp/music-note-check.log --script res://tools/verify_music_note.gd`。シーン読み込み・寸法・位相/マテリアル独立・通常区間・ピーク・両周期・回転角/正面幅下限・回収判定固定・ポーズ/再開を確認する。

## ステージ配置

- 全3ステージの `MusicNotes`（TileMapLayer）に配置。専用TileSetは `assets/items/music_note_tileset.tres`、シーンコレクションの音符を32pxグリッドにペイントできる。レストラン70個、リングテラス25個、はこび屋キッチン22個、合計117個。
- 平地は原則2〜3セル間隔、段差手前とガム上昇箇所は上向きの列にする。大きな料理の周囲は48px以上空け、料理自体も進行の目印として使う。静的な安全空間の確認であり、全音符を連続取得する物理経路は保証しない。
- 配置原本は `scripts/music_note_layout.gd` のRESTAURANT/TERRACE/KITCHEN。保存マップと同時に更新する。レストランの生成ツールも同じRESTAURANT配置を使用する。生成ツールはマップ全体を上書きするため、音符だけの編集には実行しない。
- 音符は移動を遮らないArea2D。中心半径18pxで、物理レイヤー2かつ`player`グループのボディとの接触を検出する。接触すると即座に非表示になり、共通の`item3.wav`（score_item）取得音と`collected()`通知を一度だけ発生させて削除する。1個につき10点を加算し、取得位置の上に「10」を表示する。文字は0.65秒で32px上昇しながら消える。能力回復・追加パーティクルは付与しない。ガムの対象外（collision_layer=0）で、箱では回収されない。シーンツリーのポーズに従い、手動リトライ・新規開始で配置が復元し、死亡復帰では取得済み状態とスコアを保持する。
- 検証: `Godot --headless --path gd-bungee-gum --log-file /tmp/music-note-placement-check.log --script res://tools/verify_music_note_placement.gd`。全保存セルとアニメーションインスタンス数、24×28px範囲の地形/一方通行足場/トゲ非重複、料理中心との48px以上の距離を確認。

## 回収の検証

`Godot --headless --path gd-bungee-gum --log-file /tmp/music-note-pickup.log --script res://tools/verify_music_note_pickup.gd` で全3ステージの実シーンタイルへの物理接触、箱/非playerグループの除外、ガムレイ対象外、ポーズ中の回収停止、再読込復元、同一フレームでの重複要求による二重通知防止、10点の一度だけの加算、文字の上昇・消滅、タイムアタックのスコアとタイマーの併記を確認する。

数字演出は `scripts/score_popup.gd` をフランスパン・食べ物と共用し、数字はクリーム色・縁取りは白（4px）とする。専用 `resources/score_popup_theme.tres` のDefault Font／Default Font SizeとLabelのColors（Font Color／Font Outline Color）、Constants（Outline Size）で調整する。スクリプト側のスタイル上書きはなく、他のUIテーマとは独立する。得点と表示は `ContactPickup.points`（音符10・フランスパン30）および `FoodCollectible.POINTS`（300）を参照する。ラベルをアイテムの外側に所有させ、回収による削除後も演出を継続する。
