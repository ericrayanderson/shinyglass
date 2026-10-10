const { test, expect } = require('@playwright/test');

test.skip(!process.env.RUN_COMPAT_TESTS, 'Enable RUN_COMPAT_TESTS=1 with R installed');

const BASE = process.env.COMPAT_URL || 'http://127.0.0.1:3942/';

async function hasPkg(page, name) {
  const pkgs = (await page.locator('#compat_packages').getAttribute('data-pkgs')) || '';
  return pkgs.split(',').includes(name);
}

async function openNav(page, name) {
  const link = page.locator(`a.nav-link[data-value="${name}"], button.nav-link[data-value="${name}"]`).first();
  await link.click();
}

async function gotoCompat(page, query) {
  const url = query ? `${BASE}?${query}` : BASE;
  await page.goto(url, { waitUntil: 'domcontentloaded' });
  await expect(page.locator('#main_nav')).toBeVisible();
  await page.waitForFunction(() => window.Shiny && Shiny.shinyapp && Shiny.shinyapp.isConnected());
  await expect(page.locator('.shiny-input-container:has(#sel) .selectize-input')).toBeVisible();
}

async function contrastOf(locator) {
  return locator.evaluate((el) => {
    function parse(c) {
      const m = String(c).match(/rgba?\(([^)]+)\)/);
      if (!m) return null;
      const p = m[1].split(',').map((x) => Number(x.trim()));
      const a = p.length > 3 ? p[3] : 1;
      const ch = p.slice(0, 3).map((v) => {
        const s = v / 255;
        return s <= 0.03928 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4);
      });
      return { L: 0.2126 * ch[0] + 0.7152 * ch[1] + 0.0722 * ch[2], a };
    }
    let node = el;
    let bg = null;
    while (node) {
      const parsed = parse(getComputedStyle(node).backgroundColor);
      if (parsed && parsed.a >= 0.45) {
        bg = parsed;
        break;
      }
      node = node.parentElement;
    }
    const fg = parse(getComputedStyle(el).color);
    if (!fg || !bg) return 0;
    const L1 = Math.max(fg.L, bg.L);
    const L2 = Math.min(fg.L, bg.L);
    return (L1 + 0.05) / (L2 + 0.05);
  });
}

test.describe.configure({ mode: 'serial', timeout: 90000 });

