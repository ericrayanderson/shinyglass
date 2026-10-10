const { test, expect } = require('@playwright/test');
const path = require('node:path');
const runtime = path.resolve(__dirname, '../../js/shiny-glass.js');
const motion = path.resolve(__dirname, '../../js/glass-ios27.js');

async function boot(page) {
  await page.emulateMedia({ colorScheme: 'light', reducedMotion: 'no-preference' });
  await page.route('http://glass.test/**', (route) =>
    route.fulfill({
      contentType: 'text/html',
      body: '<!DOCTYPE html><html><body></body></html>',
    })
  );
  await page.goto('http://glass.test/app');
  await page.setContent(`<html><body style="min-height:2400px">
    <div class="nav nav-pills" id="pills">
      <a class="nav-link active" id="tab-a" href="#a">One</a>
      <a class="nav-link" id="tab-b" href="#b">Two</a>
    </div>
    <button class="btn btn-secondary" id="go" type="button">Go</button>
    <input id="name" class="form-control" />
    <select id="pet"><option value="a">A</option><option value="b">B</option></select>
    <div class="card" id="lens" style="width:240px;height:120px;border-radius:24px"></div>
    <div id="clicks">0</div>
  </body></html>`);
  await page.addScriptTag({ path: require.resolve('jquery') });
  await page.evaluate(() => {
    window.sent = [];
    window.handlers = {};
    window.Shiny = {
      setInputValue: (name, value, options) => sent.push({ name, value, options }),
      addCustomMessageHandler: (name, handler) => { handlers[name] = handler; }
    };
    document.getElementById('go').addEventListener('click', () => {
      const n = document.getElementById('clicks');
      n.textContent = String(Number(n.textContent) + 1);
    });
  });
  await page.addScriptTag({ path: runtime });
  await page.addScriptTag({ path: motion });
  await page.evaluate(() => new Promise(resolve => $(resolve)));
}

test('displacement map bends more at the rim than in the flat interior', async ({ page }) => {
  await boot(page);
  const stats = await page.evaluate(() => shinyglass._buildDisplacementMap(240, 120, 28));
  expect(stats.rimDelta).toBeGreaterThan(stats.centerDelta);
  expect(stats.centerDelta).toBeLessThan(8);
  expect(stats.url.startsWith('data:image/png')).toBe(true);
});

test('Chromium attaches a cached lens and the fallback path does not', async ({ page }) => {
  await boot(page);
  await page.evaluate(() => {
    window.__shinyglassForceRefractionSupport = true;
    window.__shinyglassForceDispersion = false;
    shinyglass.setRefraction(true);
  });
  await expect.poll(() => page.locator('#lens.glass-refract').count()).toBe(1);
  await expect.poll(() => page.locator('#shinyglass-refract-svg').count()).toBe(1);
  const first = await page.evaluate(() => document.getElementById('lens').dataset.glassRefractKey);
  await page.evaluate(() => shinyglass._scheduleIos27());
  await page.waitForTimeout(50);
  const second = await page.evaluate(() => document.getElementById('lens').dataset.glassRefractKey);
  expect(second).toBe(first);

  await page.evaluate(() => {
    window.__shinyglassForceRefractionSupport = false;
    shinyglass.setRefraction(true);
  });
  await expect.poll(() => page.locator('.glass-refract').count()).toBe(0);
  expect(await page.evaluate(() => document.documentElement.dataset.glassRefractionSupport)).toBe('false');
});

test('low-tier devices skip chromatic dispersion', async ({ page }) => {
  await boot(page);
  await page.evaluate(() => {
    window.__shinyglassForceRefractionSupport = true;
    window.__shinyglassForceLowTier = true;
    window.__shinyglassForceDispersion = false;
    shinyglass.setRefraction(true);
  });
  await expect.poll(() => page.locator('#shinyglass-refract-svg feDisplacementMap').count()).toBeGreaterThan(0);
  expect(await page.locator('#shinyglass-refract-svg feColorMatrix').count()).toBe(0);
  await page.evaluate(() => {
    window.__shinyglassForceDispersion = true;
    document.getElementById('lens').removeAttribute('data-glass-refract-key');
    shinyglass.setRefraction(true);
  });
  await expect.poll(() => page.locator('#shinyglass-refract-svg feColorMatrix').count()).toBeGreaterThan(0);
});

test('active pill indicator moves and clicks still land', async ({ page }) => {
  await boot(page);
  await expect.poll(() => page.locator('.glass-morph-indicator').count()).toBe(1);
  const before = await page.locator('.glass-morph-indicator').evaluate((el) => el.style.transform);
  await page.evaluate(() => {
    document.getElementById('tab-a').classList.remove('active');
    document.getElementById('tab-b').classList.add('active');
  });
  await expect.poll(() => page.locator('.glass-morph-indicator').evaluate((el) => el.style.transform)).not.toBe(before);
  await page.locator('#go').dispatchEvent('pointerdown', { clientX: 6, clientY: 6, button: 0 });
  expect(await page.locator('#go').evaluate((el) => el.style.scale)).toBe('0.965');
  await page.locator('#go').dispatchEvent('pointerup', { clientX: 6, clientY: 6, button: 0 });
  await page.locator('#name').fill('Ada');
  await page.locator('#pet').selectOption('b');
  await page.locator('#go').click();
  await expect(page.locator('#name')).toHaveValue('Ada');
  await expect(page.locator('#pet')).toHaveValue('b');
  await expect(page.locator('#clicks')).toHaveText('1');
});

test('reduced motion skips press springs and tab shrinking', async ({ page }) => {
  await boot(page);
  await page.emulateMedia({ reducedMotion: 'reduce' });
  await page.locator('#go').dispatchEvent('pointerdown', { clientX: 8, clientY: 8, button: 0 });
  expect(await page.locator('#go').evaluate((el) => el.style.scale)).toBe('');
  await page.evaluate(() => window.scrollTo(0, 800));
  await page.waitForTimeout(50);
  expect(await page.evaluate(() => document.body.classList.contains('glass-tabs-min'))).toBe(false);
});

test('scroll edge and tab minimize follow scroll, and inputs keep working', async ({ page }) => {
  await boot(page);
  await page.evaluate(() => {
    document.documentElement.dataset.glassScrollEdge = 'true';
    document.documentElement.dataset.glassMinimizeTabs = 'true';
    document.body.classList.add('nav-pills');
  });
  await page.evaluate(() => window.scrollTo(0, 700));
  await expect.poll(() => page.evaluate(() => document.body.classList.contains('glass-scroll-edge'))).toBe(true);
  await expect.poll(() => page.evaluate(() => document.body.classList.contains('glass-tabs-min'))).toBe(true);
  await page.locator('#pills').click();
  await expect.poll(() => page.evaluate(() => document.body.classList.contains('glass-tabs-min'))).toBe(false);
  await page.locator('#name').fill('still here');
  await expect(page.locator('#name')).toHaveValue('still here');
});
