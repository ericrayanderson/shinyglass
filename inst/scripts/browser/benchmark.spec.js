const { test, expect } = require('@playwright/test');
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
test.skip(!process.env.RUN_BENCHMARK, 'Enable RUN_BENCHMARK=1 and RUN_SHINY_TESTS=1');

test('representative Shiny responsiveness comparison', async ({ browser }) => {
  test.setTimeout(240000);
  const rows = [];
  const variants = ['plain', 'glass', 'static'];
  for (let round = 0; round < 3; round++) {
    // Rotate order to reduce warm-cache/order bias; each variant gets a fresh session.
    for (let position = 0; position < variants.length; position++) {
      const variant = variants[(position + round) % variants.length];
      const context = await browser.newContext({ viewport: { width: 1440, height: 900 }, colorScheme: 'light' });
      const page = await context.newPage();
      await page.goto(`http://127.0.0.1:3941/?variant=${variant}`);
      await expect(page.locator('#plot img')).toBeVisible();
      const advance = page.getByRole('button', { name: 'Advance workload', exact: true });
      await advance.click();
      await expect.poll(async () => JSON.parse(await page.locator('#benchmark_result').textContent()).iteration).toBe(1);
      await page.waitForTimeout(700);
      const cdp = await context.newCDPSession(page);
      await cdp.send('Performance.enable');
      const metrics = async () => Object.fromEntries((await cdp.send('Performance.getMetrics')).metrics.map(m => [m.name, m.value]));
      for (let iteration = 2; iteration <= 11; iteration++) {
        const before = await metrics();
        const traceEvents = [];
        const collect = event => traceEvents.push(...event.value);
        cdp.on('Tracing.dataCollected', collect);
        await cdp.send('Tracing.start', { categories: 'devtools.timeline', transferMode: 'ReportEvents' });
        await page.evaluate(() => {
          window.benchmarkLongTasks = [];
          window.benchmarkObserver = new PerformanceObserver(list => benchmarkLongTasks.push(...list.getEntries().map(x => x.duration)));
          benchmarkObserver.observe({ type: 'longtask' });
        });
        const start = performance.now();
        await advance.click();
        await expect.poll(async () => JSON.parse(await page.locator('#benchmark_result').textContent()).iteration).toBe(iteration);
        await page.waitForFunction(() => !document.documentElement.classList.contains('shiny-busy'));
        await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
        const latency = performance.now() - start;
        // Include deferred tint work in CPU/paint sampling, excluding it from response latency.
        await page.waitForTimeout(500);
        const after = await metrics();
        const complete = new Promise(resolve => cdp.once('Tracing.tracingComplete', resolve));
        await cdp.send('Tracing.end');
        await complete;
        cdp.off('Tracing.dataCollected', collect);
        const longTasks = await page.evaluate(() => { benchmarkObserver.disconnect(); return benchmarkLongTasks; });
        const result = JSON.parse(await page.locator('#benchmark_result').textContent());
        const duration = name => 1000 * (after[name] - before[name]);
        rows.push({ variant, round, iteration,
          response_ms: latency,
          server_plot_compute_ms: result.server_compute_ms,
          browser_task_ms: duration('TaskDuration'),
          browser_script_ms: duration('ScriptDuration'),
          browser_layout_ms: duration('LayoutDuration'),
          browser_style_ms: duration('RecalcStyleDuration'),
          browser_paint_ms: traceEvents.filter(e => e.name === 'Paint' && e.ph === 'X').reduce((sum, e) => sum + (e.dur || 0) / 1000, 0),
          long_tasks: longTasks.length,
          long_task_ms: longTasks.reduce((sum, n) => sum + n, 0)
        });
      }
      await context.close();
    }
  }
  const quantile = (values, q) => [...values].sort((a, b) => a - b)[Math.ceil(values.length * q) - 1];
  const summary = variants.map(variant => {
    const samples = rows.filter(row => row.variant === variant);
    return { variant, samples: samples.length,
      median_response_ms: quantile(samples.map(row => row.response_ms), 0.5),
      p95_response_ms: quantile(samples.map(row => row.response_ms), 0.95),
      median_browser_task_ms: quantile(samples.map(row => row.browser_task_ms), 0.5),
      median_server_plot_compute_ms: quantile(samples.map(row => row.server_plot_compute_ms), 0.5)
    };
  });
  const report = {
    environment: { browser: browser.version(), platform: os.platform(), arch: os.arch(), cpu: os.cpus()[0]?.model, viewport: '1440x900' },
    method: '3 rotated rounds, 10 measured interactions per variant after warmup; deterministic 20,000-point data, two plots and a 50-row table. Response uses driver timing through Shiny idle and two animation frames. CPU/paint includes 500 ms deferred work. Server timing covers the main plot expression only, excluding serialization and network. Headless CPU paint is not GPU/device compositing cost.',
    summary, samples: rows
  };
  const out = path.join(__dirname, 'test-results', 'benchmark.json');
  fs.mkdirSync(path.dirname(out), { recursive: true });
  fs.writeFileSync(out, JSON.stringify(report, null, 2));
  console.log(JSON.stringify(summary, null, 2));
});
