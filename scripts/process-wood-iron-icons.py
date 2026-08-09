# Processes the user-supplied assets/wood.png and assets/ironore.png (same
# baked two-tone gray checkerboard as items.png / the hero portraits, not
# real alpha) into public/assets/items/wood.png and iron_ore.png. Reuses
# the same background-removal approach as scripts/remove_bg.py and
# scripts/crop-new-item-icons.py — border-flood-fill only (no enclosed-
# pocket pass): both icons are solid clusters with no interior holes, and
# the ore's pale highlight streaks are themselves near-neutral gray, so the
# pocket pass (needed for e.g. hero portraits) would incorrectly treat them
# as enclosed background and erase them.
from PIL import Image
from collections import deque

ROOT = "c:/Users/Martyna/Desktop/rpg"
TARGET_MAX_DIM = 110  # matches the scale of the existing public/assets/items icons


def is_background(r, g, b, lo=100, hi=235, tol=14):
    return abs(r - g) <= tol and abs(g - b) <= tol and abs(r - b) <= tol and lo <= r <= hi


def remove_background(img):
    w, h = img.size
    px = img.load()

    def idx(x, y):
        return y * w + x

    def neighbors(x, y):
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h:
                yield nx, ny

    visited = bytearray(w * h)
    q = deque()
    border = [(x, y) for x in range(w) for y in (0, h - 1)] + [(x, y) for y in range(h) for x in (0, w - 1)]
    for x, y in border:
        if not visited[idx(x, y)]:
            r, g, b, a = px[x, y]
            if is_background(r, g, b):
                visited[idx(x, y)] = 1
                q.append((x, y))

    while q:
        x, y = q.popleft()
        r, g, b, a = px[x, y]
        px[x, y] = (r, g, b, 0)
        for nx, ny in neighbors(x, y):
            if not visited[idx(nx, ny)]:
                nr, ng, nb, na = px[nx, ny]
                if is_background(nr, ng, nb):
                    visited[idx(nx, ny)] = 1
                    q.append((nx, ny))

    return img


def tight_crop(img, pad=4):
    bbox = img.getbbox()
    if not bbox:
        return img
    minx, miny, maxx, maxy = bbox
    minx = max(0, minx - pad)
    miny = max(0, miny - pad)
    maxx = min(img.width, maxx + pad)
    maxy = min(img.height, maxy + pad)
    return img.crop((minx, miny, maxx, maxy))


FILES = {
    f"{ROOT}/assets/wood.png": f"{ROOT}/public/assets/items/wood.png",
    f"{ROOT}/assets/ironore.png": f"{ROOT}/public/assets/items/iron_ore.png",
}

for src, dst in FILES.items():
    img = Image.open(src).convert("RGBA")
    img = remove_background(img)
    img = tight_crop(img)
    scale = TARGET_MAX_DIM / max(img.size)
    img = img.resize((max(1, round(img.width * scale)), max(1, round(img.height * scale))), Image.LANCZOS)
    img.save(dst)
    print(f"{src} -> {dst}: {img.size}")
