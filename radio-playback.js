const puppeteer = require('puppeteer');
const { execSync } = require('child_process');

const RADIO_URL = 'https://www.smwcentral.net/?p=section&s=smwmusic';

function updateIcecastTrack(track) {
  const mount = '/stream';
  const cmd = `curl -u source:hackme "http://localhost:8000/admin/metadata?mount=${mount}&mode=updinfo&song=${encodeURIComponent(track)}"`;
  try {
    execSync(cmd);
  } catch (e) {
    console.error('Failed to update IceCast metadata:', e.message);
  }
}

(async () => {
  const browser = await puppeteer.launch({
    executablePath: '/usr/bin/chromium',
    headless: false,
    args: [
      '--no-sandbox',
      '--autoplay-policy=no-user-gesture-required',
      '--window-size=1280,720',
      '--disable-gpu',
      '--disable-software-rasterizer',
    ],
    env: {
      DISPLAY: ':99'
    }
  });
  const page = await browser.newPage();
  await page.goto(RADIO_URL, { waitUntil: 'networkidle2' });

  // Click the "Radio" button
  await page.evaluate(() => {
    const links = Array.from(document.querySelectorAll('a'));
    for (const link of links) {
      if (link.textContent.includes('Radio')) {
        link.click();
        break;
      }
    }
  });

  // Wait for player interface to load
  await page.waitForSelector('#spc-player-interface', { timeout: 0 });

  let lastTrack = '';
  setInterval(async () => {
    let track = '';
    try {
      track = await page.$eval(
        '#spc-player-interface h2 a',
        el => el.textContent.trim()
      );
    } catch (err) {
      track = '';
    }

    if (track && track !== lastTrack) {
      console.log('Current Song:', track);
      updateIcecastTrack(track);
      lastTrack = track;
    }
  }, 10000);

  // Keep the script running
})();
