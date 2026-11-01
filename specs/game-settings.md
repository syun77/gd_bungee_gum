# ゲームパラメータの編集

GodotのFileSystemで `res://resources/game_settings.tres` を選択し、Inspectorで編集して保存する。F5を再実行すると反映される。定義・範囲・単位の説明は `scripts/game_settings.gd` にある。

| Inspectorのグループ | 主な項目 |
| --- | --- |
| Player Movement | 走行速度、地上／空中の入力加速度、地面の摩擦、重力、蹴り出し速度、プレイヤー質量 |
| Gum Physics | ばね係数、減衰、収縮速度、最小／最大長、最大張力、緩め余裕長 |
| Aim Guide | 接着可／不可の色と透明度、補助線の太さ・破線長、照準円の半径・太さ |
| Gum Appearance | 弛緩／最大張力の色、線の太さと張力による追加幅 |
| Stage Rules | 落下時に再スタートするY座標 |

X長押し中の補助線は **Aim Valid Color / Aim Invalid Color** で変更する。カラーピッカーの **A（アルファ）** が透明度で、1が不透明。初期値は両方0.9、**Aim Line Width** は2 px。色とアルファは照準円にも適用する。描画側は `scripts/gum_connection.gd` の `_draw()`。

`scenes/game.tscn` のGameノードのSettingsが設定の参照元。Gameは起動時に同じResourceをPlayerとGumへ渡す。Player単体のシーンにも既定ファイルを割り当てる。パラメータをスクリプト側へコピーせず参照しており、接続解除時の運動量保持や双方への力の適用方式は変わらない。

マップ形状・カメラ範囲・個別の箱の質量など、配置に属する値は各シーンで編集する。アニメーションのコマや衝突用カプセルも各アセット／シーンで管理する。
