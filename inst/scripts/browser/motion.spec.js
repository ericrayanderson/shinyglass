const { test, expect } = require('@playwright/test');
const path = require('node:path');
const fs = require('node:fs');
const runtime = path.resolve(__dirname, '../../js/shiny-glass.js');
const motion = path.resolve(__dirname, '../../js/glass-ios27.js');
const fontDir = path.resolve(__dirname, '../../fonts/inter');

async function boot(page, flags = {}) {
  await page.emulateMedia({ colorScheme: 'light', reducedMotion: 'no-preference' });
  await page.route('http://glass.test/**', (route) => {
    const url = new URL(route.request().url());
    if (url.pathname.startsWith('/fonts/')) {
      const file = path.join(fontDir, path.basename(url.pathname));
      const type = file.endsWith('.css') ? 'text/css' : 'font/woff2';
      return route.fulfill({ contentType: type, body: fs.readFileSync(file) });
    }
    const data = Object.entries(flags).map(([k, v]) => `data-glass-${k}="${v}"`).join(' ');
    return route.fulfill({
      contentType: 'text/html',
      body: `<!DOCTYPE html><html ${data}><head>
        <link rel="stylesheet" href="/fonts/shinyglass-inter.css"></head>
        <body style="min-height:3000px">
        <nav class="navbar navbar-static-top" id="bar" style="position:sticky;top:0">Bar</nav>
        <div class="card" id="card" style="width:300px;height:160px;margin:40px">Card text</div>
        </body></html>`,
    });
  });
  await page.goto('http://glass.test/app');
  await page.addScriptTag({ path: require.resolve('jquery') });
  await page.evaluate(() => {
    window.Shiny = { setInputValue: () => {}, addCustomMessageHandler: () => {} };
  });
  await page.addScriptTag({ path: runtime });
  await page.addScriptTag({ path: motion });
  await page.evaluate(() => new Promise(resolve => $(resolve)));
}

test('pointer specular follows the mouse over a card', async ({ page }) => {
  await boot(page, { 'pointer-specular': 'true' });
  const box = await page.locator('#card').boundingBox();
  await page.mouse.move(box.x + box.width * 0.9, box.y + box.height * 0.2);
  await expect.poll(() => page.locator('#card.glass-pointer-lit').count()).toBe(1);
  const x = await page.evaluate(() => parseFloat(getComputedStyle(document.getElementById('card')).getPropertyValue('--glass-specular-x')));
  expect(x).toBeGreaterThan(70);
});

test('motion off keeps the static highlight', async ({ page }) => {
  await boot(page, { 'pointer-specular': 'true', motion: 'false' });
  const box = await page.locator('#card').boundingBox();
  await page.mouse.move(box.x + 20, box.y + 20);
  await page.waitForTimeout(200);
  expect(await page.locator('#card.glass-pointer-lit').count()).toBe(0);
});

test('bundled Inter loads and is the computed font off Apple platforms', async ({ page }) => {
  await boot(page, { font: 'matched' });
  const loaded = await page.evaluate(async () => {
    await document.fonts.load('16px Inter');
    await document.fonts.ready;
    return [...document.fonts].some(f => f.family.replace(/"/g, '') === 'Inter' && f.status === 'loaded');
  });
  expect(loaded).toBe(true);
  const family = await page.evaluate(() => getComputedStyle(document.body).getPropertyValue('--bs-body-font-family'));
  expect(family).toContain('Inter');
  if (process.platform !== 'darwin') {
    // Chrome on Linux or Windows has no -apple-system or SF Pro, so Inter renders.
    const rendered = await page.evaluate(() => {
      document.body.style.fontFamily = 'var(--bs-body-font-family)';
      return document.fonts.check('16px ' + getComputedStyle(document.body).fontFamily);
    });
    expect(rendered).toBe(true);
  }
});

test('desktop navbar shrinks to a pill on scroll down', async ({ page }) => {
  await page.setViewportSize({ width: 1280, height: 800 });
  await boot(page, { 'nav-pill': 'true', 'nav-morph': 'true' });
  await page.addStyleTag({ path: path.resolve(__dirname, '../../../python/src/shinyglass/static/glass-rules-light.css') });
  for (let y = 100; y <= 900; y += 200) {
    await page.evaluate((v) => window.scrollTo(0, v), y);
    await page.waitForTimeout(80);
  }
  await expect.poll(() => page.evaluate(() => document.body.classList.contains('glass-nav-compact'))).toBe(true);
  await expect.poll(() => page.evaluate(() => parseFloat(getComputedStyle(document.getElementById('bar')).borderTopLeftRadius))).toBeGreaterThan(100);
  const w = await page.evaluate(() => document.getElementById('bar').getBoundingClientRect().width);
  expect(w).toBeLessThan(1280 - 100);
});
