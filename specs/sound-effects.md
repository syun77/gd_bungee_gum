# 効果音

元音源はルートの `sounds/`。checkpoint / crash / dead / door1 / door2 / hit / item / item3 / jump / landing / pull / shoot の12種類の WAV を `gd-bungee-gum/assets/sounds/` にコピーして使用する。

| 音源 | 再生タイミング |
| --- | --- |
| checkpoint | チェックポイントの初回有効化（復帰時は無音） |
| crash | ガムで破壊可能ブロックを壊した時（1マスにつき1回） |
| dead | トゲ死亡、落下死亡（手動リスタートは無音） |
| hit | ガムの接着成功。フードへの命中も含む |
| item3（score_item） | 音符・フランスパンの取得確定時に1回 |
| item | フード獲得確定。接触・ガム回収共通 |
| jump | 成功したジャンプ。先行入力は実際に跳ぶ時。拒否・床すり抜けは無音 |
| landing | Player.landed と同じ有効な着地。初期接地は除外 |
| pull | 接着後最初の収縮ステップ、緩めた後の収縮再開。フード回収も含む |
| shoot | ガム発射成立時。飛行中の無効入力は無音 |

SoundEffects Autoload が非位置依存の AudioStreamPlayer を再生し、終了時に破棄する。各音は一回再生で、同時発音は最大24。死亡音を含む再生中の音はシーン再読込でも維持する。収縮中の X 再入力では pull を重複再生しない。物理挙動と音源の速度・ピッチは変更しない。

検証: `tools/verify_sound_effects.gd` と controls / gum / player / food / checkpoint / spike の各検証。

入口・出口のドアは開き始めに door1.wav（door_open）、閉じるアニメーション完了時に door2.wav（door_close）を各1回再生する。入口の待機中と出口の着地・中央への移動中は再生しない。
