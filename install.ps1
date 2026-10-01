#Requires -Version 7.0
<#
.SYNOPSIS
  agent-bootstrap installer - takes any machine to a 10/10 AI agent setup.

.DESCRIPTION
  One command installs OpenCode V2, 163 agent definitions, fleet orchestration
  commands, skill packs, and MCP servers. Everything is free-tier and local-first.

  Install:
    pwsh -c "irm https://raw.githubusercontent.com/Sachitt-AV-08/agent-bootstrap/main/install.ps1 | iex"

  Or from a clone:
    ./install.ps1 --all

  Run with no flags to install everything. Your existing configuration is
  backed up before anything is written, and a rollback path is printed at the
  end. If a step fails, the installer explains what broke and what to run -
  it never leaves a half-written config behind.

.PARAMETER All
  Install every domain (default when no selector is given).

.PARAMETER Minimal
  Install only the core domain: agents, commands, OpenCode V2. No Python deps.

.PARAMETER Domains
  Selective install. Available: core, security, performance, api, data-ml, frontend,
  backend-infra, testing, docs-dx, migration, specialty, meta, content, research,
  debugging, web-scraping, social-media, memory, orchestration

.PARAMETER With
  Also register project MCP servers: orvima, parley, genesis

.PARAMETER SkipDeps
  Do not install system or Python dependencies.

.PARAMETER DryRun
  Print what would happen without writing anything.

.EXAMPLE
  ./install.ps1 --all --with orvima,parley,genesis

.EXAMPLE
  ./install.ps1 --domains web-scraping,memory

.NOTES
  Existing ~/.config/opencode is backed up to ~/.config/opencode-backup-<timestamp>
  before anything is written. Rollback instructions are printed at the end.
#>

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Flags are parsed by hand out of $args rather than through a `param()` block.
# PowerShell's declarative binding rejects `--domains=research,debugging`,
# splits array tokens across parameters, and drops unrecognised flags silently -
# all of which produce a config that is subtly wrong instead of an error.
# A hand-rolled parser sees exactly what the user typed. Both `-flag` and
# `--flag` spellings are accepted, as is `-Flag` (PowerShell's own convention).
$All          = $false
$Minimal      = $false
$SkipDeps     = $false
$SkipMcp      = $false
$Force        = $false
$DryRun       = $false
$SelfTest     = $false
$Interactive  = $false
$InstallDir   = ""
$TargetConfig = ""
$Model        = "kilo/kilo-auto/free"
$SmallModel   = "kilo/kilo-auto/small"

# `$args` is function-scoped in PowerShell, so inside a helper it refers to
# that helper's own arguments, not the script's. Capture the script's arguments
# once here and have the parser read this instead.
$Script:RawArgs = @($args)
$script:Domains = @()
$script:With    = @()

# Declared up front, not created on first use: Set-StrictMode -Version Latest
# throws when a variable is read before it has been assigned, and both are
# caches consulted before anything populates them.
$script:BuPython         = $null
$script:BuPythonResolved = $false
$script:SourceRoot       = ''

# --------------------------- constants ---------------------------

$Script:RepoName    = 'agent-bootstrap'
$Script:UserHome    = $HOME
$script:Help        = $false

$Script:Usage = @'
  agent-bootstrap - one command to a full AI agent environment

  USAGE
    ./install.ps1 [options]     install everything (no flags needed)
    irm https://raw.githubusercontent.com/Sachitt-AV-08/agent-bootstrap/main/install.ps1 | iex

  WHAT TO INSTALL
    --all                  every domain (this is the default)
    --minimal              core agents and commands only, no Python packages
    --domains a,b,c        install specific domains
    --interactive          be asked what to install, in plain language
    --with orvima,parley   also register these project MCP servers

  SAFETY
    --dry-run              show what would happen, change nothing
    --skip-deps            do not install system or Python packages
    --skip-mcp             do not touch MCP server configuration
    --force                overwrite an existing checkout without asking

  MODELS   (the Kilo gateway is free-tier; paid ids return HTTP 402)
    --model kilo/kilo-auto/free
    --small-model kilo/kilo-auto/small

  PATHS
    --install-dir <dir>    where to keep the agent-bootstrap checkout
    --target-config <dir>  where to write opencode.jsonc

  OTHER
    --self-test            verify the installer's own code, install nothing
    --help                 this message

  EXAMPLES
    ./install.ps1                      install everything
    ./install.ps1 --interactive        be asked what to install
    ./install.ps1 --dry-run            preview, change nothing
    ./install.ps1 --minimal            just the essentials
    ./install.ps1 --self-test         check the installer works
    ./install.ps1 --domains research,debugging
'@

$Script:AllDomains  = @(
  'core','security','performance','api','data-ml','frontend','backend-infra',
  'testing','docs-dx','migration','specialty','meta','content','research',
  'debugging','web-scraping','social-media','memory','orchestration','projects'
)

# Free, local-first dependency sets per domain.
$Script:PyDeps = @{
  'web-scraping' = @(
    'yt-dlp','youtube-transcript-api','httpx','beautifulsoup4','lxml','selectolax',
    'trafilatura','newspaper3k','scrapy'
  )
  'social-media' = @('linkedin-api','instagrapi')
  'memory'       = @('chromadb','qdrant-client','mem0ai','faiss-cpu','sqlite-vec')
  'content'      = @('Pillow','imageio-ffmpeg')
  'research'     = @('arxiv','semanticscholar','pandas')
}

# The PyPI package name is usually not the module you import. Probing for the
# package name (newspaper3k, qdrant_client, mem0ai) reports a healthy install as
# missing, which is a false alarm that sends users chasing a problem they do not
# have. This maps only the names that actually differ; everything else keeps the
# package name with dashes turned into underscores.
$Script:PyImportName = @{
  'newspaper3k'      = 'newspaper'
  'qdrant-client'    = 'qdrant_client'
  'mem0ai'           = 'mem0'
  'faiss-cpu'        = 'faiss'
  'sqlite-vec'       = 'sqlite_vec'
  'beautifulsoup4'   = 'bs4'
  'youtube-transcript-api' = 'youtube_transcript_api'
  'Pillow'           = 'PIL'
  'imageio-ffmpeg'   = 'imageio_ffmpeg'
  'semanticscholar'  = 'semanticscholar'
  'instagrapi'       = 'instagrapi'
  'linkedin-api'     = 'linkedin_api'
  'trafilatura'      = 'trafilatura'
  'yt-dlp'           = 'yt_dlp'
  'selectolax'       = 'selectolax'
  'scrapy'           = 'scrapy'
  'arxiv'            = 'arxiv'
  'pandas'           = 'pandas'
  'lxml'             = 'lxml'
  'httpx'            = 'httpx'
  'chromadb'         = 'chromadb'
}
$Script:SystemDeps = @{
  'core'          = @()
  'web-scraping'  = @('ffmpeg')
  'content'       = @('ffmpeg')
  'debugging'     = @()
}

# --------------------------- ui helpers ---------------------------

$Script:Step = 0
function Write-Step([string]$msg) {
  $Script:Step++
  Write-Host ''
  Write-Host "  [$Script:Step] $msg" -ForegroundColor Cyan
}
function Write-Ok([string]$msg)   { Write-Host "      OK $msg" -ForegroundColor Green }
function Write-Warn2([string]$msg){ Write-Host "      ! $msg" -ForegroundColor Yellow }
function Write-Err2([string]$msg) { Write-Host "      X $msg" -ForegroundColor Red }
function Write-Info([string]$msg) { Write-Host "      $msg" -ForegroundColor DarkGray }

