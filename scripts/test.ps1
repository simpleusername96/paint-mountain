[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$GodotPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if (-not (Test-Path -LiteralPath $GodotPath -PathType Leaf)) {
    throw "Godot executable does not exist: $GodotPath"
}
$resolvedGodot = (Resolve-Path -LiteralPath $GodotPath).Path

$ordinaryTests = @(
    'version4_contract_test.gd',
    'stage_generation_test.gd',
    'mountain_range_mvp_test.gd',
    'phase8_front_transition_test.gd',
    'stage_mvp_permit_test.gd',
    'mechanism_placement_test.gd',
    'decoration_placement_test.gd',
    'phase2_test.gd',
    'phase2_physics_test.gd',
    'containment_wall_test.gd',
    'projectile_contact_test.gd',
    'projectile_settling_test.gd',
    'phase3_paint_test.gd',
    'paint_queue_determinism_test.gd',
    'phase3_projectile_paint_test.gd',
    'stage1_mvp_test.gd',
    'phase4_state_test.gd',
    'phase5_mechanism_test.gd',
    'phase6_content_test.gd',
    'aim_interaction_test.gd',
    'shot_observation_test.gd',
    'camera_safety_test.gd',
    'phase8_aiming_composition_test.gd',
    'phase7_ui_test.gd',
    'phase8_hud_truth_test.gd',
    'localization_ui_test.gd',
    'shot_feedback_test.gd',
    'replay_presentation_test.gd',
    'phase8_debug_test.gd',
    'phase8_reliability_test.gd'
)

function Invoke-GodotTest {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        [string[]]$EngineArguments = @(),
        [string[]]$UserArguments = @()
    )

    Write-Host "Running $ScriptName..."
    $arguments = @('--headless', '--path', $projectRoot) + $EngineArguments + @('--script', "res://tests/$ScriptName")
    if ($UserArguments.Count -gt 0) {
        $arguments += '--'
        $arguments += $UserArguments
    }
    & $resolvedGodot @arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$ScriptName failed with exit code $LASTEXITCODE."
    }
}

$primaryFailure = $null
try {
    foreach ($test in $ordinaryTests) {
        Invoke-GodotTest -ScriptName $test
    }
    Invoke-GodotTest -ScriptName 'phase8_performance_test.gd' -EngineArguments @('--resolution', '1920x1080')
    Invoke-GodotTest -ScriptName 'phase6_solution_test.gd'

    Invoke-GodotTest -ScriptName 'phase8_persistence_test.gd' -UserArguments @('--mode=cleanup')
    Invoke-GodotTest -ScriptName 'phase8_persistence_test.gd' -UserArguments @('--mode=write')
    Invoke-GodotTest -ScriptName 'phase8_persistence_test.gd' -UserArguments @('--mode=read')

    Invoke-GodotTest -ScriptName 'phase8_replay_process_test.gd' -UserArguments @('--mode=cleanup')
    Invoke-GodotTest -ScriptName 'phase8_replay_process_test.gd' -UserArguments @('--mode=record')
    Invoke-GodotTest -ScriptName 'phase8_replay_process_test.gd' -UserArguments @('--mode=replay')
}
catch {
    $primaryFailure = $_
}
finally {
    $cleanupFailures = [System.Collections.Generic.List[string]]::new()
    foreach ($cleanup in @(
        @{ Script = 'phase8_persistence_test.gd'; Mode = '--mode=cleanup' },
        @{ Script = 'phase8_replay_process_test.gd'; Mode = '--mode=cleanup' }
    )) {
        try {
            Invoke-GodotTest -ScriptName $cleanup.Script -UserArguments @($cleanup.Mode)
        }
        catch {
            $cleanupFailures.Add($_.Exception.Message)
        }
    }
    if ($cleanupFailures.Count -gt 0) {
        $cleanupMessage = 'Final cleanup failed: ' + ($cleanupFailures -join ' | ')
        if ($null -eq $primaryFailure) {
            $primaryFailure = [System.Management.Automation.RuntimeException]::new($cleanupMessage)
        }
        else {
            Write-Error $cleanupMessage
        }
    }
}

if ($null -ne $primaryFailure) {
    throw $primaryFailure
}
Write-Host 'Paint Mountain complete test suite passed.'
