param(
    [Parameter(Mandatory = $true)]
    [string]$InputPath,

    [Parameter(Mandatory = $true)]
    [string]$Start,

    [Parameter(Mandatory = $true)]
    [string]$End,

    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

function Test-MmSsTimestamp {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    if ($Value -notmatch '^\d{1,2}:\d{2}$') {
        return $false
    }

    $parts = $Value.Split(':')
    $minutes = [int]$parts[0]
    $seconds = [int]$parts[1]

    if ($minutes -gt 59 -or $seconds -gt 59) {
        return $false
    }

    return $true
}

function Convert-ToSeconds {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    $parts = $Value.Split(':')
    $minutes = [int]$parts[0]
    $seconds = [int]$parts[1]

    return (($minutes * 60) + $seconds)
}

if (-not (Test-Path -LiteralPath $InputPath -PathType Leaf)) {
    throw "Input file not found: $InputPath"
}

if (-not (Test-MmSsTimestamp -Value $Start)) {
    throw "Start must be in MM:SS format with values under 59:59. Example: 03:45"
}

if (-not (Test-MmSsTimestamp -Value $End)) {
    throw "End must be in MM:SS format with values under 59:59. Example: 04:10"
}

$startSeconds = Convert-ToSeconds -Value $Start
$endSeconds = Convert-ToSeconds -Value $End

if ($startSeconds -ge $endSeconds) {
    throw "Start time must be earlier than end time."
}

$ffprobe = Get-Command ffprobe -ErrorAction SilentlyContinue
if (-not $ffprobe) {
    throw "ffprobe was not found. Run .\setup.ps1 or install FFmpeg first."
}

$durationOutput = & ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 -sexagesimal $InputPath 2>$null
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($durationOutput)) {
    throw "Could not determine video duration. Check that the file is a valid MP4 and FFmpeg is installed correctly."
}

# ffprobe returns seconds as a floating-point decimal, e.g. 455.12
$totalDuration = [double]$durationOutput
if ($endSeconds -gt [math]::Floor($totalDuration)) {
    throw "End time '$End' is beyond the video duration ($totalDuration seconds)."
}

$inputDirectory = Split-Path -Parent $InputPath
$inputBaseName = [System.IO.Path]::GetFileNameWithoutExtension($InputPath)

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $outputFileName = "{0}_trim_{1}_{2}.mp4" -f $inputBaseName, ($Start.Replace(':', '_')), ($End.Replace(':', '_'))
    $OutputPath = Join-Path -Path $inputDirectory -ChildPath $outputFileName
}

if (Test-Path -LiteralPath $OutputPath -PathType Leaf) {
    Write-Host "Output file already exists: $OutputPath" -ForegroundColor Yellow
    $overwrite = Read-Host "Overwrite it? (Y/N)"
    if ($overwrite -notmatch '^(y|yes)$') {
        throw "Operation cancelled. Choose a different output path."
    }
}

$trimDuration = $endSeconds - $startSeconds
Write-Host "Trimming from $Start to $End ($trimDuration seconds)" -ForegroundColor Cyan
Write-Host "Input: $InputPath" -ForegroundColor Cyan
Write-Host "Output: $OutputPath" -ForegroundColor Cyan

$ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
if (-not $ffmpeg) {
    throw "ffmpeg was not found. Run .\setup.ps1 or install FFmpeg first."
}

& ffmpeg -hide_banner -loglevel error -y -ss $startSeconds -i $InputPath -t $trimDuration -c copy -avoid_negative_ts make_zero $OutputPath
if ($LASTEXITCODE -ne 0) {
    throw "FFmpeg failed while trimming the file. See the ffmpeg output above for details."
}

Write-Host "Trim complete: $OutputPath" -ForegroundColor Green
