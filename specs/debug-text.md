# Debug text

In-game help/status, stage labels and map preview use the project-wide `resources/debug_theme.tres`: PixelMplus12 Regular at24px (2× native grid). Font import disables antialiasing and subpixel positioning and uses1× oversampling. License accompanies the fonts in `assets/fonts/README.txt`.

Keep labels on the shared theme; stage generation must not add arbitrary font-size overrides. Game status starts at y108 below the three-line help; map preview has a72px header. Console diagnostic output uses the editor/terminal font and is independent of the game theme.
