# 回収用フード画像素材

## タイルマップへの配置

- `gd-bungee-gum/scenes/stages/theater_stage.tscn` を開き、`Foods`（TileMapLayer）を選択する。下部のタイルマップパネルでシーンコレクション `Foods` から料理を選び、マップにペイントする。消去は通常のタイル消去操作。現在のマップには全6区画に6個ずつ、合計36個を配置している。下段ルート・段差/ガムリフトの着地点を案内し、高い棚にも任意回収の報酬を配置。11種類すべてを使用する。
- 専用 TileSet は `assets/foods/food_tileset.tres`。11種類のシーンは `scenes/items/foods/`、ゲーム内画像は `assets/foods/`。新規マップでもこの TileSet を TileMapLayer に指定すれば使用できる。32pxグリッド中心に配置し、64px原画を等倍・Nearestで表示する（従来の32px表示の2倍）。Sprite2Dの中心をセル中心に合わせ、32pxセルの外へ描画する。配置グリッドはそのまま。取得・ガム命中判定は中心半径36px（直径72px）の円とし、64px表示より少し広くする。
- `food_collectible.gd` の Area2D はプレイヤーの物理レイヤー2だけを監視し、`player` グループのボディ接触で一度だけ `collected(food_id)` を通知して消える。地形・箱には衝突しない。食べ物の物理ビット32をガムのレイが検出し、命中時は手元へ引き寄せる（[food-gum-reel.md](food-gum-reel.md)）。スコア・回復・永続保存は付与しない。ステージ再起動で保存された配置が復元される。
- 配置の原本は `scripts/stage_layout.gd` の `FOODS`（セルx/y・料理シーンID）。マップ生成ツールもこの配置を再現する。生成ツールの実行は原本にない手動配置を上書きするため、通常の配置編集では実行しない。
- 検証: `Godot --headless --path gd-bungee-gum --log-file /tmp/food-check.log --script res://tools/verify_food_collectibles.gd`。全11種類の実シーンタイル生成・接触回収・箱の除外・一度だけの通知・再読込を確認する。


## イタリアンプリン

- ファイル: `images/foods/italian_pudding.png`
- 64 × 64 px、RGBA PNG、透過背景。単一の静止スプライト。
- 黄色い台形状のプリン、濃いカラメルの上面とソース、細い茶色の縁がある白い皿を表現。
- built-in imagegenで添付写真を参考に生成し、可視領域を基準に最近傍補間で正規化。表示はNearestフィルター。回収用シーンタイルとして配置可能（下記の配置方法を参照）。

最終生成プロンプト:

> A tiny 16-bit pixel-art game collectible based on reference photo: Italian caramel pudding. One firm pale golden yellow custard pudding shaped as a short truncated cone, round dark reddish-brown caramel top seen as an ellipse, with a few chunky amber highlights. A pool of dark caramel sauce around its base, entirely contained in a shallow white oval ceramic plate with a thin tan rim. Slightly elevated three-quarter view, entire plate and pudding centered on square transparent canvas with padding. Simple chunky square pixel clusters on uniform 64x64 logical grid; complete dessert and plate about 56x38 logical pixels. Restrained palette, bold stepped warm dark outline, large clean yellow custard and brown caramel shapes, crisp nearest-neighbor enlarged pixel art. Actual transparent background alpha zero outside plate. NO glow, halo, shadow, backdrop, vignette, gradients, blur, antialiasing, photographic texture or fine noise. No whipped cream, fruit, mint, spoon, text, logos or extra garnish. Single static sprite.

## ペペロンチーノ

- ファイル: `images/foods/peperoncino.png`
- 64 × 64 px、RGBA PNG、透過背景。単一の静止スプライト。
- 黄色いスパゲッティ、金色のにんにくスライス、赤唐辛子、緑のパセリ、淡い色模様の白い器を表現。
- built-in imagegenで添付写真を参考に生成し、可視領域を基準に最近傍補間で正規化。表示はNearestフィルター。回収用シーンタイルとして配置可能（下記の配置方法を参照）。

最終生成プロンプト:

