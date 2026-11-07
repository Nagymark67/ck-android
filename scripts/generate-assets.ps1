Add-Type -AssemblyName System.Drawing

$srcPath = Join-Path $PSScriptRoot "..\ck_cimer_szines.png"
if (-not (Test-Path $srcPath)) {
    Write-Error "Source image not found: $srcPath"
    exit 1
}

$srcImg = [System.Drawing.Image]::FromFile((Resolve-Path $srcPath))
$srcImg.MakeTransparent([System.Drawing.Color]::White)
$resDir = Join-Path $PSScriptRoot "..\android\app\src\main\res"

function Save-ResizedImage {
    param(
        [System.Drawing.Image]$source,
        [int]$targetWidth,
        [int]$targetHeight,
        [string]$destPath,
        [System.Drawing.Color]$bgColor = [System.Drawing.Color]::Transparent,
        [double]$scaleFactor = 1.0
    )
    $destDir = Split-Path $destPath
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    $destBmp = New-Object System.Drawing.Bitmap($targetWidth, $targetHeight)
    $g = [System.Drawing.Graphics]::FromImage($destBmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

    if ($bgColor -ne [System.Drawing.Color]::Transparent) {
        $brush = New-Object System.Drawing.SolidBrush($bgColor)
        $g.FillRectangle($brush, 0, 0, $targetWidth, $targetHeight)
        $brush.Dispose()
    } else {
        $g.Clear([System.Drawing.Color]::Transparent)
    }

    $drawW = [int]($targetWidth * $scaleFactor)
    $drawH = [int]($targetHeight * $scaleFactor)
    $offsetX = [int](($targetWidth - $drawW) / 2)
    $offsetY = [int](($targetHeight - $drawH) / 2)

    $g.DrawImage($source, $offsetX, $offsetY, $drawW, $drawH)
    $g.Dispose()

    $destBmp.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $destBmp.Dispose()
    Write-Host "Created: $destPath ($($targetWidth)x$($targetHeight))"
}

# 1. Launcher icons
$launcherSizes = @{
    "mipmap-mdpi"    = 48
    "mipmap-hdpi"    = 72
    "mipmap-xhdpi"   = 96
    "mipmap-xxhdpi"  = 144
    "mipmap-xxxhdpi" = 192
}

foreach ($density in $launcherSizes.Keys) {
    $size = $launcherSizes[$density]
    $iconPath = Join-Path $resDir "$density\ic_launcher.png"
    $roundPath = Join-Path $resDir "$density\ic_launcher_round.png"
    Save-ResizedImage -source $srcImg -targetWidth $size -targetHeight $size -destPath $iconPath
    Save-ResizedImage -source $srcImg -targetWidth $size -targetHeight $size -destPath $roundPath
}

# 2. Launcher foreground icons (for adaptive icons, centered with padding)
$foregroundSizes = @{
    "mipmap-mdpi"    = 108
    "mipmap-hdpi"    = 162
    "mipmap-xhdpi"   = 216
    "mipmap-xxhdpi"  = 324
    "mipmap-xxxhdpi" = 432
}

foreach ($density in $foregroundSizes.Keys) {
    $size = $foregroundSizes[$density]
    $fgPath = Join-Path $resDir "$density\ic_launcher_foreground.png"
    # Scale factor 0.65 to fit safely inside adaptive icon circle/mask
    Save-ResizedImage -source $srcImg -targetWidth $size -targetHeight $size -destPath $fgPath -scaleFactor 0.65
}

# 3. Splash screens
$wineColor = [System.Drawing.Color]::FromArgb(75, 0, 0) # #4b0000

$splashSizes = @{
    "drawable"               = @{ w = 480; h = 800 }
    "drawable-port-mdpi"     = @{ w = 320; h = 480 }
    "drawable-port-hdpi"     = @{ w = 480; h = 800 }
    "drawable-port-xhdpi"    = @{ w = 720; h = 1280 }
    "drawable-port-xxhdpi"   = @{ w = 960; h = 1600 }
    "drawable-port-xxxhdpi"  = @{ w = 1280; h = 1920 }
    "drawable-land-mdpi"     = @{ w = 480; h = 320 }
    "drawable-land-hdpi"     = @{ w = 800; h = 480 }
    "drawable-land-xhdpi"    = @{ w = 1280; h = 720 }
    "drawable-land-xxhdpi"   = @{ w = 1600; h = 960 }
    "drawable-land-xxxhdpi"  = @{ w = 1920; h = 1280 }
}

foreach ($folder in $splashSizes.Keys) {
    $w = $splashSizes[$folder].w
    $h = $splashSizes[$folder].h
    $splashPath = Join-Path $resDir "$folder\splash.png"

    # Target splash emblem: min dimension * 0.4
    $destBmp = New-Object System.Drawing.Bitmap($w, $h)
    $g = [System.Drawing.Graphics]::FromImage($destBmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

    $brush = New-Object System.Drawing.SolidBrush($wineColor)
    $g.FillRectangle($brush, 0, 0, $w, $h)
    $brush.Dispose()

    $emblemSize = [int]([Math]::Min($w, $h) * 0.45)
    $offsetX = [int](($w - $emblemSize) / 2)
    $offsetY = [int](($h - $emblemSize) / 2)
    $g.DrawImage($srcImg, $offsetX, $offsetY, $emblemSize, $emblemSize)
    $g.Dispose()

    $destDir = Split-Path $splashPath
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
    $destBmp.Save($splashPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $destBmp.Dispose()
    Write-Host "Created splash: $splashPath ($($w)x$($h))"
}

$srcImg.Dispose()
Write-Host "All icons and splash screens generated successfully!"
