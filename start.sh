#!/bin/bash
set -e

export HOME=/home/radio
# export PULSE_RUNTIME_PATH="$HOME/.pulse"
# export PULSE_SERVER=unix:$PULSE_RUNTIME_PATH/native
export DISPLAY=:99

# mkdir -p "$PULSE_RUNTIME_PATH"
# chmod 700 "$PULSE_RUNTIME_PATH"

# Start PulseAudio with user runtime dir
pulseaudio --start --exit-idle-time=-1 --daemonize --log-target=stderr --system=false --disallow-exit

sleep 2

pactl load-module module-null-sink sink_name=radio_sink sink_properties=device.description="RadioSink"
pactl set-default-sink radio_sink

icecast2 -c /etc/icecast2/icecast.xml &

Xvfb :99 -screen 0 1280x720x16 &
sleep 2

x11vnc -display :99 -nopw -listen 0.0.0.0 -forever &
sleep 2

chromium --no-sandbox --autoplay-policy=no-user-gesture-required --user-data-dir="$HOME/chromium-data" \
  --window-size=1280,720 \
  --disable-gpu \
  --disable-software-rasterizer \
  "https://www.smwcentral.net/?p=section&s=smwmusic" &
sleep 10

node /app/radio-playback.js &
sleep 10

MONITOR_SOURCE=$(pactl list sources short | grep 'radio_sink.monitor' | awk '{print $2}')
if [ -z "$MONITOR_SOURCE" ]; then
  echo "Monitor source not found! Available sources:"
  pactl list sources short
  exit 1
fi

ffmpeg -f pulse -i "$MONITOR_SOURCE" -vn -c:a libmp3lame -b:a 128k -content_type audio/mpeg \
  -f mp3 icecast://source:hackme@localhost:8000/stream


