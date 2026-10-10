const { test, expect } = require('@playwright/test');

test.skip(!process.env.RUN_CHAT_TESTS, 'Enable RUN_CHAT_TESTS=1 with shinychat installed');

const BASE = process.env.CHAT_URL || 'http://127.0.0.1:3943/';

async function gotoChat(page) {
  await page.goto(BASE, { waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => window.Shiny && Shiny.shinyapp && Shiny.shinyapp.isConnected());
  await expect(page.locator('.shiny-chat-input .tiptap, .ProseMirror').first()).toBeVisible();
}

test.describe.configure({ mode: 'serial', timeout: 90000 });

test('harbor notes loads on dusk glass with a floating composer', async ({ page }) => {
  const pageErrors = [];
  page.on('pageerror', (err) => pageErrors.push(String(err)));
  await gotoChat(page);
  await expect(page.locator('html')).toHaveAttribute('data-glass-refraction', 'true');
  await expect(page.locator('html')).toHaveAttribute('data-glass-morph', 'true');
  await expect(page.locator('html')).toHaveAttribute('data-glass-press', 'true');
  await expect(page.locator('html')).toHaveAttribute('data-glass-scroll-edge', 'true');
  await expect(page.locator('html')).toHaveAttribute('data-glass-scene', 'dusk');

  const header = page.locator('.shiny-chat-page-header');
  const sidebar = page.locator('.shiny-chat-page-sidebar');
  const composer = page.locator('.shiny-chat-input .tiptap').first();
  await expect(header).toBeVisible();
  await expect(sidebar).toBeVisible();
  await expect(page.getByText('Harbor notes').first()).toBeVisible();
  await expect(page.locator('.suggestion').first()).toBeVisible();

  const scene = await page.evaluate(() => getComputedStyle(document.documentElement).getPropertyValue('--glass-page-bg') || '');
  expect(scene).toContain('gradient');
  const blur = await composer.evaluate((el) => getComputedStyle(el).backdropFilter || '');
  expect(blur).toContain('blur');
  const radius = await composer.evaluate((el) => parseFloat(getComputedStyle(el).borderTopLeftRadius));
  expect(radius).toBeGreaterThan(16);
  const headerBlur = await header.evaluate((el) => getComputedStyle(el).backdropFilter || '');
  expect(headerBlur).toContain('blur');
  expect(pageErrors, pageErrors.join('\n')).toEqual([]);
});

test('scripted reply streams thinking, a citation, and a tool card', async ({ page }) => {
  await gotoChat(page);
  await page.getByRole('button', { name: /tide at dawn/i }).click();
  await expect(page.getByText('You asked:').first()).toBeVisible({ timeout: 20000 });
  await expect(page.getByText("What's the tide at dawn?").first()).toBeVisible();
  await expect(page.locator('.shiny-chat-thinking').first()).toBeVisible();
  const citation = page.locator('.shiny-aside-pill').first();
  await expect(citation).toBeVisible({ timeout: 20000 });
  await expect(page.getByRole('button', { name: 'Field log' }).first()).toBeVisible();
  await expect(page.getByText('Read the tide table').first()).toBeVisible({ timeout: 20000 });
  await expect(page.locator('.shiny-tool-card, .shiny-chat-tool-call-row, .shiny-chat-tool-group').first()).toBeVisible();
  await expect(page.getByText('1.4 m').first()).toBeVisible();

  const composer = page.locator('.shiny-chat-input .tiptap').first();
  await composer.click();
  await page.keyboard.type('/');
  const palette = page.locator('.shiny-chat-slash-palette');
  await expect(palette).toBeVisible();
  await expect(palette).toContainText('note');
  const z = await palette.evaluate((el) => Number(getComputedStyle(el).zIndex) || 0);
  expect(z).toBeGreaterThan(1000);
  await page.keyboard.press('Escape');
});

test('offcanvas morphs in, stays glassy, and shows a scroll edge', async ({ page }) => {
  await gotoChat(page);
  await page.locator('#open_sources').click();
  const panel = page.locator('#sources_panel.offcanvas, .offcanvas.show').first();
  await expect(panel).toBeVisible();
  await expect(panel).toContainText('Citations stay');
  const filter = await panel.evaluate((el) => getComputedStyle(el).backdropFilter || '');
  expect(filter).toContain('blur');
  const origin = await panel.evaluate((el) => el.style.transformOrigin || getComputedStyle(el).transformOrigin);
  expect(origin.length).toBeGreaterThan(0);

  await page.locator('#sources_panel .offcanvas-body').evaluate((el) => {
    el.scrollTop = 200;
    el.dispatchEvent(new Event('scroll', { bubbles: true }));
  });
  await expect(panel).toHaveClass(/glass-scroll-edge/);

  await page.locator('#sources_panel .btn-close').click();
  await expect(panel).toBeHidden();
});

test('phone width keeps the composer on screen', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await gotoChat(page);
  const composer = page.locator('.shiny-chat-input .tiptap').first();
  await expect(composer).toBeVisible();
  const overflow = await page.evaluate(() => (
    document.documentElement.scrollWidth - document.documentElement.clientWidth
  ));
  expect(overflow).toBeLessThanOrEqual(2);
  const box = await composer.boundingBox();
  expect(box.width).toBeGreaterThan(200);
  expect(box.x).toBeGreaterThanOrEqual(0);
  expect(box.x + box.width).toBeLessThanOrEqual(392);
});
