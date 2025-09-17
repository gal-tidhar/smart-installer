# Smart Authenticated Installer

Generic installer that handles GitHub CLI setup and private repository access.

## Features

🔧 **Auto-installs GitHub CLI** if missing  
🔐 **Handles authentication** via secure web browser flow  
🛡️ **Verifies repository access** before proceeding  
🚀 **Zero configuration** required  
🎯 **Works with any private repo** - no hardcoded values  

## Usage

```bash
# Basic usage
bash <(curl -sSL https://raw.githubusercontent.com/gal-tidhar/smart-installer/main/install.sh) OWNER/REPOSITORY

# With installer arguments
bash <(curl -sSL https://raw.githubusercontent.com/gal-tidhar/smart-installer/main/install.sh) OWNER/REPOSITORY --dry-run --email user@company.com
```

## What It Does

1. **Installs GitHub CLI** (if not already installed)
2. **Authenticates with GitHub** (one-time setup via browser)
3. **Clones the specified private repository** 
4. **Runs the main installer** (`main.py`, `install.py`, or `setup.py`)
5. **Passes through all arguments** to the target installer
6. **Cleans up temporary files** when done

## Security

- ✅ **No secrets stored** in this repository
- ✅ **No hardcoded organization details**  
- ✅ **Uses GitHub's secure authentication flow**
- ✅ **Temporary file cleanup**
- ✅ **Minimal required permissions** (repo, read:org)

## Requirements

- **macOS**: Homebrew (for GitHub CLI installation)
- **Linux**: apt/yum package manager
- **Python 3.9+** (for running the target installer)

Perfect for:
- 🏢 **Company onboarding scripts** in private repositories
- 🔒 **Secure installer distribution** 
- 🎯 **One-command setup** workflows
- 📦 **Private tooling deployment**