# ステージ入口と登場演出

## 採用素材

`images/tilesets/restaurant_stage_entrance_animation_entrance.png` がENTRANCE看板付き生成原画。`tools/build_stage_entrance_art.py` を Python/Pillow で実行し、96×128pxセル、3列×2行、288×256 RGBAへ切り出す。各コマの足元を揃え、固定の上部51pxを共有してひさし・看板の揺れを抑える。

採用シートは `images/tilesets/restaurant_stage_entrance.png`、同一のGodotコピーは `gd-bungee-gum/assets/stage/restaurant_stage_entrance.png`。nearest表示。矢印付き画像は原画として保持する。扉は装飾であり、衝突・ガム接着判定を持たない。

## タイムライン

`stage_entrance.gd` をGameが固定ステップで進める。

1. 0〜0.20秒：扉は全閉、キャラクター非表示。
2. 0.20〜0.60秒：6コマで開く。キャラクターはまだ非表示。
3. 0.60〜1.10秒：キャラクターを表示し、AnimatedSprite2Dの頂点色（self_modulate RGB）を黒から通常色へ補間する。同時に6コマを逆順再生して閉める。アルファは保持し、不透明な黒いシルエットから現れる。
4. 1.10秒：扉は全閉、キャラクターは通常色で操作可能。

演出中はGameが通常の入力・Gum.step・Player.simulateをスキップし、プレイヤーの全速度とジャンプバッファを毎ステップ初期化する。移動・重力・ジャンプ・ガム発射は停止。ガム照準も非表示。演出中の押下は予約しない。終了後に継続している移動入力は有効だが、ジャンプ/発射には新しい押下が必要。Rとステージ選択への復帰は演出中も有効。

## 配置とライフサイクル

3ステージ共通。PlayerSpawnから下64px以内の静的地形を調べて入口の底を合わせ、通常開始時はプレイヤーの足元も一致させる。地形がなければマーカー位置を使う。入口は背景装飾より前、Playerより後ろに同じZで配置する。既存の大きいENTRANCEラベルは廃止。

新規開始・手動Rでは再生する。有効なチェックポイント復帰では再生せず、入口は開始位置に閉じたまま残す。シーンの解放で演出も終了し、Tweenや遅延コールは残さない。

検証：`tools/verify_stage_entrance.gd`（全3ステージの順序・同時フェード/閉扉・物理/操作ロック・終了後操作・チェックポイント省略）、`verify_stage_select.gd`、`verify_controls.gd`。
