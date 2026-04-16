# --------------------------------------------------------------------------
#  Scripts Fixer -- One-liner bootstrap installer
#  Usage:  irm https://raw.githubusercontent.com/alimtvnetwork/scripts-fixer-v7/main/install.ps1 | iex
# --------------------------------------------------------------------------
& {
    $ErrorActionPreference = "Stop"

    $repo   = "https://github.com/alimtvnetwork/scripts-fixer-v7.git"
    $folder = Join-Path $env:USERPROFILE "scripts-fixer"

    Write-Host ""
    Write-Host "  Scripts Fixer -- Bootstrap Installer" -ForegroundColor Cyan
    Write-Host ""

    # -- Check git is available -----------------------------------------------
    $hasGit = Get-Command git -ErrorAction SilentlyContinue
    if (-not $hasGit) {
        Write-Host "  [ERROR] git is not installed. Install Git first, then re-run." -ForegroundColor Red
        Write-Host "          winget install Git.Git" -ForegroundColor DarkGray
        return
    }

    # -- Clone or pull --------------------------------------------------------
    if (Test-Path (Join-Path $folder ".git")) {
        Write-Host "  [OK] Repo already exists at $folder -- pulling latest..." -ForegroundColor Green
        try {
            $null = & git -C $folder pull --ff-only 2>&1
        } catch {
            Write-Host "  [WARN] Pull failed -- continuing with existing copy." -ForegroundColor Yellow
        }
    } else {
        Write-Host "  [>>] Cloning into $folder ..." -ForegroundColor Yellow
        try {
            $null = & git clone $repo $folder 2>&1
        } catch {
            Write-Host "  [ERROR] Clone failed: $_" -ForegroundColor Red
            return
        }
        if (-not (Test-Path $folder)) {
            Write-Host "  [ERROR] Clone failed. Check your network and try again." -ForegroundColor Red
            return
        }
        Write-Host "  [OK] Cloned successfully." -ForegroundColor Green
    }

    # -- Launch interactive menu ----------------------------------------------
    Write-Host ""
    Write-Host "  Launching interactive menu..." -ForegroundColor Cyan
    Write-Host ""
    Set-Location $folder
    & .\run.ps1 -d
}
