const { test, expect } = require('@playwright/test');
const path = require('node:path');
test('text contrast uses font size and weight and composites ancestor fills', async ({ page }) => {
  await page.setContent(`<div style="background: white">
    <button id="normal" style="color: #777; background: transparent; font-size: 16px">Normal text</button>
    <button id="large" style="color: #777; background: transparent; font-size: 24px">Large text</button>
    <button id="disabled" disabled style="color: #aaa; background: white">Disabled</button>
    <div style="background: black"><span id="nested" style="color: white">Nested</span></div>
  </div>`);
  await page.addScriptTag({ path: path.resolve(__dirname, '../audit-glass-contrast.js') });
  const audit = await page.evaluate(() => runGlassAudit(['#normal', '#large', '#disabled', '#nested'], 'light', 3, true));
  expect(audit.findings.filter(x => x.level === 'FAIL').map(x => x.meta.selector)).toEqual(['#normal']);
});
