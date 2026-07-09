$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$modelRoot = Join-Path $repoRoot "assets/live2d/models/Haru"
$baseUrl = "https://raw.githubusercontent.com/Live2D/CubismWebSamples/develop/Samples/Resources/Haru"

$files = @(
  "Haru.model3.json",
  "Haru.cdi3.json",
  "Haru.physics3.json",
  "Haru.moc3",
  "Haru.2048/texture_00.png",
  "Haru.2048/texture_01.png",
  "Haru.2048/texture_02.png",
  "expressions/exp_01.exp3.json",
  "expressions/exp_02.exp3.json",
  "expressions/exp_03.exp3.json",
  "motions/idle_00.motion3.json",
  "motions/idle_01.motion3.json",
  "motions/idle_02.motion3.json",
  "motions/idle_03.motion3.json",
  "motions/tapBody_00.motion3.json",
  "motions/tapBody_01.motion3.json",
  "motions/tapBody_02.motion3.json",
  "motions/tapBody_03.motion3.json"
)

New-Item -ItemType Directory -Force -Path $modelRoot | Out-Null

foreach ($file in $files) {
  $target = Join-Path $modelRoot $file
  $targetDir = Split-Path -Parent $target
  New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

  $url = "$baseUrl/$file"
  Write-Host "Downloading $file"
  Invoke-WebRequest -Uri $url -OutFile $target
}

Write-Host ""
Write-Host "Haru sample model downloaded to: $modelRoot"
Write-Host "Run flutter pub get after the model files are in place."
