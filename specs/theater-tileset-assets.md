# 劇場タイルセット画像・初版

## ファイル

- `images/tilesets/theater_tileset.png`: 512 × 512 RGBA、32 × 32セル、16列。間隔・余白0。先頭105セルを使用、残り151セルは透明。
- `images/tilesets/theater_tileset_source.png`: 組み込みimagegenで生成した1254 × 1254の原本。
- `specs/theater-tileset-atlas.json`: 各セルのID、分類、アトラス座標、ピクセル矩形、原本セルの対応表。座標は左上起点・0始まり。

| ID（両端含む） | 分類 | 数 |
| --- | --- | ---: |
| 0–55 | 石材の形状候補 | 56 |
| 56–64 | 石材差分 | 9 |
| 65–78 | 鉄骨 | 14 |
| 79–88 | 背景 | 10 |
| 89–96 | 透過装飾 | 8 |
| 97–104 | 案内・警告 | 8 |

本画像は手置きマップ用の初版素材。仕様の美術方向・セル寸法に合わせたが、生成された形状の内訳は設計の99セルと異なる。47近傍パターンの網羅性・シームレス接続・物理判定は未検証であり、近傍マスクはJSONで `null` としている。自動接続用に登録する前に、類似形状の整理、欠ける形状の追加、連続面の継ぎ目調整が必要。危険表示は絵だけであり、物理・進行処理を持たない。

## 整形と確認

原本は指定の16列ではなく14列で生成されたため、ImageMagickで各セルを整数座標切り出し、境界の生成線を除き、補間なしで32 × 32へ縮小して16列に再配置。アルファを50%閾値で二値化した。Pythonはコマンド呼び出し・JSON出力・読み取り検証に使用し、画像描画には使用していない。

寸法512 × 512、RGBA、アルファ0/255のみ、105セルに可視画素あり、未使用151セルは透明であることを検証。完成シートを目視確認した。Godotには未導入。インポート時は32 × 32、マージン0、セパレーション0、補間なしを使い、背景・装飾へ地形の衝突を付けない。

## 生成プロンプト

組み込み `image_gen` を使用。下記を原本生成の最終指示として与えた。続けて16列への再配置編集も試したが、列数が改善しなかったため、採用原本を機械的に整列した。

Use case: stylized-concept. Asset type: production pixel-art TILE ATLAS, NOT a scene or mockup.
Create a precise square transparent PNG sprite sheet for a side-view 2D game set in an abandoned theater converted into a physics training facility. Target logical atlas 512x512 pixels, exactly 16 columns x16 rows of 32x32 logical pixel cells, no margins or spacing. If output higher resolution, keep exactly this grid and use nearest-neighbor enlarged pixel art. Strict orthographic front view, crisp pixel clusters, no antialiasing, no shadows outside cells, no lettering, no numbers, no visible grid.
Palette: dark blue gray stone #344655 #526978 with restrained edge #91A5AD, dark iron; background #171D2B #293346; small mint #9AD5C2 and amber #E5B85C symbols. No pink, no characters.
Layout: first 99 cells occupied, packed row-major; remaining 157 cells completely transparent.
Cells 0-46: 47 blob-autotile configurations of solid blue-gray masonry terrain. All tile solids fill the ENTIRE 32px cell: no inset border or padding. Adjacent terrain must join without seams. Only exposed edges have thin bright rim and dark outer contour; interior connections have NO border. Include full interior, straight top/bottom/left/right exposed edge, convex corners, concave corner notches, thin horizontal/vertical runs, isolated block, ends, all multi-corner combinations. Quiet subtle masonry texture; minimal cracks. Walls and ceiling as clear as floors.
Cells 47-54: eight subtle masonry alternatives, four full interior tiles, two top-edge and two bottom-edge.
Cells 55-70: sixteen dark iron structural beam tiles, solid full-cell width/thickness, rivets restrained: horizontal left/middle/right, vertical top/middle/bottom, four elbows, four T junctions, cross, isolated.
Cells 71-82: twelve darker low-contrast background tiles: four masonry fills, two vertical seams, two horizontal seams, four arch quarters. No bright terrain rim.
Cells 83-90: eight transparent overlay decals: two tiny hairline cracks, two rivet arrangements, two recessed panels, two brackets.
Cells 91-98: eight transparent symbol decals: left arrow, right arrow, entrance emblem, exit emblem, section marker, two amber diagonal warning stripe variations, target emblem. Icons without text.
Do not include crates, projectiles, exit door sprites or distant scenery in this atlas. Do not draw a display board or checkerboard transparency. Every tile strictly within its exact grid cell, no gutters, no labels. This is a utilitarian usable game atlas rather than illustrated catalog.
