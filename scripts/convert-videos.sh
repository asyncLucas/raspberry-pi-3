#!/bin/bash
# convert-to-mp4.sh
# Recursively convert/remux videos to MP4 (H.264 + AAC) for Jellyfin direct play
# Deletes original file after successful conversion

SOURCE_DIR="$1"

if [ -z "$SOURCE_DIR" ]; then
    echo "Usage: $0 /path/to/media"
    exit 1
fi

# Loop through all video files in subdirectories
find "$SOURCE_DIR" -type f \( -iname "*.avi" -o -iname "*.mkv" -o -iname "*.mov" -o -iname "*.flv" \) | while IFS= read -r file; do
    dir=$(dirname "$file")
    base=$(basename "$file")
    name="${base%.*}"
    output="$dir/$name.mp4"

    # Skip if output already exists
    if [ -f "$output" ]; then
        echo "⏭ Skipping (already exists): $output"
        continue
    fi

    echo "🎬 Processing: \"$file\" → \"$output\""

    # Try remux first (copy video, convert audio to AAC)
    ffmpeg -i "$file" -c:v copy -c:a aac -b:a 128k -movflags +faststart "$output" -y

    # If remux failed, do full re-encode
    if [ $? -ne 0 ]; then
        echo "⚠️ Remux failed, trying full re-encode..."
        ffmpeg -i "$file" -c:v libx264 -preset fast -crf 20 -c:a aac -b:a 192k -movflags +faststart "$output" -y
    fi

    # If conversion succeeded, delete original
    if [ $? -eq 0 ] && [ -f "$output" ]; then
        echo "✅ Success: \"$output\""
        rm -f "$file"
    else
        echo "❌ Failed: \"$file\" (keeping original)"
        [ -f "$output" ] && rm -f "$output"
    fi
done