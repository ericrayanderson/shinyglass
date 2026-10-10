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
  await page.getByRole('button', { name: /glass_theme work/i }).click();
  await expect(page.getByText('Liquid Glass bslib theme').first()).toBeVisible({ timeout: 20000 });
  await expect(page.getByText('You asked:')).toHaveCount(0);
  const thinking = page.locator('.shiny-chat-thinking').first();
  const thinkingHeader = page.locator('.shiny-chat-thinking-header').first();
  await expect(thinking).toBeVisible();
  await expect(thinkingHeader).toBeVisible();
  await thinkingHeader.click();
  const opened = await thinkingHeader.getAttribute('aria-expanded');
  await thinkingHeader.click();
  const closed = await thinkingHeader.getAttribute('aria-expanded');
  expect(opened).not.toEqual(closed);
  await expect(thinking).toContainText('theme API');
  await expect(page.locator('#chat-drawer')).toHaveCount(0);
  const citation = page.locator('.shiny-aside-pill').first();
  await expect(citation).toBeVisible({ timeout: 20000 });
  await expect(page.getByRole('button', { name: 'shinyglass docs' }).first()).toBeVisible();
  await expect(page.getByText('Read glass_theme').first()).toBeVisible({ timeout: 20000 });
  await expect(page.locator('.shiny-tool-card, .shiny-chat-tool-call-row, .shiny-chat-tool-group').first()).toBeVisible();
  const history = page.getByRole('region', { name: /conversation history/i });
  await expect(history.getByText('How does glass_theme work?')).toBeVisible();
  await expect(history).not.toContainText('No conversations yet');

  const column = await page.locator('.shiny-chat-messages-content').boundingBox();
  const userBox = await page.locator('.shiny-chat-user-message').first().boundingBox();
  const assistantBox = await page.locator('.shiny-chat-message .shiny-chat-message-content').first().boundingBox();
  expect(assistantBox.x).toBeGreaterThanOrEqual(column.x + 12);
  expect(assistantBox.x).toBeLessThanOrEqual(column.x + 20);
  expect(userBox.x + userBox.width).toBeGreaterThanOrEqual(column.x + column.width - 20);
  expect(userBox.x + userBox.width).toBeLessThanOrEqual(column.x + column.width - 12);

  const bubble = page.locator('.shiny-chat-message .shiny-chat-message-content').first();
  const bubbleStyle = await bubble.evaluate((el) => {
    const cs = getComputedStyle(el);
    return {
      bg: cs.backgroundColor,
      radius: parseFloat(cs.borderTopLeftRadius),
      pad: parseFloat(cs.paddingTop)
    };
  });
  expect(bubbleStyle.bg).not.toBe('rgba(0, 0, 0, 0)');
  expect(bubbleStyle.radius).toBeGreaterThan(12);
  expect(bubbleStyle.pad).toBeGreaterThan(8);

  const composer = page.locator('.shiny-chat-input .tiptap').first();
  await composer.click();
  await page.keyboard.type('/');
  const palette = page.locator('.shiny-chat-slash-palette');
  await expect(palette).toBeVisible();
  await expect(palette).toContainText('note');
  const typed = await composer.innerText();
  expect(typed).toContain('/');
  const slashMark = await composer.evaluate((el) => {
    const node = el.querySelector('.suggestion');
    if (!node) return 'missing';
    return getComputedStyle(node, '::after').content;
  });
  expect(slashMark === 'none' || slashMark === 'normal').toBeTruthy();
  const z = await palette.evaluate((el) => Number(getComputedStyle(el).zIndex) || 0);
  expect(z).toBeGreaterThan(1000);
  await page.keyboard.press('Escape');
});

