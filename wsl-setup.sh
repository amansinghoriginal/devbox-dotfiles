#!/bin/bash
###############################################################################
# WSL Ubuntu Setup Script
# Called from Windows: wsl -d Ubuntu -- bash /mnt/c/devbox-dotfiles/wsl-setup.sh
###############################################################################
set -e

echo "=== Installing system packages ==="
sudo apt-get update && sudo apt-get install -y \
    curl git unzip wget \
    build-essential pkg-config libssl-dev \
    zsh \
    jq ripgrep fd-find bat htop tmux \
    fontconfig

# Ubuntu uses different binary names for fd and bat
mkdir -p ~/.local/bin
ln -sf "$(which fdfind)" ~/.local/bin/fd 2>/dev/null || true
ln -sf "$(which batcat)" ~/.local/bin/bat 2>/dev/null || true

echo "=== Installing Zsh + Oh-My-Zsh ==="
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Powerlevel10k theme
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

# Plugins
git clone https://github.com/zsh-users/zsh-autosuggestions \
    "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
git clone https://github.com/zsh-users/zsh-syntax-highlighting \
    "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"

# Configure .zshrc
sed -i 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' ~/.zshrc
sed -i 's|^plugins=(.*)|plugins=(git docker rust python dotnet fzf zsh-autosuggestions zsh-syntax-highlighting)|' ~/.zshrc

# Ensure ~/.local/bin is in PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc

echo "=== Installing fzf ==="
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --all --no-bash --no-fish

echo "=== Installing Node.js (LTS via nvm) ==="
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
source "$NVM_DIR/nvm.sh"
nvm install --lts

echo "=== Installing Claude Code ==="
npm install -g @anthropic-ai/claude-code

echo "=== Installing GitHub CLI + Copilot extension ==="
(type -p wget >/dev/null || sudo apt-get install -y wget) \
    && sudo mkdir -p -m 755 /etc/apt/keyrings \
    && out=$(mktemp) \
    && wget -nv -O"$out" https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    && cat "$out" | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && sudo apt-get update \
    && sudo apt-get install -y gh
gh extension install github/gh-copilot

echo "=== Installing Rust (via rustup) ==="
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
# shellcheck source=/dev/null
source "$HOME/.cargo/env"
echo 'source "$HOME/.cargo/env"' >> ~/.zshrc

echo "=== Installing .NET 9 ==="
curl -sSL https://dot.net/v1/dotnet-install.sh | bash -s -- --channel 9.0
echo 'export DOTNET_ROOT="$HOME/.dotnet"' >> ~/.zshrc
echo 'export PATH="$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools"' >> ~/.zshrc

echo "=== Installing Python (via pyenv) ==="
curl https://pyenv.run | bash
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
echo 'eval "$(pyenv init -)"' >> ~/.zshrc
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
pyenv install 3.12
pyenv global 3.12

echo "=== Setting zsh as default shell ==="
sudo chsh -s "$(which zsh)" "$USER"

echo "============================================"
echo "WSL setup complete!"
echo "Restart your terminal for zsh to take effect."
echo "============================================"