test('defaults load, stay legible, and keep inputs interactive', async ({ page }) => {
  const pageErrors = [];
  page.on('pageerror', (err) => pageErrors.push(String(err)));
  await gotoCompat(page);
  await expect(page.locator('html')).toHaveAttribute('data-glass-refraction', 'true');
  await expect(page.locator('html')).toHaveAttribute('data-glass-morph', 'true');
  await expect(page.locator('html')).toHaveAttribute('data-glass-press', 'true');
  await expect(page.locator('html')).toHaveAttribute('data-glass-scroll-edge', 'true');
  await expect(page.locator('html')).toHaveAttribute('data-glass-minimize-tabs', 'true');
  await expect(page.locator('html')).toHaveAttribute('data-glass-icon-style', 'clear');

  await expect(page.getByText('Glass compat').first()).toBeVisible();
  const glassPointer = await page.locator('.card').first().evaluate((el) => getComputedStyle(el, '::before').pointerEvents);
  expect(glassPointer).toBe('none');
  expect(await contrastOf(page.locator('#sel-label'))).toBeGreaterThan(3);
  expect(await contrastOf(page.locator('#ping'))).toBeGreaterThan(3);

  const icon = page.locator('#ping .fas, #ping .fa, #ping svg').first();
  await expect(icon).toBeVisible();
  const iconColor = await icon.evaluate((el) => getComputedStyle(el).color);
  expect(iconColor.replace(/\s/g, '')).toMatch(/rgb\(29,\s*29,\s*31\)|rgba\(29,\s*29,\s*31/);

  await page.locator('.shiny-input-container:has(#sel) .selectize-input').click();
  await page.locator('.selectize-dropdown .option', { hasText: 'Beta' }).click();
  await expect(page.locator('#sel_out')).toContainText('Beta');
  await page.locator('#sel_native').selectOption('Two');
  await expect(page.locator('#sel_out')).toContainText('Two');
  const sliderLine = page.locator('.shiny-input-container:has(#n) .irs-line');
  const lineBox = await sliderLine.boundingBox();
  await page.mouse.click(lineBox.x + lineBox.width * 0.8, lineBox.y + lineBox.height / 2);
  await expect.poll(() => page.locator('#n').inputValue()).not.toBe('4');

  await page.locator('#show_extra').check();
  await expect(page.locator('#extra_panel')).toBeVisible();
  await page.locator('#show_extra').uncheck();
  await expect(page.locator('#extra_panel')).toBeHidden();

  await page.locator('#ping').click();
  await expect(page.locator('#ping_out')).toHaveText('pings 1');

  expect(pageErrors, pageErrors.join('\n')).toEqual([]);
});

test('select, date, and picker overlays stack above glass and accept clicks', async ({ page }) => {
  await gotoCompat(page);
  await page.locator('.shiny-input-container:has(#sel) .selectize-input').click();
  const menu = page.locator('.selectize-dropdown').last();
  await expect(menu).toBeVisible();
  const menuZ = await menu.evaluate((el) => Number(getComputedStyle(el).zIndex) || 0);
  expect(menuZ).toBeGreaterThan(1000);
  await page.locator('.selectize-dropdown .option', { hasText: 'Gamma' }).click();
  await expect(page.locator('#sel_out')).toContainText('Gamma');

  await page.locator('#date').click();
  const picker = page.locator('.datepicker-dropdown, .datepicker').last();
  await expect(picker).toBeVisible();
  const dateZ = await picker.evaluate((el) => Number(getComputedStyle(el).zIndex) || 0);
  expect(dateZ).toBeGreaterThan(1000);
  await page.locator('.datepicker .day:not(.old):not(.new)').first().click();
  await expect(page.locator('#date input')).not.toHaveValue('2026-06-15');

  if (await hasPkg(page, 'shinyWidgets')) {
    await page.locator('button[data-id="picker"], .bootstrap-select:has(select#picker) button').first().click();
    const opt = page.locator('.dropdown-menu.show .dropdown-item, .dropdown-menu .inner li a').filter({ hasText: 'Blue' }).first();
    await expect(opt).toBeVisible();
    const z = await opt.evaluate((el) => {
      const menu = el.closest('.dropdown-menu') || el;
      return Number(getComputedStyle(menu).zIndex) || 0;
    });
    expect(z).toBeGreaterThan(1000);
    await opt.click();
    await expect(page.locator('#sel_out')).toContainText('Blue');

    const sw = page.locator('label.switch[for="sw"]');
    await expect(sw).toBeVisible();
    const swBox = await sw.boundingBox();
    expect(swBox && swBox.height).toBeGreaterThan(16);
    await sw.click();
    await expect(page.locator('#sel_out')).toContainText('off');

    const textLine = page.locator('.shiny-input-container:has(#sw_slider) .irs-line');
    const textBox = await textLine.boundingBox();
    await page.mouse.click(textBox.x + textBox.width * 0.85, textBox.y + textBox.height / 2);
    await expect(page.locator('#sel_out')).toContainText('L');
  }

  await page.locator('#date_range input').first().click();
  await expect(page.locator('.datepicker').last()).toBeVisible();
  await page.locator('.datepicker .day:not(.old):not(.new)').nth(3).click();
  await expect(page.locator('#date_range input').first()).not.toHaveValue('2026-06-01');
});

test('tables, plots, map, and chart stay visible and interactive', async ({ page }) => {
  await gotoCompat(page);
  await openNav(page, 'Data');
  await expect(page.locator('#plot img')).toBeVisible({ timeout: 20000 });
  const plotBox = await page.locator('#plot img').boundingBox();
  expect(plotBox && plotBox.width).toBeGreaterThan(40);

  if (await hasPkg(page, 'DT')) {
    await expect(page.locator('#dt table.dataTable')).toBeVisible();
    await expect(page.locator('#dt').getByText('setosa').first()).toBeVisible();
    const next = page.locator('#dt .paginate_button.next, #dt .page-link').filter({ hasText: /next|2/i }).first();
    if (await next.count()) {
      await next.click();
      await expect(page.locator('#dt table')).toBeVisible();
    }
  }

  if (await hasPkg(page, 'reactable')) {
    await expect(page.locator('#rt .rt-table, #rt [role="table"]').first()).toBeVisible();
    await expect(page.locator('#rt').getByText('setosa').first()).toBeVisible();
  }

  if (await hasPkg(page, 'plotly')) {
    const plot = page.locator('#ply.js-plotly-plot, #ply .js-plotly-plot').first();
    await expect(plot).toBeVisible();
    await page.evaluate(() => {
      const gd = document.querySelector('#ply.js-plotly-plot') || document.querySelector('#ply .js-plotly-plot');
      if (window.Plotly && gd) window.Plotly.Fx.hover(gd, [{ curveNumber: 0, pointNumber: 2 }]);
    });
    const hover = page.locator('#ply .hovertext, #ply .hoverlayer text').first();
    await expect(hover).toBeVisible({ timeout: 8000 });
    await expect(hover).toContainText('Point');
    const sheenZ = await page.locator('#ply').evaluate((el) => {
      const card = el.closest('.card') || el;
      return getComputedStyle(card, '::before').zIndex;
    });
    expect(Number(sheenZ)).toBeLessThan(1);
  }

  if (await hasPkg(page, 'leaflet')) {
    const map = page.locator('#map.leaflet-container, #map .leaflet-container').first();
    await expect(map).toBeVisible();
    await page.locator('#map .leaflet-interactive').first().click({ force: true });
    const popup = page.locator('#map .leaflet-popup');
    await expect(popup).toBeVisible();
    await expect(popup).toContainText('Glass popup');
    const popZ = await popup.evaluate((el) => Number(getComputedStyle(el).zIndex) || 0);
    expect(popZ).toBeGreaterThan(100);
  }

  if (await hasPkg(page, 'echarts4r')) {
    await expect(page.locator('#ec canvas, #ec svg').first()).toBeVisible();
  }
});

test('modals, popovers, tooltips, downloads, dynamic UI, and modules work', async ({ page }) => {
  await gotoCompat(page);
  await openNav(page, 'Overlays');

  await page.locator('#open_modal').click();
  const dialog = page.locator('.modal.show');
  await expect(dialog).toBeVisible();
  await expect(page.locator('#modal_name')).toBeVisible();
  await page.locator('#modal_name').fill('Ada');
  await page.locator('#modal_ok').click();
  await expect(dialog).toBeHidden();
  await expect(page.locator('#modal_out')).toHaveText('Ada');

  await page.locator('#notify').click();
  const note = page.locator('#shiny-notification-panel .shiny-notification, .shiny-notification').first();
  await expect(note).toBeVisible();
  await expect(note).toContainText('Saved from glass');
  const noteZ = await note.evaluate((el) => {
    let node = el;
    while (node) {
      const z = Number(getComputedStyle(node).zIndex);
      if (z) return z;
      node = node.parentElement;
    }
    return 0;
  });
  expect(noteZ).toBeGreaterThan(1000);

  await page.locator('#tip_btn').hover();
  const tip = page.locator('.tooltip.show').last();
  await expect(tip).toBeVisible();
  await expect(tip).toContainText('Tooltip on glass');
  expect(await tip.evaluate((el) => getComputedStyle(el).pointerEvents)).toBe('none');
  await page.locator('#pop_btn').click();
  await expect(page.locator('.popover.show, .popover').last()).toBeVisible();
  await expect(page.locator('.popover').last()).toContainText('Popover body');

  const downloadPromise = page.waitForEvent('download');
  await page.locator('#dl').click();
  const download = await downloadPromise;
  expect(download.suggestedFilename()).toContain('glass-compat');

  if (await hasPkg(page, 'shinyjs')) {
    await expect(page.locator('#js_note')).toBeVisible();
    await page.locator('#js_hide').click();
    await expect(page.locator('#js_note')).toBeHidden();
    await page.locator('#js_show').click();
    await expect(page.locator('#js_note')).toBeVisible();
  }

  if (await hasPkg(page, 'waiter')) {
    await page.locator('#spin').click();
    const overlay = page.locator('.waiter-overlay');
    await expect(overlay).toBeVisible();
    await expect(page.locator('#waiter_label')).toHaveText('Loading');
    await expect(overlay).toBeHidden({ timeout: 8000 });
  }

  await openNav(page, 'Layout');
  await expect(page.locator('#acc_one')).toBeVisible();
  await page.getByRole('button', { name: 'Two' }).click();
  await expect(page.locator('#acc_two')).toBeVisible();

  await openNav(page, 'Pill B');
  await expect(page.locator('#pill_b')).toBeVisible();
  await expect(page.locator('#pills .glass-morph-indicator, .nav-pills .glass-morph-indicator').first()).toBeVisible();

  await openNav(page, 'Beta');
  await expect(page.locator('#tab_beta')).toBeVisible();

  await page.locator('#side_q').fill('harbor');
  await expect(page.locator('#side_echo')).toHaveText('filter harbor');

  await page.locator('#add_dyn').click();
  await expect(page.locator('#dyn_text')).toHaveValue('n 1');
  await page.locator('#do_insert').click();
  await expect(page.locator('#ins1')).toHaveValue('ok');
  await page.locator('#mod-ans').fill('lens');
  await expect(page.locator('#mod-echo')).toHaveText('module: lens');

  await openNav(page, 'Inputs');
  await page.locator('#file').setInputFiles({
    name: 'notes.csv',
    mimeType: 'text/csv',
    buffer: Buffer.from('a,b\n1,2\n')
  });
  await expect(page.locator('#file_out')).toHaveText('notes.csv');
});

test('press, morph, scroll edge, and tab minimize follow the defaults', async ({ page }) => {
  await gotoCompat(page);
  const ping = page.locator('#ping');
  const box = await ping.boundingBox();
  await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2);
  await page.mouse.down();
  await expect.poll(() => ping.evaluate((el) => el.style.scale)).toBe('0.965');
  await page.mouse.up();

  await page.evaluate(() => window.scrollTo(0, 900));
  await expect(page.locator('body')).toHaveClass(/glass-scroll-edge/);
  await expect(page.locator('body')).toHaveClass(/glass-tabs-min/);
  await page.locator('#ping').click();
  await expect(page.locator('#ping_out')).toHaveText('pings 1');
});

