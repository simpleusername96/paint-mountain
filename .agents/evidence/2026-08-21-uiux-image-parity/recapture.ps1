[CmdletBinding()]
param([int]$StartAt = 1)

$ErrorActionPreference = 'Stop'

$paintExe = (Resolve-Path -LiteralPath 'builds/windows/PaintMountain.exe').Path
$captureEvidence = (Resolve-Path -LiteralPath '.agents/evidence/2026-08-21-uiux-image-parity').Path
$captures = @(
    @{ Name = '01-main-menu-hover-ko-1280x720.png'; Screen = 'main_menu_hover'; Stage = 'stage_01'; Size = '1280x720' },
    @{ Name = '02-stage-select-stage08-ko-1280x720.png'; Screen = 'stage_select'; Stage = 'stage_08'; Size = '1280x720' },
    @{ Name = '03-aim-entry-stage08-ko-1280x720.png'; Screen = 'aiming'; Stage = 'stage_08'; Size = '1280x720' },
    @{ Name = '04-aim-center-stage08-ko-1280x720.png'; Screen = 'target_center_score'; Stage = 'stage_08'; Size = '1280x720' },
    @{ Name = '05-aim-overflow-stage08-ko-1280x720.png'; Screen = 'target_overflow_score'; Stage = 'stage_08'; Size = '1280x720' },
    @{ Name = '06-ball-detail-stage08-ko-1280x720.png'; Screen = 'target_queue_description'; Stage = 'stage_08'; Size = '1280x720' },
    @{ Name = '07-map-stage08-ko-1280x720.png'; Screen = 'map_inspection'; Stage = 'stage_08'; Size = '1280x720' },
    @{ Name = '08-shot-follow-stage08-ko-1280x720.png'; Screen = 'shot_follow_midflight'; Stage = 'stage_08'; Size = '1280x720' },
    @{ Name = '09-pause-stage01-ko-1280x720.png'; Screen = 'pause'; Stage = 'stage_01'; Size = '1280x720' },
    @{ Name = '10-settings-stage01-ko-1280x720.png'; Screen = 'settings'; Stage = 'stage_01'; Size = '1280x720' },
    @{ Name = '11-clear-stage08-ko-1280x720.png'; Screen = 'target_clear_result'; Stage = 'stage_08'; Size = '1280x720' },
    @{ Name = '12-failure-stage08-ko-1280x720.png'; Screen = 'target_failed_result'; Stage = 'stage_08'; Size = '1280x720' },
    @{ Name = '13-main-menu-focus-ko-640x360.png'; Screen = 'main_menu_focus'; Stage = 'stage_01'; Size = '640x360' },
    @{ Name = '14-stage-select-stage08-ko-640x360.png'; Screen = 'stage_select'; Stage = 'stage_08'; Size = '640x360' },
    @{ Name = '15-aim-center-stage08-ko-640x360.png'; Screen = 'target_center_score'; Stage = 'stage_08'; Size = '640x360' },
    @{ Name = '16-ball-detail-stage08-ko-640x360.png'; Screen = 'target_queue_description'; Stage = 'stage_08'; Size = '640x360' },
    @{ Name = '17-map-stage08-ko-640x360.png'; Screen = 'map_inspection'; Stage = 'stage_08'; Size = '640x360' },
    @{ Name = '18-shot-follow-stage08-ko-640x360.png'; Screen = 'shot_follow_midflight'; Stage = 'stage_08'; Size = '640x360' },
    @{ Name = '19-pause-stage01-ko-640x360.png'; Screen = 'pause'; Stage = 'stage_01'; Size = '640x360' },
    @{ Name = '20-settings-stage01-ko-640x360.png'; Screen = 'settings'; Stage = 'stage_01'; Size = '640x360' },
    @{ Name = '21-clear-stage08-ko-640x360.png'; Screen = 'target_clear_result'; Stage = 'stage_08'; Size = '640x360' },
    @{ Name = '22-failure-stage08-ko-640x360.png'; Screen = 'target_failed_result'; Stage = 'stage_08'; Size = '640x360' },
    @{ Name = '23-ball-detail-stage12-ko-1280x720.png'; Screen = 'target_queue_description'; Stage = 'stage_12'; Size = '1280x720' },
    @{ Name = '24-ball-detail-stage24-ko-1280x720.png'; Screen = 'target_queue_description'; Stage = 'stage_24'; Size = '1280x720' },
    @{ Name = '25-aim-negative-stage09-ko-1280x720.png'; Screen = 'target_negative_score'; Stage = 'stage_09'; Size = '1280x720' },
    @{ Name = '26-aim-zero-weight-stage06-ko-1280x720.png'; Screen = 'target_zero_weight_score'; Stage = 'stage_06'; Size = '1280x720' },
    @{ Name = '27-stage-select-stage30-ko-1280x720.png'; Screen = 'stage_select'; Stage = 'stage_30'; Size = '1280x720' }
)

foreach ($capture in $captures) {
    if ([int]($capture.Name.Split('-', 2)[0]) -lt $StartAt) {
        continue
    }
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
    if ($capture.Screen -eq 'target_queue_description') {
        $arguments += '--capture-settle-frames=0'
    }
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
