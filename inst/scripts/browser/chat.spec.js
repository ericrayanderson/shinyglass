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
  const citation = page.locator('a.harbor-pill').first();
  await expect(citation).toBeVisible({ timeout: 20000 });
  await expect(page.locator('a.harbor-pill', { hasText: 'shinyglass docs' }).first()).toBeVisible();
  await expect(citation.locator('svg')).toBeVisible();
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
  await expect(page.locator('.harbor-status')).toHaveAttribute('data-mode', 'demo');
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
  const gaps = await page.evaluate(() => {
    const send = document.querySelector('.shiny-chat-btn-send').getBoundingClientRect();
    const composer = document.querySelector('.shiny-chat-input .tiptap').getBoundingClientRect();
    return {
      send: { width: send.width, height: send.height, x: send.x, y: send.y },
      composer: { width: composer.width, height: composer.height, x: composer.x, y: composer.y },
      rightGap: (composer.x + composer.width) - (send.x + send.width),
      bottomGap: (composer.y + composer.height) - (send.y + send.height),
      topGap: send.y - composer.y
    };
  });
  const send = gaps.send;
  const composer = gaps.composer;
  expect(send.width).toBeGreaterThanOrEqual(44);
  expect(send.height).toBeGreaterThanOrEqual(44);
  expect(composer.height).toBeGreaterThanOrEqual(44);
  const rightGap = gaps.rightGap;
  const bottomGap = gaps.bottomGap;
  const topGap = gaps.topGap;
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
  const theme = await page.locator('bslib-input-dark-mode').evaluate((el) => {
    const btn = el.shadowRoot && el.shadowRoot.querySelector('button');
    const rect = (btn || el).getBoundingClientRect();
    return { width: rect.width, height: rect.height };
  });
  expect(theme.width).toBeGreaterThanOrEqual(44);
  expect(theme.height).toBeGreaterThanOrEqual(44);
  const sources = await page.locator('#open_sources').boundingBox();
  expect(sources.width).toBeGreaterThanOrEqual(44);
  expect(sources.height).toBeGreaterThanOrEqual(44);
  const toggle = await page.locator('.shiny-chat-page-sidebar-toggle').boundingBox();
  expect(toggle.width).toBeGreaterThanOrEqual(44);
  expect(toggle.height).toBeGreaterThanOrEqual(44);
  const menu = await page.locator('.shiny-chat-history-itemmenu > button').first().evaluate((el) => {
    const rect = el.getBoundingClientRect();
    return { width: rect.width, height: rect.height };
  });
  expect(menu.width).toBeGreaterThanOrEqual(44);
  expect(menu.height).toBeGreaterThanOrEqual(44);
  const select = await page.locator('.shiny-chat-history-item-select').first().evaluate((el) => {
    const rect = el.getBoundingClientRect();
    const row = el.closest('.shiny-chat-history-item').getBoundingClientRect();
    return { height: rect.height, row: row.height };
  });
  expect(select.height).toBeGreaterThanOrEqual(44);
  expect(select.height).toBeGreaterThanOrEqual(select.row - 1);
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
  await expect(page.locator('.shiny-chat-thinking').first()).toBeVisible({ timeout: 20000 });
  await expect(page.locator('.shiny-chat-thinking').first()).toContainText('theme API');
  await expect(page.locator('a.harbor-pill').first()).toBeVisible({ timeout: 20000 });
  await expect(page.locator('a.harbor-pill svg').first()).toBeVisible();
  const restoredText = await page.locator('.shiny-chat-message .shiny-chat-message-content').first().innerText();
  expect(restoredText).not.toMatch(/\+\d+/);
  await expect(page.locator('.harbor-status')).toBeVisible();
});

test('staged favicon is inline and the files answer 200', async ({ page, request }) => {
  const missing = [];
  page.on('response', (res) => {
    const url = res.url();
    if (/favicon\.(svg|ico)(?:$|\?)/i.test(url) && res.status() >= 400) missing.push(`${res.status()} ${url}`);
  });
  page.on('request', (req) => {
    if (/duckduckgo|gstatic\.com\/favicon|faviconkit|google\.com\/s2\/favicons/i.test(req.url())) missing.push(req.url());
  });
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
  await expect(page.locator('link[rel="alternate icon"]')).toHaveCount(0);
  expect(missing).toEqual([]);
});

