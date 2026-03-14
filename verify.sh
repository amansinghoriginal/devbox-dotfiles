#!/bin/bash
###############################################################################
# Dev Box WSL Ubuntu Verification Script
# Run inside WSL Ubuntu to verify setup
###############################################################################

PASS=0
FAIL=0

check() {
    local name="$1"
    shift
    if "$@" > /dev/null 2>&1; then
        echo -e "  \033[32mPASS\033[0m  $name"
        ((PASS++))
    else
        echo -e "  \033[31mFAIL\033[0m  $name"
        ((FAIL++))
    fi
}

check_env() {
    local name="$1"
    local var="$2"
    local val
    val=$(zsh -ic "echo \$$var" 2>/dev/null)
    if [ -n "$val" ]; then
        echo -e "  \033[32mPASS\033[0m  $name ($val)"
        ((PASS++))
    else
        echo -e "  \033[31mFAIL\033[0m  $name"
        ((FAIL++))
    fi
}

echo ""
echo -e "\033[36m=== Dev Box WSL Ubuntu Verification ===\033[0m"

# --- Shell ---
echo ""
echo "--- Shell ---"
check "Default shell is zsh" test "$(basename "$SHELL")" = "zsh"
check "Oh-my-zsh installed" test -d "$HOME/.oh-my-zsh"
check "zsh-autosuggestions plugin" test -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
check "zsh-syntax-highlighting plugin" test -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
check "robbyrussell theme set" grep -q 'ZSH_THEME="robbyrussell"' "$HOME/.zshrc"
check "fzf installed" test -d "$HOME/.fzf"

# --- Languages ---
echo ""
echo "--- Languages ---"
check "Node.js (nvm)" test -f "$HOME/.nvm/nvm.sh"

# Source tools so we can check versions
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
[ -s "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$HOME/.dotnet:$HOME/.local/bin:$PATH"
eval "$(pyenv init -)" 2>/dev/null

check "Node.js available" node --version
check "Rust (rustc)" rustc --version
check "Cargo" cargo --version
check ".NET 9" dotnet --version
check "Python (pyenv)" python --version
check "Go" go version

# --- Dev Tools ---
echo ""
echo "--- Dev Tools ---"
check "Claude Code" command -v claude
check "GitHub CLI" gh --version
check "GitHub Copilot CLI" gh copilot --version
check "Dev Containers CLI" devcontainer --version
check "Docker (WSL integration)" docker --version
check "ShellCheck" shellcheck --version
check "ripgrep" rg --version
check "fd" fd --version 2>/dev/null || fdfind --version
check "bat" bat --version 2>/dev/null || batcat --version
check "jq" jq --version
check "fzf" fzf --version
check "htop" command -v htop
check "tmux" tmux -V

# --- Database Clients ---
echo ""
echo "--- Database Clients ---"
check "PostgreSQL client" psql --version
check "MySQL client" mysql --version

# --- Spell Checking ---
echo ""
echo "--- Spell Checking ---"
check "aspell" aspell --version
check "pyspelling" command -v pyspelling

# --- Git Config ---
echo ""
echo "--- Git Config ---"
check "git user.name set" test -n "$(git config --global user.name)"
check "git user.email set" test -n "$(git config --global user.email)"
check "git credential helper set" test -n "$(git config --global credential.helper)"

echo ""
GIT_NAME=$(git config --global user.name)
GIT_EMAIL=$(git config --global user.email)
echo "       Name:  $GIT_NAME"
echo "       Email: $GIT_EMAIL"

# --- WSL-Windows Integration ---
echo ""
echo "--- WSL-Windows Integration ---"
check_env "BROWSER set" "BROWSER"
check_env "GITHUB_TOKEN bridge" "GITHUB_TOKEN"

# --- Summary ---
echo ""
TOTAL=$((PASS + FAIL))
if [ "$FAIL" -eq 0 ]; then
    COLOR="\033[32m"
else
    COLOR="\033[31m"
fi
echo -e "\033[36m==========================================\033[0m"
echo -e "  ${COLOR}Results: $PASS passed, $FAIL failed (out of $TOTAL)\033[0m"
echo -e "\033[36m==========================================\033[0m"
echo ""
