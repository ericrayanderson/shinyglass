const { test, expect } = require('@playwright/test');
test.skip(!process.env.RUN_SHINY_TESTS, 'Enable RUN_SHINY_TESTS=1 with R installed');

async function ready(page, variant = 'glass') {
  await page.goto(`http://127.0.0.1:3941/?variant=${variant}`);
  await expect(page.locator('#plot img')).toBeVisible();
  await expect(page.locator('#module-value')).toHaveText('0.25');
  await page.waitForFunction(() => !document.documentElement.classList.contains('shiny-busy'));
}

test('module slider initialization, keyboard input, server updates and dynamic insertion', async ({ page }) => {
  await ready(page);
  const slider = page.locator('#module-intensity');
  await expect(slider).toHaveValue('0.25');
  await slider.focus();
  await page.keyboard.press('ArrowRight');
  await expect(page.locator('#module-value')).toHaveText('0.26');
  await expect(slider).toHaveAttribute('aria-valuetext', '26% intensity');
  expect(await slider.evaluate(el => getComputedStyle(el.closest('.glass-intensity-slider')).outlineStyle)).toBe('solid');
  await page.getByRole('button', { name: 'Server update', exact: true }).click();
  await expect(slider).toHaveValue('0.8');
  await expect(page.locator('#resolved')).toHaveText('dark');
  await page.getByRole('button', { name: 'Insert slider', exact: true }).click();
  await expect(page.locator('#inserted1')).toHaveValue('0.6');
  await expect(slider).toHaveValue('0.6');
  await expect(page.locator('#inserted1')).toHaveAccessibleName('Liquid Glass intensity');
});

test('preset changes redraw the plot once; intensity does not redraw it', async ({ page }) => {
  await page.emulateMedia({ colorScheme: 'light' });
  await ready(page);
  await page.waitForTimeout(700);
  const before = Number(await page.locator('#render_count').textContent());
  await page.locator('#module-mode_dark').click();
  await expect(page.locator('#resolved')).toHaveText('dark');
  await expect(page.locator('#render_count')).toHaveText(String(before + 1));
  await page.locator('#module-mode_dark').click();
  await page.locator('#module-intensity').focus();
  await page.keyboard.press('End');
  await page.waitForTimeout(700);
  await expect(page.locator('#render_count')).toHaveText(String(before + 1));
});

test('actual new-session WebSocket reconnect preserves controls and server communication', async ({ page }) => {
  await ready(page);
  await page.evaluate(() => {
    window.reconnections = 0;
    $(document).on('shiny:connected.test', () => { window.reconnections++; });
    Shiny.shinyapp.$socket.close();
  });
  await expect.poll(() => page.evaluate(() => window.reconnections), { timeout: 20000 }).toBeGreaterThan(0);
  await page.getByRole('button', { name: 'Server update', exact: true }).click();
  await expect(page.locator('#module-intensity')).toHaveValue('0.8');
  await expect(page.locator('#resolved')).toHaveText('dark');
});

test('ambient motion opt-out and OS preferences update live', async ({ page }) => {
  await ready(page, 'static');
  expect(await page.locator('.card').first().evaluate(el => getComputedStyle(el).animationName)).toBe('none');
  await ready(page, 'glass');
  await page.mouse.move(0, 0);
  expect(await page.locator('.card').first().evaluate(el => getComputedStyle(el).animationName)).toBe('glass-ambient-specular');
  await page.emulateMedia({ reducedMotion: 'reduce' });
  expect(await page.locator('.card').first().evaluate(el => getComputedStyle(el).animationName)).toBe('none');
  const cdp = await page.context().newCDPSession(page);
  const fill = () => page.evaluate(() => document.documentElement.style.getPropertyValue('--glass-bg'));
  const original = await fill();
  await cdp.send('Emulation.setEmulatedMedia', { features: [
    { name: 'prefers-reduced-motion', value: 'reduce' },
    { name: 'prefers-reduced-transparency', value: 'reduce' }
  ] });
  await expect.poll(fill).not.toBe(original);
  await expect(page.locator('#module-intensity')).toHaveValue('0.25');
  await cdp.send('Emulation.setEmulatedMedia', { features: [] });
  await expect.poll(fill).toBe(original);
});
