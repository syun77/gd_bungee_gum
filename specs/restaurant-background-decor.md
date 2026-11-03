# レストラン背景装飾画像

`images/tilesets/restaurant_background_decor_source.png` は背景配置用の透過原画。組み込みimage_genで生成。4列×4行の16種類で、左上から行順に以下を収録。

- 観葉植物：大葉、フィカス、シダ、吊り鉢。
- 照明：クリームのペンダント、ミントのペンダント、二灯壁付け、フロアランプ。
- 窓：四角、アーチ、カーテン付き、花鉢付き横長。
- 絵画：風景、花、果物、二枚組の植物画。

クリーム・ミント・コーラルと金色金具、落ち着いた輪郭の正面ピクセルアート。背景のみ透明、窓のガラスは不透明。

## ゲーム内の利用

- `images/tilesets/restaurant_background_decor.png`：384×384 RGBAの実装用アトラス。原画の各4×4区画を切り出し、透明余白をtrim、nearestで88×88以内へ等比縮小、96×96の中央に配置。Godotの同名ファイルは `assets/tilesets/` に同一コピー。
- `gd-bungee-gum/assets/tilesets/background_decor_tileset.tres`：専用TileSet。32px配置グリッド、source0、16種類の独立した96×96（3×3セル）スタンプ。アトラス座標は列・行それぞれ0/3/6/9。装飾を一個選んで一回クリックすると全体を配置できる。
- 保存済み `scenes/stages/theater_stage.tscn` の `BackgroundDecor` を選択して編集する。nearest表示、色補正RGBA(0.82,0.86,0.84,0.85)、背景構造より前・地形やプレイヤーより後ろ。物理レイヤーなし、レイヤー衝突無効。歩行・ガムの吸着・ラッピングには影響しない。
- `scripts/stage_layout.gd` の `BACKGROUND_DECOR` が42配置（各区画7個、全16種類を使用）の正本。Vector3iは中心セルx/yと0始まりの行順装飾ID。見た目は中心から48pxずつ広がるので配置セルの周囲にも余白を確保する。
- `scripts/background_decor.gd` が保存用と生成用のレイヤー生成を共有する。`tools/build_theater_stage.gd` は他のマップ要素と一緒に再生成する。

背景装飾だけを更新し、他の手編集を保持する場合：

```sh
/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path gd-bungee-gum --log-file /tmp/decor-install.log --script res://tools/install_background_decor.gd
```

この更新は既存BackgroundDecorを配置正本で置き換える。手で装飾位置を編集した場合、再生成前に正本も更新する。

## 検証

`tools/verify_background_decor.gd` が保存配置・生成処理の一致、全16種類、3×3セル寸法、nearest、描画順と物理レイヤーなしを確認する。同じheadlessコマンド形式で実行可能。ネイティブ描画時に `-- --render` を追加すると `/tmp/restaurant-background-decor-stage.png` に入口付近を保存する。地形変更がないことは `tools/verify_theater_stage.gd` で確認する。

## 生成指示

透過背景、均等な4×4配置、各セルに独立した装飾一個、正面投影、32pxタイルゲームの64〜96px程度の表示に合うピクセル表現。観葉植物・照明・窓・絵画を各4種類。既存のクリーム／ミント／コーラルのファミリーレストランに合わせ、背景として控えめなコントラスト。人物・文字・ロゴ・壁床・グリッド線なし。
