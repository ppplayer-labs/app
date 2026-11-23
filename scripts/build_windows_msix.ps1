<#
.SYNOPSIS
  Build PPPlayer Windows Store MSIX package with WACK certification safeguards.
.DESCRIPTION
  Runs `dart run msix:build --store`, removes the unused debug-CRT zlib.dll from
  media_kit_libs_windows_video's ANGLE archive (WACK #46), normalizes all
  Images\BadgeLogo.scale-*.png assets to monochrome white-on-transparent masks
  (WACK #45), verifies zero debug CRT imports when dumpbin is available, and packs
  the final Store MSIX via `dart run msix:pack --store`.
#>
param(
    [switch]$BuildWindows
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
Push-Location $repoRoot
try {
    $releaseDir = Join-Path $repoRoot 'build\windows\x64\runner\Release'

    if ($BuildWindows) {
        Write-Host 'Building Flutter Windows release...'
        & flutter build windows --release
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }

    if (-not (Test-Path (Join-Path $releaseDir 'ppplayer.exe'))) {
        throw "Missing Release executable: $releaseDir\ppplayer.exe. Run 'flutter build windows --release' or pass -BuildWindows."
    }

    # Defensive guard: ensure unused debug-CRT zlib.dll is removed before MSIX staging (WACK #46).
    $zlibPath = Join-Path $releaseDir 'zlib.dll'
    if (Test-Path $zlibPath) {
        Write-Host "Removing unused debug-CRT binary: $zlibPath"
        Remove-Item -Force $zlibPath
    }

    Write-Host 'Staging Store MSIX files (msix:build --store --build-windows false)...'
    & dart run msix:build --store --build-windows false
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    # Re-verify zlib.dll is absent after msix:build.
    if (Test-Path $zlibPath) {
        Remove-Item -Force $zlibPath
    }

    # Normalize Images\BadgeLogo.scale-*.png to WACK #45 compliant white (#FFFFFF) + alpha masks.
    $imagesDir = Join-Path $releaseDir 'Images'
    $badgeFiles = @(Get-ChildItem -Path $imagesDir -Filter 'BadgeLogo*.png' -ErrorAction SilentlyContinue)
    if ($badgeFiles.Count -eq 0) {
        throw "Expected BadgeLogo*.png files in $imagesDir after msix:build"
    }

    Add-Type -AssemblyName System.Drawing
    foreach ($file in $badgeFiles) {
        $srcBytes = [System.IO.File]::ReadAllBytes($file.FullName)
        $ms = New-Object System.IO.MemoryStream(, $srcBytes)
        $srcBmp = [System.Drawing.Bitmap]::new($ms)
        $dstBmp = New-Object System.Drawing.Bitmap($srcBmp.Width, $srcBmp.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
            for ($y = 0; $y -lt $srcBmp.Height; $y++) {
                for ($x = 0; $x -lt $srcBmp.Width; $x++) {
                    $px = $srcBmp.GetPixel($x, $y)
                    if ($px.A -eq 0) {
                        $dstBmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
                    } else {
                        # Preserve glyph luminance as alpha with strictly pure white (#FFFFFF) RGB.
                        $luma = [int][Math]::Round((0.299 * $px.R) + (0.587 * $px.G) + (0.114 * $px.B))
                        $outA = [int][Math]::Round(($luma * $px.A) / 255.0)
                        if ($outA -le 0) {
                            $dstBmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
                        } else {
                            $dstBmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($outA, 255, 255, 255))
                        }
                    }
                }
            }
            $srcBmp.Dispose()
            $ms.Dispose()
            $dstBmp.Save($file.FullName, [System.Drawing.Imaging.ImageFormat]::Png)
        } finally {
            if ($dstBmp) { $dstBmp.Dispose() }
        }

        # Verify 100% of pixels are strictly transparent (A=0) or pure white (RGB=#FFFFFF).
        $checkBmp = [System.Drawing.Bitmap]::new($file.FullName)
        try {
            for ($y = 0; $y -lt $checkBmp.Height; $y++) {
                for ($x = 0; $x -lt $checkBmp.Width; $x++) {
                    $c = $checkBmp.GetPixel($x, $y)
                    if ($c.A -ne 0 -and ($c.R -ne 255 -or $c.G -ne 255 -or $c.B -ne 255)) {
                        throw "Invalid BadgeLogo pixel in $($file.Name) at ($x,$y): ARGB=$($c.A),$($c.R),$($c.G),$($c.B)"
                    }
                }
            }
        } finally {
            $checkBmp.Dispose()
        }
    }
    Write-Host "Normalized and verified $($badgeFiles.Count) WACK-compliant monochrome BadgeLogo PNGs."

    # Verify zero Release binaries depend on MSVC debug CRT DLLs if dumpbin is installed.
    $dumpbin = Get-ChildItem 'C:\Program Files\Microsoft Visual Studio\*\*\VC\Tools\MSVC\*\bin\Hostx64\x64\dumpbin.exe' -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending | Select-Object -First 1
    if ($dumpbin) {
        $debugHits = @()
        foreach ($bin in Get-ChildItem -Path $releaseDir -Include *.exe, *.dll -Recurse) {
            $deps = & $dumpbin.FullName /dependents $bin.FullName 2>$null | Out-String
            if ($deps -match '(?i)(VCRUNTIME140D|ucrtbased|MSVCP140D)\.dll') {
                $debugHits += "$($bin.Name): $($Matches[0])"
            }
        }
        if ($debugHits.Count -gt 0) {
            throw "Debug CRT dependencies detected in Release binaries: $($debugHits -join '; ')"
        }
        Write-Host 'Verified zero MSVC debug CRT dependencies across all Release executables and DLLs.'
    }

    Write-Host 'Packing Store MSIX (msix:pack --store)...'
    & dart run msix:pack --store
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    $msix = Get-ChildItem -Path $releaseDir -Filter '*.msix' | Select-Object -First 1
    if (-not $msix) {
        throw "MSIX output missing in $releaseDir"
    }
    $hash = (Get-FileHash -Algorithm SHA256 $msix.FullName).Hash
    Write-Host "MSIX ready: $($msix.FullName) ($($msix.Length) bytes) SHA-256=$hash"
} finally {
    Pop-Location
}