function Test-Cmd([string]$name) {
  [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

# --------------------------- error reporting ----------------------

$Script:DocRoot = 'https://github.com/Sachitt-AV-08/agent-bootstrap/blob/main/docs'

<#
.SYNOPSIS
  Abort with an explanation a non-expert can act on.
.DESCRIPTION
  Every fatal path in this installer routes through here. A bare
  `throw "property X cannot be found"` tells a newcomer nothing; each error
  below states what broke, what it costs them, and the exact command to run.
  Exit code 1 for user/environment problems, 2 for installer bugs - a
  non-zero code is what a CI wrapper keys off, so it must never be 0 here.
#>
function Stop-Install {
  param(
    [Parameter(Mandatory)][string]$Code,
    [string]$What = '',
    [string]$Impact = '',
    [string]$Fix = '',
    [string]$Doc = "$Script:DocRoot/guides/troubleshooting.md",
    [int]$ExitCode = 1
  )
  Write-Host ''
  Write-Host '  Something went wrong - nothing was broken by this run.' -ForegroundColor Yellow
  Write-Host '  ----------------------------------------------------' -ForegroundColor DarkGray
  Write-Host "  [$Code]" -ForegroundColor Red
  if ($What)    { Write-Host "  What happened:  $What" }
  if ($Impact)  { Write-Host "  Why it matters: $Impact" }
  if ($Fix)     { Write-Host "  What to do:     $Fix" -ForegroundColor Green }
  if ($Doc)     { Write-Host "  More help:      $Doc" -ForegroundColor DarkGray }
  Write-Host '  ----------------------------------------------------' -ForegroundColor DarkGray
  Write-Host '  Your previous configuration is untouched. Nothing was overwritten.' -ForegroundColor DarkGray
  Write-Host ''
  exit $ExitCode
}

function Assert-Node {
  if (-not (Test-Cmd 'npm')) {
    $fix = if ($IsWindows) { 'winget install OpenJS.NodeJS.LTS' }
           elseif (Test-Cmd 'brew') { 'brew install node@20' }
           else { 'see https://nodejs.org/en/download' }
    Stop-Install -Code 'E_NO_NODE' `
      -What 'Node.js 20 or newer was not found on this machine.' `
      -Impact 'OpenCode is a Node application, so nothing can be installed without it.' `
      -Fix "Install Node 20+, then open a new terminal and run this again. On Windows: $fix"
  }
}

# --------------------------- resolution ---------------------------

function Write-Usage {
  Write-Host ''
  Write-Host '  agent-bootstrap' -ForegroundColor White
  Write-Host '  ------------------------------------------------' -ForegroundColor DarkGray
  Write-Host $Script:Usage
  Write-Host ''
}

function Get-FlagKey([string]$name) {
  # One canonical key per flag, so every spelling a user might type collapses to
  # the same lookup: --skip-deps, -SkipDeps, --skipdeps and /SKIP_DEPS are all
  # the same flag. PowerShell users are used to -PascalCase, and refusing that
  # would break muscle memory.
  ($name -replace '[-_]', '').ToLowerInvariant()
}

function Resolve-Selection {
  # $args is parsed literally, so every spelling a user might type resolves to
  # the same variable.
  $switches = @{
    'all'='All'; 'minimal'='Minimal'; 'force'='Force'; 'f'='Force'
    'skipdeps'='SkipDeps'; 'skipmcp'='SkipMcp'; 'dryrun'='DryRun'
    'selftest'='SelfTest'; 'help'='Help'; 'h'='Help'; '?'='Help'
    'interactive'='Interactive'; 'i'='Interactive'; 'wizard'='Interactive'
  }
  # canonical key -> variable name. The display name and example are kept
  # separately because the canonical key has no dashes ("targetconfig") and
  # would be confusing to show a user in an error message.
  $valued = @{
    'domains'='Domains'; 'with'='With'; 'model'='Model'; 'smallmodel'='SmallModel'
    'installdir'='InstallDir'; 'targetconfig'='TargetConfig'
  }
  $valuedName = @{
    'Domains'='--domains'; 'With'='--with'; 'Model'='--model'
    'SmallModel'='--small-model'; 'InstallDir'='--install-dir'
    'TargetConfig'='--target-config'
  }
  $valuedExample = @{
    'Domains'   = "$($Script:AllDomains[0]),$($Script:AllDomains[12])"
    'With'      = 'orvima,parley'
    'Model'     = 'kilo/kilo-auto/free'
    'SmallModel'= 'kilo/kilo-auto/small'
    'InstallDir'= "$HOME/.local/share/agent-bootstrap"
    'TargetConfig' = "$HOME/.config/opencode"
  }

  $domains  = New-Object System.Collections.Generic.List[string]
  $with     = New-Object System.Collections.Generic.List[string]
  $expect   = $null
  $expectName = $null
  $Help     = $false

  $raw = $Script:RawArgs
  for ($i = 0; $i -lt $raw.Count; $i++) {
    $tok = [string]$raw[$i]
    if (-not $tok) { continue }

    # a value the previous flag was waiting for
    if ($null -ne $expect) {
      $targets = $expect
      if ($targets -eq 'Domains') { foreach ($p in ($tok -split ',')) { if ($p.Trim()) { $domains.Add($p.Trim()) } } }
      elseif ($targets -eq 'With') { foreach ($p in ($tok -split ',')) { if ($p.Trim()) { $with.Add($p.Trim()) } } }
      else { Set-Variable -Name $targets -Value $tok -Scope Script; $expect = $null }
      # List-valued flags stay greedy so `--with orvima parley` works as well
      # as `--with orvima,parley`; scalar flags take exactly one value.
      if ($expect -ne $null) {
        $next = if (($i + 1) -lt $raw.Count) { [string]$raw[$i + 1] } else { '' }
        if (-not $next -or $next.StartsWith('-')) { $expect = $null }
        else { $i++ }
      }
      continue
    }

    # --flag=value
    if ($tok -match '^--?([^=/]+)=(.*)$') {
      $name = Get-FlagKey $Matches[1]; $val = $Matches[2]
      if ($switches.ContainsKey($name)) {
        if ($switches[$name] -eq 'Help') { $Help = $true } else { Set-Variable -Name $switches[$name] -Value $true -Scope Script }
      } elseif ($valued.ContainsKey($name)) {
        $targets = $valued[$name]
        if ($targets -eq 'Domains') { foreach ($p in ($val -split ',')) { if ($p.Trim()) { $domains.Add($p.Trim()) } } }
        elseif ($targets -eq 'With') { foreach ($p in ($val -split ',')) { if ($p.Trim()) { $with.Add($p.Trim()) } } }
        else { Set-Variable -Name $targets -Value $val -Scope Script }
      } else {
        Stop-Install -Code 'E_UNKNOWN_FLAG' `
          -What "'$tok' is not a flag this installer knows." `
          -Impact 'Nothing was installed.' `
          -Fix 'Run `./install.ps1 --help` to see every supported flag.'
      }
      continue
    }

    # bare --flag
    if ($tok -match '^--?(.+)$') {
      $name = Get-FlagKey $Matches[1]
      if ($switches.ContainsKey($name)) {
        if ($switches[$name] -eq 'Help') { $Help = $true } else { Set-Variable -Name $switches[$name] -Value $true -Scope Script }
      } elseif ($valued.ContainsKey($name)) {
        $expect = $valued[$name]
        $expectName = $name
      } else {
        Stop-Install -Code 'E_UNKNOWN_FLAG' `
          -What "'$tok' is not a flag this installer knows." `
          -Impact 'Nothing was installed.' `
          -Fix 'Run `./install.ps1 --help` to see every supported flag.'
      }
      continue
    }

    # a bare word is a domain name
    $domains.Add($tok)
  }

  if ($null -ne $expect) {
    $shown = if ($valuedName.ContainsKey($expect)) { $valuedName[$expect] } else { "--$expectName" }
    $ex    = if ($valuedExample.ContainsKey($expect)) { $valuedExample[$expect] } else { '<value>' }
    Stop-Install -Code 'E_MISSING_VALUE' `
      -What "The $shown flag was given without a value after it." `
      -Impact 'Nothing was installed.' `
      -Fix "Example: $shown $ex"
  }

  $script:Domains = @($domains | Select-Object -Unique)
  $script:With    = @($with    | Select-Object -Unique)
  $script:Help    = $Help
  $Domains        = $script:Domains

  if ($Minimal) {
    if ($Domains.Count) {
      Stop-Install -Code 'E_CONFLICTING_FLAGS' `
        -What 'You asked for --minimal and --domains at the same time.' `
        -Impact 'Minimal means "core only"; listing domains asks for specific extras. These contradict.' `
        -Fix 'Pick one: either `--minimal`, or `--domains core,research,debugging`.'
    }
    return @('core')
  }
  if ($Domains.Count) {
    $unknown = @($Domains | Where-Object { $_ -notin $Script:AllDomains })
    if ($unknown.Count) {
      $close = @($unknown | ForEach-Object {
        $Script:AllDomains | Where-Object { $_ -like "*$_*" -or $_ -like "*$($_ -replace 's$','')*" } | Select-Object -First 1
      } | Where-Object { $_ })
      $hint = if ($close) { " Did you mean: $($close -join ', ')?" } else { '' }
      Stop-Install -Code 'E_UNKNOWN_DOMAIN' `
        -What "These are not real domain names: $($unknown -join ', ').$hint" `
        -Impact 'Nothing was installed.' `
        -Fix "Valid domains are: $($Script:AllDomains -join ', '). Run with no flags to install everything."
    }
    # core is always present - the fleet commands depend on it
    return (@('core') + ($Domains | Where-Object { $_ -ne 'core' }) | Select-Object -Unique)
  }
  return $Script:AllDomains
}

# --------------------------- 1. prerequisites ---------------------

function Install-SystemDeps {
  param([string[]]$Domains)

  $needed = @()
  foreach ($d in $Domains) {
    foreach ($s in $Script:SystemDeps[$d]) {
      if ($s -eq 'ffmpeg' -and -not (Test-Cmd 'ffmpeg')) { $needed += 'ffmpeg' }
    }
  }
  if ($needed.Count -eq 0) { Write-Ok 'No system dependencies required'; return }

  if ($IsWindows) {
    if (Test-Cmd 'winget') {
      foreach ($s in ($needed | Select-Object -Unique)) {
        Write-Info "winget install $s"
        if (-not $DryRun) {
          winget install --id "Gyan.FFmpeg" --exact --accept-source-agreements `
            --accept-package-agreements --silent 2>&1 | Out-Null
        }
      }
      # refresh PATH for the current session
      $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' +
                  [Environment]::GetEnvironmentVariable('Path','User')
      if (Test-Cmd 'ffmpeg') { Write-Ok 'ffmpeg installed' } else { Write-Warn2 'ffmpeg not on PATH yet - restart the shell' }
    }
    elseif (Test-Cmd 'choco') {
      foreach ($s in ($needed | Select-Object -Unique)) { if (-not $DryRun) { choco install $s -y | Out-Null } }
      Write-Ok 'ffmpeg installed via chocolatey'
    }
    else { Write-Warn2 'Install ffmpeg manually: https://ffmpeg.org/download.html' }
  }
  elseif (Test-Cmd 'brew') {
    foreach ($s in ($needed | Select-Object -Unique)) { if (-not $DryRun) { brew install $s | Out-Null } }
    Write-Ok 'ffmpeg installed via homebrew'
  }
  elseif (Test-Cmd 'apt-get') {
    # apt needs an explicit update or it installs a stale index and reports the
    # package as unavailable, which reads as "install failed"
    if (-not $DryRun) { sudo apt-get update -qq 2>&1 | Out-Null }
    foreach ($s in ($needed | Select-Object -Unique)) { if (-not $DryRun) { sudo apt-get install -y $s 2>&1 | Out-Null } }
    Write-Ok 'ffmpeg installed via apt'
  }
  elseif (Test-Cmd 'dnf') {
    foreach ($s in ($needed | Select-Object -Unique)) { if (-not $DryRun) { sudo dnf install -y $s 2>&1 | Out-Null } }
    Write-Ok 'ffmpeg installed via dnf'
  }
  elseif (Test-Cmd 'pacman') {
    foreach ($s in ($needed | Select-Object -Unique)) { if (-not $DryRun) { sudo pacman -S --noconfirm $s 2>&1 | Out-Null } }
    Write-Ok 'ffmpeg installed via pacman'
  }
  else {
    Write-Warn2 'Install ffmpeg manually: https://ffmpeg.org/download.html (needed for the content/video domain only)'
  }
}

function Install-OpenCode {
  if (Test-Cmd 'opencode') {
    $v = (& opencode --version) -replace '^opencode\s*v',''
    Write-Ok "opencode already installed (v$v)"
    return
  }
  Assert-Node
  Write-Info 'npm install -g @opencode/cli@latest'
  if (-not $DryRun) {
    $npmOut = & npm install -g '@opencode/cli@latest' 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
      # Three distinct causes produce one generic npm failure, and they need
      # three different fixes - so name the cause rather than passing it on.
      if ($npmOut -match 'EAI_AGAIN|ENOTFOUND|ECONNREFUSED|ETIMEDOUT|network') {
        Stop-Install -Code 'E_NETWORK' `
          -What 'npm could not reach the internet.' `
          -Impact 'OpenCode was not installed, so nothing else in this installer will work either.' `
          -Fix "Check your connection, then run this again.`n           If you are behind a proxy or firewall, set it first:`n             $env:HTTPS_PROXY='http://your-proxy:port'`n           Behind a corporate network, also try: npm config set registry https://registry.npmjs.org/"
      }
      if ($npmOut -match 'EACCES|EPERM|permission denied') {
        Stop-Install -Code 'E_PERMISSION_DENIED' `
          -What 'npm was not allowed to write to its global folder.' `
          -Impact 'OpenCode was not installed.' `
          -Fix "Run PowerShell as Administrator and try again.`n           Or point npm at a folder you own:`n             npm config set prefix '$env:APPDATA\npm'`n           Then reopen your terminal and re-run this installer."
      }
      Stop-Install -Code 'E_NPM_INSTALL' `
        -What 'npm failed to install OpenCode.' `
        -Impact 'OpenCode is the program this whole setup is built on, so the rest cannot run.' `
        -Fix "npm said:`n           $(($npmOut -split "`r?`n" | Where-Object { $_ -match '\S' } | Select-Object -Last 4) -join "`n           ")`n           You can install it by hand and then re-run this installer:`n             npm install -g @opencode/cli@latest"
    }
  }
  if (Test-Cmd 'opencode') {
    Write-Ok "opencode installed ($((& opencode --version)))"
  } else {
    Stop-Install -Code 'E_PATH_MISSING' `
      -What 'OpenCode installed successfully but is not on your PATH.' `
      -Impact 'The config was not written, because a fresh shell could not run opencode to verify it.' `
      -Fix "Close this terminal and open a new one, then run: opencode --version`n           Still not found? Add npm''s global folder to your PATH:`n             $env:PATH += ';$env:APPDATA\npm'`n           or reinstall Node.js, which puts it back for you."
  }
}

function Get-BrowserUsePython {
  # Returns the interpreter path to use for the browser-use MCP server, or $null
  # to leave the template default alone. Cached, because the venv is created once.
  if ($script:BuPythonResolved) { return $script:BuPython }
  $script:BuPythonResolved = $false
  $script:BuPython = $null

  $stackRoot = if ($env:AGENT_STACK_ROOT) { $env:AGENT_STACK_ROOT } else { Join-Path $Script:UserHome 'agent-stack' }
  $venvDir  = Join-Path $stackRoot 'browser-use-env'
  $exe      = if ($IsWindows) { Join-Path $venvDir 'Scripts/python.exe' } else { Join-Path $venvDir 'bin/python' }

  if (Test-Path $exe) { $script:BuPython = $exe; $script:BuPythonResolved = $true; return $exe }

  if ($DryRun -or $SkipDeps) { $script:BuPythonResolved = $true; return $null }

  $py = $null
  foreach ($c in @('python','python3')) { if (Test-Cmd $c) { $py = $c; break } }
  if (-not $py) { $script:BuPythonResolved = $true; return $null }

  Write-Info "creating browser-use virtualenv at $venvDir"
  try {
    New-Item -ItemType Directory -Force $stackRoot | Out-Null
    & $py -m venv $venvDir 2>&1 | Out-Null
    if (-not (Test-Path $exe)) {
      Write-Warn2 'could not create the browser-use virtualenv - the MCP server will fall back to the system python'
      $script:BuPythonResolved = $true
      return $null
    }
    & $exe -m pip install --quiet --upgrade pip 2>&1 | Out-Null
    & $exe -m pip install --quiet browser-use 2>&1 | Out-Null
    $script:BuPython = $exe
    Write-Ok "browser-use installed in its own virtualenv"
  } catch {
    Write-Warn2 "browser-use virtualenv setup failed: $($_.Exception.Message)"
    $script:BuPython = $null
  }
  $script:BuPythonResolved = $true
  return $script:BuPython
}

function Install-PythonDeps {
  param([string[]]$Domains)

  $pkgs = @()
  foreach ($d in $Domains) {
    if ($Script:PyDeps.ContainsKey($d)) { $pkgs += $Script:PyDeps[$d] }
  }
  $pkgs = $pkgs | Select-Object -Unique
  if ($pkgs.Count -eq 0) { Write-Ok 'No Python dependencies required'; return }

  $py = $null
  foreach ($c in @('python','python3','py')) { if (Test-Cmd $c) { $py = $c; break } }
  if (-not $py) {
    # A silent skip here produces a config whose skills all fail at run time,
    # which is far harder to diagnose than refusing now.
    $fix = if ($IsWindows) { 'winget install Python.Python.3.12' }
           elseif (Test-Cmd 'brew') { 'brew install python@3.12' }
           else { 'sudo apt install python3-venv  (or see https://www.python.org/downloads)' }
    Stop-Install -Code 'E_NO_PYTHON' `
      -What 'Python is not installed, but these domains need Python packages.' `
      -Impact "Agents in: $($Domains -join ', ') will be installed but will fail when they run, because the libraries they import are missing." `
      -Fix "Install Python 3.10+ and open a new terminal, then run this again.`n           On this machine: $fix`n           Or install the agent setup without any Python now: ./install.ps1 --minimal"
  }

  # Probe by import name, then map back to the PyPI name for anything missing,
  # because `pip install` needs the package name and `find_spec` needs the
  # module name. Probing by package name reported a working install as missing.
  $pairs = @()
  foreach ($pkg in $pkgs) {
    $mod = if ($Script:PyImportName.ContainsKey($pkg)) { $Script:PyImportName[$pkg] } else { $pkg -replace '-', '_' }
    $pairs += "$mod|$pkg"
  }
  $probeCode = @"
import importlib.util, sys
pairs = [p.strip() for p in '''$($pairs -join ',')'''.split(',') if p.strip()]
# report the PyPI name, not the module name, so the caller can pip install it
print('\n'.join(p.split('|')[1] for p in pairs if importlib.util.find_spec(p.split('|')[0]) is None))
"@
  $missing = @()
  if (-not $DryRun) {
    $out = & $py -c $probeCode 2>$null
    if ($out) { $missing = @($out | Where-Object { $_ }) }
  }
  if ($missing.Count -eq 0) { Write-Ok 'Python dependencies already satisfied'; return }

  Write-Info "pip install $($missing.Count) package(s): $($missing -join ', ')"
  if (-not $DryRun) {
    # Capture stderr: pip's real complaint ("No matching distribution",
    # "permission denied", "network unreachable") is the only clue to the cause
    # and Out-Null was discarding it, leaving a bare "installed" message on a
    # failed install.
    $pipOut = & $py -m pip install --upgrade pip 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
      Stop-Install -Code 'E_PYTHON_INSTALL' `
        -What 'pip could not upgrade itself.' `
        -Impact 'No Python packages were installed, so the affected agents will not run.' `
        -Fix "pip said:`n           $(($pipOut -split "`r?`n" | Where-Object { $_ -match '\S' } | Select-Object -Last 3) -join "`n           ")`n           If this is a permissions problem, try creating a virtual environment first:`n           $py -m venv ~/.venvs/agent-bootstrap"
    }
    $pipOut = & $py -m pip install @missing 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
      Stop-Install -Code 'E_PYTHON_INSTALL' `
        -What "pip failed to install: $($missing -join ', ')" `
        -Impact 'No Python packages were installed, so the affected agents will not run.' `
        -Fix "pip said:`n           $(($pipOut -split "`r?`n" | Where-Object { $_ -match '\S' } | Select-Object -Last 3) -join "`n           ")`n           You can continue without them: ./install.ps1 --minimal"
    }
  }
  Write-Ok 'Python dependencies installed'
}

function Install-Playwright {
  $py = $null
  foreach ($c in @('python','python3')) { if (Test-Cmd $c) { $py = $c; break } }
  if (-not $py) { return }
  & $py -c "import importlib.util,sys; sys.exit(0 if importlib.util.find_spec('playwright') else 1)" 2>$null
  if ($LASTEXITCODE -ne 0) {
    Write-Info 'pip install playwright'
    if (-not $DryRun) { & $py -m pip install --quiet playwright 2>&1 | Out-Null }
  }
  Write-Info 'playwright install chromium'
  if (-not $DryRun) { & $py -m playwright install chromium 2>&1 | Out-Null }
  Write-Ok 'Playwright chromium ready'
}

# --------------------------- 2. source checkout -------------------

function Resolve-Source {
  # Use the directory this script lives in, so a git clone works offline.
  $here = Split-Path -Parent $PSCommandPath
  if ((Split-Path -Leaf $here) -eq 'scripts') { $here = Split-Path -Parent $here }
  if (Test-Path (Join-Path $here 'config/opencode.jsonc')) { return $here }

  $target = if ($InstallDir) { $InstallDir } else { Join-Path $Script:UserHome ".local/share/$($Script:RepoName)" }
  $hasRepo = Test-Path (Join-Path $target 'config/opencode.jsonc')

  if ($hasRepo -and $Force) {
    # `git clone` into a populated directory fails, and piping that to Out-Null
    # hid it, so --force returned a path with no config and the run died later
    # with a misleading "template not found". Replace the tree outright instead.
    Write-Info "--force: replacing the existing checkout at $target"
    if (-not $DryRun) {
      try {
        Remove-Item -Recurse -Force $target -ErrorAction Stop
        $hasRepo = $false
      } catch {
        Stop-Install -Code 'E_PERMISSION_DENIED' `
          -What "Could not remove the existing checkout at $target" `
          -Impact 'Nothing was changed.' `
          -Fix "Close anything using that folder, or install somewhere else:`n           --install-dir $env:TEMP\agent-bootstrap-fresh"
      }
    }
  }

  if ($hasRepo) { return $target }

  Write-Info "cloning agent-bootstrap -> $target"
  if (-not $DryRun) {
    New-Item -ItemType Directory -Force (Split-Path -Parent $target) | Out-Null
    # Capture git's output: "fatal: destination path already exists" is the only
    # clue when a clone fails, and it was being discarded.
    $gitOut = & git clone --depth 1 https://github.com/Sachitt-AV-08/agent-bootstrap.git $target 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
      $reason = if ($gitOut -match 'already exists') { 'the folder already exists and is not empty' }
                elseif ($gitOut -match 'not found|Could not resolve') { 'no network connection' }
                elseif ($gitOut -match 'Permission denied') { 'no write permission for that location' }
                else { 'git reported an error' }
      Stop-Install -Code 'E_CLONE_FAILED' `
        -What "Could not download agent-bootstrap: $reason." `
        -Impact 'Nothing was installed.' `
        -Fix "git said:`n           $(($gitOut -split "`r?`n" | Where-Object { $_ -match '\S' } | Select-Object -Last 3) -join "`n           ")`n           Or clone it yourself and run the installer from that folder:`n           git clone https://github.com/Sachitt-AV-08/agent-bootstrap.git`n           Or pick a writable location:`n           --install-dir <dir>"
    }
  }
  return $target
}

# --------------------------- 3. backup ----------------------------

function Backup-TargetConfig {
  param([string]$Target)
  if (-not (Test-Path $Target)) { return $null }
  $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
  $bak = "$Target-backup-$stamp"
  Write-Info "backing up -> $bak"
  if (-not $DryRun) {
    # A failed backup must abort the run, not warn and continue: everything
    # after this point overwrites the target, and without a backup that
    # overwrite would be unrecoverable.
    try {
      Copy-Item -Path $Target -Destination $bak -Recurse -Force -ErrorAction Stop
    } catch {
      $locked = $_.Exception.Message -match 'being used by another process|access is denied'
      if ($locked) {
        Stop-Install -Code 'E_CONFIG_LOCKED' `
          -What "The file $Target is open in another program, so it cannot be backed up." `
          -Impact 'The installer refuses to continue: it will overwrite that file, and without a backup you could not undo it.' `
          -Fix "Close OpenCode and any editor showing your config, then run this again.`n           If a backup already exists from an earlier run, delete it first: Remove-Item -Recurse -Force '$bak'"
      }
      Stop-Install -Code 'E_PERMISSION_DENIED' `
        -What "Could not back up $Target" `
        -Impact 'The installer will not write anything it cannot undo.' `
        -Fix "The error was: $($_.Exception.Message)`n           If this folder needs admin rights, run PowerShell as Administrator. Otherwise point the installer at a writable folder: --target-config <dir>"
    }
  }
  return $bak
}

# --------------------------- 4. yaml -> agents block ---------------

function ConvertFrom-SimpleYaml {
  # Minimal YAML reader for the restricted schema used by agents/*.yaml:
  # scalars, one nested list of permission maps, and a block scalar (|) for system.
  param([string]$Path)
  $lines = Get-Content -LiteralPath $Path
  $agent = [ordered]@{}
  $inPermissions = $false
  $inSystem = $false
  $sysLines = New-Object System.Collections.Generic.List[string]
  $currentPerm = $null

  foreach ($raw in $lines) {
    $line = $raw
    if ($inSystem) {
      if ($line -match '^\S') { $inSystem = $false }
      else { $sysLines.Add(($line -replace '^\s{2}','')); continue }
    }
    if (-not $line.Trim() -or $line.TrimStart().StartsWith('#')) { continue }

    if ($line -match '^(\w[\w-]*):\s*(.*)$') {
      $key = $Matches[1]; $val = $Matches[2]
      if ($key -eq 'permissions') { $inPermissions = $true; $agent['permissions'] = @(); continue }
      $inPermissions = $false
      if ($val -eq '|') { $inSystem = $true; continue }
      if ($val -ne '') { $agent[$key] = $val }
      else { $agent[$key] = '' }
      continue
    }
    if ($inPermissions -and $line -match '^\s*-\s+(\w[\w-]*):\s*(.*)$') {
      $currentPerm = [ordered]@{ $Matches[1] = $Matches[2] }
      $agent['permissions'] += ,$currentPerm
      continue
    }
    if ($inPermissions -and $line -match '^\s+(\w[\w-]*):\s*(.*)$' -and $currentPerm) {
      $currentPerm[$Matches[1]] = $Matches[2]
      continue
    }
  }
  if ($sysLines.Count) { $agent['system'] = ($sysLines -join "`n").Trim() }
  return $agent
}

function Build-AgentsBlock {
  param([string]$Source,[string[]]$Domains)
  $agentsDir = Join-Path $Source 'agents'
  if (-not (Test-Path $agentsDir)) { return $null, 0 }

  $agents = [ordered]@{}
  $seen   = @{}
  foreach ($d in $Domains) {
    $dir = Join-Path $agentsDir $d
    if (-not (Test-Path $dir)) { continue }
    foreach ($f in Get-ChildItem -Path $dir -Filter '*.yaml' -Recurse -File) {
      $a = ConvertFrom-SimpleYaml -Path $f.FullName
      if (-not $a.Contains('name') -or -not $a['name']) { continue }
      $n = $a['name']
      # a duplicate name silently overwrites the earlier agent in the config
      # block, so fail loudly instead of shipping a short agent list
      if ($seen.ContainsKey($n)) {
        Stop-Install -Code 'E_DUPLICATE_AGENT' -ExitCode 2 `
          -What "Two agent files both call themselves '$n'." `
          -Impact "Only one can exist under that name. The other would be dropped silently, so the installer stops instead of quietly shipping a shorter agent list." `
          -Fix "Rename one of these files (the name inside it must match the filename), then re-run:`n           $((Resolve-Path $f.FullName).Path)`n           $($seen[$n])" `
          -Doc "$Script:DocRoot/guides/custom-agents.md"
      }
      $seen[$n] = $f.FullName
      $entry = [ordered]@{}
      if ($a.Contains('description') -and $a['description']) { $entry['description'] = $a['description'] }
      if ($a.Contains('model') -and $a['model'])             { $entry['model'] = $a['model'] }
      if ($a.Contains('system') -and $a['system'])           { $entry['system'] = $a['system'] }
      # `mode` MUST always be written out. In OpenCode V2 an omitted mode defaults
      # to "primary", which would put all 163 domain agents into the Tab/Shift+Tab
      # primary-agent cycle and bury the built-in build/plan pair.
      if ($a.Contains('mode') -and $a['mode']) { $entry['mode'] = $a['mode'] }
      $perms = @()
      if ($a.Contains('permissions') -and $a['permissions']) {
        foreach ($p in $a['permissions']) {
          if (-not $p.Contains('action')) { continue }
          $perms += [ordered]@{
            action   = $p['action']
            resource = $(if ($p.Contains('resource')) { $p['resource'] } else { '*' })
            effect   = $(if ($p.Contains('effect')) { $p['effect'] } else { 'ask' })
          }
        }
      }
      if ($perms.Count) { $entry['permissions'] = $perms }
      $agents[$a['name']] = $entry
    }
  }
  return $agents, $agents.Count
}

function Get-Prop($obj, [string]$name) {
  if ($null -eq $obj) { return $null }
  if ($obj -is [System.Collections.IDictionary]) {
    if ($obj.Contains($name)) { return $obj[$name] }
    return $null
  }
  $p = $obj.PSObject.Properties[$name]
  if ($p) { return $p.Value }
  return $null
}

function Build-McpBlock {
  param([string]$Source,[string[]]$Names)
  $mcpDir = Join-Path $Source 'mcp'
  $servers = [ordered]@{}
  if (-not (Test-Path $mcpDir)) { return $servers }
  foreach ($f in Get-ChildItem -Path $mcpDir -Filter '*.json' -File) {
    $j = Get-Content $f.FullName -Raw | ConvertFrom-Json
    $name = Get-Prop $j 'name'; if (-not $name) { $name = $f.BaseName }
    if ($Names.Count -and $name -notin $Names) { continue }

    $type = Get-Prop $j 'type'; if (-not $type) { $type = 'local' }
    $entry = [ordered]@{ 'type' = $type }

    if (Get-Prop $j 'disabled') { $entry['disabled'] = $true; $servers[$name] = $entry; continue }

    $cmd = Get-Prop $j 'command'
    if ($cmd) {
      # expand `~/` so the shipped templates stay machine-independent
      $entry['command'] = @($cmd | ForEach-Object {
        $s = [string]$_
        if ($s.StartsWith('~/')) { $Script:UserHome.Replace('\','/') + $s.Substring(1) } else { $s }
      })
    }
    $url = Get-Prop $j 'url'
    if ($url) { $entry['url'] = $url }
    $env = Get-Prop $j 'environment'
    if ($env) { $entry['environment'] = $env }
    $to  = Get-Prop $j 'timeout'
    if ($to) { $entry['timeout'] = $to }
    $servers[$name] = $entry
  }
  return $servers
}

# --------------------------- 5. config write ----------------------

function ConvertTo-BlockBody($obj, [int]$Indent = 6) {
  # The template markers already sit INSIDE `"agents": { ... }` / `"servers": { ... }`,
  # so the injected text must be the object *properties only* - injecting a fully
  # wrapped object would nest it one level too deep and produce invalid JSON.
  if ($null -eq $obj) { return '' }
  $json = $obj | ConvertTo-Json -Depth 12
  if ($null -eq $json) { return '' }
  $lines = @($json -split "`r?`n" | ForEach-Object { $_.TrimEnd() })
  if ($lines.Count -eq 0) { return '' }
  # single-line `{}` or a bare scalar means nothing to inject
  if ($lines.Count -eq 1) { return '' }
  # strip the wrapping braces
  $lines = $lines[1..($lines.Count - 2)]
  $pad = ' ' * $Indent
  return (($lines | ForEach-Object { $pad + $_ }) -join "`n")
}

function Get-ExistingMcpServers([string]$Target) {
  # Parse the user's current config, tolerating // line comments, and return its
  # mcp.servers object. Returns $null when absent or unparseable.
  $f = Join-Path $Target 'opencode.jsonc'
  if (-not (Test-Path $f)) { return $null }
  try {
    $raw = (Get-Content -LiteralPath $f -Raw) -replace '(?m)^[ \t]*//.*$',''
    $cur = $raw | ConvertFrom-Json
    $sp = $cur.PSObject.Properties['mcp']
    if (-not $sp -or -not $sp.Value) { return $null }
    $ss = $sp.Value.PSObject.Properties['servers']
    if (-not $ss -or -not $ss.Value) { return $null }
    return $ss.Value
  } catch {
    Write-Warn2 'could not parse existing config for MCP merge - template wins'
    return $null
  }
}

function Write-TargetConfig {
  param(
    [string]$Source, [string]$Target, [string[]]$Domains,
    [string]$Model, [string]$SmallModel, [string]$McpNames
  )
  $tpl = Join-Path $Source 'config/opencode.jsonc'
  if (-not (Test-Path $tpl)) {
    Stop-Install -Code 'E_NO_TEMPLATE' -ExitCode 2 `
      -What "The config template is missing from the agent-bootstrap source tree ($tpl)." `
      -Impact 'The installer cannot generate a configuration without it.' `
      -Fix "Re-clone the repo, or run the one-liner which downloads a complete copy:`n           git clone https://github.com/Sachitt-AV-08/agent-bootstrap.git"
  }

  # tui.json carries the theme and keybinds, so an existing one is never
  # clobbered - a user's colour scheme and shortcuts are theirs to choose.
  $tplTui = Join-Path $Source 'config/tui.json'
  $targetTui = Join-Path $Target 'tui.json'
  if (Test-Path $tplTui) {
    if (Test-Path $targetTui) {
      Write-Info 'kept your existing tui.json (theme and keybinds untouched)'
    } elseif (-not $DryRun) {
      New-Item -ItemType Directory -Force $Target | Out-Null
      Copy-Item -LiteralPath $tplTui -Destination $targetTui -Force
      Write-Ok 'tui.json installed (tokyonight theme, shift+tab cycles plan/build)'
    }
  }

  # ---- build the MCP server map first (template, then preserved user entries) ----
  $want = @($McpNames -split ',' | Where-Object { $_ -and $_ -ne 'merge' })
  $servers = Build-McpBlock -Source $Source -Names $want
  $overridden = $null

  # The shipped template says `"command": ["python", ...]`, which is wrong for a
  # fresh machine: browser-use is not in the system Python, so that command
  # fails with a bare "Connection closed". Point it at the venv we actually
  # created, if we made one. Runs before the merge below, so a user who already
  # has a working browser-use entry still keeps their own path.
  $buPy = Get-BrowserUsePython
  if ($buPy -and $servers.Contains('browser-use')) {
    $servers['browser-use'].command = @($buPy, '-m', 'browser_use.mcp.cli_mcp')
  }

  if ($McpNames -match '(^|,)merge(,|$)') {
    $existing = Get-ExistingMcpServers -Target $Target
    if ($existing) {
      $kept = @()
      foreach ($prop in $existing.PSObject.Properties) {
        # The user's existing definition ALWAYS wins. A template value that
        # overrides a working local command (e.g. a venv-specific interpreter
        # path) silently breaks that server, so template entries only fill gaps.
        if ($servers.Contains($prop.Name)) { $overridden = $prop.Name }
        $servers[$prop.Name] = $prop.Value
        $kept += $prop.Name
      }
      if ($kept.Count) { Write-Info "kept existing MCP definition(s): $($kept -join ', ')" }
      if ($overridden)  { Write-Info "template default overridden by your config: $overridden" }
    }
  }

  # ---- inject both blocks into the template ----
  $text = Get-Content -LiteralPath $tpl -Raw
  $text = $text.Replace('{{MODEL}}', $Model).Replace('{{SMALL_MODEL}}', $SmallModel)

  $agents, $count = Build-AgentsBlock -Source $Source -Domains $Domains
  # NB: use a MatchEvaluator, not a string replacement - system prompts contain
  # `$ARGUMENTS` / `$(...)`, which [regex]::Replace would treat as $ tokens.
  $agentBody = ConvertTo-BlockBody $agents 4
  $mcpBody   = ConvertTo-BlockBody $servers 6
  $text = [regex]::Replace($text, '(?m)^[ \t]*//[ \t]*__AGENTS_BLOCK__.*$', { param($m) $agentBody })
  $text = [regex]::Replace($text, '(?m)^[ \t]*//[ \t]*__MCP_BLOCK__.*$',   { param($m) $mcpBody })

  # ---- validate before writing: a config that does not parse breaks every
  # ---- skill, agent, MCP and permission rule, so never write an unverified file.
  $probe = ($text -replace '(?m)^[ \t]*//.*$','')
  try {
    $null = $probe | ConvertFrom-Json -ErrorAction Stop
  } catch {
    # A config that fails to parse takes every skill, agent, MCP and permission
    # rule with it, so this is checked before anything is written.
    $dump = Join-Path ([IO.Path]::GetTempPath()) 'agent-bootstrap-invalid.jsonc'
    try { Set-Content -LiteralPath $dump -Value $text -Encoding UTF8 } catch {}
    Stop-Install -Code 'E_CONFIG_INVALID' -ExitCode 2 `
      -What 'The configuration this installer just generated is not valid JSON, so it was NOT written.' `
      -Impact 'Nothing was changed. Your existing setup still works exactly as before.' `
      -Fix "This is an installer bug, not a problem with your machine. The generated file was saved to:`n           $dump`n           Please attach it to a bug report: $Script:DocRoot/../issues"
  }

  if (-not $DryRun) {
    New-Item -ItemType Directory -Force $Target | Out-Null
    Set-Content -LiteralPath (Join-Path $Target 'opencode.jsonc') -Value $text -Encoding UTF8
  }
  return $count
}

function Install-Tree {
  param([string]$From,[string]$To)
  if (-not (Test-Path $From)) { return 0 }
  if ($DryRun) { return (Get-ChildItem -Path $From -Recurse -File).Count }
  New-Item -ItemType Directory -Force $To | Out-Null
  Copy-Item -Path (Join-Path $From '*') -Destination $To -Recurse -Force
  return (Get-ChildItem -Path $To -Recurse -File).Count
}

# --------------------------- 6. doctor ----------------------------

function Invoke-Doctor {
  param([string]$Target)
  $ok = $true
  Write-Host ''
  Write-Host '  Verification' -ForegroundColor Cyan

  if (Test-Cmd 'opencode') {
    Write-Ok "opencode $((& opencode --version) -replace '^opencode\s*v','')"
  } else { Write-Err2 'opencode not on PATH'; $ok = $false }

  $cfg = Join-Path $Target 'opencode.jsonc'
  if (Test-Path $cfg) { Write-Ok "config present ($((Get-Item $cfg).Length) bytes)" }
  elseif ($DryRun) { Write-Warn2 'config not written (dry run)' }
  else { Write-Err2 'opencode.jsonc missing'; $ok = $false }

  $fileCount = 0
  foreach ($d in @('commands','agents')) {
    $p = Join-Path $Target $d
    if (Test-Path $p) { $fileCount += (Get-ChildItem $p -Recurse -File).Count }
  }
  if ($fileCount -gt 0) { Write-Ok "$fileCount agent/command files installed" }
  elseif (-not $DryRun) {
    # Not a warning. An install that produced no agents and no commands has
    # installed nothing useful, and reporting it as "Ready" is the one outcome
    # worse than an outright failure: the user walks away believing it worked.
    Write-Err2 'no agents or commands installed'
    $ok = $false
  }

  $skillCount = 0
  $sp = Join-Path $Target 'skills'
  if (Test-Path $sp) { $skillCount = (Get-ChildItem $sp -Directory).Count }
  if ($skillCount -gt 0) { Write-Ok "$skillCount skill packs installed" }
  elseif (-not $DryRun) { Write-Err2 'no skill packs installed'; $ok = $false }

  if (Test-Cmd 'ffmpeg') { Write-Ok 'ffmpeg available' } else { Write-Warn2 'ffmpeg not found (needed for content/video)' }

  if (Test-Cmd 'opencode' -and $ok) {
    Write-Info 'opencode mcp list'
    $mcp = & opencode mcp list 2>&1 | Out-String
    $broken = @()
    foreach ($line in ($mcp -split "`r?`n")) {
      if ([string]::IsNullOrWhiteSpace($line)) { continue }
      if ($line -match 'connected') { Write-Ok ("mcp  " + $line.Trim()) }
      elseif ($line -match 'needs authentication') { Write-Warn2 ("mcp  " + $line.Trim() + '  -> run: opencode, then /mcps') }
      elseif ($line -match 'failed|error|closed') {
        Write-Warn2 ("mcp  " + $line.Trim())
        $broken += $line.Trim()
      }
    }
    if ($broken.Count) {
      Write-Host ''
      Write-Info 'MCP servers are optional add-ons. Everything else installed fine, and'
      Write-Info 'agents that need a broken server will report which one when they run.'
      Write-Info 'To fix one, check its command and interpreter in ~/.config/opencode/opencode.jsonc,'
      Write-Info 'or see docs/guides/troubleshooting.md#mcp-server-will-not-start.'
    }
  }
  return $ok
}

# --------------------------- interactive mode ---------------------

function Test-Interactive {
  # True only when a human can actually answer a question. When the script is
  # piped (`irm ... | iex`) or run by CI, stdin is redirected and any prompt
  # would either hang forever or silently eat the next line of the pipeline.
  if ([Console]::IsInputRedirected)  { return $false }
  if ([Console]::IsOutputRedirected) { return $false }
  # $Host.UI.RawUI is absent in some non-interactive hosts; treat that as no
  if ($null -eq $Host.UI.RawUI) { return $false }
  return $true
}

function Read-Choice {
  # One line, bounded, never throws. Returns $null on empty input or EOF so the
  # caller can apply its own default rather than blocking forever.
  param([string]$Prompt, [int]$Default)
  try {
    $raw = Read-Host $Prompt
  } catch {
    return $null
  }
  if ($null -eq $raw) { return $null }
  $raw = $raw.Trim()
  if (-not $raw) { return $Default }
  $n = 0
  if ([int]::TryParse($raw, [ref]$n)) { return $n }
  return $null
}

function Invoke-InteractiveSetup {
  <#
    Aimed at someone who has never opened a terminal. Three questions, each
    with a safe default, and Enter always takes the recommended path. Anything
    non-interactive falls straight through to the full install.
  #>
  $n = 0
  $totalAgents = @(Get-ChildItem (Join-Path $Script:SourceRoot 'agents') -Recurse -Filter '*.yaml' -File -ErrorAction SilentlyContinue).Count

  Write-Host ''
  Write-Host '  agent-bootstrap  -  let us set this up' -ForegroundColor White
  Write-Host '  ------------------------------------------------' -ForegroundColor DarkGray
  Write-Host ''
  Write-Host "  This installs OpenCode plus about $totalAgents ready-to-use AI agents," -ForegroundColor Gray
  Write-Host '  commands, and skills. It takes a few minutes. Nothing you already' -ForegroundColor Gray
  Write-Host '  have is deleted - your current setup is backed up first.' -ForegroundColor Gray
  Write-Host ''

  Write-Host '  1.  Everything, please            (recommended)' -ForegroundColor White
  Write-Host "      all $totalAgents agents, 10 commands, 6 skill packs" -ForegroundColor DarkGray
  Write-Host ''
  Write-Host '  2.  Just the essentials' -ForegroundColor White
  Write-Host '      the core agents and commands, no downloads' -ForegroundColor DarkGray
  Write-Host ''
  Write-Host '  3.  Choose which parts I need' -ForegroundColor White
  Write-Host '      pick from a list of what each part is for' -ForegroundColor DarkGray
  Write-Host ''

  $pick = Read-Choice '  Type 1, 2 or 3 and press Enter [1]:' 1
  if ($null -eq $pick) { $pick = 1 }

  switch ($pick) {
    1 {
      $script:Domains = @($Script:AllDomains)
      Write-Host ''; Write-Ok 'Installing everything. This is the full setup.'
      return
    }
    2 {
      $script:Domains = @('core')
      Write-Host ''; Write-Ok 'Installing just the essentials (no downloads needed).'
      return
    }
    3 { }
    default {
      Write-Host ''; Write-Info 'That is not one of the choices - going with everything.'
      $script:Domains = @($Script:AllDomains)
      return
    }
  }

  # ---- option 3: pick domains, described in plain language ----
  Write-Host ''
  Write-Host '  Which parts do you want? Type the numbers, separated by spaces or commas.' -ForegroundColor White
  Write-Host '  Press Enter on its own to go back to installing everything.' -ForegroundColor DarkGray
  Write-Host ''

  # Descriptions matter more than names: "security" means nothing to someone
  # who has not used these tools, but "catch bad code before it ships" does.
  $blurb = @{
    'core'           = 'the core agents every task uses'
    'security'       = 'find vulnerabilities and review code safely'
    'performance'    = 'profile and speed up slow code'
    'api'            = 'design and document APIs'
    'data-ml'        = 'data analysis and machine learning'
    'frontend'       = 'web interfaces, React, CSS'
    'backend-infra'  = 'servers, databases, deployment'
    'testing'        = 'write tests and find flaky ones'
    'docs-dx'        = 'write and maintain documentation'
    'migration'      = 'move old code to new frameworks'
    'specialty'      = 'specialist tools: PDFs, spreadsheets, diagrams'
    'meta'           = 'tools that manage your other agents'
    'content'        = 'video, audio and images'
    'research'       = 'search papers, gather and summarise sources'
    'debugging'      = 'track down why something broke'
    'web-scraping'   = 'pull data off websites'
    'social-media'   = 'LinkedIn and Instagram'
    'memory'         = 'long-term memory and vector search'
    'orchestration'  = 'run many agents in parallel across worktrees'
    'projects'       = 'project-specific helpers'
  }
  $i = 0
  foreach ($d in $Script:AllDomains) {
    $i++
    $desc = if ($blurb.ContainsKey($d)) { $blurb[$d] } else { '' }
    Write-Host ("   {0,2}.  {1,-15} {2}" -f $i, $d, $desc) -ForegroundColor Gray
  }
  Write-Host ''

  $raw = $null
  try { $raw = Read-Host '  Numbers (blank = everything):' } catch { $raw = $null }
  if ($null -eq $raw -or -not $raw.Trim()) {
    Write-Host ''
    Write-Info 'Going with everything instead.'
    $script:Domains = @($Script:AllDomains)
    return
  }

  $chosen = New-Object System.Collections.Generic.List[string]
  $bad = New-Object System.Collections.Generic.List[string]
  foreach ($tok in ($raw -split '[\s,]+')) {
    if (-not $tok) { continue }
    $idx = 0
    if ([int]::TryParse($tok, [ref]$idx) -and $idx -ge 1 -and $idx -le $Script:AllDomains.Count) {
      $chosen.Add($Script:AllDomains[$idx - 1])
    } else {
      $bad.Add($tok)
    }
  }

  if ($bad.Count) {
    Write-Host ''
    Write-Warn2 "I did not recognise: $($bad -join ', ')"
    Write-Info "Valid names are: $($Script:AllDomains -join ', ')"
  }
  if ($chosen.Count -eq 0) {
    Write-Host ''
    Write-Info 'Nothing valid was chosen, so installing everything.'
    $script:Domains = @($Script:AllDomains)
    return
  }

  # core is always added: the fleet commands depend on it, so installing
  # without it leaves half the commands referencing missing agents.
  # Materialise the List to a plain array first. `List[string] + 'core'`
  # concatenates onto the *last element* in PowerShell 7, which silently
  # produces a domain named "performancecore" instead of adding core.
  $picked = @($chosen | Select-Object -Unique)
  $script:Domains = @(@($picked) + @('core') | Select-Object -Unique)
  Write-Host ''
  Write-Ok "Installing: $($script:Domains -join ', ')"
}

# --------------------------- main ---------------------------------

# Resolve-Selection parses $args literally; it also sets $script:Help
$selected = Resolve-Selection

if ($script:Help) { Write-Usage; exit 0 }

# --self-test: verify the installer's own code paths, install nothing
if ($SelfTest) {
  # scripts/ sits next to install.ps1 in a clone; the odd relative path covers
  # being invoked from ~/.local/share/agent-bootstrap after a one-liner install
  $candidates = @(
    (Join-Path $PSCommandPath 'scripts/selftest.ps1'),
    (Join-Path (Split-Path -Parent $PSCommandPath) 'scripts/selftest.ps1')
  )
  $testScript = @($candidates | Where-Object { $_ -and (Test-Path $_) }) | Select-Object -First 1
  if (-not $testScript) {
    Stop-Install -Code 'E_NO_SELFTEST' -ExitCode 2 `
      -What 'The self-test script (scripts/selftest.ps1) is missing from the source tree.' `
      -Impact 'Cannot verify the installer.' `
      -Fix 'Re-clone the repo, or run the one-liner which downloads a complete copy.'
  }
  & pwsh -NoProfile -File $testScript
  exit $LASTEXITCODE
}

# Resolve-Selection already split flags from values; read the normalised list
$With = @($script:With)
if (-not $With) { $With = @() }
if (-not $TargetConfig) { $TargetConfig = Join-Path $Script:UserHome '.config/opencode' }

# The source tree is resolved first because the interactive menu reports the real
# agent count, and a count that turns out to be wrong is its own small betrayal.
$source = Resolve-Source
$Script:SourceRoot = $source

if ($Interactive) {
  if (Test-Interactive) {
    Invoke-InteractiveSetup
    $selected = @($script:Domains)
  } else {
    # `irm ... | iex` and CI runs land here. Prompting would hang or swallow the
    # next pipeline item, so say why and carry on with the full install.
    Write-Host ''
    Write-Info 'Running without a terminal to ask questions on, so installing everything.'
    Write-Info 'To pick what gets installed, run this from a normal terminal:'
    Write-Info '  ./install.ps1 --interactive'
    $selected = @($Script:AllDomains)
  }
}

Write-Host ''
Write-Host '  agent-bootstrap' -ForegroundColor White -NoNewline
Write-Host '  -  universal AI agent setup' -ForegroundColor DarkGray
Write-Host '  ------------------------------------------------' -ForegroundColor DarkGray

Write-Info "domains: $($selected -join ', ')"
if ($With.Count) { Write-Info "project MCPs: $($With -join ', ')" }

Write-Step "Source: $source"

if ($SkipDeps) {
  Write-Step 'Dependencies skipped (-SkipDeps)'
} else {
  Write-Step 'Installing system dependencies'
  Install-SystemDeps -Domains $selected
  Write-Step 'Installing OpenCode'
  Install-OpenCode
  Write-Step 'Installing Python dependencies'
  Install-PythonDeps -Domains $selected
  if ($selected -contains 'web-scraping' -or $With -contains 'orvima') { Install-Playwright }
}

Write-Step 'Backing up existing configuration'
$bak = Backup-TargetConfig -Target $TargetConfig
if ($bak) { Write-Ok "backup at $bak" } else { Write-Ok 'nothing to back up (fresh install)' }

Write-Step 'Writing opencode.jsonc'
$mcpNames = 'context7,browser-use,vision'
if ($With.Count) { $mcpNames = "$mcpNames,$($With -join ',')" }
$mcpNames = "$mcpNames,merge"
$n = Write-TargetConfig -Source $source -Target $TargetConfig -Domains $selected `
        -Model $Model -SmallModel $SmallModel -McpNames $mcpNames
Write-Ok "$n agent definitions merged into config"

Write-Step 'Installing commands, skills, templates'
$c = Install-Tree -From (Join-Path $source 'commands') -To (Join-Path $TargetConfig 'commands')
$s = Install-Tree -From (Join-Path $source 'skills')   -To (Join-Path $TargetConfig 'skills')
Write-Ok "commands: $c file(s), skills: $s file(s)"

Write-Step 'Installing helper scripts'
$binDir = if ($IsWindows) { Join-Path $Script:UserHome '.local/bin' } else { Join-Path $Script:UserHome '.local/bin' }
$sc = Install-Tree -From (Join-Path $source 'scripts') -To $binDir
Write-Ok "scripts: $sc file(s) -> $binDir"
if (-not $DryRun) {
  $userPath = [Environment]::GetEnvironmentVariable('Path','User')
  if ($userPath -notlike "*$binDir*") {
    [Environment]::SetEnvironmentVariable('Path', ($userPath.TrimEnd(';') + ';' + $binDir), 'User')
    Write-Ok 'added ~/.local/bin to user PATH'
  }
}

if (-not $SkipMcp) {
  Write-Step 'Registering MCP servers'
  Write-Info 'start opencode, then run /mcps to authorize any OAuth-based server'
  Write-Ok "template MCPs: context7, browser-use, vision$(if($With.Count){', ' + ($With -join ', ')})"
}

$healthy = Invoke-Doctor -Target $TargetConfig

# --------------------------- summary dashboard --------------------
# Reads the config that was actually written rather than the counts the install
# steps happened to print. A number that disagrees with the file on disk is
# exactly the kind of thing a dashboard exists to catch.

$dashAgent = 0; $dashMcp = 0; $dashSubagent = 0; $dashModeProblem = 0; $dashPacks = 0
$installFailed = $false
if (-not $DryRun) {
  # A pack is a directory, not a file. Reporting the file count as "packs"
  # overstated this by roughly 7x, which is the sort of number people notice.
  $skillDir = Join-Path $TargetConfig 'skills'
  if (Test-Path $skillDir) { $dashPacks = @(Get-ChildItem $skillDir -Directory -ErrorAction SilentlyContinue).Count }
  try {
    $cfgPath = Join-Path $TargetConfig 'opencode.jsonc'
    $raw = (Get-Content -LiteralPath $cfgPath -Raw) -replace '(?m)^[ \t]*//.*$',''
    $cfg = $raw | ConvertFrom-Json
    if ($cfg.PSObject.Properties['agents']) {
      $dashAgent = @($cfg.agents.PSObject.Properties).Count
      foreach ($p in $cfg.agents.PSObject.Properties) {
        $hasMode = $p.Value.PSObject.Properties['mode']
        if ($hasMode -and $hasMode.Value -eq 'subagent') { $dashSubagent++ }
        else { $dashModeProblem++ }
      }
    }
    if ($cfg.PSObject.Properties['mcp']) {
      $sp = $cfg.mcp.PSObject.Properties['servers']
      if ($sp) { $dashMcp = @($sp.Value.PSObject.Properties).Count }
    }
  } catch {
    Write-Warn2 'could not read back the config for the summary'
  }
}

Write-Host ''
Write-Host '  ------------------------------------------------' -ForegroundColor DarkGray
Write-Host '  Your setup' -ForegroundColor White
Write-Host '  ------------------------------------------------' -ForegroundColor DarkGray

$rows = @(
  @{ label = 'AI agents';        value = if ($DryRun) { "$n (not written - dry run)" } else { "$dashAgent" }
     ok = ($DryRun -or $dashAgent -gt 0) }
  @{ label = '  of those, subagents'; value = if ($DryRun) { 'not checked - dry run' } else { "$dashSubagent" }
     ok = ($DryRun -or ($dashAgent -gt 0 -and $dashModeProblem -eq 0)) }
  @{ label = 'MCP servers';      value = if ($DryRun) { 'not written - dry run' } else { "$dashMcp" }; ok = $true }
  @{ label = 'Slash commands';   value = "$c";  ok = ($DryRun -or $c -gt 0) }
  @{ label = 'Skill packs';      value = if ($DryRun) { "$s files (not written - dry run)" } else { "$dashPacks packs, $s files" }
     ok = ($DryRun -or $dashPacks -gt 0) }
  @{ label = 'Helper commands';  value = "$sc scripts in ~/.local/bin"; ok = $true }
  @{ label = 'Model';            value = $Model; ok = $true }
)
foreach ($r in $rows) {
  # The mark must reflect the status, not just the colour: a row that says "OK"
  # while the value is 0 is worse than no dashboard at all.
  if ($r.ok)      { $mark = '  OK'; $col = 'Green' }
  else            { $mark = ' FAIL'; $col = 'Red' }
  Write-Host "  [$mark] " -NoNewline -ForegroundColor $col
  # pad to the widest label, or the value runs into the text above it
  Write-Host ("{0,-24}" -f $r.label) -NoNewline -ForegroundColor DarkGray
  Write-Host $r.value -ForegroundColor Gray
}

if (-not $DryRun -and $dashModeProblem -gt 0) {
  Write-Host ''
  Write-Warn2 "$dashModeProblem agent(s) are not marked mode=subagent, so they will appear in your Tab / Shift+Tab cycle."
  Write-Info 'See docs/reference/keyboard-shortcuts.md'
}

Write-Host ''
if ($healthy) {
  Write-Host '  Ready.' -ForegroundColor Green
  Write-Host '  Open a new terminal, then run:' -ForegroundColor DarkGray
} elseif (-not $DryRun -and $dashAgent -eq 0) {
  # The one case that is not "installed with warnings": nothing usable landed.
  Write-Host '  This did not install correctly.' -ForegroundColor Red
  Write-Host '  No agents were written, so OpenCode would start with nothing in it.' -ForegroundColor DarkGray
  Write-Host ''
  Write-Host '  Most likely cause: the source checkout is incomplete or in the' -ForegroundColor DarkGray
  Write-Host '  wrong place, so there were no agent definitions to copy.' -ForegroundColor DarkGray
  Write-Host ''
  Write-Host '  Try again from a fresh clone:' -ForegroundColor White
  Write-Host '    git clone https://github.com/Sachitt-AV-08/agent-bootstrap.git' -ForegroundColor Gray
  Write-Host '    cd agent-bootstrap' -ForegroundColor Gray
  Write-Host '    ./install.ps1 --force' -ForegroundColor Gray
  Write-Host ''
  Write-Host '  Or see docs/guides/troubleshooting.md' -ForegroundColor DarkGray
  $installFailed = $true
} else {
  Write-Host '  Installed, with warnings above.' -ForegroundColor Yellow
  Write-Host '  Everything important still works. Run doctor for the full list.' -ForegroundColor DarkGray
}

# Only suggest next steps when there is a working setup to use them with.
# Telling someone to run `opencode` after an install that produced no agents is
# an instruction to go and be disappointed.
if (-not $installFailed) {
  Write-Host ''
  Write-Host '    opencode' -ForegroundColor White
  Write-Host '        start OpenCode'
  Write-Host ''
  Write-Host '    doctor' -ForegroundColor White
  Write-Host '        check everything is still healthy, any time'
  Write-Host ''
  Write-Host '    /plan-feature "add OAuth2 login"' -ForegroundColor White
  Write-Host '        plan a feature across several agents'
  Write-Host ''
  Write-Host '    /fleet-spawn reviewer 3' -ForegroundColor White
  Write-Host '        run 3 reviewers in parallel, each in its own worktree'
}
if ($bak) {
  Write-Host ''
  Write-Host "  Changed your mind? Your previous setup is at:" -ForegroundColor DarkGray
  Write-Host "    $bak" -ForegroundColor DarkGray
  Write-Host '    Copy-Item -Recurse -Force "<that folder>\*" "$HOME/.config/opencode\"' -ForegroundColor DarkGray
}
Write-Host ''

if ($healthy) { exit 0 } else { exit 1 }

