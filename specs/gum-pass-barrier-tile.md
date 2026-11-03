# ガム貫通バリアタイル

32×32px透過RGBA。1px程度の細い明るい銀灰色枠、コーラルの側面マーク、明るさを抑えた淡い青灰色の平行な斜め反射で透明ガラスを表現する。ガラス面は低アルファの薄青色で、背景や通過中のガムが透けて見える。ディザではなく実際の半透明RGBAを使う。丸い接着リングとは角枠で区別する。nearest表示。

- 原本: `images/tilesets/restaurant_gum_pass_barrier_source.png`（組み込みimagegenで既存タイルを編集した透過画像）
- タイル: `images/tilesets/restaurant_gum_pass_barrier.png`
- Godot用同一コピー: `gd-bungee-gum/assets/tilesets/restaurant_gum_pass_barrier.png`
- 正規化: `tools/build_gum_pass_barrier.py`（Pillow、1254px原本の銀枠領域(156,156)〜(1098,1098)をクロップし、nearestで32pxに縮小して両コピーを同時更新）

## 配置

`scenes/stages/theater_stage.tscn` の **GumPassBarriers** レイヤーを選び、theater_tilesetの **source3 / (0,0)** を描く。衝突生成ONで使う。初期配置はセクション01のセル(4〜6,15)とセクション03の(59〜61,16)、各3枚／計6枚。既存リング(5,12)と(60,14)の下に水平スクリーンを置き、下からガムを通して接着できる。中央を体で上昇すると止まり、横端から回り込める。下側の通常通路は開ける。`stage_layout.gd` の `GUM_PASS_BARRIERS` が配置の正本で、生成器も同じ配置を作る。手描きの配置はシーン保存で保持できるが、ステージ再生成は正本の配置に戻す。

画像の透明部分も含め、セル全体32×32pxが四方向からの通行を遮る。物理エンジンがプレイヤーと箱の衝突を解決する。ガムは枠も中央も貫通し、このタイルには接着・巻き付きしない。奥の通常地形、箱、リングへは通常どおり接着できる。

TileSet physics index2、物理ビット64（Inspectorレイヤー7、GumPassBarriers）、mask0。プレイヤーmask77、箱mask73。ガムmask53には64を含めない。一方向床8とは独立しており、Down+Zによる床抜け中もこのバリアは有効。

## 検証

`tools/verify_gum_pass_barrier.gd` を通常のheadlessコマンドで実行する。保存済み6セルと配置正本の一致、実配置でのリング接着／上昇衝突、プレイヤー／箱の四方向の実衝突クエリ、透明中央の充填判定、奥の地形への実ガム接着と接続維持、床抜けマスク中の衝突を検証する。

## 画像編集指示

組み込みimagegen、既存タイルを編集入力、透明背景指定。最終プロンプト:

画像編集後に元画像のアルファチャンネルをImageMagickのCopyOpacityで復元し、ガラスの透け方を保持する。保存原本には復元済みのアルファを含む。

```text
Precisely edit the supplied RGBA glass tile: reduce ONLY the brightness of the white diagonal reflection pixels slightly (15-20 percent), to a soft pale blue-gray. Everything else unchanged. Especially preserve the original image alpha channel: blue pane is extremely translucent (about10 percent opacity), NOT opaque; preserve the original bright silver frame and original transparent blue pane exactly. No dark blue fill. No new elements. Keep same square tile position, dimensions and framing. Pixel-art game asset. Render real alpha transparency.
```
