const { test, expect } = require('@playwright/test');
const path = require('node:path');
const runtime = path.resolve(__dirname, '../../js/shiny-glass.js');

async function setMediaFeatures(page, features) {
  const client = await page.context().newCDPSession(page);
  await client.send('Emulation.setEmulatedMedia', { features });
}

async function boot(page, beforeScript) {
  await page.route('http://glass.test/**', (route) =>
    route.fulfill({
      contentType: 'text/html',
      body: '<!DOCTYPE html><html><body></body></html>',
    })
  );
  await page.goto('http://glass.test/app');
  await page.setContent(`<!DOCTYPE html>
    <html data-glass-mode="light" data-glass-preset="light" data-glass-tint="false">
      <head>
        <style>
          :root[data-glass-contrast="more"] { --glass-border: rgba(29, 29, 31, 0.72) !important; }
          :root[data-glass-reduced-transparency="reduce"] {
            --glass-bg: #f5f5f7 !important;
            --glass-blur: 0px !important;
          }
          :root[data-glass-forced-colors="active"] {
            --glass-bg: Canvas !important;
            --glass-blur: 0px !important;
            --glass-border: ButtonBorder !important;
          }
        </style>
      </head>
      <body>
        <div class="glass-intensity-slider">
          <input aria-label="Intensity" type="range" min="0" max="1" step="0.01" class="glass-intensity-range">
        </div>
      </body>
    </html>`);
  if (beforeScript) await beforeScript(page);
  await page.addScriptTag({ path: require.resolve('jquery') });
  await page.evaluate(() => {
    window.sent = [];
    window.handlers = {};
    window.Shiny = {
      setInputValue: (name, value, options) => sent.push({ name, value, options }),
      addCustomMessageHandler: (name, handler) => { handlers[name] = handler; }
    };
  });
  await page.addScriptTag({ path: runtime });
  await page.evaluate(() => new Promise((resolve) => { window.jQuery(resolve); }));
}

test('default intensity is the iOS 27 midpoint', async ({ page }) => {
  await boot(page);
  expect(await page.evaluate(() => window.shinyglass.getIntensity())).toBe(0.5);
  await expect(page.getByRole('slider', { name: 'Intensity' })).toHaveValue('0.5');
  const bg = await page.evaluate(() =>
    document.documentElement.style.getPropertyValue('--glass-bg')
  );
  expect(bg).toContain('0.3000');
});

test('material clear maps to a low intensity and a later setIntensity wins', async ({ page }) => {
  await boot(page);
  const messages = [];
  page.on('console', (msg) => messages.push(msg.text()));
  await page.evaluate(() => window.shinyglass.setMaterial('clear'));
  expect(await page.evaluate(() => window.shinyglass.getMaterial())).toBe('clear');
  expect(await page.evaluate(() => window.shinyglass.getIntensity())).toBe(0.12);
  const clearBg = await page.evaluate(() =>
    document.documentElement.style.getPropertyValue('--glass-bg')
  );
  expect(clearBg).not.toContain('0.3000');
  await page.evaluate(() => window.shinyglass.setIntensity(0.5));
  expect(await page.evaluate(() => window.shinyglass.getIntensity())).toBe(0.5);
  expect(await page.evaluate(() => window.shinyglass.getMaterial())).toBe('clear');
  expect(messages.some((text) => /deprecated/i.test(text))).toBe(true);
});

test('prefers-contrast more applies a high-contrast border that beats a weak inline value', async ({ page }) => {
  await boot(page);
  await setMediaFeatures(page, [
    { name: 'prefers-color-scheme', value: 'light' },
    { name: 'prefers-contrast', value: 'more' },
  ]);
  await expect(page.locator('html')).toHaveAttribute('data-glass-contrast', 'more');
  await page.evaluate(() => {
    document.documentElement.style.setProperty('--glass-border', 'rgba(255, 255, 255, 0.1)');
  });
  const border = await page.evaluate(() =>
    getComputedStyle(document.documentElement).getPropertyValue('--glass-border')
  );
  expect(border).toContain('29, 29, 31');
  expect(border).not.toContain('0.1');
});

test('forced-colors active clears blur and uses system colors', async ({ page }) => {
  await boot(page, (p) => setMediaFeatures(p, [
    { name: 'forced-colors', value: 'active' },
  ]));
  await expect(page.locator('html')).toHaveAttribute('data-glass-forced-colors', 'active');
  const inline = await page.evaluate(() => ({
    bg: document.documentElement.style.getPropertyValue('--glass-bg'),
    blur: document.documentElement.style.getPropertyValue('--glass-blur'),
    border: document.documentElement.style.getPropertyValue('--glass-border'),
  }));
  expect(inline.bg).toBe('Canvas');
  expect(inline.blur).toBe('0px');
  expect(inline.border).toBe('ButtonBorder');
  const computedBlur = await page.evaluate(() =>
    getComputedStyle(document.documentElement).getPropertyValue('--glass-blur').trim()
  );
  expect(computedBlur).toBe('0px');
});

test('reduced transparency is a solid fill with no blur, including live changes', async ({ page }) => {
  await boot(page);
  expect(await page.evaluate(() =>
    document.documentElement.dataset.glassReducedTransparency || ''
  )).toBe('');
  await setMediaFeatures(page, [
    { name: 'prefers-color-scheme', value: 'light' },
    { name: 'prefers-reduced-transparency', value: 'reduce' },
  ]);
  await expect(page.locator('html')).toHaveAttribute('data-glass-reduced-transparency', 'reduce');
  await page.evaluate(() => {
    document.documentElement.style.setProperty('--glass-bg', 'rgba(255, 255, 255, 0.22)');
    document.documentElement.style.setProperty('--glass-blur', '40px');
  });
  const painted = await page.evaluate(() => {
    const cs = getComputedStyle(document.documentElement);
    return {
      bg: cs.getPropertyValue('--glass-bg').replace(/\s/g, '').toLowerCase(),
      blur: cs.getPropertyValue('--glass-blur').trim(),
    };
  });
  expect(painted.blur).toBe('0px');
  expect(painted.bg === '#f5f5f7' || painted.bg === 'rgb(245,245,247)').toBe(true);
  expect(await page.evaluate(() => window.shinyglass.getIntensity())).toBe(0.5);
});
