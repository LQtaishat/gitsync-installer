# =================================================================
# GitSync Tool Suite Installer - Production Grade
# =================================================================
# - Comprehensive logging to a file on the user's Desktop.
# - Robust menu with input validation and an exit option.
# - Checks for dependencies before installing.
# - Interactive prompts for required software.
# - Graceful exit with a summary message and pause.
# =================================================================

# --- Step 1: Setup Logging ---
$logFile = "$([Environment]::GetFolderPath('Desktop'))\gitsync-installer-log.txt"
Function Write-Log {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    # Create the timestamp
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    
    # Write to the console with color
    Write-Host $logMessage -ForegroundColor $Color
    
    # Append to the log file
    Add-Content -Path $logFile -Value $logMessage
}

# Clear previous log file if it exists
if (Test-Path $logFile) {
    Remove-Item $logFile
}
Write-Log -Message "GitSync Installer log started." -Color Green


# --- Reusable Functions ---

function Ensure-Chocolatey {
    Write-Log -Message "`n----- Checking for Chocolatey..." -Color Yellow
    try {
        if (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-Log -Message "SUCCESS: Chocolatey is already installed." -Color Green
            return
        }
        
        Write-Log -Message "INFO: Chocolatey (a package manager) is required to automate setup. Installing now..."
        Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    } catch {
        Write-Log -Message "FATAL: Failed to install Chocolatey. Please try running the script in an Administrator PowerShell." -Color Red
        Write-Log -Message "Error Details: $($_.Exception.Message)"
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
            choco install $PackageName -y | Out-Null # Pipe output to null to keep console clean
            if (-not (Get-Command $CommandName -ErrorAction SilentlyContinue)) {
                throw "Installation of $CommandName appears to have failed."
            }
            Write-Log -Message "SUCCESS: $CommandName has been installed." -Color Green
        }
    } catch {
        Write-Log -Message "FATAL: Failed to install '$PackageName'. Please check the Chocolatey logs or try installing it manually." -Color Red
        Write-Log -Message "Error Details: $($_.Exception.Message)"
        exit
    }
}

function Show-FinalMessageAndPause {
    param([string]$Message)
    $finalMessage = "`n======================================================`n $Message`n======================================================`n"
    Write-Log -Message $finalMessage -Color Green
    Read-Host "Press Enter to exit..."
}


# --- Main Script Body ---

# Loop to display the menu
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
    else {
        Write-Host "`nINVALID INPUT: Please enter only 1, 2, or 3." -ForegroundColor Red
        Read-Host "Press Enter to try again..."
    }
}

# Main logic based on user choice
switch ($installChoice) {
    '1' { # CLI Tool Only
        Write-Log -Message "`nStarting installation for: CLI Tool Only..." -Color Yellow
        Ensure-Chocolatey
        Ensure-Prerequisite -CommandName "git" -PackageName "git"
        Ensure-Prerequisite -CommandName "npm" -PackageName "nodejs-lts"
        
        Write-Log -Message "`n----- Installing the GitSync CLI Tool..." -Color Yellow
        try {
            $cliUrl = "https://github.com/LQtaishat/gitsync-installer/releases/download/v1.0.0/git-sync-tool-1.0.0.tgz"
            Write-Log -Message "INFO: Installing CLI tool from $cliUrl"
            powershell -Command "npm install -g $cliUrl"
        } catch {
            Write-Log -Message "FATAL: Failed to install the GitSync CLI tool." -Color Red
            Write-Log -Message "Error Details: $($_.Exception.Message)"
            exit
        }
        Show-FinalMessageAndPause -Message "Installation Complete! You can now use 'gitsync' in a new terminal."
    }

    '2' { # Full Suite
        Write-Log -Message "`nStarting installation for: Full Suite..." -Color Yellow
        Ensure-Chocolatey
        Ensure-Prerequisite -CommandName "git" -PackageName "git"
        Ensure-Prerequisite -CommandName "npm" -PackageName "nodejs-lts"

        Write-Log -Message "`n----- Checking for Visual Studio Code..." -Color Yellow
        if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
             $choice = Read-Host "INFO: VS Code is required for the Full Suite but was not found. Install it now? (Y/N)"
            if ($choice -eq 'Y' -or $choice -eq 'y') {
                Ensure-Prerequisite -CommandName "code" -PackageName "vscode"
            } else {
                Write-Log -Message "ABORTED: Installation cancelled by user." -Color Red
                exit
            }
        } else {
             Write-Log -Message "SUCCESS: Visual Studio Code is already installed." -Color Green
        }

        Write-Log -Message "`n----- Installing the GitSync CLI Tool..." -Color Yellow
        try {
            $cliUrl = "https://github.com/LQtaishat/gitsync-installer/releases/download/v1.0.0/git-sync-tool-1.0.0.tgz"
            Write-Log -Message "INFO: Installing CLI tool from $cliUrl"
            powershell -Command "npm install -g $cliUrl"
        } catch {
            Write-Log -Message "FATAL: Failed to install the GitSync CLI tool." -Color Red
            Write-Log -Message "Error Details: $($_.Exception.Message)"
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
            Write-Log -Message "FATAL: Could not download or install the VS Code extension." -Color Red
            Write-Log -Message "Error Details: $($_.Exception.Message)"
            exit
        }
        Show-FinalMessageAndPause -Message "Installation Complete! Please restart VS Code to activate the extension."
    }
    
    '3' { # Exit
        Show-FinalMessageAndPause -Message "Exiting installer. No changes were made to your system."
    }
}