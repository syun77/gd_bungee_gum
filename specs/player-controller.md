# プレイヤー試作

F5で `scenes/game.tscn` を実行。A/Dまたは左右矢印で走り、Spaceで接触面から短く蹴り出す。Rでステージを再生成する。既存マップの閲覧は `scenes/map_preview.tscn` をF6で実行する。

`CharacterBody2D` の足元を原点とし、幅20・高さ52 pxの固定カプセルで衝突する。正規化済みTeto画像を256 pxセルで切り出し、0.3125倍で表示。待機は6コマ/6 fps、走りは8コマ/12 fpsでループ。空中はjumpの2・3・5番（0始まり）を上昇・頂点・下降に割り当て、着地時は6番を短く表示する。描画は移動や当たり判定に影響しない。

左右の意図速度と外部速度を別々に保持し、重力・蹴り出しは外部速度へ加算。地上速度220 px/s、重力1100 px/s²、蹴り出し260 px/s。空中の入力加速度は弱める。床・壁・天井に接触しているときだけ蹴り出せる。同じ接触中の連打・長押しや空中ジャンプは不可。衝突法線に向かう速度を両成分から取り除く。ガムの張力は `apply_external_force(force, delta)` で積分する。

カメラはマップ範囲内で追従する。ガムと軽・重の物理箱を実装。マウス照準、左クリックで接着、右ボタン長押しで収縮、E／中クリックで解除する。詳細は `bungee-gum-prototype.md` を参照。敵・クリア判定は未実装。全ステージ攻略の合格判定は未完了。

`Game` が毎物理ティック、接続入力→張力→`Player.simulate(delta)`→カメラ・表示の順に更新する。Player自身は `_physics_process` を持たず二重更新を避ける。カメラは移動後の位置を追う。

検証: `Godot --headless --path gd-bungee-gum --log-file /tmp/player-check.log --script res://tools/verify_player.gd`。
