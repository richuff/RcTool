$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$vendorRoot = Join-Path $repoRoot "assets/live2d/viewer/vendor"

$files = @(
  @{
    Url = "https://cubism.live2d.com/sdk-web/cubismcore/live2dcubismcore.min.js"
    File = "live2dcubismcore.min.js"
  },
  @{
    Url = "https://cdn.jsdelivr.net/npm/pixi.js@6.5.10/dist/browser/pixi.min.js"
    File = "pixi.min.js"
  },
  @{
    Url = "https://cdn.jsdelivr.net/npm/pixi-live2d-display@0.4.0/dist/cubism4.min.js"
    File = "pixi-live2d-display-cubism4.min.js"
  }
)

New-Item -ItemType Directory -Force -Path $vendorRoot | Out-Null

foreach ($item in $files) {
  $target = Join-Path $vendorRoot $item.File
  Write-Host "Downloading $($item.File)"
  Invoke-WebRequest `
    -Uri $item.Url `
    -OutFile $target `
    -Headers @{ "User-Agent" = "RcTool-Live2D-Vendor-Downloader" }
}

Write-Host ""
Write-Host "Live2D viewer vendor files downloaded to: $vendorRoot"
