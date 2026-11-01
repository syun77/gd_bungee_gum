# 回収用フード画像素材

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
