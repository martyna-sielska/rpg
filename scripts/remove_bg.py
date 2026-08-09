from PIL import Image
from collections import deque
import sys

# The source portraits bake a two-tone gray checkerboard into the RGB data
# instead of using real alpha, e.g. (183,183,183) and (149,149,149) squares.
# Pass 1: flood-fill from the image border through any connected run of
# near-neutral-gray pixels (crosses both checker tones, stops at the
# character's outline).
# Pass 2: some background pockets are fully enclosed by the silhouette
# (e.g. under an arm) and never touch the border. Flood-fill the *whole*
# image into background-colored connected components and clear any
# component above a small size threshold — large enough to catch a pocket,
# small enough not to eat a stray light highlight on the character itself.

def is_background(r, g, b, lo=100, hi=235, tol=14):
    return abs(r - g) <= tol and abs(g - b) <= tol and abs(r - b) <= tol and lo <= r <= hi


def remove_background(path, out_path, pocket_min_size=60):
    img = Image.open(path).convert("RGBA")
    w, h = img.size
    px = img.load()

    def idx(x, y):
        return y * w + x

    def neighbors(x, y):
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h:
                yield nx, ny

    cleared = 0

    # Pass 1: border-connected background.
    visited = bytearray(w * h)
    q = deque()
    border = [(x, y) for x in range(w) for y in (0, h - 1)] + [
        (x, y) for y in range(h) for x in (0, w - 1)
    ]
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
        cleared += 1
        for nx, ny in neighbors(x, y):
            if not visited[idx(nx, ny)]:
                nr, ng, nb, na = px[nx, ny]
                if is_background(nr, ng, nb):
                    visited[idx(nx, ny)] = 1
                    q.append((nx, ny))

    # Pass 2: enclosed background pockets not touching the border.
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
            if len(component) >= pocket_min_size:
                for cx, cy in component:
                    r, g, b, a = px[cx, cy]
                    px[cx, cy] = (r, g, b, 0)
                    cleared += 1

    # Pass 3: stray edge flecks. A few source images have thin, slightly
    # color-shifted noise hugging the canvas border (not neutral-gray enough
    # for pass 1/2 to catch). Any *small* opaque component sitting within a
    # margin of the border is noise, not the character — the character is a
    # single large connected blob of thousands of pixels regardless of where
    # it sits, so this can't accidentally eat it.
    margin = 8
    max_fleck_size = 400
    seen2 = bytearray(w * h)
    for y in range(h):
        for x in range(w):
            i = idx(x, y)
            if seen2[i]:
                continue
            r, g, b, a = px[x, y]
            if a == 0:
                seen2[i] = 1
                continue
            component = [(x, y)]
            touches_margin = x < margin or y < margin or x >= w - margin or y >= h - margin
            seen2[i] = 1
            qq = deque([(x, y)])
            while qq:
                cx, cy = qq.popleft()
                for nx, ny in neighbors(cx, cy):
                    ni = idx(nx, ny)
                    if seen2[ni]:
                        continue
                    nr, ng, nb, na = px[nx, ny]
                    if na != 0:
                        seen2[ni] = 1
                        component.append((nx, ny))
                        if nx < margin or ny < margin or nx >= w - margin or ny >= h - margin:
                            touches_margin = True
                        if len(component) > max_fleck_size:
                            qq.clear()
                            break
                        qq.append((nx, ny))
            if touches_margin and len(component) <= max_fleck_size:
                for cx, cy in component:
                    r, g, b, a = px[cx, cy]
                    px[cx, cy] = (r, g, b, 0)
                    cleared += 1

    img.save(out_path)
    print(f"{path} -> {out_path}: cleared {cleared} / {w*h} px")


ROOT = "c:/Users/Martyna/Desktop/rpg"

# name -> (source, destination). Heroes come straight from assets/; the
# pet/boss sprites are already-cropped cutouts from the pets.png/bosses.png
# sheets (see crop-assets.ps1) that need this same cleanup applied in place.
IMAGES = {
    "elara": (f"{ROOT}/assets/elara.png", f"{ROOT}/public/assets/heroes/elara.png"),
    "kael": (f"{ROOT}/assets/kael.png", f"{ROOT}/public/assets/heroes/kael.png"),
    "liora": (f"{ROOT}/assets/liora.png", f"{ROOT}/public/assets/heroes/liora.png"),
    "rowan": (f"{ROOT}/assets/rowan.png", f"{ROOT}/public/assets/heroes/rowan.png"),
    "dragon": (
        f"{ROOT}/public/assets/pets/dragon.png",
        f"{ROOT}/public/assets/pets/dragon.png",
    ),
    "procrastination": (
        f"{ROOT}/public/assets/bosses/procrastination.png",
        f"{ROOT}/public/assets/bosses/procrastination.png",
    ),
    "bog_slime": (
        f"{ROOT}/public/assets/monsters/bog_slime.png",
        f"{ROOT}/public/assets/monsters/bog_slime.png",
    ),
    "wild_ember": (
        f"{ROOT}/public/assets/monsters/wild_ember.png",
        f"{ROOT}/public/assets/monsters/wild_ember.png",
    ),
    "bramble_warden": (
        f"{ROOT}/public/assets/monsters/bramble_warden.png",
        f"{ROOT}/public/assets/monsters/bramble_warden.png",
    ),
    "iron_sword": (
        f"{ROOT}/public/assets/items/iron_sword.png",
        f"{ROOT}/public/assets/items/iron_sword.png",
    ),
    "crystal_shard": (
        f"{ROOT}/public/assets/items/crystal_shard.png",
        f"{ROOT}/public/assets/items/crystal_shard.png",
    ),
    "healing_potion": (
        f"{ROOT}/public/assets/items/healing_potion.png",
        f"{ROOT}/public/assets/items/healing_potion.png",
    ),
    "travelers_ring": (
        f"{ROOT}/public/assets/items/travelers_ring.png",
        f"{ROOT}/public/assets/items/travelers_ring.png",
    ),
    "icon_world_map": (
        f"{ROOT}/public/assets/icons/world_map.png",
        f"{ROOT}/public/assets/icons/world_map.png",
    ),
    "icon_character": (
        f"{ROOT}/public/assets/icons/character.png",
        f"{ROOT}/public/assets/icons/character.png",
    ),
    "icon_quests": (
        f"{ROOT}/public/assets/icons/quests.png",
        f"{ROOT}/public/assets/icons/quests.png",
    ),
    "icon_home": (
        f"{ROOT}/public/assets/icons/home.png",
        f"{ROOT}/public/assets/icons/home.png",
    ),
    "icon_inventory": (
        f"{ROOT}/public/assets/icons/inventory.png",
        f"{ROOT}/public/assets/icons/inventory.png",
    ),
}

if __name__ == "__main__":
    names = sys.argv[1:] or list(IMAGES.keys())
    for name in names:
        src, dst = IMAGES[name]
        remove_background(src, dst)
