# チェックポイント

## 動作

卓上札にプレイヤーが触れると、その札を奈落死・トゲ接触時の復活ポイントにする。最後に触れた札が優先され、以前の札に戻って触れた場合も更新する。未到達時の死亡は入口へ戻る。

死亡時はGameシーンを遅延再ロードする。復活位置は札の足元から上へ2px。速度、ガム、演出、箱、食品などのステージ状態は初期化する。復活先の札はチェックマークで表示し、再生を繰り返さない。他の札は未到達表示に戻る。Rまたはメニューの「リトライ」による手動リスタートはチェックポイントを解除して入口へ戻る。アプリ終了後の保存は行わない。

## 配置・画像

`scenes/props/checkpoint.tscn` は足元原点の再利用可能なArea2D。幅52×高さ56pxの非固体領域でプレイヤーのbit2だけを検出する。ガムや箱の対象にはならない。`TheaterStage/Checkpoints` の子として配置する。`scripts/stage_layout.gd` のCHECKPOINTSが5か所の既定配置を持ち、保存済みシーンと生成スクリプトを揃える。

画像は `images/props/restaurant_checkpoint_flip_source.png` と同一の `assets/props/restaurant_checkpoint.png`。4列×2行をnearestで表示し、各コマ0.055秒、最後のコマで停止する。くすんだコーラルの旗（太い旗竿＋右向き三角旗）からミント色のチェックマークへ8コマで横軸回転し、揺り戻しなしで停止する。画像は生成ソースの分割表示。各コマの台座の不透明部分の下端を足元原点に合わせ、透明余白で地面から浮かないようにする。

## 所有と検証

札は接触通知と画像再生を担当し、Gameが復活先を管理する。死亡時だけSceneTreeの一回限りのメタデータへシーンパスと札NodePathを渡し、新しいGameが消費する。削除された札や別シーンの記録は入口へフォールバックする。既存の単一リスタート経路を共有し、同時の死亡要求でも一度だけ再ロードする。

`tools/verify_checkpoints.gd` は実プレイヤー接触、全8コマと最終コマの保持、奈落・トゲの再ロード、最新地点への更新、速度／ガム初期化、手動解除、未登録時の入口復帰を検証する。`verify_spikes.gd`、`verify_controls.gd`、`verify_theater_stage.gd` も併用する。

## 画像編集

未到達側4コマの編集原画は `images/props/restaurant_checkpoint_flag_edit.png`。組み込みimagegenで生成し、札の内側だけを既存アトラスへ合成して台座・透明余白・有効側4コマを保持した。

編集プロンプト: “Use case: precise-object-edit. Edit target: supplied 4-column 2-row checkpoint sprite atlas. Replace ONLY the pink circular ring symbols in the TOP FOUR frames with one consistent simple checkpoint FLAG icon: thick vertical pole at left and solid triangular pennant pointing right, muted dusty coral, readable at small size. Match each frame's existing horizontal-axis rotation/vertical foreshortening (upright, partly tilted, strongly tilted, almost edge-on). Keep icon centered on cream sign. Keep ALL sign frames, cream panels, mint borders, coral stands, positions, scale, transparent padding and layout exactly unchanged. Bottom four frames with mint checkmarks MUST remain unchanged. Pixel art matching existing style, transparent background, no text, no circle/ring symbols.”

## 周囲のPixelFX

左右の台座脇から光の粒が短い尾を引き、50px上昇して札の斜め上で最大10px幅の星になり消える。左右を1秒ずらし、各側2秒で一巡。未到達はクリーム＋淡いコーラル、登録後はミント＋クリーム。途中から明るくなり、上端で星と局所グローが膨らんで消える。2秒ループ・30fps、96×96pxセル、10列×6行・60コマ。中央の札を避け、nearestで等倍表示する。

初回接触では待機演出を隠し、左右のミント色の短い弧（明色の芯を含む2px幅）が外へ膨らんで戻る。0.4秒でチェック完成に合わせ最大9px幅の6個の星が局所グローとともに上・左右へ弾け、0.8秒で消えて登録後ループへ移る。128×96pxセル、5列×5行・25コマ（最終透明）、30fps。輪で囲まない。再接触では再生せず、復活時は登録後ループのみ。札とともにシーン再生成で破棄される。

原点は足元（待機48/80、到達64/80）。`checkpoint_effect.gd` が非物理の子Sprite2Dを生成し、親のZ+1で描画する。接触・復活判定は従来のGame所有のまま。

編集ソースは `images/effects/checkpoint-idle.mjs` と `checkpoint-activate.mjs`。`node tools/build_checkpoint_effects.mjs` でローカルPixelFXコアから `checkpoint_{idle,active,activate}.png` とGodot側の同名コピーを再生成する。外部パッケージは不要。`verify_checkpoints.gd` は待機ループ、実接触での単発再生、0.4秒同期、再接触、0.8秒後の切替、復活時の再生抑止を検証する。
