const { test, expect } = require('@playwright/test');
const path = require('node:path');
const runtime = path.resolve(__dirname, '../../js/shiny-glass.js');

async function boot(page, mode = 'light') {
  await page.emulateMedia({ colorScheme: 'light' });
  // about:blank is an opaque origin, so localStorage throws SecurityError.
  await page.route('http://glass.test/**', (route) =>
    route.fulfill({
      contentType: 'text/html',
      body: '<!DOCTYPE html><html><body></body></html>',
    })
  );
  await page.goto('http://glass.test/app');
  await page.setContent(`<html data-glass-mode="${mode}" data-glass-preset="light" data-glass-tint="false"><body>
    <div class="glass-theme-toggle">${['light', 'dark', 'auto'].map(m => `<button data-glass-preset-mode="${m}">${m}</button>`).join('')}</div>
    <div id="dynamic"></div></body></html>`);
  await page.addScriptTag({ path: require.resolve('jquery') });
  // A recording transport: these tests exercise the real runtime, not an R server.
  await page.evaluate(() => {
    window.sent = [];
    window.handlers = {};
    window.Shiny = {
      setInputValue: (name, value, options) => sent.push({ name, value, options }),
      addCustomMessageHandler: (name, handler) => { handlers[name] = handler; }
    };
  });
  await page.addScriptTag({ path: runtime });
  await page.evaluate(() => new Promise(resolve => $(resolve)));
}

test('initial Auto follows OS changes; explicit presets detach from OS', async ({ page }) => {
  await boot(page, 'auto');
  await page.emulateMedia({ colorScheme: 'dark' });
  await expect(page.locator('html')).toHaveAttribute('data-glass-preset', 'dark');
  await page.getByRole('button', { name: 'light', exact: true }).click();
  await page.emulateMedia({ colorScheme: 'light' });
  await page.emulateMedia({ colorScheme: 'dark' });
  await expect(page.locator('html')).toHaveAttribute('data-glass-preset', 'light');
  await page.getByRole('button', { name: 'auto', exact: true }).click();
  await expect(page.locator('html')).toHaveAttribute('data-glass-preset', 'dark');
});

test('first explicit slider value wins and restricted controls display clamped values', async ({ page }) => {
  await boot(page);
  await page.evaluate(() => {
    document.querySelector('#dynamic').innerHTML = `
      <div class="glass-intensity-slider" data-glass-initial-intensity="0.8"><input id="explicit" type="range" min="0" max="1" step="0.01" class="glass-intensity-range"></div>
      <div class="glass-intensity-slider" data-glass-initial-intensity="0.2"><input id="second" type="range" min="0" max="1" step="0.01" class="glass-intensity-range"></div>
      <div class="glass-intensity-slider"><input id="restricted" type="range" min="0.2" max="0.6" step="0.01" class="glass-intensity-range"></div>`;
  });
  await expect(page.locator('#explicit')).toHaveValue('0.8');
  await expect(page.locator('#second')).toHaveValue('0.8');
  await expect(page.locator('#restricted')).toHaveValue('0.6');
  expect(await page.evaluate(() => shinyglass.getIntensity())).toBe(0.8);
  await page.locator('#restricted').focus();
  await page.keyboard.press('Home');
  await expect(page.locator('#explicit')).toHaveValue('0.2');
  await expect(page.locator('#restricted')).toHaveAttribute('aria-valuetext', '20% intensity');
});

test('keyboard toggles publish one resolved change despite duplicate server delivery', async ({ page }) => {
  await boot(page);
  await page.getByRole('button', { name: 'dark', exact: true }).focus();
  await page.keyboard.press('Enter');
  await expect(page.getByRole('button', { name: 'dark', exact: true })).toHaveAttribute('aria-pressed', 'true');
  await page.evaluate(() => {
    handlers.shinyglass({ preset: 'dark' });
    handlers.glassPreset('dark');
  });
  const dark = await page.evaluate(() => sent.filter(x => x.name === 'glass_resolved_preset' && x.value === 'dark'));
  expect(dark).toHaveLength(1);
  expect(dark[0].options).toBeUndefined();
});

test('inserted intensity slider responds to keyboard and server updates', async ({ page }) => {
  await boot(page);
  await page.evaluate(() => {
    document.querySelector('#dynamic').innerHTML = '<div class="glass-intensity-slider"><input aria-label="Intensity" type="range" min="0" max="1" step="0.01" class="glass-intensity-range"></div>';
  });
  const slider = page.getByRole('slider', { name: 'Intensity' });
  await expect(slider).toHaveValue('0.45');
  await slider.focus();
  await page.keyboard.press('End');
  await expect.poll(() => page.evaluate(() => shinyglass.getIntensity())).toBe(1);
  await page.evaluate(() => handlers.shinyglass({ intensity: 0, primary: '#AF52DE' }));
  await expect(slider).toHaveValue('0');
  expect(await page.evaluate(() => document.documentElement.style.getPropertyValue('--glass-accent'))).toBe('#af52de');
});

