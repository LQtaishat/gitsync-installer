# =================================================================
# GitSync Tool Suite Installer - Definitive Edition
# =================================================================
# - Fixes download issues with a standard User-Agent header.
# - Intelligently checks for existing installations and versions.
# - Prompts user to skip, reinstall, or upgrade.
# - Comprehensive logging with a final message showing the log path.
# =================================================================

# --- Step 0: Initial Setup ---
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$global:latestVersion = "1.0.0" # The version available for download

# --- Step 1: Setup Logging ---
$logFile = "$([Environment]::GetFolderPath('Desktop'))\gitsync-installer-log.txt"
Function Write-Log {
    param([string]$Message, [string]$Color = "White")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage -ForegroundColor $Color
    Add-Content -Path $logFile -Value $logMessage
}
if (Test-Path $logFile) { Remove-Item $logFile }
Write-Log -Message "GitSync Installer log started for version $global:latestVersion." -Color Green


# --- Reusable Functions ---
function Show-FinalMessageAndPause {
    param([string]$Message, [string]$Color = "Green")
    $finalMessage = "`n======================================================`n $Message`n======================================================`n"
    Write-Log -Message $finalMessage -Color $Color
    Write-Log -Message "For full details, see the log file at: $logFile" -Color Gray
    Read-Host "Press Enter to exit..."
}

function Ensure-Chocolatey {
    # (This function remains robust and does not need changes)
    Write-Log -Message "`n----- Checking for Chocolatey..." -Color Yellow
    try {
        if (Get-Command choco -ErrorAction SilentlyContinue) { Write-Log -Message "SUCCESS: Chocolatey is already installed." -Color Green; return }
        Write-Log -Message "INFO: Chocolatey (a package manager) is required. Installing now..."
        Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    } catch {
        Show-FinalMessageAndPause -Message "FATAL: Failed to install Chocolatey.`nError Details: $($_.Exception.Message)" -Color Red; exit
    }
}

function Ensure-Prerequisite {
    # (This function remains robust and does not need changes)
    param([string]$CommandName, [string]$PackageName)
    Write-Log -Message "`n----- Checking for $CommandName..." -Color Yellow
    try {
        if (Get-Command $CommandName -ErrorAction SilentlyContinue) { Write-Log -Message "SUCCESS: $CommandName is already installed." -Color Green }
        else {
            Write-Log -Message "INFO: $CommandName is not found. Installing '$PackageName'..."
            choco install $PackageName -y | Out-Null
            if (-not (Get-Command $CommandName -ErrorAction SilentlyContinue)) { throw "Installation of $CommandName appears to have failed." }
            Write-Log -Message "SUCCESS: $CommandName has been installed." -Color Green
        }
    } catch {
        Show-FinalMessageAndPause -Message "FATAL: Failed to install '$PackageName'.`nError Details: $($_.Exception.Message)" -Color Red; exit
    }
}

# --- NEW Intelligent Handler Functions ---

function Handle-CliInstallation {
    Write-Log -Message "`n----- Checking for existing GitSync CLI installation..." -Color Yellow
    $cliInfo = npm list -g git-sync-tool --depth=0 2>$null
    if ($cliInfo) {
        $installedVersion = ($cliInfo | Select-String -Pattern 'git-sync-tool@' | ForEach-Object { $_.ToString().Split('@')[1] }).Trim()
        Write-Log -Message "INFO: Found GitSync CLI version $installedVersion installed." -Color Cyan

        if ($installedVersion -eq $global:latestVersion) {
            $choice = Read-Host "It looks like you already have the latest version. What would you like to do? [1] Skip, [2] Reinstall"
            if ($choice -ne '2') { return "SKIP" }
        } else {
            $choice = Read-Host "An older version ($installedVersion) is installed. Upgrade to $global:latestVersion? [Y/n]"
            if ($choice -eq 'n' -or $choice -eq 'N') { return "SKIP" }
        }
    }
    return "INSTALL"
}

function Handle-ExtensionInstallation {
    Write-Log -Message "`n----- Checking for existing VS Code Extension..." -Color Yellow
    $extList = code --list-extensions --show-versions 2>$null
    $installedExt = $extList | Select-String -Pattern "LQtaishat.gitsync-vscode"
    
    if ($installedExt) {
        $installedVersion = ($installedExt | ForEach-Object { $_.ToString().Split('@')[1] }).Trim()
        Write-Log -Message "INFO: Found GitSync VS Code Extension v$installedVersion installed." -Color Cyan

        if ($installedVersion -eq $global:latestVersion) {
            $choice = Read-Host "It looks like you already have the latest version. What would you like to do? [1] Skip, [2] Reinstall"
            if ($choice -ne '2') { return "SKIP" }
        } else {
            $choice = Read-Host "An older version ($installedVersion) is installed. Upgrade to $global:latestVersion? [Y/n]"
            if ($choice -eq 'n' -or $choice -eq 'N') { return "SKIP" }
        }
    }
    return "INSTALL"
}