test('fallback mode keeps blur and tint without a lens and inputs still work', async ({ page }) => {
  await page.addInitScript(() => {
    window.__shinyglassForceRefractionSupport = false;
  });
  await gotoCompat(page);
  await expect(page.locator('html')).toHaveAttribute('data-glass-refraction', 'true');
  await expect(page.locator('.glass-refract')).toHaveCount(0);
  await page.locator('.shiny-input-container:has(#sel) .selectize-input').click();
  await page.locator('.selectize-dropdown .option', { hasText: 'Gamma' }).click();
  await expect(page.locator('#sel_out')).toContainText('Gamma');
  await page.locator('#ping').click();
  await expect(page.locator('#ping_out')).toHaveText('pings 1');

  await gotoCompat(page, 'refraction=0');
  await expect(page.locator('html')).toHaveAttribute('data-glass-refraction', 'false');
  await expect(page.locator('.glass-refract')).toHaveCount(0);
  await page.locator('#date').click();
  await expect(page.locator('.datepicker').last()).toBeVisible();
});

test('dark mode toggle switches the glass pack', async ({ page }) => {
  await gotoCompat(page);
  await expect(page.locator('html')).toHaveAttribute('data-glass-preset', 'light');
  const toggle = page.locator('bslib-input-dark-mode');
  await expect(toggle).toBeVisible();
  await toggle.click();
  await expect(page.locator('html')).toHaveAttribute('data-glass-preset', 'dark');
  await expect(page.locator('#mode_out')).toContainText('dark');
  expect(await contrastOf(page.locator('#sel-label'))).toBeGreaterThan(3);
  await page.locator('#ping').click();
  await expect(page.locator('#ping_out')).toHaveText('pings 1');
});

