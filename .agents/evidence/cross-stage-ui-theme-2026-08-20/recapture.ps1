$ErrorActionPreference = 'Stop'

$paintExe = (Resolve-Path -LiteralPath 'builds/windows/PaintMountain.exe').Path
$captureEvidence = (Resolve-Path -LiteralPath '.agents/evidence/cross-stage-ui-theme-2026-08-20').Path
$captures = @(
    @{ Name = '01-main-menu-ko-1280x720.png'; Screen = 'main_menu'; Stage = 'stage_01'; Size = '1280x720'; Language = 'ko' },
    @{ Name = '02-stage-select-stage30-ko-1280x720.png'; Screen = 'stage_select'; Stage = 'stage_30'; Size = '1280x720'; Language = 'ko' },
    @{ Name = '03-pause-stage01-ko-1280x720.png'; Screen = 'pause'; Stage = 'stage_01'; Size = '1280x720'; Language = 'ko' },
    @{ Name = '04-settings-stage01-ko-1280x720.png'; Screen = 'settings'; Stage = 'stage_01'; Size = '1280x720'; Language = 'ko' },
    @{ Name = '05-briefing-stage01-ko-1280x720.png'; Screen = 'briefing'; Stage = 'stage_01'; Size = '1280x720'; Language = 'ko' },
    @{ Name = '06-aiming-stage01-ko-1280x720.png'; Screen = 'aiming'; Stage = 'stage_01'; Size = '1280x720'; Language = 'ko' },
    @{ Name = '07-clear-stage01-ko-1280x720.png'; Screen = 'target_clear_result'; Stage = 'stage_01'; Size = '1280x720'; Language = 'ko' },
    @{ Name = '08-aiming-stage03-ko-1280x720.png'; Screen = 'aiming'; Stage = 'stage_03'; Size = '1280x720'; Language = 'ko' },
    @{ Name = '09-shot-follow-stage03-ko-1280x720.png'; Screen = 'shot_follow_midflight'; Stage = 'stage_03'; Size = '1280x720'; Language = 'ko' },
    @{ Name = '10-queue-description-stage03-ko-1280x720.png'; Screen = 'target_queue_description'; Stage = 'stage_03'; Size = '1280x720'; Language = 'ko' },
    @{ Name = '11-failed-stage03-ko-1280x720.png'; Screen = 'target_failed_result'; Stage = 'stage_03'; Size = '1280x720'; Language = 'ko' },
    @{ Name = '12-aiming-stage07-ko-1280x720.png'; Screen = 'aiming'; Stage = 'stage_07'; Size = '1280x720'; Language = 'ko' },
    @{ Name = '13-result-stage07-ko-1280x720.png'; Screen = 'manual_result'; Stage = 'stage_07'; Size = '1280x720'; Language = 'ko' },
    @{ Name = '14-aiming-stage30-en-1920x1080.png'; Screen = 'aiming'; Stage = 'stage_30'; Size = '1920x1080'; Language = 'en' },
    @{ Name = '15-map-stage30-en-1920x1080.png'; Screen = 'map_inspection'; Stage = 'stage_30'; Size = '1920x1080'; Language = 'en' },
    @{ Name = '16-result-stage30-en-1920x1080.png'; Screen = 'manual_result'; Stage = 'stage_30'; Size = '1920x1080'; Language = 'en' },
    @{ Name = '17-aiming-stage01-ko-640x360.png'; Screen = 'aiming'; Stage = 'stage_01'; Size = '640x360'; Language = 'ko' },
    @{ Name = '18-stage-select-stage01-en-640x360.png'; Screen = 'stage_select'; Stage = 'stage_01'; Size = '640x360'; Language = 'en' },
    @{ Name = '19-settings-stage01-ko-640x360.png'; Screen = 'settings'; Stage = 'stage_01'; Size = '640x360'; Language = 'ko' },
    @{ Name = '20-result-stage01-ko-640x360.png'; Screen = 'target_clear_result'; Stage = 'stage_01'; Size = '640x360'; Language = 'ko' }
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
