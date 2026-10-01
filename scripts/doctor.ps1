#Requires -Version 7.0
<#
.SYNOPSIS
  Verify an agent-bootstrap installation.

.DESCRIPTION
  Checks the OpenCode install, the generated config, agent/command/skill counts,
  optional tooling (ffmpeg, python, playwright, git, gh), and live MCP status.
  Exit code 0 = healthy, 1 = problems found.

.EXAMPLE
  doctor
  doctor -Target "$HOME/.config/opencode"
#>
[CmdletBinding()]
param(
  [string]$Target = "",
  [switch]$Json
)

$ErrorActionPreference = 'Continue'
Set-StrictMode -Version Latest

if (-not $Target) {
  $Target = if ($env:AGENT_BOOTSTRAP_CONFIG) { $env:AGENT_BOOTSTRAP_CONFIG }
            else { Join-Path $HOME '.config/opencode' }
}

$results = New-Object System.Collections.Generic.List[object]
function Add-Check([string]$name, [string]$status, [string]$detail) {
  $script:results.Add([pscustomobject]@{ check = $name; status = $status; detail = $detail })
}
function Ok([string]$n, [string]$d) { Add-Check $n 'OK'      $d }
function Warn2([string]$n, [string]$d) { Add-Check $n 'WARN'  $d }
function Fail([string]$n, [string]$d) { Add-Check $n 'FAIL'  $d }

# ── 1. opencode ────────────────────────────────────────────────────
$oc = Get-Command opencode -ErrorAction SilentlyContinue
if ($oc) {
  $ver = (& opencode --version 2>$null | Out-String).Trim()
  if ($ver -match 'v?2\.') { Ok 'opencode' $ver }
  else { Warn2 'opencode' "$ver (expected 2.x for this config shape)" }
} else {
  Fail 'opencode' 'not on PATH — npm install -g @opencode/cli@latest'
}

# ── 2. config ──────────────────────────────────────────────────────
$cfg = Join-Path $Target 'opencode.jsonc'
if (Test-Path $cfg) {
  $raw = Get-Content $cfg -Raw
  $stripped = ($raw -replace '(?m)^\s*//.*$','') -replace '/\*.*?\*/',''
  try {
    $j = $stripped | ConvertFrom-Json
    $agents  = if ($j.agents)       { @($j.agents.PSObject.Properties).Count } else { 0 }
    $servers = if ($j.mcp.servers)  { @($j.mcp.servers.PSObject.Properties).Count } else { 0 }
    $perms   = if ($j.permissions)  { @($j.permissions).Count } else { 0 }
    Ok 'config' "$([math]::Round((Get-Item $cfg).Length/1KB,1)) KB — $agents agents, $servers MCPs, $perms permission rules"
    # `model` may be a plain string ("kilo/kilo-auto/free") or an object
    # ({ providerID, model }) depending on how it was written.
    function Format-Model($v) {
      if ($null -eq $v) { return $null }
      if ($v -is [string]) { return $v }
      $p = $v.PSObject.Properties['model']
      if ($p) { return [string]$p.Value }
      return [string]$v
    }
    $m  = Format-Model $j.model
    $sm = Format-Model $j.small_model
    if ($m)  { Ok 'model'       $m  } else { Warn2 'model'       'no default model set' }
    if ($sm) { Ok 'small_model' $sm } else { Warn2 'small_model' 'not set' }
    $wt = $null
    $wp = $j.PSObject.Properties['worktree']
    if ($wp -and $wp.Value) {
      $dp = $wp.Value.PSObject.Properties['directory']
      if ($dp) { $wt = [string]$dp.Value }
    }
    if ($wt) { Ok 'worktrees' $wt } else { Warn2 'worktrees' 'no worktree directory configured' }
  } catch {
    Fail 'config' "invalid JSONC: $($_.Exception.Message.Split([char]10)[0])"
  }
} else {
  Fail 'config' "missing $cfg — run ./install.ps1"
}

# ── 3. commands, skills, agents on disk ────────────────────────────
$cmdDir = Join-Path $Target 'commands'
if (Test-Path $cmdDir) {
  $n = (Get-ChildItem $cmdDir -Filter '*.md' -File).Count
  if ($n -gt 0) { Ok 'commands' "$n file(s)" } else { Warn2 'commands' 'directory empty' }
} else { Warn2 'commands' 'not installed' }

$skillDir = Join-Path $Target 'skills'
if (Test-Path $skillDir) {
  $packs = @(Get-ChildItem $skillDir -Directory)
  $withSkill = @($packs | Where-Object { Test-Path (Join-Path $_.FullName 'SKILL.md') })
  if ($packs.Count -gt 0) { Ok 'skills' "$($packs.Count) pack(s), $($withSkill.Count) with SKILL.md" }
  else { Warn2 'skills' 'no skill packs' }
} else { Warn2 'skills' 'not installed' }

