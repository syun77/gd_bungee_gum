# 効果音

元音源はルートの `sounds/`。先頭に「2」が付かない8種類の WAV を `gd-bungee-gum/assets/sounds/` にコピーして使用する。

| 音源 | 再生タイミング |
| --- | --- |
| checkpoint | チェックポイントの初回有効化（復帰時は無音） |
| dead | トゲ死亡、落下死亡（手動リスタートは無音） |
| hit | ガムの接着成功。フードへの命中も含む |
| item | フード獲得確定。接触・ガム回収共通 |
| jump | 成功したジャンプ。先行入力は実際に跳ぶ時。拒否・床すり抜けは無音 |
| landing | Player.landed と同じ有効な着地。初期接地は除外 |
| pull | 接着後最初の収縮ステップ、緩めた後の収縮再開。フード回収も含む |
| shoot | ガム発射成立時。飛行中の無効入力は無音 |

SoundEffects Autoload が非位置依存の AudioStreamPlayer を再生し、終了時に破棄する。各音は一回再生で、同時発音は最大24。死亡音を含む再生中の音はシーン再読込でも維持する。収縮中の X 再入力では pull を重複再生しない。物理挙動と音源の速度・ピッチは変更しない。

検証: `tools/verify_sound_effects.gd` と controls / gum / player / food / checkpoint / spike の各検証。
