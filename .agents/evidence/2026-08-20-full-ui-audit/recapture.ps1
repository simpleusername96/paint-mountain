$ErrorActionPreference = 'Stop'

$paintExe = (Resolve-Path -LiteralPath 'builds/windows/PaintMountain.exe').Path
$captureEvidence = (Resolve-Path -LiteralPath '.agents/evidence/2026-08-20-full-ui-audit').Path
$captures = @(
    @{ Name = '01-main-menu-ko-1280x720.png'; Screen = 'main_menu'; Stage = 'stage_01'; Size = '1280x720' },
    @{ Name = '02-stage-select-stage08-ko-1280x720.png'; Screen = 'stage_select'; Stage = 'stage_08'; Size = '1280x720' },
    @{ Name = '03-briefing-stage08-ko-1280x720.png'; Screen = 'briefing'; Stage = 'stage_08'; Size = '1280x720' },
    @{ Name = '04-aiming-stage08-ko-1280x720.png'; Screen = 'aiming'; Stage = 'stage_08'; Size = '1280x720' },
    @{ Name = '05-queue-detail-stage08-ko-1280x720.png'; Screen = 'target_queue_description'; Stage = 'stage_08'; Size = '1280x720' },
    @{ Name = '06-map-inspection-stage08-ko-1280x720.png'; Screen = 'map_inspection'; Stage = 'stage_08'; Size = '1280x720' },
    @{ Name = '07-shot-follow-stage08-ko-1280x720.png'; Screen = 'shot_follow_midflight'; Stage = 'stage_08'; Size = '1280x720' },
    @{ Name = '08-pause-stage01-ko-1280x720.png'; Screen = 'pause'; Stage = 'stage_01'; Size = '1280x720' },
    @{ Name = '09-settings-stage01-ko-1280x720.png'; Screen = 'settings'; Stage = 'stage_01'; Size = '1280x720' },
    @{ Name = '10-clear-result-stage08-ko-1280x720.png'; Screen = 'target_clear_result'; Stage = 'stage_08'; Size = '1280x720' },
    @{ Name = '11-failure-result-stage08-ko-1280x720.png'; Screen = 'target_negative_result'; Stage = 'stage_08'; Size = '1280x720' },
    @{ Name = '12-stage-select-stage30-ko-640x360.png'; Screen = 'stage_select'; Stage = 'stage_30'; Size = '640x360' },
    @{ Name = '13-briefing-stage08-ko-640x360.png'; Screen = 'briefing'; Stage = 'stage_08'; Size = '640x360' },
    @{ Name = '14-aiming-stage08-ko-640x360.png'; Screen = 'aiming'; Stage = 'stage_08'; Size = '640x360' },
    @{ Name = '15-settings-stage01-ko-640x360.png'; Screen = 'settings'; Stage = 'stage_01'; Size = '640x360' },
    @{ Name = '16-failure-result-stage08-ko-640x360.png'; Screen = 'target_negative_result'; Stage = 'stage_08'; Size = '640x360' }
)

foreach ($capture in $captures) {
    $outputPath = Join-Path $captureEvidence $capture.Name
    $arguments = @(
        '--',
        '--capture-background',
        "--capture-screen=$($capture.Screen)",
        "--capture-stage=$($capture.Stage)",
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
