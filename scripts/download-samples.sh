#!/usr/bin/env bash
set -euo pipefail

DEST="$(cd "$(dirname "$0")/.." && pwd)/public/samples/salamander"
BASE_URL="https://tonejs.github.io/audio/salamander"

NOTES=(
  A0 C1 Ds1 Fs1
  A1 C2 Ds2 Fs2
  A2 C3 Ds3 Fs3
  A3 C4 Ds4 Fs4
  A4 C5 Ds5 Fs5
  A5 C6 Ds6 Fs6
  A6 C7 Ds7 Fs7
  A7 C8
)

mkdir -p "$DEST"

for note in "${NOTES[@]}"; do
  file="$DEST/${note}.mp3"
  if [ -f "$file" ]; then
    echo "Skip (exists): ${note}.mp3"
    continue
  fi
  echo "Downloading: ${note}.mp3"
  curl -fSL -o "$file" "${BASE_URL}/${note}.mp3"
done

echo "Done. ${#NOTES[@]} samples in $DEST"
