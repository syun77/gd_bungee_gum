# アイテム獲得エフェクト

食べ物の獲得成功時に、クリーム色の閃光、コーラルの輪、ミントの星状粒子を0.7秒再生する。接触・ガム回収とも `Food.collect()` が一度だけ生成する。飛行中の命中や回収中には発生しない。物理・報酬・操作タイミングは変更しない。

PixelFXの `pickups/collect-burst` を `images/effects/food-collect.mjs` で配色変更・2倍速化。編集元、透過PNG、Aseprite形式JSONは `images/effects/`、Godot用PNGは `assets/effects/food_collect.png`。PixelFX/Sprite FusionのMIT帰属は既存LICENSE/NOTICEに従う。

112×108pxセル、5列5行、22フレーム（最後は透明）、30fps。元エフェクトのアンカーは(56,84)、光の中心はそこから30px上の(56,54)。ランタイムはセル中央を獲得位置に置く。nearestフィルタ、絶対Z7。`food_collect_effect.gd` はステージ配下で独立再生し、食べ物の削除後も世界座標に残る。終了時に削除、ステージ再生成時も消える。

検証: `tools/verify_food_collect_effect.gd`、`verify_food_collectibles.gd`、`verify_food_reel.gd`。プレビューは `images/effects/food_collect_preview.png`。
