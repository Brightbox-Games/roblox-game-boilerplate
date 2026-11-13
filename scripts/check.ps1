$ErrorActionPreference = 'Stop'
Push-Location (Split-Path $PSScriptRoot -Parent)
try {
    & lune run check
    if ($LASTEXITCODE -ne 0) { throw 'Check failed' }
} finally {
    Pop-Location
}
