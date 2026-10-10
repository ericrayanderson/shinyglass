const { defineConfig } = require('@playwright/test');

// route.fulfill() makes Chrome treat the document as a local-network
// initiator and block ws://127.0.0.1. The phone tests rewrite that
// document to stand in for main, so the Shiny socket has to be allowed.
function chromeArgs() {
  const args = JSON.parse(process.env.CHROME_ARGS || '[]');
  const feature = 'LocalNetworkAccessChecks';
  const flag = '--disable-features=';
  const index = args.findIndex((arg) => arg.startsWith(flag));
  if (index === -1) args.push(flag + feature);
  else if (!args[index].slice(flag.length).split(',').includes(feature)) args[index] += ',' + feature;
  return args;
}

module.exports = defineConfig({
  testDir: '.',
  testMatch: '*.spec.js',
  use: { headless: true, launchOptions: { executablePath: process.env.CHROME_PATH, args: chromeArgs() } },
  reporter: 'list',
  workers: (process.env.RUN_SHINY_TESTS || process.env.RUN_COMPAT_TESTS || process.env.RUN_CHAT_TESTS || process.env.RUN_PHONE_TESTS) ? 1 : undefined,
  timeout: 45000,
  webServer: (() => {
    const servers = [];
    if (process.env.RUN_SHINY_TESTS) {
      servers.push({
        command: 'Rscript shiny-app.R',
        url: 'http://127.0.0.1:3941',
        timeout: 120000,
        reuseExistingServer: false,
      });
    }
    if (process.env.RUN_COMPAT_TESTS) {
      servers.push({
        command: 'Rscript compat-app.R',
        url: 'http://127.0.0.1:3942',
        timeout: 180000,
        reuseExistingServer: false,
      });
    }
    if (process.env.RUN_PHONE_TESTS) {
      const phoneApps = [
        [3945, 'inst/examples/demo-app.R'],
        [3946, 'inst/examples/bslib-dashboard.R'],
        [3947, 'inst/examples/inputs-gallery.R'],
        [3948, 'inst/shinyapps/olympic-medals/app-glass.R'],
        [3949, 'inst/examples/shinychat-glass'],
      ];
      for (const [port, app] of phoneApps) {
        servers.push({
          command: `SHINYGLASS_PHONE_PORT=${port} SHINYGLASS_PHONE_APP=${app} Rscript phone-preview-app.R`,
          url: `http://127.0.0.1:${port}`,
          timeout: 180000,
          reuseExistingServer: false,
        });
      }
    }
    if (process.env.RUN_CHAT_TESTS) {
      servers.push({
        command: 'Rscript chat-app.R',
        url: 'http://127.0.0.1:3943',
        timeout: 180000,
        reuseExistingServer: false,
      });
      servers.push({
        command: 'SHINYGLASS_CHAT_MOCK_LIVE=1 SHINYGLASS_CHAT_PORT=3944 Rscript chat-app.R',
        url: 'http://127.0.0.1:3944',
        timeout: 180000,
        reuseExistingServer: false,
      });
    }
    return servers.length ? servers : undefined;
  })(),
});
