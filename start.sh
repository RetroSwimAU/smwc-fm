#!/bin/bash

set -e

# Start PulseAudio (for audio routing)
pulseaudio --start

# Start IceCast
service icecast2 start

# Start Xvfb (virtual display, required for Chromium)
Xvfb :99 -screen 0 1280x720x16 &
export DISPLAY=:99

# Wait for everything to start up
sleep 5

# Start Chromium in background, visiting the radio site
chromium-browser --no-sandbox --autoplay-policy=no-user-gesture-required --user-data-dir=/tmp/chromium-data \
  --window-size=1280,720 \
  --disable-gpu \
  --disable-software-rasterizer \
  \"https://www.smwcentral.net/?p=section&s=smwmusic\" &

# Wait a bit for Chromium to launch
sleep 10

# Start Puppeteer script (automates playback and song title updates)
node /radio-playback.js &

# Wait a bit for audio to start
sleep 10

# Find PulseAudio monitor source (for ffmpeg)
MONITOR_SOURCE=$(pactl list sources short | grep 'monitor' | awk '{print $2}' | head -n 1)

# Start ffmpeg to stream audio to IceCast
ffmpeg -f pulse -i \"$MONITOR_SOURCE\" -vn -c:a libmp3lame -b:a 128k -content_type audio/mpeg \
  -f mp3 icecast://source:hackme@localhost:8000/stream
