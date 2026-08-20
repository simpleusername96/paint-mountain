param(
    [Parameter(Mandatory = $true)]
    [string]$OutputPath,
    [int]$FirstStage = 7,
    [int]$LastStage = 30,
    [int]$SeedCount = 2,
    [int]$MaxParallel = 4
)

$ErrorActionPreference = 'Stop'

if (-not $env:GODOT_BIN) {
    throw 'GODOT_BIN is not set.'
}
if ($FirstStage -lt 1 -or $LastStage -gt 30 -or $FirstStage -gt $LastStage) {
    throw 'Stage range must stay inside 1-30.'
}
if ($SeedCount -lt 1 -or $SeedCount -gt 8) {
    throw 'SeedCount must stay inside 1-8.'
}
if ($MaxParallel -lt 1 -or $MaxParallel -gt 8) {
    throw 'MaxParallel must stay inside 1-8.'
}

$requests = [System.Collections.Generic.List[object]]::new()
for ($stageNumber = $FirstStage; $stageNumber -le $LastStage; $stageNumber++) {
    $stageId = 'stage_{0:D2}' -f $stageNumber
    $defaultSeed = 1000 + $stageNumber
    for ($seedOffset = 0; $seedOffset -lt $SeedCount; $seedOffset++) {
        $requests.Add([pscustomobject]@{
            stage_id = $stageId
            deal_seed = $defaultSeed + $seedOffset
        })
    }
}

$projectRoot = (Get-Location).Path
$godotBin = $env:GODOT_BIN
$results = $requests | ForEach-Object -Parallel {
        Set-Location -LiteralPath $using:projectRoot
        $stageId = $_.stage_id
        $dealSeed = $_.deal_seed
        $output = & $using:godotBin --headless --path . --quit-after 30000 `
            --script res://tests/prototype_playable_witness_test.gd `
            -- "--stage=$stageId" "--deal-seed=$dealSeed" 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Witness failed for $stageId seed $dealSeed`n$($output -join [Environment]::NewLine)"
        }
        $line = $output | Where-Object { $_ -like 'PROTOTYPE_WITNESS *' } | Select-Object -Last 1
        if (-not $line) {
            throw "Witness emitted no structured record for $stageId seed $dealSeed"
        }
        $record = ($line -replace '^PROTOTYPE_WITNESS\s+', '') | ConvertFrom-Json
        [pscustomobject]@{
            stage_id = $stageId
            deal_seed = $dealSeed
            record = $record
        }
    } -ThrottleLimit $MaxParallel

$orderedResults = @($results | Sort-Object stage_id, deal_seed)
foreach ($result in $orderedResults) {
    Write-Output ("{0} seed={1} score={2:N1} clear={3}" -f `
        $result.stage_id, $result.deal_seed, [double]$result.record.paint_score,
        [bool]$result.record.cleared)
}
$records = @($orderedResults | ForEach-Object { $_.record })

$resolvedOutput = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $OutputPath))
$outputDirectory = [System.IO.Path]::GetDirectoryName($resolvedOutput)
[System.IO.Directory]::CreateDirectory($outputDirectory) | Out-Null
$payload = [ordered]@{
    generated_at = [DateTimeOffset]::Now.ToString('o')
    stage_range = @($FirstStage, $LastStage)
    seed_count = $SeedCount
    sample_count = $records.Count
    samples = $records
}
[System.IO.File]::WriteAllText(
    $resolvedOutput,
    ($payload | ConvertTo-Json -Depth 8),
    [System.Text.UTF8Encoding]::new($false)
)
Write-Output "Wrote $($records.Count) physical score samples to $resolvedOutput"
