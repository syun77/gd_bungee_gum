# トゲ接触時の消滅エフェクト

PixelFX coreを使う編集元は `images/effects/player-disappear.mjs`。クリーム色の短い閃光、ピンクの膨らみ、放射状に飛散して縮む粒で消滅を表現する。血や身体の破片は含まない。

- `player_disappear.png`: 128×128pxセル、5列×4行、19フレーム（最後は透明）、30fps、0.6秒。中心ピボット(64,64)、nearest、ループなし。JSONと全フレーム確認用PNGも同じディレクトリ。
- Godotコピー: `assets/effects/player_disappear.png`。`player_disappear_effect.gd` が固定ステップで再生する。PixelFXの帰属は既存のpixelfx-LICENSE.txt / pixelfx-NOTICE.mdに従う。
- Gameのトゲ判定成立時、プレイヤーとガムを即座に非表示にして接続と残像を消去し、移動・入力更新を停止する。ShapeCastの安全移動率から接触時点の体中心を求め、そのワールド位置で一度だけ再生する。カメラも接触位置に固定する。
- 0.6秒後に既存のチェックポイント再開を実行する。チェックポイント未到達なら入口へ戻る。Rと画面外落下は即時再開のまま。シーン再生成でエフェクトも破棄する。
- 検証: `tools/verify_spikes.gd`。実移動の高速接触・初期重なり・単発再生・途中フレーム・死亡中の移動停止・復帰を確認する。