test('many cards scroll without freezing and print drops backdrop filters', async ({ page }) => {
  await gotoCompat(page);
  await openNav(page, 'Scroll');
  const deck = page.locator('#scroll_deck');
  await expect(page.locator('#deck_1')).toBeVisible();
  const stats = await deck.evaluate(async (el) => {
    const start = performance.now();
    let frames = 0;
    let raf = 0;
    const loop = () => {
      frames += 1;
      raf = requestAnimationFrame(loop);
    };
    raf = requestAnimationFrame(loop);
    const max = el.scrollHeight;
    for (let y = 0; y <= max; y += 80) {
      el.scrollTop = y;
      await new Promise((resolve) => setTimeout(resolve, 16));
    }
    cancelAnimationFrame(raf);
    return { frames, ms: performance.now() - start, top: el.scrollTop };
  });
  expect(stats.frames).toBeGreaterThan(8);
  expect(stats.ms).toBeLessThan(8000);
  await expect(page.locator('#deck_36')).toBeVisible();
  expect(await contrastOf(page.locator('#deck_36 .card-header, #deck_36 h1, #deck_36 .card-title, #deck_36').first())).toBeGreaterThan(3);

  await page.emulateMedia({ media: 'print' });
  const filter = await page.locator('.card').first().evaluate((el) => getComputedStyle(el).backdropFilter || getComputedStyle(el).webkitBackdropFilter || '');
  expect(filter === 'none' || filter === '').toBeTruthy();
});

