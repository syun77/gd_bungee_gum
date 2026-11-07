# 壊せるブロックのタイル画像

- `images/tilesets/restaurant_breakable_block.png`: 32×32px、透過RGBAの単独タイル。
- `images/tilesets/restaurant_breakable_block_source.png`: 組み込みimagegenの生成原本。
- `gd-bungee-gum/assets/tilesets/restaurant_breakable_block.png`: 同一バイトのGodot用コピー。

クリーム色の陶板、コーラルの縁、暗い青緑の輪郭と枝分かれしたひび。レストランの既存タイル配色に合わせる。nearestフィルタで表示する。画像のみであり、TileSet登録・破壊処理・配置は未実装。

生成プロンプト（組み込みimagegen、要約）: “Single front-view breakable ceramic block tile; cream face, coral rim, dark teal outline, prominent branching cracks, chipped corners; 32×32 logical pixel art, transparent background, no text or scenery.”

原本をImageMagickのpoint補間で32×32へ正規化。寸法、RGBA、透明部分、ランタイムコピーの一致を検証し、10倍nearestプレビューでひびの視認性を確認した。

## 茶色レンガ案

`images/tilesets/restaurant_breakable_brick.png` は32×32px RGBA・全面不透明の赤茶色レンガ案。`restaurant_breakable_brick_source.png` が生成原本。Godotの `assets/tilesets/` に同一コピーを保存。nearest表示。陶板案は別画像として保持する。茶色版は共有TileSetに登録済みで、ガム命中で破壊できる。

組み込みimagegenで既存原本を編集。プロンプト: “Recolor only: terracotta brown face, ochre brown rim, chocolate cracks/outline, tan chips/highlights; preserve square silhouette and crack shapes; fully opaque flat face, no holes, no dark patches, no text or scenery.” 原本をpoint補間で32px化し、寸法・RGBA・全面不透明・コピー一致を検証、10倍プレビューで目視確認。

## 配置方法

共有 `assets/tilesets/theater_tileset.tres` のソースID **4**、アトラス座標 **(0,0)** を `TerrainTiles` に配置する。レストランとTime Attackで共通。MapEditではGodotからステージをコピーし直すと、配置種別「破壊可能ブロック」が表示され、そのタイル欄で「茶色レンガ」を選べる。地形のタイル欄には重複表示しない。MapEdit更新後は再起動が必要。MapEditから反映すると既存の地形矩形・輪郭再構築に含まれる。Godotで直接配置する場合も、地形変更時の通常手順でTerrainの矩形・輪郭を更新する。

タイル自体には専用コリジョンを持たせず、Terrainが地形の衝突を所有する。画像はnearest表示。ステージ生成ツールも同じソースIDを登録する。既存マップへの追加配置は行っていない。破壊前は通常の地形として衝突し、ガム先端の命中で消える。

MapEditの「破壊可能ブロック」の色設定は、TerrainTilesのソース4/(0,0)を判別して配置済みセル・配置プレビュー・ミニマップへ反映する。通常の地形の色とは独立する。この設定はエディタ内の表示色で、Godotの画像自体は変更しない。

## ガムによる破壊

実際のOUTBOUND先端スイープがTerrainTilesのソース4/(0,0)に命中すると、1発で命中した1マスだけを消去する。隣のレンガと通常地形は残す。ガムは接着・収縮・力の適用をせず、その命中位置から通常の戻り動作に入る。READY照準や既存の接続線が触れただけでは壊さない。通常地形への接着は同じルールを継続する。

`breakable_terrain.gd` がヒット面の0.1px内側から対象セルを特定し、残存セルを共有 `terrain_rectangles.gd` で矩形化してTerrainの衝突とレストランのRimを更新する。ガムの地形ジオメトリは次の経路更新で形状変更を検出する。実行中インスタンスだけを変更し、保存シーンは変更しない。死亡・リトライ等のシーン再読込で配置が復元する。

検証: `tools/verify_breakable_terrain.gd` は実レイによる隣接2ブロックの逐次破壊、1マス限定、無張力、穴を通った通常地形への再接着、巻き付きジオメトリの穴、保存シーン再読込を確認する。

破壊時はPixelFXのレンガ片・土ぼこりをセル中心で0.5秒再生する。画像仕様と再生成は `specs/brick-break-effect.md` を参照。

破壊成功時の音は `sounds/crash.wav`（SoundEffectsのcrashキュー）。通常の接着成功はhitキューを使う。
