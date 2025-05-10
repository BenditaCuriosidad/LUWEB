#!/bin/zsh
set -e

# ── paths ───────────────────────────────────────────────────────────────
PROJECT_DIR="/Users/julianmora/projects/luweb/luweb"
IMAGE_PATH="$PROJECT_DIR/PA300052.jpg"
DZI_BASE="$PROJECT_DIR/PA300052_dzi"        # vips adds .dzi and _files
HASH_FILE="$PROJECT_DIR/.last_image_hash"

cd "$PROJECT_DIR"

# ── 1. detect change ────────────────────────────────────────────────────
[[ -f "$IMAGE_PATH" ]] || { echo "❌ $IMAGE_PATH not found"; exit 1; }

NEW_HASH=$(md5 -q "$IMAGE_PATH")
OLD_HASH=$(cat "$HASH_FILE" 2>/dev/null || echo "")

[[ "$NEW_HASH" == "$OLD_HASH" ]] && { echo "ℹ️  Image unchanged — exit."; exit 0; }

echo "🔄 Image changed — regenerating tiles…"

# ── 2. generate tiles ───────────────────────────────────────────────────
rm -rf "${DZI_BASE}.dzi" "${DZI_BASE}_files"
vips dzsave "$IMAGE_PATH" "$DZI_BASE" \
     --tile-size 512 --overlap 0 --suffix '.jpg[Q=90]' --depth onepixel

echo "$NEW_HASH" > "$HASH_FILE"

# ── 3. git commit & push ────────────────────────────────────────────────
git add PA300052.jpg "${DZI_BASE}.dzi" "${DZI_BASE}_files" "$HASH_FILE"
git diff --cached --quiet && { echo "ℹ️  Nothing new to commit."; exit 0; }

git commit -m "auto: new tiles $(date '+%Y-%m-%d %H:%M')"
git push origin main

echo "✅ Pushed. GitHub Pages will redeploy in ~30 s."
