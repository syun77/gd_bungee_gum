# ゲームパラメータの編集

未接続時の下降速度は `Player Movement / Max Fall Speed`（初期600 px/s）で制限する。横・上昇速度は保持し、ガム接続中は緩んでいても制限しない。切断したティックから上限を再適用する。

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

Shader hit wave: enabled by default, radius56px, duration0.32s, refraction strength4 screen pixels, pink/near-white rim opacity0.3 (script defaults). Saved gameplay tuning: radius160px, duration1s, strength16px, opacity1. Duration0 disables emission. See [gum-hit-shockwave.md](gum-hit-shockwave.md).

### Food Collection

`food_reel_speed`: 手元への引き寄せ速度、既定600px/s（Inspector範囲1〜4000）。速度・重力停止と回収後ジャンプの詳細は [food-gum-reel.md](food-gum-reel.md)。

- `Player Movement/jump_buffer_time`: 着地前ジャンプの入力保存秒数。既定0.12秒、0で無効。床接触後の最初の物理ティックで一度だけ通常キックを実行し、成功・降下・移動リセット・フード回収ロックで消費／消去する。

ハシゴ範囲内では上下で昇降（Ladder / ladder_speed既定120px/s）。左右・Z・ガム発射で離れる。詳細は [ladders.md](ladders.md)。

`Hanging Pose Diagnostics` は `[HangingPoseDiagnostic]` でガム方向と姿勢選択を調査する。スクリプト初期値OFF、現在の共有Resourceは調査用にON。`resources/game_settings.tres` の Inspector → Diagnostics → Hanging Pose Diagnostics で切り替える。F5実行時のGodot Outputで確認できる。

- `SELECTED`：ガム接続／飛行中のアニメーション・方向コマ・左右反転が変化したとき。真上ループ内の時間コマ進行では繰り返さない。
- `SAMPLE`：選択が同じでも30物理ティックごとに現在値を出力。`EXIT`：接続／飛行状態を離れたときに1回。
- `signed_angle_deg`：真上0度、右正／左負の実際のガム支持方向。`angle_deg`：その絶対値。巻き付き時は最初のピボット方向を使う。
- `animation` / `frame`：選択結果。`gum_hang_angles` のframe0〜7は公称10/20/30/40/50/60/70/80度。`nominal_angle_deg` が公称角度、`selection_error_deg` は実角度絶対値−公称角度。真上の `gum_hang` は公称0度、他のアニメーションは公称−1（対象外）。画像そのものの腕の実測角度ではない。
- `flip_h` / `floor` / `speed` / `tension` / `above` / `upper_sector` / `attached` / `outbound` で方向中割りが使われなかった条件を確認する。`above` は方向が上半分（Y<0）、`upper_sector` は真上基準70度未満を示す。速度は腕向きの条件ではない。`support_offset` は胸から最初の支持点へのベクトル、`endpoint` は最終接着点。

例：`angle_deg=32.4 animation=gum_hang_angles frame=2 nominal_angle_deg=30 selection_error_deg=2.4` なら30度のコマが選択されている。上方セクター内で5度未満は真上ループ、コマ切り替え境界は15/25/35/45/55/65度。真上基準70度以上（上半分では水平から20度以内）は横寄りの発射／牽引姿勢を使用し、80度コマは現在使わない。同距離は小さい角度側、5度・70度境界と最寄り判定には浮動小数誤差0.0001度の許容を適用。発射中は地上／空中を問わず方向選択を優先し、接続中は空中・張力10超で方向選択する。速度・支持点までの高さは選択条件ではない。接続中の接地／弛緩時は通常姿勢、下方接続／発射は既存fire/pull素材を使う。

`Gum Appearance / Gum Hand Follow Speed` は線の手元側の描画起点の追従速度（初期値360px/s）。ポーズ・左右反転・描画変形による手先座標の差を固定ステップで連続的に追い、Player自体の移動には即追従する。物理の接続点や張力には影響しない。`HangingPoseDiagnostic` の `hand_origin`（現在の線起点）、`hand_target`（姿勢の手先目標）、`hand_gap_px`（追従中の差）で確認する。ログは姿勢選択直後・同ステップの追従更新前の値。

## Player Double Jump

`resources/game_settings.tres` の **Player Double Jump → Double Jump Rotation Speed** (`double_jump_rotation_speed`) は2段ジャンプ中の描画回転速度。単位は回転/秒 (rev/s)、既定2.5（1回転0.4秒）。大きいほど速く、1なら1秒に1回転、0なら現在の角度で停止する。空中で値を変えても次の固定更新から反映し、膝抱えポーズ・ジャンプの強さ・速度・重力・当たり判定は変わらない。着地時には速度設定にかかわらず正立へ戻る。

回転ジャンプの向きは表示中のキャラクターに従い、右向きは時計回り、左向きは反時計回り。空中で左右入力により振り向くと、角度をリセットせずその更新から逆回転する。無入力時は直前の向きを保持する。`double_jump_rotation_speed` は両方向共通の速さで、移動速度や外部運動量には影響しない。

**Player Movement → Kick Speed** (`kick_speed`) は初段・床／天井・コヨーテ・ガム解除・フード報酬・ハシゴのジャンプ速度。**Player Double Jump → Double Jump Kick Speed** (`double_jump_kick_speed`) は回転する二段目の空中ジャンプだけに適用する。単位はpx/s、二段目の既定380、現在の保存値は初段400・二段目300。上下・横の運動量処理、下降補正、ジャンプ回数・回転速度は各設定を変更しても同じ規則を使う。

二段ジャンプの発動更新では縦速度を `-double_jump_kick_speed` に代入する。発動前の上昇・下降速度とその更新の重力は引き継がず、横速度だけを保持する。次更新から重力を再開する。初段・ガム解除などの補正は各既存規則を使う。

## 強い横牽引の姿勢

Gum Pull Pose / `gum_hair_pull_force` は大きな髪なびき姿勢に入る水平ガム力のしきい値（初期700、継続側75%）。空中・上向き〜水平・横成分優勢の接続時のみ。速度ではなく実際のガム力を使い、物理は変更しない。
