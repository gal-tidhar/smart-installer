# Smart Authenticated Installer

Generic installer that handles GitHub CLI setup and private repository access.

## 🔒 **SECURITY NOTICE: THIS IS A PUBLIC REPOSITORY**

**✅ CONTAINS NO SECRETS OR PROPRIETARY INFORMATION**

This repository is intentionally public and contains:
- ✅ **Zero company secrets** or sensitive information
- ✅ **Zero hardcoded organization details** 
- ✅ **Zero API tokens, URLs, or internal configurations**
- ✅ **100% generic code** that works with any GitHub organization
- ✅ **Repository names passed as arguments** - not embedded in code

**Safe to be public** - acts as a generic "GitHub CLI + private repo cloner" utility.

## Features

🔧 **Auto-installs GitHub CLI** if missing  
🔐 **Handles authentication** via secure web browser flow  
🛡️ **Verifies repository access** before proceeding  
🚀 **Zero configuration** required  
🎯 **Works with any private repo** - no hardcoded values  
📦 **Auto-installs Python dependencies** from requirements.txt  

## Usage

```bash
# Basic usage
bash <(curl -sSL https://raw.githubusercontent.com/gal-tidhar/smart-installer/main/install.sh) OWNER/REPOSITORY

# With installer arguments
bash <(curl -sSL https://raw.githubusercontent.com/gal-tidhar/smart-installer/main/install.sh) OWNER/REPOSITORY --dry-run --email user@company.com

# Real example (replace with your org/repo)
bash <(curl -sSL https://raw.githubusercontent.com/gal-tidhar/smart-installer/main/install.sh) myorg/private-onboarding
```

## What It Does

1. **Installs GitHub CLI** (if not already installed)
2. **Authenticates with GitHub** (one-time setup via browser)
3. **Verifies access** to the specified private repository
4. **Clones the repository** to a temporary directory
5. **Installs Python dependencies** from requirements.txt (if exists)
6. **Runs the main installer** (`main.py`, `install.py`, or `setup.py`)
7. **Passes through all arguments** to the target installer
8. **Cleans up temporary files** when done

## Security & Privacy

- ✅ **No secrets stored** in this repository
- ✅ **No hardcoded organization details** or internal URLs  
- ✅ **Uses GitHub's secure authentication flow** (OAuth via browser)
- ✅ **Temporary file cleanup** - no traces left behind
- ✅ **Minimal required permissions** (repo access, read:org only)
- ✅ **Repository argument required** - nothing hardcoded
- ✅ **Safe to be public** - contains only generic installation logic

## Requirements

- **macOS**: Homebrew (for GitHub CLI installation)
- **Linux**: apt/yum package manager
- **Python 3.9+** (for running the target installer)

Perfect for:
- 🏢 **Company onboarding scripts** in private repositories
- 🔒 **Secure installer distribution** 
- 🎯 **One-command setup** workflows
- 📦 **Private tooling deployment**