# --- Main Script Body ---
# (Menu logic remains the same)
while ($true) {
    Clear-Host; Write-Host "=================================================" -ForegroundColor Green; Write-Host " Welcome to the GitSync Tool Suite Installer" -ForegroundColor Green; Write-Host "================================================="
    Write-Host "`nThis script will set up the GitSync tools on your system.`n"; Write-Host "A detailed log will be saved to your Desktop: gitsync-installer-log.txt`n" -ForegroundColor Gray
    Write-Host "Please choose an option:"; Write-Host "  [1] Install CLI Tool Only" -ForegroundColor Cyan; Write-Host "`n  [2] Install Full Suite (CLI Tool + VS Code Extension)" -ForegroundColor Cyan; Write-Host "`n  [3] Exit" -ForegroundColor Cyan
    $installChoice = Read-Host "`nEnter your choice (1, 2, or 3) and press Enter"
    if ($installChoice -in '1', '2', '3') { break } else { Read-Host "`nINVALID INPUT: Please enter only 1, 2, or 3. Press Enter to try again..." }
}

switch ($installChoice) {
    '1' { # CLI Tool Only
        Write-Log -Message "`nStarting installation for: CLI Tool Only..." -Color Yellow
        Ensure-Chocolatey; Ensure-Prerequisite -CommandName "git" -PackageName "git"; Ensure-Prerequisite -CommandName "npm" -PackageName "nodejs-lts"
        
        if ((Handle-CliInstallation) -eq "INSTALL") {
            Write-Log -Message "`n----- Installing the GitSync CLI Tool..." -Color Yellow
            try {
                $cliUrl = "https://github.com/LQtaishat/gitsync-installer/releases/download/v$($global:latestVersion)/git-sync-tool-$($global:latestVersion).tgz"
                Write-Log -Message "INFO: Installing CLI tool from $cliUrl"
                powershell -Command "npm install -g $cliUrl"
            } catch { Show-FinalMessageAndPause -Message "FATAL: Failed to install the GitSync CLI tool.`nError Details: $($_.Exception.Message)" -Color Red; exit }
        } else { Write-Log -Message "Skipping CLI tool installation as requested by user." -Color Yellow }
        Show-FinalMessageAndPause -Message "Process Complete! You can now use 'gitsync' in a new terminal."
    }
    '2' { # Full Suite
        Write-Log -Message "`nStarting installation for: Full Suite..." -Color Yellow
        Ensure-Chocolatey; Ensure-Prerequisite -CommandName "git" -PackageName "git"; Ensure-Prerequisite -CommandName "npm" -PackageName "nodejs-lts"
        Write-Log -Message "`n----- Checking for Visual Studio Code..." -Color Yellow
        if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
             $choice = Read-Host "INFO: VS Code is required. Install it now? (Y/N)"
            if ($choice -eq 'Y' -or $choice -eq 'y') { Ensure-Prerequisite -CommandName "code" -PackageName "vscode" } 
            else { Show-FinalMessageAndPause -Message "ABORTED: VS Code is required for the Full Suite." -Color Red; exit }
        } else { Write-Log -Message "SUCCESS: Visual Studio Code is already installed." -Color Green }
        
        if ((Handle-CliInstallation) -eq "INSTALL") {
             Write-Log -Message "`n----- Installing the GitSync CLI Tool..." -Color Yellow
             try {
                $cliUrl = "https://github.com/LQtaishat/gitsync-installer/releases/download/v$($global:latestVersion)/git-sync-tool-$($global:latestVersion).tgz"
                Write-Log -Message "INFO: Installing CLI tool from $cliUrl"
                powershell -Command "npm install -g $cliUrl"
            } catch { Show-FinalMessageAndPause -Message "FATAL: Failed to install the GitSync CLI tool.`nError Details: $($_.Exception.Message)" -Color Red; exit }
        } else { Write-Log -Message "Skipping CLI tool installation as requested by user." -Color Yellow }

        if ((Handle-ExtensionInstallation) -eq "INSTALL") {
            Write-Log -Message "`n----- Installing the GitSync VS Code Extension..." -Color Yellow
            try {
                $vsixUrl = "https://github.com/LQtaishat/gitsync-installer/releases/download/v$($global:latestVersion)/gitsync-vscode-$($global:latestVersion).vsix"
                $vsixPath = "$env:TEMP\gitsync-vscode.vsix"
                $userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36"
                Write-Log -Message "INFO: Downloading extension from $vsixUrl..."
                Invoke-WebRequest -Uri $vsixUrl -OutFile $vsixPath -UserAgent $userAgent -ErrorAction Stop
                Write-Log -Message "INFO: Installing VSIX package into VS Code..."
                code --install-extension $vsixPath --force
                Remove-Item $vsixPath
            } catch { Show-FinalMessageAndPause -Message "FATAL: Could not download or install the VS Code extension.`nError Details: $($_.Exception.Message)" -Color Red; exit }
        } else { Write-Log -Message "Skipping VS Code Extension installation as requested by user." -Color Yellow }
        Show-FinalMessageAndPause -Message "Process Complete! Please restart VS Code to activate the extension."
    }
    '3' { # Exit
        Show-FinalMessageAndPause -Message "Exiting installer. No changes were made to your system."
    }
}