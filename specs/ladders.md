# ハシゴ

`scenes/props/ladder.tscn` をステージに配置する。原点は下端中央、`height` は高さ（既定128px）、`grab_half_width` はつかまれる横幅の半分（18px）。回転・拡大せず高さで調整する。toolスクリプトによりエディターでも高さ変更を描画へ反映する。画像は `images/restaurant_ladder.png` と `assets/props/restaurant_ladder.png` の同一PNG。nearest表示で背景に描画する。

- 足元が範囲内で上下入力するとつかまる。上下で昇降、無入力で停止。共通設定 Ladder / ladder_speed は120px/s、0で無効。
- 左右入力で離れる。Zはハシゴを足場として通常のworld-upキックを1回行う。離れる際は昇降速度を外部速度として保持する。
- ガム接続中・弾の飛行中はつかまらず、既につかまっていれば離す。ガム力・照準・長さ操作の意味は変えない。食べ物回収ロックは優先する。
- つかまった瞬間に静的ハシゴへ運動量を吸収する。昇降中は重力を加算しない。既存のmove_and_slide、地形・動的物体との接触解決を共有し、座標のスナップやテレポートは行わない。
- 昇降中のみプレイヤーの一方通行床bit8を無視し、上下端で足元の移動量を制限する。上下端への到達後は離れて通常の床判定に戻る。通常地形は通過しない。
- 離れた後の再取得には上下を一度離す。食べ物ロック・ハシゴ削除でも一方通行床マスクを復元する。
- ハシゴ自体は非衝突・ガム非対象。専用 `climb` アニメを6fpsで再生し、停止中は現在のコマを止める。左右向きは反転せず常に背面。`images/normalized/teto_climb.png` とruntimeコピーは512×256、256pxセル2個、足元y232。左コマは左手を上げ右足を下げ、右コマは右手を上げ左足を下げる。nearestの4px単位ドット。`images/teto_climb_sheet_source.png` は生成元、`images/teto_climb.png` は先に作成した参考画像として保持する。

最初の任意足場に下端(464,640)、高さ128の1本を配置。`stage_layout.gd` の `LADDERS` と保存シーン・生成処理を揃える。必須ガムリフトは維持する。

検証: `--headless --path gd-bungee-gum --log-file /tmp/verify-ladder.log --script res://tools/verify_ladder.gd`。
