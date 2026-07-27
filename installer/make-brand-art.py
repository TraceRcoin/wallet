"""Generate Tracercoin-branded NSIS installer artwork from the brand avatar.
Outputs (into ./brand): tracercoin.ico, nsis-wizard.bmp (164x314), nsis-header.bmp (150x57).
Also refreshes the canonical E-tree share/pixmaps if present so `make deploy` picks them up.
"""
from PIL import Image
import os, shutil

SRC = r"C:\XTKRecall\tracercoin-youtube\brand\avatar.png"
OUT = r"C:\XTKRecall\tracercoin-installer\brand"
os.makedirs(OUT, exist_ok=True)

logo = Image.open(SRC).convert("RGBA")
BG = (8, 14, 12)  # near-black Tracercoin brand background

def dark_canvas(w, h):
    return Image.new("RGB", (w, h), BG)

# 1) Multi-resolution Windows icon (.ico)
ico_sizes = [16, 24, 32, 48, 64, 128, 256]
ico_path = os.path.join(OUT, "tracercoin.ico")
logo.save(ico_path, format="ICO", sizes=[(s, s) for s in ico_sizes])

# 2) Wizard / welcome-finish side banner — 164 x 314 (24-bit BMP)
wiz = dark_canvas(164, 314)
lw = 150
lg = logo.resize((lw, lw), Image.LANCZOS)
wiz.paste(lg, ((164 - lw) // 2, 26), lg)
wiz_path = os.path.join(OUT, "nsis-wizard.bmp")
wiz.save(wiz_path)  # Pillow writes 24-bit BMP3 — NSIS MUI compatible

# 3) Header strip — 150 x 57, logo on the RIGHT (script sets MUI_HEADERIMAGE_RIGHT)
hdr = dark_canvas(150, 57)
hh = 49
hg = logo.resize((hh, hh), Image.LANCZOS)
hdr.paste(hg, (150 - hh - 4, (57 - hh) // 2), hg)
hdr_path = os.path.join(OUT, "nsis-header.bmp")
hdr.save(hdr_path)

print("Generated:")
for p in (ico_path, wiz_path, hdr_path):
    print("  %6d B  %s" % (os.path.getsize(p), p))

# 4) Refresh canonical E-tree pixmaps (keep the filenames the template expects)
E_PIX = r"E:\Tracercoin\blockchain\share\pixmaps"
if os.path.isdir(E_PIX):
    mapping = {
        "bitcoin.ico": ico_path,
        "nsis-wizard.bmp": wiz_path,
        "nsis-header.bmp": hdr_path,
    }
    print("Refreshing canonical pixmaps in", E_PIX)
    for name, srcf in mapping.items():
        dst = os.path.join(E_PIX, name)
        shutil.copyfile(srcf, dst)
        print("  ->", dst)
else:
    print("Canonical E-tree pixmaps not found (skipped):", E_PIX)