test('sources panel has an empty state, real citations, and a quiet scrollbar', async ({ page }) => {
  await gotoChat(page);
  await expect(page.locator('.harbor-status')).toContainText(/Live \(Gemini\)|Demo replies/);
  await page.locator('#open_sources').click();
  const panel = page.locator('#sources_panel.offcanvas, .offcanvas.show').first();
  await expect(panel).toBeVisible();
  await expect(panel).toContainText('No sources yet');
  await expect(panel).not.toContainText('Citations stay');
  const filter = await panel.evaluate((el) => getComputedStyle(el).backdropFilter || '');
  expect(filter).toContain('blur');
  const origin = await panel.evaluate((el) => el.style.transformOrigin || getComputedStyle(el).transformOrigin);
  expect(origin.length).toBeGreaterThan(0);
  const idleBar = await page.locator('#sources_panel .offcanvas-body').evaluate((el) => getComputedStyle(el).scrollbarWidth);
  expect(idleBar).toBe('none');

  await page.locator('#sources_panel .btn-close').click();
  await expect(panel).toBeHidden();

  await page.getByRole('button', { name: /glass_theme work/i }).click();
  await expect(page.getByText('Read glass_theme').first()).toBeVisible({ timeout: 20000 });
  await page.locator('#open_sources').click();
  await expect(panel).toBeVisible();
  await expect(panel.locator('a[href*="github.io/shinyglass"]')).toBeVisible();
  await expect(panel.locator('a[href*="human-interface-guidelines"]')).toBeVisible();
  await expect(panel.locator('a[href*="shiny.posit.co"]')).toBeVisible();

  await page.locator('#sources_panel .offcanvas-body').evaluate((el) => {
    el.style.maxHeight = '140px';
  });
  await expect(page.locator('#sources_panel .offcanvas-body')).toHaveClass(/glass-overflowing/, { timeout: 5000 });
  const liveBar = await page.locator('#sources_panel .offcanvas-body').evaluate((el) => getComputedStyle(el).scrollbarWidth);
  expect(liveBar).toBe('thin');
  await page.locator('#sources_panel .offcanvas-body').evaluate((el) => {
    el.scrollTop = 80;
    el.dispatchEvent(new Event('scroll', { bubbles: true }));
  });
  await expect(panel).toHaveClass(/glass-scroll-edge/);

  await page.locator('#sources_panel .btn-close').click();
  await expect(panel).toBeHidden();
});

test('a long transcript fades under the header and the composer', async ({ page }) => {
  await gotoChat(page);
  await page.getByRole('button', { name: /glass_theme work/i }).click();
  await expect(page.getByText('Read glass_theme').first()).toBeVisible({ timeout: 20000 });
  for (let i = 0; i < 3; i += 1) {
    await page.evaluate((n) => {
      window.Shiny.setInputValue(
        'chat_user_input',
        { text: 'Another harbor note ' + n + ' about shinyglass and the tide.' },
        { priority: 'event' }
      );
    }, i);
    await page.waitForTimeout(350);
  }
  // Wait until the extra notes are tall enough to scroll, then move the
  // transcript. A still-streaming reply stays one short row.
  await expect.poll(async () => page.locator('.shiny-chat-messages').evaluate((el) => {
    if (el.scrollHeight <= el.clientHeight + 40) return 0;
    el.scrollTop = 160;
    el.dispatchEvent(new Event('scroll', { bubbles: true }));
    return el.scrollTop;
  }), { timeout: 20000 }).toBeGreaterThan(8);
  await expect(page.locator('.shiny-chat-page-header')).toHaveClass(/glass-scroll-edge/);
  await expect(page.locator('.shiny-chat-composer')).toHaveClass(/glass-scroll-edge/);
  await expect(page.locator('.shiny-chat-messages')).toHaveClass(/glass-scroll-edge-top/);
  const mask = await page.locator('.shiny-chat-messages').evaluate((el) => (
    getComputedStyle(el).maskImage || getComputedStyle(el).webkitMaskImage || ''
  ));
  expect(mask).not.toBe('none');
  expect(mask.length).toBeGreaterThan(8);
});

