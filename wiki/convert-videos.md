🎬 Automatic Video Conversion for Direct Play in Jellyfin

📌 Objective

This script automatically converts (or remuxes) video files to a format universally compatible with Direct Play in Jellyfin and HTML5 browsers.

Output format:
• Container: MP4
• Video: H.264 (libx264)
• Audio: AAC
• Subtitles: preserved if supported

This avoids heavy transcoding on Raspberry Pi or servers with limited resources.

⸻

⚡ Script Features
• ✅ Scans subfolders (series, seasons, collections, etc.).
• ✅ Automatically detects video and audio codecs.
• ✅ If file is already in H.264 + AAC, just remuxes (super fast, no quality loss).
• ✅ If not compatible, converts to H.264 + AAC.
• ✅ Keeps folder structure intact.

⸻

📂 Example Structure

/media/videos/
├── Movies/
│ ├── movie1.mkv
│ └── movie2.avi
└── Series/
└── SeriesX/
├── Season1/
│ ├── S01E01.mkv
│ └── S01E02.mp4
└── Season2/
└── S02E01.mov

After running the script, all files will be compatible .mp4.

⸻

🔧 Installation

1. Dependencies

Make sure you have ffmpeg and ffprobe installed:

sudo apt update
sudo apt install ffmpeg -y

2. Download the script

Create a file called convert-videos.sh:

nano convert_videos.sh

Paste the content below:

#!/bin/bash

# Usage: ./convert-videos.sh /path/to/your/library

INPUT_DIR="$1"
if [ -z "$INPUT_DIR" ]; then
echo "❌ Provide the videos folder. Example: ./convert-videos.sh /media/videos"
exit 1
fi

find "$INPUT_DIR" -type f \( -iname "*.mkv" -o -iname "*.avi" -o -iname "*.mov" -o -iname "*.mp4" \) | while read -r file; do
  dir=$(dirname "$file")
  base=$(basename "$file")
  name="${base%.\*}"
output="$dir/$name.mp4"

echo "🎬 Processing: $file"

# Check video and audio codecs

vcodec=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 "$file")
acodec=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of csv=p=0 "$file")

if [["$vcodec" == "h264" && "$acodec" == "aac"]]; then
echo "✅ Already in H.264 + AAC → just remuxing..."
ffmpeg -i "$file" -c copy -movflags +faststart "$output" -y
else
echo "⚡ Converting to H.264 + AAC..."
ffmpeg -i "$file" -c:v libx264 -preset fast -crf 20 -c:a aac -b:a 192k -movflags +faststart "$output" -y
fi

echo "✔️ Finished: $output"
done

3. Execution permission

chmod +x convert_videos.sh

⸻

▶️ Usage

Run the script passing the library folder:

./convert-videos.sh /media/videos

The script will traverse all folders and subfolders converting/remuxing the files.

⸻

⚡ Customization Options \

### • Change video quality (-crf):

• 18 → Very high quality (larger files) \
• 20 → Balanced (recommended) \
• 23 → More compression (smaller files)

### • Change conversion speed (-preset):

• veryfast → Faster, larger files \
• slow → Slower, smaller files
