#Requires -Version 7.0
<#
.SYNOPSIS
  agent-bootstrap installer - takes any machine to a 10/10 AI agent setup.

.DESCRIPTION
  One command installs OpenCode V2, ~260 agent definitions, fleet orchestration
  commands, skill packs, and MCP servers (orvima, parley, genesis, context7,
  browser-use, vision, memory backends). Everything is free-tier and local-first.

  Install:
    pwsh -c "irm https://raw.githubusercontent.com/Sachitt-AV-08/agent-bootstrap/main/install.ps1 | iex"

  Or from a clone:
    ./install.ps1 --all

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

[CmdletBinding()]
param(
  [switch]$All,
  [switch]$Minimal,
  [string[]]$Domains = @(),
  [string[]]$With = @(),
  [string]$InstallDir = "",
  [string]$TargetConfig = "",
  [string]$Model = "kilo/kilo-auto/free",
  [string]$SmallModel = "kilo/kilo-auto/small",
  [switch]$SkipDeps,
  [switch]$SkipMcp,
  [switch]$Force,
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# --------------------------- constants ---------------------------

$Script:RepoName    = 'agent-bootstrap'
$Script:UserHome    = $HOME
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

# --------------------------- resolution ---------------------------

function Resolve-Selection {
  # PowerShell can bind unknown `--flag` tokens into the first string[] parameter.
  # Reclassify them here: known flags become switches, the rest are real domains.
  $flagMap = @{
    '--all'='All'; '--minimal'='Minimal'; '--force'='Force'; '-f'='Force'
    '--skip-deps'='SkipDeps'; '--skip-mcp'='SkipMcp'; '--dry-run'='DryRun'
  }
  $tokens = @($Domains) + @($With)
  $clean = @()
  foreach ($t in $tokens) {
    if (-not $t) { continue }
    foreach ($part in ($t -split ',')) {
      $p = $part.Trim()
      if (-not $p) { continue }
      if ($flagMap.ContainsKey($p)) { Set-Variable -Name $flagMap[$p] -Value $true -Scope Script }
      elseif ($p.StartsWith('-')) { Write-Warn2 "ignoring unknown flag: $p" }
      else { $clean += $p }
    }
  }
  $script:Domains = @($clean | Select-Object -Unique)

  if ($Minimal) {
    if ($Domains.Count) { throw "-Minimal and -Domains are mutually exclusive." }
    return @('core')
  }
  if ($Domains.Count) {
    $unknown = $Domains | Where-Object { $_ -notin $Script:AllDomains }
    if ($unknown) { throw "Unknown domain(s): $($unknown -join ', '). Valid: $($Script:AllDomains -join ', ')" }
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
  else {
    Write-Warn2 'Install ffmpeg manually: https://ffmpeg.org/download.html'
  }
}

function Install-OpenCode {
  if (Test-Cmd 'opencode') {
    $v = (& opencode --version) -replace '^opencode\s*v',''
    Write-Ok "opencode already installed (v$v)"
    return
  }
  if (-not (Test-Cmd 'npm')) { throw "Node.js/npm not found. Install Node 20+ first: https://nodejs.org" }
  Write-Info 'npm install -g @opencode/cli@latest'
  if (-not $DryRun) {
    & npm install -g '@opencode/cli@latest' 2>&1 | Out-Null
    $script:InstallFailed = $true
  }
  if (Test-Cmd 'opencode') {
    Write-Ok "opencode installed ($((& opencode --version)))"
  } else {
    Write-Warn2 'opencode shim not on PATH. Reinstall node/npm or add the npm global bin to PATH.'
  }
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
  if (-not $py) { Write-Warn2 'Python not found - skipping python deps'; return }

  # fast path: check all modules in one interpreter launch instead of N
  $modules = ($pkgs | ForEach-Object { ($_ -replace '-', '_') }) -join ','
  $probeCode = @"
import importlib.util, sys
mods = [m.strip() for m in '''$modules'''.split(',') if m.strip()]
missing = [m for m in mods if importlib.util.find_spec(m) is None]
print('\n'.join(missing))
"@
  $missing = @()
  if (-not $DryRun) {
    $out = & $py -c $probeCode 2>$null
    if ($out) { $missing = @($out | Where-Object { $_ }) }
  }
  if ($missing.Count -eq 0) { Write-Ok 'Python dependencies already satisfied'; return }

  Write-Info "pip install $($missing.Count) package(s): $($missing -join ', ')"
  if (-not $DryRun) {
    & $py -m pip install --quiet --upgrade pip 2>&1 | Out-Null
    & $py -m pip install --quiet @missing 2>&1 | Out-Null
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

  # otherwise clone
  $target = if ($InstallDir) { $InstallDir } else { Join-Path $Script:UserHome ".local/share/$($Script:RepoName)" }
  if ((Test-Path (Join-Path $target 'config/opencode.jsonc')) -and -not $Force) { return $target }
  Write-Info "cloning agent-bootstrap -> $target"
  if (-not $DryRun) {
    New-Item -ItemType Directory -Force (Split-Path -Parent $target) | Out-Null
    & git clone --depth 1 https://github.com/Sachitt-AV-08/agent-bootstrap.git $target 2>&1 | Out-Null
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
    Copy-Item -Path $Target -Destination $bak -Recurse -Force
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
        throw "duplicate agent name '$n' in $($f.FullName) (already defined by $($seen[$n])). Rename one; agent names must be globally unique."
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
  if (-not (Test-Path $tpl)) { throw "template not found: $tpl" }

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
    $dump = Join-Path ([IO.Path]::GetTempPath()) 'agent-bootstrap-invalid.jsonc'
    try { Set-Content -LiteralPath $dump -Value $text -Encoding UTF8 } catch {}
    throw "generated config is not valid JSON - nothing was written. Candidate saved to $dump. $($_.Exception.Message)"
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
  elseif (-not $DryRun) { Write-Warn2 'no agents or commands installed' }

  $skillCount = 0
  $sp = Join-Path $Target 'skills'
  if (Test-Path $sp) { $skillCount = (Get-ChildItem $sp -Directory).Count }
  if ($skillCount -gt 0) { Write-Ok "$skillCount skill packs installed" }
  elseif (-not $DryRun) { Write-Warn2 'no skill packs installed' }

  if (Test-Cmd 'ffmpeg') { Write-Ok 'ffmpeg available' } else { Write-Warn2 'ffmpeg not found (needed for content/video)' }

  if (Test-Cmd 'opencode' -and $ok) {
    Write-Info 'opencode mcp list'
    $mcp = & opencode mcp list 2>&1 | Out-String
    foreach ($line in ($mcp -split "`n")) {
      if ($line -match 'connected') { Write-Ok ("mcp  " + $line.Trim()) }
      elseif ($line -match 'needs authentication') { Write-Warn2 ("mcp  " + $line.Trim()) }
      elseif ($line -match 'failed|error') { Write-Warn2 ("mcp  " + $line.Trim()) }
    }
  }
  return $ok
}

# --------------------------- main ---------------------------------

Write-Host ''
Write-Host '  agent-bootstrap' -ForegroundColor White -NoNewline
Write-Host '  -  universal AI agent setup' -ForegroundColor DarkGray
Write-Host '  ------------------------------------------------' -ForegroundColor DarkGray

# tolerate `--all` / `--minimal` style (double-dash) flags that PowerShell binds
# into the string[] parameters; Resolve-Selection reclassifies them into switches
$selected = Resolve-Selection
$With = @($With | Where-Object { $_ -and $_ -notmatch '^-' })
if (-not $TargetConfig) { $TargetConfig = Join-Path $Script:UserHome '.config/opencode' }

Write-Info "domains: $($selected -join ', ')"
if ($With.Count) { Write-Info "project MCPs: $($With -join ', ')" }

$source = Resolve-Source
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

Write-Host ''
Write-Host '  ------------------------------------------------' -ForegroundColor DarkGray
if ($healthy) {
  Write-Host '  OK 10/10 ready' -ForegroundColor Green
} else {
  Write-Host '  ! Installed with warnings - see lines above' -ForegroundColor Yellow
}
Write-Host ''
Write-Host '  Next:' -ForegroundColor White
Write-Host '    opencode                              # start the TUI (tokyonight theme)'
Write-Host '    doctor                                # re-verify any time (from ~/.local/bin)'
Write-Host '    /fleet-spawn reviewer 3               # spawn 3 reviewer agents in worktrees'
Write-Host '    /plan-feature "add OAuth2 login"      # plan a feature across agents'
Write-Host '    /fleet-status                         # see the fleet'
Write-Host '    /fleet-collect                        # merge results'
if ($bak) {
  Write-Host ''
  Write-Host "  Rollback: restore from $bak" -ForegroundColor DarkGray
}
Write-Host ''

if ($healthy) { exit 0 } else { exit 1 }

