$ErrorActionPreference = 'Stop'

Write-Host "Checking for FFmpeg..." -ForegroundColor Cyan

$ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
if (-not $ffmpeg) {
    Write-Host "FFmpeg is not installed or not on PATH." -ForegroundColor Yellow

    $installChoice = Read-Host "Would you like to try installing it with winget? (Y/N)"
    if ($installChoice -match '^(y|yes)$') {
        try {
            Write-Host "Running winget install for FFmpeg..." -ForegroundColor Cyan
            & winget install --id Gyan.Dev.FFmpeg -e -s winget
            if ($LASTEXITCODE -ne 0) {
                throw "winget install failed."
            }
        }
        catch {
            Write-Host "winget install failed or is unavailable." -ForegroundColor Red
            Write-Host "Please install FFmpeg manually and ensure ffmpeg and ffprobe are on your PATH." -ForegroundColor Yellow
            Write-Host "You can download it from: https://www.ffmpeg.org/download.html" -ForegroundColor Yellow
            exit 1
        }
    }
    else {
        Write-Host "FFmpeg is required to use this project." -ForegroundColor Red
        Write-Host "Install FFmpeg and rerun this setup script." -ForegroundColor Yellow
        exit 1
    }
}

Write-Host "FFmpeg found: $($ffmpeg.Source)" -ForegroundColor Green

$ffprobe = Get-Command ffprobe -ErrorAction SilentlyContinue
if (-not $ffprobe) {
    Write-Host "ffprobe was not found. FFmpeg install may be incomplete." -ForegroundColor Red
    exit 1
}

Write-Host "ffprobe found: $($ffprobe.Source)" -ForegroundColor Green
Write-Host "Setup complete. You can now trim MP4 files with Trim-Mp4.ps1" -ForegroundColor Green
