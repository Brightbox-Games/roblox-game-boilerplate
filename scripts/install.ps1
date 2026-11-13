$ErrorActionPreference = 'Stop'
Push-Location (Split-Path $PSScriptRoot -Parent)
try {
    & rokit install
    if ($LASTEXITCODE -ne 0) { throw 'Rokit install failed' }
    & lune run install
    if ($LASTEXITCODE -ne 0) { throw 'Install failed' }
} finally {
    Pop-Location
}
