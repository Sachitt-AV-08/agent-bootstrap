<# 
.SYNOPSIS
    Set up browser-use Python environment for MCP
.DESCRIPTION
    Creates a dedicated virtual environment for browser-use with all dependencies
#>

[CmdletBinding()]
param(
    [string]$EnvPath = "$env:USERPROFILE\agent-stack\browser-use-env",
    [string]$PythonVersion = "3.12"
)

$ErrorActionPreference = 'Stop'

Write-Host "Setting up browser-use environment at $EnvPath..." -ForegroundColor Cyan

# Check Python
if (-not (Get-Command "python$PythonVersion" -ErrorAction SilentlyContinue) -and 
    -not (Get-Command "python" -ErrorAction SilentlyContinue)) {
    Write-Error "Python $PythonVersion not found. Install via winget: 'winget install Python.Python.3.12'"
    exit 1
}

# Create venv
if (Test-Path $EnvPath) {
    Write-Warn "Environment exists. Removing..."
    Remove-Item $EnvPath -Recurse -Force
}

python -m venv $EnvPath
Write-Success "Virtual environment created"

# Upgrade pip
& "$EnvPath\Scripts\python.exe" -m pip install --upgrade pip

# Install browser-use and dependencies
$packages = @(
    'browser-use',
    'playwright',
    'lxml',
    'cssselect',
    'pydantic',
    'pydantic-settings',
    'python-dotenv',
    'requests',
    'aiohttp',
    'websockets'
)

foreach ($pkg in $packages) {
    Write-Host "Installing $pkg..." -ForegroundColor Gray
    & "$EnvPath\Scripts\pip.exe" install $pkg
}

# Install Playwright browsers
Write-Host "Installing Playwright Chromium..." -ForegroundColor Cyan
& "$EnvPath\Scripts\playwright.exe" install chromium
& "$EnvPath\Scripts\playwright.exe" install-deps chromium 2>$null

# Verify
Write-Host "`nVerifying installation..." -ForegroundColor Cyan
& "$EnvPath\Scripts\python.exe" -c "import browser_use; print('browser-use OK')"
& "$EnvPath\Scripts\python.exe" -c "import playwright; print('playwright OK')"

Write-Success "`nBrowser-use environment ready at $EnvPath"
Write-Host "Binary: $EnvPath\Scripts\python.exe" -ForegroundColor Gray