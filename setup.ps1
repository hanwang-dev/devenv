#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Write-Info    { param($msg) Write-Host "[INFO]  $msg" -ForegroundColor Cyan }
function Write-Ok      { param($msg) Write-Host "[OK]    $msg" -ForegroundColor Green }
function Write-Warn    { param($msg) Write-Host "[WARN]  $msg" -ForegroundColor Yellow }
function Write-Err     { param($msg) Write-Host "[ERR]   $msg" -ForegroundColor Red }

function Test-Command {
  param($Name)
  return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Install-WingetPackage {
  param($Id, $Name)
  winget list --id $Id --exact --accept-source-agreements | Out-Null
  if ($LASTEXITCODE -eq 0) {
    Write-Ok "$Name already installed"
  } else {
    Write-Info "Installing $Name..."
    winget install --id $Id --silent --accept-source-agreements --accept-package-agreements
    Write-Ok "$Name installed"
  }
}

function Install-Packages {
  Write-Info "=== Windows Package Installation ==="

  if (-not (Test-Command winget)) {
    Write-Err "winget not found. Install App Installer from the Microsoft Store first."
    exit 1
  }

  $packages = @(
    @{ Id = "Git.Git";                    Name = "Git" },
    @{ Id = "GitHub.cli";                 Name = "GitHub CLI" },
    @{ Id = "Microsoft.VisualStudioCode"; Name = "VS Code" },
    @{ Id = "GoLang.Go";                  Name = "Go" },
    @{ Id = "OpenJS.NodeJS.LTS";          Name = "Node.js LTS" },
    @{ Id = "Microsoft.AzureCLI";         Name = "Azure CLI" },
    @{ Id = "Microsoft.WindowsTerminal";  Name = "Windows Terminal" },
    @{ Id = "ajeetdsouza.zoxide";         Name = "zoxide" },
    @{ Id = "junegunn.fzf";              Name = "fzf" },
    @{ Id = "JanDeDobbeleer.OhMyPosh";  Name = "Oh My Posh" }
  )

  foreach ($pkg in $packages) {
    Install-WingetPackage -Id $pkg.Id -Name $pkg.Name
  }

  # Refresh PATH so npm is available in this session
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
              [System.Environment]::GetEnvironmentVariable("Path", "User")

  Write-Info "Installing Python via pyenv-win..."
  if (-not (Test-Path "$env:USERPROFILE\.pyenv")) {
    Invoke-WebRequest -UseBasicParsing `
      "https://raw.githubusercontent.com/pyenv-win/pyenv-win/master/pyenv-win/install-pyenv-win.ps1" `
      -OutFile "$env:TEMP\install-pyenv-win.ps1"
    & "$env:TEMP\install-pyenv-win.ps1"
    Write-Ok "pyenv-win installed"
  } else {
    Write-Ok "pyenv-win already installed"
  }

  Write-Info "Installing npm global tools..."
  npm install -g @openai/codex @anthropic-ai/claude-code
  Write-Ok "Codex CLI and Claude Code installed"

  $psrl = Get-Module -ListAvailable PSReadLine | Sort-Object Version -Descending | Select-Object -First 1
  if (-not $psrl -or $psrl.Version -lt [version]'2.1') {
    Write-Info "Installing PSReadLine (latest)..."
    Install-Module -Name PSReadLine -Force -Scope CurrentUser -SkipPublisherCheck
    Write-Ok "PSReadLine installed"
  } else {
    Write-Ok "PSReadLine $($psrl.Version) already installed"
  }

  if (-not (Get-Module -ListAvailable PSFzf)) {
    Write-Info "Installing PSFzf module..."
    Install-Module -Name PSFzf -Scope CurrentUser
    Write-Ok "PSFzf installed"
  } else {
    Write-Ok "PSFzf already installed"
  }
}

function Configure-Git {
  Write-Info "=== Git Configuration ==="
  $currentName  = git config --global user.name  2>$null
  $currentEmail = git config --global user.email 2>$null

  if (-not $currentName) {
    $gitName = Read-Host "Git user name"
    git config --global user.name $gitName
  } else {
    Write-Ok "Git name: $currentName"
  }

  if (-not $currentEmail) {
    $gitEmail = Read-Host "Git email"
    git config --global user.email $gitEmail
  } else {
    Write-Ok "Git email: $currentEmail"
  }

  # Apply shared gitconfig settings
  $gitconfigSrc = Join-Path $ScriptDir "configs\git\.gitconfig"
  git config --global include.path $gitconfigSrc
  Write-Ok "gitconfig applied"
}

function Install-VSCodeExtensions {
  if (-not (Test-Command code)) {
    Write-Warn "VS Code CLI not found — skipping extensions"
    return
  }
  Write-Info "Installing VS Code extensions..."
  $extFile = Join-Path $ScriptDir "configs\vscode\extensions.txt"
  Get-Content $extFile | Where-Object { $_ -notmatch "^#|^\s*$" } | ForEach-Object {
    code --install-extension $_ --force
  }
  Write-Ok "VS Code extensions installed"
}

function Install-SarasaFont {
  Write-Info "=== Sarasa Mono SC ==="
  $fontInstalled = (
    (Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Windows\Fonts" -Filter "SarasaMonoSC*" -ErrorAction SilentlyContinue) -or
    (Get-ChildItem "C:\Windows\Fonts" -Filter "SarasaMonoSC*" -ErrorAction SilentlyContinue)
  )
  if ($fontInstalled) {
    Write-Ok "Sarasa Mono SC already installed"
    return
  }
  Write-Info "Downloading Sarasa Mono SC..."
  $release = Invoke-RestMethod "https://api.github.com/repos/be5invis/Sarasa-Gothic/releases/latest"
  $ver = $release.tag_name -replace '^v', ''
  $url = "https://github.com/be5invis/Sarasa-Gothic/releases/download/v$ver/Sarasa-MonoSC-TTF-$ver.7z"
  $tmp = "$env:TEMP\sarasa.7z"
  Invoke-WebRequest -Uri $url -OutFile $tmp -UseBasicParsing
  $fontDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
  New-Item -ItemType Directory -Force -Path $fontDir | Out-Null
  & "${env:ProgramFiles}\7-Zip\7z.exe" e $tmp -o"$fontDir" "*.ttf" -r -y | Out-Null
  Remove-Item $tmp
  # Register fonts in the registry
  $regPath = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
  Get-ChildItem $fontDir -Filter "SarasaMonoSC*" | ForEach-Object {
    $name = $_.BaseName + " (TrueType)"
    Set-ItemProperty -Path $regPath -Name $name -Value $_.FullName
  }
  Write-Ok "Sarasa Mono SC installed"
}

function Configure-WindowsTerminal {
  Write-Info "=== Windows Terminal font ==="
  $settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
  if (-not (Test-Path $settingsPath)) {
    Write-Warn "Windows Terminal settings.json not found — skipping font config"
    return
  }
  $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
  $font = [PSCustomObject]@{ face = "Sarasa Mono SC" }
  $settings.profiles.defaults | Add-Member -NotePropertyName font -NotePropertyValue $font -Force
  # Use WriteAllText to avoid the UTF-8 BOM that PS5.1 Set-Content adds
  [System.IO.File]::WriteAllText($settingsPath, ($settings | ConvertTo-Json -Depth 10), [System.Text.UTF8Encoding]::new($false))
  Write-Ok "Windows Terminal font set to Sarasa Mono SC"
}

function Install-OhMyPoshTheme {
  Write-Info "=== Oh My Posh Theme ==="
  $themesDir = "$env:USERPROFILE\.cache\oh-my-posh\themes"
  New-Item -ItemType Directory -Force -Path $themesDir | Out-Null
  $themeFile = "$themesDir\clean-detailed.omp.json"
  if (Test-Path $themeFile) {
    Write-Ok "clean-detailed theme already present"
    return
  }
  $url = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/clean-detailed.omp.json"
  Invoke-WebRequest -Uri $url -OutFile $themeFile -UseBasicParsing
  Write-Ok "clean-detailed theme downloaded to $themesDir"
}

function Configure-PSProfile {
  Write-Info "=== PowerShell Profile ==="
  $profileDir = Split-Path $PROFILE
  New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
  $src = Join-Path $ScriptDir "configs\shell\profile.ps1"
  if (Test-Path $PROFILE) {
    Move-Item $PROFILE "$PROFILE.bak" -Force
    Write-Warn "Backed up existing PowerShell profile"
  }
  New-Item -ItemType SymbolicLink -Path $PROFILE -Target $src -Force | Out-Null
  Write-Ok "PowerShell profile linked"
}

function Link-VSCodeSettings {
  $vscodeSrc = Join-Path $ScriptDir "configs\vscode\settings.json"
  $vscodeDir = "$env:APPDATA\Code\User"
  New-Item -ItemType Directory -Force -Path $vscodeDir | Out-Null
  $dst = Join-Path $vscodeDir "settings.json"
  if (Test-Path $dst) {
    Move-Item $dst "$dst.bak" -Force
    Write-Warn "Backed up existing settings.json"
  }
  New-Item -ItemType SymbolicLink -Path $dst -Target $vscodeSrc -Force | Out-Null
  Write-Ok "VS Code settings linked"
}

# Main
Install-Packages
Install-SarasaFont
Configure-WindowsTerminal
Configure-Git
Install-VSCodeExtensions
Link-VSCodeSettings
Install-OhMyPoshTheme
Configure-PSProfile

Write-Host ""
Write-Ok "Dev environment ready! Restart your terminal to apply PATH changes."
