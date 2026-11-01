# ゲームパラメータの編集

GodotのFileSystemで `res://resources/game_settings.tres` を選択し、Inspectorで編集して保存する。F5を再実行すると反映される。現在の基準値は蹴り出し速度400 px/s、Coyote Time 0.20秒、ガム最大長400 px、射程240 px、発射速度1200 px/s。保存済み設定とスクリプトの初期値を揃えている。定義・範囲・単位の説明は `scripts/game_settings.gd` にある。

| Inspectorのグループ | 主な項目 |
| --- | --- |
| Player Movement | 走行速度、地上／空中の入力加速度、地面の摩擦、重力、蹴り出し速度、Coyote Time（床離脱後の猶予秒数）、プレイヤー質量 |
| Player Contact | 接触余白0.75 px、反発係数0.1、深度補正率0.8、分離速度上限120 px/s |
| Gum Physics | ばね係数、減衰、収縮速度、最小／最大長、最大張力、手動延長／短縮速度、手動延長上限の安全余裕 |
| Gum Flight | 先端速度、回収速度、回収表示の最大寿命 |
| Gum Wrapping | 支点のクリアランス、解除離隔・確認ティック、支点数・経路修正の上限 |
| Aim Guide | 接着可／不可の色と透明度、補助線の太さ・破線長、照準円の半径・太さ |
| Gum Appearance | 緩めモードの色（Gum Loosen Color、初期値 #B8A6AD）、収縮中の無張力／最大張力の色、線の太さと張力による追加幅 |
| Diagnostics | Landing Diagnostics：着地不安定の調査ログ、Jump Diagnostics：接地キックの調査ログ（両方初期値ON） |
| Camera Zoom | 通常／長距離時の倍率、距離範囲、追従速度 |
| Stage Rules | 落下時に再スタートするY座標 |

READY時に表示する命中予告の補助線（発射から回収完了までは非表示）は **Aim Valid Color / Aim Invalid Color** で変更する。カラーピッカーの **A（アルファ）** が透明度で、1が不透明。初期値は両方0.9、**Aim Line Width** は2 px。色とアルファは照準円にも適用する。方向入力にかかわらず`Aim Guide Opacity`（0.3）をアルファに掛け、常に薄く表示する。描画側は `scripts/gum_connection.gd` の `_draw()`。

`scenes/game.tscn` のGameノードのSettingsが設定の参照元。Gameは起動時に同じResourceをPlayerとGumへ渡す。Player単体のシーンにも既定ファイルを割り当てる。パラメータをスクリプト側へコピーせず参照しており、接続解除時の運動量保持や双方への力の適用方式は変わらない。

マップ形状・カメラ範囲・個別の箱の質量など、配置に属する値は各シーンで編集する。アニメーションのコマや衝突用カプセルも各アセット／シーンで管理する。

巻き付き時の最大長・手動延長上限・自然長は総経路長に適用する。初期設定はクリアランス1 px、解除離隔2 pxを2ティック確認、支点16個・修正32回まで。

`Landing Diagnostics`がONの場合、横移動用速度に1 px/sを超える上下成分が生じたとき、`[LandingDiagnostic]`ログをGodotのOutputと標準ログへ出す。発生時、最初の接地変化6回、以後60物理ティックごとの要約、解消時を記録する。座標・両速度・接地変化・アニメーション・着地タイマー・ガム接続と張力・衝突法線を含む。衝突時に入力用の縦成分を除外した際はCONTROL_COLLISION_RESOLVED、高速着地時はHIGH_SPEED_LANDINGを出力する（詳細は30ティック間隔）。衝突前の速度と除外した縦成分も含む。通常の待機・歩行では出力しない。

カメラはプレイヤーを追従し、通常は `camera_normal_zoom`（1.5倍）。Godotの倍率は大きいほど近く、小さいほど広く映る。Xによる照準ズームは設けない。

接続中はガムの総経路長（巻き付き支点を含む）が `camera_gum_zoom_start`（200 px）から `camera_gum_zoom_end`（800 px）へ伸びるにつれ、通常倍率から `camera_long_gum_zoom`（1.0倍）へ線形に引く。自然長や張力では判定しない。接続中は経路長だけを判定し、未接続時は通常倍率へ戻る。通常より近づく設定値は採用しない。終了距離が開始距離以下なら開始距離で切り替える。

倍率は `camera_zoom_response`（5 /秒）の指数応答で滑らかに変化し、0なら即時切り替え。解除後も同じ応答で戻る。起動・再スタートは通常倍率から始まる。カメラの位置追従とシーンの範囲制限は維持するため、画面端ではキャラクターが中央からずれることがある。

`Jump Diagnostics`がONの場合、Zの押下要求ごとに`[JumpDiagnostic]`を出力する。`ACCEPTED`は接地キック実行、`ACCEPTED_COYOTE`は床離脱猶予中のキック、`REJECTED_NO_CONTACT`は接触なし、`REJECTED_NOT_REARMED`は前回のキック後に床接触または完全な非接触ティックを経ていないための拒否。直後の`AFTER_MOVE`には同じ物理ティックの移動後状態と衝突前速度を記録する。`REARMED`は床接触または完全な非接触による再使用可能化の直前状態を示す。座標・床／壁／天井接触・使用可否・Z/X保持・入力／外部速度・衝突法線・ガム接続を含む。要求時の接触は前回の`move_and_slide()`の結果。Zは押下エッジ入力のため、押し続けても要求ログは繰り返さない。ガム接続状態はGameによるZの切断処理後。

`Coyote Time`は初期値0.20秒（0で無効）。ジャンプ診断の`coyote`は残り秒数を示す。床・コヨーテでは真上へ速度を加算し、成功時に残り時間を0にする。

