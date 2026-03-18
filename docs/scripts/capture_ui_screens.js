const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const BASE_URL = process.env.CAPTURE_URL || 'http://localhost:8080';
const OUT_DIR = path.resolve(
  process.cwd(),
  'docs/ui_captures/screenshots_for_design',
);

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function clickTextIfPresent(page, text) {
  const locator = page.getByText(text, { exact: false }).first();
  const count = await locator.count();
  if (count === 0) return false;
  await locator.scrollIntoViewIfNeeded();
  await locator.click({ timeout: 6000 });
  return true;
}

async function capture(page, filename) {
  const target = path.join(OUT_DIR, filename);
  await page.screenshot({ path: target, fullPage: true });
  // eslint-disable-next-line no-console
  console.log(`Captured ${target}`);
}

async function clickBottomTab(page, index) {
  const size = page.viewportSize();
  const x = (size.width * (index + 0.5)) / 5;
  const y = size.height - 22;
  await page.mouse.click(x, y);
  await sleep(900);
}

async function main() {
  fs.mkdirSync(OUT_DIR, { recursive: true });

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    viewport: { width: 1512, height: 1200 },
    deviceScaleFactor: 2,
  });
  const page = await context.newPage();

  await page.goto(BASE_URL, { waitUntil: 'networkidle', timeout: 120000 });
  await sleep(2500);

  await capture(page, '01_home_light.png');

  // Top-right notification and profile icons on home.
  {
    const size = page.viewportSize();
    await page.mouse.click(size.width - 56, 22);
    await sleep(900);
    await capture(page, '02_notifications.png');
    await page.goBack({ waitUntil: 'networkidle' });
    await sleep(700);

    await page.mouse.click(size.width - 22, 22);
    await sleep(900);
    await capture(page, '03_profile.png');
    await page.goBack({ waitUntil: 'networkidle' });
    await sleep(700);
  }

  if (await clickTextIfPresent(page, 'Dark')) {
    await sleep(800);
    await capture(page, '04_home_dark.png');
    await clickTextIfPresent(page, 'Light');
    await sleep(600);
  }

  await clickBottomTab(page, 2);
  await capture(page, '05_track_home.png');

  if (await clickTextIfPresent(page, 'Vitals Trends')) {
    await sleep(1000);
    await capture(page, '06_vitals_trends.png');
    await page.goBack({ waitUntil: 'networkidle' });
    await sleep(700);
  }

  if (await clickTextIfPresent(page, 'Chronic Symptoms')) {
    await sleep(1000);
    await capture(page, '07_symptoms_list.png');

    if (await clickTextIfPresent(page, 'Add Symptom')) {
      await sleep(800);
      await capture(page, '08_add_symptom.png');
      await page.goBack({ waitUntil: 'networkidle' });
      await sleep(700);
    }

    await page.goBack({ waitUntil: 'networkidle' });
    await sleep(700);
  }

  if (await clickTextIfPresent(page, 'View All')) {
    await sleep(1000);
    await capture(page, '09_medications_list.png');
    await page.goBack({ waitUntil: 'networkidle' });
    await sleep(700);
  }

  // Reminder timeline is lower in the track page.
  await page.mouse.wheel(0, 800);
  await sleep(500);
  if (await clickTextIfPresent(page, 'Reminder Timeline')) {
    await sleep(1000);
    await capture(page, '10_reminders_timeline.png');
    if (await clickTextIfPresent(page, 'Add Reminder')) {
      await sleep(800);
      await capture(page, '11_add_reminder.png');
      await page.goBack({ waitUntil: 'networkidle' });
      await sleep(700);
    }
    await page.goBack({ waitUntil: 'networkidle' });
    await sleep(700);
  }

  await clickBottomTab(page, 3);
  await capture(page, '12_family.png');

  await clickBottomTab(page, 4);
  await capture(page, '13_ai.png');

  await clickBottomTab(page, 1);
  await capture(page, '14_vault.png');

  await clickBottomTab(page, 0);
  await capture(page, '15_home_final.png');

  await browser.close();
}

main().catch((err) => {
  // eslint-disable-next-line no-console
  console.error(err);
  process.exit(1);
});
