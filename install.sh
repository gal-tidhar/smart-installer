#!/bin/bash
#
# Smart Authenticated Installer
# Generic installer that handles GitHub CLI setup and private repo access
# Contains NO secrets, NO organization details, NO hardcoded values
#
# Usage: bash <(curl -sSL https://raw.githubusercontent.com/gal-tidhar/smart-installer/main/install.sh) OWNER/REPO [args...]
# Example: bash <(curl -sSL https://raw.githubusercontent.com/gal-tidhar/smart-installer/main/install.sh) sedric-ai-labs/developer-onboarding --dry-run
# Default branch: main (can be overridden with BRANCH environment variable)
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}❌ $1${NC}" >&2
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Check if GitHub CLI is installed, install if missing
install_github_cli() {
    if command -v gh &> /dev/null; then
        log "GitHub CLI already installed: $(gh --version | head -1)"
        return 0
    fi
    
    log "Installing GitHub CLI..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew &> /dev/null; then
            brew install gh
        else
            error "Homebrew required but not found"
            echo "Please install Homebrew first: https://brew.sh"
            exit 1
        fi
    elif command -v apt &> /dev/null; then
        log "Installing via apt..."
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt update && sudo apt install gh -y
    elif command -v yum &> /dev/null; then
        log "Installing via yum..."
        sudo yum install -y gh
    else
        error "Unsupported system. Please install GitHub CLI manually: https://cli.github.com"
        exit 1
    fi
    
    success "GitHub CLI installed successfully"
}

# Authenticate with GitHub if not already authenticated
authenticate_github() {
    log "Checking GitHub authentication status..."
    
    if gh auth status &> /dev/null; then
        success "Already authenticated with GitHub"
        return 0
    fi
    
    local max_attempts=3
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        log "GitHub authentication required (attempt $attempt/$max_attempts)"
        echo ""
        echo "🔐 This installer needs to authenticate with GitHub to access private repositories."
        echo "   You'll be redirected to GitHub in your browser for secure authentication."
        echo ""
        
        if gh auth login --web --scopes repo,read:org; then
            success "GitHub authentication completed"
            return 0
        fi
        
        warn "GitHub authentication failed (attempt $attempt/$max_attempts)"
        
        if [[ $attempt -lt $max_attempts ]]; then
            echo ""
            echo "Common issues and solutions:"
            echo "• Make sure your browser opened and you completed the authentication"
            echo "• Check your internet connection"
            echo "• Try closing and reopening your browser"
            echo "• Make sure you're logged into the correct GitHub account"
            echo ""
            echo "Press Enter to try again or Ctrl+C to cancel..."
            read -r
        fi
        
        ((attempt++))
    done
    
    error "GitHub authentication failed after $max_attempts attempts"
    echo ""
    echo "💡 Troubleshooting tips:"
    echo "• Run 'gh auth login' manually first, then re-run this installer"
    echo "• Check if your GitHub account has access to the target repository"
    echo "• Ensure you're using the correct GitHub organization account"
    echo ""
    exit 1
}

# Verify repository access
verify_repo_access() {
    local repo="$1"
    
    log "Verifying access to repository: $repo"
    
    if ! gh repo view "$repo" --json name &> /dev/null; then
        error "Cannot access repository: $repo"
        echo ""
        echo "Possible reasons:"
        echo "• Repository doesn't exist"
        echo "• You don't have access to this private repository"
        echo "• You're not a member of the required organization"
        echo ""
        exit 1
    fi
    
    success "Repository access verified"
}

# Check Python availability
check_python() {
    if ! command -v python3 &> /dev/null; then
        error "Python 3 is required but not found"
        echo "Please install Python 3.9+ and try again"
        exit 1
    fi
    
    local python_version
    python_version=$(python3 --version 2>&1 | cut -d' ' -f2)
    log "Found Python $python_version"
}

