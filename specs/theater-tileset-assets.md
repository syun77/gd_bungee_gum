# ファミリーレストラン用タイルセット

## 採用ファイル

- `images/tilesets/theater_tileset.png`: 採用アトラス。512 × 512 RGBA、32 × 32セル、16列、余白・間隔0。105セル使用、151セル透明。
- `gd-bungee-gum/assets/tilesets/theater_tileset.png`: Godot用の同一コピー。`theater_tileset.tres` が105セルを参照する。
- `images/tilesets/restaurant_tileset_source.png`: 組み込みimagegenで編集した1254 × 1254 RGBA原本。
- `specs/theater-tileset-atlas.json`: 0始まりのアトラス座標と形状分類。`source_cell` は形状制作時の `theater_tileset_source.png` のセル対応を示し、色編集原本の座標ではない。

舞台は明るいファミリーレストラン。暖色のクリーム色の陶板、コーラルの縁、ミントのラインと塗装フレーム、金色の金具、茶色の輪郭を使う。ファイル名の `theater` は現行リソースの識別名。

| ID（両端含む） | 形状分類 | 数 |
| --- | --- | ---: |
| 0–55 | 地形の形状候補 | 56 |
| 56–64 | 地形差分 | 9 |
| 65–78 | 塗装フレーム | 14 |
| 79–88 | 背景 | 10 |
| 89–96 | 透過装飾 | 8 |
| 97–104 | 案内・警告 | 8 |

## 整形と確認

imagegen編集後、ImageMagickのpoint補間で512 × 512へ正規化し、元アトラスのアルファを復元。黄緑色の強いフリンジを暖かい金茶色へ調整した。Pillowは読み取り検証にのみ使用。

寸法・RGBA、元画像とのアルファバイト完全一致、105使用セル・151透明セルを確認。形状、透過穴、セル配置は既存マップと同一。描画色を変えても衝突形状は変わらない。Godotでテクスチャを再インポートし、保存済みマップの物理検査とOpenGL実描画を確認した。

32 px、nearest表示で使用する。背景・装飾に衝突を付けず、地形判定は `Terrain` の静的矩形へ集約する。マップの背景は落ち着いたティール、地形の輪郭は茶色、区画名はクリーム色。

本画像は手置き素材。47近傍パターンの網羅性・シームレス接続は未検証で、JSONの近傍マスクは `null`。タイルの縁や反復模様には継ぎ目がある。家具・料理・店舗設備はこの画像に含めていない。案内・危険表示は絵だけで、ゲーム判定は別実装。

## 使用した最終プロンプト

組み込み `image_gen` の画像編集を使用。入力は既存アトラス、透過背景を指定。

```text
Use case: precise-object-edit. Edit target: the provided production pixel-art tile atlas. Change ONLY its colors and surface material appearance into a cheerful Japanese family restaurant interior palette: warm vanilla cream ceramic/painted surfaces, restrained coral red accents, fresh mint/turquoise trim, honey yellow details, warm brown outlines. Existing stone blocks should read as clean colorful ceramic wall/floor masonry, metal structural pieces as painted mint restaurant fixtures. Keep general terrain bright cream and warm beige, reserve coral and mint for trim and occasional tile variants. Background wall tiles darker muted teal for foreground contrast. Signage bright teal and golden yellow. Keep texture clean, playful, crisp pixel art. CRITICAL invariants: exact same composition, exact same 16 by 16 atlas grid, 105 tiles in identical cells, identical silhouettes and cutouts, identical size and position of every tile and icon. Input is 512x512 pixels with 32x32 cells: preserve this logical resolution (if output upscaled use exact uniform nearest neighbor scaling). First 105 cells occupied, all remaining cells completely TRANSPARENT. No added restaurant furniture, food, lettering, new tiles, grids, checkerboard, background or shadows outside original silhouettes. Preserve real alpha transparency. This is a color/material edit of an engine asset, not a scene illustration.
```

## 一方通行床用の追加画像

`images/tilesets/restaurant_one_way_platform.png` と同名の `gd-bungee-gum/assets/tilesets/` コピーを使用する。128 × 32 RGBA、32pxセル4列、nearest表示。既存アトラスとは独立した画像で、既存105セルの配置は変えない。

| セル（0始まり） | 用途 |
| --- | --- |
| (0, 0) | 左端 |
| (1, 0) | 反復する中央 |
| (2, 0) | 右端 |
| (3, 0) | 1セル単独 |

上端y=0、棚板は高さ10px、残りは透明。クリーム色の天板、ミント色の前縁と金色の小金具で、厚い通常地形と区別する。左端→中央の反復→右端で水平に接続する。生成原本は `images/tilesets/restaurant_one_way_platform_source.png`。組み込みimagegenで生成・厚み編集後、point補間で128×32のグリッドへ整形した。厚み編集の指示は「上端とX方向・配色を保ち、棚板のY方向の厚みだけを5pxから10pxへ2倍にする。残りは透明」。

`theater_tileset.tres` のsource ID 1に登録済み。`OneWayPlatforms` レイヤーで配置すると、上端y=0〜5pxの一方向衝突が生成される。source ID 0の既存タイルに衝突は付けない。使い方・物理仕様は `specs/one-way-platforms.md` を参照。

## ガム接着専用タイル

`restaurant_gum_anchor.png`（32×32 RGBA）をsource ID2に登録。衝突生成ONの`GumAnchors`で配置し、プレイヤー・箱は通過、ガムだけ接着する。物理ビット16、TileSet physics layer index1。既存source0/1の形状・用途は維持。詳細は `specs/gum-anchor-tile.md`。
