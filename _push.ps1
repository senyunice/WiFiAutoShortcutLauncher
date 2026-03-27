$ErrorActionPreference = "Stop"
$repoDir = "C:\Users\Administrator\Desktop\WiFiAutoShortcutLauncher"
$token = "ghp_QD4B5xZbKQmH9J5rF7sT1nL6yX3vA8eC2wK0dM"
$gitExe = "C:\Program Files\Git\cmd\git.exe"

Set-Location $repoDir
Write-Host "Current dir: $(Get-Location)"
Write-Host "Files: $(Get-ChildItem | Select-Object -First 5 | Out-String)"

# Set remote with token
& $gitExe remote set-url origin "https://senyunice:$token@github.com/senyunice/WiFiAutoShortcutLauncher.git"
Write-Host "Remote set"

# Push
$env:GIT_TERMINAL_PROMPT = "0"
& $gitExe push -u origin master 2>&1
Write-Host "Push exit code: $LASTEXITCODE"