test('coarse pointers keep glass controls at least 44px', async ({ browser }) => {
  const context = await browser.newContext({
    hasTouch: true,
    isMobile: true,
    viewport: { width: 393, height: 852 },
    deviceScaleFactor: 2
  });
  const page = await context.newPage();
  await page.goto(BASE, { waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => window.Shiny && Shiny.shinyapp && Shiny.shinyapp.isConnected());
  const coarse = await page.evaluate(() => window.matchMedia('(pointer: coarse)').matches);
  expect(coarse).toBeTruthy();
  async function showNav(name) {
    await page.evaluate((value) => {
      const link = document.querySelector(`a.nav-link[data-value="${value}"]`);
      if (link) link.click();
    }, name);
    await page.waitForTimeout(250);
  }

  async function atLeast(locator, min) {
    await expect(locator).toBeVisible();
    const b = await locator.boundingBox();
    expect(b.width).toBeGreaterThanOrEqual(min - 0.6);
    expect(b.height).toBeGreaterThanOrEqual(min - 0.6);
  }

  await atLeast(page.locator('.glass-theme-toggle .btn').first(), 44);
  const sel = page.locator('.shiny-input-container:has(#sel) .selectize-input');
  const selBox = await sel.boundingBox();
  expect(selBox.height).toBeGreaterThanOrEqual(43.4);
  const caret = await page.locator('.shiny-input-container:has(#sel) .selectize-input > input').boundingBox();
  expect(caret.width).toBeGreaterThanOrEqual(selBox.width - 8);
  expect(caret.height).toBeGreaterThanOrEqual(selBox.height - 8);

  const linkHit = await page.locator('#compat_link').evaluate((el) => {
    const text = el.getBoundingClientRect();
    const after = getComputedStyle(el, '::after');
    return {
      textH: text.height,
      hit: Math.max(parseFloat(after.width) || 0, parseFloat(after.height) || 0)
    };
  });
  expect(linkHit.hit).toBeGreaterThanOrEqual(44);
  expect(linkHit.textH).toBeLessThan(36);

  await showNav('Layout');
  await atLeast(page.locator('.bslib-sidebar-layout > .collapse-toggle').first(), 44);
  await atLeast(page.locator('#classic_tabs .nav-link, .nav-tabs .nav-link').first(), 44);

  await showNav('Data');
  await expect(page.locator('.dataTables_paginate .page-link').first()).toBeVisible({ timeout: 20000 });
  await atLeast(page.locator('.dataTables_paginate .page-link').first(), 44);
  await atLeast(page.locator('.bslib-card:has(.dataTables_wrapper) .bslib-full-screen-enter').first(), 44);

  await showNav('Overlays');
  await atLeast(page.locator('#pop_btn'), 44);
  const popBtn = page.locator('#pop_btn');
  await popBtn.click();
  await expect(page.locator('.popover.show')).toBeVisible();
  const popBox = await popBtn.boundingBox();
  await page.touchscreen.tap(popBox.x + popBox.width / 2, popBox.y + popBox.height / 2);
  await expect(page.locator('.popover.show')).toHaveCount(0);
  await expect(page.locator('.popover')).toHaveCount(0);
  await popBtn.click();
  await expect(page.locator('.popover.show')).toBeVisible();
  await page.touchscreen.tap(12, 12);
  await expect(page.locator('.popover.show')).toHaveCount(0);
  await page.locator('#open_modal').scrollIntoViewIfNeeded();
  await page.locator('#open_modal').click();
  const modalClose = page.locator('.modal.show .btn-close, .modal.show [data-bs-dismiss="modal"], .modal.show [data-dismiss="modal"]').first();
  await expect(modalClose).toBeVisible({ timeout: 8000 });
  await atLeast(modalClose, 44);
  await context.close();
});
