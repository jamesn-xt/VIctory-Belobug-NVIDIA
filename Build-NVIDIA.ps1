[CmdletBinding()]
param(
    [string]$OutputDirectory = (Join-Path $env:LOCALAPPDATA 'Belobug NVIDIA')
)
$ErrorActionPreference = 'Stop'
$OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
for ($parent = [IO.DirectoryInfo]::new($OutputDirectory); $parent; $parent = $parent.Parent) {
    if (Test-Path -LiteralPath (Join-Path $parent.FullName '.victory-root')) {
        throw 'Choose an output directory outside the source checkout.'
    }
}
$names = @('victory.exe')
foreach ($process in Get-Process -ErrorAction SilentlyContinue) {
    if ($process.Path -and $names -contains [IO.Path]::GetFileName($process.Path) -and
        [IO.Path]::GetDirectoryName($process.Path) -eq $OutputDirectory) {
        throw 'Close the Belobug NVIDIA programs in the output directory before updating.'
    }
}
Push-Location -LiteralPath $PSScriptRoot
try {
    & cargo build --locked --release -p victory --features diagnostics --bins
    if ($LASTEXITCODE -ne 0) { throw 'Belobug NVIDIA build failed.' }
    $target = if ($env:CARGO_TARGET_DIR) { $env:CARGO_TARGET_DIR } else { Join-Path $PSScriptRoot 'target' }
    $release = Join-Path $target 'release'
    foreach ($name in $names) {
        if (!(Test-Path -LiteralPath (Join-Path $release $name))) { throw "Build output missing: $name" }
    }
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    & (Join-Path $PSScriptRoot 'Initialize-FormatTables.ps1') -Destination (Join-Path $OutputDirectory 'bcpack-tables.bin')
    foreach ($name in $names) {
        Copy-Item -LiteralPath (Join-Path $release $name) -Destination (Join-Path $OutputDirectory $name)
    }
    Copy-Item -LiteralPath @((Join-Path $PSScriptRoot 'LICENSE'), (Join-Path $PSScriptRoot 'Initialize-FormatTables.ps1'), (Join-Path $PSScriptRoot 'scripts/Launch-NVIDIA.ps1'), (Join-Path $PSScriptRoot 'victory.example.toml')) -Destination $OutputDirectory
} finally { Pop-Location }
Write-Host "Built Belobug NVIDIA in $OutputDirectory"
Write-Host 'Use Launch-NVIDIA.ps1 to run the Series S profile.'
