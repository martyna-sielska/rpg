from PIL import Image

# NPC source art (assets/*.png) is a full painted scene (character + room),
# not a cutout on a flat backdrop, so remove_bg.py's flood-fill approach
# doesn't apply here. Instead we crop a portrait-aspect (3:4) window centered
# on the character, trimming the excess side background down to a framing
# sliver — the same treatment a visual-novel dialogue portrait uses.

ROOT = "c:/Users/Martyna/Desktop/rpg"

# name -> horizontal center (px) of the character's face in the 1672x941 source
PORTRAITS = {
    "elira": 490,
    "dorran": 480,
    "mira": 620,
}

ASPECT = 3 / 4  # width / height


def crop_portrait(name, center_x):
    src = f"{ROOT}/assets/{name}.png"
    dst = f"{ROOT}/public/assets/npcs/{name}.png"
    img = Image.open(src).convert("RGB")
    w, h = img.size
    crop_w = round(h * ASPECT)
    left = max(0, min(w - crop_w, center_x - crop_w // 2))
    box = (left, 0, left + crop_w, h)
    img.crop(box).save(dst)
    print(f"{src} -> {dst}: cropped {box}")


if __name__ == "__main__":
    for name, center_x in PORTRAITS.items():
        crop_portrait(name, center_x)
