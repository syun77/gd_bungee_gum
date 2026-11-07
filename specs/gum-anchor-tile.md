# ガム接着専用リング画像

## 素材

- `images/tilesets/restaurant_gum_anchor.png`: 32×32px、透過RGBAの単独タイル。
- `gd-bungee-gum/assets/tilesets/restaurant_gum_anchor.png`: Godot用の同一コピー。
- `images/tilesets/restaurant_gum_anchor_enlarged_source.png`: 組み込みimagegenの編集原本。
- `images/tilesets/restaurant_gum_anchor_source.png`: 編集入力のデザイン原本。

ミントの輪、クリームの内縁、茶色の輪郭、コーラルの接着マークを使用する。中央の穴と外周は透明。既存レストランの配色に合わせ、足場と混同しにくい開いた輪形とする。32pxセル、nearest表示で使う。

編集原本をImageMagickでtrimし、point補間と透明余白で32×32へ正規化。最終可視範囲はx/y=1〜30（30×30px）、中央と外周1pxは透過。RGBA・寸法・可視範囲・中央透過・Godotコピーのバイト一致を確認し、10倍nearestプレビューを目視確認した。

## TileMapでの配置

`scenes/stages/theater_stage.tscn` の `GumAnchors` を選び、TileSetのsource ID **2**、アトラス座標 **(0,0)** の輪を描く。32pxグリッド、衝突生成はONのまま使用する。`TerrainTiles` などの衝突生成OFFのレイヤーではガム判定も生成されない。

保存済みマップの12個はセル(5,12)、(7,9)、(10,7)、(22,10)、(25,8)、(38,10)、(43,8)、(60,14)、(62,8)、(90,11)、(120,14)、(138,16)に配置。生成時の配置は `scripts/stage_layout.gd` の `GUM_ANCHORS` が管理し、`tools/build_theater_stage.gd` で再生成する。手描きした配置はシーンに保存できるが、再生成時はこの配列に戻る。

source0の(5,6)も輪に見えるが装飾用で、接着判定を持たない。配置にはsource2を使う。

## 判定の扱い

TileSetのphysics layer index1を物理ビット16（Inspectorのレイヤー5、GumAnchors）に割り当て、mask0とする。プレイヤーmask77・箱mask73はこのビットを含まないので、両者とも通過できる。ガムのレイクエリはmask53（地形1・動的物体4・接着点16・食べ物32）。既存の一方向床8は検出しない。

接着判定はタイル中央を中心とする48×48pxの八角形。見た目30×30pxより各辺方向へ9px広く、32pxセルの外にも8px張り出す。見た目は変えず、輪の少し外を通る発射も受け付ける。角は8px切り落とすため48px四方の全域が有効ではない。形状の定義は `scripts/stage_layout.gd` の `GUM_ANCHOR_POLYGON` とし、生成器がこれを使用する。中央の穴を含むため、輪の中心を狙って接着できる。PNGの透明部分自体は判定を定義しない。静的な接着点として既存の張力・収縮・解除ルールを使い、他の輪は巻き付き障害物にならない。接着点を消すかレイヤーの衝突を無効にすると接続が失効する。ガムは当たった衝突RIDのセルを取得し、当たり位置に関わらずタイル中央へ接着する。照準マーカー・到着時の先端・自然長と経路の初期値も中央を使う。最大接続長は中央までの距離で判定する。地形・箱は実際の命中位置に接着する。発射原点がアンカー判定の内部にある場合も接着できる。飛行中の先端命中後に行う経路確認では、命中したアンカーのセルRIDだけを除外し、同じ輪を遮蔽物として誤判定しない。他のアンカー・地形・箱の判定は維持する。

`GumAnchors` の Physics Quadrant Size は **1** とし、1セルにつき独立した衝突RIDを持たせる。拡大判定がセル外へ張り出していても正しい輪を識別できる。既定の16ではRIDが区画単位になり、中央のセルを特定できない。ガムは中央のローカル座標と衝突RIDの有効性を追跡し、レイヤー変換に追従する。

## 検証

```sh
/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path gd-bungee-gum --log-file /tmp/gum-anchors.log --script res://tools/verify_gum_anchors.gd
```

保存済み12点のsource・衝突生成・実レイ接着を検証。同じTileSetの独立した空間でプレイヤー/箱の通過、見た目の外側を通る四方向レイと実発射・斜めの接着、範囲外での不成立、収縮張力、描画/消去/無効化時の判定を確認する。

## 生成指示

組み込み `image_gen`、既存PNGを編集入力として透過背景指定。最終編集プロンプト:

```text
Use case: precise-object-edit. Edit target: supplied 32x32 transparent pixel-art gum anchor ring. Change ONLY size: enlarge existing ring from22px visible diameter to30px visible diameter inside the SAME square32x32 logical canvas, centered,1px transparent margin all four sides. Preserve mint enamel, cream inner rim, brown outline, four coral cardinal grip marks and hollow transparent central hole. Same front view and pixel-art design, nearest-neighbor style crisp pixels, same proportions. No extra elements, no backplate, no floor, no text, no shadow, no background. Genuinely transparent outer area and center. Output may uniformly upscale logical32px but occupy94percent of canvas width/height.
```
