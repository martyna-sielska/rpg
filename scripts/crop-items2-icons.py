# Crops the 18 labeled icons out of assets/items2.png (a hand-drawn sheet:
# solid (64,64,64) background, icon art in the upper part of each grid cell,
# a text label below it) into public/assets/items/*.png. Grid is a regular
# 7-col x 3-row layout over the 1408x768 sheet (cell = 201.14 x 256).
#
# Approach: chroma-key every pixel matching the solid gray background to
# alpha=0 across the whole sheet (so anti-aliased icon edges keep real
# alpha instead of being clipped by a hard rectangle), then for each known
# cell, look only at the top ~72% of the cell (above where the text label
# starts) to isolate the icon glyph from its caption, take the connected-
# component bbox of remaining non-transparent pixels in that sub-region,
# pad it, and crop+save from the *background-removed* full image.
#
# Chroma-keying every matching pixel (not just background reachable from
# the sheet border via flood-fill) matters here: several icons are
# ring/medallion shapes (the seals) or have gaps in their linework (stone
# tablets, gates) where a pocket of background color is fully enclosed by
# the icon's own opaque art and was never reachable from the border — a
# plain border flood-fill left those pockets as solid opaque gray discs
# baked into the cropped PNG.
#
# tol=34 (not the tighter ~10 an exact-match would use): several icons
# (investigation_spot in particular) have a soft painted glow/vignette
# around the subject that fades gradually into the (64,64,64) backdrop —
# a tight tolerance only stripped the flat background and left a visible
# gray halo of half-blended glow pixels. 34 eats that gradient too, while
# staying well below the ~100+ color distance of the actual artwork (gold,
# blue glass, saturated stone tones), verified by inspecting each cropped
# icon after regenerating.
from PIL import Image

ROOT = "c:/Users/Martyna/Desktop/rpg"
BG = (64, 64, 64)


def is_background(r, g, b, tol=34):
    return abs(r - BG[0]) <= tol and abs(g - BG[1]) <= tol and abs(b - BG[2]) <= tol


def remove_background(img):
    w, h = img.size
    px = img.load()

    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if is_background(r, g, b):
                px[x, y] = (r, g, b, 0)

    return img


def bbox_in_region(img, box):
    sub = img.crop(box)
    bbox = sub.getbbox()
    if not bbox:
        return None
    l, t, r, b = bbox
    return (box[0] + l, box[1] + t, box[0] + r, box[1] + b)


sheet = Image.open(f"{ROOT}/assets/items2.png").convert("RGBA")
clean = remove_background(sheet.copy())

COLS = 7
CELL_W = 1408 / COLS
# Per-row (top, bottom) bands that contain only icon art, with the previous
# row's two-line caption and this row's own caption both excluded (measured
# by eye from debug crops — captions bleed a few px past the naive 256px/3
# grid split, so rows are not simply y in [row*256, (row+1)*256)).
ROW_BANDS = {
    0: (0, 210),
    1: (285, 463),
    2: (545, 700),
}

# (row, col) -> (x0, x1) horizontal override, for cells where the naive
# equal-width column split cuts through art instead of the gap between
# icons. locked_ancient_gate's stone doorframe pillars start left of the
# nominal col-4/col-5 boundary, so the naive split let a chunk of its left
# pillar bleed into locked_location_padlock's crop, and clipped the
# doorframe's own left pillar in the gate's crop. Bounds below were found by
# scanning row 2 for background-only columns between the two icons.
COL_OVERRIDES = {
    (2, 4): (820, 919),
    (2, 5): (976, 1180),
}

# (row, col) -> output filename (None = empty cell)
GRID = {
    (0, 0): "ancient_seal",
    (0, 1): "second_seal",
    (0, 2): "third_seal",
    (0, 3): "veil_key",
    (0, 4): "volcanic_material",
    (0, 5): "rare_metal",
    (0, 6): "ancient_forge_fragment",
    (1, 0): "ancient_stone_tablet",
    (1, 1): "ancient_stone_inscription",
    (1, 2): "ancient_altar",
    (1, 3): "veil_inscription",
    (1, 4): "ancient_archive_document",
    (1, 5): "torn_archive_page",
    (1, 6): "hidden_archive_book",
    (2, 0): "investigation_spot",
    (2, 1): None,
    (2, 2): None,
    (2, 3): None,
    (2, 4): "locked_location_padlock",
    (2, 5): "locked_ancient_gate",
    (2, 6): "ancient_seal_socket",
}

pad = 4
for (row, col), name in GRID.items():
    if name is None:
        continue
    band_top, band_bottom = ROW_BANDS[row]
    if (row, col) in COL_OVERRIDES:
        x0, x1 = COL_OVERRIDES[(row, col)]
        region = (x0, band_top, x1, band_bottom)
    else:
        cell_x0 = col * CELL_W
        region = (int(cell_x0), band_top, int(cell_x0 + CELL_W), band_bottom)
    bbox = bbox_in_region(clean, region)
    if not bbox:
        print(f"WARNING: no content found for {name} in {region}")
        continue
    l, t, r, b = bbox
    l = max(region[0], l - pad)
    t = max(region[1], t - pad)
    r = min(region[2], r + pad)
    b = min(region[3], b + pad)
    crop = clean.crop((l, t, r, b))
    out_path = f"{ROOT}/public/assets/items/{name}.png"
    crop.save(out_path)
    print(f"{name}: region={region} bbox={(l, t, r, b)} size={crop.size} -> {out_path}")
