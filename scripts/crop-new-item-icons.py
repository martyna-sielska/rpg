# One-off crop for the 3 new quest-item icons (ancient_gate_fragment,
# ancient_key, broken_crystal), sourced from assets/items.png. That sheet
# bakes a two-tone gray checkerboard into the RGB data instead of using
# real alpha (same situation scripts/remove_bg.py already handles for the
# hero portraits) — reuses its is_background/flood-fill approach, then
# tight-crops to the resulting alpha bounding box, matching how the
# existing public/assets/items/*.png icons were produced.
from PIL import Image
from collections import deque

ROOT = "c:/Users/Martyna/Desktop/rpg"


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

    seen = bytearray(w * h)
    for y in range(h):
        for x in range(w):
            i = idx(x, y)
            if seen[i]:
                continue
            r, g, b, a = px[x, y]
            if a == 0 or not is_background(r, g, b):
                seen[i] = 1
                continue
            component = [(x, y)]
            seen[i] = 1
            qq = deque([(x, y)])
            while qq:
                cx, cy = qq.popleft()
                for nx, ny in neighbors(cx, cy):
                    ni = idx(nx, ny)
                    if seen[ni]:
                        continue
                    nr, ng, nb, na = px[nx, ny]
                    if na != 0 and is_background(nr, ng, nb):
                        seen[ni] = 1
                        component.append((nx, ny))
                        qq.append((nx, ny))
            if len(component) >= 60:
                for cx, cy in component:
                    r, g, b, a = px[cx, cy]
                    px[cx, cy] = (r, g, b, 0)

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


# (x0, y0, x1, y1) source boxes in assets/items.png, generous padding around
# each icon's connected-component bounding box found via scripted scan.
BOXES = {
    "ancient_gate_fragment": (859, 430, 943, 525),  # icy-blue crystal cluster
    "broken_crystal": (755, 430, 844, 526),  # purple crystal cluster
    "ancient_key": (943, 529, 1001, 633),  # single gold key — was cropped too tight up top, clipping the bow
}

sheet = Image.open(f"{ROOT}/assets/items.png").convert("RGBA")

for name, box in BOXES.items():
    crop = sheet.crop(box).copy()
    crop = remove_background(crop)
    crop = tight_crop(crop)
    out_path = f"{ROOT}/public/assets/items/{name}.png"
    crop.save(out_path)
    print(f"{name}: {crop.size} -> {out_path}")
