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

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

(async () => {
  const browser = await puppeteer.connect({
    browserURL: 'http://localhost:9222',
    defaultViewport: null
  });

  const pages = await browser.pages();

  var gotPage = false;
  var playerPage;

  while(!gotPage){
    playerPage = pages.find(p => p.url().includes(RADIO_URL));
    if(playerPage) { gotPage = true; }
    else { await sleep(1000); }
  }


  console.log("wait for smwc music page to finish loading");
  var pageLoaded = false;
  while(!pageLoaded) {
    try{
      await playerPage.waitForSelector('span[data-spc-radio="enable-span"]', { timeout: 10000 });
      pageLoaded = true;
    } catch {
      console.log("Click captcha maybe?");
      playerPage.mouse.click(204,288);
      // do nothing
    }
  }

  console.log("Got it.");
  sleep(2000);

  var playerIsUp = false;

  // Click the "Radio" button
  while(!playerIsUp) {
    try{
      await playerPage.waitForSelector('#spc-radio', { timeout: 2000 });
      console.log("Player has appeared!");
      playerIsUp = true;
    } catch {
      await playerPage.evaluate(() => {
        const links = Array.from(document.querySelectorAll('a'));
        for (const link of links) {
          if (link.textContent.includes('Radio')) {
            console.log("\n\nFound a radio link, giving it a clickaroo.\n\n");
            link.click();
            break;
          }
        }
      });
    }
  }
  // Wait for player interface to load
  await playerPage.waitForSelector('#spc-player-interface', { timeout: 0 });

  let lastTrack = '';
  let lastArtist = '';
  setInterval(async () => {
    let track = '';
    let artist = '';
    try {
      track = await playerPage.$eval(
        '#spc-player-interface h2 a',
        el => el.textContent.trim()
      );
      artist = await playerPage.$eval(
        '#spc-player-interface h3',
        el => el.textContent.trim()
      );
    } catch (err) {
      track = 'RADIO';
      artist = 'SMWC';
    }

    if (track && track !== lastTrack && artist && artist !== lastArtist) {
      console.log('Current Track:', track);
      console.log('Current Artist:', artist);
      const newText = artist + ' - ' + track;
      updateIcecastTrack(newText);
      lastTrack = track;
      lastArtist = artist;
    }
  }, 10000);

  // Keep the script running
})();
