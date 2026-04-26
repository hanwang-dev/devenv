# PSReadLine — fish-style history suggestions
if (Get-Module -ListAvailable -Name PSReadLine) {
  Set-PSReadLineOption -PredictionSource History
  Set-PSReadLineOption -PredictionViewStyle ListView
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
