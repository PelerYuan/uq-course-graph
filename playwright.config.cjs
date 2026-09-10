const { defineConfig } = require('@playwright/test');
module.exports = defineConfig({
  testDir: './browser-tests', timeout: 60000, retries: process.env.CI ? 1 : 0,
  use: { baseURL: 'http://127.0.0.1:8766/uq-course-graph/', viewport: {width:1440, height:1000}, trace:'retain-on-failure' },
  webServer: { command:'node scripts/serve_docs.cjs', url:'http://127.0.0.1:8766/uq-course-graph/', reuseExistingServer:!process.env.CI },
  reporter: [['list'], ['html', {open:'never'}]]
});
