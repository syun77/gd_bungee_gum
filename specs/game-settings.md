# ゲームパラメータの編集

GodotのFileSystemで `res://resources/game_settings.tres` を選択し、Inspectorで編集して保存する。F5を再実行すると反映される。現在の基準値は蹴り出し速度400 px/s、Coyote Time 0.20秒、ガム最大長400 px、射程160 px、発射速度1200 px/s。保存済み設定とスクリプトの初期値を揃えている。ガム最小自然長は4 px。Gum／Pinning診断はOFF、Jump／Landing診断はOFFを基準とする。定義・範囲・単位の説明は `scripts/game_settings.gd` にある。

| Inspectorのグループ | 主な項目 |
| --- | --- |
| Player Movement | 走行速度、地上／空中の入力加速度、地面の摩擦、重力、蹴り出し速度、Coyote Time（床離脱後の猶予秒数）、プレイヤー質量 |
| Player Contact | 接触余白0.75 px、反発係数0.1、深度補正率0.8、分離速度上限120 px/s |
| Gum Physics | ばね係数、減衰、収縮速度、最小／最大長、最大張力、手動延長／短縮速度、手動延長上限の安全余裕 |
| Gum Flight | 先端速度、回収速度、回収表示の最大寿命 |
| Gum Wrapping | 支点のクリアランス、解除離隔・確認ティック、支点数・経路修正の上限 |
| Aim Guide | 接着可／不可の色と透明度、補助線の太さ・破線長、照準円の半径・太さ |
| Gum Appearance | 緩めモードの色（Gum Loosen Color、初期値 #B8A6AD）、収縮中の無張力／最大張力の色、線の太さと張力による追加幅 |
| Diagnostics | Landing Diagnostics：着地不安定の調査ログ、Jump Diagnostics：接地キックの調査ログ（両方初期値OFF） |
| Camera Zoom | 通常／長距離時の倍率、距離範囲、追従速度 |
| Stage Rules | 落下時に再スタートするY座標 |

READY時に表示する命中予告の補助線（発射から回収完了までは非表示）は **Aim Valid Color / Aim Invalid Color** で変更する。カラーピッカーの **A（アルファ）** が透明度で、1が不透明。初期値は両方0.9、**Aim Line Width** は2 px。色とアルファは照準円にも適用する。接着可能な予測では有効色のアルファをそのまま使い、明るく表示する（初期0.9）。対象なし／接着不可では`Aim Guide Opacity`（0.3）を無効色のアルファに掛ける（初期0.27）。方向入力の有無では明るさを変えない。描画側は `scripts/gum_connection.gd` の `_draw()`。

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

接続中のガムは同じ経路に加算合成・ガウス減衰のハロー24層、ピンクのリボン、幅75%の白ピンクの芯を重ねて発光感を出す。折り返し点と接着点にも適用する。線の基本幅は4 px、最大張力でさらに4 px加算する。距離や経路上の位置による幅の変化はなく、たるみ・折り返しの物理経路を維持する。通常色は #FF8DD6、最大張力色は #FF62BD。Gum Appearance の **Gum Glow Radius**（初期18 px）、**Gum Glow Opacity**（0.18）、**Gum Core Brightness**（白の混合率0.12）で調整する。半径または不透明度0でハローを無効化できる。緩めモードの基本色は灰色寄りのまま。描画のみの効果で、周囲への照明や物理への影響はなく、Compatibility対応の局所ブルーム近似で、画面全体のHDRポストエフェクトに依存しない。

**Attachment Range**（`attachment_range`、初期160 px）は先端の累積飛行距離と照準の射程。**Maximum Length**（`maximum_length`、初期400 px）は接続後に伸びられる総経路長の切断上限で、巻き付き経路を含む。両者は独立して編集できる。例えば射程400／最大長800なら400 px以内に接着し、その後800 pxまで伸びられる。手動自然長の上限はMaximum Length−Manual Length Margin。射程を最大長より長くしても、最大長を超える位置には接着できず照準も接着不可になる。

`Gum Flight`の`gum_shot_speed`は先端の直進速度（1200 px/s）、`gum_return_speed`は回収経路の短縮速度（3200 px/s）、`gum_return_max_duration`は回収表示の最大寿命（0.25秒）。飛行・回収はガム力を発生させず、接着成立の次更新から既存の物理計算を行う。飛行・回収の長さは経路長ズームに使用しない。

`Gum Diagnostics`（初期値OFF）は切断時に`[GumDiagnostic] DETACH`を出力する。切断理由、状態／モード、両端位置、プレイヤー速度／外部速度、接続先パス・回転・ローカル接着点・剛体速度／質量、経路長・自然長・上限・経路点・ピボット数・修復回数・失敗理由を含む。`HISTORY`は力のリセット前に保存した直近8ステップ（前ステップの張力／力、今回のdelta／長さ入力）の履歴。動的障害物による切断はレイ区間、検出物、接続先自身かを示す`is_target`、衝突位置／法線／shapeも記録する。通常の接続中は出力せず、手動切断・飛行失敗・再起動も切断理由で区別する。GodotのOutputまたは標準出力ログで確認し、InspectorのDiagnosticsから無効化できる。経路更新失敗時の経路点／長さは最後に完成した経路の場合があるため、現在の両端位置・previous位置と併せて読む。

