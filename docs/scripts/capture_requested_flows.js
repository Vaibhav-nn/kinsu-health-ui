const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const BASE_URL = process.env.CAPTURE_URL || 'http://localhost:8081';
const OUT_DIR = path.resolve(
  process.cwd(),
  'docs/ui_captures/requested_flow_capture_2026-03-18',
);

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function capture(page, name, fullPage = true) {
  const target = path.join(OUT_DIR, name);
  await page.screenshot({ path: target, fullPage });
  // eslint-disable-next-line no-console
  console.log(`Captured ${target}`);
}

async function openHome(page) {
  await page.goto(BASE_URL, { waitUntil: 'networkidle', timeout: 120000 });
  await sleep(1800);
}

async function clickBottomTab(page, index) {
  const size = page.viewportSize();
  const x = (size.width * (index + 0.5)) / 5;
  const y = size.height - 22;
  await page.mouse.click(x, y);
  await sleep(900);
}

async function scrollTrackLower(page) {
  await page.mouse.click(300, 300);
  for (let i = 0; i < 6; i += 1) {
    await page.mouse.wheel(0, 400);
    await sleep(220);
  }
  await sleep(400);
}

async function runVitalsFlow(browser) {
  const page = await browser.newPage({ viewport: { width: 1512, height: 1200 } });
  await openHome(page);
  await clickBottomTab(page, 2);
  await capture(page, '01_track_home_for_vitals.png', false);

  // More Tracking -> Vitals Trends (upper-left card at this viewport).
  await page.mouse.click(250, 930);
  await sleep(1000);
  await capture(page, '02_vitals_trends_screen.png');

  // Inner screen from Vitals Trends -> Log Vital.
  await page.mouse.click(1420, 1140);
  await sleep(1000);
  await capture(page, '03_log_vital_inner_screen.png');
  await page.close();
}

async function runIllnessFlow(browser) {
  const page = await browser.newPage({ viewport: { width: 1512, height: 1200 } });
  await openHome(page);
  await clickBottomTab(page, 2);
  await scrollTrackLower(page);
  await capture(page, '04_track_lower_cards_for_illness.png', false);

  // Lower-left card -> Illness Episodes.
  await page.mouse.click(260, 470);
  await sleep(1100);
  await capture(page, '05_illness_episodes_screen.png');

  // Inner screen/sheet -> Add New Episode.
  await page.mouse.click(1420, 1140);
  await sleep(900);
  await capture(page, '06_illness_add_episode_inner_sheet.png');
  await page.close();
}

async function runMedicationFlow(browser) {
  const page = await browser.newPage({ viewport: { width: 1512, height: 1200 } });
  await openHome(page);

  // Home quick action -> Medications.
  await page.mouse.click(565, 506);
  await sleep(1000);
  await capture(page, '07_medications_screen.png');

  // Inner screen -> Add Medication.
  await page.mouse.click(1420, 1140);
  await sleep(1000);
  await capture(page, '08_add_medication_inner_screen.png');
  await page.close();
}

async function runReminderFlow(browser) {
  const page = await browser.newPage({ viewport: { width: 1512, height: 1200 } });
  await openHome(page);
  await clickBottomTab(page, 2);
  await scrollTrackLower(page);

  // Lower-right card -> Reminder Timeline.
  await page.mouse.click(760, 470);
  await sleep(1100);
  await capture(page, '09_reminders_timeline_screen.png');

  // Inner screen -> Add Reminder.
  await page.mouse.click(1420, 1140);
  await sleep(1000);
  await capture(page, '10_add_reminder_inner_screen.png');
  await page.close();
}

async function runAppointmentFlow(browser) {
  const page = await browser.newPage({ viewport: { width: 1512, height: 1200 } });
  await openHome(page);
  await capture(page, '11_home_appointments_section.png');

  // First upcoming appointment card -> appointment overview bottom sheet.
  await page.mouse.click(95, 850);
  await sleep(900);
  await capture(page, '12_appointment_inner_overview_sheet.png');
  await page.close();
}

async function main() {
  fs.mkdirSync(OUT_DIR, { recursive: true });
  const browser = await chromium.launch({ headless: true });

  await runVitalsFlow(browser);
  await runIllnessFlow(browser);
  await runMedicationFlow(browser);
  await runReminderFlow(browser);
  await runAppointmentFlow(browser);

  await browser.close();
}

main().catch((err) => {
  // eslint-disable-next-line no-console
  console.error(err);
  process.exit(1);
});
