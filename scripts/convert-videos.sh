#!/bin/bash
# Uso: ./convert_videos.sh /caminho/para/sua/biblioteca

INPUT_DIR="$1"
if [ -z "$INPUT_DIR" ]; then
  echo "❌ Informe a pasta de vídeos. Exemplo: ./convert_videos.sh /media/videos"
  exit 1
fi

find "$INPUT_DIR" -type f \( -iname "*.mkv" -o -iname "*.avi" -o -iname "*.mov" -o -iname "*.mp4" \) | while read -r file; do
  dir=$(dirname "$file")
  base=$(basename "$file")
  name="${base%.*}"
  output="$dir/$name.mp4"

  echo "🎬 Processando: $file"

  # Verifica codecs de vídeo e áudio
  vcodec=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 "$file")
  acodec=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of csv=p=0 "$file")

  if [[ "$vcodec" == "h264" && "$acodec" == "aac" ]]; then
    echo "✅ Já está em H.264 + AAC → apenas remuxando..."
    ffmpeg -i "$file" -c copy -movflags +faststart "$output" -y
  else
    echo "⚡ Convertendo para H.264 + AAC..."
    ffmpeg -i "$file" -c:v libx264 -preset fast -crf 20 -c:a aac -b:a 192k -movflags +faststart "$output" -y
  fi

  echo "✔️ Finalizado: $output"
done