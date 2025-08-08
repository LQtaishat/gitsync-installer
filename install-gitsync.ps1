# =================================================================
# GitSync Tool Suite Installer - Production Grade v2
# =================================================================
# - Sets modern security protocol for reliable downloads.
# - Ensures installer pauses on fatal errors to allow user to read logs.
# =================================================================

# --- Step 0: Set Security Protocol for Robust Downloads ---
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

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
Write-Log -Message "GitSync Installer log started." -Color Green


# --- Reusable Functions ---
function Show-FinalMessageAndPause {
    param([string]$Message, [string]$Color = "Green")
    $finalMessage = "`n======================================================`n $Message`n======================================================`n"
    Write-Log -Message $finalMessage -Color $Color
    Read-Host "Press Enter to exit..."
}

function Ensure-Chocolatey {
    Write-Log -Message "`n----- Checking for Chocolatey..." -Color Yellow
    try {
        if (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-Log -Message "SUCCESS: Chocolatey is already installed." -Color Green; return
        }
        Write-Log -Message "INFO: Chocolatey (a package manager) is required. Installing now..."
        Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    } catch {
        $errorMessage = "FATAL: Failed to install Chocolatey. Please try running the script in an Administrator PowerShell.`nError Details: $($_.Exception.Message)"
        Show-FinalMessageAndPause -Message $errorMessage -Color Red
        exit
    }
}

function Ensure-Prerequisite {
    param([string]$CommandName, [string]$PackageName)
    Write-Log -Message "`n----- Checking for $CommandName..." -Color Yellow
    try {
        if (Get-Command $CommandName -ErrorAction SilentlyContinue) {
            Write-Log -Message "SUCCESS: $CommandName is already installed." -Color Green
        } else {
            Write-Log -Message "INFO: $CommandName is not found. Installing '$PackageName' via Chocolatey..."
            choco install $PackageName -y | Out-Null
            if (-not (Get-Command $CommandName -ErrorAction SilentlyContinue)) { throw "Installation of $CommandName appears to have failed." }
            Write-Log -Message "SUCCESS: $CommandName has been installed." -Color Green
        }
    } catch {
        $errorMessage = "FATAL: Failed to install '$PackageName'. Please check the Chocolatey logs or try installing it manually.`nError Details: $($_.Exception.Message)"
        Show-FinalMessageAndPause -Message $errorMessage -Color Red
        exit
    }
}

# --- Main Script Body ---
# (Menu logic remains the same)
while ($true) {
    Clear-Host
    Write-Host "=================================================" -ForegroundColor Green
    Write-Host " Welcome to the GitSync Tool Suite Installer" -ForegroundColor Green
    Write-Host "================================================="
    Write-Host "`nThis script will set up the GitSync tools on your system.`n"
    Write-Host "A detailed log will be saved to your Desktop: gitsync-installer-log.txt`n" -ForegroundColor Gray
    Write-Host "Please choose an option:"
    Write-Host "  [1] Install CLI Tool Only" -ForegroundColor Cyan
    Write-Host "`n  [2] Install Full Suite (CLI Tool + VS Code Extension)" -ForegroundColor Cyan
    Write-Host "`n  [3] Exit" -ForegroundColor Cyan
    $installChoice = Read-Host "`nEnter your choice (1, 2, or 3) and press Enter"
    if ($installChoice -in '1', '2', '3') { break } 
    else { Read-Host "`nINVALID INPUT: Please enter only 1, 2, or 3. Press Enter to try again..." }
}

switch ($installChoice) {
    '1' { # CLI Tool Only
        Write-Log -Message "`nStarting installation for: CLI Tool Only..." -Color Yellow
        Ensure-Chocolatey; Ensure-Prerequisite -CommandName "git" -PackageName "git"; Ensure-Prerequisite -CommandName "npm" -PackageName "nodejs-lts"
        Write-Log -Message "`n----- Installing the GitSync CLI Tool..." -Color Yellow
        try {
            $cliUrl = "https://github.com/LQtaishat/gitsync-installer/releases/download/v1.0.0/git-sync-tool-1.0.0.tgz"
            Write-Log -Message "INFO: Installing CLI tool from $cliUrl"
            powershell -Command "npm install -g $cliUrl"
        } catch {
            $errorMessage = "FATAL: Failed to install the GitSync CLI tool.`nError Details: $($_.Exception.Message)"
            Show-FinalMessageAndPause -Message $errorMessage -Color Red
            exit
        }
        Show-FinalMessageAndPause -Message "Installation Complete! You can now use 'gitsync' in a new terminal."
    }
    '2' { # Full Suite
        Write-Log -Message "`nStarting installation for: Full Suite..." -Color Yellow
        Ensure-Chocolatey; Ensure-Prerequisite -CommandName "git" -PackageName "git"; Ensure-Prerequisite -CommandName "npm" -PackageName "nodejs-lts"
        Write-Log -Message "`n----- Checking for Visual Studio Code..." -Color Yellow
        if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
             $choice = Read-Host "INFO: VS Code is required for the Full Suite but was not found. Install it now? (Y/N)"
            if ($choice -eq 'Y' -or $choice -eq 'y') { Ensure-Prerequisite -CommandName "code" -PackageName "vscode" } 
            else { Show-FinalMessageAndPause -Message "ABORTED: Installation cancelled by user." -Color Red; exit }
        } else { Write-Log -Message "SUCCESS: Visual Studio Code is already installed." -Color Green }
        Write-Log -Message "`n----- Installing the GitSync CLI Tool..." -Color Yellow
        try {
            $cliUrl = "https://github.com/LQtaishat/gitsync-installer/releases/download/v1.0.0/git-sync-tool-1.0.0.tgz"
            Write-Log -Message "INFO: Installing CLI tool from $cliUrl"
            powershell -Command "npm install -g $cliUrl"
        } catch {
            $errorMessage = "FATAL: Failed to install the GitSync CLI tool.`nError Details: $($_.Exception.Message)"
            Show-FinalMessageAndPause -Message $errorMessage -Color Red
            exit
        }
        Write-Log -Message "`n----- Installing the GitSync VS Code Extension..." -Color Yellow
        try {
            $vsixUrl = "https://github.com/LQtaishat/gitsync-installer/releases/download/v1.0.0/gitsync-vscode-1.0.0.vsix"
            $vsixPath = "$env:TEMP\gitsync-vscode.vsix"
            Write-Log -Message "INFO: Downloading extension from $vsixUrl..."
            Invoke-WebRequest -Uri $vsixUrl -OutFile $vsixPath -ErrorAction Stop
            Write-Log -Message "INFO: Installing VSIX package into VS Code..."
            code --install-extension $vsixPath --force
            Remove-Item $vsixPath
        } catch {
            $errorMessage = "FATAL: Could not download or install the VS Code extension.`nError Details: $($_.Exception.Message)"
            Show-FinalMessageAndPause -Message $errorMessage -Color Red
            exit
        }
        Show-FinalMessageAndPause -Message "Installation Complete! Please restart VS Code to activate the extension."
    }
    '3' { # Exit
        Show-FinalMessageAndPause -Message "Exiting installer. No changes were made to your system."
    }
}