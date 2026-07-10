$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$modelRoot = Join-Path $repoRoot "assets/live2d/models/Haru"
$archiveUrl = "https://codeload.github.com/Live2D/CubismWebSamples/zip/refs/heads/develop"
$workRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("rctool-live2d-" + [guid]::NewGuid().ToString("N"))
$zipPath = Join-Path $workRoot "CubismWebSamples-develop.zip"
$extractRoot = Join-Path $workRoot "extract"

New-Item -ItemType Directory -Force -Path $workRoot | Out-Null
New-Item -ItemType Directory -Force -Path $extractRoot | Out-Null
New-Item -ItemType Directory -Force -Path $modelRoot | Out-Null

try {
  Write-Host "Downloading Live2D CubismWebSamples archive..."
  Invoke-WebRequest `
    -Uri $archiveUrl `
    -OutFile $zipPath `
    -Headers @{ "User-Agent" = "RcTool-Live2D-Model-Downloader" }

  Write-Host "Extracting archive..."
  Expand-Archive -Path $zipPath -DestinationPath $extractRoot -Force

  $sourceModelRoot = Join-Path $extractRoot "CubismWebSamples-develop/Samples/Resources/Haru"
  if (!(Test-Path $sourceModelRoot)) {
    throw "Cannot find Haru model in extracted archive: $sourceModelRoot"
  }

  Write-Host "Copying Haru model files..."
  Copy-Item -Path (Join-Path $sourceModelRoot "*") -Destination $modelRoot -Recurse -Force

  Write-Host ""
  Write-Host "Haru sample model downloaded to: $modelRoot"
  Write-Host "Run flutter pub get after the model files are in place."
}
finally {
  if (Test-Path $workRoot) {
    Remove-Item -LiteralPath $workRoot -Recurse -Force
  }
}
