Add-Type -AssemblyName System.Drawing

function Crop-TightBoundingBox {
    param(
        [System.Drawing.Bitmap]$Source,
        [int]$X, [int]$Y, [int]$Width, [int]$Height,
        [string]$OutPath
    )

    $cellW = [Math]::Min($Width, $Source.Width - $X)
    $cellH = [Math]::Min($Height, $Source.Height - $Y)
    $cell = New-Object System.Drawing.Bitmap $cellW, $cellH
    $g = [System.Drawing.Graphics]::FromImage($cell)
    $g.DrawImage($Source, (New-Object System.Drawing.Rectangle 0, 0, $cellW, $cellH), (New-Object System.Drawing.Rectangle $X, $Y, $cellW, $cellH), [System.Drawing.GraphicsUnit]::Pixel)
    $g.Dispose()

    $minX = $cellW; $minY = $cellH; $maxX = 0; $maxY = 0
    for ($yy = 0; $yy -lt $cellH; $yy += 2) {
        for ($xx = 0; $xx -lt $cellW; $xx += 2) {
            $p = $cell.GetPixel($xx, $yy)
            if ($p.A -gt 15) {
                if ($xx -lt $minX) { $minX = $xx }
                if ($yy -lt $minY) { $minY = $yy }
                if ($xx -gt $maxX) { $maxX = $xx }
                if ($yy -gt $maxY) { $maxY = $yy }
            }
        }
    }

    $pad = 4
    $minX = [Math]::Max(0, $minX - $pad)
    $minY = [Math]::Max(0, $minY - $pad)
    $maxX = [Math]::Min($cellW - 1, $maxX + $pad)
    $maxY = [Math]::Min($cellH - 1, $maxY + $pad)
    $w = $maxX - $minX + 1
    $h = $maxY - $minY + 1

    $final = New-Object System.Drawing.Bitmap $w, $h
    $g2 = [System.Drawing.Graphics]::FromImage($final)
    $g2.DrawImage($cell, (New-Object System.Drawing.Rectangle 0, 0, $w, $h), (New-Object System.Drawing.Rectangle $minX, $minY, $w, $h), [System.Drawing.GraphicsUnit]::Pixel)
    $g2.Dispose()

    $final.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $cell.Dispose()
    $final.Dispose()
    Write-Output "Saved $OutPath ($w x $h)"
}

$assets = "c:\Users\Martyna\Desktop\rpg\assets"
$out = "c:\Users\Martyna\Desktop\rpg\public\assets"

New-Item -ItemType Directory -Force -Path "$out\heroes" | Out-Null
New-Item -ItemType Directory -Force -Path "$out\pets" | Out-Null
New-Item -ItemType Directory -Force -Path "$out\bosses" | Out-Null

# Hero portraits: the source files have an opaque grayish backdrop (not real
# transparency), so they go through scripts/remove_bg.py (flood-fill cutout)
# instead of a plain copy. Run separately: python scripts/remove_bg.py

# Landing background
Copy-Item "$assets\map.png" "$out\map.png" -Force

# pets.png / bosses.png are a 3x2 grid, ~421x421 per cell. Top-left cell:
# pets.png   -> purple dragon ("Smoczek")
# bosses.png -> procrastination monster ("Prokrastynacja")
$cellW = [Math]::Ceiling(1264 / 3)
$cellH = [Math]::Ceiling(843 / 2)

# Dragon art bleeds into the next cell around x=375-420, so crop narrower than a full cell.
$petsImg = [System.Drawing.Bitmap]::FromFile("$assets\pets.png")
Crop-TightBoundingBox -Source $petsImg -X 0 -Y 0 -Width 350 -Height $cellH -OutPath "$out\pets\dragon.png"
$petsImg.Dispose()

$bossesImg = [System.Drawing.Bitmap]::FromFile("$assets\bosses.png")
Crop-TightBoundingBox -Source $bossesImg -X 0 -Y 0 -Width $cellW -Height $cellH -OutPath "$out\bosses\procrastination.png"
$bossesImg.Dispose()
