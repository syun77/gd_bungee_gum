# 出口とステージ終了演出

## 素材

静止原画は `images/tilesets/restaurant_stage_exit_source.png`。開扉原画は `images/tilesets/restaurant_stage_exit_animation_source.png`。看板は全コマEXIT、矢印なし。`tools/build_stage_exit_art.py`（Python/Pillow）が6コマを足元基準の96×128pxセル、3列×2行の288×256 RGBAに整形し、固定の上部51pxを共有する。

採用画像は `images/tilesets/restaurant_stage_exit.png` と同一の `gd-bungee-gum/assets/stage/restaurant_stage_exit.png`。nearest表示。Gameが `stage_exit.gd` のSprite2Dを3ステージ共通で作る。入口と同じ床位置解決を用い、Exitマーカーの下64px以内にある静的地形へ底を合わせる。背景装飾より前、プレイヤーより後ろに同じZで描画する。旧EXITラベルは表示しない。

## 接触とタイムライン

出口は非固体。足元から上64px、幅40pxのArea2Dでプレイヤー（物理ビット2かつplayerグループ）との接触を検出する。箱・ガムでは開始しない。距離だけではクリアしない。入口演出中・死亡中・再起動中・開始済みは新たに開始しない。

1. 接触時：操作を止め、ガムを解除・非表示、プレイヤー速度/ジャンプバッファ・残像・着地煙を消去。
2. 0〜0.40秒：6コマで開扉。キャラクターは通常色のまま。
3. 0.40〜0.90秒：全開を保持。キャラクターのAnimatedSprite2D.self_modulate RGBを元色から黒へ補間する。アルファは保持する。
4. 0.90秒：プレイヤーを非表示にし、物理レイヤーとマスクを0にして消失後の衝突もなくす。
5. 0.90〜1.30秒：扉を逆順再生して閉める。
6. 1.30秒：全閉になって初めてSTAGE CLEARの結果画面を表示する。

Gameの固定ステップが演出を進める間、通常のPlayer.simulate/Gum.stepを停止する。連打で演出や結果を重複しない。キャラクターを出口中心へワープさせず、接触位置を維持する。ワールドの剛体は通常どおり動く。OPTIONSで一時停止すると出口演出も止まり、キャンセルで続きから再開する。リトライ・ステージ選択でシーンを解放し、演出を破棄できる。

## 検証

`tools/verify_stage_exit.gd`：全3ステージで実Area接触、箱の除外、非接触時の未開始、開扉→頂点色減衰→消失/衝突無効化→閉扉→一度だけ結果、操作ロックを検証する。`verify_stage_select.gd` は接触後の閉扉完了まで待ってクリアと選択復帰を確認する。入口・一時停止・マップ検証も併用する。
