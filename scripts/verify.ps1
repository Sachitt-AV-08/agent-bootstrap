<# 
.SYNOPSIS
    Verify agent-bootstrap installation
.DESCRIPTION
    Runs comprehensive checks on OpenCode, MCPs, Python env, and dependencies
#>

[CmdletBinding()]
param(
    [switch]$Verbose,
    [switch]$Fix
)

$ErrorActionPreference = 'Continue'

$Green  = [ConsoleColor]::Green
$Red    = [ConsoleColor]::Red
$Yellow = [ConsoleColor]::Yellow
$Cyan   = [ConsoleColor]::Cyan

function Test-Check {
    param([string]$Name, [scriptblock]$Test, [string]$FixHint = "")
    Write-Host -NoNewline "[$Name] "
    try {
        $result = & $Test
        if ($result) {
            Write-Host "PASS" -ForegroundColor $Green
            return $true
        } else {
            Write-Host "FAIL" -ForegroundColor $Red
            if ($FixHint) { Write-Host "  Fix: $FixHint" -ForegroundColor $Yellow }
            return $false
        }
    } catch {
        Write-Host "ERROR" -ForegroundColor $Red
        if ($Verbose) { Write-Host "  $_" -ForegroundColor $Red }
        if ($FixHint) { Write-Host "  Fix: $FixHint" -ForegroundColor $Yellow }
        return $false
    }
}

$allPassed = $true

Write-Host "`n==========================================" -ForegroundColor $Cyan
Write-Host "  agent-bootstrap Verification" -ForegroundColor $Cyan
Write-Host "==========================================`n" -ForegroundColor $Cyan

# 1. OpenCode CLI
$allPassed &= Test-Check "OpenCode CLI" {
    $ver = opencode --version 2>$null
    $ver -match '\d+\.\d+\.\d+'
} "Reinstall: npm install -g @opencode/cli@latest"

# 2. OpenCode Doctor
$allPassed &= Test-Check "OpenCode Doctor" {
    $out = opencode doctor 2>&1
    $out -notmatch 'error|fail|warn' -or $out -match 'OK|pass|healthy'
} "Run 'opencode doctor' for details"

# 3. MCP Config exists
$mcpPath = "$env:USERPROFILE\.config\opencode\mcp.json"
$allPassed &= Test-Check "MCP Config" {
    Test-Path $mcpPath
} "Run install.ps1 to generate"

# 4. browser-use Python
$buPython = "$env:USERPROFILE\agent-stack\browser-use-env\Scripts\python.exe"
$allPassed &= Test-Check "browser-use Python" {
    Test-Path $buPython -and (& $buPython -c "import browser_use; print('OK')" 2>$null)
} "Run scripts\setup-browser-use.ps1"

# 5. Playwright Chromium
$allPassed &= Test-Check "Playwright Chromium" {
    & $buPython -m playwright install chromium 2>&1 | Select-String -Pattern 'already|installed|done' -Quiet
} "Run: $buPython -m playwright install chromium"

# 6. Python dependencies
$pyDeps = @('playwright', 'yt_dlp', 'chromadb', 'qdrant_client', 'mem0', 'linkedin_api', 'instagrapi')
foreach ($dep in $pyDeps) {
    $allPassed &= Test-Check "Python: $dep" {
        & $buPython -c "import $dep; print('OK')" 2>$null
    } "Run: $buPython -m pip install $dep"
}

# 7. Node/npm
$allPassed &= Test-Check "Node.js" { (node --version 2>$null) -match '^v\d+' } "Install Node LTS"
$allPassed &= Test-Check "npm" { (npm --version 2>$null) -match '^\d+' } "Reinstall Node"

# 8. Git/GH
$allPassed &= Test-Check "Git" { (git --version 2>$null) -match 'git version' } "winget install Git.Git"
$allPassed &= Test-Check "GitHub CLI" { (gh --version 2>$null) -match 'gh version' } "winget install GitHub.cli"

# 9. FFmpeg
$allPassed &= Test-Check "FFmpeg" { (ffmpeg -version 2>$null) -match 'ffmpeg version' } "winget install Gyan.FFmpeg"

# 10. uv
$allPassed &= Test-Check "uv" { (uv --version 2>$null) -match 'uv \d+' } "winget install astral-sh.uv"

# 11. Config files
$configDir = "$env:USERPROFILE\.config\opencode"
$configFiles = @('opencode.jsonc', 'tui.json', 'AGENTS.md')
foreach ($cf in $configFiles) {
    $allPassed &= Test-Check "Config: $cf" { Test-Path "$configDir\$cf" } "Re-run installer"
}

# 12. MCP Registrations
$allPassed &= Test-Check "MCP: browser-use" { opencode mcp list 2>$null | Select-String 'browser-use' -Quiet } "opencode mcp add browser-use"
$allPassed &= Test-Check "MCP: context7" { opencode mcp list 2>$null | Select-String 'context7' -Quiet } "opencode mcp add context7"
$allPassed &= Test-Check "MCP: vision" { opencode mcp list 2>$null | Select-String 'vision' -Quiet } "opencode mcp add vision"

# Summary
Write-Host "`n==========================================" -ForegroundColor $Cyan
if ($allPassed) {
    Write-Host "  ALL CHECKS PASSED" -ForegroundColor $Green
} else {
    Write-Host "  SOME CHECKS FAILED" -ForegroundColor $Red
}
Write-Host "==========================================`n" -ForegroundColor $Cyan

exit (if ($allPassed) { 0 } else { 1 })