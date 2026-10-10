const { test, expect, devices } = require('@playwright/test');

test.skip(!process.env.RUN_PHONE_TESTS, 'Enable RUN_PHONE_TESTS=1 with R installed');

const BASE = process.env.PHONE_URL || 'http://127.0.0.1:3945/';

async function connected(page) {
  await page.goto(BASE, { waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => window.Shiny && Shiny.shinyapp && Shiny.shinyapp.isConnected());
}

test('desktop toggle frames the app and remembers the choice', async ({ page }) => {
  test.setTimeout(90000);
  await page.setViewportSize({ width: 1280, height: 800 });
  await page.goto(BASE, { waitUntil: 'domcontentloaded' });
  await page.evaluate(() => localStorage.removeItem('shinyglass-phone-preview:demo'));
  await connected(page);

  const toggle = page.locator('.phone-preview-toggle');
  await expect(toggle).toBeVisible();
  await expect(toggle).toHaveAttribute('aria-pressed', 'false');
  await expect(toggle).toHaveText(/Phone view/);
  const box = await toggle.boundingBox();
  expect(box.height).toBeGreaterThanOrEqual(32);
  expect(box.width).toBeGreaterThanOrEqual(32);

  await expect(page.locator('#dist_plot')).toBeVisible();
  await toggle.focus();
  await page.keyboard.press('Enter');

  await expect(toggle).toHaveAttribute('aria-pressed', 'true');
  await expect(toggle).toHaveText(/Full view/);
  const frame = page.locator('iframe.phone-preview-frame');
  await expect(frame).toBeVisible();
  await expect(page.locator('#dist_plot')).toBeHidden();
  await expect(frame).toHaveAttribute('src', /[?&]frame=0(?:&|$)/);

  const child = page.frames().find((f) => f.parentFrame() === page.mainFrame());
  await child.waitForFunction(() => document.documentElement.getAttribute('data-phone-frame') === '0');
  await expect(child.locator('.phone-preview-toggle')).toHaveCount(0);
  await child.waitForSelector('text=Form Controls', { timeout: 30000 });

  await page.reload({ waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => window.Shiny && Shiny.shinyapp && Shiny.shinyapp.isConnected());
  await expect(page.getByRole('button', { name: 'Full view' })).toHaveAttribute('aria-pressed', 'true');
  await expect(page.locator('iframe.phone-preview-frame')).toBeVisible();
  await expect(page.locator('#dist_plot')).toBeHidden();
  const saved = await page.evaluate(() => localStorage.getItem('shinyglass-phone-preview:demo'));
  expect(saved).toBe('phone');
});

test('reduced motion drops the switch transition', async ({ page }) => {
  await page.setViewportSize({ width: 1280, height: 800 });
  await page.emulateMedia({ reducedMotion: 'reduce' });
  await connected(page);
  const duration = await page.locator('.phone-preview-toggle').evaluate((el) => getComputedStyle(el).transitionDuration);
  expect(duration === '0s' || duration === '0ms').toBeTruthy();
});

test('a 393px coarse phone does not show the toggle', async ({ browser }) => {
  const iphone = devices['iPhone 14 Pro'];
  const context = await browser.newContext({
    ...iphone,
    viewport: { width: 393, height: 852 },
  });
  const page = await context.newPage();
  try {
    await connected(page);
    const coarse = await page.evaluate(() => window.matchMedia('(pointer: coarse)').matches);
    const narrow = await page.evaluate(() => window.matchMedia('(max-width: 899px)').matches);
    expect(coarse || narrow).toBeTruthy();
    expect(narrow).toBeTruthy();
    await expect(page.locator('.phone-preview-toggle')).toBeHidden();
    await expect(page.locator('#dist_plot')).toBeVisible();
  } finally {
    await context.close();
  }
});

test('a narrow fine pointer does not show the toggle', async ({ browser }) => {
  const context = await browser.newContext({
    viewport: { width: 393, height: 852 },
    hasTouch: false,
    isMobile: false,
  });
  const page = await context.newPage();
  try {
    await connected(page);
    await expect(page.locator('.phone-preview-toggle')).toBeHidden();
  } finally {
    await context.close();
  }
});

test('a wide coarse pointer does not show the toggle', async ({ browser }) => {
  const iphone = devices['iPhone 14 Pro'];
  const context = await browser.newContext({
    ...iphone,
    viewport: { width: 1280, height: 800 },
  });
  const page = await context.newPage();
  try {
    await connected(page);
    const coarse = await page.evaluate(() => window.matchMedia('(pointer: coarse)').matches);
    expect(coarse).toBeTruthy();
    await expect(page.locator('.phone-preview-toggle')).toBeHidden();
    await expect(page.locator('iframe.phone-preview-frame')).toBeHidden();
    expect(await page.locator('iframe.phone-preview-frame').getAttribute('src')).toBeNull();
  } finally {
    await context.close();
  }
});