test('coarse pointers keep 44px chat targets', async ({ browser }) => {
  const context = await browser.newContext({
    viewport: { width: 393, height: 852 },
    isMobile: true,
    hasTouch: true,
    deviceScaleFactor: 2
  });
  const page = await context.newPage();
  await gotoChat(page);
  const send = await page.locator('.shiny-chat-btn-send').first().boundingBox();
  const composer = await page.locator('.shiny-chat-input .tiptap').first().boundingBox();
  expect(send.width).toBeGreaterThanOrEqual(44);
  expect(send.height).toBeGreaterThanOrEqual(44);
  expect(composer.height).toBeGreaterThanOrEqual(44);
  const rightGap = (composer.x + composer.width) - (send.x + send.width);
  const bottomGap = (composer.y + composer.height) - (send.y + send.height);
  const topGap = send.y - composer.y;
  expect(send.x).toBeGreaterThanOrEqual(composer.x + 2);
  expect(rightGap).toBeGreaterThanOrEqual(2);
  expect(topGap).toBeGreaterThanOrEqual(2);
  expect(bottomGap).toBeGreaterThanOrEqual(2);
  expect(Math.abs(rightGap - bottomGap)).toBeLessThan(3);
  await page.getByRole('button', { name: /glass_theme work/i }).click();
  await expect(page.locator('.shiny-chat-user-message').first()).toBeVisible({ timeout: 20000 });
  const edit = page.locator('.shiny-chat-edit-btn').first();
  await expect(edit).toBeVisible();
  const editBox = await edit.boundingBox();
  expect(editBox.width).toBeGreaterThanOrEqual(44);
  expect(editBox.height).toBeGreaterThanOrEqual(44);
  const userBox = await page.locator('.shiny-chat-user-message').first().boundingBox();
  const assistantBox = await page.locator('.shiny-chat-message .shiny-chat-message-content').first().boundingBox();
  expect(assistantBox.x).toBeGreaterThanOrEqual(12);
  expect(393 - (userBox.x + userBox.width)).toBeGreaterThanOrEqual(12);

  const messages = await page.locator('.shiny-chat-messages').boundingBox();
  const content = await page.locator('.shiny-chat-messages-content').boundingBox();
  const composerCol = await page.locator('.shiny-chat-composer').boundingBox();
  expect(messages.x).toBeGreaterThanOrEqual(-1);
  expect(messages.x + messages.width).toBeLessThanOrEqual(394);
  expect(content.x + content.width).toBeLessThanOrEqual(394);
  expect(Math.abs(content.x - composerCol.x)).toBeLessThanOrEqual(2);
  expect(Math.abs((content.x + content.width) - (composerCol.x + composerCol.width))).toBeLessThanOrEqual(2);

  const overflow = await page.evaluate(() => (
    document.documentElement.scrollWidth - document.documentElement.clientWidth
  ));
  expect(overflow).toBeLessThanOrEqual(2);

  for (let i = 0; i < 4; i += 1) {
    await page.evaluate((n) => {
      window.Shiny.setInputValue(
        'chat_user_input',
        { text: 'Another harbor note ' + n + ' about shinyglass and the tide.' },
        { priority: 'event' }
      );
    }, i);
    await page.waitForTimeout(200);
  }
  await expect.poll(async () => page.locator('.shiny-chat-messages').evaluate((el) => {
    if (el.scrollHeight <= el.clientHeight + 40) return 0;
    el.scrollTop = 80;
    el.dispatchEvent(new Event('scroll', { bubbles: true }));
    return el.scrollTop;
  }), { timeout: 20000 }).toBeGreaterThan(8);
  const jump = page.locator('.shiny-chat-scroll-to-bottom').first();
  await expect(jump).toBeVisible();
  const jumpBox = await jump.boundingBox();
  expect(jumpBox.width).toBeGreaterThanOrEqual(44);
  expect(jumpBox.height).toBeGreaterThanOrEqual(44);
  await context.close();
});

