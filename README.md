# MP4 Trimmer

A Windows-only PowerShell utility that trims an .mp4 file by start and end timestamps using FFmpeg in stream-copy mode. This method is fast and preserves the original video/audio content without re-encoding.

## Why this approach

- Fast for large files: no transcoding, so a 1+ GB MP4 can be trimmed quickly.
- Keeps content intact: it copies the original streams instead of recompressing them.
- Good for one-time edits: best when you want a clean trimmed clip in a new file.

## Prerequisites

You need FFmpeg installed and available on your PATH.

- Install FFmpeg with the included setup script:
  - `powershell -ExecutionPolicy Bypass -File .\setup.ps1`
- Or install FFmpeg manually and confirm:
  - `ffmpeg -version`

## Usage

Run the trim script:

```powershell
powershell -ExecutionPolicy Bypass -File .\Trim-Mp4.ps1 -InputPath "C:\path\to\video.mp4" -Start "02:15" -End "03:45"
```

This will create a new file next to the original, like:

```text
video_trim_02_15_to_03_45.mp4
```

### Supported timestamp format

- `MM:SS` only
- Example: `03:45` means 3 minutes 45 seconds
- Maximum supported time is `59:59`

### Parameters

- `-InputPath` : Full path to the source MP4
- `-Start` : Start timestamp in `MM:SS`
- `-End` : End timestamp in `MM:SS`
- `-OutputPath` : Optional custom output path

### Example with custom output name

```powershell
powershell -ExecutionPolicy Bypass -File .\Trim-Mp4.ps1 -InputPath "C:\videos\clip.mp4" -Start "01:20" -End "02:05" -OutputPath "C:\videos\clip_trimmed.mp4"
```

## What the script does

The script:

1. Validates the input file exists
2. Validates the timestamp format and range
3. Uses `ffprobe` to read the total duration
4. Verifies the trim range is valid
5. Runs FFmpeg in copy mode to generate a new trimmed file

It does not alter original content or re-encode the video.

## Important notes

- The original file is left untouched.
- The output is a new file.
- If the input is already close to the size limit of your disk, make sure you have enough free space for the trimmed output.
- If you encounter issues, the script prints useful ffmpeg failure details.

## Troubleshooting

If FFmpeg is not found:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```

If the script says the trim range is invalid, double-check:

- start is before end
- both timestamps use `MM:SS`
- the selected range fits within the video duration

## License

This project is provided as-is for personal use.
