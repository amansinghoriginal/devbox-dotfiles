# Dev Box Dotfiles

Automated Microsoft Dev Box configuration for Windows 11 + WSL Ubuntu.

## What's included

**Windows:** VS Code, Windows Terminal (default), Docker Desktop (always-on), PowerToys, dark mode, file extensions visible, search/widgets hidden, bloatware removed, clean taskbar (Edge + Terminal + Explorer), Edge first-run skipped, desktop shortcut cleanup.

**WSL Ubuntu:** zsh + oh-my-zsh (robbyrussell), Node.js (LTS), Rust, .NET 9, Python 3.12, Go, Claude Code, GitHub Copilot CLI, Dev Containers CLI, fzf, ripgrep, fd, bat, jq, htop, tmux, ShellCheck, PostgreSQL/MySQL clients, aspell/pyspelling, git config with Windows credential manager bridge.

## Create a Dev Box

1. Go to [devbox.microsoft.com](https://devbox.microsoft.com)
2. Click **New dev box**, pick your pool/size
3. Click **"Add customizations from file"**
4. Upload [`devbox.yaml`](devbox.yaml) from this repo
5. Create the dev box and wait for provisioning

The YAML file installs apps via WinGet, clones this repo to `C:\devbox-dotfiles`, then runs `install.ps1` and `wsl-setup.sh` automatically.

## After first login

```bash
# In WSL Ubuntu terminal
gh auth login        # browser flow, ~30 seconds
claude               # first-run Anthropic login
```

## Verify setup

**Windows** (PowerShell):
```powershell
C:\devbox-dotfiles\verify.ps1
```

**WSL Ubuntu**:
```bash
bash /mnt/c/devbox-dotfiles/verify.sh
```

Both scripts report color-coded pass/fail results for every check.