test('reconnect restores message hook and forwards unrelated host messages', async ({ page }) => {
  await boot(page);
  await page.evaluate(() => {
    $(document).trigger('shiny:connected');
    $(document).trigger('shiny:disconnected');
    window.forwarded = [];
    Shiny.oncustommessage = message => forwarded.push(message);
    $(document).trigger('shiny:connected');
    Shiny.oncustommessage({ shinyglass: { preset: 'dark', intensity: 0.8 }, other: 'keep' });
  });
  await expect(page.locator('html')).toHaveAttribute('data-glass-preset', 'dark');
  expect(await page.evaluate(() => shinyglass.getIntensity())).toBe(0.8);
  expect(await page.evaluate(() => forwarded.some(x => x.other === 'keep'))).toBe(true);
});

test('reactive text updates do not sample unchanged media or rewrite widget styles', async ({ page }) => {
  await boot(page);
  await page.evaluate(() => {
    document.querySelector('#dynamic').innerHTML = '<div class="Reactable">table</div><div class="stati"><span class="stati-value">42</span></div><div id="text-output"></div><canvas width="10" height="10"></canvas>';
    const ctx = document.querySelector('canvas').getContext('2d');
    ctx.fillStyle = 'red'; ctx.fillRect(0, 0, 10, 10);
    window.readbacks = 0;
    const original = CanvasRenderingContext2D.prototype.getImageData;
    CanvasRenderingContext2D.prototype.getImageData = function (...args) {
      readbacks++;
      return original.apply(this, args);
    };
    shinyglass.setTint(true);
  });
  await expect.poll(() => page.evaluate(() => readbacks)).toBeGreaterThan(0);
  // Allow the initialization and one coalesced observer frame to settle.
  await page.waitForTimeout(600);
  await page.evaluate(() => {
    window.styleWrites = 0;
    window.beforeReads = readbacks;
    window.styleObserver = new MutationObserver(records => { styleWrites += records.length; });
    for (const widget of document.querySelectorAll('.Reactable, .stati')) {
      styleObserver.observe(widget, { attributes: true, attributeFilter: ['style'], subtree: true });
    }
    const output = document.querySelector('#text-output');
    for (let i = 0; i < 100; i++) {
      output.textContent = String(i);
      $(output).trigger('shiny:value');
    }
  });
  // Exceeds the tint debounce interval: catches delayed work as well.
  await page.waitForTimeout(700);
  expect(await page.evaluate(() => readbacks - beforeReads)).toBe(0);
  expect(await page.evaluate(() => styleWrites)).toBe(0);
  // Genuine widget changes must still be corrected.
  await page.evaluate(() => document.querySelector('.Reactable').style.setProperty('color', 'red', 'important'));
  await expect.poll(() => page.evaluate(() => document.querySelector('.Reactable').style.color)).toBe('inherit');
});

test('persist writes preset and intensity; material and scene update live', async ({ page }) => {
  await boot(page);
  await page.evaluate(() => {
    document.documentElement.dataset.glassPersist = 'true';
    localStorage.clear();
    shinyglass.setPreset('dark');
    shinyglass.setIntensity(0.7);
    shinyglass.setMaterial('clear');
    shinyglass.setScene('dusk');
  });
  await expect.poll(() => page.evaluate(() => document.documentElement.dataset.glassMaterial)).toBe('clear');
  await expect(page.locator('html')).toHaveAttribute('data-glass-scene', 'dusk');
  const stored = await page.waitForFunction(() => {
    const keys = Object.keys(localStorage).filter(k => k.startsWith('shinyglass:'));
    if (!keys.length) return null;
    return JSON.parse(localStorage.getItem(keys[0]));
  });
  const value = await stored.jsonValue();
  expect(value.preset).toBe('dark');
  expect(value.intensity).toBe(0.7);
  expect(value.material).toBe('clear');
  expect(value.scene).toBe('dusk');
});

test('accent wells apply primary immediately', async ({ page }) => {
  await boot(page);
  await page.evaluate(() => {
    document.querySelector('#dynamic').innerHTML = `
      <div class="glass-accent-input" data-glass-accent-input="glass_accent">
        <button class="glass-accent-well" data-glass-primary="#AF52DE" data-glass-accent-input="glass_accent">purple</button>
      </div>`;
  });
  await page.locator('.glass-accent-well').click();
  expect(await page.evaluate(() => shinyglass.getPrimary().toLowerCase())).toBe('#af52de');
  await expect(page.locator('.glass-accent-well')).toHaveClass(/is-selected/);
});

test('pointer highlight layout reads are coalesced within a frame', async ({ page }) => {
  await boot(page);
  await page.evaluate(() => {
    const card = document.createElement('div');
    card.className = 'card';
    document.body.appendChild(card);
    window.layoutReads = 0;
    card.getBoundingClientRect = () => {
      layoutReads++;
      return { left: 0, top: 0, width: 100, height: 100 };
    };
    for (let i = 0; i < 100; i++) {
      card.dispatchEvent(new MouseEvent('mousemove', { bubbles: true, clientX: i, clientY: 20 }));
    }
  });
  await expect.poll(() => page.evaluate(() => layoutReads)).toBe(1);
  expect(await page.evaluate(() => document.querySelector('.card').style.getPropertyValue('--glass-specular-x'))).toBe('99%');
});
