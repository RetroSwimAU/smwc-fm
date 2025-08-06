FROM node:20-bullseye

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies as root
RUN apt-get update && apt-get install -y \
    icecast2 \
    ffmpeg \
    pulseaudio \
    xvfb \
    wget \
    alsa-utils \
    x11vnc \
    chromium \
    --no-install-recommends

# Add non-root user
RUN useradd -m -s /bin/bash radio

# Prepare working directory for our app and set permissions
WORKDIR /app
COPY radio-playback.js /app/radio-playback.js
RUN chown -R radio:radio /app

# Install Puppeteer as our app user
USER radio
RUN npm install puppeteer

# Back to root to copy configs and scripts, fix permissions, then drop to user
USER root
COPY --chown=radio:radio icecast.xml /etc/icecast2/icecast.xml
COPY --chown=radio:radio start.sh /start.sh
RUN chmod +x /start.sh
RUN mkdir -p /home/radio/logs && chown radio:radio /home/radio/logs

# Expose ports
EXPOSE 8000
EXPOSE 5900

# Switch to non-root for runtime
USER radio
WORKDIR /app

CMD ["/start.sh"]