`Pinning Diagnostics`（初期値OFF）はプレイヤーと剛体のスライド接触、または深い接触で移動できない状態を調査する。剛体が接触一覧から欠落しても、接触深度1 px以上・衝突前速度10 px/s以上・1ステップの実変位0.1 px未満なら`stalled_penetration=true`として記録を継続する。`rigid_contact`、`deepest_contact`、`slide_count`も含む。`[PinningDiagnostic] CONTACT_STARTED`で直前8ステップの`HISTORY`と現在状態を出力し、接触中は30物理ティックごとに`PERSISTING`、移動／Z／X／上下入力またはガム状態・モードの変化時に`ACTION_CHANGED`、剛体接触も深い接触による停滞も報告されなくなると`CONTACT_ENDED`を出す。挟まったと断定する検出ではなく、通常のブロック接触も対象。入力、キック可否・猶予、移動前後位置・実変位、衝突前の入力／外部／合成速度、move_and_slide直後速度、衝突整理・摩擦後の入力／外部速度、床・壁・天井、safe_margin／max_slides、接触相手・法線・深度・位置・相手速度、剛体の質量・回転・速度・sleep/freeze、ガムの状態・張力・両端力・長さを含む。イベント時の`nearby`はプレイヤー衝突形状を2 px拡張した重なり検索（最大16件）で、スライド結果に現れない近接壁やブロックを補足する。近接候補は接触や挟まりの証明ではない。ガム切断後も剛体接触ログは継続する。物理挙動は変更せず、InspectorのDiagnosticsから無効化できる。

`Player Contact`は壁・天井相当のブロック接触の反作用を調整する。床相当の支持接触は実カプセルの衝突に任せ、接触余白による分離や反発を加えない。本体カプセルのサイズを変更する設定ではない。`Pinning Diagnostics`の`CONTACT_IMPULSE`で接触点のインパルスと剛体速度の前後を確認できる。接触応答と検証条件は`player-controller.md`を参照。

`Landing Dust`は着地土煙の表示しきい値。`landing_dust_minimum_speed`は80px/s未満を省略し、`landing_dust_heavy_speed`は450px/s以上で強着地画像を選ぶ。いずれも床法線方向の接触直前相対速度で、横移動速度を含めない。強着地しきい値を最小速度未満に設定した場合は最小速度を下限にする。物理への影響はない。

`Gum Shot Particles`は発射軌跡の光粒子。`gum_shot_particles_enabled`はON、`gum_particle_spacing`は10px（±20%）、`gum_particle_lifetime`は0.5秒（0.7〜1.3倍）、`gum_particle_spread`は16px、`gum_particle_opacity`は1.0。放出は実際の先端移動距離で決まり、接着・回収中は追加しない。無効化すると残粒も消える。物理への影響はない。詳細は`gum-shot-particles.md`。

`Gum Hit Particles`は接着成功時の光粒子リング。`gum_hit_particles_enabled`はON、`gum_hit_particle_count`は16（4〜16）、`gum_hit_particle_radius`は20px、`gum_hit_particle_lifetime`は0.5秒、`gum_hit_particle_opacity`は1.0、`gum_hit_arcs_enabled`はOFF。リングは全周、通常面は外側半円へ広がる。解除後も寿命まで残り、再開・無効化で全消去する。追加の物理力はない。詳細は`gum-hit-particles.md`。

## Player Squash and Stretch

`resources/game_settings.tres` のInspectorで見た目だけの伸縮を調整する。

| 設定 | 初期値 | 意味 |
| --- | --- | --- |
| Jump Stretch | (0.84, 1.41) | 上向きジャンプ開始時の横／縦倍率 |
| Jump Stretch Duration | 0.31秒 | ジャンプ伸縮の復元時間 |
| Landing Squash | (1.44, 0.82) | 着地時の横／縦倍率 |
| Landing Squash Duration | 0.31秒 | 着地伸縮の復元時間 |

倍率1で通常サイズ。時間0で該当効果を無効化。足元基準・二次曲線で復元し、当たり判定や速度は変更しない。

### 高速移動の残像

高速移動時の残像は `Player Afterimages` 設定で調整する。実移動距離÷固定ステップ秒数が `afterimage_minimum_speed`（350px/s）以上なら、`afterimage_interval`（0.04秒）ごとに表示中のフレーム・向き・変形をワールド座標に固定して複製する。通常走行220px/sでは発生せず、落下・ジャンプ・ガム移動にも同じ速度条件を使う。薄いピンク `afterimage_color`（RGBA 1/0.72/0.85/0.32）が `afterimage_lifetime`（0.20秒）で二次減衰し、最大8枚。減速後も既存の残像は消えるまで残る。`afterimage_enabled=false` または寿命0で消去・停止する。Playerの子として再スタート時に破棄され、当たり判定や運動には影響しない。

残像は元のプレイヤー画像の実効Zより1低い絶対Zで描画し、常にプレイヤーの背面に置く。

残像は `shaders/afterimage_silhouette.gdshader` の単色シルエットで描画する。元画像からはアルファだけを使い、RGBは `afterimage_color`、不透明度は同色のアルファとフェードから決める。共有マテリアルを使い、プレイヤー本体の色は変更しない。

### Gum Hit Shockwave

Shader hit wave: enabled by default, radius56px, duration0.32s, refraction strength4 screen pixels, pink rim opacity0.3. Duration0 disables emission. See [gum-hit-shockwave.md](gum-hit-shockwave.md).

### Food Collection

`food_reel_speed`: 手元への引き寄せ速度、既定600px/s（Inspector範囲1〜4000）。速度・重力停止と回収後ジャンプの詳細は [food-gum-reel.md](food-gum-reel.md)。