コヨーテキックでは、猶予中に重力で増えた下向き速度だけを補正してから`Kick Speed`を加算する。`Coyote Time`を延ばしても重力による相殺は増えないが、入力までに落ちた位置は戻さない。補正量用の追加設定はない。

角での斜めジャンプ調査では、`KICK_APPLIED`の`source`（floor/wall/ceiling/coyote）、キック方向`normal`、上向きからの符号付き角度`angle_from_up_deg`、加算速度`impulse`、猶予重力補正`compensation`、`external_before/after`、合成した`launch`を比較する。`ACCEPTED`と`AFTER_MOVE`の`contacts`には衝突相手のノードパス・接触点・法線・深さを記録する。`floor_normal`／`wall_normal`、実移動速度`real_velocity`と移動量`position_delta`も出力する。要求時のこれらの接触・実移動値は前回の移動結果、`AFTER_MOVE`は今回の結果。接地法線とキック方向の違い、残存する横速度、移動時の衝突の影響を分けて確認できる。床・コヨーテの`normal`は常に`(0, -1)`、`compensation`の横成分は0。

手動長さ調整は`manual_extension_speed`（180 px/s）、`manual_shortening_speed`（90 px/s）、`manual_length_margin`（240 px）で調整する。自動収縮は`contraction_speed`（180 px/s）。手動延長上限は最大長から安全余裕を引き0〜最大長に制限する。保存基準では160 px。

接続中のガムは同じ経路に半透明のハロー4層、基本色の線、細い明るい芯を重ねて発光感を出す。折り返し点と接着点にも適用する。Gum Appearance の **Gum Glow Radius**（初期8 px）、**Gum Glow Opacity**（0.12）、**Gum Core Brightness**（白の混合率0.65）で調整する。半径または不透明度0でハローを無効化できる。緩めモードの基本色は灰色寄りのまま。描画のみの効果で、周囲への照明や物理への影響はなく、ポストエフェクトに依存しない。

**Attachment Range**（`attachment_range`、初期240 px）は先端の累積飛行距離と照準の射程。**Maximum Length**（`maximum_length`、初期400 px）は接続後に伸びられる総経路長の切断上限で、巻き付き経路を含む。両者は独立して編集できる。例えば射程400／最大長800なら400 px以内に接着し、その後800 pxまで伸びられる。手動自然長の上限はMaximum Length−Manual Length Margin。射程を最大長より長くしても、最大長を超える位置には接着できず照準も接着不可になる。

`Gum Flight`の`gum_shot_speed`は先端の直進速度（1200 px/s）、`gum_return_speed`は回収経路の短縮速度（3200 px/s）、`gum_return_max_duration`は回収表示の最大寿命（0.25秒）。飛行・回収はガム力を発生させず、接着成立の次更新から既存の物理計算を行う。飛行・回収の長さは経路長ズームに使用しない。

`Gum Diagnostics`（初期値ON）は切断時に`[GumDiagnostic] DETACH`を出力する。切断理由、状態／モード、両端位置、プレイヤー速度／外部速度、接続先パス・回転・ローカル接着点・剛体速度／質量、経路長・自然長・上限・経路点・ピボット数・修復回数・失敗理由を含む。`HISTORY`は力のリセット前に保存した直近8ステップ（前ステップの張力／力、今回のdelta／長さ入力）の履歴。動的障害物による切断はレイ区間、検出物、接続先自身かを示す`is_target`、衝突位置／法線／shapeも記録する。通常の接続中は出力せず、手動切断・飛行失敗・再起動も切断理由で区別する。GodotのOutputまたは標準出力ログで確認し、InspectorのDiagnosticsから無効化できる。経路更新失敗時の経路点／長さは最後に完成した経路の場合があるため、現在の両端位置・previous位置と併せて読む。

`Pinning Diagnostics`（初期値ON）はプレイヤーと剛体のスライド接触、または深い接触で移動できない状態を調査する。剛体が接触一覧から欠落しても、接触深度1 px以上・衝突前速度10 px/s以上・1ステップの実変位0.1 px未満なら`stalled_penetration=true`として記録を継続する。`rigid_contact`、`deepest_contact`、`slide_count`も含む。`[PinningDiagnostic] CONTACT_STARTED`で直前8ステップの`HISTORY`と現在状態を出力し、接触中は30物理ティックごとに`PERSISTING`、移動／Z／X／上下入力またはガム状態・モードの変化時に`ACTION_CHANGED`、剛体接触も深い接触による停滞も報告されなくなると`CONTACT_ENDED`を出す。挟まったと断定する検出ではなく、通常のブロック接触も対象。入力、キック可否・猶予、移動前後位置・実変位、衝突前の入力／外部／合成速度、move_and_slide直後速度、衝突整理・摩擦後の入力／外部速度、床・壁・天井、safe_margin／max_slides、接触相手・法線・深度・位置・相手速度、剛体の質量・回転・速度・sleep/freeze、ガムの状態・張力・両端力・長さを含む。イベント時の`nearby`はプレイヤー衝突形状を2 px拡張した重なり検索（最大16件）で、スライド結果に現れない近接壁やブロックを補足する。近接候補は接触や挟まりの証明ではない。ガム切断後も剛体接触ログは継続する。物理挙動は変更せず、InspectorのDiagnosticsから無効化できる。

`Player Contact`はブロック衝突時の反作用を調整する。本体カプセルのサイズを変更する設定ではない。`Pinning Diagnostics`の`CONTACT_IMPULSE`で接触点のインパルスと剛体速度の前後を確認できる。接触応答と検証条件は`player-controller.md`を参照。