> A tiny 16-bit pixel-art game collectible based on reference photo: spaghetti aglio olio e peperoncino. Compact mound of pale golden yellow spaghetti loops lightly coated in olive oil, several clearly visible toasted golden garlic slices, a few short dark red chili pieces and sparse green parsley flecks. No creamy sauce, no cheese, no meat. In a shallow white ceramic bowl with subtle pale coral, cream and mint rectangular rim marks, slightly elevated three-quarter view, horizontal oval silhouette. Entire bowl centered on square transparent canvas with padding. Simple chunky square pixel clusters on uniform 64x64 logical grid, complete dish about 56x36 pixels. Restrained palette, bold stepped warm gray outline, large clean noodle loops, garlic slices and red chili accents readable at tiny size. Crisp nearest-neighbor enlarged pixel art. Actual transparent background alpha zero outside bowl. NO glow, halo, shadow, backdrop, vignette, gradients, blur, antialiasing, photographic texture or fine noise. No steam, text, logos, utensils or extra garnish. Single static sprite.

## ほうれん草のソテー

- ファイル: `images/foods/sauteed_spinach.png`
- 64 × 64 px、RGBA PNG、透過背景。単一の静止スプライト。
- 濃い緑の加熱したほうれん草、明るい茎、4切れのピンクのベーコン、細い茶色の縁がある白い器を表現。
- built-in imagegenで添付写真を参考に生成し、可視領域を基準に最近傍補間で正規化。表示はNearestフィルター。回収用シーンタイルとして配置可能（下記の配置方法を参照）。

最終生成プロンプト:

> A tiny 16-bit pixel-art game collectible based on the reference food: sauteed spinach with bacon. One shallow white ceramic bowl with thin tan rim, horizontal oval silhouette viewed slightly from above in three-quarter view. Compact mound of cooked DARK forest-green folded spinach leaves with several brighter green curved stems, topped by FOUR short pink bacon strips with creamy ivory fat ends. Keep spinach visibly cooked and dark, not salad lettuce. Simple chunky square pixel clusters on uniform 64x64 logical grid, complete bowl about 56x36 pixels. Restrained palette, bold stepped warm gray outline, large readable green leaf clusters and pink bacon accents, crisp nearest-neighbor enlarged pixel art. Entire complete bowl centered on square transparent canvas with padding. Actual transparent background alpha zero outside bowl. NO glow, halo, shadow, backdrop, vignette, gradients, blur, antialiasing, photo texture or fine noise. No steam, text, logos, utensils or additional garnish. Single static sprite.

## ハンバーグ・ステーキ

- ファイル: `images/foods/hamburger_steak.png`
- 64 × 64 px、RGBA PNG、透過背景。単一の静止スプライト。
- 濃い茶色のソースをかけたハンバーグ、目玉焼き、コーン、2本のポテト、黒い鉄板と赤茶色の木台を表現。
- built-in imagegenで添付写真を参考に生成し、可視領域を基準に最近傍補間で正規化。表示はNearestフィルター。回収用シーンタイルとして配置可能（下記の配置方法を参照）。

最終生成プロンプト:

> A tiny 16-bit pixel-art game collectible based on reference photo hamburger steak dinner. One black oval sizzling iron platter on a thin red-brown wooden base, entire platter visible centered horizontally. Large oval brown hamburger steak in front center with deep reddish-brown demi-glace sauce and a few chunky cream highlights. At back right a sunny-side-up fried egg with bright orange yolk and white edge; back center bright yellow corn mound; back left two golden rectangular potato croquettes. Slightly elevated three-quarter view. Simple chunky square pixel clusters on uniform 64x64 logical grid, complete item about 56x34 logical pixels. Restrained palette, bold stepped dark contour, clean readable food silhouettes, crisp nearest-neighbor enlarged pixel art. No fine texture, photo noise, gradients, blur or antialiasing. Actual transparent background alpha zero outside platter/base. NO glow, halo, shadow, backdrop or vignette. No steam, text, logos, cutlery or extra garnish. Single static sprite on square transparent canvas with padding.

## たらこソースシシリー風

- ファイル: `images/foods/tarako_pasta.png`
- 64 × 64 px、RGBA PNG、透過背景。単一の静止スプライト。
- 黄色いスパゲッティ、淡いピンクのたらこソース、黒緑色の刻み海苔、淡い色模様の白い器を表現。
- built-in imagegenで添付写真を参考に生成し、可視領域を基準に最近傍補間で正規化。表示はNearestフィルター。回収用シーンタイルとして配置可能（下記の配置方法を参照）。

最終生成プロンプト:

