FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    icecast2 \
    ffmpeg \
    pulseaudio \
    xvfb \
    wget \
    nodejs \
    npm \
    chromium-browser \
    alsa-utils \
    x11vnc \
    --no-install-recommends

# Install Puppeteer
RUN npm install puppeteer

# Set up IceCast config
COPY icecast.xml /etc/icecast2/icecast.xml

# Copy scripts
COPY start.sh /start.sh
COPY radio-playback.js /radio-playback.js

RUN chmod +x /start.sh

EXPOSE 8000
EXPOSE 5900

CMD ["/start.sh"]
