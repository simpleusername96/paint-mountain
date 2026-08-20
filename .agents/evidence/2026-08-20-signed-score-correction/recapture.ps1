param(
    [string]$PaintExePath = 'builds/windows/PaintMountain.exe'
)

$ErrorActionPreference = 'Stop'

$paintExe = (Resolve-Path -LiteralPath $PaintExePath).Path
$captureEvidence = (Resolve-Path -LiteralPath '.agents/evidence/2026-08-20-signed-score-correction').Path
$captures = @(
    @{ Name = '01-negative-score-stage08-ko-1280x720.png'; Screen = 'target_negative_score'; Size = '1280x720' },
    @{ Name = '02-negative-result-stage08-ko-1280x720.png'; Screen = 'target_negative_result'; Size = '1280x720' },
    @{ Name = '03-negative-score-stage08-ko-640x360.png'; Screen = 'target_negative_score'; Size = '640x360' }
)

foreach ($capture in $captures) {
    $outputPath = Join-Path $captureEvidence $capture.Name
    $arguments = @(
        '--',
        '--capture-background',
        "--capture-screen=$($capture.Screen)",
        '--capture-stage=stage_08',
        "--capture-size=$($capture.Size)",
        '--capture-language=ko',
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
