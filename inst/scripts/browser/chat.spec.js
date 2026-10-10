const { test, expect } = require('@playwright/test');

test.skip(!process.env.RUN_CHAT_TESTS, 'Enable RUN_CHAT_TESTS=1 with shinychat installed');

const BASE = process.env.CHAT_URL || 'http://127.0.0.1:3943/';

async function gotoChat(page) {
  await page.goto(BASE, { waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => window.Shiny && Shiny.shinyapp && Shiny.shinyapp.isConnected());
  await expect(page.locator('.shiny-chat-input .tiptap, .ProseMirror').first()).toBeVisible();
}

test.describe.configure({ mode: 'serial', timeout: 90000 });

test('page chat loads with glass chrome and a floating composer', async ({ page }) => {
  const pageErrors = [];
  page.on('pageerror', (err) => pageErrors.push(String(err)));
  await gotoChat(page);
  await expect(page.locator('html')).toHaveAttribute('data-glass-refraction', 'true');
  await expect(page.locator('html')).toHaveAttribute('data-glass-morph', 'true');
  await expect(page.locator('html')).toHaveAttribute('data-glass-press', 'true');
  await expect(page.locator('html')).toHaveAttribute('data-glass-scroll-edge', 'true');

  const header = page.locator('.shiny-chat-page-header');
  const sidebar = page.locator('.shiny-chat-page-sidebar');
  const composer = page.locator('.shiny-chat-input .tiptap').first();
  await expect(header).toBeVisible();
  await expect(sidebar).toBeVisible();
  await expect(page.getByText('Glass notes').first()).toBeVisible();

  const blur = await composer.evaluate((el) => getComputedStyle(el).backdropFilter || '');
  expect(blur).toContain('blur');
  const radius = await composer.evaluate((el) => parseFloat(getComputedStyle(el).borderTopLeftRadius));
  expect(radius).toBeGreaterThan(16);
  const headerBlur = await header.evaluate((el) => getComputedStyle(el).backdropFilter || '');
  expect(headerBlur).toContain('blur');

  expect(pageErrors, pageErrors.join('\n')).toEqual([]);
});

test('echo, thinking, citation, tool card, and slash menu stay interactive', async ({ page }) => {
  await gotoChat(page);
  const composer = page.locator('.shiny-chat-input .tiptap').first();
  await composer.click();
  await page.keyboard.type('tide line');
  await page.keyboard.press('Enter');
  await expect(page.getByText('Echo: tide line').first()).toBeVisible({ timeout: 15000 });
  await expect(page.locator('.shiny-chat-thinking').first()).toBeVisible();
  const citation = page.locator('.shiny-aside-pill').first();
  await expect(citation).toBeVisible();
  await expect(page.getByRole('button', { name: 'Field log' }).first()).toBeVisible();
  const citationBg = await citation.evaluate((el) => getComputedStyle(el).backgroundColor);
  expect(citationBg).not.toBe('rgba(0, 0, 0, 0)');

  await page.locator('#show_sample').click();
  await expect(page.getByText('Read the tide table').first()).toBeVisible({ timeout: 10000 });
  await expect(page.locator('.shiny-tool-card, .shiny-chat-tool-call-row, .shiny-chat-tool-group').first()).toBeVisible();
  await expect(page.getByText('1.4 m').first()).toBeVisible();

  await composer.click();
  await page.keyboard.type('/');
  const palette = page.locator('.shiny-chat-slash-palette');
  await expect(palette).toBeVisible();
  await expect(palette).toContainText('note');
  const z = await palette.evaluate((el) => Number(getComputedStyle(el).zIndex) || 0);
  expect(z).toBeGreaterThan(1000);
  await page.keyboard.press('Escape');
});

test('embedded chat_ui and artifact preview use the glass pack', async ({ page }) => {
  await gotoChat(page);
  await page.getByRole('link', { name: 'Preview' }).or(page.getByRole('button', { name: 'Preview' })).first().click();
  const preview = page.locator('#artifact_preview');
  await expect(preview).toBeVisible();
  const previewBg = await preview.evaluate((el) => getComputedStyle(el).backgroundColor);
  expect(previewBg).not.toBe('rgba(0, 0, 0, 0)');

  await page.getByRole('link', { name: 'Embed' }).or(page.getByRole('button', { name: 'Embed' })).first().click();
  const embed = page.locator('#embed .tiptap, shiny-chat-container#embed .tiptap').first();
  await expect(embed).toBeVisible();
  await embed.click();
  await page.keyboard.type('buoy');
  await page.keyboard.press('Enter');
  await expect(page.getByText('Embed echo: buoy')).toBeVisible({ timeout: 10000 });
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
