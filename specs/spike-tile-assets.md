# 即死トゲタイル画像

- `images/tilesets/restaurant_spikes.png`: 32×32px RGBA、透過背景、上向き3本のトゲを持つ単独タイル。nearest表示用。
- `images/tilesets/restaurant_spikes_source.png`: 組み込みimagegenの1254×1254px生成原本。32px版はキャンバス全体をnearest縮小し、生成alphaを保持。
- クリーム／鋼色の刃、暗いティールの輪郭、コーラルの土台。横並び配置を想定。

## 即死判定と配置

`gd-bungee-gum/scenes/stages/theater_stage.tscn` の **Spikes** TileMapLayerを選択し、専用TileSetのsource0 / scene0を塗る。32pxセル中央に画像と判定が置かれ、床の直上のセルに塗ると土台が床面に接する。シーン単体は `scenes/hazards/spikes.tscn`。現在は6区間の床に2セル列を各1組、任意の上段ショートカットに2セル列を4組、計20セルを配置。生成時の配置は `stage_layout.gd` の `SPIKES` (Vector2i配列) に記録する。生成スクリプトは手描き配置を上書きする。

Godot画像コピーは `assets/hazards/restaurant_spikes.png`、専用TileSetは `assets/hazards/spike_tileset.tres`。Nearest表示。刃3本の三角形と下部7pxの土台がArea2Dの即死判定。物理ビット64（Inspectorレイヤー7）、mask0、非ソリッド。プレイヤーや箱の移動を妨げず、既存ガムmask53から除外される。

Gameがプレイヤーカプセルと同じ形・変換を使うShapeCast2Dで、移動前の重なりとPlayer.simulate後の実移動区間を判定する。高速移動と静止中の重なりを検出し、食べ物回収ロック中も有効。トゲ側に独立した物理コールバックは持たない。

接触は `Game.restart()` を呼び、即座に以降の更新を停止、ガム接続と残留エフェクトを解除し、遅延実行で現在シーンを1回だけリロードする。Rキー・落下も同じ処理。復帰先は現在のステージ入口（チェックポイント機能なし）。箱や食べ物、接続状態も初期化される。HP・無敵時間・死亡アニメーションはない。

## 動作検証

`Godot --headless --path gd-bungee-gum --log-file /tmp/spikes-check.log --script res://tools/verify_spikes.gd`

保存レイヤー、塗り／消去、静止重なり、縦横の高速通過、安全な上方通過、ガム除外、実Gameの高速移動死・重複リロード防止・入口復帰と接続初期化を検証。

## 生成指示

Built-in image_gen, transparent_background=true. Prompt: single upward-facing instant-death spike floor tile, side-view restaurant pixel-art platformer,32px logical square grid,three sharp steel/ivory spikes,muted teal outlines,coral base spanning full width,cream highlights,transparent background,no text/perspective/scenery,nearest-neighbor style.

## 確認

原本および32px版の10倍nearestプレビューを目視確認。32×32 RGBA、背景alpha0、刃と土台の可視alpha最大254を確認。生成alphaをそのまま保持。

接触時は[消滅エフェクト](player-disappear-effect.md)を0.6秒再生してからチェックポイントへ戻る。

## 現在の配置と編集

床列（セル左端）: (10,19)、(34,21)、(64,19)、(87,21)、(119,19)、(137,21)。各2セル幅64px。接触キックの助走・着地点を残し、出入口・チェックポイント・箱の初期作業空間・ガムリフトの開始地点を避ける。上段の任意ルートは(28,9)、(64,10)、(80,7)、(116,10)に各2セル。全トゲの土台は既存のソリッド床上面に一致する。

`stage_layout.gd` の `SPIKES` を編集して `tools/install_spikes.gd` を実行すると、保存シーンのSpikesセルだけを更新する。背景装飾・地形・チェックポイントなどを再生成しない。全体生成時も同じ配列を使用する。

`tools/verify_spike_placements.gd` は保存セル・床支持・初期位置の安全距離を検証し、6床列それぞれを現行設定の実Playerで接触キックして無接触通過できることを確認する。これは局所的な回避検証。既存 `verify_stage_route.gd` は射程240px想定に対し現在の保存設定が160pxのため最初のリフトで失敗し、現在の設定で全区間の完走を保証するものではない。
