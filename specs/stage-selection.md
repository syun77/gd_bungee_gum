# ステージ選択と仮ステージ

F5の起動シーンは `res://scenes/stage_select.tscn`。クリーム・ミント・コーラルの3枚のカードに既存料理スプライトを表示する。最初の開始ボタンにフォーカスし、クリック、矢印＋Enter、Godot標準ui_accept/ui方向操作のゲームパッドで選択・開始できる。

| 番号 | 名前 | 内容 | ゲームシーン |
| --- | --- | --- | --- |
| 1 | レストラン | 既存の6区画ロングコース | scenes/game.tscn |
| 2 | リングテラス | 2048×768px、64/128pxの段差、9リング、片方向足場、料理8個 | scenes/game_stage_2.tscn |
| 3 | はこび屋キッチン | 2048×768px、箱、可動滑車、段差、9リング、料理8個 | scenes/game_stage_3.tscn |

2・3は仮コース。連続した下段床を復帰経路とし、リング・料理・箱・滑車は既存のガム／物理規則で動く。全ステージを最初から選択可能。クリア状態の保存・ロックは設けない。

Gameはstage_scene指定時にマップを差し替え、stage_widthでカメラ右端を設定する。2・3のゲームシーンは共通game.tscnの継承シーン。配置の入口はTheaterStage/PlacementMarkers、チェックポイントはCheckpoints。追加のEntranceLightBox/EntranceHeavyBox/PulleySpawnマーカーで共通ギミックを配置する。stage_catalog.gdが選択カードの名前・説明・シーンパスを管理する。

プレイ中はOPTIONS／Esc／左上「メニュー」で一時停止し、「ステージ選択に戻る」で戻る。メニューは「リトライ」「ステージ選択に戻る」「キャンセル」の3項目。新規開始はチェックポイント情報を消して入口から開始する。Rは選択したゲームシーンを再読込、死亡はそのシーン内のチェックポイントへ復帰する。出口へ接触すると操作を停止し、開扉・黒への頂点色フェード・プレイヤー消失・閉扉の完了後にSTAGE CLEARを表示する。決定ボタンで選択へ戻れる。

ステージ1の編集元は従来どおりstage_layout.gd。2・3の編集元はtools/build_provisional_stages.gdであり、実行するとscenes/stages/stage_2.tscnとstage_3.tscnだけを再生成する。共有TileSetと既存レストランは変更しない。各ゲームシーンのF6直接起動も可能。

検証: `Godot --headless --path gd-bungee-gum --log-file /tmp/stage-select-check.log --script res://tools/verify_stage_select.gd`。初期フォーカス、決定、3ステージの実シーン、床接触、リング実射、カメラ範囲、チェックポイント／R再開、ゴール、選択画面への復帰を確認する。

ステージ開始時は入口の開閉・登場演出（1.10秒）が終了するまで移動・ジャンプ・ガム操作を停止する。黒い頂点色から通常色への復帰と閉扉を同時に行う。チェックポイント復帰は省略。R・ステージ選択復帰は演出中も有効。詳細は `stage-entrance-art.md`。
