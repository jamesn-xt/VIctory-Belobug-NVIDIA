param(
    [Parameter(Mandatory)][string]$GameExe,
    [Parameter(Mandatory)][string]$Config,
    [Parameter(Mandatory)][string]$DxcDirectory,
    [string]$Executable = (Join-Path $PSScriptRoot 'victory.exe'),
    [string]$LogDirectory = (Join-Path $PSScriptRoot 'logs'),
    [ValidateRange(30,7200)][int]$Seconds = 1800,
    [switch]$CheckOnly
)
$ErrorActionPreference = 'Stop'
$dxil = Join-Path $DxcDirectory 'dxil.dll'
$dxc = Join-Path $DxcDirectory 'dxc.exe'
foreach ($file in @($GameExe,$Config,$Executable,$dxil,$dxc)) {
    if (!(Test-Path -LiteralPath $file -PathType Leaf)) { throw "Missing file: $file" }
}
$Executable = (Resolve-Path -LiteralPath $Executable).Path
$GameExe = (Resolve-Path -LiteralPath $GameExe).Path
$Config = (Resolve-Path -LiteralPath $Config).Path
if ($CheckOnly) { Get-FileHash -LiteralPath $Executable; return }
if (Get-Process victory -ErrorAction SilentlyContinue) { throw 'Close the existing runtime instance first.' }
$memory = Get-CimInstance Win32_PerfFormattedData_PerfOS_Memory
if (($memory.CommitLimit-$memory.CommittedBytes) -lt 4GB) { throw 'Less than 4 GiB available commit.' }
New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
Get-ChildItem Env:VICTORY_* | Remove-Item
$env:VICTORY_CONFIG = $Config
$env:VICTORY_DXIL = $dxil
$env:VICTORY_PC_DXC = $dxc
$env:VICTORY_LOG = 'victory_gpu=info,warn'
$env:VICTORY_CARD_BUFFERS_MIN_KB = '64'
$env:VICTORY_CARD_BUFFERS_MB = '1280'
$env:VICTORY_AMBIENT = '0.6'
$env:VICTORY_AMBIENT_SKY = '0.36,0.05,0.4'
$prefix = Join-Path $LogDirectory (Get-Date -Format 'yyyyMMdd-HHmmss')
$gameProcess = Start-Process -FilePath $Executable -ArgumentList @('run',('"'+$GameExe+'"'),'--execute','--console','series-s') -WorkingDirectory $PSScriptRoot -WindowStyle Hidden -RedirectStandardOutput "$prefix.stdout.log" -RedirectStandardError "$prefix.stderr.log" -PassThru
$started = Get-Date
Write-Host "Started PID $($gameProcess.Id); logs $prefix.*.log."
Write-Host 'Focus the game. Enter=A, WASD=movement, IJKL=camera. No scripted input is sent.'
try {
    while (!$gameProcess.HasExited) {
        Start-Sleep -Seconds 5
        $gameProcess.Refresh()
        if ($gameProcess.HasExited) { break }
        $memory = Get-CimInstance Win32_PerfFormattedData_PerfOS_Memory
        if (($memory.CommitLimit-$memory.CommittedBytes) -lt 2GB) { Write-Host 'Stopped: commit guard.'; break }
        if (((Get-Date)-$started).TotalSeconds -ge $Seconds) { Write-Host 'Stopped: time limit.'; break }
    }
} finally {
    $gameProcess.Refresh()
    if (!$gameProcess.HasExited) { $gameProcess.Kill(); $gameProcess.WaitForExit() }
}
