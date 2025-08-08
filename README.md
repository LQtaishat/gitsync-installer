# GitSync Tool Suite

![GitSync Logo](https://raw.githubusercontent.com/LQtaishat/gitsync-installer/main/assets/logo.png)

**A simple, powerful workflow for semantic versioning and structured Git history.**

![Version](https://img.shields.io/badge/Version-v1.0.0-blue)
![License](https://img.shields.io/badge/License-MIT-green)
![Maintained](https://img.shields.io/badge/Maintained-Yes-brightgreen)

The GitSync Tool Suite is designed for educators, students, and developers who want to bring clarity and structure to their Git workflow. It automates versioning and syncing based on a clear "Testing" vs. "Stable" cycle, abstracting away complex branching strategies into simple, memorable commands.

---

## ✨ Features

- **Semantic Workflow**  
  Simple commands (`test`, `stable`, `rollback`) that have real meaning.

- **Automated Versioning**  
  Automatically create and increment semantic version tags (e.g., `v1.2.1`).

- **CLI First**  
  A powerful, universal command-line tool that works in any terminal on any OS.

- **Full VS Code Integration**  
  A companion extension that provides a UI and runs commands directly in the integrated terminal.

- **Safety First**  
  Built-in checks to prevent accidental pushes to diverged branches.

- **Automated Installer**  
  A one-line command to set up the entire suite, including all dependencies.

---

## 🚀 Quick Start: One-Line Installation (Windows)

Open a PowerShell terminal and run the following command. The installer will guide you through the process, check for dependencies like Git and Node.js, and install them if they are missing:

    Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/LQtaishat/gitsync-installer/main/install-gitsync.ps1'))

---

## 🛠️ Usage

### Using the VS Code Extension (Recommended)

Once installed, open the Command Palette (`Ctrl+Shift+P`), type `GitSync`, and choose your desired action. All commands run in an interactive terminal.

![VS Code Demo](https://raw.githubusercontent.com/LQtaishat/gitsync-installer/main/assets/vscode-demo.gif)

### Using the CLI Tool

From any project's folder in any terminal:

- Save your current work-in-progress:

      gitsync test

- Finalize a milestone and create a new stable version:

      gitsync stable

- Revert to a previous stable version in a new branch:

      gitsync rollback

![CLI Demo](https://raw.githubusercontent.com/LQtaishat/gitsync-installer/main/assets/cli-demo.gif)

---

## 🤝 Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are greatly appreciated.

Please see our `CONTRIBUTING.md` file for details on our code of conduct and the process for submitting pull requests.

---

## 🐛 Reporting Bugs

See the [issues page](https://github.com/LQtaishat/gitsync-installer/issues) to report a bug. Please use the "Bug Report" template.

---

## 📝 License

This project is licensed under the MIT License – see the `LICENSE` file for details.