# Main installation function
main() {
    echo ""
    echo "🚀 Smart Authenticated Installer"
    echo "================================="
    echo ""
    
    # Parse arguments
    local repo="${1:-}"
    local installer_path="${2:-}"
    
    if [[ -z "$repo" ]]; then
        error "Repository not specified"
        echo ""
        echo "Usage: $0 OWNER/REPOSITORY [INSTALLER_PATH] [installer-options...]"
        echo ""
        echo "Examples:"
        echo "  $0 myorg/private-installer --dry-run"
        echo "  $0 myorg/dev-setup V2/src/sedric_forge/main.py --email user@company.com"
        echo "  $0 myorg/dev-setup scripts/setup.py --verbose"
        echo ""
        exit 1
    fi
    
    # Shift to pass remaining args to the installer
    shift
    if [[ -n "$installer_path" ]]; then
        shift  # Remove installer_path from args if provided
    fi
    
    log "Target repository: $repo"
    
    # Setup and verification
    install_github_cli
    authenticate_github
    verify_repo_access "$repo"
    check_python
    
    # Clone repository to temporary directory
    local branch="${BRANCH:-main}"
    log "Downloading installer from private repository..."
    log "Using branch: $branch"
    local temp_dir
    temp_dir=$(mktemp -d)
    
    # Cleanup on exit
    trap "rm -rf '$temp_dir'" EXIT
    
    if ! gh repo clone "$repo" "$temp_dir" -- -b "$branch"; then
        error "Failed to clone repository (branch: $branch)"
        exit 1
    fi
    
    # Change to temporary directory and run main installer
    cd "$temp_dir"
    
    success "Repository downloaded successfully"
    
    # Install Python dependencies if requirements.txt exists
    if [[ -f "requirements.txt" ]]; then
        log "Installing Python dependencies..."
        
        # Try different installation methods for Python 3.13+ externally-managed environments
        local install_success=false
        
        # Method 1: Try --user flag first (most common)
        if python3 -m pip install --user -r requirements.txt 2>/dev/null; then
            install_success=true
        # Method 2: Try --break-system-packages for externally-managed environments  
        elif python3 -m pip install --break-system-packages --user -r requirements.txt 2>/dev/null; then
            warn "Used --break-system-packages flag for externally-managed Python environment"
            install_success=true
        # Method 3: Create temporary virtual environment (properly handle activation)
        elif python3 -m venv .temp_venv 2>/dev/null; then
            log "Creating temporary virtual environment for dependencies..."
            # Activate venv and install in same shell context
            if source .temp_venv/bin/activate && pip install -r requirements.txt 2>/dev/null; then
                log "Virtual environment created and dependencies installed"
                install_success=true
                export VIRTUAL_ENV_ACTIVE=true
            else
                # Clean up failed venv
                rm -rf .temp_venv 2>/dev/null
            fi
        fi
        
        if [[ "$install_success" == "false" ]]; then
            error "Failed to install Python dependencies"
            echo ""
            echo "💡 Your system has an externally-managed Python environment."
            echo "   This is common with Python 3.13+ and Homebrew Python installations."
            echo ""
            echo "🔧 Manual solutions (choose one):"
            echo "  Option 1 (Recommended): Use pipx"
            echo "    brew install pipx"
            echo "    # Then re-run this installer"
            echo ""
            echo "  Option 2: Allow system packages (not recommended)"
            echo "    python3 -m pip install --break-system-packages --user pyyaml requests click rich"
            echo "    # Then re-run this installer"
            echo ""
            echo "  Option 3: Use virtual environment"
            echo "    python3 -m venv ~/sedric-installer-venv"
            echo "    source ~/sedric-installer-venv/bin/activate"
            echo "    pip install pyyaml requests click rich"
            echo "    # Then re-run this installer"
            echo ""
            exit 1
        fi
        
        success "Dependencies installed successfully"
    fi
    
    log "Starting main installer with arguments: $*"
    echo ""
    
    # Determine Python command (use venv if we created one)
    local python_cmd="python3"
    if [[ "${VIRTUAL_ENV_ACTIVE:-}" == "true" && -f ".temp_venv/bin/activate" ]]; then
        source .temp_venv/bin/activate
        python_cmd="python"
        log "Using virtual environment for main installer"
    fi
    
    # Run the main installer with all provided arguments
    if [[ -n "$installer_path" ]]; then
        # Use specified installer path
        if [[ -f "$installer_path" ]]; then
            log "Using specified installer: $installer_path"
            $python_cmd "$installer_path" "$@"
        else
            error "Specified installer not found: $installer_path"
            exit 1
        fi
    else
        # Auto-detect installer (default behavior)
        if [[ -f "main.py" ]]; then
            log "Found root installer: main.py"
            $python_cmd main.py "$@"
        elif [[ -f "install.py" ]]; then
            log "Found installer: install.py"
            $python_cmd install.py "$@"
        elif [[ -f "setup.py" ]]; then
            log "Found installer: setup.py"
            $python_cmd setup.py "$@"
        else
            error "No installer script found (looking for main.py, install.py, or setup.py)"
            exit 1
        fi
    fi
}

# Run main function with all arguments
main "$@"