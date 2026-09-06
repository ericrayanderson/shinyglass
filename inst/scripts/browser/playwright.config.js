const { defineConfig } = require('@playwright/test');
module.exports = defineConfig({
  testDir: '.',
  testMatch: '*.spec.js',
  use: { headless: true, launchOptions: { executablePath: process.env.CHROME_PATH, args: JSON.parse(process.env.CHROME_ARGS || "[]") } },
  reporter: 'list',
});
