[CmdletBinding()]
param([int]$StartAt = 1)

$ErrorActionPreference = 'Stop'

$paintExe = (Resolve-Path -LiteralPath 'builds/windows/PaintMountain.exe').Path
$captureEvidence = (Resolve-Path -LiteralPath '.agents/evidence/2026-08-21-stage-ui-final').Path
$captures = @(
    @{ Name = '01-main-menu-ko-1280x720.png'; Screen = 'main_menu'; Stage = 'stage_01'; Size = '1280x720' },
    @{ Name = '02-stage-select-stage08-ko-1280x720.png'; Screen = 'stage_select'; Stage = 'stage_08'; Size = '1280x720' },
    @{ Name = '03-briefing-stage08-ko-1280x720.png'; Screen = 'briefing'; Stage = 'stage_08'; Size = '1280x720' },
    @{ Name = '04-aiming-stage08-ko-1280x720.png'; Screen = 'aiming'; Stage = 'stage_08'; Size = '1280x720' },
    @{ Name = '05-queue-detail-stage08-ko-1280x720.png'; Screen = 'target_queue_description'; Stage = 'stage_08'; Size = '1280x720' },
    @{ Name = '06-map-stage08-ko-1280x720.png'; Screen = 'map_inspection'; Stage = 'stage_08'; Size = '1280x720' },
    @{ Name = '07-shot-follow-stage08-ko-1280x720.png'; Screen = 'shot_follow_midflight'; Stage = 'stage_08'; Size = '1280x720' },
    @{ Name = '08-pause-stage01-ko-1280x720.png'; Screen = 'pause'; Stage = 'stage_01'; Size = '1280x720' },
    @{ Name = '09-settings-stage01-ko-1280x720.png'; Screen = 'settings'; Stage = 'stage_01'; Size = '1280x720' },
    @{ Name = '10-clear-stage08-ko-1280x720.png'; Screen = 'target_clear_result'; Stage = 'stage_08'; Size = '1280x720' },
    @{ Name = '11-failure-stage08-ko-1280x720.png'; Screen = 'target_failed_result'; Stage = 'stage_08'; Size = '1280x720' },
    @{ Name = '12-main-menu-ko-640x360.png'; Screen = 'main_menu'; Stage = 'stage_01'; Size = '640x360' },
    @{ Name = '13-stage-select-stage30-ko-640x360.png'; Screen = 'stage_select'; Stage = 'stage_30'; Size = '640x360' },
    @{ Name = '14-briefing-stage08-ko-640x360.png'; Screen = 'briefing'; Stage = 'stage_08'; Size = '640x360' },
    @{ Name = '15-aiming-stage08-ko-640x360.png'; Screen = 'aiming'; Stage = 'stage_08'; Size = '640x360' },
    @{ Name = '16-queue-detail-stage08-ko-640x360.png'; Screen = 'target_queue_description'; Stage = 'stage_08'; Size = '640x360' },
    @{ Name = '17-map-stage08-ko-640x360.png'; Screen = 'map_inspection'; Stage = 'stage_08'; Size = '640x360' },
    @{ Name = '18-shot-follow-stage08-ko-640x360.png'; Screen = 'shot_follow_midflight'; Stage = 'stage_08'; Size = '640x360' },
    @{ Name = '19-pause-stage01-ko-640x360.png'; Screen = 'pause'; Stage = 'stage_01'; Size = '640x360' },
    @{ Name = '20-settings-stage01-ko-640x360.png'; Screen = 'settings'; Stage = 'stage_01'; Size = '640x360' },
    @{ Name = '21-clear-stage08-ko-640x360.png'; Screen = 'target_clear_result'; Stage = 'stage_08'; Size = '640x360' },
    @{ Name = '22-failure-stage08-ko-640x360.png'; Screen = 'target_failed_result'; Stage = 'stage_08'; Size = '640x360' },
    @{ Name = '23-stage-select-stage07-ko-1280x720.png'; Screen = 'stage_select'; Stage = 'stage_07'; Size = '1280x720' },
    @{ Name = '24-queue-detail-stage12-ko-1280x720.png'; Screen = 'target_queue_description'; Stage = 'stage_12'; Size = '1280x720' },
    @{ Name = '25-stage-select-stage18-ko-1280x720.png'; Screen = 'stage_select'; Stage = 'stage_18'; Size = '1280x720' },
    @{ Name = '26-queue-detail-stage24-ko-1280x720.png'; Screen = 'target_queue_description'; Stage = 'stage_24'; Size = '1280x720' },
    @{ Name = '27-result-stage30-ko-1280x720.png'; Screen = 'target_clear_result'; Stage = 'stage_30'; Size = '1280x720' },
    @{ Name = '28-negative-score-stage09-ko-1280x720.png'; Screen = 'target_negative_result'; Stage = 'stage_09'; Size = '1280x720' }
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
