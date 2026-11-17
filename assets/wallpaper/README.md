# Wallpaper assets placeholder

This directory receives the wallpaper bundle at CI time.

The upstream interactive CD wallpaper assets are NOT stored in git (they are
third-party content kept out of this public repository). The CI workflow
downloads `wallpaper-assets.zip` from a private source using the
`WALLPAPER_ASSETS_TOKEN` secret, extracts the files here, and the Windows
build packs this directory into `data/flutter_assets/assets/wallpaper/`.

Local development without the token: this directory may be empty; the
desktop-wallpaper feature will show an error state instead of the wallpaper.

Keep this README as the only tracked file in the directory.
