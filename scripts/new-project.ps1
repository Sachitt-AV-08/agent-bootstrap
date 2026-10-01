<# 
.SYNOPSIS
    Create a new project from template
.DESCRIPTION
    Creates a new project in projects/ from a template
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [string]$Name,
    
    [ValidateSet('python', 'node', 'basic')]
    [string]$Template = 'python',
    
    [string]$Description = '',
    [string]$Author = $env:USERNAME,
    [string]$Email = "$env:USERNAME@users.noreply.github.com"
)

$ErrorActionPreference = 'Stop'

$projectRoot = "$PSScriptRoot\..\projects"
$projectDir = "$projectRoot\$Name"

if (Test-Path $projectDir) {
    Write-Error "Project '$Name' already exists at $projectDir"
    exit 1
}

$templateDir = "$PSScriptRoot\..\templates\${Template}-project"
if (-not (Test-Path $templateDir)) {
    Write-Error "Template '$Template' not found at $templateDir"
    exit 1
}

$packageName = $Name.ToLower().Replace('-', '_').Replace(' ', '_')
$desc = if ($Description) { $Description } else { "A $Template project: $Name" }

Write-Host "Creating project '$Name' from '$Template' template..." -ForegroundColor Cyan

# Copy template
Copy-Item $templateDir $projectDir -Recurse

# Template variables
$replacements = @{
    '{{PROJECT_NAME}}'     = $Name
    '{{PACKAGE_NAME}}'     = $packageName
    '{{PROJECT_DESCRIPTION}}' = $desc
    '{{AUTHOR}}'           = $Author
    '{{EMAIL}}'            = $Email
}

# Process all files
Get-ChildItem $projectDir -Recurse -File | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    foreach ($kv in $replacements.GetEnumerator()) {
        $content = $content -replace [regex]::Escape($kv.Key), $kv.Value
    }
    # Rename files with template vars
    $newName = $_.Name
    foreach ($kv in $replacements.GetEnumerator()) {
        $newName = $newName -replace [regex]::Escape($kv.Key), $kv.Value
    }
    if ($newName -ne $_.Name) {
        Rename-Item $_.FullName (Join-Path $_.DirectoryName $newName)
    } else {
        Set-Content $_.FullName $content -Encoding UTF8
    }
}

# Rename package directory for Python
if ($Template -eq 'python') {
    $oldPkg = Get-ChildItem "$projectDir\src" -Directory | Where-Object { $_.Name -match '^\{\{PACKAGE_NAME\}\}$' }
    if ($oldPkg) {
        Rename-Item $oldPkg.FullName "$projectDir\src\$packageName"
    }
}

# Initialize git
git -C $projectDir init -q
git -C $projectDir add -A
git -C $projectDir commit -m "Initial commit from $Template template" -q

Write-Success "Project created at $projectDir"
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "  cd $projectDir"
if ($Template -eq 'python') {
    Write-Host "  uv sync --dev"
    Write-Host "  uv run pytest"
} elseif ($Template -eq 'node') {
    Write-Host "  npm install"
    Write-Host "  npm test"
}
Write-Host "  opencode"