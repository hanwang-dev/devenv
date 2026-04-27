#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

param(
  [switch]$Schedule,
  [string]$ScheduleTime = "09:00",        # daily time for the scheduled task
  [string]$ScheduleDaysOfWeek = "Monday"  # comma-separated, e.g. "Monday,Thursday"
)

$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$ScriptPath = Join-Path $ScriptDir "upgrade.ps1"
$LogPath    = "$env:USERPROFILE\.devenv-upgrade.log"

function Write-Info    { param($msg) Write-Host "[INFO]  $msg" -ForegroundColor Cyan }
function Write-Ok      { param($msg) Write-Host "[OK]    $msg" -ForegroundColor Green }
function Write-Warn    { param($msg) Write-Host "[WARN]  $msg" -ForegroundColor Yellow }

function Upgrade-WingetPackages {
  Write-Info "Upgrading winget packages..."
  $ids = @(
    "Git.Git",
    "GitHub.cli",
    "Microsoft.VisualStudioCode",
    "GoLang.Go",
    "OpenJS.NodeJS.LTS",
    "Microsoft.AzureCLI",
    "Microsoft.WindowsTerminal",
    "ajeetdsouza.zoxide",
    "junegunn.fzf"
  )
  foreach ($id in $ids) {
    $before = (winget list --id $id 2>$null | Select-String $id | Select-Object -Last 1) -replace '\s+', ' '
    winget upgrade --id $id --silent --accept-source-agreements --accept-package-agreements 2>$null
    if ($LASTEXITCODE -eq 0) {
      $after = (winget list --id $id 2>$null | Select-String $id | Select-Object -Last 1) -replace '\s+', ' '
      # Extract version fields (4th column in winget list output)
      $beforeVer = ($before -split ' ')[3]
      $afterVer  = ($after  -split ' ')[3]
      if ($beforeVer -and $afterVer -and $beforeVer -ne $afterVer) {
        Write-Ok "$id upgraded ($beforeVer → $afterVer)"
      } else {
        Write-Ok "$id upgraded"
      }
    } else {
      Write-Warn "$id — already up to date or not installed"
    }
  }
}

function Upgrade-PyenvWin {
  $pyenvDir = "$env:USERPROFILE\.pyenv"
  if (Test-Path $pyenvDir) {
    Write-Info "Upgrading pyenv-win..."
    git -C $pyenvDir pull -q
    Write-Ok "pyenv-win upgraded"
  }
}

function Upgrade-NpmGlobals {
  Write-Info "Upgrading global npm packages..."
  npm update -g @openai/codex @anthropic-ai/claude-code
  Write-Ok "Codex CLI and Claude Code upgraded"
}

function Upgrade-AzureCLI {
  if (Get-Command az -ErrorAction SilentlyContinue) {
    Write-Info "Upgrading Azure CLI extensions..."
    az upgrade --yes --all 2>$null
    Write-Ok "Azure CLI upgraded"
  }
}

function Install-ScheduledTask {
  $taskName = "devenv-auto-upgrade"

  # Remove existing task if present
  Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

  $days = $ScheduleDaysOfWeek -split "," | ForEach-Object { $_.Trim() }
  $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $days -At $ScheduleTime

  $action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NonInteractive -WindowStyle Hidden -File `"$ScriptPath`" >> `"$LogPath`" 2>&1"

  $settings = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit (New-TimeSpan -Hours 1) `
    -StartWhenAvailable `
    -RunOnlyIfNetworkAvailable

  Register-ScheduledTask `
    -TaskName $taskName `
    -Trigger $trigger `
    -Action $action `
    -Settings $settings `
    -RunLevel Highest `
    -Force | Out-Null

  Write-Ok "Scheduled task '$taskName' installed"
  Write-Info "Runs every $ScheduleDaysOfWeek at $ScheduleTime"
  Write-Info "Logs: $LogPath"
  Write-Info "To remove: Unregister-ScheduledTask -TaskName '$taskName'"
}

function Run-Upgrade {
  Write-Info "=== devenv upgrade $(Get-Date -Format 'yyyy-MM-dd HH:mm') ==="
  Upgrade-WingetPackages
  Upgrade-PyenvWin
  Upgrade-NpmGlobals
  Upgrade-AzureCLI
  Write-Ok "All tools upgraded"
}

if ($Schedule) {
  Install-ScheduledTask
} else {
  Run-Upgrade
}