> A tiny 16-bit pixel-art game collectible based on the reference dish: Sicilian-style tarako spaghetti. A compact mound of pale yellow spaghetti loops topped with generous pale pink creamy cod roe sauce and a small mound of short dark olive-black shredded nori strips. In a shallow white ceramic bowl with subtle pale coral, cream and mint rectangular rim marks. Slightly elevated three-quarter view, horizontal oval silhouette. Entire complete bowl centered on square transparent canvas, generous padding. Simple chunky square pixel clusters on a uniform 64x64 logical grid; complete dish about 56x36 pixels. Limited palette, bold stepped warm gray outline, clean separated yellow noodles / pink sauce / dark nori, no tiny photographic texture or fine noise. Crisp nearest-neighbor enlarged pixel art. Actual transparent background alpha zero outside bowl. NO glow, halo, shadow, backdrop, vignette, gradients, blur, antialiasing, text, logos, utensils or extra garnish. Single static sprite.

## バッファローモッツァレラのマルゲリータピザ

- ファイル: `images/foods/margherita_pizza.png`
- 64 × 64 px、RGBA PNG、透過背景。単一の静止スプライト。
- 金色の耳、赤いトマトソース、5か所の白いモッツァレラ、浅い白皿を表現。小さい表示で形を保つため、持ち上げた一切れは省略してホールピザにする。
- built-in imagegenで添付写真を参考に生成し、可視領域を基準に最近傍補間で正規化。表示はNearestフィルター。回収用シーンタイルとして配置可能（下記の配置方法を参照）。

最終生成プロンプト:

> A tiny 16-bit pixel-art game collectible of buffalo mozzarella margherita pizza, based on reference photo food identity. A COMPLETE round pizza seen slightly from above in three-quarter view, horizontal oval silhouette, on a shallow white plate with subtle tan rim. Puffy pale golden crust with a few brown baked spots, vivid red tomato sauce, melted golden cheese and FIVE distinct large creamy white mozzarella patches. Keep entire pizza intact: no lifted slice, missing wedge, stretching cheese or utensils. No added toppings or basil. Simple chunky square pixel clusters on a uniform 64x64 logical grid; entire item about 56x36 logical pixels. Restrained palette, bold stepped warm dark outline, crisp nearest-neighbor pixel art, large clean shapes readable at tiny size. Single static sprite centered with transparent padding on square canvas. Actual transparent background alpha zero outside plate. NO glow, halo, shadow, backdrop, vignette, gradients, photographic texture, fine noise or antialiasing. No text or logos.

## 辛味チキン

- ファイル: `images/foods/spicy_chicken.png`
- 64 × 64 px、RGBA PNG、透過背景。単一の静止スプライト。
- 赤橙色に焼けた4つの手羽中、金色の焼き目、細い茶色の縁がある白い皿を表現。
- built-in imagegenで添付写真を参考に生成し、可視領域を基準に最近傍補間で正規化。表示はNearestフィルター。回収用シーンタイルとして配置可能（下記の配置方法を参照）。

最終生成プロンプト:

> A tiny 16-bit pixel-art game collectible sprite based on the reference food: exactly four orange-red roasted spicy chicken mid-wing pieces, two behind and two in front, piled on a shallow white oval ceramic plate with a thin tan rim. Wings are squat tapered meaty sections with crisp golden highlights and dark reddish-brown edges, no garnish or sauce bowl. Entire plate centered, slightly elevated three-quarter view, horizontal oval. Extremely simple chunky square pixel clusters on a uniform 64x64 logical grid; complete plate about 56x34 pixels. Restrained palette, bold stepped warm dark outline, crisp nearest-neighbor pixels. Actual transparent background alpha zero everywhere outside the plate. NO glow, NO halo, NO shadow, NO backdrop, NO vignette, NO gradients, NO photo texture, NO antialiasing. No text, logos, utensils or extra objects. Single static inventory sprite, square canvas with padding.

## 小エビのサラダ

- ファイル: `images/foods/shrimp_salad.png`
- 64 × 64 px、RGBA PNG、透過背景。単一の静止スプライト。
- ピンクの小エビ、緑のレタス、2個の赤いミニトマト、紫キャベツ、淡いコーラル模様の白い器を表現。
- built-in imagegenで生成し、可視領域を基準に最近傍補間で正規化。表示はNearestフィルター。回収用シーンタイルとして配置可能（下記の配置方法を参照）。

最終生成プロンプト:

> A tiny 16-bit video game inventory icon of shrimp salad in a white oval bowl. Pink curled shrimp over green lettuce, two red cherry tomatoes at right, a few purple cabbage pieces. Coral marks on bowl rim. Flat pixel art, extremely simple large square pixel clusters, dark stepped outline, about 56 by 36 pixels on a 64 by 64 logical grid. Entire bowl centered. TRANSPARENT BACKGROUND. This is a cutout sprite asset: background completely empty alpha zero. NO surrounding glow, NO halo, NO shadow, NO backdrop, NO vignette, NO gradients, NO lighting effects. Square canvas. Crisp nearest neighbor pixels.

