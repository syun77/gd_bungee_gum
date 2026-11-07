# Debug text

In-game help/status, stage labels and map preview use the project-wide `resources/debug_theme.tres`: PixelMplus12 Regular at24px (2× native grid). Font import disables antialiasing and subpixel positioning and uses1× oversampling. License accompanies the fonts in `assets/fonts/README.txt`.

Keep labels on the shared theme; stage generation must not add arbitrary font-size overrides. Game status starts at y108 below the three-line help; map preview has a72px header. Console diagnostic output uses the editor/terminal font and is independent of the game theme.

## スコア・時間のHUD

スコアは `resources/hud_score_theme.tres`、時間は `resources/hud_timer_theme.tres` で個別に調整する。Default Font / Default Font Sizeで書体とサイズ、LabelのColorsで文字・縁取り・影の色、ConstantsのOutline Size / Shadow Offset X/Yで縁取り幅と影位置を設定する。`scenes/game.tscn` のHUD/ScoreとHUD/Timerにそれぞれ割り当て、ローカル上書きは使わない。Timerはタイムアタックでのみ表示する。取得数字演出の `score_popup_theme.tres`、その他UIの `debug_theme.tres` とは独立する。