$agDir = Join-Path $Target 'agents'
if (Test-Path $agDir) { Ok 'agent-sources' "$((Get-ChildItem $agDir -Recurse -File).Count) file(s)" }
else { Warn2 'agent-sources' 'not installed (agents are inlined in opencode.jsonc anyway)' }

foreach ($f in @('tui.json','AGENTS.md')) {
  $p = Join-Path $Target $f
  if (Test-Path $p) { Ok $f "$([math]::Round((Get-Item $p).Length/1KB,1)) KB" } else { Warn2 $f 'not installed' }
}

# ── 4. optional tooling ────────────────────────────────────────────
foreach ($pair in @(
  @('git','git'), @('gh','GitHub CLI'), @('python','Python'), @('node','Node'),
  @('ffmpeg','ffmpeg (video/audio)'), @('uv','uv'))) {
  $cmd = $pair[0]; $label = $pair[1]
  if (Get-Command $cmd -ErrorAction SilentlyContinue) { Ok $cmd $label }
  else { Warn2 $cmd "$label not found" }
}

$py = Get-Command python -ErrorAction SilentlyContinue
if ($py) {
  # Probe by module name and report the PyPI name, because the two differ
  # (newspaper3k imports as `newspaper`). Probing by package name reported a
  # working install as missing and sent people hunting a nonexistent problem.
  $code = @'
import importlib.util
mods = ["yt_dlp:yt-dlp","youtube_transcript_api:youtube-transcript-api","bs4:beautifulsoup4",
        "lxml:lxml","selectolax:selectolax","trafilatura:trafilatura",
        "newspaper:newspaper3k","scrapy:scrapy","chromadb:chromadb",
        "qdrant_client:qdrant-client","mem0:mem0ai","faiss:faiss-cpu","playwright:playwright"]
present = [pkg for mod, pkg in (m.split(":") for m in mods) if importlib.util.find_spec(mod)]
missing = [pkg for mod, pkg in (m.split(":") for m in mods) if not importlib.util.find_spec(mod)]
print("present=" + ",".join(present))
print("missing=" + ",".join(missing))
'@
  $out = & python -c $code 2>$null | Out-String
  $missing = if ($out -match 'missing=([^\r\n]*)') { $Matches[1] } else { '' }
  if ($missing) {
    Warn2 'python-deps' "missing: $missing"
    Write-Host '        fix: python -m pip install ' (($missing -split ',') -join ' ') -ForegroundColor DarkGray
  }
  else { Ok 'python-deps' 'scraping + memory + playback deps present' }
}

# ── 5. live MCP status ─────────────────────────────────────────────
if ($oc) {
  $mcp = & opencode mcp list 2>&1 | Out-String
  foreach ($line in ($mcp -split "`r?`n")) {
    $t = $line.Trim()
    if (-not $t) { continue }
    # `opencode mcp list` prefixes status glyphs: "OK browser-use  connected"
    $name = ($t -replace '[^A-Za-z0-9_\- ]',' ').Trim() -split '\s+' | Select-Object -First 1
    if (-not $name) { continue }
    if ($t -match 'connected')                { Ok   "mcp:$name" 'connected' }
    elseif ($t -match 'needs authentication')  { Warn2 "mcp:$name" 'needs OAuth - run /mcps in the TUI' }
    elseif ($t -match 'disabled')              { Warn2 "mcp:$name" 'disabled (enable when the service is up)' }
    elseif ($t -match 'failed|error')          { Fail  "mcp:$name" $t }
  }
}

# ── report ─────────────────────────────────────────────────────────
if ($Json) {
  $results | ConvertTo-Json -Depth 4
} else {
  Write-Host ''
  Write-Host '  agent-bootstrap doctor' -ForegroundColor White
  Write-Host '  ------------------------------------------------' -ForegroundColor DarkGray
  foreach ($r in $results) {
    $color = switch ($r.status) { 'OK' { 'Green' } 'WARN' { 'Yellow' } default { 'Red' } }
    $mark  = switch ($r.status) { 'OK' { 'OK  ' } 'WARN' { 'warn' } default { 'FAIL' } }
    Write-Host ("  {0}  {1,-18} {2}" -f $mark, $r.check, $r.detail) -ForegroundColor $color
  }
  $bad  = @($results | Where-Object { $_.status -eq 'FAIL' }).Count
  $warn = @($results | Where-Object { $_.status -eq 'WARN' }).Count
  Write-Host '  ------------------------------------------------' -ForegroundColor DarkGray
  if ($bad -eq 0) { Write-Host "  healthy ($warn warning(s))" -ForegroundColor Green }
  else             { Write-Host "  $bad failure(s), $warn warning(s)" -ForegroundColor Red }
  Write-Host ''
}

exit (@($results | Where-Object { $_.status -eq 'FAIL' }).Count -gt 0 ? 1 : 0)
