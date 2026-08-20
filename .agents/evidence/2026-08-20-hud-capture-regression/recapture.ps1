$ErrorActionPreference = 'Stop'

$paintExe = (Resolve-Path -LiteralPath 'builds/windows/PaintMountain.exe').Path
$captureEvidence = (Resolve-Path -LiteralPath '.agents/evidence/2026-08-20-hud-capture-regression').Path
$captures = @(
    @{ Name = '01-aiming-stage08-ko-1280x720.png'; Screen = 'aiming'; Stage = 'stage_08'; Size = '1280x720'; Language = 'ko' },
    @{ Name = '02-queue-description-stage08-ko-1280x720.png'; Screen = 'target_queue_description'; Stage = 'stage_08'; Size = '1280x720'; Language = 'ko' },
    @{ Name = '03-map-stage08-ko-1280x720.png'; Screen = 'map_inspection'; Stage = 'stage_08'; Size = '1280x720'; Language = 'ko' },
    @{ Name = '04-aiming-stage01-ko-640x360.png'; Screen = 'aiming'; Stage = 'stage_01'; Size = '640x360'; Language = 'ko' }
)

foreach ($capture in $captures) {
    $outputPath = Join-Path $captureEvidence $capture.Name
    $arguments = @(
        '--',
        '--capture-background',
        "--capture-screen=$($capture.Screen)",
        "--capture-stage=$($capture.Stage)",
        "--capture-size=$($capture.Size)",
        "--capture-language=$($capture.Language)",
        "--capture-output=$outputPath"
    )
    $process = Start-Process -FilePath $paintExe -WindowStyle Hidden -ArgumentList $arguments -PassThru -Wait
    if ($process.ExitCode -ne 0) {
        throw "Capture $($capture.Name) failed with exit $($process.ExitCode)"
    }
    $file = Get-Item -LiteralPath $outputPath
    if ($file.Length -le 0) {
        throw "Capture $($capture.Name) is empty"
    }
    Write-Output ("{0} OK {1} bytes" -f $capture.Name, $file.Length)
}
