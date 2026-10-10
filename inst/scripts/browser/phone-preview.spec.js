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
  const outerSelect = await page.locator('.selectize-control .selectize-input').first().boundingBox();
  expect(outerSelect.height).toBeLessThan(43);
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
  await child.waitForFunction(() => document.documentElement.getAttribute('data-glass-pointer') === 'coarse');
  await child.waitForSelector('.selectize-control .selectize-input', { timeout: 30000 });
  const framedSelect = await child.locator('.selectize-control .selectize-input').first().evaluate((el) => {
    const box = el.getBoundingClientRect();
    return { width: box.width, height: box.height };
  });
  expect(framedSelect.height).toBeGreaterThanOrEqual(43.4);
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

test('the phone frame uses coarse sizes for the sidebar toggle', async ({ page }) => {
  test.setTimeout(90000);
  await page.setViewportSize({ width: 1280, height: 900 });
  await page.addInitScript(() => localStorage.setItem('shinyglass-phone-preview:dashboard', 'full'));
  await page.goto('http://127.0.0.1:3946/', { waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => window.Shiny && Shiny.shinyapp && Shiny.shinyapp.isConnected());
  const outer = page.locator('.bslib-sidebar-layout > .collapse-toggle').first();
  await expect(outer).toBeVisible();
  const outerBox = await outer.boundingBox();
  expect(outerBox.height).toBeLessThan(40);
  await page.evaluate(() => localStorage.setItem('shinyglass-phone-preview:dashboard', 'phone'));
  await page.locator('.phone-preview-toggle').click();
  const frame = page.locator('iframe.phone-preview-frame');
  await expect(frame).toBeVisible();
  const child = page.frames().find((f) => f.parentFrame() === page.mainFrame());
  await child.waitForFunction(() => document.documentElement.getAttribute('data-glass-pointer') === 'coarse');
  await child.waitForFunction(() => window.Shiny && Shiny.shinyapp && Shiny.shinyapp.isConnected());
  const framed = child.locator('.bslib-sidebar-layout > .collapse-toggle').first();
  await expect(framed).toBeVisible({ timeout: 20000 });
  const framedBox = await framed.evaluate((el) => {
    const box = el.getBoundingClientRect();
    return { width: box.width, height: box.height };
  });
  expect(framedBox.width).toBeGreaterThanOrEqual(43.4);
  expect(framedBox.height).toBeGreaterThanOrEqual(43.4);
});

test('reduced motion drops the switch transition', async ({ page }) => {
  await page.setViewportSize({ width: 1280, height: 800 });
  await page.emulateMedia({ reducedMotion: 'reduce' });
  await connected(page);
  const duration = await page.locator('.phone-preview-toggle').evaluate((el) => getComputedStyle(el).transitionDuration);
  expect(duration === '0s' || duration === '0ms').toBeTruthy();
});

test('a narrow fine pointer does not mount the preview', async ({ browser }) => {
  const context = await browser.newContext({
    viewport: { width: 393, height: 852 },
    hasTouch: false,
    isMobile: false,
  });
  const page = await context.newPage();
  try {
    await connected(page);
    expect(await page.evaluate(() => window.matchMedia('(pointer: fine) and (min-width: 900px)').matches)).toBe(false);
    await expect(page.locator('.phone-preview-toggle')).toHaveCount(0);
    await expect(page.locator('iframe')).toHaveCount(0);
    await expect(page.locator('.phone-preview-root')).toHaveCount(0);
  } finally {
    await context.close();
  }
});

test('a wide coarse pointer does not mount the preview', async ({ browser }) => {
  const iphone = devices['iPhone 16'];
  const context = await browser.newContext({
    userAgent: iphone.userAgent,
    viewport: { width: 1280, height: 800 },
    deviceScaleFactor: iphone.deviceScaleFactor,
    isMobile: true,
    hasTouch: true,
  });
  const page = await context.newPage();
  try {
    await connected(page);
    expect(await page.evaluate(() => window.matchMedia('(pointer: coarse)').matches)).toBe(true);
    expect(await page.evaluate(() => window.matchMedia('(pointer: fine) and (min-width: 900px)').matches)).toBe(false);
    await expect(page.locator('.phone-preview-toggle')).toHaveCount(0);
    await expect(page.locator('iframe')).toHaveCount(0);
    await expect(page.locator('.phone-preview-root')).toHaveCount(0);
  } finally {
    await context.close();
  }
});

test('shrinking below 900px removes the frame and the extra session', async ({ page }) => {
  test.setTimeout(90000);
  const sockets = [];
  page.on('websocket', (ws) => {
    const rec = { url: ws.url(), open: true };
    ws.on('close', () => { rec.open = false; });
    sockets.push(rec);
  });
  const openShiny = () => sockets.filter((s) => /websocket/i.test(s.url) && s.open);

  await page.setViewportSize({ width: 1280, height: 800 });
  await page.addInitScript(() => localStorage.setItem('shinyglass-phone-preview:demo', 'full'));
  await page.goto(BASE, { waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => window.Shiny && Shiny.shinyapp && Shiny.shinyapp.isConnected());
  await expect.poll(() => openShiny().map((s) => s.url)).toHaveLength(1);

  await page.locator('.phone-preview-toggle').click();
  await expect(page.locator('iframe.phone-preview-frame')).toBeVisible();
  await expect.poll(() => openShiny().length, { timeout: 20000 }).toBe(2);

  await page.setViewportSize({ width: 393, height: 852 });
  await expect(page.locator('.phone-preview-toggle')).toHaveCount(0);
  await expect(page.locator('iframe')).toHaveCount(0);
  await expect(page.locator('.phone-preview-root')).toHaveCount(0);
  await expect.poll(() => openShiny().length, { timeout: 15000 }).toBe(1);
  expect(await page.evaluate(() => getComputedStyle(document.documentElement).overflowY)).not.toBe('hidden');
  await expect(page.locator('#dist_plot')).toBeVisible();
});

const IPHONE_APPS = [
  {
    name: 'demo',
    url: 'http://127.0.0.1:3945/',
    selectors: ['h2', '#species', '#bins', '#dist_plot'],
    ready: '#dist_plot',
  },
  {
    name: 'dashboard',
    url: 'http://127.0.0.1:3946/',
    selectors: ['.bslib-page-title', '.bslib-value-box', '#dist_plot', '#tabs'],
    ready: '.bslib-page-title',
  },
  {
    name: 'inputs',
    url: 'http://127.0.0.1:3947/',
    selectors: ['.bslib-page-title', '#text', '#slider', '#numeric'],
    ready: '#text',
  },
  {
    name: 'olympics',
    url: 'http://127.0.0.1:3948/',
    selectors: ['.olympics-hero', '#btn', '#discipline'],
    ready: '.olympics-hero',
    img: '.olympics-hero img',
  },
  {
    name: 'chat',
    url: 'http://127.0.0.1:3949/',
    selectors: ['#chat_page', '#project', '#chat_user_input'],
    ready: '#chat_user_input',
  },
];

function iphone16Context() {
  const iphone = devices['iPhone 16'];
  return {
    userAgent: iphone.userAgent,
    viewport: { width: 393, height: 852 },
    screen: { width: 393, height: 852 },
    deviceScaleFactor: iphone.deviceScaleFactor,
    isMobile: true,
    hasTouch: true,
  };
}

async function stripPhonePreview(route) {
  if (route.request().resourceType() !== 'document') {
    await route.continue();
    return;
  }
  const response = await route.fetch();
  const headers = { ...response.headers() };
  delete headers['content-length'];
  delete headers['content-encoding'];
  let body = await response.text();
  body = body
    .replace(/<meta\b[^>]*\bshinyglass-phone-[^>]*>/gi, '')
    .replace(/<link\b[^>]*\bphone-preview\.css[^>]*>/gi, '')
    .replace(/<script\b[^>]*\bphone-preview\.js[^>]*>\s*<\/script>/gi, '')
    .replace(/<script\b[^>]*\bid="shinyglass-phone-preview-loader"[^>]*>[\s\S]*?<\/script>/gi, '');
  await route.fulfill({ status: response.status(), headers, body });
}

async function settle(page, app) {
  await page.waitForFunction(
    () => window.Shiny && Shiny.shinyapp && Shiny.shinyapp.isConnected(),
    null,
    { timeout: 60000 }
  );
  await page.waitForSelector(app.ready, { timeout: 30000 });
  if (app.img) {
    await page.waitForFunction((sel) => {
      const img = document.querySelector(sel);
      return img && img.complete && img.naturalWidth > 0;
    }, app.img, { timeout: 30000 });
  }
  await page.evaluate(() => (document.fonts ? document.fonts.ready : null));
  await page.waitForFunction(() => !document.getElementById('shiny-disconnected-overlay'), null, { timeout: 15000 }).catch(() => {});
  await page.waitForTimeout(400);
}

async function layoutSnapshot(page, app) {
  return page.evaluate((selectors) => {
    function box(sel) {
      const el = document.querySelector(sel);
      if (!el) return { sel, missing: true };
      const r = el.getBoundingClientRect();
      return {
        sel,
        x: Math.round(r.x),
        y: Math.round(r.y),
        w: Math.round(r.width),
        h: Math.round(r.height),
      };
    }
    const html = getComputedStyle(document.documentElement);
    const body = getComputedStyle(document.body);
    return {
      boxes: selectors.map(box),
      layout: {
        htmlOverflow: html.overflow,
        bodyOverflow: body.overflow,
        htmlTouch: html.touchAction,
        bodyTouch: body.touchAction,
      },
    };
  }, app.selectors);
}

for (const app of IPHONE_APPS) {
  test(`iPhone 16 leaves ${app.name} identical to main`, async ({ browser }) => {
    test.setTimeout(120000);
    const context = await browser.newContext(iphone16Context());
    try {
      const baselinePage = await context.newPage();
      await baselinePage.route('**/*', stripPhonePreview);
      await baselinePage.goto(app.url, { waitUntil: 'domcontentloaded' });
      await settle(baselinePage, app);
      const baselineHtml = await baselinePage.content();
      expect(baselineHtml).not.toContain('phone-preview.js');
      expect(baselineHtml).not.toContain('phone-preview.css');
      const baseline = await layoutSnapshot(baselinePage, app);
      expect(baseline.boxes.every((box) => !box.missing)).toBe(true);
      await baselinePage.close();

      const page = await context.newPage();
      const sockets = [];
      page.on('websocket', (ws) => {
        const rec = { url: ws.url(), open: true };
        ws.on('close', () => { rec.open = false; });
        sockets.push(rec);
      });
      await page.goto(app.url, { waitUntil: 'domcontentloaded' });
      await settle(page, app);
      const live = await layoutSnapshot(page, app);

      expect(await page.evaluate(() => window.matchMedia('(pointer: fine) and (min-width: 900px)').matches)).toBe(false);
      expect(await page.evaluate(() => window.matchMedia('(pointer: coarse)').matches)).toBe(true);
      await expect(page.locator('.phone-preview-toggle')).toHaveCount(0);
      await expect(page.locator('.phone-preview-root')).toHaveCount(0);
      await expect(page.locator('iframe')).toHaveCount(0);
      expect(page.frames().length).toBe(1);
      expect(live.boxes.map((box) => box.sel)).toEqual(baseline.boxes.map((box) => box.sel));
      for (let i = 0; i < live.boxes.length; i += 1) {
        expect(live.boxes[i].missing, live.boxes[i].sel).toBeFalsy();
        for (const key of ['x', 'y', 'w', 'h']) {
          expect(Math.abs(live.boxes[i][key] - baseline.boxes[i][key]), `${live.boxes[i].sel} ${key}`).toBeLessThanOrEqual(1);
        }
      }
      expect(live.layout).toEqual(baseline.layout);
      const openShiny = sockets.filter((s) => /websocket/i.test(s.url) && s.open);
      expect(openShiny).toHaveLength(1);
    } finally {
      await context.close();
    }
  });
}
