# Oh My Posh — p10k-style prompt theme
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
  # Derive themes path from binary (winget installs: .../oh-my-posh/bin/oh-my-posh.exe)
  $ompThemes = Join-Path (Split-Path (Split-Path (Get-Command oh-my-posh).Source)) "themes"
  if (-not (Test-Path $ompThemes)) { $ompThemes = $env:POSH_THEMES_PATH }
  oh-my-posh init pwsh --config "$ompThemes\jandedobbeleer.omp.json" | Invoke-Expression
}

# PSReadLine — fish-style history suggestions
if (Get-Module -ListAvailable -Name PSReadLine) {
  $psrlVersion = (Get-Module -ListAvailable -Name PSReadLine | Sort-Object Version -Descending | Select-Object -First 1).Version
  if ($psrlVersion -ge [version]'2.1') {
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView
  }
  Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
}

# zoxide — frecency-based directory jumping (z <dir>, zi for interactive fzf picker)
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
  Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

# PSFzf — fzf keybindings: Ctrl+T files · Ctrl+R history · Alt+C cd into subdir
if (Get-Module -ListAvailable -Name PSFzf) {
  Import-Module PSFzf
  Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
}
