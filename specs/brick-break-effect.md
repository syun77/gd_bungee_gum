# ブロック破壊エフェクト

バンジーガムで茶色レンガを壊すと、マスの中心でクリーム色の短い衝撃光、赤茶色の回転する破片12個、細かい砂粒、薄い土ぼこりを再生する。約0.5秒で縮小・消滅。演出に衝突や追加の力はない。

- 編集原本: `images/effects/brick-break.mjs`。リポジトリのPixelFX coreを使用し、seed固定の座標・速度・回転から描画する。
- 出力: `images/effects/brick_break.png` と同名のGodot `assets/effects/` コピー。RGBA・512×512px、128×128pxセル、4列×4行、16フレーム（15可視＋透明終端）、30fps、ピボット(64,56)。nearest表示。
- `brick_break.json`: PixelFX/Aseprite形式メタデータ。`brick_break_contact.png`: 全フレーム一覧。`brick_break_preview.gif`: 拡大アニメーションプレビュー。
- 再生成: `node tools/build_brick_break_effect.mjs`（画像・メタデータ・一覧を両ディレクトリへ出力。GIFは確認用成果物）。Node18以上、PixelFX checkoutが必要。

`breakable_terrain.gd` は破壊成功時だけ `brick_break_effect.gd` をステージへ追加する。ワールド座標のセル中心に固定し、Z7、Sprite2D offset(0,8)でピボットを合わせる。連続破壊は独立して再生。0.5秒で自動削除、ステージの破棄でも削除。通常地形への命中・照準では生成しない。破壊処理、ガムの戻り、物理への力は既存ルールを使う。

検証: PixelFXのchecker（原本を一時的なcustomラッパーで登録）で決定性・範囲・透明終端・速度に警告なし。全フレーム一覧で3回調整。`tools/verify_breakable_terrain.gd` は実際の命中から発生数・中心座標・連続再生・画像スライス・フレーム進行・終了時削除・通常地形での非発生を確認する。

破片の射出係数は水平1.9・鉛直1.65。高速の砂粒と広がる土ぼこりを伴い、0.5秒の中で回転・落下・縮小する。透明キャンバスは飛散範囲を収める128pxで、元の破片サイズと実行時スケールは一定。
