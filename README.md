# SMWC-FM

Another attempt at a streaming radio station serving SMWC music. It offloads song selection to the website.

Quality of life feature I'd like is detecting dead and refreshing the page automatically.

## Features

- **Automatic streaming:** Opens the web page in a browser and clicks play, the webpage already curates (I assume), don't wanna reinvent the wheel.
- **Track title updates:** Puppeteer extracts the current song name from the html DOM and updates IceCast's metadata automagically.
- **Fully containerized:** Docker run, and forget.

## How it works

Puppeteer -> Chromium -> PulseAudio -> ffmpeg -> IceCast -> You

## Usage

1. **Build the Docker image:**
   ```sh
   docker build -t internet-radio-docker .
   ```

2. **Run the container:**
   ```sh
   docker run --rm -p 8000:8000 internet-radio-docker
   ```

3. **Listen to the stream:**
   - Open [http://localhost:8000](http://localhost:8000) in your browser.


## License

This app is too young to drive and doesn't have a license.
