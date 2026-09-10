const { test, expect } = require('@playwright/test');
const path = require('node:path');
const runtime = path.resolve(__dirname, '../../js/shiny-glass.js');
const themeCss = path.resolve(
  __dirname,
  '../../../python/src/shinyglass/static/theme-light.css'
);

async function bootOverflow(page, { width = 1280, height = 800 } = {}) {
  await page.setViewportSize({ width, height });
  await page.route('http://glass.test/**', (route) =>
    route.fulfill({
      contentType: 'text/html',
      body: '<!DOCTYPE html><html><body></body></html>',
    })
  );
  await page.goto('http://glass.test/app');
  await page.setContent(`<!DOCTYPE html>
<html data-glass-mode="light" data-glass-preset="light" data-glass-tint="false">
<head></head>
<body class="bslib-page-sidebar">
  <nav class="navbar navbar-static-top"><span class="navbar-brand">Glass Dashboard</span></nav>
  <div class="bslib-sidebar-layout">
    <aside class="sidebar" style="width:280px">Filters</aside>
    <main class="main bslib-page-main" style="padding-left:312px;padding-right:12px">
      <div class="layout-column-wrap">
        <div class="card">
          <div class="card-header">Iris data</div>
          <div class="dataTables_wrapper">
            <table class="dataTable">
              <thead><tr>
                <th>Sepal Length</th><th>Sepal Width</th>
                <th>Petal Length</th><th>Petal Width</th><th>Species</th>
              </tr></thead>
              <tbody><tr>
                <td>5.1</td><td>3.5</td><td>1.4</td><td>0.2</td><td>setosa</td>
              </tr></tbody>
            </table>
          </div>
        </div>
        <div class="card">
          <div class="card-header">Dates</div>
          <div class="shiny-date-range-input">
            <div class="input-daterange input-group">
              <input class="form-control" value="2026-01-01">
              <input class="form-control" value="2026-09-10">
            </div>
          </div>
          <pre class="shiny-text-output">list(selectizeInput = c("red","green","blue"), dateRangeInput = c("2026-01-01","2026-09-10"))</pre>
        </div>
        <div class="card">
          <div class="js-plotly-plot">
            <svg class="main-svg" width="900" height="200" viewBox="0 0 900 200">
              <g class="xtick"><text x="20" y="180">axis</text></g>
              <text class="gtitle" x="40" y="24">plotly</text>
            </svg>
          </div>
        </div>
      </div>
    </main>
  </div>
</body>
</html>`);
  await page.addStyleTag({ path: themeCss });
  await page.addScriptTag({ path: require.resolve('jquery') });
  await page.evaluate(() => {
    window.sent = [];
    window.Shiny = {
      setInputValue: (name, value, options) => sent.push({ name, value, options }),
      addCustomMessageHandler: () => {},
    };
  });
  await page.addScriptTag({ path: runtime });
  await page.evaluate(() => new Promise(resolve => $(resolve)));
}

test('1280px side-by-side page_sidebar card keeps five DT columns on-page', async ({ page }) => {
  await bootOverflow(page, { width: 1280, height: 800 });
  await page.evaluate(() => {
    const main = document.querySelector('.bslib-page-main');
    main.innerHTML = `
      <div class="bslib-grid" style="display:grid;grid-template-columns:1fr 1fr;gap:0.75rem;min-width:0">
        <div class="card"><div class="js-plotly-plot">
          <svg class="main-svg" width="900" height="120" viewBox="0 0 900 120">
            <text class="gtitle" x="20" y="24">plotly</text>
          </svg>
        </div></div>
        <div class="card">
          <div class="dataTables_wrapper">
            <table class="dataTable">
              <thead><tr>
                <th>Sepal Length</th><th>Sepal Width</th>
                <th>Petal Length</th><th>Petal Width</th><th>Species</th>
              </tr></thead>
              <tbody><tr>
                <td>5.1</td><td>3.5</td><td>1.4</td><td>0.2</td><td>setosa</td>
              </tr></tbody>
            </table>
          </div>
        </div>
      </div>`;
  });
  const metrics = await page.evaluate(() => ({
    scrollWidth: document.documentElement.scrollWidth,
    clientWidth: document.documentElement.clientWidth,
    tableLayout: getComputedStyle(document.querySelector('table.dataTable')).tableLayout,
    headers: [...document.querySelectorAll('table.dataTable thead th')].map((th) => ({
      visible: th.getClientRects().length > 0,
      width: th.getBoundingClientRect().width,
    })),
    tableWidth: document.querySelector('table.dataTable').getBoundingClientRect().width,
    cardWidth: document.querySelectorAll('.card')[1].getBoundingClientRect().width,
  }));
  expect(metrics.scrollWidth).toBeLessThanOrEqual(metrics.clientWidth + 1);
  expect(metrics.tableLayout).toBe('fixed');
  expect(metrics.headers).toHaveLength(5);
  expect(metrics.headers.every((h) => h.visible && h.width > 24)).toBe(true);
  expect(metrics.tableWidth).toBeLessThanOrEqual(metrics.cardWidth + 2);
});

test('1280px dashboard-like layout does not grow a page scrollbar', async ({ page }) => {
  await bootOverflow(page, { width: 1280, height: 800 });
  const metrics = await page.evaluate(() => ({
    scrollWidth: document.documentElement.scrollWidth,
    clientWidth: document.documentElement.clientWidth,
    overflowX: getComputedStyle(document.documentElement).overflowX,
    tableWidth: document.querySelector('table.dataTable').getBoundingClientRect().width,
    headers: [...document.querySelectorAll('table.dataTable thead th')].map((th) => ({
      text: th.textContent.trim(),
      visible: th.getClientRects().length > 0,
      width: th.getBoundingClientRect().width,
    })),
  }));
  expect(metrics.overflowX).toBe('clip');
  expect(metrics.scrollWidth).toBeLessThanOrEqual(metrics.clientWidth + 1);
  expect(metrics.headers).toHaveLength(5);
  expect(metrics.headers.every((h) => h.visible && h.width > 40)).toBe(true);
  expect(metrics.tableWidth).toBeGreaterThan(500);
});

test('theme switch snaps plotly axis ink and settles after plot reload', async ({ page }) => {
  await bootOverflow(page);
  const before = await page.evaluate(() => getComputedStyle(document.querySelector('.js-plotly-plot .gtitle')).fill);
  await page.evaluate(() => shinyglass.setPreset('dark'));
  expect(await page.evaluate(() => document.documentElement.classList.contains('glass-theme-settling'))).toBe(true);
  const after = await page.evaluate(() => getComputedStyle(document.querySelector('.js-plotly-plot .gtitle')).fill);
  expect(after).not.toBe(before);
  await page.evaluate(() => {
    const img = document.createElement('img');
    img.className = 'plot-img';
    document.querySelector('.js-plotly-plot').after(img);
    const wrap = document.createElement('div');
    wrap.className = 'shiny-plot-output';
    const plot = document.createElement('img');
    plot.src = 'data:image/gif;base64,R0lGODlhAQABAIAAAP///wAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==';
    wrap.appendChild(plot);
    document.body.appendChild(wrap);
  });
  await expect.poll(
    () => page.evaluate(() => document.documentElement.classList.contains('glass-theme-settling'))
  ).toBe(false);
});