test('theme and the conversation stay after reload', async ({ page }) => {
  await gotoChat(page);
  const toggle = page.locator('bslib-input-dark-mode');
  await toggle.click();
  await expect(page.locator('html')).toHaveAttribute('data-glass-preset', 'dark', { timeout: 5000 });
  await page.getByRole('button', { name: /glass_theme work/i }).click();
  await expect(page.getByText('Liquid Glass bslib theme').first()).toBeVisible({ timeout: 20000 });
  await page.reload({ waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => window.Shiny && Shiny.shinyapp && Shiny.shinyapp.isConnected());
  await expect(page.locator('html')).toHaveAttribute('data-glass-preset', 'dark');
  await expect(page.getByText('Liquid Glass bslib theme').first()).toBeVisible({ timeout: 20000 });
  await expect(page.locator('.harbor-status')).toBeVisible();
});

test('staged favicon is inline and the files answer 200', async ({ page, request }) => {
  await gotoChat(page);
  const href = await page.locator('link[rel="icon"]').first().getAttribute('href');
  expect(href.startsWith('data:image/svg+xml')).toBeTruthy();
  const mark = await page.locator('.harbor-mark').first().getAttribute('src');
  expect(mark.startsWith('data:image/svg+xml')).toBeTruthy();
  for (const path of ['favicon.svg', 'favicon.ico']) {
    const res = await request.get(new URL(path, BASE).toString());
    expect(res.status(), path).toBe(200);
    expect((await res.body()).length).toBeGreaterThan(32);
  }
});

test('mocked live replies show thinking and topic citations', async ({ page }) => {
  const live = process.env.CHAT_MOCK_URL || 'http://127.0.0.1:3944/';
  await page.goto(live, { waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => window.Shiny && Shiny.shinyapp && Shiny.shinyapp.isConnected());
  await expect(page.locator('.harbor-status')).toContainText('Live (Gemini)');
  await expect(page.locator('#chat-drawer')).toHaveCount(0);

  await page.getByRole('button', { name: /glass_theme work/i }).click();
  const thinkingHeader = page.locator('.shiny-chat-thinking-header').first();
  await expect(thinkingHeader).toBeVisible({ timeout: 20000 });
  await thinkingHeader.click();
  const opened = await thinkingHeader.getAttribute('aria-expanded');
  await thinkingHeader.click();
  const closed = await thinkingHeader.getAttribute('aria-expanded');
  expect(opened).not.toEqual(closed);
  await expect(page.locator('.shiny-chat-thinking').first()).toContainText('theme API');
  await expect(page.getByText('Liquid Glass bslib theme').first()).toBeVisible({ timeout: 20000 });

  await page.locator('#open_sources').click();
  const panel = page.locator('#sources_panel.offcanvas, .offcanvas.show').first();
  await expect(panel).toBeVisible();
  await expect(panel.locator('a[href*="github.io/shinyglass"]')).toBeVisible();
  await expect(panel.locator('a[href*="human-interface-guidelines"]')).toBeVisible();
  await expect(panel.locator('a[href*="shiny.posit.co"]')).toBeVisible();
  await expect(panel.locator('a[href*="shinychat"]')).toHaveCount(0);
  await page.locator('#sources_panel .btn-close').click();

  await page.goto(live, { waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => window.Shiny && Shiny.shinyapp && Shiny.shinyapp.isConnected());
  await page.evaluate(() => {
    window.Shiny.setInputValue(
      'chat_user_input',
      { text: "What's the tide at dawn?" },
      { priority: 'event' }
    );
  });
  await expect(page.getByText('1.4 m').first()).toBeVisible({ timeout: 20000 });
  await page.locator('#open_sources').click();
  await expect(panel).toBeVisible();
  await expect(panel).toContainText('No sources yet');
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