test('mocked live replies show thinking and topic citations', async ({ page }) => {
  const live = process.env.CHAT_MOCK_URL || 'http://127.0.0.1:3944/';
  await page.goto(live, { waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => window.Shiny && Shiny.shinyapp && Shiny.shinyapp.isConnected());
  await expect(page.locator('.harbor-status')).toContainText('Live (Gemini)');
  await expect(page.locator('.harbor-status')).toHaveAttribute('data-mode', 'ready');
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
  const livePill = page.locator('a.harbor-pill').first();
  await expect(livePill).toBeVisible({ timeout: 20000 });
  await expect(livePill.locator('svg')).toBeVisible();
  expect(await livePill.innerText()).not.toMatch(/\+\d+/);

  await page.locator('#open_sources').click();
  const panel = page.locator('#sources_panel.offcanvas, .offcanvas.show').first();
  await expect(panel).toBeVisible();
  await expect(panel.locator('a[href*="github.io/shinyglass"]')).toBeVisible();
  await expect(panel.locator('a[href*="human-interface-guidelines"]')).toBeVisible();
  await expect(panel.locator('a[href*="shiny.posit.co"]')).toBeVisible();
  await expect(panel.locator('.harbor-source-icon svg').first()).toBeVisible();
  await page.locator('#sources_panel .btn-close').click();

  await page.reload({ waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => window.Shiny && Shiny.shinyapp && Shiny.shinyapp.isConnected());
  await expect(page.locator('.shiny-chat-thinking').first()).toContainText('theme API', { timeout: 20000 });
  await expect(page.locator('.harbor-status')).toHaveAttribute('data-mode', 'live');
  await page.locator('bslib-input-dark-mode').click();
  await expect(page.locator('html')).toHaveAttribute('data-glass-preset', 'dark');
  const chipContrast = await page.locator('.harbor-status').evaluate((el) => {
    const cs = getComputedStyle(el);
    const parse = (c) => {
      const m = c.match(/rgba?\(([^)]+)\)/);
      if (!m) return null;
      return m[1].split(',').map((part) => parseFloat(part));
    };
    const lin = (v) => {
      const s = v / 255;
      return s <= 0.04045 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4;
    };
    const L = (rgb) => 0.2126 * lin(rgb[0]) + 0.7152 * lin(rgb[1]) + 0.0722 * lin(rgb[2]);
    const fg = parse(cs.color);
    const bg = parse(cs.backgroundColor);
    const l1 = L(fg);
    const l2 = L(bg);
    return (Math.max(l1, l2) + 0.05) / (Math.min(l1, l2) + 0.05);
  });
  expect(chipContrast).toBeGreaterThanOrEqual(4.5);
  const liveBubble = page.locator('.shiny-chat-message .shiny-chat-message-content').first();
  await expect(liveBubble).toContainText('Liquid Glass');
  await expect(liveBubble).not.toContainText('local note');
  await expect(page.locator('a.harbor-pill').first()).toBeVisible({ timeout: 20000 });
  expect(await liveBubble.innerText()).not.toMatch(/\+\d+/);

  await page.evaluate(() => localStorage.clear());
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

test('fallback notice stays separate, thinking survives reload, and the sidebar stays clickable', async ({ page }) => {
  await gotoChat(page);
  await page.evaluate(() => {
    window.Shiny.setInputValue(
      'chat_user_input',
      { text: 'a'.repeat(401) },
      { priority: 'event' }
    );
  });
  const notice = page.locator('.harbor-notice-copy');
  await expect(notice).toBeVisible({ timeout: 20000 });
  await expect(notice).toContainText('a bit long');
  const bubble = page.locator('.shiny-chat-message .shiny-chat-message-content').first();
  await expect(bubble).toContainText('glass_theme()');
  await expect(bubble).not.toContainText('a bit long');
  await expect(page.locator('.shiny-chat-thinking').first()).toContainText('theme API');
  await expect(page.locator('.harbor-status')).toHaveAttribute('data-mode', 'demo');

  const hostPos = await page.locator('#harbor_notice_host').evaluate((el) => getComputedStyle(el).position);
  expect(hostPos).not.toBe('fixed');
  const hostPe = await page.locator('#harbor_notice_host').evaluate((el) => getComputedStyle(el).pointerEvents);
  expect(hostPe).toBe('none');
  const sidebar = page.locator('.shiny-chat-page-sidebar');
  const side = await sidebar.boundingBox();
  const header = await page.locator('.shiny-chat-page-header').boundingBox();
  const toast = await page.locator('.harbor-notice').boundingBox();
  expect(toast.y).toBeGreaterThan(header.y + header.height - 4);
  expect(toast.x).toBeGreaterThan(side.x + side.width - 8);
  const hitSidebar = await page.evaluate((pt) => {
    const el = document.elementFromPoint(pt.x, pt.y);
    return !!(el && el.closest('.shiny-chat-page-sidebar'));
  }, { x: side.x + 24, y: side.y + Math.min(80, side.height / 2) });
  expect(hitSidebar).toBeTruthy();
  await page.locator('#project').fill('North dock');
  await expect(page.locator('#project')).toHaveValue('North dock');

  await page.reload({ waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => window.Shiny && Shiny.shinyapp && Shiny.shinyapp.isConnected());
  await expect(page.locator('.harbor-notice-copy')).toContainText('a bit long', { timeout: 20000 });
  const restored = page.locator('.shiny-chat-message .shiny-chat-message-content').first();
  await expect(restored).toContainText('glass_theme()');
  await expect(restored).not.toContainText('a bit long');
  await expect(page.locator('.shiny-chat-thinking').first()).toContainText('theme API');
  const joined = await restored.evaluate((el) => (el.innerText || '').replace(/\s+/g, ' '));
  expect(joined.includes('instead.glass_theme')).toBeFalsy();
});

test('source pills do not request third-party favicons', async ({ page }) => {
  const external = [];
  page.on('request', (req) => {
    const url = req.url();
    if (/duckduckgo|gstatic\.com\/favicon|faviconkit|google\.com\/s2\/favicons/i.test(url)) {
      external.push(url);
    }
  });
  await gotoChat(page);
  await page.getByRole('button', { name: /glass_theme work/i }).click();
  const pill = page.locator('a.harbor-pill').first();
  await expect(pill).toBeVisible({ timeout: 20000 });
  await expect(pill.locator('svg')).toBeVisible();
  const imgs = page.locator('img');
  const srcs = await imgs.evaluateAll((nodes) => nodes.map((node) => node.getAttribute('src') || node.src || ''));
  for (const src of srcs) {
    expect(src, src).not.toMatch(/duckduckgo|gstatic\.com\/favicon/i);
  }
  expect(external).toEqual([]);
});

test('fine pointers use at least 32px send and edit', async ({ page }) => {
  await page.setViewportSize({ width: 1280, height: 800 });
  await gotoChat(page);
  const send = await page.locator('.shiny-chat-btn-send').first().boundingBox();
  expect(send.width).toBeGreaterThanOrEqual(32);
  expect(send.height).toBeGreaterThanOrEqual(32);
  expect(send.width).toBeLessThan(40);
  await page.getByRole('button', { name: /glass_theme work/i }).click();
  await expect(page.locator('.shiny-chat-user-message').first()).toBeVisible({ timeout: 20000 });
  const edit = await page.locator('.shiny-chat-edit-btn').first().evaluate((el) => {
    const rect = el.getBoundingClientRect();
    return { width: rect.width, height: rect.height };
  });
  expect(edit.width).toBeGreaterThanOrEqual(32);
  expect(edit.height).toBeGreaterThanOrEqual(32);
  const theme = await page.locator('bslib-input-dark-mode').evaluate((el) => {
    const btn = el.shadowRoot && el.shadowRoot.querySelector('button');
    const rect = (btn || el).getBoundingClientRect();
    return {
      width: rect.width,
      height: rect.height,
      speed: getComputedStyle(el).getPropertyValue('--speed-fast').trim()
    };
  });
  expect(theme.width).toBeGreaterThanOrEqual(32);
  expect(theme.height).toBeGreaterThanOrEqual(32);
  expect(theme.speed === '0s' || theme.speed === '0').toBeTruthy();
  const sources = await page.locator('#open_sources').boundingBox();
  expect(sources.width).toBeGreaterThanOrEqual(32);
  expect(sources.height).toBeGreaterThanOrEqual(32);
  const toggle = await page.locator('.shiny-chat-page-sidebar-toggle').boundingBox();
  expect(toggle.width).toBeGreaterThanOrEqual(32);
  expect(toggle.height).toBeGreaterThanOrEqual(32);
  const menu = page.locator('.shiny-chat-history-itemmenu > button').first();
  await expect(menu).toHaveCount(1);
  const menuBox = await menu.evaluate((el) => {
    const rect = el.getBoundingClientRect();
    return { width: rect.width, height: rect.height };
  });
  expect(menuBox.width).toBeGreaterThanOrEqual(32);
  expect(menuBox.height).toBeGreaterThanOrEqual(32);
  const select = await page.locator('.shiny-chat-history-item-select').first().evaluate((el) => {
    const rect = el.getBoundingClientRect();
    const row = el.closest('.shiny-chat-history-item').getBoundingClientRect();
    return { height: rect.height, row: row.height };
  });
  expect(select.height).toBeGreaterThanOrEqual(32);
  expect(select.height).toBeGreaterThanOrEqual(select.row - 1);
});

test('ambient motion settles and reduced motion stops it', async ({ page }) => {
  await gotoChat(page);
  const intro = await page.evaluate(() => {
    const cs = getComputedStyle(document.body, '::before');
    return { count: cs.animationIterationCount, name: cs.animationName };
  });
  expect(intro.name).toBe('harbor-orb-intro');
  expect(intro.count).toBe('1');
  await page.waitForTimeout(2800);
  const settled = await page.evaluate(async () => {
    const read = () => getComputedStyle(document.body, '::before').transform;
    const first = read();
    await new Promise((resolve) => setTimeout(resolve, 400));
    return first === read();
  });
  expect(settled).toBeTruthy();
  const sendAnim = await page.locator('.shiny-chat-btn-send').first().evaluate((el) => getComputedStyle(el).animationName);
  expect(sendAnim === 'none' || sendAnim === '').toBeTruthy();

  await page.emulateMedia({ reducedMotion: 'reduce' });
  await page.reload({ waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => window.Shiny && Shiny.shinyapp && Shiny.shinyapp.isConnected());
  const reduced = await page.evaluate(() => getComputedStyle(document.body, '::before').animationName);
  expect(reduced).toBe('none');
});

test('forced fallback shows the demo chip and a toast under the header', async ({ page }) => {
  const live = process.env.CHAT_MOCK_URL || 'http://127.0.0.1:3944/';
  const external = [];
  page.on('request', (req) => {
    if (/duckduckgo|gstatic\.com\/favicon|faviconkit|google\.com\/s2\/favicons/i.test(req.url())) {
      external.push(req.url());
    }
  });
  await page.goto(live, { waitUntil: 'domcontentloaded' });
  await page.evaluate(() => localStorage.clear());
  await page.goto(`${live}?harbor_fallback=1`, { waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => window.Shiny && Shiny.shinyapp && Shiny.shinyapp.isConnected());
  await page.getByRole('button', { name: /glass_theme work/i }).click();
  const notice = page.locator('.harbor-notice-copy');
  await expect(notice).toBeVisible({ timeout: 20000 });
  await expect(notice).toContainText('free-tier');
  await expect(page.locator('.harbor-status')).toHaveAttribute('data-mode', 'demo');
  const bubble = page.locator('.shiny-chat-message .shiny-chat-message-content').first();
  await expect(bubble).toContainText('glass_theme()');
  await expect(bubble).not.toContainText('free-tier');
  await expect(bubble).not.toContainText('local note');
  await expect(page.locator('a.harbor-pill svg').first()).toBeVisible();
  const header = await page.locator('.shiny-chat-page-header').boundingBox();
  const toast = await page.locator('.harbor-notice').boundingBox();
  expect(toast.y).toBeGreaterThan(header.y + header.height - 4);
  expect(external).toEqual([]);
});

test('legacy transcripts split the notice and restore source pills', async ({ page }) => {
  const external = [];
  const missing = [];
  page.on('request', (req) => {
    if (/duckduckgo|gstatic\.com\/favicon|faviconkit|google\.com\/s2\/favicons/i.test(req.url())) {
      external.push(req.url());
    }
  });
  page.on('response', (res) => {
    if (/favicon\.(svg|ico)(?:$|\?)/i.test(res.url()) && res.status() >= 400) missing.push(res.url());
  });
  await gotoChat(page);
  await page.evaluate(() => {
    const path = (location.pathname || '/').replace(/\/$/, '') || '/';
    localStorage.setItem('harbor-notes:' + path, JSON.stringify({
      v: 1,
      messages: [
        { role: 'user', text: 'How does glass_theme work?' },
        {
          role: 'assistant',
          text: 'The live model could not answer just now. Here is the local note instead.glass_theme() builds a Liquid Glass bslib theme. shinyglass docs +5 <img src="https://icons.duckduckgo.com/ip3/ericrayanderson.github.io.ico">',
          thinking: 'Looking through the theme API.'
        }
      ],
      citations: [{
        title: 'shinyglass docs',
        url: 'https://ericrayanderson.github.io/shinyglass/',
        note: 'Theme'
      }],
      notice: ''
    }));
  });
  await page.reload({ waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => window.Shiny && Shiny.shinyapp && Shiny.shinyapp.isConnected());
  await expect(page.locator('.harbor-notice-copy')).toContainText('local note', { timeout: 20000 });
  const bubble = page.locator('.shiny-chat-message .shiny-chat-message-content').first();
  await expect(bubble).toContainText('glass_theme()');
  await expect(bubble).not.toContainText('local note');
  await expect(bubble).not.toContainText('+5');
  await expect(page.locator('a.harbor-pill svg').first()).toBeVisible();
  const joined = await bubble.evaluate((el) => (el.innerText || '').replace(/\s+/g, ' '));
  expect(joined.includes('instead.glass_theme')).toBeFalsy();
  expect(external).toEqual([]);
  expect(missing).toEqual([]);
});

test('mobile header controls respond without a transition delay', async ({ browser }) => {
  const context = await browser.newContext({
    viewport: { width: 390, height: 852 },
    isMobile: true,
    hasTouch: true
  });
  const page = await context.newPage();
  await gotoChat(page);
  const toggle = page.locator('.shiny-chat-page-sidebar-toggle');
  const toggleStarted = Date.now();
  await toggle.click({ timeout: 2000 });
  expect(Date.now() - toggleStarted).toBeLessThan(1500);
  const theme = page.locator('bslib-input-dark-mode');
  await expect(theme).toBeVisible();
  const themeStarted = Date.now();
  await theme.click({ timeout: 2000 });
  expect(Date.now() - themeStarted).toBeLessThan(1500);
  await expect(page.locator('html')).toHaveAttribute('data-glass-preset', 'dark');
  const close = page.locator('.shiny-chat-page-sidebar-close');
  await expect(close).toBeVisible();
  const closeStarted = Date.now();
  await close.click({ timeout: 2000 });
  expect(Date.now() - closeStarted).toBeLessThan(1500);
  await context.close();
});

test('mobile app menu closes on a tap outside the sidebar', async ({ browser }) => {
  const context = await browser.newContext({
    viewport: { width: 393, height: 852 },
    isMobile: true,
    hasTouch: true
  });
  const page = await context.newPage();
  await gotoChat(page);
  const toggle = page.locator('.shiny-chat-page-sidebar-toggle');
  await toggle.click();
  await expect(page.locator('shiny-chat-page')).toHaveAttribute('data-mobile-menu-open', 'true');
  const aside = await page.locator('.shiny-chat-page-sidebar').boundingBox();
  await page.touchscreen.tap(Math.min(380, aside.x + aside.width + 24), 420);
  await expect(page.locator('shiny-chat-page')).not.toHaveAttribute('data-mobile-menu-open', 'true');
  await context.close();
});

test('history list sits at the top of the glass sidebar', async ({ page }) => {
  await page.setViewportSize({ width: 1024, height: 835 });
  await gotoChat(page);
  await expect(page.locator('.shiny-chat-history').first()).toBeVisible();
  const layout = await page.evaluate(() => {
    const header = document.querySelector('.shiny-chat-page-header').getBoundingClientRect();
    const sidebar = document.querySelector('.shiny-chat-page-sidebar').getBoundingClientRect();
    const history = document.querySelector('.shiny-chat-history').getBoundingClientRect();
    const hist = document.querySelector('.shiny-chat-history.shiny-chat-history-inline');
    const section = document.querySelector('.shiny-chat-history-section');
    const bg = hist ? getComputedStyle(hist).backgroundColor : '';
    const sectionBg = section ? getComputedStyle(section).backgroundColor : bg;
    return {
      headerBottom: header.y + header.height,
      sidebarY: sidebar.y,
      sidebarBottom: sidebar.y + sidebar.height,
      historyY: history.y,
      bg,
      sectionBg,
      vh: window.innerHeight
    };
  });
  expect(layout.sidebarY).toBeLessThan(layout.headerBottom + 12);
  expect(layout.sidebarBottom).toBeGreaterThan(layout.vh - 8);
  expect(layout.historyY).toBeLessThan(layout.sidebarY + 48);
  expect(layout.bg === 'rgba(0, 0, 0, 0)' || layout.bg === 'transparent').toBeTruthy();
  expect(layout.sectionBg === 'rgba(0, 0, 0, 0)' || layout.sectionBg === 'transparent').toBeTruthy();
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
