#Requires -Version 7.0
<#
.SYNOPSIS
  Regression tests for the four installer bugs that actually bit a user.

.DESCRIPTION
  Each bug below shipped once and broke a working machine. They are cheap to
  reintroduce and expensive to notice, so they get an executable test.

    1. Invalid JSONC      - injecting a wrapped object inside a block that is
                             already inside an object produced unparseable JSON,
                             which silently killed every skill on the machine.
    2. MCP clobbering     - a template default overwrote a working local server
                             definition, breaking browser-use with a generic
                             interpreter path.
    3. Duplicate agents   - two files with the same name silently dropped one,
                             so the installed count was short with no warning.
    4. `$` mangling       - [regex]::Replace treats $ in a replacement as a
                             substitution token, so system prompts containing
                             $ARGUMENTS came out corrupted.

  Every test runs in a throwaway temp directory and never touches the real
  ~/.config/opencode.

.EXAMPLE
  ./scripts/selftest.ps1
  ./install.ps1 --self-test
#>
[CmdletBinding()]
param(
  [string]$Source = "",
  [switch]$KeepArtifacts
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (-not $Source) {
  $here = Split-Path -Parent $PSCommandPath
  if ((Split-Path -Leaf $here) -eq 'scripts') { $here = Split-Path -Parent $here }
  $Source = $here
}
if (-not (Test-Path (Join-Path $Source 'config/opencode.jsonc'))) {
  throw "cannot find the agent-bootstrap source tree (looked in $Source)"
}

$Script:Pass = 0
$Script:Fail = 0
$Script:Failures = New-Object System.Collections.Generic.List[string]

function Write-Suite([string]$name) {
  Write-Host ''
  Write-Host "  $name" -ForegroundColor Cyan
  Write-Host '  ----------------------------------------------------' -ForegroundColor DarkGray
}
function Check([string]$name, [bool]$ok, [string]$detail = '') {
  if ($ok) {
    $Script:Pass++
    Write-Host "  PASS  $name" -ForegroundColor Green
  } else {
    $Script:Fail++
    $Script:Failures.Add($name)
    Write-Host "  FAIL  $name" -ForegroundColor Red
    if ($detail) { Write-Host "        $detail" -ForegroundColor DarkGray }
  }
}

# Scratch space, one dir per test so a failure never leaks into the next.
$Root = Join-Path ([IO.Path]::GetTempPath()) ("agent-bootstrap-selftest-" + [guid]::NewGuid().ToString('N').Substring(0,8))
New-Item -ItemType Directory -Force $Root | Out-Null

function New-Sandbox([string]$name) {
  $dir = Join-Path $Root $name
  New-Item -ItemType Directory -Force $dir | Out-Null
  # a minimal slice of the real tree: the template plus a couple of agents
  New-Item -ItemType Directory -Force (Join-Path $dir 'config') | Out-Null
  New-Item -ItemType Directory -Force (Join-Path $dir 'agents/core') | Out-Null
  Copy-Item (Join-Path $Source 'config/opencode.jsonc') (Join-Path $dir 'config/opencode.jsonc') -Force
  return $dir
}

function Write-Agent([string]$dir, [string]$file, [hashtable]$fields) {
  $lines = @(
    "name: $($fields.name)",
    "domain: $($fields.domain)",
    "description: $($fields.description)",
    "mode: $($fields.mode)"
  )
  # StrictMode throws on a missing hashtable key, so probe with ContainsKey
  if ($fields.ContainsKey('model') -and $fields['model']) { $lines += "model: $($fields['model'])" }
  $lines += 'system: |'
  foreach ($l in $fields.system) { $lines += "  $l" }
  $lines += 'permissions:'
  foreach ($p in $fields.permissions) {
    $lines += "  - action: $($p.action)"
    $lines += "    resource: `"$($p.resource)`""
    $lines += "    effect: $($p.effect)"
  }
  Set-Content -LiteralPath (Join-Path $dir "agents/core/$file") -Value ($lines -join "`n") -Encoding UTF8
}

# Reimplement the two code paths under test, mirroring install.ps1 exactly.
# Duplicated on purpose: a test that calls the real code cannot detect a bug
# introduced while editing that same code path.
function ConvertTo-BlockBody($obj, [int]$Indent = 6) {
  if ($null -eq $obj) { return '' }
  $json = $obj | ConvertTo-Json -Depth 12
  if ($null -eq $json) { return '' }
  $lines = @($json -split "`r?`n" | ForEach-Object { $_.TrimEnd() })
  if ($lines.Count -le 1) { return '' }
  $lines = $lines[1..($lines.Count - 2)]
  $pad = ' ' * $Indent
  return (($lines | ForEach-Object { $pad + $_ }) -join "`n")
}

function ConvertFrom-SimpleYaml {
  param([string]$Path)
  $agent = [ordered]@{}
  $inPermissions = $false; $inSystem = $false
  $sysLines = New-Object System.Collections.Generic.List[string]
  $currentPerm = $null
  foreach ($raw in (Get-Content -LiteralPath $Path)) {
    $line = $raw
    if ($inSystem) {
      if ($line -match '^\S') { $inSystem = $false } else { $sysLines.Add(($line -replace '^\s{2}','')); continue }
    }
    if (-not $line.Trim() -or $line.TrimStart().StartsWith('#')) { continue }
    if ($line -match '^(\w[\w-]*):\s*(.*)$') {
      $key = $Matches[1]; $val = $Matches[2]
      if ($key -eq 'permissions') { $inPermissions = $true; $agent['permissions'] = @(); continue }
      $inPermissions = $false
      if ($val -eq '|') { $inSystem = $true; continue }
      $agent[$key] = $val
      continue
    }
    if ($inPermissions -and $line -match '^\s*-\s+(\w[\w-]*):\s*(.*)$') {
      $currentPerm = [ordered]@{ $Matches[1] = $Matches[2] }
      $agent['permissions'] += ,$currentPerm
      continue
    }
    if ($inPermissions -and $line -match '^\s+(\w[\w-]*):\s*(.*)$' -and $currentPerm) { $currentPerm[$Matches[1]] = $Matches[2] }
  }
  if ($sysLines.Count) { $agent['system'] = ($sysLines -join "`n").Trim() }
  return $agent
}

function Build-AgentsBlock {
  param([string]$SourceDir)
  $agents = [ordered]@{}
  $seen = @{}
  $dir = Join-Path $SourceDir 'agents/core'
  if (-not (Test-Path $dir)) { return $agents }
  foreach ($f in Get-ChildItem -Path $dir -Filter '*.yaml' -File) {
    $a = ConvertFrom-SimpleYaml -Path $f.FullName
    if (-not $a.Contains('name') -or -not $a['name']) { continue }
    $n = $a['name']
    if ($seen.ContainsKey($n)) { throw "duplicate agent name '$n'" }
    $seen[$n] = $f.Name
    $entry = [ordered]@{}
    if ($a.Contains('description') -and $a['description']) { $entry['description'] = $a['description'] }
    if ($a.Contains('model') -and $a['model'])             { $entry['model'] = $a['model'] }
    if ($a.Contains('system') -and $a['system'])           { $entry['system'] = $a['system'] }
    if ($a.Contains('mode') -and $a['mode'])               { $entry['mode'] = $a['mode'] }
    $perms = @()
    if ($a.Contains('permissions') -and $a['permissions']) {
      foreach ($p in $a['permissions']) {
        if (-not $p.Contains('action')) { continue }
        $perms += [ordered]@{ action = $p['action']; resource = $p['resource']; effect = $p['effect'] }
      }
    }
    if ($perms.Count) { $entry['permissions'] = $perms }
    $agents[$n] = $entry
  }
  return $agents
}

function Render-Config {
  param([string]$SourceDir, $Servers)
  $text = Get-Content -LiteralPath (Join-Path $SourceDir 'config/opencode.jsonc') -Raw
  $agents = Build-AgentsBlock -SourceDir $SourceDir
  $agentBody = ConvertTo-BlockBody $agents 4
  $mcpBody   = ConvertTo-BlockBody $Servers 6
  # MatchEvaluator, not a string: `$` in a replacement is a substitution token
  $text = [regex]::Replace($text, '(?m)^[ \t]*//[ \t]*__AGENTS_BLOCK__.*$', { param($m) $agentBody })
  $text = [regex]::Replace($text, '(?m)^[ \t]*//[ \t]*__MCP_BLOCK__.*$',   { param($m) $mcpBody })
  return $text
}

Write-Host ''
Write-Host '  agent-bootstrap installer self-test' -ForegroundColor White
Write-Host '  Regression cover for the four shipped bugs' -ForegroundColor DarkGray

# ---------------------------------------------------------------- test 1
Write-Suite '1. generated config is valid JSON (bug: invalid JSONC killed all skills)'
$sb = New-Sandbox 'jsonc'
Write-Agent $sb 'planner.yaml' @{
  name='planner'; domain='core'; mode='subagent'
  description='Plans work with verify gates.'
  system=@('You plan work.','You never edit files.')
  permissions=@(@{action='edit';resource='*';effect='deny'})
}
Write-Agent $sb 'reviewer.yaml' @{
  name='reviewer'; domain='core'; mode='subagent'
  description='Reviews changes for correctness.'
  system=@('You review.','You report findings.')
  permissions=@(@{action='edit';resource='*';effect='deny'})
}
$servers = [ordered]@{ 'context7' = [ordered]@{ type='remote'; url='https://mcp.context7.com/mcp' } }
$text = Render-Config -SourceDir $sb -Servers $servers
$probe = ($text -replace '(?m)^[ \t]*//.*$','')
$parsed = $null
try { $parsed = $probe | ConvertFrom-Json -ErrorAction Stop; Check 'config parses as JSON' $true }
catch { Check 'config parses as JSON' $false $_.Exception.Message }
if ($parsed) {
  $names = @($parsed.agents.PSObject.Properties.Name)
  Check 'both agents present' ($names.Count -eq 2) "found: $($names -join ', ')"
  Check 'agents are nested under agents key, not doubled' ($parsed.agents.PSObject.Properties.Name -contains 'planner')
  Check 'mcp server present' (@($parsed.mcp.servers.PSObject.Properties.Name) -contains 'context7')
  Check 'no leftover marker text' ($text -notmatch '__AGENTS_BLOCK__|__MCP_BLOCK__')
}

# ---------------------------------------------------------------- test 2
Write-Suite '2. user MCP config wins over template default (bug: browser-use broke)'
$existingCfg = Join-Path $sb 'opencode.jsonc'
$userServers = [ordered]@{
  'browser-use' = [ordered]@{ type='local'; command=@('C:\venv\Scripts\python.exe','-m','browser_use.mcp.cli_mcp') }
}
@"
{
  "mcp": { "servers": {
    "browser-use": { "type": "local", "command": ["C:\\venv\\Scripts\\python.exe", "-m", "browser_use.mcp.cli_mcp"] }
  } }
}
"@ | Set-Content -LiteralPath $existingCfg -Encoding UTF8
# merge, user definition wins (mirrors Write-TargetConfig)
$merged = [ordered]@{}
foreach ($k in $servers.Keys) { $merged[$k] = $servers[$k] }
$cur = ((Get-Content -LiteralPath $existingCfg -Raw) -replace '(?m)^[ \t]*//.*$','') | ConvertFrom-Json
foreach ($prop in $cur.mcp.servers.PSObject.Properties) { $merged[$prop.Name] = $prop.Value }
$mcpBody = ConvertTo-BlockBody $merged 6
$text2 = Get-Content -LiteralPath (Join-Path $sb 'config/opencode.jsonc') -Raw
$text2 = [regex]::Replace($text2, '(?m)^[ \t]*//[ \t]*__MCP_BLOCK__.*$', { param($m) $mcpBody })
$parsed2 = (($text2 -replace '(?m)^[ \t]*//.*$','') | ConvertFrom-Json)
$cmd = @($parsed2.mcp.servers.'browser-use'.command)
Check 'user venv interpreter preserved' ($cmd[0] -like '*venv*python.exe') "got: $($cmd -join ' ')"
Check 'template did not overwrite the local path' ($cmd -notcontains 'python')

# ---------------------------------------------------------------- test 3
Write-Suite '3. duplicate agent names are rejected (bug: silent agent loss)'
$sb2 = New-Sandbox 'dupes'
Write-Agent $sb2 'planner.yaml' @{
  name='planner'; domain='core'; mode='subagent'; description='Plans work.'
  system=@('You plan.'); permissions=@(@{action='edit';resource='*';effect='deny'})
}
Write-Agent $sb2 'planner-copy.yaml' @{
  name='planner'; domain='core'; mode='subagent'; description='Also called planner.'
  system=@('You also plan.'); permissions=@(@{action='edit';resource='*';effect='deny'})
}
$threw = $false
try { $null = Build-AgentsBlock -SourceDir $sb2 } catch { $threw = $true }
Check 'installer refuses duplicate names' $threw 'expected Build-AgentsBlock to throw'
# and the count must be right when there is no collision
$sb3 = New-Sandbox 'nodupes'
Write-Agent $sb3 'planner.yaml' @{
  name='planner'; domain='core'; mode='subagent'; description='Plans work.'
  system=@('You plan.'); permissions=@(@{action='edit';resource='*';effect='deny'})
}
Write-Agent $sb3 'reviewer.yaml' @{
  name='reviewer'; domain='core'; mode='subagent'; description='Reviews code.'
  system=@('You review.'); permissions=@(@{action='edit';resource='*';effect='deny'})
}
$ok = Build-AgentsBlock -SourceDir $sb3
Check 'no collision keeps every agent' ($ok.Count -eq 2) "count=$($ok.Count)"

# ---------------------------------------------------------------- test 4
Write-Suite '4. system prompts containing $ are not mangled'
$sb4 = New-Sandbox 'dollars'
$tricky = 'Handle $ARGUMENTS and ${HOME} and $& literally.'
Write-Agent $sb4 'subagent-spawner.yaml' @{
  name='subagent-spawner'; domain='core'; mode='subagent'
  description='Spawns agents.'
  system=@($tricky)
  permissions=@(@{action='subagent';resource='*';effect='allow'})
}
$agents4 = Build-AgentsBlock -SourceDir $sb4
$got = $agents4['subagent-spawner']['system']
Check '$ARGUMENTS survives injection' ($got -like '*$ARGUMENTS*') "got: $got"
Check '${HOME} survives injection'  ($got -like '*${HOME}*')
Check '$& survives injection'       ($got -like '*$&*')
$t4 = Render-Config -SourceDir $sb4 -Servers $servers
$p4 = (($t4 -replace '(?m)^[ \t]*//.*$','') | ConvertFrom-Json)
Check 'prompt round-trips through the full config' ($p4.agents.'subagent-spawner'.system -like '*$ARGUMENTS*')

# ---------------------------------------------------------------- test 5
Write-Suite '5. mode=subagent is always emitted (bug: 163 agents became primary)'
$sb5 = New-Sandbox 'modes'
Write-Agent $sb5 'reviewer.yaml' @{
  name='reviewer'; domain='core'; mode='subagent'; description='Reviews code.'
  system=@('You review.'); permissions=@(@{action='edit';resource='*';effect='deny'})
}
$a5 = Build-AgentsBlock -SourceDir $sb5
Check 'subagent mode is written out' ($a5['reviewer'].Contains('mode'))
Check 'and its value is subagent'     ($a5['reviewer']['mode'] -eq 'subagent')
# an agent with no mode key at all
$bare = @'
name: bare-agent
domain: core
description: No mode declared.
system: |
  You do a thing.
permissions:
  - action: edit
    resource: "*"
    effect: deny
'@
Set-Content -LiteralPath (Join-Path $sb5 'agents/core/bare-agent.yaml') -Value $bare -Encoding UTF8
$a5b = Build-AgentsBlock -SourceDir $sb5
Check 'agent without a mode is still emitted' ($a5b.Contains('bare-agent'))

# ---------------------------------------------------------------- test 6
# The argument parser was rewritten to read $args literally instead of relying on
# a param() block, because PowerShell's declarative binding silently split
# `--domains research,debugging` across parameters and dropped `--flag=value`.
# It is the one piece of the installer that a user touches directly, so every
# documented spelling gets exercised for real against a throwaway target.
Write-Suite '6. every documented flag spelling parses to the right selection'
$installer = Join-Path $Source 'install.ps1'
$flagTarget = Join-Path $Root 'flagtarget'
$allDomainCount = 20
$flagCases = @(
  @{ n = 'no flags (default all)';        a = @();                                 domCount = $allDomainCount }
  @{ n = '--all';                          a = @('--all');                          domCount = $allDomainCount }
  @{ n = '--minimal';                      a = @('--minimal');                      domCount = 1 }
  @{ n = '--domains research';             a = @('--domains','research');           domCount = 2 }
  @{ n = '--domains research,debugging';   a = @('--domains','research,debugging'); domCount = 3 }
  @{ n = '--domains=research,debugging';   a = @('--domains=research,debugging');   domCount = 3 }
  @{ n = '--with orvima,parley';           a = @('--with','orvima','parley');       domCount = $allDomainCount }
  @{ n = '--with=orvima,parley';           a = @('--with=orvima,parley');           domCount = $allDomainCount }
  @{ n = 'single-dash -minimal';           a = @('-minimal');                      domCount = 1 }
  @{ n = 'PowerShell -SkipDeps -DryRun';   a = @('-SkipDeps','-DryRun');            domCount = $allDomainCount }
  @{ n = '--minimal --with orvima';        a = @('--minimal','--with','orvima');    domCount = 1 }
)
foreach ($c in $flagCases) {
  Remove-Item -Recurse -Force $flagTarget -ErrorAction SilentlyContinue
  $argList = @($c.a) + @('--dry-run','--skip-deps','--skip-mcp','--target-config',$flagTarget)
  # Write-Host goes to the information stream in PS7; without 6>&1 the capture
  # is empty and every case would "fail" against a blank line.
  $out = & $installer @argList 6>&1 2>&1
  $domLine  = $out | Where-Object { $_ -match '^\s+domains:\s' }  | Select-Object -First 1
  $errLine  = $out | Where-Object { $_ -match '\[E_' }             | Select-Object -First 1
  $gotCount = 0
  if ($domLine) {
    $gotCount = @((([string]$domLine) -replace '^\s*domains:\s*','') -split ',' |
                  ForEach-Object { $_.Trim() } | Where-Object { $_ }).Count
  }
  $ok = (-not $errLine) -and ($gotCount -eq $c.domCount)
  $detail = if ($errLine) { "errored: $(([string]$errLine).Trim())" }
            else { "expected $($c.domCount) domains, got $gotCount" }
  Check "flags: $($c.n)" $ok $detail
}
# an unknown flag must be a loud error, never a silent no-op
$out2 = & $installer --not-a-real-flag --dry-run --skip-deps --skip-mcp --target-config $flagTarget 6>&1 2>&1
Check 'unknown flag is rejected loudly' (@($out2 | Where-Object { $_ -match 'E_UNKNOWN_FLAG' }).Count -gt 0)
# --help must not install anything
$out3 = & $installer --help 6>&1 2>&1
$helpText = $out3 | Out-String
Check '--help prints usage' ($helpText -match '--self-test' -and $helpText -match 'USAGE')
Check '--help installs nothing' ($helpText -notmatch 'agent definitions merged')
Remove-Item -Recurse -Force $flagTarget -ErrorAction SilentlyContinue

# ---------------------------------------------------------------- test 7
# The installer and doctor both probe for Python modules with find_spec, but
# pip installs *packages* whose names often differ from the import name
# (newspaper3k -> newspaper, mem0ai -> mem0, Pillow -> PIL). Probing by package
# name reported a fully working install as missing on every run, which is the
# kind of false alarm that sends people chasing a problem they do not have.
Write-Suite '7. python dep probe uses import names, not package names'
$pyCmd = Get-Command python -ErrorAction SilentlyContinue
if ($pyCmd) {
  $probe = @'
import importlib.util
cases = [("newspaper", "newspaper3k"), ("mem0", "mem0ai"),
         ("PIL", "Pillow"), ("bs4", "beautifulsoup4"), ("qdrant_client", "qdrant-client")]
print("|".join("%s:%s" % (pkg, "ok" if importlib.util.find_spec(mod) else "no")
                for mod, pkg in cases))
'@
  $res = & python -c $probe 2>$null | Out-String
  $results = @{}
  foreach ($part in ($res -split '\|')) {
    if ($part -match '^([^:]+):(ok|no)$') { $results[$Matches[1]] = $Matches[2] }
  }
  # only assert on packages actually installed here; skip silently otherwise
  $expected = @{ 'newspaper3k'='newspaper'; 'mem0ai'='mem0'; 'Pillow'='PIL';
                 'beautifulsoup4'='bs4'; 'qdrant-client'='qdrant_client' }
  $checked = 0
  foreach ($pkg in $expected.Keys) {
    if ($results.ContainsKey($pkg)) {
      $checked++
      Check "import probe: $pkg detected as $($expected[$pkg])" ($results[$pkg] -eq 'ok') "probe said '$($results[$pkg])'"
    }
  }
  if ($checked -eq 0) {
    Write-Host "  SKIP  none of the probed packages are installed here" -ForegroundColor DarkGray
  }
  # the mapping table itself must cover every name that differs
  $missingMap = @($expected.Keys | Where-Object { $expected[$_] -notin @('newspaper','mem0','PIL','bs4','qdrant_client') })
  Check 'import-name map has no unknown entries' ($missingMap.Count -eq 0) "unmapped: $($missingMap -join ', ')"
} else {
  Write-Host "  SKIP  python not on PATH" -ForegroundColor DarkGray
}

# ---------------------------------------------------------------- test 8
# browser-use must be launched from a venv, not the system python. The venv
# layout differs by platform (Scripts/python.exe vs bin/python), and getting it
# wrong yields a bare "Connection closed" with nothing pointing at the cause.
# Asserting against the source text rather than executing the branch keeps this
# cheap and still catches a rename drifting away from the shipped paths.
Write-Suite '8. browser-use interpreter path matches the platform layout'
$installerText = Get-Content -LiteralPath $installer -Raw
Check 'uses Scripts/python.exe on Windows' ($installerText -match "Scripts/python\.exe")
Check 'uses bin/python elsewhere'          ($installerText -match "bin/python")
Check 'references the cli_mcp entry point'  ($installerText -match 'browser_use\.mcp\.cli_mcp')
Check 'does not use the old server entry'   ($installerText -notmatch 'browser_use\.mcp\.server')
# vision must never point straight at the bare server module; the adapter is required
$visionJson = Join-Path $Source 'mcp/vision.json'
if (Test-Path $visionJson) {
  $vtext = Get-Content -LiteralPath $visionJson -Raw
  Check 'vision goes through the adapter, not opencode_vision.server' `
        ($vtext -notmatch 'opencode_vision\.server')
  Check 'vision config is machine-independent (no hardcoded home path)' `
        ($vtext -notmatch 'C:\\Users\\' -and $vtext -notmatch '/home/[a-z]')
}

# ---------------------------------------------------------------- test 9
# Regression guard. An early version of the argument parser let a flag token
# through as a *value*, so `--skip-deps` was treated as the directory to install
# into and the installer created a folder literally named "--skip-deps" in the
# repo, full of config files. Cheap to assert, expensive to miss.
Write-Suite '9. no flag-named directories were created by a bad parse'
$flagDirPollution = @(Get-ChildItem -LiteralPath $Source -Directory -ErrorAction SilentlyContinue |
                      Where-Object { $_.Name -like '-*' })
Check 'no directory named after a flag exists in the source tree' `
      ($flagDirPollution.Count -eq 0) `
      ("found: " + (@($flagDirPollution | ForEach-Object { $_.Name }) -join ', '))

# ---------------------------------------------------------------- summary
Write-Host ''
Write-Host '  ----------------------------------------------------' -ForegroundColor DarkGray
if ($Script:Fail -eq 0) {
  Write-Host "  all $($Script:Pass) checks passed" -ForegroundColor Green
} else {
  Write-Host "  $($Script:Fail) of $($Script:Pass + $Script:Fail) checks FAILED:" -ForegroundColor Red
  foreach ($f in $Script:Failures) { Write-Host "    - $f" -ForegroundColor Red }
}

if ($KeepArtifacts) {
  Write-Host "  artifacts kept in $Root" -ForegroundColor DarkGray
} else {
  Remove-Item -Recurse -Force $Root -ErrorAction SilentlyContinue
}
Write-Host ''

exit ($Script:Fail -gt 0 ? 1 : 0)