## 若鶏のディアボラ風

- ファイル: `images/foods/chicken_diavola.png`
- 64 × 64 px、RGBA PNG、透過背景。単一の静止スプライト。
- 香味野菜とソースをのせたチキン、コーン、2本のポテト、黒い鉄板と赤茶色の木台を表現。
- built-in imagegenで生成し、最近傍補間で正規化。表示にはNearestフィルターを使用する。素材のみで、回収処理・配置は未実装。

最終生成プロンプト:

> Use case: stylized-concept. Asset type: collectible food sprite for a side-view 2D pixel-art family restaurant game. Reference image: identity and arrangement of diavola-style grilled chicken. Create a black oval sizzling iron platter on a thin reddish-brown wooden base. Main food in front/right is golden grilled chicken with pale diced onion and green herb topping and amber sauce. Behind it a bright yellow corn mound, at left two golden rectangular potato croquettes. Keep food simplified but distinct. Entire platter horizontal, slightly elevated three-quarter view, centered with transparent padding. SNES-style low-resolution pixel art drawn on a uniform 64x64 logical pixel grid: complete item about 56x32 pixels. Bold dark stepped outline, limited palette, large simple color clusters, crisp square pixels. No photo texture, no antialiasing, no blur, no fine detail, no steam, no text, no logos, no cutlery. Actual transparent background, alpha=0 everywhere outside platter and wooden base, no glow, no vignette, no ground shadow. Render clean nearest-neighbor enlarged sprite only.

## エスカルゴのオーブン焼き

- ファイル: `images/foods/escargot_oven_baked.png`
- 64 × 64 px、RGBA PNG、透過背景。単一の静止スプライト。
- 写真の茶色い専用皿、6つのくぼみ、緑のガーリックバターと茶色い具を表現。外側の白い取り皿は省略。
- built-in imagegenで生成し、最近傍補間で正規化。表示にはNearestフィルターを使用する。素材のみで、回収処理・配置は未実装。

最終生成プロンプト:

> Use case: stylized-concept. Asset type: single collectible food sprite for a side-view 2D pixel-art family restaurant game. Reference image: food identity and six-well arrangement. Create oven-baked escargots in a round terracotta brown ceramic escargot pan viewed from slightly above, appearing oval in perspective. Exactly SIX circular wells arranged one back, three middle (left, center, right), two front. Each well contains a dark brown snail morsel surrounded by bright yellow-green garlic herb butter with cream highlights, a few tiny orange accents. Omit the outer white serving plate. Single isolated complete pan centered on a square transparent canvas with generous padding. Simple SNES-style pixel art on a uniform 64x64 logical grid: pan about 56x38 logical pixels, bold stepped dark brown contour, chunky flat color clusters, restrained palette, no fine texture, no blur, no antialiasing. Clean nearest-neighbor enlarged pixels. No text, logos, utensils, steam, glow, background, vignette or ground shadow. Outside pan must be truly transparent alpha=0.

## ミラノ風ドリア

- ファイル: `images/foods/milano_doria.png`
- 64 × 64 px、RGBA PNG、透過背景。単一の静止スプライト。
- 添付写真を参考に、茶色い楕円の耐熱皿、焼き目のあるチーズ、赤茶色のミートソースを表現。スプーン・木製トレイは省略。
- built-in imagegenで生成し、最近傍補間でゲーム用サイズへ正規化。拡大表示にはNearestフィルターを使用する。
- 素材のみ。回収処理やステージ配置は未実装。Godotに組み込む際は `res://` 内へコピーする。

最終生成プロンプト:

> Edit this food sprite into a production game collectible. Keep brown oval doria dish, golden cheese, reddish meat sauce. CRITICAL: remove ALL background, dark backdrop, glow, haze, vignette and shadow: outside the dish must be fully transparent alpha=0, including every corner. Reduce detail drastically to a tiny SNES-style icon drawn on a uniform 64x64 pixel grid, enlarged with nearest neighbor only. Single square canvas, centered horizontal oval dish occupying about 56x34 logical pixels. 16-color palette, bold dark brown 1-pixel outline, large simple clusters of cheese and sauce, clean stair-step edges. No fine texture or tiny subpixels. No spoon or tray. Actual transparent background.

獲得成功時はPixelFXの共通パーティクルを再生する。接触・ガム回収とも同じ演出を使う。詳細は[アイテム獲得エフェクト](food-collect-effect.md)。
