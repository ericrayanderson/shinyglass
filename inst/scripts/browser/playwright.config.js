const { defineConfig } = require('@playwright/test');
module.exports = defineConfig({
  testDir: '.',
  testMatch: '*.spec.js',
  use: { headless: true, launchOptions: { executablePath: process.env.CHROME_PATH, args: JSON.parse(process.env.CHROME_ARGS || "[]") } },
  reporter: 'list',
  workers: process.env.RUN_SHINY_TESTS ? 1 : undefined,
  timeout: 45000,
  webServer: process.env.RUN_SHINY_TESTS ? {
    command: 'Rscript shiny-app.R',
    url: 'http://127.0.0.1:3941',
    timeout: 120000,
    reuseExistingServer: false,
  } : undefined,
});
