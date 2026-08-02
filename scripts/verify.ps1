[CmdletBinding()]
param(
    [string]$GodotPath = $env:GODOT_BIN
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

if ([string]::IsNullOrWhiteSpace($GodotPath)) {
    $command = Get-Command godot4, godot -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -ne $command) {
        $GodotPath = $command.Source
    }
}

if ([string]::IsNullOrWhiteSpace($GodotPath) -or -not (Test-Path -LiteralPath $GodotPath -PathType Leaf)) {
    throw 'Godot was not found. Pass -GodotPath, set GODOT_BIN, or add godot4/godot to PATH.'
}

$resolvedGodot = (Resolve-Path -LiteralPath $GodotPath).Path

Write-Host 'Checking project import and script parsing...'
& $resolvedGodot --headless --path $projectRoot --editor --quit
if ($LASTEXITCODE -ne 0) {
    throw "Godot editor smoke check failed with exit code $LASTEXITCODE."
}

Write-Host 'Checking main-scene startup...'
& $resolvedGodot --headless --path $projectRoot --quit-after 3
if ($LASTEXITCODE -ne 0) {
    throw "Godot runtime smoke check failed with exit code $LASTEXITCODE."
}

Write-Host 'Paint Mountain verification passed.'
