# =================================================================
# GitSync Tool Suite Installer - Final Version
# =================================================================
# - Presents a menu for CLI-only or Full Suite installation.
# - Installs dependencies based on user's choice.
# - Provides a professional, interactive setup experience.
# - Includes robust error handling with try/catch blocks.
# =================================================================

# --- Reusable Functions for Checking and Installing ---

# Function to ensure Chocolatey package manager is installed.
function Ensure-Chocolatey {
    Write-Host "`n----- Checking for Chocolatey..." -ForegroundColor Yellow
    try {
        if (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-Host "SUCCESS: Chocolatey is already installed." -ForegroundColor Green
            return
        }
        
        Write-Host "INFO: Chocolatey (a package manager) is required to automate setup."
        Write-Host "      Installing it now. This may require administrator permission..."
        Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    } catch {
        Write-Host "FATAL: Failed to install Chocolatey. Please try running the script in an Administrator PowerShell." -ForegroundColor Red
        Write-Host "Error Details: $($_.Exception.Message)"
        exit
    }
}

# Function to check for and install a single prerequisite using Chocolatey.
function Ensure-Prerequisite {
    param(
        [string]$CommandName,
        [string]$PackageName
    )
    Write-Host "`n----- Checking for $CommandName..." -ForegroundColor Yellow
    try {
        if (Get-Command $CommandName -ErrorAction SilentlyContinue) {
            Write-Host "SUCCESS: $CommandName is already installed." -ForegroundColor Green
        } else {
            Write-Host "INFO: $CommandName is not found. Installing '$PackageName' via Chocolatey..."
            choco install $PackageName -y
            if (-not (Get-Command $CommandName -ErrorAction SilentlyContinue)) {
                throw "Installation of $CommandName appears to have failed."
            }
            Write-Host "SUCCESS: $CommandName has been installed." -ForegroundColor Green
        }
    } catch {
        Write-Host "FATAL: Failed to install '$PackageName'. Please check the Chocolatey logs or try installing it manually." -ForegroundColor Red
        Write-Host "Error Details: $($_.Exception.Message)"
        exit
    }
}


# --- Main Script Body ---

# Loop to display the menu until a valid choice is made.
while ($true) {
    Clear-Host
    Write-Host "=================================================" -ForegroundColor Green
    Write-Host " Welcome to the GitSync Tool Suite Installer" -ForegroundColor Green
    Write-Host "================================================="
    Write-Host "`nThis script will set up the GitSync tools on your system.`n"
    Write-Host "Please choose an option:"
    Write-Host "  [1] Install CLI Tool Only" -ForegroundColor Cyan
    Write-Host "      For using 'gitsync' in any terminal. Best for non-VS Code users."
    Write-Host "`n  [2] Install Full Suite (CLI Tool + VS Code Extension)" -ForegroundColor Cyan
    Write-Host "      The complete, recommended experience for VS Code users."
    Write-Host "`n  [3] Exit" -ForegroundColor Cyan
    Write-Host "      No changes will be made to your system.`n"
    
    $installChoice = Read-Host "Enter your choice (1, 2, or 3) and press Enter"

    if ($installChoice -in '1', '2', '3') {
        break
    } else {
        Write-Host "`nINVALID INPUT: Please enter only 1, 2, or 3." -ForegroundColor Red
        Read-Host "Press Enter to try again..."
    }
}

# Use a switch statement to act on the validated choice.
switch ($installChoice) {
    '1' { # --- Case 1: User chose "CLI Tool Only" ---
        Write-Host "`nStarting installation for: CLI Tool Only..." -ForegroundColor Yellow
        Ensure-Chocolatey
        Ensure-Prerequisite -CommandName "git" -PackageName "git"
        Ensure-Prerequisite -CommandName "npm" -PackageName "nodejs-lts"
        
        Write-Host "`n----- Installing the GitSync CLI Tool..." -ForegroundColor Yellow
        try {
            $cliUrl = "https://github.com/LQtaishat/gitsync-installer/releases/download/v1.0.0/git-sync-tool-1.0.0.tgz"
            Write-Host "INFO: Downloading CLI tool from GitHub..."
            powershell -Command "npm install -g $cliUrl"
        } catch {
            Write-Host "FATAL: Failed to install the GitSync CLI tool from the URL." -ForegroundColor Red
            Write-Host "Error Details: $($_.Exception.Message)"
            exit
        }

        Write-Host "`n======================================================" -ForegroundColor Green
        Write-Host " Installation Complete!" -ForegroundColor Green
        Write-Host " You can now open a NEW terminal and use the 'gitsync' command." -ForegroundColor Green
        Write-Host "======================================================" -ForegroundColor Green
    }

    '2' { # --- Case 2: User chose "Full Suite" ---
        Write-Host "`nStarting installation for: Full Suite..." -ForegroundColor Yellow
        Ensure-Chocolatey
        Ensure-Prerequisite -CommandName "git" -PackageName "git"
        Ensure-Prerequisite -CommandName "npm" -PackageName "nodejs-lts"

        # Check specifically for VS Code
        Write-Host "`n----- Checking for Visual Studio Code..." -ForegroundColor Yellow
        if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
             $choice = Read-Host "INFO: VS Code is required for the Full Suite but was not found. Install it now? (Y/N)"
            if ($choice -eq 'Y' -or $choice -eq 'y') {
                Ensure-Prerequisite -CommandName "code" -PackageName "vscode"
            } else {
                Write-Host "ABORTED: Installation cancelled by user. VS Code is required for the Full Suite." -ForegroundColor Red
                exit
            }
        } else {
             Write-Host "SUCCESS: Visual Studio Code is already installed." -ForegroundColor Green
        }

        Write-Host "`n----- Installing the GitSync CLI Tool..." -ForegroundColor Yellow
        try {
            $cliUrl = "https://github.com/LQtaishat/gitsync-installer/releases/download/v1.0.0/git-sync-tool-1.0.0.tgz"
            Write-Host "INFO: Downloading CLI tool from GitHub..."
            powershell -Command "npm install -g $cliUrl"
        } catch {
            Write-Host "FATAL: Failed to install the GitSync CLI tool." -ForegroundColor Red
            Write-Host "Error Details: $($_.Exception.Message)"
            exit
        }

        Write-Host "`n----- Installing the GitSync VS Code Extension..." -ForegroundColor Yellow
        try {
            $vsixUrl = "https://github.com/LQtaishat/gitsync-installer/releases/download/v1.0.0/gitsync-vscode-1.0.0.vsix"
            $vsixPath = "$env:TEMP\gitsync-vscode.vsix"
            Write-Host "INFO: Downloading extension from $vsixUrl..."
            Invoke-WebRequest -Uri $vsixUrl -OutFile $vsixPath -ErrorAction Stop
            Write-Host "INFO: Installing VSIX package into VS Code..."
            code --install-extension $vsixPath --force
            Remove-Item $vsixPath
        } catch {
            Write-Host "FATAL: Could not download or install the VS Code extension." -ForegroundColor Red
            Write-Host "Error Details: $($_.Exception.Message)"
            exit
        }

        Write-Host "`n======================================================" -ForegroundColor Green
        Write-Host " Installation Complete!" -ForegroundColor Green
        Write-Host " Please restart any open VS Code windows to activate the extension." -ForegroundColor Green
        Write-Host "======================================================" -ForegroundColor Green
    }
    
    '3' { # --- Case 3: User chose "Exit" ---
        Write-Host "`nExiting installer. No changes were made." -ForegroundColor Cyan
    }
}